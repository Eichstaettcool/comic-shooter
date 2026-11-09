class_name GenMonsters
extends TexDraw


static func _make_monster(body: Color, highlight: Color, crown: bool = false) -> ImageTexture:
	var img = _new_img(56, 56)
	var cx := 28.0

	# Schatten
	_ellipse(img, cx, 48, 16, 5, SHADOW, true)
	# Füße
	_outlined_ellipse(img, 20, 43, 5, 3, body, 2)
	_outlined_ellipse(img, 36, 43, 5, 3, body, 2)
	# Körper (Blob)
	_outlined_ellipse(img, cx, 30, 16, 15, body, 3)
	# Glanz/Bauch
	_ellipse(img, cx, 34, 9, 7, highlight, true)
	# Krone beim Boss (gold) oder Hörner
	if crown:
		_tri(img, Vector2(10, 14), Vector2(10, 4), Vector2(17, 11), Color(0.3, 0.22, 0.02))
		_tri(img, Vector2(21, 11), Vector2(25, 2), Vector2(29, 11), Color(0.3, 0.22, 0.02))
		_tri(img, Vector2(35, 11), Vector2(39, 2), Vector2(43, 11), Color(0.3, 0.22, 0.02))
		_tri(img, Vector2(10, 12), Vector2(10, 6), Vector2(16, 11), Color(1.0, 0.84, 0.2))
		_tri(img, Vector2(21, 10), Vector2(25, 4), Vector2(29, 10), Color(1.0, 0.84, 0.2))
		_tri(img, Vector2(35, 10), Vector2(39, 4), Vector2(43, 10), Color(1.0, 0.84, 0.2))
		_rect(img, 10, 11, 25, 4, Color(0.3, 0.22, 0.02))
		_rect(img, 11, 12, 23, 2, Color(1.0, 0.84, 0.2))
	else:
		_tri(img, Vector2(13, 18), Vector2(9, 6), Vector2(20, 12), OUTLINE)
		_tri(img, Vector2(14, 16), Vector2(11, 8), Vector2(19, 12), Color(0.95, 0.92, 0.80))
		_tri(img, Vector2(43, 18), Vector2(47, 6), Vector2(36, 12), OUTLINE)
		_tri(img, Vector2(42, 16), Vector2(45, 8), Vector2(37, 12), Color(0.95, 0.92, 0.80))
	# Arme/Stummel
	_outlined_disc(img, 9, 30, 4, body, 2)
	_outlined_disc(img, 47, 30, 4, body, 2)
	# Augen weiß + Pupillen
	_outlined_disc(img, 22, 25, 6, Color(1, 1, 1), 2)
	_outlined_disc(img, 34, 25, 6, Color(1, 1, 1), 2)
	_disc(img, 23, 26, 2.5, Color(0.05, 0.05, 0.08))
	_disc(img, 33, 26, 2.5, Color(0.05, 0.05, 0.08))
	# Zornige Augenbrauen
	_tri(img, Vector2(16, 17), Vector2(27, 20), Vector2(16, 20), OUTLINE)
	_tri(img, Vector2(40, 17), Vector2(29, 20), Vector2(40, 20), OUTLINE)
	# Mund mit Zähnen
	_ellipse(img, cx, 38, 10, 5.5, OUTLINE)
	_ellipse(img, cx, 38, 8, 4, Color(0.40, 0.05, 0.10))
	_tri(img, Vector2(22, 35), Vector2(26, 35), Vector2(24, 40), Color(1, 1, 1))
	_tri(img, Vector2(28, 35), Vector2(32, 35), Vector2(30, 40), Color(1, 1, 1))
	_tri(img, Vector2(25, 41.5), Vector2(29, 41.5), Vector2(27, 37), Color(1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _make_monster_volt_drone() -> ImageTexture:
	# Schwebende Drohne mit blitzkern
	var img = _new_img(64, 64)
	var steel := Color(0.46, 0.50, 0.60)
	var steel_d := Color(0.24, 0.27, 0.36)
	var glow := Color(1.0, 0.86, 0.28)
	_ellipse(img, 32, 56, 18, 6, SHADOW, true)
	_outlined_ellipse(img, 32, 30, 22, 16, steel, 4)
	_outlined_disc(img, 32, 30, 9, glow, 3)
	_disc(img, 29, 27, 4, Color(1, 1, 0.9))
	_rect(img, 8, 22, 12, 5, steel_d)
	_rect(img, 44, 22, 12, 5, steel_d)
	_tri(img, Vector2(26.0, 40.0), Vector2(20.0, 54.0), Vector2(32.0, 46.0), steel_d)
	_tri(img, Vector2(38.0, 40.0), Vector2(44.0, 54.0), Vector2(32.0, 46.0), steel_d)
	return ImageTexture.create_from_image(img)


static func _make_monster_volt_trooper() -> ImageTexture:
	# Runde 49: SPULEN-TROOPER - ein starker Roboter mit gelbem
	# Spulenarm. vorher war er ein dunkler Block mit zwei gelben
	# Augen, der in der Menge unterging.
	var img = _new_img(64, 64)
	var steel := Color(0.66, 0.69, 0.78)
	var steel_d := Color(0.38, 0.41, 0.50)
	var steel_l := Color(0.86, 0.89, 0.96)
	var yellow := Color(1.0, 0.82, 0.24)
	var yellow_l := Color(1.0, 0.94, 0.60)
	_ellipse(img, 32, 58, 20, 6, SHADOW, true)
	# --- Beine (dick, gepanzert) ---
	for lx in [18, 30]:
		_rect(img, lx, 46, 10, 12, OUTLINE)
		_rect(img, lx + 1, 47, 8, 10, steel_d)
		_rect(img, lx, 55, 11, 3, OUTLINE)
	# --- Torso (breit, mit Brustplatte) ---
	_outlined_ellipse(img, 28, 38, 15, 16, steel, 3)
	_rect(img, 20, 32, 17, 10, steel_l)
	# Warnstreifen auf der Brust
	for x in range(20, 37):
		if (x + 32) % 6 < 3:
			img.set_pixel(x, 35, yellow)
	# Spulen-Kern in der Brust
	_outlined_disc(img, 28, 37, 5, yellow, 2)
	_disc(img, 27, 36, 2, yellow_l)
	# --- Kopf (mit Visier) ---
	_outlined_disc(img, 28, 18, 12, steel, 3)
	_rect(img, 19, 15, 19, 7, steel_d)
	_rect(img, 21, 17, 15, 3, yellow)
	_px(img, 24, 18, Color(1, 1, 1, 0.9))
	_px(img, 32, 18, Color(1, 1, 1, 0.9))
	# Antenne
	_rect(img, 28, 2, 2, 6, OUTLINE)
	_disc(img, 29, 2, 2, yellow)
	# --- Spulenarm rechts (die Signatur) ---
	_rect(img, 40, 24, 8, 20, OUTLINE)
	_rect(img, 41, 25, 6, 18, steel_d)
	# Spule am Arm
	_outlined_disc(img, 46, 46, 9, steel, 3)
	_outlined_disc(img, 46, 46, 5, yellow, 2)
	_disc(img, 45, 45, 2, yellow_l)
	# Stift daraus
	_tri(img, Vector2(44, 52), Vector2(38, 62), Vector2(48, 62), yellow)
	_tri(img, Vector2(45, 52), Vector2(41, 60), Vector2(47, 60), yellow_l)
	return ImageTexture.create_from_image(img)


static func _make_monster_volt_spider() -> ImageTexture:
	# Runde 49: SPULEN-SPINNE - eigener Farbton (dunkles Violett mit
	# giftgruenem Kern), sonst war sie von der Drohne kaum zu
	# unterscheiden (beide dunkelgrau mit leuchtendem Kern).
	# Dazu deutliche Spinnenbeine in drei Paaren.
	var img = _new_img(64, 64)
	var steel := Color(0.44, 0.36, 0.58)
	var steel_d := Color(0.24, 0.19, 0.34)
	var steel_l := Color(0.64, 0.55, 0.78)
	var glow := Color(0.62, 1.0, 0.42)
	_ellipse(img, 32, 58, 22, 6, SHADOW, true)
	# --- Acht Beine: je vier pro Seite, gestaffelt ---
	for s2 in [-1, 1]:
		for i2 in range(4):
			var y: float = 24.0 + float(i2) * 8.0
			var x0: int = 32 + int(s2 * 12.0)
			var x1: int = 32 + int(s2 * 24.0) - (3 if s2 > 0 else 0)
			# Oberschenkel waagerecht
			_rect(img, min(x0, x1), int(y), abs(x1 - x0) + 3, 3, steel_d)
			# Fuss nach unten
			_rect(img, x1, int(y), 3, 9 if i2 % 2 == 0 else 6, steel_d)
			_rect(img, x1, int(y), 2, 8 if i2 % 2 == 0 else 5, steel)
	# --- Koerper (breiter, flacher) ---
	_outlined_ellipse(img, 32, 36, 17, 14, steel, 3)
	# --- GIFTKERN ---
	_outlined_disc(img, 32, 36, 8, glow, 3)
	_disc(img, 29, 33, 3, Color(0.92, 1.0, 0.80))
	# --- Segment-Fugen ---
	_rect(img, 24, 26, 16, 2, steel_l)
	_rect(img, 24, 44, 16, 2, steel_l)
	return ImageTexture.create_from_image(img)


static func _make_monster_volt_spooler() -> ImageTexture:
	# Runde 49: SPULENTROOPER - ein schwerer, gepanzerter Gegner:
	# eine grosse Teslaspule als Rucksack, ein breiter Schildschild
	# in der linken Hand und ein Stab mit einer Elektro-Kugel.
	# Er ist langsam, hat viel Leben und schiesst eine Salve.
	var img = _new_img(64, 64)
	var steel := Color(0.62, 0.66, 0.76)
	var steel_d := Color(0.34, 0.38, 0.48)
	var steel_l := Color(0.84, 0.88, 0.96)
	var copper := Color(0.92, 0.56, 0.26)
	var copper_l := Color(1.0, 0.78, 0.44)
	var glow := Color(0.55, 0.92, 1.0)
	_ellipse(img, 32, 58, 18, 5, SHADOW, true)
	# --- Rucksack: Teslaspule (Ringe) ---
	_outlined_ellipse(img, 20, 30, 10, 14, steel_d, 3)
	_outlined_ellipse(img, 20, 30, 6, 10, copper, 2)
	_ellipse(img, 20, 30, 3, 7, copper_l)
	# Spulenwindungen
	for ry in [23, 28, 33, 37]:
		_rect(img, 11, ry, 18, 2, copper_l if ry % 2 == 0 else copper)
	# --- Kopf ---
	_outlined_disc(img, 40, 22, 10, steel, 3)
	# Visier
	_rect(img, 34, 19, 12, 5, steel_d)
	_rect(img, 36, 20, 8, 3, glow)
	# --- Torso ---
	_outlined_ellipse(img, 40, 38, 13, 12, steel, 3)
	# Brustplatte mit Warnstreifen
	_rect(img, 34, 34, 12, 7, steel_l)
	for x in range(34, 46):
		if (x + 34) % 5 < 2:
			img.set_pixel(x, 36, copper)
	# --- Schild (linke Hand, zum Betrachter) ---
	_outlined_ellipse(img, 26, 42, 11, 14, steel_d, 3)
	_outlined_ellipse(img, 26, 42, 8, 11, steel, 2)
	# Schild-Emblem (Blitz)
	_tri(img, Vector2(24, 48), Vector2(28, 36), Vector2(29, 45), glow)
	# --- Beine ---
	_rect(img, 34, 48, 7, 10, OUTLINE)
	_rect(img, 35, 49, 5, 9, steel_d)
	_rect(img, 42, 48, 7, 10, OUTLINE)
	_rect(img, 43, 49, 5, 9, steel_d)
	# --- Stab mit Elektro-Kugel (rechte Hand) ---
	_rect(img, 52, 30, 3, 26, OUTLINE)
	_rect(img, 53, 31, 1, 24, steel_l)
	_outlined_disc(img, 53, 26, 6, glow, 2)
	_disc(img, 52, 25, 2, Color(1, 1, 1, 0.95))
	# Funken
	_px(img, 48, 20, glow)
	_px(img, 58, 18, glow)
	_px(img, 50, 14, glow)
	return ImageTexture.create_from_image(img)


static func _make_boss_earth() -> ImageTexture:
	# Runde 34: MUTIERTER KRISTALL-ROBOTER (Erde-Riesenboss) - Panzerstand mit
	# leuchtendem Kristallkern, Kristallklinge, Schulterkristalle, Kristallkrone.
	var img = _new_img(320, 320)
	var stone := Color(0.44, 0.46, 0.52)
	var stone_d := Color(0.24, 0.26, 0.32)
	var crystal := Color(0.42, 0.82, 0.98)
	var crystal_d := Color(0.18, 0.48, 0.72)
	var glow := Color(0.60, 0.96, 1.0)
	_ellipse(img, 160, 298, 92, 20, SHADOW, true)
	_outlined_ellipse(img, 116, 250, 30, 36, stone_d, 4)
	_outlined_ellipse(img, 204, 250, 30, 36, stone_d, 4)
	_outlined_ellipse(img, 160, 178, 70, 64, stone, 6)
	_outlined_ellipse(img, 160, 186, 50, 44, stone_d, 4)
	# Kristallkern in der Brust
	_tri(img, Vector2(160.0, 136.0), Vector2(198.0, 198.0), Vector2(122.0, 198.0), OUTLINE)
	_tri(img, Vector2(160.0, 145.0), Vector2(190.0, 193.0), Vector2(130.0, 193.0), crystal)
	_tri(img, Vector2(160.0, 152.0), Vector2(173.0, 190.0), Vector2(147.0, 190.0), glow)
	# Schulterkristalle
	for s in [-1, 1]:
		var sx: float = float(s)
		_tri(img, Vector2(160.0 + sx * 52.0, 130.0), Vector2(160.0 + sx * 88.0, 98.0), Vector2(160.0 + sx * 78.0, 152.0), OUTLINE)
		_tri(img, Vector2(160.0 + sx * 54.0, 134.0), Vector2(160.0 + sx * 82.0, 106.0), Vector2(160.0 + sx * 74.0, 148.0), crystal)
	# Arme
	_outlined_ellipse(img, 92, 202, 26, 58, stone, 5)
	_outlined_ellipse(img, 228, 202, 26, 58, stone, 5)
	# Kristallklinge
	_tri(img, Vector2(236.0, 192.0), Vector2(302.0, 118.0), Vector2(262.0, 216.0), OUTLINE)
	_tri(img, Vector2(243.0, 193.0), Vector2(295.0, 128.0), Vector2(265.0, 210.0), crystal)
	_tri(img, Vector2(250.0, 195.0), Vector2(285.0, 140.0), Vector2(265.0, 203.0), glow)
	# Kopf + Kristallkrone
	_outlined_disc(img, 160, 96, 40, stone, 6)
	for i in range(5):
		var ang: float = -PI * 0.88 + float(i) * 0.44
		var bx: float = 160.0 + cos(ang) * 34.0
		var by: float = 96.0 + sin(ang) * 34.0
		_tri(img, Vector2(bx, by), Vector2(bx + cos(ang) * 30.0, by + sin(ang) * 30.0),
			Vector2(bx + cos(ang + 1.3) * 15.0, by + sin(ang + 1.3) * 15.0), crystal_d)
	_outlined_disc(img, 146, 96, 9, glow, 3)
	_outlined_disc(img, 174, 96, 9, glow, 3)
	_disc(img, 146, 96, 3, OUTLINE)
	_disc(img, 174, 96, 3, OUTLINE)
	# Runde 34b: leuchtende Kristallrisse im Stein + Halo um den Kern
	_ellipse(img, 160, 170, 74, 62, Color(0.35, 0.75, 1.0, 0.16), true)
	for cr in [[Vector2(108.0, 150.0), Vector2(96.0, 206.0), Vector2(116.0, 198.0)],
			[Vector2(214.0, 152.0), Vector2(226.0, 208.0), Vector2(204.0, 200.0)],
			[Vector2(160.0, 206.0), Vector2(154.0, 240.0), Vector2(168.0, 238.0)]]:
		_tri(img, cr[0], cr[1], cr[2], crystal_d)
		_tri(img, cr[0], cr[1], cr[2], Color(0.45, 0.85, 1.0, 0.75))
	# Nieten auf den Armen
	for i in range(3):
		_disc(img, 82, 186 + i * 16, 4, stone_d)
		_disc(img, 238, 186 + i * 16, 4, stone_d)
	# Groessere Kristallkrone
	for i in range(5):
		var ang2: float = -PI * 0.92 + float(i) * 0.46
		var bx2: float = 160.0 + cos(ang2) * 36.0
		var by2: float = 96.0 + sin(ang2) * 36.0
		_tri(img, Vector2(bx2, by2), Vector2(bx2 + cos(ang2) * 40.0, by2 + sin(ang2) * 40.0),
			Vector2(bx2 + cos(ang2 + 1.3) * 20.0, by2 + sin(ang2 + 1.3) * 20.0), OUTLINE)
		_tri(img, Vector2(bx2 + cos(ang2) * 4.0, by2 + sin(ang2) * 4.0),
			Vector2(bx2 + cos(ang2) * 36.0, by2 + sin(ang2) * 36.0),
			Vector2(bx2 + cos(ang2 + 1.3) * 16.0, by2 + sin(ang2 + 1.3) * 16.0), crystal)
	return ImageTexture.create_from_image(img)


static func _make_boss_jungle() -> ImageTexture:
	# MUTIERTER HALB-ROBOTER-GORILLA (Jungle): Gorilla-Koerper wie der Bananen-Affe,
	# aber eine Roboter-Schulter + Roboterarm mit Kralle, rotes Robo-Auge, Kabel,
	# Banane in der Hand.
	var img = _new_img(320, 320)
	var fur := Color(0.34, 0.26, 0.22)
	var fur_d := Color(0.22, 0.16, 0.14)
	var metal := Color(0.70, 0.74, 0.80)
	var metal_d := Color(0.44, 0.48, 0.55)
	var glow := Color(0.95, 0.30, 0.25)
	var face := Color(0.74, 0.62, 0.50)
	var banana := Color(0.98, 0.85, 0.30)
	_ellipse(img, 160, 296, 96, 20, SHADOW, true)
	_outlined_ellipse(img, 118, 250, 30, 34, fur_d, 4)
	_outlined_ellipse(img, 202, 250, 30, 34, metal_d, 4)
	_outlined_ellipse(img, 160, 178, 74, 66, fur, 6)
	_outlined_ellipse(img, 160, 196, 52, 48, fur_d, 4)
	_outlined_ellipse(img, 160, 172, 44, 42, metal, 5)
	_disc(img, 160, 172, 14, glow)
	_disc(img, 154, 166, 6, Color(1, 1, 1, 0.85))
	_outlined_ellipse(img, 96, 150, 40, 34, metal, 5)
	for i in range(3):
		_disc(img, 78 + i * 16, 136, 4, metal_d)
	_outlined_ellipse(img, 232, 214, 28, 62, fur, 5)
	_outlined_disc(img, 236, 278, 28, fur_d, 5)
	_outlined_ellipse(img, 88, 214, 24, 60, metal, 5)
	_outlined_disc(img, 84, 274, 24, metal_d, 5)
	for i in range(3):
		_tri(img, Vector2(float(64 + i * 16), 284.0), Vector2(float(58 + i * 16), 306.0), Vector2(float(74 + i * 16), 288.0), metal)
	_outlined_disc(img, 160, 100, 56, fur, 6)
	_outlined_ellipse(img, 160, 118, 36, 24, face, 4)
	_rect(img, 144, 126, 32, 6, OUTLINE)
	_outlined_disc(img, 100, 92, 16, fur_d, 4)
	_outlined_disc(img, 220, 92, 16, fur_d, 4)
	_outlined_disc(img, 140, 92, 10, Color(0.95, 0.95, 0.92), 3)
	_disc(img, 140, 92, 4, OUTLINE)
	_outlined_disc(img, 184, 92, 14, glow, 4)
	_disc(img, 184, 92, 6, Color(1.0, 0.75, 0.6))
	# Kabel kompakt unter der Schulterplatte (wirkten vorher aufgeklebt)
	for i in range(3):
		_rect(img, 112 + i * 7, 132 + i * 3, 4, 18, Color(0.20, 0.50, 0.40))
	_rect(img, 206, 44, 5, 34, OUTLINE)
	_disc(img, 208, 42, 7, glow)
	# Banane als klare ovale Form IN der rechten Faust (Dreieck wirkte wie eine Flosse)
	_outlined_ellipse(img, 240, 258, 30, 12, banana, 3)
	_disc(img, 214, 262, 4, Color(0.62, 0.48, 0.16))
	_disc(img, 266, 254, 4, Color(0.62, 0.48, 0.16))
	_ellipse(img, 238, 252, 16, 4, Color(1.0, 0.95, 0.6, 0.75), true)
	return ImageTexture.create_from_image(img)


static func _make_boss_mars() -> ImageTexture:
	# MUTIERTER ALIEN-ROBOTER (Mars): grosser Alien-Schaedel mit schraegen Augen
	# auf einem Maschinenkoerper mit Leuchtkern, Krallehänden, Antennen, Kabeln.
	var img = _new_img(320, 320)
	var skin := Color(0.62, 0.76, 0.60)
	var skin_d := Color(0.44, 0.58, 0.44)
	var metal := Color(0.72, 0.70, 0.66)
	var metal_d := Color(0.46, 0.44, 0.42)
	var eye := Color(0.08, 0.06, 0.10)
	var core := Color(1.0, 0.55, 0.20)
	var rust := Color(0.62, 0.34, 0.24)
	_ellipse(img, 160, 298, 100, 20, SHADOW, true)
	_outlined_ellipse(img, 160, 262, 74, 34, metal, 5)
	_outlined_ellipse(img, 160, 272, 56, 22, metal_d, 4)
	_outlined_ellipse(img, 160, 190, 62, 54, metal, 6)
	_outlined_ellipse(img, 160, 196, 42, 36, rust, 4)
	_outlined_disc(img, 160, 190, 22, core, 4)
	_disc(img, 160, 190, 10, Color(1, 1, 1, 0.8))
	_outlined_ellipse(img, 92, 168, 30, 26, metal, 5)
	_outlined_ellipse(img, 228, 168, 30, 26, metal, 5)
	_outlined_ellipse(img, 78, 214, 20, 50, metal_d, 5)
	_outlined_ellipse(img, 242, 214, 20, 50, metal_d, 5)
	for s in [-1, 1]:
		for i in range(3):
			var bx: float = 160.0 + float(s * 84) + float((i - 1) * 14)
			_tri(img, Vector2(bx, 260.0), Vector2(bx + float(s * 6), 286.0), Vector2(bx + float(s * 14), 262.0), metal)
	_rect(img, 146, 118, 28, 26, OUTLINE)
	_rect(img, 150, 120, 20, 24, skin_d)
	_outlined_ellipse(img, 160, 76, 62, 46, skin, 6)
	_outlined_ellipse(img, 160, 92, 44, 26, skin_d, 4)
	for s2 in [-1, 1]:
		var ex: int = 160 + s2 * 30
		_outlined_ellipse(img, ex, 78, 20, 12, eye, 3)
		_disc(img, ex - s2 * 5, 74, 4, Color(0.95, 0.98, 1.0, 0.9))
	_rect(img, 144, 104, 32, 4, OUTLINE)
	for i in range(2):
		_rect(img, 138 + i * 40, 22, 4, 26, OUTLINE)
		_disc(img, 140 + i * 40, 20, 6, core)
	for i in range(4):
		_rect(img, 122 + i * 12, 116, 6, 22, Color(0.35, 0.30, 0.28))
	return ImageTexture.create_from_image(img)


static func _make_boss_volt() -> ImageTexture:
	# Runde 35: DER STURMLEITER - Riesenroboter mit gewaltiger Teslaspule
	var img = _new_img(320, 320)
	var steel := Color(0.40, 0.44, 0.56)
	var steel_d := Color(0.20, 0.23, 0.32)
	var dark := Color(0.28, 0.31, 0.42)
	var glow := Color(1.0, 0.88, 0.30)
	var arc := Color(0.70, 0.95, 1.0)
	_ellipse(img, 160, 296, 96, 20, SHADOW, true)
	# Beine
	_outlined_ellipse(img, 112, 246, 32, 38, steel_d, 5)
	_outlined_ellipse(img, 208, 246, 32, 38, steel_d, 5)
	# Rumpf
	_outlined_ellipse(img, 160, 176, 76, 66, steel, 6)
	_outlined_ellipse(img, 160, 184, 54, 46, dark, 4)
	# Blitzkern
	_outlined_disc(img, 160, 168, 26, steel_d, 4)
	_outlined_disc(img, 160, 168, 17, glow, 3)
	_disc(img, 154, 162, 6, Color(1, 1, 0.92))
	# Grosse Spule auf dem Ruecken
	_outlined_ellipse(img, 160, 116, 52, 26, steel_d, 5)
	for i in range(5):
		_outlined_ellipse(img, 160, 132 - i * 14, 34 - i * 3, 8, steel, 3)
	_outlined_disc(img, 160, 74, 20, glow, 4)
	_disc(img, 160, 74, 9, Color(1, 1, 0.9))
	# Arme
	_outlined_ellipse(img, 82, 196, 26, 60, steel, 5)
	_outlined_ellipse(img, 238, 196, 26, 60, steel, 5)
	_outlined_disc(img, 82, 256, 20, steel_d, 4)
	_outlined_disc(img, 238, 256, 20, steel_d, 4)
	# Kopf mit leuchtendem Visier
	_outlined_disc(img, 160, 214, 34, dark, 5)
	_rect(img, 140, 206, 40, 10, glow)
	# Lichtbogen zwischen den Armen
	for i in range(5):
		var x0: float = 96.0 + float(i) * 30.0
		_tri(img, Vector2(x0, 150.0), Vector2(x0 + 12.0, 118.0), Vector2(x0 + 22.0, 156.0), Color(arc.r, arc.g, arc.b, 0.75))
	return ImageTexture.create_from_image(img)


static func _make_mini_earth() -> ImageTexture:
	# ROBOTER-KAEFER (Erde): Halbkugel-Panzer mit Naht und Nieten, SECHS klar
	# getrennte Beine, Fuehler, zwei Leuchtaugen, deutliche Rueckenkanone.
	var img = _new_img(224, 224)
	var shell := Color(0.42, 0.52, 0.72)
	var shell_d := Color(0.24, 0.32, 0.50)
	var metal := Color(0.76, 0.78, 0.82)
	var metal_d := Color(0.50, 0.52, 0.58)
	var glow := Color(0.98, 0.72, 0.20)
	var glow2 := Color(0.95, 0.30, 0.25)
	_ellipse(img, 112, 208, 70, 12, SHADOW, true)
	# SECHS Beine (drei je Seite, untereinander versetzt)
	for s in [-1, 1]:
		var sx: float = float(s)
		for i in range(3):
			var ly: int = 112 + i * 30
			var lx: int = 112 + int(sx * (62.0 + float(i) * 6.0))
			_rect(img, lx - (8 if s < 0 else 0), ly, 18, 13, metal_d)
			_rect(img, lx + int(sx * 13.0) - (8 if s < 0 else 0), ly + 11, 12, 28, metal)
			_disc(img, lx + int(sx * 21.0), ly + 43, 8, metal)
	# Panzer (Halbkugel) + mittlere Naht + Platten mit Nieten
	_outlined_ellipse(img, 112, 134, 66, 48, shell, 6)
	_rect(img, 108, 88, 8, 92, shell_d)
	_outlined_ellipse(img, 74, 142, 20, 26, shell_d, 3)
	_outlined_ellipse(img, 150, 142, 20, 26, shell_d, 3)
	for i in range(3):
		_disc(img, 62, 128 + i * 14, 3, metal)
		_disc(img, 162, 128 + i * 14, 3, metal)
	# Kopf + Sensor-Spalten + Fuehler
	# Runde 49c: Zwei runde, gelbe Scheiben MIT dunkler Pupille lasen
	# sich als grosses Gesichts-Auge. Jetzt: schmale waagerechte
	# Sensor-Spalten ohne Pupille - das bleibt ein Kafer-Rig.
	_outlined_disc(img, 112, 84, 28, metal, 5)
	_rect(img, 88, 78, 18, 6, OUTLINE)
	_rect(img, 89, 79, 16, 4, glow)
	_rect(img, 118, 78, 18, 6, OUTLINE)
	_rect(img, 119, 79, 16, 4, glow)
	# Kleine Warnleuchte in der Mitte statt eines dritten Auges
	_rect(img, 109, 76, 6, 4, OUTLINE)
	_rect(img, 110, 77, 4, 2, glow2)
	_rect(img, 94, 42, 4, 26, OUTLINE)
	_rect(img, 126, 42, 4, 26, OUTLINE)
	_disc(img, 96, 40, 6, glow)
	_disc(img, 128, 40, 6, glow)
	# Rueckenkanone (Sockel + Turm + Rohr + Muendung) - deutlich auf dem Panzer
	_rect(img, 148, 88, 44, 16, metal_d)
	_rect(img, 162, 58, 24, 32, metal)
	_rect(img, 170, 36, 9, 24, metal_d)
	_disc(img, 174, 34, 9, glow2)
	_disc(img, 174, 34, 3, Color(1.0, 0.9, 0.6))
	return ImageTexture.create_from_image(img)


static func _make_mini_jungle() -> ImageTexture:
	# ROBOTER-PAPAGEI (Jungle): gruenlich schimmerndes Metall, Haken-Schnabel,
	# Federkamm, rotes Robo-Auge, ausgebreitete Metallfluegel, Krallenfuesse.
	var img = _new_img(224, 224)
	var metal := Color(0.28, 0.60, 0.48)
	var metal_d := Color(0.16, 0.38, 0.32)
	var steel := Color(0.72, 0.76, 0.82)
	var steel_d := Color(0.46, 0.50, 0.56)
	var beak := Color(0.98, 0.62, 0.20)
	var glow := Color(0.95, 0.25, 0.22)
	_ellipse(img, 112, 208, 62, 12, SHADOW, true)
	# Schwanzfedern (Metall)
	_tri(img, Vector2(104.0, 150.0), Vector2(46.0, 196.0), Vector2(78.0, 168.0), steel)
	_tri(img, Vector2(110.0, 156.0), Vector2(58.0, 208.0), Vector2(86.0, 176.0), steel_d)
	_tri(img, Vector2(116.0, 152.0), Vector2(70.0, 210.0), Vector2(94.0, 178.0), steel)
	# Fluügel
	for s in [-1, 1]:
		var sx: float = float(s)
		_tri(img, Vector2(118.0 + sx * 30.0, 122.0), Vector2(118.0 + sx * 80.0, 104.0), Vector2(118.0 + sx * 62.0, 170.0), steel)
		_tri(img, Vector2(118.0 + sx * 34.0, 128.0), Vector2(118.0 + sx * 72.0, 118.0), Vector2(118.0 + sx * 58.0, 160.0), steel_d)
	# Koerper + Brustplatte mit Leuchtlicht + Metallnieten
	_outlined_ellipse(img, 118, 140, 46, 40, metal, 5)
	for i in range(3):
		_disc(img, 92, 122 + i * 18, 3, steel_d)
		_disc(img, 144, 122 + i * 18, 3, steel_d)
	_outlined_ellipse(img, 120, 150, 24, 20, steel, 4)
	_disc(img, 120, 150, 7, glow)
	# Kopf + Kamm
	_outlined_disc(img, 126, 92, 30, metal, 5)
	_tri(img, Vector2(104.0, 70.0), Vector2(110.0, 36.0), Vector2(122.0, 70.0), steel)
	_tri(img, Vector2(118.0, 66.0), Vector2(126.0, 30.0), Vector2(136.0, 66.0), glow)
	_tri(img, Vector2(132.0, 68.0), Vector2(144.0, 40.0), Vector2(150.0, 70.0), steel)
	# Rot leuchtendes Robo-Auge
	_outlined_disc(img, 138, 88, 12, glow, 3)
	_disc(img, 138, 88, 6, Color(0.30, 0.04, 0.06))
	_disc(img, 135, 85, 3, Color(1.0, 0.92, 0.88))
	# Haken-Schnabel (Ober- + Unterschnabel als Haken)
	_tri(img, Vector2(146.0, 92.0), Vector2(188.0, 100.0), Vector2(148.0, 108.0), beak)
	_tri(img, Vector2(148.0, 104.0), Vector2(180.0, 110.0), Vector2(158.0, 128.0), beak)
	_tri(img, Vector2(156.0, 116.0), Vector2(174.0, 110.0), Vector2(162.0, 126.0), Color(0.78, 0.40, 0.08))
	# Beine + Krallen
	_rect(img, 96, 170, 10, 30, metal_d)
	_rect(img, 130, 170, 10, 30, metal_d)
	for s2 in [-1, 1]:
		var ox: float = 0.0 if s2 < 0 else 34.0
		_tri(img, Vector2(84.0 + ox, 198.0), Vector2(100.0 + ox, 216.0), Vector2(114.0 + ox, 198.0), steel)
	# Antenne
	_rect(img, 150, 56, 4, 24, OUTLINE)
	_disc(img, 152, 54, 6, glow)
	return ImageTexture.create_from_image(img)


static func _make_mini_mars() -> ImageTexture:
	# ROBOTER-SONDE (Mars): schwebender Kugelkoerper mit grosser Linse,
	# Panzerring, Sensorarmen, Antenne, Triebwerksflamme.
	var img = _new_img(224, 224)
	var metal := Color(0.74, 0.72, 0.68)
	var metal_d := Color(0.44, 0.42, 0.40)
	var rust := Color(0.64, 0.36, 0.26)
	var lens := Color(1.0, 0.58, 0.18)
	var glow := Color(0.95, 0.30, 0.25)
	_ellipse(img, 112, 202, 56, 12, SHADOW, true)
	# Triebwerksflamme
	_tri(img, Vector2(94.0, 170.0), Vector2(130.0, 170.0), Vector2(112.0, 212.0), Color(1.0, 0.62, 0.24, 0.85))
	# Sensorarme
	_rect(img, 30, 110, 32, 10, metal_d)
	_rect(img, 162, 110, 32, 10, metal_d)
	_disc(img, 28, 115, 10, metal)
	_disc(img, 196, 115, 10, metal)
	# Kugelkoerper + Panzerring
	_outlined_disc(img, 112, 116, 52, metal, 6)
	_outlined_ellipse(img, 112, 116, 52, 18, rust, 4)
	# Grosse Linse
	_outlined_disc(img, 112, 110, 27, metal_d, 5)
	_outlined_disc(img, 112, 110, 18, lens, 4)
	_disc(img, 106, 104, 7, Color(1, 1, 1, 0.9))
	# Antenne + Seitenlichter
	_rect(img, 110, 34, 5, 30, OUTLINE)
	_disc(img, 112, 32, 7, glow)
	_disc(img, 72, 78, 5, glow)
	_disc(img, 152, 78, 5, glow)
	return ImageTexture.create_from_image(img)


static func _make_mini_volt() -> ImageTexture:
	# Runde 54: VOLT-SPULE - lebende Teslaspule fuer die Elektro-Karte.
	# Drei Isolatoren, gewickelter Koerper, cyaner Kern (schwacher Punkt),
	# zwei violette Spitzen mit Lichtbogen.
	var img = _new_img(224, 224)
	var body := Color(0.23, 0.25, 0.39)
	var metal := Color(0.35, 0.37, 0.48)
	var metal_l := Color(0.49, 0.53, 0.66)
	var core := Color(0.31, 0.85, 1.0)
	var core_l := Color(0.87, 0.96, 1.0)
	var vio := Color(0.64, 0.42, 1.0)

	_ellipse(img, 112, 206, 60, 11, SHADOW, true)

	# Drei Isolatoren als Beine
	for lx in [76, 140, 108]:
		_rect(img, lx - 2, 170, 20, 36, OUTLINE)
		_rect(img, lx, 172, 16, 32, metal)
		_disc(img, lx + 8, 208, 9, OUTLINE)
		_disc(img, lx + 8, 208, 6, metal_l)

	# Spulenkoerper (Kapsel)
	_rect(img, 78, 84, 68, 96, OUTLINE)
	_disc(img, 112, 84, 34, OUTLINE)
	_disc(img, 112, 180, 34, OUTLINE)
	_rect(img, 84, 84, 56, 96, body)
	_disc(img, 112, 84, 28, body)
	_disc(img, 112, 180, 28, body)

	# Windungen
	for wy in [96, 122, 148, 174]:
		_ellipse(img, 112, wy, 42, 12, metal_l)
		_ellipse(img, 112, wy, 33, 6, body)

	# Kern = schwacher Punkt
	_disc(img, 112, 138, 30, OUTLINE)
	_disc(img, 112, 138, 26, core)
	_disc(img, 112, 138, 11, core_l)
	_disc(img, 104, 130, 4, Color(1, 1, 1, 0.9), true)

	# Kopfkappe
	_rect(img, 96, 56, 32, 32, OUTLINE)
	_rect(img, 100, 59, 24, 26, metal)

	# Spitzen
	_thick_line(img, Vector2(103, 70), Vector2(78, 34), 6, metal_l)
	_thick_line(img, Vector2(121, 70), Vector2(146, 34), 6, metal_l)
	_disc(img, 78, 32, 12, OUTLINE)
	_disc(img, 78, 32, 8, vio)
	_disc(img, 146, 32, 12, OUTLINE)
	_disc(img, 146, 32, 8, vio)

	# Lichtbogen zwischen den Spitzen
	_thick_line(img, Vector2(86, 28), Vector2(98, 40), 2, core_l)
	_thick_line(img, Vector2(98, 40), Vector2(88, 46), 2, core_l)
	_thick_line(img, Vector2(88, 46), Vector2(106, 58), 2, core_l)
	_thick_line(img, Vector2(138, 28), Vector2(126, 40), 2, core)
	_thick_line(img, Vector2(126, 40), Vector2(136, 46), 2, core)
	_thick_line(img, Vector2(136, 46), Vector2(118, 58), 2, core)

	# Sensor-Schlitze
	_rect(img, 104, 64, 8, 3, core_l)
	_rect(img, 116, 64, 8, 3, core_l)

	return ImageTexture.create_from_image(img)


static func _make_mars_alien() -> ImageTexture:
	var img = _new_img(64, 64)
	var skin := Color(0.45, 0.86, 0.46)
	var suit := Color(0.86, 0.36, 0.24)
	_ellipse(img, 32, 55, 14, 4, SHADOW, true)
	_outlined_ellipse(img, 32, 38, 11, 13, suit, 3)
	_outlined_disc(img, 32, 22, 12, skin, 3)
	_outlined_disc(img, 27, 22, 5, Color(0.08, 0.08, 0.12), 1)
	_outlined_disc(img, 38, 22, 5, Color(0.08, 0.08, 0.12), 1)
	_px(img, 26, 20, Color(1, 1, 1))
	_px(img, 37, 20, Color(1, 1, 1))
	_rect(img, 31, 4, 2, 8, OUTLINE)
	_outlined_disc(img, 32, 3, 4, Color(1.0, 0.86, 0.25), 1)
	_rect(img, 40, 32, 16, 6, OUTLINE)
	_rect(img, 41, 33, 14, 4, Color(0.30, 0.32, 0.38))
	_outlined_disc(img, 44, 38, 4, skin, 2)
	return ImageTexture.create_from_image(img)


static func _make_mars_rover() -> ImageTexture:
	var img = _new_img(64, 64)
	var body := Color(0.78, 0.72, 0.62)
	var panel := Color(0.30, 0.45, 0.85)
	_ellipse(img, 32, 55, 20, 5, SHADOW, true)
	_outlined_disc(img, 16, 47, 8, Color(0.20, 0.20, 0.24), 2)
	_outlined_disc(img, 48, 47, 8, Color(0.20, 0.20, 0.24), 2)
	_rect(img, 12, 27, 40, 22, OUTLINE)
	_rect(img, 14, 29, 36, 18, body)
	_tri(img, Vector2(52, 25), Vector2(61, 38), Vector2(52, 51), Color(0.60, 0.58, 0.54))
	_rect(img, 18, 15, 28, 12, OUTLINE)
	_rect(img, 20, 17, 24, 8, panel)
	_outlined_disc(img, 32, 38, 6, Color(1.0, 0.35, 0.25), 2)
	_px(img, 31, 37, Color(1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _make_mars_drone() -> ImageTexture:
	var img = _new_img(64, 64)
	var metal := Color(0.72, 0.74, 0.80)
	var eye := Color(1.0, 0.25, 0.20)
	_ellipse(img, 32, 53, 14, 4, SHADOW, true)
	_outlined_ellipse(img, 32, 34, 20, 9, metal, 3)
	_outlined_disc(img, 32, 27, 11, Color(0.85, 0.88, 0.95), 2)
	_outlined_disc(img, 32, 27, 6, eye, 2)
	_px(img, 31, 26, Color(1, 1, 1))
	for i in range(5):
		var a := PI * (0.15 + 0.18 * float(i))
		_disc(img, int(32.0 + cos(a) * 18.0), int(34.0 + sin(a) * 8.0), 2, Color(0.55, 1.0, 0.85))
	return ImageTexture.create_from_image(img)


static func _make_mars_guard() -> ImageTexture:
	var img = _new_img(64, 64)
	var rock := Color(0.58, 0.30, 0.24)
	var plate := Color(0.78, 0.76, 0.72)
	var eye := Color(1.0, 0.55, 0.20)
	_ellipse(img, 32, 57, 20, 5, SHADOW, true)
	_outlined_ellipse(img, 22, 50, 8, 8, rock, 2)
	_outlined_ellipse(img, 42, 50, 8, 8, rock, 2)
	_outlined_ellipse(img, 32, 34, 17, 17, rock, 3)
	_outlined_ellipse(img, 41, 33, 11, 15, plate, 3)
	_rect(img, 37, 22, 8, 20, OUTLINE)
	_outlined_disc(img, 26, 17, 9, rock, 3)
	_outlined_disc(img, 25, 16, 3, eye, 1)
	return ImageTexture.create_from_image(img)


static func _make_robo_ape() -> ImageTexture:
	# Runde 18: echter Gorilla-Umriss (breite Schultern, lange Arme im
	# Knoechelgang, Schnauze, Ohren) + Robo-Teile + Banane in der Hand
	var img = _new_img(80, 80)
	var fur := Color(0.40, 0.32, 0.28)
	var fur_d := Color(0.26, 0.20, 0.18)
	var metal := Color(0.72, 0.76, 0.82)
	var face := Color(0.80, 0.68, 0.56)
	var eye := Color(0.95, 0.35, 0.30)
	var banana := Color(0.98, 0.85, 0.30)
	_ellipse(img, 40, 75, 22, 5, SHADOW, true)
	# Beine (kurz)
	_outlined_ellipse(img, 29, 65, 7, 8, fur_d, 2)
	_outlined_ellipse(img, 51, 65, 7, 8, fur_d, 2)
	# Rumpf: breite Schultern, schmaler unten
	_outlined_ellipse(img, 40, 46, 18, 16, fur, 3)
	_outlined_ellipse(img, 40, 50, 13, 12, fur_d, 2)
	# Metall-Brustplatte
	_outlined_ellipse(img, 40, 44, 10, 10, metal, 2)
	_disc(img, 40, 44, 3, Color(0.55, 0.95, 1.0))
	# lange Arme bis zum Boden
	_outlined_ellipse(img, 19, 55, 7, 16, fur, 2)
	_outlined_ellipse(img, 61, 55, 7, 16, fur, 2)
	_outlined_disc(img, 17, 71, 7, fur_d, 2)
	_outlined_disc(img, 63, 71, 7, fur_d, 2)
	# Kopf + Schnauze + Ohren
	_outlined_disc(img, 40, 28, 14, fur, 3)
	_outlined_ellipse(img, 40, 33, 9, 6, face, 2)
	_px(img, 37, 30, OUTLINE)
	_px(img, 43, 30, OUTLINE)
	_rect(img, 36, 35, 8, 2, OUTLINE)
	_outlined_disc(img, 25, 25, 4, fur_d, 2)
	_outlined_disc(img, 55, 25, 4, fur_d, 2)
	# Robo-Auge + Antenne
	_outlined_disc(img, 40, 23, 3, eye, 1)
	_rect(img, 39, 12, 2, 5, OUTLINE)
	_disc(img, 40, 11, 3, eye)
	# Banane in der rechten Hand
	_tri(img, Vector2(63, 62), Vector2(77, 70), Vector2(64, 77), banana)
	_tri(img, Vector2(64, 68), Vector2(75, 72), Vector2(65, 78), Color(0.86, 0.72, 0.24))
	return ImageTexture.create_from_image(img)


static func _make_robo_tiger() -> ImageTexture:
	# Runde 49: ROBOTER-KATZE - eine klar erkennbare Katzen-Silhouette:
	# hoher Koerper auf vier Beinen, Brust aufrecht, runder Kopf mit
	# zwei spitzen Ohren, Schnauze, leuchtendes Auge und ein Schweif
	# nach oben. Vorher war es ein flacher, gestreckter Block, der
	# eher wie ein Kabel las.
	var img = _new_img(64, 64)
	var metal := Color(0.82, 0.80, 0.72)
	var metal2 := Color(0.62, 0.60, 0.54)
	var metal3 := Color(0.94, 0.93, 0.88)
	var stripe := Color(0.16, 0.17, 0.22)
	var glow := Color(0.35, 0.95, 1.0)
	_ellipse(img, 30, 55, 17, 4, SHADOW, true)
	# --- Schweif (nach oben gebogen) ---
	_tri(img, Vector2(14, 40), Vector2(4, 22), Vector2(12, 42), OUTLINE)
	_tri(img, Vector2(13, 39), Vector2(7, 26), Vector2(12, 39), metal2)
	_rect(img, 9, 26, 3, 3, glow)
	# --- Hintere Beine ---
	for lx in [20, 34]:
		_rect(img, lx, 38, 6, 16, OUTLINE)
		_rect(img, lx + 1, 39, 4, 14, metal2)
		_rect(img, lx, 51, 7, 3, OUTLINE)
	# --- Vorderbeine (heller, naeher) ---
	for lx in [15, 29]:
		_rect(img, lx, 36, 7, 18, OUTLINE)
		_rect(img, lx + 1, 37, 5, 16, metal)
		_rect(img, lx, 50, 8, 4, OUTLINE)
		_rect(img, lx + 1, 51, 6, 2, metal2)
	# --- Koerper (hoch, Brust aufrecht) ---
	_outlined_ellipse(img, 28, 32, 15, 12, metal, 3)
	# Brustpartie heller
	_ellipse(img, 24, 30, 8, 8, metal3)
	# --- Tigerstreifen ---
	_rect(img, 22, 21, 3, 11, stripe)
	_rect(img, 28, 20, 3, 13, stripe)
	_rect(img, 34, 22, 3, 9, stripe)
	# --- Kopf (rund, gross) ---
	_outlined_disc(img, 48, 24, 12, metal, 3)
	# Backenzeichnung
	_ellipse(img, 45, 27, 7, 5, metal3)
	# --- Ohren (spitz, mit Innen) ---
	_tri(img, Vector2(40, 15), Vector2(42, 3), Vector2(47, 13), OUTLINE)
	_tri(img, Vector2(41, 14), Vector2(43, 6), Vector2(46, 13), metal)
	_tri(img, Vector2(42, 13), Vector2(43, 8), Vector2(45, 12), stripe)
	_tri(img, Vector2(50, 13), Vector2(55, 3), Vector2(57, 15), OUTLINE)
	_tri(img, Vector2(51, 13), Vector2(54, 6), Vector2(56, 14), metal)
	_tri(img, Vector2(52, 12), Vector2(54, 8), Vector2(55, 13), stripe)
	# --- Auge (leuchtend) ---
	_outlined_disc(img, 51, 21, 4, glow, 2)
	_px(img, 50, 20, Color(1, 1, 1, 0.9))
	# --- Schnauze + Nase ---
	_ellipse(img, 55, 27, 5, 4, metal3)
	_px(img, 57, 25, OUTLINE)
	_px(img, 56, 26, OUTLINE)
	# --- Zaehne ---
	_tri(img, Vector2(52, 29), Vector2(54, 33), Vector2(55, 29), Color(0.96, 0.96, 0.90))
	# --- Halsband mit Antenne ---
	_rect(img, 38, 31, 6, 3, OUTLINE)
	_rect(img, 39, 32, 4, 1, glow)
	_rect(img, 41, 26, 2, 6, OUTLINE)
	_disc(img, 42, 25, 2, glow)
	return ImageTexture.create_from_image(img)


static func _make_vine_trap() -> ImageTexture:
	var img = _new_img(64, 64)
	var stem := Color(0.18, 0.46, 0.22)
	var maw := Color(0.62, 0.18, 0.32)
	var tooth := Color(0.96, 0.96, 0.90)
	_ellipse(img, 32, 57, 16, 5, SHADOW, true)
	_rect(img, 29, 34, 6, 24, OUTLINE)
	_rect(img, 30, 36, 4, 22, stem)
	_disc(img, 22, 48, 7, stem)
	_disc(img, 42, 44, 6, stem)
	_outlined_ellipse(img, 32, 26, 16, 12, maw, 3)
	_tri(img, Vector2(18, 20), Vector2(24, 8), Vector2(30, 20), maw)
	_tri(img, Vector2(34, 20), Vector2(40, 8), Vector2(46, 20), maw)
	for i in range(5):
		var x := 20 + i * 6
		_tri(img, Vector2(x, 20), Vector2(x + 3, 13), Vector2(x + 6, 20), tooth)
	_disc(img, 32, 27, 6, Color(0.30, 0.06, 0.14))
	return ImageTexture.create_from_image(img)


static func _make_projectile() -> ImageTexture:
	var img = _new_img(20, 20)
	_disc(img, 10, 10, 7, OUTLINE)
	_disc(img, 10, 10, 5, Color(0.95, 0.90, 0.2))
	_disc(img, 9, 9, 2.5, Color(1, 1, 0.9))
	return ImageTexture.create_from_image(img)


static func _make_enemy_ball() -> ImageTexture:
	var img = _new_img(20, 20)
	_disc(img, 10, 10, 7, OUTLINE)
	_disc(img, 10, 10, 5, Color(0.95, 0.30, 0.25))
	_disc(img, 9, 9, 2.5, Color(1.0, 0.75, 0.7))
	return ImageTexture.create_from_image(img)


static func _make_muzzle_flash() -> ImageTexture:
	var img = _new_img(48, 48)
	# Sternform (4 Zipfel)
	_tri(img, Vector2(24, 2), Vector2(16, 24), Vector2(32, 24), OUTLINE)
	_tri(img, Vector2(46, 24), Vector2(24, 16), Vector2(24, 32), OUTLINE)
	_tri(img, Vector2(24, 46), Vector2(16, 24), Vector2(32, 24), OUTLINE)
	_tri(img, Vector2(2, 24), Vector2(24, 16), Vector2(24, 32), OUTLINE)
	_tri(img, Vector2(24, 5), Vector2(18, 24), Vector2(30, 24), Color(1.0, 0.55, 0.1))
	_tri(img, Vector2(43, 24), Vector2(24, 18), Vector2(24, 30), Color(1.0, 0.55, 0.1))
	_tri(img, Vector2(24, 43), Vector2(18, 24), Vector2(30, 24), Color(1.0, 0.55, 0.1))
	_tri(img, Vector2(5, 24), Vector2(24, 18), Vector2(24, 30), Color(1.0, 0.55, 0.1))
	_disc(img, 24, 24, 10, Color(1.0, 0.85, 0.2))
	_disc(img, 24, 24, 5, Color(1, 1, 0.95))
	return ImageTexture.create_from_image(img)


# ================================================================
# v1.41 (M5): drei Unterstuetzungs-Monster + Spore
# Jede Art hat eine eigene Silhouette (nicht nur eine andere Farbe).
# ================================================================

static func _make_sporenbrut() -> ImageTexture:
	# SPORENBRUT: klein, schnell, vier duenne Beine, Pilzkappe mit
	# drei Sporenballen auf dem Ruecken. Farbton 165 (Teal-Gruen).
	var img = _new_img(64, 64)
	var body := Color(0.14, 0.76, 0.28)
	var body_d := Color(0.10, 0.45, 0.17)
	var cap := Color(0.54, 0.87, 0.61)
	var spore := Color(0.86, 0.96, 0.55)
	_ellipse(img, 32, 58, 15, 5, SHADOW, true)
	# vier Beine
	_thick_line(img, Vector2(26, 42), Vector2(16, 58), 2.6, body_d)
	_thick_line(img, Vector2(30, 44), Vector2(28, 60), 2.6, body_d)
	_thick_line(img, Vector2(36, 44), Vector2(38, 60), 2.6, body_d)
	_thick_line(img, Vector2(40, 42), Vector2(50, 58), 2.6, body_d)
	# Koerper (klein, gedrungen)
	_outlined_ellipse(img, 32, 40, 12, 9, body, 3)
	# Pilzkappe
	_outlined_ellipse(img, 32, 29, 15, 8, cap, 3)
	_ellipse(img, 32, 31, 11, 4, Color(0.22, 0.56, 0.50), true)
	# drei Sporenballen auf dem Ruecken
	_disc(img, 24, 24, 3.4, OUTLINE)
	_disc(img, 24, 24, 2.4, spore)
	_disc(img, 34, 21, 3.8, OUTLINE)
	_disc(img, 34, 21, 2.8, spore)
	_disc(img, 43, 25, 3.0, OUTLINE)
	_disc(img, 43, 25, 2.1, spore)
	# schmale Augen (schnell, fiebrig)
	_rect(img, 25, 36, 5, 2, Color(1.0, 0.98, 0.65))
	_rect(img, 35, 36, 5, 2, Color(1.0, 0.98, 0.65))
	_disc(img, 27, 37, 1.0, OUTLINE)
	_disc(img, 37, 37, 1.0, OUTLINE)
	return ImageTexture.create_from_image(img)


static func _make_schild() -> ImageTexture:
	# SCHILDTRÄGER: hoher Turmschild vor dem Koerper, Kopf lugt oben
	# drueber, kurze breite Beine. Farbton 245 (Blau-Violett).
	var img = _new_img(64, 64)
	var body := Color(0.14, 0.76, 0.53)
	var body_d := Color(0.10, 0.45, 0.32)
	var pl := Color(0.24, 0.80, 0.62)
	var pl_l := Color(0.54, 0.87, 0.74)
	var gold := Color(0.98, 0.80, 0.25)
	_ellipse(img, 32, 59, 18, 4, SHADOW, true)
	# kurze breite Beine
	_outlined_ellipse(img, 24, 54, 6, 5, body_d, 2)
	_outlined_ellipse(img, 40, 54, 6, 5, body_d, 2)
	# Koerper dahinter
	_outlined_ellipse(img, 30, 38, 13, 14, body, 3)
	# Kopf lugt oben drueber
	_outlined_disc(img, 32, 20, 8, Color(0.70, 0.74, 0.92), 3)
	_rect(img, 26, 18, 13, 3, body_d)
	_disc(img, 29, 21, 1.6, Color(1.0, 0.45, 0.35))
	_disc(img, 36, 21, 1.6, Color(1.0, 0.45, 0.35))
	# Turmschild vor der Brust
	_rect(img, 30, 24, 24, 30, OUTLINE)
	_rect(img, 32, 26, 20, 26, pl)
	_rect(img, 34, 28, 16, 10, pl_l)
	_rect(img, 40, 30, 4, 20, pl_l)
	_disc(img, 42, 40, 4.2, OUTLINE)
	_disc(img, 42, 40, 3.0, gold)
	_rect(img, 30, 47, 24, 3, body_d)
	# Schildkante links (Silhouette)
	_tri(img, Vector2(30, 24), Vector2(24, 30), Vector2(30, 40), pl)
	return ImageTexture.create_from_image(img)


static func _make_herold() -> ImageTexture:
	# HEROLD: hoch aufgerichtet, Robe, Bannerstange mit Fahne, offener
	# Mund (er schreit Befehle - kein Kontaktschaden). Farbton 90.
	var img = _new_img(64, 64)
	var robe := Color(0.14, 0.73, 0.76)
	var robe_d := Color(0.10, 0.43, 0.45)
	var skin := Color(0.92, 0.84, 0.62)
	var pole := Color(0.42, 0.30, 0.18)
	var flag := Color(0.96, 0.96, 0.92)
	var flag2 := Color(0.95, 0.35, 0.30)
	_ellipse(img, 30, 61, 14, 3, SHADOW, true)
	# duenne Beine
	_thick_line(img, Vector2(27, 48), Vector2(24, 61), 2.6, robe_d)
	_thick_line(img, Vector2(35, 48), Vector2(38, 61), 2.6, robe_d)
	# Robe (lang, schmal)
	_outlined_ellipse(img, 31, 40, 11, 14, robe, 3)
	_rect(img, 21, 44, 20, 4, robe_d)
	# Bannerstange + Fahne
	_thick_line(img, Vector2(48, 12), Vector2(50, 56), 2.2, pole)
	_rect(img, 34, 10, 15, 13, OUTLINE)
	_rect(img, 35, 11, 13, 11, flag)
	_rect(img, 35, 16, 13, 3, flag2)
	_tri(img, Vector2(34, 23), Vector2(49, 23), Vector2(41, 30), flag)
	# Kopf mit offenem Mund
	_outlined_disc(img, 29, 20, 8, skin, 3)
	_rect(img, 24, 16, 4, 2, OUTLINE)
	_rect(img, 32, 16, 4, 2, OUTLINE)
	_ellipse(img, 29, 24, 3.2, 2.4, Color(0.30, 0.10, 0.16))
	# ausgestreckter Arm zur Stange
	_thick_line(img, Vector2(40, 34), Vector2(48, 22), 2.6, robe)
	_disc(img, 48, 21, 2.6, skin)
	return ImageTexture.create_from_image(img)


static func _make_spore() -> ImageTexture:
	# SPORE: winzige, halb durchsichtige Sporenkugel mit Tentakeln.
	var img = _new_img(32, 32)
	var c := Color(0.78, 0.94, 0.52, 0.92)
	var c_d := Color(0.42, 0.70, 0.32, 0.92)
	_ellipse(img, 16, 26, 9, 3, SHADOW, true)
	for i in range(4):
		var x := 9.0 + float(i) * 4.6
		_thick_line(img, Vector2(x, 18), Vector2(x - 2.0 + float(i), 27), 1.4, c_d)
	_disc(img, 16, 15, 9.0, OUTLINE)
	_disc(img, 16, 15, 7.6, c)
	_disc(img, 13, 12, 2.4, Color(1.0, 1.0, 0.88, 0.9))
	_disc(img, 19, 13, 1.6, Color(0.30, 0.50, 0.20))
	_disc(img, 14, 18, 1.4, Color(0.30, 0.50, 0.20))
	return ImageTexture.create_from_image(img)
