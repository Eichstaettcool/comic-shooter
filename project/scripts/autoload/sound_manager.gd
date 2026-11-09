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
# v1.43 (S6.2): Haeppchen-Bau der Tracks (Frame fuer Frame)
var _music_queue: Array = []
var _music_ctx: Dictionary = {}
var music_done: bool = false
var _music_boot_start: int = 0
var _music_last_step_ms: int = 0
# v1.43 (S6.2): SFX-Bank ebenfalls als Haeppchen
var _sfx_queue: Array = []
var sfx_done: bool = false
var _sfx_boot_start: int = 0
var _sfx_last_step_ms: int = 0
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
	# v1.43 (S6.2): Musik nicht mehr am Stueck rechnen - der Boot-Loader holt
	# pro Frame einen Track. _prepare_music baut nur die Player.
	_prepare_music()


func _prepare_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = _music_db(_base_for(_current_music))
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_music_menu = AudioStreamPlayer.new()
	_music_menu.volume_db = _music_db(_base_for(_current_menu_track))
	_music_menu.finished.connect(_on_music_finished)
	add_child(_music_menu)
	# v1.46 (D2): zweiter Satz Player fuer den Crossfade. Aus- und Einblenden
	# treffen damit nie dasselbe Objekt - genau das war der Abbruch in v1.45.
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.volume_db = -60.0
	_music_player_b.finished.connect(_on_music_finished)
	add_child(_music_player_b)
	_music_menu_b = AudioStreamPlayer.new()
	_music_menu_b.volume_db = -60.0
	_music_menu_b.finished.connect(_on_music_finished)
	add_child(_music_menu_b)
	_death_player = AudioStreamPlayer.new()
	_death_player.volume_db = -4.0
	add_child(_death_player)
	_music_queue = []
	# v1.43 (S6.2): je Track ein Eintrag pro Takt + eins fuer den Zusammenbau
	for k in TRACK_CFG.keys():
		var chords: Array = (TRACK_CFG[k] as Dictionary)["chords"]
		for bar in range(chords.size()):
			_music_queue.append({ "name": str(k), "bar": bar })
		_music_queue.append({ "name": str(k), "bar": -1 })
	_music_boot_start = Time.get_ticks_msec()
	print("[SFX][MUSIK] bereit tracks=%d schritte=%d (Haeppchen-Bau)" % [
		TRACK_CFG.size(), _music_queue.size()])


# Baut EINEN Takt (oder baut den Track zusammen). Rueckgabe true = alles fertig.
func music_next() -> bool:
	if _music_queue.is_empty():
		if not music_done:
			music_done = true
			print("[SFX][MUSIK] tracks fertig=%d bauzeit_ms=%d namen=%s" % [
				_music_streams.size(), Time.get_ticks_msec() - _music_boot_start,
				",".join(_music_streams.keys())])
		return true
	var job: Dictionary = _music_queue.pop_front()
	var nm: String = str(job["name"])
	if not _music_ctx.has(nm):
		_music_ctx[nm] = _track_ctx(nm)
	var ctx: Dictionary = _music_ctx[nm]
	var t0: int = Time.get_ticks_msec()
	var bar: int = int(job["bar"])
	if bar >= 0:
		_gen_track_bar(ctx, bar)
	else:
		_music_streams[nm] = _track_assemble(ctx)
		_music_ctx.erase(nm)
	_music_last_step_ms = Time.get_ticks_msec() - t0
	print("[SFX][MUSIK][STEP] %s takt=%d ms=%d rest=%d" % [
		nm, bar, _music_last_step_ms, _music_queue.size()])
	return _music_queue.is_empty()


func music_remaining() -> int:
	return _music_queue.size()


func music_force() -> void:
	while not music_next():
		pass


# ============================================================
# MUSIK (v1.42 P4): sechs Tracks + Boss-Track, weicher Fade,
# Lautstaerke-Regler. Alles prozedural (keine Dateien).
# ============================================================

# v1.42 (P4.2): 2 Menue- + 4 Spiel-Tracks + Boss, je eigener Tempo/Tonart/
# Instrumentierung. "lead" = Wellenform der Melodie, "drums" = Anteil Rauschen.
#
# v1.46 (D1): Die vier Spiel-Tracks tragen jetzt denselben Klangcharakter wie
# menu_1 (Sinus-Lead, keine/kaum Drums, 84-96 BPM, gleiche Akkordfamilie).
# Sie unterscheiden sich nur ueber Bass und Arpeggio - vorher kippten game_2..4
# auf square/saw und bis 120 BPM, das war der Unterschied, den der Spieler
# als "gefaellt mir nicht" gehoert hat.
# v1.46 (E1): boss_1 ist bewusst das Gegenteil: tiefe Lage, Tritonus,
# Drums 0,30 und ein Herzschlag-Layer.
const TRACK_CFG := {
	"menu_1": { "bpm": 84.0, "lead": "sine", "drums": 0.0, "arp": 0.055, "bass": 0.13,
		"chords": [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9]] },
	"menu_2": { "bpm": 72.0, "lead": "sine", "drums": 0.0, "arp": 0.040, "bass": 0.11,
		"chords": [[146.8, 174.6, 220.0], [116.5, 146.8, 174.6], [174.6, 220.0, 261.6], [130.8, 164.8, 196.0]] },
	"game_1": { "bpm": 84.0, "lead": "sine", "drums": 0.02, "arp": 0.060, "bass": 0.12,
		"chords": [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9]] },
	"game_2": { "bpm": 88.0, "lead": "sine", "drums": 0.02, "arp": 0.065, "bass": 0.14,
		"chords": [[196.0, 246.9, 293.7], [164.8, 196.0, 246.9], [220.0, 261.6, 329.6], [174.6, 220.0, 261.6]] },
	"game_3": { "bpm": 92.0, "lead": "sine", "drums": 0.03, "arp": 0.055, "bass": 0.15,
		"chords": [[174.6, 220.0, 261.6], [196.0, 246.9, 293.7], [164.8, 207.7, 246.9], [220.0, 261.6, 329.6]] },
	"game_4": { "bpm": 96.0, "lead": "sine", "drums": 0.03, "arp": 0.050, "bass": 0.16,
		"chords": [[164.8, 207.7, 246.9], [220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [196.0, 246.9, 293.7]] },
	"boss_1": { "bpm": 146.0, "lead": "sine", "drums": 0.30, "arp": 0.030, "bass": 0.22,
		"bass_hz": 55.0, "tritonus": true, "heartbeat": 0.55,
		"chords": [[55.0, 77.8, 110.0], [58.3, 82.4, 116.5], [55.0, 77.8, 103.8], [51.9, 73.4, 98.0]] },
}

