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

    def test_item_unknown_canon_id_fails(self):
        (self.root / "canon" / "items").mkdir(parents=True)
        self.put("items", {**ITEM, "canon": "thing.nowhere"})
        self.assertFails("x.json", "canon id 'thing.nowhere' does not exist")

    def test_item_canon_unchecked_without_canon_dir(self):
        self.put("items", {**ITEM, "canon": "thing.nowhere"})
        self.assertEqual(self.errors(), [])

    def test_item_known_canon_id_passes(self):
        machine = ("id: machine.hook\nname: Hook\ntype: machine\nkind: tool\n"
                   "summary: A hook.\nfacts:\n  - It is bent.\nsources: [world-bible.md#1]\n")
        (self.root / "canon" / "machines").mkdir(parents=True)
        (self.root / "canon" / "machines" / "hook.yaml").write_text(machine, encoding="utf-8")
        self.put("items", {**ITEM, "canon": "machine.hook"})
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

    def test_condition_new_keys_pass_and_unknown_key_fails(self):
        when = {"day_min": 3, "heard": [{"person": "mender", "topic": "place.low-anthem"}], "holds": {"hook": 2}}
        topic = {"topic": "place.low-anthem", "panels": [PANEL]}
        self.put("items", {**ITEM, "id": "hook"})
        self.put("dialogue", {**DIALOGUE, "topics": [{**topic, "when": when}]})
        self.assertEqual(self.errors(), [])
        self.put("dialogue", {**DIALOGUE, "topics": [{**topic, "when": {"day_max": 3}}]})
        self.assertFails("x.json", "/topics/0/when")

    def test_condition_holds_unknown_item_fails(self):
        topic = {"topic": "place.low-anthem", "when": {"holds": {"nothing": 1}}, "panels": [PANEL]}
        self.put("dialogue", {**DIALOGUE, "topics": [topic]})
        self.assertFails("x.json", "unknown item 'nothing'")

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


STAGE1_AREA = area(
    legend={".": {}, "#": {"blocks": True}}, rows=["..#.", "..#.", "...."], spawn=[0, 0],
    exits=[{"cell": [1, 2], "to": "b", "to_cell": [0, 0], "when": {"flag": "q.done"}}],
    things=[{"id": "lamp", "canon": "place.low-anthem", "cell": [3, 0], "hidden": {"trait": "trait.water-breather"}}],
    encounters=[{"cell": [1, 1], "battle": "bt"}], light=0.5, trait_access=[{"cell": [3, 2], "trait": "trait.water-breather"}],
    variants=[{"when": {"flag": "q.done"}, "rows": ["...."] * 3}])
OTHER_AREA = area(id="b", legend={".": {}}, rows=["..", ".."])


class Stage1ContentTests(ContentCase):
    def put_area(self, **kw):
        self.put("areas", {**STAGE1_AREA, **kw}, "a.json")
        self.put("areas", OTHER_AREA, "b.json")

    def test_valid_stage1_content_passes(self):
        self.put_area()
        self.put("battles", battle(id="bt"))
        self.put("dialogue", {**DIALOGUE, "topics": [{**DIALOGUE["topics"][0], "sets": ["q.done"],
                                                      "next": ["place.low-anthem"]}]})
        self.put("people", sheet(area="a", cell=[0, 0], topics=[{"topic": "place.low-anthem", "dialogue": "dl"}]), "p.json")
        self.put("quests", {**QUEST, "steps": [{**QUEST["steps"][0], "kind": "discover", "area": "a",
                                                "requires": {"flag": "q.done"}, "sets": ["q.done"]}]})
        self.assertEqual(self.errors(), [])

    def test_area_bad_fields_fail(self):
        self.put_area(exits=[{"cell": [1, 2], "to": "b"}])
        self.assertFails("a.json", "/exits/0", "to_cell")
        self.put_area(light=2)
        self.assertFails("a.json", "/light")
        self.put_area(things=[{"id": "t", "canon": "Lamp", "cell": [0, 0]}])
        self.assertFails("a.json", "/things/0/canon")

    def test_exit_to_unknown_area_fails(self):
        self.put_area(exits=[{"cell": [1, 2], "to": "nowhere", "to_cell": [0, 0]}])
        self.assertFails("a.json", "unknown area 'nowhere'")

    def test_exit_target_cell_outside_fails(self):
        self.put_area(exits=[{"cell": [1, 2], "to": "b", "to_cell": [5, 5]}])
        self.assertFails("a.json", "exit to b", "outside")

    def test_cell_outside_area_fails(self):
        self.put_area(spawn=[9, 9])
        self.assertFails("a.json", "/spawn", "outside")

    def test_unreachable_exit_fails(self):
        self.put_area(rows=["..#.", "..#.", "..#."], exits=[{"cell": [3, 1], "to": "b", "to_cell": [0, 0]}],
                      things=[], encounters=[], trait_access=[], variants=[])
        self.assertFails("/exits/0/cell", "cannot be reached")

    def test_person_unknown_area_or_dialogue_fails(self):
        self.put_area()
        self.put("people", sheet(area="zz", topics=[{"topic": "place.low-anthem", "dialogue": "nope"}]), "p.json")
        self.assertFails("p.json", "unknown area 'zz'")
        self.assertFails("p.json", "unknown dialogue 'nope'")

    def test_person_topic_needs_dialogue_fails(self):
        self.put("people", sheet(topics=[{"topic": "place.low-anthem"}]), "p.json")
        self.assertFails("p.json", "/topics/0", "dialogue")

    def test_dialogue_bad_sets_fails(self):
        self.put("dialogue", {**DIALOGUE, "topics": [{**DIALOGUE["topics"][0], "sets": ["Bad Flag"]}]})
        self.assertFails("x.json", "/topics/0/sets/0")

    def test_quest_step_bad_kind_fails(self):
        self.put("quests", {**QUEST, "steps": [{**QUEST["steps"][0], "kind": "battle"}]})
        self.assertFails("x.json", "/steps/0/kind")

    def test_unknown_canon_id_fails(self):
        canon = self.root / "canon" / "places"
        canon.mkdir(parents=True)
        self.put_area(canon="place.nowhere")
        self.assertFails("a.json", "canon id 'place.nowhere' does not exist")

    def test_encounter_unknown_battle_fails(self):
        self.put_area()
        (self.root / "game" / "content" / "battles").mkdir()
        self.assertFails("a.json", "unknown battle 'bt'")

    def test_variant_rows_bad_glyph_or_shape_fail(self):
        self.put_area(variants=[{"when": {"flag": "q.done"}, "rows": ["ZZZZ"] * 3}])
        self.assertFails("/variants/0/rows", "glyph 'Z'")
        self.put_area(variants=[{"when": {"flag": "q.done"}, "rows": ["..", ".."]}])
        self.assertFails("/variants/0/rows", "same shape")

    def test_variant_cells_checked_against_variant_rows(self):
        self.put("battles", battle(id="bt"))
        walled = ["..#.", "..#.", "..##"]
        self.put_area(variants=[{"when": {"flag": "q.done"}, "rows": walled,
                                 "things": [{"id": "t", "canon": "place.low-anthem", "cell": [3, 0]}]}])
        self.assertFails("/variants/0/things/0/cell", "cannot be reached")
        self.put_area(variants=[{"when": {"flag": "q.done"}, "rows": ["...."] * 3,
                                 "exits": [{"cell": [9, 0], "to": "b", "to_cell": [0, 0]}]}])
        self.assertFails("/variants/0/exits/0/cell", "outside")


if __name__ == "__main__":
    unittest.main()
