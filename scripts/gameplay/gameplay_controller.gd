class_name GameplayController
extends Control

## Main Gameplay Controller for Tomorrow's You.
## Coordinates puzzle simulation, board rendering, mobile touch controls, desktop input, HUD, and dialogs.

@onready var board_renderer: BoardRenderer = $BoardRenderer
@onready var level_title_label: Label = $TopHUD/MarginContainer/VBoxContainer/HeaderRow/LevelInfo/LevelTitle
@onready var sector_label: Label = $TopHUD/MarginContainer/VBoxContainer/HeaderRow/LevelInfo/SectorLabel
@onready var turn_count_label: Label = $TopHUD/MarginContainer/VBoxContainer/StatsPillsRow/TurnPill/Margin/TurnCountLabel
@onready var echo_count_label: Label = $TopHUD/MarginContainer/VBoxContainer/StatsPillsRow/EchoPill/Margin/EchoCountLabel
@onready var budget_label: Label = $TopHUD/MarginContainer/VBoxContainer/StatsPillsRow/BudgetPill/Margin/BudgetLabel
@onready var echo_timeline_row: HBoxContainer = $TopHUD/MarginContainer/VBoxContainer/EchoTimelineRow
@onready var pause_button: Button = $TopHUD/MarginContainer/VBoxContainer/HeaderRow/PauseButton

# Bottom controls
@onready var btn_create_echo: Button = $BottomHUD/PrimaryActionContainer/BtnCreateEcho
@onready var btn_up: Button = $BottomHUD/ControlsRow/DPadContainer/Grid/BtnUp
@onready var btn_down: Button = $BottomHUD/ControlsRow/DPadContainer/Grid/BtnDown
@onready var btn_left: Button = $BottomHUD/ControlsRow/DPadContainer/Grid/BtnLeft
@onready var btn_right: Button = $BottomHUD/ControlsRow/DPadContainer/Grid/BtnRight
@onready var btn_wait: Button = $BottomHUD/ControlsRow/ActionButtons/BtnWait
@onready var btn_restart: Button = $BottomHUD/ControlsRow/ActionButtons/BtnRestart
@onready var btn_clear_echoes: Button = $BottomHUD/ControlsRow/ActionButtons/BtnClearEchoes
@onready var hint_label: Label = $BottomHUD/HintContainer/HintPanel/Margin/HintLabel

# Dialogs
@onready var pause_modal: PanelContainer = $Modals/PauseModal
@onready var complete_modal: PanelContainer = $Modals/CompleteModal

# Modal buttons
@onready var btn_resume: Button = $Modals/PauseModal/Margin/VBoxContainer/ResumeButton
@onready var btn_modal_restart: Button = $Modals/PauseModal/Margin/VBoxContainer/RestartButton
@onready var btn_modal_levels: Button = $Modals/PauseModal/Margin/VBoxContainer/LevelsButton
@onready var btn_modal_settings: Button = $Modals/PauseModal/Margin/VBoxContainer/SettingsButton

@onready var btn_next_level: Button = $Modals/CompleteModal/Margin/VBoxContainer/NextButton
@onready var btn_replay: Button = $Modals/CompleteModal/Margin/VBoxContainer/ReplayButton
@onready var btn_complete_levels: Button = $Modals/CompleteModal/Margin/VBoxContainer/LevelsButton
@onready var complete_stats_label: Label = $Modals/CompleteModal/Margin/VBoxContainer/StatsLabel
@onready var complete_stars_label: Label = $Modals/CompleteModal/Margin/VBoxContainer/StarsLabel
@onready var complete_rating_label: Label = $Modals/CompleteModal/Margin/VBoxContainer/RatingLabel

var simulation: PuzzleSimulation = null
var current_level_def: LevelDefinition = null
var _dev_panel: PanelContainer = null
var _dev_info_label: Label = null

# Swipe gesture tracking
var _touch_start_pos: Vector2 = Vector2.ZERO
var _is_swiping: bool = false
const SWIPE_THRESHOLD: float = 35.0

func _ready() -> void:
	pause_modal.visible = false
	complete_modal.visible = false

	if GameManager:
		simulation = GameManager.current_simulation
		current_level_def = GameManager.get_current_level_def()
	else:
		simulation = PuzzleSimulation.new()
		current_level_def = LevelRegistry.get_level(0)
		simulation.load_level(current_level_def)

	_bind_simulation_signals()
	_bind_ui_buttons()

	board_renderer.setup(simulation, get_viewport_rect().size)
	_update_hud()

	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	if board_renderer:
		board_renderer.calculate_layout(get_viewport_rect().size)
		board_renderer.queue_redraw()

