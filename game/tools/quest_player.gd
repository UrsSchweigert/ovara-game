extends RefCounted
## Plays a quest with the rules alone: opens it, does each step, clears it. A step that waits
## on a flag is helped only if some loaded quest can set that flag; otherwise the quest is stuck.

const Quests: GDScript = preload("res://rules/quest_engine.gd")
const People: GDScript = preload("res://rules/people.gd")
const Area: GDScript = preload("res://rules/area.gd")
## Pack key for items granted to a party with no members.
const STAND_IN_KEY: String = "quest_player"


## Error messages; empty if the quest was cleared. `all_quests` are the loaded quests whose
## flags may stand in for the world's other doings. `item_ids` are the items the player may be
## given for steps that wait on holds. `people` maps file id to person JSON and `dialogues` maps
## dialogue id to dialogue JSON, for steps that wait on topics heard. `areas` maps area id to Area
## and `targets` maps step id to {"thing": id} or {"exit": area id}: the player must find a path
## from the area's spawn to that thing or exit before the step is done. `person_areas` maps
## person id to the area they are in: the party walks there, through Area.enter, before asking.
static func play(quest: Dictionary, world: RefCounted, all_quests: Array[Dictionary], item_ids: Array[String] = [], people: Dictionary = {}, dialogues: Dictionary = {}, areas: Dictionary = {}, targets: Dictionary = {}, person_areas: Dictionary = {}) -> Array[String]:
	var id: String = str(quest["id"])
	if not Quests.open(quest, world):
		return ["quest %s: cannot open at chapter %d (chapters %s)" % [id, world.chapter, str(quest["chapters"])]]
	var walk_errors: Array[String] = _walk_to_steps(quest, world, areas, targets)
	if not walk_errors.is_empty():
		return walk_errors
	for pass_number: int in 2:
		for step: Dictionary in quest["steps"]:
			if not step.has("requires"):
				Quests.complete_step(quest, str(step["id"]), world)
		var day_errors: Array[String] = _pass_days(quest, world, people, dialogues, areas, person_areas)
		if not day_errors.is_empty():
			return day_errors
		var thing_errors: Array[String] = _do_things(quest, world, areas)
		if not thing_errors.is_empty():
			return thing_errors
		var held_errors: Array[String] = _grant_holds(quest, world, item_ids)
		if not held_errors.is_empty():
			return held_errors
		var heard_errors: Array[String] = _hear_topics(quest, world, people, dialogues, areas, person_areas)
		if not heard_errors.is_empty():
			return heard_errors
		Quests.update(quest, world)
		if Quests.status(quest, world) == Quests.CLEARED:
			return []
		_set_outside_flags(quest, world, all_quests)
	var stuck: Array[String] = []
	for step: Dictionary in quest["steps"]:
		if not Quests.is_done(quest, str(step["id"]), world):
			stuck.append(str(step["id"]))
	return ["quest %s: stuck at step %s" % [id, ", ".join(stuck)]]


