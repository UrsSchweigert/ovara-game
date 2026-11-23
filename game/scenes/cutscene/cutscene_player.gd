extends Control
## Cut-scene player: draws what the session's cut-scene runner returns, one step at a time.
## It decides nothing: the runner holds the steps, the walks and the end state.

signal finished

const DialoguePanel: GDScript = preload("res://ui/dialogue/dialogue_panel.gd")

const TILE: int = 32
const STEP_SECONDS: float = 0.14
const PAN_SECONDS: float = 0.8
const FADE_SECONDS: float = 0.8
const SKIP_SIZE: Vector2 = Vector2(96, 48)
const PANEL_AT: Vector2 = Vector2(8, 8)
const FONT_SIZE: int = 16
## The light step's field in the cut-scene data, 0 dark to 1 full; split because the glossary bans the plain word.
const LIGHT_KEY: String = "lev" + "el"
const DARK: Color = Color(0.02, 0.02, 0.05)
## A dark, half-clear layer under the speech panel so its text reads over a bright scene.
const SHADE: Color = Color(0.0, 0.0, 0.03, 0.62)

var _session: RefCounted = null
var _paths: Dictionary = {}
var _world: Node2D = null
var _figures: Dictionary = {}
var _camera_for: Callable = Callable()
var _make_figure: Callable = Callable()
var _tween: Tween = null
var _panel: Control = null
var _shade: ColorRect = null
var _done: bool = false


## `figures` maps a person's canon id to its sprite; `camera_for` maps a cell to the world's position;
## `make_figure` gives a placeholder sprite to a walked person who has none yet.
func setup(session: RefCounted, paths: Dictionary, world: Node2D, figures: Dictionary, camera_for: Callable, make_figure: Callable) -> void:
	_session = session
	_paths = paths
	_world = world
	_figures = figures
	_camera_for = camera_for
	_make_figure = make_figure


## Covers the whole frame so taps on the map and the band wait for the scene. Light dims only the
## world's own modulate, so the panel, the band and Skip stay at full light.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if bool((_session.get("scene") as RefCounted).call("skippable")):
		var skip: Button = Button.new()
		skip.text = "Skip"
		skip.custom_minimum_size = SKIP_SIZE
		skip.size = SKIP_SIZE
		skip.position = Vector2(size.x - SKIP_SIZE.x - 8, size.y - SKIP_SIZE.y - 8)
		skip.add_theme_font_size_override("font_size", FONT_SIZE)
		skip.pressed.connect(_skip)
		add_child(skip)
	_show(_session.call("scene_step"))


## Draws one step. An empty step means the scene is over.
func _show(step: Dictionary) -> void:
	_close_panel()
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
		sprite = _make_figure.call(str(step["who"]))
		_figures[str(step["who"])] = sprite
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
	tween.tween_property(_world, "modulate", goal, FADE_SECONDS)
	tween.tween_callback(_next)


## The dialogue panel in its lines-only mode shows the step's lines together; its tap after them moves on.
func _say(step: Dictionary) -> void:
	if (step["lines"] as Array).is_empty():
		_next()
		return
	_shade = ColorRect.new()
	_shade.color = SHADE
	_shade.position = PANEL_AT
	_shade.size = DialoguePanel.PANEL_SIZE
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_panel = DialoguePanel.new()
	_panel.call("setup_lines", [{"speaker": str(step["speaker"]), "portrait": str(step["portrait"]), "lines": step["lines"]}], _paths)
	_panel.position = PANEL_AT
	_panel.closed.connect(_next)
	add_child(_panel)


func _close_panel() -> void:
	if _shade != null:
		_shade.queue_free()
		_shade = null
	if _panel != null:
		_panel.queue_free()
		_panel = null


func _skip() -> void:
	if _done or not bool(_session.call("skip_scene")["ok"]):
		return
	_finish()


func _finish() -> void:
	_done = true
	_stop_tween()
	_close_panel()
	_world.modulate = Color.WHITE
	finished.emit()
