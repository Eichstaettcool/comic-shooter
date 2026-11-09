class_name GenItems
extends TexDraw


static func _create_heart_texture(color: Color, outline_color: Color, size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var fx = float(x) - size / 2.0
			var fy = float(y) - size / 2.0 + size / 4.0
			var circle1 = Vector2(float(x) - size / 4.0, fy).length()
			var circle2 = Vector2(float(x) - 3.0 * size / 4.0, fy).length()
			if circle1 <= half / 2.0 or circle2 <= half / 2.0 or (fy >= 0 and fy < half and abs(fx) < half - fy * 0.5):
				img.set_pixel(x, y, color)
			elif circle1 <= half / 2.0 + 1 or circle2 <= half / 2.0 + 1:
				img.set_pixel(x, y, outline_color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


static func _create_shape_texture(color: Color, outline_color: Color, size: int, outline_width: int, shape_type: String) -> ImageTexture:
	var outer = size
	var img = _new_img(outer * 2, outer * 2)
	var center = float(outer)
	for x in range(int(center * 2)):
		for y in range(int(center * 2)):
			if shape_type == "pistol":
				if abs(x - center) < size / 1.5 and abs(y - center) < size / 3:
					img.set_pixel(x, y, color)
				elif abs(x - center) < size * 0.7 and abs(y - center) < size / 2:
					img.set_pixel(x, y, outline_color)
			elif shape_type == "shotgun":
				if abs(x - center) < size and abs(y - center) < size / 3:
					img.set_pixel(x, y, color)
				elif abs(x - center) < size * 1.1 and abs(y - center) < size / 2:
					img.set_pixel(x, y, outline_color)
			elif shape_type == "machine":
				if abs(x - center) < size / 1.2 and abs(y - center) < size / 2:
					img.set_pixel(x, y, color)
				elif abs(x - center) < size * 0.9 and abs(y - center) < size:
					img.set_pixel(x, y, outline_color)
	return ImageTexture.create_from_image(img)


static func _make_weapon_pistol() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.74, 0.76, 0.80)
	var steel_dark := Color(0.46, 0.48, 0.54)
	var grip := Color(0.34, 0.25, 0.18)
	_rect(img, 19, 14, 31, 10, OUTLINE)
	_rect(img, 21, 15, 28, 8, steel)
	_rect(img, 45, 17, 16, 6, OUTLINE)
	_rect(img, 45, 18, 15, 4, steel_dark)
	_rect(img, 23, 16, 6, 3, Color(0.92, 0.94, 0.98))
	_rect(img, 15, 22, 11, 15, OUTLINE)
	_rect(img, 17, 23, 8, 13, grip)
	_rect(img, 30, 24, 4, 7, OUTLINE)
	_rect(img, 36, 25, 3, 4, steel_dark)
	return ImageTexture.create_from_image(img)


static func _make_weapon_shotgun() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.66, 0.68, 0.72)
	var wood := Color(0.55, 0.34, 0.19)
	var wood_dark := Color(0.38, 0.23, 0.13)
	# Schaft
	_rect(img, 6, 16, 16, 11, OUTLINE)
	_rect(img, 8, 17, 13, 9, wood)
	_rect(img, 8, 20, 13, 3, wood_dark)
	# Verschluss
	_rect(img, 20, 15, 16, 10, OUTLINE)
	_rect(img, 22, 16, 13, 8, Color(0.30, 0.30, 0.34))
	# langer Lauf
	_rect(img, 34, 17, 28, 6, OUTLINE)
	_rect(img, 34, 18, 27, 4, steel)
	# Pumpe
	_rect(img, 40, 22, 12, 6, OUTLINE)
	_rect(img, 41, 23, 10, 4, wood)
	return ImageTexture.create_from_image(img)


static func _make_weapon_machine() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.46, 0.50, 0.56)
	var steel_dark := Color(0.28, 0.31, 0.36)
	var mag := Color(0.36, 0.58, 0.36)
	_rect(img, 12, 15, 34, 11, OUTLINE)
	_rect(img, 14, 16, 30, 9, steel)
	# Magazin unten
	_rect(img, 26, 25, 12, 13, OUTLINE)
	_rect(img, 28, 26, 8, 11, mag)
	_rect(img, 28, 28, 8, 2, Color(0.22, 0.40, 0.24))
	# Lauf mit Kühlrippen
	_rect(img, 44, 16, 18, 7, OUTLINE)
	_rect(img, 44, 17, 17, 5, steel_dark)
	for i in range(4):
		_px(img, 47 + i * 4, 17, Color(0.70, 0.74, 0.80))
	# Schulterstuetze
	_rect(img, 6, 14, 8, 13, OUTLINE)
	_rect(img, 7, 15, 6, 11, steel_dark)
	# Korn
	_rect(img, 54, 11, 3, 6, OUTLINE)
	return ImageTexture.create_from_image(img)


