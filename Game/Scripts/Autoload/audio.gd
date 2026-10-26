extends Node

## All sound is synthesised at startup so the game ships no audio files.
## Effects are short note lists; music is an original chiptune rendered a slice per frame,
## so it works on the single-threaded web build without freezing the title screen.

enum Wave {
	SQUARE,
	PULSE,
	TRIANGLE,
	SINE,
	NOISE,
}

const MIX_RATE := 22050
const PLAYER_COUNT := 12
const EFFECTS_VOLUME_DB := -9.0
const MUSIC_VOLUME_DB := -11.0
const ATTACK_SECONDS := 0.004
# Music rendering yields back to the engine after this much work in one frame.
const RENDER_BUDGET_USEC := 5000

# Each note: [wave, start Hz, end Hz, seconds, volume 0..1]. Notes play one after another.
const SOUNDS := {
	"start": [
		[Wave.PULSE, 523.0, 523.0, 0.07, 0.5],
		[Wave.PULSE, 784.0, 784.0, 0.07, 0.5],
		[Wave.PULSE, 1047.0, 1047.0, 0.16, 0.5],
	],
	"shot": [
		[Wave.PULSE, 1500.0, 700.0, 0.045, 0.16],
	],
	"bomb_drop": [
		[Wave.TRIANGLE, 900.0, 300.0, 0.16, 0.45],
	],
	"bomb_hit": [
		[Wave.NOISE, 1800.0, 120.0, 0.28, 0.6],
	],
	"hit": [
		[Wave.SQUARE, 300.0, 220.0, 0.03, 0.22],
	],
	"explode": [
		[Wave.NOISE, 2600.0, 300.0, 0.22, 0.5],
	],
	"explode_big": [
		[Wave.NOISE, 2000.0, 60.0, 0.9, 0.8],
	],
	"cloud": [
		[Wave.TRIANGLE, 500.0, 760.0, 0.06, 0.35],
	],
	"bell_hit": [
		[Wave.SINE, 1760.0, 1760.0, 0.09, 0.4],
	],
	"bell_change": [
		[Wave.SINE, 1319.0, 1319.0, 0.06, 0.45],
		[Wave.SINE, 1976.0, 1976.0, 0.14, 0.45],
	],
	"bell_break": [
		[Wave.NOISE, 4000.0, 900.0, 0.18, 0.4],
	],
	"bell_get": [
		[Wave.SINE, 1568.0, 1568.0, 0.06, 0.5],
		[Wave.SINE, 2093.0, 2093.0, 0.06, 0.5],
		[Wave.SINE, 2637.0, 2637.0, 0.18, 0.5],
	],
	"powerup": [
		[Wave.PULSE, 523.0, 1047.0, 0.1, 0.45],
		[Wave.PULSE, 784.0, 1568.0, 0.14, 0.45],
	],
	"fruit": [
		[Wave.TRIANGLE, 988.0, 988.0, 0.05, 0.5],
		[Wave.TRIANGLE, 1319.0, 1319.0, 0.12, 0.5],
	],
	"arm_lost": [
		[Wave.SQUARE, 600.0, 150.0, 0.25, 0.45],
	],
	"siren": [
		[Wave.TRIANGLE, 880.0, 880.0, 0.18, 0.3],
		[Wave.TRIANGLE, 660.0, 660.0, 0.18, 0.3],
		[Wave.TRIANGLE, 880.0, 880.0, 0.18, 0.3],
		[Wave.TRIANGLE, 660.0, 660.0, 0.18, 0.3],
	],
	"arms_back": [
		[Wave.PULSE, 659.0, 659.0, 0.07, 0.45],
		[Wave.PULSE, 880.0, 880.0, 0.07, 0.45],
		[Wave.PULSE, 1319.0, 1319.0, 0.18, 0.45],
	],
	"barrier_hit": [
		[Wave.TRIANGLE, 1200.0, 400.0, 0.12, 0.45],
	],
	"death": [
		[Wave.SQUARE, 880.0, 110.0, 0.35, 0.45],
		[Wave.NOISE, 1500.0, 60.0, 0.7, 0.7],
	],
	"extend": [
		[Wave.PULSE, 784.0, 784.0, 0.08, 0.45],
		[Wave.PULSE, 988.0, 988.0, 0.08, 0.45],
		[Wave.PULSE, 1175.0, 1175.0, 0.08, 0.45],
		[Wave.PULSE, 1568.0, 1568.0, 0.25, 0.45],
	],
	"warning": [
		[Wave.SQUARE, 440.0, 440.0, 0.22, 0.35],
		[Wave.SQUARE, 0.0, 0.0, 0.08, 0.0],
		[Wave.SQUARE, 440.0, 440.0, 0.22, 0.35],
		[Wave.SQUARE, 0.0, 0.0, 0.08, 0.0],
		[Wave.SQUARE, 440.0, 440.0, 0.22, 0.35],
	],
	"stage_clear": [
		[Wave.PULSE, 523.0, 523.0, 0.1, 0.45],
		[Wave.PULSE, 659.0, 659.0, 0.1, 0.45],
		[Wave.PULSE, 784.0, 784.0, 0.1, 0.45],
		[Wave.PULSE, 1047.0, 1047.0, 0.2, 0.45],
		[Wave.PULSE, 988.0, 988.0, 0.1, 0.45],
		[Wave.PULSE, 1047.0, 1047.0, 0.1, 0.45],
		[Wave.PULSE, 1319.0, 1319.0, 0.5, 0.45],
	],
	"game_over": [
		[Wave.TRIANGLE, 523.0, 523.0, 0.25, 0.6],
		[Wave.TRIANGLE, 392.0, 392.0, 0.25, 0.6],
		[Wave.TRIANGLE, 330.0, 330.0, 0.25, 0.6],
		[Wave.TRIANGLE, 262.0, 200.0, 0.8, 0.6],
	],
	"menu": [
		[Wave.PULSE, 1047.0, 1047.0, 0.05, 0.4],
	],
}

