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

Done. The checks were built in `val-canon-schemas-refs` (`acd79cf`), `val-glossary-chapter` (`7c5506c`), `content-map-schemas` (`4d18784`), `content-story-schemas` (`ddb24b3`), `content-sheet-schemas` (`98453e6`) and `val-flag-check-index` (`6da1f89`), all merged on `main`. Facts from the repository:

- **Schemas:** 19 JSON Schema files in `tools/schemas/` (canon entry, canon chapter, canon trait, asset manifest, and content kinds: ability, area, battle, cutscene, defs, dialogue, dungeon, item, person, quest, shop, skill, teacher, trait, unit), plus a README.
- **Checks in `tools/checks.py`:** canon schema, reference, glossary, `TODO-CANON`, chapter, flag and content checks, run by `./ov check`.
- **`./ov index`:** generates `canon/index.md`, which is 216 lines, under the 400-line limit.
- **Tests:** Python tests in `tools/tests/` (`test_canon.py`, `test_chapters.py`, `test_content.py`, `test_flags.py`, `test_glossary.py`, `test_art.py`, `test_placeholders.py`), run as part of `./ov check`.
- **Python packages:** pinned in `tools/requirements.txt` (PyYAML, jsonschema, pillow).

**Not verified:** I did not separately confirm that each check has a deliberately broken fixture that fails with a useful message, beyond the test files existing and passing. The check on the real canon passes, so no canon-keeper tasks were needed for it.

## Verification

- `bash ov check` at this revision: 102 tests `OK`, `canon: 0 error(s), 0 warning(s)`, `glossary: 0 error(s), 0 warning(s)`, `references: 0 error(s), 0 warning(s)`, `CHECK PASSED`.
- Not done: running each check against a broken fixture by hand.

## Added by decision 0003

- **Schemas** are needed for every kind under `game/content/`: areas, dungeons, battles, units, abilities, skills, items, shops, people, dialogue, quests and cut scenes. Take the fields from `PLAN.md` section 2 and `.claude/agents/content-author.md`.
- **Flag check:** collect every flag that content reads and every flag that content sets. Fail if one is read and never set, or if a flag is not in `docs/design/quests.md`.
- **Traits** (decision 0004) are canon entries and need a schema: an ID, who has it in which chapters, and what it opens, closes or forbids.
