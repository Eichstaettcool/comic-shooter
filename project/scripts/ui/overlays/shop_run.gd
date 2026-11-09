class_name ShopRunOverlay
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null

const SHOP_ICONS := {
	"heal": "heart_full",
	"shield": "icon_shield",
	"weapon": "weapon_shotgun",
	"maxhp": "rarity_epic",
	"speed": "powerup_rapid",
	"damage": "projectile"
}


func show_shop(coins_v: int, items: Array, buys_left: int = -1, buys_max: int = -1) -> void:
	if host.shop_panel == null:
		host._sui("BUILD", "shop_panel war null -> wird jetzt gebaut")
		_build_shop()
	var sig: String = "%d|%d|%d|" % [coins_v, buys_left, buys_max]
	for itx in items:
		sig += "%s:%s;" % [str(itx.get("id", "?")), str(itx.get("bought", false))]
	if sig == host._shop_sig and host.shop_panel != null and host.shop_panel.visible:
		update_shop_coins(coins_v, buys_left, buys_max)
		return
	host._shop_sig = sig
	host._sui("SHOW", "Items=%d | Gold=%d | Kaeufe=%d/%d | Panel vorher sichtbar=%s" % [
		items.size(), coins_v, buys_left, buys_max,
		str(host.shop_panel.visible if host.shop_panel != null else false)])
	if items.is_empty():
		host._sui("WARN", "Shop mit LEERER Item-Liste geoeffnet - es gibt nichts zu kaufen")
	var buyable: int = 0
	for it0 in items:
		var p0: int = maxi(1, int(round(float(it0["price"]) * host.shop_price_mult())))
		if coins_v >= p0 and not bool(it0.get("bought", false)):
			buyable += 1
	host._sui("PRICES", "%d von %d Items bezahlbar (Gold=%d, Kaeufe frei=%s)" % [
		buyable, items.size(), coins_v, str(buys_max <= 0 or buys_left > 0)])
	# Runde 28: Shop pausiert das Spiel - die Wellen liefen vorher im Hintergrund weiter
	host.get_tree().paused = true
	var kk: float = host._ui_k()
	for c in host.shop_list.get_children():
		host.shop_list.remove_child(c)
		c.queue_free()
	for c in host.shop_continue_row.get_children():
		host.shop_continue_row.remove_child(c)
		c.queue_free()
	host.shop_title.text = "SHOP"
	if host.shop_wave_label:
		host.shop_wave_label.text = "Welle %d geschafft — jetzt einkaufen" % host.game_manager.wave if host.game_manager else ""
	if host.shop_coin_label:
		host.shop_coin_label.text = "%d" % coins_v
	if host.shop_hint:
		host.shop_hint.text = "Im Wellen-Modus gibt es Upgrades NUR hier — Level-Ups bringen keine Karten."
		if buys_max > 0:
			host.shop_hint.text = "KAEUFE: %d / %d   ·   im Wellen-Modus gibt es Upgrades NUR hier" % [maxi(0, buys_left), buys_max]
	for it in items:
		var price: int = maxi(1, int(round(float(it["price"]) * host.shop_price_mult())))
		var can: bool = coins_v >= price
		var rare: bool = bool(it.get("rare", false))
		var base_col := Color(0.24, 0.20, 0.07) if rare else Color(0.12, 0.34, 0.30)
		if not can:
			base_col = Color(0.20, 0.21, 0.25)
		var card = host._make_styled_button("", base_col, int(28.0 * kk))
		card.custom_minimum_size = Vector2(330.0 * kk, 92.0 * kk)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # Runde 34b: zentriert
		var bought: bool = bool(it.get("bought", false))
		card.disabled = not can or (buys_max > 0 and buys_left <= 0) or bought
		if bought:
			# Runde 36: gekaufte Angebote als "verpasst" markieren
			card.modulate = Color(0.45, 0.45, 0.5, 0.75)
		if rare:
			# Runde 34: Rare-Items bekommen einen goldenen Rahmen
			for st in ["normal", "hover", "pressed"]:
				var sb: StyleBoxFlat = card.get_theme_stylebox(st).duplicate()
				sb.border_color = Color(1.0, 0.82, 0.25)
				sb.set_border_width_all(5)
				sb.set_corner_radius_all(22)
				card.add_theme_stylebox_override(st, sb)
		card.pressed.connect(_on_shop_buy.bind(str(it["id"])))
		host.shop_list.add_child(card)

		var inner := HBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 14.0
		inner.offset_right = -14.0
		inner.offset_top = 8.0
		inner.offset_bottom = -8.0
		inner.add_theme_constant_override("separation", int(14.0 * kk))
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(inner)

		var ic := TextureRect.new()
		ic.texture = TextureManager.get_texture(str(SHOP_ICONS.get(str(it["id"]), "chest")))
		ic.custom_minimum_size = Vector2(64.0 * kk, 64.0 * kk)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(ic)

		var txt = VBoxContainer.new()
		txt.alignment = BoxContainer.ALIGNMENT_CENTER
		txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(txt)

		var nm = Label.new()
		nm.text = str(it["label"])
		nm.label_settings = host._make_label_settings(28, Color(1, 1, 1) if can else Color(0.6, 0.6, 0.65), 5)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt.add_child(nm)

		var pr = Label.new()
		pr.text = "%d Muenzen" % price
		pr.label_settings = host._make_label_settings(22, Color(1.0, 0.85, 0.35) if can else Color(0.85, 0.35, 0.35), 4)
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt.add_child(pr)

	var cont = host._make_styled_button("WEITER — naechste Welle", Color(0.26, 0.48, 0.92), int(30.0 * kk))
	cont.custom_minimum_size = Vector2(400.0 * kk, 88.0 * kk)
	cont.pressed.connect(_on_shop_continue)
	host.shop_continue_row.add_child(cont)
	host.shop_panel.visible = true


