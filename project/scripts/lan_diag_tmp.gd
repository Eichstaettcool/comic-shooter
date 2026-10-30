extends Node
# COMIC_LANTEST=hittest2 - Treffer-RPC pruefen (langes Fenster)

var gm: Node = null
var t: float = 0.0
var step: int = 0
var mode: String = ""
var send_t: float = 0.0


func start(gmi: Node) -> void:
	gm = gmi
	mode = OS.get_environment("COMIC_SHOT")
	set_process(true)


func _process(delta: float) -> void:
	t += delta
	if mode == "host":
		if step == 0 and t > 2.0:
			step = 1
			gm.call("set_active_map", "jungle")
			gm.call("start_lan_host", 2)
		elif step == 1 and NetManager.has_partner():
			step = 2
			gm.call("start_lan_run_as_host")
			print("[HIT2] Host Run")
		elif step == 2 and t > 55.0:
			print("[HIT2] Host Ende")
			get_tree().quit()
	elif mode == "client":
		if step == 0 and t > 4.0:
			step = 1
			NetManager.join_game("127.0.0.1")
		elif step == 1 and int(gm.get("current_state")) == 2:
			step = 2
			print("[HIT2] Client im Run")
		elif step == 2:
			send_t += delta
			if send_t > 2.0:
				send_t = 0.0
				var ghosts = gm.get("_ghosts")
				if ghosts.size() > 0:
					var ids = ghosts.keys()
					var id: int = int(ids[0])
					print("[HIT2] Client meldet Treffer %d (Geister=%d)" % [id, ghosts.size()])
					NetManager.c_send_hit(id, 7)
				else:
					print("[HIT2] noch keine Geister")
			if t > 45.0:
				get_tree().quit()