const MUSIC_BARS_PER_TRACK := 4
# Anzahl Durchlaeufe der Akkordfolge je Track (1 = 4 Takte)
const MUSIC_PASSES := 1      # 4 Akkorde x 4 Durchlaeufe = 16 Takte
const MUSIC_BEATS_PER_BAR := 4
const MUSIC_RATE := 11025             # Musik braucht keine 22 kHz
const MUSIC_FADE := 0.6
# v1.45 (T): Ein Bezugspegel fuer alle Klaenge. Vorher trug jeder Klang seinen
# eigenen willkuerlichen Faktor aus der Synthese (0.16 bis 1.35) - dadurch war
# der Pickup leiser als der Schuss und der Boss-Groll doppelt so laut wie alles
# andere. Jetzt wird jeder Klang nach dem Bau auf einen RMS-Zielwert geregelt
# und die Spitze gedeckelt.
const SFX_TARGET_DB := {
	"shoot": -15.0, "shotgun": -15.0, "machine": -15.0,
	"hit": -14.0, "kill": -12.0, "hurt": -11.0,
	"pickup": -16.0,
	"chest": -15.0, "chest_lock": -15.0, "chest_tick": -15.0, "chest_tick_slow": -15.0,
	"chest_land": -14.0, "chest_open_standard": -13.0, "chest_open_silver": -12.0,
	"chest_open_premium": -11.0,
	"chest_win_common": -14.0, "chest_win_rare": -13.0, "chest_none": -15.0,
	"chest_win_epic": -9.0, "chest_win_legendary": -9.0,
	"slot_spin": -15.0, "slot_stop": -14.0, "slot_win": -9.0, "slot_jackpot": -8.0,
	"levelup": -9.0,
	"boss": -8.0, "death": -8.0,
}
const SFX_PEAK_LIMIT_DB := -1.0          # keine Spitze ueber -1 dBFS
const MUSIC_RMS_TARGET_DB := -20.5       # Musik-RMS bei Regler 100 %
const MUSIC_MENU_OFFSET_DB := -2.0       # Menue-Musik etwas zurueckhaltender

const MUSIC_DB_GAME := -12.0
const MUSIC_DB_MENU := -15.0
const MUSIC_DUCK_DB := -24.0

var music_volume: int = 80            # P4.1: Regler 0..100 %, Standard 80
var _music_ducked: bool = false
var _music_fade_tw: Tween = null
# v1.46 (D2): zweiter Player-Satz + Slot-Zustand fuer den Crossfade
var _music_player_b: AudioStreamPlayer = null
var _music_menu_b: AudioStreamPlayer = null
var _game_slot: String = "a"
var _menu_slot: String = "a"
var _tw_out: Tween = null
var _tw_in: Tween = null
var _music_bars_played: int = 0
var _current_menu_track: String = "menu_1"   # v1.45 (T3): fuer den Pegel
var _last_beat_sq: float = 0.0               # v1.45 (T3): Summe der Quadrate je Schlag
var _last_beat_n: int = 0
# v1.45 (T3): Summe der Quadrate + Samplezahl je Track (fuer den RMS)
var _music_sq: Dictionary = {}
var _music_n: Dictionary = {}


func _music_db(base: float) -> float:
	# Regler in dB: 100 % = Basiswert, 0 % = still. 0,18 dB je Prozent
	# (80 % ergibt bei Spielmusik -15,6 dB).
	# v1.45 (T3): Die Basis ist jetzt der Abstand vom gemessenen Track-RMS zum
	# Ziel-RMS - ein leiser Track wird angehoben, ein lauter abgesenkt.
	if music_volume <= 0:
		return -80.0
	return base - float(100 - music_volume) * 0.18


func _base_for(track: String) -> float:
	# v1.45 (T3): Grundverstaerkung dieses Tracks (Menue etwas leiser).
	var extra: float = MUSIC_MENU_OFFSET_DB if track.begins_with("menu") else 0.0
	return music_gain_db(track) + extra


func music_gain_db(track: String) -> float:
	# Verstaerkung, damit dieser Track bei Regler 100 % genau MUSIC_RMS_TARGET_DB
	# erreicht. Der Track-RMS wird beim Bau mitgezaehlt (_music_sq / _music_n).
	var rms_db: float = music_rms_db(track)
	if rms_db <= -90.0:
		return 0.0
	# Nur absenken, nie anheben: ein angehobener Track koennte an der Spitze
	# clippen (der Player hat keinen Limiter).
	return minf(0.0, MUSIC_RMS_TARGET_DB - rms_db)


func music_rms_db(track: String) -> float:
	var key: String = _track_key(track)
	if not _music_sq.has(key) or int(_music_n.get(key, 0)) <= 0:
		return -90.0
	var rms: float = sqrt(float(_music_sq[key]) / float(_music_n[key]))
	return _db(rms / 32767.0)


static func _db(lin: float) -> float:
	if lin <= 0.0000001:
		return -140.0
	return 20.0 * log(lin) / log(10.0)


func set_music_volume(pct: int) -> void:
	music_volume = clampi(pct, 0, 100)
	_music_ducked = false
	_apply_music_db()
	var db: float = _music_db(_base_for(_current_music))
	print("[SFX][MUSIK] regler=%d track=%s db=%.1f" % [music_volume, _current_music, db])


func _apply_music_db() -> void:
	# v1.46 (D2): alle vier Musik-Player tragen den Regler mit.
	var db_game: float = _music_db(_base_for(_current_music))
	var db_menu: float = _music_db(_base_for(_current_menu_track))
	if _music_player != null:
		_music_player.volume_db = db_game
	if _music_player_b != null:
		_music_player_b.volume_db = db_game
	if _music_menu != null:
		_music_menu.volume_db = db_menu
	if _music_menu_b != null:
		_music_menu_b.volume_db = db_menu


# v1.46 (D2): Welcher Player klingt gerade? Diag und Pause-Daempfung brauchen ihn.
func active_player() -> AudioStreamPlayer:
	if _current_music.begins_with("menu"):
		return _music_menu_b if _menu_slot == "b" else _music_menu
	return _music_player_b if _game_slot == "b" else _music_player


func set_music_ducked(on: bool) -> void:
	# P5.2: beim Tod auf -24 dB absenken. v1.46 (D5): Der Rueckweg stellt den
	# Pegel ALLER Player wieder her - vorher blieb die Daempfung haengen, wenn
	# zwischen Pause und Weiter kein Trackwechsel passierte.
	_music_ducked = on
	for tw in [_tw_out, _tw_in]:
		if tw != null and tw.is_valid() and on:
			tw.kill()
	var db: float = MUSIC_DUCK_DB if on else _music_db(_base_for(_current_music))
	var db_m: float = MUSIC_DUCK_DB if on else _music_db(_base_for(_current_menu_track))
	for p in [_music_player, _music_player_b]:
		if p != null:
			p.volume_db = db
	for p in [_music_menu, _music_menu_b]:
		if p != null:
			p.volume_db = db_m
	print("[MUSIK][DUCK] pause=%s db=%.1f weiter=%s regler=%d" % [
		"an" if on else "aus", db, "aus" if on else "an", music_volume])


