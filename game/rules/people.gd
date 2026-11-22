extends RefCounted
## People and topics. A person holds topics, each gated by chapter and flag; the party must
## also know a topic to ask it. Pure functions over the world state and loaded JSON data.

## No one tells the hero his name before this chapter.
const NAME_CHAPTER: int = 7
const MAX_LINES: int = 3


static func condition_met(cond: Dictionary, world: RefCounted) -> bool:
	if cond.has("chapter_min") and int(world.get("chapter")) < int(cond["chapter_min"]):
		return false
	if cond.has("chapter_max") and int(world.get("chapter")) > int(cond["chapter_max"]):
		return false
	if cond.has("flag") and not bool(world.call("get_flag", str(cond["flag"]))):
		return false
	if cond.has("not_flag") and bool(world.call("get_flag", str(cond["not_flag"]))):
		return false
	if cond.has("day_min") and int(world.get("day")) < int(cond["day_min"]):
		return false
	for h: Variant in cond.get("heard", []):
		if not heard(str(h["person"]), str(h["topic"]), world):
			return false
	for e: Variant in cond.get("entered", []):
		var cell: Array = (e as Dictionary)["cell"]
		if not bool(world.call("has_entered", str(e["area"]), Vector2i(int(cell[0]), int(cell[1])))):
			return false
	var uses: Dictionary = cond.get("used", {})
	for thing: Variant in uses:
		if int(world.call("uses_of", str(thing))) < int(uses[thing]):
			return false
	var held: Dictionary = cond.get("holds", {})
	for item: Variant in held:
		var total: int = 0
		for pack: Variant in (world.get("packs") as Dictionary).values():
			total += int((pack as Dictionary).get(item, 0))
		if total < int(held[item]):
			return false
	return true


## Reads a person or dialogue JSON file; an empty dictionary if it cannot be read.
static func load_json(path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	var json: JSON = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data


## The dialogue entry for a topic, or an empty dictionary.
static func _entry(dialogues: Dictionary, dialogue_id: String, topic: String) -> Dictionary:
	var d: Dictionary = dialogues.get(dialogue_id, {})
	for e: Variant in d.get("topics", []):
		if str((e as Dictionary).get("topic", "")) == topic:
			return e
	return {}


## Topic ids the person will answer now. `dialogues` maps dialogue id to its loaded JSON.
static func available_topics(person: Dictionary, dialogues: Dictionary, world: RefCounted) -> Array[String]:
	var out: Array[String] = []
	var known: Array[String] = world.get("topics_known")
	for t: Variant in person.get("topics", []):
		var topic: String = str(t["topic"])
		if not known.has(topic) or out.has(topic):
			continue
		if not condition_met(t.get("when", {}), world):
			continue
		var e: Dictionary = _entry(dialogues, str(t["dialogue"]), topic)
		if e.is_empty() or not condition_met(e.get("when", {}), world):
			continue
		if bool(e.get("names_hero", false)) and int(world.get("chapter")) < NAME_CHAPTER:
			continue
		out.append(topic)
	return out


static func heard(person_id: String, topic: String, world: RefCounted) -> bool:
	var h: Dictionary = world.get("topics_heard")
	return (h.get(person_id, []) as Array).has(topic)


## The speaking mark: the person can answer a held topic not yet heard.
static func has_news(person: Dictionary, dialogues: Dictionary, world: RefCounted) -> bool:
	var id: String = str(person.get("id", ""))
	for topic: String in available_topics(person, dialogues, world):
		if not heard(id, topic, world):
			return true
	return false


## Adds a topic once, by canon id.
static func learn_topic(world: RefCounted, topic: String) -> void:
	var known: Array[String] = world.get("topics_known")
	if not known.has(topic):
		known.append(topic)


## Asks a topic. Returns {"ok": bool, "panels": Array, "error": String}. A good ask marks the
## topic heard, sets its flags and teaches the topics it opens. A refused ask changes nothing.
static func ask(person: Dictionary, dialogues: Dictionary, topic: String, world: RefCounted) -> Dictionary:
	if not available_topics(person, dialogues, world).has(topic):
		return {"ok": false, "panels": [], "error": "'%s' is not available" % topic}
	var dialogue_id: String = ""
	for t: Variant in person["topics"]:
		if str(t["topic"]) == topic and condition_met(t.get("when", {}), world):
			dialogue_id = str(t["dialogue"])
			break
	var e: Dictionary = _entry(dialogues, dialogue_id, topic)
	var panels: Array = e.get("panels", [])
	for p: Variant in panels:
		if (p.get("lines", []) as Array).size() > MAX_LINES:
			return {"ok": false, "panels": [], "error": "a panel holds at most %d lines" % MAX_LINES}
	var id: String = str(person.get("id", ""))
	var h: Dictionary = world.get("topics_heard")
	if not h.has(id):
		var fresh: Array[String] = []
		h[id] = fresh
	if not (h[id] as Array).has(topic):
		(h[id] as Array).append(topic)
	for f: Variant in e.get("sets", []):
		world.call("set_flag", str(f))
	for n: Variant in e.get("next", []):
		learn_topic(world, str(n))
	return {"ok": true, "panels": panels, "error": ""}


## The name the world calls the person by at the world's chapter: the entry of `names` with the
## highest from_chapter not after it. A later name is never returned early. Without one, the id.
static func display_name(person: Dictionary, world: RefCounted) -> String:
	var chapter: int = int(world.get("chapter"))
	var best: int = -1
	var out: String = str(person.get("id", ""))
	for n: Variant in person.get("names", []):
		var from: int = int((n as Dictionary).get("from_chapter", 1))
		if from <= chapter and from > best:
			best = from
			out = str((n as Dictionary).get("name", out))
	return out


## The key the client looks a portrait up by.
static func portrait_key(person: Dictionary) -> String:
	return str(person.get("portrait", person.get("id", "")))
