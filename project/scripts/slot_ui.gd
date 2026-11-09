extends Control
# Runde 94: Glueckswalze mit echten Walzenbaendern.
# Spec: SPEC_SLOT.md §3 (Mechanik) und §6 (Band-Animation)
# Runde 141: E1 (Einsatz 1-5000: Feld + Regler + +/-) und E3 (Chancen-Tabelle
#            ueber den Walzen) nachgezogen. Vorher referenzierte _set_bet()
#            bet_input/bet_slider, die es nicht gab -> Script kompilierte nicht,
#            die Walze liess sich im Shop gar nicht oeffnen.

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
var bet_input: LineEdit = null
var bet_slider: HSlider = null
var bet_minus: Button = null
var bet_plus: Button = null
var _syncing: bool = false
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
	print("[SLOT][UI] geoeffnet bet=%d gold=%d" % [bet, int(gm.get("gold")) if gm != null else 0])


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.985)
	dim.position = Vector2.ZERO
	dim.size = size
	add_child(dim)

	var title := Label.new()
	title.text = "GLÜCKSWALZE"
	title.position = Vector2(0, 24)
	title.size = Vector2(size.x, 66)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.label_settings = _ls(56, Color(0.99, 0.80, 0.22), 10)
	add_child(title)

	gold_label = Label.new()
	gold_label.position = Vector2(size.x - 500, 34)
	gold_label.size = Vector2(460, 56)
	gold_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.label_settings = _ls(36, Color(1.0, 0.88, 0.45), 6)
	add_child(gold_label)

	_build_odds(100.0)

	var gap: float = 26.0
	var total: float = CELL_W * 3.0 + gap * 2.0
	var x0: float = (size.x - total) * 0.5
	var y0: float = 348.0

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

	# ---- E1: Einsatz-Steuerung (minus / Feld / plus / Chips / Regler) ----
	var row_w: float = 64.0 + 6.0 + 150.0 + 6.0 + 64.0 + 14.0 + 3.0 * 158.0 + 2.0 * 8.0
	var bx: float = (size.x - row_w) * 0.5
	var by: float = 778.0
	bet_minus = _pixbtn("−", Color(0.28, 0.34, 0.44))
	bet_minus.position = Vector2(bx, by)
	bet_minus.size = Vector2(64, 64)
	bet_minus.add_theme_font_size_override("font_size", 40)
	bet_minus.pressed.connect(_bet_minus)
	add_child(bet_minus)

	bet_input = LineEdit.new()
	bet_input.position = Vector2(bx + 70.0, by)
	bet_input.size = Vector2(150, 64)
	bet_input.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	bet_input.add_theme_font_size_override("font_size", 30)
	var le_sb := StyleBoxFlat.new()
	le_sb.bg_color = Color(0.10, 0.12, 0.18)
	le_sb.border_color = Color(0.99, 0.80, 0.22)
	le_sb.set_border_width_all(3)
	le_sb.set_corner_radius_all(4)
	bet_input.add_theme_stylebox_override("normal", le_sb)
	bet_input.add_theme_stylebox_override("focus", le_sb)
	bet_input.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	bet_input.text = str(bet)
	bet_input.text_submitted.connect(_on_bet_text)
	bet_input.focus_exited.connect(func(): _on_bet_text(bet_input.text))
	add_child(bet_input)

	bet_plus = _pixbtn("+", Color(0.28, 0.34, 0.44))
	bet_plus.position = Vector2(bx + 226.0, by)
	bet_plus.size = Vector2(64, 64)
	bet_plus.add_theme_font_size_override("font_size", 40)
	bet_plus.pressed.connect(_bet_plus)
	add_child(bet_plus)

	var qx: float = bx + 304.0
	for i in range(3):
		var v: int = int([50, 100, 250][i])
		var b := _pixbtn("%d 🪙" % v, Color(0.28, 0.34, 0.44))
		b.position = Vector2(qx + float(i) * 166.0, by)
		b.size = Vector2(158, 64)
		b.pressed.connect(_set_bet.bind(v))
		add_child(b)
		bet_buttons.append(b)

	bet_slider = HSlider.new()
	bet_slider.min_value = 1.0
	bet_slider.max_value = 5000.0
	bet_slider.step = 1.0
	bet_slider.value = float(bet)
	bet_slider.position = Vector2(size.x * 0.5 - 450.0, 848.0)
	bet_slider.size = Vector2(900, 30)
	bet_slider.value_changed.connect(_on_bet_slider)
	add_child(bet_slider)

	result_label = Label.new()
	result_label.text = ""
	result_label.position = Vector2(0, 868.0)
	result_label.size = Vector2(size.x, 54)
	result_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	result_label.label_settings = _ls(32, Color(0.90, 0.94, 0.98), 6)
	add_child(result_label)

	spin_btn = _pixbtn("DREHEN", Color(0.99, 0.80, 0.22))
	spin_btn.position = Vector2(size.x * 0.5 - 220.0, 930.0)
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


