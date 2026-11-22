extends RefCounted
## Hands the running session from the title to the scenes that follow it.

static var session: RefCounted = null


static func put(value: RefCounted) -> void:
	session = value
