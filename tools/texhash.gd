extends SceneTree

# Textur-Fingerprint: erzeugt alle Texturen und hasht die Pixeldaten.
# Beleg fuer Block C: gleiche Hashes vor/nach dem Modul-Split = gleiche Pixel.

func _hash_texture(t) -> String:
	if t == null:
		return "null"
	var img: Image = null
	if t is ImageTexture:
		img = t.get_image()
	elif t is Texture2D:
		img = t.get_image()
	if img == null:
		return "keinbild"
	var w: int = img.get_width()
	var h: int = img.get_height()
	var data: PackedByteArray = img.get_data()
	var acc: int = 0
	# FNV-1a ueber alle Bytes (stabil, ohne Zufall)
	for b in data:
		acc = (acc ^ b) * 16777619
		acc = acc & 0xFFFFFFFF
	var s := "%dx%d:%08x" % [w, h, acc]
	return s

func _init() -> void:
	var tm = load("res://scripts/autoload/texture_manager.gd").new()
	tm._gen_boot()
	var boot_keys: Array = tm.textures.keys()
	boot_keys.sort()
	for k in boot_keys:
		print("[TEXHASH] boot %s %s" % [k, _hash_texture(tm.textures[k])])
	tm._gen_run()
	var run_keys: Array = tm.textures.keys()
	run_keys.sort()
	for k in run_keys:
		print("[TEXHASH] run %s %s" % [k, _hash_texture(tm.textures[k])])
	print("[TEXHASH] ende boot=%d gesamt=%d" % [boot_keys.size(), run_keys.size()])
	tm.free()
	quit(0)
