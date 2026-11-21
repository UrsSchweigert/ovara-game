extends RefCounted
## The one world state. Every mode reads and changes this and keeps no copy of its own.
## It saves to versioned JSON. Dice for acts are stored here, keyed by act id, so that
## reloading a save cannot change an answer.

const SeededRng: GDScript = preload("res://rules/seeded_rng.gd")

const VERSION: int = 1

var seed_value: int = 1
var flags: Dictionary = {}
## Act id -> [d1, d2, d3], each 1 to 6.
var dice: Dictionary = {}


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


func to_dict() -> Dictionary:
	return {"version": VERSION, "seed": seed_value, "flags": flags.duplicate(true), "dice": dice.duplicate(true)}


func to_json() -> String:
	return JSON.stringify(to_dict())


## Returns null if the text is not a save this version can read.
static func from_json(text: String) -> RefCounted:
	var json: JSON = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = json.data
	if int(data.get("version", -1)) != VERSION:
		return null
	var state: RefCounted = (load("res://rules/world_state.gd") as GDScript).new(int(data.get("seed", 1)))
	state.flags = (data.get("flags", {}) as Dictionary).duplicate(true)
	var loaded: Dictionary = data.get("dice", {})
	for key: Variant in loaded.keys():
		var triple: Array[int] = []
		for d: Variant in loaded[key]:
			triple.append(int(d))
		state.dice[str(key)] = triple
	return state
