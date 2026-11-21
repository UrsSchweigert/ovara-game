extends "res://tests/test_case.gd"

const SeededRng: GDScript = preload("res://rules/seeded_rng.gd")


func test_same_seed_same_sequence() -> void:
	var a: RefCounted = SeededRng.new(42)
	var b: RefCounted = SeededRng.new(42)
	for i: int in 100:
		check_eq(a.call("next_u32"), b.call("next_u32"), "draw %d" % i)


func test_known_values() -> void:
	# Pinned so that a change to the generator is noticed: saves and replays depend on it.
	var r: RefCounted = SeededRng.new(1)
	check_eq(r.call("next_u32"), 270369, "first draw from seed 1")
	check_eq(r.call("next_u32"), 67634689, "second draw from seed 1")


func test_next_below_stays_in_range() -> void:
	var r: RefCounted = SeededRng.new(7)
	for i: int in 500:
		var v: int = r.call("next_below", 6)
		check(v >= 0 and v < 6, "value %d out of range" % v)
