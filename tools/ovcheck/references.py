"""Check that every ID mentioned in canon exists, is not retired, and has the right type."""
from .canon import LINK_PREFIX, load_chapters, load_entries


def _ref(ref, where, entries, errors, prefix=None):
    if not isinstance(ref, str):
        errors.append(f"{where}: reference {ref!r} is not a string")
    elif ref not in entries:
        errors.append(f"{where}: {ref} does not exist")
    elif entries[ref][1].get("status") == "retired":
        errors.append(f"{where}: {ref} is retired")
    elif prefix and not ref.startswith(prefix + "."):
        errors.append(f"{where}: {ref} should start with {prefix}.")


def check_references(canon):
    errors, warnings = [], []
    entries = load_entries(canon, [], warnings)
    for eid, (path, data) in entries.items():
        for key in ("region", "parent"):
            if key in data:
                _ref(data[key], f"{path}: {key}", entries, errors, "place")
        links = data.get("links")
        for key, refs in (links.items() if isinstance(links, dict) else []):
            for ref in refs if isinstance(refs, list) else []:
                _ref(ref, f"{path}: links.{key}", entries, errors, LINK_PREFIX.get(key))
    for path, ch in load_chapters(canon, []).items():
        _ref(ch.get("region"), f"{path}: region", entries, errors, "place")
        for key in ("hero_abilities", "companions_available", "without_gift"):
            for ref in ch.get(key) or []:
                _ref(ref, f"{path}: {key}", entries, errors)
        for ref in ch.get("alive") or {}:
            _ref(ref, f"{path}: alive", entries, errors, "person")
    return errors, warnings
