class_name GenChests
extends TexDraw


static func bw_inset(cx: float, bw: float, y: float) -> float:
	# Korpus verjuengt sich nach unten leicht -> Breitenfunktion
	return bw * (0.97 - 0.04 * clampf((y - cx * 0.8) / 400.0, 0.0, 1.0))


static func _make_chest_gold_icon() -> ImageTexture:
	# Runde 48: Goldtruhe - der PRESTIGE-Schrank: wulstiger Deckel,
	# Doppelband, leuchtender Edelstein auf dem Schloss.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.24, 0.15, 0.03)
	var gold := Color(0.98, 0.79, 0.24)
	var gold2 := Color(0.74, 0.54, 0.10)
	var gold3 := Color(1.0, 0.92, 0.52)
	var gem := Color(0.35, 0.85, 0.95)
	# Wulst-Deckel (oben gewolbt)
	for y in range(4, 12):
		var bulge: int = 0
		if y < 6:
			bulge = 1
		for x in range(2 - bulge, 22 + bulge):
			img.set_pixel(x, y, gold3 if y < 7 else gold)
	# Deckel-Fuge
	for x in range(2, 22):
		img.set_pixel(x, 11, gold2)
	# Korpus
	for y in range(12, 21):
		for x in range(2, 22):
			img.set_pixel(x, y, gold if y < 18 else gold2)
	# Doppelband
	for x in range(2, 22):
		img.set_pixel(x, 14, gold2)
		img.set_pixel(x, 15, gold3)
	# Vertikale Zierbaender
	for x in [5, 6, 17, 18]:
		for y in range(4, 21):
			img.set_pixel(x, y, gold2 if x in [5, 17] else gold3)
	# GROSSER Edelstein im Schloss
	for y in range(9, 15):
		for x in range(9, 14):
			var edge: bool = (x == 9 or x == 13 or y == 9 or y == 14)
			img.set_pixel(x, y, gold2 if edge else gem)
	img.set_pixel(10, 11, Color(1, 1, 1, 0.75))
	# Goldener Wulst oben
	for x in range(8, 16):
		img.set_pixel(x, 3, dark)
	for x in range(9, 15):
		img.set_pixel(x, 2, gold3)
	# Glanzlicht
	img.set_pixel(7, 7, Color(1, 1, 1, 0.55))
	img.set_pixel(8, 7, Color(1, 1, 1, 0.30))
	img.set_pixel(3, 17, Color(1, 1, 1, 0.22))
	# Fuesse
	for x in range(3, 21):
		img.set_pixel(x, 21, dark)
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


