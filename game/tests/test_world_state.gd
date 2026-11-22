extends "res://tests/test_case.gd"

const World: GDScript = preload("res://rules/world_state.gd")
const Sheet: GDScript = preload("res://rules/character_sheet.gd")


func _sample() -> RefCounted:
	var w: RefCounted = World.new()
	var s: RefCounted = Sheet.new()
	s.id = "wrack"
	s.body = 12
	s.hands = 9
	s.mind = 12
	s.standing = 14
	s.reach = 5
	s.skills = {"Listen": 2, "Move": 1}
	s.traits.append("kelp-born")
	w.sheets["wrack"] = s
	w.party.append("wrack")
	w.base = {"id": "base.test", "level": 1}
	w.packs = {"wrack": {"flask": 2}}
	w.supplies = {"food": 6}
	w.add_ebb("wrack", 3)
	w.set_flag("a.flag")
	w.set_flag("a.count", 4)
	w.set_flag("a.text", "x")
	w.chapter = 3
	w.advance_watch(4)
	w.journal.append("first entry")
	w.position = {"area": "a1", "x": 3, "y": 4}
	w.mode = "dungeon"
	w.dice_seed = 99
	w.dice.append_array([3, 5, 2])
	return w


func test_round_trip_is_lossless() -> void:
	var w: RefCounted = _sample()
	var back: RefCounted = World.from_json(w.to_json())
	check(back != null, "from_json returned null: %s" % World.last_error)
	if back != null:
		check_eq(back.to_dict(), w.to_dict(), "dict after json round trip")
		check_eq(back.dice, [3, 5, 2], "stored dice are kept, not redrawn")
		check_eq(back.get_flag("a.count"), 4, "flag stays an int")
		check_eq(back.position["x"], 3, "position stays an int")


func test_missing_version_refused() -> void:
	var d: Dictionary = _sample().to_dict()
	d.erase("version")
	check(World.from_dict(d) == null, "missing version accepted")
	check(World.last_error.contains("no version"), "error was '%s'" % World.last_error)


func test_wrong_version_refused() -> void:
	var d: Dictionary = _sample().to_dict()
	d["version"] = 2
	check(World.from_dict(d) == null, "wrong version accepted")
	check(World.last_error.contains("version 2"), "error was '%s'" % World.last_error)
	check(World.from_json("[1]") == null, "non-object accepted")


func test_flags() -> void:
	var w: RefCounted = World.new()
	check(not w.has_flag("x"), "flag present before set")
	check_eq(w.get_flag("x"), false, "default flag value")
	check_eq(w.get_flag("x", 7), 7, "given default")
	w.set_flag("x")
	check_eq(w.get_flag("x"), true, "flag set")


func test_chapter_and_calendar() -> void:
	var w: RefCounted = World.new()
	w.advance_chapter()
	check_eq(w.chapter, 2, "chapter")
	w.advance_watch(2)
	check_eq([w.day, w.watch], [1, 2], "two watches")
	w.advance_watch()
	check_eq([w.day, w.watch], [2, 0], "third watch rolls the day")
	w.advance_watch(7)
	check_eq([w.day, w.watch], [4, 1], "seven watches")
	w.advance_days(2)
	check_eq(w.day, 6, "days")


func test_sheet_derived_values() -> void:
	var w: RefCounted = _sample()
	check_eq(w.health_of("wrack"), 12, "health equals Body")
	check_eq(w.ebb_limit_of("wrack"), 14, "ebb limit equals Standing")
	check_eq(w.sheet_of("wrack").quickness(), 10, "quickness")
	w.add_ebb("wrack", 20)
	check_eq(w.ebb_of("wrack"), 23, "ebb may pass the limit")
