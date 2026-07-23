class_name ItemDB
extends RefCounted

const ITEMS := {
	"driftwood": {
		"id": "driftwood", "name": "Driftwood", "icon": "▰", "stack_limit": 50,
		"weight": 0.55, "tags": ["wood", "fuel", "resource"],
		"world_model": "", "use_behavior": "fuel"
	},
	"deadfall": {
		"id": "deadfall", "name": "Deadfall", "icon": "╱", "stack_limit": 30,
		"weight": 0.8, "tags": ["wood", "fuel", "resource"],
		"world_model": "", "use_behavior": "fuel"
	},
	"stone": {
		"id": "stone", "name": "Stone", "icon": "◆", "stack_limit": 50,
		"weight": 0.7, "tags": ["stone", "resource"],
		"world_model": "", "use_behavior": ""
	},
	"plant_fiber": {
		"id": "plant_fiber", "name": "Plant Fiber", "icon": "≋", "stack_limit": 80,
		"weight": 0.08, "tags": ["fiber", "resource"],
		"world_model": "", "use_behavior": ""
	},
	"stone_tool": {
		"id": "stone_tool", "name": "Primitive Stone Tool", "icon": "⛏",
		"stack_limit": 1, "weight": 1.4, "tags": ["tool", "axe", "pick"],
		"world_model": "", "use_behavior": "harvest"
	},
	"building_plan": {
		"id": "building_plan", "name": "Building Plan", "icon": "⌂",
		"stack_limit": 1, "weight": 0.2, "tags": ["tool", "building"],
		"world_model": "", "use_behavior": "build"
	},
	"campfire_kit": {
		"id": "campfire_kit", "name": "Campfire Kit", "icon": "♨",
		"stack_limit": 4, "weight": 1.0, "tags": ["building", "fire"],
		"world_model": "", "use_behavior": "place_campfire"
	}
}

static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {}).duplicate(true)

static func exists(item_id: String) -> bool:
	return ITEMS.has(item_id)

static func display_name(item_id: String) -> String:
	return str(ITEMS.get(item_id, {"name": item_id}).get("name", item_id))

static func stack_limit(item_id: String) -> int:
	return maxi(1, int(ITEMS.get(item_id, {"stack_limit": 1}).get("stack_limit", 1)))

static func has_tag(item_id: String, tag: String) -> bool:
	return tag in ITEMS.get(item_id, {}).get("tags", [])

