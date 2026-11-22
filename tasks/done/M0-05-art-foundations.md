# M0-05: Art guide, master palette, art check and placeholders

- **Role:** art-director (the art check itself is written with the rules engineer; see Scope)
- **Milestone:** M0
- **Depends on:** M0-01, M0-02

## Goal

Fix the look before any scene is built. After this task there is one palette, a working guide, a script that rejects any image that breaks the rules, and a first set of placeholder tiles and figures in the final view, sizes and colours.

## Canon to read

- `docs/style/art-direction.md` (the owner's brief; all of it)
- Region entries under `canon/places/` and their `look` fields
- `canon/powers/` entries for the six water states
- `PLAN.md` section 8, "Region look"

## Scope

- In:
  - Study the reference. Look at screenshots of *Albion* (Blue Byte, 1995) and write, at the top of `docs/style/art.md`, five observations about how its pictures work that we will apply. Do not save, trace or reuse any of its images.
  - **Master palette:** 64 colours as `game/assets/palettes/ovara.json` (name, hex value, ramp) and a swatch image. Each of the five regions gets a named subset of about 16.
  - **`docs/style/art.md`:** the working guide. Palette and region subsets as hex values; how each water state is drawn (colour, pattern, movement); outline shapes by faction; frame counts and timing; interface materials for mariner and agravar screens; portrait rules. Concrete values, not adjectives.
  - **Manifest:** `game/assets/manifest.json` and its schema in `tools/schemas/`: key, path, kind, canon ID, size, frames, placeholder.
  - **Placeholder generator:** a Python script under `tools/` that writes, from the palette: one hex tile per water state per region (64 by 48, with its pattern), and one figure silhouette per faction (32 by 48, with a two-letter label). It also writes the manifest entries.
  - **Art check**, replacing the placeholder in `tools/checks.py` (a task for the rules engineer if you cannot edit `tools/`): every image under `game/assets/` uses only palette colours with all-or-nothing transparency, has the size its kind requires, and is in the manifest; every manifest entry points to a file that exists.
  - One brief in `game/assets/briefs/` for each placeholder made.
- Out: no final art. No scenes. No change to the sizes or the view in the brief.

## Acceptance

- [ ] `./ov check` passes, and an image with one off-palette pixel makes it fail and names the file.
- [ ] Every region and every water state has a tile; the six water states can be told apart in a greyscale copy of the swatch sheet.
- [ ] A contact sheet of all placeholders, `shots/placeholders.png`, is named in the Result for the owner to approve.
- [ ] `docs/style/art.md` does not contradict `docs/style/art-direction.md`.
- [ ] Nothing in `game/assets/` is taken from another game.

## Result

Done in these commits: the palette and guide in `4fedebc`, `2a1aa50` and `ef23ebe` (merged as `a41f8f4`); the manifest schema and art check in `906e24e` (merged as `ed6558f`); the placeholder generator and its tiles, figures, textures and things in `be16701`, `3a0ec5a`, `07481ee`, `6294ba4`, `cc6a4bc`, `1c35081` and their merges; the review pictures, moved from `shots/` to `docs/review/` in `1dc2b6a`. Facts from the repository:

- **Palette:** `game/assets/palettes/ovara.json`, with a swatch `ovara-swatch.png`. Keys are `name`, `size`, `colours`, `ramps`, `subsets`, `water`, `region_water` and `region_pattern`.
- **Guide:** `docs/style/art.md`, with five observations about the reference at the top, region subsets, water states, outlines, frames, portraits and a manifest section.
- **Manifest:** `game/assets/manifest.json`, 73 entries: 30 tiles, 16 dungeon textures, 8 figures, 8 exploring tiles, 7 portraits and 4 things. Each entry has `path`, `kind`, `canon` and `brief`.
- **Art check:** passes in `./ov check` at this revision.
- **Contact sheet:** `docs/review/placeholders.png`. The task asked for `shots/placeholders.png`; the file was moved to `docs/review/` in `1dc2b6a`, so that is the path to approve. The dungeon picture is `docs/review/dungeon-placeholder.png`.

**Pending the owner:** approval of the master palette and the placeholder contact sheet, `docs/review/placeholders.png`. Nothing here is a visual check: no one has looked at the pictures on a phone, and I did not look at them in this session. The greyscale test (six water states told apart) was not run by me.

## Verification

- `bash ov check` at this revision: `art: 0 error(s), 0 warning(s)`, `CHECK PASSED`.
- Not done: the greyscale distinguishability check and looking at `docs/review/placeholders.png`.

## Added by decision 0003

- The placeholder generator also makes: 32-pixel square tiles for exploring (floor, wall, water by state); a set of 32-pixel dungeon textures (Maker, island, mariner, the Hush) for walls, floors, ceilings and doors; and 24-pixel pictures for things.
- The art check also knows these kinds and their sizes.
- Deliver one dungeon screenshot built from the placeholder textures at 320 by 180, scaled up twice.
