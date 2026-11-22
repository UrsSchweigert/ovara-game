extends "res://tests/test_case.gd"

const Session: GDScript = preload("res://rules/session.gd")
const Cutscene: GDScript = preload("res://rules/cutscene.gd")
const World: GDScript = preload("res://rules/world_state.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")

const PATH: String = "user://test_cutscene.json"


func _scene(skippable: bool = true) -> Dictionary:
	return {"id": "arrive", "area": "a", "skippable": skippable, "steps": [
		{"op": "walk", "who": "person.sefa", "to": [1, 0]},
		{"op": "say", "who": "person.sefa", "lines": ["Land."]},
		{"op": "camera", "to": [2, 1]},
		{"op": "walk", "who": "person.sefa", "to": [2, 2]},
		{"op": "light", "level": 0.5}]}


func _people() -> Dictionary:
	return {"sefa": {"canon": "person.sefa", "portrait": "p_sefa", "names": [{"name": "Sefa", "from_chapter": 1}]}}


func _runner(world: RefCounted, skippable: bool = true) -> RefCounted:
	return Cutscene.new(_scene(skippable), world, _people())


func test_run_to_end() -> void:
	var w: RefCounted = World.new()
	var c: RefCounted = _runner(w)
	check_eq(c.current()["op"], "walk", "first step")
	check_eq(w.figure_cell("person.sefa"), null, "not moved yet")
	var say: Dictionary = c.advance()
	check_eq(w.figure_cell("person.sefa"), Vector2i(1, 0), "walked")
	check_eq(say["speaker"], "Sefa", "display name")
	check_eq(say["portrait"], "p_sefa", "portrait")
	c.advance()
	c.advance()
	check(not c.finished(), "two steps left")
	c.advance()
	c.advance()
	check(c.finished(), "finished")
	check_eq(c.current(), {}, "no step")
	check_eq(w.figure_cell("person.sefa"), Vector2i(2, 2), "ended there")
	check(w.has_seen_scene("arrive"), "seen")


func test_skip_mid_way() -> void:
	var w: RefCounted = World.new()
	var c: RefCounted = _runner(w)
	c.advance()
	check(c.skip()["ok"], "skip allowed")
	check(c.finished(), "finished")
	check_eq(w.figure_cell("person.sefa"), Vector2i(2, 2), "final cell")
	check(w.has_seen_scene("arrive"), "seen")


func test_refused_skip() -> void:
	var w: RefCounted = World.new()
	var c: RefCounted = _runner(w, false)
	check(not c.skip()["ok"], "refused")
	check(not c.finished(), "still running")
	check_eq(w.figure_cell("person.sefa"), null, "nothing moved")
	for i: int in 5:
		c.advance()
	check(c.finished(), "finishes by advancing")
	check(w.has_seen_scene("arrive"), "seen")


func test_old_save_loads() -> void:
	var d: Dictionary = World.new().to_dict()
	d.erase("seen_scenes")
	d.erase("figures")
	var r: Dictionary = World.from_dict(d)
	check(r["state"] != null, "old save loads")
	check(not r["state"].has_seen_scene("arrive"), "none seen")


func _content() -> Dictionary:
	var area: Dictionary = {"id": "a", "legend": {".": {}}, "rows": ["...", "...", "..."], "spawn": [0, 0]}
	var q: Dictionary = {"id": "s1", "kind": "discover", "giver": "person.x", "chapters": [1, 1],
		"steps": [{"id": "go", "intent": "Go.", "points": 1, "difficulty": 8, "requires": {"entered": [{"area": "a", "cell": [2, 2]}]}}],
		"clears": "s1.done", "sets": [], "start": {"area": "a", "cell": [0, 0], "arrival": "arrive"}}
	return {"areas": {"a": area}, "quests": [q], "people": _people(), "cutscenes": {"arrive": _scene()}}


func test_new_game_and_resume() -> void:
	var store: RefCounted = SaveStore.new(PATH)
	store.call("clear")
	var s: RefCounted = Session.new_game(_content(), store)
	check(s.scene != null, "arrival starts")
	check_eq(s.scene_step()["op"], "walk", "first step")
	for i: int in 5:
		s.advance_scene()
	check(s.scene == null, "scene closed")
	var r: RefCounted = Session.resume(store, _content())
	check(r.world.has_seen_scene("arrive"), "seen survives the save")
	check_eq(r.world.figure_cell("person.sefa"), Vector2i(2, 2), "figure survives")
	check(r.scene == null, "not replayed")
	store.call("clear")
