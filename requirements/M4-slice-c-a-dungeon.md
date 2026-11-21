# Milestone 4: slice C, a dungeon

The first-person mode. See `PLAN.md` section 2 (Dungeons), decision 0003 and the Dungeons section of the art brief.

Read with `PLAN.md`, `CLAUDE.md` and, for anything about quests or places, `docs/design/quests.md`. Lanes and path limits are in `CLAUDE.md`, "Working under the harness".

| ID | Requirement | Description |
| :--- | :--- | :--- |
| **M4.1** | **Dungeon rules** | Levels as text grids; cells, walls on edges, doors, seams, switches, flooded and dry cells, lamps; the automatic map as data; what happens on entering a cell. |
| **M4.2** | **Dungeon scene** | Godot 3D in the Compatibility renderer at 320 by 180, scaled up twice; levels built from the grid by script; free movement by touch with tap to walk; level view; flat figures. |
| **M4.3** | **Two dungeons** | The flooded third of Low Anthem (stage 2) and a wreck in the Tangle (stage 3), as content. |
| **M4.4** | **Walker for dungeons** | Every cell that should be reachable is, in every flag state. |

## Gate

The owner walks both dungeons on a phone and can always tell where they are.

## Needs the owner

- Manual tests of touch control and comfort on a phone. This is the riskiest mode: expect several rounds.
