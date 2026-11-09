class_name GenConcepts
extends TexDraw

# v1.41 (N3, zweite Fassung): Konzept-Skins zum Aussuchen.
# Schichten: Schatten -> Ruecken (Umhang/Schild) -> Beine -> Rumpf (Falten +
# Shading) -> Guertel -> Schultern -> Arme -> Kopf (Gesicht) -> Kopfbedeckung
# -> Waffe. Jede Variante hat ein eigenes Gesicht und echte Schattierung.


static func _shaded(img: Image, cx: float, cy: float, rx: float, ry: float, base: Color, ow: int = 3) -> void:
	# Kontur, Grundton, Schattenseite unten rechts, Licht oben links.
	_outlined_ellipse(img, cx, cy, rx, ry, base, ow)
	_ellipse(img, cx + rx * 0.26, cy + ry * 0.30, rx * 0.70, ry * 0.62, base.darkened(0.20), true)
	_ellipse(img, cx - rx * 0.26, cy - ry * 0.32, rx * 0.44, ry * 0.36, base.lightened(0.20), true)


static func _cloth(img: Image, cx: float, cy: float, rx: float, ry: float, base: Color, folds: int = 3) -> void:
	# Stoff mit Faltenlinien, damit Flaechen nicht flach wirken.
	_shaded(img, cx, cy, rx, ry, base, 3)
	for i in range(folds):
		var t: float = float(i + 1) / float(folds + 1)
		var x0: float = cx - rx * 0.70 + rx * 1.4 * t
		_thick_line(img, Vector2(x0, cy - ry * 0.40), Vector2(x0 + 1.5, cy + ry * 0.55), 0.9, base.darkened(0.28))


static func _face(img: Image, cx: float, cy: float, style: String, skin: Color, accent: Color) -> void:
	# Jedes Gesicht hat Augapfel, Pupille und Glanzpunkt - sonst wirkt die
	# Figur gesichtslos (das war die Kritik an der ersten Fassung).
	match style:
		"grim":
			_outlined_disc(img, cx, cy, 10, skin, 3)
			for s in [-1.0, 1.0]:
				var ex2: float = cx + s * 3.8
				_ellipse(img, ex2, cy - 0.5, 2.4, 2.6, Color(0.98, 0.98, 1.0))
				_disc(img, ex2 + s * 0.4, cy - 0.1, 1.4, Color(0.10, 0.10, 0.16))
			_thick_line(img, Vector2(cx - 7.0, cy - 5.5), Vector2(cx - 1.5, cy - 3.5), 1.4, skin.darkened(0.6))
			_thick_line(img, Vector2(cx + 1.5, cy - 3.5), Vector2(cx + 7.0, cy - 5.5), 1.4, skin.darkened(0.6))
			_ellipse(img, cx, cy + 5, 4.0, 2.0, Color(0.30, 0.08, 0.10))
			_rect(img, int(cx) - 3, int(cy) + 4, 6, 1, Color(0.96, 0.96, 0.92))
		"oni":
			_outlined_ellipse(img, cx, cy, 11, 10, accent, 3)
			_ellipse(img, cx, cy + 3, 8, 5, accent.darkened(0.22), true)
			for s in [-1.0, 1.0]:
				_ellipse(img, cx + s * 4.2, cy - 1, 3.0, 2.2, Color(0.99, 0.95, 0.80))
				_disc(img, cx + s * 4.4, cy - 1, 1.5, Color(0.12, 0.08, 0.08))
			_rect(img, int(cx) - 5, int(cy) + 4, 10, 3, Color(0.25, 0.05, 0.08))
			_tri(img, Vector2(cx - 4, cy + 4), Vector2(cx - 2, cy + 9), Vector2(cx - 1, cy + 4), Color(0.98, 0.96, 0.90))
			_tri(img, Vector2(cx + 1, cy + 4), Vector2(cx + 2, cy + 9), Vector2(cx + 4, cy + 4), Color(0.98, 0.96, 0.90))
		"skull":
			_outlined_disc(img, cx, cy, 9, Color(0.92, 0.90, 0.82), 3)
			for s in [-1.0, 1.0]:
				_ellipse(img, cx + s * 3.4, cy - 1, 2.6, 2.8, Color(0.08, 0.08, 0.10))
			_tri(img, Vector2(cx, cy + 2), Vector2(cx - 1.2, cy + 4.5), Vector2(cx + 1.2, cy + 4.5), Color(0.08, 0.08, 0.10))
			for i in range(4):
				_rect(img, int(cx) - 4 + i * 2, int(cy) + 6, 1, 2, Color(0.08, 0.08, 0.10))
		"visor":
			_outlined_disc(img, cx, cy, 10, skin, 3)
			_rect(img, int(cx) - 8, int(cy) - 2, 16, 5, Color(0.10, 0.12, 0.18))
			_rect(img, int(cx) - 6, int(cy) - 1, 12, 2, accent)
			_disc(img, cx - 3, cy, 1.0, Color(1, 1, 1, 0.9))
		"paint":
			_outlined_disc(img, cx, cy, 10, Color(0.96, 0.96, 0.98), 3)
			for s in [-1.0, 1.0]:
				_disc(img, cx + s * 3.6, cy - 2, 1.8, Color(0.10, 0.10, 0.14))
			_thick_line(img, Vector2(cx - 6.0, cy + 3.0), Vector2(cx, cy + 6.0), 1.6, accent)
			_thick_line(img, Vector2(cx, cy + 6.0), Vector2(cx + 6.0, cy + 3.0), 1.6, accent)
		_:
			_outlined_disc(img, cx, cy, 10, skin, 3)
			_ellipse(img, cx + 4.0, cy + 3.0, 5.0, 4.5, skin.darkened(0.13), true)
			for s in [-1.0, 1.0]:
				var ex: float = cx + s * 3.6
				_ellipse(img, ex, cy - 0.5, 2.6, 3.0, Color(0.98, 0.98, 1.0))
				_disc(img, ex + s * 0.4, cy - 0.2, 1.5, Color(0.10, 0.10, 0.16))
				_disc(img, ex + s * 0.4 - 0.6, cy - 1.0, 0.6, Color(1, 1, 1, 0.9))
			_thick_line(img, Vector2(cx - 6.0, cy - 4.0), Vector2(cx - 2.0, cy - 5.0), 1.1, skin.darkened(0.55))
			_thick_line(img, Vector2(cx + 2.0, cy - 5.0), Vector2(cx + 6.0, cy - 4.0), 1.1, skin.darkened(0.55))
			_thick_line(img, Vector2(cx - 2.5, cy + 4.5), Vector2(cx + 2.5, cy + 4.5), 1.0, Color(0.45, 0.16, 0.18))


