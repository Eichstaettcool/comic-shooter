extends Node
var t := 0.0
var step := 0
func start(_g: Node) -> void: set_process(true)
func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("C:/Users/vince/Games/comic-shooter/screenshots/" + n + ".png")
	print("[SHOT] " + n)
func _process(d: float) -> void:
	t += d
	var gm = get_parent(); var ui = gm.get("ui_manager")
	if step == 0 and t > 6.5:
		step = 1; gm.set("gold", 9000); gm.set("gems", 80); ui.call("_open_chest_page")
	elif step == 1 and t > 8.2:
		step = 2; _shot("130-shop-sym")
	elif step == 2 and t > 8.6:
		step = 3
		# Skin 7 (Gold-Roboter) pruefen
		gm.set("p_rig", 7); gm.set("active_map", "earth"); gm.call("quit_to_menu"); gm.call("start_game", false, false)
	elif step == 3 and t > 12.0:
		step = 4
		var p = gm.get("player")
		if p != null:
			var tex = TextureManager.get_skin_hat_texture(0, 7, 0)
			print("[TEST] Skin7 tex=%s" % str(tex != null))
		get_tree().quit()
