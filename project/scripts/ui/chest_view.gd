class_name ChestView
extends Control

# v1.52 — Comic-Kiste als gezeichneter Knoten (nicht mehr als 64x64-Textur).
# Drei Stile, gleiche Geometrie, unterschiedliche Farbwelt und Deko:
#   STYLE_INK  — Tusche & Halbton: Holz, dicke schwarze Kontur, Punktraster im Schatten
#   STYLE_POW  — Pow-Pop: Rot/Gelb, Ben-Day-Punkte, Strahlenkranz, Comic-Stern
#   STYLE_NEON — Neon-Vault: dunkles Metall, leuchtende Kanten, Energie-Ringe
#
# Alles laeuft ueber _draw(): Deckel oeffnet sich als echte Drehung um das
# Scharnier, Koerper kann stauchen (squash) und wackeln (shake) — das ist der
# Unterschied zwischen "Textur austauschen" und "Kiste geht auf".

const STYLE_INK := 0
const STYLE_POW := 1
const STYLE_NEON := 2
const STYLE_NAMES := ["INK", "POW", "NEON"]

const DESIGN := 150.0        # Zeichenraum; wird auf die Knotengroesse skaliert

var style: int = STYLE_POW
var tier: String = "standard"      # standard / silver / premium
var lid_t: float = 0.0             # 0 = zu, 1 = 105 Grad offen
var glow_t: float = 0.0            # 0..1 Innenraum leuchtet
var shake: Vector2 = Vector2.ZERO  # Pixel in Zeichenraum-Einheiten
var squash: float = 1.0            # 1 = normal, <1 gestaucht
var rays_t: float = 0.0            # 0..1 Strahlenkranz hinter der Kiste
var burst_t: float = 0.0           # 0..1 Comic-Stern
var halftone: bool = true
var sparkle_t: float = 0.0         # 0..1 kleine Glitzerpunkte auf der Kiste

# --- Paletten -------------------------------------------------------------
const INK := Color(0.05, 0.04, 0.07)
const PAPER := Color(0.98, 0.96, 0.90)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_style(s: int) -> void:
	style = clampi(s, 0, 2)
	queue_redraw()


func set_tier(t: String) -> void:
	tier = _norm_tier(t)
	queue_redraw()


static func _norm_tier(t: String) -> String:
	# game_manager nennt die Stufen wood/silver/gold, Shop und UI
	# standard/silver/premium - beides muss dieselbe Palette treffen.
	match t:
		"wood", "standard", "holzkiste":
			return "standard"
		"gold", "premium", "goldkiste":
			return "premium"
		"silver", "silberkiste":
			return "silver"
	return "standard"


func set_state(t_lid: float = -1.0, t_glow: float = -1.0, sh: Vector2 = Vector2(-999, -999),
		sq: float = -1.0, rays: float = -1.0, burst: float = -1.0) -> void:
	if t_lid >= 0.0:
		lid_t = t_lid
	if t_glow >= 0.0:
		glow_t = t_glow
	if sh.x > -900:
		shake = sh
	if sq >= 0.0:
		squash = sq
	if rays >= 0.0:
		rays_t = rays
	if burst >= 0.0:
		burst_t = burst
	queue_redraw()


