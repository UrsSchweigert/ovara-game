"""The steward's handling of defects in the harness itself. Called from steward.py.

The harness's own code (tools/harness/) is protected: no worker may change it, and the steward never merges a change
to it. What the steward may do is prepare a fix for the owner and carry on once the owner has merged it:

  1. PREPARE  In a throwaway worktree of main, have Claude make the smallest fix under tools/harness/, run the
              harness's own tests, and, only if they pass, push a branch and open a pull request.
  2. WAIT     The owner reads and merges the pull request. The steward does not.
  3. RESTART  Once it is merged: pause the run so that workers in flight finish, pull main, start the run again so
              that it loads the fix, and answer the blocked task with "retry as is".

A pull request the owner or someone else prepared can be handed to the steward to wait on:

    python3 tools/steward.py --adopt-fix 11 --for-task decision-canon-things-events-1
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

FIX_RULES = """You are preparing a fix for a defect in the Ovara project's development harness, for its owner to review.

You are in a throwaway checkout of the main branch. The harness is the Python package under tools/harness/. The
defect, as diagnosed, is described below.

Rules:

- Change only files under tools/harness/. Nothing else, for any reason.
- Make the smallest change that removes the defect. Do not refactor, rename, reformat or tidy anything else.
- Do not weaken a check, a guard, a schema or a test to make something pass. If the fix would need that, change
  nothing and say so.
- If a test must change because it asserted the defective behaviour, change that one assertion and say which.
- Do not run commands. The tests are run for you afterwards.
- If you are not sure what the defect is, or the fix is more than a few lines in more than two files, change
  nothing and say so.

End with one JSON object and nothing after it:

{"fixed": true, "title": "harness: one line, imperative", "summary": "what was wrong and what you changed, in three sentences at most"}

