class_name BuildRecord
extends RefCounted

static func create(save_id: String, piece_id: String, owner_id: String, transform: Transform3D, parent_id: String = "") -> Dictionary:
	var definition := BuildingDB.get_piece(piece_id)
	return {
		"save_id": save_id,
		"piece_id": piece_id,
		"owner_id": owner_id,
		"parent_id": parent_id,
		"transform": {
			"origin": [transform.origin.x, transform.origin.y, transform.origin.z],
			"basis_x": [transform.basis.x.x, transform.basis.x.y, transform.basis.x.z],
			"basis_y": [transform.basis.y.x, transform.basis.y.y, transform.basis.y.z],
			"basis_z": [transform.basis.z.x, transform.basis.z.y, transform.basis.z.z]
		},
		"health": float(definition.get("health", Tune.BUILD_DEFAULT_HEALTH)),
		"tier": int(definition.get("tier", 0)),
		"upkeep_category": str(definition.get("upkeep_category", "")),
		"decay_resistance": float(definition.get("decay_resistance", 0.0)),
		"protection": float(definition.get("protection", 0.0)),
		"damage_hook": {},
		"repair_hook": {},
		"demolish_hook": {}
	}

static func transform_from(record: Dictionary) -> Transform3D:
	var data: Dictionary = record.get("transform", {})
	var bx := _vector(data.get("basis_x", [1, 0, 0]), Vector3.RIGHT)
	var by := _vector(data.get("basis_y", [0, 1, 0]), Vector3.UP)
	var bz := _vector(data.get("basis_z", [0, 0, 1]), Vector3.BACK)
	return Transform3D(Basis(bx, by, bz), _vector(data.get("origin", [0, 0, 0]), Vector3.ZERO))

static func _vector(raw: Variant, fallback: Vector3) -> Vector3:
	if raw is Array and raw.size() >= 3:
		return Vector3(
			Tune.finite_number(raw[0], fallback.x),
			Tune.finite_number(raw[1], fallback.y),
			Tune.finite_number(raw[2], fallback.z)
		)
	return fallback

