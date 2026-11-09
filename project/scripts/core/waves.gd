class_name WavesModule
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
#
# v1.56 (Spec A2/A3/A4/B1/B2): WAVE_BALANCE ist WEG. Alle Zahlen kommen aus
# Balance (core/balance.gd). Die Welle laeuft jetzt als SAEGEZAHN:
#   Anlauf  -> erster Schub, Rest gestaffelt
#   Peak    -> Schuhe alle `fenster` s, Rollen-Mix, Hetzer-Limit
#   Erholung-> KEIN Spawn, Restgegner langsam, kein Fernkampf
# Boss-Wellen: der Boss ERSETZT den Wellen-Spawn (keine Adds, P3), 2 s
# Telegraph vorher, danach garantiert ein Erholungsfenster.
var host: Node = null

var phase: String = "anlauf"
var phase_left: float = 0.0
var stage_pending: int = 0          # Gegner, die noch nicht gespawnt sind
var burst_t: float = 0.0
var wave_boss: bool = false
var boss_telegraph: float = 0.0
var boss_typ: int = -1
var boss_ist_riese: bool = false
var erholung_dauer: float = 0.0
var wave_druck: float = 0.0
var _slow_marked: Array = []


func _stufe() -> String:
	return Balance.stufe_von_index(int(host.difficulty))


# ============================================================
# Wellenwerte (Adapter auf Balance - eine Zahlenquelle)
# ============================================================

func wave_balance() -> Dictionary:
	var st: String = _stufe()
	var d: Dictionary = Balance.data(st)
	var hp: float = Balance.hp_mult(int(host.wave), st)
	var ziel: float = Balance.ziel_druck("wellen", st, float(host.wave) * 40.0)
	var roh: int = Balance.anzahl_fuer_druck(ziel, hp, 10.0)
	var count: int = clampi(int(round(float(roh) * float(d["wellen_anzahl"]))), 5, 44)
	return { "count": count, "hp": hp, "spd": Balance.spd_mult(int(host.wave)) }


# ============================================================
# Start einer Welle
# ============================================================

func _start_wave() -> void:
	# Sicherheitsnetz: eine bereits laufende Welle nicht erneut starten
	if host.wave_active:
		return
	host.wave += 1
	host.wave_active = true
	host.in_shop = false
	host.wave_remaining = 0
	host.wave_start_level = host.level          # Runde 33: Level-Aufstiege dieser Welle zaehlen
	host.shop_ready.clear()
	host._shop_delay_active = false
	host._shop_coins_start = int(host.coins)
	host.slot_coins[host.my_slot] = host.coins
	host.ui_manager.hide_shop()
	var st: String = _stufe()
	var bal: Dictionary = wave_balance()
	var count: int = int(bal["count"])
	var center: Vector2 = _center()

	# --- Boss-Welle? Dann ERSETZT der Boss den Wellen-Spawn (P3) ---
	wave_boss = Balance.boss_welle(int(host.wave))
	boss_telegraph = 0.0
	boss_typ = -1
	stage_pending = 0
	burst_t = 0.0
	_clear_slow()
	if wave_boss:
		boss_ist_riese = Balance.riesen_welle(int(host.wave))
		boss_typ = host._biome_boss_type() if boss_ist_riese else host._mini_boss_type()
		boss_telegraph = 2.0
		phase = "boss"
		host.wave_remaining = 1        # der Boss zaehlt fuer die Welle
		phase_left = Balance.phase_laenge(st, "boss")
		wave_druck = Balance.druck(float(count), float(bal["hp"]), 10.0)
		print("[BAL][BOSS] modus=wellen welle=%d art=%s phase=1 ersetzt_peak=true adds=0 telegraph=2.0 typ=%d" % [
			int(host.wave), ("biom" if boss_ist_riese else "mini"), boss_typ])
		host.ui_manager.show_boss_warning(int(host.wave) / 5)
		if boss_ist_riese:
			host.ui_manager.show_banner("%s ERSCHEINT!" % host._biome_boss_name(), Color(1.0, 0.45, 0.75))
		host._bdiag("TELEGRAPH", "2.0 s Vorwarnung vor dem Boss-Spawn (Welle %d)" % int(host.wave))
	else:
		# Anlauf: erster Schub = 40 % der Welle, Rest gestaffelt im Peak
		var anlauf_n: int = maxi(2, int(ceil(float(count) * 0.40)))
		stage_pending = maxi(0, count - anlauf_n)
		phase = "anlauf"
		phase_left = Balance.phase_laenge(st, "anlauf")
		wave_druck = Balance.druck(float(count), float(bal["hp"]),
			maxf(1.0, Balance.phase_laenge(st, "anlauf") + Balance.phase_laenge(st, "peak")))
		_spawn_mix(anlauf_n, "laeufer", center)
		print("[BAL][PHASE] modus=wellen welle=%d art=anlauf dauer=%.1f druck=%.2f anzahl=%d offen=%d" % [
			int(host.wave), phase_left, wave_druck, anlauf_n, stage_pending])
		print("[BAL][MODELL] modus=wellen stufe=%s welle=%d druck=%.2f ziel=%.2f abweichung=%.2f hp=%.2f spd=%.2f" % [
			st, int(host.wave), wave_druck,
			Balance.ziel_druck("wellen", st, float(host.wave) * 40.0),
			wave_druck - Balance.ziel_druck("wellen", st, float(host.wave) * 40.0),
			float(bal["hp"]), float(bal["spd"])])

	# Runde 38: Kraftfelder ab Welle 7 (alle 3 Wellen) - NICHT auf Boss-Wellen
	if not wave_boss and int(host.wave) >= 7 and (int(host.wave) % 3 == 0 or int(host.wave) % 10 == 0 or int(host.wave) % 5 == 0):
		host._spawn_force_field()
	host.ui_manager.show_banner("WELLE " + str(host.wave), Color(0.95, 0.85, 0.35))
	if not host.tip_shown and host.ui_manager.has_method("show_tip"):
		host.tip_shown = true
		host.ui_manager.show_tip("FEUERKNOPF GEDRÜCKT HALTEN = DAUERFEUER   ·   Q = TRANK, E = BOMBE")
		host._save_profile()
	_recount_wave()
	host.ui_manager.update_wave_label(host.wave, host.coins, false, 0.0, host.wave_remaining, host.level, host.wave_start_level + WAVE_LEVEL_UPS)


