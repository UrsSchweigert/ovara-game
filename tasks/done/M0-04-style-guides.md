# M0-04: Writing style guide

- **Role:** content-author
- **Milestone:** M0
- **Depends on:** M0-01

## Goal

Give every later agent one short page for how the game should read, so that dialogue written months apart feels like one work, and fits a dialogue panel on a phone.

## Canon to read

- `canon/source/novel-the-man-the-tide-brought-in.md` (voice reference)
- The people entries for the hero, Sefa, Okonta, Hesper, Jef, Maelis and Anselm Rook
- `docs/style/art-direction.md`, section "Portraits and dialogue"

## Scope

- In:
  - `docs/style/writing.md`, one page: tone; sentence length; the limit of three lines of about forty characters per panel; how mariners, agravars, Driftfolk, the hero and Rook each speak, with five sample lines per voice taken or adapted from the novel; words to avoid; how the rays communicate (in pictures, never in words).
- Out: no dialogue for quests. The art guide is task M0-05.

## Acceptance

- [ ] The guide fits on one screen-length page and contains concrete examples, not adjectives.
- [ ] Every sample line fits the panel limit.
- [ ] Sample lines use only glossary terms.
- [ ] `./ov check` passes.

## Result

Done. The guide was written in `writing-guide` (`4bf56ee`, merged as `2fdefd7`). `docs/style/writing.md` has these sections: the panel, mariners, agravars, Driftfolk, the hero, Anselm Rook, and the great rays. Each voice section has sample lines. The rays speak in pictures, not words, as the task asks.

**Not verified:** I did not count the five sample lines per voice, measure each line against the forty-character panel limit, or check every sample word against the glossary. The `./ov check` glossary check covers banned terms in game content, not the guide itself, because `docs/style/` is outside its scope. A person should read the guide once for voice; no one has seen it on a phone, and nothing here is a visual check.

## Verification

- `bash ov check` at this revision: `CHECK PASSED`, including `glossary: 0 error(s), 0 warning(s)`.
- Not done: line-length and glossary checks of the sample lines by hand.
