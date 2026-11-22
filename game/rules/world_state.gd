extends RefCounted
## The one world state. Every mode reads and changes this and keeps no copy of its own.
## It saves to versioned JSON. Dice for acts are stored here, keyed by act id, so that
## reloading a save cannot change an answer. No files are touched here.

const SeededRng: GDScript = preload("res://rules/seeded_rng.gd")
const Sheet: GDScript = preload("res://rules/character_sheet.gd")

const VERSION: int = 1
const WATCHES_PER_DAY: int = 3
const MODES: Array[String] = ["explore", "dungeon", "battle"]
## What health_of and ebb_limit_of return for a person with no sheet.
const NO_SHEET: int = -1

var seed_value: int = 1
var flags: Dictionary = {}
## Act id -> [d1, d2, d3], each 1 to 6.
var dice: Dictionary = {}
## Person ids, in marching order.
var party: Array[String] = []
var base: Dictionary = {}
## Person id to character sheet.
var sheets: Dictionary = {}
## Person id to {item id: count}.
var packs: Dictionary = {}
## Supply id to count held by the party.
var supplies: Dictionary = {}
## Person id to current ebb. May pass the limit: overreach is allowed.
var ebb: Dictionary = {}
var chapter: int = 1
var day: int = 1
## 0 to 2 within the day.
var watch: int = 0
var journal: Array[String] = []
## Where the party stands: area or dungeon id, tile or cell, facing.
var position: Dictionary = {}
var mode: String = "explore"
## Topic canon ids the party holds.
var topics_known: Array[String] = []
## Person id to the topic ids they have already answered.
var topics_heard: Dictionary = {}


func _init(new_seed: int = 1) -> void:
	seed_value = new_seed


## The three dice for an act. Drawn the first time the act is chosen, then returned as stored.
func dice_for(act_id: String) -> Array[int]:
	if not dice.has(act_id):
		var rng: RefCounted = SeededRng.new(seed_value ^ act_id.hash())
		var drawn: Array[int] = []
		for i: int in 3:
			drawn.append(1 + int(rng.call("next_below", 6)))
		dice[act_id] = drawn
	var stored: Array[int] = []
	for d: Variant in dice[act_id]:
		stored.append(int(d))
	return stored


func get_flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)


func set_flag(name: String, value: Variant = true) -> void:
	flags[name] = value


func has_flag(name: String) -> bool:
	return flags.has(name)


func advance_chapter() -> void:
	chapter += 1


## Moves the calendar on by a number of watches; three watches make a day.
func advance_watch(count: int = 1) -> void:
	assert(count >= 0)
	var total: int = watch + count
	@warning_ignore("integer_division")
	day += total / WATCHES_PER_DAY
	watch = total % WATCHES_PER_DAY


func advance_days(count: int) -> void:
	assert(count >= 0)
	day += count


func has_sheet(id: String) -> bool:
	return sheets.has(id)


## Null for a person with no sheet.
func sheet_of(id: String) -> RefCounted:
	return sheets.get(id) as RefCounted


## Health equals Body. NO_SHEET for a person with no sheet.
func health_of(id: String) -> int:
	var s: RefCounted = sheet_of(id)
	return NO_SHEET if s == null else int(s.call("health"))


## The ebb limit equals Standing. NO_SHEET for a person with no sheet.
func ebb_limit_of(id: String) -> int:
	var s: RefCounted = sheet_of(id)
	return NO_SHEET if s == null else int(s.call("ebb_limit"))


func ebb_of(id: String) -> int:
	return int(ebb.get(id, 0))


## Adds ebb without clamping.
func add_ebb(id: String, amount: int) -> void:
	ebb[id] = ebb_of(id) + amount


func to_dict() -> Dictionary:
	var sheet_data: Dictionary = {}
	for id: Variant in sheets:
		sheet_data[id] = (sheets[id] as RefCounted).call("to_dict")
	return {
		"version": VERSION, "seed": seed_value, "flags": flags.duplicate(true), "dice": dice.duplicate(true),
		"party": party.duplicate(), "base": base.duplicate(true), "sheets": sheet_data,
		"packs": packs.duplicate(true), "supplies": supplies.duplicate(), "ebb": ebb.duplicate(),
		"chapter": chapter, "day": day, "watch": watch,
		"journal": journal.duplicate(), "position": position.duplicate(true), "mode": mode,
		"topics_known": topics_known.duplicate(), "topics_heard": topics_heard.duplicate(true),
	}


func to_json() -> String:
	return JSON.stringify(to_dict())


## Returns {"state": world state or null, "error": why it was refused, empty when it was not}.
static func from_dict(data: Dictionary) -> Dictionary:
	if not data.has("version"):
		return _refused("save has no version, expected %d" % VERSION)
	var v: Variant = data["version"]
	if not (v is int or v is float) or float(v) != float(VERSION):
		return _refused("save version %s not supported, expected %d" % [str(v), VERSION])
	var mode_value: String = str(data.get("mode", "explore"))
	if not MODES.has(mode_value):
		return _refused("unknown mode '%s'" % mode_value)
	var w: RefCounted = (load("res://rules/world_state.gd") as GDScript).new(int(data.get("seed", 1)))
	w.flags = _ints(data.get("flags", {}))
	var loaded: Dictionary = data.get("dice", {})
	for key: Variant in loaded:
		var triple: Array[int] = []
		for d: Variant in loaded[key]:
			triple.append(int(d))
		w.dice[str(key)] = triple
	for p: Variant in data.get("party", []):
		w.party.append(str(p))
	w.base = _ints(data.get("base", {}))
	var sd: Dictionary = data.get("sheets", {})
	for id: Variant in sd:
		w.sheets[str(id)] = Sheet.call("from_dict", sd[id])
	var pk: Dictionary = data.get("packs", {})
	for id: Variant in pk:
		w.packs[str(id)] = _ints(pk[id])
	w.supplies = _ints(data.get("supplies", {}))
	w.ebb = _ints(data.get("ebb", {}))
	w.chapter = int(data.get("chapter", 1))
	w.day = int(data.get("day", 1))
	w.watch = int(data.get("watch", 0))
	for j: Variant in data.get("journal", []):
		w.journal.append(str(j))
	w.position = _ints(data.get("position", {}))
	w.mode = mode_value
	for t: Variant in data.get("topics_known", []):
		w.topics_known.append(str(t))
	var heard: Dictionary = data.get("topics_heard", {})
	for id: Variant in heard:
		var list: Array[String] = []
		for t: Variant in heard[id]:
			list.append(str(t))
		w.topics_heard[str(id)] = list
	return {"state": w, "error": ""}


## Same as from_dict, from JSON text.
static func parse(text: String) -> Dictionary:
	var json: JSON = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _refused("save is not a JSON object")
	return from_dict(json.data)


## Returns null if the text is not a save this version can read; parse() says why.
static func from_json(text: String) -> RefCounted:
	return parse(text)["state"] as RefCounted


static func _refused(error: String) -> Dictionary:
	return {"state": null, "error": error}


## JSON reads every number as a float; turn whole ones back into ints, all the way down.
static func _ints(value: Variant) -> Variant:
	if value is float and value == floorf(value):
		return int(value)
	if value is Dictionary:
		var out: Dictionary = {}
		for k: Variant in value:
			out[k] = _ints(value[k])
		return out
	if value is Array:
		var arr: Array = []
		for v: Variant in value:
			arr.append(_ints(v))
		return arr
	return value
