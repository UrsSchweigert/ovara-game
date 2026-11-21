extends "res://tests/test_case.gd"

const Decide: GDScript = preload("res://rules/decide.gd")
const WorldState: GDScript = preload("res://rules/world_state.gd")


func test_value() -> void:
	check_eq(Decide.value(12, 1), 10, "first step two under")
	check_eq(Decide.value(12, 5), 14, "fifth step two over")


func test_zero_step() -> void:
	check(not Decide.usable(0), "no step cannot be used")
	check(Decide.usable(0, true), "weapon with no step can")
	check_eq(Decide.value(12, 0, true), 7, "weapon five under")
	check_eq(Decide.value(12, 1, true), 10, "weapon with a step has no penalty")


func test_margin_and_difficulty() -> void:
	check_eq(Decide.margin(10, 1, Decide.HARD), -1, "short by one")
	check_eq(Decide.margin(12, 0, Decide.EASY), 4, "over by four")
	check_eq([Decide.EASY, Decide.ORDINARY, Decide.HARD, Decide.VERY_HARD], [8, 10, 12, 14], "difficulties")


func test_gift_uses_margin_and_no_dice() -> void:
	var state: RefCounted = WorldState.new(5)
	var act: Dictionary = {"id": "g1", "kind": "gift", "attribute": 12, "step": 1, "difficulty": 10}
	var r: Dictionary = Decide.decide(act, state)
	check_eq(r["margin"], 0, "margin zero")
	check(r["success"], "zero margin succeeds")
	check((r["dice"] as Array).is_empty(), "no dice")
	check((state.get("dice") as Dictionary).is_empty(), "nothing stored")


func test_weapon_same_act_same_result() -> void:
	var state: RefCounted = WorldState.new(9)
	var act: Dictionary = {"id": "hit1", "kind": "weapon", "attribute": 12, "step": 2, "difficulty": 10}
	var a: Dictionary = Decide.decide(act, state)
	var b: Dictionary = Decide.decide(act, state)
	check_eq(a, b, "repeat gives same result")
	check_eq((a["dice"] as Array).size(), 3, "three dice")


func test_dice_survive_reload() -> void:
	var state: RefCounted = WorldState.new(3)
	var act: Dictionary = {"id": "talk1", "kind": "people", "attribute": 11, "step": 1}
	var before: Dictionary = Decide.decide(act, state)
	var loaded: RefCounted = WorldState.from_json(state.call("to_json"))
	check(loaded != null, "loads")
	check_eq(loaded.call("to_dict"), state.call("to_dict"), "round trip")
	loaded.set("seed_value", 999)
	check_eq(Decide.decide(act, loaded), before, "same after reload")


func test_bad_version_rejected() -> void:
	check(WorldState.from_json("{\"version\": 99}") == null, "unknown version")
	check(WorldState.from_json("nonsense") == null, "not json")
