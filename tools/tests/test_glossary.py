import tempfile
import unittest
from pathlib import Path

from fixtures import CanonCase
from ovcheck.glossary import check_glossary

GLOSSARY = "- term: mariner\n  meaning: x\n  banned: [merfolk, sea-person]\n"


class GlossaryTests(CanonCase):
    def setUp(self):
        super().setUp()
        self.root = self.canon.parent / (self.canon.name + "-root")
        self.canon = self.root / "canon"
        self.canon.mkdir(parents=True)
        self.write("glossary.yaml", GLOSSARY)

    def game(self, rel, text):
        path = self.root / "game" / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        self.addCleanup(lambda: path.unlink(missing_ok=True))

    def test_clean_passes(self):
        self.game("content/a.json", '{"text": "A mariner waits."}\n')
        self.assertEqual(check_glossary(self.root), ([], []))

    def test_banned_in_json_reports_file_and_line(self):
        self.game("content/a.json", '{\n "text": "The Sea Person waits."\n}\n')
        errors, _ = check_glossary(self.root)
        self.assertTrue(any("a.json:2:" in e and "sea-person" in e and "'mariner'" in e for e in errors), errors)

    def test_canon_value_exempt(self):
        self.game("content/a.json", '{"canon": "merfolk"}\n')
        self.assertEqual(check_glossary(self.root)[0], [])

    def test_banned_in_script_string(self):
        self.game("scenes/a.gd", 'var x: String = "merfolk"\n')
        errors, _ = check_glossary(self.root)
        self.assertTrue(any("a.gd:1:" in e for e in errors), errors)

    def test_placeholder_fails(self):
        self.game("rules/a.gd", "# TODO-CANON: name\n")
        errors, _ = check_glossary(self.root)
        self.assertTrue(any("a.gd:1:" in e and "TODO-CANON" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
