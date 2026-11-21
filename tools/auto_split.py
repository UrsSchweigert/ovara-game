#!/usr/bin/env python3
"""Apply split proposals the harness has already checked, so the owner is not asked each time.

The harness stops and asks the owner whenever a strong analysis recommends splitting an issue that is too big.
The proposal has been validated by trusted code by then, and the owner's answer is nearly always the same:
option 6, "apply the proposed split". This script gives that answer, and only that answer.

It never answers anything else. Canon proposals, design decisions, manual tests, retries, budget extensions and
cancellations are left for the owner, and are listed each round so they are not missed.

Run it in its own terminal, as the same user who approved the plan:

    python3 tools/auto_split.py              # check every 60 seconds until stopped with Ctrl+C
    python3 tools/auto_split.py --once       # one round
    python3 tools/auto_split.py --dry-run    # show what it would answer, answer nothing

Every answer it gives is written to auto_split.log beside the harness store.
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPLIT_OPTION = re.compile(r"^\s*(\d+)\)\s*apply the proposed split\b", re.M)
RECOMMENDS_SPLIT = "the strong analysis recommends split"
TASK_HEADER = re.compile(r"^[a-z0-9][a-z0-9-]*\s+\[[a-z_]+\]\s")


def harness(*args):
    env = dict(os.environ, PYTHONPATH=os.path.join(ROOT, "tools"))
    return subprocess.run([sys.executable, "-m", "harness", *args], cwd=ROOT, env=env, capture_output=True, text=True)


def open_tasks():
    out = harness("status", "--json")
    if out.returncode != 0:
        raise RuntimeError("harness status failed: %s" % out.stderr.strip()[:300])
    data = json.loads(out.stdout)
    return [t for t in data.get("human_tasks", []) if t.get("state") == "Requested"], data.get("store", "")


def task_blocks():
    """The text of `harness tasks`, cut into one block per task id. The option numbers are only in this text."""
    text = harness("tasks").stdout
    blocks, current = {}, None
    for line in text.splitlines():
        if TASK_HEADER.match(line):  # "<task-id>  [kind] State ...": wrapped text inside a block may also start at column 0
            current = line.split()[0]
            blocks[current] = []
        if current:
            blocks[current].append(line)
    return {k: "\n".join(v) for k, v in blocks.items()}


def log(store, message):
    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = "%s  %s" % (stamp, message)
    print(line, flush=True)
    if store and os.path.isdir(store):
        with open(os.path.join(store, "auto_split.log"), "a") as fh:
            fh.write(line + "\n")


def one_round(dry_run):
    tasks, store = open_tasks()
    blocks = task_blocks() if tasks else {}
    for task in tasks:
        task_id = task.get("task_id", "")
        block = blocks.get(task_id, "")
        option = SPLIT_OPTION.search(block)
        is_split = task.get("kind") == "decision" and RECOMMENDS_SPLIT in (task.get("why") or "") and option
        if not is_split:
            print("  waiting for you: %s (%s)" % (task_id, task.get("kind")), flush=True)
            continue
        parts = re.findall(r"proposed issue ([a-z0-9-]+)", block)
        if dry_run:
            print("  would apply the split on %s into: %s" % (task_id, ", ".join(parts) or "?"), flush=True)
            continue
        answer = harness("respond", task_id, "--option", option.group(1))
        if answer.returncode == 0:
            log(store, "applied the proposed split on %s into: %s" % (task_id, ", ".join(parts) or "?"))
        else:
            log(store, "could not apply the split on %s: %s" % (task_id, (answer.stderr or answer.stdout).strip()[:300]))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--once", action="store_true", help="one round, then stop")
    ap.add_argument("--dry-run", action="store_true", help="show what would be answered; answer nothing")
    ap.add_argument("--interval", type=int, default=60, help="seconds between rounds (default 60)")
    args = ap.parse_args()
    while True:
        try:
            one_round(args.dry_run)
        except Exception as exc:  # keep watching: a failed round must not stop the watcher
            print("  round failed: %s" % exc, flush=True)
        if args.once:
            return 0
        time.sleep(max(15, args.interval))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
