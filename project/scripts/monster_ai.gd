# MonsterAI.gd - Monster-Verhalten: folgt Spieler, 7 Typen mit Funktionen
# GREEN/RED/BLUE/PURPLE wie bisher, YELLOW=Werfer, PINK=Splitter, ORANGE=Panzer
extends CharacterBody2D

signal monster_killed(points: int)
signal damage_player(damage: int)
signal boss_hp(current: int, max: int)

enum MonsterType { GREEN, RED, BLUE, PURPLE, YELLOW, PINK, ORANGE, BOSS, BURROWER, GOLEM, PYRO, MARS_ALIEN, MARS_ROVER, ROBO_APE, BIG_FLOWER, MARS_DRONE, MARS_GUARD, ROBO_TIGER, VINE_TRAP, BOSS_MARS, BOSS_JUNGLE, BOSS_EARTH, MINI_EARTH, MINI_MARS, MINI_JUNGLE, VOLT_DRONE, VOLT_TROOPER, VOLT_SPIDER, BOSS_VOLT, VOLT_SPOOLER, MINI_VOLT }

var type: MonsterType = MonsterType.GREEN
var speed: float = 80.0
var max_health: int = 3
var current_health: int = 3
var damage_amount: int = 1
var points_worth: int = 10
var target: Node2D = null
var damage_cooldown: float = 0.0
var facing_direction: Vector2 = Vector2.LEFT
var anim_time: float = 0.0
var gm: Node = null
var shoot_timer: float = 1.0
var base_scale := Vector2.ONE
# Boss-Angriffsmuster (Punkt 4)
var boss_state: int = 0            # 0 = Kugelfächer, 1 = Anlauf, 2 = Beschwören
var boss_timer: float = 3.0
var boss_telegraph: float = 0.0
var boss_charge_dir: Vector2 = Vector2.ZERO
# Graber
var burrow_timer: float = 3.0
# Rover-Anlauf (Runde 12)
var charge_timer: float = 2.8
var charge_state: int = 0
var charge_hold: float = 0.0
var charge_dir: Vector2 = Vector2.ZERO
var _escape_timer: float = 0.0
# Eigenschaften (Runde 14)
var armor: float = 0.0
var kamikaze: bool = false
var dmg_mult: float = 1.0          # Schwierigkeits-Faktor fuer Kontaktschaden
var ranged: bool = false          # schiesst dieser Gegner in diesem Frame?
var start_hp: int = 1             # fuer Phase 2
var warn_sprite: Sprite2D = null   # Ladeblitz als Vorwarnung
# Runde 49: Miniboss-HP-Bar (schwebt ueber dem Kopf)
var mini_bar_bg: ColorRect = null
var mini_bar_fill: ColorRect = null
# Runde 49: Aura (zeigt die aktive Biom-Faehigkeit)
var aura: Sprite2D = null
var aura_tween: Tween = null
var ability_cd: float = 0.0
var overcharged: bool = false       # Runde 54: Volt-Spule, Phase 2
var active_ability: Dictionary = {}
# Runde 49: Weak Points (Schild/Kern) - Schaden-Multiplikator
var weak_points: Array = []         # [{ "pos": Vector2, "r": float, "mult": float }]
var hit_flash: float = 0.0
# Runde 49: Dash-Angriff
var dash_state: int = 0             # 0 = kein Dash, 1 = Aufwind, 2 = Angriff
var dash_dir: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_cycle: int = 0
# Runde 49: Eigenes Muster fuer die Mini-Bosse
var mini_state: int = 0
# Runde 49: Basis-Position des Sprites - die schwebende Drohne
# braucht einen Anker, um sich relativ dazu zu bewegen
var base_sprite_pos: Vector2 = Vector2.ZERO

# Runde 49: Biom-spezifische Miniboss-Faehigkeiten.
# Die Aura-Farbe und der Effekt folgen der Faehigkeit des aktuellen Bioms.
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
	MonsterType.VINE_TRAP: { "speed": 0.0, "health": 12, "damage": 2, "points": 90, "texture_key": "monster_vine_trap" }
}

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("monsters")
	collision_layer = 2
	collision_mask = 17
	_setup_type_stats()
	# Runde 49: Sprite-Basis merken (fuer das Schweben der Drohne)
	base_sprite_pos = sprite.position
	# Runde 49: Boss-Objekte aufbauen. ACHTUNG: set_type() wird erst
	# NACH add_child() gerufen - _ready() sieht also noch den
	# Default-Typ. Deshalb wird _apply_boss_visuals() auch in set_type()
	# aufgerufen (idempotent).
	_apply_boss_visuals()


func _apply_boss_visuals() -> void:
	# Runde 49: Idempotent - baut HP-Bar/Aura/Weak-Points je nach Typ
	if is_mini_boss():
		if mini_bar_bg == null:
			_build_mini_bar()
		elif mini_bar_fill != null:
			# Runde 49c: Die Bar muss zum Boss passen - sie haengt
			# an base_scale, das sich mit dem Typ aendert.
			var sc: float = base_scale.x
			mini_bar_bg.scale = Vector2(sc, sc)
			mini_bar_bg.position = Vector2(-48, -74)
		if aura == null:
			_build_aura()
	if is_boss() and weak_points.is_empty():
		_setup_weak_points()


