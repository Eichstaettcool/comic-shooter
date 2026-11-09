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
# v1.39 B5: Gewinner-Position ist pro Oeffnung zufaellig (14..22).
var _win_index: int = WIN_INDEX

var gm: Node = null
var result: Dictionary = {}
var strip: HBoxContainer
var win_tile: Control = null
var viewport_box: PanelContainer
var marker: ColorRect
var reveal_card: PanelContainer
var chest_img: TextureRect
var spike_img: TextureRect = null
var info_label: Label
var duration: float = 6.0
var _target_x: float = 0.0
var _start_x: float = 0.0
var _spinning: bool = false
var _tick_timer: Timer = null
var _next_tick_tile: int = 0
var _tick_count: int = 0
var _slow_ticks: int = 0
var _tick_times: Array = []   # v1.44 (A4): Zeitpunkte fuer den Abstands-Beleg
const TICK_EVERY_TILES := 4        # Runde 136: Klick alle 4 Kacheln im Laufband
var _tween: Tween = null
# v1.39 B: Skip-Knopf + Messpunkte
var _skip_btn: Button = null
var _done: bool = false
var _t_start: int = 0
var _total_anim: float = 0.0
var _tier: String = ""
# v1.39 B5: Signatur des Laufbands (fuer den Beleg "jedes Mal neu")
var strip_sig: String = ""


func setup(gmi: Node) -> void:
	gm = gmi
	# Runde 122 (D2): Dauer zufaellig 4,5-8,0 s. Der Gewinn steht vorher fest,
	# die Dauer ist reine Optik.
	var env_dur: String = OS.get_environment("COMIC_CHEST_FAST")
	duration = float(env_dur) if env_dur != "" else randf_range(4.5, 8.0)
	print("[CHEST][DUR] Animationsdauer=%.2f s (Vorgabe 4,5-8,0)" % duration)


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
	print("[CHEST][SKIP] bereit=%s tasten=ui_cancel" % str(_skip_btn != null))


