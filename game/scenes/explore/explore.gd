extends Control
## Exploring: draws the session's current area and sends the player's taps to the session.
## It decides nothing: paths, legality, exits and quests all come back from the rules.

const Holder: GDScript = preload("res://scenes/explore/session_holder.gd")

const TILE: int = 32
const VIEW: Vector2i = Vector2i(640, 256)
const BAND_HEIGHT: int = 96
const BUTTON_SIZE: Vector2 = Vector2(96, 48)
const STEP_SECONDS: float = 0.14
const FIGURE_SIZE: Vector2i = Vector2i(32, 48)
const ASSET_ROOT: String = "res://assets/"
const TITLE: String = "res://scenes/title/title.tscn"

var _session: RefCounted = null
var _view: Control = null
var _world: Node2D = null
var _layer: TileMapLayer = null
var _sprites: Node2D = null
var _party: Sprite2D = null
var _status: Label = null
var _paths: Dictionary = {}
var _drawn_area: String = ""
var _target: Vector2i = Vector2i.ZERO
var _thing_id: String = ""
var _thing_cell: Vector2i = Vector2i.ZERO
var _walking: bool = false
var _holding: bool = false
var _finger: Vector2 = Vector2.ZERO
var _clock: float = 0.0


func _ready() -> void:
	_session = Holder.session
	if _session == null:
		get_tree().change_scene_to_file.call_deferred(TITLE)
		return
	_load_manifest()
	_build_view()
	_build_band()
	_redraw()


func _load_manifest() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSET_ROOT + "manifest.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for entry: Variant in (parsed as Dictionary).get("assets", []):
		var path: String = str((entry as Dictionary).get("path", ""))
		_paths[path.get_file().get_basename()] = path


func _texture(key: String) -> Texture2D:
	if not _paths.has(key):
		return null
	return load(ASSET_ROOT + str(_paths[key])) as Texture2D


func _build_view() -> void:
	_view = Control.new()
	_view.position = Vector2.ZERO
	_view.size = Vector2(VIEW)
	_view.clip_contents = true
	_view.gui_input.connect(_on_view_input)
	add_child(_view)
	_world = Node2D.new()
	_view.add_child(_world)
	_layer = TileMapLayer.new()
	_world.add_child(_layer)
	_sprites = Node2D.new()
	_sprites.y_sort_enabled = true
	_world.add_child(_sprites)


func _build_band() -> void:
	var band: TextureRect = TextureRect.new()
	band.texture = _texture("ui-menu-band")
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.position = Vector2(0, VIEW.y)
	band.size = Vector2(VIEW.x, BAND_HEIGHT)
	add_child(band)
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(8, VIEW.y + 44)
	row.size = Vector2(VIEW.x - 16, BUTTON_SIZE.y)
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	for name: String in ["Journal", "Party", "Pack"]:
		_add_button(row, name).disabled = true
	_add_button(row, "Rest").pressed.connect(_on_rest)
	_add_button(row, "Title").pressed.connect(_on_title)
	_status = Label.new()
	_status.position = Vector2(8, VIEW.y + 8)
	_status.size = Vector2(VIEW.x - 16, 32)
	add_child(_status)


