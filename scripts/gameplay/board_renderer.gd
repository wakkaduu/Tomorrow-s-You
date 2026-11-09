class_name BoardRenderer
extends Node2D

## Procedural 2D sci-fi vector board renderer for Tomorrow's You.
## Dynamically scales and centers the grid within the mobile portrait viewport.
## Includes holographic Echo trails, animated doors/plates, and shockwave feedback.

signal tile_clicked(grid_pos: Vector2i)

const COLOR_BG: Color = Color("#0B1020")
const COLOR_FLOOR: Color = Color("#0E1726")
const COLOR_FLOOR_ALT: Color = Color("#111C2E")
const COLOR_FLOOR_LINE: Color = Color("#1E293B")
const COLOR_WALL: Color = Color("#131B2E")
const COLOR_WALL_HIGHLIGHT: Color = Color("#2A3B56")
const COLOR_WALL_SHADOW: Color = Color("#080D18")
const COLOR_WALL_BORDER: Color = Color("#334155")
const COLOR_PLAYER: Color = Color("#54E6EA")
const COLOR_ECHO: Color = Color("#A78BFA")
const COLOR_AMBER_ACTIVE: Color = Color("#FFBE55")
const COLOR_LOCKED_RED: Color = Color("#FF647C")
const COLOR_EXIT: Color = Color("#38BDF8")

var level_def: LevelDefinition = null
var simulation: PuzzleSimulation = null
var tile_size: float = 64.0
var board_offset: Vector2 = Vector2.ZERO

# Actor visual states for smooth interpolation
var player_visual_pos: Vector2 = Vector2.ZERO
var player_target_pos: Vector2 = Vector2.ZERO
var player_facing_dir: Vector2i = Vector2i.DOWN

var echo_visual_positions: Array[Vector2] = []
var echo_target_positions: Array[Vector2] = []
var echo_facing_dirs: Array[Vector2i] = []

# Historical trails for Echoes: Array of Array of Vector2
var echo_trail_points: Array[Array] = []

# Smooth animation weights (0.0 to 1.0)
var plate_anim_weights: Dictionary = {} # plate_id -> float
var door_anim_weights: Dictionary = {}  # door_id -> float

# Visual effects
var _pulse_timer: float = 0.0
var _shockwave_timer: float = 0.0
var _shockwave_origin: Vector2 = Vector2.ZERO
var _ambient_particles: Array[Dictionary] = []
const MAX_PARTICLES: int = 16

# Developer inspection mode
var show_debug_connections: bool = false

func setup(p_sim: PuzzleSimulation, viewport_size: Vector2) -> void:
	simulation = p_sim
	level_def = simulation.level_def

	simulation.player_moved.connect(_on_player_moved)
	simulation.echo_stepped.connect(_on_echo_stepped)
	simulation.echo_created.connect(_on_echo_created)
	simulation.echoes_cleared.connect(_on_echoes_cleared)
	simulation.attempt_restarted.connect(_on_attempt_restarted)
	simulation.plate_state_changed.connect(_on_plate_state_changed)
	simulation.door_state_changed.connect(_on_door_state_changed)

	_init_particles()
	calculate_layout(viewport_size)
	_reset_visual_positions()
	queue_redraw()

func _init_particles() -> void:
	_ambient_particles.clear()
	for i in range(MAX_PARTICLES):
		_ambient_particles.append({
			"pos": Vector2(randf(), randf()),
			"speed": randf_range(0.02, 0.06),
			"size": randf_range(1.5, 3.0),
			"alpha": randf_range(0.15, 0.4)
		})

