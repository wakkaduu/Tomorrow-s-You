extends SceneTree

## Dedicated Verification Suite for Save Scenarios and Story Triggers.
## Tests Scenario A (Existing v2 player save migration) and Scenario B (Fresh profile).
## Verifies opening transmission triggers, research log unlocking, and archive status.

const NarrativeRegistryClass = preload("res://scripts/narrative/narrative_registry.gd")
const SaveManagerScript = preload("res://scripts/autoload/save_manager.gd")
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
	print("\n===================================================================")
	print("   TOMORROW'S YOU — SAVE SCENARIOS & STORY TRIGGERS TEST SUITE")
	print("===================================================================")

	run_all_scenario_tests()

	print("\n===================================================================")
	print(" SCENARIO TEST SUMMARY: %d / %d TESTS PASSED" % [passed_tests, total_tests])
	print("===================================================================")

	if failed_tests == 0:
		print(" ALL SCENARIO TESTS PASSED WITH 100% SUCCESS! [✓]\n")
		quit(0)
	else:
		printerr(" %d SCENARIO TESTS FAILED! [✗]\n" % failed_tests)
		quit(1)

func run_test(test_name: String, test_callable: Callable) -> void:
	total_tests += 1
	print("\n[SCENARIO | TEST %d] %s" % [total_tests, test_name])
	var result = test_callable.call()
	if result == true or result == null:
		passed_tests += 1
		print("   --> PASSED [✓]")
	else:
		failed_tests += 1
		printerr("   --> FAILED [✗]")

