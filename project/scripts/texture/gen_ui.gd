class_name GenUi
extends TexDraw


static func _make_crosshair_icon() -> ImageTexture:
	# Runde 43: Pixel-Art-Fadenkreuz (16x16, 4x NEAREST) - einheitlich mit
	# der Muenze und den uebrigen Item-Icons.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.32, 0.10, 0.08)
	var mid := Color(1.0, 0.38, 0.28)
	var light := Color(1.0, 0.68, 0.52)
	# Ring (Pixelkreis) + Kreuzstifte
	for y in range(px):
		for x in range(px):
			var dx: float = float(x) - 7.5
			var dy: float = float(y) - 7.5
			var d: float = sqrt(dx * dx + dy * dy)
			if d >= 3.6 and d <= 6.4:
				small.set_pixel(x, y, mid)
	for i in range(4):
		var o: int = 7 - i
		small.set_pixel(7, o, mid)
		small.set_pixel(8, o, mid)
		small.set_pixel(o, 7, mid)
		small.set_pixel(o, 8, mid)
	# Innerer Ring hell
	for y in range(px):
		for x in range(px):
			var dx2: float = float(x) - 7.5
			var dy2: float = float(y) - 7.5
			var d2: float = sqrt(dx2 * dx2 + dy2 * dy2)
			if d2 >= 4.6 and d2 <= 5.4:
				small.set_pixel(x, y, light)
	# Mitte dunkel + Kern
	small.set_pixel(7, 7, edge)
	small.set_pixel(8, 7, edge)
	small.set_pixel(7, 8, edge)
	small.set_pixel(8, 8, edge)
	# Kontur nachziehen
	for y in range(px):
		for x in range(px):
			if small.get_pixel(x, y).a > 0.0:
				var up: bool = y + 1 < px and small.get_pixel(x, y + 1).a > 0.0
				var dn: bool = y - 1 >= 0 and small.get_pixel(x, y - 1).a > 0.0
				var lf: bool = x + 1 < px and small.get_pixel(x + 1, y).a > 0.0
				var rt: bool = x - 1 >= 0 and small.get_pixel(x - 1, y).a > 0.0
				if not (up and dn and lf and rt):
					small.set_pixel(x, y, edge)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_gear_icon() -> ImageTexture:
	var img = _new_img(96, 96)
	# Zahnrad: 8 Zähne + Ring + Nabe
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var c := Vector2(48, 48) + Vector2(cos(a), sin(a)) * 36.0
		_outlined_disc(img, int(c.x), int(c.y), 12, Color(0.86, 0.89, 0.96), 2)
	_outlined_disc(img, 48, 48, 30, Color(0.86, 0.89, 0.96), 3)
	_disc(img, 48, 48, 13, Color(0.30, 0.34, 0.42))
	_disc(img, 48, 48, 9, Color(0.14, 0.16, 0.22))
	return ImageTexture.create_from_image(img)


static func _make_shield_icon() -> ImageTexture:
	# Runde 43: Pixel-Art-Schild (16x16, 4x NEAREST) - vorher war es ein
	# weiches Dreieck und brach die Einheitlichkeit der Icon-Reihe.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.12, 0.16, 0.26)
	var body := Color(0.36, 0.62, 0.92)
	var light := Color(0.72, 0.88, 1.0)
	# Schildform in Pixelstufen
	for y in range(3, 12):
		var w: int = 5
		if y > 6:
			w = 5 - (y - 6)
		if y >= 11:
			w = 1
		for x in range(8 - w, 8 + w):
			small.set_pixel(x, y, body)
	# Spitze
	small.set_pixel(7, 12, body)
	small.set_pixel(8, 12, body)
	small.set_pixel(7, 13, body.darkened(0.2))
	small.set_pixel(8, 13, body.darkened(0.2))
	# Innerer Rand + Glanz
	for y in range(4, 11):
		small.set_pixel(6, y, light)
	small.set_pixel(7, 4, light)
	small.set_pixel(8, 4, light)
	# Mittelstreifen
	for y in range(5, 11):
		small.set_pixel(7, y, light.darkened(0.15))
		small.set_pixel(8, y, light.darkened(0.15))
	# Kontur
	_px_outline(small, px, edge)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_revive_icon() -> ImageTexture:
	# v1.41 (F3): eigenes Icon fuer "LEBEN ZURUECK" - Herz mit Pfeil nach oben.
	# Vorher hatte dieser Artikel gar keine Grafik (nur Text).
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.16, 0.06, 0.10)
	var rot := Color(0.90, 0.24, 0.28)
	var light := Color(1.0, 0.55, 0.55)
	var arr := Color(0.45, 0.95, 0.60)
	# Herz in Pixelstufen (untere 10 Zeilen)
	var rows := [
		".XXX..XXX.",
		"XXXXXXXXX.",
		"XXXXXXXXXX",
		"XXXXXXXXXX",
		".XXXXXXXX.",
		"..XXXXXX..",
		"...XXXX...",
		"....XX...."
	]
	for y in range(rows.size()):
		var r: String = str(rows[y])
		for x in range(10):
			if x < r.length() and str(r[x]) == "X":
				small.set_pixel(3 + x, 6 + y, rot)
	# Glanzkante links oben
	small.set_pixel(5, 7, light)
	small.set_pixel(6, 7, light)
	small.set_pixel(4, 8, light)
	# Pfeil nach oben (Wiederbelebung)
	for y in range(2, 7):
		small.set_pixel(8, y, arr)
	small.set_pixel(7, 3, arr)
	small.set_pixel(9, 3, arr)
	small.set_pixel(6, 4, arr)
	small.set_pixel(10, 4, arr)
	_px_outline(small, px, edge)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	print("[TEX][NEU] icon_revive gezeichnet (%dx%d)" % [px * big, px * big])
	return ImageTexture.create_from_image(small)


