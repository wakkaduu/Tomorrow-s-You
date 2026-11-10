class_name UIDesignSystem
extends RefCounted

## Master UI Design System V2 for Tomorrow's You.
## Provides standardized typography, color tokens, button components, and
## reusable StyleBox constructors across all game screens for a premium sci-fi interface.

# ==============================================================================
# 1. CANONICAL COLOR PALETTE & DESIGN TOKENS
# ==============================================================================

const COLOR_BG_VOID: Color = Color(0.024, 0.039, 0.078, 1.0)       # #060A14 - Deep Cosmic Void
const COLOR_BG_DEEP: Color = Color(0.043, 0.063, 0.125, 1.0)       # #0B1020 - Primary Screen Background
const COLOR_BG_SURFACE: Color = Color(0.078, 0.110, 0.180, 0.96)   # #141C2E - Secondary Background Surface
const COLOR_BG_ELEVATED: Color = Color(0.102, 0.141, 0.231, 0.95)  # #1A243B - Elevated Card Surface
const COLOR_BG_HOVER: Color = Color(0.133, 0.188, 0.306, 0.95)     # #22304E - Interactive Element Hover

const COLOR_CYAN_PRIMARY: Color = Color(0.329, 0.902, 0.918, 1.0)   # #54E6EA - Player Cyan / Primary Action
const COLOR_CYAN_DARK: Color = Color(0.035, 0.078, 0.110, 1.0)      # #09141C - Deep Navy for High-Contrast Text on Cyan
const COLOR_CYAN_HOVER: Color = Color(0.494, 0.957, 0.969, 1.0)     # #7EF5F7 - Brightened Cyan
const COLOR_CYAN_PRESSED: Color = Color(0.176, 0.722, 0.737, 1.0)   # #2DB8BC - Pressed Cyan
const COLOR_CYAN_GLOW: Color = Color(0.329, 0.902, 0.918, 0.35)    # Subtle Bloom Glow
const COLOR_CYAN_DIM: Color = Color(0.329, 0.902, 0.918, 0.14)

const COLOR_VIOLET_ECHO: Color = Color(0.655, 0.545, 0.980, 1.0)   # #A78BFA - Echo Violet
const COLOR_VIOLET_GLOW: Color = Color(0.655, 0.545, 0.980, 0.30)

const COLOR_AMBER_WARN: Color = Color(1.0, 0.745, 0.333, 1.0)       # #FFBE55 - Strategic Hint & Warning Amber
const COLOR_AMBER_GLOW: Color = Color(1.0, 0.745, 0.333, 0.30)

const COLOR_ROSE_ALERT: Color = Color(1.0, 0.392, 0.486, 1.0)       # #FF647C - Destructive & Hazard Coral Red
const COLOR_ROSE_GLOW: Color = Color(1.0, 0.392, 0.486, 0.30)

const COLOR_EMERALD_SUCCESS: Color = Color(0.204, 0.827, 0.600, 1.0)# #34D399 - Success & Synchronized Emerald

const COLOR_TEXT_PRIMARY: Color = Color(0.961, 0.969, 1.0, 1.0)     # #F5F7FF - Primary Reading Text
const COLOR_TEXT_SECONDARY: Color = Color(0.655, 0.690, 0.769, 1.0) # #A7B0C4 - Supporting Body & Subtitles
const COLOR_TEXT_MUTED: Color = Color(0.494, 0.545, 0.624, 1.0)     # #7E8B9F - Monospace & Technical Labels
const COLOR_TEXT_DIM: Color = Color(0.290, 0.333, 0.408, 1.0)       # #4A5568 - Disabled / Inactive Details
const COLOR_BORDER_SUBTLE: Color = Color(0.250, 0.380, 0.520, 0.35) # Architectural Divider Line

# ==============================================================================
# 2. TYPOGRAPHY ASSETS & HIERARCHY CONSTANTS
# ==============================================================================

# Font Paths
const FONT_PATH_OXANIUM_BOLD: String = "res://assets/fonts/Oxanium/Oxanium-Bold.ttf"
const FONT_PATH_OXANIUM_SEMIBOLD: String = "res://assets/fonts/Oxanium/Oxanium-SemiBold.ttf"
const FONT_PATH_OXANIUM_MEDIUM: String = "res://assets/fonts/Oxanium/Oxanium-Medium.ttf"
const FONT_PATH_OXANIUM_REGULAR: String = "res://assets/fonts/Oxanium/Oxanium-Regular.ttf"

