class_name GameplayController
extends Control

## Main Gameplay Controller for Tomorrow's You.
## Coordinates puzzle simulation, board rendering, mobile touch controls, desktop input, HUD, and dialogs.

const HintRegistryClass = preload("res://scripts/hints/hint_registry.gd")
const NarrativeRegistryClass = preload("res://scripts/narrative/narrative_registry.gd")
const UIDesignSystemClass = preload("res://scripts/ui/components/ui_design_system.gd")
const MorrowVisualizerClass = preload("res://scripts/ui/components/morrow_visualizer.gd")

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

var wait_meter: ProgressBar
var wait_feedback: Label

# Dialogs & Modals
@onready var pause_modal: PanelContainer = $Modals/PauseModal
@onready var complete_modal: PanelContainer = $Modals/CompleteModal
@onready var log_reward_label: Label = $Modals/CompleteModal/Margin/VBoxContainer/LogRewardLabel

# Restart Confirmation Modal
@onready var restart_confirm_modal: PanelContainer = $Modals/RestartConfirmModal
@onready var btn_confirm_restart: Button = $Modals/RestartConfirmModal/Margin/VBoxContainer/ButtonsRow/BtnConfirmRestart
@onready var btn_cancel_restart: Button = $Modals/RestartConfirmModal/Margin/VBoxContainer/ButtonsRow/BtnCancelRestart

# Communication Log Modal
@onready var comm_log_modal: PanelContainer = $Modals/CommunicationLogModal
@onready var btn_close_comm_log: Button = $Modals/CommunicationLogModal/Margin/VBoxContainer/HeaderBox/BtnCloseCommLog
@onready var comm_log_list: VBoxContainer = $Modals/CommunicationLogModal/Margin/VBoxContainer/ScrollContainer/TransmissionsList

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

# Transmission Modal
@onready var transmission_modal: PanelContainer = $Modals/TransmissionModal
@onready var transmission_sender: Label = $Modals/TransmissionModal/Margin/VBoxContainer/HeaderBox/SenderLabel
@onready var transmission_channel: Label = $Modals/TransmissionModal/Margin/VBoxContainer/HeaderBox/ChannelLabel
@onready var transmission_content: Label = $Modals/TransmissionModal/Margin/VBoxContainer/ScrollContainer/TransmissionContent
@onready var btn_skip_transmission: Button = $Modals/TransmissionModal/Margin/VBoxContainer/ButtonsRow/BtnSkipTransmission
@onready var btn_proceed_transmission: Button = $Modals/TransmissionModal/Margin/VBoxContainer/ButtonsRow/BtnProceedTransmission
@onready var morrow_core: Control = $Modals/TransmissionModal/Margin/VBoxContainer/VisualizerContainer/MorrowCore
@onready var transmission_signal_status: Label = $Modals/TransmissionModal/Margin/VBoxContainer/VisualizerContainer/SignalStatusLabel
@onready var transmission_meta: Label = $Modals/TransmissionModal/Margin/VBoxContainer/HeaderBox/MetaLabel
@onready var transmission_line_progress: Label = $Modals/TransmissionModal/Margin/VBoxContainer/ProgressRow/LineProgressLabel

# Ending Modal
@onready var ending_modal: PanelContainer = $Modals/EndingModal
@onready var ending_stats_label: Label = $Modals/EndingModal/Margin/VBoxContainer/EndingStatsLabel
@onready var btn_ending_archive: Button = $Modals/EndingModal/Margin/VBoxContainer/BtnEndingArchive
@onready var btn_ending_main_menu: Button = $Modals/EndingModal/Margin/VBoxContainer/BtnEndingMainMenu
@onready var btn_ending_replay: Button = $Modals/EndingModal/Margin/VBoxContainer/BtnEndingReplay

# Modal buttons
@onready var btn_resume: Button = $Modals/PauseModal/Margin/VBoxContainer/ResumeButton
@onready var btn_modal_restart: Button = $Modals/PauseModal/Margin/VBoxContainer/RestartButton
@onready var btn_modal_transmission: Button = $Modals/PauseModal/Margin/VBoxContainer/TransmissionButton
@onready var btn_modal_archive: Button = $Modals/PauseModal/Margin/VBoxContainer/ArchiveButton
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
var _active_transmission: Dictionary = {}
var _current_transmission_line: int = 0
var _transmission_callback: Callable = Callable()

# Typewriter text animation state
var _typewriter_active: bool = false
var _typewriter_chars_per_sec: float = 40.0
var _typewriter_elapsed: float = 0.0
var _typewriter_target_len: int = 0

# Swipe gesture tracking
var _touch_start_pos: Vector2 = Vector2.ZERO
var _is_swiping: bool = false
const SWIPE_THRESHOLD: float = 35.0

