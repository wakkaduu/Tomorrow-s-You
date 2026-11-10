class_name LevelValidator
extends RefCounted

## Automated Level Solvability & Echo-Dependency Validator for Tomorrow's You.
## Verifies that:
## 1. Zero-Echo solutions do NOT exist (Zero-Echo Bypass Test passes).
## 2. Screen for sub-minimum Echo counterexamples (not an exhaustive absence proof).
## 3. The level has a verified solvable path with `min_echoes_required` Echoes.

const CampaignSolutionsClass = preload("res://scripts/level/campaign_solutions.gd")
static var _counterexample_cache: Dictionary = {}

const SolverClass = preload("res://scripts/solver/campaign_wait_solver.gd")
const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")

## Result dictionary returned by validate_level():
## {
##   "level_id": String,
##   "min_echoes_required": int,
##   "zero_echo_passed": bool,       # True if 0 Echoes cannot reach exit
##   "sub_min_echoes_passed": bool,  # True if topology screen and prefix audit found no bypass
##   "solvable_with_min": bool,      # True if min_echoes solves the level
##   "is_valid": bool,               # True if all pass
##   "states_explored_0_echo": int,
##   "log": Array[String],
##   "report": String
## }
static func validate_level(level_def: LevelDefinition, verified_solution: Array = [], action_bound: int = -1, proof: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"level_id": level_def.level_id,
		"level_name": level_def.level_name,
		"min_echoes_required": level_def.min_echoes_required,
		"zero_echo_passed": false,
		"sub_min_echoes_passed": false,
		"solvable_with_min": false,
		"is_valid": false,
		"optimization_valid": false,
		"optimization_status": "INCONCLUSIVE",
		"structural_errors": level_def.validate(),
		"counterexamples": [],
		"intended_solution_valid": false,
		"global_echo_status": "TOPOLOGY_SCREEN_ONLY",
		"states_explored_0_echo": 0,
		"log": [],
		"report": ""
	}

	var report_lines: Array[String] = []
	report_lines.append("===================================================================")
	report_lines.append(" LEVEL VALIDATION REPORT: %s (%s)" % [level_def.level_name.to_upper(), level_def.level_id])
	report_lines.append("===================================================================")
	report_lines.append("Minimum Echo requirement: %d" % level_def.min_echoes_required)
	report_lines.append("Echo capacity limit:      %d" % level_def.echo_limit)
	report_lines.append("Shared WAIT allowance:    %d" % level_def.max_wait_actions)
	report_lines.append("")

	# --------------------------------------------------------------------------
	# 1. ZERO-ECHO BYPASS VALIDATION
	# --------------------------------------------------------------------------
	var zero_echo_search: Dictionary = _search_zero_echo_path(level_def)
	result["states_explored_0_echo"] = zero_echo_search.get("states_explored", 0)

	if zero_echo_search.get("path_found", false):
		report_lines.append("0 Echoes: CRITICAL FAILURE — Bypass found! Exit reachable with 0 Echoes!")
		report_lines.append("          Bypass steps: %s" % [str(zero_echo_search.get("path", []))])
		result["zero_echo_passed"] = false
	else:
		report_lines.append("0 Echoes: FAILED — No solution found. (Explored %d states)" % result["states_explored_0_echo"])
		result["zero_echo_passed"] = zero_echo_search.get("complete", false)

	# --------------------------------------------------------------------------
	# 2. SUB-MINIMUM ECHO VALIDATION (for levels requiring >= 2 echoes)
	# --------------------------------------------------------------------------
	var sub_min_ok: bool = true
	for echo_count in range(1, level_def.min_echoes_required):
		var partial_search: Dictionary = _search_partial_echo_path(level_def, echo_count)
		if partial_search.get("path_found", false):
			if partial_search.has("actions"):
				result["counterexamples"].append(partial_search)
				result["global_echo_status"] = "VIOLATED_BY_REPLAYED_WITNESS"
			report_lines.append("%d Echo(es): CRITICAL FAILURE — Solvable with only %d Echo(es) (requires %d)!" % [
				echo_count, echo_count, level_def.min_echoes_required
			])
			sub_min_ok = false
		else:
			report_lines.append("%d Echo(es): FAILED — No solution found." % echo_count)

	result["sub_min_echoes_passed"] = sub_min_ok

	# --------------------------------------------------------------------------
	# 3. VERIFIED SOLUTION REPLAY
	# --------------------------------------------------------------------------
	if not verified_solution.is_empty():
		var replay_result: Dictionary = _replay_solution(level_def, verified_solution, action_bound)
		result["replay"] = replay_result
		result["route_analysis"] = SolverClass.inspect_routes(level_def, verified_solution)
		if replay_result.get("completed", false):
			var turns: int = replay_result.get("turns", 0)
			var echoes_used: int = replay_result.get("echoes_used", 0)
			report_lines.append("%d Echoes: PASSED — Valid solution verified! (%d turns, %d echoes)" % [
				level_def.min_echoes_required, turns, echoes_used
			])
			result["solvable_with_min"] = (echoes_used == level_def.min_echoes_required)
		else:
			report_lines.append("%d Echoes: CRITICAL FAILURE — Solution replay failed! Reason: %s" % [
				level_def.min_echoes_required, replay_result.get("error", "Unknown")
			])
			result["solvable_with_min"] = false
	else:
		report_lines.append("%d Echoes: SKIPPED (No verified solution provided for replay)" % level_def.min_echoes_required)
		result["solvable_with_min"] = false # No witness means INCONCLUSIVE, never a pass.

	# --------------------------------------------------------------------------
	# SUMMARY
	# --------------------------------------------------------------------------
	report_lines.append("")
	if result["zero_echo_passed"]:
		report_lines.append("Zero-Echo bypass test:   PASSED [✓] (Cannot be solved without Echoes)")
	else:
		report_lines.append("Zero-Echo bypass test:   FAILED/INCONCLUSIVE (See search result above)")

	if result["sub_min_echoes_passed"]:
		report_lines.append("Sub-minimum Echo screen: PASSED [✓] (No counterexample; not a global proof)")
	else:
		report_lines.append("Sub-minimum Echo test:   FAILED [✗] (Solved with too few Echoes)")

	if result["solvable_with_min"]:
		report_lines.append("Level solvability:       PASSED [✓] (Solvable with %d Echoes)" % level_def.min_echoes_required)
	else:
		report_lines.append("Level solvability:       FAILED [✗]")

	result["intended_solution_valid"] = result["structural_errors"].is_empty() and result["zero_echo_passed"] and result["solvable_with_min"]
	result["is_valid"] = result["intended_solution_valid"] and result["sub_min_echoes_passed"]
	report_lines.append("OVERALL SCREEN STATUS:   %s" % ("VALIDATED [✓]" if result["is_valid"] else "INVALID [✗]"))
	report_lines.append("===================================================================")

	if not proof.is_empty():
		var complete: bool = proof.get("status", "") == "BOUNDED_EXACT" and proof.get("level_id", "") == level_def.level_id
		complete = complete and proof.get("level_fingerprint", "") == level_def.get_rules_fingerprint()
		complete = complete and int(proof.get("minimum_wait", -1)) == level_def.max_wait_actions
		complete = complete and int(proof.get("action_bound", -1)) == action_bound
		complete = complete and proof.get("actions", []) == verified_solution
		complete = complete and result.get("route_analysis", {}).get("intended_route", false)
		var trials: Array = proof.get("trials", [])
		complete = complete and trials.size() == level_def.max_wait_actions + 1
		for index in range(trials.size()):
			var trial: Dictionary = trials[index]
			complete = complete and int(trial.get("wait_limit", -1)) == index and trial.get("complete", false)
			complete = complete and bool(trial.get("found", false)) == (index == level_def.max_wait_actions)
		result["optimization_valid"] = complete and result["intended_solution_valid"]
		result["optimization_status"] = "BOUNDED_EXACT" if result["optimization_valid"] else "INCONCLUSIVE"
	result["report"] = "\n".join(report_lines)
	return result

