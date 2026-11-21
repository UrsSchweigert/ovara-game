import json
import shutil
import tempfile
import unittest
from pathlib import Path

from PIL import Image

import fixtures  # noqa: F401  (puts tools/ on sys.path)
from art import make_placeholders as mp

REAL = Path(__file__).resolve().parents[2]


class PlaceholderTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        palette = mp.assets_dir(REAL) / "palettes" / "ovara.json"
        (self.root / "game" / "assets" / "palettes").mkdir(parents=True)
        shutil.copy(palette, self.root / "game" / "assets" / "palettes" / "ovara.json")

    def subset_hexes(self):
        _, data = mp.load_palette(self.root)
        names = data["subsets"][mp.REGION]
        return {c["hex"] for c in data["colours"] if c["name"] in names}

    def test_tiles_use_only_region_subset(self):
        mp.build(self.root)
        allowed = {tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) for h in self.subset_hexes()}
        for state in mp.STATES:
            img = Image.open(mp.assets_dir(self.root) / "tiles" / f"pale-{state}.png").convert("RGBA")
            self.assertEqual(img.size, (64, 48))
            used = {p[:3] for p in img.getdata() if p[3] == 255}
            self.assertTrue(used <= allowed, f"pale-{state}.png uses colours outside the Pale subset")
            self.assertEqual(img.getpixel((0, 0))[3], 0)  # corners are outside the hex

    def test_contact_sheet_has_one_cell_per_manifest_entry(self):
        mp.build(self.root)
        entries = json.loads((mp.assets_dir(self.root) / "manifest.json").read_text(encoding="utf-8"))["assets"]
        _, cells = mp.contact_sheet(self.root)
        self.assertEqual(len(cells), len(entries))
        self.assertEqual(len(cells), len(mp.STATES))

    def test_every_tile_has_manifest_entry_and_brief(self):
        mp.build(self.root)
        assets = mp.assets_dir(self.root)
        entries = json.loads((assets / "manifest.json").read_text(encoding="utf-8"))["assets"]
        self.assertEqual(len(entries), len(mp.STATES))
        for e in entries:
            self.assertEqual(e["kind"], "tile")
            self.assertEqual(e["canon"], mp.PLACE_ID)
            brief = (assets / e["brief"]).read_text(encoding="utf-8").splitlines()
            self.assertTrue(1 <= len(brief) <= 3)

    def test_rerun_changes_nothing(self):
        mp.build(self.root)
        assets = mp.assets_dir(self.root)
        first = {p.relative_to(assets): p.read_bytes() for p in assets.rglob("*") if p.is_file()}
        mp.build(self.root)
        second = {p.relative_to(assets): p.read_bytes() for p in assets.rglob("*") if p.is_file()}
        self.assertEqual(first, second)

    def test_manifest_upsert_keeps_other_entries(self):
        assets = mp.assets_dir(self.root)
        (assets / "manifest.json").write_text(json.dumps({"assets": [
            {"path": "ui/frame.png", "kind": "ui"}]}), encoding="utf-8")
        mp.build(self.root)
        paths = [e["path"] for e in json.loads((assets / "manifest.json").read_text(encoding="utf-8"))["assets"]]
        self.assertIn("ui/frame.png", paths)
        self.assertEqual(paths, sorted(paths))


if __name__ == "__main__":
    unittest.main()
