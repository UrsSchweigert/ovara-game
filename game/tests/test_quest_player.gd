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


func test_heard_topic_learned_by_next() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("n1", "ione", "power.y")
	var people: Dictionary = _people()
	(people["ione"]["topics"] as Array).append({"topic": "power.y", "dialogue": "d", "when": {}})
	var dialogues: Dictionary = _dialogues()
	(dialogues["d"]["topics"][0] as Dictionary)["next"] = ["power.y"]
	(dialogues["d"]["topics"] as Array).append({"topic": "power.y", "panels": [{"speaker": "person.ione", "lines": ["Next."]}]})
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], people, dialogues)
	check_eq(found, [] as Array[String], "no errors")
	check(People.heard("ione", "power.x", w), "opening topic asked first")
	check(People.heard("ione", "power.y", w), "next topic heard")


func test_all_conditions_need_play() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("m1", "")
	q["steps"][1]["requires"] = {"day_min": 3, "holds": {"thing.x": 1}, "heard": [{"person": "ione", "topic": "power.x"}]}
	Quests.update(q, w)
	check(Quests.status(q, w) != Quests.CLEARED, "update alone does not clear")
	check(not Quests.is_done(q, "b", w), "step b open")
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], ["thing.x"] as Array[String], _people(), _dialogues())
	check_eq(found, [] as Array[String], "no errors")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared by play")
	check_eq(w.day, 3, "days passed")


func test_unsatisfiable_flag_beside_heard_names_flag_step() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("m2", "ione", "power.x")
	q["steps"].append({"id": "c", "intent": "Wait.", "points": 1, "difficulty": 8, "requires": {"flag": "nobody.sets"}})
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(), _dialogues())
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "stuck at step c" in found[0] and not "step b" in found[0], "names only step c")


const Area: GDScript = preload("res://rules/area.gd")


func _real(dir: String) -> Dictionary:
	var out: Dictionary = {}
	for file: String in DirAccess.get_files_at("res://content/" + dir):
		var d: Dictionary = People.load_json("res://content/%s/%s" % [dir, file])
		out[str(d.get("id", ""))] = d
	return out


func _stage1_targets() -> Dictionary:
	return {"follow_sefa": {"exit": "low_anthem_dome_hall"}, "cut_fronds": {"thing": "drying_rack_1"},
		"nursery_gate": {"thing": "nursery_gate"}, "meeting_hall_lamp": {"thing": "dead_lamp"}}


func _stage1_person_areas() -> Dictionary:
	return {"sefa": "low_anthem_dry_room", "ione": "low_anthem_dome_hall", "davin": "low_anthem_dome_hall"}


func _tiny_area(id: String, to: String) -> RefCounted:
	var d: Dictionary = {"id": id, "spawn": [0, 0], "rows": ["..."], "legend": {".": {}}}
	if to != "":
		d["exits"] = [{"cell": [2, 0], "to": to, "to_cell": [0, 0]}]
	return Area.from_dict(d)


func test_person_asked_in_their_area() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("w1", "ione", "power.x")
	q["steps"][1]["area"] = "a"
	var areas: Dictionary = {"a": _tiny_area("a", "b"), "b": _tiny_area("b", "")}
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(), _dialogues(), areas, {}, {"ione": "b"})
	check_eq(found, [] as Array[String], "no errors")
	check_eq(str(w.position["area"]), "b", "party is in the person's area")
	check(w.has_entered("a", Vector2i(2, 0)), "entry went through Area.enter")
	check(People.heard("ione", "power.x", w), "heard")


func test_person_in_unreachable_area_fails() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("w2", "ione", "power.x")
	q["steps"][1]["area"] = "a"
	var areas: Dictionary = {"a": _tiny_area("a", ""), "b": _tiny_area("b", "")}
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(), _dialogues(), areas, {}, {"ione": "b"})
	check(found.size() > 0 and "ione" in found[0] and "power.x" in found[0] and " b" in found[0], "names person, topic, area")
	check(not People.heard("ione", "power.x", w), "not asked")


func test_ask_from_wrong_area_fails() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _hearing("w3", "ione", "power.x")
	q["steps"][1]["area"] = "a"
	var areas: Dictionary = {"a": _tiny_area("a", "b"), "b": _tiny_area("b", "")}
	w.position = {"area": "a", "x": 0, "y": 0}
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people(), _dialogues(), areas, {}, {"ione": "c"})
	check(found.size() > 0 and "ione" in found[0] and "power.x" in found[0] and " c" in found[0], "wrong area is an error")
	check(not People.heard("ione", "power.x", w), "not asked")


func _real_areas() -> Dictionary:
	var out: Dictionary = {}
	for d: Variant in _real("areas").values():
		out[str((d as Dictionary)["id"])] = Area.from_dict(d)
	return out


func _play_stage1(people: Dictionary, w: RefCounted) -> Array[String]:
	var q: Dictionary = People.load_json("res://content/quests/stage_1.json")
	var items: Array[String] = ["frond"]
	return QuestPlayer.play(q, w, [q] as Array[Dictionary], items, people, _real("dialogue"), _real_areas(), _stage1_targets(), _stage1_person_areas())


func test_stage1_needs_play() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = People.load_json("res://content/quests/stage_1.json")
	Quests.open(q, w)
	Quests.update(q, w)
	check(Quests.status(q, w) != Quests.CLEARED, "update alone does not clear")
	var w2: RefCounted = World.new()
	check_eq(_play_stage1(_real("people"), w2), [] as Array[String], "no errors")
	check_eq(w2.chapter, 2, "chapter advanced")


