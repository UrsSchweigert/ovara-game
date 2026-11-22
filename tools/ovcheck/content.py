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


def _inside(where, cell, rows, errors):
    x, y = cell
    if y >= len(rows) or x >= len(rows[0]):
        errors.append(f"{where}: {cell} is outside the area")
        return False
    return True


def _reachable(rows, legend, spawn):
    """Cells the party can stand on from spawn; trait-gated cells count as open."""
    seen, todo = set(), [tuple(spawn)]
    while todo:
        x, y = todo.pop()
        if (x, y) in seen or not (0 <= y < len(rows) and 0 <= x < len(rows[0])):
            continue
        if legend[rows[y][x]].get("blocks"):
            continue
        seen.add((x, y))
        todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return seen


def _area(where, data, errors):
    """Cells inside the grid and, if there is a spawn, reachable from it.

    Each variant's rows must match the base shape and legend; a variant's cells are checked
    against its own rows when it has them, otherwise against the base rows."""
    legend, base = data["legend"], data["rows"]
    places = [(f"{where}/spawn", data["spawn"])] if "spawn" in data else []
    for key in ("exits", "things", "encounters", "trait_access"):
        places += [(f"{where}/{key}/{i}/cell", e["cell"]) for i, e in enumerate(data.get(key, []))]
    groups = [(base, places)]
    for i, v in enumerate(data.get("variants", [])):
        vw = f"{where}/variants/{i}"
        rows = base
        if "rows" in v:
            if not _grid(vw, v["rows"], legend, LIMITS["areas"], errors):
                continue
            if len(v["rows"]) != len(base) or len(v["rows"][0]) != len(base[0]):
                errors.append(f"{vw}/rows: must have the same shape as the base rows")
                continue
            rows = v["rows"]
        vplaces = [(f"{vw}/{key}/{j}/cell", e["cell"]) for key in ("exits", "things")
                   for j, e in enumerate(v.get(key, []))]
        groups.append((rows, vplaces))
    for rows, group in groups:
        inside = [(w, c) for w, c in group if _inside(w, c, rows, errors)]
        if "spawn" not in data or not _inside(f"{where}/spawn", data["spawn"], rows, []):
            continue
        seen = _reachable(rows, legend, data["spawn"])
        for w, (x, y) in inside:
            near = {(x, y), (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)}
            if not near & seen:
                errors.append(f"{w}: {[x, y]} cannot be reached from the spawn")


