# 0002: Walkable hubs and side quests

**Replaced in part by 0003.** Places are now areas on square tiles in a role-playing game. The limits on side quests below still hold.

**Context.** The first plan had single-screen hubs where the player taps people. The owner wants to walk around places, and to add side quests and more people later.

**Decision.**

- Hubs are walkable maps on the battle grid: same hexes, view, figures and path-finding. Up to 24 by 16 hexes, camera follows the hero, grid hidden.
- Movement is tap to walk. No virtual stick.
- Hubs, people and side quests are JSON in `game/content/hubs/` and `game/content/quests/`. Story state lives in `game/rules/`.
- Side quests are optional, built from five step kinds, and close when their chapters pass. They never grant an ability early, never gate the main path, and never add world facts without a canon proposal.
- The main path of a chapter block is finished before its side quests are written.
- A hub walker in `./ov check` proves every person and exit is reachable and every quest can be finished.

**Consequences.**

- Milestone 1 must include path-finding. Milestone 4 is larger: hubs, journal, quest system, one sample quest.
- Figures need four facings (two drawn, two mirrored).
- Hubs need tiles and standing sprites, not one painted picture each.
- There is still no world map to walk: travel between places is a choice of destination.
