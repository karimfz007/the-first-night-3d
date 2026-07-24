extends SceneTree

var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("THE FIRST NIGHT — deterministic brain tests")
	_test_zero_elapsed()
	_test_deterministic_reconciliation()
	_test_absence_durations()
	_test_fire_fuel_exhaustion()
	_test_warmth_bounds_and_floor()
	_test_offline_spatial_fairness()
	_test_offline_report_cap_and_shelter()
	_test_slice_resource_budget()
	_test_inventory_serialization()
	_test_crafting_input_output_and_cancel()
	_test_building_serialization()
	_test_save_migration()
	_test_corrupt_save_recovery()
	_test_stable_ids()
	_test_no_negative_resources()
	_test_no_nan_or_infinite()
	_test_property_sweep()
	_test_main_scene_contract()
	_test_body_interaction_contracts()
	_test_save_file_round_trip()
	print("\nRESULT: %d passed, %d failed" % [passed, failed])
	for failure in failures:
		printerr("FAIL: " + failure)
	quit(1 if failed > 0 else 0)

func _test_zero_elapsed() -> void:
	var initial := WorldState.new_game(100)
	initial.fires = [{"save_id": "fire_1", "fuel": 100.0, "lit": true}]
	var result := Reconciler.reconcile(initial, 0.0)
	_expect_equal(result.state.world_seconds, initial.world_seconds, "zero elapsed keeps world clock")
	_expect_equal(result.state.fires[0].fuel, 100.0, "zero elapsed keeps fire fuel")
	_expect_equal(result.report.world_advanced_seconds, 0.0, "zero elapsed report")

func _test_deterministic_reconciliation() -> void:
	var initial := WorldState.new_game(100)
	initial.fires = [{"save_id": "fire_1", "fuel": 400.0, "lit": true}]
	var first := Reconciler.reconcile(initial, 1234.5)
	var second := Reconciler.reconcile(initial, 1234.5)
	_expect_equal(JSON.stringify(first), JSON.stringify(second), "same state and elapsed reconcile identically")

func _test_absence_durations() -> void:
	for seconds in [60.0, 3600.0, 86400.0]:
		var initial := WorldState.new_game(100)
		var result := Reconciler.reconcile(initial, seconds)
		_expect_approx(result.report.world_advanced_seconds, minf(seconds, Tune.OFFLINE_MAX_REAL_SECONDS) * Tune.WORLD_TIME_SCALE, 0.001, "absence duration %.0f advances correctly" % seconds)

func _test_fire_fuel_exhaustion() -> void:
	var initial := WorldState.new_game(100)
	initial.fires = [{"save_id": "fire_1", "fuel": 10.0, "lit": true}]
	var result := Reconciler.reconcile(initial, 120.0)
	_expect_equal(result.state.fires[0].fuel, 0.0, "fire fuel cannot become negative")
	_expect_true(not result.state.fires[0].lit, "exhausted fire is unlit")
	_expect_true(result.report.fire_went_out, "report records fuel exhaustion")

func _test_warmth_bounds_and_floor() -> void:
	var cold := WorldState.new_game(100)
	cold.warmth = 2.0
	var cold_result := Reconciler.reconcile(cold, Tune.OFFLINE_MAX_REAL_SECONDS)
	_expect_equal(cold_result.state.warmth, Tune.WARMTH_OFFLINE_FLOOR, "offline warmth uses fair floor")
	var hot := WorldState.new_game(100)
	hot.warmth = 99.0
	hot.fires = [{"save_id": "fire_1", "fuel": Tune.FIRE_FUEL_MAX, "lit": true}]
	var hot_result := Reconciler.reconcile(hot, 1.0)
	_expect_true(hot_result.state.warmth <= Tune.WARMTH_MAX, "warmth is upper bounded")

func _test_offline_spatial_fairness() -> void:
	var near := WorldState.new_game(100)
	near.player.position = [0.0, 2.0, 0.0]
	near.fires = [{"save_id": "fire_1", "fuel": Tune.FIRE_FUEL_MAX, "lit": true, "position": [1.0, 0.0, 0.0]}]
	var near_result := Reconciler.reconcile(near, 30.0)
	var far := near.duplicate(true)
	far.fires[0].position = [40.0, 0.0, 0.0]
	var far_result := Reconciler.reconcile(far, 30.0)
	_expect_true(near_result.report.fire_heat_seconds > 0.0, "nearby offline fire provides heat")
	_expect_equal(far_result.report.fire_heat_seconds, 0.0, "distant offline fire provides no fake heat")
	_expect_true(near_result.state.warmth >= far_result.state.warmth, "spatial fire warmth is causally bounded")

