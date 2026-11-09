class_name BackgroundThemeManager
extends RefCounted

## Manages screen and difficulty themes for the Temporal Research Facility background system.
## Provides cohesive color palettes, animation timings, and architectural density settings.

enum ScreenMode {
	MAIN_MENU,
	DIFFICULTY_SELECT,
	LEVEL_SELECT,
	SETTINGS,
	CREDITS,
	GAMEPLAY,
	PAUSED,
	LEVEL_COMPLETE
}

# Canonical Palette Colors
const COLOR_BG_PRIMARY: Color = Color(0.043, 0.063, 0.125, 1.0)       # #0B1020
const COLOR_BG_SECONDARY: Color = Color(0.078, 0.110, 0.180, 1.0)     # #141C2E
const COLOR_PLAYER_CYAN: Color = Color(0.329, 0.902, 0.918, 1.0)      # #54E6EA
const COLOR_ECHO_VIOLET: Color = Color(0.655, 0.545, 0.980, 1.0)      # #A78BFA
const COLOR_ENERGY_AMBER: Color = Color(1.0, 0.745, 0.333, 1.0)       # #FFBE55
const COLOR_NIGHTMARE_CRIMSON: Color = Color(0.937, 0.267, 0.380, 1.0) # #EF4460

static func get_theme_for_mode(mode: ScreenMode, difficulty_tier: int = 1) -> Dictionary:
	match mode:
		ScreenMode.MAIN_MENU:
			return {
				"mode": ScreenMode.MAIN_MENU,
				"bg_dark": COLOR_BG_PRIMARY,
				"bg_mid": COLOR_BG_SECONDARY,
				"primary_glow": COLOR_PLAYER_CYAN,
				"secondary_glow": COLOR_ECHO_VIOLET,
				"ring_count": 3,
				"ring_radius_scale": 0.28,
				"ring_speed": 0.25,
				"particle_count": 35,
				"particle_speed": 18.0,
				"pulse_speed": 0.8,
				"beam_opacity": 0.18,
				"grid_opacity": 0.08,
				"vignette_strength": 0.55,
				"silhouette_alpha": 0.35,
				"echo_silhouette_count": 2,
				"fog_density": 0.12,
			}

		ScreenMode.DIFFICULTY_SELECT:
			return get_difficulty_tier_theme(difficulty_tier)

		ScreenMode.LEVEL_SELECT:
			# Sector lighting based on current difficulty tier
			var primary: Color = COLOR_PLAYER_CYAN
			var secondary: Color = COLOR_ECHO_VIOLET
			if difficulty_tier >= 4:
				primary = COLOR_ECHO_VIOLET
				secondary = COLOR_NIGHTMARE_CRIMSON
			elif difficulty_tier >= 2:
				primary = COLOR_ECHO_VIOLET
				secondary = COLOR_ENERGY_AMBER

			return {
				"mode": ScreenMode.LEVEL_SELECT,
				"bg_dark": COLOR_BG_PRIMARY,
				"bg_mid": COLOR_BG_SECONDARY,
				"primary_glow": primary,
				"secondary_glow": secondary,
				"ring_count": 2,
				"ring_radius_scale": 0.35,
				"ring_speed": 0.15,
				"particle_count": 25,
				"particle_speed": 14.0,
				"pulse_speed": 0.6,
				"beam_opacity": 0.12,
				"grid_opacity": 0.06,
				"vignette_strength": 0.65,
				"silhouette_alpha": 0.25,
				"echo_silhouette_count": 1,
				"fog_density": 0.10,
			}

		ScreenMode.SETTINGS:
			return {
				"mode": ScreenMode.SETTINGS,
				"bg_dark": COLOR_BG_PRIMARY,
				"bg_mid": Color(0.06, 0.085, 0.14, 1.0),
				"primary_glow": Color(0.329, 0.902, 0.918, 0.4), # Subdued
				"secondary_glow": Color(0.655, 0.545, 0.980, 0.3),
				"ring_count": 1,
				"ring_radius_scale": 0.25,
				"ring_speed": 0.08,
				"particle_count": 12, # Minimal
				"particle_speed": 8.0,
				"pulse_speed": 0.4,
				"beam_opacity": 0.06,
				"grid_opacity": 0.04,
				"vignette_strength": 0.70,
				"silhouette_alpha": 0.18,
				"echo_silhouette_count": 0,
				"fog_density": 0.08,
			}

		ScreenMode.CREDITS:
			return {
				"mode": ScreenMode.CREDITS,
				"bg_dark": Color(0.035, 0.05, 0.10, 1.0),
				"bg_mid": COLOR_BG_SECONDARY,
				"primary_glow": COLOR_ECHO_VIOLET,
				"secondary_glow": COLOR_PLAYER_CYAN,
				"ring_count": 4,
				"ring_radius_scale": 0.32,
				"ring_speed": 0.18,
				"particle_count": 40,
				"particle_speed": 22.0,
				"pulse_speed": 0.5,
				"beam_opacity": 0.22,
				"grid_opacity": 0.07,
				"vignette_strength": 0.60,
				"silhouette_alpha": 0.30,
				"echo_silhouette_count": 3,
				"fog_density": 0.15,
			}

		ScreenMode.GAMEPLAY:
			# High contrast, low clutter to preserve puzzle tile readability
			return {
				"mode": ScreenMode.GAMEPLAY,
				"bg_dark": COLOR_BG_PRIMARY,
				"bg_mid": Color(0.06, 0.08, 0.14, 1.0),
				"primary_glow": COLOR_PLAYER_CYAN,   # Cyan on player side
				"secondary_glow": COLOR_ECHO_VIOLET, # Violet on Echo/Exit side
				"ring_count": 2,
				"ring_radius_scale": 0.38,
				"ring_speed": 0.10,
				"particle_count": 20, # Edge particles
				"particle_speed": 12.0,
				"pulse_speed": 0.5,
				"beam_opacity": 0.08,
				"grid_opacity": 0.05,
				"vignette_strength": 0.75, # Darker center to pop tiles
				"silhouette_alpha": 0.18,
				"echo_silhouette_count": 0,
				"fog_density": 0.06,
			}

		ScreenMode.PAUSED:
			return {
				"mode": ScreenMode.PAUSED,
				"bg_dark": Color(0.025, 0.035, 0.07, 1.0), # Heavily darkened
				"bg_mid": Color(0.04, 0.055, 0.10, 1.0),
				"primary_glow": Color(0.329, 0.902, 0.918, 0.2),
				"secondary_glow": Color(0.655, 0.545, 0.980, 0.2),
				"ring_count": 2,
				"ring_radius_scale": 0.38,
				"ring_speed": 0.02, # Near freeze
				"particle_count": 20,
				"particle_speed": 2.0, # Slow motion
				"pulse_speed": 0.2,
				"beam_opacity": 0.04,
				"grid_opacity": 0.03,
				"vignette_strength": 0.88, # Deep vignette
				"silhouette_alpha": 0.12,
				"echo_silhouette_count": 0,
				"fog_density": 0.05,
			}

		ScreenMode.LEVEL_COMPLETE:
			# Triumphant luminous surge
			return {
				"mode": ScreenMode.LEVEL_COMPLETE,
				"bg_dark": COLOR_BG_PRIMARY,
				"bg_mid": Color(0.09, 0.13, 0.22, 1.0),
				"primary_glow": Color(0.40, 0.95, 0.98, 1.0),
				"secondary_glow": Color(0.80, 0.65, 1.0, 1.0),
				"ring_count": 4,
				"ring_radius_scale": 0.42,
				"ring_speed": 0.40,
				"particle_count": 45,
				"particle_speed": 28.0,
				"pulse_speed": 1.2,
				"beam_opacity": 0.28,
				"grid_opacity": 0.10,
				"vignette_strength": 0.45,
				"silhouette_alpha": 0.30,
				"echo_silhouette_count": 2,
				"fog_density": 0.18,
			}

	return {}

