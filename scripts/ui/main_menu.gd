extends Control

## Main menu for Tomorrow's You.
## Features atmospheric glowing sci-fi UI and responsive button feedback.

const ThemeManagerClass = preload("res://scripts/background/background_theme_manager.gd")
const UIDesignSystemClass = preload("res://scripts/ui/components/ui_design_system.gd")

@onready var play_button: Button = $VBoxContainer/Buttons/PlayButton
@onready var levels_button: Button = $VBoxContainer/Buttons/LevelsButton
@onready var archive_button: Button = $VBoxContainer/Buttons/ArchiveButton
@onready var settings_button: Button = $VBoxContainer/Buttons/SettingsButton
@onready var credits_button: Button = $VBoxContainer/Buttons/CreditsButton
@onready var credits_popup: PanelContainer = $CreditsPopup
@onready var title_label: Label = $VBoxContainer/Header/Title
@onready var background: Control = $TemporalBackground

var _pulse_timer: float = 0.0
var exit_confirmation: ConfirmationDialog

func _ready() -> void:
	credits_popup.visible = false
	exit_confirmation = ConfirmationDialog.new()
	exit_confirmation.title = "Exit Tomorrow's You?"
	exit_confirmation.dialog_text = "Leave the game? Your saved progress will be kept."
	exit_confirmation.ok_button_text = "Exit Game"
	exit_confirmation.cancel_button_text = "Stay"
	exit_confirmation.confirmed.connect(func(): get_tree().quit())
	add_child(exit_confirmation)

	# Apply design system panel style to credits popup
	credits_popup.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(
		UIDesignSystemClass.COLOR_CYAN_PRIMARY,
		Color(0.04, 0.065, 0.12, 0.98),
		1,
		14,
		14
	))

	# Apply typography to title and tagline
	UIDesignSystemClass.apply_display_heading(title_label, UIDesignSystemClass.FONT_SIZE_MAIN_TITLE, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")
	var tagline_lbl = $VBoxContainer/Header/Tagline
	if tagline_lbl:
		UIDesignSystemClass.apply_body_text(tagline_lbl, UIDesignSystemClass.FONT_SIZE_BODY, UIDesignSystemClass.COLOR_TEXT_SECONDARY, "Medium")

	# Update Play button text and icon with clear hierarchy
	var has_progress: bool = SaveManager and not SaveManager.completed_levels.is_empty()
	var play_title: String = "Continue Journey" if has_progress else "Start Journey"
	UIDesignSystemClass.apply_primary_button(play_button, play_title, "icon_play")
	play_button.custom_minimum_size = Vector2(0, 56)

	UIDesignSystemClass.apply_secondary_button(levels_button, "Select Level", "icon_menu")
	levels_button.custom_minimum_size = Vector2(0, 50)

	var archive_title: String = "Incident Archive"
	if SaveManager:
		var prog = SaveManager.get_archive_progress()
		var unl = prog.get("unlocked", 0)
		var tot = prog.get("total", 31)
		if unl > 0:
			archive_title = "Incident Archive (%d/%d)" % [unl, tot]
	UIDesignSystemClass.apply_secondary_button(archive_button, archive_title, "icon_archive")
	archive_button.custom_minimum_size = Vector2(0, 50)

	UIDesignSystemClass.apply_secondary_button(settings_button, "Settings", "icon_settings")
	settings_button.custom_minimum_size = Vector2(0, 50)

	# Credits has less visual weight (Tertiary)
	UIDesignSystemClass.apply_button_style(credits_button, UIDesignSystemClass.ButtonType.TERTIARY)
	credits_button.text = "Facility Credits"
	credits_button.custom_minimum_size = Vector2(0, 44)

	var close_cred_btn = $CreditsPopup/VBoxContainer/CloseCreditsButton
	if close_cred_btn:
		UIDesignSystemClass.apply_primary_button(close_cred_btn, "Close", "icon_close")

	var cred_title = $CreditsPopup/VBoxContainer/CreditsTitle
	if cred_title:
		UIDesignSystemClass.apply_display_heading(cred_title, 22, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")
	var cred_body = $CreditsPopup/VBoxContainer/CreditsBody
	if cred_body:
		UIDesignSystemClass.apply_body_text(cred_body, 14, UIDesignSystemClass.COLOR_TEXT_SECONDARY)

	play_button.pressed.connect(_on_play_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	archive_button.pressed.connect(_on_archive_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	if close_cred_btn:
		close_cred_btn.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
			credits_popup.visible = false
			$VBoxContainer.visible = true
			if background and background.has_method("set_screen_mode"):
				background.set_screen_mode(ThemeManagerClass.ScreenMode.MAIN_MENU)
		)

	if AudioManager:
		AudioManager.play_music()

	_apply_safe_area()
	if AndroidSystemManager:
		AndroidSystemManager.safe_area_changed.connect(func(_m): _apply_safe_area())

func _apply_safe_area() -> void:
	if not AndroidSystemManager:
		return
	var m = AndroidSystemManager.get_safe_margins()
	var vb = $VBoxContainer
	if vb:
		vb.offset_top = maxi(float(m.get("top", 0)), 40.0)
		vb.offset_bottom = -maxi(float(m.get("bottom", 0)), 40.0)

func handle_back_button() -> bool:
	if exit_confirmation.visible:
		exit_confirmation.hide()
		return true
	if credits_popup and credits_popup.visible:
		credits_popup.visible = false
		$VBoxContainer.visible = true
		if background and background.has_method("set_screen_mode"):
			background.set_screen_mode(ThemeManagerClass.ScreenMode.MAIN_MENU)
		return true
	exit_confirmation.popup_centered(Vector2i(420, 180))
	return true

func _process(delta: float) -> void:
	if SaveManager and SaveManager.reduced_animations:
		title_label.modulate = Color(1.0, 1.0, 1.0)
		return
	_pulse_timer += delta * 2.0
	var glow: float = sin(_pulse_timer) * 0.15 + 0.85
	title_label.modulate = Color(glow, 1.0, 1.0)

func _on_play_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")
	var target_index: int = 0
	if SaveManager:
		for i in range(LevelRegistry.get_level_count()):
			var lvl: LevelDefinition = LevelRegistry.get_level(i)
			if SaveManager.is_level_unlocked(lvl.level_id):
				target_index = i
	SceneRouter.go_to_gameplay(target_index)

func _on_levels_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")
	SceneRouter.go_to_difficulty_select()

func _on_archive_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")
	SceneRouter.go_to_archive()

func _on_settings_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")
	SceneRouter.go_to_settings()

func _on_credits_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")
	$VBoxContainer.visible = false
	credits_popup.visible = true
	if background and background.has_method("set_screen_mode"):
		background.set_screen_mode(ThemeManagerClass.ScreenMode.CREDITS)