func calculate_layout(viewport_size: Vector2) -> void:
	if level_def == null:
		return

	# Query safe margins if available
	var safe_top: float = 0.0
	var safe_bottom: float = 0.0
	var safe_mgr = get_node_or_null("/root/AndroidSystemManager")
	if safe_mgr and safe_mgr.has_method("get_safe_margins"):
		var m = safe_mgr.get_safe_margins()
		safe_top = float(m.get("top", 0))
		safe_bottom = float(m.get("bottom", 0))

	# Responsive vertical budget calculation for small, medium, and tall screens
	# Small screens (e.g. 360x640): Top HUD ~90px, Bottom Controls ~230px
	# Standard screens (e.g. 720x1280): Top HUD ~120px, Bottom Controls ~310px
	# Tall screens (e.g. 1080x2400): Top HUD ~150px, Bottom Controls ~360px
	var top_hud_h: float = 110.0 + safe_top
	var bottom_hud_h: float = 290.0 + safe_bottom

	if viewport_size.y < 700.0:
		top_hud_h = 80.0 + safe_top
		bottom_hud_h = 230.0 + safe_bottom
	elif viewport_size.y > 1600.0:
		top_hud_h = 150.0 + safe_top
		bottom_hud_h = 370.0 + safe_bottom

	var available_h: float = maxf(viewport_size.y - (top_hud_h + bottom_hud_h), 180.0)
	var available_w: float = maxf(viewport_size.x - 32.0, 180.0)

	var scale_x: float = available_w / float(maxi(level_def.grid_width, 1))
	var scale_y: float = available_h / float(maxi(level_def.grid_height, 1))
	tile_size = clampf(minf(scale_x, scale_y), 20.0, 84.0)

	var total_grid_w: float = float(level_def.grid_width) * tile_size
	var total_grid_h: float = float(level_def.grid_height) * tile_size

	board_offset = Vector2(
		(viewport_size.x - total_grid_w) * 0.5,
		top_hud_h + (available_h - total_grid_h) * 0.5
	)

func _process(delta: float) -> void:
	_pulse_timer += delta * 2.8

	# Update shockwave
	if _shockwave_timer > 0.0:
		_shockwave_timer -= delta * 2.0
		if _shockwave_timer < 0.0:
			_shockwave_timer = 0.0

	# Update ambient particles
	for p: Dictionary in _ambient_particles:
		p["pos"].y -= p["speed"] * delta
		if p["pos"].y < 0.0:
			p["pos"].y = 1.0
			p["pos"].x = randf()

	# Interpolation speed (instant if reduced animations enabled)
	var lerp_speed: float = 20.0 * delta
	var anim_speed: float = 12.0 * delta
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and bool(save_mgr.get("reduced_animations")):
		lerp_speed = 1.0
		anim_speed = 1.0

	player_visual_pos = player_visual_pos.lerp(player_target_pos, lerp_speed)
	for i in range(echo_visual_positions.size()):
		if i < echo_target_positions.size():
			echo_visual_positions[i] = echo_visual_positions[i].lerp(echo_target_positions[i], lerp_speed)

	# Interpolate plate animation weights
	for pid in plate_anim_weights.keys():
		var target: float = 1.0 if simulation.is_plate_active(pid) else 0.0
		plate_anim_weights[pid] = move_toward(plate_anim_weights[pid], target, anim_speed)

	# Interpolate door animation weights
	for did in door_anim_weights.keys():
		var target: float = 1.0 if simulation.is_door_open(did) else 0.0
		door_anim_weights[did] = move_toward(door_anim_weights[did], target, anim_speed)

	queue_redraw()

func _reset_visual_positions() -> void:
	if simulation == null or level_def == null:
		return
	player_target_pos = grid_to_world(simulation.player_pos)
	player_visual_pos = player_target_pos
	player_facing_dir = Vector2i.DOWN

	echo_visual_positions.clear()
	echo_target_positions.clear()
	echo_facing_dirs.clear()
	echo_trail_points.clear()

	for i in range(simulation.echoes.size()):
		var target: Vector2 = grid_to_world(simulation.get_echo_position(i))
		echo_target_positions.append(target)
		echo_visual_positions.append(target)
		echo_facing_dirs.append(Vector2i.DOWN)
		echo_trail_points.append([target])

	# Reset animation weights
	plate_anim_weights.clear()
	for p: Dictionary in level_def.plates_data:
		var pid: String = str(p.get("id", ""))
		plate_anim_weights[pid] = 1.0 if simulation.is_plate_active(pid) else 0.0

	door_anim_weights.clear()
	for d: Dictionary in level_def.doors_data:
		var did: String = str(d.get("id", ""))
		door_anim_weights[did] = 1.0 if simulation.is_door_open(did) else 0.0

