class_name GameplayController
extends Control

## Main Gameplay Controller for Tomorrow's You.
## Coordinates puzzle simulation, board rendering, mobile touch controls, desktop input, HUD, and dialogs.

const HintRegistryClass = preload("res://scripts/hints/hint_registry.gd")

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
@onready var btn_hint: Button = $BottomHUD/HintContainer/BtnHint

# Dialogs & Modals
@onready var pause_modal: PanelContainer = $Modals/PauseModal
@onready var complete_modal: PanelContainer = $Modals/CompleteModal

# Hint Modals
@onready var hint_modal: PanelContainer = $Modals/HintModal
@onready var hint_level_name: Label = $Modals/HintModal/Margin/VBoxContainer/HeaderBox/LevelNameLabel
@onready var hint_allowance_label: Label = $Modals/HintModal/Margin/VBoxContainer/HeaderBox/AllowanceLabel
@onready var hint_content_vbox: VBoxContainer = $Modals/HintModal/Margin/VBoxContainer/ScrollContainer/ContentVBox
@onready var btn_reveal_next: Button = $Modals/HintModal/Margin/VBoxContainer/BtnRevealNext
@onready var btn_close_hint: Button = $Modals/HintModal/Margin/VBoxContainer/BtnCloseHint

@onready var hint_confirm_modal: PanelContainer = $Modals/HintConfirmModal
@onready var btn_confirm_reveal: Button = $Modals/HintConfirmModal/Margin/VBoxContainer/BtnConfirmReveal
@onready var btn_cancel_reveal: Button = $Modals/HintConfirmModal/Margin/VBoxContainer/BtnCancelReveal

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
@onready var background: Control = $TemporalBackground

const ThemeManagerClass = preload("res://scripts/background/background_theme_manager.gd")

var simulation: PuzzleSimulation = null
var current_level_def: LevelDefinition = null
var _dev_panel: PanelContainer = null
var _dev_info_label: Label = null
var _level_completed_handled: bool = false

# Swipe gesture tracking
var _touch_start_pos: Vector2 = Vector2.ZERO
var _is_swiping: bool = false
const SWIPE_THRESHOLD: float = 35.0

func _ready() -> void:
	pause_modal.visible = false
	complete_modal.visible = false
	hint_modal.visible = false
	hint_confirm_modal.visible = false

	if GameManager:
		simulation = GameManager.current_simulation
		current_level_def = GameManager.get_current_level_def()
	else:
		simulation = PuzzleSimulation.new()
		current_level_def = LevelRegistry.get_level(0)
		simulation.load_level(current_level_def)

	_bind_simulation_signals()
	_bind_ui_buttons()
	_style_holographic_modals()

	if background and background.has_method("set_screen_mode"):
		var tier: int = current_level_def.difficulty_tier if current_level_def else 1
		background.set_screen_mode(ThemeManagerClass.ScreenMode.GAMEPLAY, tier)

	board_renderer.setup(simulation, get_viewport_rect().size)
	_update_hud()

	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	if board_renderer:
		board_renderer.calculate_layout(get_viewport_rect().size)
		board_renderer.queue_redraw()

func _bind_simulation_signals() -> void:
	simulation.turn_completed.connect(func(_turn): _update_hud())
	simulation.attempt_restarted.connect(func():
		_level_completed_handled = false
		if background and background.has_method("set_level_complete"):
			background.set_level_complete(false)
		_update_hud()
	)
	simulation.echo_created.connect(func(_idx, _total):
		if AudioManager: AudioManager.play_sfx("echo_create")
		_update_hud()
	)
	simulation.echoes_cleared.connect(func():
		_level_completed_handled = false
		if background and background.has_method("set_level_complete"):
			background.set_level_complete(false)
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

func _is_modal_active() -> bool:
	return _level_completed_handled or pause_modal.visible or complete_modal.visible or hint_modal.visible or hint_confirm_modal.visible

func _bind_ui_buttons() -> void:
	# D-Pad
	btn_up.pressed.connect(func(): if not _is_modal_active(): _execute_move(Vector2i.UP))
	btn_down.pressed.connect(func(): if not _is_modal_active(): _execute_move(Vector2i.DOWN))
	btn_left.pressed.connect(func(): if not _is_modal_active(): _execute_move(Vector2i.LEFT))
	btn_right.pressed.connect(func(): if not _is_modal_active(): _execute_move(Vector2i.RIGHT))

	# Actions
	btn_wait.pressed.connect(func(): if not _is_modal_active(): simulation.step_wait())
	btn_create_echo.pressed.connect(func(): if not _is_modal_active(): simulation.create_echo())
	btn_restart.pressed.connect(func(): if not _is_modal_active(): simulation.restart_attempt())
	btn_clear_echoes.pressed.connect(func(): if not _is_modal_active(): simulation.clear_echoes())

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
		_level_completed_handled = false
		if background and background.has_method("set_level_complete"):
			background.set_level_complete(false)
		simulation.clear_echoes()
	)
	btn_complete_levels.pressed.connect(func():
		complete_modal.visible = false
		SceneRouter.go_to_level_select()
	)

	# Hint system buttons
	btn_hint.pressed.connect(_open_hint_modal)
	btn_close_hint.pressed.connect(_close_hint_modal)
	btn_reveal_next.pressed.connect(_on_reveal_next_pressed)
	btn_confirm_reveal.pressed.connect(_on_confirm_reveal)
	btn_cancel_reveal.pressed.connect(_on_cancel_reveal)

	if SaveManager:
		SaveManager.daily_hints_reset.connect(_update_hint_button)
		SaveManager.hint_revealed.connect(func(_lid, _idx, _rem): _update_hint_button())

