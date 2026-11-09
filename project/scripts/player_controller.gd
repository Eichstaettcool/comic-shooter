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
var _touch_count: int = 0
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
var _protect_logged: bool = false   # B3: Log nur einmal pro Schutzphase

# --- LAN/Co-op-Modi ---
var local_controlled: bool = false   # Runde 88: dieser Knoten wird lokal gesteuert (Client)
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
		# Runde 107: 0..5 war fest verdrahtet - dadurch wurden GEIST/WIKINGER/ALIEN
		# auf MARS-MARSCHALL geklemmt. Man spielte also einen anderen Skin.
		# v1.42 (P11.3): Skins mit gezeichneter Waffe bekommen die Fassung OHNE
		# Deko, weil im Spiel die echte Waffe in der Hand liegt.
		var deco: bool = TextureManager.rig_has_deco_weapon(rig)
		var st = TextureManager.get_skin_hat_texture(color_idx, clampi(rig, 0, TextureManager.RIG_NAMES.size() - 1), hat_idx, deco)
		if st != null:
			sprite.texture = st
			_apply_weapon_anchor(rig)
			return
	if sprite != null:
		sprite.texture = TextureManager.get_player_texture(color_idx, hat_idx)
		_apply_weapon_anchor(0)
	if player_id == 2 and color_idx == 0 and hat_idx == 0:
		sprite.texture = TextureManager.get_player_texture(1, 0)   # P2 bleibt rot
		_apply_weapon_anchor(0)


func _apply_weapon_anchor(rig: int) -> void:
	# v1.42 (P11.1/P11.2): Handanker des Skins merken und die echte Waffe
	# darueber zeichnen. (56,32) entspricht dem bisherigen Offset (24,0).
	hand_anchor = TextureManager.hand_anchor_of(rig)
	if weapon_holder != null:
		weapon_holder.z_index = 2
	var hand_px: Vector2 = hand_anchor
	print("[SKIN][HAND] rig=%d hand=(%d,%d) waffe=%s ueber_deko=true z=+1 deko=%s" % [
		rig, int(hand_px.x), int(hand_px.y), get_weapon_key(),
		"aus" if TextureManager.rig_has_deco_weapon(rig) else "an"])


func _hand_offset() -> Vector2:
	# Anker in Textur-Pixeln -> Offset vom Koerperzentrum (32,32)
	return hand_anchor - Vector2(32.0, 32.0)

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

# v1.56 (Spec K5/P1): Unverwundbarkeit nach einem Treffer. Ohne sie kostete
# eine Gruppe gleichzeitig beruehrender Gegner in einem Frame mehrere Herzen -
# genau das "sofort tot", das den Spielspass zerstoert. 0,6 s sind kurz genug,
# um nicht zu schuetzen, aber lang genug, dass eine Menge nicht mehr salvenartig
# abzieht.
const IFRAME_MS := 600
var iframe_until_ms: int = 0

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
const WEAPON_DATA := WeaponsModule.WEAPON_DATA

# ============================================================
# Runde 136 (J): Waffen-Seltenheiten
# Jede aufgenommene Waffe bekommt eine Stufe. Die Stufe skaliert Schaden,
# Nachladezeit, Magazin und Projektiltempo - eine Tabelle, keine Streuung.
# ============================================================
const RARITY_NAMES := WeaponsModule.RARITY_NAMES
const RARITY_LABEL := WeaponsModule.RARITY_LABEL
const RARITY_COLOR := WeaponsModule.RARITY_COLOR
const RARITY_WEIGHTS := WeaponsModule.RARITY_WEIGHTS
const WEAPON_RARITY := WeaponsModule.WEAPON_RARITY

var weapon_rarity: Dictionary = {}      # "weapon_shotgun" -> "epic"

func roll_weapon_rarity() -> String: return _wpn_p().roll_weapon_rarity()


func rarity_mult(key: String, field: String) -> float: return _wpn_p().rarity_mult(key, field)


func weapon_key_of(t: int) -> String: return _wpn_p().weapon_key_of(t)


func _wd(t: int = -1) -> Dictionary: return _wpn_p()._wd(t)


func effective_stats(t: int) -> Dictionary: return _wpn_p().effective_stats(t)


func dps_of(t: int) -> float: return _wpn_p().dps_of(t)


