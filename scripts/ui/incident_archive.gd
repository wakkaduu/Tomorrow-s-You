class_name IncidentArchive
extends Control

## UI Controller for the Incident Archive.
## Displays recovered Meridian Facility lore, MORROW transmissions, research logs,
## facility records, and the Project PALIMPSEST timeline.
## Features a classified research terminal aesthetic and cinematic transmission replay.

const NarrativeRegistryClass = preload("res://scripts/narrative/narrative_registry.gd")
const ThemeManagerClass = preload("res://scripts/background/background_theme_manager.gd")
const UIDesignSystemClass = preload("res://scripts/ui/components/ui_design_system.gd")
const MorrowVisualizerClass = preload("res://scripts/ui/components/morrow_visualizer.gd")

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
@onready var restoration_bar: ProgressBar = $MainContainer/VBoxContainer/Header/ProgressBarContainer/RestorationBar
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
@onready var reader_integrity_label: Label = $ReaderModal/Margin/VBoxContainer/HeaderBox/IntegrityLabel
@onready var reader_text_label: Label = $ReaderModal/Margin/VBoxContainer/ScrollContainer/ContentLabel
@onready var btn_close_reader: Button = $ReaderModal/Margin/VBoxContainer/ButtonsRow/BtnCloseReader
@onready var btn_replay_reader: Button = $ReaderModal/Margin/VBoxContainer/ButtonsRow/BtnReplay

# Cinematic Transmission Modal (Inside Archive)
@onready var transmission_modal: PanelContainer = $TransmissionModal
@onready var transmission_sender: Label = $TransmissionModal/Margin/VBoxContainer/HeaderBox/SenderLabel
@onready var transmission_channel: Label = $TransmissionModal/Margin/VBoxContainer/HeaderBox/ChannelLabel
@onready var transmission_meta: Label = $TransmissionModal/Margin/VBoxContainer/HeaderBox/MetaLabel
@onready var transmission_content: Label = $TransmissionModal/Margin/VBoxContainer/ScrollContainer/TransmissionContent
@onready var morrow_core: Control = $TransmissionModal/Margin/VBoxContainer/VisualizerContainer/MorrowCore
@onready var transmission_signal_status: Label = $TransmissionModal/Margin/VBoxContainer/VisualizerContainer/SignalStatusLabel
@onready var transmission_line_progress: Label = $TransmissionModal/Margin/VBoxContainer/ProgressRow/LineProgressLabel
@onready var btn_skip_transmission: Button = $TransmissionModal/Margin/VBoxContainer/ButtonsRow/BtnSkipTransmission
@onready var btn_proceed_transmission: Button = $TransmissionModal/Margin/VBoxContainer/ButtonsRow/BtnProceedTransmission

var _current_active_entry: Dictionary = {}
var _active_transmission: Dictionary = {}
var _current_transmission_line: int = 0
var _typewriter_active: bool = false
var _typewriter_chars_per_sec: float = 40.0
var _typewriter_elapsed: float = 0.0
var _typewriter_target_len: int = 0

func _ready() -> void:
	reader_modal.visible = false
	if transmission_modal:
		transmission_modal.visible = false

	if background and background.has_method("set_screen_mode"):
		background.set_screen_mode(ThemeManagerClass.ScreenMode.SETTINGS)

	_bind_signals()
	_style_components()
	_apply_safe_area()

	if AndroidSystemManager:
		AndroidSystemManager.safe_area_changed.connect(func(_m): _apply_safe_area())

	_update_tab_buttons()
	_render_current_tab()

