class_name PuzzleSimulation
extends RefCounted

## Pure, deterministic simulation of the Tomorrow's You gameplay mechanics.
## Fully decoupled from visual rendering and UI for automated testing and rock-solid determinism.

signal wait_limit_reached()

signal turn_completed(turn_index: int)
signal player_moved(from_pos: Vector2i, to_pos: Vector2i, action: String)
signal echo_stepped(echo_index: int, pos: Vector2i, action: String)
signal echo_created(echo_index: int, total_echoes: int)
signal echoes_cleared()
signal attempt_restarted()
signal plate_state_changed(plate_id: String, is_active: bool)
signal door_state_changed(door_id: String, is_open: bool)
signal level_completed(turns_in_winning_attempt: int, echoes_used: int, total_actions: int)
signal move_blocked(target_pos: Vector2i, reason: String)
signal echo_limit_reached()
signal echo_expired(echo_index: int, final_pos: Vector2i)
signal sequence_advanced(door_id: String, step_index: int, total_steps: int)
signal sequence_reset(door_id: String)

enum GameState { PLAYING, PAUSED, COMPLETED, FAILED }
var game_state: GameState = GameState.PLAYING

var debug_turn_logging: bool = false

var level_def: LevelDefinition = null
var current_turn: int = 0
var total_actions_taken: int = 0
var player_pos: Vector2i = Vector2i.ZERO
var echoes: Array[EchoRecording] = []
var current_recording: EchoRecording = null

# State tables
var plates_state: Dictionary = {} # plate_id (String) -> bool
var doors_state: Dictionary = {}  # door_id (String) -> bool
var sequence_progress: Dictionary = {} # door_id (String) -> int
var sequence_unlocked: Dictionary = {} # door_id (String) -> bool
var is_completed: bool = false

func load_level(p_level_def: LevelDefinition) -> void:
	level_def = p_level_def
	total_actions_taken = 0
	echoes.clear()
	game_state = GameState.PLAYING
	is_completed = false
	restart_attempt()

func restart_attempt() -> void:
	if level_def == null:
		return
	game_state = GameState.PLAYING
	is_completed = false
	current_turn = 0
	player_pos = level_def.spawn_pos
	current_recording = EchoRecording.new(level_def.level_id, level_def.spawn_pos)
	sequence_progress.clear()
	sequence_unlocked.clear()

	plates_state.clear()
	doors_state.clear()
	# Initialize states at turn 0
	_recalculate_plates_and_doors()
	attempt_restarted.emit()

func create_echo() -> bool:
	if level_def == null or game_state == GameState.COMPLETED or is_completed:
		return false
	if current_recording == null or current_recording.get_step_count() == 0:
		# Empty attempt, just restart without creating echo
		restart_attempt()
		return false

	for recording: EchoRecording in echoes + [current_recording]:
		if not recording.has_valid_actions():
			move_blocked.emit(player_pos, "INVALID_RECORDING")
			return false

	if get_wait_actions_used() > level_def.max_wait_actions:
		wait_limit_reached.emit()
		return false

	if echoes.size() >= level_def.echo_limit:
		echo_limit_reached.emit()
		return false

	var new_echo: EchoRecording = current_recording.duplicate_recording()
	echoes.append(new_echo)
	var new_index: int = echoes.size() - 1
	restart_attempt()
	echo_created.emit(new_index, echoes.size())
	return true

func clear_echoes() -> void:
	if level_def == null:
		return
	echoes.clear()
	restart_attempt()
	echoes_cleared.emit()

func is_exit_available() -> bool:
	if level_def == null:
		return false
	var door_info: Dictionary = level_def.get_door_at(level_def.exit_pos)
	if door_info.is_empty():
		return true
	var door_id: String = str(door_info.get("id", ""))
	return is_door_open(door_id) or player_pos == level_def.exit_pos

func check_level_completion() -> bool:
	if game_state == GameState.COMPLETED:
		return false
	if level_def == null:
		print("[LEVEL] Rejected: No level definition loaded.")
		return false
	if player_pos != level_def.exit_pos:
		return false
	if not is_exit_available():
		print("[LEVEL] Rejected: Exit at %s is locked/unavailable." % str(level_def.exit_pos))
		return false

	complete_level()
	return true

func complete_level() -> void:
	if game_state == GameState.COMPLETED:
		return

	game_state = GameState.COMPLETED
	is_completed = true

	print("[LEVEL] Completion condition: satisfied")
	print("[LEVEL] COMPLETION TRIGGERED")

	level_completed.emit(current_turn, echoes.size(), total_actions_taken)

