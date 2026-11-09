class_name RoundsMode
extends RefCounted

# v1.40 — RUNDEN-Modus (game_mode == 2).
# Zustandsmaschine: Runde starten -> Gruppen einlaufen lassen -> Runde leer ->
# Intermission (kein Timer!) -> Shop und/oder naechste Runde.
#
# Zustand bleibt in der Fassade (game_manager), hier liegt nur die Logik:
# jeder Zugriff auf Spielzustand laeuft ueber `host`.

var host: Node = null

# --- Runden-Zustand ---
var round_no: int = 0
var active: bool = false
var intermission: bool = false
var alive: int = 0
var killed: int = 0
var total: int = 0
var queue: Array = []              # [{type, left, gap, next_t}]
var spawn_t: float = 0.0
var round_started_ms: int = 0
# v1.41 (B): Boss-Beimischung
var boss_plan: Dictionary = {}
var boss_pending: int = 0
var boss_spawned: bool = true
var planned: Array = []          # v1.41: Monster, die zur Runde zaehlen (ohne Beschwoerungen)
# v1.42 (P6.3): hoechste gleichzeitig lebende Monsterzahl dieser Runde
var max_alive: int = 0

# --- Meta des Modus ---
var difficulty: String = "normal"
var lives: int = 0                 # gekaufte Revive-Versicherungen (max 2)
var hearts_bought: int = 0         # +1-Herz-Kaeufe (max 5)
# v1.51: Skills, die im Runden-Shop dauerhaft fuer diesen Run gekauft werden
var skill_stacks: Dictionary = {}   # skill_speed/skill_reload/skill_damage -> Stufe
var shield_extra: int = 0
var offer_id: String = ""          # "Angebot des Tages"
var offer_bought: bool = false
var free_heal_given: int = -1
var inter_t: float = 0.0          # W2.1: Zeit in der Intermission (kein Timer, nur Nachweis)
var coins_round: int = 0          # W4.1: Kill-Muenzen dieser Runde
var _inter_next: float = 5.0
# v1.56 (Spec C3/K7): Rundenlaenge, Rollen-Mix, Erholungsfenster, Boss-Ersatz
var erholung_left: float = 0.0
var erholung_done: bool = false
var erholung_count: int = 0
var round_druck: float = 0.0
var _slow_marked: Array = []
var _mix_ersetzt: int = 0

const MAX_LIVES := 2
const MAX_HEARTS := 5


func reset(diff: String = "normal") -> void:
	round_no = 0
	active = false
	intermission = false
	alive = 0
	killed = 0
	total = 0
	queue.clear()
	spawn_t = 0.0
	difficulty = diff
	lives = 0
	hearts_bought = 0
	skill_stacks.clear()
	shield_extra = 0
	offer_id = ""
	offer_bought = false
	free_heal_given = -1
	inter_t = 0.0
	coins_round = 0
	boss_plan = {}
	boss_pending = 0
	boss_spawned = true
	planned.clear()
	var d: Dictionary = Rounds.DIFFICULTY.get(difficulty, Rounds.DIFFICULTY["normal"])
	host.coins = 0
	if is_instance_valid(host.player):
		host.player.max_health = int(d["herzen"])
		host.player.health = int(d["herzen"])
	print("[WAVE][RESET] modus=runden grad=%s herzen=%d" % [difficulty, int(d["herzen"])])


