extends Control
# Runde 67: Kisten-Öffnen im CS:GO-Stil.
# Ein Streifen aus Item-Kacheln läuft nach rechts durch, wird langsamer und
# bleibt auf dem Gewinner-Item unter dem Marker stehen.
#
# Aufbau:  Control (clip_contents) -> HBoxContainer mit Kacheln
# Animation: EIN Tween auf position:x mit TRANS_CUBIC/EASE_OUT
# Danach: Einrasten (TRANS_BACK) + Reveal-Karte

signal finished(result: Dictionary)
signal closed()

const TILE_W := 148.0
const TILE_GAP := 14.0
const STRIP_LEN := 26
const WIN_INDEX := 18

var gm: Node = null
var result: Dictionary = {}
var strip: HBoxContainer
var win_tile: Control = null
var viewport_box: PanelContainer
var marker: ColorRect
var reveal_card: PanelContainer
var chest_img: TextureRect
var info_label: Label
var duration: float = 3.4
var _target_x: float = 0.0
var _tween: Tween = null


func setup(gmi: Node) -> void:
	gm = gmi
	duration = float(OS.get_environment("COMIC_CHEST_FAST")) if OS.get_environment("COMIC_CHEST_FAST") != "" else 3.4


func open(chest_id: String, res: Dictionary) -> void:
	result = res
	# Unter einer CanvasLayer greifen Anker nicht - Groesse explizit setzen,
	# sonst ist das Overlay 0x0 und unsichtbar.
	var vp: Vector2 = get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	size = vp
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build(chest_id)
	_animate(chest_id)
	print("[CHEST][UI] start chest=%s item=%s_%d rarity=%s dup=%s dur=%.2f" % [
		chest_id, str(res.get("kind", "?")), int(res.get("index", -1)),
		str(res.get("rarity", "?")), str(res.get("duplicate", false)), duration])


func _build(chest_id: String) -> void:
	# Layout haengt an der Bildschirmhoehe: Kiste so gross wie moeglich,
	# ohne Titel und Laufband zu beruehren (720p wie 1080p).
	var panel_top: float = size.y * 0.5 - 120.0
	var title_y: float = panel_top - 66.0
	var cs: float = clampf(size.y * 0.17, 120.0, 200.0)
	if title_y - cs - 14.0 < 8.0:
		cs = maxf(110.0, title_y - 22.0)
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = size
	dim.color = Color(0.02, 0.03, 0.06, 0.985)
	add_child(dim)

	var title := Label.new()
	title.text = "KISTE WIRD GEÖFFNET"
	title.position = Vector2(0, title_y)
	title.size = Vector2(size.x, 64)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.label_settings = _ls(40, Color(0.99, 0.80, 0.22))
	add_child(title)

	# Laufband-Fenster
	viewport_box = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.15, 1.0)
	sb.border_color = Color(0.99, 0.80, 0.22)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	viewport_box.add_theme_stylebox_override("panel", sb)
	viewport_box.position = Vector2((size.x - 1200.0) * 0.5, panel_top)
	viewport_box.size = Vector2(1200, 210)
	add_child(viewport_box)

	# Eigene Clip-Flaeche: ein PanelContainer wuerde Kinder auf seine Groesse
	# zwingen - der Streifen muss sich aber frei bewegen koennen.
	var view := Control.new()
	view.position = viewport_box.position + Vector2(3, 3)
	view.size = Vector2(1194, 204)
	view.clip_contents = true
	add_child(view)

	strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", int(TILE_GAP))
	strip.position = Vector2(0, 8)
	view.add_child(strip)

	# Marker (feste Linie in der Mitte)
	marker = ColorRect.new()
	marker.color = Color(0.99, 0.80, 0.22, 0.95)
	marker.position = Vector2(viewport_box.position.x + 598.0, viewport_box.position.y)
	marker.size = Vector2(4, 210)
	add_child(marker)

	# Kacheln: zufällige Items, Gewinner an fester Position
	var catalog: Array = gm.call("_cosmetic_catalog")
	var win_kind := str(result.get("kind", "hat"))
	var win_idx := int(result.get("index", 0))
	for i in range(STRIP_LEN):
		var e: Dictionary
		if i == WIN_INDEX:
			e = { "kind": win_kind, "index": win_idx, "rarity": str(result.get("rarity", "common")) }
		else:
			var roll := (i * 7 + 3) % 12
			if roll == 0:
				e = { "kind": "gold", "index": -1, "rarity": "gold" }
			elif roll == 1:
				e = { "kind": "gems", "index": -1, "rarity": "gems" }
			else:
				e = catalog[(i * 7 + 3) % catalog.size()]
		var tl := _tile(e, i == WIN_INDEX)
		if i == WIN_INDEX:
			win_tile = tl
		strip.add_child(tl)

	chest_img = TextureRect.new()
	chest_img.texture = TextureManager.get_texture("chest_gem_" + chest_id)
	chest_img.position = Vector2(size.x * 0.5 - 85, size.y * 0.5 - 460)
	chest_img.custom_minimum_size = Vector2.ZERO
	chest_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest_img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(chest_img)
	chest_img.size = Vector2(cs, cs)
	chest_img.position = Vector2(size.x * 0.5 - cs * 0.5, title_y - cs - 14.0)
	chest_img.pivot_offset = Vector2(cs * 0.5, cs * 0.5)
	var idle := create_tween()
	idle.set_loops()
	idle.tween_property(chest_img, "scale", Vector2(1.06, 0.96), 0.6).set_trans(Tween.TRANS_SINE)
	idle.tween_property(chest_img, "scale", Vector2(0.98, 1.03), 0.6).set_trans(Tween.TRANS_SINE)

	info_label = Label.new()
	info_label.text = ""
	info_label.position = Vector2(0, size.y * 0.5 + 125)
	info_label.size = Vector2(size.x, 44)
	info_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	info_label.label_settings = _ls(30, Color(0.90, 0.94, 0.92))
	add_child(info_label)


