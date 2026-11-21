#!/usr/bin/env python3
"""The steward: answers the harness's process questions for the owner while a plan runs.

The harness stops and asks the owner whenever it cannot decide something. Most of those questions are about the
process (retry, give a hint, extend a budget, refine, split), not about the game. The steward answers those, and
leaves the owner what only the owner should decide: core plot, and anything only a person can do.

How it works, each round:

  1. It reads the open human tasks from the harness.
  2. A decision whose split proposal the harness has already checked is applied at once, with no AI.
  3. For any other decision, it asks Claude (headless, read-only: it may read the repository and nothing else)
     to decide by the rules in .claude/agents/steward.md.
  4. THIS SCRIPT, not the AI, checks the answer against a fixed list of what the steward may do, checks the caps,
     and only then gives the answer to the harness with `harness respond`.
  5. Everything else (manual tests, assets, promotions, anything the AI escalates) is left for the owner and
     listed as waiting.

What it can never do: cancel an issue, approve a plan, promote a run, answer a manual test or an asset request,
touch GitHub, tokens, files or the harness's store. Its answers are recorded by the harness as the owner's, because
it runs as the owner. Every answer, with its reason, is written to steward.log beside the harness store.

    python3 tools/steward.py               # every 5 minutes until Ctrl+C
    python3 tools/steward.py --once        # one round
    python3 tools/steward.py --dry-run     # decide and show, answer nothing
    python3 tools/steward.py --no-ai       # splits only, never call Claude
    python3 tools/steward.py --try FILE    # show what it would decide for a task text in FILE; answers nothing
"""
import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES = os.path.join(ROOT, ".claude", "agents", "steward.md")

# The only answers the steward may give, by the label the harness prints. "cancel the issue" is deliberately absent.
ALLOWED = ("retry as is", "give guidance and retry", "extend retry budget and retry", "refine the scope", "apply the proposed split")
MAY_DECIDE = ("process", "minor_canon")
MAX_DECISIONS_PER_ISSUE = 4      # after this many steward answers on one issue, the owner is asked
MAX_BUDGET_EXTENSIONS_PER_ISSUE = 2

TASK_HEADER = re.compile(r"^[a-z0-9][a-z0-9-]*\s+\[[a-z_]+\]\s")
OPTION_LINE = re.compile(r"^\s*(\d+)\)\s*([^:\n]+):", re.M)
RECOMMENDS_SPLIT = "the strong analysis recommends split"


def harness(*args):
    env = dict(os.environ, PYTHONPATH=os.path.join(ROOT, "tools"))
    return subprocess.run([sys.executable, "-m", "harness", *args], cwd=ROOT, env=env, capture_output=True, text=True)


def read_status():
    out = harness("status", "--json")
    if out.returncode != 0:
        raise RuntimeError("harness status failed: %s" % out.stderr.strip()[:300])
    return json.loads(out.stdout)


def task_blocks():
    """`harness tasks` as one text block per task id. Option numbers and labels are only in this text."""
    blocks, current = {}, None
    for line in harness("tasks").stdout.splitlines():
        if TASK_HEADER.match(line):
            current = line.split()[0]
            blocks[current] = []
        if current:
            blocks[current].append(line)
    return {k: "\n".join(v) for k, v in blocks.items()}


def options_in(block):
    return {label.strip().lower(): number for number, label in OPTION_LINE.findall(block)}


class Book:
    """What the steward has done so far, kept beside the harness store so it survives restarts."""

    def __init__(self, store):
        self.store = store if store and os.path.isdir(store) else None
        self.path = os.path.join(self.store, "steward-state.json") if self.store else None
        self.data = {"issues": {}, "escalated": []}
        if self.path and os.path.exists(self.path):
            with open(self.path) as fh:
                self.data = json.load(fh)

    def issue(self, issue_id):
        return self.data["issues"].setdefault(issue_id, {"decisions": 0, "budget_extensions": 0})

    def save(self):
        if self.path:
            with open(self.path + ".tmp", "w") as fh:
                json.dump(self.data, fh, indent=1)
            os.replace(self.path + ".tmp", self.path)

    def log(self, message):
        line = "%s  %s" % (datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), message)
        print(line, flush=True)
        if self.store:
            with open(os.path.join(self.store, "steward.log"), "a") as fh:
                fh.write(line + "\n")

    def note(self, task_id, text):
        if not self.store:
            return
        folder = os.path.join(self.store, "steward-notes")
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, task_id + ".md"), "w") as fh:
            fh.write(text + "\n")


