extends RefCounted
## One play session: the world state plus the loaded content, and the intents the exploring
## scene sends. The session decides; the scene draws what comes back. Content is
## {"areas": {id: area JSON}, "quests": [quest JSON]}. The first area is the fallback start.

const World: GDScript = preload("res://rules/world_state.gd")
const Area: GDScript = preload("res://rules/area.gd")
const Quests: GDScript = preload("res://rules/quest_engine.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")

## Person the party holds when no start block names one.
const HERO_ID: String = "hero"

var world: RefCounted = null
## Area id -> Area.
var areas: Dictionary = {}
var quests: Array[Dictionary] = []
var store: RefCounted = null
## Empty, or why resume began a new game.
var note: String = ""


static func new_game(content: Dictionary, save_store: RefCounted = null) -> RefCounted:
	var s: RefCounted = (load("res://rules/session.gd") as GDScript).new()
	s.call("_begin", content, save_store)
	return s


## Loads the save and returns the party to where it stood. A missing or refused save, or one
## that stands in an area the content lacks, gives a new game with `note` saying why.
static func resume(save_store: RefCounted, content: Dictionary) -> RefCounted:
	var loaded: Dictionary = save_store.call("load_state")
	var state: RefCounted = loaded["state"] as RefCounted
	var s: RefCounted = (load("res://rules/session.gd") as GDScript).new()
	s.call("_load_content", content, save_store)
	var why: String = str(loaded["error"])
	if state != null and not s.areas.has(str(state.position.get("area", ""))):
		why = "save stands in unknown area '%s'" % str(state.position.get("area", ""))
	if state == null or why != "":
		s.call("_start_fresh")
		s.note = why
		return s
	s.world = state
	return s


func _load_content(content: Dictionary, save_store: RefCounted) -> void:
	store = save_store
	var raw: Dictionary = content.get("areas", {})
	for id: Variant in raw:
		areas[str(id)] = Area.from_dict(raw[id])
	for q: Variant in content.get("quests", []):
		quests.append(q)


func _begin(content: Dictionary, save_store: RefCounted) -> void:
	_load_content(content, save_store)
	_start_fresh()


func _start_fresh() -> void:
	world = World.new()
	var start: Dictionary = _first_main_start()
	var area_id: String = str(start.get("area", ""))
	var cell: Vector2i = Vector2i.ZERO
	if area_id != "" and areas.has(area_id):
		cell = Area.cell_of(start["cell"])
	elif not areas.is_empty():
		area_id = str(areas.keys()[0])
		cell = Area.cell_of((areas[area_id].data as Dictionary).get("spawn", [0, 0]))
	for p: Variant in start.get("party", []):
		world.party.append(str(p))
	if world.party.is_empty():
		world.party.append(HERO_ID)
	world.position = {"area": area_id, "x": cell.x, "y": cell.y, "guests": (start.get("guests", []) as Array).duplicate()}
	if areas.has(area_id):
		areas[area_id].call("enter", world, cell)
	_update_quests()


func _first_main_start() -> Dictionary:
	var first: Dictionary = {}
	for q: Dictionary in quests:
		if Quests.is_side(q):
			continue
		if first.is_empty() or int(q["chapters"][0]) < int(first["chapters"][0]):
			first = q
	return first.get("start", {})


func area_id() -> String:
	return str(world.position.get("area", ""))


func cell() -> Vector2i:
	return Vector2i(int(world.position.get("x", 0)), int(world.position.get("y", 0)))


func current_area() -> RefCounted:
	return areas.get(area_id()) as RefCounted


## The rules' path from the party's cell to `to`, both ends included; empty if none.
func path_to(to: Vector2i) -> Array[Vector2i]:
	var a: RefCounted = current_area()
	if a == null:
		return [] as Array[Vector2i]
	return a.call("find_path", world, cell(), to)


## The party enters one neighbouring cell. Returns {"ok", "area", "cell", "entered", "exit",
## "encounter", "steps_done"}; exit is the exit taken, if any, and area and cell say where the
## party now stands. A cell that cannot be entered gives ok false and changes nothing.
func step_to(to: Vector2i) -> Dictionary:
	var a: RefCounted = current_area()
	var here: Vector2i = cell()
	var delta: Vector2i = (to - here).abs()
	var out: Dictionary = {"ok": false, "area": area_id(), "cell": here, "entered": false, "exit": {}, "encounter": "", "steps_done": []}
	if a == null or delta.x + delta.y != 1 or not bool(a.call("is_walkable", world, to)):
		return out
	var before_area: String = area_id()
	var before: Dictionary = _done_snapshot()
	_set_cell(to)
	var found: Dictionary = a.call("enter", world, to)
	out["ok"] = true
	out["entered"] = true
	out["encounter"] = found["encounter"]
	var taken: Dictionary = a.call("take_exit", world, to)
	if not taken.is_empty():
		out["exit"] = taken
		var target: RefCounted = current_area()
		if target != null:
			target.call("enter", world, taken["to_cell"])
	out["area"] = area_id()
	out["cell"] = cell()
	_after_intent(before_area, before, out)
	return out


## Uses a thing in the current area. Returns {"ok", "gave", "steps_done"}.
func use_thing(thing_id: String) -> Dictionary:
	var a: RefCounted = current_area()
	var out: Dictionary = {"ok": false, "gave": {}, "steps_done": []}
	if a == null:
		return out
	var before: Dictionary = _done_snapshot()
	var used: Dictionary = a.call("use_thing", world, thing_id)
	out["ok"] = used["ok"]
	out["gave"] = used["gave"]
	_after_intent(area_id(), before, out)
	return out


## Rests one day, only where the area's JSON says rest: true. Returns {"ok", "day", "steps_done"}.
func rest() -> Dictionary:
	var a: RefCounted = current_area()
	var out: Dictionary = {"ok": false, "day": int(world.day), "steps_done": []}
	if a == null or not bool((a.data as Dictionary).get("rest", false)):
		return out
	var before: Dictionary = _done_snapshot()
	world.advance_days(1)
	out["ok"] = true
	out["day"] = int(world.day)
	_after_intent(area_id(), before, out)
	return out


func _set_cell(to: Vector2i) -> void:
	world.position["x"] = to.x
	world.position["y"] = to.y


## Quest id -> number of steps done.
func _done_snapshot() -> Dictionary:
	var snap: Dictionary = {}
	for id: Variant in world.quests:
		snap[id] = ((world.quests[id] as Dictionary).get("done", []) as Array).duplicate()
	return snap


## Updates the quests, lists the steps they finished as "quest:step", and saves if the area
## changed or a step was done.
func _after_intent(area_before: String, before: Dictionary, out: Dictionary) -> void:
	_update_quests()
	var done: Array[String] = []
	for id: Variant in world.quests:
		var now: Array = (world.quests[id] as Dictionary).get("done", [])
		for step: Variant in now:
			if not (before.get(id, []) as Array).has(step):
				done.append("%s:%s" % [str(id), str(step)])
	out["steps_done"] = done
	if (area_id() != area_before or not done.is_empty()) and store != null:
		store.call("save", world)


## Opens the main quests whose chapter has come and updates every open quest. Clearing a stage
## moves the chapter, so this runs until nothing changes.
func _update_quests() -> void:
	for pass_number: int in quests.size() + 1:
		var changed: bool = false
		for q: Dictionary in quests:
			if not Quests.is_side(q) and Quests.open(q, world):
				changed = true
			if Quests.status(q, world) == Quests.OPEN and Quests.update(q, world):
				changed = true
		if not changed:
			return