func _process(delta: float) -> void:
	if _typewriter_active and transmission_modal and transmission_modal.visible:
		if SaveManager and SaveManager.reduced_animations:
			transmission_content.visible_characters = -1
			_typewriter_active = false
		else:
			_typewriter_elapsed += delta
			var chars: int = int(_typewriter_elapsed * _typewriter_chars_per_sec)
			if chars >= _typewriter_target_len:
				transmission_content.visible_characters = -1
				_typewriter_active = false
			else:
				transmission_content.visible_characters = chars

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

	if btn_skip_transmission:
		btn_skip_transmission.pressed.connect(_close_transmission)
	if btn_proceed_transmission:
		btn_proceed_transmission.pressed.connect(_advance_transmission)

	if transmission_content:
		transmission_content.mouse_filter = Control.MOUSE_FILTER_STOP
		transmission_content.gui_input.connect(func(event: InputEvent):
			if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				if _typewriter_active:
					transmission_content.visible_characters = -1
					_typewriter_active = false
					if AudioManager: AudioManager.play_sfx("ui_click")
		)

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

	var tab_list = [
		[tab_transmissions, "Transmissions", "icon_transmission", current_tab == Tab.TRANSMISSIONS],
		[tab_logs, "Logs", "icon_logs", current_tab == Tab.LOGS],
		[tab_records, "Records", "icon_records", current_tab == Tab.RECORDS],
		[tab_timeline, "Timeline", "icon_timeline", current_tab == Tab.TIMELINE]
	]

	for item in tab_list:
		var btn: Button = item[0]
		var title: String = item[1]
		var icon_name: String = item[2]
		var is_active: bool = item[3]
		btn.text = title
		UIDesignSystemClass.apply_button_icon(btn, icon_name, HORIZONTAL_ALIGNMENT_LEFT)
		btn.add_theme_stylebox_override("normal", UIDesignSystemClass.create_tab_style(is_active))
		btn.add_theme_stylebox_override("hover", UIDesignSystemClass.create_tab_style(is_active))
		btn.add_theme_stylebox_override("pressed", UIDesignSystemClass.create_tab_style(true))
		var active_col = UIDesignSystemClass.COLOR_CYAN_PRIMARY
		var dim_col = UIDesignSystemClass.COLOR_TEXT_SECONDARY
		btn.add_theme_color_override("font_color", active_col if is_active else dim_col)
		btn.add_theme_color_override("icon_normal_color", active_col if is_active else dim_col)
		btn.add_theme_color_override("icon_hover_color", Color.WHITE)
		btn.add_theme_color_override("icon_pressed_color", active_col)

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
	status_label.text = "Archive Restoration: %d%% (%d / %d Records Recovered)" % [int(round(pct)), unl, tot]
	if restoration_bar:
		restoration_bar.value = pct

# ==============================================================================
# TAB RENDERERS
# ==============================================================================

func _create_locked_row(message: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var lock_icon = TextureRect.new()
	lock_icon.texture = UIDesignSystemClass.get_icon("icon_locked")
	lock_icon.custom_minimum_size = Vector2(16, 16)
	lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_icon.modulate = UIDesignSystemClass.COLOR_TEXT_DIM
	hbox.add_child(lock_icon)

	var locked_lbl = Label.new()
	locked_lbl.text = message
	locked_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIDesignSystemClass.apply_technical_text(locked_lbl, 12, UIDesignSystemClass.COLOR_TEXT_DIM)
	hbox.add_child(locked_lbl)
	return hbox

func _create_status_badge(text: String, icon_name: String, color: Color) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)
	var icon_rect = TextureRect.new()
	icon_rect.texture = UIDesignSystemClass.get_icon(icon_name)
	icon_rect.custom_minimum_size = Vector2(14, 14)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.modulate = color
	hbox.add_child(icon_rect)

	var lbl = Label.new()
	lbl.text = text
	UIDesignSystemClass.apply_technical_text(lbl, 11, color, "Bold")
	hbox.add_child(lbl)
	return hbox

