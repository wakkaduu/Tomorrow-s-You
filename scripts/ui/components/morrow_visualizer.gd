class_name MorrowVisualizer
extends Control

## Original Holographic AI Visualizer for MORROW (Facility AI).
## Renders a mysterious, intelligent concentric core using pure Godot-native drawing.
## Supports 4 distinct transmission categories: NORMAL, EMERGENCY, CORRUPTED, FINAL.
## Optimized for mobile 60 FPS performance and honors the reduced-animations setting.

enum Category {
	NORMAL,
	EMERGENCY,
	CORRUPTED,
	FINAL
}

@export var current_category: Category = Category.NORMAL
@export var base_radius: float = 48.0
@export var show_waveform: bool = true

# Animation states
var _time: float = 0.0
var _rot_outer: float = 0.0
var _rot_mid: float = 0.0
var _rot_inner: float = 0.0
var _pulse_phase: float = 0.0
var _glitch_timer: float = 0.0
var _is_glitching: bool = false
var _glitch_offset: Vector2 = Vector2.ZERO

# Category Color Palettes
const COLOR_CYAN: Color = Color(0.329, 0.902, 0.918, 1.0)
const COLOR_VIOLET: Color = Color(0.655, 0.545, 0.980, 1.0)
const COLOR_AMBER: Color = Color(0.984, 0.749, 0.141, 1.0)
const COLOR_GOLD: Color = Color(1.0, 0.843, 0.360, 1.0)

func _ready() -> void:
	custom_minimum_size = Vector2(180, 140)

func set_category(cat: Category) -> void:
	current_category = cat
	queue_redraw()

func _process(delta: float) -> void:
	var is_reduced: bool = false
	if SaveManager and SaveManager.reduced_animations:
		is_reduced = true

	_time += delta
	var speed_mult: float = 0.4 if is_reduced else 1.0

	match current_category:
		Category.NORMAL:
			_rot_outer += delta * 0.45 * speed_mult
			_rot_mid -= delta * 0.30 * speed_mult
			_rot_inner += delta * 0.60 * speed_mult
			_pulse_phase += delta * 2.2 * speed_mult
			_is_glitching = false
		Category.EMERGENCY:
			_rot_outer += delta * 0.85 * speed_mult
			_rot_mid -= delta * 0.60 * speed_mult
			_rot_inner += delta * 1.10 * speed_mult
			_pulse_phase += delta * 4.5 * speed_mult
			_handle_glitch(delta, 0.25, is_reduced)
		Category.CORRUPTED:
			_rot_outer += delta * 0.30 * speed_mult
			_rot_mid -= delta * 0.90 * speed_mult
			_rot_inner += delta * 0.40 * speed_mult
			_pulse_phase += delta * 1.8 * speed_mult
			_handle_glitch(delta, 0.55, is_reduced)
		Category.FINAL:
			_rot_outer += delta * 0.50 * speed_mult
			_rot_mid -= delta * 0.40 * speed_mult
			_rot_inner += delta * 0.75 * speed_mult
			_pulse_phase += delta * 2.8 * speed_mult
			_is_glitching = false

	queue_redraw()

func _handle_glitch(delta: float, glitch_chance: float, is_reduced: bool) -> void:
	if is_reduced:
		_is_glitching = false
		_glitch_offset = Vector2.ZERO
		return
	_glitch_timer += delta
	if _glitch_timer > 0.15:
		_glitch_timer = 0.0
		if randf() < glitch_chance:
			_is_glitching = true
			_glitch_offset = Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0))
		else:
			_is_glitching = false
			_glitch_offset = Vector2.ZERO

