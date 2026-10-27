extends Node
# COMIC_LANTEST=uistyle - HUD im Comic-Stil

var gm: Node = null
var t: float = 0.0
var step: int = 0
var t0: float = -1.0


func start(gmi: Node) -> void:
	gm = gmi
	set_process(true)


func _process(delta: float) -> void:
	t += delta
	if step == 0 and t > 1.0:
		step = 1
		gm.set("active_map", "jungle")
		gm.set("biome_id", "jungle")
		gm.call("start_game", false, false)
	if step == 1 and int(gm.get("current_state")) == 2:
		if t0 < 0.0:
			t0 = t
		elif t - t0 > 3.5:
			step = 2
			var ui = gm.get("ui_manager")
			ui.call("refresh_weapon_hud", ["pistol", "shotgun"], "pistol")
			var img: Image = get_viewport().get_texture().get_image()
			img.save_png("C:/Users/vince/AppData/Local/hermes/cache/scratch/hud_comic2.png")
			print("[UI] HUD gespeichert")
			get_tree().quit()
