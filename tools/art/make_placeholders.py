#!/usr/bin/env python3
"""Writes placeholder art for Ovara: the water tiles of each region, eight faction
figures, four generic things, their briefs, their manifest entries and a contact
sheet for the owner to look at.

Usage: python3 tools/art/make_placeholders.py

Reads game/assets/palettes/ovara.json (from make_palette.py). Output is
deterministic and idempotent: running it again changes nothing. These are
placeholders, not final art.
"""
import json
from pathlib import Path
from typing import Optional

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
# region key -> canon place id; the key names the files and matches the palette's region_water
REGIONS = {"pale": "place.the-pale", "anthem": "place.anthem-waters", "girdle": "place.the-girdle",
           "shelves": "place.bright-shelves", "quiet": "place.the-quiet"}
REGION_NAMES = {"pale": "Pale", "anthem": "Anthem", "girdle": "Girdle",
                "shelves": "Shelves", "quiet": "Quiet"}  # short names for briefs
STATES = ["well", "storm", "fouled", "clean", "deaf", "orphan"]  # dark to light, art.md
TILE_W, TILE_H = 64, 48  # battle hex, pointy-top
SCALE, COLS, PAD = 2, 8, 8  # contact sheet: twice size, eight to a row
FIG_W, FIG_H = 32, 48  # figures stand on the hex, feet on the bottom row at x 16
THING_SIZE = 24
LABEL_X, LABEL_Y = 12, 21  # two-letter label at chest height
NEIGHBOURS = ((1, 0), (-1, 0), (0, 1), (0, -1))