static func _make_nav_icon(kind: String) -> ImageTexture:
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var dark := Color(0.10, 0.10, 0.16)
	match kind:
		"lan":
			# Zwei Spieler + Verbindung
			_outlined_disc(small, 5, 6, 3, Color(0.95, 0.72, 0.30), 1)
			_outlined_disc(small, 11, 6, 3, Color(0.40, 0.78, 0.95), 1)
			_rect(small, 2, 10, 6, 4, dark)
			_rect(small, 8, 10, 6, 4, dark)
			_rect(small, 6, 5, 4, 1, Color(0.60, 0.95, 0.60))
		"char":
			# Heldenkopf
			_outlined_disc(small, 8, 7, 5, Color(0.95, 0.75, 0.55), 1)
			_ellipse(small, 8, 4, 5, 3, Color(0.45, 0.25, 0.10), true)
			_px(small, 6, 7, dark)
			_px(small, 10, 7, dark)
			_rect(small, 6, 10, 5, 1, dark)
			_rect(small, 4, 12, 8, 3, Color(0.30, 0.55, 0.95))
		"shop":
			# Truhe
			_rect(small, 3, 6, 10, 6, Color(0.72, 0.48, 0.22))
			_rect(small, 2, 4, 12, 3, Color(0.88, 0.62, 0.26))
			_rect(small, 6, 4, 4, 8, Color(0.55, 0.38, 0.16))
			_rect(small, 7, 7, 2, 2, Color(0.98, 0.85, 0.30))
		"coll":
			# Raster (Sammlung)
			for gy in range(3, 14, 5):
				for gx in range(3, 14, 5):
					_rect(small, gx, gy, 4, 4, Color(0.62, 0.42, 0.85))
					_rect(small, gx + 1, gy + 1, 2, 2, Color(0.85, 0.72, 0.98))
		"chal":
			# Klemmbrett mit Haken (Aufgaben)
			_rect(small, 3, 3, 10, 11, Color(0.98, 0.80, 0.22))
			_rect(small, 4, 4, 8, 9, Color(0.92, 0.92, 0.96))
			_rect(small, 6, 2, 4, 2, dark)
			_rect(small, 5, 6, 2, 2, Color(0.30, 0.78, 0.45))
			_rect(small, 8, 6, 3, 1, dark)
			_rect(small, 5, 9, 2, 2, Color(0.30, 0.78, 0.45))
			_rect(small, 8, 9, 3, 1, dark)
		"map":
			# Weltkarte
			_rect(small, 2, 3, 12, 10, Color(0.20, 0.56, 0.68))
			_rect(small, 4, 5, 3, 2, Color(0.60, 0.85, 0.40))
			_rect(small, 8, 8, 4, 2, Color(0.60, 0.85, 0.40))
			_rect(small, 5, 9, 2, 2, Color(0.95, 0.85, 0.35))
	_px_outline(small, px, dark)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_chal_icon(kind: String, size: int = 128) -> ImageTexture:
	# v1.44 (C3): sechs Aufgaben-Motive, 128 px, flache Fuellung, 3-px-Kontur,
	# ohne Text. Gleiche Palette wie die uebrigen UI-Icons.
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink := Color(0.10, 0.10, 0.16)
	var gold := Color(0.98, 0.80, 0.22)
	var steel := Color(0.66, 0.72, 0.82)
	var red := Color(0.86, 0.24, 0.28)
	var green := Color(0.30, 0.78, 0.45)
	var wood := Color(0.72, 0.48, 0.22)
	match kind:
		"revolver":
			# Revolver in Seitenansicht: Lauf rechts, Trommel mittig, Griff schraeg
			# nach links unten, Abzugsbuegel darunter.
			_rect(img, 50, 40, 70, 26, ink)
			_rect(img, 53, 43, 64, 20, steel)
			_rect(img, 110, 34, 12, 38, ink)
			_rect(img, 113, 37, 6, 32, steel)
			_disc(img, 46, 58, 20, ink, true)
			_disc(img, 46, 58, 16, Color(0.78, 0.83, 0.90), true)
			_disc(img, 46, 58, 5, ink, true)
			_rect(img, 46, 26, 9, 16, ink)
			_rect(img, 48, 28, 5, 12, steel)
			_tri(img, Vector2(24, 62), Vector2(50, 62), Vector2(34, 108), ink)
			_tri(img, Vector2(28, 64), Vector2(46, 64), Vector2(35, 102), wood)
			_rect(img, 62, 64, 14, 12, ink)
			_rect(img, 64, 66, 10, 8, steel)
			_rect(img, 66, 76, 7, 14, ink)
		"shield":
			# Schild mit durchgestrichenem Balken
			_rect(img, 26, 30, 76, 40, ink)
			_tri(img, Vector2(20, 64), Vector2(108, 64), Vector2(64, 114), ink)
			_rect(img, 29, 33, 70, 34, steel)
			_tri(img, Vector2(26, 62), Vector2(102, 62), Vector2(64, 108), steel)
			_thick_line(img, Vector2(36, 96), Vector2(92, 34), 8.0, red)
			_thick_line(img, Vector2(36, 96), Vector2(92, 34), 3.0, Color(1.0, 0.62, 0.55))
		"crown":
			# Boss-Krone
			_tri(img, Vector2(20, 92), Vector2(44, 92), Vector2(30, 26), ink)
			_tri(img, Vector2(52, 92), Vector2(76, 92), Vector2(64, 14), ink)
			_tri(img, Vector2(84, 92), Vector2(108, 92), Vector2(98, 26), ink)
			_tri(img, Vector2(24, 90), Vector2(40, 90), Vector2(30, 30), gold)
			_tri(img, Vector2(56, 90), Vector2(72, 90), Vector2(64, 19), gold)
			_tri(img, Vector2(88, 90), Vector2(104, 90), Vector2(98, 30), gold)
			_rect(img, 18, 84, 92, 26, ink)
			_rect(img, 21, 87, 86, 20, gold)
			_rect(img, 21, 94, 86, 6, Color(0.82, 0.58, 0.12))
			_disc(img, 64, 84, 7, red, true)
		"clock":
			# Stoppuhr
			_rect(img, 54, 12, 20, 16, ink)
			_rect(img, 57, 15, 14, 10, gold)
			_disc(img, 64, 72, 46, ink, true)
			_disc(img, 64, 72, 41, gold, true)
			_disc(img, 64, 72, 32, Color(0.96, 0.97, 0.99), true)
			_thick_line(img, Vector2(64, 72), Vector2(64, 48), 5.0, ink)
			_thick_line(img, Vector2(64, 72), Vector2(84, 82), 5.0, red)
			_disc(img, 64, 72, 6, ink, true)
			_rect(img, 30, 20, 22, 8, ink)
		"heart":
			# Herz auf Schild
			_rect(img, 24, 26, 80, 42, ink)
			_tri(img, Vector2(18, 60), Vector2(110, 60), Vector2(64, 116), ink)
			_rect(img, 27, 29, 74, 36, green)
			_tri(img, Vector2(24, 58), Vector2(104, 58), Vector2(64, 110), green)
			_disc(img, 50, 54, 17, ink, true)
			_disc(img, 78, 54, 17, ink, true)
			_tri(img, Vector2(33, 56), Vector2(95, 56), Vector2(64, 98), ink)
			_disc(img, 50, 54, 13, red, true)
			_disc(img, 78, 54, 13, red, true)
			_tri(img, Vector2(37, 56), Vector2(91, 56), Vector2(64, 93), red)
			_disc(img, 44, 46, 4, Color(1.0, 0.70, 0.68), true)
		"chest":
			# Schatzkiste
			_rect(img, 16, 50, 96, 60, ink)
			_rect(img, 19, 53, 90, 54, wood)
			_rect(img, 12, 36, 104, 22, ink)
			_rect(img, 15, 39, 98, 16, Color(0.86, 0.62, 0.28))
			_rect(img, 56, 36, 16, 74, gold)
			_rect(img, 54, 64, 20, 18, gold)
			_disc(img, 64, 73, 5, ink, true)
			_rect(img, 61, 76, 6, 10, ink)
		_:
			_disc(img, 64, 64, 40, gold, true)
	if size != 128:
		img.resize(size, size, Image.INTERPOLATE_NEAREST)
	print("[TEX][CHAL] kind=%s px=%d kontur=3" % [kind, size])
	return ImageTexture.create_from_image(img)


