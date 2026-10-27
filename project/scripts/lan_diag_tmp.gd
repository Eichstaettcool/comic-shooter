extends Node
# COMIC_LANTEST=lan - LAN-Fenster im Comic-Stil

var gm: Node = null
var t: float = 0.0
var step: int = 0


func start(gmi: Node) -> void:
	gm = gmi
	set_process(true)


func _process(delta: float) -> void:
	t += delta
	if step == 0 and t > 2.5:
		step = 1
		var ui = gm.get("ui_manager")
		ui.call("_open_lan_panel")
		print("[LAN-UI] offen")
	if step == 1 and t > 4.5:
		step = 2
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png("C:/Users/vince/AppData/Local/hermes/cache/scratch/lan_panel.png")
		print("[LAN-UI] Shot ok")
		get_tree().quit()