func _update_mini_bar() -> void:
	# Runde 49: Die Bar zeigt current_health/max_health
	if mini_bar_fill == null or mini_bar_bg == null:
		return
	var frac: float = 0.0
	if max_health > 0:
		frac = clampf(float(current_health) / float(max_health), 0.0, 1.0)
	mini_bar_fill.size.x = 116.0 * frac
	# Farbe: gruen -> gelb -> rot
	if frac > 0.5:
		mini_bar_fill.color = Color(0.40, 0.88, 0.35)
	elif frac > 0.25:
		mini_bar_fill.color = Color(0.98, 0.80, 0.25)
	else:
		mini_bar_fill.color = Color(0.95, 0.25, 0.30)
	# Die Bar folgt der Skalierung des Monsters
	var sc: float = base_scale.x
	mini_bar_bg.scale = Vector2(sc, sc)
	mini_bar_bg.position = Vector2(-60.0 * sc, -110.0 * sc)


func _build_mini_bar() -> void:
	# Runde 49: Schwebende HP-Bar ueber dem Miniboss-Kopf
	# Runde 49c: Die Bar war 120 px breit bei einem nur 100 px hohen
	# Boss und lag bei -110 - sie war breiter als der Boss selbst und
	# schwebte abgeschnitten daneben. Jetzt: sie skaliert MIT dem
	# Boss und sitzt direkt ueber dem Kopf.
	var sc: float = base_scale.x
	mini_bar_bg = ColorRect.new()
	mini_bar_bg.name = "MiniBarBg"
	mini_bar_bg.color = Color(0.08, 0.06, 0.10, 0.88)
	mini_bar_bg.size = Vector2(96, 13)
	mini_bar_bg.position = Vector2(-48, -74)
	mini_bar_bg.scale = Vector2(sc, sc)
	mini_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mini_bar_bg.z_index = 40
	add_child(mini_bar_bg)
	mini_bar_fill = ColorRect.new()
	mini_bar_fill.name = "MiniBarFill"
	mini_bar_fill.color = Color(0.95, 0.25, 0.30)
	mini_bar_fill.size = Vector2(92, 9)
	mini_bar_fill.position = Vector2(2, 2)
	mini_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mini_bar_bg.add_child(mini_bar_fill)


func _build_aura() -> void:
	# Runde 53: FIX - hier stand "monster_green". Dadurch erschien hinter
	# dem neuen Boss-Sprite ein ALTES Monster-Sprite, das beim Einsatz
	# der Faehigkeit pulsierte ("alte Textur bewegt sich im Hintergrund").
	aura = Sprite2D.new()
	aura.name = "AbilityAura"
	aura.texture = TextureManager.get_texture("glow_common")
	aura.modulate = Color(1, 1, 1, 0)
	aura.scale = Vector2(1.6, 1.6)
	aura.z_index = -5
	add_child(aura)
	print("[BOSS][VISUAL] AbilityAura gebaut: texture=glow_common (vorher monster_green)")


func _setup_weak_points() -> void:
	if type == MonsterType.MINI_VOLT:
		# Runde 54: Nur der leuchtende Kern ist verwundbar (Weltkoordinaten,
		# unskaliert: Kern sitzt ~16 px unter der Mitte).
		weak_points = [ { "pos": Vector2(2, 16), "r": 16.0, "mult": 2.5 } ]
		return
	# Runde 49: Zwei Weak Points pro Boss - ein Schild (links) und ein
	# Kern (oben). Treffer dort richten den SCHILD-Multiplikator.
	weak_points = [
		{ "pos": Vector2(-46, -6), "r": 30.0, "mult": 2.5 },
		{ "pos": Vector2(0, -58), "r": 26.0, "mult": 2.5 },
	]


func _biome_key() -> String:
	# Runde 54: FIX - hier stand gm.active_map_id(), diese Methode gibt es
	# nicht. Dadurch fiel JEDER Mini-Boss auf "earth" zurueck und warf
	# immer ERDBEBEN, auch auf Mars/Jungle/Volt. Jetzt entscheidet der Typ.
	match type:
		MonsterType.MINI_MARS: return "mars"
		MonsterType.MINI_JUNGLE: return "jungle"
		MonsterType.MINI_VOLT: return "volt"
		MonsterType.MINI_EARTH: return "earth"
	if gm != null and gm.has_method("active_map_id"):
		var mid: String = str(gm.call("active_map_id"))
		if MINI_ABILITIES.has(mid):
			return mid
	return "earth"


func _weak_point_at(local_pos: Vector2) -> Dictionary:
	# Runde 49: Liefert den Weak-Point, in den der Einschlag fiel
	for wp in weak_points:
		var d: Vector2 = local_pos - (wp["pos"] as Vector2)
		if d.length() <= float(wp["r"]):
			return wp
	return {}


