class_name MapsPage
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func _create_maps_page() -> void:
	host.maps_page = host._make_page("KARTEN")
	var box = host._page_box(host.maps_page)

	host.maps_gold_chip = host._make_chip("GOLD: 0", Color(0.34, 0.27, 0.12), 34)
	box.add_child(host.maps_gold_chip)

	var sub = Label.new()
	sub.text = "Jede Karte ist eine eigene Welt mit eigenen Monstern. Freischalten per Schalter (XP in einem Run) oder mit Gold."
	sub.label_settings = host._make_label_settings(22, Color(0.86, 0.90, 0.88), 5)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	# Runde 48: alle Karten bekommen dieselbe Hoehe (size_flags_vertical
	# FILL) und dieselbe Breite - vorher waren sie versetzt.
	var crow = HBoxContainer.new()
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	crow.add_theme_constant_override("separation", 18)
	crow.size_flags_vertical = Control.SIZE_FILL
	box.add_child(crow)

	host.maps_cards.clear()
	if host.game_manager != null:
		for m in host.game_manager.MAPS:
			var card := VBoxContainer.new()
			card.alignment = BoxContainer.ALIGNMENT_CENTER
			card.add_theme_constant_override("separation", 5)
			# Runde 48: alle Karten gleich hoch und gleich breit
			card.custom_minimum_size = Vector2(320, 700)
			card.size_flags_horizontal = Control.SIZE_FILL
			card.size_flags_vertical = Control.SIZE_FILL
			crow.add_child(card)

			# Runde 40: Karten-Icon im Comic-Rahmen
			var map_frame := PanelContainer.new()
			# Runde 48: feste Icon-Flaeche -> alle Karten-Icons gleich hoch
			map_frame.custom_minimum_size = Vector2(296, 156)
			map_frame.add_theme_stylebox_override("panel", host._make_pixel_panel_sb(Color(0.08, 0.10, 0.16, 0.92), Color(0.36, 0.78, 0.92), 5, 8))
			card.add_child(map_frame)
			var ic := TextureRect.new()
			ic.texture = TextureManager.get_texture(str(m["icon"]))
			ic.custom_minimum_size = Vector2(140, 140)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			map_frame.add_child(ic)

			var nl := Label.new()
			nl.text = str(m["name"])
			nl.label_settings = host._make_label_settings(26, Color(1.0, 0.86, 0.40), 6)
			nl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(nl)

			var dl := Label.new()
			dl.text = str(m["desc"])
			dl.label_settings = host._make_label_settings(18, Color(0.84, 0.88, 0.88), 4)
			dl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			dl.custom_minimum_size = Vector2(280, 62)
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(dl)

			var sl := Label.new()
			sl.label_settings = host._make_label_settings(20, Color(0.7, 1.0, 0.7), 4)
			sl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			# Runde 48: feste Hoehe -> alle Karten gleich hoch
			sl.custom_minimum_size = Vector2(286, 30)
			card.add_child(sl)

			# Schalter-Block (Runde 12): Bedingung + Fortschritt
			var gl := Label.new()
			gl.label_settings = host._make_label_settings(16, Color(1.0, 0.86, 0.45), 4)
			gl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			gl.custom_minimum_size = Vector2(286, 44)
			gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(gl)

			var gb := ProgressBar.new()
			gb.custom_minimum_size = Vector2(286, 14)
			gb.show_percentage = false
			gb.max_value = 100
			gb.value = 0
			var gsb_bg = StyleBoxFlat.new()
			gsb_bg.bg_color = Color(0.10, 0.11, 0.14, 0.85)
			gsb_bg.set_corner_radius_all(6)
			gb.add_theme_stylebox_override("background", gsb_bg)
			var gsb_fg = StyleBoxFlat.new()
			gsb_fg.bg_color = Color(0.35, 0.90, 0.70)
			gsb_fg.set_corner_radius_all(6)
			gb.add_theme_stylebox_override("fill", gsb_fg)
			card.add_child(gb)

			# Jahreszeiten-Streifen (Runde 13, nur Planeten mit Seasons)
			var srow := HBoxContainer.new()
			srow.alignment = BoxContainer.ALIGNMENT_CENTER
			srow.add_theme_constant_override("separation", 5)
			# Runde 48: feste Hoehe -> die Zeilen der Karten bleiben untereinander buendig.
			# v1.48 (A3): gilt jetzt fuer ALLE Planeten inkl. Erde.
			srow.custom_minimum_size = Vector2(286, 40)
			card.add_child(srow)
			var sbtns: Array = []
			if host.game_manager != null and host.game_manager.seasons_enabled(str(m["id"])):
				for se in host.game_manager.SEASONS:
					var sb2 = host._make_styled_button(str(se["name"]).substr(0, 4), Color(0.20, 0.24, 0.30), 17)
					sb2.custom_minimum_size = Vector2(68, 40)
					sb2.tooltip_text = str(se["name"]) + " — " + str(se["desc"])
					sb2.pressed.connect(_on_season_pressed.bind(str(m["id"]), str(se["id"])))
					srow.add_child(sb2)
					sbtns.append(sb2)
				print("[LAYOUT] karten_saisons planet=%s knoepfe=%d" % [str(m["id"]), sbtns.size()])
				print("[MAP][SEASON] planet=%s knoepfe=%d" % [str(m["id"]), sbtns.size()])
			var season_hint := Label.new()
			season_hint.label_settings = host._make_label_settings(15, Color(0.72, 0.90, 1.0), 4)
			season_hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			season_hint.custom_minimum_size = Vector2(286, 30)
			season_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(season_hint)

			# Runde 136 (I2): FEST / WECHSELND je Planet
			var mrow := HBoxContainer.new()
			mrow.alignment = BoxContainer.ALIGNMENT_CENTER
			mrow.add_theme_constant_override("separation", 6)
			mrow.custom_minimum_size = Vector2(286, 46)
			card.add_child(mrow)
			var mode_btns: Array = []
			if host.game_manager != null and host.game_manager.seasons_enabled(str(m["id"])):
				var bf = host._make_styled_button("FEST", Color(0.20, 0.28, 0.42), 16)
				bf.custom_minimum_size = Vector2(132, 40)
				bf.tooltip_text = "Die gewaehlte Jahreszeit bleibt den ganzen Run"
				bf.pressed.connect(_on_season_mode.bind(str(m["id"]), "fixed"))
				mrow.add_child(bf)
				var bc = host._make_styled_button("WECHSELND", Color(0.20, 0.28, 0.42), 16)
				bc.custom_minimum_size = Vector2(146, 40)
				bc.tooltip_text = "Jahreszeit wechselt im Run durch die freigeschalteten"
				bc.pressed.connect(_on_season_mode.bind(str(m["id"]), "cycle"))
				mrow.add_child(bc)
				mode_btns = [bf, bc]

			var b = host._make_styled_button("WAEHLEN", Color(0.24, 0.52, 0.42), 22)
			b.custom_minimum_size = Vector2(286, 60)
			b.pressed.connect(_on_map_action.bind(str(m["id"])))
			card.add_child(b)
			host.maps_cards.append({ "btn": b, "status": sl, "gate_label": gl, "gate_bar": gb,
				"season_btns": sbtns, "season_hint": season_hint, "mode_btns": mode_btns, "id": str(m["id"]) })

	var back = host._make_styled_button("ZURUECK", Color(0.35, 0.38, 0.46), 30)
	back.custom_minimum_size = Vector2(300, 72)
	back.pressed.connect(host._close_pages)
	box.add_child(back)
	host.maps_page.hide()


