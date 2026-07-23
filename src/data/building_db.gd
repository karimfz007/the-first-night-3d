class_name BuildingDB
extends RefCounted

const ORDER := ["foundation", "wall", "doorway", "door", "roof", "campfire"]

const PIECES := {
	"foundation": {
		"id": "foundation", "name": "Foundation",
		"size": Vector3(4.0, 0.35, 4.0), "cost": {"driftwood": 6},
		"snap": "floor", "tier": 0, "health": 100.0, "upkeep_category": "wood",
		"decay_resistance": 0.2, "protection": 0.08
	},
	"wall": {
		"id": "wall", "name": "Wall",
		"size": Vector3(4.0, 2.7, 0.24), "cost": {"driftwood": 4, "plant_fiber": 1},
		"snap": "wall", "tier": 0, "health": 80.0, "upkeep_category": "wood",
		"decay_resistance": 0.15, "protection": 0.18
	},
	"doorway": {
		"id": "doorway", "name": "Doorway Frame",
		"size": Vector3(4.0, 2.7, 0.28), "cost": {"driftwood": 4, "plant_fiber": 1},
		"snap": "wall", "tier": 0, "health": 75.0, "upkeep_category": "wood",
		"decay_resistance": 0.15, "protection": 0.12
	},
	"door": {
		"id": "door", "name": "Simple Door",
		"size": Vector3(1.45, 2.25, 0.18), "cost": {"driftwood": 3, "plant_fiber": 2},
		"snap": "door", "tier": 0, "health": 60.0, "upkeep_category": "wood",
		"decay_resistance": 0.12, "protection": 0.15
	},
	"roof": {
		"id": "roof", "name": "Roof",
		"size": Vector3(4.0, 0.28, 4.0), "cost": {"driftwood": 5, "plant_fiber": 3},
		"snap": "roof", "tier": 0, "health": 70.0, "upkeep_category": "thatch",
		"decay_resistance": 0.1, "protection": 0.28
	},
	"campfire": {
		"id": "campfire", "name": "Campfire",
		"size": Vector3(1.2, 0.45, 1.2), "cost": {"campfire_kit": 1},
		"snap": "ground", "tier": 0, "health": 50.0, "upkeep_category": "none",
		"decay_resistance": 1.0, "protection": 0.0
	}
}

static func get_piece(piece_id: String) -> Dictionary:
	return PIECES.get(piece_id, {}).duplicate(true)

static func next_piece(current: String, direction: int = 1) -> String:
	var index := ORDER.find(current)
	if index < 0:
		return ORDER[0]
	return ORDER[posmod(index + direction, ORDER.size())]