## Finds a path in the step's area from its spawn to the step's thing or exit; an error if none.
static func _walk_to_steps(quest: Dictionary, world: RefCounted, areas: Dictionary, targets: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for step: Dictionary in quest["steps"]:
		var step_id: String = str(step["id"])
		if not targets.has(step_id) or Quests.is_done(quest, step_id, world):
			continue
		var area_id: String = str(step.get("area", ""))
		var where: String = "quest %s: step %s in %s" % [str(quest["id"]), step_id, area_id]
		if not areas.has(area_id):
			errors.append("%s: area is unknown" % where)
			continue
		var area: RefCounted = areas[area_id]
		var target: Dictionary = targets[step_id]
		var cell: Variant = null
		if target.has("thing"):
			for t: Variant in area.data.get("things", []):
				if str((t as Dictionary)["id"]) == str(target["thing"]):
					cell = area.cell_of((t as Dictionary)["cell"])
		else:
			for e: Variant in area.data.get("exits", []):
				if str((e as Dictionary)["to"]) == str(target.get("exit", "")):
					cell = area.cell_of((e as Dictionary)["cell"])
		if cell == null:
			errors.append("%s: no such thing or exit %s" % [where, str(target)])
			continue
		var from: Vector2i = area.cell_of(area.data.get("spawn", [0, 0]))
		if area.find_path(world, from, cell as Vector2i).is_empty():
			errors.append("%s: no path from %s to %s" % [where, str(from), str(cell)])
	return errors


## Lets the days pass for undone steps that wait on a day, one day at a time and never back. Each
## day, before it ends, the party asks the topics those steps need that the person offers that day.
static func _pass_days(quest: Dictionary, world: RefCounted, people: Dictionary, dialogues: Dictionary, areas: Dictionary, person_areas: Dictionary) -> Array[String]:
	while int(world.get("day")) < _last_day_min(quest, world):
		var errors: Array[String] = _hear_topics(quest, world, people, dialogues, areas, person_areas, true)
		if not errors.is_empty():
			return errors
		world.advance_days(1)
	return []


## The largest day_min among the undone steps; 0 if none waits on a day.
static func _last_day_min(quest: Dictionary, world: RefCounted) -> int:
	var last: int = 0
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		if not Quests.is_done(quest, str(step["id"]), world) and cond.has("day_min"):
			last = maxi(last, int(cond["day_min"]))
	return last


## Does the entered, used and holds steps through the areas' rules: walks into each cell with
## Area.enter and uses each thing with Area.use_thing. Nothing happens with no areas.
static func _do_things(quest: Dictionary, world: RefCounted, areas: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if areas.is_empty():
		return errors
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		if Quests.is_done(quest, str(step["id"]), world):
			continue
		var where: String = "quest %s: step %s" % [str(quest["id"]), str(step["id"])]
		for e: Variant in cond.get("entered", []):
			var cell: Vector2i = Area.cell_of((e as Dictionary)["cell"])
			var failed: String = _walk_to(world, areas, str(e["area"]), cell)
			if failed != "":
				errors.append("%s: cannot enter %s %s: %s" % [where, str(e["area"]), str(cell), failed])
		var used: Dictionary = cond.get("used", {})
		for thing: Variant in used:
			var failed: String = _use_times(world, areas, str(thing), int(used[thing]), str(step.get("area", "")))
			if failed != "":
				errors.append("%s: cannot use %s: %s" % [where, str(thing), failed])
		var held: Dictionary = cond.get("holds", {})
		for item: Variant in held:
			var givers: Array = _things_giving(areas, str(item), str(step.get("area", "")))
			if givers.is_empty():
				continue
			if (world.get("party") as Array).is_empty():
				(world.get("party") as Array).append(STAND_IN_KEY)
			var need: int = int(held[item])
			var failed_use: bool = false
			for found: Variant in givers:
				var thing_id: String = str(((found as Array)[1] as Dictionary)["id"])
				var cap: int = int((((found as Array)[1] as Dictionary)["use"] as Dictionary).get("max", 100))
				while not failed_use and _pack_total(world, str(item)) < need and int(world.call("uses_of", thing_id)) < cap:
					var failed: String = _use_times(world, areas, thing_id, int(world.call("uses_of", thing_id)) + 1, str((found as Array)[0]))
					if failed != "":
						errors.append("%s: cannot use %s for %s: %s" % [where, thing_id, str(item), failed])
						failed_use = true
			if not failed_use and _pack_total(world, str(item)) < need:
				var ids: Array[String] = []
				for found: Variant in givers:
					ids.append(str(((found as Array)[1] as Dictionary)["id"]))
				errors.append("%s: using %s never gives enough %s" % [where, ", ".join(ids), str(item)])
	return errors


## [area id, thing] of every thing whose use gives `item`: those in area `prefer` first, then
## the other areas in order.
static func _things_giving(areas: Dictionary, item: String, prefer: String) -> Array:
	var ids: Array = areas.keys()
	if areas.has(prefer):
		ids.erase(prefer)
		ids.push_front(prefer)
	var found: Array = []
	for area_id: Variant in ids:
		for t: Variant in (areas[area_id].data as Dictionary).get("things", []):
			var gives: Dictionary = ((t as Dictionary).get("use", {}) as Dictionary).get("gives", {})
			if not gives.is_empty() and str(gives.get("item", "")) == item:
				found.append([str(area_id), t])
	return found


static func _pack_total(world: RefCounted, item: String) -> int:
	var total: int = 0
	for pack: Variant in (world.get("packs") as Dictionary).values():
		total += int((pack as Dictionary).get(item, 0))
	return total


## Walks to the thing and uses it until the world counts `times` uses. An error, or empty.
static func _use_times(world: RefCounted, areas: Dictionary, thing_id: String, times: int, prefer: String) -> String:
	var ids: Array = areas.keys()
	if areas.has(prefer):
		ids.erase(prefer)
		ids.push_front(prefer)
	for area_id: Variant in ids:
		var area: RefCounted = areas[area_id]
		for t: Variant in area.data.get("things", []):
			if str((t as Dictionary)["id"]) != thing_id:
				continue
			var failed: String = _walk_to(world, areas, str(area_id), area.cell_of(t["cell"]))
			if failed != "":
				return failed
			while int(world.call("uses_of", thing_id)) < times:
				if not bool(area.use_thing(world, thing_id, true)["ok"]):
					return "the thing cannot be used"
			return ""
	return "no such thing"


## Walks the party to a cell of an area, entering each cell of the path through Area.enter.
static func _walk_to(world: RefCounted, areas: Dictionary, area_id: String, cell: Vector2i) -> String:
	if not areas.has(area_id):
		return "area is unknown"
	var trip: String = _travel(world, areas, area_id, area_id)
	if trip != "":
		return trip
	var position: Dictionary = world.get("position")
	var area: RefCounted = areas[area_id]
	var from: Vector2i = Vector2i(int(position["x"]), int(position["y"]))
	var path: Array[Vector2i] = area.find_path(world, from, cell)
	if from == cell:
		path = [from] as Array[Vector2i]
	if path.is_empty():
		return "no path from %s to %s" % [str(from), str(cell)]
	for step_cell: Vector2i in path:
		area.enter(world, step_cell)
	world.set("position", {"area": area_id, "x": cell.x, "y": cell.y})
	return ""


## FALLBACK, removed in P3: gives the hero the held items that no thing gives.
## Tops up the hero's pack with the items that undone steps wait on; an error for any item
## not in `item_ids`, since the player cannot be given it.
static func _grant_holds(quest: Dictionary, world: RefCounted, item_ids: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	var packs: Dictionary = world.get("packs")
	var party: Array = world.get("party")
	var hero: String = str(party[0]) if not party.is_empty() else STAND_IN_KEY
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		if Quests.is_done(quest, str(step["id"]), world) or not cond.has("holds"):
			continue
		var held: Dictionary = cond["holds"]
		for item: Variant in held:
			var item_id: String = str(item)
			if _pack_total(world, item_id) >= int(held[item]):
				continue
			if not item_ids.has(item_id):
				errors.append("quest %s: step %s needs item %s, which is unknown" % [str(quest["id"]), str(step["id"]), item_id])
				continue
			var total: int = 0
			for pack: Variant in packs.values():
				total += int((pack as Dictionary).get(item_id, 0))
			var missing: int = int(held[item]) - total
			if missing > 0:
				if not packs.has(hero):
					packs[hero] = {}
				var mine: Dictionary = packs[hero]
				mine[item_id] = int(mine.get(item_id, 0)) + missing
	return errors


## Has the hero ask the topics that undone steps wait on. The topic is first learned, as if the
## world had taught it; the ask itself goes through People, so a refused ask is an error. When
## `waiting`, only steps whose day has not come are served, and only with topics offered today.
static func _hear_topics(quest: Dictionary, world: RefCounted, people: Dictionary, dialogues: Dictionary, areas: Dictionary = {}, person_areas: Dictionary = {}, waiting: bool = false) -> Array[String]:
	var errors: Array[String] = []
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		if Quests.is_done(quest, str(step["id"]), world):
			continue
		if waiting and int(cond.get("day_min", 0)) <= int(world.get("day")):
			continue
		for entry: Variant in cond.get("heard", []):
			var person_id: String = str(entry["person"])
			var topic: String = str(entry["topic"])
			if People.heard(person_id, topic, world):
				continue
			var where: String = "quest %s: step %s needs %s to tell %s" % [str(quest["id"]), str(step["id"]), person_id, topic]
			if not people.has(person_id):
				errors.append("%s, but the person is unknown" % where)
				continue
			var person: Dictionary = people[person_id]
			var offered: bool = false
			for t: Variant in person.get("topics", []):
				offered = offered or str((t as Dictionary).get("topic", "")) == topic
			if not offered:
				errors.append("%s, but the topic is unknown" % where)
				continue
			if person_areas.has(person_id) and not areas.is_empty():
				var to_area: String = str(person_areas[person_id])
				var trip: String = _travel(world, areas, to_area, str(step.get("area", "")))
				if trip != "" or str((world.get("position") as Dictionary).get("area", "")) != to_area:
					errors.append("%s in %s, but the party cannot get there: %s" % [where, to_area, trip])
					continue
			_learn_by_next(topic, people, dialogues, world, [topic] as Array[String])
			if waiting and not People.available_topics(person, dialogues, world).has(topic):
				continue
			var result: Dictionary = People.ask(person, dialogues, topic, world)
			if not bool(result["ok"]):
				errors.append("%s, but the ask was refused on day %d: %s" % [where, int(world.get("day")), str(result["error"])])
	return errors


## Walks the party to `to_area`: from the position (or the spawn of `start_area`) to an exit cell,
## entering each cell of the path through Area.enter, then through the exit, leg by leg along the
## shortest chain of exits. An error message, or empty if the party is there.
static func _travel(world: RefCounted, areas: Dictionary, to_area: String, start_area: String) -> String:
	var position: Dictionary = world.get("position")
	if position.is_empty():
		if not areas.has(start_area):
			return "no area to start in"
		var first: RefCounted = areas[start_area]
		var spawn: Vector2i = first.cell_of(first.data.get("spawn", [0, 0]))
		position = {"area": start_area, "x": spawn.x, "y": spawn.y}
		world.set("position", position)
	var hops: int = 0
	while str(position["area"]) != to_area:
		hops += 1
		var here: String = str(position["area"])
		var route: Array[String] = _route(areas, here, to_area)
		if route.size() < 2 or hops > areas.size():
			return "no way from %s to %s" % [here, to_area]
		var area: RefCounted = areas[here]
		var from: Vector2i = Vector2i(int(position["x"]), int(position["y"]))
		var path: Array[Vector2i] = []
		for e: Variant in area.data.get("exits", []):
			if str((e as Dictionary)["to"]) == route[1]:
				path = area.find_path(world, from, area.cell_of((e as Dictionary)["cell"]))
				if not path.is_empty():
					break
		if path.is_empty():
			return "no path in %s to the exit to %s" % [here, route[1]]
		for cell: Vector2i in path:
			area.enter(world, cell)
		if area.take_exit(world, path[path.size() - 1]).is_empty():
			return "the exit of %s to %s is shut" % [here, route[1]]
		position = world.get("position")
	return ""


## Shortest chain of area ids from `from` to `to` along the areas' exits, both included.
static func _route(areas: Dictionary, from: String, to: String) -> Array[String]:
	var came: Dictionary = {from: ""}
	var queue: Array[String] = [from]
	var head: int = 0
	while head < queue.size() and not came.has(to):
		var here: String = queue[head]
		head += 1
		if not areas.has(here):
			continue
		for e: Variant in (areas[here].data as Dictionary).get("exits", []):
			var next: String = str((e as Dictionary)["to"])
			if not came.has(next):
				came[next] = here
				queue.append(next)
	var route: Array[String] = []
	if not came.has(to):
		return route
	var at: String = to
	while at != "":
		route.append(at)
		at = str(came[at])
	route.reverse()
	return route


## Makes `topic` known the way play does: ask a topic whose dialogue opens it, learning that one
## first the same way. A topic nobody opens is learned outright, as if the world had taught it.
static func _learn_by_next(topic: String, people: Dictionary, dialogues: Dictionary, world: RefCounted, seen: Array[String]) -> void:
	var known: Array[String] = world.get("topics_known")
	if known.has(topic):
		return
	for person: Variant in people.values():
		for t: Variant in (person as Dictionary).get("topics", []):
			var other: String = str((t as Dictionary)["topic"])
			if seen.has(other):
				continue
			var e: Dictionary = {}
			for d: Variant in (dialogues.get(str(t["dialogue"]), {}) as Dictionary).get("topics", []):
				if str((d as Dictionary).get("topic", "")) == other:
					e = d
			if not (e.get("next", []) as Array).has(topic):
				continue
			seen.append(other)
			_learn_by_next(other, people, dialogues, world, seen)
			if bool(People.ask(person, dialogues, other, world)["ok"]) and known.has(topic):
				return
	People.learn_topic(world, topic)


## Sets the flags that undone steps wait on, when another quest can set them.
static func _set_outside_flags(quest: Dictionary, world: RefCounted, all_quests: Array[Dictionary]) -> void:
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		if Quests.is_done(quest, str(step["id"]), world) or not cond.has("flag"):
			continue
		var flag: String = str(cond["flag"])
		for other: Dictionary in all_quests:
			if str(other["id"]) != str(quest["id"]) and Quests.settable_flags(other).has(flag):
				world.set_flag(flag)