# ------------------------------------------------------------------ Palette
func _pal() -> Dictionary:
	# Grundfarben je Stil, Stufe verschiebt Metallton und Glanz
	var base: Dictionary
	match style:
		STYLE_INK:
			base = {
				"body": Color(0.76, 0.45, 0.19), "body_d": Color(0.47, 0.25, 0.09),
				"body_l": Color(0.94, 0.66, 0.32), "accent": Color(0.98, 0.80, 0.22),
				"accent_d": Color(0.66, 0.45, 0.08), "glow": Color(1.0, 0.87, 0.42),
				"bg_a": Color(0.99, 0.86, 0.30), "bg_b": Color(0.09, 0.08, 0.10),
			}
		STYLE_POW:
			base = {
				"body": Color(0.93, 0.30, 0.22), "body_d": Color(0.55, 0.10, 0.09),
				"body_l": Color(1.0, 0.56, 0.30), "accent": Color(1.0, 0.86, 0.16),
				"accent_d": Color(0.85, 0.55, 0.05), "glow": Color(1.0, 0.96, 0.62),
				"bg_a": Color(1.0, 0.80, 0.10), "bg_b": Color(0.95, 0.22, 0.30),
			}
		_:
			base = {
				"body": Color(0.11, 0.13, 0.26), "body_d": Color(0.05, 0.06, 0.14),
				"body_l": Color(0.22, 0.28, 0.48), "accent": Color(0.22, 0.96, 1.0),
				"accent_d": Color(0.10, 0.55, 0.85), "glow": Color(0.55, 0.99, 1.0),
				"bg_a": Color(0.30, 0.95, 1.0), "bg_b": Color(0.75, 0.28, 0.95),
			}
	# Neon bleibt dunkel: die Stufe faerbt dort nur das Leuchten, nicht den
	# Korpus - sonst wird aus Neon-Vault eine braune Holzkiste.
	var nur_akzent: bool = style == STYLE_NEON
	match tier:
		"silver":
			# Silber: kuehler und entsaettigt, aber die Stilfarbe bleibt stehen
			base["body"] = base["body"].lerp(Color(0.44, 0.54, 0.72), 0.88)
			base["body_d"] = base["body_d"].lerp(Color(0.28, 0.34, 0.46), 0.80)
			base["body_l"] = base["body_l"].lerp(Color(0.62, 0.72, 0.90), 0.78)
			base["accent"] = base["accent"].lerp(Color(0.86, 0.92, 1.0), 0.45)
			base["glow"] = base["glow"].lerp(Color(0.80, 0.93, 1.0), 0.5)
		"premium":
			if not nur_akzent:
				# Premium ist LILA mit Gold - nicht "goldener HolzKasten"
				base["body"] = base["body"].lerp(Color(0.50, 0.22, 0.76), 0.86)
				base["body_d"] = base["body_d"].lerp(Color(0.28, 0.10, 0.42), 0.82)
				base["body_l"] = base["body_l"].lerp(Color(0.70, 0.46, 0.94), 0.72)
			base["accent"] = base["accent"].lerp(Color(1.0, 0.95, 0.45), 0.35 if nur_akzent else 0.6)
			base["glow"] = base["glow"].lerp(Color(1.0, 0.97, 0.70), 0.5)
	return base


func _s(v: float) -> float:
	return v * (minf(size.x, size.y) / DESIGN) if DESIGN > 0.0 else v


func _p(x: float, y: float) -> Vector2:
	# Koordinaten sind um (128,128) herum gezeichnet (Design-Raum 256), skaliert
	# wird aber mit DESIGN=150 -> Bezugspunkt bleibt 128, sonst sitzt die Kiste
	# um 53 Einheiten zu tief und rechts.
	var k: float = minf(size.x, size.y) / DESIGN
	return Vector2(size.x * 0.5 + (x - 128.0) * k, size.y * 0.5 + (y - 128.0) * k) + shake * k


func _poly(pts: Array, col: Color) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(_p(float(p.x), float(p.y)))
	draw_colored_polygon(arr, col)


func _line(pts: Array, col: Color, width: float, closed: bool = true) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(_p(float(p.x), float(p.y)))
	if closed and arr.size() > 1:
		arr.append(arr[0])
	draw_polyline(arr, col, _s(width), true)


func _rect(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(_p(x, y), Vector2(_s(w), _s(h))), col)


func _disc(x: float, y: float, r: float, col: Color) -> void:
	draw_circle(_p(x, y), _s(r), col, true, -1.0, true)


# ------------------------------------------------------------------ Zeichnen
func _draw() -> void:
	var c: Dictionary = _pal()
	if rays_t > 0.01:
		_draw_rays(c)
	if burst_t > 0.01:
		_draw_burst(c)
	_draw_shadow()
	_draw_body(c)
	_draw_lid(c)
	if glow_t > 0.01:
		_draw_inner_glow(c)
	_draw_ink_edges(c)


