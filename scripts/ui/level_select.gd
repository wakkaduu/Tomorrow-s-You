extends Control

## Level Selection screen for Tomorrow's You.
## Displays campaign levels organized by Sector with clear status indicators and best records.

@onready var levels_grid: GridContainer = $ScrollContainer/VBoxContainer/LevelsGrid
@onready var back_button: Button = $Header/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_level_cards()

func _on_back_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	SceneRouter.go_to_main_menu()

func _build_level_cards() -> void:
	for child in levels_grid.get_children():
		child.queue_free()

	var total_levels: int = LevelRegistry.get_level_count()
	var current_sector: int = -1

	var sector_titles: Dictionary = {
		1: "SECTOR 01 — AWAKENING",
		2: "SECTOR 02 — SYNCHRONIZATION",
		3: "SECTOR 03 — PARADOX"
	}

	for i in range(total_levels):
		var lvl: LevelDefinition = LevelRegistry.get_level(i)

		# Add Sector Header when transitioning sectors
		if lvl.sector != current_sector:
			current_sector = lvl.sector
			var header_panel: PanelContainer = PanelContainer.new()
			var margin: MarginContainer = MarginContainer.new()
			margin.add_theme_constant_override("margin_top", 12)
			margin.add_theme_constant_override("margin_bottom", 4)
			margin.add_theme_constant_override("margin_left", 8)

			var header_lbl: Label = Label.new()
			header_lbl.text = sector_titles.get(current_sector, "SECTOR %02d" % current_sector)
			header_lbl.add_theme_font_size_override("font_size", 16)
			header_lbl.add_theme_color_override("font_color", Color("#A78BFA"))

			margin.add_child(header_lbl)
			header_panel.add_child(margin)
			levels_grid.add_child(header_panel)

		var is_unlocked: bool = SaveManager.is_level_unlocked(lvl.level_id) if SaveManager else (i == 0)
		var is_completed: bool = SaveManager.is_level_completed(lvl.level_id) if SaveManager else false

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(300, 68)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if not is_unlocked:
			btn.text = "🔒  %d. [LOCKED]" % [i + 1]
			btn.disabled = true
			btn.modulate = Color(0.45, 0.45, 0.55, 0.6)
		elif is_completed:
			var best_turns: int = SaveManager.best_actions.get(lvl.level_id, 0) if SaveManager else 0
			var best_echoes: int = SaveManager.best_echoes.get(lvl.level_id, 0) if SaveManager else 0
			btn.text = "✓  %d. %s  |  Best: %d turns (%d echoes)" % [i + 1, lvl.level_name, best_turns, best_echoes]
			btn.modulate = Color("#54E6EA")
		else:
			btn.text = "▶  %d. %s  [NEW]" % [i + 1, lvl.level_name]
			btn.modulate = Color("#FFFFFF")

		var level_idx: int = i
		btn.pressed.connect(func():
			if AudioManager:
				AudioManager.play_sfx("ui_click")
			SceneRouter.go_to_gameplay(level_idx)
		)

		levels_grid.add_child(btn)