const FONT_PATH_INTER_BOLD: String = "res://assets/fonts/Inter/Inter-Bold.ttf"
const FONT_PATH_INTER_SEMIBOLD: String = "res://assets/fonts/Inter/Inter-SemiBold.ttf"
const FONT_PATH_INTER_MEDIUM: String = "res://assets/fonts/Inter/Inter-Medium.ttf"
const FONT_PATH_INTER_REGULAR: String = "res://assets/fonts/Inter/Inter-Regular.ttf"

const FONT_PATH_MONO_BOLD: String = "res://assets/fonts/IBMPlexMono/IBMPlexMono-Bold.ttf"
const FONT_PATH_MONO_SEMIBOLD: String = "res://assets/fonts/IBMPlexMono/IBMPlexMono-SemiBold.ttf"
const FONT_PATH_MONO_MEDIUM: String = "res://assets/fonts/IBMPlexMono/IBMPlexMono-Medium.ttf"
const FONT_PATH_MONO_REGULAR: String = "res://assets/fonts/IBMPlexMono/IBMPlexMono-Regular.ttf"

# Type Size Hierarchy Tokens (Optimized for 720x1280 mobile portrait viewport)
const FONT_SIZE_MAIN_TITLE: int = 40
const FONT_SIZE_SCREEN_HEADING: int = 28
const FONT_SIZE_LEVEL_TITLE: int = 24
const FONT_SIZE_DIFFICULTY_TITLE: int = 22
const FONT_SIZE_SECTION_HEADING: int = 20
const FONT_SIZE_BUTTON: int = 16
const FONT_SIZE_BODY: int = 15
const FONT_SIZE_SUPPORTING: int = 13
const FONT_SIZE_METADATA: int = 12

# Geometry & Spacing Tokens
const CORNER_RADIUS_BUTTON: int = 8
const CORNER_RADIUS_CARD: int = 8
const CORNER_RADIUS_PANEL: int = 12
const CORNER_RADIUS_BADGE: int = 4
const MIN_TOUCH_SIZE: int = 48
const PRIMARY_ACTION_HEIGHT: int = 54

# Cached Font Instances
static var _fonts_cache: Dictionary = {}

static func get_font(path: String) -> Font:
	if _fonts_cache.has(path):
		return _fonts_cache[path]
	if ResourceLoader.exists(path):
		var f: Font = load(path)
		if f:
			_fonts_cache[path] = f
			return f
	return ThemeDB.fallback_font

static func get_display_font(weight: String = "SemiBold") -> Font:
	match weight.to_lower():
		"bold": return get_font(FONT_PATH_OXANIUM_BOLD)
		"medium": return get_font(FONT_PATH_OXANIUM_MEDIUM)
		"regular": return get_font(FONT_PATH_OXANIUM_REGULAR)
		_: return get_font(FONT_PATH_OXANIUM_SEMIBOLD)

static func get_interface_font(weight: String = "Regular") -> Font:
	match weight.to_lower():
		"bold": return get_font(FONT_PATH_INTER_BOLD)
		"semibold": return get_font(FONT_PATH_INTER_SEMIBOLD)
		"medium": return get_font(FONT_PATH_INTER_MEDIUM)
		_: return get_font(FONT_PATH_INTER_REGULAR)

static func get_technical_font(weight: String = "Regular") -> Font:
	match weight.to_lower():
		"bold": return get_font(FONT_PATH_MONO_BOLD)
		"semibold": return get_font(FONT_PATH_MONO_SEMIBOLD)
		"medium": return get_font(FONT_PATH_MONO_MEDIUM)
		_: return get_font(FONT_PATH_MONO_REGULAR)

# ==============================================================================
# 3. REUSABLE BUTTON TYPES
# ==============================================================================

enum ButtonType {
	PRIMARY,     ## Solid cyan fill, deep navy text, high-prominence action (Continue, Play, Create Echo, Next)
	SECONDARY,   ## Dark navy surface, cyan outline, crisp light text (Levels, Settings, Back)
	TERTIARY,    ## Subtle/transparent surface, muted text, minimal border (Skip, Cancel, Details)
	UTILITY,     ## Dark elevated surface with recognizable icon and controlled accent (Wait, Hint, Comm Log)
	DESTRUCTIVE, ## Dark hazard surface with coral-red accent (Restart, Reset Progress, Clear Echoes)
	ICON         ## Precision compact square button (>=48dp touch target) with centered vector icon
}