func _draw_shadow() -> void:
	# Ellipse unter der Kiste - als Polygon, weil draw_set_transform den
	# Ursprung (0,0) skaliert und die Ellipse sonst nach oben wandert.
	var pts: Array = []
	var w: float = 66.0 * squash
	for i in range(28):
		var a: float = TAU * float(i) / 28.0
		pts.append(Vector2(128.0 + cos(a) * w, 206.0 + sin(a) * 13.0))
	var col := Color(0, 0, 0, 0.34)
	var arr := PackedVector2Array()
	for q in pts:
		arr.append(_p(q.x, q.y))
	draw_colored_polygon(arr, col)


func _draw_rays(c: Dictionary) -> void:
	# Strahlenkranz: 14 Keile, aussen hart, innen weich - comic-typisch
	var n: int = 14
	var r_in: float = 78.0 + 6.0 * (1.0 - rays_t)
	var r_out: float = 120.0 + 56.0 * rays_t
	for i in range(n):
		var a0: float = TAU * float(i) / float(n) + 0.06
		var a1: float = TAU * float(i + 0.55) / float(n)
		var col: Color = c["bg_a"] if i % 2 == 0 else c["bg_b"]
		col.a = 0.95 * rays_t
		_poly([
			Vector2(128 + cos(a0) * r_in, 120 + sin(a0) * r_in),
			Vector2(128 + cos(a0) * r_out, 120 + sin(a0) * r_out),
			Vector2(128 + cos(a1) * r_out, 120 + sin(a1) * r_out),
			Vector2(128 + cos(a1) * r_in, 120 + sin(a1) * r_in),
		], col)


func _draw_burst(c: Dictionary) -> void:
	# Comic-Stern (12 Zacken) hinter der Kiste
	var n: int = 12
	var r_out: float = 84.0 + 30.0 * burst_t
	var r_in: float = 50.0 + 8.0 * burst_t
	var pts: Array = []
	for i in range(n * 2):
		var a: float = TAU * float(i) / float(n * 2) - PI * 0.5
		var r: float = r_out if i % 2 == 0 else r_in
		pts.append(Vector2(128 + cos(a) * r, 118 + sin(a) * r * 0.92))
	# Kein dunkler Schleier: der Stern ist nur noch eine helle Kontur, die sich
	# ueber die Strahlen legt - das war der graue Keil beim Oeffnen.
	var col: Color = Color(1.0, 0.97, 0.86, 0.10 * burst_t)
	_poly(pts, col)
	var col2: Color = c["accent"]
	col2.a = 0.85 * burst_t
	_line(pts, col2, 2.5)


# Koerper-Geometrie: Trapez (oben breiter), Deckel sitzt auf der Oberkante
const BODY_W := 108.0
const BODY_H := 58.0
const BODY_TOP := 140.0


func _body_pts() -> Array:
	var w: float = BODY_W * squash
	var h: float = BODY_H / maxf(0.6, squash)
	var x0: float = 128.0 - w * 0.5
	var y0: float = BODY_TOP
	return [
		Vector2(x0, y0 + 4.0), Vector2(x0 + w, y0 + 4.0),
		Vector2(x0 + w - 5.0, y0 + h), Vector2(x0 + 5.0, y0 + h),
	]


