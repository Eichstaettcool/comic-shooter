extends Control

# v1.45 (Z3-Z6): Gluecksrad-Overlay. Zweiter Gluecksmodus neben der Walze,
# gleicher Look (dunkles Panel, Goldrand, Titel 56 px) und gleiche Bedienung
# (Einsatz-Feld + -/+, Chips, ein Drehknopf).
#
# Ablauf (Spec Z4): Ergebnis ziehen -> Zielwinkel daraus -> eine Tween-Fahrt
# mit TRANS_CUBIC/EASE_OUT (kein Ueberschwingen) -> Tick an jeder
# Segmentgrenze -> Einrasten -> Buchung + Auswertung.
signal closed()

const WM = preload("res://scripts/wheel_machine.gd")
const BET_MIN := 100
const BET_MAX := 5000
const RAND_PX := 520.0

var gm: Node = null
var bet: int = 500
var spinning: bool = false
var gold_label: Label = null
var result_label: Label = null
var info_label: Label = null
var bet_input: LineEdit = null
var spin_btn: Button = null
var wheel: Control = null
var pointer: Polygon2D = null
var rng := RandomNumberGenerator.new()
var _winkel: float = 0.0
var _max_winkel: float = 0.0
var _ueberschwinger: bool = false
var _von: float = 0.0
var _bis: float = 0.0
var _ticks_gesamt: int = 0
var _ticks_erwartet: int = 0
var _letzte_grenze: int = 0
var _spin_start_ms: int = 0
var _spin_dauer: float = 0.0
var _ziel_index: int = -1
var _ergebnis: Dictionary = {}


func setup(gmi: Node) -> void:
	gm = gmi
	rng.randomize()


func open() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	size = vp
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_refresh_gold()
	print("[WHEEL][UI] geoeffnet segmente=%d icons=%d rad_px=%d zeiger=oben einsatz=%d gold=%d" % [
		WM.SEGMENTS, WM.SLICES.size(), int(RAND_PX), bet, _gold()])


func _gold() -> int:
	if gm == null:
		return 0
	return int(gm.get("gold"))


func _ls(sz: int, col: Color, outline: int) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font_size = sz
	ls.font_color = col
	if outline > 0:
		ls.outline_size = outline
		ls.outline_color = Color(0.04, 0.04, 0.08)
	return ls