func test_stage1_missing_topic_is_stuck() -> void:
	var people: Dictionary = _real("people").duplicate(true)
	var sefa: Dictionary = people["sefa"]
	var kept: Array = []
	for t: Variant in sefa["topics"]:
		if str((t as Dictionary)["topic"]) != "person.jef":
			kept.append(t)
	sefa["topics"] = kept
	var found: Array[String] = _play_stage1(people, World.new())
	check(found.size() > 0 and "person.jef" in found[0], "names the missing topic")


func test_walled_target_has_no_path() -> void:
	var data: Dictionary = (_real("areas")["low_anthem_terraces"] as Dictionary).duplicate(true)
	data["rows"] = ["#".repeat(str(data["rows"][0]).length())]
	data["legend"]["#"] = {"blocks": true}
	var areas: Dictionary = {"low_anthem_terraces": Area.from_dict(data)}
	var q: Dictionary = People.load_json("res://content/quests/stage_1.json")
	var found: Array[String] = QuestPlayer.play(q, World.new(), [q] as Array[Dictionary], [] as Array[String], {}, {}, areas, _stage1_targets())
	check(found.size() > 0 and "no path" in found[0], "reports no path")


func _waiting(offered_from_day: int, day_min: int) -> Dictionary:
	var q: Dictionary = _hearing("w1", "ione", "power.x")
	q["steps"][1]["requires"]["day_min"] = day_min
	return q


func _people_from_day(day: int) -> Dictionary:
	var people: Dictionary = _people()
	(people["ione"]["topics"][0] as Dictionary)["when"] = {"day_min": day}
	return people


func test_topic_offered_on_day_two_is_heard_day_by_day() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _waiting(2, 3)
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people_from_day(2), _dialogues())
	check_eq(found, [] as Array[String], "no errors")
	check(People.heard("ione", "power.x", w), "topic heard")
	check_eq(w.day, 3, "stopped at day_min, no further")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared after the days")


func test_days_never_jump() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _waiting(2, 4)
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people_from_day(2), _dialogues())
	check_eq(found, [] as Array[String], "no errors")
	check_eq(w.day, 4, "each day passed once")
	check(People.heard("ione", "power.x", w), "topic heard")


func test_step_not_done_before_days_pass() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _waiting(2, 3)
	Quests.update(q, w)
	check(not Quests.is_done(q, "b", w), "step open before play")
	check_eq(w.day, 1, "calendar untouched by update")


func test_topic_never_offered_before_day_min_errors() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _waiting(9, 3)
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], _people_from_day(9), _dialogues())
	check_eq(found.size(), 1, "one message")
	check(found.size() > 0 and "power.x" in found[0] and "day 3" in found[0], "names topic and day")


func _thing_area(things: Array) -> RefCounted:
	return Area.from_dict({"id": "a", "spawn": [0, 0], "rows": ["..."], "legend": {".": {}}, "things": things})


func _thing(id: String, cell: int, use: Dictionary = {}) -> Dictionary:
	var t: Dictionary = {"id": id, "cell": [cell, 0]}
	if not use.is_empty():
		t["use"] = use
	return t


func test_holds_cleared_by_using_giving_thing() -> void:
	var w: RefCounted = World.new()
	w.party = ["hero"] as Array[String]
	var q: Dictionary = _holding("t1", "item.frond", 2)
	q["steps"][1]["area"] = "a"
	var areas: Dictionary = {"a": _thing_area([_thing("thing.frond", 2, {"gives": {"item": "item.frond", "count": 1}, "max": 5})])}
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], {}, {}, areas)
	check_eq(found, [] as Array[String], "no errors")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared")
	check_eq(w.uses_of("thing.frond"), 2, "used twice")
	check(w.has_entered("a", Vector2i(2, 0)), "walked to the thing")
	check(not w.packs.has(QuestPlayer.STAND_IN_KEY), "no fallback grant")


func test_used_count_three_clears_after_three_uses() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("t2", "")
	q["steps"][1]["requires"] = {"used": {"thing.lever": 3}}
	q["steps"][1]["area"] = "a"
	var areas: Dictionary = {"a": _thing_area([_thing("thing.lever", 1)])}
	check_eq(QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], {}, {}, areas), [] as Array[String], "no errors")
	check_eq(w.uses_of("thing.lever"), 3, "three uses")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared")


func test_entered_step_clears_after_walk() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("t3", "")
	q["steps"][1]["requires"] = {"entered": [{"area": "a", "cell": [2, 0]}]}
	var areas: Dictionary = {"a": _thing_area([])}
	check(not w.has_entered("a", Vector2i(2, 0)), "not yet entered")
	check_eq(QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], {}, {}, areas), [] as Array[String], "no errors")
	check(w.has_entered("a", Vector2i(2, 0)), "entered")
	check_eq(Quests.status(q, w), Quests.CLEARED, "cleared")


func test_used_missing_thing_is_named() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _quest("t4", "")
	q["steps"][1]["requires"] = {"used": {"thing.gone": 1}}
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], [] as Array[String], {}, {}, {"a": _thing_area([])})
	check(found.size() > 0 and "thing.gone" in found[0] and "step b" in found[0], "names thing and step")


func test_holds_without_giving_thing_uses_fallback() -> void:
	var w: RefCounted = World.new()
	var q: Dictionary = _holding("t5", "item.x", 1)
	var found: Array[String] = QuestPlayer.play(q, w, [q] as Array[Dictionary], ["item.x"] as Array[String], {}, {}, {"a": _thing_area([_thing("thing.plain", 1)])})
	check_eq(found, [] as Array[String], "no errors")
	check_eq((w.packs[QuestPlayer.STAND_IN_KEY] as Dictionary)["item.x"], 1, "fallback grant")
