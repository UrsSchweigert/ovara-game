"""The steward's work between milestones. Called from steward.py once a round.

When a plan has finished, the harness opens one pull request from the run branch into the base branch and waits for
the owner. This module takes it from there:

  1. AUDIT    Check out that pull request's head in a throwaway worktree, run `bash ov check`, and have Claude
              (read-only) compare the result with the milestone's requirements file: what is met, what is a gap,
              what only a person can judge, and whether anything is broken.
  2. PROMOTE  If the check passes and nothing is broken, merge that one pull request. Otherwise refer it.
  3. GAPS     If the audit found gaps, write a follow-up requirements file and draft a plan for it.
  4. GATE     If the milestone has things only a person can judge, wait until the owner records them as passed:
                  python3 tools/steward.py --sign-off <plan-id>
  5. NEXT     Draft the plan for the next file in requirements/.
  6. APPROVAL Stop. The owner types the approval:   ./ov harness approve <plan-id>
  7. START    Once the plan is approved, import its issues and start the run.

It never approves a plan. It merges exactly one kind of pull request: the harness's own promotion of a finished run,
and only after its own check and audit. It writes nothing to the repository except untracked drafts under
requirements/.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

AUDIT_RULES = """You are auditing a finished milestone of the Ovara project for its owner. You are read-only.

You are in a checkout of the finished work. The milestone's requirements file is given below. The project check
(`bash ov check`) has already been run on this checkout, and its result is given below.

For each row of the requirements table, and each line of its Gate section, decide by reading the repository:

- met: the work is here and does what the row asks.
- gap: something the row asks for is missing or incomplete. Say exactly what, so that a worker could be given it.
- needs a person: it can only be judged by looking, listening, or trying it on a device, or it is a decision of taste.

Then give one verdict:

- "sound": the check passes and nothing here would mislead or block later work. Gaps may remain.
- "broken": the check fails, or something is wrong in a way that later work would build on: a contradiction with
  canon/source/, a world rule in CLAUDE.md broken, a guard weakened, a placeholder passed off as real.

Be strict about "broken" and plain about gaps. Do not count as a gap anything the requirements file does not ask for.

End with one JSON object and nothing after it:

