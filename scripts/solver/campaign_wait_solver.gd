class_name CampaignWaitSolver
extends RefCounted

## Enumerates purposeful shortest spatial routes, with WAIT at every position.
## All legal transitions are evaluated by PuzzleSimulation, never by a second engine.
## Results are exact only within the explicitly reported route/action domain.
const Sim = preload("res://scripts/gameplay/puzzle_simulation.gd")
const DIRECTIONS = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const ACTIONS = ["U", "D", "L", "R"]
var max_states: int = 2000000
var max_msec: int = 120000
var use_lower_bounds: bool = true
var movement_slack: int = 0 # Diagnostic domain extension; zero excludes movement padding.
var stop_after_first: bool = false
var explored: int = 0
var cut_off: bool = false
var _deadline: int
var _level: LevelDefinition
var _goals: Array[Vector2i] = []
var _distances: Array[Dictionary] = []
var _visited: Dictionary = {}
var _best: Array = []
var _best_actions: int
var _wait_limit: int
var _earliest_plates: Dictionary = {}
var _hold_until: Array[int] = []
var _stage_min_waits: Array[int] = []
var _bound: int

static func fork(source: PuzzleSimulation) -> PuzzleSimulation:
	var copy = Sim.new()
	copy.level_def = source.level_def
	copy.current_turn = source.current_turn
	copy.total_actions_taken = source.total_actions_taken
	copy.player_pos = source.player_pos
	copy.echoes.assign(source.echoes)
	copy.current_recording = source.current_recording.duplicate_recording()
	copy.plates_state = source.plates_state.duplicate()
	copy.doors_state = source.doors_state.duplicate()
	copy.sequence_progress = source.sequence_progress.duplicate()
	copy.sequence_unlocked = source.sequence_unlocked.duplicate()
	copy.game_state = source.game_state
	copy.is_completed = source.is_completed
	return copy

static func distances(level: LevelDefinition, goal: Vector2i) -> Dictionary:
	var result: Dictionary = {goal: 0}
	var queue: Array[Vector2i] = [goal]
	var head: int = 0
	while head < queue.size():
		var pos: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in DIRECTIONS:
			var next: Vector2i = pos + direction
			if not level.is_wall(next) and not result.has(next):
				result[next] = int(result[pos]) + 1
				queue.append(next)
	return result

static func _orders(positions: Array[Vector2i]) -> Array:
	if positions.is_empty(): return [[]]
	var result: Array = []
	for i in range(positions.size()):
		var rest: Array[Vector2i] = positions.duplicate()
		var first: Vector2i = rest.pop_at(i)
		for tail: Array in _orders(rest):
			var order: Array = [first]
			order.append_array(tail)
			result.append(order)
	return result

func solve(level: LevelDefinition, upper_wait: int = -1) -> Dictionary:
	_level = level.duplicate(true)
	_level.initialize_from_map()
	_bound = level.target_3_stars
	_deadline = Time.get_ticks_msec() + max_msec
	explored = 0
	cut_off = false
	var positions: Array[Vector2i] = []
	for plate: Dictionary in level.plates_data: positions.append(plate.pos)
	if positions.size() != level.min_echoes_required or _bound <= 0:
		return {"status": "INCONCLUSIVE", "reason": "Unsupported goal assignment or action bound", "level_id": level.level_id, "minimum_wait": null, "actions": [], "total_actions": null, "action_bound": _bound, "states_explored": 0, "trials": []}
	_earliest_plates = _optimistic_plate_times()
	var trials: Array = []
	var upper: int = level.max_wait_actions if upper_wait < 0 else upper_wait
	for limit in range(upper + 1):
		_wait_limit = limit
		_level.max_wait_actions = limit
		_best = []
		_best_actions = _bound + 1
		var start_states: int = explored
		for order: Array in _orders(positions):
			_goals.assign(order)
			_goals.append(level.exit_pos)
			_distances.clear()
			for goal: Vector2i in _goals: _distances.append(distances(_level, goal))
			_prepare_wait_lower_bounds()
			_visited.clear()
			var sim = Sim.new()
			sim.load_level(_level)
			_search(sim, [])
			if cut_off: break
		trials.append({"wait_limit": limit, "states_explored": explored - start_states,
			"complete": not cut_off, "found": not _best.is_empty()})
		if cut_off or not _best.is_empty(): break
	return {"level_id": level.level_id, "level_fingerprint": level.get_rules_fingerprint(), "status": "INCONCLUSIVE" if cut_off else ("BOUNDED_EXACT" if not _best.is_empty() else "NO_SOLUTION_IN_DOMAIN"),
		"domain": "shortest spatial routes + %d movement slack per attempt; all distinct plate orders; WAIT anywhere; exactly intended Echo count" % movement_slack,
		"action_bound": _bound, "states_explored": explored, "trials": trials,
		"minimum_wait": _wait_limit if not _best.is_empty() else null,
		"actions": _best, "total_actions": _best_actions if not _best.is_empty() else null}

