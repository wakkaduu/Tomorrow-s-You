class_name BackgroundFacilitySilhouettes
extends Control

## Procedural rendering of the Temporal Research Facility architecture,
## concentric temporal rings, perspective grids, and faint Echo silhouettes.

var primary_color: Color = Color(0.329, 0.902, 0.918, 1.0)
var secondary_color: Color = Color(0.655, 0.545, 0.980, 1.0)
var silhouette_alpha: float = 0.35
var grid_opacity: float = 0.08
var ring_count: int = 3
var ring_radius_scale: float = 0.28
var ring_speed: float = 0.25
var echo_silhouette_count: int = 2
var reduced_motion: bool = false
var paused: bool = false

var _time_accum: float = 0.0
var _ring_angles: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func set_parameters(
	prim: Color,
	sec: Color,
	sil_alpha: float,
	grid_alpha: float,
	rings: int,
	radius_scale: float,
	speed: float,
	echo_count: int,
	reduced: bool
) -> void:
	primary_color = prim
	secondary_color = sec
	silhouette_alpha = sil_alpha
	grid_opacity = grid_alpha
	ring_count = clampi(rings, 1, 5)
	ring_radius_scale = radius_scale
	ring_speed = speed
	echo_silhouette_count = echo_count
	reduced_motion = reduced
	queue_redraw()

func set_paused_state(is_paused: bool) -> void:
	paused = is_paused

