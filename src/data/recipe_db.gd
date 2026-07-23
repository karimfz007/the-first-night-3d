class_name RecipeDB
extends RefCounted

const RECIPES := {
	"primitive_stone_tool": {
		"id": "primitive_stone_tool",
		"name": "Primitive Stone Tool",
		"ingredients": {"driftwood": 2, "stone": 3, "plant_fiber": 2},
		"output": {"item_id": "stone_tool", "quantity": 1},
		"duration": Tune.CRAFT_TOOL_SECONDS,
		"knowledge": "",
		"required_tool": "",
		"required_station": ""
	},
	"campfire": {
		"id": "campfire",
		"name": "Campfire Kit",
		"ingredients": {"driftwood": 5, "stone": 4},
		"output": {"item_id": "campfire_kit", "quantity": 1},
		"duration": Tune.CRAFT_FIRE_SECONDS,
		"knowledge": "",
		"required_tool": "",
		"required_station": ""
	},
	"building_plan": {
		"id": "building_plan",
		"name": "Building Plan",
		"ingredients": {"driftwood": 3, "plant_fiber": 4},
		"output": {"item_id": "building_plan", "quantity": 1},
		"duration": Tune.CRAFT_PLAN_SECONDS,
		"knowledge": "",
		"required_tool": "stone_tool",
		"required_station": ""
	}
}

static func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {}).duplicate(true)

static func all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for recipe: Dictionary in RECIPES.values():
		result.append(recipe.duplicate(true))
	return result