func _signature(sim: PuzzleSimulation) -> String:
	# Historical Echo positions only affect the environment when on a plate.
	# Keep every plate-occupancy turn and duration; non-plate Echo positions cannot
	# influence collision (Echoes are historical). Player position and all temporal
	# environment state remain in the key. Never use this key for a loop-free domain.
	var history: Array = []
	for rec: EchoRecording in sim.echoes + [sim.current_recording]:
		var occupancy: Array = []
		for step: Dictionary in rec.steps:
			occupancy.append(_level.get_plate_at(step.position).get("id", "-"))
		history.append(occupancy)
	return str([sim.echoes.size(), sim.player_pos, sim.current_turn, history,
		sim.sequence_progress, sim.sequence_unlocked, sim.plates_state, sim.get_wait_actions_used(),
		sim.current_recording.get_wait_action_count()])

func _search(sim: PuzzleSimulation, path: Array) -> void:
	if cut_off or (stop_after_first and not _best.is_empty()): return
	explored += 1
	if explored > max_states or Time.get_ticks_msec() >= _deadline:
		cut_off = true
		return
	var stage: int = sim.echoes.size()
	if sim.is_completed:
		if stage == _level.min_echoes_required and sim.total_actions_taken < _best_actions:
			_best = path.duplicate()
			_best_actions = sim.total_actions_taken
		return
	if stage >= _goals.size(): return
	var lower_wait: int = sim.get_wait_actions_used()
	for later in range(stage, _goals.size()):
		var already: int = sim.current_recording.get_wait_action_count() if later == stage else 0
		lower_wait += maxi(0, _stage_min_waits[later] - already)
	if lower_wait > _wait_limit: return
	var remaining_moves: int = int(_distances[stage].get(sim.player_pos, 100000))
	for later in range(stage + 1, _goals.size()):
		remaining_moves += int(_distances[later].get(_level.spawn_pos, 100000))
	if sim.total_actions_taken + remaining_moves > _bound or sim.total_actions_taken + remaining_moves >= _best_actions: return
	var signature: String = _signature(sim)
	if _visited.has(signature): return
	_visited[signature] = true
	if sim.player_pos == _goals[stage] and stage < _level.min_echoes_required and sim.current_turn >= _hold_until[stage]:
		var committed = fork(sim)
		if committed.create_echo():
			_search(committed, path + ["ECHO"])
	if sim.player_pos != _goals[stage] or movement_slack > 0:
		var moves: int = sim.current_recording.get_step_count() - sim.current_recording.get_wait_action_count()
		var max_moves: int = int(_distances[stage].get(_level.spawn_pos, 100000)) + movement_slack
		for i in range(DIRECTIONS.size()):
			var direction: Vector2i = DIRECTIONS[i]
			if moves + 1 + int(_distances[stage].get(sim.player_pos + direction, 100000)) > max_moves: continue
			var next = fork(sim)
			if next.step_move(direction): _search(next, path + [ACTIONS[i]])
	if sim.get_remaining_wait_actions() > 0 and sim.total_actions_taken < _bound and sim.total_actions_taken < _best_actions - 1:
		var next = fork(sim)
		if next.step_wait(): _search(next, path + ["W"])

# Admissible lower bounds only: ignore Echo expiry and let plates stay occupied
# forever after their earliest possible arrival. Relaxation may under-estimate
# required WAIT; it never authorizes an action. Search still calls the real engine.
func _optimistic_arrival(goal: Vector2i, plate_times: Dictionary) -> int:
	var times: Dictionary = {_level.spawn_pos: 0}
	var pending: Array[Vector2i] = [_level.spawn_pos]
	while not pending.is_empty():
		var best: int = 0
		for i in range(1, pending.size()):
			if int(times[pending[i]]) < int(times[pending[best]]): best = i
		var pos: Vector2i = pending.pop_at(best)
		var time: int = int(times[pos])
		if pos == goal: return time
		for direction: Vector2i in DIRECTIONS:
			var next: Vector2i = pos + direction
			if _level.is_wall(next): continue
			var arrival: int = time + 1
			var door: Dictionary = _level.get_door_at(next)
			if not door.is_empty():
				var logic: String = door.get("logic", "AND")
				var required: Array = door.get("required_sequence", door.get("required_plates", []))
				var opening: int = 100000 if logic == "OR" else 0
				for pid in required:
					opening = mini(opening, int(plate_times.get(pid, 0))) if logic == "OR" else maxi(opening, int(plate_times.get(pid, 0)))
				if logic == "SEQUENCE": opening += 1
				arrival = maxi(arrival, opening)
			if arrival < int(times.get(next, 100000)):
				times[next] = arrival
				if next not in pending: pending.append(next)
	return 100000

func _optimistic_plate_times() -> Dictionary:
	var times: Dictionary = {}
	for plate: Dictionary in _level.plates_data:
		times[plate.id] = int(distances(_level, plate.pos).get(_level.spawn_pos, 100000))
	for iteration in range(100):
		var changed: bool = false
		for plate: Dictionary in _level.plates_data:
			var earliest: int = _optimistic_arrival(plate.pos, times)
			if earliest > int(times[plate.id]):
				times[plate.id] = earliest
				changed = true
		if not changed: break
	return times

