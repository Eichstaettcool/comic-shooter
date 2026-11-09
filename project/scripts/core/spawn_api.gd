class_name SpawnApi
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func spawn_monster_at(position: Vector2, mtype: int = -1, as_mini: bool = false):
	var monster = host.monster_scene.instantiate()
	monster.position = position
	monster.connect("monster_killed", Callable(host, "_on_monster_killed"))
	monster.connect("damage_player", Callable(host, "_on_monster_damage_player"))
	host.monster_container.add_child(monster)
	host._monster_cache.append(monster)     # Runde 33
	monster.call("set_gm", host)
	var t := mtype if mtype >= 0 else _pick_random_monster_type()
	monster.call("set_type", t)
	if not bool(monster.call("is_boss")):
		# Runde 34: Wellen-Balance auf normale Monster anwenden
		var bal: Dictionary = host.wave_balance()
		# v1.41 (B2): im RUNDEN-Modus gilt die Runden-Kurve (Rounds.hp_mult),
		# nicht die Endlos-Wellen-Tabelle - sonst bleibt R30 so leicht wie R1.
		if int(host.game_mode) == 2:
			var rm = host.get("rounds_mode")
			if rm != null:
				var rr: int = int(rm.get("round_no"))
				var rd: String = str(rm.get("difficulty"))
				bal = { "hp": Rounds.hp_mult_spawn(rr, rd), "spd": Rounds.spd_mult(rr) }
		monster.call("apply_wave_mult", float(bal["hp"]), float(bal["spd"]))
	if monster.call("is_boss"):
		# Runde 27: vorher stand hier "t == TYPE_BOSS" - damit waren die Biom-Bosse
		# (Mars/Jungle/Erde) und die neuen Mini-Bosse NICHT verbunden, die Bossbar
		# hat sich im Kampf also nie aktualisiert
		monster.connect("boss_hp", Callable(host, "_on_boss_hp"))
	if as_mini:
		monster.call("set_mini")
	# v1.41 (M6): Beleg, dass die neuen Unterstuetzungstypen wirklich spawnen
	if t == 31 or t == 32 or t == 33 or t == 34:
		print("[MON][SPAWN] typ=%d name=%s pos=(%.0f,%.0f) hp=%d" % [
			t, Rounds.type_name(t), position.x, position.y, int(monster.get("current_health"))])
	# Wellen-Modus: Zaehlung erfolgt zentral in _recount_wave() (Runde 31)
	return monster


func spawn_projectile(position: Vector2, dir: Vector2, dmg: int, spd: float, chain: int = 0) -> void:
	if host.projectile_scene == null:
		return
	var proj = host.projectile_scene.instantiate()
	proj.call("set_enemy", dmg)
	proj.position = position
	proj.set_direction(dir, spd)
	# Runde 55: Blitzkette - Treffer springt auf den Partner ueber
	proj.set("gm", host)
	proj.set("chain_hops", chain)
	host.ysort.add_child(proj)


func spawn_run_chest_at(pos: Vector2, rarity: String = "rare") -> void:
	# Garantierter Kisten-Drop (E2) - gleiche Kiste wie die im Level
	if host.chest_scene == null:
		print("[CHEST][FEHLER] chest_scene fehlt - kein Drop")
		return
	var chest = host.chest_scene.instantiate()
	chest.position = pos
	chest.connect("item_spawned", Callable(host, "_on_chest_item_spawned"))
	chest.gm = host
	chest.call("set_rarity", rarity)
	host.chest_container.add_child(chest)
	print("[CHEST][DROP] Kiste bei (%.0f,%.0f) seltenheit=%s" % [pos.x, pos.y, rarity])


func _pick_random_monster_type() -> int:
	var t := Time.get_ticks_msec() / 1000.0
	var r = randf()
	# Welten-Pool (Runde 12): Mars/Jungle haben eigene Gegner
	var pool: Array = host.map_data().get("pool", [])
	if not pool.is_empty():
		# Runde 35b: Gewichte pro Karte (Mars = mehr Schuetzen, Jungle = mehr
		# Pflanzen, Elektro = mehr Technik-Gegner)
		var mw: Dictionary = host._map_type_weights()
		if mw.is_empty():
			return int(pool[randi() % pool.size()])   # Planeten sind STRIKT getrennt
		var mtotal: float = 0.0
		for mt in pool:
			mtotal += float(mw.get(int(mt), 1.0))
		var mroll: float = randf() * mtotal
		for mt2 in pool:
			mroll -= float(mw.get(int(mt2), 1.0))
			if mroll <= 0.0:
				return int(mt2)
		return int(pool[randi() % pool.size()])
	# Biom-Spezialisten (Punkt 5): je Biom eigene Gegner, die die Mechanik nutzen
	# Karten (Runde 11): bias multipliziert die Chance
	var bias = float(host.map_data().get("bias", 1.0))
	var biome_roll := randf()
	if biome_roll < clampf(0.22 * bias, 0.0, 0.85) and t > 20.0:
		match host.biome_id:
			"desert":
				return 8     # GRABER
			"ice":
				return 9     # EISGOLEM
			"lava":
				return 10    # FEUERWERFER
	if r < 0.28:
		return 0  # GREEN
	elif r < 0.50:
		return 1  # RED
	elif r < 0.64:
		return 2  # BLUE
	elif r < 0.74:
		return 3  # PURPLE
	elif r < 0.84:
		return 4 if t > 60.0 else 0   # YELLOW (Werfer)
	elif r < 0.92:
		return 5 if t > 90.0 else 1   # PINK (Splitter)
	else:
		return 6 if t > 120.0 else 2  # ORANGE (Panzer)

# Konstanten aus der Fassade (ui_manager.gd)
const TYPE_BOSS := 7  # Index im MonsterType-Enum
