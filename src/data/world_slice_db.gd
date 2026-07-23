class_name WorldSliceDB
extends RefCounted
## Authored resource placement for DRIFT vertical slice 0.1.

const RESOURCES := [
	["loose_wood_01", "loose", "driftwood", 2, Vector3(-3, 0.18, 13), Vector3(0, 20, 0)],
	["loose_wood_02", "loose", "driftwood", 2, Vector3(3, 0.18, 10), Vector3(0, -35, 0)],
	["loose_wood_03", "loose", "driftwood", 2, Vector3(-9, 0.18, 7), Vector3(0, 55, 0)],
	["loose_wood_04", "loose", "driftwood", 2, Vector3(12, 0.18, 6), Vector3(0, 10, 0)],
	["stone_01", "loose", "stone", 2, Vector3(-1, 0.2, 18), Vector3.ZERO],
	["stone_02", "loose", "stone", 2, Vector3(6, 0.2, 15), Vector3.ZERO],
	["stone_03", "loose", "stone", 2, Vector3(-8, 0.2, 18), Vector3.ZERO],
	["fiber_01", "fiber", "plant_fiber", 6, Vector3(2, 0.25, 25), Vector3.ZERO],
	["fiber_02", "fiber", "plant_fiber", 6, Vector3(10, 0.25, 27), Vector3.ZERO],
	["fiber_03", "fiber", "plant_fiber", 6, Vector3(-7, 0.25, 28), Vector3.ZERO],
	["fiber_04", "fiber", "plant_fiber", 6, Vector3(16, 0.25, 24), Vector3.ZERO],
	["deadfall_01", "deadfall", "deadfall", 5, Vector3(-15, 0.3, 21), Vector3(0, 22, 0)],
	["tree_node_01", "tree", "driftwood", 24, Vector3(18, 0, 31), Vector3.ZERO],
	["tree_node_02", "tree", "driftwood", 24, Vector3(-18, 0, 34), Vector3.ZERO],
	["rock_node_01", "rock", "stone", 20, Vector3(25, 0.8, 22), Vector3(0, 18, 0)],
	["rock_node_02", "rock", "stone", 20, Vector3(-31, 0.8, 20), Vector3(0, -12, 0)]
]

static func total_item(item_id: String) -> int:
	var total := 0
	for resource: Array in RESOURCES:
		if str(resource[2]) == item_id:
			total += int(resource[3])
	return total

static func get_resource(save_id: String) -> Array:
	for resource: Array in RESOURCES:
		if str(resource[0]) == save_id:
			return resource.duplicate(true)
	return []
