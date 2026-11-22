extends "res://tests/test_case.gd"

const Area: GDScript = preload("res://rules/area.gd")
const World: GDScript = preload("res://rules/world_state.gd")
const Sheet: GDScript = preload("res://rules/character_sheet.gd")

const FIXTURE: Dictionary = {
	"id": "fix", "name": "Fixture", "legend": {".": {}, "#": {"blocks": true}, "g": {}},
	"rows": ["....", ".##.", "...g"],
	"spawn": [0, 0],
	"exits": [{"cell": [3, 0], "to": "other", "to_cell": [1, 2]}],
	"things": [
		{"id": "stone", "canon": "x.y", "cell": [0, 2]},
		{"id": "mark", "canon": "x.y", "cell": [2, 0], "hidden": {"trait": "trait.listener"}},
		{"id": "late", "canon": "x.y", "cell": [1, 0], "when": {"chapter_min": 3}},
	],
	"encounters": [{"cell": [2, 2], "battle": "b1"}],
	"trait_access": [{"cell": [3, 2], "trait": "trait.diver"}],
	"variants": [{"when": {"flag": "door.open"}, "rows": ["....", "....", "...g"]}],
	"light": 0.1,
}


func _world(traits: Array[String] = []) -> RefCounted:
	var w: RefCounted = World.new()
	var s: RefCounted = Sheet.new()
	s.id = "p"
	s.traits.append_array(traits)
	w.sheets["p"] = s
	w.party.append("p")
	return w


func _area() -> RefCounted:
	return Area.from_dict(FIXTURE.duplicate(true))


func test_loads_clean() -> void:
	check_eq((_area().errors as Array).size(), 0, "errors")
	var bad: Dictionary = FIXTURE.duplicate(true)
	bad["rows"] = ["...", "..", "..."]
	check(not (Area.from_dict(bad).errors as Array).is_empty(), "ragged rows accepted")


func test_shortest_path() -> void:
	var p: Array[Vector2i] = _area().find_path(_world(), Vector2i(0, 0), Vector2i(2, 2))
	check_eq(p.size(), 5, "path length")
	check_eq(p[0], Vector2i(0, 0), "starts at from")
	check_eq(p[-1], Vector2i(2, 2), "ends at to")


func test_blocked_tile() -> void:
	var a: RefCounted = _area()
	check(not a.is_walkable(_world(), Vector2i(1, 1)), "wall walkable")
	check(a.find_path(_world(), Vector2i(0, 0), Vector2i(1, 1)).is_empty(), "path into wall")
	check(not a.is_walkable(_world(), Vector2i(9, 9)), "out of bounds walkable")


func test_trait_blocked_tile() -> void:
	var a: RefCounted = _area()
	check(not a.is_walkable(_world(), Vector2i(3, 2)), "entered without trait")
	check(a.is_walkable(_world(["trait.diver"] as Array[String]), Vector2i(3, 2)), "refused with trait")


func test_exit_transfer() -> void:
	var w: RefCounted = _world()
	var e: Dictionary = _area().take_exit(w, Vector2i(3, 0))
	check_eq(e["to"], "other", "destination")
	check_eq(w.position, {"area": "other", "x": 1, "y": 2}, "position")
	check(_area().exit_at(w, Vector2i(0, 0)).is_empty(), "exit where none")


func test_hidden_thing_needs_listen() -> void:
	var w: RefCounted = _world(["trait.listener"] as Array[String])
	var a: RefCounted = _area()
	check_eq(a.visible_things(w, false).size(), 1, "before Listen")
	check_eq(a.visible_things(w, true).size(), 2, "after Listen")
	check_eq(a.visible_things(_world(), true).size(), 1, "Listen without the trait")
	w.chapter = 3
	check_eq(a.visible_things(w, true).size(), 3, "chapter condition")


func test_dark_area_needs_light() -> void:
	var a: RefCounted = _area()
	check(a.is_dark(), "dark")
	check(not a.can_enter(false), "entered dark without light")
	check(a.can_enter(true), "refused with light")


func test_variant_by_flag() -> void:
	var w: RefCounted = _world()
	var a: RefCounted = _area()
	check(not a.is_walkable(w, Vector2i(1, 1)), "wall before flag")
	w.set_flag("door.open")
	check(a.is_walkable(w, Vector2i(1, 1)), "wall after flag")


func test_encounter_seen_before_met() -> void:
	var a: RefCounted = _area()
	var w: RefCounted = _world()
	check_eq(a.encounters_seen(w, Vector2i(0, 2), 2).size(), 1, "seen from two away")
	check_eq(a.encounter_at(w, Vector2i(0, 2)), "", "not met yet")
	check_eq(a.encounter_at(w, Vector2i(2, 2)), "b1", "met on the cell")


func test_mariner_on_land_rule() -> void:
	var w: RefCounted = _world(["trait.water-breather"] as Array[String])
	w.day = 1
	check(not Area.weakened_on_land(w, "p", 1), "weak on the day of landing")
	w.advance_days(1)
	check(Area.weakened_on_land(w, "p", 1), "mariner not weakened a day on land")
	check(not Area.weakened_on_land(_world(), "p", 1), "non-mariner weakened")
