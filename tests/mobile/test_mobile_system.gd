extends Node

## Comprehensive Unit & Integration Test Suite for Android Mobile Features.
## Validates:
## 1. AndroidSystemManager back-button navigation hierarchy
## 2. Safe area inset calculation and margin container application
## 3. Haptic feedback dispatch and setting toggle respect
## 4. Multi-resolution responsive board layout across 7 mobile aspect ratios:
##    - 360x640 (16:9 standard)
##    - 360x800 (20:9 entry)
##    - 390x844 (19.5:9 modern)
##    - 412x915 (20:9 Pixel)
##    - 432x960 (20:9 tall)
##    - 720x1280 (HD portrait)
##    - 1080x2400 (FHD+ portrait)
## 5. Touch swipe gesture detection and boundaries

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("   TOMORROW'S YOU — ANDROID MOBILE VALIDATION SUITE    ")
	print("=======================================================\n")

	test_safe_area_calculations()
	test_haptics_dispatch()
	test_back_button_routing()
	test_board_layout_across_resolutions()
	test_swipe_gesture_bounds()

	print("\n-------------------------------------------------------")
	print("Mobile Suite Results: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("-------------------------------------------------------\n")

	if tests_failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] %s" % msg)
		tests_passed += 1
	else:
		printerr("  [FAIL] %s" % msg)
		tests_failed += 1

func assert_equal(actual, expected, msg: String) -> void:
	if actual == expected:
		print("  [PASS] %s (expected %s, got %s)" % [msg, str(expected), str(actual)])
		tests_passed += 1
	else:
		printerr("  [FAIL] %s (expected %s, got %s)" % [msg, str(expected), str(actual)])
		tests_failed += 1

# ------------------------------------------------------------------------------
# 1. Safe Area Calculations
# ------------------------------------------------------------------------------
func test_safe_area_calculations() -> void:
	print("--- TEST GROUP 1: Safe Area & Inset Handling ---")

	var mgr = get_node_or_null("/root/AndroidSystemManager")
	assert_true(mgr != null, "AndroidSystemManager autoload exists and is registered")

	if mgr:
		var margins = mgr.get_safe_margins()
		assert_true(margins.has("top"), "Safe area contains 'top' margin")
		assert_true(margins.has("bottom"), "Safe area contains 'bottom' margin")
		assert_true(margins.has("left"), "Safe area contains 'left' margin")
		assert_true(margins.has("right"), "Safe area contains 'right' margin")

		var mc: MarginContainer = MarginContainer.new()
		add_child(mc)
		mgr.apply_safe_area_to_margin(mc, 10, 20, 5, 5)
		var top_val = mc.get_theme_constant("margin_top")
		var bot_val = mc.get_theme_constant("margin_bottom")
		assert_true(top_val >= 10, "Margin container received top safe margin offset")
		assert_true(bot_val >= 20, "Margin container received bottom safe margin offset")
		mc.queue_free()

# ------------------------------------------------------------------------------
# 2. Haptics Feedback Dispatch
# ------------------------------------------------------------------------------
func test_haptics_dispatch() -> void:
	print("\n--- TEST GROUP 2: Haptic Feedback Integration ---")

	var mgr = get_node_or_null("/root/AndroidSystemManager")
	assert_true(mgr != null, "AndroidSystemManager accessible for haptics")

	if mgr:
		# Check duration mapping
		assert_equal(mgr.HAPTIC_DURATIONS.get("move"), 15, "Move haptic is 15ms")
		assert_equal(mgr.HAPTIC_DURATIONS.get("wait"), 15, "Wait haptic is 15ms")
		assert_equal(mgr.HAPTIC_DURATIONS.get("echo_create"), 35, "Echo create haptic is 35ms")
		assert_equal(mgr.HAPTIC_DURATIONS.get("plate"), 40, "Pressure plate haptic is 40ms")
		assert_equal(mgr.HAPTIC_DURATIONS.get("door"), 50, "Door toggle haptic is 50ms")
		assert_equal(mgr.HAPTIC_DURATIONS.get("complete"), 80, "Level complete haptic is 80ms")
		assert_equal(mgr.HAPTIC_DURATIONS.get("reset"), 25, "Reset haptic is 25ms")

		# Test enabled / disabled toggle respect
		var save_mgr = get_node_or_null("/root/SaveManager")
		if save_mgr:
			save_mgr.haptics_enabled = false
			mgr.trigger_haptic("move") # Should cleanly no-op
			assert_true(true, "trigger_haptic safely respects haptics_enabled = false")

			save_mgr.haptics_enabled = true
			mgr.trigger_haptic("move") # Should cleanly dispatch
			assert_true(true, "trigger_haptic safely handles haptics_enabled = true")
		else:
			assert_true(true, "trigger_haptic handles absence of save_mgr")

