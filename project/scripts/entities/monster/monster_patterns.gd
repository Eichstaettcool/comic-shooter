class_name MonsterPatterns
extends RefCounted

# Runde 138: Boss-/Mini-Boss-Muster aus monster_ai.gd
var host: Node = null

# Spiegel von monster_ai.gd - Enum ist nicht ueber host erreichbar,
# Reihenfolge muss identisch bleiben.
enum MonsterType { GREEN, RED, BLUE, PURPLE, YELLOW, PINK, ORANGE, BOSS, BURROWER, GOLEM, PYRO, MARS_ALIEN, MARS_ROVER, ROBO_APE, BIG_FLOWER, MARS_DRONE, MARS_GUARD, ROBO_TIGER, VINE_TRAP, BOSS_MARS, BOSS_JUNGLE, BOSS_EARTH, MINI_EARTH, MINI_MARS, MINI_JUNGLE, VOLT_DRONE, VOLT_TROOPER, VOLT_SPIDER, BOSS_VOLT, VOLT_SPOOLER, MINI_VOLT, SPORENBRUT, SCHILD, HEROLD, SPORE }


func _mini_boss_pattern(delta: float, direction: Vector2, dist: float, spd_mult: float) -> void:
	# Runde 49: Eigenes Muster fuer die Mini-Bosse - sie jagen den
	# Spieler, feuern in Wellen und nutzen ihre Biom-Faehigkeit.
	if direction.x != 0.0:
		host.sprite.flip_h = direction.x < 0.0
	host.boss_timer -= delta
	match host.mini_state:
		0:
			# Anrennen
			host.velocity = direction * host.speed * spd_mult
			host.sprite.scale = host.base_scale
			host.shoot_timer -= delta
			if host.shoot_timer <= 0.0 and host.gm != null and dist < 560.0:
				host.shoot_timer = 2.4
				for k in range(-1, 2):
					var d2 := direction.rotated(float(k) * 0.26)
					host.gm.call("spawn_projectile", host.global_position + d2 * 44.0, d2, int(host.damage_amount), 230.0)
			if host.boss_timer <= 0.0:
				host.mini_state = 1
				host.boss_timer = 1.1
		1:
			# Pause mit Aufblitzen (Telegraph fuer die Faehigkeit)
			host.velocity = host.velocity.lerp(Vector2.ZERO, 0.2)
			var puff: float = 1.0 + 0.20 * sin(host.boss_timer * 28.0)
			host.sprite.scale = Vector2(host.base_scale.x * puff, host.base_scale.y * puff)
			if host.boss_timer <= 0.0:
				host.sprite.scale = host.base_scale
				_trigger_ability()
				host.mini_state = 0
				host.boss_timer = 3.4


func _boss_pattern(delta: float, direction: Vector2, dist: float, spd_mult: float) -> void:
	# Boss-Muster (Punkt 4): Fächer -> Anlauf -> Beschwören
	if direction.x != 0.0:
		host.sprite.flip_h = direction.x < 0.0
	host.boss_timer -= delta
	match host.boss_state:
		0:
			# Kugel-Fächer
			host.velocity = direction * host.speed * spd_mult
			host.sprite.scale = host.base_scale
			host.shoot_timer -= delta
			if host.shoot_timer <= 0.0 and host.gm != null and dist < 620.0:
				host.shoot_timer = 2.2
				for k in range(-1, 2):
					var d2 := direction.rotated(k * 0.30)
					host.gm.call("spawn_projectile", host.global_position + d2 * 40.0, d2, 1, 190.0)
			if host.boss_timer <= 0.0:
				_enter_boss_state(1)
		1:
			# Anlauf: erst aufladen (pulsierende Größe als Warnung), dann stürmen
			host.boss_telegraph -= delta
			if host.boss_telegraph > 0.0:
				host.velocity = Vector2.ZERO
				var puff = 1.0 + 0.18 * sin(host.boss_telegraph * 30.0)
				host.sprite.scale = Vector2(host.base_scale.x * puff, host.base_scale.y * puff)
				host.boss_charge_dir = direction
			else:
				host.sprite.scale = host.base_scale
				host.velocity = host.boss_charge_dir * host.speed * 6.0 * spd_mult
			if host.boss_timer <= 0.0:
				_enter_boss_state(2)
		2:
			# Beschwören: 3 Mini-Splitter
			host.velocity = Vector2.ZERO
			host.sprite.scale = host.base_scale
			if host.boss_timer <= 0.0:
				if host.gm != null and host.gm.has_method("spawn_boss_minions"):
					host.gm.call("spawn_boss_minions", host.global_position)
				# Runde 49: Jeder dritte Zyklus endet mit einem DASH
				if host.dash_cycle >= 2:
					host.dash_cycle = 0
					_enter_boss_state(3)
				else:
					host.dash_cycle += 1
					_enter_boss_state(0)
		3:
			# Runde 49: DASH-Angriff mit Aufwind-Animation
			# Phase 1 = Aufwind (Warnung), Phase 2 = schneller Angriff
			if host.dash_state == 0:
				host.dash_state = 1
				host.dash_timer = 0.55
				host.dash_dir = direction
			elif host.dash_state == 1:
				host.dash_timer -= delta
				host.velocity = Vector2.ZERO
				# Aufwind: pulsierende Groesse als deutliche Warnung
				var dp = 1.0 + 0.30 * sin(host.dash_timer * 26.0)
				host.sprite.scale = Vector2(host.base_scale.x * dp, host.base_scale.y * dp)
				if host.dash_timer <= 0.0:
					host.dash_state = 2
					host.dash_timer = 0.85
					host.sprite.scale = host.base_scale
			else:
				host.dash_timer -= delta
				host.velocity = host.dash_dir * host.speed * 9.0 * spd_mult
				if host.dash_timer <= 0.0:
					host.dash_state = 0
					host.sprite.scale = host.base_scale
					_enter_boss_state(0)