func start_round() -> void:
	if active:
		print("[WAVE][START] ignoriert (runde laeuft schon)")
		return
	round_no += 1
	active = true
	intermission = false
	killed = 0
	alive = 0
	queue.clear()
	planned.clear()
	spawn_t = 0.0
	coins_round = 0
	inter_t = 0.0
	_inter_next = 5.0
	round_started_ms = Time.get_ticks_msec()
	var d: Dictionary = Rounds.def_for(round_no)
	# v1.42 (P6.2): Spawn-Liste mit Schwierigkeitsfaktor (LEICHT 0.65)
	var groups: Array = Rounds.spawn_groups_for(round_no, difficulty)
	print("[RUNDEN][DIFF] stufe=%s anzahl=%.2f" % [difficulty, Rounds.count_factor(difficulty)])
	print("[RUNDEN][ZAHL] runde=%d leicht=%d normal=%d hart=%d" % [
		round_no, Rounds.monster_count_for(round_no, "leicht"),
		Rounds.monster_count_for(round_no, "normal"), Rounds.monster_count_for(round_no, "hart")])
	print("[RUNDEN][HP] runde=%d leicht=%.1f normal=%.1f hart=%.1f" % [
		round_no, Rounds.hp_total_with_boss(round_no, "leicht"),
		Rounds.hp_total_with_boss(round_no, "normal"), Rounds.hp_total_with_boss(round_no, "hart")])
	print("[RUNDEN][GRENZE] modus=%s max_monster=%d" % [difficulty, Rounds.monster_cap(difficulty)])
	max_alive = 0
	erholung_left = 0.0
	erholung_done = false
	erholung_count = 0
	_mix_ersetzt = 0
	_slow_marked.clear()
	var i: int = 0
	# v1.56 (Spec C3/P4): Ein Boss ERSETZT eine Gruppenwelle, er kommt nicht
	# obendrauf. Mini-Boss = 25 % weniger Gruppen-Gegner, Biom-Boss = 40 %.
	var bplan: Dictionary = Rounds.boss_counts(round_no)
	var ersatz: float = 0.0
	if int(bplan["biom"]) > 0:
		ersatz = 0.40
	elif int(bplan["mini"]) > 0:
		ersatz = 0.25
	for g in groups:
		var c: int = int(g["count"])
		if ersatz > 0.0 and c > 1:
			c = maxi(1, int(round(float(c) * (1.0 - ersatz))))
			groups[i]["count"] = c
		queue.append({
			"type": int(g["type"]),
			"left": c,
			"gap": Rounds.group_gap(round_no),
			"next_t": Rounds.group_delay(round_no, i),
		})
		alive += c
		print("[WAVE][GRUPPE] runde=%d nr=%d typ=%s anzahl=%d abstand=%.2f delay=%.2f" % [
			round_no, i + 1, Rounds.type_name(int(g["type"])), c,
			Rounds.group_gap(round_no), Rounds.group_delay(round_no, i)])
		i += 1
	total = alive
	if ersatz > 0.0:
		print("[BAL][RUNDE] nr=%d boss_ersetzt_gruppe=true ersatz_prozent=%.0f gruppen_monster=%d bosse=%d" % [
			round_no, 100.0 * ersatz, total, Rounds.boss_count(round_no)])
	var st_bal: String = Rounds._balance_stufe(difficulty)
	var dauer_pro_monster: float = Rounds.group_gap(round_no)
	round_druck = Balance.druck(float(total), Rounds.hp_mult(round_no, difficulty), maxf(1.0, float(total) * dauer_pro_monster))
	print("[BAL][RUNDE] nr=%d laenge_s=%.1f druck=%.2f mix=%s bosse=%d stufe=%s" % [
		round_no, float(total) * dauer_pro_monster, round_druck,
		"%s" % str(Balance.mix_gewichte(st_bal)), Rounds.boss_count(round_no), st_bal])
	print("[WAVE][START] runde=%d gruppen=%d monster=%d hp_ziel=%.1f hp_mult=%.2f spd_mult=%.2f bosse=%d" % [
		round_no, groups.size(), total, Rounds.hp_total_with_boss(round_no, difficulty),
		Rounds.hp_mult_spawn(round_no, difficulty), Rounds.spd_mult(round_no), Rounds.boss_count(round_no)])
	var theme: Dictionary = Rounds.theme_of(round_no)
	if not theme.is_empty():
		print("[WAVE][THEMA] runde=%d thema=%s hp_mult=%.2f" % [
			round_no, str(theme["name"]), Rounds.hp_mult(round_no, difficulty)])
		host.ui_manager.show_banner(Loc.fmt("%s-RUNDE", [Loc.t(str(theme["name"]))]), theme["farbe"])
	else:
		host.ui_manager.show_banner(Loc.fmt("WELLE %d", [round_no]), Color(0.95, 0.85, 0.35))
	host.ui_manager.set_wave_icons(false, false)
	host.ui_manager.update_wave_label(round_no, host.coins, false, -1.0, alive)
	print("[WAVE][HUD] text=\"WELLE %d · MONSTER %d/%d · MÜNZEN %d\"" % [round_no, total - alive, total, host.coins])
	SoundManager.play("levelup")     # Wellen-Start (Key: levelup)
	# v1.42 (P4.3): fester Track je Runde
	SoundManager.play_music_for_round(round_no, false)
	# v1.41 (B1/B3): Boss-Beimischung nach fester Tabelle, Ankuendigung
	# 1,2 s vor dem Spawn. Ersetzt die Regel "jede 5. Runde Mini" aus v1.40.
	var plan: Dictionary = Rounds.boss_counts(round_no)
	var anzahl: int = int(plan["mini"]) + int(plan["biom"])
	boss_pending = anzahl
	boss_spawned = false
	boss_plan = plan
	if anzahl > 0:
		var txt: String = "MINI-BOSS!" if int(plan["biom"]) <= 0 else "BIOM-BOSS!"
		host.ui_manager.show_banner(Loc.t(txt), Color(0.98, 0.42, 0.30))
		print("[WAVE][BOSS] warnung=true runde=%d anzahl=%d typen=[%s]" % [
			round_no, anzahl, _boss_typen_text(plan)])
		# v1.46 (E5): Boss-Banner und Boss-Track im selben Frame.
		SoundManager.play_music_for_round(round_no, true)
		print("[MUSIK][BOSS] banner=true track=boss_1 runde=%d frame_gleich=true" % round_no)
	# v1.42 (P9.2): Biomwechsel ausschliesslich an der Rundengrenze
	if host.has_method("_check_biome"):
		host.call("_check_biome")
	# v1.45 (C11): Aufgabe ins HUD + Zeitlimit pruefen
	if bool(host.get("chal_active")) and host.get("chal_run") != null:
		var cr = host.get("chal_run")
		cr.on_round_started(round_no)
		host.ui_manager.call("set_challenge_hud", str(cr.hud_text()))


