#!/usr/bin/env python3
"""Data checks for Ovara: canon, glossary, references, art.

Usage: python tools/checks.py <canon|glossary|references|art|index>

canon, glossary, references and index are real; references also validates map content. art is a placeholder until
its task implements it; a placeholder passes and says so.
`canon` also runs the Python tests in tools/tests.
Keep this file free of third-party imports at module level, so that it runs
before the virtual environment exists.
"""
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
CANON = TOOLS.parent / "canon"

PLACEHOLDERS = {
    "art": "art check (palette, sizes, manifest): nothing to check yet (task M0-05)",
}


def report(label, errors, warnings):
    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    print(f"{label}: {len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


def run_tests():
    suite = unittest.TestLoader().discover(str(TOOLS / "tests"), top_level_dir=str(TOOLS / "tests"))
    return 0 if unittest.TextTestRunner(verbosity=1).run(suite).wasSuccessful() else 1


def main(argv):
    sys.path.insert(0, str(TOOLS))
    if len(argv) == 2 and argv[1] == "canon":
        from ovcheck.canon import check_canon
        return report("canon", *check_canon(CANON)) | run_tests()
    if len(argv) == 2 and argv[1] == "references":
        from ovcheck.chapters import check_chapters
        from ovcheck.content import check_content
        from ovcheck.references import check_references
        errors, warnings = check_references(CANON)
        more_errors, more_warnings = check_chapters(CANON.parent)
        content_errors, content_warnings = check_content(CANON.parent)
        return report("references", errors + more_errors + content_errors,
                      warnings + more_warnings + content_warnings)
    if len(argv) == 2 and argv[1] == "glossary":
        from ovcheck.glossary import check_glossary
        return report("glossary", *check_glossary(CANON.parent))
    if len(argv) == 2 and argv[1] == "index":
        from ovcheck.index import build_index
        text, errors = build_index(CANON)
        if errors:
            return report("index", errors, [])
        (CANON / "index.md").write_text(text + "\n", encoding="utf-8")
        print(f"index: wrote canon/index.md ({text.count(chr(10)) + 2} lines)")
        return 0
    if len(argv) != 2 or argv[1] not in PLACEHOLDERS:
        print(__doc__)
        return 2
    print(PLACEHOLDERS[argv[1]])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