func _on_player_moved(from_pos: Vector2i, to_pos: Vector2i, _action: String) -> void:
	player_target_pos = grid_to_world(to_pos)
	if to_pos != from_pos:
		player_facing_dir = to_pos - from_pos

func _on_echo_stepped(echo_index: int, pos: Vector2i, _action: String) -> void:
	var target: Vector2 = grid_to_world(pos)
	if echo_index >= echo_target_positions.size():
		echo_target_positions.resize(echo_index + 1)
		echo_visual_positions.resize(echo_index + 1)
		echo_facing_dirs.resize(echo_index + 1)
		echo_trail_points.resize(echo_index + 1)
		echo_visual_positions[echo_index] = target
		echo_facing_dirs[echo_index] = Vector2i.DOWN
		echo_trail_points[echo_index] = []

	var old_target: Vector2 = echo_target_positions[echo_index]
	echo_target_positions[echo_index] = target

	# Update facing direction & trail
	if target != old_target:
		echo_facing_dirs[echo_index] = pos - world_to_grid(old_target)
		var trail: Array = echo_trail_points[echo_index]
		trail.append(target)
		if trail.size() > 5:
			trail.pop_front()

func _on_echo_created(_echo_index: int, _total: int) -> void:
	_shockwave_origin = grid_to_world(level_def.spawn_pos)
	_shockwave_timer = 1.0 # Trigger shockwave animation
	_reset_visual_positions()

func _on_echoes_cleared() -> void:
	_reset_visual_positions()

func _on_attempt_restarted() -> void:
	_reset_visual_positions()

func _on_plate_state_changed(plate_id: String, is_active: bool) -> void:
	if not plate_anim_weights.has(plate_id):
		plate_anim_weights[plate_id] = 1.0 if is_active else 0.0

func _on_door_state_changed(door_id: String, is_open: bool) -> void:
	if not door_anim_weights.has(door_id):
		door_anim_weights[door_id] = 1.0 if is_open else 0.0

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return board_offset + Vector2(grid_pos.x * tile_size + tile_size * 0.5, grid_pos.y * tile_size + tile_size * 0.5)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = world_pos - board_offset
	return Vector2i(int(floor(local.x / tile_size)), int(floor(local.y / tile_size)))

# ==============================================================================
# Rendering
# ==============================================================================

func _draw() -> void:
	if level_def == null or simulation == null:
		return

	_draw_ambient_effects()
	_draw_board_grid()
	_draw_pressure_plates()
	_draw_doors()
	_draw_exit_portal()
	_draw_echo_trails()
	_draw_echoes()
	_draw_player()
	_draw_shockwave()
	if show_debug_connections:
		_draw_debug_connections()

func _draw_ambient_effects() -> void:
	var total_w: float = float(level_def.grid_width) * tile_size
	var total_h: float = float(level_def.grid_height) * tile_size
	var board_rect: Rect2 = Rect2(board_offset, Vector2(total_w, total_h))

	# Subtle board drop shadow
	draw_rect(Rect2(board_offset + Vector2(0, 8), Vector2(total_w, total_h)), Color(0, 0, 0, 0.45), true)

	# Ambient floating temporal dust particles
	for p: Dictionary in _ambient_particles:
		var p_pos: Vector2 = board_offset + Vector2(p["pos"].x * total_w, p["pos"].y * total_h)
		var p_color: Color = Color(COLOR_PLAYER.r, COLOR_PLAYER.g, COLOR_PLAYER.b, p["alpha"] * 0.6)
		draw_circle(p_pos, p["size"], p_color)

