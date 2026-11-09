class_name MonsterStats
extends RefCounted

# Runde 138: Gegner-Tabellen aus monster_ai.gd
var host: Node = null

# Spiegel von monster_ai.gd - Enum ist nicht ueber host erreichbar,
# Reihenfolge muss identisch bleiben.
enum MonsterType { GREEN, RED, BLUE, PURPLE, YELLOW, PINK, ORANGE, BOSS, BURROWER, GOLEM, PYRO, MARS_ALIEN, MARS_ROVER, ROBO_APE, BIG_FLOWER, MARS_DRONE, MARS_GUARD, ROBO_TIGER, VINE_TRAP, BOSS_MARS, BOSS_JUNGLE, BOSS_EARTH, MINI_EARTH, MINI_MARS, MINI_JUNGLE, VOLT_DRONE, VOLT_TROOPER, VOLT_SPIDER, BOSS_VOLT, VOLT_SPOOLER, MINI_VOLT, SPORENBRUT, SCHILD, HEROLD, SPORE }

const MINI_ABILITIES: Dictionary = {
	"earth": { "name": "ERDBEBEN", "color": Color(0.95, 0.62, 0.20), "dmg": 3, "cd": 6.0, "kind": "quake" },
	"mars": { "name": "FEUERSTURM", "color": Color(1.0, 0.35, 0.15), "dmg": 4, "cd": 5.5, "kind": "fire" },
	"jungle": { "name": "DORNENWURZ", "color": Color(0.40, 0.90, 0.35), "dmg": 3, "cd": 6.5, "kind": "spike" },
	"volt": { "name": "BLITZKETTE", "color": Color(0.45, 0.75, 1.0), "dmg": 3, "cd": 4.5, "kind": "shock" },
}