func _render_transmissions() -> void:
	var transmissions = NarrativeRegistryClass.get_all_transmissions()
	var idx: int = 1
	for trans in transmissions:
		var tid: String = trans.get("id", "")
		var is_unlocked: bool = SaveManager and SaveManager.is_transmission_unlocked(tid)
		var lvl_id: String = trans.get("level_id", "")
		var ch_info = NarrativeRegistryClass.get_chapter_info(lvl_id)
		var ch_name = "%s: %s" % [ch_info.get("code", "CH"), ch_info.get("title", "")]
		var type_str = trans.get("type", "OPENING")

		var card = _create_card_container(is_unlocked, UIDesignSystemClass.COLOR_CYAN_PRIMARY)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)

		if is_unlocked:
			var top_row = HBoxContainer.new()
			var num_badge = Label.new()
			num_badge.text = "COMM #%02d" % idx
			num_badge.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_MUTED)
			num_badge.add_theme_font_size_override("font_size", 11)
			top_row.add_child(num_badge)

			var spacer = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_row.add_child(spacer)

			var status_pill = _create_status_badge("Restored", "icon_complete", UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
			top_row.add_child(status_pill)
			vbox.add_child(top_row)

			var title_lbl = Label.new()
			title_lbl.text = "%s // %s" % [ch_name, type_str]
			title_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_CYAN_PRIMARY)
			title_lbl.add_theme_font_size_override("font_size", 15)
			vbox.add_child(title_lbl)

			var sub_lbl = Label.new()
			sub_lbl.text = "Speaker: %s  •  Channel: %s" % [trans.get("sender", "MORROW"), trans.get("channel", "LINK")]
			sub_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_MUTED)
			sub_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(sub_lbl)

			var btn_row = HBoxContainer.new()
			btn_row.add_theme_constant_override("separation", 8)

			var btn_view = Button.new()
			btn_view.custom_minimum_size = Vector2(0, 44)
			btn_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UIDesignSystemClass.apply_secondary_button(btn_view, "View Transmission", "icon_transmission")
			var captured_trans = trans
			btn_view.pressed.connect(func():
				_open_reader(
					"%s // %s" % [ch_name, type_str],
					"Speaker: %s\nChannel: %s" % [captured_trans.get("sender", ""), captured_trans.get("channel", "")],
					"\n\n".join(captured_trans.get("lines", [])),
					"MORROW COMMUNICATION DISPATCH",
					true,
					captured_trans
				)
			)
			btn_row.add_child(btn_view)

			var btn_play = Button.new()
			btn_play.custom_minimum_size = Vector2(110, 44)
			UIDesignSystemClass.apply_primary_button(btn_play, "Replay", "icon_play")
			btn_play.pressed.connect(func():
				_show_cinematic_transmission(captured_trans)
			)
			btn_row.add_child(btn_play)

			vbox.add_child(btn_row)
		else:
			vbox.add_child(_create_locked_row("Restricted Transmission // Complete %s to Decrypt" % ch_name))

		entries_list.add_child(card)
		idx += 1

func _render_logs() -> void:
	var logs = NarrativeRegistryClass.get_all_logs()
	for log_entry in logs:
		var lid: String = log_entry.get("id", "")
		var is_unlocked: bool = SaveManager and SaveManager.is_log_unlocked(lid)
		var is_read: bool = SaveManager and SaveManager.is_log_read(lid)

		var card = _create_card_container(is_unlocked, UIDesignSystemClass.COLOR_CYAN_PRIMARY)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)

		if is_unlocked:
			var top_row = HBoxContainer.new()
			var num_lbl = Label.new()
			num_lbl.text = "RECORD #%s" % log_entry.get("number", "000")
			num_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_MUTED)
			num_lbl.add_theme_font_size_override("font_size", 11)
			top_row.add_child(num_lbl)

			var spacer = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_row.add_child(spacer)

			var badge = _create_status_badge("New Entry", "icon_unread", UIDesignSystemClass.COLOR_AMBER_WARN) if not is_read else _create_status_badge("Verified Log", "icon_complete", UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
			top_row.add_child(badge)
			vbox.add_child(top_row)

			var title_lbl = Label.new()
			title_lbl.text = log_entry.get("title", "")
			title_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_CYAN_PRIMARY)
			title_lbl.add_theme_font_size_override("font_size", 15)
			vbox.add_child(title_lbl)

			var meta_lbl = Label.new()
			meta_lbl.text = "Author: %s  •  Date: %s" % [log_entry.get("author", "Unknown"), log_entry.get("date", "Unknown")]
			meta_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_MUTED)
			meta_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(meta_lbl)

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 44)
			if not is_read:
				UIDesignSystemClass.apply_primary_button(btn, "Read Research Log", "icon_logs")
			else:
				UIDesignSystemClass.apply_secondary_button(btn, "Read Research Log", "icon_logs")
			var captured_log = log_entry
			var captured_lid = lid
			btn.pressed.connect(func():
				if SaveManager:
					SaveManager.mark_log_read(captured_lid)
				_open_reader(
					"%s: %s" % [captured_lid.to_upper(), captured_log.get("title", "")],
					"Author: %s\nDate: %s\nClassification: %s" % [captured_log.get("author", ""), captured_log.get("date", ""), captured_log.get("classification", "")],
					captured_log.get("content", ""),
					"MERIDIAN RESEARCH LOG // RECOVERED",
					false,
					captured_log
				)
			)
			vbox.add_child(btn)
		else:
			var unlock_lvl = log_entry.get("unlock_level", 1)
			vbox.add_child(_create_locked_row("Classified Research Log // Recover in Sector %02d" % unlock_lvl))

		entries_list.add_child(card)