static func _make_chest_silver_icon() -> ImageTexture:
	# Runde 48: Silberkiste - ein INDUSTRIE-Design: eckige Kiste mit
	# Nietenreihen, Warnstreifen und einem Gitterdeckel.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.10, 0.11, 0.15)
	var steel := Color(0.78, 0.82, 0.88)
	var steel2 := Color(0.52, 0.57, 0.66)
	var steel3 := Color(0.92, 0.95, 1.0)
	var warn := Color(0.98, 0.76, 0.20)
	# Deckel (flach, industriell)
	for y in range(4, 11):
		for x in range(2, 22):
			img.set_pixel(x, y, steel3 if y < 6 else steel)
	# Runde 49: KEIN Gitter mehr - zwei dunkle Felder auf dem Deckel
	# lasen sich als Augen, das Sprite bekam ein Gesicht. Stattdessen
	# eine einzelne Deckelkante und Nieten an den Ecken.
	for y in [9]:
		for x in range(2, 22):
			img.set_pixel(x, y, steel2)
	for nx in [4, 19]:
		for ny in [6, 8]:
			img.set_pixel(nx, ny, steel2)
	# Warndreieck als Erkennungsmerkmal in der Mitte des Deckels
	_tri(img, Vector2(9, 4), Vector2(12, 8), Vector2(15, 4), warn)
	_tri(img, Vector2(10, 5), Vector2(12, 7), Vector2(14, 5), Color(0.20, 0.22, 0.28))
	# Korpus
	for y in range(11, 21):
		for x in range(2, 22):
			img.set_pixel(x, y, steel if y < 17 else steel2)
	# Untere Haelfte leicht aufhellen - das dunkle Band las sich
	# sonst als Mund hoehle
	for y in range(17, 21):
		for x in range(2, 22):
			if img.get_pixel(x, y) == steel2:
				img.set_pixel(x, y, steel2.lightened(0.14))
	# Warnstreifen
	for x in range(2, 22):
		img.set_pixel(x, 15, warn)
		img.set_pixel(x, 16, warn.darkened(0.25))
	# Runde 49: KEINE durchlaufende Nietenreihe mehr. Die helle
	# Punktereihe ueber dem dunklen Band las sich als Zaehne in einem
	# Mund - die Kiste bekam ein Gesicht. Jetzt nur noch VIER Nieten
	# an den Ecken, das Band dazwischen bleibt einfarbig.
	for nx in [4, 19]:
		img.set_pixel(nx, 12, steel3)
		img.set_pixel(nx, 13, steel2.darkened(0.20))
		img.set_pixel(nx, 18, steel3)
		img.set_pixel(nx, 19, steel2.darkened(0.20))
	# Ecken-Winkel (Rahmen) statt Scharnier-Felder
	for x in [3, 18]:
		for y in [11, 12, 18, 19]:
			img.set_pixel(x, y, steel2.darkened(0.25))
	# Runde 49: EIN zentrales Schloss statt zwei Haetten. Die zwei
	# Haetten mit ihren dunklen Pixeln bildeten Augen mit Pupillen -
	# die Kiste bekam ein Gesicht und las als Wesen, nicht als Kiste.
	for y in range(12, 17):
		for x in range(10, 14):
			img.set_pixel(x, y, steel2)
	for y in range(13, 16):
		for x in range(11, 13):
			img.set_pixel(x, y, steel3)
	img.set_pixel(11, 15, dark)
	img.set_pixel(12, 15, dark)
	# Griff oben
	for x in range(10, 14):
		img.set_pixel(x, 2, dark)
	for x in range(11, 13):
		img.set_pixel(x, 3, steel3)
	# Glanz
	img.set_pixel(4, 6, Color(1, 1, 1, 0.45))
	img.set_pixel(5, 6, Color(1, 1, 1, 0.20))
	img.set_pixel(3, 13, Color(1, 1, 1, 0.18))
	# Fuesse
	for x in range(3, 21):
		img.set_pixel(x, 21, dark)
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


static func _make_chest_wood_icon() -> ImageTexture:
	# Runde 48: Holztruhe - waermere Farbtöne als Basis, sichtbare
	# Plankenfugen, ein Eisenband und ein Wulst am Deckel.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.13, 0.08, 0.05)
	var body := Color(0.72, 0.47, 0.24)
	var body2 := Color(0.60, 0.38, 0.19)
	var body3 := Color(0.82, 0.58, 0.31)
	var iron := Color(0.36, 0.38, 0.44)
	var iron_l := Color(0.56, 0.59, 0.66)
	# --- Deckel (schraeg, gewollt) ---
	for y in range(5, 12):
		for x in range(2, 18):
			img.set_pixel(x, y, body3 if y < 8 else body)
	for y in range(3, 7):
		for x in range(4, 17):
			img.set_pixel(x, y, body3.lightened(0.10))
	# --- Korpus ---
	for y in range(12, 21):
		for x in range(2, 18):
			img.set_pixel(x, y, body if y < 18 else body2)
	# Seiten-Schatten
	for y in range(9, 19):
		for x in range(18, 22):
			img.set_pixel(x, y, body2.darkened(0.18))
	# Plankenfugen (waagerecht)
	for yy in [14, 17]:
		for x in range(2, 18):
			img.set_pixel(x, yy, body2.darkened(0.30))
	# Eisenband quer
	for x in range(2, 22):
		img.set_pixel(x, 12, iron)
		img.set_pixel(x, 13, iron_l)
	# Vertikale Eisenbaender
	for x in [5, 6, 15, 16]:
		for y in range(6, 21):
			img.set_pixel(x, y, iron if x in [5, 15] else iron_l)
	# Schloss
	for y in range(11, 16):
		img.set_pixel(10, y, Color(0.98, 0.84, 0.28))
		img.set_pixel(11, y, Color(0.98, 0.84, 0.28))
	img.set_pixel(10, 13, dark)
	img.set_pixel(11, 13, dark)
	img.set_pixel(9, 11, dark)
	img.set_pixel(12, 11, dark)
	img.set_pixel(9, 15, dark)
	img.set_pixel(12, 15, dark)
	# Griff
	for x in range(9, 13):
		img.set_pixel(x, 2, dark)
	img.set_pixel(9, 3, iron)
	img.set_pixel(12, 3, iron)
	# Glanzlicht
	img.set_pixel(7, 7, Color(1, 1, 1, 0.40))
	img.set_pixel(8, 7, Color(1, 1, 1, 0.22))
	img.set_pixel(3, 16, Color(1, 1, 1, 0.14))
	# Fuesse
	for x in range(3, 17):
		img.set_pixel(x, 21, dark)
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


