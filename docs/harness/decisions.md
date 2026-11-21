# Harness decisions for Ovara

The harness was built and proven in another repository of the owner's. These are the choices made when it was copied here. All are recorded as chosen unless marked assumed.

| Decision | Value |
|---|---|
| Location | `tools/harness/`, run as `./ov harness` |
| Language | Python 3.9+, standard library only |
| Agent runtime | Claude Code, headless, on the owner's subscription token |
| State store | SQLite under `~/.local/state/ovara-harness/` |
| Isolation | Tier A: the Docker image `ovara-worker:1`, verified daily |
| Sandbox toolchain | Godot 4.7.2, gdtoolkit, GUT, Pillow, PyYAML, jsonschema. Swift, Node and Playwright are carried over from the original image and unused here (assumed acceptable; removing them means changing the sandbox checks) |
| Approval | Typed digest in a real terminal, once per plan |
| Merge policy | Autonomous when every gate passes, onto a run branch; needs branch protection with the required check `check` |
| Overseer | On |
| Requirements | One file per milestone in `requirements/` |
| Trusted checks | `tools/harness/smoke.json`: the Godot project must load, and `bash ov check` must pass, for any change under `game/`, `canon/` or the data checks |
| Protected paths | Added for this project: `canon/source/`, `CLAUDE.md`, `PLAN.md`, `docs/design/quests.md`, `docs/decisions/`, `ov`, `game/project.godot`, the test runner and structure tests, `.claude/agents/`, `requirements/` |
| Assets | Placeholders by script; final art is a human decision before milestone 9. The art service and Blender are off unless the owner sets them up |
| Notifications | The terminal and the local dashboard (assumed) |

Not carried over: the original project's own decisions history, its run records, its browser and iOS smoke rules' targets, and one test tied to its CI.

Changed from the original: default state and work folders, the image name, two smoke rules added, protected paths added, two Python packages added to the image with a sandbox check for them, and the `.env` file read from the repository root first.
