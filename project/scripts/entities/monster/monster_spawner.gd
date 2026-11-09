# MonsterSpawner.gd - Spawnet Monster in Intervallen an zufälligen Positionen
extends Node2D

# ============================================================
# v1.56 (Spec A3/A4/B1/B2/C1) — ENDLOS laeuft als SAEGEZAHN
# ============================================================
# Der alte Spawner schuettete alle 30 s (dann alle 10 s) einen Haufen
# Zufallsgegner aus und setzte ab "Welle 3" JEDEN Schub einen Mini-Boss
# obendrauf. Genau das war der "sofort tot"-Effekt (P1/P3/P6).
#
# Jetzt gilt:
#   Anlauf   -> wenige, langsame Gegner (nur Laeufer)
#   Peak     -> Schuhe alle `fenster` s im Rollen-Mix der Stufe
#   Erholung -> KEIN Spawn, Restgegner 40 % langsamer, kein Fernkampf
#   Boss     -> 2 s Telegraph, dann NUR der Boss (adds=0), danach 6-8 s Ruhe
# Dazu: Schonfrist am Anfang, Hetzer-Limit, harte Gleichzeitig-Grenze und
# ein Rettungsanker (Level-Up + Heilung) bei niedriger HP.
const MonsterAiType = preload("res://scripts/monster_ai.gd")

var active: bool = false
var spawn_interval: float = 30.0
var time_since_last_spawn: float = 0.0
var game_manager: Node = null
var spawn_distance: float = 700.0
var min_interval: float = 10.0
var quality_mult: float = 1.0      # Grafikstufe: laengere Abstaende = weniger Last
var max_monsters: int = 140        # Grafikstufe: harte Obergrenze gleichzeitig

# --- v1.56 Zustand ---
var stufe: String = "normal"
var t: float = 0.0                  # Laufzeit seit dem Spawner-Start
var phase: String = "anlauf"
var phase_left: float = 0.0
var burst_t: float = 0.0
var druck: float = 0.0
var wave_no: int = 0                # nur noch Anzeige (45 s = 1 "Welle")
var _erholung_log_t: float = 0.0
var _slow_marked: Array = []
var _anker_t: float = 0.0
var _mini_naechste: float = 0.0
var _boss_naechste: float = 0.0
var _boss_art: String = ""          # "" | "mini" | "biom"
var _boss_telegraph: float = 0.0
var _boss_knoten: Node = null
var _boss_adds_log: bool = false
var _schon_log_t: float = -1.0
var _budget: float = 0.0            # kontinuierliches Spawn-Budget (Gegner)
var _pool_gemeldet: bool = false
var _fallback_gemeldet: bool = false
var _erster_schub: bool = false


func start_spawning(first_delay: float, interval: float, gm: Node) -> void:
	game_manager = gm
	spawn_interval = interval
	time_since_last_spawn = 0.0
	active = true
	t = 0.0
	wave_no = 0
	phase = "anlauf"
	burst_t = 0.0
	druck = 0.0
	_boss_knoten = null
	_boss_art = ""
	_boss_telegraph = 0.0
	_boss_adds_log = false
	_erholung_log_t = 0.0
	_budget = 0.0
	_anker_t = 0.0
	stufe = Balance.stufe_von_index(int(game_manager.get("difficulty")))
	phase_left = Balance.phase_laenge(stufe, "anlauf")
	_mini_naechste = float(Balance.data(stufe)["mini_ab"])
	_boss_naechste = float(Balance.data(stufe)["boss_ab"])
	# Belegzeile des alten Spawners bleibt (Golden-Referenz + Rueckwaertsvergleich)
	print("[SPAWN] start first_delay=%.1f interval=%.1f" % [first_delay, interval])
	print("[BAL][SPAWN] modus=endlos stufe=%s start=true schonfrist_gegner=%.0f schonfrist_hetzer=%.0f first_delay=%.1f" % [
		stufe, Balance.schonfrist_gegner(stufe), Balance.schonfrist_hetzer(stufe), first_delay])
	print(Balance.modell_zeile("endlos", stufe))


func stop_spawning() -> void:
	active = false
	print("[BAL][SPAWN] modus=endlos stop t=%.0f phase=%s" % [t, phase])


