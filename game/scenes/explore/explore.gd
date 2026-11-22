extends Control
## Exploring: draws the session's current area and sends the player's taps to the session.
## It decides nothing: paths, legality, exits and quests all come back from the rules.

const Holder: GDScript = preload("res://scenes/explore/session_holder.gd")

const TILE: int = 32
const VIEW: Vector2i = Vector2i(640, 256)
const BAND_HEIGHT: int = 96
const BUTTON_SIZE: Vector2 = Vector2(96, 48)
const STEP_SECONDS: float = 0.14
## A press becomes a hold after this long, or as soon as the finger leaves the tile it pressed.
const HOLD_SECONDS: float = 0.3
## Placeholder figure for a shop keeper, who has no person entry of their own.
const KEEPER_FIGURE: String = "figure-mariners"
const ASSET_ROOT: String = "res://assets/"
const TITLE: String = "res://scenes/title/title.tscn"
const DialoguePanel: GDScript = preload("res://ui/dialogue/dialogue_panel.gd")

var _session: RefCounted = null
var _frame: Control = null
var _view: Control = null
var _world: Node2D = null
var _layer: TileMapLayer = null
var _sprites: Node2D = null
var _party: Sprite2D = null
var _status: Label = null
var _paths: Dictionary = {}
var _drawn_area: String = ""
var _target: Vector2i = Vector2i.ZERO
## What a tap asked for at the end of the walk: {"kind": "thing"|"person"|"keeper", "id", "cell"}.
var _goal: Dictionary = {}
var _walking: bool = false
var _pressed: bool = false
var _holding: bool = false
var _press_tile: Vector2i = Vector2i.ZERO
var _press_time: float = 0.0
var _finger: Vector2 = Vector2.ZERO
var _clock: float = 0.0
var _dialogue: Control = null


func _ready() -> void:
	_session = Holder.session
	if _session == null:
		get_tree().change_scene_to_file.call_deferred(TITLE)
		return
	_load_manifest()
	_frame = Control.new()
	_frame.size = Vector2(VIEW.x, VIEW.y + BAND_HEIGHT)
	add_child(_frame)
	resized.connect(_centre_frame)
	_centre_frame()
	_build_view()
	_build_band()
	_redraw()


## Keeps the 640-pixel frame centred when the screen is wider or taller than the base size.
func _centre_frame() -> void:
	_frame.position = Vector2(floori(maxf(size.x - _frame.size.x, 0.0) / 2.0), floori(maxf(size.y - _frame.size.y, 0.0) / 2.0))


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
	_frame.add_child(_view)
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
	_frame.add_child(band)
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(8, VIEW.y + 44)
	row.size = Vector2(VIEW.x - 16, BUTTON_SIZE.y)
	row.add_theme_constant_override("separation", 8)
	_frame.add_child(row)
	for name: String in ["Journal", "Party", "Pack"]:
		_add_button(row, name).disabled = true
	_add_button(row, "Rest").pressed.connect(_on_rest)
	_add_button(row, "Title").pressed.connect(_on_title)
	_status = Label.new()
	_status.position = Vector2(8, VIEW.y + 8)
	_status.size = Vector2(VIEW.x - 16, 32)
	_frame.add_child(_status)


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
	for who: Dictionary in _session.call("people_here"):
		_place(_figure_of(who), who["cell"])
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


## A sprite standing on `cell`: its origin is the centre of the tile's lower edge and the picture
## rises from there, whatever its size, so the y-sort orders figures and things by the row they stand on.
func _place(tex: Texture2D, cell: Vector2i) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(cell.x * TILE + TILE / 2, (cell.y + 1) * TILE)
	if tex != null:
		s.offset = Vector2(-floori(tex.get_width() / 2.0), -tex.get_height())
	_sprites.add_child(s)
	return s


## A person's figure follows their portrait's people ("portrait-hero" stands as "figure-hero").
func _figure_of(who: Dictionary) -> Texture2D:
	var key: String = str(who.get("portrait", "")).replace("portrait-", "figure-")
	var tex: Texture2D = _texture(key)
	return tex if tex != null else _texture(KEEPER_FIGURE)


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
	if _dialogue != null:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var b: InputEventMouseButton = event
		_pressed = b.pressed
		_holding = false
		_finger = b.position
		if b.pressed:
			_press_tile = _tile_at(b.position)
			_press_time = 0.0
			_aim(_press_tile)
	elif event is InputEventMouseMotion and _pressed:
		_finger = (event as InputEventMouseMotion).position


## Takes a pressed tile as the new goal; a tap on a thing or a person means walk up and use or talk.
func _aim(tile: Vector2i) -> void:
	_target = tile
	_goal = {}
	var area: RefCounted = _session.call("current_area")
	for thing: Dictionary in area.call("visible_things", _session.get("world"), false):
		if area.call("cell_of", thing["cell"]) == tile:
			_goal = {"kind": "thing", "id": str(thing["id"]), "cell": tile}
	for who: Dictionary in _session.call("people_here"):
		if who["cell"] == tile:
			_goal = {"kind": str(who["kind"]), "id": str(who["id"]), "cell": tile}
	_walking = true
	_clock = STEP_SECONDS


func _process(delta: float) -> void:
	if _session == null:
		return
	if _pressed and not _holding:
		_press_time += delta
		_holding = _press_time >= HOLD_SECONDS or _tile_at(_finger) != _press_tile
	if _holding:
		_target = _tile_at(_finger)
		_goal = {}
		_walking = true
	if not _walking:
		return
	_clock += delta
	if _clock < STEP_SECONDS:
		return
	_clock = 0.0
	_walk_one()


func _walk_one() -> void:
	var here: Vector2i = _session.call("cell")
	if not _goal.is_empty():
		var gap: Vector2i = (here - (_goal["cell"] as Vector2i)).abs()
		if gap.x + gap.y <= 1:
			_act(_goal)
			_goal = {}
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
		_pressed = false
		_holding = false
		_goal = {}
	_redraw()


## Sends the tapped goal to the session. The dialogue and stall screens are later issues; until
## then the band's status line shows what came back.
func _act(goal: Dictionary) -> void:
	var id: String = str(goal["id"])
	match str(goal["kind"]):
		"thing":
			_status.text = _gave_text(_session.call("use_thing", id))
			_redraw()
		"person":
			if bool(_session.call("talk", id)["ok"]):
				_open_dialogue(id)
		"keeper":
			var offers: Array[Dictionary] = _session.call("trades", id)
			_status.text = "Stall: %d trades" % offers.size()


func _open_dialogue(person_id: String) -> void:
	_dialogue = DialoguePanel.new()
	_dialogue.call("setup", _session, person_id, _paths)
	_dialogue.position = Vector2(8, 8)
	_dialogue.closed.connect(_close_dialogue)
	_frame.add_child(_dialogue)
	_pressed = false
	_holding = false


func _close_dialogue() -> void:
	_dialogue.queue_free()
	_dialogue = null
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
