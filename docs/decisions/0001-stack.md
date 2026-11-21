# 0001: Engine and tools

**Context.** The game is a 2D, turn-based, hex-grid tactics game for phones, built mostly by AI agents. The owner chose Godot and a look inspired by *Albion* (Blue Byte, 1995).

**Decision.**

- **Engine:** Godot 4, Compatibility renderer. The kit was built and tested with Godot 4.7.2 stable on macOS. Use that version or a newer 4.x; record any change here.
- **Language:** GDScript with static types. `untyped_declaration` is set to error in `project.godot`.
- **Display:** 640 by 360 base viewport, stretch mode `viewport`, aspect `expand`, nearest-neighbour filtering, 2D transforms snapped to pixels, landscape only, touch emulated from the mouse on the desktop.
- **Logic:** all rules in `game/rules/` as scripts extending `RefCounted`. Randomness only through `rules/seeded_rng.gd`.
- **Data:** content as JSON in `game/content/`; canon as YAML in `canon/`, outside the Godot project.
- **Tests:** the in-repository runner `game/tests/run_tests.gd`. No test add-on.
- **Data checks:** Python 3.9 or newer in `.venv`, with PyYAML, jsonschema and Pillow.
- **Commands:** `./ov`.

**Consequences.**

- No add-ons are installed. Adding one needs a new decision record.
- `*.uid` and `*.import` files are committed; `game/.godot/` is not.
- Checking a scene by eye needs a desktop session, because `./ov shot` opens a window.
- iOS Simulator export may not be available in Godot; phone checks rely on real devices and, on Apple Silicon, running the exported project on the Mac from Xcode. Confirm against the current Godot documentation at milestone 2.
- The generator in `seeded_rng.gd` must not change once saves exist; its first values are pinned by a test.

**Changed by 0003:** the game is now a role-playing game in three modes, and dungeons use Godot 3D in the same renderer, drawn at 320 by 180. Everything else here stands.

**Replaces:** an earlier plan based on TypeScript, Phaser and Capacitor, which was never built.