func _test_offline_report_cap_and_shelter() -> void:
	var state_value := WorldState.new_game(100)
	state_value.player.position = [0.0, 1.0, 0.0]
	var ids := StableIds.new()
	for piece_id in ["foundation", "wall", "wall", "doorway", "roof"]:
		state_value.buildings.append(BuildRecord.create(ids.next_id("build"), piece_id, Tune.OWNER_ID, Transform3D(Basis.IDENTITY, Vector3.ZERO)))
	var requested := Tune.OFFLINE_MAX_REAL_SECONDS + 7200.0
	var result := Reconciler.reconcile(state_value, requested)
	_expect_equal(result.report.requested_elapsed_seconds, requested, "morning report preserves actual time absent")
	_expect_equal(result.report.elapsed_real_seconds, Tune.OFFLINE_MAX_REAL_SECONDS, "offline consequences use configured fairness cap")
	_expect_true(result.report.sheltered, "offline report detects completed shelter")
	_expect_true("shelter reduced exposure" in str(result.report.cause).to_lower(), "offline explanation names shelter protection")

func _test_slice_resource_budget() -> void:
	var required := {"driftwood": 0, "stone": 0, "plant_fiber": 0}
	for recipe_id in ["primitive_stone_tool", "building_plan", "campfire"]:
		var recipe := RecipeDB.get_recipe(recipe_id)
		for item_id: String in recipe.ingredients:
			if required.has(item_id):
				required[item_id] += int(recipe.ingredients[item_id])
	for piece_id in ["foundation", "wall", "wall", "doorway", "door", "roof"]:
		var piece := BuildingDB.get_piece(piece_id)
		for item_id: String in piece.cost:
			if required.has(item_id):
				required[item_id] += int(piece.cost[item_id])
	for item_id: String in required:
		_expect_true(WorldSliceDB.total_item(item_id) >= int(required[item_id]), "authored slice contains enough %s for tool, fire, and functional shelter" % item_id)

func _test_inventory_serialization() -> void:
	var inventory := Inventory.new(4)
	inventory.add("driftwood", 57)
	inventory.add("stone", 3)
	var restored := Inventory.from_dict(inventory.to_dict())
	_expect_equal(restored.count("driftwood"), 57, "inventory restores merged stacks")
	_expect_equal(restored.count("stone"), 3, "inventory restores second item")
	_expect_true(restored.slots.size() == 3, "stack limits are preserved")

func _test_crafting_input_output_and_cancel() -> void:
	var inventory := Inventory.new()
	inventory.add("driftwood", 12)
	inventory.add("stone", 10)
	inventory.add("plant_fiber", 10)
	var crafting := CraftingService.new()
	var started := crafting.start("primitive_stone_tool", inventory)
	_expect_true(started.ok, "valid craft starts")
	_expect_equal(inventory.count("stone"), 7, "craft consumes input once")
	crafting.tick(Tune.CRAFT_TOOL_SECONDS + 0.1, inventory)
	_expect_equal(inventory.count("stone_tool"), 1, "craft produces output")
	var before := inventory.count("driftwood")
	crafting.start("campfire", inventory)
	_expect_true(crafting.cancel(0, inventory), "craft queue is cancellable")
	_expect_equal(inventory.count("driftwood"), before, "cancel returns inputs")

func _test_building_serialization() -> void:
	var transform := Transform3D(Basis(Vector3.UP, 0.7), Vector3(2.5, 0.2, -4.0))
	var record := BuildRecord.create("build_00000001", "foundation", Tune.OWNER_ID, transform)
	var restored := BuildRecord.transform_from(JSON.parse_string(JSON.stringify(record)))
	_expect_approx(restored.origin.x, 2.5, 0.0001, "building origin serializes")
	_expect_approx(restored.basis.x.z, transform.basis.x.z, 0.0001, "building rotation serializes")
	_expect_equal(record.save_id, "build_00000001", "building stable save ID serializes")

func _test_save_migration() -> void:
	var old := WorldState.new_game(100)
	old.schema_version = 1
	old.temperature = 44.0
	old.erase("warmth")
	old.erase("stable_ids")
	var migrated := SaveCodec.decode(JSON.stringify(old))
	_expect_equal(migrated.schema_version, Tune.SCHEMA_VERSION, "save schema migrates")
	_expect_equal(migrated.warmth, 44.0, "legacy temperature migrates to warmth")
	_expect_true(migrated.has("stable_ids"), "migration adds stable IDs")
	_expect_true(migrated.resources.has("loose_wood_01") or old.resources.is_empty(), "migration converts authored resource state")
	var version_two := WorldState.new_game(100)
	version_two.schema_version = 2
	version_two.resources = {"loose_wood_01": 1}
	var resource_migration := SaveCodec.decode(JSON.stringify(version_two))
	_expect_equal(resource_migration.resources.loose_wood_01.quantity, 1, "v2 resource quantities migrate to reconstructible records")

