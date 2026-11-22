extends "res://tests/test_case.gd"

const Area: GDScript = preload("res://rules/area.gd")
const World: GDScript = preload("res://rules/world_state.gd")
const Sheet: GDScript = preload("res://rules/character_sheet.gd")
const MapText: GDScript = preload("res://tools/map_text.gd")

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

const FULL: String = """fix  Fixture  4x3  light 0.1  dark
...>
.##.
T.!~

P person  T thing  > exit  ! encounter  ~ needs a trait  ? hidden thing (listened)

legend
  #  blocks
  .  open
  g  open
spawn
  (0,0)
exits
  (3,0) -> other at (1,2)
things
  stone (0,2) canon x.y
people
  none
encounters
  (2,2) b1
trait access
  (3,2) trait.diver
"""


func _world(traits: Array[String] = []) -> RefCounted:
	var w: RefCounted = World.new()
	var s: RefCounted = Sheet.new()
	s.id = "p"
	s.traits.append_array(traits)
	w.sheets["p"] = s
	w.party.append("p")
	return w


func _render(w: RefCounted, listened: bool = false) -> String:
	return MapText.render(Area.from_dict(FIXTURE.duplicate(true)), w, listened)


## Row y of the grid: line 0 is the header.
func _row(text: String, y: int) -> String:
	return text.split("\n")[y + 1]


func test_full_text_is_stable() -> void:
	check_eq(_render(_world()), FULL, "full text")


func test_same_world_same_text() -> void:
	var w: RefCounted = _world(["trait.listener"] as Array[String])
	check_eq(_render(w, true), _render(w, true), "rendered twice")


func test_header_names_the_area_and_light() -> void:
	check_eq(_render(_world()).split("\n")[0], "fix  Fixture  4x3  light 0.1  dark", "header")


func test_default_grid_marks() -> void:
	var out: String = _render(_world())
	check_eq(_row(out, 0), "...>", "chapter 1 row 0")
	check_eq(_row(out, 1), ".##.", "wall row")
	check_eq(_row(out, 2), "T.!~", "thing, encounter and trait cell")


func test_variant_row_after_flag() -> void:
	var w: RefCounted = _world()
	w.set_flag("door.open")
	check_eq(_row(_render(w), 1), "....", "variant row replaces the wall")


func test_hidden_thing_only_after_listen() -> void:
	var w: RefCounted = _world(["trait.listener"] as Array[String])
	check_eq(_row(_render(w, false), 0), "...>", "before Listen")
	check_eq(_row(_render(w, true), 0), "..?>", "after Listen with the trait")
	check_eq(_row(_render(_world(), true), 0), "...>", "after Listen without the trait")


func test_late_thing_at_chapter_three() -> void:
	var w: RefCounted = _world()
	check_eq(_row(_render(w), 0).find("T"), -1, "no late thing in chapter 1")
	w.chapter = 3
	check_eq(_row(_render(w), 0), ".T.>", "late thing in chapter 3")
	check(_render(w).contains("late (1,0)"), "late thing listed in chapter 3")