static func _gear_back(img: Image, gear: String, cloth: Color, cloth_d: Color, metal: Color, metal_d: Color, accent: Color) -> void:
	# Kopfbedeckungen, die HINTER dem Gesicht liegen (Kapuze, Nemes, Schakal).
	match gear:
		"hood":
			_outlined_ellipse(img, 32, 18, 14, 13, cloth_d, 3)
			_ellipse(img, 32, 27, 10, 8, cloth_d.darkened(0.10), true)
			_ellipse(img, 32, 11, 12, 5, cloth.lightened(0.10), true)
		"nemes":
			_outlined_ellipse(img, 32, 16, 15, 12, metal, 3)
			_rect(img, 17, 16, 7, 17, metal_d)
			_rect(img, 40, 16, 7, 17, metal_d)
			for i in range(3):
				_rect(img, 18 + i * 2, 18, 1, 13, metal)
				_rect(img, 41 + i * 2, 18, 1, 13, metal)
		"anubis":
			# Schakelkopf: Kapuze in dunklem Ton, zwei lange Ohren in Akzentfarbe
			_outlined_ellipse(img, 32, 17, 11, 10, Color(0.10, 0.10, 0.14), 3)
			_tri(img, Vector2(26, 12), Vector2(15, 2), Vector2(31, 8), accent)
			_tri(img, Vector2(38, 12), Vector2(49, 2), Vector2(33, 8), accent)
			_tri(img, Vector2(26, 11), Vector2(20, 1), Vector2(29, 9), accent.darkened(0.35))
			_tri(img, Vector2(38, 11), Vector2(44, 1), Vector2(35, 9), accent.darkened(0.35))
		"helm":
			_outlined_ellipse(img, 32, 15, 12, 11, metal, 3)
		_:
			pass