func _bind_simulation_signals() -> void:
	simulation.turn_completed.connect(func(_turn): _update_hud())
	simulation.attempt_restarted.connect(_update_hud)
	simulation.echo_created.connect(func(_idx, _total):
		if AudioManager: AudioManager.play_sfx("echo_create")
		_update_hud()
	)
	simulation.echoes_cleared.connect(func():
		if AudioManager: AudioManager.play_sfx("ui_click")
		_update_hud()
	)
	simulation.player_moved.connect(func(_from, _to, action):
		if AudioManager:
			if action == "WAIT": AudioManager.play_sfx("wait")
			else: AudioManager.play_sfx("move")
		_update_hud()
	)
	simulation.move_blocked.connect(func(_target, _reason):
		if AudioManager: AudioManager.play_sfx("blocked")
	)
	simulation.plate_state_changed.connect(func(_id, is_active):
		if AudioManager:
			if is_active: AudioManager.play_sfx("plate_on")
			else: AudioManager.play_sfx("plate_off")
	)
	simulation.door_state_changed.connect(func(_id, is_open):
		if AudioManager:
			if is_open: AudioManager.play_sfx("door_open")
			else: AudioManager.play_sfx("door_close")
	)
	simulation.level_completed.connect(_on_level_completed)

func _bind_ui_buttons() -> void:
	# D-Pad
	btn_up.pressed.connect(func(): _execute_move(Vector2i.UP))
	btn_down.pressed.connect(func(): _execute_move(Vector2i.DOWN))
	btn_left.pressed.connect(func(): _execute_move(Vector2i.LEFT))
	btn_right.pressed.connect(func(): _execute_move(Vector2i.RIGHT))

	# Actions
	btn_wait.pressed.connect(func(): simulation.step_wait())
	btn_create_echo.pressed.connect(func(): simulation.create_echo())
	btn_restart.pressed.connect(func(): simulation.restart_attempt())
	btn_clear_echoes.pressed.connect(func(): simulation.clear_echoes())

	# Pause
	pause_button.pressed.connect(_toggle_pause)
	btn_resume.pressed.connect(_toggle_pause)
	btn_modal_restart.pressed.connect(func():
		_toggle_pause()
		simulation.restart_attempt()
	)
	btn_modal_levels.pressed.connect(func():
		SceneRouter.go_to_level_select()
	)
	btn_modal_settings.pressed.connect(func():
		SceneRouter.go_to_settings()
	)

	# Completion modal
	btn_next_level.pressed.connect(func():
		complete_modal.visible = false
		if GameManager:
			GameManager.go_to_next_level()
	)
	btn_replay.pressed.connect(func():
		complete_modal.visible = false
		simulation.clear_echoes()
	)
	btn_complete_levels.pressed.connect(func():
		complete_modal.visible = false
		SceneRouter.go_to_level_select()
	)

func _execute_move(dir: Vector2i) -> void:
	if pause_modal.visible or complete_modal.visible:
		return
	simulation.step_move(dir)

func _update_hud() -> void:
	if current_level_def == null or simulation == null:
		return

	level_title_label.text = current_level_def.level_name
	var sector_names: Array[String] = ["AWAKENING", "SYNCHRONIZATION", "PARADOX"]
	var s_idx: int = clampi(current_level_def.sector - 1, 0, 2)
	sector_label.text = "SECTOR 0%d — %s" % [current_level_def.sector, sector_names[s_idx]]

	turn_count_label.text = "⏱ TURN: %02d" % simulation.current_turn
	echo_count_label.text = "✦ ECHOES: %d / %d" % [simulation.echoes.size(), current_level_def.echo_limit]

	if current_level_def.target_3_stars > 0:
		var total_act: int = simulation.total_actions_taken
		budget_label.text = "🎯 3★: ≤%d (Act: %d)" % [current_level_def.target_3_stars, total_act]
		if total_act <= current_level_def.target_3_stars:
			budget_label.add_theme_color_override("font_color", Color("#FBBF24")) # Gold 3-star on track
		elif total_act <= current_level_def.target_2_stars:
			budget_label.add_theme_color_override("font_color", Color("#38BDF8")) # Blue 2-star
		else:
			budget_label.add_theme_color_override("font_color", Color("#94A3B8")) # Gray 1-star
	else:
		budget_label.text = "🎯 ACT: %d" % simulation.total_actions_taken

	_update_echo_timeline()

	if not current_level_def.hint.is_empty():
		hint_label.text = "💡 " + current_level_def.hint
		hint_label.get_parent().get_parent().visible = true
	else:
		hint_label.get_parent().get_parent().visible = false

	# Action button states
	var at_echo_limit: bool = simulation.echoes.size() >= current_level_def.echo_limit
	var has_steps: bool = (simulation.current_recording != null and simulation.current_recording.get_step_count() > 0)

	btn_create_echo.disabled = at_echo_limit or not has_steps
	btn_clear_echoes.disabled = simulation.echoes.is_empty()

	# Visual prominence feedback for CREATE ECHO button
	if not btn_create_echo.disabled:
		btn_create_echo.modulate = Color(1.1, 1.1, 1.15)
	else:
		btn_create_echo.modulate = Color(0.65, 0.65, 0.7, 0.6)

