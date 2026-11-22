extends RefCounted
## The one world state: exploring, dungeons and battles all read and change this and nothing else.
## Plain typed data; saved as versioned JSON text. No files are touched here.

const SAVE_VERSION: int = 1
const WATCHES_PER_DAY: int = 3
const MODES: Array[String] = ["explore", "dungeon", "battle"]

const Sheet: GDScript = preload("res://rules/character_sheet.gd")

## Why the last from_dict or from_json call refused its input; empty when it succeeded.
static var last_error: String = ""

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
var flags: Dictionary = {}
var chapter: int = 1
var day: int = 1
## 0 to 2 within the day.
var watch: int = 0
var journal: Array[String] = []
## Where the party stands: area or dungeon id, cell or tile, position inside it, facing.
var position: Dictionary = {}
var mode: String = "explore"
## Seed for the state's dice, and the draws stored so that a reload never redraws them.
var dice_seed: int = 1
var dice: Array[int] = []


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
	day += total / WATCHES_PER_DAY
	watch = total % WATCHES_PER_DAY


func advance_days(count: int) -> void:
	assert(count >= 0)
	day += count


func sheet_of(id: String) -> RefCounted:
	return sheets.get(id) as RefCounted


func health_of(id: String) -> int:
	return sheet_of(id).health()


func ebb_limit_of(id: String) -> int:
	return sheet_of(id).ebb_limit()


func ebb_of(id: String) -> int:
	return int(ebb.get(id, 0))


## Adds ebb without clamping.
func add_ebb(id: String, amount: int) -> void:
	ebb[id] = ebb_of(id) + amount


func to_dict() -> Dictionary:
	var sheet_data: Dictionary = {}
	for id: Variant in sheets:
		sheet_data[id] = (sheets[id] as RefCounted).to_dict()
	return {
		"version": SAVE_VERSION,
		"party": party.duplicate(), "base": base.duplicate(true), "sheets": sheet_data,
		"packs": packs.duplicate(true), "supplies": supplies.duplicate(), "ebb": ebb.duplicate(),
		"flags": flags.duplicate(true), "chapter": chapter, "day": day, "watch": watch,
		"journal": journal.duplicate(), "position": position.duplicate(true), "mode": mode,
		"dice_seed": dice_seed, "dice": dice.duplicate(),
	}


## Returns null and sets last_error when the version is missing or not SAVE_VERSION.
static func from_dict(d: Dictionary) -> RefCounted:
	last_error = ""
	if not d.has("version"):
		last_error = "save has no version, expected %d" % SAVE_VERSION
		return null
	if not (d["version"] is int or d["version"] is float) or int(d["version"]) != SAVE_VERSION:
		last_error = "save version %s not supported, expected %d" % [str(d["version"]), SAVE_VERSION]
		return null
	var mode_value: String = str(d.get("mode", "explore"))
	if not MODES.has(mode_value):
		last_error = "unknown mode '%s'" % mode_value
		return null
	var w: RefCounted = (load("res://rules/world_state.gd") as GDScript).new()
	for p: Variant in d.get("party", []):
		w.party.append(str(p))
	w.base = _ints(d.get("base", {}))
	var sd: Dictionary = d.get("sheets", {})
	for id: Variant in sd:
		w.sheets[str(id)] = Sheet.from_dict(sd[id])
	var pk: Dictionary = d.get("packs", {})
	for id: Variant in pk:
		w.packs[str(id)] = _ints(pk[id])
	w.supplies = _ints(d.get("supplies", {}))
	w.ebb = _ints(d.get("ebb", {}))
	w.flags = _ints(d.get("flags", {}))
	w.chapter = int(d.get("chapter", 1))
	w.day = int(d.get("day", 1))
	w.watch = int(d.get("watch", 0))
	for j: Variant in d.get("journal", []):
		w.journal.append(str(j))
	w.position = _ints(d.get("position", {}))
	w.mode = mode_value
	w.dice_seed = int(d.get("dice_seed", 1))
	for x: Variant in d.get("dice", []):
		w.dice.append(int(x))
	return w


func to_json() -> String:
	return JSON.stringify(to_dict())


static func from_json(text: String) -> RefCounted:
	last_error = ""
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		last_error = "save is not a JSON object"
		return null
	return from_dict(parsed)


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
