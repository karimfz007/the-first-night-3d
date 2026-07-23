class_name Inspectable
extends StaticBody3D

var prompt := "Inspect"
var message := ""

func configure(id_value: String, prompt_value: String, message_value: String, position_value: Vector3) -> Inspectable:
	name = id_value
	prompt = prompt_value
	message = message_value
	position = position_value
	return self

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.36, 0.1, 0.36)
	add_child(PrototypeFactory.mesh_instance(mesh, Color(0.12, 0.13, 0.11)))
	PrototypeFactory.add_collision(self, mesh.size)

func interaction_label(_player: Node) -> String:
	return prompt

func interaction_hold_duration() -> float:
	return 0.35

func interact(_game: Node, _player: Node) -> Dictionary:
	return {"ok": true, "message": message}

