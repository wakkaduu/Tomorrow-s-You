extends Node

## Central session manager for active gameplay, current level selection, and high-level events.

const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")

signal level_started(level_def: LevelDefinition)
signal level_completed_event(level_def: LevelDefinition, turns: int, echoes: int, total_actions: int)

var current_level_index: int = 0
var current_level_def: LevelDefinition = null
var current_simulation: PuzzleSimulation = null

func _ready() -> void:
	current_simulation = PuzzleSimulation.new()
	current_simulation.level_completed.connect(_on_sim_level_completed)

func select_level(index: int) -> void:
	current_level_index = clampi(index, 0, LevelRegistryClass.get_level_count() - 1)
	current_level_def = LevelRegistryClass.get_level(current_level_index)
	current_simulation.load_level(current_level_def)
	level_started.emit(current_level_def)

func get_current_level_def() -> LevelDefinition:
	if current_level_def == null:
		select_level(0)
	return current_level_def

func next_level_exists() -> bool:
	return current_level_index + 1 < LevelRegistryClass.get_level_count()

func get_next_level_def() -> LevelDefinition:
	if next_level_exists():
		return LevelRegistryClass.get_level(current_level_index + 1)
	return null

func go_to_next_level() -> void:
	if next_level_exists():
		select_level(current_level_index + 1)
		SceneRouter.go_to_gameplay(current_level_index)
	else:
		SceneRouter.go_to_level_select()

func _on_sim_level_completed(turns: int, echoes: int, total_actions: int) -> void:
	if current_level_def == null:
		return

	if AudioManager:
		AudioManager.play_sfx("victory")

	level_completed_event.emit(current_level_def, turns, echoes, total_actions)
