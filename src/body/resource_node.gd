class_name ResourceNode
extends StaticBody3D

var save_id: String = ""
var item_id: String = "driftwood"
var quantity: int = 1
var node_kind: String = "loose"
var hold_seconds: float = Tune.LOOSE_PICKUP_HOLD
var required_tool: bool = false
var depleted := false
var _base_color := Color(0.4, 0.28, 0.14)

func configure(id_value: String, kind: String, item: String, amount: int, position_value: Vector3, rotation_value: Vector3 = Vector3.ZERO) -> ResourceNode:
	save_id = id_value
	node_kind = kind
	item_id = item
	quantity = maxi(0, amount)
	position = position_value
	rotation_degrees = rotation_value
	required_tool = kind in ["tree", "rock"]
	hold_seconds = Tune.SALVAGE_HOLD_SECONDS if kind == "deadfall" else Tune.LOOSE_PICKUP_HOLD
	return self

func _ready() -> void:
	name = save_id
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")
	_create_shape()
	if quantity <= 0:
		depleted = true
		visible = false
		collision_layer = 0

func _create_shape() -> void:
	var mesh: PrimitiveMesh
	var collision_size: Vector3
	match node_kind:
		"tree":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.34
			cylinder.bottom_radius = 0.48
			cylinder.height = 5.5
			mesh = cylinder
			collision_size = Vector3(0.9, 5.5, 0.9)
			_base_color = Color(0.25, 0.14, 0.07)
		"rock":
			var sphere := SphereMesh.new()
			sphere.radius = 1.15
			sphere.height = 1.65
			mesh = sphere
			collision_size = Vector3(2.2, 1.65, 2.0)
			_base_color = Color(0.31, 0.34, 0.34)
		"fiber":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.3
			cylinder.bottom_radius = 0.5
			cylinder.height = 0.5
			mesh = cylinder
			collision_size = Vector3(0.8, 0.5, 0.8)
			_base_color = Color(0.24, 0.45, 0.22)
		"deadfall":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.18
			cylinder.bottom_radius = 0.26
			cylinder.height = 2.8
			mesh = cylinder
			collision_size = Vector3(0.55, 2.8, 0.55)
			_base_color = Color(0.35, 0.22, 0.1)
		_:
			var box := BoxMesh.new()
			box.size = Vector3(0.75, 0.22, 0.28) if item_id == "driftwood" else Vector3(0.38, 0.28, 0.38)
			mesh = box
			collision_size = box.size
			_base_color = Color(0.5, 0.32, 0.13) if item_id == "driftwood" else Color(0.42, 0.44, 0.43)
	var instance := PrototypeFactory.mesh_instance(mesh, _base_color)
	if node_kind == "deadfall":
		instance.rotation_degrees.z = 90.0
	add_child(instance)
	if node_kind == "tree":
		instance.position.y = 2.75
		var crown := SphereMesh.new()
		crown.radius = 2.1
		crown.height = 3.5
		var crown_mesh := PrototypeFactory.mesh_instance(crown, Color(0.08, 0.24, 0.13), "Palm Crown")
		crown_mesh.position.y = 5.45
		add_child(crown_mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.shape = shape
	collision.position.y = collision_size.y * 0.5 if node_kind in ["tree", "fiber"] else 0.0
	if node_kind == "deadfall":
		collision.rotation_degrees.z = 90.0
	add_child(collision)

func interaction_label(_player: Node) -> String:
	if depleted:
		return ""
	var verb := "Salvage" if hold_seconds > 0.0 else "Pick up"
	if required_tool:
		verb = "Strike"
	return "%s %s" % [verb, ItemDB.display_name(item_id)]

func interaction_hold_duration() -> float:
	return hold_seconds

func interact(game: Node, _player: Node) -> Dictionary:
	if depleted:
		return {"ok": false, "message": "Nothing remains."}
	if required_tool:
		return {"ok": false, "message": "Use a tool action to harvest this."}
	var amount := 1 if node_kind == "loose" else mini(quantity, 2)
	var result: Dictionary = game.receive_item(item_id, amount, global_position)
	var accepted := int(result.get("accepted", 0))
	if accepted <= 0:
		return {"ok": false, "message": "Inventory full — item left in the world."}
	quantity -= accepted
	game.resource_changed(save_id, quantity)
	if quantity <= 0:
		_deplete()
	return {"ok": true, "message": "+%d %s" % [accepted, ItemDB.display_name(item_id)]}

func strike(game: Node, _player: Node, tool_equipped: bool) -> Dictionary:
	if depleted:
		return {"ok": false, "message": "Depleted."}
	var yield_amount := Tune.TOOL_YIELD if tool_equipped else Tune.BARE_HAND_YIELD
	if not tool_equipped:
		yield_amount = Tune.BARE_HAND_YIELD
	var accepted_result: Dictionary = game.receive_item(item_id, mini(yield_amount, quantity), global_position)
	var accepted := int(accepted_result.get("accepted", 0))
	if accepted <= 0:
		return {"ok": false, "message": "Inventory full."}
	quantity -= accepted
	game.resource_changed(save_id, quantity)
	if quantity <= 0:
		_deplete()
	var resistance := "The tool bites cleanly." if tool_equipped else "Bare hands barely loosen it."
	return {"ok": true, "message": "%s  +%d %s" % [resistance, accepted, ItemDB.display_name(item_id)]}

func _deplete() -> void:
	depleted = true
	visible = false
	collision_layer = 0