static func _make_coin_icon() -> ImageTexture:
	# Runde 43: Pixel-Art-Muenze im gleichen Stil wie das Herz-Asset
	# (16x16 Pixel, 4x NEAREST) - vorher war sie ein weicher Vektor-Kreis
	# und damit die hässliche Ausnahme in der Icon-Reihe.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.42, 0.28, 0.05)
	var mid := Color(0.98, 0.80, 0.18)
	var light := Color(1.0, 0.93, 0.55)
	# runde Muenze in Pixelstufen
	var rows := [
		"....XXXXXX....",
		"..XXXXXXXXXX..",
		".XXXXXXXXXXXX.",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		".XXXXXXXXXXXX.",
		"..XXXXXXXXXX..",
		"....XXXXXX...."
	]
	for y in range(rows.size()):
		var r: String = str(rows[y])
		for x in range(px):
			if x < r.length() and str(r[x]) == "X":
				small.set_pixel(x, 2 + y, mid)
	# Randpixel dunkel
	for y in range(2, 13):
		for x in range(px):
			if small.get_pixel(x, y).a > 0.0:
				var up_ok: bool = y + 1 < px and small.get_pixel(x, y + 1).a > 0.0
				var down_ok: bool = y - 1 >= 0 and small.get_pixel(x, y - 1).a > 0.0
				var left_ok: bool = x + 1 < px and small.get_pixel(x + 1, y).a > 0.0
				var right_ok: bool = x - 1 >= 0 and small.get_pixel(x - 1, y).a > 0.0
				if not (up_ok and down_ok and left_ok and right_ok):
					small.set_pixel(x, y, edge)
	# Praegung: heller Rand + Waehrungszeichen
	for x in range(5, 11):
		small.set_pixel(x, 4, light)
		small.set_pixel(x, 9, light)
	for y in range(5, 9):
		small.set_pixel(5, y, light)
		small.set_pixel(10, y, light)
	# kleines Zeichen in der Mitte
	small.set_pixel(7, 6, edge)
	small.set_pixel(8, 6, edge)
	small.set_pixel(8, 7, edge)
	small.set_pixel(7, 8, edge)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_stick_base() -> ImageTexture:
	var img = _new_img(240, 240)
	_disc(img, 120, 120, 118, OUTLINE)
	_disc(img, 120, 120, 114, Color(0.1, 0.1, 0.12, 0.30))
	_ring(img, 120, 120, 108, 4, Color(1, 1, 1, 0.35))
	return ImageTexture.create_from_image(img)


