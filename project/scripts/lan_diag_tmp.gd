extends Node
var t := 0.0
var done := false
func start(_g: Node) -> void: set_process(true)
func _process(d: float) -> void:
	t += d
	if done or t < 1.0: return
	done = true
	var W := 1400
	var H := 760
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.10, 0.11, 0.14))
	for i in range(13):
		var tex = TextureManager.get_skin_hat_texture(0, 0, i)
		if tex == null: continue
		var im: Image = tex.get_image(); im.resize(92, 92, Image.INTERPOLATE_NEAREST)
		img.blend_rect(im, Rect2i(0, 0, 92, 92), Vector2i(10 + (i % 7) * 190, 10 + int(i / 7) * 180))
	for s in range(9):
		var tex2 = TextureManager.get_skin_hat_texture(0, s, 0)
		if tex2 == null: continue
		var im2: Image = tex2.get_image(); im2.resize(120, 120, Image.INTERPOLATE_NEAREST)
		img.blend_rect(im2, Rect2i(0, 0, 120, 120), Vector2i(10 + (s % 7) * 190, 390 + int(s / 7) * 180))
	# Farbe 3 (andere Farbe) fuer Skin 7 zeigen
	var tex3 = TextureManager.get_skin_hat_texture(3, 7, 0)
	if tex3 != null:
		var im3: Image = tex3.get_image(); im3.resize(120, 120, Image.INTERPOLATE_NEAREST)
		img.blend_rect(im3, Rect2i(0, 0, 120, 120), Vector2i(1250, 390))
		print("[TEST] Skin7 in Farbe 3 gezeichnet")
	img.save_png("C:/Users/vince/Games/comic-shooter/screenshots/141-kontakt2.png")
	print("[SHOT] 141")
	get_tree().quit()
