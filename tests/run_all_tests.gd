extends SceneTree

# Preloads
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")

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
	var run_actions = func(sim: PuzzleSimulation, actions: String) -> void:
		for i in range(actions.length()):
			var ch: String = actions[i]
			match ch:
				"U": sim.step_move(Vector2i.UP)
				"D": sim.step_move(Vector2i.DOWN)
				"L": sim.step_move(Vector2i.LEFT)
				"R": sim.step_move(Vector2i.RIGHT)
				"W": sim.step_wait()
				" ": pass

	var campaign_solvers = [
		# Level 1: First Contact (Sector 1, Min 1 Echo)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "DDDWWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRDDDRR")
			return sim.is_completed,
		# Level 2: Stay Behind (Sector 1, Min 1 Echo)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "DDDDWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRDDRRR")
			return sim.is_completed,
		# Level 3: Double Perspective (Sector 1, Min 1 Echo)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "RRRRRRWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRDWWDD RRR")
			return sim.is_completed,
		# Level 4: Sequential Relay (Sector 2, Min 2 Echoes)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "RRWWWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRURRWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRDD W LLLD")
			return sim.is_completed,
		# Level 5: Split Decision (Sector 2, Min 2 Echoes)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "LLLUUWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRUUWWWW")
			sim.create_echo()
			run_actions.call(sim, "WWWWW DD")
			return sim.is_completed,
		# Level 6: Crossed Signals (Sector 2, Min 2 Echoes)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "DDWWWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRRURRWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRRDDDRRR")
			return sim.is_completed,
		# Level 7: No Turning Back (Sector 2, Min 2 Echoes)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "RRRWWWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRRURRWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRRDDDRRR")
			return sim.is_completed,
		# Level 8: Temporal Interlock (Sector 3, Min 3 Echoes)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "RRRWWWWWWWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRRDDRRRWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRRDD WWW D DLLL WWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRRDD WWW DD WWW DD")
			return sim.is_completed,
		# Level 9: Parallel Existence (Sector 3, Min 3 Echoes)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "RRRWWWWWWWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRRDDRRRWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRRDD WWW D DLLL WWWW")
			sim.create_echo()
			run_actions.call(sim, "RRRRDD WWW DD WWW DD")
			return sim.is_completed,
		# Level 10: The Last Tomorrow (Sector 3, Min 3 Echoes)
		func(sim: PuzzleSimulation) -> bool:
			run_actions.call(sim, "DRWWWWWWWWWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRRURRRWWWWWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRRDWWWWDDDRRWWWW")
			sim.create_echo()
			run_actions.call(sim, "DRRRRRDWWWWDDD WW LLDL")
			return sim.is_completed
	]

	for i in range(10):
		var lvl: LevelDefinition = LevelRegistryClass.get_level(i)
		run_test.call("CAMPAIGN", "Level %d: %s (Sector %d)" % [i + 1, lvl.level_name, lvl.sector], func() -> bool:
			var sim: PuzzleSimulation = PuzzleSimulationClass.new()
			sim.load_level(lvl)
			var solver: Callable = campaign_solvers[i]
			return solver.call(sim)
		)

	# ==========================================================================
	# SECTION 3: AUTOMATED LEVEL VALIDATION (ZERO-ECHO BYPASS ELIMINATION)
	# ==========================================================================
	var LevelValidatorClass = preload("res://scripts/level/level_validator.gd")
	for i in range(10):
		var lvl: LevelDefinition = LevelRegistryClass.get_level(i)
		run_test.call("VALIDATOR", "Level %d: Zero-Echo bypass blocked & Min %d Echoes enforced" % [i + 1, lvl.min_echoes_required], func() -> bool:
			var res: Dictionary = LevelValidatorClass.validate_level(lvl)
			return res["zero_echo_passed"] and res["sub_min_echoes_passed"]
		)

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