func _draw_body(c: Dictionary) -> void:
	var pts: Array = _body_pts()
	var w: float = BODY_W * squash
	var h: float = BODY_H / maxf(0.6, squash)
	var x0: float = 128.0 - w * 0.5
	var y0: float = BODY_TOP
	_poly(pts, c["body"])
	# Schattenseite rechts
	_poly([Vector2(x0 + w * 0.66, y0 + 4.0), Vector2(x0 + w, y0 + 4.0),
		Vector2(x0 + w - 5.0, y0 + h), Vector2(x0 + w * 0.64, y0 + h)], c["body_d"])
	# Lichtkante links oben
	_poly([Vector2(x0 + 7.0, y0 + 8.0), Vector2(x0 + w * 0.26, y0 + 8.0),
		Vector2(x0 + w * 0.22, y0 + h * 0.34), Vector2(x0 + 6.0, y0 + h * 0.34)], c["body_l"].lerp(c["body"], 0.25))
	if halftone:
		_draw_halftone(Rect2(x0 + w * 0.72, y0 + h * 0.30, w * 0.24, h * 0.62), c["body_d"].darkened(0.30))
	# Eisenbaender INNEN in der Silhouette (vorher standen sie ueber den Rand)
	for t in [0.19, 0.81]:
		var bx: float = x0 + w * t
		var band: Array = [Vector2(bx - 5.5, y0 + 6.0), Vector2(bx + 5.5, y0 + 6.0),
			Vector2(bx + 4.5, y0 + h - 1.0), Vector2(bx - 6.5, y0 + h - 1.0)]
		_poly(band, c["body_d"].darkened(0.30))
		_line(band, INK, 2.5)
		_line([Vector2(bx - 5.0, y0 + 9.0), Vector2(bx - 5.0, y0 + h - 3.0)], c["accent"].darkened(0.15), 1.5, false)
	# Schlossplatte mittig
	var lp: float = y0 + h * 0.42
	_rect(128 - 16, lp - 2, 32, 30, _outline_col())
	_rect(128 - 12, lp + 2, 24, 22, c["accent"].darkened(0.12))
	_rect(128 - 12, lp + 2, 24, 3, c["accent"].lightened(0.55))
	_rect(126, lp + 8, 4, 9, Color(0.05, 0.04, 0.07))
	_disc(128, lp + 14, 4.5, Color(0.05, 0.04, 0.07))
	_disc(128, lp + 6, 2.2, _outline_col())
	_deco_body(c)
	# v1.52: Halbton ueber der ganzen Kiste nur angedeutet (Papier-Feeling)
	if halftone and style == 1:
		_draw_halftone(Rect2(x0 + 4.0, y0 + h * 0.5, w * 0.30, h * 0.45), Color(0.15, 0.10, 0.06))


func _draw_lid(c: Dictionary) -> void:
	# Flacher Deckel mit abgeschraegten Ecken - klare Comic-Form, weniger
	# Baustellen als ein Dom und passt zum flaechigen Rest des Spiels.
	# v1.52: Eine echte 2D-Drehung um 108 Grad kippt den Deckel IN die Kiste
	# (Koordinaten werden negativ). Optisch richtig ist die 3D-Klappe: Deckel
	# wandert nach oben, wird flacher und kippt leicht nach hinten.
	var ang: float = -deg_to_rad(14.0) * lid_t
	var lift: float = -10.0 * lid_t
	var flach: float = 1.0 - 0.55 * lid_t
	var half: float = 57.0 * squash
	var hh: float = 30.0
	var y_base: float = BODY_TOP + 2.0
	var ch: float = 9.0
	var local: Array = [
		Vector2(-half, 0.0), Vector2(half, 0.0),
		Vector2(half, -hh + ch), Vector2(half - ch, -hh),
		Vector2(-half + ch, -hh), Vector2(-half, -hh + ch),
	]
	var pts: Array = []
	for q in local:
		var r := Vector2(q.x, q.y * flach).rotated(ang)
		pts.append(Vector2(128 + r.x, y_base + r.y + lift))
	_poly(pts, c["body_l"])
	# untere Schattenkante des Deckels
	var strip: Array = []
	for q in [local[0], local[1], Vector2(half, -hh * 0.24), Vector2(-half, -hh * 0.24)]:
		var r := Vector2(q.x, q.y * flach).rotated(ang)
		strip.append(Vector2(128 + r.x, y_base + r.y + lift))
	_poly(strip, c["body_d"])
	# zwei Baender, exakt ueber denen des Korpus
	for t in [-0.62, 0.62]:
		var bx: float = half * t
		var band: Array = []
		for q in [Vector2(bx - 5.5, 1.0), Vector2(bx + 5.5, 1.0),
				Vector2(bx + 4.5, -hh + 2.0), Vector2(bx - 6.5, -hh + 2.0)]:
			var r := Vector2(q.x, q.y * flach).rotated(ang)
			band.append(Vector2(128 + r.x, y_base + r.y + lift))
		_poly(band, c["body_d"].darkened(0.28))
		_line(band, _outline_col(), 1.5)
	# Kontur
	_line(pts, _outline_col(), 4.0)
	_line(pts, Color(0.06, 0.05, 0.08, 0.30), 1.4)
	_deco_lid(c, ang, half, hh, y_base, flach)
	# Glanzkante
	var gl: Array = []
	for q in [Vector2(-half + 11.0, -hh + 3.0), Vector2(half * 0.30, -hh + 3.0)]:
		var r := Vector2(q.x, q.y * flach).rotated(ang)
		gl.append(Vector2(128 + r.x, y_base + r.y + lift))
	_line(gl, PAPER.lerp(c["body_l"], 0.55), 2.5, false)


