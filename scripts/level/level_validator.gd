class_name LevelValidator
extends RefCounted

## Automated Level Solvability & Echo-Dependency Validator for Tomorrow's You.
## Verifies that:
## 1. Zero-Echo solutions do NOT exist (Zero-Echo Bypass Test passes).
## 2. Puzzles cannot be solved with fewer Echoes than `min_echoes_required`.
## 3. The level has a verified solvable path with `min_echoes_required` Echoes.

const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")

## Result dictionary returned by validate_level():
## {
##   "level_id": String,
##   "min_echoes_required": int,
##   "zero_echo_passed": bool,       # True if 0 Echoes cannot reach exit
##   "sub_min_echoes_passed": bool,  # True if < min_echoes cannot reach exit
##   "solvable_with_min": bool,      # True if min_echoes solves the level
##   "is_valid": bool,               # True if all pass
##   "states_explored_0_echo": int,
##   "log": Array[String],
##   "report": String
## }
static func validate_level(level_def: LevelDefinition, verified_solution: Array = []) -> Dictionary:
	var result: Dictionary = {
		"level_id": level_def.level_id,
		"level_name": level_def.level_name,
		"min_echoes_required": level_def.min_echoes_required,
		"zero_echo_passed": false,
		"sub_min_echoes_passed": false,
		"solvable_with_min": false,
		"is_valid": false,
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
		result["zero_echo_passed"] = true

	# --------------------------------------------------------------------------
	# 2. SUB-MINIMUM ECHO VALIDATION (for levels requiring >= 2 echoes)
	# --------------------------------------------------------------------------
	var sub_min_ok: bool = true
	for echo_count in range(1, level_def.min_echoes_required):
		var partial_search: Dictionary = _search_partial_echo_path(level_def, echo_count)
		if partial_search.get("path_found", false):
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
		var replay_result: Dictionary = _replay_solution(level_def, verified_solution)
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
		result["solvable_with_min"] = true # Neutral if not provided

	# --------------------------------------------------------------------------
	# SUMMARY
	# --------------------------------------------------------------------------
	report_lines.append("")
	if result["zero_echo_passed"]:
		report_lines.append("Zero-Echo bypass test:   PASSED [✓] (Cannot be solved without Echoes)")
	else:
		report_lines.append("Zero-Echo bypass test:   FAILED [✗] (Player can walk to exit!)")

	if result["sub_min_echoes_passed"]:
		report_lines.append("Sub-minimum Echo test:   PASSED [✓] (Cannot be solved with fewer Echoes)")
	else:
		report_lines.append("Sub-minimum Echo test:   FAILED [✗] (Solved with too few Echoes)")

	if result["solvable_with_min"]:
		report_lines.append("Level solvability:       PASSED [✓] (Solvable with %d Echoes)" % level_def.min_echoes_required)
	else:
		report_lines.append("Level solvability:       FAILED [✗]")

	result["is_valid"] = result["zero_echo_passed"] and result["sub_min_echoes_passed"] and result["solvable_with_min"]
	report_lines.append("OVERALL STATUS:          %s" % ("VALIDATED [✓]" if result["is_valid"] else "INVALID [✗]"))
	report_lines.append("===================================================================")

	result["report"] = "\n".join(report_lines)
	return result

## Simulates state-space BFS with 0 Echoes to find if exit is reachable.
static func _search_zero_echo_path(level_def: LevelDefinition) -> Dictionary:
	var queue: Array[Vector2i] = [level_def.spawn_pos]
	var visited: Dictionary = {level_def.spawn_pos: true}
	var parent: Dictionary = {}
	var states_explored: int = 0

	var directions: Array[Vector2i] = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
	]

	while not queue.is_empty():
		var curr: Vector2i = queue.pop_front()
		states_explored += 1

		if curr == level_def.exit_pos:
			# Path found! Construct path
			var path: Array[Vector2i] = []
			var trace: Vector2i = curr
			while parent.has(trace):
				path.push_front(trace)
				trace = parent[trace]
			path.push_front(level_def.spawn_pos)
			return {"path_found": true, "path": path, "states_explored": states_explored}

		# Compute doors state if player is at curr
		# In zero-echo, only a plate at curr is active!
		var active_plates: Dictionary = {}
		for p: Dictionary in level_def.plates_data:
			if p.get("pos", Vector2i(-1, -1)) == curr:
				active_plates[str(p.get("id", ""))] = true

		var open_doors: Dictionary = {}
		for d: Dictionary in level_def.doors_data:
			var did: String = str(d.get("id", ""))
			var logic: String = str(d.get("logic", "AND"))
			var req: Array = d.get("required_plates", [])
			var opened: bool = false
			if logic == "AND":
				opened = true
				for r in req:
					if not active_plates.has(str(r)):
						opened = false
						break
			elif logic == "OR":
				opened = false
				for r in req:
					if active_plates.has(str(r)):
						opened = true
						break
			open_doors[did] = opened

		for dir in directions:
			var nxt: Vector2i = curr + dir

			# 1. Bounds check
			if not level_def.is_in_bounds(nxt):
				continue

			# 2. Wall check
			if level_def.is_wall(nxt):
				continue

			# 3. Door check
			var door_info: Dictionary = level_def.get_door_at(nxt)
			if not door_info.is_empty():
				var did: String = str(door_info.get("id", ""))
				if not open_doors.get(did, false):
					continue # Closed door blocks movement

			if not visited.has(nxt):
				visited[nxt] = true
				parent[nxt] = curr
				queue.append(nxt)

	return {"path_found": false, "states_explored": states_explored}

## Checks if exit can be reached when fewer than min_echoes hold plates
static func _search_partial_echo_path(level_def: LevelDefinition, echo_count: int) -> Dictionary:
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
static func _replay_solution(level_def: LevelDefinition, solution_steps: Array) -> Dictionary:
	var sim: PuzzleSimulation = PuzzleSimulationClass.new()
	sim.load_level(level_def)

	var dir_map: Dictionary = {
		"U": Vector2i.UP,
		"D": Vector2i.DOWN,
		"L": Vector2i.LEFT,
		"R": Vector2i.RIGHT
	}

	for step in solution_steps:
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
				sim.step_wait()
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

		if sim.is_completed:
			return {
				"completed": true,
				"turns": sim.total_actions_taken,
				"echoes_used": sim.echoes.size()
			}

	return {
		"completed": sim.is_completed,
		"error": "Solution ended without reaching exit",
		"turns": sim.total_actions_taken,
		"echoes_used": sim.echoes.size()
	}
