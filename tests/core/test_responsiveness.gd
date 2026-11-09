extends SceneTree

# Preload classes
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const PuzzleSimulationClass = preload("res://scripts/gameplay/puzzle_simulation.gd")
const BoardRendererClass = preload("res://scripts/gameplay/board_renderer.gd")

func _init() -> void:
	print("\n===================================================================")
	print("       TOMORROW'S YOU — RESPONSIVENESS & RESOLUTION TEST")
	print("===================================================================")

	var resolutions: Array[Vector2] = [
		Vector2(360, 640),   # Small budget Android
		Vector2(720, 1280),  # Standard reference portrait
		Vector2(1080, 2400)  # Tall modern 20:9 phone
	]

	var stats: Dictionary = {"total": 0, "passed": 0}

	var check = func(name: String, ok: bool) -> void:
		stats["total"] += 1
		print("[%d] %s" % [stats["total"], name])
		if ok:
			stats["passed"] += 1
			print("    --> PASSED [✓]")
		else:
			push_error("    --> FAILED [✗]: " + name)

	for res in resolutions:
		print("\n--- Testing Target Resolution: %dx%d ---" % [int(res.x), int(res.y)])

		# Test across multiple level sizes (7x7, 11x7, 15x11)
		for lvl_idx in [0, 5, 9]:
			var lvl: LevelDefinition = LevelRegistryClass.get_level(lvl_idx)
			var sim: PuzzleSimulation = PuzzleSimulationClass.new()
			sim.load_level(lvl)

			var renderer: BoardRenderer = BoardRendererClass.new()
			renderer.simulation = sim
			renderer.level_def = lvl
			renderer.calculate_layout(res)

			var grid_pixel_w: float = float(lvl.grid_width) * renderer.tile_size
			var grid_pixel_h: float = float(lvl.grid_height) * renderer.tile_size

			# 1. Tile size is non-trivial and clamped (>= 20px on small screens/wide maps, up to 84px)
			var min_tile: float = 20.0 if res.x < 400.0 else 32.0
			check.call(
				"Res %dx%d (Level %d %dx%d): Tile size >= %.0fpx (got %.1fpx)" % [
					int(res.x), int(res.y), lvl_idx + 1, lvl.grid_width, lvl.grid_height, min_tile, renderer.tile_size
				],
				renderer.tile_size >= min_tile and renderer.tile_size <= 84.0
			)

			# 2. Grid width fits inside viewport with margins
			check.call(
				"Res %dx%d (Level %d): Board width %.1fpx <= Viewport width %.1fpx" % [
					int(res.x), int(res.y), lvl_idx + 1, grid_pixel_w, res.x
				],
				grid_pixel_w <= res.x and renderer.board_offset.x >= 0.0
			)

			# 3. Grid does not overlap top HUD
			var top_margin: float = 75.0 if res.y < 700.0 else (140.0 if res.y > 1600.0 else 100.0)
			check.call(
				"Res %dx%d (Level %d): Board Y offset %.1fpx >= Top HUD %.1fpx" % [
					int(res.x), int(res.y), lvl_idx + 1, renderer.board_offset.y, top_margin
				],
				renderer.board_offset.y >= top_margin - 0.1
			)

			# 4. Grid does not overlap bottom HUD
			var bottom_margin: float = 220.0 if res.y < 700.0 else (360.0 if res.y > 1600.0 else 270.0)
			var board_bottom: float = renderer.board_offset.y + grid_pixel_h
			check.call(
				"Res %dx%d (Level %d): Board bottom %.1fpx <= Max allowed %.1fpx" % [
					int(res.x), int(res.y), lvl_idx + 1, board_bottom, res.y - bottom_margin + 1.0
				],
				board_bottom <= res.y - bottom_margin + 2.0
			)

			renderer.free()

	print("\n===================================================================")
	print(" RESPONSIVENESS TEST SUMMARY: %d / %d PASSED" % [stats["passed"], stats["total"]])
	print("===================================================================")

	if stats["passed"] == stats["total"] and stats["total"] > 0:
		print(" ALL RESPONSIVENESS CHECKS PASSED WITH 100% SUCCESS! ")
		quit(0)
	else:
		push_error(" SOME RESPONSIVENESS CHECKS FAILED!")
		quit(1)