func _style(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.985)
	dim.position = Vector2.ZERO
	dim.size = size
	add_child(dim)

	var title := Label.new()
	title.text = "GLÜCKSRAD"
	title.position = Vector2(0, 18)
	title.size = Vector2(size.x, 70)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.label_settings = _ls(56, Color(0.99, 0.80, 0.22), 10)
	add_child(title)

	info_label = Label.new()
	info_label.position = Vector2(0, 92)
	info_label.size = Vector2(size.x, 34)
	info_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	info_label.label_settings = _ls(24, Color(0.86, 0.92, 0.98), 4)
	info_label.text = "8 SEGMENTE  ·  GEWINNCHANCE %.0f %%  ·  GOLDRÜCKFLUSS %.0f %%" % [
		100.0 - float(WM.odds_table()[1]["chance"]), WM.rtp_gold() * 100.0]
	add_child(info_label)

	gold_label = Label.new()
	# Nicht hinter den ZURUECK-Knopf legen (stand vorher auf dessen Text)
	gold_label.position = Vector2(size.x - 700, 32)
	gold_label.size = Vector2(360, 52)
	gold_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.label_settings = _ls(36, Color(1.0, 0.88, 0.45), 6)
	add_child(gold_label)

	# --- Rad ---
	var cx: float = size.x * 0.5
	var cy: float = 600.0
	wheel = load("res://scripts/ui/wheel_view.gd").new()
	wheel.name = "WheelView"
	wheel.position = Vector2(cx - (RAND_PX + 60.0) * 0.5, cy - (RAND_PX + 60.0) * 0.5)
	wheel.size = Vector2(RAND_PX + 60.0, RAND_PX + 60.0)
	wheel.call("set_radius", RAND_PX)
	wheel.call("set_angle_deg", _winkel)
	add_child(wheel)

	# Zeiger oben (zeigt nach unten in das Rad)
	pointer = Polygon2D.new()
	pointer.name = "Zeiger"
	pointer.position = Vector2(cx, cy - RAND_PX * 0.5 - 26.0)
	pointer.polygon = PackedVector2Array([
		Vector2(-34, -34), Vector2(34, -34), Vector2(0, 30),
	])
	pointer.color = Color(1.0, 0.30, 0.24)
	add_child(pointer)

	result_label = Label.new()
	result_label.name = "WheelResult"
	result_label.position = Vector2(0, cy + RAND_PX * 0.5 + 44.0)
	result_label.size = Vector2(size.x, 54)
	result_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	result_label.label_settings = _ls(34, Color(1.0, 0.90, 0.45), 6)
	result_label.text = "EINSATZ WÄHLEN UND DREHEN"
	add_child(result_label)

	# --- Bedienung ---
	var row := HBoxContainer.new()
	row.position = Vector2(0, cy + RAND_PX * 0.5 + 112.0)
	row.size = Vector2(size.x, 84)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	var minus := Button.new()
	minus.text = "–"
	minus.custom_minimum_size = Vector2(84, 76)
	minus.add_theme_font_size_override("font_size", 40)
	minus.pressed.connect(_on_minus)
	row.add_child(minus)

	bet_input = LineEdit.new()
	bet_input.name = "WheelBet"
	bet_input.text = str(bet)
	bet_input.custom_minimum_size = Vector2(200, 76)
	bet_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_input.add_theme_font_size_override("font_size", 34)
	bet_input.text_submitted.connect(_on_bet_entered)
	bet_input.focus_exited.connect(_on_bet_entered.bind(bet_input.text))
	row.add_child(bet_input)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(84, 76)
	plus.add_theme_font_size_override("font_size", 40)
	plus.pressed.connect(_on_plus)
	row.add_child(plus)

	for v in [100, 500, 1000, 2500]:
		var chip := Button.new()
		chip.text = str(v)
		chip.custom_minimum_size = Vector2(112, 68)
		chip.add_theme_font_size_override("font_size", 26)
		chip.pressed.connect(_set_bet.bind(int(v)))
		row.add_child(chip)

	spin_btn = Button.new()
	spin_btn.name = "WheelSpin"
	spin_btn.text = "DREHEN"
	spin_btn.custom_minimum_size = Vector2(300, 84)
	spin_btn.add_theme_font_size_override("font_size", 36)
	var sb := _style(Color(0.98, 0.78, 0.20), Color(0.06, 0.05, 0.10), 5, 8)
	spin_btn.add_theme_stylebox_override("normal", sb)
	sb = _style(Color(1.0, 0.88, 0.42), Color(0.06, 0.05, 0.10), 5, 8)
	spin_btn.add_theme_stylebox_override("hover", sb)
	spin_btn.add_theme_color_override("font_color", Color(0.08, 0.07, 0.10))
	spin_btn.pressed.connect(_on_spin)
	row.add_child(spin_btn)

	var close := Button.new()
	close.name = "WheelClose"
	close.text = "ZURÜCK"
	close.position = Vector2(size.x - 300, 24)
	close.size = Vector2(260, 64)
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(_on_close)
	add_child(close)

	# Ergebnis-Tabelle der Segmente (klein, unter dem Rad links)
	var odds := VBoxContainer.new()
	odds.position = Vector2(80, 300)
	odds.add_theme_constant_override("separation", 2)
	add_child(odds)
	var head := Label.new()
	head.text = "CHANCEN"
	head.label_settings = _ls(24, Color(0.99, 0.80, 0.22), 4)
	odds.add_child(head)
	for o in WM.odds_table():
		var l := Label.new()
		l.text = "%-10s %5.1f %%" % [str(o["label"]), float(o["chance"])]
		l.label_settings = _ls(18, Color(0.80, 0.86, 0.92), 3)
		odds.add_child(l)
	print("[WHEEL][UI] segmente=%d rad_px=%d zeiger=oben knopf=DREHEN einsatz_min=%d einsatz_max=%d" % [
		WM.SEGMENTS, int(RAND_PX), BET_MIN, BET_MAX])
	for i in range(WM.SLICES.size()):
		var sl: Dictionary = WM.SLICES[i]
		print("[WHEEL][SEGMENT] index=%d icon=%s wert=%d key=%s" % [
			i, "wheel_icon_" + str(sl.get("art", "gold")),
			int(sl.get("gems", 0)) if int(sl.get("gems", 0)) > 0 else int(sl.get("mult", 0.0)),
			str(sl["key"])])