func _build_odds(y: float) -> void:
	# Runde 136 (B1): Statt "SYMBOL · 3 GLEICHE · CHANCE" jetzt "SO GEWINNT MAN".
	# Keine Prozentwerte, kein Totenkopf - nur die Kombinationen, ab wann es
	# Geld gibt, und wie viel. Quelle bleibt SlotMachine.PAYTABLE/PAYTABLE_TWO
	# ueber gm.slot_odds(), damit es keine zweite Zahlenquelle gibt.
	var px0: float = (size.x - 1560.0) * 0.5
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.09, 0.14, 0.94)
	sb.border_color = Color(0.42, 0.36, 0.24)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(px0, y)
	panel.size = Vector2(1560, 244)
	add_child(panel)

	var head := Label.new()
	head.text = "SO GEWINNT MAN"
	head.position = Vector2(18, 4)
	head.size = Vector2(600, 34)
	head.label_settings = _ls(24, Color(0.99, 0.84, 0.36), 4)
	panel.add_child(head)

	var rows: Array = []
	if gm != null and gm.has_method("slot_odds"):
		rows = gm.call("slot_odds")
	if rows.is_empty():
		print("[SLOT][UI] FEHLER: slot_odds() liefert keine Tabelle")
		return
	var by_key: Dictionary = {}
	for r in rows:
		by_key[str(r.get("key", "?"))] = r

	# Kombinationen: 2 gleiche (von links) und 3 gleiche je Symbol, Muenzen
	# zuletzt als groesster Gewinn. Reihenfolge wie im Entwurf: Kirschen,
	# Glocken, Balken - je Symbol erst die 2er-, dann die 3er-Reihe.
	var entries: Array = []
	var plur := { "cherry": "Kirschen", "bell": "Glocken", "bar": "Balken" }
	for key in ["cherry", "bell", "bar"]:
		var r2: Dictionary = by_key.get(key, {})
		if r2.is_empty():
			continue
		var two: float = float(r2.get("pay2", 0.0))
		var three: float = float(r2.get("pay3", 0.0))
		var nm: String = str(plur.get(key, key))
		if two > 0.0:
			entries.append({ "icons": [key], "label": "2 " + nm,
				"pay": "%s× Einsatz" % _num_ger(two) })
		if three > 0.0:
			entries.append({ "icons": [key, key, key], "label": "3 " + nm,
				"pay": "%s× Einsatz" % _num_ger(three) })
	var g2: float = float((by_key.get("gold2", {}) as Dictionary).get("pay3", 0.0)) if by_key.has("gold2") else 0.0
	var g3: float = float((by_key.get("gold3", {}) as Dictionary).get("pay3", 0.0)) if by_key.has("gold3") else 0.0
	entries.append({ "icons": ["gold3", "gold3", "gold3"], "label": "3 Münzen",
		"pay": "%s× / %s× Einsatz" % [_num_ger(g2), _num_ger(g3)] })

	# 2 Spalten x 4 Reihen. Jede Zeile ist ein HBoxContainer - der rechnet die
	# Breiten selbst, dadurch koennen sich Symbole und Auszahlung nicht
	# ueberlappen.
	var col_w: float = 770.0
	var row_h: float = 42.0
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		var col: int = i / 4
		var row: int = i % 4
		var row_box := HBoxContainer.new()
		row_box.position = Vector2(18.0 + float(col) * col_w, 44.0 + float(row) * row_h)
		row_box.size = Vector2(col_w - 24.0, row_h - 4.0)
		row_box.add_theme_constant_override("separation", 8)
		panel.add_child(row_box)

		var icon_keys: Array = e["icons"]
		for ik in icon_keys:
			var tex: Texture2D = TextureManager.get_texture("slot_" + str(ik))
			var icon := TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(40, 36)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			if tex == null:
				print("[SLOT][UI] FEHLER: Symboltextur slot_%s fehlt im Gewinnschema" % str(ik))
			row_box.add_child(icon)

		var nm2 := Label.new()
		nm2.text = str(e["label"])
		nm2.custom_minimum_size = Vector2(210, 36)
		nm2.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
		nm2.label_settings = _ls(22, Color(0.90, 0.92, 0.96), 4)
		row_box.add_child(nm2)

		var pl := Label.new()
		pl.text = str(e["pay"])
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
		pl.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
		pl.label_settings = _ls(22, Color(1.0, 0.84, 0.36), 4)
		row_box.add_child(pl)

	# B2: eine Zeile unter dem Schema, damit die Regel klar ist.
	var note := Label.new()
	note.text = "GEWINN AB 2 GLEICHEN VON LINKS  ·  MITTE ZÄHLT"
	note.position = Vector2(18, 214)
	note.size = Vector2(1524, 26)
	note.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	note.label_settings = _ls(20, Color(0.72, 0.88, 0.78), 4)
	panel.add_child(note)

	print("[SLOT][UI] Gewinnschema: %d Zeilen" % entries.size())
	var logp: Array = []
	for e in entries:
		logp.append(str(e["pay"]))
	print("[SLOT][UI] Gewinnschema Werte: %s" % str(logp))


