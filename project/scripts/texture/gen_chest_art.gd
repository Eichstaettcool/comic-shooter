class_name GenChestArt
extends TexDraw

# v1.45 (K): Die drei Shop-Kisten werden GEZEICHNET - im selben Raster wie die
# Figuren (64x64, 3 px Kontur, flache Farben, 4x NEAREST hochskaliert).
# Vorher lagen hier fremde PNGs (assets/chests/*.png, weiche 3D-Truhen mit
# Glanzlichtern) - die passten nicht zum Comic-Shooter-Look.
#
# Je Stufe zwei Fassungen: geschlossen (Shop, Vorschau) und offen (Reveal).

const GOLD := Color(0.98, 0.80, 0.22)
const GOLD_D := Color(0.74, 0.52, 0.10)


static func _make_chest_art(tier: String, open: bool, size: int = 256) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match tier:
		"silver":
			_chest_steel(img, open)
		"premium":
			_chest_gold(img, open)
		_:
			_chest_wood(img, open)
	# Auf den Inhalt zuschneiden und quadratisch zentrieren - sonst steht die
	# Kiste mit viel Luft im Fenster (die 64x64-Flaeche ist nicht voll genutzt).
	img = _crop_center(img, 62)
	if size != 64:
		img.resize(size, size, Image.INTERPOLATE_NEAREST)
	var spitzen: int = kanten_spitzen(img)
	print("[TEX][CHEST] tier=%s offen=%s px=%d kontur=3 quelle=generiert spitzen=%d" % [tier, str(open), size, spitzen])
	return ImageTexture.create_from_image(img)



# v1.48 (C2): Alle drei Kisten neu - gleiche Silhouette, klare Formen,
# GERADE Deckelkante (keine Zacken), Schloss mittig.
# Gemeinsame Geometrie fuer "offen": Deckel liegt hinter dem Koerper,
# Scharniere verbinden beide, oben ist der Innenraum sichtbar.
static func _draw_open(img: Image, lid_col: Color, lid_dark: Color, body_box: Array, inner_col: Color) -> void:
	var bx: int = int(body_box[0])
	var by: int = int(body_box[1])
	var bw: int = int(body_box[2])
	var bh: int = int(body_box[3])
	# Deckel hinten: flacher Kasten mit gerader Oberkante (kein Zackenrand)
	_rect(img, bx + 2, by - 18, bw - 4, 16, OUTLINE)
	_rect(img, bx + 4, by - 16, bw - 8, 12, lid_col)
	_rect(img, bx + 4, by - 7, bw - 8, 3, lid_dark)
	# Scharniere
	_rect(img, bx + 5, by - 8, 5, 10, OUTLINE)
	_rect(img, bx + 6, by - 7, 3, 8, Color(0.42, 0.44, 0.50))
	_rect(img, bx + bw - 10, by - 8, 5, 10, OUTLINE)
	_rect(img, bx + bw - 9, by - 7, 3, 8, Color(0.42, 0.44, 0.50))
	# Innenraum: dunkle Oeffnung oben am Koerper
	_rect(img, bx + 2, by, bw - 4, 8, OUTLINE)
	_rect(img, bx + 3, by + 1, bw - 6, 6, inner_col)
	_rect(img, bx + 5, by + 3, bw - 10, 2, Color(1.0, 0.94, 0.62, 0.30))


