class_name Hud
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func _create_hud():
	host.hud = Control.new()
	host.hud.name = "HUD"
	# Bugfix Runde 15: ohne Anker war die Groesse 0x0 -> alles mit PRESET_CENTER_TOP
	# oder anchor 0.5 (Banner, Boss-Leiste) lag halb ausserhalb des Bildschirms.
	host.hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.hud.mouse_filter = Control.MOUSE_FILTER_IGNORE   # Joystick/Buttons nicht blockieren
	host.add_child(host.hud)

	# ---------------- Oben links: Leben + XP ----------------
	var left = VBoxContainer.new()
	left.name = "LeftPanel"
	left.position = Vector2(18, 14)
	left.add_theme_constant_override("separation", 8)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.hud.add_child(left)

	var life_panel = PanelContainer.new()
	life_panel.name = "LifePanel"
	life_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_panel.add_theme_stylebox_override("panel", host._hud_comic_sb(0.92))
	left.add_child(life_panel)

	var life_box = VBoxContainer.new()
	life_box.add_theme_constant_override("separation", 7)
	life_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_panel.add_child(life_box)

	host.health_bar = HBoxContainer.new()
	host.health_bar.name = "HealthBar"
	host.health_bar.add_theme_constant_override("separation", 4)
	host.health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_box.add_child(host.health_bar)
	host.heart_labels.clear()
	for i in range(5):
		var heart = TextureRect.new()
		heart.name = "Heart%d" % i
		heart.texture = TextureManager.get_texture("heart_full")
		heart.custom_minimum_size = Vector2(42, 42)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		host.health_bar.add_child(heart)
		host.heart_labels.append(heart)

	# P2-Herzen (Duo) — vorhanden, aktuell ungenutzt
	host.health_bar2 = HBoxContainer.new()
	host.health_bar2.name = "HealthBar2"
	host.health_bar2.visible = false
	life_box.add_child(host.health_bar2)
	host.heart_labels2.clear()
	for i in range(5):
		var heart2 = TextureRect.new()
		heart2.name = "Heart2_%d" % i
		heart2.texture = TextureManager.get_texture("heart_full")
		heart2.custom_minimum_size = Vector2(36, 36)
		heart2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		host.health_bar2.add_child(heart2)
		host.heart_labels2.append(heart2)

	var xp_row = HBoxContainer.new()
	xp_row.name = "XPRow"
	xp_row.add_theme_constant_override("separation", 10)
	xp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_box.add_child(xp_row)

	host.lvl_label = Label.new()
	host.lvl_label.name = "LvlLabel"
	host.lvl_label.text = "LVL 1"
	host.lvl_label.add_theme_font_size_override("font_size", 22)
	host.lvl_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	xp_row.add_child(host.lvl_label)

	host.xp_bar = ProgressBar.new()
	host.xp_bar.name = "XPBar"
	host.xp_bar.custom_minimum_size = Vector2(290, 18)
	host.xp_bar.max_value = 25
	host.xp_bar.value = 0
	host.xp_bar.show_percentage = false
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.10, 0.10, 0.12, 0.8)
	sb_bg.set_corner_radius_all(7)
	host.xp_bar.add_theme_stylebox_override("background", sb_bg)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.30, 0.85, 1.0)
	sb_fg.set_corner_radius_all(7)
	host.xp_bar.add_theme_stylebox_override("fill", sb_fg)
	xp_row.add_child(host.xp_bar)

	# ---------------- Oben Mitte: Score + Combo ----------------
	var center = VBoxContainer.new()
	center.name = "CenterPanel"
	center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center.offset_left = -320.0
	center.offset_right = 320.0
	center.offset_top = 10.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.hud.add_child(center)

	host.score_label = Label.new()
	host.score_label.name = "ScoreLabel"
	host.score_label.text = "0"
	host.score_label.label_settings = host._make_label_settings(48, Color(1, 1, 1), 10)
	host.score_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(host.score_label)

	host.combo_label = Label.new()
	host.combo_label.name = "ComboLabel"
	host.combo_label.text = ""
	host.combo_label.label_settings = host._make_label_settings(28, Color(1.0, 0.62, 0.12), 8)
	host.combo_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(host.combo_label)

	# Runde 136 (I3): Jahreszeit oben mittig + "als Naechstes"
	host.season_hud_label = Label.new()
	host.season_hud_label.name = "SeasonHud"
	host.season_hud_label.text = ""
	host.season_hud_label.label_settings = host._make_label_settings(22, Color(0.85, 0.95, 0.85), 6)
	host.season_hud_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	host.season_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(host.season_hud_label)

	# Boss-HP (mittig unter dem Score)
	host.boss_bar = ProgressBar.new()
	host.boss_bar.name = "BossBar"
	host.boss_bar.anchor_left = 0.18
	host.boss_bar.anchor_right = 0.82
	host.boss_bar.anchor_top = 0.135
	host.boss_bar.anchor_bottom = 0.135
	host.boss_bar.offset_left = 0.0
	host.boss_bar.offset_right = 0.0
	host.boss_bar.offset_top = 0.0
	host.boss_bar.offset_bottom = 26.0
	host.boss_bar.max_value = 40
	host.boss_bar.show_percentage = false
	host.boss_bar.visible = false
	var b_bg = StyleBoxFlat.new()
	b_bg.bg_color = Color(0.10, 0.05, 0.05, 0.85)
	b_bg.border_color = Color(0.08, 0.08, 0.10)
	b_bg.set_border_width_all(3)
	b_bg.set_corner_radius_all(8)
	host.boss_bar.add_theme_stylebox_override("background", b_bg)
	var b_fg = StyleBoxFlat.new()
	b_fg.bg_color = Color(0.85, 0.15, 0.15)
	b_fg.set_corner_radius_all(6)
	host.boss_bar.add_theme_stylebox_override("fill", b_fg)
	host.hud.add_child(host.boss_bar)

	# Runde 136 (E1): Name unter der Boss-Leiste - Mini-Bosse bekommen ihn
	# genauso wie der grosse Boss.
	host.boss_name_label = Label.new()
	host.boss_name_label.name = "BossName"
	host.boss_name_label.anchor_left = 0.18
	host.boss_name_label.anchor_right = 0.82
	host.boss_name_label.anchor_top = 0.135
	host.boss_name_label.anchor_bottom = 0.135
	host.boss_name_label.offset_top = 30.0
	host.boss_name_label.offset_bottom = 62.0
	host.boss_name_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	host.boss_name_label.label_settings = host._make_label_settings(24, Color(1.0, 0.86, 0.45), 6)
	host.boss_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.boss_name_label.visible = false
	host.hud.add_child(host.boss_name_label)

	# ---------------- Oben rechts: Waffen + Muenzen + Welle ----------------
	var right = VBoxContainer.new()
	right.name = "RightPanel"
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -436.0
	right.offset_right = -18.0
	right.offset_top = 14.0
	right.add_theme_constant_override("separation", 8)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.hud.add_child(right)

	var wp = PanelContainer.new()
	wp.name = "WeaponPanel"
	wp.add_theme_stylebox_override("panel", host._hud_comic_sb(0.92))
	right.add_child(wp)

	var wbox = VBoxContainer.new()
	wbox.add_theme_constant_override("separation", 6)
	wp.add_child(wbox)

	var wep_title = Label.new()
	wep_title.name = "WeaponTitle"
	wep_title.text = "WAFFEN  (tippen)"
	wep_title.add_theme_font_size_override("font_size", 18)
	wep_title.add_theme_color_override("font_color", Color(0.82, 0.88, 0.94))
	wbox.add_child(wep_title)

	host.weapon_row = GridContainer.new()
	host.weapon_row.name = "WeaponRow"
	host.weapon_row.columns = 3
	host.weapon_row.add_theme_constant_override("h_separation", 8)
	host.weapon_row.add_theme_constant_override("v_separation", 8)
	wbox.add_child(host.weapon_row)

	# Runde 49: Reload-Indikator - Balken + Munitionstext
	host.reload_row = HBoxContainer.new()
	host.reload_row.name = "ReloadRow"
	host.reload_row.add_theme_constant_override("separation", 8)
	wbox.add_child(host.reload_row)

	# Runde 49: Button fuer die Waffen-Stats-Seite
	var stats_btn = host._make_pixel_button("WAFFEN-STATS", Color(0.26, 0.34, 0.52), 18)
	stats_btn.custom_minimum_size = Vector2(150, 30)
	stats_btn.pressed.connect(host._open_stats_page)
	wbox.add_child(stats_btn)

	host.reload_bar = ProgressBar.new()
	host.reload_bar.name = "ReloadBar"
	host.reload_bar.custom_minimum_size = Vector2(150, 18)
	host.reload_bar.show_percentage = false
	host.reload_bar.max_value = 100.0
	host.reload_bar.value = 0.0
	host.reload_bar.visible = false
	var rb_bg := StyleBoxFlat.new()
	rb_bg.bg_color = Color(0.10, 0.11, 0.14, 0.9)
	rb_bg.set_corner_radius_all(0)
	host.reload_bar.add_theme_stylebox_override("background", rb_bg)
	var rb_fg := StyleBoxFlat.new()
	rb_fg.bg_color = Color(0.98, 0.72, 0.20)
	rb_fg.set_corner_radius_all(0)
	host.reload_bar.add_theme_stylebox_override("fill", rb_fg)
	host.reload_row.add_child(host.reload_bar)

	host.reload_label = Label.new()
	host.reload_label.name = "ReloadLabel"
	host.reload_label.label_settings = host._make_label_settings(20, Color(1.0, 0.85, 0.35), 4)
	host.reload_label.visible = false
	host.reload_row.add_child(host.reload_label)
	host.weapon_hud = wbox

	# Utility-Leiste (Runde 15): Trank + Bombe, antippbar oder Q/E
	var urow = HBoxContainer.new()
	urow.name = "UtilityRow"
	urow.add_theme_constant_override("separation", 6)
	wbox.add_child(urow)
	host.util_buttons.clear()
	for kind in ["potion", "bomb"]:
		var ub := Button.new()
		ub.custom_minimum_size = Vector2(136, 64)
		ub.focus_mode = Control.FOCUS_NONE
		ub.text = "TRANK x0"
		ub.set_meta("loc_fmt", true)
		ub.add_theme_font_size_override("font_size", 20)
		ub.add_theme_stylebox_override("normal", host._hud_comic_sb(0.88, Color(0.42, 0.48, 0.60), 8, 8))
		ub.add_theme_stylebox_override("hover", host._hud_comic_sb(0.95, COMIC_YELLOW, 8, 8))
		ub.add_theme_stylebox_override("pressed", host._hud_comic_sb(1.0, COMIC_YELLOW, 8, 8))
		ub.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		ub.pressed.connect(host._on_util_pressed.bind(str(kind)))
		urow.add_child(ub)
		host.util_buttons[str(kind)] = ub

	# v1.40: zwei Icons fuer den RUNDEN-Modus - unter der Waffen-/Traenke-Leiste
	var wicons := VBoxContainer.new()
	wicons.name = "WaveIconBox"
	wicons.add_theme_constant_override("separation", 6)
	wicons.visible = false
	wbox.add_child(wicons)
	host.wave_shop_btn = _wave_icon_button("SHOP", Color(0.95, 0.72, 0.25))
	host.wave_shop_btn.name = "WaveShopBtn"
	host.wave_shop_btn.pressed.connect(func():
		if host.game_manager != null:
			host.game_manager.call("open_rounds_shop"))
	wicons.add_child(host.wave_shop_btn)
	host.wave_next_btn = _wave_icon_button("WELLE >>", Color(0.35, 0.85, 0.45))
	host.wave_next_btn.name = "WaveNextBtn"
	host.wave_next_btn.pressed.connect(func():
		if host.game_manager != null:
			host.game_manager.call("next_round"))
	wicons.add_child(host.wave_next_btn)
	# W6.1: Vorschau der naechsten Runde
	host.wave_preview = Label.new()
	host.wave_preview.name = "WavePreview"
	host.wave_preview.custom_minimum_size = Vector2(300, 0)
	host.wave_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.wave_preview.add_theme_font_size_override("font_size", 15)
	host.wave_preview.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	wicons.add_child(host.wave_preview)
	host.wave_icon_box = wicons

	# Muenz-Chip (nur Wellen-Modus)
	host.coin_panel = PanelContainer.new()
	host.coin_panel.name = "CoinPanel"
	host.coin_panel.add_theme_stylebox_override("panel", host._hud_comic_sb(0.90))
	host.coin_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	host.coin_panel.visible = false
	right.add_child(host.coin_panel)

	var coin_row = HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 8)
	host.coin_panel.add_child(coin_row)

	host.coin_icon = TextureRect.new()
	host.coin_icon.name = "CoinIcon"
	host.coin_icon.texture = TextureManager.get_texture("icon_coin")
	host.coin_icon.custom_minimum_size = Vector2(34, 34)
	host.coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	host.coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(host.coin_icon)

	host.coin_label = Label.new()
	host.coin_label.name = "CoinLabel"
	host.coin_label.text = "0"
	host.coin_label.add_theme_font_size_override("font_size", 30)
	host.coin_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	coin_row.add_child(host.coin_label)

	host.wave_label = Label.new()
	host.wave_label.name = "WaveLabel"
	host.wave_label.add_theme_font_size_override("font_size", 22)
	host.wave_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	host.wave_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	host.wave_label.custom_minimum_size = Vector2(418, 0)
	host.wave_label.visible = false
	right.add_child(host.wave_label)

	host.buff_label = Label.new()
	host.buff_label.name = "BuffLabel"
	host.buff_label.text = ""
	host.buff_label.add_theme_font_size_override("font_size", 22)
	host.buff_label.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	host.buff_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	host.buff_label.custom_minimum_size = Vector2(418, 0)
	right.add_child(host.buff_label)

	host.switch_label = Label.new()
	host.switch_label.name = "SwitchLabel"
	host.switch_label.text = ""
	host.switch_label.add_theme_font_size_override("font_size", 20)
	host.switch_label.add_theme_color_override("font_color", Color(0.60, 1.0, 0.82))
	host.switch_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	host.switch_label.custom_minimum_size = Vector2(418, 0)
	right.add_child(host.switch_label)

	host.switch_bar = ProgressBar.new()
	host.switch_bar.custom_minimum_size = Vector2(418, 12)
	host.switch_bar.show_percentage = false
	host.switch_bar.max_value = 100
	host.switch_bar.value = 0
	host.switch_bar.visible = false
	var swb = StyleBoxFlat.new()
	swb.bg_color = Color(0.10, 0.11, 0.14, 0.85)
	swb.set_corner_radius_all(6)
	host.switch_bar.add_theme_stylebox_override("background", swb)
	var swf = StyleBoxFlat.new()
	swf.bg_color = Color(0.35, 0.90, 0.70)
	swf.set_corner_radius_all(6)
	host.switch_bar.add_theme_stylebox_override("fill", swf)
	right.add_child(host.switch_bar)

	# ---------------- Partner-Liste (links unter dem Leben-Panel) ----------------
	host.partner_list = VBoxContainer.new()
	host.partner_list.name = "PartnerList"
	host.partner_list.position = Vector2(18, 186)
	host.partner_list.add_theme_constant_override("separation", 10)
	host.partner_list.modulate = Color(1, 1, 1, 0.78)
	host.partner_list.visible = false
	host.hud.add_child(host.partner_list)

	# Alt-Box (WLAN-Phase-1) bleibt vorhanden, aber ungenutzt
	host.partner_box = VBoxContainer.new()
	host.partner_box.name = "PartnerBox"
	host.partner_box.visible = false
	host.partner_box.add_child(Label.new())
	host.partner_tag = Label.new()
	host.partner_tag.text = "PARTNER (WLAN)"
	host.partner_box.add_child(host.partner_tag)
	host.partner_hearts_row = HBoxContainer.new()
	host.partner_box.add_child(host.partner_hearts_row)
	host.partner_weapon_icon = TextureRect.new()
	host.partner_weapon_label = Label.new()
	host.partner_box.add_child(host.partner_weapon_icon)
	host.partner_box.add_child(host.partner_weapon_label)
	host.hud.add_child(host.partner_box)

	var p2tag = Label.new()
	p2tag.name = "P2Tag"
	p2tag.text = "P2"
	p2tag.set_meta("loc_fmt", true)
	p2tag.visible = false
	host.hud.add_child(p2tag)

	# Pause-Knopf (Runde 15)
	var pause_btn := Button.new()
	pause_btn.name = "PauseButton"
	pause_btn.text = "II"
	pause_btn.set_meta("loc_fmt", true)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.offset_left = -84.0
	pause_btn.offset_right = -20.0
	pause_btn.offset_top = 14.0
	pause_btn.offset_bottom = 74.0
	pause_btn.add_theme_font_size_override("font_size", 30)
	pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn.pressed.connect(func(): host.game_manager.call("toggle_pause"))
	host.hud.add_child(pause_btn)

	# ---------------- PING (Mehrspieler) ----------------
	host.ping_btn = Button.new()
	host.ping_btn.name = "PingButton"
	host.ping_btn.text = "PING"
	host.ping_btn.focus_mode = Control.FOCUS_NONE
	host.ping_btn.anchor_left = 1.0
	host.ping_btn.anchor_right = 1.0
	host.ping_btn.offset_left = -152.0
	host.ping_btn.offset_right = -92.0
	host.ping_btn.offset_top = 14.0
	host.ping_btn.offset_bottom = 74.0
	host.ping_btn.add_theme_font_size_override("font_size", 20)
	host.ping_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	host.ping_btn.visible = false
	host.ping_btn.pressed.connect(host._on_ping_pressed)
	host.hud.add_child(host.ping_btn)

	# ---------------- Banner ----------------
	host.banner_label = Label.new()
	host.banner_label.name = "BannerLabel"
	host.banner_label.text = ""
	host.banner_label.anchor_left = 0.0
	host.banner_label.anchor_right = 1.0
	host.banner_label.anchor_top = 0.28
	host.banner_label.anchor_bottom = 0.28
	host.banner_label.offset_left = 0.0
	host.banner_label.offset_right = 0.0
	host.banner_label.offset_top = 0.0
	host.banner_label.offset_bottom = 110.0
	host.banner_label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	host.banner_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	host.banner_label.add_theme_font_size_override("font_size", 84)
	host.banner_label.add_theme_color_override("font_color", Color(1, 1, 1))
	host.banner_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	host.banner_label.add_theme_constant_override("outline_size", 14)
	host.banner_label.modulate.a = 0.0
	host.banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.hud.add_child(host.banner_label)

	# ---------------- FPS/Debug ----------------
	host.fps_label = Label.new()
	host.fps_label.name = "FpsLabel"
	host.fps_label.position = Vector2(14, 1010)
	host.fps_label.custom_minimum_size = Vector2(1100, 34)
	host.fps_label.size = Vector2(1100, 34)
	host.fps_label.add_theme_font_size_override("font_size", 22)
	host.fps_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.6))
	host.fps_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	host.fps_label.add_theme_constant_override("outline_size", 8)
	host.fps_label.visible = false
	host.hud.add_child(host.fps_label)

	# Touch-Controls
	_create_touch_controls()

	host.hud.hide()


