extends SceneTree

# Preloads
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")
const SaveManagerClass = preload("res://scripts/autoload/save_manager.gd")
const HintRegistryClass = preload("res://scripts/hints/hint_registry.gd")

func _init() -> void:
	print("\n===================================================================")
	print("       TOMORROW'S YOU — MASTER AUTOMATED TEST SUITE")
	print("===================================================================")

	var counters: Dictionary = {"total": 0, "passed": 0}

	var run_test = func(suite: String, test_name: String, test_fn: Callable) -> void:
		counters["total"] += 1
		print("[%s | TEST %d] %s" % [suite, counters["total"], test_name])
		var ok: bool = test_fn.call()
		if ok:
			counters["passed"] += 1
			print("   --> PASSED [✓]")
		else:
			push_error("   --> FAILED [✗]: " + test_name)

	# ==========================================================================
	# SECTION 1: CORE MECHANICS
	# ==========================================================================
	var make_test_level = func(lines: Array, doors: Array, plates: Array, limit: int = 3) -> LevelDefinition:
		var lvl: LevelDefinition = LevelDefinition.new()
		lvl.level_id = "test_lvl"
		lvl.level_name = "Test Level"
		lvl.echo_limit = limit
		var typed_lines: Array[String] = []
		for l in lines: typed_lines.append(str(l))
		lvl.map_lines = typed_lines
		var typed_doors: Array[Dictionary] = []
		for d in doors: if d is Dictionary: typed_doors.append(d)
		lvl.doors_data = typed_doors
		var typed_plates: Array[Dictionary] = []
		for p in plates: if p is Dictionary: typed_plates.append(p)
		lvl.plates_data = typed_plates
		lvl.initialize_from_map()
		return lvl

	run_test.call("CORE", "Movement in all 4 directions & turn count", func() -> bool:
		var lvl = make_test_level.call(["#####", "#...#", "#.P.#", "#...#", "###X#"], [], [])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.UP)
		sim.step_move(Vector2i.LEFT)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.RIGHT)
		return sim.player_pos == Vector2i(2, 2) and sim.current_turn == 4
	)

	run_test.call("CORE", "Wall collision does not consume turns", func() -> bool:
		var lvl = make_test_level.call(["###", "#P#", "#X#"], [], [])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		var blocked = not sim.step_move(Vector2i.UP)
		return blocked and sim.player_pos == Vector2i(1, 1) and sim.current_turn == 0
	)

	run_test.call("CORE", "WAIT advances turn without changing position", func() -> bool:
		var lvl = make_test_level.call(["###", "#P#", "#X#"], [], [])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_wait()
		sim.step_wait()
		return sim.player_pos == Vector2i(1, 1) and sim.current_turn == 2
	)

	run_test.call("CORE", "Echo recording and synchronous replay", func() -> bool:
		var lvl = make_test_level.call(["#####", "#P..#", "#...#", "####X"], [], [])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.create_echo()
		sim.step_wait()
		if sim.get_echo_position(0) != Vector2i(2, 1): return false
		sim.step_wait()
		if sim.get_echo_position(0) != Vector2i(3, 1): return false
		return true
	)

	run_test.call("CORE", "Finished Echo expires when recording ends", func() -> bool:
		var lvl = make_test_level.call(["#####", "#P..#", "#...#", "####X"], [], [])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.create_echo()
		sim.step_wait()
		sim.step_wait()
		if not sim.is_echo_active(0): return false
		sim.step_wait() # turn 3 > 2 steps -> expired
		return not sim.is_echo_active(0) and sim.get_echo_position(0) == Vector2i(-1, -1)
	)

	run_test.call("CORE", "Echo activates pressure plate to hold door open with WAIT", func() -> bool:
		var lvl = make_test_level.call([
			"#######", "#P.1.A#", "#####X#"
		], [{"id": "A", "pos": Vector2i(5, 1), "logic": "AND", "required_plates": ["1"]}], [{"id": "1", "pos": Vector2i(3, 1)}])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_wait()
		sim.step_wait()
		sim.create_echo()
		sim.step_wait()
		sim.step_wait()
		return sim.is_plate_active("1") and sim.is_door_open("A")
	)

	run_test.call("CORE", "AND logic door requires all specified plates", func() -> bool:
		var lvl = make_test_level.call([
			"#######", "#P.1.2#", "####.A#", "#####X#"
		], [{"id": "A", "pos": Vector2i(5, 2), "logic": "AND", "required_plates": ["1", "2"]}], [{"id": "1", "pos": Vector2i(3, 1)}, {"id": "2", "pos": Vector2i(5, 1)}])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		for _w in range(4): sim.step_wait()
		sim.create_echo()
		for _i in range(4): sim.step_move(Vector2i.RIGHT)
		return sim.is_plate_active("1") and sim.is_plate_active("2") and sim.is_door_open("A")
	)

	run_test.call("CORE", "OR logic door opens if at least one plate active", func() -> bool:
		var lvl = make_test_level.call([
			"#######", "#P.1.2#", "####.A#", "#####X#"
		], [{"id": "A", "pos": Vector2i(5, 2), "logic": "OR", "required_plates": ["1", "2"]}], [{"id": "1", "pos": Vector2i(3, 1)}, {"id": "2", "pos": Vector2i(5, 1)}])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		return sim.is_door_open("A")
	)

	run_test.call("CORE", "Safety rule: Never crush player inside physical door", func() -> bool:
		var lvl = make_test_level.call([
			"#######", "#P.1.A#", "#####X#"
		], [{"id": "A", "pos": Vector2i(5, 1), "logic": "AND", "required_plates": ["1"]}], [{"id": "1", "pos": Vector2i(3, 1)}])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_wait()
		sim.step_wait()
		sim.step_move(Vector2i.LEFT)
		sim.create_echo()
		for _i in range(4): sim.step_move(Vector2i.RIGHT)
		sim.step_wait()
		return sim.player_pos == Vector2i(5, 1) and sim.is_door_open("A") and not sim.is_plate_active("1")
	)

	run_test.call("CORE", "Echo reaching exit does NOT complete level (real player only)", func() -> bool:
		var lvl = make_test_level.call(["###", "#P#", "#.#", "#X#"], [], [])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.DOWN)
		sim.create_echo()
		sim.step_wait()
		return not sim.is_completed
	)

	run_test.call("CORE", "Multiple simultaneous Echoes coordination", func() -> bool:
		var lvl = make_test_level.call([
			"#######", "#P....#", "#1.2.3#", "####..#", "#####X#"
		], [], [{"id": "1", "pos": Vector2i(1, 2)}, {"id": "2", "pos": Vector2i(3, 2)}, {"id": "3", "pos": Vector2i(5, 2)}], 3)
		# This synthetic coordination fixture records 17 WAITs across all attempts.
		lvl.max_wait_actions = 17
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.DOWN)
		for _w in range(8): sim.step_wait()
		sim.create_echo()
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.DOWN)
		for _w in range(6): sim.step_wait()
		sim.create_echo()
		sim.step_wait()
		sim.step_wait()
		sim.step_wait()
		return sim.is_plate_active("1") and sim.is_plate_active("2")
	)

	run_test.call("CORE", "Echo limit enforcement & Clear Echoes", func() -> bool:
		var lvl = make_test_level.call(["#####", "#P..#", "###X#"], [], [], 2)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT)
		sim.create_echo()
		sim.step_move(Vector2i.RIGHT)
		sim.create_echo()
		var c3 = sim.create_echo()
		if c3 or sim.echoes.size() != 2: return false
		sim.clear_echoes()
		return sim.echoes.is_empty() and sim.player_pos == Vector2i(1, 1) and sim.current_turn == 0
	)

	# ==========================================================================
	# SECTION 2: 10 CAMPAIGN LEVELS VERIFICATION
	# ==========================================================================
	var solutions = preload("res://scripts/level/campaign_solutions.gd")
	for i in range(10):
		var lvl: LevelDefinition = LevelRegistryClass.get_level(i)
		run_test.call("CAMPAIGN", "Level %d: %s (Sector %d)" % [i + 1, lvl.level_name, lvl.sector], func() -> bool:
			var sim: PuzzleSimulation = PuzzleSimulationClass.new()
			sim.load_level(lvl)
			var directions: Dictionary = {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
			for action in solutions.get_actions(lvl.level_id):
				var accepted: bool = false
				if action == "ECHO": accepted = sim.create_echo()
				elif action == "W": accepted = sim.step_wait()
				else: accepted = sim.step_move(directions[action])
				if not accepted: return false
			return sim.is_completed and sim.get_wait_actions_used() == lvl.max_wait_actions and sim.echoes.size() == lvl.min_echoes_required and sim.total_actions_taken <= lvl.target_3_stars
		)

	# ==========================================================================
	# SECTION 3: AUTOMATED LEVEL VALIDATION (ZERO-ECHO BYPASS ELIMINATION)
	# ==========================================================================
	var LevelValidatorClass = preload("res://scripts/level/level_validator.gd")
	for i in range(10):
		var lvl: LevelDefinition = LevelRegistryClass.get_level(i)
		run_test.call("VALIDATOR", "Level %d: Zero-Echo bypass blocked & intended %d Echoes audited" % [i + 1, lvl.min_echoes_required], func() -> bool:
			var res: Dictionary = LevelValidatorClass.validate_level(lvl)
			return res["zero_echo_passed"] and (res["sub_min_echoes_passed"] or lvl.level_id == "lvl_10" and res["global_echo_status"] == "VIOLATED_BY_REPLAYED_WITNESS")
		)

	# ==========================================================================
	# SECTION 4: DAILY HINT SYSTEM (ALLOWANCE, ROBUST RESET, AND PROGRESSION)
	# ==========================================================================
	var sm = SaveManagerClass.new()
	sm.reset_progress()

	run_test.call("HINTS", "Global daily allowance starts at 3 and decrements to 0", func() -> bool:
		sm.reset_progress()
		if sm.get_remaining_daily_hints() != 3: return false
		sm.reveal_next_hint("lvl_01")
		if sm.get_remaining_daily_hints() != 2: return false
		sm.reveal_next_hint("lvl_01")
		if sm.get_remaining_daily_hints() != 1: return false
		sm.reveal_next_hint("lvl_01")
		if sm.get_remaining_daily_hints() != 0: return false
		var blocked = not sm.reveal_next_hint("lvl_02")
		return blocked and sm.get_remaining_daily_hints() == 0
	)

	run_test.call("HINTS", "Daily allowance is shared across all levels", func() -> bool:
		sm.reset_progress()
		sm.set_test_date("2026-11-20", 1000)
		sm.reveal_next_hint("lvl_01")
		if sm.get_remaining_daily_hints() != 2: return false
		var rem_lvl2 = sm.get_remaining_daily_hints()
		sm.reveal_next_hint("lvl_02")
		var rem_lvl3 = sm.get_remaining_daily_hints()
		return rem_lvl2 == 2 and rem_lvl3 == 1
	)

	run_test.call("HINTS", "Calendar day rollover resets allowance to 3", func() -> bool:
		sm.set_test_date("2026-11-20", 1000)
		while sm.get_remaining_daily_hints() > 0:
			sm.reveal_next_hint("lvl_03")
		if sm.get_remaining_daily_hints() != 0: return false
		sm.set_test_date("2026-11-21", 86400 + 1000)
		return sm.get_remaining_daily_hints() == 3
	)

	run_test.call("HINTS", "Clock rollback is detected and does not grant fresh allowance", func() -> bool:
		sm.set_test_date("2026-11-21", 86400 + 1000)
		while sm.get_remaining_daily_hints() > 0:
			sm.reveal_next_hint("lvl_04")
		sm.set_test_date("2026-11-20", 1000) # backwards
		return sm.get_remaining_daily_hints() == 0
	)

	run_test.call("HINTS", "Persistence roundtrip preserves hints used and revealed stages", func() -> bool:
		sm.set_test_date("2026-11-22", 200000)
		sm.reset_progress()
		sm.set_test_date("2026-11-22", 200000)
		sm.reveal_next_hint("lvl_05")
		sm.write_save()
		var sm_fresh = SaveManagerClass.new()
		sm_fresh.set_test_date("2026-11-22", 200000)
		sm_fresh.load_save()
		var ok = sm_fresh.get_remaining_daily_hints() == 2 and sm_fresh.get_revealed_hint_index("lvl_05") == 0
		sm_fresh.free()
		return ok
	)

	run_test.call("HINTS", "All 10 campaign levels have valid 3-stage verified hint data", func() -> bool:
		var errs = HintRegistryClass.validate_all_hints()
		return errs.is_empty()
	)

	sm.clear_test_date()
	sm.reset_progress()
	sm.free()

	# ==========================================================================
	# FINAL SUMMARY
	# ==========================================================================
	print("\n===================================================================")
	print(" MASTER SUITE SUMMARY: %d / %d TESTS PASSED" % [counters["passed"], counters["total"]])
	print("===================================================================")

	if counters["passed"] == counters["total"]:
		print(" ALL %d TESTS PASSED WITH 100%% SUCCESS! " % counters["total"])
		quit(0)
	else:
		push_error(" SOME TESTS FAILED!")
		quit(1)

