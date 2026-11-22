extends "res://tests/test_case.gd"

const World: GDScript = preload("res://rules/world_state.gd")
const People: GDScript = preload("res://rules/people.gd")


func _person() -> Dictionary:
	return {"id": "visitor", "topics": [
		{"topic": "topic.name", "dialogue": "d"},
		{"topic": "topic.rain", "dialogue": "d", "when": {"chapter_min": 2, "chapter_max": 4}},
		{"topic": "topic.door", "dialogue": "d", "when": {"flag": "door.open"}},
		{"topic": "topic.shut", "dialogue": "d", "when": {"not_flag": "door.open"}},
		{"topic": "topic.long", "dialogue": "d"},
	]}


func _panel(line_count: int) -> Dictionary:
	var lines: Array = []
	for i: int in line_count:
		lines.append("line")
	return {"speaker": "person.visitor", "lines": lines}


func _dialogues() -> Dictionary:
	return {"d": {"id": "d", "person": "person.visitor", "topics": [
		{"topic": "topic.name", "names_hero": true, "panels": [_panel(2)], "sets": ["said.name"], "next": ["topic.rain"]},
		{"topic": "topic.rain", "panels": [_panel(3)]},
		{"topic": "topic.door", "panels": [_panel(1)]},
		{"topic": "topic.shut", "panels": [_panel(1)]},
		{"topic": "topic.long", "panels": [_panel(4)]},
	]}}


func _world(chapter: int) -> RefCounted:
	var w: RefCounted = World.new()
	w.chapter = chapter
	for t: String in ["topic.name", "topic.rain", "topic.door", "topic.shut", "topic.long"]:
		People.learn_topic(w, t)
	return w


func test_no_one_names_the_hero_before_chapter_7() -> void:
	for ch: int in [1, 4, 6]:
		var w: RefCounted = _world(ch)
		check(not People.available_topics(_person(), _dialogues(), w).has("topic.name"), "offered at chapter %d" % ch)
		check(not bool(People.ask(_person(), _dialogues(), "topic.name", w)["ok"]), "asked at chapter %d" % ch)
		check(not w.has_flag("said.name"), "flag set at chapter %d" % ch)
	var late: RefCounted = _world(7)
	check(People.available_topics(_person(), _dialogues(), late).has("topic.name"), "not offered at chapter 7")


func test_mark_disappears_after_heard() -> void:
	var w: RefCounted = _world(1)
	var p: Dictionary = _person()
	(p["topics"] as Array).pop_back()
	var d: Dictionary = _dialogues()
	check(People.has_news(p, d, w), "no mark with a new topic")
	for t: String in People.available_topics(p, d, w):
		People.ask(p, d, t, w)
	check(not People.has_news(p, d, w), "mark stays after asking everything")
	check(People.heard("visitor", "topic.shut", w), "topic not marked heard")
	w.set_flag("door.open")
	check(People.has_news(p, d, w), "mark missing for topic opened by flag")


func test_list_filtered_by_chapter_and_flag() -> void:
	var w: RefCounted = _world(1)
	var p: Dictionary = _person()
	var d: Dictionary = _dialogues()
	check_eq(People.available_topics(p, d, w), ["topic.shut", "topic.long"] as Array[String], "chapter 1")
	w.chapter = 3
	w.set_flag("door.open")
	check_eq(People.available_topics(p, d, w), ["topic.rain", "topic.door", "topic.long"] as Array[String], "chapter 3 with flag")
	w.chapter = 5
	check_eq(People.available_topics(p, d, w), ["topic.door", "topic.long"] as Array[String], "chapter 5")


func test_topic_not_held_is_not_listed() -> void:
	var w: RefCounted = World.new()
	check_eq(People.available_topics(_person(), _dialogues(), w).size(), 0, "no held topics")


