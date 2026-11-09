class_name BackgroundParticles
extends Control

## Procedural, lightweight atmospheric floating particle system.
## Simulates ambient dust motes, temporal energy sparks, and air currents.
## Zero allocation in runtime loop for peak mobile battery efficiency.

var particle_count: int = 30
var base_speed: float = 16.0
var primary_color: Color = Color(0.329, 0.902, 0.918, 1.0)
var secondary_color: Color = Color(0.655, 0.545, 0.980, 1.0)
var reduced_motion: bool = false
var paused: bool = false

class Mote:
	var pos: Vector2 = Vector2.ZERO
	var vel: Vector2 = Vector2.ZERO
	var size: float = 2.0
	var alpha: float = 0.5
	var phase: float = 0.0
	var phase_speed: float = 1.0
	var is_primary: bool = true

var _motes: Array[Mote] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_rng.randomize()
	_init_particles()
	resized.connect(_on_resized)

func set_palette(prim: Color, sec: Color) -> void:
	primary_color = prim
	secondary_color = sec
	queue_redraw()

func set_motion_settings(count: int, speed: float, reduced: bool) -> void:
	particle_count = count
	base_speed = speed
	reduced_motion = reduced
	_adjust_particle_count()

func set_paused_state(is_paused: bool) -> void:
	paused = is_paused

func _on_resized() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	# Re-wrap any particles outside new bounds
	for m in _motes:
		if m.pos.x > size.x: m.pos.x = fmod(m.pos.x, size.x)
		if m.pos.y > size.y: m.pos.y = fmod(m.pos.y, size.y)
	queue_redraw()

func _init_particles() -> void:
	_motes.clear()
	var w: float = maxf(size.x, 720.0)
	var h: float = maxf(size.y, 1280.0)
	for i in range(particle_count):
		var m: Mote = Mote.new()
		m.pos = Vector2(_rng.randf_range(0.0, w), _rng.randf_range(0.0, h))
		m.vel = Vector2(_rng.randf_range(-4.0, 4.0), -_rng.randf_range(base_speed * 0.6, base_speed * 1.4))
		m.size = _rng.randf_range(1.2, 3.2)
		m.alpha = _rng.randf_range(0.2, 0.7)
		m.phase = _rng.randf_range(0.0, TAU)
		m.phase_speed = _rng.randf_range(0.8, 2.2)
		m.is_primary = (_rng.randf() > 0.4)
		_motes.append(m)

func _adjust_particle_count() -> void:
	var w: float = maxf(size.x, 720.0)
	var h: float = maxf(size.y, 1280.0)
	while _motes.size() < particle_count:
		var m: Mote = Mote.new()
		m.pos = Vector2(_rng.randf_range(0.0, w), _rng.randf_range(0.0, h))
		m.vel = Vector2(_rng.randf_range(-4.0, 4.0), -_rng.randf_range(base_speed * 0.6, base_speed * 1.4))
		m.size = _rng.randf_range(1.2, 3.2)
		m.alpha = _rng.randf_range(0.2, 0.7)
		m.phase = _rng.randf_range(0.0, TAU)
		m.phase_speed = _rng.randf_range(0.8, 2.2)
		m.is_primary = (_rng.randf() > 0.4)
		_motes.append(m)
	while _motes.size() > particle_count:
		_motes.pop_back()

func _process(delta: float) -> void:
	if _motes.is_empty():
		return

	var w: float = maxf(size.x, 720.0)
	var h: float = maxf(size.y, 1280.0)
	var dt: float = delta
	if paused:
		dt *= 0.15
	if reduced_motion:
		dt *= 0.25

	for m in _motes:
		m.phase += m.phase_speed * dt
		# Gentle horizontal sine wave drift
		var sway: float = sin(m.phase) * (6.0 if not reduced_motion else 1.0)
		m.pos.x += (m.vel.x + sway) * dt
		m.pos.y += m.vel.y * dt

		# Wrap-around screen bounds
		if m.pos.y < -10.0:
			m.pos.y = h + 10.0
			m.pos.x = _rng.randf_range(0.0, w)
		elif m.pos.y > h + 10.0:
			m.pos.y = -10.0
			m.pos.x = _rng.randf_range(0.0, w)

		if m.pos.x < -10.0:
			m.pos.x = w + 10.0
		elif m.pos.x > w + 10.0:
			m.pos.x = -10.0

	queue_redraw()

func _draw() -> void:
	for m in _motes:
		# Subtle pulsation of brightness
		var pulse: float = sin(m.phase) * 0.25 + 0.75
		var base_col: Color = primary_color if m.is_primary else secondary_color
		var current_alpha: float = m.alpha * pulse
		
		# Outer soft glow halo
		var halo_col: Color = Color(base_col.r, base_col.g, base_col.b, current_alpha * 0.3)
		draw_circle(m.pos, m.size * 2.2, halo_col)
		
		# Bright energetic core
		var core_col: Color = Color(
			lerpf(base_col.r, 1.0, 0.4),
			lerpf(base_col.g, 1.0, 0.4),
			lerpf(base_col.b, 1.0, 0.4),
			current_alpha
		)
		draw_circle(m.pos, m.size, core_col)