func _ready() -> void:
	pause_modal.visible = false
	complete_modal.visible = false
	hint_modal.visible = false
	hint_confirm_modal.visible = false
	if restart_confirm_modal:
		restart_confirm_modal.visible = false
	if comm_log_modal:
		comm_log_modal.visible = false
	if transmission_modal:
		transmission_modal.visible = false
	if ending_modal:
		ending_modal.visible = false

	if transmission_content:
		transmission_content.mouse_filter = Control.MOUSE_FILTER_STOP
		transmission_content.gui_input.connect(func(event: InputEvent):
			if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				if _typewriter_active:
					transmission_content.visible_characters = -1
					_typewriter_active = false
					if AudioManager: AudioManager.play_sfx("ui_click")
		)

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
	_apply_safe_area()

	if AndroidSystemManager:
		AndroidSystemManager.safe_area_changed.connect(func(_m): _apply_safe_area())

	if background and background.has_method("set_screen_mode"):
		var tier: int = current_level_def.difficulty_tier if current_level_def else 1
		background.set_screen_mode(ThemeManagerClass.ScreenMode.GAMEPLAY, tier)

	board_renderer.setup(simulation, get_viewport_rect().size)
	_update_hud()

	# Check and unlock opening transmission
	if current_level_def:
		var lid: String = current_level_def.level_id
		print("[NARRATIVE] Initializing level %s (Chapter %s)" % [lid, NarrativeRegistryClass.get_chapter_info(lid).get("code", "CH")])
		if SaveManager:
			SaveManager.unlock_narrative_on_level_started(lid)
		var intro_tr: Dictionary = NarrativeRegistryClass.get_opening_transmission(lid)
		if not intro_tr.is_empty():
			var tid: String = intro_tr.get("id", "")
			var viewed: bool = SaveManager.is_transmission_viewed(tid) if SaveManager else false
			print("[NARRATIVE] Found opening transmission '%s' (sender: %s, lines: %d, viewed: %s)" % [
				tid, intro_tr.get("sender", ""), intro_tr.get("lines", []).size(), viewed
			])
			if not viewed:
				print("[NARRATIVE] DISPLAYING opening transmission modal for '%s'" % tid)
				show_transmission(intro_tr)
			else:
				print("[NARRATIVE] SKIPPING opening transmission '%s' (already viewed in save data)" % tid)
		else:
			print("[NARRATIVE] No opening transmission registered for level: %s" % lid)

	get_viewport().size_changed.connect(_on_viewport_resized)

func _process(delta: float) -> void:
	if _typewriter_active and transmission_modal and transmission_modal.visible:
		if SaveManager and SaveManager.reduced_animations:
			transmission_content.visible_characters = -1
			_typewriter_active = false
		else:
			_typewriter_elapsed += delta
			var chars: int = int(_typewriter_elapsed * _typewriter_chars_per_sec)
			if chars >= _typewriter_target_len:
				transmission_content.visible_characters = -1
				_typewriter_active = false
			else:
				transmission_content.visible_characters = chars

func _apply_safe_area() -> void:
	if not AndroidSystemManager:
		return
	var margins = AndroidSystemManager.get_safe_margins()
	var top_margin: int = maxi(int(margins.get("top", 0)), 16)
	var bottom_margin: int = maxi(int(margins.get("bottom", 0)), 16)
	var left_margin: int = maxi(int(margins.get("left", 0)), 16)
	var right_margin: int = maxi(int(margins.get("right", 0)), 16)

	var top_mc = $TopHUD/MarginContainer
	if top_mc:
		top_mc.add_theme_constant_override("margin_top", top_margin)
		top_mc.add_theme_constant_override("margin_left", left_margin)
		top_mc.add_theme_constant_override("margin_right", right_margin)

	var bottom_hud = $BottomHUD
	if bottom_hud:
		bottom_hud.offset_bottom = -float(bottom_margin)
		bottom_hud.offset_left = float(left_margin)
		bottom_hud.offset_right = -float(right_margin)

func _on_viewport_resized() -> void:
	_apply_safe_area()
	if board_renderer:
		board_renderer.calculate_layout(get_viewport_rect().size)
		board_renderer.queue_redraw()

func _bind_simulation_signals() -> void:
	simulation.wait_limit_reached.connect(_show_wait_limit)
	simulation.turn_completed.connect(func(_turn): _update_hud())
	simulation.attempt_restarted.connect(func():
		_level_completed_handled = false
		if background and background.has_method("set_level_complete"):
			background.set_level_complete(false)
		if AndroidSystemManager:
			AndroidSystemManager.trigger_haptic("reset")
		_update_hud()
	)
	simulation.echo_created.connect(func(_idx, _total):
		if AudioManager: AudioManager.play_sfx("echo_create")
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("echo_create")
		_update_hud()
	)
	simulation.echoes_cleared.connect(func():
		_level_completed_handled = false
		if background and background.has_method("set_level_complete"):
			background.set_level_complete(false)
		if AudioManager: AudioManager.play_sfx("ui_click")
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("reset")
		_update_hud()
	)
	simulation.player_moved.connect(func(_from, _to, action):
		if AudioManager:
			if action == "WAIT": AudioManager.play_sfx("wait")
			else: AudioManager.play_sfx("move")
		if AndroidSystemManager:
			if action == "WAIT": AndroidSystemManager.trigger_haptic("wait")
			else: AndroidSystemManager.trigger_haptic("move")
		_update_hud()
	)
	simulation.move_blocked.connect(func(_target, _reason):
		if AudioManager: AudioManager.play_sfx("blocked")
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("error")
	)
	simulation.plate_state_changed.connect(func(_id, is_active):
		if AudioManager:
			if is_active: AudioManager.play_sfx("plate_on")
			else: AudioManager.play_sfx("plate_off")
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("plate")
	)
	simulation.door_state_changed.connect(func(_id, is_open):
		if AudioManager:
			if is_open: AudioManager.play_sfx("door_open")
			else: AudioManager.play_sfx("door_close")
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("door")
	)
	simulation.level_completed.connect(_on_level_completed)