func step_move(dir: Vector2i) -> bool:
	if game_state == GameState.COMPLETED or is_completed or level_def == null:
		return false

	if dir not in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		move_blocked.emit(player_pos, "INVALID_DIRECTION")
		return false

	var target_pos: Vector2i = player_pos + dir

	# 1. Check wall collision
	if level_def.is_wall(target_pos):
		move_blocked.emit(target_pos, "WALL")
		return false # Does NOT consume a turn

	# 2. Check door collision
	var door_info: Dictionary = level_def.get_door_at(target_pos)
	if not door_info.is_empty():
		var door_id: String = str(door_info.get("id", ""))
		var is_open: bool = is_door_open_at_turn(door_id, current_turn + 1)
		if not is_open:
			move_blocked.emit(target_pos, "DOOR_CLOSED")
			return false # Does NOT consume a turn

	# Valid move!
	var from_pos: Vector2i = player_pos
	player_pos = target_pos
	current_turn += 1
	total_actions_taken += 1
	current_recording.record_step("MOVE", dir, player_pos)
	_advance_turn(from_pos, "MOVE")
	return true

func step_wait() -> bool:
	if game_state == GameState.COMPLETED or is_completed or level_def == null:
		return false

	if get_remaining_wait_actions() <= 0:
		wait_limit_reached.emit()
		return false

	current_turn += 1
	total_actions_taken += 1
	current_recording.record_step("WAIT", Vector2i.ZERO, player_pos)
	_advance_turn(player_pos, "WAIT")
	return true

func step_interact() -> bool:
	# There is no separate interactable mechanic: stationary time advancement is WAIT.
	return step_wait()

func get_wait_actions_used() -> int:
	var used: int = 0
	for echo: EchoRecording in echoes:
		used += echo.get_wait_action_count()
	if current_recording != null:
		used += current_recording.get_wait_action_count()
	return used

func get_remaining_wait_actions() -> int:
	return maxi(0, level_def.max_wait_actions - get_wait_actions_used()) if level_def else 0

func get_turn_snapshot() -> Dictionary:
	var actors: Array[Dictionary] = []
	for i in range(echoes.size()):
		actors.append({"index": i, "active": is_echo_active(i), "position": get_echo_position(i)})
	var next_doors: Dictionary = {}
	for door: Dictionary in level_def.doors_data if level_def else []:
		var did: String = str(door.get("id", ""))
		next_doors[did] = is_door_open_at_turn(did, current_turn + 1)
	return {"turn": current_turn, "player": player_pos, "echoes": actors,
		"plates": plates_state.duplicate(), "doors": doors_state.duplicate(),
		"next_doors": next_doors, "wait_used": get_wait_actions_used(),
		"wait_remaining": get_remaining_wait_actions()}

func _advance_turn(from_pos: Vector2i, action: String) -> void:
	# Commit order: accepted player action -> Echo positions at current_turn ->
	# plates/door/sequence resolution -> presentation signals -> exit -> HUD.
	# Door entry is validated BEFORE commit using upcoming Echo positions and the
	# player's pre-move position (is_door_open_at_turn). Historical Echoes never collide.
	_recalculate_plates_and_doors()
	player_moved.emit(from_pos, player_pos, action)
	for i in range(echoes.size()):
		var echo: EchoRecording = echoes[i]
		var echo_pos: Vector2i = echo.get_position_at_turn(current_turn)
		if current_turn == echo.get_step_count() + 1:
			echo_expired.emit(i, echo_pos)
		echo_stepped.emit(i, echo_pos, echo.get_action_at_turn(current_turn))
	check_level_completion()
	turn_completed.emit(current_turn)
	if OS.is_debug_build() and debug_turn_logging:
		print("[RESOLVED TURN] ", get_turn_snapshot())

