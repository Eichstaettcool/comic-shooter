class_name BossesModule
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null

const MAP_COLS: int = 120
const MAP_ROWS: int = 80
const TILE_SIZE: int = 32


func _spawn_boss() -> void:
	if not is_instance_valid(host.player):
		host._bdiag("SPAWN", "ABGEBROCHEN: kein Spieler-Knoten")
		return
	# Erst spawnen, wenn der alte Boss besiegt ist
	if host.current_boss != null and is_instance_valid(host.current_boss) and not host.current_boss.is_queued_for_deletion():
		host._bdiag("SPAWN", "ABGEBROCHEN: es lebt noch ein Boss (%s hp=%d)" % [
			str(host.current_boss.get("type")), int(host.current_boss.get("current_health"))])
		return
	host._boss_count += 1
	# Boss etwas ausserhalb des Schirms spawnen
	var ang := randf_range(0, TAU)
	var pos = host.player.position + Vector2(cos(ang), sin(ang)) * 600.0
	var wmax := float(MAP_COLS * TILE_SIZE) - 200.0
	var hmax := float(MAP_ROWS * TILE_SIZE) - 200.0
	pos.x = clampf(pos.x, 200.0, wmax)
	pos.y = clampf(pos.y, 200.0, hmax)
	# Runde 49: Es darf nie zwei Bosse gleichzeitig geben. Wenn
	# current_boss schon lebt, wird der alte zuerst entfernt.
	if host.current_boss != null and is_instance_valid(host.current_boss) and not host.current_boss.is_queued_for_deletion():
		host.current_boss.queue_free()
	host.current_boss = host.spawn_monster_at(pos, _biome_boss_type())
	if host.current_boss == null:
		host._bdiag("SPAWN", "WARNUNG: Boss-Spawn null - zweiter Versuch")
		pos = host.player.position + Vector2(cos(ang + PI), sin(ang + PI)) * 380.0
		host.current_boss = host.spawn_monster_at(pos, _biome_boss_type())
	host._boss_active = host.current_boss != null
	host.ui_manager.set_boss_name(_biome_boss_name())
	host.ui_manager.show_boss_warning(host._boss_count)
	if host.current_boss != null:
		# Runde 26: echte Werte statt hart 40/40
		var bmx: int = int(host.current_boss.start_hp)
		host.ui_manager.update_boss_hp(int(host.current_boss.current_health), maxi(1, bmx))
		host._bdiag("SPAWN", "Boss #%d type=%s hp=%d/%d pos=%s map=%s biome=%s" % [
			host._boss_count, str(host.current_boss.get("type")), int(host.current_boss.current_health),
			bmx, str(pos.round()), host.active_map, host.biome_id])
		host._boss_last_type = str(host.current_boss.get("type"))
	else:
		host._bdiag("SPAWN", "FEHLER: spawn_monster_at() lieferte null (type=%d)" % _biome_boss_type())


func _biome_boss_type() -> int:
	match host.biome_id:
		"volt":
			# Runde 49: BOSS_VOLT ist der Enum-Index 28. Vorher stand
			# hier 27 (VOLT_SPIDER) - der "Volt-Boss" war damit ein
			# normaler Spinnen-Gegner: kein Boss-Muster, keine Weak
			# Points, kein Boss-Balken. Genau das war die Meldung
			# "der Boss greift nicht an".
			return 28
		"mars":
			return 19
		"jungle":
			return 20
		_:
			return 21


func _biome_boss_name() -> String:
	match host.biome_id:
		"mars":
			return "METEOR-GOLEM"
		"jungle":
			return "ROBO-AFFE-KÖNIG"
		_:
			return "SPLITTER-KÖNIG"


func _mini_boss_type() -> int:
	# Runde 27: Mini-Bosse je Biom (Papagei / Sonde / Kaefer)
	match host.active_map:
		"mars": return 23
		"jungle": return 24
		"volt":
			# Runde 54: eigener Volt-Mini (Index 30) statt Erd-Kaefer
			host._bdiag("MINI", "Volt-Karte -> MINI_VOLT (Spule)")
			return 30
		_: return 22


func _mini_boss_display_name(t: int) -> String:
	match t:
		22:
			return "ERD-KÄFER"
		23:
			return "MARS-SONDE"
		24:
			return "DSCHUNGEL-PAPAGEI"
		30:
			return "VOLT-SPULE"
	return "MINI-BOSS"


func name_miniboss(monster: Node) -> void:
	# E1: Name an der Boss-Leiste, wie beim grossen Boss
	if monster == null:
		return
	var nm: String = _mini_boss_display_name(int(monster.get("type")))
	host.ui_manager.set_boss_name(nm)
	print("[SPAWN][MINIBOSS] name=%s an der Leiste" % nm)


func on_miniboss_killed(dt: float, pos: Vector2 = Vector2.ZERO) -> void:
	# E2: 5x Gold eines Normalgegners + 1 Kiste, mit Belegzeile
	var normal_points: int = 20          # ein normaler Treffer im Mittelfeld
	var normal_gold: int = maxi(1, int(round(float(normal_points) * 0.24 * float(host.diff_data()["coins"]))))
	var bonus: int = normal_gold * 5
	host.gold += bonus
	if host.game_mode == 1:
		# Wellen-Modus: Muenzen landen im Shop-Beutel
		host.slot_coins[host.my_slot] = int(host.slot_coins.get(host.my_slot, 0)) + bonus
		host.coins = int(host.slot_coins[host.my_slot])
	print("[SPAWN][MINIBOSS] kill nach %.1fs, gold=+%d (5x %d, gesamt %d)" % [dt, bonus, normal_gold, host.gold])
	if pos == Vector2.ZERO and is_instance_valid(host.player):
		pos = host.player.global_position + Vector2(randf_range(-70, 70), randf_range(-70, 70))
	host.spawn_run_chest_at(pos, "rare")
	host.ui_manager.show_banner("MINI-BOSS BESIEGT  ·  +%d GOLD  ·  KISTE" % bonus, Color(0.99, 0.85, 0.35))
