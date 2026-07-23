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

func configure(settings: Dictionary) -> TouchControls:
	_control_side = str(settings.get("control_side", "left_move"))
	_scale_value = clampf(float(settings.get("touch_scale", Tune.TOUCH_DEFAULT_SCALE)), Tune.TOUCH_MIN_SCALE, Tune.TOUCH_MAX_SCALE)
	return self

func _ready() -> void:
	name = "Touch Controls"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = OS.has_feature("mobile")
	set_process_input(true)
	_create_buttons()

func _input(event: InputEvent) -> void:
	if not visible:
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
			queue_redraw()
		elif event.index == _look_touch:
			var drag_delta: Vector2 = event.position - _look_knob
			_look_knob = event.position
			_look_accumulator += drag_delta
			queue_redraw()

func _begin_touch(index: int, point: Vector2) -> void:
	var move_is_left := _control_side == "left_move"
	var on_left := point.x < size.x * 0.5
	if _move_touch < 0 and on_left == move_is_left:
		_move_touch = index
		_move_origin = point
		_move_knob = point
	elif _look_touch < 0:
		_look_touch = index
		_look_origin = point
		_look_knob = point
	queue_redraw()

func _end_touch(index: int) -> void:
	if index == _move_touch:
		_move_touch = -1
		move_vector = Vector2.ZERO
	if index == _look_touch:
		_look_touch = -1
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

func _draw() -> void:
	var radius := Tune.TOUCH_STICK_RADIUS * _scale_value
	if _move_touch >= 0:
		draw_circle(_move_origin, radius, Color(0.08, 0.1, 0.12, 0.38))
		draw_circle(_move_knob, radius * 0.38, Color(0.9, 0.78, 0.54, 0.58))
	if _look_touch >= 0:
		draw_circle(_look_origin, radius, Color(0.08, 0.1, 0.12, 0.22))
		draw_circle(_look_knob, radius * 0.3, Color(0.75, 0.83, 0.88, 0.38))

func _create_buttons() -> void:
	var right_column := VBoxContainer.new()
	right_column.name = "Action Buttons"
	right_column.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right_column.position = Vector2(-118, -310)
	right_column.add_theme_constant_override("separation", 8)
	add_child(right_column)
	_add_action_button(right_column, "INTERACT", "interact")
	_add_action_button(right_column, "ACTION", "primary_action")
	_add_action_button(right_column, "JUMP", "jump")
	var crouch_button := _add_action_button(right_column, "CROUCH", "crouch")
	crouch_button.toggled.connect(func(active: bool): crouch_active = active)
	crouch_button.toggle_mode = true
	var top_row := HBoxContainer.new()
	top_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_row.position = Vector2(-690, 18)
	top_row.add_theme_constant_override("separation", 8)
	add_child(top_row)
	_add_action_button(top_row, "PACK", "inventory")
	_add_action_button(top_row, "CRAFT", "crafting")
	_add_action_button(top_row, "BUILD", "build_mode")
	_add_action_button(top_row, "PIECE", "build_cycle")
	_add_action_button(top_row, "↶", "rotate_left")
	_add_action_button(top_row, "↷", "rotate_right")
	var hotbar_row := HBoxContainer.new()
	hotbar_row.name = "Touch Hotbar"
	hotbar_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar_row.position = Vector2(-192, -128)
	hotbar_row.add_theme_constant_override("separation", 4)
	add_child(hotbar_row)
	for index in range(Tune.HOTBAR_SLOTS):
		var hotbar_button := Button.new()
		hotbar_button.text = str(index + 1)
		hotbar_button.custom_minimum_size = Vector2(56, 42) * _scale_value
		hotbar_button.pressed.connect(_select_hotbar.bind(index))
		hotbar_row.add_child(hotbar_button)

func _add_action_button(parent: Control, title: String, action: String) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(92, 48) * _scale_value
	button.modulate = Color(1, 1, 1, 0.74)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	parent.add_child(button)
	return button

func _select_hotbar(index: int) -> void:
	hotbar_selected.emit(index)