func _create_touch_controls():
	# Control (NICHT CanvasLayer!) -> wird mit dem HUD ausgeblendet,
	# damit Joysticks auf Start-/Todes-Screen unsichtbar sind (V3)
	host.touch_layer = Control.new()
	host.touch_layer.name = "TouchLayer"
	host.touch_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.touch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.hud.add_child(host.touch_layer)

	var joystick_script = load("res://scripts/touch_joystick.gd")

	# Bewegungs-Joystick P1 links: 440px Hitbox, Visual 300px (etwas mehr zur Mitte)
	host.move_stick = joystick_script.new()
	host.move_stick.name = "MoveStick"
	host.move_stick.position = Vector2(96, 566)
	host.move_stick.size = Vector2(440, 440)
	host.move_stick.vis_scale = 0.68
	host.move_stick.direction_changed.connect(host._on_move_stick)
	host.touch_layer.add_child(host.move_stick)

	# Schuss-Button P1 (Startposition = Solo: rechts unten)
	host.shoot_btn = TouchScreenButton.new()
	host.shoot_btn.name = "ShootButton"
	host.shoot_btn.position = Vector2(1580, 790)
	# v1.48 (C3): Textur ist jetzt 256 px -> 0.9 ergibt dieselbe Groesse (~230 px)
	host.shoot_btn.scale = Vector2(0.9, 0.9)
	host.shoot_btn.texture_normal = TextureManager.get_texture("btn_shoot")
	host.shoot_btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	host.shoot_btn.connect("pressed", Callable(host, "_on_shoot_down"))
	host.shoot_btn.connect("released", Callable(host, "_on_shoot_up"))
	host.touch_layer.add_child(host.shoot_btn)

	# --- P2 (Duo): Feuer links, Joystick ganz rechts ---
	host.move_stick2 = joystick_script.new()
	host.move_stick2.name = "MoveStick2"
	host.move_stick2.position = Vector2(1460, 620)
	host.move_stick2.size = Vector2(440, 440)
	host.move_stick2.vis_scale = 0.68
	host.move_stick2.direction_changed.connect(host._on_move_stick2)
	host.move_stick2.visible = false
	host.touch_layer.add_child(host.move_stick2)

	host.shoot_btn2 = TouchScreenButton.new()
	host.shoot_btn2.name = "ShootButton2"
	host.shoot_btn2.position = Vector2(1290, 880)
	host.shoot_btn2.scale = Vector2(0.8, 0.8)
	host.shoot_btn2.texture_normal = TextureManager.get_texture("btn_shoot")
	host.shoot_btn2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	host.shoot_btn2.connect("pressed", Callable(host, "_on_shoot_down2"))
	host.shoot_btn2.connect("released", Callable(host, "_on_shoot_up2"))
	host.shoot_btn2.visible = false
	host.touch_layer.add_child(host.shoot_btn2)




