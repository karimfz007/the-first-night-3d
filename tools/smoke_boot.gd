extends SceneTree
## Full composition-root smoke test used by CI after deterministic tests.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://src/body/main.tscn") as PackedScene
	if packed == null:
		printerr("SMOKE FAIL: main scene did not load")
		quit(1)
		return
	var game := packed.instantiate() as GameRoot
	root.add_child(game)
	for _frame in range(90):
		await process_frame
	var failures: Array[String] = []
	if game.player == null or not game.player.is_inside_tree():
		failures.append("player did not enter the tree")
	if game.hud == null or not game.hud.is_inside_tree():
		failures.append("HUD did not enter the tree")
	if game.world_builder == null or game.resource_nodes.size() != WorldSliceDB.RESOURCES.size():
		failures.append("authored resource nodes were not fully created")
	if game.inventory == null or game.state.is_empty():
		failures.append("new/load world state did not initialize")
	game.queue_free()
	for _frame in range(5):
		await process_frame
	if failures.is_empty():
		print("FULL SCENE SMOKE PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("SMOKE FAIL: " + failure)
		quit(1)

