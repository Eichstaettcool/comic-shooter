# CreateScenes.gd - Autoload-Bootstrap: erstellt alle .tscn beim ersten Start
extends Node

func _ready() -> void:
	if not ResourceLoader.exists("res://scenes/Main.tscn"):
		print("Erzeuge .tscn-Szenen (Erststart) ...")
		_create_all_scenes()
	# Danach die eigentliche Spielszene laden
	get_tree().change_scene_to_file.call_deferred("res://scenes/Main.tscn")

func _create_all_scenes() -> void:
	_create_player_scene()
	_create_monster_scene()
	_create_projectile_scene()
	_create_chest_scene()
	_create_item_scene()
	_create_main_scene()
	print("Alle .tscn-Szenen wurden erstellt!")

func _prepare_for_pack(root: Node) -> void:
	# pack() speichert nur Nodes mit owner; das Root selbst darf keinen owner bekommen
	for child in root.get_children():
		_set_owner_recursive(child, root)

func _set_owner_recursive(node: Node, root: Node) -> void:
	node.owner = root
	for child in node.get_children():
		_set_owner_recursive(child, root)

# --- Player Scene ---
func _create_player_scene() -> void:
	var scene = PackedScene.new()
	var root = CharacterBody2D.new()
	root.name = "Player"
	root.collision_layer = 1
	root.collision_mask = 10  # Layer 2 (Monster) + Layer 4 (Items)

	var script = load("res://scripts/player_controller.gd")
	root.set_script(script)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 16
	collision.shape = shape
	root.add_child(collision)

	var weapon_holder = Node2D.new()
	weapon_holder.name = "WeaponHolder"
	weapon_holder.position = Vector2(24, 0)
	root.add_child(weapon_holder)

	_prepare_for_pack(root)
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/Player.tscn")
	print("Player.tscn erstellt")

# --- Monster Scene ---
func _create_monster_scene() -> void:
	var scene = PackedScene.new()
	var root = CharacterBody2D.new()
	root.name = "Monster"
	root.collision_layer = 2
	root.collision_mask = 1

	var script = load("res://scripts/monster_ai.gd")
	root.set_script(script)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 14
	collision.shape = shape
	root.add_child(collision)

	_prepare_for_pack(root)
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/Monster.tscn")
	print("Monster.tscn erstellt")

# --- Projectile Scene ---
func _create_projectile_scene() -> void:
	var scene = PackedScene.new()
	var root = Area2D.new()
	root.name = "Projectile"
	root.collision_layer = 4
	root.collision_mask = 2

	var script = load("res://scripts/entities/projectile.gd")
	root.set_script(script)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 4
	collision.shape = shape
	root.add_child(collision)

	_prepare_for_pack(root)
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/Projectile.tscn")
	print("Projectile.tscn erstellt")

# --- Chest Scene ---
func _create_chest_scene() -> void:
	var scene = PackedScene.new()
	var root = Area2D.new()
	root.name = "Chest"
	root.collision_layer = 8
	root.collision_mask = 1

	var script = load("res://scripts/systems/chest_system.gd")
	root.set_script(script)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 18
	collision.shape = shape
	root.add_child(collision)

	var timer = Timer.new()
	timer.name = "OpenTimer"
	timer.wait_time = 3.0
	timer.one_shot = true
	root.add_child(timer)

	var prompt = Label.new()
	prompt.name = "PromptLabel"
	prompt.position = Vector2(-30, -50)
	prompt.size = Vector2(100, 30)
	prompt.text = "Halten: 3s"
	prompt.hide()
	root.add_child(prompt)

	_prepare_for_pack(root)
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/Chest.tscn")
	print("Chest.tscn erstellt")

# --- Item Scene (Weapon + Heart) ---
func _create_item_scene() -> void:
	var scene = PackedScene.new()
	var root = Area2D.new()
	root.name = "Item"
	root.collision_layer = 8
	root.collision_mask = 1

	var script = load("res://scripts/entities/item_system.gd")
	root.set_script(script)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)

	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	root.add_child(collision)

	_prepare_for_pack(root)
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/Item.tscn")
	print("Item.tscn erstellt")

# --- Main Scene ---
func _create_main_scene() -> void:
	var scene = PackedScene.new()
	var root = Node2D.new()
	root.name = "Main"

	var script = load("res://scripts/game_manager.gd")
	root.set_script(script)

	# YSort für korrekte Render-Reihenfolge
	var ysort = Node2D.new()
	ysort.name = "YSort"
	ysort.set_y_sort_enabled(true)
	root.add_child(ysort)

	# Container
	var monster_container = Node2D.new()
	monster_container.name = "MonsterContainer"
	ysort.add_child(monster_container)

	var chest_container = Node2D.new()
	chest_container.name = "ChestContainer"
	ysort.add_child(chest_container)

	var item_container = Node2D.new()
	item_container.name = "ItemContainer"
	ysort.add_child(item_container)

	# MapGenerator
	var map_gen = Node2D.new()
	map_gen.name = "MapGenerator"
	map_gen.set_script(load("res://scripts/map_generator.gd"))
	ysort.add_child(map_gen)

	# MonsterSpawner
	var spawner = Node2D.new()
	spawner.name = "MonsterSpawner"
	spawner.set_script(load("res://scripts/entities/monster/monster_spawner.gd"))
	root.add_child(spawner)

	# Camera
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 25 * 32
	camera.limit_bottom = 25 * 32
	root.add_child(camera)

	# CanvasLayer for UI
	var canvas = CanvasLayer.new()
	canvas.name = "CanvasLayer"
	root.add_child(canvas)

	# UIManager
	var ui_manager = Node.new()
	ui_manager.name = "UIManager"
	ui_manager.set_script(load("res://scripts/ui/ui_manager.gd"))
	canvas.add_child(ui_manager)

	_prepare_for_pack(root)
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/Main.tscn")
	print("Main.tscn erstellt")

# Public API für manuellen Aufruf (falls --script nicht funktioniert)
func _run():
	_create_all_scenes()
	if get_tree() != null:
		get_tree().quit()
