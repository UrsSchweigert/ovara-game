import json
import unittest

from fixtures import CanonCase, PERSON
from ovcheck.chapters import check_chapters


class ChapterTests(CanonCase):
    def setUp(self):
        super().setUp()
        self.root = self.canon.parent / (self.canon.name + "-root")
        self.canon = self.root / "canon"
        self.canon.mkdir(parents=True)
        self.write("places/alpha.yaml", __import__("fixtures").PLACE)
        self.write("people/bea.yaml", PERSON)
        self.write("chapters/ch01.yaml", __import__("fixtures").CHAPTER)

    def content(self, data):
        path = self.root / "game" / "content" / "a.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data), encoding="utf-8")

    def test_alive_person_passes(self):
        self.content({"chapter": 1, "who": {"canon": "person.bea"}})
        self.assertEqual(check_chapters(self.root), ([], []))

    def test_dead_person_fails(self):
        self.write("chapters/ch01.yaml", __import__("fixtures").CHAPTER.replace("bea: true", "bea: false"))
        self.content({"chapter": 1, "who": {"canon": "person.bea"}})
        errors, _ = check_chapters(self.root)
        self.assertTrue(any("a.json" in e and "person.bea is not alive in chapter 1" in e for e in errors), errors)

    def test_unlisted_ability_fails(self):
        self.write("powers/tide.yaml", "id: power.tide\nname: Tide\ntype: power\nsummary: s\nfacts: [f]\nsources: [x.md#1]\n")
        self.content({"chapter": 1, "skill": {"canon": "power.tide"}})
        errors, _ = check_chapters(self.root)
        self.assertTrue(any("power.tide is not a hero ability" in e for e in errors), errors)

    def test_untagged_ignored(self):
        self.content({"who": {"canon": "person.nobody"}})
        self.assertEqual(check_chapters(self.root), ([], []))


if __name__ == "__main__":
    unittest.main()