# ---------------------------------------------------------------- Holz
static func _chest_wood(img: Image, open: bool) -> void:
	var dark := Color(0.13, 0.08, 0.05)
	var body := Color(0.66, 0.42, 0.20)
	var body_d := Color(0.48, 0.29, 0.13)
	var body_l := Color(0.80, 0.54, 0.27)
	var iron := Color(0.40, 0.42, 0.48)
	var iron_l := Color(0.68, 0.71, 0.78)

	_ellipse(img, 32, 58, 25, 4, Color(0, 0, 0, 0.32), true)

	if open:
		_draw_open(img, body_l, body_d, [7, 34, 50, 22], Color(0.09, 0.06, 0.04))
		_rect(img, 7, 34, 50, 22, OUTLINE)
		_rect(img, 10, 37, 44, 16, body)
		# Inhalt: zwei Goldmuenzen
		_disc(img, 22, 40, 5, GOLD, true)
		_disc(img, 41, 39, 5, GOLD, true)
		_disc(img, 40, 37, 3, Color(0.99, 0.90, 0.55), true)
	else:
		# Deckel: flacher Kasten, gerade Oberkante, 2 px Fase
		_rect(img, 9, 20, 46, 14, OUTLINE)
		_rect(img, 11, 22, 42, 10, body_l)
		_rect(img, 11, 26, 42, 6, body)
		# Deckelfuge (gerade Linie)
		_rect(img, 9, 32, 46, 3, dark)
		# Koerper
		_rect(img, 7, 33, 50, 24, OUTLINE)
		_rect(img, 10, 36, 44, 18, body)

	var body_y: int = 36 if open else 36
	var body_h: int = 17 if open else 18
	# Planken
	for i in range(1, 4):
		var yy: int = body_y + int(float(body_h) * float(i) / 4.0)
		_rect(img, 10, yy, 44, 1, body_d)
	# Zwei Eisenbaender
	for bx in [17, 41]:
		_rect(img, bx, body_y - 1, 6, body_h + 1, OUTLINE)
		_rect(img, bx + 1, body_y, 4, body_h - 1, iron)
		_rect(img, bx + 1, body_y, 1, body_h - 1, iron_l)
	# Schloss mittig
	_rect(img, 27, body_y - 1, 10, 11, OUTLINE)
	_rect(img, 28, body_y, 8, 9, GOLD)
	_px(img, 32, body_y + 3, OUTLINE)
	_px(img, 32, body_y + 4, OUTLINE)
	_px(img, 32, body_y + 5, OUTLINE)


# ---------------------------------------------------------------- Silber
static func _chest_steel(img: Image, open: bool) -> void:
	var steel := Color(0.56, 0.61, 0.70)
	var steel_d := Color(0.34, 0.38, 0.47)
	var steel_l := Color(0.78, 0.83, 0.92)
	var blue := Color(0.35, 0.72, 0.95)

	_ellipse(img, 32, 58, 25, 4, Color(0, 0, 0, 0.32), true)

	if open:
		_draw_open(img, steel_l, steel_d, [7, 34, 50, 22], Color(0.09, 0.11, 0.16))
		_rect(img, 7, 34, 50, 22, OUTLINE)
		_rect(img, 10, 37, 44, 16, steel)
		_rect(img, 25, 42, 14, 9, OUTLINE)
		_rect(img, 27, 43, 10, 6, blue)
		_rect(img, 29, 44, 3, 2, Color(0.85, 0.97, 1.0))
	else:
		# Deckel: flach, etwas schmaler als der Korpus (Lippe)
		_rect(img, 11, 19, 42, 15, OUTLINE)
		_rect(img, 13, 21, 38, 11, steel_l)
		_rect(img, 13, 25, 38, 7, steel)
		# Griffmulde im Deckel
		_rect(img, 26, 23, 12, 5, OUTLINE)
		_rect(img, 27, 24, 10, 3, steel_d)
		# Korpus
		_rect(img, 7, 33, 50, 24, OUTLINE)
		_rect(img, 10, 36, 44, 18, steel)

	var body_y: int = 36
	var body_h: int = 17 if open else 18
	# Zwei Quer-Rippen
	_rect(img, 10, body_y + 5, 44, 2, steel_d)
	_rect(img, 10, body_y + 11, 44, 2, steel_d)
	# Nieten in den Ecken (keine "Augen"-Reihe)
	for pos in [[13, body_y + 2], [50, body_y + 2], [13, body_y + 15], [50, body_y + 15]]:
		_px(img, int(pos[0]), int(pos[1]), steel_l)
		_px(img, int(pos[0]) + 1, int(pos[1]) + 1, steel_d)
	# Schloss mittig
	_rect(img, 26, body_y - 1, 12, 11, OUTLINE)
	_rect(img, 27, body_y, 10, 9, steel_l)
	_rect(img, 27, body_y, 10, 2, steel_d)
	_rect(img, 31, body_y + 3, 3, 5, steel_d)
	if not open:
		# Sichtfenster im Korpus (unter dem Schloss, mittig)
		_rect(img, 26, body_y + 6, 12, 7, OUTLINE)
		_rect(img, 28, body_y + 7, 8, 5, blue)
		_rect(img, 30, body_y + 8, 3, 2, Color(0.85, 0.97, 1.0))