func refresh_maps_ui() -> void:
	if host.game_manager == null or host.maps_page == null:
		return
	var l = host.maps_gold_chip.get_meta("label")
	if l:
		l.text = "GOLD: %d" % host.game_manager.gold
	for c in host.maps_cards:
		var mid: String = c["id"]
		var d: Dictionary = host.game_manager.map_data(mid)
		var unlocked: bool = host.game_manager.is_map_unlocked(mid)
		var active: bool = host.game_manager.active_map == mid
		var price := int(d.get("price", 0))
		var b: Button = c["btn"]
		var sl: Label = c["status"]
		var gate: Dictionary = d.get("gate", {})
		var gl: Label = c["gate_label"]
		var gb: ProgressBar = c["gate_bar"]
		if unlocked or gate.is_empty():
			gl.text = ""
			gb.visible = false
		else:
			var need := int(gate.get("need", 0))
			var pre := str(gate.get("prereq", ""))
			if pre != "" and not host.game_manager.is_map_unlocked(pre):
				gl.text = "Erst " + str(host.game_manager.map_data(pre)["name"]) + " freischalten"
				gb.visible = false
			else:
				gl.text = "SCHALTER: " + str(need) + " XP in EINEM Run  (Bestwert " + str(host.game_manager.best_run_xp) + ")"
				gb.visible = true
				gb.max_value = need
				gb.value = mini(host.game_manager.best_run_xp, need)
		# Jahreszeiten-Kacheln (Runde 136: Preis in Gold statt XP-Schalter)
		if c.has("season_btns") and (c["season_btns"] as Array).size() > 0:
			var planet: String = c["id"]
			var sel: String = str(host.game_manager.planet_season(planet))
			var btns: Array = c["season_btns"]
			for i in range(btns.size()):
				var se: Dictionary = host.game_manager.SEASONS[i]
				var sid := str(se["id"])
				var un: bool = host.game_manager.is_season_unlocked(planet, sid)
				var bb: Button = btns[i]
				var col: Color = se["color"]
				# v1.44 (K1/K4): Preis je Planet (Kartenpreis / 3)
				var sprice: int = int(host.game_manager.season_price_for(planet, sid))
				if not un:
					# gesperrt: Schloss + Preis, Klick kauft
					bb.text = "🔒 " + str(sprice)
					bb.disabled = false
					bb.modulate = Color(1.0, 0.95, 0.75) if host.game_manager.gold >= sprice else Color(0.62, 0.60, 0.58)
					bb.tooltip_text = "%s — %s Gold (Klick kauft)" % [str(se["name"]), str(sprice)]
				else:
					bb.text = str(se["name"]).substr(0, 4)
					bb.disabled = false
					bb.modulate = Color(col.r * 1.25, col.g * 1.25, col.b * 1.25) if sid == sel else Color(0.85, 0.85, 0.90)
					bb.tooltip_text = str(se["name"]) + " — frei"
			var hint: Label = c["season_hint"]
			var pool_txt: Array = host.game_manager.season_pool(planet)
			var modus: String = host.game_manager.season_mode_of(planet)
			hint.text = "Aktiv: " + host.game_manager.season_name(sel) + "  ·  " + modus.to_upper()
			hint.text += "  ·  frei: " + str(pool_txt.size()) + "/4"
			# FEST / WECHSELND
			if c.has("mode_btns"):
				var mbtns: Array = c["mode_btns"]
				if mbtns.size() == 2:
					var bf2: Button = mbtns[0]
					var bc2: Button = mbtns[1]
					bf2.disabled = (modus == "fixed")
					var can_cycle: bool = pool_txt.size() >= 2
					bc2.disabled = (modus == "cycle") or not can_cycle
					bc2.tooltip_text = ("Jahreszeit wechselt im Run durch " + str(pool_txt)) if can_cycle \
						else "erst eine zweite Jahreszeit freischalten"
					bf2.modulate = Color(0.55, 1.0, 0.70) if modus == "fixed" else Color(1, 1, 1)
					bc2.modulate = Color(0.55, 1.0, 0.70) if modus == "cycle" else Color(1, 1, 1)
		if active:
			sl.text = "AKTIV"
			sl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
			b.text = "GEWAEHLT"
			b.disabled = true
		elif unlocked:
			sl.text = "FREIGESCHALTET"
			sl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
			b.text = "WAEHLEN"
			b.disabled = false
		else:
			sl.text = "GESPERRT"
			sl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
			b.text = "KAUFEN %d" % price
			b.disabled = host.game_manager.gold < price


