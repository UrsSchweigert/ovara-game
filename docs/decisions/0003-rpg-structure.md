# 0003: The game is a role-playing game in three modes

**Context.** The first plan was a mission-based tactics game with walkable hubs (0002). The owner wants the structure of *Albion*: a world walked from above, dungeons in first person, battles on a grid, a party, things to find and trade, skills to train, and quests in place of missions.

**Decision.**

- Three modes over one game state: exploring (32-pixel square tiles, from above), dungeons (first person, 3D, free movement and turning, on levels built from a square grid of cells), battles (hex grid, 9 by 7 visible).
- A party of the hero and up to three, with a base in the Dragon's gallery.
- Quests are fetch, discover or puzzle. Battles happen inside and between them. The main quest has one stage per place, with a clearing condition and flags. It is written in `docs/design/quests.md`.
- Skills have five steps of mastery, gained by practice and a teacher. The hero's reach is fixed at 5; mastery is his control.
- Ebb is carried out of battle and goes only with rest.
- Fast travel is the needle, the Dragon and Dace's boat, and follows the story.
- Cut scenes are data, played with the game's own graphics.

**Consequences.**

- 0002 is replaced: areas use square tiles, not hexes. Its limits on side quests still hold.
- The game is larger. Milestones 2 to 4 prove each mode on a phone before content is written.
- Dungeons use Godot 3D in the Compatibility renderer at 320 by 180.
- Free movement is the one place where a scene decides something: where the party stands inside a cell. The rules still decide everything that matters, and act when the party enters a cell, opens a door or uses a thing.