{"verdict": "sound", "summary": "two sentences", "gaps": [{"id": "M0.2", "title": "short name", "what": "what is missing, exactly"}], "needs_person": ["what the owner must look at"]}
"""


def run(cmd, cwd, timeout=1800, env=None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=env)


def requirements_dir(root):
    return os.path.join(root, "requirements")


def requirements_files(root):
    """Milestone files in order: M0, M1, ... M10. Gap files live in requirements/gaps/ and are not in this list."""
    names = [n for n in os.listdir(requirements_dir(root)) if re.match(r"M\d+-.*\.md$", n)]
    return sorted(names, key=lambda n: int(re.match(r"M(\d+)", n).group(1)))


def plan_id_for(name):
    return re.sub(r"[^a-z0-9]+", "-", os.path.basename(name).lower()).strip("-")


def file_for_plan(root, plan_id):
    for name in requirements_files(root):
        if plan_id_for(name) == plan_id:
            return os.path.join(requirements_dir(root), name)
    gaps = os.path.join(requirements_dir(root), "gaps")
    if os.path.isdir(gaps):
        for name in os.listdir(gaps):
            if plan_id_for(name) == plan_id:
                return os.path.join(gaps, name)
    return None


def next_file(root, plan_id):
    names = requirements_files(root)
    ids = [plan_id_for(n) for n in names]
    if plan_id in ids and ids.index(plan_id) + 1 < len(names):
        return os.path.join(requirements_dir(root), names[ids.index(plan_id) + 1])
    return None


def audit(root, ref, requirements_path, claude_json, model):
    """Check and audit the commit `ref`. Returns a dict with check_passed, verdict, gaps, needs_person, summary."""
    work = tempfile.mkdtemp(prefix="steward-audit-")
    try:
        fetched = run(["git", "fetch", "-q", "origin", ref], root)
        if fetched.returncode != 0:
            raise RuntimeError("cannot fetch %s: %s" % (ref, fetched.stderr.strip()[:200]))
        added = run(["git", "worktree", "add", "--detach", "-f", work, "FETCH_HEAD"], root)
        if added.returncode != 0:
            raise RuntimeError("cannot check out %s: %s" % (ref, added.stderr.strip()[:200]))
        venv = os.path.join(root, ".venv")
        if os.path.isdir(venv) and not os.path.exists(os.path.join(work, ".venv")):
            os.symlink(venv, os.path.join(work, ".venv"))
        check = run(["bash", "ov", "check"], work, timeout=1800)
        tail = (check.stdout + check.stderr)[-3000:]
        with open(requirements_path, encoding="utf-8") as fh:
            requirements = fh.read()
        prompt = "%s\n\n---\n\nThe requirements file (%s):\n\n%s\n\n---\n\nResult of `bash ov check` (exit %d), last lines:\n\n%s\n" % (
            AUDIT_RULES, os.path.basename(requirements_path), requirements, check.returncode, tail)
        result = claude_json(prompt, work, model, "verdict")
        result["check_passed"] = check.returncode == 0
        if not result["check_passed"]:
            result["verdict"] = "broken"
        result.setdefault("gaps", [])
        result.setdefault("needs_person", [])
        return result
    finally:
        run(["git", "worktree", "remove", "--force", work], root)
        shutil.rmtree(work, ignore_errors=True)


def audit_report(plan_id, result):
    lines = ["# Audit of %s" % plan_id, "", "Verdict: **%s**. Project check: %s." % (
        result.get("verdict"), "passed" if result.get("check_passed") else "FAILED"), "", result.get("summary", ""), ""]
    lines.append("## Gaps")
    lines += ["- **%s %s:** %s" % (g.get("id", ""), g.get("title", ""), g.get("what", "")) for g in result["gaps"]] or ["None found."]
    lines += ["", "## Needs you"]
    lines += ["- %s" % item for item in result["needs_person"]] or ["Nothing."]
    return "\n".join(lines)


def write_gap_file(root, plan_id, source_path, gaps):
    """An untracked follow-up requirements file. The owner commits it if they want it kept."""
    folder = os.path.join(requirements_dir(root), "gaps")
    os.makedirs(folder, exist_ok=True)
    stem = os.path.basename(source_path)[:-3]
    number = len([n for n in os.listdir(folder) if n.startswith(stem)]) + 1
    path = os.path.join(folder, "%s-gaps-%d.md" % (stem, number))
    prefix = "G%s%d" % (re.match(r"M(\d+)", stem).group(1) if re.match(r"M(\d+)", stem) else "", number)
    rows = "".join("| **%s.%d** | **%s** | %s Closes a gap in %s of `%s`. |\n" % (
        prefix, i, (g.get("title") or "Gap").replace("|", "/"), (g.get("what") or "").replace("|", "/").replace("\n", " "),
        g.get("id", "the milestone"), os.path.basename(source_path)) for i, g in enumerate(gaps, 1))
    text = ("# Follow-up: gaps in %s\n\nWritten by the steward after auditing the finished milestone. Each row is something the "
            "milestone's requirements file asked for and the audit did not find. Read with `%s`, `PLAN.md` and `CLAUDE.md`.\n\n"
            "| ID | Requirement | Description |\n| :--- | :--- | :--- |\n%s\n## Gate\n\n`bash ov check` passes, and a second audit finds no gaps.\n"
            % (os.path.basename(source_path), os.path.relpath(source_path, root), rows))
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
    return path


def draft_plan(root, harness, path, book):
    """Investigate and plan, up to the point where only the owner's approval is missing. Returns the plan id or None."""
    rel = os.path.relpath(path, root)
    out_dir = path + "_plan"
    if not os.path.exists(os.path.join(out_dir, "phases.json")):
        book.log("draft   investigating %s (this takes a while)" % rel)
        inv = harness("investigate", "--requirements", rel, "--non-interactive", "--model-source", "claude")
        if os.path.exists(os.path.join(out_dir, "questions.md")) and not os.path.exists(os.path.join(out_dir, "phases.json")):
            book.log("REFER   the investigator has questions for you: %s/questions.md. Answer them with "
                     "`./ov harness investigate --requirements %s --answers <file>`" % (os.path.relpath(out_dir, root), rel))
            return None
        if inv.returncode != 0 or not os.path.exists(os.path.join(out_dir, "phases.json")):
            book.log("REFER   investigating %s failed: %s" % (rel, (inv.stderr or inv.stdout).strip()[-300:]))
            return None
    command = ["plan", "--requirements", rel, "--phases", os.path.join(out_dir, "phases.json")]
    if os.path.exists(os.path.join(out_dir, "issues.json")):
        command += ["--issues", os.path.join(out_dir, "issues.json")]
    planned = harness(*command)
    try:
        info = json.loads(planned.stdout[planned.stdout.index("{"):])
    except ValueError:
        book.log("REFER   planning %s failed: %s" % (rel, (planned.stderr or planned.stdout).strip()[-300:]))
        return None
    if info.get("problems"):
        book.log("REFER   the plan for %s has problems: %s" % (rel, "; ".join(map(str, info["problems"]))[:400]))
        return None
    return info.get("plan_id")


