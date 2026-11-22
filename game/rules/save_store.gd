extends RefCounted
## Writes and reads the world state as JSON at a path the caller gives. Nothing else is kept.

const World: GDScript = preload("res://rules/world_state.gd")

var path: String = ""


func _init(save_path: String = "") -> void:
	path = save_path


func has_save() -> bool:
	return FileAccess.file_exists(path)


## Writes the world state. False if the file could not be opened.
func save(world: RefCounted) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(str(world.call("to_json")))
	file.close()
	return true


## Returns {"state": world state or null, "error": why there is none}. A missing file and a
## refused file both give a null state.
func load_state() -> Dictionary:
	if not has_save():
		return {"state": null, "error": "no save at %s" % path}
	return World.parse(FileAccess.get_file_as_string(path))


## Removes the save file, if any.
func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(path)
