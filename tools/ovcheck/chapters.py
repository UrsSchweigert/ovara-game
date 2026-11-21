"""Check tagged content (JSON with an integer "chapter") against that chapter's canon state."""
import json
from pathlib import Path

from .canon import load_entries


def _canon_ids(node):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "canon" and isinstance(v, str):
                yield v
            else:
                yield from _canon_ids(v)
    elif isinstance(node, list):
        for v in node:
            yield from _canon_ids(v)


def check_chapters(root):
    root = Path(root)
    errors, warnings = [], []
    entries = load_entries(root / "canon", [], warnings)
    for path in sorted((root / "game" / "content").rglob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except ValueError as e:
            errors.append(f"{path}: invalid JSON: {e}")
            continue
        chapter = data.get("chapter") if isinstance(data, dict) else None
        if not isinstance(chapter, int) or isinstance(chapter, bool):
            continue
        cpath = root / "canon" / "chapters" / f"ch{chapter:02d}.yaml"
        if not cpath.exists():
            errors.append(f"{path}: no canon/chapters/ch{chapter:02d}.yaml for chapter {chapter}")
            continue
        import yaml
        state = yaml.safe_load(cpath.read_text(encoding="utf-8")) or {}
        alive, abilities = state.get("alive") or {}, state.get("hero_abilities") or []
        for ref in sorted(set(_canon_ids(data))):
            if ref not in entries:
                errors.append(f"{path}: {ref} does not exist in canon")
            elif ref.startswith("person.") and alive.get(ref) is not True:
                errors.append(f"{path}: {ref} is not alive in chapter {chapter}")
            elif ref.startswith(("power.", "machine.")) and ref not in abilities:
                errors.append(f"{path}: {ref} is not a hero ability in chapter {chapter}")
    return errors, warnings
