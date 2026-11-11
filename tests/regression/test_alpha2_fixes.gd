extends Node

var failures: int = 0
var checks: int = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("[FAIL] ", label)
	else:
		print("[PASS] ", label)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	test_scoring()
	test_resize()
	await test_navigation()
	print("ALPHA2 REGRESSION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func solve_first(sim: PuzzleSimulation) -> void:
	for _i in range(3): check(sim.step_move(Vector2i.DOWN), "Recording move accepted")
	for _i in range(3): check(sim.step_wait(), "Recording WAIT accepted")
	check(sim.total_actions_taken == 6, "Uncommitted recording counts once")
	check(sim.create_echo(), "Echo committed")
	check(sim.committed_echo_actions == 6 and sim.current_attempt_actions == 0 and sim.total_actions_taken == 6, "Commit transfers recording without double counting")
	for c: String in "DRRRDDRR":
		check(sim.step_move(Vector2i.DOWN if c == "D" else Vector2i.RIGHT), "Winning move accepted")
	check(sim.is_completed and sim.total_actions_taken == 14, "Current solution scores exactly 14 actions")

func test_scoring() -> void:
	var sim := PuzzleSimulation.new()
	sim.load_level(LevelRegistry.get_level(0))
	check(sim.step_move(Vector2i.DOWN), "Discardable action accepted")
	sim.restart_attempt()
	check(sim.total_actions_taken == 0 and sim.current_turn == 0, "Restart refunds discarded current-attempt score")
	solve_first(sim)
	sim.clear_echoes()
	check(sim.total_actions_taken == 0 and sim.echoes.is_empty(), "Completed-level replay starts independent run")
	solve_first(sim)
	sim.restart_attempt()
	check(sim.total_actions_taken == 6 and sim.committed_echo_actions == 6, "Restart retains only committed Echo actions")
	sim.clear_echoes()
	check(sim.total_actions_taken == 0 and sim.get_remaining_wait_actions() == 3, "Clear All resets current run and WAIT accounting")
	var sm = load("res://scripts/autoload/save_manager.gd").new()
	sm.set_custom_save_path("user://alpha2-records.cfg")
	sm._set_default_save()
	sm.record_level_completion("lvl_01", 18, 1)
	sm.record_level_completion("lvl_01", 22, 1)
	check(sm.best_actions.lvl_01 == 18 and sm.level_records.lvl_01.actions == 18, "Worse replay preserves both historical best representations")
	sm.record_level_completion("lvl_01", 14, 1)
	check(sm.best_actions.lvl_01 == 14 and sm.level_records.lvl_01.actions == 14 and sm.best_stars.lvl_01 == 3, "Better replay updates best score and stars")
	sm.load_save()
	check(sm.save_version == 3 and sm.best_actions.lvl_01 == 14, "Best record persists in unchanged schema 3")
	sm.free()

func test_resize() -> void:
	var sim := PuzzleSimulation.new()
	sim.load_level(LevelRegistry.get_level(0))
	for _i in range(3): sim.step_move(Vector2i.DOWN)
	for _i in range(3): sim.step_wait()
	sim.create_echo()
	var board := BoardRenderer.new()
	add_child(board)
	board.setup(sim, Vector2(720, 1280))
	sim.step_move(Vector2i.DOWN)
	board._process(0.01) # Deliberately mid-animation.
	var snapshot: Dictionary = sim.get_turn_snapshot()
	var recording: Array = sim.current_recording.steps.duplicate(true)
	var fraction: Vector2 = (board.player_visual_pos - board.board_offset) / board.tile_size
	var trail_fraction: Vector2 = (board.echo_trail_points[0][0] - board.board_offset) / board.tile_size
	for size: Vector2 in [Vector2(720, 1600), Vector2(360, 640), Vector2(1080, 2400), Vector2(720, 1280)]:
		board.calculate_layout(size)
		check(board.player_target_pos.is_equal_approx(board.grid_to_world(sim.player_pos)), "Player target follows resized grid %s" % size)
		check(board.echo_target_positions[0].is_equal_approx(board.grid_to_world(sim.get_echo_position(0))), "Echo target follows resized grid")
		check(((board.player_visual_pos - board.board_offset) / board.tile_size).is_equal_approx(fraction), "In-flight player interpolation preserves fractional cell")
		check(((board.echo_trail_points[0][0] - board.board_offset) / board.tile_size).is_equal_approx(trail_fraction), "Echo trail uses same resized transform")
		check(sim.get_turn_snapshot() == snapshot and sim.current_recording.steps == recording, "Resize preserves turn, grid positions, doors, plates and recording")
	board._process(1.0)
	check(board.player_visual_pos.is_equal_approx(board.grid_to_world(sim.player_pos)), "Animation settles at new endpoint without stale position or overshoot")
	for _i in range(2): sim.step_move(Vector2i.DOWN)
	board._process(1.0)
	snapshot = sim.get_turn_snapshot()
	board.calculate_layout(Vector2(720, 1600))
	check(sim.plates_state.values().has(true) and sim.get_turn_snapshot() == snapshot, "Resize with occupied plate preserves simulation")
	check(board.echo_visual_positions[0].is_equal_approx(board.grid_to_world(sim.get_echo_position(0))), "Stationary Echo stays aligned on occupied plate")
	board.free()

func mount(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	return scene

func back() -> void:
	AndroidSystemManager.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().process_frame
	await get_tree().process_frame

func dispose(scene: Node) -> void:
	get_tree().current_scene = self
	scene.free()

func test_navigation() -> void:
	check(not get_tree().quit_on_go_back and not ProjectSettings.get_setting("application/config/quit_on_go_back"), "Engine automatic Back exit disabled")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method.android") == "gl_compatibility", "Android selects Compatibility without player intervention")
	GameManager.select_level(0)
	var game = mount("res://scenes/gameplay/gameplay.tscn")
	check(game.background.has_node("ShaderEnvironment") and game.background.get_node("ShaderEnvironment").material != null, "Custom temporal shader and background layers retained")
	if game.transmission_modal.visible:
		var tid: String = game._active_transmission.id
		check(not SaveManager.is_transmission_viewed(tid), "Showing MORROW does not mark it viewed")
		await back()
		check(not game.transmission_modal.visible and SaveManager.is_transmission_viewed(tid), "Back follows existing transmission Skip/viewed policy")
	var snapshot: Dictionary = game.simulation.get_turn_snapshot()
	AndroidSystemManager.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	AndroidSystemManager.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().process_frame
	await get_tree().process_frame
	check(game.pause_modal.visible, "Duplicate delivery in one frame produces one Pause action")
	game.btn_down.pressed.emit()
	game.btn_wait.pressed.emit()
	check(game.simulation.get_turn_snapshot() == snapshot, "Paused gameplay rejects moves and WAIT without advancing Echoes")
	await back()
	check(not game.pause_modal.visible, "Back from Pause resumes")
	game._open_hint_modal()
	var credits: int = SaveManager.get_remaining_daily_hints()
	await back()
	check(not game.hint_modal.visible and SaveManager.get_remaining_daily_hints() == credits, "Back closes Hint without charging credits")
	game.simulation.step_move(Vector2i.DOWN)
	await back()
	SceneRouter.go_to_settings()
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().current_scene.scene_file_path.ends_with("settings.tscn"), "Settings opens from paused gameplay")
	await back()
	check(get_tree().current_scene == game and game.simulation.current_turn == 1 and game.pause_modal.visible, "Settings Back restores exact originating puzzle, still paused")
	SceneRouter.go_to_archive()
	await get_tree().process_frame
	await get_tree().process_frame
	var archive = get_tree().current_scene
	archive.reader_modal.visible = true
	await back()
	check(get_tree().current_scene == archive and not archive.reader_modal.visible, "Archive Back closes active reader first")
	await back()
	check(get_tree().current_scene == game and game.simulation.current_turn == 1, "Archive Back restores previous screen without resetting puzzle")
	# Resize with Pause open uses the same layout path without touching the run.
	snapshot = game.simulation.get_turn_snapshot()
	game.board_renderer.calculate_layout(Vector2(720, 1600))
	check(game.pause_modal.visible and game.simulation.get_turn_snapshot() == snapshot, "Resizing paused puzzle preserves all gameplay state")
	dispose(game)
	var levels = mount("res://scenes/menus/level_select.tscn")
	await back()
	await get_tree().process_frame
	check(get_tree().current_scene.scene_file_path.ends_with("difficulty_select.tscn"), "Level selection Back routes to difficulty")
	await back()
	await get_tree().process_frame
	var menu = get_tree().current_scene
	check(menu.scene_file_path.ends_with("main_menu.tscn"), "Difficulty Back routes to Main Menu")
	menu._on_credits_pressed()
	await back()
	check(not menu.credits_popup.visible and menu.get_node("VBoxContainer").visible, "Back closes Credits and restores Main Menu")
	await back()
	check(menu.exit_confirmation.visible, "Main Menu Back requires explicit exit confirmation")
	await back()
	check(not menu.exit_confirmation.visible and is_instance_valid(menu), "Back cancels exit without terminating application")
	dispose(menu)
