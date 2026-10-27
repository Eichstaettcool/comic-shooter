extends Node
# COMIC_LANTEST=ui2 - Einstellungen und Sammlung im Menue aufnehmen

var gm: Node = null
var t: float = 0.0
var step: int = 0


func start(gmi: Node) -> void:
	gm = gmi
	set_process(true)


func _process(delta: float) -> void:
	t += delta
	var ui = gm.get("ui_manager")
	if step == 0 and t > 2.0:
		step = 1
		gm.call("quit_to_menu")
		ui.call("_open_settings_page")
		print("[UI2] Einstellungen offen")
	if step == 1 and t > 6.0:
		step = 2
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png("C:/Users/vince/AppData/Local/hermes/cache/scratch/settings2.png")
		ui.call("show_collection")
		print("[UI2] Sammlung offen")
	if step == 2 and t > 8.0:
		step = 3
		var img2: Image = get_viewport().get_texture().get_image()
		img2.save_png("C:/Users/vince/AppData/Local/hermes/cache/scratch/collection.png")
		# Pruefen: sind die Kacheln wirklich gesperrt?
		var page = ui.get("collection_page")
		var btns := 0
		var locked := 0
		var stack := [page]
		while not stack.is_empty():
			var n = stack.pop_back()
			if n == null:
				continue
			for c in n.get_children():
				stack.append(c)
				if c is Button:
					btns += 1
					if c.disabled:
						locked += 1
		print("[UI2] Kacheln=%d gesperrt=%d" % [btns, locked])
		get_tree().quit()
