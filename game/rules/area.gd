extends RefCounted
## One area, loaded from its JSON: tiles, exits, things, encounters, light. It reads the world
## state for flags, chapter and party traits and changes only position. No nodes, no files.

const MAX_COLS: int = 64
const MAX_ROWS: int = 48
const WATER_BREATHER: String = "trait.water-breather"
## Below this, the area is dark and the party needs a light.
const DARK_BELOW: float = 0.3
## Days a mariner lasts on land before drying out (canon rule 8).
const MARINER_DAYS_ON_LAND: int = 1
const STEPS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var id: String = ""
var data: Dictionary = {}
var errors: Array[String] = []


## Returns the area, or an area whose errors say why the data was refused.
static func from_dict(source: Dictionary) -> RefCounted:
	var a: RefCounted = (load("res://rules/area.gd") as GDScript).new()
	a.call("_load", source)
	return a


func _load(source: Dictionary) -> void:
	data = source
	id = str(source.get("id", ""))
	var rows: Array = source.get("rows", [])
	if rows.is_empty() or rows.size() > MAX_ROWS:
		errors.append("area needs 1 to %d rows" % MAX_ROWS)
	var legend: Dictionary = source.get("legend", {})
	for r: Variant in rows:
		var row: String = str(r)
		if row.length() != str(rows[0]).length() or row.length() > MAX_COLS:
			errors.append("rows must be equal in length, at most %d" % MAX_COLS)
			break
		for i: int in row.length():
			if not legend.has(row[i]):
				errors.append("glyph '%s' not in legend" % row[i])
				return


## True if a condition (chapter_min, chapter_max, flag, not_flag) holds. No condition always holds.
static func holds(cond: Variant, world: RefCounted) -> bool:
	if not (cond is Dictionary):
		return true
	var c: Dictionary = cond
	var chapter: int = int(world.get("chapter"))
	if c.has("chapter_min") and chapter < int(c["chapter_min"]):
		return false
	if c.has("chapter_max") and chapter > int(c["chapter_max"]):
		return false
	if c.has("flag") and not bool(world.call("get_flag", str(c["flag"]))):
		return false
	if c.has("not_flag") and bool(world.call("get_flag", str(c["not_flag"]))):
		return false
	return true


## The first variant whose condition holds, or an empty dictionary.
func variant(world: RefCounted) -> Dictionary:
	for v: Variant in data.get("variants", []):
		if holds((v as Dictionary).get("when"), world):
			return v
	return {}


func _section(world: RefCounted, key: String) -> Array:
	var v: Dictionary = variant(world)
	return v[key] if v.has(key) else data.get(key, [])


## The entries of one section (exits, things, encounters, ...) as the world sees them now.
func section(world: RefCounted, key: String) -> Array:
	return _section(world, key)


func rows(world: RefCounted) -> Array:
	return _section(world, "rows")


func width(world: RefCounted) -> int:
	var r: Array = rows(world)
	return 0 if r.is_empty() else str(r[0]).length()


func height(world: RefCounted) -> int:
	return rows(world).size()


func in_bounds(world: RefCounted, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width(world) and cell.y < height(world)


static func cell_of(value: Variant) -> Vector2i:
	var arr: Array = value
	return Vector2i(int(arr[0]), int(arr[1]))


## True if some party member has the trait.
static func party_has_trait(world: RefCounted, trait_id: String) -> bool:
	for p: String in world.get("party"):
		var s: RefCounted = world.call("sheet_of", p)
		if s != null and (s.get("traits") as Array).has(trait_id):
			return true
	return false


## The trait a cell demands, or an empty string.
func trait_needed(cell: Vector2i) -> String:
	for t: Variant in data.get("trait_access", []):
		if cell_of((t as Dictionary)["cell"]) == cell:
			return str((t as Dictionary)["trait"])
	return ""


func is_walkable(world: RefCounted, cell: Vector2i) -> bool:
	if not in_bounds(world, cell):
		return false
	var glyph: String = str(rows(world)[cell.y])[cell.x]
	var entry: Dictionary = (data.get("legend", {}) as Dictionary).get(glyph, {})
	if bool(entry.get("blocks", false)):
		return false
	var needed: String = trait_needed(cell)
	return needed == "" or party_has_trait(world, needed)


## Shortest path by breadth-first search over four neighbours, both ends included.
## Empty if the goal cannot be reached.
func find_path(world: RefCounted, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not is_walkable(world, from) or not is_walkable(world, to):
		return path
	var came: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size() and not came.has(to):
		var here: Vector2i = queue[head]
		head += 1
		for step: Vector2i in STEPS:
			var next: Vector2i = here + step
			if not came.has(next) and is_walkable(world, next):
				came[next] = here
				queue.append(next)
	if not came.has(to):
		return path
	var at: Vector2i = to
	while at != from:
		path.append(at)
		at = came[at]
	path.append(from)
	path.reverse()
	return path


## The exit at a cell whose condition holds: {to, to_cell}, or an empty dictionary.
func exit_at(world: RefCounted, cell: Vector2i) -> Dictionary:
	for e: Variant in _section(world, "exits"):
		var d: Dictionary = e
		if cell_of(d["cell"]) == cell and holds(d.get("when"), world):
			return {"to": str(d["to"]), "to_cell": cell_of(d["to_cell"])}
	return {}


## Moves the party to the exit's area by setting the world position. Returns the exit, or empty.
func take_exit(world: RefCounted, cell: Vector2i) -> Dictionary:
	var e: Dictionary = exit_at(world, cell)
	if not e.is_empty():
		var to_cell: Vector2i = e["to_cell"]
		world.set("position", {"area": e["to"], "x": to_cell.x, "y": to_cell.y})
	return e


## Things on show. A hidden thing shows only after Listen, and only if the party has its trait.
func visible_things(world: RefCounted, listened: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Variant in _section(world, "things"):
		var d: Dictionary = t
		if not holds(d.get("when"), world):
			continue
		if d.has("hidden") and not (listened and party_has_trait(world, str(d["hidden"]["trait"]))):
			continue
		out.append(d)
	return out


## The battle id met at a cell, or an empty string. Meeting is the caller's act: a thing
## is seen from afar, an encounter only when stepped on.
func encounter_at(world: RefCounted, cell: Vector2i) -> String:
	for e: Variant in data.get("encounters", []):
		var d: Dictionary = e
		if cell_of(d["cell"]) == cell and holds(d.get("when"), world):
			return str(d["battle"])
	return ""


## Encounters within sight (Chebyshev distance) of a cell, to be seen before they are met.
func encounters_seen(world: RefCounted, cell: Vector2i, sight: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for e: Variant in data.get("encounters", []):
		var c: Vector2i = cell_of((e as Dictionary)["cell"])
		if holds((e as Dictionary).get("when"), world) and maxi(absi(c.x - cell.x), absi(c.y - cell.y)) <= sight:
			out.append(c)
	return out


func is_dark() -> bool:
	return float(data.get("light", 1.0)) < DARK_BELOW


## A dark area can be walked only with a light.
func can_enter(has_light: bool) -> bool:
	return has_light or not is_dark()


## Canon rule 8: mariners weaken on land within a day. True if the person has the water-breather
## trait and has stood on land since day `since_day` for a day or more.
static func weakened_on_land(world: RefCounted, person: String, since_day: int) -> bool:
	var s: RefCounted = world.call("sheet_of", person)
	if s == null or not (s.get("traits") as Array).has(WATER_BREATHER):
		return false
	return int(world.get("day")) - since_day >= MARINER_DAYS_ON_LAND