func run_all_scenario_tests() -> void:
	var sandbox_v2_path: String = "user://test_scenario_a_v2.cfg"
	var sandbox_fresh_path: String = "user://test_scenario_b_fresh.cfg"

	# ==========================================================================
	# SCENARIO A: EXISTING PLAYER SAVE (MIGRATION FROM SCHEMA V2)
	# ==========================================================================

	run_test("Scenario A: Existing v2 player save preserved and properly migrated to v3", func():
		# 1. Create a simulated v2 player save file (levels 1-5 completed, stars earned, hints used, NO narrative section)
		var v2_config: ConfigFile = ConfigFile.new()
		v2_config.set_value("meta", "version", 2)
		v2_config.set_value("progress", "unlocked", ["lvl_01", "lvl_02", "lvl_03", "lvl_04", "lvl_05", "lvl_06"])
		v2_config.set_value("progress", "completed", ["lvl_01", "lvl_02", "lvl_03", "lvl_04", "lvl_05"])
		v2_config.set_value("records", "best_actions", {"lvl_01": 16, "lvl_02": 16, "lvl_03": 18, "lvl_04": 22, "lvl_05": 26})
		v2_config.set_value("records", "best_echoes", {"lvl_01": 1, "lvl_02": 1, "lvl_03": 1, "lvl_04": 2, "lvl_05": 2})
		v2_config.set_value("records", "best_stars", {"lvl_01": 3, "lvl_02": 3, "lvl_03": 3, "lvl_04": 3, "lvl_05": 3})
		v2_config.set_value("records", "level_records", {
			"lvl_01": {"actions": 16, "echoes": 1, "rules_version": 2, "stars": 3, "status": "VERIFIED", "time_sec": 12.5}
		})
		v2_config.set_value("hint_daily", "last_reset_date", "2026-11-10")
		v2_config.set_value("hint_daily", "hints_used_today", 1)
		v2_config.set_value("hint_daily", "last_observed_timestamp", 1794270000)
		v2_config.save(sandbox_v2_path)

		# 2. Load into SaveManager
		var sm = SaveManagerScript.new()
		sm.set_custom_save_path(sandbox_v2_path)
		sm.load_save()

		# Verify migration to v3
		assert(sm.save_version == 3, "Save version must be upgraded to 3")

		# Verify existing campaign progress is 100% PRESERVED
		assert(sm.completed_levels.size() == 5, "Completed levels count must be 5")
		assert(sm.completed_levels.has("lvl_01"), "Level 1 must remain completed")
		assert(sm.completed_levels.has("lvl_05"), "Level 5 must remain completed")
		assert(sm.is_level_unlocked("lvl_06"), "Level 6 must remain unlocked")
		assert(sm.best_stars.get("lvl_01") == 3, "Level 1 stars must be preserved")
		assert(sm.best_actions.get("lvl_01") == 16, "Level 1 best actions must be preserved")
		assert(sm.hints_used_today == 1, "Daily hints used must be preserved")

		# Verify narrative unlocked content derived from progress
		assert(sm.is_transmission_unlocked("tr_lvl_01_intro"), "Level 1 intro must be unlocked")
		assert(sm.is_transmission_unlocked("tr_lvl_01_outro"), "Level 1 outro must be unlocked")
		assert(sm.is_transmission_unlocked("tr_lvl_02_intro"), "Level 2 intro must be unlocked")
		assert(sm.is_transmission_unlocked("tr_lvl_06_intro"), "Level 6 intro must be unlocked")
		assert(sm.is_log_unlocked("log_001"), "Log 001 must be unlocked")
		assert(sm.is_log_unlocked("log_005"), "Log 005 must be unlocked")
		assert(not sm.is_log_unlocked("log_006"), "Log 006 must remain locked (level 6 not yet complete)")

		# CRITICAL: Verify that existing save migration did NOT mark transmissions as already viewed
		assert(sm.viewed_transmissions.is_empty(), "Viewed transmissions must be empty on migration from v2!")
		assert(not sm.is_transmission_viewed("tr_lvl_01_intro"), "Level 1 intro must NOT be viewed!")
		assert(sm.read_logs.is_empty(), "Read logs must be empty on migration from v2!")

		# Verify archive reflects unlocked progress accurately
		var prog = sm.get_archive_progress()
		assert(prog.get("unlocked") > 10, "Archive should have substantial unlocked records for completed chapters")
		assert(prog.get("percentage") > 30.0, "Archive percentage should reflect 5 completed chapters")

		sm.free()
		DirAccess.remove_absolute(sandbox_v2_path)
		return true
	)

	# ==========================================================================
	# SCENARIO B: FRESH TEST SAVE (CLEAN PROFILE)
	# ==========================================================================

	run_test("Scenario B: Fresh profile starts clean, Level 1 transmission is unviewed", func():
		var sm = SaveManagerScript.new()
		sm.set_custom_save_path(sandbox_fresh_path)
		sm._set_default_save()

		# Verify fresh baseline
		assert(sm.unlocked_levels == ["lvl_01"], "Fresh profile starts with only lvl_01 unlocked")
		assert(sm.completed_levels.is_empty(), "Fresh profile has zero completed levels")
		assert(sm.unlocked_transmissions == ["tr_lvl_01_intro"], "Only Level 1 intro unlocked initially")
		assert(sm.viewed_transmissions.is_empty(), "Zero transmissions viewed initially")
		assert(sm.unlocked_logs.is_empty(), "Zero logs unlocked initially")
		assert(sm.read_logs.is_empty(), "Zero logs read initially")
		assert(sm.story_ending_unlocked == false, "Ending locked initially")

		# When Level 1 is started
		sm.unlock_narrative_on_level_started("lvl_01")
		assert(sm.is_transmission_unlocked("tr_lvl_01_intro"), "tr_lvl_01_intro is unlocked")
		assert(not sm.is_transmission_viewed("tr_lvl_01_intro"), "tr_lvl_01_intro is UNVIEWED (will trigger modal)")

		# Simulate player viewing Level 1 intro transmission
		sm.mark_transmission_viewed("tr_lvl_01_intro")
		assert(sm.is_transmission_viewed("tr_lvl_01_intro"), "tr_lvl_01_intro is now marked viewed")

		# Simulate completing Level 1
		sm.unlock_narrative_on_level_completed("lvl_01")
		assert(sm.is_log_unlocked("log_001"), "log_001 is unlocked after Level 1 completion")
		assert(not sm.is_log_read("log_001"), "log_001 is unread (displays [NEW] badge)")
		assert(sm.is_transmission_unlocked("tr_lvl_01_outro"), "tr_lvl_01_outro unlocked after Level 1 completion")
		assert(sm.is_transmission_unlocked("tr_lvl_02_intro"), "tr_lvl_02_intro unlocked for next level")
		assert(not sm.is_transmission_viewed("tr_lvl_02_intro"), "tr_lvl_02_intro is UNVIEWED")

		# Simulate reading log_001 in archive
		sm.mark_log_read("log_001")
		assert(sm.is_log_read("log_001"), "log_001 is now marked read")

		sm.free()
		DirAccess.remove_absolute(sandbox_fresh_path)
		return true
	)

	# ==========================================================================
	# VERIFICATION 3: ALL 10 CAMPAIGN LEVELS TRANSMISSION TRIGGER MAPPING
	# ==========================================================================

	run_test("All 10 campaign levels trigger distinct opening transmissions", func():
		for i in range(1, 11):
			var lid = "lvl_%02d" % i
			var tr = NarrativeRegistryClass.get_opening_transmission(lid)
			assert(not tr.is_empty(), "Level %s must have an opening transmission" % lid)
			assert(tr.get("id") == "tr_lvl_%02d_intro" % i, "Level %s transmission ID mismatch" % lid)
			assert(tr.get("sender") == "MORROW // FACILITY AI", "Level %s sender mismatch" % lid)
			var lines: Array = tr.get("lines", [])
			assert(lines.size() >= 3, "Level %s must have at least 3 lines of dialogue" % lid)
		return true
	)

	# ==========================================================================
	# VERIFICATION 4: LEVEL 10 CLIMAX & ENDING SEQUENCE
	# ==========================================================================

	run_test("Level 10 completion triggers climax transmission and ending protocol", func():
		var sm = SaveManagerScript.new()
		sm.set_custom_save_path(sandbox_fresh_path)
		sm._set_default_save()

		for i in range(1, 11):
			var lid = "lvl_%02d" % i
			sm.completed_levels.append(lid)
			sm.unlock_narrative_on_level_completed(lid)

		assert(sm.story_ending_unlocked == true, "Story ending flag must be true")
		var outro_10 = NarrativeRegistryClass.get_completion_transmission("lvl_10")
		assert(not outro_10.is_empty(), "Level 10 outro transmission must exist")
		assert(outro_10.get("lines", []).size() == 6, "Level 10 outro must have exactly 6 thematic lines")
		assert(outro_10.get("lines", [])[5] == "Tomorrow begins now.", "Climax ending line must be 'Tomorrow begins now.'")

		var prog = sm.get_archive_progress()
		assert(prog.get("unlocked") == 31, "All 31 archive records must be unlocked upon campaign completion")
		assert(is_equal_approx(prog.get("percentage"), 100.0), "Archive status must be 100%")

		sm.free()
		DirAccess.remove_absolute(sandbox_fresh_path)
		return true
	)