func _render_records() -> void:
	var records = NarrativeRegistryClass.get_all_facility_records()
	var idx: int = 1
	for rec in records:
		var is_unlocked: bool = SaveManager and SaveManager.is_record_unlocked(rec)

		var card = _create_card_container(is_unlocked, UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)

		if is_unlocked:
			var top_row = HBoxContainer.new()
			var num_lbl = Label.new()
			num_lbl.text = "FACILITY RECORD #%02d" % idx
			num_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_MUTED)
			num_lbl.add_theme_font_size_override("font_size", 11)
			top_row.add_child(num_lbl)

			var spacer = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_row.add_child(spacer)

			var class_badge = _create_status_badge(rec.get("classification", "RESTRICTED"), "icon_restricted", UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
			top_row.add_child(class_badge)
			vbox.add_child(top_row)

			var title_lbl = Label.new()
			title_lbl.text = rec.get("title", "")
			title_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
			title_lbl.add_theme_font_size_override("font_size", 15)
			vbox.add_child(title_lbl)

			var cat_lbl = Label.new()
			cat_lbl.text = "Category: %s" % rec.get("category", "")
			cat_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_MUTED)
			cat_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(cat_lbl)

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 44)
			UIDesignSystemClass.apply_secondary_button(btn, "Inspect Directive", "icon_records", UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
			var captured_rec = rec
			btn.pressed.connect(func():
				_open_reader(
					captured_rec.get("title", ""),
					"Category: %s\nClassification: %s" % [captured_rec.get("category", ""), captured_rec.get("classification", "")],
					captured_rec.get("content", ""),
					"FACILITY DIRECTIVE & SCHEMATIC",
					false,
					captured_rec
				)
			)
			vbox.add_child(btn)
		else:
			var req_lvl = rec.get("unlock_level", 1)
			vbox.add_child(_create_locked_row("Restricted Schematic // Reach Level %02d" % req_lvl))

		entries_list.add_child(card)
		idx += 1

func _render_timeline() -> void:
	var timeline = NarrativeRegistryClass.get_all_timeline_entries()
	for entry in timeline:
		var is_unlocked: bool = SaveManager and SaveManager.is_timeline_unlocked(entry)

		var card = _create_card_container(is_unlocked, UIDesignSystemClass.COLOR_AMBER_WARN)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		card.add_child(vbox)

		if is_unlocked:
			var top_row = HBoxContainer.new()
			var time_lbl = Label.new()
			time_lbl.text = entry.get("timestamp", "")
			time_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_AMBER_WARN)
			time_lbl.add_theme_font_size_override("font_size", 12)
			top_row.add_child(time_lbl)

			var spacer = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			top_row.add_child(spacer)

			var auth_badge = _create_status_badge("Parity Secure", "icon_complete", UIDesignSystemClass.COLOR_EMERALD_SUCCESS)
			top_row.add_child(auth_badge)
			vbox.add_child(top_row)

			var title_lbl = Label.new()
			title_lbl.text = entry.get("title", "")
			title_lbl.add_theme_color_override("font_color", UIDesignSystemClass.COLOR_TEXT_PRIMARY)
			title_lbl.add_theme_font_size_override("font_size", 15)
			vbox.add_child(title_lbl)

			var summary_lbl = Label.new()
			summary_lbl.text = entry.get("summary", "")
			summary_lbl.add_theme_color_override("font_color", Color("#CBD5E1"))
			summary_lbl.add_theme_font_size_override("font_size", 13)
			summary_lbl.theme_override_constants_set("line_spacing", 4)
			summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(summary_lbl)
		else:
			var req_lvl = entry.get("unlock_level", 1)
			vbox.add_child(_create_locked_row("Temporal Record Encrypted // Reach Level %02d" % req_lvl))

		entries_list.add_child(card)

