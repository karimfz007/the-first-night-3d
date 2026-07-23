class_name CraftingService
extends RefCounted

var queue: Array[Dictionary] = []

func start(recipe_id: String, inventory: Inventory, knowledge: Array[String] = [], station: String = "") -> Dictionary:
	var recipe := RecipeDB.get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "Unknown recipe"}
	var required_knowledge := str(recipe.get("knowledge", ""))
	if not required_knowledge.is_empty() and required_knowledge not in knowledge:
		return {"ok": false, "reason": "Knowledge required"}
	var required_tool := str(recipe.get("required_tool", ""))
	if not required_tool.is_empty() and inventory.count(required_tool) <= 0:
		return {"ok": false, "reason": "%s required" % ItemDB.display_name(required_tool)}
	var required_station := str(recipe.get("required_station", ""))
	if not required_station.is_empty() and required_station != station:
		return {"ok": false, "reason": "%s required" % required_station}
	var cost: Dictionary = recipe.get("ingredients", {})
	if not inventory.consume_cost(cost):
		return {"ok": false, "reason": _missing_text(inventory.missing_for(cost))}
	queue.append({
		"recipe_id": recipe_id,
		"remaining": maxf(0.0, float(recipe.get("duration", 0.0))),
		"output": recipe.get("output", {}).duplicate(true)
	})
	return {"ok": true, "reason": "Crafting %s" % recipe.get("name", recipe_id)}

func tick(delta: float, inventory: Inventory) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	if queue.is_empty():
		return completed
	queue[0].remaining = maxf(0.0, float(queue[0].remaining) - maxf(0.0, delta))
	if float(queue[0].remaining) <= 0.0:
		var job: Dictionary = queue.pop_front()
		var output: Dictionary = job.get("output", {})
		var result := inventory.add(str(output.get("item_id", "")), int(output.get("quantity", 0)))
		job["overflow"] = int(result.overflow)
		completed.append(job)
	return completed

func cancel(index: int, inventory: Inventory) -> bool:
	if index < 0 or index >= queue.size():
		return false
	var job: Dictionary = queue[index]
	var recipe := RecipeDB.get_recipe(str(job.get("recipe_id", "")))
	for item_id: String in recipe.get("ingredients", {}):
		inventory.add(item_id, int(recipe.ingredients[item_id]))
	queue.remove_at(index)
	return true

func to_dict() -> Dictionary:
	return {"queue": queue.duplicate(true)}

func load_dict(data: Dictionary) -> void:
	queue.clear()
	for raw: Variant in data.get("queue", []):
		if raw is Dictionary and RecipeDB.get_recipe(str(raw.get("recipe_id", ""))).size() > 0:
			queue.append(raw.duplicate(true))

func _missing_text(missing: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id: String in missing:
		parts.append("%s ×%d" % [ItemDB.display_name(item_id), int(missing[item_id])])
	return "Missing " + ", ".join(parts)

