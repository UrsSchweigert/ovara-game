# Milestone 0: canon and foundations

Turn the prose into data and put the checks in place. Nothing playable is built here. The five task files in `tasks/backlog/` give the detail for each requirement and are part of this specification.

Read with `PLAN.md`, `CLAUDE.md` and, for anything about quests or places, `docs/design/quests.md`. Lanes and path limits are in `CLAUDE.md`, "Working under the harness".

| ID | Requirement | Description |
| :--- | :--- | :--- |
| **M0.1** | **Ingest canon** | Carry out `tasks/backlog/M0-01-ingest-canon.md`: one YAML entry per place, person, faction, power, machine, creature, plant, event and thing in the three sources under `canon/source/`, the 18 chapter state files, `world.distances` and `world.physical`. Lane: canon keeper. Only `canon/` may change, and never `canon/source/`. |
| **M0.2** | **Validators** | Carry out `tasks/backlog/M0-03-canon-validators.md`: canon schema, reference, glossary, chapter and flag checks in `tools/checks.py`, JSON schemas under `tools/schemas/` for every kind of content, and the generated `canon/index.md`. Lane: rules engineer. |
| **M0.3** | **Writing guide** | Carry out `tasks/backlog/M0-04-style-guides.md`: `docs/style/writing.md`. Lane: content author. |
| **M0.4** | **Art foundations** | Carry out `tasks/backlog/M0-05-art-foundations.md`: the 64-colour master palette, `docs/style/art.md`, the art check, and the placeholder generator for tiles, figures, portraits, dungeon textures and things. Lane: art director for `game/assets/` and `docs/style/art.md`; rules engineer for the check in `tools/`. |
| **M0.5** | **Canon proposals answered** | Every file in `canon/proposals/` has a recorded answer. Workers may draft the entry that would follow from a yes; the yes itself is the owner's. |

## Gate

`./ov check` passes with the real validators in place of the placeholders. The owner spot-checks 20 canon entries against the world bible and approves the palette from a picture.

## Needs the owner

- Approving the palette (a visual judgement).
- Answering canon proposals, starting with `P-001`.
- Spot-checking the ingested canon.
