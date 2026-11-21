"""Load canon and validate it against tools/schemas/."""
import json
import re
from pathlib import Path

SCHEMAS = Path(__file__).resolve().parent.parent / "schemas"
SKIP = {"proposals", "source", "chapters"}
LINK_PREFIX = {"places": "place", "people": "person", "factions": "faction", "powers": "power",
               "machines": "machine", "creatures": "creature", "flora": "flora", "events": "event"}
TYPE_DIR = {"place": "places", "person": "people", "faction": "factions", "power": "powers",
            "machine": "machines", "creature": "creatures", "flora": "flora", "event": "events",
            "world": "world"}


def _yaml():
    import yaml
    return yaml


def _schema(name):
    return json.loads((SCHEMAS / name).read_text(encoding="utf-8"))


def _load(path, errors):
    try:
        data = _yaml().safe_load(path.read_text(encoding="utf-8"))
    except Exception as e:  # yaml.YAMLError and decode errors
        errors.append(f"{path}: cannot parse: {e}")
        return None
    if not isinstance(data, dict):
        errors.append(f"{path}: top level must be a mapping")
        return None
    return data


def normalise_facts(data, path, warnings):
    """Turn an unquoted 'Label: text' fact (parsed as a one-key mapping) into a string."""
    facts = data.get("facts")
    if not isinstance(facts, list):
        return
    for i, fact in enumerate(facts):
        if isinstance(fact, dict) and len(fact) == 1:
            (k, v), = fact.items()
            if isinstance(k, str) and isinstance(v, str):
                facts[i] = f"{k}: {v}"
                warnings.append(f"{path}: fact {i + 1} is an unquoted mapping; quote this fact; canon-keeper follow-up")


def _validate(data, schema, path, errors):
    import jsonschema
    for e in sorted(jsonschema.Draft202012Validator(schema).iter_errors(data), key=lambda e: list(map(str, e.path))):
        where = "/".join(map(str, e.path)) or "(entry)"
        errors.append(f"{path}: {where}: {e.message}")


def load_entries(canon, errors, warnings):
    """Return {id: (path, data)} for every entry, with schema errors appended."""
    schema = _schema("canon-entry.schema.json")
    entries = {}
    for path in sorted(Path(canon).glob("*/*.yaml")):
        if path.parent.name in SKIP:
            continue
        data = _load(path, errors)
        if data is None:
            continue
        normalise_facts(data, path, warnings)
        _validate(data, schema, path, errors)
        eid, typ = data.get("id"), data.get("type")
        if isinstance(eid, str):
            if eid in entries:
                errors.append(f"{path}: duplicate id {eid} (also {entries[eid][0]})")
            entries[eid] = (path, data)
            if eid.split(".", 1)[0] != typ:
                errors.append(f"{path}: id {eid} does not match type {typ}")
            if path.stem != eid.split(".", 1)[-1]:
                errors.append(f"{path}: id {eid} does not match file name")
        if typ in TYPE_DIR and path.parent.name != TYPE_DIR[typ]:
            errors.append(f"{path}: type {typ} belongs in {TYPE_DIR[typ]}/")
    return entries


def load_chapters(canon, errors):
    schema = _schema("canon-chapter.schema.json")
    chapters = {}
    for path in sorted((Path(canon) / "chapters").glob("*.yaml")):
        data = _load(path, errors)
        if data is None:
            continue
        _validate(data, schema, path, errors)
        m = re.fullmatch(r"ch(\d\d)", path.stem)
        if not m or data.get("chapter") != int(m.group(1)):
            errors.append(f"{path}: chapter {data.get('chapter')} does not match file name")
        chapters[path] = data
    return chapters


def check_canon(canon):
    errors, warnings = [], []
    load_entries(canon, errors, warnings)
    load_chapters(canon, errors)
    return errors, warnings