func _tier_key() -> String:
	return _norm_tier(tier)


func _deco_body(c: Dictionary) -> void:
	# v1.53: Die drei Stufen muessen sich im DESIGN unterscheiden, nicht nur im
	# Farbton: Holz hat Planken + Naegel, Silber Nieten + blauen Stein,
	# Premium Goldkanten + lila Stein.
	var w: float = BODY_W * squash
	var h: float = BODY_H / maxf(0.6, squash)
	var x0: float = 128.0 - w * 0.5
	var y0: float = BODY_TOP
	match _tier_key():
		"standard":
			# Plankenfaugen + Eisennaegel
			for i in range(1, 3):
				var yy: float = y0 + h * float(i) / 3.0
				_line([Vector2(x0 + 8.0, yy), Vector2(x0 + w - 8.0, yy)],
					c["body_d"].darkened(0.35), 1.6, false)
			for nx in [x0 + 12.0, x0 + w - 12.0]:
				for ny in [y0 + 12.0, y0 + h - 12.0]:
					_disc(nx, ny, 2.6, c["accent"].darkened(0.25))
		"silver":
			# Nieten entlang der Baender + blauer Stein im Schloss
			for t in [0.19, 0.81]:
				var bx: float = x0 + w * t
				for k in range(4):
					var ny2: float = y0 + 10.0 + (h - 20.0) * float(k) / 3.0
					_disc(bx - 1.0, ny2, 2.2, Color(0.88, 0.93, 1.0))
					_disc(bx - 1.0, ny2 + 1.0, 1.1, Color(0.45, 0.50, 0.62))
			_disc(128, y0 + h * 0.42 + 13.0, 4.4, Color(0.35, 0.72, 0.95))
			_disc(126.8, y0 + h * 0.42 + 11.5, 1.6, Color(0.85, 0.97, 1.0))
		"premium":
			# Goldkanten unten + zwei Steine
			_line([Vector2(x0 + 6.0, y0 + h - 4.0), Vector2(x0 + w - 6.0, y0 + h - 4.0)],
				Color(0.99, 0.84, 0.28), 3.0, false)
			_disc(128, y0 + h * 0.42 + 13.0, 4.6, Color(0.86, 0.36, 0.92))
			_disc(126.6, y0 + h * 0.42 + 11.4, 1.7, Color(1.0, 0.86, 1.0))
			for gx in [x0 + 16.0, x0 + w - 16.0]:
				_disc(gx, y0 + h - 10.0, 3.0, Color(0.99, 0.84, 0.28))
				_disc(gx - 0.8, y0 + h - 11.0, 1.2, Color(1.0, 0.96, 0.70))


