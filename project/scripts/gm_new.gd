# GameManager.gd - Zentraler Spiel-Controller
# Verwaltet Spielzustände, Score, Map, Monster-Spawning und UI-Übergänge
extends Node2D

enum GameState { MENU, PLAYING, DEAD }
var current_state: GameState = GameState.MENU
var score: int = 0
var high_score: int = 0
var player_health: int = 5
const MAX_HEALTH: int = 5

# Game-Einstellungen
const MAP_COLS: int = 25
const MAP_ROWS: int = 25
const TILE_SIZE: int = 32
const NUM_CHESTS: int = 8
const NUM_TREES: int = 25
const NUM_ROCKS: int = 15
const MONSTER_SPAWN_INTERVAL: float = 30.0
const FIRST_WAVE_DELAY: float = 5.0

# Node-Referenzen
@onready var ysort = $YSort
@onready var monster_container = $YSort/MonsterContainer
@onready var chest_container = $YSort/ChestContainer
@onready var item_container = $YSort/ItemContainer
@onready var camera = $Camera2D
@onready var map_generator = $MapGenerator
@onready var monster_spawner = $MonsterSpawner
@onready var ui_manager = $CanvasLayer/UIManager

var player: Node2D = null

# Szenen werden per load() geladen (nicht preload, da sie per create_scenes.gd erstellt werden)
var player_scene: PackedScene = null
var monster_scene: PackedScene = null
var chest_scene: PackedScene = null
var item_scene: PackedScene = null

func _ready():
	_load_high_score()
	_load_scenes()
	ui_manager.register_references(self, null)
	_setup_initial_state()

func _load_scenes() -> void:
	player_scene = load("res://scenes/Player.tscn") as PackedScene
	monster_scene = load("res://scenes/Monster.tscn") as PackedScene
	chest_scene = load("res://scenes/Chest.tscn") as PackedScene
	item_scene = load("res://scenes/Item.tscn") as PackedScene

func _setup_initial_state():
	current_state = GameState.MENU
	score = 0
	ui_manager.show_start_screen()
	ui_manager.set_start_score(high_score)

func start_game():
	if current_state != GameState.MENU:
		return
	current_state = GameState.PLAYING
	score = 0
	player_health = MAX_HEALTH

	# Karte generieren
	map_generator.generate_map(MAP_COLS, MAP_ROWS, TILE_SIZE)
	map_generator.place_obstacles(NUM_TREES, NUM_ROCKS)

	# Kisten platzieren
	_place_chests()

	# Monster-Spawning starten
	monster_spawner.start_spawning(FIRST_WAVE_DELAY, MONSTER_SPAWN_INTERVAL, self)

	# Spieler erstellen
	player = player_scene.instantiate()
	player.position = map_generator.get_center()
	ysort.add_child(player)
	player.connect("health_changed", Callable(self, "_on_player_health_changed"))
	player.connect("player_died", Callable(self, "_on_player_died"))

	# UI registrieren
	ui_manager.register_references(self, player)

	# Kamera folgt Spieler
	camera.reparent(player)
	camera.make_current()

	# UI anzeigen
	ui_manager.show_hud()
	ui_manager.update_health(MAX_HEALTH, MAX_HEALTH)
	ui_manager.update_score(score)

func _place_chests():
	var positions = map_generator.get_random_walkable_positions(NUM_CHESTS, margin=5)
	for pos in positions:
		var chest = chest_scene.instantiate()
		chest.position = pos
		chest.connect("item_spawned", Callable(self, "_on_chest_item_spawned"))
		chest_container.add_child(chest)

func _on_player_health_changed(new_health: int):
	player_health = new_health
	ui_manager.update_health(player_health, MAX_HEALTH)

func _on_player_died():
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.DEAD

	# High Score speichern
	if score > high_score:
		high_score = score
		_save_high_score()

	# Death Screen anzeigen
	ui_manager.show_death_screen(score, high_score)

func _on_chest_item_spawned(item_type: String, position: Vector2):
	var item = item_scene.instantiate()
	item.set_item_type(item_type)
	item.position = position
	item.connect("picked_up", Callable(self, "_on_item_picked_up"))
	item_container.add_child(item)

func _on_item_picked_up(item_type: String):
	if item_type == "heart":
		if is_instance_valid(player):
			player.call("heal", 1)
			ui_manager.update_health(player_health, MAX_HEALTH)
	elif item_type.begins_with("weapon"):
		if is_instance_valid(player):
			player.call("switch_weapon", item_type)

func spawn_monster_at(position: Vector2):
	var monster = monster_scene.instantiate()
	monster.position = position
	if is_instance_valid(player):
		monster.set_target(player)
	monster.connect("monster_killed", Callable(self, "_on_monster_killed"))
	monster.connect("damage_player", Callable(self, "_on_monster_damage_player"))
	monster_container.add_child(monster)

func _on_monster_killed(points: int):
	score += points
	ui_manager.update_score(score)

func _on_monster_damage_player(damage: int):
	if is_instance_valid(player):
		player.call("take_damage", damage)

func restart_game():
	# Alle Container bereinigen
	for child in monster_container.get_children():
		child.queue_free()
	for child in chest_container.get_children():
		child.queue_free()
	for child in item_container.get_children():
		child.queue_free()

	# Spieler entfernen
	if is_instance_valid(player):
		player.queue_free()
		player = null

	# Kamera zurücksetzen
	if is_instance_valid(camera):
		camera.reparent(self)

	# Karte bereinigen
	map_generator.clear_map()

	# Monster-Spawner stoppen
	monster_spawner.stop_spawning()

	# UI zurücksetzen
	ui_manager.register_references(self, null)
	_setup_initial_state()

func exit_game():
	get_tree().quit()

func get_player_position() -> Vector2:
	if is_instance_valid(player):
		return player.position
	return Vector2.ZERO

func _load_high_score():
	var save_path = "user://savegame.save"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()

func _save_high_score():
	var save_path = "user://savegame.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()