static func _make_chest_storm_icon() -> ImageTexture:
	# Runde 49: STURMKISTE - eine flache, breite WAFFENKISTE mit
	# Stangen oben drauf und einem Blitzzeichen auf dem Deckel.
	# Eigenes Silhouettenprofil (flach und breit statt hoch).
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.07, 0.10, 0.16)
	var steel := Color(0.26, 0.56, 0.84)
	var steel2 := Color(0.17, 0.38, 0.62)
	var steel3 := Color(0.40, 0.72, 0.98)
	var bolt := Color(0.98, 0.94, 0.42)
	# --- Stangen (Sturm-Fangzaehne) oben ---
	for x in [6, 8, 15, 17]:
		_px_rect(img, x, 2, 2, 5, steel2)
		img.set_pixel(x, 1, bolt)
	# --- Flacher Deckel ---
	_px_up(img, 2, 7, 20, 5, steel3)
	_px_rect(img, 2, 11, 20, 1, steel2)
	# --- Breiter, flacher Korpus ---
	_px_rect(img, 3, 12, 18, 8, steel)
	_px_rect(img, 3, 12, 3, 8, steel2)
	_px_rect(img, 18, 12, 3, 8, steel2.darkened(0.10))
	# --- Warnstreifen ---
	for x in range(3, 21):
		if (x + 12) % 6 < 3:
			img.set_pixel(x, 15, bolt)
	# --- Blitzzeichen auf dem Deckel ---
	var bz := [Vector2i(12, 7), Vector2i(10, 9), Vector2i(12, 9), Vector2i(10, 12)]
	for p in bz:
		img.set_pixel(p.x, p.y, bolt)
	img.set_pixel(11, 8, bolt)
	img.set_pixel(11, 10, bolt)
	# --- Schloss ---
	_px_rect(img, 10, 16, 4, 4, steel2)
	_px_rect(img, 11, 17, 2, 2, bolt)
	# --- Fuesse ---
	_px_rect(img, 3, 20, 4, 2, dark)
	_px_rect(img, 17, 20, 4, 2, dark)
	# Glanz
	img.set_pixel(5, 8, Color(1, 1, 1, 0.40))
	img.set_pixel(6, 8, Color(1, 1, 1, 0.18))
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


static func _make_chest_platinum_icon() -> ImageTexture:
	# Runde 49: KRISTALL-TRUHE - eine schlanke, hohe Truhe mit einem
	# leuchtenden Spalt in der Mitte (darin ein Kristall). Eigenes
	# Silhouettenprofil, nicht die Standard-Truhenform.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.12, 0.10, 0.20)
	var shell := Color(0.84, 0.88, 0.96)
	var shell2 := Color(0.62, 0.66, 0.80)
	var glow := Color(0.70, 0.42, 1.0)
	var glow_l := Color(0.92, 0.76, 1.0)
	# --- Facettierter Kristall, der aus dem Deckel SPITZT ---
	# (Runde 49: vorher war es eine zusaetzliche Spitze ueber dem
	# Deckel - das las sich als Grabstein, nicht als Truhe.)
	_tri(img, Vector2(9, 8), Vector2(12, 1), Vector2(15, 8), OUTLINE)
	_tri(img, Vector2(10, 8), Vector2(12, 3), Vector2(14, 8), glow)
	_px(img, 12, 5, glow_l)
	# --- Deckel (flach, breit) ---
	_px_up(img, 6, 8, 12, 3, shell)
	_px_rect(img, 6, 10, 12, 1, shell2)
	# --- Korpus ---
	_px_rect(img, 5, 11, 14, 10, shell)
	# Seiten-Schatten
	_px_rect(img, 5, 11, 3, 10, shell2)
	_px_rect(img, 16, 11, 3, 10, shell2.darkened(0.12))
	# --- Leuchtender Spalt in der Mitte ---
	_px_rect(img, 10, 11, 4, 10, glow)
	_px_rect(img, 11, 12, 2, 8, glow_l)
	# --- Rahmenkanten ---
	_px_rect(img, 4, 11, 1, 10, dark)
	_px_rect(img, 19, 11, 1, 10, dark)
	# --- Fussleiste ---
	_px_rect(img, 4, 20, 16, 2, shell2)
	_px_rect(img, 4, 21, 16, 1, dark)
	# Glanzlichter
	img.set_pixel(7, 13, Color(1, 1, 1, 0.45))
	img.set_pixel(8, 13, Color(1, 1, 1, 0.22))
	img.set_pixel(17, 17, Color(1, 1, 1, 0.20))
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


