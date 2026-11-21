#!/usr/bin/env python3
"""Data checks for Ovara: canon, glossary, references, art.

Usage: python tools/checks.py <canon|glossary|references|flags|art|index>

canon, glossary, references and index are real; references also validates content and flags. art checks game/assets against the manifest and palette.
`canon` also runs the Python tests in tools/tests.
Keep this file free of third-party imports at module level, so that it runs
before the virtual environment exists.
"""
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
CANON = TOOLS.parent / "canon"

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
        from ovcheck.flags import check_flags
        from ovcheck.references import check_references
        errors, warnings = check_references(CANON)
        more_errors, more_warnings = check_chapters(CANON.parent)
        content_errors, content_warnings = check_content(CANON.parent)
        flag_errors, flag_warnings = check_flags(CANON.parent)
        return report("references", errors + more_errors + content_errors + flag_errors,
                      warnings + more_warnings + content_warnings + flag_warnings)
    if len(argv) == 2 and argv[1] == "flags":
        from ovcheck.flags import check_flags
        return report("flags", *check_flags(CANON.parent))
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
    if len(argv) == 2 and argv[1] == "art":
        from ovcheck.art import check_art
        return report("art", *check_art(CANON.parent))
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
