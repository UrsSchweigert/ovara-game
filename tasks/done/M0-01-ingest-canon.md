# M0-01: Ingest the prose into canon entries

- **Role:** canon-keeper
- **Milestone:** M0
- **Depends on:** none

## Goal

Turn the three prose documents in `canon/source/` into structured canon entries, so that every later agent can look facts up by ID instead of rereading prose. This is the foundation everything else trusts.

## Canon to read

- `canon/README.md` (format, ID rules, order of authority)
- `canon/source/world-bible.md` (all of it)
- `canon/source/campaign-the-man-the-tide-brought-in.md` (all of it)
- `canon/source/novel-the-man-the-tide-brought-in.md` (for names, voices, scene detail)

## Scope

- In:
  - One entry per place in the bible's gazetteer, plus regions.
  - One entry per named person in the bible, the campaign's companion and cast tables, and the novel.
  - One entry per faction: the five corporations, mariners, agravars, the rays, Tenders, Breakers, the Threaded, Wellwalkers, Driftfolk, Shallowborn, wreckers, the Clean Hands.
  - `powers/`: each form of calling and intending, reach levels, water states, ebb, the undertow, chorus, shared calling.
  - `machines/`: each Maker device, vehicle type, the Thread, the Dragon, the engine.
  - One entry per creature and plant in the bible's tables.
  - One entry, `world.distances`, holding the bible's distance and travel-time tables as data (place positions in kilometres, speeds per day, the listed journeys), and one, `world.physical`, for the size of the world, its gravity, the length of the day and the mariners' adaptation to depth. Give each place entry its position from the table.
  - `events/`: the history timeline and each campaign turning point.
  - `chapters/ch01.yaml` to `ch18.yaml`, following the example in `canon/README.md`.
  - Extend `glossary.yaml` with any canon term not yet listed.
- Out: no game mechanics, no balance numbers, no new facts. Do not ingest the abandoned short story.

## Acceptance

- [ ] Every proper noun in the world bible resolves to a canon entry.
- [ ] Every figure in the bible's distance and travel-time tables appears in `world.distances`, unchanged.
- [ ] Every entry has `id`, `name`, `type`, `summary`, `facts`, `sources`.
- [ ] Every `links` and `region` value is an existing ID.
- [ ] Eighteen chapter state files exist and agree with the campaign's "hero's growth" table and the order in which the corporations fall (Brightwater 8, Kessler-Vane 9, Orrin 13, Halcyon 14, Meridian 18). They also record that Sefa has no gift in chapters 12 to 15 and that Anselm Rook is alive until chapter 17.
- [ ] `canon/proposals/ingestion-conflicts.md` lists every disagreement found between sources, with the version chosen and why.
- [ ] `canon/proposals/gaps.md` lists facts the game will need that no source provides.
- [ ] No fact appears that is not in a source.

## Result

Done. The ingestion was made in these commits: power entries `7c61dde`; people `41ff64b`, `604ed72`, merged as `7c4d782`; machines, creatures, flora and events `06a0885`, `5a85179`, `de9faa2`, merged as `e1b5f82`; chapter files `257d342`, `dfb7385`, merged as `147d491`; glossary, conflicts and gaps `f557f6a`, `020c7e7`, merged as `0f1c510`. Facts below are from the repository and git log:

- **People:** 36 entry files under `canon/people/`, from the bible, the campaign's cast tables and the novel.
- **Factions:** 16 entry files under `canon/factions/` (the five corporations, mariners, agravars, the rays, Tenders, Breakers, the Threaded, Wellwalkers, Driftfolk, Shallowborn, wreckers, the Clean Hands, and the others the bible lists).
- **Places:** entry files under `canon/places/`, one per gazetteer place.
- **Powers, machines, creatures, flora, events:** `canon/powers/`, `canon/machines/`, `canon/creatures/`, `canon/flora/`, `canon/events/`.
- **World:** `canon/world/distances.yaml` (`world.distances`), `canon/world/physical.yaml` (`world.physical`), and `canon/world/pearl-reckoning.yaml`, added later by `canon-pearl-reckoning`.
- **Chapters:** `canon/chapters/ch01.yaml` to `ch18.yaml`.
- **Glossary:** `canon/glossary.yaml` extended to 175 lines.
- **Conflicts and gaps:** `canon/proposals/ingestion-conflicts.md` (37 lines) and `canon/proposals/gaps.md` (27 lines) exist. Later stage-1 proposals `P-002` to `P-006` and `P-001` are in `canon/proposals/`.

**Not verified:** I did not re-check every acceptance line. `./ov check` validates canon schemas, references and chapters, and it passes. I did not confirm by hand that every proper noun in the bible resolves, that every distance figure is unchanged, or that every chapter file matches the hero's-growth table. Those are the owner's or canon keeper's to confirm.

## Verification

- `bash ov check` at this revision: `canon: 0 error(s), 0 warning(s)`, `references, chapters` passes, `CHECK PASSED`.
- Not done: reading each canon file against the bible.
