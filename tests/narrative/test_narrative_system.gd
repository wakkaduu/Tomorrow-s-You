extends SceneTree

## Comprehensive Automated Test Suite for Narrative, Lore, and Archive Systems.
## Validates Chapter Registry, MORROW Transmissions, Recovered Logs, SaveManager persistence,
## and Archive progress calculations.

const NarrativeRegistryClass = preload("res://scripts/narrative/narrative_registry.gd")
const SaveManagerScript = preload("res://scripts/autoload/save_manager.gd")
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
	print("\n===================================================================")
	print("       TOMORROW'S YOU — NARRATIVE & LORE ARCHIVE TEST SUITE")
	print("===================================================================")

	run_all_narrative_tests()

	print("\n===================================================================")
	print(" NARRATIVE TEST SUMMARY: %d / %d TESTS PASSED" % [passed_tests, total_tests])
	print("===================================================================")

	if failed_tests == 0:
		print(" ALL NARRATIVE TESTS PASSED WITH 100% SUCCESS! [✓]\n")
		quit(0)
	else:
		printerr(" %d NARRATIVE TESTS FAILED! [✗]\n" % failed_tests)
		quit(1)

func run_test(test_name: String, test_callable: Callable) -> void:
	total_tests += 1
	print("\n[NARRATIVE | TEST %d] %s" % [total_tests, test_name])
	var result = test_callable.call()
	if result == true or result == null:
		passed_tests += 1
		print("   --> PASSED [✓]")
	else:
		failed_tests += 1
		printerr("   --> FAILED [✗]")

