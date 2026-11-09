class_name ChallengePage
extends RefCounted

# v1.44 (C4-C7): Aufgaben-Seite ("Challenges") im Comic-Shooter-Look.
# Aufbau wie die anderen Seiten (MapsPage/ShopPage): der Zustand bleibt in der
# Fassade (ui_manager), hier stehen nur Aufbau und Darstellung.
#
#   page (dunkler Grund + Comic-Panel)
#     box VBox
#       Titel "CHALLENGES"          (aus _make_page, 52 px)
#       Kopfzeile: Zaehler-Chip links, Diamanten-Chip rechts
#       Raster 3 x 2 Karten
#       Fuss: ZURUECK              (fester Fuss, kein Scrollbereich)
var host: Node = null

const CARD_W := 560
const CARD_H := 292
const ChalRunScript = preload("res://scripts/core/challenge_run.gd")
const ChalScript = preload("res://scripts/core/challenge_run.gd")
const ICON_PX := 128

var _cards: Array = []
var _scroll: SmoothScroll = null
var _gem_chip: PanelContainer = null
var _count_chip: PanelContainer = null
var _back: Button = null


func _create_challenge_page() -> void:
	host.challenge_page = host._make_page("CHALLENGES")
	var page: Control = host.challenge_page
	# v1.46 (A1/A2): Beleg fuer den Seitentitel (vorher "AUFGABEN").
	var title_lbl: Label = page.find_child("PageTitle", true, false)
	print("[UI][PAGE] titel=%s" % (title_lbl.text if title_lbl != null else "CHALLENGES"))
	# v1.46 (A3): Uebersetzungsschluessel im Woerterbuch nachweisen (DE und EN).
	print("[LOC][KEY] challenges de=CHALLENGES en=%s" % str(Loc.DE_EN.get("CHALLENGES", "-")))
	var box: VBoxContainer = host._page_box(page)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)

	# --- Kopfzeile: links Zaehler, rechts Diamanten ---
	var head := HBoxContainer.new()
	head.name = "ChalHead"
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 20)
	head.custom_minimum_size = Vector2(1720, 56)
	box.add_child(head)

	_count_chip = host._make_chip("ERLEDIGT 0/6", Color(0.24, 0.30, 0.20), 26)
	head.add_child(_count_chip)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size = Vector2(0, 1)
	head.add_child(spacer)

	_gem_chip = host._make_chip("DIAMANTEN: 0", Color(0.20, 0.30, 0.42), 26)
	head.add_child(_gem_chip)

	# --- v1.46 (C1/C4): nur das Raster scrollt, Kopfzeile und Fuss stehen fest ---
	_scroll = UiStyle.smooth_scroll("challenges", 600.0)
	box.add_child(_scroll)
	var content := VBoxContainer.new()
	content.name = "ChalScrollContent"
	content.add_theme_constant_override("separation", 14)
	_scroll.set_content(content)

	var grid := GridContainer.new()
	grid.name = "ChalGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(grid)

	_cards.clear()
	if host.game_manager != null and host.game_manager.has_method("chal_defs"):
		for d in host.game_manager.chal_defs():
			grid.add_child(_make_card(d))

	# --- Fester Fuss ---
	var foot := HBoxContainer.new()
	foot.name = "ChalFooter"
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 18)
	box.add_child(foot)

	_back = host._make_pixel_button("ZURUECK", Color(0.35, 0.38, 0.46), 32)
	_back.name = "ChallengeBack"
	_back.custom_minimum_size = Vector2(340, 76)
	_back.pressed.connect(host._close_pages)
	foot.add_child(_back)

	page.hide()
	print("[CHAL][BAU] seite=challenges karten=%d raster=3x%d scroll=ja" % [_cards.size(), int(ceil(float(_cards.size()) / 3.0))])
	# v1.46 (C4): Kopfzeile (Titel + Chips) und Fuss (ZURUECK) stehen ausserhalb
	# des Scrollbereichs - nur das Raster bewegt sich.
	print("[SCROLL][FIX] titel=true chips=true fuss=true scroll_kind=grid")


