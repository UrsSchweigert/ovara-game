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

- [x] A fresh clone followed by `./ov check` passes, ending with `CHECK PASSED`.
- [x] Each of the three deliberate mistakes made it fail, and the task Result quotes the failing line of output for each.
- [x] `shots/title.png` is 640 by 360 and shows the title.
- [x] `tools/requirements.txt` has exact versions.
- [x] `git status` shows no `game/.godot/` files staged, and the `.uid` files beside scripts are committed.

## Result

Done on 2026-11-21, on macOS with Godot 4.7.2 stable and Python 3.9, by the session that created this repository.

- `./ov check` passed on the untouched skeleton.
- A Python environment was made at `.venv`, and `tools/requirements.txt` now pins PyYAML 6.0.3, jsonschema 4.25.1 and pillow 11.3.0, the same versions the harness's sandbox image carries.
- The three guards were proved, one at a time, and each file was removed afterwards with its `.uid`:
  - `randi()` in `game/rules/`: `res://rules/bad_random.gd:4 uses something rules/ may not: return randi()` and `CHECK FAILED`.
  - an untyped parameter in `game/rules/`: `at: GDScript::reload (res://rules/bad_untyped.gd:3)` and `CHECK FAILED`.
  - a failing test: `FAIL  test_bad.gd  test_one_is_two` and `CHECK FAILED`.
  - `./ov check` passed again after each.
- `./ov shot res://scenes/title/title.tscn shots/title.png` saved a 640 by 360 picture: the word OVARA in white, centred on a near-black ground.
- A root `README.md` was written.

**Changed outside the task's scope:** `ov`. The `shot` command failed with "cannot write shots/title.png" because it did not make the folder. It now makes the folder and takes a relative path from where it is run.

**Not verified:** nothing on a phone; no export.

## Verification
