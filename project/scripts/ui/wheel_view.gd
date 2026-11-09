extends Control

# v1.45 (Z3): Das gezeichnete Rad. Keine PNG-Grafik - acht Tortenstuecke aus
# Farbe + Kontur, Beschriftung im Comic-Look, Nabe in der Mitte.
# Der Winkel `winkel` dreht das Rad, 0 Grad = Segment 0 unter dem Zeiger oben.

const WM = preload("res://scripts/wheel_machine.gd")

var winkel: float = 0.0
var labels_an: bool = true
var rad_px: float = 620.0
var farben := {
	"gold": Color(0.98, 0.78, 0.20),
	"grau": Color(0.28, 0.30, 0.36),
	"blau": Color(0.30, 0.62, 0.96),
	"gruen": Color(0.28, 0.72, 0.40),
	"lila": Color(0.62, 0.34, 0.86),
}
var _slices: Array = []


func _ready() -> void:
	_slices = WM.SLICES
	custom_minimum_size = Vector2(rad_px + 60.0, rad_px + 60.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_radius(px: float) -> void:
	rad_px = px
	custom_minimum_size = Vector2(rad_px + 60.0, rad_px + 60.0)
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = rad_px * 0.5
	var n: int = _slices.size()
	if n <= 0:
		return
	var step: float = TAU / float(n)
	# Aussenkranz
	draw_circle(c, r + 14.0, Color(0.06, 0.07, 0.12, 1.0))
	draw_arc(c, r + 12.0, 0.0, TAU, 96, Color(0.98, 0.80, 0.22), 7.0, true)
	for i in range(n):
		var s: Dictionary = _slices[i]
		var a0: float = deg_to_rad(float(i) * 45.0 + winkel) - PI * 0.5
		var a1: float = a0 + step
		var col: Color = Color(0.5, 0.5, 0.5)
		if farben.has(str(s["farbe"])):
			col = farben[str(s["farbe"])]
		var pts := PackedVector2Array()
		pts.append(c)
		var seg_steps: int = 14
		for k in range(seg_steps + 1):
			var a: float = a0 + (a1 - a0) * float(k) / float(seg_steps)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, col)
		# Trennlinien (Comic-Kontur)
		draw_line(c, c + Vector2(cos(a0), sin(a0)) * r, Color(0.05, 0.05, 0.09), 5.0, true)
		# v1.48 (A2): ICON am Segmentmittelpunkt statt langem Text
		var am: float = (a0 + a1) * 0.5
		var tp: Vector2 = c + Vector2(cos(am), sin(am)) * (r * 0.70)
		if not labels_an:
			continue
		var art: String = str(s.get("art", "gold"))
		var tex: Texture2D = TextureManager.get_texture("wheel_icon_" + art)
		var icon_px: float = 72.0
		if tex != null:
			draw_texture_rect(tex, Rect2(tp - Vector2(icon_px * 0.5, icon_px * 0.66), Vector2(icon_px, icon_px)), false)
		var f: Font = ThemeDB.fallback_font
		var txt: String = _wert_text(s)
		var fs: int = 26
		var tw: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, tp + Vector2(-tw * 0.5 + 2.0, icon_px * 0.52 + 2.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(0.05, 0.05, 0.08, 0.95))
		draw_string(f, tp + Vector2(-tw * 0.5, icon_px * 0.52), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(1.0, 0.98, 0.92))
	# Nabe
	draw_circle(c, 62.0, Color(0.10, 0.11, 0.16, 1.0))
	draw_arc(c, 62.0, 0.0, TAU, 48, Color(0.98, 0.80, 0.22), 6.0, true)
	draw_circle(c, 30.0, Color(0.98, 0.80, 0.22, 0.9))


func _wert_text(s: Dictionary) -> String:
	# Kurztext unter dem Icon: Gold-Multiplikator oder Diamantenzahl.
	if int(s.get("gems", 0)) > 0:
		return "x%d" % int(s["gems"])
	if float(s.get("mult", 0.0)) > 0.0:
		return "x%d" % int(s["mult"])
	return "-"


func set_angle_deg(a: float) -> void:
	winkel = a
	queue_redraw()