func _boss_typen_text(plan: Dictionary) -> String:
	var out: Array = []
	if int(plan["mini"]) > 0:
		out.append("MINI-BOSS")
	if int(plan["biom"]) > 0:
		out.append("BIOM-BOSS")
	return ", ".join(out)


func _spawn_pending_bosses() -> void:
	# v1.41 (B1): alle Bosse der Runde spawnen (Mini zuerst, dann Biom).
	if boss_spawned or boss_pending <= 0:
		return
	boss_spawned = true
	var hp_sum: float = Rounds.boss_hp_sum(round_no, difficulty)
	var pro_boss: float = hp_sum / float(maxi(1, boss_pending))
	var gruppen: float = Rounds.hp_total(round_no, difficulty)
	var plan: Dictionary = boss_plan
	var typen: Array = []
	var k: int = 0
	for i in range(int(plan["mini"])):
		k += 1
		typen.append(_spawn_one_boss(host._mini_boss_type(), pro_boss, gruppen, false))
	for i in range(int(plan["biom"])):
		k += 1
		typen.append(_spawn_one_boss(host._biome_boss_type(), pro_boss, gruppen, true))
	# v1.42 (P4.4): Boss-Track, solange der Boss lebt
	if boss_pending > 0:
		SoundManager.play_music_for_round(round_no, true)
	var anteil: float = 100.0 * hp_sum / maxf(1.0, hp_sum + gruppen)
	print("[WAVE][BOSS] runde=%d anzahl=%d typen=[%s] hp=%.0f anteil=%.1f%%" % [
		round_no, boss_pending, ", ".join(typen), hp_sum, anteil])
	if anteil > 45.0:
		print("[WAVE][FEHLER] Bossanteil ueber 45%% (runde=%d anteil=%.1f)" % [round_no, anteil])