func _is_modal_active() -> bool:
	return _level_completed_handled \
		or (pause_modal != null and pause_modal.visible) \
		or (complete_modal != null and complete_modal.visible) \
		or (hint_modal != null and hint_modal.visible) \
		or (hint_confirm_modal != null and hint_confirm_modal.visible) \
		or (transmission_modal != null and transmission_modal.visible) \
		or (ending_modal != null and ending_modal.visible) \
		or (restart_confirm_modal != null and restart_confirm_modal.visible) \
		or (comm_log_modal != null and comm_log_modal.visible)

func _bind_ui_buttons() -> void:
	# D-Pad
	btn_up.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			_execute_move(Vector2i.UP)
	)
	btn_down.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			_execute_move(Vector2i.DOWN)
	)
	btn_left.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			_execute_move(Vector2i.LEFT)
	)
	btn_right.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			_execute_move(Vector2i.RIGHT)
	)

	# Actions
	btn_wait.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			simulation.step_wait()
	)
	btn_create_echo.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			simulation.create_echo()
	)
	btn_restart.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			simulation.restart_attempt()
	)
	btn_clear_echoes.pressed.connect(func():
		if not _is_modal_active():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			simulation.clear_echoes()
	)

	# Pause
	pause_button.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		_toggle_pause()
	)
	btn_resume.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		_toggle_pause()
	)
	btn_modal_restart.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		if simulation and (simulation.current_turn > 0 or simulation.echoes.size() > 0):
			restart_confirm_modal.visible = true
		else:
			_toggle_pause()
			simulation.restart_attempt()
	)
	if btn_confirm_restart:
		btn_confirm_restart.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("reset")
			restart_confirm_modal.visible = false
			pause_modal.visible = false
			if background and background.has_method("set_paused"):
				background.set_paused(false)
			simulation.restart_attempt()
		)
	if btn_cancel_restart:
		btn_cancel_restart.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			restart_confirm_modal.visible = false
		)
	if btn_modal_transmission:
		btn_modal_transmission.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			pause_modal.visible = false
			_open_comm_log_modal()
		)
	if btn_close_comm_log:
		btn_close_comm_log.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			comm_log_modal.visible = false
			pause_modal.visible = true
		)
	if btn_modal_archive:
		btn_modal_archive.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			SceneRouter.go_to_archive()
		)
	btn_modal_levels.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		SceneRouter.go_to_level_select()
	)
	btn_modal_settings.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		SceneRouter.go_to_settings()
	)

	# Completion modal
	btn_next_level.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		complete_modal.visible = false
		if GameManager:
			GameManager.go_to_next_level()
	)
	btn_replay.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		complete_modal.visible = false
		_level_completed_handled = false
		if background and background.has_method("set_level_complete"):
			background.set_level_complete(false)
		simulation.clear_echoes()
	)
	btn_complete_levels.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		complete_modal.visible = false
		SceneRouter.go_to_level_select()
	)

	# Hint system buttons
	btn_hint.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		_open_hint_modal()
	)
	btn_close_hint.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		_close_hint_modal()
	)
	btn_reveal_next.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		_on_reveal_next_pressed()
	)
	btn_confirm_reveal.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		_on_confirm_reveal()
	)
	btn_cancel_reveal.pressed.connect(func():
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		_on_cancel_reveal()
	)

	# Narrative transmission buttons
	if btn_skip_transmission:
		btn_skip_transmission.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			_close_transmission()
		)
	if btn_proceed_transmission:
		btn_proceed_transmission.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			_advance_transmission()
		)

	# Ending modal buttons
	if btn_ending_archive:
		btn_ending_archive.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			ending_modal.visible = false
			SceneRouter.go_to_archive()
		)
	if btn_ending_main_menu:
		btn_ending_main_menu.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			ending_modal.visible = false
			SceneRouter.go_to_main_menu()
		)
	if btn_ending_replay:
		btn_ending_replay.pressed.connect(func():
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			ending_modal.visible = false
			_level_completed_handled = false
			if background and background.has_method("set_level_complete"):
				background.set_level_complete(false)
			simulation.clear_echoes()
		)

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
	var chapter: Dictionary = NarrativeRegistryClass.get_chapter_info(current_level_def.level_id)
	sector_label.text = "%s // %s" % [chapter.get("code", "CH-01"), chapter.get("title", "THE AWAKENING")]

	turn_count_label.text = "Turn: %02d" % simulation.current_turn
	echo_count_label.text = "Echoes: %d / %d" % [simulation.echoes.size(), current_level_def.echo_limit]

	if current_level_def.target_3_stars > 0:
		var total_act: int = simulation.total_actions_taken
		budget_label.text = "3★ Target: ≤%d (%d)" % [current_level_def.target_3_stars, total_act]
		if total_act <= current_level_def.target_3_stars:
			budget_label.add_theme_color_override("font_color", Color("#FBBF24")) # Gold 3-star on track
		elif total_act <= current_level_def.target_2_stars:
			budget_label.add_theme_color_override("font_color", Color("#38BDF8")) # Blue 2-star
		else:
			budget_label.add_theme_color_override("font_color", Color("#94A3B8")) # Gray 1-star
	else:
		budget_label.text = "Actions: %d" % simulation.total_actions_taken

	_update_echo_timeline()
	_update_hint_button()

	# Action button states
	var at_echo_limit: bool = simulation.echoes.size() >= current_level_def.echo_limit
	var has_steps: bool = (simulation.current_recording != null and simulation.current_recording.get_step_count() > 0)

	_update_wait_control()
	btn_create_echo.disabled = at_echo_limit or not has_steps
	btn_clear_echoes.disabled = simulation.echoes.is_empty()

	if at_echo_limit:
		btn_create_echo.text = "Max Echoes Active (%d/%d)" % [simulation.echoes.size(), current_level_def.echo_limit]
	elif not has_steps:
		btn_create_echo.text = "Create Echo (Move to Record)"
	else:
		btn_create_echo.text = "Create Echo (%d/%d Ready)" % [simulation.echoes.size(), current_level_def.echo_limit]

	# Visual prominence feedback for CREATE ECHO button
	if not btn_create_echo.disabled:
		btn_create_echo.modulate = Color(1.0, 1.0, 1.0)
	else:
		btn_create_echo.modulate = Color(0.7, 0.7, 0.75, 0.65)

