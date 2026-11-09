class_name UpgradeToast
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func show_upgrade_toast(n: int) -> void:
	var txt := _toast_text(n)
	if host.upgrade_toast != null and is_instance_valid(host.upgrade_toast):
		# Schon offen: nur Zaehler hochziehen, keinen zweiten Toast bauen.
		var lbl = host.upgrade_toast.get_meta("count_label", null)
		if lbl != null and is_instance_valid(lbl):
			lbl.text = txt
		_pop_toast(host.upgrade_toast)
		print("[UPG][TOAST][UI] Zaehler=%d (kein zweiter Toast)" % n)
		return
	var vp: Vector2 = host.get_viewport().get_visible_rect().size
	var btn := Button.new()
	btn.name = "UpgradeToast"
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	# 380 x 96, unten mittig (bei 1080 -> y 940)
	btn.position = Vector2((vp.x - 380.0) * 0.5, vp.y - 140.0)
	btn.custom_minimum_size = Vector2(380, 96)
	btn.size = Vector2(380, 96)
	btn.pivot_offset = Vector2(190, 48)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.80, 0.22)
	sb.border_color = Color(0.05, 0.05, 0.08)
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.65)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(7, 7)
	btn.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = Color(1.0, 0.87, 0.38)
	btn.add_theme_stylebox_override("hover", sbh)
	var sbp: StyleBoxFlat = sb.duplicate()
	sbp.bg_color = Color(0.86, 0.67, 0.15)
	sbp.shadow_offset = Vector2(3, 3)
	btn.add_theme_stylebox_override("pressed", sbp)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var top := Label.new()
	top.text = txt
	top.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	top.label_settings = host._make_label_settings(26, Color(0.10, 0.08, 0.02), 0)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top)

	var bot := Label.new()
	bot.text = "ANTIPPEN"
	bot.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	bot.label_settings = host._make_label_settings(18, Color(0.24, 0.18, 0.04), 0)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(bot)

	btn.set_meta("count_label", top)
	btn.pressed.connect(func():
		print("[UPG][TOAST][UI] angetippt -> Karten")
		# v1.48 (E2): Das Signal haengt am UI-Manager, nicht am Modul.
		# Vorher lief emit_signal() ins Leere ("non-existing signal") und
		# die Karten gingen nie auf - der Toast war eine Sackgasse.
		if host != null:
			host.emit_signal("upgrade_toast_tapped"))
	host.add_child(btn)
	host.upgrade_toast = btn
	_pop_toast(btn)
	# danach leichtes Pulsieren (+-3 %)
	var pulse := btn.create_tween()
	pulse.set_loops()
	pulse.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.45).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(btn, "scale", Vector2(0.99, 0.99), 0.45).set_trans(Tween.TRANS_SINE)
	print("[UPG][TOAST][UI] gebaut verfuegbar=%d pos=(%.0f,%.0f) groesse=380x96" % [n, btn.position.x, btn.position.y])


func hide_upgrade_toast() -> void:
	if host.upgrade_toast != null and is_instance_valid(host.upgrade_toast):
		host.upgrade_toast.queue_free()
	host.upgrade_toast = null


func _toast_text(n: int) -> String:
	if n == 1:
		return "⬆  1 UPGRADE VERFÜGBAR"
	return "⬆  %d UPGRADES VERFÜGBAR" % n


func _pop_toast(node: Control) -> void:
	# Pop: 0,8 -> 1,0 in 0,18 s
	node.scale = Vector2(0.8, 0.8)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func has_upgrade_toast() -> bool:
	return host.upgrade_toast != null and is_instance_valid(host.upgrade_toast)
