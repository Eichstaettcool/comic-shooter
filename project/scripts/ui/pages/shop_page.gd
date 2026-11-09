class_name ShopPage
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null

const LootTable = preload("res://scripts/systems/loot_table.gd")
const WheelMachineScript = preload("res://scripts/wheel_machine.gd")


func _create_chest_page() -> void:
	# v1.44 (R): Der Shop ist ein AUTOMAT, kein Menue-Stapel. Vorbild ist die
	# Glueckswalze: dunkles Panel, Goldrand, goldene Ueberschrift mit Akzentlinie,
	# ein klarer goldener Aktionsknopf. Aufbau:
	#   [ZURUECK]                                  [GOLD] [DIAMANTEN]
	#   ── KISTEN ──     3 Automaten-Karten (Fenster 320x300, 4 Chancen-Zeilen)
	#   ── UMTAUSCH ──   ein Panel, drei Streifen, je ein TAUSCHEN-Knopf rechts
	#   ── GLUECKSWALZE ──  Walzen-Karte
	#   ── SOFORTKAUF ──   3 Karten fuer genau diesen Lauf
	host.chest_page = host._make_page("SHOP")
	var box = host._page_box(host.chest_page)
	box.add_theme_constant_override("separation", 10)
	print("[SHOP][STIL] bausteine=3 quelle=ui_style panel=slot_banner+slot_button")

	# ---- ZURUECK fest oben links ----
	var back_top: Button = host._make_pixel_button("ZURÜCK", Color(0.32, 0.35, 0.42), 26)
	back_top.add_theme_font_override("font", host._shop_font())
	back_top.position = Vector2(40, 24)
	back_top.custom_minimum_size = Vector2(210, 64)
	back_top.size = Vector2(210, 64)
	back_top.pressed.connect(host._close_pages)
	host.chest_page.add_child(back_top)
	host.shop_back_top = back_top

	# ---- Waehrungen fest oben rechts ----
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.alignment = BoxContainer.ALIGNMENT_END
	head.anchor_left = 0.0
	head.anchor_right = 1.0
	head.offset_left = 0.0
	head.offset_right = -120.0
	head.offset_top = 24.0
	head.offset_bottom = 88.0
	host.chest_page.add_child(head)
	host.shop_gold_chip = host._make_chip("🪙 0", Color(0.34, 0.27, 0.10), 34)
	host.gems_label = host._make_chip("💎 0", Color(0.14, 0.32, 0.42), 34)
	head.add_child(host.shop_gold_chip)
	head.add_child(host.gems_label)

	# ---- Scrollbereich ----
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1700, 830)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	# v1.56c (Bug 3): Der ScrollContainer darf Finger-Zuege NICHT selbst
	# schlucken - sonst verliert der Knopf darunter das Release (Messung:
	# ab 8 px Fingerweg oeffnet die Kiste nicht mehr). Gescrollt wird
	# zentral in ui_manager._input (mit Tipp-Schwelle).
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.gui_input.connect(func(ev):
		if ev is InputEventScreenDrag:
			# v1.56c (Bug 3): Mini-Bewegung (Tipp) darf nicht scrollen
			if absf(ev.relative.y) < 6.0:
				return
			scroll.scroll_vertical -= int(ev.relative.y)
		elif ev is InputEventMouseButton and ev.pressed:
			if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll.scroll_vertical += 120
			elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll.scroll_vertical -= 120)
	box.add_child(scroll)
	host.shop_scroll = scroll

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(1700, 0)
	col.add_theme_constant_override("separation", 14)
	scroll.add_child(col)

	var top_pad := Control.new()
	top_pad.name = "TopPad"
	top_pad.custom_minimum_size = Vector2(0, 12)
	top_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top_pad)

	# ---- KISTEN ----
	col.add_child(host._slot_banner("KISTEN", 40))
	var chest_row := HBoxContainer.new()
	chest_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chest_row.add_theme_constant_override("separation", 34)
	col.add_child(chest_row)
	chest_row.add_child(_chest_card("standard", "STANDARD", Color(0.46, 0.32, 0.18), [44, 15, 5, 1]))
	chest_row.add_child(_chest_card("silver", "SILBER", Color(0.62, 0.66, 0.74), [20, 30, 13, 2]))
	chest_row.add_child(_chest_card("premium", "PREMIUM", Color(0.72, 0.52, 0.92), [0, 39, 19, 6]))

	# ---- UMTAUSCH ----
	col.add_child(host._slot_banner("UMTAUSCH", 40))
	col.add_child(_exchange_panel())

	# ---- GLUECKSAUTOMATEN (v1.45 Z7: Walze + Rad nebeneinander) ----
	col.add_child(host._slot_banner("GLÜCKSAUTOMATEN", 40))
	var auto_row := HBoxContainer.new()
	auto_row.name = "AutomatRow"
	auto_row.alignment = BoxContainer.ALIGNMENT_CENTER
	auto_row.add_theme_constant_override("separation", 24)
	col.add_child(auto_row)
	auto_row.add_child(_slot_section())
	auto_row.add_child(_wheel_section())
	print("[LAYOUT] seite=shop automaten=2 reihe=hbox abstand=24")

	# ---- v1.49: SOFORTKAUF (Portionen) entfernt ----
	print("[SHOP][VORAB] entfernt=1 grund=abstuerze_in_mehreren_modi sektionen=3")

	host.chest_msg = Label.new()
	host.chest_msg.text = ""
	host.chest_msg.label_settings = host._make_label_settings(20, Color(0.95, 0.85, 0.45), 4)
	host.chest_msg.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(host.chest_msg)

	var back: Button = host._make_pixel_button("ZURÜCK", Color(0.32, 0.35, 0.42), 26)
	back.custom_minimum_size = Vector2(210, 68)
	back.add_theme_font_override("font", host._shop_font())
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(host._close_pages)
	col.add_child(back)
	host.shop_back_bottom = back

	# ---- Trefferflaeche fuer den oberen ZURUECK (v1.43 A3) ----
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.chest_page.move_child(back_top, host.chest_page.get_child_count() - 1)
	back_top.z_index = 10
	back_top.mouse_filter = Control.MOUSE_FILTER_STOP
	var hit := Button.new()
	hit.name = "BackHitTop"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.position = Vector2(0, 0)
	hit.size = Vector2(260, 104)
	hit.z_index = 11
	hit.pressed.connect(host._close_pages)
	host.chest_page.add_child(hit)
	print("[SHOP][BACK] trefferflaeche gebaut: knopf=(40,24,210x64) streifen=(0,0,260x104) head_ignore=true")


