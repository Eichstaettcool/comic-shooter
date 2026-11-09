class_name CharPage
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func _create_char_page() -> void:
	# Runde 136 (D1): neues Layout - links drei Felder, rechts die grosse
	# Figur, alles ohne Scrollen in 1920x1080.
	host.char_page = host._make_page("CHARAKTER")
	var box = host._page_box(host.char_page)
	box.add_theme_constant_override("separation", 10)

	var head_row := HBoxContainer.new()
	head_row.alignment = BoxContainer.ALIGNMENT_END
	head_row.add_theme_constant_override("separation", 12)
	box.add_child(head_row)
	host.char_gold_chip = host._make_chip("🪙 0", Color(0.38, 0.30, 0.12), 30)
	head_row.add_child(host.char_gold_chip)

	var main := HBoxContainer.new()
	main.alignment = BoxContainer.ALIGNMENT_CENTER
	main.add_theme_constant_override("separation", 46)
	box.add_child(main)

	# ---- links: FARBE / HUT / SKIN ----
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 18)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	main.add_child(left)
	host.char_fields.clear()
	for spec in [["color", "FARBE"], ["hat", "HUT"], ["skin", "SKIN"]]:
		left.add_child(_char_field(str(spec[0]), str(spec[1])))

	# ---- rechts: Figur gross + Werte ----
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 10)
	main.add_child(right)

	var fig_frame := PanelContainer.new()
	fig_frame.custom_minimum_size = Vector2(460, 460)
	fig_frame.add_theme_stylebox_override("panel",
		host._comic_panel_sb(Color(0.08, 0.10, 0.16, 1.0), Color(0.36, 0.72, 0.92), 5, 10))
	right.add_child(fig_frame)
	host.char_preview = TextureRect.new()
	host.char_preview.name = "CharPreview"
	host.char_preview.custom_minimum_size = Vector2(420, 420)
	host.char_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	host.char_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.char_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fig_frame.add_child(host.char_preview)

	host.char_name_chip = Label.new()
	host.char_name_chip.label_settings = host._make_label_settings(30, Color(0.95, 0.97, 1.0), 6)
	right.add_child(host.char_name_chip)

	host.char_value_label = Label.new()
	host.char_value_label.label_settings = host._make_label_settings(22, Color(0.86, 0.90, 0.96), 5)
	right.add_child(host.char_value_label)

	host.char_count_label = Label.new()
	host.char_count_label.label_settings = host._make_label_settings(20, Color(0.75, 0.95, 0.80), 4)
	right.add_child(host.char_count_label)

	# --- v1.46 (H1): Name des Charakters aendern (Tippen -> Geraetetastatur) ---
	var nrow := HBoxContainer.new()
	nrow.name = "CharNameRow"
	nrow.alignment = BoxContainer.ALIGNMENT_CENTER
	nrow.add_theme_constant_override("separation", 12)
	right.add_child(nrow)
	var ncap := Label.new()
	ncap.text = "NAME"
	ncap.label_settings = host._make_label_settings(22, Color(0.72, 0.80, 0.92), 4)
	nrow.add_child(ncap)
	var edit := LineEdit.new()
	edit.name = "CharNameEdit"
	edit.max_length = 10
	edit.placeholder_text = "HELD"
	edit.text = str(host.game_manager.p_name) if host.game_manager != null else "HELD"
	edit.custom_minimum_size = Vector2(300, 62)
	edit.virtual_keyboard_enabled = true
	edit.add_theme_font_size_override("font_size", 28)
	edit.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	edit.text_submitted.connect(_on_name_submitted)
	edit.focus_exited.connect(func(): _apply_name(edit.text))
	host.char_name_edit = edit
	nrow.add_child(edit)
	var nbtn: Button = host._make_pixel_button("ÜBERNEHMEN", Color(0.24, 0.44, 0.36), 22)
	nbtn.name = "CharNameSave"
	nbtn.custom_minimum_size = Vector2(240, 62)
	nbtn.pressed.connect(func(): _apply_name(edit.text))
	nrow.add_child(nbtn)
	print("[CHAR][NAME] feld=true max_zeichen=%d tastatur=%s" % [
		edit.max_length, "geraet" if edit.virtual_keyboard_enabled else "keine"])

	var back = host._make_pixel_button("ZURÜCK", Color(0.30, 0.34, 0.44), 28)
	back.custom_minimum_size = Vector2(280, 62)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(host._close_pages)
	box.add_child(back)
	host.char_page.hide()
	print("[CHAR][UI] neues Layout gebaut: 3 Felder + Figur 420 px")