func _test_corrupt_save_recovery() -> void:
	_expect_true(SaveCodec.decode("{bad json").is_empty(), "corrupt JSON is rejected")
	_expect_true(SaveCodec.decode("[1,2,3]").is_empty(), "non-object save is rejected")
	var future := WorldState.new_game(100)
	future.schema_version = Tune.SCHEMA_VERSION + 99
	_expect_true(SaveCodec.decode(JSON.stringify(future)).is_empty(), "unknown future schema is rejected")

func _test_stable_ids() -> void:
	var ids := StableIds.new(7)
	_expect_equal(ids.next_id("build"), "build_00000007", "stable ID has deterministic format")
	var restored := StableIds.from_dict(ids.to_dict())
	_expect_equal(restored.next_id("build"), "build_00000008", "stable ID counter persists")

func _test_no_negative_resources() -> void:
	var inventory := Inventory.new()
	inventory.add("stone", 2)
	_expect_true(not inventory.remove("stone", 3), "over-removal is rejected")
	_expect_equal(inventory.count("stone"), 2, "failed removal leaves resources intact")
	_expect_true(inventory.remove("stone", 2), "exact removal works")
	_expect_equal(inventory.count("stone"), 0, "resource reaches zero, never negative")

func _test_no_nan_or_infinite() -> void:
	var invalid := WorldState.new_game(100)
	invalid.warmth = NAN
	invalid.world_seconds = INF
	var sanitized := WorldState.sanitized(invalid)
	_expect_true(not is_nan(sanitized.warmth) and not is_inf(sanitized.warmth), "warmth sanitizes non-finite values")
	_expect_true(not is_nan(sanitized.world_seconds) and not is_inf(sanitized.world_seconds), "clock sanitizes non-finite values")
	for sample in [NAN, INF, -INF]:
		var result := Reconciler.reconcile(invalid, sample)
		_expect_true(not is_nan(result.state.warmth) and not is_inf(result.state.warmth), "reconciliation stays finite")

func _test_property_sweep() -> void:
	var all_valid := true
	for index in range(240):
		var initial := WorldState.new_game(100)
		initial.warmth = float((index * 37) % 140) - 20.0
		initial.world_seconds = float((index * 7919) % int(Tune.WORLD_DAY_SECONDS))
		initial.player.position = [float(index % 11), 2.0, float(index % 7)]
		initial.fires = [{
			"save_id": "fire_property",
			"fuel": float((index * 53) % int(Tune.FIRE_FUEL_MAX + 200.0)) - 100.0,
			"lit": index % 3 != 0,
			"position": [float(index % 13), 0.0, float(index % 5)]
		}]
		var elapsed := float(index * index * 17)
		var first := Reconciler.reconcile(initial, elapsed)
		var second := Reconciler.reconcile(initial, elapsed)
		var state_value: Dictionary = first.state
		all_valid = all_valid \
			and JSON.stringify(first) == JSON.stringify(second) \
			and float(state_value.warmth) >= Tune.WARMTH_MIN \
			and float(state_value.warmth) <= Tune.WARMTH_MAX \
			and float(state_value.fires[0].fuel) >= 0.0 \
			and not is_nan(float(state_value.world_seconds)) \
			and not is_inf(float(state_value.world_seconds))
		if not all_valid:
			break
	_expect_true(all_valid, "240-case deterministic property sweep preserves bounds and finiteness")

func _test_main_scene_contract() -> void:
	var scene := load("res://src/body/main.tscn") as PackedScene
	_expect_true(scene != null, "main scene loads")
	if scene:
		var instance := scene.instantiate()
		_expect_true(instance is Node3D, "main scene instantiates as 3D root")
		_expect_true(instance.get_script() != null, "main scene has a valid game script")
		_expect_true(instance.get_script().can_instantiate(), "main game script compiles")
		instance.free()