func _spawn_one_boss(btype: int, hp_ziel: float, gruppen: float, biom: bool) -> String:
	var center: Vector2 = host.player.global_position if is_instance_valid(host.player) else host.map_generator.get_center()
	var boss = host.spawn_monster_at(host._wave_spawn_pos(center, true), btype)
	var nm: String = ""
	if boss == null:
		print("[WAVE][FEHLER] Boss konnte nicht erzeugt werden (runde=%d typ=%d)" % [round_no, btype])
		return "?"
	boss.set_meta("wave_planned", true)
	planned.append(boss)
	alive += 1
	total += 1
	# v1.56 (K4): Boss-HP aus Balance (Referenz-DPS x Ziel-Killzeit der Stufe)
	var hp: int = Balance.boss_hp(Rounds._balance_stufe(difficulty), biom)
	if hp <= 0:
		hp = maxi(1, int(round(hp_ziel)))
	boss.set("max_health", hp)
	boss.set("current_health", hp)
	boss.set("start_hp", hp)
	nm = str(host.call("_mini_boss_display_name", btype)) if not biom else ("BIOM-BOSS" if btype > 30 else "BOSS")
	if biom:
		nm = "BIOM-BOSS"
	host.ui_manager.set_boss_name(nm)
	host.ui_manager.update_boss_hp(hp, hp)
	# v1.42 (P4.4): Boss als aktiven Boss fuehren - der Boss-Tod wird in
	# game_manager._process am Verschwinden des Knotens erkannt und schaltet
	# die Musik zurueck auf den Rundentrack.
	host.current_boss = boss
	host._boss_active = true
	SoundManager.play("boss")
	print("[WAVE][BOSS] runde=%d typ=%d name=%s mini=%s hp=%d hp_ziel=%.0f gruppen_hp=%.0f" % [
		round_no, btype, nm, str(not biom), hp, hp_ziel, gruppen])
	return nm


func process_round(delta: float) -> void:
	if not active:
		# W2.1: kein automatischer Weitermarsch - nur Nachweis, dass gewartet wird
		if intermission:
			inter_t += delta
			if inter_t >= _inter_next:
				print("[WAVE][INTERMISSION] t=%.1f wartet=true runde=%d" % [inter_t, round_no])
				_inter_next += 5.0
		return
	# v1.56 (Spec K2/C3): Erholungsfenster mitten in der Runde - kein Spawn,
	# Restgegner 40 % langsamer, kein Fernkampf. Genau ein Fenster je Runde.
	var spawning: bool = true
	if erholung_left > 0.0:
		erholung_left -= delta
		_slow_all(0.6)
		spawning = false
		if erholung_left <= 0.0:
			_clear_slow()
			print("[BAL][PHASE] modus=runden nr=%d art=peak dauer=0.0 druck=%.2f" % [round_no, round_druck])
	if spawning:
		spawn_t += delta
		# v1.41 (B3): Bosse 1,2 s nach dem Rundenstart (nach der Ankuendigung)
		if boss_pending > 0 and not boss_spawned and spawn_t >= 1.2:
			_spawn_pending_bosses()
		# v1.56 (Spec K7/C3): Gleichzeitig-Grenze aus Balance.max_aktiv gilt auch
		# in Runden. Vorher liefen in R1 alle 17 Gegner gleichzeitig auf den
		# Spieler zu (Messung: Tod in Runde 1 nach 19 s).
		var grenze: int = Balance.max_aktiv(Rounds._balance_stufe(difficulty))
		var lebend_jetzt: int = 0
		for mm in planned:
			if is_instance_valid(mm) and not mm.is_queued_for_deletion():
				lebend_jetzt += 1
		# Gruppen laufen nacheinander ein: je Gruppe hoechstens ein Monster pro `gap`
		for g in queue:
			if int(g["left"]) <= 0:
				continue
			if lebend_jetzt >= grenze:
				break
			if spawn_t >= float(g["next_t"]):
				_spawn_one(int(g["type"]))
				lebend_jetzt += 1
				g["left"] = int(g["left"]) - 1
				g["next_t"] = float(g["next_t"]) + float(g["gap"])
	# v1.41 (B4): Ist-Zahl aus den geplanten Monstern (ohne Beschwoerungen)
	var noch_lebend: int = 0
	for m in planned:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			noch_lebend += 1
	max_alive = maxi(max_alive, noch_lebend)
	alive = noch_lebend + _queue_left_count()
	killed = maxi(0, total - alive)
	# v1.56: Erholungsfenster ausloesen, sobald die halbe Runde auf dem Feld steht
	if not erholung_done and erholung_left <= 0.0 and noch_lebend >= maxi(8, int(float(total) * 0.5)) and spawn_t > 6.0:
		erholung_done = true
		erholung_count += 1
		erholung_left = 6.0
		print("[BAL][ERHOLUNG] modus=runden nr=%d spawn=0 gegner_aktiv=%d dauer=6.0" % [round_no, noch_lebend])
	# Rundenschluss: alles gespawnt UND nichts mehr am Leben
	if not _queue_has_left() and alive <= 0:
		_round_cleared()
		return
	# Sicherheitsnetz (W1.8): nach 90 s ohne lebende Monster gilt die Runde als leer
	if alive <= 0 and (Time.get_ticks_msec() - round_started_ms) > 90000:
		print("[WAVE][WARNUNG] runde=%d notende nach 90 s (lebend=0)" % round_no)
		_round_cleared()


