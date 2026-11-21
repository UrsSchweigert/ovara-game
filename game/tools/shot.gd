extends SceneTree
## Renders a scene for a moment and saves a PNG, so an agent can look at its own work.
## Usage: ./ov shot res://scenes/title/title.tscn out.png [width height]
## Needs a real renderer, so it opens a window briefly; it cannot run with --headless.


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: shot.gd -- <scene path> <output png> [width height]")
		quit(2)
		return
	if args.size() >= 4:
		root.get_window().size = Vector2i(int(args[2]), int(args[3]))
	var packed: PackedScene = load(args[0]) as PackedScene
	if packed == null:
		printerr("cannot load scene: " + args[0])
		quit(1)
		return
	root.add_child(packed.instantiate())
	_capture.call_deferred(args[1])


func _capture(out_path: String) -> void:
	for i: int in 12:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(out_path)
	if error != OK:
		printerr("cannot write " + out_path)
		quit(1)
		return
	print("saved %s (%dx%d)" % [out_path, image.get_width(), image.get_height()])
	quit(0)