func _draw_board_grid() -> void:
	for y in range(level_def.grid_height):
		for x in range(level_def.grid_width):
			var pos: Vector2i = Vector2i(x, y)
			var rect: Rect2 = Rect2(board_offset.x + x * tile_size, board_offset.y + y * tile_size, tile_size, tile_size)

			if level_def.is_wall(pos):
				# Solid raised 3D metallic wall block
				# Base shadow
				draw_rect(rect, COLOR_WALL_SHADOW, true)
				# Main face
				var inset: float = tile_size * 0.08
				var face_rect: Rect2 = Rect2(rect.position + Vector2(inset, inset), rect.size - Vector2(inset * 2.0, inset * 2.0))
				draw_rect(face_rect, COLOR_WALL, true)

				# Top/Left highlight bevel
				draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), COLOR_WALL_HIGHLIGHT, 2.0)
				draw_line(rect.position, rect.position + Vector2(0, rect.size.y), COLOR_WALL_HIGHLIGHT, 2.0)
				# Bottom/Right shadow bevel
				draw_line(rect.position + Vector2(0, rect.size.y), rect.end, COLOR_WALL_SHADOW, 2.0)
				draw_line(rect.position + Vector2(rect.size.x, 0), rect.end, COLOR_WALL_SHADOW, 2.0)
				# Outer border
				draw_rect(rect, COLOR_WALL_BORDER, false, 1.0)
			else:
				# High-contrast floor tile
				var is_alt: bool = ((x + y) % 2 == 1)
				draw_rect(rect, COLOR_FLOOR_ALT if is_alt else COLOR_FLOOR, true)
				draw_rect(rect, COLOR_FLOOR_LINE, false, 1.0)

				# Tech corner notches
				var c: Vector2 = rect.get_center()
				var notch: float = tile_size * 0.12
				draw_line(rect.position + Vector2(notch, 0), rect.position + Vector2(0, notch), Color(0.25, 0.35, 0.5, 0.25), 1.0)
				draw_line(rect.end - Vector2(notch, 0), rect.end - Vector2(0, notch), Color(0.25, 0.35, 0.5, 0.25), 1.0)

func _draw_pressure_plates() -> void:
	for p: Dictionary in level_def.plates_data:
		var pid: String = str(p.get("id", ""))
		var ppos: Vector2i = p.get("pos", Vector2i(-1, -1))
		var center: Vector2 = grid_to_world(ppos)
		var weight: float = plate_anim_weights.get(pid, 0.0)

		# Outer recessed basin
		var outer_r: float = tile_size * 0.42
		draw_circle(center, outer_r, Color(0.06, 0.09, 0.14))
		draw_arc(center, outer_r, 0, TAU, 32, Color(0.22, 0.3, 0.45), 1.5)

		# Animated active glow aura
		if weight > 0.01:
			var pulse: float = sin(_pulse_timer * 1.5) * 0.12 + 0.88
			var aura_r: float = tile_size * (0.45 + weight * 0.15) * pulse
			draw_circle(center, aura_r, Color(COLOR_AMBER_ACTIVE.r, COLOR_AMBER_ACTIVE.g, COLOR_AMBER_ACTIVE.b, 0.35 * weight * pulse))

		# Plate central pad (scale slightly down when depressed)
		var pad_scale: float = lerpf(1.0, 0.88, weight)
		var pad_r: float = tile_size * 0.32 * pad_scale

		var pad_color: Color = Color(0.14, 0.18, 0.28).lerp(COLOR_AMBER_ACTIVE, weight)
		draw_circle(center, pad_r, pad_color)

		var border_color: Color = Color(0.35, 0.45, 0.6).lerp(Color.WHITE, weight)
		draw_arc(center, pad_r, 0, TAU, 24, border_color, 2.0)

		# Plate ID label
		var text_col: Color = Color("#0F172A") if weight > 0.5 else Color("#94A3B8")
		draw_string(ThemeDB.fallback_font, center + Vector2(-5, 6), pid, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, text_col)

