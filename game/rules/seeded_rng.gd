extends RefCounted
## The only source of randomness allowed in rules/. Same seed, same sequence, on every device.
## PLAN.md allows randomness only where it says so (Storm scatter).

var _state: int


func _init(seed_value: int) -> void:
	_state = seed_value & 0xFFFFFFFF
	if _state == 0:
		_state = 0x9E3779B9


## Next raw 32-bit value (xorshift32).
func next_u32() -> int:
	var x: int = _state
	x = (x ^ (x << 13)) & 0xFFFFFFFF
	x = x ^ (x >> 17)
	x = (x ^ (x << 5)) & 0xFFFFFFFF
	_state = x
	return x


## Whole number from 0 up to, not including, bound.
func next_below(bound: int) -> int:
	assert(bound > 0)
	return next_u32() % bound
