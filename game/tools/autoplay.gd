extends SceneTree
## Walks every area and plays every quest. Usage: ./ov play <id> | --all
## Battles and dungeons are not played yet. Exit 0 when all pass, 1 on a failure or an unknown id, 2 for bad usage.

const Area: GDScript = preload("res://rules/area.gd")
const People: GDScript = preload("res://rules/people.gd")
const World: GDScript = preload("res://rules/world_state.gd")
const Walker: GDScript = preload("res://tools/walker.gd")
const QuestPlayer: GDScript = preload("res://tools/quest_player.gd")
const USAGE: String = "usage: ./ov play <id> | --all"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1 or (args[0] != "--all" and not args[0].is_valid_filename()):
		printerr(USAGE)
		quit(2)
		return
	var want: String = "" if args[0] == "--all" else args[0]
	var areas: Array[RefCounted] = []
	for data: Dictionary in _load_dir("res://content/areas"):
		areas.append(Area.from_dict(data))
	var quests: Array[Dictionary] = _load_dir("res://content/quests")
	var item_ids: Array[String] = []
	for item: Dictionary in _load_dir("res://content/items"):
		item_ids.append(str(item.get("id", "")))
	var people: Dictionary = _load_keyed("res://content/people")
	var dialogues: Dictionary = _load_keyed("res://content/dialogue")
	var errors: Array[String] = []
	var played: int = 0
	for area: RefCounted in areas:
		if want != "" and area.id != want:
			continue
		played += 1
		errors.append_array(area.errors)
		var found: Array[String] = [] if not (area.errors as Array).is_empty() else Walker.walk(area)
		print("walker: %s %s" % [area.id, "OK" if found.is_empty() and (area.errors as Array).is_empty() else "FAILED"])
		errors.append_array(found)
	played += _play_quests(quests, item_ids, people, dialogues, want, errors)
	if want != "" and played == 0:
		errors.append("play: unknown id %s" % want)
	for message: String in errors:
		printerr(message)
	if want == "" and played == 0:
		print("auto-player: no content yet")
	quit(1 if not errors.is_empty() else 0)


## Main stages in chapter order on one world, then each side quest on a fresh world.
func _play_quests(quests: Array[Dictionary], item_ids: Array[String], people: Dictionary, dialogues: Dictionary, want: String, errors: Array[String]) -> int:
	var main: Array[Dictionary] = []
	var sides: Array[Dictionary] = []
	for q: Dictionary in quests:
		(sides if bool(q.get("side", false)) else main).append(q)
	main.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["chapters"][0]) < int(b["chapters"][0]))
	var played: int = 0
	var shared: RefCounted = World.new()
	for q: Dictionary in main:
		var found: Array[String] = QuestPlayer.play(q, shared, quests, item_ids, people, dialogues)
		if want == "" or want == str(q["id"]):
			played += 1
			print("quest: %s %s" % [q["id"], "OK" if found.is_empty() else "FAILED"])
			errors.append_array(found)
	for q: Dictionary in sides:
		if want != "" and want != str(q["id"]):
			continue
		var world: RefCounted = World.new()
		world.chapter = int(q["chapters"][0])
		var found: Array[String] = QuestPlayer.play(q, world, quests, item_ids, people, dialogues)
		played += 1
		print("quest: %s %s" % [q["id"], "OK" if found.is_empty() else "FAILED"])
		errors.append_array(found)
	return played


func _load_dir(path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var files: PackedStringArray = DirAccess.get_files_at(path)
	files.sort()
	for file: String in files:
		if file.ends_with(".json"):
			var data: Dictionary = People.load_json(path.path_join(file))
			if not data.is_empty():
				out.append(data)
	return out


## Files of a content folder keyed by their "id".
func _load_keyed(path: String) -> Dictionary:
	var out: Dictionary = {}
	for data: Dictionary in _load_dir(path):
		out[str(data.get("id", ""))] = data
	return out