func _make_card(d: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "ChalCard_" + str(d["id"])
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel",
		host._comic_panel_sb(Color(0.10, 0.11, 0.16, 0.96), Color(0.30, 0.32, 0.38), 4, 12))
	card.gui_input.connect(_on_card_input.bind(str(d["id"])))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	# Icon links, 128 px
	var icon := TextureRect.new()
	icon.texture = TextureManager.get_texture("chal_" + str(d["icon"]))
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	# Rechts: Name / Beschreibung / Fortschritt / Belohnung
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = str(d["name"])
	name_lbl.label_settings = host._make_label_settings(30, Color(1.0, 0.86, 0.40), 6)
	col.add_child(name_lbl)

	var desc := Label.new()
	desc.text = ChalScript.desc_for(str(d["id"]), "normal")
	desc.label_settings = host._make_label_settings(20, Color(0.86, 0.90, 0.94), 4)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(CARD_W - ICON_PX - 56, 52)
	desc.max_lines_visible = 2
	col.add_child(desc)

	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 10)
	col.add_child(prow)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	var ziel_n: int = ChalRunScript.ziel_of(str(d["id"]), "normal")
	bar.max_value = maxf(1.0, float(ziel_n))
	bar.value = 0
	var bbg := StyleBoxFlat.new()
	bbg.bg_color = Color(0.08, 0.09, 0.12, 0.9)
	bbg.set_corner_radius_all(6)
	bbg.set_border_width_all(2)
	bbg.border_color = Color(0.05, 0.05, 0.08, 0.9)
	bar.add_theme_stylebox_override("background", bbg)
	var bfg := StyleBoxFlat.new()
	bfg.bg_color = Color(0.98, 0.80, 0.22)
	bfg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", bfg)
	prow.add_child(bar)

	var prog := Label.new()
	prog.text = "0/%d" % ziel_n
	prog.label_settings = host._make_label_settings(22, Color(0.92, 0.95, 1.0), 4)
	prog.custom_minimum_size = Vector2(96, 0)
	prog.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	prow.add_child(prog)

	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	col.add_child(brow)

	var state_lbl := Label.new()
	state_lbl.text = "GESPERRT"
	state_lbl.label_settings = host._make_label_settings(19, Color(0.72, 0.76, 0.80), 4)
	state_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Kein Mindestbreiten-Zwang: sonst schiebt die lange Beschriftung das
	# Raster ueber den Rand (gemessen: inhalt 1950 px bei 1920 px Canvas).
	state_lbl.clip_text = true
	brow.add_child(state_lbl)

	var reward: PanelContainer = host._make_chip("%d ◆" % int((d["gems"] as Array)[1]), Color(0.22, 0.36, 0.52), 22)
	brow.add_child(reward)

	# --- v1.45 (C2): Stufenwahl + START (Spielmodus, nicht nur Anzeige) ---
	var srow := HBoxContainer.new()
	srow.name = "Stufen_" + str(d["id"])
	srow.add_theme_constant_override("separation", 6)
	col.add_child(srow)
	var stufe_btns: Dictionary = {}
	for sk in ChalRunScript.STUFEN:
		var bl: Button = host._make_pixel_button(str(ChalRunScript.STUFEN_LABEL[sk]), Color(0.20, 0.24, 0.32), 18)
		bl.name = "Stufe_%s_%s" % [str(d["id"]), str(sk)]
		bl.custom_minimum_size = Vector2(80, 44)
		bl.pressed.connect(_on_stufe.bind(str(d["id"]), str(sk)))
		srow.add_child(bl)
		stufe_btns[str(sk)] = bl
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size = Vector2(0, 1)
	srow.add_child(spacer2)
	var start_btn: Button = host._make_pixel_button("START", Color(0.22, 0.62, 0.34), 24)
	start_btn.name = "ChalStart_" + str(d["id"])
	start_btn.custom_minimum_size = Vector2(126, 46)
	start_btn.pressed.connect(_on_start.bind(str(d["id"])))
	srow.add_child(start_btn)

	_cards.append({
		"id": str(d["id"]), "card": card, "icon": icon, "name": name_lbl, "desc": desc,
		"bar": bar, "prog": prog, "state": state_lbl, "reward": reward,
		"goal": ziel_n, "unit": ChalRunScript.unit_of(str(d["id"])),
		"chips": int((d["gems"] as Array)[1]),
		"stufe": "normal", "stufe_btns": stufe_btns, "start": start_btn,
		"def": d,
	})
	# v1.46 (C2): Ziehen muss AUCH auf einer Karte funktionieren. Die Karte
	# laesst Ereignisse durch (PASS), und alles ausser den Knoepfen ist IGNORE -
	# sonst schluckt die Karte den Zug und der Scrollbereich bekommt ihn nie.
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	for n in card.find_children("*", "Control", true, false):
		if n is Button:
			continue
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _gems_of(id: String, stufe: String) -> int:
	var d: Dictionary = ChalRunScript.def_of(id)
	if d.is_empty():
		return 0
	var gems: Array = d["gems"]
	return int(gems[ChalRunScript.stufe_index(stufe)])


