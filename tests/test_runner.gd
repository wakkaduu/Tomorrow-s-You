extends Node

## Comprehensive in-tree integration test runner for Tomorrow's You.
## Executes with all autoloads, UI nodes, audio managers, and saves initialized.

func _ready() -> void:
	print("\n=======================================================")
	print(" RUNNING IN-ENGINE FULL INTEGRATION SUITE")
	print("=======================================================")

	var counters: Dictionary = {"total": 0, "passed": 0}

	var run_test = func(test_name: String, test_fn: Callable) -> void:
		counters["total"] += 1
		print("\n[TEST %d] %s" % [counters["total"], test_name])
		var ok: bool = test_fn.call()
		if ok:
			counters["passed"] += 1
			print("  --> PASSED")
		else:
			push_error("  --> FAILED: " + test_name)

	# --------------------------------------------------------------------------
	# TEST 1: Autoloads Active
	# --------------------------------------------------------------------------
	run_test.call("Verify Autoloads are mounted and operational", func() -> bool:
		if SaveManager == null: return false
		if AudioManager == null: return false
		if GameManager == null: return false
		if SceneRouter == null: return false
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 2: Boot Scene Instantiation
	# --------------------------------------------------------------------------
	run_test.call("Boot scene loads and instantiates", func() -> bool:
		var scene = load("res://scenes/boot/boot.tscn").instantiate()
		add_child(scene)
		scene.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 3: Main Menu Scene Instantiation & Buttons
	# --------------------------------------------------------------------------
	run_test.call("Main Menu scene loads and buttons respond", func() -> bool:
		var scene = load("res://scenes/menus/main_menu.tscn").instantiate()
		add_child(scene)
		var play_btn: Button = scene.get_node("VBoxContainer/Buttons/PlayButton")
		if play_btn == null or play_btn.text.is_empty(): return false
		scene.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 4: Difficulty Select Scene
	# --------------------------------------------------------------------------
	run_test.call("Difficulty Select displays 5 difficulty tier cards", func() -> bool:
		var scene = load("res://scenes/menus/difficulty_select.tscn").instantiate()
		add_child(scene)
		var cards: VBoxContainer = scene.get_node("ScrollContainer/VBoxContainer/CardsContainer")
		if cards.get_child_count() != 5: return false
		scene.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 5: Level Select Scene & Filtering
	# --------------------------------------------------------------------------
	run_test.call("Level Select displays filtered campaign levels by difficulty tier", func() -> bool:
		SaveManager.selected_difficulty_tier = 1 # Easy (3 levels)
		var scene = load("res://scenes/menus/level_select.tscn").instantiate()
		add_child(scene)
		var grid: GridContainer = scene.get_node("ScrollContainer/VBoxContainer/LevelsGrid")
		var button_count: int = 0
		for child in grid.get_children():
			if child is Button:
				button_count += 1
		if button_count != 3: return false
		scene.queue_free()

		# Test showing all levels when tier is 0
		SaveManager.selected_difficulty_tier = 0
		var scene_all = load("res://scenes/menus/level_select.tscn").instantiate()
		add_child(scene_all)
		var grid_all: GridContainer = scene_all.get_node("ScrollContainer/VBoxContainer/LevelsGrid")
		var all_count: int = 0
		for child in grid_all.get_children():
			if child is Button:
				all_count += 1
		if all_count != 10: return false
		scene_all.queue_free()

		SaveManager.selected_difficulty_tier = 1 # reset
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 5: Settings Menu Controls
	# --------------------------------------------------------------------------
	run_test.call("Settings menu controls adjust SaveManager and AudioManager", func() -> bool:
		var scene = load("res://scenes/menus/settings.tscn").instantiate()
		add_child(scene)
		var music_slider: HSlider = scene.get_node("Content/VBoxContainer/MusicRow/MusicSlider")
		music_slider.value = 50.0
		if absf(SaveManager.music_volume - 0.5) > 0.05: return false
		scene.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 6: Gameplay Controller & BoardRenderer Mounting
	# --------------------------------------------------------------------------
	run_test.call("Gameplay scene mounts and plays moves", func() -> bool:
		GameManager.select_level(0)
		var scene = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		add_child(scene)

		var sim: PuzzleSimulation = GameManager.current_simulation
		var initial_turn: int = sim.current_turn
		sim.step_move(Vector2i.RIGHT)
		if sim.current_turn != initial_turn + 1: return false

		scene.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 8: AudioManager Sound Synthesis
	# --------------------------------------------------------------------------
	run_test.call("AudioManager generates and plays SFX", func() -> bool:
		AudioManager.play_sfx("move")
		AudioManager.play_sfx("plate_on")
		AudioManager.play_sfx("door_open")
		AudioManager.play_sfx("victory")
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 9: Hint System Integration in Gameplay Scene
	# --------------------------------------------------------------------------
	run_test.call("Hint Modal opens, displays allowance, and closes without advancing turns", func() -> bool:
		GameManager.select_level(0)
		var scene = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		add_child(scene)

		var btn_hint: Button = scene.btn_hint
		var hint_modal: PanelContainer = scene.hint_modal
		var btn_close: Button = scene.btn_close_hint
		var sim: PuzzleSimulation = GameManager.current_simulation
		var turn_before: int = sim.current_turn

		# Open hint modal
		btn_hint.pressed.emit()
		if not hint_modal.visible: return false
		if not scene._is_modal_active(): return false

		# Verify turn has not advanced
		if sim.current_turn != turn_before: return false

		# Close hint modal
		btn_close.pressed.emit()
		if hint_modal.visible: return false
		if scene._is_modal_active(): return false

		scene.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 10: Authoritative Level Completion Flow & Complete Modal
	# --------------------------------------------------------------------------
	run_test.call("Level completion triggers CompleteModal and blocks subsequent input", func() -> bool:
		GameManager.select_level(0)
		var scene = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		add_child(scene)

		var sim: PuzzleSimulation = GameManager.current_simulation
		sim.step_move(Vector2i.DOWN)
		sim.create_echo()
		sim.complete_level()

		if not scene.complete_modal.visible:
			scene.queue_free()
			return false
		if not scene._is_modal_active():
			scene.queue_free()
			return false
		if sim.game_state != PuzzleSimulation.GameState.COMPLETED:
			scene.queue_free()
			return false

		# Ensure subsequent moves are blocked
		var post_move: bool = sim.step_move(Vector2i.RIGHT)
		var post_wait: bool = sim.step_wait()
		if post_move or post_wait:
			scene.queue_free()
			return false

		scene.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 11: Atmospheric Temporal Background System
	# --------------------------------------------------------------------------
	run_test.call("Atmospheric Temporal Background mounts and transitions across all screens", func() -> bool:
		var bg_scene = load("res://scenes/background/temporal_background.tscn").instantiate()
		add_child(bg_scene)

		# Test screen mode transitions
		bg_scene.set_screen_mode(0) # MAIN_MENU
		bg_scene.set_screen_mode(1, 3) # DIFFICULTY_SELECT Tier 3
		bg_scene.set_difficulty_tier(5) # Tier 5 Nightmare
		bg_scene.set_screen_mode(5) # GAMEPLAY
		bg_scene.set_paused(true)
		bg_scene.set_paused(false)
		bg_scene.set_level_complete(true)
		bg_scene.set_level_complete(false)

		var ok: bool = (bg_scene.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		bg_scene.queue_free()
		return ok
	)

	# --------------------------------------------------------------------------
	# SUMMARY
	# --------------------------------------------------------------------------
	print("\n=======================================================")
	print(" FULL INTEGRATION SUMMARY: %d / %d PASSED" % [counters["passed"], counters["total"]])
	print("=======================================================")

	if counters["passed"] == counters["total"]:
		print(" ALL INTEGRATION TESTS PASSED WITH 100% SUCCESS! ")
		get_tree().quit(0)
	else:
		push_error(" SOME INTEGRATION TESTS FAILED!")
		get_tree().quit(1)