func update_partner(hp: int, mx: int, weapon_name: String, shield: int = 0, pname: String = "") -> void:
	# Alt-Aufruf: auf die neue Mitspieler-Liste (Slot 2) umleiten
	update_partner_slot(2, hp, mx, weapon_name, shield, pname)
	return
	if host.partner_box == null:
		return
	host.partner_box.visible = true
	while host.partner_hearts.size() < mx:
		var h = TextureRect.new()
		h.texture = TextureManager.get_texture("heart_full")
		h.custom_minimum_size = Vector2(24, 24)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		host.partner_hearts_row.add_child(h)
		host.partner_hearts.append(h)
	for i in range(host.partner_hearts.size()):
		host.partner_hearts[i].texture = TextureManager.get_texture("heart_full" if i < hp else "heart_empty")
	host.partner_weapon_icon.texture = TextureManager.get_texture("weapon_" + weapon_name)
	host.partner_weapon_label.text = weapon_name
	var tag := pname if pname != "" else "PARTNER (WLAN)"
	host.partner_tag.text = tag + ("  +%d Schild" % shield if shield > 0 else "")


func refresh_utility_hud(utils: Dictionary = {}, weapon_key: String = "") -> void:
	for kind in host.util_buttons.keys():
		var b = host.util_buttons[kind]
		if not is_instance_valid(b):
			continue
		var n := int(utils.get(kind, 0))
		var nm := Loc.t("TRANK (Q)") if str(kind) == "potion" else Loc.t("BOMBE (E)")
		b.text = "%s x%d" % [nm, n]
		b.set_meta("loc_fmt", true)
		b.modulate = Color(1, 1, 1, 1) if n > 0 else Color(0.62, 0.62, 0.68, 0.85)


