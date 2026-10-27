# PlayerController.gd - Spieler: Bewegung (rotierte Optik), Schiessen, Regeneration
extends CharacterBody2D

signal health_changed(new_health: int)
signal player_died

const SPEED: float = 160.0
const MAX_HEALTH: int = 5

var player_id: int = 1          # 1 = blauer Held, 2 = roter Held (Duo)
var health: int = MAX_HEALTH
var max_health: int = MAX_HEALTH
var input_direction: Vector2 = Vector2.ZERO
var shoot_held: bool = false
var downed: bool = false             # Runde 34: liegt am Boden (Mehrspieler)
var spectating: bool = false         # Runde 51: endgueltig tot -> Zuschauer
var _downed_tint: bool = false       # Runde 50: Farbe fuer den liegenden Zustand
var rig_sprite: Sprite2D = null      # Runde 38: Character-Rig-Overlay
var rig_idx: int = 0
var anim_time: float = 0.0
var sprite_base_scale: Vector2 = Vector2.ONE
var sprite_base_pos: Vector2 = Vector2.ZERO
var recoil_tween: Tween = null
var punch_tween: Tween = null
var gm: Node = null

# --- LAN/Co-op-Modi ---
var remote_controlled: bool = false        # Client: Position kommt vom Host
var remote_target_pos: Vector2 = Vector2.ZERO
var remote_driven: bool = false            # Host: Held wird vom Client gesteuert
var remote_input_dir: Vector2 = Vector2.ZERO
var remote_shoot: bool = false

var slow_time: float = 0.0          # Eisgolem-Treffer: verlangsamt den Helden
var profile_color: int = 0
var profile_hat: int = 0

func apply_slow(dur: float) -> void:
	slow_time = maxf(slow_time, dur)

func _make_rig_sprite() -> void:  # Runde 38
	# Runde 38: Character-Rig als Overlay-Sprite ueber dem Helden
	if rig_sprite != null:
		return
	rig_sprite = Sprite2D.new()
	rig_sprite.name = "RigOverlay"
	rig_sprite.texture = TextureManager.get_texture("player_rig0")
	rig_sprite.z_index = 1
	rig_sprite.visible = false
	add_child(rig_sprite)

func apply_profile(color_idx: int, hat_idx: int, rig: int = 0) -> void:
	# Runde 38: Rig-Overlay (Character-Rig) mit setzen
	rig_idx = rig
	# Runde 40: ein Skin ist ein KOMPLETTER Charakter-Look -> er ersetzt das
	# Spielerbild ganz (kein blosses Overlay mehr).
	if rig_sprite != null and is_instance_valid(rig_sprite):
		rig_sprite.visible = false
	profile_color = color_idx
	profile_hat = hat_idx
	if rig > 0:
		# Runde 62: Hut mitgeben - vorher rief der Skin-Pfad get_skin_texture()
		# ohne Hut, dadurch verschwand der gewaehlte Hut im Spiel.
		var st = TextureManager.get_skin_hat_texture(color_idx, clampi(rig, 0, 5), hat_idx)
		if st != null:
			sprite.texture = st
			return
	if sprite != null:
		sprite.texture = TextureManager.get_player_texture(color_idx, hat_idx)
	if player_id == 2 and color_idx == 0 and hat_idx == 0:
		sprite.texture = TextureManager.get_player_texture(1, 0)   # P2 bleibt rot

func set_remote_transform(pos: Vector2, angle_deg: float) -> void:
	remote_target_pos = pos
	facing_direction = Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
	_update_facing_visuals()

func play_shot_visual() -> void:
	# Vom Host gemeldeter Schuss -> nur Optik
	_spawn_muzzle_flash()

func set_remote_input(dir: Vector2, shoot: bool, angle_deg: float) -> void:
	remote_input_dir = dir
	remote_shoot = shoot
	if dir == Vector2.ZERO:
		# Stehend: Blickrichtung aus der Netzinfo uebernehmen
		facing_direction = Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
		_update_facing_visuals()

