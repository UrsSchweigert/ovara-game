extends RefCounted
## How anything is decided (PLAN.md, "The character sheet"). Pure functions of their inputs and
## of the dice stored on the world state.

const EASY: int = 8
const ORDINARY: int = 10
const HARD: int = 12
const VERY_HARD: int = 14

## Acts that use the margin as it is, with no dice.
const MARGIN_KINDS: Array[String] = ["gift", "craft", "lesson"]
## Acts that roll three dice, the value or under.
const DICE_KINDS: Array[String] = ["weapon", "people"]

const WEAPON_PENALTY: int = 5


## Attribute plus step, less three. A weapon with no step is used at five under the attribute.
## Returns -1 for a skill that cannot be used (no step, not a weapon).
static func value(attribute: int, step: int, is_weapon: bool = false) -> int:
	if step <= 0:
		return attribute - WEAPON_PENALTY if is_weapon else -1
	return attribute + step - 3


static func usable(step: int, is_weapon: bool = false) -> bool:
	return step > 0 or is_weapon


static func margin(skill_value: int, modifiers: int, difficulty: int) -> int:
	return skill_value + modifiers - difficulty


## act: {id, kind, attribute, step, modifiers, difficulty}. Dice kinds draw from and store on state.
## Returns {usable, value, modifiers, difficulty, margin, dice, success}.
static func decide(act: Dictionary, state: RefCounted) -> Dictionary:
	var kind: String = act.get("kind", "gift")
	var step: int = act.get("step", 0)
	var is_weapon: bool = kind == "weapon"
	var modifiers: int = act.get("modifiers", 0)
	var difficulty: int = act.get("difficulty", ORDINARY)
	var result: Dictionary = {
		"usable": usable(step, is_weapon), "value": value(act.get("attribute", 10), step, is_weapon),
		"modifiers": modifiers, "difficulty": difficulty, "dice": [], "success": false,
	}
	result["margin"] = margin(result["value"], modifiers, difficulty)
	if not result["usable"]:
		return result
	if kind in DICE_KINDS:
		var rolled: Array[int] = state.call("dice_for", str(act.get("id", "")))
		result["dice"] = rolled
		var total: int = rolled[0] + rolled[1] + rolled[2]
		result["success"] = total <= result["value"] + modifiers
	else:
		result["success"] = result["margin"] >= 0
	return result