func _process(delta: float) -> void:
	if not active or game_manager == null:
		return
	t += delta
	wave_no = 1 + int(t / 45.0)
	_anker_tick(delta)

	# ---------- Boss-Telegraph ----------
	if _boss_telegraph > 0.0:
		_boss_telegraph -= delta
		if _boss_telegraph <= 0.0:
			_boss_telegraph = 0.0
			_spawn_boss_now()

	# ---------- Schonfrist: keine Gegner ----------
	if t < Balance.schonfrist_gegner(stufe):
		if _schon_log_t < 0.0:
			_schon_log_t = t
			print("[BAL][SCHONFRIST] modus=endlos t=%.1f gegner=0 dauer=%.0f art=start" % [
				t, Balance.schonfrist_gegner(stufe)])
		return
	# v1.56b (Bug 2): direkt nach der Schonfrist kommt ein erster Schub - vorher
	# lief der Anlauf leer und die ersten 20-30 s war nichts zu finden.
	if not _erster_schub:
		_erster_schub = true
		burst_t = 999.0
		print("[BAL][ANLAUF] modus=endlos t=%.1f erster_schub=true" % t)

	# ---------- Phasentakt ----------
	phase_left -= delta
	if phase_left <= 0.0:
		_next_phase()

	# ---------- Boss-Kadenz (ersetzt den 120-s-Timer) ----------
	if _boss_art == "" and not _boss_wartet():
		if t >= _mini_naechste:
			_mini_naechste += float(Balance.data(stufe)["mini_alle"])
			_boss_start("mini")
		elif t >= _boss_naechste:
			_boss_naechste += float(Balance.data(stufe)["boss_alle"])
			_boss_start("biom")

	# ---------- Laufender Boss: keine Adds (Spec K4) ----------
	if _boss_adds_log and not _boss_lebt():
		_boss_adds_log = false
		_boss_art = ""
		phase = "erholung"
		phase_left = Balance.erholung_nach_boss(stufe)
		print("[BAL][BOSS] modus=endlos besiegt=true adds=0 ruhe=%.1f" % phase_left)

	# ---------- Erholung: kein Spawn, Gegner langsam ----------
	if phase == "erholung":
		_slow_all(0.6)
		_erholung_log_t += delta
		if _erholung_log_t >= 1.0:
			_erholung_log_t = 0.0
			print("[BAL][ERHOLUNG] modus=endlos spawn=0 gegner_aktiv=%d dauer=%.1f" % [_count_aktiv(), phase_left])
		return
	_clear_slow()

	# ---------- Spawn ----------
	if _boss_wartet() or _boss_lebt():
		if not _boss_adds_log and _boss_lebt():
			_boss_adds_log = true
			print("[BAL][BOSS] modus=endlos art=%s phase=1 ersetzt_peak=true adds=0 (kein Wellen-Spawn waehrend des Kampfes)" % _boss_art)
		return
	if _count_aktiv() >= Balance.max_aktiv(stufe):
		return
	var f: float = Balance.fenster(stufe)
	burst_t += delta
	if phase == "anlauf":
		if burst_t >= f * 1.2:
			burst_t = 0.0
			_spawn_schub(3, "laeufer")
		return
	# Peak: kontinuierliches Budget statt "mindestens 1 Gegner je Fenster"
	var ziel: float = Balance.ziel_druck("endlos", stufe, t)
	var hpm: float = Balance.hp_mult(wave_no, stufe)
	var rate: float = Balance.rate_fuer_druck(ziel, hpm)
	_budget = minf(_budget + rate * delta, 12.0)
	if _budget >= 1.0:
		var n: int = int(floor(_budget))
		_budget -= float(n)
		n = mini(n, maxi(0, Balance.max_aktiv(stufe) - _count_aktiv()))
		if n > 0:
			druck = Balance.druck(float(n), hpm, maxf(0.1, float(n) / maxf(0.001, rate)))
			_spawn_schub(n, "")
	var log_t: float = float(int(t / 10) * 10)
	if log_t != float(int((t - delta) / 10) * 10):
		print("[BAL][MODELL] modus=endlos stufe=%s t=%.0f druck=%.2f ziel=%.2f abweichung=%+.2f hp=%.2f rate=%.2f/s budget=%.2f aktiv=%d" % [
			stufe, t, druck, ziel, druck - ziel, hpm, rate, _budget, _count_aktiv()])


# ============================================================
# Phasen
# ============================================================

func _next_phase() -> void:
	if _boss_lebt() or _boss_wartet():
		phase_left = Balance.phase_laenge(stufe, "peak")
		return
	var alt: String = phase
	phase = Balance.naechste_phase(alt)
	phase_left = Balance.phase_laenge(stufe, phase)
	print("[BAL][PHASE] modus=endlos art=%s dauer=%.1f druck=%.2f t=%.0f" % [phase, phase_left, druck, t])


