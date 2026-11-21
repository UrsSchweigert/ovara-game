"""Flag check: every flag read must be set, and every flag used must be listed in docs/design/quests.md."""
import json
import re
from pathlib import Path

LISTED = re.compile(r"`([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)*)`")
READ_KEYS = {"flag", "not_flag"}
SET_KEYS = {"clears", "key_flag"}


def listed_flags(quests):
    out = set()
    for line in quests.read_text(encoding="utf-8").splitlines():
        if "**Sets:**" in line:
            out.update(LISTED.findall(line))
    return out


def _walk(node, where, reads, sets):
    if isinstance(node, dict):
        for k, v in node.items():
            if isinstance(v, str) and k in READ_KEYS:
                reads.setdefault(v, where)
            elif isinstance(v, str) and k in SET_KEYS:
                sets.setdefault(v, where)
            elif k == "sets" and isinstance(v, list):
                for s in v:
                    if isinstance(s, str):
                        sets.setdefault(s, where)
            else:
                _walk(v, where, reads, sets)
    elif isinstance(node, list):
        for v in node:
            _walk(v, where, reads, sets)


def check_flags(root):
    errors, warnings = [], []
    quests = root / "docs" / "design" / "quests.md"
    if not quests.is_file():
        return [f"{quests}: missing, cannot check flags"], warnings
    listed = listed_flags(quests)
    reads, sets = {}, {}
    for path in sorted((root / "game" / "content").rglob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except ValueError:
            continue  # check_content reports invalid JSON
        _walk(data, path.relative_to(root).as_posix(), reads, sets)
    for flag, where in sorted(reads.items()):
        if flag not in sets:
            errors.append(f"{where}: flag '{flag}' is read but never set")
    for flag, where in sorted({**sets, **reads}.items()):
        if flag not in listed:
            errors.append(f"{where}: flag '{flag}' is not listed in docs/design/quests.md")
    return errors, warnings
