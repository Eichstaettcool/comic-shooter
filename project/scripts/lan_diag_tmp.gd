extends Node
var t := 0.0
var step := 0
func start(_g: Node) -> void: set_process(true)
func _count_players(gm) -> int:
	var n := 0
	for c in gm.get_tree().root.get_children():
		pass
	var cont = gm.get("player_container")
	if cont != null:
		n = cont.get_child_count()
	return n
func _process(d: float) -> void:
	t += d
	var gm = get_parent()
	if step == 0 and t > 1.4:
		step = 1; gm.call("start_game", false, false)
	elif step == 1 and t > 2.6:
		step = 2
		print("[RUN] Run1 Spieler=%d Monster=%d" % [gm.call("player_nodes").size(), gm.get("wave_remaining")])
		gm.call("debug_unlock_all")
		var dp = gm.get("debug_panel")
		var b = gm.get("current_boss")
		gm.call("quit_to_menu")
		print("[RUN] nach quit: players=%d" % gm.call("player_nodes").size())
	elif step == 2 and t > 3.0:
		step = 3
		gm.call("start_game", false, false)
	elif step == 3 and t > 4.2:
		step = 4
		print("[RUN] Run2 Spieler=%d (erwartet 1)" % gm.call("player_nodes").size())
		get_tree().quit()
