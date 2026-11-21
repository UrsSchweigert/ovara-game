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

    def allowed_hexes(self, region):
        """The region's subset plus its own water and pattern colours (art.md)."""
        _, data = mp.load_palette(self.root)
        names = set(data["subsets"][region])
        names |= {data["region_water"][region][s] for s in mp.STATES}
        names |= {data["region_pattern"][region][s] for s in mp.STATES}
        return {tuple(int(c["hex"].lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
                for c in data["colours"] if c["name"] in names}

    def test_tiles_use_only_region_subset(self):
        mp.build(self.root)
        for region in mp.REGIONS:
            allowed = self.allowed_hexes(region)
            for state in mp.STATES:
                name = f"{region}-{state}.png"
                img = Image.open(mp.assets_dir(self.root) / "tiles" / name).convert("RGBA")
                self.assertEqual(img.size, (64, 48))
                used = {p[:3] for p in img.getdata() if p[3] == 255}
                self.assertTrue(used <= allowed, f"{name} uses colours outside its region subset")
                self.assertEqual(img.getpixel((0, 0))[3], 0)  # corners are outside the hex

    def test_contact_sheet_has_one_cell_per_manifest_entry(self):
        mp.build(self.root)
        entries = json.loads((mp.assets_dir(self.root) / "manifest.json").read_text(encoding="utf-8"))["assets"]
        _, cells = mp.contact_sheet(self.root)
        self.assertEqual(len(cells), len(entries))
        self.assertEqual(len(cells), len(mp.REGIONS) * len(mp.STATES) + len(mp.FIGURES) + len(mp.THINGS))

    def palette_hexes(self):
        _, data = mp.load_palette(self.root)
        return {tuple(int(c["hex"].lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)) for c in data["colours"]}

    def test_figures_are_32_by_48_palette_only_with_feet_on_the_bottom_row(self):
        mp.build(self.root)
        palette = self.palette_hexes()
        for key in mp.FIGURES:
            img = Image.open(mp.assets_dir(self.root) / "sprites" / f"figure-{key}.png").convert("RGBA")
            self.assertEqual(img.size, (32, 48))
            used = {p[:3] for p in img.getdata() if p[3] == 255}
            self.assertTrue(used <= palette, f"figure-{key}.png uses off-palette colours")
            feet = [x for x in range(32) if img.getpixel((x, 47))[3] == 255 and abs(x - 16) <= 3]
            self.assertTrue(feet, f"figure-{key}.png has no feet near x 16")

    def test_figure_outlines_are_the_faction_colour(self):
        mp.build(self.root)
        rgb, _ = mp.load_palette(self.root)
        for key, spec in mp.FIGURES.items():
            if "rim" in spec or not spec.get("outline"):
                continue
            img = Image.open(mp.assets_dir(self.root) / "sprites" / f"figure-{key}.png").convert("RGBA")
            edges = self.edge_colours(img, rgb[spec["ink"]] if spec["ink"] else None)
            self.assertEqual(edges, {rgb[spec["outline"]]}, f"figure-{key}.png outline")

    def test_fouled_has_dithered_rim_and_no_outline(self):
        mp.build(self.root)
        rgb, _ = mp.load_palette(self.root)
        img = Image.open(mp.assets_dir(self.root) / "sprites" / "figure-fouled.png").convert("RGBA")
        self.assertEqual(self.edge_colours(img, rgb[mp.FIGURES["fouled"]["ink"]]), {rgb["brass-1"], rgb["brass-2"]})

    def edge_colours(self, img, ink):
        """Colours of opaque pixels that touch a transparent pixel or the image edge, but not the label ink."""
        w, h = img.size
        opaque = {(x, y) for x in range(w) for y in range(h) if img.getpixel((x, y))[3] == 255}
        edge = {img.getpixel(p)[:3] for p in opaque
                if not all(n in opaque for n in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)))}
        return edge - {ink}

    def test_things_are_24_by_24_and_generic(self):
        mp.build(self.root)
        palette = self.palette_hexes()
        assets = mp.assets_dir(self.root)
        entries = json.loads((assets / "manifest.json").read_text(encoding="utf-8"))["assets"]
        for key in mp.THINGS:
            img = Image.open(assets / "sprites" / f"thing-{key}.png").convert("RGBA")
            self.assertEqual(img.size, (24, 24))
            used = {p[:3] for p in img.getdata() if p[3] == 255}
            self.assertTrue(used <= palette)
        things = [e for e in entries if e["kind"] == "thing"]
        self.assertEqual(len(things), len(mp.THINGS))
        self.assertTrue(all("canon" not in e for e in things))

    def test_figures_list_canon_ids_and_hero_has_none(self):
        mp.build(self.root)
        entries = {e["path"]: e for e in json.loads(
            (mp.assets_dir(self.root) / "manifest.json").read_text(encoding="utf-8"))["assets"]}
        self.assertEqual(entries["sprites/figure-mariners.png"]["canon"], "faction.mariners")
        self.assertEqual(entries["sprites/figure-fouled.png"]["canon"], "creature.the-fouled")
        self.assertEqual(entries["sprites/figure-makers.png"]["canon"], "event.the-makers")
        self.assertEqual(entries["sprites/figure-rays.png"]["canon"], "faction.great-rays")
        self.assertNotIn("canon", entries["sprites/figure-hero.png"])
        for key in mp.FIGURES:
            e = entries[f"sprites/figure-{key}.png"]
            self.assertTrue((mp.assets_dir(self.root) / e["brief"]).is_file())

    def test_every_tile_has_manifest_entry_and_brief(self):
        mp.build(self.root)
        assets = mp.assets_dir(self.root)
        entries = json.loads((assets / "manifest.json").read_text(encoding="utf-8"))["assets"]
        tiles = [e for e in entries if e["kind"] == "tile"]
        self.assertEqual(len(tiles), len(mp.REGIONS) * len(mp.STATES))
        for region, place_id in mp.REGIONS.items():
            mine = [e for e in tiles if e["path"].startswith(f"tiles/{region}-")]
            self.assertEqual(len(mine), len(mp.STATES))
            for e in mine:
                self.assertEqual(e["canon"], place_id)
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