func _refresh_gold() -> void:
	if gold_label != null:
		gold_label.text = "GOLD: %d" % _gold()


func _set_bet(v: int) -> void:
	if spinning:
		return
	bet = clampi(v, BET_MIN, BET_MAX)
	if bet_input != null:
		bet_input.text = str(bet)


func _on_minus() -> void:
	_set_bet(bet - 100)


func _on_plus() -> void:
	_set_bet(bet + 100)


func _on_bet_entered(_txt: String = "") -> void:
	if spinning or bet_input == null:
		return
	var v: int = int(bet_input.text.strip_edges())
	_set_bet(v)


func _on_close() -> void:
	if spinning:
		return
	print("[WHEEL][UI] geschlossen")
	closed.emit()
	queue_free()


func _on_spin() -> void:
	if spinning:
		return
	_on_bet_entered("")
	var gold: int = _gold()
	if bet > gold:
		print("[WHEEL][FEHLER] zu_wenig_gold einsatz=%d gold=%d" % [bet, gold])
		result_label.text = "ZU WENIG GOLD"
		return
	var res: Dictionary = WM.spin(bet, gold, rng)
	if not bool(res.get("ok", false)):
		result_label.text = "DREH NICHT MÖGLICH"
		return
	_ergebnis = res
	_ziel_index = int(res["index"])
	_drehen(_ziel_index)


func _drehen(idx: int) -> void:
	# Z4: Zielwinkel aus dem Segment. Zeiger oben, Segment i sitzt bei
	# i*45+22,5 Grad im Uhrzeigersinn -> Rad muss auf -(i*45+22,5) stehen.
	var seg: float = WM.slice_angle_deg()
	var ziel_norm: float = fposmod(-(float(idx) * seg + seg * 0.5), 360.0)
	var start_norm: float = fposmod(_winkel, 360.0)
	var delta: float = fposmod(ziel_norm - start_norm, 360.0)
	# kleine Streuung innerhalb des Segments, damit es nicht immer exakt
	# dieselbe Stelle ist (bleibt sicher im Segment: +-14 Grad bei 45 Grad)
	var jitter: float = rng.randf_range(-8.0, 8.0)
	delta = fposmod(delta + jitter, 360.0)
	var umdrehungen: int = 4 + rng.randi_range(0, 1)
	_von = _winkel
	_bis = _winkel + 360.0 * float(umdrehungen) + delta
	_max_winkel = _von
	_spin_dauer = rng.randf_range(4.4, 6.0)
	_ticks_gesamt = 0
	# Erwartete Ticks: jede volle Segmentbreite auf dem Weg = ein Tick
	_ticks_erwartet = int(floor((_bis - _von) / seg))
	_letzte_grenze = int(floor(_von / seg))
	_spinning_start()
	print("[WHEEL][SPIN] ziel_segment=%d dauer=%.2fs winkel=%.1fdeg start=%.1f ziel=%.1f drehungen=%d ueberschwinger=false ticks_erwartet=%d" % [
		idx, _spin_dauer, delta, _von, _bis, umdrehungen, _ticks_erwartet])


