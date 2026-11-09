class_name LobbyOverlay
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func _build_lobby() -> void:
	host.lobby_panel = ColorRect.new()
	host.lobby_panel.name = "LobbyPanel"
	host.lobby_panel.color = Color(0.04, 0.06, 0.09, 0.98)
	host.lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.lobby_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(host.lobby_panel)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 260.0
	panel.offset_right = -260.0
	panel.offset_top = 60.0
	panel.offset_bottom = -60.0
	panel.add_theme_stylebox_override("panel", host._make_panel_sb(0.96, 32))
	host.lobby_panel.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	host.lobby_title = Label.new()
	host.lobby_title.text = "LOBBY"
	host.lobby_title.label_settings = host._make_label_settings(78, Color(0.45, 0.95, 0.65), 12)
	host.lobby_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(host.lobby_title)

	host.lobby_info = Label.new()
	host.lobby_info.label_settings = host._make_label_settings(28, Color(0.9, 0.94, 0.9), 6)
	host.lobby_info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(host.lobby_info)

	var list_title = Label.new()
	list_title.text = "SPIELER"
	list_title.label_settings = host._make_label_settings(30, Color(1.0, 0.85, 0.35), 6)
	list_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(list_title)

	host.lobby_rows_box = VBoxContainer.new()
	host.lobby_rows_box.alignment = BoxContainer.ALIGNMENT_CENTER
	host.lobby_rows_box.add_theme_constant_override("separation", 10)
	box.add_child(host.lobby_rows_box)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 26)
	box.add_child(btn_row)

	host.lobby_ready_btn = host._make_styled_button("BEREIT", Color(0.25, 0.55, 0.30), 32)
	host.lobby_ready_btn.custom_minimum_size = Vector2(320, 84)
	host.lobby_ready_btn.pressed.connect(_on_lobby_ready_pressed)
	btn_row.add_child(host.lobby_ready_btn)

	host.lobby_start_btn = host._make_styled_button("SPIEL STARTEN", Color(0.22, 0.62, 0.32), 34)
	host.lobby_start_btn.custom_minimum_size = Vector2(400, 92)
	host.lobby_start_btn.pressed.connect(_on_lobby_start_pressed)
	btn_row.add_child(host.lobby_start_btn)

	var leave = host._make_styled_button("VERLASSEN", Color(0.45, 0.28, 0.28), 30)
	leave.custom_minimum_size = Vector2(280, 78)
	leave.pressed.connect(_on_lobby_leave_pressed)
	box.add_child(leave)

	var hint = Label.new()
	hint.text = "Der Host startet das Spiel fuer alle — beide betreten das Feld gleichzeitig."
	hint.label_settings = host._make_label_settings(24, Color(0.8, 0.86, 0.86), 5)
	hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	host.lobby_panel.visible = false


func show_lobby(is_host: bool, slot: int) -> void:
	if host.lobby_panel == null:
		_build_lobby()
	host.lobby_host = is_host
	host.lobby_my_ready = false
	host.lobby_panel.visible = true
	if host.start_screen:
		host.start_screen.hide()
	if host.hud:
		host.hud.hide()
	if host.lan_panel:
		host.lan_panel.hide()
	if host.death_screen:
		host.death_screen.hide()
	if host.lobby_ready_btn:
		host.lobby_ready_btn.visible = not is_host
	if host.lobby_start_btn:
		host.lobby_start_btn.visible = is_host
	if is_host:
		host.lobby_title.text = "LOBBY — HOST"
		host.lobby_info.text = "Warte auf Mitspieler …  ·  IP: %s  ·  Port %d" % [NetManager.get_local_ip(), NetManager.ENET_PORT]
	else:
		host.lobby_title.text = "LOBBY"
		host.lobby_info.text = "Verbunden — warte auf den Host …"
	update_lobby(NetManager.lobby, NetManager.player_count, is_host)