# ---------------------------------------------------------------- Premium/Gold
static func _chest_gold(img: Image, open: bool) -> void:
	var purple := Color(0.30, 0.18, 0.42)
	var purple_l := Color(0.44, 0.28, 0.58)
	var purple_d := Color(0.18, 0.10, 0.26)
	var gem := Color(0.62, 0.90, 1.0)
	var gem_d := Color(0.28, 0.60, 0.92)

	_ellipse(img, 32, 58, 26, 4, Color(0, 0, 0, 0.38), true)

	if open:
		_draw_open(img, purple_l, purple, [7, 34, 50, 22], Color(0.10, 0.05, 0.12))
		_rect(img, 7, 34, 50, 22, OUTLINE)
		_rect(img, 10, 37, 44, 16, purple)
		# schwebender Diamant ueber dem Innenraum (gerade Fassung)
		_tri(img, Vector2(32, 25), Vector2(38, 34), Vector2(26, 34), OUTLINE)
		_tri(img, Vector2(32, 27), Vector2(36, 33), Vector2(28, 33), gem)
		_tri(img, Vector2(32, 27), Vector2(34, 33), Vector2(30, 33), Color(0.90, 0.99, 1.0))
	else:
		# Deckel: zwei Stufen mit GERADER Oberkante, Goldleisten statt Zacken
		_rect(img, 12, 18, 40, 16, OUTLINE)
		_rect(img, 14, 20, 36, 12, purple_l)
		_rect(img, 14, 24, 36, 8, purple)
		# Zierleisten (zwei gerade Goldbaender)
		_rect(img, 14, 20, 36, 2, GOLD)
		_rect(img, 14, 29, 36, 2, GOLD_D)
		# Korpus
		_rect(img, 7, 33, 50, 24, OUTLINE)
		_rect(img, 10, 36, 44, 18, purple)

	var body_y: int = 36
	var body_h: int = 17 if open else 18
	# Goldbaender + Bodenleiste
	for bx in [15, 44]:
		_rect(img, bx, body_y, 5, body_h, OUTLINE)
		_rect(img, bx + 1, body_y, 3, body_h - 1, GOLD)
	_rect(img, 10, body_y + body_h - 5, 44, 4, OUTLINE)
	_rect(img, 10, body_y + body_h - 4, 44, 2, GOLD_D)
	# Schloss mittig mit Edelstein
	_rect(img, 26, body_y - 1, 12, 12, OUTLINE)
	_rect(img, 27, body_y, 10, 10, GOLD)
	_rect(img, 28, body_y + 1, 8, 8, GOLD_D)
	# Edelstein (Raute) im Schloss
	_tri(img, Vector2(32, body_y + 2), Vector2(36, body_y + 5), Vector2(28, body_y + 5), gem)
	_tri(img, Vector2(32, body_y + 8), Vector2(36, body_y + 5), Vector2(28, body_y + 5), gem_d)
	_px(img, 31, body_y + 4, Color(0.95, 1.0, 1.0))


# v1.48 (C2): Messung "keine Farbspitzen ueber der Deckellinie".
# Zaehlt Spalten, die mehr als 2 px ueber ihre beiden Nachbarspalten hinausragen.
static func kanten_spitzen(img: Image) -> int:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var tops: Array = []
	for x in range(w):
		var top: int = -1
		for y in range(h):
			if img.get_pixel(x, y).a > 0.2:
				top = y
				break
		tops.append(top)
	var spitzen: int = 0
	for x in range(1, w - 1):
		var t0: int = int(tops[x - 1])
		var t1: int = int(tops[x])
		var t2: int = int(tops[x + 1])
		if t1 < 0 or t0 < 0 or t2 < 0:
			continue
		if t0 - t1 >= 3 and t2 - t1 >= 3:
			spitzen += 1
	return spitzen


static func _crop_center(img: Image, ziel: int) -> Image:
	var x0: int = img.get_width()
	var y0: int = img.get_height()
	var x1: int = -1
	var y1: int = -1
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.02:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return img
	x0 = maxi(0, x0 - 1)
	y0 = maxi(0, y0 - 1)
	x1 = mini(img.get_width() - 1, x1 + 1)
	y1 = mini(img.get_height() - 1, y1 + 1)
	var w: int = x1 - x0 + 1
	var h: int = y1 - y0 + 1
	var side: int = maxi(w, h)
	var out := Image.create(side, side, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ox: int = int((side - w) * 0.5)
	var oy: int = int((side - h) * 0.5)
	out.blit_rect(img, Rect2i(x0, y0, w, h), Vector2i(ox, oy))
	if side > ziel:
		out.resize(ziel, ziel, Image.INTERPOLATE_NEAREST)
	return out
