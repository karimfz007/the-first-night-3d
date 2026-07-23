extends SceneTree
## Local visual smoke capture. Not used by CI because headless drivers do not draw.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://src/body/main.tscn") as PackedScene
	if packed == null:
		printerr("Could not load main scene")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(30):
		await process_frame
	var image := root.get_texture().get_image()
	var directory := DirAccess.open("res://")
	if directory:
		directory.make_dir_recursive("reports/local")
	var error := image.save_png("res://reports/local/main_scene.png")
	if error != OK:
		printerr("Capture failed: ", error)
		quit(1)
		return
	print("Captured reports/local/main_scene.png")
	quit(0)
