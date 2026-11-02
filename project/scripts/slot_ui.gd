extends Control
# Runde 94: Glueckswalze mit echten Walzenbaendern.
# Spec: SPEC_SLOT.md §3 (Mechanik) und §6 (Band-Animation)

signal closed()

const CELL_H := 140.0
const CELL_W := 230.0
const STRIP_LEN := 24
const WIN_CELL := 18
const REEL_H := 420.0
const SYM_KEYS := ["cherry", "bell", "bar", "gold1", "gold2", "gold3", "skull"]

var gm: Node = null
var bet: int = 100
var spinning: bool = false
var strips: Array = []
var gold_label: Label = null
var result_label: Label = null
var bet_buttons: Array = []
var spin_btn: Button = null
var rng := RandomNumberGenerator.new()
var _result: Dictionary = {}


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
	print("[SLOT][UI] geoeffnet bet=%d" % bet)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.985)
	dim.position = Vector2.ZERO
	dim.size = size
	add_child(dim)

	var title := Label.new()
	title.text = "GLÜCKSWALZE"
	title.position = Vector2(0, 70)
	title.size = Vector2(size.x, 70)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.label_settings = _ls(60, Color(0.99, 0.80, 0.22), 10)
	add_child(title)

	gold_label = Label.new()
	gold_label.position = Vector2(size.x - 520, 34)
	gold_label.size = Vector2(480, 56)
	gold_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.label_settings = _ls(36, Color(1.0, 0.88, 0.45), 6)
	add_child(gold_label)

	var gap: float = 26.0
	var total: float = CELL_W * 3.0 + gap * 2.0
	var x0: float = (size.x - total) * 0.5
	var y0: float = size.y * 0.5 - 380.0

	for i in range(3):
		# Panel statt PanelContainer: ein Container wuerde sich der Bandhoehe
		# (24 x 120 px) anpassen und das Fenster aufreissen.
		var frame := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.08, 0.13, 1.0)
		sb.border_color = Color(0.99, 0.80, 0.22)
		sb.set_border_width_all(5)
		sb.set_corner_radius_all(6)
		frame.add_theme_stylebox_override("panel", sb)
		frame.position = Vector2(x0 + float(i) * (CELL_W + gap), y0)
		frame.size = Vector2(CELL_W, REEL_H)
		frame.clip_contents = true
		add_child(frame)

		var view := Control.new()
		view.position = Vector2(5, 5)
		view.size = Vector2(CELL_W - 10.0, REEL_H - 10.0)
		view.clip_contents = true
		frame.add_child(view)

		var strip := VBoxContainer.new()
		strip.add_theme_constant_override("separation", 0)
		strip.position = Vector2.ZERO
		view.add_child(strip)
		strips.append(strip)
		for c in range(STRIP_LEN):
			var cell := TextureRect.new()
			cell.custom_minimum_size = Vector2(CELL_W, CELL_H)
			cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cell.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			cell.texture = _random_symbol()
			strip.add_child(cell)

	var line := ColorRect.new()
	line.color = Color(0.99, 0.80, 0.22, 0.45)
	line.position = Vector2(x0, y0 + 208.0)
	line.size = Vector2(total, 4)
	add_child(line)

	result_label = Label.new()
	result_label.text = ""
	result_label.position = Vector2(0, y0 + REEL_H + 110.0)
	result_label.size = Vector2(size.x, 54)
	result_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	result_label.label_settings = _ls(32, Color(0.90, 0.94, 0.98), 6)
	add_child(result_label)

	var bx: float = (size.x - 3.0 * 170.0 - 2.0 * 18.0) * 0.5
	for i in range(3):
		var v: int = int([50, 100, 250][i])
		var b := _pixbtn("%d 🪙" % v, Color(0.28, 0.34, 0.44))
		b.position = Vector2(bx + float(i) * 188.0, y0 + REEL_H + 26.0)
		b.size = Vector2(170, 64)
		b.pressed.connect(_set_bet.bind(v))
		add_child(b)
		bet_buttons.append(b)

	spin_btn = _pixbtn("DREHEN", Color(0.99, 0.80, 0.22))
	spin_btn.position = Vector2(size.x * 0.5 - 220.0, y0 + REEL_H + 170.0)
	spin_btn.size = Vector2(440, 96)
	spin_btn.add_theme_color_override("font_color", Color(0.16, 0.11, 0.02))
	spin_btn.pressed.connect(_spin)
	add_child(spin_btn)

	var back := _pixbtn("ZURÜCK", Color(0.32, 0.35, 0.42))
	back.position = Vector2(40, 30)
	back.size = Vector2(220, 68)
	back.pressed.connect(func():
		closed.emit()
		queue_free())
	add_child(back)
	_set_bet(bet)


func _random_symbol() -> Texture2D:
	var k: String = str(SYM_KEYS[rng.randi_range(0, SYM_KEYS.size() - 1)])
	return TextureManager.get_texture("slot_" + k)


func _symbol_texture(sym: String) -> Texture2D:
	var t = TextureManager.get_texture("slot_" + sym)
	if t == null:
		print("[SLOT][UI] FEHLER: Textur slot_%s fehlt" % sym)
	return t