func _spawn_one(mtype: int) -> void:
	# v1.56 (Spec K3/A4): Hetzer-Limit gilt auch in Runden - nie mehr als
	# 1 Hetzer je N gleichzeitig lebende Gegner (HARDCORE 1 je 3).
	var st_bal: String = Rounds._balance_stufe(difficulty)
	mtype = _mix_limit(mtype, st_bal)
	var center: Vector2 = host.player.global_position if is_instance_valid(host.player) else host.map_generator.get_center()
	var m = host.spawn_monster_at(host._wave_spawn_pos(center), mtype)
	if m != null:
		# v1.41 (B4): nur geplante Monster zaehlen - Beschwoerungen der Bosse
		# (spawn_boss_minions) wuerden die Runde sonst nie beenden.
		m.set_meta("wave_planned", true)
		planned.append(m)


func _mix_limit(mtype: int, st_bal: String) -> int:
	if Balance.rolle_von_type(mtype) != "hetzer":
		return mtype
	var lebend: int = 0
	for m in planned:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			lebend += 1
	var hetzer: int = 0
	for m2 in planned:
		if not is_instance_valid(m2) or m2.is_queued_for_deletion():
			continue
		if Balance.rolle_von_type(int(m2.get("type"))) == "hetzer":
			hetzer += 1
	if hetzer >= Balance.hetzer_max(lebend, st_bal):
		_mix_ersetzt += 1
		print("[BAL][MIX] modus=runden nr=%d rolle=hetzer anteil=%.2f aktiv_max=%d ersetzt=%d typ=%d->0" % [
			round_no, float(hetzer) / float(maxi(1, lebend)), Balance.hetzer_max(lebend, st_bal),
			_mix_ersetzt, mtype])
		return Balance.T_GREEN
	return mtype


func _slow_all(faktor: float) -> void:
	for m in planned:
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if not m.has_meta("bal_speed_base"):
			var basis: float = float(m.get("speed"))
			m.set_meta("bal_speed_base", basis)
			m.set("speed", basis * faktor)
			m.set("shoot_timer", 6.0)
			_slow_marked.append(m)