func _trigger_ability() -> void:
	# Runde 49: Die Biom-Faehigkeit ausloesen - Aura leuchtet in der
	# Faehigkeitsfarbe, der Effekt wird angewendet.
	var ab: Dictionary = MINI_ABILITIES.get(_biome_key(), MINI_ABILITIES["earth"])
	active_ability = ab
	print("[BOSS][ABILITY] cast: kind=%s name=%s spieler=%d type=%d" % [
		str(ab.get("kind", "")), str(ab.get("name", "?")), _players_alive().size(), type])
	var col: Color = ab.get("color", Color(1, 1, 1))
	if aura != null:
		aura.modulate = Color(col.r, col.g, col.b, 0.85)
		aura.scale = Vector2(1.6, 1.6)
		if aura_tween != null and aura_tween.is_valid():
			aura_tween.kill()
		aura_tween = aura.create_tween()
		aura_tween.set_loops(3)
		aura_tween.tween_property(aura, "scale", Vector2(2.3, 2.3), 0.35).set_trans(Tween.TRANS_QUAD)
		aura_tween.tween_property(aura, "scale", Vector2(1.6, 1.6), 0.35)
	# Runde 54: Faehigkeits-Art. "shock" = Blitzkette (Elektro-Mini),
	# alles andere = der bisherige 8er-Ring.
	if str(ab.get("kind", "")) == "shock":
		var tgt = _nearest_player()
		if tgt == null:
			print("[BOSS][ABILITY] FEHLER: kein Zielspieler gefunden (players=%s)" % str(gm.get("players").keys() if gm != null else "?"))
		if tgt != null and gm != null and gm.has_method("spawn_projectile"):
			var base: Vector2 = (tgt.global_position - global_position).normalized()
			for k in range(3):
				var a2: float = deg_to_rad(-12.0 + 12.0 * float(k))
				var d3: Vector2 = base.rotated(a2)
				gm.call("spawn_projectile", global_position + d3 * 46.0, d3, int(ab.get("dmg", 3)), 300.0, 1)
			print("[BOSS][ABILITY] Blitzkette: 3 Blitze auf Slot %s (Kette beim Treffer)" % str(tgt.get("player_id")))
	elif gm != null and gm.has_method("spawn_projectile"):
		for k in range(8):
			var ang: float = TAU * float(k) / 8.0
			var d2 := Vector2(cos(ang), sin(ang))
			gm.call("spawn_projectile", global_position + d2 * 50.0, d2, int(ab.get("dmg", 2)), 210.0)
	ability_cd = 3.0 if overcharged else float(ab.get("cd", 6.0))


func _players_alive() -> Array:
	# Runde 54: alle lebenden Spieler (nicht downed, kein Zuschauer)
	var out: Array = []
	if gm == null:
		return out
	var ps = gm.get("players")
	if ps == null:
		return out
	for s in ps.keys():
		var p = ps[s]
		if not is_instance_valid(p):
			continue
		if bool(p.get("downed")) or bool(p.get("spectating")):
			continue
		out.append(p)
	return out


func _nearest_player():
	var best = null
	var bd: float = 1e20
	for p in _players_alive():
		var d: float = global_position.distance_to(p.global_position)
		if d < bd:
			bd = d
			best = p
	return best


func _setup_type_stats():
	var stats = type_stats[type]
	speed = stats["speed"]
	max_health = stats["health"]
	current_health = max_health
	damage_amount = stats["damage"]
	points_worth = stats["points"]
	sprite.texture = TextureManager.get_texture(stats["texture_key"])
	armor = float(stats.get("armor", 0.0))
	kamikaze = bool(stats.get("kamikaze", false))
	# Biom-Bosse: eigene Groesse/Hitbox, echte PNGs weich gezeichnet
	if stats.has("scale"):
		base_scale = Vector2(float(stats["scale"]), float(stats["scale"]))
		sprite.scale = base_scale
		if collision_shape != null:
			collision_shape.scale = Vector2.ONE
			collision_shape.shape = CircleShape2D.new()
			collision_shape.shape.radius = float(stats.get("radius", 26.0))

	if str(stats.get("texture_key", "")).begins_with("boss_"):
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Bosse wachsen mit der Welle (Nutzerwahl B1)
	if is_boss():
		var wv := 0
		if gm != null:
			wv = int(gm.wave)
		# Runde 26: staerkerer Zuwachs + start_hp NACH der Skalierung setzen
		current_health = int(round(float(current_health) * (1.0 + float(wv) * 0.18)))
		# Runde 27: max_health MUSS mit - sonst zeigt die Bossbar max < value
		# und der Balken verhaelt sich nicht wie das Leben des Bosses
		max_health = current_health
	start_hp = maxi(1, current_health)
	# Schwierigkeitsgrad (Runde 15): HP/Tempo/Schaden skalieren
	if gm != null and gm.has_method("diff_data"):
		var dd: Dictionary = gm.call("diff_data")
		current_health = maxi(1, int(round(float(current_health) * float(dd["hp"]))))
		# Runde 53: start_hp MUSS mit - sonst blieb der Basiswert (z.B. 230)
		# stehen, waehrend max_health auf 173 sank: Bossbar zeigte 173/230
		# und die Rage-Phase startete bei 115 statt 86 HP.
		max_health = current_health
		start_hp = maxi(1, current_health)
		speed *= float(dd["speed"])
		dmg_mult = float(dd["dmg"])
	if type == MonsterType.BOSS:
		base_scale = Vector2(2.3, 2.3)
	# Hitbox an die Groesse anpassen (Boss/Mini) — vorher blieb sie bei Radius 14!
	if collision_shape != null:
		collision_shape.scale = base_scale
	# Runde 53: Diagnose - welcher Typ hat welche Textur/Groesse bekommen?
	if is_boss():
		print("[BOSS][VISUAL] type=%d key=%s scale=%s hp=%d max=%d radius=%s" % [
			type, str(stats.get("texture_key", "?")), str(base_scale),
			current_health, max_health, str(stats.get("radius", -1))])

func set_type(t: MonsterType) -> void:
	type = t
	_setup_type_stats()
	# Runde 49: Boss-Objekte (HP-Bar, Aura, Weak-Points) fuer den
	# neuen Typ aufbauen - set_type() laeuft nach add_child(),
	# also NACH _ready().
	_apply_boss_visuals()

func set_target(t: Node2D) -> void:
	target = t

func set_gm(g: Node) -> void:
	gm = g

# Mini-Version (Splitter-Kinder)
func set_mini() -> void:
	max_health = 2
	current_health = 2
	points_worth = 4
	base_scale = Vector2(0.65, 0.65)
	if collision_shape != null:
		collision_shape.scale = base_scale

# --- LAN-Geist (Client): keine KI, Position kommt vom Host ---
var ghost: bool = false
var net_id: int = 0
var ghost_target_pos: Vector2 = Vector2.ZERO
var ghost_hp: int = 0

