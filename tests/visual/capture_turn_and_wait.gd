extends SceneTree

## Rendered desktop QA. Use an isolated XDG_DATA_HOME; images go to user://qa/.
func _init() -> void:
	call_deferred("_run")

func capture(filename: String) -> void:
	for i in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = "user://qa/" + filename
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Screenshot failed: " + path)
		quit(1)
	print("[QA SCREENSHOT] ", ProjectSettings.globalize_path(path))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://qa")
	root.size = Vector2i(360, 640)
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var sm = root.get_node("SaveManager")
	sm.viewed_transmissions.append("tr_lvl_01_intro")
	root.get_node("GameManager").select_level(0)
	var game = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	root.add_child(game)
	var sim = game.simulation
	for i in range(3): sim.step_move(Vector2i.DOWN)
	for i in range(3): sim.step_wait()
	sim.create_echo()
	for i in range(3): sim.step_move(Vector2i.RIGHT)
	for i in range(2): sim.step_move(Vector2i.DOWN)
	await capture("01_door_open.png")
	sim.step_move(Vector2i.UP)
	await capture("02_door_next_shut.png")
	sim.step_move(Vector2i.DOWN)
	await capture("03_door_closed.png")
	while sim.get_remaining_wait_actions() > 0: sim.step_wait()
	await capture("04_wait_exhausted.png")
	game.queue_free()
	await process_frame
	quit(0)
