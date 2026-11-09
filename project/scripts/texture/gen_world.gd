class_name GenWorld
extends TexDraw


static func _make_tree() -> ImageTexture:
	var img = _new_img(64, 64)
	var leaf := Color(0.20, 0.70, 0.20)
	var leaf_dark := Color(0.12, 0.50, 0.14)
	var leaf_light := Color(0.45, 0.85, 0.40)
	var trunk := Color(0.50, 0.30, 0.15)
	# Schatten
	_ellipse(img, 32, 58, 18, 4, SHADOW, true)
	# Stamm
	_rect(img, 27, 40, 10, 16, OUTLINE)
	_rect(img, 28, 41, 8, 14, trunk)
	# Blätter-Busche mit Outline
	for blob in [[22, 30, 11], [42, 30, 11], [32, 22, 14]]:
		_disc(img, blob[0], blob[1], blob[2] + 2, OUTLINE)
	_disc(img, 22, 30, 11, leaf_dark)
	_disc(img, 42, 30, 11, leaf_dark)
	_disc(img, 32, 22, 14, leaf)
	# Lichtkante
	_disc(img, 28, 16, 6, leaf_light, true)
	_disc(img, 37, 20, 4, leaf_light, true)
	return ImageTexture.create_from_image(img)


static func _make_rock() -> ImageTexture:
	var img = _new_img(48, 48)
	var gray := Color(0.58, 0.58, 0.60)
	var gray_dark := Color(0.40, 0.40, 0.44)
	_ellipse(img, 24, 40, 18, 5, SHADOW, true)
	_ellipse(img, 24, 28, 17, 13, OUTLINE)
	_ellipse(img, 24, 28, 15, 11, gray)
	_ellipse(img, 19, 23, 6, 4, Color(0.75, 0.75, 0.78), true)
	# Riss
	_px(img, 26, 30, gray_dark)
	_px(img, 27, 32, gray_dark)
	_px(img, 28, 34, gray_dark)
	_px(img, 29, 35, gray_dark)
	return ImageTexture.create_from_image(img)


static func _make_rock_col(base: Color, darker: Color) -> ImageTexture:
	var img = _new_img(48, 48)
	_ellipse(img, 24, 40, 18, 5, SHADOW, true)
	_ellipse(img, 24, 28, 17, 13, OUTLINE)
	_ellipse(img, 24, 28, 15, 11, base)
	_ellipse(img, 19, 23, 6, 4, base.lightened(0.28), true)
	# Riss
	_px(img, 26, 30, darker)
	_px(img, 27, 32, darker)
	_px(img, 28, 34, darker)
	_px(img, 29, 35, darker)
	return ImageTexture.create_from_image(img)


static func _make_cactus() -> ImageTexture:
	var img = _new_img(64, 64)
	var body := Color(0.30, 0.64, 0.34)
	var body_dark := Color(0.20, 0.48, 0.26)
	_ellipse(img, 32, 58, 14, 4, SHADOW, true)
	# Hauptkörper
	_rect(img, 27, 18, 11, 40, OUTLINE)
	_rect(img, 29, 20, 7, 36, body)
	# linker Arm
	_rect(img, 13, 32, 16, 8, OUTLINE)
	_rect(img, 15, 33, 13, 6, body)
	_rect(img, 13, 22, 8, 14, OUTLINE)
	_rect(img, 15, 24, 4, 11, body)
	# rechter Arm
	_rect(img, 36, 38, 15, 8, OUTLINE)
	_rect(img, 37, 39, 13, 6, body)
	_rect(img, 43, 26, 8, 16, OUTLINE)
	_rect(img, 45, 28, 4, 13, body)
	# Stacheln
	for i in range(6):
		_px(img, 30, 26 + i * 5, body_dark)
		_px(img, 34, 28 + i * 5, body_dark)
	# Blüte oben
	_disc(img, 32, 15, 5, OUTLINE)
	_disc(img, 32, 15, 3, Color(1.0, 0.45, 0.60))
	return ImageTexture.create_from_image(img)


static func _make_pine() -> ImageTexture:
	var img = _new_img(64, 64)
	var snow := Color(0.94, 0.97, 1.0)
	var green := Color(0.16, 0.44, 0.36)
	var green_light := Color(0.30, 0.62, 0.50)
	var trunk := Color(0.36, 0.24, 0.16)
	_ellipse(img, 32, 58, 15, 4, SHADOW, true)
	_rect(img, 29, 46, 7, 12, OUTLINE)
	_rect(img, 30, 47, 5, 10, trunk)
	# Nadel-Ebenen (nach oben schmaler)
	var i := 0
	while i < 14:
		var w := 44 - i * 3
		var y := 46 - i * 3
		_rect(img, int(32 - w / 2) - 1, y, w + 2, 4, OUTLINE)
		_rect(img, int(32 - w / 2), y + 1, w, 2, green if i % 3 != 0 else green_light)
		i += 1
	# Schneehaube
	_rect(img, 28, 6, 8, 6, snow)
	_disc(img, 32, 6, 4, snow)
	return ImageTexture.create_from_image(img)


static func _make_dead_tree() -> ImageTexture:
	var img = _new_img(64, 64)
	var wood := Color(0.42, 0.32, 0.26)
	var wood_light := Color(0.56, 0.44, 0.36)
	_ellipse(img, 32, 58, 14, 4, SHADOW, true)
	_rect(img, 28, 26, 9, 32, OUTLINE)
	_rect(img, 29, 27, 6, 30, wood)
	# kahle Äste
	_rect(img, 18, 28, 12, 5, OUTLINE)
	_rect(img, 19, 29, 11, 3, wood_light)
	_rect(img, 36, 22, 13, 5, OUTLINE)
	_rect(img, 37, 23, 12, 3, wood_light)
	_rect(img, 22, 16, 5, 14, OUTLINE)
	_rect(img, 23, 17, 3, 12, wood_light)
	_rect(img, 39, 10, 5, 14, OUTLINE)
	_rect(img, 40, 11, 3, 12, wood_light)
	# Glut-Augen (Lava-Biom)
	_disc(img, 30, 34, 2, Color(1.0, 0.45, 0.15))
	_disc(img, 36, 34, 2, Color(1.0, 0.45, 0.15))
	return ImageTexture.create_from_image(img)


static func _make_boulder(body: Color, hl: Color, size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(c + c * 0.52), int(c * 0.86), int(c * 0.22), SHADOW, true)
	_outlined_disc(img, int(c - c * 0.26), int(c - c * 0.02), int(c * 0.44), body, 3)
	_outlined_disc(img, int(c + c * 0.30), int(c + c * 0.06), int(c * 0.38), body, 3)
	_outlined_disc(img, int(c + c * 0.04), int(c - c * 0.34), int(c * 0.34), body, 3)
	_disc(img, int(c - c * 0.24), int(c - c * 0.22), int(c * 0.20), hl)
	_disc(img, int(c + c * 0.32), int(c - c * 0.08), int(c * 0.15), hl)
	return ImageTexture.create_from_image(img)