func update_reload_indicator(progress: float, text: String) -> void:
	# Runde 49: Balken + Text aktualisieren (0 = kein Nachladen)
	if host.reload_bar == null or host.reload_label == null:
		return
	if progress <= 0.0 and text == "":
		host.reload_bar.visible = false
		host.reload_label.visible = false
		return
	host.reload_bar.visible = true
	host.reload_bar.value = clampf(progress, 0.0, 1.0) * 100.0
	host.reload_label.visible = true
	host.reload_label.text = text


func refresh_weapon_hud(owned: Array, current_key: String) -> void:
	if host.weapon_row == null:
		return
	# Runde 33: vorher wurden die Buttons JEDES Mal neu gebaut (clear + queue_free).
	# Im MP ruft der Sync das 15x/s pro Spieler auf -> massenhaftes Node-Churn
	# (Hauptursache der schlechten Performance beim Nicht-Host).
	var sig := ""
	var rar_map: Dictionary = {}
	if host.player != null and is_instance_valid(host.player):
		var wr = host.player.get("weapon_rarity")
		if wr is Dictionary:
			rar_map = wr
	for k in owned:
		sig += str(k) + ":" + str(rar_map.get(str(k), "common")) + "|"
	sig += "#" + str(current_key)
	if sig == host._weapon_hud_sig:
		return
	host._weapon_hud_sig = sig
	for c in host.weapon_row.get_children():
		host.weapon_row.remove_child(c)
		c.queue_free()
	host.weapon_buttons.clear()
	for key in owned:
		var b := Button.new()
		var is_cur: bool = str(key) == current_key
		# Runde 61: groessere Slots (88px) mit Comic-Rahmen - vorher 56px,
		# dadurch war das Antippen auf dem Handy kaum zu treffen.
		b.custom_minimum_size = Vector2(88, 88)
		b.icon = TextureManager.get_texture(str(key))
		b.expand_icon = true
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = str(key)
		var frame: Color = COMIC_YELLOW if is_cur else Color(0.42, 0.48, 0.60)
		# Runde 136b (J4): Stufe am HUD sichtbar - Rahmenfarbe + Farbkante
		var rar: String = str(rar_map.get(str(key), "common"))
		var rcol: Color = host._rarity_col_of(rar)
		if not is_cur:
			frame = rcol
		b.tooltip_text = "%s · %s" % [str(key).replace("weapon_", "").to_upper(), host._rarity_label_de(rar)]
		# v1.42 (P2.4): Schaden + RPM der AKTUELLEN Stufe in der Anzeige
		var wst: Dictionary = {}
		if host.player != null and is_instance_valid(host.player) and host.player.has_method("stats_by_key"):
			wst = host.player.call("stats_by_key", str(key))
		if not wst.is_empty():
			b.tooltip_text += "\n%d Schaden · %d RPM" % [int(wst["damage"]), int(wst.get("rpm", 0))]
		b.add_theme_stylebox_override("normal", host._hud_comic_sb(0.95 if is_cur else 0.80, frame, 10, 6))
		b.add_theme_stylebox_override("hover", host._hud_comic_sb(0.98, COMIC_YELLOW.lightened(0.12), 10, 6))
		b.add_theme_stylebox_override("pressed", host._hud_comic_sb(1.0, COMIC_YELLOW, 10, 6))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.modulate = Color(1, 1, 1, 1) if is_cur else Color(0.80, 0.82, 0.86, 0.92)
		b.pressed.connect(_on_weapon_button.bind(str(key)))
		# Farbkante oben im Slot: Höhe zeigt die Stufe (4/6/8/10 px)
		var stripe := ColorRect.new()
		stripe.color = rcol
		stripe.position = Vector2(4, 4)
		var sh: int = 4
		match rar:
			"rare":
				sh = 6
			"epic":
				sh = 8
			"legendary":
				sh = 10
		stripe.size = Vector2(80, sh)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(stripe)
		host.weapon_row.add_child(b)
		host.weapon_buttons.append(b)
		print("[WPN][HUD] slot=%s stufe=%s farbe=(%.2f,%.2f,%.2f) kante=%dpx" % [
			str(key), rar, rcol.r, rcol.g, rcol.b, sh])


