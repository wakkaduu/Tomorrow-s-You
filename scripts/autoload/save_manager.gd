extends Node

## Local save and progress management for Tomorrow's You.
## Saves to user://save.cfg with safe defaults and corruption resilience.

signal save_loaded()
signal save_written()

const SAVE_PATH: String = "user://save.cfg"
const CURRENT_VERSION: int = 1

var save_version: int = 1
var unlocked_levels: Array[String] = ["lvl_01"]
var completed_levels: Array[String] = []
var best_actions: Dictionary = {} # level_id -> int
var best_echoes: Dictionary = {}  # level_id -> int

# Settings
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var haptics_enabled: bool = true
var reduced_animations: bool = false
var tutorial_seen: bool = false

func _ready() -> void:
	load_save()

func load_save() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SAVE_PATH)
	if err != OK:
		# First launch or no save file; set defaults
		_set_default_save()
		save_loaded.emit()
		return

	save_version = config.get_value("meta", "version", 1)

	# Progression
	var raw_unlocked = config.get_value("progress", "unlocked", ["lvl_01"])
	unlocked_levels.clear()
	for id in raw_unlocked:
		unlocked_levels.append(str(id))
	if not unlocked_levels.has("lvl_01"):
		unlocked_levels.append("lvl_01")

	var raw_completed = config.get_value("progress", "completed", [])
	completed_levels.clear()
	for id in raw_completed:
		completed_levels.append(str(id))

	best_actions = config.get_value("records", "best_actions", {})
	best_echoes = config.get_value("records", "best_echoes", {})

	# Settings
	music_volume = clampf(float(config.get_value("settings", "music_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("settings", "sfx_volume", 0.9)), 0.0, 1.0)
	haptics_enabled = bool(config.get_value("settings", "haptics", true))
	reduced_animations = bool(config.get_value("settings", "reduced_animations", false))
	tutorial_seen = bool(config.get_value("settings", "tutorial_seen", false))

	save_loaded.emit()

func write_save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("meta", "version", CURRENT_VERSION)
	config.set_value("progress", "unlocked", unlocked_levels)
	config.set_value("progress", "completed", completed_levels)
	config.set_value("records", "best_actions", best_actions)
	config.set_value("records", "best_echoes", best_echoes)

	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "haptics", haptics_enabled)
	config.set_value("settings", "reduced_animations", reduced_animations)
	config.set_value("settings", "tutorial_seen", tutorial_seen)

	var err: Error = config.save(SAVE_PATH)
	if err == OK:
		save_written.emit()
	else:
		push_error("Failed to write save file to: " + SAVE_PATH)

func is_level_unlocked(level_id: String) -> bool:
	return unlocked_levels.has(level_id)

func is_level_completed(level_id: String) -> bool:
	return completed_levels.has(level_id)

func record_level_completion(level_id: String, actions: int, echoes: int, next_level_id: String = "") -> void:
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)

	# Update best records
	var prev_best_act: int = best_actions.get(level_id, 999999)
	if actions < prev_best_act:
		best_actions[level_id] = actions

	var prev_best_ech: int = best_echoes.get(level_id, 999999)
	if echoes < prev_best_ech:
		best_echoes[level_id] = echoes

	# Unlock next level
	if not next_level_id.is_empty() and not unlocked_levels.has(next_level_id):
		unlocked_levels.append(next_level_id)

	write_save()

func reset_progress() -> void:
	_set_default_save()
	write_save()

func _set_default_save() -> void:
	save_version = CURRENT_VERSION
	unlocked_levels = ["lvl_01"]
	completed_levels = []
	best_actions = {}
	best_echoes = {}
	music_volume = 0.8
	sfx_volume = 0.9
	haptics_enabled = true
	reduced_animations = false
	tutorial_seen = false

