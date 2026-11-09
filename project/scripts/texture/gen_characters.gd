class_name GenCharacters
extends TexDraw

# v1.44 (X1): Grundkoerper-Cache. Das Debug-Raster braucht 425 Bilder
# (17 Rigs x 25 Huete). Vorher wurde fuer JEDE Kachel der komplette Koerper
# neu gezeichnet (gemessen 21-26 ms je Bild -> 11-19 s Blockade).
# Jetzt wird der Koerper einmal je (Rig, Farbe) gezeichnet und kopiert; nur
# die Hut-Ebene (ca. 5 ms) entsteht pro Kombination neu.
static var _rig_body_cache: Dictionary = {}
static var _base_body_cache: Dictionary = {}
static var _head_cache: Dictionary = {}        # Kopfform je (Rig, Farbe)
static var _hat_layer_cache: Dictionary = {}   # Hut-Ebene je (Hut, Rig, Kopfform)


static func _draw_hat(img, hat: int) -> void:
	# Eigene Motive zuerst (kein Durchlauf durch die match-Zweige)
	if hat == 10:
		# HALO
		_draw_ring(img, 32.0, 6.0, 9.5, 4.0, Color(1.0, 0.88, 0.35), 2.2)
		_draw_ring(img, 32.0, 6.0, 9.5, 4.0, Color(1.0, 0.97, 0.70), 1.2)
		return
	if hat == 11:
		# ANTENNE
		_thick_line(img, Vector2(28, 20), Vector2(26, 7), 2.0, OUTLINE)
		_thick_line(img, Vector2(36, 20), Vector2(38, 7), 2.0, OUTLINE)
		_disc(img, 26, 6, 2.4, OUTLINE, true)
		_disc(img, 38, 6, 2.4, OUTLINE, true)
		_disc(img, 26, 6, 1.6, Color(1.0, 0.45, 0.35), true)
		_disc(img, 38, 6, 1.6, Color(0.45, 1.0, 0.55), true)
		return
	if hat == 12:
		# KROENCHEN: klein, drei Zacken
		_rect(img, 27, 9, 13, 6, OUTLINE)
		_rect(img, 28, 10, 11, 4, Color(0.99, 0.84, 0.26))
		_tri(img, Vector2(28, 10), Vector2(30, 4), Vector2(32, 10), OUTLINE)
		_tri(img, Vector2(33, 10), Vector2(35, 3), Vector2(37, 10), OUTLINE)
		_tri(img, Vector2(29, 10), Vector2(30, 5), Vector2(31, 10), Color(1.0, 0.92, 0.45))
		_tri(img, Vector2(34, 10), Vector2(35, 4), Vector2(36, 10), Color(1.0, 0.92, 0.45))
		_disc(img, 30, 8, 1.2, Color(0.98, 0.55, 0.75), true)
		return

	# Hut-Overlay - fuer Base-Skin UND alle Skins. Koordinaten gelten fuer den
	# Standardkopf (Mitte x=32, Oberkante y=13); _hat_layer_for() verschiebt
	# und skaliert sie auf die Kopfform des jeweiligen Skins.
	match hat:
		1:
			# KAPPE (v1.55 flacher): die alte Kuppel war 17 px hoch und bedeckte
			# auf jedem Skin die Augen. Jetzt 10 px - passt auf die Stirn.
			_outlined_ellipse(img, 32, 13.5, 8.2, 4.8, Color(0.88, 0.22, 0.20), 2)
			_rect(img, 31, 9, 1, 5, Color(0.64, 0.12, 0.11))
			_outlined_ellipse(img, 37.5, 16.4, 5.0, 1.9, Color(0.72, 0.14, 0.12), 2)
			_disc(img, 32, 8.6, 1.5, Color(0.99, 0.62, 0.55))
		2:
			# COWBOY: Krempe + Krone + Band
			_ellipse(img, 32, 17, 14, 4.0, OUTLINE)
			_ellipse(img, 32, 17, 12, 2.4, Color(0.55, 0.38, 0.18))
			_ellipse(img, 32, 11, 8, 5.5, OUTLINE)
			_ellipse(img, 32, 11, 6, 3.8, Color(0.70, 0.50, 0.25))
			_rect(img, 26, 13, 12, 2, Color(0.35, 0.22, 0.10))
		3:
			# KRONE: Goldreif + drei Zacken + Rubin
			_rect(img, 24, 11, 16, 7, OUTLINE)
			_rect(img, 25, 12, 14, 5, Color(0.98, 0.82, 0.20))
			_tri(img, Vector2(25, 12), Vector2(28, 4), Vector2(31, 12), Color(0.98, 0.82, 0.20))
			_tri(img, Vector2(31, 12), Vector2(34, 3), Vector2(37, 12), Color(0.98, 0.82, 0.20))
			_tri(img, Vector2(36, 12), Vector2(39, 5), Vector2(40, 12), Color(0.98, 0.82, 0.20))
			_disc(img, 34, 14, 1, Color(0.85, 0.20, 0.30))
		4:
			# ZYLINDER: Roehre + rote Binde + Krempe
			_ellipse(img, 32, 17, 11, 3.2, OUTLINE)
			_ellipse(img, 32, 17, 9, 2.0, Color(0.12, 0.12, 0.16))
			_rect(img, 26, 5, 12, 12, OUTLINE)
			_rect(img, 27, 6, 10, 11, Color(0.12, 0.12, 0.16))
			_rect(img, 27, 14, 10, 3, Color(0.85, 0.15, 0.20))
		5:
			# WOLLMUETZE: Kuppel + Rippen + Bommel
			_disc(img, 32, 14, 8.5, OUTLINE)
			_disc(img, 32, 14, 6.5, Color(0.30, 0.62, 0.95))
			_rect(img, 28, 8, 1, 11, Color(0.22, 0.50, 0.80))
			_rect(img, 32, 7, 1, 12, Color(0.22, 0.50, 0.80))
			_rect(img, 36, 9, 1, 10, Color(0.22, 0.50, 0.80))
			_disc(img, 32, 5, 3.4, OUTLINE)
			_disc(img, 32, 5, 2.6, Color(0.96, 0.96, 0.99))
		6:
			# PIRAT: Dreispitz + Knoepfe
			_tri(img, Vector2(32.0, 4.0), Vector2(48.0, 16.0), Vector2(32.0, 12.0), OUTLINE)
			_tri(img, Vector2(32.0, 6.0), Vector2(45.0, 15.0), Vector2(32.0, 13.0), Color(0.18, 0.18, 0.22))
			_tri(img, Vector2(32.0, 4.0), Vector2(16.0, 16.0), Vector2(32.0, 12.0), OUTLINE)
			_tri(img, Vector2(32.0, 6.0), Vector2(19.0, 15.0), Vector2(32.0, 13.0), Color(0.18, 0.18, 0.22))
			_disc(img, 32, 8, 1.8, Color(0.95, 0.95, 0.98))
		7:
			# STROHHUT (v1.39 C6 neu): breite helle Krempe + flache Krone +
			# dunkles Band. Vorher rot wie die Wollmuetze.
			_outlined_ellipse(img, 32, 18, 12.0, 3.0, Color(0.92, 0.80, 0.42), 2)
			_outlined_ellipse(img, 32, 12, 6.0, 4.2, Color(0.86, 0.72, 0.34), 2)
			_rect(img, 27, 14, 11, 2, Color(0.42, 0.26, 0.12))
			for i in range(5):
				_rect(img, 24 + i * 4, 19, 1, 2, Color(0.74, 0.62, 0.28))
		8:
			# WIKINGER-HELM: Kuppe + Hoerner + Nasenschutz
			_ellipse(img, 32, 9, 8, 6, OUTLINE)
			_ellipse(img, 32, 9, 6, 4, Color(0.62, 0.66, 0.74))
			_tri(img, Vector2(25.0, 7.0), Vector2(17.0, 2.0), Vector2(26.0, 3.0), Color(0.92, 0.90, 0.82))
			_tri(img, Vector2(39.0, 7.0), Vector2(47.0, 2.0), Vector2(38.0, 3.0), Color(0.92, 0.90, 0.82))
			_rect(img, 30, 7, 5, 7, Color(0.46, 0.49, 0.56))
		9:
			# STERN: freier Stern mit Glanzpunkt
			_tri(img, Vector2(32, 1), Vector2(38, 13), Vector2(26, 13), Color(1.0, 0.86, 0.28))
			_tri(img, Vector2(32, 17), Vector2(38, 6), Vector2(26, 6), Color(1.0, 0.86, 0.28))
			_rect(img, 29, 4, 6, 10, Color(1.0, 0.86, 0.28))
			_disc(img, 32, 9, 2.2, Color(1.0, 0.98, 0.70), true)
		13:
			# STIRNBAND (v1.55: 2 px tiefer, Knoten statt Pfeil - lag vorher
			# wie ein loser Streifen ueber dem Kopf)
			_rect(img, 22, 17, 20, 5, Color(0.85, 0.20, 0.22))
			_rect(img, 22, 21, 20, 1, Color(0.55, 0.10, 0.12))
			_rect(img, 22, 17, 20, 1, Color(0.98, 0.52, 0.48))
			_tri(img, Vector2(42, 17), Vector2(48, 20), Vector2(42, 23), Color(0.72, 0.14, 0.16))
		14:
			# BRILLE: runde Schutzbrille
			_draw_ring(img, 27.0, 22.0, 4.2, 4.2, OUTLINE, 1.4)
			_draw_ring(img, 37.0, 22.0, 4.2, 4.2, OUTLINE, 1.4)
			_rect(img, 31, 21, 3, 1, OUTLINE)
			_disc(img, 27, 22, 3.0, Color(0.60, 0.85, 1.0, 0.55), true)
			_disc(img, 37, 22, 3.0, Color(0.60, 0.85, 1.0, 0.55), true)
		15:
			# ABZEICHEN: Anstecker am Kragen
			_disc(img, 40, 39, 6.0, Color(0.95, 0.78, 0.20), true)
			_disc(img, 40, 39, 4.4, Color(0.75, 0.15, 0.15), true)
			_tri(img, Vector2(40, 35), Vector2(42, 39), Vector2(38, 39), Color(1.0, 0.88, 0.35))
			_tri(img, Vector2(40, 43), Vector2(42, 39), Vector2(38, 39), Color(1.0, 0.88, 0.35))
		16:
			# RUCKSACK (v1.54: weiter links und breiter - lag hinter dem Koerper
			# und war auf 10 Skins komplett unsichtbar)
			_rect(img, 10, 28, 12, 17, OUTLINE)
			_rect(img, 11, 29, 10, 15, Color(0.38, 0.30, 0.22))
			_rect(img, 12, 32, 8, 2, Color(0.62, 0.52, 0.36))
			_rect(img, 12, 38, 8, 2, Color(0.62, 0.52, 0.36))
		17:
			# HOERNER: zwei Hoerner ohne Helm
			_tri(img, Vector2(26, 12), Vector2(18, 3), Vector2(27, 6), Color(0.94, 0.92, 0.86))
			_tri(img, Vector2(38, 12), Vector2(46, 3), Vector2(37, 6), Color(0.94, 0.92, 0.86))
		18:
			# BLATTKRANZ
			for i in range(7):
				var ang: float = PI * (0.15 + 0.7 * float(i) / 6.0)
				_disc(img, 32.0 + cos(ang) * 11.0, 16.0 - sin(ang) * 4.0, 3.0, [Color(0.30, 0.62, 0.28), Color(0.42, 0.75, 0.34)][i % 2], true)
		19:
			# ELEKTRO-ANTENNE
			_thick_line(img, Vector2(32, 14), Vector2(32, 3), 2.0, OUTLINE)
			_disc(img, 32, 2, 2.6, Color(0.45, 0.90, 1.0), true)
			_disc(img, 32, 2, 1.2, Color(1, 1, 1), true)
		20:
			# KRISTALL-HALO
			for i in range(5):
				var a2: float = TAU * float(i) / 5.0 - PI * 0.5
				_tri(img, Vector2(32.0 + cos(a2) * 10.0, 7.0 + sin(a2) * 5.0),
					Vector2(32.0 + cos(a2 + 0.3) * 10.0, 7.0 + sin(a2 + 0.3) * 5.0),
					Vector2(32.0, 7.0), Color(0.72, 0.55, 1.0))
		21:
			# DROHNE
			_rect(img, 24, 2, 16, 6, OUTLINE)
			_rect(img, 25, 3, 14, 4, Color(0.45, 0.50, 0.58))
			_thick_line(img, Vector2(24, 2), Vector2(30, 2), 1.6, Color(0.85, 0.90, 0.96))
			_thick_line(img, Vector2(34, 2), Vector2(40, 2), 1.6, Color(0.85, 0.90, 0.96))
			_disc(img, 32, 5, 1.8, Color(1.0, 0.35, 0.30), true)
		22:
			# SCHULTERPLATTEN
			_rect(img, 15, 36, 11, 7, OUTLINE)
			_rect(img, 16, 37, 9, 5, Color(0.55, 0.60, 0.70))
			_rect(img, 38, 36, 11, 7, OUTLINE)
			_rect(img, 39, 37, 9, 5, Color(0.55, 0.60, 0.70))
		23:
			# STERNEN-HALO
			_draw_ring(img, 32.0, 6.0, 9.5, 4.0, Color(1.0, 0.90, 0.55), 1.8)
			for i in range(6):
				var a3: float = TAU * float(i) / 6.0
				_disc(img, 32.0 + cos(a3) * 9.5, 6.0 + sin(a3) * 3.2, 1.4, Color(1, 1, 1), true)
		24:
			# STERNCHEN
			for i in range(3):
				var px: float = 20.0 + float(i) * 12.0
				var py: float = 4.0 + float(i % 2) * 6.0
				_tri(img, Vector2(px, py), Vector2(px + 2, py + 6), Vector2(px - 2, py + 6), Color(1.0, 0.92, 0.45))
				_tri(img, Vector2(px, py + 12), Vector2(px + 2, py + 6), Vector2(px - 2, py + 6), Color(1.0, 0.92, 0.45))