func _update_wait_control() -> void:
	if wait_meter == null:
		var indicator = VBoxContainer.new()
		indicator.name = "WaitAllowance"
		indicator.add_theme_constant_override("separation", 2)
		btn_wait.get_parent().add_child(indicator)
		btn_wait.get_parent().move_child(indicator, btn_wait.get_index() + 1)
		wait_meter = ProgressBar.new()
		wait_meter.custom_minimum_size = Vector2(0, 6)
		wait_meter.show_percentage = false
		wait_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		indicator.add_child(wait_meter)
		wait_feedback = Label.new()
		wait_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIDesignSystemClass.apply_body_text(wait_feedback, 14, UIDesignSystemClass.COLOR_AMBER_WARN)
		indicator.add_child(wait_feedback)
		btn_wait.gui_input.connect(func(event: InputEvent):
			if btn_wait.disabled and not _is_modal_active():
				if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
					_show_wait_limit()
		)
	var remaining: int = simulation.get_remaining_wait_actions()
	btn_wait.text = "WAIT · %d LEFT" % remaining
	btn_wait.disabled = remaining == 0 or simulation.is_completed
	btn_wait.tooltip_text = "Shared by all Echoes and this attempt. Restart refunds this attempt; Clear Echoes resets all."
	wait_meter.max_value = maxi(1, current_level_def.max_wait_actions)
	wait_meter.value = remaining
	wait_feedback.text = "TEMPORAL WAIT LIMIT REACHED" if remaining == 0 else ""
	wait_feedback.visible = remaining == 0

func _show_wait_limit() -> void:
	_update_wait_control()
	if AudioManager: AudioManager.play_sfx("blocked")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("error")

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

	# Update log reward badge if a log exists for this level
	var chapter: Dictionary = NarrativeRegistryClass.get_chapter_info(current_level_def.level_id)
	var log_id: String = chapter.get("log_id", "")
	if not log_id.is_empty():
		var log_data: Dictionary = NarrativeRegistryClass.get_log(log_id)
		print("[NARRATIVE] Level %s complete -> Unlocking recovered log: %s (%s)" % [current_level_def.level_id, log_id, log_data.get("title", "")])
		log_reward_label.text = "✦ ARCHIVE RECORD RESTORED: [%s %s]" % [log_id.to_upper(), log_data.get("title", "")]
		log_reward_label.visible = true
	else:
		print("[NARRATIVE] Level %s complete -> No recovered log for this level" % current_level_def.level_id)
		log_reward_label.visible = false

	if GameManager and not GameManager.next_level_exists():
		btn_next_level.text = "CAMPAIGN COMPLETE!"
		btn_next_level.disabled = true
	else:
		btn_next_level.text = "NEXT LEVEL >"
		btn_next_level.disabled = false

	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("complete")

	var outro_tr: Dictionary = NarrativeRegistryClass.get_completion_transmission(current_level_def.level_id)

	if current_level_def.level_id == "lvl_10":
		# Level 10 ending sequence
		print("[NARRATIVE] Level 10 completed! Initiating final sequence and ending transition.")
		var on_outro_finished = func():
			if background and background.has_method("set_ending_stabilized"):
				background.set_ending_stabilized()
			var tot_actions: int = 0
			var tot_echoes: int = 0
			if SaveManager:
				for lid in SaveManager.completed_levels:
					tot_actions += SaveManager.best_actions.get(lid, 0)
					tot_echoes += SaveManager.best_echoes.get(lid, 0)
				var stars_info = SaveManager.get_total_stars()
				ending_stats_label.text = "Total Actions: %d | Echoes Deployed: %d | Stars: %d / %d" % [
					tot_actions, tot_echoes, stars_info.get("earned", 0), stars_info.get("total", 30)
				]
			ending_modal.visible = true

		if not outro_tr.is_empty():
			show_transmission(outro_tr, on_outro_finished)
		else:
			on_outro_finished.call()
	else:
		if background and background.has_method("set_level_complete"):
			background.set_level_complete(true)
		if not outro_tr.is_empty() and SaveManager and not SaveManager.is_transmission_viewed(outro_tr.get("id", "")):
			print("[NARRATIVE] Outro transmission '%s' available and unviewed. Displaying before level completion modal." % outro_tr.get("id", ""))
			show_transmission(outro_tr, func():
				complete_modal.visible = true
			)
		else:
			if not outro_tr.is_empty():
				print("[NARRATIVE] Outro transmission '%s' already viewed; proceeding directly to complete modal." % outro_tr.get("id", ""))
			complete_modal.visible = true

	print("[SCENE] Level Complete sequence executed")