## Simulates state-space BFS with 0 Echoes to find if exit is reachable.
static func _search_zero_echo_path(level_def: LevelDefinition) -> Dictionary:
	var initial = PuzzleSimulationClass.new()
	initial.load_level(level_def)
	var pending: Array = [{"sim": initial, "path": [level_def.spawn_pos]}]
	var visited: Dictionary = {}
	var head: int = 0
	while head < pending.size():
		if head >= 50000:
			return {"path_found": false, "complete": false, "states_explored": head}
		var node: Dictionary = pending[head]
		head += 1
		var sim: PuzzleSimulation = node.sim
		if sim.is_completed:
			return {"path_found": true, "complete": true, "states_explored": head, "path": node.path}
		# With no Echoes, stationary WAIT cannot change occupancy or sequence edges;
		# it is dominated by omitting it. Histories/clocks do not affect future legality.
		for direction: Vector2i in SolverClass.DIRECTIONS:
			var next: PuzzleSimulation = SolverClass.fork(sim)
			if not next.step_move(direction): continue
			var signature: String = str([next.player_pos, next.sequence_progress, next.sequence_unlocked, next.plates_state])
			if visited.has(signature): continue
			visited[signature] = true
			pending.append({"sim": next, "path": node.path + [next.player_pos]})
	return {"path_found": false, "complete": true, "states_explored": head}