func dps_table() -> Array: return _wpn_p().dps_table()

# v1.42 (P2): Stufenbelege und Anzeige-Texte
func check_rarity_table() -> bool: return _wpn_p().check_rarity_table()


func dps_at(t: int, stufe: String) -> float: return _wpn_p().dps_at(t, stufe)


func rarity_label(key: String) -> String: return _wpn_p().rarity_label(key)

var projectile_scene: PackedScene = null

# --- Runde 15: Utilitys, Zielen, Tasten ---
var utilities: Dictionary = { "potion": 0, "bomb": 0 }
var aim_assist: int = 1
var _key_state: Dictionary = {}
var _last_mouse: Vector2 = Vector2.ZERO
var aim_line: Line2D = null
# v1.42 (P11): Handanker der aktuellen Spielfigur (Textur-Pixel)
var hand_anchor: Vector2 = Vector2(56, 32)

# v1.42 (P3): Trank regeneriert 3 LP ueber 4,5 s (1 LP je 1,5 s)
const TRANK_HP := 3
const TRANK_INTERVALL := 1.5
const TRANK_QUEUE_MAX := 1
var regen_left: int = 0
var regen_t: float = 0.0
var regen_ticks_done: int = 0
var regen_queue: int = 0
var regen_heart: Sprite2D = null

func add_utility(kind: String, n: int = 1) -> void:
	utilities[kind] = int(utilities.get(kind, 0)) + n
	if gm != null and gm.has_method("refresh_utility_hud"):
		gm.call("refresh_utility_hud")

func use_potion() -> bool:
	# v1.46 (B2): OHNE VORRAT - Trank und Bombe sind im Run gesperrt.
	if gm != null and gm.has_method("chal_regel") and bool(gm.call("chal_regel", "verbrauch")):
		print("[CHAL][SPERRE] verbrauch=potion id=%s" % str(gm.get("chal_id")))
		return false
	# v1.42 (P3): Der Trank heilt nicht mehr sofort 2 LP, sondern regeneriert
	# 3 Herzen ueber 4,5 s (1 LP je 1,5 s). Ein zweiter Trank wartet.
	if int(utilities.get("potion", 0)) <= 0:
		return false
	if regen_left > 0:
		if regen_queue >= TRANK_QUEUE_MAX:
			print("[TRANK][REGEN] FEHLER: schon ein Trank in Warteschlange (queue=%d)" % regen_queue)
			return false
		utilities["potion"] = int(utilities["potion"]) - 1
		regen_queue += 1
		print("[TRANK][REGEN] queue=%d (laeuft weiter: %d LP offen)" % [regen_queue, regen_left])
		if gm != null and gm.has_method("refresh_utility_hud"):
			gm.call("refresh_utility_hud")
		return true
	if health >= max_health:
		return false
	utilities["potion"] = int(utilities["potion"]) - 1
	_start_regen()
	if gm != null and gm.has_method("refresh_utility_hud"):
		gm.call("refresh_utility_hud")
	return true


func _start_regen() -> void:
	# P3.2: nur bis zum Maximum auffuellen, ueberschuessige Ticks verfallen
	regen_left = mini(TRANK_HP, max_health - health)
	regen_ticks_done = 0
	regen_t = 0.0
	if regen_left <= 0:
		print("[TRANK][REGEN] ende hp=%d/%d ticks=0 rest=0 (voller Balken)" % [health, max_health])
		return
	print("[TRANK][REGEN] start hp=%d/%d ziel=%d dauer=%.1fs" % [
		health, max_health, mini(health + regen_left, max_health),
		float(regen_left) * TRANK_INTERVALL])
	SoundManager.play("pickup")
	_show_regen_heart(true)


func _tick_regen(delta: float) -> void:
	if regen_left <= 0:
		return
	regen_t += delta
	while regen_left > 0 and regen_t >= TRANK_INTERVALL:
		regen_t -= TRANK_INTERVALL
		if health >= max_health:
			regen_left = 0
			break
		health = mini(health + 1, max_health)
		regen_left -= 1
		regen_ticks_done += 1
		emit_signal("health_changed", health)
		print("[TRANK][REGEN] +1 LP (%d/%d)" % [health, max_health])
		_pulse_regen_heart()
	if regen_left <= 0:
		print("[TRANK][REGEN] ende hp=%d/%d ticks=%d rest=%d" % [
			health, max_health, regen_ticks_done, regen_left])
		_show_regen_heart(false)
		if regen_queue > 0 and health < max_health:
			regen_queue -= 1
			_start_regen()


