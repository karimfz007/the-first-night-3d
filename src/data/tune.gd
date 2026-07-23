class_name Tune
extends RefCounted
## Single source of gameplay and presentation tuning for vertical slice 0.1.

const SCHEMA_VERSION := 3
const OWNER_ID := "player_local"

# World clock and offline fairness.
const START_WORLD_SECONDS := 18.25 * 3600.0
const WORLD_DAY_SECONDS := 24.0 * 3600.0
const WORLD_TIME_SCALE := 36.0
const NIGHT_START_HOUR := 19.0
const NIGHT_END_HOUR := 6.0
const OFFLINE_MAX_REAL_SECONDS := 3.0 * 24.0 * 3600.0
const AUTOSAVE_SECONDS := 30.0
const OFFLINE_REPORT_MIN_SECONDS := 5.0

# Vitals.
const WARMTH_MIN := 0.0
const WARMTH_MAX := 100.0
const WARMTH_START := 72.0
const WARMTH_OFFLINE_FLOOR := 15.0
const WARMTH_EXPOSED_LOSS_PER_WORLD_MINUTE := 0.18
const WARMTH_SHELTER_LOSS_MULTIPLIER := 0.28
const WARMTH_FIRE_GAIN_PER_SECOND := 2.2
const WARMTH_FIRE_OFFLINE_GAIN_PER_WORLD_MINUTE := 0.22
const SANCTUARY_WARMTH := 62.0
const STAMINA_MAX := 100.0
const STAMINA_DRAIN_PER_SECOND := 18.0
const STAMINA_RECOVER_PER_SECOND := 13.0

# Fire.
const FIRE_FUEL_PER_WOOD := 75.0
const FIRE_FUEL_MAX := 900.0
const FIRE_BURN_PER_WORLD_SECOND := 0.18
const FIRE_HEAT_RADIUS := 7.0
const FIRE_LIGHT_RANGE := 12.0
const FIRE_LIGHT_ENERGY := 2.4

# Player movement/camera.
const WALK_SPEED := 4.1
const SPRINT_SPEED := 6.3
const CROUCH_SPEED := 2.25
const GROUND_ACCELERATION := 28.0
const AIR_ACCELERATION := 7.0
const DECELERATION := 24.0
const JUMP_VELOCITY := 5.0
const GRAVITY := 15.5
const STANDING_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.15
const HEAD_HEIGHT := 1.58
const CROUCH_HEAD_HEIGHT := 1.02
const CROUCH_LERP_SPEED := 10.0
const LOOK_SENSITIVITY := 0.0022
const TOUCH_SENSITIVITY := 0.0028
const LOOK_PITCH_LIMIT := 1.48
const BOB_FREQUENCY := 7.5
const BOB_AMPLITUDE := 0.025
const DEFAULT_BOB_INTENSITY := 0.35

# Interaction and feedback.
const INTERACT_RANGE := 3.4
const TOOL_RANGE := 3.7
const INTERACT_CANCEL_DISTANCE := 3.8
const LOOSE_PICKUP_HOLD := 0.0
const SALVAGE_HOLD_SECONDS := 1.25
const TOOL_STRIKE_COOLDOWN := 0.48
const BARE_HAND_YIELD := 1
const TOOL_YIELD := 3
const MAX_INVENTORY_SLOTS := 20
const HOTBAR_SLOTS := 6
const NOTIFICATION_SECONDS := 2.8
const HINT_IDLE_SECONDS := 24.0
const FOOTSTEP_INTERVAL := 0.48

# Building.
const BUILD_RANGE := 6.0
const BUILD_GRID := 0.5
const BUILD_ROTATION_STEP_DEGREES := 90.0
const BUILD_MAX_SLOPE_DEGREES := 24.0
const BUILD_PREVIEW_ALPHA := 0.48
const BUILD_VALID_COLOR := Color(0.25, 0.9, 0.48, BUILD_PREVIEW_ALPHA)
const BUILD_INVALID_COLOR := Color(0.95, 0.25, 0.2, BUILD_PREVIEW_ALPHA)
const BUILD_DEFAULT_HEALTH := 100.0
const SHELTER_CHECK_RADIUS := 7.5
const SHELTER_REQUIRED_WALLS := 3
const SHELTER_PROTECTION := 0.72

# World presentation and authored-space constants.
const BEACH_SIZE := Vector3(120.0, 1.0, 90.0)
const WATER_SIZE := Vector3(180.0, 0.5, 65.0)
const TREELINE_SIZE := Vector3(120.0, 1.0, 55.0)
const WORLD_VIEW_DISTANCE := 180.0
const SHADOW_DISTANCE := 70.0
const FOG_DENSITY := 0.008
const SUN_ENERGY := 0.72
const RESOURCE_RESPAWN_ENABLED := false

# Touch and accessibility.
const TOUCH_STICK_RADIUS := 72.0
const TOUCH_DEADZONE := 0.16
const TOUCH_DEFAULT_SCALE := 1.0
const TOUCH_MIN_SCALE := 0.7
const TOUCH_MAX_SCALE := 1.4
const UI_SCALE_MIN := 0.8
const UI_SCALE_MAX := 1.35
const DEFAULT_AUDIO_VOLUME := 0.82
const AMBIENT_SAMPLE_RATE := 22050.0

# Crafting.
const CRAFT_TICK_SECONDS := 0.1
const CRAFT_TOOL_SECONDS := 2.5
const CRAFT_FIRE_SECONDS := 2.0
const CRAFT_PLAN_SECONDS := 1.2

static func is_night(world_seconds: float) -> bool:
	var hour := fposmod(world_seconds, WORLD_DAY_SECONDS) / 3600.0
	return hour >= NIGHT_START_HOUR or hour < NIGHT_END_HOUR

static func finite_number(value: Variant, fallback: float = 0.0) -> float:
	if value is int or value is float:
		var number := float(value)
		if not is_nan(number) and not is_inf(number):
			return number
	return fallback

static func snapped(value: Vector3) -> Vector3:
	return Vector3(
		snappedf(value.x, BUILD_GRID),
		snappedf(value.y, BUILD_GRID),
		snappedf(value.z, BUILD_GRID)
	)