static func _make_player(shirt := Color(0.20, 0.60, 1.0), pants := Color(0.15, 0.25, 0.55), hat: int = 0) -> ImageTexture:
	_aa = true
	var img: Image = _base_body(shirt, pants)
	_draw_hat(img, hat)
	_aa = false
	return ImageTexture.create_from_image(img)


# v1.44 (X1): Grundkoerper des Standardskins ohne Hut - einmal je Farbpaar.
static func _base_body(shirt: Color, pants: Color) -> Image:
	var key := "%d_%d" % [shirt.to_rgba32(), pants.to_rgba32()]
	if _base_body_cache.has(key):
		return (_base_body_cache[key] as Image).duplicate()
	_aa = true
	var img = _new_img(64, 64)
	var skin := Color(0.95, 0.75, 0.55)
	var hair := Color(0.45, 0.25, 0.10)
	var gun := Color(0.25, 0.25, 0.30)

	# Schatten
	_ellipse(img, 32, 54, 18, 5, SHADOW, true)
	# Beine
	_outlined_ellipse(img, 26, 46, 4, 8, pants, 2)
	_outlined_ellipse(img, 38, 46, 4, 8, pants, 2)
	# Gewehrlauf nach rechts
	_rect(img, 40, 28, 20, 8, OUTLINE)
	_rect(img, 41, 29, 18, 6, gun)
	_rect(img, 55, 27, 5, 10, OUTLINE)
	_rect(img, 56, 28, 3, 8, gun)
	# Oberkörper
	_outlined_ellipse(img, 32, 36, 12, 14, shirt, 3)
	# Gürtel
	_rect(img, 21, 44, 22, 3, Color(0.35, 0.22, 0.10))
	# Arme
	_outlined_disc(img, 20, 34, 5, skin, 2)
	_outlined_disc(img, 44, 32, 5, skin, 2)
	# Kopf: Haut + Haar-Deckel (Top-Down), Gesicht nach rechts
	_outlined_disc(img, 32, 22, 9, skin, 2)
	_disc(img, 32, 20, 9, hair)
	_ellipse(img, 36, 25, 5, 4, skin)
	# Augenpunkte
	_px(img, 37, 24, OUTLINE)
	_px(img, 40, 24, OUTLINE)
	_base_body_cache[key] = img.duplicate()
	return img


static func _center_run(img: Image, y: int, cx_guess: int) -> Vector3:
	# Zusammenhaengender Alpha-Lauf, der der Mittelachse am naechsten liegt.
	if y < 0 or y >= img.get_height():
		return Vector3(0, 0, 0)
	var best := Vector3(0, 0, 0)
	var best_d: int = 9999
	var x0: int = -1
	var x: int = 0
	while x <= img.get_width():
		var solid: bool = x < img.get_width() and img.get_pixel(x, y).a > 0.5
		if solid and x0 < 0:
			x0 = x
		elif not solid and x0 >= 0:
			var x1: int = x - 1
			var mitte: int = int((x0 + x1) / 2)
			var d: int = absi(mitte - cx_guess)
			if d < best_d:
				best_d = d
				best = Vector3(float(x0), float(x1), float(x1 - x0 + 1))
			x0 = -1
		x += 1
	return best


static func _head_metrics(img: Image) -> Dictionary:
	# v1.39 C7: Kopflogik aus dem GEZEICHNETEN Bild ableiten. Gesucht wird der
	# zusammenhaengende Lauf um die Mittelachse, der mindestens 12 px breit ist
	# und es auch in den zwei Zeilen darunter bleibt - damit fallen Antennen,
	# Hoernerspitzen und Drohnen oben nicht als "Kopf" durch.
	var w: int = img.get_width()
	var h: int = img.get_height()
	var cx_guess: int = int(w / 2)
	var top: int = -1
	for y in range(h - 2):
		var r: Vector3 = _center_run(img, y, cx_guess)
		if int(r.z) < 12:
			continue
		var r1: Vector3 = _center_run(img, y + 1, cx_guess)
		var r2: Vector3 = _center_run(img, y + 2, cx_guess)
		if int(r1.z) >= 12 and int(r2.z) >= 12:
			top = y
			break
	if top < 0:
		return { "top": 21.0, "cx": 32.0, "w": 18.0, "links": 23.0, "rechts": 41.0 }
	# Kopfbreite = breitester Mittellauf in den ersten 9 Zeilen unter der Oberkante
	var best: Vector3 = Vector3(23, 41, 19)
	for y in range(top, mini(h, top + 9)):
		var r: Vector3 = _center_run(img, y, cx_guess)
		if int(r.z) > int(best.z):
			best = r
	# v1.46 (F2): Augenband aus dem GEZEICHNETEN Bild messen (weisse Augapfel-
	# Pixel im Kopfbereich, mindestens 2 px breit - damit fallen einzelne
	# Glanzpunkte und Helmdetails heraus). Der Hut wird daran gehindert, es
	# zu ueberdecken.
	var eyes: Array = eye_pixels(img, { "top": float(top), "links": best.x, "rechts": best.y })
	var eye_top: int = -1
	var eye_bot: int = -1
	for ep in eyes:
		var ey: int = int((ep as Vector2i).y)
		if eye_top < 0:
			eye_top = ey
		eye_bot = maxi(eye_bot, ey)
	return {
		"top": float(top),
		"cx": (best.x + best.y) * 0.5,
		"w": float(best.z),
		"links": best.x,
		"rechts": best.y,
		"eye_top": float(eye_top if eye_top >= 0 else top + 8),
		"eye_bot": float(eye_bot if eye_bot >= 0 else top + 8),
		"eye_n": eyes.size(),
		"eye_px": eyes,
	}


