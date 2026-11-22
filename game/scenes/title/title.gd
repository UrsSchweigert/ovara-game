extends Control
## Title: starts a new game, or continues the save when there is one.

const Session: GDScript = preload("res://rules/session.gd")
const SaveStore: GDScript = preload("res://rules/save_store.gd")
const Loader: GDScript = preload("res://scenes/explore/content_loader.gd")
const Holder: GDScript = preload("res://scenes/explore/session_holder.gd")

const SAVE_PATH: String = "user://save.json"
const EXPLORE: String = "res://scenes/explore/explore.tscn"
const BUTTON_SIZE: Vector2 = Vector2(240, 48)

var _store: RefCounted = null


func _ready() -> void:
	_store = SaveStore.new(SAVE_PATH)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var label: Label = Label.new()
	label.text = "OVARA"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	if bool(_store.call("has_save")):
		_add_button(box, "Continue", _on_continue)
	_add_button(box, "New game", _on_new_game)


func _add_button(box: VBoxContainer, text: String, handler: Callable) -> void:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = BUTTON_SIZE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(handler)
	box.add_child(b)


func _on_new_game() -> void:
	Holder.put(Session.new_game(Loader.load_all(), _store))
	get_tree().change_scene_to_file(EXPLORE)


func _on_continue() -> void:
	Holder.put(Session.resume(_store, Loader.load_all()))
	get_tree().change_scene_to_file(EXPLORE)
