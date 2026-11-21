extends SceneTree
## Headless test runner. Usage: godot --headless --path game -s res://tests/run_tests.gd
## Runs every test_* method in every res://tests/**/test_*.gd. Exit code 0 only if all pass.

const TEST_DIR: String = "res://tests"
const BASE: String = "res://tests/test_case.gd"


func _init() -> void:
	var files: Array[String] = []
	_collect(TEST_DIR, files)
	files.sort()
	var passed: int = 0
	var failed: int = 0
	for path: String in files:
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			print("FAIL  %s  (does not load)" % path)
			failed += 1
			continue
		var probe: Object = script.new()
		var names: Array[String] = []
		for method: Dictionary in probe.get_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				names.append(method_name)
		names.sort()
		for method_name: String in names:
			var case: Object = script.new()
			case.call(method_name)
			var problems: Array = case.get("failures")
			if problems.is_empty():
				passed += 1
			else:
				failed += 1
				print("FAIL  %s  %s" % [path.get_file(), method_name])
				for problem: String in problems:
					print("        " + problem)
	print("tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file: String in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd") and dir_path.path_join(file) != BASE:
			out.append(dir_path.path_join(file))
