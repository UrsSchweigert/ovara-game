extends "res://ui/screens/screen_base.gd"
## Pack: what each person carries, with the stacks used, then the shared supplies. Read only.


func _title() -> String:
	return "Pack"


func _fill() -> void:
	var v: Dictionary = _session.call("pack_view")
	for p: Dictionary in v["people"]:
		_heading("%s  (slots %d)" % [p["name"], p["slots"]])
		var items: Array = p["items"]
		if items.is_empty():
			_line("Nothing.")
		for it: Dictionary in items:
			_line("%s x%d" % [label_of(str(it["item"])), int(it["count"])])
	var supplies: Dictionary = v["supplies"]
	_heading("Supplies")
	if supplies.is_empty():
		_line("None.")
	for k: Variant in supplies:
		_line("%s x%d" % [label_of(str(k)), int(supplies[k])])