func _boss_wartet() -> bool:
	return _boss_telegraph > 0.0


func _boss_lebt() -> bool:
	return _boss_knoten != null and is_instance_valid(_boss_knoten) and not _boss_knoten.is_queued_for_deletion() \
		and int(_boss_knoten.get("current_health")) > 0


func _boss_start(art: String) -> void:
	_boss_art = art
	_boss_telegraph = 2.0
	print("[BAL][BOSS] modus=endlos art=%s telegraph=2.0 ersetzt_peak=true adds=0 t=%.0f" % [art, t])


func _spawn_boss_now() -> void:
	var gm = game_manager
	if gm == null:
		return
	var btype: int = int(gm.call("_biome_boss_type")) if _boss_art == "biom" else int(gm.call("_mini_boss_type"))
	var center: Vector2 = gm.get_player_position()
	var pos: Vector2 = _pos_aussen(center, 520.0)
	var knoten = gm.spawn_monster_at(pos, btype)
	_boss_knoten = knoten
	if knoten != null:
		# v1.56 (K4): Boss-HP aus der Spielerleistung, nicht aus type_stats
		var riese: bool = (_boss_art == "biom")
		var hp_ziel: int = Balance.boss_hp(stufe, riese) if riese else Balance.mini_hp(stufe)
		knoten.set("max_health", hp_ziel)
		knoten.set("current_health", hp_ziel)
		knoten.set("start_hp", hp_ziel)
		if not riese:
			knoten.set("speed", Balance.mini_speed(stufe))
			knoten.set("damage_amount", 1)
		knoten.set_meta("bal_boss", true)
		knoten.set_meta("bal_phase", 1)
		gm.set("current_boss", knoten)
		gm.set("_boss_active", true)
		gm.set("_boss_last_type", str(knoten.get("type")))
		print("[BAL][BOSS] modus=endlos art=%s spawn=true hp=%d pos=(%.0f,%.0f) adds=0" % [
			_boss_art, int(knoten.get("start_hp")), pos.x, pos.y])
	else:
		print("[BAL][FEHLER] Boss konnte nicht erzeugt werden (art=%s typ=%d)" % [_boss_art, btype])


# ============================================================
# Rettungsanker (Spec K5): Level-Up + Heilung bei niedriger HP
# ============================================================

func _anker_tick(delta: float) -> void:
	_anker_t += delta
	var iv: float = Balance.anker_intervall(stufe)
	if _anker_t < iv:
		return
	var gm = game_manager
	var p = gm.get("player")
	if p == null or not is_instance_valid(p):
		return
	var hp: int = int(p.call("get_health"))
	var mx: int = int(p.call("get_max_health"))
	if mx <= 0:
		return
	if float(hp) / float(mx) < Balance.anker_schwelle(stufe):
		_anker_t = 0.0
		p.call("heal", 1)
		gm.set("pending_upgrades", int(gm.get("pending_upgrades")) + 1)
		print("[BAL][ANKER] art=levelup+heilung grund=hp_niedrig hp=%d/%d (%.0f%%) t=%.0f" % [
			hp, mx, 100.0 * float(hp) / float(mx), t])


# ============================================================
# Spawn mit Rollen-Mix + Hetzer-Limit
# ============================================================

func _spawn_schub(n: int, nur_rolle: String) -> void:
	var gm = game_manager
	var gewichte: Dictionary = Balance.mix_gewichte(stufe)
	var hetzer_aktiv: int = _count_hetzer()
	var aktiv: int = _count_aktiv()
	var gespawnt: int = 0
	var zaehler: Dictionary = { "laeufer": 0, "hetzer": 0, "anker": 0, "stoerer": 0 }
	var center: Vector2 = gm.get_player_position()
	for i in range(n):
		if aktiv + gespawnt >= Balance.max_aktiv(stufe) or get_tree().get_nodes_in_group("monsters").size() >= max_monsters:
			break
		var rolle: String = nur_rolle
		if rolle == "":
			rolle = Balance.rolle_waehlen(stufe, gewichte, hetzer_aktiv, aktiv + gespawnt)
		# Schonfrist fuer Hetzer (Spec K5: 60 s kein Hetzer)
		if rolle == "hetzer" and t < Balance.schonfrist_hetzer(stufe):
			rolle = "laeufer"
		if rolle == "hetzer" and hetzer_aktiv >= Balance.hetzer_max(aktiv + gespawnt, stufe):
			rolle = "laeufer"
		var typ: int = _typ_fuer_rolle(rolle)
		gm.spawn_monster_at(_pos_aussen(center, spawn_distance), typ)
		if rolle == "hetzer":
			hetzer_aktiv += 1
		gespawnt += 1
		zaehler[rolle] = int(zaehler[rolle]) + 1
	if gespawnt <= 0:
		return
	print("[BAL][MIX] modus=endlos rolle=hetzer anteil=%.2f aktiv_max=%d gespawnt=%d mix=%s t=%.0f" % [
		float(int(zaehler["hetzer"])) / float(gespawnt), Balance.hetzer_max(aktiv + gespawnt, stufe),
		gespawnt, "%d/%d/%d/%d" % [int(zaehler["laeufer"]), int(zaehler["hetzer"]), int(zaehler["anker"]), int(zaehler["stoerer"])], t])