# Regeneration: 12s ohne Schaden -> +1 Herz
var regen_timer: float = 0.0
const REGEN_DELAY := 12.0

# Schild
var shield: int = 0
var shield_time: float = 0.0
const SHIELD_DURATION := 12.0
var shield_ring: Sprite2D = null
var weapon_sprite: Sprite2D = null

# Level-Up-Upgrades
var damage_mult: float = 1.0
var cooldown_mult: float = 1.0
var buff_cooldown_mult: float = 1.0    # Buff-Faktor (Schnellfeuer aus Kiste)
var speed_mult: float = 1.0
var vampire_per: int = 0
var kill_count: int = 0

func on_kill() -> void:
	kill_count += 1
	if vampire_per > 0 and kill_count % vampire_per == 0:
		heal(1)

# Waffen-System
enum WeaponType { PISTOL, SHOTGUN, MACHINE, LASER, REVOLVER }
var current_weapon: WeaponType = WeaponType.PISTOL
var weapon_cooldown: float = 0.0
var can_shoot: bool = true
# Runde 49: Magazin + Nachladen
var ammo: int = -1                # -1 = unendlich
var reload_timer: float = 0.0
var reloading: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var owned_weapons: Array = ["weapon_pistol"]     # fuer das Waffen-HUD

# Runde 49: Jede Waffe hat ein MAGAZIN (Schuesse) und eine RELOAD-Zeit.
# 0 = unendlich Munition (kein Nachladen). RPM = 60 / cooldown.
const WEAPON_DATA = {
	WeaponType.PISTOL: { "name": "pistol", "damage": 3, "cooldown": 0.4, "speed": 300.0, "mag": 0, "reload": 0.0 },
	WeaponType.SHOTGUN: { "name": "shotgun", "damage": 5, "cooldown": 0.8, "speed": 250.0, "spread": 3, "mag": 6, "reload": 2.4 },
	# Runde 49: SMG und Laser bekommen ein Magazin + Nachladezeit
	WeaponType.MACHINE: { "name": "machine", "damage": 2, "cooldown": 0.1, "speed": 350.0, "mag": 40, "reload": 2.2 },
	WeaponType.LASER: { "name": "laser", "damage": 2, "cooldown": 0.14, "speed": 560.0, "mag": 24, "reload": 1.6 },
	WeaponType.REVOLVER: { "name": "revolver", "damage": 9, "cooldown": 1.05, "speed": 420.0, "mag": 6, "reload": 1.9 }
}

var projectile_scene: PackedScene = null

# --- Runde 15: Utilitys, Zielen, Tasten ---
var utilities: Dictionary = { "potion": 0, "bomb": 0 }
var aim_assist: int = 1
var _key_state: Dictionary = {}
var _last_mouse: Vector2 = Vector2.ZERO
var aim_line: Line2D = null

func add_utility(kind: String, n: int = 1) -> void:
	utilities[kind] = int(utilities.get(kind, 0)) + n
	if gm != null and gm.has_method("refresh_utility_hud"):
		gm.call("refresh_utility_hud")

func use_potion() -> bool:
	if int(utilities.get("potion", 0)) <= 0 or health >= max_health:
		return false
	utilities["potion"] = int(utilities["potion"]) - 1
	heal(2)
	SoundManager.play("pickup")
	if gm != null and gm.has_method("refresh_utility_hud"):
		gm.call("refresh_utility_hud")
	return true

