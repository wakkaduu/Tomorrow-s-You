extends SceneTree

const Sim = preload("res://scripts/gameplay/puzzle_simulation.gd")
const Level = preload("res://scripts/level/level_definition.gd")
const Recording = preload("res://scripts/echoes/echo_recording.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func fixture() -> LevelDefinition:
	var level = Level.new()
	level.level_id = "regression"
	level.map_lines.assign(["########", "#P1.A.X#", "#..2...#", "########"])
	level.doors_data.assign([{"id": "A", "logic": "AND", "required_plates": ["1"]}])
	level.initialize_from_map()
	return level

func _door_reproduction() -> void:
	var sim = Sim.new()
	sim.load_level(fixture())
	sim.step_move(Vector2i.RIGHT)
	sim.step_wait()
	sim.step_move(Vector2i.LEFT)
	sim.step_move(Vector2i.RIGHT)
	sim.create_echo()
	var renderer = load("res://scripts/gameplay/board_renderer.gd").new()
	root.add_child(renderer)
	renderer.setup(sim, Vector2(720, 1280))
	sim.step_wait()
	check(sim.is_door_open("A"), "Echo should open door on turn 1")
	check(renderer.door_anim_weights["A"] == 1.0, "REPRO: door visual stays closed after authoritative open")
	renderer._process(0.5)
	sim.step_wait()
	sim.step_wait()
	check(not sim.is_door_open("A"), "Echo should leave plate on turn 3")
	check(renderer.door_anim_weights["A"] == 0.0, "REPRO: door visual stays open after authoritative close")
	renderer.queue_free()
	await process_frame
	print("DOOR REPRODUCTION: %d / %d passed" % [checks - failures, checks])


func recording(level: LevelDefinition, actions: String) -> EchoRecording:
	var rec = Recording.new(level.level_id, level.spawn_pos)
	var pos: Vector2i = level.spawn_pos
	var dirs: Dictionary = {"R": Vector2i.RIGHT, "L": Vector2i.LEFT, "U": Vector2i.UP, "D": Vector2i.DOWN}
	for action in actions:
		var direction: Vector2i = dirs.get(action, Vector2i.ZERO)
		pos += direction
		rec.record_step("WAIT" if action == "W" else "MOVE", direction, pos)
	return rec

func _door_matrix() -> void:
	for logic in ["AND", "OR"]:
		var level = fixture()
		level.doors_data[0]["logic"] = logic
		level.doors_data[0]["required_plates"] = ["1", "2"]
		var sim = Sim.new()
		sim.load_level(level)
		sim.echoes.append(recording(level, "RWLR"))
		sim.echoes.append(recording(level, "DRRWWW"))
		sim.restart_attempt()
		var renderer = load("res://scripts/gameplay/board_renderer.gd").new()
		root.add_child(renderer)
		renderer.setup(sim, Vector2(720, 1280))
		for turn in range(1, 8):
			check(sim.step_wait(), "Matrix WAIT accepted")
			var plate1: bool = turn in [1, 2, 4]
			var plate2: bool = turn in [3, 4, 5, 6]
			var expected: bool = (plate1 and plate2) if logic == "AND" else (plate1 or plate2)
			check(sim.is_plate_active("1") == plate1 and sim.is_plate_active("2") == plate2, "%s plate occupancy turn %d" % [logic, turn])
			check(sim.is_door_open("A") == expected, "%s door turn %d" % [logic, turn])
			check(renderer.door_anim_weights["A"] == (1.0 if expected else 0.0), "Immediate gate state %s turn %d" % [logic, turn])
			check(renderer.get_door_presentation("A").open == expected, "Rendered authoritative state")
			renderer._process(0.001 if turn % 2 else 0.5)
			check(renderer.door_anim_weights["A"] == (1.0 if expected else 0.0), "Frame timing cannot override gate")
		check(not sim.is_echo_active(0) and not sim.is_echo_active(1), "Both Echoes expired")
		renderer.queue_free()
	await process_frame

func _entry_and_sequence() -> void:
	var level = fixture()
	var sim = Sim.new()
	sim.load_level(level)
	sim.echoes.append(recording(level, "RW"))
	sim.restart_attempt()
	check(sim.step_move(Vector2i.RIGHT) and sim.step_move(Vector2i.RIGHT), "Approach open gate")
	check(sim.is_door_open("A") and not sim.is_door_open_at_turn("A", 3), "Final Echo turn has next-entry closure")
	var before: Dictionary = sim.get_turn_snapshot()
	check(not sim.step_move(Vector2i.RIGHT), "Entry blocks when Echo expires on proposed turn")
	check(sim.get_turn_snapshot() == before, "Blocked entry leaves resolved state intact")
	sim.clear_echoes()
	sim.echoes.append(recording(level, "RWW"))
	sim.restart_attempt()
	for i in range(3):
		check(sim.step_move(Vector2i.RIGHT), "Valid gate approach and entry")
	check(sim.step_wait() and sim.is_door_open("A"), "Door protects player after Echo expires")
	check(sim.step_move(Vector2i.RIGHT) and not sim.is_door_open("A"), "Door closes after player leaves")
	# Historical Echoes replay recorded positions even through now-closed gates.
	sim.clear_echoes()
	sim.echoes.append(recording(level, "RRR"))
	sim.restart_attempt()
	for i in range(3):
		sim.step_wait()
	check(sim.get_echo_position(0) == Vector2i(4, 1) and not sim.is_door_open("A"), "Echo playback ignores current collision")
	level = fixture()
	level.doors_data[0]["logic"] = "SEQUENCE"
	level.doors_data[0]["required_sequence"] = ["1", "2"]
	sim.load_level(level)
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.RIGHT]:
		sim.step_move(dir)
	check(sim.is_sequence_unlocked("A") and sim.is_door_open("A"), "Sequence unlock preserved")
	sim.restart_attempt()
	check(not sim.is_sequence_unlocked("A") and not sim.is_door_open("A"), "Restart resets sequence")

