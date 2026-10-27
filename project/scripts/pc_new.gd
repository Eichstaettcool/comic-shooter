# PlayerController.gd - Spieler-Bewegung, Schiessen und Gesundheit
extends CharacterBody2D

signal health_changed(new_health: int)
signal player_died

const SPEED: float = 160.0
const MAX_HEALTH: int = 5

var health: int = MAX_HEALTH
var input_direction: Vector2 = Vector2.ZERO
var shoot_requested: bool = false

# Waffen-System
enum WeaponType { PISTOL, SHOTGUN, MACHINE }
var current_weapon: WeaponType = WeaponType.PISTOL
var weapon_cooldown: float = 0.0
var can_shoot: bool = true
var facing_direction: Vector2 = Vector2.RIGHT

const WEAPON_DATA = {
	WeaponType.PISTOL: {
		"name": "pistol",
		"damage": 3,
		"cooldown": 0.4,
		"speed": 300.0,
	},
	WeaponType.SHOTGUN: {
		"name": "shotgun",
		"damage": 5,
		"cooldown": 0.8,
		"speed": 250.0,
		"spread": 3,
	},
	WeaponType.MACHINE: {
		"name": "machine",
		"damage": 2,
		"cooldown": 0.1,
		"speed": 350.0,
	}
}

var projectile_scene: PackedScene = null

@onready var sprite = $Sprite2D
@onready var weapon_holder = $WeaponHolder

func _ready():
	add_to_group("player")
	collision_layer = 1
	collision_mask = 10  # Layer 2 (Monster) + Layer 8 (Items)
	sprite.texture = TextureManager.get_texture("player")
	projectile_scene = load("res://scenes/Projectile.tscn") as PackedScene

func _physics_process(delta: float) -> void:
	# Waffen-Cooldown
	if weapon_cooldown > 0:
		weapon_cooldown -= delta
		if weapon_cooldown <= 0:
			can_shoot = true

	# Eingabe verarbeiten (Touch + Keyboard)
	var input_dir = input_direction
	if input_dir == Vector2.ZERO:
		# Keyboard-Fallback für Desktop-Tests
		input_dir = Vector2.ZERO
		if Input.is_key_pressed(Key.W) or Input.is_key_pressed(Key.Up):
			input_dir.y -= 1
		if Input.is_key_pressed(Key.S) or Input.is_key_pressed(Key.Down):
			input_dir.y += 1
		if Input.is_key_pressed(Key.A) or Input.is_key_pressed(Key.Left):
			input_dir.x -= 1
		if Input.is_key_pressed(Key.D) or Input.is_key_pressed(Key.Right):
			input_dir.x += 1

	# Bewegung
	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * SPEED
		facing_direction = input_dir.normalized()
		if input_dir.x > 0:
			sprite.flip_h = false
			weapon_holder.position.x = 24
		elif input_dir.x < 0:
			sprite.flip_h = true
			weapon_holder.position.x = -24
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Schießen (Touch-Button oder Space-Taste)
	var shoot_input = shoot_requested or Input.is_key_pressed(Key.Space)
	if shoot_input and can_shoot:
		_shoot()
	shoot_requested = false

func _shoot() -> void:
	if projectile_scene == null:
		return
	var weapon = WEAPON_DATA[current_weapon]
	can_shoot = false
	weapon_cooldown = weapon["cooldown"]

	var proj_speed = weapon["speed"]
	var proj_damage = weapon["damage"]

	if current_weapon == WeaponType.SHOTGUN and weapon.has("spread"):
		var spread_count = weapon["spread"]
		for i in range(spread_count):
			var angle_offset = (float(i) / float(spread_count - 1) - 0.5) * 0.3
			var proj = projectile_scene.instantiate()
			proj.position = weapon_holder.global_position
			var dir = facing_direction.rotated(angle_offset)
			proj.set_direction(dir, proj_speed)
			proj.set_damage(proj_damage)
			get_parent().add_child(proj)
	else:
		var proj = projectile_scene.instantiate()
		proj.position = weapon_holder.global_position
		proj.set_direction(facing_direction, proj_speed)
		proj.set_damage(proj_damage)
		get_parent().add_child(proj)

func take_damage(amount: int) -> void:
	health -= amount
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("player_died")
		queue_free()

func heal(amount: int) -> void:
	health = min(health + amount, MAX_HEALTH)
	emit_signal("health_changed", health)

func switch_weapon(weapon_name: String) -> void:
	var new_weapon: WeaponType
	match weapon_name:
		"weapon_pistol":
			new_weapon = WeaponType.PISTOL
		"weapon_shotgun":
			new_weapon = WeaponType.SHOTGUN
		"weapon_machine":
			new_weapon = WeaponType.MACHINE
		_:
			return

	if new_weapon != current_weapon:
		current_weapon = new_weapon

func set_input_direction(direction: Vector2) -> void:
	input_direction = direction

func set_shoot_request(value: bool) -> void:
	shoot_requested = value

func get_health() -> int:
	return health