func _add_button(row: HBoxContainer, text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = BUTTON_SIZE
	row.add_child(b)
	return b


## Rebuilds the tiles and the sprites from the session. Cheap enough to run on every change.
func _redraw() -> void:
	var area: RefCounted = _session.call("current_area")
	if area == null:
		return
	var world: RefCounted = _session.get("world")
	if _drawn_area != str(_session.call("area_id")):
		_drawn_area = str(_session.call("area_id"))
		_build_tiles(area, world)
	for child: Node in _sprites.get_children():
		child.queue_free()
	for thing: Dictionary in area.call("visible_things", world, false):
		var cell: Vector2i = area.call("cell_of", thing["cell"])
		_place(_texture("thing-supply"), cell)
	_party = _place(_texture("figure-hero"), _session.call("cell"))
	_follow()


func _build_tiles(area: RefCounted, world: RefCounted) -> void:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var legend: Dictionary = (area.get("data") as Dictionary).get("legend", {})
	var source_of: Dictionary = {}
	for glyph: Variant in legend:
		var key: String = str((legend[glyph] as Dictionary).get("tile", ""))
		var tex: Texture2D = _texture(key)
		if tex == null or source_of.has(key):
			continue
		var source: TileSetAtlasSource = TileSetAtlasSource.new()
		source.texture = tex
		source.texture_region_size = Vector2i(TILE, TILE)
		source.create_tile(Vector2i.ZERO)
		source_of[key] = tile_set.add_source(source)
	_layer.tile_set = tile_set
	_layer.clear()
	var rows: Array = area.call("rows", world)
	for y: int in rows.size():
		var line: String = str(rows[y])
		for x: int in line.length():
			var entry: Dictionary = legend.get(line[x], {})
			var key: String = str(entry.get("tile", ""))
			if source_of.has(key):
				_layer.set_cell(Vector2i(x, y), int(source_of[key]), Vector2i.ZERO)


## A 32x48 figure standing on `cell`, its feet at the tile's lower edge.
func _place(tex: Texture2D, cell: Vector2i) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(cell.x * TILE, (cell.y + 1) * TILE - FIGURE_SIZE.y)
	s.z_index = cell.y
	_sprites.add_child(s)
	return s


## Camera: whole pixels, centred on the party, clamped to the area (centred if it is smaller).
func _follow() -> void:
	var area: RefCounted = _session.call("current_area")
	var world: RefCounted = _session.get("world")
	var size: Vector2i = Vector2i(int(area.call("width", world)), int(area.call("height", world))) * TILE
	var cell: Vector2i = _session.call("cell")
	var at: Vector2i = cell * TILE + Vector2i(TILE / 2, TILE / 2)
	var cam: Vector2i = Vector2i.ZERO
	for axis: int in 2:
		if size[axis] <= VIEW[axis]:
			cam[axis] = (size[axis] - VIEW[axis]) / 2
		else:
			cam[axis] = clampi(at[axis] - VIEW[axis] / 2, 0, size[axis] - VIEW[axis])
	_world.position = Vector2(-cam)


func _tile_at(local: Vector2) -> Vector2i:
	var p: Vector2 = local - _world.position
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var b: InputEventMouseButton = event
		_holding = b.pressed
		if b.pressed:
			_finger = b.position
			_aim(_tile_at(b.position))
	elif event is InputEventMouseMotion and _holding:
		_finger = (event as InputEventMouseMotion).position


## Takes a tapped tile as the new goal; a tap on a thing means to walk up and use it.
func _aim(tile: Vector2i) -> void:
	_target = tile
	_thing_id = ""
	var area: RefCounted = _session.call("current_area")
	for thing: Dictionary in area.call("visible_things", _session.get("world"), false):
		if area.call("cell_of", thing["cell"]) == tile:
			_thing_id = str(thing["id"])
			_thing_cell = tile
	_walking = true
	_clock = STEP_SECONDS


func _process(delta: float) -> void:
	if _session == null or not _walking:
		return
	_clock += delta
	if _clock < STEP_SECONDS:
		return
	_clock = 0.0
	if _holding:
		_target = _tile_at(_finger)
		_thing_id = ""
	_walk_one()


func _walk_one() -> void:
	var here: Vector2i = _session.call("cell")
	if _thing_id != "" and (here - _thing_cell).abs().x + (here - _thing_cell).abs().y <= 1:
		var used: Dictionary = _session.call("use_thing", _thing_id)
		_status.text = _gave_text(used)
		_walking = false
		return
	var path: Array[Vector2i] = _session.call("path_to", _target)
	if path.size() < 2:
		_walking = _holding
		return
	var out: Dictionary = _session.call("step_to", path[1])
	if not bool(out["ok"]):
		_walking = false
		return
	if not (out["exit"] as Dictionary).is_empty():
		_walking = false
		_holding = false
	_redraw()


func _gave_text(used: Dictionary) -> String:
	var gave: Dictionary = used["gave"]
	if not bool(used["ok"]) or gave.is_empty():
		return ""
	return "Got %s x%d" % [str(gave.get("item", "")), int(gave.get("count", 1))]


func _on_rest() -> void:
	var out: Dictionary = _session.call("rest")
	_status.text = "Day %d" % int(out["day"]) if bool(out["ok"]) else "No rest here."


func _on_title() -> void:
	get_tree().change_scene_to_file(TITLE)
