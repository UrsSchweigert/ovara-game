"""Art check: manifest schema, manifest coverage, sizes per kind, palette-only opaque pixels."""
import json
from pathlib import Path

SCHEMA = Path(__file__).resolve().parent.parent / "schemas" / "asset-manifest.schema.json"
SIZES = {
    "tile": {(64, 48)},
    "figure": {(32, 48)},
    "exploring-tile": {(32, 32)},
    "dungeon-texture": {(32, 32), (64, 64)},
    "thing": {(24, 24)},
    "portrait": {(96, 96)},
}


def _palette(assets):
    data = json.loads((assets / "palettes" / "ovara.json").read_text(encoding="utf-8"))
    out = set()
    for c in data["colours"]:
        h = c["hex"].lstrip("#")
        out.add(tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)))
    return out


def _check_image(path, rel, kind, palette, errors):
    from PIL import Image
    with Image.open(path) as im:
        im = im.convert("RGBA")
    if kind in SIZES and im.size not in SIZES[kind]:
        want = " or ".join(f"{w}x{h}" for w, h in sorted(SIZES[kind]))
        errors.append(f"{rel}: size {im.size[0]}x{im.size[1]} is wrong for {kind} (want {want})")
    w = im.size[0]
    partial = []
    bad = []
    for i, (r, g, b, a) in enumerate(im.getdata()):
        if a not in (0, 255):
            partial.append(i)
        elif a == 255 and (r, g, b) not in palette:
            bad.append(i)
    if partial:
        errors.append(f"{rel}: {len(partial)} pixel(s) with partial alpha, first at {partial[0] % w},{partial[0] // w}")
    if bad:
        r, g, b, _ = im.getpixel((bad[0] % w, bad[0] // w))
        errors.append(f"{rel}: {len(bad)} off-palette pixel(s), first at {bad[0] % w},{bad[0] // w} "
                      f"(#{r:02x}{g:02x}{b:02x})")


def check_art(root):
    import jsonschema
    errors, warnings = [], []
    assets = Path(root) / "game" / "assets"
    manifest = assets / "manifest.json"
    pngs = sorted(p.relative_to(assets).as_posix() for p in assets.rglob("*.png")
                  if p.relative_to(assets).parts[0] != "palettes")
    if not manifest.exists():
        if pngs:
            errors.append("game/assets/manifest.json: missing")
        return errors, warnings
    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except ValueError as e:
        return [f"game/assets/manifest.json: not valid JSON: {e}"], warnings
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    for e in sorted(jsonschema.Draft202012Validator(schema).iter_errors(data), key=lambda e: list(map(str, e.path))):
        errors.append(f"game/assets/manifest.json: {'/'.join(map(str, e.path)) or '(root)'}: {e.message}")
    if errors:
        return errors, warnings
    palette = _palette(assets)
    listed = {}
    for entry in data["assets"]:
        if entry["path"] in listed:
            errors.append(f"game/assets/manifest.json: {entry['path']} is listed twice")
        listed[entry["path"]] = entry["kind"]
    for rel in pngs:
        if rel not in listed:
            errors.append(f"game/assets/{rel}: not listed in manifest.json")
    for rel, kind in sorted(listed.items()):
        if not (assets / rel).is_file():
            errors.append(f"game/assets/{rel}: listed in manifest.json but missing")
        else:
            _check_image(assets / rel, f"game/assets/{rel}", kind, palette, errors)
    return errors, warnings
