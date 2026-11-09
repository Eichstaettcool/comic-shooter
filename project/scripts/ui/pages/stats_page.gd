class_name StatsPage
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
# v1.41 (F4): zwei getrennte Pfade - im Menue liegt die Seite unter
# start_screen (wie bisher), im laufenden Spiel oeffnet sie als eigenes
# Overlay ueber ui_manager mit get_tree().paused = true.
var host: Node = null

var overlay: Control = null          # v1.41: In-Game-Overlay (nur waehrend des Runs)
var overlay_cards: Array = []        # Karten des Overlays (getrennt von host.stat_cards)

const WEAPON_STATS := [
	{ "key": "weapon_pistol", "name": "PISTOLE", "desc": "Der Standard. Unendlich Munition, keine Nachladezeit. Verlaesslich, aber schwach gegen Panzer." },
	{ "key": "weapon_shotgun", "name": "SCHROTFLINTE", "desc": "6 Schuss, 3 Streu-Patronen pro Schuss. Toetet_groups im Nahbereich, reloadt aber lang." },
	{ "key": "weapon_machine", "name": "SMG", "desc": "40 Schuss Magazin, 600 RPM. Dauerfeuer, aber nach 40 Schuss 2.2s Nachladen." },
	{ "key": "weapon_laser", "name": "LASER", "desc": "24 Schuss, sehr hohe RPM und 560 px/s Geschwindigkeit. Nach 24 Schuss 1.6s Nachladen." },
	{ "key": "weapon_revolver", "name": "REVOLVER", "desc": "6 Schuss, 9 Schaden pro Schuss. Wiegt schwer, trifft aber am haeufigsten." },
]
const WEAPON_STAT_VALUES := {
	"weapon_pistol": { "damage": 3, "cooldown": 0.4, "mag": 0, "reload": 0.0 },
	"weapon_shotgun": { "damage": 5, "cooldown": 0.8, "mag": 6, "reload": 2.4 },
	"weapon_machine": { "damage": 2, "cooldown": 0.1, "mag": 40, "reload": 2.2 },
	"weapon_laser": { "damage": 2, "cooldown": 0.14, "mag": 24, "reload": 1.6 },
	"weapon_revolver": { "damage": 9, "cooldown": 1.05, "mag": 6, "reload": 1.9 },
}


func _open_stats_page() -> void:
	# v1.41 (F4): im Spiel eigenes Overlay, im Menue die alte Seite.
	if _im_spiel():
		_open_stats_overlay()
		return
	if host.stats_page == null:
		_build_stats_page()
	host._close_pages()
	host.stats_page.show()
	_refresh_stats_page()
	print("[STATS][UI] offen=true quelle=menu pause=false")


func _im_spiel() -> bool:
	# "Im Spiel" = das HUD ist sichtbar (im Menue ist es versteckt).
	var h = host.get("hud")
	if h == null or not is_instance_valid(h):
		return false
	return (h as Control).visible


# ---------------------------------------------------------------
# In-Game-Overlay (v1.41 F4)
# ---------------------------------------------------------------

func _open_stats_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = Control.new()
	overlay.name = "StatsOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(overlay)

	var dim := ColorRect.new()
	dim.name = "StatsDim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "StatsPanel"
	panel.add_theme_stylebox_override("panel", host._comic_panel_sb(Color(0.06, 0.07, 0.11, 0.98), Color(0.45, 0.72, 0.98), 7, 22))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "WAFFEN-STATS"
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.label_settings = host._make_label_settings(64, Color(1.0, 0.88, 0.40), 10)
	box.add_child(title)

	var sub := Label.new()
	sub.text = Loc.t("Tippe auf eine Waffe fuer alle Werte. SCHADEN pro Schuss, RPM = Schuesse pro Minute, NACHLADEN = Magazin-Nachladezeit.")
	sub.set_meta("loc_fmt", true)
	sub.label_settings = host._make_label_settings(19, Color(0.86, 0.90, 0.88), 4)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	overlay_cards.clear()
	_build_stat_cards(box, overlay_cards)

	var back = host._make_pixel_button(Loc.t("ZURÜCK INS SPIEL"), Color(0.20, 0.58, 0.36), 28)
	back.name = "StatsBackToGame"
	back.set_meta("loc_fmt", true)
	back.custom_minimum_size = Vector2(420, 72)
	back.pressed.connect(close_stats_overlay)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_child(back)
	box.add_child(brow)

	# Esc schliesst ebenfalls (eigene Eingabe-Ebene, weil der Baum pausiert)
	var in_layer = load("res://scripts/ui/overlays/stats_overlay_input.gd").new()
	in_layer.name = "StatsInput"
	in_layer.on_close = close_stats_overlay
	overlay.add_child(in_layer)

	_set_paused(true)
	_refresh_cards(overlay_cards)
	print("[STATS][UI] offen=true quelle=hud pause=true karten=%d" % overlay_cards.size())