func _biome_boss(delta: float, direction: Vector2, dist: float, spd_mult: float) -> void:
	# Biom-Boss: 3 Zustaende, je Biom eigene Waffen, ab 50% Leben Phase 2 (schneller)
	if host.start_hp <= 1:
		host.start_hp = maxi(1, host.current_health)
	if direction.x != 0.0:
		host.sprite.flip_h = direction.x < 0.0
	var rage: bool = host.current_health * 2 <= host.start_hp
	var spd2: float = spd_mult * (1.45 if rage else 1.0)
	match host.boss_state:
		0:
			host.velocity = direction * host.speed * spd2 * 0.55
			host.sprite.scale = host.base_scale
			host.shoot_timer -= delta
			if host.shoot_timer <= 0.0 and host.gm != null and dist < 720.0:
				host.shoot_timer = 1.7 if rage else 2.5
				match host.type:
					MonsterType.BOSS_MARS:
						# METEOR-GOLEM: Fels-Salve
						for k in range(-2, 3):
							var d2 := direction.rotated(float(k) * 0.20)
							host.gm.call("spawn_projectile", host.global_position + d2 * 56.0, d2, 2, 220.0)
					MonsterType.BOSS_JUNGLE:
						# ROBO-AFFE-KOENIG: Bananen-Salve
						for k in range(-1, 2):
							var d3 := direction.rotated(float(k) * 0.30)
							host.gm.call("spawn_banana", host.global_position + d3 * 50.0, d3, 2, 240.0)
					_:
						# SPLITTER-KOENIG: Rundum-Salve
						for k in range(8):
							var d4 := direction.rotated(float(k) * TAU / 8.0)
							host.gm.call("spawn_projectile", host.global_position + d4 * 52.0, d4, 1, 200.0)
			if host.boss_timer <= 0.0:
				# Runde 49: Jeder dritte Zyklus endet mit einem DASH
				# (auch fuer die Biom-Bosse - vorher war der Dash nur
				# im Standard-Boss, die Biom-Bosse konnten NIE dashen).
				if host.dash_cycle >= 2:
					host.dash_cycle = 0
					_enter_boss_state(3)
				else:
					host.dash_cycle += 1
					_enter_boss_state(0)
				if rage:
					host.boss_timer *= 0.7
		1:
			# Anlauf mit deutlicher Vorwarnung, dann Sturmangriff
			host.boss_telegraph -= delta
			if host.boss_telegraph > 0.0:
				host.velocity = Vector2.ZERO
				var puff = 1.0 + 0.22 * sin(host.boss_telegraph * 34.0)
				host.sprite.scale = Vector2(host.base_scale.x * puff, host.base_scale.y * puff)
				host.boss_charge_dir = direction
			else:
				host.sprite.scale = host.base_scale
				host.velocity = host.boss_charge_dir * host.speed * (5.2 if rage else 4.0) * spd2
			if host.boss_timer <= 0.0:
				_enter_boss_state(2)
		2:
			# Beschwoeren: eigene Biom-Diener
			host.velocity = Vector2.ZERO
			host.sprite.scale = host.base_scale
			if host.boss_timer <= 0.0:
				if host.gm != null and host.gm.has_method("spawn_boss_minions"):
					host.gm.call("spawn_boss_minions", host.global_position)
				_enter_boss_state(0)
				if rage:
					host.boss_timer *= 0.7
		3:
			# Runde 49: DASH-Angriff mit Aufwind-Warnung.
			# Der Dash war nur im Standard-Boss (_boss_pattern) - die
			# Biom-Bosse hatten states 0/1/2 und konnten NIE dashen.
			# Phase 1 = Aufwind (Warnung), Phase 2 = schneller Angriff.
			if host.dash_state == 0:
				host.dash_state = 1
				host.dash_timer = 0.55
				host.dash_dir = direction
			elif host.dash_state == 1:
				host.dash_timer -= delta
				host.velocity = Vector2.ZERO
				# Aufwind: pulsierende Groesse als deutliche Warnung
				var dp = 1.0 + 0.30 * sin(host.dash_timer * 26.0)
				host.sprite.scale = Vector2(host.base_scale.x * dp, host.base_scale.y * dp)
				if host.dash_timer <= 0.0:
					host.dash_state = 2
					host.dash_timer = 0.85
					host.sprite.scale = host.base_scale
			else:
				host.dash_timer -= delta
				host.velocity = host.dash_dir * host.speed * 9.0 * spd2
				if host.dash_timer <= 0.0:
					host.dash_state = 0
					host.sprite.scale = host.base_scale
					_enter_boss_state(0)


