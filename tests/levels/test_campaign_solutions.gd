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
			print("  [✓] Gameplay solution verified! Completed in %d actions, %d echoes used." % [
				sim.total_actions_taken, sim.echoes.size()
			])
		else:
			push_error("  [✗] Level %d solution failed to complete!" % [i + 1])

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
# LEVEL 1: First Steps (Basic navigation)
# ------------------------------------------------------------------------------
func _solve_lvl_01(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRRRDDDDR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 2: Temporal Twin (1 Echo on Plate 1)
# ------------------------------------------------------------------------------
func _solve_lvl_02(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "DDR")
	sim.create_echo()
	_run_actions(sim, "RRRDDRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 3: Relay Run (Echo travel timing)
# ------------------------------------------------------------------------------
func _solve_lvl_03(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "DDD")
	sim.create_echo()
	_run_actions(sim, "RRRRRRDDRD")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 4: Dual Lock (2 Echoes for AND Door A)
# ------------------------------------------------------------------------------
func _solve_lvl_04(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "DD")
	sim.create_echo()
	_run_actions(sim, "RRRRRRDD")
	sim.create_echo()
	_run_actions(sim, "RRRDDWWWDDD")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 5: Sequential Relay (Staggered gate relay)
# ------------------------------------------------------------------------------
func _solve_lvl_05(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRRRR")
	sim.create_echo()
	_run_actions(sim, "DDRWWRDL")
	sim.create_echo()
	_run_actions(sim, "DDDDDRRWRRRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 6: The Standoff (WAIT action coordination)
# ------------------------------------------------------------------------------
func _solve_lvl_06(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRRRRRR")
	sim.create_echo()
	_run_actions(sim, "DDRRWWWRRRRR")
	sim.create_echo()
	_run_actions(sim, "DDDDRRWWWWWW RRRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 7: Logic Divergence (OR & AND doors)
# ------------------------------------------------------------------------------
func _solve_lvl_07(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRRRR")
	sim.create_echo()
	_run_actions(sim, "DDRRWRRDR")
	sim.create_echo()
	_run_actions(sim, "DDDDRRWWW RRRRRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 8: Triad Coordination (3 Echoes)
# ------------------------------------------------------------------------------
func _solve_lvl_08(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRR")
	sim.create_echo()
	_run_actions(sim, "DDRRWRRUURRR")
	sim.create_echo()
	_run_actions(sim, "DDRRWRRRRWWWRRRRR")
	sim.create_echo()
	_run_actions(sim, "DDDDRRRRWWWWWWWWW RRRRRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 9: Temporal Interlock (Chained gates)
# ------------------------------------------------------------------------------
func _solve_lvl_09(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRRRR")
	sim.create_echo()
	_run_actions(sim, "DDRRWW RRRRR")
	sim.create_echo()
	_run_actions(sim, "DDDDRRWWWWW RRRRR")
	sim.create_echo()
	_run_actions(sim, "DDDDDDRRWWWWWWWW RRRRR")
	return sim.is_completed

# ------------------------------------------------------------------------------
# LEVEL 10: Tomorrow's You (Grand Finale)
# ------------------------------------------------------------------------------
func _solve_lvl_10(sim: PuzzleSimulation) -> bool:
	_run_actions(sim, "RRRRRRR")
	sim.create_echo()
	_run_actions(sim, "DDRRWWWRRRRR")
	sim.create_echo()
	_run_actions(sim, "DDDDRRWWWWWWRRRRR")
	sim.create_echo()
	_run_actions(sim, "DDDDDDRRWWWW RRRR DD W RRRRR")
	return sim.is_completed