func _build(chest_id: String) -> void:
	_tier = chest_id
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

	# D1: Spitzen sind eine EIGENE Ebene mit festem Ursprung. Sie liegt VOR dem
	# Dim, aber HINTER Titel/Laufband/Kiste - deshalb wird sie als erstes Kind
	# nach dem Dim angelegt und beim Oeffnen nur eingeblendet, nie verschoben.
	var s_size: float = cs * 1.35
	spike_img = TextureRect.new()
	spike_img.name = "ChestSpikes"
	spike_img.texture = TextureManager.get_texture("chest_spikes_" + chest_id)
	spike_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spike_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spike_img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spike_img.size = Vector2(s_size, s_size)
	# Ursprung der Strahlen = Bildmitte / 62 % Hoehe der eigenen Kachel
	spike_img.position = Vector2(
		size.x * 0.5 - s_size * 0.5,
		(title_y - cs - 14.0) + cs * 0.52 - s_size * 0.62)
	spike_img.visible = false
	spike_img.modulate = Color(1, 1, 1, 0)
	add_child(spike_img)
	if spike_img.texture == null:
		print("[CHEST][SPIKES] FEHLER: Textur chest_spikes_%s fehlt" % chest_id)
	else:
		print("[CHEST][SPIKES] stufe=%s eigene ebene pos=(%.0f,%.0f) groesse=%.0f (statisch, hinter der Kiste)"
			% [chest_id, spike_img.position.x, spike_img.position.y, s_size])

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

	# Kacheln: v1.39 B5 - Laufband JEDES Mal neu wuerfeln (Reihenfolge,
	# Nieten und Gewinner-Position). Vorher stand die Nieten-Reihe fest
	# ((i*7+3) % n), deshalb zeigte jede Kiste dieselben Items in derselben
	# Reihenfolge - "immer die gleiche Gewinnauswahl".
	var catalog: Array = gm.call("_cosmetic_catalog")
	var win_kind := str(result.get("kind", "hat"))
	var win_idx := int(result.get("index", 0))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pool: Array = []
	# Der Gewinn darf als Niete NICHT noch einmal auftauchen (sonst steht
	# dieselbe Kachel zweimal im Band).
	for e0 in catalog:
		if str(e0.get("kind", "")) == win_kind and int(e0.get("index", -2)) == win_idx:
			continue
		pool.append(e0)
	pool.shuffle()
	var decoys: Array = []
	# 1 von 7 Nieten ist ein Trostpreis (Gold/Edelsteine), Rest aus dem Katalog
	var runden: int = 0
	while decoys.size() < STRIP_LEN - 1:
		for e0 in pool:
			if decoys.size() >= STRIP_LEN - 1:
				break
			if runden > 0 and rng.randi_range(0, 6) == 0:
				# Trostpreis statt Katalog-Item
				if rng.randi_range(0, 1) == 0:
					decoys.append({ "kind": "gold", "index": -1, "rarity": "gold",
						"gold": rng.randi_range(10, 250) })
				else:
					decoys.append({ "kind": "gems", "index": -1, "rarity": "gems",
						"gems": rng.randi_range(1, 5) })
			else:
				decoys.append(e0)
		pool.shuffle()
		runden += 1
	_win_index = rng.randi_range(14, 22)
	var sig: String = ""
	var di: int = 0
	for i in range(STRIP_LEN):
		var e: Dictionary
		if i == _win_index:
			e = { "kind": win_kind, "index": win_idx, "rarity": str(result.get("rarity", "common")),
				"gold": int(result.get("gold", 0)), "gems": int(result.get("gems", 0)) }
		else:
			e = decoys[di]
			di += 1
		sig += "%s:%d|" % [str(e.get("kind", "?")), int(e.get("index", -1))]
		var tl := _tile(e, i == _win_index)
		if i == _win_index:
			win_tile = tl
		strip.add_child(tl)
	print("[CHEST][STRIP] gewinner_pos=%d hash=%d katalog=%d nieten=%d" % [
		_win_index, sig.hash(), catalog.size(), decoys.size()])
	strip_sig = sig

	chest_img = TextureRect.new()
	chest_img.texture = TextureManager.get_texture("chest_gem_" + chest_id)
	chest_img.position = Vector2(size.x * 0.5 - 85, size.y * 0.5 - 460)
	chest_img.custom_minimum_size = Vector2.ZERO
	chest_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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

	# v1.39 B1: Skip-Knopf - ab dem ersten Frame sichtbar, oben rechts,
	# damit er Kiste, Titel und Laufband nicht verdeckt.
	_skip_btn = Button.new()
	_skip_btn.name = "ChestSkip"
	_skip_btn.text = "UEBERSPRINGEN  >>"
	_skip_btn.custom_minimum_size = Vector2(360, 74)
	_skip_btn.add_theme_font_size_override("font_size", 26)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.14, 0.17, 0.25, 0.96)
	ssb.border_color = Color(0.99, 0.80, 0.22)
	ssb.set_border_width_all(4)
	ssb.set_corner_radius_all(4)
	ssb.shadow_color = Color(0, 0, 0, 0.6)
	ssb.shadow_offset = Vector2(5, 5)
	_skip_btn.add_theme_stylebox_override("normal", ssb)
	var sssb: StyleBoxFlat = ssb.duplicate()
	sssb.bg_color = Color(0.20, 0.24, 0.34, 0.98)
	_skip_btn.add_theme_stylebox_override("hover", sssb)
	var spsb: StyleBoxFlat = ssb.duplicate()
	spsb.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	spsb.shadow_offset = Vector2(2, 2)
	_skip_btn.add_theme_stylebox_override("pressed", spsb)
	_skip_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_skip_btn.position = Vector2(size.x - 400.0, 26.0)
	_skip_btn.pressed.connect(_skip)
	add_child(_skip_btn)