func _wait_accounting() -> void:
	var level = fixture()
	level.max_wait_actions = 3
	var sim = Sim.new()
	sim.load_level(level)
	check(sim.get_wait_actions_used() == 0 and sim.get_remaining_wait_actions() == 3, "Fresh WAIT budget")
	check(sim.step_wait() and sim.get_remaining_wait_actions() == 2, "WAIT charged once")
	check(sim.create_echo() and sim.get_remaining_wait_actions() == 2, "Commit transfers usage without charge or refill")
	check(sim.step_wait() and sim.get_wait_actions_used() == 2, "Replayed WAIT not charged")
	check(sim.create_echo() and sim.get_wait_actions_used() == 2, "Two Echoes share allowance")
	check(sim.step_wait() and sim.get_remaining_wait_actions() == 0, "Last WAIT allowed")
	var snapshot: Dictionary = sim.get_turn_snapshot()
	var steps: Array = sim.current_recording.steps.duplicate(true)
	var total: int = sim.total_actions_taken
	for i in range(3):
		check(not sim.step_wait(), "Exhausted WAIT rejected")
	check(sim.get_turn_snapshot() == snapshot and sim.current_recording.steps == steps and sim.total_actions_taken == total, "Rejected WAIT changes no state or recording")
	check(not sim.step_interact() and not sim.step_move(Vector2i.ZERO), "Idle aliases cannot bypass budget")
	check(sim.step_move(Vector2i.DOWN), "Movement remains available")
	sim.restart_attempt()
	check(sim.get_wait_actions_used() == 2 and sim.get_remaining_wait_actions() == 1 and sim.echoes.size() == 2, "Restart refunds only current recording")
	sim.clear_echoes()
	check(sim.get_remaining_wait_actions() == 3 and sim.echoes.is_empty(), "Clear All resets entire allowance")
	# Injected over-budget or mislabeled idle recordings cannot be committed.
	for i in range(4):
		sim.current_recording.record_step("WAIT", Vector2i.ZERO, sim.player_pos)
	check(not sim.create_echo() and sim.echoes.is_empty(), "Over-budget commit rejected")
	sim.restart_attempt()
	sim.current_recording.record_step("MOVE", Vector2i.ZERO, sim.player_pos)
	check(not sim.create_echo(), "Malformed stationary MOVE commit rejected")
	level = fixture()
	level.max_wait_actions = 0
	sim.load_level(level)
	check(not sim.step_wait() and sim.current_turn == 0, "Zero budget supported")
	level.max_wait_actions = -1
	check(not level.validate().is_empty(), "Negative budget invalid")