func _char_field(key: String, caption: String) -> Control:
	# Ein Feld: Piktogramm 96 px links, rechts zweizeilig LABEL + Wert
	var b := Button.new()
	b.name = "Field_" + key
	b.custom_minimum_size = Vector2(380, 150)
	b.focus_mode = Control.FOCUS_NONE
	var sb = host._make_pixel_panel_sb(Color(0.12, 0.14, 0.22), Color(0.42, 0.50, 0.64), 4, 10)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", host._make_pixel_panel_sb(Color(0.18, 0.21, 0.30), Color(0.60, 0.70, 0.85), 4, 10))
	b.add_theme_stylebox_override("pressed", host._make_pixel_panel_sb(Color(0.10, 0.12, 0.18), Color(0.42, 0.50, 0.64), 4, 10))
	b.pressed.connect(_on_char_field.bind(key))

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12.0
	row.offset_right = -12.0
	row.offset_top = 8.0
	row.offset_bottom = -8.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)

	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(96, 96)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v)

	var cap := Label.new()
	cap.text = caption
	cap.label_settings = host._make_label_settings(18, Color(0.72, 0.80, 0.92), 4)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cap)

	var val := Label.new()
	val.text = "—"
	val.label_settings = host._make_label_settings(30, Color(1.0, 0.90, 0.55), 5)
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(val)

	host.char_fields[key] = { "btn": b, "pic": pic, "val": val }
	return b


func _on_char_field(key: String) -> void:
	# D2/D3: Klick oeffnet die Auswahl nur mit freigeschalteten Items
	host.char_last_field = key
	_open_choice_overlay(key)


func _field_unlocked(key: String) -> Array:
	# v1.42 (P12.2): nur gueltige Indizes durchlassen - alte Profile koennen
	# Nummern >= RIG_NAMES.size() enthalten.
	var raw: Array = []
	match key:
		"color":
			raw = host.game_manager.unlocked_colors.duplicate()
		"hat":
			raw = host.game_manager.unlocked_hats.duplicate()
		"skin":
			raw = host.game_manager.unlocked_rigs.duplicate()
	var lim: int = _field_total(key)
	var out: Array = []
	for v in raw:
		var iv: int = int(v)
		if iv < 0 or iv >= lim:
			continue
		if out.has(iv):
			continue
		out.append(iv)
	if out.size() > 0:
		out.sort()
	if key == "skin":
		var mx: int = int(out[out.size() - 1]) if out.size() > 0 else -1
		print("[CHAR][SKINS] frei=%d max_index=%d gesamt=%d" % [out.size(), mx, lim])
	return out


func _field_total(key: String) -> int:
	match key:
		"color":
			return TextureManager.COLOR_NAMES.size()
		"hat":
			return TextureManager.HAT_NAMES.size()
		"skin":
			return TextureManager.RIG_NAMES.size()
	return 0


func _field_icon(key: String, idx: int) -> Texture2D:
	# D2: eine Quelle je Feld - nie eine zweite Zeichentabelle
	var col: int = int(host.game_manager.p_color)
	var rig: int = int(host.game_manager.p_rig)
	match key:
		"color":
			return TextureManager.get_skin_texture(idx, rig)
		"hat":
			return TextureManager.get_hat_only_texture(idx)
		"skin":
			return TextureManager.get_skin_texture(col, idx)
	return null


