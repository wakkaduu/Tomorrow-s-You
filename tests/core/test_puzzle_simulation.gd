extends SceneTree

func _init() -> void:
	print("\n==========================================")
	print(" RUNNING TOMORROW'S YOU - CORE SIMULATION TESTS")
	print("==========================================")

	var counters: Dictionary = {"total": 0, "passed": 0}

	var run_test = func(test_name: String, test_callable: Callable) -> void:
		counters["total"] += 1
		print("\n[TEST %d] %s" % [counters["total"], test_name])
		var result: bool = test_callable.call()
		if result:
			counters["passed"] += 1
			print("  --> PASSED")
		else:
			push_error("  --> FAILED: " + test_name)

	# Helper to create a test level
	var make_test_level = func(lines: Array, doors: Array, plates: Array, limit: int = 3) -> LevelDefinition:
		var lvl: LevelDefinition = LevelDefinition.new()
		lvl.level_id = "test_lvl"
		lvl.level_name = "Test Level"
		lvl.echo_limit = limit
		var typed_lines: Array[String] = []
		for l in lines:
			typed_lines.append(str(l))
		lvl.map_lines = typed_lines

		var typed_doors: Array[Dictionary] = []
		for d in doors:
			if d is Dictionary:
				typed_doors.append(d)
		lvl.doors_data = typed_doors

		var typed_plates: Array[Dictionary] = []
		for p in plates:
			if p is Dictionary:
				typed_plates.append(p)
		lvl.plates_data = typed_plates

		var ok: bool = lvl.initialize_from_map()
		if not ok:
			printerr("Level validation failed: ", lvl.validate())
		return lvl

	# -------------------------------------------------------------------------
	# TEST 1: Basic Movement in All Directions
	# -------------------------------------------------------------------------
	run_test.call("Movement in all 4 directions & turn count", func() -> bool:
		var lvl = make_test_level.call([
			"#####",
			"#...#",
			"#.P.#",
			"#...#",
			"###X#"
		], [], [])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		assert(sim.player_pos == Vector2i(2, 2))
		assert(sim.current_turn == 0)

		# Move UP
		var ok = sim.step_move(Vector2i.UP)
		if not ok or sim.player_pos != Vector2i(2, 1) or sim.current_turn != 1: return false
		# Move LEFT
		ok = sim.step_move(Vector2i.LEFT)
		if not ok or sim.player_pos != Vector2i(1, 1) or sim.current_turn != 2: return false
		# Move DOWN
		ok = sim.step_move(Vector2i.DOWN)
		if not ok or sim.player_pos != Vector2i(1, 2) or sim.current_turn != 3: return false
		# Move RIGHT
		ok = sim.step_move(Vector2i.RIGHT)
		if not ok or sim.player_pos != Vector2i(2, 2) or sim.current_turn != 4: return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 2: Movement Blocked by Walls Does Not Consume Turns
	# -------------------------------------------------------------------------
	run_test.call("Wall collision does not advance turn", func() -> bool:
		var lvl = make_test_level.call([
			"###",
			"#P#",
			"#X#"
		], [], [])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Attempt move UP into wall (0, -1)
		var blocked = not sim.step_move(Vector2i.UP)
		if not blocked or sim.player_pos != Vector2i(1, 1) or sim.current_turn != 0: return false

		# Attempt move LEFT into wall
		blocked = not sim.step_move(Vector2i.LEFT)
		if not blocked or sim.player_pos != Vector2i(1, 1) or sim.current_turn != 0: return false

		# Attempt move RIGHT into wall
		blocked = not sim.step_move(Vector2i.RIGHT)
		if not blocked or sim.player_pos != Vector2i(1, 1) or sim.current_turn != 0: return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 3: WAIT Action Consumes Turn Without Changing Position
	# -------------------------------------------------------------------------
	run_test.call("WAIT advances turn without movement", func() -> bool:
		var lvl = make_test_level.call([
			"###",
			"#P#",
			"#X#"
		], [], [])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		var ok = sim.step_wait()
		if not ok or sim.player_pos != Vector2i(1, 1) or sim.current_turn != 1: return false

		ok = sim.step_wait()
		if not ok or sim.player_pos != Vector2i(1, 1) or sim.current_turn != 2: return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 4: Echo Creation and Playback Synchronization
	# -------------------------------------------------------------------------
	run_test.call("Echo recording and synchronous replay", func() -> bool:
		var lvl = make_test_level.call([
			"#####",
			"#P..#",
			"#...#",
			"####X"
		], [], [])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Attempt 1: Player moves RIGHT twice, then DOWN
		sim.step_move(Vector2i.RIGHT) # (2, 1)
		sim.step_move(Vector2i.RIGHT) # (3, 1)
		sim.step_move(Vector2i.DOWN)  # (3, 2)
		assert(sim.player_pos == Vector2i(3, 2))
		assert(sim.current_turn == 3)

		# Create Echo
		var created = sim.create_echo()
		if not created or sim.echoes.size() != 1: return false
		if sim.player_pos != Vector2i(1, 1) or sim.current_turn != 0: return false

		# Check Echo starts at spawn
		if sim.get_echo_position(0) != Vector2i(1, 1): return false

		# Attempt 2: Player waits, Echo should move according to recording
		sim.step_wait() # Turn 1
		if sim.get_echo_position(0) != Vector2i(2, 1): return false

		sim.step_wait() # Turn 2
		if sim.get_echo_position(0) != Vector2i(3, 1): return false

		sim.step_wait() # Turn 3
		if sim.get_echo_position(0) != Vector2i(3, 2): return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 5: Echo Remains at Final Position Indefinitely
	# -------------------------------------------------------------------------
	run_test.call("Finished Echo remains at final tile indefinitely", func() -> bool:
		var lvl = make_test_level.call([
			"#####",
			"#P..#",
			"#...#",
			"####X"
		], [], [])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Make 2 moves, then create Echo
		sim.step_move(Vector2i.RIGHT) # turn 1 -> (2,1)
		sim.step_move(Vector2i.RIGHT) # turn 2 -> (3,1)
		sim.create_echo()

		# Echo had 2 steps. Advance 5 turns in next attempt:
		sim.step_wait() # turn 1 -> echo at (2,1)
		sim.step_wait() # turn 2 -> echo at (3,1)
		sim.step_wait() # turn 3 -> echo STILL at (3,1)
		if sim.get_echo_position(0) != Vector2i(3, 1): return false
		sim.step_wait() # turn 4 -> echo STILL at (3,1)
		if sim.get_echo_position(0) != Vector2i(3, 1): return false
		sim.step_wait() # turn 5 -> echo STILL at (3,1)
		if sim.get_echo_position(0) != Vector2i(3, 1): return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 6: Echo Activates Pressure Plate and Opens Single Door
	# -------------------------------------------------------------------------
	run_test.call("Echo holds pressure plate to open single door", func() -> bool:
		var lvl = make_test_level.call([
			"#######",
			"#P.1.A#",
			"#####X#"
		], [
			{"id": "A", "pos": Vector2i(5, 1), "logic": "AND", "required_plates": ["1"]}
		], [
			{"id": "1", "pos": Vector2i(3, 1)}
		])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Door A initially closed
		if sim.is_door_open("A"): return false

		# Attempt 1: Walk to plate (3,1)
		sim.step_move(Vector2i.RIGHT) # (2, 1)
		sim.step_move(Vector2i.RIGHT) # (3, 1) -> plate pressed!
		if not sim.is_plate_active("1") or not sim.is_door_open("A"): return false

		# Create Echo (Echo will walk to plate and stay there!)
		sim.create_echo()
		# At turn 0, door is closed again
		if sim.is_door_open("A"): return false

		# Attempt 2: Player waits while Echo reaches plate
		sim.step_wait() # turn 1: Echo at (2,1) -> door still closed
		if sim.is_door_open("A"): return false

		sim.step_wait() # turn 2: Echo reaches (3,1) -> plate active -> Door A OPENS!
		if not sim.is_plate_active("1") or not sim.is_door_open("A"): return false

		# Turn 3: Echo stays on plate, Door A remains OPEN!
		sim.step_wait()
		if not sim.is_door_open("A"): return false

		# Player can now walk through Door A!
		sim.step_move(Vector2i.RIGHT) # (2,1)
		sim.step_move(Vector2i.RIGHT) # (3,1) (sharing tile with echo)
		sim.step_move(Vector2i.RIGHT) # (4,1)
		var walked_through = sim.step_move(Vector2i.RIGHT) # (5,1) Door tile
		if not walked_through or sim.player_pos != Vector2i(5, 1): return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 7: AND Logic Door (Requires Both Plates Active)
	# -------------------------------------------------------------------------
	run_test.call("AND logic door requires all specified plates active", func() -> bool:
		var lvl = make_test_level.call([
			"#######",
			"#P.1.2#",
			"####.A#",
			"#####X#"
		], [
			{"id": "A", "pos": Vector2i(5, 2), "logic": "AND", "required_plates": ["1", "2"]}
		], [
			{"id": "1", "pos": Vector2i(3, 1)},
			{"id": "2", "pos": Vector2i(5, 1)}
		])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Plate 1 pressed only -> Door A closed
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT) # At Plate 1 (3, 1)
		if not sim.is_plate_active("1") or sim.is_plate_active("2") or sim.is_door_open("A"): return false

		# Create Echo 1 (holds plate 1)
		sim.create_echo()

		# Attempt 2: Echo 1 goes to plate 1. Player goes to plate 2 (5, 1)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT) # At Plate 2 (5, 1)
		# Now Echo 1 is on Plate 1 AND Player is on Plate 2 -> Door A should be OPEN!
		if not sim.is_plate_active("1") or not sim.is_plate_active("2") or not sim.is_door_open("A"): return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 8: OR Logic Door (Requires Either Plate Active)
	# -------------------------------------------------------------------------
	run_test.call("OR logic door opens if at least one plate active", func() -> bool:
		var lvl = make_test_level.call([
			"#######",
			"#P.1.2#",
			"####.A#",
			"#####X#"
		], [
			{"id": "A", "pos": Vector2i(5, 2), "logic": "OR", "required_plates": ["1", "2"]}
		], [
			{"id": "1", "pos": Vector2i(3, 1)},
			{"id": "2", "pos": Vector2i(5, 1)}
		])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		if sim.is_door_open("A"): return false

		# Move to Plate 1 -> OR door opens immediately
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		if not sim.is_plate_active("1") or not sim.is_door_open("A"): return false

		# Move off Plate 1 towards (4, 1) -> OR door closes
		sim.step_move(Vector2i.RIGHT)
		if sim.is_door_open("A"): return false

		# Move onto Plate 2 -> OR door opens again
		sim.step_move(Vector2i.RIGHT)
		if not sim.is_plate_active("2") or not sim.is_door_open("A"): return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 9: Door Safety Rule (Never close on real player standing in door)
	# -------------------------------------------------------------------------
	run_test.call("Safety rule: Door remains open while player stands on it", func() -> bool:
		var lvl = make_test_level.call([
			"#######",
			"#P.1.A#",
			"#####X#"
		], [
			{"id": "A", "pos": Vector2i(5, 1), "logic": "AND", "required_plates": ["1"]}
		], [
			{"id": "1", "pos": Vector2i(3, 1)}
		])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Player steps on plate 1, then steps off plate 1 towards door A
		# Attempt 1: Make Echo hold plate 1 for 4 turns, then walk away!
		sim.step_move(Vector2i.RIGHT) # (2,1)
		sim.step_move(Vector2i.RIGHT) # (3,1) plate 1
		sim.step_wait()              # turn 3 on plate
		sim.step_wait()              # turn 4 on plate
		sim.step_move(Vector2i.LEFT)  # turn 5 moves OFF plate!
		sim.create_echo()

		# Attempt 2: Player rushes to door while Echo is on plate, then Echo leaves
		sim.step_move(Vector2i.RIGHT) # turn 1 (2,1)
		sim.step_move(Vector2i.RIGHT) # turn 2 (3,1)
		sim.step_move(Vector2i.RIGHT) # turn 3 (4,1)
		sim.step_move(Vector2i.RIGHT) # turn 4 (5,1) Inside Door A!
		if not sim.is_door_open("A"): return false

		# Turn 5: Echo leaves plate 1 (plate 1 deactivated).
		# BUT player is standing on Door A! Door A MUST STAY OPEN!
		sim.step_wait()
		if sim.is_plate_active("1"): return false # Plate deactivated
		if not sim.is_door_open("A"): return false # Door kept open by safety rule!

		# Player can now safely step out of door to exit (5, 2)
		var exited = sim.step_move(Vector2i.DOWN)
		if not exited or sim.player_pos != Vector2i(5, 2): return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 10: Echo Reaching Exit Does NOT Complete Level (Real Player Only)
	# -------------------------------------------------------------------------
	run_test.call("Echo reaching exit does NOT trigger level completion", func() -> bool:
		var lvl = make_test_level.call([
			"###",
			"#P#",
			"#.#",
			"#X#"
		], [], [])
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Attempt 1: Player walks to (1, 2)
		sim.step_move(Vector2i.DOWN)
		sim.create_echo()

		# Attempt 2: Player waits. Echo moves to (1, 2).
		sim.step_wait()
		if sim.is_completed: return false # Level not complete

		# Only real player reaching (1, 3) completes level
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.DOWN)
		if not sim.is_completed: return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 11: Multiple Simultaneous Echoes
	# -------------------------------------------------------------------------
	run_test.call("Multiple simultaneous Echoes coordination", func() -> bool:
		var lvl = make_test_level.call([
			"#######",
			"#P....#",
			"#1.2.3#",
			"####..#",
			"#####X#"
		], [], [
			{"id": "1", "pos": Vector2i(1, 2)},
			{"id": "2", "pos": Vector2i(3, 2)},
			{"id": "3", "pos": Vector2i(5, 2)}
		], 3)
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Echo 1: walks to Plate 1
		sim.step_move(Vector2i.DOWN) # (1, 2)
		sim.create_echo()
		if sim.echoes.size() != 1: return false

		# Echo 2: walks to Plate 2
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.DOWN) # (3, 2)
		sim.create_echo()
		if sim.echoes.size() != 2: return false

		# Now in Attempt 3: Echo 1 and Echo 2 are playing simultaneously!
		# Turn 1: Echo 1 is at (1, 2); Echo 2 is at (2, 1)
		sim.step_wait()
		if not sim.is_plate_active("1") or sim.is_plate_active("2"): return false

		# Turn 2: Echo 1 stays at (1, 2); Echo 2 is at (3, 1)
		sim.step_wait()
		# Turn 3: Echo 2 arrives at (3, 2)
		sim.step_wait()
		if not sim.is_plate_active("1") or not sim.is_plate_active("2"): return false

		# Player now steps to Plate 3 (5, 2)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.DOWN) # (5, 2) Plate 3!
		# All 3 plates active!
		if not sim.is_plate_active("1") or not sim.is_plate_active("2") or not sim.is_plate_active("3"):
			return false

		return true
	)

	# -------------------------------------------------------------------------
	# TEST 12: Echo Limit Enforcement & Clear Echoes
	# -------------------------------------------------------------------------
	run_test.call("Echo limit enforcement and Clear Echoes", func() -> bool:
		var lvl = make_test_level.call([
			"#####",
			"#P..#",
			"###X#"
		], [], [], 2) # Limit = 2
		var sim: PuzzleSimulation = PuzzleSimulation.new()
		sim.load_level(lvl)

		# Create Echo 1
		sim.step_move(Vector2i.RIGHT)
		var c1 = sim.create_echo()
		if not c1 or sim.echoes.size() != 1: return false

		# Create Echo 2
		sim.step_move(Vector2i.RIGHT)
		var c2 = sim.create_echo()
		if not c2 or sim.echoes.size() != 2: return false

		# Attempt Create Echo 3 -> should fail due to limit
		sim.step_move(Vector2i.RIGHT)
		var c3 = sim.create_echo()
		if c3 or sim.echoes.size() != 2: return false

		# Clear Echoes
		sim.clear_echoes()
		if sim.echoes.size() != 0 or sim.player_pos != Vector2i(1, 1) or sim.current_turn != 0: return false

		return true
	)

	# -------------------------------------------------------------------------
	# RESULTS SUMMARY
	# -------------------------------------------------------------------------
	print("\n==========================================")
	print(" CORE TEST SUMMARY: %d / %d PASSED" % [counters["passed"], counters["total"]])
	print("==========================================")

	if counters["passed"] == counters["total"]:
		print(" ALL CORE TESTS PASSED SUCCESSFULLY! ")
		quit(0)
	else:
		push_error(" TESTS FAILED!")
		quit(1)
