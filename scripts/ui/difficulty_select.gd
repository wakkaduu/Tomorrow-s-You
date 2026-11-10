extends Control

## Dedicated Difficulty Selection Screen for Tomorrow's You.
## Displays 5 distinct difficulty tier cards with progressive unlocking,
## completion tracking, star statistics, and mobile-friendly touch targets.

const UIDesignSystemClass = preload("res://scripts/ui/components/ui_design_system.gd")

@onready var cards_container: VBoxContainer = $ScrollContainer/VBoxContainer/CardsContainer
@onready var back_button: Button = $Header/BackButton
@onready var stars_label: Label = $Header/StarsLabel
@onready var background: Control = $TemporalBackground

const TIER_DATA: Array[Dictionary] = [
	{
		"tier": 1,
		"code": "TIER 01",
		"title": "EASY — INITIATION",
		"description": "Learn temporal fundamentals. Single Echo routing and basic pressure plates.",
		"echoes": "1 Echo required",
		"color": Color("#54E6EA"), # Cyan
		"bg_tint": Color(0.08, 0.22, 0.26, 0.7)
	},
	{
		"tier": 2,
		"code": "TIER 02",
		"title": "NORMAL — SYNCHRONIZATION",
		"description": "Coordinate dual timelines. Chained doors, AND logic gates, and WAIT management.",
		"echoes": "2 Echoes required",
		"color": Color("#34D399"), # Emerald
		"bg_tint": Color(0.08, 0.24, 0.18, 0.7)
	},
	{
		"tier": 3,
		"code": "TIER 03",
		"title": "HARD — CONVERGENCE",
		"description": "Challenging interconnected chambers. Staggered durations and strict action timing.",
		"echoes": "2 Echoes required",
		"color": Color("#FBBF24"), # Amber
		"bg_tint": Color(0.26, 0.22, 0.08, 0.7)
	},
	{
		"tier": 4,
		"code": "TIER 04",
		"title": "EXPERT — PARADOX",
		"description": "Advanced multi-timeline planning. Cumulative security matrices and triple-Echo relays.",
		"echoes": "3 Echoes required",
		"color": Color("#A78BFA"), # Violet
		"bg_tint": Color(0.20, 0.14, 0.28, 0.7)
	},
	{
		"tier": 5,
		"code": "TIER 05",
		"title": "NIGHTMARE — THE LAST TOMORROW",
		"description": "The ultimate test: 4-Quadrant facility featuring the precision Sequence Lock.",
		"echoes": "3 Echoes required",
		"color": Color("#F43F5E"), # Rose/Crimson
		"bg_tint": Color(0.28, 0.08, 0.14, 0.7)
	}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	UIDesignSystemClass.apply_button_skin(back_button, UIDesignSystemClass.COLOR_CYAN_PRIMARY, false)

	_update_header_stars()
	_build_tier_cards()
	_apply_safe_area()
	if AndroidSystemManager:
		AndroidSystemManager.safe_area_changed.connect(func(_m): _apply_safe_area())
	var active_tier: int = SaveManager.selected_difficulty_tier if SaveManager else 1
	if background and background.has_method("set_difficulty_tier"):
		background.set_difficulty_tier(active_tier)

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
	SceneRouter.go_to_main_menu()

func _update_header_stars() -> void:
	if not SaveManager:
		stars_label.text = "★ 0/30"
		return
	var totals: Dictionary = SaveManager.get_total_stars()
	stars_label.text = "★ %d/%d" % [totals.get("earned", 0), totals.get("total", 30)]

func _build_tier_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for info in TIER_DATA:
		var tier_num: int = info["tier"]
		var is_unlocked: bool = SaveManager.is_difficulty_unlocked(tier_num) if SaveManager else (tier_num == 1)
		var pct: float = SaveManager.get_difficulty_completion_percentage(tier_num) if SaveManager else 0.0
		var stars_dict: Dictionary = SaveManager.get_difficulty_stars(tier_num) if SaveManager else {"earned": 0, "total": 3}
		var tier_levels: Array[LevelDefinition] = SaveManager.get_difficulty_levels(tier_num) if SaveManager else []
		var count: int = tier_levels.size()
		var card_color: Color = info["color"]

		# Card container
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 130)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UIDesignSystemClass.create_card_style(card_color, is_unlocked, false))

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 18)
		margin.add_theme_constant_override("margin_right", 18)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(margin)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		margin.add_child(vbox)

		# Row 1: Tier Code Pill, Title, and Status
		var top_row: HBoxContainer = HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 10)

		var tier_pill: Label = Label.new()
		tier_pill.text = " %s " % info.get("code", "TIER")
		tier_pill.add_theme_font_size_override("font_size", 11)
		if is_unlocked:
			tier_pill.add_theme_color_override("font_color", card_color)
		else:
			tier_pill.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_DIM)
		top_row.add_child(tier_pill)

		var title_lbl: Label = Label.new()
		title_lbl.text = info["title"]
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 17)
		title_lbl.add_theme_color_override("font_color", card_color if is_unlocked else Color(0.5, 0.55, 0.62))
		top_row.add_child(title_lbl)

		var status_lbl: Label = Label.new()
		if not is_unlocked:
			status_lbl.text = "🔒 LOCKED"
			status_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_ROSE_ALERT)
		elif pct >= 100.0:
			status_lbl.text = "★ COMPLETED"
			status_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
		else:
			status_lbl.text = "%.0f%% DONE" % pct
			status_lbl.add_theme_color_override("font_color", card_color)
		status_lbl.add_theme_font_size_override("font_size", 13)
		top_row.add_child(status_lbl)
		vbox.add_child(top_row)

		# Row 2: Description
		var desc_lbl: Label = Label.new()
		desc_lbl.text = info["description"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color("#CBD5E1") if is_unlocked else Color(0.42, 0.48, 0.55))
		vbox.add_child(desc_lbl)

		# Row 3: Meta info (Level count, Echo requirement, Stars)
		var meta_row: HBoxContainer = HBoxContainer.new()
		var count_lbl: Label = Label.new()
		count_lbl.text = "%d %s" % [count, "Level" if count == 1 else "Levels"]
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_MUTED)
		meta_row.add_child(count_lbl)

		var dot1: Label = Label.new()
		dot1.text = " • "
		dot1.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_DIM)
		meta_row.add_child(dot1)

		var echo_lbl: Label = Label.new()
		echo_lbl.text = info["echoes"]
		echo_lbl.add_theme_font_size_override("font_size", 12)
		echo_lbl.add_theme_color_override("font_color", card_color if is_unlocked else UIDesignSystemClass.COLOR_TEXT_DIM)
		meta_row.add_child(echo_lbl)

		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meta_row.add_child(spacer)

		var star_lbl: Label = Label.new()
		star_lbl.text = "★ %d/%d" % [stars_dict.get("earned", 0), stars_dict.get("total", 0)]
		star_lbl.add_theme_font_size_override("font_size", 13)
		star_lbl.add_theme_color_override("font_color", Color("#FBBF24") if is_unlocked else UIDesignSystemClass.COLOR_TEXT_DIM)
		meta_row.add_child(star_lbl)
		vbox.add_child(meta_row)

		# Row 4: Progress Bar
		if is_unlocked:
			var pbar: ProgressBar = ProgressBar.new()
			pbar.custom_minimum_size = Vector2(0, 6)
			pbar.max_value = 100.0
			pbar.value = pct
			pbar.show_percentage = false

			var pbar_bg = StyleBoxFlat.new()
			pbar_bg.bg_color = Color(0.04, 0.06, 0.10, 0.8)
			pbar_bg.set_corner_radius_all(3)
			pbar.add_theme_stylebox_override("background", pbar_bg)

			var pbar_fill = StyleBoxFlat.new()
			pbar_fill.bg_color = card_color
			pbar_fill.set_corner_radius_all(3)
			pbar.add_theme_stylebox_override("fill", pbar_fill)

			vbox.add_child(pbar)

		# Action Button
		var select_btn: Button = Button.new()
		select_btn.custom_minimum_size = Vector2(0, 48)
		select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if not is_unlocked:
			var prev_name: String = TIER_DATA[tier_num - 2]["title"].split(" — ")[0]
			select_btn.text = "🔒 Complete %s to unlock" % prev_name
			select_btn.disabled = true
			UIDesignSystemClass.apply_button_skin(select_btn, card_color, false)
		else:
			select_btn.text = "SELECT %s ▶" % info["title"].split(" — ")[0]
			UIDesignSystemClass.apply_button_skin(select_btn, card_color, true)

		var captured_tier: int = tier_num
		var captured_card: PanelContainer = card
		var captured_col: Color = card_color
		var captured_unlocked: bool = is_unlocked

		select_btn.focus_entered.connect(func():
			if background and background.has_method("set_difficulty_tier"):
				background.set_difficulty_tier(captured_tier)
			captured_card.add_theme_stylebox_override("panel", UIDesignSystemClass.create_card_style(captured_col, captured_unlocked, true))
		)
		select_btn.mouse_entered.connect(func():
			if background and background.has_method("set_difficulty_tier"):
				background.set_difficulty_tier(captured_tier)
			captured_card.add_theme_stylebox_override("panel", UIDesignSystemClass.create_card_style(captured_col, captured_unlocked, true))
		)
		select_btn.focus_exited.connect(func():
			captured_card.add_theme_stylebox_override("panel", UIDesignSystemClass.create_card_style(captured_col, captured_unlocked, false))
		)
		select_btn.mouse_exited.connect(func():
			captured_card.add_theme_stylebox_override("panel", UIDesignSystemClass.create_card_style(captured_col, captured_unlocked, false))
		)

		select_btn.pressed.connect(func():
			if AudioManager:
				AudioManager.play_sfx("ui_click")
			if AndroidSystemManager:
				AndroidSystemManager.trigger_haptic("button")
			if SaveManager:
				SaveManager.selected_difficulty_tier = captured_tier
			SceneRouter.go_to_level_select()
		)
		vbox.add_child(select_btn)

		cards_container.add_child(card)
