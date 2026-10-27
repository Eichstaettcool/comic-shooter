# SoundManager.gd - Autoload: prozedural generierte Sounds (keine Dateien)
extends Node

const SAMPLE_RATE := 22050
var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []


# ============================================================
# Runde 49: MUSIK
# Zweigeteilt: das Menue hat einen ruhigen Loop, das Spiel einen
# schnellen. Beides prozedural (keine Dateien), wie die Effekte.
# ============================================================

var _music_player: AudioStreamPlayer = null
var _music_menu: AudioStreamPlayer = null
var _music_streams: Dictionary = {}
var music_on: bool = true
var _current_music: String = ""

# Die Looplaenge in Sekunden. Kurz genug, dass die Datei klein bleibt,
# lang genug, dass der Loop nicht als "wiederholt" auffaellt.
const MUSIC_BARS := 8
const MUSIC_BEAT := 0.25          # 1/4 Note bei 120 BPM
const MUSIC_LOOP_LEN := MUSIC_BARS * 4 * MUSIC_BEAT


func _ready() -> void:
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_pool.append(p)
	_build_streams()
	_build_music()


func _build_music() -> void:
	# Zwei Themes: MENU (ruhig, aeolisch) und GAME (Drums + Bass,
	# schneller). Beides als LOOP gesetzt, damit sie ohne Klick
	# weiterlaufen.
	_music_streams["menu"] = _gen_music_menu()
	_music_streams["game"] = _gen_music_game()
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -19.0
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_music_menu = AudioStreamPlayer.new()
	_music_menu.volume_db = -22.0
	_music_menu.finished.connect(_on_music_finished)
	add_child(_music_menu)


func _on_music_finished() -> void:
	# Der Stream ist als Loop gesetzt - das Signal kommt trotzdem.
	# Ein Neustart haelt die Musik am Leben.
	if _current_music == "game" and _music_player.stream != null:
		_music_player.play()
	elif _current_music == "menu" and _music_menu.stream != null:
		_music_menu.play()


func play_music(name: String) -> void:
	# Wechselt die Musik. "menu" laeuft im Menue, "game" im Spiel.
	# Ist der Sound generell aus, bleibt die Musik auch aus.
	if not music_on or not _music_streams.has(name):
		return
	if muted:
		# Stumm: die Auswahl merken, aber nicht abspielen. Wird der
		# Ton wieder eingeschaltet, startet die Musik dort.
		_current_music = name
		return
	if _current_music == name:
		return
	_current_music = name
	_music_player.stop()
	_music_menu.stop()
	if name == "game":
		_music_player.stream = _music_streams["game"]
		_music_player.play()
	else:
		_music_menu.stream = _music_streams["menu"]
		_music_menu.play()


func stop_music() -> void:
	_current_music = ""
	_music_player.stop()
	_music_menu.stop()


func set_music_enabled(on: bool) -> void:
	music_on = on
	if not on:
		stop_music()
	elif _current_music != "":
		var c: String = _current_music
		_current_music = ""
		play_music(c)


