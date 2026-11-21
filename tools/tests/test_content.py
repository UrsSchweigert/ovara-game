import json
import tempfile
import unittest
from pathlib import Path

from ovcheck.content import check_content

LEGEND = {"~": {"name": "water"}, "#": {"name": "wall"}}
BLEGEND = {"~": {"terrain": "open_water", "water": "clean"}}
DLEGEND = {".": {"flooded": True}, ",": {"flooded": False}}


def area(**kw):
    d = {"id": "a", "canon": "place.low-anthem", "name": "A", "legend": LEGEND, "rows": ["~~#", "~~#"]}
    return {**d, **kw}


def battle(**kw):
    d = {"id": "b", "canon": "place.low-anthem", "legend": BLEGEND, "rows": ["~~~", "~~~"]}
    return {**d, **kw}


def dungeon(**level):
    lv = {"legend": DLEGEND, "rows": ["..", ".,"], "walls": ["3c", "69"],
          "doors": [{"cell": [0, 0], "edge": "N", "kind": "door"}]}
    return {"id": "d", "canon": "place.low-anthem", "levels": [{**lv, **level}]}


class ContentTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)

    def put(self, kind, data, name="x.json"):
        p = self.root / "game" / "content" / kind / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(data if isinstance(data, str) else json.dumps(data), encoding="utf-8")

    def errors(self):
        return check_content(self.root)[0]

    def assertFails(self, *parts):
        errs = self.errors()
        self.assertTrue(any(all(p in e for p in parts) for e in errs), errs)

    def test_valid_maps_pass(self):
        self.put("areas", area())
        self.put("battles", battle())
        self.put("dungeons", dungeon())
        self.assertEqual(self.errors(), [])

    def test_empty_dirs_and_gitkeep_pass(self):
        self.put("areas", "", ".gitkeep")
        (self.root / "game" / "content" / "battles").mkdir()
        self.assertEqual(self.errors(), [])

    def test_unknown_kind_fails(self):
        self.put("monsters", {})
        self.assertFails("monsters", "unknown content kind")

    def test_bad_json_fails(self):
        self.put("people", "{nope")
        self.assertFails("x.json", "cannot parse")

    def test_schema_error_names_file_and_path(self):
        self.put("areas", area(canon="Low Anthem"))
        self.assertFails("x.json", "/canon")

    def test_battle_bad_water_fails(self):
        self.put("battles", battle(legend={"~": {"terrain": "open_water", "water": "murky"}}))
        self.assertFails("x.json", "/legend/~/water")

    def test_ragged_rows_fail(self):
        self.put("areas", area(rows=["~~#", "~~"]))
        self.assertFails("x.json", "/rows", "ragged")

    def test_glyph_not_in_legend_fails(self):
        self.put("areas", area(rows=["~~#", "~?#"]))
        self.assertFails("x.json", "/rows/1/1", "'?'")

    def test_oversize_area_fails(self):
        self.put("areas", area(rows=["~" * 65]))
        self.assertFails("x.json", "65x1", "64x48")
        self.put("areas", area(rows=["~"] * 49))
        self.assertFails("1x49")

    def test_oversize_battle_fails(self):
        self.put("battles", battle(rows=["~" * 13]))
        self.assertFails("x.json", "13x1", "12x9")
        self.put("battles", battle(rows=["~"] * 10))
        self.assertFails("1x10")

    def test_oversize_dungeon_fails(self):
        self.put("dungeons", dungeon(rows=["." * 33], walls=["0" * 33], doors=[]))
        self.assertFails("x.json", "/levels/0/rows", "33x1", "32x32")

    def test_dungeon_walls_shape_fails(self):
        self.put("dungeons", dungeon(walls=["3c"]))
        self.assertFails("/levels/0/walls", "same shape")

    def test_dungeon_door_without_wall_fails(self):
        self.put("dungeons", dungeon(doors=[{"cell": [0, 0], "edge": "S", "kind": "seam"}]))
        self.assertFails("/levels/0/doors/0", "not set in walls")


if __name__ == "__main__":
    unittest.main()
