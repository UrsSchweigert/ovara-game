extends "res://tests/test_case.gd"

const World: GDScript = preload("res://rules/world_state.gd")
const Quests: GDScript = preload("res://rules/quest_engine.gd")
const QuestPlayer: GDScript = preload("res://tools/quest_player.gd")


func _quest(id: String, requires_flag: String, side: bool = false, day_min: int = 0) -> Dictionary:
	var gated: Dictionary = {"id": "b", "intent": "Wait.", "points": 1, "difficulty": 8}
	if requires_flag != "":
		gated["requires"] = {"flag": requires_flag}
	if day_min > 0:
		gated["requires"] = {"day_min": day_min}
	return {"id": id, "kind": "discover", "giver": "person.x", "chapters": [1, 1], "side": side,
		"steps": [{"id": "a", "intent": "Go.", "points": 1, "difficulty": 8, "sets": ["%s.a" % id]}, gated],
		"clears": "%s.done" % id, "sets": []}


func test_fixture_stage_is_cleared() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("s1", "outside.flag")
	var helper: Dictionary = _quest("helper", "")
	helper["steps"][0]["sets"] = ["outside.flag"]
	var found: Array[String] = QuestPlayer.play(q, w, [q, helper] as Array[Dictionary])
	check_eq(found, [] as Array[String], "no errors")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared")
	check_eq(w.chapter, 2, "chapter advanced")


func test_flag_nobody_sets_is_stuck() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("s1", "nobody.sets")
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary])
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "stuck at step b" in found[0], "names the step")


func test_side_quest_leaves_chapter() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("side", "", true)
	check_eq(QuestPlayer.play(q, w, [q] as Array[Dictionary]), [] as Array[String], "no errors")
	check_eq(w.chapter, 1, "chapter unchanged")


func test_day_min_advances_forward() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("d1", "", false, 3)
	check_eq(QuestPlayer.play(q, w, [q] as Array[Dictionary]), [] as Array[String], "no errors")
	check(Quests.is_done(q, "b", w), "step b done")
	check_eq(w.day, 3, "day advanced to 3")


func test_day_min_never_moves_back() -> void:
	var w: RefCounted = World.new()
	w.advance_days(4)
	var q: Dictionary = _quest("d2", "", false, 3)
	check_eq(QuestPlayer.play(q, w, [q] as Array[Dictionary]), [] as Array[String], "no errors")
	check(Quests.is_done(q, "b", w), "step b done")
	check_eq(w.day, 5, "day unchanged past day_min")
