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
	_test_inventory_serialization()
	_test_crafting_input_output_and_cancel()
	_test_building_serialization()
	_test_save_migration()
	_test_corrupt_save_recovery()
	_test_stable_ids()
	_test_no_negative_resources()
	_test_no_nan_or_infinite()
	_test_main_scene_contract()
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

func _test_main_scene_contract() -> void:
	var scene := load("res://src/body/main.tscn") as PackedScene
	_expect_true(scene != null, "main scene loads")
	if scene:
		var instance := scene.instantiate()
		_expect_true(instance is Node3D, "main scene instantiates as 3D root")
		_expect_true(instance.get_script() != null, "main scene has a valid game script")
		_expect_true(instance.get_script().can_instantiate(), "main game script compiles")
		instance.free()

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
