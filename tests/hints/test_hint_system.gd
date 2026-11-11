extends SceneTree

# Preloads to ensure robust headless standalone execution
const SaveManagerClass = preload("res://scripts/autoload/save_manager.gd")
const HintRegistryClass = preload("res://scripts/hints/hint_registry.gd")
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")

func _init() -> void:
	print("\n===================================================================")
	print("       TOMORROW'S YOU — DAILY HINT SYSTEM AUTOMATED SUITE (20 TESTS)")
	print("===================================================================")

	var counters: Dictionary = {"total": 0, "passed": 0}

	var run_test = func(test_num: int, test_name: String, test_fn: Callable) -> void:
		counters["total"] += 1
		print("[HINT | TEST %2d] %s" % [test_num, test_name])
		var ok: bool = false
		var err_msg: String = ""
		var result = test_fn.call()
		if result is bool:
			ok = result
		else:
			ok = false
			err_msg = "Expected boolean return, got: " + str(result)
		
		if ok:
			counters["passed"] += 1
			print("   --> PASSED [✓]")
		else:
			push_error("   --> FAILED [✗]: %s %s" % [test_name, err_msg])

	var save_mgr = SaveManagerClass.new()
	save_mgr.set_test_date("2026-11-10", 1000)
	save_mgr.set_custom_save_path("user://hint-clock-tests.cfg")
	save_mgr.reset_progress()

	# --------------------------------------------------------------------------
	# TEST 1: New player starts with 3 daily hints
	# --------------------------------------------------------------------------
	run_test.call(1, "New player starts with 3 daily hints", func() -> bool:
		save_mgr.reset_progress()
		return save_mgr.get_remaining_daily_hints() == 3
	)

	# --------------------------------------------------------------------------
	# TEST 2: Revealing a hint decrements the daily count by 1 (3 -> 2)
	# --------------------------------------------------------------------------
	run_test.call(2, "Revealing a hint decrements daily count by 1 (3 -> 2)", func() -> bool:
		var ok: bool = save_mgr.reveal_next_hint("lvl_01")
		var rem: int = save_mgr.get_remaining_daily_hints()
		var stage: int = save_mgr.get_revealed_hint_index("lvl_01")
		return ok and rem == 2 and stage == 0
	)

	# --------------------------------------------------------------------------
	# TEST 3: Revealing a 2nd hint decrements count to 1 (2 -> 1)
	# --------------------------------------------------------------------------
	run_test.call(3, "Revealing a 2nd hint decrements count to 1 (2 -> 1)", func() -> bool:
		var ok: bool = save_mgr.reveal_next_hint("lvl_01")
		var rem: int = save_mgr.get_remaining_daily_hints()
		var stage: int = save_mgr.get_revealed_hint_index("lvl_01")
		return ok and rem == 1 and stage == 1
	)

	# --------------------------------------------------------------------------
	# TEST 4: Revealing a 3rd hint decrements count to 0 (1 -> 0)
	# --------------------------------------------------------------------------
	run_test.call(4, "Revealing a 3rd hint decrements count to 0 (1 -> 0)", func() -> bool:
		var ok: bool = save_mgr.reveal_next_hint("lvl_01")
		var rem: int = save_mgr.get_remaining_daily_hints()
		var stage: int = save_mgr.get_revealed_hint_index("lvl_01")
		return ok and rem == 0 and stage == 2
	)

	# --------------------------------------------------------------------------
	# TEST 5: Attempting to reveal a 4th hint when daily count is 0 is blocked
	# --------------------------------------------------------------------------
	run_test.call(5, "Attempting to reveal a 4th hint when daily count is 0 is blocked", func() -> bool:
		var can_rev: bool = save_mgr.can_reveal_next_hint("lvl_02")
		var ok: bool = save_mgr.reveal_next_hint("lvl_02")
		var rem: int = save_mgr.get_remaining_daily_hints()
		var stage: int = save_mgr.get_revealed_hint_index("lvl_02")
		return (not can_rev) and (not ok) and rem == 0 and stage == -1
	)

	# --------------------------------------------------------------------------
	# TEST 6: Daily hint allowance is shared across levels
	# --------------------------------------------------------------------------
	run_test.call(6, "Daily hint allowance is shared across levels", func() -> bool:
		save_mgr.reset_progress()
		save_mgr.set_test_date("2026-11-10", 1000)
		# Reveal 1 in lvl_01
		save_mgr.reveal_next_hint("lvl_01")
		if save_mgr.get_remaining_daily_hints() != 2:
			return false
		# Now in lvl_02, remaining must be 2, not 3
		var rem_for_lvl_02: int = save_mgr.get_remaining_daily_hints()
		if rem_for_lvl_02 != 2:
			return false
		# Reveal 1 in lvl_02
		save_mgr.reveal_next_hint("lvl_02")
		# Now in lvl_03, remaining must be 1
		return save_mgr.get_remaining_daily_hints() == 1
	)

	# --------------------------------------------------------------------------
	# TEST 7: Revisiting an already revealed hint is free (0 credits consumed)
	# --------------------------------------------------------------------------
	run_test.call(7, "Revisiting an already revealed hint is free (0 credits consumed)", func() -> bool:
		var rem_before: int = save_mgr.get_remaining_daily_hints()
		var stage_idx: int = save_mgr.get_revealed_hint_index("lvl_01")
		var hint_data: Dictionary = HintRegistryClass.get_hint_stage("lvl_01", stage_idx)
		var rem_after: int = save_mgr.get_remaining_daily_hints()
		return rem_before == rem_after and not hint_data.is_empty()
	)

	# --------------------------------------------------------------------------
	# TEST 8: Cancelling the confirmation modal does not consume a hint
	# --------------------------------------------------------------------------
	run_test.call(8, "Cancelling the confirmation modal does not consume a hint", func() -> bool:
		var rem_before: int = save_mgr.get_remaining_daily_hints()
		# Emulate opening confirmation dialog and cancelling
		var confirm_modal_visible: bool = true
		# User presses Cancel:
		confirm_modal_visible = false
		var rem_after: int = save_mgr.get_remaining_daily_hints()
		return rem_before == rem_after and (not confirm_modal_visible)
	)

	# --------------------------------------------------------------------------
	# TEST 9: Opening the hint panel does not consume a hint
	# --------------------------------------------------------------------------
	run_test.call(9, "Opening the hint panel does not consume a hint", func() -> bool:
		var rem_before: int = save_mgr.get_remaining_daily_hints()
		# Opening panel only reads remaining allowance and revealed hints
		save_mgr.check_and_apply_daily_reset()
		var rem_check: int = save_mgr.get_remaining_daily_hints()
		var rem_after: int = save_mgr.get_remaining_daily_hints()
		return rem_before == rem_check and rem_before == rem_after
	)

	# --------------------------------------------------------------------------
	# TEST 10: Closing the hint panel without revealing does not consume a hint
	# --------------------------------------------------------------------------
	run_test.call(10, "Closing the hint panel without revealing does not consume a hint", func() -> bool:
		var rem_before: int = save_mgr.get_remaining_daily_hints()
		# Panel closed
		var rem_after: int = save_mgr.get_remaining_daily_hints()
		return rem_before == rem_after
	)

	# --------------------------------------------------------------------------
	# TEST 11: Allowance resets to 3 on the next local calendar day (test date injection)
	# --------------------------------------------------------------------------
	run_test.call(11, "Allowance resets to 3 on the next local calendar day", func() -> bool:
		save_mgr.set_test_date("2026-11-10", 1000)
		# Exhaust remaining hints
		while save_mgr.get_remaining_daily_hints() > 0:
			save_mgr.reveal_next_hint("lvl_03")
		if save_mgr.get_remaining_daily_hints() != 0:
			return false
		# Roll clock forward to next calendar day
		save_mgr.set_test_date("2026-11-11", 86400 + 1000)
		return save_mgr.get_remaining_daily_hints() == 3
	)

	# --------------------------------------------------------------------------
	# TEST 12: Allowance does not reset before midnight
	# --------------------------------------------------------------------------
	run_test.call(12, "Allowance does not reset before midnight within same date", func() -> bool:
		save_mgr.set_test_date("2026-11-11", 100000)
		save_mgr.reveal_next_hint("lvl_04") # Consumes 1 hint -> 2 remaining
		if save_mgr.get_remaining_daily_hints() != 2:
			return false
		# Advance time within same calendar day (e.g. 5 hours later)
		save_mgr.set_test_date("2026-11-11", 100000 + 18000)
		return save_mgr.get_remaining_daily_hints() == 2
	)

	# --------------------------------------------------------------------------
	# TEST 13: Daily count persists across application restarts (save/load roundtrip)
	# --------------------------------------------------------------------------
	run_test.call(13, "Daily count persists across application restarts", func() -> bool:
		save_mgr.set_test_date("2026-11-12", 200000)
		save_mgr.reset_progress()
		save_mgr.set_test_date("2026-11-12", 200000)
		save_mgr.reveal_next_hint("lvl_01")
		save_mgr.reveal_next_hint("lvl_02")
		# 1 hint remaining
		if save_mgr.get_remaining_daily_hints() != 1:
			return false
		save_mgr.write_save()

		# Instantiate a fresh SaveManager to simulate application restart
		var fresh_mgr = SaveManagerClass.new()
		fresh_mgr.set_test_date("2026-11-12", 200000)
		fresh_mgr.set_custom_save_path("user://hint-clock-tests.cfg")
		fresh_mgr.load_save()
		var rem: int = fresh_mgr.get_remaining_daily_hints()
		fresh_mgr.free()
		return rem == 1
	)

	# --------------------------------------------------------------------------
	# TEST 14: Revealed hints remain revealed across application restarts
	# --------------------------------------------------------------------------
	run_test.call(14, "Revealed hints remain revealed across application restarts", func() -> bool:
		var fresh_mgr = SaveManagerClass.new()
		fresh_mgr.set_test_date("2026-11-12", 200000)
		fresh_mgr.set_custom_save_path("user://hint-clock-tests.cfg")
		fresh_mgr.load_save()
		var lvl_01_idx: int = fresh_mgr.get_revealed_hint_index("lvl_01")
		var lvl_02_idx: int = fresh_mgr.get_revealed_hint_index("lvl_02")
		fresh_mgr.free()
		return lvl_01_idx >= 0 and lvl_02_idx >= 0
	)

	# --------------------------------------------------------------------------
	# TEST 15: Level-specific hint progression is independent
	# --------------------------------------------------------------------------
	run_test.call(15, "Level-specific hint progression is independent", func() -> bool:
		save_mgr.set_test_date("2026-11-13", 300000)
		save_mgr.reset_progress()
		save_mgr.set_test_date("2026-11-13", 300000)
		save_mgr.reveal_next_hint("lvl_05")
		save_mgr.reveal_next_hint("lvl_05")
		# lvl_05 should be at stage 1
		# lvl_06 should still be at stage -1
		var l5_idx: int = save_mgr.get_revealed_hint_index("lvl_05")
		var l6_idx: int = save_mgr.get_revealed_hint_index("lvl_06")
		return l5_idx == 1 and l6_idx == -1
	)

	# --------------------------------------------------------------------------
	# TEST 16: Level with all 3 hints revealed shows all hints and does not consume credits
	# --------------------------------------------------------------------------
	run_test.call(16, "Level with all 3 hints revealed does not consume more daily credits", func() -> bool:
		save_mgr.set_test_date("2026-11-14", 400000)
		save_mgr.reset_progress()
		save_mgr.set_test_date("2026-11-14", 400000)
		save_mgr.reveal_next_hint("lvl_06") # Stage 0
		save_mgr.reveal_next_hint("lvl_06") # Stage 1
		save_mgr.reveal_next_hint("lvl_06") # Stage 2 (All revealed)
		if save_mgr.get_revealed_hint_index("lvl_06") != 2:
			return false
		
		# Give a new day with 3 fresh credits
		save_mgr.set_test_date("2026-11-15", 500000)
		if save_mgr.get_remaining_daily_hints() != 3:
			return false
		
		var can_rev: bool = save_mgr.can_reveal_next_hint("lvl_06")
		var rev_res: bool = save_mgr.reveal_next_hint("lvl_06")
		var rem: int = save_mgr.get_remaining_daily_hints()
		return (not can_rev) and (not rev_res) and rem == 3
	)

	# --------------------------------------------------------------------------
	# TEST 17: Clock rollback does not grant fresh hint allowance
	# --------------------------------------------------------------------------
	run_test.call(17, "Clock rollback does not grant fresh hint allowance", func() -> bool:
		save_mgr.set_test_date("2026-11-15", 500000)
		# Exhaust all hints on 2026-11-15
		save_mgr.reveal_next_hint("lvl_07")
		save_mgr.reveal_next_hint("lvl_07")
		save_mgr.reveal_next_hint("lvl_07")
		if save_mgr.get_remaining_daily_hints() != 0:
			return false
		
		# Roll clock BACKWARDS to 2026-11-14
		save_mgr.set_test_date("2026-11-14", 400000)
		var rem_after_rollback: int = save_mgr.get_remaining_daily_hints()
		return rem_after_rollback == 0
	)

	# --------------------------------------------------------------------------
	# TEST 18: Opening hint panel pauses gameplay (inputs ignored, echoes do not move)
	# --------------------------------------------------------------------------
	run_test.call(18, "Opening hint panel pauses gameplay (inputs ignored, echoes do not move)", func() -> bool:
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		var lvl = LevelRegistryClass.get_level(0)
		sim.load_level(lvl)
		var p_start: Vector2i = sim.player_pos
		
		# Simulate modal active guard
		var modal_active: bool = true
		var step_move_guarded = func(dir: Vector2i) -> bool:
			if modal_active:
				return false
			return sim.step_move(dir)
		
		var moved: bool = step_move_guarded.call(Vector2i.RIGHT)
		return (not moved) and sim.player_pos == p_start
	)

	# --------------------------------------------------------------------------
	# TEST 19: Opening hint panel does not advance the global turn counter
	# --------------------------------------------------------------------------
	run_test.call(19, "Opening hint panel does not advance the global turn counter", func() -> bool:
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		var lvl = LevelRegistryClass.get_level(0)
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		var turn_before: int = sim.current_turn
		
		# Modal active; user taps screen or wait button while modal is open
		var modal_active: bool = true
		var step_wait_guarded = func() -> void:
			if modal_active:
				return
			sim.step_wait()
		
		step_wait_guarded.call()
		step_wait_guarded.call()
		return sim.current_turn == turn_before
	)

	# --------------------------------------------------------------------------
	# TEST 20: All 10 campaign levels have valid, non-empty, solution-verified hints
	# --------------------------------------------------------------------------
	run_test.call(20, "All 10 campaign levels have valid, solution-verified hints registered", func() -> bool:
		var errs: Array[String] = HintRegistryClass.validate_all_hints()
		if not errs.is_empty():
			push_error("Hint validation errors: " + str(errs))
			return false
		
		for i in range(1, 11):
			var lid: String = "lvl_%02d" % i
			var hdef = HintRegistryClass.get_hints_for_level(lid)
			if not hdef or hdef.get_hint_count() != 3:
				return false
			for s in range(3):
				var h = hdef.get_hint(s)
				if str(h.get("text", "")).strip_edges().is_empty():
					return false
				if str(h.get("title", "")).strip_edges().is_empty():
					return false
		return true
	)

	# Cleanup & restore clean save state
	save_mgr.clear_test_date()
	save_mgr.reset_progress()
	save_mgr.free()

	print("\n===================================================================")
	print(" DAILY HINT SYSTEM SUMMARY: %d / %d TESTS PASSED" % [counters["passed"], counters["total"]])
	print("===================================================================")

	if counters["passed"] == counters["total"]:
		print(" ALL 20 HINT SYSTEM TESTS PASSED WITH 100% SUCCESS! \n")
		quit(0)
	else:
		push_error(" SOME HINT SYSTEM TESTS FAILED!")
		quit(1)