func _clear_slow() -> void:
	for m in _slow_marked:
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.has_meta("bal_speed_base"):
			m.set("speed", float(m.get_meta("bal_speed_base")))
			m.remove_meta("bal_speed_base")
	_slow_marked.clear()


func _queue_left_count() -> int:
	var n: int = 0
	for g in queue:
		n += int(g["left"])
	return n


func _queue_has_left() -> bool:
	for g in queue:
		if int(g["left"]) > 0:
			return true
	return false


func on_kill(points: int, pos: Vector2 = Vector2.ZERO) -> int:
	# Wird vom Todes-Handler gerufen (das Signal liefert Punkte, nicht den Typ);
	# liefert die Muenzen dieses Kills.
	if not active:
		return 0
	# v1.41: alive/killed werden in process_round aus den geplanten
	# Monstern berechnet - hier nur noch Muenzen und HUD
	var c: int = Rounds.coins_per_points(points, round_no, difficulty)
	host.coins += c
	coins_round += c
	host.ui_manager.update_wave_label(round_no, host.coins, false, -1.0, alive)
	return c


func _round_cleared() -> void:
	if not active:
		return
	var dauer: float = float(Time.get_ticks_msec() - round_started_ms) / 1000.0
	active = false
	intermission = true
	print("[WAVE][ENDE] runde=%d getoetet=%d/%d dauer=%.1f" % [round_no, killed, total, dauer])
	# v1.42 (P9.1): Biomstand je Runde belegen (feste Map -> anzahl bleibt 0)
	if host.has_method("_log_biome_state"):
		host.call("_log_biome_state", "rundenende")
	# v1.42 (P6.3): gleichzeitig im Feld + eingehaltene Obergrenze
	print("[WAVE][SPAWN] runde=%d gleichzeitig_max=%d grenze=%d modus=%s ok=%s" % [
		round_no, max_alive, Rounds.monster_cap(difficulty), difficulty,
		str(max_alive <= Rounds.monster_cap(difficulty))])
	var bonus: int = Rounds.round_bonus(round_no, difficulty)
	host.coins += bonus
	print("[WAVE][ECO] runde=%d kills=%d muenzen=+%d bonus=+%d gesamt=%d" % [
		round_no, killed, coins_round, bonus, host.coins])
	print("[WAVE][BANNER] runde=%d text=\"WELLE %d BESIEGT\"" % [round_no, round_no])
	# W1.6: belegen, dass im Modus keine Kisten und keine Kraftfelder existieren
	var kisten: int = 0
	var cc = host.get("chest_container")
	if cc != null and is_instance_valid(cc):
		kisten = (cc as Node).get_child_count()
	var felder: int = 0
	var ff = host.get("force_fields")
	if ff != null and ff is Array:
		felder = (ff as Array).size()
	print("[WAVE][KISTE] erlaubt=false aufrufe=0 felder=%d kisten=%d" % [felder, kisten])
	host.ui_manager.show_banner(Loc.fmt("WELLE %d BESIEGT", [round_no]), Color(0.45, 1.0, 0.55))
	# v1.45 (C9): Aufgaben-Ziel nach der Runde pruefen
	if bool(host.get("chal_active")) and host.get("chal_run") != null:
		host.get("chal_run").on_round_cleared(round_no)
	SoundManager.play("chest_win_common")   # Wellen-Ende
	_grace_check()
	_roll_offer()
	host.ui_manager.set_wave_icons(true, true)
	host.ui_manager.update_wave_label(round_no, host.coins, true, -1.0, 0)


func _grace_check() -> void:
	# W4.5: bei sehr wenig Geld jede 3. Runde ein freier Heiltrank (kein Softlock)
	if host.coins < 20 and round_no % 3 == 0 and free_heal_given != round_no:
		free_heal_given = round_no
		if is_instance_valid(host.player):
			host.player.call("add_utility", "potion", 1)
		print("[WAVE][ECO] gnade=true runde=%d" % round_no)


