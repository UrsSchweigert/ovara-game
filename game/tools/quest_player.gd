extends RefCounted
## Plays a quest with the rules alone: opens it, does each step, clears it. A step that waits
## on a flag is helped only if some loaded quest can set that flag; otherwise the quest is stuck.

const Quests: GDScript = preload("res://rules/quest_engine.gd")
## Pack key for items granted to a party with no members.
const STAND_IN_KEY: String = "quest_player"


## Error messages; empty if the quest was cleared. `all_quests` are the loaded quests whose
## flags may stand in for the world's other doings. `item_ids` are the items the player may be
## given for steps that wait on holds.
static func play(quest: Dictionary, world: RefCounted, all_quests: Array[Dictionary], item_ids: Array[String] = []) -> Array[String]:
	var id: String = str(quest["id"])
	if not Quests.open(quest, world):
		return ["quest %s: cannot open at chapter %d (chapters %s)" % [id, world.chapter, str(quest["chapters"])]]
	for pass_number: int in 2:
		for step: Dictionary in quest["steps"]:
			if not step.has("requires"):
				Quests.complete_step(quest, str(step["id"]), world)
		_advance_days(quest, world)
		var held_errors: Array[String] = _grant_holds(quest, world, item_ids)
		if not held_errors.is_empty():
			return held_errors
		Quests.update(quest, world)
		if Quests.status(quest, world) == Quests.CLEARED:
			return []
		_set_outside_flags(quest, world, all_quests)
	var stuck: Array[String] = []
	for step: Dictionary in quest["steps"]:
		if not Quests.is_done(quest, str(step["id"]), world):
			stuck.append(str(step["id"]))
	return ["quest %s: stuck at step %s" % [id, ", ".join(stuck)]]


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