# ==============================================================================
# 4. STYLEBOX FACTORIES
# ==============================================================================

## Standard Terminal / Modal Panel Style
static func create_panel_style(
	border_color: Color = COLOR_CYAN_PRIMARY,
	bg_color: Color = COLOR_BG_SURFACE,
	border_width: int = 2,
	corner_radius: int = CORNER_RADIUS_PANEL,
	shadow_size: int = 16
) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	if shadow_size > 0:
		sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.25)
		sb.shadow_size = shadow_size
		sb.shadow_offset = Vector2(0, 4)
	return sb

## Reusable Card Style (Archive, Difficulty, Levels)
static func create_card_style(
	accent_color: Color = COLOR_CYAN_PRIMARY,
	is_unlocked: bool = true,
	is_highlighted: bool = false
) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(CORNER_RADIUS_CARD)

	if not is_unlocked:
		sb.bg_color = Color(0.045, 0.065, 0.105, 0.70)
		sb.border_color = Color(0.20, 0.26, 0.35, 0.30)
		sb.set_border_width_all(1)
		return sb

	if is_highlighted:
		sb.bg_color = Color(accent_color.r * 0.14, accent_color.g * 0.14, accent_color.b * 0.14, 0.96)
		sb.border_color = accent_color
		sb.set_border_width_all(2)
		sb.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.30)
		sb.shadow_size = 12
		sb.shadow_offset = Vector2(0, 3)
	else:
		sb.bg_color = COLOR_BG_ELEVATED
		sb.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.40)
		sb.set_border_width_all(1)

	return sb

## Classification / Status Badge Style
static func create_badge_style(accent_color: Color = COLOR_CYAN_PRIMARY) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(accent_color.r * 0.15, accent_color.g * 0.15, accent_color.b * 0.15, 0.85)
	sb.border_color = accent_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(CORNER_RADIUS_BADGE)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb

## Navigation Tab Style
static func create_tab_style(is_active: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(CORNER_RADIUS_BUTTON)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8

	if is_active:
		sb.bg_color = Color(0.329 * 0.18, 0.902 * 0.18, 0.918 * 0.18, 0.95)
		sb.border_color = COLOR_CYAN_PRIMARY
		sb.set_border_width_all(2)
		sb.shadow_color = Color(0.329, 0.902, 0.918, 0.25)
		sb.shadow_size = 8
	else:
		sb.bg_color = Color(0.06, 0.085, 0.14, 0.85)
		sb.border_color = COLOR_BORDER_SUBTLE
		sb.set_border_width_all(1)
	return sb

# ==============================================================================
# 5. BUTTON COMPONENT STYLING ENGINE
# ==============================================================================

## Apply complete visual styling to any Button according to its semantic ButtonType.
static func apply_button_style(
	btn: Button,
	type: ButtonType = ButtonType.SECONDARY,
	custom_accent: Variant = null
) -> void:
	if not btn:
		return

	var accent: Color = custom_accent if (custom_accent is Color) else COLOR_CYAN_PRIMARY

	var sb_normal: StyleBoxFlat = StyleBoxFlat.new()
	var sb_hover: StyleBoxFlat = StyleBoxFlat.new()
	var sb_pressed: StyleBoxFlat = StyleBoxFlat.new()
	var sb_disabled: StyleBoxFlat = StyleBoxFlat.new()
	var sb_focus: StyleBoxFlat = StyleBoxFlat.new()

	var radius: int = CORNER_RADIUS_BUTTON
	sb_normal.set_corner_radius_all(radius)
	sb_hover.set_corner_radius_all(radius)
	sb_pressed.set_corner_radius_all(radius)
	sb_disabled.set_corner_radius_all(radius)
	sb_focus.set_corner_radius_all(radius)

	# Content margins to ensure touch comfort
	for sb in [sb_normal, sb_hover, sb_pressed, sb_disabled, sb_focus]:
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8

	# Focus Ring (Accessible, subtle cyan border)
	sb_focus.bg_color = Color(0, 0, 0, 0)
	sb_focus.border_color = COLOR_CYAN_PRIMARY
	sb_focus.set_border_width_all(2)

	var font: Font = get_interface_font("SemiBold")
	var font_color: Color = COLOR_TEXT_PRIMARY
	var font_hover: Color = COLOR_TEXT_PRIMARY
	var font_pressed: Color = COLOR_TEXT_PRIMARY
	var font_disabled: Color = COLOR_TEXT_DIM

	match type:
		ButtonType.PRIMARY:
			# Solid Cyan Fill, Deep Navy Text, Outer Cyan Glow
			font = get_display_font("SemiBold")
			font_color = COLOR_CYAN_DARK
			font_hover = COLOR_CYAN_DARK
			font_pressed = COLOR_CYAN_DARK
			font_disabled = COLOR_TEXT_DIM

			sb_normal.bg_color = COLOR_CYAN_PRIMARY
			sb_normal.border_color = COLOR_CYAN_HOVER
			sb_normal.set_border_width_all(1)
			sb_normal.shadow_color = COLOR_CYAN_GLOW
			sb_normal.shadow_size = 10
			sb_normal.shadow_offset = Vector2(0, 2)

			sb_hover.bg_color = COLOR_CYAN_HOVER
			sb_hover.border_color = Color.WHITE
			sb_hover.set_border_width_all(1)
			sb_hover.shadow_color = Color(COLOR_CYAN_PRIMARY.r, COLOR_CYAN_PRIMARY.g, COLOR_CYAN_PRIMARY.b, 0.50)
			sb_hover.shadow_size = 14
			sb_hover.shadow_offset = Vector2(0, 2)

			sb_pressed.bg_color = COLOR_CYAN_PRESSED
			sb_pressed.border_color = COLOR_CYAN_PRIMARY
			sb_pressed.set_border_width_all(1)
			sb_pressed.shadow_size = 4

			sb_disabled.bg_color = Color(0.08, 0.12, 0.18, 0.6)
			sb_disabled.border_color = COLOR_BORDER_SUBTLE
			sb_disabled.set_border_width_all(1)

		ButtonType.SECONDARY:
			# Dark Navy Fill, Cyan/Accent Outline, Bright Text
			font = get_interface_font("Medium")
			font_color = COLOR_TEXT_PRIMARY
			font_hover = COLOR_TEXT_PRIMARY
			font_pressed = accent
			font_disabled = COLOR_TEXT_DIM

			sb_normal.bg_color = COLOR_BG_SURFACE
			sb_normal.border_color = Color(accent.r, accent.g, accent.b, 0.55)
			sb_normal.set_border_width_all(1)

			sb_hover.bg_color = COLOR_BG_HOVER
			sb_hover.border_color = accent
			sb_hover.set_border_width_all(2)
			sb_hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.25)
			sb_hover.shadow_size = 8

			sb_pressed.bg_color = Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.95)
			sb_pressed.border_color = accent
			sb_pressed.set_border_width_all(1)

			sb_disabled.bg_color = Color(0.05, 0.07, 0.11, 0.60)
			sb_disabled.border_color = COLOR_BORDER_SUBTLE
			sb_disabled.set_border_width_all(1)

		ButtonType.TERTIARY:
			# Minimal/Transparent Surface, Subtle Highlight
			font = get_interface_font("Regular")
			font_color = COLOR_TEXT_SECONDARY
			font_hover = COLOR_TEXT_PRIMARY
			font_pressed = accent
			font_disabled = COLOR_TEXT_DIM

			sb_normal.bg_color = Color(0.08, 0.12, 0.20, 0.25)
			sb_normal.border_color = Color(0, 0, 0, 0)
			sb_normal.set_border_width_all(0)

			sb_hover.bg_color = Color(1.0, 1.0, 1.0, 0.08)
			sb_hover.border_color = COLOR_BORDER_SUBTLE
			sb_hover.set_border_width_all(1)

			sb_pressed.bg_color = Color(1.0, 1.0, 1.0, 0.14)
			sb_pressed.border_color = accent
			sb_pressed.set_border_width_all(1)

			sb_disabled.bg_color = Color(0, 0, 0, 0)
			sb_disabled.border_color = Color(0, 0, 0, 0)
			sb_disabled.set_border_width_all(0)

		ButtonType.UTILITY:
			# Dark Elevated Surface with Accent Border & Icon Support
			font = get_interface_font("SemiBold")
			font_color = COLOR_TEXT_PRIMARY
			font_hover = COLOR_TEXT_PRIMARY
			font_pressed = accent
			font_disabled = COLOR_TEXT_DIM

			sb_normal.bg_color = COLOR_BG_ELEVATED
			sb_normal.border_color = Color(accent.r, accent.g, accent.b, 0.50)
			sb_normal.set_border_width_all(1)

			sb_hover.bg_color = COLOR_BG_HOVER
			sb_hover.border_color = accent
			sb_hover.set_border_width_all(2)
			sb_hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.25)
			sb_hover.shadow_size = 6

			sb_pressed.bg_color = Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 0.95)
			sb_pressed.border_color = accent
			sb_pressed.set_border_width_all(2)

			sb_disabled.bg_color = Color(0.04, 0.06, 0.10, 0.50)
			sb_disabled.border_color = COLOR_BORDER_SUBTLE
			sb_disabled.set_border_width_all(1)

		ButtonType.DESTRUCTIVE:
			# Red/Coral Warning Border and Accents
			var red_col: Color = COLOR_ROSE_ALERT
			font = get_interface_font("SemiBold")
			font_color = Color("#FFA4B3")
			font_hover = COLOR_TEXT_PRIMARY
			font_pressed = red_col
			font_disabled = COLOR_TEXT_DIM

			sb_normal.bg_color = Color(0.14, 0.05, 0.08, 0.90)
			sb_normal.border_color = Color(red_col.r, red_col.g, red_col.b, 0.55)
			sb_normal.set_border_width_all(1)

			sb_hover.bg_color = Color(0.22, 0.07, 0.12, 0.95)
			sb_hover.border_color = red_col
			sb_hover.set_border_width_all(2)
			sb_hover.shadow_color = COLOR_ROSE_GLOW
			sb_hover.shadow_size = 8

			sb_pressed.bg_color = Color(0.10, 0.03, 0.05, 0.95)
			sb_pressed.border_color = red_col
			sb_pressed.set_border_width_all(1)

			sb_disabled.bg_color = Color(0.08, 0.04, 0.06, 0.50)
			sb_disabled.border_color = COLOR_BORDER_SUBTLE
			sb_disabled.set_border_width_all(1)

		ButtonType.ICON:
			# Square / Circular Compact Icon Button (>= 48dp)
			font = get_interface_font("Medium")
			font_color = COLOR_TEXT_PRIMARY
			font_hover = COLOR_TEXT_PRIMARY
			font_pressed = accent
			font_disabled = COLOR_TEXT_DIM

			sb_normal.bg_color = COLOR_BG_SURFACE
			sb_normal.border_color = COLOR_BORDER_SUBTLE
			sb_normal.set_border_width_all(1)

			sb_hover.bg_color = COLOR_BG_HOVER
			sb_hover.border_color = accent
			sb_hover.set_border_width_all(2)

			sb_pressed.bg_color = Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.95)
			sb_pressed.border_color = accent
			sb_pressed.set_border_width_all(1)

			sb_disabled.bg_color = Color(0.04, 0.06, 0.10, 0.50)
			sb_disabled.border_color = COLOR_BORDER_SUBTLE
			sb_disabled.set_border_width_all(1)

	# Apply overrides
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_focus)
	btn.add_theme_stylebox_override("disabled", sb_disabled)

	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", FONT_SIZE_BUTTON)

	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_hover)
	btn.add_theme_color_override("font_pressed_color", font_pressed)
	btn.add_theme_color_override("font_focus_color", font_hover)
	btn.add_theme_color_override("font_disabled_color", font_disabled)