# Songs: chords drive bass and arpeggio; melody tokens are eighth notes ("." holds, "-" rests).
const SONGS := {
	"title": {
		"bpm": 118,
		"chords": ["C", "G", "Am", "F", "C", "G", "F", "C"],
		"melody": [
			"G5 . E5 . C5 . E5 G5",
			"D5 . . . B4 . D5 .",
			"C5 . E5 . A5 . G5 .",
			"F5 . E5 . D5 . C5 .",
			"G5 . E5 . C6 . B5 A5",
			"G5 . D5 . G5 . B5 .",
			"A5 . G5 . F5 . D5 .",
			"C5 . . . - - - -",
		],
		"drums": "k - h - s - h h",
	},
	"stage": {
		"bpm": 142,
		"chords": ["C", "Am", "F", "G", "C", "Am", "F", "G", "F", "G", "Em", "Am", "F", "G", "C", "C"],
		"melody": [
			"E5 G5 C6 G5 E5 G5 A5 G5",
			"E5 . C5 . A4 C5 E5 .",
			"F5 A5 C6 A5 F5 A5 G5 F5",
			"D5 . G5 . B4 . D5 .",
			"E5 G5 C6 G5 E5 G5 A5 G5",
			"C6 . B5 A5 E5 . A5 .",
			"A5 G5 F5 E5 D5 . F5 .",
			"G5 . . . - - G4 B4",
			"C5 . F5 . A5 . G5 F5",
			"D5 . G5 . B5 . A5 G5",
			"E5 . G5 . B5 . A5 G5",
			"A5 . E5 . C5 . E5 .",
			"F5 . A5 . C6 . D6 C6",
			"B5 . G5 . D5 . G5 B5",
			"C6 . G5 E5 C5 E5 G5 B5",
			"C6 . . . - - - -",
		],
		"drums": "k h s h k k s h",
	},
	"boss": {
		"bpm": 160,
		"chords": ["Am", "Am", "F", "G", "Am", "Am", "E", "E"],
		"melody": [
			"A4 C5 E5 A5 G5 E5 C5 E5",
			"A4 C5 E5 A5 B5 A5 G5 E5",
			"F5 . A5 . C6 . A5 F5",
			"G5 . B5 . D6 . B5 G5",
			"A5 . . G5 E5 . C5 .",
			"D5 . E5 . C5 . A4 .",
			"B4 . E5 . G#5 . B5 .",
			"E6 . D6 . B5 . G#5 .",
		],
		"drums": "k h s h k h s s",
	},
}

