class_name CollectionPage
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func show_collection() -> void:
	# Runde 37: Sammlungs-Screen (alle Farben + Huete, Fortschritt, Equip)
	# Runde 43: Inhalt danach einpassen
	if host.collection_page == null:
		_build_collection_page()
	host._close_pages()
	host.collection_page.show()
	refresh_collection_ui()
	# v1.39 A: beim Oeffnen wieder nach oben - sonst startet die Seite dort,
	# wo zuletzt gescrollt wurde.
	var sc = host.collection_page.find_child("CollectionScroll", true, false)
	if sc is ScrollContainer:
		(sc as ScrollContainer).scroll_vertical = 0


func _build_collection_page() -> void:
	host.collection_page = host._make_page("SAMMLUNG")
	# Runde 37: den vorhandenen Box-Container der Seite nutzen
	# (Panel = child 1 der Seite, darin die VBox = child 0)
	var panel = host.collection_page.get_child(1) as PanelContainer
	var box: VBoxContainer = panel.get_child(0) as VBoxContainer

	# v1.39 A1: Inhalt in einen Scrollbereich. Bei vollem Profil
	# (10 Farben + 25 Skins + 29 Huete) ist die Seite hoeher als der Schirm -
	# ohne Scrollen lag der ZURUECK-Knopf ausserhalb und die Sammlung war
	# nicht mehr zu verlassen (Meldung "Sammlung ist kaputt").
	var scroll := ScrollContainer.new()
	scroll.name = "CollectionScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var inner := VBoxContainer.new()
	inner.name = "CollectionInner"
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)

	var info := Label.new()
	info.name = "CollectionInfo"
	info.label_settings = host._make_label_settings(24, Color(1.0, 0.86, 0.40), 5)
	info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(info)

	# Runde 48: DREI getrennte Sektionen (je Header + eigenes, zentriertes
	# Kachel-Grid). Vorher lagen die Header als Zelle im selben Grid und
	# zerschoben das Raster.
	var sections := VBoxContainer.new()
	sections.name = "CollectionSections"
	sections.alignment = BoxContainer.ALIGNMENT_CENTER
	sections.add_theme_constant_override("separation", 10)
	inner.add_child(sections)

	var back = host._make_comic_button("ZURUECK", Color(0.26, 0.34, 0.52), 28)
	back.name = "CollectionBack"
	back.pressed.connect(func(): host.show_start_screen())
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_child(back)
	inner.add_child(brow)


