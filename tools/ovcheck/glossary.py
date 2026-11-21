"""Banned terms and TODO-CANON placeholders in game/."""
import re
from pathlib import Path

STRING = re.compile(r'"((?:[^"\\]|\\.)*)"(\s*:)?')
CANON_LINE = re.compile(r'"canon"\s*:')


def load_banned(root, errors):
    """Return [(regex, banned word, accepted term)] from canon/glossary.yaml."""
    import yaml
    path = Path(root) / "canon" / "glossary.yaml"
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as e:
        errors.append(f"{path}: cannot read glossary: {e}")
        return []
    if not isinstance(data, list):
        errors.append(f"{path}: glossary must be a list of terms")
        return []
    banned = []
    for item in data:
        for word in (item.get("banned") or []) if isinstance(item, dict) else []:
            parts = [re.escape(p) for p in re.split(r"[-\s]+", str(word)) if p]
            banned.append((re.compile(r"(?<!\w)" + r"[-\s]?".join(parts) + r"(?!\w)", re.I), word, item.get("term")))
    return banned


def _scan(path, banned, errors, skip_canon):
    for n, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if skip_canon and CANON_LINE.search(line):
            continue
        for m in STRING.finditer(line):
            if m.group(2):
                continue
            for rx, word, term in banned:
                if rx.search(m.group(1)):
                    errors.append(f"{path}:{n}: banned term '{word}' (use '{term}')")


def scan_terms(root, banned):
    errors = []
    game = Path(root) / "game"
    for path in sorted((game / "content").rglob("*.json")):
        _scan(path, banned, errors, True)
    for sub in ("scenes", "ui"):
        for ext in ("*.gd", "*.tscn"):
            for path in sorted((game / sub).rglob(ext)):
                _scan(path, banned, errors, False)
    return errors


def check_placeholders(root):
    errors = []
    game = Path(root) / "game"
    for path in sorted(game.rglob("*")):
        if not path.is_file() or ".godot" in path.relative_to(game).parts:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for n, line in enumerate(text.splitlines(), 1):
            if "TODO-CANON" in line:
                errors.append(f"{path}:{n}: TODO-CANON placeholder remains")
    return errors


def check_glossary(root):
    errors = []
    banned = load_banned(root, errors)
    errors += scan_terms(root, banned) + check_placeholders(root)
    return errors, []
