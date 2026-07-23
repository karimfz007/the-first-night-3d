class_name WorldState
extends RefCounted

static func new_game(real_timestamp: int = 0) -> Dictionary:
	var now := real_timestamp if real_timestamp > 0 else int(Time.get_unix_time_from_system())
	return {
		"schema_version": Tune.SCHEMA_VERSION,
		"player": {
			"position": [0.0, 2.0, 17.0],
			"rotation_y": 0.0,
			"settings": default_settings()
		},
		"inventory": Inventory.new().to_dict(),
		"crafting": {"queue": []},
		"buildings": [],
		"fires": [],
		"resources": {},
		"world_seconds": Tune.START_WORLD_SECONDS,
		"warmth": Tune.WARMTH_START,
		"stable_ids": {"counter": 1},
		"objective_index": 0,
		"last_save_unix": now
	}

static func default_settings() -> Dictionary:
	return {
		"look_sensitivity": Tune.LOOK_SENSITIVITY,
		"touch_sensitivity": Tune.TOUCH_SENSITIVITY,
		"invert_look": false,
		"bob_intensity": Tune.DEFAULT_BOB_INTENSITY,
		"audio_volume": Tune.DEFAULT_AUDIO_VOLUME,
		"control_side": "left_move",
		"touch_scale": Tune.TOUCH_DEFAULT_SCALE,
		"debug_overlay": false
	}

static func sanitized(data: Dictionary) -> Dictionary:
	var state := data.duplicate(true)
	state["schema_version"] = Tune.SCHEMA_VERSION
	state["world_seconds"] = fposmod(maxf(0.0, Tune.finite_number(state.get("world_seconds"), Tune.START_WORLD_SECONDS)), Tune.WORLD_DAY_SECONDS)
	state["warmth"] = clampf(Tune.finite_number(state.get("warmth"), Tune.WARMTH_START), Tune.WARMTH_MIN, Tune.WARMTH_MAX)
	state["last_save_unix"] = maxi(0, int(state.get("last_save_unix", 0)))
	if state.get("player") is not Dictionary:
		state["player"] = new_game().player
	var player: Dictionary = state.player
	if player.get("position") is not Array or player.position.size() < 3:
		player["position"] = [0.0, 2.0, 17.0]
	player["rotation_y"] = Tune.finite_number(player.get("rotation_y"), 0.0)
	var defaults := default_settings()
	var settings: Dictionary = player.get("settings", {})
	for key: String in defaults:
		if not settings.has(key):
			settings[key] = defaults[key]
	player["settings"] = settings
	state["player"] = player
	state["inventory"] = Inventory.from_dict(state.get("inventory", {})).to_dict()
	for collection in ["buildings", "fires"]:
		if state.get(collection) is not Array:
			state[collection] = []
	if state.get("resources") is not Dictionary:
		state["resources"] = {}
	if state.get("crafting") is not Dictionary:
		state["crafting"] = {"queue": []}
	if state.get("stable_ids") is not Dictionary:
		state["stable_ids"] = {"counter": 1}
	state["objective_index"] = maxi(0, int(state.get("objective_index", 0)))
	return state

