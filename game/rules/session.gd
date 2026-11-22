extends RefCounted
## One play session: the world state plus the loaded content, and the intents the exploring
## scene sends. The session decides; the scene draws what comes back. Content is
## {"areas": {id: area JSON}, "quests": [quest JSON]}. The first area is the fallback start.

const World: GDScript = preload("res://rules/world_state.gd")
const Area: GDScript = preload("res://rules/area.gd")
const Quests: GDScript = preload("res://rules/quest_engine.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")
const People: GDScript = preload("res://rules/people.gd")
const Views: GDScript = preload("res://rules/views.gd")
const Cutscene: GDScript = preload("res://rules/cutscene.gd")
const Shop: GDScript = preload("res://rules/shop.gd")

## Person the party holds when no start block names one.
const HERO_ID: String = "hero"

var world: RefCounted = null
## Area id -> Area.
var areas: Dictionary = {}
var quests: Array[Dictionary] = []
var store: RefCounted = null
## Person id -> person JSON, and dialogue id -> dialogue JSON.
var people: Dictionary = {}
var dialogues: Dictionary = {}
## Item id -> item JSON, and shop id -> shop JSON.
var items: Dictionary = {}
var shops: Dictionary = {}
## Cut scene id -> cut scene JSON.
var cutscenes: Dictionary = {}
## The cut scene running now, or null.
var scene: RefCounted = null
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
	people = (content.get("people", {}) as Dictionary).duplicate()
	dialogues = (content.get("dialogues", {}) as Dictionary).duplicate()
	cutscenes = (content.get("cutscenes", {}) as Dictionary).duplicate()
	items = (content.get("items", {}) as Dictionary).duplicate()
	shops = (content.get("shops", {}) as Dictionary).duplicate()


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
	var arrival: String = str(start.get("arrival", ""))
	if cutscenes.has(arrival) and not world.has_seen_scene(arrival):
		scene = Cutscene.new(cutscenes[arrival], world, people)


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


## Who stands in the current area now: [{"kind", "id", "cell", "portrait"}]. A "person" comes
## from the area's "people" section ({"id", "cell", "when"}) and can be talked to; a "keeper"
## stands at a shop placed in the area, and its id is the shop's.
func people_here() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var a: RefCounted = current_area()
	if a == null:
		return out
	for p: Variant in a.call("section", world, "people"):
		var d: Dictionary = p
		var id: String = str(d.get("id", ""))
		if people.has(id) and Area.holds(d.get("when"), world):
			var canon: String = str(_person(id).get("canon", ""))
			var moved: Variant = world.call("figure_cell", canon)
			var cell: Vector2i = moved if moved is Vector2i else Area.cell_of(d.get("cell", [0, 0]))
			out.append({"kind": "person", "id": id, "canon": canon, "cell": cell, "portrait": People.portrait_key(_person(id))})
	for id: Variant in shops:
		var shop: Dictionary = shops[id]
		if str(shop.get("area", "")) == area_id():
			out.append({"kind": "keeper", "id": str(id), "cell": Area.cell_of(shop.get("cell", [0, 0])), "portrait": ""})
	return out


## Who a finished cut scene set in this area walked in and the area does not list:
## [{"canon", "cell"}], standing where the last walk left them. Drawn only, never talked to.
func walked_here() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var listed: Array[String] = []
	for who: Dictionary in people_here():
		listed.append(str(who.get("canon", "")))
	for sid: Variant in cutscenes:
		var data: Dictionary = cutscenes[sid]
		if str(data.get("area", "")) != area_id() or not bool(world.call("has_seen_scene", str(sid))):
			continue
		for step: Variant in data.get("steps", []):
			var canon: String = str((step as Dictionary).get("who", ""))
			var cell: Variant = world.call("figure_cell", canon)
			if str((step as Dictionary).get("op", "")) == "walk" and cell is Vector2i and not listed.has(canon):
				listed.append(canon)
				out.append({"canon": canon, "cell": cell})
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


## The dialogue panel's opening: {"ok", "name", "portrait", "topics": [{"topic", "news"}]}.
## An unknown person gives ok false.
func talk(person_id: String) -> Dictionary:
	var out: Dictionary = {"ok": false, "name": "", "portrait": "", "topics": []}
	if not people.has(person_id):
		return out
	var person: Dictionary = _person(person_id)
	out["ok"] = true
	out["name"] = People.display_name(person, world)
	out["portrait"] = People.portrait_key(person)
	for topic: String in People.available_topics(person, dialogues, world):
		(out["topics"] as Array).append({"topic": topic, "news": not People.heard(person_id, topic, world)})
	return out


