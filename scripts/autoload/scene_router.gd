extends Node

## Manages screen navigation and scene transitions.

signal scene_transition_started(target_scene: String)
signal scene_transition_finished(target_scene: String)

var suppress_scene_change: bool = false
var current_scene_path: String = ""
var is_transitioning: bool = false
var _auxiliary_stack: Array[Dictionary] = []

func change_scene(scene_path: String) -> void:
	if is_transitioning:
		return
	current_scene_path = scene_path
	scene_transition_started.emit(scene_path)
	if suppress_scene_change:
		scene_transition_finished.emit(scene_path)
		return
	_clear_auxiliary_stack()
	is_transitioning = true
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err == OK:
		await get_tree().scene_changed
		is_transitioning = false
		scene_transition_finished.emit(scene_path)
	else:
		is_transitioning = false
		push_error("Failed to change scene to: " + scene_path)

# Settings and Archive retain the originating scene, including paused gameplay.
# Keeping it disabled in-tree also keeps viewport/safe-area connections valid.
func _open_auxiliary(scene_path: String) -> void:
	if suppress_scene_change:
		change_scene(scene_path)
		return
	if is_transitioning:
		return
	is_transitioning = true
	_push_auxiliary.call_deferred(scene_path)

func _push_auxiliary(scene_path: String) -> void:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		is_transitioning = false
		return
	var previous: Node = get_tree().current_scene
	if previous:
		_auxiliary_stack.append({"node": previous, "process_mode": previous.process_mode,
			"path": previous.scene_file_path, "visible": previous.visible if previous is CanvasItem else true})
		previous.process_mode = Node.PROCESS_MODE_DISABLED
		if previous is CanvasItem:
			previous.hide()
	scene_transition_started.emit(scene_path)
	var next: Node = packed.instantiate()
	get_tree().root.add_child(next)
	get_tree().current_scene = next
	current_scene_path = scene_path
	is_transitioning = false
	scene_transition_finished.emit(scene_path)

func return_from_auxiliary() -> void:
	if is_transitioning:
		return
	if _auxiliary_stack.is_empty():
		go_to_main_menu()
		return
	is_transitioning = true
	_pop_auxiliary.call_deferred()

func _pop_auxiliary() -> void:
	var entry: Dictionary = _auxiliary_stack.pop_back()
	var previous: Node = entry.node
	var outgoing: Node = get_tree().current_scene
	get_tree().current_scene = previous
	if outgoing:
		outgoing.queue_free()
	previous.process_mode = entry.process_mode
	if previous is CanvasItem:
		previous.visible = entry.visible
	current_scene_path = entry.path
	is_transitioning = false
	scene_transition_finished.emit(current_scene_path)

func _clear_auxiliary_stack() -> void:
	for entry: Dictionary in _auxiliary_stack:
		if is_instance_valid(entry.node):
			entry.node.queue_free()
	_auxiliary_stack.clear()

func go_to_boot() -> void:
	change_scene("res://scenes/boot/boot.tscn")

func go_to_main_menu() -> void:
	change_scene("res://scenes/menus/main_menu.tscn")

func go_to_difficulty_select() -> void:
	change_scene("res://scenes/menus/difficulty_select.tscn")

func go_to_level_select() -> void:
	change_scene("res://scenes/menus/level_select.tscn")

func go_to_gameplay(level_index: int = 0) -> void:
	if is_transitioning:
		return
	if GameManager:
		GameManager.select_level(level_index)
	change_scene("res://scenes/gameplay/gameplay.tscn")

func go_to_settings() -> void:
	_open_auxiliary("res://scenes/menus/settings.tscn")

func go_to_archive() -> void:
	_open_auxiliary("res://scenes/menus/incident_archive.tscn")