func _execute_move(dir: Vector2i) -> void:
	if _is_modal_active():
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
	_update_hint_button()

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
	if background and background.has_method("set_paused"):
		background.set_paused(pause_modal.visible)

func _on_level_completed(turns: int, echoes: int, total_actions: int) -> void:
	if _level_completed_handled:
		return
	_level_completed_handled = true

	var stars: int = 1
	if SaveManager:
		stars = SaveManager.calculate_stars(current_level_def.level_id, total_actions)
		var next_id: String = ""
		if GameManager and GameManager.next_level_exists():
			var next_lvl = GameManager.get_next_level_def()
			if next_lvl: next_id = next_lvl.level_id
		SaveManager.record_level_completion(current_level_def.level_id, total_actions, echoes, next_id)
		print("[SAVE] Level progress saved")

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
	print("[SCENE] Level Complete screen displayed")
	if background and background.has_method("set_level_complete"):
		background.set_level_complete(true)

func _style_holographic_modals() -> void:
	var make_panel_style = func(border_col: Color, fill_col: Color = Color(0.05, 0.075, 0.14, 0.96), border_w: int = 2) -> StyleBoxFlat:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = fill_col
		sb.border_color = border_col
		sb.set_border_width_all(border_w)
		sb.set_corner_radius_all(12)
		sb.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.22)
		sb.shadow_size = 14
		sb.shadow_offset = Vector2(0, 4)
		return sb

	if pause_modal:
		pause_modal.add_theme_stylebox_override("panel", make_panel_style.call(Color(0.329, 0.902, 0.918, 0.8)))
	if complete_modal:
		complete_modal.add_theme_stylebox_override("panel", make_panel_style.call(Color(0.329, 0.902, 0.918, 1.0), Color(0.06, 0.10, 0.18, 0.97), 2))
	if hint_modal:
		hint_modal.add_theme_stylebox_override("panel", make_panel_style.call(Color(1.0, 0.745, 0.333, 0.8)))
	if hint_confirm_modal:
		hint_confirm_modal.add_theme_stylebox_override("panel", make_panel_style.call(Color(1.0, 0.745, 0.333, 0.9)))

# ==============================================================================
# Desktop & Touch Input Handling
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if _is_modal_active():
		if event.is_action_pressed("action_pause"):
			if hint_confirm_modal.visible:
				_on_cancel_reveal()
			elif hint_modal.visible:
				_close_hint_modal()
			elif pause_modal.visible:
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

# ==============================================================================
# Progressive Daily Hint Assistance System
# ==============================================================================

func _update_hint_button() -> void:
	if not btn_hint:
		return
	var rem: int = SaveManager.get_remaining_daily_hints() if SaveManager else 3
	btn_hint.text = "💡 HINT · %d LEFT" % rem
	if rem > 0:
		btn_hint.modulate = Color(1.0, 1.0, 1.0)
	else:
		btn_hint.modulate = Color(0.65, 0.65, 0.7, 0.8)

