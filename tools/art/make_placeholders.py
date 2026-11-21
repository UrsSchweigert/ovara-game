#!/usr/bin/env python3
"""Writes placeholder art for Ovara: the water tiles of each region, their briefs,
their manifest entries and a contact sheet for the owner to look at.

Usage: python3 tools/art/make_placeholders.py

Reads game/assets/palettes/ovara.json (from make_palette.py). Output is
deterministic and idempotent: running it again changes nothing. These are
placeholders, not final art.
"""
import json
from pathlib import Path

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
    (assets / "tiles").mkdir(parents=True, exist_ok=True)
    (assets / "briefs").mkdir(parents=True, exist_ok=True)
    entries = []
    for region in REGIONS:
        for state in STATES:
            entry = entry_for(region, state)
            tile_image(root, region, state).save(assets / entry["path"])
            (assets / entry["brief"]).write_text(brief_text(root, region, state), encoding="utf-8")
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
    print(f"wrote {len(REGIONS) * len(STATES)} tiles, briefs and manifest entries; sheet {out} with {len(cells)} cells")


if __name__ == "__main__":
    main()
