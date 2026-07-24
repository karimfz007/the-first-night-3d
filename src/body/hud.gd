class_name HUD
extends CanvasLayer

var game: Node
var player: PlayerController
var root: Control
var objective_label: Label
var horizon_label: Label
var prompt_label: Label
var toast_label: Label
var warmth_bar: ProgressBar
var stamina_bar: ProgressBar
var time_label: Label
var progress_bar: ProgressBar
var hotbar: HBoxContainer
var hotbar_labels: Array[Label] = []
var inventory_panel: PanelContainer
var inventory_text: RichTextLabel
var crafting_panel: PanelContainer
var crafting_queue_label: Label
var debug_label: Label
var build_label: Label
var save_label: Label
var settings_button: Button
var settings_panel: PanelContainer
var help_panel: PanelContainer
var focus_label: Label
var active_item_label: Label
var fullscreen_button: Button
var _settings_controls: Dictionary = {}
var _toast_remaining := 0.0
var _refresh_timer := 0.0

func configure(game_node: Node, player_node: PlayerController) -> HUD:
	game = game_node
	player = player_node
	return self

func _ready() -> void:
	name = "HUD"
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_create_status()
	_create_crosshair()
	_create_hotbar()
	_create_inventory()
	_create_crafting()
	_create_settings()
	_create_help()
	_create_debug()
	root.resized.connect(_publish_layout_state)
	call_deferred("_publish_layout_state")
	WebRuntimeBridge.publish({"settingsButtonVisible": true, "settingsOpen": false, "helpOpen": false})

func _process(delta: float) -> void:
	if game == null or player == null:
		return
	_toast_remaining = maxf(0.0, _toast_remaining - delta)
	toast_label.modulate.a = clampf(_toast_remaining, 0.0, 1.0)
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.18
		refresh()
	if Input.is_action_just_pressed("cancel") and _any_modal_open():
		close_modals()
		return
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	if Input.is_action_just_pressed("crafting"):
		toggle_crafting()

func _create_status() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	root.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 21)
	objective_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.62))
	stack.add_child(objective_label)
	horizon_label = Label.new()
	horizon_label.text = "%s\n%s" % [GameStrings.get_text("horizon_session"), GameStrings.get_text("horizon_long")]
	horizon_label.add_theme_font_size_override("font_size", 13)
	horizon_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.78))
	stack.add_child(horizon_label)
	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 15)
	stack.add_child(time_label)
	var bars := VBoxContainer.new()
	bars.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bars.position = Vector2(24, -92)
	bars.custom_minimum_size = Vector2(220, 64)
	root.add_child(bars)
	var warmth_row := HBoxContainer.new()
	var warmth_title := Label.new()
	warmth_title.text = "WARMTH"
	warmth_title.custom_minimum_size.x = 72
	warmth_row.add_child(warmth_title)
	warmth_bar = ProgressBar.new()
	warmth_bar.min_value = Tune.WARMTH_MIN
	warmth_bar.max_value = Tune.WARMTH_MAX
	warmth_bar.show_percentage = false
	warmth_bar.custom_minimum_size = Vector2(145, 15)
	warmth_row.add_child(warmth_bar)
	bars.add_child(warmth_row)
	var stamina_row := HBoxContainer.new()
	var stamina_title := Label.new()
	stamina_title.text = "STAMINA"
	stamina_title.custom_minimum_size.x = 72
	stamina_row.add_child(stamina_title)
	stamina_bar = ProgressBar.new()
	stamina_bar.max_value = Tune.STAMINA_MAX
	stamina_bar.show_percentage = false
	stamina_bar.custom_minimum_size = Vector2(145, 12)
	stamina_row.add_child(stamina_bar)
	bars.add_child(stamina_row)
	save_label = Label.new()
	save_label.text = ""
	save_label.add_theme_font_size_override("font_size", 12)
	bars.add_child(save_label)

