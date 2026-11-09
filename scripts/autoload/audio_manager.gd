extends Node

## Procedural audio synthesizer and sound manager for Tomorrow's You.
## Generates clean 16-bit retro-futuristic sound effects and ambient synth pads in-engine.

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 8

var _cached_sounds: Dictionary = {}
var _music_stream: AudioStreamWAV = null

func _ready() -> void:
	# Configure master bus or volume settings
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	for i in range(MAX_SFX_PLAYERS):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

	_pregenerate_sounds()
	_update_volumes()

	if SaveManager:
		SaveManager.save_loaded.connect(_update_volumes)

	play_music()

func _update_volumes() -> void:
	if SaveManager == null:
		return
	if SaveManager.music_volume <= 0.001:
		music_player.volume_db = -80.0
	else:
		music_player.volume_db = linear_to_db(SaveManager.music_volume)

	var sfx_vol_db: float = -80.0 if SaveManager.sfx_volume <= 0.001 else linear_to_db(SaveManager.sfx_volume)
	for p: AudioStreamPlayer in sfx_players:
		p.volume_db = sfx_vol_db

func play_sfx(sound_name: String) -> void:
	if SaveManager and SaveManager.sfx_volume <= 0.001:
		return
	var stream: AudioStreamWAV = _cached_sounds.get(sound_name, null)
	if stream == null:
		return

	for p: AudioStreamPlayer in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# All busy, steal first
	sfx_players[0].stream = stream
	sfx_players[0].play()

func play_music() -> void:
	if SaveManager and SaveManager.music_volume <= 0.001:
		return
	if _music_stream != null and not music_player.playing:
		music_player.stream = _music_stream
		music_player.play()

func stop_music() -> void:
	music_player.stop()

# ==============================================================================
# Procedural Audio Generation
# ==============================================================================

func _pregenerate_sounds() -> void:
	_cached_sounds["move"] = _synth_tone(520.0, 0.06, 0.8, "sine", true)
	_cached_sounds["wait"] = _synth_tone(240.0, 0.08, 0.6, "triangle", false)
	_cached_sounds["echo_create"] = _synth_arp([330.0, 440.0, 660.0, 880.0], 0.28, 0.9)
	_cached_sounds["plate_on"] = _synth_tone(350.0, 0.12, 0.85, "square", false)
	_cached_sounds["plate_off"] = _synth_tone(220.0, 0.10, 0.7, "sine", false)
	_cached_sounds["door_open"] = _synth_slide(260.0, 520.0, 0.22, 0.8)
	_cached_sounds["door_close"] = _synth_slide(480.0, 200.0, 0.18, 0.8)
	_cached_sounds["blocked"] = _synth_buzz(140.0, 0.14, 0.9)
	_cached_sounds["victory"] = _synth_arp([440.0, 554.37, 659.25, 880.0, 1108.73], 0.6, 0.95)
	_cached_sounds["ui_click"] = _synth_tone(800.0, 0.03, 0.5, "sine", true)

	_music_stream = _synth_ambient_loop(4.0)

func _synth_tone(freq: float, duration: float, volume: float, wave_type: String, decay_fast: bool) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = int(sample_rate * duration)
	var raw: PackedByteArray = PackedByteArray()
	raw.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)
		var progress: float = float(i) / float(sample_count)
		var env: float = (1.0 - progress * progress) if decay_fast else (1.0 - progress)

		var val: float = 0.0
		var phase: float = TAU * freq * t
		match wave_type:
			"sine":
				val = sin(phase)
			"triangle":
				val = asin(sin(phase)) * (2.0 / PI)
			"square":
				val = 0.7 if sin(phase) >= 0.0 else -0.7

		var sample_val: int = int(clampf(val * env * volume, -1.0, 1.0) * 32767.0)
		raw.encode_s16(i * 2, sample_val)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = raw
	return stream

func _synth_slide(start_f: float, end_f: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = int(sample_rate * duration)
	var raw: PackedByteArray = PackedByteArray()
	raw.resize(sample_count * 2)

	var current_phase: float = 0.0
	for i in range(sample_count):
		var p: float = float(i) / float(sample_count)
		var freq: float = lerpf(start_f, end_f, p)
		var env: float = sin(p * PI) # Bell envelope
		current_phase += TAU * freq / float(sample_rate)
		var val: float = sin(current_phase) * 0.8 + sin(current_phase * 2.0) * 0.2
		var sample_val: int = int(clampf(val * env * volume, -1.0, 1.0) * 32767.0)
		raw.encode_s16(i * 2, sample_val)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = raw
	return stream

func _synth_buzz(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = int(sample_rate * duration)
	var raw: PackedByteArray = PackedByteArray()
	raw.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)
		var env: float = 1.0 - (float(i) / float(sample_count))
		# Modulated square wave buzz
		var val: float = (1.0 if sin(TAU * freq * t) > 0.0 else -1.0) * 0.6
		var sample_val: int = int(clampf(val * env * volume, -1.0, 1.0) * 32767.0)
		raw.encode_s16(i * 2, sample_val)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = raw
	return stream

func _synth_arp(notes: Array, total_dur: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = int(sample_rate * total_dur)
	var raw: PackedByteArray = PackedByteArray()
	raw.resize(sample_count * 2)

	var note_dur_samples: int = sample_count / notes.size()
	for i in range(sample_count):
		var note_idx: int = mini(i / note_dur_samples, notes.size() - 1)
		var freq: float = float(notes[note_idx])
		var local_i: int = i % note_dur_samples
		var env: float = 1.0 - (float(local_i) / float(note_dur_samples)) * 0.7
		var t: float = float(i) / float(sample_rate)
		var val: float = sin(TAU * freq * t) * 0.8 + sin(TAU * freq * 1.5 * t) * 0.2
		var sample_val: int = int(clampf(val * env * volume, -1.0, 1.0) * 32767.0)
		raw.encode_s16(i * 2, sample_val)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = raw
	return stream

func _synth_ambient_loop(duration: float) -> AudioStreamWAV:
	var sample_rate: int = 16000
	var sample_count: int = int(sample_rate * duration)
	var raw: PackedByteArray = PackedByteArray()
	raw.resize(sample_count * 2)

	# Frequencies of a minor chord pad (A2, C3, E3, G3)
	var freqs: Array[float] = [110.0, 130.81, 164.81, 196.0]
	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)
		var cycle: float = float(i) / float(sample_count)
		# Smooth seamless loop envelope
		var loop_env: float = sin(cycle * PI) * 0.7 + 0.3
		var val: float = 0.0
		for f in freqs:
			val += sin(TAU * f * t) * 0.2 + sin(TAU * (f * 1.005) * t) * 0.1
		var sample_val: int = int(clampf(val * loop_env * 0.4, -1.0, 1.0) * 32767.0)
		raw.encode_s16(i * 2, sample_val)

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = raw
	return stream