const CHORD_TONES := {
	"C": ["C", 0, 4, 7],
	"G": ["G", 0, 4, 7],
	"F": ["F", 0, 4, 7],
	"E": ["E", 0, 4, 7],
	"Am": ["A", 0, 3, 7],
	"Em": ["E", 0, 3, 7],
}

const NOTE_INDEX := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

var streams := {}
var songs := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music_player: AudioStreamPlayer
var wanted_song := ""
var slice_start := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.volume_db = EFFECTS_VOLUME_DB
		add_child(player)
		players.append(player)

	music_player = AudioStreamPlayer.new()
	music_player.volume_db = MUSIC_VOLUME_DB
	add_child(music_player)

	var rng := RandomNumberGenerator.new()
	for sound_name in SOUNDS:
		streams[sound_name] = _to_stream(_render_effect(SOUNDS[sound_name], rng), false)

	# ~1 minute of music takes seconds of GDScript work; spread it over frames (title song first).
	_render_all_songs()


func play(sound_name: String, volume_db := 0.0) -> void:
	if not streams.has(sound_name):
		push_warning("Unknown sound: %s" % sound_name)
		return

	# Round-robin so overlapping sounds do not cut each other off.
	var player := players[next_player]
	next_player = (next_player + 1) % PLAYER_COUNT
	player.stream = streams[sound_name]
	player.volume_db = EFFECTS_VOLUME_DB + volume_db
	player.play()


func play_music(song_name: String) -> void:
	wanted_song = song_name
	if not songs.has(song_name):
		return
	if music_player.stream == songs[song_name] and music_player.playing:
		return
	music_player.stream = songs[song_name]
	music_player.play()


func stop_music() -> void:
	wanted_song = ""
	music_player.stop()


func _render_all_songs() -> void:
	var rng := RandomNumberGenerator.new()
	slice_start = Time.get_ticks_usec()
	for song_name in ["title", "stage", "boss"]:
		var samples: PackedFloat32Array = await _render_song(SONGS[song_name], rng)
		var data: PackedByteArray = await _encode(samples)
		songs[song_name] = _make_stream(data, samples.size(), true)
		if wanted_song == song_name:
			play_music(song_name)


# Yields to the next frame once this frame's rendering budget is used up.
func _breathe() -> void:
	if Time.get_ticks_usec() - slice_start > RENDER_BUDGET_USEC:
		await get_tree().process_frame
		slice_start = Time.get_ticks_usec()


