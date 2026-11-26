
class_name AudioManager
extends RefCounted

const SAMPLE_RATE: int = 22050

static var muted: bool = false
static var volume: float = 1.0
static var _streams: Dictionary = {}

# Pemanggilan utama. a bisa Node (self) atau String (nama SFX),
# b bisa String (nama SFX) atau Node. Kedua urutan diterima.
static func play_sfx(a = null, b = "") -> void:
	var caller: Node = null
	var sfx_name: String = "click"
	if a is Node:
		caller = a
		if b is String and b != "":
			sfx_name = b
	elif a is String:
		sfx_name = a
		if b is Node:
			caller = b
	if muted:
		return
	var stream: AudioStreamWAV = _get_stream(sfx_name)
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(clampf(volume, 0.01, 1.0))
	var parent: Node = caller
	if parent == null or not parent.is_inside_tree():
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null:
			parent = tree.root
	if parent == null:
		return
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

# Alias, kalau ada kode yang memanggil nama lain.
static func play(a = null, b = "") -> void:
	play_sfx(a, b)

static func play_sound(a = null, b = "") -> void:
	play_sfx(a, b)

static func play_click(caller: Node = null) -> void:
	play_sfx(caller, "click")

static func play_error(caller: Node = null) -> void:
	play_sfx(caller, "error")

static func set_muted(m: bool) -> void:
	muted = m

static func set_sfx_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)

static func set_master_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)

static func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)

# Tidak ada BGM di Phase 1 — sengaja no-op supaya tidak error kalau dipanggil.
static func set_music_volume(_v: float) -> void:
	pass

static func is_muted() -> bool:
	return muted

static func _get_stream(sfx_name: String) -> AudioStreamWAV:
	if _streams.has(sfx_name):
		return _streams[sfx_name]
	var stream: AudioStreamWAV = _build_stream(_notes_for(sfx_name))
	_streams[sfx_name] = stream
	return stream

# Tiap SFX = daftar [frekuensi Hz, durasi detik]. Frekuensi 0 = noise (bulldoze).
static func _notes_for(sfx_name: String) -> Array:
	match sfx_name:
		"click":
			return [[880.0, 0.06]]
		"build":
			return [[220.0, 0.08], [330.0, 0.10]]
		"bulldoze":
			return [[0.0, 0.18]]
		"harvest":
			return [[523.0, 0.09], [659.0, 0.09], [784.0, 0.12]]
		"sell":
			return [[988.0, 0.08], [1319.0, 0.14]]
		"level_up", "levelup", "naik_level":
			return [[523.0, 0.10], [659.0, 0.10], [784.0, 0.10], [1047.0, 0.18]]
		"error":
			return [[160.0, 0.20]]
		"complaint":
			return [[392.0, 0.12], [311.0, 0.18]]
		"toast", "notification", "pengaduan":
			return [[659.0, 0.10], [880.0, 0.12]]
		_:
			return [[660.0, 0.08]]

static func _build_stream(notes: Array) -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	for note in notes:
		var freq: float = float(note[0])
		var duration: float = float(note[1])
		var count: int = int(duration * float(SAMPLE_RATE))
		for i in range(count):
			var t: float = float(i) / float(SAMPLE_RATE)
			var value: float = 0.0
			if freq <= 0.0:
				value = randf() * 2.0 - 1.0
			else:
				value = sin(TAU * freq * t)
			# Envelope sederhana: fade-in 10 ms, fade-out 20 ms di akhir nada.
			var attack: float = clampf(t / 0.01, 0.0, 1.0)
			var release: float = clampf((duration - t) / 0.02, 0.0, 1.0)
			value *= attack * release * 0.6
			var byte_value: int = clampi(int(128.0 + 127.0 * value), 0, 255)
			bytes.append(byte_value)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