func _refresh_skin_buttons() -> void:
	# Runde 43: Skin-Kacheln aktualisieren - Icon, Rahmen, AKTIV-Marke
	if host.game_manager == null:
		return
	for i in range(host.skin_buttons.size()):
		var sk = host.skin_buttons[i]
		if sk == null:
			continue
		var owned: bool = host.game_manager.unlocked_rigs.has(i)
		var equipped: bool = int(host.game_manager.p_rig) == i
		var rar: String = str(host.game_manager.RIG_RARITY[i]) if i < host.game_manager.RIG_RARITY.size() else "rare"
		var rcol: Color = host.game_manager.RARITY_COLORS.get(rar, Color(0.5, 0.6, 0.8))
		# Icon: Skin in der aktuell gewaehlten Farbe
		var tex = host.game_manager.skin_preview_texture(i)
		if tex != null:
			sk.icon = tex
		if equipped:
			# aktiv = goldener Rahmen + heller
			sk.add_theme_stylebox_override("normal", host._make_pixel_panel_sb(Color(0.34, 0.26, 0.10), Color(1.0, 0.84, 0.24), 5, 8))
			sk.add_theme_stylebox_override("hover", host._make_pixel_panel_sb(Color(0.40, 0.31, 0.12), Color(1.0, 0.88, 0.34), 5, 8))
			sk.add_theme_stylebox_override("pressed", host._make_pixel_panel_sb(Color(0.28, 0.22, 0.08), Color(1.0, 0.84, 0.24), 5, 8))
			sk.modulate = Color(1.18, 1.18, 1.18)
			sk.tooltip_text = str(TextureManager.RIG_NAMES[i]) + "  ·  " + str(host.game_manager.RARITY_NAMES.get(rar, rar)) + "  (AKTIV)"
		elif owned:
			sk.add_theme_stylebox_override("normal", host._make_pixel_panel_sb(Color(0.16, 0.14, 0.22), rcol, 4, 8))
			sk.add_theme_stylebox_override("hover", host._make_pixel_panel_sb(Color(0.22, 0.20, 0.30), rcol.lightened(0.2), 4, 8))
			sk.add_theme_stylebox_override("pressed", host._make_pixel_panel_sb(Color(0.12, 0.10, 0.16), rcol, 4, 8))
			sk.modulate = Color(1, 1, 1)
			sk.tooltip_text = str(TextureManager.RIG_NAMES[i]) + "  ·  " + str(host.game_manager.RARITY_NAMES.get(rar, rar))
		else:
			# gesperrt: Silhouette + Raritaetsrand
			sk.add_theme_stylebox_override("normal", host._make_pixel_panel_sb(Color(0.10, 0.10, 0.14), Color(0.28, 0.30, 0.36), 3, 8))
			sk.add_theme_stylebox_override("hover", host._make_pixel_panel_sb(Color(0.14, 0.14, 0.19), Color(0.34, 0.36, 0.44), 3, 8))
			sk.add_theme_stylebox_override("pressed", host._make_pixel_panel_sb(Color(0.08, 0.08, 0.11), Color(0.28, 0.30, 0.36), 3, 8))
			sk.modulate = Color(0.40, 0.42, 0.50, 0.9)
			sk.tooltip_text = str(TextureManager.RIG_NAMES[i]) + "  ·  " + str(host.game_manager.RARITY_NAMES.get(rar, rar)) + "  (gesperrt - im Shop)"


func _make_cat_section(parent: VBoxContainer, title: String, count: String, col: Color, columns: int) -> VBoxContainer:
	# v1.49: Kategorie = Kopfzeile + Zeilen-Container. Die Zeilen werden einzeln
	# als zentrierte HBox gebaut - ein GridContainer laesst die letzte, unvoll-
	# staendige Zeile immer links kleben (sah "verzogen" aus).
	var sec := VBoxContainer.new()
	sec.add_theme_constant_override("separation", 6)
	parent.add_child(sec)
	var l := Label.new()
	l.text = title + "   " + count
	l.label_settings = host._make_label_settings(26, col, 6)
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	sec.add_child(l)
	var rows := VBoxContainer.new()
	rows.name = "Rows_" + title
	rows.add_theme_constant_override("separation", 10)
	sec.add_child(rows)
	rows.set_meta("columns", columns)
	return rows


func _fill_rows(rows: VBoxContainer, tiles: Array) -> void:
	var cols: int = int(rows.get_meta("columns", 6))
	var i: int = 0
	while i < tiles.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		rows.add_child(row)
		for k in range(cols):
			if i + k >= tiles.size():
				break
			row.add_child(tiles[i + k])
		i += cols


func _add_cat_header(grid: GridContainer, title: String, count: String, col: Color) -> void:
	# Runde 46: Kategorie-Header in der Sammlung (z. B. "FARBEN  10/10")
	# Runde 48: der Header liegt als EIGENE ZeILE ueber der Kachelreihe
	# (vorher war er eine Grid-Spalte und zerschob das Raster).
	var l := Label.new()
	l.text = title + "   " + count
	l.label_settings = host._make_label_settings(26, col, 6)
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(0, 34)
	grid.add_child(l)


