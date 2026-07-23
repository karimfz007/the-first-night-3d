class_name GameStrings
extends RefCounted

const TEXT := {
	"objective_driftwood": "Find driftwood on the beach",
	"objective_tool": "Craft a primitive stone tool [K]",
	"objective_fire": "Craft and place a campfire",
	"objective_shelter": "Build a foundation, walls, doorway and roof [B]",
	"objective_survive": "Keep the fire alive. Survive the night.",
	"horizon_session": "Tonight: create shelter and survive",
	"horizon_long": "Beyond: find a way off the island",
	"cold": "Cold air is pulling warmth from you.",
	"sanctuary": "Firelight and shelter cut through the cold.",
	"clue": "The compass is fused pointing inland. The needle still trembles."
}

static func get_text(key: String) -> String:
	return str(TEXT.get(key, key))