func _set_paused(an: bool) -> void:
	if host.get_tree() != null:
		host.get_tree().paused = an


func close_stats_overlay() -> void:
	var hatte: bool = overlay != null and is_instance_valid(overlay)
	if hatte:
		overlay.queue_free()
	overlay = null
	overlay_cards.clear()
	_set_paused(false)
	var hud_sichtbar: bool = false
	var h = host.get("hud")
	if h != null and is_instance_valid(h):
		(h as Control).show()
		hud_sichtbar = (h as Control).visible
	print("[STATS][UI] offen=false zurueck=spiel pause=false")
	print("[STATS][UI] hud_sichtbar=%s" % str(hud_sichtbar))


# ---------------------------------------------------------------
# Menue-Seite (unveraendert seit Runde 49, nur Karten ausgelagert)
# ---------------------------------------------------------------

func _build_stats_page() -> void:
	host.stats_page = host._make_page("WAFFEN-STATS")
	var box = host._page_box(host.stats_page)

	var sub = Label.new()
	sub.text = Loc.t("Tippe auf eine Waffe fuer alle Werte. SCHADEN pro Schuss, RPM = Schuesse pro Minute, NACHLADEN = Magazin-Nachladezeit.")
	sub.set_meta("loc_fmt", true)
	sub.label_settings = host._make_label_settings(19, Color(0.86, 0.90, 0.88), 4)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	host.stat_cards.clear()
	_build_stat_cards(box, host.stat_cards)

	var back = host._make_pixel_button("ZURUECK", Color(0.30, 0.34, 0.44), 26)
	back.custom_minimum_size = Vector2(280, 58)
	back.pressed.connect(host.show_start_screen)
	box.add_child(back)
	host.stats_page.hide()


func _build_stat_cards(box: Control, arr: Array) -> void:
	# Baut die fuenf Waffenkarten in ein Raster und haengt sie in `box`.
	var grid := GridContainer.new()
	grid.name = "StatsGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var wrap := HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(wrap)
	wrap.add_child(grid)

	for w in WEAPON_STATS:
		var key: String = str(w["key"])
		var card := PanelContainer.new()
		card.name = "StatCard_" + key
		card.custom_minimum_size = Vector2(300, 300)
		card.add_theme_stylebox_override("panel", host._make_pixel_panel_sb(Color(0.12, 0.13, 0.19, 0.95), Color(0.45, 0.52, 0.66), 4, 10))
		grid.add_child(card)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		card.add_child(inner)

		# Icon
		var icon_frame := PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(280, 130)
		icon_frame.add_theme_stylebox_override("panel", host._make_pixel_panel_sb(Color(0.08, 0.10, 0.16, 0.92), Color(0.36, 0.78, 0.92), 4, 6))
		inner.add_child(icon_frame)
		var ic := TextureRect.new()
		ic.texture = TextureManager.get_texture(key)
		ic.custom_minimum_size = Vector2(110, 110)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_frame.add_child(ic)

		# Name
		var nl := Label.new()
		nl.text = Loc.t(str(w["name"]))
		nl.set_meta("loc_fmt", true)
		nl.label_settings = host._make_label_settings(24, Color(1.0, 0.86, 0.40), 6)
		nl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(nl)

		# Die drei Kernwerte
		var vals: Array = _weapon_stat_values(key)
		var vlabels: Array = []
		for v in vals:
			var vl := Label.new()
			vl.text = str(v)
			vl.set_meta("loc_fmt", true)
			vl.label_settings = host._make_label_settings(19, Color(0.90, 0.94, 0.96), 4)
			vl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			inner.add_child(vl)
			vlabels.append(vl)

		# Detailzeile (ausgeklappt)
		var detail := Label.new()
		detail.name = "Detail"
		detail.text = Loc.t(str(w["desc"]))
		detail.set_meta("loc_fmt", true)
		detail.label_settings = host._make_label_settings(16, Color(0.78, 0.84, 0.88), 4)
		detail.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size = Vector2(280, 0)
		detail.visible = false
		inner.add_child(detail)

		# Klick = aufklappen
		var hit := Button.new()
		hit.flat = true
		hit.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit.offset_left = 0.0
		hit.offset_right = 0.0
		hit.offset_top = 0.0
		hit.offset_bottom = 0.0
		hit.focus_mode = Control.FOCUS_NONE
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		hit.pressed.connect(_toggle_stat_card.bind(card))
		card.add_child(hit)

		arr.append({ "card": card, "detail": detail, "key": key, "vals": vlabels })