static func _gear_front(img: Image, gear: String, cloth: Color, cloth_d: Color, metal: Color, metal_d: Color, accent: Color) -> void:
	# Kopfbedeckungen vor dem Gesicht (Krone, Hoerner, Zylinder, Brille ...).
	match gear:
		"hood":
			# Kapuzenrand ueber der Stirn, Gesicht bleibt frei
			_ellipse(img, 32, 12, 12, 5, cloth, true)
			_thick_line(img, Vector2(20, 13), Vector2(44, 13), 1.2, cloth_d)
		"nemes":
			# Stirnband mit Streifen
			_rect(img, 21, 12, 22, 4, metal)
			_rect(img, 21, 15, 22, 1, metal_d)
			for i in range(5):
				_rect(img, 23 + i * 4, 12, 1, 4, metal_d)
		"anubis":
			# goldene Schnauze + Augenringe
			_outlined_ellipse(img, 32, 27, 5.0, 3.2, Color(0.28, 0.26, 0.22), 2)
			_draw_ring(img, 32.0, 38.0, 5.0, 5.0, metal, 1.4)
		"helm":
			_rect(img, 23, 18, 18, 4, Color(0.10, 0.10, 0.14))
			_rect(img, 24, 19, 16, 1, metal_d)
		"crown":
			_rect(img, 23, 8, 18, 5, metal)
			_rect(img, 23, 12, 18, 1, metal_d)
			for i in range(3):
				var bx: float = 24.0 + i * 7.0
				_tri(img, Vector2(bx, 9), Vector2(bx + 2, 1), Vector2(bx + 4, 9), metal)
				_disc(img, bx + 2, 10, 0.9, accent)
		"horns":
			_tri(img, Vector2(23, 15), Vector2(10, 2), Vector2(27, 11), Color(0.94, 0.92, 0.86))
			_tri(img, Vector2(41, 15), Vector2(54, 2), Vector2(37, 11), Color(0.94, 0.92, 0.86))
			_thick_line(img, Vector2(24, 14), Vector2(28, 11), 1.0, Color(0.75, 0.72, 0.66))
			_thick_line(img, Vector2(40, 14), Vector2(36, 11), 1.0, Color(0.75, 0.72, 0.66))
		"tricorn":
			# Krone + breite, an den Seiten hochgeklappte Krempe
			_outlined_ellipse(img, 32, 10, 10, 7, cloth_d, 2)
			_outlined_ellipse(img, 32, 14, 18, 5, cloth_d, 2)
			_tri(img, Vector2(16, 14), Vector2(8, 6), Vector2(26, 11), cloth_d)
			_tri(img, Vector2(48, 14), Vector2(56, 6), Vector2(38, 11), cloth_d)
			_ellipse(img, 32, 13, 12, 2, cloth_d.lightened(0.18), true)
			_disc(img, 32, 8, 1.8, accent)
			_thick_line(img, Vector2(17, 16), Vector2(22, 12), 0.9, metal)
			_thick_line(img, Vector2(47, 16), Vector2(42, 12), 0.9, metal)
		"tophat":
			_rect(img, 26, 0, 13, 15, Color(0.10, 0.10, 0.14))
			_rect(img, 27, 2, 11, 4, Color(0.17, 0.17, 0.22))
			_rect(img, 26, 11, 13, 3, accent)
			_rect(img, 17, 14, 30, 4, Color(0.10, 0.10, 0.14))
		"jester":
			_tri(img, Vector2(24, 13), Vector2(7, 2), Vector2(27, 5), accent)
			_tri(img, Vector2(40, 13), Vector2(57, 2), Vector2(37, 5), accent)
			_disc(img, 7, 2, 2.6, metal)
			_disc(img, 57, 2, 2.6, metal)
			_rect(img, 22, 12, 20, 3, accent.darkened(0.25))
		"goggles":
			_rect(img, 21, 16, 23, 7, Color(0.16, 0.16, 0.20))
			_rect(img, 23, 18, 7, 4, Color(0.55, 0.88, 1.0))
			_rect(img, 34, 18, 7, 4, Color(0.55, 0.88, 1.0))
			_rect(img, 21, 15, 23, 2, metal_d)
		"wreath":
			for i in range(7):
				var a: float = PI * (0.15 + 0.7 * float(i) / 6.0)
				_disc(img, 32.0 + cos(a) * 11.0, 15.0 - sin(a) * 4.0, 3.0,
					[Color(0.30, 0.62, 0.28), Color(0.44, 0.78, 0.36)][i % 2], true)
		_:
			pass