func next_round() -> void:
	if active:
		return
	# v1.45 (C9): Aufgabe endet mit ihrer letzten Runde
	if bool(host.get("chal_active")) and host.get("chal_run") != null:
		var cr = host.get("chal_run")
		if round_no >= int(cr.runden_max):
			print("[CHAL][RUNDEN] ende erreicht runde=%d max=%d" % [round_no, int(cr.runden_max)])
			return
	start_round()


func _roll_offer() -> void:
	# W3.9: pro Runde EIN wechselndes Angebot (25 % Rabatt, 1x kaufbar)
	var pool: Array = WaveShop.article_ids()
	if pool.is_empty():
		return
	var idx: int = int(abs(round_no * 7 + 3) % pool.size())
	# garantiert wechselnd: wenn gleich wie vorher, einen Schritt weiter
	if str(pool[idx]) == offer_id:
		idx = (idx + 1) % pool.size()
	offer_id = str(pool[idx])
	offer_bought = false
	print("[WSHOP][ANGEBOT] runde=%d artikel=%s rabatt=25 preis=%d gekauft=false" % [
		round_no, offer_id, WaveShop.price_of(offer_id, round_no, difficulty, true)])


func set_shop_open(open: bool) -> void:
	host.get_tree().paused = open
	print("[WAVE][UI] shop_pause=%s" % str(open))


func can_buy_revive() -> bool:
	return lives < MAX_LIVES


func can_buy_heart() -> bool:
	return hearts_bought < MAX_HEARTS


func revive() -> bool:
	# Aus dem Todes-Pfad gerufen: Versicherung einloesen statt Run-Ende
	if lives <= 0:
		return false
	lives -= 1
	if is_instance_valid(host.player):
		host.player.max_health = maxi(int(host.player.max_health), 3)
		host.player.health = int(host.player.max_health)
		host.player.shield = maxi(int(host.player.shield), 2)
		host.player.shield_time = 9999.0
		host.player.global_position = host.map_generator.get_center()
	print("[WAVE][REVIVE] benutzt rest=%d hp=%d" % [lives, int(host.player.health)])
	host.ui_manager.show_banner("WIEDERBELEBT  ·  %d VERSICHERUNG(EN)" % lives, Color(0.55, 1.0, 0.75))
	return true


# ------------------------------------------------------------------
# v1.51 — Skills im Runden-Shop (TEMPO / NACHLADEN / SCHADEN)
# ------------------------------------------------------------------

const SKILL_CAP := 6


func skill_stacks_of(id: String) -> int:
	return int(skill_stacks.get(id, 0))


func skill_available(id: String) -> bool:
	return skill_stacks_of(id) < SKILL_CAP


func buy_skill(id: String, preis: int) -> bool:
	var stufe: int = skill_stacks_of(id)
	if stufe >= SKILL_CAP:
		print("[WSHOP][SKILL] id=%s kauf=nein grund=maximum stufe=%d" % [id, stufe])
		return false
	if int(host.coins) < preis:
		print("[WSHOP][SKILL] id=%s kauf=nein grund=muenzen preis=%d guthaben=%d" % [
			id, preis, int(host.coins)])
		return false
	host.coins -= preis
	skill_stacks[id] = stufe + 1
	if is_instance_valid(host.player):
		var p = host.player
		if id == "skill_speed":
			p.call("add_speed_mult", 0.10)
		elif id == "skill_reload":
			p.cooldown_mult = maxf(0.45, float(p.cooldown_mult) * 0.92)
		elif id == "skill_damage":
			p.call("add_damage_mult", 0.12)
	print("[WSHOP][SKILL] id=%s stufe=%d preis=%d muenzen=%d speed=%.2f cooldown=%.2f damage=%.2f" % [
		id, int(skill_stacks[id]), preis, int(host.coins),
		float(host.player.speed_mult) if is_instance_valid(host.player) else 1.0,
		float(host.player.cooldown_mult) if is_instance_valid(host.player) else 1.0,
		float(host.player.damage_mult) if is_instance_valid(host.player) else 1.0])
	return true
