class_name UiStyle
extends RefCounted

# Runde 138: Farben des Comic-Stils (aus ui_manager hierher, weil die
# Style-Bauer sie als Default-Parameter benutzen).
const COMIC_YELLOW := Color(0.99, 0.80, 0.22)
const COMIC_PAPER := Color(0.09, 0.12, 0.21)

# Pixel-Schrift-Cache des Shops (fruehere Member-Variablen von ui_manager).
static var _pixel_font: Font = null
static var _pixel_font_tried: bool = false


static func ImageUtils_fill_polygon(img: Image, pts: PackedVector2Array, col: Color) -> void:
	# Runde 40: einfache Polygonfuellung (Scanline) fuer den Burst
	if pts.size() < 3:
		return
	var min_y: int = int(pts[0].y)
	var max_y: int = int(pts[0].y)
	for p in pts:
		min_y = mini(min_y, int(p.y))
		max_y = maxi(max_y, int(p.y))
	for y in range(maxi(0, min_y), mini(img.get_height(), max_y + 1)):
		var xs: Array = []
		for i in range(pts.size()):
			var p1: Vector2 = pts[i]
			var p2: Vector2 = pts[(i + 1) % pts.size()]
			if (p1.y <= float(y) and p2.y > float(y)) or (p2.y <= float(y) and p1.y > float(y)):
				var t: float = (float(y) - p1.y) / (p2.y - p1.y)
				xs.append(p1.x + t * (p2.x - p1.x))
		xs.sort()
		var k: int = 0
		while k + 1 < xs.size():
			var x0: int = int(xs[k])
			var x1: int = int(xs[k + 1])
			for x in range(maxi(0, x0), mini(img.get_width(), x1 + 1)):
				img.set_pixel(x, y, col)
			k += 2


static func _make_halftone_texture(size: int = 64) -> ImageTexture:
	# Runde 40: Ben-Day-Punktraster (Comic-Halbschatten)
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for gy in range(0, size, 8):
		for gx in range(0, size, 8):
			var off: int = 4 if (gy / 8) % 2 == 0 else 0
			for dy in range(0, 4):
				for dx in range(0, 4):
					var d: float = Vector2(float(dx - 2), float(dy - 2)).length()
					if d < 2.2:
						img.set_pixel(gx + off + dx, gy + dy, Color(0, 0, 0, 0.20))
	return ImageTexture.create_from_image(img)


static func _make_burst_texture(size: int = 512) -> ImageTexture:
	# Runde 40: Comic-Strahlenburst als Hintergrund der Startseite
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size * 0.5, size * 0.5)
	var rays: int = 24
	for i in range(rays):
		var a0: float = TAU * float(i) / float(rays)
		var a1: float = a0 + TAU / float(rays) * 0.42
		var col := Color(1, 1, 1, 0.16 if i % 2 == 0 else 0.07)
		var pts := PackedVector2Array([c])
		var steps: int = 7
		for s in range(steps + 1):
			var a: float = lerp(a0, a1, float(s) / float(steps))
			pts.append(c + Vector2(cos(a), sin(a)) * size * 0.75)
		ImageUtils_fill_polygon(img, pts, col)
	return ImageTexture.create_from_image(img)


static func smooth_scroll(tag_name: String, min_height: float) -> SmoothScroll:
	# v1.46 (C1): gemeinsamer, weich laufender Scrollbereich (Challenge-Ansicht).
	var s := SmoothScroll.new()
	s.name = "Scroll_" + tag_name
	s.tag = tag_name
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, min_height)
	return s


static func _make_pixel_panel_sb(fill: Color, border: Color = Color(0.06, 0.05, 0.10), bw: int = 4, pad: int = 8) -> StyleBoxFlat:
	# Runde 43: Pixel-Kachel - harte Kanten, echter Pixel-Versatz unten
	# rechts (wie ein Sprite), helle Oberkante. Kein Rundeglanz.
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(0)
	sb.corner_detail = 1
	# Pixel-Schatten: 5 px nach unten rechts, schwarz
	sb.shadow_color = Color(0.02, 0.02, 0.05, 0.85)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(6, 6)
	sb.content_margin_left = float(pad)
	sb.content_margin_right = float(pad)
	sb.content_margin_top = float(pad)
	sb.content_margin_bottom = float(pad)
	return sb


static func _make_pixel_button(text: String, fill: Color, font_size: int = 40) -> Button:
	# Runde 43: Pixel-Knopf - kein Rundeglanz, harter Versatz nach unten
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 90)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.92, 0.92))
	btn.add_theme_stylebox_override("normal", _make_pixel_panel_sb(fill, Color(0.06, 0.05, 0.10), 4, 10))
	btn.add_theme_stylebox_override("hover", _make_pixel_panel_sb(fill.lightened(0.14), Color(0.06, 0.05, 0.10), 4, 10))
	btn.add_theme_stylebox_override("pressed", _make_pixel_panel_sb(fill.darkened(0.22), Color(0.06, 0.05, 0.10), 4, 10))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn


static func _make_label_settings(size: int, color: Color, outline: int) -> LabelSettings:
	var ls = LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = outline
	ls.outline_color = Color(0.05, 0.05, 0.1)
	ls.shadow_size = 8
	ls.shadow_color = Color(0, 0, 0, 0.4)
	ls.shadow_offset = Vector2(4, 4)
	return ls


static func _make_stylebox(bg: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(0.05, 0.05, 0.1)
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 6)
	return sb