func _open_chest_page() -> void:
	if host.chest_page == null:
		_create_chest_page()
	host._close_pages()
	host.chest_page.show()
	if host.shop_scroll != null:
		host.shop_scroll.scroll_vertical = 0
	refresh_chest_page()
	# R8: Layout erst messen, wenn Godot gerechnet hat (ein Frame warten).
	await host.get_tree().process_frame
	_log_layout()
	# A4-Beleg: Scroll steht auf 0, Innenabstand oben 28 px
	print("[SHOP][SCROLL] scroll_vertical=%d (Start 0) top_pad=28" % (
		host.shop_scroll.scroll_vertical if host.shop_scroll != null else -1))


func _chest_card(tier: String, title: String, accent: Color, odds: Array) -> Control:
	# R2/R3: Automaten-Karte. Oben ein FENSTER (320x300) mit Goldrand, in dem
	# die Kiste sitzt; darunter Namensbalken, vier Chancen-Zeilen und Kaufknopf.
	var card := PanelContainer.new()
	card.name = "ShopChest_" + tier
	card.custom_minimum_size = Vector2(500, 0)
	card.add_theme_stylebox_override("panel", host._slot_panel_sb(16, 3))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)

	# --- Fenster ---
	var win := PanelContainer.new()
	win.name = "ChestWindow_" + tier
	win.custom_minimum_size = Vector2(320, 300)
	win.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var wsb := StyleBoxFlat.new()
	wsb.bg_color = Color(0.05, 0.05, 0.08, 1.0)
	wsb.border_color = Color(0.99, 0.80, 0.22, 0.92)
	wsb.set_border_width_all(4)
	wsb.set_corner_radius_all(4)
	win.add_theme_stylebox_override("panel", wsb)
	v.add_child(win)

	# R3: Innenfeld mit 15 px Rand, damit das Bild NIE das Fenster ausfuellt
	# (270 px = 90 % von 300 -> 15 px Luft oben und unten).
	var pad_holder := CenterContainer.new()
	pad_holder.custom_minimum_size = Vector2(316, 296)
	pad_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	win.add_child(pad_holder)
	# v1.52: Die Kiste wird GEZEICHNET (ChestView) statt als 64-px-Textur
	# hochskaliert - Vorschau und Oeffnung zeigen damit dieselbe Optik.
	# v1.53: eine Optik - POW (ChestOpenUI.STYLE_FIXED)
	var stil: int = ChestView.STYLE_POW
	var img := ChestView.new()
	img.name = "ChestImage_" + tier
	img.size = Vector2(270, 270)
	img.custom_minimum_size = Vector2(270, 270)
	img.set_style(stil)
	img.set_tier(tier)
	img.set_state(-1.0, 0.25)
	pad_holder.add_child(img)
	print("[SHOP][KISTE] tier=%s vorschau=chest_view stil=%s px=270" % [
		tier, ChestView.STYLE_NAMES[stil]])
	# R10: EIN lebendes Bild (Premium atmet), keine Dauer-Tweens auf allen drei -
	# jeder Tween auf einem skalierten Bild kostet pro Frame Redraw.
	if tier == "premium":
		img.pivot_offset = Vector2(154, 135)
		var bob := img.create_tween()
		bob.set_loops()
		bob.tween_property(img, "scale", Vector2(1.03, 1.03), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(img, "scale", Vector2(1.0, 1.0), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	card.set_meta("img", img)
	card.set_meta("win", win)

	# --- Namensbalken ---
	var name_bar := PanelContainer.new()
	name_bar.custom_minimum_size = Vector2(0, 44)
	var nsb := StyleBoxFlat.new()
	nsb.bg_color = accent.darkened(0.45)
	nsb.border_color = Color(0.99, 0.80, 0.22, 0.75)
	nsb.set_border_width_all(3)
	nsb.set_corner_radius_all(3)
	name_bar.add_theme_stylebox_override("panel", nsb)
	v.add_child(name_bar)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.label_settings = host._make_label_settings(26, Color(0.99, 0.90, 0.62), 6)
	name_bar.add_child(t)

	# --- Vier Chancen-Zeilen: Name, Punkte, Prozent ---
	var rar := ["GEWÖHNLICH", "SELTEN", "EPISCH", "LEGENDÄR"]
	for i in range(4):
		var val: int = int(odds[i]) if i < odds.size() else 0
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(0, 26)
		v.add_child(row)
		var rl := Label.new()
		rl.text = str(rar[i])
		rl.label_settings = host._make_label_settings(17, Color(0.80, 0.84, 0.90), 4)
		rl.custom_minimum_size = Vector2(150, 0)
		rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(rl)
		var dots := Label.new()
		var n: int = clampi(int(ceil(float(val) / 12.0)), 0, 4)
		dots.text = "●".repeat(n) + "○".repeat(4 - n)
		dots.label_settings = host._make_label_settings(16, Color(0.99, 0.80, 0.22), 0)
		dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dots.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(dots)
		var pl := Label.new()
		pl.text = "%d %%" % val
		pl.label_settings = host._make_label_settings(20, Color(0.96, 0.97, 1.0), 4)
		pl.custom_minimum_size = Vector2(78, 0)
		pl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(pl)

	# --- Kaufknopf ---
	var b: Button = host._slot_button("%d 💎 ÖFFNEN" % LootTable.chest_cost(tier), 24)
	b.name = "BuyChest_" + tier
	b.custom_minimum_size = Vector2(320, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		print("[TOUCH][KNOPF] tier=%s treffer=true -> oeffnen" % tier)
		host.call("_on_chest_open", tier))
	v.add_child(b)
	# v1.57b: Die GANZE Karte oeffnet die Kiste. Auf dem Handy ist der Knopf
	# nur 36 px hoch (Canvas 1920x4160 -> Fenster 1080x2340); ein Tipp daneben
	# (auf Bild oder Chancen-Zeilen) lief bisher ins Leere - genau das fuehlt
	# sich wie "Kisten lassen sich nicht antippen" an.
	card.gui_input.connect(func(ev):
		if ev is InputEventScreenTouch and not ev.pressed:
			print("[TOUCH][KARTE] tier=%s flaeche=karte pos=(%.0f,%.0f) -> oeffnen" % [
				tier, ev.position.x, ev.position.y])
			host.call("_on_chest_open", tier)
		elif ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			print("[TOUCH][KARTE] tier=%s flaeche=karte maus=true -> oeffnen" % tier)
			host.call("_on_chest_open", tier))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	# v1.57c: Alles ausser Knoepfen ist "durchlaessig" - sonst schluckt das
	# Kistenbild (ChestView) den Tipp und die Karten-Trefferflaeche kommt nie
	# zum Zug (Messung: Tipp auf das Bild = keine Oeffnung).
	var durchlaessig: int = 0
	for c in card.find_children("*", "Control", true, false):
		if c is Button:
			continue
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		durchlaessig += 1
	print("[SHOP][KARTE] tier=%s fenster=320x300 balken=true chancen_zeilen=4 knopf=true bild=308x270" % tier)
	# v1.57c: eigene Zeile, damit die Golden-Referenz der Kartenzeile unberuehrt bleibt
	print("[SHOP][KARTE][TIP] tier=%s durchlaessig=%d ganz_flaeche=true" % [tier, durchlaessig])
	return card


func _exchange_panel() -> Control:
	# R5: DREI Streifen in EINEM Panel, getrennt durch zwei Akzentlinien.
	var panel := PanelContainer.new()
	panel.name = "ExchangePanel"
	panel.custom_minimum_size = Vector2(1660, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", host._slot_panel_sb(14, 3))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	var n: int = 0
	for pkg in host.game_manager.GEM_PACKAGES:
		if n > 0:
			var ln := ColorRect.new()
			ln.color = Color(0.99, 0.80, 0.22, 0.30)
			ln.custom_minimum_size = Vector2(0, 2)
			ln.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.add_child(ln)
		col.add_child(_exchange_strip(n, int(pkg["gold"]), int(pkg["gems"])))
		n += 1
	print("[SHOP][UMTAUSCH] panel=true streifen=%d trennlinien=%d" % [n, n - 1])
	return panel


func _exchange_strip(idx: int, gold_cost: int, gems: int) -> Control:
	# R4: links Goldbetrag mit Muenze, Pfeil, rechts Diamanten mit Stein,
	# ganz rechts EIN Knopf (240x64). Kein Symbol im Knopftext.
	var row := HBoxContainer.new()
	row.name = "ExchangeStrip_%d" % idx
	row.custom_minimum_size = Vector2(0, 76)
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var gold_icon := TextureRect.new()
	gold_icon.texture = TextureManager.get_texture("slot_gold3")
	gold_icon.custom_minimum_size = Vector2(56, 56)
	gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	row.add_child(gold_icon)

	var g_amount := Label.new()
	g_amount.text = _num_dots(gold_cost) + " GOLD"
	g_amount.label_settings = host._make_label_settings(34, Color(0.99, 0.86, 0.40), 6)
	g_amount.custom_minimum_size = Vector2(320, 0)
	g_amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(g_amount)

	var arrow := Label.new()
	arrow.text = "➜"
	arrow.label_settings = host._make_label_settings(34, Color(0.95, 0.95, 0.98), 6)
	arrow.custom_minimum_size = Vector2(64, 0)
	arrow.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(arrow)

	var gem_lvl: int = 1
	if gems >= 25:
		gem_lvl = 3
	elif gems >= 10:
		gem_lvl = 2
	var gem_icon := TextureRect.new()
	gem_icon.texture = TextureManager.get_texture("slot_gem%d" % gem_lvl)
	if gem_icon.texture == null:
		print("[SHOP][FEHLER] Diamant-Piktogramm fehlt lvl=%d" % gem_lvl)
	gem_icon.custom_minimum_size = Vector2(56, 56)
	gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	row.add_child(gem_icon)

	var m_amount := Label.new()
	m_amount.text = "%d DIAMANT" % gems if gems == 1 else "%d DIAMANTEN" % gems
	m_amount.label_settings = host._make_label_settings(34, Color(0.60, 0.92, 1.0), 6)
	m_amount.custom_minimum_size = Vector2(360, 0)
	m_amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(m_amount)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size = Vector2(20, 1)
	row.add_child(spacer)

	var b: Button = host._slot_button("TAUSCHEN", 24)
	b.name = "ExchangeBtn_%d" % idx
	b.custom_minimum_size = Vector2(240, 64)
	b.pressed.connect(_on_gem_package.bind(idx))
	row.add_child(b)
	print("[SHOP][UMTAUSCH] idx=%d streifen=true knopf=240x64 icon_im_text=false gold=%d gems=%d" % [
		idx, gold_cost, gems])
	return row


func _slot_section() -> Control:
	# R6: Walzen-Abschnitt - oeffnet unveraendert slot_ui, nur im Banner-Look.
	var card := PanelContainer.new()
	card.name = "SlotSection"
	card.custom_minimum_size = Vector2(660, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", host._slot_panel_sb(18, 4))
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 10)
	card.add_child(sv)
	var sicon := TextureRect.new()
	sicon.texture = TextureManager.get_texture("slot_machine_icon")
	sicon.custom_minimum_size = Vector2(300, 210)
	sicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sicon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sicon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sv.add_child(sicon)
	var stitle := Label.new()
	stitle.text = "NUR GOLD  ·  EINSATZ 1–5.000  ·  TREFFERCHANCE 21 %"
	stitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	stitle.label_settings = host._make_label_settings(20, Color(1.0, 0.88, 0.50), 5)
	sv.add_child(stitle)
	var sbtn: Button = host._slot_button("🪙  DREHEN", 28)
	sbtn.name = "SlotOpenBtn"
	sbtn.custom_minimum_size = Vector2(520, 82)
	sbtn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sbtn.pressed.connect(host._open_slot_ui)
	sv.add_child(sbtn)
	print("[SHOP][WALZE] oeffnet=true stil=banner")
	return card


func _wheel_section() -> Control:
	# Z7: zweiter Automat - gleiche Karte, gleicher Banner-Stil, gleicher
	# Knopf. Das Vorschaubild ist das gezeichnete Rad (kein PNG).
	var card := PanelContainer.new()
	card.name = "WheelSection"
	card.custom_minimum_size = Vector2(660, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", host._slot_panel_sb(18, 4))
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 10)
	card.add_child(sv)
	# Fester Rahmen 300x210 (wie das Walzenbild) - sonst wird die Karte
	# hoeher als die Walzenkarte und die Knoepfe stehen auf verschiedenen Hoehen.
	var pframe := Control.new()
	pframe.name = "WheelPreviewFrame"
	pframe.custom_minimum_size = Vector2(300, 210)
	pframe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pframe.clip_contents = true
	sv.add_child(pframe)
	var prev: Control = load("res://scripts/ui/wheel_view.gd").new()
	prev.name = "WheelPreview"
	prev.set("labels_an", false)
	prev.call("set_radius", 200.0)
	prev.position = Vector2(50, 5)
	prev.size = Vector2(200, 200)
	prev.custom_minimum_size = Vector2(200, 200)
	pframe.add_child(prev)
	var wtitle := Label.new()
	wtitle.text = "GOLD + DIAMANTEN  ·  EINSATZ 100–5.000  ·  8 SEGMENTE"
	wtitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	wtitle.label_settings = host._make_label_settings(20, Color(1.0, 0.88, 0.50), 5)
	sv.add_child(wtitle)
	var wbtn: Button = host._slot_button("🎡  DREHEN", 28)
	wbtn.name = "WheelOpenBtn"
	wbtn.custom_minimum_size = Vector2(520, 82)
	wbtn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wbtn.pressed.connect(host._open_wheel_ui)
	sv.add_child(wbtn)
	print("[SHOP][RAD] oeffnet=true stil=banner rad=gezeichnet segmente=%d" % WheelMachineScript.SEGMENTS)
	return card


func _num_dots(v: int) -> String:
	# 1000 -> "1.000"
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if v < 0 else "") + out


func _log_layout() -> void:
	# R8: Inhalt vs. Canvas, Ueberlauf, rechter Rand; R3: Bildmasse im Fenster.
	if host.chest_page == null:
		return
	var vp: Vector2 = host.chest_page.get_viewport().get_visible_rect().size
	var box: VBoxContainer = host._page_box(host.chest_page)
	var inhalt: Vector2 = box.get_combined_minimum_size()
	var max_rechts: float = 0.0
	for c in box.find_children("*", "Control", true, false):
		var cc := c as Control
		if cc == null or not cc.is_visible_in_tree():
			continue
		if cc is ColorRect:
			continue      # dunkler Grund / Trennlinien liegen absichtlich breit
		max_rechts = maxf(max_rechts, cc.get_global_rect().end.x)
	var scroll_h: float = float(host.shop_scroll.custom_minimum_size.y) if host.shop_scroll != null else 0.0
	print("[LAYOUT] seite=shop inhalt=(%.0f,%.0f) canvas=(%.0f,%.0f) scroll=(%.0f,%.0f) ueberlauf=%s max_rechts=%.0f" % [
		inhalt.x, inhalt.y, vp.x, vp.y,
		float(host.shop_scroll.custom_minimum_size.x) if host.shop_scroll != null else 0.0, scroll_h,
		str(max_rechts > vp.x - 20.0), max_rechts])
	for tier in ["standard", "silver", "premium"]:
		var card: Control = host.chest_page.find_child("ShopChest_" + tier, true, false)
		if card == null:
			continue
		var img: Control = card.get_meta("img", null)
		var win: Control = card.get_meta("win", null)
		if img == null or win == null:
			continue
		var ir: Rect2 = img.get_global_rect()
		var wr: Rect2 = win.get_global_rect()
		var luft: float = (wr.size.y - ir.size.y) * 0.5
		print("[SHOP][KARTE] tier=%s bild=%.0fx%.0f fenster=%.0fx%.0f luft=%.0fpx keep_aspect=true" % [
			tier, ir.size.x, ir.size.y, wr.size.x, wr.size.y, luft])


func refresh_chest_page() -> void:
	if host.game_manager == null:
		return
	if host.gems_label != null:
		var gl = host.gems_label.get_meta("label", null)
		if gl != null:
			gl.text = "💎 %d" % host.game_manager.gems
	if host.shop_gold_chip != null:
		var gol = host.shop_gold_chip.get_meta("label", null)
		if gol != null:
			gol.text = "🪙 %d" % host.game_manager.gold


func _on_gem_package(i: int) -> void:
	if host.game_manager == null:
		return
	var gold_vor: int = int(host.game_manager.gold)
	var ok: bool = host.game_manager.call("exchange_gold_for_gems", i)
	var pkg0: Dictionary = host.game_manager.GEM_PACKAGES[i]
	print("[SHOP][TAUSCH] idx=%d gold_vorher=%d nachher=%d gems=%d ok=%s" % [
		i, gold_vor, int(host.game_manager.gold), int(pkg0["gems"]), str(ok)])
	if host.chest_msg != null:
		var pkg: Dictionary = host.game_manager.GEM_PACKAGES[i]
		host.chest_msg.text = ("+%d Edelsteine für %d Gold" % [int(pkg["gems"]), int(pkg["gold"])]) if ok 			else ("Zu wenig Gold - %d nötig" % int(pkg["gold"]))
	refresh_chest_page()


func _on_chest_buy(tier_id: String) -> void:
	if host.game_manager == null:
		return
	# Runde 48: Der Kauf oeffnet nur das Bestaetigungs-Fenster.
	# Die Kiste wird erst nach einem weiteren Klick geoeffnet.
	if int(host.game_manager.gold) < int(host.game_manager.chest_price(tier_id)):
		host.show_banner("ZU WENIG GOLD", Color(1.0, 0.5, 0.35))
		return
	host.chest_pending_tier = tier_id
	_show_chest_confirm(tier_id)


func _show_chest_confirm(tier_id: String) -> void:
	# Runde 48: eigenes Fenster - der ganze Fokus liegt auf der Kiste.
	if host.chest_overlay == null:
		host._build_chest_overlay()
	host.chest_overlay.set_meta("mode", "confirm")
	# Title aendern
	for c in host.chest_overlay.find_children("*", "Label", true, false):
		if (c as Label).text == "KISTE GEOEFFNET":
			(c as Label).text = "KISTE VERWENDEN"
	# Kisten-Icon in der Buehne zeigen
	var tname: String = "HOLZKISTE"
	var tprice: int = 0
	for tier in host.game_manager.CHESTS:
		if str(tier["id"]) == tier_id:
			tname = str(tier["name"])
			tprice = int(tier["price"])
			host.chest_box_icon.texture = TextureManager.get_texture(str(tier["icon"]))
	if host.chest_box_icon != null:
		host.chest_box_icon.visible = true
		host.chest_box_icon.modulate.a = 1.0
		host.chest_box_icon.scale = Vector2(1, 1)
		host.chest_box_icon.rotation = 0.0
		host.chest_result_icon.visible = false
	# Bestaetigungs-UI
	if host.chest_confirm_btn != null:
		host.chest_confirm_btn.visible = true
		host.chest_confirm_btn.text = "OEFFNEN  (%d Gold)" % tprice
	if host.chest_ok_btn != null:
		host.chest_ok_btn.visible = false
	if host.chest_confirm_hint != null:
		host.chest_confirm_hint.visible = true
	if host.chest_item_box != null:
		for c in host.chest_item_box.get_children():
			host.chest_item_box.remove_child(c)
			c.queue_free()
	host.chest_item_rows.clear()
	if host.chest_result_label != null:
		host.chest_result_label.visible = false
	host.chest_overlay.visible = true


func _on_chest_confirm() -> void:
	# Runde 48: der zweite Klick - jetzt wird die Kiste wirklich geoeffnet
	if host.game_manager == null:
		return
	var gems_vor: int = int(host.game_manager.gems)
	var gold_vor: int = int(host.game_manager.gold)
	var res: Dictionary = host.game_manager.open_chest(host.chest_pending_tier)
	print("[SHOP][KAUF] tier=%s abgebucht=%d gold_vorher=%d nachher=%d gems_vorher=%d nachher=%d ok=%s" % [
		str(host.chest_pending_tier), gold_vor - int(host.game_manager.gold),
		gold_vor, int(host.game_manager.gold), gems_vor, int(host.game_manager.gems),
		str(bool(res.get("ok", false)))])
	if not bool(res.get("ok", false)):
		print("[SHOP][KAUF] FEHLER tier=%s grund=zu_wenig_gold" % str(host.chest_pending_tier))
	if not bool(res.get("ok", false)):
		host.show_banner("ZU WENIG GOLD", Color(1.0, 0.5, 0.35))
		host._on_chest_ok()
		return
	SoundManager.play("levelup")
	host.show_chest_result(res)
	host.refresh_shop_ui()
	host.refresh_profile_ui()