func _tile(e: Dictionary, highlight: bool) -> Control:
	var p := PanelContainer.new()
	var rar := str(e.get("rarity", "common"))
	var col := _rarity_color(rar)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.13, 0.20, 1.0)
	sb.border_color = col
	sb.set_border_width_all(3 if highlight else 2)
	sb.set_corner_radius_all(4)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(TILE_W, TILE_W + 12)

	var tr := TextureRect.new()
	var kind := str(e.get("kind", "hat"))
	var idx := int(e.get("index", 0))
	var tex = null
	if kind == "none" or kind == "gold" or kind == "gems":
		var lbl := Label.new()
		lbl.text = "LEER" if kind == "none" else ("GOLD" if kind == "gold" else "GEMS")
		lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
		lbl.label_settings = _ls(24, Color(0.95, 0.80, 0.30) if kind == "gold" else Color(0.55, 0.58, 0.62))
		p.add_child(lbl)
		return p
	match kind:
		"hat":
			tex = TextureManager.get_skin_hat_texture_or_player(gm.get("p_color"), gm.get("p_rig"), idx)
		"skin":
			tex = TextureManager.get_skin_hat_texture_or_player(gm.get("p_color"), idx, gm.get("p_hat"))
		"color":
			tex = TextureManager.get_skin_hat_texture_or_player(idx, gm.get("p_rig"), gm.get("p_hat"))
	if tex != null:
		tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(TILE_W - 10, TILE_W - 10)
	p.add_child(tr)
	return p


func _rarity_color(r: String) -> Color:
	match r:
		"rare":
			return Color(0.35, 0.65, 0.95)
		"epic":
			return Color(0.72, 0.45, 0.95)
		"legendary":
			return Color(0.99, 0.72, 0.20)
	return Color(0.55, 0.60, 0.68)


func _ls(size: int, col: Color) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = 4
	ls.outline_color = Color(0.03, 0.03, 0.06)
	return ls


func _animate(tier: String) -> void:
	var step: float = TILE_W + TILE_GAP
	var view_w: float = 1200.0
	var target_x: float = -1.0 * (float(WIN_INDEX) * step) + (view_w * 0.5) - (TILE_W * 0.5)
	_target_x = target_x
	strip.position = Vector2(view_w * 0.5, 22)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	# 1) Aufziehen + 2) Deckel auf mit Blitz
	_tween.tween_interval(0.30)
	_tween.tween_property(chest_img, "scale", Vector2(1.14, 0.92), 0.16).set_trans(Tween.TRANS_BACK)
	_tween.tween_callback(_flash.bind(tier))
	_tween.tween_interval(0.24)
	# 3) Laufband
	_tween.tween_callback(func(): print("[CHEST][UI] strip start target_x=%.1f" % target_x))
	_tween.tween_property(strip, "position:x", target_x, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(strip, "position:x", target_x - 4.0, 0.08)
	_tween.tween_property(strip, "position:x", target_x, 0.10)
	_tween.tween_callback(_reveal)


func _flash(tier: String) -> void:
	# Weisser Blitz zwischen geschlossenem und offenem Bild - ohne ihn springt
	# das Auge, mit ihm liest es den Deckel als "aufgeklappt".
	if chest_img != null:
		chest_img.texture = TextureManager.get_texture("chest_gem_open_" + tier)
		print("[CHEST][UI] deckel auf tier=%s" % tier)
	var fl := ColorRect.new()
	fl.color = Color(1, 1, 1, 0)
	fl.position = Vector2.ZERO
	fl.size = size
	add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 0.80, 0.07)
	tw.tween_property(fl, "color:a", 0.0, 0.17)
	tw.tween_callback(fl.queue_free)


