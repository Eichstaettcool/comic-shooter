# Projectile.gd - Projektil-Verhalten
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: int = 3
var lifetime: float = 3.0
var is_player_projectile: bool = true
var is_enemy: bool = false
var variant: String = ""              # "" | "banana" (Runde 12)

@onready var sprite = $Sprite2D

func _ready():
	add_to_group("projectiles")
	_apply_layers()
	connect("body_entered", Callable(self, "_on_body_entered"))


func _apply_layers() -> void:
	# Runde 49: Die Layer/Maske haengt an is_enemy + variant. Das wird
	# JEDES MAL neu gesetzt, wenn sich eines davon aendert - sonst
	# greift die Maske aus _ready() (die wurde gesetzt, BEVOR der
	# Aufrufer set_banana()/set_enemy() aufrief, also war die Banane
	# noch ein Spieler-Geschoss und traf den Spieler nie).
	if is_enemy:
		collision_layer = 32
		collision_mask = 17
		sprite.texture = TextureManager.get_texture("banana" if variant == "banana" else "enemy_ball")
	else:
		collision_layer = 4
		collision_mask = 2
		sprite.texture = TextureManager.get_texture("projectile")

func _physics_process(delta: float) -> void:
	if variant == "banana":
		rotation += 11.0 * delta        # Banane dreht sich im Flug
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func set_direction(dir: Vector2, spd: float) -> void:
	direction = dir.normalized()
	speed = spd

func set_damage(dmg: int) -> void:
	damage = dmg

var owner_slot: int = 0          # Runde 33: welcher Spieler hat geschossen (MP-Coins)
var chain_hops: int = 0          # Runde 55: Blitzkette springt nach Treffer weiter
var gm: Node = null              # Runde 55: fuer die Ketten-Suche


func _chain_from(hit_body) -> void:
	# Runde 55: Die Kette springt jetzt beim EINSCHLAG weiter, nicht nach
	# einem Timer. Sucht den naechsten ANDEREN lebenden Spieler.
	if gm == null:
		return
	var ps = gm.get("players")
	if ps == null:
		return
	var best = null
	var bd: float = 1e20
	for s in ps.keys():
		var p = ps[s]
		if p == hit_body or not is_instance_valid(p):
			continue
		if bool(p.get("downed")) or bool(p.get("spectating")):
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < bd:
			bd = d
			best = p
	if best == null:
		print("[BOSS][ABILITY] Kette: kein zweiter Spieler -> Ende")
		return
	var dir2: Vector2 = (best.global_position - global_position).normalized()
	gm.call("spawn_projectile", global_position + dir2 * 24.0, dir2, maxi(1, damage - 1), 340.0)
	print("[BOSS][ABILITY] Blitzkette springt per Treffer auf Slot %s" % str(best.get("player_id")))

func set_enemy(dmg: int) -> void:
	is_enemy = true
	damage = dmg
	# Runde 49: Layer/Maske sofort nachziehen - der Aufrufer ruft
	# set_enemy() MEIST NACH add_child(), also ist _ready() schon
	# gelaufen und hat die Spieler-Maske gesetzt.
	if is_inside_tree():
		_apply_layers()

func set_banana(dmg: int) -> void:
	is_enemy = true
	damage = dmg
	variant = "banana"
	# Runde 49: Siehe set_enemy() - ohne das fliegt die Banane mit der
	# Spieler-Maske und verfehlt den Spieler komplett.
	if is_inside_tree():
		_apply_layers()

func _on_body_entered(body) -> void:
	if is_enemy:
		# Gegner-Kugel trifft Spieler oder vergeht an Hindernissen
		if body.is_in_group("player"):
			# Runde 49: Der Spieler hat take_damage(amount) - EIN Argument.
			# Der Aufruf mit 2 Argumenten ist fehlgeschlagen, dadurch
			# machten alle Gegner-Geschosse (u. a. die Affen-Bananen)
			# KEINEN Schaden mehr.
			if body.has_method("take_damage"):
				body.call("take_damage", damage)
			# Runde 55: Blitzkette springt beim Treffer weiter
			if chain_hops > 0:
				_chain_from(body)
			queue_free()
		elif body is StaticBody2D:
			queue_free()
	elif body.is_in_group("monsters"):
		if body.has_method("take_damage"):
			SoundManager.play("hit")
			# Runde 49: Der Trefferpunkt wird uebergeben, damit der Boss
			# pruefen kann, ob ein WEAK POINT getroffen wurde.
			var local_hit: Vector2 = global_position - body.global_position
			body.take_damage(damage, owner_slot, local_hit)
		queue_free()