func setup_ghost(gid: int, mtype: int, x: float, y: float, hp_max: int) -> void:
	ghost = true
	net_id = gid
	position = Vector2(x, y)
	ghost_target_pos = position
	set_type(mtype)
	max_health = hp_max
	current_health = hp_max
	ghost_hp = hp_max
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)   # keine KI, kein Kontakt
	set_process(true)

func sync_ghost(x: float, y: float, hp: int, angle_deg: float) -> void:
	ghost_target_pos = Vector2(x, y)
	if hp < ghost_hp:
		_flash_hit()
	ghost_hp = hp
	current_health = hp
	if sprite != null:
		sprite.flip_h = cos(deg_to_rad(angle_deg)) < 0.0

func _flash_hit() -> void:
	if sprite == null:
		return
	sprite.modulate = Color(2.2, 2.2, 2.2)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1, 1, 1), 0.12)

func _process(delta: float) -> void:
	if not ghost or sprite == null:
		return
	# Position weich nachziehen + Comic-Wackeln weiterlaufen lassen
	position = position.lerp(ghost_target_pos, clampf(delta * 12.0, 0.0, 1.0))
	anim_time += delta
	var bob := sin(anim_time * 9.0 + type * 2.0) * 0.06
	sprite.scale = Vector2((1.0 + bob) * base_scale.x, (1.0 - bob) * base_scale.y)

# BOSS: groß + Herzleiste im HUD
func is_boss() -> bool:
	return type == MonsterType.BOSS or type == MonsterType.BOSS_MARS or type == MonsterType.BOSS_JUNGLE 		or type == MonsterType.BOSS_EARTH or type == MonsterType.BOSS_VOLT or is_mini_boss()

static func ghost_texture_key(mtype: int) -> String:
	# Runde 34: Client-Geister sind nur noch ein Sprite (kein Monster-Scene)
	var st: Dictionary = type_stats.get(mtype, {})
	return str(st.get("texture_key", "monster_green"))

static func ghost_scale(mtype: int) -> float:
	var st: Dictionary = type_stats.get(mtype, {})
	return float(st.get("scale", 1.0))

func apply_wave_mult(hp_mult: float, spd_mult: float) -> void:
	# Runde 34: Balance-Tabelle (HP/Speed der aktuellen Welle)
	if hp_mult > 0.0:
		max_health = maxi(1, int(round(float(max_health) * hp_mult)))
		current_health = max_health
	if spd_mult > 0.0:
		speed *= spd_mult

func counts_for_wave() -> bool:
	# Runde 31: Rankenfallen und Pflanzen sind Hindernisse (sie schiessen bzw.
	# schaden bei Beruehrung), zaehlen aber NICHT zum Wellen-Fortschritt - sie
	# waren sonst schwer zu finden und blockierten den Wellenabschluss.
	return type != MonsterType.VINE_TRAP and type != MonsterType.BIG_FLOWER

func is_mini_boss() -> bool:
	return type == MonsterType.MINI_EARTH or type == MonsterType.MINI_MARS or type == MonsterType.MINI_JUNGLE or type == MonsterType.MINI_VOLT


func is_biome_boss() -> bool:
	# Runde 49: Die Biom-Bosse - als PREDICATE, damit ein neuer
	# Boss-Typ nicht wieder aus der Liste fällt (das war der Grund,
	# warum der Volt-Boss nicht angriff).
	return type == MonsterType.BOSS_MARS or type == MonsterType.BOSS_JUNGLE \
		or type == MonsterType.BOSS_EARTH or type == MonsterType.BOSS_VOLT


func _mini_boss_pattern(delta: float, direction: Vector2, dist: float, spd_mult: float) -> void:
	# Runde 49: Eigenes Muster fuer die Mini-Bosse - sie jagen den
	# Spieler, feuern in Wellen und nutzen ihre Biom-Faehigkeit.
	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0
	boss_timer -= delta
	match mini_state:
		0:
			# Anrennen
			velocity = direction * speed * spd_mult
			sprite.scale = base_scale
			shoot_timer -= delta
			if shoot_timer <= 0.0 and gm != null and dist < 560.0:
				shoot_timer = 2.4
				for k in range(-1, 2):
					var d2 := direction.rotated(float(k) * 0.26)
					gm.call("spawn_projectile", global_position + d2 * 44.0, d2, int(damage_amount), 230.0)
			if boss_timer <= 0.0:
				mini_state = 1
				boss_timer = 1.1
		1:
			# Pause mit Aufblitzen (Telegraph fuer die Faehigkeit)
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
			var puff: float = 1.0 + 0.20 * sin(boss_timer * 28.0)
			sprite.scale = Vector2(base_scale.x * puff, base_scale.y * puff)
			if boss_timer <= 0.0:
				sprite.scale = base_scale
				_trigger_ability()
				mini_state = 0
				boss_timer = 3.4

