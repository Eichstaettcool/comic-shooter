# MonsterSpawner.gd - Spawnet Monster in Intervallen an zufälligen Positionen
extends Node2D

var active: bool = false
var spawn_interval: float = 30.0
var time_since_last_spawn: float = 0.0
var game_manager: Node = null
var spawn_distance: float = 700.0
var min_interval: float = 10.0
var quality_mult: float = 1.0      # Grafikstufe: laengere Abstaende = weniger Last
var max_monsters: int = 140        # Grafikstufe: harte Obergrenze gleichzeitig

func start_spawning(first_delay: float, interval: float, gm: Node) -> void:
	game_manager = gm
	spawn_interval = interval
	time_since_last_spawn = interval - first_delay  # erste Welle schon nach first_delay
	active = true

func stop_spawning() -> void:
	active = false

func _process(delta: float) -> void:
	if not active or game_manager == null:
		return
	
	time_since_last_spawn += delta
	if time_since_last_spawn >= spawn_interval * quality_mult:
		time_since_last_spawn = 0.0
		_spawn_monster_wave()
	
	# Difficulty: Intervall verringern
	if spawn_interval > min_interval:
		spawn_interval = max(min_interval, spawn_interval - 2.0)

func _spawn_monster_wave() -> void:
	# Performance-Grenze je Grafikstufe: Gesamtzahl der Monster deckeln
	if get_tree().get_nodes_in_group("monsters").size() >= max_monsters:
		return
	var player_pos = game_manager.get_player_position()
	var num_monsters = 1 + min(5, int(Time.get_ticks_msec() / 60000))  # Mehr Monster im Lauf der Zeit
	var wmax = game_manager.MAP_COLS * game_manager.TILE_SIZE - 100.0
	var hmax = game_manager.MAP_ROWS * game_manager.TILE_SIZE - 100.0

	for i in range(num_monsters):
		var angle = randf_range(0, PI * 2)
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * spawn_distance
		# Innerhalb der Welt bleiben (wichtig auf großer Map)
		spawn_pos.x = clampf(spawn_pos.x, 100.0, wmax)
		spawn_pos.y = clampf(spawn_pos.y, 100.0, hmax)
		game_manager.spawn_monster_at(spawn_pos)
