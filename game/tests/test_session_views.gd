extends "res://tests/test_case.gd"

const Session: GDScript = preload("res://rules/session.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")
const People: GDScript = preload("res://rules/people.gd")
const World: GDScript = preload("res://rules/world_state.gd")

const PATH: String = "user://test_session_views.json"


func _content() -> Dictionary:
	var area: Dictionary = {"id": "a", "legend": {".": {}}, "rows": ["...."], "spawn": [0, 0], "exits": [], "things": []}
	var quest: Dictionary = {"id": "s1", "title": "First", "kind": "discover", "giver": "person.x", "chapters": [1, 1],
		"steps": [{"id": "hear", "intent": "Ask Sefa.", "points": 1, "difficulty": 8,
			"requires": {"heard": [{"person": "sefa", "topic": "place.a"}]}},
			{"id": "later", "intent": "Go on.", "points": 1, "difficulty": 8, "requires": {"day_min": 9}}],
		"clears": "s1.done", "sets": []}
	var side: Dictionary = {"id": "sd", "side": true, "kind": "discover", "giver": "person.x", "chapters": [1, 1],
		"steps": [{"id": "x", "intent": "Side.", "points": 1, "difficulty": 8, "requires": {"day_min": 9}}],
		"clears": "sd.done", "sets": []}
	var sefa: Dictionary = {"id": "sefa", "canon": "person.sefa", "portrait": "sefa_a", "topics": [{"topic": "place.a", "dialogue": "d"}]}
	var hero: Dictionary = {"id": "hero", "canon": "person.hero", "names": [{"from_chapter": 7, "name": "Ruel"}, {"from_chapter": 1, "name": "Wrack"}]}
	var d: Dictionary = {"d": {"id": "d", "topics": [{"topic": "place.a", "panels": [
		{"speaker": "person.sefa", "lines": ["One.", "Two."]}, {"speaker": "person.hero", "lines": ["Three."]}]}]}}
	return {"areas": {"a": area}, "quests": [quest, side], "people": {"sefa": sefa, "hero": hero}, "dialogues": d}


func _session(store: RefCounted = null) -> RefCounted:
	var s: RefCounted = Session.new_game(_content(), store)
	People.learn_topic(s.world, "place.a")
	return s


func test_talk_lists_topics_with_news() -> void:
	var s: RefCounted = _session()
	var t: Dictionary = s.talk("sefa")
	check(t["ok"], "known person")
	check_eq(t["name"], "sefa", "no names falls back to id")
	check_eq(t["portrait"], "sefa_a", "portrait key")
	check_eq(t["topics"], [{"topic": "place.a", "news": true}], "news before asking")
	s.ask("sefa", "place.a")
	check_eq(s.talk("sefa")["topics"], [{"topic": "place.a", "news": false}], "no news after")
	check(not s.talk("nobody")["ok"], "unknown person")


func test_ask_panels_and_save() -> void:
	var store: RefCounted = SaveStore.new(PATH)
	store.call("clear")
	var s: RefCounted = _session(store)
	var r: Dictionary = s.ask("sefa", "place.a")
	check(r["ok"], "asked")
	check_eq(r["panels"].size(), 2, "two panels")
	check_eq(r["panels"][0]["speaker"], "sefa", "speaker name")
	check_eq(r["panels"][0]["portrait"], "sefa_a", "portrait")
	check_eq(r["panels"][1]["speaker"], "Wrack", "hero speaks by chapter name")
	check_eq(r["steps_done"], ["s1:hear"], "step done by asking")
	check(bool(store.call("load_state")["state"] != null), "saved on step")
	store.call("clear")


func test_refused_ask_changes_nothing() -> void:
	var s: RefCounted = _session()
	var r: Dictionary = s.ask("sefa", "place.zzz")
	check(not r["ok"], "refused")
	check(not People.heard("sefa", "place.zzz", s.world), "not heard")
	check(not s.ask("nobody", "place.a")["ok"], "unknown person")


func test_display_name_by_chapter() -> void:
	var s: RefCounted = _session()
	var hero: Dictionary = s.people["hero"]
	var w: RefCounted = World.new()
	var seen: Array[String] = []
	for ch: int in [1, 3, 6, 7, 9]:
		w.chapter = ch
		seen.append(People.display_name(hero, w))
	check_eq(seen, ["Wrack", "Wrack", "Wrack", "Ruel", "Ruel"] as Array[String], "never early")
	w.chapter = 0
	check_eq(People.display_name({"id": "h", "names": [{"from_chapter": 2, "name": "X"}]}, w), "h", "before first name")


func test_journal_view() -> void:
	var s: RefCounted = _session()
	(load("res://rules/quest_engine.gd") as GDScript).call("open", s.quests[1], s.world)
	var j: Dictionary = s.journal_view()
	check_eq(j["stage"]["title"], "First", "stage title")
	check_eq(j["stage"]["next"], "Ask Sefa.", "next intent")
	check_eq(j["open"].size(), 1, "one open side quest")
	s.ask("sefa", "place.a")
	check_eq(s.journal_view()["stage"]["next"], "Go on.", "next advances")


func test_party_and_pack_views() -> void:
	var s: RefCounted = _session()
	var sheet: RefCounted = (load("res://rules/character_sheet.gd") as GDScript).call("from_dict", {"id": "hero", "body": 12, "standing": 9, "reach": 2, "skills": {"nets": 2}})
	s.world.sheets["hero"] = sheet
	s.world.add_ebb("hero", 3)
	s.world.position["guests"] = ["sefa"]
	var p: Dictionary = s.party_view()
	check_eq(p["members"][0]["name"], "Wrack", "member name")
	check_eq(p["members"][0]["body"], 12, "body")
	check_eq(p["members"][0]["limit"], 9, "ebb limit")
	check_eq(p["members"][0]["ebb"], 3, "ebb")
	check_eq(p["members"][0]["skills"], [{"skill": "nets", "step": 2}], "skills")
	check_eq(p["guests"][0]["id"], "sefa", "guest listed")
	s.world.packs["hero"] = {"item.frond": 3, "item.rope": 1}
	s.world.supplies["supply.water"] = 4
	var k: Dictionary = s.pack_view()
	check_eq(k["people"][0]["slots"], 2, "slots")
	check_eq(k["people"][0]["items"][0], {"item": "item.frond", "count": 3}, "counts")
	check_eq(k["supplies"], {"supply.water": 4}, "supplies")