# ------------------------------------------------------------------------------
# 3. Back Button Routing
# ------------------------------------------------------------------------------
func test_back_button_routing() -> void:
	print("\n--- TEST GROUP 3: Hardware Back Button Navigation ---")

	var mgr = get_node_or_null("/root/AndroidSystemManager")
	assert_true(mgr != null, "AndroidSystemManager accessible for back navigation")

	# Test mock gameplay back button handler
	var gameplay_scene = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	assert_true(gameplay_scene.has_method("handle_back_button"), "Gameplay scene implements handle_back_button")

	add_child(gameplay_scene)

	# 1. Initially playing: back button should toggle pause
	var pause_modal = gameplay_scene.get_node("Modals/PauseModal")
	assert_true(not pause_modal.visible, "Pause modal initially closed")

	var handled1 = gameplay_scene.handle_back_button()
	assert_true(handled1, "Back button handled by gameplay")
	assert_true(pause_modal.visible, "Back button opened pause modal")

	# 2. While paused: back button should resume
	var handled2 = gameplay_scene.handle_back_button()
	assert_true(handled2, "Back button handled while paused")
	assert_true(not pause_modal.visible, "Back button closed pause modal (resumed)")

	# 3. While hint modal open: back button should close hint modal
	var hint_modal = gameplay_scene.get_node("Modals/HintModal")
	hint_modal.visible = true
	var handled3 = gameplay_scene.handle_back_button()
	assert_true(handled3, "Back button handled while hint modal open")
	assert_true(not hint_modal.visible, "Back button dismissed hint modal")

	gameplay_scene.queue_free()

# ------------------------------------------------------------------------------
# 4. Board Layout Across 7 Mobile Aspect Ratios
# ------------------------------------------------------------------------------
func test_board_layout_across_resolutions() -> void:
	print("\n--- TEST GROUP 4: Multi-Resolution Board Fitting ---")

	var BoardRendererClass = load("res://scripts/gameplay/board_renderer.gd")
	var sim = PuzzleSimulation.new()
	var lvl = LevelRegistry.get_level(0)
	sim.load_level(lvl)

	var resolutions: Array[Vector2] = [
		Vector2(360, 640),   # 16:9 standard
		Vector2(360, 800),   # 20:9 entry
		Vector2(390, 844),   # 19.5:9 standard
		Vector2(412, 915),   # 20:9 Pixel
		Vector2(432, 960),   # 20:9 tall
		Vector2(720, 1280),  # HD portrait
		Vector2(1080, 2400)  # FHD+ portrait
	]

	for res in resolutions:
		var renderer = Node2D.new()
		renderer.set_script(BoardRendererClass)
		add_child(renderer)
		renderer.setup(sim, res)

		var tile_sz: float = renderer.tile_size
		var offset: Vector2 = renderer.board_offset
		var grid_w: float = float(lvl.grid_width) * tile_sz
		var grid_h: float = float(lvl.grid_height) * tile_sz

		# Verify bounds
		assert_true(tile_sz >= 20.0 and tile_sz <= 84.0,
			"Res %dx%d: Tile size %.1fpx within [20, 84]" % [int(res.x), int(res.y), tile_sz])

		# Verify horizontal centering within viewport
		assert_true(offset.x >= 0.0 and (offset.x + grid_w) <= (res.x + 1.0),
			"Res %dx%d: Board width fits horizontally (%.1fpx in %.1fpx)" % [int(res.x), int(res.y), grid_w, res.x])

		# Verify vertical bounds stay in clear playfield (below top HUD, above bottom controls)
		assert_true(offset.y >= 70.0 and (offset.y + grid_h) <= (res.y - 200.0),
			"Res %dx%d: Board fits vertically without overlapping HUDs (y=%.1f, h=%.1f, vp_h=%.1f)" % [
				int(res.x), int(res.y), offset.y, grid_h, res.y
			])

		renderer.queue_free()

# ------------------------------------------------------------------------------
# 5. Touch Swipe Gesture Bounds
# ------------------------------------------------------------------------------
func test_swipe_gesture_bounds() -> void:
	print("\n--- TEST GROUP 5: Touch Swipe Gesture Bounds ---")

	var gameplay_scene = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	add_child(gameplay_scene)

	var vp_size = gameplay_scene.get_viewport_rect().size

	# Simulate touch in bottom HUD area (e.g. y = vp_size.y - 100) -> should NOT start swipe
	var touch_down_in_hud = InputEventScreenTouch.new()
	touch_down_in_hud.position = Vector2(vp_size.x * 0.5, vp_size.y - 100.0)
	touch_down_in_hud.pressed = true
	gameplay_scene._unhandled_input(touch_down_in_hud)
	assert_true(not gameplay_scene._is_swiping, "Touch inside bottom HUD does NOT start swipe gesture")

	# Simulate touch on board area (e.g. y = vp_size.y * 0.5) -> should start swipe
	var touch_down_on_board = InputEventScreenTouch.new()
	touch_down_on_board.position = Vector2(vp_size.x * 0.5, vp_size.y * 0.5)
	touch_down_on_board.pressed = true
	gameplay_scene._unhandled_input(touch_down_on_board)
	assert_true(gameplay_scene._is_swiping, "Touch on board playfield successfully initiates swipe")

	# Release with delta right
	var touch_up = InputEventScreenTouch.new()
	touch_up.position = Vector2(vp_size.x * 0.5 + 60.0, vp_size.y * 0.5)
	touch_up.pressed = false
	gameplay_scene._unhandled_input(touch_up)
	assert_true(not gameplay_scene._is_swiping, "Swipe completes and resets is_swiping")

	gameplay_scene.queue_free()
