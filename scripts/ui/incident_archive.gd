class_name IncidentArchive
extends Control

## UI Controller for the Incident Archive.
## Displays recovered Meridian Facility lore, MORROW transmissions, research logs,
## facility records, and the Project PALIMPSEST timeline.

const NarrativeRegistryClass = preload("res://scripts/narrative/narrative_registry.gd")
const ThemeManagerClass = preload("res://scripts/background/background_theme_manager.gd")

enum Tab {
	TRANSMISSIONS,
	LOGS,
	RECORDS,
	TIMELINE
}

var current_tab: Tab = Tab.TRANSMISSIONS

@onready var background: Control = $TemporalBackground
@onready var btn_back: Button = $MainContainer/VBoxContainer/Header/TopRow/BackButton
@onready var status_label: Label = $MainContainer/VBoxContainer/Header/ProgressBarContainer/ArchiveStatusLabel
@onready var tab_transmissions: Button = $MainContainer/VBoxContainer/TabBar/TabTransmissions
@onready var tab_logs: Button = $MainContainer/VBoxContainer/TabBar/TabLogs
@onready var tab_records: Button = $MainContainer/VBoxContainer/TabBar/TabRecords
@onready var tab_timeline: Button = $MainContainer/VBoxContainer/TabBar/TabTimeline
@onready var entries_list: VBoxContainer = $MainContainer/VBoxContainer/ContentScroll/EntriesList

# Reader Modal
@onready var reader_modal: PanelContainer = $ReaderModal
@onready var reader_category_label: Label = $ReaderModal/Margin/VBoxContainer/HeaderBox/CategoryLabel
@onready var reader_title_label: Label = $ReaderModal/Margin/VBoxContainer/HeaderBox/TitleLabel
@onready var reader_meta_label: Label = $ReaderModal/Margin/VBoxContainer/HeaderBox/MetaLabel
@onready var reader_text_label: Label = $ReaderModal/Margin/VBoxContainer/ScrollContainer/ContentLabel
@onready var btn_close_reader: Button = $ReaderModal/Margin/VBoxContainer/ButtonsRow/BtnCloseReader
@onready var btn_replay_reader: Button = $ReaderModal/Margin/VBoxContainer/ButtonsRow/BtnReplay

var _current_active_entry: Dictionary = {}

func _ready() -> void:
	reader_modal.visible = false

	if background and background.has_method("set_screen_mode"):
		background.set_screen_mode(ThemeManagerClass.ScreenMode.SETTINGS)

	_bind_signals()
	_style_components()
	_apply_safe_area()

	if AndroidSystemManager:
		AndroidSystemManager.safe_area_changed.connect(func(_m): _apply_safe_area())

	_update_tab_buttons()
	_render_current_tab()

func _apply_safe_area() -> void:
	if not AndroidSystemManager:
		return
	var margins = AndroidSystemManager.get_safe_margins()
	var top_m: int = maxi(int(margins.get("top", 0)), 16)
	var bottom_m: int = maxi(int(margins.get("bottom", 0)), 16)
	var left_m: int = maxi(int(margins.get("left", 0)), 16)
	var right_m: int = maxi(int(margins.get("right", 0)), 16)

	var mc = $MainContainer
	if mc:
		mc.add_theme_constant_override("margin_top", top_m + 8)
		mc.add_theme_constant_override("margin_bottom", bottom_m + 8)
		mc.add_theme_constant_override("margin_left", left_m + 8)
		mc.add_theme_constant_override("margin_right", right_m + 8)

func _bind_signals() -> void:
	btn_back.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("ui_click")
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
		SceneRouter.go_to_main_menu()
	)

	tab_transmissions.pressed.connect(func(): _select_tab(Tab.TRANSMISSIONS))
	tab_logs.pressed.connect(func(): _select_tab(Tab.LOGS))
	tab_records.pressed.connect(func(): _select_tab(Tab.RECORDS))
	tab_timeline.pressed.connect(func(): _select_tab(Tab.TIMELINE))

	btn_close_reader.pressed.connect(_close_reader)
	btn_replay_reader.pressed.connect(_on_replay_transmission)

func _select_tab(tab: Tab) -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
	current_tab = tab
	_update_tab_buttons()
	_render_current_tab()

func _update_tab_buttons() -> void:
	tab_transmissions.button_pressed = (current_tab == Tab.TRANSMISSIONS)
	tab_logs.button_pressed = (current_tab == Tab.LOGS)
	tab_records.button_pressed = (current_tab == Tab.RECORDS)
	tab_timeline.button_pressed = (current_tab == Tab.TIMELINE)

	var active_color = Color("#54E6EA")
	var dim_color = Color("#94A3B8")

	tab_transmissions.add_theme_color_override("font_color", active_color if current_tab == Tab.TRANSMISSIONS else dim_color)
	tab_logs.add_theme_color_override("font_color", active_color if current_tab == Tab.LOGS else dim_color)
	tab_records.add_theme_color_override("font_color", active_color if current_tab == Tab.RECORDS else dim_color)
	tab_timeline.add_theme_color_override("font_color", active_color if current_tab == Tab.TIMELINE else dim_color)

