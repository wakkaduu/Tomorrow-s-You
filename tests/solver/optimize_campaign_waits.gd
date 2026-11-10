extends SceneTree
const Solver = preload("res://scripts/solver/campaign_wait_solver.gd")
const Registry = preload("res://scripts/level/level_registry.gd")
const Validator = preload("res://scripts/level/level_validator.gd")
const OUTPUT: String = "res://tests/fixtures/wait_solver_results.json"
func _init() -> void:
	var previous: Dictionary = {}
	if FileAccess.file_exists(OUTPUT):
		var old = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT))
		if old is Array:
			for entry: Dictionary in old: previous[entry.level_id] = entry.get("previous_wait", -1)
	var results: Array = []
	var valid: bool = true
	# Sequential Relay is intentionally investigated first.
	for i in [3, 0, 1, 2, 4, 5, 6, 7, 8, 9]:
		var solver = Solver.new()
		var level = Registry.get_level(i)
		print("SOLVING ", level.level_id)
		var result: Dictionary = solver.solve(level)
		result["previous_wait"] = previous.get(level.level_id, level.max_wait_actions)
		result["proof_scope"] = "BOUNDED intended shortest-route domain; not an unrestricted minimum"
		if result.status == "BOUNDED_EXACT":
			var attempts: Array = []
			var actions: Array = []
			for action in result.actions:
				if action == "ECHO":
					attempts.append(_attempt(actions, "Echo %d" % (attempts.size() + 1)))
					actions = []
				else: actions.append(action)
			attempts.append(_attempt(actions, "Player"))
			result["attempts"] = attempts
			var replay_level: LevelDefinition = level.duplicate(true)
			replay_level.initialize_from_map()
			replay_level.max_wait_actions = result.minimum_wait
			var replay: Dictionary = Validator._replay_solution(replay_level, result.actions, result.action_bound)
			result["verification"] = replay
			valid = valid and replay.get("completed", false)
		else: valid = false
		results.append(result)
		results.sort_custom(func(a, b): return str(a.level_id) < str(b.level_id))
		var output = FileAccess.open(OUTPUT, FileAccess.WRITE)
		output.store_string(JSON.stringify(results, "\t") + "\n")
		output.close()
		print("SOLVER RESULT %s: status=%s wait=%s actions=%s states=%s" % [level.level_id, result.status, result.minimum_wait, result.total_actions, result.states_explored])
	quit(0 if valid else 1)

func _attempt(actions: Array, role: String) -> Dictionary:
	return {"role": role, "actions": actions.duplicate(), "wait_actions": actions.count("W"), "accepted_actions": actions.size()}