func _create_crosshair() -> void:
	var crosshair := Label.new()
	crosshair.text = "·"
	crosshair.add_theme_font_size_override("font_size", 30)
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-6, -21)
	root.add_child(crosshair)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	prompt_label.position = Vector2(-260, 400)
	prompt_label.custom_minimum_size = Vector2(520, 32)
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.78))
	root.add_child(prompt_label)
	progress_bar = ProgressBar.new()
	progress_bar.set_anchors_preset(Control.PRESET_CENTER)
	progress_bar.position = Vector2(-90, 48)
	progress_bar.custom_minimum_size = Vector2(180, 8)
	progress_bar.max_value = 1.0
	progress_bar.show_percentage = false
	progress_bar.visible = false
	root.add_child(progress_bar)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.position = Vector2(-300, -142)
	toast_label.custom_minimum_size = Vector2(600, 34)
	toast_label.add_theme_font_size_override("font_size", 17)
	toast_label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.68))
	root.add_child(toast_label)
	build_label = Label.new()
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	build_label.position = Vector2(-300, 76)
	build_label.custom_minimum_size = Vector2(600, 42)
	build_label.add_theme_font_size_override("font_size", 18)
	root.add_child(build_label)
	focus_label = Label.new()
	focus_label.name = "Click To Control"
	focus_label.text = "CLICK TO CONTROL"
	focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	focus_label.set_anchors_preset(Control.PRESET_CENTER)
	focus_label.position = Vector2(-120, 72)
	focus_label.custom_minimum_size = Vector2(240, 48)
	focus_label.add_theme_font_size_override("font_size", 18)
	focus_label.add_theme_color_override("font_color", Color(1.0, 0.89, 0.68))
	focus_label.visible = not OS.has_feature("mobile")
	focus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(focus_label)

func _create_hotbar() -> void:
	hotbar = HBoxContainer.new()
	hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar.position = Vector2(-252, -76)
	hotbar.add_theme_constant_override("separation", 5)
	hotbar.visible = not player._uses_touch_controls()
	root.add_child(hotbar)
	for index in range(Tune.HOTBAR_SLOTS):
		var panel := PanelContainer.new()
		panel.name = "Slot %d" % (index + 1)
		panel.custom_minimum_size = Vector2(78, 54)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "%d\n—" % (index + 1)
		panel.add_child(label)
		hotbar.add_child(panel)
		hotbar_labels.append(label)
	active_item_label = Label.new()
	active_item_label.name = "Active Item Purpose"
	active_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_item_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	active_item_label.position = Vector2(-310, -112)
	active_item_label.custom_minimum_size = Vector2(620, 28)
	active_item_label.add_theme_font_size_override("font_size", 15)
	active_item_label.add_theme_color_override("font_color", Color(0.94, 0.84, 0.63))
	root.add_child(active_item_label)