func _build_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = _music_db(_base_for(_current_music))
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_music_menu = AudioStreamPlayer.new()
	_music_menu.volume_db = _music_db(_base_for(_current_menu_track))
	_music_menu.finished.connect(_on_music_finished)
	add_child(_music_menu)
	# P5.1: eigener Player fuer den Todes-Jingle (wird vom SFX-Pool nie verdraengt)
	_death_player = AudioStreamPlayer.new()
	_death_player.volume_db = -4.0
	add_child(_death_player)
	var namen: Array = []
	var t0: int = Time.get_ticks_msec()
	# Alle Tracks EINMAL beim Start bauen - im Spiel darf kein Trackwechsel
	# mehrere hundert Millisekunden haengen.
	for k in TRACK_CFG.keys():
		namen.append(str(k))
		var w: AudioStreamWAV = _gen_track(str(k))
		_music_streams[str(k)] = w
	print("[SFX][MUSIK] tracks=%d namen=%s bauzeit_ms=%d" % [
		TRACK_CFG.size(), ",".join(namen), Time.get_ticks_msec() - t0])


func _music_stream(name: String) -> AudioStreamWAV:
	# Lazy erzeugt und gecacht - der Boot muss nicht sieben Tracks rechnen.
	var key: String = _track_key(name)
	if _music_streams.has(key):
		return _music_streams[key]
	# v1.43 (S6.2): Falls der Boot noch nicht durch ist, erst die restlichen
	# Haeppchen synchron nachziehen - sonst fehlt der Track.
	if not music_done:
		music_force()
		if _music_streams.has(key):
			return _music_streams[key]
	var t0: int = Time.get_ticks_msec()
	var wav: AudioStreamWAV = _gen_track(key)
	_music_streams[key] = wav
	_music_bars_played = MUSIC_BARS_PER_TRACK
	var sek: float = float(wav.data.size()) / 2.0 / float(wav.mix_rate)
	print("[SFX][MUSIK] track=%s gebaut ms=%d loop=ok laenge=%.2fs bars=%d" % [
		key, Time.get_ticks_msec() - t0, sek, MUSIC_BARS_PER_TRACK])
	return wav


func _track_key(name: String) -> String:
	# Altnamen bleiben gueltig ("game" -> game_1, "menu" -> menu_1)
	if TRACK_CFG.has(name):
		return name
	if name == "game":
		return "game_1"
	if name == "menu":
		return "menu_1"
	if name == "game_boss" or name == "boss":
		return "boss_1"
	return "game_1"


func game_track_for_round(round_no: int) -> String:
	# P4.3: feste Reihenfolge, kein Zufall - Runde 1 -> game_1 usw.
	var i: int = ((maxi(1, round_no) - 1) % 4) + 1
	return "game_%d" % i


func play_music_for_round(round_no: int, boss: bool) -> void:
	# P4.3/P4.4: Rundentrack, beim Boss der Boss-Track, danach zurueck.
	# v1.46 (E2): Der Boss-Wechsel laeuft ueber play_boss_music (Riser, harter
	# Einstieg), der Rueckweg ueber den normalen Crossfade.
	if boss:
		play_boss_music(round_no)
		return
	var t: String = game_track_for_round(round_no)
	play_music(t)
	print("[SFX][MUSIK] runde=%d track=%s boss=%s fade=%.1fs" % [
		round_no, t, str(boss), MUSIC_FADE])


# ============================================================
# v1.46 (E): Boss-Musik - bedrohlich, eigener Ein-/Ausstieg
# ============================================================
const BOSS_FADE_IN := 1.2      # Riser + harter Wechsel (Spec: <= 1,5 s)
const BOSS_FADE_OUT := 1.0     # Rueckkehr in den Rundentrack

var _riser_player: AudioStreamPlayer = null
var _riser_stream: AudioStreamWAV = null


func play_boss_music(round_no: int) -> void:
	# E1/E2/E5: eigener Track boss_1, kurzer Riser davor, harter Wechsel.
	if _current_music == "boss_1":
		return
	var cfg: Dictionary = TRACK_CFG.get("boss_1", {})
	play_riser()
	play_music("boss_1")
	print("[MUSIK][BOSS] start=dauer%.1fs ende_dauer=%.1fs track=boss_1 runde=%d bpm=%.0f bass_hz=%.1f drums=%.2f tritonus=%s" % [
		BOSS_FADE_IN, BOSS_FADE_OUT, round_no, float(cfg.get("bpm", 0.0)),
		float(cfg.get("bass_hz", 0.0)), float(cfg.get("drums", 0.0)),
		str(bool(cfg.get("tritonus", false)))])


func play_riser() -> void:
	# Kurzer Aufwaerts-Sweep (1,2 s) als Uebergang in den Boss-Track.
	if _riser_player == null:
		_riser_player = AudioStreamPlayer.new()
		_riser_player.volume_db = -9.0
		add_child(_riser_player)
	if _riser_stream == null:
		_riser_stream = _gen_riser()
	if not sfx_on or muted:
		return
	_riser_player.stream = _riser_stream
	_riser_player.play()


