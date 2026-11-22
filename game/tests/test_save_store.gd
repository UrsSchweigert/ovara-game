extends "res://tests/test_case.gd"

const World: GDScript = preload("res://rules/world_state.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")

const PATH: String = "user://test_save_store.json"


func _store() -> RefCounted:
	var s: RefCounted = SaveStore.new(PATH)
	s.call("clear")
	return s


func test_round_trip() -> void:
	var s: RefCounted = _store()
	var w: RefCounted = World.new(7)
	w.party.append("hero")
	w.day = 4
	w.position = {"area": "a", "x": 3, "y": 2}
	w.set_flag("f.one")
	check(bool(s.call("save", w)), "save succeeds")
	check(bool(s.call("has_save")), "file exists")
	var loaded: Dictionary = s.call("load_state")
	check_eq(loaded["error"], "", "no error")
	var back: RefCounted = loaded["state"]
	check(back != null, "state loaded")
	if back != null:
		check_eq(back.to_json(), w.to_json(), "same state")
		check_eq(back.position["x"], 3, "position is an int")
	s.call("clear")
	check(not bool(s.call("has_save")), "clear removes the file")


func test_missing_file() -> void:
	var loaded: Dictionary = _store().call("load_state")
	check(loaded["state"] == null, "no state")
	check(str(loaded["error"]) != "", "says why")


func test_refused_files() -> void:
	var s: RefCounted = _store()
	for text: String in ["not json", "{\"version\": 99}", "[1]"]:
		var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
		f.store_string(text)
		f.close()
		var loaded: Dictionary = s.call("load_state")
		check(loaded["state"] == null, "refused: %s" % text)
		check(str(loaded["error"]) != "", "reason for: %s" % text)
	s.call("clear")


func test_unwritable_path() -> void:
	var s: RefCounted = SaveStore.new("user://no_such_dir_xyz/save.json")
	check(not bool(s.call("save", World.new())), "save fails cleanly")
