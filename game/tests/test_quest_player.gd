extends "res://tests/test_case.gd"

const World: GDScript = preload("res://rules/world_state.gd")
const Quests: GDScript = preload("res://rules/quest_engine.gd")
const People: GDScript = preload("res://rules/people.gd")
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


func _holding(id: String, item_id: String, count: int) -> Dictionary:
	var q: Dictionary = _quest(id, "")
	q["steps"][1]["requires"] = {"holds": {item_id: count}}
	return q


func test_holds_known_item_clears() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _holding("h1", "thing.x", 2)
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], ["thing.x"] as Array[String])
	check_eq(found, [] as Array[String], "no errors")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared")
	check_eq((w.packs[QuestPlayer.STAND_IN_KEY] as Dictionary)["thing.x"], 2, "pack holds two")


func test_holds_unknown_item_names_step() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _holding("h2", "thing.x", 1)
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary])
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "h2" in found[0] and "step b" in found[0] and "thing.x" in found[0], "names quest, step and item")


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


func _hearing(id: String, person: String, topic: String) -> Dictionary:
	var q: Dictionary = _quest(id, "")
	q["steps"][1]["requires"] = {"heard": [{"person": person, "topic": topic}]}
	return q


func _people(chapter_min: int = 0) -> Dictionary:
	var when: Dictionary = {"chapter_min": chapter_min} if chapter_min > 0 else {}
	return {"ione": {"id": "ione", "topics": [{"topic": "power.x", "dialogue": "d", "when": when}]}}


func _dialogues() -> Dictionary:
	return {"d": {"id": "d", "topics": [{"topic": "power.x", "panels": [{"speaker": "person.ione", "lines": ["Hello."]}]}]}}


func test_heard_topic_clears() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("e1", "ione", "power.x")
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(), _dialogues())
	check_eq(found, [] as Array[String], "no errors")
	check(People.heard("ione", "power.x", w), "topic heard")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared")


func test_heard_unknown_person() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("e2", "nobody", "power.x")
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(), _dialogues())
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "e2" in found[0] and "step b" in found[0] and "nobody" in found[0] and "power.x" in found[0] and "person is unknown" in found[0], "names quest, step, person, topic")


func test_heard_unknown_topic() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("e3", "ione", "power.none")
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(), _dialogues())
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "e3" in found[0] and "step b" in found[0] and "ione" in found[0] and "power.none" in found[0] and "topic is unknown" in found[0], "names quest, step, person, topic")
	check(not People.heard("ione", "power.none", w), "not faked")


func test_heard_refused_ask() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("e4", "ione", "power.x")
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(5), _dialogues())
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "e4" in found[0] and "step b" in found[0] and "ione" in found[0] and "power.x" in found[0] and "refused" in found[0], "names quest, step, person, topic")
	check(not People.heard("ione", "power.x", w), "not faked")
