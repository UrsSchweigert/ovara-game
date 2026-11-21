# Art direction: the owner's brief

This is the brief for how Ovara looks. It is short on purpose. The art director turns it into the working guide, `docs/style/art.md`, with exact colour values (task M0-05). If the two ever disagree, this file wins until the owner changes it.

## The reference

The look takes its inspiration from *Albion*, the role-playing game Blue Byte released in 1995. Look at screenshots of it before doing any visual work. What matters about it for us:

- You see its world from above at a slant, drawn by hand in pixels, with small, sturdy, readable figures.
- The planet is lush and alive, with buildings that look grown. The mining ship the humans arrive on is cold metal. The contrast carries the story.
- People speak in framed panels with a painted portrait beside the words.
- The interface looks like made objects: carved, bound, inlaid.
- The colours are few and rich, and shading is done with dither and with shifts of hue.

That contrast is our story too. Mariners live in grown, curved, lit places. Agravars live in steel.

## What we take, and what we do not

We take its **structure** (a world walked from above, dungeons in first person, battles on a small grid) and its **principles**: the viewpoint, the density, the contrast of living and industrial, portraits, a crafted interface, a small palette, a world that moves.

We take **nothing else**. Do not copy, trace, recolour or closely imitate any sprite, tile, portrait, interface graphic, font, character, creature, building or name from *Albion* or from any other game. Do not reproduce its screens' layout. If a piece of our art could be mistaken for a piece of theirs, redo it.

## The view

- **Two views.** Exploring and battles are oblique, from above and slightly south, and share their figures. Dungeons are first person.
- **Base resolution 640 by 360 pixels.** The game is drawn at that size and scaled up to the device without smoothing. Never draw at another scale and shrink.
- **Exploring tiles** are squares of **32 by 32 pixels**. Twenty columns and eight rows show above a 96-pixel interface band. Walls, furniture and tall things are sprites standing on tiles, drawn in row order, so the party can pass behind them.
- **Battle hexes** are pointy-top, drawn squashed to fit the view: **64 pixels wide, 48 high**, rows 36 pixels apart. Nine columns and seven rows fit in 640 by 264, leaving a 96-pixel band for the interface.
- **Figures stand upright** on their hex, about 32 wide and 48 high, anchored at the centre of the hex's lower edge. Large things (a needle, a gunboat, a ray) cover several hexes and are drawn as one sprite.
- **Light comes from the upper left** on the surface and in dry halls. Under water, light comes from above and from whatever glows.
- **Depth order** is by row: things lower on the screen are drawn over things higher.

## Colour

- **One master palette of 64 colours** for the whole game, held in `game/assets/palettes/`. Every image uses only those colours. A script checks it.
- Each region uses a **subset of about 16**: see the region table in `PLAN.md` section 8.
- Transparency is all or nothing. No soft edges, no glows made with alpha; a glow is drawn with lighter pixels and dither.
- Shade by shifting hue as well as brightness: shadows lean toward blue-green under water and toward violet on land; lights lean warm.
- No pure black outlines. Outline with the darkest colour of the thing's own ramp, and only where the figure meets a busy background.
- No gradients, blur, bloom or smooth scaling anywhere, including the interface.

## Whose ground it is

| Belongs to | Shapes | Materials | Colours | Light |
|---|---|---|---|---|
| **Mariners** | Curves, terraces, things tied and woven | Sea-silk, shell, cord, fitted stone, kelp | Grey-green, brass, gold | Soft, from lamps and lampweed |
| **The Makers** | Seamless arcs and ribs, nothing straight, nothing joined | Pale glass, white metal | White, milk, a faint inner blue | Steady and white, from within |
| **Agravars** | Straight lines, grids, stacks, signs | Riveted steel, rust, concrete, tarpaulin, glass | Rust, soot, wet grey, with neon magenta, orange and electric blue | Hard, coloured, flickering |
| **Meridian** | The same, with everything taken off | Smooth grey, no rivets, no lettering | One grey | Flat |
| **The rays and the Wells** | Long slow shapes | Living skin, black stone | Black, bone, ember red or lantern blue | Their own, and slow |

A player should know whose ground a map is on before reading a word.

## Water states

Water state is the heart of the game. Each state is told apart by **pattern and movement as well as colour**, so that it reads on a small screen and for players who cannot tell colours apart.

| State | Colour | Pattern | Movement |
|---|---|---|---|
| Clean | The region's own water colour | Sparse light flecks | Flecks drift slowly |
| Fouled | Brown over the region colour | Diagonal dither bands, dark motes | Motes sink |
| Deaf | Flat grey, drained of the region colour | None, with a dotted edge where it meets other water | **None at all.** It is the only thing on the map that never moves |
| Orphan | Pale, slightly green | A fine square grid, like tile | A slow slosh at the edges only |
| Storm | Dark slate with white | Streaks along the wind | Fast |
| Well | Deep black-blue with gold | Concentric rings | Rings widen slowly |