func show_transmission(trans: Dictionary, on_completed: Callable = Callable()) -> void:
	if trans.is_empty():
		if on_completed.is_valid():
			on_completed.call()
		return

	_active_transmission = trans
	_transmission_callback = on_completed
	var lines: Array = trans.get("lines", [])
	_current_transmission_line = 0

	var tid = trans.get("id", "unknown")
	print("[NARRATIVE] Displaying transmission modal '%s' (Lines: %d)" % [tid, lines.size()])

	var cat_name: String = NarrativeRegistryClass.get_transmission_category(tid)
	var cat_enum = MorrowVisualizerClass.Category.NORMAL
	var border_color: Color = UIDesignSystemClass.COLOR_CYAN_PRIMARY
	var status_text: String = "● CARRIER LOCK // RESONANCE STABLE"

	match cat_name:
		"EMERGENCY":
			cat_enum = MorrowVisualizerClass.Category.EMERGENCY
			border_color = UIDesignSystemClass.COLOR_AMBER_WARN
			status_text = "● WARNING // FREQUENCY JITTER DETECTED"
		"CORRUPTED":
			cat_enum = MorrowVisualizerClass.Category.CORRUPTED
			border_color = UIDesignSystemClass.COLOR_VIOLET_ECHO
			status_text = "● DATA CORRUPTION // MEMORY PACKET LOSS"
		"FINAL":
			cat_enum = MorrowVisualizerClass.Category.FINAL
			border_color = Color(1.0, 0.84, 0.36)
			status_text = "● FINAL HARMONICS // TEMPORAL STABILIZATION"
		_:
			cat_enum = MorrowVisualizerClass.Category.NORMAL
			border_color = UIDesignSystemClass.COLOR_CYAN_PRIMARY
			status_text = "● CARRIER LOCK // RESONANCE STABLE"

	if morrow_core:
		morrow_core.set_category(cat_enum)

	if transmission_signal_status:
		transmission_signal_status.text = status_text
		transmission_signal_status.add_theme_color_override("font_color", border_color)

	if transmission_modal:
		var panel_sb = UIDesignSystemClass.create_panel_style(border_color, Color(0.02, 0.035, 0.07, 0.98), 2, 14, 20)
		transmission_modal.add_theme_stylebox_override("panel", panel_sb)

	transmission_sender.text = trans.get("sender", "MORROW // FACILITY AI")
	transmission_channel.text = trans.get("channel", "EMERGENCY CONTAINMENT LINK")

	UIDesignSystemClass.apply_display_heading(transmission_sender, 18, border_color, "Bold")
	UIDesignSystemClass.apply_technical_text(transmission_channel, 12, border_color, "SemiBold")
	if transmission_signal_status:
		UIDesignSystemClass.apply_technical_text(transmission_signal_status, 11, border_color)
	if transmission_line_progress:
		UIDesignSystemClass.apply_technical_text(transmission_line_progress, 12, UIDesignSystemClass.COLOR_TEXT_MUTED, "SemiBold")
	if transmission_content:
		transmission_content.add_theme_font_override("font", UIDesignSystemClass.get_interface_font("Medium"))
		transmission_content.add_theme_font_size_override("font_size", 18)
		transmission_content.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_PRIMARY)

	if btn_proceed_transmission:
		UIDesignSystemClass.apply_button_style(btn_proceed_transmission, UIDesignSystemClass.ButtonType.PRIMARY, border_color)
	if btn_skip_transmission:
		UIDesignSystemClass.apply_button_style(btn_skip_transmission, UIDesignSystemClass.ButtonType.TERTIARY)

	var lvl_id: String = trans.get("level_id", "")
	var ch_info = NarrativeRegistryClass.get_chapter_info(lvl_id)
	if transmission_meta:
		var ch_str = "%s // %s" % [ch_info.get("code", "CH-01"), ch_info.get("title", "SECTOR")]
		transmission_meta.text = "%s  •  %s" % [ch_str, tid.to_upper()]
		UIDesignSystemClass.apply_technical_text(transmission_meta, 12, UIDesignSystemClass.COLOR_TEXT_MUTED)

	_display_transmission_line(0)

	transmission_modal.visible = true
	if background and background.has_method("set_paused"):
		background.set_paused(true)

	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")

