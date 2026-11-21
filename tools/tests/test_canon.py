import unittest
from pathlib import Path

from fixtures import CanonCase, PERSON
from ovcheck.canon import check_canon
from ovcheck.index import build_index
from ovcheck.references import check_references

REAL = Path(__file__).resolve().parent.parent.parent / "canon"


class CanonTests(CanonCase):
    def test_valid_fixture_passes(self):
        self.assertEqual(check_canon(self.canon), ([], []))
        self.assertEqual(check_references(self.canon), ([], []))

    def test_missing_field(self):
        self.write("people/bea.yaml", PERSON.replace("summary: A person.\n", ""))
        errors, _ = check_canon(self.canon)
        self.assertTrue(any("bea.yaml" in e and "'summary' is a required property" in e for e in errors), errors)

    def test_id_must_match_file_and_type(self):
        self.write("people/bea.yaml", PERSON.replace("person.bea", "person.zed"))
        errors, _ = check_canon(self.canon)
        self.assertTrue(any("does not match file name" in e for e in errors), errors)

    def test_bad_link(self):
        self.write("people/bea.yaml", PERSON.replace("region: place.alpha", "region: place.nowhere"))
        errors, _ = check_references(self.canon)
        self.assertTrue(any("bea.yaml" in e and "place.nowhere does not exist" in e for e in errors), errors)

    def test_wrong_prefix_link(self):
        self.write("places/alpha.yaml", (self.canon / "places/alpha.yaml").read_text().replace("people: [person.bea]", "people: [place.alpha]"))
        errors, _ = check_references(self.canon)
        self.assertTrue(any("should start with person." in e for e in errors), errors)

    def test_retired_id(self):
        self.write("people/bea.yaml", PERSON + "status: retired\nretired_reason: merged\n")
        errors, _ = check_references(self.canon)
        self.assertTrue(any("alpha.yaml" in e and "person.bea is retired" in e for e in errors), errors)
        self.assertTrue(any("ch01.yaml" in e and "person.bea is retired" in e for e in errors), errors)

    def test_retired_needs_reason(self):
        self.write("people/bea.yaml", PERSON + "status: retired\n")
        errors, _ = check_canon(self.canon)
        self.assertTrue(any("retired_reason" in e for e in errors), errors)

    def test_chapter_unknown_person(self):
        self.write("chapters/ch01.yaml", (self.canon / "chapters/ch01.yaml").read_text().replace("{person.bea: true}", "{person.ghost: true}"))
        errors, _ = check_references(self.canon)
        self.assertTrue(any("ch01.yaml" in e and "person.ghost does not exist" in e for e in errors), errors)

    def test_chapter_number_must_match_file(self):
        self.write("chapters/ch02.yaml", (self.canon / "chapters/ch01.yaml").read_text())
        errors, _ = check_canon(self.canon)
        self.assertTrue(any("ch02.yaml" in e and "does not match file name" in e for e in errors), errors)

    def test_single_key_mapping_fact_warns_and_passes(self):
        self.write("people/bea.yaml", PERSON.replace("  - She is kind.", "  - Voice: slow and low."))
        errors, warnings = check_canon(self.canon)
        self.assertEqual(errors, [])
        self.assertTrue(any("bea.yaml" in w and "quote this fact; canon-keeper follow-up" in w for w in warnings), warnings)

    def test_list_fact_fails(self):
        self.write("people/bea.yaml", PERSON.replace("  - She is kind.", "  - [a, b]"))
        errors, _ = check_canon(self.canon)
        self.assertTrue(any("bea.yaml" in e and "facts/0" in e for e in errors), errors)

    def test_multi_key_mapping_fact_fails(self):
        self.write("people/bea.yaml", PERSON.replace("  - She is kind.", "  - {a: b, c: d}"))
        errors, _ = check_canon(self.canon)
        self.assertTrue(any("facts/0" in e for e in errors), errors)

    def test_index_lists_entries(self):
        text, errors = build_index(self.canon)
        self.assertEqual(errors, [])
        self.assertIn("- `place.alpha` Alpha: A hold.", text)


class RealCanonTests(unittest.TestCase):
    def test_real_canon_passes(self):
        errors, _ = check_canon(REAL)
        self.assertEqual(errors, [])
        errors, _ = check_references(REAL)
        self.assertEqual(errors, [])

    def test_real_index_under_400_lines(self):
        text, _ = build_index(REAL)
        self.assertLess(text.count("\n"), 400)


if __name__ == "__main__":
    unittest.main()