static func _make_stick_knob() -> ImageTexture:
	var img = _new_img(100, 100)
	_disc(img, 50, 50, 48, OUTLINE)
	_disc(img, 50, 50, 42, Color(0.90, 0.92, 0.95, 0.90))
	_disc(img, 50, 50, 20, Color(0.60, 0.62, 0.68, 0.90))
	_disc(img, 42, 40, 8, Color(1, 1, 1, 0.8), true)
	return ImageTexture.create_from_image(img)


static func _make_wheel_icon(kind: String, size: int = 96) -> ImageTexture:
	# v1.48 (A2): Symbol fuer ein Gluecksrad-Segment (Muenze / Diamant / Niete).
	# Pixel-Art auf 32x32, dann NEAREST hochskaliert - gleiche Technik wie die
	# uebrigen Icons der Reihe.
	var px: int = 32
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.10, 0.08, 0.06)
	if kind == "gold":
		var gold := Color(0.98, 0.80, 0.18)
		var light := Color(1.0, 0.94, 0.60)
		for y in range(px):
			for x in range(px):
				var dx: float = float(x) - 15.5
				var dy: float = float(y) - 15.5
				if sqrt(dx * dx + dy * dy) <= 13.0:
					small.set_pixel(x, y, gold)
		for x in range(8, 25):
			small.set_pixel(x, 9, light)
			small.set_pixel(x, 22, light)
		for y in range(11, 21):
			small.set_pixel(9, y, light)
			small.set_pixel(22, y, light)
		for y in range(13, 19):
			small.set_pixel(15, y, edge)
		small.set_pixel(16, 13, edge)
		small.set_pixel(16, 18, edge)
	elif kind == "gems":
		var blue := Color(0.34, 0.66, 0.98)
		var light := Color(0.72, 0.92, 1.0)
		var dark := Color(0.16, 0.36, 0.72)
		# Diamant: obere Krone + untere Spitze
		for y in range(6, 26):
			var half: int = 0
			if y < 14:
				half = 4 + (y - 6)
			elif y < 19:
				half = 12
			else:
				half = maxi(1, 12 - (y - 19) * 2)
			for x in range(16 - half, 16 + half):
				var c: Color = blue
				if y < 14 and x < 16:
					c = light
				elif y > 18:
					c = dark
				small.set_pixel(x, y, c)
	else:
		var grau := Color(0.52, 0.55, 0.62)
		for i in range(7, 25):
			for t in range(-1, 2):
				small.set_pixel(i, i + t, grau)
				small.set_pixel(i, 31 - i + t, grau)
	# Kontur
	for y in range(px):
		for x in range(px):
			if small.get_pixel(x, y).a > 0.0:
				var up: bool = y + 1 < px and small.get_pixel(x, y + 1).a > 0.0
				var dn: bool = y - 1 >= 0 and small.get_pixel(x, y - 1).a > 0.0
				var lf: bool = x + 1 < px and small.get_pixel(x + 1, y).a > 0.0
				var rt: bool = x - 1 >= 0 and small.get_pixel(x - 1, y).a > 0.0
				if not (up and dn and lf and rt):
					small.set_pixel(x, y, edge)
	var big: int = maxi(1, int(round(float(size) / float(px))))
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	print("[TEX][WHEEL] icon=%s px=%d" % [kind, px * big])
	return ImageTexture.create_from_image(small)


