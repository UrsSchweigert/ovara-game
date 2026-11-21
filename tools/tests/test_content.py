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


class ContentCase(unittest.TestCase):
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


class ContentTests(ContentCase):
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


ITEM = {"id": "i", "canon": "item.hook", "name": "Hook", "slot": "weapon", "kind": "hook"}
SHOP = {"id": "s", "person": "person.mender", "stock": [{"from_chapter": 1, "to_chapter": 3, "items": ["i"]}]}
PANEL = {"speaker": "person.mender", "portrait": "mender", "lines": ["One.", "Two.", "Three."]}
DIALOGUE = {"id": "dl", "person": "person.mender", "topics": [
    {"topic": "place.low-anthem", "when": {"chapter_min": 1, "not_flag": "jef.dead"}, "panels": [PANEL]}]}
QUEST = {"id": "q", "kind": "fetch", "giver": "person.mender", "chapters": [1, 3], "clears": "q.done", "sets": ["q.done"],
         "steps": [{"id": "s1", "intent": "Carry it.", "points": 2, "difficulty": 10}]}
CUTSCENE = {"id": "c", "skippable": True, "steps": [
    {"op": "walk", "who": "person.mender", "to": [1, 2]}, {"op": "say", "who": "person.mender", "lines": ["Hm."]},
    {"op": "camera", "to": [0, 0]}, {"op": "light", "level": 0.5}]}


class StoryContentTests(ContentCase):
    def test_valid_story_content_passes(self):
        for kind, d in [("items", ITEM), ("shops", SHOP), ("dialogue", DIALOGUE), ("quests", QUEST),
                        ("cutscenes", CUTSCENE)]:
            self.put(kind, d)
        self.assertEqual(self.errors(), [])

    def test_item_bad_slot_fails(self):
        self.put("items", {**ITEM, "slot": "hat"})
        self.assertFails("x.json", "/slot")

    def test_key_item_needs_key_flag(self):
        self.put("items", {**ITEM, "slot": "key"})
        self.assertFails("x.json", "key_flag")

    def test_intended_water_needs_fade_days(self):
        self.put("items", {**ITEM, "kind": "intended_water"})
        self.assertFails("x.json", "fade_days")
        self.put("items", {**ITEM, "kind": "intended_water", "fade_days": {"sea": 3, "land": 1}})
        self.assertEqual(self.errors(), [])

    def test_shop_without_stock_fails(self):
        self.put("shops", {**SHOP, "stock": []})
        self.assertFails("x.json", "/stock")

    def test_dialogue_four_lines_fail(self):
        self.put("dialogue", {**DIALOGUE, "topics": [{"topic": "place.low-anthem", "panels": [
            {**PANEL, "lines": ["a", "b", "c", "d"]}]}]})
        self.assertFails("x.json", "/topics/0/panels/0/lines")

    def test_dialogue_topic_must_be_canon_id(self):
        self.put("dialogue", {**DIALOGUE, "topics": [{"topic": "Low Anthem", "panels": [PANEL]}]})
        self.assertFails("x.json", "/topics/0/topic")

    def test_quest_bad_kind_fails(self):
        self.put("quests", {**QUEST, "kind": "battle"})
        self.assertFails("x.json", "/kind")

    def test_quest_bad_points_and_difficulty_fail(self):
        step = {"id": "s1", "intent": "x", "points": 4, "difficulty": 9}
        self.put("quests", {**QUEST, "steps": [step]})
        self.assertFails("/steps/0/points")
        self.assertFails("/steps/0/difficulty")

    def test_cutscene_bad_step_fails(self):
        self.put("cutscenes", {**CUTSCENE, "steps": [{"op": "dance"}]})
        self.assertFails("x.json", "/steps/0")


SHEET = {"id": "p", "canon": "person.bea", "attributes": {"body": 10, "hands": 10, "mind": 10, "standing": 10},
         "reach": 2, "skills": {"listen": 3}, "traits": ["trait.water-breather"]}
ABILITY = {"id": "listen", "form": "listen", "type": "calling", "size": 2}
SKILL = {"id": "listen", "skill": "listen", "attribute": "standing"}
TRAIT = {"id": "water_breather", "canon": "trait.water-breather"}
TEACHER = {"id": "t", "person": "person.hesper", "place": "place.low-anthem", "skill": "listen", "max_step": 2,
           "chapter": 2, "trial": "Name the water."}


def sheet(**kw):
    return {**SHEET, **kw}


class SheetContentTests(ContentCase):
    def test_valid_sheet_kinds_pass(self):
        for kind, data in (("units", sheet(faction="faction.halcyon")), ("people", sheet(join_chapter=3)),
                           ("abilities", ABILITY), ("skills", SKILL), ("traits", TRAIT), ("teachers", TEACHER)):
            self.put(kind, data)
        self.assertEqual(self.errors(), [])

    def test_attribute_range_fails(self):
        for v in (7, 15):
            self.put("people", sheet(attributes={**SHEET["attributes"], "body": v}))
            self.assertFails("x.json", "/attributes/body")
        self.put("units", sheet(attributes={"body": 10, "hands": 10, "mind": 10}))
        self.assertFails("x.json", "'standing' is a required property")

    def test_reach_range_fails(self):
        self.put("people", sheet(reach=6))
        self.assertFails("x.json", "/reach")

    def test_skill_step_and_name_fail(self):
        for steps in ({"listen": 0}, {"listen": 6}, {"juggling": 1}):
            self.put("people", sheet(skills=steps))
            self.assertFails("x.json", "/skills")

    def test_trait_needs_canon_prefix_fails(self):
        self.put("units", sheet(traits=["water-breather"]))
        self.assertFails("x.json", "/traits/0")
        self.put("traits", {**TRAIT, "canon": "person.bea"})
        self.assertFails("x.json", "/canon")

    def test_ability_fails(self):
        self.put("abilities", {**ABILITY, "size": 6})
        self.assertFails("x.json", "/size")
        self.put("abilities", {**ABILITY, "form": "sing"})
        self.assertFails("x.json", "/form")
        self.put("abilities", {**ABILITY, "type": "magic"})
        self.assertFails("x.json", "/type")

    def test_skill_def_fails(self):
        self.put("skills", {**SKILL, "attribute": "luck"})
        self.assertFails("x.json", "/attribute")

    def test_teacher_fails(self):
        for key in ("trial", "max_step", "place", "chapter"):
            self.put("teachers", {k: v for k, v in TEACHER.items() if k != key})
            self.assertFails("x.json", f"'{key}' is a required property")
        self.put("teachers", {**TEACHER, "max_step": 6})
        self.assertFails("x.json", "/max_step")
        self.put("teachers", {**TEACHER, "trial": ""})
        self.assertFails("x.json", "/trial")


if __name__ == "__main__":
    unittest.main()