func _door_is_mandatory(goal: Vector2i, blocked: Vector2i, start: Vector2i = Vector2i(-1, -1)) -> bool:
	if start == Vector2i(-1, -1): start = _level.spawn_pos
	var visited: Dictionary = {start: true}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var pos: Vector2i = pending.pop_back()
		if pos == goal: return false
		for direction: Vector2i in DIRECTIONS:
			var next: Vector2i = pos + direction
			if next != blocked and not _level.is_wall(next) and not visited.has(next):
				visited[next] = true
				pending.append(next)
	return true

func _prepare_wait_lower_bounds() -> void:
	_hold_until.clear()
	_stage_min_waits.clear()
	for stage in range(_goals.size()):
		var needed_until: int = _optimistic_arrival(_goals[stage], _earliest_plates) if use_lower_bounds else 0
		if use_lower_bounds and stage < _level.min_echoes_required and movement_slack == 0 and _unique_terminal_holder(stage):
			var pid: String = _level.get_plate_at(_goals[stage]).get("id", "")
			for door: Dictionary in _level.doors_data:
				if door.get("logic", "AND") != "AND" or pid not in door.get("required_plates", []): continue
				# A plate next to its door might be held by the moving player. Avoid
				# assigning that door's support exclusively to an earlier Echo.
				if (_goals[stage] - Vector2i(door.pos)).length() <= 1.0: continue
				for later in range(stage + 1, _goals.size()):
					if _door_is_mandatory(_goals[later], door.pos):
						needed_until = maxi(needed_until, _optimistic_arrival(door.pos, _earliest_plates))
		_hold_until.append(needed_until)
		var shortest: int = int(_distances[stage].get(_level.spawn_pos, 100000))
		_stage_min_waits.append(maxi(0, needed_until - shortest - movement_slack))

func _unique_terminal_holder(holder: int) -> bool:
	# Proof of applicability for the lifetime lower bound. Another shortest-route
	# recording can either never visit this plate, or must subsequently cross a
	# remote AND gate controlled by it. In the latter case it cannot be the latest
	# holder: constructing that later gate crossing needs an even later holder in
	# an earlier recording. By descending recording index the terminal holder has
	# the latest occupancy. This is NOT assumed for arbitrary layouts or detours.
	var plate: Vector2i = _goals[holder]
	var pid: String = _level.get_plate_at(plate).get("id", "")
	var from_plate: Dictionary = distances(_level, plate)
	var spawn_to_plate: int = int(from_plate.get(_level.spawn_pos, 100000))
	for other in range(_goals.size()):
		if other == holder: continue
		var direct: int = int(_distances[other].get(_level.spawn_pos, 100000))
		if spawn_to_plate + int(from_plate.get(_goals[other], 100000)) > direct:
			continue # Visiting the plate would require movement padding.
		var must_cross_after: bool = false
		for door: Dictionary in _level.doors_data:
			if door.get("logic", "AND") != "AND" or pid not in door.get("required_plates", []): continue
			if (plate - Vector2i(door.pos)).length() <= 1.0: continue
			if _door_is_mandatory(_goals[other], door.pos, plate):
				must_cross_after = true
				break
		if not must_cross_after: return false
	return true

static func inspect_routes(level: LevelDefinition, actions: Array) -> Dictionary:
	# Annotation only, after authoritative replay; this does not decide legality.
	var attempts: Array = []
	var pos: Vector2i = level.spawn_pos
	var seen: Dictionary = {pos: true}
	var moves: int = 0
	var waits: int = 0
	var looped: bool = false
	var intended: bool = true
	var plate_goals: Array = []
	var dirs: Dictionary = {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
	for index in range(actions.size() + 1):
		var action: String = str(actions[index]) if index < actions.size() else "END"
		if action in ["ECHO", "END"]:
			var shortest: int = int(distances(level, pos).get(level.spawn_pos, 100000))
			var pid: String = level.get_plate_at(pos).get("id", "")
			if action == "ECHO":
				intended = intended and not pid.is_empty() and pid not in plate_goals
				plate_goals.append(pid)
			else: intended = intended and pos == level.exit_pos
			intended = intended and moves == shortest and not looped
			attempts.append({"moves": moves, "waits": waits, "shortest_moves": shortest,
				"movement_padding": moves - shortest, "movement_loop": looped,
				"endpoint": [pos.x, pos.y], "plate": pid})
			pos = level.spawn_pos
			seen = {pos: true}
			moves = 0
			waits = 0
			looped = false
		elif action == "W": waits += 1
		elif dirs.has(action):
			pos += Vector2i(dirs[action])
			moves += 1
			looped = looped or seen.has(pos)
			seen[pos] = true
		else: intended = false
	intended = intended and plate_goals.size() == level.min_echoes_required
	return {"intended_route": intended, "attempts": attempts}