# v1.46 (F2): Augenpixel (weisse Augapfel) im Kopfbereich. Zusammenhängende
# Laeufe ab 2 px zaehlen - ein einzelner Glanzpunkt oder ein weisses
# Helm-Detail ist kein Auge.
static func eye_pixels(img: Image, head: Dictionary) -> Array:
	var top: int = int(head.get("top", 13.0))
	var l: int = int(head.get("links", 20)) + 1
	var r: int = int(head.get("rechts", 44))
	var h: int = img.get_height()
	var out: Array = []
	for y in range(top + 1, mini(h, top + 15)):
		var x: int = l
		while x < r:
			var c: Color = img.get_pixel(x, y)
			var weiss: bool = c.a > 0.6 and c.r > 0.86 and c.g > 0.86 and c.b > 0.86
			if not weiss:
				x += 1
				continue
			var start: int = x
			var run: int = 0
			while x < r:
				var c2: Color = img.get_pixel(x, y)
				if c2.a > 0.6 and c2.r > 0.86 and c2.g > 0.86 and c2.b > 0.86:
					run += 1
					x += 1
				else:
					break
			if run >= 2:
				for k in range(run):
					out.append(Vector2i(start + k, y))
	return out


static func _draw_hat_on(img, hat: int, anchor_y: float) -> void:
	var layer := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	layer.fill(Color(0, 0, 0, 0))
	_draw_hat(layer, hat)
	var dy: int = int(round(anchor_y - 21.0))
	if dy == 0:
		img.blend_rect(layer, Rect2i(0, 0, 64, 64), Vector2i(0, 0))
	else:
		print("[HAT][ANCHOR] Hut %d verschoben um %+d px (Kopf bei y=%.0f)" % [hat, dy, anchor_y])
		img.blend_rect(layer, Rect2i(0, 0, 64, 64), Vector2i(0, dy))


# v1.39 C: Der Hut wird an die GEMESSENE Kopfform angepasst (Breite, Mitte,
# Oberkante) statt nur um einen festen y-Wert verschoben.
const NOM_CX := 32.0        # Kopfmitte der Standardfigur
const NOM_TOP := 13.0       # Kopfoberkante der Standardfigur
const NOM_CONTACT := 21.0   # Auflagepunkt des Hutes (Kopf oben + 8)
const NOM_HEAD_W := 25.0    # Kopfbreite der Standardfigur (gemessen, C7)

# v1.39 C3: eigener Sitz je Hut. [Absenkung unter die Kopfoberkante in px,
# Skalierungsfaktor]. Positiv = tiefer auf den Kopf, negativ = schwebt
# absichtlich (Halo, Stern, Drohne).
const HAT_SEAT := {
	1: [9.0, 1.00],    # KAPPE: Schirm auf Stirnhoehe, Haaransatz bedeckt
	2: [8.0, 1.02],    # COWBOY
	3: [6.5, 1.00],    # KRONE
	4: [7.0, 1.00],    # ZYLINDER
	5: [9.5, 1.00],    # WOLLMUETZE: sitzt tief
	6: [6.0, 1.03],    # PIRAT
	7: [7.0, 1.03],    # STROHHUT
	8: [6.0, 1.03],    # WIKINGER-HELM
	9: [4.0, 0.90],    # STERN (schwebt absichtlich)
	10: [0.0, 0.95],   # HALO (schwebt absichtlich)
	11: [8.0, 0.90],   # ANTENNE
	12: [6.5, 0.90],   # KROENCHEN
	13: [12.0, 1.00],  # STIRNBAND (Stirn)
	14: [12.0, 1.00],  # BRILLE (Augenhoehe)
	17: [9.0, 1.03],   # HOERNER (Basis am Kopf)
	18: [8.0, 1.00],   # BLATTKRANZ
	19: [8.0, 1.00],   # ELEKTRO-ANTENNE
	20: [2.0, 1.00],   # KRISTALL-HALO (schwebt)
	21: [1.0, 1.00],   # DROHNE (schwebt)
	23: [2.0, 1.00],   # STERNEN-HALO (schwebt)
	24: [5.0, 1.05],   # STERNCHEN
}
# Diese "Huete" liegen am KOERPER, nicht am Kopf - sie duerfen nicht mitskalieren.
# v1.54: Anstecker (15) und Schulterplatten (22) liegen VOR dem Koerper -
# dahinter waren sie auf breiten Skins komplett unsichtbar. Rucksack (16) bleibt hinten.
const HAT_BODY_ITEMS := [16]

# v1.54: Schwebende Huete bekommen einen FESTEN Sitz (keine Kopf-Skalierung).
const FLOAT_HATS := [9, 10, 20, 21, 23, 24]

# v1.54: Koerperteile (Anstecker, Rucksack, Schulterplatten) werden NICHT auf
# den Kopf gesetzt - sie benutzen ihre absoluten Koordinaten im 64x64-Raster.
# Vorher landeten sie per Kopf-Metrik im Gesicht.
const FIXED_HATS := [15, 16, 22]
# v1.41 (S3): Sitz je Skin nachgemessen - die vier neu gezeichneten Skins
# haben einen kleineren Kopf als der Standard (18-22 statt 25 px), dadurch
# sass der Hut 3-5 px zu hoch. Positiv = tiefer auf den Kopf.
# v1.42 (P13): die sechs neuen Skins (11-16) wurden NACHGEMESSEN (Median-Luecke
# Hutunterkante -> Kopfoberkante ueber alle 21 Kopf-Huete = 0 px). Sie brauchen
# deshalb keine Verschiebung; der Eintrag haelt das Messergebnis fest, damit die
# Tabelle vollstaendig ist und ein spaeterer Kopf-Umbau nicht still durchfaellt.
const RIG_HAT_ADJ := { 7: 4.0, 8: 3.0, 9: 4.0, 10: 4.0,
	11: 0.0, 12: 0.0, 13: 0.0, 14: 0.0, 15: 0.0, 16: 0.0 }


static func _img_top(img: Image) -> int:
	# Oberste Zeile mit deckendem Pixel (ganzes Bild)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.4:
				return y
	return 0


static func _img_top_head(img: Image, cx: float, w: float) -> int:
	# v1.55: Oberkante NUR in der Kopfspalte. Ueber das ganze Bild gemessen
	# lieferten Schwertspitze, Sax oder Stab einen zu hohen Wert - der Hut
	# schwebte dann ueber dem Kopf.
	var x0: int = clampi(int(cx - w * 0.6), 0, 63)
	var x1: int = clampi(int(cx + w * 0.6), 0, 63)
	for y in range(img.get_height()):
		for x in range(x0, x1 + 1):
			if img.get_pixel(x, y).a > 0.4:
				return y
	return _img_top(img)


static func _sample_bilinear(img: Image, u: float, v: float) -> Color:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var x0: int = clampi(int(floor(u)), 0, w - 1)
	var y0: int = clampi(int(floor(v)), 0, h - 1)
	var x1: int = mini(x0 + 1, w - 1)
	var y1: int = mini(y0 + 1, h - 1)
	var fx: float = u - float(x0)
	var fy: float = v - float(y0)
	var c00: Color = img.get_pixel(x0, y0)
	var c10: Color = img.get_pixel(x1, y0)
	var c01: Color = img.get_pixel(x0, y1)
	var c11: Color = img.get_pixel(x1, y1)
	var top: Color = c00.lerp(c10, fx)
	var bot: Color = c01.lerp(c11, fx)
	return top.lerp(bot, fy)


static func _hat_layer_for(hat: int, head: Dictionary, scale_mul: float = 1.0, rig: int = -1) -> Image:
	return _hat_layer_fast(hat, head, scale_mul, rig)