func _physics_process(delta: float) -> void:
	# Lauf-Wackeln (Comic-Squash)
	anim_time += delta
	# Runde 49: Der Weak-Point-Blitz verblasst wieder
	if hit_flash > 0.0:
		hit_flash -= delta
		if hit_flash <= 0.0:
			sprite.modulate = Color(1, 1, 1)
	# Runde 49: Miniboss-HP-Bar fuellen + Biom-Faehigkeit ausloesen
	if is_mini_boss():
		# Runde 54: Volt-Spule geht ab 35 % Leben in Ueberladung
		if type == MonsterType.MINI_VOLT and not overcharged and max_health > 0 \
				and current_health <= int(float(max_health) * 0.35):
			overcharged = true
			speed *= 1.35
			if aura != null:
				aura.modulate = Color(0.55, 0.85, 1.0, 0.55)
				aura.scale = Vector2(2.0, 2.0)
			print("[BOSS][PHASE] Volt-Spule ueberladen: hp=%d/%d speed=%.0f cd=3.0" % [
				current_health, max_health, speed])
		_update_mini_bar()
		ability_cd -= delta
		if ability_cd <= 0.0:
			_trigger_ability()
	var bob := sin(anim_time * 9.0 + type * 2.0) * 0.06
	sprite.scale = Vector2((1.0 + bob) * base_scale.x, (1.0 - bob) * base_scale.y)

	if damage_cooldown > 0:
		damage_cooldown -= delta

	# Sicherheitsnetz (Bugfix Runde 9): nie ausserhalb der Weltwand feststecken,
	# sonst ist eine Welle nicht raeumbar (Monster unsichtbar hinter der Grenze).
	_escape_timer += delta
	if _escape_timer >= 1.0 and gm != null and gm.has_method("get_map_bounds"):
		_escape_timer = 0.0
		var wb: Rect2 = gm.call("get_map_bounds")
		if not wb.has_point(global_position):
			global_position = Vector2(
				clampf(global_position.x, wb.position.x + 90.0, wb.end.x - 90.0),
				clampf(global_position.y, wb.position.y + 90.0, wb.end.y - 90.0))

	# Korruptionszonen-Boost + Biom-Tint + Frost-Buff
	var zone_boost := 1.0
	var tint := Color(1, 1, 1)
	if gm != null and gm.has_method("is_corrupted") and gm.is_corrupted(global_position):
		zone_boost = 1.35
		tint = Color(1.0, 0.72, 0.72)
	# Karten-Tempo (Runde 11): Wueste/… geben Monstern mehr Tempo
	if gm != null and gm.has_method("get_monster_speed_mult"):
		zone_boost *= float(gm.call("get_monster_speed_mult"))
	if gm != null and gm.has_method("get_biome_tint"):
		tint *= gm.get_biome_tint()
	var frost := 1.0
	if gm != null and gm.has_method("is_frozen") and gm.is_frozen():
		frost = 0.35
		tint *= Color(0.75, 0.90, 1.0)
	sprite.modulate = tint

	# Ziel: im Duo immer den naeheren Helden jagen
	if gm != null and gm.has_method("get_nearest_target"):
		target = gm.get_nearest_target(global_position)
	if target == null or not is_instance_valid(target):
		return

	var to_target := target.global_position - global_position
	var dist := to_target.length()
	var direction := Vector2.ZERO
	if dist > 0.001:
		direction = to_target / dist
	ranged = false

	if type == MonsterType.YELLOW and dist < 320.0:
		# WERFER: bleibt auf Abstand und schießt
		velocity = Vector2.ZERO
		if direction.x > 0:
			sprite.flip_h = false
		elif direction.x < 0:
			sprite.flip_h = true
		ranged = true
		shoot_timer -= delta
		if shoot_timer <= 0.0 and gm != null:
			shoot_timer = 3.0
			gm.call("spawn_projectile", global_position + direction * 22.0, direction, 1, 175.0)
	elif type == MonsterType.PYRO:
		# FEUERWERFER (Lava): hält Abstand, wirft große Feuerbälle
		if direction != Vector2.ZERO:
			sprite.flip_h = direction.x < 0.0
		if dist > 460.0:
			velocity = direction * speed * zone_boost * frost
		elif dist < 320.0:
			velocity = -direction * speed * 0.8 * zone_boost * frost
		else:
			velocity = Vector2.ZERO
		ranged = true
		shoot_timer -= delta
		if shoot_timer <= 0.0 and gm != null and dist < 620.0:
			shoot_timer = 3.0
			gm.call("spawn_projectile", global_position + direction * 26.0, direction, 1, 210.0)
	elif type == MonsterType.BURROWER:
		# GRABER (Wüste): gräbt sich unter und taucht beim Helden wieder auf
		velocity = direction * speed * zone_boost * frost
		if direction != Vector2.ZERO:
			sprite.flip_h = direction.x < 0.0
		burrow_timer -= delta
		if burrow_timer <= 0.0 and dist > 240.0 and gm != null:
			burrow_timer = 4.0
			_burrow_near()
	elif type == MonsterType.MARS_ALIEN:
		# MARS-MAENNCHEN: schwebt auf Abstand und schiesst Strahlen
		velocity = Vector2.ZERO
		if dist > 400.0:
			velocity = direction * speed * zone_boost * frost
		elif dist < 260.0:
			velocity = -direction * speed * 0.7 * zone_boost * frost
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		ranged = true
		shoot_timer -= delta
		if shoot_timer <= 0.0 and gm != null and dist < 460.0:
			shoot_timer = 2.8
			gm.call("spawn_projectile", global_position + direction * 24.0, direction, 1, 210.0)
	elif type == MonsterType.MARS_ROVER:
		# MARS-ROVER: faehrt langsam, rammt dann in Schueben (kurze Anlauf-Warnung)
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		charge_timer -= delta
		if charge_timer <= 0.0:
			charge_timer = 2.8
			charge_state = 1 - charge_state
			charge_hold = 0.45 if charge_state == 1 else 1.4
		charge_hold -= delta
		if charge_state == 1 and charge_hold <= 0.0:
			velocity = charge_dir * speed * 4.6 * zone_boost * frost
		elif charge_state == 1:
			charge_dir = direction
			velocity = direction * speed * 0.4 * zone_boost * frost
		else:
			velocity = direction * speed * zone_boost * frost
	elif type == MonsterType.ROBO_APE:
		# ROBO-AFFE: wirft Bananen
		velocity = Vector2.ZERO
		if dist > 330.0:
			velocity = direction * speed * zone_boost * frost
		elif dist < 190.0:
			velocity = -direction * speed * 0.6 * zone_boost * frost
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		ranged = true
		shoot_timer -= delta
		if shoot_timer <= 0.0 and gm != null and dist < 470.0:
			shoot_timer = 2.7
			gm.call("spawn_banana", global_position + direction * 26.0, direction, 1, 195.0)
	elif type == MonsterType.BIG_FLOWER:
		# RIESENBLUME: verwurzelt, spuckt Sporen
		velocity = Vector2.ZERO
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		ranged = true
		shoot_timer -= delta
		if shoot_timer <= 0.0 and gm != null and dist < 430.0:
			shoot_timer = 3.1
			gm.call("spawn_projectile", global_position + direction * 20.0, direction, 1, 175.0)
	elif type == MonsterType.MARS_DRONE:
		# MARS-DROHNE: stuermt direkt auf den Helden zu (Kamikaze)
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		velocity = direction * speed * zone_boost * frost
	elif type == MonsterType.MARS_GUARD:
		# MARS-WAECHTER: langsam, aber gepanzert und schwer
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		velocity = direction * speed * zone_boost * frost
	elif type == MonsterType.ROBO_TIGER:
		# ROBO-TIGER: schnelle Kurzattacken
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		charge_timer -= delta
		if charge_timer <= 0.0:
			charge_timer = 1.9
			charge_state = 1 - charge_state
			charge_hold = 0.34 if charge_state == 1 else 1.5
		charge_hold -= delta
		if charge_state == 1 and charge_hold > 0.0:
			charge_dir = direction
			velocity = direction * speed * zone_boost * frost
		else:
			velocity = direction * speed * 0.35 * zone_boost * frost
	elif type == MonsterType.VOLT_DRONE:
		# ELEKTRO-DROHNE: schwebt ueber dem Boden, saust auf den Helden zu
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		sprite.position.y = base_sprite_pos.y - 6.0 + sin(anim_time * 4.0) * 3.0
		velocity = direction * speed * 0.9 * zone_boost * frost
	elif type == MonsterType.VOLT_TROOPER:
		# SPULENTROOPER (alt): laeuft deckungsuchend, feuert Einzelschuesse
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		velocity = direction * speed * zone_boost * frost
		ranged = true
		shoot_timer -= delta
		if shoot_timer <= 0.0 and gm != null and dist < 520.0:
			shoot_timer = 2.4
			gm.call("spawn_projectile", global_position + direction * 26.0, direction, 2, 240.0)
	elif type == MonsterType.VOLT_SPOOLER:
		# Runde 49: NEUER Gegner - SPULENTROOPER. Langsam und zaeh,
		# haelt auf mittlere Distanz und schiesst eine 3er-Salve.
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		if dist > 420.0:
			velocity = direction * speed * zone_boost * frost
		elif dist < 210.0:
			velocity = -direction * speed * 0.55 * zone_boost * frost
		else:
			velocity = Vector2.ZERO
		ranged = true
		shoot_timer -= delta
		if shoot_timer <= 0.0 and gm != null and dist < 560.0:
			shoot_timer = 3.4
			# Salve: 3 Kugeln leicht gestreut
			for k in range(-1, 2):
				var ds := direction.rotated(float(k) * 0.20)
				gm.call("spawn_projectile", global_position + ds * 30.0, ds, 3, 215.0)

	elif type == MonsterType.VINE_TRAP:
		# RANKENFALLE: verwurzelt, schnappt zu wenn der Held nahe kommt
		velocity = Vector2.ZERO
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
		if charge_state == 1:
			charge_hold -= delta
			velocity = charge_dir * 250.0
			if charge_hold <= 0.0:
				charge_state = 0
				charge_timer = 1.7
		else:
			charge_timer -= delta
			if charge_timer <= 0.0 and dist < 185.0:
				charge_state = 1
				charge_hold = 0.32
				charge_dir = direction
	elif type == MonsterType.BOSS:
		_boss_pattern(delta, direction, dist, zone_boost * frost)
	elif is_biome_boss():
		# Runde 49: Vorher stand hier eine feste Typ-Liste
		# (BOSS_MARS/JUNGLE/EARTH) - BOSS_VOLT fehlte, dadurch
		# griff der Volt-Boss NICHT an.
		_biome_boss(delta, direction, dist, zone_boost * frost)
	elif is_mini_boss():
		# Runde 49: Die Mini-Bosse haben ihr eigenes Muster
		_mini_boss_pattern(delta, direction, dist, zone_boost * frost)

	# Telegraph (Runde 15): 0,42 s vor dem Schuss pulsiert ein roter Ladeblitz
	if ranged:
		_ensure_warn()
		var armed := shoot_timer <= 0.42 and shoot_timer > 0.0
		warn_sprite.visible = armed and current_health > 0
		if armed:
			var pl := 1.0 + 0.30 * sin(float(Time.get_ticks_msec()) * 0.022)
			warn_sprite.scale = Vector2(0.42 * pl, 0.42 * pl)
			warn_sprite.modulate.a = 0.8
	elif warn_sprite != null and is_instance_valid(warn_sprite):
		warn_sprite.visible = false
	else:
		if direction != Vector2.ZERO:
			facing_direction = direction
			if direction.x > 0:
				sprite.flip_h = false
			elif direction.x < 0:
				sprite.flip_h = true
		velocity = direction * speed * zone_boost * frost

	move_and_slide()

	# Collision mit Spieler
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null and collider.is_in_group("player") and damage_cooldown <= 0:
			var dmg := damage_amount
			if gm != null and gm.has_method("get_monster_damage_mult"):
				dmg = int(round(float(damage_amount) * float(gm.call("get_monster_damage_mult"))))
			collider.call("take_damage", maxi(1, int(round(float(dmg) * dmg_mult))))
			# EISGOLEM: verlangsamt den getroffenen Helden
			if type == MonsterType.GOLEM and gm != null and gm.has_method("apply_player_slow_to"):
				gm.call("apply_player_slow_to", collider, 3.0)
			damage_cooldown = 1.0
			if kamikaze:
				die()
			break
