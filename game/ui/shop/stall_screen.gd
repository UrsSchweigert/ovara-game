extends "res://ui/screens/screen_base.gd"
## A stall: each trade is a row showing what is given and what is wanted. A tap selects a row; the
## separate Confirm button makes the trade through the session. Rows the party cannot pay are grey.

const ICON: Vector2 = Vector2(32, 32)
const GREY: Color = Color(0.5, 0.5, 0.5, 1.0)
const SELECTED: Color = Color(0.35, 0.3, 0.15, 1.0)

var _shop_id: String = ""
var _paths: Dictionary = {}
var _role: String = ""
var _selected: int = -1
var _result: Label = null
var _confirm: Button = null
var _view: Dictionary = {}


func open(session: RefCounted, shop_id: String, paths: Dictionary) -> void:
	_session = session
	_shop_id = shop_id
	_paths = paths
	_role = str((session.call("stall_view", shop_id) as Dictionary).get("role", ""))


func _title() -> String:
	return label_of(_role)


func _fill() -> void:
	if _confirm == null:
		_confirm = Button.new()
		_confirm.text = "Confirm"
		_confirm.size = Vector2(120, ROW_HEIGHT)
		_confirm.position = Vector2(SCREEN_SIZE.x - 12 - 240 - 12, SCREEN_SIZE.y - 6 - ROW_HEIGHT)
		_confirm.add_theme_font_size_override("font_size", FONT_SIZE)
		_confirm.pressed.connect(_on_confirm)
		add_child(_confirm)
		_result = Label.new()
		_result.position = Vector2(12, SCREEN_SIZE.y - 6 - ROW_HEIGHT + 8)
		_result.size = Vector2(SCREEN_SIZE.x - 288, 28)
		_result.add_theme_font_size_override("font_size", FONT_SIZE)
		add_child(_result)
	_view = _session.call("stall_view", _shop_id)
	for child: Node in _body.get_children():
		child.queue_free()
	var trades: Array = _view["trades"]
	if trades.is_empty():
		_line("Nothing to trade.")
	for t: Dictionary in trades:
		_body.add_child(_row(t))
	_confirm.disabled = not _can_confirm()


func _can_confirm() -> bool:
	for t: Dictionary in _view["trades"]:
		if int(t["index"]) == _selected:
			return bool(t["affordable"])
	return false


func _row(t: Dictionary) -> Control:
	var index: int = int(t["index"])
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(_body.custom_minimum_size.x, ROW_HEIGHT + 8)
	b.toggle_mode = false
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = SELECTED if index == _selected else Color(0.16, 0.16, 0.22, 1.0)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, box)
	if not bool(t["affordable"]):
		b.modulate = GREY
	b.pressed.connect(_on_select.bind(index))
	var line: HBoxContainer = HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.position = Vector2(8, 4)
	line.size = Vector2(b.custom_minimum_size.x - 16, ROW_HEIGHT)
	b.add_child(line)
	_stacks(line, t["gives"], false)
	_text(line, "  for  ")
	_stacks(line, t["wants"], true)
	return b


func _stacks(line: HBoxContainer, stacks: Array, with_have: bool) -> void:
	for s: Dictionary in stacks:
		var icon: Texture2D = _icon(str(s["slot"]))
		if icon != null:
			var r: TextureRect = TextureRect.new()
			r.texture = icon
			r.custom_minimum_size = ICON
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.add_child(r)
		var text: String = " %s x%d" % [label_of(str(s["item"])), int(s["count"])]
		if with_have:
			text += " (have %d)" % int(s["have"])
		_text(line, text + "  ")


func _text(line: HBoxContainer, text: String) -> void:
	var l: Label = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	line.add_child(l)


func _icon(slot: String) -> Texture2D:
	for key: String in ["thing-" + slot, "thing-supply"]:
		if _paths.has(key):
			return load("res://assets/" + str(_paths[key])) as Texture2D
	return null


func _on_select(index: int) -> void:
	_selected = index
	_result.text = ""
	_fill()


func _on_confirm() -> void:
	if not _can_confirm():
		return
	var out: Dictionary = _session.call("trade", _shop_id, _selected)
	_result.text = "Traded." if bool(out["ok"]) else str(out["error"])
	_fill()