func _create_card_container(unlocked: bool, accent_color: Color = UIDesignSystemClass.COLOR_CYAN_PRIMARY) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIDesignSystemClass.create_card_style(accent_color, unlocked, false))
	panel.custom_minimum_size = Vector2(0, 72)
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
	btn_replay_reader.text = "REPLAY AUDIO ▶"
	reader_modal.visible = true

func _close_reader() -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
	reader_modal.visible = false
	_render_current_tab()

func _on_replay_transmission() -> void:
	if _current_active_entry.is_empty():
		return
	_close_reader()
	_show_cinematic_transmission(_current_active_entry)

# ==============================================================================
# CINEMATIC TRANSMISSION OVERLAY (ARCHIVE REPLAY)
# ==============================================================================

func _show_cinematic_transmission(trans: Dictionary) -> void:
	if trans.is_empty() or not transmission_modal:
		return

	_active_transmission = trans
	var lines: Array = trans.get("lines", [])
	_current_transmission_line = 0

	var tid = trans.get("id", "unknown")
	var cat_name: String = NarrativeRegistryClass.get_transmission_category(tid)
	var cat_enum = MorrowVisualizerClass.Category.NORMAL
	var border_color = UIDesignSystemClass.COLOR_CYAN_PRIMARY
	var status_text = "● CARRIER LOCK // RESONANCE STABLE"

	match cat_name:
		"EMERGENCY":
			cat_enum = MorrowVisualizerClass.Category.EMERGENCY
			border_color = UIDesignSystemClass.COLOR_AMBER_WARN
			status_text = "● WARNING // FREQUENCY JITTER DETECTED"
		"CORRUPTED":
			cat_enum = MorrowVisualizerClass.Category.CORRUPTED
			border_color = UIDesignSystemClass.COLOR_VIOLET_ECHO
			status_text = "● DATA CORRUPTION // MEMORY PACKET LOSS"
		"FINAL":
			cat_enum = MorrowVisualizerClass.Category.FINAL
			border_color = Color(1.0, 0.84, 0.36)
			status_text = "● FINAL HARMONICS // TEMPORAL STABILIZATION"

	if morrow_core and morrow_core.has_method("set_category"):
		morrow_core.set_category(cat_enum)

	if transmission_signal_status:
		transmission_signal_status.text = status_text
		transmission_signal_status.add_theme_color_override("font_color", border_color)

	var panel_sb = UIDesignSystemClass.create_panel_style(border_color, Color(0.02, 0.035, 0.07, 0.98), 2, 14, 20)
	transmission_modal.add_theme_stylebox_override("panel", panel_sb)

	transmission_sender.text = trans.get("sender", "MORROW // FACILITY AI")
	transmission_channel.text = trans.get("channel", "EMERGENCY CONTAINMENT LINK")

	var lvl_id: String = trans.get("level_id", "")
	var ch_info = NarrativeRegistryClass.get_chapter_info(lvl_id)
	if transmission_meta:
		var ch_str = "%s // %s" % [ch_info.get("code", "CH-01"), ch_info.get("title", "SECTOR")]
		transmission_meta.text = "%s  •  %s" % [ch_str, tid.to_upper()]

	_display_transmission_line(0)
	transmission_modal.visible = true

	if AudioManager: AudioManager.play_sfx("ui_click")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")

func _display_transmission_line(idx: int) -> void:
	var lines: Array = _active_transmission.get("lines", [])
	_current_transmission_line = idx
	var text: String = lines[idx] if idx < lines.size() else ""
	transmission_content.text = text
	_typewriter_target_len = text.length()
	_typewriter_elapsed = 0.0
	_typewriter_active = true
	transmission_content.visible_characters = 0

	if transmission_line_progress:
		transmission_line_progress.text = "LINE %02d / %02d" % [idx + 1, lines.size()]

	btn_proceed_transmission.text = "NEXT ▶" if (idx < lines.size() - 1) else "PROCEED ▶"

func _advance_transmission() -> void:
	var lines: Array = _active_transmission.get("lines", [])
	_current_transmission_line += 1
	if _current_transmission_line < lines.size():
		_display_transmission_line(_current_transmission_line)
		if AudioManager: AudioManager.play_sfx("ui_click")
		if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")
	else:
		_close_transmission()