# v1.44 (X1): gleiche Rechnung wie _hat_layer_for_slow, aber ohne get_pixel/
# set_pixel je Bildpunkt. Gemessen: 2,65 ms -> Ziel unter 0,7 ms je Hut-Ebene,
# weil das Debug-Raster 425 Ebenen braucht. Beleg: COMIC_LANTEST=hatcmp144
# vergleicht beide Fassungen Bildpunkt fuer Bildpunkt.
static func _hat_layer_fast(hat: int, head: Dictionary, scale_mul: float = 1.0, rig: int = -1) -> Image:
	var layer := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	layer.fill(Color(0, 0, 0, 0))
	if hat <= 0:
		return layer
	_draw_hat(layer, hat)
	if hat in FIXED_HATS:
		# absolute Position, keine Kopf-Skalierung
		return layer
	if hat in HAT_BODY_ITEMS:
		return layer
	var seat: Array = HAT_SEAT.get(hat, [4.0, 1.0])
	var s: float = clampf(float(head.get("w", NOM_HEAD_W)) / NOM_HEAD_W, 0.60, 1.30) * float(seat[1]) * scale_mul
	var dx: float = float(head.get("cx", 32.0)) - NOM_CX
	var adj: float = float(RIG_HAT_ADJ.get(rig, 0.0))
	# v1.55: Sitz an der sichtbaren Oberkante (sil_top), nicht an der Kopfform
	var top_ref: float = float(head.get("sil_top", head.get("top", 13.0)))
	var dy: float = (top_ref + float(seat[0]) + adj) - NOM_CONTACT
	# v1.46 (F2): Augenband dieses Skins (gemessen in _head_metrics).
	var eye_top: float = float(head.get("eye_top", float(head.get("top", 13.0)) + 8.0))
	var top_ref2: float = float(head.get("sil_top", head.get("top", 13.0)))
	# Grenzen der gezeichneten Hutpixel (Rohdaten, kein get_pixel je Bildpunkt)
	var src: PackedByteArray = layer.get_data()
	var sy0: int = 64
	var sy1: int = -1
	for y in range(64):
		var base: int = y * 64 * 4
		for x in range(64):
			if src[base + x * 4 + 3] > 1:
				if y < sy0:
					sy0 = y
				if y > sy1:
					sy1 = y
				break
	if sy1 < 0:
		return layer
	if hat in FLOAT_HATS:
		# Schweber: eigene Groesse, fester Sitz 2 px ueber dem Kopf
		s = 1.0
		dy = -2.0
	var y_top: float = (float(sy0) - NOM_CONTACT) * s + NOM_CONTACT + dy
	var y_bot: float = (float(sy1) - NOM_CONTACT) * s + NOM_CONTACT + dy
	# v1.46 (F2): Augen frei halten. Der Hut wird auf die Augenoberkante
	# gesetzt; passt er nicht in die Hoehe darueber, wird er verkleinert.
	# Schwebende Huete liegen bereits darueber und bleiben unberuehrt.
	if y_bot > eye_top - 1.0 and hat not in FLOAT_HATS:
		var hh: float = float(sy1 - sy0 + 1)
		# Platz ist die ganze Hoehe ueber dem Augenband - Huete duerfen ueber
		# den Kopf hinausragen, nur die Augen bleiben tabu.
		# v1.55: Groesse auch an die HOEHE des Kopfes anpassen (Konzept-Skins
		# haben 14 px hohe Koepfe - eine Kappe in Standardgroesse verschluckt sie)
		var avail: float = maxf(6.0, eye_top - top_ref2 + 4.0)
		if hh * s > avail:
			s = clampf(avail / hh, 0.50, s)
			print("[HAT][SCHRUMPF] hut=%d rig=%d kopf_w=%.0f skala=%.2f grund=augenband" % [
				hat, rig, float(head.get("w", 25.0)), s])
		dy = (eye_top - 0.5) - ((float(sy1) - NOM_CONTACT) * s + NOM_CONTACT)
		y_top = (float(sy0) - NOM_CONTACT) * s + NOM_CONTACT + dy
		y_bot = (float(sy1) - NOM_CONTACT) * s + NOM_CONTACT + dy
	# v1.55: Ein getragener Hut darf NICHT ueber der Silhouette schweben.
	# (Die Augenregel schob ihn bei hohen Augen ueber den Kopf hinaus.)
	var min_top: float = 1.0
	if hat not in FLOAT_HATS:
		min_top = maxf(1.0, top_ref2)
	if hat not in FLOAT_HATS and y_top < min_top:
		var lift: float = min_top - y_top
		dy += lift
		y_top += lift
		y_bot += lift
	# v1.54: Hut ragte oben aus dem Bild (y<0) und wurde abgeschnitten.
	if y_top < 1.0:
		var shift: float = 1.0 - y_top
		dy += shift
		y_top = 1.0
		y_bot += shift
		if hat not in FLOAT_HATS and y_bot > eye_top - 0.5:
			var hh2: float = float(sy1 - sy0 + 1)
			var avail2: float = maxf(6.0, eye_top - 1.5)
			if hh2 * s > avail2:
				s = clampf(avail2 / hh2, 0.45, s)
			dy = (eye_top - 0.5) - ((float(sy1) - NOM_CONTACT) * s + NOM_CONTACT)
			y_top = (float(sy0) - NOM_CONTACT) * s + NOM_CONTACT + dy
			y_bot = (float(sy1) - NOM_CONTACT) * s + NOM_CONTACT + dy
			if y_top < 1.0:
				dy += 1.0 - y_top
		print("[HAT][DECKEL] hut=%d rig=%d oben=%.1f skala=%.2f" % [hat, rig, y_top, s])
	if y_bot > 63.0:
		dy -= (y_bot - 63.0)
		y_bot = 63.0
	if absf(s - 1.0) < 0.01 and absf(dx) < 0.4 and absf(dy) < 0.4:
		return layer
	var out := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var dst: PackedByteArray = out.get_data()
	for y in range(64):
		var v: float = NOM_CONTACT + (float(y) - NOM_CONTACT - dy) / s
		if v < 0.0 or v > 63.0:
			continue
		var y0: int = clampi(int(floor(v)), 0, 63)
		var y1: int = mini(y0 + 1, 63)
		var fy: float = v - float(y0)
		var r0: int = y0 * 64 * 4
		var r1: int = y1 * 64 * 4
		for x in range(64):
			var u: float = NOM_CX + (float(x) - NOM_CX - dx) / s
			if u < 0.0 or u > 63.0:
				continue
			var x0: int = clampi(int(floor(u)), 0, 63)
			var x1: int = mini(x0 + 1, 63)
			var i00: int = r0 + x0 * 4
			var i10: int = r0 + x1 * 4
			var i01: int = r1 + x0 * 4
			var i11: int = r1 + x1 * 4
			# leere Nachbarschaft ueberspringen (Hut deckt nur ~20 % der Flaeche)
			if src[i00 + 3] == 0 and src[i10 + 3] == 0 and src[i01 + 3] == 0 and src[i11 + 3] == 0:
				continue
			var fx: float = u - float(x0)
			var o: int = (y * 64 + x) * 4
			for ch in range(4):
				var top: float = lerpf(float(src[i00 + ch]), float(src[i10 + ch]), fx)
				var bot: float = lerpf(float(src[i01 + ch]), float(src[i11 + ch]), fx)
				dst[o + ch] = int(clampf(lerpf(top, bot, fy), 0.0, 255.0))
	out.set_data(64, 64, false, Image.FORMAT_RGBA8, dst)
	# v1.46 (F2): Augen bleiben frei - kein Hutpixel ueber dem Augenband.
	# (Nach dem Resampling, sonst wuerde es ueberschrieben.)
	var frei: PackedByteArray = out.get_data()
	var geloescht: int = 0
	for ep in (head.get("eye_px", []) as Array):
		var ex: int = int((ep as Vector2i).x)
		var ey: int = int((ep as Vector2i).y)
		if ex < 0 or ex > 63 or ey < 0 or ey > 63:
			continue
		var oi: int = (ey * 64 + ex) * 4
		if frei[oi + 3] > 0:
			geloescht += 1
		frei[oi] = 0
		frei[oi + 1] = 0
		frei[oi + 2] = 0
		frei[oi + 3] = 0
	if geloescht > 0:
		out.set_data(64, 64, false, Image.FORMAT_RGBA8, frei)
	return out