static func _make_chip_sb(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(1, 1, 1, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 22.0
	sb.content_margin_right = 22.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


static func _comic_button_sb(fill: Color, pressed: bool = false) -> StyleBoxFlat:
	# Runde 40: Comic-Knopf - schwarzer Rand, harter Versatz zum Rausruecken
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill.darkened(0.35) if pressed else fill
	sb.border_color = Color(0.06, 0.05, 0.10)
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2.ZERO
	return sb


static func _comic_panel_sb(fill: Color, border: Color = Color(0.06, 0.05, 0.10), bw: int = 7, pad: int = 14) -> StyleBoxFlat:
	# Runde 40: echtes Comic-Panel - dicke schwarze Kontur, kein Rundeglanz
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(5, 6)
	sb.content_margin_left = float(pad)
	sb.content_margin_right = float(pad)
	sb.content_margin_top = float(pad)
	sb.content_margin_bottom = float(pad)
	return sb


static func _make_chip(text: String, bg: Color, size: int = 30) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _make_chip_sb(bg))
	var l := Label.new()
	l.text = text
	l.label_settings = _make_label_settings(size, Color(1, 1, 1), 6)
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(l)
	chip.set_meta("label", l)
	return chip


static func _make_comic_button(text: String, fill: Color, font_size: int = 40) -> Button:
	# Runde 40: Comic-Knopf mit schwarzer Kontur
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 90)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.92, 0.92))
	btn.add_theme_stylebox_override("normal", _comic_button_sb(fill))
	btn.add_theme_stylebox_override("hover", _comic_button_sb(fill.lightened(0.14)))
	btn.add_theme_stylebox_override("pressed", _comic_button_sb(fill, true))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn


static func _make_styled_button(text: String, bg: Color, font_size: int = 40) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 90)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_stylebox_override("normal", _make_stylebox(bg))
	btn.add_theme_stylebox_override("hover", _make_stylebox(bg.lightened(0.15)))
	btn.add_theme_stylebox_override("pressed", _make_stylebox(bg.darkened(0.2)))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn


static func _hud_comic_sb(alpha: float = 0.94, accent: Color = COMIC_YELLOW, radius: int = 14, pad: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COMIC_PAPER.r, COMIC_PAPER.g, COMIC_PAPER.b, alpha)
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = float(pad)
	sb.content_margin_right = float(pad)
	sb.content_margin_top = float(pad) * 0.7
	sb.content_margin_bottom = float(pad) * 0.7
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(4, 5)
	return sb


static func _hud_panel_sb(alpha: float = 0.55, radius: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, alpha)
	sb.border_color = Color(0.58, 0.70, 0.84, 0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb


static func _shop_font() -> Font:
	# Pixel-Schrift fuer den Shop. Faellt auf die Standardschrift zurueck,
	# wenn die Datei fehlt - mit klarer Meldung.
	if not _pixel_font_tried:
		_pixel_font_tried = true
		var path := "res://assets/fonts/PixelifySans.ttf"
		if ResourceLoader.exists(path):
			_pixel_font = load(path)
			print("[FONT] Pixel-Schrift geladen: %s" % path)
		else:
			print("[FONT] FEHLER: %s fehlt - Standardschrift" % path)
	return _pixel_font


static func _shop_ls(size: int, col: Color, outline: int = 6) -> LabelSettings:
	var ls := LabelSettings.new()
	if _shop_font() != null:
		ls.font = _shop_font()
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = outline
	ls.outline_color = Color(0.03, 0.03, 0.06)
	ls.shadow_size = 0
	return ls

# ============================================================
# v1.44 (R1): Bausteine im Look der Glueckswalze (slot_ui.gd)
# ============================================================

static func _slot_panel_sb(pad: int = 14, border: int = 3) -> StyleBoxFlat:
	# Automaten-Feld: dunkles Panel, duenner Goldrand, harter Versatzschatten.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.14, 0.94)
	sb.border_color = Color(0.42, 0.36, 0.24)
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = float(pad)
	sb.content_margin_right = float(pad)
	sb.content_margin_top = float(pad)
	sb.content_margin_bottom = float(pad)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(6, 6)
	return sb


static func _slot_banner(text: String, font_size: int = 40) -> Control:
	# Abschnitts-Balken: Comic-Ueberschrift in Gold, darunter eine Akzentlinie.
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 0)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	lbl.label_settings = _make_label_settings(font_size, Color(0.99, 0.80, 0.22), 9)
	holder.add_child(lbl)
	var line := ColorRect.new()
	line.color = Color(0.99, 0.80, 0.22, 0.45)
	line.custom_minimum_size = Vector2(0, 4)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(line)
	return holder


static func _slot_button(text: String, font_size: int = 28) -> Button:
	# Aktionsknopf des Automaten: gold, dunkle Schrift, harter schwarzer Versatz.
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(0.16, 0.11, 0.02))
	b.add_theme_color_override("font_hover_color", Color(0.10, 0.07, 0.01))
	b.add_theme_color_override("font_pressed_color", Color(0.20, 0.14, 0.03))
	b.add_theme_stylebox_override("normal", _slot_btn_sb(Color(0.99, 0.80, 0.22), false))
	b.add_theme_stylebox_override("hover", _slot_btn_sb(Color(1.0, 0.86, 0.34), false))
	b.add_theme_stylebox_override("pressed", _slot_btn_sb(Color(0.84, 0.66, 0.16), true))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


static func _slot_btn_sb(col: Color, pressed: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = Color(0.03, 0.03, 0.05)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(2, 2) if pressed else Vector2(5, 5)
	return sb

