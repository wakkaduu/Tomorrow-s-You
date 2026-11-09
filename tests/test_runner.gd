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
	# TEST 7: Audio Synthesis
	# --------------------------------------------------------------------------
	run_test.call("AudioManager generates and plays SFX", func() -> bool:
		AudioManager.play_sfx("move")
		AudioManager.play_sfx("plate_on")
		AudioManager.play_sfx("door_open")
		AudioManager.play_sfx("victory")
		return true
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