func _reveal() -> void:
	# Exakt auf den Gewinner einrasten - sonst bleibt der Streifen durch
	# Timing/Tab-Wechsel neben dem Item stehen und zeigt das falsche Feld.
	strip.position.x = _target_x
	var rar := str(result.get("rarity", "common"))
	var label := str(result.get("name", "?"))
	var dup := bool(result.get("duplicate", false))
	var refund := int(result.get("refund", 0))
	if str(result.get("kind", "")) == "none":
		info_label.text = "NIETE  ·  diesmal nichts"
		info_label.label_settings = _ls(32, Color(0.62, 0.64, 0.70))
	elif str(result.get("kind", "")) == "gems":
		info_label.text = "TROSTPREIS  ·  +%d Edelsteine" % int(result.get("gems", 0))
		info_label.label_settings = _ls(32, Color(0.55, 0.80, 0.98))
	elif str(result.get("kind", "")) == "gold":
		info_label.text = "TROSTPREIS  ·  +%d Gold" % int(result.get("gold", 0))
		info_label.label_settings = _ls(32, Color(0.98, 0.82, 0.30))
	elif dup:
		info_label.text = "%s  ·  %s  ·  schon vorhanden  →  +%d Edelsteine" % [label, rar.to_upper(), refund]
		info_label.label_settings = _ls(30, Color(0.85, 0.86, 0.90))
	else:
		info_label.text = "%s  ·  %s  ·  NEU FREIGESCHALTET" % [label, rar.to_upper()]
		info_label.label_settings = _ls(32, _rarity_color(rar))
	# --- Gewinner-Kachel hervorheben: aufleuchten + pulsieren ---
	if win_tile != null:
		var col2: Color = _rarity_color(rar)
		var boost: float = 1.0
		match rar:
			"rare": boost = 1.06
			"epic": boost = 1.12
			"legendary": boost = 1.18
		win_tile.pivot_offset = win_tile.size * 0.5
		# Rahmen in Seltenheitsfarbe, dicker und leuchtend
		var wsb := StyleBoxFlat.new()
		wsb.bg_color = Color(0.13, 0.15, 0.22, 1.0)
		wsb.border_color = col2.lightened(0.25)
		wsb.set_border_width_all(6 if rar != "common" else 4)
		wsb.set_corner_radius_all(4)
		wsb.shadow_color = Color(col2.r, col2.g, col2.b, 0.7)
		wsb.shadow_size = 16
		win_tile.add_theme_stylebox_override("panel", wsb)
		win_tile.modulate = Color(1.4, 1.4, 1.4, 1.0)
		var pw := create_tween()
		pw.set_loops()
		pw.tween_property(win_tile, "scale", Vector2(boost, boost), 0.42) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pw.tween_property(win_tile, "scale", Vector2(1.0, 1.0), 0.42) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# Seltene Stufen bekommen zusaetzlich einen kurzen Lichtstoss
		if rar == "epic" or rar == "legendary":
			var burst := ColorRect.new()
			burst.color = Color(col2.r, col2.g, col2.b, 0.0)
			burst.position = Vector2.ZERO
			burst.size = size
			add_child(burst)
			var bt := create_tween()
			bt.tween_property(burst, "color:a", 0.35 if rar == "epic" else 0.55, 0.10)
			bt.tween_property(burst, "color:a", 0.0, 0.45)
			bt.tween_callback(burst.queue_free)
		print("[CHEST][UI] highlight rarity=%s boost=%.2f" % [rar, boost])
	info_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(info_label, "modulate:a", 1.0, 0.25)
	print("[CHEST][UI] reveal item=%s_%d rarity=%s dup=%s" % [
		str(result.get("kind", "?")), int(result.get("index", -1)), rar, str(dup)])
	finished.emit(result)

	# Weiter-Knopf
	var btn := Button.new()
	btn.text = "WEITER"
	btn.custom_minimum_size = Vector2(260, 64)
	btn.add_theme_font_size_override("font_size", 26)
	btn.position = Vector2((size.x - 260) * 0.5, size.y - 110)
	add_child(btn)
	btn.pressed.connect(func():
		closed.emit()
		queue_free())


func is_landed() -> bool:
	# Fuer Tests: steht das Gewinner-Item unter dem Marker?
	var step: float = TILE_W + TILE_GAP
	var target_x: float = -1.0 * (float(WIN_INDEX) * step) + (900.0 * 0.5) - (TILE_W * 0.5)
	return absf(strip.position.x - target_x) < 2.0