func _enter_boss_state(s: int) -> void:
	host.boss_state = s
	match s:
		0:
			host.boss_timer = 4.0
			host.shoot_timer = 0.6
		1:
			host.boss_timer = 1.7
			host.boss_telegraph = 0.65
		2:
			host.boss_timer = 0.7
		3:
			# Runde 49: DASH - der Aufwind beginnt im State selbst
			host.boss_timer = 1.5
			host.dash_state = 0
			host.dash_timer = 0.0


func _burrow_near() -> void:
	# Graber: untertauchen, beim Helden wieder auftauchen (mit Fade-In)
	if host.target == null or not is_instance_valid(host.target):
		return
	var ang := randf_range(0.0, TAU)
	var np: Vector2 = host.target.global_position + Vector2(cos(ang), sin(ang)) * randf_range(130.0, 210.0)
	var bounds: Rect2 = Rect2(140.0, 140.0, 3600.0, 2300.0)
	if host.gm != null and host.gm.has_method("get_map_bounds"):
		bounds = host.gm.call("get_map_bounds")
	np.x = clampf(np.x, bounds.position.x + 40.0, bounds.end.x - 40.0)
	np.y = clampf(np.y, bounds.position.y + 40.0, bounds.end.y - 40.0)
	host.global_position = np
	host.sprite.modulate.a = 0.2
	var tw = host.create_tween()
	tw.tween_property(host.sprite, "modulate:a", 1.0, 0.35)


func _ensure_warn() -> void:
	if host.warn_sprite != null and is_instance_valid(host.warn_sprite):
		return
	host.warn_sprite = Sprite2D.new()
	host.warn_sprite.name = "Warn"
	host.warn_sprite.texture = TextureManager.get_texture("glow_common")
	host.warn_sprite.modulate = Color(3.4, 0.9, 0.85)
	host.warn_sprite.z_index = 4
	host.warn_sprite.visible = false
	host.add_child(host.warn_sprite)


func _trigger_ability() -> void:
	# Runde 49: Die Biom-Faehigkeit ausloesen - Aura leuchtet in der
	# Faehigkeitsfarbe, der Effekt wird angewendet.
	var ab: Dictionary = MINI_ABILITIES.get(host._biome_key(), MINI_ABILITIES["earth"])
	host.active_ability = ab
	print("[BOSS][ABILITY] cast: kind=%s name=%s spieler=%d type=%d" % [
		str(ab.get("kind", "")), str(ab.get("name", "?")), host._players_alive().size(), host.type])
	var col: Color = ab.get("color", Color(1, 1, 1))
	if host.aura != null:
		host.aura.modulate = Color(col.r, col.g, col.b, 0.85)
		host.aura.scale = Vector2(1.6, 1.6)
		if host.aura_tween != null and host.aura_tween.is_valid():
			host.aura_tween.kill()
		host.aura_tween = host.aura.create_tween()
		host.aura_tween.set_loops(3)
		host.aura_tween.tween_property(host.aura, "scale", Vector2(2.3, 2.3), 0.35).set_trans(Tween.TRANS_QUAD)
		host.aura_tween.tween_property(host.aura, "scale", Vector2(1.6, 1.6), 0.35)
	# Runde 54: Faehigkeits-Art. "shock" = Blitzkette (Elektro-Mini),
	# alles andere = der bisherige 8er-Ring.
	if str(ab.get("kind", "")) == "shock":
		var tgt = host._nearest_player()
		if tgt == null:
			print("[BOSS][ABILITY] FEHLER: kein Zielspieler gefunden (players=%s)" % str(host.gm.get("players").keys() if host.gm != null else "?"))
		if tgt != null and host.gm != null and host.gm.has_method("spawn_projectile"):
			var base: Vector2 = (tgt.global_position - host.global_position).normalized()
			for k in range(3):
				var a2: float = deg_to_rad(-12.0 + 12.0 * float(k))
				var d3: Vector2 = base.rotated(a2)
				host.gm.call("spawn_projectile", host.global_position + d3 * 46.0, d3, int(ab.get("dmg", 3)), 300.0, 1)
			print("[BOSS][ABILITY] Blitzkette: 3 Blitze auf Slot %s (Kette beim Treffer)" % str(tgt.get("player_id")))
	elif host.gm != null and host.gm.has_method("spawn_projectile"):
		for k in range(8):
			var ang: float = TAU * float(k) / 8.0
			var d2 := Vector2(cos(ang), sin(ang))
			host.gm.call("spawn_projectile", host.global_position + d2 * 50.0, d2, int(ab.get("dmg", 2)), 210.0)
	host.ability_cd = 3.0 if host.overcharged else float(ab.get("cd", 6.0))

# Konstanten aus monster_ai.gd
const MINI_ABILITIES := MonsterStats.MINI_ABILITIES
