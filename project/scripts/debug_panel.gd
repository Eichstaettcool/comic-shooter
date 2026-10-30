extends CanvasLayer
# Runde 60: Debug-Fenster (F9). Zeigt Charakter-Vorschau mit Farbe/Skin/Hut,
# erlaubt Weltwechsel, Detailstufe, Gitter und Live-Werte.
# Laeuft mit PROCESS_MODE_ALWAYS, damit es auch bei Pause bedienbar bleibt.

var gm: Node = null
var panel: PanelContainer
var preview: TextureRect
var sel_lbl: Label
var stats_lbl: Label
var grid_scroll: ScrollContainer
var grid: GridContainer
var grid_open: bool = false
var c_idx: int = 0
var s_idx: int = 0
var h_idx: int = 0
var _tick: float = 0.0


func setup(gmi: Node) -> void:
	gm = gmi
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func _build() -> void:
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.10, 0.95)
	sb.border_color = Color(0.40, 0.90, 0.60, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "DEBUG-FENSTER"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.55, 0.98, 0.68))
	vb.add_child(title)

	var hint := Label.new()
	hint.text = "F9 = schliessen"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.62, 0.70, 0.64))
	vb.add_child(hint)
	vb.add_child(HSeparator.new())

	# ---------- Charakter ----------
	var cap := Label.new()
	cap.text = "CHARAKTER"
	cap.add_theme_font_size_override("font_size", 15)
	cap.add_theme_color_override("font_color", Color(0.80, 0.86, 0.92))
	vb.add_child(cap)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)

	var pv := 104
	var pbox := PanelContainer.new()
	pbox.custom_minimum_size = Vector2(pv, pv)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.28, 0.50, 0.26, 1.0)
	psb.set_corner_radius_all(6)
	psb.set_border_width_all(1)
	psb.border_color = Color(0.10, 0.16, 0.10, 0.8)
	pbox.add_theme_stylebox_override("panel", psb)
	hb.add_child(pbox)

	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(pv, pv)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pbox.add_child(preview)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(rows)
	_make_row(rows, "FARBE", _c_prev, _c_next)
	_make_row(rows, "SKIN", _s_prev, _s_next)
	_make_row(rows, "HUT", _h_prev, _h_next)

	sel_lbl = Label.new()
	sel_lbl.add_theme_font_size_override("font_size", 12)
	sel_lbl.add_theme_color_override("font_color", Color(0.70, 0.78, 0.72))
	sel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(sel_lbl)

	var apply := Button.new()
	apply.text = "AUF SPIELER ANWENDEN"
	apply.pressed.connect(_apply)
	vb.add_child(apply)

	var allbtn := Button.new()
	allbtn.text = "ALLE KOMBINATIONEN EIN-/AUSBLENDEN"
	allbtn.pressed.connect(_toggle_grid)
	vb.add_child(allbtn)

	var unlock := Button.new()
	unlock.text = "ALLES FREISCHALTEN (GOLD / SKINS / HUETE)"
	unlock.pressed.connect(_unlock_all)
	vb.add_child(unlock)

	var spawnall := Button.new()
	spawnall.text = "ALLE MONSTER SPAWNEN (12 um den Spieler)"
	spawnall.pressed.connect(_spawn_all_monsters)
	vb.add_child(spawnall)

	# --- Gezielt Monster/Bosse spawnen ---
	var pick_row := HBoxContainer.new()
	vb.add_child(pick_row)
	type_picker = OptionButton.new()
	type_picker.custom_minimum_size = Vector2(230, 40)
	var names: Array = [
		"GREEN","RED","BLUE","PURPLE","YELLOW","PINK","ORANGE","BOSS (alt)",
		"BURROWER","GOLEM","PYRO","MARS_ALIEN","MARS_ROVER","ROBO_APE","BIG_FLOWER",
		"MARS_DRONE","MARS_GUARD","ROBO_TIGER","VINE_TRAP",
		"BOSS MARS","BOSS JUNGLE","BOSS EARTH",
		"MINI EARTH","MINI MARS","MINI JUNGLE",
		"VOLT DRONE","VOLT TROOPER","VOLT SPIDER","BOSS VOLT","VOLT SPOOLER","MINI VOLT"]
	for i in range(names.size()):
		type_picker.add_item("%d · %s" % [i, names[i]], i)
	pick_row.add_child(type_picker)

	var spawn_one := Button.new()
	spawn_one.text = "SPAWNEN"
	spawn_one.pressed.connect(_spawn_selected)
	pick_row.add_child(spawn_one)

	var boss_btn := Button.new()
	boss_btn.text = "BOSS DIESER KARTE"
	boss_btn.pressed.connect(_spawn_biome_boss)
	vb.add_child(boss_btn)

	var mini_btn := Button.new()
	mini_btn.text = "MINI-BOSS DIESER KARTE"
	mini_btn.pressed.connect(_spawn_biome_mini)
	vb.add_child(mini_btn)

	var god := Button.new()
	god.text = "UNVERWUNDBAR: AUS"
	god.pressed.connect(_toggle_god)
	vb.add_child(god)
	god_btn = god

	grid_scroll = ScrollContainer.new()
	grid_scroll.custom_minimum_size = Vector2(0, 0)
	grid_scroll.visible = false
	vb.add_child(grid_scroll)
	grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid_scroll.add_child(grid)

	vb.add_child(HSeparator.new())

	# ---------- Welt ----------
	var cap2 := Label.new()
	cap2.text = "WELT"
	cap2.add_theme_font_size_override("font_size", 15)
	cap2.add_theme_color_override("font_color", Color(0.80, 0.86, 0.92))
	vb.add_child(cap2)

	var maps := HBoxContainer.new()
	maps.add_theme_constant_override("separation", 6)
	vb.add_child(maps)
	for m in ["earth", "mars", "jungle", "volt"]:
		var b := Button.new()
		b.text = m.to_upper()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_switch_map.bind(m))
		maps.add_child(b)

	var hb2 := HBoxContainer.new()
	hb2.add_theme_constant_override("separation", 6)
	vb.add_child(hb2)
	var bnew := Button.new()
	bnew.text = "KARTE NEU"
	bnew.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bnew.pressed.connect(_restart_same)
	hb2.add_child(bnew)
	var bgrid := Button.new()
	bgrid.text = "GITTER"
	bgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bgrid.pressed.connect(_toggle_gridlines)
	hb2.add_child(bgrid)

	vb.add_child(HSeparator.new())

	# ---------- Werte ----------
	stats_lbl = Label.new()
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.72, 0.80, 0.74))
	vb.add_child(stats_lbl)

	_refresh()