static func _hat_layer_for_slow(hat: int, head: Dictionary, scale_mul: float = 1.0, rig: int = -1) -> Image:
	# Hut in eine eigene 64x64-Ebene zeichnen und auf die Kopfform abbilden:
	#   s  = Kopfbreite / 25 (Standardkopf), geklemmt, mal Hut-Faktor
	#   dx = Kopfmitte - 32
	#   dy = (Kopfoberkante + Sitz) - NOM_CONTACT
	# Koerperteile (Abzeichen, Rucksack, ...) bleiben unveraendert.
	var layer := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	layer.fill(Color(0, 0, 0, 0))
	if hat <= 0:
		return layer
	_draw_hat(layer, hat)
	if hat in FIXED_HATS:
		# absolute Position, keine Kopf-Skalierung
		return layer
	if hat in HAT_BODY_ITEMS:
		return layer
	var seat: Array = HAT_SEAT.get(hat, [4.0, 1.0])
	var s: float = clampf(float(head.get("w", NOM_HEAD_W)) / NOM_HEAD_W, 0.60, 1.30) * float(seat[1]) * scale_mul
	var dx: float = float(head.get("cx", 32.0)) - NOM_CX
	var adj: float = float(RIG_HAT_ADJ.get(rig, 0.0))
	# v1.55: Sitz an der sichtbaren Oberkante (sil_top), nicht an der Kopfform
	var top_ref: float = float(head.get("sil_top", head.get("top", 13.0)))
	var dy: float = (top_ref + float(seat[0]) + adj) - NOM_CONTACT
	# v1.46 (F2): Augenband dieses Skins (gemessen in _head_metrics).
	var eye_top: float = float(head.get("eye_top", float(head.get("top", 13.0)) + 8.0))
	var top_ref2: float = float(head.get("sil_top", head.get("top", 13.0)))
	# Quellbereich des gezeichneten Hutes bestimmen, damit der Hut nicht aus
	# dem Bild laeuft (Halo auf hohen Koepfen -> sonst unsichtbar).
	var sy0: int = 64
	var sy1: int = -1
	for y in range(64):
		for x in range(64):
			if layer.get_pixel(x, y).a > 0.004:
				if y < sy0:
					sy0 = y
				if y > sy1:
					sy1 = y
	if sy1 < 0:
		return layer
	if hat in FLOAT_HATS:
		# Schweber: eigene Groesse, fester Sitz 2 px ueber dem Kopf
		s = 1.0
		dy = -2.0
	var y_top: float = (float(sy0) - NOM_CONTACT) * s + NOM_CONTACT + dy
	var y_bot: float = (float(sy1) - NOM_CONTACT) * s + NOM_CONTACT + dy
	# v1.46 (F2): Augen frei halten. Der Hut wird auf die Augenoberkante
	# gesetzt; passt er nicht in die Hoehe darueber, wird er verkleinert.
	# Schwebende Huete liegen bereits darueber und bleiben unberuehrt.
	if y_bot > eye_top - 1.0 and hat not in FLOAT_HATS:
		var hh: float = float(sy1 - sy0 + 1)
		# Platz ist die ganze Hoehe ueber dem Augenband - Huete duerfen ueber
		# den Kopf hinausragen, nur die Augen bleiben tabu.
		# v1.55: Groesse auch an die HOEHE des Kopfes anpassen (Konzept-Skins
		# haben 14 px hohe Koepfe - eine Kappe in Standardgroesse verschluckt sie)
		var avail: float = maxf(6.0, eye_top - top_ref2 + 4.0)
		if hh * s > avail:
			s = clampf(avail / hh, 0.50, s)
			print("[HAT][SCHRUMPF] hut=%d rig=%d kopf_w=%.0f skala=%.2f grund=augenband" % [
				hat, rig, float(head.get("w", 25.0)), s])
		dy = (eye_top - 0.5) - ((float(sy1) - NOM_CONTACT) * s + NOM_CONTACT)
		y_top = (float(sy0) - NOM_CONTACT) * s + NOM_CONTACT + dy
		y_bot = (float(sy1) - NOM_CONTACT) * s + NOM_CONTACT + dy
	# v1.55: Ein getragener Hut darf NICHT ueber der Silhouette schweben.
	# (Die Augenregel schob ihn bei hohen Augen ueber den Kopf hinaus.)
	var min_top: float = 1.0
	if hat not in FLOAT_HATS:
		min_top = maxf(1.0, top_ref2)
	if hat not in FLOAT_HATS and y_top < min_top:
		var lift: float = min_top - y_top
		dy += lift
		y_top += lift
		y_bot += lift
	# v1.54: Hut ragte oben aus dem Bild (y<0) und wurde abgeschnitten.
	if y_top < 1.0:
		var shift: float = 1.0 - y_top
		dy += shift
		y_top = 1.0
		y_bot += shift
		if hat not in FLOAT_HATS and y_bot > eye_top - 0.5:
			var hh2: float = float(sy1 - sy0 + 1)
			var avail2: float = maxf(6.0, eye_top - 1.5)
			if hh2 * s > avail2:
				s = clampf(avail2 / hh2, 0.45, s)
			dy = (eye_top - 0.5) - ((float(sy1) - NOM_CONTACT) * s + NOM_CONTACT)
			y_top = (float(sy0) - NOM_CONTACT) * s + NOM_CONTACT + dy
			y_bot = (float(sy1) - NOM_CONTACT) * s + NOM_CONTACT + dy
			if y_top < 1.0:
				dy += 1.0 - y_top
		print("[HAT][DECKEL] hut=%d rig=%d oben=%.1f skala=%.2f" % [hat, rig, y_top, s])
	if y_bot > 63.0:
		dy -= (y_bot - 63.0)
		y_bot = 63.0
	if absf(s - 1.0) < 0.01 and absf(dx) < 0.4 and absf(dy) < 0.4:
		return layer
	var out := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in range(64):
		for x in range(64):
			var u: float = NOM_CX + (float(x) - NOM_CX - dx) / s
			var v: float = NOM_CONTACT + (float(y) - NOM_CONTACT - dy) / s
			if u < 0.0 or v < 0.0 or u > 63.0 or v > 63.0:
				continue
			var c: Color = _sample_bilinear(layer, u, v)
			if c.a <= 0.004:
				continue
			out.set_pixel(x, y, c)
	return out


static func _eye_pair(img: Image, cxa: float, cxb: float, cy: float, style: String, iris: Color = Color(0.10, 0.10, 0.16)) -> void:
	# v1.41 (S3b): echte Augen statt einzelner Pixel - Augapfel, Pupille,
	# Glanzpunkt. Ohne das wirken die Figuren auf dem Sammelbild gesichtslos.
	for i in range(2):
		var ex: float = cxa if i == 0 else cxb
		match style:
			"narrow":
				_ellipse(img, ex, cy, 2.4, 1.6, Color(0.96, 0.96, 1.0))
				_disc(img, ex, cy + 0.2, 1.2, iris)
			"sunken":
				_ellipse(img, ex, cy, 2.6, 2.2, Color(0.86, 0.84, 0.72))
				_disc(img, ex, cy + 0.3, 1.3, iris)
				_px(img, int(ex) - 1, int(cy) - 2, Color(0.20, 0.22, 0.16))
			_:
				_ellipse(img, ex, cy, 2.6, 2.8, Color(0.98, 0.98, 1.0))
				_disc(img, ex, cy + 0.2, 1.5, iris)
				_px(img, int(ex) - 1, int(cy) - 1, Color(1, 1, 1, 0.95))


static func _mouth(img: Image, cx: float, cy: float, style: String, col: Color = Color(0.42, 0.18, 0.18)) -> void:
	match style:
		"smile":
			_thick_line(img, Vector2(cx - 2.5, cy), Vector2(cx + 2.5, cy), 1.0, col)
			_px(img, int(cx) - 3, int(cy) - 1, col)
			_px(img, int(cx) + 3, int(cy) - 1, col)
		"grim":
			_thick_line(img, Vector2(cx - 2.0, cy), Vector2(cx + 2.0, cy), 1.0, col)
		"stitch":
			_thick_line(img, Vector2(cx - 3.0, cy), Vector2(cx + 3.0, cy), 1.0, col)
			for k in range(4):
				_px(img, int(cx) - 3 + k * 2, int(cy) - 1, col)
		_:
			pass


static func _shade_body(img: Image, shirt: Color, pants: Color) -> void:
	# v1.41 (S3b): Koerperflaechen bekommen Licht/Schatten, damit sie nicht als
	# flache Farbflaeche wirken. Nur Pixel, die zur Stoff- oder Hosenfarbe
	# gehoeren, werden moduliert - Konturen, Haut, Metall bleiben unberuehrt.
	# Der Farbton bleibt erhalten (multiplikativ), die Farbpruefung (S4) misst
	# weiterhin dieselbe Farbfamilie.
	var cols := [shirt, pants, shirt.darkened(0.22), shirt.lightened(0.10)]
	for y in range(64):
		for x in range(64):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var treffer := false
			for base in cols:
				if Vector3(c.r - base.r, c.g - base.g, c.b - base.b).length() < 0.16:
					treffer = true
					break
			if not treffer:
				continue
			# Licht von links oben, Schatten rechts unten
			var f: float = 1.0 - 0.24 * (float(x) - 32.0) / 32.0 - 0.18 * (float(y) - 34.0) / 34.0
			f = clampf(f, 0.66, 1.20)
			img.set_pixel(x, y, Color(clampf(c.r * f, 0.0, 1.0), clampf(c.g * f, 0.0, 1.0), clampf(c.b * f, 0.0, 1.0), c.a))


static func _face_pass(img: Image, rig: int) -> void:
	# v1.41 (S3b): pro Skin ein eigenes Gesicht - Position immer auf dem Kopf.
	match rig:
		0:
			_eye_pair(img, 28.0, 36.0, 22.0, "normal", Color(0.16, 0.24, 0.40))
			_mouth(img, 32.0, 27.0, "smile")
		2:
			# Ninja: schmale Augen IM hellen Maskenstreifen
			_eye_pair(img, 28.0, 36.0, 23.0, "narrow", Color(0.10, 0.10, 0.16))
		4:
			_eye_pair(img, 27.0, 37.0, 22.5, "normal", Color(0.14, 0.30, 0.55))
			_mouth(img, 32.0, 27.0, "smile", Color(0.48, 0.20, 0.18))
		7:
			_eye_pair(img, 28.0, 36.0, 23.0, "normal", Color(0.20, 0.34, 0.52))
			_mouth(img, 32.0, 25.0, "grim", Color(0.38, 0.16, 0.14))
		10:
			_eye_pair(img, 28.0, 36.0, 22.0, "sunken", Color(0.28, 0.35, 0.22))
			_mouth(img, 32.0, 27.0, "stitch", Color(0.26, 0.20, 0.14))
		_:
			pass


# v1.46 (F3): Anteil der Koerperpixel (unteres 55 %), der sich durch eine
# weitere Ebene veraendert - Mass fuer "liegt der Gegenstand auf der Brust?".
static func _cover_percent(base: Image, out: Image, head: Dictionary = {}) -> float:
	var w: int = base.get_width()
	var h: int = base.get_height()
	var n: int = 0
	var diff: int = 0
	for y in range(int(h * 0.45), h):
		for x in range(w):
			var c0: Color = base.get_pixel(x, y)
			if c0.a <= 0.6:
				continue
			n += 1
			var c1: Color = out.get_pixel(x, y)
			if absf(c1.r - c0.r) + absf(c1.g - c0.g) + absf(c1.b - c0.b) > 0.15:
				diff += 1
	if n == 0:
		return 0.0
	return 100.0 * float(diff) / float(n)