const type_stats: Dictionary = {   # Runde 34: const -> statische Helfer fuer Geist-Sprites
	MonsterType.GREEN: { "speed": 60.0, "health": 3, "damage": 1, "points": 10, "texture_key": "monster_green" },
	MonsterType.RED: { "speed": 140.0, "health": 2, "damage": 1, "points": 20, "texture_key": "monster_red" },
	MonsterType.BLUE: { "speed": 90.0, "health": 4, "damage": 1, "points": 30, "texture_key": "monster_blue" },
	MonsterType.PURPLE: { "speed": 70.0, "health": 6, "damage": 2, "points": 50, "texture_key": "monster_purple" },
	MonsterType.YELLOW: { "speed": 75.0, "health": 3, "damage": 1, "points": 15, "texture_key": "monster_yellow" },
	MonsterType.PINK: { "speed": 105.0, "health": 4, "damage": 1, "points": 12, "texture_key": "monster_pink" },
	MonsterType.ORANGE: { "speed": 45.0, "health": 12, "damage": 1, "points": 60, "texture_key": "monster_orange" },
	MonsterType.BOSS: { "speed": 38.0, "health": 120, "damage": 2, "points": 300, "texture_key": "boss", "scale": 1.9, "radius": 34.0 },
	# Runde 16 (B1): eigener Boss je Biom, deutlich mehr Leben + eigene Angriffe
	MonsterType.BOSS_MARS: { "speed": 44.0, "health": 180, "damage": 3, "points": 900, "texture_key": "boss_mars", "scale": 0.42, "radius": 52.0 },
	MonsterType.BOSS_JUNGLE: { "speed": 60.0, "health": 200, "damage": 3, "points": 1000, "texture_key": "boss_jungle", "scale": 0.44, "radius": 50.0 },
	MonsterType.BOSS_EARTH: { "speed": 46.0, "health": 230, "damage": 3, "points": 1100, "texture_key": "boss_earth", "scale": 0.42, "radius": 54.0, "armor": 0.20 },
	# Runde 27: eigene Mini-Bosse (alle 5 Wellen) - je Biom ein eigenes Design
	MonsterType.MINI_EARTH: { "speed": 100.0, "health": 125, "damage": 2, "points": 260, "texture_key": "boss_mini_earth", "scale": 0.45, "radius": 34.0 },
	MonsterType.MINI_MARS: { "speed": 90.0, "health": 120, "damage": 2, "points": 260, "texture_key": "boss_mini_mars", "scale": 0.45, "radius": 34.0 },
	MonsterType.MINI_JUNGLE: { "speed": 108.0, "health": 115, "damage": 2, "points": 260, "texture_key": "boss_mini_jungle", "scale": 0.45, "radius": 34.0 },
	# Runde 54: eigener Mini-Boss fuer die Elektro-Karte (vorher Erd-Kaefer)
	MonsterType.MINI_VOLT: { "speed": 96.0, "health": 130, "damage": 2, "points": 280, "texture_key": "boss_mini_volt", "scale": 0.45, "radius": 34.0, "armor": 0.15 },
	# Runde 35: Elektro-Welt - Schwebedrohne, Spulentrooper, Spinnenspule
	MonsterType.VOLT_DRONE: { "speed": 120.0, "health": 6, "damage": 2, "points": 70, "texture_key": "monster_volt_drone" },
	MonsterType.VOLT_TROOPER: { "speed": 78.0, "health": 16, "damage": 2, "points": 95, "texture_key": "monster_volt_trooper" },
	MonsterType.VOLT_SPIDER: { "speed": 105.0, "health": 10, "damage": 2, "points": 85, "texture_key": "monster_volt_spider" },
	MonsterType.BOSS_VOLT: { "speed": 50.0, "health": 260, "damage": 3, "points": 1400, "texture_key": "boss_volt", "scale": 0.45, "radius": 54.0 },
	# Runde 49: Spulentrooper - langsam, zaeh, schiesst eine 3er-Salve
	MonsterType.VOLT_SPOOLER: { "speed": 52.0, "health": 22, "damage": 3, "points": 130, "texture_key": "monster_volt_spooler" },
	# Biom-Spezialisten (Punkt 5)
	MonsterType.BURROWER: { "speed": 95.0, "health": 5, "damage": 1, "points": 45, "texture_key": "monster_burrower" },
	MonsterType.GOLEM: { "speed": 40.0, "health": 16, "damage": 1, "points": 70, "texture_key": "monster_golem" },
	MonsterType.PYRO: { "speed": 65.0, "health": 5, "damage": 1, "points": 55, "texture_key": "monster_pyro" },
	# Runde 12: Welten-spezifische Gegner
	MonsterType.MARS_ALIEN: { "speed": 72.0, "health": 4, "damage": 1, "points": 55, "texture_key": "monster_mars_alien" },
	MonsterType.MARS_ROVER: { "speed": 46.0, "health": 14, "damage": 2, "points": 85, "texture_key": "monster_mars_rover" },
	MonsterType.ROBO_APE: { "speed": 78.0, "health": 6, "damage": 1, "points": 65, "texture_key": "monster_robo_ape" },
	MonsterType.BIG_FLOWER: { "speed": 0.0, "health": 11, "damage": 1, "points": 90, "texture_key": "monster_big_flower" },
	# Runde 14: eigene Eigenschaften je Planet
	MonsterType.MARS_DRONE: { "speed": 132.0, "health": 3, "damage": 2, "points": 50, "texture_key": "monster_mars_drone", "kamikaze": true },
	MonsterType.MARS_GUARD: { "speed": 38.0, "health": 22, "damage": 2, "points": 110, "texture_key": "monster_mars_guard", "armor": 0.5 },
	MonsterType.ROBO_TIGER: { "speed": 124.0, "health": 8, "damage": 1, "points": 75, "texture_key": "monster_robo_tiger" },
	MonsterType.VINE_TRAP: { "speed": 0.0, "health": 12, "damage": 2, "points": 90, "texture_key": "monster_vine_trap" },
	# v1.41 (M): drei Unterstuetzungs-Monster + die Spore als Teilungs-Kind
	MonsterType.SPORENBRUT: { "speed": 128.0, "health": 6, "damage": 1, "points": 40, "texture_key": "monster_sporenbrut", "split_into": 34, "split_count": 2, "split_hp": 0.4 },
	MonsterType.SCHILD: { "speed": 56.0, "health": 14, "damage": 2, "points": 75, "texture_key": "monster_schild", "front_block": 0.70, "front_winkel": 70.0 },
	MonsterType.HEROLD: { "speed": 48.0, "health": 9, "damage": 0, "points": 95, "texture_key": "monster_herold", "aura_radius": 180.0, "aura_speed": 1.25, "hp_faktor": 1.5 },
	MonsterType.SPORE: { "speed": 112.0, "health": 3, "damage": 1, "points": 12, "texture_key": "monster_spore", "lifetime": 8.0 }
}