func update_lobby(roster: Dictionary, max_players: int, is_host: bool) -> void:
	if host.lobby_panel == null or not host.lobby_panel.visible:
		return
	if host.lobby_rows_box == null:
		return
	for c in host.lobby_rows_box.get_children():
		c.queue_free()
	var my_id = host.multiplayer.get_unique_id()
	var slots: Array = []
	for k in roster.keys():
		slots.append(int(roster[k].get("slot", 1)))
	slots.sort()
	var connected := 0
	for s in slots:
		var pr: Dictionary = {}
		var peer_key := 0
		for k in roster.keys():
			if int(roster[k].get("slot", 1)) == int(s):
				pr = roster[k]
				peer_key = int(k)
				break
		var is_me: bool = (peer_key == my_id) or (is_host and peer_key == 1)
		var nm := str(pr.get("name", ""))
		if nm == "":
			nm = "HOST" if int(s) == 1 else "SPIELER %d" % int(s)
		var ready: bool = bool(pr.get("ready", false))
		if int(s) != 1:
			connected += 1
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", host._make_chip_sb(Color(0.20, 0.42, 0.30, 0.85) if ready else Color(0.22, 0.26, 0.34, 0.85)))
		card.custom_minimum_size = Vector2(760, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		row.custom_minimum_size = Vector2(720, 78)
		card.add_child(row)

		var ic := TextureRect.new()
		ic.texture = TextureManager.get_player_texture(int(pr.get("color", (int(s) - 1) % 6)), int(pr.get("hat", 0)))
		ic.custom_minimum_size = Vector2(64, 64)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(ic)

		var t := VBoxContainer.new()
		t.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(t)
		var nl := Label.new()
		nl.text = "P%d  %s%s" % [int(s), nm, "  (DU)" if is_me else ""]
		nl.label_settings = host._make_label_settings(30, Color(1, 1, 1), 5)
		t.add_child(nl)
		var sl := Label.new()
		sl.text = "Host" if int(s) == 1 else ("Bereit" if ready else "Noch nicht bereit")
		sl.label_settings = host._make_label_settings(22, Color(0.6, 1.0, 0.7) if ready else Color(1.0, 0.75, 0.4), 4)
		t.add_child(sl)
		host.lobby_rows_box.add_child(card)

	if is_host:
		var full := connected >= (max_players - 1)
		host.lobby_info.text = "Warte auf Mitspieler …  ·  %d/%d verbunden  ·  IP: %s  ·  Port %d" % [connected + 1, max_players, NetManager.get_local_ip(), NetManager.ENET_PORT]
		if host.lobby_start_btn:
			host.lobby_start_btn.disabled = connected < 1
			host.lobby_start_btn.text = "SPIEL STARTEN (%d)" % (connected + 1)
	else:
		if host.lobby_ready_btn:
			host.lobby_ready_btn.text = "BEREIT" if not host.lobby_my_ready else "BEREIT ✓"
			host.lobby_ready_btn.modulate = Color(1.35, 1.35, 1.35) if host.lobby_my_ready else Color(1, 1, 1)


func hide_lobby() -> void:
	if host.lobby_panel:
		host.lobby_panel.visible = false


func _on_lobby_ready_pressed() -> void:
	host.lobby_my_ready = not host.lobby_my_ready
	NetManager.c_send_lobby_ready(host.lobby_my_ready)
	if host.lobby_ready_btn:
		host.lobby_ready_btn.text = "BEREIT ✓" if host.lobby_my_ready else "BEREIT"
		host.lobby_ready_btn.modulate = Color(1.35, 1.35, 1.35) if host.lobby_my_ready else Color(1, 1, 1)


func _on_lobby_start_pressed() -> void:
	if host.game_manager and host.game_manager.has_method("start_lan_run_as_host"):
		host.game_manager.start_lan_run_as_host()


func _on_lobby_leave_pressed() -> void:
	if host.game_manager and host.game_manager.has_method("leave_lobby"):
		host.game_manager.leave_lobby()
	else:
		NetManager.leave()
		hide_lobby()