func _process(delta: float) -> void:
	var dt: float = delta
	if paused:
		dt *= 0.1
	if reduced_motion:
		dt *= 0.15

	_time_accum += dt
	for i in range(_ring_angles.size()):
		var dir: float = 1.0 if (i % 2 == 0) else -1.0
		var spd: float = ring_speed * (1.0 + float(i) * 0.35)
		_ring_angles[i] += dir * spd * dt

	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return

	var center: Vector2 = Vector2(w * 0.5, h * 0.38)
	var base_sil_color: Color = Color(0.06, 0.085, 0.14, silhouette_alpha)
	var line_highlight: Color = Color(primary_color.r, primary_color.g, primary_color.b, silhouette_alpha * 0.5)

	# --------------------------------------------------------------------------
	# 1. FACILITY PERSPECTIVE GRID (Floor plane in lower third)
	# --------------------------------------------------------------------------
	if grid_opacity > 0.005:
		var horizon_y: float = h * 0.62
		var grid_col: Color = Color(primary_color.r, primary_color.g, primary_color.b, grid_opacity)
		# Perspective lines originating from central horizon
		var num_lines: int = 12
		for i in range(num_lines + 1):
			var t: float = float(i) / float(num_lines)
			var ground_x: float = lerpf(-w * 0.2, w * 1.2, t)
			draw_line(Vector2(center.x, horizon_y), Vector2(ground_x, h), grid_col, 1.0)
		
		# Horizontal depth lines with perspective spacing
		for j in range(1, 7):
			var yt: float = pow(float(j) / 7.0, 2.2)
			var y_line: float = lerpf(horizon_y, h, yt)
			draw_line(Vector2(0.0, y_line), Vector2(w, y_line), grid_col, 1.0)

	# --------------------------------------------------------------------------
	# 2. ARCHITECTURAL SILHOUETTES (Laboratory walls, pillars, catwalks)
	# --------------------------------------------------------------------------
	var pillar_w: float = clampf(w * 0.08, 30.0, 60.0)
	# Left structural pillar
	draw_rect(Rect2(0, 0, pillar_w, h), base_sil_color)
	draw_line(Vector2(pillar_w, 0), Vector2(pillar_w, h), line_highlight, 1.5)
	# Horizontal brackets on left pillar
	for k in range(8):
		var by: float = h * (0.12 * float(k))
		draw_line(Vector2(0, by), Vector2(pillar_w, by), line_highlight, 1.0)

	# Right structural pillar
	draw_rect(Rect2(w - pillar_w, 0, pillar_w, h), base_sil_color)
	draw_line(Vector2(w - pillar_w, 0), Vector2(w - pillar_w, h), line_highlight, 1.5)
	# Horizontal brackets on right pillar
	for k in range(8):
		var by: float = h * (0.12 * float(k))
		draw_line(Vector2(w - pillar_w, by), Vector2(w, by), line_highlight, 1.0)

	# Upper suspended gantry / catwalk
	var catwalk_y: float = h * 0.20
	var catwalk_h: float = 14.0
	draw_rect(Rect2(0, catwalk_y, w, catwalk_h), base_sil_color)
	draw_line(Vector2(0, catwalk_y), Vector2(w, catwalk_y), line_highlight, 1.5)
	draw_line(Vector2(0, catwalk_y + catwalk_h), Vector2(w, catwalk_y + catwalk_h), line_highlight, 1.0)
	
	# Truss struts across the catwalk
	var strut_spacing: float = 40.0
	var struts: int = int(w / strut_spacing)
	for s in range(struts + 1):
		var sx: float = float(s) * strut_spacing
		draw_line(Vector2(sx, catwalk_y), Vector2(sx + 20.0, catwalk_y + catwalk_h), line_highlight * 0.6, 1.0)

	# --------------------------------------------------------------------------
	# 3. CENTRAL TEMPORAL APERTURE & CONCENTRIC TIME RINGS
	# --------------------------------------------------------------------------
	var base_radius: float = minf(w, h) * ring_radius_scale
	
	# Massive outer containment collar
	draw_circle(center, base_radius * 1.35, Color(base_sil_color.r, base_sil_color.g, base_sil_color.b, silhouette_alpha * 0.4))
	draw_arc(center, base_radius * 1.35, 0.0, TAU, 64, line_highlight, 1.5)
	draw_arc(center, base_radius * 1.25, 0.0, TAU, 48, line_highlight * 0.6, 1.0)

	# Inner concentric active temporal rings
	for r in range(ring_count):
		var t_ring: float = float(r + 1) / float(ring_count)
		var rad: float = base_radius * (0.35 + 0.65 * t_ring)
		var rot: float = _ring_angles[r % _ring_angles.size()]
		var is_odd: bool = (r % 2 == 1)
		var ring_color: Color = secondary_color if is_odd else primary_color
		var ring_alpha: float = clampf(0.25 + 0.25 * float(r), 0.2, 0.65)
		var active_ring_col: Color = Color(ring_color.r, ring_color.g, ring_color.b, ring_alpha)

		# Segmented rotating arcs (temporal ring pattern)
		var segments: int = 4 + r * 2
		var arc_len: float = (TAU / float(segments)) * 0.65
		for s in range(segments):
			var start_ang: float = rot + float(s) * (TAU / float(segments))
			draw_arc(center, rad, start_ang, start_ang + arc_len, 24, active_ring_col, 1.8 + float(r) * 0.4)

		# Cardinal tick marks
		for c in range(4):
			var tick_ang: float = rot + float(c) * (PI * 0.5)
			var p1: Vector2 = center + Vector2(cos(tick_ang), sin(tick_ang)) * (rad - 5.0)
			var p2: Vector2 = center + Vector2(cos(tick_ang), sin(tick_ang)) * (rad + 5.0)
			draw_line(p1, p2, active_ring_col * 1.3, 1.5)

	# Central core temporal vortex indicator
	var pulse: float = sin(_time_accum * 2.0) * 0.2 + 0.8
	draw_circle(center, base_radius * 0.16 * pulse, Color(primary_color.r, primary_color.g, primary_color.b, 0.18))
	draw_arc(center, base_radius * 0.22, 0.0, TAU, 32, primary_color * 0.6, 1.2)

	# --------------------------------------------------------------------------
	# 4. GHOSTLY ECHO SILHOUETTES IN DISTANT CHAMBERS
	# --------------------------------------------------------------------------
	if echo_silhouette_count > 0:
		var echo_col: Color = Color(secondary_color.r, secondary_color.g, secondary_color.b, 0.22)
		for e in range(echo_silhouette_count):
			var ex: float = lerpf(w * 0.22, w * 0.78, float(e) / float(maxi(1, echo_silhouette_count - 1)))
			var ey: float = catwalk_y - 2.0 # Standing on the catwalk
			# Draw miniature wireframe humanoid silhouette (head + body + limbs)
			var head_pos: Vector2 = Vector2(ex, ey - 22.0)
			draw_arc(head_pos, 4.0, 0.0, TAU, 12, echo_col, 1.2)
			# Torso
			draw_line(Vector2(ex, ey - 18.0), Vector2(ex, ey - 7.0), echo_col, 1.5)
			# Legs
			draw_line(Vector2(ex, ey - 7.0), Vector2(ex - 4.0, ey), echo_col, 1.2)
			draw_line(Vector2(ex, ey - 7.0), Vector2(ex + 4.0, ey), echo_col, 1.2)
			# Arms
			draw_line(Vector2(ex - 5.0, ey - 14.0), Vector2(ex + 5.0, ey - 14.0), echo_col, 1.2)

