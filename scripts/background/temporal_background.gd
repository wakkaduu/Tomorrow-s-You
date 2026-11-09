class_name TemporalBackground
extends Control

## Reusable, high-performance background system for the TEMPORAL RESEARCH FACILITY.
## Features layered environmental depth:
## - Layer 1: Procedural gradient & radial depth with anti-banding dither
## - Layer 2: Distant research facility architectural silhouettes & catwalks
## - Layer 3: Atmospheric volumetric light beams & glowing temporal aperture
## - Layer 4: Ambient floating particles & energetic motes
## - Layer 5: Rotating concentric time rings, coordinate grid & Echo silhouettes

const ThemeManagerClass = preload("res://scripts/background/background_theme_manager.gd")
const SilhouettesClass = preload("res://scripts/background/background_facility_silhouettes.gd")
const ParticlesClass = preload("res://scripts/background/background_particles.gd")
const EnvironmentShader = preload("res://scripts/background/temporal_environment.gdshader")

@export var initial_mode: int = 0 # Corresponds to ThemeManagerClass.ScreenMode.MAIN_MENU
@export var initial_tier: int = 1

var current_mode: int = 0
var current_tier: int = 1
var is_paused_mode: bool = false
var is_complete_mode: bool = false

var _shader_rect: ColorRect = null
var _shader_mat: ShaderMaterial = null
var _silhouettes: Control = null
var _particles: Control = null
var _overlay_rect: ColorRect = null

var _time_accum: float = 0.0
var _pulse_speed: float = 0.8
var _current_theme: Dictionary = {}

func _ready() -> void:
	# Guarantee input pass-through
	mouse_filter = MOUSE_FILTER_IGNORE

	_setup_layers()
	set_screen_mode(initial_mode, initial_tier)

	# Listen to SaveManager for reduced motion updates
	if SaveManager and SaveManager.has_signal("save_loaded"):
		SaveManager.save_loaded.connect(_on_settings_updated)

	_on_settings_updated()

func _setup_layers() -> void:
	# Layer 1 & 3: Environment Shader
	_shader_rect = ColorRect.new()
	_shader_rect.name = "ShaderEnvironment"
	_shader_rect.mouse_filter = MOUSE_FILTER_IGNORE
	_shader_rect.set_anchors_preset(PRESET_FULL_RECT)
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = EnvironmentShader
	_shader_rect.material = _shader_mat
	add_child(_shader_rect)

	# Layer 2 & 5: Architectural Silhouettes, Rings, Grid
	_silhouettes = SilhouettesClass.new()
	_silhouettes.name = "SilhouettesAndRings"
	_silhouettes.mouse_filter = MOUSE_FILTER_IGNORE
	_silhouettes.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_silhouettes)

	# Layer 4: Atmospheric Floating Particles
	_particles = ParticlesClass.new()
	_particles.name = "AmbientParticles"
	_particles.mouse_filter = MOUSE_FILTER_IGNORE
	_particles.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_particles)

	# Overlay for Pause darkening & Level-Complete flashes
	_overlay_rect = ColorRect.new()
	_overlay_rect.name = "AtmosphericOverlay"
	_overlay_rect.mouse_filter = MOUSE_FILTER_IGNORE
	_overlay_rect.set_anchors_preset(PRESET_FULL_RECT)
	_overlay_rect.color = Color(0, 0, 0, 0)
	add_child(_overlay_rect)

func set_screen_mode(mode: int, tier: int = 1) -> void:
	current_mode = mode
	current_tier = tier
	var theme: Dictionary = ThemeManagerClass.get_theme_for_mode(mode, tier)
	_apply_theme(theme)

func set_difficulty_tier(tier: int) -> void:
	current_tier = tier
	if current_mode == ThemeManagerClass.ScreenMode.DIFFICULTY_SELECT:
		var theme: Dictionary = ThemeManagerClass.get_difficulty_tier_theme(tier)
		_apply_theme(theme)
	elif current_mode == ThemeManagerClass.ScreenMode.LEVEL_SELECT:
		var theme: Dictionary = ThemeManagerClass.get_theme_for_mode(ThemeManagerClass.ScreenMode.LEVEL_SELECT, tier)
		_apply_theme(theme)