func _setup_type_stats():
	var stats = type_stats[host.type]
	host.speed = stats["speed"]
	host.max_health = stats["health"]
	host.current_health = host.max_health
	host.damage_amount = stats["damage"]
	host.points_worth = stats["points"]
	host.sprite.texture = TextureManager.get_texture(stats["texture_key"])
	host.armor = float(stats.get("armor", 0.0))
	host.kamikaze = bool(stats.get("kamikaze", false))
	# v1.41 (M): Eigenheiten der drei Unterstuetzungstypen
	host.front_block = float(stats.get("front_block", 0.0))
	host.front_winkel = float(stats.get("front_winkel", 70.0))
	host.aura_radius = float(stats.get("aura_radius", 0.0))
	host.aura_speed = float(stats.get("aura_speed", 1.0))
	host.split_into = int(stats.get("split_into", -1))
	host.split_count = int(stats.get("split_count", 0))
	host.split_hp = float(stats.get("split_hp", 0.0))
	host.life_left = float(stats.get("lifetime", -1.0))
	host.speed_ref = host.speed
	if stats.has("hp_faktor"):
		var f: float = float(stats["hp_faktor"])
		host.max_health = maxi(1, int(round(float(host.max_health) * f)))
		host.current_health = host.max_health
		print("[MON][STATS] typ=%d hp_faktor=%.2f hp=%d" % [host.type, f, host.max_health])
	if host.type == MonsterType.SPORE:
		host.base_scale = Vector2(0.6, 0.6)
		host.sprite.scale = host.base_scale
		print("[MON][SPORE] lebensdauer=%.1fs hp=%d" % [host.life_left, host.max_health])
	# Biom-Bosse: eigene Groesse/Hitbox, echte PNGs weich gezeichnet
	if stats.has("scale"):
		host.base_scale = Vector2(float(stats["scale"]), float(stats["scale"]))
		host.sprite.scale = host.base_scale
		if host.collision_shape != null:
			host.collision_shape.scale = Vector2.ONE
			host.collision_shape.shape = CircleShape2D.new()
			host.collision_shape.shape.radius = float(stats.get("radius", 26.0))

	if str(stats.get("texture_key", "")).begins_with("boss_"):
		host.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Bosse wachsen mit der Welle (Nutzerwahl B1)
	if host.is_boss():
		var wv := 0
		if host.gm != null:
			wv = int(host.gm.wave)
		# Runde 26: staerkerer Zuwachs + start_hp NACH der Skalierung setzen
		host.current_health = int(round(float(host.current_health) * (1.0 + float(wv) * 0.18)))
		# Runde 27: max_health MUSS mit - sonst zeigt die Bossbar max < value
		# und der Balken verhaelt sich nicht wie das Leben des Bosses
		host.max_health = host.current_health
	host.start_hp = maxi(1, host.current_health)
	# Schwierigkeitsgrad (Runde 15): HP/Tempo/Schaden skalieren
	if host.gm != null and host.gm.has_method("diff_data"):
		var dd: Dictionary = host.gm.call("diff_data")
		host.current_health = maxi(1, int(round(float(host.current_health) * float(dd["hp"]))))
		# Runde 53: start_hp MUSS mit - sonst blieb der Basiswert (z.B. 230)
		# stehen, waehrend max_health auf 173 sank: Bossbar zeigte 173/230
		# und die Rage-Phase startete bei 115 statt 86 HP.
		host.max_health = host.current_health
		host.start_hp = maxi(1, host.current_health)
		host.speed *= float(dd["speed"])
		host.dmg_mult = float(dd["dmg"])
	if host.type == MonsterType.BOSS:
		host.base_scale = Vector2(2.3, 2.3)
	# Hitbox an die Groesse anpassen (Boss/Mini) — vorher blieb sie bei Radius 14!
	if host.collision_shape != null:
		host.collision_shape.scale = host.base_scale
	# Runde 53: Diagnose - welcher Typ hat welche Textur/Groesse bekommen?
	if host.is_boss():
		print("[BOSS][VISUAL] type=%d key=%s scale=%s hp=%d max=%d radius=%s" % [
			host.type, str(stats.get("texture_key", "?")), str(host.base_scale),
			host.current_health, host.max_health, str(stats.get("radius", -1))])
