class_name Reconciler
extends RefCounted

static func reconcile(initial_state: Dictionary, elapsed_real_seconds: float) -> Dictionary:
	var state := WorldState.sanitized(initial_state)
	var requested := maxf(0.0, Tune.finite_number(elapsed_real_seconds, 0.0))
	var elapsed := minf(requested, Tune.OFFLINE_MAX_REAL_SECONDS)
	var world_advanced := elapsed * Tune.WORLD_TIME_SCALE
	var start_world_seconds := float(state.world_seconds)
	var warmth_before := float(state.warmth)
	var fire_seconds := 0.0
	var heated_seconds := 0.0
	var fire_went_out := false
	var player_position := _player_position(state)
	var fires: Array = state.get("fires", [])
	for index in range(fires.size()):
		if fires[index] is not Dictionary:
			continue
		var fire: Dictionary = fires[index]
		var was_lit := bool(fire.get("lit", false))
		var fuel_before := maxf(0.0, Tune.finite_number(fire.get("fuel"), 0.0))
		if not was_lit or fuel_before <= 0.0:
			fire["lit"] = false
			fire["fuel"] = fuel_before
			fires[index] = fire
			continue
		var possible_world_seconds := fuel_before / Tune.FIRE_BURN_PER_WORLD_SECOND
		var burned_world_seconds := minf(world_advanced, possible_world_seconds)
		var burned_real_seconds := burned_world_seconds / Tune.WORLD_TIME_SCALE
		fire_seconds = maxf(fire_seconds, burned_real_seconds)
		if _fire_is_near(fire, player_position):
			heated_seconds = maxf(heated_seconds, burned_real_seconds)
		fire["fuel"] = maxf(0.0, fuel_before - burned_world_seconds * Tune.FIRE_BURN_PER_WORLD_SECOND)
		if float(fire.fuel) <= 0.0001 and world_advanced >= possible_world_seconds:
			fire["lit"] = false
			fire_went_out = true
		fires[index] = fire
	state["fires"] = fires
	state["world_seconds"] = fposmod(float(state.world_seconds) + world_advanced, Tune.WORLD_DAY_SECONDS)
	var night_world_seconds := _night_seconds(start_world_seconds, world_advanced)
	var night_minutes := night_world_seconds / 60.0
	var sheltered := _is_sheltered(state, player_position)
	var shelter_multiplier := Tune.WARMTH_SHELTER_LOSS_MULTIPLIER if sheltered else 1.0
	var exposed_loss := night_minutes * Tune.WARMTH_EXPOSED_LOSS_PER_WORLD_MINUTE * shelter_multiplier
	var fire_gain_minutes := (heated_seconds * Tune.WORLD_TIME_SCALE) / 60.0
	var fire_gain := fire_gain_minutes * Tune.WARMTH_FIRE_OFFLINE_GAIN_PER_WORLD_MINUTE
	var warmth_after := clampf(warmth_before - exposed_loss + fire_gain, Tune.WARMTH_OFFLINE_FLOOR, Tune.WARMTH_MAX)
	state["warmth"] = warmth_after
	var causes: Array[String] = []
	if elapsed <= 0.0:
		causes.append("No time passed.")
	elif heated_seconds > 0.0 and fire_went_out:
		causes.append("The fire provided warmth until its fuel was exhausted.")
	elif heated_seconds > 0.0:
		causes.append("The fire remained lit and slowed the cold.")
	elif fire_seconds > 0.0:
		causes.append("A fire burned, but the player was outside its heat radius.")
	elif night_world_seconds <= 0.0:
		causes.append("The absence passed outside the coldest night hours.")
	else:
		causes.append("Without a lit fire, the night air reduced warmth.")
	if sheltered:
		causes.append("The completed shelter reduced exposure.")
	if requested > elapsed:
		causes.append("Offline consequences were capped for fairness.")
	return {
		"state": state,
		"report": {
			"elapsed_real_seconds": elapsed,
			"requested_elapsed_seconds": requested,
			"world_advanced_seconds": world_advanced,
			"night_world_seconds": night_world_seconds,
			"fire_duration_seconds": fire_seconds,
			"fire_heat_seconds": heated_seconds,
			"fire_went_out": fire_went_out,
			"sheltered": sheltered,
			"warmth_before": warmth_before,
			"warmth_after": warmth_after,
			"warmth_change": warmth_after - warmth_before,
			"cause": " ".join(causes)
		}
	}

static func _player_position(state: Dictionary) -> Vector3:
	var player: Dictionary = state.get("player", {})
	var raw: Variant = player.get("position", [0.0, 0.0, 0.0])
	if raw is Array and raw.size() >= 3:
		return Vector3(
			Tune.finite_number(raw[0], 0.0),
			Tune.finite_number(raw[1], 0.0),
			Tune.finite_number(raw[2], 0.0)
		)
	return Vector3.ZERO

static func _fire_is_near(fire: Dictionary, player_position: Vector3) -> bool:
	var raw: Variant = fire.get("position", [])
	if raw is not Array or raw.size() < 3:
		return false
	var position := Vector3(
		Tune.finite_number(raw[0], 0.0),
		Tune.finite_number(raw[1], 0.0),
		Tune.finite_number(raw[2], 0.0)
	)
	return position.distance_to(player_position) <= Tune.FIRE_HEAT_RADIUS

static func _is_sheltered(state: Dictionary, player_position: Vector3) -> bool:
	var walls := 0
	var foundation := false
	var roof := false
	for raw: Variant in state.get("buildings", []):
		if raw is not Dictionary:
			continue
		var record: Dictionary = raw
		if BuildRecord.transform_from(record).origin.distance_to(player_position) > Tune.SHELTER_CHECK_RADIUS:
			continue
		match str(record.get("piece_id", "")):
			"wall", "doorway":
				walls += 1
			"foundation":
				foundation = true
			"roof":
				roof = true
	return foundation and roof and walls >= Tune.SHELTER_REQUIRED_WALLS

static func _night_seconds(start_world_seconds: float, duration_world_seconds: float) -> float:
	var remaining := maxf(0.0, duration_world_seconds)
	var cursor := fposmod(start_world_seconds, Tune.WORLD_DAY_SECONDS)
	var result := 0.0
	while remaining > 0.0:
		var step := minf(remaining, Tune.WORLD_DAY_SECONDS - cursor)
		var segment_end := cursor + step
		var night_start := Tune.NIGHT_START_HOUR * 3600.0
		var night_end := Tune.NIGHT_END_HOUR * 3600.0
		result += maxf(0.0, minf(segment_end, night_end) - maxf(cursor, 0.0))
		result += maxf(0.0, minf(segment_end, Tune.WORLD_DAY_SECONDS) - maxf(cursor, night_start))
		remaining -= step
		cursor = 0.0
	return result
