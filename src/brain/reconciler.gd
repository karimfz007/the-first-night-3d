class_name Reconciler
extends RefCounted

static func reconcile(initial_state: Dictionary, elapsed_real_seconds: float) -> Dictionary:
	var state := WorldState.sanitized(initial_state)
	var requested := maxf(0.0, Tune.finite_number(elapsed_real_seconds, 0.0))
	var elapsed := minf(requested, Tune.OFFLINE_MAX_REAL_SECONDS)
	var world_advanced := elapsed * Tune.WORLD_TIME_SCALE
	var warmth_before := float(state.warmth)
	var fire_seconds := 0.0
	var fire_went_out := false
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
		fire["fuel"] = maxf(0.0, fuel_before - burned_world_seconds * Tune.FIRE_BURN_PER_WORLD_SECOND)
		if float(fire.fuel) <= 0.0001 and world_advanced >= possible_world_seconds:
			fire["lit"] = false
			fire_went_out = true
		fires[index] = fire
	state["fires"] = fires
	state["world_seconds"] = fposmod(float(state.world_seconds) + world_advanced, Tune.WORLD_DAY_SECONDS)
	var world_minutes := world_advanced / 60.0
	var exposed_loss := world_minutes * Tune.WARMTH_EXPOSED_LOSS_PER_WORLD_MINUTE
	var fire_gain_minutes := (fire_seconds * Tune.WORLD_TIME_SCALE) / 60.0
	var fire_gain := fire_gain_minutes * Tune.WARMTH_FIRE_OFFLINE_GAIN_PER_WORLD_MINUTE
	var warmth_after := clampf(warmth_before - exposed_loss + fire_gain, Tune.WARMTH_OFFLINE_FLOOR, Tune.WARMTH_MAX)
	state["warmth"] = warmth_after
	var causes: Array[String] = []
	if elapsed <= 0.0:
		causes.append("No time passed.")
	elif fire_seconds > 0.0 and fire_went_out:
		causes.append("The fire provided warmth until its fuel was exhausted.")
	elif fire_seconds > 0.0:
		causes.append("The fire remained lit and slowed the cold.")
	else:
		causes.append("Without a lit fire, the night air reduced warmth.")
	if requested > elapsed:
		causes.append("Offline consequences were capped for fairness.")
	return {
		"state": state,
		"report": {
			"elapsed_real_seconds": elapsed,
			"requested_elapsed_seconds": requested,
			"world_advanced_seconds": world_advanced,
			"fire_duration_seconds": fire_seconds,
			"fire_went_out": fire_went_out,
			"warmth_before": warmth_before,
			"warmth_after": warmth_after,
			"warmth_change": warmth_after - warmth_before,
			"cause": " ".join(causes)
		}
	}