static func _make_lock_chain(size: int = 96, col: Color = Color(0.80, 0.82, 0.88)) -> ImageTexture:
	# v1.48 (B1): Kette + Vorhaengeschloss fuer GESPERRTE Sammlungs-Kacheln.
	# Kette laeuft diagonal aus der linken oberen Ecke, das Schloss haengt
	# mittig darunter. Bewusst klein (96 px Basis), damit es das Item nicht
	# zudeckt.
	var img = _new_img(96, 96)
	var edge := Color(0.05, 0.05, 0.07, 0.95)
	# Kette: drei Glieder von (8,8) nach (34,34)
	var gl := [[14.0, 14.0], [24.0, 24.0], [33.0, 33.0]]
	for g in gl:
		_ring(img, float(g[0]), float(g[1]), 7.0, 4.0, edge)
		_ring(img, float(g[0]), float(g[1]), 7.0, 2.0, col)
	# Schlosskoerper (48..80 x 44..78)
	_rect(img, 44, 42, 38, 36, edge)
	_rect(img, 47, 45, 32, 30, Color(0.98, 0.80, 0.22))
	_rect(img, 47, 45, 32, 4, Color(1.0, 0.92, 0.55))
	# Buegel
	_ring(img, 63.0, 42.0, 13.0, 6.0, edge)
	_ring(img, 63.0, 42.0, 13.0, 3.0, col)
	# Schluesselloch
	_disc(img, 63.0, 57.0, 5.0, Color(0.12, 0.10, 0.08))
	_rect(img, 61, 57, 4, 10, Color(0.12, 0.10, 0.08))
	print("[TEX][LOCK] px=%d kette=3 schloss=1" % size)
	return ImageTexture.create_from_image(img)


static func _make_shoot_button() -> ImageTexture:
	# v1.48 (C3): In 512 px zeichnen, mit Kantenglaettung, dann auf 256 px
	# herunterrechnen - gleiches Design (roter Knopf, Ring, Zielpunkt), aber
	# ohne Treppchen und ohne einzelne Streupixel.
	var big: int = 512
	var img = _new_img(big, big)
	var c := float(big) * 0.5
	_aa = true
	_aa_n = 4
	# Aussenkontur + Fuellung
	_disc(img, c, c, 248.0, OUTLINE)
	_disc(img, c, c, 240.0, Color(0.72, 0.14, 0.12))
	_disc(img, c, c, 226.0, Color(0.90, 0.22, 0.19))
	# Ring (dicker, geschlossen)
	_ring(img, c, c, 176.0, 26.0, Color(0.99, 0.96, 0.90, 0.95))
	_ring(img, c, c, 176.0, 10.0, Color(1.0, 0.86, 0.36))
	# Zielkreuz
	_disc(img, c, c, 74.0, OUTLINE)
	_disc(img, c, c, 66.0, Color(0.99, 0.97, 0.92))
	_disc(img, c, c, 40.0, Color(0.86, 0.16, 0.14))
	_disc(img, c, c, 20.0, Color(1.0, 0.88, 0.30))
	# Vier Zielstriche (aussen am Ring)
	for ang in [0.0, PI * 0.5, PI, PI * 1.5]:
		var a := Vector2(cos(ang), sin(ang))
		var cv := Vector2(c, c)
		_thick_line(img, cv + a * 196.0, cv + a * 232.0, 9.0, OUTLINE)
		_thick_line(img, cv + a * 198.0, cv + a * 228.0, 5.0, Color(0.99, 0.96, 0.90))
	_aa = false
	_aa_n = 4
	img.resize(256, 256, Image.INTERPOLATE_CUBIC)
	var mess := _isolated_pixels(img)
	print("[BTN][PIXEL] knopf=shoot px=256 einsam=%d anteil=%.2f%%" % [int(mess["einsam"]), float(mess["anteil"])])
	return ImageTexture.create_from_image(img)


