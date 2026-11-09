class_name UpgradeCards
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null

const UPGRADE_COLORS := {
	"power": Color(0.85, 0.36, 0.26),
	"turbo": Color(0.28, 0.58, 0.92),
	"speed": Color(0.26, 0.78, 0.52),
	"vitality": Color(0.92, 0.34, 0.52),
	"guardian": Color(0.32, 0.68, 0.96),
	"vampire": Color(0.66, 0.30, 0.88)
}
const UPGRADE_ICONS := {
	"power": "upg_power",
	"turbo": "upg_turbo",
	"speed": "upg_speed",
	"vitality": "upg_vitality",
	"guardian": "upg_guardian",
	"vampire": "upg_vampire"
}


func show_upgrade_cards(options: Array, idx: int = 1, total: int = 1) -> void:
	hide_upgrade_cards()
	# Runde 28: alles auf die Bildschirmgroesse skalieren - vorher ragten die Karten
	# (fix 330 px + 72-px-Titel) unten aus dem Bild
	var vp: Vector2 = host.get_viewport().get_visible_rect().size
	var k: float = clampf(minf(vp.y / 820.0, vp.x / 1560.0), 0.50, 1.25)
	host.upgrade_overlay = Control.new()
	host.upgrade_overlay.name = "UpgradeOverlay"
	host.upgrade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.upgrade_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(host.upgrade_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	host.upgrade_overlay.add_child(dim)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	host.upgrade_overlay.add_child(box)

	var title = Label.new()
	# Runde 136 (H2): Zaehler im Titel, damit man weiss, wie viele noch kommen
	if total > 1:
		title.text = "UPGRADE %d VON %d" % [idx, total]
	else:
		title.text = "LEVEL UP!"
	title.label_settings = host._make_label_settings(int(72.0 * k), Color(1.0, 0.85, 0.1), int(14.0 * k))
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub = Label.new()
	if total > 1:
		sub.text = "NOCH %d VERFÜGBAR" % maxi(1, total - idx + 1)
	else:
		sub.text = "Waehle ein Upgrade"
	sub.label_settings = host._make_label_settings(int(30.0 * k), Color(0.92, 0.95, 0.92), int(6.0 * k))
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(34.0 * k))
	box.add_child(row)

	for opt in options:
		var id := str(opt["id"])
		var accent: Color = UPGRADE_COLORS.get(id, Color(0.35, 0.45, 0.65))
		var card = host._make_pixel_button("", accent.darkened(0.62), 26)
		card.custom_minimum_size = Vector2(330.0 * k, 330.0 * k)
		card.set_meta("id", id)
		card.pressed.connect(_on_card_pressed.bind(card))
		# Akzentrahmen
		for st in ["normal", "hover", "pressed"]:
			var sb: StyleBoxFlat = card.get_theme_stylebox(st).duplicate()
			sb.border_color = accent
			sb.set_border_width_all(5)
			sb.set_corner_radius_all(22)
			card.add_theme_stylebox_override(st, sb)
		row.add_child(card)

		var col = VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.offset_left = 20.0
		col.offset_right = -20.0
		col.offset_top = 22.0
		col.offset_bottom = -22.0
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", int(14.0 * k))
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(col)

		var ic := TextureRect.new()
		ic.texture = TextureManager.get_texture(str(UPGRADE_ICONS.get(id, "chest")))
		ic.custom_minimum_size = Vector2(104.0 * k, 104.0 * k)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(ic)

		var nm = Label.new()
		nm.text = str(opt["name"])
		nm.label_settings = host._make_label_settings(int(34.0 * k), accent.lightened(0.35), int(6.0 * k))
		nm.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(nm)

		var ds = Label.new()
		ds.text = str(opt["desc"])
		ds.label_settings = host._make_label_settings(int(22.0 * k), Color(0.92, 0.94, 0.96), int(4.0 * k))
		ds.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(ds)

		if host.game_manager:
			var used: int = int(host.game_manager.upg_stacks.get(id, 0))
			var cap: int = int(opt.get("cap", 0))
			if cap > 0:
				var st = Label.new()
				st.text = "Stufe %d / %d" % [used, cap]
				st.label_settings = host._make_label_settings(20, Color(1.0, 0.85, 0.4), 4)
				st.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
				st.mouse_filter = Control.MOUSE_FILTER_IGNORE
				col.add_child(st)

	var foot = Label.new()
	foot.text = "nach der Wahl geht es sofort weiter"
	foot.label_settings = host._make_label_settings(int(22.0 * k), Color(0.80, 0.84, 0.90), int(4.0 * k))
	foot.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(foot)


func hide_upgrade_cards() -> void:
	if host.upgrade_overlay != null and is_instance_valid(host.upgrade_overlay):
		host.upgrade_overlay.queue_free()
	host.upgrade_overlay = null


func _on_card_pressed(card: Button) -> void:
	var id: String = card.get_meta("id")
	hide_upgrade_cards()
	# v1.48 (E2): Signal des UI-Managers, nicht des Moduls -
	# vorher kam die Wahl nie beim GameManager an (Karten zu, Spiel blieb pausiert).
	if host != null:
		host.emit_signal("upgrade_chosen", id)