func _render_effect(notes: Array, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var total := 0
	for note in notes:
		total += int(note[3] * MIX_RATE)

	var buffer := PackedFloat32Array()
	buffer.resize(total)
	var offset := 0
	for note in notes:
		var count := int(note[3] * MIX_RATE)
		_add_tone(buffer, offset, count, note[0], note[1], note[2], note[4], 1.0, rng)
		offset += count
	return buffer


func _render_song(song: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var eighth: float = 30.0 / song["bpm"]
	var step := int(eighth * MIX_RATE)
	var bars: Array = song["chords"]
	var buffer := PackedFloat32Array()
	buffer.resize(step * 8 * bars.size())

	for bar in range(bars.size()):
		var bar_start := bar * 8 * step
		var chord: Array = CHORD_TONES[bars[bar]]
		var root := _midi(chord[0] + "3")

		# Bass: octave bounce on the root.
		for i in range(8):
			var bass_note := root + (12 if i % 2 == 1 else 0)
			_add_tone(buffer, bar_start + i * step, int(step * 0.9), Wave.TRIANGLE,
				_hz(bass_note), _hz(bass_note), 0.42, 0.25, rng)
			await _breathe()

		# Arpeggio: chord tones climbing and falling an octave up.
		var arp_order := [1, 2, 3, 2, 1, 2, 3, 2]
		for i in range(8):
			var arp_note: int = root + 12 + chord[arp_order[i]] + (12 if i == 2 or i == 6 else 0)
			_add_tone(buffer, bar_start + i * step, int(step * 0.5), Wave.PULSE,
				_hz(arp_note), _hz(arp_note), 0.07, 0.15, rng)
			await _breathe()

		await _render_melody_bar(buffer, bar_start, step, song["melody"][bar], rng)
		_render_drum_bar(buffer, bar_start, step, song["drums"], rng)
		await _breathe()

	return buffer


func _render_melody_bar(buffer: PackedFloat32Array, bar_start: int, step: int, line: String, rng: RandomNumberGenerator) -> void:
	var tokens := line.split(" ", false)
	var i := 0
	while i < tokens.size():
		var token := tokens[i]
		if token == "." or token == "-":
			i += 1
			continue
		var length := 1
		while i + length < tokens.size() and tokens[i + length] == ".":
			length += 1
		var note := _midi(token)
		_add_tone(buffer, bar_start + i * step, int(step * length * 0.92), Wave.PULSE,
			_hz(note), _hz(note), 0.2, 0.3, rng)
		# Quiet echo an eighth later gives the lead some space.
		_add_tone(buffer, bar_start + (i + 1) * step, int(step * length * 0.8), Wave.PULSE,
			_hz(note), _hz(note), 0.05, 0.3, rng)
		i += length
		await _breathe()


func _render_drum_bar(buffer: PackedFloat32Array, bar_start: int, step: int, pattern: String, rng: RandomNumberGenerator) -> void:
	var hits := pattern.split(" ", false)
	for i in range(hits.size()):
		var at := bar_start + i * step
		match hits[i]:
			"k":
				_add_tone(buffer, at, int(0.12 * MIX_RATE), Wave.SINE, 150.0, 45.0, 0.55, 0.0, rng)
			"s":
				_add_tone(buffer, at, int(0.11 * MIX_RATE), Wave.NOISE, 5000.0, 2500.0, 0.22, 0.0, rng)
			"h":
				_add_tone(buffer, at, int(0.035 * MIX_RATE), Wave.NOISE, 9000.0, 9000.0, 0.09, 0.0, rng)


# Adds one tone into the buffer. sustain 0 = plain linear decay; above 0 = decay to that level then hold.
func _add_tone(
	buffer: PackedFloat32Array,
	offset: int,
	count: int,
	wave: Wave,
	start_hz: float,
	end_hz: float,
	volume: float,
	sustain: float,
	rng: RandomNumberGenerator
) -> void:
	if volume <= 0.0 or start_hz <= 0.0:
		return
	var attack := ATTACK_SECONDS * MIX_RATE
	var release := 0.02 * MIX_RATE
	var phase := 0.0
	var noise_value := 0.0
	var end := mini(count, buffer.size() - offset)

	for i in range(end):
		var progress := float(i) / count
		var frequency := lerpf(start_hz, end_hz, progress)
		var previous_phase := phase
		phase = fmod(phase + frequency / MIX_RATE, 1.0)
		if phase < previous_phase or i == 0:
			noise_value = rng.randf_range(-1.0, 1.0)

		var envelope: float
		if sustain <= 0.0:
			envelope = 1.0 - progress
		else:
			envelope = lerpf(1.0, sustain, minf(1.0, progress * 4.0))
			envelope *= minf(1.0, (count - i) / release)
		envelope *= minf(1.0, i / attack)

		buffer[offset + i] += _wave_value(wave, phase, noise_value) * envelope * volume


func _wave_value(wave: Wave, phase: float, noise_value: float) -> float:
	match wave:
		Wave.SQUARE:
			return 1.0 if phase < 0.5 else -1.0
		Wave.PULSE:
			return 1.0 if phase < 0.25 else -1.0
		Wave.TRIANGLE:
			return 4.0 * absf(phase - 0.5) - 1.0
		Wave.SINE:
			return sin(phase * TAU)
		_:
			return noise_value


func _to_stream(samples: PackedFloat32Array, looping: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	return _make_stream(data, samples.size(), looping)


# Same 16-bit conversion as _to_stream, sliced across frames for long music buffers.
func _encode(samples: PackedFloat32Array) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
		if i % 4096 == 0:
			await _breathe()
	return data


func _make_stream(data: PackedByteArray, sample_count: int, looping: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream


# "C5", "G#4" -> MIDI note number.
func _midi(token: String) -> int:
	var semitone: int = NOTE_INDEX[token[0]]
	var octave_text := token.substr(1)
	if octave_text.begins_with("#"):
		semitone += 1
		octave_text = octave_text.substr(1)
	return 12 * (int(octave_text) + 1) + semitone


func _hz(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)
