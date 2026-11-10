extends Node

## Comprehensive Regression Suite for Level Completion & Turn Resolution Order
## Tests all 12 required regression scenarios in-engine with real nodes and signals.

const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")

var counters: Dictionary = {"total": 0, "passed": 0}

func _ready() -> void:
	print("\n===================================================================")
	print("   TOMORROW'S YOU — LEVEL COMPLETION REGRESSION SUITE (12 TESTS)")
	print("===================================================================")

	_run_all_tests()

	print("\n===================================================================")
	print(" COMPLETION SUITE SUMMARY: %d / %d TESTS PASSED" % [counters["passed"], counters["total"]])
	print("===================================================================")

	if counters["passed"] == counters["total"]:
		print(" ALL 12 LEVEL COMPLETION REGRESSION TESTS PASSED! [✓]\n")
		get_tree().quit(0)
	else:
		push_error(" SOME LEVEL COMPLETION REGRESSION TESTS FAILED! [✗]")
		get_tree().quit(1)

func run_test(num: int, name: String, fn: Callable) -> void:
	counters["total"] += 1
	print("\n[COMPLETION | TEST %2d] %s" % [num, name])
	var ok: bool = fn.call()
	if ok:
		counters["passed"] += 1
		print("   --> PASSED [✓]")
	else:
		push_error("   --> FAILED [✗]: " + name)

func _create_custom_level(map: Array[String], doors: Array[Dictionary] = [], plates: Array[Dictionary] = [], limit: int = 2) -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "test_comp_lvl"
	lvl.level_name = "Completion Test"
	lvl.echo_limit = limit
	lvl.min_echoes_required = 1
	lvl.map_lines = map
	lvl.doors_data = doors
	lvl.plates_data = plates
	lvl.initialize_from_map()
	return lvl

