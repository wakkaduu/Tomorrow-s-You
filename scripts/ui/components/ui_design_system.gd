class_name UIDesignSystem
extends RefCounted

## Master UI Design System for Tomorrow's You.
## Provides standardized styling, colors, and reusable StyleBox constructors
## across all screens, modals, cards, and buttons for a cohesive cinematic sci-fi interface.

# ==============================================================================
# CANONICAL COLOR PALETTE
# ==============================================================================

const COLOR_BG_VOID: Color = Color(0.025, 0.040, 0.080, 1.0)       # #060A14 - Deep Void
const COLOR_BG_SURFACE: Color = Color(0.045, 0.070, 0.130, 0.96)    # #0B1221 - Panel Surface
const COLOR_BG_ELEVATED: Color = Color(0.075, 0.115, 0.200, 0.95)   # #131D33 - Elevated Cards
const COLOR_BG_HOVER: Color = Color(0.110, 0.170, 0.280, 0.95)      # #1C2B47 - Interactive Hover

const COLOR_CYAN_PRIMARY: Color = Color(0.329, 0.902, 0.918, 1.0)    # #54E6EA - Player / Meridian Cyan
const COLOR_CYAN_GLOW: Color = Color(0.329, 0.902, 0.918, 0.30)
const COLOR_CYAN_DIM: Color = Color(0.329, 0.902, 0.918, 0.12)

const COLOR_VIOLET_ECHO: Color = Color(0.655, 0.545, 0.980, 1.0)    # #A78BFA - Echo Violet
const COLOR_VIOLET_GLOW: Color = Color(0.655, 0.545, 0.980, 0.30)

const COLOR_AMBER_WARN: Color = Color(0.984, 0.749, 0.141, 1.0)     # #FBBF24 - Amber Alert
const COLOR_AMBER_GLOW: Color = Color(0.984, 0.749, 0.141, 0.30)

const COLOR_EMERALD_SUCCESS: Color = Color(0.204, 0.827, 0.600, 1.0) # #34D399 - Success / Synchronized
const COLOR_ROSE_ALERT: Color = Color(0.957, 0.247, 0.369, 1.0)      # #F43F5E - Danger / Nightmare

const COLOR_TEXT_PRIMARY: Color = Color(0.945, 0.961, 0.976, 1.0)    # #F1F5F9 - High-Contrast Text
const COLOR_TEXT_MUTED: Color = Color(0.580, 0.639, 0.722, 1.0)      # #94A3B8 - Secondary Text
const COLOR_TEXT_DIM: Color = Color(0.392, 0.455, 0.545, 1.0)        # #64748B - Disabled / Ambient
const COLOR_BORDER_SUBTLE: Color = Color(0.250, 0.380, 0.520, 0.30)  # Subtle Architectural Edge

# ==============================================================================
# STYLEBOX FACTORIES
# ==============================================================================

## Standard Terminal / Modal Panel Style
static func create_panel_style(
	border_color: Color = COLOR_CYAN_PRIMARY,
	bg_color: Color = COLOR_BG_SURFACE,
	border_width: int = 2,
	corner_radius: int = 12,
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

## Interactive Button Styles
static func create_button_style(
	accent_color: Color = COLOR_CYAN_PRIMARY,
	is_primary: bool = false,
	is_pressed: bool = false,
	is_disabled: bool = false
) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(10)

	if is_disabled:
		sb.bg_color = Color(0.04, 0.06, 0.10, 0.6)
		sb.border_color = Color(0.25, 0.32, 0.42, 0.25)
		sb.set_border_width_all(1)
		return sb

	if is_primary:
		if is_pressed:
			sb.bg_color = Color(accent_color.r * 0.4, accent_color.g * 0.4, accent_color.b * 0.4, 0.95)
			sb.border_color = accent_color
			sb.set_border_width_all(2)
		else:
			sb.bg_color = Color(accent_color.r * 0.16, accent_color.g * 0.16, accent_color.b * 0.16, 0.90)
			sb.border_color = accent_color
			sb.set_border_width_all(2)
			sb.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.35)
			sb.shadow_size = 8
			sb.shadow_offset = Vector2(0, 2)
	else:
		# Secondary / Architectural
		if is_pressed:
			sb.bg_color = Color(0.12, 0.18, 0.28, 0.95)
			sb.border_color = accent_color
			sb.set_border_width_all(1)
		else:
			sb.bg_color = COLOR_BG_ELEVATED
			sb.border_color = COLOR_BORDER_SUBTLE
			sb.set_border_width_all(1)

	return sb

## Archive / Difficulty Card Style
static func create_card_style(
	accent_color: Color = COLOR_CYAN_PRIMARY,
	is_unlocked: bool = true,
	is_highlighted: bool = false
) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(10)

	if not is_unlocked:
		sb.bg_color = Color(0.035, 0.050, 0.090, 0.70)
		sb.border_color = Color(0.20, 0.26, 0.35, 0.30)
		sb.set_border_width_all(1)
		return sb

	if is_highlighted:
		sb.bg_color = Color(accent_color.r * 0.12, accent_color.g * 0.12, accent_color.b * 0.12, 0.95)
		sb.border_color = accent_color
		sb.set_border_width_all(2)
		sb.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.25)
		sb.shadow_size = 12
		sb.shadow_offset = Vector2(0, 3)
	else:
		sb.bg_color = COLOR_BG_ELEVATED
		sb.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.35)
		sb.set_border_width_all(1)

	return sb

## Classification / Status Badge Style
static func create_badge_style(accent_color: Color = COLOR_CYAN_PRIMARY) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(accent_color.r * 0.15, accent_color.g * 0.15, accent_color.b * 0.15, 0.85)
	sb.border_color = accent_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	return sb

## Navigation Tab Style
static func create_tab_style(is_active: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	if is_active:
		sb.bg_color = Color(0.329 * 0.15, 0.902 * 0.15, 0.918 * 0.15, 0.95)
		sb.border_color = COLOR_CYAN_PRIMARY
		sb.set_border_width_all(2)
		sb.shadow_color = Color(0.329, 0.902, 0.918, 0.25)
		sb.shadow_size = 8
	else:
		sb.bg_color = Color(0.04, 0.065, 0.11, 0.85)
		sb.border_color = COLOR_BORDER_SUBTLE
		sb.set_border_width_all(1)
	return sb

## Apply comprehensive styling to any Button node
static func apply_button_skin(btn: Button, accent_color: Color = COLOR_CYAN_PRIMARY, is_primary: bool = false) -> void:
	if not btn:
		return
	var normal = create_button_style(accent_color, is_primary, false, false)
	var hover = create_button_style(accent_color, true, false, false)
	var pressed = create_button_style(accent_color, is_primary, true, false)
	var disabled = create_button_style(accent_color, false, false, true)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY if is_primary else Color("#CBD5E1"))
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)
	btn.add_theme_color_override("font_pressed_color", accent_color)
	btn.add_theme_color_override("font_disabled_color", COLOR_TEXT_DIM)