func _draw_doors() -> void:
	for d: Dictionary in level_def.doors_data:
		var did: String = str(d.get("id", ""))
		var dpos: Vector2i = d.get("pos", Vector2i(-1, -1))
		var weight: float = door_anim_weights.get(did, 0.0)
		var logic: String = str(d.get("logic", "AND")).to_upper()
		var center: Vector2 = grid_to_world(dpos)
		var rect: Rect2 = Rect2(board_offset.x + dpos.x * tile_size, board_offset.y + dpos.y * tile_size, tile_size, tile_size)

		# Left and right heavy steel door jambs
		var jamb_w: float = tile_size * 0.16
		var left_jamb: Rect2 = Rect2(rect.position.x, rect.position.y, jamb_w, rect.size.y)
		var right_jamb: Rect2 = Rect2(rect.end.x - jamb_w, rect.position.y, jamb_w, rect.size.y)
		draw_rect(left_jamb, COLOR_WALL, true)
		draw_rect(right_jamb, COLOR_WALL, true)
		draw_rect(left_jamb, COLOR_WALL_BORDER, false, 1.5)
		draw_rect(right_jamb, COLOR_WALL_BORDER, false, 1.5)

		# Center retractable gate area
		var gate_w: float = (rect.size.x - jamb_w * 2.0) * (1.0 - weight)
		var open_alpha: float = 1.0 - weight

		if open_alpha > 0.05:
			# Locked / Closing state: Armored barrier with glowing red laser bars
			var gate_rect: Rect2 = Rect2(center.x - gate_w * 0.5, rect.position.y + 2, gate_w, rect.size.y - 4)
			var gate_bg: Color = Color(0.22, 0.08, 0.12, open_alpha)
			draw_rect(gate_rect, gate_bg, true)

			# Red energy laser beams
			var beam_col: Color = Color(COLOR_LOCKED_RED.r, COLOR_LOCKED_RED.g, COLOR_LOCKED_RED.b, open_alpha)
			draw_line(Vector2(gate_rect.position.x, center.y - 8), Vector2(gate_rect.end.x, center.y - 8), beam_col, 2.0)
			draw_line(Vector2(gate_rect.position.x, center.y + 8), Vector2(gate_rect.end.x, center.y + 8), beam_col, 2.0)
			draw_rect(gate_rect, beam_col, false, 1.5)

			# Door label & logic badge
			if open_alpha > 0.6:
				var badge_text: String = "%s: %s" % [did, logic]
				if logic == "SEQUENCE":
					var seq: Array = d.get("required_sequence", [])
					var cur_step: int = simulation.get_sequence_progress(did) if simulation else 0
					badge_text = "%s: %d/%d" % [did, cur_step, seq.size()]
				draw_string(ThemeDB.fallback_font, center + Vector2(-18, 5), badge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, beam_col)
		else:
			# Open state: glowing floor conduits with direction chevrons
			var open_glow: Color = Color(COLOR_AMBER_ACTIVE.r, COLOR_AMBER_ACTIVE.g, COLOR_AMBER_ACTIVE.b, 0.25)
			draw_rect(Rect2(rect.position.x + jamb_w, rect.position.y + 4, rect.size.x - jamb_w * 2.0, rect.size.y - 8), open_glow, true)
			# Small green/amber clearance chevrons
			draw_line(center - Vector2(6, 4), center + Vector2(0, 0), COLOR_AMBER_ACTIVE, 2.0)
			draw_line(center + Vector2(6, -4), center + Vector2(0, 0), COLOR_AMBER_ACTIVE, 2.0)
			draw_line(center - Vector2(6, 4), center + Vector2(0, 8), COLOR_AMBER_ACTIVE, 2.0)
			draw_line(center + Vector2(6, 4), center + Vector2(0, 8), COLOR_AMBER_ACTIVE, 2.0)

func _draw_exit_portal() -> void:
	var center: Vector2 = grid_to_world(level_def.exit_pos)
	var pulse: float = sin(_pulse_timer * 1.8) * 0.15 + 0.85

	# Outer pulsating event horizon aura
	draw_circle(center, tile_size * 0.48 * pulse, Color(COLOR_EXIT.r, COLOR_EXIT.g, COLOR_EXIT.b, 0.22))
	draw_circle(center, tile_size * 0.36, Color(COLOR_EXIT.r, COLOR_EXIT.g, COLOR_EXIT.b, 0.45))
	draw_circle(center, tile_size * 0.22, Color.WHITE)

	# Spinning concentric vortex rings
	draw_arc(center, tile_size * 0.40, _pulse_timer, _pulse_timer + PI * 0.8, 20, COLOR_EXIT, 2.5)
	draw_arc(center, tile_size * 0.40, _pulse_timer + PI, _pulse_timer + PI * 1.8, 20, COLOR_EXIT, 2.5)
	draw_arc(center, tile_size * 0.28, -_pulse_timer * 1.5, -_pulse_timer * 1.5 + PI, 16, Color.WHITE, 1.8)

