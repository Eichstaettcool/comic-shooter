# icon_gen.gd - Einmaliger Icon-Generator: Godot.exe --headless --path project --script res://scripts/icon_gen.gd
extends SceneTree

const OUTLINE := Color(0.08, 0.08, 0.1)

func _initialize() -> void:
	print("Erzeuge icon.png ...")
	var img := Image.create(512, 512, false, Image.FORMAT_RGBA8)

	# Hintergrund: goldenes Sonnenstrahlen-Muster
	img.fill(Color(0.98, 0.78, 0.2))
	for x in range(512):
		for y in range(512):
			var ang := rad_to_deg(atan2(y - 256.0, x - 256.0))
			if int((ang + 360.0) / 30.0) % 2 == 0:
				img.set_pixel(x, y, Color(0.95, 0.68, 0.12))

	# Comic-Rahmen
	_ring(img, 256, 256, 252, 16, OUTLINE)
	_ring(img, 256, 256, 232, 8, Color(0.15, 0.4, 0.8))

	# Monster-Blob (gruen) mit Schatten
	_ellipse(img, 256, 430, 150, 40, Color(0, 0, 0, 0.25))
	_ellipse(img, 256, 300, 195, 185, OUTLINE)
	_ellipse(img, 256, 300, 175, 165, Color(0.25, 0.8, 0.3))
	_ellipse(img, 256, 340, 105, 85, Color(0.45, 0.95, 0.5))

	# Horner
	_tri(img, Vector2(110, 190), Vector2(60, 60), Vector2(180, 150), OUTLINE)
	_tri(img, Vector2(118, 178), Vector2(80, 85), Vector2(172, 152), Color(0.95, 0.92, 0.8))
	_tri(img, Vector2(402, 190), Vector2(452, 60), Vector2(332, 150), OUTLINE)
	_tri(img, Vector2(394, 178), Vector2(432, 85), Vector2(340, 152), Color(0.95, 0.92, 0.8))

	# Augen
	_disc(img, 185, 250, 72, OUTLINE)
	_disc(img, 185, 250, 58, Color(1, 1, 1))
	_disc(img, 327, 250, 72, OUTLINE)
	_disc(img, 327, 250, 58, Color(1, 1, 1))
	_disc(img, 200, 265, 26, Color(0.05, 0.05, 0.08))
	_disc(img, 312, 265, 26, Color(0.05, 0.05, 0.08))

	# Augenbrauen
	_tri(img, Vector2(120, 170), Vector2(235, 205), Vector2(120, 215), OUTLINE)
	_tri(img, Vector2(392, 170), Vector2(277, 205), Vector2(392, 215), OUTLINE)

	# Mund mit Zaehnen
	_ellipse(img, 256, 385, 120, 62, OUTLINE)
	_ellipse(img, 256, 385, 105, 48, Color(0.4, 0.05, 0.1))
	_tri(img, Vector2(180, 348), Vector2(222, 348), Vector2(201, 400), Color(1, 1, 1))
	_tri(img, Vector2(235, 348), Vector2(277, 348), Vector2(256, 400), Color(1, 1, 1))
	_tri(img, Vector2(290, 348), Vector2(332, 348), Vector2(311, 400), Color(1, 1, 1))
	_tri(img, Vector2(215, 428), Vector2(257, 428), Vector2(236, 380), Color(1, 1, 1))
	_tri(img, Vector2(270, 428), Vector2(312, 428), Vector2(291, 380), Color(1, 1, 1))

	var err := img.save_png("res://icon.png")
	print("save_png err=", err)
	quit(0)

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)

func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for x in range(int(cx - r) - 1, int(cx + r) + 2):
		for y in range(int(cy - r) - 1, int(cy + r) + 2):
			if Vector2(float(x) - cx, float(y) - cy).length() <= r:
				_px(img, x, y, c)

func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
		for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
			var dx := (float(x) - cx) / rx
			var dy := (float(y) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, x, y, c)

func _ring(img: Image, cx: float, cy: float, r: float, thickness: float, c: Color) -> void:
	for x in range(int(cx - r) - 1, int(cx + r) + 2):
		for y in range(int(cy - r) - 1, int(cy + r) + 2):
			var d := Vector2(float(x) - cx, float(y) - cy).length()
			if d <= r and d > r - thickness:
				_px(img, x, y, c)

func _tri(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, c: Color) -> void:
	for x in range(int(minf(p0.x, minf(p1.x, p2.x))), int(maxf(p0.x, maxf(p1.x, p2.x))) + 1):
		for y in range(int(minf(p0.y, minf(p1.y, p2.y))), int(maxf(p0.y, maxf(p1.y, p2.y))) + 1):
			if _in_tri(Vector2(x, y), p0, p1, p2):
				_px(img, x, y, c)

func _in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 = c - a
	var v1 = b - a
	var v2 = p - a
	var dot00 = v0.dot(v0)
	var dot01 = v0.dot(v1)
	var dot02 = v0.dot(v2)
	var dot11 = v1.dot(v1)
	var dot12 = v1.dot(v2)
	var denom = dot00 * dot11 - dot01 * dot01
	if absf(denom) < 0.000001:
		return false
	var inv = 1.0 / denom
	var u = (dot11 * dot02 - dot01 * dot12) * inv
	var v = (dot00 * dot12 - dot01 * dot02) * inv
	return u >= 0 and v >= 0 and u + v < 1
