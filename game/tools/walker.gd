extends RefCounted
## Walks one area from its spawn to every person, thing and exit, in every flag state its data
## names. Uses only the rules: Area.find_path decides what can be reached. Hidden things are
## checked as if listened to, with every trait the area asks for in the party.

const Area: GDScript = preload("res://rules/area.gd")
const World: GDScript = preload("res://rules/world_state.gd")
const Sheet: GDScript = preload("res://rules/character_sheet.gd")
const SECTIONS: Array[String] = ["exits", "things", "people", "encounters"]


## Messages for every target that cannot be reached. Empty means all were reached.
static func walk(area: RefCounted) -> Array[String]:
	var out: Array[String] = []
	if not area.data.has("spawn"):
		out.append("area %s: no spawn cell" % area.id)
		return out
	for world: RefCounted in worlds(area):
		for message: String in _walk_world(area, world):
			if not out.has(message):
				out.append(message)
	return out


## The base world, then one world per distinct condition found in the area's data.
static func worlds(area: RefCounted) -> Array[RefCounted]:
	var conds: Array[Dictionary] = [{}]
	for v: Variant in area.data.get("variants", []):
		_collect(conds, (v as Dictionary).get("when"))
		for key: String in SECTIONS:
			for e: Variant in (v as Dictionary).get(key, []):
				_collect(conds, (e as Dictionary).get("when"))
	for key: String in SECTIONS:
		for e: Variant in area.data.get(key, []):
			_collect(conds, (e as Dictionary).get("when"))
	var out: Array[RefCounted] = []
	for c: Dictionary in conds:
		out.append(_world_for(area, c))
	return out


static func _collect(conds: Array[Dictionary], cond: Variant) -> void:
	if cond is Dictionary and not conds.has(cond):
		conds.append(cond)


static func _world_for(area: RefCounted, cond: Dictionary) -> RefCounted:
	var world: RefCounted = World.new()
	var sheet: RefCounted = Sheet.new()
	sheet.id = "walker"
	for t: Variant in area.data.get("trait_access", []):
		sheet.traits.append(str((t as Dictionary)["trait"]))
	for t: Variant in area.data.get("things", []):
		if (t as Dictionary).has("hidden"):
			sheet.traits.append(str(t["hidden"]["trait"]))
	world.sheets["walker"] = sheet
	world.party.append("walker")
	world.chapter = int(cond.get("chapter_min", 1))
	if cond.has("flag"):
		world.set_flag(str(cond["flag"]))
	return world


static func _walk_world(area: RefCounted, world: RefCounted) -> Array[String]:
	var out: Array[String] = []
	var spawn: Vector2i = Area.cell_of(area.data["spawn"])
	var state: String = "chapter %d, flags %s" % [world.chapter, str(world.flags.keys())]
	if not area.is_walkable(world, spawn):
		out.append("area %s: spawn %s is not walkable (%s)" % [area.id, spawn, state])
		return out
	for e: Dictionary in area.section(world, "exits"):
		if Area.holds(e.get("when"), world) and area.find_path(world, spawn, Area.cell_of(e["cell"])).is_empty():
			out.append("area %s: exit to %s at %s is unreachable (%s)" % [area.id, e["to"], Area.cell_of(e["cell"]), state])
	for p: Dictionary in area.section(world, "people"):
		if Area.holds(p.get("when"), world) and not _reach_beside(area, world, spawn, Area.cell_of(p["cell"])):
			out.append("area %s: person %s at %s is unreachable (%s)" % [area.id, p["id"], Area.cell_of(p["cell"]), state])
	for t: Dictionary in area.visible_things(world, true):
		if not _reach_beside(area, world, spawn, Area.cell_of(t["cell"])):
			out.append("area %s: thing %s at %s is unreachable (%s)" % [area.id, t["id"], Area.cell_of(t["cell"]), state])
	return out


## People and things are met from their own cell or from one beside it.
static func _reach_beside(area: RefCounted, world: RefCounted, from: Vector2i, cell: Vector2i) -> bool:
	if not area.find_path(world, from, cell).is_empty():
		return true
	for step: Vector2i in Area.STEPS:
		if not area.find_path(world, from, cell + step).is_empty():
			return true
	return false