func _make_row(parent: VBoxContainer, label: String, on_prev: Callable, on_next: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	var b1 := Button.new()
	b1.text = "<"
	b1.custom_minimum_size = Vector2(34, 0)
	b1.pressed.connect(on_prev)
	var l := Label.new()
	l.text = label
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 13)
	var b2 := Button.new()
	b2.text = ">"
	b2.custom_minimum_size = Vector2(34, 0)
	b2.pressed.connect(on_next)
	h.add_child(b1)
	h.add_child(l)
	h.add_child(b2)
	parent.add_child(h)


func _count_colors() -> int:
	return TextureManager.PLAYER_COLORS.size()


func _refresh() -> void:
	if preview == null:
		return
	var tex = TextureManager.get_skin_hat_texture(c_idx, s_idx, h_idx)
	if tex != null:
		preview.texture = tex
	sel_lbl.text = "%s / %s / %s" % [
		TextureManager.COLOR_NAMES[clampi(c_idx, 0, TextureManager.COLOR_NAMES.size() - 1)],
		TextureManager.RIG_NAMES[s_idx],
		TextureManager.HAT_NAMES[h_idx]]


func _c_prev() -> void:
	c_idx = (c_idx - 1 + _count_colors()) % _count_colors()
	_pick_refresh()


func _c_next() -> void:
	c_idx = (c_idx + 1) % _count_colors()
	_pick_refresh()


func _s_prev() -> void:
	s_idx = (s_idx - 1 + TextureManager.RIG_NAMES.size()) % TextureManager.RIG_NAMES.size()
	_pick_refresh()


func _s_next() -> void:
	s_idx = (s_idx + 1) % TextureManager.RIG_NAMES.size()
	_pick_refresh()


func _h_prev() -> void:
	h_idx = (h_idx - 1 + TextureManager.HAT_NAMES.size()) % TextureManager.HAT_NAMES.size()
	_pick_refresh()


func _h_next() -> void:
	h_idx = (h_idx + 1) % TextureManager.HAT_NAMES.size()
	_pick_refresh()


func _pick_refresh() -> void:
	_refresh()
	if grid_open:
		_build_grid()


func _apply() -> void:
	if gm == null:
		return
	var p = gm.get("player")
	if p == null or not is_instance_valid(p):
		print("[DEBUG] Kein Spieler aktiv - Auswahl nur in der Vorschau")
		return
	p.call("apply_profile", c_idx, h_idx, s_idx)
	print("[DEBUG] Angewendet: Farbe=%d Skin=%d Hut=%d" % [c_idx, s_idx, h_idx])


func _toggle_grid() -> void:
	grid_open = not grid_open
	grid_scroll.visible = grid_open
	grid_scroll.custom_minimum_size = Vector2(0, 300) if grid_open else Vector2(0, 0)
	if grid_open:
		_build_grid()
	else:
		for ch in grid.get_children():
			ch.queue_free()


func _build_grid() -> void:
	for ch in grid.get_children():
		ch.queue_free()
	for s in range(TextureManager.RIG_NAMES.size()):
		for h in range(TextureManager.HAT_NAMES.size()):
			var tex = TextureManager.get_skin_hat_texture(c_idx, s, h)
			if tex == null:
				continue
			var tb := TextureButton.new()
			tb.texture_normal = tex
			tb.ignore_texture_size = true
			tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			tb.custom_minimum_size = Vector2(46, 46)
			tb.pressed.connect(_pick_combo.bind(s, h))
			grid.add_child(tb)


