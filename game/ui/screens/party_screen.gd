extends "res://ui/screens/screen_base.gd"
## Party: each member's attributes, reach, ebb against its limit, skills as pips and traits as marks.
## Standing is in the view but is never drawn.


func _title() -> String:
	return "Party"


func _fill() -> void:
	var v: Dictionary = _session.call("party_view")
	for m: Dictionary in v["members"]:
		_member(m, false)
	var guests: Array = v["guests"]
	if not guests.is_empty():
		_heading("Guests")
		for g: Dictionary in guests:
			_member(g, true)


func _member(m: Dictionary, guest: bool) -> void:
	_heading("%s (guest)" % m["name"] if guest else str(m["name"]))
	_line("Body %d  Hands %d  Mind %d  Reach %d" % [m["body"], m["hands"], m["mind"], m["reach"]])
	_line("Ebb %d / %d" % [m["ebb"], m["limit"]])
	for s: Dictionary in m["skills"]:
		_line("%s  %s" % [pips(int(s["step"])), label_of(str(s["skill"]))])
	var marks: Array = []
	for t: Variant in m["traits"]:
		marks.append("[%s]" % label_of(str(t)))
	if not marks.is_empty():
		_line(" ".join(marks))
