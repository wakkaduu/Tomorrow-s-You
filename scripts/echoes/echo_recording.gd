class_name EchoRecording
extends RefCounted

## Immutable historical turn record of player actions and positions.
## Echoes faithfully replay their recorded positions to guarantee deterministic playback.

var level_id: String = ""
var spawn_pos: Vector2i = Vector2i.ZERO
var steps: Array[Dictionary] = []
var version: int = 1

func _init(p_level_id: String = "", p_spawn_pos: Vector2i = Vector2i.ZERO) -> void:
	level_id = p_level_id
	spawn_pos = p_spawn_pos
	steps = []
	version = 1

func record_step(action: String, direction: Vector2i, position: Vector2i) -> void:
	steps.append({
		"turn": steps.size() + 1,
		"action": action,
		"direction": direction,
		"position": position
	})

func has_valid_actions() -> bool:
	var previous: Vector2i = spawn_pos
	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		var action: String = str(step.get("action", ""))
		var direction = step.get("direction")
		var position = step.get("position")
		if not (direction is Vector2i) or not (position is Vector2i) or step.get("turn", -1) != i + 1:
			return false
		if action == "MOVE":
			if direction not in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT] or position != previous + direction:
				return false
		elif action in ["WAIT", "INTERACT"]:
			if direction != Vector2i.ZERO or position != previous:
				return false
		else:
			return false
		previous = position
	return true

func get_wait_action_count() -> int:
	var count: int = 0
	for step: Dictionary in steps:
		# Legacy idle INTERACT recordings must not bypass the shared allowance.
		if str(step.get("action", "")).to_upper() in ["WAIT", "INTERACT"]:
			count += 1
	return count

func get_step_count() -> int:
	return steps.size()

func get_position_at_turn(turn: int) -> Vector2i:
	if turn <= 0:
		return spawn_pos
	if steps.is_empty():
		return spawn_pos
	if turn <= steps.size():
		return steps[turn - 1]["position"]
	# Expired recording: returns last position for fadeout visuals
	return steps[steps.size() - 1]["position"]

func get_action_at_turn(turn: int) -> String:
	if turn <= 0 or steps.is_empty():
		return "SPAWN"
	if turn <= steps.size():
		return steps[turn - 1]["action"]
	return "EXPIRED"

func is_active_at_turn(turn: int) -> bool:
	if steps.is_empty():
		return false
	return turn <= steps.size()

func get_remaining_turns(turn: int) -> int:
	return maxi(0, steps.size() - turn)

func duplicate_recording() -> EchoRecording:
	var dup: EchoRecording = EchoRecording.new(level_id, spawn_pos)
	dup.version = version
	for s: Dictionary in steps:
		dup.steps.append({
			"turn": s["turn"],
			"action": s["action"],
			"direction": s["direction"],
			"position": s["position"]
		})
	return dup

func to_dict() -> Dictionary:
	return {
		"level_id": level_id,
		"spawn_pos": [spawn_pos.x, spawn_pos.y],
		"version": version,
		"steps": steps
	}

static func from_dict(data: Dictionary) -> EchoRecording:
	var sp: Array = data.get("spawn_pos", [0, 0])
	var rec: EchoRecording = EchoRecording.new(
		str(data.get("level_id", "")),
		Vector2i(int(sp[0]), int(sp[1]))
	)
	rec.version = int(data.get("version", 1))
	var raw_steps: Array = data.get("steps", [])
	for s in raw_steps:
		if s is Dictionary:
			var dir_arr = s.get("direction", [0, 0])
			var dir_vec: Vector2i = Vector2i.ZERO
			if dir_arr is Vector2i:
				dir_vec = dir_arr
			elif dir_arr is Array and dir_arr.size() >= 2:
				dir_vec = Vector2i(int(dir_arr[0]), int(dir_arr[1]))

			var pos_arr = s.get("position", [0, 0])
			var pos_vec: Vector2i = Vector2i.ZERO
			if pos_arr is Vector2i:
				pos_vec = pos_arr
			elif pos_arr is Array and pos_arr.size() >= 2:
				pos_vec = Vector2i(int(pos_arr[0]), int(pos_arr[1]))

			rec.steps.append({
				"turn": int(s.get("turn", 0)),
				"action": str(s.get("action", "MOVE")),
				"direction": dir_vec,
				"position": pos_vec
			})
	return rec

