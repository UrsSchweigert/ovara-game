# M0-03: Canon validators and index generator

- **Role:** rules-engineer
- **Milestone:** M0
- **Depends on:** M0-01, M0-02

## Goal

Make consistency a machine check. After this task, a broken reference, a banned word or a malformed canon entry fails `./ov check`.

## Canon to read

- `canon/README.md`
- `canon/glossary.yaml`
- Three or four entries of different types, as examples

## Scope

- In, all in Python under `tools/`, replacing the placeholders in `tools/checks.py`:
  - **Schema validation** for every canon entry type and for chapter state files, with the schemas as JSON Schema files in `tools/schemas/`.
  - **Reference check:** every ID used in `links`, `region`, chapter files and any `"canon"` field in JSON under `game/content/` must exist and not be retired.
  - **Glossary check:** any banned term found in `game/content/` or in player-facing strings in scripts and scenes under `game/scenes/` and `game/ui/` fails, with file and line. `canon/source/` is exempt.
  - **Placeholder check:** any `TODO-CANON` under `game/` fails.
  - **Chapter check:** an area, dungeon, battle, dialogue, quest, shop or cut-scene file tagged with a chapter may only use people marked alive and available in that chapter's state file, and only hero abilities listed there.
  - **Content schemas:** JSON Schema files for every kind under `game/content/` (listed at the end of this task), including the text-row format and legend for areas, dungeon levels and battle maps. Every file under `game/content/` must validate. Agree the formats with `.claude/agents/content-author.md`.
  - **`./ov index`:** generates `canon/index.md`, grouped by type, one line per entry: ID, name, summary.
  - Tests for the checks themselves, in Python, run as part of `./ov check`.
- Out: no changes to canon entries. If an entry fails validation, write a task for the canon keeper. The art check is task M0-05.

## Acceptance

- [ ] Each check has a test that feeds it a deliberately broken fixture and sees it fail with a useful message.
- [ ] `./ov check` passes on the real canon, or the failures are listed as tasks for the canon keeper.
- [ ] `canon/index.md` is generated and under 400 lines.
- [ ] The checks run with only the packages pinned in `tools/requirements.txt`.

## Result

## Verification

## Added by decision 0003

- **Schemas** are needed for every kind under `game/content/`: areas, dungeons, battles, units, abilities, skills, items, shops, people, dialogue, quests and cut scenes. Take the fields from `PLAN.md` section 2 and `.claude/agents/content-author.md`.
- **Flag check:** collect every flag that content reads and every flag that content sets. Fail if one is read and never set, or if a flag is not in `docs/design/quests.md`.
- **Traits** (decision 0004) are canon entries and need a schema: an ID, who has it in which chapters, and what it opens, closes or forbids.
