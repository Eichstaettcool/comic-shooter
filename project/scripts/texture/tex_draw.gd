class_name TexDraw
extends RefCounted

# Runde 138: Zeichenprimitive aus texture_manager.gd.
# Alle Generator-Module (gen_*.gd) erben von hier und rufen diese Funktionen
# ohne Klassenprefix auf.
const OUTLINE := Color(0.08, 0.08, 0.1)
const SHADOW := Color(0, 0, 0, 0.25)
const _AA_N: int = 4
# v1.43 (S6.2): Abtastrate fuer Dreiecks-Kanten. Grosse Flaechen (Kistenspitzen)
# laufen mit 2x2, kleine Formen mit 4x4 - sonst kostet ein Strahl ~0,5 s.
static var _aa_n: int = 4
# Anti-Alias-Schalter: war frueher eine Member-Variable von texture_manager.
# static, weil die Zeichner jetzt klassenlos (static) sind - Probe bestaetigt,
# dass abgeleitete Klassen denselben Speicher sehen.
static var _aa: bool = false


static func _new_img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)


static func _px_blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a <= 0.001:
		return
	var d: Color = img.get_pixel(x, y)
	var a = c.a + d.a * (1.0 - c.a)
	if a <= 0.0:
		return
	var r = (c.r * c.a + d.r * d.a * (1.0 - c.a)) / a
	var g = (c.g * c.a + d.g * d.a * (1.0 - c.a)) / a
	var b = (c.b * c.a + d.b * d.a * (1.0 - c.a)) / a
	img.set_pixel(x, y, Color(r, g, b, a))


static func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
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
	var inv_denom = 1.0 / denom
	var u = (dot11 * dot02 - dot01 * dot12) * inv_denom
	var v = (dot00 * dot12 - dot01 * dot02) * inv_denom
	return u >= 0 and v >= 0 and u + v < 1


static func _aa_blend(img: Image, x: int, y: int, c: Color, cov: float) -> void:
	if cov <= 0.002:
		return
	_px_blend(img, x, y, Color(c.r, c.g, c.b, c.a * cov))


static func _aa_cov_disc(x: int, y: int, cx: float, cy: float, r: float) -> float:
	var hit: int = 0
	for sy in range(_AA_N):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(_AA_N)
		for sx in range(_AA_N):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(_AA_N)
			var dx: float = px - cx
			var dy: float = py - cy
			if dx * dx + dy * dy <= r * r:
				hit += 1
	return float(hit) / float(_AA_N * _AA_N)


