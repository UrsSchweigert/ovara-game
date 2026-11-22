extends RefCounted
## Plays a quest with the rules alone: opens it, does each step, clears it. A step that waits
## on a flag is helped only if some loaded quest can set that flag; otherwise the quest is stuck.

const Quests: GDScript = preload("res://rules/quest_engine.gd")
const People: GDScript = preload("res://rules/people.gd")
## Pack key for items granted to a party with no members.
const STAND_IN_KEY: String = "quest_player"


## Error messages; empty if the quest was cleared. `all_quests` are the loaded quests whose
## flags may stand in for the world's other doings. `item_ids` are the items the player may be
## given for steps that wait on holds. `people` maps file id to person JSON and `dialogues` maps
## dialogue id to dialogue JSON, for steps that wait on topics heard. `areas` maps area id to Area
## and `targets` maps step id to {"thing": id} or {"exit": area id}: the player must find a path
## from the area's spawn to that thing or exit before the step is done.
static func play(quest: Dictionary, world: RefCounted, all_quests: Array[Dictionary], item_ids: Array[String] = [], people: Dictionary = {}, dialogues: Dictionary = {}, areas: Dictionary = {}, targets: Dictionary = {}) -> Array[String]:
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
		_advance_days(quest, world)
		var held_errors: Array[String] = _grant_holds(quest, world, item_ids)
		if not held_errors.is_empty():
			return held_errors
		var heard_errors: Array[String] = _hear_topics(quest, world, people, dialogues)
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


## Lets the days pass for undone steps that wait on a day; never moves the calendar back.
static func _advance_days(quest: Dictionary, world: RefCounted) -> void:
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		if Quests.is_done(quest, str(step["id"]), world) or not cond.has("day_min"):
			continue
		var day_min: int = int(cond["day_min"])
		if int(world.get("day")) < day_min:
			world.advance_days(day_min - int(world.get("day")))


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
## world had taught it; the ask itself goes through People, so a refused ask is an error.
static func _hear_topics(quest: Dictionary, world: RefCounted, people: Dictionary, dialogues: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		if Quests.is_done(quest, str(step["id"]), world):
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
			_learn_by_next(topic, people, dialogues, world, [topic] as Array[String])
			var result: Dictionary = People.ask(person, dialogues, topic, world)
			if not bool(result["ok"]):
				errors.append("%s, but the ask was refused: %s" % [where, str(result["error"])])
	return errors


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