func _tile(e: Dictionary, highlight: bool) -> Control:
	var p := PanelContainer.new()
	var rar := str(e.get("rarity", "common"))
	var col := _rarity_color(rar)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.13, 0.20, 1.0)
	sb.border_color = col
	# Runde 124 (D4): Rahmen nach Seltenheit unterscheidbar
	var bw := 3
	match rar:
		"rare": bw = 4
		"epic": bw = 5
		"legendary": bw = 6
	sb.set_border_width_all(bw if highlight else maxi(2, bw - 1))
	sb.set_corner_radius_all(4)
	match rar:
		"rare":
			sb.shadow_color = Color(0.30, 0.60, 1.0, 0.35)
			sb.shadow_size = 7
		"epic":
			sb.shadow_color = Color(0.75, 0.35, 1.0, 0.5)
			sb.shadow_size = 11
		"legendary":
			sb.shadow_color = Color(1.0, 0.85, 0.30, 0.6)
			sb.shadow_size = 15
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(TILE_W, TILE_W + 12)
	if highlight and (rar == "epic" or rar == "legendary"):
		var pulse := p.create_tween().set_loops()
		pulse.tween_property(p, "modulate", Color(1.25, 1.25, 1.25, 1.0), 0.55).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(p, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55).set_trans(Tween.TRANS_SINE)
		print("[CHEST][FRAME] Puls aktiv fuer Seltenheit=%s" % rar)

	var tr := TextureRect.new()
	var kind := str(e.get("kind", "hat"))
	var idx := int(e.get("index", 0))
	var tex = null
	if kind == "none":
		var lbl := Label.new()
		lbl.text = "LEER"
		lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
		lbl.label_settings = _ls(24, Color(0.55, 0.58, 0.62))
		p.add_child(lbl)
		return p
	if kind == "gold" or kind == "gems":
		# Runde 95: 1 / 2 / 3 Symbole je nach Hoehe - man sieht sofort,
		# ob es ein kleiner oder grosser Trostpreis ist.
		var amount: int = int(e.get("gold", 0)) if kind == "gold" else int(e.get("gems", 0))
		var level: int = 1
		if kind == "gold":
			if amount >= 250: level = 3
			elif amount >= 100: level = 2
		else:
			if amount >= 25: level = 3
			elif amount >= 10: level = 2
		var sym := "slot_gold%d" % level if kind == "gold" else "slot_gem%d" % level
		var tex2 = TextureManager.get_texture(sym)
		if tex2 == null:
			print("[CHEST][UI] FEHLER: Textur %s fehlt fuer %s x%d" % [sym, kind, amount])
			tex2 = TextureManager.get_texture("slot_gold1")
		var tr2 := TextureRect.new()
		tr2.texture = tex2
		tr2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr2.custom_minimum_size = Vector2(TILE_W - 14, TILE_W - 30)
		p.add_child(tr2)
		var cl := Label.new()
		cl.text = ("+%d" % amount)
		cl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		cl.label_settings = _ls(18, Color(0.98, 0.86, 0.40) if kind == "gold" else Color(0.60, 0.90, 1.0))
		p.add_child(cl)
		return p
	# Runde 96: Jede Kategorie zeigt NUR das, was man gewinnt.
	match kind:
		"hat":
			tex = TextureManager.get_hat_only_texture(idx)
		"skin":
			tex = TextureManager.get_skin_texture(int(gm.get("p_color")), idx)
		"color":
			tex = TextureManager.get_skin_texture(idx, int(gm.get("p_rig")))
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
	var target_x: float = -1.0 * (float(_win_index) * step) + (view_w * 0.5) - (TILE_W * 0.5)
	_target_x = target_x
	# v1.39 B: Startzeit + Gesamtlaenge fuer Restzeit-Log beim Skip
	_t_start = Time.get_ticks_msec()
	_total_anim = 0.46 + duration + 0.18
	print("[CHEST][DUR] gesamt=%.2f s (0,46 + %.2f + 0,18)" % [_total_anim, duration])
	strip.position = Vector2(view_w * 0.5, 22)
	_start_x = strip.position.x
	# G1-1: Rasseln beim Start (Zahnrad, Deckel sitzt noch)
	SoundManager.play("chest_lock")
	print("[CHEST][SND] lock -> Rasseln startet (0,35 s)")
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	# 1) Aufziehen + 2) Deckel auf mit Blitz
	_tween.tween_interval(0.30)
	_tween.tween_property(chest_img, "scale", Vector2(1.14, 0.92), 0.16).set_trans(Tween.TRANS_BACK)
	_tween.tween_callback(_flash.bind(tier))
	# Runde 136 (C2): KEIN tween_interval mehr nach dem Blitz. Das Laufband
	# startet im selben Tween direkt nach dem Deckel - vorher klaffte hier
	# ein 0,24-s-Loch, in dem das Bild stand.
	# 3) Laufband: eine durchgehende Bewegung in zwei Geschwindigkeitsphasen
	_tween.tween_callback(_start_strip)
	# v1.44 (A1): SOFORT schnell, dann auslaufen. Vorher wurde 45 % der Zeit
	# erst beschleunigt (EASE_IN) - genau das "langsam rein", das der Nutzer
	# nicht will. Jetzt: Phase 1 20 % LINEAR (volle Geschwindigkeit ab Frame 1),
	# Phase 2 80 % auslaufend mit TRANS_QUART.
	# Stetiger Uebergang: bei QUART/EASE_OUT ist die Startgeschwindigkeit
	# 4 * Strecke / Zeit -> mit t1 = 0,2 d und t2 = 0,8 d muss die erste Phase
	# genau die HAELFTE der Strecke legen (d1 == d2), sonst springt das Band.
	var mid_x: float = lerpf(strip.position.x, target_x, 0.50)
	var t1: float = duration * 0.20
	var t2: float = duration * 0.80
	print("[CHEST][SPEED] phasen=linear20+out80 quartic_nach_quad max_speed_frac=0.20 t1=%.2f t2=%.2f d1=%.0f d2=%.0f" % [
		t1, t2, absf(mid_x - strip.position.x), absf(target_x - mid_x)])
	_tween.tween_property(strip, "position:x", mid_x, t1).set_trans(Tween.TRANS_LINEAR)
	# v1.44 (A1, gemessen): TRANS_QUART laesst das Band in den letzten 0,75 s
	# nur 0,01-0,03 % der Strecke legen - das sieht wie ein Haenger aus, nicht
	# wie Auslaufen. TRANS_QUAD haelt ~2 % und bleibt sichtbar in Bewegung.
	_tween.tween_property(strip, "position:x", target_x, t2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(strip, "position:x", target_x - 4.0, 0.08)
	_tween.tween_property(strip, "position:x", target_x, 0.10)
	_tween.tween_callback(_land)
	_tween.tween_callback(_reveal)


func _start_strip() -> void:
	# Laufband laeuft: erst jetzt ist ein Klick erlaubt (G-Regel: chest_tick nur
	# wenn der Streifen wirklich faehrt).
	_spinning = true
	_next_tick_tile = TICK_EVERY_TILES
	_tick_times.clear()
	_tick_count = 0
	_slow_ticks = 0
	if _tick_timer == null:
		_tick_timer = Timer.new()
		_tick_timer.wait_time = 0.05
		_tick_timer.one_shot = false
		_tick_timer.timeout.connect(_on_tick)
		add_child(_tick_timer)
	_tick_timer.start()
	print("[CHEST][UI] strip start target_x=%.1f ticks=%d" % [_target_x, TICK_EVERY_TILES])


func _on_tick() -> void:
	if not _spinning or strip == null:
		return
	var step: float = TILE_W + TILE_GAP
	var moved: int = int(absf(strip.position.x - _start_x) / step)
	if moved < _next_tick_tile:
		return
	_next_tick_tile += TICK_EVERY_TILES
	_tick_times.append(Time.get_ticks_msec())
	# Fortschritt 0..1 - letzte 20 % gelten als Auslauf (G1-4: halbe Tonhoehe)
	var total: float = absf(_start_x - _target_x)
	var prog: float = clampf(absf(_start_x - strip.position.x) / maxf(1.0, total), 0.0, 1.0)
	if prog >= 0.80:
		_slow_ticks += 1
		SoundManager.play("chest_tick_slow")
		print("[CHEST][SND] tick_slow #%d kachel=%d prog=%.2f" % [_slow_ticks, moved, prog])
	else:
		_tick_count += 1
		SoundManager.play("chest_tick")
		print("[CHEST][SND] tick #%d kachel=%d prog=%.2f" % [_tick_count, moved, prog])


func _land() -> void:
	# G1-5: Einrasten - Klack + Bass, und das Band steht.
	_spinning = false
	if _tick_timer != null:
		_tick_timer.stop()
	SoundManager.play("chest_land")
	print("[CHEST][SND] land (ticks=%d slow=%d)" % [_tick_count, _slow_ticks])
	_log_tick_gaps()


func _log_tick_gaps() -> void:
	# A4: kein Tick-Sprung am Phasenwechsel - kleinster/groesster Abstand.
	if _tick_times.size() < 2:
		print("[CHEST][TICK] gesamt=%d max_abstand_ms=0 min_abstand_ms=0" % _tick_times.size())
		return
	var mn: int = 100000
	var mx: int = 0
	for i in range(1, _tick_times.size()):
		var gap: int = int(_tick_times[i]) - int(_tick_times[i - 1])
		mn = mini(mn, gap)
		mx = maxi(mx, gap)
	print("[CHEST][TICK] gesamt=%d max_abstand_ms=%d min_abstand_ms=%d" % [_tick_times.size(), mx, mn])


func _skip() -> void:
	# v1.39 B2: Skip springt sofort zum Ergebnis. Die Belohnung steht bereits
	# in `result` und wird hier NICHT neu gewuerfelt - _reveal() wertet nur
	# das vorhandene Dictionary aus.
	if _done:
		print("[CHEST][SKIP] ignoriert (Ergebnis steht schon)")
		return
	var t_press: int = Time.get_ticks_msec()
	var elapsed: float = float(t_press - _t_start) / 1000.0
	var rest: float = maxf(0.0, _total_anim - elapsed)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_spinning = false
	if _tick_timer != null:
		_tick_timer.stop()
	if _skip_btn != null:
		_skip_btn.visible = false
	if chest_img != null:
		# Deckel auf, damit der Beleg-Screenshot nicht die geschlossene Kiste zeigt
		chest_img.texture = TextureManager.get_texture("chest_gem_open_" + _tier)
	_land()
	_reveal()
	var dauer: float = float(Time.get_ticks_msec() - t_press) / 1000.0
	print("[CHEST][SKIP] t=%.2f rest=%.2f elapsed=%.2f" % [dauer, rest, elapsed])


func _unhandled_input(event: InputEvent) -> void:
	# v1.39 B1: auch per Tastatur/Gamepad (ui_cancel = ESC / B / Android-Zurueck)
	if event.is_action_pressed("ui_cancel"):
		if not _done and _skip_btn != null:
			_skip()
			get_viewport().set_input_as_handled()


func _flash(tier: String) -> void:
	# Weisser Blitz zwischen geschlossenem und offenem Bild - ohne ihn springt
	# das Auge, mit ihm liest es den Deckel als "aufgeklappt".
	if chest_img != null:
		chest_img.texture = TextureManager.get_texture("chest_gem_open_" + tier)
		print("[CHEST][UI] deckel auf tier=%s" % tier)
	# G1-2: Deckel-Knall je Stufe (standard tief, silver mittel, premium hell)
	SoundManager.play("chest_open_" + tier)
	print("[CHEST][SND] open stufe=%s" % tier)
	# D1: Spitzen einblenden - Position und Groesse bleiben unveraendert.
	# v1.48 (C2): Die Strahlen-Ebene lag wie ein Zackenrand ueber dem Deckel ->
	# bleibt dauerhaft aus (kein Einblenden, keine Tween).
	print("[CHEST][KANTE] kiste=%s spitzen=0 grund=strahlen_aus_v148" % tier)
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
	if _done:
		return
	_done = true
	strip.position.x = _target_x
	var rar := str(result.get("rarity", "common"))
	var label := str(result.get("name", "?"))
	var dup := bool(result.get("duplicate", false))
	var refund := int(result.get("refund", 0))
	# G1-6/7: Belohnungsklang je Seltenheit, bei Niete der enttaeuschte 2-Ton.
	var kind_now := str(result.get("kind", ""))
	if kind_now == "none":
		SoundManager.play("chest_none")
		print("[CHEST][SND] none -> absteigender 2-Ton")
	else:
		var win_key := "chest_win_" + rar
		if not (rar in ["common", "rare", "epic", "legendary"]):
			win_key = "chest_win_common"
		SoundManager.play(win_key)
		print("[CHEST][SND] win key=%s rarity=%s" % [win_key, rar])
	if str(result.get("kind", "")) == "none":
		info_label.text = "NIETE  ·  diesmal nichts"
		info_label.label_settings = _ls(26, Color(0.45, 0.47, 0.52))
		info_label.modulate = Color(0.75, 0.75, 0.78, 1.0)
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
		info_label.text = "%s  ·  %s  ·  NEU!" % [label, rar.to_upper()]
		info_label.label_settings = _ls(40, _rarity_color(rar).lightened(0.15))
		var pop := create_tween()
		pop.tween_property(info_label, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK)
		pop.tween_property(info_label, "scale", Vector2(1.0, 1.0), 0.25)
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
	btn.custom_minimum_size = Vector2(300, 76)
	btn.add_theme_font_size_override("font_size", 32)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.99, 0.80, 0.22)
	bsb.border_color = Color(0.03, 0.03, 0.05)
	bsb.set_border_width_all(5)
	bsb.set_corner_radius_all(4)
	bsb.shadow_color = Color(0, 0, 0, 0.6)
	bsb.shadow_size = 0
	bsb.shadow_offset = Vector2(6, 6)
	btn.add_theme_stylebox_override("normal", bsb)
	var bh: StyleBoxFlat = bsb.duplicate()
	bh.bg_color = Color(1.0, 0.88, 0.40)
	btn.add_theme_stylebox_override("hover", bh)
	var bp: StyleBoxFlat = bsb.duplicate()
	bp.bg_color = Color(0.85, 0.66, 0.14)
	bp.shadow_offset = Vector2(2, 2)
	btn.add_theme_stylebox_override("pressed", bp)
	btn.add_theme_color_override("font_color", Color(0.14, 0.10, 0.02))
	btn.position = Vector2((size.x - 300) * 0.5, size.y - 120)
	add_child(btn)
	btn.pressed.connect(func():
		closed.emit()
		queue_free())


func is_landed() -> bool:
	# Fuer Tests: steht das Gewinner-Item unter dem Marker?
	var step: float = TILE_W + TILE_GAP
	var target_x: float = -1.0 * (float(_win_index) * step) + (1200.0 * 0.5) - (TILE_W * 0.5)
	return absf(strip.position.x - target_x) < 2.0
