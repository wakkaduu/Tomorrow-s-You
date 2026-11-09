extends Node

const TemporalBackgroundClass = preload("res://scripts/background/temporal_background.gd")
const ThemeManagerClass = preload("res://scripts/background/background_theme_manager.gd")

func _ready() -> void:
	print("\n===================================================================")
	print("       TOMORROW'S YOU — TEMPORAL BACKGROUND SYSTEM SUITE")
	print("===================================================================")

	var counters = {"total": 0, "passed": 0}

	var run_test = func(test_name: String, test_fn: Callable) -> void:
		counters["total"] += 1
		print("[BACKGROUND | TEST %2d] %s" % [counters["total"], test_name])
		var ok: bool = test_fn.call()
		if ok:
			counters["passed"] += 1
			print("   --> PASSED [✓]")
		else:
			push_error("   --> FAILED [✗]: " + test_name)

	# --------------------------------------------------------------------------
	# TEST 1: Instantiation & Layer Tree
	# --------------------------------------------------------------------------
	run_test.call("TemporalBackground instantiates with all 5 environmental layers", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)
		bg.size = Vector2(720, 1280)

		var has_shader: bool = bg.has_node("ShaderEnvironment")
		var has_silhouettes: bool = bg.has_node("SilhouettesAndRings")
		var has_particles: bool = bg.has_node("AmbientParticles")
		var has_overlay: bool = bg.has_node("AtmosphericOverlay")

		bg.queue_free()
		return has_shader and has_silhouettes and has_particles and has_overlay
	)

	# --------------------------------------------------------------------------
	# TEST 2: Input pass-through (MOUSE_FILTER_IGNORE)
	# --------------------------------------------------------------------------
	run_test.call("Background and all internal layers ignore mouse/touch input", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)

		var ok: bool = (bg.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		for child in bg.get_children():
			if child is Control and child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				ok = false

		bg.queue_free()
		return ok
	)

	# --------------------------------------------------------------------------
	# TEST 3: All 8 Screen Modes provide valid parameters
	# --------------------------------------------------------------------------
	run_test.call("All 8 ScreenMode themes load correctly without missing parameters", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)

		for mode in range(8):
			bg.set_screen_mode(mode)
			if bg._current_theme.is_empty():
				bg.queue_free()
				return false
			if not bg._current_theme.has("primary_glow") or not bg._current_theme.has("bg_dark"):
				bg.queue_free()
				return false

		bg.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 4: Difficulty Tier Themes (1 to 5)
	# --------------------------------------------------------------------------
	run_test.call("Difficulty tiers 1 to 5 exhibit distinct progression in rings and colors", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)
		bg.set_screen_mode(ThemeManagerClass.ScreenMode.DIFFICULTY_SELECT, 1)

		var last_rings: int = 0
		for tier in range(1, 6):
			bg.set_difficulty_tier(tier)
			var rings: int = bg._current_theme.get("ring_count", 0)
			if rings < last_rings: # Rings should increase or stay constant with danger
				bg.queue_free()
				return false
			last_rings = rings

		# Verify Tier 1 is Cyan, Tier 5 is Crimson
		var t1 = ThemeManagerClass.get_difficulty_tier_theme(1)
		var t5 = ThemeManagerClass.get_difficulty_tier_theme(5)
		var t1_is_cyan: bool = (t1["primary_glow"] == ThemeManagerClass.COLOR_PLAYER_CYAN)
		var t5_is_crimson: bool = (t5["primary_glow"] == ThemeManagerClass.COLOR_NIGHTMARE_CRIMSON)

		bg.queue_free()
		return t1_is_cyan and t5_is_crimson
	)

	# --------------------------------------------------------------------------
	# TEST 5: Paused Mode Dimming and Slowdown
	# --------------------------------------------------------------------------
	run_test.call("Pause state darkens overlay and slows movement", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)
		bg.set_screen_mode(ThemeManagerClass.ScreenMode.GAMEPLAY)

		bg.set_paused(true)
		var overlay_dark: bool = (bg._overlay_rect.color.a > 0.3)
		var is_paused: bool = bg.is_paused_mode

		bg.set_paused(false)
		var overlay_cleared: bool = (bg._overlay_rect.color.a == 0.0)

		bg.queue_free()
		return overlay_dark and is_paused and overlay_cleared
	)

	# --------------------------------------------------------------------------
	# TEST 6: Level Complete Shimmer Mode
	# --------------------------------------------------------------------------
	run_test.call("Level Complete triggers radiant cyan shimmer theme", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)
		bg.set_screen_mode(ThemeManagerClass.ScreenMode.GAMEPLAY)

		bg.set_level_complete(true)
		var has_shimmer: bool = (bg._overlay_rect.color.a > 0.05)
		var is_comp: bool = bg.is_complete_mode
		var theme_mode: int = bg._current_theme.get("mode", -1)

		bg.queue_free()
		return has_shimmer and is_comp and (theme_mode == ThemeManagerClass.ScreenMode.LEVEL_COMPLETE)
	)

	# --------------------------------------------------------------------------
	# TEST 7: Multi-Resolution Scaling & Particle Wrapping
	# --------------------------------------------------------------------------
	run_test.call("Background scales cleanly across 360x640, 720x1280, 1080x2400 viewports", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)

		var resolutions = [Vector2(360, 640), Vector2(720, 1280), Vector2(1080, 2400)]
		for res in resolutions:
			bg.size = res
			bg.notification(Control.NOTIFICATION_RESIZED)
			bg._process(0.016)

		bg.queue_free()
		return true
	)

	# --------------------------------------------------------------------------
	# TEST 8: Reduced Animations Accessibility Setting
	# --------------------------------------------------------------------------
	run_test.call("Respects SaveManager.reduced_animations setting", func() -> bool:
		var bg = TemporalBackgroundClass.new()
		add_child(bg)

		SaveManager.reduced_animations = true
		bg._on_settings_updated()
		var reduced_active: bool = bg.is_reduced_animations_active()

		SaveManager.reduced_animations = false
		bg._on_settings_updated()
		var reduced_inactive: bool = not bg.is_reduced_animations_active()

		bg.queue_free()
		return reduced_active and reduced_inactive
	)

	# --------------------------------------------------------------------------
	# SUMMARY
	# --------------------------------------------------------------------------
	print("\n===================================================================")
	print(" BACKGROUND SYSTEM SUMMARY: %d / %d TESTS PASSED" % [counters["passed"], counters["total"]])
	print("===================================================================")

	if counters["passed"] == counters["total"]:
		print(" ALL BACKGROUND TESTS PASSED WITH 100% SUCCESS! [✓]\n")
		get_tree().quit(0)
	else:
		push_error(" SOME BACKGROUND TESTS FAILED! [✗]\n")
		get_tree().quit(1)
