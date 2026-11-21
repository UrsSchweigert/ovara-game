#!/usr/bin/env python3
"""Data checks for Ovara: canon, glossary, references, art.

Usage: python tools/checks.py <canon|glossary|references|art|index>

Each check is a placeholder until task M0-03 (canon, glossary, references, index)
and task M0-05 (art) implement it. A placeholder passes and says so.
Keep this file free of third-party imports at module level, so that it runs
before the virtual environment exists.
"""
import sys

PLACEHOLDERS = {
    "canon": "canon validation: nothing to check yet (task M0-03)",
    "glossary": "glossary check: nothing to check yet (task M0-03)",
    "references": "reference and chapter check: nothing to check yet (task M0-03)",
    "art": "art check (palette, sizes, manifest): nothing to check yet (task M0-05)",
    "index": "canon index: nothing to generate yet (task M0-03)",
}


def main(argv):
    if len(argv) != 2 or argv[1] not in PLACEHOLDERS:
        print(__doc__)
        return 2
    print(PLACEHOLDERS[argv[1]])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
