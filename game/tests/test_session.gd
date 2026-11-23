extends "res://tests/test_case.gd"

const Session: GDScript = preload("res://rules/session.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")

const PATH: String = "user://test_session.json"


func _area(id: String, rest: bool, exits: Array, things: Array = []) -> Dictionary:
	return {"id": id, "legend": {".": {}, "#": {"blocks": true}}, "rows": ["....", ".#..", "...."],
		"spawn": [0, 0], "rest": rest, "exits": exits, "things": things}


func _quest(start: Dictionary) -> Dictionary:
	var q: Dictionary = {"id": "s1", "kind": "discover", "giver": "person.x", "chapters": [1, 1],
		"steps": [{"id": "go", "intent": "Go.", "points": 1, "difficulty": 8,
			"requires": {"entered": [{"area": "b", "cell": [1, 0]}]}}],
		"clears": "s1.done", "sets": []}
	if not start.is_empty():
		q["start"] = start
	return q


func _content(start: Dictionary = {}) -> Dictionary:
	var exit: Dictionary = {"cell": [3, 0], "to": "b", "to_cell": [0, 0]}
	var thing: Dictionary = {"id": "t1", "cell": [2, 2], "use": {"gives": {"item": "item.x", "count": 1}, "max": 1}}
	return {"areas": {"a": _area("a", false, [exit], [thing]), "b": _area("b", true, [])},
		"quests": [_quest(start)]}


func _store() -> RefCounted:
	var s: RefCounted = SaveStore.new(PATH)
	s.call("clear")
	return s


func test_new_game_fallback() -> void:
	var s: RefCounted = Session.new_game(_content())
	check_eq(s.area_id(), "a", "first area")
	check_eq(s.cell(), Vector2i(0, 0), "spawn")
	check_eq(s.world.party, ["hero"] as Array[String], "single hero")
	check_eq(s.world.quests["s1"]["status"], "open", "quest opened")


func test_new_game_start_block() -> void:
	var start: Dictionary = {"area": "b", "cell": [2, 0], "party": ["sefa", "ione"], "guests": ["jef"]}
	var s: RefCounted = Session.new_game(_content(start))
	check_eq(s.area_id(), "b", "start area")
	check_eq(s.cell(), Vector2i(2, 0), "start cell")
	check_eq(s.world.party, ["sefa", "ione"] as Array[String], "start party")
	check_eq(s.world.position["guests"], ["jef"], "guests kept")


func test_path_and_step() -> void:
	var s: RefCounted = Session.new_game(_content())
	var path: Array[Vector2i] = s.path_to(Vector2i(2, 1))
	check_eq(path.size(), 4, "path around the wall")
	check_eq(path[0], Vector2i(0, 0), "starts here")
	var bad: Dictionary = s.step_to(Vector2i(2, 0))
	check(not bad["ok"], "no jump")
	var wall: Dictionary = s.step_to(Vector2i(1, 1))
	check(not wall["ok"], "no wall")
	var ok: Dictionary = s.step_to(Vector2i(1, 0))
	check(ok["ok"] and ok["entered"], "stepped")
	check_eq(s.cell(), Vector2i(1, 0), "moved")
	check(s.world.has_entered("a", Vector2i(1, 0)), "entry recorded")


func test_people_block_walking() -> void:
	var c: Dictionary = _content()
	(c["areas"]["a"] as Dictionary)["people"] = [{"id": "sefa", "cell": [2, 0]}]
	c["people"] = {"sefa": {"canon": "person.sefa", "portrait": "portrait-mariners"}}
	var s: RefCounted = Session.new_game(c)
	check_eq(s.occupied_cells().keys(), [Vector2i(2, 0)], "the person's cell is occupied")
	s.step_to(Vector2i(1, 0))
	var onto: Dictionary = s.step_to(Vector2i(2, 0))
	check(not onto["ok"], "cannot step onto a person")
	check_eq(s.cell(), Vector2i(1, 0), "stayed")
	var round: Array[Vector2i] = s.path_to(Vector2i(3, 0))
	check(not round.has(Vector2i(2, 0)), "path goes round the person")
	var to_person: Array[Vector2i] = s.path_to(Vector2i(2, 0))
	check_eq(to_person[-1], Vector2i(2, 0), "a path may end at the person")
	check_eq(to_person[-2], Vector2i(1, 0), "and the step before is the neighbour")


func test_walk_in_another_area_does_not_move_a_person_here() -> void:
	var c: Dictionary = _content()
	(c["areas"]["b"] as Dictionary)["people"] = [{"id": "sefa", "cell": [2, 0]}]
	c["people"] = {"sefa": {"canon": "person.sefa", "portrait": "portrait-mariners"}}
	var s: RefCounted = Session.new_game(c, null)
	s.world.position["area"] = "b"
	s.world.call("set_figure_cell", "person.sefa", Vector2i(3, 2))
	var here: Array[Dictionary] = s.people_here()
	check_eq(here[0]["cell"], Vector2i(2, 0), "no cut scene set in b walked her, so the listed cell stands")


func test_exit_and_quest_step() -> void:
	var st: RefCounted = _store()
	var s: RefCounted = Session.new_game(_content(), st)
	s.step_to(Vector2i(1, 0))
	s.step_to(Vector2i(2, 0))
	check(not st.has_save(), "plain steps do not save")
	var r: Dictionary = s.step_to(Vector2i(3, 0))
	check_eq(r["exit"]["to"], "b", "exit taken")
	check_eq(s.area_id(), "b", "new area")
	check(st.has_save(), "area change saves")
	st.clear()
	var r2: Dictionary = s.step_to(Vector2i(1, 0))
	check_eq(r2["steps_done"], ["s1:go"], "step done")
	check(st.has_save(), "step saves")
	check_eq(s.world.quests["s1"]["status"], "cleared", "quest cleared")
	st.clear()


func test_use_thing() -> void:
	var s: RefCounted = Session.new_game(_content())
	check(not s.use_thing("nope")["ok"], "unknown thing")
	var r: Dictionary = s.use_thing("t1")
	check(r["ok"], "used")
	check_eq(s.world.packs["hero"]["item.x"], 1, "item given")
	check_eq(s.world.uses_of("t1"), 1, "use counted")


func test_rest() -> void:
	var s: RefCounted = Session.new_game(_content())
	check(not s.rest()["ok"], "no rest in a")
	check_eq(s.world.day, 1, "day unchanged")
	var start: Dictionary = {"area": "b", "cell": [0, 0]}
	var s2: RefCounted = Session.new_game(_content(start))
	var r: Dictionary = s2.rest()
	check(r["ok"], "rest in b")
	check_eq(s2.world.day, 2, "one day passed")


func test_resume_in_place() -> void:
	var st: RefCounted = _store()
	var s: RefCounted = Session.new_game(_content(), st)
	for c: Vector2i in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]:
		s.step_to(c)
	var back: RefCounted = Session.resume(st, _content())
	check_eq(back.note, "", "no note")
	check_eq(back.area_id(), "b", "same area")
	check_eq(back.cell(), Vector2i(0, 0), "same cell")
	check_eq(back.world.to_json(), s.world.to_json(), "same world")
	st.clear()


func test_resume_without_save() -> void:
	var back: RefCounted = Session.resume(_store(), _content())
	check(back.note != "", "says why")
	check_eq(back.area_id(), "a", "new game")
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{\"version\": 99}")
	f.close()
	var refused: RefCounted = Session.resume(SaveStore.new(PATH), _content())
	check(refused.note != "", "refused save says why")
	check_eq(refused.area_id(), "a", "refused save gives new game")
	SaveStore.new(PATH).clear()
