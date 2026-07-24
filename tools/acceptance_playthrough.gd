extends SceneTree
## Full-scene, player-path acceptance scenario for the DRIFT vertical slice.

const ACCEPTANCE_SAVE := "user://acceptance_world.json"

var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("TFN_SAVE_PATH", ACCEPTANCE_SAVE)
	_clear_acceptance_save()
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://src/body/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		_finish()
		return
	var game := packed.instantiate() as GameRoot
	root.add_child(game)
	for _frame in range(12):
		await process_frame

	_gather_loose(game, ["loose_wood_01", "stone_01", "stone_02", "fiber_01"])
	_expect(game.inventory.count("driftwood") >= 2, "physical driftwood pickup reached inventory")
	_expect(game.inventory.count("stone") >= 3, "physical stone pickup reached inventory")
	_expect(game.inventory.count("plant_fiber") >= 2, "physical fiber gathering reached inventory")

	game.request_craft("primitive_stone_tool")
	game._update_crafting(Tune.CRAFT_TOOL_SECONDS + 0.1)
	_expect(game.inventory.count("stone_tool") == 1, "primitive tool crafted through live game service")
	var tool_slot := _slot_for(game.inventory, "stone_tool")
	game.player.select_hotbar(tool_slot)
	_expect(game.is_tool_equipped(game.player.selected_hotbar), "crafted tool equipped through hotbar selection")

	var tree := game.resource_nodes.get("tree_node_01") as ResourceNode
	var tree_before := tree.quantity
	var tool_result := tree.strike(game, game.player, game.is_tool_equipped(game.player.selected_hotbar))
	_expect(bool(tool_result.get("ok", false)) and tree_before - tree.quantity == Tune.TOOL_YIELD, "equipped tool improves physical tree harvest")

	_harvest_requirements(game)
	_craft_live(game, "campfire", Tune.CRAFT_FIRE_SECONDS)
	_craft_live(game, "building_plan", Tune.CRAFT_PLAN_SECONDS)
	_expect(game.inventory.count("campfire_kit") == 1, "campfire kit crafted")
	_expect(game.inventory.count("building_plan") == 1, "building plan crafted")
	var fire_slot := _slot_for(game.inventory, "campfire_kit")
	game.player.select_hotbar(fire_slot)
	_expect(game.player.build_mode and game.player.build_piece_id == "campfire", "selecting the campfire kit immediately enters campfire placement")
	game.player.set_build_mode(false)

	game.player.global_position = Vector3(0.0, 1.0, -5.0)
	await physics_frame
	var foundation := _preview_and_place(game, "foundation", Vector3.ZERO, 0.0)
	var wall_a := _preview_and_place(game, "wall", Vector3.ZERO, 0.0)
	var wall_b := _preview_and_place(game, "wall", Vector3.ZERO, PI * 0.5)
	var doorway := _preview_and_place(game, "doorway", Vector3.ZERO, PI)
	game.player.global_position = BuildRecord.transform_from(doorway).origin + Vector3(0.0, 1.0, -2.0)
	var door := _preview_and_place(game, "door", BuildRecord.transform_from(doorway).origin, PI)
	var roof := _preview_and_place(game, "roof", Vector3.ZERO, 0.0)
	_expect(not foundation.is_empty() and not wall_a.is_empty() and not wall_b.is_empty(), "foundation and snapped walls placed")
	_expect(not doorway.is_empty() and not door.is_empty(), "doorway and operable door placed")
	_expect(not roof.is_empty(), "snapped roof placed")

	var fire_record := _preview_and_place(game, "campfire", Vector3(4.0, 0.0, 0.0), 0.0)
	var fire := game.current_fire()
	_expect(not fire_record.is_empty() and fire != null, "campfire placed through preview and placement services")
	var fueled := fire.interact(game, game.player)
	var ignited := fire.interact(game, game.player)
	_expect(bool(fueled.get("ok", false)) and bool(ignited.get("ok", false)) and fire.lit, "campfire fueled and ignited")
	var extinguished := fire.strike(game, game.player, false)
	_expect(bool(extinguished.get("ok", false)) and not fire.lit and fire.fuel > 0.0, "campfire manually extinguishes while preserving fuel")

	game.world_seconds = 20.0 * 3600.0
	game.player.global_position = Vector3(18.0, 1.0, 0.0)
	game.warmth = 70.0
	game._update_warmth(10.0)
	var exposed_loss := 70.0 - game.warmth
	game.player.global_position = BuildRecord.transform_from(foundation).origin + Vector3.UP
	game.warmth = 70.0
	game._update_warmth(10.0)
	var sheltered_loss := 70.0 - game.warmth
	_expect(game.is_player_sheltered() and sheltered_loss < exposed_loss, "completed shelter visibly reduces night exposure")
	fire.interact(game, game.player)
	game.player.global_position = fire.global_position + Vector3.UP
	game.warmth = 50.0
	game._update_warmth(2.0)
	_expect(game.warmth > 50.0 and game.exposure_text() == "SANCTUARY", "lit campfire creates a warming sanctuary")

	await _verify_head_clearance(game)
	game.queue_free()
	for _frame in range(5):
		await process_frame
	_finish()