func _num_ger(v: float) -> String:
	# Deutsche Schreibweise mit Komma: 2.1 -> "2,1"
	return ("%.1f" % v).replace(".", ",")


func _random_symbol() -> Texture2D:
	var k: String = str(SYM_KEYS[rng.randi_range(0, SYM_KEYS.size() - 1)])
	return TextureManager.get_texture("slot_" + k)


func _symbol_texture(sym: String) -> Texture2D:
	var t = TextureManager.get_texture("slot_" + sym)
	if t == null:
		print("[SLOT][UI] FEHLER: Textur slot_%s fehlt" % sym)
	return t


func _step_for(v: int) -> int:
	# Runde 121: angenehme Schrittweiten
	if v < 100:
		return 1
	if v < 1000:
		return 10
	return 100


func _clamp_bet(v: int) -> int:
	var owned: int = int(gm.get("gold")) if gm != null else 0
	# E2: nie mehr als vorhanden, nie unter 1, nie ueber 5000
	var capped: int = mini(v, maxi(owned, 0))
	var out: int = clampi(capped, 1, 5000)
	if v > owned and gm != null:
		print("[SLOT][BET] Einsatz %d auf vorhandenes Gold %d begrenzt" % [v, owned])
	if v > 5000:
		print("[SLOT][BET] Einsatz %d auf Maximum 5000 begrenzt" % v)
	return out


func _set_bet(v: int) -> void:
	if spinning:
		return
	bet = _clamp_bet(v)
	_syncing = true
	if bet_input != null:
		bet_input.text = str(bet)
	if bet_slider != null and int(bet_slider.value) != bet:
		bet_slider.set_value_no_signal(float(bet))
	_syncing = false
	print("[SLOT][BET] Einsatz=%d (Gold=%d)" % [bet, int(gm.get("gold")) if gm != null else 0])
	if result_label != null and not spinning:
		result_label.text = "EINSATZ %d 🪙" % bet
		result_label.label_settings = _ls(32, Color(0.90, 0.94, 0.98), 6)


func _bet_minus() -> void:
	_set_bet(bet - _step_for(bet))


func _bet_plus() -> void:
	_set_bet(bet + _step_for(bet))


func _on_bet_text(s: String) -> void:
	if _syncing:
		return
	var clean := s.strip_edges()
	if not clean.is_valid_int():
		print("[SLOT][BET] FEHLER: '%s' ist keine Zahl - Einsatz bleibt %d" % [s, bet])
		if bet_input != null:
			bet_input.text = str(bet)
		return
	_set_bet(int(clean))


func _on_bet_slider(v: float) -> void:
	if _syncing:
		return
	_set_bet(int(v))


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
	if bet_minus != null:
		bet_minus.disabled = true
	if bet_plus != null:
		bet_plus.disabled = true
	if bet_input != null:
		bet_input.editable = false
	if bet_slider != null:
		bet_slider.editable = false

	var syms: Array = r["symbols"]
	var same_two: bool = str(syms[0]) == str(syms[1])
	# Runde 122 (E4): Bei zwei Gleichen laeuft die dritte Walze mit ~55 %
	# Geschwindigkeit (1,15 s -> 2,07 s) und haelt danach 0,4 s laenger.
	var d3: float = 1.15
	if same_two:
		d3 = 1.15 * 1.8
		print("[SLOT][UI] Anticipation: zwei gleiche (%s) - Walze 3 laeuft %.2f s (55 %% Speed)" % [str(syms[0]), d3])
	var stops := [0.62, 0.88, d3]
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
	if bet_minus != null:
		bet_minus.disabled = false
	if bet_plus != null:
		bet_plus.disabled = false
	if bet_input != null:
		bet_input.editable = true
	if bet_slider != null:
		bet_slider.editable = true
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
		print("[SLOT][UI] win=0 combo=%s" % combo)


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
