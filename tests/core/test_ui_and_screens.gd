extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var SaveManagerClass = load("res://scripts/autoload/save_manager.gd")
	var AudioManagerClass = load("res://scripts/autoload/audio_manager.gd")
	print("\n=======================================================")
	print(" RUNNING TOMORROW'S YOU - UI & SCREEN TESTS")
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
	# TEST 1: Load and instantiate Boot Scene
	# --------------------------------------------------------------------------
	run_test.call("Boot scene loads and instantiates", func() -> bool:
		var scene: PackedScene = load("res://scenes/boot/boot.tscn")
		if scene == null: return false
		var inst = scene.instantiate()
		if inst == null: return false
		inst.free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 2: Load and instantiate Main Menu Scene
	# --------------------------------------------------------------------------
	run_test.call("Main Menu scene loads and instantiates", func() -> bool:
		var scene: PackedScene = load("res://scenes/menus/main_menu.tscn")
		if scene == null: return false
		var inst = scene.instantiate()
		if inst == null: return false
		inst.free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 3: Load and instantiate Level Select Scene
	# --------------------------------------------------------------------------
	run_test.call("Level Select scene loads and instantiates", func() -> bool:
		var scene: PackedScene = load("res://scenes/menus/level_select.tscn")
		if scene == null: return false
		var inst = scene.instantiate()
		if inst == null: return false
		inst.free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 4: Load and instantiate Settings Scene
	# --------------------------------------------------------------------------
	run_test.call("Settings scene loads and instantiates", func() -> bool:
		var scene: PackedScene = load("res://scenes/menus/settings.tscn")
		if scene == null: return false
		var inst = scene.instantiate()
		if inst == null: return false
		inst.free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 5: Load and instantiate Gameplay Scene
	# --------------------------------------------------------------------------
	run_test.call("Gameplay scene loads and instantiates", func() -> bool:
		var scene: PackedScene = load("res://scenes/gameplay/gameplay.tscn")
		if scene == null: return false
		var inst = scene.instantiate()
		if inst == null: return false
		inst.free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 6: SaveManager Persistence
	# --------------------------------------------------------------------------
	run_test.call("SaveManager save and load roundtrip", func() -> bool:
		var save_mgr = SaveManagerClass.new()
		save_mgr.record_level_completion("lvl_01", 12, 1, "lvl_02")
		if not save_mgr.is_level_completed("lvl_01"): return false
		if not save_mgr.is_level_unlocked("lvl_02"): return false
		if save_mgr.best_actions.get("lvl_01", 0) != 12: return false

		# Re-load from disk
		save_mgr.load_save()
		if not save_mgr.is_level_completed("lvl_01"): return false
		if not save_mgr.is_level_unlocked("lvl_02"): return false
		save_mgr.free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 7: AudioManager Sound Synthesis
	# --------------------------------------------------------------------------
	run_test.call("AudioManager sound synthesis and playback triggers", func() -> bool:
		var audio_mgr = AudioManagerClass.new()
		root.add_child(audio_mgr)
		audio_mgr.play_sfx("move")
		audio_mgr.play_sfx("wait")
		audio_mgr.play_sfx("echo_create")
		audio_mgr.play_sfx("plate_on")
		audio_mgr.play_sfx("plate_off")
		audio_mgr.play_sfx("door_open")
		audio_mgr.play_sfx("door_close")
		audio_mgr.play_sfx("blocked")
		audio_mgr.play_sfx("victory")
		audio_mgr.play_sfx("ui_click")
		audio_mgr.free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST SUMMARY
	# --------------------------------------------------------------------------
	print("\n=======================================================")
	print(" UI & SCREEN TEST SUMMARY: %d / %d PASSED" % [counters["passed"], counters["total"]])
	print("=======================================================")

	if counters["passed"] == counters["total"]:
		print(" ALL UI AND SCREEN TESTS PASSED! ")
		quit(0)
	else:
		push_error(" SOME UI TESTS FAILED!")
		quit(1)
