extends SceneTree

## Integration coverage for real containers at Android portrait aspect ratios.
## Run with an isolated XDG_DATA_HOME: existing autoloads persist narrative state.
const UI = preload("res://scripts/ui/components/ui_design_system.gd")
var failures: int = 0
var checks: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _settle() -> void:
	for i in range(5):
		await process_frame

func _run() -> void:
	var sm = root.get_node("SaveManager")
	var gm = root.get_node("GameManager")
	var registry = load("res://scripts/narrative/narrative_registry.gd")
	for tr in registry.get_all_transmissions():
		sm.unlocked_transmissions.append(tr.id)
		sm.viewed_transmissions.append(tr.id)
	for log_entry in registry.get_all_logs():
		sm.unlocked_logs.append(log_entry.id)
	for i in range(1, 11):
		sm.completed_levels.append("lvl_%02d" % i)
		sm.unlocked_levels.append("lvl_%02d" % i)
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	for resolution in [Vector2i(360, 640), Vector2i(360, 800), Vector2i(390, 844), Vector2i(412, 915), Vector2i(432, 960)]:
		root.size = resolution
		gm.select_level(0)
		var game = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		root.add_child(game)
		await _settle()
		var bounds = game.get_viewport_rect()
		for button in [game.btn_create_echo, game.btn_wait, game.btn_restart, game.btn_clear_echoes, game.btn_hint, game.btn_up, game.btn_left, game.btn_right, game.btn_down]:
			check(bounds.encloses(button.get_global_rect()), "%s: gameplay control clipped: %s" % [resolution, button.name])
		var board = game.board_renderer
		var board_bottom: float = board.board_offset.y + board.tile_size * board.level_def.grid_height
		check(board_bottom <= game.get_node("BottomHUD").get_global_rect().position.y, "Board overlaps gameplay controls at %s" % resolution)
		var turn: int = game.simulation.current_turn
		game.show_transmission(registry.get_opening_transmission("lvl_01"))
		await _settle()
		check(game.simulation.current_turn == turn, "Transmission advanced gameplay")
		game.queue_free()
		await _settle()
		var archive = load("res://scenes/menus/incident_archive.tscn").instantiate()
		root.add_child(archive)
		await _settle()
		for tab in range(4):
			archive._select_tab(tab)
			await _settle()
			check(archive.entries_list.get_child_count() == [12, 9, 4, 6][tab], "Archive entries missing in tab %d" % tab)
			check(archive.entries_list.size.x <= bounds.size.x, "%s: archive tab %d clips horizontally" % [resolution, tab])
		archive._select_tab(0)
		await _settle()
		var card = archive.entries_list.get_child(0)
		var action = card.get_child(0).get_child(3).get_child(0)
		action.pressed.emit()
		check(archive.reader_modal.visible, "View Transmission did not open reader")
		archive.btn_replay_reader.pressed.emit()
		check(archive.transmission_modal.visible, "Reader replay did not open transmission")
		archive.queue_free()
		await _settle()
	print("UI INTEGRATION: %d / %d passed" % [checks - failures, checks])
	quit(1 if failures else 0)
