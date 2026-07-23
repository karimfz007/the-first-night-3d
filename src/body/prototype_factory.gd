class_name PrototypeFactory
extends RefCounted

static func material(color: Color, roughness: float = 0.82, emission: Color = Color.TRANSPARENT) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	if color.a < 0.999:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if emission.a > 0.0:
		result.emission_enabled = true
		result.emission = emission
		result.emission_energy_multiplier = 1.5
	return result

static func mesh_instance(mesh: PrimitiveMesh, color: Color, node_name: String = "Mesh") -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	mesh.material = material(color)
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance

static func static_box(parent: Node, node_name: String, position: Vector3, size: Vector3, color: Color, rotation_degrees: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.rotation_degrees = rotation_degrees
	body.collision_layer = 1
	body.collision_mask = 0
	var mesh := BoxMesh.new()
	mesh.size = size
	body.add_child(mesh_instance(mesh, color))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body

static func visual_box(parent: Node, node_name: String, position: Vector3, size: Vector3, color: Color, rotation_degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := mesh_instance(mesh, color, node_name)
	instance.position = position
	instance.rotation_degrees = rotation_degrees
	parent.add_child(instance)
	return instance

static func static_cylinder(parent: Node, node_name: String, position: Vector3, radius: float, height: float, color: Color, rotation_degrees: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.rotation_degrees = rotation_degrees
	body.collision_layer = 1
	body.collision_mask = 0
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	body.add_child(mesh_instance(mesh, color))
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body

static func add_collision(body: CollisionObject3D, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