def _cross_check(root, found, errors):
    """References between files and to canon. found: kind -> {id: (file, data)}."""
    ids = {k: {v[1].get("id") for v in d.values()} for k, d in found.items()}
    for f, a in found.get("areas", {}).values():
        groups = [a.get("exits", [])] + [v.get("exits", []) for v in a.get("variants", [])]
        for e in (e for g in groups for e in g):
            target = found["areas"].get(e["to"])
            if target is None:
                errors.append(f"{f}: exit to unknown area {e['to']!r}")
            else:
                _inside(f"{f}: exit to {e['to']}", e["to_cell"], target[1]["rows"], errors)
        for e in a.get("encounters", []):
            if e["battle"] not in ids.get("battles", set()):
                errors.append(f"{f}: encounter with unknown battle {e['battle']!r}")
    for f, p in found.get("people", {}).values():
        if "area" in p and p["area"] not in ids.get("areas", set()):
            errors.append(f"{f}: person stands in unknown area {p['area']!r}")
        for t in p.get("topics", []):
            if t["dialogue"] not in ids.get("dialogue", set()):
                errors.append(f"{f}: topic {t['topic']} names unknown dialogue {t['dialogue']!r}")
    for f, q in found.get("quests", {}).values():
        start = q.get("start")
        if start:
            target = found.get("areas", {}).get(start["area"])
            if target is None:
                errors.append(f"{f}: start names unknown area {start['area']!r}")
            else:
                _inside(f"{f}: start {start['area']}", start["cell"], target[1]["rows"], errors)
            arrival = start.get("arrival")
            if arrival and arrival not in ids.get("cutscenes", set()):
                errors.append(f"{f}: start names unknown arrival cut scene {arrival!r}")
    for f, c in found.get("cutscenes", {}).values():
        if "area" not in c:
            if any(s.get("arrival") == c.get("id") for _, q in found.get("quests", {}).values()
                   for s in [q.get("start") or {}]):
                errors.append(f"{f}: arrival cut scene needs an area")
            continue
        target = found.get("areas", {}).get(c["area"])
        if target is None:
            errors.append(f"{f}: cut scene names unknown area {c['area']!r}")
            continue
        for i, st in enumerate(c["steps"]):
            if st["op"] in ("walk", "camera"):
                _inside(f"{f}: step {i} {st['op']}", st["to"], target[1]["rows"], errors)
    canon = Path(root) / "canon"
    if canon.is_dir():
        from .canon import load_entries
        entries = load_entries(canon, [], [])
        for kind in ("areas", "people", "dialogue", "quests", "items"):
            for f, data in found.get(kind, {}).values():
                for ref in _canon_refs(data):
                    if ref not in entries:
                        errors.append(f"{f}: canon id {ref!r} does not exist")
    things = {t["id"] for _, a in found.get("areas", {}).values()
              for g in [a] + a.get("variants", []) for t in g.get("things", [])}
    for kind_files in found.values():
        for f, data in kind_files.values():
            for key in _condition_nodes(data, "used"):
                if key not in things:
                    errors.append(f"{f}: used names unknown thing {key!r}")
            for e in _condition_nodes(data, "entered"):
                target = found.get("areas", {}).get(e.get("area"))
                if target is None:
                    errors.append(f"{f}: entered names unknown area {e.get('area')!r}")
                else:
                    _inside(f"{f}: entered {e['area']}", e["cell"], target[1]["rows"], errors)
            for key in _holds_keys(data):
                if key not in ids.get("items", set()):
                    errors.append(f"{f}: holds names unknown item {key!r}")


def _canon_refs(node, key=""):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "heard" and isinstance(v, list):
                # heard names its person by file id (sefa), not canon; only the topic is canon.
                yield from (str(e["topic"]) for e in v if isinstance(e, dict) and "topic" in e)
            else:
                yield from _canon_refs(v, k)
    elif isinstance(node, list):
        for v in node:
            yield from _canon_refs(v, key)
    elif isinstance(node, str) and key in ("canon", "topic", "speaker", "person", "giver", "next"):
        yield node


def _condition_nodes(node, name):
    """The entries of every condition key `name` in the content: list items, or dict keys."""
    if isinstance(node, dict):
        for k, v in node.items():
            if k == name and isinstance(v, list):
                yield from (e for e in v if isinstance(e, dict))
            elif k == name and isinstance(v, dict):
                yield from v.keys()
            yield from _condition_nodes(v, name)
    elif isinstance(node, list):
        for v in node:
            yield from _condition_nodes(v, name)


def _holds_keys(node):
    """Item ids named as keys of any 'holds' dict in the content."""
    return _condition_nodes(node, "holds")


def check_content(root):
    errors, warnings = [], []
    found = {}
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
            if problems:
                continue
            if d.name in ("areas", "battles", "people", "dialogue", "quests", "items"):
                found.setdefault(d.name, {})[data["id"]] = (f, data)
            if d.name not in LIMITS:
                continue
            if d.name == "dungeons":
                for i, level in enumerate(data["levels"]):
                    where = f"{f}: /levels/{i}"
                    if _grid(where, level["rows"], level["legend"], LIMITS[d.name], errors):
                        _dungeon_level(where, level, errors)
            elif _grid(f"{f}: ", data["rows"], data["legend"], LIMITS[d.name], errors) and d.name == "areas":
                _area(f"{f}: ", data, errors)
    _cross_check(root, found, errors)
    return errors, warnings