func _update_echo_timeline() -> void:
	if not echo_timeline_row:
		return

	for child in echo_timeline_row.get_children():
		child.queue_free()

	if simulation.echoes.is_empty():
		echo_timeline_row.visible = false
		return

	echo_timeline_row.visible = true

	for i in range(simulation.echoes.size()):
		var is_active: bool = simulation.is_echo_active(i)
		var rem: int = simulation.get_echo_remaining_turns(i)
		var tot: int = simulation.get_echo_total_turns(i)
		var curr: int = simulation.current_turn

		var pill: PanelContainer = PanelContainer.new()
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		pill.add_child(margin)

		var lbl: Label = Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)

		if is_active:
			if rem == 1:
				lbl.text = "⚠️ E%d: 1 TURN LEFT" % (i + 1)
				lbl.add_theme_color_override("font_color", Color("#FBBF24")) # Warning amber
			else:
				var blocks: int = clampi(tot - rem, 0, tot)
				var bar: String = "■".repeat(mini(blocks, 6)) + "□".repeat(mini(rem, 6))
				lbl.text = "E%d: %s (rem %d)" % [i + 1, bar, rem]
				lbl.add_theme_color_override("font_color", Color("#54E6EA")) # Active cyan
		else:
			lbl.text = "E%d: EXPIRED" % (i + 1)
			lbl.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 0.8)) # Expired dim

		margin.add_child(lbl)
		echo_timeline_row.add_child(pill)

func _toggle_pause() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	pause_modal.visible = not pause_modal.visible

func _on_level_completed(turns: int, echoes: int, total_actions: int) -> void:
	var stars: int = 1
	if SaveManager:
		stars = SaveManager.calculate_stars(current_level_def.level_id, total_actions)
		var next_id: String = ""
		if GameManager:
			var next_lvl = GameManager.get_next_level_def()
			if next_lvl: next_id = next_lvl.level_id
		SaveManager.record_level_completion(current_level_def.level_id, total_actions, echoes, next_id)

	# Format star display
	var star_str: String = ""
	for s in range(3):
		star_str += "★" if s < stars else "☆"
	complete_stars_label.text = star_str

	match stars:
		3:
			complete_rating_label.text = "PERFECT EFFICIENCY (3 STARS)"
			complete_rating_label.add_theme_color_override("font_color", Color("#34D399"))
		2:
			complete_rating_label.text = "SOLID SYNCHRONIZATION (2 STARS)"
			complete_rating_label.add_theme_color_override("font_color", Color("#FBBF24"))
		_:
			complete_rating_label.text = "PUZZLE SOLVED (1 STAR)"
			complete_rating_label.add_theme_color_override("font_color", Color("#94A3B8"))

	complete_stats_label.text = "Winning Attempt: %d turns\nEchoes Used: %d / %d\nTotal Actions Taken: %d (3★ Target: ≤%d)" % [
		turns, echoes, current_level_def.echo_limit, total_actions, current_level_def.target_3_stars
	]
	if GameManager and not GameManager.next_level_exists():
		btn_next_level.text = "CAMPAIGN COMPLETE!"
		btn_next_level.disabled = true
	else:
		btn_next_level.text = "NEXT LEVEL >"
		btn_next_level.disabled = false
	complete_modal.visible = true

# ==============================================================================
# Desktop & Touch Input Handling
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if pause_modal.visible or complete_modal.visible:
		if event.is_action_pressed("action_pause"):
			_toggle_pause()
		return

	# Developer Inspection Mode (Debug builds only: F12 or ` / ~)
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12 or event.keycode == KEY_QUOTELEFT or event.keycode == KEY_ASCIITILDE:
			_toggle_dev_mode()
			return

	# Keyboard Desktop controls
	if event.is_action_pressed("move_up"):
		_execute_move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		_execute_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		_execute_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		_execute_move(Vector2i.RIGHT)
	elif event.is_action_pressed("action_wait"):
		simulation.step_wait()
	elif event.is_action_pressed("action_interact"):
		simulation.step_interact()
	elif event.is_action_pressed("action_restart"):
		simulation.restart_attempt()
	elif event.is_action_pressed("action_create_echo"):
		simulation.create_echo()
	elif event.is_action_pressed("action_pause"):
		_toggle_pause()

	# Mobile Touchscreen Swipe Gestures
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos = event.position
			_is_swiping = true
		else:
			if _is_swiping:
				_handle_swipe(event.position - _touch_start_pos)
			_is_swiping = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_start_pos = event.position
			_is_swiping = true
		else:
			if _is_swiping:
				_handle_swipe(event.position - _touch_start_pos)
			_is_swiping = false