func _on_weapon_button(key: String) -> void:
	if host.player == null:
		return
	host.player.call("switch_weapon", key)
	refresh_weapon_hud(host.player.call("get_owned_weapons"), host.player.call("get_weapon_key"))


func update_switch_hint(txt: String, cur: int = -1, need: int = -1) -> void:
	if host.switch_label:
		host.switch_label.text = txt
	if host.switch_bar:
		if need > 0:
			host.switch_bar.visible = true
			host.switch_bar.max_value = need
			host.switch_bar.value = mini(cur, need)
		else:
			host.switch_bar.visible = false


func update_buffs(rapid: float, freeze: float, gold: float = 0.0) -> void:
	if host.buff_label == null:
		return
	var txt := ""
	if rapid > 0.0:
		txt += "SCHNELLFEUER %ds" % int(ceil(rapid))
	if freeze > 0.0:
		if txt != "":
			txt += "   "
		txt += "FROST %ds" % int(ceil(freeze))
	if gold > 0.0:
		if txt != "":
			txt += "   "
		txt += "GOLDRAUSCH %ds" % int(ceil(gold))
	if host.buff_label.text != txt:
		host.buff_label.text = txt
	host.buff_label.visible = txt != ""


func update_season_hud(cur_name: String, next_name: String, col: Color) -> void:
	# Runde 136 (I3): Jahreszeit + "als Naechstes" oben mittig
	if host.season_hud_label == null:
		return
	if cur_name == "":
		host.season_hud_label.text = ""
		return
	# v1.41 (F5): Jahreszeit-Zeile uebersetzen (Name + "als Naechstes")
	var txt: String = Loc.t(cur_name)
	if next_name != "":
		txt += Loc.t("   ·   als Nächstes: ") + Loc.t(next_name)
	host.season_hud_label.text = txt
	host.season_hud_label.set_meta("loc_fmt", true)
	host.season_hud_label.set_meta("loc_fmt", true)
	host.season_hud_label.label_settings = host._make_label_settings(22, col.lightened(0.25), 6)
	print("[SEASON][HUD] %s" % txt)