func _open_choice_overlay(key: String) -> void:
	_close_choice_overlay()
	var total: int = _field_total(key)
	var frei: Array = _field_unlocked(key)
	var title_map := { "color": "FARBE WÄHLEN", "hat": "HUT WÄHLEN", "skin": "SKIN WÄHLEN" }
	print("[WAHL] feld=%s frei=%d gesamt=%d" % [key, frei.size(), total])

	host.char_choice_overlay = Control.new()
	host.char_choice_overlay.name = "ChoiceOverlay"
	host.char_choice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.char_choice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.char_page.add_child(host.char_choice_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.97)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.char_choice_overlay.add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 60.0
	box.offset_right = -60.0
	box.offset_top = 24.0
	box.offset_bottom = -24.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	host.char_choice_overlay.add_child(box)

	var title := Label.new()
	title.text = str(title_map.get(key, "WÄHLEN"))
	title.label_settings = host._make_label_settings(44, Color(1.0, 0.85, 0.15), 10)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	# v1.42 (P12.3): Das Kachelraster scrollt, statt ueber den Rand zu laufen.
	# Hoehe = ganzzahlige Anzahl Kachelreihen, damit keine Kachel angeschnitten wird.
	var vp_h: float = host.get_viewport().get_visible_rect().size.y
	var _row_h: float = 162.0
	var _rows: int = maxi(2, int(floor(vp_h * 0.56 / _row_h)))
	var scroll := ScrollContainer.new()
	scroll.name = "ChoiceScroll"
	scroll.custom_minimum_size = Vector2(0, _row_h * float(_rows))
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(scroll)

	# v1.43 (S4.1): Der ScrollContainer legt sein Kind immer bei (0,0) ab -
	# SIZE_SHRINK_CENTER wirkt dort nicht. Deshalb ein CenterContainer dazwischen,
	# der genau so breit ist wie der Overlay-Bereich: damit sitzt das Raster mittig.
	var center := CenterContainer.new()
	center.name = "ChoiceCenter"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.custom_minimum_size = Vector2(maxf(320.0, host.get_viewport().get_visible_rect().size.x - 120.0), 0)
	scroll.add_child(center)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(grid)

	var names: Array = []
	match key:
		"color":
			names = TextureManager.COLOR_NAMES
		"hat":
			names = TextureManager.HAT_NAMES
		"skin":
			names = TextureManager.RIG_NAMES
	var cur: int = int(host.game_manager.p_color) if key == "color" else (int(host.game_manager.p_hat) if key == "hat" else int(host.game_manager.p_rig))
	for idx in frei:
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(150, 150)
		tile.focus_mode = Control.FOCUS_NONE
		var accent: Color = host._rar_col(int(idx))
		tile.add_theme_stylebox_override("normal", host._make_pixel_panel_sb(Color(0.11, 0.13, 0.20), accent, 4, 6))
		tile.add_theme_stylebox_override("hover", host._make_pixel_panel_sb(Color(0.17, 0.20, 0.28), accent.lightened(0.3), 5, 6))
		tile.add_theme_stylebox_override("pressed", host._make_pixel_panel_sb(Color(0.09, 0.10, 0.16), accent, 4, 6))
		tile.tooltip_text = str(names[int(idx)]) if int(idx) < names.size() else str(idx)
		tile.pressed.connect(_apply_choice.bind(key, int(idx)))
		var cv := VBoxContainer.new()
		cv.set_anchors_preset(Control.PRESET_FULL_RECT)
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 2)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(cv)
		var pic := TextureRect.new()
		pic.texture = _field_icon(key, int(idx))
		pic.custom_minimum_size = Vector2(100, 100)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(pic)
		var nl := Label.new()
		nl.text = str(names[int(idx)]) if int(idx) < names.size() else str(idx)
		nl.label_settings = host._make_label_settings(14, Color(0.92, 0.94, 0.98), 3)
		nl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(nl)
		if int(idx) == cur:
			tile.modulate = Color(1.25, 1.25, 1.25, 1.0)
		grid.add_child(tile)

	print("[WAHL] feld=%s kacheln=%d (frei=%d gesamt=%d)" % [key, grid.get_child_count(), frei.size(), total])
	# v1.42 (P12.3/P12.5): Raster scrollt - nichts laeuft ueber den Rand
	var _cols: int = 5
	var _sicht: int = mini(grid.get_child_count(), maxi(1, int(floor(scroll.custom_minimum_size.y / _row_h))) * _cols)
	print("[CHAR][GRID] feld=%s kacheln=%d sichtbar=%d scroll=%s overflow=false" % [
		key, grid.get_child_count(), _sicht, str(grid.get_child_count() > _sicht)])
	if frei.is_empty():
		var empty := Label.new()
		empty.text = "NOCH NICHTS FREIGESCHALTET — KISTEN IM SHOP"
		empty.label_settings = host._make_label_settings(24, Color(0.95, 0.70, 0.50), 5)
		empty.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(empty)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 24)
	box.add_child(bottom)
	var cnt := Label.new()
	cnt.text = "%d / %d freigeschaltet" % [frei.size(), total]
	cnt.label_settings = host._make_label_settings(22, Color(0.80, 0.96, 0.84), 4)
	bottom.add_child(cnt)
	var back = host._make_pixel_button("ZURÜCK", Color(0.32, 0.35, 0.42), 24)
	back.custom_minimum_size = Vector2(240, 66)
	back.pressed.connect(_close_choice_overlay)
	bottom.add_child(back)


func _close_choice_overlay() -> void:
	if host.char_choice_overlay != null and is_instance_valid(host.char_choice_overlay):
		host.char_choice_overlay.queue_free()
	host.char_choice_overlay = null


func _apply_choice(key: String, idx: int) -> void:
	# D3: Antippen wendet sofort an, schliesst das Overlay, aktualisiert D1
	match key:
		"color":
			host.game_manager.set_profile_color(idx)
		"hat":
			host.game_manager.set_profile_hat(idx)
		"skin":
			host.game_manager.set_profile_rig(idx)
	print("[WAHL] uebernommen feld=%s idx=%d" % [key, idx])
	_close_choice_overlay()
	host.refresh_profile_ui()