## Figures

- Tell factions apart by **outline shape first**, colour second: mariners are long-limbed and unarmoured; agravar divers are squat and helmeted; the Threaded lie along their needles; the fouled have no clear edge.
- The hero is the only figure who wears both: sea-silk, and a worn tool at his belt.
- Four frames for standing, six for moving, drawn on a shared timing so the whole map breathes together. Figures are drawn facing down-left and up-left, and mirrored for the right: four facings from two sets of frames, enough for walking a hub.
- Out of the fight is a kneeling or drifting pose, never a corpse, unless the story says a death happened.

## Portraits and dialogue

- Every speaking character has a **96 by 96** portrait in the master palette: head and shoulders, three-quarter face, one clear feature that survives being small (Jef's apron strap, Maelis's patched coat, Rook's high collar, Sefa's grey band).
- Dialogue appears in a framed panel across the lower part of the screen, portrait on the speaker's side, at most three short lines at a time.
- The rays never have a text panel. What they show is drawn: a picture panel with no words.

## Interface

- It is made of **objects**. Mariner screens are framed in shell and pale glass with cord bindings. Agravar screens are riveted steel with dim green or amber readouts. The frame changes with whose ground the chapter is on.
- Ebb is shown as a vessel emptying, not a bar filling.
- Text is a pixel font at least 12 pixels tall at base resolution. Nothing is written smaller.
- Every touch target is at least 44 base pixels across, or a whole hex.

## Exploring maps

Most of the game is seen this way: holds, terraces, kelp forest, ports, decks and streets, built from 32-pixel tiles and standing sprites.

- **Each place is composed.** What the player sees on arriving should say whose place this is and what state it is in, before a word is read.
- **Places change.** An area is redrawn by swapping tiles and sprites from data when its flags change: Low Anthem before and after the charges, lamps dark and lamps lit. Never paint an area as one fixed picture.
- **Under water and on land look different without a label:** under water, light falls in moving nets, hair and cloth drift, and nothing casts a hard shadow. On land, shadows are hard and rain falls.
- **People who can be spoken to carry a small mark** above the head, in the frame's own material. The mark for the main quest differs from the mark for a side quest and from a shop's, by shape as well as colour. There is no hover, so nothing is found by pointing.
- **Things that can be examined glint** on the shared timing.
- **The interface stays out of the way:** journal, party, pack and map buttons, each 44 pixels, in the corners. The dialogue panel covers the lower band only while someone is speaking.

## Dungeons

Dungeons are first person and must look like the same game.

- **Walked freely, kept level.** The party moves and turns smoothly, so walls are seen at every angle and distance: textures must hold up close to, and repeat cleanly far off. There is no looking up or down.
- **Drawn at 320 by 180** and scaled up twice, with no smoothing. Textures are 32 by 32 or 64 by 64 pixels, in the master palette, with no filtering and no mip blending.
- **Flat light.** No real-time shadows, no bloom, no fog gradients. Distance is shown by stepping the texture down the palette ramp in bands, and by darkness beyond the lamp's reach.
- **People and creatures are flat figures** that turn to face the party, drawn in the same style as the portraits and at whole-pixel sizes.
- **Whose place it is** follows the same table as everywhere else: ribs and pale glass for the Makers, riveted plate and stencilled numbers for the islanders, fitted stone and hung weed for mariner work, block on block of black stone for the Hush.
- **Water is the material that matters.** A flooded stretch has drifting motes and a soft green or blue cast; a dry stretch is sharp and still. Orphan water in tanks and pipes shows its tiled grid. Deaf water does not move at all.
- **Light is a resource.** A lamp or a strand of lampweed lights a few cells. A Maker lamp that the party lights stays lit, and the map remembers it.
- **The frame** round the first-person view is the interface for that ground, with a compass, the party's four portraits with their ebb vessels, and the automatic map.

## Things

Every thing that can be carried has a 24 by 24 picture in the master palette and reads at a glance as mariner-made, Maker-made or island-made.

## Placeholders

Until milestone 7 every asset is a placeholder, and placeholders obey every rule above: final size, final anchor, palette colours only. A placeholder figure is a flat silhouette in its faction's colours with a two-letter label. A placeholder tile is a flat hex with its water pattern. They are generated by a script, so they can be regenerated when the palette changes.

Each asset has a brief in `game/assets/briefs/`: what it is, its canon ID, its size, which colours, and one sentence on what must be recognisable. Whoever makes the final art works from the brief.
