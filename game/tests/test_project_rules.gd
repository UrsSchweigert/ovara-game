extends "res://tests/test_case.gd"
## Guards the project's structure. Do not loosen these; see CLAUDE.md.

## rules/ must be pure logic: no scenes, no input, no engine clock, no global randomness.
const FORBIDDEN_IN_RULES: Array[String] = [
	"\\bextends\\s+(Node|Node2D|Control|CanvasItem|CanvasLayer|Sprite2D|SceneTree|Area2D)\\b",
	"\\bget_tree\\s*\\(", "\\bInput\\.", "\\bDisplayServer\\.", "\\bTime\\.", "\\bOS\\.",
	"\\brandi\\s*\\(", "\\brandf\\s*\\(", "\\brandi_range\\s*\\(", "\\brandf_range\\s*\\(",
	"\\brandomize\\s*\\(", "\\bRandomNumberGenerator\\b", "\\.shuffle\\s*\\(", "\\.pick_random\\s*\\(",
	"res://scenes", "res://ui", "res://assets",
]


func test_rules_are_pure() -> void:
	var files: Array[String] = []
	_collect("res://rules", files)
	check(not files.is_empty(), "no scripts found under res://rules")
	for path: String in files:
		var number: int = 0
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			number += 1
			var code: String = line.split("#")[0]
			for pattern: String in FORBIDDEN_IN_RULES:
				var regex: RegEx = RegEx.new()
				regex.compile(pattern)
				if regex.search(code) != null:
					check(false, "%s:%d uses something rules/ may not: %s" % [path, number, code.strip_edges()])


func test_every_script_loads() -> void:
	var files: Array[String] = []
	for root: String in ["res://rules", "res://scenes", "res://ui", "res://tools", "res://tests"]:
		_collect(root, files)
	for path: String in files:
		var script: GDScript = load(path) as GDScript
		check(script != null and script.can_instantiate(), "%s does not load" % path)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file: String in dir.get_files():
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