func _boss_pattern(delta: float, direction: Vector2, dist: float, spd_mult: float) -> void:
	# Boss-Muster (Punkt 4): Fächer -> Anlauf -> Beschwören
	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0
	boss_timer -= delta
	match boss_state:
		0:
			# Kugel-Fächer
			velocity = direction * speed * spd_mult
			sprite.scale = base_scale
			shoot_timer -= delta
			if shoot_timer <= 0.0 and gm != null and dist < 620.0:
				shoot_timer = 2.2
				for k in range(-1, 2):
					var d2 := direction.rotated(k * 0.30)
					gm.call("spawn_projectile", global_position + d2 * 40.0, d2, 1, 190.0)
			if boss_timer <= 0.0:
				_enter_boss_state(1)
		1:
			# Anlauf: erst aufladen (pulsierende Größe als Warnung), dann stürmen
			boss_telegraph -= delta
			if boss_telegraph > 0.0:
				velocity = Vector2.ZERO
				var puff := 1.0 + 0.18 * sin(boss_telegraph * 30.0)
				sprite.scale = Vector2(base_scale.x * puff, base_scale.y * puff)
				boss_charge_dir = direction
			else:
				sprite.scale = base_scale
				velocity = boss_charge_dir * speed * 6.0 * spd_mult
			if boss_timer <= 0.0:
				_enter_boss_state(2)
		2:
			# Beschwören: 3 Mini-Splitter
			velocity = Vector2.ZERO
			sprite.scale = base_scale
			if boss_timer <= 0.0:
				if gm != null and gm.has_method("spawn_boss_minions"):
					gm.call("spawn_boss_minions", global_position)
				# Runde 49: Jeder dritte Zyklus endet mit einem DASH
				if dash_cycle >= 2:
					dash_cycle = 0
					_enter_boss_state(3)
				else:
					dash_cycle += 1
					_enter_boss_state(0)
		3:
			# Runde 49: DASH-Angriff mit Aufwind-Animation
			# Phase 1 = Aufwind (Warnung), Phase 2 = schneller Angriff
			if dash_state == 0:
				dash_state = 1
				dash_timer = 0.55
				dash_dir = direction
			elif dash_state == 1:
				dash_timer -= delta
				velocity = Vector2.ZERO
				# Aufwind: pulsierende Groesse als deutliche Warnung
				var dp := 1.0 + 0.30 * sin(dash_timer * 26.0)
				sprite.scale = Vector2(base_scale.x * dp, base_scale.y * dp)
				if dash_timer <= 0.0:
					dash_state = 2
					dash_timer = 0.85
					sprite.scale = base_scale
			else:
				dash_timer -= delta
				velocity = dash_dir * speed * 9.0 * spd_mult
				if dash_timer <= 0.0:
					dash_state = 0
					sprite.scale = base_scale
					_enter_boss_state(0)