func _spinning_start() -> void:
	spinning = true
	_spin_start_ms = Time.get_ticks_msec()
	if spin_btn != null:
		spin_btn.disabled = true
	result_label.text = "…"
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_winkel, _von, _bis, _spin_dauer)
	tw.tween_callback(_landen)


func _set_winkel(v: float) -> void:
	# Z5: an jeder Segmentgrenze ein Tick - gezaehlt aus dem echten Winkel.
	_winkel = v
	_max_winkel = maxf(_max_winkel, v)
	if wheel != null:
		wheel.call("set_angle_deg", _winkel)
	var seg: float = WM.slice_angle_deg()
	var grenze: int = int(floor(_winkel / seg))
	if grenze != _letzte_grenze:
		var anzahl: int = absi(grenze - _letzte_grenze)
		for _k in range(anzahl):
			_ticks_gesamt += 1
			SoundManager.play("chest_tick")
		_letzte_grenze = grenze


func _landen() -> void:
	spinning = false
	_ueberschwinger = _max_winkel > _bis + 0.01
	_winkel = fposmod(_bis, 360.0)
	if wheel != null:
		wheel.call("set_angle_deg", _winkel)
	if spin_btn != null:
		spin_btn.disabled = false
	# Einrast-Tick: der letzte Tick gehoert zum Einrasten, kein doppelter
	var doppelt: bool = _ticks_gesamt > _ticks_erwartet
	print("[WHEEL][TICK] gesamt=%d erwartet=%d doppelt=%s" % [_ticks_gesamt, _ticks_erwartet, str(doppelt)])
	_buchen()
	var dauer: float = float(Time.get_ticks_msec() - _spin_start_ms) / 1000.0
	print("[WHEEL][DAUER] gemessen=%.2fs soll=%.2fs ueberschwinger=%s max=%.2f ziel=%.2f" % [
		dauer, _spin_dauer, str(_ueberschwinger), _max_winkel, _bis])


func _buchen() -> void:
	if gm == null or _ergebnis.is_empty():
		return
	var vorher: int = int(gm.get("gold"))
	var win: int = int(_ergebnis.get("win", 0))
	var gems: int = int(_ergebnis.get("gems", 0))
	var guthaben: int = vorher - bet + win
	var key: String = str(_ergebnis.get("key", ""))
	# v1.48 (A2): NUR Gold und Diamanten - kein Hut, kein Skin, keine Ersatzlogik.
	gm.set("gold", guthaben)
	if gems > 0:
		gm.set("gems", int(gm.get("gems")) + gems)
	if gm.has_method("_save_profile"):
		gm.call("_save_profile")
	if gm.has_method("_save_high_score"):
		gm.call("_save_high_score")
	_refresh_gold()
	var txt: String = str(_ergebnis.get("label", ""))
	if win > 0:
		result_label.text = "%s  ·  +%d GOLD" % [txt, win]
		SoundManager.play("chest_win_common")
		print("[WHEEL][GEWINN] art=gold wert=%d guthaben=%d key=%s" % [win, guthaben, key])
	elif gems > 0:
		result_label.text = "%s  ·  +%d DIAMANT" % [txt, gems]
		SoundManager.play("levelup")
		print("[WHEEL][GEWINN] art=diamanten wert=%d guthaben=%d key=%s" % [gems, int(gm.get("gems")), key])
	else:
		result_label.text = "%s  ·  NICHTS" % txt
		SoundManager.play("slot_stop")
		print("[WHEEL][GEWINN] art=niete wert=0 guthaben=%d key=%s" % [guthaben, key])
	print("[WHEEL][KAUF] einsatz=%d gold_vorher=%d nachher=%d ergebnis=%s win=%d gems=%d gespeichert=true" % [
		bet, vorher, guthaben, key, win, gems])


func is_spinning() -> bool:
	return spinning