static func _make_chest_icon(body: Color, band: Color) -> ImageTexture:
	# Runde 43: KISTENKÖRPER in 3/4-Ansicht, Pixel-Art (24x24, 3x NEAREST).
	# Vorher war es ein flaches 16x16-Icon - der Nutzer fand die Kisten
	# "nicht special" und ohne Oeffnungs-Animation.
	var px: int = 24
	var big: int = 3
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var dark := Color(0.09, 0.07, 0.06)
	var shade := body.darkened(0.34)
	var bshade := band.darkened(0.26)
	var highlight := body.lightened(0.22)
	# --- Korpus (3/4-Ansicht: Front + rechte Seite) ---
	# Front: x 3..16, y 12..20 ; Seite: x 16..20, y 10..18
	for y in range(12, 21):
		for x in range(3, 17):
			small.set_pixel(x, y, body if y < 18 else shade)
	for y in range(10, 19):
		for x in range(16, 21):
			small.set_pixel(x, y, shade)
	# Front-Planken
	for y in range(15, 21):
		for x in range(3, 17):
			small.set_pixel(x, y, shade if (y == 15 or y == 18) else body)
	# --- Deckel (schraeg nach hinten oben) ---
	for y in range(6, 13):
		for x in range(3, 17):
			small.set_pixel(x, y, band)
	for y in range(4, 7):
		for x in range(5, 16):
			small.set_pixel(x, y, band.lightened(0.10))
	# Deckel-Oberkante (3/4)
	for x in range(16, 21):
		for y in range(3, 11):
			small.set_pixel(x, y, bshade)
	# --- Metallbaender ---
	for y in range(6, 21):
		small.set_pixel(6, y, bshade)
		small.set_pixel(7, y, band.lightened(0.18))
		small.set_pixel(14, y, bshade)
		small.set_pixel(15, y, band.lightened(0.18))
	# Band quer ueber den Deckel
	for x in range(3, 21):
		if x < 16:
			small.set_pixel(x, 11, bshade)
		else:
			small.set_pixel(x, 9, bshade)
	# --- Schloss ---
	for y in range(10, 15):
		small.set_pixel(10, y, Color(0.98, 0.85, 0.30))
		small.set_pixel(11, y, Color(0.98, 0.85, 0.30))
	small.set_pixel(10, 12, dark)
	small.set_pixel(11, 12, dark)
	small.set_pixel(10, 13, dark)
	small.set_pixel(11, 13, dark)
	# Schloss-Rahmen
	small.set_pixel(9, 10, dark)
	small.set_pixel(12, 10, dark)
	small.set_pixel(9, 14, dark)
	small.set_pixel(12, 14, dark)
	# --- Griff oben ---
	small.set_pixel(9, 2, dark)
	small.set_pixel(10, 2, dark)
	small.set_pixel(11, 2, dark)
	small.set_pixel(12, 2, dark)
	small.set_pixel(9, 3, dark)
	small.set_pixel(12, 3, dark)
	small.set_pixel(10, 3, band.lightened(0.30))
	small.set_pixel(11, 3, band.lightened(0.30))
	# --- Niete ---
	small.set_pixel(4, 13, band.lightened(0.35))
	small.set_pixel(4, 19, band.lightened(0.30))
	small.set_pixel(13, 13, band.lightened(0.35))
	small.set_pixel(13, 19, band.lightened(0.30))
	small.set_pixel(17, 11, band.lightened(0.25))
	small.set_pixel(17, 17, band.lightened(0.22))
	# --- Glanzlicht auf dem Deckel ---
	small.set_pixel(8, 7, Color(1, 1, 1, 0.42))
	small.set_pixel(9, 7, Color(1, 1, 1, 0.28))
	small.set_pixel(12, 16, Color(1, 1, 1, 0.16))
	# Fuss
	for x in range(4, 16):
		small.set_pixel(x, 21, dark)
	# Kontur ringsum
	_px_outline(small, px, dark)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


