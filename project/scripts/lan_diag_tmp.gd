extends Node
# COMIC_LANTEST=earth4 - Wiese mit neuen Bueschen

var gm: Node = null
var t: float = 0.0
var step: int = 0


func start(gmi: Node) -> void:
	gm = gmi
	set_process(true)


func _process(delta: float) -> void:
	t += delta
	if step == 0 and t > 1.0:
		step = 1
		gm.call("set_active_map", "earth")
		gm.call("start_game", false, false)
	if step == 1 and t > 8.0:
		step = 2
		var mg = gm.get("map_generator")
		print("[CHECK] %d Objekte" % mg.get("obstacles").size())
		get_viewport().get_texture().get_image().save_png(
			"C:/Users/vince/AppData/Local/hermes/cache/scratch/earth_v4.png")
		print("[CHECK] ok")
		get_tree().quit()