func _show_regen_heart(an: bool) -> void:
	# P3.3: pulsierendes Herz ueber dem Spieler waehrend der Regeneration
	if not an:
		if regen_heart != null and is_instance_valid(regen_heart):
			regen_heart.queue_free()
		regen_heart = null
		return
	if regen_heart != null and is_instance_valid(regen_heart):
		return
	var s := Sprite2D.new()
	s.name = "RegenHerz"
	# v1.42 (P3.3): vorhandene Herz-Textur (Registry-Schluessel), sonst Skalierung aus
	s.texture = TextureManager.get_texture("heart_big")
	if s.texture == null:
		s.texture = TextureManager.get_texture("heart_full")
	if s.texture == null:
		s.texture = TextureManager.get_texture("heart_gold")
	s.position = Vector2(0, -56)
	s.scale = Vector2(0.55, 0.55)
	s.z_index = 60
	add_child(s)
	regen_heart = s
	print("[TRANK][REGEN] herz_tex=%s" % str(s.texture != null))
	_pulse_regen_heart()


func _pulse_regen_heart() -> void:
	if regen_heart == null or not is_instance_valid(regen_heart):
		return
	var tw := regen_heart.create_tween()
	tw.tween_property(regen_heart, "scale", Vector2(1.35, 1.35), 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(regen_heart, "scale", Vector2(0.95, 0.95), 0.28).set_trans(Tween.TRANS_SINE)

func use_bomb() -> bool:
	# v1.46 (B2): OHNE VORRAT - Bomben sind im Run gesperrt.
	if gm != null and gm.has_method("chal_regel") and bool(gm.call("chal_regel", "verbrauch")):
		print("[CHAL][SPERRE] verbrauch=bombe id=%s" % str(gm.get("chal_id")))
		return false
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
	# v1.42 (P3): Trank-Regeneration laeuft auch waehrend Bewegung
	_tick_regen(delta)
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
			var weapon: Dictionary = _wd()
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
	# Runde 91: Auf Mobile kann der Touch-Knopf "haengen" (released kommt nicht
	# an, wenn der Finger woanders hochgeht). Dann feuert der Spieler dauerhaft.
	# Wenn kein Finger mehr auf dem Schirm ist, wird der Zustand hart geloescht.
	if OS.has_feature("mobile") and shoot_held and _touch_count == 0:
		shoot_held = false
	if shooting_allowed and (shoot_held or key_shoot) and can_shoot:
		_shoot()

func _start_reload() -> void:
	# Runde 49: Nachladen starten
	if reloading:
		return
	var weapon: Dictionary = _wd()
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
	var weapon: Dictionary = _wd()
	var rl: float = float(weapon.get("reload", 0.0))
	if rl <= 0.0:
		return 0.0
	return clampf(1.0 - reload_timer / rl, 0.0, 1.0)


func get_ammo_text() -> String:
	# Runde 49: Munitionstext fuer das HUD
	var weapon: Dictionary = _wd()
	var mag: int = int(weapon.get("mag", 0))
	if mag <= 0:
		return ""
	if reloading:
		return "NACHLADEN %.1fs" % maxf(0.0, reload_timer)
	return "%d / %d" % [maxi(0, ammo), mag]


func _shoot() -> void:
	if projectile_scene == null:
		return
	var weapon = _wd()
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
	weapon_holder.position = _hand_offset().rotated(angle)
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
	weapon_holder.position = (_hand_offset() - Vector2(12, 0)).rotated(angle)
	if recoil_tween != null and recoil_tween.is_valid():
		recoil_tween.kill()
	recoil_tween = create_tween()
	recoil_tween.tween_property(weapon_holder, "position", _hand_offset().rotated(angle), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Comic-Squash
	sprite.scale = Vector2(1.12, 0.9)
	if punch_tween != null and punch_tween.is_valid():
		punch_tween.kill()
	punch_tween = create_tween()
	punch_tween.tween_property(sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
	# Finger auf dem Schirm zaehlen, damit ein haengender Touch-Knopf erkannt wird
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_count += 1
		else:
			_touch_count = maxi(0, _touch_count - 1)


func _unhandled_input(event: InputEvent) -> void:
	# Runde 90: Mausfeuer nur am Desktop. Auf Android wuerde die
	# Touch-Emulation dauerhaft "Maustaste gedrueckt" melden.
	if OS.has_feature("mobile"):
		return
	if remote_controlled or remote_driven:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		set_shoot_held(event.pressed)


func set_shoot_held(value: bool) -> void:
	shoot_held = value

var god_mode: bool = false

func take_damage(amount: int) -> void:
	if god_mode:
		return
	# B3: Im Co-op laeuft die Welt weiter, waehrend jemand Karten waehlt.
	# Der Waehlende ist in dieser Zeit unverwundbar - sonst stirbt er blind
	# hinter dem Kartenfenster.
	if gm != null and gm.has_method("is_protected") and bool(gm.call("is_protected", player_id)):
		if not _protect_logged:
			_protect_logged = true
			print("[B3][SCHUTZ] Slot %d ignoriert Schaden (Karten offen)" % player_id)
		return
	_protect_logged = false
	# Runde 50: Wer schon liegt, nimmt keinen weiteren Schaden
	if downed:
		return
	# v1.56: 0,6 s Unverwundbarkeit nach einem echten Treffer
	if iframe_until_ms > 0 and Time.get_ticks_msec() < iframe_until_ms:
		return
	regen_timer = 0.0
	if shield > 0:
		shield -= 1
		shield_time = SHIELD_DURATION
		SoundManager.play("hit")
		emit_signal("health_changed", health)
		return
	SoundManager.play("hurt")
	# v1.56: JEDER echte LP-Verlust zaehlt als Treffer - auch Kontaktschaden,
	# der direkt am Spieler landet (nicht ueber game_manager._on_monster_damage_player).
	if gm != null and gm.has_method("_bal_treffer"):
		gm.call("_bal_treffer", amount)
	# v1.46 (B2): UNBERUEHRT - jeder echte LP-Verlust zaehlt als Treffer.
	if gm != null and gm.has_method("chal_damage_taken"):
		gm.call("chal_damage_taken", amount)
	health -= amount
	iframe_until_ms = Time.get_ticks_msec() + IFRAME_MS
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
		# Runde 99: Im LAN darf der Knoten NIE geloescht werden - der Host
		# braucht ihn fuer Downed/Revive. Vorher verschwand Slot 1 und war
		# gleichzeitig als "liegt" im Log.
		var in_lan: bool = gm != null and bool(gm.get("lan_mode"))
		if in_lan:
			print("[LAN][DEATH] health<=0 -> Knoten bleibt (LAN)")
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
	# Runde 136 (J1): Seltenheitsstufe beim AUFNEHMEN rollen
	if not weapon_rarity.has(weapon_name):
		weapon_rarity[weapon_name] = roll_weapon_rarity()
	var tid: int = -1
	match weapon_name:
		"weapon_pistol":
			tid = WeaponType.PISTOL
		"weapon_shotgun":
			tid = WeaponType.SHOTGUN
		"weapon_machine":
			tid = WeaponType.MACHINE
		"weapon_laser":
			tid = WeaponType.LASER
		"weapon_revolver":
			tid = WeaponType.REVOLVER
	if tid >= 0:
		var st: Dictionary = effective_stats(tid)
		print("[WPN][DROP] waffe=%s seltenheit=%s schaden=%d tempo=%.2f mag=%d" % [
			str(st["waffe"]), str(st["stufe"]), int(st["schaden"]), float(st["tempo"]), int(st["mag"])])
		if gm != null and gm.has_method("on_weapon_pickup"):
			gm.call("on_weapon_pickup", weapon_name, str(st["stufe"]), st)
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
	# Runde 136 (J1): auch die Startpistole bekommt eine Stufe
	if not weapon_rarity.has(weapon_name):
		weapon_rarity[weapon_name] = roll_weapon_rarity()
	# Runde 49: Beim Waffenwechsel ist das Magazin voll
	var weapon: Dictionary = _wd()
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


var _wpn: WeaponsModule = null

func _wpn_p() -> WeaponsModule:
	if _wpn == null:
		_wpn = WeaponsModule.new()
		_wpn.host = self
	return _wpn