static func _make_chest() -> ImageTexture:
	# Runde 49: Klassische Truhe mit klarer Silhouette - gewoelbter
	# Deckel, sichtbarer Deckelspalt, zwei Eisenbaender, ein Schloss
	# mit Schluesselbart und vier Fuessen. Vorher war es ein flacher
	# brauner Topf, der als "dumpfer Kasten" las.
	var img = _new_img(48, 48)
	var wood := Color(0.62, 0.40, 0.21)
	var wood_lit := Color(0.76, 0.52, 0.29)
	var wood_dark := Color(0.44, 0.26, 0.13)
	var iron := Color(0.44, 0.46, 0.52)
	var iron_l := Color(0.64, 0.67, 0.74)
	var gold := Color(0.96, 0.80, 0.26)
	_ellipse(img, 24, 43, 19, 4, SHADOW, true)
	# --- Korpus (leicht trapezfoermig: unten breiter) ---
	_rect(img, 6, 22, 36, 18, OUTLINE)
	_rect(img, 8, 23, 32, 16, wood)
	# Seiten-Schatten rechts
	_rect(img, 34, 23, 6, 16, wood_dark)
	# --- Deckel: gewoelbt, mit Spalt zum Korpus ---
	_ellipse(img, 24, 22, 18, 8, OUTLINE)
	_ellipse(img, 24, 21, 16, 6, wood_lit)
	# Deckelspalt (dunkle Linie zwischen Deckel und Korpus)
	_rect(img, 7, 21, 34, 2, OUTLINE)
	# Deckel-Front
	_rect(img, 8, 22, 32, 2, wood)
	# --- Zwei Eisenbaender quer ueber Deckel und Korpus ---
	for bx in [11, 33]:
		_rect(img, bx, 14, 4, 26, OUTLINE)
		_rect(img, bx + 1, 15, 2, 24, iron)
		_rect(img, bx + 1, 15, 1, 24, iron_l)
	# --- Schloss in der Mitte ---
	_rect(img, 20, 25, 8, 9, OUTLINE)
	_rect(img, 21, 26, 6, 7, iron)
	_rect(img, 22, 27, 4, 5, gold)
	_px(img, 23, 29, OUTLINE)
	_px(img, 23, 30, OUTLINE)
	# Schluesselbart
	_rect(img, 22, 32, 3, 3, gold)
	_px(img, 24, 34, gold)
	# --- Eckbeschlaege ---
	for ex in [6, 40]:
		_rect(img, ex, 22, 2, 18, iron)
	# --- Plankenfugen ---
	for yy in [27, 32, 36]:
		for lx in range(8, 34):
			_px(img, lx, yy, wood_dark)
	# --- Fuesse ---
	_rect(img, 8, 40, 5, 3, OUTLINE)
	_rect(img, 35, 40, 5, 3, OUTLINE)
	# --- Glanzlichter ---
	_rect(img, 17, 17, 4, 1, Color(1, 1, 1, 0.30))
	_rect(img, 18, 16, 2, 1, Color(1, 1, 1, 0.45))
	_px(img, 10, 29, Color(1, 1, 1, 0.16))
	return ImageTexture.create_from_image(img)


