extends Node

## Manages screen navigation and scene transitions.

signal scene_transition_started(target_scene: String)
signal scene_transition_finished(target_scene: String)

var current_scene_path: String = ""

func change_scene(scene_path: String) -> void:
	scene_transition_started.emit(scene_path)
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err == OK:
		current_scene_path = scene_path
		scene_transition_finished.emit(scene_path)
	else:
		push_error("Failed to change scene to: " + scene_path)

func go_to_boot() -> void:
	change_scene("res://scenes/boot/boot.tscn")

func go_to_main_menu() -> void:
	change_scene("res://scenes/menus/main_menu.tscn")

func go_to_level_select() -> void:
	change_scene("res://scenes/menus/level_select.tscn")

func go_to_gameplay(level_index: int = 0) -> void:
	if GameManager:
		GameManager.select_level(level_index)
	change_scene("res://scenes/gameplay/gameplay.tscn")

func go_to_settings() -> void:
	change_scene("res://scenes/menus/settings.tscn")

