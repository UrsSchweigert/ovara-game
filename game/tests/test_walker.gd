extends "res://tests/test_case.gd"

const Area: GDScript = preload("res://rules/area.gd")
const Walker: GDScript = preload("res://tools/walker.gd")

const LEGEND: Dictionary = {".": {}, "#": {"blocks": true}, "g": {}}


func _area(extra: Dictionary) -> RefCounted:
	var d: Dictionary = {"id": "fix", "legend": LEGEND, "rows": ["...", "...", "..."], "spawn": [0, 0]}
	d.merge(extra, true)
	return Area.from_dict(d)


func test_reachable_targets_pass() -> void:
	var a: RefCounted = _area({
		"exits": [{"cell": [2, 0], "to": "o", "to_cell": [0, 0]}],
		"things": [{"id": "stone", "canon": "x.y", "cell": [0, 2]}],
		"people": [{"id": "sefa", "cell": [2, 2]}],
	})
	check_eq(Walker.walk(a), [] as Array[String], "all reachable")


func test_walled_off_thing_fails() -> void:
	var a: RefCounted = _area({
		"rows": ["..#.", "..##", "###."],
		"things": [{"id": "lost", "canon": "x.y", "cell": [3, 2]}],
	})
	var found: Array[String] = Walker.walk(a)
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "lost" in found[0], "message names the thing")


func test_flag_gated_thing_checked_in_its_state() -> void:
	var a: RefCounted = _area({
		"rows": ["..#.", "..#.", "..#."],
		"things": [{"id": "late", "canon": "x.y", "cell": [3, 0], "when": {"flag": "f"}}],
	})
	check_eq(Walker.walk(a).size(), 1, "unreachable once the flag is set")
	var b: RefCounted = _area({
		"rows": ["..#.", "..#.", "..#."],
		"things": [{"id": "late", "canon": "x.y", "cell": [3, 0], "when": {"flag": "f"}}],
		"variants": [{"when": {"flag": "f"}, "rows": ["....", "....", "...."]}],
	})
	check_eq(Walker.walk(b), [] as Array[String], "variant opens the way")


func test_hidden_thing_and_trait_cell_are_reached() -> void:
	var a: RefCounted = _area({
		"rows": [".#.", ".g.", ".#."],
		"trait_access": [{"cell": [1, 1], "trait": "trait.diver"}],
		"things": [{"id": "mark", "canon": "x.y", "cell": [2, 2], "hidden": {"trait": "trait.listener"}}],
	})
	check_eq(Walker.walk(a), [] as Array[String], "traits granted")


func test_no_spawn_fails() -> void:
	var a: RefCounted = _area({})
	a.data.erase("spawn")
	check_eq(Walker.walk(a).size(), 1, "spawn message")