static func _isolated_pixels(img: Image) -> Dictionary:
	# v1.48 (C3): Anteil Pixel, deren vier Nachbarn alle (fast) leer sind.
	var w: int = img.get_width()
	var h: int = img.get_height()
	var einsam: int = 0
	var voll: int = 0
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if img.get_pixel(x, y).a <= 0.35:
				continue
			voll += 1
			var n: int = 0
			if img.get_pixel(x + 1, y).a > 0.10:
				n += 1
			if img.get_pixel(x - 1, y).a > 0.10:
				n += 1
			if img.get_pixel(x, y + 1).a > 0.10:
				n += 1
			if img.get_pixel(x, y - 1).a > 0.10:
				n += 1
			if n == 0:
				einsam += 1
	var anteil: float = 100.0 * float(einsam) / float(maxi(1, voll))
	return { "einsam": einsam, "anteil": anteil, "voll": voll}


static func _make_arrow_marker() -> ImageTexture:
	# Runde 31: Richtungspfeil zum letzten Monster (zeigt nach OBEN, wird gedreht)
	var img = _new_img(64, 64)
	_tri(img, Vector2(32.0, 4.0), Vector2(61.0, 42.0), Vector2(3.0, 42.0), OUTLINE)
	_tri(img, Vector2(32.0, 12.0), Vector2(54.0, 39.0), Vector2(10.0, 39.0), Color(1.0, 0.55, 0.12))
	_tri(img, Vector2(32.0, 20.0), Vector2(46.0, 35.0), Vector2(18.0, 35.0), Color(1.0, 0.86, 0.38))
	_rect(img, 25, 38, 14, 22, OUTLINE)
	_rect(img, 28, 40, 8, 18, Color(1.0, 0.72, 0.22))
	return ImageTexture.create_from_image(img)


static func _make_force_field() -> ImageTexture:
	# Runde 39: sichtbares Hexagon-Kraftfeld
	var img = _new_img(256, 256)
	var line_c := Color(0.45, 0.85, 1.0, 0.85)
	var fill_c := Color(0.30, 0.60, 1.0, 0.16)
	var pts: Array = []
	for i in range(6):
		var a: float = PI / 6.0 + float(i) * TAU / 6.0
		pts.append(Vector2(128.0 + cos(a) * 120.0, 128.0 + sin(a) * 120.0))
	for i in range(6):
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % 6]
		_tri(img, p1, p2, Vector2(128, 128), fill_c)
	# Hexagon-Ringe + Ecken
	for ring in [1.0, 0.72, 0.44]:
		var rpts: Array = []
		for i in range(6):
			var a2: float = PI / 6.0 + float(i) * TAU / 6.0
			rpts.append(Vector2(128.0 + cos(a2) * 120.0 * ring, 128.0 + sin(a2) * 120.0 * ring))
		for i in range(6):
			var q1: Vector2 = rpts[i]
			var q2: Vector2 = rpts[(i + 1) % 6]
			_tri(img, q1, q2, Vector2(128, 128), Color(0, 0, 0, 0))
		_rect(img, int(rpts[0].x) - 2, int(rpts[0].y) - 2, 4, 4, line_c)
		_rect(img, int(rpts[2].x) - 2, int(rpts[2].y) - 2, 4, 4, line_c)
		_rect(img, int(rpts[4].x) - 2, int(rpts[4].y) - 2, 4, 4, line_c)
	return ImageTexture.create_from_image(img)