func _weapon_stat_values(key: String) -> Array:
	# Runde 49: Schaden / RPM / Magazin / Nachladezeit
	# v1.42 (P2.4): Werte der AKTUELLEN Stufe - nicht die Basistabelle
	var out: Array = []
	var d: Dictionary = {}
	var pl = null
	if host.game_manager != null:
		pl = host.game_manager.get("player")
	if pl != null and is_instance_valid(pl):
		var t: int = _weapon_type_of(key)
		if t >= 0:
			d = pl.call("_wd", t)
	if d.is_empty():
		d = WEAPON_STAT_VALUES.get(key, {})
	if d.is_empty():
		return ["SCHADEN  -", "RPM  -", "NACHLADEN  -"]
	var dmg: int = int(d.get("damage", 0))
	var cd: float = float(d.get("cooldown", 1.0))
	var rpm: int = int(d.get("rpm", int(round(60.0 / maxf(0.01, cd)))))
	var mag: int = int(d.get("mag", 0))
	var rl: float = float(d.get("reload", 0.0))
	out.append(Loc.fmt("SCHADEN  %d", [dmg]))
	out.append("RPM  %d" % rpm)
	if mag > 0:
		out.append(Loc.fmt("MAGAZIN  %d   NACHLADEN  %.1fs", [mag, rl]))
	else:
		out.append(Loc.t("MAGAZIN  UNENDLICH"))
	return out


func _weapon_type_of(key: String) -> int:
	# "weapon_machine" -> WeaponType-Index (Reihenfolge aus WeaponsModule)
	var want: String = key.replace("weapon_", "")
	for t in WeaponsModule.WEAPON_DATA.keys():
		if str(WeaponsModule.WEAPON_DATA[t]["name"]) == want:
			return int(t)
	return -1


func _refresh_stats_page() -> void:
	_refresh_cards(host.stat_cards)


func _refresh_cards(arr: Array) -> void:
	# Runde 49: Die Werte der Karten auffrischen (Schaden haengt von
	# den Upgrades ab, RPM/Nachladen von der Waffe)
	# Runde 136b (J4): zusaetzlich Stufe + Farbe je Waffe
	var rar_map: Dictionary = {}
	if host.player != null and is_instance_valid(host.player):
		var wr = host.player.get("weapon_rarity")
		if wr is Dictionary:
			rar_map = wr
	for entry in arr:
		var card: Control = entry["card"]
		if card == null or not is_instance_valid(card):
			continue
		var key: String = str(entry.get("key", card.name.replace("StatCard_", "")))
		var rar: String = str(rar_map.get(key, "common"))
		var rcol: Color = host._rarity_col_of(rar)
		card.add_theme_stylebox_override("panel",
			host._make_pixel_panel_sb(Color(0.12, 0.13, 0.19, 0.95), rcol, 5, 10))
		card.tooltip_text = "%s · %s" % [key.replace("weapon_", "").to_upper(), host._rarity_label_de(rar)]
		var rl = card.find_child("RarityLabel", true, false)
		if rl == null:
			rl = Label.new()
			rl.name = "RarityLabel"
			card.get_child(0).add_child(rl)
		# v1.42 (P2.5): Stufe + Kurzbegruendung (DE/EN ueber Loc)
		var _desc: String = str(WeaponsModule.RARITY_DESC.get(rar, ""))
		(rl as Label).text = "STUFE: " + host._rarity_label_de(rar) + " — " + Loc.t(_desc)
		(rl as Label).set_meta("loc_fmt", true)
		(rl as Label).label_settings = host._make_label_settings(20, rcol.lightened(0.15), 4)
		# v1.42 (P2.4): Werte der aktuellen Stufe nachziehen
		var vls: Array = entry.get("vals", [])
		var fresh: Array = _weapon_stat_values(key)
		var gezogen := 0
		for i in range(mini(vls.size(), fresh.size())):
			var l2 = vls[i]
			if l2 != null and is_instance_valid(l2):
				(l2 as Label).text = str(fresh[i])
				(l2 as Label).set_meta("loc_fmt", true)
				gezogen += 1
		print("[WPN][STATS-UI] waffe=%s stufe=%s zeilen=%d rpm=%s" % [
			key, rar, gezogen, str(fresh[1]) if fresh.size() > 1 else "-"])


func _toggle_stat_card(card: Control) -> void:
	# Runde 49: Detailzeile auf- oder zuklappen
	var d = card.find_child("Detail", true, false) as Label
	if d == null:
		return
	d.visible = not d.visible
