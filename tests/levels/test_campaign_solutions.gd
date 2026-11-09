extends SceneTree

# Preload classes
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")

func _init() -> void:
	print("\n=======================================================")
	print(" RUNNING TOMORROW'S YOU - 10 CAMPAIGN LEVEL VALIDATION")
	print("=======================================================")

	var total_levels: int = 10
	var verified_levels: int = 0

	for i in range(total_levels):
		var lvl: LevelDefinition = LevelRegistryClass.get_level(i)
		print("\n--- VALIDATING LEVEL %d: %s (ID: %s, Sector %d) ---" % [i + 1, lvl.level_name, lvl.level_id, lvl.sector])

		# 1. Structural validation
		var errors: Array[String] = lvl.validate()
		if not errors.is_empty():
			push_error("Level %d structural validation failed: %s" % [i + 1, str(errors)])
			continue
		print("  [✓] Structural integrity valid (Spawn: %s, Exit: %s, Dimensions: %dx%d)" % [
			str(lvl.spawn_pos), str(lvl.exit_pos), lvl.grid_width, lvl.grid_height
		])

		# 2. Gameplay solution execution
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		var solved: bool = _solve_level(i, sim)

		if solved and sim.is_completed:
			verified_levels += 1
			print("  [✓] Gameplay solution verified! Completed in %d actions, %d echoes used (Expected min: %d)." % [
				sim.total_actions_taken, sim.echoes.size(), lvl.min_echoes_required
			])
		else:
			push_error("  [✗] Level %d solution failed to complete! (Player pos: %s, Exit: %s)" % [
				i + 1, str(sim.player_pos), str(lvl.exit_pos)
			])

	print("\n=======================================================")
	print(" CAMPAIGN VALIDATION SUMMARY: %d / %d LEVELS SOLVED" % [verified_levels, total_levels])
	print("=======================================================")

	if verified_levels == total_levels:
		print(" ALL 10 CAMPAIGN PUZZLES FULLY VERIFIED AND SOLVABLE! ")
		quit(0)
	else:
		push_error(" SOME CAMPAIGN PUZZLES FAILED!")
		quit(1)

func _solve_level(idx: int, sim: PuzzleSimulation) -> bool:
	match idx:
		0: return _solve_lvl_01(sim)
		1: return _solve_lvl_02(sim)
		2: return _solve_lvl_03(sim)
		3: return _solve_lvl_04(sim)
		4: return _solve_lvl_05(sim)
		5: return _solve_lvl_06(sim)
		6: return _solve_lvl_07(sim)
		7: return _solve_lvl_08(sim)
		8: return _solve_lvl_09(sim)
		9: return _solve_lvl_10(sim)
	return false

func _run_actions(sim: PuzzleSimulation, actions: String) -> void:
	for i in range(actions.length()):
		var ch: String = actions[i]
		match ch:
			"U": sim.step_move(Vector2i.UP)
			"D": sim.step_move(Vector2i.DOWN)
			"L": sim.step_move(Vector2i.LEFT)
			"R": sim.step_move(Vector2i.RIGHT)
			"W": sim.step_wait()
			" ": pass

# ------------------------------------------------------------------------------
# LEVEL 1: First Contact (Sector 1, Min 1 Echo)
# ------------------------------------------------------------------------------
func _solve_lvl_01(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "DDD")
	sim.create_echo()
	_run_actions(sim, "RRRDDDRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 2: Stay Behind (Sector 1, Min 1 Echo)
# ------------------------------------------------------------------------------
func _solve_lvl_02(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "DDDD")
	sim.create_echo()
	_run_actions(sim, "RRRDDRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 3: Double Perspective (Sector 1, Min 1 Echo)
# ------------------------------------------------------------------------------
func _solve_lvl_03(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRRRRR")
	sim.create_echo()
	_run_actions(sim, "RRRDWWDD RRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 4: Sequential Relay (Sector 2, Min 2 Echoes)
# ------------------------------------------------------------------------------
func _solve_lvl_04(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RR")
	sim.create_echo()
	_run_actions(sim, "DRRRRURR")
	sim.create_echo()
	_run_actions(sim, "DRRRRDD W LLLD")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 5: Split Decision (Sector 2, Min 2 Echoes, AND Door A)
# ------------------------------------------------------------------------------
func _solve_lvl_05(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "LLLUU")
	sim.create_echo()
	_run_actions(sim, "RRRUU")
	sim.create_echo()
	_run_actions(sim, "WWWWW DD")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 6: Crossed Signals (Sector 2, Min 2 Echoes)
# ------------------------------------------------------------------------------
func _solve_lvl_06(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "DD")
	sim.create_echo()
	_run_actions(sim, "DRRRRRURR")
	sim.create_echo()
	_run_actions(sim, "DRRRRRDDDRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 7: No Turning Back (Sector 2, Min 2 Echoes, AND Door B)
# ------------------------------------------------------------------------------
func _solve_lvl_07(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRR")
	sim.create_echo()
	_run_actions(sim, "DRRRRRURR")
	sim.create_echo()
	_run_actions(sim, "DRRRRRDDDRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 8: Temporal Interlock (Sector 3, Min 3 Echoes)
# ------------------------------------------------------------------------------
func _solve_lvl_08(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRR")
	sim.create_echo()
	_run_actions(sim, "RRRRDDRRR")
	sim.create_echo()
	_run_actions(sim, "RRRRDD WWW D DLLL")
	sim.create_echo()
	_run_actions(sim, "RRRRDD WWW DD WWW DD")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 9: Parallel Existence (Sector 3, Min 3 Echoes, Cumulative AND Matrix)
# ------------------------------------------------------------------------------
func _solve_lvl_09(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRR")
	sim.create_echo()
	_run_actions(sim, "RRRRDDRRR")
	sim.create_echo()
	_run_actions(sim, "RRRRDD WWW D DLLL")
	sim.create_echo()
	_run_actions(sim, "RRRRDD WWW DD WWW DD")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 10: The Last Tomorrow (Sector 3, Min 3 Echoes, 4-Quadrant Synchronization)
# ------------------------------------------------------------------------------
func _solve_lvl_10(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "DR")
	sim.create_echo()
	_run_actions(sim, "DRRRRRURRR")
	sim.create_echo()
	_run_actions(sim, "DRRRRRDWWWWDDDRR")
	sim.create_echo()
	_run_actions(sim, "DRRRRRDWWWWDDD WW LLDL")
	return sim.is_completed