static func _make_chest_spikes(tier: String, size: int) -> ImageTexture:
	# Runde 141 (D1): Strahlen/Spitzen der geoeffneten Kiste - eigene Textur,
	# eigener Ursprung (Mitte/62 % Hoehe), flach im Comic-Stil mit Kontur.
	# Wird in chest_ui.gd als eigene Ebene HINTER der Kiste gezeigt, damit
	# nichts in die Kiste ragt und sich beim Oeffnen nichts verschiebt.
	var col := Color(0.78, 0.42, 0.96)
	var hi := Color(0.95, 0.86, 1.0)
	match tier:
		"standard":
			col = Color(0.52, 0.78, 1.0)
			hi = Color(0.90, 0.97, 1.0)
		"silver":
			col = Color(0.48, 0.94, 0.66)
			hi = Color(0.90, 1.0, 0.94)
	# v1.43 (S6.2): Kantenglaettung kostete bei 256 px und 16 Abtastungen je
	# Pixel ueber 2 s pro Frame. Jetzt: doppelt so gross zeichnen (harte Kanten,
	# schnell) und am Ende per LANCZOS herunterskalieren - gleiche Wirkung.
	var ss: int = 2
	var inner: int = size * ss
	_aa = false
	var img = _new_img(inner, inner)
	var f := float(inner)
	var cx := f * 0.5
	var cy := f * 0.62
	var ctr := Vector2(cx, cy)
	var outline := Color(0.05, 0.03, 0.08, 1.0)
	var angles := [-158.0, -126.0, -90.0, -54.0, -22.0]
	var i := 0
	for a in angles:
		var rad: float = deg_to_rad(a)
		var dir := Vector2(cos(rad), sin(rad))
		var nrm := Vector2(-dir.y, dir.x)
		var ln: float = f * (0.42 if i % 2 == 0 else 0.33)
		var wd: float = f * (0.062 if i % 2 == 0 else 0.045)
		var tip: Vector2 = ctr + dir * ln
		var b0: Vector2 = ctr + nrm * wd
		var b1: Vector2 = ctr - nrm * wd
		var o: float = f * 0.011
		# Kontur zuerst, Fuellung darauf
		_tri(img, tip + dir * o, b0 + nrm * o, b1 - nrm * o, outline)
		_tri(img, tip, b0, b1, col)
		# heller Kern
		var tip2: Vector2 = ctr + dir * (ln * 0.72)
		_tri(img, tip2, ctr.lerp(b0, 0.55), ctr.lerp(b1, 0.55), hi)
		i += 1
	_aa = false
	_aa_n = 4
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	print("[CHEST][SPIKES] Textur gezeichnet stufe=%s (%d Strahlen, %d px)" % [tier, angles.size(), size])
	return ImageTexture.create_from_image(img)


static func _make_run_chest(body: Color, band: Color, gem: Color, spikes: bool) -> ImageTexture:
	# Runde 49: Die IN-GAME-Truhe war ein flacher Block (zwei
	# Rechtecke + ein Kreis) und sah aus wie ein Kistendeckel, nicht
	# wie eine Truhe. Jetzt: gewoelbter Deckel, sichtbarer Deckelspalt,
	# Eisenbaender, ein Schloss mit dem Edelstein und - bei der
	# Epic-Variante - eine Krone aus Stacheln.
	var img = _new_img(64, 64)
	var dark := Color(0.10, 0.08, 0.07)
	var body2 := body.darkened(0.28)
	var body3 := body.lightened(0.18)
	var band2 := band.darkened(0.24)
	var band_l := band.lightened(0.24)
	# --- Schatten ---
	_ellipse(img, 32, 58, 25, 5, SHADOW)
	# --- Korpus ---
	_rect(img, 7, 32, 50, 24, OUTLINE)
	_rect(img, 9, 34, 46, 20, body)
	# Seiten-Schatten
	_rect(img, 45, 34, 10, 20, body2)
	# Boden-Kante
	_rect(img, 9, 50, 46, 4, body2)
	# --- Gewoelbter Deckel (mit Kontur) ---
	_outlined_ellipse(img, 32, 31, 22, 10, body3, 3)
	# Deckelspalt (dunkle Linie)
	_rect(img, 9, 32, 46, 2, OUTLINE)
	# --- Zwei Eisenbaender quer ueber Deckel und Korpus ---
	for bx in [15, 45]:
		_rect(img, bx, 21, 5, 35, OUTLINE)
		_rect(img, bx + 1, 22, 3, 33, band)
		_rect(img, bx + 1, 22, 1, 33, band_l)
	# --- Schloss in der Mitte ---
	_rect(img, 27, 36, 11, 12, OUTLINE)
	_rect(img, 28, 37, 9, 10, band)
	_rect(img, 29, 38, 7, 8, band2)
	# Edelstein im Schloss
	_outlined_disc(img, 32, 42, 6, gem, 2)
	_disc(img, 30, 40, 2, Color(1, 1, 1, 0.9))
	# --- Eckbeschlaege ---
	_rect(img, 7, 32, 3, 24, band2)
	_rect(img, 54, 32, 3, 24, band2)
	# --- Fuesse ---
	_rect(img, 10, 56, 8, 4, OUTLINE)
	_rect(img, 46, 56, 8, 4, OUTLINE)
	# --- Glanzlicht auf dem Deckel ---
	# blend=true, sonst ERSETZT _px den Pixel und das Licht wird ein
	# halbtransparentes Loch im Deckel.
	_ellipse(img, 22, 26, 7, 3, Color(1, 1, 1, 0.30), true)
	# --- v1.48 (C2): statt Zackenkrone eine GERADE Goldleiste auf dem Deckel ---
	if spikes:
		_rect(img, 11, 23, 42, 4, OUTLINE)
		_rect(img, 12, 24, 40, 2, band)
		_rect(img, 12, 24, 40, 1, band_l)
		_disc(img, 32, 25, 3, gem)
		_disc(img, 31, 24, 2, Color(1, 1, 1, 0.9))
		print("[CHEST][KANTE] kiste=run_epic spitzen=0 grund=zacken_entfernt_v148")
	return ImageTexture.create_from_image(img)


