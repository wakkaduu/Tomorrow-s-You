extends Control

## Level Selection screen for Tomorrow's You.
## Displays campaign levels filtered by selected difficulty tier,
## showing earned stars (1–3), move budgets, and minimum Echo requirements.

const UIDesignSystemClass = preload("res://scripts/ui/components/ui_design_system.gd")

@onready var levels_grid: GridContainer = $ScrollContainer/VBoxContainer/LevelsGrid
@onready var back_button: Button = $Header/BackButton
@onready var title_label: Label = $Header/Title
@onready var background: Control = $TemporalBackground

const TIER_NAMES: Dictionary = {
	1: "EASY — INITIATION",
	2: "NORMAL — SYNCHRONIZATION",
	3: "HARD — CONVERGENCE",
	4: "EXPERT — PARADOX",
	5: "NIGHTMARE — THE LAST TOMORROW"
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	UIDesignSystemClass.apply_icon_button(back_button, "icon_back", Vector2(48, 48))

	var tier: int = SaveManager.selected_difficulty_tier if SaveManager else 1
	title_label.text = TIER_NAMES.get(tier, "Select Level")
	UIDesignSystemClass.apply_display_heading(title_label, UIDesignSystemClass.FONT_SIZE_SCREEN_HEADING, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")

	if background and background.has_method("set_difficulty_tier"):
		background.set_difficulty_tier(tier)
	_build_level_cards()
	_apply_safe_area()
	if AndroidSystemManager:
		AndroidSystemManager.safe_area_changed.connect(func(_m): _apply_safe_area())

func _apply_safe_area() -> void:
	if not AndroidSystemManager:
		return
	var m = AndroidSystemManager.get_safe_margins()
	var header = $Header
	if header:
		header.offset_top = maxi(float(m.get("top", 0)), 16.0)
	var scroll = $ScrollContainer
	if scroll:
		scroll.offset_bottom = -maxi(float(m.get("bottom", 0)), 16.0)

func handle_back_button() -> bool:
	_on_back_pressed()
	return true

func _on_back_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if AndroidSystemManager:
		AndroidSystemManager.trigger_haptic("button")
	SceneRouter.go_to_difficulty_select()

func _build_level_cards() -> void:
	for child in levels_grid.get_children():
		child.queue_free()

	var total_levels: int = LevelRegistry.get_level_count()
	var filter_tier: int = SaveManager.selected_difficulty_tier if SaveManager else 1

	for i in range(total_levels):
		var lvl: LevelDefinition = LevelRegistry.get_level(i)
		# Filter by tier if set
		if filter_tier > 0 and lvl.difficulty_tier != filter_tier:
			continue

		var is_unlocked: bool = SaveManager.is_level_unlocked(lvl.level_id) if SaveManager else (i == 0)
		var is_completed: bool = SaveManager.is_level_completed(lvl.level_id) if SaveManager else false
		var stars: int = SaveManager.get_level_stars(lvl.level_id) if SaveManager else 0

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(300, 84)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if not is_unlocked:
			btn.text = "Level %02d: %s\nRestricted // Complete Previous Level" % [i + 1, lvl.level_name]
			btn.disabled = true
			UIDesignSystemClass.apply_button_icon(btn, "icon_locked")
			UIDesignSystemClass.apply_button_style(btn, UIDesignSystemClass.ButtonType.SECONDARY, UIDesignSystemClass.COLOR_TEXT_DIM)
		elif is_completed:
			var star_str: String = "%d/3 Stars" % stars
			var best_turns: int = SaveManager.best_actions.get(lvl.level_id, 0) if SaveManager else 0
			var best_ech: int = SaveManager.best_echoes.get(lvl.level_id, 0) if SaveManager else 0
			var label_text: String = "Level %02d: %s [%s]\nRecord: %d Turns (%d Echoes) • 3★ Target: ≤%d" % [
				i + 1, lvl.level_name, star_str, best_turns, best_ech, lvl.target_3_stars
			]
			UIDesignSystemClass.apply_secondary_button(btn, label_text, "icon_complete", UIDesignSystemClass.COLOR_CYAN_PRIMARY)
		else:
			var label_text: String = "Level %02d: %s [Ready to Deploy]\nMin Echoes: %d • 3★ Target: ≤%d" % [
				i + 1, lvl.level_name, lvl.min_echoes_required, lvl.target_3_stars
			]
			UIDesignSystemClass.apply_primary_button(btn, label_text, "icon_play")

		var level_idx: int = i
		btn.pressed.connect(func():
			if AudioManager:
				AudioManager.play_sfx("ui_click")
			if AndroidSystemManager:
				AndroidSystemManager.trigger_haptic("button")
			SceneRouter.go_to_gameplay(level_idx)
		)

		levels_grid.add_child(btn)
