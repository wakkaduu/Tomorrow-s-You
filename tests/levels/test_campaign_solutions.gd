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
	var solutions = preload("res://scripts/level/campaign_solutions.gd")
	var directions: Dictionary = {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
	for action in solutions.get_actions(sim.level_def.level_id):
		var accepted: bool = false
		if action == "ECHO": accepted = sim.create_echo()
		elif action == "W": accepted = sim.step_wait()
		else: accepted = sim.step_move(directions[action])
		if not accepted:
			push_error("Verified solution action rejected: %s at %d" % [action, sim.current_turn])
			return false
	return sim.is_completed and sim.echoes.size() == sim.level_def.min_echoes_required and sim.get_wait_actions_used() == sim.level_def.max_wait_actions and sim.total_actions_taken <= sim.level_def.target_3_stars