static func _make_crater(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(c), int(c * 0.94), int(c * 0.80), Color(0.66, 0.32, 0.23), true)
	_ellipse(img, int(c), int(c), int(c * 0.76), int(c * 0.62), Color(0.46, 0.19, 0.15), true)
	_ellipse(img, int(c), int(c), int(c * 0.58), int(c * 0.47), Color(0.30, 0.12, 0.10), true)
	_ellipse(img, int(c), int(c - c * 0.52), int(c * 0.72), int(c * 0.10), Color(0.82, 0.48, 0.35, 0.75), true)
	return ImageTexture.create_from_image(img)


static func _make_jungle_tree(size: int) -> ImageTexture:
	# Bugfix: Krone lag vorher teilweise ausserhalb des Bildes (oben abgeschnitten)
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var trunk := Color(0.44, 0.31, 0.19)
	var leaf1 := Color(0.14, 0.44, 0.21)
	var leaf2 := Color(0.24, 0.62, 0.30)
	_ellipse(img, int(c), int(size - c * 0.18), int(c * 0.72), int(c * 0.13), SHADOW, true)
	_rect(img, int(c - c * 0.12), int(c * 0.46), int(c * 0.24), int(c * 0.60), OUTLINE)
	_rect(img, int(c - c * 0.08), int(c * 0.48), int(c * 0.16), int(c * 0.58), trunk)
	# drei Bueschel, alle mit Rand innerhalb der Leinwand
	_outlined_disc(img, int(c - c * 0.40), int(c * 0.58), int(c * 0.28), leaf1, 3)
	_outlined_disc(img, int(c + c * 0.42), int(c * 0.56), int(c * 0.26), leaf1, 3)
	_outlined_disc(img, int(c), int(c * 0.36), int(c * 0.30), leaf2, 3)
	_outlined_disc(img, int(c - c * 0.16), int(c * 0.70), int(c * 0.22), leaf2, 2)
	return ImageTexture.create_from_image(img)