func _recalculate_plates_and_doors() -> void:
	if level_def == null:
		return

	# Determine positions of all eligible active actors (Player + Active Echoes ONLY)
	# IMPORTANT: Expired Echoes DO NOT press pressure plates!
	var active_positions: Array[Vector2i] = [player_pos]
	for echo: EchoRecording in echoes:
		if echo.is_active_at_turn(current_turn):
			active_positions.append(echo.get_position_at_turn(current_turn))

	var newly_pressed_plates: Array[String] = []
	var notifications: Array[Array] = []

	# 1. Update plates
	for p: Dictionary in level_def.plates_data:
		var pid: String = str(p.get("id", ""))
		var ppos: Vector2i = p.get("pos", Vector2i(-1, -1))
		var is_pressed: bool = ppos in active_positions

		var old_state: bool = plates_state.get(pid, false)
		if is_pressed and not old_state:
			newly_pressed_plates.append(pid)

		if old_state != is_pressed or not plates_state.has(pid):
			plates_state[pid] = is_pressed
			notifications.append(["plate_state_changed", pid, is_pressed])

	# 2. Update doors
	for d: Dictionary in level_def.doors_data:
		var did: String = str(d.get("id", ""))
		var dpos: Vector2i = d.get("pos", Vector2i(-1, -1))
		var logic: String = str(d.get("logic", "AND")).to_upper()
		var req_plates: Array = d.get("required_plates", [])

		var condition_met: bool = false
		if logic == "AND":
			condition_met = true
			for rpid in req_plates:
				if not plates_state.get(str(rpid), false):
					condition_met = false
					break
		elif logic == "OR":
			condition_met = false
			for rpid in req_plates:
				if plates_state.get(str(rpid), false):
					condition_met = true
					break
		elif logic == "SEQUENCE":
			var seq: Array = d.get("required_sequence", [])
			if sequence_unlocked.get(did, false):
				condition_met = true
			else:
				var curr_step: int = sequence_progress.get(did, 0)
				for pid in newly_pressed_plates:
					if seq.has(pid):
						if curr_step < seq.size() and pid == str(seq[curr_step]):
							curr_step += 1
							sequence_progress[did] = curr_step
							notifications.append(["sequence_advanced", did, curr_step, seq.size()])
							if curr_step >= seq.size():
								sequence_unlocked[did] = true
								condition_met = true
						else:
							sequence_progress[did] = 0
							notifications.append(["sequence_reset", did])

		# CRITICAL SAFETY RULE:
		# Never close a physical door on the real player standing inside its tile!
		if player_pos == dpos:
			condition_met = true

		var old_door: bool = doors_state.get(did, false)
		if old_door != condition_met or not doors_state.has(did):
			doors_state[did] = condition_met
			notifications.append(["door_state_changed", did, condition_met])

	# Observers only receive notifications after all environment tables are committed.
	for notification: Array in notifications:
		callv("emit_signal", notification)

func get_echo_position(echo_index: int) -> Vector2i:
	if echo_index < 0 or echo_index >= echoes.size():
		return Vector2i(-1, -1)
	if not is_echo_active(echo_index):
		return Vector2i(-1, -1)
	return echoes[echo_index].get_position_at_turn(current_turn)

func is_echo_active(echo_index: int) -> bool:
	if echo_index < 0 or echo_index >= echoes.size():
		return false
	return echoes[echo_index].is_active_at_turn(current_turn)

func get_echo_remaining_turns(echo_index: int) -> int:
	if echo_index < 0 or echo_index >= echoes.size():
		return 0
	return echoes[echo_index].get_remaining_turns(current_turn)

func get_echo_total_turns(echo_index: int) -> int:
	if echo_index < 0 or echo_index >= echoes.size():
		return 0
	return echoes[echo_index].get_step_count()

func get_sequence_progress(door_id: String) -> int:
	return sequence_progress.get(door_id, 0)

func is_sequence_unlocked(door_id: String) -> bool:
	return sequence_unlocked.get(door_id, false)

func is_plate_active(plate_id: String) -> bool:
	return plates_state.get(plate_id, false)

func is_door_open_at_turn(door_id: String, turn: int) -> bool:
	if level_def == null:
		return false
	var d: Dictionary = {}
	for door: Dictionary in level_def.doors_data:
		if str(door.get("id", "")) == door_id:
			d = door
			break
	if d.is_empty():
		return false

	var dpos: Vector2i = d.get("pos", Vector2i(-1, -1))
	# CRITICAL SAFETY RULE: Never close a physical door on the real player standing inside its tile!
	if player_pos == dpos:
		return true

	var logic: String = str(d.get("logic", "AND")).to_upper()
	if logic == "SEQUENCE":
		return sequence_unlocked.get(door_id, false)

	var req_plates: Array = d.get("required_plates", [])
	if req_plates.is_empty():
		return true

	# Active actors at `turn`: Player (at current position) + Active Echoes at `turn`
	var active_positions: Array[Vector2i] = [player_pos]
	for echo: EchoRecording in echoes:
		if echo.is_active_at_turn(turn):
			active_positions.append(echo.get_position_at_turn(turn))

	var active_plate_ids: Dictionary = {}
	for p: Dictionary in level_def.plates_data:
		var pid: String = str(p.get("id", ""))
		var ppos: Vector2i = p.get("pos", Vector2i(-1, -1))
		if active_positions.has(ppos):
			active_plate_ids[pid] = true

	if logic == "AND":
		for rpid in req_plates:
			if not active_plate_ids.get(str(rpid), false):
				return false
		return true
	elif logic == "OR":
		for rpid in req_plates:
			if active_plate_ids.get(str(rpid), false):
				return true
		return false

	return false

func is_door_open(door_id: String) -> bool:
	return doors_state.get(door_id, false)

