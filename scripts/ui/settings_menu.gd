extends Control

## Settings screen: audio, haptics, and accessibility controls.

const UIDesignSystemClass = preload("res://scripts/ui/components/ui_design_system.gd")

@onready var music_slider: HSlider = $Content/VBoxContainer/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Content/VBoxContainer/SFXRow/SFXSlider
@onready var haptics_check: CheckBox = $Content/VBoxContainer/HapticsRow/HapticsCheck
@onready var anims_check: CheckBox = $Content/VBoxContainer/AnimsRow/AnimsCheck
@onready var reset_button: Button = $Content/VBoxContainer/ResetButton
@onready var back_button: Button = $Header/BackButton
@onready var reset_confirm_dialog: ConfirmationDialog = $ResetConfirmDialog
@onready var background: Control = $TemporalBackground

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	UIDesignSystemClass.apply_button_style(back_button, UIDesignSystemClass.ButtonType.SECONDARY)
	back_button.icon = preload("res://assets/icons/ui/icon_back.svg")

	var header_title = $Header/Title
	if header_title:
		UIDesignSystemClass.apply_display_heading(header_title, UIDesignSystemClass.FONT_SIZE_SCREEN_HEADING, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")

	UIDesignSystemClass.apply_button_style(reset_button, UIDesignSystemClass.ButtonType.DESTRUCTIVE)

	# Apply typography to row labels
	var music_lbl = $Content/VBoxContainer/MusicRow/Label
	if music_lbl:
		UIDesignSystemClass.apply_display_heading(music_lbl, 18, UIDesignSystemClass.COLOR_TEXT_PRIMARY, "SemiBold")
	var sfx_lbl = $Content/VBoxContainer/SFXRow/Label
	if sfx_lbl:
		UIDesignSystemClass.apply_display_heading(sfx_lbl, 18, UIDesignSystemClass.COLOR_TEXT_PRIMARY, "SemiBold")
	var haptics_lbl = $Content/VBoxContainer/HapticsRow/Label
	if haptics_lbl:
		UIDesignSystemClass.apply_display_heading(haptics_lbl, 18, UIDesignSystemClass.COLOR_TEXT_PRIMARY, "SemiBold")
	var anims_lbl = $Content/VBoxContainer/AnimsRow/Label
	if anims_lbl:
		UIDesignSystemClass.apply_display_heading(anims_lbl, 18, UIDesignSystemClass.COLOR_TEXT_PRIMARY, "SemiBold")

	reset_button.pressed.connect(func(): reset_confirm_dialog.popup_centered())
	reset_confirm_dialog.confirmed.connect(_on_reset_confirmed)

	if SaveManager:
		music_slider.value = SaveManager.music_volume * 100.0
		sfx_slider.value = SaveManager.sfx_volume * 100.0
		haptics_check.button_pressed = SaveManager.haptics_enabled
		anims_check.button_pressed = SaveManager.reduced_animations

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	haptics_check.toggled.connect(_on_haptics_toggled)
	anims_check.toggled.connect(_on_anims_toggled)

	_apply_safe_area()
	if AndroidSystemManager:
		AndroidSystemManager.safe_area_changed.connect(func(_m): _apply_safe_area())

func _apply_safe_area() -> void:
	if not AndroidSystemManager:
		return
	var m = AndroidSystemManager.get_safe_margins()
	var header = $Header
	if header:
		header.offset_top = maxi(float(m.get("top", 0)), 16.0)
	var content = $Content
	if content:
		content.offset_bottom = -maxi(float(m.get("bottom", 0)), 16.0)

func handle_back_button() -> bool:
	_on_back_pressed()
	return true

func _on_back_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")
	if SaveManager:
		SaveManager.write_save()
	SceneRouter.go_to_main_menu()

func _on_music_changed(val: float) -> void:
	if SaveManager:
		SaveManager.music_volume = val / 100.0
	if AudioManager:
		AudioManager._update_volumes()

func _on_sfx_changed(val: float) -> void:
	if SaveManager:
		SaveManager.sfx_volume = val / 100.0
	if AudioManager:
		AudioManager._update_volumes()
		AudioManager.play_sfx("ui_click")

func _on_haptics_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.haptics_enabled = pressed
	if pressed and AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")

func _on_anims_toggled(pressed: bool) -> void:
	if SaveManager:
		SaveManager.reduced_animations = pressed
	if background and background.has_method("_on_settings_updated"):
		background._on_settings_updated()

func _on_reset_confirmed() -> void:
	if SaveManager:
		SaveManager.reset_progress()
	if AudioManager:
		AudioManager.play_sfx("ui_click")
