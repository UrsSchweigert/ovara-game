import json
import tempfile
import unittest
from pathlib import Path

from fixtures import CanonCase
from ovcheck.flags import check_flags
from ovcheck.index import build_index

QUESTS = "- **Sets:** `a.one`, `a.two`.\n"


class FlagTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        (self.root / "docs" / "design").mkdir(parents=True)
        (self.root / "docs" / "design" / "quests.md").write_text(QUESTS, encoding="utf-8")

    def content(self, name, data):
        path = self.root / "game" / "content" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data), encoding="utf-8")

    def test_valid_passes(self):
        self.content("quests/q.json", {"sets": ["a.one"]})
        self.content("dialogue/d.json", {"x": [{"when": {"flag": "a.one"}}]})
        self.assertEqual(check_flags(self.root), ([], []))

    def test_read_never_set_fails(self):
        self.content("dialogue/d.json", {"x": [{"when": {"not_flag": "a.two"}}]})
        errors, _ = check_flags(self.root)
        self.assertTrue(any("d.json" in e and "'a.two'" in e and "never set" in e for e in errors), errors)

    def test_unlisted_set_fails(self):
        self.content("quests/q.json", {"sets": ["a.nine"]})
        errors, _ = check_flags(self.root)
        self.assertTrue(any("'a.nine'" in e and "not listed" in e for e in errors), errors)

    def test_unlisted_read_fails(self):
        self.content("quests/q.json", {"sets": ["a.one"]})
        self.content("dialogue/d.json", {"flag": "a.nine"})
        errors, _ = check_flags(self.root)
        self.assertTrue(any("'a.nine'" in e and "not listed" in e for e in errors), errors)

    def test_key_flag_and_clears_count_as_sets(self):
        self.content("items/i.json", {"key_flag": "a.one"})
        self.content("quests/q.json", {"clears": "a.two"})
        self.content("dialogue/d.json", {"flag": "a.one", "not_flag": "a.two"})
        self.assertEqual(check_flags(self.root)[0], [])


class IndexSizeTests(CanonCase):
    def test_too_many_entries_fails(self):
        for i in range(400):
            self.write(f"places/p{i}.yaml", f"id: place.p{i}\nname: P\ntype: place\nkind: hold\nsummary: s\n"
                       "facts: [x]\nsources: [a.md#1]\n")
        _, errors = build_index(self.canon)
        self.assertTrue(any("limit is 399" in e for e in errors), errors)