func _gen_music_menu() -> AudioStreamWAV:
	# Ruhiger Loop: eine langsame, traurige Akkordfolge mit einer
	# einfachen Melodie darueber (Am -> F -> G -> Em).
	var chords: Array = [
		[220.0, 261.6, 329.6],
		[174.6, 220.0, 261.6],
		[196.0, 246.9, 293.7],
		[164.8, 207.7, 246.9],
	]
	var melody: Array = [
		[659.3, 587.3, 523.3, 440.0],
		[523.3, 493.9, 440.0, 392.0],
		[493.9, 440.0, 392.0, 392.0],
		[440.0, 392.0, 349.2, 329.6],
	]
	var n := int(SAMPLE_RATE * MUSIC_LOOP_LEN)
	var data := PackedByteArray()
	data.resize(n * 2)
	var step_len := int(SAMPLE_RATE * MUSIC_BEAT)
	for i in range(n):
		var step: int = i / step_len
		var bar: int = step / 4
		var chord: Array = chords[bar % chords.size()]
		var t: float = float(i % step_len) / float(step_len)
		var s: float = 0.0
		# Pad (Akkord) - weich
		for f in chord:
			s += sin(TAU * float(f) * float(i) / float(SAMPLE_RATE)) * 0.22
		s /= float(chord.size())
		# Melodie - nur in der zweiten Haelfte jedes Takts
		var mel: Array = melody[bar % melody.size()]
		if step % 4 >= 2:
			var mf: float = mel[step % 4]
			var env: float = pow(1.0 - t, 2.0)
			s += sin(TAU * mf * float(i) / float(SAMPLE_RATE)) * 0.26 * env
			s += sin(TAU * mf * 2.0 * float(i) / float(SAMPLE_RATE)) * 0.07 * env
		# Sanftes Tremolo, damit es nicht statisch klingt
		s *= 0.88 + 0.12 * sin(TAU * 3.0 * float(i) / float(SAMPLE_RATE))
		# Weiche Saettigung am Anfang/Ende -> kein Klick
		var loop_env: float = 1.0
		var pos: float = float(i) / float(n)
		if pos < 0.02:
			loop_env = pos / 0.02
		elif pos > 0.98:
			loop_env = (1.0 - pos) / 0.02
		data.encode_s16(i * 2, int(clampf(s * loop_env * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_music_game() -> AudioStreamWAV:
	# Runde 61: Spielmusik im Stil des Startbildschirms. Statt Drums jetzt
	# dieselbe ruhige Akkordfolge (Am-F-G-Em) mit weichem Bass-Puls,
	# Arpeggio und Melodie darueber - nur etwas lebhafter als im Menue.
	var chords: Array = [
		[220.0, 261.6, 329.6],
		[174.6, 220.0, 261.6],
		[196.0, 246.9, 293.7],
		[164.8, 207.7, 246.9],
	]
	var melody: Array = [
		[659.3, 587.3, 523.3, 440.0],
		[523.3, 493.9, 440.0, 392.0],
		[493.9, 440.0, 392.0, 392.0],
		[440.0, 392.0, 349.2, 329.6],
	]
	var n := int(SAMPLE_RATE * MUSIC_LOOP_LEN)
	var data := PackedByteArray()
	data.resize(n * 2)
	var step_len := int(SAMPLE_RATE * MUSIC_BEAT)
	for i in range(n):
		var step: int = i / step_len
		var bar: int = step / 4
		var chord: Array = chords[bar % chords.size()]
		var t: float = float(i % step_len) / float(step_len)
		var s: float = 0.0
		# weiches Pad
		for f in chord:
			s += sin(TAU * float(f) * float(i) / float(SAMPLE_RATE)) * 0.20
		s /= float(chord.size())
		# sanfter Bass-Puls auf jedem Schlag (statt Kick)
		var bass_f: float = float(chord[0]) * 0.5
		s += sin(TAU * bass_f * float(i) / float(SAMPLE_RATE)) * 0.13 * pow(1.0 - t, 2.0)
		# Arpeggio ueber den Akkord, leise
		var arp_f: float = float(chord[(step * 2) % chord.size()]) * 2.0
		s += sin(TAU * arp_f * float(i) / float(SAMPLE_RATE)) * 0.055 * pow(1.0 - t, 2.4)
		# Melodie in der zweiten Takthaelfte
		var mel: Array = melody[bar % melody.size()]
		if step % 4 >= 2:
			var mf: float = mel[step % 4]
			var env: float = pow(1.0 - t, 1.9)
			s += sin(TAU * mf * float(i) / float(SAMPLE_RATE)) * 0.24 * env
			s += sin(TAU * mf * 2.0 * float(i) / float(SAMPLE_RATE)) * 0.05 * env
		# leichtes Tremolo wie im Menue
		s *= 0.90 + 0.10 * sin(TAU * 3.0 * float(i) / float(SAMPLE_RATE))
		# Loop-Rand weich
		var loop_env: float = 1.0
		var pos: float = float(i) / float(n)
		if pos < 0.02:
			loop_env = pos / 0.02
		elif pos > 0.98:
			loop_env = (1.0 - pos) / 0.02
		data.encode_s16(i * 2, int(clampf(s * loop_env * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


var muted: bool = false
var sfx_on: bool = true

func set_sfx_enabled(on: bool) -> void:
	# Runde 62: eigene Einstellung fuer Soundeffekte, unabhaengig von der Musik
	sfx_on = on
	if not on:
		for p in _pool:
			if p != null:
				p.stop()

func set_muted(m: bool) -> void:
	muted = m
	# Runde 49: Beim Stummschalten auch die Musik stoppen
	if muted:
		stop_music()
	elif music_on and _current_music != "":
		var c: String = _current_music
		_current_music = ""
		play_music(c)

func play(name: String) -> void:
	if muted or not sfx_on:
		return
	if not _streams.has(name):
		return
	for p in _pool:
		if not p.playing:
			p.stream = _streams[name]
			p.play()
			return
	# Alle belegt -> naechsten ueberschreiben
	_pool[0].stream = _streams[name]
	_pool[0].play()

func _build_streams():
	_streams["shoot"] = _gen_sweep(900.0, 200.0, 0.08, "square", 0.5)
	_streams["shotgun"] = _gen_noise(0.14, 0.6)
	_streams["machine"] = _gen_sweep(700.0, 400.0, 0.04, "square", 0.35)
	_streams["hit"] = _gen_sweep(300.0, 120.0, 0.07, "saw", 0.5)
	_streams["kill"] = _gen_sweep(500.0, 150.0, 0.12, "square", 0.5)
	_streams["pickup"] = _gen_sweep(500.0, 1100.0, 0.12, "sine", 0.6)
	_streams["hurt"] = _gen_sweep(200.0, 60.0, 0.25, "saw", 0.7)
	_streams["chest"] = _gen_sweep(150.0, 400.0, 0.3, "sine", 0.5)
	_streams["levelup"] = _gen_chord([523.0, 659.0, 784.0, 1046.0], 0.5)
	_streams["boss"] = _gen_sweep(90.0, 40.0, 0.8, "saw", 0.9)
	_streams["death"] = _gen_sweep(400.0, 50.0, 1.2, "square", 0.7)

func _gen_sweep(f0: float, f1: float, dur: float, type: String, vol: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(n)
		var freq := lerpf(f0, f1, t)
		phase += TAU * freq / float(SAMPLE_RATE)
		var s := 0.0
		match type:
			"sine":
				s = sin(phase)
			"square":
				s = 1.0 if sin(phase) >= 0.0 else -1.0
			"saw":
				s = 2.0 * fmod(phase / TAU, 1.0) - 1.0
		# Ausklingende Huellkuurve
		var env := pow(1.0 - t, 1.6)
		var sample := int(clampf(s * vol * env * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sample)
	return _make_wav(data)

func _gen_noise(dur: float, vol: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(n)
		var s := (randf() * 2.0 - 1.0) * pow(1.0 - t, 2.0) * vol
		data.encode_s16(i * 2, int(clampf(s * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)

func _gen_chord(freqs: Array, dur: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(n)
		var s := 0.0
		for f in freqs:
			s += sin(TAU * f * t * (1.0 + t * 0.5))
		s = s / float(freqs.size()) * pow(1.0 - t, 1.3) * 0.6
		data.encode_s16(i * 2, int(clampf(s * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	return wav