func show_hud() -> void:
	if host.hud:
		host.hud.show()
	host.hide_lobby()
	if host.lan_panel:
		host.lan_panel.hide()
	if host.move_stick:
		host.move_stick.force_reset()
	if host.move_stick2:
		host.move_stick2.force_reset()
	if host.boss_bar:
		host.boss_bar.visible = false
		host.boss_bar.modulate.a = 1.0
	if host.start_screen:
		host.start_screen.hide()
	if host.death_screen:
		host.death_screen.hide()


func update_partner_slot(slot: int, hp: int, mx: int, weapon_name: String, shield: int, pname: String = "") -> void:
	host.partner_slots[slot] = { "hp": hp, "mx": mx, "weapon": weapon_name, "shield": shield, "name": pname }
	host._render_partner_rows()


func show_banner(text: String, color: Color = Color(1, 1, 1)) -> void:
	if host.banner_label == null:
		return
	host.banner_label.text = text
	# v1.41 (F5): Bannertexte kommen schon uebersetzt (Loc.fmt)
	host.banner_label.set_meta("loc_fmt", true)
	host.banner_label.add_theme_color_override("font_color", color)
	host.banner_label.add_theme_color_override("font_outline_color", Color(0.06, 0.06, 0.08))
	host.banner_label.add_theme_constant_override("outline_size", 14)
	host.banner_label.visible = true
	host.banner_label.modulate = Color(1, 1, 1, 1)
	host.banner_label.scale = Vector2(0.65, 0.65)
	var tw = host.create_tween()
	tw.tween_property(host.banner_label, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.15)
	tw.tween_property(host.banner_label, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func(): host.banner_label.visible = false)