func _display_transmission_line(line_idx: int) -> void:
	var lines: Array = _active_transmission.get("lines", [])
	_current_transmission_line = line_idx
	var text: String = lines[line_idx] if line_idx < lines.size() else ""
	transmission_content.text = text
	_typewriter_target_len = text.length()
	_typewriter_elapsed = 0.0
	_typewriter_active = true
	transmission_content.visible_characters = 0

	if transmission_line_progress:
		transmission_line_progress.text = "LINE %02d / %02d" % [line_idx + 1, lines.size()]

	btn_proceed_transmission.text = "Next" if (line_idx < lines.size() - 1) else "Continue"

func _advance_transmission() -> void:
	var lines: Array = _active_transmission.get("lines", [])
	_current_transmission_line += 1
	if _current_transmission_line < lines.size():
		_display_transmission_line(_current_transmission_line)
		if AudioManager:
			AudioManager.play_sfx("ui_click")
		if AndroidSystemManager:
			AndroidSystemManager.trigger_haptic("button")
	else:
		_close_transmission()

func _close_transmission() -> void:
	if SaveManager and not _active_transmission.is_empty():
		var tid = _active_transmission.get("id", "")
		print("[NARRATIVE] Closing transmission '%s' and marking as viewed in SaveManager." % tid)
		SaveManager.mark_transmission_viewed(tid)
	transmission_modal.visible = false
	_typewriter_active = false
	if background and background.has_method("set_paused"):
		background.set_paused(pause_modal.visible or (comm_log_modal and comm_log_modal.visible))
	var cb = _transmission_callback
	_active_transmission = {}
	_transmission_callback = Callable()
	if cb.is_valid():
		cb.call()

func _open_comm_log_modal() -> void:
	for child in comm_log_list.get_children():
		child.queue_free()

	var all_transmissions = NarrativeRegistryClass.get_all_transmissions()
	for trans in all_transmissions:
		var tid: String = trans.get("id", "")
		var is_unlocked: bool = SaveManager and SaveManager.is_transmission_unlocked(tid)
		var is_viewed: bool = SaveManager and SaveManager.is_transmission_viewed(tid)
		var lvl_id: String = trans.get("level_id", "")
		var ch = NarrativeRegistryClass.get_chapter_info(lvl_id)
		var ch_str = "%s: %s" % [ch.get("code", "CH"), ch.get("title", "")]
		var type_str = trans.get("type", "OPENING")

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 72)
		card.add_theme_stylebox_override("panel", UIDesignSystemClass.create_card_style(
			UIDesignSystemClass.COLOR_CYAN_PRIMARY if is_unlocked else UIDesignSystemClass.COLOR_TEXT_DIM,
			is_unlocked,
			false
		))

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		margin.add_child(row)

		var info_box = VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.add_theme_constant_override("separation", 3)
		row.add_child(info_box)

		if is_unlocked:
			var title_lbl = Label.new()
			title_lbl.text = "✦ %s // %s" % [ch_str, type_str]
			UIDesignSystemClass.apply_display_heading(title_lbl, 14, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "SemiBold")
			info_box.add_child(title_lbl)

			var sub_lbl = Label.new()
			sub_lbl.text = "%s • %s" % [trans.get("sender", "MORROW"), trans.get("channel", "LINK")]
			UIDesignSystemClass.apply_technical_text(sub_lbl, 11, UIDesignSystemClass.COLOR_TEXT_MUTED)
			info_box.add_child(sub_lbl)

			var replay_btn = Button.new()
			replay_btn.custom_minimum_size = Vector2(100, 42)
			replay_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			replay_btn.text = "REPLAY ▶"
			UIDesignSystemClass.apply_button_style(replay_btn, UIDesignSystemClass.ButtonType.PRIMARY)
			var captured_trans = trans
			replay_btn.pressed.connect(func():
				comm_log_modal.visible = false
				show_transmission(captured_trans, func():
					comm_log_modal.visible = true
				)
			)
			row.add_child(replay_btn)
		else:
			var locked_lbl = Label.new()
			var req_ch = ch.get("code", "CH")
			locked_lbl.text = "🔒 RESTRICTED // COMPLETE %s TO RECOVER" % req_ch
			UIDesignSystemClass.apply_technical_text(locked_lbl, 12, UIDesignSystemClass.COLOR_TEXT_DIM)
			info_box.add_child(locked_lbl)

		comm_log_list.add_child(card)

	comm_log_modal.visible = true

func handle_back_button() -> bool:
	if transmission_modal and transmission_modal.visible:
		_close_transmission()
		return true
	if ending_modal and ending_modal.visible:
		ending_modal.visible = false
		SceneRouter.go_to_main_menu()
		return true
	if restart_confirm_modal and restart_confirm_modal.visible:
		restart_confirm_modal.visible = false
		return true
	if comm_log_modal and comm_log_modal.visible:
		comm_log_modal.visible = false
		pause_modal.visible = true
		return true
	if hint_confirm_modal and hint_confirm_modal.visible:
		_on_cancel_reveal()
		return true
	if hint_modal and hint_modal.visible:
		_close_hint_modal()
		return true
	if complete_modal and complete_modal.visible:
		complete_modal.visible = false
		SceneRouter.go_to_level_select()
		return true
	if pause_modal and pause_modal.visible:
		_toggle_pause()
		return true
	_toggle_pause()
	return true