func _draw_echo_trails() -> void:
	for i in range(echo_trail_points.size()):
		var trail: Array = echo_trail_points[i]
		if trail.size() < 2:
			continue
		for j in range(trail.size() - 1):
			var p1: Vector2 = trail[j]
			var p2: Vector2 = trail[j + 1]
			var alpha: float = float(j + 1) / float(trail.size()) * 0.4
			var trail_color: Color = Color(COLOR_ECHO.r, COLOR_ECHO.g, COLOR_ECHO.b, alpha)
			draw_line(p1, p2, trail_color, 3.0)

func _draw_echoes() -> void:
	for i in range(echo_visual_positions.size()):
		var is_active: bool = simulation.is_echo_active(i) if simulation else true
		if not is_active:
			# Expired Echo is not drawn on board
			continue

		var remaining: int = simulation.get_echo_remaining_turns(i) if simulation else 99
		var is_warning: bool = (remaining == 1)
		var e_pos: Vector2 = echo_visual_positions[i]
		var radius: float = tile_size * 0.33
		var aura_pulse: float = sin(_pulse_timer + float(i) * 1.8) * 0.12 + 0.88

		# Holographic expanding aura (amber pulse if 1 turn left before expiration)
		var aura_color: Color = Color("#FFBE55") if is_warning else COLOR_ECHO
		var aura_alpha: float = (sin(_pulse_timer * 6.0) * 0.2 + 0.35) if is_warning else 0.2
		draw_circle(e_pos, radius * 1.4 * aura_pulse, Color(aura_color.r, aura_color.g, aura_color.b, aura_alpha))

		# Semi-transparent holographic phantom body
		draw_circle(e_pos, radius, Color(COLOR_ECHO.r, COLOR_ECHO.g, COLOR_ECHO.b, 0.65))
		draw_circle(e_pos, radius * 0.65, Color(0.9, 0.85, 1.0, 0.75))

		# Holographic horizontal scanlines
		for scan_y in range(-int(radius) + 3, int(radius) - 2, 4):
			var half_chord: float = sqrt(maxf(radius * radius - float(scan_y * scan_y), 0.0)) * 0.8
			draw_line(e_pos + Vector2(-half_chord, scan_y), e_pos + Vector2(half_chord, scan_y), Color(1, 1, 1, 0.35), 1.0)

		# Distinct outer ring
		var ring_color: Color = Color("#FFBE55") if is_warning else Color.WHITE
		draw_arc(e_pos, radius, 0, TAU, 28, ring_color, 2.0)

		# Echo ID badge pill + remaining turns
		var badge_rect: Rect2 = Rect2(e_pos.x - 22, e_pos.y - radius - 15, 44, 16)
		draw_rect(badge_rect, Color("#1E1B4B"), true)
		draw_rect(badge_rect, ring_color, false, 1.5)
		var badge_str: String = "E%d:%d" % [i + 1, remaining]
		draw_string(ThemeDB.fallback_font, Vector2(badge_rect.position.x + 3, badge_rect.position.y + 12), badge_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, ring_color)