static func _make_weapon_laser() -> ImageTexture:
	var img = _new_img(64, 40)
	var body := Color(0.30, 0.62, 0.72)
	var body_dark := Color(0.18, 0.42, 0.52)
	var glow := Color(0.55, 1.0, 1.0)
	# kompakter Körper
	_rect(img, 20, 14, 26, 13, OUTLINE)
	_rect(img, 22, 15, 22, 11, body)
	_rect(img, 22, 15, 22, 3, Color(0.55, 0.90, 1.0))
	# Energie-Kern
	_disc(img, 33, 20, 5, OUTLINE)
	_disc(img, 33, 20, 3, glow)
	# duenner Strahler
	_rect(img, 44, 18, 16, 5, OUTLINE)
	_rect(img, 44, 19, 15, 3, body_dark)
	_disc(img, 60, 20, 4, OUTLINE)
	_disc(img, 60, 20, 2.5, glow)
	# Griff
	_rect(img, 24, 26, 9, 11, OUTLINE)
	_rect(img, 25, 27, 7, 9, body_dark)
	return ImageTexture.create_from_image(img)


static func _make_weapon_revolver() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.80, 0.68, 0.30)
	var steel_dark := Color(0.52, 0.41, 0.16)
	var grip := Color(0.40, 0.24, 0.16)
	# Trommel
	_disc(img, 32, 20, 11, OUTLINE)
	_disc(img, 32, 20, 9, steel)
	for i in range(6):
		var a := i * TAU / 6.0
		_disc(img, 32 + cos(a) * 5.0, 20 + sin(a) * 5.0, 2.0, steel_dark)
	# Lauf
	_rect(img, 42, 17, 20, 7, OUTLINE)
	_rect(img, 42, 18, 19, 5, steel)
	# Hahn
	_rect(img, 20, 12, 6, 6, OUTLINE)
	# Griff schraeg
	_rect(img, 18, 26, 12, 13, OUTLINE)
	_rect(img, 20, 27, 9, 11, grip)
	# Abzug
	_rect(img, 34, 29, 4, 7, OUTLINE)
	return ImageTexture.create_from_image(img)


static func _make_rarity_ring(c: Color) -> ImageTexture:
	var img = _new_img(56, 56)
	_ring(img, 28, 28, 26, 4, Color(c.r, c.g, c.b, 0.85))
	_ring(img, 28, 28, 22, 2, Color(c.r, c.g, c.b, 0.35))
	# 4 Funkel-Punkte
	for pt in [[28, 3], [28, 53], [3, 28], [53, 28]]:
		_disc(img, pt[0], pt[1], 2.5, Color(1, 1, 1, 0.9))
	return ImageTexture.create_from_image(img)


static func _make_shield_ring() -> ImageTexture:
	var img = _new_img(64, 64)
	_ring(img, 32, 32, 30, 5, OUTLINE)
	_ring(img, 32, 32, 26, 4, Color(0.3, 0.85, 1.0, 0.75))
	# 4 Glanzpunkte
	for pt in [[32, 4], [32, 60], [4, 32], [60, 32]]:
		_disc(img, pt[0], pt[1], 3, Color(0.8, 0.98, 1.0))
	return ImageTexture.create_from_image(img)


static func _make_glow(size: int, col: Color) -> ImageTexture:
	var img = _new_img(size, size)
	var c := int(size / 2)
	for r in range(c, 0, -1):
		var a := pow(1.0 - float(r) / float(c), 1.6) * 0.5
		_disc(img, c, c, r, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)


