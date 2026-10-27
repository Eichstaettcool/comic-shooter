extends Node
# COMIC_LANTEST=shots - Praesentations-Screenshots
# COMIC_SHOT: start | worlds | skins | settings

var gm: Node = null
var t: float = 0.0
var step: int = 0
var mode: String = ""
var out_dir: String = "C:/Users/vince/Games/comic-shooter/screenshots"
var world_idx: int = 0
var worlds: Array = ["earth", "mars", "jungle", "volt"]
var world_names: Array = ["02-welt-erde", "03-welt-mars", "04-welt-dschungel", "05-welt-elektro"]
var heal_t: float = 0.0


func start(gmi: Node) -> void:
	gm = gmi
	mode = OS.get_environment("COMIC_SHOT")
	if mode == "":
		mode = "start"
	DirAccess.make_dir_recursive_absolute(out_dir)
	set_process(true)


func _shot(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(out_dir + "/" + name + ".png")
	print("[SHOT] %s (%dx%d)" % [name, img.get_width(), img.get_height()])


func _keep_alive(delta: float) -> void:
	heal_t += delta
	if heal_t < 0.2:
		return
	heal_t = 0.0
	var p = gm.get("player")
	if p != null and is_instance_valid(p):
		p.set("health", p.get("max_health"))
		p.set("shield", 40)
		p.set("shield_time", 99.0)


func _process(delta: float) -> void:
	t += delta
	match mode:
		"start":
			if step == 0 and t > 3.0:
				step = 1
				gm.set("gold", 2450)
				gm.get("ui_manager").call("set_start_gold", 2450)
			elif step == 1 and t > 4.0:
				step = 2
				_shot("01-startseite")
				get_tree().quit()
		"worlds":
			if step == 0 and t > 1.0:
				step = 1
				gm.call("set_active_map", worlds[world_idx])
				gm.call("start_game", false, false)
			elif step == 1:
				_keep_alive(delta)
				var ui = gm.get("ui_manager")
				var tl = ui.get("touch_layer")
				if tl != null:
					tl.visible = false
				var cam = gm.get("camera")
				if cam != null and is_instance_valid(cam):
					cam.zoom = Vector2(1.35, 1.35)
				if t > 6.0:
					get_tree().paused = true
				if t > 6.4:
					gm.set("score", 1240)
					ui.call("update_score", 1240)
					step = 2
			elif step == 2:
				_shot(world_names[world_idx])
				world_idx += 1
				if world_idx >= worlds.size():
					get_tree().quit()
				else:
					get_tree().paused = false
					gm.call("quit_to_menu")
					t = 0.0
					step = 0
		"skins":
			if step == 0 and t > 3.0:
				step = 1
				gm.set("gold", 2450)
				gm.get("ui_manager").call("set_start_gold", 2450)
				gm.get("ui_manager").call("_open_char_page")
			elif step == 1 and t > 5.0:
				step = 2
				_shot("06-skins")
				get_tree().quit()
		"settings":
			if step == 0 and t > 3.0:
				step = 1
				gm.set("gold", 2450)
				gm.get("ui_manager").call("set_start_gold", 2450)
				gm.get("ui_manager").call("_open_settings_page")
			elif step == 1 and t > 5.0:
				step = 2
				_shot("07-einstellungen")
				get_tree().quit()