## Backwards-compatibility wrapper for existing screens
static func apply_button_skin(btn: Button, accent_color: Color = COLOR_CYAN_PRIMARY, is_primary: bool = false) -> void:
	if is_primary:
		apply_button_style(btn, ButtonType.PRIMARY, accent_color)
	else:
		apply_button_style(btn, ButtonType.SECONDARY, accent_color)

# ==============================================================================
# 6. TYPOGRAPHIC LABEL HELPERS
# ==============================================================================

## Apply futuristic Display font (Oxanium) for titles, headings, and chapter marks
static func apply_display_heading(
	lbl: Label,
	size: int = FONT_SIZE_SCREEN_HEADING,
	color: Color = COLOR_CYAN_PRIMARY,
	weight: String = "Bold"
) -> void:
	if not lbl: return
	lbl.add_theme_font_override("font", get_display_font(weight))
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)

## Apply clean Interface font (Inter) for instructions, dialogue, and menu items
static func apply_body_text(
	lbl: Label,
	size: int = FONT_SIZE_BODY,
	color: Color = COLOR_TEXT_PRIMARY,
	weight: String = "Regular"
) -> void:
	if not lbl: return
	lbl.add_theme_font_override("font", get_interface_font(weight))
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)

## Apply precision Technical font (IBM Plex Mono) for logs, timestamps, coordinates, and metadata
static func apply_technical_text(
	lbl: Label,
	size: int = FONT_SIZE_METADATA,
	color: Color = COLOR_TEXT_MUTED,
	weight: String = "Regular"
) -> void:
	if not lbl: return
	lbl.add_theme_font_override("font", get_technical_font(weight))
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)

