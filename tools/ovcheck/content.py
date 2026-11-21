"""Validate content under game/content/."""
import json
from pathlib import Path

SCHEMAS = Path(__file__).resolve().parent.parent / "schemas"
KINDS = {"abilities", "areas", "battles", "cutscenes", "dialogue", "dungeons", "items", "people",
         "quests", "shops", "skills", "teachers", "traits", "units"}
# kind -> (max columns, max rows)
LIMITS = {"areas": (64, 48), "dungeons": (32, 32), "battles": (12, 9)}
KIND_NAME = {"areas": "area", "dungeons": "dungeon", "battles": "battle", "items": "item", "shops": "shop",
             "dialogue": "dialogue", "quests": "quest", "cutscenes": "cutscene",
             "units": "unit", "people": "person", "abilities": "ability", "skills": "skill", "traits": "trait",
             "teachers": "teacher"}
EDGE_BIT = {"N": 1, "E": 2, "S": 4, "W": 8}


def _validator(kind):
    import jsonschema
    from referencing import Registry, Resource
    registry = Registry()
    for p in SCHEMAS.glob("content-*.schema.json"):
        doc = json.loads(p.read_text(encoding="utf-8"))
        registry = registry.with_resource(p.name, Resource.from_contents(doc))
    schema = json.loads((SCHEMAS / f"content-{KIND_NAME[kind]}.schema.json").read_text(encoding="utf-8"))
    return jsonschema.Draft202012Validator(schema, registry=registry.with_resource(
        "", Resource.from_contents(schema)))


def _grid(where, rows, legend, limit, errors):
    """Check ragged rows, size and glyphs; return True if the grid is well-formed."""
    ok = True
    if len(set(len(r) for r in rows)) > 1:
        errors.append(f"{where}/rows: ragged rows (lengths {sorted(set(len(r) for r in rows))})")
        ok = False
    width = max(len(r) for r in rows)
    if width > limit[0] or len(rows) > limit[1]:
        errors.append(f"{where}/rows: map is {width}x{len(rows)}, limit is {limit[0]}x{limit[1]}")
        ok = False
    for y, row in enumerate(rows):
        for x, g in enumerate(row):
            if g not in legend:
                errors.append(f"{where}/rows/{y}/{x}: glyph {g!r} is not in the legend")
                ok = False
    return ok


def _dungeon_level(where, level, errors):
    rows, walls = level["rows"], level["walls"]
    if len(walls) != len(rows) or any(len(w) != len(r) for w, r in zip(walls, rows)):
        errors.append(f"{where}/walls: must have the same shape as rows")
        return
    for i, door in enumerate(level.get("doors", [])):
        x, y = door["cell"]
        if y >= len(rows) or x >= len(rows[y]):
            errors.append(f"{where}/doors/{i}/cell: {[x, y]} is outside the level")
        elif not int(walls[y][x], 16) & EDGE_BIT[door["edge"]]:
            errors.append(f"{where}/doors/{i}: edge {door['edge']} of {[x, y]} is not set in walls")


def check_content(root):
    errors, warnings = [], []
    base = Path(root) / "game" / "content"
    if not base.is_dir():
        return errors, warnings
    for d in sorted(p for p in base.iterdir() if p.is_dir()):
        if d.name not in KINDS:
            errors.append(f"{d}: unknown content kind {d.name!r}")
            continue
        validator = _validator(d.name) if d.name in KIND_NAME else None
        for f in sorted(d.rglob("*.json")):
            try:
                data = json.loads(f.read_text(encoding="utf-8"))
            except (ValueError, OSError) as e:
                errors.append(f"{f}: cannot parse: {e}")
                continue
            if validator is None:
                continue
            problems = sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path))
            for e in problems:
                path = "/" + "/".join(str(p) for p in e.absolute_path)
                errors.append(f"{f}: {path}: {e.message}")
            if problems or d.name not in LIMITS:
                continue
            if d.name == "dungeons":
                for i, level in enumerate(data["levels"]):
                    where = f"{f}: /levels/{i}"
                    if _grid(where, level["rows"], level["legend"], LIMITS[d.name], errors):
                        _dungeon_level(where, level, errors)
            else:
                _grid(f"{f}: ", data["rows"], data["legend"], LIMITS[d.name], errors)
    return errors, warnings
