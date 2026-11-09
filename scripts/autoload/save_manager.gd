extends Node

## Local save and progress management for Tomorrow's You.
## Saves to user://save.cfg with safe defaults, migration logic, and corruption resilience.

const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")

signal save_loaded()
signal save_written()
signal daily_hints_reset()
signal hint_revealed(level_id: String, stage_index: int, remaining_credits: int)

const SAVE_PATH: String = "user://save.cfg"
const CURRENT_VERSION: int = 2
const DAILY_HINT_LIMIT: int = 3

var save_version: int = 2
var unlocked_levels: Array[String] = ["lvl_01"]
var completed_levels: Array[String] = [] # Only stores valid/verified completions under current rules
var level_records: Dictionary = {} # level_id -> { "actions": int, "echoes": int, "stars": int, "time_sec": float, "rules_version": int, "status": "VERIFIED"|"LEGACY" }
var legacy_records: Dictionary = {} # level_id -> { ... } invalidated records from v1

var best_actions: Dictionary = {} # level_id -> int
var best_echoes: Dictionary = {}  # level_id -> int
var best_stars: Dictionary = {}   # level_id -> int

# Daily Hint System Tracking
var last_reset_date: String = ""
var hints_used_today: int = 0
var last_observed_timestamp: int = 0
var level_hint_progress: Dictionary = {} # level_id -> int (-1: none, 0: obs, 1: strat, 2: sol)

# Injectable test clock / date provider
var _date_override: String = ""
var _timestamp_override: int = 0

# Currently active difficulty filter (1: Easy, 2: Normal, 3: Hard, 4: Expert, 5: Nightmare)
var selected_difficulty_tier: int = 1

# Settings
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var haptics_enabled: bool = true
var reduced_animations: bool = false
var tutorial_seen: bool = false

