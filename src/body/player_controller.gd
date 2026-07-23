class_name PlayerController
extends CharacterBody3D

var game: Node
var camera: Camera3D
var collision: CollisionShape3D
var touch_controls: TouchControls
var settings: Dictionary = WorldState.default_settings()
var stamina := Tune.STAMINA_MAX
var selected_hotbar := 0
var active_target: Node
var active_target_distance := 0.0
var hold_progress := 0.0
var hold_target: Node
var build_mode := false
var build_piece_id := "foundation"
var build_rotation := 0.0
var build_valid := false
var build_parent_id := ""
var build_preview: MeshInstance3D
var menu_open := false
var _tool_cooldown := 0.0
var _bob_time := 0.0
var _touch_look := Vector2.ZERO
var _step_timer := 0.0

func configure(game_node: Node, settings_value: Dictionary) -> PlayerController:
	game = game_node
	settings = WorldState.default_settings()
	settings.merge(settings_value, true)
	return self

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	collision_layer = 4
	collision_mask = 1
	floor_max_angle = deg_to_rad(47.0)
	floor_snap_length = 0.38
	floor_stop_on_slope = true
	collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = Tune.STANDING_HEIGHT
	collision.shape = capsule
	collision.position.y = Tune.STANDING_HEIGHT * 0.5
	add_child(collision)
	camera = Camera3D.new()
	camera.name = "First Person Camera"
	camera.position.y = Tune.HEAD_HEIGHT
	camera.current = true
	camera.fov = 72.0
	add_child(camera)
	_create_build_preview()
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if game == null:
		return
	_tool_cooldown = maxf(0.0, _tool_cooldown - delta)
	_update_look()
	_update_movement(delta)
	_update_interaction(delta)
	_update_build_preview()
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and OS.has_feature("web") and not menu_open and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not menu_open:
		_apply_look(event.relative * float(settings.get("look_sensitivity", Tune.LOOK_SENSITIVITY)))
	if event is InputEventMouseButton and event.pressed and build_mode:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_build_piece(BuildingDB.next_piece(build_piece_id, 1))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_build_piece(BuildingDB.next_piece(build_piece_id, -1))
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
			select_hotbar(int(event.physical_keycode - KEY_1))
	if Input.is_action_just_pressed("cancel"):
		if build_mode:
			set_build_mode(false)
		elif not OS.has_feature("mobile"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _update_look() -> void:
	if touch_controls and not menu_open:
		var delta_look := touch_controls.consume_look()
		if delta_look.length_squared() > 0.0:
			_apply_look(delta_look * float(settings.get("touch_sensitivity", Tune.TOUCH_SENSITIVITY)))

func _apply_look(delta_look: Vector2) -> void:
	var invert := -1.0 if bool(settings.get("invert_look", false)) else 1.0
	rotate_y(-delta_look.x)
	camera.rotation.x = clampf(camera.rotation.x - delta_look.y * invert, -Tune.LOOK_PITCH_LIMIT, Tune.LOOK_PITCH_LIMIT)

func _update_movement(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if touch_controls and touch_controls.move_vector.length() > input_vector.length():
		input_vector = touch_controls.move_vector
	if menu_open:
		input_vector = Vector2.ZERO
	var crouching := Input.is_action_pressed("crouch")
	var sprinting := Input.is_action_pressed("sprint") and not crouching and input_vector.y < -0.1 and stamina > 0.0
	if touch_controls:
		crouching = crouching or touch_controls.crouch_active
		sprinting = sprinting or (input_vector.length() > 0.92 and not crouching and stamina > 0.0)
	var speed := Tune.CROUCH_SPEED if crouching else (Tune.SPRINT_SPEED if sprinting else Tune.WALK_SPEED)
	if sprinting:
		stamina = maxf(0.0, stamina - Tune.STAMINA_DRAIN_PER_SECOND * delta)
	else:
		stamina = minf(Tune.STAMINA_MAX, stamina + Tune.STAMINA_RECOVER_PER_SECOND * delta)
	var desired_height := Tune.CROUCH_HEIGHT if crouching else Tune.STANDING_HEIGHT
	var desired_head := Tune.CROUCH_HEAD_HEIGHT if crouching else Tune.HEAD_HEIGHT
	var capsule: CapsuleShape3D = collision.shape
	capsule.height = move_toward(capsule.height, desired_height, Tune.CROUCH_LERP_SPEED * delta)
	collision.position.y = capsule.height * 0.5
	camera.position.y = move_toward(camera.position.y, desired_head, Tune.CROUCH_LERP_SPEED * delta)
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var acceleration := Tune.GROUND_ACCELERATION if is_on_floor() else Tune.AIR_ACCELERATION
	if direction.length_squared() > 0.0:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, Tune.DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, Tune.DECELERATION * delta)
	if not is_on_floor():
		velocity.y -= Tune.GRAVITY * delta
	elif Input.is_action_just_pressed("jump") and not crouching and not menu_open:
		velocity.y = Tune.JUMP_VELOCITY
	_bob_time += delta * Vector2(velocity.x, velocity.z).length()
	var bob := sin(_bob_time * Tune.BOB_FREQUENCY) * Tune.BOB_AMPLITUDE * float(settings.get("bob_intensity", Tune.DEFAULT_BOB_INTENSITY))
	camera.position.y += bob if is_on_floor() and direction.length_squared() > 0.0 else 0.0
	_step_timer -= delta
	if is_on_floor() and direction.length_squared() > 0.0 and _step_timer <= 0.0:
		_step_timer = Tune.FOOTSTEP_INTERVAL * (0.72 if sprinting else 1.0)
		game.feedback.cue("step_sand")

func _update_interaction(delta: float) -> void:
	if menu_open or build_mode:
		active_target = null
		hold_target = null
		hold_progress = 0.0
		game.hud.set_prompt("")
		return
	var hit := _raycast(Tune.INTERACT_RANGE, 3)
	var target: Node = hit.get("collider")
	active_target_distance = float(hit.get("position", global_position).distance_to(camera.global_position)) if not hit.is_empty() else 999.0
	if target and target.has_method("interaction_label"):
		active_target = target
		var label := str(target.interaction_label(self))
		var hold_duration := float(target.interaction_hold_duration())
		var suffix := " [Hold E]" if hold_duration > 0.0 else " [E]"
		if target.has_method("strike"):
			suffix = " [Primary]"
		game.hud.set_prompt(label + suffix)
	else:
		active_target = null
		game.hud.set_prompt("")
	if Input.is_action_just_pressed("interact") and active_target:
		var duration := float(active_target.interaction_hold_duration())
		if duration <= 0.0:
			_complete_interaction(active_target)
		else:
			hold_target = active_target
			hold_progress = 0.0
	if Input.is_action_pressed("interact") and hold_target:
		if not is_instance_valid(hold_target) or hold_target != active_target or active_target_distance > Tune.INTERACT_CANCEL_DISTANCE:
			_cancel_hold("Interaction cancelled — moved out of range.")
		else:
			var duration := maxf(0.01, float(hold_target.interaction_hold_duration()))
			hold_progress += delta
			game.hud.set_interaction_progress(hold_progress / duration)
			if hold_progress >= duration:
				var completed := hold_target
				hold_target = null
				hold_progress = 0.0
				game.hud.set_interaction_progress(0.0)
				_complete_interaction(completed)
	elif hold_target:
		_cancel_hold("Interaction cancelled.")
	if Input.is_action_just_pressed("primary_action") and active_target and active_target.has_method("strike") and _tool_cooldown <= 0.0:
		_tool_cooldown = Tune.TOOL_STRIKE_COOLDOWN
		var result: Dictionary = active_target.strike(game, self, game.is_tool_equipped(selected_hotbar))
		game.notify_player(str(result.get("message", "")), "impact_wood" if active_target.item_id == "driftwood" else "impact_stone")

func _complete_interaction(target: Node) -> void:
	if not is_instance_valid(target):
		return
	var result: Dictionary = target.interact(game, self)
	game.notify_player(str(result.get("message", "")), "pickup" if bool(result.get("ok", false)) else "fail")

func _cancel_hold(message: String) -> void:
	hold_target = null
	hold_progress = 0.0
	game.hud.set_interaction_progress(0.0)
	game.notify_player(message, "fail")

func _raycast(distance: float, mask: int) -> Dictionary:
	var from := camera.global_position
	var to := from + -camera.global_basis.z * distance
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, [get_rid()])
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query)

