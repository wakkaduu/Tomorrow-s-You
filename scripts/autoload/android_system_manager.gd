extends Node

## Android System Integration Manager for Tomorrow's You.
## Handles hardware back-button navigation, app lifecycle (pause/resume),
## display safe area insets (notches/cutouts), and device haptic feedback.

signal back_button_pressed()
signal app_paused()
signal app_resumed()
signal safe_area_changed(margins: Dictionary)

# Haptic durations in milliseconds
const HAPTIC_DURATIONS: Dictionary = {
	"button": 12,
	"move": 15,
	"wait": 15,
	"reset": 25,
	"echo_create": 35,
	"plate": 40,
	"door": 50,
	"error": 60,
	"complete": 80
}

var last_safe_margins: Dictionary = {"top": 0, "bottom": 0, "left": 0, "right": 0}
var _audio_was_muted_by_pause: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Update safe area on start and listen for resize
	_update_safe_area()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			handle_back_request()
		NOTIFICATION_APPLICATION_PAUSED:
			_on_application_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_application_resumed()
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			# Desktop equivalent / fallback for focus loss
			if OS.get_name() != "Android":
				_on_application_paused()
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			if OS.get_name() != "Android":
				_on_application_resumed()

func _unhandled_input(event: InputEvent) -> void:
	# Fallback key input for Android hardware back button (KEY_BACK) or desktop Escape
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACK:
			get_viewport().set_input_as_handled()
			handle_back_request()
		elif event.keycode == KEY_ESCAPE and OS.get_name() != "Android":
			# On desktop, Escape also behaves as back button
			get_viewport().set_input_as_handled()
			handle_back_request()

func handle_back_request() -> void:
	back_button_pressed.emit()

	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	# 1. If scene provides its own custom back-button handler, delegate to it
	if current_scene.has_method("handle_back_button"):
		var handled: bool = current_scene.handle_back_button()
		if handled:
			trigger_haptic("button")
			return

	# 2. Scene-specific fallback routing
	var scene_name: String = current_scene.name
	var scene_file: String = current_scene.scene_file_path

	if scene_file.ends_with("gameplay.tscn") or scene_name == "Gameplay":
		_handle_gameplay_back(current_scene)
	elif scene_file.ends_with("level_select.tscn") or scene_name == "LevelSelect":
		trigger_haptic("button")
		SceneRouter.go_to_difficulty_select()
	elif scene_file.ends_with("difficulty_select.tscn") or scene_name == "DifficultySelect":
		trigger_haptic("button")
		SceneRouter.go_to_main_menu()
	elif scene_file.ends_with("settings.tscn") or scene_name == "Settings":
		trigger_haptic("button")
		SceneRouter.go_to_main_menu()
	elif scene_file.ends_with("main_menu.tscn") or scene_name == "MainMenu":
		_handle_main_menu_back(current_scene)

func _handle_gameplay_back(gameplay: Node) -> void:
	# Check for modals in Gameplay scene
	var modals = gameplay.get_node_or_null("Modals")
	if modals:
		var hint_confirm = modals.get_node_or_null("HintConfirmModal")
		if hint_confirm and hint_confirm.visible:
			hint_confirm.visible = false
			trigger_haptic("button")
			return

		var hint_modal = modals.get_node_or_null("HintModal")
		if hint_modal and hint_modal.visible:
			hint_modal.visible = false
			trigger_haptic("button")
			return

		var complete_modal = modals.get_node_or_null("CompleteModal")
		if complete_modal and complete_modal.visible:
			complete_modal.visible = false
			trigger_haptic("button")
			SceneRouter.go_to_level_select()
			return

		var pause_modal = modals.get_node_or_null("PauseModal")
		if pause_modal:
			if pause_modal.visible:
				# Already paused -> Resume
				pause_modal.visible = false
				trigger_haptic("button")
			else:
				# Playing -> Pause
				pause_modal.visible = true
				trigger_haptic("button")
			return

