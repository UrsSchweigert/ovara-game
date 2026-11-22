extends Control
## Base of the journal, party and pack screens: a title, a scrolling body and a Close button in the
## bottom right, where a thumb rests. It draws what the session's views give; it decides nothing.

signal closed

const SCREEN_SIZE: Vector2 = Vector2(640, 360)
const ROW_HEIGHT: int = 44
const FONT_SIZE: int = 16
const PIP_FULL: String = "●"
const PIP_EMPTY: String = "○"
const PIPS: int = 5

var _session: RefCounted = null
var _body: VBoxContainer = null


func setup(session: RefCounted) -> void:
	_session = session


func _ready() -> void:
	size = SCREEN_SIZE
	var back: ColorRect = ColorRect.new()
	back.color = Color(0.1, 0.1, 0.14, 1.0)
	back.size = SCREEN_SIZE
	add_child(back)
	var title: Label = Label.new()
	title.text = _title()
	title.position = Vector2(12, 8)
	title.add_theme_font_size_override("font_size", FONT_SIZE + 4)
	add_child(title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.position = Vector2(12, 44)
	scroll.size = Vector2(SCREEN_SIZE.x - 24, SCREEN_SIZE.y - 44 - ROW_HEIGHT - 12)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_body = VBoxContainer.new()
	_body.custom_minimum_size = Vector2(scroll.size.x - 8, 0)
	scroll.add_child(_body)
	var close: Button = Button.new()
	close.text = "Close"
	close.size = Vector2(120, ROW_HEIGHT)
	close.position = Vector2(SCREEN_SIZE.x - 12 - close.size.x, SCREEN_SIZE.y - 6 - ROW_HEIGHT)
	close.add_theme_font_size_override("font_size", FONT_SIZE)
	close.pressed.connect(func() -> void: closed.emit())
	add_child(close)
	_fill()


func _title() -> String:
	return ""


func _fill() -> void:
	pass


func _line(text: String, size_px: int = FONT_SIZE) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(_body.custom_minimum_size.x, 24)
	l.add_theme_font_size_override("font_size", size_px)
	_body.add_child(l)
	return l


func _heading(text: String) -> void:
	_line(text, FONT_SIZE + 2).add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))


## Five pips for a skill: a step is 0 to 5.
static func pips(step: int) -> String:
	var out: String = ""
	for i: int in PIPS:
		out += PIP_FULL if i < step else PIP_EMPTY
	return out


static func label_of(id: String) -> String:
	return id.replace("-", " ").replace("_", " ").capitalize()
