extends Control
## Title screen placeholder. Replaced in milestone 4 (campaign shell).


func _ready() -> void:
	var label: Label = Label.new()
	label.text = "OVARA"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