func _draw() -> void:
	var center: Vector2 = size * 0.5 + _glitch_offset
	center.y -= 14.0 # Leave room below for the waveform

	var pri_color: Color
	var sec_color: Color
	var pulse_glow: float = sin(_pulse_phase) * 0.18 + 0.82

	match current_category:
		Category.NORMAL:
			pri_color = COLOR_CYAN
			sec_color = COLOR_VIOLET
		Category.EMERGENCY:
			pri_color = COLOR_AMBER
			sec_color = Color(1.0, 0.4, 0.2)
		Category.CORRUPTED:
			pri_color = COLOR_VIOLET
			sec_color = Color(0.9, 0.2, 0.6)
		Category.FINAL:
			pri_color = COLOR_CYAN.lerp(COLOR_GOLD, sin(_time * 1.5) * 0.5 + 0.5)
			sec_color = COLOR_VIOLET

	# Outer ambient halo
	draw_circle(center, base_radius * 1.15, Color(pri_color.r, pri_color.g, pri_color.b, 0.06 * pulse_glow))
	draw_circle(center, base_radius * 0.75, Color(sec_color.r, sec_color.g, sec_color.b, 0.08 * pulse_glow))

	# Ring 1: Outermost segmented tracking ring
	var r_outer: float = base_radius
	_draw_segmented_arc(center, r_outer, _rot_outer, 6, 0.75, pri_color * Color(1, 1, 1, 0.75 * pulse_glow), 1.8)

	# Ring 2: Concentric calibration ring with notch markers
	var r_mid: float = base_radius * 0.72
	_draw_notched_ring(center, r_mid, _rot_mid, 12, pri_color * Color(1, 1, 1, 0.60), sec_color * Color(1, 1, 1, 0.90))

	# Ring 3: Fast inner core ring
	var r_inner: float = base_radius * 0.44
	_draw_segmented_arc(center, r_inner, _rot_inner, 3, 0.60, sec_color * Color(1, 1, 1, 0.85 * pulse_glow), 2.2)

	# Central Holographic Core Glyph
	var core_rad: float = base_radius * 0.22 * pulse_glow
	draw_circle(center, core_rad, Color(pri_color.r, pri_color.g, pri_color.b, 0.85))
	draw_circle(center, core_rad * 0.45, Color(1.0, 1.0, 1.0, 0.95))

	# Ambient Orbiting Data Particles
	_draw_data_nodes(center, base_radius, pri_color)

	# Bottom Telemetric Waveform
	if show_waveform:
		_draw_waveform(Vector2(center.x, size.y - 18.0), size.x * 0.75, pri_color)

func _draw_segmented_arc(c: Vector2, r: float, start_angle: float, segments: int, arc_ratio: float, col: Color, width: float) -> void:
	var total_slice: float = TAU / float(segments)
	var active_slice: float = total_slice * arc_ratio
	for i in range(segments):
		var a1: float = start_angle + i * total_slice
		var a2: float = a1 + active_slice
		draw_arc(c, r, a1, a2, 16, col, width, true)

func _draw_notched_ring(c: Vector2, r: float, rot: float, notch_count: int, ring_col: Color, notch_col: Color) -> void:
	draw_arc(c, r, 0, TAU, 32, ring_col, 1.2, true)
	var step: float = TAU / float(notch_count)
	for i in range(notch_count):
		var angle: float = rot + i * step
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var p1: Vector2 = c + dir * (r - 2.5)
		var p2: Vector2 = c + dir * (r + 2.5)
		draw_line(p1, p2, notch_col, 1.4, true)

func _draw_data_nodes(c: Vector2, max_r: float, col: Color) -> void:
	var node_count: int = 5
	for i in range(node_count):
		var angle: float = _time * (0.3 + float(i) * 0.15) + float(i) * (TAU / float(node_count))
		var r: float = (max_r * 0.6) + sin(_time * 2.0 + float(i)) * (max_r * 0.35)
		var p: Vector2 = c + Vector2(cos(angle), sin(angle)) * r
		draw_circle(p, 1.8, col * Color(1, 1, 1, 0.8))

func _draw_waveform(base_pos: Vector2, total_width: float, col: Color) -> void:
	var half_w: float = total_width * 0.5
	var points_count: int = 24
	var step: float = total_width / float(points_count - 1)
	var start_x: float = base_pos.x - half_w

	var points: PackedVector2Array = PackedVector2Array()
	for i in range(points_count):
		var x: float = start_x + float(i) * step
		var norm_dist: float = 1.0 - absf((x - base_pos.x) / half_w) # 0 at edges, 1 at center
		var freq: float = 3.5 if current_category != Category.EMERGENCY else 6.0
		var jitter: float = (randf_range(-2.0, 2.0) if _is_glitching else 0.0)
		var wave_y: float = sin(_time * freq + float(i) * 0.6) * 6.0 * norm_dist + jitter
		points.append(Vector2(x, base_pos.y + wave_y))

	if points.size() > 1:
		for i in range(points.size() - 1):
			var alpha: float = 0.2 + (1.0 - absf(float(i - points.size() / 2) / float(points.size() / 2))) * 0.6
			draw_line(points[i], points[i + 1], col * Color(1, 1, 1, alpha), 1.5, true)
