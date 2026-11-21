#!/usr/bin/env python3
"""Writes the Ovara master palette and its swatch image.

Usage: python3 tools/art/make_palette.py

Output (deterministic): game/assets/palettes/ovara.json and ovara-swatch.png.
The palette is eight ramps of eight colours, dark to light. Shadows lean
toward blue-green (water) or violet (land); lights lean warm.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game" / "assets" / "palettes"

RAMPS: dict[str, list[str]] = {
    "deep": ["0a1018", "102030", "163a4a", "1f5a68", "2f8588", "58b4b0", "98e0d8", "dcfaf2"],
    "kelp": ["0e1a14", "16301f", "1f4a28", "2f6a30", "4f8a38", "82aa48", "b8cc6c", "e4eaa0"],
    "brass": ["2a1a14", "4a3018", "6e4a1c", "9a6e20", "c89a30", "e8c250", "f6dc88", "fff2c4"],
    "stone": ["15121c", "2a2733", "413e4a", "5c5a64", "7c7a80", "a09e9e", "c6c4c0", "eceae4"],
    "rust": ["2a1218", "4a1e1e", "6e2c1c", "9a4220", "c46228", "e88a38", "f8b05c", "ffd890"],
    "neon": ["1e0c38", "3c1068", "5a1c98", "2848d0", "e03aa8", "2c8cf0", "ff7ac8", "ffc0e8"],
    "sand": ["3a2a2e", "6a5048", "9a7a64", "c4a47e", "dcc496", "eedcb0", "f8eed0", "fffaf0"],
    "ember": ["080406", "1a0a0c", "380e12", "5e1216", "8c1a1a", "c02a20", "e85a30", "ff9a60"],
}

# Region subsets: ramp:index lists, about 16 each (PLAN.md section 8).
SUBSETS: dict[str, list[str]] = {
    "pale": ["deep:0", "deep:1", "deep:2", "deep:3", "deep:4", "deep:5", "deep:6", "deep:7",
             "stone:0", "stone:2", "stone:4", "stone:7", "kelp:1", "kelp:3", "brass:5", "sand:7"],
    "anthem": ["kelp:0", "kelp:1", "kelp:2", "kelp:3", "kelp:4", "kelp:5", "kelp:6", "kelp:7",
               "brass:1", "brass:3", "brass:4", "brass:5", "brass:6", "deep:2", "deep:4", "sand:5"],
    "girdle": ["deep:1", "deep:2", "deep:3", "deep:4", "stone:0", "stone:1", "stone:2", "stone:3",
               "stone:5", "rust:1", "rust:3", "rust:5", "neon:3", "neon:4", "neon:5", "neon:6"],
    "shelves": ["sand:3", "sand:4", "sand:5", "sand:6", "sand:7", "deep:3", "deep:4", "deep:5",
                "deep:6", "deep:7", "kelp:5", "kelp:6", "brass:5", "stone:2", "stone:5", "neon:6"],
    "quiet": ["ember:0", "ember:1", "ember:2", "ember:3", "ember:4", "ember:5", "ember:6", "ember:7",
              "stone:0", "stone:1", "stone:2", "stone:4", "stone:6", "sand:6", "deep:0", "deep:2"],
}

# Water states (art-direction.md): colour plus the pattern/movement that
# carries the state when colour does not. Lightness must differ in greyscale.
WATER: dict[str, dict[str, str]] = {
    "clean": {"colour": "deep:4", "pattern": "sparse light flecks", "movement": "flecks drift slowly"},
    "fouled": {"colour": "brass:2", "pattern": "diagonal dither bands, dark motes", "movement": "motes sink"},
    "deaf": {"colour": "stone:5", "pattern": "none, dotted edge", "movement": "none at all"},
    "orphan": {"colour": "kelp:7", "pattern": "fine square grid", "movement": "slow slosh at the edges"},
    "storm": {"colour": "stone:1", "pattern": "streaks along the wind", "movement": "fast"},
    "well": {"colour": "deep:0", "pattern": "concentric rings", "movement": "rings widen slowly"},
}
MIN_LUMA_GAP = 20  # of 255, Rec.601


def rgb(h: str) -> tuple[int, int, int]:
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def luma(h: str) -> int:
    r, g, b = rgb(h)
    return round(0.299 * r + 0.587 * g + 0.114 * b)


def lookup(ref: str) -> str:
    ramp, i = ref.split(":")
    return RAMPS[ramp][int(i)]


def check() -> None:
    allc = [c for r in RAMPS.values() for c in r]
    assert len(RAMPS) == 8 and all(len(r) == 8 for r in RAMPS.values())
    assert len(set(allc)) == 64, "colours must be unique"
    for name, r in RAMPS.items():
        ls = [luma(c) for c in r]
        assert ls == sorted(ls) and len(set(ls)) == 8, f"ramp {name} must get lighter"
    for name, refs in SUBSETS.items():
        assert len(set(refs)) == len(refs) and 14 <= len(refs) <= 18, name
        for ref in refs:
            lookup(ref)
    ls = sorted((luma(lookup(w["colour"])), k) for k, w in WATER.items())
    for (a, ka), (b, kb) in zip(ls, ls[1:]):
        assert b - a >= MIN_LUMA_GAP, f"water {ka}/{kb} too close in greyscale: {a} vs {b}"


def compact(data: dict) -> str:
    """One line per colour, ramp, subset and water state; still plain JSON."""
    lines = []
    for key, val in data.items():
        if isinstance(val, list):
            body = ",\n".join("  " + json.dumps(v) for v in val)
            lines.append(f' "{key}": [\n{body}\n ]')
        elif isinstance(val, dict):
            body = ",\n".join(f"  {json.dumps(k)}: {json.dumps(v)}" for k, v in val.items())
            lines.append(f' "{key}": {{\n{body}\n }}')
        else:
            lines.append(f" {json.dumps(key)}: {json.dumps(val)}")
    return "{\n" + ",\n".join(lines) + "\n}\n"


def write_json() -> None:
    colours = []
    for ramp, cols in RAMPS.items():
        for i, c in enumerate(cols):
            colours.append({"name": f"{ramp}-{i}", "hex": "#" + c, "ramp": ramp, "luma": luma(c)})
    data = {
        "name": "ovara",
        "size": 64,
        "colours": colours,
        "ramps": {k: [f"{k}-{i}" for i in range(8)] for k in RAMPS},
        "subsets": {k: [r.replace(":", "-") for r in v] for k, v in SUBSETS.items()},
        "water": {k: {**w, "colour": w["colour"].replace(":", "-"),
                      "hex": "#" + lookup(w["colour"]), "luma": luma(lookup(w["colour"]))}
                  for k, w in WATER.items()},
    }
    (OUT / "ovara.json").write_text(compact(data))


def write_swatch() -> None:
    s = 24
    w, h = 8 * s + 16, 8 * s + 5 * (s // 2 + 2) + 2 * s + 40
    img = Image.new("RGB", (w, h), rgb("15121c"))
    d = ImageDraw.Draw(img)
    for y, cols in enumerate(RAMPS.values()):
        for x, c in enumerate(cols):
            d.rectangle([8 + x * s, 8 + y * s, 8 + x * s + s - 1, 8 + y * s + s - 1], fill=rgb(c))
    y0 = 8 + 8 * s + 8
    for refs in SUBSETS.values():
        for x, ref in enumerate(refs):
            d.rectangle([8 + x * 12, y0, 8 + x * 12 + 11, y0 + s // 2 - 1], fill=rgb(lookup(ref)))
        y0 += s // 2 + 2
    y0 += 8
    for x, wt in enumerate(WATER.values()):  # colour row, then greyscale row
        c = lookup(wt["colour"])
        d.rectangle([8 + x * 30, y0, 8 + x * 30 + 29, y0 + s - 1], fill=rgb(c))
        g = luma(c)
        d.rectangle([8 + x * 30, y0 + s, 8 + x * 30 + 29, y0 + 2 * s - 1], fill=(g, g, g))
    img.save(OUT / "ovara-swatch.png")


if __name__ == "__main__":
    check()
    OUT.mkdir(parents=True, exist_ok=True)
    write_json()
    write_swatch()
    print("wrote", OUT)