def ask_claude(task_text, issue_text, model):
    """One headless, read-only call. Returns the decision dict, or raises."""
    claude = shutil.which("claude")
    if not claude:
        raise RuntimeError("the `claude` command is not on the PATH")
    with open(RULES, encoding="utf-8") as fh:
        rules = re.sub(r"\A---\n.*?\n---\n", "", fh.read(), flags=re.S).strip()
    prompt = (
        "%s\n\n---\n\nThe open task, exactly as the harness prints it:\n\n%s\n\n"
        "The issue's record:\n\n%s\n\n"
        "Read what you need in this repository, then decide. End with the JSON object and nothing after it."
        % (rules, task_text, issue_text[:12000])
    )
    # The prompt goes in on standard input: it begins with dashes, which the CLI would read as an option.
    command = [claude, "-p", "--output-format", "json"]
    if model:
        command += ["--model", model]
    command += ["--allowedTools", "Read", "Grep", "Glob"]
    out = subprocess.run(command, cwd=ROOT, input=prompt, capture_output=True, text=True, timeout=900)
    if out.returncode != 0:
        raise RuntimeError("claude failed: %s" % (out.stderr or out.stdout).strip()[:300])
    try:
        text = json.loads(out.stdout).get("result", "")
    except ValueError:
        text = out.stdout
    found = re.findall(r"\{[^{}]*\"decision\"[^{}]*\}", text, re.S)
    if not found:
        raise RuntimeError("no decision in the reply: %s" % text.strip()[-300:])
    return json.loads(found[-1])


def judge(decision, block, counts):
    """The script's own check of what the AI answered. Returns (option_number, guidance) or raises ValueError to escalate."""
    if decision.get("decision") != "respond":
        raise ValueError(decision.get("reason") or "the steward chose to escalate")
    if decision.get("class") not in MAY_DECIDE:
        raise ValueError("class %r is the owner's: %s" % (decision.get("class"), decision.get("reason", "")))
    label = (decision.get("option_label") or "").strip().lower()
    if label not in ALLOWED:
        raise ValueError("%r is not an answer the steward may give" % label)
    number = options_in(block).get(label)
    if not number:
        raise ValueError("the harness does not offer %r on this task" % label)
    guidance = (decision.get("guidance") or "").strip()
    if label == "give guidance and retry" and not guidance:
        raise ValueError("guidance was chosen with no guidance text")
    if counts["decisions"] >= MAX_DECISIONS_PER_ISSUE:
        raise ValueError("the steward has already answered %d times on this issue" % counts["decisions"])
    if label == "extend retry budget and retry" and counts["budget_extensions"] >= MAX_BUDGET_EXTENSIONS_PER_ISSUE:
        raise ValueError("the budget on this issue has already been extended %d times" % counts["budget_extensions"])
    return number, guidance, label