func _render_current_tab() -> void:
	for child in entries_list.get_children():
		child.queue_free()

	_update_header_status()

	match current_tab:
		Tab.TRANSMISSIONS:
			_render_transmissions()
		Tab.LOGS:
			_render_logs()
		Tab.RECORDS:
			_render_records()
		Tab.TIMELINE:
			_render_timeline()

func _update_header_status() -> void:
	if not SaveManager:
		return
	var prog = SaveManager.get_archive_progress()
	var pct: float = prog.get("percentage", 0.0)
	var unl: int = prog.get("unlocked", 0)
	var tot: int = prog.get("total", 0)
	status_label.text = "ARCHIVE STATUS: %d%% RESTORED (%d / %d RECORDS)" % [int(round(pct)), unl, tot]

# ==============================================================================
# TAB RENDERERS
# ==============================================================================

func _render_transmissions() -> void:
	var transmissions = NarrativeRegistryClass.get_all_transmissions()
	for trans in transmissions:
		var tid: String = trans.get("id", "")
		var is_unlocked: bool = SaveManager and SaveManager.is_transmission_unlocked(tid)
		var lvl_id: String = trans.get("level_id", "")
		var ch_info = NarrativeRegistryClass.get_chapter_info(lvl_id)
		var ch_name = "%s: %s" % [ch_info.get("code", "CH"), ch_info.get("title", "")]
		var type_str = trans.get("type", "OPENING")

		var card = _create_card_container(is_unlocked)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		if is_unlocked:
			var title_lbl = Label.new()
			title_lbl.text = "✦ %s // %s TRANSMISSION" % [ch_name, type_str]
			title_lbl.add_theme_color_override("font_color", Color("#54E6EA"))
			title_lbl.add_theme_font_size_override("font_size", 14)
			vbox.add_child(title_lbl)

			var sub_lbl = Label.new()
			sub_lbl.text = "%s  |  %s" % [trans.get("sender", "MORROW"), trans.get("channel", "LINK")]
			sub_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
			sub_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(sub_lbl)

			var btn = Button.new()
			btn.text = "VIEW TRANSMISSION ▶"
			btn.custom_minimum_size = Vector2(0, 40)
			btn.pressed.connect(func():
				_open_reader(
					"%s // %s" % [ch_name, type_str],
					"%s\n%s" % [trans.get("sender", ""), trans.get("channel", "")],
					"\n\n".join(trans.get("lines", [])),
					"MORROW COMMUNICATION DISPATCH",
					true,
					trans
				)
			)
			vbox.add_child(btn)
		else:
			var locked_lbl = Label.new()
			locked_lbl.text = "🔒 [CORRUPTED // COMPLETE %s TO DECRYPT]" % ch_name
			locked_lbl.add_theme_color_override("font_color", Color("#64748B"))
			locked_lbl.add_theme_font_size_override("font_size", 13)
			vbox.add_child(locked_lbl)

		entries_list.add_child(card)

func _render_logs() -> void:
	var logs = NarrativeRegistryClass.get_all_logs()
	for log_entry in logs:
		var lid: String = log_entry.get("id", "")
		var is_unlocked: bool = SaveManager and SaveManager.is_log_unlocked(lid)
		var is_read: bool = SaveManager and SaveManager.is_log_read(lid)

		var card = _create_card_container(is_unlocked)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		if is_unlocked:
			var hbox = HBoxContainer.new()
			var title_lbl = Label.new()
			title_lbl.text = "✦ %s: %s" % [lid.to_upper(), log_entry.get("title", "")]
			title_lbl.add_theme_color_override("font_color", Color("#38BDF8"))
			title_lbl.add_theme_font_size_override("font_size", 14)
			title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(title_lbl)

			if not is_read:
				var new_badge = Label.new()
				new_badge.text = "[NEW]"
				new_badge.add_theme_color_override("font_color", Color("#FBBF24"))
				new_badge.add_theme_font_size_override("font_size", 12)
				hbox.add_child(new_badge)

			vbox.add_child(hbox)

			var meta_lbl = Label.new()
			meta_lbl.text = "Author: %s  |  Date: %s" % [log_entry.get("author", "Unknown"), log_entry.get("date", "Unknown")]
			meta_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
			meta_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(meta_lbl)

			var btn = Button.new()
			btn.text = "READ RESEARCH LOG ▶"
			btn.custom_minimum_size = Vector2(0, 40)
			btn.pressed.connect(func():
				if SaveManager:
					SaveManager.mark_log_read(lid)
				_open_reader(
					"%s: %s" % [lid.to_upper(), log_entry.get("title", "")],
					"Author: %s\nDate: %s\nClassification: %s" % [log_entry.get("author", ""), log_entry.get("date", ""), log_entry.get("classification", "")],
					log_entry.get("content", ""),
					"MERIDIAN RESEARCH LOG // RECOVERED",
					false,
					log_entry
				)
			)
			vbox.add_child(btn)
		else:
			var locked_lbl = Label.new()
			var unlock_lvl = log_entry.get("unlock_level", 1)
			locked_lbl.text = "🔒 [CLASSIFIED LOG // RESTORE IN LEVEL %02d]" % unlock_lvl
			locked_lbl.add_theme_color_override("font_color", Color("#64748B"))
			locked_lbl.add_theme_font_size_override("font_size", 13)
			vbox.add_child(locked_lbl)

		entries_list.add_child(card)