func _style_holographic_modals() -> void:
	# Top HUD Typography
	if level_title_label:
		UIDesignSystemClass.apply_display_heading(level_title_label, UIDesignSystemClass.FONT_SIZE_LEVEL_TITLE, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")
	if sector_label:
		UIDesignSystemClass.apply_technical_text(sector_label, UIDesignSystemClass.FONT_SIZE_METADATA, UIDesignSystemClass.COLOR_TEXT_MUTED, "SemiBold")
	if turn_count_label:
		UIDesignSystemClass.apply_technical_text(turn_count_label, 16, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "SemiBold")
	if echo_count_label:
		UIDesignSystemClass.apply_technical_text(echo_count_label, 16, UIDesignSystemClass.COLOR_VIOLET_ECHO, "SemiBold")
	if budget_label:
		UIDesignSystemClass.apply_technical_text(budget_label, 15, UIDesignSystemClass.COLOR_AMBER_WARN, "SemiBold")

	# Top HUD Pills styling
	var turn_pill = $TopHUD/MarginContainer/VBoxContainer/StatsPillsRow/TurnPill
	if turn_pill:
		_setup_stat_pill_icon(turn_pill, turn_count_label, "icon_turn_count", UIDesignSystemClass.COLOR_CYAN_PRIMARY)
	var echo_pill = $TopHUD/MarginContainer/VBoxContainer/StatsPillsRow/EchoPill
	if echo_pill:
		_setup_stat_pill_icon(echo_pill, echo_count_label, "icon_echo_count", UIDesignSystemClass.COLOR_VIOLET_ECHO)
	var budget_pill = $TopHUD/MarginContainer/VBoxContainer/StatsPillsRow/BudgetPill
	if budget_pill:
		_setup_stat_pill_icon(budget_pill, budget_label, "icon_star", UIDesignSystemClass.COLOR_AMBER_WARN)

	# Pause Button (Top HUD right)
	if pause_button:
		UIDesignSystemClass.apply_icon_button(pause_button, "icon_pause", Vector2(48, 48), UIDesignSystemClass.COLOR_CYAN_PRIMARY)

	# Directional Pad buttons
	var dpad_pairs = [
		[btn_up, "icon_arrow_up"],
		[btn_down, "icon_arrow_down"],
		[btn_left, "icon_arrow_left"],
		[btn_right, "icon_arrow_right"]
	]
	for pair in dpad_pairs:
		var b: Button = pair[0]
		var icon_name: String = pair[1]
		if b:
			UIDesignSystemClass.apply_icon_button(b, icon_name, Vector2(74, 74), UIDesignSystemClass.COLOR_CYAN_PRIMARY)

	# Primary Gameplay Action (Create Echo)
	if btn_create_echo:
		UIDesignSystemClass.apply_primary_button(btn_create_echo, "Create Echo", "icon_echo")
		btn_create_echo.custom_minimum_size = Vector2(0, UIDesignSystemClass.PRIMARY_ACTION_HEIGHT)

	# Utility Actions
	if btn_wait:
		UIDesignSystemClass.apply_utility_button(btn_wait, "Wait", "icon_wait", UIDesignSystemClass.COLOR_CYAN_PRIMARY)

	if btn_hint:
		UIDesignSystemClass.apply_utility_button(btn_hint, "Hint · 3 Left", "icon_hint", UIDesignSystemClass.COLOR_AMBER_WARN)

	# Destructive Actions
	if btn_restart:
		UIDesignSystemClass.apply_destructive_button(btn_restart, "Restart Attempt", "icon_restart")

	if btn_clear_echoes:
		UIDesignSystemClass.apply_destructive_button(btn_clear_echoes, "Clear Echoes", "icon_clear")

	# Modal Panels
	if pause_modal:
		pause_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_CYAN_PRIMARY, Color(0.04, 0.065, 0.12, 0.98), 1, 14, 14))
	if restart_confirm_modal:
		restart_confirm_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_ROSE_ALERT, Color(0.06, 0.04, 0.08, 0.98), 1, 12, 14))
	if comm_log_modal:
		comm_log_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_CYAN_PRIMARY, Color(0.03, 0.05, 0.10, 0.98), 1, 14, 14))
	if complete_modal:
		complete_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_CYAN_PRIMARY, Color(0.04, 0.07, 0.14, 0.98), 1, 14, 14))
	if hint_modal:
		hint_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_AMBER_WARN, Color(0.05, 0.06, 0.10, 0.98), 1, 14, 14))
	if hint_confirm_modal:
		hint_confirm_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_AMBER_WARN, Color(0.05, 0.06, 0.10, 0.98), 1, 12, 14))
	if transmission_modal:
		transmission_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_CYAN_PRIMARY, Color(0.02, 0.035, 0.07, 0.98), 1, 14, 16))
	if ending_modal:
		ending_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_EMERALD_SUCCESS, Color(0.03, 0.06, 0.12, 0.98), 1, 14, 16))

	# Modal Buttons
	if btn_resume:
		UIDesignSystemClass.apply_primary_button(btn_resume, "Resume Puzzle", "icon_resume")
	if btn_modal_restart:
		UIDesignSystemClass.apply_destructive_button(btn_modal_restart, "Restart Attempt", "icon_restart")
	if btn_modal_transmission:
		UIDesignSystemClass.apply_secondary_button(btn_modal_transmission, "Communication Log", "icon_communication_log")
	if btn_modal_archive:
		UIDesignSystemClass.apply_secondary_button(btn_modal_archive, "Incident Archive", "icon_archive")
	if btn_modal_levels:
		UIDesignSystemClass.apply_secondary_button(btn_modal_levels, "Level Select", "icon_menu")
	if btn_modal_settings:
		UIDesignSystemClass.apply_secondary_button(btn_modal_settings, "Settings", "icon_settings")

	if btn_close_comm_log:
		UIDesignSystemClass.apply_secondary_button(btn_close_comm_log, "Back to Game", "icon_back")

	if btn_confirm_restart:
		UIDesignSystemClass.apply_destructive_button(btn_confirm_restart, "Confirm Restart", "icon_restart")
	if btn_cancel_restart:
		UIDesignSystemClass.apply_button_style(btn_cancel_restart, UIDesignSystemClass.ButtonType.TERTIARY)
		btn_cancel_restart.text = "Cancel"

	if btn_reveal_next:
		UIDesignSystemClass.apply_primary_button(btn_reveal_next, "Reveal Next Stage", "icon_hint")
	if btn_close_hint:
		UIDesignSystemClass.apply_button_style(btn_close_hint, UIDesignSystemClass.ButtonType.TERTIARY)
		btn_close_hint.text = "Return to Puzzle"
	if btn_confirm_reveal:
		UIDesignSystemClass.apply_primary_button(btn_confirm_reveal, "Confirm Unlock (-1 Hint)", "icon_hint")
	if btn_cancel_reveal:
		UIDesignSystemClass.apply_button_style(btn_cancel_reveal, UIDesignSystemClass.ButtonType.TERTIARY)
		btn_cancel_reveal.text = "Cancel"

	if btn_proceed_transmission:
		UIDesignSystemClass.apply_primary_button(btn_proceed_transmission, "Proceed", "icon_next")
	if btn_skip_transmission:
		UIDesignSystemClass.apply_button_style(btn_skip_transmission, UIDesignSystemClass.ButtonType.TERTIARY)
		btn_skip_transmission.text = "Skip"

	if btn_next_level:
		UIDesignSystemClass.apply_primary_button(btn_next_level, "Next Level", "icon_next")
	if btn_replay:
		UIDesignSystemClass.apply_secondary_button(btn_replay, "Replay Attempt", "icon_restart")
	if btn_complete_levels:
		UIDesignSystemClass.apply_secondary_button(btn_complete_levels, "Level Select", "icon_menu")

	if btn_ending_archive:
		UIDesignSystemClass.apply_primary_button(btn_ending_archive, "Incident Archive", "icon_archive")
	if btn_ending_main_menu:
		UIDesignSystemClass.apply_secondary_button(btn_ending_main_menu, "Main Menu", "icon_menu")
	if btn_ending_replay:
		UIDesignSystemClass.apply_secondary_button(btn_ending_replay, "Replay Climax", "icon_restart")

