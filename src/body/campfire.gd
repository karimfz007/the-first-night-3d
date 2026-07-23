class_name Campfire
extends StaticBody3D

var save_id := ""
var fuel := 0.0
var lit := false
var owner_id := Tune.OWNER_ID
var _light: OmniLight3D
var _flame: MeshInstance3D
var _smoke: GPUParticles3D

func configure(id_value: String, transform_value: Transform3D, fire_data: Dictionary = {}) -> Campfire:
	save_id = id_value
	transform = transform_value
	fuel = clampf(Tune.finite_number(fire_data.get("fuel"), 0.0), 0.0, Tune.FIRE_FUEL_MAX)
	lit = bool(fire_data.get("lit", false)) and fuel > 0.0
	owner_id = str(fire_data.get("owner_id", Tune.OWNER_ID))
	return self

func _ready() -> void:
	name = save_id
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")
	add_to_group("campfire")
	for angle in [0.0, 60.0, 120.0]:
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.11
		log_mesh.bottom_radius = 0.14
		log_mesh.height = 1.0
		var log_instance := PrototypeFactory.mesh_instance(log_mesh, Color(0.26, 0.12, 0.045), "Firewood")
		log_instance.position.y = 0.15
		log_instance.rotation_degrees = Vector3(90.0, angle, 0.0)
		add_child(log_instance)
	var ring := CylinderMesh.new()
	ring.top_radius = 0.62
	ring.bottom_radius = 0.7
	ring.height = 0.16
	var ring_instance := PrototypeFactory.mesh_instance(ring, Color(0.29, 0.3, 0.29), "Stone Ring")
	ring_instance.position.y = 0.06
	add_child(ring_instance)
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.22
	flame_mesh.height = 0.9
	_flame = PrototypeFactory.mesh_instance(flame_mesh, Color(1.0, 0.36, 0.05), "Flame")
	_flame.position.y = 0.55
	_flame.material_override = PrototypeFactory.material(Color(1.0, 0.34, 0.04), 0.6, Color(1.0, 0.17, 0.015, 1.0))
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.name = "Fire Light"
	_light.position.y = 0.75
	_light.light_color = Color(1.0, 0.47, 0.18)
	_light.light_energy = Tune.FIRE_LIGHT_ENERGY
	_light.omni_range = Tune.FIRE_LIGHT_RANGE
	_light.shadow_enabled = false
	add_child(_light)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.72
	shape.height = 0.45
	collision.shape = shape
	collision.position.y = 0.2
	add_child(collision)
	_create_smoke()
	_update_visual()

func _create_smoke() -> void:
	_smoke = GPUParticles3D.new()
	_smoke.name = "Smoke"
	_smoke.position.y = 0.9
	_smoke.amount = 14
	_smoke.lifetime = 2.6
	_smoke.visibility_aabb = AABB(Vector3(-2, 0, -2), Vector3(4, 7, 4))
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.UP
	material.spread = 14.0
	material.initial_velocity_min = 0.65
	material.initial_velocity_max = 1.15
	material.gravity = Vector3(0.08, 0.18, 0.02)
	material.scale_min = 0.18
	material.scale_max = 0.42
	material.color = Color(0.28, 0.29, 0.3, 0.28)
	_smoke.process_material = material
	var smoke_mesh := QuadMesh.new()
	smoke_mesh.size = Vector2(0.45, 0.45)
	smoke_mesh.material = PrototypeFactory.material(Color(0.34, 0.35, 0.36, 0.28))
	_smoke.draw_pass_1 = smoke_mesh
	add_child(_smoke)

func _process(delta: float) -> void:
	if not lit:
		return
	fuel = maxf(0.0, fuel - Tune.FIRE_BURN_PER_WORLD_SECOND * Tune.WORLD_TIME_SCALE * delta)
	if fuel <= 0.0:
		lit = false
		_update_visual()
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.notify_player("The campfire gutters out.", "fail")
	if _flame:
		_flame.scale.y = 0.85 + sin(Time.get_ticks_msec() * 0.011) * 0.12

func interaction_label(_player: Node) -> String:
	if lit:
		return "Add fuel · Action extinguishes · %s" % fuel_text()
	if fuel > 0.0:
		return "Ignite campfire"
	return "Add wood to campfire"

func interaction_hold_duration() -> float:
	return 0.45

func interact(game: Node, _player: Node) -> Dictionary:
	if fuel <= 0.0:
		if not game.consume_wood_for_fire():
			return {"ok": false, "message": "Need driftwood or deadfall for fuel."}
		fuel = minf(Tune.FIRE_FUEL_MAX, fuel + Tune.FIRE_FUEL_PER_WOOD)
		return {"ok": true, "message": "Dry wood rests inside the stone ring."}
	if not lit:
		lit = true
		_update_visual()
		game.feedback.cue("ignite")
		return {"ok": true, "message": "The fire catches. Warmth reaches your hands."}
	if game.consume_wood_for_fire():
		fuel = minf(Tune.FIRE_FUEL_MAX, fuel + Tune.FIRE_FUEL_PER_WOOD)
		return {"ok": true, "message": "Fuel added · %s" % fuel_text()}
	return {"ok": false, "message": "No wood available."}

func strike(_game: Node, _player: Node, _tool_equipped: bool) -> Dictionary:
	if not lit:
		return {"ok": false, "message": "The campfire is already out."}
	lit = false
	_update_visual()
	return {"ok": true, "message": "The flames are smothered; the remaining fuel is preserved."}

func is_heating(point: Vector3) -> bool:
	return lit and global_position.distance_to(point) <= Tune.FIRE_HEAT_RADIUS

func fuel_text() -> String:
	return "%d%% fuel" % roundi((fuel / Tune.FIRE_FUEL_MAX) * 100.0)

func to_fire_record() -> Dictionary:
	return {
		"save_id": save_id,
		"owner_id": owner_id,
		"fuel": fuel,
		"lit": lit,
		"position": [global_position.x, global_position.y, global_position.z]
	}

func _update_visual() -> void:
	if _flame:
		_flame.visible = lit
	if _light:
		_light.visible = lit
	if _smoke:
		_smoke.emitting = lit