# Shapes are integer tests: ("box", x0, y0, x1, y1), ("disc", cx, cy, r), ("ring", cx, cy, r0, r1),
# ("ellipse", cx, cy, rx, ry), ("trap", cx, y0, y1, w0, w1) with half-width growing from w0 to w1.
# The first shape that hits a pixel gives it that part's colour. Outline and rim apply to edge pixels.
# Figure colours are palette names (art.md, "Outlines by faction"). Meridian has no lettering (art.md).
FIGURES = {
    "mariners": {"canon": "faction.mariners", "parts": {"head": "sand-5", "body": "deep-3"},
                 "outline": "deep-0", "ink": "sand-7", "label": "MA",
                 "note": "long-limbed, unarmoured, cloth and cord hanging",
                 "shapes": [("head", ("disc", 16, 6, 3)), ("body", ("box", 13, 10, 19, 25)),
                            ("body", ("box", 9, 11, 11, 28)), ("body", ("box", 21, 11, 23, 28)),
                            ("body", ("box", 13, 26, 15, 47)), ("body", ("box", 17, 26, 19, 47))]},
    "agravars": {"canon": "faction.agravars", "parts": {"head": "stone-5", "body": "stone-3"},
                 "outline": "stone-0", "ink": "brass-6", "label": "AG",
                 "note": "squat, helmeted, blocky, straight edges",
                 "shapes": [("head", ("box", 11, 2, 21, 9)), ("body", ("box", 8, 10, 24, 34)),
                            ("body", ("box", 5, 12, 7, 30)), ("body", ("box", 25, 12, 27, 30)),
                            ("body", ("box", 9, 35, 15, 47)), ("body", ("box", 17, 35, 23, 47))]},
    "threaded": {"canon": "faction.threaded", "parts": {"head": "sand-5", "body": "kelp-3"},
                 "outline": "deep-0", "ink": "sand-7", "label": "TH",
                 "note": "long and low, lying along its needle",
                 "shapes": [("head", ("disc", 28, 33, 3)), ("body", ("box", 4, 30, 28, 38)),
                            ("body", ("box", 15, 39, 16, 47))]},
    "fouled": {"canon": "creature.the-fouled", "parts": {"head": "brass-3", "body": "brass-3"},
               "rim": ("brass-2", "brass-1"), "ink": "sand-7", "label": "FO",
               "note": "no clear edge, dithered rim, no outline",
               "shapes": [("body", ("disc", 16, 26, 11)), ("body", ("disc", 16, 38, 9))]},
    "makers": {"canon": "event.the-makers", "parts": {"head": "stone-7", "body": "stone-7"},
               "outline": "stone-2", "ink": "stone-0", "label": "MK",
               "note": "seamless arcs, nothing straight, outline stone-2 on pale glass",
               "shapes": [("body", ("ring", 16, 12, 6, 8)), ("body", ("ring", 16, 35, 11, 13))]},
    "meridian": {"canon": "faction.meridian", "parts": {"head": "stone-4", "body": "stone-4"},
                 "outline": "stone-0", "ink": None, "label": None,
                 "note": "one grey, hard edges, no rivets",
                 "shapes": [("head", ("box", 12, 2, 20, 10)), ("body", ("box", 8, 11, 24, 30)),
                            ("body", ("box", 9, 31, 14, 47)), ("body", ("box", 18, 31, 23, 47))]},
    "rays": {"canon": "faction.great-rays", "parts": {"head": "deep-4", "body": "deep-4"},
             "outline": "ember-0", "ink": "sand-7", "label": "RA",
             "note": "long slow shape with a trailing tail",
             "shapes": [("body", ("ellipse", 16, 22, 14, 8)), ("body", ("box", 15, 30, 17, 47))]},
    "hero": {"canon": None, "parts": {"head": "sand-5", "body": "deep-5", "tool": "brass-4"},
             "outline": "deep-0", "ink": "brass-6", "label": "HE",
             "note": "sea-silk shape with a worn tool at the belt",
             "shapes": [("head", ("disc", 16, 6, 3)), ("body", ("box", 15, 9, 17, 11)),
                        ("body", ("trap", 16, 12, 40, 4, 8)), ("body", ("box", 13, 41, 15, 47)),
                        ("body", ("box", 17, 41, 19, 47)), ("tool", ("box", 21, 24, 23, 27))]},
}
THINGS = {
    "weapon": {"parts": {"blade": "stone-6", "guard": "brass-4", "grip": "deep-2", "pommel": "brass-5"},
               "shapes": [("blade", ("box", 11, 1, 12, 16)), ("guard", ("box", 8, 16, 15, 17)),
                          ("grip", ("box", 11, 18, 12, 21)), ("pommel", ("box", 10, 22, 13, 23))]},
    "garment": {"parts": {"cloth": "deep-3", "trim": "deep-6"},
                "shapes": [("trim", ("box", 6, 21, 17, 21)), ("cloth", ("box", 6, 4, 17, 20))]},
    "supply": {"parts": {"crate": "brass-3", "band": "brass-1", "rim": "brass-2"},
               "shapes": [("band", ("box", 4, 13, 19, 14)), ("rim", ("box", 4, 6, 19, 7)),
                          ("crate", ("box", 4, 8, 19, 20))]},
    "key": {"parts": {"ring": "brass-5", "shaft": "brass-5", "tooth": "brass-4"},
            "shapes": [("ring", ("ring", 6, 11, 2, 4)), ("shaft", ("box", 10, 10, 20, 12)),
                       ("tooth", ("box", 17, 13, 18, 15)), ("tooth", ("box", 20, 13, 21, 14))]},
}
# 3 by 5 pixel letters for the figure labels
GLYPHS = {
    "A": [" # ", "# #", "###", "# #", "# #"], "E": ["###", "#  ", "###", "#  ", "###"],
    "F": ["###", "#  ", "###", "#  ", "#  "], "G": ["###", "#  ", "# #", "# #", "###"],
    "H": ["# #", "# #", "###", "# #", "# #"], "K": ["# #", "# #", "## ", "# #", "# #"],
    "M": ["# #", "###", "# #", "# #", "# #"], "O": ["###", "# #", "# #", "# #", "###"],
    "R": ["###", "# #", "###", "## ", "# #"], "T": ["###", " # ", " # ", " # ", " # "],
}


def assets_dir(root: Path) -> Path:
    return root / "game" / "assets"