func refresh_collection_ui() -> void:
	# Runde 46: Die Sammlung zeigt ALLE drei Kategorien getrennt:
	# FARBEN, HUETE, SKINS - jeweils mit eigener Ueberschrift.
	if host.collection_page == null or host.game_manager == null:
		return
	var sections = host.collection_page.find_child("CollectionSections", true, false) as VBoxContainer
	var info = host.collection_page.find_child("CollectionInfo", true, false) as Label
	if sections == null:
		return
	for c in sections.get_children():
		sections.remove_child(c)
		c.queue_free()
	COLL_BALKEN.clear()
	var cc: int = TextureManager.COLOR_NAMES.size()
	var hc: int = TextureManager.HAT_NAMES.size()
	var rc: int = TextureManager.RIG_NAMES.size()
	var own_c: int = 0
	for i in range(cc):
		if host.game_manager.unlocked_colors.has(i):
			own_c += 1
	var own_h: int = 0
	for i in range(hc):
		if host.game_manager.unlocked_hats.has(i):
			own_h += 1
	var own_r: int = 0
	for i in range(rc):
		if host.game_manager.unlocked_rigs.has(i):
			own_r += 1
	if info != null:
		info.text = "FARBEN %d/%d      SKINS %d/%d      HUETE %d/%d" % [own_c, cc, own_r, rc, own_h, hc]

	# ---- v1.48 (B1): drei Zustaende je Kachel ----
	# FARBEN
	var grid := _make_cat_section(sections, "FARBEN", "%d / %d" % [own_c, cc], Color(0.40, 0.82, 0.48), 10)
	var pcol: int = int(host.game_manager.p_color)
	var pskin: int = int(host.game_manager.p_rig)
	var phat: int = int(host.game_manager.p_hat)
	var tiles_color: Array = []
	var tiles_skin: Array = []
	var tiles_hat: Array = []
	var order_c: Array = _sorted_indices(cc, host.game_manager.COLOR_RARITY, str(host.game_manager.p_color))
	print("[COLL][SORT] kategorie=farben reihenfolge=%s" % str(order_c))
	for i in order_c:
		var owned: bool = host.game_manager.unlocked_colors.has(i)
		var equipped: bool = pcol == i
		var rar: String = str(host.game_manager.COLOR_RARITY[i]) if i < host.game_manager.COLOR_RARITY.size() else "common"
		var tex: Texture2D = TextureManager.get_skin_hat_texture_or_player(i, pskin, phat) if owned else TextureManager.get_player_texture(i, phat)
		var t_c: Control = _tile(i, owned, equipped, rar, tex, str(TextureManager.COLOR_NAMES[i]), 0)
		tiles_color.append(t_c)
		COLL_BALKEN.append({ "item": i, "rar": rar, "bar": t_c.find_child("RarBar", true, false) })

	# SKINS
	var grid_s := _make_cat_section(sections, "SKINS", "%d / %d" % [own_r, rc], Color(0.98, 0.80, 0.20), 6)
	var order_r: Array = _sorted_indices(rc, host.game_manager.RIG_RARITY, str(host.game_manager.p_rig))
	print("[COLL][SORT] kategorie=skins reihenfolge=%s" % str(order_r))
	for i in order_r:
		var owned3: bool = host.game_manager.unlocked_rigs.has(i)
		var equipped3: bool = int(host.game_manager.p_rig) == i
		var rar3: String = str(host.game_manager.RIG_RARITY[i]) if i < host.game_manager.RIG_RARITY.size() else "rare"
		var tex3: Texture2D = TextureManager.get_skin_hat_texture_or_player(pcol, i, phat)
		var t_s: Control = _tile(i, owned3, equipped3, rar3, tex3, str(TextureManager.RIG_NAMES[i]), 1)
		tiles_skin.append(t_s)
		COLL_BALKEN.append({ "item": i, "rar": rar3, "bar": t_s.find_child("RarBar", true, false) })

	# HUETE
	var grid_h := _make_cat_section(sections, "HUETE", "%d / %d" % [own_h, hc], Color(0.70, 0.52, 0.95), 10)
	var order_h: Array = _sorted_indices(hc, host.game_manager.HAT_RARITY, str(host.game_manager.p_hat))
	print("[COLL][SORT] kategorie=huete reihenfolge=%s" % str(order_h))
	for i in order_h:
		var owned2: bool = host.game_manager.unlocked_hats.has(i)
		var equipped2: bool = int(host.game_manager.p_hat) == i
		var rar2: String = str(host.game_manager.HAT_RARITY[i]) if i < host.game_manager.HAT_RARITY.size() else "common"
		var tex2: Texture2D = TextureManager.get_skin_hat_texture_or_player(pcol, pskin, i)
		var t_h: Control = _tile(i, owned2, equipped2, rar2, tex2, str(TextureManager.HAT_NAMES[i]), 2)
		tiles_hat.append(t_h)
		COLL_BALKEN.append({ "item": i, "rar": rar2, "bar": t_h.find_child("RarBar", true, false) })

	_fill_rows(grid, tiles_color)
	_fill_rows(grid_s, tiles_skin)
	_fill_rows(grid_h, tiles_hat)

	# v1.42 (P12.2): Beleg - die Sammlung zeigt genau die vorhandenen Skins
	print("[COLL][OWNED] rigs=%d/%d farben=%d/%d huete=%d/%d" % [own_r, rc, own_c, cc, own_h, hc])
	for i in range(rc):
		print("[COLL][OWNED] rig=%d owned=%s liste=%s" % [
			i, str(host.game_manager.unlocked_rigs.has(i)), str(host.game_manager.unlocked_rigs)])
	print("[COLL][SKINS] angezeigt=%d frei=%d max_index=%d" % [rc, own_r, rc - 1])
	print("[COLL][RASTER] farben=%d huete=%d skins=%d zeilen=%d/%d/%d scroll=true" % [
		tiles_color.size(), tiles_hat.size(), tiles_skin.size(),
		grid.get_child_count(), grid_h.get_child_count(), grid_s.get_child_count()])
	for e in COLL_BALKEN:
		var bar = e.get("bar")
		if bar == null:
			continue
		var soll: Color = bar.get_meta("soll", Color.BLACK)
		var basis: Color = bar.get_meta("basis", Color.BLACK)
		var ist: Color = (bar as ColorRect).color
		var ok: bool = absf(ist.r - soll.r) <= 8.0 / 255.0 and absf(ist.g - soll.g) <= 8.0 / 255.0 and absf(ist.b - soll.b) <= 8.0 / 255.0
		print("[COLL][BALKEN] item=%d farbe=#%02x%02x%02x soll=#%02x%02x%02x basis=#%02x%02x%02x ok=%s" % [
			int(e["item"]), int(ist.r * 255.0), int(ist.g * 255.0), int(ist.b * 255.0),
			int(soll.r * 255.0), int(soll.g * 255.0), int(soll.b * 255.0),
			int(basis.r * 255.0), int(basis.g * 255.0), int(basis.b * 255.0), str(ok)])


