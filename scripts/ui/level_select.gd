extends Control

## Level Selection screen for Tomorrow's You.
## Displays campaign levels filtered by selected difficulty tier,
## showing earned stars (1–3), move budgets, and minimum Echo requirements.

@onready var levels_grid: GridContainer = $ScrollContainer/VBoxContainer/LevelsGrid
@onready var back_button: Button = $Header/BackButton
@onready var title_label: Label = $Header/Title
@onready var background: Control = $TemporalBackground

const TIER_NAMES: Dictionary = {
	1: "EASY — INITIATION",
	2: "NORMAL — SYNCHRONIZATION",
	3: "HARD — CONVERGENCE",
	4: "EXPERT — PARADOX",
	5: "NIGHTMARE"
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	var tier: int = SaveManager.selected_difficulty_tier if SaveManager else 1
	title_label.text = TIER_NAMES.get(tier, "SELECT LEVEL")
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
		btn.custom_minimum_size = Vector2(300, 76)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if not is_unlocked:
			btn.text = "🔒  %d. %s [LOCKED]\n     Requires previous level completion" % [i + 1, lvl.level_name]
			btn.disabled = true
			btn.modulate = Color(0.45, 0.45, 0.55, 0.6)
		elif is_completed:
			var star_str: String = ""
			for s in range(3):
				star_str += "★" if s < stars else "☆"
			var best_turns: int = SaveManager.best_actions.get(lvl.level_id, 0) if SaveManager else 0
			var best_ech: int = SaveManager.best_echoes.get(lvl.level_id, 0) if SaveManager else 0
			btn.text = "%s  %d. %s\nBest: %d turns (%d echoes) | 3★ Target: ≤%d" % [
				star_str, i + 1, lvl.level_name, best_turns, best_ech, lvl.target_3_stars
			]
			btn.modulate = Color("#54E6EA")
		else:
			btn.text = "▶  %d. %s [NEW]\nMin Echoes: %d | 3★ Target: ≤%d" % [
				i + 1, lvl.level_name, lvl.min_echoes_required, lvl.target_3_stars
			]
			btn.modulate = Color("#FFFFFF")

		var level_idx: int = i
		btn.pressed.connect(func():
			if AudioManager:
				AudioManager.play_sfx("ui_click")
			if AndroidSystemManager:
				AndroidSystemManager.trigger_haptic("button")
			SceneRouter.go_to_gameplay(level_idx)
		)

		levels_grid.add_child(btn)