or {"fixed": false, "summary": "why you changed nothing"}
"""


def run(cmd, cwd, timeout=1800, env=None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=env)


def executing_plan(status):
    for plan in status.get("plans", []):
        if plan.get("state") in ("Executing", "Paused"):
            return plan["plan_id"]
    return None


def prepare(root, book, task_id, diagnosis, task_text, plan_id, model, claude_json):
    """Steps 1: make the fix, test it, open the pull request. Returns the pull request number or None."""
    slug = re.sub(r"[^a-z0-9]+", "-", task_id.lower()).strip("-")[:40]
    branch = "steward/harness-fix-%s" % slug
    work = tempfile.mkdtemp(prefix="steward-fix-")
    try:
        if run(["git", "fetch", "-q", "origin", "main"], root).returncode != 0:
            raise RuntimeError("cannot fetch main")
        added = run(["git", "worktree", "add", "-f", "-B", branch, work, "FETCH_HEAD"], root)
        if added.returncode != 0:
            raise RuntimeError("cannot make a worktree: %s" % added.stderr.strip()[:200])
        prompt = "%s\n\n---\n\nThe diagnosis:\n\n%s\n\nThe task as the harness printed it:\n\n%s\n" % (FIX_RULES, diagnosis, task_text[:6000])
        answer = claude_json(prompt, work, model, "fixed", tools=("Read", "Grep", "Glob", "Edit", "Write"))
        changed = [line[3:].strip() for line in run(["git", "status", "--porcelain"], work).stdout.splitlines() if line.strip()]
        if not answer.get("fixed") or not changed:
            book.log("REFER   no fix prepared for %s: %s" % (task_id, answer.get("summary", "nothing was changed")[:300]))
            return None
        outside = [path for path in changed if not path.startswith("tools/harness/")]
        if outside:
            book.log("REFER   the prepared fix for %s touched files outside tools/harness/ (%s); discarded" % (task_id, ", ".join(outside)[:200]))
            return None
        python = os.path.join(root, ".venv", "bin", "python")
        if not os.path.exists(python):
            python = sys.executable
        env = dict(os.environ, PYTHONPATH=os.path.join(work, "tools"), HARNESS_HOME=tempfile.mkdtemp(prefix="steward-fix-home-"))
        tests = run([python, "-m", "pytest", "tools/harness/tests", "-q", "-p", "no:cacheprovider"], work, timeout=3000, env=env)
        last = (tests.stdout.strip().splitlines() or [""])[-1]
        shutil.rmtree(env["HARNESS_HOME"], ignore_errors=True)
        if tests.returncode != 0:
            book.log("REFER   the prepared fix for %s fails the harness tests (%s); discarded" % (task_id, last[:160]))
            return None
        title = (answer.get("title") or "harness: fix a defect found on %s" % task_id)[:100]
        body = ("Prepared by the steward for the owner to review. The steward does not merge changes to the harness.\n\n"
                "**Found on:** `%s`\n\n**Diagnosis:** %s\n\n**Change:** %s\n\n**Files:** %s\n\n**Harness tests:** %s\n\n"
                "Once this is merged, the steward pauses the run, pulls `main`, restarts the run and retries the blocked task."
                % (task_id, diagnosis[:1500], answer.get("summary", "")[:1500], ", ".join("`%s`" % p for p in changed), last))
        run(["git", "add", "-A", "tools/harness"], work)
        committed = run(["git", "commit", "-q", "-m", "%s\n\nPrepared by the steward (tools/steward.py) for the owner's review." % title], work)
        if committed.returncode != 0:
            raise RuntimeError("cannot commit: %s" % committed.stderr.strip()[:200])
        pushed = run(["git", "push", "-q", "-f", "-u", "origin", branch], work)
        if pushed.returncode != 0:
            raise RuntimeError("cannot push: %s" % pushed.stderr.strip()[:200])
        created = run(["gh", "pr", "create", "--base", "main", "--head", branch, "--title", title, "--body", body], root)
        found = re.search(r"/pull/(\d+)", created.stdout + created.stderr)
        if not found:
            raise RuntimeError("cannot open a pull request: %s" % (created.stderr or created.stdout).strip()[:200])
        number = int(found.group(1))
        book.data.setdefault("fixes", {})[task_id] = {"pr": number, "plan_id": plan_id, "stage": "open"}
        book.save()
        book.log("FIXPR   a fix for %s is ready for you to read and merge: pull request %d (%s)" % (task_id, number, last[:80]))
        return number
    finally:
        run(["git", "worktree", "remove", "--force", work], root)
        shutil.rmtree(work, ignore_errors=True)


def adopt(book, status, number, task_id):
    book.data.setdefault("fixes", {})[task_id] = {"pr": int(number), "plan_id": executing_plan(status), "stage": "open"}
    book.save()
    book.log("FIXPR   waiting on pull request %s for %s; when you merge it the run is restarted and the task retried" % (number, task_id))


def start_run(root, book, plan_id, verb):
    log_path = os.path.join(book.store or tempfile.gettempdir(), "steward-run-%s.log" % plan_id)
    env = dict(os.environ, PYTHONPATH=os.path.join(root, "tools"))
    with open(log_path, "a") as fh:
        subprocess.Popen([sys.executable, "-m", "harness", verb, plan_id], cwd=root, env=env, stdout=fh, stderr=fh, start_new_session=True)
    return log_path


def fixes_round(root, args, status, book, harness, options_in, task_blocks):
    """Steps 2 and 3, a little further each round."""
    fixes = book.data.setdefault("fixes", {})
    plans = {p["plan_id"]: p for p in status.get("plans", [])}
    runner_alive = (status.get("runner") or {}).get("status") == "alive"
    for task_id, fix in fixes.items():
        stage, plan_id = fix.get("stage"), fix.get("plan_id")
        if stage in ("done", "abandoned"):
            continue
        if stage == "open":
            view = run(["gh", "pr", "view", str(fix["pr"]), "--json", "state"], root)
            try:
                state = json.loads(view.stdout).get("state")
            except ValueError:
                continue
            if state == "CLOSED":
                fix["stage"] = "abandoned"
                book.log("REFER   pull request %s was closed without merging; %s is still yours" % (fix["pr"], task_id))
            elif state == "MERGED":
                fix["stage"] = "merged"
                book.log("fix     pull request %s is merged" % fix["pr"])
            else:
                print("  waiting for you: merge pull request %s (the harness fix for %s)" % (fix["pr"], task_id), flush=True)
            book.save()
            if fix["stage"] != "merged":
                continue
        if args.dry_run:
            print("  would pause %s, pull main, restart the run and retry %s" % (plan_id, task_id), flush=True)
            continue
        plan = plans.get(plan_id) or {}
        if fix["stage"] == "merged":
            if plan.get("state") == "Executing" and runner_alive:
                paused = harness("pause", plan_id)
                book.log("fix     pausing %s so that workers in flight can finish%s" % (
                    plan_id, "" if paused.returncode == 0 else ": " + (paused.stderr or paused.stdout).strip()[:200]))
            fix["stage"] = "pausing"
            book.save()
            continue
        if fix["stage"] == "pausing":
            if runner_alive:
                print("  waiting: the run of %s is finishing its workers before the restart" % plan_id, flush=True)
                continue
            branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], root).stdout.strip()
            pulled = run(["git", "pull", "-q", "--ff-only", "origin", "main"], root) if branch == "main" else None
            if pulled is None or pulled.returncode != 0:
                book.log("REFER   cannot pull main into the working tree (on %s): %s. Pull it yourself, then run: ./ov harness resume %s" % (
                    branch, (pulled.stderr.strip()[:200] if pulled else "not on main"), plan_id))
                fix["stage"] = "abandoned"
                book.save()
                continue
            log_path = start_run(root, book, plan_id, "resume")
            book.log("fix     pulled main and restarted the run of %s with the fix; its output goes to %s" % (plan_id, log_path))
            fix["stage"] = "restarted"
            book.save()
            continue
        if fix["stage"] == "restarted":
            block = task_blocks().get(task_id, "")
            number = options_in(block).get("retry as is")
            if block and number:
                answered = harness("respond", task_id, "--option", number)
                book.log("fix     %s answered with 'retry as is'%s" % (
                    task_id, "" if answered.returncode == 0 else " FAILED: " + (answered.stderr or answered.stdout).strip()[:200]))
            else:
                book.log("fix     %s is no longer open; nothing to retry" % task_id)
            if task_id in book.data.get("escalated", []):
                book.data["escalated"].remove(task_id)
            fix["stage"] = "done"
            book.save()