func set_build_mode(enabled: bool) -> void:
	if enabled and game.inventory.count("building_plan") <= 0 and game.inventory.count("campfire_kit") <= 0:
		game.notify_player("Craft a building plan or campfire kit first.", "fail")
		return
	build_mode = enabled
	build_preview.visible = enabled
	game.hud.set_build_status(enabled, build_piece_id, false)
	if enabled:
		game.notify_player("Build mode · wheel cycles pieces · Q/R rotate", "confirm")

func _select_build_piece(piece: String) -> void:
	build_piece_id = piece
	_refresh_preview_mesh()
	game.hud.set_build_status(true, build_piece_id, build_valid)

func _create_build_preview() -> void:
	build_preview = MeshInstance3D.new()
	build_preview.name = "Build Preview"
	build_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	build_preview.visible = false
	get_parent().call_deferred("add_child", build_preview)
	call_deferred("_refresh_preview_mesh")

func _refresh_preview_mesh() -> void:
	if build_preview == null:
		return
	var definition := BuildingDB.get_piece(build_piece_id)
	var mesh := BoxMesh.new()
	mesh.size = definition.get("size", Vector3.ONE)
	mesh.material = PrototypeFactory.material(Tune.BUILD_INVALID_COLOR)
	build_preview.mesh = mesh