static func _aa_cov_ellipse(x: int, y: int, cx: float, cy: float, rx: float, ry: float) -> float:
	var hit: int = 0
	for sy in range(_AA_N):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(_AA_N)
		for sx in range(_AA_N):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(_AA_N)
			var dx: float = (px - cx) / rx
			var dy: float = (py - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				hit += 1
	return float(hit) / float(_AA_N * _AA_N)


static func _aa_cov_rect(x: int, y: int, x0: int, y0: int, w: int, h: int) -> float:
	var hit: int = 0
	for sy in range(_AA_N):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(_AA_N)
		for sx in range(_AA_N):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(_AA_N)
			if px >= float(x0) and px < float(x0 + w) and py >= float(y0) and py < float(y0 + h):
				hit += 1
	return float(hit) / float(_AA_N * _AA_N)


static func _aa_cov_tri(x: int, y: int, a: Vector2, b: Vector2, c: Vector2) -> float:
	var hit: int = 0
	var n: int = _aa_n
	for sy in range(n):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(n)
		for sx in range(n):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(n)
			if _point_in_triangle(Vector2(px, py), a, b, c):
				hit += 1
	return float(hit) / float(n * n)


static func _disc(img: Image, cx: float, cy: float, r: float, c: Color, blend: bool = false) -> void:
	for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
		for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 2):
			if _aa:
				var cov := _aa_cov_disc(x, y, cx, cy, r)
				if cov > 0.0:
					_aa_blend(img, x, y, c, cov)
			elif Vector2(float(x) - cx, float(y) - cy).length() <= r:
				if blend:
					_px_blend(img, x, y, c)
				else:
					_px(img, x, y, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color, blend: bool = false) -> void:
	for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 2):
		for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 2):
			if _aa:
				var cov := _aa_cov_ellipse(x, y, cx, cy, rx, ry)
				if cov > 0.0:
					_aa_blend(img, x, y, c, cov)
				continue
			var dx := (float(x) - cx) / rx
			var dy := (float(y) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				if blend:
					_px_blend(img, x, y, c)
				else:
					_px(img, x, y, c)


static func _tri(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, c: Color) -> void:
	# v1.43 (S6.2): Zeilenweise nur die tatsaechliche Spannweite des Dreiecks
	# abtasten. Vorher lief die Schleife ueber die ganze Bounding-Box - bei
	# langen, schmalen Strahlen (Kistenspitzen) waren 80 % der Arbeit leer und
	# ein Frame blockierte >2 s.
	var min_y := int(floor(minf(p0.y, minf(p1.y, p2.y))))
	var max_y := int(ceil(maxf(p0.y, maxf(p1.y, p2.y))))
	for y in range(min_y, max_y + 1):
		var span := _tri_row_span(y, p0, p1, p2)
		if span.y < span.x:
			continue
		var x0 := int(floor(span.x)) - 1
		var x1 := int(ceil(span.y)) + 1
		for x in range(x0, x1 + 1):
			if _aa:
				var cov := _aa_cov_tri(x, y, p0, p1, p2)
				if cov > 0.0:
					_aa_blend(img, x, y, c, cov)
			elif _point_in_triangle(Vector2(x, y), p0, p1, p2):
				_px(img, x, y, c)


# Schnitt der Waagerechten y mit dem Dreieck: x-Spannweite (x = min, y = max).
static func _tri_row_span(y: int, a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var fy: float = float(y)
	var lo: float = 1.0e9
	var hi: float = -1.0e9
	var pts := [a, b, c]
	for i in range(3):
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[(i + 1) % 3]
		if absf(q.y - p.y) < 0.000001:
			if absf(fy - p.y) < 0.5:
				lo = minf(lo, minf(p.x, q.x))
				hi = maxf(hi, maxf(p.x, q.x))
			continue
		var t: float = (fy - p.y) / (q.y - p.y)
		if t >= 0.0 and t <= 1.0:
			var xx: float = p.x + (q.x - p.x) * t
			lo = minf(lo, xx)
			hi = maxf(hi, xx)
	if lo > hi:
		return Vector2(1.0, 0.0)
	return Vector2(lo, hi)


static func _ring(img: Image, cx: float, cy: float, r: float, thickness: float, c: Color) -> void:
	for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
		for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 2):
			var d := Vector2(float(x) - cx, float(y) - cy).length()
			if d <= r and d > r - thickness:
				_px(img, x, y, c)


static func _rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for x in range(x0, x0 + w):
		for y in range(y0, y0 + h):
			_px(img, x, y, c)


static func _rect_tex(color: Color, size: int) -> ImageTexture:
	var img = _new_img(size, size)
	img.fill(color)
	return ImageTexture.create_from_image(img)


static func _outlined_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, fill: Color, ow: int) -> void:
	_ellipse(img, cx, cy, rx + ow, ry + ow, OUTLINE)
	_ellipse(img, cx, cy, rx, ry, fill)


static func _outlined_disc(img: Image, cx: float, cy: float, r: float, fill: Color, ow: int) -> void:
	_disc(img, cx, cy, r + ow, OUTLINE)
	_disc(img, cx, cy, r, fill)


static func _draw_ring(img, cx: float, cy: float, rx: float, ry: float, col: Color, width: float) -> void:
	# Einfacher Ring aus vielen kleinen Punkten (fuer Halo)
	var steps := 120
	for i in range(steps):
		var a: float = TAU * float(i) / float(steps)
		var px: float = cx + cos(a) * rx
		var py: float = cy + sin(a) * ry
		_disc(img, px, py, width, col, true)


static func _thick_line(img: Image, a: Vector2, b: Vector2, r: float, c: Color) -> void:
	# Runde 54: dicke Linie als Disc-Kette (es gibt keinen Linien-Helfer)
	var n: int = maxi(2, int(a.distance_to(b) / maxf(1.0, r * 0.55)))
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(n))
		_disc(img, p.x, p.y, r, c)


static func _px_ell(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	# Runde 49: Ellipsen-Helfer fuer die Kisten-Formen
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx: float = float(x - cx) / float(maxi(1, rx))
			var dy: float = float(y - cy) / float(maxi(1, ry))
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)


static func _px_rect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			img.set_pixel(x, y, col)