func _on_season_mode(planet: String, mode: String) -> void:
	# Runde 136 (I2): FEST / WECHSELND umschalten
	if host.game_manager == null:
		return
	var pool: Array = host.game_manager.season_pool(planet)
	if mode == "cycle" and pool.size() < 2:
		host.show_banner("ERST EINE ZWEITE JAHRESZEIT FREISCHALTEN", Color(1.0, 0.7, 0.4))
		print("[SEASON][MODE] ABGELEHNT planet=%s modus=cycle pool=%s (zu klein)" % [planet, str(pool)])
		return
	host.game_manager.set_season_mode(planet, mode)
	host.show_banner(("WECHSELND" if mode == "cycle" else "FEST") + " · " + str(host.game_manager.map_data(planet)["name"]),
		Color(0.6, 1.0, 0.85))


func _on_season_pressed(planet: String, sid: String) -> void:
	if host.game_manager == null:
		return
	# Runde 136 (I1): gesperrte Jahreszeit -> kaufen
	if not host.game_manager.is_season_unlocked(planet, sid):
		if not host.game_manager.is_map_unlocked(planet):
			host.show_banner("ERST " + str(host.game_manager.map_data(planet)["name"]) + " FREISCHALTEN", Color(1.0, 0.6, 0.4))
			return
		host.game_manager.buy_season(planet, sid)
		refresh_maps_ui()
		return
	if not host.game_manager.is_map_unlocked(planet):
		host.show_banner("ERST " + str(host.game_manager.map_data(planet)["name"]) + " FREISCHALTEN", Color(1.0, 0.6, 0.4))
		return
	host.game_manager.set_active_map(planet)
	host.game_manager.set_active_season(planet, sid)
	host.show_banner(str(host.game_manager.map_data(planet)["name"]) + " · " + host.game_manager.season_name(sid), Color(0.6, 1.0, 0.8))
	refresh_maps_ui()


func _on_map_action(mid: String) -> void:
	if host.game_manager == null:
		return
	if host.game_manager.is_map_unlocked(mid):
		host.game_manager.set_active_map(mid)
		host.show_banner("KARTE GEWAEHLT: " + str(host.game_manager.map_data(mid)["name"]), Color(0.6, 1.0, 0.8))
	else:
		if host.game_manager.buy_map(mid):
			host.show_banner("KARTE FREIGESCHALTET!", Color(0.6, 1.0, 0.8))
		else:
			host.show_banner("ZU WENIG GOLD", Color(1.0, 0.5, 0.35))
	refresh_maps_ui()
	host.refresh_shop_ui()
	if host.game_manager:
		var l = host.maps_gold_chip.get_meta("label")
		if l:
			l.text = "GOLD: %d" % host.game_manager.gold
