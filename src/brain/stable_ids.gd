class_name StableIds
extends RefCounted

var counter: int = 1

func _init(start_counter: int = 1) -> void:
	counter = maxi(1, start_counter)

func next_id(prefix: String) -> String:
	var result := "%s_%08d" % [prefix, counter]
	counter += 1
	return result

func to_dict() -> Dictionary:
	return {"counter": counter}

static func from_dict(data: Dictionary) -> StableIds:
	return StableIds.new(int(data.get("counter", 1)))

