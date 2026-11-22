extends SceneTree
## Prints an area as text. Usage: ./ov map <area id> [--chapter N] [--flag name]... [--listened]
## Dungeon and battle maps are not printed yet. Exit 0 when printed, 1 for an unknown or broken area, 2 for bad usage.

const Area: GDScript = preload("res://rules/area.gd")
const People: GDScript = preload("res://rules/people.gd")
const World: GDScript = preload("res://rules/world_state.gd")
const MapText: GDScript = preload("res://tools/map_text.gd")
const USAGE: String = "usage: ./ov map <area id> [--chapter N] [--flag name]... [--listened]"


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var id: String = ""
	var chapter: int = 1
	var flags: Array[String] = []
	var listened: bool = false
	var i: int = 0
	while i < args.size():
		var arg: String = args[i]
		var has_value: bool = i + 1 < args.size()
		if arg == "--chapter" and has_value and args[i + 1].is_valid_int():
			chapter = int(args[i + 1])
			i += 2
		elif arg == "--flag" and has_value:
			flags.append(args[i + 1])
			i += 2
		elif arg == "--listened":
			listened = true
			i += 1
		elif id == "" and not arg.begins_with("--"):
			id = arg
			i += 1
		else:
			printerr(USAGE)
			quit(2)
			return
	if id == "" or not id.is_valid_filename():
		printerr(USAGE)
		quit(2)
		return

	var path: String = "res://content/areas/%s.json" % id
	var data: Dictionary = People.load_json(path) if FileAccess.file_exists(path) else {}
	if data.is_empty():
		printerr("map: unknown area %s" % id)
		quit(1)
		return
	var area: RefCounted = Area.from_dict(data)
	if not (area.errors as Array).is_empty():
		printerr("map: area %s has errors" % id)
		for error: String in area.errors:
			printerr("  " + error)
		quit(1)
		return

	var world: RefCounted = World.new()
	world.chapter = chapter
	for flag: String in flags:
		world.set_flag(flag)
	print(MapText.render(area, world, listened).trim_suffix("\n"))
	quit(0)