static func _make_player_rig(idx: int, shirt: Color = Color(0.20, 0.60, 1.0), pants: Color = Color(0.15, 0.25, 0.55), hat: int = -1, noweapon: bool = false) -> ImageTexture:
	_aa = true
	var body_key := "%d_%d_%d_%s" % [idx, shirt.to_rgba32(), pants.to_rgba32(), str(noweapon)]
	# v1.54: Mit Hut legt der Skin sein eigenes Kopfstueck ab (Helm, Hoerner,
	# Dreispitz, Kapuze) - sonst sitzt der neue Hut auf dem alten.
	# v1.55: PANZERHELD behaelt seinen Helm - bei ihm wird nichts entfernt,
	# die Huete werden stattdessen auf den Helm gesetzt.
	var bare: bool = hat > 0 and idx != 1
	var img: Image = _rig_body(idx, shirt, pants, noweapon, bare)
	# v1.39 C: Hut auf die GEMESSENE Kopfform dieses Skins setzen.
	# v1.44 (X1): Kopfform und Hut-Ebene werden zwischengespeichert - die
	# Messung (get_pixel-Schleifen) und das bilineare Umrechnen kosteten je
	# Kachel ~8 ms, mit Cache ~0 ms.
	if hat >= 0:
		var head: Dictionary
		if _head_cache.has(body_key):
			head = _head_cache[body_key]
		else:
			head = _head_metrics(img)
			_head_cache[body_key] = head
		# v1.55: Oberkante der SILHOUETTE - auf Kapuzen-/Helm-Skins liegt die
		# gemessene Kopfform tiefer als die sichtbare Figur, dadurch schwebten
		# Huete (Stirnband, Dreispitz) ueber dem Kopf.
		head["sil_top"] = float(_img_top_head(img, float(head.get("cx", 32.0)), float(head.get("w", 25.0))))
		var sig: String = "%.1f_%.1f_%.1f" % [float(head["top"]), float(head["cx"]), float(head["w"])]
		var lkey := "%d_%d_%s" % [hat, idx, sig]
		var hl: Image
		if _hat_layer_cache.has(lkey):
			hl = _hat_layer_cache[lkey]
		else:
			hl = _hat_layer_for(hat, head, 1.0, idx)
			_hat_layer_cache[lkey] = hl
		if hat in HAT_BODY_ITEMS:
			# v1.46 (F3): Rucksack/Schulterplatten liegen HINTER dem Koerper.
			var back := Image.create(64, 64, false, Image.FORMAT_RGBA8)
			back.fill(Color(0, 0, 0, 0))
			back.blend_rect(hl, Rect2i(0, 0, 64, 64), Vector2i(0, 0))
			back.blend_rect(img, Rect2i(0, 0, 64, 64), Vector2i(0, 0))
			var ueber: float = _cover_percent(img, back, head)
			print("[HAT][EBENE] hut=%d rig=%d ebene=hinten koerper_ueberdeckt=%.1f%%" % [hat, idx, ueber])
			img = back
		else:
			img.blend_rect(hl, Rect2i(0, 0, 64, 64), Vector2i(0, 0))
		# v1.46 (F1): den TATSAECHLICH benutzten Faktor ausgeben (vorher stand
		# hier eine andere Formel - die Recon-Zahl "s=1.39 konstant" war falsch).
		var seat: Array = HAT_SEAT.get(hat, [4.0, 1.0])
		var s_echt: float = clampf(float(head["w"]) / NOM_HEAD_W, 0.85, 1.30) * float(seat[1])
		var dy_echt: float = (float(head["top"]) + float(seat[0]) + float(RIG_HAT_ADJ.get(idx, 0.0))) - NOM_CONTACT
		print("[HAT][FIT] hut=%d rig=%d kopf_w=%.0f skala=%.2f dx=%.1f dy=%.1f augenband=%.0f..%.0f" % [
			hat, idx, float(head["w"]), s_echt, float(head["cx"]) - 32.0, dy_echt,
			float(head.get("eye_top", 0.0)), float(head.get("eye_bot", 0.0))])
	_aa = false
	return ImageTexture.create_from_image(img)