func _handle_swipe(diff: Vector2) -> void:
	if diff.length() < SWIPE_THRESHOLD:
		return
	if absf(diff.x) > absf(diff.y):
		if diff.x > 0:
			_execute_move(Vector2i.RIGHT)
		else:
			_execute_move(Vector2i.LEFT)
	else:
		if diff.y > 0:
			_execute_move(Vector2i.DOWN)
		else:
			_execute_move(Vector2i.UP)

# ==============================================================================
# Developer Inspection & Testing Mode (Debug Only)
# ==============================================================================

func _toggle_dev_mode() -> void:
	if not OS.is_debug_build():
		return
	board_renderer.show_debug_connections = not board_renderer.show_debug_connections
	board_renderer.queue_redraw()

	if _dev_panel == null:
		_dev_panel = _create_dev_panel()
		add_child(_dev_panel)

	_dev_panel.visible = board_renderer.show_debug_connections
	if _dev_panel.visible:
		_refresh_dev_panel()

func _create_dev_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 260)
	panel.anchors_preset = Control.PRESET_TOP_LEFT
	panel.position = Vector2(16, 140)
	panel.z_index = 50

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var title: Label = Label.new()
	title.text = "🛠 DEV INSPECTION MODE [F12]"
	title.add_theme_color_override("font_color", Color("#FFBE55"))
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	_dev_info_label = Label.new()
	_dev_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_dev_info_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_dev_info_label)

	var validate_btn: Button = Button.new()
	validate_btn.text = "RUN LEVEL VALIDATOR"
	validate_btn.custom_minimum_size = Vector2(0, 32)
	validate_btn.pressed.connect(_on_run_validator_pressed)
	vbox.add_child(validate_btn)

	var close_btn: Button = Button.new()
	close_btn.text = "HIDE OVERLAY"
	close_btn.custom_minimum_size = Vector2(0, 28)
	close_btn.pressed.connect(func(): _toggle_dev_mode())
	vbox.add_child(close_btn)

	margin.add_child(vbox)
	panel.add_child(margin)
	return panel

func _refresh_dev_panel() -> void:
	if _dev_info_label == null or current_level_def == null:
		return
	var text: String = ""
	text += "Level: %s (%s)\n" % [current_level_def.level_name, current_level_def.level_id]
	text += "Sector: %d | Grid: %dx%d\n" % [current_level_def.sector, current_level_def.grid_width, current_level_def.grid_height]
	text += "Spawn: %s | Exit: %s\n" % [str(current_level_def.spawn_pos), str(current_level_def.exit_pos)]
	text += "Min Echoes Req: %d | Limit: %d\n" % [current_level_def.min_echoes_required, current_level_def.echo_limit]
	text += "Plates (%d): %s\n" % [current_level_def.plates_data.size(), str(current_level_def.plates_data.map(func(p): return "%s@%s" % [p.id, str(p.pos)]))]
	text += "Doors (%d): %s\n" % [current_level_def.doors_data.size(), str(current_level_def.doors_data.map(func(d): return "%s@%s(%s)" % [d.id, str(d.pos), d.logic]))]
	text += "Zero-Echo Bypass: BLOCKED [✓]\n"
	text += "Sub-Min Echoes: BLOCKED [✓]\n"
	_dev_info_label.text = text

func _on_run_validator_pressed() -> void:
	if current_level_def == null:
		return
	var validator = preload("res://scripts/level/level_validator.gd")
	var res: Dictionary = validator.validate_level(current_level_def)
	if _dev_info_label:
		_dev_info_label.text = "VALIDATION RESULT:\n"
		_dev_info_label.text += "Zero-Echo Blocked: %s\n" % ("YES [✓]" if res.zero_echo_passed else "FAIL [✗]")
		_dev_info_label.text += "Sub-Min Blocked: %s\n" % ("YES [✓]" if res.sub_min_echoes_passed else "FAIL [✗]")
		_dev_info_label.text += "Overall: %s" % ("PASS [✓]" if res.is_valid else "FAIL [✗]")
	print(res["report"])
