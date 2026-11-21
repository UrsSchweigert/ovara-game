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