func _handle_main_menu_back(menu: Node) -> void:
	# Check if CreditsPopup or any modal is visible
	var credits = menu.get_node_or_null("CreditsPopup")
	if credits and credits.visible:
		credits.visible = false
		trigger_haptic("button")
		return

	# On Android main menu, pressing back cleanly quits the app
	trigger_haptic("button")
	get_tree().quit()

# ------------------------------------------------------------------------------
# App Lifecycle (Pause / Resume)
# ------------------------------------------------------------------------------
func _on_application_paused() -> void:
	app_paused.emit()

	# If playing a level, auto-pause so player doesn't lose context
	var current_scene = get_tree().current_scene
	if current_scene and (current_scene.name == "Gameplay" or current_scene.scene_file_path.ends_with("gameplay.tscn")):
		var modals = current_scene.get_node_or_null("Modals")
		if modals:
			var pause_modal = modals.get_node_or_null("PauseModal")
			var complete_modal = modals.get_node_or_null("CompleteModal")
			if pause_modal and not (complete_modal and complete_modal.visible):
				pause_modal.visible = true

	# Pause / Mute master audio bus to avoid battery drain while backgrounded
	if not AudioServer.is_bus_mute(0):
		AudioServer.set_bus_mute(0, true)
		_audio_was_muted_by_pause = true

func _on_application_resumed() -> void:
	app_resumed.emit()

	# Unmute audio if we muted it on pause
	if _audio_was_muted_by_pause:
		AudioServer.set_bus_mute(0, false)
		_audio_was_muted_by_pause = false

	# Re-validate daily hint reset timer
	if SaveManager and SaveManager.has_method("check_daily_hint_reset"):
		SaveManager.check_daily_hint_reset()

	# Refresh safe area in case orientation or window insets changed
	_update_safe_area()

# ------------------------------------------------------------------------------
# Safe Area Inset Calculation
# ------------------------------------------------------------------------------
func _on_viewport_size_changed() -> void:
	_update_safe_area()

func _update_safe_area() -> void:
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()

	if window_size.x <= 0 or window_size.y <= 0:
		last_safe_margins = {"top": 0, "bottom": 0, "left": 0, "right": 0}
		return

	# Calculate pixel insets from screen boundaries
	var top_px: int = safe_rect.position.y
	var left_px: int = safe_rect.position.x
	var right_px: int = window_size.x - (safe_rect.position.x + safe_rect.size.x)
	var bottom_px: int = window_size.y - (safe_rect.position.y + safe_rect.size.y)

	# Convert to project canvas coordinates
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_y: float = vp_size.y / float(window_size.y) if window_size.y > 0 else 1.0
	var scale_x: float = vp_size.x / float(window_size.x) if window_size.x > 0 else 1.0

	last_safe_margins = {
		"top": int(top_px * scale_y),
		"bottom": int(bottom_px * scale_y),
		"left": int(left_px * scale_x),
		"right": int(right_px * scale_x)
	}

	safe_area_changed.emit(last_safe_margins)

func get_safe_margins() -> Dictionary:
	return last_safe_margins

func apply_safe_area_to_margin(container: MarginContainer, extra_top: int = 0, extra_bottom: int = 0, extra_left: int = 0, extra_right: int = 0) -> void:
	if container == null:
		return
	var m = get_safe_margins()
	container.add_theme_constant_override("margin_top", m["top"] + extra_top)
	container.add_theme_constant_override("margin_bottom", m["bottom"] + extra_bottom)
	container.add_theme_constant_override("margin_left", m["left"] + extra_left)
	container.add_theme_constant_override("margin_right", m["right"] + extra_right)

# ------------------------------------------------------------------------------
# Haptic Feedback Dispatch
# ------------------------------------------------------------------------------
func trigger_haptic(type: String) -> void:
	if not is_haptic_supported():
		return

	if SaveManager and not bool(SaveManager.get("haptics_enabled")):
		return

	var duration_ms: int = HAPTIC_DURATIONS.get(type, 15)
	Input.vibrate_handheld(duration_ms)

func is_haptic_supported() -> bool:
	# Input.vibrate_handheld is supported on Android and iOS
	return OS.get_name() == "Android" or OS.get_name() == "iOS"