## Checks if exit can be reached when fewer than min_echoes hold plates
static func _search_partial_echo_path(level_def: LevelDefinition, echo_count: int) -> Dictionary:
	var witness: Dictionary = find_prefix_counterexample(level_def, echo_count)
	if witness.get("path_found", false): return witness
	# Enumerate all combinations of `echo_count` plates held permanently by echoes
	var plates: Array[Dictionary] = level_def.plates_data
	if plates.is_empty():
		return {"path_found": false}

	var combinations: Array[Array] = _get_combinations(plates, echo_count)
	for held_plates in combinations:
		var held_plate_ids: Dictionary = {}
		for p: Dictionary in held_plates:
			held_plate_ids[str(p.get("id", ""))] = true

		# BFS from spawn to exit with these plates held
		var queue: Array[Vector2i] = [level_def.spawn_pos]
		var visited: Dictionary = {level_def.spawn_pos: true}

		var directions: Array[Vector2i] = [
			Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
		]

		while not queue.is_empty():
			var curr: Vector2i = queue.pop_front()
			if curr == level_def.exit_pos:
				return {"path_found": true}

			# Active plates = held plates + plate at curr
			var active: Dictionary = held_plate_ids.duplicate()
			for p: Dictionary in level_def.plates_data:
				if p.get("pos", Vector2i(-1, -1)) == curr:
					active[str(p.get("id", ""))] = true

			var open_doors: Dictionary = {}
			for d: Dictionary in level_def.doors_data:
				var did: String = str(d.get("id", ""))
				var logic: String = str(d.get("logic", "AND"))
				var req: Array = d.get("required_plates", [])
				var opened: bool = false
				if logic == "AND":
					opened = true
					for r in req:
						if not active.has(str(r)):
							opened = false
							break
				elif logic == "OR":
					opened = false
					for r in req:
						if active.has(str(r)):
							opened = true
							break
				open_doors[did] = opened

			for dir in directions:
				var nxt: Vector2i = curr + dir
				if not level_def.is_in_bounds(nxt) or level_def.is_wall(nxt):
					continue
				var door_info: Dictionary = level_def.get_door_at(nxt)
				if not door_info.is_empty():
					var did: String = str(door_info.get("id", ""))
					if not open_doors.get(did, false):
						continue
				if not visited.has(nxt):
					visited[nxt] = true
					queue.append(nxt)

	return {"path_found": false}

## Generates combinations of k elements from array
static func _get_combinations(arr: Array, k: int) -> Array[Array]:
	var result: Array[Array] = []
	if k <= 0:
		return [[]]
	if arr.is_empty() or k > arr.size():
		return result
	if k == arr.size():
		return [arr.duplicate()]

	var head: Variant = arr[0]
	var tail: Array = arr.slice(1)

	# Combinations with head
	var with_head: Array[Array] = _get_combinations(tail, k - 1)
	for c: Array in with_head:
		var combo: Array = [head]
		combo.append_array(c)
		result.append(combo)

	# Combinations without head
	var without_head: Array[Array] = _get_combinations(tail, k)
	result.append_array(without_head)

	return result

## Replays an action sequence in PuzzleSimulation to verify completion
static func _replay_solution(level_def: LevelDefinition, solution_steps: Array, action_bound: int = -1) -> Dictionary:
	var sim: PuzzleSimulation = PuzzleSimulationClass.new()
	sim.load_level(level_def)

	var dir_map: Dictionary = {
		"U": Vector2i.UP,
		"D": Vector2i.DOWN,
		"L": Vector2i.LEFT,
		"R": Vector2i.RIGHT
	}

	for index in range(solution_steps.size()):
		var step = solution_steps[index]
		var act: String = str(step).strip_edges().to_upper()
		match act:
			"U", "D", "L", "R":
				var ok: bool = sim.step_move(dir_map[act])
				if not ok:
					return {
						"completed": false,
						"error": "Move %s blocked at turn %d (player at %s)" % [act, sim.current_turn, str(sim.player_pos)]
					}
			"W":
				if not sim.step_wait():
					return {"completed": false, "error": "WAIT rejected at turn %d (limit %d, used %d)" % [sim.current_turn, level_def.max_wait_actions, sim.get_wait_actions_used()]}
			"ECHO":
				var ok: bool = sim.create_echo()
				if not ok:
					return {
						"completed": false,
						"error": "Failed to create Echo at turn %d" % sim.current_turn
					}
			"RESTART":
				sim.restart_attempt()
			_:
				return {
					"completed": false,
					"error": "Unrecognized action '%s'" % act
				}

		if action_bound >= 0 and sim.total_actions_taken > action_bound:
			return {"completed": false, "error": "Action bound exceeded"}
		var state_error: String = _resolved_state_error(sim)
		if not state_error.is_empty():
			return {"completed": false, "error": state_error}
		if sim.is_completed:
			if index != solution_steps.size() - 1:
				return {"completed": false, "error": "Trailing actions after completion"}
			return {
				"completed": true,
				"turns": sim.total_actions_taken,
				"echoes_used": sim.echoes.size(),
				"wait_used": sim.get_wait_actions_used(),
				"exit_state": {"completed": sim.is_completed, "player": [sim.player_pos.x, sim.player_pos.y],
					"exit": [level_def.exit_pos.x, level_def.exit_pos.y], "doors": sim.doors_state.duplicate()}
			}

	return {
		"completed": sim.is_completed,
		"error": "Solution ended without reaching exit",
		"turns": sim.total_actions_taken,
		"echoes_used": sim.echoes.size(),
		"wait_used": sim.get_wait_actions_used()
	}