# ==============================================================================
# 7. MASTER THEME GENERATION
# ==============================================================================

## Construct a comprehensive Godot Theme resource embedding all default font and widget styles
static func create_master_theme() -> Theme:
	var t: Theme = Theme.new()

	var default_font: Font = get_interface_font("Regular")
	var default_bold: Font = get_interface_font("Bold")
	t.default_font = default_font
	t.default_font_size = FONT_SIZE_BODY

	# Button defaults
	var btn_normal: StyleBoxFlat = StyleBoxFlat.new()
	btn_normal.bg_color = COLOR_BG_SURFACE
	btn_normal.border_color = Color(COLOR_CYAN_PRIMARY.r, COLOR_CYAN_PRIMARY.g, COLOR_CYAN_PRIMARY.b, 0.5)
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(CORNER_RADIUS_BUTTON)
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8

	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = COLOR_BG_HOVER
	btn_hover.border_color = COLOR_CYAN_PRIMARY
	btn_hover.set_border_width_all(2)

	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = COLOR_BG_ELEVATED
	btn_pressed.border_color = COLOR_CYAN_PRIMARY

	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color(0.04, 0.06, 0.10, 0.5)
	btn_disabled.border_color = COLOR_BORDER_SUBTLE

	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("focus", "Button", btn_hover)
	t.set_stylebox("disabled", "Button", btn_disabled)

	t.set_color("font_color", "Button", COLOR_TEXT_PRIMARY)
	t.set_color("font_hover_color", "Button", COLOR_TEXT_PRIMARY)
	t.set_color("font_pressed_color", "Button", COLOR_CYAN_PRIMARY)
	t.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)
	t.set_font("font", "Button", get_interface_font("Medium"))
	t.set_font_size("font_size", "Button", FONT_SIZE_BUTTON)

	# Label defaults
	t.set_color("font_color", "Label", COLOR_TEXT_PRIMARY)
	t.set_font("font", "Label", default_font)
	t.set_font_size("font_size", "Label", FONT_SIZE_BODY)

	# Panel & PanelContainer defaults
	var panel_sb: StyleBoxFlat = StyleBoxFlat.new()
	panel_sb.bg_color = COLOR_BG_SURFACE
	panel_sb.border_color = COLOR_BORDER_SUBTLE
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(CORNER_RADIUS_PANEL)
	t.set_stylebox("panel", "Panel", panel_sb)
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	# ProgressBar defaults
	var pbar_bg: StyleBoxFlat = StyleBoxFlat.new()
	pbar_bg.bg_color = Color(0.04, 0.06, 0.10, 0.8)
	pbar_bg.set_corner_radius_all(3)
	var pbar_fill: StyleBoxFlat = StyleBoxFlat.new()
	pbar_fill.bg_color = COLOR_CYAN_PRIMARY
	pbar_fill.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", pbar_bg)
	t.set_stylebox("fill", "ProgressBar", pbar_fill)

	# HSlider defaults
	var slider_bg: StyleBoxFlat = StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.08, 0.12, 0.20, 0.9)
	slider_bg.border_color = COLOR_BORDER_SUBTLE
	slider_bg.set_border_width_all(1)
	slider_bg.set_corner_radius_all(4)
	slider_bg.content_margin_top = 4
	slider_bg.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", slider_bg)

	return t