func _set_bet(v: int) -> void:
	if spinning:
		return
	bet = v
	for i in range(bet_buttons.size()):
		var val: int = int([50, 100, 250][i])
		bet_buttons[i].modulate = Color(1, 1, 1, 1) if val == bet else Color(0.62, 0.66, 0.72, 1)
	if result_label != null and not spinning:
		result_label.text = "EINSATZ %d 🪙" % bet
		result_label.label_settings = _ls(32, Color(0.90, 0.94, 0.98), 6)


func _refresh_gold() -> void:
	if gm != null and gold_label != null:
		gold_label.text = "🪙 %d" % int(gm.get("gold"))


func _spin() -> void:
	if spinning or gm == null:
		return
	if not gm.has_method("slot_spin"):
		print("[SLOT][UI] FEHLER: game_manager.slot_spin() fehlt")
		return
	var r: Dictionary = gm.call("slot_spin", bet)
	if not bool(r.get("ok", false)):
		result_label.text = "NICHT GENUG GOLD (EINSATZ %d)" % bet
		result_label.label_settings = _ls(30, Color(1.0, 0.45, 0.42), 6)
		return
	_result = r
	spinning = true
	result_label.text = ""
	spin_btn.disabled = true
	_refresh_gold()
	for b in bet_buttons:
		b.modulate = Color(0.6, 0.6, 0.6, 1)

	var syms: Array = r["symbols"]
	var same_two: bool = str(syms[0]) == str(syms[1])
	var stops := [0.62, 0.88, 1.45 if same_two else 1.15]
	if same_two:
		print("[SLOT][UI] Anticipation: zwei gleiche (%s) - Walze 3 auf 1.45 s" % str(syms[0]))
	for i in range(3):
		_roll_reel(i, float(stops[i]), str(syms[i]))


func _roll_reel(idx: int, dur: float, final_sym: String) -> void:
	var strip: VBoxContainer = strips[idx]
	var cells: Array = strip.get_children()
	if cells.size() < STRIP_LEN:
		print("[SLOT][UI] FEHLER: Walze %d hat nur %d Zellen" % [idx, cells.size()])
		return
	for i in range(STRIP_LEN):
		var c: TextureRect = cells[i]
		c.texture = _random_symbol()
	var target_cell: TextureRect = cells[WIN_CELL]
	target_cell.texture = _symbol_texture(final_sym)
	strip.position = Vector2(0, rng.randf_range(-90.0, 0.0))
	SoundManager.play("slot_spin")

	var target_y: float = 140.0 - float(WIN_CELL) * CELL_H
	var tw := create_tween()
	# Phase 1: schneller Lauf (80 % der Strecke in 55 % der Zeit)
	tw.tween_property(strip, "position:y", lerpf(strip.position.y, target_y, 0.80), dur * 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Phase 2: letzte 20 % kriechen - das erzeugt die Spannung
	tw.tween_property(strip, "position:y", target_y - 12.0, dur * 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(strip, "position:y", target_y, 0.13) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		SoundManager.play("slot_stop")
		target_cell.pivot_offset = target_cell.size * 0.5
		var g := create_tween()
		g.tween_property(target_cell, "scale", Vector2(1.16, 1.16), 0.06)
		g.tween_property(target_cell, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK)
		print("[SLOT][UI] Walze %d gestoppt: %s" % [idx, final_sym])
		if idx == 2:
			_finish())


func _finish() -> void:
	spinning = false
	spin_btn.disabled = false
	for b in bet_buttons:
		b.modulate = Color(1, 1, 1, 1)
	_set_bet(bet)
	var win: int = int(_result.get("win", 0))
	var combo := str(_result.get("combo", ""))
	_refresh_gold()
	if win > 0:
		var big: bool = combo == "three_gold3"
		SoundManager.play("slot_jackpot" if big else "slot_win")
		result_label.text = "EINSATZ %d  ·  GEWINN +%d 🪙" % [bet, win]
		result_label.label_settings = _ls(40 if big else 34, Color(1.0, 0.88, 0.30) if big else Color(0.55, 0.95, 0.60), 8)
		if big:
			_jackpot_flash()
		print("[SLOT][UI] win=%d combo=%s" % [win, combo])
	else:
		result_label.text = "EINSATZ %d  ·  NIETE" % bet
		result_label.label_settings = _ls(32, Color(0.62, 0.66, 0.72), 5)


func _jackpot_flash() -> void:
	var fl := ColorRect.new()
	fl.color = Color(1, 1, 1, 0)
	fl.position = Vector2.ZERO
	fl.size = size
	add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 0.85, 0.08)
	tw.tween_property(fl, "color:a", 0.0, 0.35)
	tw.tween_callback(fl.queue_free)


func _ls(sz: int, col: Color, outline: int) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font_size = sz
	ls.font_color = col
	ls.outline_size = outline
	ls.outline_color = Color(0.03, 0.03, 0.06)
	return ls


func _pixbtn(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = Color(0.03, 0.03, 0.05)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(5, 5)
	b.add_theme_stylebox_override("normal", sb)
	return b
