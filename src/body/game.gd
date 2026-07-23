class_name GameRoot
extends Node3D

var state: Dictionary
var inventory: Inventory
var crafting := CraftingService.new()
var stable_ids: StableIds
var world_seconds := Tune.START_WORLD_SECONDS
var warmth := Tune.WARMTH_START
var resource_records: Dictionary = {}
var resource_nodes: Dictionary = {}
var building_records: Array[Dictionary] = []
var build_nodes: Dictionary = {}
var fires: Array[Campfire] = []
var player: PlayerController
var hud: HUD
var feedback: AudioFeedback
var touch_controls: TouchControls
var world_builder: WorldBuilder
var save_status := "Not saved"
var objective_index := 0
var _autosave_remaining := Tune.AUTOSAVE_SECONDS
var _objective_idle := 0.0
var _last_objective := -1
var _morning_report: Dictionary = {}
var _last_frame_ms := 0.0

func _ready() -> void:
	name = "THE FIRST NIGHT"
	add_to_group("game")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_state()
	feedback = AudioFeedback.new()
	add_child(feedback)
	feedback.apply_volume(float(state.player.settings.get("audio_volume", Tune.DEFAULT_AUDIO_VOLUME)))
	world_builder = WorldBuilder.new()
	world_builder.name = "Authored Island"
	add_child(world_builder)
	world_builder.build(self, resource_records)
	_restore_buildings()
	player = PlayerController.new().configure(self, state.player.settings)
	add_child(player)
	_restore_player_transform()
	hud = HUD.new().configure(self, player)
	add_child(hud)
	touch_controls = TouchControls.new().configure(player.settings)
	hud.root.add_child(touch_controls)
	player.touch_controls = touch_controls
	touch_controls.hotbar_selected.connect(player.select_hotbar)
	_update_objective(true)
	if not _morning_report.is_empty() and float(_morning_report.get("elapsed_real_seconds", 0.0)) >= Tune.OFFLINE_REPORT_MIN_SECONDS:
		hud.call_deferred("show_morning_report", _morning_report)
	notify_player("Regain control. The light is going.", "confirm")

func _process(delta: float) -> void:
	var frame_start := Time.get_ticks_usec()
	world_seconds = fposmod(world_seconds + delta * Tune.WORLD_TIME_SCALE, Tune.WORLD_DAY_SECONDS)
	_update_sun()
	_update_warmth(delta)
	_update_crafting(delta)
	_update_objective()
	_autosave_remaining -= delta
	if _autosave_remaining <= 0.0:
		save_now("autosave")
	if Input.is_action_just_pressed("build_mode") and player and not player.menu_open:
		player.set_build_mode(not player.build_mode)
	if Input.is_action_just_pressed("quick_save"):
		save_now("explicit")
	if Input.is_action_just_pressed("debug_overlay"):
		apply_setting("debug_overlay", not bool(player.settings.get("debug_overlay", false)))
	_last_frame_ms = float(Time.get_ticks_usec() - frame_start) / 1000.0

func _notification(what: int) -> void:
	if what in [
		NOTIFICATION_APPLICATION_PAUSED,
		NOTIFICATION_APPLICATION_FOCUS_OUT,
		NOTIFICATION_WM_CLOSE_REQUEST
	]:
		if is_inside_tree() and inventory != null and player != null:
			save_now("lifecycle")
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()

func _load_state() -> void:
	var loaded := SaveCodec.load_file(SaveCodec.runtime_path())
	if loaded.is_empty():
		state = WorldState.new_game()
	else:
		var elapsed := maxf(0.0, Time.get_unix_time_from_system() - float(loaded.get("last_save_unix", Time.get_unix_time_from_system())))
		var result := Reconciler.reconcile(loaded, elapsed)
		state = result.state
		_morning_report = result.report
	inventory = Inventory.from_dict(state.get("inventory", {}))
	crafting.load_dict(state.get("crafting", {}))
	stable_ids = StableIds.from_dict(state.get("stable_ids", {}))
	world_seconds = float(state.get("world_seconds", Tune.START_WORLD_SECONDS))
	warmth = float(state.get("warmth", Tune.WARMTH_START))
	resource_records = state.get("resources", {}).duplicate(true)
	for raw: Variant in state.get("buildings", []):
		if raw is Dictionary:
			building_records.append(raw.duplicate(true))
	objective_index = int(state.get("objective_index", 0))