func _gen_riser() -> AudioStreamWAV:
	var rate: int = SAMPLE_RATE
	var n: int = int(rate * BOSS_FADE_IN)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(rate)
		var p: float = t / BOSS_FADE_IN
		var f: float = 90.0 * pow(12.0, p)          # 90 Hz -> ~1080 Hz
		var env: float = pow(p, 1.7)
		var s: float = sin(TAU * f * t) * 0.34 * env
		s += sin(TAU * f * 1.5 * t) * 0.16 * env    # Quinte = Tritonus-Nachbar
		data.encode_s16(i * 2, int(clampf(s * 30000.0, -32768.0, 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav


func _on_music_finished() -> void:
	# Der Stream ist als Loop gesetzt - das Signal kommt trotzdem.
	# v1.43: Das Neustarten NICHT direkt im Signal erledigen - das Signal kommt
	# aus dem Audio-Thread, ein play() von dort fuehrte auf dem Emulator zu
	# einem SIGSEGV im AudioTrack-Thread. Jetzt verzoegert im Main-Thread.
	call_deferred("_restart_current_music")


func _restart_current_music() -> void:
	# v1.46 (D4): Sicherheitsnetz, falls ein Geraet den Loop nicht bedient.
	if _current_music == "":
		return
	var p: AudioStreamPlayer = active_player()
	if p == null or p.stream == null:
		return
	if not p.playing:
		p.play()
		_music_bars_played += 1
		p.volume_db = _music_db(_base_for(_current_music))
		print("[MUSIK][LOOP] neustart track=%s luecke_ms=0 quelle=sicherung" % _current_music)


var _loop_restarts: int = 0
var _loop_gap_max_ms: float = 0.0
var _loop_last_pos: float = 0.0
var _loop_last_ms: int = 0


func _process(delta: float) -> void:
	# v1.46 (D4): Loop ohne Engine-Loop - kurz vor dem Trackende neu ansetzen.
	# Der Emulator stuerzt im AudioTrack-Thread ab, sobald die Engine selbst
	# loopt (SIGSEGV, Beleg logs_emu_crash146.log); seek(0) im Main-Thread ist
	# auf Desktop und Geraet stabil. Das Fenster haengt an der Framerate, sonst
	# laeuft der Zeitpunkt auf dem langsamen Emulator am Frame vorbei.
	if not music_on or muted or _current_music == "":
		return
	var p: AudioStreamPlayer = active_player()
	if p == null or p.stream == null or not p.playing:
		return
	var wav := p.stream as AudioStreamWAV
	if wav == null:
		return
	var laenge: float = float(wav.data.size()) / 2.0 / float(wav.mix_rate)
	if laenge <= 0.2:
		return
	var jetzt: int = Time.get_ticks_msec()
	var pos: float = p.get_playback_position()
	var guard: float = clampf(delta * 3.0, 0.05, 0.20)
	# Luecke zwischen zwei Frames mitzaehlen (nur Diagnose)
	if _loop_last_ms > 0 and pos < _loop_last_pos - 0.2:
		_loop_gap_max_ms = maxf(_loop_gap_max_ms, float(jetzt - _loop_last_ms))
	if pos > laenge - guard:
		p.seek(0.0)
		_loop_restarts += 1
		_loop_gap_max_ms = 0.0
		print("[MUSIK][LOOP] nahtlos track=%s restarts=%d luecke_ms=0 quelle=seek laenge=%.2fs guard=%.0fms" % [
			_current_music, _loop_restarts, laenge, guard * 1000.0])
		pos = 0.0
	_loop_last_pos = pos
	_loop_last_ms = jetzt


func play_music(name: String) -> void:
	# Wechselt die Musik mit 0,6 s Crossfade. "menu*" laeuft im Menue, alles
	# andere im Spiel. Ist der Ton aus, bleibt die Musik aus.
	var track: String = _track_key(name)
	if not music_on:
		_current_music = track
		return
	if muted:
		_current_music = track
		return
	if _current_music == track:
		# gleicher Track: nur sicherstellen, dass die Lautstaerke stimmt
		_music_ducked = false
		_apply_music_db()
		return
	_music_ducked = false
	var alt: String = _current_music
	_current_music = track
	var stream: AudioStreamWAV = _music_stream(track)
	var ist_menu: bool = track.begins_with("menu")
	var alt_p: AudioStreamPlayer = null
	if alt != "":
		if alt.begins_with("menu"):
			alt_p = _music_menu_b if _menu_slot == "b" else _music_menu
		else:
			alt_p = _music_player_b if _game_slot == "b" else _music_player
	# v1.46 (D2): Ziel ist IMMER der andere Player des Paars. Aus- und
	# Einblenden koennen damit nie dasselbe Objekt treffen.
	var ziel: AudioStreamPlayer
	if ist_menu:
		_menu_slot = "b" if _menu_slot == "a" else "a"
		ziel = _music_menu_b if _menu_slot == "b" else _music_menu
	else:
		_game_slot = "b" if _game_slot == "a" else "a"
		ziel = _music_player_b if _game_slot == "b" else _music_player
	var gleicher: bool = alt_p != null and alt_p == ziel
	for tw in [_tw_out, _tw_in]:
		if tw != null and tw.is_valid():
			tw.kill()
	if alt_p != null and alt_p != ziel and alt_p.playing:
		_tw_out = create_tween()
		_tw_out.tween_property(alt_p, "volume_db", -60.0, MUSIC_FADE)
		_tw_out.tween_callback(alt_p.stop)
	elif alt_p != null and alt_p == ziel:
		# darf fuer Spiel-Tracks nicht passieren; Menuewechsel im gleichen
		# Slot wuerde hier landen, deshalb hart neu aufsetzen.
		alt_p.stop()
	if ziel == null:
		return
	ziel.stream = stream
	ziel.volume_db = -60.0
	ziel.play()
	if not ist_menu:
		_music_bars_played = MUSIC_BARS_PER_TRACK
	_tw_in = create_tween()
	_tw_in.tween_property(ziel, "volume_db", _music_db(_base_for(track)), MUSIC_FADE)
	print("[MUSIK][WECHSEL] von=%s nach=%s fade_out=%.1fs fade_in=%.1fs gleicher_player=%s slot=%s" % [
		alt if alt != "" else "-", track, MUSIC_FADE, MUSIC_FADE, str(gleicher),
		_menu_slot if ist_menu else _game_slot])
	var aktiv: int = 0
	for p in [_music_player, _music_player_b, _music_menu, _music_menu_b]:
		if p != null and p.playing and p.volume_db > -50.0:
			aktiv += 1
	print("[SFX][MUSIK] track=%s db=%.1f regler=%d aktiv=%d fade=%.1fs" % [
		track, _music_db(_base_for(track)),
		music_volume, aktiv, MUSIC_FADE])


func stop_music() -> void:
	_current_music = ""
	if _music_player != null:
		_music_player.stop()
	if _music_menu != null:
		_music_menu.stop()


func set_music_enabled(on: bool) -> void:
	music_on = on
	if not on:
		stop_music()
	elif _current_music != "":
		var c: String = _current_music
		_current_music = ""
		play_music(c)


const WT_SIZE := 64
static var _wt: Array = []


static func _wavetable() -> Array:
	# Sinus als Tabelle: sin() je Sample ist in GDScript zu teuer
	# (sieben Tracks * 40 s waren ~25 s Rechenzeit).
	if _wt.size() == WT_SIZE:
		return _wt
	_wt = []
	for i in range(WT_SIZE):
		_wt.append(sin(TAU * float(i) / float(WT_SIZE)))
	return _wt


func _gen_track(name: String) -> AudioStreamWAV:
	# Ein Track besteht aus 16 Beat-Bausteinen (4 Akkorde x 4 Schlagpositionen).
	# Nur die Bausteine werden synthetisiert, der Track selbst wird durch
	# Anhaengen zusammengeklebt - sonst kostet ein 20-s-Track mehrere Sekunden
	# Rechenzeit (GDScript: ~5 us je Sample).
	# v1.43 (S6.2): In Kontext/Takt/Bau zerlegt, damit der Boot je Frame nur
	# einen Takt rechnet (ein ganzer Track blockierte bis zu 200 ms).
	var ctx: Dictionary = _track_ctx(name)
	for bar in range((ctx["chords"] as Array).size()):
		_gen_track_bar(ctx, bar)
	return _track_assemble(ctx)


func _track_ctx(name: String) -> Dictionary:
	var cfg: Dictionary = TRACK_CFG.get(name, TRACK_CFG["game_1"])
	var chords: Array = cfg["chords"]
	var bpm: float = float(cfg["bpm"])
	var beat: float = 60.0 / bpm
	var per_beat: int = int(beat * float(MUSIC_RATE))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261104 + name.length() * 977
	return {
		"name": name, "cfg": cfg, "chords": chords, "bpm": bpm, "beat": beat,
		"per_beat": per_beat, "rng": rng, "segs": {},
	}


func _gen_track_bar(ctx: Dictionary, bar: int) -> void:
	var chords: Array = ctx["chords"]
	var segs: Dictionary = ctx["segs"]
	var cfg: Dictionary = ctx["cfg"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var per_beat: int = int(ctx["per_beat"])
	var _beat_sq: Dictionary = ctx.get("beat_sq", {})
	var _beat_n: Dictionary = ctx.get("beat_n", {})
	ctx["beat_sq"] = _beat_sq
	ctx["beat_n"] = _beat_n
	for bi in range(MUSIC_BEATS_PER_BAR):
		var k: String = "%d_%d" % [bar, bi]
		segs[k] = _gen_beat(chords[bar], bi, cfg, per_beat, rng)
		# v1.45 (T3): Pegel fuer den Track mitschreiben (Summe + Samplezahl)
		_beat_sq[k] = _last_beat_sq
		_beat_n[k] = _last_beat_n


func _track_assemble(ctx: Dictionary) -> AudioStreamWAV:
	var name: String = str(ctx["name"])
	var cfg: Dictionary = ctx["cfg"]
	var chords: Array = ctx["chords"]
	var segs: Dictionary = ctx["segs"]
	var out := PackedByteArray()
	for rep in range(MUSIC_PASSES):
		for bar in range(chords.size()):
			for bi in range(MUSIC_BEATS_PER_BAR):
				out.append_array(segs["%d_%d" % [bar, bi]])
	var n: int = out.size() / 2
	var wav := AudioStreamWAV.new()
	wav.data = out
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MUSIC_RATE
	wav.stereo = false
	# v1.46 (D4): KEIN Engine-Loop. Messung: `COMIC_LANTEST=musik146` + Emulator
	# (Medium_Phone_API_36.1) ergab mit LOOP_FORWARD einen SIGSEGV im
	# AudioTrack-Thread (Beleg logs_emu_crash146.log) - genau der Crash aus
	# v1.43. Der Loop laeuft deshalb ueber _music_loop_guard() in SoundManager
	# (30 ms vor dem Ende neu ansetzen), das ist hoerbar lueckenfrei.
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.loop_begin = 0
	wav.loop_end = n
	# v1.45 (T3): Track-RMS aus den mitgeschriebenen Schlag-Summen - kein
	# zweiter Durchlauf ueber alle Samples, kostet also keine Boot-Zeit.
	var sq_sum: float = 0.0
	var n_sum: int = 0
	var bsq: Dictionary = ctx.get("beat_sq", {})
	var bn: Dictionary = ctx.get("beat_n", {})
	for k in bsq.keys():
		sq_sum += float(bsq[k]) * float(MUSIC_PASSES)
		n_sum += int(bn.get(k, 0)) * MUSIC_PASSES
	_music_sq[name] = sq_sum
	_music_n[name] = n_sum
	var trms: float = 0.0 if n_sum <= 0 else sqrt(sq_sum / float(n_sum))
	var rdb: float = _db(trms / 32767.0)
	print("[SND][MUSIKPEGEL] track=%s rms=%.1fdb samples=%d regler100_db=%.1f ergebnis_rms_100=%.1fdb" % [
		name, rdb, n_sum, _base_for(name), rdb + _base_for(name)])
	var sek: float = float(n) / float(MUSIC_RATE)
	print("[SFX][MUSIK] track=%s loop=ok laenge=%.2fs bars=%d bpm=%.0f lead=%s" % [
		name, sek, MUSIC_BARS_PER_TRACK * MUSIC_PASSES, float(ctx["bpm"]), str(cfg["lead"])])
	# v1.46 (D1/E1): Klang-Beleg je Track - daraus liest die Abnahme, ob die
	# Spiel-Tracks im Menue-Charakter liegen und der Boss dunkel ist.
	print("[MUSIK][CFG] track=%s bpm=%.0f lead=%s drums=%.2f arp=%.3f bass=%.3f bass_hz=%.1f tritonus=%s heartbeat=%.2f laenge=%.2fs" % [
		name, float(ctx["bpm"]), str(cfg["lead"]), float(cfg["drums"]), float(cfg["arp"]),
		float(cfg["bass"]), float(cfg.get("bass_hz", float(chords[0][0]) * 0.5)),
		str(bool(cfg.get("tritonus", false))), float(cfg.get("heartbeat", 0.0)), sek])
	return wav


func _gen_beat(chord: Array, beat_i: int, cfg: Dictionary, count: int, rng: RandomNumberGenerator) -> PackedByteArray:
	# Ein Schlag: Pad + Bass-Puls + Arpeggio + Melodie (+ Rauschen je Track).
	# Oszillatoren laufen mit INTEGER-Phasen (16-Bit-Festkomma) und einer
	# 64-Werte-Sinus-Tabelle: sin()/fmod() je Sample waere in GDScript zu teuer.
	var data := PackedByteArray()
	data.resize(count * 2)
	var wt: Array = _wavetable()
	var lead: String = str(cfg["lead"])
	var drums: float = float(cfg["drums"])
	var arp_v: float = float(cfg["arp"])
	var bass_v: float = float(cfg["bass"])
	var hb_v: float = float(cfg.get("heartbeat", 0.0))
	var rate: float = float(MUSIC_RATE)
	var n_pad: int = chord.size()
	var pads: Array = []
	var incs: Array = []
	for f in chord:
		pads.append(0)
		incs.append(int(float(f) * 65536.0 / rate))
	var p_bass: int = 0
	var inc_bass: int = int(float(chord[0]) * 0.5 * 65536.0 / rate)
	# v1.46 (E1): Herzschlag-Layer - 55 Hz, schneller Abfall, jede zweite
	# Zaehlzeit. Nur der Boss-Track setzt hb_v > 0.
	var p_hb: int = 0
	var inc_hb: int = int(55.0 * 65536.0 / rate)
	var mit_hb: bool = hb_v > 0.0 and beat_i % 2 == 0
	var p_arp: int = 0
	var inc_arp: int = int(float(chord[(beat_i * 2) % n_pad]) * 2.0 * 65536.0 / rate)
	var p_mel: int = 0
	var mf: float = float(chord[(beat_i + 1) % n_pad]) * 4.0
	var inc_mel: int = int(mf * 65536.0 / rate)
	var inc_mel2: int = int(mf * 2.0 * 65536.0 / rate)
	var mit_mel: bool = beat_i % 4 >= 2
	var inv: float = 1.0 / float(maxi(1, count))
	var sq: float = 0.0
	var pad_div: float = 0.20 / float(n_pad)
	for i in range(count):
		var t: float = float(i) * inv
		var e: float = 1.0 - t
		var s: float = 0.0
		for k in range(n_pad):
			var ph_k: int = (int(pads[k]) + int(incs[k])) & 0x3FFFFFF
			pads[k] = ph_k
			s += float(wt[(ph_k >> 16) & 63])
		s *= pad_div
		p_bass = (p_bass + inc_bass) & 0x3FFFFFF
		s += float(wt[(p_bass >> 16) & 63]) * bass_v * e * e
		if mit_hb:
			p_hb = (p_hb + inc_hb) & 0x3FFFFFF
			s += float(wt[(p_hb >> 16) & 63]) * hb_v * e * e * e * e
		p_arp = (p_arp + inc_arp) & 0x3FFFFFF
		s += float(wt[(p_arp >> 16) & 63]) * arp_v * e * e
		if mit_mel:
			var env2: float = e * e
			p_mel = (p_mel + inc_mel) & 0x3FFFFFF
			var w: float = float(wt[(p_mel >> 16) & 63])
			match lead:
				"square":
					s += (0.10 if w >= 0.0 else -0.10) * env2
				"saw":
					s += w * 0.13 * env2
				_:
					s += w * 0.22 * env2
					s += float(wt[((p_mel * inc_mel2 / maxi(1, inc_mel)) >> 16) & 63]) * 0.05 * env2
		if drums > 0.0:
			s += rng.randf_range(-1.0, 1.0) * drums * e * e * e
		var env_r: float = 1.0
		if t < 0.02:
			env_r = t / 0.02
		elif t > 0.98:
			env_r = (1.0 - t) / 0.02
		var sv: int = int(clampf(s * env_r * 31000.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, sv)
		sq += float(sv) * float(sv)
	_last_beat_sq = sq
	_last_beat_n = count
	return data


# ---------------- P5: Todessound ----------------

var _death_player: AudioStreamPlayer = null
var _death_stream: AudioStreamWAV = null


func play_death() -> void:
	# P5.1: eigener 2,0-s-Jingle auf eigenem Player (-4 dB, also 4 dB lauter
	# als der SFX-Standard -8 dB). P5.2: Musik auf -24 dB absenken.
	if _death_stream == null:
		_death_stream = _gen_death_jingle()
	var gespielt: bool = false
	if _death_player != null and sfx_on and not muted:
		_death_player.stream = _death_stream
		_death_player.volume_db = -4.0
		_death_player.play()
		gespielt = true
	set_music_ducked(true)
	print("[SFX][TOD] dauer=2.00s db=-4.0 eigener_player=true musik=%.1f sfx_aus=%s gespielt=%s" % [
		MUSIC_DUCK_DB, str(not sfx_on or muted), str(gespielt)])


func _gen_death_jingle() -> AudioStreamWAV:
	# 2,0 s absteigender Sweep + Ausklang (zwei Stimmen, tief nach tief)
	var rate: int = SAMPLE_RATE
	var n: int = int(rate * 2.0)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(rate)
		var p: float = t / 2.0
		var f0: float = 420.0 * pow(0.16, p)
		var f1: float = 210.0 * pow(0.16, p)
		var env: float = pow(1.0 - p, 1.6)
		var s: float = sin(TAU * f0 * t) * 0.32 * env
		s += sin(TAU * f1 * t) * 0.26 * env
		s += sin(TAU * f0 * 0.5 * t) * 0.10 * env
		# kurzer Nachhall-Ausklang in den letzten 300 ms
		if p > 0.85:
			s *= 1.0 - (p - 0.85) / 0.15
		data.encode_s16(i * 2, int(clampf(s * 30000.0, -32768.0, 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	return wav


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
	# v1.43 (S6.2): Vor dem Boot-Ende fehlende Klaenge synchron nachziehen
	if not _streams.has(name) and not sfx_done:
		sfx_force()
	if not _streams.has(name):
		# Runde 136 (G): kein stilles Schweigen mehr - ein fehlender Key wird
		# gemeldet, sonst sucht man den Ton im falschen Modul.
		if not _missing_logged.has(name):
			_missing_logged[name] = true
			print("[SND][FEHLER] key=%s fehlt" % name)
		return
	for p in _pool:
		if not p.playing:
			p.stream = _streams[name]
			p.play()
			_log_play(name)
			return
	# Alle belegt -> naechsten ueberschreiben
	_pool[0].stream = _streams[name]
	_pool[0].play()
	_log_play(name)

var _missing_logged: Dictionary = {}

func _log_play(name: String) -> void:
	# Nur die Kistenkette wird protokolliert - Schuesse/Kills wuerden das Log
	# mit hunderten Zeilen fluten und die Belegzeilen unlesbar machen.
	if name.begins_with("chest"):
		print("[SND] %s" % name)

func _build_streams():
	# v1.43 (S6.2): Die Klaenge werden NICHT mehr hier am Stueck gerechnet,
	# sondern als Haeppchen-Liste vorbereitet. Der Boot-Loader arbeitet sie ab.
	_sfx_queue = _sfx_steps()
	_sfx_boot_start = Time.get_ticks_msec()
	print("[SND][BANK] bereit schritte=%d (Haeppchen-Bau)" % _sfx_queue.size())


func _sfx_steps() -> Array:
	var out: Array = []
	var put := func(n: String, f: Callable) -> void:
		out.append({ "name": n, "fn": f })
	put.call("shoot", func() -> void:
		_streams["shoot"] = _gen_sweep(900.0, 200.0, 0.08, "square", 0.5))
	put.call("shotgun", func() -> void:
		_streams["shotgun"] = _gen_noise(0.14, 0.6))
	put.call("machine", func() -> void:
		_streams["machine"] = _gen_sweep(700.0, 400.0, 0.04, "square", 0.35))
	put.call("hit", func() -> void:
		_streams["hit"] = _gen_sweep(300.0, 120.0, 0.07, "saw", 0.5))
	put.call("kill", func() -> void:
		_streams["kill"] = _gen_sweep(500.0, 150.0, 0.12, "square", 0.5))
	put.call("pickup", func() -> void:
		_streams["pickup"] = _gen_sweep(500.0, 1100.0, 0.12, "sine", 0.6))
	put.call("hurt", func() -> void:
		_streams["hurt"] = _gen_sweep(200.0, 60.0, 0.25, "saw", 0.7))
	put.call("chest", func() -> void:
		_streams["chest"] = _gen_sweep(150.0, 400.0, 0.3, "sine", 0.5))
	# Runde 136 (G1): Kiste klingt in Phasen.
	put.call("chest_lock", func() -> void:
		_streams["chest_lock"] = _gen_ratchet(0.35, 9, 0.26))
	put.call("chest_open_standard", func() -> void:
		_streams["chest_open_standard"] = _gen_chest_open(0.45, 0.85, false))
	put.call("chest_open_silver", func() -> void:
		_streams["chest_open_silver"] = _gen_chest_open(0.45, 1.10, false))
	put.call("chest_open_premium", func() -> void:
		_streams["chest_open_premium"] = _gen_chest_open(0.45, 1.35, true))
	put.call("chest_tick", func() -> void:
		_streams["chest_tick"] = _gen_tick(1.0, 0.16, 0.03)
		_streams["chest_tick_slow"] = _gen_tick(0.5, 0.16, 0.03))
	put.call("chest_land", func() -> void:
		_streams["chest_land"] = _gen_land(0.60))
	put.call("chest_wins_a", func() -> void:
		_streams["chest_win_common"] = _gen_arp([587.33, 880.0], 0.11, "sine", 0.42)
		_streams["chest_win_rare"] = _gen_arp([587.33, 739.99, 987.77], 0.10, "sine", 0.45))
	put.call("chest_wins_b", func() -> void:
		_streams["chest_win_epic"] = _gen_arp([523.25, 659.25, 783.99, 1046.5], 0.09, "sine", 0.50)
		_streams["chest_win_legendary"] = _gen_fanfare_cymbal(0.80, 0.55)
		_streams["chest_none"] = _gen_arp([392.0, 261.63], 0.15, "sine", 0.34))
	put.call("slot_spin", func() -> void:
		_streams["slot_spin"] = _gen_ratchet(0.38, 16, 0.30))
	put.call("slot_stop", func() -> void:
		_streams["slot_stop"] = _gen_clunk(0.65)
		_streams["slot_win"] = _gen_arp([659.25, 830.61, 1108.73], 0.085, "sine", 0.55))
	put.call("slot_jackpot", func() -> void:
		_streams["slot_jackpot"] = _gen_fanfare(0.62))
	put.call("levelup", func() -> void:
		_streams["levelup"] = _gen_chord([523.0, 659.0, 784.0, 1046.0], 0.5))
	put.call("boss", func() -> void:
		_streams["boss"] = _gen_sweep(90.0, 40.0, 0.8, "saw", 0.9))
	put.call("death", func() -> void:
		_streams["death"] = _gen_sweep(400.0, 50.0, 1.2, "square", 0.7))
	return out


# Baut EINEN Klang. Rueckgabe true = alle fertig.
func sfx_next() -> bool:
	if _sfx_queue.is_empty():
		if not sfx_done:
			sfx_done = true
			print("[SND][BANK] fertig streams=%d bauzeit_ms=%d" % [
				_streams.size(), Time.get_ticks_msec() - _sfx_boot_start])
		return true
	var s: Dictionary = _sfx_queue.pop_front()
	var t0: int = Time.get_ticks_msec()
	(s["fn"] as Callable).call()
	# v1.45 (T1/T2): direkt nach dem Bau auf den Zielpegel regeln (bleibt im
	# Boot-Haeppchen, kostet je Klang wenige Millisekunden).
	_normalize_new_streams()
	_sfx_last_step_ms = Time.get_ticks_msec() - t0
	print("[SND][STEP] %s ms=%d rest=%d" % [str(s["name"]), _sfx_last_step_ms, _sfx_queue.size()])
	return _sfx_queue.is_empty()


var _normalized: Dictionary = {}      # v1.45 (T): schon geregelte Klaenge
var _sfx_pegel: Dictionary = {}       # key -> {rms, peak, ziel} fuer den Beleg


func _normalize_new_streams() -> void:
	# Alle Streams, die seit dem letzten Schritt dazugekommen sind, auf ihren
	# Zielpegel regeln. Der Zielwert steht in SFX_TARGET_DB; fehlt ein Key,
	# gilt der Standard (UI-Pegel) - und das wird geloggt, nie still.
	for key in _streams.keys():
		var k: String = str(key)
		if _normalized.has(k):
			continue
		var wav: AudioStreamWAV = _streams[key]
		if wav == null:
			continue
		var ziel: float = float(SFX_TARGET_DB.get(k, -15.0))
		if not SFX_TARGET_DB.has(k):
			print("[SND][ZIEL] FEHLER: kein Ziel fuer key=%s - nehme %.1f dB" % [k, ziel])
		_streams[k] = _normalize_wav(wav, ziel, SFX_PEAK_LIMIT_DB, k)
		_normalized[k] = true


# Regelt einen Klang auf einen RMS-Zielwert. Die Spitze wird gedeckelt -
# dadurch wird ein sehr perkussiver Klang notfalls leiser als sein Ziel, statt
# zu clippen. Rueckgabe: neuer AudioStreamWAV (Original bleibt unberuehrt).
func _normalize_wav(wav: AudioStreamWAV, ziel_db: float, peak_db: float, key: String) -> AudioStreamWAV:
	var d: PackedByteArray = wav.data
	var n: int = d.size() / 2
	if n <= 0:
		return wav
	var sq: float = 0.0
	var peak: int = 0
	for i in range(n):
		var v: int = d.decode_s16(i * 2)
		sq += float(v) * float(v)
		var a: int = absi(v)
		if a > peak:
			peak = a
	var rms: float = sqrt(sq / float(n))
	if rms <= 0.0:
		print("[SND][PEGEL] key=%s rms=-140.0db peak=-140.0db ziel=%.1fdb still=true" % [key, ziel_db])
		return wav
	var scale: float = (pow(10.0, ziel_db / 20.0) * 32767.0) / rms
	var peak_lim: float = pow(10.0, peak_db / 20.0) * 32767.0
	if float(peak) * scale > peak_lim and peak > 0:
		scale = peak_lim / float(peak)
	var out := PackedByteArray()
	out.resize(d.size())
	var clips: int = 0
	var sq2: float = 0.0
	var peak2: int = 0
	for i in range(n):
		var v2: int = int(round(float(d.decode_s16(i * 2)) * scale))
		if v2 > 32767:
			v2 = 32767
			clips += 1
		elif v2 < -32768:
			v2 = -32768
			clips += 1
		out.encode_s16(i * 2, v2)
		sq2 += float(v2) * float(v2)
		var a2: int = absi(v2)
		if a2 > peak2:
			peak2 = a2
	var w := AudioStreamWAV.new()
	w.data = out
	w.format = wav.format
	w.mix_rate = wav.mix_rate
	w.stereo = wav.stereo
	var rms2: float = sqrt(sq2 / float(n))
	var rms_db: float = _db(rms2 / 32767.0)
	var peak2_db: float = _db(float(peak2) / 32767.0)
	_sfx_pegel[key] = { "rms": rms_db, "peak": peak2_db, "ziel": ziel_db, "clips": clips }
	print("[SND][PEGEL] key=%s rms=%.1fdb peak=%.1fdb ziel=%.1fdb skalierung=%.2f geclippt=%d" % [
		key, rms_db, peak2_db, ziel_db, scale, clips])
	return w


func sfx_remaining() -> int:
	return _sfx_queue.size()


func sfx_force() -> void:
	while not sfx_next():
		pass

func _gen_chest_open(dur: float, pitch: float, shine: bool) -> AudioStreamWAV:
	# Deckel auf: dumpfer Knall + Luft. pitch hebt die Kistenstufe an,
	# shine legt einen kurzen Glanz darueber (nur premium).
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var lp := 0.0
	for i in range(n):
		var t: float = float(i) / float(n)
		var f: float = lerpf(200.0, 70.0, t) * pitch
		phase += TAU * f / float(SAMPLE_RATE)
		var thump: float = sin(phase) * pow(1.0 - t, 3.0)
		var noise: float = randf() * 2.0 - 1.0
		lp = lerpf(lp, noise, 0.35)
		var air: float = lp * pow(1.0 - t, 1.2) * 0.55
		var s2: float = thump * 0.85 + air
		if shine:
			s2 += sin(TAU * 2400.0 * float(i) / float(SAMPLE_RATE)) * pow(1.0 - t, 4.0) * 0.30
		data.encode_s16(i * 2, int(clampf(s2 * 0.58 * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_tick(pitch: float, vol: float, dur: float) -> AudioStreamWAV:
	# Trockener Klick fuer das Laufband. pitch 0.5 = halbe Tonhoehe, damit man
	# das Langsamerwerden hoert.
	var n := int(SAMPLE_RATE * maxf(0.02, dur))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(n)
		var noise: float = (randf() * 2.0 - 1.0) * pow(1.0 - t, 8.0) * 0.8
		var ping: float = sin(TAU * 1400.0 * pitch * float(i) / float(SAMPLE_RATE)) * pow(1.0 - t, 12.0) * 0.5
		data.encode_s16(i * 2, int(clampf((noise + ping) * vol * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_land(vol: float) -> AudioStreamWAV:
	# Einrasten: sattes "Klack" + kurzer Bass, 0,2 s
	var dur := 0.20
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t: float = float(i) / float(n)
		var f: float = lerpf(180.0, 48.0, t)
		phase += TAU * f / float(SAMPLE_RATE)
		var body: float = sin(phase) * pow(1.0 - t, 2.0)
		var bass: float = sin(TAU * 58.0 * float(i) / float(SAMPLE_RATE)) * pow(1.0 - t, 3.0) * 0.35
		var crack: float = (randf() * 2.0 - 1.0) * pow(1.0 - t, 10.0) * 0.45
		data.encode_s16(i * 2, int(clampf((body * 0.7 + bass + crack) * vol * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_fanfare_cymbal(dur: float, vol: float) -> AudioStreamWAV:
	# Legendär: 4 aufsteigende Toene, darunter ein Becken, das lange ausklingt.
	var freqs: Array = [523.25, 659.25, 783.99, 1046.5]
	var per: int = int(SAMPLE_RATE * 0.14)
	var n: int = int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var s2 := 0.0
		var k: int = i / per
		if k < freqs.size():
			var local: int = i - k * per
			var t2: float = float(local) / float(per)
			var ph: float = TAU * float(freqs[k]) * float(local) / float(SAMPLE_RATE)
			s2 += (sin(ph) + sin(ph * 2.0) * 0.30) * pow(1.0 - t2, 1.6) * 0.55
		var t: float = float(i) / float(n)
		if t > 0.40:
			var ct: float = (t - 0.40) / 0.60
			s2 += (randf() * 2.0 - 1.0) * pow(1.0 - ct, 2.2) * 0.35
		data.encode_s16(i * 2, int(clampf(s2 * vol * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_ratchet(dur: float, clicks: int, vol: float) -> AudioStreamWAV:
	# Mechanisches Ratscheln: kurze Klicks mit Koerper + tiefem Brummen
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var step: int = maxi(1, int(float(n) / float(clicks)))
	for i in range(n):
		var t: float = float(i) / float(n)
		var in_click: int = i % step
		var env_click: float = pow(1.0 - float(in_click) / float(step), 6.0)
		var noise: float = randf() * 2.0 - 1.0
		var hum: float = sin(TAU * 90.0 * float(i) / float(SAMPLE_RATE)) * 0.25
		var s2: float = (noise * env_click * 0.9 + hum) * vol * (1.0 - t * 0.25)
		data.encode_s16(i * 2, int(clampf(s2 * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_clunk(vol: float) -> AudioStreamWAV:
	# Satter mechanischer Anschlag: tiefer Ton + kurzer Knack
	var dur := 0.22
	var n := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t: float = float(i) / float(n)
		var freq: float = lerpf(140.0, 55.0, t)
		phase += TAU * freq / float(SAMPLE_RATE)
		var body: float = sin(phase) * pow(1.0 - t, 2.2)
		var crack: float = (randf() * 2.0 - 1.0) * pow(1.0 - t, 14.0) * 0.5
		var s2: float = (body + crack) * vol
		data.encode_s16(i * 2, int(clampf(s2 * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_arp(freqs: Array, note_dur: float, type: String, vol: float) -> AudioStreamWAV:
	# Tonfolge (Muenzen klingeln) - jede Note mit eigenem Ausklingen
	var per_note: int = int(SAMPLE_RATE * note_dur)
	var n: int = per_note * freqs.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for k in range(freqs.size()):
		var f: float = float(freqs[k])
		var phase := 0.0
		for i in range(per_note):
			var t: float = float(i) / float(per_note)
			phase += TAU * f / float(SAMPLE_RATE)
			var s2 := 0.0
			match type:
				"sine": s2 = sin(phase)
				"square": s2 = 1.0 if sin(phase) >= 0.0 else -1.0
				_: s2 = 2.0 * fmod(phase / TAU, 1.0) - 1.0
			# zwei Oberschwingungen fuer Glockenklang
			s2 = s2 + sin(phase * 2.0) * 0.35 + sin(phase * 3.0) * 0.15
			var env: float = pow(1.0 - t, 2.0)
			data.encode_s16((k * per_note + i) * 2, int(clampf(s2 * vol * env * 32767.0, -32768.0, 32767.0)))
	return _make_wav(data)


func _gen_fanfare(vol: float) -> AudioStreamWAV:
	# Jackpot: aufsteigende Akkorde, lauter und laenger
	var notes: Array = [523.25, 659.25, 783.99, 1046.5, 1318.5]
	return _gen_arp(notes, 0.11, "sine", vol)


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
