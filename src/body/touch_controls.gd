class_name TouchControls
extends Control

signal hotbar_selected(index: int)

var move_vector := Vector2.ZERO
var crouch_active := false
var _look_accumulator := Vector2.ZERO
var _move_touch := -1
var _look_touch := -1
var _move_origin := Vector2.ZERO
var _move_knob := Vector2.ZERO
var _look_origin := Vector2.ZERO
var _look_knob := Vector2.ZERO
var _control_side := "left_move"
var _scale_value := Tune.TOUCH_DEFAULT_SCALE
var _opacity_value := Tune.TOUCH_DEFAULT_OPACITY
var _input_suppressed := false
var _placement_active := false
var _move_center := Vector2.ZERO
var _interactive_controls: Array[Control] = []
var _action_column: VBoxContainer
var _top_row: HBoxContainer
var _hotbar_row: HBoxContainer
var _placement_row: HBoxContainer
var _look_hint: Label
var _crouch_button: Button
var _layout_publish_elapsed := 0.0

func configure(settings: Dictionary) -> TouchControls:
	_control_side = str(settings.get("control_side", "left_move"))
	_scale_value = clampf(float(settings.get("touch_scale", Tune.TOUCH_DEFAULT_SCALE)), Tune.TOUCH_MIN_SCALE, Tune.TOUCH_MAX_SCALE)
	_opacity_value = clampf(float(settings.get("touch_opacity", Tune.TOUCH_DEFAULT_OPACITY)), Tune.TOUCH_MIN_OPACITY, Tune.TOUCH_MAX_OPACITY)
	return self

func _ready() -> void:
	name = "Touch Controls"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	set_process_input(visible)
	_create_surface()
	resized.connect(_layout_controls)
	call_deferred("_layout_controls")
	WebRuntimeBridge.publish({"mobileControlsVisible": visible})

func _process(delta: float) -> void:
	if not visible:
		return
	_layout_publish_elapsed += delta
	if _layout_publish_elapsed >= 0.5:
		_layout_publish_elapsed = 0.0
		_publish_layout_state()

func _input(event: InputEvent) -> void:
	if not visible or _input_suppressed:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_touch(event.index, event.position)
		else:
			_end_touch(event.index)
	elif event is InputEventScreenDrag:
		if event.index == _move_touch:
			_move_knob = event.position
			move_vector = _stick_vector(_move_origin, _move_knob)
			_publish_input_state()
			queue_redraw()
		elif event.index == _look_touch:
			var drag_delta: Vector2 = event.position - _look_knob
			_look_knob = event.position
			_look_accumulator += drag_delta
			_publish_input_state()
			queue_redraw()

func _begin_touch(index: int, point: Vector2) -> void:
	if _point_over_ui(point):
		return
	var radius := Tune.TOUCH_STICK_RADIUS * _scale_value
	var move_is_left := _control_side == "left_move"
	var on_move_side := point.x < size.x * 0.5 if move_is_left else point.x >= size.x * 0.5
	if _move_touch < 0 and on_move_side and point.distance_to(_move_center) <= radius * 1.55:
		_move_touch = index
		_move_origin = _move_center
		_move_knob = point
		move_vector = _stick_vector(_move_origin, _move_knob)
	elif _look_touch < 0 and not on_move_side:
		_look_touch = index
		_look_origin = point
		_look_knob = point
	_publish_input_state()
	queue_redraw()

func _end_touch(index: int) -> void:
	if index == _move_touch:
		_move_touch = -1
		move_vector = Vector2.ZERO
		_move_origin = _move_center
		_move_knob = _move_center
	if index == _look_touch:
		_look_touch = -1
	_publish_input_state()
	queue_redraw()

func _stick_vector(origin: Vector2, current: Vector2) -> Vector2:
	var radius := Tune.TOUCH_STICK_RADIUS * _scale_value
	var value := (current - origin) / radius
	if value.length() < Tune.TOUCH_DEADZONE:
		return Vector2.ZERO
	return value.limit_length(1.0)

func consume_look() -> Vector2:
	var result := _look_accumulator
	_look_accumulator = Vector2.ZERO
	return result

func release_all() -> void:
	_move_touch = -1
	_look_touch = -1
	move_vector = Vector2.ZERO
	_look_accumulator = Vector2.ZERO
	crouch_active = false
	if _crouch_button:
		_crouch_button.button_pressed = false
	_move_origin = _move_center
	_move_knob = _move_center
	for action in ["interact", "primary_action", "jump", "crouch", "sprint", "cancel", "rotate_right"]:
		Input.action_release(action)
	_publish_input_state()
	queue_redraw()

