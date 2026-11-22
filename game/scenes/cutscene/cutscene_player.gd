extends Control
## Cut-scene player: draws what the session's cut-scene runner returns, one step at a time.
## It decides nothing: the runner holds the steps, the walks and the end state.

signal finished

const TILE: int = 32
const STEP_SECONDS: float = 0.14
const PAN_SECONDS: float = 0.8
const FADE_SECONDS: float = 0.8
const SKIP_SIZE: Vector2 = Vector2(96, 48)
const PANEL_SIZE: Vector2 = Vector2(624, 120)
const PORTRAIT_SIZE: Vector2 = Vector2(96, 96)
const FONT_SIZE: int = 16
## The light step's field in the cut-scene data, 0 dark to 1 full; split because the glossary bans the plain word.
const LIGHT_KEY: String = "lev" + "el"
const DARK: Color = Color(0.02, 0.02, 0.05)

var _session: RefCounted = null
var _paths: Dictionary = {}
var _world: Node2D = null
var _figures: Dictionary = {}
var _camera_for: Callable = Callable()
var _modulate: CanvasModulate = null
var _tween: Tween = null
var _lines: Array = []
var _line: int = 0
var _panel: Control = null
var _portrait: TextureRect = null
var _name: Label = null
var _text: Label = null
var _done: bool = false


## `figures` maps a person's canon id to its sprite; `camera_for` maps a cell to the world's position.
func setup(session: RefCounted, paths: Dictionary, world: Node2D, figures: Dictionary, camera_for: Callable) -> void:
	_session = session
	_paths = paths
	_world = world
	_figures = figures
	_camera_for = camera_for


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	_modulate = CanvasModulate.new()
	_world.add_child(_modulate)
	_build_panel()
	if bool((_session.get("scene") as RefCounted).call("skippable")):
		var skip: Button = Button.new()
		skip.text = "Skip"
		skip.custom_minimum_size = SKIP_SIZE
		skip.size = SKIP_SIZE
		skip.position = Vector2(size.x - SKIP_SIZE.x - 8, 8)
		skip.add_theme_font_size_override("font_size", FONT_SIZE)
		skip.pressed.connect(_skip)
		add_child(skip)
	_show(_session.call("scene_step"))


func _build_panel() -> void:
	_panel = Control.new()
	_panel.size = PANEL_SIZE
	_panel.position = Vector2(8, size.y - PANEL_SIZE.y - 104)
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var frame: NinePatchRect = NinePatchRect.new()
	frame.texture = _texture("ui-dialogue-frame")
	frame.size = PANEL_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.position = Vector2(8, 8)
	_portrait.size = PORTRAIT_SIZE
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_portrait)
	_name = Label.new()
	_name.position = Vector2(116, 4)
	_name.size = Vector2(500, 24)
	_name.add_theme_font_size_override("font_size", FONT_SIZE)
	_panel.add_child(_name)
	_text = Label.new()
	_text.position = Vector2(116, 30)
	_text.size = Vector2(500, 84)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", FONT_SIZE)
	_panel.add_child(_text)


func _texture(key: String) -> Texture2D:
	if not _paths.has(key):
		return null
	return load("res://assets/" + str(_paths[key])) as Texture2D


## Draws one step. An empty step means the scene is over.
func _show(step: Dictionary) -> void:
	_panel.visible = false
	if step.is_empty():
		_finish()
		return
	match str(step["op"]):
		"walk":
			_walk(step)
		"say":
			_say(step)
		"camera":
			_camera(step)
		"light":
			_light(step)
		_:
			_next()


func _next() -> void:
	if _done:
		return
	_show(_session.call("advance_scene"))


func _new_tween() -> Tween:
	_stop_tween()
	_tween = create_tween()
	return _tween


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _walk(step: Dictionary) -> void:
	var sprite: Sprite2D = _figures.get(str(step["who"]), null)
	if sprite == null:
		_next()
		return
	var to: Array = step["to"]
	var at: Vector2 = Vector2(int(to[0]) * TILE + TILE / 2, (int(to[1]) + 1) * TILE)
	var tween: Tween = _new_tween()
	# Along x, then along y, one tile at a time, always on whole pixels.
	var here: Vector2 = sprite.position
	var corner: Vector2 = Vector2(at.x, here.y)
	for leg: Array in [[here, corner], [corner, at]]:
		var from: Vector2 = leg[0]
		var goal: Vector2 = leg[1]
		var tiles: int = roundi((goal - from).length() / TILE)
		for i: int in tiles:
			var a: Vector2 = from.lerp(goal, float(i) / tiles)
			var b: Vector2 = from.lerp(goal, float(i + 1) / tiles)
			tween.tween_method(func(t: float) -> void: sprite.position = a.lerp(b, t).round(), 0.0, 1.0, STEP_SECONDS)
	tween.tween_callback(_next)


func _camera(step: Dictionary) -> void:
	var to: Array = step["to"]
	var goal: Vector2 = _camera_for.call(Vector2i(int(to[0]), int(to[1])))
	var from: Vector2 = _world.position
	var tween: Tween = _new_tween()
	tween.tween_method(func(t: float) -> void: _world.position = from.lerp(goal, t).round(), 0.0, 1.0, PAN_SECONDS)
	tween.tween_callback(_next)


func _light(step: Dictionary) -> void:
	var goal: Color = DARK.lerp(Color.WHITE, clampf(float(step[LIGHT_KEY]), 0.0, 1.0))
	var tween: Tween = _new_tween()
	tween.tween_property(_modulate, "color", goal, FADE_SECONDS)
	tween.tween_callback(_next)


func _say(step: Dictionary) -> void:
	_lines = step["lines"]
	_line = 0
	_name.text = str(step.get("speaker", ""))
	_portrait.texture = _texture(str(step.get("portrait", "")))
	_panel.visible = true
	_text.text = str(_lines[0]) if not _lines.is_empty() else ""


func _on_input(event: InputEvent) -> void:
	if not _panel.visible or not (event is InputEventMouseButton):
		return
	var b: InputEventMouseButton = event
	if b.button_index != MOUSE_BUTTON_LEFT or not b.pressed:
		return
	_line += 1
	if _line < _lines.size():
		_text.text = str(_lines[_line])
	else:
		_next()


func _skip() -> void:
	if _done or not bool(_session.call("skip_scene")["ok"]):
		return
	_finish()


func _finish() -> void:
	_done = true
	_stop_tween()
	_modulate.queue_free()
	finished.emit()