static func _make_bamboo_alt(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var stalk := Color(0.72, 0.86, 0.36)
	var dark := Color(0.40, 0.58, 0.20)
	var leaf := Color(0.26, 0.68, 0.32)
	var c := float(size) / 2.0
	_ellipse(img, int(c), size - 6, int(c * 0.62), 5, SHADOW, true)
	for i in range(5):
		var x := int(c + (float(i) - 2.0) * c * 0.30)
		var h := int(c * (1.44 + 0.13 * float(i % 3)))
		_rect(img, x - 5, size - h - 3, 11, h, OUTLINE)
		_rect(img, x - 3, size - h - 1, 7, h - 4, stalk)
		for k in range(1, 5):
			_rect(img, x - 4, size - int(float(h) * float(k) / 5.0), 9, 2, dark)
		_tri(img, Vector2(x - 3, size - h - 3), Vector2(x - 18, size - h - 10), Vector2(x - 3, size - h + 4), leaf)
		_tri(img, Vector2(x + 4, size - h - 3), Vector2(x + 19, size - h - 12), Vector2(x + 4, size - h + 2), leaf)
	return ImageTexture.create_from_image(img)


static func _make_grass_tuft() -> ImageTexture:
	# Runde 25: GRUENES Grassbueschel (das weisse wurde im Spiel als weisse
	# Details/Schnee gelesen). Koerper gruen + dunkle Kontur.
	var img = _new_img(16, 22)
	var b1 := Color(0.28, 0.54, 0.22)
	var b2 := Color(0.40, 0.66, 0.29)
	var b3 := Color(0.24, 0.46, 0.19)
	for i in range(3):
		var x: int = 3 + i * 5
		var h: int = 13 + (i % 2) * 6
		_rect(img, x - 1, 22 - h, 4, h, OUTLINE)
		_rect(img, x, 22 - h + 1, 2, h - 2, b1 if i == 0 else (b2 if i == 1 else b3))
		_tri(img, Vector2(float(x - 1), float(22 - h)), Vector2(float(x + 2), float(22 - h - 5)), Vector2(float(x + 3), float(22 - h + 1)), b2)
	return ImageTexture.create_from_image(img)


static func _make_mushroom(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var stem := Color(0.94, 0.90, 0.80)
	var cap := Color(0.90, 0.28, 0.32)
	_rect(img, int(size * 0.44), int(size * 0.55), int(size * 0.12), int(size * 0.35), OUTLINE)
	_rect(img, int(size * 0.46), int(size * 0.57), int(size * 0.08), int(size * 0.32), stem)
	_ellipse(img, int(size / 2), int(size * 0.50), int(size * 0.30), int(size * 0.22), OUTLINE, true)
	_ellipse(img, int(size / 2), int(size * 0.48), int(size * 0.27), int(size * 0.19), cap, true)
	_disc(img, int(size * 0.40), int(size * 0.44), 3, Color(1, 1, 1, 0.85))
	_disc(img, int(size * 0.60), int(size * 0.50), 2, Color(1, 1, 1, 0.85))
	return ImageTexture.create_from_image(img)


static func _make_bush_dot() -> ImageTexture:
	# Runde 25: echter Busch (drei ueberlappende gruene Kugeln mit Kontur)
	var img = _new_img(64, 64)
	var c := float(32)
	_ellipse(img, 32, 58, 20, 5, SHADOW, true)
	_outlined_disc(img, int(c - c * 0.30), int(44.0), 15, Color(0.18, 0.44, 0.19), 3)
	_outlined_disc(img, int(c + c * 0.30), int(42.0), 15, Color(0.18, 0.44, 0.19), 3)
	_outlined_disc(img, 32, 32, 18, Color(0.22, 0.52, 0.23), 3)
	_disc(img, 28, 26, 8, Color(0.34, 0.64, 0.28))
	_disc(img, 40, 30, 6, Color(0.30, 0.60, 0.26))
	return ImageTexture.create_from_image(img)


static func _make_bush_prop(size: int, variant: int = 0) -> ImageTexture:
	# Runde 64: Busch im Stil der Baeume - schwarze Kontur, dunkle Unterseite,
	# Hauptfarbe, Lichtkante oben links. Die geladenen busch_*.png hatten
	# keine Kontur und wirkten wie Flammen.
	var img = _new_img(size, size)
	var f := float(size)
	var leaf := Color(0.20, 0.70, 0.20)
	var leaf_dark := Color(0.12, 0.50, 0.14)
	var leaf_light := Color(0.45, 0.85, 0.40)
	var blobs: Array
	match variant % 4:
		0:
			blobs = [[0.34, 0.60, 0.23], [0.52, 0.55, 0.26], [0.68, 0.61, 0.21]]
		1:
			blobs = [[0.36, 0.58, 0.24], [0.58, 0.60, 0.21], [0.47, 0.45, 0.19]]
		2:
			blobs = [[0.30, 0.62, 0.20], [0.48, 0.58, 0.25], [0.68, 0.65, 0.18], [0.50, 0.44, 0.17]]
		_:
			blobs = [[0.40, 0.56, 0.27], [0.62, 0.62, 0.19]]
	for b in blobs:
		_disc(img, float(b[0]) * f, float(b[1]) * f, float(b[2]) * f + 2.0, OUTLINE)
	for b in blobs:
		_disc(img, float(b[0]) * f, float(b[1]) * f + f * 0.035, float(b[2]) * f * 0.95, leaf_dark)
	for b in blobs:
		_disc(img, float(b[0]) * f, float(b[1]) * f, float(b[2]) * f * 0.86, leaf)
	for b in blobs:
		_disc(img, float(b[0]) * f - float(b[2]) * f * 0.22, float(b[1]) * f - float(b[2]) * f * 0.26,
			float(b[2]) * f * 0.32, leaf_light, true)
	return ImageTexture.create_from_image(img)


static func _make_bridge() -> ImageTexture:
	# Runde 23: klare Bruecke - Planken quer, seitliche Gelaender mit Pfosten,
	# Querbalken. Wird ueber die Kollisions-Insel gekachelt (texture_repeat).
	var img = _new_img(128, 96)
	var wood := Color(0.58, 0.40, 0.21)
	var wood_d := Color(0.45, 0.30, 0.15)
	var plank := Color(0.68, 0.49, 0.26)
	var dark := Color(0.34, 0.22, 0.11)
	# Planken (senkrecht, 8 Stueck)
	for i in range(8):
		var x: int = i * 16
		_rect(img, x, 12, 16, 72, OUTLINE)
		_rect(img, x + 1, 13, 14, 70, plank if i % 2 == 0 else wood_d)
	# seitliche Gelaender
	_rect(img, 0, 4, 128, 9, OUTLINE)
	_rect(img, 0, 6, 128, 5, wood)
	_rect(img, 0, 83, 128, 9, OUTLINE)
	_rect(img, 0, 85, 128, 5, wood)
	# Querbalken unter den Planken (Bruecken-Look)
	_rect(img, 0, 42, 128, 7, dark)
	# Pfosten
	for x in [4, 58, 114]:
		_rect(img, x, 0, 9, 96, OUTLINE)
		_rect(img, x + 1, 2, 7, 92, wood)
	return ImageTexture.create_from_image(img)


static func _make_palm() -> ImageTexture:
	var img = _new_img(64, 64)
	var trunk := Color(0.50, 0.36, 0.20)
	var leaf := Color(0.20, 0.62, 0.26)
	_ellipse(img, 32, 56, 16, 5, SHADOW, true)
	_rect(img, 28, 22, 8, 34, OUTLINE)
	_rect(img, 30, 24, 4, 32, trunk)
	for i in range(5):
		var a := -PI * 0.9 + PI * 0.8 * (float(i) / 4.0)
		var c := Vector2(32, 22) + Vector2(cos(a) * 15.0, sin(a) * 12.0)
		_ellipse(img, int(c.x), int(c.y), 9, 5, leaf)
	_outlined_disc(img, 30, 22, 4, Color(0.85, 0.65, 0.20), 1)
	return ImageTexture.create_from_image(img)


static func _make_big_flower() -> ImageTexture:
	var img = _new_img(64, 64)
	var petal := Color(0.95, 0.36, 0.66)
	var core := Color(1.0, 0.86, 0.26)
	var stem := Color(0.20, 0.50, 0.22)
	_ellipse(img, 32, 57, 14, 4, SHADOW, true)
	_rect(img, 30, 34, 5, 22, OUTLINE)
	_rect(img, 31, 36, 3, 20, stem)
	for i in range(6):
		var a := TAU * float(i) / 6.0
		var c := Vector2(32, 26) + Vector2(cos(a), sin(a)) * 13.0
		_outlined_disc(img, int(c.x), int(c.y), 8, petal, 2)
	_outlined_disc(img, 32, 26, 10, core, 3)
	_outlined_disc(img, 32, 26, 5, Color(0.55, 0.18, 0.35), 2)
	return ImageTexture.create_from_image(img)


static func _make_banana() -> ImageTexture:
	var img = _new_img(32, 32)
	var peel := Color(0.98, 0.86, 0.26)
	var dark := Color(0.72, 0.56, 0.10)
	for i in range(9):
		var t := float(i) / 8.0
		var a := PI * 0.18 + PI * 0.66 * t
		var c := Vector2(16, 19) + Vector2(cos(a) * 11.0, -sin(a) * 9.0)
		_disc(img, int(c.x), int(c.y), 4, peel)
		_px(img, int(c.x), int(c.y) - 3, dark)
	return ImageTexture.create_from_image(img)


static func _jleaf_shape(img: Image, center: Vector2, angle: float, length: float, width: float, col: Color) -> void:
	# Runde 58: Einzelnes Blatt - zwei Haelften (hell/dunkel) + Mittelrippe
	# + Stiel. Vorher waren es Rauten ohne Rippe, die wie Splitter wirkten.
	var d: Vector2 = Vector2.RIGHT.rotated(angle) * length * 0.5
	var n: Vector2 = Vector2(-d.y, d.x) * width * 0.5
	var tip1: Vector2 = center - d
	var tip2: Vector2 = center + d
	_tri(img, tip1, tip2, center + n, col.lightened(0.10))
	_tri(img, tip1, tip2, center - n, col.darkened(0.14))
	_thick_line(img, tip1, tip2, 1.1, col.darkened(0.38))
	_thick_line(img, tip2, tip2 + d.normalized() * (length * 0.22), 1.4, col.darkened(0.30))


static func _make_jleafpile(size: int) -> ImageTexture:
	# Runde 58b: Runde, gedämpfte Blatthaufen. Die Dreiecks-Blätter lasen im
	# Spiel wie orange Explosionen. Jetzt flache Blattkissen aus ueberlappenden
	# Scheiben mit dunkler Kante und kleinem Glanzpunkt.
	var img = _new_img(size, size)
	var f := float(size)
	var cols := [Color(0.52, 0.36, 0.19), Color(0.62, 0.46, 0.22), Color(0.44, 0.44, 0.20), Color(0.68, 0.52, 0.26)]
	_ellipse(img, int(f * 0.50), int(f * 0.70), int(f * 0.40), int(f * 0.14), Color(0.14, 0.18, 0.10, 0.40), true)
	var spots := [
		Vector2(0.32, 0.62), Vector2(0.50, 0.58), Vector2(0.68, 0.63),
		Vector2(0.40, 0.69), Vector2(0.60, 0.70), Vector2(0.50, 0.66),
		Vector2(0.24, 0.66), Vector2(0.76, 0.67), Vector2(0.46, 0.72),
	]
	for i in range(spots.size()):
		var p: Vector2 = spots[i] * f
		var r: float = f * (0.115 - 0.008 * float(i % 3))
		var c: Color = cols[i % cols.size()]
		_disc(img, p.x, p.y + r * 0.22, r, Color(0.18, 0.16, 0.09, 0.55))   # Schattenkante
		_disc(img, p.x, p.y, r * 0.94, c)                                   # Blatt
		_disc(img, p.x - r * 0.26, p.y - r * 0.28, r * 0.34, c.lightened(0.16))  # Glanz
	print("[JUNGLE][TEX] jleafpile neu gezeichnet (%dpx, 9 runde Blaetter)" % size)
	return ImageTexture.create_from_image(img)


static func _leaf_cluster(img, cx: float, cy: float, r: float) -> void:
	# Busch in 3 Toenen: dunkle Kontur, Mittelton, Highlight oben-links
	_outlined_disc(img, int(cx), int(cy), int(r), JT_LEAF_D, 3)
	_disc(img, int(cx), int(cy), int(r * 0.88), JT_LEAF)
	_disc(img, int(cx - r * 0.26), int(cy - r * 0.30), int(r * 0.44), JT_LEAF_L)


static func _trunk(img, cx: float, top: float, bot: float, w: float) -> void:
	_rect(img, int(cx - w / 2.0 - 2.0), int(top), int(w + 4.0), int(bot - top), OUTLINE)
	_rect(img, int(cx - w / 2.0), int(top), int(w), int(bot - top), JT_TRUNK)
	_rect(img, int(cx - w / 2.0), int(top), int(w * 0.34), int(bot - top), JT_TRUNK_D)


static func _leaf(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	# Runde 56: Blatt mit dunkler Kontur (Comic-Look) - erst Rand, dann
	# die Fuellung leicht zum Zentrum hin verkleinert.
	var g: Vector2 = (a + b + c) / 3.0
	_tri(img, a, b, c, OUTLINE)
	_tri(img, g.lerp(a, 0.78), g.lerp(b, 0.78), g.lerp(c, 0.78), col)


static func _make_jmushroom(size: int, cap: Color) -> ImageTexture:
	# Runde 56: breiterer Hut, dickere Stielkante, Lamellenband - vorher
	# wirkte der Pilz wie ein kleiner brauner Klecks.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.05), int(c * 0.56), int(c * 0.10), SHADOW, true)
	_rect(img, int(c - c * 0.16 - 2), int(c * 0.82), int(c * 0.32 + 4), int(c * 0.66), OUTLINE)
	_rect(img, int(c - c * 0.16), int(c * 0.84), int(c * 0.32), int(c * 0.62), Color(0.94, 0.90, 0.82))
	_rect(img, int(c - c * 0.16), int(c * 0.84), int(c * 0.10), int(c * 0.62), Color(0.80, 0.75, 0.66))
	_ellipse(img, int(c), int(c * 0.88), int(c * 0.74), int(c * 0.50), OUTLINE, true)
	_ellipse(img, int(c), int(c * 0.84), int(c * 0.68), int(c * 0.44), cap, true)
	_ellipse(img, int(c), int(c * 1.16), int(c * 0.60), int(c * 0.10), Color(0.86, 0.80, 0.68))
	_disc(img, int(c - c * 0.30), int(c * 0.56), int(c * 0.14), Color(1, 1, 1, 0.35))
	_disc(img, int(c - c * 0.24), int(c * 0.72), int(c * 0.10), Color(1, 1, 1, 0.9))
	_disc(img, int(c + c * 0.22), int(c * 0.80), int(c * 0.08), Color(1, 1, 1, 0.85))
	_disc(img, int(c + c * 0.02), int(c * 0.62), int(c * 0.07), Color(1, 1, 1, 0.7))
	print("[JUNGLE][TEX] jmushroom neu gezeichnet (%dpx)" % size)
	return ImageTexture.create_from_image(img)


static func _make_jcrystal(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var gem := Color(0.40, 0.80, 0.98)
	var gem_d := Color(0.22, 0.55, 0.85)
	_ellipse(img, int(c), int(size - c * 0.05), int(c * 0.62), int(c * 0.12), SHADOW, true)
	# drei Kristalle
	_tri(img, Vector2(c - c * 0.42, size - c * 0.12), Vector2(c - c * 0.28, c * 0.42), Vector2(c - c * 0.12, size - c * 0.12), OUTLINE)
	_tri(img, Vector2(c - c * 0.38, size - c * 0.16), Vector2(c - c * 0.28, c * 0.48), Vector2(c - c * 0.17, size - c * 0.16), gem_d)
	_tri(img, Vector2(c - c * 0.10, size - c * 0.10), Vector2(c + c * 0.06, c * 0.16), Vector2(c + c * 0.24, size - c * 0.10), OUTLINE)
	_tri(img, Vector2(c - c * 0.05, size - c * 0.15), Vector2(c + c * 0.06, c * 0.24), Vector2(c + c * 0.19, size - c * 0.15), gem)
	_tri(img, Vector2(c + c * 0.28, size - c * 0.14), Vector2(c + c * 0.42, c * 0.52), Vector2(c + c * 0.56, size - c * 0.14), OUTLINE)
	_tri(img, Vector2(c + c * 0.32, size - c * 0.18), Vector2(c + c * 0.42, c * 0.58), Vector2(c + c * 0.52, size - c * 0.18), gem_d)
	return ImageTexture.create_from_image(img)


static func _make_jrock(size: int) -> ImageTexture:
	# Runde 56: facettierter Fels statt glatter grauer Kiesel
	var img = _new_img(size, size)
	var f := float(size)
	var base := Color(0.48, 0.52, 0.50)
	var light := Color(0.64, 0.68, 0.63)
	var dark := Color(0.33, 0.37, 0.37)
	_ellipse(img, int(f * 0.50), int(f * 0.86), int(f * 0.44), int(f * 0.11), SHADOW, true)
	_outlined_ellipse(img, int(f * 0.50), int(f * 0.62), int(f * 0.38), int(f * 0.28), base, 3)
	_tri(img, Vector2(f * 0.54, f * 0.36), Vector2(f * 0.80, f * 0.60), Vector2(f * 0.46, f * 0.58), light)
	_tri(img, Vector2(f * 0.54, f * 0.36), Vector2(f * 0.46, f * 0.58), Vector2(f * 0.30, f * 0.44), Color(0.55, 0.59, 0.56))
	_tri(img, Vector2(f * 0.26, f * 0.66), Vector2(f * 0.44, f * 0.82), Vector2(f * 0.30, f * 0.82), dark)
	_disc(img, int(f * 0.64), int(f * 0.78), int(f * 0.11), Color(0.30, 0.50, 0.27))
	_disc(img, int(f * 0.72), int(f * 0.73), int(f * 0.06), Color(0.36, 0.58, 0.30))
	print("[JUNGLE][TEX] jrock neu gezeichnet (%dpx, facettiert)" % size)
	return ImageTexture.create_from_image(img)


static func _make_volt_pylon() -> ImageTexture:
	# Teslaspule: Sockel + Wickelringe + leuchtende Kugel
	var img = _new_img(96, 128)
	var steel := Color(0.42, 0.46, 0.56)
	var steel_d := Color(0.22, 0.25, 0.34)
	var glow := Color(1.0, 0.88, 0.30)
	_ellipse(img, 48, 120, 34, 10, SHADOW, true)
	_outlined_ellipse(img, 48, 108, 30, 18, steel_d, 4)
	_rect(img, 40, 44, 16, 70, OUTLINE)
	_rect(img, 42, 46, 12, 66, steel)
	for i in range(4):
		_outlined_ellipse(img, 48, 96 - i * 16, 20 - i * 2, 7, steel_d, 3)
	_outlined_disc(img, 48, 30, 15, glow, 4)
	_disc(img, 48, 30, 7, Color(1, 1, 0.85))
	_tri(img, Vector2(44.0, 40.0), Vector2(52.0, 20.0), Vector2(56.0, 42.0), Color(1.0, 0.92, 0.5, 0.7))
	return ImageTexture.create_from_image(img)


static func _make_volt_capacitor() -> ImageTexture:
	# Energieblock mit Blitz-Symbol
	var img = _new_img(80, 80)
	var steel := Color(0.46, 0.52, 0.64)
	var steel_d := Color(0.24, 0.28, 0.38)
	var glow := Color(1.0, 0.85, 0.25)
	_ellipse(img, 40, 72, 26, 8, SHADOW, true)
	_outlined_ellipse(img, 40, 40, 26, 30, steel, 4)
	_outlined_ellipse(img, 40, 40, 16, 18, steel_d, 3)
	_tri(img, Vector2(44.0, 20.0), Vector2(26.0, 44.0), Vector2(40.0, 44.0), glow)
	_tri(img, Vector2(40.0, 44.0), Vector2(58.0, 44.0), Vector2(44.0, 64.0), glow)
	_tri(img, Vector2(42.0, 26.0), Vector2(33.0, 42.0), Vector2(40.0, 42.0), Color(1, 1, 0.8))
	_tri(img, Vector2(42.0, 46.0), Vector2(51.0, 46.0), Vector2(43.0, 58.0), Color(1, 1, 0.8))
	return ImageTexture.create_from_image(img)


static func _make_volt_spool() -> ImageTexture:
	# Kabeltrommel
	var img = _new_img(88, 88)
	var steel := Color(0.38, 0.42, 0.52)
	var steel_d := Color(0.20, 0.23, 0.30)
	var wire := Color(0.95, 0.78, 0.20)
	_ellipse(img, 44, 78, 32, 9, SHADOW, true)
	_outlined_disc(img, 44, 44, 34, steel_d, 4)
	_outlined_disc(img, 44, 44, 22, wire, 4)
	_outlined_disc(img, 44, 44, 10, steel, 3)
	for i in range(6):
		var a: float = float(i) * TAU / 6.0
		_rect(img, 44 + int(cos(a) * 18.0) - 2, 44 + int(sin(a) * 18.0) - 2, 5, 5, steel_d)
	return ImageTexture.create_from_image(img)


static func _make_volt_wreck() -> ImageTexture:
	# Schrottroboter
	var img = _new_img(96, 96)
	var steel := Color(0.44, 0.48, 0.58)
	var steel_d := Color(0.22, 0.25, 0.33)
	var dead := Color(0.55, 0.20, 0.20)
	_ellipse(img, 48, 88, 32, 9, SHADOW, true)
	_outlined_ellipse(img, 46, 62, 30, 20, steel_d, 4)
	_outlined_disc(img, 68, 38, 16, steel, 4)
	_disc(img, 62, 36, 5, dead)
	_rect(img, 18, 48, 8, 34, steel_d)
	_rect(img, 74, 62, 8, 22, steel_d)
	_tri(img, Vector2(30.0, 34.0), Vector2(38.0, 12.0), Vector2(40.0, 36.0), Color(1.0, 0.85, 0.3, 0.8))
	_disc(img, 26, 24, 4, Color(1.0, 0.9, 0.4))
	return ImageTexture.create_from_image(img)


static func _make_volt_antenna() -> ImageTexture:
	# Antennenmast mit Parabolschuessel
	var img = _new_img(96, 128)
	var steel := Color(0.40, 0.44, 0.54)
	var steel_d := Color(0.20, 0.23, 0.31)
	var warn := Color(1.0, 0.35, 0.30)
	_ellipse(img, 48, 120, 28, 9, SHADOW, true)
	_rect(img, 44, 40, 8, 80, OUTLINE)
	_rect(img, 46, 42, 4, 76, steel)
	for i in range(3):
		_rect(img, 34, 96 - i * 20, 28, 4, steel_d)
	_outlined_ellipse(img, 48, 30, 28, 12, steel, 4)
	_outlined_ellipse(img, 48, 26, 20, 8, steel_d, 3)
	_disc(img, 48, 18, 6, warn)
	return ImageTexture.create_from_image(img)


static func _make_bamboo_pixel() -> ImageTexture:
	# Runde 56: Bambus mit echter Kontur. Vorher 2 px breite Striche ohne
	# Rand - auf dem Boden kaum als Pflanze lesbar.
	var W := 44
	var H := 80
	var img = _new_img(W, H)
	var s_l := Color(0.62, 0.82, 0.40)
	var s_m := Color(0.46, 0.68, 0.29)
	var s_d := Color(0.30, 0.48, 0.20)
	var leaf := Color(0.30, 0.58, 0.24)
	var leaf_l := Color(0.50, 0.76, 0.34)
	var xs := [8, 17, 26, 35]
	for i in range(xs.size()):
		var x: int = xs[i]
		var h: int = H - 16 - (i % 3) * 8
		var top: int = H - h
		# Halm: 7 px Kontur, 4 px Fuellung, Lichtkante
		_rect(img, x - 3, top, 7, h, OUTLINE)
		_rect(img, x - 2, top + 1, 4, h - 1, s_m if i % 2 == 0 else s_l)
		_rect(img, x - 2, top + 1, 1, h - 1, s_l)
		var k: int = top + 6
		while k < H - 4:
			# Runde 57: Knoten nur als dunkelgruener Ring, NICHT als voller
			# schwarzer Balken - der liess die Halme wie Leitern aussehen.
			_rect(img, x - 2, k, 5, 2, s_d)
			_rect(img, x - 2, k + 2, 5, 1, s_l)
			k += 9
		# Blattbueschel
		var lb := Vector2(float(x) + 0.5, float(top + 2))
		_leaf(img, lb, lb + Vector2(-13, -9), lb + Vector2(-5, 4), leaf)
		_leaf(img, lb, lb + Vector2(13, -11), lb + Vector2(5, 3), leaf_l)
		_leaf(img, lb, lb + Vector2(1, -15), lb + Vector2(3, 1), leaf)
	print("[JUNGLE][TEX] bamboo neu gezeichnet (%dx%d, 4 Halme)" % [W, H])
	return ImageTexture.create_from_image(img)


static func _frond(img: Image, base: Vector2, ang: float, length: float, droop: float,
		col: Color, col2: Color, leaf_len: float = 12.0) -> void:
	# Runde 56: Palmwedel - geschwungene Spindel mit Fiederblaettern
	var steps: int = 11
	var dir: Vector2 = Vector2.RIGHT.rotated(ang)
	# 1) dunkle Kontur der Spindel
	var prev: Vector2 = base
	for i in range(1, steps + 1):
		var f: float = float(i) / float(steps)
		var p: Vector2 = base + dir * length * f + Vector2(0, droop * f * f)
		_thick_line(img, prev, p, 3.0 - 1.6 * f, OUTLINE)
		prev = p
	# 2) Farbe + Fiederblaetter
	prev = base
	for i in range(1, steps + 1):
		var f: float = float(i) / float(steps)
		var p: Vector2 = base + dir * length * f + Vector2(0, droop * f * f)
		_thick_line(img, prev, p, 2.2 - 1.2 * f, col2)
		var t: Vector2 = (p - prev).normalized()
		var n: Vector2 = Vector2(-t.y, t.x)
		var ll: float = leaf_len * (1.0 - 0.55 * f)
		var c1: Color = col if i % 2 == 0 else col2
		_leaf(img, p, p + n * ll - t * 2.0, p + n * ll * 0.22, c1)
		_leaf(img, p, p - n * ll - t * 2.0, p - n * ll * 0.22, c1)
		prev = p


static func _make_jtree_round(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.08), int(c * 0.60), int(c * 0.13), SHADOW, true)
	_trunk(img, c, c * 0.66, size - c * 0.06, c * 0.20)
	# Wurzelansatz
	_tri(img, Vector2(c - c * 0.10, size - c * 0.16), Vector2(c - c * 0.30, size - c * 0.02), Vector2(c - c * 0.02, size - c * 0.20), JT_TRUNK_D)
	_leaf_cluster(img, c, c * 0.50, c * 0.36)
	_leaf_cluster(img, c - c * 0.40, c * 0.68, c * 0.26)
	_leaf_cluster(img, c + c * 0.42, c * 0.66, c * 0.25)
	_leaf_cluster(img, c - c * 0.12, c * 0.34, c * 0.20)
	_leaf_cluster(img, c + c * 0.20, c * 0.38, c * 0.19)
	return ImageTexture.create_from_image(img)


static func _make_jtree_tall(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.06), int(c * 0.52), int(c * 0.11), SHADOW, true)
	_trunk(img, c, c * 0.34, size - c * 0.05, c * 0.16)
	# leichte Kruemmung
	_ellipse(img, int(c + c * 0.04), int(c * 0.70), int(c * 0.10), int(c * 0.20), JT_TRUNK, true)
	_leaf_cluster(img, c, c * 0.32, c * 0.25)
	_leaf_cluster(img, c - c * 0.30, c * 0.38, c * 0.22)
	_leaf_cluster(img, c + c * 0.32, c * 0.36, c * 0.22)
	return ImageTexture.create_from_image(img)


static func _make_jtree_willow(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.06), int(c * 0.58), int(c * 0.12), SHADOW, true)
	_trunk(img, c, c * 0.40, size - c * 0.05, c * 0.18)
	_leaf_cluster(img, c, c * 0.36, c * 0.30)
	# haengende Straenge
	var strand := Color(0.24, 0.56, 0.28)
	var strand_d := Color(0.13, 0.36, 0.18)
	for i in range(9):
		var px0 := c - c * 0.62 + float(i) * (c * 1.24 / 8.0)
		var hh := c * (0.42 + 0.22 * float((i * 7) % 5) / 4.0)
		_rect(img, int(px0), int(c * 0.30), 5, int(hh), OUTLINE)
		_rect(img, int(px0) + 1, int(c * 0.32), 3, int(hh - 4), strand if i % 2 == 0 else strand_d)
	return ImageTexture.create_from_image(img)


static func _make_jtree_ancient(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.06), int(c * 0.62), int(c * 0.14), SHADOW, true)
	# krummer, dicker Stamm mit Gesicht in den Wurzeln
	_trunk(img, c - c * 0.04, c * 0.36, size - c * 0.05, c * 0.34)
	_tri(img, Vector2(c - c * 0.20, size - c * 0.18), Vector2(c - c * 0.44, size - c * 0.02), Vector2(c - c * 0.04, size - c * 0.24), JT_TRUNK_D)
	_tri(img, Vector2(c + c * 0.18, size - c * 0.18), Vector2(c + c * 0.42, size - c * 0.02), Vector2(c + c * 0.04, size - c * 0.24), JT_TRUNK_D)
	_disc(img, int(c - c * 0.10), int(size - c * 0.30), int(c * 0.05), Color(0.08, 0.08, 0.10))   # Augen
	_disc(img, int(c + c * 0.06), int(size - c * 0.30), int(c * 0.05), Color(0.08, 0.08, 0.10))
	_leaf_cluster(img, c, c * 0.40, c * 0.34)
	_leaf_cluster(img, c - c * 0.44, c * 0.54, c * 0.26)
	_leaf_cluster(img, c + c * 0.46, c * 0.50, c * 0.26)
	# blauer Kristall am Stamm
	_tri(img, Vector2(c + c * 0.22, c * 0.86), Vector2(c + c * 0.30, c * 0.48), Vector2(c + c * 0.38, c * 0.86), OUTLINE)
	_tri(img, Vector2(c + c * 0.24, c * 0.84), Vector2(c + c * 0.30, c * 0.52), Vector2(c + c * 0.36, c * 0.84), Color(0.42, 0.82, 0.98))
	return ImageTexture.create_from_image(img)


