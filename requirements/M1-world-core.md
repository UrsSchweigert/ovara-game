# Milestone 1: world core

The game's logic with no screen: `game/rules/` only, tested headless. See `PLAN.md` section 2 and decision 0004.

Read with `PLAN.md`, `CLAUDE.md` and, for anything about quests or places, `docs/design/quests.md`. Lanes and path limits are in `CLAUDE.md`, "Working under the harness".

| ID | Requirement | Description |
| :--- | :--- | :--- |
| **M1.1** | **World state** | One typed world state: party, base, sheets (attributes, Reach, skills, traits), packs, supplies, ebb, flags, chapter, calendar, journal, position and mode. Saved and loaded as versioned JSON. |
| **M1.2** | **Areas and walking** | Square-tile areas loaded from JSON: path-finding, exits, who can go where by trait, things to use, encounters seen before met, Listen, light. |
| **M1.3** | **People and topics** | People with topics by chapter and flag; the speaking mark; the topic list. |
| **M1.4** | **Quest engine** | Steps of kind fetch, discover and puzzle; clearing conditions; flags set; points awarded; the journal; closing rules. |
| **M1.5** | **Deciding things** | The one function for value, modifiers, difficulty and margin; seeded dice drawn and stored when an act is chosen. |
| **M1.6** | **Text printer** | `./ov map <id>` prints an area as text. |
| **M1.7** | **Walker and auto-player** | The walker reaches every person, thing and exit of every area in every flag state. The auto-player plays stage 1 of the main quest to its end. Both run in `./ov check`. |
| **M1.8** | **Stage 1 as data** | Stage 1 of `docs/design/quests.md` as content: the areas of Low Anthem, its people, dialogue, topics and quest steps. Lane: content author. |

## Gate

Chapter 1 of the main quest is played to its end by the script in the terminal, and `./ov check` passes.

## Needs the owner

- Nothing visual. Canon proposals for unnamed people who now have lines.
