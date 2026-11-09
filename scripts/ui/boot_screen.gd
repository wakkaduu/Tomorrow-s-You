extends Control

## Boot screen: initializes engine systems and transitions to main menu.

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel

func _ready() -> void:
	modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_on_boot_complete)

func _on_boot_complete() -> void:
	SceneRouter.go_to_main_menu()