func _restore_player_transform() -> void:
	var player_state: Dictionary = state.get("player", {})
	var raw_position: Array = player_state.get("position", [0.0, 2.0, 17.0])
	player.global_position = Vector3(
		Tune.finite_number(raw_position[0], 0.0),
		maxf(0.5, Tune.finite_number(raw_position[1], 2.0)),
		Tune.finite_number(raw_position[2], 17.0)
	)
	player.rotation.y = Tune.finite_number(player_state.get("rotation_y"), 0.0)

func register_resource(node: ResourceNode) -> void:
	resource_nodes[node.save_id] = node
	resource_records[node.save_id] = {
		"save_id": node.save_id,
		"kind": node.node_kind,
		"item_id": node.item_id,
		"quantity": node.quantity,
		"position": [node.position.x, node.position.y, node.position.z],
		"rotation_degrees": [node.rotation_degrees.x, node.rotation_degrees.y, node.rotation_degrees.z],
		"dynamic": node.save_id.begins_with("drop_")
	}

func resource_changed(save_id: String, quantity: int) -> void:
	if not resource_records.has(save_id):
		return
	var record: Dictionary = resource_records[save_id]
	record["quantity"] = maxi(0, quantity)
	resource_records[save_id] = record

func receive_item(item_id: String, amount: int, world_position: Vector3) -> Dictionary:
	var result := inventory.add(item_id, amount)
	var overflow := int(result.get("overflow", 0))
	if overflow > 0:
		spawn_loose_item(item_id, overflow, world_position)
	if int(result.get("accepted", 0)) > 0:
		feedback.cue("pickup")
	return result

func spawn_loose_item(item_id: String, amount: int, world_position: Vector3) -> void:
	if amount <= 0:
		return
	var id_value := stable_ids.next_id("drop")
	var node := ResourceNode.new().configure(id_value, "loose", item_id, amount, world_position + Vector3(0.0, 0.25, 0.0))
	world_builder.add_child(node)
	register_resource(node)

func request_craft(recipe_id: String) -> void:
	var result := crafting.start(recipe_id, inventory)
	notify_player(str(result.get("reason", "")), "confirm" if bool(result.get("ok", false)) else "fail")

func cancel_craft() -> void:
	if crafting.cancel(0, inventory):
		notify_player("Craft cancelled. Materials returned.", "confirm")
	else:
		notify_player("Nothing is being crafted.", "fail")

func _update_crafting(delta: float) -> void:
	var completed := crafting.tick(delta, inventory)
	for job in completed:
		var output: Dictionary = job.get("output", {})
		var item_id := str(output.get("item_id", ""))
		var overflow := int(job.get("overflow", 0))
		if overflow > 0:
			spawn_loose_item(item_id, overflow, player.global_position + -player.global_basis.z)
		notify_player("Crafted %s" % ItemDB.display_name(item_id), "craft")

func crafting_text() -> String:
	if crafting.queue.is_empty():
		return "Queue empty · crafting is cancellable"
	var job: Dictionary = crafting.queue[0]
	return "Crafting %s · %.1fs" % [RecipeDB.get_recipe(str(job.recipe_id)).get("name", job.recipe_id), float(job.remaining)]

func consume_wood_for_fire() -> bool:
	for item_id in ["deadfall", "driftwood"]:
		if inventory.remove(item_id, 1):
			return true
	return false