static func get_difficulty_tier_theme(tier: int) -> Dictionary:
	match tier:
		1: # EASY — INITIATION: Brighter cyan lighting, calm laboratory atmosphere, simple geometric elements
			return {
				"mode": ScreenMode.DIFFICULTY_SELECT,
				"tier": 1,
				"bg_dark": COLOR_BG_PRIMARY,
				"bg_mid": Color(0.08, 0.12, 0.20, 1.0),
				"primary_glow": COLOR_PLAYER_CYAN,
				"secondary_glow": Color(0.4, 0.75, 0.9, 1.0),
				"ring_count": 2,
				"ring_radius_scale": 0.26,
				"ring_speed": 0.20,
				"particle_count": 25,
				"particle_speed": 14.0,
				"pulse_speed": 0.7,
				"beam_opacity": 0.15,
				"grid_opacity": 0.07,
				"vignette_strength": 0.55,
				"silhouette_alpha": 0.30,
				"echo_silhouette_count": 1,
				"fog_density": 0.10,
			}

		2: # NORMAL — SYNCHRONIZATION: Cyan and violet energy patterns, two overlapping holographic structures
			return {
				"mode": ScreenMode.DIFFICULTY_SELECT,
				"tier": 2,
				"bg_dark": COLOR_BG_PRIMARY,
				"bg_mid": COLOR_BG_SECONDARY,
				"primary_glow": COLOR_PLAYER_CYAN,
				"secondary_glow": COLOR_ECHO_VIOLET,
				"ring_count": 3,
				"ring_radius_scale": 0.30,
				"ring_speed": 0.25,
				"particle_count": 30,
				"particle_speed": 18.0,
				"pulse_speed": 0.8,
				"beam_opacity": 0.18,
				"grid_opacity": 0.08,
				"vignette_strength": 0.60,
				"silhouette_alpha": 0.32,
				"echo_silhouette_count": 2,
				"fog_density": 0.12,
			}

		3: # HARD — CONVERGENCE: Darker atmosphere, complex geometric patterns, amber and violet contrast
			return {
				"mode": ScreenMode.DIFFICULTY_SELECT,
				"tier": 3,
				"bg_dark": Color(0.035, 0.05, 0.10, 1.0),
				"bg_mid": Color(0.07, 0.09, 0.16, 1.0),
				"primary_glow": COLOR_ENERGY_AMBER,
				"secondary_glow": COLOR_ECHO_VIOLET,
				"ring_count": 3,
				"ring_radius_scale": 0.33,
				"ring_speed": 0.30,
				"particle_count": 35,
				"particle_speed": 20.0,
				"pulse_speed": 0.9,
				"beam_opacity": 0.20,
				"grid_opacity": 0.09,
				"vignette_strength": 0.65,
				"silhouette_alpha": 0.35,
				"echo_silhouette_count": 2,
				"fog_density": 0.14,
			}

		4: # EXPERT — PARADOX: Deep violet illumination, multiple temporal rings, distorted holographic structures
			return {
				"mode": ScreenMode.DIFFICULTY_SELECT,
				"tier": 4,
				"bg_dark": Color(0.03, 0.04, 0.09, 1.0),
				"bg_mid": Color(0.08, 0.07, 0.17, 1.0),
				"primary_glow": COLOR_ECHO_VIOLET,
				"secondary_glow": Color(0.85, 0.45, 0.95, 1.0),
				"ring_count": 4,
				"ring_radius_scale": 0.36,
				"ring_speed": 0.35,
				"particle_count": 40,
				"particle_speed": 24.0,
				"pulse_speed": 1.0,
				"beam_opacity": 0.22,
				"grid_opacity": 0.10,
				"vignette_strength": 0.68,
				"silhouette_alpha": 0.38,
				"echo_silhouette_count": 3,
				"fog_density": 0.16,
			}

		5, _: # NIGHTMARE — THE LAST TOMORROW: Almost-black environment, dramatic purple and crimson accents, overlapping temporal structures
			return {
				"mode": ScreenMode.DIFFICULTY_SELECT,
				"tier": 5,
				"bg_dark": Color(0.02, 0.025, 0.05, 1.0),
				"bg_mid": Color(0.06, 0.03, 0.08, 1.0),
				"primary_glow": COLOR_NIGHTMARE_CRIMSON,
				"secondary_glow": Color(0.70, 0.25, 0.85, 1.0),
				"ring_count": 5,
				"ring_radius_scale": 0.40,
				"ring_speed": 0.42,
				"particle_count": 45,
				"particle_speed": 28.0,
				"pulse_speed": 1.2,
				"beam_opacity": 0.25,
				"grid_opacity": 0.12,
				"vignette_strength": 0.74,
				"silhouette_alpha": 0.42,
				"echo_silhouette_count": 3,
				"fog_density": 0.18,
			}