static func _make_freeze_icon() -> ImageTexture:
	var img = _new_img(40, 40)
	_disc(img, 20, 20, 19, OUTLINE)
	_disc(img, 20, 20, 17, Color(0.45, 0.80, 1.0))
	# Schneeflocke
	_rect(img, 19, 7, 3, 26, Color(1, 1, 1))
	_rect(img, 7, 19, 26, 3, Color(1, 1, 1))
	_px(img, 12, 12, Color(1, 1, 1))
	_px(img, 13, 13, Color(1, 1, 1))
	_px(img, 27, 27, Color(1, 1, 1))
	_px(img, 26, 26, Color(1, 1, 1))
	_px(img, 12, 28, Color(1, 1, 1))
	_px(img, 13, 27, Color(1, 1, 1))
	_px(img, 27, 13, Color(1, 1, 1))
	_px(img, 26, 12, Color(1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _make_rapid_icon() -> ImageTexture:
	var img = _new_img(40, 40)
	_disc(img, 20, 20, 19, OUTLINE)
	_disc(img, 20, 20, 17, Color(1.0, 0.72, 0.20))
	# Blitz
	_tri(img, Vector2(23, 6), Vector2(12, 22), Vector2(20, 22), Color(1, 1, 1))
	_tri(img, Vector2(17, 34), Vector2(28, 18), Vector2(20, 18), Color(1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _make_slot_icon(size: int) -> ImageTexture:
	# Runde 100: Automat als Kachel-Icon fuer den Shop
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var cx := f * 0.5
	# Gehaeuse
	_rect(img, int(f * 0.10), int(f * 0.14), int(f * 0.80), int(f * 0.72), OUTLINE)
	_rect(img, int(f * 0.14), int(f * 0.18), int(f * 0.72), int(f * 0.64), Color(0.55, 0.16, 0.20))
	# Fenster
	_rect(img, int(f * 0.18), int(f * 0.24), int(f * 0.64), int(f * 0.30), OUTLINE)
	_rect(img, int(f * 0.21), int(f * 0.27), int(f * 0.58), int(f * 0.24), Color(0.92, 0.90, 0.82))
	for i in range(3):
		var wx: float = f * 0.29 + float(i) * f * 0.18
		_disc(img, wx, f * 0.39, f * 0.055, [Color(0.80, 0.14, 0.18), Color(0.96, 0.78, 0.20), Color(0.24, 0.44, 0.78)][i], true)
	# Hebel
	_thick_line(img, Vector2(f * 0.86, f * 0.30), Vector2(f * 0.92, f * 0.62), 5.0, OUTLINE)
	_disc(img, f * 0.92, f * 0.64, f * 0.055, Color(0.95, 0.20, 0.20), true)
	# Muenzschacht
	_rect(img, int(f * 0.36), int(f * 0.70), int(f * 0.28), int(f * 0.08), OUTLINE)
	_rect(img, int(f * 0.38), int(f * 0.72), int(f * 0.24), int(f * 0.04), Color(0.15, 0.15, 0.18))
	# Fuss
	_rect(img, int(f * 0.14), int(f * 0.86), int(f * 0.72), int(f * 0.06), Color(0.30, 0.30, 0.36))
	_aa = false
	return ImageTexture.create_from_image(img)


static func _make_slot_symbol(kind: String, size: int) -> ImageTexture:
	# Runde 94: Walzensymbole im Comic-Stil - dicke Kontur, flache Farben.
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var cx := f * 0.5
	match kind:
		"cherry":
			_thick_line(img, Vector2(cx, f * 0.30), Vector2(cx - f * 0.16, f * 0.62), 4.0, Color(0.20, 0.55, 0.22))
			_thick_line(img, Vector2(cx, f * 0.30), Vector2(cx + f * 0.18, f * 0.58), 4.0, Color(0.20, 0.55, 0.22))
			_disc(img, cx - f * 0.17, f * 0.66, f * 0.17, OUTLINE, true)
			_disc(img, cx + f * 0.19, f * 0.62, f * 0.16, OUTLINE, true)
			_disc(img, cx - f * 0.17, f * 0.65, f * 0.13, Color(0.80, 0.12, 0.16), true)
			_disc(img, cx + f * 0.19, f * 0.61, f * 0.12, Color(0.72, 0.10, 0.14), true)
			_disc(img, cx - f * 0.21, f * 0.60, f * 0.035, Color(1, 1, 1, 0.85), true)
		"bell":
			_tri(img, Vector2(cx, f * 0.20), Vector2(cx + f * 0.30, f * 0.66), Vector2(cx - f * 0.30, f * 0.66), OUTLINE)
			_tri(img, Vector2(cx, f * 0.26), Vector2(cx + f * 0.25, f * 0.64), Vector2(cx - f * 0.25, f * 0.64), Color(0.96, 0.79, 0.22))
			_rect(img, int(cx - f * 0.34), int(f * 0.64), int(f * 0.68), int(f * 0.08), OUTLINE)
			_rect(img, int(cx - f * 0.30), int(f * 0.66), int(f * 0.60), int(f * 0.04), Color(0.98, 0.86, 0.40))
			_disc(img, cx, f * 0.78, f * 0.07, OUTLINE, true)
			_disc(img, cx, f * 0.78, f * 0.05, Color(0.85, 0.66, 0.16), true)
		"bar":
			_rect(img, int(cx - f * 0.34), int(f * 0.30), int(f * 0.68), int(f * 0.40), OUTLINE)
			_rect(img, int(cx - f * 0.30), int(f * 0.34), int(f * 0.60), int(f * 0.32), Color(0.20, 0.42, 0.78))
			for i in range(3):
				_rect(img, int(cx - f * 0.22 + float(i) * f * 0.17), int(f * 0.40), int(f * 0.10), int(f * 0.20), Color(0.92, 0.95, 1.0))
		"gold1", "gold2", "gold3":
			var n: int = 1
			if kind == "gold2": n = 2
			elif kind == "gold3": n = 3
			for i in range(n):
				var ox: float = (float(i) - float(n - 1) * 0.5) * f * 0.22
				_disc(img, cx + ox, f * 0.52, f * 0.19, OUTLINE, true)
				_disc(img, cx + ox, f * 0.52, f * 0.15, Color(0.98, 0.80, 0.20), true)
				_disc(img, cx + ox - f * 0.04, f * 0.47, f * 0.045, Color(1, 1, 1, 0.9), true)
			if n == 3:
				_disc(img, cx, f * 0.22, f * 0.06, Color(1, 1, 0.9, 0.95), true)
		"skull":
			_disc(img, cx, f * 0.44, f * 0.28, OUTLINE, true)
			_disc(img, cx, f * 0.44, f * 0.24, Color(0.90, 0.90, 0.86), true)
			_rect(img, int(cx - f * 0.14), int(f * 0.60), int(f * 0.28), int(f * 0.14), OUTLINE)
			_rect(img, int(cx - f * 0.11), int(f * 0.60), int(f * 0.22), int(f * 0.11), Color(0.90, 0.90, 0.86))
			_disc(img, cx - f * 0.10, f * 0.42, f * 0.06, Color(0.05, 0.05, 0.08), true)
			_disc(img, cx + f * 0.10, f * 0.42, f * 0.06, Color(0.05, 0.05, 0.08), true)
			_tri(img, Vector2(cx, f * 0.50), Vector2(cx + f * 0.05, f * 0.58), Vector2(cx - f * 0.05, f * 0.58), Color(0.05, 0.05, 0.08))
	_aa = false
	return ImageTexture.create_from_image(img)


static func _make_gem_icon(level: int, size: int) -> ImageTexture:
	# Runde 95: 1-3 Edelsteine fuer den Kisten-Reveal
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var cx := f * 0.5
	for i in range(level):
		var ox: float = (float(i) - float(level - 1) * 0.5) * f * 0.22
		var cy: float = f * 0.55
		var w: float = f * 0.14
		var h: float = f * 0.20
		_tri(img, Vector2(cx + ox, cy - h), Vector2(cx + ox + w, cy), Vector2(cx + ox - w, cy), OUTLINE)
		_tri(img, Vector2(cx + ox, cy + h), Vector2(cx + ox + w, cy), Vector2(cx + ox - w, cy), OUTLINE)
		_tri(img, Vector2(cx + ox, cy - h * 0.9), Vector2(cx + ox + w * 0.85, cy), Vector2(cx + ox - w * 0.85, cy), Color(0.35, 0.82, 0.98))
		_tri(img, Vector2(cx + ox, cy - h * 0.9), Vector2(cx + ox, cy), Vector2(cx + ox - w * 0.85, cy), Color(0.78, 0.96, 1.0))
		_tri(img, Vector2(cx + ox, cy), Vector2(cx + ox + w * 0.85, cy), Vector2(cx + ox, cy + h * 0.9), Color(0.12, 0.52, 0.72))
		_disc(img, cx + ox - w * 0.3, cy - h * 0.45, f * 0.012, Color(1, 1, 1, 0.95), true)
	_aa = false
	return ImageTexture.create_from_image(img)


static func _heart_padded(color: Color, outline_color: Color, size: int) -> ImageTexture:
	# Herz mit Rand im Bild (sonst wird der Umriss am breitesten Punkt angeschnitten)
	var inner := int(round(float(size) * 0.82))
	var src: Image = _create_heart_texture(color, outline_color, inner).get_image()
	var img = _new_img(size, size)
	var off := int((size - inner) / 2)
	for x in range(inner):
		for y in range(inner):
			var c: Color = src.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x + off, y + off, c)
	return ImageTexture.create_from_image(img)
