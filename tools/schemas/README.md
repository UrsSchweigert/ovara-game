# Content schemas

Stage 1 additions (all optional, so older content stays valid):

- **Area:** `spawn`, `exits` (`cell`, `to`, `to_cell`, `when`), `things` (`canon`, `cell`, `hidden.trait`, `when`),
  `encounters` (`cell`, `battle`, `when`), `light` (0 to 1), `trait_access` (cells only a trait holder may enter),
  `variants` (`when` plus replacement `rows`, `things`, `exits`). A legend glyph with `blocks: true` cannot be walked on.
- **Person:** `area`, `cell`, `topics` (`topic` canon id, `dialogue` id, `when` chapter or flag condition).
- **Dialogue topic:** `sets` (flags), `next` (topic ids). A panel still holds at most three lines.
- **Quest step:** `kind` (fetch, discover, puzzle), `area`, `requires` (condition), `sets` (flags).

Step completion lives in quest state, not in flags. Flags are only those under **Sets:** in `docs/design/quests.md`.
`tools/ovcheck/content.py` checks that cells lie inside the grid and are reachable from `spawn`, that exits, people and
topics name existing content, and that canon ids exist.
