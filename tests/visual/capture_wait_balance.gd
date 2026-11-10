extends SceneTree
## Rendered QA for Sequential Relay's optimized WAIT budget and generated hint.
func _init() -> void:
	call_deferred("_run")
func capture(name: String) -> void:
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var path: String = "user://qa/" + name + ".png"
	if root.get_texture().get_image().save_png(path) != OK:
		quit(1)
	print("[BALANCE SCREENSHOT] ", ProjectSettings.globalize_path(path))
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://qa")
	root.size = Vector2i(360, 640)
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var sm = root.get_node("SaveManager")
	var narrative = load("res://scripts/narrative/narrative_registry.gd")
	for trans in narrative.get_all_transmissions(): sm.viewed_transmissions.append(trans.id)
	root.get_node("GameManager").select_level(3)
	var game = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	root.add_child(game)
	await capture("relay_wait_2")
	game.btn_wait.pressed.emit()
	game.btn_wait.pressed.emit()
	await capture("relay_wait_0")
	sm.level_hint_progress["lvl_04"] = 2
	game.btn_hint.pressed.emit()
	await capture("relay_verified_hint")
	game.queue_free()
	await process_frame
	quit(0)
