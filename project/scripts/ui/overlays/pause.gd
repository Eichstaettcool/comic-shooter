class_name PauseOverlay
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null

const AIM_NAMES := ["AUS", "SCHWACH", "STARK"]
const DIFF_NAMES := ["LEICHT", "NORMAL", "SCHWER", "HARDCORE"]


func show_pause() -> void:
	hide_pause()
	host.pause_overlay = Control.new()
	host.pause_overlay.name = "PauseOverlay"
	host.pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(host.pause_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.05, 0.78)
	host.pause_overlay.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", host._hud_comic_sb(0.97, COMIC_YELLOW, 8, 30))
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title = Label.new()
	title.text = "PAUSE"
	title.label_settings = host._make_label_settings(76, Color(1.0, 0.92, 0.55), 14)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var info = Label.new()
	var _dname := "NORMAL"
	if host.game_manager != null and host.game_manager.has_method("diff_data"):
		_dname = str(host.game_manager.diff_data()["name"])
	info.text = "Welle %d   ·   Schwierigkeit: %s   ·   %d Muenzen" % [host.game_manager.wave, _dname, host.game_manager.coins]
	info.label_settings = host._make_label_settings(30, Color(0.85, 0.90, 0.95), 8)
	info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	var dtitle = Label.new()
	dtitle.text = "SCHWIERIGKEIT  (sofort wirksam)"
	dtitle.label_settings = host._make_label_settings(28, Color(0.80, 0.86, 0.92), 8)
	dtitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(dtitle)

	var drow = HBoxContainer.new()
	drow.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_theme_constant_override("separation", 10)
	box.add_child(drow)
	host.diff_buttons.clear()
	for i in range(DIFF_NAMES.size()):
		var db = host._make_pixel_button(str(DIFF_NAMES[i]), Color(0.24, 0.28, 0.38), 24)
		db.custom_minimum_size = Vector2(210, 62)
		db.pressed.connect(_on_difficulty_set.bind(i))
		drow.add_child(db)
		host.diff_buttons.append(db)

	var atitle = Label.new()
	atitle.text = "ZIELHILFE"
	atitle.label_settings = host._make_label_settings(28, Color(0.80, 0.86, 0.92), 8)
	atitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(atitle)

	var arow = HBoxContainer.new()
	arow.alignment = BoxContainer.ALIGNMENT_CENTER
	arow.add_theme_constant_override("separation", 10)
	box.add_child(arow)
	host.aim_buttons.clear()
	for i in range(3):
		var ab = host._make_pixel_button(str(AIM_NAMES[i]), Color(0.24, 0.28, 0.38), 24)
		ab.custom_minimum_size = Vector2(210, 62)
		ab.pressed.connect(_on_aim_set.bind(i))
		arow.add_child(ab)
		host.aim_buttons.append(ab)

	var sep = Control.new()
	sep.custom_minimum_size = Vector2(10, 18)
	box.add_child(sep)

	var bcont = host._make_pixel_button("WEITER  (ESC)", Color(0.24, 0.62, 0.36), 32)
	bcont.custom_minimum_size = Vector2(520, 84)
	bcont.pressed.connect(func(): host.game_manager.call("toggle_pause"))
	box.add_child(bcont)

	var brow = HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 12)
	box.add_child(brow)

	var brest = host._make_pixel_button("NEUSTART", Color(0.55, 0.42, 0.16), 26)
	brest.custom_minimum_size = Vector2(250, 72)
	brest.pressed.connect(func(): host.game_manager.call("restart_run"))
	brow.add_child(brest)

	var bset = host._make_pixel_button("EINSTELLUNGEN", Color(0.28, 0.36, 0.52), 26)
	bset.custom_minimum_size = Vector2(250, 72)
	bset.pressed.connect(func():
		# v1.42 (P1): NICHT entpausieren - die Einstellungen uebernehmen den
		# pausierten Zustand und geben ihn beim ZURUECK wieder ab.
		host._open_settings_page("pause"))
	brow.add_child(bset)

	var bmenu = host._make_pixel_button("HAUPTMENÜ", Color(0.52, 0.24, 0.24), 26)
	bmenu.custom_minimum_size = Vector2(250, 72)
	bmenu.pressed.connect(func(): host.game_manager.call("quit_to_menu"))
	brow.add_child(bmenu)

	var hint = Label.new()
	hint.text = "Tipp: Feuerknopf gedrückt halten = Dauerfeuer   ·   Q = Trank   ·   E = Bombe"
	hint.label_settings = host._make_label_settings(24, Color(0.72, 0.78, 0.85), 6)
	hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	refresh_difficulty_ui()
	refresh_aim_ui()


func hide_pause() -> void:
	if host.pause_overlay != null and is_instance_valid(host.pause_overlay):
		host.pause_overlay.queue_free()
	host.pause_overlay = null


func _on_difficulty_set(i: int) -> void:
	host.game_manager.call("set_difficulty", i)
	refresh_difficulty_ui()


func _on_aim_set(i: int) -> void:
	host.game_manager.call("set_aim_assist", i)
	refresh_aim_ui()


func refresh_difficulty_ui() -> void:
	for i in range(host.diff_buttons.size()):
		var b = host.diff_buttons[i]
		if not is_instance_valid(b):
			continue
		b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == host.game_manager.difficulty else Color(0.72, 0.74, 0.80, 1.0)
	_sync_setting_rows()


func refresh_aim_ui() -> void:
	for i in range(host.aim_buttons.size()):
		var b = host.aim_buttons[i]
		if not is_instance_valid(b):
			continue
		b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == host.game_manager.aim_assist else Color(0.72, 0.74, 0.80, 1.0)
	_sync_setting_rows()


func _sync_setting_rows() -> void:
	if host.settings_diff_buttons.size() > 0:
		for i in range(host.settings_diff_buttons.size()):
			var b = host.settings_diff_buttons[i]
			if is_instance_valid(b):
				b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == host.game_manager.difficulty else Color(0.72, 0.74, 0.80, 1.0)
	if host.settings_aim_buttons.size() > 0:
		for i in range(host.settings_aim_buttons.size()):
			var b = host.settings_aim_buttons[i]
			if is_instance_valid(b):
				b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == host.game_manager.aim_assist else Color(0.72, 0.74, 0.80, 1.0)


func show_tip(text: String) -> void:
	var l := Label.new()
	l.name = "TipLabel"
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_top = -150.0
	l.offset_bottom = -104.0
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.70))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	l.add_theme_constant_override("outline_size", 10)
	l.text = text
	l.process_mode = Node.PROCESS_MODE_ALWAYS
	# alten Tipp entfernen
	for c in host.get_children():
		if c is Label and c.name == "TipLabel":
			c.queue_free()
	host.add_child(l)
	var tw = host.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)

# Konstanten aus der Fassade (ui_manager.gd)
const COMIC_YELLOW := Color(0.99, 0.80, 0.22)