static func _make_map_icon_earth(season: String) -> ImageTexture:
	# Runde 43: ERDE - Landschaft mit Himmel, Sonne, Huegel und Baum
	var px: int = 16
	var small := _px_canvas(px)
	var sky := Color(0.42, 0.68, 0.92)
	var ground := Color(0.48, 0.76, 0.36)
	var dark_g := Color(0.30, 0.56, 0.22)
	var sun := Color(1.0, 0.88, 0.30)
	var tree := Color(0.18, 0.48, 0.20)
	match season:
		"desert":
			sky = Color(0.92, 0.72, 0.42)
			ground = Color(0.88, 0.76, 0.44)
			dark_g = Color(0.68, 0.56, 0.28)
			tree = Color(0.42, 0.60, 0.24)
		"ice":
			sky = Color(0.62, 0.78, 0.92)
			ground = Color(0.86, 0.93, 0.98)
			dark_g = Color(0.66, 0.78, 0.88)
			tree = Color(0.40, 0.58, 0.52)
		"lava":
			sky = Color(0.32, 0.14, 0.16)
			ground = Color(0.36, 0.20, 0.20)
			dark_g = Color(0.22, 0.10, 0.10)
			tree = Color(0.55, 0.22, 0.12)
	# Himmel oben
	for y in range(0, 6):
		for x in range(px):
			small.set_pixel(x, y, sky)
	# Sonne
	small.set_pixel(12, 1, sun)
	small.set_pixel(11, 1, sun)
	small.set_pixel(12, 2, sun)
	small.set_pixel(13, 2, sun)
	# Huegel-Linie
	for x in range(px):
		var h: int = 6 + int(round(sin(float(x) * 0.55) * 1.4))
		for y in range(h, px):
			small.set_pixel(x, y, ground)
	# dunkle Kante
	for x in range(px):
		var h2: int = 6 + int(round(sin(float(x) * 0.55) * 1.4))
		small.set_pixel(x, h2, dark_g)
	# Baum links
	for y in range(6, 10):
		small.set_pixel(4, y, tree)
	small.set_pixel(3, 7, tree)
	small.set_pixel(5, 7, tree)
	small.set_pixel(4, 5, tree)
	# Busch rechts
	small.set_pixel(11, 10, dark_g)
	small.set_pixel(12, 10, dark_g)
	small.set_pixel(11, 11, dark_g)
	_px_outline(small, px, Color(0.10, 0.12, 0.16))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_map_icon_mars() -> ImageTexture:
	# Runde 43: MARS - roter Boden, Krater, Felsbrocken, Antenne
	var px: int = 16
	var small := _px_canvas(px)
	var sky := Color(0.72, 0.34, 0.26)
	var ground := Color(0.82, 0.44, 0.30)
	var dark := Color(0.52, 0.24, 0.18)
	var rock := Color(0.46, 0.30, 0.26)
	for y in range(0, 5):
		for x in range(px):
			small.set_pixel(x, y, sky)
	for y in range(5, px):
		for x in range(px):
			small.set_pixel(x, y, ground)
	# Horizont-Kante
	for x in range(px):
		small.set_pixel(x, 5, dark)
	# Krater (Ring)
	for i in range(4):
		small.set_pixel(3 + i, 9, dark)
		small.set_pixel(11 - i, 9, dark)
		small.set_pixel(2, 10 + i, dark)
		small.set_pixel(13, 10 + i, dark)
	small.set_pixel(4, 10, ground.darkened(0.10))
	small.set_pixel(5, 10, ground.darkened(0.10))
	small.set_pixel(10, 10, ground.darkened(0.10))
	# Felsen links
	small.set_pixel(2, 12, rock)
	small.set_pixel(3, 11, rock)
	small.set_pixel(3, 12, rock)
	small.set_pixel(2, 13, rock)
	# Antenne rechts (Mars-Rover)
	small.set_pixel(12, 8, Color(0.70, 0.72, 0.78))
	small.set_pixel(12, 9, Color(0.70, 0.72, 0.78))
	small.set_pixel(11, 7, Color(0.94, 0.40, 0.28))
	small.set_pixel(13, 12, Color(0.30, 0.26, 0.24))
	small.set_pixel(14, 12, Color(0.30, 0.26, 0.24))
	_px_outline(small, px, Color(0.16, 0.08, 0.06))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_map_icon_jungle() -> ImageTexture:
	# Runde 43: JUNGLE - dichtes Blattdach, Lianen, Vulkan, Banane
	var px: int = 16
	var small := _px_canvas(px)
	var deep := Color(0.12, 0.30, 0.16)
	var leaf := Color(0.24, 0.56, 0.24)
	var leaf2 := Color(0.36, 0.68, 0.28)
	var ground := Color(0.20, 0.40, 0.20)
	for y in range(0, px):
		for x in range(px):
			small.set_pixel(x, y, deep)
	# Blattdach oben (3 Ebenen)
	for y in range(0, 4):
		for x in range(px):
			small.set_pixel(x, y, leaf if (x + y) % 3 == 0 else leaf2)
	for y in range(4, 6):
		for x in range(px):
			small.set_pixel(x, y, leaf.darkened(0.18))
	# Boden
	for y in range(12, px):
		for x in range(px):
			small.set_pixel(x, y, ground)
	# Stamm
	for y in range(5, 13):
		small.set_pixel(7, y, Color(0.34, 0.24, 0.14))
		small.set_pixel(8, y, Color(0.28, 0.19, 0.11))
	# Liane links
	for y in range(3, 10):
		small.set_pixel(2, y, leaf2)
	small.set_pixel(3, 8, leaf2)
	small.set_pixel(3, 9, leaf2)
	# Banane rechts (gelb)
	small.set_pixel(12, 9, Color(0.98, 0.86, 0.20))
	small.set_pixel(13, 9, Color(0.98, 0.86, 0.20))
	small.set_pixel(13, 10, Color(0.90, 0.78, 0.16))
	small.set_pixel(12, 8, Color(0.40, 0.62, 0.20))
	# Vulkan-Rauch
	small.set_pixel(11, 1, Color(0.62, 0.58, 0.60))
	small.set_pixel(12, 0, Color(0.62, 0.58, 0.60))
	_px_outline(small, px, Color(0.06, 0.14, 0.08))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_map_icon_volt() -> ImageTexture:
	# Runde 43: ELEKTRO-WELT - Blitz, Spulen, Kabel auf dunklem Stahl
	var px: int = 16
	var small := _px_canvas(px)
	var steel := Color(0.18, 0.20, 0.30)
	var steel2 := Color(0.26, 0.29, 0.42)
	var bolt := Color(1.0, 0.86, 0.22)
	var bolt2 := Color(1.0, 0.97, 0.65)
	for y in range(px):
		for x in range(px):
			small.set_pixel(x, y, steel if (x + y) % 4 == 0 else steel2)
	# Spulen links + rechts
	for y in range(4, 11):
		small.set_pixel(1, y, Color(0.55, 0.40, 0.16))
		small.set_pixel(14, y, Color(0.55, 0.40, 0.16))
	for x in range(1, 4):
		small.set_pixel(x, 4, Color(0.75, 0.56, 0.22))
		small.set_pixel(x, 10, Color(0.75, 0.56, 0.22))
	for x in range(12, 15):
		small.set_pixel(x, 4, Color(0.75, 0.56, 0.22))
		small.set_pixel(x, 10, Color(0.75, 0.56, 0.22))
	# Blitz in der Mitte
	var b := [[8,1],[7,2],[6,3],[5,4],[4,5],[8,5],[9,6],[10,7],[11,8],[12,9],[11,10],[10,11],[9,12],[8,13],[7,12],[6,11],[5,10],[4,9],[5,8],[6,7],[7,6],[8,5]]
	for p in b:
		small.set_pixel(int(p[0]), int(p[1]), bolt)
	small.set_pixel(6, 4, bolt2)
	small.set_pixel(5, 5, bolt2)
	small.set_pixel(9, 6, bolt2)
	_px_outline(small, px, Color(0.06, 0.06, 0.10))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_map_icon(base: Color, accent: Color, motif: String) -> ImageTexture:
	# Runde 42: echtes PIXEL-ART-Icon.
	# 16x16 Pixel 4x hochskaliert (NEAREST) -> harte Kanten, keine weichen Verlaeufe.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	for y in range(px):
		for x in range(px):
			var c := base if (x + y) % 2 == 0 else base.darkened(0.16)
			small.set_pixel(x, y, c)
	var dark := accent.darkened(0.45)
	match motif:
		"tuft":
			for hx in [5, 9, 12]:
				for i in range(4):
					small.set_pixel(hx, 9 - i, accent)
				small.set_pixel(hx - 1, 8, accent.darkened(0.22))
				small.set_pixel(hx + 1, 7, accent.darkened(0.22))
		"cactus":
			for i in range(8):
				small.set_pixel(7, 13 - i, accent)
			for i in range(3):
				small.set_pixel(5, 10 - i, accent)
				small.set_pixel(9, 8 - i, accent)
			small.set_pixel(4, 11, accent)
			small.set_pixel(10, 9, accent)
		"ice":
			# Runde 42: Breite begrenzt (max 8 Pixel je Seite), sonst Out-of-Bounds
			for i in range(9):
				var w: int = mini(8, 9 - i)
				for j in range(w):
					small.set_pixel(8 - j, 12 - i, accent)
					small.set_pixel(8 + j, 12 - i, accent)
			for i in range(3):
				var w2: int = mini(4, 4 - i)
				for j in range(w2):
					small.set_pixel(8 - j, 10 - i, Color(1, 1, 1))
					small.set_pixel(8 + j, 10 - i, Color(1, 1, 1))
		"lava":
			for i in range(4):
				small.set_pixel(5 - i, 11, accent)
				small.set_pixel(5 + i, 11, accent)
				small.set_pixel(5, 11 - i, accent)
				small.set_pixel(5, 11 + i, accent)
			small.set_pixel(4, 10, accent.lightened(0.35))
			small.set_pixel(6, 10, accent.lightened(0.35))
			small.set_pixel(4, 12, accent.lightened(0.35))
			small.set_pixel(6, 12, accent.lightened(0.35))
			small.set_pixel(5, 10, accent.lightened(0.55))
			small.set_pixel(5, 12, accent.lightened(0.55))
	for i in range(px):
		small.set_pixel(i, 0, dark)
		small.set_pixel(i, px - 1, dark)
		small.set_pixel(0, i, dark)
		small.set_pixel(px - 1, i, dark)
	# Runde 42: resize() mutiert in Godot 4 (gibt void zurueck)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)