func use_bomb() -> bool:
	if int(utilities.get("bomb", 0)) <= 0:
		return false
	utilities["bomb"] = int(utilities["bomb"]) - 1
	SoundManager.play("shotgun")
	# Schockwelle + Flaechenschaden
	var wave := Sprite2D.new()
	wave.texture = TextureManager.get_texture("glow_common")
	wave.modulate = Color(3.0, 1.6, 0.6)
	wave.z_index = 8
	wave.scale = Vector2(0.4, 0.4)
	add_child(wave)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(wave, "scale", Vector2(5.2, 5.2), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(wave, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(wave.queue_free)
	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if m.global_position.distance_to(global_position) <= 270.0:
			m.call("take_damage", 6)
	if gm != null and gm.has_method("refresh_utility_hud"):
		gm.call("refresh_utility_hud")
	return true

func _pressed_once(key: int) -> bool:
	# Tastendruck-Flanke (GDScript ohne InputMap)
	var now: bool = Input.is_key_pressed(key)
	var was: bool = bool(_key_state.get(key, false))
	_key_state[key] = now
	return now and not was

func _solve_aim(input_dir: Vector2) -> Vector2:
	var aim := facing_direction
	if input_dir != Vector2.ZERO:
		aim = input_dir.normalized()
	# Runde 26: Maus-Zielen ENTFERNT. Vorher wurde auf dem Geraet die (unten
	# rechts liegende) Zeigerposition als Ziel genommen -> Auto-Aim zielte immer
	# nach rechts unten. Default ist jetzt strikt die zuletzt gelaufene Richtung.
	# Zielhilfe: auf das naechste Monster im Kegel einrasten
	if aim_assist > 0:
		var cone := 0.55 if aim_assist == 1 else 1.10
		var best: Node2D = null
		var best_d := 1.0e9
		for m in get_tree().get_nodes_in_group("monsters"):
			if not is_instance_valid(m) or m.is_queued_for_deletion():
				continue
			var to_m: Vector2 = m.global_position - global_position
			var d: float = to_m.length()
			if d < 2.0 or d > 470.0:
				continue
			if absf(aim.angle_to(to_m.normalized())) > cone:
				continue
			if d < best_d:
				best_d = d
				best = m
		if best != null:
			aim = (best.global_position - global_position).normalized()
	return aim

@onready var sprite = $Sprite2D
@onready var weapon_holder = $WeaponHolder

func _ready():
	_make_rig_sprite()
	add_to_group("player")
	collision_layer = 1
	collision_mask = 26
	var tex_key := "player" if player_id == 1 else "player2"
	sprite.texture = TextureManager.get_texture(tex_key)
	# Runde 59: weiche Skalierung der 64px-Charaktere statt harter Pixelkanten
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if rig_sprite != null:
		rig_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite_base_scale = sprite.scale
	sprite_base_pos = sprite.position
	# Waffe in der Hand sichtbar machen
	weapon_sprite = Sprite2D.new()
	weapon_sprite.name = "WeaponSprite"
	weapon_sprite.scale = Vector2(0.72, 0.72)
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	weapon_sprite.position = Vector2(-4, 0)
	weapon_sprite.z_index = 2
	weapon_holder.add_child(weapon_sprite)
	_update_weapon_visual()
	projectile_scene = load("res://scenes/Projectile.tscn") as PackedScene
	aim_line = Line2D.new()
	aim_line.name = "AimLine"
	aim_line.width = 3.0
	aim_line.default_color = Color(1.0, 1.0, 0.6, 0.30)
	aim_line.z_index = 1
	aim_line.add_point(Vector2(26, 0))
	aim_line.add_point(Vector2(104, 0))
	add_child(aim_line)
	shield_ring = Sprite2D.new()
	shield_ring.name = "ShieldRing"
	shield_ring.texture = TextureManager.get_texture("shield_ring")
	shield_ring.z_index = 3
	shield_ring.visible = false
	add_child(shield_ring)
	_update_facing_visuals()

func _physics_process(delta: float) -> void:
	# Runde 51: Zuschauer bewegt und schiesst nicht
	if spectating:
		velocity = Vector2.ZERO
		return
	# Runde 50: Ein liegender Spieler bewegt sich nicht und schiesst nicht
	if downed:
		velocity = Vector2.ZERO
		if not _downed_tint:
			_downed_tint = true
			sprite.modulate = Color(0.55, 0.55, 0.62)
		_update_body_anim(delta, false)
		return
	if _downed_tint:
		_downed_tint = false
		sprite.modulate = Color.WHITE
	# LAN-Client: Position/Blickrichtung kommen vom Host (kein eigenes Input-Physik-Modell)
	if remote_controlled:
		global_position = global_position.lerp(remote_target_pos, clampf(delta * 16.0, 0.0, 1.0))
		_update_body_anim(delta, global_position.distance_to(remote_target_pos) > 1.5)
		return

	# Regeneration (nur wenn noch am Leben und nicht voll)
	if health > 0 and health < max_health:
		regen_timer += delta
		if regen_timer >= REGEN_DELAY:
			regen_timer = 0.0
			heal(1)
	else:
		regen_timer = 0.0

	# Schild-Timer + pulsierender Ring
	if shield > 0:
		shield_time -= delta
		shield_ring.visible = true
		var pulse := 1.0 + 0.07 * sin(anim_time * 6.0)
		shield_ring.scale = Vector2(pulse, pulse)
		if shield_time <= 0.0:
			shield = 0
			shield_ring.visible = false
	else:
		shield_ring.visible = false

	# Waffen-Cooldown
	if weapon_cooldown > 0:
		weapon_cooldown -= delta
		if weapon_cooldown <= 0:
			can_shoot = true
	# Runde 49: Nachlade-Timer
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			reloading = false
			reload_timer = 0.0
			var weapon: Dictionary = WEAPON_DATA[current_weapon]
			var mag2: int = int(weapon.get("mag", 0))
				# Runde 49: Nach dem Nachladen ist das Magazin voll
			ammo = mag2 if mag2 > 0 else -1
			can_shoot = true

	# Eingabe: Touch-Stick, sonst Tastatur (P1 WASD, P2 Pfeile)
	var input_dir = input_direction
	if remote_driven:
		# Host: dieser Held wird vom LAN-Client gesteuert
		input_dir = remote_input_dir
	elif input_dir == Vector2.ZERO:
		input_dir = Vector2.ZERO
		if player_id == 2:
			if Input.is_key_pressed(KEY_UP):
				input_dir.y -= 1
			if Input.is_key_pressed(KEY_DOWN):
				input_dir.y += 1
			if Input.is_key_pressed(KEY_LEFT):
				input_dir.x -= 1
			if Input.is_key_pressed(KEY_RIGHT):
				input_dir.x += 1
		else:
			if Input.is_key_pressed(KEY_W):
				input_dir.y -= 1
			if Input.is_key_pressed(KEY_S):
				input_dir.y += 1
			if Input.is_key_pressed(KEY_A):
				input_dir.x -= 1
			if Input.is_key_pressed(KEY_D):
				input_dir.x += 1

	# Bewegung (mit Korruptionszonen-Verlangsamung)
	var moving := false
	var slow := 1.0
	if gm != null and gm.has_method("is_corrupted") and gm.is_corrupted(global_position):
		slow = 0.7
	# Karten-Effekt (Runde 11): Eisfeld ist glatt
	if gm != null and gm.has_method("get_ground_slow"):
		slow *= float(gm.call("get_ground_slow"))
	# Eisgolem-Effekt: verlangsamt
	if slow_time > 0.0:
		slow_time -= delta
		slow *= 0.6
	var target_vel := Vector2.ZERO
	if input_dir != Vector2.ZERO:
		moving = true
		target_vel = input_dir.normalized() * SPEED * speed_mult * slow
	# Zielrichtung jeden Frame neu bestimmen (auch im Stehen) -> Waffe dreht mit
	facing_direction = _solve_aim(input_dir)
	_update_facing_visuals()
	# Karten-Physik (Runde 12): auf dem Mars rutscht man (Traegheit)
	var drift := 0.0
	if gm != null and gm.has_method("get_drift"):
		drift = clampf(float(gm.call("get_drift")), 0.0, 0.85)
	if drift > 0.0:
		velocity = velocity.lerp(target_vel, clampf(delta * (1.0 - drift) * 14.0, 0.0, 1.0))
	else:
		velocity = target_vel

	move_and_slide()

	_update_body_anim(delta, moving)

	# Utility-Tasten (Runde 15): Q = Trank, E = Bombe
	if not remote_controlled and not remote_driven and player_id == 1:
		if _pressed_once(KEY_Q):
			use_potion()
		if _pressed_once(KEY_E):
			use_bomb()
		for i in range(5):
			if _pressed_once([KEY_1, KEY_2, KEY_3, KEY_4, KEY_5][i]):
				switch_to_index(i)

	# Schiessen: Button/Space (P1) bzw. Enter (P2) halten
	var key_shoot := false
	if remote_driven:
		key_shoot = remote_shoot
	elif player_id == 2:
		key_shoot = Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	else:
		key_shoot = Input.is_key_pressed(KEY_SPACE)
	var shooting_allowed := true
	if gm != null and gm.has_method("can_shoot_now"):
		shooting_allowed = bool(gm.call("can_shoot_now"))
	if shooting_allowed and (shoot_held or key_shoot) and can_shoot:
		_shoot()

func _start_reload() -> void:
	# Runde 49: Nachladen starten
	if reloading:
		return
	var weapon: Dictionary = WEAPON_DATA[current_weapon]
	var rl: float = float(weapon.get("reload", 0.0))
	if rl <= 0.0:
		return
	reloading = true
	reload_timer = rl
	can_shoot = false


func get_reload_progress() -> float:
	# Runde 49: 0 = kein Nachladen, 1 = fertig
	if not reloading:
		return 0.0
	var weapon: Dictionary = WEAPON_DATA[current_weapon]
	var rl: float = float(weapon.get("reload", 0.0))
	if rl <= 0.0:
		return 0.0
	return clampf(1.0 - reload_timer / rl, 0.0, 1.0)


func get_ammo_text() -> String:
	# Runde 49: Munitionstext fuer das HUD
	var weapon: Dictionary = WEAPON_DATA[current_weapon]
	var mag: int = int(weapon.get("mag", 0))
	if mag <= 0:
		return ""
	if reloading:
		return "NACHLADEN %.1fs" % maxf(0.0, reload_timer)
	return "%d / %d" % [maxi(0, ammo), mag]


func _shoot() -> void:
	if projectile_scene == null:
		return
	var weapon = WEAPON_DATA[current_weapon]
	can_shoot = false
	weapon_cooldown = weapon["cooldown"] * cooldown_mult * buff_cooldown_mult
	# Runde 49: Magazin verbrauchen - ist es leer, wird nachgeladen
	var mag: int = int(weapon.get("mag", 0))
	if mag > 0:
		if ammo <= 0:
			# noch kein Magazin initiiert oder leer -> neu fuellen
			ammo = mag
		ammo -= 1
		if ammo <= 0:
			ammo = 0
			_start_reload()

	var proj_speed = weapon["speed"]
	var proj_damage = int(round(weapon["damage"] * damage_mult))
	match current_weapon:
		WeaponType.SHOTGUN:
			SoundManager.play("shotgun")
		WeaponType.MACHINE:
			SoundManager.play("machine")
		_:
			SoundManager.play("shoot")

	if current_weapon == WeaponType.SHOTGUN and weapon.has("spread"):
		var spread_count = weapon["spread"]
		for i in range(spread_count):
			var angle_offset = (float(i) / float(spread_count - 1) - 0.5) * 0.3
			var proj = projectile_scene.instantiate()
			proj.position = weapon_holder.global_position
			var dir = facing_direction.rotated(angle_offset)
			proj.set_direction(dir, proj_speed)
			proj.set_damage(proj_damage)
			proj.owner_slot = player_id      # Runde 33: Coins dem Schuetzen zuordnen
			get_parent().add_child(proj)
	else:
		var proj = projectile_scene.instantiate()
		proj.position = weapon_holder.global_position
		proj.set_direction(facing_direction, proj_speed)
		proj.set_damage(proj_damage)
		proj.owner_slot = player_id          # Runde 33
		get_parent().add_child(proj)

	_spawn_muzzle_flash()
	# Co-op: der Host meldet die Schuesse des Mitspielers an dessen Client
	if gm != null and gm.has_method("notify_shot"):
		gm.notify_shot(self, facing_direction.angle())

func _update_facing_visuals() -> void:
	# Nur Waffe/Schussachse folgen der Blickrichtung — der Körper bleibt aufrecht!
	var angle := facing_direction.angle()
	weapon_holder.position = Vector2(24, 0).rotated(angle)
	weapon_holder.rotation = angle
	# Aufrecht: nur horizontal spiegeln, niemals kopfüber drehen
	sprite.flip_h = cos(angle) < 0.0
	sprite.rotation = 0.0
	if aim_line != null and is_instance_valid(aim_line):
		aim_line.rotation = angle

func _update_body_anim(delta: float, moving: bool) -> void:
	# Lauf-Animation: Wippen + leichtes comic-Kippen, Körper bleibt senkrecht
	if sprite == null:
		return
	var flip := cos(facing_direction.angle()) < 0.0
	sprite.flip_h = flip
	sprite.rotation = 0.0
	# Frost-Effekt sichtbar machen
	if slow_time > 0.0:
		sprite.modulate = Color(0.70, 0.85, 1.15)
	elif sprite.modulate.b > 1.0 or sprite.modulate.r < 0.9:
		sprite.modulate = Color(1, 1, 1)
	if moving:
		anim_time += delta
		var bob := sin(anim_time * 12.0)
		var dir := -1.0 if flip else 1.0
		sprite.position = sprite_base_pos + Vector2(0, bob * 1.8)
		sprite.skew = bob * 0.05 * dir
		sprite.scale = Vector2(sprite_base_scale.x * (1.0 - bob * 0.03), sprite_base_scale.y * (1.0 + bob * 0.05))
	else:
		sprite.position = sprite_base_pos
		sprite.skew = 0.0
		sprite.scale = sprite_base_scale

func _spawn_muzzle_flash() -> void:
	var angle := facing_direction.angle()
	var flash = Sprite2D.new()
	flash.texture = TextureManager.get_texture("muzzle_flash")
	flash.position = Vector2(40, 0).rotated(angle)
	flash.rotation = angle
	flash.z_index = 5
	add_child(flash)
	flash.scale = Vector2(0.5, 0.5)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", Vector2(1.5, 1.5), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(flash, "modulate:a", 0.0, 0.12).set_delay(0.02)
	tw.chain().tween_callback(flash.queue_free)
	# Rueckstoß der Waffe entlang der Blickachse
	weapon_holder.position = Vector2(12, 0).rotated(angle)
	if recoil_tween != null and recoil_tween.is_valid():
		recoil_tween.kill()
	recoil_tween = create_tween()
	recoil_tween.tween_property(weapon_holder, "position", Vector2(24, 0).rotated(angle), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Comic-Squash
	sprite.scale = Vector2(1.12, 0.9)
	if punch_tween != null and punch_tween.is_valid():
		punch_tween.kill()
	punch_tween = create_tween()
	punch_tween.tween_property(sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func set_shoot_held(value: bool) -> void:
	shoot_held = value

func take_damage(amount: int) -> void:
	# Runde 50: Wer schon liegt, nimmt keinen weiteren Schaden
	if downed:
		return
	regen_timer = 0.0
	if shield > 0:
		shield -= 1
		shield_time = SHIELD_DURATION
		SoundManager.play("hit")
		emit_signal("health_changed", health)
		return
	SoundManager.play("hurt")
	health -= amount
	emit_signal("health_changed", health)
	if health <= 0:
		health = 0
		# Runde 50: Der GM markiert uns im LAN als "downed" (Signal ist
		# synchron). Dann bleibt der Koerper LIEGEN und wird nicht
		# geloescht - sonst ist er nicht wiederzubeleben.
		emit_signal("player_died")
		if downed:
			print("[LAN][DEATH] health<=0 -> DOWNED (Knoten bleibt fuer Revive)")
			return
		print("[LAN][DEATH] health<=0 -> nicht LAN, Knoten wird entfernt")
		queue_free()

func add_speed_mult(amount: float) -> void:
	# Runde 35b: Rare-Item "TEMPO +20%"
	speed_mult = minf(2.0, speed_mult + amount)

func add_damage_mult(amount: float) -> void:
	# Runde 34: Rare-Item "SCHADEN +35%"
	damage_mult += amount

func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	emit_signal("health_changed", health)

func add_shield(amount: int) -> void:
	shield = mini(shield + amount, 3)
	shield_time = SHIELD_DURATION

func add_max_health(amount: int = 1) -> void:
	# Runde 34: Rare-Items geben +2/+3 Herzen -> Cap 10
	if max_health < 10:
		max_health += amount
		health = mini(health + amount, max_health)
	emit_signal("health_changed", health)

func get_max_health() -> int:
	return max_health

func get_health() -> int:
	return health

func get_weapon_name() -> String:
	return WEAPON_DATA[current_weapon]["name"]

func get_aim_degrees() -> float:
	# Bugfix Runde 15: sprite.rotation ist immer 0 -> Mitspieler bekam immer 0 Grad
	return rad_to_deg(facing_direction.angle())

func get_shield() -> int:
	return shield

func add_weapon(weapon_name: String) -> bool:
	# Runde 15: Waffe wird nur INS INVENTAR gelegt - kein Zwangswechsel mehr.
	# Nur wenn man noch die Startpistole hat, wird direkt gewechselt (klares Upgrade).
	if owned_weapons.has(weapon_name):
		return false
	owned_weapons.append(weapon_name)
	if current_weapon == WeaponType.PISTOL and weapon_name != "weapon_pistol":
		switch_weapon(weapon_name)
	return true

func weapon_count() -> int:
	return owned_weapons.size()

func switch_to_index(i: int) -> void:
	if i >= 0 and i < owned_weapons.size():
		switch_weapon(str(owned_weapons[i]))

func switch_weapon(weapon_name: String) -> void:
	var new_weapon: WeaponType = current_weapon
	match weapon_name:
		"weapon_pistol":
			new_weapon = WeaponType.PISTOL
		"weapon_shotgun":
			new_weapon = WeaponType.SHOTGUN
		"weapon_machine":
			new_weapon = WeaponType.MACHINE
		"weapon_laser":
			new_weapon = WeaponType.LASER
		"weapon_revolver":
			new_weapon = WeaponType.REVOLVER
		_:
			return
	if not owned_weapons.has(weapon_name):
		owned_weapons.append(weapon_name)
	current_weapon = new_weapon
	# Runde 49: Beim Waffenwechsel ist das Magazin voll
	var weapon: Dictionary = WEAPON_DATA[current_weapon]
	ammo = int(weapon.get("mag", 0))
	if ammo == 0:
		ammo = -1
	reloading = false
	reload_timer = 0.0
	_update_weapon_visual()

func _update_weapon_visual() -> void:
	if weapon_sprite == null:
		return
	weapon_sprite.texture = TextureManager.get_texture(get_weapon_key())

func get_owned_weapons() -> Array:
	return owned_weapons

func get_weapon_key() -> String:
	return "weapon_" + str(WEAPON_DATA[current_weapon]["name"])

func set_input_direction(direction: Vector2) -> void:
	input_direction = direction