# ============================================================
# Phasentakt (wird von game_manager._process im Wellen-Modus gerufen)
# ============================================================

func stage_tick(delta: float) -> void:
	if not host.wave_active:
		return
	var st: String = _stufe()
	phase_left -= delta

	# Boss-Telegraph: 2 s Vorwarnung, dann erscheint der Boss
	if boss_telegraph > 0.0:
		boss_telegraph -= delta
		if boss_telegraph <= 0.0:
			boss_telegraph = 0.0
			_spawn_wave_boss()

	# v1.56b (Bug 4): Feld leer, aber es sind noch Gegner im Vorrat -> SOFORT
	# nachschicken. Vorher (erster Versuch) setzte dieser Block nur phase="peak"
	# und kehrte zurueck - der Spawn-Code darunter wurde nie erreicht, die Welle
	# blieb mit offen=3 und feld=0 stehen (Beleg: [WAVE][WATCHDOG] rest=0 offen=3
	# phase=peak phase_left=-256). Jetzt wird direkt gespawnt.
	if stage_pending > 0 and _count_aktiv() == 0 and boss_telegraph <= 0.0:
		var n_nach: int = mini(stage_pending, maxi(1, Balance.max_aktiv(st)))
		print("[BAL][NACHSCHUB] modus=wellen welle=%d feld_leer=true offen=%d schub=%d" % [
			int(host.wave), stage_pending, n_nach])
		_spawn_mix(n_nach, "", _center())
		stage_pending -= n_nach
		if phase != "peak":
			phase = "peak"
			phase_left = Balance.phase_laenge(st, "peak")
		return

	if phase == "erholung":
		_slow_all(0.6)
		erholung_dauer += delta
		if phase_left <= 0.0:
			_clear_slow()
			phase = "anlauf"
			phase_left = Balance.phase_laenge(st, "anlauf")
			print("[BAL][PHASE] modus=wellen welle=%d art=anlauf dauer=%.1f druck=%.2f" % [
				int(host.wave), phase_left, wave_druck])
		return

	if phase == "anlauf":
		if phase_left <= 0.0:
			phase = "peak"
			phase_left = Balance.phase_laenge(st, "peak")
			print("[BAL][PHASE] modus=wellen welle=%d art=peak dauer=%.1f druck=%.2f offen=%d" % [
				int(host.wave), phase_left, wave_druck, stage_pending])
		return

	if phase == "peak":
		var f: float = Balance.fenster(st)
		burst_t += delta
		if burst_t >= f and stage_pending > 0:
			burst_t = 0.0
			var links: float = maxf(1.0, phase_left)
			var schuebe: int = maxi(1, int(ceil(links / f)))
			var n: int = maxi(1, int(ceil(float(stage_pending) / float(schuebe))))
			n = mini(n, stage_pending)
			_spawn_mix(n, "", _center())
			stage_pending -= n
		if phase_left <= 0.0:
			# Peak vorbei -> Erholung. Der Rest kommt nach der Pause.
			phase = "erholung"
			phase_left = Balance.phase_laenge(st, "erholung")
			erholung_dauer = 0.0
			_aktive_log()
		return

	if phase == "boss":
		if phase_left <= 0.0 and stage_pending <= 0:
			phase = "erholung"
			phase_left = Balance.erholung_nach_boss(st)
			erholung_dauer = 0.0
			_aktive_log()