func _gather_loose(game: GameRoot, ids: Array[String]) -> void:
	for save_id in ids:
		var node := game.resource_nodes.get(save_id) as ResourceNode
		if node == null:
			_fail("missing authored resource " + save_id)
			continue
		while node.quantity > 0:
			game.player._complete_interaction(node)

func _harvest_requirements(game: GameRoot) -> void:
	for save_id in ["loose_wood_02", "loose_wood_03", "loose_wood_04", "fiber_02", "fiber_03", "fiber_04"]:
		var node := game.resource_nodes.get(save_id) as ResourceNode
		while node != null and node.quantity > 0:
			game.player._complete_interaction(node)
	for save_id in ["tree_node_01", "tree_node_02", "rock_node_01"]:
		var node := game.resource_nodes.get(save_id) as ResourceNode
		while node != null and node.quantity > 0:
			node.strike(game, game.player, true)

func _craft_live(game: GameRoot, recipe_id: String, duration: float) -> void:
	game.request_craft(recipe_id)
	game._update_crafting(duration + 0.1)

func _preview_and_place(game: GameRoot, piece_id: String, hit: Vector3, rotation_y: float) -> Dictionary:
	var preview := game.get_build_preview(piece_id, hit, Vector3.UP, rotation_y, game.player.global_position)
	if not bool(preview.get("valid", false)):
		_fail("%s preview invalid: %s" % [piece_id, preview.get("reason", "unknown")])
		return {}
	if not game.place_build(piece_id, preview.transform, str(preview.get("parent_id", ""))):
		_fail(piece_id + " placement failed")
		return {}
	return game.building_records.back()

func _verify_head_clearance(game: GameRoot) -> void:
	var player := game.player
	var capsule := player.collision.shape as CapsuleShape3D
	capsule.height = Tune.CROUCH_HEIGHT
	player.collision.position.y = Tune.CROUCH_HEIGHT * 0.5
	player.camera.position.y = Tune.CROUCH_HEAD_HEIGHT
	var ceiling := StaticBody3D.new()
	ceiling.collision_layer = 1
	ceiling.collision_mask = 0
	var ceiling_collision := CollisionShape3D.new()
	var ceiling_shape := BoxShape3D.new()
	ceiling_shape.size = Vector3(2.0, 0.24, 2.0)
	ceiling_collision.shape = ceiling_shape
	ceiling.add_child(ceiling_collision)
	game.add_child(ceiling)
	ceiling.global_position = player.global_position + Vector3.UP * 1.42
	await physics_frame
	_expect(not player.can_stand(), "head-clearance blocks standing below a low ceiling")
	ceiling.queue_free()
	await physics_frame
	await physics_frame
	_expect(player.can_stand(), "standing is restored when head clearance returns")

func _slot_for(inventory: Inventory, item_id: String) -> int:
	for index in range(inventory.slots.size()):
		if str(inventory.slots[index].get("item_id", "")) == item_id:
			return index
	return -1

func _clear_acceptance_save() -> void:
	for path in [ACCEPTANCE_SAVE, ACCEPTANCE_SAVE + ".bak", ACCEPTANCE_SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("ACCEPT: " + label)
	else:
		_fail(label)

func _fail(label: String) -> void:
	failures.append(label)
	printerr("ACCEPTANCE FAIL: " + label)

func _finish() -> void:
	_clear_acceptance_save()
	if failures.is_empty():
		print("VERTICAL SLICE ACCEPTANCE PLAYTHROUGH PASS")
		quit(0)
	else:
		quit(1)