static func _px_up(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	# Rechteck mit abgerundeten oberen Ecken (Truhen-Deckel)
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if y == y0 and (x == x0 or x == x0 + w - 1):
				continue
			img.set_pixel(x, y, col)


static func _px_canvas(px: int) -> Image:
	return Image.create(px, px, false, Image.FORMAT_RGBA8)


static func _px_outline(small: Image, px: int, col: Color) -> void:
	# Runde 43: Kontur um alle gesetzten Pixel legen
	for y in range(px):
		for x in range(px):
			if small.get_pixel(x, y).a > 0.0:
				var up: bool = y + 1 < px and small.get_pixel(x, y + 1).a > 0.0
				var dn: bool = y - 1 >= 0 and small.get_pixel(x, y - 1).a > 0.0
				var lf: bool = x + 1 < px and small.get_pixel(x + 1, y).a > 0.0
				var rt: bool = x - 1 >= 0 and small.get_pixel(x - 1, y).a > 0.0
				if not (up and dn and lf and rt):
					small.set_pixel(x, y, col)


static func _quad(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	# Runde 56: quadratische Bezier fuer geschwungene Staemme/Wedel
	var u: float = 1.0 - t
	return a * u * u + b * 2.0 * u * t + c * t * t

const HEAD_ANCHOR := [21, 21, 21, 21, 21, 21, 26, 22, 24, 21, 21, 21, 21, 21, 21, 21, 21]   # v1.41 (N5): 17 Skins
# v1.42 (P11): Handanker je Skin in TEXTUR-Pixeln (64x64-Koerper).
# (56,32) ist die bisherige Waffenposition der Standard-Rigs (Offset (24,0) vom
# Zentrum, damit sich fuer die 11 alten Skins nichts aendert). Die neuen Rigs
# 11-16 zeichnen die Waffe in die rechte Hand bei (46,45) - dort sitzt die echte
# Waffe jetzt auch.
const HAND_ANCHOR := [
	[56, 32], [56, 32], [56, 32], [56, 32], [56, 32], [56, 32],
	[56, 32], [56, 32], [56, 32], [56, 32], [56, 32],
	[46, 45], [46, 45], [46, 45], [46, 45], [46, 45], [46, 45],
]
# v1.42 (P11.3): Rigs, deren Skin eine eigene Waffen-Deko zeichnet. Die Deko wird
# ausgeblendet, sobald die echte Waffe in der Hand liegt (sonst doppelt).
const RIG_DECO_WEAPON := [false, false, false, false, false, false, false, false, false, false, false,
	true, false, true, true, true, true]   # 12 (Oni) zeichnet bewusst keine Waffe
const COLOR_NAMES := ["BLAU", "ROT", "GRUEN", "GELB", "LILA", "WEISS", "ORANGE", "CYAN", "ROSA", "STAHL"]
const RIG_NAMES := ["STANDARD", "PANZERHELD", "NINJA", "ROBOTER", "COMIC-HELD", "MARS-MARSCHALL", "GEIST", "WIKINGER", "ALIEN", "SPINNENMANN", "ZOMBIE",
	"EISENKARDINAL", "ONI-FELDHERR", "EWIGER HERRSCHER", "KAPITAEN ROST", "FROSTBEIL", "GRINSER"]   # v1.41 (N5): 17 Skins
const HAT_NAMES := ["OHNE", "KAPPE", "COWBOY", "KRONE", "ZYLINDER", "WOLLMÜTZE", "PIRAT", "STROHHUT", "WIKINGER", "STERN", "HALO", "ANTENNE", "KRÖNCHEN", "STIRNBAND", "BRILLE", "ABZEICHEN", "RUCKSACK", "HÖRNER", "BLATTKRANZ", "ELEKTRO-ANTENNE", "KRISTALL-HALO", "DROHNE", "SCHULTERPLATTEN", "STERNEN-HALO", "STERNCHEN"]
const PLAYER_COLORS := [
	{ "shirt": Color(0.20, 0.60, 1.00), "pants": Color(0.15, 0.25, 0.55) },
	{ "shirt": Color(0.90, 0.24, 0.22), "pants": Color(0.45, 0.13, 0.13) },
	{ "shirt": Color(0.28, 0.78, 0.32), "pants": Color(0.13, 0.34, 0.16) },
	{ "shirt": Color(0.98, 0.82, 0.18), "pants": Color(0.50, 0.38, 0.10) },
	{ "shirt": Color(0.68, 0.30, 0.92), "pants": Color(0.30, 0.13, 0.46) },
	{ "shirt": Color(0.94, 0.94, 0.96), "pants": Color(0.42, 0.44, 0.50) },
	{ "shirt": Color(0.98, 0.52, 0.14), "pants": Color(0.46, 0.22, 0.08) },
	{ "shirt": Color(0.20, 0.84, 0.88), "pants": Color(0.10, 0.36, 0.40) },
	{ "shirt": Color(0.98, 0.42, 0.72), "pants": Color(0.46, 0.16, 0.30) },
	{ "shirt": Color(0.58, 0.64, 0.72), "pants": Color(0.26, 0.30, 0.36) }
]
const JT_LEAF_D := Color(0.11, 0.31, 0.15)
const JT_LEAF := Color(0.20, 0.52, 0.24)
const JT_LEAF_L := Color(0.38, 0.70, 0.30)
const JT_TRUNK_D := Color(0.30, 0.20, 0.12)
const JT_TRUNK := Color(0.48, 0.33, 0.19)