func _init() -> void:
	load_save()

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

	# Load raw records
	best_actions = config.get_value("records", "best_actions", {})
	best_echoes = config.get_value("records", "best_echoes", {})
	best_stars = config.get_value("records", "best_stars", {})
	level_records = config.get_value("records", "level_records", {})
	legacy_records = config.get_value("records", "legacy_records", {})

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

	# Settings
	music_volume = clampf(float(config.get_value("settings", "music_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("settings", "sfx_volume", 0.9)), 0.0, 1.0)
	haptics_enabled = bool(config.get_value("settings", "haptics", true))
	reduced_animations = bool(config.get_value("settings", "reduced_animations", false))
	tutorial_seen = bool(config.get_value("settings", "tutorial_seen", false))

	# Load daily hint system data
	last_reset_date = str(config.get_value("hint_daily", "last_reset_date", ""))
	hints_used_today = int(config.get_value("hint_daily", "hints_used_today", 0))
	last_observed_timestamp = int(config.get_value("hint_daily", "last_observed_timestamp", 0))
	level_hint_progress = config.get_value("hint_progress", "revealed", {})

	check_and_apply_daily_reset()

	# Schema migration
	if save_version < CURRENT_VERSION:
		_migrate_save(save_version)

	save_loaded.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		check_and_apply_daily_reset()

func _migrate_save(old_version: int) -> void:
	print("[SaveManager] Migrating save from version %d to %d..." % [old_version, CURRENT_VERSION])
	
	# In version 2, zero-Echo and sub-minimum completions are invalid.
	# Any historical record with echoes < min_echoes_required is marked as LEGACY/UNVERIFIED
	# and removed from active completed_levels so it cannot unlock higher difficulties.
	var valid_completed: Array[String] = []
	
	for lid in completed_levels:
		var lvl: LevelDefinition = LevelRegistryClass.get_level_by_id(lid)
		var recorded_echoes: int = best_echoes.get(lid, 0)
		var min_req: int = lvl.min_echoes_required if lvl else 1
		
		if recorded_echoes < min_req:
			print("[SaveManager] Invalidating legacy record for %s (recorded echoes: %d, min required: %d)" % [lid, recorded_echoes, min_req])
			legacy_records[lid] = {
				"actions": best_actions.get(lid, 0),
				"echoes": recorded_echoes,
				"rules_version": 1,
				"status": "LEGACY_INVALID"
			}
			level_records.erase(lid)
			best_stars.erase(lid)
		else:
			valid_completed.append(lid)
			var stars = calculate_stars(lid, best_actions.get(lid, 999))
			best_stars[lid] = stars
			level_records[lid] = {
				"actions": best_actions.get(lid, 0),
				"echoes": recorded_echoes,
				"stars": stars,
				"rules_version": 2,
				"status": "VERIFIED"
			}
			
	completed_levels = valid_completed
	save_version = CURRENT_VERSION
	write_save()

func write_save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("meta", "version", CURRENT_VERSION)
	config.set_value("progress", "unlocked", unlocked_levels)
	config.set_value("progress", "completed", completed_levels)
	config.set_value("records", "best_actions", best_actions)
	config.set_value("records", "best_echoes", best_echoes)
	config.set_value("records", "best_stars", best_stars)
	config.set_value("records", "level_records", level_records)
	config.set_value("records", "legacy_records", legacy_records)

	# Hint system persistence
	config.set_value("hint_daily", "last_reset_date", last_reset_date)
	config.set_value("hint_daily", "hints_used_today", hints_used_today)
	config.set_value("hint_daily", "last_observed_timestamp", last_observed_timestamp)
	config.set_value("hint_progress", "revealed", level_hint_progress)

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

func get_level_stars(level_id: String) -> int:
	if not completed_levels.has(level_id):
		return 0
	return best_stars.get(level_id, 1)

func calculate_stars(level_id: String, actions: int) -> int:
	var lvl: LevelDefinition = LevelRegistryClass.get_level_by_id(level_id)
	if not lvl:
		return 1
	if lvl.target_3_stars > 0 and actions <= lvl.target_3_stars:
		return 3
	elif lvl.target_2_stars > 0 and actions <= lvl.target_2_stars:
		return 2
	return 1

func record_level_completion(level_id: String, actions: int, echoes: int, next_level_id: String = "", time_sec: float = 0.0) -> void:
	var lvl: LevelDefinition = LevelRegistryClass.get_level_by_id(level_id)
	var min_req: int = lvl.min_echoes_required if lvl else 1
	
	if echoes < min_req:
		push_warning("Attempted to record invalid completion: %d echoes < %d required" % [echoes, min_req])
		return

	if not completed_levels.has(level_id):
		completed_levels.append(level_id)

	# Calculate stars earned
	var stars: int = calculate_stars(level_id, actions)
	var prev_stars: int = best_stars.get(level_id, 0)
	if stars > prev_stars:
		best_stars[level_id] = stars

	# Update best records
	var prev_best_act: int = best_actions.get(level_id, 999999)
	if actions < prev_best_act:
		best_actions[level_id] = actions

	var prev_best_ech: int = best_echoes.get(level_id, 999999)
	if echoes < prev_best_ech:
		best_echoes[level_id] = echoes

	# Store structured record
	level_records[level_id] = {
		"actions": actions,
		"echoes": echoes,
		"stars": stars,
		"time_sec": time_sec,
		"rules_version": CURRENT_VERSION,
		"status": "VERIFIED"
	}

	# Clean up any legacy marker for this level
	legacy_records.erase(level_id)

	# Unlock next level
	if not next_level_id.is_empty() and not unlocked_levels.has(next_level_id):
		unlocked_levels.append(next_level_id)

	write_save()

# ==============================================================================
# DIFFICULTY TIERS & PROGRESSION HELPERS
# ==============================================================================

func get_difficulty_levels(tier: int) -> Array[LevelDefinition]:
	var result: Array[LevelDefinition] = []
	for lvl in LevelRegistryClass.get_all_levels():
		if lvl.difficulty_tier == tier:
			result.append(lvl)
	return result

func is_difficulty_unlocked(tier: int) -> bool:
	if tier <= 1:
		return true # Easy is always unlocked
	# Higher difficulties unlock progressively after completing 100% of the previous tier
	var prev_tier_levels: Array[LevelDefinition] = get_difficulty_levels(tier - 1)
	if prev_tier_levels.is_empty():
		return true
	for lvl in prev_tier_levels:
		if not completed_levels.has(lvl.level_id):
			return false
	return true

func get_difficulty_completion_percentage(tier: int) -> float:
	var tier_levels: Array[LevelDefinition] = get_difficulty_levels(tier)
	if tier_levels.is_empty():
		return 0.0
	var completed_count: int = 0
	for lvl in tier_levels:
		if completed_levels.has(lvl.level_id):
			completed_count += 1
	return float(completed_count) / float(tier_levels.size()) * 100.0

func get_difficulty_stars(tier: int) -> Dictionary:
	var tier_levels: Array[LevelDefinition] = get_difficulty_levels(tier)
	var earned: int = 0
	var total: int = tier_levels.size() * 3
	for lvl in tier_levels:
		earned += get_level_stars(lvl.level_id)
	return {"earned": earned, "total": total}

func get_total_stars() -> Dictionary:
	var earned: int = 0
	var total: int = LevelRegistryClass.get_level_count() * 3
	for lvl in LevelRegistryClass.get_all_levels():
		earned += get_level_stars(lvl.level_id)
	return {"earned": earned, "total": total}

func reset_progress() -> void:
	_set_default_save()
	write_save()

func _set_default_save() -> void:
	save_version = CURRENT_VERSION
	unlocked_levels = ["lvl_01"]
	completed_levels = []
	best_actions = {}
	best_echoes = {}
	best_stars = {}
	level_records = {}
	legacy_records = {}
	selected_difficulty_tier = 1
	music_volume = 0.8
	sfx_volume = 0.9
	haptics_enabled = true
	reduced_animations = false
	tutorial_seen = false
	last_reset_date = get_current_date()
	hints_used_today = 0
	last_observed_timestamp = get_current_timestamp()
	level_hint_progress = {}

# ==============================================================================
# DAILY HINT SYSTEM & CLOCK MANAGEMENT
# ==============================================================================

func get_current_date() -> String:
	if not _date_override.is_empty():
		return _date_override
	return Time.get_date_string_from_system(false)

func get_current_timestamp() -> int:
	if _timestamp_override > 0:
		return _timestamp_override
	return int(Time.get_unix_time_from_system())

func set_test_date(date_str: String, timestamp: int = 0) -> void:
	_date_override = date_str
	_timestamp_override = timestamp
	check_and_apply_daily_reset()

func clear_test_date() -> void:
	_date_override = ""
	_timestamp_override = 0

func check_and_apply_daily_reset() -> bool:
	var curr_date: String = get_current_date()
	var curr_ts: int = get_current_timestamp()

	if last_reset_date.is_empty():
		last_reset_date = curr_date
		hints_used_today = 0
		last_observed_timestamp = curr_ts
		write_save()
		return true

	# Clock rollback protection:
	# If detected local date is earlier than last recorded valid date,
	# do not grant fresh allowance (prevent clock manipulation).
	if curr_date < last_reset_date:
		push_warning("[SaveManager] Clock rollback detected: Current date '%s' < Last reset date '%s'. Retaining existing hint allowance." % [curr_date, last_reset_date])
		return false

	# Legitimate new calendar day!
	if curr_date > last_reset_date:
		print("[SaveManager] Calendar day rolled over from %s to %s. Resetting daily hint allowance to %d." % [last_reset_date, curr_date, DAILY_HINT_LIMIT])
		last_reset_date = curr_date
		hints_used_today = 0
		last_observed_timestamp = curr_ts
		write_save()
		daily_hints_reset.emit()
		return true

	if curr_ts > last_observed_timestamp:
		last_observed_timestamp = curr_ts

	return false

func get_remaining_daily_hints() -> int:
	check_and_apply_daily_reset()
	return clampi(DAILY_HINT_LIMIT - hints_used_today, 0, DAILY_HINT_LIMIT)

func get_revealed_hint_index(level_id: String) -> int:
	return int(level_hint_progress.get(level_id, -1))

func can_reveal_next_hint(level_id: String) -> bool:
	check_and_apply_daily_reset()
	var highest: int = get_revealed_hint_index(level_id)
	if highest >= 2:
		return false # All 3 hints already unlocked
	return get_remaining_daily_hints() > 0

func reveal_next_hint(level_id: String) -> bool:
	check_and_apply_daily_reset()
	if not can_reveal_next_hint(level_id):
		return false

	hints_used_today += 1
	var next_idx: int = get_revealed_hint_index(level_id) + 1
	level_hint_progress[level_id] = next_idx
	last_observed_timestamp = get_current_timestamp()
	write_save()
	hint_revealed.emit(level_id, next_idx, get_remaining_daily_hints())
	return true