func _render_records() -> void:
	var records = NarrativeRegistryClass.get_all_facility_records()
	for rec in records:
		var is_unlocked: bool = SaveManager and SaveManager.is_record_unlocked(rec)

		var card = _create_card_container(is_unlocked)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		if is_unlocked:
			var title_lbl = Label.new()
			title_lbl.text = "✦ %s" % rec.get("title", "")
			title_lbl.add_theme_color_override("font_color", Color("#34D399"))
			title_lbl.add_theme_font_size_override("font_size", 14)
			vbox.add_child(title_lbl)

			var cat_lbl = Label.new()
			cat_lbl.text = "Category: %s  |  %s" % [rec.get("category", ""), rec.get("classification", "")]
			cat_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
			cat_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(cat_lbl)

			var btn = Button.new()
			btn.text = "INSPECT FACILITY RECORD ▶"
			btn.custom_minimum_size = Vector2(0, 40)
			btn.pressed.connect(func():
				_open_reader(
					rec.get("title", ""),
					"Category: %s\nClassification: %s" % [rec.get("category", ""), rec.get("classification", "")],
					rec.get("content", ""),
					"FACILITY DIRECTIVE & SCHEMATIC",
					false,
					rec
				)
			)
			vbox.add_child(btn)
		else:
			var locked_lbl = Label.new()
			var req_lvl = rec.get("unlock_level", 1)
			locked_lbl.text = "🔒 [RESTRICTED SCHEMATIC // REACH LEVEL %02d]" % req_lvl
			locked_lbl.add_theme_color_override("font_color", Color("#64748B"))
			locked_lbl.add_theme_font_size_override("font_size", 13)
			vbox.add_child(locked_lbl)

		entries_list.add_child(card)

func _render_timeline() -> void:
	var timeline = NarrativeRegistryClass.get_all_timeline_entries()
	for entry in timeline:
		var is_unlocked: bool = SaveManager and SaveManager.is_timeline_unlocked(entry)

		var card = _create_card_container(is_unlocked)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		if is_unlocked:
			var time_lbl = Label.new()
			time_lbl.text = "⏱ %s // %s" % [entry.get("timestamp", ""), entry.get("title", "")]
			time_lbl.add_theme_color_override("font_color", Color("#FBBF24"))
			time_lbl.add_theme_font_size_override("font_size", 14)
			vbox.add_child(time_lbl)

			var summary_lbl = Label.new()
			summary_lbl.text = entry.get("summary", "")
			summary_lbl.add_theme_color_override("font_color", Color("#E2E8F0"))
			summary_lbl.add_theme_font_size_override("font_size", 13)
			summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(summary_lbl)
		else:
			var locked_lbl = Label.new()
			var req_lvl = entry.get("unlock_level", 1)
			locked_lbl.text = "🔒 [TEMPORAL RECORD ENCRYPTED // REACH LEVEL %02d]" % req_lvl
			locked_lbl.add_theme_color_override("font_color", Color("#64748B"))
			locked_lbl.add_theme_font_size_override("font_size", 13)
			vbox.add_child(locked_lbl)

		entries_list.add_child(card)

func _create_card_container(unlocked: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.16, 0.92) if unlocked else Color(0.04, 0.05, 0.09, 0.75)
	sb.border_color = Color(0.33, 0.90, 0.92, 0.5) if unlocked else Color(0.2, 0.25, 0.35, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	return panel

# ==============================================================================
# READER MODAL
# ==============================================================================

func _open_reader(title: String, meta: String, content: String, category: String, is_trans: bool, raw_data: Dictionary) -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
	_current_active_entry = raw_data
	reader_category_label.text = category
	reader_title_label.text = title
	reader_meta_label.text = meta
	reader_text_label.text = content
	btn_replay_reader.visible = is_trans
	reader_modal.visible = true

func _close_reader() -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
	reader_modal.visible = false
	_render_current_tab()

func _on_replay_transmission() -> void:
	# If transmission, replay lines
	if _current_active_entry.has("lines"):
		reader_text_label.text = "\n\n".join(_current_active_entry.get("lines", []))
	if AudioManager: AudioManager.play_sfx("ui_click")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")

func handle_back_button() -> bool:
	if reader_modal and reader_modal.visible:
		_close_reader()
		return true
	SceneRouter.go_to_main_menu()
	return true

func _style_components() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.13, 0.98)
	sb.border_color = Color(0.329, 0.902, 0.918, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0.329, 0.902, 0.918, 0.2)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 4)
	if reader_modal:
		reader_modal.add_theme_stylebox_override("panel", sb)