func _setup_stat_pill_icon(pill: PanelContainer, label: Label, icon_name: String, color: Color) -> void:
	if not pill or not label:
		return
	pill.add_theme_stylebox_override("panel", UIDesignSystemClass.create_badge_style(color))
	var margin = label.get_parent()
	if margin and not margin.has_node("HBox"):
		var hbox = HBoxContainer.new()
		hbox.name = "HBox"
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 6)

		var icon_rect = TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.texture = UIDesignSystemClass.get_icon(icon_name)
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.modulate = color

		margin.remove_child(label)
		margin.add_child(hbox)
		hbox.add_child(icon_rect)
		hbox.add_child(label)

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
			var vp_h: float = get_viewport_rect().size.y
			if event.position.y > 130.0 and event.position.y < (vp_h - 320.0):
				_touch_start_pos = event.position
				_is_swiping = true
			else:
				_is_swiping = false
		else:
			if _is_swiping:
				_handle_swipe(event.position - _touch_start_pos)
			_is_swiping = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var vp_h: float = get_viewport_rect().size.y
			if event.position.y > 130.0 and event.position.y < (vp_h - 320.0):
				_touch_start_pos = event.position
				_is_swiping = true
			else:
				_is_swiping = false
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
	simulation.debug_turn_logging = board_renderer.show_debug_connections
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
	text += "WAIT: %d / %d used | %d left\n" % [simulation.get_wait_actions_used(), current_level_def.max_wait_actions, simulation.get_remaining_wait_actions()]
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
	btn_hint.text = "Hint · %d Left" % rem
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

