extends Control
## Dialogue panel: the person's portrait and name, their topics, and the panels an answer returns.
## It decides nothing: topics, news, names, answers and quest steps all come from the session.

signal closed

const ASSET_ROOT: String = "res://assets/"
const PANEL_SIZE: Vector2 = Vector2(624, 232)
const PORTRAIT_SIZE: Vector2 = Vector2(96, 96)
const ROW_HEIGHT: int = 48
const FONT_SIZE: int = 16
const MARK_SIZE: Vector2 = Vector2(24, 24)
const BODY_RECT: Rect2 = Rect2(116, 8, 500, 216)

var _session: RefCounted = null
var _person_id: String = ""
var _paths: Dictionary = {}
var _panels: Array = []
var _index: int = 0
var _portrait: TextureRect = null
var _name: Label = null
var _topics: ScrollContainer = null
var _rows: VBoxContainer = null
var _text: Label = null


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
	var portrait_frame: TextureRect = _picture("ui-portrait-frame")
	add_child(portrait_frame)
	_portrait = _picture("")
	add_child(_portrait)
	_name = Label.new()
	_name.position = Vector2(8, 108)
	_name.size = Vector2(PORTRAIT_SIZE.x, 28)
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.add_theme_font_size_override("font_size", FONT_SIZE)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	# Close sits under the name, outside the topic list, so it stays visible however many topics there are.
	var close: Button = Button.new()
	close.text = "Close"
	close.position = Vector2(8, PANEL_SIZE.y - 8 - ROW_HEIGHT)
	close.size = Vector2(PORTRAIT_SIZE.x, ROW_HEIGHT)
	close.add_theme_font_size_override("font_size", FONT_SIZE)
	close.pressed.connect(func() -> void: closed.emit())
	add_child(close)
	_topics = ScrollContainer.new()
	_topics.position = BODY_RECT.position
	_topics.size = BODY_RECT.size
	_topics.clip_contents = true
	_topics.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_topics)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 4)
	_topics.add_child(_rows)
	_text = Label.new()
	_text.position = BODY_RECT.position
	_text.size = BODY_RECT.size
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", FONT_SIZE)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_show_topics()


func _texture(key: String) -> Texture2D:
	if not _paths.has(key):
		return null
	return load(ASSET_ROOT + str(_paths[key])) as Texture2D


func _picture(key: String) -> TextureRect:
	var pic: TextureRect = TextureRect.new()
	pic.texture = _texture(key)
	pic.position = Vector2(8, 8)
	pic.size = PORTRAIT_SIZE
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pic


func _set_speaker(speaker: String, portrait: String) -> void:
	_name.text = speaker
	_portrait.texture = _texture(portrait)


func _show_topics() -> void:
	_panels = []
	_text.visible = false
	_topics.visible = true
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var talk: Dictionary = _session.call("talk", _person_id)
	if not bool(talk["ok"]):
		closed.emit()
		return
	_set_speaker(str(talk["name"]), str(talk["portrait"]))
	for entry: Dictionary in talk["topics"]:
		_add_topic(str(entry["topic"]), bool(entry["news"]))
	_topics.scroll_vertical = 0


func _add_topic(topic: String, news: bool) -> void:
	var row: Button = Button.new()
	row.text = str(_session.call("topic_label", topic))
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_SCALE
		mark.anchor_left = 1.0
		mark.anchor_right = 1.0
		mark.anchor_top = 0.5
		mark.anchor_bottom = 0.5
		mark.offset_left = -MARK_SIZE.x - 8
		mark.offset_right = -8
		mark.offset_top = -MARK_SIZE.y / 2
		mark.offset_bottom = MARK_SIZE.y / 2
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(mark)
	_rows.add_child(row)


## A topic the rules refuse, or one with nothing to say, leaves the player on the refreshed list.
func _on_topic(topic: String) -> void:
	var out: Dictionary = _session.call("ask", _person_id, topic)
	if not bool(out["ok"]) or (out["panels"] as Array).is_empty():
		_show_topics()
		return
	_panels = out["panels"]
	_index = 0
	_show_panel()


func _show_panel() -> void:
	var panel: Dictionary = _panels[_index]
	_set_speaker(str(panel["speaker"]), str(panel["portrait"]))
	_topics.visible = false
	_text.text = "\n".join(PackedStringArray(panel["lines"]))
	_text.visible = true


## A tap anywhere on the panel moves on: the next panel, or back to the topics after the last.
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var b: InputEventMouseButton = event
	if not b.pressed or b.button_index != MOUSE_BUTTON_LEFT or not _text.visible:
		return
	accept_event()
	_index += 1
	if _index < _panels.size():
		_show_panel()
	else:
		_show_topics()