func test_ask_sets_flags_teaches_topics_and_saves() -> void:
	var w: RefCounted = World.new()
	w.chapter = 7
	People.learn_topic(w, "topic.name")
	People.learn_topic(w, "topic.name")
	var r: Dictionary = People.ask(_person(), _dialogues(), "topic.name", w)
	check(bool(r["ok"]), "ask refused: %s" % r["error"])
	check(w.has_flag("said.name"), "flag not set")
	check_eq(w.topics_known, ["topic.name", "topic.rain"] as Array[String], "known topics")
	var back: RefCounted = World.from_json(w.to_json())
	check(back != null, "save refused")
	if back != null:
		check_eq(back.topics_known, w.topics_known, "known topics after load")
		check_eq(back.topics_heard, w.topics_heard, "heard topics after load")


func test_panel_over_three_lines_refused() -> void:
	var w: RefCounted = _world(1)
	var r: Dictionary = People.ask(_person(), _dialogues(), "topic.long", w)
	check(not bool(r["ok"]), "long panel accepted")
	check(not People.heard("visitor", "topic.long", w), "refused ask marked heard")


func test_condition_day_min() -> void:
	var w: RefCounted = World.new()
	check(not People.condition_met({"day_min": 3}, w), "day 1 met day_min 3")
	w.advance_days(2)
	check(People.condition_met({"day_min": 3}, w), "day 3 unmet day_min 3")


func test_condition_heard() -> void:
	var w: RefCounted = _world(1)
	var cond: Dictionary = {"heard": [{"person": "visitor", "topic": "topic.long"}]}
	check(not People.condition_met(cond, w), "unheard topic met")
	People.ask(_person(), _dialogues(), "topic.long", w)
	check(not People.condition_met(cond, w), "refused ask marks heard")
	People.ask(_person(), _dialogues(), "topic.shut", w)
	cond = {"heard": [{"person": "visitor", "topic": "topic.shut"}]}
	check(People.condition_met(cond, w), "heard topic unmet")
	cond["heard"].append({"person": "visitor", "topic": "topic.door"})
	check(not People.condition_met(cond, w), "one of two heard met")


func test_condition_holds_sums_packs() -> void:
	var w: RefCounted = World.new()
	var cond: Dictionary = {"holds": {"hook": 3}}
	check(not People.condition_met(cond, w), "empty packs met")
	w.packs["a"] = {"hook": 1}
	w.packs["b"] = {"hook": 1, "rope": 4}
	check(not People.condition_met(cond, w), "two of three met")
	w.packs["b"]["hook"] = 2
	check(People.condition_met(cond, w), "three over two packs unmet")
	check(not People.condition_met({"holds": {"hook": 3, "net": 1}}, w), "missing item met")


func test_condition_entered() -> void:
	var w: RefCounted = World.new()
	var cond: Dictionary = {"entered": [{"area": "a", "cell": [2, 3]}]}
	check(not People.condition_met(cond, w), "unentered cell met")
	w.record_entry("a", Vector2i(2, 3))
	check(People.condition_met(cond, w), "entered cell unmet")
	cond["entered"].append({"area": "a", "cell": [0, 0]})
	check(not People.condition_met(cond, w), "one of two cells met")


func test_condition_used() -> void:
	var w: RefCounted = World.new()
	var cond: Dictionary = {"used": {"frond": 2}}
	check(not People.condition_met(cond, w), "unused thing met")
	w.record_use("frond")
	check(not People.condition_met(cond, w), "one of two uses met")
	w.record_use("frond")
	check(People.condition_met(cond, w), "two uses unmet")


func test_condition_combined_and_empty() -> void:
	var w: RefCounted = World.new()
	w.chapter = 2
	w.advance_days(1)
	w.packs["a"] = {"hook": 1}
	var cond: Dictionary = {"chapter_min": 2, "flag": "door.open", "day_min": 2, "holds": {"hook": 1}}
	check(not People.condition_met(cond, w), "met without flag")
	w.set_flag("door.open")
	check(People.condition_met(cond, w), "unmet with all keys")
	w.chapter = 1
	check(not People.condition_met(cond, w), "met below chapter_min")
	check(People.condition_met({}, w), "empty condition false")
