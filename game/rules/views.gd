extends RefCounted
## Ready-made data for the journal, party and pack screens: plain dictionaries drawn from a
## session's world state and content. Nothing here changes the world.

const Quests: GDScript = preload("res://rules/quest_engine.gd")
const People: GDScript = preload("res://rules/people.gd")


## {"stage": {"id", "title", "next"}, "open": [{"id", "title", "next"}], "finished": [...]}.
## The stage is the open main quest; `next` is the intent line of its first step not done.
static func journal(session: RefCounted) -> Dictionary:
	var out: Dictionary = {"stage": {}, "open": [], "finished": []}
	for q: Dictionary in session.quests:
		var status: String = Quests.status(q, session.world)
		if status == "":
			continue
		var entry: Dictionary = {"id": str(q["id"]), "title": str(q.get("title", q["id"])), "next": _next_intent(q, session.world)}
		if not Quests.is_side(q):
			if status == Quests.OPEN:
				out["stage"] = entry
		elif status == Quests.OPEN:
			(out["open"] as Array).append(entry)
		else:
			entry["next"] = ""
			(out["finished"] as Array).append(entry)
	return out


static func _next_intent(quest: Dictionary, world: RefCounted) -> String:
	if Quests.status(quest, world) != Quests.OPEN:
		return ""
	for step: Dictionary in quest["steps"]:
		if not Quests.is_done(quest, str(step["id"]), world):
			return str(step["intent"])
	return ""


## {"members": [...], "guests": [...]}; each is {"id", "name", "portrait", "body", "hands", "mind",
## "standing", "reach", "ebb", "limit", "skills": [{"skill", "step"}], "traits": [String]}.
static func party(session: RefCounted) -> Dictionary:
	var out: Dictionary = {"members": [], "guests": []}
	for id: String in session.world.party:
		(out["members"] as Array).append(_sheet_view(session, id))
	for id: Variant in session.world.position.get("guests", []):
		(out["guests"] as Array).append(_sheet_view(session, str(id)))
	return out


static func _sheet_view(session: RefCounted, id: String) -> Dictionary:
	var person: Dictionary = session.people.get(id, {"id": id})
	person = person.duplicate()
	person["id"] = id
	var v: Dictionary = {"id": id, "name": People.display_name(person, session.world), "portrait": People.portrait_key(person),
		"body": 0, "hands": 0, "mind": 0, "standing": 0, "reach": 0, "ebb": session.world.ebb_of(id), "limit": 0, "skills": [], "traits": []}
	var sheet: RefCounted = session.world.sheet_of(id)
	if sheet == null:
		return v
	v["body"] = sheet.body
	v["hands"] = sheet.hands
	v["mind"] = sheet.mind
	v["standing"] = sheet.standing
	v["reach"] = sheet.reach
	v["limit"] = sheet.ebb_limit()
	v["traits"] = sheet.traits.duplicate()
	var names: Array = sheet.skills.keys()
	names.sort()
	for k: Variant in names:
		(v["skills"] as Array).append({"skill": str(k), "step": int(sheet.skills[k])})
	return v


## {"people": [{"id", "name", "items": [{"item", "count"}], "slots"}], "supplies": {item: count}};
## slots is the number of stacks the person carries.
static func pack(session: RefCounted) -> Dictionary:
	var out: Dictionary = {"people": [], "supplies": (session.world.supplies as Dictionary).duplicate()}
	for id: String in session.world.party:
		var person: Dictionary = (session.people.get(id, {}) as Dictionary).duplicate()
		person["id"] = id
		var held: Dictionary = session.world.packs.get(id, {})
		var items: Array = []
		var keys: Array = held.keys()
		keys.sort()
		for k: Variant in keys:
			if int(held[k]) > 0:
				items.append({"item": str(k), "count": int(held[k])})
		(out["people"] as Array).append({"id": id, "name": People.display_name(person, session.world), "items": items, "slots": items.size()})
	return out
