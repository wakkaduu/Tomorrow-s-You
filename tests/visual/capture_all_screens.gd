extends Node

## Comprehensive in-engine screenshot generator for Tomorrow's You.
## Captures high-resolution 720x1280 portrait screenshots of all major game screens
## and cinematic transmission presentations.

const NarrativeRegistryClass = preload("res://scripts/narrative/narrative_registry.gd")

func _ready() -> void:
	get_window().size = Vector2i(720, 1280)
	print("\n=======================================================")
	print(" CAPTURING ALL CINEMATIC VISUAL SCREENSHOTS (720x1280)")
	print("=======================================================")

	_capture_sequence()

func _capture_sequence() -> void:
	# 1. Main Menu
	print("\n[1/16] Capturing Main Menu...")
	var main_menu = load("res://scenes/menus/main_menu.tscn").instantiate()
	add_child(main_menu)
	await _wait_frames(12)
	_save_screen("01_main_menu.png")

	# 2. Credits
	print("\n[2/16] Capturing Credits...")
	main_menu.credits_button.pressed.emit()
	await _wait_frames(12)
	_save_screen("02_credits.png")
	main_menu.queue_free()
	await _wait_frames(4)

	# 3. Difficulty Select (Tier 1 Easy)
	print("\n[3/16] Capturing Difficulty Select (Easy)...")
	SaveManager.selected_difficulty_tier = 1
	var diff_select = load("res://scenes/menus/difficulty_select.tscn").instantiate()
	add_child(diff_select)
	await _wait_frames(12)
	_save_screen("03_difficulty_select_easy.png")

	# 4. Difficulty Select (Tier 5 Nightmare)
	print("\n[4/16] Capturing Difficulty Select (Nightmare)...")
	if diff_select.background:
		diff_select.background.set_difficulty_tier(5)
	await _wait_frames(12)
	_save_screen("04_difficulty_select_nightmare.png")
	diff_select.queue_free()
	await _wait_frames(4)

	# 5. Level Select
	print("\n[5/16] Capturing Level Select...")
	SaveManager.selected_difficulty_tier = 1
	var lvl_select = load("res://scenes/menus/level_select.tscn").instantiate()
	add_child(lvl_select)
	await _wait_frames(12)
	_save_screen("05_level_select.png")
	lvl_select.queue_free()
	await _wait_frames(4)

	# 6. Settings
	print("\n[6/16] Capturing Settings...")
	var settings = load("res://scenes/menus/settings.tscn").instantiate()
	add_child(settings)
	await _wait_frames(12)
	_save_screen("06_settings.png")
	settings.queue_free()
	await _wait_frames(4)

	# 7. Incident Archive
	print("\n[7/16] Capturing Incident Archive...")
	var archive = load("res://scenes/menus/incident_archive.tscn").instantiate()
	add_child(archive)
	await _wait_frames(12)
	_save_screen("15_incident_archive.png")

	# 8. Archive Document Reader
	print("\n[8/16] Capturing Archive Document Reader...")
	var test_log = NarrativeRegistryClass.get_log("log_001")
	archive._open_reader(
		"LOG #001: %s" % test_log.get("title", ""),
		"Author: %s\nDate: %s\nClassification: %s" % [test_log.get("author", ""), test_log.get("date", ""), test_log.get("classification", "")],
		test_log.get("content", ""),
		"MERIDIAN RESEARCH LOG // RECOVERED",
		false,
		test_log
	)
	await _wait_frames(12)
	_save_screen("16_archive_document_reader.png")
	archive.queue_free()
	await _wait_frames(4)

	# 9. Gameplay (Playing Level 1)
	print("\n[9/16] Capturing Gameplay (Playing)...")
	GameManager.select_level(0)
	var gameplay = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	add_child(gameplay)
	# Dismiss opening transmission if showing
	if gameplay.transmission_modal and gameplay.transmission_modal.visible:
		gameplay.transmission_modal.visible = false
	var sim = GameManager.current_simulation
	sim.step_move(Vector2i.DOWN)
	await _wait_frames(12)
	_save_screen("07_gameplay_playing.png")

	# 10. Gameplay (Paused with Facility Terminal)
	print("\n[10/16] Capturing Gameplay (Paused)...")
	gameplay.pause_button.pressed.emit()
	await _wait_frames(12)
	_save_screen("08_gameplay_paused.png")

	# 11. Communication Log Modal
	print("\n[11/16] Capturing Communication Log Modal...")
	gameplay.btn_modal_transmission.pressed.emit()
	await _wait_frames(12)
	_save_screen("14_communication_log.png")
	gameplay.btn_close_comm_log.pressed.emit() # return to pause
	gameplay.btn_resume.pressed.emit() # resume
	await _wait_frames(4)

	# 12. Gameplay (Hint Panel)
	print("\n[12/16] Capturing Gameplay (Hint Panel)...")
	gameplay.btn_hint.pressed.emit()
	await _wait_frames(12)
	_save_screen("09_gameplay_hint_panel.png")
	gameplay.btn_close_hint.pressed.emit() # close hint
	await _wait_frames(4)

	# 13. Gameplay (Level Complete)
	print("\n[13/16] Capturing Gameplay (Level Complete)...")
	sim.create_echo()
	sim.complete_level()
	await _wait_frames(12)
	_save_screen("10_gameplay_level_complete.png")
	gameplay.complete_modal.visible = false
	await _wait_frames(4)

	# 14. Cinematic Transmission: EMERGENCY (Opening Level 1)
	print("\n[14/16] Capturing Cinematic Transmission (Emergency - Level 1)...")
	var tr1 = NarrativeRegistryClass.get_opening_transmission("lvl_01")
	gameplay.show_transmission(tr1)
	gameplay.transmission_content.visible_characters = -1 # Reveal full line for clean screenshot
	await _wait_frames(12)
	_save_screen("11_transmission_emergency.png")
	gameplay.transmission_modal.visible = false
	await _wait_frames(4)

	# 15. Cinematic Transmission: CORRUPTED (Chapter 8)
	print("\n[15/16] Capturing Cinematic Transmission (Corrupted - Chapter 8)...")
	var tr8 = NarrativeRegistryClass.get_opening_transmission("lvl_08")
	gameplay.show_transmission(tr8)
	gameplay.transmission_content.visible_characters = -1
	await _wait_frames(12)
	_save_screen("12_transmission_corrupted.png")
	gameplay.transmission_modal.visible = false
	await _wait_frames(4)

	# 16. Cinematic Transmission: FINAL CONVERGENCE (Level 10 Outro)
	print("\n[16/16] Capturing Cinematic Transmission (Final Climax - Level 10 Outro)...")
	var tr10 = NarrativeRegistryClass.get_completion_transmission("lvl_10")
	gameplay.show_transmission(tr10)
	gameplay.transmission_content.visible_characters = -1
	await _wait_frames(12)
	_save_screen("13_transmission_final.png")
	gameplay.queue_free()
	await _wait_frames(4)

	print("\n=======================================================")
	print(" ALL 16 SCREENSHOTS CAPTURED SUCCESSFULLY! ")
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
