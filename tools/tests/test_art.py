import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

import fixtures  # noqa: F401  (puts tools/ on sys.path)
from ovcheck.art import check_art

GOOD = (10, 16, 24)


class ArtTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.assets = self.root / "game" / "assets"
        (self.assets / "palettes").mkdir(parents=True)
        (self.assets / "palettes" / "ovara.json").write_text(
            json.dumps({"colours": [{"hex": "#0a1018"}, {"hex": "#102030"}]}), encoding="utf-8")
        self.entries = []

    def png(self, rel, size, pixel=GOOD, kind=None, listed=True, alpha=255):
        path = self.assets / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGBA", size, pixel + (alpha,)).save(path)
        if listed:
            self.entries.append({"path": rel, "kind": kind})

    def run_check(self):
        (self.assets / "manifest.json").write_text(json.dumps({"assets": self.entries}), encoding="utf-8")
        return check_art(self.root)[0]

    def test_valid_passes(self):
        self.png("tiles/a.png", (64, 48), kind="tile")
        self.png("sprites/f.png", (32, 48), kind="figure")
        self.png("tiles/e.png", (32, 32), kind="exploring-tile")
        self.png("tiles/d.png", (64, 64), kind="dungeon-texture")
        self.png("sprites/t.png", (24, 24), kind="thing")
        self.png("portraits/p.png", (96, 96), kind="portrait")
        self.assertEqual(self.run_check(), [])

    def test_empty_and_missing_manifest(self):
        self.assertEqual(self.run_check(), [])
        (self.assets / "manifest.json").unlink()
        self.assertEqual(check_art(self.root)[0], [])
        self.png("tiles/a.png", (64, 48), kind="tile", listed=False)
        self.assertEqual(len(check_art(self.root)[0]), 1)

    def test_off_palette_names_file(self):
        self.png("tiles/a.png", (64, 48), pixel=(11, 16, 24), kind="tile")
        errors = self.run_check()
        self.assertEqual(len(errors), 1)
        self.assertIn("game/assets/tiles/a.png", errors[0])
        self.assertIn("off-palette", errors[0])

    def test_partial_alpha(self):
        self.png("tiles/a.png", (64, 48), kind="tile", alpha=128)
        self.assertIn("partial alpha", self.run_check()[0])

    def test_transparent_pixels_pass(self):
        self.png("tiles/a.png", (64, 48), pixel=(1, 2, 3), kind="tile", alpha=0)
        self.assertEqual(self.run_check(), [])

    def test_wrong_size(self):
        self.png("tiles/a.png", (32, 32), kind="tile")
        self.png("sprites/t.png", (32, 32), kind="thing")
        errors = self.run_check()
        self.assertEqual(len(errors), 2)
        self.assertTrue(any("tiles/a.png" in e for e in errors))

    def test_unlisted_and_missing(self):
        self.png("tiles/a.png", (64, 48), kind="tile", listed=False)
        self.entries.append({"path": "tiles/gone.png", "kind": "tile"})
        errors = self.run_check()
        self.assertEqual(len(errors), 2)
        self.assertTrue(any("a.png: not listed" in e for e in errors))
        self.assertTrue(any("gone.png: listed" in e for e in errors))

    def test_bad_kind(self):
        self.png("tiles/a.png", (64, 48), kind="blob")
        self.assertIn("manifest.json", self.run_check()[0])


if __name__ == "__main__":
    unittest.main()