def milestone_round(root, args, status, book, harness, claude_json):
    plans = {p["plan_id"]: p for p in status.get("plans", [])}
    book.data.setdefault("milestones", {})
    book.data.setdefault("signed", {})
    runner_alive = (status.get("runner") or {}).get("status") == "alive"

    # 7. START: a plan the steward drafted has been approved by the owner.
    for plan_id, record in list(book.data["milestones"].items()):
        waiting = record.get("awaiting_approval")
        if not waiting or waiting not in plans:
            continue
        state = plans[waiting]["state"]
        if state == "Approved" and not runner_alive:
            issues = os.path.join(record["awaiting_path"] + "_plan", "issues.json")
            if args.dry_run:
                print("  would import the issues of %s and start its run" % waiting, flush=True)
                continue
            imported = harness("import-issues", waiting, os.path.relpath(issues, root))
            if imported.returncode != 0:
                book.log("REFER   importing issues for %s failed: %s" % (waiting, (imported.stderr or imported.stdout).strip()[-300:]))
                record.pop("awaiting_approval")
                book.save()
                continue
            log_path = os.path.join(book.store or tempfile.gettempdir(), "steward-run-%s.log" % waiting)
            env = dict(os.environ, PYTHONPATH=os.path.join(root, "tools"))
            with open(log_path, "a") as fh:
                subprocess.Popen([sys.executable, "-m", "harness", "run", waiting], cwd=root, env=env, stdout=fh, stderr=fh,
                                 start_new_session=True)
            book.log("start   run of %s started; its output goes to %s" % (waiting, log_path))
            record.pop("awaiting_approval")
            book.save()
        elif state in ("Proposed", "Draft") and not record.get("approval_asked"):
            book.log("APPROVE the plan %s is drafted and waits for you:  ./ov harness approve %s" % (waiting, waiting))
            record["approval_asked"] = True
            book.save()

    for plan_id, plan in plans.items():
        record = book.data["milestones"].setdefault(plan_id, {})
        promotion = plan.get("promotion") or {}
        number = promotion.get("number")
        source = file_for_plan(root, plan_id)
        if not number or not source or record.get("done"):
            continue

        # 1. AUDIT, once per plan.
        if "audit" not in record:
            if args.dry_run or args.no_ai:
                print("  would audit the finished plan %s (pull request %s)" % (plan_id, number), flush=True)
                continue
            book.log("audit   %s: checking and auditing pull request %s" % (plan_id, number))
            try:
                record["audit"] = audit(root, plan["run_branch"], source, claude_json, args.model)
            except Exception as exc:
                book.log("ERROR   audit of %s: %s" % (plan_id, str(exc)[:300]))
                continue
            book.note("%s-audit" % plan_id, audit_report(plan_id, record["audit"]))
            book.log("audit   %s: %s, %d gap(s), %d thing(s) for you. Report: steward-notes/%s-audit.md" % (
                plan_id, record["audit"]["verdict"], len(record["audit"]["gaps"]), len(record["audit"]["needs_person"]), plan_id))
            book.save()
        result = record["audit"]

        # 2. PROMOTE: merge the harness's own pull request, or refer it.
        if not promotion.get("merged") and not record.get("promoted"):
            if result["verdict"] != "sound":
                if not record.get("referred"):
                    book.log("REFER   %s is not sound, so its pull request %s is left for you: %s" % (plan_id, number, result.get("summary", "")))
                    record["referred"] = True
                    book.save()
                continue
            view = run(["gh", "pr", "view", str(number), "--json", "state,baseRefName,headRefName,mergeStateStatus"], root)
            try:
                pr = json.loads(view.stdout)
            except ValueError:
                continue
            if pr.get("state") == "MERGED":
                record["promoted"] = True
            elif pr.get("baseRefName") != plan["base_branch"] or pr.get("headRefName") != plan["run_branch"]:
                book.log("REFER   pull request %s is not the promotion of %s; not touching it" % (number, plan_id))
                record["referred"] = True
            elif pr.get("mergeStateStatus") in ("CLEAN", "HAS_HOOKS", "UNSTABLE"):
                if args.dry_run:
                    print("  would merge pull request %s (promotion of %s)" % (number, plan_id), flush=True)
                    continue
                merged = run(["gh", "pr", "merge", str(number), "--merge"], root)
                if merged.returncode == 0:
                    record["promoted"] = True
                    book.log("promote %s: merged pull request %s into %s" % (plan_id, number, plan["base_branch"]))
                else:
                    book.log("wait    pull request %s cannot merge yet: %s" % (number, (merged.stderr or merged.stdout).strip()[:200]))
            book.save()
            continue

        # 3. GAPS: a follow-up plan, once.
        if result["gaps"] and not record.get("gap_plan_tried"):
            record["gap_plan_tried"] = True
            stem = os.path.basename(source)[:-3]
            gap_dir = os.path.join(requirements_dir(root), "gaps")
            earlier = [n for n in os.listdir(gap_dir) if n.startswith(stem.split("-gaps-")[0])] if os.path.isdir(gap_dir) else []
            if len(earlier) >= 2:
                book.log("REFER   %s still has %d gap(s) after two follow-ups; see steward-notes/%s-audit.md" % (plan_id, len(result["gaps"]), plan_id))
                book.save()
                continue
            if args.dry_run:
                print("  would draft a follow-up plan for %d gap(s) in %s" % (len(result["gaps"]), plan_id), flush=True)
                continue
            path = write_gap_file(root, plan_id, source, result["gaps"])
            record["gap_path"] = path
            book.log("gaps    %s: wrote %s" % (plan_id, os.path.relpath(path, root)))
            drafted = draft_plan(root, harness, path, book)
            if drafted:
                record.update(awaiting_approval=drafted, awaiting_path=path, approval_asked=False, gap_plan=drafted)
            book.save()
            continue
        if record.get("awaiting_approval"):
            continue  # the follow-up is with the owner; the next milestone waits behind it

        # A milestone does not advance past its follow-up. The follow-up may have been drafted here, or later by the
        # owner after answering the investigator's questions: either way it is the plan made from the gap file.
        if record.get("gap_path") and not record.get("gaps_waived"):
            follow_up = plan_id_for(record["gap_path"])
            if follow_up in plans:
                record["gap_plan"] = follow_up
                if plans[follow_up]["state"] in ("Draft", "Proposed") and not record.get("approval_asked_gap"):
                    record.update(awaiting_approval=follow_up, awaiting_path=record["gap_path"], approval_asked=False,
                                  approval_asked_gap=True)
                    book.save()
                    continue
            merged = follow_up in plans and ((plans[follow_up].get("promotion") or {}).get("merged")
                                             or book.data["milestones"].get(follow_up, {}).get("promoted"))
            if not merged:
                if not record.get("hold_said"):
                    book.log("HOLD    %s has %d gap(s) and its follow-up (%s) is not merged yet, so the next milestone waits. "
                             "To go on without it:  python3 tools/steward.py --skip-gaps %s" % (
                                 plan_id, len(result["gaps"]), os.path.relpath(record["gap_path"], root), plan_id))
                    record["hold_said"] = True
                    book.save()
                continue

        # 4. GATE: things only a person can judge.
        if result["needs_person"] and plan_id not in book.data["signed"]:
            if not record.get("gate_asked"):
                book.log("GATE    %s is merged. Before the next milestone, look at: %s. Then record it:  python3 tools/steward.py --sign-off %s" % (
                    plan_id, "; ".join(result["needs_person"])[:600], plan_id))
                record["gate_asked"] = True
                book.save()
            continue

        # 5. NEXT: draft the plan for the next milestone file. Follow-up plans do not advance the milestone.
        following = next_file(root, plan_id)
        record["done"] = True
        if not following or plan_id_for(following) in plans:
            book.save()
            continue
        if args.dry_run:
            print("  would draft the plan for %s" % os.path.relpath(following, root), flush=True)
            record["done"] = False
            continue
        drafted = draft_plan(root, harness, following, book)
        if drafted:
            book.data["milestones"].setdefault(drafted, {})
            record.update(awaiting_approval=drafted, awaiting_path=following, approval_asked=False)
        book.save()