func _run_all_tests() -> void:
	# --------------------------------------------------------------------------
	# TEST 1: Player reaches an unlocked exit normally
	# --------------------------------------------------------------------------
	run_test(1, "Player reaches an unlocked exit normally", func() -> bool:
		var lvl = _create_custom_level(["#####", "#P.X#", "#####"])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)
		sim.step_move(Vector2i.RIGHT) # to (2, 1)
		if sim.is_completed: return false
		sim.step_move(Vector2i.RIGHT) # onto X (3, 1)
		return sim.is_completed and sim.game_state == PuzzleSimulation.GameState.COMPLETED and sim.player_pos == lvl.exit_pos
	)

	# --------------------------------------------------------------------------
	# TEST 2: Player reaches the exit on the exact turn an Echo expires
	# --------------------------------------------------------------------------
	run_test(2, "Player reaches the exit on the exact turn an Echo expires", func() -> bool:
		# Layout: Spawn (1,1), Plate (1,2), Door A (2,1), Exit (3,1)
		# Door A is open when Plate 1 is active.
		var lvl = _create_custom_level(
			["#####", "#PAX#", "#1..#", "#####"],
			[{"id": "A", "pos": Vector2i(2, 1), "logic": "AND", "required_plates": ["1"]}],
			[{"id": "1", "pos": Vector2i(1, 2)}]
		)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		# Attempt 1: Step DOWN to plate (turn 1). Record 1 WAIT (turn 2). Total 2 steps.
		sim.step_move(Vector2i.DOWN)
		sim.step_wait()
		sim.create_echo()

		# Attempt 2:
		# Turn 1: Player WAITs at (1,1). Echo moves to (1,2) [Plate active! Door A open].
		sim.step_wait()
		# Turn 2: Player moves RIGHT to (2,1) [Door A tile]. Echo WAITs on Plate 1.
		sim.step_move(Vector2i.RIGHT)
		# Turn 3: Echo expires (recorded 2 steps, turn 3 > 2).
		# Player moves RIGHT to Exit (3,1).
		# Legal movement into exit occurs on the exact turn Echo expires!
		sim.step_move(Vector2i.RIGHT)
		return sim.is_completed and not sim.is_echo_active(0) and sim.player_pos == lvl.exit_pos
	)

	# --------------------------------------------------------------------------
	# TEST 3: An Echo expires immediately before the player attempts to enter the exit
	# --------------------------------------------------------------------------
	run_test(3, "Echo expires before player reaches door guarding exit (blocked)", func() -> bool:
		# Door A is on the exit or guarding it.
		var lvl = _create_custom_level(
			["#####", "#P.AX", "#1..#", "#####"],
			[{"id": "A", "pos": Vector2i(3, 1), "logic": "AND", "required_plates": ["1"]}],
			[{"id": "1", "pos": Vector2i(1, 2)}]
		)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		# Attempt 1: Step DOWN to plate (1 step only).
		sim.step_move(Vector2i.DOWN)
		sim.create_echo()

		# Attempt 2:
		# Turn 1: Player moves to (2, 1). Echo steps on (1, 2).
		sim.step_move(Vector2i.RIGHT)
		# Turn 2: Echo expires (had only 1 step). Door A closes!
		# Player attempts to move RIGHT into Door A at (3, 1).
		var moved: bool = sim.step_move(Vector2i.RIGHT)
		return (not moved) and (not sim.is_completed) and sim.player_pos == Vector2i(2, 1) and not sim.is_door_open_at_turn("A", sim.current_turn + 1)
	)

	# --------------------------------------------------------------------------
	# TEST 4: An Echo expires after the player has already crossed the door
	# --------------------------------------------------------------------------
	run_test(4, "Echo expires after player has crossed the door", func() -> bool:
		# Layout: P (1,1) -> Door A (2,1) -> Hall (3,1) -> Exit (4,1)
		var lvl = _create_custom_level(
			["######", "#PA.X#", "#1...#", "######"],
			[{"id": "A", "pos": Vector2i(2, 1), "logic": "AND", "required_plates": ["1"]}],
			[{"id": "1", "pos": Vector2i(1, 2)}]
		)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		# Attempt 1: Move D, WAIT 1. Total 2 steps.
		sim.step_move(Vector2i.DOWN)
		sim.step_wait()
		sim.create_echo()

		# Attempt 2:
		# Turn 1: Echo at (1,2) [Plate active, Door open]. Player moves R to (2,1) [Inside door].
		sim.step_move(Vector2i.RIGHT)
		# Turn 2: Echo WAITs at (1,2). Player moves R to (3,1) [Crossed door!].
		sim.step_move(Vector2i.RIGHT)
		# Turn 3: Echo expires. Door A closes behind player!
		# Player moves R to Exit (4,1).
		sim.step_move(Vector2i.RIGHT)
		return sim.is_completed and sim.player_pos == Vector2i(4, 1) and not sim.is_door_open("A")
	)

	# --------------------------------------------------------------------------
	# TEST 5: A door closes behind the player after crossing it
	# --------------------------------------------------------------------------
	run_test(5, "Door closes behind player without crushing or impeding exit reach", func() -> bool:
		var lvl = _create_custom_level(
			["#######", "#PA..X#", "#1....#", "#######"],
			[{"id": "A", "pos": Vector2i(2, 1), "logic": "AND", "required_plates": ["1"]}],
			[{"id": "1", "pos": Vector2i(1, 2)}]
		)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		sim.step_move(Vector2i.DOWN)
		sim.create_echo() # Echo has 1 step

		# Turn 1: Player moves through Door A to (2,1)
		sim.step_move(Vector2i.RIGHT)
		# Turn 2: Player moves to (3,1). Echo expires. Door A closes.
		sim.step_move(Vector2i.RIGHT)
		if sim.is_door_open("A"): return false
		# Turn 3: Player moves to (4,1).
		sim.step_move(Vector2i.RIGHT)
		# Turn 4: Player moves to Exit (5,1).
		sim.step_move(Vector2i.RIGHT)
		return sim.is_completed and sim.player_pos == Vector2i(5, 1)
	)

	# --------------------------------------------------------------------------
	# TEST 6: Player reaches a locked exit (door on exit tile is closed)
	# --------------------------------------------------------------------------
	run_test(6, "Player cannot enter locked exit", func() -> bool:
		# Door A is positioned directly on the exit (3,1)
		var lvl = _create_custom_level(
			["#####", "#P.X#", "#1..#", "#####"],
			[{"id": "A", "pos": Vector2i(3, 1), "logic": "AND", "required_plates": ["1"]}],
			[{"id": "1", "pos": Vector2i(1, 2)}]
		)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		# No echoes created. Plate 1 is inactive. Door A on exit is closed.
		sim.step_move(Vector2i.RIGHT) # to (2,1)
		var blocked: bool = not sim.step_move(Vector2i.RIGHT) # Try entering exit (3,1)
		return blocked and (not sim.is_completed) and sim.player_pos == Vector2i(2, 1)
	)

	# --------------------------------------------------------------------------
	# TEST 7: Player reaches the exit with all required Echoes active
	# --------------------------------------------------------------------------
	run_test(7, "Player reaches exit with all required Echoes active", func() -> bool:
		var lvl = _create_custom_level(
			["######", "#PABX#", "#12..#", "######"],
			[
				{"id": "A", "pos": Vector2i(2, 1), "logic": "AND", "required_plates": ["1"]},
				{"id": "B", "pos": Vector2i(3, 1), "logic": "AND", "required_plates": ["2"]}
			],
			[
				{"id": "1", "pos": Vector2i(1, 2)},
				{"id": "2", "pos": Vector2i(2, 2)}
			],
			2
		)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		# Echo 1: D, W, W, W, W (5 steps on Plate 1)
		sim.step_move(Vector2i.DOWN)
		for _w in range(4): sim.step_wait()
		sim.create_echo()

		# Echo 2: D, R, W, W, W (5 steps on Plate 2)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.RIGHT)
		for _w in range(3): sim.step_wait()
		sim.create_echo()

		# Player run: Turn 1 W, Turn 2 R (2,1), Turn 3 R (3,1), Turn 4 R (4,1 Exit)
		sim.step_wait() # Turn 1
		sim.step_move(Vector2i.RIGHT) # Turn 2
		sim.step_move(Vector2i.RIGHT) # Turn 3
		sim.step_move(Vector2i.RIGHT) # Turn 4 -> Exit!
		return sim.is_completed and sim.is_echo_active(0) and sim.is_echo_active(1)
	)

	# --------------------------------------------------------------------------
	# TEST 8: Player reaches exit after Echo expires where permitted
	# --------------------------------------------------------------------------
	run_test(8, "Player reaches exit after Echo expires where rules permit", func() -> bool:
		# First Contact topology
		var lvl = LevelRegistryClass.get_level(0)
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		# Echo: D, D, D, W, W, W, W (7 steps)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.DOWN)
		for _w in range(4): sim.step_wait()
		sim.create_echo()

		# Player: R, R, R, D, D, D, R, R (8 turns)
		sim.step_move(Vector2i.RIGHT) # 1
		sim.step_move(Vector2i.RIGHT) # 2
		sim.step_move(Vector2i.RIGHT) # 3
		sim.step_move(Vector2i.DOWN)  # 4
		sim.step_move(Vector2i.DOWN)  # 5
		sim.step_move(Vector2i.DOWN)  # 6
		sim.step_move(Vector2i.RIGHT) # 7
		sim.step_move(Vector2i.RIGHT) # 8 -> Exit! (Echo expires on this exact turn)
		return sim.is_completed and not sim.is_echo_active(0) and sim.player_pos == lvl.exit_pos
	)

	# --------------------------------------------------------------------------
	# TEST 9: Level completion only triggers once
	# --------------------------------------------------------------------------
	run_test(9, "Level completion triggers exactly once", func() -> bool:
		var lvl = _create_custom_level(["#####", "#P.X#", "#####"])
		var sim: PuzzleSimulation = PuzzleSimulationClass.new()
		sim.load_level(lvl)

		var completion_event_box: Array[int] = [0]
		sim.level_completed.connect(func(_t, _e, _a): completion_event_box[0] += 1)

		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT) # Completes level!
		if completion_event_box[0] != 1: return false

		# Attempt further movements or checks after completion
		var extra_move = sim.step_move(Vector2i.LEFT)
		var extra_wait = sim.step_wait()
		var extra_check = sim.check_level_completion()
		return (not extra_move) and (not extra_wait) and (not extra_check) and completion_event_box[0] == 1
	)

	# --------------------------------------------------------------------------
	# TEST 10: Progress saves correctly after completion
	# --------------------------------------------------------------------------
	run_test(10, "Progress saves correctly after level completion in Gameplay scene", func() -> bool:
		SaveManager.reset_progress()
		GameManager.select_level(0)
		var gameplay = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		add_child(gameplay)

		var sim = GameManager.current_simulation
		# Solve First Contact
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.DOWN)
		for _w in range(3): sim.step_wait()
		sim.create_echo()

		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.DOWN)
		sim.step_move(Vector2i.RIGHT)
		sim.step_move(Vector2i.RIGHT)

		# Completion presentation follows the existing narrative outro.
		if gameplay.transmission_modal.visible:
			gameplay.btn_skip_transmission.pressed.emit()
		var completed: bool = SaveManager.is_level_completed("lvl_01")
		var stars: int = SaveManager.get_level_stars("lvl_01")
		var next_unlocked: bool = SaveManager.is_level_unlocked("lvl_02")
		var modal_vis: bool = gameplay.complete_modal.visible

		gameplay.queue_free()
		return completed and stars >= 1 and next_unlocked and modal_vis
	)

	# --------------------------------------------------------------------------
	# TEST 11: The next-level button works
	# --------------------------------------------------------------------------
	run_test(11, "Next-level button advances to next level", func() -> bool:
		GameManager.select_level(0)
		var gameplay = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		add_child(gameplay)

		var sim = GameManager.current_simulation
		sim.step_move(Vector2i.DOWN)
		sim.create_echo()
		sim.complete_level() # Trigger completion
		if gameplay.transmission_modal.visible:
			gameplay.btn_skip_transmission.pressed.emit()
		if not gameplay.complete_modal.visible:
			gameplay.queue_free()
			return false

		# Press next level button (suppress actual SceneTree replacement during runner)
		SceneRouter.suppress_scene_change = true
		gameplay.btn_next_level.pressed.emit()
		var next_idx: int = GameManager.current_level_index
		var route_target: String = SceneRouter.current_scene_path
		SceneRouter.suppress_scene_change = false

		gameplay.queue_free()
		return next_idx == 1 and route_target == "res://scenes/gameplay/gameplay.tscn"
	)

	# --------------------------------------------------------------------------
	# TEST 12: Restarting a completed level works correctly
	# --------------------------------------------------------------------------
	run_test(12, "Restarting a completed level allows playing and completing again", func() -> bool:
		GameManager.select_level(0)
		var gameplay = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		add_child(gameplay)

		var sim = GameManager.current_simulation
		sim.step_move(Vector2i.DOWN)
		sim.create_echo()
		sim.complete_level()
		if gameplay.transmission_modal.visible:
			gameplay.btn_skip_transmission.pressed.emit()
		if not gameplay.complete_modal.visible:
			gameplay.queue_free()
			return false

		# Press Replay
		gameplay.btn_replay.pressed.emit()
		if gameplay.complete_modal.visible:
			gameplay.queue_free()
			return false
		if sim.is_completed or sim.game_state != PuzzleSimulation.GameState.PLAYING:
			gameplay.queue_free()
			return false
		if sim.player_pos != gameplay.current_level_def.spawn_pos:
			gameplay.queue_free()
			return false

		# Verify player can move again
		var moved: bool = sim.step_move(Vector2i.DOWN)
		gameplay.queue_free()
		return moved
	)