func _deco_lid(c: Dictionary, ang: float, half: float, hh: float, y_base: float, flach: float) -> void:
	match _tier_key():
		"standard":
			# einfache Eisenklammern
			for bx in [-half * 0.62, half * 0.62]:
				var q := Vector2(bx, -hh * 0.5).rotated(ang)
				_disc(128 + q.x, y_base + q.y + (-10.0 * flach), 2.4, c["accent"].darkened(0.3))
		"silver":
			for bx in [-half * 0.62, half * 0.62]:
				for k in range(3):
					var q2 := Vector2(bx, -hh * (0.25 + 0.25 * float(k)) * flach).rotated(ang)
					_disc(128 + q2.x, y_base + q2.y - 10.0 * flach, 2.0, Color(0.90, 0.95, 1.0))
		"premium":
			# KEINE Zacken (der Nutzer hat sie zweimal als Fehler gelesen):
			# Premium unterscheidet sich ueber Goldkante, Steine und Farbe.
			var edge: Array = []
			for q4 in [Vector2(-half + 9.0, -hh + 2.0), Vector2(half - 9.0, -hh + 2.0)]:
				var r4 := Vector2(q4.x, q4.y * flach).rotated(ang)
				edge.append(Vector2(128 + r4.x, y_base + r4.y - 10.0 * flach))
			_line(edge, Color(0.99, 0.84, 0.28), 3.0, false)
			for gx in [-half * 0.40, half * 0.40]:
				var q5 := Vector2(gx, -hh * 0.5).rotated(ang)
				_disc(128 + q5.x, y_base + q5.y - 10.0 * flach, 3.0, Color(0.99, 0.86, 0.35))
				_disc(128 + q5.x - 0.9, y_base + q5.y - 11.0 * flach, 1.2, Color(1.0, 0.98, 0.82))


func _draw_inner_glow(c: Dictionary) -> void:
	# Leuchtender Spalt zwischen Deckel und Koerper + Lichtkegel nach oben
	var w: float = (BODY_W - 8.0) * squash
	var y0: float = BODY_TOP + 2.0
	var col: Color = c["glow"]
	col.a = 0.30 + 0.35 * glow_t
	draw_rect(Rect2(_p(128 - w * 0.5, y0 - 4.0), Vector2(_s(w), _s(9.0 + 6.0 * glow_t))), col)


func _draw_halftone(area: Rect2, col: Color) -> void:
	# Ben-Day-Punktraster, 45 Grad versetzt
	var step: float = 5.5
	var r: float = 1.45
	var c := col
	c.a = 0.32
	var yy: float = area.position.y
	while yy < area.position.y + area.size.y:
		var xx: float = area.position.x + (step * 0.5 if int((yy - area.position.y) / step) % 2 == 1 else 0.0)
		while xx < area.position.x + area.size.x:
			_disc(xx, yy, r, c)
			xx += step
		yy += step


func _outline_col() -> Color:
	# Auf Papier (Stil 1) schwarze Tusche, auf dunklem Grund helle Kontur -
	# eine schwarze Kontur auf fast schwarzem Hintergrund ist unsichtbar.
	if style == STYLE_INK:
		return INK
	return Color(0.97, 0.95, 0.88)


func _draw_ink_edges(c: Dictionary) -> void:
	# Kontur zuletzt: dadurch liegt sie ueber allen Flaechen
	var oc: Color = _outline_col()
	_line(_body_pts(), oc, 5.0)
	# Kistenkanten betonen
	var pts: Array = _body_pts()
	_line([pts[0], pts[1]], oc, 5.0, false)
	# Doppelkontur: innen eine dunkle Linie, damit die Form auf hellem Grund steht
	_line(_body_pts(), Color(0.06, 0.05, 0.08, 0.55), 2.0)
	if style == STYLE_NEON:
		_line(_body_pts(), c["accent"], 2.0)
		_disc(128, 172, 9.0 + 12.0 * glow_t, Color(c["accent"].r, c["accent"].g, c["accent"].b, 0.30 * (0.4 + glow_t)))