func _readonly_tile(b: Button) -> void:
	# Runde 62: Kachel nur anzeigen - kein Klick, kein Hover.
	# "disabled" bekommt die normale Optik, damit nichts grau wirkt.
	b.focus_mode = Control.FOCUS_NONE
	var sb := b.get_theme_stylebox("normal")
	if sb != null:
		b.add_theme_stylebox_override("disabled", sb)
	b.disabled = true


# v1.48 (B1): Farben der Seltenheitsbalken, wie sie GEZEICHNET werden.
var COLL_BALKEN: Array = []


func _sorted_indices(n: int, rarity: Array, aktiv: String) -> Array:
	# v1.49: Sortierung nach Seltenheit (LEGENDAER -> GEWOEHNLICH), bei Gleichstand
	# der aktive Eintrag zuerst, danach die Originalreihenfolge.
	var rank := { "common": 0, "rare": 1, "epic": 2, "legendary": 3 }
	var idx: Array = []
	for i in range(n):
		idx.append(i)
	var act: int = int(aktiv)
	idx.sort_custom(func(a: int, b: int) -> bool:
		var ra: int = int(rank.get(str(rarity[a]) if a < rarity.size() else "common", 0))
		var rb: int = int(rank.get(str(rarity[b]) if b < rarity.size() else "common", 0))
		# Schluessel: Seltenheit zuerst, innerhalb der Stufe der aktive Eintrag vorn.
		# (Ein Comparator, der bei a==act pauschal true liefert, ist nicht konsistent
		# und kann die Reihenfolge durcheinanderbringen.)
		# Absteigend sortiert: hoehere Seltenheit zuerst, innerhalb der Stufe
		# bekommt der AKTIVE Eintrag den hoeheren Schluessel (also Platz 1).
		var ka: int = ra * 10 + (1 if a == act else 0)
		var kb: int = rb * 10 + (1 if b == act else 0)
		if ka != kb:
			return ka > kb
		return a < b)
	return idx


