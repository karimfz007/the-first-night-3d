class_name WorldBuilder
extends Node3D

var game: Node

func build(game_node: Node, resource_state: Dictionary) -> void:
	game = game_node
	_create_environment()
	_create_land()
	_create_authored_landmarks()
	_create_resources(resource_state)

func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "Dusk Environment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.025, 0.05, 0.12)
	sky_material.sky_horizon_color = Color(0.83, 0.28, 0.12)
	sky_material.ground_bottom_color = Color(0.015, 0.02, 0.025)
	sky_material.ground_horizon_color = Color(0.34, 0.15, 0.09)
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.08
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.48
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.2, 0.24, 0.29)
	environment.fog_light_energy = 0.55
	environment.fog_density = Tune.FOG_DENSITY
	environment.fog_sky_affect = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Dusk Sun"
	sun.rotation_degrees = Vector3(-18.0, -32.0, 0.0)
	sun.light_color = Color(1.0, 0.55, 0.34)
	sun.light_energy = Tune.SUN_ENERGY
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = Tune.SHADOW_DISTANCE
	add_child(sun)
	sun.add_to_group("sun")

func _create_land() -> void:
	PrototypeFactory.static_box(self, "Beach", Vector3(0, -0.5, 0), Tune.BEACH_SIZE, Color(0.62, 0.47, 0.27))
	PrototypeFactory.static_box(self, "Treeline Ground", Vector3(0, -0.35, 56), Tune.TREELINE_SIZE, Color(0.105, 0.22, 0.11))
	var water := PrototypeFactory.static_box(self, "Shallow Water Boundary", Vector3(0, -0.72, -62), Tune.WATER_SIZE, Color(0.035, 0.23, 0.32, 0.72))
	water.collision_layer = 1
	for index in range(10):
		var x := -48.0 + float(index) * 10.5
		var z := 28.0 + sin(float(index) * 1.7) * 7.0
		_create_palm(Vector3(x, 0.0, z), 0.8 + fposmod(float(index) * 0.17, 0.4))
	for index in range(7):
		var x := -42.0 + float(index) * 14.0
		var z := 48.0 + cos(float(index) * 1.2) * 5.0
		_create_palm(Vector3(x, 0.0, z), 0.75 + fposmod(float(index) * 0.13, 0.35))

func _create_palm(position_value: Vector3, scale_value: float) -> void:
	var trunk := PrototypeFactory.static_cylinder(self, "Palm", position_value + Vector3.UP * (3.3 * scale_value), 0.32 * scale_value, 6.6 * scale_value, Color(0.27, 0.16, 0.07), Vector3(0, 0, 3.0))
	var crown := SphereMesh.new()
	crown.radius = 2.1 * scale_value
	crown.height = 2.2 * scale_value
	var leaves := PrototypeFactory.mesh_instance(crown, Color(0.045, 0.19, 0.085), "Palm Leaves")
	leaves.position.y = 3.5 * scale_value
	trunk.add_child(leaves)

func _create_authored_landmarks() -> void:
	# A raised black-rock lookout on the east edge.
	PrototypeFactory.static_box(self, "Lookout Rock", Vector3(36, 1.0, 24), Vector3(10, 3, 8), Color(0.18, 0.20, 0.20), Vector3(0, 15, -7))
	PrototypeFactory.static_box(self, "Lookout Step", Vector3(30.5, 0.25, 22), Vector3(4, 1.2, 4), Color(0.2, 0.21, 0.2))
	# Weathered wreck ribs create a vertical silhouette and shelter landmark.
	for index in range(5):
		PrototypeFactory.static_box(
			self, "Wreck Rib %d" % index,
			Vector3(-27.0 + index * 1.8, 2.1 + abs(index - 2) * 0.22, 10.0 + sin(index) * 0.5),
			Vector3(0.32, 5.0, 1.0), Color(0.16, 0.095, 0.045),
			Vector3(0, 4.0 * index, -18.0 + index * 7.0)
		)
	PrototypeFactory.static_box(self, "Wreck Spine", Vector3(-23.5, 0.8, 10.5), Vector3(10, 0.45, 1.0), Color(0.13, 0.075, 0.035), Vector3(0, 8, -8))
	var clue := Inspectable.new().configure("wreck_compass", "Inspect fused compass", GameStrings.get_text("clue"), Vector3(-23.3, 1.25, 9.7))
	add_child(clue)
	# Flat, readable shelter location framed with a few stones.
	for point in [Vector3(8, 0.15, 13), Vector3(14, 0.15, 13), Vector3(8, 0.15, 20), Vector3(14, 0.15, 20)]:
		var stone := SphereMesh.new()
		stone.radius = 0.22
		stone.height = 0.3
		var marker := PrototypeFactory.mesh_instance(stone, Color(0.34, 0.33, 0.29), "Shelter Site Stone")
		marker.position = point
		add_child(marker)

func _create_resources(saved: Dictionary) -> void:
	for raw: Array in WorldSliceDB.RESOURCES:
		var saved_value: Variant = saved.get(str(raw[0]), {})
		var amount := int(saved_value.get("quantity", raw[3])) if saved_value is Dictionary else int(saved_value)
		var node := ResourceNode.new().configure(str(raw[0]), str(raw[1]), str(raw[2]), amount, raw[4], raw[5])
		add_child(node)
		game.register_resource(node)
	for save_id: String in saved:
		if game.resource_nodes.has(save_id):
			continue
		var record: Variant = saved[save_id]
		if record is not Dictionary or not bool(record.get("dynamic", false)):
			continue
		var position_value := _vector(record.get("position", [0.0, 0.25, 0.0]))
		var rotation_value := _vector(record.get("rotation_degrees", [0.0, 0.0, 0.0]))
		var node := ResourceNode.new().configure(
			save_id,
			str(record.get("kind", "loose")),
			str(record.get("item_id", "")),
			maxi(0, int(record.get("quantity", 0))),
			position_value,
			rotation_value
		)
		add_child(node)
		game.register_resource(node)

func _vector(raw: Variant) -> Vector3:
	if raw is Array and raw.size() >= 3:
		return Vector3(
			Tune.finite_number(raw[0], 0.0),
			Tune.finite_number(raw[1], 0.0),
			Tune.finite_number(raw[2], 0.0)
		)
	return Vector3.ZERO