func _test_body_interaction_contracts() -> void:
	var ids := StableIds.new()
	var doorway_record := BuildRecord.create(ids.next_id("build"), "doorway", Tune.OWNER_ID, Transform3D.IDENTITY)
	var doorway := BuildPiece.new().configure(doorway_record)
	doorway._ready()
	var doorway_collisions := doorway.find_children("*", "CollisionShape3D", true, false)
	_expect_equal(doorway_collisions.size(), 3, "doorway collision preserves a walkable opening")
	doorway.free()
	var door_record := BuildRecord.create(ids.next_id("build"), "door", Tune.OWNER_ID, Transform3D.IDENTITY)
	var door := BuildPiece.new().configure(door_record)
	door._ready()
	var opened := door.interact(null, null)
	_expect_true(opened.ok and bool(door.record.get("door_open", false)), "simple door opens physically")
	var closed := door.interact(null, null)
	_expect_true(closed.ok and not bool(door.record.get("door_open", true)), "simple door closes physically")
	door.free()
	var game := GameRoot.new()
	game.inventory = Inventory.new()
	game.inventory.add("driftwood", 2)
	game.inventory.add("stone_tool", 1)
	_expect_true(not game.is_tool_equipped(0), "tool effectiveness ignores an unequipped inventory tool")
	_expect_true(game.is_tool_equipped(1), "selected hotbar tool governs harvesting")
	game.player = PlayerController.new()
	game.player.selected_hotbar = 0
	game.move_selected_slot(1)
	_expect_equal(game.inventory.slots[1].item_id, "driftwood", "inventory move controls reorder the selected slot")
	game.player.free()
	game.free()
	var touch := TouchControls.new()
	touch._ready()
	var button_texts: Array[String] = []
	for button: Button in touch.find_children("*", "Button", true, false):
		button_texts.append(button.text)
	_expect_true("PLACE" in button_texts and "CANCEL" in button_texts and "ROTATE" in button_texts, "touch UI exposes explicit placement confirmation, cancellation, and rotation")
	for number in ["1", "2", "3", "4", "5", "6"]:
		_expect_true(number in button_texts, "touch hotbar exposes slot %s" % number)
	touch.free()
	var settings := WorldState.default_settings()
	_expect_true(settings.has("touch_opacity") and float(settings.touch_opacity) >= Tune.TOUCH_MIN_OPACITY, "mobile control opacity has a persisted accessible default")

	var persistent_drop := WorldState.new_game(100)
	persistent_drop.resources = {
		"drop_00000001": {
			"save_id": "drop_00000001",
			"kind": "loose",
			"item_id": "stone",
			"quantity": 3,
			"position": [4.0, 0.25, 9.0],
			"rotation_degrees": [0.0, 20.0, 0.0],
			"dynamic": true
		}
	}
	var restored_drop := SaveCodec.decode(SaveCodec.encode(persistent_drop))
	_expect_equal(restored_drop.resources.drop_00000001.quantity, 3, "dynamic dropped-item quantity persists")
	_expect_equal(restored_drop.resources.drop_00000001.position, [4.0, 0.25, 9.0], "dynamic dropped-item transform persists")
	var restore_game := GameRoot.new()
	var restore_builder := WorldBuilder.new()
	restore_builder.game = restore_game
	restore_builder._create_resources(restored_drop.resources)
	_expect_true(restore_game.resource_nodes.has("drop_00000001"), "dynamic dropped item reconstructs into the world")
	_expect_equal(restore_game.resource_nodes.drop_00000001.quantity, 3, "reconstructed dropped item preserves quantity")
	restore_builder.free()
	restore_game.free()

func _test_save_file_round_trip() -> void:
	var path := "user://test_world_round_trip.json"
	var absolute := ProjectSettings.globalize_path(path)
	var backup_absolute := ProjectSettings.globalize_path(path + ".bak")
	var temp_absolute := ProjectSettings.globalize_path(path + ".tmp")
	for target in [absolute, backup_absolute, temp_absolute]:
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(target)
	var state_value := WorldState.new_game(123)
	state_value.inventory = Inventory.new().to_dict()
	_expect_true(SaveCodec.save_file(state_value, path), "save file is created")
	var loaded := SaveCodec.load_file(path)
	_expect_equal(loaded.schema_version, Tune.SCHEMA_VERSION, "save reload succeeds")
	for target in [absolute, backup_absolute, temp_absolute]:
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(target)

func _expect_true(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		failures.append(label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect_true(actual == expected, "%s (actual=%s expected=%s)" % [label, actual, expected])

func _expect_approx(actual: float, expected: float, tolerance: float, label: String) -> void:
	_expect_true(absf(actual - expected) <= tolerance, "%s (actual=%s expected=%s)" % [label, actual, expected])