func _pool() -> Array:
	# v1.56b (Bug 1): Der Pool der AKTIVEN Karte ist bindend (Mars/Jungle/Elektro
	# haben eigene Gegner). Vorher fiel der Spawner bei fehlender Rolle auf
	# GREEN zurueck - die Elektro-Welt spawnte dadurch nur Wiesen-Monster.
	var pool: Array = []
	if game_manager != null and game_manager.has_method("map_data"):
		pool = (game_manager.map_data().get("pool", []) as Array).duplicate()
	var welt_spezifisch: bool = not pool.is_empty()
	if not welt_spezifisch:
		pool = [0, 1, 2, 3, 4, 5, 6]
		var bio: String = str(game_manager.get("biome_id")) if game_manager != null else "meadow"
		match bio:
			"desert": pool = pool + [8]
			"ice": pool = pool + [9]
			"lava": pool = pool + [10]
	# Bosse/Mini-Bosse nie als normalen Gegner
	var gefiltert: Array = []
	for t in pool:
		if not Balance.ist_boss_typ(int(t)):
			gefiltert.append(int(t))
	if gefiltert.is_empty():
		gefiltert = [0, 1, 2]
	if welt_spezifisch and not _pool_gemeldet:
		_pool_gemeldet = true
		print("[BAL][POOL] karte=%s quelle=map pool=%s (nur Kartenmonster)" % [
			str(game_manager.get("active_map")), str(gefiltert)])
	return gefiltert


func _typ_fuer_rolle(rolle: String) -> int:
	var pool: Array = _pool()
	var kandidaten: Array = Balance.typen_fuer_rolle(rolle, pool)
	if kandidaten.is_empty():
		# Kein Typ dieser Rolle auf dieser Karte -> aus DEM POOL nehmen,
		# nicht auf GREEN ausweichen (das war der Elektro-Bug).
		var fallback: int = int(pool[randi() % pool.size()])
		if not _fallback_gemeldet:
			_fallback_gemeldet = true
			print("[BAL][POOL] rolle=%s kein_kandidat=true fallback=%s (aus Kartenpool)" % [
				rolle, Rounds.type_name(fallback)])
		return fallback
	return int(kandidaten[randi() % kandidaten.size()])


func _pos_aussen(center: Vector2, dist: float) -> Vector2:
	var wmax: float = float(game_manager.MAP_COLS * game_manager.TILE_SIZE) - 100.0
	var hmax: float = float(game_manager.MAP_ROWS * game_manager.TILE_SIZE) - 100.0
	var ang: float = randf_range(0.0, TAU)
	var pos: Vector2 = center + Vector2(cos(ang), sin(ang)) * dist
	pos.x = clampf(pos.x, 100.0, wmax)
	pos.y = clampf(pos.y, 100.0, hmax)
	return pos


func _count_aktiv() -> int:
	var n: int = 0
	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if m.get("ghost") == true:
			continue
		n += 1
	return n


func _count_hetzer() -> int:
	var n: int = 0
	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if m.get("ghost") == true:
			continue
		if Balance.rolle_von_type(int(m.get("type"))) == "hetzer":
			n += 1
	return n


func _slow_all(faktor: float) -> void:
	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if m.get("ghost") == true:
			continue
		if not m.has_meta("bal_speed_base"):
			var basis: float = float(m.get("speed"))
			m.set_meta("bal_speed_base", basis)
			m.set("speed", basis * faktor)
			m.set("shoot_timer", 6.0)
			_slow_marked.append(m)


func _clear_slow() -> void:
	if _slow_marked.is_empty():
		return
	for m in _slow_marked:
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.has_meta("bal_speed_base"):
			m.set("speed", float(m.get_meta("bal_speed_base")))
			m.remove_meta("bal_speed_base")
	_slow_marked.clear()
