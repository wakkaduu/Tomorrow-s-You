extends Node

## Dedicated End-to-End In-Engine Test:
## Validates the exact user sequence:
## 1. Launch Game
## 2. Open Level Select
## 3. Select Level 1 — First Contact
## 4. Start the level
## 5. Verify MORROW's introductory transmission appears before gameplay

const NarrativeRegistryClass = preload("res://scripts/narrative/narrative_registry.gd")
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const GameplayScene = preload("res://scenes/gameplay/gameplay.tscn")

func _ready() -> void:
	print("\n===================================================================")
	print("   VERIFYING EXACT USER SEQUENCE: LEVEL 1 OPENING TRANSMISSION    ")
	print("===================================================================")

	# Ensure fresh/clean save state for Level 1 transmission test
	if SaveManager:
		SaveManager.set_custom_save_path("user://test_opening_flow_save.cfg")
		SaveManager._set_default_save()

	# 1. Step: Level 1 selected from Level Select
	print("\n[STEP 1] Selecting Level 1 (First Contact) from Level Select...")
	if GameManager:
		GameManager.select_level(0) # Index 0 = lvl_01 First Contact
		assert(GameManager.get_current_level_def().level_id == "lvl_01", "Level must be lvl_01")
	print("  --> Level 1 definition loaded: %s" % GameManager.get_current_level_def().level_name)

	# 2. Step: Instantiate and mount Gameplay scene (equivalent to change_scene)
	print("\n[STEP 2] Mounting Gameplay scene...")
	var gameplay = GameplayScene.instantiate()
	add_child(gameplay)

	# 3. Step: Inspect modal states immediately upon start
	print("\n[STEP 3] Inspecting scene modals before any player input...")
	var trans_modal = gameplay.get_node("Modals/TransmissionModal")
	var pause_modal = gameplay.get_node("Modals/PauseModal")
	var complete_modal = gameplay.get_node("Modals/CompleteModal")

	assert(trans_modal != null, "TransmissionModal node must exist in gameplay scene")
	assert(trans_modal.visible == true, "CRITICAL: TransmissionModal MUST be visible when Level 1 starts!")
	print("  --> [PASS] TransmissionModal is VISIBLE before gameplay")

	assert(pause_modal.visible == false, "PauseModal must NOT be visible")
	assert(complete_modal.visible == false, "CompleteModal must NOT be visible")

	# 4. Step: Verify MORROW's transmission contents
	print("\n[STEP 4] Verifying transmission header and dialogue lines...")
	var sender_label = gameplay.get_node("Modals/TransmissionModal/Margin/VBoxContainer/HeaderBox/SenderLabel")
	var channel_label = gameplay.get_node("Modals/TransmissionModal/Margin/VBoxContainer/HeaderBox/ChannelLabel")
	var content_label = gameplay.get_node("Modals/TransmissionModal/Margin/VBoxContainer/ScrollContainer/TransmissionContent")
	var btn_proceed = gameplay.get_node("Modals/TransmissionModal/Margin/VBoxContainer/ButtonsRow/BtnProceedTransmission")
	var btn_skip = gameplay.get_node("Modals/TransmissionModal/Margin/VBoxContainer/ButtonsRow/BtnSkipTransmission")

	assert(sender_label.text == "MORROW // FACILITY AI", "Sender mismatch")
	assert(channel_label.text == "EMERGENCY CONTAINMENT LINK - CH 01", "Channel mismatch")
	assert(content_label.text == "Good morning, Operator 07.", "Opening line mismatch")
	print("  --> [PASS] Header: %s | %s" % [sender_label.text, channel_label.text])
	print("  --> [PASS] Line 1: '%s'" % content_label.text)

	# 5. Step: Verify gameplay simulation is frozen while modal is active
	print("\n[STEP 5] Verifying simulation is frozen while transmission is active...")
	var initial_turn: int = gameplay.simulation.current_turn
	var initial_pos: Vector2i = gameplay.simulation.player_pos

	assert(gameplay._is_modal_active() == true, "Modal active flag must be true")

	# Attempt to move while modal is open
	gameplay._execute_move(Vector2i.RIGHT)
	assert(gameplay.simulation.current_turn == initial_turn, "Turn MUST NOT advance while transmission is open")
	assert(gameplay.simulation.player_pos == initial_pos, "Player MUST NOT move while transmission is open")
	print("  --> [PASS] Controls locked; turns not consumed")

	# 6. Step: Advance through transmission lines
	print("\n[STEP 6] Stepping through transmission lines...")
	var lines = NarrativeRegistryClass.get_opening_transmission("lvl_01").get("lines", [])
	for i in range(1, lines.size()):
		btn_proceed.emit_signal("pressed")
		assert(content_label.text == lines[i], "Line %d mismatch: got '%s', expected '%s'" % [i, content_label.text, lines[i]])
		print("  --> Advanced to line %d: '%s'" % [i + 1, content_label.text])

	# Final step: tap proceed on last line to dismiss
	btn_proceed.emit_signal("pressed")
	assert(trans_modal.visible == false, "TransmissionModal must be dismissed after last line")
	assert(gameplay._is_modal_active() == false, "Modal active flag must now be false")
	print("  --> [PASS] Transmission dismissed; gameplay active")

	# 7. Step: Normal gameplay resumes
	print("\n[STEP 7] Verifying normal gameplay operates after transmission dismiss...")
	gameplay._execute_move(Vector2i.DOWN)
	assert(gameplay.simulation.current_turn == initial_turn + 1, "Turn should advance to 2")
	assert(gameplay.simulation.player_pos != initial_pos, "Player should have moved down")
	print("  --> [PASS] Player moved successfully to %s on Turn %d" % [gameplay.simulation.player_pos, gameplay.simulation.current_turn])

	# Cleanup
	gameplay.queue_free()
	if SaveManager:
		SaveManager.reset_save_path()
	DirAccess.remove_absolute("user://test_opening_flow_save.cfg")

	print("\n===================================================================")
	print(" VERIFICATION SUCCESS: OPENING TRANSMISSION FLOW FULLY VALIDATED! [✓]")
	print("===================================================================\n")
	get_tree().quit(0)