# v1.44 (X1): Rig-Koerper ohne Hut, einmal je (Rig, Farbe, Waffe).
static func _rig_body(idx: int, shirt: Color, pants: Color, noweapon: bool, bare_head: bool = false) -> Image:
	var key := "%d_%d_%d_%s_%s" % [idx, shirt.to_rgba32(), pants.to_rgba32(), str(noweapon), str(bare_head)]
	if _rig_body_cache.has(key):
		return (_rig_body_cache[key] as Image).duplicate()
	# Runde 42: SKINS sind komplette Charakter-Looks UND nehmen die gewaehlte
	# Spielerfarbe an - Farbe x Haut x Skin sind frei kombinierbar.
	_aa = true
	var img = _new_img(64, 64)
	var skin := Color(0.95, 0.75, 0.55)
	var hair := Color(0.45, 0.25, 0.10)
	var gun := Color(0.25, 0.25, 0.30)
	match idx:
		1:
			# PANZERHELD: Panzerung in der Spielerfarbe, Helm mit Visier
			var armor := shirt.lerp(Color(0.45, 0.50, 0.60), 0.28)
			var armor_dark := armor.darkened(0.30)
			_outlined_ellipse(img, 32, 36, 15, 14, armor, 3)
			_outlined_ellipse(img, 17, 30, 7, 9, armor_dark, 3)
			_outlined_ellipse(img, 47, 30, 7, 9, armor_dark, 3)
			if not bare_head:
				# Helm + Visier: weichen dem gewaehlten Hut
				_outlined_disc(img, 32, 21, 11, armor_dark, 3)
				_rect(img, 23, 18, 18, 6, Color(0.12, 0.16, 0.24))
			else:
				_outlined_disc(img, 32, 21, 10, skin, 3)
			_disc(img, 27, 21, 2, Color(1.0, 0.86, 0.30))
			_disc(img, 37, 21, 2, Color(1.0, 0.86, 0.30))
			_disc(img, 32, 36, 4, Color(1.0, 0.82, 0.22))
			_outlined_ellipse(img, 26, 47, 4, 8, pants, 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants, 2)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		2:
			# NINJA: dunkle Stoffe, Schal in der Spielerfarbe
			var ninja := shirt.darkened(0.62)
			_outlined_ellipse(img, 32, 36, 12, 14, ninja, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, pants.darkened(0.5), 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants.darkened(0.5), 2)
			_outlined_disc(img, 32, 22, 11, Color(0.18, 0.20, 0.28), 3)
			_rect(img, 22, 21, 20, 5, Color(0.92, 0.92, 0.96))
			_tri(img, Vector2(48.0, 26.0), Vector2(61.0, 42.0), Vector2(46.0, 33.0), shirt)
			_rect(img, 21, 29, 22, 5, shirt)
			_rect(img, 20, 30, 3, 3, shirt.darkened(0.15))
			_tri(img, Vector2(24, 33), Vector2(30, 33), Vector2(26, 38), shirt.darkened(0.10))
			_rect(img, 40, 30, 20, 4, OUTLINE)
			_rect(img, 41, 31, 18, 2, Color(0.82, 0.86, 0.92))
		3:
			# ROBOTER: Metall mit Leuchtkern in der Spielerfarbe
			var metal := Color(0.68, 0.72, 0.80).lerp(shirt, 0.40)
			_outlined_ellipse(img, 32, 36, 13, 14, shirt, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, pants.lerp(metal, 0.15), 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants.lerp(metal, 0.15), 2)
			_outlined_disc(img, 32, 21, 12, metal.lightened(0.12), 3)
			_rect(img, 24, 18, 16, 6, shirt)
			# v1.54: Antenne 2 px tiefer - die Kugel lag bei y=3 mit Radius 4
			# ueber den Bildrand und war oben abgeschnitten.
			_rect(img, 31, 5, 3, 8, Color(0.45, 0.50, 0.60))
			_disc(img, 32, 5, 3.6, shirt.lightened(0.3))
			_disc(img, 32, 36, 6, shirt.lightened(0.25))
			_disc(img, 30, 34, 2, Color(1, 1, 1))
			_outlined_ellipse(img, 20, 32, 5, 8, metal.darkened(0.15), 3)
			_outlined_ellipse(img, 44, 32, 5, 8, metal.darkened(0.15), 3)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		6:
			# v1.46 (G2): GEIST neu - schwebender Saum (keine Beine),
			# transparenter Unterkoerper (Alpha-Verlauf), leuchtende Augen,
			# Kette am Arm. Erkennbar auch ohne Farbe.
			var sheet := shirt.lerp(Color(0.88, 0.94, 1.0), 0.30)
			var sheet_d := sheet.darkened(0.22)
			# Schultern / Oberkoerper
			_outlined_ellipse(img, 32, 30, 14, 12, sheet, 3)
			# Kopf mit Kapuze, leicht nach vorn geneigt
			_outlined_ellipse(img, 32, 21, 10, 10, sheet.lightened(0.08), 3)
			# Gesichtsöffnung
			_ellipse(img, 32, 22, 6, 6, Color(0.07, 0.08, 0.13), true)
			# leuchtende Augen (Kerne + Hof)
			_disc(img, 29, 21, 2.6, Color(0.45, 0.95, 1.0, 0.45), true)
			_disc(img, 35, 21, 2.6, Color(0.45, 0.95, 1.0, 0.45), true)
			_px(img, 29, 21, Color(0.85, 1.0, 1.0))
			_px(img, 35, 21, Color(0.85, 1.0, 1.0))
			_px(img, 28, 21, Color(0.55, 0.98, 1.0))
			_px(img, 34, 21, Color(0.55, 0.98, 1.0))
			# Arme als Zipfel
			_outlined_ellipse(img, 18, 32, 4, 7, sheet, 2)
			_outlined_ellipse(img, 46, 32, 4, 7, sheet, 2)
			# Kette am linken Arm (dunkle Glieder)
			for k in range(4):
				_disc(img, 15 - k, 39 + k, 1.6, Color(0.55, 0.58, 0.66), true)
				_px(img, 15 - k, 39 + k, Color(0.72, 0.76, 0.84))
			# schwebender Saum: Unterkoerper laeuft nach unten aus (Alpha-Verlauf)
			for y in range(35, 59):
				var p: float = float(y - 35) / 24.0
				var a: float = clampf(0.92 - p * 0.92, 0.0, 0.92)
				var halb: float = 13.0 + p * 6.0 - (p * p) * 5.0
				var wob: float = sin(p * 9.0) * 1.6
				for x in range(32 - int(halb + wob), 32 + int(halb + wob) + 1):
					_px_blend(img, x, y, Color(sheet.r, sheet.g, sheet.b, a))
			# welliger Saum als Silhouette (unten dunkler Rand)
			for k in range(5):
				var sx: int = 20 + k * 6
				var sy: int = 54 + int(sin(float(k) * 1.4) * 2.0)
				_px_blend(img, sx, sy, Color(sheet_d.r, sheet_d.g, sheet_d.b, 0.55))
				_px_blend(img, sx + 1, sy + 1, Color(sheet_d.r, sheet_d.g, sheet_d.b, 0.35))
		4:
			# COMIC-HELD: Umhang + Muskel in der Spielerfarbe
			_tri(img, Vector2(20.0, 26.0), Vector2(44.0, 26.0), Vector2(40.0, 50.0), shirt.darkened(0.22))
			_tri(img, Vector2(44.0, 26.0), Vector2(20.0, 26.0), Vector2(24.0, 50.0), shirt.darkened(0.22))
			_outlined_ellipse(img, 32, 36, 13, 13, shirt, 3)
			_disc(img, 32, 34, 4, Color(1.0, 0.88, 0.25))
			_outlined_ellipse(img, 26, 47, 4, 8, pants, 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants, 2)
			_outlined_disc(img, 32, 22, 10, skin, 3)
			_ellipse(img, 32, 16, 11, 6, Color(0.95, 0.78, 0.28), true)
			_rect(img, 34, 27, 7, 2, OUTLINE)
			_outlined_ellipse(img, 19, 32, 4, 7, skin, 2)
			_outlined_ellipse(img, 45, 32, 4, 7, skin, 2)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		5:
			# MARS-MARSCHALL: weisser Anzug mit Farbakzenten
			var suit := Color(0.90, 0.92, 0.96).lerp(shirt, 0.68)
			_outlined_ellipse(img, 32, 36, 13, 14, suit, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, pants, 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants, 2)
			_outlined_disc(img, 32, 21, 12, suit, 3)
			_ellipse(img, 35, 22, 8, 6, Color(0.35, 0.72, 0.88), true)
			_px(img, 33, 22, Color(1, 1, 1, 0.85))
			_rect(img, 31, 5, 3, 8, Color(0.60, 0.64, 0.72))
			_disc(img, 32, 5, 3, shirt)
			_rect(img, 16, 26, 7, 16, OUTLINE)
			_rect(img, 17, 27, 5, 14, Color(0.55, 0.80, 0.92))
			_rect(img, 26, 30, 12, 3, shirt)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		7:
			# v1.46 (G1): WIKINGER neu gezeichnet - Helm mit Hoernern, Bart als
			# eigene Silhouette (nicht als Fleck), Schulterfell, Axt am Guertel.
			# Der Helm bleibt unten offen genug, dass Huete weiter passen.
			var fur := shirt.lerp(Color(0.46, 0.34, 0.22), 0.45)
			var wood := Color(0.62, 0.42, 0.20)
			var wood_d := Color(0.38, 0.24, 0.10)
			var helm := Color(0.66, 0.70, 0.78)
			var helm_d := Color(0.40, 0.44, 0.52)
			var bart := Color(0.74, 0.36, 0.14)
			# Holzschild auf dem Ruecken (hinter dem Koerper)
			_outlined_disc(img, 50, 40, 9.0, wood, 3)
			_draw_ring(img, 50.0, 40.0, 7.4, 7.4, wood_d, 1.2)
			_disc(img, 50, 40, 2.0, Color(0.80, 0.82, 0.86))
			# breite Schultern
			_outlined_ellipse(img, 32, 40, 15, 9, shirt, 3)
			# Schulterfell (zottelig, als Silhouette ueber den Schultern)
			_ellipse(img, 32, 33, 16, 6, fur.darkened(0.18), true)
			for i in range(7):
				var fx: int = 18 + i * 5
				_disc(img, fx, 31 + (i % 2), 2.6, fur, true)
				_thick_line(img, Vector2(fx, 31), Vector2(fx - 1, 35), 1.2, fur.darkened(0.10))
			# Arme
			_outlined_ellipse(img, 17, 41, 4, 7, shirt.darkened(0.15), 2)
			_outlined_ellipse(img, 47, 41, 4, 7, shirt.darkened(0.15), 2)
			# Beine (breit, fest)
			_outlined_ellipse(img, 26, 52, 5, 7, pants.darkened(0.2), 2)
			_outlined_ellipse(img, 38, 52, 5, 7, pants.darkened(0.2), 2)
			_rect(img, 21, 57, 8, 4, OUTLINE)
			_rect(img, 35, 57, 8, 4, OUTLINE)
			# Axt am Guertel (Griff schraeg, Kopf links)
			_rect(img, 44, 40, 3, 12, Color(0.42, 0.28, 0.14))
			_tri(img, Vector2(40, 40), Vector2(50, 38), Vector2(47, 47), Color(0.78, 0.80, 0.86))
			_tri(img, Vector2(50, 38), Vector2(42, 41), Vector2(49, 46), Color(0.58, 0.60, 0.68))
			# Kopf
			_outlined_disc(img, 32, 24, 10, Color(0.90, 0.72, 0.54), 3)
			# Bart als Silhouette: breit unter dem Gesicht, zulaufend
			_tri(img, Vector2(22, 24), Vector2(42, 24), Vector2(32, 40), bart)
			_tri(img, Vector2(24, 27), Vector2(40, 27), Vector2(32, 36), bart.lightened(0.12))
			# Schnauzer ueber dem Bart
			_rect(img, 27, 23, 10, 2, bart.darkened(0.18))
			# v1.54: Helm + Hoerner weichen dem gewaehlten Hut
			if not bare_head:
				_ellipse(img, 32, 15, 11, 6.5, helm, true)
				_draw_ring(img, 32.0, 15.0, 11.0, 6.5, helm_d, 1.4)
				_rect(img, 31, 15, 3, 6, helm_d)
				_rect(img, 24, 19, 17, 2, helm_d)
				_thick_line(img, Vector2(21, 13), Vector2(13, 8), 2.6, Color(0.94, 0.92, 0.84))
				_thick_line(img, Vector2(13, 8), Vector2(10, 3), 2.0, Color(0.94, 0.92, 0.84))
				_thick_line(img, Vector2(43, 13), Vector2(51, 8), 2.6, Color(0.94, 0.92, 0.84))
				_thick_line(img, Vector2(51, 8), Vector2(54, 3), 2.0, Color(0.94, 0.92, 0.84))
				_disc(img, 10, 3, 1.6, Color(0.86, 0.84, 0.76))
				_disc(img, 54, 3, 1.6, Color(0.86, 0.84, 0.76))
			else:
				_ellipse(img, 32, 17, 10, 5.5, hair, true)
		8:
			# v1.41 (S3): ALIEN neu - Birnenkopf (Breite 20 px, Oberkante y=14),
			# zwei grosse ovale Augen (asymmetrisch), EINE Antenne, schlanker
			# Koerper, 3-Finger-Haende, digitigrade Beine. Keine Fluigel.
			var al := shirt
			var al_d := shirt.darkened(0.22)
			var al_akz := shirt.lerp(Color(0.40, 0.78, 0.46), 0.55)
			# digitigrade Beine (Knick nach hinten)
			_thick_line(img, Vector2(28, 44), Vector2(24, 52), 3.0, al_d)
			_thick_line(img, Vector2(24, 52), Vector2(27, 60), 3.0, al_d)
			_thick_line(img, Vector2(36, 44), Vector2(40, 52), 3.0, al_d)
			_thick_line(img, Vector2(40, 52), Vector2(37, 60), 3.0, al_d)
			_rect(img, 23, 58, 7, 3, OUTLINE)
			_rect(img, 34, 58, 7, 3, OUTLINE)
			# schlanker Koerper
			_outlined_ellipse(img, 32, 40, 8, 12, shirt, 3)
			_ellipse(img, 32, 42, 5, 8, shirt.lightened(0.10), true)
			# Arme mit drei Fingern
			_thick_line(img, Vector2(26, 34), Vector2(18, 42), 2.6, shirt.darkened(0.30))
			_thick_line(img, Vector2(38, 34), Vector2(46, 42), 2.6, shirt.darkened(0.30))
			for k in range(3):
				_disc(img, 16 + k * 2, 45 - k, 1.4, al, true)
				_disc(img, 48 - k * 2, 45 - k, 1.4, al, true)
			# Birnenkopf: unten schmal, oben breit
			_outlined_ellipse(img, 32, 26, 10, 11, al, 3)
			_ellipse(img, 32, 20, 9, 6, al.lightened(0.08), true)
			_rect(img, 26, 17, 12, 2, al_akz)      # Art-Akzent (gruener Streifen)
			# zwei grosse ovale Augen, absichtlich asymmetrisch
			_ellipse(img, 27, 24, 4.2, 5.4, Color(0.06, 0.06, 0.10))
			_ellipse(img, 37, 23, 3.4, 4.4, Color(0.06, 0.06, 0.10))
			_disc(img, 26, 22, 1.4, Color(0.95, 0.98, 0.55), true)
			_disc(img, 36, 21, 1.1, Color(0.95, 0.98, 0.55), true)
			# EINE Antenne
			_thick_line(img, Vector2(32, 15), Vector2(34, 6), 1.8, al_d)
			_disc(img, 34, 5, 2.4, Color(0.95, 0.80, 0.30))
		9:
			# v1.41 (S3): SPINNENMANN neu - geduckt, vier Beine aus dem Rumpf,
			# zwei Arme, Hinterleib nach hinten. Kopf frei und klar getrennt.
			# Kopf: Breite 18 px, Oberkante y=14.
			var spin := shirt.lerp(Color(0.62, 0.12, 0.18), 0.35)
			var spin_d := shirt.darkened(0.40)
			var spin_l := shirt.lerp(Color(0.82, 0.28, 0.30), 0.30)
			# vier Spinnenbeine (aus dem Rumpf, nach unten ausgestellt)
			_thick_line(img, Vector2(28, 32), Vector2(8, 42), 3.0, spin_d)
			_thick_line(img, Vector2(8, 42), Vector2(4, 56), 3.0, spin_d)
			_thick_line(img, Vector2(28, 38), Vector2(12, 52), 3.0, spin_d)
			_thick_line(img, Vector2(12, 52), Vector2(14, 62), 3.0, spin_d)
			_thick_line(img, Vector2(38, 38), Vector2(52, 52), 3.0, spin_d)
			_thick_line(img, Vector2(52, 52), Vector2(50, 62), 3.0, spin_d)
			# v1.54: rechtes Bein 3 px eingerueckt - lag mit 3 px Strichstärke
			# ueber den rechten Bildrand (x=63) und wurde abgeschnitten.
			_thick_line(img, Vector2(38, 32), Vector2(55, 44), 3.0, spin_d)
			_thick_line(img, Vector2(55, 44), Vector2(59, 56), 3.0, spin_d)
			# Hinterleib nach hinten (rechts)
			_outlined_ellipse(img, 46, 46, 8, 7, shirt, 3)
			_ellipse(img, 46, 46, 4, 3, shirt.lightened(0.12), true)
			# Rumpf (geduckt, breiter als hoch)
			_outlined_ellipse(img, 31, 42, 9, 8, shirt, 3)
			# zwei Arme
			_outlined_ellipse(img, 20, 40, 3.4, 6, spin_l, 2)
			_outlined_ellipse(img, 40, 40, 3.4, 6, spin_l, 2)
			# Kopf (frei, vom Rumpf getrennt)
			_outlined_disc(img, 31, 24, 9, spin_l, 3)
			_ellipse(img, 28, 23, 3.0, 4.0, Color(0.98, 0.98, 1.0))
			_ellipse(img, 35, 23, 3.0, 4.0, Color(0.98, 0.98, 1.0))
			_disc(img, 28, 24, 1.2, OUTLINE)
			_disc(img, 35, 24, 1.2, OUTLINE)
		10:
			# v1.41 (S3): ZOMBIE neu - aufrechter Gang, Kopf frei und MITTIG
			# (kein Haar-Klumpen, keine offene Schaedeldecke), Arme haengen
			# seitlich, zerrissenes Hemd, ein Bein nachgezogen.
			# Kopf: Breite 20 px, Oberkante y=13.
			var zskin := Color(0.56, 0.72, 0.42)
			var zcloth := shirt.lerp(Color(0.44, 0.42, 0.32), 0.30)
			# Beine: eines normal, eines nachgezogen (laenger, schraeg)
			_outlined_ellipse(img, 28, 52, 4.4, 8, pants, 2)
			_thick_line(img, Vector2(38, 44), Vector2(41, 56), 4.0, pants.darkened(0.20))
			_rect(img, 38, 57, 8, 3, OUTLINE)
			_rect(img, 24, 59, 8, 3, OUTLINE)
			# Arme haengen seitlich (nicht nach vorn)
			_outlined_ellipse(img, 19, 40, 3.6, 9, zskin, 2)
			_outlined_ellipse(img, 45, 40, 3.6, 9, zskin.darkened(0.10), 2)
			_disc(img, 19, 50, 3.2, zskin)
			_disc(img, 45, 50, 3.2, zskin.darkened(0.10))
			# Rumpf im zerrissenen Hemd (ausgefranste Unterkante)
			_outlined_ellipse(img, 32, 36, 12, 13, zcloth, 3)
			for k in range(5):
				_tri(img, Vector2(21 + k * 5, 44), Vector2(24 + k * 5, 44), Vector2(22 + k * 5, 50), zcloth)
			_rect(img, 27, 32, 4, 3, zskin)      # Loch im Hemd
			_rect(img, 35, 38, 5, 3, zskin)
			# Kopf: frei, mittig, ohne Haare
			_outlined_disc(img, 32, 23, 10, zskin, 3)
			_rect(img, 28, 27, 9, 1, OUTLINE)
			_px(img, 32, 26, zskin.darkened(0.3))
		11:
			# v1.41 (N5): EISENKARDINAL / Templer - weisse Surcoate in Spielerfarbe,
			# rotes Wappen, Kettenkapuze, Streitkolben.
			img.blit_rect(GenConcepts._make_concept({
				"cloth": shirt, "legs_col": pants, "metal": Color(0.72, 0.74, 0.80),
				"accent": Color(0.78, 0.12, 0.14), "face": "human", "gear": ("none" if bare_head else "hood"),
				"torso": "plate", "shoulder": "pads", "weapon": ("none" if noweapon else "mace"), "legs": "normal"}).get_image(),
				Rect2i(0, 0, 64, 64), Vector2i(0, 0))
		12:
			# v1.41 (N5): ONI-FELDHERR / Blauer Oni - Maske mit Hauern, Platte,
			# Stachelschultern, breiter Stand, keine Waffe (Klauen).
			img.blit_rect(GenConcepts._make_concept({
				"cloth": shirt, "legs_col": pants, "metal": Color(0.56, 0.66, 0.86),
				"accent": Color(0.34, 0.56, 0.86), "face": "oni", "gear": ("none" if bare_head else "horns"),
				"torso": "plate", "shoulder": "spikes", "weapon": "none", "legs": "wide"}).get_image(),
				Rect2i(0, 0, 64, 64), Vector2i(0, 0))
		13:
			# v1.41 (N5): EWIGER HERRSCHER / Anubis-Priester - Schakelkopf,
			# dunkle Robe, goldener Stab.
			img.blit_rect(GenConcepts._make_concept({
				"cloth": shirt, "legs_col": pants, "metal": Color(0.90, 0.75, 0.25),
				"accent": Color(0.55, 0.88, 1.0), "skin": Color(0.32, 0.30, 0.38), "face": "grim", "gear": "anubis",
				"torso": "robe", "weapon": ("none" if noweapon else "staff"), "legs": "robe"}).get_image(),
				Rect2i(0, 0, 64, 64), Vector2i(0, 0))
		14:
			# v1.41 (N5): KAPITAEN ROST / Klassisch - Dreispitz, Umhang, Saeber.
			img.blit_rect(GenConcepts._make_concept({
				"cloth": shirt, "legs_col": pants, "metal": Color(0.80, 0.83, 0.88),
				"accent": Color(0.92, 0.75, 0.20), "face": "human", "gear": ("none" if bare_head else "tricorn"),
				"torso": "normal", "cloak": true, "weapon": ("none" if noweapon else "sabre"), "legs": "normal"}).get_image(),
				Rect2i(0, 0, 64, 64), Vector2i(0, 0))
		15:
			# v1.41 (N5): FROSTBEIL / Fellkapuze - Fellkragen, Eisaxt, breiter Stand.
			img.blit_rect(GenConcepts._make_concept({
				"cloth": shirt, "legs_col": pants, "metal": Color(0.82, 0.86, 0.90),
				"accent": Color(0.55, 0.80, 1.0), "face": "human", "gear": ("none" if bare_head else "hood"),
				"torso": "plate", "shoulder": "fur", "weapon": ("none" if noweapon else "axe"), "legs": "wide"}).get_image(),
				Rect2i(0, 0, 64, 64), Vector2i(0, 0))
		16:
			# v1.41 (N5): GRINSER / Joker-Maske - weiss geschminkt, gruenes
			# Grinsen, Robe, Spielkarten.
			img.blit_rect(GenConcepts._make_concept({
				"cloth": shirt, "legs_col": pants, "metal": Color(0.10, 0.85, 0.35),
				"accent": Color(0.10, 0.85, 0.35), "face": "paint", "gear": "none",
				"torso": "robe", "weapon": ("none" if noweapon else "cards"), "legs": "robe"}).get_image(),
				Rect2i(0, 0, 64, 64), Vector2i(0, 0))
		_:
			_outlined_ellipse(img, 32, 36, 12, 14, shirt, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, pants, 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants, 2)
			_outlined_disc(img, 32, 22, 10, skin, 3)
			_ellipse(img, 32, 16, 11, 6, hair, true)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
	# v1.41 (S3b): Gesichter und Koerper-Shading vor der Hut-Montage
	_face_pass(img, idx)
	_shade_body(img, shirt, pants)
	_rig_body_cache[key] = img.duplicate()
	return img


static func _make_hat_icon(idx: int, size: int) -> ImageTexture:
	# Runde 106: NICHT mehr separat zeichnen. Vorher gab es eine eigene
	# map-Tabelle, die nicht zu _draw_hat() passte -> in der Kiste war ein
	# anderer Hut zu sehen als man bekam. Jetzt wird der Kopfbereich der
	# ECHTEN Figur ausgeschnitten: Icon = das, was man auch traegt.
	var hi: int = clampi(idx, 0, HAT_NAMES.size() - 1)
	var c: Dictionary = PLAYER_COLORS[0]
	var full: Image = _make_player(c["shirt"], c["pants"], hi).get_image()
	var crop: Image = full.get_region(Rect2i(4, 0, 56, 38))
	var target_h: int = int(float(size) * 38.0 / 56.0)
	crop.resize(size, target_h, Image.INTERPOLATE_NEAREST)
	var out_img := _new_img(size, size)
	var oy: int = int((size - target_h) * 0.5)
	out_img.blit_rect(crop, Rect2i(0, 0, size, target_h), Vector2i(0, oy))
	return ImageTexture.create_from_image(out_img)
