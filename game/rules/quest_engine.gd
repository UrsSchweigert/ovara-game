extends RefCounted
## The quest engine. A quest is loaded JSON; its progress lives in the world state under
## `quests`. Steps are done by the rules, never by flags. Each step gives its points once to
## every party member; clearing a stage gives STAGE_POINTS more. Battles give no points.

const People: GDScript = preload("res://rules/people.gd")

const STAGE_POINTS: int = 5
const OPEN: String = "open"
const CLEARED: String = "cleared"
const CLOSED: String = "closed"


static func status(quest: Dictionary, world: RefCounted) -> String:
	var q: Dictionary = (world.get("quests") as Dictionary).get(str(quest["id"]), {})
	return str(q.get("status", ""))


static func is_done(quest: Dictionary, step_id: String, world: RefCounted) -> bool:
	var q: Dictionary = (world.get("quests") as Dictionary).get(str(quest["id"]), {})
	return (q.get("done", []) as Array).has(step_id)


static func is_side(quest: Dictionary) -> bool:
	return bool(quest.get("side", false))


## Opens a quest when the chapter is within its range. Returns false if it could not open.
static func open(quest: Dictionary, world: RefCounted) -> bool:
	var range: Array = quest["chapters"]
	var chapter: int = int(world.get("chapter"))
	if status(quest, world) != "" or chapter < int(range[0]) or chapter > int(range[1]):
		return false
	(world.get("quests") as Dictionary)[str(quest["id"])] = {"status": OPEN, "done": []}
	_log_next(quest, world)
	return true


## Finishes a step once: awards its points, sets its flags, journals the next step.
## Returns the points awarded; 0 if the quest is not open, the step is unknown or already done.
static func complete_step(quest: Dictionary, step_id: String, world: RefCounted) -> int:
	if status(quest, world) != OPEN or is_done(quest, step_id, world):
		return 0
	for step: Dictionary in quest["steps"]:
		if str(step["id"]) != step_id:
			continue
		var q: Dictionary = (world.get("quests") as Dictionary)[str(quest["id"])]
		(q["done"] as Array).append(step_id)
		var given: int = int(step["points"])
		_award(world, given)
		for f: Variant in step.get("sets", []):
			world.call("set_flag", str(f))
		_log_next(quest, world)
		return given
	return 0


## Completes every open step whose condition is met, then tries to clear. Steps with no
## `requires` are only completed by complete_step. Returns true if the quest cleared.
static func update(quest: Dictionary, world: RefCounted) -> bool:
	if status(quest, world) != OPEN:
		return false
	for step: Dictionary in quest["steps"]:
		if step.has("requires") and People.condition_met(step["requires"], world):
			complete_step(quest, str(step["id"]), world)
	return try_clear(quest, world)


## Clears the quest once every step is done: sets its flags, pays the stage bonus and, for a
## stage, advances the chapter. Side quests pay no bonus and never move the chapter.
static func try_clear(quest: Dictionary, world: RefCounted) -> bool:
	if status(quest, world) != OPEN:
		return false
	for step: Dictionary in quest["steps"]:
		if not is_done(quest, str(step["id"]), world):
			return false
	((world.get("quests") as Dictionary)[str(quest["id"])] as Dictionary)["status"] = CLEARED
	world.call("set_flag", str(quest["clears"]))
	for f: Variant in quest["sets"]:
		world.call("set_flag", str(f))
	if not is_side(quest):
		_award(world, STAGE_POINTS)
		world.call("advance_chapter")
	(world.get("journal") as Array[String]).append("Done: %s" % str(quest["id"]))
	return true


## Closes open side quests tied to a lost place. Every close is written to the journal.
static func close_for_place(quests: Array, place_id: String, world: RefCounted) -> Array[String]:
	var closed: Array[String] = []
	for quest: Dictionary in quests:
		if not is_side(quest) or status(quest, world) != OPEN or str(quest.get("place", "")) != place_id:
			continue
		((world.get("quests") as Dictionary)[str(quest["id"])] as Dictionary)["status"] = CLOSED
		(world.get("journal") as Array[String]).append("Closed: %s" % str(quest["id"]))
		closed.append(str(quest["id"]))
	return closed


## Battles give no points. Kept so callers state it and tests hold it.
static func award_battle(_world: RefCounted) -> int:
	return 0


## Every flag the quest can set: its clears flag, its sets and its steps' sets.
static func settable_flags(quest: Dictionary) -> Array[String]:
	var out: Array[String] = [str(quest["clears"])]
	for f: Variant in quest["sets"]:
		out.append(str(f))
	for step: Dictionary in quest["steps"]:
		for f: Variant in step.get("sets", []):
			out.append(str(f))
	return out


## Flags the quest reads that nothing in it sets. The caller checks them against other quests.
static func unsettable_reads(quest: Dictionary) -> Array[String]:
	var settable: Array[String] = settable_flags(quest)
	var out: Array[String] = []
	for step: Dictionary in quest["steps"]:
		var cond: Dictionary = step.get("requires", {})
		for key: String in ["flag", "not_flag"]:
			if cond.has(key) and not settable.has(str(cond[key])) and not out.has(str(cond[key])):
				out.append(str(cond[key]))
	return out


static func _award(world: RefCounted, amount: int) -> void:
	var pts: Dictionary = world.get("points")
	for id: String in world.get("party"):
		pts[id] = int(pts.get(id, 0)) + amount


static func _log_next(quest: Dictionary, world: RefCounted) -> void:
	for step: Dictionary in quest["steps"]:
		if not is_done(quest, str(step["id"]), world):
			(world.get("journal") as Array[String]).append(str(step["intent"]))
			return
