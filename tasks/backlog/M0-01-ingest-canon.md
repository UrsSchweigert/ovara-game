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

## Verification