func _input_and_hud() -> void:
	var gm = root.get_node("GameManager")
	var sm = root.get_node("SaveManager")
	sm.viewed_transmissions.append("tr_lvl_01_intro")
	gm.select_level(0)
	var game = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var sim: PuzzleSimulation = game.simulation
	game.current_level_def.max_wait_actions = 2
	game._update_hud()
	game.btn_wait.pressed.emit()
	check(sim.current_turn == 1 and game.btn_wait.text == "WAIT · 1 LEFT", "Touch WAIT updates HUD")
	game.btn_create_echo.pressed.emit()
	check(sim.get_remaining_wait_actions() == 1 and game.btn_wait.text == "WAIT · 1 LEFT", "Echo does not refill HUD")
	var key = InputEventAction.new()
	key.action = "action_wait"
	key.pressed = true
	game._unhandled_input(key)
	check(sim.get_remaining_wait_actions() == 0 and game.btn_wait.disabled and game.wait_meter.value == 0, "Keyboard consumes remaining allowance")
	var before: Dictionary = sim.get_turn_snapshot()
	game._unhandled_input(key)
	game.btn_wait.pressed.emit()
	check(sim.get_turn_snapshot() == before and game.wait_feedback.visible, "Keyboard and forced button signal blocked with feedback")
	var touch = InputEventScreenTouch.new()
	touch.pressed = true
	game.btn_wait.gui_input.emit(touch)
	check(sim.get_turn_snapshot() == before, "Disabled touch cannot advance")
	game._toggle_pause()
	game._unhandled_input(key)
	game._toggle_pause()
	check(sim.get_turn_snapshot() == before, "Pause cannot refill or spend allowance")
	game.btn_hint.pressed.emit()
	game._unhandled_input(key)
	game.btn_close_hint.pressed.emit()
	check(sim.get_turn_snapshot() == before, "Hints cannot refill or spend allowance")
	game._toggle_pause()
	game.btn_modal_transmission.pressed.emit()
	game._unhandled_input(key)
	game.btn_close_comm_log.pressed.emit()
	game.btn_resume.pressed.emit()
	check(sim.get_turn_snapshot() == before, "Communication log cannot refill allowance")
	game.propagate_notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
	check(sim.get_turn_snapshot() == before, "Application resume cannot refill allowance")
	for resolution in [Vector2i(360, 640), Vector2i(360, 800), Vector2i(390, 844), Vector2i(412, 915), Vector2i(432, 960)]:
		root.size = resolution
		for i in range(5): await process_frame
		for control in [game.btn_wait, game.wait_feedback, game.btn_restart, game.btn_clear_echoes]:
			check(game.get_viewport_rect().encloses(control.get_global_rect()), "Exhausted WAIT control fits %s: %s" % [resolution, control.name])
		check(game.wait_feedback.get_global_rect().end.y <= game.btn_restart.get_global_rect().position.y, "WAIT feedback does not overlap restart")
	sim.restart_attempt()
	check(game.btn_wait.text == "WAIT · 1 LEFT" and not game.btn_wait.disabled, "Restart refreshes HUD")
	sim.clear_echoes()
	check(game.btn_wait.text == "WAIT · 2 LEFT", "Full reset refreshes HUD")
	game.queue_free()
	await process_frame