static func _make_gem_chest(size: int, tier: String, open_state: bool) -> ImageTexture:
	# Runde 71: Truhen-Silhouette - hoher Korpus, halbrunder Deckel mit
	# Ueberstand, Schloss auf der Naht. Weiche Kanten via Coverage-Sampling.
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var body_l: Color
	var body_m: Color
	var body_d: Color
	var rim_l: Color
	var rim_m: Color
	var rim_d: Color
	var gem_l: Color
	var gem_m: Color
	var gem_d: Color
	match tier:
		"silver":
			body_l = Color(0.80, 0.82, 0.88); body_m = Color(0.60, 0.63, 0.70)
			body_d = Color(0.37, 0.40, 0.48)
			rim_l = Color(0.98, 0.99, 1.0); rim_m = Color(0.74, 0.78, 0.86); rim_d = Color(0.45, 0.48, 0.56)
			gem_l = Color(0.88, 1.0, 0.95); gem_m = Color(0.32, 0.86, 0.60); gem_d = Color(0.10, 0.50, 0.34)
		"premium":
			body_l = Color(0.48, 0.40, 0.68); body_m = Color(0.31, 0.25, 0.50)
			body_d = Color(0.17, 0.13, 0.31)
			rim_l = Color(1.0, 0.92, 0.60); rim_m = Color(0.87, 0.72, 0.33); rim_d = Color(0.50, 0.37, 0.14)
			gem_l = Color(0.96, 0.78, 1.0); gem_m = Color(0.75, 0.40, 0.98); gem_d = Color(0.43, 0.16, 0.66)
		_:
			body_l = Color(0.70, 0.47, 0.25); body_m = Color(0.50, 0.31, 0.16)
			body_d = Color(0.29, 0.17, 0.09)
			rim_l = Color(0.98, 0.89, 0.58); rim_m = Color(0.78, 0.64, 0.29); rim_d = Color(0.45, 0.34, 0.13)
			gem_l = Color(0.80, 0.98, 1.0); gem_m = Color(0.31, 0.73, 0.95); gem_d = Color(0.10, 0.36, 0.58)

	var cx: float = f * 0.5
	var half: float = f * 0.33          # halbe Korpusbreite
	var top: float = f * 0.50           # Deckel-Naht
	var bot: float = f * 0.84

	# Bodenschatten
	_ellipse(img, int(cx), int(bot + f * 0.02), int(half * 1.06), int(f * 0.045), Color(0, 0, 0, 0.28), true)

	# --- Deckel zuerst (Korpus deckt die untere Haelfte spaeter ab) ---
	if not open_state:
		_ellipse(img, int(cx), int(top), int(half * 1.06), int(f * 0.20), OUTLINE)
		_ellipse(img, int(cx), int(top - f * 0.005), int(half * 1.01), int(f * 0.185), body_m)
		_ellipse(img, int(cx), int(top - f * 0.045), int(half * 0.96), int(f * 0.150), body_l)
		# Metallkante entlang der Naht
		_rect(img, int(cx - half * 1.03), int(top - f * 0.018), int(half * 2.06), int(f * 0.030), rim_m)
		_rect(img, int(cx - half * 1.03), int(top - f * 0.018), int(half * 2.06), int(f * 0.010), rim_l)

	# --- Korpus ---
	_rect(img, int(cx - half) - 3, int(top) - 3, int(half * 2.0) + 6, int(bot - top) + 3, OUTLINE)
	_rect(img, int(cx - half), int(top), int(half * 2.0), int(f * 0.10), body_l)
	_rect(img, int(cx - half), int(top + f * 0.10), int(half * 2.0), int(f * 0.16), body_m)
	_rect(img, int(cx - half), int(bot - f * 0.08), int(half * 2.0), int(f * 0.08), body_d)
	# senkrechte Metallbaender
	for bx in [cx - half * 0.52, cx + half * 0.52]:
		_rect(img, int(bx - f * 0.020), int(top), int(f * 0.040), int(bot - top), rim_m)
		_rect(img, int(bx - f * 0.020), int(top), int(f * 0.012), int(bot - top), rim_l)

	# --- Schloss auf der Naht ---
	_rect(img, int(cx - f * 0.055), int(top - f * 0.035), int(f * 0.11), int(f * 0.105), OUTLINE)
	_rect(img, int(cx - f * 0.045), int(top - f * 0.025), int(f * 0.09), int(f * 0.085), rim_m)
	_rect(img, int(cx - f * 0.045), int(top - f * 0.025), int(f * 0.09), int(f * 0.012), rim_l)

	if open_state:
		# Deckel hinten aufgeklappt: schmaler Bogen ueber der Hinterkante
		_ellipse(img, int(cx), int(top - f * 0.10), int(half * 1.02), int(f * 0.075), OUTLINE)
		_ellipse(img, int(cx), int(top - f * 0.105), int(half * 0.97), int(f * 0.062), body_d)
		_ellipse(img, int(cx), int(top - f * 0.115), int(half * 0.80), int(f * 0.040), body_m)
		# Oeffnung + Licht
		_ellipse(img, int(cx), int(top + f * 0.01), int(half * 0.90), int(f * 0.055), Color(0.05, 0.04, 0.08, 1.0), true)
		_ellipse(img, int(cx), int(top + f * 0.015), int(half * 0.74), int(f * 0.040),
			Color(gem_m.r, gem_m.g, gem_m.b, 0.65), true)
		_ellipse(img, int(cx), int(top + f * 0.02), int(half * 0.42), int(f * 0.022), Color(1, 1, 1, 0.30), true)

	# --- Edelstein auf dem Deckel (geschlossen) ---
	if not open_state:
		var gy: float = top - f * 0.115
		var gw: float = f * 0.075
		var gh: float = f * 0.070
		_tri(img, Vector2(cx, gy - gh), Vector2(cx + gw, gy), Vector2(cx - gw, gy), OUTLINE)
		_tri(img, Vector2(cx, gy + gh * 0.55), Vector2(cx + gw, gy), Vector2(cx - gw, gy), OUTLINE)
		_tri(img, Vector2(cx, gy - gh * 0.82), Vector2(cx + gw * 0.80, gy), Vector2(cx - gw * 0.80, gy), gem_m)
		_tri(img, Vector2(cx, gy - gh * 0.82), Vector2(cx, gy), Vector2(cx - gw * 0.80, gy), gem_l)
		_tri(img, Vector2(cx, gy), Vector2(cx + gw * 0.80, gy), Vector2(cx, gy + gh * 0.40), gem_d)
		_disc(img, cx - gw * 0.28, gy - gh * 0.42, f * 0.010, Color(1, 1, 1, 0.95), true)

	_aa = false
	return ImageTexture.create_from_image(img)


static func _make_chest_icon_rich(tier: String) -> ImageTexture:
	# Runde 49: JEDE Kiste hat eine EIGENE SILHOUETTE - nicht nur eine
	# andere Farbe. Vorher teilten sich Holz/Silber/Gold dieselbe
	# Truhenform und Platinum/Storm waren reine Farbvarianten, dadurch
	# sahen alle Kisten gleich aus.
	match tier:
		"wood":
			# HOLZTRUHE: gewölbter Deckel, Planken, Eisenbeschlag
			return _make_chest_wood_icon()
		"silver":
			# INDUSTRIE-CRATE: eckiger Koffer mit Nieten + Warnstreifen
			return _make_chest_silver_icon()
		"gold":
			# SCHATZTRUHE: hoher gewölbter Deckel, Goldschmuck, Rubin
			return _make_chest_gold_icon()
		"platinum":
			# KRISTALL-TRUHE: schlanke Truhe mit leuchtendem Spalt
			return _make_chest_platinum_icon()
		"storm":
			# STURMKISTE: flache Waffenkiste mit Stangen + Blitzzeichen
			return _make_chest_storm_icon()
	return _make_chest_wood_icon()
