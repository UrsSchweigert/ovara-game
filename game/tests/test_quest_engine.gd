extends "res://tests/test_case.gd"

const World: GDScript = preload("res://rules/world_state.gd")
const Quests: GDScript = preload("res://rules/quest_engine.gd")


func _stage() -> Dictionary:
	return {"id": "stage_1", "kind": "discover", "giver": "person.sefa", "chapters": [1, 1],
		"steps": [
			{"id": "arrive", "intent": "Follow Sefa to the sea-door.", "points": 1, "difficulty": 8, "sets": ["low_anthem.accepted"]},
			{"id": "fronds", "intent": "Cut ten fronds.", "points": 2, "difficulty": 8},
			{"id": "lamp", "intent": "Light the lamp.", "points": 3, "difficulty": 12,
				"requires": {"flag": "lamp.fixed"}, "sets": ["hero.craft_mend"]},
		],
		"clears": "low_anthem.lamp_lit", "sets": ["low_anthem.accepted", "hero.craft_mend"]}


func _side() -> Dictionary:
	return {"id": "side_a", "kind": "fetch", "giver": "person.sefa", "chapters": [1, 3], "side": true, "place": "low_anthem",
		"steps": [{"id": "one", "intent": "Fetch it.", "points": 2, "difficulty": 8}],
		"clears": "side_a.done", "sets": []}


func _world() -> RefCounted:
	var w: RefCounted = World.new()
	w.party.append("wrack")
	w.party.append("sefa")
	return w


func test_points_awarded_once() -> void:
	var w: RefCounted = _world()
	var q: Dictionary = _stage()
	check(Quests.open(q, w), "did not open")
	check_eq(Quests.complete_step(q, "arrive", w), 1, "first completion")
	check_eq(Quests.complete_step(q, "arrive", w), 0, "second completion")
	check_eq(w.points["wrack"], 1, "wrack points")
	check_eq(w.points["sefa"], 1, "sefa points")


func test_battle_gives_none() -> void:
	var w: RefCounted = _world()
	check_eq(Quests.award_battle(w), 0, "battle points")
	check(w.points.is_empty(), "points held after battle")


func test_stage_clearing_sets_flags_and_advances() -> void:
	var w: RefCounted = _world()
	var q: Dictionary = _stage()
	Quests.open(q, w)
	Quests.complete_step(q, "arrive", w)
	Quests.complete_step(q, "fronds", w)
	check(not Quests.update(q, w), "cleared before the lamp")
	check_eq(w.chapter, 1, "chapter moved early")
	check_eq(w.journal[w.journal.size() - 1], "Light the lamp.", "journal next step")
	w.set_flag("lamp.fixed")
	check(Quests.update(q, w), "did not clear")
	for f: String in ["low_anthem.accepted", "low_anthem.lamp_lit", "hero.craft_mend"]:
		check(w.has_flag(f), "flag missing " + f)
	check_eq(w.chapter, 2, "chapter")
	check_eq(w.points["wrack"], 1 + 2 + 3 + Quests.STAGE_POINTS, "points with bonus")
	check(not Quests.update(q, w), "cleared twice")
	check_eq(w.chapter, 2, "chapter moved twice")


func test_side_quest_closes_with_its_place_and_says_so() -> void:
	var w: RefCounted = _world()
	var q: Dictionary = _side()
	Quests.open(q, w)
	var before: int = w.journal.size()
	check_eq(Quests.close_for_place([q], "low_anthem", w), ["side_a"] as Array[String], "closed list")
	check_eq(Quests.status(q, w), Quests.CLOSED, "status")
	check_eq(w.journal.size(), before + 1, "close not journalled")
	check_eq(Quests.complete_step(q, "one", w), 0, "closed quest paid")


func test_side_quest_does_not_advance_chapter() -> void:
	var w: RefCounted = _world()
	var q: Dictionary = _side()
	Quests.open(q, w)
	Quests.complete_step(q, "one", w)
	check(Quests.try_clear(q, w), "did not clear")
	check_eq(w.chapter, 1, "chapter")
	check_eq(w.points["wrack"], 2, "no stage bonus")


func test_open_respects_chapters() -> void:
	var w: RefCounted = _world()
	w.chapter = 5
	check(not Quests.open(_stage(), w), "opened outside its chapters")


func test_flags_read_are_settable() -> void:
	var q: Dictionary = _stage()
	check_eq(Quests.unsettable_reads(q), ["lamp.fixed"] as Array[String], "lamp.fixed is set by play, not the quest")
	check(Quests.settable_flags(q).has("low_anthem.lamp_lit"), "clears flag")


func test_save_round_trip_keeps_quests() -> void:
	var w: RefCounted = _world()
	var q: Dictionary = _stage()
	Quests.open(q, w)
	Quests.complete_step(q, "arrive", w)
	var back: RefCounted = World.from_json(w.to_json())
	check(back != null, "save refused")
	check(Quests.is_done(q, "arrive", back), "step lost")
	check_eq(back.points["sefa"], 1, "points lost")
	check_eq(Quests.complete_step(q, "arrive", back), 0, "paid again after load")


func test_step_requires_entry_and_use() -> void:
	var w: RefCounted = _world()
	var q: Dictionary = {"id": "q", "kind": "discover", "giver": "person.sefa", "chapters": [1, 1],
		"steps": [
			{"id": "go", "intent": "Go.", "points": 1, "difficulty": 8, "requires": {"entered": [{"area": "a", "cell": [1, 1]}]}},
			{"id": "cut", "intent": "Cut.", "points": 1, "difficulty": 8, "requires": {"used": {"frond": 2}}},
		],
		"clears": "q.done", "sets": []}
	Quests.open(q, w)
	check(not Quests.update(q, w), "cleared untouched")
	check(not w.has_flag("q.done"), "flag set untouched")
	w.record_entry("a", Vector2i(1, 1))
	w.record_use("frond")
	check(not Quests.update(q, w), "cleared with one use")
	w.record_use("frond")
	check(Quests.update(q, w), "did not clear after entry and uses")