func _campaign() -> void:
	var solutions: Dictionary = load("res://tests/core/test_level_validation.gd")._get_verified_solutions()
	var registry = load("res://scripts/level/level_registry.gd")
	var validator = load("res://scripts/level/level_validator.gd")
	for i in range(10):
		var level: LevelDefinition = registry.get_level(i)
		var sim = Sim.new()
		var twin = Sim.new()
		sim.load_level(level)
		twin.load_level(level)
		var renderer = load("res://scripts/gameplay/board_renderer.gd").new()
		root.add_child(renderer)
		renderer.setup(sim, Vector2(720, 1280))
		var directions: Dictionary = {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
		for action in solutions[level.level_id]:
			var ok: bool = false
			if action == "ECHO":
				ok = sim.create_echo()
				twin.create_echo()
			elif action == "W":
				ok = sim.step_wait()
				twin.step_wait()
			else:
				ok = sim.step_move(directions[action])
				twin.step_move(directions[action])
			check(ok, "%s rejects verified action %s at turn %d" % [level.level_id, action, sim.current_turn])
			check(sim.get_turn_snapshot() == twin.get_turn_snapshot(), "Identical inputs resolve identical snapshots")
			check(sim.get_wait_actions_used() <= level.max_wait_actions, "Campaign stays within WAIT allowance")
			var positions: Array[Vector2i] = [sim.player_pos]
			for echo: EchoRecording in sim.echoes:
				if echo.is_active_at_turn(sim.current_turn):
					positions.append(echo.get_position_at_turn(sim.current_turn))
			for plate: Dictionary in level.plates_data:
				check(sim.is_plate_active(plate.id) == (plate.pos in positions), "Campaign plate occupancy resolved")
			for door: Dictionary in level.doors_data:
				var expected: bool = door.get("logic", "AND") == "AND"
				if door.get("logic", "AND") == "SEQUENCE":
					expected = sim.is_sequence_unlocked(door.id)
				else:
					for plate_id in door.get("required_plates", []):
						if door.get("logic", "AND") == "AND":
							expected = expected and sim.is_plate_active(plate_id)
						else:
							expected = expected or sim.is_plate_active(plate_id)
				if sim.player_pos == door.pos:
					expected = true
				check(sim.is_door_open(door.id) == expected, "Campaign door matches resolved occupancy and safety")
				check(renderer.door_anim_weights[door.id] == (1.0 if expected else 0.0), "Campaign gate presentation matches same turn")
		check(sim.is_completed and sim.echoes.size() == level.min_echoes_required, "Campaign legal exit with intended Echo count")
		check(sim.get_wait_actions_used() == [3, 2, 1, 2, 4, 4, 8, 8, 20, 9][i], "Campaign recorded WAIT total")
		var validation: Dictionary = validator.validate_level(level, solutions[level.level_id])
		check(validation.intended_solution_valid and (validation.sub_min_echoes_passed or level.level_id == "lvl_10" and validation.global_echo_status == "VIOLATED_BY_REPLAYED_WITNESS"), "Campaign intended solution valid and known bypass reported")
		print("[CAMPAIGN WAIT] %s: used=%d limit=%d remaining=%d" % [level.level_id, sim.get_wait_actions_used(), level.max_wait_actions, sim.get_remaining_wait_actions()])
		renderer.queue_free()
		await process_frame
	var tiny = fixture()
	tiny.max_wait_actions = 1
	var rejected: Dictionary = validator._replay_solution(tiny, ["W", "W"])
	check(not rejected.completed and "WAIT rejected" in rejected.error, "Validator fails an exhausted WAIT instead of skipping it")

func _run() -> void:
	await _door_reproduction()
	await _door_matrix()
	_entry_and_sequence()
	_wait_accounting()
	await _input_and_hud()
	await _campaign()
	print("TURN/WAIT REGRESSION: %d / %d passed" % [checks - failures, checks])
	quit(1 if failures else 0)
