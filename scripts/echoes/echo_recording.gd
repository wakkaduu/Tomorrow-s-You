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

func get_step_count() -> int:
	return steps.size()

func get_position_at_turn(turn: int) -> Vector2i:
	if turn <= 0:
		return spawn_pos
	if steps.is_empty():
		return spawn_pos
	if turn <= steps.size():
		return steps[turn - 1]["position"]
	# Finished recording: Echo remains permanently at final recorded position
	return steps[steps.size() - 1]["position"]

func get_action_at_turn(turn: int) -> String:
	if turn <= 0 or steps.is_empty():
		return "SPAWN"
	if turn <= steps.size():
		return steps[turn - 1]["action"]
	return "IDLE"

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