static func _make_jbush_leaf(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.04), int(c * 0.62), int(c * 0.10), SHADOW, true)
	_leaf_cluster(img, c, c * 0.72, c * 0.44)
	_leaf_cluster(img, c - c * 0.36, c * 0.94, c * 0.28)
	_leaf_cluster(img, c + c * 0.38, c * 0.90, c * 0.28)
	# grosse Blaetter
	var lf := Color(0.24, 0.58, 0.26)
	for i in range(5):
		var bx := c - c * 0.50 + float(i) * c * 0.26
		_tri(img, Vector2(bx, c * 1.34), Vector2(bx + c * 0.13, c * 0.52), Vector2(bx + c * 0.26, c * 1.34), lf)
	return ImageTexture.create_from_image(img)


static func _make_jvine(size: int) -> ImageTexture:
	# Runde 56: Lianen mit Kontur und Blattpaaren entlang des Halms -
	# vorher waren es 2-px-Faeden mit lose schwebenden Dreiecken.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var v := Color(0.22, 0.54, 0.26)
	var vl := Color(0.36, 0.70, 0.32)
	for i in range(5):
		var px0: float = c - c * 0.44 + float(i) * c * 0.22
		var hh: float = c * (0.86 + 0.28 * float((i * 3) % 4) / 3.0)
		var sway: float = 3.5 if i % 2 == 0 else -3.5
		var steps: int = 7
		var prev := Vector2(px0, 0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(px0 + sway * f, hh * f)
			_thick_line(img, prev, p, 2.2, OUTLINE)
			prev = p
		prev = Vector2(px0, 0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(px0 + sway * f, hh * f)
			_thick_line(img, prev, p, 1.2, v if i % 2 == 0 else vl)
			prev = p
		for k in range(4):
			var f2: float = 0.18 + 0.20 * float(k)
			var bp := Vector2(px0 + sway * f2, hh * f2)
			var ll: float = c * (0.26 - 0.03 * float(k))
			_leaf(img, bp, bp + Vector2(-ll, -ll * 0.42), bp + Vector2(-ll * 0.18, ll * 0.30), v)
			_leaf(img, bp, bp + Vector2(ll, -ll * 0.30), bp + Vector2(ll * 0.18, ll * 0.42), vl)
	print("[JUNGLE][TEX] jvine neu gezeichnet (%dpx, 5 Ranken)" % size)
	return ImageTexture.create_from_image(img)


static func _make_jflower(size: int, petal := Color(0.98, 0.96, 0.92), petal_d := Color(0.86, 0.84, 0.80),
		center := Color(0.98, 0.72, 0.24)) -> ImageTexture:
	# Runde 56: Blume mit Kontur, Stiel und Blatt - vorher nur fünf weisse
	# Kreise ohne Rand, bei Spielgroesse nicht als Bluete lesbar.
	# Runde 58: Farbvarianten (weiss/pink/gelb) fuer Farbakzente in der Karte.
	var img = _new_img(size, size)
	var f := float(size)
	var stem := Color(0.26, 0.56, 0.26)
	var cx: float = f * 0.50
	var cy: float = f * 0.40
	_rect(img, int(cx) - 2, int(cy), 5, int(f * 0.52), OUTLINE)
	_rect(img, int(cx) - 1, int(cy), 3, int(f * 0.50), stem)
	_leaf(img, Vector2(cx + 1.0, cy + f * 0.30), Vector2(cx + f * 0.26, cy + f * 0.14), Vector2(cx + f * 0.04, cy + f * 0.36), stem)
	for i in range(5):
		var a: float = TAU * float(i) / 5.0 - PI * 0.5
		var px: float = cx + cos(a) * f * 0.20
		var py: float = cy + sin(a) * f * 0.20
		_disc(img, px, py, f * 0.16, OUTLINE)
		_disc(img, px, py, f * 0.135, petal if i % 2 == 0 else petal_d)
	_disc(img, cx, cy, f * 0.105, OUTLINE)
	_disc(img, cx, cy, f * 0.085, center)
	print("[JUNGLE][TEX] jflower neu gezeichnet (%dpx, %s)" % [size, str(petal)])
	return ImageTexture.create_from_image(img)


static func _make_jreed(size: int) -> ImageTexture:
	# Runde 56: Schilf mit geschwungenen Halmen und Fahne - vorher waren es
	# fuenf gerade Striche ohne Kontur, die wie ein Strichcode wirkten.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var st := Color(0.36, 0.60, 0.26)
	var st_l := Color(0.55, 0.76, 0.34)
	_ellipse(img, int(c), int(size - 5), int(c * 0.46), int(c * 0.08), SHADOW, true)
	for i in range(6):
		var bx: float = c - c * 0.34 + float(i) * c * 0.14
		var hh: float = c * (1.10 + 0.35 * float((i * 3) % 4) / 3.0)
		var topy: float = float(size) - hh - 4.0
		var sway: float = 7.0 if i % 2 == 0 else -7.0
		var steps: int = 8
		var prev := Vector2(bx, float(size) - 5.0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(bx + sway * f * f, float(size) - 5.0 - hh * f)
			_thick_line(img, prev, p, 2.6, OUTLINE)
			prev = p
		prev = Vector2(bx, float(size) - 5.0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(bx + sway * f * f, float(size) - 5.0 - hh * f)
			_thick_line(img, prev, p, 1.6, st if i % 2 == 0 else st_l)
			prev = p
		var tip := Vector2(bx + sway, topy)
		_leaf(img, tip, tip + Vector2(-7, -10), tip + Vector2(-2, 2), st)
		_leaf(img, tip, tip + Vector2(7, -12), tip + Vector2(2, 1), st_l)
		_leaf(img, tip, tip + Vector2(0, -14), tip + Vector2(2, 0), st)
	print("[JUNGLE][TEX] jreed neu gezeichnet (%dpx, 6 Halme)" % size)
	return ImageTexture.create_from_image(img)


static func _make_fern(size: int) -> ImageTexture:
	# Runde 56: Echter Farn. Vorher ein Stern aus sieben graden Dreiecken
	# ("Grasbueschel"). Jetzt sechs geschwungene Wedel mit Fiederblaettern.
	var img = _new_img(size, size)
	var leaf := Color(0.19, 0.52, 0.24)
	var leaf2 := Color(0.31, 0.70, 0.32)
	var s: float = float(size)
	_ellipse(img, int(s * 0.50), int(s * 0.88), int(s * 0.26), int(s * 0.06), SHADOW, true)
	var base := Vector2(s * 0.50, s * 0.86)
	for i in range(6):
		var ang: float = deg_to_rad(-152.0 + 24.0 * float(i))
		var ln: float = s * (0.52 + 0.06 * float(i % 3))
		_frond(img, base, ang, ln, s * 0.10, leaf if i % 2 == 0 else leaf2, leaf2, s * 0.10)
	_disc(img, base.x, base.y - 2.0, s * 0.07, Color(0.16, 0.38, 0.20))
	print("[JUNGLE][TEX] fern neu gezeichnet (%dpx, 6 Wedel)" % size)
	return ImageTexture.create_from_image(img)


static func _make_jpalm(size: int) -> ImageTexture:
	# Runde 56: ECHTE Palme. Vorher war das ein brauner Pfahl mit einem
	# Stern oben ("Besen"). Jetzt geschwungener Stamm mit Ringen und
	# acht gefiederte Wedel.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var trunk := Color(0.46, 0.30, 0.18)
	var trunk_l := Color(0.60, 0.41, 0.25)
	var trunk_d := Color(0.31, 0.19, 0.11)
	var frond := Color(0.17, 0.46, 0.21)
	var frond_l := Color(0.30, 0.64, 0.27)
	_ellipse(img, int(c), int(size - 10), int(c * 0.42), int(c * 0.09), SHADOW, true)

	var p0 := Vector2(c + 6.0, size - 16.0)
	var p1 := Vector2(c - 4.0, c + 18.0)
	var p2 := Vector2(c - 26.0, c * 0.44)
	# Stamm: Kontur, Fuellung, Ringe, Lichtkante
	for i in range(24):
		var f: float = float(i) / 23.0
		var p: Vector2 = _quad(p0, p1, p2, f)
		var r: float = 11.5 - 4.5 * f
		_disc(img, p.x, p.y, r + 2.0, OUTLINE)
	for i in range(24):
		var f: float = float(i) / 23.0
		var p: Vector2 = _quad(p0, p1, p2, f)
		var r: float = 11.0 - 4.5 * f
		_disc(img, p.x, p.y, r, trunk)
		_disc(img, p.x - r * 0.45, p.y, r * 0.42, trunk_l)
	for i in range(8):
		var f: float = float(i) / 8.0
		var p: Vector2 = _quad(p0, p1, p2, f)
		_disc(img, p.x, p.y + 1.0, 6.0 - 3.0 * f, trunk_d)

	var crown: Vector2 = p2
	for i in range(8):
		var ang: float = deg_to_rad(-168.0 + 21.0 * float(i))
		var ln: float = 62.0 + 10.0 * float(i % 3)
		_frond(img, crown, ang, ln, 20.0 + 10.0 * float(i % 2), frond, frond_l)
	# Kokosnuesse
	_disc(img, crown.x - 2.0, crown.y + 4.0, 7.0, OUTLINE)
	_disc(img, crown.x - 2.0, crown.y + 4.0, 5.0, Color(0.52, 0.36, 0.18))
	_disc(img, crown.x + 9.0, crown.y + 7.0, 6.0, OUTLINE)
	_disc(img, crown.x + 9.0, crown.y + 7.0, 4.0, Color(0.45, 0.30, 0.15))
	return ImageTexture.create_from_image(img)



# ============================================================
# v1.42 (P7.4): Steine mit echter Textur - funf Silhouetten,
# dunkler Umriss, 4-5 Grautoene, Moos an der Unterseite.
# ============================================================

static func _make_stone_variant(idx: int, size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var f := float(size)
	var bases: Array = [
		Color(0.52, 0.54, 0.55), Color(0.47, 0.49, 0.52), Color(0.58, 0.57, 0.54),
		Color(0.44, 0.47, 0.50), Color(0.50, 0.52, 0.51),
	]
	var base: Color = bases[idx % bases.size()]
	var light: Color = base.lightened(0.26)
	var light2: Color = base.lightened(0.12)
	var mid: Color = base
	var dark: Color = base.darkened(0.20)
	var deep: Color = base.darkened(0.40)
	var moss: Color = Color(0.30, 0.50, 0.26)
	var moss_d: Color = Color(0.22, 0.40, 0.20)
	_ellipse(img, int(f * 0.50), int(f * 0.90), int(f * 0.40), int(f * 0.08), SHADOW, true)
	match idx % 5:
		0:
			# runder Findling
			_outlined_ellipse(img, int(f * 0.50), int(f * 0.62), int(f * 0.40), int(f * 0.29), mid, 3)
			_tri(img, Vector2(f * 0.34, f * 0.40), Vector2(f * 0.66, f * 0.40), Vector2(f * 0.50, f * 0.58), light)
			_tri(img, Vector2(f * 0.24, f * 0.62), Vector2(f * 0.46, f * 0.62), Vector2(f * 0.34, f * 0.84), dark)
			_rect(img, int(f * 0.60), int(f * 0.52), int(f * 0.14), int(f * 0.05), light2)
			_tri(img, Vector2(f * 0.62, f * 0.72), Vector2(f * 0.80, f * 0.78), Vector2(f * 0.68, f * 0.88), deep)
		1:
			# flacher Brocken
			_outlined_ellipse(img, int(f * 0.50), int(f * 0.70), int(f * 0.46), int(f * 0.19), mid, 3)
			_rect(img, int(f * 0.22), int(f * 0.62), int(f * 0.30), int(f * 0.04), light)
			_rect(img, int(f * 0.56), int(f * 0.66), int(f * 0.22), int(f * 0.04), light2)
			_tri(img, Vector2(f * 0.30, f * 0.74), Vector2(f * 0.54, f * 0.74), Vector2(f * 0.42, f * 0.88), dark)
		2:
			# hoher Fels (Umriss + Fuellung, keine freie Dreiecksform - die
			# wirkte im Spiel wie ein heller Kegel)
			_outlined_ellipse(img, int(f * 0.50), int(f * 0.70), int(f * 0.30), int(f * 0.13), deep, 2)
			_outlined_ellipse(img, int(f * 0.50), int(f * 0.56), int(f * 0.34), int(f * 0.26), mid, 3)
			_outlined_ellipse(img, int(f * 0.50), int(f * 0.40), int(f * 0.24), int(f * 0.16), mid, 3)
			_ellipse(img, int(f * 0.42), int(f * 0.34), int(f * 0.10), int(f * 0.05), light, true)
			_ellipse(img, int(f * 0.60), int(f * 0.52), int(f * 0.08), int(f * 0.04), light2, true)
			_rect(img, int(f * 0.30), int(f * 0.62), int(f * 0.16), int(f * 0.04), dark)
			_thick_line(img, Vector2(f * 0.50, f * 0.34), Vector2(f * 0.50, f * 0.70), 1.0, deep)
		3:
			# gespalten (zwei Huegel)
			_outlined_ellipse(img, int(f * 0.38), int(f * 0.64), int(f * 0.28), int(f * 0.24), mid, 3)
			_outlined_ellipse(img, int(f * 0.66), int(f * 0.70), int(f * 0.24), int(f * 0.18), base.darkened(0.10), 3)
			_tri(img, Vector2(f * 0.30, f * 0.46), Vector2(f * 0.46, f * 0.48), Vector2(f * 0.38, f * 0.62), light)
			_rect(img, int(f * 0.30), int(f * 0.72), int(f * 0.24), int(f * 0.04), dark)
			_thick_line(img, Vector2(f * 0.54, f * 0.56), Vector2(f * 0.50, f * 0.80), 2.0, deep)
		4:
			# eckiger Block
			_outlined_ellipse(img, int(f * 0.50), int(f * 0.66), int(f * 0.36), int(f * 0.24), mid, 3)
			_tri(img, Vector2(f * 0.30, f * 0.56), Vector2(f * 0.70, f * 0.56), Vector2(f * 0.58, f * 0.42), light)
			_rect(img, int(f * 0.26), int(f * 0.66), int(f * 0.48), int(f * 0.05), dark)
			_rect(img, int(f * 0.42), int(f * 0.46), int(f * 0.16), int(f * 0.22), light2)
			_tri(img, Vector2(f * 0.62, f * 0.72), Vector2(f * 0.82, f * 0.74), Vector2(f * 0.70, f * 0.86), deep)
	# Moos/Gras an der Unterseite (bei jedem Varianten-Typ)
	var mx: int = int(f * 0.22)
	while mx < int(f * 0.78):
		var h: int = 2 + int(abs(sin(float(mx) * 0.7)) * 4.0)
		_rect(img, mx, int(f * 0.86) - h, 2, h, moss if (mx / 2) % 2 == 0 else moss_d)
		mx += 2
	_disc(img, int(f * 0.30), int(f * 0.82), int(f * 0.05), moss, true)
	_disc(img, int(f * 0.68), int(f * 0.84), int(f * 0.04), moss_d, true)
	print("[ART][STEIN] variante=%d basis=(%.2f,%.2f,%.2f) toene=5 moss=true" % [
		idx % 5, base.r, base.g, base.b])
	return ImageTexture.create_from_image(img)

