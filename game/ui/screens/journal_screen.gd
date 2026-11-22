extends "res://ui/screens/screen_base.gd"
## Journal: the main stage with its next step in one line, then side quests by state.


func _title() -> String:
	return "Journal"


func _fill() -> void:
	var v: Dictionary = _session.call("journal_view")
	var stage: Dictionary = v["stage"]
	if stage.is_empty():
		_line("Nothing is asked of you yet.")
	else:
		_heading(str(stage["title"]))
		_line(str(stage["next"]))
	var open: Array = v["open"]
	if not open.is_empty():
		_heading("Open")
		for q: Dictionary in open:
			_line("%s: %s" % [q["title"], q["next"]])
	var finished: Array = v["finished"]
	if not finished.is_empty():
		_heading("Finished")
		for q: Dictionary in finished:
			_line(str(q["title"]))
