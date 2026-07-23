class_name Inventory
extends RefCounted

var slots: Array[Dictionary] = []
var max_slots: int = Tune.MAX_INVENTORY_SLOTS

func _init(slot_limit: int = Tune.MAX_INVENTORY_SLOTS) -> void:
	max_slots = maxi(1, slot_limit)

func add(item_id: String, quantity: int) -> Dictionary:
	if not ItemDB.exists(item_id) or quantity <= 0:
		return {"accepted": 0, "overflow": maxi(0, quantity)}
	var remaining := quantity
	var limit := ItemDB.stack_limit(item_id)
	for slot in slots:
		if str(slot.get("item_id", "")) == item_id and int(slot.get("quantity", 0)) < limit:
			var room := limit - int(slot.quantity)
			var moved := mini(room, remaining)
			slot.quantity = int(slot.quantity) + moved
			remaining -= moved
			if remaining == 0:
				break
	while remaining > 0 and slots.size() < max_slots:
		var moved := mini(limit, remaining)
		slots.append({"item_id": item_id, "quantity": moved})
		remaining -= moved
	return {"accepted": quantity - remaining, "overflow": remaining}

func count(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if str(slot.get("item_id", "")) == item_id:
			total += maxi(0, int(slot.get("quantity", 0)))
	return total

func has_cost(cost: Dictionary) -> bool:
	for item_id: String in cost:
		if count(item_id) < maxi(0, int(cost[item_id])):
			return false
	return true

func missing_for(cost: Dictionary) -> Dictionary:
	var missing := {}
	for item_id: String in cost:
		var need := maxi(0, int(cost[item_id]))
		var lack := need - count(item_id)
		if lack > 0:
			missing[item_id] = lack
	return missing

func remove(item_id: String, quantity: int) -> bool:
	if quantity < 0 or count(item_id) < quantity:
		return false
	var remaining := quantity
	for index in range(slots.size() - 1, -1, -1):
		if str(slots[index].get("item_id", "")) != item_id:
			continue
		var taken := mini(int(slots[index].quantity), remaining)
		slots[index].quantity = int(slots[index].quantity) - taken
		remaining -= taken
		if int(slots[index].quantity) <= 0:
			slots.remove_at(index)
		if remaining == 0:
			break
	return remaining == 0

func consume_cost(cost: Dictionary) -> bool:
	if not has_cost(cost):
		return false
	for item_id: String in cost:
		remove(item_id, int(cost[item_id]))
	return true

func move_slot(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= slots.size() or to_index < 0 or to_index >= max_slots:
		return false
	while slots.size() <= to_index:
		slots.append({})
	var temp := slots[to_index]
	slots[to_index] = slots[from_index]
	slots[from_index] = temp
	_compact_empty()
	return true

func split_slot(index: int, quantity: int) -> bool:
	if index < 0 or index >= slots.size() or slots.size() >= max_slots:
		return false
	var available := int(slots[index].get("quantity", 0))
	if quantity <= 0 or quantity >= available:
		return false
	slots[index].quantity = available - quantity
	slots.append({"item_id": str(slots[index].item_id), "quantity": quantity})
	return true

func drop_slot(index: int, quantity: int = -1) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	var available := int(slots[index].get("quantity", 0))
	var dropped := available if quantity < 0 else clampi(quantity, 0, available)
	var result := {"item_id": str(slots[index].item_id), "quantity": dropped}
	slots[index].quantity = available - dropped
	_compact_empty()
	return result

func _compact_empty() -> void:
	for index in range(slots.size() - 1, -1, -1):
		if slots[index].is_empty() or int(slots[index].get("quantity", 0)) <= 0:
			slots.remove_at(index)

func to_dict() -> Dictionary:
	return {"max_slots": max_slots, "slots": slots.duplicate(true)}

static func from_dict(data: Dictionary) -> Inventory:
	var inventory := Inventory.new(int(data.get("max_slots", Tune.MAX_INVENTORY_SLOTS)))
	for raw_slot: Variant in data.get("slots", []):
		if raw_slot is not Dictionary:
			continue
		var item_id := str(raw_slot.get("item_id", ""))
		var quantity := maxi(0, int(raw_slot.get("quantity", 0)))
		if ItemDB.exists(item_id) and quantity > 0:
			inventory.add(item_id, quantity)
	return inventory