func apply_settings(settings: Dictionary) -> void:
	_control_side = str(settings.get("control_side", "left_move"))
	_scale_value = clampf(float(settings.get("touch_scale", Tune.TOUCH_DEFAULT_SCALE)), Tune.TOUCH_MIN_SCALE, Tune.TOUCH_MAX_SCALE)
	_opacity_value = clampf(float(settings.get("touch_opacity", Tune.TOUCH_DEFAULT_OPACITY)), Tune.TOUCH_MIN_OPACITY, Tune.TOUCH_MAX_OPACITY)
	if is_inside_tree():
		_layout_controls()

func set_input_suppressed(suppressed: bool) -> void:
	_input_suppressed = suppressed
	if suppressed:
		release_all()
	for control in _interactive_controls:
		if control is BaseButton:
			(control as BaseButton).disabled = suppressed
	modulate.a = _opacity_value * (0.32 if suppressed else 1.0)
	WebRuntimeBridge.publish({"touchInputSuppressed": suppressed})

func set_placement_mode(active: bool) -> void:
	_placement_active = active
	if _placement_row:
		_placement_row.visible = active
	WebRuntimeBridge.publish({"mobilePlacementControlsVisible": visible and active})
	call_deferred("_publish_layout_state")

func _draw() -> void:
	if not visible:
		return
	var radius := Tune.TOUCH_STICK_RADIUS * _scale_value
	var alpha := _opacity_value * (0.35 if _input_suppressed else 1.0)
	draw_circle(_move_center, radius * 1.18, Color(0.04, 0.07, 0.09, 0.48 * alpha))
	draw_arc(_move_center, radius * 1.18, 0.0, TAU, 48, Color(0.88, 0.73, 0.45, 0.72 * alpha), 3.0)
	var knob_point := _move_knob if _move_touch >= 0 else _move_center
	draw_circle(knob_point, radius * 0.44, Color(0.92, 0.78, 0.52, 0.72 * alpha))
	var font := ThemeDB.fallback_font
	var label_position := _move_center + Vector2(-font.get_string_size("MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x * 0.5, radius * 0.12)
	draw_string(font, label_position, "MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1.0, 0.94, 0.82, 0.92 * alpha))

func _create_surface() -> void:
	_action_column = VBoxContainer.new()
	_action_column.name = "Action Buttons"
	_action_column.add_theme_constant_override("separation", 10)
	add_child(_action_column)
	_add_action_button(_action_column, "INTERACT", "interact")
	_add_action_button(_action_column, "ACTION", "primary_action")
	_add_action_button(_action_column, "JUMP", "jump")
	_crouch_button = _add_action_button(_action_column, "CROUCH", "crouch")
	_crouch_button.toggle_mode = true
	_crouch_button.toggled.connect(func(active: bool): crouch_active = active)

	_top_row = HBoxContainer.new()
	_top_row.name = "Mobile Menus"
	_top_row.add_theme_constant_override("separation", 10)
	add_child(_top_row)
	_add_action_button(_top_row, "PACK", "inventory")
	_add_action_button(_top_row, "CRAFT", "crafting")
	_add_action_button(_top_row, "BUILD", "build_mode")

	_hotbar_row = HBoxContainer.new()
	_hotbar_row.name = "Touch Hotbar"
	_hotbar_row.add_theme_constant_override("separation", 6)
	add_child(_hotbar_row)
	for index in range(Tune.HOTBAR_SLOTS):
		var hotbar_button := Button.new()
		hotbar_button.name = "Hotbar %d" % (index + 1)
		hotbar_button.text = str(index + 1)
		hotbar_button.custom_minimum_size = Vector2(72, 76)
		hotbar_button.pressed.connect(_select_hotbar.bind(index))
		_hotbar_row.add_child(hotbar_button)
		_interactive_controls.append(hotbar_button)

	_placement_row = HBoxContainer.new()
	_placement_row.name = "Placement Controls"
	_placement_row.add_theme_constant_override("separation", 10)
	_placement_row.visible = false
	add_child(_placement_row)
	_add_action_button(_placement_row, "PLACE", "primary_action", Vector2(130, 76))
	_add_action_button(_placement_row, "CANCEL", "cancel", Vector2(130, 76))
	_add_action_button(_placement_row, "ROTATE", "rotate_right", Vector2(130, 76))

	_look_hint = Label.new()
	_look_hint.name = "Touch Look Region"
	_look_hint.text = "SWIPE TO LOOK"
	_look_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_look_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_look_hint.add_theme_font_size_override("font_size", 16)
	_look_hint.add_theme_color_override("font_color", Color(0.9, 0.93, 0.94, 0.74))
	_look_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_look_hint)

func _add_action_button(parent: Control, title: String, action: String, minimum := Vector2(126, 76)) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = minimum
	button.modulate = Color(1, 1, 1, _opacity_value)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	parent.add_child(button)
	_interactive_controls.append(button)
	return button

func _select_hotbar(index: int) -> void:
	hotbar_selected.emit(index)
	WebRuntimeBridge.publish({"touchHotbarSelection": index})

func _layout_controls() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var scale := _scale_value
	var move_is_left := _control_side == "left_move"
	_move_center = Vector2(128.0 * scale, size.y - 142.0 * scale) if move_is_left else Vector2(size.x - 128.0 * scale, size.y - 142.0 * scale)
	if _move_touch < 0:
		_move_origin = _move_center
		_move_knob = _move_center

	_action_column.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var action_size := _action_column.get_combined_minimum_size() * scale
	_action_column.position = Vector2(size.x - action_size.x - 24.0 * scale, size.y - action_size.y - 24.0 * scale) if move_is_left else Vector2(24.0 * scale, size.y - action_size.y - 24.0 * scale)
	_action_column.scale = Vector2.ONE * scale

	_top_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var top_size := _top_row.get_combined_minimum_size() * scale
	_top_row.position = Vector2((size.x - top_size.x) * 0.5, 18.0 * scale)
	_top_row.scale = Vector2.ONE * scale

	_hotbar_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var hotbar_size := _hotbar_row.get_combined_minimum_size() * scale
	_hotbar_row.position = Vector2((size.x - hotbar_size.x) * 0.5, size.y - 84.0 * scale)
	_hotbar_row.scale = Vector2.ONE * scale

	_placement_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var placement_size := _placement_row.get_combined_minimum_size() * scale
	_placement_row.position = Vector2((size.x - placement_size.x) * 0.5, size.y - 176.0 * scale)
	_placement_row.scale = Vector2.ONE * scale

	_look_hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_look_hint.custom_minimum_size = Vector2(160.0, 44.0)
	_look_hint.position = Vector2(size.x * 0.75 - 80.0, size.y * 0.5 + 80.0) if move_is_left else Vector2(size.x * 0.25 - 80.0, size.y * 0.5 + 80.0)

	modulate.a = _opacity_value * (0.32 if _input_suppressed else 1.0)
	for control in _interactive_controls:
		control.modulate.a = _opacity_value
	queue_redraw()
	call_deferred("_publish_layout_state")

func _point_over_ui(point: Vector2) -> bool:
	for control in _interactive_controls:
		if control.visible and not (control is BaseButton and (control as BaseButton).disabled) and control.get_global_rect().has_point(point):
			return true
	return false

func _publish_layout_state() -> void:
	if not is_inside_tree() or size.x <= 1.0 or size.y <= 1.0:
		return
	var first_hotbar := _hotbar_row.get_child(0) as Control
	var first_center := first_hotbar.get_global_rect().get_center()
	var placement_centers: Array = []
	for child in _placement_row.get_children():
		if child is Control:
			var center := (child as Control).get_global_rect().get_center()
			placement_centers.append([center.x / size.x, center.y / size.y])
	var action_centers := {}
	for child in _action_column.get_children():
		if child is Button:
			var action_button := child as Button
			var action_center := action_button.get_global_rect().get_center()
			action_centers[action_button.text.to_lower()] = [action_center.x / size.x, action_center.y / size.y]
	WebRuntimeBridge.publish({
		"mobileControlsVisible": visible,
		"controlSide": _control_side,
		"joystick": [
			_move_center.x / size.x,
			_move_center.y / size.y,
			Tune.TOUCH_STICK_RADIUS * _scale_value / size.x,
			Tune.TOUCH_STICK_RADIUS * _scale_value / size.y
		],
		"lookRegion": [0.5 if _control_side == "left_move" else 0.0, 0.0, 0.5, 1.0],
		"hotbarFirst": [first_center.x / size.x, first_center.y / size.y],
		"actionButtons": action_centers,
		"placementButtons": placement_centers,
		"mobilePlacementControlsVisible": visible and _placement_active
	})

func _publish_input_state() -> void:
	WebRuntimeBridge.publish({
		"moveVector": [move_vector.x, move_vector.y],
		"moveTouchActive": _move_touch >= 0,
		"lookTouchActive": _look_touch >= 0
	})
