extends RefCounted
## Reads the content folders into the dictionary a Session takes. Files are keyed by their "id".

const People: GDScript = preload("res://rules/people.gd")
const ROOT: String = "res://content"


static func load_all() -> Dictionary:
	return {
		"areas": _keyed("areas"), "people": _keyed("people"), "dialogues": _keyed("dialogue"),
		"cutscenes": _keyed("cutscenes"), "items": _keyed("items"), "shops": _keyed("shops"),
		"quests": _files("quests"),
	}


static func _files(folder: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var path: String = ROOT.path_join(folder)
	var names: PackedStringArray = DirAccess.get_files_at(path)
	names.sort()
	for file: String in names:
		if file.ends_with(".json"):
			var data: Dictionary = People.load_json(path.path_join(file))
			if not data.is_empty():
				out.append(data)
	return out


static func _keyed(folder: String) -> Dictionary:
	var out: Dictionary = {}
	for data: Dictionary in _files(folder):
		out[str(data.get("id", ""))] = data
	return out
