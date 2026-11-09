class_name DisconnectOverlay
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func _build_disconnect_screen() -> void:
	host.disconnect_screen = Control.new()
	host.disconnect_screen.name = "DisconnectScreen"
	host.disconnect_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.disconnect_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(host.disconnect_screen)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07, 0.94)
	host.disconnect_screen.add_child(bg)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	host.disconnect_screen.add_child(box)

	var icon = Label.new()
	icon.text = "!"
	icon.label_settings = host._make_label_settings(110, Color(0.95, 0.55, 0.2), 0)
	icon.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(icon)

	host.disconnect_title = Label.new()
	host.disconnect_title.text = "VERBINDUNG ZUM HOST ABGEBROCHEN"
	host.disconnect_title.label_settings = host._make_label_settings(56, Color(0.98, 0.35, 0.3), 10)
	host.disconnect_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	host.disconnect_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.disconnect_title.custom_minimum_size = Vector2(1500, 0)
	box.add_child(host.disconnect_title)

	var sub = Label.new()
	sub.text = "Die Verbindung zum Host wurde getrennt."
	sub.label_settings = host._make_label_settings(32, Color(0.85, 0.85, 0.9), 6)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	host.disconnect_count = Label.new()
	host.disconnect_count.text = ""
	host.disconnect_count.label_settings = host._make_label_settings(26, Color(0.7, 0.7, 0.78), 4)
	host.disconnect_count.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(host.disconnect_count)

	var btn = host._make_styled_button("ZUR STARTSEITE", Color(0.22, 0.62, 0.32), 36)
	btn.custom_minimum_size = Vector2(460, 92)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_disconnect_back)
	box.add_child(btn)

	host.disconnect_screen.hide()


func show_disconnect_screen(msg: String = "VERBINDUNG ZUM HOST ABGEBROCHEN") -> void:
	if host.disconnect_screen == null:
		_build_disconnect_screen()
	if host.disconnect_title != null:
		host.disconnect_title.text = msg
	host.disconnect_left = 8.0
	if host.disconnect_count != null:
		host.disconnect_count.text = "Rueckkehr zur Startseite in 8 s"
	host.disconnect_screen.show()
	host.disconnect_screen.move_to_front()
	# Mauszeiger freigeben (im Spiel ist er oft gefangen)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_disconnect_screen() -> void:
	host.disconnect_left = 0.0
	if host.disconnect_screen != null:
		host.disconnect_screen.hide()


func _on_disconnect_back() -> void:
	hide_disconnect_screen()
	if host.game_manager:
		host.game_manager.abort_run_to_start()