func _create_inventory() -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.position = Vector2(-260, -245)
	inventory_panel.custom_minimum_size = Vector2(520, 490)
	inventory_panel.visible = false
	root.add_child(inventory_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	inventory_panel.add_child(margin)
	var inventory_column := VBoxContainer.new()
	inventory_column.custom_minimum_size.x = 470
	margin.add_child(inventory_column)
	var title := Label.new()
	title.text = "PACK"
	title.add_theme_font_size_override("font_size", 24)
	inventory_column.add_child(title)
	inventory_text = RichTextLabel.new()
	inventory_text.bbcode_enabled = true
	inventory_text.fit_content = false
	inventory_text.custom_minimum_size = Vector2(470, 350)
	inventory_column.add_child(inventory_text)
	var item_actions := HBoxContainer.new()
	inventory_column.add_child(item_actions)
	var split_button := Button.new()
	split_button.text = "SPLIT"
	split_button.tooltip_text = "Split the selected hotbar stack in half"
	split_button.pressed.connect(func(): game.split_selected_stack())
	item_actions.add_child(split_button)
	var move_left_button := Button.new()
	move_left_button.text = "← MOVE"
	move_left_button.pressed.connect(func(): game.move_selected_slot(-1))
	item_actions.add_child(move_left_button)
	var move_right_button := Button.new()
	move_right_button.text = "MOVE →"
	move_right_button.pressed.connect(func(): game.move_selected_slot(1))
	item_actions.add_child(move_right_button)
	var drop_one_button := Button.new()
	drop_one_button.text = "DROP ONE"
	drop_one_button.pressed.connect(func(): game.drop_selected_item(1))
	item_actions.add_child(drop_one_button)
	var drop_stack_button := Button.new()
	drop_stack_button.text = "DROP STACK"
	drop_stack_button.pressed.connect(func(): game.drop_selected_item(-1))
	item_actions.add_child(drop_stack_button)
func _add_slider(parent: Control, title: String, key: String, minimum: float, maximum: float, step: float) -> HSlider:
	var label := Label.new()
	label.text = title
	parent.add_child(label)
	var slider := HSlider.new()
	slider.name = key
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(player.settings.get(key, minimum))
	slider.custom_minimum_size = Vector2(280, 30)
	slider.value_changed.connect(func(value: float): game.apply_setting(key, value))
	parent.add_child(slider)
	_settings_controls[key] = slider
	return slider

func _create_settings() -> void:
	settings_button = Button.new()
	settings_button.name = "Settings Button"
	settings_button.text = "⚙ SETTINGS"
	settings_button.tooltip_text = "Open settings and controls"
	settings_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	settings_button.position = Vector2(-164, 18)
	settings_button.custom_minimum_size = Vector2(144, 76)
	settings_button.add_theme_font_size_override("font_size", 17)
	settings_button.z_index = 60
	settings_button.pressed.connect(toggle_settings)
	root.add_child(settings_button)

	settings_panel = PanelContainer.new()
	settings_panel.name = "Settings"
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-360, -310)
	settings_panel.custom_minimum_size = Vector2(720, 620)
	settings_panel.visible = false
	settings_panel.z_index = 50
	root.add_child(settings_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	settings_panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 28)
	stack.add_child(title)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	stack.add_child(columns)
	var camera_column := VBoxContainer.new()
	camera_column.custom_minimum_size.x = 320
	columns.add_child(camera_column)
	_add_slider(camera_column, "Mouse-look sensitivity", "look_sensitivity", 0.0006, 0.006, 0.0001)
	_add_slider(camera_column, "Touch-look sensitivity", "touch_sensitivity", 0.001, 0.009, 0.0001)
	_add_slider(camera_column, "Motion / camera bob", "bob_intensity", 0.0, 1.0, 0.05)
	_add_slider(camera_column, "Master / audio volume", "audio_volume", 0.0, 1.0, 0.05)
	var invert := CheckButton.new()
	invert.name = "invert_look"
	invert.text = "Invert vertical look"
	invert.custom_minimum_size.y = 48
	invert.button_pressed = bool(player.settings.get("invert_look", false))
	invert.toggled.connect(func(value: bool): game.apply_setting("invert_look", value))
	camera_column.add_child(invert)
	_settings_controls["invert_look"] = invert

	var touch_column := VBoxContainer.new()
	touch_column.custom_minimum_size.x = 320
	columns.add_child(touch_column)
	_add_slider(touch_column, "Mobile control scale", "touch_scale", Tune.TOUCH_MIN_SCALE, Tune.TOUCH_MAX_SCALE, 0.05)
	_add_slider(touch_column, "Mobile control opacity", "touch_opacity", Tune.TOUCH_MIN_OPACITY, Tune.TOUCH_MAX_OPACITY, 0.05)
	var side_label := Label.new()
	side_label.text = "Mobile control side"
	touch_column.add_child(side_label)
	var side := OptionButton.new()
	side.name = "control_side"
	side.custom_minimum_size.y = 48
	side.add_item("Move left / look right")
	side.add_item("Move right / look left")
	side.selected = 1 if str(player.settings.get("control_side", "left_move")) == "right_move" else 0
	side.item_selected.connect(func(index: int): game.apply_setting("control_side", "right_move" if index == 1 else "left_move"))
	touch_column.add_child(side)
	_settings_controls["control_side"] = side
	fullscreen_button = Button.new()
	fullscreen_button.text = "FULLSCREEN / FILL SCREEN"
	fullscreen_button.custom_minimum_size.y = 52
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	touch_column.add_child(fullscreen_button)
	var reset_button := Button.new()
	reset_button.text = "RESET CONTROLS"
	reset_button.custom_minimum_size.y = 52
	reset_button.pressed.connect(_reset_controls)
	touch_column.add_child(reset_button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	stack.add_child(actions)
	var help_button := Button.new()
	help_button.text = "CONTROLS / HELP"
	help_button.custom_minimum_size = Vector2(210, 54)
	help_button.pressed.connect(toggle_help)
	actions.add_child(help_button)
	var save_button := Button.new()
	save_button.text = "SAVE NOW"
	save_button.custom_minimum_size = Vector2(180, 54)
	save_button.pressed.connect(func(): game.save_now("explicit"))
	actions.add_child(save_button)
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(180, 54)
	close_button.pressed.connect(toggle_settings)
	actions.add_child(close_button)

func _create_help() -> void:
	help_panel = PanelContainer.new()
	help_panel.name = "Control Help"
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.position = Vector2(-340, -260)
	help_panel.custom_minimum_size = Vector2(680, 520)
	help_panel.visible = false
	help_panel.z_index = 55
	root.add_child(help_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	help_panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "CONTROLS"
	title.add_theme_font_size_override("font_size", 28)
	stack.add_child(title)
	var body := Label.new()
	body.name = "Contextual Control Help"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(620, 360)
	body.add_theme_font_size_override("font_size", 18)
	body.text = _control_help_text()
	stack.add_child(body)
	var close := Button.new()
	close.text = "BACK TO SETTINGS"
	close.custom_minimum_size.y = 56
	close.pressed.connect(toggle_help)
	stack.add_child(close)

func _create_crafting() -> void:
	crafting_panel = PanelContainer.new()
	crafting_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	crafting_panel.position = Vector2(-375, -205)
	crafting_panel.custom_minimum_size = Vector2(350, 410)
	crafting_panel.visible = false
	root.add_child(crafting_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	crafting_panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "HAND CRAFTING"
	title.add_theme_font_size_override("font_size", 23)
	stack.add_child(title)
	for recipe: Dictionary in RecipeDB.all():
		var button := Button.new()
		button.text = "%s\n%s" % [recipe.name, _cost_text(recipe.ingredients)]
		button.custom_minimum_size.y = 64
		button.pressed.connect(_craft_pressed.bind(str(recipe.id)))
		stack.add_child(button)
	crafting_queue_label = Label.new()
	crafting_queue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(crafting_queue_label)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel current craft"
	cancel_button.pressed.connect(func(): game.cancel_craft())
	stack.add_child(cancel_button)

func _create_debug() -> void:
	debug_label = Label.new()
	debug_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	debug_label.position = Vector2(-315, 84)
	debug_label.custom_minimum_size = Vector2(290, 210)
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	debug_label.add_theme_font_size_override("font_size", 13)
	debug_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.7))
	debug_label.visible = false
	root.add_child(debug_label)

func refresh() -> void:
	warmth_bar.value = game.warmth
	stamina_bar.value = player.stamina
	objective_label.text = game.current_objective()
	time_label.text = "%s  ·  %s  ·  FIRE %s" % [game.clock_text(), game.exposure_text(), game.fire_status_text()]
	var inventory: Inventory = game.inventory
	for index in range(Tune.HOTBAR_SLOTS):
		var text := "%d\n—" % (index + 1)
		if index < inventory.slots.size():
			var slot: Dictionary = inventory.slots[index]
			var definition := ItemDB.get_item(str(slot.item_id))
			text = "%d  %s\n%s ×%d" % [index + 1, definition.get("icon", "•"), definition.get("name", slot.item_id), int(slot.quantity)]
		hotbar_labels[index].text = text
		hotbar_labels[index].modulate = Color(1.0, 0.84, 0.45) if index == player.selected_hotbar else Color.WHITE
	var active_id := player.selected_item_id()
	var active_definition := ItemDB.get_item(active_id)
	var purpose := str(active_definition.get("use_behavior", ""))
	var purpose_text: String = str({
		"harvest": "Primary action harvests efficiently",
		"build": "B / BUILD opens shelter placement",
		"place_campfire": "Selected for immediate campfire placement",
		"fuel": "Interact with a campfire to add fuel"
	}.get(purpose, "Select an item to see its purpose"))
	active_item_label.text = "ACTIVE · %s · %s" % [active_definition.get("name", "Empty"), purpose_text]
	if inventory_panel.visible:
		var lines: Array[String] = []
		for index in range(inventory.slots.size()):
			var slot: Dictionary = inventory.slots[index]
			lines.append("[color=#d8c79f]%02d[/color]  %s  ×%d" % [index + 1, ItemDB.display_name(str(slot.item_id)), int(slot.quantity)])
		if lines.is_empty():
			lines.append("[color=#888888]Empty. The beach is full of useful debris.[/color]")
		inventory_text.text = "\n".join(lines) + "\n\n[color=#89979a]Stacks merge automatically. Overflow remains in the world.[/color]"
	crafting_queue_label.text = game.crafting_text()
	debug_label.visible = bool(player.settings.get("debug_overlay", false))
	if debug_label.visible:
		debug_label.text = game.debug_text()

func toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		crafting_panel.visible = false
		settings_panel.visible = false
		help_panel.visible = false
	_sync_modal_state()

func toggle_crafting() -> void:
	crafting_panel.visible = not crafting_panel.visible
	if crafting_panel.visible:
		inventory_panel.visible = false
		settings_panel.visible = false
		help_panel.visible = false
	_sync_modal_state()

func toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	help_panel.visible = false
	if settings_panel.visible:
		inventory_panel.visible = false
		crafting_panel.visible = false
	else:
		game.save_now("settings")
	_sync_modal_state()

func toggle_help() -> void:
	help_panel.visible = not help_panel.visible
	settings_panel.visible = not help_panel.visible
	_sync_modal_state()

func close_modals() -> void:
	var settings_was_open := settings_panel.visible or help_panel.visible
	inventory_panel.visible = false
	crafting_panel.visible = false
	settings_panel.visible = false
	help_panel.visible = false
	if settings_was_open:
		game.save_now("settings")
	_sync_modal_state()

func _any_modal_open() -> bool:
	return inventory_panel.visible or crafting_panel.visible or settings_panel.visible or help_panel.visible

func _sync_modal_state() -> void:
	player.set_menu_open(_any_modal_open())
	WebRuntimeBridge.publish({
		"settingsButtonVisible": settings_button.visible,
		"settingsOpen": settings_panel.visible,
		"helpOpen": help_panel.visible,
		"menuOpen": _any_modal_open()
	})

func set_prompt(text: String) -> void:
	prompt_label.text = text

func set_interaction_progress(value: float) -> void:
	progress_bar.value = clampf(value, 0.0, 1.0)
	progress_bar.visible = value > 0.0 and value < 1.0

func notify(message: String) -> void:
	toast_label.text = message
	toast_label.modulate.a = 1.0
	_toast_remaining = Tune.NOTIFICATION_SECONDS

func set_hotbar_selection(index: int) -> void:
	player.selected_hotbar = clampi(index, 0, Tune.HOTBAR_SLOTS - 1)

func set_build_status(active: bool, piece_id: String, valid: bool, reason: String = "") -> void:
	if not active:
		build_label.text = ""
		return
	var definition := BuildingDB.get_piece(piece_id)
	var color := "#7ee09a" if valid else "#ef766c"
	var controls := "Left click / PLACE confirms · Right click / Esc / CANCEL exits"
	build_label.text = "[%s] %s · %s\n%s" % ["VALID" if valid else "BLOCKED", definition.get("name", piece_id), reason, controls]
	build_label.add_theme_color_override("font_color", Color.html(color))
	WebRuntimeBridge.publish({
		"placementStatusVisible": active,
		"placementStatus": build_label.text,
		"placementInstructionsVisible": active
	})

func set_focus_prompt(visible_value: bool) -> void:
	if focus_label:
		focus_label.visible = visible_value
	WebRuntimeBridge.publish({"focusPromptVisible": visible_value})

func show_save_status(text: String) -> void:
	save_label.text = text

func show_morning_report(report: Dictionary) -> void:
	var overlay := ColorRect.new()
	overlay.name = "Morning Report"
	overlay.color = Color(0.015, 0.025, 0.035, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -210)
	panel.custom_minimum_size = Vector2(620, 420)
	overlay.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "MORNING REPORT"
	title.add_theme_font_size_override("font_size", 28)
	stack.add_child(title)
	var elapsed := float(report.get("elapsed_real_seconds", 0.0))
	var advanced := float(report.get("world_advanced_seconds", 0.0))
	var fire_duration := float(report.get("fire_duration_seconds", 0.0))
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 230
	var requested_elapsed := float(report.get("requested_elapsed_seconds", elapsed))
	var cap_note := " (fairness cap applied)" if requested_elapsed > elapsed else ""
	body.text = "Away: %s\nConsequences reconciled: %s%s\nWorld advanced: %s\nFire burned: %s\nFire went out: %s\nShelter protected you: %s\nWarmth: %.1f → %.1f (%+.1f)\n\n%s" % [
		_duration(requested_elapsed), _duration(elapsed), cap_note, _duration(advanced), _duration(fire_duration),
		"yes" if bool(report.get("fire_went_out", false)) else "no",
		"yes" if bool(report.get("sheltered", false)) else "no",
		float(report.get("warmth_before", 0.0)), float(report.get("warmth_after", 0.0)),
		float(report.get("warmth_change", 0.0)), str(report.get("cause", ""))
	]
	stack.add_child(body)
	var close := Button.new()
	close.text = "RETURN TO THE BEACH"
	close.pressed.connect(func(): overlay.queue_free(); player.set_menu_open(false); set_focus_prompt(not player._uses_touch_controls()))
	stack.add_child(close)
	player.set_menu_open(true)

func _craft_pressed(recipe_id: String) -> void:
	game.request_craft(recipe_id)

func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	game.notify_player("Fullscreen request sent. Browser permission may be required.", "confirm")
	WebRuntimeBridge.publish({"fullscreenRequested": true})

func _reset_controls() -> void:
	var defaults := WorldState.default_settings()
	for key in ["look_sensitivity", "touch_sensitivity", "invert_look", "bob_intensity", "audio_volume", "control_side", "touch_scale", "touch_opacity"]:
		game.apply_setting(key, defaults[key])
	for key: String in _settings_controls:
		var control: Control = _settings_controls[key]
		if control is HSlider:
			(control as HSlider).value = float(defaults[key])
		elif control is CheckButton:
			(control as CheckButton).button_pressed = bool(defaults[key])
		elif control is OptionButton:
			(control as OptionButton).selected = 1 if str(defaults[key]) == "right_move" else 0
	game.notify_player("Controls reset to defaults.", "confirm")

func _control_help_text() -> String:
	if player._uses_touch_controls():
		return "MOBILE\n\nMove · visible joystick\nLook · swipe the labelled look region\nInteract / Action · right-side buttons\nJump / Crouch · right-side buttons\nHotbar · numbered touch buttons\nPlacement · PLACE, CANCEL, and ROTATE appear above the hotbar\nSettings · top-right gear"
	return "DESKTOP\n\nMove · WASD\nLook / focus · click inside the game; Esc releases\nInteract · E\nInventory / crafting · I or Tab / K\nHotbar · number keys 1–6\nPlacement · left click confirms; right click or Esc cancels; Q/R rotates\nSettings · top-right gear"

func _publish_layout_state() -> void:
	if not is_inside_tree() or root.size.x <= 1.0 or root.size.y <= 1.0:
		return
	var center := settings_button.get_global_rect().get_center()
	WebRuntimeBridge.publish({
		"settingsButtonVisible": settings_button.visible,
		"settingsButton": [center.x / root.size.x, center.y / root.size.y]
	})

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id: String in cost:
		parts.append("%s ×%d" % [ItemDB.display_name(item_id), int(cost[item_id])])
	return " · ".join(parts)

func _duration(seconds: float) -> String:
	var total := maxi(0, roundi(seconds))
	if total >= 3600:
		return "%dh %02dm" % [total / 3600, (total % 3600) / 60]
	if total >= 60:
		return "%dm %02ds" % [total / 60, total % 60]
	return "%ds" % total
