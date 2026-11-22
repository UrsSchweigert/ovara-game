extends RefCounted
## Plays a quest with the rules alone: opens it, does each step, clears it. A step that waits
## on a flag is helped only if some loaded quest can set that flag; otherwise the quest is stuck.

const Quests: GDScript = preload("res://rules/quest_engine.gd")


## Error messages; empty if the quest was cleared. `all_quests` are the loaded quests whose
## flags may stand in for the world's other doings.
static func play(quest: Dictionary, world: RefCounted, all_quests: Array[Dictionary]) -> Array[String]:
	var id: String = str(quest["id"])
	if not Quests.open(quest, world):
		return ["quest %s: cannot open at chapter %d (chapters %s)" % [id, world.chapter, str(quest["chapters"])]]
	for pass_number: int in 2:
		for step: Dictionary in quest["steps"]:
			if not step.has("requires"):
				Quests.complete_step(quest, str(step["id"]), world)
		_advance_days(quest, world)
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