func _biome_boss(delta: float, direction: Vector2, dist: float, spd_mult: float) -> void:
	# Biom-Boss: 3 Zustaende, je Biom eigene Waffen, ab 50% Leben Phase 2 (schneller)
	if start_hp <= 1:
		start_hp = maxi(1, current_health)
	if direction.x != 0.0:
		sprite.flip_h = direction.x < 0.0
	var rage: bool = current_health * 2 <= start_hp
	var spd2: float = spd_mult * (1.45 if rage else 1.0)
	match boss_state:
		0:
			velocity = direction * speed * spd2 * 0.55
			sprite.scale = base_scale
			shoot_timer -= delta
			if shoot_timer <= 0.0 and gm != null and dist < 720.0:
				shoot_timer = 1.7 if rage else 2.5
				match type:
					MonsterType.BOSS_MARS:
						# METEOR-GOLEM: Fels-Salve
						for k in range(-2, 3):
							var d2 := direction.rotated(float(k) * 0.20)
							gm.call("spawn_projectile", global_position + d2 * 56.0, d2, 2, 220.0)
					MonsterType.BOSS_JUNGLE:
						# ROBO-AFFE-KOENIG: Bananen-Salve
						for k in range(-1, 2):
							var d3 := direction.rotated(float(k) * 0.30)
							gm.call("spawn_banana", global_position + d3 * 50.0, d3, 2, 240.0)
					_:
						# SPLITTER-KOENIG: Rundum-Salve
						for k in range(8):
							var d4 := direction.rotated(float(k) * TAU / 8.0)
							gm.call("spawn_projectile", global_position + d4 * 52.0, d4, 1, 200.0)
			if boss_timer <= 0.0:
				# Runde 49: Jeder dritte Zyklus endet mit einem DASH
				# (auch fuer die Biom-Bosse - vorher war der Dash nur
				# im Standard-Boss, die Biom-Bosse konnten NIE dashen).
				if dash_cycle >= 2:
					dash_cycle = 0
					_enter_boss_state(3)
				else:
					dash_cycle += 1
					_enter_boss_state(0)
				if rage:
					boss_timer *= 0.7
		1:
			# Anlauf mit deutlicher Vorwarnung, dann Sturmangriff
			boss_telegraph -= delta
			if boss_telegraph > 0.0:
				velocity = Vector2.ZERO
				var puff := 1.0 + 0.22 * sin(boss_telegraph * 34.0)
				sprite.scale = Vector2(base_scale.x * puff, base_scale.y * puff)
				boss_charge_dir = direction
			else:
				sprite.scale = base_scale
				velocity = boss_charge_dir * speed * (5.2 if rage else 4.0) * spd2
			if boss_timer <= 0.0:
				_enter_boss_state(2)
		2:
			# Beschwoeren: eigene Biom-Diener
			velocity = Vector2.ZERO
			sprite.scale = base_scale
			if boss_timer <= 0.0:
				if gm != null and gm.has_method("spawn_boss_minions"):
					gm.call("spawn_boss_minions", global_position)
				_enter_boss_state(0)
				if rage:
					boss_timer *= 0.7
		3:
			# Runde 49: DASH-Angriff mit Aufwind-Warnung.
			# Der Dash war nur im Standard-Boss (_boss_pattern) - die
			# Biom-Bosse hatten states 0/1/2 und konnten NIE dashen.
			# Phase 1 = Aufwind (Warnung), Phase 2 = schneller Angriff.
			if dash_state == 0:
				dash_state = 1
				dash_timer = 0.55
				dash_dir = direction
			elif dash_state == 1:
				dash_timer -= delta
				velocity = Vector2.ZERO
				# Aufwind: pulsierende Groesse als deutliche Warnung
				var dp := 1.0 + 0.30 * sin(dash_timer * 26.0)
				sprite.scale = Vector2(base_scale.x * dp, base_scale.y * dp)
				if dash_timer <= 0.0:
					dash_state = 2
					dash_timer = 0.85
					sprite.scale = base_scale
			else:
				dash_timer -= delta
				velocity = dash_dir * speed * 9.0 * spd2
				if dash_timer <= 0.0:
					dash_state = 0
					sprite.scale = base_scale
					_enter_boss_state(0)