static func _make_concept(cfg: Dictionary) -> ImageTexture:
	_aa = true
	var img = _new_img(64, 64)
	var cloth: Color = cfg.get("cloth", Color(0.45, 0.45, 0.55))
	var metal: Color = cfg.get("metal", Color(0.72, 0.74, 0.80))
	var accent: Color = cfg.get("accent", Color(0.85, 0.30, 0.25))
	var skin: Color = cfg.get("skin", Color(0.92, 0.76, 0.58))
	var cloth_d: Color = cloth.darkened(0.30)
	# v1.41 (N5): Beine koennen separat gefaerbt werden (Spielerfarbe Hose)
	var legs_col: Color = cfg.get("legs_col", cloth_d)
	var metal_d: Color = metal.darkened(0.32)
	var legs: String = str(cfg.get("legs", "normal"))
	var gear: String = str(cfg.get("gear", "none"))
	var weapon: String = str(cfg.get("weapon", "none"))
	var face: String = str(cfg.get("face", "human"))
	var torso: String = str(cfg.get("torso", "normal"))
	var shoulder: String = str(cfg.get("shoulder", "none"))

	_ellipse(img, 32, 58, 17, 5, SHADOW, true)

	# --- Ruecken ---
	if bool(cfg.get("cloak", false)):
		_tri(img, Vector2(19, 27), Vector2(45, 27), Vector2(52, 55), cloth_d)
		_tri(img, Vector2(45, 27), Vector2(19, 27), Vector2(12, 55), cloth_d)
		_thick_line(img, Vector2(32, 28), Vector2(32, 54), 1.0, cloth.darkened(0.45))
	if bool(cfg.get("shield_back", false)):
		_outlined_disc(img, 50, 40, 9.0, Color(0.62, 0.42, 0.20), 3)
		_draw_ring(img, 50.0, 40.0, 7.2, 7.2, Color(0.38, 0.24, 0.10), 1.2)
		_disc(img, 50, 40, 2.0, metal)

	# --- Beine ---
	match legs:
		"wide":
			_shaded(img, 25, 51, 5.0, 8.0, legs_col, 2)
			_shaded(img, 39, 51, 5.0, 8.0, legs_col, 2)
			_rect(img, 20, 57, 9, 3, Color(0.18, 0.14, 0.10))
			_rect(img, 35, 57, 9, 3, Color(0.18, 0.14, 0.10))
		"one":
			_shaded(img, 28, 51, 4.4, 8.0, legs_col, 2)
			_thick_line(img, Vector2(38, 45), Vector2(43, 57), 4.2, legs_col)
			_rect(img, 40, 57, 8, 3, Color(0.18, 0.14, 0.10))
		"mech":
			_rect(img, 22, 45, 9, 15, OUTLINE)
			_rect(img, 23, 46, 7, 13, metal_d)
			_rect(img, 25, 50, 3, 6, accent)
			_rect(img, 33, 45, 9, 15, OUTLINE)
			_rect(img, 34, 46, 7, 13, metal_d)
			_rect(img, 36, 50, 3, 6, accent)
		"robe":
			_tri(img, Vector2(32, 34), Vector2(52, 58), Vector2(12, 58), cloth)
			_tri(img, Vector2(32, 36), Vector2(46, 57), Vector2(18, 57), cloth.lightened(0.10))
			_thick_line(img, Vector2(32, 38), Vector2(32, 56), 1.0, cloth_d)
		_:
			_shaded(img, 26, 51, 4.4, 8.0, legs_col, 2)
			_shaded(img, 38, 51, 4.4, 8.0, legs_col, 2)

	# --- Rumpf ---
	match torso:
		"plate":
			_shaded(img, 32, 36, 14, 12, metal, 3)
			_rect(img, 22, 33, 20, 2, metal_d)
			_rect(img, 22, 40, 20, 2, metal_d)
			_disc(img, 32, 36, 3.0, accent)
		"slim":
			_cloth(img, 32, 36, 9.5, 13, cloth, 2)
		_:
			_cloth(img, 32, 36, 12, 13, cloth, 3)

	# --- Guertel ---
	if torso != "robe":
		_rect(img, 21, 44, 22, 3, Color(0.30, 0.20, 0.12))
		_rect(img, 30, 44, 5, 3, metal)

	# --- Schultern ---
	match shoulder:
		"pads":
			_shaded(img, 16, 30, 7.0, 5.0, metal, 2)
			_shaded(img, 48, 30, 7.0, 5.0, metal, 2)
		"spikes":
			_tri(img, Vector2(22, 32), Vector2(11, 21), Vector2(27, 28), metal)
			_tri(img, Vector2(42, 32), Vector2(53, 21), Vector2(37, 28), metal)
			_thick_line(img, Vector2(16, 26), Vector2(24, 30), 1.0, metal_d)
			_thick_line(img, Vector2(48, 26), Vector2(40, 30), 1.0, metal_d)
		"fur":
			for i in range(6):
				_disc(img, 20 + i * 5, 29, 2.8, Color(0.62, 0.50, 0.36), true)

	# --- Arme ---
	_shaded(img, 18, 37, 4.0, 8.0, cloth, 2)
	_shaded(img, 46, 37, 4.0, 8.0, cloth, 2)
	_disc(img, 18, 45, 2.6, skin)
	_disc(img, 46, 45, 2.6, skin)

	# --- Kopf + Gesicht ---
	_face(img, 32, 21, face, skin, accent)

	# --- Kopf: Kopfbedeckung hinten, dann Gesicht, dann Kopfbedeckung vorn ---
	_gear_back(img, gear, cloth, cloth_d, metal, metal_d, accent)
	_face(img, 32, 21, face, skin, accent)
	_gear_front(img, gear, cloth, cloth_d, metal, metal_d, accent)

	# --- Waffe / Requisite ---
	match weapon:
		"axe":
			_rect(img, 52, 22, 3, 30, Color(0.42, 0.28, 0.14))
			_rect(img, 44, 20, 12, 8, metal)
			_rect(img, 44, 20, 3, 8, metal_d)
			_tri(img, Vector2(56, 20), Vector2(62, 24), Vector2(56, 28), metal)
		"mace":
			_rect(img, 13, 26, 3, 26, Color(0.42, 0.28, 0.14))
			_disc(img, 14, 21, 5.0, metal)
			for i in range(6):
				var a2: float = TAU * float(i) / 6.0
				_disc(img, 14 + cos(a2) * 6.5, 21 + sin(a2) * 6.5, 1.8, metal_d)
		"staff":
			_rect(img, 8, 14, 3, 40, Color(0.42, 0.28, 0.14))
			_draw_ring(img, 9.5, 11.0, 4.5, 4.5, metal, 2.0)
			_disc(img, 9, 11, 2.0, accent)
		"sabre":
			_thick_line(img, Vector2(50, 44), Vector2(59, 16), 3.2, metal)
			_thick_line(img, Vector2(50, 44), Vector2(59, 16), 1.2, metal.lightened(0.40))
			_rect(img, 46, 44, 8, 3, Color(0.42, 0.28, 0.14))
			_draw_ring(img, 50.0, 47.0, 3.0, 3.0, metal_d, 1.2)
		"compass":
			_disc(img, 52, 33, 5.0, metal)
			_disc(img, 52, 33, 3.6, Color(0.94, 0.92, 0.82))
			_thick_line(img, Vector2(52, 33), Vector2(54, 30), 1.0, accent)
		"hook":
			_thick_line(img, Vector2(50, 45), Vector2(52, 27), 2.2, metal)
			_draw_ring(img, 52.0, 24.0, 3.6, 3.6, metal, 2.0)
			_thick_line(img, Vector2(55.5, 21.5), Vector2(56.5, 27.5), 1.6, metal)
			_disc(img, 56, 20, 1.6, metal_d)
		"cards":
			for i in range(3):
				_rect(img, 45 + i * 4, 30 - i * 3, 7, 10, Color(0.98, 0.98, 1.0))
				_rect(img, 46 + i * 4, 31 - i * 3, 5, 8, accent if i % 2 == 0 else Color(0.15, 0.15, 0.20))
		"whip":
			_thick_line(img, Vector2(48, 44), Vector2(58, 50), 1.6, Color(0.36, 0.22, 0.12))
			_thick_line(img, Vector2(58, 50), Vector2(62, 44), 1.6, Color(0.36, 0.22, 0.12))
		"flag":
			_rect(img, 7, 18, 3, 34, Color(0.42, 0.28, 0.14))
			_rect(img, 9, 18, 13, 11, cloth.lightened(0.10))
			_rect(img, 9, 22, 13, 2, accent)
			_rect(img, 9, 25, 13, 1, accent)
			_tri(img, Vector2(9, 29), Vector2(22, 29), Vector2(15, 34), cloth.lightened(0.10))
		"banner_shield":
			_shaded(img, 50, 38, 9.0, 11.0, metal, 3)
			_rect(img, 46, 34, 9, 3, accent)
			_disc(img, 50, 40, 2.4, accent)
		_:
			pass

	_aa = false
	return ImageTexture.create_from_image(img)
