extends Control

## Dedicated Difficulty Selection Screen for Tomorrow's You.
## Displays 5 distinct difficulty tier cards with progressive unlocking,
## completion tracking, star statistics, and mobile-friendly touch targets.

@onready var cards_container: VBoxContainer = $ScrollContainer/VBoxContainer/CardsContainer
@onready var back_button: Button = $Header/BackButton
@onready var stars_label: Label = $Header/StarsLabel
@onready var background: Control = $TemporalBackground

const TIER_DATA: Array[Dictionary] = [
	{
		"tier": 1,
		"title": "EASY — INITIATION",
		"description": "Learn temporal fundamentals. Single Echo routing and basic pressure plates.",
		"echoes": "1 Echo required",
		"color": Color("#54E6EA"), # Cyan
		"bg_tint": Color(0.08, 0.22, 0.26, 0.7)
	},
	{
		"tier": 2,
		"title": "NORMAL — SYNCHRONIZATION",
		"description": "Coordinate dual timelines. Chained doors, AND logic gates, and WAIT management.",
		"echoes": "2 Echoes required",
		"color": Color("#34D399"), # Emerald
		"bg_tint": Color(0.08, 0.24, 0.18, 0.7)
	},
	{
		"tier": 3,
		"title": "HARD — CONVERGENCE",
		"description": "Challenging interconnected chambers. Staggered durations and strict action timing.",
		"echoes": "2 Echoes required",
		"color": Color("#FBBF24"), # Amber
		"bg_tint": Color(0.26, 0.22, 0.08, 0.7)
	},
	{
		"tier": 4,
		"title": "EXPERT — PARADOX",
		"description": "Advanced multi-timeline planning. Cumulative security matrices and triple-Echo relays.",
		"echoes": "3 Echoes required",
		"color": Color("#A78BFA"), # Violet
		"bg_tint": Color(0.20, 0.14, 0.28, 0.7)
	},
	{
		"tier": 5,
		"title": "NIGHTMARE — THE LAST TOMORROW",
		"description": "The ultimate test: 4-Quadrant facility featuring the precision Sequence Lock.",
		"echoes": "3 Echoes required",
		"color": Color("#F43F5E"), # Rose/Crimson
		"bg_tint": Color(0.28, 0.08, 0.14, 0.7)
	}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_update_header_stars()
	_build_tier_cards()
	var active_tier: int = SaveManager.selected_difficulty_tier if SaveManager else 1
	if background and background.has_method("set_difficulty_tier"):
		background.set_difficulty_tier(active_tier)

func _on_back_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
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

		# Card container
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 110)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(margin)

		var vbox: VBoxContainer = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		margin.add_child(vbox)

		# Row 1: Title and Lock/Star status
		var top_row: HBoxContainer = HBoxContainer.new()
		var title_lbl: Label = Label.new()
		title_lbl.text = info["title"]
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.add_theme_color_override("font_color", info["color"] if is_unlocked else Color(0.5, 0.5, 0.55))
		top_row.add_child(title_lbl)

		var status_lbl: Label = Label.new()
		if not is_unlocked:
			status_lbl.text = "🔒 LOCKED"
			status_lbl.add_theme_color_override("font_color", Color("#EF4444"))
		elif pct >= 100.0:
			status_lbl.text = "★ COMPLETE"
			status_lbl.add_theme_color_override("font_color", Color("#10B981"))
		else:
			status_lbl.text = "%.0f%% DONE" % pct
			status_lbl.add_theme_color_override("font_color", Color("#38BDF8"))
		status_lbl.add_theme_font_size_override("font_size", 14)
		top_row.add_child(status_lbl)
		vbox.add_child(top_row)

		# Row 2: Description
		var desc_lbl: Label = Label.new()
		desc_lbl.text = info["description"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color("#CBD5E1") if is_unlocked else Color(0.4, 0.4, 0.45))
		vbox.add_child(desc_lbl)

		# Row 3: Meta info (Level count, Echo requirement, Stars)
		var meta_row: HBoxContainer = HBoxContainer.new()
		var count_lbl: Label = Label.new()
		count_lbl.text = "%d %s" % [count, "Level" if count == 1 else "Levels"]
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
		meta_row.add_child(count_lbl)

		var dot1: Label = Label.new()
		dot1.text = " • "
		dot1.add_theme_color_override("font_color", Color("#64748B"))
		meta_row.add_child(dot1)

		var echo_lbl: Label = Label.new()
		echo_lbl.text = info["echoes"]
		echo_lbl.add_theme_font_size_override("font_size", 12)
		echo_lbl.add_theme_color_override("font_color", info["color"] if is_unlocked else Color("#64748B"))
		meta_row.add_child(echo_lbl)

		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meta_row.add_child(spacer)

		var star_lbl: Label = Label.new()
		star_lbl.text = "★ %d/%d" % [stars_dict.get("earned", 0), stars_dict.get("total", 0)]
		star_lbl.add_theme_font_size_override("font_size", 13)
		star_lbl.add_theme_color_override("font_color", Color("#FBBF24") if is_unlocked else Color("#64748B"))
		meta_row.add_child(star_lbl)
		vbox.add_child(meta_row)

		# Action Button covering the card or attached
		var select_btn: Button = Button.new()
		select_btn.custom_minimum_size = Vector2(0, 48)
		select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not is_unlocked:
			var prev_name: String = TIER_DATA[tier_num - 2]["title"].split(" — ")[0]
			select_btn.text = "🔒 Complete %s to unlock" % prev_name
			select_btn.disabled = true
			select_btn.modulate = Color(0.45, 0.45, 0.5, 0.7)
		else:
			select_btn.text = "SELECT %s ▶" % info["title"].split(" — ")[0]
			select_btn.modulate = info["color"]

		var captured_tier: int = tier_num
		select_btn.focus_entered.connect(func():
			if background and background.has_method("set_difficulty_tier"):
				background.set_difficulty_tier(captured_tier)
		)
		select_btn.mouse_entered.connect(func():
			if background and background.has_method("set_difficulty_tier"):
				background.set_difficulty_tier(captured_tier)
		)
		select_btn.pressed.connect(func():
			if AudioManager:
				AudioManager.play_sfx("ui_click")
			if SaveManager:
				SaveManager.selected_difficulty_tier = captured_tier
			SceneRouter.go_to_level_select()
		)
		vbox.add_child(select_btn)

		cards_container.add_child(card)