func offen() -> int:
	# v1.56b (Bug 4): Alles, was noch kommt, zaehlt als "offen":
	#   - Spawn-Vorrat der Welle
	#   - Telegraph eines angekuendigten Bosses
	#   - lebender Boss der Boss-Welle
	# Vorher oeffnete sich bei Boss-Wellen sofort der Shop (wellen_remaining war
	# beim Start 0) und bei leerem Feld wartete der Spieler auf Nachschub, der
	# erst im naechsten Peak kam -> "Spiel steht".
	var n: int = stage_pending
	if boss_telegraph > 0.0:
		n += 1
	if bool(host.get("_boss_active")) and host.get("current_boss") != null:
		n += 1
	return n


func _aktive_log() -> void:
	var aktiv: int = _count_aktiv()
	print("[BAL][ERHOLUNG] modus=wellen welle=%d spawn=0 gegner_aktiv=%d dauer=%.1f" % [
		int(host.wave), aktiv, phase_left])


func _center() -> Vector2:
	if is_instance_valid(host.player):
		return host.player.global_position
	return host.map_generator.get_center()


# ============================================================
# Spawn mit Rollen-Mix + Hetzer-Limit (Spec K3 / A4)
# ============================================================

func _spawn_mix(n: int, nur_rolle: String, center: Vector2) -> int:
	var st: String = _stufe()
	var gewichte: Dictionary = Balance.mix_gewichte(st)
	var hetzer_aktiv: int = _count_hetzer()
	var aktiv: int = _count_aktiv()
	var gespawnt: int = 0
	var zaehler: Dictionary = { "laeufer": 0, "hetzer": 0, "anker": 0, "stoerer": 0 }
	for i in range(n):
		if aktiv + gespawnt >= Balance.max_aktiv(st):
			print("[BAL][SPAWN] stufe=%s grenze=%d erreicht - Rest spaeter" % [st, Balance.max_aktiv(st)])
			break
		var rolle: String = nur_rolle
		if rolle == "":
			rolle = Balance.rolle_waehlen(st, gewichte, hetzer_aktiv, aktiv + gespawnt)
		if rolle == "hetzer" and hetzer_aktiv >= Balance.hetzer_max(aktiv + gespawnt, st):
			rolle = "laeufer"
		var t: int = _typ_fuer_rolle(rolle)
		host.spawn_monster_at(host._wave_spawn_pos(center), t)
		if rolle == "hetzer":
			hetzer_aktiv += 1
		gespawnt += 1
		zaehler[rolle] = int(zaehler[rolle]) + 1
	var anteil: float = 0.0
	if gespawnt > 0:
		anteil = float(int(zaehler["hetzer"])) / float(gespawnt)
	print("[BAL][MIX] modus=wellen welle=%d rolle=hetzer anteil=%.2f aktiv_max=%d gespawnt=%d mix=%s" % [
		int(host.wave), anteil, Balance.hetzer_max(aktiv + gespawnt, st), gespawnt,
		"%d/%d/%d/%d" % [int(zaehler["laeufer"]), int(zaehler["hetzer"]), int(zaehler["anker"]), int(zaehler["stoerer"])]])
	return gespawnt


func _pool() -> Array:
	var pool: Array = host.map_data().get("pool", [])
	if pool.is_empty():
		pool = [0, 1, 2, 3, 4, 5, 6]
	# Biom-Spezialisten ergaenzen (Graber/Golem/Feuerwerfer)
	match str(host.biome_id):
		"desert": pool = pool + [8]
		"ice": pool = pool + [9]
		"lava": pool = pool + [10]
	return pool


func _typ_fuer_rolle(rolle: String) -> int:
	var kandidaten: Array = Balance.typen_fuer_rolle(rolle, _pool())
	if kandidaten.is_empty():
		return host._pick_random_monster_type()
	return int(kandidaten[randi() % kandidaten.size()])


func _count_hetzer() -> int:
	var n: int = 0
	for m in host.monster_container.get_children():
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if not m.has_method("counts_for_wave") or not bool(m.call("counts_for_wave")):
			continue
		if Balance.rolle_von_type(int(m.get("type"))) == "hetzer":
			n += 1
	return n


func _count_aktiv() -> int:
	var n: int = 0
	for m in host.monster_container.get_children():
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.has_method("counts_for_wave") and bool(m.call("counts_for_wave")):
			n += 1
	return n


# ============================================================
# Boss (2 Phasen, keine Adds) - Spec K4 / B1
# ============================================================

