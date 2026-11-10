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

func _ready() -> void:
	credits_popup.visible = false

	# Apply design system panel style to credits popup
	credits_popup.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(
		UIDesignSystemClass.COLOR_CYAN_PRIMARY,
		Color(0.04, 0.065, 0.12, 0.98),
		2,
		14,
		20
	))

	# Apply typography to title and tagline
	UIDesignSystemClass.apply_display_heading(title_label, UIDesignSystemClass.FONT_SIZE_MAIN_TITLE, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")
	var tagline_lbl = $VBoxContainer/Header/Tagline
	if tagline_lbl:
		UIDesignSystemClass.apply_body_text(tagline_lbl, UIDesignSystemClass.FONT_SIZE_BODY, UIDesignSystemClass.COLOR_TEXT_SECONDARY, "Medium")

	# Apply button styling with clear hierarchy
	UIDesignSystemClass.apply_button_style(play_button, UIDesignSystemClass.ButtonType.PRIMARY)
	play_button.custom_minimum_size = Vector2(0, 60)

	UIDesignSystemClass.apply_button_style(levels_button, UIDesignSystemClass.ButtonType.SECONDARY)
	levels_button.custom_minimum_size = Vector2(0, 52)

	UIDesignSystemClass.apply_button_style(archive_button, UIDesignSystemClass.ButtonType.SECONDARY)
	archive_button.custom_minimum_size = Vector2(0, 52)

	UIDesignSystemClass.apply_button_style(settings_button, UIDesignSystemClass.ButtonType.SECONDARY)
	settings_button.custom_minimum_size = Vector2(0, 52)

	# Credits has less visual weight (Tertiary)
	UIDesignSystemClass.apply_button_style(credits_button, UIDesignSystemClass.ButtonType.TERTIARY)
	credits_button.custom_minimum_size = Vector2(0, 44)

	var close_cred_btn = $CreditsPopup/VBoxContainer/CloseCreditsButton
	if close_cred_btn:
		UIDesignSystemClass.apply_button_style(close_cred_btn, UIDesignSystemClass.ButtonType.PRIMARY)

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

	# Update Play button text: "CONTINUE JOURNEY" if progress exists, else "START PLAYING"
	if SaveManager and not SaveManager.completed_levels.is_empty():
		play_button.text = "CONTINUE JOURNEY ▶"
	else:
		play_button.text = "START PLAYING ▶"

	# Update Archive button badge with recovery stats
	if SaveManager:
		var prog = SaveManager.get_archive_progress()
		var unl = prog.get("unlocked", 0)
		var tot = prog.get("total", 31)
		if unl > 0:
			archive_button.text = "INCIDENT ARCHIVE [%d/%d]" % [unl, tot]
		else:
			archive_button.text = "INCIDENT ARCHIVE"

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
	if credits_popup and credits_popup.visible:
		credits_popup.visible = false
		$VBoxContainer.visible = true
		if background and background.has_method("set_screen_mode"):
			background.set_screen_mode(ThemeManagerClass.ScreenMode.MAIN_MENU)
		return true
	return false

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