func _close_transmission() -> void:
	transmission_modal.visible = false
	_typewriter_active = false
	_active_transmission = {}
	if AudioManager: AudioManager.play_sfx("ui_click")
	if AndroidSystemManager: AndroidSystemManager.trigger_haptic("button")

func handle_back_button() -> bool:
	if transmission_modal and transmission_modal.visible:
		_close_transmission()
		return true
	if reader_modal and reader_modal.visible:
		_close_reader()
		return true
	SceneRouter.go_to_main_menu()
	return true

func _style_components() -> void:
	if reader_modal:
		reader_modal.add_theme_stylebox_override("panel", UIDesignSystemClass.create_panel_style(UIDesignSystemClass.COLOR_CYAN_PRIMARY, Color(0.04, 0.065, 0.12, 0.98), 1, 14, 14))
	if btn_close_reader:
		UIDesignSystemClass.apply_primary_button(btn_close_reader, "Close Record", "icon_close")
	if btn_replay_reader:
		UIDesignSystemClass.apply_secondary_button(btn_replay_reader, "Replay Transmission", "icon_play")
	if btn_back:
		UIDesignSystemClass.apply_icon_button(btn_back, "icon_back", Vector2(48, 48))

	var header_title = $MainContainer/VBoxContainer/Header/TopRow/TitleBox/Title
	if header_title:
		UIDesignSystemClass.apply_display_heading(header_title, UIDesignSystemClass.FONT_SIZE_SCREEN_HEADING, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")
	var sub = $MainContainer/VBoxContainer/Header/TopRow/TitleBox/FacilitySubtitle
	if sub:
		UIDesignSystemClass.apply_technical_text(sub, 11, UIDesignSystemClass.COLOR_TEXT_MUTED, "SemiBold")
	if status_label:
		UIDesignSystemClass.apply_technical_text(status_label, 12, UIDesignSystemClass.COLOR_TEXT_MUTED, "SemiBold")

	# Document reader typography
	if reader_category_label:
		UIDesignSystemClass.apply_technical_text(reader_category_label, 12, UIDesignSystemClass.COLOR_CYAN_PRIMARY, "Bold")
	if reader_title_label:
		UIDesignSystemClass.apply_display_heading(reader_title_label, 20, UIDesignSystemClass.COLOR_TEXT_PRIMARY, "Bold")
	if reader_meta_label:
		UIDesignSystemClass.apply_technical_text(reader_meta_label, 12, UIDesignSystemClass.COLOR_TEXT_MUTED)
	if reader_integrity_label:
		UIDesignSystemClass.apply_technical_text(reader_integrity_label, 11, UIDesignSystemClass.COLOR_EMERALD_SUCCESS, "Bold")
	if reader_text_label:
		UIDesignSystemClass.apply_body_text(reader_text_label, 15, Color("#E2E8F0"))

	# Embedded transmission modal buttons
	if btn_proceed_transmission:
		UIDesignSystemClass.apply_primary_button(btn_proceed_transmission, "Proceed", "icon_next")
	if btn_skip_transmission:
		UIDesignSystemClass.apply_button_style(btn_skip_transmission, UIDesignSystemClass.ButtonType.TERTIARY)
		btn_skip_transmission.text = "Skip"
		UIDesignSystemClass.apply_button_icon(btn_skip_transmission, "icon_close")

	# Progress bar style
	if restoration_bar:
		var bg_sb = StyleBoxFlat.new()
		bg_sb.bg_color = Color(0.05, 0.08, 0.14, 0.9)
		bg_sb.border_color = UIDesignSystemClass.COLOR_BORDER_SUBTLE
		bg_sb.set_border_width_all(1)
		bg_sb.set_corner_radius_all(5)
		restoration_bar.add_theme_stylebox_override("background", bg_sb)

		var fill_sb = StyleBoxFlat.new()
		fill_sb.bg_color = UIDesignSystemClass.COLOR_CYAN_PRIMARY
		fill_sb.set_corner_radius_all(5)
		fill_sb.shadow_color = UIDesignSystemClass.COLOR_CYAN_GLOW
		fill_sb.shadow_size = 6
		restoration_bar.add_theme_stylebox_override("fill", fill_sb)