def load_palette(root: Path) -> tuple[dict[str, tuple[int, int, int]], dict]:
    data = json.loads((assets_dir(root) / "palettes" / "ovara.json").read_text(encoding="utf-8"))
    rgb = {}
    for c in data["colours"]:
        h = c["hex"].lstrip("#")
        rgb[c["name"]] = (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    return rgb, data


def inside_hex(x: int, y: int) -> bool:
    """Pointy-top hex filling the 64 by 48 box. Integer test on doubled offsets from the centre."""
    dx = abs(2 * x + 1 - TILE_W)
    dy = abs(2 * y + 1 - TILE_H)
    return 8 * dy + 3 * dx <= 384


def on_edge(x: int, y: int) -> bool:
    return any(not inside_hex(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))


def pattern_hit(state: str, x: int, y: int) -> bool:
    """The pixels that carry a water state's pattern (art.md, water states)."""
    if state == "well":  # concentric rings
        band = 5 * (((x + 0.5 - TILE_W / 2) / (TILE_W / 2)) ** 2 + ((y + 0.5 - TILE_H / 2) / (TILE_H / 2)) ** 2) ** 0.5
        return 0 < round(band) < 5 and abs(band - round(band)) < 0.12
    if state == "storm":  # streaks along the wind
        return (x + 2 * y) % 9 == 0
    if state == "fouled":  # diagonal dither bands and dark motes
        return ((x + y) % 6 < 2 and (x + y) % 2 == 0) or (x * 7 + y * 13) % 41 == 0
    if state == "clean":  # sparse light flecks
        return (x * 5 + y * 11) % 23 == 0
    if state == "deaf":  # no pattern, only a dotted edge
        return on_edge(x, y) and (x + y) % 2 == 0
    if state == "orphan":  # fine square grid, a line every 4
        return x % 4 == 0 or y % 4 == 0
    raise ValueError(f"unknown water state: {state}")


def tile_image(root: Path, region: str, state: str) -> Image.Image:
    rgb, data = load_palette(root)
    base = rgb[data["region_water"][region][state]]
    pattern = rgb[data["region_pattern"][region][state]]
    img = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    px = img.load()
    for y in range(TILE_H):
        for x in range(TILE_W):
            if inside_hex(x, y):
                px[x, y] = pattern + (255,) if pattern_hit(state, x, y) else base + (255,)
    return img


def hit(shape: tuple, x: int, y: int) -> bool:
    kind, a = shape[0], shape[1:]
    if kind == "box":
        return a[0] <= x <= a[2] and a[1] <= y <= a[3]
    if kind == "disc":
        return (x - a[0]) ** 2 + (y - a[1]) ** 2 <= a[2] ** 2
    if kind == "ring":
        return a[2] ** 2 <= (x - a[0]) ** 2 + (y - a[1]) ** 2 <= a[3] ** 2
    if kind == "ellipse":  # (dx / rx) squared plus (dy / ry) squared, scaled to whole numbers
        return (x - a[0]) ** 2 * a[3] ** 2 + (y - a[1]) ** 2 * a[2] ** 2 <= (a[2] * a[3]) ** 2
    if kind == "trap":
        if not a[1] <= y <= a[2]:
            return False
        half = a[3] + (y - a[1]) * (a[4] - a[3]) // (a[2] - a[1])
        return abs(x - a[0]) <= half
    raise ValueError(f"unknown shape: {kind}")


def part_at(shapes: list, x: int, y: int) -> Optional[str]:
    for part, shape in shapes:
        if hit(shape, x, y):
            return part
    return None


def sprite_image(root: Path, size: tuple[int, int], spec: dict) -> Image.Image:
    """Draws the parts of a figure or thing. Edge pixels take the rim, else the outline, when the spec has one."""
    rgb, _ = load_palette(root)
    w, h = size
    cells = {(x, y): part for y in range(h) for x in range(w)
             if (part := part_at(spec["shapes"], x, y)) is not None}
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    for (x, y), part in cells.items():
        name = spec["parts"][part]
        if not all((x + dx, y + dy) in cells for dx, dy in NEIGHBOURS):
            if "rim" in spec:
                name = spec["rim"][(x + y) % 2]
            elif spec.get("outline"):
                name = spec["outline"]
        px[x, y] = rgb[name] + (255,)
    if spec.get("label"):
        for i, letter in enumerate(spec["label"]):
            for r, row in enumerate(GLYPHS[letter]):
                for c, ch in enumerate(row):
                    if ch == "#":
                        px[LABEL_X + 4 * i + c, LABEL_Y + r] = rgb[spec["ink"]] + (255,)
    return img


def figure_entry(key: str) -> dict:
    entry = {"path": f"sprites/figure-{key}.png", "kind": "figure"}
    if FIGURES[key]["canon"]:
        entry["canon"] = FIGURES[key]["canon"]
    entry["brief"] = f"briefs/figure-{key}.md"
    return entry


def thing_entry(key: str) -> dict:
    return {"path": f"sprites/thing-{key}.png", "kind": "thing", "brief": f"briefs/thing-{key}.md"}


def figure_brief(key: str) -> str:
    spec = FIGURES[key]
    return (f"{key.capitalize()} figure, 32 by 48: {spec['note']}. "
            f"Outline {spec.get('outline') or 'none'}; label {spec['label'] or 'none'}.\n"
            "Placeholder from tools/art/make_placeholders.py, for owner approval. Not final art.\n")


def thing_brief(key: str) -> str:
    return (f"{key.capitalize()} thing, 24 by 24, generic: no name and no canon fact.\n"
            "Placeholder from tools/art/make_placeholders.py, for owner approval. Not final art.\n")


def entry_for(region: str, state: str) -> dict:
    return {"path": f"tiles/{region}-{state}.png", "kind": "tile",
            "canon": REGIONS[region], "brief": f"briefs/{region}-{state}.md"}


def brief_text(root: Path, region: str, state: str) -> str:
    _, data = load_palette(root)
    water = data["water"][state]
    return (f"{REGION_NAMES[region]} water, {state}: {water['pattern']}; movement {water['movement']}.\n"
            f"{REGION_NAMES[region]} subset only: base {data['region_water'][region][state]}, "
            f"pattern {data['region_pattern'][region][state]}. Hex 64 by 48, outside transparent.\n"
            "Placeholder from tools/art/make_placeholders.py, for owner approval. Not final art.\n")


def upsert_manifest(root: Path, entries: list[dict]) -> list[dict]:
    """Adds or replaces entries by path, keeps the rest, and writes one sorted entry per line."""
    path = assets_dir(root) / "manifest.json"
    current = json.loads(path.read_text(encoding="utf-8"))["assets"] if path.exists() else []
    by_path = {e["path"]: e for e in current}
    for e in entries:
        by_path[e["path"]] = e
    rows = sorted(by_path.values(), key=lambda e: e["path"])
    if rows:
        body = ",\n".join("  " + json.dumps(e) for e in rows)
        path.write_text('{"assets": [\n' + body + "\n]}\n", encoding="utf-8")
    else:
        path.write_text('{"assets": []}\n', encoding="utf-8")
    return rows


def build(root: Path) -> list[dict]:
    """Writes the tiles and briefs, upserts their manifest entries, and returns the entries."""
    assets = assets_dir(root)
    for folder in ("tiles", "sprites", "briefs"):
        (assets / folder).mkdir(parents=True, exist_ok=True)
    entries = []
    for region in REGIONS:
        for state in STATES:
            entry = entry_for(region, state)
            tile_image(root, region, state).save(assets / entry["path"])
            (assets / entry["brief"]).write_text(brief_text(root, region, state), encoding="utf-8")
            entries.append(entry)
    for key in FIGURES:
        entry = figure_entry(key)
        sprite_image(root, (FIG_W, FIG_H), FIGURES[key]).save(assets / entry["path"])
        (assets / entry["brief"]).write_text(figure_brief(key), encoding="utf-8")
        entries.append(entry)
    for key in THINGS:
        entry = thing_entry(key)
        sprite_image(root, (THING_SIZE, THING_SIZE), THINGS[key]).save(assets / entry["path"])
        (assets / entry["brief"]).write_text(thing_brief(key), encoding="utf-8")
        entries.append(entry)
    upsert_manifest(root, entries)
    return entries


def contact_sheet(root: Path) -> tuple[Image.Image, list[tuple[int, int]]]:
    """One cell per entry in the manifest, sorted by path. Returns the sheet and each cell's position."""
    rgb, _ = load_palette(root)
    assets = assets_dir(root)
    rows = json.loads((assets / "manifest.json").read_text(encoding="utf-8"))["assets"]
    rows = sorted(rows, key=lambda e: e["path"])
    images = []
    for e in rows:
        with Image.open(assets / e["path"]) as im:
            images.append(im.convert("RGBA").resize((im.width * SCALE, im.height * SCALE), Image.NEAREST))
    cell_w = max(im.width for im in images) + PAD
    cell_h = max(im.height for im in images) + PAD
    cols = min(COLS, len(images))
    height = -(-len(images) // COLS) * cell_h + PAD
    sheet = Image.new("RGBA", (cols * cell_w + PAD, height), rgb["stone-0"] + (255,))
    cells = []
    for i, im in enumerate(images):
        x = PAD + (i % COLS) * cell_w
        y = PAD + (i // COLS) * cell_h
        sheet.paste(im, (x, y), im)
        cells.append((x, y))
    return sheet, cells


def main() -> None:
    build(ROOT)
    sheet, cells = contact_sheet(ROOT)
    out = ROOT / "shots" / "placeholders.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"wrote {len(REGIONS) * len(STATES)} tiles, {len(FIGURES)} figures, {len(THINGS)} things, "
          f"briefs and manifest entries; sheet {out} with {len(cells)} cells")


if __name__ == "__main__":
    main()
