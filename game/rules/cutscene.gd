extends RefCounted
## Runs one cut scene: walk, say, camera and light steps, one at a time. Walks move the named
## figure's cell in the world state. The scene is marked seen when it finishes, by either route.

const People: GDScript = preload("res://rules/people.gd")

var id: String = ""
var steps: Array = []
var index: int = 0
var _skippable: bool = true
var _world: RefCounted = null
## Person id -> person JSON, used to turn a canon id into a display name and portrait.
var _people: Dictionary = {}


func _init(data: Dictionary, world: RefCounted, people: Dictionary = {}) -> void:
	id = str(data.get("id", ""))
	steps = (data.get("steps", []) as Array).duplicate(true)
	_skippable = bool(data.get("skippable", true))
	_world = world
	_people = people


func skippable() -> bool:
	return _skippable


func finished() -> bool:
	return index >= steps.size()


## The step to show now, or an empty dictionary when the scene is over. A say step carries the
## speaker's display name and portrait.
func current() -> Dictionary:
	if finished():
		return {}
	var step: Dictionary = (steps[index] as Dictionary).duplicate(true)
	if str(step["op"]) == "say":
		var who: Dictionary = _person_by_canon(str(step["who"]))
		step["speaker"] = People.display_name(who, _world) if not who.is_empty() else str(step["who"])
		step["portrait"] = People.portrait_key(who) if not who.is_empty() else str(step["who"])
	return step


## Finishes the current step and returns the next one. A walk puts its figure in place.
func advance() -> Dictionary:
	if finished():
		return {}
	_apply(steps[index] as Dictionary)
	index += 1
	_close_if_done()
	return current()


## Applies every remaining walk and finishes. Refused (ok false, nothing changed) when the
## scene is not skippable.
func skip() -> Dictionary:
	if not _skippable:
		return {"ok": false}
	while not finished():
		_apply(steps[index] as Dictionary)
		index += 1
	_close_if_done()
	return {"ok": true}


func _apply(step: Dictionary) -> void:
	if str(step["op"]) == "walk":
		var to: Array = step["to"]
		_world.call("set_figure_cell", str(step["who"]), Vector2i(int(to[0]), int(to[1])))


func _close_if_done() -> void:
	if finished():
		_world.call("mark_scene_seen", id)


func _person_by_canon(canon_id: String) -> Dictionary:
	for pid: Variant in _people:
		if str((_people[pid] as Dictionary).get("canon", "")) == canon_id:
			var person: Dictionary = (_people[pid] as Dictionary).duplicate()
			person["id"] = str(pid)
			return person
	return {}