func _pick_combo(s: int, h: int) -> void:
	s_idx = s
	h_idx = h
	_refresh()
	_apply()


var god_btn: Button = null
var type_picker: OptionButton = null

func _spawn_selected() -> void:
	if gm == null or type_picker == null:
		return
	var p = gm.get("player")
	if p == null:
		print("[DEBUG] FEHLER: kein Spieler")
		return
	var id: int = type_picker.get_selected_id()
	var m = gm.call("spawn_monster_at", p.global_position + Vector2(180, 0), id, false)
	var isb: bool = bool(m.call("is_boss")) if m != null else false
	print("[DEBUG] gespawnt id=%d boss=%s" % [id, str(isb)])


func _spawn_biome_boss() -> void:
	if gm == null:
		return
	var p = gm.get("player")
	if p == null:
		print("[DEBUG] FEHLER: kein Spieler")
		return
	var id: int = int(gm.call("_biome_boss_type"))
	gm.call("spawn_monster_at", p.global_position + Vector2(220, 0), id, false)
	print("[DEBUG] Biome-Boss id=%d gespawnt" % id)


func _spawn_biome_mini() -> void:
	if gm == null:
		return
	var p = gm.get("player")
	if p == null:
		print("[DEBUG] FEHLER: kein Spieler")
		return
	var id: int = int(gm.call("_mini_boss_type"))
	# NICHT as_mini: MINI_*-Typen sind bereits Mini-Bosse. Der Flag haette
	# ihnen die HP genommen (alter set_mini-Bug).
	var mb = gm.call("spawn_monster_at", p.global_position + Vector2(220, 0), id, false)
	if mb != null:
		print("[DEBUG] Biome-Mini id=%d hp=%d boss=%s" % [id, int(mb.get("current_health")), str(mb.call("is_boss"))])
	else:
		print("[DEBUG] FEHLER: Mini-Boss id=%d nicht erzeugt" % id)

func _spawn_all_monsters() -> void:
	if gm == null:
		return
	var p = gm.get("player")
	if p == null:
		print("[DEBUG] FEHLER: kein Spieler in der Szene")
		return
	var base: Vector2 = p.global_position
	for i in range(12):
		var a: float = TAU * float(i) / 12.0
		gm.call("spawn_monster_at", base + Vector2(cos(a), sin(a)) * 260.0, -1, false)
	print("[DEBUG] 12 Monster um %s gespawnt" % str(base))


func _toggle_god() -> void:
	if gm == null:
		return
	var p = gm.get("player")
	if p == null:
		print("[DEBUG] FEHLER: kein Spieler")
		return
	p.god_mode = not bool(p.god_mode)
	if god_btn != null:
		god_btn.text = "UNVERWUNDBAR: " + ("AN" if p.god_mode else "AUS")
	print("[DEBUG] Unverwundbar=%s hp=%d" % [str(p.god_mode), int(p.health)])


func _unlock_all() -> void:
	if gm != null:
		gm.gems += 5000
		print("[DEBUG] +5000 Edelsteine")
	if gm == null:
		return
	gm.call("debug_unlock_all")
	print("[DEBUG] Freischalten ausgeloest")


func _switch_map(mid: String) -> void:
	if gm == null:
		return
	print("[DEBUG] Weltwechsel -> %s" % mid)
	gm.call("quit_to_menu")
	gm.call("set_active_map", mid)
	gm.call("start_game", false, false)


func _restart_same() -> void:
	if gm == null:
		return
	var mid := str(gm.get("active_map"))
	print("[DEBUG] Karte neu erzeugen: %s" % mid)
	gm.call("quit_to_menu")
	gm.call("start_game", false, false)


func _toggle_gridlines() -> void:
	if gm == null:
		return
	var mg = gm.get("map_generator")
	if mg == null:
		return
	var g = mg.get("grid_sprite")
	if g != null and is_instance_valid(g):
		g.visible = not g.visible
		print("[DEBUG] Karo-Gitter: %s" % ("AN" if g.visible else "AUS"))


func toggle() -> void:
	visible = not visible
	if gm != null:
		gm.set("debug_open", visible)
	if visible:
		var vp: Vector2 = get_viewport().get_visible_rect().size
		var w: float = maxf(panel.size.x, panel.get_combined_minimum_size().x)
		panel.position = Vector2(maxf(12.0, vp.x - w - 24.0), 110.0)
		_refresh()
		print("[DEBUG] Fenster geoeffnet")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F9 or event.keycode == KEY_ESCAPE:
			toggle()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible or gm == null:
		return
	_tick += delta
	if _tick < 0.25:
		return
	_tick = 0.0
	var enemies := 0
	var mc = gm.get("monster_container")
	if mc != null and is_instance_valid(mc):
		enemies = mc.get_child_count()
	stats_lbl.text = "FPS %d   Mobs %d   Welle %s\nHP %s   Score %s   Biom %s" % [
		Engine.get_frames_per_second(), enemies,
		str(gm.get("wave")), str(gm.get("player_health")), str(gm.get("score")),
		str(gm.get("biome_id"))]