static func _resolved_state_error(sim: PuzzleSimulation) -> String:
	var actors: Array[Vector2i] = [sim.player_pos]
	for i in range(sim.echoes.size()):
		var rec: EchoRecording = sim.echoes[i]
		var active: bool = not rec.steps.is_empty() and sim.current_turn <= rec.steps.size()
		if sim.is_echo_active(i) != active: return "Echo expiration disagrees with recording duration"
		if active:
			var pos: Vector2i = rec.spawn_pos if sim.current_turn == 0 else rec.steps[sim.current_turn - 1].position
			if sim.get_echo_position(i) != pos: return "Echo playback position mismatch"
			actors.append(pos)
		elif sim.get_echo_position(i) != Vector2i(-1, -1): return "Expired Echo occupies a tile"
	for plate: Dictionary in sim.level_def.plates_data:
		if sim.is_plate_active(plate.id) != (plate.pos in actors): return "Pressure plate occupancy mismatch"
	for door: Dictionary in sim.level_def.doors_data:
		var logic: String = door.get("logic", "AND")
		var expected: bool = logic == "AND"
		if logic == "SEQUENCE": expected = sim.is_sequence_unlocked(door.id)
		else:
			for pid in door.get("required_plates", []):
				if logic == "AND": expected = expected and sim.is_plate_active(pid)
				else: expected = expected or sim.is_plate_active(pid)
		if sim.player_pos == door.pos: expected = true
		if sim.is_door_open(door.id) != expected: return "Resolved door condition mismatch"
	if sim.get_wait_actions_used() > sim.level_def.max_wait_actions: return "Shared WAIT allowance exceeded"
	return ""

## Counterexample search, NOT a proof of absence. Build the first k canonical
## recordings legally, then search every final-player action within the star bound.
## This catches sequence-latch shortcuts hidden by the old static plate screen.
static func find_prefix_counterexample(level: LevelDefinition, echo_count: int, max_states: int = 30000) -> Dictionary:
	var key: String = str([level.get_rules_fingerprint(), level.max_wait_actions, echo_count, max_states])
	if _counterexample_cache.has(key): return _counterexample_cache[key].duplicate(true)
	var seed = PuzzleSimulationClass.new()
	seed.load_level(level)
	var prefix: Array = []
	var directions: Dictionary = {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
	for action in CampaignSolutionsClass.get_actions(level.level_id):
		if seed.echoes.size() >= echo_count: break
		var accepted: bool = false
		if action == "ECHO": accepted = seed.create_echo()
		elif action == "W": accepted = seed.step_wait()
		else: accepted = seed.step_move(directions[action])
		if not accepted: return {"path_found": false, "complete": false, "reason": "Canonical seed rejected"}
		prefix.append(action)
	if seed.echoes.size() != echo_count:
		return {"path_found": false, "complete": false, "reason": "No canonical seed"}
	var pending: Array = [{"sim": seed, "actions": prefix}]
	var visited: Dictionary = {}
	var head: int = 0
	var result: Dictionary = {"path_found": false, "complete": true, "states_explored": 0, "scope": "fixed canonical Echo prefix; star action bound"}
	while head < pending.size():
		if head >= max_states:
			result["complete"] = false
			break
		var node: Dictionary = pending[head]
		head += 1
		var sim: PuzzleSimulation = node.sim
		if sim.is_completed:
			result["path_found"] = true
			result["actions"] = node.actions
			result["replay"] = _replay_solution(level, node.actions, level.target_3_stars)
			break
		if sim.total_actions_taken >= level.target_3_stars: continue
		for action in ["U", "D", "L", "R", "W"]:
			var next: PuzzleSimulation = SolverClass.fork(sim)
			var accepted: bool = next.step_wait() if action == "W" else next.step_move(directions[action])
			if not accepted: continue
			var signature: String = str([next.player_pos, next.current_turn, next.sequence_progress, next.sequence_unlocked, next.plates_state, next.get_wait_actions_used()])
			if visited.has(signature): continue
			visited[signature] = true
			pending.append({"sim": next, "actions": node.actions + [action]})
	result["states_explored"] = head
	_counterexample_cache[key] = result.duplicate(true)
	return result