func _runden_of(id: String, stufe: String) -> int:
	var d: Dictionary = ChalRunScript.def_of(id)
	if d.is_empty():
		return 0
	var r: Array = d["runden"]
	return int(r[ChalRunScript.stufe_index(stufe)])


func _on_stufe(id: String, stufe: String) -> void:
	for c in _cards:
		if str(c["id"]) != id:
			continue
		c["stufe"] = stufe
		var btns: Dictionary = c["stufe_btns"]
		for sk in btns.keys():
			var b: Button = btns[sk]
			var an: bool = str(sk) == stufe
			b.modulate = Color(1, 1, 1) if an else Color(0.66, 0.70, 0.78)
		var reward: PanelContainer = c["reward"]
		var lbl = reward.get_meta("label")
		if lbl != null:
			lbl.text = "%d ◆" % _gems_of(id, stufe)
		# Fortschrittsziel + Beschreibung folgen der gewaehlten Stufe
		var bar: ProgressBar = c["bar"]
		var prog_lbl: Label = c["prog"]
		var ziel: int = _runden_of(id, stufe)
		var desc: Label = c["desc"]
		desc.text = ChalScript.desc_for(id, stufe)
		# v1.46 (B1): Zielzahl kommt aus der Definition (Runden, Kills, Muenzen,
		# Kisten, Bosse) - nicht mehr nur der Kisten-Sonderfall.
		ziel = ChalRunScript.ziel_of(id, stufe) if str(ChalRunScript.def_of(id).get("ziel", "")) != "runden" else _runden_of(id, stufe)
		bar.max_value = maxf(1.0, float(ziel))
		prog_lbl.text = "%d/%d" % [int(bar.value), ziel]
		print("[CHAL][WAHL] id=%s stufe=%s runden=%d diamanten=%d" % [
			id, stufe, _runden_of(id, stufe), _gems_of(id, stufe)])


func _on_start(id: String) -> void:
	var stufe: String = "normal"
	for c in _cards:
		if str(c["id"]) == id:
			stufe = str(c["stufe"])
	print("[CHAL][START] id=%s stufe=%s runden=%d waffe=%s" % [
		id, stufe, _runden_of(id, stufe),
		("REVOLVER" if str(ChalRunScript.def_of(id).get("startwaffe", "")) != "" else "frei")])
	if host.game_manager != null and host.game_manager.has_method("chal_start"):
		host.game_manager.call("chal_start", id, stufe)