func _draw_player() -> void:
	var radius: float = tile_size * 0.35
	var pulse: float = sin(_pulse_timer * 2.0) * 0.08 + 0.92

	# Sharp cyan pulse halo
	draw_circle(player_visual_pos, radius * 1.35 * pulse, Color(COLOR_PLAYER.r, COLOR_PLAYER.g, COLOR_PLAYER.b, 0.28))

	# Solid high-contrast cyber agent body
	draw_circle(player_visual_pos, radius, COLOR_PLAYER)
	draw_circle(player_visual_pos, radius * 0.65, Color("#0B132B"))
	draw_circle(player_visual_pos, radius * 0.32, Color.WHITE)
	draw_arc(player_visual_pos, radius, 0, TAU, 32, Color.WHITE, 2.2)

	# Directional visor chevron pointing in facing direction
	var dir_vec: Vector2 = Vector2(player_facing_dir).normalized() * (radius * 0.7)
	var perp: Vector2 = Vector2(-dir_vec.y, dir_vec.x) * 0.5
	draw_line(player_visual_pos + dir_vec * 0.4 + perp, player_visual_pos + dir_vec, Color.WHITE, 2.5)
	draw_line(player_visual_pos + dir_vec * 0.4 - perp, player_visual_pos + dir_vec, Color.WHITE, 2.5)

func _draw_shockwave() -> void:
	if _shockwave_timer <= 0.0:
		return
	var progress: float = 1.0 - _shockwave_timer
	var shock_r: float = progress * tile_size * 4.5
	var shock_alpha: float = (1.0 - progress) * 0.7
	var shock_col: Color = Color(COLOR_ECHO.r, COLOR_ECHO.g, COLOR_ECHO.b, shock_alpha)
	draw_arc(_shockwave_origin, shock_r, 0, TAU, 36, shock_col, 3.0)

func _draw_debug_connections() -> void:
	if level_def == null:
		return

	# 1. Door to Plate connection lines
	for d: Dictionary in level_def.doors_data:
		var d_pos: Vector2 = grid_to_world(d.get("pos", Vector2i.ZERO))
		var did: String = str(d.get("id", ""))
		var req: Array = d.get("required_plates", [])
		var logic: String = str(d.get("logic", "AND")).to_upper()
		if logic == "SEQUENCE":
			var seq: Array = d.get("required_sequence", [])
			var prev_pos: Vector2 = Vector2.ZERO
			var has_prev: bool = false
			for step_i in range(seq.size()):
				var seq_pid = seq[step_i]
				for p: Dictionary in level_def.plates_data:
					if str(p.get("id", "")) == str(seq_pid):
						var p_pos: Vector2 = grid_to_world(p.get("pos", Vector2i.ZERO))
						if has_prev:
							draw_line(prev_pos, p_pos, Color("#FF647C"), 2.0)
						prev_pos = p_pos
						has_prev = true
						draw_string(ThemeDB.fallback_font, p_pos + Vector2(10, -10), "[#%d]" % (step_i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FF647C"))
			if has_prev:
				draw_line(prev_pos, d_pos, Color("#FF647C"), 2.5)
				draw_string(ThemeDB.fallback_font, (prev_pos + d_pos) * 0.5, "SEQ➔%s" % did, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#FF647C"))
		else:
			for pid in req:
				for p: Dictionary in level_def.plates_data:
					if str(p.get("id", "")) == str(pid):
						var p_pos: Vector2 = grid_to_world(p.get("pos", Vector2i.ZERO))
						draw_line(p_pos, d_pos, Color(1.0, 0.75, 0.2, 0.85), 2.5)
						var mid: Vector2 = (p_pos + d_pos) * 0.5
						draw_string(ThemeDB.fallback_font, mid, "%s➔%s" % [pid, did], HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color("#FFBE55"))

	# 2. Highlight spawn & exit
	var spawn_w: Vector2 = grid_to_world(level_def.spawn_pos)
	draw_arc(spawn_w, tile_size * 0.45, 0, TAU, 24, Color("#54E6EA"), 2.0)
	draw_string(ThemeDB.fallback_font, spawn_w + Vector2(-16, -tile_size * 0.4), "SPAWN", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#54E6EA"))

	var exit_w: Vector2 = grid_to_world(level_def.exit_pos)
	draw_arc(exit_w, tile_size * 0.45, 0, TAU, 24, Color("#38BDF8"), 2.0)
	draw_string(ThemeDB.fallback_font, exit_w + Vector2(-12, tile_size * 0.55), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#38BDF8"))
