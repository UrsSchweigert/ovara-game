extends RefCounted
## Draws one area as text for ./ov map: the grid with people, things, exits, encounters and
## trait cells marked over the tiles, then the lists behind the marks. Read-only: it asks the
## rules and changes nothing, so the same area and world always give the same text.

const Area: GDScript = preload("res://rules/area.gd")
const KEY: String = "P person  T thing  > exit  ! encounter  ~ needs a trait  ? hidden thing (listened)"


## The whole area as text, with a line break after every line.
static func render(area: RefCounted, world: RefCounted, listened: bool) -> String:
	var lines: Array[String] = [_header(area, world)]
	var marks: Dictionary = _marks(area, world, listened)
	var rows: Array = area.rows(world)
	for y: int in area.height(world):
		var row: String = str(rows[y])
		var line: String = ""
		for x: int in row.length():
			var glyph: String = marks.get(Vector2i(x, y), row.substr(x, 1))
			line += glyph
		lines.append(line)
	lines.append("")
	lines.append(KEY)
	lines.append("")
	lines.append_array(_legend(area))
	lines.append_array(_block("spawn", _spawn(area)))
	lines.append_array(_block("exits", _exits(area, world)))
	lines.append_array(_block("things", _things(area, world, listened)))
	lines.append_array(_block("people", _people(area, world)))
	lines.append_array(_block("encounters", _encounters(area, world)))
	lines.append_array(_block("trait access", _trait_access(area, world)))
	return "\n".join(lines) + "\n"


static func _header(area: RefCounted, world: RefCounted) -> String:
	var text: String = "%s  %s  %dx%d  light %.1f" % [
		area.id, str(area.data.get("name", "")), area.width(world), area.height(world),
		float(area.data.get("light", 1.0)),
	]
	return text + ("  dark" if area.is_dark() else "")


## One glyph per line: how the legend says it behaves.
static func _legend(area: RefCounted) -> Array[String]:
	var out: Array[String] = ["legend"]
	var legend: Dictionary = area.data.get("legend", {})
	var glyphs: Array = legend.keys()
	glyphs.sort()
	for glyph: Variant in glyphs:
		var entry: Dictionary = legend[glyph]
		out.append("  %s  %s" % [glyph, "blocks" if bool(entry.get("blocks", false)) else "open"])
	return out


## Overlay glyph per cell. The first mark on a cell wins, in the order people, things, exits,
## encounters, trait cells. A hidden thing is marked ? only when the party has listened.
static func _marks(area: RefCounted, world: RefCounted, listened: bool) -> Dictionary:
	var marks: Dictionary = {}
	for d: Dictionary in _active(area, world, "people"):
		_mark(marks, _cell(d), "P")
	var plain: Array[Dictionary] = area.visible_things(world, false)
	for t: Dictionary in area.visible_things(world, listened):
		_mark(marks, _cell(t), "T" if plain.has(t) else "?")
	for d: Dictionary in _active(area, world, "exits"):
		_mark(marks, _cell(d), ">")
	for d: Dictionary in _active(area, world, "encounters"):
		_mark(marks, _cell(d), "!")
	for d: Dictionary in _active(area, world, "trait_access"):
		_mark(marks, _cell(d), "~")
	return marks


static func _mark(marks: Dictionary, cell: Vector2i, glyph: String) -> void:
	if not marks.has(cell):
		marks[cell] = glyph


## The entries of a section whose condition holds now, as dictionaries.
static func _active(area: RefCounted, world: RefCounted, key: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d: Variant in area.section(world, key):
		var entry: Dictionary = d
		if Area.holds(entry.get("when"), world):
			out.append(entry)
	return out


static func _spawn(area: RefCounted) -> Array[String]:
	var out: Array[String] = []
	if area.data.has("spawn"):
		out.append(_at(Area.cell_of(area.data["spawn"])))
	return out


static func _exits(area: RefCounted, world: RefCounted) -> Array[String]:
	var items: Array[Dictionary] = []
	for d: Dictionary in _active(area, world, "exits"):
		var text: String = "%s -> %s at %s%s" % [
			_at(_cell(d)), d["to"], _at(Area.cell_of(d["to_cell"])), _when(d),
		]
		items.append({"cell": _cell(d), "id": str(d["to"]), "text": text})
	return _lines(items)


static func _things(area: RefCounted, world: RefCounted, listened: bool) -> Array[String]:
	var items: Array[Dictionary] = []
	for t: Dictionary in area.visible_things(world, listened):
		var hidden: String = " hidden: %s" % t["hidden"]["trait"] if t.has("hidden") else ""
		var text: String = "%s %s canon %s%s%s" % [t["id"], _at(_cell(t)), t["canon"], hidden, _when(t)]
		items.append({"cell": _cell(t), "id": str(t["id"]), "text": text})
	return _lines(items)


static func _people(area: RefCounted, world: RefCounted) -> Array[String]:
	var items: Array[Dictionary] = []
	for d: Dictionary in _active(area, world, "people"):
		items.append({"cell": _cell(d), "id": str(d["id"]), "text": "%s %s" % [d["id"], _at(_cell(d))]})
	return _lines(items)


static func _encounters(area: RefCounted, world: RefCounted) -> Array[String]:
	var items: Array[Dictionary] = []
	for d: Dictionary in _active(area, world, "encounters"):
		var text: String = "%s %s%s" % [_at(_cell(d)), d["battle"], _when(d)]
		items.append({"cell": _cell(d), "id": str(d["battle"]), "text": text})
	return _lines(items)


static func _trait_access(area: RefCounted, world: RefCounted) -> Array[String]:
	var items: Array[Dictionary] = []
	for d: Dictionary in _active(area, world, "trait_access"):
		var text: String = "%s %s" % [_at(_cell(d)), d["trait"]]
		items.append({"cell": _cell(d), "id": str(d["trait"]), "text": text})
	return _lines(items)


## A heading, then its entries indented, or "none" when there are none.
static func _block(title: String, entries: Array[String]) -> Array[String]:
	var out: Array[String] = [title]
	if entries.is_empty():
		out.append("  none")
	for e: String in entries:
		out.append("  " + e)
	return out


## The item texts, sorted by row, then column, then id, then text.
static func _lines(items: Array[Dictionary]) -> Array[String]:
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _before(a, b))
	var out: Array[String] = []
	for item: Dictionary in items:
		out.append(str(item["text"]))
	return out


static func _before(a: Dictionary, b: Dictionary) -> bool:
	var ca: Vector2i = a["cell"]
	var cb: Vector2i = b["cell"]
	if ca.y != cb.y:
		return ca.y < cb.y
	if ca.x != cb.x:
		return ca.x < cb.x
	if a["id"] != b["id"]:
		return str(a["id"]) < str(b["id"])
	return str(a["text"]) < str(b["text"])


static func _cell(d: Dictionary) -> Vector2i:
	return Area.cell_of(d["cell"])


static func _at(cell: Vector2i) -> String:
	return "(%d,%d)" % [cell.x, cell.y]


static func _when(d: Dictionary) -> String:
	return "  when %s" % JSON.stringify(d["when"]) if d.has("when") else ""