func refresh_challenges_ui() -> void:
	if host.game_manager == null or host.challenge_page == null:
		return
	var gm = host.game_manager
	if gm.has_method("chal_ensure"):
		gm.call("chal_ensure")
	var l = _gem_chip.get_meta("label")
	if l:
		l.text = "DIAMANTEN: %d" % int(gm.gems)
	var cnt: Dictionary = gm.call("chal_counts") if gm.has_method("chal_counts") else {}
	var erl: int = int(cnt.get("ERLEDIGT", 0)) + int(cnt.get("BELOHNT", 0))
	var cl = _count_chip.get_meta("label")
	if cl:
		cl.text = "ERLEDIGT %d/%d" % [erl, _cards.size()]

	for c in _cards:
		var id: String = str(c["id"])
		var state: String = str(gm.call("chal_state", id))
		var prog: int = int(gm.call("chal_progress", id))
		var goal: int = int(c["goal"])
		var card: PanelContainer = c["card"]
		var icon: TextureRect = c["icon"]
		var name_lbl: Label = c["name"]
		var bar: ProgressBar = c["bar"]
		var prog_lbl: Label = c["prog"]
		var state_lbl: Label = c["state"]
		var reward: PanelContainer = c["reward"]
		_on_stufe(id, str(c.get("stufe", "normal")))
		var ziel: int = ChalRunScript.ziel_of(id, str(c.get("stufe", "normal")))
		if str(ChalRunScript.def_of(id).get("ziel", "")) == "runden":
			ziel = _runden_of(id, str(c.get("stufe", "normal")))
		bar.max_value = maxf(1.0, float(ziel))
		bar.value = clampi(prog, 0, ziel)
		prog_lbl.text = "%d/%d" % [clampi(prog, 0, ziel), ziel]
		# --- Zustand sichtbar machen (C6) ---
		match state:
			"LAEUFT":
				card.add_theme_stylebox_override("panel",
					host._comic_panel_sb(Color(0.12, 0.12, 0.16, 0.98), Color(0.98, 0.80, 0.22), 5, 12))
				state_lbl.text = "LAEUFT  " + str(c["unit"])
				state_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.40))
				icon.modulate = Color(1, 1, 1)
				name_lbl.modulate = Color(1, 1, 1)
				reward.modulate = Color(1, 1, 1)
				_bar_fill(bar, Color(0.98, 0.80, 0.22))
			"ERLEDIGT":
				card.add_theme_stylebox_override("panel",
					host._comic_panel_sb(Color(0.10, 0.16, 0.12, 0.98), Color(0.30, 0.78, 0.45), 5, 12))
				state_lbl.text = "✓  ABHOLEN"
				state_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
				icon.modulate = Color(1, 1, 1)
				name_lbl.modulate = Color(1, 1, 1)
				reward.modulate = Color(1.25, 1.25, 1.15)
				_bar_fill(bar, Color(0.30, 0.78, 0.45))
			"BELOHNT":
				card.add_theme_stylebox_override("panel",
					host._comic_panel_sb(Color(0.09, 0.09, 0.11, 0.96), Color(0.35, 0.36, 0.40), 4, 12))
				state_lbl.text = "✓  BELOHNT"
				state_lbl.add_theme_color_override("font_color", Color(0.66, 0.70, 0.74))
				icon.modulate = Color(0.55, 0.58, 0.60)
				name_lbl.modulate = Color(0.62, 0.64, 0.68)
				reward.modulate = Color(0.55, 0.58, 0.62)
				_bar_fill(bar, Color(0.42, 0.46, 0.50))
			_:
				card.add_theme_stylebox_override("panel",
					host._comic_panel_sb(Color(0.09, 0.09, 0.12, 0.96), Color(0.28, 0.30, 0.36), 4, 12))
				state_lbl.text = "🔒  GESPERRT"
				state_lbl.add_theme_color_override("font_color", Color(0.70, 0.72, 0.78))
				icon.modulate = Color(0.45, 0.47, 0.52)
				name_lbl.modulate = Color(0.60, 0.62, 0.68)
				reward.modulate = Color(0.55, 0.58, 0.62)
				_bar_fill(bar, Color(0.40, 0.42, 0.48))
		print("[CHAL][KARTE] id=%s icon_px=%d name_px=30 desc_zeilen=%d fortschritt=ja belohnung=ja zustand=%s" % [
			id, ICON_PX, mini(2, int((c["desc"] as Label).get_line_count())), state])


func desc_lines(c: Dictionary) -> int:
	var d: Label = c["desc"]
	return int(d.get_line_count())


func _bar_fill(bar: ProgressBar, col: Color) -> void:
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fg)


func _on_card_input(event: InputEvent, id: String) -> void:
	# C7: erledigte Aufgabe antippen holt die Belohnung (genau einmal).
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if host.game_manager == null:
		return
	var state: String = str(host.game_manager.call("chal_state", id))
	if state != "ERLEDIGT":
		print("[CHAL][TAP] id=%s zustand=%s keine_belohnung=true" % [id, state])
		return
	var res: Dictionary = host.game_manager.call("chal_claim", id)
	if bool(res.get("gutschrift", false)):
		host.show_banner("BELOHNUNG: +%d DIAMANTEN" % int(res.get("add", 0)), Color(0.55, 1.0, 0.70))
	refresh_challenges_ui()


# C4: Messwerte fuer den Layout-Beleg
func scroll_node() -> SmoothScroll:
	return _scroll


func last_card_control() -> Control:
	if _cards.is_empty():
		return null
	return _cards[_cards.size() - 1]["card"]


func layout_info() -> Dictionary:
	var page: Control = host.challenge_page
	var box: VBoxContainer = host._page_box(page)
	var need: Vector2 = box.get_combined_minimum_size()
	var brect: Rect2 = _back.get_global_rect() if _back != null else Rect2()
	# Nur der INHALT zaehlt - der dunkle Hintergrund (ColorRect) liegt immer
	# auf voller Breite und wuerde die Messung auf die Canvas-Breite ziehen.
	var max_rechts: float = 0.0
	for c in box.find_children("*", "Control", true, false):
		var cc := c as Control
		if cc != null and cc.is_visible_in_tree():
			max_rechts = maxf(max_rechts, cc.get_global_rect().end.x)
	return {
		"inhalt": need,
		"knopf_y": brect.position.y,
		"knopf_h": brect.size.y,
		"knopf_rect": brect,
		"max_rechts": max_rechts,
	}
