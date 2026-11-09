extends Node

## Comprehensive in-engine screenshot generator for Tomorrow's You.
## Captures high-resolution 720x1280 portrait screenshots of all 10 major game screens.

const SCREENS = [
	"01_main_menu",
	"02_credits",
	"03_difficulty_select_easy",
	"04_difficulty_select_nightmare",
	"05_level_select",
	"06_settings",
	"07_gameplay_playing",
	"08_gameplay_paused",
	"09_gameplay_hint_panel",
	"10_gameplay_level_complete"
]

func _ready() -> void:
	get_window().size = Vector2i(720, 1280)
	print("\n=======================================================")
	print(" CAPTURING ALL 10 IN-ENGINE VISUAL SCREENSHOTS (720x1280)")
	print("=======================================================")

	_capture_sequence()

func _capture_sequence() -> void:
	# 1. Main Menu
	print("\n[1/10] Capturing Main Menu...")
	var main_menu = load("res://scenes/menus/main_menu.tscn").instantiate()
	add_child(main_menu)
	await _wait_frames(10)
	_save_screen("01_main_menu.png")

	# 2. Credits
	print("\n[2/10] Capturing Credits...")
	main_menu.credits_button.pressed.emit()
	await _wait_frames(10)
	_save_screen("02_credits.png")
	main_menu.queue_free()
	await _wait_frames(3)

	# 3. Difficulty Select (Tier 1 Easy)
	print("\n[3/10] Capturing Difficulty Select (Easy)...")
	SaveManager.selected_difficulty_tier = 1
	var diff_select = load("res://scenes/menus/difficulty_select.tscn").instantiate()
	add_child(diff_select)
	await _wait_frames(10)
	_save_screen("03_difficulty_select_easy.png")

	# 4. Difficulty Select (Tier 5 Nightmare)
	print("\n[4/10] Capturing Difficulty Select (Nightmare)...")
	if diff_select.background:
		diff_select.background.set_difficulty_tier(5)
	await _wait_frames(10)
	_save_screen("04_difficulty_select_nightmare.png")
	diff_select.queue_free()
	await _wait_frames(3)

	# 5. Level Select
	print("\n[5/10] Capturing Level Select...")
	SaveManager.selected_difficulty_tier = 1
	var lvl_select = load("res://scenes/menus/level_select.tscn").instantiate()
	add_child(lvl_select)
	await _wait_frames(10)
	_save_screen("05_level_select.png")
	lvl_select.queue_free()
	await _wait_frames(3)

	# 6. Settings
	print("\n[6/10] Capturing Settings...")
	var settings = load("res://scenes/menus/settings.tscn").instantiate()
	add_child(settings)
	await _wait_frames(10)
	_save_screen("06_settings.png")
	settings.queue_free()
	await _wait_frames(3)

	# 7. Gameplay (Playing Level 1)
	print("\n[7/10] Capturing Gameplay (Playing)...")
	GameManager.select_level(0)
	var gameplay = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	add_child(gameplay)
	# Play 1 move to show live gameplay status
	var sim = GameManager.current_simulation
	sim.step_move(Vector2i.DOWN)
	await _wait_frames(10)
	_save_screen("07_gameplay_playing.png")

	# 8. Gameplay (Paused)
	print("\n[8/10] Capturing Gameplay (Paused)...")
	gameplay.pause_button.pressed.emit()
	await _wait_frames(10)
	_save_screen("08_gameplay_paused.png")
	gameplay.pause_button.pressed.emit() # unpause
	await _wait_frames(3)

	# 9. Gameplay (Hint Panel)
	print("\n[9/10] Capturing Gameplay (Hint Panel)...")
	gameplay.btn_hint.pressed.emit()
	await _wait_frames(10)
	_save_screen("09_gameplay_hint_panel.png")
	gameplay.btn_close_hint.pressed.emit() # close hint
	await _wait_frames(3)

	# 10. Gameplay (Level Complete)
	print("\n[10/10] Capturing Gameplay (Level Complete)...")
	sim.create_echo()
	sim.complete_level()
	await _wait_frames(10)
	_save_screen("10_gameplay_level_complete.png")
	gameplay.queue_free()
	await _wait_frames(3)

	print("\n=======================================================")
	print(" ALL 10 SCREENSHOTS CAPTURED SUCCESSFULLY! ")
	print("=======================================================")
	get_tree().quit(0)

func _wait_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _save_screen(filename: String) -> void:
	var vp: Viewport = get_viewport()
	var img: Image = vp.get_texture().get_image()
	if img:
		var path: String = "screenshots/" + filename
		var err = img.save_png(path)
		if err == OK:
			print("  [✓] Saved: %s (%dx%d)" % [path, img.get_width(), img.get_height()])
		else:
			push_error("Failed to save: " + path)
	else:
		push_error("Viewport texture is null for: " + filename)