func is_tool_equipped(hotbar_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= inventory.slots.size():
		return false
	return str(inventory.slots[hotbar_index].get("item_id", "")) == "stone_tool"

func split_selected_stack() -> void:
	var index := player.selected_hotbar
	if index < 0 or index >= inventory.slots.size():
		notify_player("Select a filled hotbar slot first.", "fail")
		return
	var quantity := int(inventory.slots[index].get("quantity", 0))
	if quantity < 2 or not inventory.split_slot(index, quantity / 2):
		notify_player("That stack cannot be split.", "fail")
		return
	notify_player("Stack split.", "confirm")

func drop_selected_item(quantity: int) -> void:
	var index := player.selected_hotbar
	if index < 0 or index >= inventory.slots.size():
		notify_player("Select a filled hotbar slot first.", "fail")
		return
	var dropped := inventory.drop_slot(index, quantity)
	if dropped.is_empty() or int(dropped.get("quantity", 0)) <= 0:
		notify_player("Nothing dropped.", "fail")
		return
	var drop_position := player.global_position + -player.global_basis.z * 1.1
	spawn_loose_item(str(dropped.item_id), int(dropped.quantity), drop_position)
	notify_player("Dropped %s ×%d" % [ItemDB.display_name(str(dropped.item_id)), int(dropped.quantity)], "confirm")

func move_selected_slot(direction: int) -> void:
	var from_index := player.selected_hotbar
	var to_index := from_index + direction
	if from_index < 0 or from_index >= inventory.slots.size() or to_index < 0 or to_index >= inventory.slots.size():
		notify_player("No inventory slot in that direction.", "fail")
		return
	if inventory.move_slot(from_index, to_index):
		player.select_hotbar(to_index)
		notify_player("Item moved in the pack.", "confirm")

func get_build_preview(piece_id: String, hit_position: Vector3, normal: Vector3, rotation_y: float, player_position: Vector3) -> Dictionary:
	var definition := BuildingDB.get_piece(piece_id)
	if definition.is_empty():
		return {"valid": false, "reason": "Unknown piece", "transform": Transform3D.IDENTITY}
	var size: Vector3 = definition.size
	var basis := Basis(Vector3.UP, rotation_y).orthonormalized()
	var origin := Tune.snapped(hit_position)
	origin.y = hit_position.y + size.y * 0.5
	var parent_id := ""
	var foundation := _nearest_piece("foundation", hit_position, 7.0)
	if piece_id in ["wall", "doorway"]:
		if foundation.is_empty():
			return {"valid": false, "reason": "Aim near a foundation", "transform": Transform3D(basis, origin)}
		var foundation_transform := BuildRecord.transform_from(foundation)
		origin = foundation_transform.origin + basis * Vector3(0.0, 0.35 * 0.5 + size.y * 0.5, -2.0)
		parent_id = str(foundation.save_id)
	elif piece_id == "roof":
		if foundation.is_empty():
			return {"valid": false, "reason": "Roof snaps above a foundation", "transform": Transform3D(basis, origin)}
		var foundation_transform := BuildRecord.transform_from(foundation)
		origin = foundation_transform.origin + Vector3.UP * (0.35 * 0.5 + 2.7 + size.y * 0.5)
		parent_id = str(foundation.save_id)
	elif piece_id == "door":
		var doorway := _nearest_piece("doorway", hit_position, 6.0)
		if doorway.is_empty():
			return {"valid": false, "reason": "Door snaps into a doorway frame", "transform": Transform3D(basis, origin)}
		var doorway_transform := BuildRecord.transform_from(doorway)
		basis = doorway_transform.basis
		origin = doorway_transform.origin + doorway_transform.basis.z * 0.16
		parent_id = str(doorway.save_id)
	var candidate := Transform3D(basis, origin)
	var distance_ok := player_position.distance_to(origin) <= Tune.BUILD_RANGE + size.length() * 0.3
	var slope_angle := rad_to_deg(acos(clampf(normal.normalized().dot(Vector3.UP), -1.0, 1.0)))
	var slope_ok := slope_angle <= Tune.BUILD_MAX_SLOPE_DEGREES or piece_id in ["wall", "doorway", "door", "roof"]
	var requirements_ok := inventory.has_cost(definition.cost)
	if piece_id != "campfire" and inventory.count("building_plan") <= 0:
		return {"valid": false, "reason": "Building plan required", "transform": candidate, "parent_id": parent_id}
	if not requirements_ok:
		return {"valid": false, "reason": _missing_cost_text(inventory.missing_for(definition.cost)), "transform": candidate, "parent_id": parent_id}
	if not distance_ok:
		return {"valid": false, "reason": "Out of placement range", "transform": candidate, "parent_id": parent_id}
	if not slope_ok:
		return {"valid": false, "reason": "Terrain is too steep", "transform": candidate, "parent_id": parent_id}
	var collision_reason := _placement_collision_reason(piece_id, origin, parent_id)
	if not collision_reason.is_empty():
		return {"valid": false, "reason": collision_reason, "transform": candidate, "parent_id": parent_id}
	return {"valid": true, "reason": _cost_text(definition.cost), "transform": candidate, "parent_id": parent_id}

func place_build(piece_id: String, placement: Transform3D, parent_id: String = "") -> bool:
	var definition := BuildingDB.get_piece(piece_id)
	if definition.is_empty() or not inventory.consume_cost(definition.cost):
		notify_player("Resources changed — placement cancelled.", "fail")
		return false
	var save_id := stable_ids.next_id("build")
	var record := BuildRecord.create(save_id, piece_id, Tune.OWNER_ID, placement, parent_id)
	building_records.append(record)
	if piece_id == "campfire":
		var fire := Campfire.new().configure(save_id, placement)
		add_child(fire)
		fires.append(fire)
		build_nodes[save_id] = fire
	else:
		var piece := BuildPiece.new().configure(record)
		add_child(piece)
		build_nodes[save_id] = piece
	notify_player("%s placed." % definition.name, "build")
	return true

func _restore_buildings() -> void:
	var fire_records: Dictionary = {}
	for raw_fire: Variant in state.get("fires", []):
		if raw_fire is Dictionary:
			fire_records[str(raw_fire.get("save_id", ""))] = raw_fire
	for record in building_records:
		var piece_id := str(record.get("piece_id", ""))
		var save_id := str(record.get("save_id", ""))
		if piece_id == "campfire":
			var fire := Campfire.new().configure(save_id, BuildRecord.transform_from(record), fire_records.get(save_id, {}))
			add_child(fire)
			fires.append(fire)
			build_nodes[save_id] = fire
		else:
			var piece := BuildPiece.new().configure(record)
			add_child(piece)
			build_nodes[save_id] = piece

func _nearest_piece(piece_id: String, point: Vector3, maximum_distance: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := maximum_distance
	for record in building_records:
		if str(record.get("piece_id", "")) != piece_id:
			continue
		var distance := BuildRecord.transform_from(record).origin.distance_to(point)
		if distance < best_distance:
			best = record
			best_distance = distance
	return best

func _placement_collision_reason(piece_id: String, origin: Vector3, parent_id: String) -> String:
	for record in building_records:
		var other_id := str(record.get("piece_id", ""))
		var other_origin := BuildRecord.transform_from(record).origin
		var distance := origin.distance_to(other_origin)
		if piece_id == "door" and other_id == "doorway" and str(record.get("save_id", "")) == parent_id:
			continue
		if piece_id in ["wall", "doorway"] and other_id == "foundation" and str(record.get("save_id", "")) == parent_id:
			continue
		if piece_id == "roof" and other_id == "foundation" and str(record.get("save_id", "")) == parent_id:
			continue
		var minimum := 3.5 if piece_id == "foundation" and other_id == "foundation" else 0.55
		if distance < minimum:
			return "Another structure occupies that snap"
	for node: Node in get_tree().get_nodes_in_group("interactable"):
		if node is ResourceNode and not node.depleted and node.global_position.distance_to(origin) < 1.35:
			return "A resource blocks placement"
	return ""

func _update_warmth(delta: float) -> void:
	if player == null:
		return
	var heating := false
	for fire in fires:
		if is_instance_valid(fire) and fire.is_heating(player.global_position):
			heating = true
			break
	var sheltered := is_player_sheltered()
	if heating:
		warmth = minf(Tune.WARMTH_MAX, warmth + Tune.WARMTH_FIRE_GAIN_PER_SECOND * delta)
	elif Tune.is_night(world_seconds):
		var per_second := Tune.WARMTH_EXPOSED_LOSS_PER_WORLD_MINUTE * Tune.WORLD_TIME_SCALE / 60.0
		if sheltered:
			per_second *= Tune.WARMTH_SHELTER_LOSS_MULTIPLIER
		warmth = maxf(Tune.WARMTH_MIN, warmth - per_second * delta)

func is_player_sheltered() -> bool:
	if player == null:
		return false
	var nearby_walls := 0
	var has_roof := false
	var has_foundation := false
	for record in building_records:
		var position_value := BuildRecord.transform_from(record).origin
		if position_value.distance_to(player.global_position) > Tune.SHELTER_CHECK_RADIUS:
			continue
		match str(record.get("piece_id", "")):
			"wall", "doorway":
				nearby_walls += 1
			"roof":
				has_roof = true
			"foundation":
				has_foundation = true
	return has_foundation and has_roof and nearby_walls >= Tune.SHELTER_REQUIRED_WALLS

func _update_objective(force: bool = false) -> void:
	var next := 0
	if inventory.count("driftwood") >= 2 and inventory.count("stone") >= 3:
		next = 1
	if inventory.count("stone_tool") > 0:
		next = 2
	var has_fire := not fires.is_empty() or inventory.count("campfire_kit") > 0
	if has_fire:
		next = 3
	var shelter_piece_count := 0
	for record in building_records:
		if str(record.get("piece_id", "")) != "campfire":
			shelter_piece_count += 1
	if shelter_piece_count >= 5:
		next = 4
	if next != objective_index or force:
		objective_index = next
		_objective_idle = 0.0
		if not force and hud:
			notify_player("A new need becomes clear.", "confirm")
	else:
		_objective_idle += get_process_delta_time()
		if _objective_idle >= Tune.HINT_IDLE_SECONDS:
			_objective_idle = 0.0
			_show_context_hint()

func current_objective() -> String:
	var keys := ["objective_driftwood", "objective_tool", "objective_fire", "objective_shelter", "objective_survive"]
	return "NOW · " + GameStrings.get_text(keys[clampi(objective_index, 0, keys.size() - 1)])

func _show_context_hint() -> void:
	var hints := [
		"Look near the tide line. Pale wood stands out against wet sand.",
		"Open hand crafting [K]. Stone, fiber, and wood bind a useful edge.",
		"Craft a campfire kit, then use build mode [B].",
		"Place a foundation first. Walls and roof snap from it.",
		"Add wood before the flames sink. Shelter slows exposed warmth loss."
	]
	notify_player(hints[clampi(objective_index, 0, hints.size() - 1)], "confirm")

func current_fire() -> Campfire:
	for fire in fires:
		if is_instance_valid(fire):
			return fire
	return null

func fire_status_text() -> String:
	var fire := current_fire()
	if fire == null:
		return "NONE"
	return fire.fuel_text() if fire.lit else ("READY" if fire.fuel > 0.0 else "EMPTY")

func exposure_text() -> String:
	var fire := current_fire()
	if fire and fire.is_heating(player.global_position):
		return "SANCTUARY"
	return "SHELTERED" if is_player_sheltered() else ("EXPOSED" if Tune.is_night(world_seconds) else "DUSK")

func clock_text() -> String:
	var total_minutes := int(fposmod(world_seconds, Tune.WORLD_DAY_SECONDS) / 60.0)
	return "%02d:%02d" % [total_minutes / 60, total_minutes % 60]

func _update_sun() -> void:
	var sun := get_tree().get_first_node_in_group("sun") as DirectionalLight3D
	if sun == null:
		return
	var hour := fposmod(world_seconds, Tune.WORLD_DAY_SECONDS) / 3600.0
	sun.rotation_degrees.x = -10.0 + (hour - 18.0) * 8.0
	sun.light_energy = clampf(Tune.SUN_ENERGY - maxf(0.0, hour - 18.0) * 0.18, 0.04, Tune.SUN_ENERGY)

func notify_player(message: String, cue_name: String = "confirm") -> void:
	if message.is_empty():
		return
	if hud:
		hud.notify(message)
	if feedback:
		feedback.cue(cue_name)

func apply_setting(key: String, value: Variant) -> void:
	if player == null:
		return
	player.settings[key] = value
	if key == "audio_volume":
		feedback.apply_volume(float(value))
	if key in ["control_side", "touch_scale"] and touch_controls:
		touch_controls._control_side = str(player.settings.get("control_side", "left_move"))
		touch_controls._scale_value = float(player.settings.get("touch_scale", Tune.TOUCH_DEFAULT_SCALE))

func save_now(reason: String = "autosave") -> bool:
	if player == null:
		return false
	var live_buildings: Array[Dictionary] = []
	for record in building_records:
		var id_value := str(record.get("save_id", ""))
		var node: Node = build_nodes.get(id_value)
		if node is BuildPiece:
			live_buildings.append(node.to_record())
		else:
			live_buildings.append(record.duplicate(true))
	var fire_records: Array[Dictionary] = []
	for fire in fires:
		if is_instance_valid(fire):
			fire_records.append(fire.to_fire_record())
	state = {
		"schema_version": Tune.SCHEMA_VERSION,
		"player": player.world_transform_data(),
		"inventory": inventory.to_dict(),
		"crafting": crafting.to_dict(),
		"buildings": live_buildings,
		"fires": fire_records,
		"resources": resource_records.duplicate(true),
		"world_seconds": world_seconds,
		"warmth": warmth,
		"stable_ids": stable_ids.to_dict(),
		"objective_index": objective_index,
		"last_save_unix": int(Time.get_unix_time_from_system())
	}
	var success := SaveCodec.save_file(state, SaveCodec.runtime_path())
	save_status = "Saved · %s" % reason if success else "SAVE FAILED"
	_autosave_remaining = Tune.AUTOSAVE_SECONDS
	if hud:
		hud.show_save_status(save_status)
	if reason == "explicit":
		notify_player(save_status, "confirm" if success else "fail")
	return success

func debug_text() -> String:
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var active: String = str(player.active_target.name) if player.active_target and is_instance_valid(player.active_target) else "none"
	var fire := current_fire()
	return "DEV OVERLAY\nFPS %d  frame %.2f ms\ndraw calls %d  memory %.1f MB\npos %.1f, %.1f, %.1f\ntarget %s\nsave %s\nworld %s  warmth %.1f\nfire %.1f" % [
		Engine.get_frames_per_second(), _last_frame_ms, int(draw_calls), memory_mb,
		player.global_position.x, player.global_position.y, player.global_position.z,
		active, save_status, clock_text(), warmth, fire.fuel if fire else 0.0
	]

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id: String in cost:
		parts.append("%s ×%d" % [ItemDB.display_name(item_id), int(cost[item_id])])
	return " · ".join(parts)

func _missing_cost_text(missing: Dictionary) -> String:
	return "Missing " + _cost_text(missing)