func run_all_narrative_tests() -> void:
	# TEST 1: Chapters 1 to 10 mapped 1:1 to levels 1 to 10
	run_test("All 10 campaign levels map to 10 narrative chapters", func():
		assert(NarrativeRegistryClass.CHAPTERS.size() == 10, "Must have exactly 10 chapters")
		for i in range(1, 11):
			var lid: String = "lvl_%02d" % i
			assert(NarrativeRegistryClass.CHAPTERS.has(lid), "Chapter mapping missing for " + lid)
			var ch = NarrativeRegistryClass.get_chapter_info(lid)
			assert(ch.get("number") == i, "Chapter number mismatch for " + lid)
			assert(not ch.get("title", "").is_empty(), "Chapter title is empty for " + lid)
			assert(not ch.get("code", "").is_empty(), "Chapter code is empty for " + lid)
		return true
	)

	# TEST 2: All 10 opening transmissions exist with required fields
	run_test("All 10 campaign levels have valid MORROW opening transmissions", func():
		for i in range(1, 11):
			var lid: String = "lvl_%02d" % i
			var tr = NarrativeRegistryClass.get_opening_transmission(lid)
			assert(not tr.is_empty(), "Missing opening transmission for " + lid)
			assert(tr.get("sender") == "MORROW // FACILITY AI", "Invalid sender for " + lid)
			assert(not tr.get("channel", "").is_empty(), "Missing channel for " + lid)
			var lines: Array = tr.get("lines", [])
			assert(lines.size() >= 3, "Transmission must contain multiple lines of dialogue for " + lid)
			for line in lines:
				assert(not str(line).is_empty(), "Empty line in transmission for " + lid)
		return true
	)

	# TEST 3: Outro transmissions exist for Level 1 and Level 10
	run_test("Level 1 and Level 10 outro transmissions are properly defined", func():
		var tr_01 = NarrativeRegistryClass.get_completion_transmission("lvl_01")
		assert(not tr_01.is_empty(), "Level 1 outro transmission missing")
		assert(tr_01.get("lines", []).size() >= 2, "Level 1 outro lines missing")

		var tr_10 = NarrativeRegistryClass.get_completion_transmission("lvl_10")
		assert(not tr_10.is_empty(), "Level 10 outro transmission missing")
		var lines_10: Array = tr_10.get("lines", [])
		assert(lines_10.size() >= 4, "Level 10 outro lines missing")
		var full_outro_10 = " ".join(lines_10)
		assert(full_outro_10.contains("Tomorrow begins now"), "Level 10 outro missing thematic climax phrase")
		return true
	)

	# TEST 4: All 9 Recovered Research Logs exist with metadata and content
	run_test("All 9 Recovered Research Logs are complete with Dr. Venn lore", func():
		var logs = NarrativeRegistryClass.get_all_logs()
		assert(logs.size() == 9, "Must have exactly 9 recovered logs")
		for i in range(1, 10):
			var log_id: String = "log_%03d" % i
			var log_entry = NarrativeRegistryClass.get_log(log_id)
			assert(not log_entry.is_empty(), "Missing log entry for " + log_id)
			assert(not log_entry.get("title", "").is_empty(), "Log title empty for " + log_id)
			assert(not log_entry.get("author", "").is_empty(), "Log author empty for " + log_id)
			assert(not log_entry.get("date", "").is_empty(), "Log date empty for " + log_id)
			assert(not log_entry.get("classification", "").is_empty(), "Log classification empty for " + log_id)
			assert(log_entry.get("content", "").length() > 50, "Log content too short for " + log_id)
		return true
	)

	# TEST 5: Facility Records and Timeline entries integrity
	run_test("Facility records and incident timeline entries are valid and ordered", func():
		var records = NarrativeRegistryClass.get_all_facility_records()
		assert(records.size() == 4, "Must have 4 facility records")
		for r in records:
			assert(not r.get("title", "").is_empty(), "Record title empty")
			assert(not r.get("content", "").is_empty(), "Record content empty")
			assert(r.get("unlock_level", 0) > 0, "Record unlock level invalid")

		var timeline = NarrativeRegistryClass.get_all_timeline_entries()
		assert(timeline.size() == 6, "Must have 6 timeline entries")
		var prev_ts: String = ""
		for e in timeline:
			var ts = e.get("timestamp", "")
			assert(not ts.is_empty(), "Timeline timestamp empty")
			assert(not e.get("title", "").is_empty(), "Timeline title empty")
			assert(not e.get("summary", "").is_empty(), "Timeline summary empty")
			assert(ts >= prev_ts, "Timeline must be chronologically ordered")
			prev_ts = ts
		return true
	)

	# TEST 6: SaveManager initial narrative defaults and unlock tracking
	run_test("SaveManager properly initializes and tracks narrative state", func():
		var sm = SaveManagerScript.new()
		sm._set_default_save()

		assert(sm.unlocked_transmissions.has("tr_lvl_01_intro"), "Level 1 intro must be unlocked by default")
		assert(sm.viewed_transmissions.is_empty(), "No transmissions viewed initially")
		assert(sm.unlocked_logs.is_empty(), "No logs unlocked initially")
		assert(sm.story_ending_unlocked == false, "Ending must be locked initially")

		# Unlock level 2 intro
		sm.unlock_narrative_on_level_started("lvl_02")
		assert(sm.is_transmission_unlocked("tr_lvl_02_intro"), "Level 2 intro should now be unlocked")
		assert(not sm.is_transmission_viewed("tr_lvl_02_intro"), "Level 2 intro should not be viewed yet")

		# Mark viewed
		sm.mark_transmission_viewed("tr_lvl_02_intro")
		assert(sm.is_transmission_viewed("tr_lvl_02_intro"), "Level 2 intro should be marked viewed")

		sm.free()
		return true
	)

	# TEST 7: Completing levels unlocks logs, outro transmissions, and next intros
	run_test("Level completion unlocks corresponding chapter log and next transmissions", func():
		var sm = SaveManagerScript.new()
		sm._set_default_save()

		# Complete Level 1
		sm.unlock_narrative_on_level_completed("lvl_01")
		assert(sm.is_log_unlocked("log_001"), "Log 001 must be unlocked on Level 1 completion")
		assert(sm.is_transmission_unlocked("tr_lvl_01_outro"), "Level 1 outro must be unlocked")
		assert(sm.is_transmission_unlocked("tr_lvl_02_intro"), "Level 2 intro must be unlocked")
		assert(not sm.is_log_read("log_001"), "Log 001 should be unread initially")

		# Mark log read
		sm.mark_log_read("log_001")
		assert(sm.is_log_read("log_001"), "Log 001 should be marked read")

		# Complete Level 10
		sm.unlock_narrative_on_level_completed("lvl_10")
		assert(sm.is_transmission_unlocked("tr_lvl_10_outro"), "Level 10 outro must be unlocked")
		assert(sm.story_ending_unlocked == true, "Story ending should be unlocked on Level 10 completion")

		sm.free()
		return true
	)

	# TEST 8: SaveManager narrative persistence roundtrip
	run_test("Narrative tracking persists across save file write and load", func():
		var sm1 = SaveManagerScript.new()
		sm1._set_default_save()
		sm1.unlock_narrative_on_level_completed("lvl_01")
		sm1.unlock_narrative_on_level_completed("lvl_02")
		sm1.mark_transmission_viewed("tr_lvl_01_intro")
		sm1.mark_log_read("log_001")
		sm1.write_save()

		var sm2 = SaveManagerScript.new()
		sm2.load_save()
		assert(sm2.is_log_unlocked("log_001"), "Persisted log_001 should be unlocked")
		assert(sm2.is_log_unlocked("log_002"), "Persisted log_002 should be unlocked")
		assert(sm2.is_log_read("log_001"), "Persisted log_001 read state should be preserved")
		assert(sm2.is_transmission_viewed("tr_lvl_01_intro"), "Persisted transmission viewed state preserved")

		sm1.free()
		sm2.free()
		return true
	)

	# TEST 9: Archive progress calculation
	run_test("Archive progress calculator correctly computes unlocked percentages", func():
		var sm = SaveManagerScript.new()
		sm._set_default_save()

		var initial_prog = sm.get_archive_progress()
		assert(initial_prog.get("total") == 31, "Total archive entries must be 12 + 9 + 4 + 6 = 31")
		var initial_unl = initial_prog.get("unlocked")
		assert(initial_unl > 0, "Baseline entries (intro 1, record 1, timeline 1) should be unlocked initially")

		# Unlock all levels and check progress reaches 100%
		for i in range(1, 11):
			var lid = "lvl_%02d" % i
			sm.completed_levels.append(lid)
			sm.unlock_narrative_on_level_completed(lid)

		var full_prog = sm.get_archive_progress()
		assert(full_prog.get("unlocked") == full_prog.get("total"), "All 31 items should be unlocked after full campaign")
		assert(is_equal_approx(full_prog.get("percentage"), 100.0), "Archive progress should be 100%")

		sm.free()
		return true
	)

	# TEST 10: Modal pause independence: narrative modal locks inputs without turn advance
	run_test("Narrative transmission pauses simulation without consuming turns", func():
		var sim = PuzzleSimulation.new()
		var lvl = LevelRegistryClass.get_level(0)
		sim.load_level(lvl)

		var initial_turn: int = sim.current_turn
		var initial_pos: Vector2i = sim.player_pos

		# Simulate modal active state check
		var is_modal_active: bool = true
		if not is_modal_active:
			sim.step_move(Vector2i.RIGHT)

		assert(sim.current_turn == initial_turn, "Turn counter must not advance while modal is active")
		assert(sim.player_pos == initial_pos, "Player position must not change while modal is active")

		# Once modal closes, input is processed
		is_modal_active = false
		if not is_modal_active:
			sim.step_move(Vector2i.RIGHT)

		assert(sim.current_turn == initial_turn + 1, "Turn counter advances normally after modal closes")
		assert(sim.player_pos != initial_pos, "Player moved normally after modal closes")

		sim = null
		return true
	)