def one_round(args):
    status = read_status()
    book = Book(status.get("store", ""))
    tasks = [t for t in status.get("human_tasks", []) if t.get("state") == "Requested"]
    blocks = task_blocks() if tasks else {}
    for task in tasks:
        task_id, kind = task.get("task_id", ""), task.get("kind")
        block = blocks.get(task_id, "")
        issues = task.get("affected_issues") or []
        counts = book.issue(issues[0]) if issues else {"decisions": 0, "budget_extensions": 0}
        if kind != "decision":
            print("  waiting for you: %s (%s)" % (task_id, kind), flush=True)
            continue
        split_number = options_in(block).get("apply the proposed split")
        if split_number and RECOMMENDS_SPLIT in (task.get("why") or "") and counts["decisions"] < MAX_DECISIONS_PER_ISSUE:
            parts = ", ".join(re.findall(r"proposed issue ([a-z0-9-]+)", block)) or "?"
            if args.dry_run:
                print("  would apply the split on %s into: %s" % (task_id, parts), flush=True)
                continue
            answer = harness("respond", task_id, "--option", split_number)
            if answer.returncode == 0:
                counts["decisions"] += 1
                book.log("split   %s -> %s" % (task_id, parts))
            else:
                book.log("FAILED  split on %s: %s" % (task_id, (answer.stderr or answer.stdout).strip()[:300]))
            book.save()
            continue
        if task_id in book.data["escalated"]:
            print("  waiting for you: %s (the steward referred it; see steward-notes/%s.md)" % (task_id, task_id), flush=True)
            continue
        if args.no_ai:
            print("  waiting for you: %s (decision; --no-ai)" % task_id, flush=True)
            continue
        issue_text = "\n\n".join(harness("issue", i).stdout for i in issues[:2])
        try:
            decision = ask_claude(block, issue_text, args.model)
        except Exception as exc:
            book.log("ERROR   %s: %s" % (task_id, str(exc)[:300]))
            continue
        try:
            number, guidance, label = judge(decision, block, counts)
        except ValueError as why:
            if not args.dry_run:
                book.data["escalated"].append(task_id)
                book.note(task_id, "# %s\n\nReferred to you by the steward.\n\n%s\n\nIts full answer:\n\n```json\n%s\n```"
                          % (task_id, why, json.dumps(decision, indent=1)))
                book.save()
            book.log("REFER   %s: %s" % (task_id, str(why)[:400]))
            continue
        if args.dry_run:
            print("  would answer %s with %r (%s): %s" % (task_id, label, decision.get("class"), decision.get("reason", "")), flush=True)
            continue
        command = ["respond", task_id, "--option", number]
        if guidance:
            command += ["--guidance", guidance]
        answer = harness(*command)
        if answer.returncode == 0:
            counts["decisions"] += 1
            if label == "extend retry budget and retry":
                counts["budget_extensions"] += 1
            book.log("answer  %s: %s [%s] %s%s" % (task_id, label, decision.get("class"), decision.get("reason", ""),
                                                  (" | guidance: " + guidance) if guidance else ""))
        else:
            book.log("FAILED  %s: %s" % (task_id, (answer.stderr or answer.stdout).strip()[:300]))
        book.save()


def try_file(path, model):
    with open(path, encoding="utf-8") as fh:
        block = fh.read()
    decision = ask_claude(block, "(no issue record: this is a trial)", model)
    print(json.dumps(decision, indent=1))
    try:
        number, guidance, label = judge(decision, block, {"decisions": 0, "budget_extensions": 0})
        print("the script would accept this: option %s, %r" % (number, label))
    except ValueError as why:
        print("the script would refer this to the owner: %s" % why)


def main():
    ap = argparse.ArgumentParser(description="The steward: answers the harness's process questions for the owner.")
    ap.add_argument("--once", action="store_true", help="one round, then stop")
    ap.add_argument("--dry-run", action="store_true", help="decide and show; answer nothing")
    ap.add_argument("--no-ai", action="store_true", help="apply checked splits only; never call Claude")
    ap.add_argument("--interval", type=int, default=300, help="seconds between rounds (default 300)")
    ap.add_argument("--model", help="model for the steward's decisions (default: the CLI's own default)")
    ap.add_argument("--try", dest="try_path", metavar="FILE", help="decide on a task text in FILE and show it; answers nothing")
    args = ap.parse_args()
    if args.try_path:
        try_file(args.try_path, args.model)
        return 0
    while True:
        try:
            one_round(args)
        except Exception as exc:  # a failed round must not stop the watcher
            print("  round failed: %s" % str(exc)[:300], flush=True)
        if args.once:
            return 0
        time.sleep(max(60, args.interval))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