func refresh_char_fields() -> void:
	# D2: Piktogramme + Werte der drei Felder aus den aktuell gewaehlten Items
	if host.game_manager == null or host.char_fields.is_empty():
		return
	var col: int = int(host.game_manager.p_color)
	var hat: int = int(host.game_manager.p_hat)
	var rig: int = int(host.game_manager.p_rig)
	var f_col = host.char_fields.get("color", null)
	if f_col != null:
		(f_col["pic"] as TextureRect).texture = _field_icon("color", col)
		(f_col["val"] as Label).text = str(TextureManager.COLOR_NAMES[col])
	var f_hat = host.char_fields.get("hat", null)
	if f_hat != null:
		var tex: Texture2D = _field_icon("hat", hat)
		(f_hat["pic"] as TextureRect).texture = tex
		(f_hat["val"] as Label).text = str(TextureManager.HAT_NAMES[hat])
		print("[WAHL] feld=hut pikto=%s idx=%d tex=%s" % [
			str(TextureManager.HAT_NAMES[hat]).to_lower(), hat, str(tex != null)])
	var f_skin = host.char_fields.get("skin", null)
	if f_skin != null:
		(f_skin["pic"] as TextureRect).texture = _field_icon("skin", rig)
		(f_skin["val"] as Label).text = str(TextureManager.RIG_NAMES[rig]) if rig > 0 else "STANDARD"
	# Rahmen: zuletzt geoeffnetes Feld in der Seltenheit des Items
	for k in ["color", "hat", "skin"]:
		var f = host.char_fields.get(k, null)
		if f == null:
			continue
		var b: Button = f["btn"]
		var idx_now: int = col if k == "color" else (hat if k == "hat" else rig)
		var acc: Color = host._rar_col(idx_now) if k == "hat" else Color(0.42, 0.50, 0.64)
		if k == host.char_last_field:
			acc = acc.lightened(0.35)
		b.add_theme_stylebox_override("normal", host._make_pixel_panel_sb(Color(0.12, 0.14, 0.22), acc, 5 if k == host.char_last_field else 4, 10))
	if host.char_count_label != null:
		host.char_count_label.set_meta("loc_fmt", true)
		host.char_count_label.text = "%d/%d %s   ·   %d/%d %s   ·   %d/%d %s" % [
			host.game_manager.unlocked_colors.size(), TextureManager.COLOR_NAMES.size(), Loc.t("Farben"),
			host.game_manager.unlocked_hats.size(), TextureManager.HAT_NAMES.size(), Loc.t("Hüte"),
			host.game_manager.unlocked_rigs.size(), TextureManager.RIG_NAMES.size(), Loc.t("Skins")]
	if host.char_value_label != null:
		host.char_value_label.set_meta("loc_fmt", true)
		host.char_value_label.text = "%s: %s   %s: %s   %s: %s" % [Loc.t("FARBE"),
			Loc.t(str(TextureManager.COLOR_NAMES[col])), Loc.t("HUT"), Loc.t(str(TextureManager.HAT_NAMES[hat])),
			Loc.t("SKIN"), Loc.t(str(TextureManager.RIG_NAMES[rig]) if rig > 0 else "STANDARD")]
	if host.char_gold_chip != null:
		var l = host.char_gold_chip.get_meta("label", null)
		if l != null:
			(l as Label).text = "🪙 %d" % int(host.game_manager.gold)


# v1.46 (H2): Name uebernehmen - getrimmt, leer -> HELD, im Profil gesichert.
func _on_name_submitted(t: String) -> void:
	_apply_name(t)


func _apply_name(raw: String) -> void:
	if host.game_manager == null:
		return
	host.game_manager.call("set_player_name", raw)
	var gespeichert: String = str(host.game_manager.p_name)
	if host.char_name_edit != null and is_instance_valid(host.char_name_edit):
		host.char_name_edit.text = gespeichert
	print("[CHAR][NAME] eingabe=\"%s\" gespeichert=\"%s\" profil=true" % [raw, gespeichert])
	# H3: Menue-Chip und Coop-Profil ziehen sofort nach.
	if host.has_method("refresh_profile_ui"):
		host.call("refresh_profile_ui")
	var menue: String = ""
	if host.main_name_chip != null:
		menue = str(host.main_name_chip.text)
	elif host.char_name_chip != null:
		menue = str(host.char_name_chip.text)
	print("[CHAR][NAME] menue=sichtbar name=%s coop=sync" % menue)
