# generate.gd - Bootstrap für Headless-Szenen-Generierung
# Aufruf: Godot.exe --headless --path <projekt> --script res://scripts/generate.gd
extends SceneTree

func _initialize() -> void:
	print("Generiere .tscn-Szenen ...")
	var creator = load("res://scripts/create_scenes.gd").new()
	creator._create_all_scenes()
	creator.free()
	print("Fertig.")
	quit()