func hide_shop() -> void:
	if host.shop_panel:
		host.shop_panel.visible = false
	host._shop_sig = ""
	host._sui("HIDE", "Shop geschlossen (modal_open=%s)" % str(host.is_modal_open()))
	# Runde 28: nach dem Shop laeuft das Spiel weiter (Pausenmenue/Upgrade bleiben aussen vor)
	if not host.is_modal_open():
		host.get_tree().paused = false


func update_shop_coins(coins_v: int, buys_left: int = -1, buys_max: int = -1) -> void:
	# Leichtgewichtiges Update: nur Gold + Hinweis, KEIN Neuaufbau
	if host.shop_coin_label != null:
		host.shop_coin_label.text = "%d" % coins_v
	if host.shop_hint != null and buys_max > 0:
		host.shop_hint.text = "KAEUFE: %d / %d   ·   im Wellen-Modus gibt es Upgrades NUR hier" % [
			maxi(0, buys_left), buys_max]


func _build_shop() -> void:
	host.shop_panel = ColorRect.new()
	host.shop_panel.name = "ShopPanel"
	host.shop_panel.color = Color(0.04, 0.05, 0.08, 0.92)
	host.shop_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	host.shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(host.shop_panel)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var k: float = host._ui_k()
	panel.offset_left = 320.0 * k
	panel.offset_right = -320.0 * k
	panel.offset_top = 80.0 * k
	panel.offset_bottom = -80.0 * k
	panel.add_theme_stylebox_override("panel", host._make_panel_sb(0.96, 30))
	host.shop_panel.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(14.0 * k))
	panel.add_child(box)

	# Runde 29: Scrollbereich - kann nie den WEITER-Button aus dem Bild draengen
	host.shop_scroll = ScrollContainer.new()
	host.shop_scroll.custom_minimum_size = Vector2(0.0, float(host.get_viewport().get_visible_rect().size.y) * 0.44)
	host.shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.shop_scroll.add_theme_constant_override("scroll_deadzone", 12)
	# Runde 34b: erst an der richtigen Stelle (nach Kopf/Welle) in die Box haengen -
	# vorher stand der ScrollContainer als ERSTES Kind -> die Itemsappeared ueber
	# der SHOP-Ueberschrift.

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 24)
	box.add_child(head)

	host.shop_title = Label.new()
	host.shop_title.text = "SHOP"
	host.shop_title.label_settings = host._make_label_settings(int(62.0 * k), Color(0.55, 0.95, 1.0), int(10.0 * k))
	head.add_child(host.shop_title)

	var coin_ic := TextureRect.new()
	coin_ic.texture = TextureManager.get_texture("icon_coin")
	coin_ic.custom_minimum_size = Vector2(48.0 * k, 48.0 * k)
	coin_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(coin_ic)

	host.shop_coin_label = Label.new()
	host.shop_coin_label.text = "0"
	host.shop_coin_label.label_settings = host._make_label_settings(int(54.0 * k), Color(1.0, 0.85, 0.25), int(8.0 * k))
	head.add_child(host.shop_coin_label)

	host.shop_wave_label = Label.new()
	host.shop_wave_label.label_settings = host._make_label_settings(int(28.0 * k), Color(0.88, 0.92, 0.95), int(5.0 * k))
	host.shop_wave_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(host.shop_wave_label)

	host.shop_list = GridContainer.new()          # Runde 36: Grid statt Liste
	host.shop_list.columns = 2
	host.shop_list.add_theme_constant_override("h_separation", int(14.0 * k))
	host.shop_list.add_theme_constant_override("v_separation", int(10.0 * k))
	# Runde 34b: HBox als Rahmen, damit die Item-Liste mittig sitzt
	# (die Liste haengt sonst links im Scrollbereich)
	var shop_wrap := HBoxContainer.new()
	shop_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.shop_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(host.shop_scroll)                                    # Runde 34b: richtige Reihenfolge
	host.shop_scroll.add_child(shop_wrap)
	shop_wrap.add_child(host.shop_list)

	host.shop_continue_row = HBoxContainer.new()
	host.shop_continue_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(host.shop_continue_row)

	host.shop_hint = Label.new()
	host.shop_hint.label_settings = host._make_label_settings(22, Color(0.75, 0.82, 0.85), 4)
	host.shop_hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(host.shop_hint)

	host.shop_panel.visible = false


func _on_shop_buy(id: String) -> void:
	host._sui("CLICK", "Kauf-Klick '%s' (Panel sichtbar=%s, paused=%s)" % [
		id, str(host.shop_panel.visible if host.shop_panel != null else false), str(host.get_tree().paused)])
	if host.game_manager:
		host.game_manager.buy_shop_item(id)
	else:
		host._sui("FAIL", "Klick '%s' ohne game_manager - nichts passiert" % id)


func _on_shop_continue() -> void:
	if host.game_manager:
		host.game_manager._next_wave()
