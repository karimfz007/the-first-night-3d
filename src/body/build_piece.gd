class_name BuildPiece
extends StaticBody3D

var record: Dictionary = {}
var piece_id := "foundation"
var save_id := ""

func configure(record_value: Dictionary) -> BuildPiece:
	record = record_value.duplicate(true)
	piece_id = str(record.get("piece_id", "foundation"))
	save_id = str(record.get("save_id", ""))
	transform = BuildRecord.transform_from(record)
	return self

func _ready() -> void:
	name = save_id
	collision_layer = 1
	collision_mask = 0
	add_to_group("build_piece")
	var definition := BuildingDB.get_piece(piece_id)
	var size: Vector3 = definition.get("size", Vector3.ONE)
	_make_visual(size)
	PrototypeFactory.add_collision(self, size)

func _make_visual(size: Vector3) -> void:
	var wood := Color(0.34, 0.20, 0.09)
	match piece_id:
		"doorway":
			var side_size := Vector3(1.15, size.y, size.z)
			PrototypeFactory.visual_box(self, "Left Post", Vector3(-1.42, 0.0, 0.0), side_size, wood)
			PrototypeFactory.visual_box(self, "Right Post", Vector3(1.42, 0.0, 0.0), side_size, wood)
			PrototypeFactory.visual_box(self, "Header", Vector3(0.0, 1.1, 0.0), Vector3(1.7, 0.48, size.z), wood)
		"door":
			var mesh := BoxMesh.new()
			mesh.size = size
			add_child(PrototypeFactory.mesh_instance(mesh, Color(0.28, 0.15, 0.065)))
			var handle := SphereMesh.new()
			handle.radius = 0.07
			handle.height = 0.14
			var handle_instance := PrototypeFactory.mesh_instance(handle, Color(0.5, 0.46, 0.34), "Handle")
			handle_instance.position = Vector3(size.x * 0.35, 0.0, -size.z * 0.6)
			add_child(handle_instance)
		"roof":
			var mesh := BoxMesh.new()
			mesh.size = size
			add_child(PrototypeFactory.mesh_instance(mesh, Color(0.31, 0.29, 0.12)))
			rotation_degrees.z += 3.5
		_:
			var mesh := BoxMesh.new()
			mesh.size = size
			add_child(PrototypeFactory.mesh_instance(mesh, wood))
			if piece_id == "wall":
				for x in [-1.5, -0.5, 0.5, 1.5]:
					PrototypeFactory.visual_box(self, "Wall Bind", Vector3(x, 0.0, -size.z * 0.58), Vector3(0.08, size.y, 0.07), Color(0.48, 0.34, 0.15))

func interaction_label(_player: Node) -> String:
	return "%s · %d%%" % [BuildingDB.get_piece(piece_id).get("name", piece_id), roundi(float(record.get("health", 0.0)))]

func interaction_hold_duration() -> float:
	return 0.0

func interact(_game: Node, _player: Node) -> Dictionary:
	return {"ok": true, "message": "Owned by you · repair and demolish hooks ready"}

func to_record() -> Dictionary:
	record["transform"] = BuildRecord.create(save_id, piece_id, str(record.get("owner_id", Tune.OWNER_ID)), transform, str(record.get("parent_id", ""))).transform
	return record.duplicate(true)