func _spawn_wave_boss() -> void:
	var center: Vector2 = _center()
	if host.current_boss != null and is_instance_valid(host.current_boss) and not host.current_boss.is_queued_for_deletion():
		host.current_boss.queue_free()
	host.current_boss = host.spawn_monster_at(host._wave_spawn_pos(center, true), boss_typ)
	if host.current_boss == null:
		host._bdiag("SPAWN", "WARNUNG: Boss-Spawn null - zweiter Versuch bei 380 px")
		host.current_boss = host.spawn_monster_at(host._wave_spawn_pos(center, false), boss_typ)
	host._boss_active = host.current_boss != null
	if host.current_boss != null:
		# v1.56 (K4): Boss-HP = Referenz-DPS x Ziel-Killzeit der Stufe
		var hp_ziel: int = Balance.boss_hp(_stufe(), true) if boss_ist_riese else Balance.mini_hp(_stufe())
		host.current_boss.set("max_health", hp_ziel)
		host.current_boss.set("current_health", hp_ziel)
		host.current_boss.set("start_hp", hp_ziel)
		if not boss_ist_riese:
			host.current_boss.set("speed", Balance.mini_speed(_stufe()))
			host.current_boss.set("damage_amount", 1)
		host._boss_last_type = str(host.current_boss.get("type"))
		host.current_boss.set_meta("bal_boss", true)
		host.current_boss.set_meta("bal_phase", 1)
		host._bdiag("SPAWN", "Wellen-Boss Welle %d type=%d %s hp=%d/%d map=%s biome=%s" % [
			int(host.wave), boss_typ, ("RIESE" if boss_ist_riese else "MINI"),
			int(host.current_boss.current_health), int(host.current_boss.start_hp),
			host.active_map, host.biome_id])
		print("[BAL][BOSS] modus=wellen welle=%d art=%s phase=1 ersetzt_peak=true adds=0 hp=%d spawn=true" % [
			int(host.wave), ("biom" if boss_ist_riese else "mini"), int(host.current_boss.start_hp)])
	else:
		host._bdiag("SPAWN", "FEHLER: Wellen-Boss type=%d wurde nicht erzeugt" % boss_typ)


# ============================================================
# Erholungsfenster: Restgegner langsam, kein Fernkampf
# ============================================================

func _slow_all(faktor: float) -> void:
	for m in host.monster_container.get_children():
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if not m.has_method("counts_for_wave"):
			continue
		if not m.has_meta("bal_speed_base"):
			m.set_meta("bal_speed_base", float(m.get("speed")))
			m.set("speed", float(m.get("speed")) * faktor)
			m.set("shoot_timer", 6.0)      # kein Fernkampf im Erholungsfenster
			_slow_marked.append(m)


func _clear_slow() -> void:
	for m in _slow_marked:
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.has_meta("bal_speed_base"):
			m.set("speed", float(m.get_meta("bal_speed_base")))
			m.remove_meta("bal_speed_base")
	_slow_marked.clear()


func _next_wave(force: bool = false) -> void:
	# Runde 32: Doppel-Tap auf "WEITER" (auf dem Handy leicht passiert) oder
	# Button + ablaufender 30s-Timer haben die Welle ZWEIMAL gestartet
	# (doppelte Monster + uebersprungene Wellennummer = "2x auf dem Feld").
	# in_shop ist genau waehrend der Shop-Phase true -> zweiter Aufruf faellt raus.
	if not host.in_shop:
		return
	# Runde 33 (Variante B): der Client meldet nur "fertig", der Host entscheidet
	if host.coop_client and not host.coop_host:
		NetManager.c_send_shop_ready()
		host.ui_manager.hide_shop()
		return
	host.shop_ready[host.my_slot] = true
	if not force and host.coop_host and host.lan_mode and not host._all_players_ready():
		host.ui_manager.show_banner("WARTE AUF DEN ANDEREN SPIELER", Color(0.95, 0.85, 0.35))
		return
	host.in_shop = false
	host.shop_time = 0.0
	host.ui_manager.hide_shop()
	_start_wave()


func _recount_wave() -> void:
	# Zaehlt alle lebenden Monster, die zur Welle gehoeren (Pflanzen/Ranken nicht)
	var n: int = 0
	for m2 in host.monster_container.get_children():
		if not is_instance_valid(m2) or m2.is_queued_for_deletion():
			continue
		# Wichtig: im Container liegen auch Item-Geister/Nicht-Monster
		if not m2.has_method("counts_for_wave"):
			continue
		if m2.get("ghost") == true:
			continue
		# wichtig: das Signal kommt VOR queue_free() - sterbende Monster nicht mitzaehlen
		if int(m2.get("current_health")) <= 0:
			continue
		if not m2.call("counts_for_wave"):
			continue
		n += 1
	host.wave_remaining = n

# Konstanten aus der Fassade (ui_manager.gd)
const WAVE_LEVEL_UPS := 2             # Level-Aufstiege pro Welle, BIS der Shop oeffnet