func _enter_boss_state(s: int) -> void:
	boss_state = s
	match s:
		0:
			boss_timer = 4.0
			shoot_timer = 0.6
		1:
			boss_timer = 1.7
			boss_telegraph = 0.65
		2:
			boss_timer = 0.7
		3:
			# Runde 49: DASH - der Aufwind beginnt im State selbst
			boss_timer = 1.5
			dash_state = 0
			dash_timer = 0.0


func _burrow_near() -> void:
	# Graber: untertauchen, beim Helden wieder auftauchen (mit Fade-In)
	if target == null or not is_instance_valid(target):
		return
	var ang := randf_range(0.0, TAU)
	var np: Vector2 = target.global_position + Vector2(cos(ang), sin(ang)) * randf_range(130.0, 210.0)
	var bounds: Rect2 = Rect2(140.0, 140.0, 3600.0, 2300.0)
	if gm != null and gm.has_method("get_map_bounds"):
		bounds = gm.call("get_map_bounds")
	np.x = clampf(np.x, bounds.position.x + 40.0, bounds.end.x - 40.0)
	np.y = clampf(np.y, bounds.position.y + 40.0, bounds.end.y - 40.0)
	global_position = np
	sprite.modulate.a = 0.2
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 1.0, 0.35)

func _ensure_warn() -> void:
	if warn_sprite != null and is_instance_valid(warn_sprite):
		return
	warn_sprite = Sprite2D.new()
	warn_sprite.name = "Warn"
	warn_sprite.texture = TextureManager.get_texture("glow_common")
	warn_sprite.modulate = Color(3.4, 0.9, 0.85)
	warn_sprite.z_index = 4
	warn_sprite.visible = false
	add_child(warn_sprite)

var last_hit_slot: int = 0       # Runde 33: Slot des letzten Treffers

func take_damage(amount: int, owner_slot: int = 0, hit_local: Vector2 = Vector2.INF) -> void:
	if owner_slot > 0:
		last_hit_slot = owner_slot
	if armor > 0.0:
		amount = maxi(1, int(round(float(amount) * (1.0 - armor))))
	# Runde 49: Weak-Point-Multiplikator - ein Treffer auf Schild oder
	# Kern richtet den SCHADEN.
	if not weak_points.is_empty() and hit_local != Vector2.INF:
		var wp: Dictionary = _weak_point_at(hit_local)
		if not wp.is_empty():
			amount = int(round(float(amount) * float(wp.get("mult", 2.5))))
			hit_flash = 0.18
			# Visuelles Feedback: der Boss blitzt kurz auf
			sprite.modulate = Color(1.9, 1.7, 1.5)
	current_health -= amount
	if is_boss():
		emit_signal("boss_hp", current_health, max_health)
	if current_health <= 0:
		die()

func die() -> void:
	_spawn_xp_popup()
	if is_boss():
		SoundManager.play("boss")
	else:
		SoundManager.play("kill")
	# SPLITTER: teilt sich in 2 Minis
	if type == MonsterType.PINK and gm != null:
		gm.call("spawn_splitter_children", global_position)
	# Runde 39: Position mitgeben (Kraftfeld-Bonus)
	emit_signal("monster_killed", points_worth, last_hit_slot, global_position)
	queue_free()

func _spawn_xp_popup() -> void:
	if get_parent() == null:
		return
	var lbl := Label.new()
	lbl.text = "+%d XP" % points_worth
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	lbl.z_index = 30
	get_parent().add_child(lbl)
	lbl.global_position = global_position + Vector2(-24, -46)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position", lbl.global_position + Vector2(0, -50), 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(lbl.queue_free)