func set_paused(paused_state: bool) -> void:
	is_paused_mode = paused_state
	if is_paused_mode:
		var theme = ThemeManagerClass.get_theme_for_mode(ThemeManagerClass.ScreenMode.PAUSED)
		_apply_theme(theme)
		if _overlay_rect:
			_overlay_rect.color = Color(0.01, 0.02, 0.04, 0.45)
	else:
		# Return to gameplay or prior screen
		var theme = ThemeManagerClass.get_theme_for_mode(current_mode, current_tier)
		_apply_theme(theme)
		if _overlay_rect:
			_overlay_rect.color = Color(0, 0, 0, 0)

	if _silhouettes and _silhouettes.has_method("set_paused_state"):
		_silhouettes.set_paused_state(is_paused_mode)
	if _particles and _particles.has_method("set_paused_state"):
		_particles.set_paused_state(is_paused_mode)

func set_level_complete(complete_state: bool) -> void:
	is_complete_mode = complete_state
	if is_complete_mode:
		var theme = ThemeManagerClass.get_theme_for_mode(ThemeManagerClass.ScreenMode.LEVEL_COMPLETE)
		_apply_theme(theme)
		# Triumphant luminous cyan shimmer
		if _overlay_rect:
			_overlay_rect.color = Color(0.33, 0.90, 0.92, 0.15)
	else:
		var theme = ThemeManagerClass.get_theme_for_mode(current_mode, current_tier)
		_apply_theme(theme)
		if _overlay_rect:
			_overlay_rect.color = Color(0, 0, 0, 0)

func _apply_theme(theme: Dictionary) -> void:
	_current_theme = theme
	_pulse_speed = theme.get("pulse_speed", 0.8)

	var bg_dark: Color = theme.get("bg_dark", Color(0.043, 0.063, 0.125))
	var bg_mid: Color = theme.get("bg_mid", Color(0.078, 0.110, 0.180))
	var prim: Color = theme.get("primary_glow", Color(0.329, 0.902, 0.918))
	var sec: Color = theme.get("secondary_glow", Color(0.655, 0.545, 0.980))
	var beam_op: float = theme.get("beam_opacity", 0.15)
	var vig: float = theme.get("vignette_strength", 0.55)
	var fog: float = theme.get("fog_density", 0.10)

	if _shader_mat:
		_shader_mat.set_shader_parameter("bg_dark", bg_dark)
		_shader_mat.set_shader_parameter("bg_mid", bg_mid)
		_shader_mat.set_shader_parameter("primary_glow", prim)
		_shader_mat.set_shader_parameter("secondary_glow", sec)
		_shader_mat.set_shader_parameter("beam_intensity", beam_op)
		_shader_mat.set_shader_parameter("vignette_strength", vig)
		_shader_mat.set_shader_parameter("fog_density", fog)
		
		# Center lighting higher for menu/difficulty, slightly lower for gameplay
		if current_mode == ThemeManagerClass.ScreenMode.GAMEPLAY or current_mode == ThemeManagerClass.ScreenMode.PAUSED:
			_shader_mat.set_shader_parameter("glow_center", Vector2(0.5, 0.42))
		else:
			_shader_mat.set_shader_parameter("glow_center", Vector2(0.5, 0.36))

	var is_reduced: bool = is_reduced_animations_active()

	if _silhouettes and _silhouettes.has_method("set_parameters"):
		_silhouettes.set_parameters(
			prim,
			sec,
			theme.get("silhouette_alpha", 0.35),
			theme.get("grid_opacity", 0.08),
			theme.get("ring_count", 3),
			theme.get("ring_radius_scale", 0.28),
			theme.get("ring_speed", 0.25),
			theme.get("echo_silhouette_count", 2),
			is_reduced
		)

	if _particles and _particles.has_method("set_palette"):
		_particles.set_palette(prim, sec)
		_particles.set_motion_settings(
			theme.get("particle_count", 30),
			theme.get("particle_speed", 16.0),
			is_reduced
		)

func is_reduced_animations_active() -> bool:
	if SaveManager and "reduced_animations" in SaveManager:
		return bool(SaveManager.reduced_animations)
	return false

func _on_settings_updated() -> void:
	if not _current_theme.is_empty():
		_apply_theme(_current_theme)

func _process(delta: float) -> void:
	var dt: float = delta
	var is_reduced: bool = is_reduced_animations_active()
	if is_paused_mode or is_reduced:
		dt *= 0.2

	_time_accum += dt

	if _shader_mat:
		_shader_mat.set_shader_parameter("time_offset", _time_accum)
		# Subtle gentle breathing pulse on the core
		var pulse_val: float = 1.0 + (sin(_time_accum * _pulse_speed) * 0.15 if not is_reduced else 0.0)
		_shader_mat.set_shader_parameter("pulse", pulse_val)
