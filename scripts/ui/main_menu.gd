extends Control

## Main menu for Tomorrow's You.
## Features atmospheric glowing sci-fi UI and responsive button feedback.

@onready var play_button: Button = $VBoxContainer/Buttons/PlayButton
@onready var levels_button: Button = $VBoxContainer/Buttons/LevelsButton
@onready var settings_button: Button = $VBoxContainer/Buttons/SettingsButton
@onready var credits_button: Button = $VBoxContainer/Buttons/CreditsButton
@onready var credits_popup: PanelContainer = $CreditsPopup
@onready var title_label: Label = $VBoxContainer/Header/Title
@onready var background: Control = $TemporalBackground

const ThemeManagerClass = preload("res://scripts/background/background_theme_manager.gd")

var _pulse_timer: float = 0.0

func _ready() -> void:
	credits_popup.visible = false

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.075, 0.14, 0.98)
	sb.border_color = Color(0.329, 0.902, 0.918, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0.329, 0.902, 0.918, 0.25)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 4)
	credits_popup.add_theme_stylebox_override("panel", sb)

	play_button.pressed.connect(_on_play_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	$CreditsPopup/VBoxContainer/CloseCreditsButton.pressed.connect(func():
		credits_popup.visible = false
		$VBoxContainer.visible = true
		if background and background.has_method("set_screen_mode"):
			background.set_screen_mode(ThemeManagerClass.ScreenMode.MAIN_MENU)
	)

	# Update Play button text: "CONTINUE" if progress exists, else "PLAY"
	if SaveManager and not SaveManager.completed_levels.is_empty():
		play_button.text = "CONTINUE JOURNEY"
	else:
		play_button.text = "START PLAYING"

	if AudioManager:
		AudioManager.play_music()

func _process(delta: float) -> void:
	_pulse_timer += delta * 2.0
	var glow: float = sin(_pulse_timer) * 0.15 + 0.85
	title_label.modulate = Color(glow, 1.0, 1.0)

func _on_play_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
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
	SceneRouter.go_to_difficulty_select()

func _on_settings_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	SceneRouter.go_to_settings()

func _on_credits_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	$VBoxContainer.visible = false
	credits_popup.visible = true
	if background and background.has_method("set_screen_mode"):
		background.set_screen_mode(ThemeManagerClass.ScreenMode.CREDITS)
