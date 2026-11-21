# The harness, for Ovara

The harness plans, approves and runs the building of this game. You give it one requirements file per milestone. An investigator drafts a plan and asks you questions. You approve once. Workers then build it issue by issue inside a Docker sandbox, each checked, independently reviewed and merged by trusted Python code. When the harness cannot decide something, it asks you.

It was built by the owner in another repository and copied here; the code is in `tools/harness/` under the owner's own licence (`tools/harness/NOTICE`). The full manual is `tools/harness/README.md`. The specifications are beside this file.

## What you need, once

| Need | Check |
|---|---|
| Python 3.9+, git | `python3 --version`, `git --version` |
| Docker, running | `docker info` |
| `gh`, signed in as the repository's owner | `gh auth status` |
| The Claude Code CLI | `claude --version` |
| A GitHub repository for this project, with this kit pushed to `main` | |
| Branch protection on `main`: require the status check `check`, require branches to be up to date, and apply it to administrators | The harness reads these settings and refuses to merge without them. It never changes them |

Then, from the repository root:

```sh
./ov harness isolation build      # builds the sandbox image ovara-worker:1; slow the first time
./ov harness isolation verify     # repeat daily; must print tier A
claude setup-token                # a long-lived subscription token
./ov harness claude login         # paste it; workers get this token and nothing else
```

Put a GitHub token that may open and merge pull requests on this repository into `~/.local/state/ovara-harness/broker.token`, readable only by you (`chmod 600`). Never put it in the repository.

`./ov harness status` should now say tier A and that a run is permitted.

## Running a milestone

```sh
./ov harness start --requirements requirements/M0-canon-and-foundations.md
```

It checks the environment, lets the investigator draft phases and issues, shows you the plan, waits for you to type the digest to approve it, and offers to run. Rerunning the same command resumes where it stopped. Leave the run in its terminal. In another:

```sh
./ov harness status     # what is happening
./ov harness tasks      # what is waiting for you
./ov harness gui        # the same in a browser, on this machine only
```

## What it will ask you

- **Canon proposals:** a worker needed a world fact that is not in `canon/`.
- **Design choices** that `docs/decisions/` has not settled.
- **Manual tests:** anything that must be seen or tried. Workers cannot open a window, so every scene, every picture and every phone build comes to you.
- **Protected paths:** a task needed to change the plan, the rules for agents, the quest outline, the sources, or the harness itself.

Before any of these reach you, an **overseer** looks at a stuck issue and may retry it, extend one budget or send it back to be refined. Its project notes are in `.claude/agents/overseer.md`.

## The steward: process questions answered for you

The harness stops and asks you whenever it cannot decide something. Most of those questions are about the process, not the game. The steward answers them in your place, so that the milestone gets delivered. Run it in its own terminal while a plan runs:

```sh
python3 tools/steward.py
```

Every five minutes it looks at the open tasks.

- **A split the harness has already checked** is applied at once, with no AI.
- **Any other decision** goes to Claude, headless and read-only, with the rules in `.claude/agents/steward.md`. It may answer: retry, give guidance and retry, extend the retry budget, refine the scope, or apply a split. It may also settle a minor canon detail that changes nothing in the story, and must tell the worker to record it under `canon/proposals/` as decided by the steward.
- **The script, not the AI, gives the answer.** It first checks the answer against its own fixed list, and against two caps: four steward answers on one issue, and two budget extensions on one issue. Past a cap, the issue comes to you.

**What still comes to you**

- Core plot: what happens in the story, the named main characters, the world's rules, the main quest's stages and flags, contradictions between the sources, reversing a recorded decision.
- Anything only a person can do: manual tests, approvals of how something looks, assets, tokens and accounts, promoting a run to `main`.
- Cancelling an issue. The steward never cancels.

When it refers something to you it leaves the task open, says so in its log, and writes its diagnosis, with what it would choose, to `steward-notes/<task>.md` in the harness's state folder.

**Between milestones**

When a plan has finished, the harness opens one pull request from its run branch into `main` and waits. The steward takes it from there:

1. **Audit.** It checks out that pull request, runs `bash ov check`, and has Claude compare the work with the milestone's requirements file: what is met, what is a gap, what only you can judge, and whether anything is broken. The report goes to `steward-notes/<plan>-audit.md`.
2. **Promote.** If the check passes and nothing is broken, it merges that pull request. This is the only pull request it ever merges. If the work is not sound, it leaves it for you.
3. **Gaps.** If the audit found gaps, it writes a follow-up requirements file under `requirements/gaps/` and drafts a plan for it. Two follow-ups per milestone at most. The next milestone does not start until the follow-up is merged, even if the investigator had questions and you finished the draft yourself. To go on without it: `python3 tools/steward.py --skip-gaps <plan-id>`.
4. **Your gate.** If the milestone has things only you can judge (the palette, a build on a phone), it stops and says what to look at. When you have, record it: `python3 tools/steward.py --sign-off <plan-id>`.
5. **Next.** It drafts the plan for the next file in `requirements/`.
6. **Your approval.** It stops and tells you. You type `./ov harness approve <plan-id>`. The steward never approves a plan.
7. **Start.** Once the plan is approved, it imports the issues and starts the run, with the output in `steward-run-<plan>.log` in the state folder.

`python3 tools/steward.py --audit <plan-id>` runs the audit at any time and changes nothing.

**When the harness itself is at fault**

The harness's own code, `tools/harness/`, is protected. No worker may change it and the steward never merges a change to it. When the steward judges that a task is blocked by a defect in that code, it:

1. **Prepares a fix.** In a throwaway copy of `main`, Claude makes the smallest change under `tools/harness/`. The script discards it if any other file was touched or if the harness's own tests fail. Otherwise it pushes a branch and opens a pull request that states the diagnosis, the change and the test result.
2. **Waits for you.** You read it and merge it, or close it.
3. **Restarts.** Once it is merged, the steward pauses the run so that workers in flight can finish, pulls `main`, starts the run again so that it loads the fix, and answers the blocked task with "retry as is".

A fix prepared some other way can be handed to it: `python3 tools/steward.py --adopt-fix <pull request> --for-task <task id>`. `--no-fix` turns the preparing off.

**Know this before you rely on it**

- Its answers are recorded by the harness as yours, because it runs as you. `steward.log` in the state folder is the record of what it answered and why. Read it.
- Each decision is a Claude call on your subscription, and each retry it grants is more worker time. The caps bound this per issue, not per plan.
- It judges whether work is converging. It does not judge whether the game is good.
- The steps between milestones have only been tried in part: the audit has been run against a live run branch, but promoting, drafting a follow-up and starting the next run have not yet happened for real. Watch the first handover.

Options: `--dry-run` decides and shows without answering; `--no-ai` applies checked splits only; `--once` does one round; `--try FILE` shows what it would decide for a task text. `tools/auto_split.py` is the same thing limited to splits, with no AI at all.

## How the roles fit

The harness has its own roles: investigator, refiner, implementer, reviewer, overseer. This project's roles (canon keeper, rules engineer, content author, client engineer, art director, verifier) are lanes: a worker takes the lane that matches the paths its issue may change. The table is in `CLAUDE.md`.

## Where things are

| What | Where |
|---|---|
| All harness state, the approval key and the two tokens | `~/.local/state/ovara-harness/` (or `$HARNESS_HOME`) |
| Throwaway worker folders | `~/.local/share/ovara-harness-work/` |
| The investigator's drafts | `requirements/<file>_plan/` |
| Work branches and the run branch | GitHub: `harness/<issue>`, `harness/run/<plan>` |
| Trusted checks by path | `tools/harness/smoke.json` |
| The sandbox image | `tools/harness/worker/Dockerfile` |

## Limits

- The sandbox image carries Godot 4.7.2 for Linux, Python with the data-check packages, and no display. Export templates, Xcode and the Android SDK are not in it. Phone builds are yours.
- The harness draws on your Claude subscription's limits. When they are reached it waits.
- It has not yet been run on this project. The first milestone is also its trial here.