func _open_hint_modal() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if SaveManager:
		SaveManager.check_and_apply_daily_reset()

	hint_level_name.text = current_level_def.level_name
	var rem: int = SaveManager.get_remaining_daily_hints() if SaveManager else 3
	hint_allowance_label.text = "Daily hints remaining: %d / %d" % [rem, SaveManager.DAILY_HINT_LIMIT if SaveManager else 3]

	for child in hint_content_vbox.get_children():
		child.queue_free()

	var highest_revealed: int = SaveManager.get_revealed_hint_index(current_level_def.level_id) if SaveManager else -1

	# 1. PREVIOUSLY REVEALED HINTS
	var prev_header: Label = Label.new()
	prev_header.text = "PREVIOUSLY REVEALED:"
	prev_header.add_theme_font_size_override("font_size", 14)
	prev_header.add_theme_color_override("font_color", Color("#94A3B8"))
	hint_content_vbox.add_child(prev_header)

	if highest_revealed >= 0:
		for s in range(highest_revealed + 1):
			var hdata: Dictionary = HintRegistryClass.get_hint_stage(current_level_def.level_id, s)
			if hdata.is_empty():
				continue

			var card: PanelContainer = PanelContainer.new()
			var margin: MarginContainer = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 12)
			margin.add_theme_constant_override("margin_right", 12)
			margin.add_theme_constant_override("margin_top", 8)
			margin.add_theme_constant_override("margin_bottom", 8)
			card.add_child(margin)

			var vbox: VBoxContainer = VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)
			margin.add_child(vbox)

			var stage_title: Label = Label.new()
			stage_title.text = "✓ " + str(hdata.get("title", "Hint %d" % (s + 1)))
			stage_title.add_theme_font_size_override("font_size", 13)
			stage_title.add_theme_color_override("font_color", Color("#54E6EA")) # Cyan
			vbox.add_child(stage_title)

			var stage_text: Label = Label.new()
			stage_text.text = str(hdata.get("text", ""))
			stage_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			stage_text.add_theme_font_size_override("font_size", 13)
			stage_text.add_theme_color_override("font_color", Color("#E2E8F0"))
			vbox.add_child(stage_text)

			hint_content_vbox.add_child(card)
	else:
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "No hints revealed for this level yet."
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color("#64748B"))
		hint_content_vbox.add_child(empty_lbl)

	# Separator
	var sep: HSeparator = HSeparator.new()
	hint_content_vbox.add_child(sep)

	# 2. NEXT AVAILABLE STAGE / ALL REVEALED
	if highest_revealed < 2:
		var next_stage: int = highest_revealed + 1
		var stage_names: Array[String] = ["Observation", "Strategy", "Solution"]
		var next_header: Label = Label.new()
		next_header.text = "NEXT AVAILABLE: Hint %d — %s" % [next_stage + 1, stage_names[next_stage]]
		next_header.add_theme_font_size_override("font_size", 14)
		next_header.add_theme_color_override("font_color", Color("#FBBF24")) # Amber
		hint_content_vbox.add_child(next_header)

		if rem > 0:
			btn_reveal_next.visible = true
			btn_reveal_next.disabled = false
			btn_reveal_next.text = "🔓 REVEAL HINT %d (%s) — [1 CREDIT]" % [next_stage + 1, stage_names[next_stage].to_upper()]
		else:
			btn_reveal_next.visible = true
			btn_reveal_next.disabled = true
			btn_reveal_next.text = "🔒 NO HINTS REMAINING TODAY"
			var exhaust_lbl: Label = Label.new()
			exhaust_lbl.text = "You've used all 3 hints for today.\nNew hints will be available tomorrow after midnight."
			exhaust_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			exhaust_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			exhaust_lbl.add_theme_font_size_override("font_size", 12)
			exhaust_lbl.add_theme_color_override("font_color", Color("#F87171"))
			hint_content_vbox.add_child(exhaust_lbl)
	else:
		btn_reveal_next.visible = false
		var all_done_lbl: Label = Label.new()
		all_done_lbl.text = "★ ALL HINTS REVEALED FOR THIS LEVEL"
		all_done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		all_done_lbl.add_theme_font_size_override("font_size", 14)
		all_done_lbl.add_theme_color_override("font_color", Color("#34D399"))
		hint_content_vbox.add_child(all_done_lbl)

	hint_confirm_modal.visible = false
	hint_modal.visible = true

func _close_hint_modal() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	hint_confirm_modal.visible = false
	hint_modal.visible = false
	_update_hint_button()

func _on_reveal_next_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	hint_confirm_modal.visible = true

func _on_cancel_reveal() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	hint_confirm_modal.visible = false

func _on_confirm_reveal() -> void:
	hint_confirm_modal.visible = false
	if not SaveManager:
		return
	var ok: bool = SaveManager.reveal_next_hint(current_level_def.level_id)
	if ok:
		if AudioManager:
			AudioManager.play_sfx("echo_create")
		_open_hint_modal()
		_update_hint_button()

