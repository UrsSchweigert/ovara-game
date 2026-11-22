extends Control
## Dialogue panel: the person's portrait and name, their topics, and the panels an answer returns.
## It decides nothing: topics, news, answers and quest steps all come from the session.

signal closed

const ASSET_ROOT: String = "res://assets/"
const PANEL_SIZE: Vector2 = Vector2(624, 232)
const PORTRAIT_SIZE: Vector2 = Vector2(96, 96)
const ROW_HEIGHT: int = 48
const FONT_SIZE: int = 16
const MARK_SIZE: Vector2 = Vector2(24, 24)

var _session: RefCounted = null
var _person_id: String = ""
var _paths: Dictionary = {}
var _panels: Array = []
var _index: int = 0
var _portrait: TextureRect = null
var _name: Label = null
var _body: VBoxContainer = null


## Opens on `person_id`'s topic list. `paths` maps an asset key to its manifest path.
func setup(session: RefCounted, person_id: String, paths: Dictionary) -> void:
	_session = session
	_person_id = person_id
	_paths = paths


func _ready() -> void:
	size = PANEL_SIZE
	var frame: NinePatchRect = NinePatchRect.new()
	frame.texture = _texture("ui-dialogue-frame")
	frame.size = PANEL_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var portrait_frame: TextureRect = TextureRect.new()
	portrait_frame.texture = _texture("ui-portrait-frame")
	portrait_frame.position = Vector2(8, 8)
	portrait_frame.size = PORTRAIT_SIZE
	portrait_frame.stretch_mode = TextureRect.STRETCH_SCALE
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait_frame)
	_portrait = TextureRect.new()
	_portrait.position = Vector2(8, 8)
	_portrait.size = PORTRAIT_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_name = Label.new()
	_name.position = Vector2(8, 108)
	_name.size = Vector2(PORTRAIT_SIZE.x, 28)
	_name.add_theme_font_size_override("font_size", FONT_SIZE)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_body = VBoxContainer.new()
	_body.position = Vector2(116, 8)
	_body.size = Vector2(PANEL_SIZE.x - 124, PANEL_SIZE.y - 16)
	_body.add_theme_constant_override("separation", 4)
	add_child(_body)
	_show_topics()


func _texture(key: String) -> Texture2D:
	if not _paths.has(key):
		return null
	return load(ASSET_ROOT + str(_paths[key])) as Texture2D


func _set_speaker(speaker: String, portrait: String) -> void:
	_name.text = speaker
	_portrait.texture = _texture(portrait)


func _clear_body() -> void:
	for child: Node in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


func _show_topics() -> void:
	_panels = []
	_clear_body()
	var talk: Dictionary = _session.call("talk", _person_id)
	if not bool(talk["ok"]):
		closed.emit()
		return
	_set_speaker(str(talk["name"]), str(talk["portrait"]))
	for entry: Dictionary in talk["topics"]:
		_add_topic(str(entry["topic"]), bool(entry["news"]))
	var close: Button = Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(96, ROW_HEIGHT)
	close.add_theme_font_size_override("font_size", FONT_SIZE)
	close.pressed.connect(func() -> void: closed.emit())
	_body.add_child(close)


func _add_topic(topic: String, news: bool) -> void:
	var row: Button = Button.new()
	row.text = topic.replace("_", " ").replace("-", " ").capitalize()
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.add_theme_font_size_override("font_size", FONT_SIZE)
	var row_tex: Texture2D = _texture("ui-topic-row")
	if row_tex != null:
		var box: StyleBoxTexture = StyleBoxTexture.new()
		box.texture = row_tex
		for state: String in ["normal", "hover", "pressed", "focus"]:
			row.add_theme_stylebox_override(state, box)
	row.pressed.connect(_on_topic.bind(topic))
	if news:
		var mark: TextureRect = TextureRect.new()
		mark.texture = _texture("ui-speaking-mark")
		mark.stretch_mode = TextureRect.STRETCH_SCALE
		mark.size = MARK_SIZE
		mark.position = Vector2(_body.size.x - MARK_SIZE.x - 8, (ROW_HEIGHT - MARK_SIZE.y) / 2)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(mark)
	_body.add_child(row)


func _on_topic(topic: String) -> void:
	var out: Dictionary = _session.call("ask", _person_id, topic)
	if not bool(out["ok"]) or (out["panels"] as Array).is_empty():
		_show_text(str(out["error"]))
		_panels = []
		return
	_panels = out["panels"]
	_index = 0
	_show_panel()


func _show_panel() -> void:
	var panel: Dictionary = _panels[_index]
	_set_speaker(str(panel["speaker"]), str(panel["portrait"]))
	_show_text("\n".join(PackedStringArray(panel["lines"])))


func _show_text(text: String) -> void:
	_clear_body()
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(_body.size.x, 0)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(label)


## A tap anywhere on the panel moves on: the next panel, or back to the topics after the last.
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or not (event as InputEventMouseButton).pressed:
		return
	if _body.get_child_count() == 0 or _body.get_child(0) is Button:
		return
	accept_event()
	_index += 1
	if _index < _panels.size():
		_show_panel()
	else:
		_show_topics()
