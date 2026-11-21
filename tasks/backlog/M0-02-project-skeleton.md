# M0-02: Confirm the skeleton and set up the tools

- **Role:** rules-engineer
- **Milestone:** M0
- **Depends on:** none (can run alongside M0-01)

## Goal

The kit ships a small Godot project that was built and tested with Godot 4.7.2 before it was packed. This task proves that it also works on this machine, sets up the Python environment the data checks need, and records what was found. After it, every agent can rely on `./ov check`.

## Canon to read

- None. Read `PLAN.md` sections 4 and 5 and `docs/decisions/0001-stack.md`.

## Scope

- In:
  - Run `./ov check` on the untouched skeleton and record the output and the Godot version.
  - Create `.venv` with Python 3.9 or newer and install the packages in `tools/requirements.txt`. Replace the bare names in that file with the exact versions installed.
  - Prove the guards work, one at a time, undoing each afterwards: a `randi()` call in a script under `game/rules/`; a function with an untyped parameter; a test with a failing `check_eq`. Each must make `./ov check` fail and name the file.
  - Run `./ov shot res://scenes/title/title.tscn shots/title.png` and look at the picture.
  - If the Godot version differs from the one in `docs/decisions/0001-stack.md`, add a line there with the version and anything that had to change.
  - Write a root `README.md` for people: what the project is, the `./ov` commands, and how to open the editor.
- Out: no game logic. No changes to `project.godot` display or warning settings. No add-ons.

## Acceptance

- [ ] A fresh clone followed by `./ov check` passes, ending with `CHECK PASSED`.
- [ ] Each of the three deliberate mistakes made it fail, and the task Result quotes the failing line of output for each.
- [ ] `shots/title.png` is 640 by 360 and shows the title.
- [ ] `tools/requirements.txt` has exact versions.
- [ ] `git status` shows no `game/.godot/` files staged, and the `.uid` files beside scripts are committed.

## Result

## Verification