func _update_build_preview() -> void:
	if not build_mode or build_preview == null:
		return
	var hit := _raycast(Tune.BUILD_RANGE, 1)
	if hit.is_empty():
		build_valid = false
		build_preview.visible = false
		game.hud.set_build_status(true, build_piece_id, false)
		return
	build_preview.visible = true
	if Input.is_action_just_pressed("build_cycle"):
		_select_build_piece(BuildingDB.next_piece(build_piece_id, 1))
	if Input.is_action_just_pressed("rotate_left"):
		build_rotation -= deg_to_rad(Tune.BUILD_ROTATION_STEP_DEGREES)
	if Input.is_action_just_pressed("rotate_right"):
		build_rotation += deg_to_rad(Tune.BUILD_ROTATION_STEP_DEGREES)
	var result: Dictionary = game.get_build_preview(build_piece_id, hit.position, hit.normal, build_rotation, global_position)
	build_preview.transform = result.get("transform", Transform3D.IDENTITY)
	build_valid = bool(result.get("valid", false))
	build_parent_id = str(result.get("parent_id", ""))
	var material_override: StandardMaterial3D = build_preview.mesh.material
	material_override.albedo_color = Tune.BUILD_VALID_COLOR if build_valid else Tune.BUILD_INVALID_COLOR
	game.hud.set_build_status(true, build_piece_id, build_valid, str(result.get("reason", "")))
	if Input.is_action_just_pressed("primary_action"):
		if build_valid:
			game.place_build(build_piece_id, build_preview.transform, build_parent_id)
		else:
			game.notify_player(str(result.get("reason", "Invalid placement")), "fail")

func set_menu_open(open: bool) -> void:
	menu_open = open
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED

func select_hotbar(index: int) -> void:
	selected_hotbar = clampi(index, 0, Tune.HOTBAR_SLOTS - 1)
	if game and game.hud:
		game.hud.set_hotbar_selection(selected_hotbar)

func apply_settings(new_settings: Dictionary) -> void:
	settings.merge(new_settings, true)

func world_transform_data() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"rotation_y": rotation.y,
		"settings": settings.duplicate(true)
	}