func update_health(current: int, maximum: int, pid: int = 1) -> void:
	# Herzanzahl dynamisch an maximum anpassen (Max-Health-Upgrade, V6)
	var bar = host.health_bar if pid == 1 else host.health_bar2
	var arr = host.heart_labels if pid == 1 else host.heart_labels2
	if bar == null:
		return
	while arr.size() < maximum:
		# Runde 26: gleiche Einstellungen wie die Starthherzen - vorher fehlten
		# expand_mode/stretch_mode, dadurch wurden Zusatz-Herzen vertikal verzerrt
		var heart = TextureRect.new()
		heart.texture = TextureManager.get_texture("heart_full")
		heart.custom_minimum_size = Vector2(42, 42)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_child(heart)
		arr.append(heart)
	while arr.size() > maximum:
		var last = arr.pop_back()
		if last:
			last.queue_free()
	for i in range(arr.size()):
		var heart = arr[i]
		if heart:
			if i < current:
				heart.texture = TextureManager.get_texture("heart_full")
			else:
				heart.texture = TextureManager.get_texture("heart_empty")


func update_combo(count: int, mult: float) -> void:
	if host.combo_label == null:
		return
	if count < 2:
		host.combo_label.visible = false
		return
	host.combo_label.text = Loc.fmt("COMBO x%d  (%.2fx Punkte)", [count, mult])
	host.combo_label.set_meta("loc_fmt", true)
	host.combo_label.visible = true
	host.combo_label.scale = Vector2(1.2, 1.2)
	var tw = host.combo_label.create_tween()
	tw.tween_property(host.combo_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func update_score(new_score: int) -> void:
	if host.score_label:
		host.score_label.text = "Score: %d" % new_score


func update_wave_label(w: int, coins_v: int, shop: bool, t: float, remaining: int = 0, level_now: int = 0, level_goal: int = 0) -> void:
	var show_coin := t >= 0.0
	if host.coin_panel:
		host.coin_panel.visible = show_coin
	if host.coin_label:
		host.coin_label.text = str(coins_v)
	if host.wave_label == null:
		return
	if not show_coin:
		host.wave_label.visible = false
		return
	host.wave_label.visible = true
	# Runde 55: Kein Level-Ziel mehr in der Anzeige - der Wellen-Fortschritt
	# haengt nur noch an den Monstern der Welle, nicht am Level.
	if shop:
		host.wave_label.text = Loc.fmt("WELLE %d GESCHAFFT   ·   Shop %ds", [w, int(ceil(maxf(0.0, t)))])
		host.wave_label.set_meta("loc_fmt", true)
	else:
		host.wave_label.text = Loc.fmt("WELLE %d   ·   %d Monster uebrig", [w, maxi(0, remaining)])
		host.wave_label.set_meta("loc_fmt", true)


func set_fps_label(on: bool) -> void:
	host.debug_fps = on
	if host.fps_label:
		host.fps_label.visible = on
	host.refresh_settings_ui()
	if host.fps_btn:
		host.fps_btn.text = "FPS-ANZEIGE: " + ("AN" if on else "AUS")


func update_target_arrow(show_it: bool, dir: Vector2) -> void:
	# Runde 31: kleiner Pfeil in Richtung des letzten Wellen-Monsters
	if host.target_arrow == null:
		if host.hud == null:
			return
		host.target_arrow = TextureRect.new()
		host.target_arrow.name = "TargetArrow"
		host.target_arrow.texture = TextureManager.get_texture("arrow_marker")
		host.target_arrow.custom_minimum_size = Vector2(60, 60)
		host.target_arrow.size = Vector2(60, 60)
		host.target_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		host.target_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		host.target_arrow.pivot_offset = Vector2(30, 30)
		host.target_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.target_arrow.process_mode = Node.PROCESS_MODE_ALWAYS
		host.target_arrow.z_index = 60
		host.hud.add_child(host.target_arrow)
	if not show_it:
		host.target_arrow.visible = false
		return
	host.target_arrow.visible = true
	var c: Vector2 = host.hud.size * 0.5
	var r: float = minf(host.hud.size.x, host.hud.size.y) * 0.17
	host.target_arrow.position = c + dir.normalized() * r
	host.target_arrow.rotation = dir.angle() + PI * 0.5   # Textur zeigt nach oben


func update_boss_hp(cur: int, mx: int) -> void:
	if host.boss_bar == null:
		return
	host.boss_bar.visible = true
	host.boss_bar.max_value = mx
	host.boss_bar.value = cur
	if cur <= 0:
		var tw = host.boss_bar.create_tween()
		tw.tween_interval(0.8)
		tw.tween_property(host.boss_bar, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func(): host.boss_bar.visible = false; host.boss_bar.modulate.a = 1.0)
	elif host.boss_bar.modulate.a < 1.0:
		host.boss_bar.modulate.a = 1.0
		host.boss_bar.visible = true


func update_xp(new_level: int, cur: int, needed: int) -> void:
	if host.lvl_label:
		host.lvl_label.text = "LVL %d" % new_level
	if host.xp_bar:
		host.xp_bar.max_value = needed
		host.xp_bar.value = cur

# Konstanten aus der Fassade (ui_manager.gd)
const COMIC_YELLOW := Color(0.99, 0.80, 0.22)


# ------------------------------------------------------------
# v1.40: Icons + Vorschau fuer den RUNDEN-Modus
# ------------------------------------------------------------

func _wave_icon_button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 66)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(0.06, 0.06, 0.09))
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = Color(0.05, 0.05, 0.09)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_offset = Vector2(4, 4)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = col.lightened(0.22)
	var sbp: StyleBoxFlat = sb.duplicate()
	sbp.bg_color = col.darkened(0.18)
	sbp.shadow_offset = Vector2(2, 2)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func set_wave_icons(shop: bool, next: bool) -> void:
	if host.wave_icon_box == null:
		return
	host.wave_icon_box.visible = shop or next
	if host.wave_shop_btn != null:
		host.wave_shop_btn.visible = shop
	if host.wave_next_btn != null:
		host.wave_next_btn.visible = next
	if shop or next:
		var rm = host.game_manager.get("rounds_mode") if host.game_manager != null else null
		if rm != null:
			var nr: int = int(rm.get("round_no")) + 1
			var rdiff: String = str(rm.get("difficulty"))
			host.wave_preview.text = Loc.fmt("NÄCHSTE RUNDE %d: %s", [nr, Rounds.preview_with_boss(nr, rdiff)])
			host.wave_preview.set_meta("loc_fmt", true)
			# v1.42 (P6.7): Anzahl der gewaehlten Schwierigkeit im HUD
			print("[HUD][VORSCHAU] runde=%d anzahl=%d modus=%s" % [
				nr, Rounds.monster_count_for(nr, rdiff), rdiff])
			print("[WAVE][VORSCHAU] runde=%d typen=%s boss=%s" % [
				nr, Rounds.preview_with_boss(nr, rdiff), str(Rounds.boss_count(nr) > 0)])
			print("[WAVE][UI] icons=%d shop=%s next=%s" % [
				(1 if shop else 0) + (1 if next else 0), str(shop), str(next)])
	else:
		print("[WAVE][UI] icons=0")


func set_rounds_preview(txt: String) -> void:
	if host.wave_preview != null:
		host.wave_preview.text = txt