func _tile(idx: int, owned: bool, equipped: bool, rarity: String, tex: Texture2D,
		title: String, kat: int) -> Control:
	# v1.49 (B1): FESTE Kachel-Geometrie ohne Button - ein Panel 150x150 mit
	# Textur + Overlay, darunter Balken und Name. Kein Layout-Container kann
	# die Kachel mehr stauchen oder strecken (Ursache des "verzogenen" Fensters:
	# der Button wurde auf die Zellenhoehe gezogen, Name/Balken lagen darin).
	var holder := VBoxContainer.new()
	holder.name = "Cell_%d_%d" % [kat, idx]
	holder.custom_minimum_size = Vector2(150, 214)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_theme_constant_override("separation", 3)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := PanelContainer.new()
	frame.name = "Tile_%d_%d" % [kat, idx]
	frame.custom_minimum_size = Vector2(150, 150)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rcol: Color = host.game_manager.RARITY_COLORS.get(rarity, Color(0.5, 0.6, 0.8))
	var bg := Color(0.16, 0.14, 0.22)
	var border := rcol
	var bw := 4
	if equipped:
		bg = Color(0.34, 0.26, 0.10)
		border = Color(1.0, 0.84, 0.24)
		bw = 5
	elif not owned:
		bg = Color(0.09, 0.09, 0.12)
		border = Color(0.26, 0.27, 0.32)
		bw = 3
	frame.add_theme_stylebox_override("panel", host._make_pixel_panel_sb(bg, border, bw, 6))
	holder.add_child(frame)

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(150, 150)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(stack)
	var tr := TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 8
	tr.offset_top = 6
	tr.offset_right = -8
	tr.offset_bottom = -6
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not owned:
		tr.modulate = Color(0.42, 0.44, 0.50)
	elif equipped:
		tr.modulate = Color(1.12, 1.12, 1.12)
	stack.add_child(tr)
	if not owned:
		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.texture = TextureManager.get_texture("coll_lock")
		lock.set_anchors_preset(Control.PRESET_CENTER)
		lock.offset_left = -26
		lock.offset_top = -26
		lock.offset_right = 26
		lock.offset_bottom = 26
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(lock)

	# Seltenheitsbalken: 8 px, volle Kachelbreite
	var bar := ColorRect.new()
	bar.name = "RarBar"
	bar.custom_minimum_size = Vector2(150, 8)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bcol: Color = rcol
	if not owned:
		var g: float = rcol.get_luminance()
		bcol = Color(g, g, g).darkened(0.35)
	elif equipped:
		bcol = rcol.lightened(0.18)
	bar.color = bcol
	bar.set_meta("soll", bcol)
	bar.set_meta("basis", rcol)
	bar.set_meta("owned", owned)
	holder.add_child(bar)

	# Name (bei gesperrten gedimmt), feste zweizeilige Hoehe
	var nl := Label.new()
	nl.text = ("AKTIV\n" if equipped else "") + title
	nl.label_settings = host._make_label_settings(15, (Color(1.0, 0.90, 0.45) if equipped else (Color(0.92, 0.94, 0.98) if owned else Color(0.55, 0.57, 0.62))), 3)
	nl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size = Vector2(150, 44)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(nl)
	return holder