## Asks a topic. Returns {"ok", "error", "panels", "steps_done"}; each panel is {"speaker" (display
## name), "portrait", "lines"} with at most three lines. Saves if a quest step was finished.
func ask(person_id: String, topic: String) -> Dictionary:
	var out: Dictionary = {"ok": false, "error": "unknown person '%s'" % person_id, "panels": [], "steps_done": []}
	if not people.has(person_id):
		return out
	var before: Dictionary = _done_snapshot()
	var asked: Dictionary = People.ask(_person(person_id), dialogues, topic, world)
	out["ok"] = asked["ok"]
	out["error"] = asked["error"]
	for p: Dictionary in asked["panels"]:
		var who: Dictionary = _person_by_canon(str(p.get("speaker", "")), person_id)
		(out["panels"] as Array).append({"speaker": People.display_name(who, world) if not who.is_empty() else str(p.get("speaker", "")),
			"portrait": str(p.get("portrait", People.portrait_key(who))), "lines": (p.get("lines", []) as Array).duplicate()})
	if bool(asked["ok"]):
		_after_intent(area_id(), before, out)
	return out


## A topic's name for the topic list: the chapter's name of the person it names, else its canon
## id without the kind ("place.low-anthem" gives "Low anthem"). Canon has no topic names yet.
func topic_label(topic: String) -> String:
	var who: Dictionary = _person_by_canon(topic, "")
	if not who.is_empty():
		return People.display_name(who, world)
	var bare: String = topic.get_slice(".", 1) if topic.contains(".") else topic
	bare = bare.replace("-", " ").replace("_", " ")
	return bare.left(1).to_upper() + bare.substr(1)


func _person(person_id: String) -> Dictionary:
	var person: Dictionary = (people[person_id] as Dictionary).duplicate()
	person["id"] = person_id
	return person


## The person a panel's canon speaker id names; the asked person if it names none.
func _person_by_canon(canon_id: String, fallback_id: String) -> Dictionary:
	for id: Variant in people:
		if str((people[id] as Dictionary).get("canon", "")) == canon_id:
			return _person(str(id))
	return _person(fallback_id) if canon_id == "" else {}


## The trades a shop offers now: [{"index", "gives", "wants"}]; empty for an unknown shop.
func trades(shop_id: String) -> Array[Dictionary]:
	if not shops.has(shop_id):
		return [] as Array[Dictionary]
	return Shop.trades(shops[shop_id], world)


## Runs trade `index` at a shop. Returns {"ok", "error", "gave", "took", "steps_done"}. Updates
## the quests and saves if a step was finished.
func trade(shop_id: String, index: int) -> Dictionary:
	if not shops.has(shop_id):
		return {"ok": false, "error": "unknown shop '%s'" % shop_id, "gave": {}, "took": {}, "steps_done": []}
	var before: Dictionary = _done_snapshot()
	var out: Dictionary = Shop.trade(shops[shop_id], world, index, items)
	out["steps_done"] = []
	if bool(out["ok"]):
		_after_intent(area_id(), before, out)
	return out


## The cut scene's current step ({} when none is running).
func scene_step() -> Dictionary:
	return {} if scene == null else scene.call("current")


## Finishes the current step. Returns the next step; saves when the scene ends.
func advance_scene() -> Dictionary:
	if scene == null:
		return {}
	var next: Dictionary = scene.call("advance")
	_close_scene()
	return next


## Skips to the end state. Returns {"ok"}; false when no scene runs or it cannot be skipped.
func skip_scene() -> Dictionary:
	if scene == null:
		return {"ok": false}
	var out: Dictionary = scene.call("skip")
	_close_scene()
	return out


func _close_scene() -> void:
	if scene != null and bool(scene.call("finished")):
		scene = null
		if store != null:
			store.call("save", world)


func journal_view() -> Dictionary:
	return Views.journal(self)


func party_view() -> Dictionary:
	return Views.party(self)


func pack_view() -> Dictionary:
	return Views.pack(self)


func stall_view(shop_id: String) -> Dictionary:
	return Views.stall(self, shop_id)


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
