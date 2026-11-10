extends SceneTree
const Solver = preload("res://scripts/solver/campaign_wait_solver.gd")
const Registry = preload("res://scripts/level/level_registry.gd")
func _init() -> void:
	var results: Array = []
	for i in [3, 0, 1, 2, 4, 5, 6, 7, 8, 9]:
		var solver = Solver.new()
		solver.movement_slack = 2 if i == 3 else 4
		solver.stop_after_first = i != 3
		solver.max_msec = 20000
		solver.max_states = 300000
		var level = Registry.get_level(i)
		print("PADDING PROBE ", level.level_id)
		var result: Dictionary = solver.solve(level, 0)
		# This is a witness search only; no global completeness claim.
		result["status"] = "PADDING_WITNESS" if not result.actions.is_empty() else "INCONCLUSIVE_GLOBAL"
		results.append(result)
		var output = FileAccess.open("res://tests/fixtures/wait_padding_results.json", FileAccess.WRITE)
		output.store_string(JSON.stringify(results, "\t"))
		output.close()
		print("PADDING RESULT ", JSON.stringify(result))
	quit()
