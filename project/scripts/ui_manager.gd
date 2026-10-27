# UIManager.gd - Verwaltet HUD, StartScreen und DeathScreen inkl. Touch-Controls
extends Node

signal upgrade_chosen(id: String)

var game_manager: Node = null
var player: Node = null
var player2: Node = null

# UI-Elemente
var hud: Control = null
var start_screen: Control = null
var death_screen: Control = null
var heart_labels: Array[TextureRect] = []
var heart_labels2: Array[TextureRect] = []
var score_label: Label = null
var combo_label: Label = null
var health_bar = null
var health_bar2 = null
var lvl_label: Label = null
var xp_bar: ProgressBar = null
var boss_bar: ProgressBar = null
var upgrade_overlay: Control = null

# Touch-Steuerung
var move_stick = null
var move_stick2 = null
var touch_layer = null
var shoot_btn = null
var shoot_btn2 = null

var duo_on: bool = false

# LAN-Partner-Anzeige (blass, oben rechts)
var partner_box: VBoxContainer = null
var partner_tag: Label = null
var partner_hearts_row: HBoxContainer = null
var partner_hearts: Array[TextureRect] = []
var partner_weapon_icon: TextureRect = null
var partner_weapon_label: Label = null

# Waffen-HUD (G2) + Buff-Anzeige
var weapon_hud: VBoxContainer = null
var weapon_row: GridContainer = null
var weapon_buttons: Array = []
# Runde 49: Reload-Indikator
var reload_row: HBoxContainer = null
var reload_bar: ProgressBar = null
var reload_label: Label = null
# Runde 49: Waffen-Stat-Seite
var stats_page: Control = null
var stat_cards: Array = []
var buff_label: Label = null
var banner_label: Label = null
var fps_label: Label = null
var debug_fps: bool = false
var _fps_timer: float = 0.0

# LAN-Auswahlfenster
var lan_panel: ColorRect = null
var lan_status: Label = null
var lan_list: VBoxContainer = null
var lan_ip_edit: LineEdit = null
var lan_refresh_t: float = 0.0

var mode_btn = null
var char_page: Control = null
var settings_page: Control = null
var char_preview: TextureRect = null
var char_name_chip: Label = null
var char_unlock_label: Label = null
var quality_btn = null
var fps_btn = null
var sound_btn = null
var sfx_btn = null
var quality_info_label: Label = null
var quality_buttons: Array = []
var main_hero_img: TextureRect = null
var main_name_chip: Label = null
var name_edit = null
var color_buttons: Array = []
var skin_buttons: Array = []          # Runde 43: Skin-Kacheln im Charakter-Fenster
var confirm_page: Control = null      # Runde 43: Run-Uebersicht
var load_time: float = 0.0            # Runde 45: Ladebildschirm
var load_next: float = 0.0
const LOAD_MIN_TIME: float = 3.2
var confirm_box: VBoxContainer = null
var hat_buttons: Array = []
var shop_coin_label: Label = null
var shop_wave_label: Label = null
var shop_hint: Label = null
var shop_continue_row: HBoxContainer = null
var partner_list: VBoxContainer = null
var coin_panel: PanelContainer = null
var coin_icon: TextureRect = null
var coin_label: Label = null
var switch_label: Label = null
var switch_bar: ProgressBar = null
var _gold_tween: Tween = null
var partner_slots: Dictionary = {}
var partner_rows: Dictionary = {}
var lobby_panel: Control = null
var lobby_title: Label = null
var lobby_info: Label = null
var lobby_rows_box: VBoxContainer = null
var lobby_ready_btn = null
var lobby_start_btn = null
var lobby_host: bool = false
var lobby_my_ready: bool = false
var lan_count_btns: Array = []
var main_score_chip: PanelContainer = null
var main_gold_chip: PanelContainer = null
var shop_page: Control = null
var shop_gold_chip: PanelContainer = null
var chest_cards: Array = []
var start_box: VBoxContainer = null     # Runde 40: Inhalts-Box der Startseite
var boost_cards: Array = []
var chest_overlay: Control = null
var chest_result_icon: TextureRect = null
var chest_result_label: Label = null
var chest_item_box: VBoxContainer = null
var chest_item_rows: Array = []
var chest_confirm_btn: Button = null
var chest_ok_btn: Button = null
var chest_confirm_hint: Label = null
var chest_pending_tier: String = ""
var chest_box_icon: TextureRect = null
var maps_page: Control = null
var maps_gold_chip: PanelContainer = null
var maps_cards: Array = []
var maps_active_label: Label = null
var lan_player_count: int = 2
var wave_label: Label = null
var shop_panel: Control = null
var shop_list: GridContainer = null
var shop_scroll: ScrollContainer = null
var _weapon_hud_sig: String = ""
var target_arrow: TextureRect = null
var collection_page: Control = null
var ping_btn: Button = null
var shop_title: Label = null

const SHOP_ICONS := {
	"heal": "heart_full",
	"shield": "icon_shield",
	"weapon": "weapon_shotgun",
	"maxhp": "rarity_epic",
	"speed": "powerup_rapid",
	"damage": "projectile"
}
const UPGRADE_ICONS := {
	"power": "upg_power",
	"turbo": "upg_turbo",
	"speed": "upg_speed",
	"vitality": "upg_vitality",
	"guardian": "upg_guardian",
	"vampire": "upg_vampire"
}
const UPGRADE_COLORS := {
	"power": Color(0.85, 0.36, 0.26),
	"turbo": Color(0.28, 0.58, 0.92),
	"speed": Color(0.26, 0.78, 0.52),
	"vitality": Color(0.92, 0.34, 0.52),
	"guardian": Color(0.32, 0.68, 0.96),
	"vampire": Color(0.66, 0.30, 0.88)
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # Pausen-Menue muss auch pausiert klickbar sein
	_create_hud()
	_create_start_screen()
	_create_death_screen()
	show_start_screen()
	# Runde 45: Ladebildschirm einblenden (Helden + Sprueche)
	_build_load_screen()
	if load_screen != null:
		load_screen.visible = true
		load_screen.modulate.a = 1.0
		load_time = 0.0
		load_next = 0.35
	NetManager.hosts_changed.connect(_refresh_lan_list)
	NetManager.conn_failed.connect(_on_lan_failed)
	NetManager.run_start_signal.connect(_on_lan_run_started)
	NetManager.partner_left.connect(_on_lan_partner_left)

func register_references(gm: Node, p: Node) -> void:
	game_manager = gm
	player = p

func register_references2(p: Node) -> void:
	player2 = p

func set_duo(on: bool) -> void:
	duo_on = on
	if move_stick2:
		move_stick2.visible = on
	if shoot_btn2:
		shoot_btn2.visible = on
	if health_bar2:
		health_bar2.visible = on
	var p2tag = hud.get_node_or_null("P2Tag")
	if p2tag:
		p2tag.visible = on
	# Layout: Solo = Joystick links + Schuss-Button rechts unten.
	#        Duo  = beide Paare an ihrer Seite (P1 links, P2 rechts).
	if move_stick:
		move_stick.position = Vector2(96, 566)
		move_stick.force_reset()
	if move_stick2:
		move_stick2.position = Vector2(1384, 566)
		move_stick2.force_reset()
	if shoot_btn:
		if on:
			shoot_btn.position = Vector2(330, 880)
			shoot_btn.scale = Vector2(2.0, 2.0)
		else:
			shoot_btn.position = Vector2(1580, 790)
			shoot_btn.scale = Vector2(2.4, 2.4)

func _hud_panel_sb(alpha: float = 0.55, radius: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, alpha)
	sb.border_color = Color(0.58, 0.70, 0.84, 0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb


# Runde 61: Einheitlicher Comic-Stil wie auf der Startseite (dunkles Papier,
# dicke gelbe Kante, harter Versatzschatten). Wird fuer HUD, Pause und
# Uebersichten benutzt, damit alles aus einem Guss wirkt.
const COMIC_YELLOW := Color(0.99, 0.80, 0.22)
const COMIC_PAPER := Color(0.09, 0.12, 0.21)


func _hud_comic_sb(alpha: float = 0.94, accent: Color = COMIC_YELLOW, radius: int = 14, pad: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COMIC_PAPER.r, COMIC_PAPER.g, COMIC_PAPER.b, alpha)
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = float(pad)
	sb.content_margin_right = float(pad)
	sb.content_margin_top = float(pad) * 0.7
	sb.content_margin_bottom = float(pad) * 0.7
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(4, 5)
	return sb

func _create_hud():
	hud = Control.new()
	hud.name = "HUD"
	# Bugfix Runde 15: ohne Anker war die Groesse 0x0 -> alles mit PRESET_CENTER_TOP
	# oder anchor 0.5 (Banner, Boss-Leiste) lag halb ausserhalb des Bildschirms.
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE   # Joystick/Buttons nicht blockieren
	add_child(hud)

	# ---------------- Oben links: Leben + XP ----------------
	var left = VBoxContainer.new()
	left.name = "LeftPanel"
	left.position = Vector2(18, 14)
	left.add_theme_constant_override("separation", 8)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(left)

	var life_panel = PanelContainer.new()
	life_panel.name = "LifePanel"
	life_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_panel.add_theme_stylebox_override("panel", _hud_comic_sb(0.92))
	left.add_child(life_panel)

	var life_box = VBoxContainer.new()
	life_box.add_theme_constant_override("separation", 7)
	life_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_panel.add_child(life_box)

	health_bar = HBoxContainer.new()
	health_bar.name = "HealthBar"
	health_bar.add_theme_constant_override("separation", 4)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_box.add_child(health_bar)
	heart_labels.clear()
	for i in range(5):
		var heart = TextureRect.new()
		heart.name = "Heart%d" % i
		heart.texture = TextureManager.get_texture("heart_full")
		heart.custom_minimum_size = Vector2(42, 42)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		health_bar.add_child(heart)
		heart_labels.append(heart)

	# P2-Herzen (Duo) — vorhanden, aktuell ungenutzt
	health_bar2 = HBoxContainer.new()
	health_bar2.name = "HealthBar2"
	health_bar2.visible = false
	life_box.add_child(health_bar2)
	heart_labels2.clear()
	for i in range(5):
		var heart2 = TextureRect.new()
		heart2.name = "Heart2_%d" % i
		heart2.texture = TextureManager.get_texture("heart_full")
		heart2.custom_minimum_size = Vector2(36, 36)
		heart2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		health_bar2.add_child(heart2)
		heart_labels2.append(heart2)

	var xp_row = HBoxContainer.new()
	xp_row.name = "XPRow"
	xp_row.add_theme_constant_override("separation", 10)
	xp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	life_box.add_child(xp_row)

	lvl_label = Label.new()
	lvl_label.name = "LvlLabel"
	lvl_label.text = "LVL 1"
	lvl_label.add_theme_font_size_override("font_size", 22)
	lvl_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	xp_row.add_child(lvl_label)

	xp_bar = ProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.custom_minimum_size = Vector2(290, 18)
	xp_bar.max_value = 25
	xp_bar.value = 0
	xp_bar.show_percentage = false
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.10, 0.10, 0.12, 0.8)
	sb_bg.set_corner_radius_all(7)
	xp_bar.add_theme_stylebox_override("background", sb_bg)
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.30, 0.85, 1.0)
	sb_fg.set_corner_radius_all(7)
	xp_bar.add_theme_stylebox_override("fill", sb_fg)
	xp_row.add_child(xp_bar)

	# ---------------- Oben Mitte: Score + Combo ----------------
	var center = VBoxContainer.new()
	center.name = "CenterPanel"
	center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center.offset_left = -320.0
	center.offset_right = 320.0
	center.offset_top = 10.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(center)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "0"
	score_label.label_settings = _make_label_settings(48, Color(1, 1, 1), 10)
	score_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(score_label)

	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = ""
	combo_label.label_settings = _make_label_settings(28, Color(1.0, 0.62, 0.12), 8)
	combo_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(combo_label)

	# Boss-HP (mittig unter dem Score)
	boss_bar = ProgressBar.new()
	boss_bar.name = "BossBar"
	boss_bar.anchor_left = 0.18
	boss_bar.anchor_right = 0.82
	boss_bar.anchor_top = 0.135
	boss_bar.anchor_bottom = 0.135
	boss_bar.offset_left = 0.0
	boss_bar.offset_right = 0.0
	boss_bar.offset_top = 0.0
	boss_bar.offset_bottom = 26.0
	boss_bar.max_value = 40
	boss_bar.show_percentage = false
	boss_bar.visible = false
	var b_bg = StyleBoxFlat.new()
	b_bg.bg_color = Color(0.10, 0.05, 0.05, 0.85)
	b_bg.border_color = Color(0.08, 0.08, 0.10)
	b_bg.set_border_width_all(3)
	b_bg.set_corner_radius_all(8)
	boss_bar.add_theme_stylebox_override("background", b_bg)
	var b_fg = StyleBoxFlat.new()
	b_fg.bg_color = Color(0.85, 0.15, 0.15)
	b_fg.set_corner_radius_all(6)
	boss_bar.add_theme_stylebox_override("fill", b_fg)
	hud.add_child(boss_bar)

	# ---------------- Oben rechts: Waffen + Muenzen + Welle ----------------
	var right = VBoxContainer.new()
	right.name = "RightPanel"
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -436.0
	right.offset_right = -18.0
	right.offset_top = 14.0
	right.add_theme_constant_override("separation", 8)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(right)

	var wp = PanelContainer.new()
	wp.name = "WeaponPanel"
	wp.add_theme_stylebox_override("panel", _hud_comic_sb(0.92))
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

	weapon_row = GridContainer.new()
	weapon_row.name = "WeaponRow"
	weapon_row.columns = 3
	weapon_row.add_theme_constant_override("h_separation", 8)
	weapon_row.add_theme_constant_override("v_separation", 8)
	wbox.add_child(weapon_row)

	# Runde 49: Reload-Indikator - Balken + Munitionstext
	reload_row = HBoxContainer.new()
	reload_row.name = "ReloadRow"
	reload_row.add_theme_constant_override("separation", 8)
	wbox.add_child(reload_row)

	# Runde 49: Button fuer die Waffen-Stats-Seite
	var stats_btn := _make_pixel_button("WAFFEN-STATS", Color(0.26, 0.34, 0.52), 18)
	stats_btn.custom_minimum_size = Vector2(150, 30)
	stats_btn.pressed.connect(_open_stats_page)
	wbox.add_child(stats_btn)

	reload_bar = ProgressBar.new()
	reload_bar.name = "ReloadBar"
	reload_bar.custom_minimum_size = Vector2(150, 18)
	reload_bar.show_percentage = false
	reload_bar.max_value = 100.0
	reload_bar.value = 0.0
	reload_bar.visible = false
	var rb_bg := StyleBoxFlat.new()
	rb_bg.bg_color = Color(0.10, 0.11, 0.14, 0.9)
	rb_bg.set_corner_radius_all(0)
	reload_bar.add_theme_stylebox_override("background", rb_bg)
	var rb_fg := StyleBoxFlat.new()
	rb_fg.bg_color = Color(0.98, 0.72, 0.20)
	rb_fg.set_corner_radius_all(0)
	reload_bar.add_theme_stylebox_override("fill", rb_fg)
	reload_row.add_child(reload_bar)

	reload_label = Label.new()
	reload_label.name = "ReloadLabel"
	reload_label.label_settings = _make_label_settings(20, Color(1.0, 0.85, 0.35), 4)
	reload_label.visible = false
	reload_row.add_child(reload_label)
	weapon_hud = wbox

	# Utility-Leiste (Runde 15): Trank + Bombe, antippbar oder Q/E
	var urow = HBoxContainer.new()
	urow.name = "UtilityRow"
	urow.add_theme_constant_override("separation", 6)
	wbox.add_child(urow)
	util_buttons.clear()
	for kind in ["potion", "bomb"]:
		var ub := Button.new()
		ub.custom_minimum_size = Vector2(136, 64)
		ub.focus_mode = Control.FOCUS_NONE
		ub.text = "TRANK x0"
		ub.add_theme_font_size_override("font_size", 20)
		ub.add_theme_stylebox_override("normal", _hud_comic_sb(0.88, Color(0.42, 0.48, 0.60), 8, 8))
		ub.add_theme_stylebox_override("hover", _hud_comic_sb(0.95, COMIC_YELLOW, 8, 8))
		ub.add_theme_stylebox_override("pressed", _hud_comic_sb(1.0, COMIC_YELLOW, 8, 8))
		ub.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		ub.pressed.connect(_on_util_pressed.bind(str(kind)))
		urow.add_child(ub)
		util_buttons[str(kind)] = ub

	# Muenz-Chip (nur Wellen-Modus)
	coin_panel = PanelContainer.new()
	coin_panel.name = "CoinPanel"
	coin_panel.add_theme_stylebox_override("panel", _hud_comic_sb(0.90))
	coin_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	coin_panel.visible = false
	right.add_child(coin_panel)

	var coin_row = HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 8)
	coin_panel.add_child(coin_row)

	coin_icon = TextureRect.new()
	coin_icon.name = "CoinIcon"
	coin_icon.texture = TextureManager.get_texture("icon_coin")
	coin_icon.custom_minimum_size = Vector2(34, 34)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(coin_icon)

	coin_label = Label.new()
	coin_label.name = "CoinLabel"
	coin_label.text = "0"
	coin_label.add_theme_font_size_override("font_size", 30)
	coin_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	coin_row.add_child(coin_label)

	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.add_theme_font_size_override("font_size", 22)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	wave_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	wave_label.custom_minimum_size = Vector2(418, 0)
	wave_label.visible = false
	right.add_child(wave_label)

	buff_label = Label.new()
	buff_label.name = "BuffLabel"
	buff_label.text = ""
	buff_label.add_theme_font_size_override("font_size", 22)
	buff_label.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	buff_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	buff_label.custom_minimum_size = Vector2(418, 0)
	right.add_child(buff_label)

	switch_label = Label.new()
	switch_label.name = "SwitchLabel"
	switch_label.text = ""
	switch_label.add_theme_font_size_override("font_size", 20)
	switch_label.add_theme_color_override("font_color", Color(0.60, 1.0, 0.82))
	switch_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	switch_label.custom_minimum_size = Vector2(418, 0)
	right.add_child(switch_label)

	switch_bar = ProgressBar.new()
	switch_bar.custom_minimum_size = Vector2(418, 12)
	switch_bar.show_percentage = false
	switch_bar.max_value = 100
	switch_bar.value = 0
	switch_bar.visible = false
	var swb = StyleBoxFlat.new()
	swb.bg_color = Color(0.10, 0.11, 0.14, 0.85)
	swb.set_corner_radius_all(6)
	switch_bar.add_theme_stylebox_override("background", swb)
	var swf = StyleBoxFlat.new()
	swf.bg_color = Color(0.35, 0.90, 0.70)
	swf.set_corner_radius_all(6)
	switch_bar.add_theme_stylebox_override("fill", swf)
	right.add_child(switch_bar)

	# ---------------- Partner-Liste (links unter dem Leben-Panel) ----------------
	partner_list = VBoxContainer.new()
	partner_list.name = "PartnerList"
	partner_list.position = Vector2(18, 186)
	partner_list.add_theme_constant_override("separation", 10)
	partner_list.modulate = Color(1, 1, 1, 0.78)
	partner_list.visible = false
	hud.add_child(partner_list)

	# Alt-Box (WLAN-Phase-1) bleibt vorhanden, aber ungenutzt
	partner_box = VBoxContainer.new()
	partner_box.name = "PartnerBox"
	partner_box.visible = false
	partner_box.add_child(Label.new())
	partner_tag = Label.new()
	partner_tag.text = "PARTNER (WLAN)"
	partner_box.add_child(partner_tag)
	partner_hearts_row = HBoxContainer.new()
	partner_box.add_child(partner_hearts_row)
	partner_weapon_icon = TextureRect.new()
	partner_weapon_label = Label.new()
	partner_box.add_child(partner_weapon_icon)
	partner_box.add_child(partner_weapon_label)
	hud.add_child(partner_box)

	var p2tag = Label.new()
	p2tag.name = "P2Tag"
	p2tag.text = "P2"
	p2tag.visible = false
	hud.add_child(p2tag)

	# Pause-Knopf (Runde 15)
	var pause_btn := Button.new()
	pause_btn.name = "PauseButton"
	pause_btn.text = "II"
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.offset_left = -84.0
	pause_btn.offset_right = -20.0
	pause_btn.offset_top = 14.0
	pause_btn.offset_bottom = 74.0
	pause_btn.add_theme_font_size_override("font_size", 30)
	pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn.pressed.connect(func(): game_manager.call("toggle_pause"))
	hud.add_child(pause_btn)

	# ---------------- PING (Mehrspieler) ----------------
	ping_btn = Button.new()
	ping_btn.name = "PingButton"
	ping_btn.text = "PING"
	ping_btn.focus_mode = Control.FOCUS_NONE
	ping_btn.anchor_left = 1.0
	ping_btn.anchor_right = 1.0
	ping_btn.offset_left = -152.0
	ping_btn.offset_right = -92.0
	ping_btn.offset_top = 14.0
	ping_btn.offset_bottom = 74.0
	ping_btn.add_theme_font_size_override("font_size", 20)
	ping_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	ping_btn.visible = false
	ping_btn.pressed.connect(_on_ping_pressed)
	hud.add_child(ping_btn)

	# ---------------- Banner ----------------
	banner_label = Label.new()
	banner_label.name = "BannerLabel"
	banner_label.text = ""
	banner_label.anchor_left = 0.0
	banner_label.anchor_right = 1.0
	banner_label.anchor_top = 0.28
	banner_label.anchor_bottom = 0.28
	banner_label.offset_left = 0.0
	banner_label.offset_right = 0.0
	banner_label.offset_top = 0.0
	banner_label.offset_bottom = 110.0
	banner_label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	banner_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 84)
	banner_label.add_theme_color_override("font_color", Color(1, 1, 1))
	banner_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	banner_label.add_theme_constant_override("outline_size", 14)
	banner_label.modulate.a = 0.0
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(banner_label)

	# ---------------- FPS/Debug ----------------
	fps_label = Label.new()
	fps_label.name = "FpsLabel"
	fps_label.position = Vector2(14, 1010)
	fps_label.custom_minimum_size = Vector2(1100, 34)
	fps_label.size = Vector2(1100, 34)
	fps_label.add_theme_font_size_override("font_size", 22)
	fps_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.6))
	fps_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	fps_label.add_theme_constant_override("outline_size", 8)
	fps_label.visible = false
	hud.add_child(fps_label)

	# Touch-Controls
	_create_touch_controls()

	hud.hide()

func _create_touch_controls():
	# Control (NICHT CanvasLayer!) -> wird mit dem HUD ausgeblendet,
	# damit Joysticks auf Start-/Todes-Screen unsichtbar sind (V3)
	touch_layer = Control.new()
	touch_layer.name = "TouchLayer"
	touch_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(touch_layer)

	var joystick_script = load("res://scripts/touch_joystick.gd")

	# Bewegungs-Joystick P1 links: 440px Hitbox, Visual 300px (etwas mehr zur Mitte)
	move_stick = joystick_script.new()
	move_stick.name = "MoveStick"
	move_stick.position = Vector2(96, 566)
	move_stick.size = Vector2(440, 440)
	move_stick.vis_scale = 0.68
	move_stick.direction_changed.connect(_on_move_stick)
	touch_layer.add_child(move_stick)

	# Schuss-Button P1 (Startposition = Solo: rechts unten)
	shoot_btn = TouchScreenButton.new()
	shoot_btn.name = "ShootButton"
	shoot_btn.position = Vector2(1580, 790)
	shoot_btn.scale = Vector2(2.4, 2.4)
	shoot_btn.texture_normal = TextureManager.get_texture("btn_shoot")
	shoot_btn.connect("pressed", Callable(self, "_on_shoot_down"))
	shoot_btn.connect("released", Callable(self, "_on_shoot_up"))
	touch_layer.add_child(shoot_btn)

	# --- P2 (Duo): Feuer links, Joystick ganz rechts ---
	move_stick2 = joystick_script.new()
	move_stick2.name = "MoveStick2"
	move_stick2.position = Vector2(1460, 620)
	move_stick2.size = Vector2(440, 440)
	move_stick2.vis_scale = 0.68
	move_stick2.direction_changed.connect(_on_move_stick2)
	move_stick2.visible = false
	touch_layer.add_child(move_stick2)

	shoot_btn2 = TouchScreenButton.new()
	shoot_btn2.name = "ShootButton2"
	shoot_btn2.position = Vector2(1290, 880)
	shoot_btn2.scale = Vector2(2.0, 2.0)
	shoot_btn2.texture_normal = TextureManager.get_texture("btn_shoot")
	shoot_btn2.connect("pressed", Callable(self, "_on_shoot_down2"))
	shoot_btn2.connect("released", Callable(self, "_on_shoot_up2"))
	shoot_btn2.visible = false
	touch_layer.add_child(shoot_btn2)

func _on_move_stick(dir: Vector2) -> void:
	if player:
		player.set_input_direction(dir)

func _on_move_stick2(dir: Vector2) -> void:
	if player2:
		player2.set_input_direction(dir)

func _on_shoot_down() -> void:
	if player:
		player.set_shoot_held(true)

func _on_shoot_up() -> void:
	if player:
		player.set_shoot_held(false)

func _on_shoot_down2() -> void:
	if player2:
		player2.set_shoot_held(true)

func _on_shoot_up2() -> void:
	if player2:
		player2.set_shoot_held(false)

# ============================================================
# LAN-AUSWAHLFENSTER (Host / Beitreten)
# ============================================================
func _open_lan_panel() -> void:
	if lan_panel == null:
		_build_lan_panel()
	lan_panel.visible = true
	if lan_status:
		lan_status.text = "Ein Geraet hosten, das andere tritt bei (beide im selben WLAN)"
	NetManager.start_scan()
	_refresh_lan_list()

func _build_lan_panel() -> void:
	lan_panel = ColorRect.new()
	lan_panel.name = "LanPanel"
	lan_panel.color = Color(0.03, 0.04, 0.07, 0.97)
	lan_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	lan_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(lan_panel)

	# Runde 63: zentriert in einem Comic-Panel wie die Startseite.
	# Vorher sass der Inhalt fest auf (520, 60) mit 960 px Hoehe und ragte
	# auf 720p unten aus dem Bild.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	lan_panel.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud_comic_sb(0.97, COMIC_YELLOW, 8, 26))
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(780, 0)
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title = Label.new()
	title.text = "LAN · WLAN-MULTIPLAYER"
	title.label_settings = _make_label_settings(52, COMIC_YELLOW, 8)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub = Label.new()
	sub.text = "Gleiches WLAN noetig. Einer hostet — der andere tritt ueber die Liste bei."
	sub.label_settings = _make_label_settings(26, Color(0.88, 0.9, 0.88), 6)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var crow = HBoxContainer.new()
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	crow.add_theme_constant_override("separation", 16)
	box.add_child(crow)

	var cl = Label.new()
	cl.text = "SPIELER:"
	cl.label_settings = _make_label_settings(30, Color(1.0, 0.85, 0.35), 6)
	crow.add_child(cl)

	lan_count_btns.clear()
	for i in range(3):
		var n := i + 2
		var cb2 := _make_pixel_button("%d" % n, Color(0.26, 0.32, 0.44), 28)
		cb2.custom_minimum_size = Vector2(110, 68)
		cb2.pressed.connect(_on_lan_count_pressed.bind(n))
		crow.add_child(cb2)
		lan_count_btns.append(cb2)
	_refresh_lan_count_ui()

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	box.add_child(row)

	var host_btn = _make_pixel_button("HOSTEN", Color(0.2, 0.66, 0.42), 32)
	host_btn.custom_minimum_size = Vector2(300, 84)
	host_btn.pressed.connect(_on_lan_host_pressed)
	row.add_child(host_btn)

	var scan_btn = _make_pixel_button("NEU SCANNEN", Color(0.25, 0.45, 0.80), 30)
	scan_btn.custom_minimum_size = Vector2(300, 84)
	scan_btn.pressed.connect(_on_lan_scan_pressed)
	row.add_child(scan_btn)

	lan_status = Label.new()
	lan_status.text = ""
	lan_status.label_settings = _make_label_settings(26, Color(1.0, 0.85, 0.35), 6)
	lan_status.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lan_status)

	var list_title = Label.new()
	list_title.text = "Gefundene Spiele im WLAN:"
	list_title.label_settings = _make_label_settings(28, Color(1, 1, 1), 6)
	box.add_child(list_title)

	lan_list = VBoxContainer.new()
	lan_list.custom_minimum_size = Vector2(760, 190)
	lan_list.add_theme_constant_override("separation", 8)
	box.add_child(lan_list)

	var ip_title = Label.new()
	ip_title.text = "Oder IP direkt eingeben (falls Broadcast blockiert wird):"
	ip_title.label_settings = _make_label_settings(24, Color(0.85, 0.88, 0.85), 5)
	box.add_child(ip_title)

	var ip_row = HBoxContainer.new()
	ip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ip_row.add_theme_constant_override("separation", 20)
	box.add_child(ip_row)

	lan_ip_edit = LineEdit.new()
	lan_ip_edit.placeholder_text = "192.168.0.42"
	lan_ip_edit.custom_minimum_size = Vector2(420, 76)
	lan_ip_edit.add_theme_font_size_override("font_size", 32)
	ip_row.add_child(lan_ip_edit)

	var join_btn = _make_pixel_button("BEITRETEN", Color(0.92, 0.55, 0.14), 30)
	join_btn.custom_minimum_size = Vector2(260, 72)
	join_btn.pressed.connect(_on_lan_join_manual)
	ip_row.add_child(join_btn)

	var back_btn = _make_pixel_button("ZURUECK", Color(0.32, 0.35, 0.42), 26)
	back_btn.custom_minimum_size = Vector2(240, 64)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_lan_back_pressed)
	box.add_child(back_btn)

func _process(delta: float) -> void:
	# Runde 51: Verbindungsabbruch -> Countdown, dann Startseite
	if disconnect_left > 0.0:
		disconnect_left -= delta
		if disconnect_count != null:
			disconnect_count.text = "Rueckkehr zur Startseite in %d s" % maxi(0, int(ceil(disconnect_left)))
		if disconnect_left <= 0.0:
			_on_disconnect_back()
		return
	# Runde 45: Ladebildschirm-Logik
	_update_load_screen(delta)
	# Hostliste regelmaessig aktualisieren, solange das Fenster offen ist
	if lan_panel != null and lan_panel.visible:
		lan_refresh_t += delta
		if lan_refresh_t >= 0.7:
			lan_refresh_t = 0.0
			_refresh_lan_list()
	# FPS-/Debug-Anzeige
	if fps_label != null and fps_label.visible:
		_fps_timer += delta
		if _fps_timer >= 0.25:
			_fps_timer = 0.0
			var qname = "-"
			var q = 2
			if game_manager and game_manager.has_method("get_quality"):
				q = game_manager.get_quality()
				qname = str(game_manager.QUALITY_NAMES[q])
			var fx = "aus"
			if game_manager:
				var fxnode = game_manager.get_node_or_null("PostFX")
				if fxnode and fxnode.visible:
					fx = "an"
			fps_label.text = "FPS %d | Draw %d | Obj %d | Proz %.1fms | Phys %.1fms | Monster %d | Grafik %s | Shader %s" % [
				Engine.get_frames_per_second(),
				int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				get_tree().get_nodes_in_group("monsters").size(),
				qname, fx]

func _refresh_lan_list() -> void:
	if lan_list == null:
		return
	for c in lan_list.get_children():
		c.queue_free()
	var ips = NetManager.discovered.keys()
	if ips.is_empty():
		var l = Label.new()
		l.text = "— noch nichts gefunden (Host aktiv? gleiches WLAN?) —"
		l.label_settings = _make_label_settings(24, Color(0.7, 0.72, 0.7), 4)
		l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		lan_list.add_child(l)
		return
	for ip in ips:
		var name = str(NetManager.discovered[ip])
		var b = _make_pixel_button("%s   ·   %s" % [name, str(ip)], Color(0.22, 0.38, 0.62), 24)
		b.custom_minimum_size = Vector2(740, 62)
		b.pressed.connect(_on_lan_join_manual.bind(str(ip)))
		lan_list.add_child(b)

func _on_lan_host_pressed() -> void:
	if game_manager == null:
		return
	# Lobby (Runde 10): Host warten lassen, Mitspieler joinen, Host drueckt START
	game_manager.start_lan_host(lan_player_count)

func _on_lan_count_pressed(n: int) -> void:
	lan_player_count = clampi(n, 2, 4)
	_refresh_lan_count_ui()

func _refresh_lan_count_ui() -> void:
	for i in range(lan_count_btns.size()):
		var b = lan_count_btns[i]
		if b == null:
			continue
		var n := i + 2
		b.modulate = Color(1.45, 1.45, 1.35) if n == lan_player_count else Color(0.72, 0.74, 0.80)

func _on_lan_scan_pressed() -> void:
	var err: String = NetManager.start_scan()
	lan_status.text = err if err != "" else "Suche im WLAN ..."
	_refresh_lan_list()

func _on_lan_join_manual(ip: String = "") -> void:
	var addr := ip
	if addr == "" and lan_ip_edit != null:
		addr = lan_ip_edit.text
	if game_manager:
		game_manager.start_lan_join(addr)
		return
	var err: String = NetManager.join_game(addr)
	lan_status.text = err if err != "" else ("Verbinde mit %s ..." % addr.strip_edges())

func _on_lan_back_pressed() -> void:
	NetManager.leave()
	if lan_panel:
		lan_panel.visible = false

func _on_lan_failed(why: String) -> void:
	if lan_status:
		lan_status.text = why

func _on_lan_run_started() -> void:
	if lan_panel:
		lan_panel.visible = false
	if lobby_panel:
		lobby_panel.visible = false

func _on_lan_partner_left() -> void:
	clear_partner()

func _on_play_pressed2() -> void:
	pass

# ---------------- Partner-Anzeige (blasser Ton) ----------------
func update_partner(hp: int, mx: int, weapon_name: String, shield: int = 0, pname: String = "") -> void:
	# Alt-Aufruf: auf die neue Mitspieler-Liste (Slot 2) umleiten
	update_partner_slot(2, hp, mx, weapon_name, shield, pname)
	return
	if partner_box == null:
		return
	partner_box.visible = true
	while partner_hearts.size() < mx:
		var h = TextureRect.new()
		h.texture = TextureManager.get_texture("heart_full")
		h.custom_minimum_size = Vector2(24, 24)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		partner_hearts_row.add_child(h)
		partner_hearts.append(h)
	for i in range(partner_hearts.size()):
		partner_hearts[i].texture = TextureManager.get_texture("heart_full" if i < hp else "heart_empty")
	partner_weapon_icon.texture = TextureManager.get_texture("weapon_" + weapon_name)
	partner_weapon_label.text = weapon_name
	var tag := pname if pname != "" else "PARTNER (WLAN)"
	partner_tag.text = tag + ("  +%d Schild" % shield if shield > 0 else "")

func clear_partner() -> void:
	clear_partner_slots()
	if partner_box:
		partner_box.visible = false

# ============================================================
# WAFFEN-ANZEIGE (G2) — oben rechts, antippbar
# ============================================================
var util_buttons: Dictionary = {}

func _on_util_pressed(kind: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	if kind == "potion":
		player.call("use_potion")
	else:
		player.call("use_bomb")
	if player.has_method("weapon_count"):
		refresh_utility_hud(player.utilities, player.call("get_weapon_key"))

func refresh_utility_hud(utils: Dictionary = {}, weapon_key: String = "") -> void:
	for kind in util_buttons.keys():
		var b = util_buttons[kind]
		if not is_instance_valid(b):
			continue
		var n := int(utils.get(kind, 0))
		var nm := "TRANK (Q)" if str(kind) == "potion" else "BOMBE (E)"
		b.text = "%s x%d" % [nm, n]
		b.modulate = Color(1, 1, 1, 1) if n > 0 else Color(0.62, 0.62, 0.68, 0.85)

func update_reload_indicator(progress: float, text: String) -> void:
	# Runde 49: Balken + Text aktualisieren (0 = kein Nachladen)
	if reload_bar == null or reload_label == null:
		return
	if progress <= 0.0 and text == "":
		reload_bar.visible = false
		reload_label.visible = false
		return
	reload_bar.visible = true
	reload_bar.value = clampf(progress, 0.0, 1.0) * 100.0
	reload_label.visible = true
	reload_label.text = text


func refresh_weapon_hud(owned: Array, current_key: String) -> void:
	if weapon_row == null:
		return
	# Runde 33: vorher wurden die Buttons JEDES Mal neu gebaut (clear + queue_free).
	# Im MP ruft der Sync das 15x/s pro Spieler auf -> massenhaftes Node-Churn
	# (Hauptursache der schlechten Performance beim Nicht-Host).
	var sig := ""
	for k in owned:
		sig += str(k) + "|"
	sig += "#" + str(current_key)
	if sig == _weapon_hud_sig:
		return
	_weapon_hud_sig = sig
	for c in weapon_row.get_children():
		weapon_row.remove_child(c)
		c.queue_free()
	weapon_buttons.clear()
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
		b.add_theme_stylebox_override("normal", _hud_comic_sb(0.95 if is_cur else 0.80, frame, 10, 6))
		b.add_theme_stylebox_override("hover", _hud_comic_sb(0.98, COMIC_YELLOW.lightened(0.12), 10, 6))
		b.add_theme_stylebox_override("pressed", _hud_comic_sb(1.0, COMIC_YELLOW, 10, 6))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.modulate = Color(1, 1, 1, 1) if is_cur else Color(0.80, 0.82, 0.86, 0.92)
		b.pressed.connect(_on_weapon_button.bind(str(key)))
		weapon_row.add_child(b)
		weapon_buttons.append(b)

func _on_weapon_button(key: String) -> void:
	if player == null:
		return
	player.call("switch_weapon", key)
	refresh_weapon_hud(player.call("get_owned_weapons"), player.call("get_weapon_key"))

# ============================================================
# BUFF-ANZEIGE (Frost / Schnellfeuer)
# ============================================================
func update_switch_hint(txt: String, cur: int = -1, need: int = -1) -> void:
	if switch_label:
		switch_label.text = txt
	if switch_bar:
		if need > 0:
			switch_bar.visible = true
			switch_bar.max_value = need
			switch_bar.value = mini(cur, need)
		else:
			switch_bar.visible = false

func update_buffs(rapid: float, freeze: float, gold: float = 0.0) -> void:
	if buff_label == null:
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
	if buff_label.text != txt:
		buff_label.text = txt
	buff_label.visible = txt != ""

# ============================================================
# BANNER (Biom-Wechsel / Boss besiegt)
# ============================================================
func show_banner(text: String, color: Color = Color(1, 1, 1)) -> void:
	if banner_label == null:
		return
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	banner_label.add_theme_color_override("font_outline_color", Color(0.06, 0.06, 0.08))
	banner_label.add_theme_constant_override("outline_size", 14)
	banner_label.visible = true
	banner_label.modulate = Color(1, 1, 1, 1)
	banner_label.scale = Vector2(0.65, 0.65)
	var tw := create_tween()
	tw.tween_property(banner_label, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.15)
	tw.tween_property(banner_label, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func(): banner_label.visible = false)

func _make_label_settings(size: int, color: Color, outline: int) -> LabelSettings:
	var ls = LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = outline
	ls.outline_color = Color(0.05, 0.05, 0.1)
	ls.shadow_size = 8
	ls.shadow_color = Color(0, 0, 0, 0.4)
	ls.shadow_offset = Vector2(4, 4)
	return ls

func _make_stylebox(bg: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(0.05, 0.05, 0.1)
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 6)
	return sb

func _make_styled_button(text: String, bg: Color, font_size: int = 40) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 90)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_stylebox_override("normal", _make_stylebox(bg))
	btn.add_theme_stylebox_override("hover", _make_stylebox(bg.lightened(0.15)))
	btn.add_theme_stylebox_override("pressed", _make_stylebox(bg.darkened(0.2)))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn

# ============================================================
# Runde 40: COMIC-LOOK - Panels, Knöpfe, Chips, Zahnrad
# ============================================================

func _comic_panel_sb(fill: Color, border: Color = Color(0.06, 0.05, 0.10), bw: int = 7, pad: int = 14) -> StyleBoxFlat:
	# Runde 40: echtes Comic-Panel - dicke schwarze Kontur, kein Rundeglanz
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(5, 6)
	sb.content_margin_left = float(pad)
	sb.content_margin_right = float(pad)
	sb.content_margin_top = float(pad)
	sb.content_margin_bottom = float(pad)
	return sb

func _comic_button_sb(fill: Color, pressed: bool = false) -> StyleBoxFlat:
	# Runde 40: Comic-Knopf - schwarzer Rand, harter Versatz zum Rausruecken
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill.darkened(0.35) if pressed else fill
	sb.border_color = Color(0.06, 0.05, 0.10)
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2.ZERO
	return sb

func _make_comic_button(text: String, fill: Color, font_size: int = 40) -> Button:
	# Runde 40: Comic-Knopf mit schwarzer Kontur
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 90)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.92, 0.92))
	btn.add_theme_stylebox_override("normal", _comic_button_sb(fill))
	btn.add_theme_stylebox_override("hover", _comic_button_sb(fill.lightened(0.14)))
	btn.add_theme_stylebox_override("pressed", _comic_button_sb(fill, true))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn

func _make_burst_texture(size: int = 512) -> ImageTexture:
	# Runde 40: Comic-Strahlenburst als Hintergrund der Startseite
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size * 0.5, size * 0.5)
	var rays: int = 24
	for i in range(rays):
		var a0: float = TAU * float(i) / float(rays)
		var a1: float = a0 + TAU / float(rays) * 0.42
		var col := Color(1, 1, 1, 0.16 if i % 2 == 0 else 0.07)
		var pts := PackedVector2Array([c])
		var steps: int = 7
		for s in range(steps + 1):
			var a: float = lerp(a0, a1, float(s) / float(steps))
			pts.append(c + Vector2(cos(a), sin(a)) * size * 0.75)
		ImageUtils_fill_polygon(img, pts, col)
	return ImageTexture.create_from_image(img)

func ImageUtils_fill_polygon(img: Image, pts: PackedVector2Array, col: Color) -> void:
	# Runde 40: einfache Polygonfuellung (Scanline) fuer den Burst
	if pts.size() < 3:
		return
	var min_y: int = int(pts[0].y)
	var max_y: int = int(pts[0].y)
	for p in pts:
		min_y = mini(min_y, int(p.y))
		max_y = maxi(max_y, int(p.y))
	for y in range(maxi(0, min_y), mini(img.get_height(), max_y + 1)):
		var xs: Array = []
		for i in range(pts.size()):
			var p1: Vector2 = pts[i]
			var p2: Vector2 = pts[(i + 1) % pts.size()]
			if (p1.y <= float(y) and p2.y > float(y)) or (p2.y <= float(y) and p1.y > float(y)):
				var t: float = (float(y) - p1.y) / (p2.y - p1.y)
				xs.append(p1.x + t * (p2.x - p1.x))
		xs.sort()
		var k: int = 0
		while k + 1 < xs.size():
			var x0: int = int(xs[k])
			var x1: int = int(xs[k + 1])
			for x in range(maxi(0, x0), mini(img.get_width(), x1 + 1)):
				img.set_pixel(x, y, col)
			k += 2

func _make_halftone_texture(size: int = 64) -> ImageTexture:
	# Runde 40: Ben-Day-Punktraster (Comic-Halbschatten)
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for gy in range(0, size, 8):
		for gx in range(0, size, 8):
			var off: int = 4 if (gy / 8) % 2 == 0 else 0
			for dy in range(0, 4):
				for dx in range(0, 4):
					var d: float = Vector2(float(dx - 2), float(dy - 2)).length()
					if d < 2.2:
						img.set_pixel(gx + off + dx, gy + dy, Color(0, 0, 0, 0.20))
	return ImageTexture.create_from_image(img)

# ============================================================
# Runde 43: PIXEL-ART-KACHELN (Punkt 7)
# Echte Pixel-Fase: die Ecken werden in 2-Stufen abgeschrägt, damit die
# Kachel "rund" wirkt, aber KEINE weichen Rundungen bekommt.
# ============================================================

func _make_pixel_panel_sb(fill: Color, border: Color = Color(0.06, 0.05, 0.10), bw: int = 4, pad: int = 8) -> StyleBoxFlat:
	# Runde 43: Pixel-Kachel - harte Kanten, echter Pixel-Versatz unten
	# rechts (wie ein Sprite), helle Oberkante. Kein Rundeglanz.
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(0)
	sb.corner_detail = 1
	# Pixel-Schatten: 5 px nach unten rechts, schwarz
	sb.shadow_color = Color(0.02, 0.02, 0.05, 0.85)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(6, 6)
	sb.content_margin_left = float(pad)
	sb.content_margin_right = float(pad)
	sb.content_margin_top = float(pad)
	sb.content_margin_bottom = float(pad)
	return sb

func _make_pixel_button(text: String, fill: Color, font_size: int = 40) -> Button:
	# Runde 43: Pixel-Knopf - kein Rundeglanz, harter Versatz nach unten
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 90)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.92, 0.92))
	btn.add_theme_stylebox_override("normal", _make_pixel_panel_sb(fill, Color(0.06, 0.05, 0.10), 4, 10))
	btn.add_theme_stylebox_override("hover", _make_pixel_panel_sb(fill.lightened(0.14), Color(0.06, 0.05, 0.10), 4, 10))
	btn.add_theme_stylebox_override("pressed", _make_pixel_panel_sb(fill.darkened(0.22), Color(0.06, 0.05, 0.10), 4, 10))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn

# ---------------- Ladescreen (Runde 45) ----------------
var load_screen: Control = null
var load_actor: TextureRect = null
var load_quote: Label = null
var load_title: Label = null
var load_bar: ColorRect = null
var load_idx: int = 0
var load_tex: Array = []


# Runde 45: Sprueche fuer den Ladebildschirm
const LOAD_QUOTES := [
	"BEREIT FUER ACTION!",
	"LETZTER SCHUSS GEFAHR!",
	"DEINE WAFFEN SIND LADEN!",
	"MONSTER AUF DEM PLAN!",
	"DEIN HELD IST BEREIT!",
]


func _make_nav_tile(icon_key: String, text: String, fill: Color, cb: Callable) -> Control:
	# Runde 48: Kachel mit Icon + Text, die KLICKBAR ist.
	#
	# Warum nicht einfach Button+Icon: bei 196px Breite passten Icon
	# (96px) und Text nicht nebeneinander - Godot presste das Icon auf 0
	# und die Kachel sah leer aus.
	#
	# Aufbau: Control
	#   |- VBox (mouse_filter IGNORE): TextureRect(Icon) + Label(Text)
	#   |- Button (flat, leere Stylebox, full rect) - LETZTES Kind,
	#      also obenauf und faengt die Klicks.
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(196, 196)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- Rahmen (Farbe der Kachel) ---
	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 0.0
	frame.offset_right = 0.0
	frame.offset_top = 0.0
	frame.offset_bottom = 0.0
	frame.add_theme_stylebox_override("panel", _make_pixel_panel_sb(fill, Color(0.06, 0.05, 0.10), 5, 8))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(frame)

	# --- Icon + Text ---
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 8.0
	col.offset_right = -8.0
	col.offset_top = 10.0
	col.offset_bottom = -10.0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(col)

	var ic := TextureRect.new()
	ic.name = "NavIcon"
	# Runde 48: der Icon-Key braucht den "nav_"-Prefix - vorher wurde
	# "lan" gesucht statt "nav_lan" und das Icon blieb leer.
	var full_key: String = icon_key if icon_key.begins_with("nav_") else "nav_" + icon_key
	ic.texture = TextureManager.get_texture(full_key)
	ic.set_meta("icon_key", full_key)
	ic.custom_minimum_size = Vector2(0, 104)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(ic)

	var lbl := Label.new()
	lbl.text = text
	lbl.label_settings = _make_label_settings(20, Color(1, 1, 1), 6)
	lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(lbl)

	# --- Klick-Button (LETZTES Kind = liegt obenauf) ---
	var hit := Button.new()
	hit.flat = true
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.offset_left = 0.0
	hit.offset_right = 0.0
	hit.offset_top = 0.0
	hit.offset_bottom = 0.0
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hit.pressed.connect(cb)
	tile.add_child(hit)
	return tile


func _build_load_screen() -> void:
	# Runde 45: Ladeschildschirm ueber allem, mit Helden + Spruch
	if load_screen != null:
		return
	load_screen = Control.new()
	load_screen.name = "LoadScreen"
	load_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_screen.z_index = 100
	add_child(load_screen)

	# Hintergrund: dunkel + Burst
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.09)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_screen.add_child(bg)
	var burst := TextureRect.new()
	burst.texture = _make_burst_texture(512)
	burst.set_anchors_preset(Control.PRESET_FULL_RECT)
	burst.stretch_mode = TextureRect.STRETCH_SCALE
	burst.modulate = Color(1.0, 0.94, 0.66, 0.55)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_screen.add_child(burst)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_screen.add_child(col)

	load_title = Label.new()
	load_title.text = "COMIC SHOOTER"
	load_title.label_settings = _make_label_settings(96, Color(1.0, 0.86, 0.12), 14)
	load_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(load_title)

	# Der Held
	var actor_frame := PanelContainer.new()
	actor_frame.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.08, 0.08, 0.14, 0.9), Color(0.98, 0.80, 0.20), 6, 14))
	actor_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(actor_frame)
	load_actor = TextureRect.new()
	load_actor.custom_minimum_size = Vector2(220, 220)
	load_actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	load_actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	load_actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor_frame.add_child(load_actor)

	# Der Spruch in einer Sprechblase
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.96, 0.96, 0.99, 0.95), Color(0.06, 0.05, 0.10), 6, 22))
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(bubble)
	load_quote = Label.new()
	load_quote.text = ""
	load_quote.label_settings = _make_label_settings(30, Color(0.10, 0.09, 0.16), 0)
	load_quote.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	load_quote.custom_minimum_size = Vector2(760, 0)
	load_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(load_quote)

	# Ladebalken
	var bar_bg := PanelContainer.new()
	bar_bg.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.10, 0.10, 0.16, 0.9), Color(0.30, 0.34, 0.44), 4, 4))
	bar_bg.custom_minimum_size = Vector2(520, 34)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(bar_bg)
	load_bar = ColorRect.new()
	load_bar.color = Color(0.98, 0.80, 0.20)
	load_bar.custom_minimum_size = Vector2(0, 22)
	load_bar.size = Vector2(0, 22)
	bar_bg.add_child(load_bar)

	# Helden-Texturen sammeln (alle Skins + ein paar Farben)
	load_tex = []
	for i in range(TextureManager.RIG_NAMES.size()):
		var t = TextureManager.get_skin_texture(0, i)
		if t != null:
			load_tex.append(t)
	for i in range(TextureManager.HAT_NAMES.size()):
		var t2 = TextureManager.get_player_texture(3, i)
		if t2 != null:
			load_tex.append(t2)
	_next_load_actor()


func _next_load_actor() -> void:
	# Runde 45: naechster Held + passender Spruch
	if load_actor == null or load_tex.is_empty():
		return
	load_idx = (load_idx + 1) % load_tex.size()
	load_actor.texture = load_tex[load_idx]
	var qi: int = randi() % LOAD_QUOTES.size()
	load_quote.text = "\u201e" + str(LOAD_QUOTES[qi]) + "\u201c"
	# Weiches Einblenden
	load_actor.modulate.a = 0.0
	load_quote.modulate.a = 0.0
	var tw := load_actor.create_tween()
	tw.set_parallel(true)
	tw.tween_property(load_actor, "modulate:a", 1.0, 0.22)
	tw.tween_property(load_quote, "modulate:a", 1.0, 0.22)


func _update_load_screen(delta: float) -> void:
	# Runde 45: Ladebildschirm-Logik (Aufruf aus _process)
	if load_screen == null or not load_screen.visible:
		return
	load_time += delta
	# Balken waechst
	if load_bar != null:
		var w: float = minf(1.0, load_time / LOAD_MIN_TIME)
		load_bar.size.x = 520.0 * w
	# Alle 1.6 s ein neuer Held
	if load_time >= load_next:
		load_next += 1.6
		_next_load_actor()
	# Fertig -> ausblenden
	if load_time >= LOAD_MIN_TIME and load_screen.visible:
		_hide_load_screen()


func _hide_load_screen() -> void:
	if load_screen == null:
		return
	var tw := load_screen.create_tween()
	tw.tween_property(load_screen, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func():
		if load_screen != null:
			load_screen.visible = false)

func _make_panel_sb(alpha: float = 0.92, radius: int = 26) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.14, alpha)
	sb.border_color = Color(0.42, 0.56, 0.72, 0.9)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 46.0
	sb.content_margin_right = 46.0
	sb.content_margin_top = 26.0
	sb.content_margin_bottom = 26.0
	return sb

func _make_chip_sb(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(1, 1, 1, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 22.0
	sb.content_margin_right = 22.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb

func _make_chip(text: String, bg: Color, size: int = 30) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _make_chip_sb(bg))
	var l := Label.new()
	l.text = text
	l.label_settings = _make_label_settings(size, Color(1, 1, 1), 6)
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(l)
	chip.set_meta("label", l)
	return chip

func _make_page(title_text: String) -> Control:
	# Runde 45: zurueck zum einfachen Aufbau (wie vor der R44-Umbauten):
	# Dim + Panel + Box. Die Seite liegt im VOLLBILD, der Inhalt bekommt
	# Innenabstand. Kein Scroll, kein Scaling - das Layout verhaelt sich
	# wieder exakt wie vorher.
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	start_screen.add_child(page)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.05, 0.08, 0.94)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.05, 0.05, 0.10, 0.93), Color(0.98, 0.80, 0.20), 5, 30))
	page.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = title_text
	# Runde 40: Comic-Titel mit dicker Kontur
	title.label_settings = _make_label_settings(52, Color(1.0, 0.85, 0.15), 11)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	page.set_meta("box", box)
	return page


func _page_box(page: Control) -> VBoxContainer:
	return page.get_meta("box")

func _create_start_screen():
	start_screen = Control.new()
	start_screen.name = "StartScreen"
	start_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(start_screen)

	# Runde 40: Comic-Hintergrund - Farbverlauf + Strahlenburst + Halbton
	var grad := Gradient.new()
	grad.set_color(0, Color(0.16, 0.13, 0.30))
	grad.set_color(1, Color(0.10, 0.20, 0.30))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 8
	var bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = gt
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	start_screen.add_child(bg)

	# Runde 40: Strahlenburst (Comic-Sonnensstrahlen) hinter allem
	var burst := TextureRect.new()
	burst.name = "ComicBurst"
	burst.texture = _make_burst_texture(512)
	burst.set_anchors_preset(Control.PRESET_FULL_RECT)
	burst.stretch_mode = TextureRect.STRETCH_SCALE
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.modulate = Color(1.0, 0.95, 0.75, 0.85)
	start_screen.add_child(burst)
	var bspin := burst.create_tween()
	bspin.set_loops()
	bspin.tween_property(burst, "rotation", 0.12, 22.0).from(-0.12)
	bspin.tween_property(burst, "rotation", -0.12, 22.0)

	# Runde 40: Halbton-Punktraster (Ben-Day-Dots) ueber dem Verlauf
	var dots := TextureRect.new()
	dots.name = "Halftone"
	dots.texture = _make_halftone_texture(64)
	dots.set_anchors_preset(Control.PRESET_FULL_RECT)
	dots.stretch_mode = TextureRect.STRETCH_TILE
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.modulate = Color(1, 1, 1, 0.75)
	start_screen.add_child(dots)

	# Runde 40: Comic-Baender oben/unten (schwarz + Akzent)
	for top_edge in [true, false]:
		var band = TextureRect.new()
		band.anchor_left = 0.0
		band.anchor_right = 1.0
		if top_edge:
			band.anchor_top = 0.0
			band.anchor_bottom = 0.0
			band.offset_top = 0.0
			band.offset_bottom = 14.0
		else:
			band.anchor_top = 1.0
			band.anchor_bottom = 1.0
			band.offset_top = -14.0
			band.offset_bottom = 0.0
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		start_screen.add_child(band)
		var band_bg := ColorRect.new()
		band_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		if top_edge:
			band_bg.anchor_top = 0.0
			band_bg.anchor_bottom = 0.0
			band_bg.offset_top = 0.0
			band_bg.offset_bottom = 14.0
		else:
			band_bg.anchor_top = 1.0
			band_bg.anchor_bottom = 1.0
			band_bg.offset_top = -14.0
			band_bg.offset_bottom = 0.0
		band_bg.color = Color(0.05, 0.04, 0.09)
		band_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		start_screen.add_child(band_bg)

	# Runde 40: Inhalt in eine SCALE-Gruppe, damit auf kleinen Hoeken nichts
	# abgeschnitten wird (der Bug: untere Knöpfe lagen unter dem Bildrand)
	# Runde 43: Der Startseiten-Content wird in eine Designflaeche gesetzt und
	# danach in den Viewport SKALIERT. Der Faktor wird aus der GEMESSENEN
	# Inhaltshoehe berechnet, damit unten nichts ueber den Rand ragt.
	var scale_wrap := Control.new()
	scale_wrap.name = "StartScale"
	scale_wrap.custom_minimum_size = Vector2(1240, 830)
	scale_wrap.size = Vector2(1240, 830)
	scale_wrap.pivot_offset = Vector2(0, 0)
	scale_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_screen.add_child(scale_wrap)

	# Runde 40: Comic-Panel als Rahmen um den ganzen Inhalt
	var frame := PanelContainer.new()
	frame.name = "StartFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.05, 0.05, 0.10, 0.74), Color(0.98, 0.80, 0.20), 6))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scale_wrap.add_child(frame)

	# Inhalt (IGNORE: schluckt keine Klicks -> Zahnrad bleibt bedienbar)
	var box = VBoxContainer.new()
	box.name = "StartBox"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(box)

	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "COMIC SHOOTER"
	title.label_settings = _make_label_settings(96, Color(1.0, 0.86, 0.12), 14)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.rotation = -0.03
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var bounce := title.create_tween()
	bounce.set_loops()
	bounce.tween_property(title, "rotation", -0.03, 0.0)
	bounce.tween_property(title, "rotation", 0.03, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bounce.tween_property(title, "rotation", -0.03, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Held + Name
	var hero_row = HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 20)
	box.add_child(hero_row)

	main_hero_img = TextureRect.new()
	main_hero_img.name = "MainHero"
	main_hero_img.custom_minimum_size = Vector2(116, 116)
	main_hero_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	main_hero_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_row.add_child(main_hero_img)

	var hero_info = VBoxContainer.new()
	hero_info.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_info.add_theme_constant_override("separation", 2)
	hero_row.add_child(hero_info)

	main_name_chip = Label.new()
	main_name_chip.name = "MainNameChip"
	main_name_chip.label_settings = _make_label_settings(44, Color(1, 1, 1), 8)
	main_name_chip.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	hero_info.add_child(main_name_chip)

	var main_sub = Label.new()
	main_sub.text = "Top-Down Monster Shooter"
	main_sub.label_settings = _make_label_settings(22, Color(0.85, 0.91, 0.86), 5)
	hero_info.add_child(main_sub)

	# Monster-Parade
	var monsters = HBoxContainer.new()
	monsters.alignment = BoxContainer.ALIGNMENT_CENTER
	monsters.add_theme_constant_override("separation", 18)
	for key in ["monster_green", "monster_red", "monster_blue", "monster_purple", "monster_yellow", "monster_pink", "monster_orange", "monster_burrower", "monster_golem", "monster_pyro"]:
		var mr = TextureRect.new()
		mr.texture = TextureManager.get_texture(key)
		mr.custom_minimum_size = Vector2(54, 54)
		mr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		monsters.add_child(mr)
	box.add_child(monsters)

	# SPIELEN
	# Runde 40: Comic-Mitte - Karte, Held und Statistik als drei Karten
	var mid_row := HBoxContainer.new()
	mid_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_row.add_theme_constant_override("separation", 16)
	box.add_child(mid_row)

	# Karte der aktiven Welt
	var map_card := PanelContainer.new()
	map_card.custom_minimum_size = Vector2(176, 168)
	map_card.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.08, 0.10, 0.16, 0.90), Color(0.36, 0.78, 0.92), 5, 10))
	mid_row.add_child(map_card)
	var map_col := VBoxContainer.new()
	map_col.alignment = BoxContainer.ALIGNMENT_CENTER
	map_col.add_theme_constant_override("separation", 4)
	map_card.add_child(map_col)
	var mapic := TextureRect.new()
	mapic.name = "MapPreview"
	if game_manager != null:
		var mkey: String = str(game_manager.map_data().get("icon", "map_meadow"))
		var mtex = TextureManager.get_texture(mkey)
		if mtex == null:
			mtex = TextureManager.get_texture("map_meadow")
		mapic.texture = mtex
	mapic.custom_minimum_size = Vector2(150, 150)
	mapic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mapic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mapic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_col.add_child(mapic)
	var mapl := Label.new()
	mapl.name = "MapName"
	if game_manager != null:
		mapl.text = str(game_manager.map_data().get("name", "WIESE")).to_upper()
	mapl.label_settings = _make_label_settings(22, Color(0.72, 0.94, 1.0), 5)
	mapl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	map_col.add_child(mapl)

	# Held (mit equipptem Skin)
	var hero_card := PanelContainer.new()
	hero_card.custom_minimum_size = Vector2(176, 168)
	hero_card.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.10, 0.08, 0.16, 0.90), Color(0.98, 0.80, 0.20), 5, 10))
	mid_row.add_child(hero_card)
	var hero_col := VBoxContainer.new()
	hero_col.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_col.add_theme_constant_override("separation", 4)
	hero_card.add_child(hero_col)
	var hero := TextureRect.new()
	hero.name = "HeroPreview"
	hero.texture = TextureManager.get_player_texture(0, 0)
	hero.custom_minimum_size = Vector2(150, 150)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_col.add_child(hero)
	var herol := Label.new()
	herol.name = "HeroSkinName"
	herol.text = "DEIN HELD"
	herol.label_settings = _make_label_settings(20, Color(1.0, 0.86, 0.40), 5)
	herol.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	hero_col.add_child(herol)

	# Statistik-Karte
	var stat_card := PanelContainer.new()
	stat_card.custom_minimum_size = Vector2(300, 168)
	stat_card.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.06, 0.08, 0.12, 0.90), Color(0.62, 0.68, 0.80), 5, 14))
	mid_row.add_child(stat_card)
	var stat_col := VBoxContainer.new()
	stat_col.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_col.add_theme_constant_override("separation", 6)
	stat_card.add_child(stat_col)
	var statl := Label.new()
	statl.name = "StartStats"
	if game_manager != null:
		statl.text = "BESTER SCORE\n%d\n\nGOLD\n%d" % [int(game_manager.high_score), int(game_manager.gold)]
	statl.label_settings = _make_label_settings(26, Color(0.90, 0.94, 0.99), 5)
	statl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	stat_col.add_child(statl)

	var play_btn = _make_pixel_button("SPIELEN", Color(0.16, 0.52, 0.95), 48)
	play_btn.custom_minimum_size = Vector2(700, 108)
	play_btn.tooltip_text = "Joystick links + Feuer rechts   ·   Tastatur: WASD + Leertaste"
	play_btn.pressed.connect(_on_play_pressed)
	box.add_child(play_btn)

	# Navigations-Reihe
	var nav = HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	box.add_child(nav)

	# Runde 44: Navigations-KACHELN - jede Kachel hat ein eigenes
	# Pixel-Art-Icon und fuehrt zu der passenden Seite.
	var nav_defs: Array = [
		{ "id": "lan", "text": "LAN SPIEL", "col": Color(0.18, 0.66, 0.40), "cb": _open_lan_panel },
		{ "id": "char", "text": "CHARAKTER", "col": Color(0.50, 0.28, 0.82), "cb": _open_char_page },
		{ "id": "shop", "text": "SHOP", "col": Color(0.86, 0.58, 0.12), "cb": _open_shop_page },
		{ "id": "coll", "text": "SAMMLUNG", "col": Color(0.74, 0.22, 0.46), "cb": func(): show_collection() },
		{ "id": "map", "text": "KARTEN", "col": Color(0.18, 0.56, 0.70), "cb": _open_maps_page }
	]
	for nd in nav_defs:
		nav.add_child(_make_nav_tile(str(nd["id"]), str(nd["text"]), nd["col"], nd["cb"]))

	# Modus + Chips
	var row3 = HBoxContainer.new()
	row3.alignment = BoxContainer.ALIGNMENT_CENTER
	row3.add_theme_constant_override("separation", 18)
	box.add_child(row3)

	mode_btn = _make_pixel_button("MODUS: ENDLOS", Color(0.26, 0.38, 0.70), 24)
	mode_btn.custom_minimum_size = Vector2(330, 74)
	mode_btn.pressed.connect(_on_mode_pressed)
	row3.add_child(mode_btn)

	main_score_chip = _make_chip("BEST SCORE: 0", Color(0.20, 0.26, 0.38), 28)
	(main_score_chip.get_meta("label") as Label).name = "BestScoreLabel"
	row3.add_child(main_score_chip)

	main_gold_chip = _make_chip("GOLD: 0", Color(0.34, 0.27, 0.12), 28)
	(main_gold_chip.get_meta("label") as Label).name = "GoldLabel"
	row3.add_child(main_gold_chip)

	# Zahnrad ZULETZT -> liegt obenauf und ist klickbar
	var gear := Button.new()
	gear.name = "GearButton"
	gear.icon = TextureManager.get_texture("icon_gear")
	gear.expand_icon = true
	gear.custom_minimum_size = Vector2(88, 88)
	gear.add_theme_constant_override("icon_max_width", 58)
	# Runde 40: Icon im Feld MITTIG (Icon-Max + Innenabstand 0, sonst sitzt es oben links)
	gear.alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	gear.add_theme_constant_override("h_separation", 0)
	gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear.offset_left = -128.0
	gear.offset_right = -40.0
	gear.offset_top = 40.0
	gear.offset_bottom = 128.0
	# Runde 48: der Gear muss ueber ALLEN Unterseiten liegen (die Seiten
	# sind Geschwister in start_screen und wuerden ihn sonst verdecken)
	gear.z_index = 200
	gear.tooltip_text = "Einstellungen"
	gear.focus_mode = Control.FOCUS_NONE
	# Runde 40: Comic-Zahnradfeld - schwarze Kontur, gelber Knopf, Icon mittig
	var gear_sb := _comic_panel_sb(Color(0.98, 0.80, 0.20), Color(0.06, 0.05, 0.10), 6)
	gear.add_theme_stylebox_override("normal", gear_sb)
	gear.add_theme_stylebox_override("hover", _comic_panel_sb(Color(1.0, 0.88, 0.34), Color(0.06, 0.05, 0.10), 6))
	gear.add_theme_stylebox_override("pressed", _comic_panel_sb(Color(0.88, 0.70, 0.16), Color(0.06, 0.05, 0.10), 6))
	gear.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	gear.add_theme_color_override("icon_normal_color", Color(0.10, 0.08, 0.14))
	gear.add_theme_color_override("icon_hover_color", Color(0.10, 0.08, 0.14))
	gear.add_theme_color_override("icon_pressed_color", Color(0.10, 0.08, 0.14))
	gear.pressed.connect(_open_settings_page)
	start_screen.add_child(gear)

	_fit_start_content.call_deferred()
	# Runde 46: Icons nachladen (TextureManager koennte noch fertig sein)
	call_deferred("_refresh_lazy_icons")
	if not get_viewport().size_changed.is_connected(_fit_start_content):
		get_viewport().size_changed.connect(_fit_start_content)

	_create_char_page()
	_create_settings_page()
	_build_confirm_page()

	start_screen.hide()

func _fit_start_content() -> void:
	# Runde 43: Startseiten-Inhalt in den Viewport einpassen.
	# Die Inhalts-BOX wird GEMESSEN (nicht der Rahmen), damit die Skalierung
	# stimmt, wenn sich die Kacheln aendern. Nichts ragt mehr ueber den Rand.
	var wrap := start_screen.find_child("StartScale", true, false)
	if wrap == null:
		return
	var sbox := start_screen.find_child("StartBox", true, false) as Control
	var frame := start_screen.find_child("StartFrame", true, false) as Control
	if sbox == null or frame == null:
		return
	var need: Vector2 = sbox.get_combined_minimum_size()
	need.x = maxf(need.x, 900.0)
	need.y = maxf(need.y, 500.0)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var k: float = minf((vp.x - 40.0) / (need.x + 40.0), (vp.y - 28.0) / (need.y + 28.0))
	k = clampf(k, 0.30, 1.0)
	wrap.scale = Vector2(k, k)
	wrap.size = need
	wrap.pivot_offset = Vector2.ZERO
	# Rahmen und Box fuellen die skalierte Flaeche
	frame.size = need
	frame.position = Vector2.ZERO
	frame.custom_minimum_size = Vector2.ZERO
	sbox.size = need
	sbox.position = Vector2.ZERO
	var sz: Vector2 = need * k
	wrap.position = Vector2((vp.x - sz.x) * 0.5, maxf(6.0, (vp.y - sz.y) * 0.5))
	# Zahnrad relativ zum skalierten Inhalt oben rechts halten
	var gear := start_screen.find_child("GearButton", true, false) as Control
	if gear != null:
		gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		gear.offset_left = -118.0
		gear.offset_right = -30.0
		gear.offset_top = 30.0
		gear.offset_bottom = 118.0


func _build_confirm_page() -> void:
	# Runde 40: Zwischenfenster - man sieht Modus, Karte und ALLE Items,
	# die im naechsten Spiel angewendet werden, und bestaetigt erst dann.
	confirm_page = _make_page("RUN-UEBERSICHT")
	confirm_box = _page_box(confirm_page)
	confirm_page.visible = false

func show_confirm_page() -> void:
	# Runde 40: Seite mit dem aktuellen Run-Setup fuellen
	if confirm_page == null:
		return
	# erst die anderen Seiten schliessen, dann diese oeffnen
	if char_page:
		char_page.hide()
	if settings_page:
		settings_page.hide()
	if shop_page:
		shop_page.hide()
	if maps_page:
		maps_page.hide()
	if collection_page:
		collection_page.hide()
	# Runde 49: Die Waffen-Stats-Seite ist auch eine Unterseite
	if stats_page:
		stats_page.hide()
	_confirm_refresh()
	confirm_page.visible = true
	start_screen.show()
	if hud:
		hud.hide()
	if death_screen:
		death_screen.hide()
	if lan_panel:
		lan_panel.hide()

func _confirm_refresh() -> void:
	if confirm_box == null or game_manager == null:
		return
	for c in confirm_box.get_children():
		if c.get_index() > 0:
			confirm_box.remove_child(c)
			c.queue_free()
	# Modus + Karte
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.08, 0.10, 0.16, 0.9), Color(0.36, 0.78, 0.92), 5, 14))
	confirm_box.add_child(head)
	var hcol := VBoxContainer.new()
	hcol.add_theme_constant_override("separation", 6)
	head.add_child(hcol)
	var mode_txt: String = "WELLEN-MODUS" if int(game_manager.game_mode) == 1 else "ENDLOS-MODUS"
	var h1 := Label.new()
	h1.text = mode_txt + "     ·     KARTE: " + str(game_manager.map_data().get("name", "ERDE")).to_upper()
	h1.label_settings = _make_label_settings(34, Color(1.0, 0.88, 0.36), 8)
	h1.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	hcol.add_child(h1)
	var h2 := Label.new()
	h2.text = "DIESE ITEMS GELTEN IM NAECHSTEN RUN"
	h2.label_settings = _make_label_settings(24, Color(0.72, 0.86, 0.96), 5)
	h2.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	hcol.add_child(h2)
	# Aktive Verbrauchsgueter (Boosts) aufzaehlen
	var items: Array = []
	for b in game_manager.BOOSTS:
		var bid: String = str(b["id"])
		var cnt: int = int(game_manager.boosts.get(bid, 0))
		if cnt > 0:
			items.append("%s  x%d" % [str(b["name"]), cnt])
	# Ausgeruesteter Held
	var pcol: int = int(game_manager.p_color)
	var phat: int = int(game_manager.p_hat)
	var prig: int = int(game_manager.p_rig)
	var hero_txt: String = "HELD: %s" % str(game_manager.p_name)
	if prig > 0:
		hero_txt += "  ·  SKIN: " + str(TextureManager.RIG_NAMES[clampi(prig, 0, 5)])
	else:
		hero_txt += "  ·  FARBE: " + str(TextureManager.COLOR_NAMES[pcol]) + "  ·  HUT: " + str(TextureManager.HAT_NAMES[phat])
	items.append(hero_txt)
	# Gekaufte Karten-Inhalte dieser Session (Skins/Farben/Huete sind dauerhaft)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	confirm_box.add_child(grid)
	if items.is_empty():
		var none_l := Label.new()
		none_l.text = "Keine Verbrauchsgueter - der Run startet ohne Bonus."
		none_l.label_settings = _make_label_settings(26, Color(0.80, 0.84, 0.88), 5)
		none_l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(none_l)
	for it in items:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.14, 0.16, 0.22, 0.95), Color(0.98, 0.80, 0.20), 4, 10))
		grid.add_child(card)
		var l := Label.new()
		l.text = str(it)
		l.label_settings = _make_label_settings(26, Color(1, 1, 1), 5)
		l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(l)
	# Knoepfe
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 20)
	confirm_box.add_child(brow)
	var back := _make_comic_button("ZURUECK", Color(0.30, 0.36, 0.52), 30)
	back.custom_minimum_size = Vector2(300, 88)
	back.pressed.connect(func():
		confirm_page.visible = false
		show_start_screen())
	brow.add_child(back)
	var go := _make_comic_button("LOS GEHT'S!", Color(0.16, 0.62, 0.34), 34)
	go.custom_minimum_size = Vector2(420, 88)
	go.pressed.connect(func():
		confirm_page.visible = false
		if game_manager:
			game_manager.start_game(false))
	brow.add_child(go)

func _create_char_page() -> void:
	char_page = _make_page("CHARAKTER")
	var box := _page_box(char_page)

	var top = HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 26)
	box.add_child(top)

	char_preview = TextureRect.new()
	char_preview.name = "CharPreview"
	# Runde 43: groessere Vorschau - der Held war kaum sichtbar
	# Runde 45: kompakter, damit die Seite ohne Scaling in den Bildschirm passt
	char_preview.custom_minimum_size = Vector2(210, 210)
	char_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	char_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(char_preview)

	var info = VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 6)
	top.add_child(info)

	var name_row = HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 12)
	info.add_child(name_row)

	var nl = Label.new()
	nl.text = "NAME:"
	nl.label_settings = _make_label_settings(28, Color(0.92, 0.95, 0.92), 5)
	name_row.add_child(nl)

	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(300, 54)
	name_edit.max_length = 10
	name_edit.placeholder_text = "HELD"
	name_edit.add_theme_font_size_override("font_size", 26)
	name_edit.text_changed.connect(_on_name_changed)
	name_row.add_child(name_edit)

	char_name_chip = Label.new()
	char_name_chip.label_settings = _make_label_settings(24, Color(0.80, 0.88, 0.95), 5)
	info.add_child(char_name_chip)

	# Farben
	var col_title = Label.new()
	col_title.text = "FARBE"
	col_title.label_settings = _make_label_settings(25, Color(1.0, 0.85, 0.35), 5)
	col_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(col_title)

	var col_row = HBoxContainer.new()
	col_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col_row.add_theme_constant_override("separation", 8)
	box.add_child(col_row)

	color_buttons.clear()
	for i in range(TextureManager.COLOR_NAMES.size()):
		# Runde 43: Pixel-Kachel mit gut lesbarem Helden-Bild
		var cb := _make_pixel_button("", Color(0.20, 0.24, 0.32), 18)
		cb.custom_minimum_size = Vector2(104, 78)
		cb.expand_icon = true
		cb.add_theme_constant_override("icon_max_width", 62)
		cb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cb.pressed.connect(_on_color_pressed.bind(i))
		col_row.add_child(cb)
		color_buttons.append(cb)

	# Hüte
	var hat_title = Label.new()
	hat_title.text = "HUT  (Kisten schalten neue frei)"
	hat_title.label_settings = _make_label_settings(25, Color(1.0, 0.85, 0.35), 5)
	hat_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hat_title)

	var hat_row = HBoxContainer.new()
	hat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hat_row.add_theme_constant_override("separation", 8)
	box.add_child(hat_row)

	hat_buttons.clear()
	for i in range(TextureManager.HAT_NAMES.size()):
		# Runde 45: HAT-Kachel zeigt das BILD (bisher nur Text!)
		var hb := _make_pixel_button("", Color(0.20, 0.24, 0.32), 18)
		hb.custom_minimum_size = Vector2(96, 96)
		hb.expand_icon = true
		hb.add_theme_constant_override("icon_max_width", 76)
		hb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hb.tooltip_text = str(TextureManager.HAT_NAMES[i])
		hb.pressed.connect(_on_hat_pressed.bind(i))
		hat_row.add_child(hb)
		hat_buttons.append(hb)

	# Runde 43: SKINS hier im Charakter-Fenster (Punkt 1 des Nutzers)
	var skin_title = Label.new()
	skin_title.text = "SKIN  (Kisten schalten neue frei)"
	skin_title.label_settings = _make_label_settings(25, Color(1.0, 0.85, 0.35), 5)
	skin_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(skin_title)

	var skin_row = HBoxContainer.new()
	skin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skin_row.add_theme_constant_override("separation", 8)
	box.add_child(skin_row)

	skin_buttons.clear()
	for i in range(TextureManager.RIG_NAMES.size()):
		var sk := _make_pixel_button("", Color(0.30, 0.18, 0.30), 18)
		sk.custom_minimum_size = Vector2(140, 140)
		sk.expand_icon = true
		sk.add_theme_constant_override("icon_max_width", 112)
		sk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Runde 45: kein Fokus-Ring (der sah wie ein Fehler aus)
		sk.focus_mode = Control.FOCUS_NONE
		sk.pressed.connect(_on_skin_pressed.bind(i))
		skin_row.add_child(sk)
		skin_buttons.append(sk)

	char_unlock_label = Label.new()
	char_unlock_label.label_settings = _make_label_settings(22, Color(0.85, 0.90, 0.85), 5)
	char_unlock_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(char_unlock_label)

	var back := _make_pixel_button("ZURUECK", Color(0.30, 0.34, 0.44), 28)
	back.custom_minimum_size = Vector2(280, 62)
	back.pressed.connect(_close_pages)
	box.add_child(back)
	char_page.hide()

# ---------------- Einstellungs-Seite ----------------

# ============================================================
# PAUSEN-SCREEN (Runde 15, Tester-Feedback)
# ============================================================
var pause_overlay: Control = null
const DIFF_NAMES := ["LEICHT", "NORMAL", "SCHWER", "HARDCORE"]
const AIM_NAMES := ["AUS", "SCHWACH", "STARK"]
var settings_diff_buttons: Array = []
var settings_aim_buttons: Array = []
var diff_buttons: Array = []
var aim_buttons: Array = []

func is_modal_open() -> bool:
	# Runde 28: Shop + Upgrade-Fenster zaehlen als Modal (Spiel muss pausiert bleiben)
	if pause_overlay != null:
		return true
	if shop_panel != null and shop_panel.visible:
		return true
	if upgrade_overlay != null:
		return true
	return false

func _input(event: InputEvent) -> void:
	# Runde 30: Shop-Liste per Finger-Drag scrollen.
	# Auf Android schlucken die Item-Buttons (mouse_filter STOP) die Drag-Events,
	# dadurch bewegte sich der ScrollContainer nicht. Hier global abgefangen -
	# funktioniert auch bei pausiertem Spiel (process_mode ALWAYS).
	if shop_panel == null or shop_scroll == null:
		return
	if not shop_panel.visible:
		return
	if event is InputEventScreenDrag:
		shop_scroll.scroll_vertical -= int((event as InputEventScreenDrag).relative.y * 1.2)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		shop_scroll.scroll_vertical -= int((event as InputEventMouseMotion).relative.y * 1.2)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if game_manager != null and game_manager.has_method("toggle_pause"):
				game_manager.call("toggle_pause")
		elif event.keycode == KEY_A and game_manager != null and game_manager.current_state == 1:
			game_manager.call("cycle_game_mode")

func show_pause() -> void:
	hide_pause()
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.05, 0.78)
	pause_overlay.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _hud_comic_sb(0.97, COMIC_YELLOW, 8, 30))
	center.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title = Label.new()
	title.text = "PAUSE"
	title.label_settings = _make_label_settings(76, Color(1.0, 0.92, 0.55), 14)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var info = Label.new()
	var _dname := "NORMAL"
	if game_manager != null and game_manager.has_method("diff_data"):
		_dname = str(game_manager.diff_data()["name"])
	info.text = "Welle %d   ·   Schwierigkeit: %s   ·   %d Muenzen" % [game_manager.wave, _dname, game_manager.coins]
	info.label_settings = _make_label_settings(30, Color(0.85, 0.90, 0.95), 8)
	info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	var dtitle = Label.new()
	dtitle.text = "SCHWIERIGKEIT  (sofort wirksam)"
	dtitle.label_settings = _make_label_settings(28, Color(0.80, 0.86, 0.92), 8)
	dtitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(dtitle)

	var drow = HBoxContainer.new()
	drow.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_theme_constant_override("separation", 10)
	box.add_child(drow)
	diff_buttons.clear()
	for i in range(DIFF_NAMES.size()):
		var db := _make_pixel_button(str(DIFF_NAMES[i]), Color(0.24, 0.28, 0.38), 24)
		db.custom_minimum_size = Vector2(210, 62)
		db.pressed.connect(_on_difficulty_set.bind(i))
		drow.add_child(db)
		diff_buttons.append(db)

	var atitle = Label.new()
	atitle.text = "ZIELHILFE"
	atitle.label_settings = _make_label_settings(28, Color(0.80, 0.86, 0.92), 8)
	atitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(atitle)

	var arow = HBoxContainer.new()
	arow.alignment = BoxContainer.ALIGNMENT_CENTER
	arow.add_theme_constant_override("separation", 10)
	box.add_child(arow)
	aim_buttons.clear()
	for i in range(3):
		var ab := _make_pixel_button(str(AIM_NAMES[i]), Color(0.24, 0.28, 0.38), 24)
		ab.custom_minimum_size = Vector2(210, 62)
		ab.pressed.connect(_on_aim_set.bind(i))
		arow.add_child(ab)
		aim_buttons.append(ab)

	var sep = Control.new()
	sep.custom_minimum_size = Vector2(10, 18)
	box.add_child(sep)

	var bcont := _make_pixel_button("WEITER  (ESC)", Color(0.24, 0.62, 0.36), 32)
	bcont.custom_minimum_size = Vector2(520, 84)
	bcont.pressed.connect(func(): game_manager.call("toggle_pause"))
	box.add_child(bcont)

	var brow = HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 12)
	box.add_child(brow)

	var brest := _make_pixel_button("NEUSTART", Color(0.55, 0.42, 0.16), 26)
	brest.custom_minimum_size = Vector2(250, 72)
	brest.pressed.connect(func(): game_manager.call("restart_run"))
	brow.add_child(brest)

	var bset := _make_pixel_button("EINSTELLUNGEN", Color(0.28, 0.36, 0.52), 26)
	bset.custom_minimum_size = Vector2(250, 72)
	bset.pressed.connect(func():
		game_manager.paused = false
		get_tree().paused = false
		hide_pause()
		_open_settings_page())
	brow.add_child(bset)

	var bmenu := _make_pixel_button("HAUPTMENÜ", Color(0.52, 0.24, 0.24), 26)
	bmenu.custom_minimum_size = Vector2(250, 72)
	bmenu.pressed.connect(func(): game_manager.call("quit_to_menu"))
	brow.add_child(bmenu)

	var hint = Label.new()
	hint.text = "Tipp: Feuerknopf gedrückt halten = Dauerfeuer   ·   Q = Trank   ·   E = Bombe"
	hint.label_settings = _make_label_settings(24, Color(0.72, 0.78, 0.85), 6)
	hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	refresh_difficulty_ui()
	refresh_aim_ui()

func hide_pause() -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = null

func _on_difficulty_set(i: int) -> void:
	game_manager.call("set_difficulty", i)
	refresh_difficulty_ui()

func _on_aim_set(i: int) -> void:
	game_manager.call("set_aim_assist", i)
	refresh_aim_ui()

func refresh_difficulty_ui() -> void:
	for i in range(diff_buttons.size()):
		var b = diff_buttons[i]
		if not is_instance_valid(b):
			continue
		b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == game_manager.difficulty else Color(0.72, 0.74, 0.80, 1.0)
	_sync_setting_rows()

func refresh_aim_ui() -> void:
	for i in range(aim_buttons.size()):
		var b = aim_buttons[i]
		if not is_instance_valid(b):
			continue
		b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == game_manager.aim_assist else Color(0.72, 0.74, 0.80, 1.0)
	_sync_setting_rows()

# Reihen in der Einstellungsseite mitziehen (falls dort ebenfalls vorhanden)
func _sync_setting_rows() -> void:
	if settings_diff_buttons.size() > 0:
		for i in range(settings_diff_buttons.size()):
			var b = settings_diff_buttons[i]
			if is_instance_valid(b):
				b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == game_manager.difficulty else Color(0.72, 0.74, 0.80, 1.0)
	if settings_aim_buttons.size() > 0:
		for i in range(settings_aim_buttons.size()):
			var b = settings_aim_buttons[i]
			if is_instance_valid(b):
				b.modulate = Color(1.35, 1.35, 1.35, 1.0) if i == game_manager.aim_assist else Color(0.72, 0.74, 0.80, 1.0)

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
	for c in get_children():
		if c is Label and c.name == "TipLabel":
			c.queue_free()
	add_child(l)
	var tw := create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)

func _create_settings_page() -> void:
	settings_page = _make_page("EINSTELLUNGEN")
	var box := _page_box(settings_page)

	var qtitle = Label.new()
	qtitle.text = "GRAFIK-STUFE"
	qtitle.label_settings = _make_label_settings(34, Color(1.0, 0.85, 0.35), 6)
	qtitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(qtitle)

	var qrow = HBoxContainer.new()
	qrow.alignment = BoxContainer.ALIGNMENT_CENTER
	qrow.add_theme_constant_override("separation", 20)
	box.add_child(qrow)

	quality_buttons.clear()
	for i in range(3):
		var qb := _make_styled_button(["NIEDRIG", "MITTEL", "HOCH"][i], Color(0.30, 0.34, 0.44), 30)
		qb.custom_minimum_size = Vector2(300, 84)
		qb.pressed.connect(_on_quality_set.bind(i))
		qrow.add_child(qb)
		quality_buttons.append(qb)

	quality_info_label = Label.new()
	quality_info_label.label_settings = _make_label_settings(26, Color(0.85, 0.90, 0.85), 6)
	quality_info_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(quality_info_label)

	var dtitle2 = Label.new()
	dtitle2.text = "SCHWIERIGKEIT"
	dtitle2.label_settings = _make_label_settings(34, Color(1.0, 0.85, 0.35), 6)
	dtitle2.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(dtitle2)

	var drow2 = HBoxContainer.new()
	drow2.alignment = BoxContainer.ALIGNMENT_CENTER
	drow2.add_theme_constant_override("separation", 12)
	box.add_child(drow2)
	settings_diff_buttons.clear()
	for i in range(DIFF_NAMES.size()):
		var db2 := _make_styled_button(str(DIFF_NAMES[i]), Color(0.30, 0.34, 0.44), 28)
		db2.custom_minimum_size = Vector2(260, 76)
		db2.pressed.connect(_on_difficulty_set.bind(i))
		drow2.add_child(db2)
		settings_diff_buttons.append(db2)

	var atitle2 = Label.new()
	atitle2.text = "ZIELHILFE  (rastet auf Monster ein)"
	atitle2.label_settings = _make_label_settings(34, Color(1.0, 0.85, 0.35), 6)
	atitle2.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(atitle2)

	var arow2 = HBoxContainer.new()
	arow2.alignment = BoxContainer.ALIGNMENT_CENTER
	arow2.add_theme_constant_override("separation", 12)
	box.add_child(arow2)
	settings_aim_buttons.clear()
	for i in range(3):
		var ab2 := _make_styled_button(str(AIM_NAMES[i]), Color(0.30, 0.34, 0.44), 28)
		ab2.custom_minimum_size = Vector2(260, 76)
		ab2.pressed.connect(_on_aim_set.bind(i))
		arow2.add_child(ab2)
		settings_aim_buttons.append(ab2)

	var row2 = HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 24)
	box.add_child(row2)

	fps_btn = _make_styled_button("FPS-ANZEIGE: AUS", Color(0.28, 0.32, 0.42), 30)
	fps_btn.custom_minimum_size = Vector2(400, 80)
	fps_btn.pressed.connect(_on_fps_pressed)
	row2.add_child(fps_btn)

	sound_btn = _make_pixel_button("MUSIK: AN", Color(0.24, 0.42, 0.34), 26)
	sound_btn.custom_minimum_size = Vector2(400, 80)
	sound_btn.pressed.connect(_on_music_pressed)
	row2.add_child(sound_btn)

	sfx_btn = _make_pixel_button("SOUNDEFFEKTE: AN", Color(0.24, 0.34, 0.48), 26)
	sfx_btn.custom_minimum_size = Vector2(400, 80)
	sfx_btn.pressed.connect(_on_sfx_pressed)

	var row3 = HBoxContainer.new()
	row3.alignment = BoxContainer.ALIGNMENT_CENTER
	row3.add_theme_constant_override("separation", 12)
	row3.add_child(sfx_btn)
	box.add_child(row3)

	var info = Label.new()
	info.text = "FPS-ANZEIGE zeigt: FPS | Draw-Calls | Objekte | Proz-ms | Phys-ms | Monster | Stufe\nNIEDRIG: ohne Shader, weniger Details (schwache Geraete)  ·  HOCH: Soft-Look-Shader"
	info.label_settings = _make_label_settings(22, Color(0.80, 0.86, 0.86), 5)
	info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	var back := _make_styled_button("ZURUECK", Color(0.35, 0.38, 0.46), 34)
	back.custom_minimum_size = Vector2(320, 76)
	back.pressed.connect(_close_pages)
	box.add_child(back)
	settings_page.hide()

# ---------------- Navigation ----------------
func _open_char_page() -> void:
	if char_page == null:
		return
	# Runde 48: alle anderen Seiten schliessen - sonst stapeln sich
	# Shop/Charakter/Sammlung uebereinander (der Shop blieb sichtbar).
	_close_pages()
	char_page.show()
	refresh_profile_ui()

func _open_settings_page() -> void:
	if settings_page == null:
		return
	# Runde 48: die Einstellungen sind von JEDER Seite erreichbar -
	# vorher blieb die jeweils offene Seite sichtbar und verdeckte sie.
	_close_pages()
	settings_page.show()
	# Runde 48: die Einstellungs-Seite nach oben in die Zeichenreihenfolge
	# holen, damit sie ueber den anderen Seiten liegt.
	if settings_page.get_parent() != null:
		var par := settings_page.get_parent()
		par.move_child(settings_page, par.get_child_count() - 1)
	refresh_settings_ui()

func _close_pages() -> void:
	if char_page:
		char_page.hide()
	if settings_page:
		settings_page.hide()
	if shop_page:
		shop_page.hide()
	if maps_page:
		maps_page.hide()
	if collection_page:
		collection_page.hide()
	# Runde 40: die Run-Uebersicht ist auch eine Seite - sonst liegt sie
	# beim Zurueck zur Startseite weiter ueber dem Menue
	if confirm_page:
		confirm_page.hide()
	refresh_profile_ui()

func _on_quality_set(i: int) -> void:
	if game_manager:
		game_manager.set_quality(i)
	refresh_settings_ui()

func _on_music_pressed() -> void:
	# Runde 62: eigene Musik-Einstellung
	var on: bool = not SoundManager.music_on
	SoundManager.set_music_enabled(on)
	if game_manager != null:
		game_manager.call("set_music_setting", on)
	refresh_settings_ui()

func _on_sfx_pressed() -> void:
	# Runde 62: eigene Soundeffekt-Einstellung
	var on: bool = not SoundManager.sfx_on
	SoundManager.set_sfx_enabled(on)
	if game_manager != null:
		game_manager.call("set_sfx_setting", on)
	refresh_settings_ui()

func refresh_settings_ui() -> void:
	if game_manager == null:
		return
	var q: int = game_manager.get_quality()
	for i in range(quality_buttons.size()):
		if quality_buttons[i] != null:
			quality_buttons[i].modulate = Color(1.45, 1.45, 1.35) if i == q else Color(0.72, 0.74, 0.80)
	if quality_info_label:
		quality_info_label.text = "Aktuell: " + str(game_manager.QUALITY_NAMES[q]) + [" — ohne Shader, minimale Details, max 55 Monster", " — ohne Shader, volle Details, max 110 Monster", " — Soft-Look-Shader, max 150 Monster"][q]
	if fps_btn:
		fps_btn.text = "FPS-ANZEIGE: " + ("AN" if game_manager.debug_fps else "AUS")
		fps_btn.modulate = Color(1.35, 1.35, 1.35) if game_manager.debug_fps else Color(0.85, 0.85, 0.9)
	if sound_btn:
		sound_btn.text = "MUSIK: " + ("AN" if SoundManager.music_on else "AUS")
		sound_btn.modulate = Color(1.35, 1.35, 1.35) if SoundManager.music_on else Color(0.85, 0.85, 0.9)
	if sfx_btn:
		sfx_btn.text = "SOUNDEFFEKTE: " + ("AN" if SoundManager.sfx_on else "AUS")
		sfx_btn.modulate = Color(1.35, 1.35, 1.35) if SoundManager.sfx_on else Color(0.85, 0.85, 0.9)

func set_quality_label(name: String) -> void:
	if quality_info_label:
		quality_info_label.set_meta("tier_name", name)
	refresh_settings_ui()
func _create_death_screen():
	death_screen = Control.new()
	death_screen.name = "DeathScreen"
	death_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(death_screen)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.25, 0.08, 0.08)
	death_screen.add_child(bg)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	death_screen.add_child(box)

	var title = Label.new()
	title.text = "GAME OVER"
	title.label_settings = _make_label_settings(100, Color(0.95, 0.25, 0.2), 14)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var score_lbl = Label.new()
	score_lbl.name = "ScoreLabel"
	score_lbl.text = "Score: 0"
	score_lbl.label_settings = _make_label_settings(56, Color(1, 1, 1), 10)
	score_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(score_lbl)

	var best_lbl = Label.new()
	best_lbl.name = "BestScoreLabel"
	best_lbl.text = "Best: 0"
	best_lbl.label_settings = _make_label_settings(40, Color(1.0, 0.85, 0.3), 8)
	best_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(best_lbl)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 40)
	box.add_child(buttons)

	var restart_btn = _make_styled_button("NOCHMAL SPIELEN", Color(0.2, 0.7, 0.3), 34)
	restart_btn.custom_minimum_size = Vector2(420, 80)
	restart_btn.pressed.connect(_on_restart_pressed)
	buttons.add_child(restart_btn)

	var menu_btn = _make_styled_button("HAUPTMENUE", Color(0.25, 0.5, 0.9), 34)
	menu_btn.custom_minimum_size = Vector2(380, 80)
	menu_btn.pressed.connect(_on_menu_pressed)
	buttons.add_child(menu_btn)

	var exit_btn = _make_styled_button("BEENDEN", Color(0.45, 0.45, 0.5), 34)
	exit_btn.custom_minimum_size = Vector2(320, 80)
	exit_btn.pressed.connect(_on_exit_pressed)
	buttons.add_child(exit_btn)

	death_screen.hide()

# Boss-Warnung (kurzer roter Blink-Banner)
func hide_boss_bar() -> void:
	# Runde 26: Leiste ausblenden, wenn kein Boss mehr da ist
	if boss_bar != null:
		boss_bar.visible = false
		boss_bar.modulate.a = 1.0

func show_boss_warning(n: int) -> void:
	var banner = Label.new()
	banner.name = "BossBanner"
	banner.text = "!!! BOSS %d NAHT !!!" % n
	banner.label_settings = _make_label_settings(72, Color(1.0, 0.25, 0.2), 14)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.offset_top = 220
	banner.offset_bottom = 320
	banner.z_index = 40
	banner.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_child(banner)
	var tw := banner.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)
	tw.tween_callback(banner.queue_free)

var _lazy_icon_tries: int = 0


func _refresh_lazy_icons() -> void:
	# Runde 47: Icons nachladen, falls die Seite vor der Erzeugung des
	# TextureManagers gebaut wurde. Funktioniert fuer TextureRect UND
	# fuer Buttons (Icon-Slot).
	if start_screen == null:
		return
	for c in start_screen.find_children("*", "TextureRect", true, false):
		if c.texture != null:
			continue
		var k: String = str(c.get_meta("icon_key", ""))
		if k == "":
			continue
		var t = TextureManager.get_texture(k)
		if t != null:
			c.texture = t
	for c in start_screen.find_children("*", "Button", true, false):
		if c.icon != null:
			continue
		var k2: String = str(c.get_meta("icon_key", ""))
		if k2 == "":
			continue
		var t2 = TextureManager.get_texture(k2)
		if t2 != null:
			c.icon = t2
			c.expand_icon = true


# ============================================================
# Runde 51: Verbindungsabbruch-Screen
# ============================================================
var disconnect_screen: Control = null
var disconnect_title: Label = null
var disconnect_count: Label = null
var disconnect_left: float = 0.0


func _build_disconnect_screen() -> void:
	disconnect_screen = Control.new()
	disconnect_screen.name = "DisconnectScreen"
	disconnect_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	disconnect_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(disconnect_screen)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.07, 0.94)
	disconnect_screen.add_child(bg)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	disconnect_screen.add_child(box)

	var icon = Label.new()
	icon.text = "!"
	icon.label_settings = _make_label_settings(110, Color(0.95, 0.55, 0.2), 0)
	icon.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(icon)

	disconnect_title = Label.new()
	disconnect_title.text = "VERBINDUNG ZUM HOST ABGEBROCHEN"
	disconnect_title.label_settings = _make_label_settings(56, Color(0.98, 0.35, 0.3), 10)
	disconnect_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	disconnect_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disconnect_title.custom_minimum_size = Vector2(1500, 0)
	box.add_child(disconnect_title)

	var sub = Label.new()
	sub.text = "Die Verbindung zum Host wurde getrennt."
	sub.label_settings = _make_label_settings(32, Color(0.85, 0.85, 0.9), 6)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	disconnect_count = Label.new()
	disconnect_count.text = ""
	disconnect_count.label_settings = _make_label_settings(26, Color(0.7, 0.7, 0.78), 4)
	disconnect_count.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(disconnect_count)

	var btn = _make_styled_button("ZUR STARTSEITE", Color(0.22, 0.62, 0.32), 36)
	btn.custom_minimum_size = Vector2(460, 92)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_disconnect_back)
	box.add_child(btn)

	disconnect_screen.hide()


func show_disconnect_screen(msg: String = "VERBINDUNG ZUM HOST ABGEBROCHEN") -> void:
	if disconnect_screen == null:
		_build_disconnect_screen()
	if disconnect_title != null:
		disconnect_title.text = msg
	disconnect_left = 8.0
	if disconnect_count != null:
		disconnect_count.text = "Rueckkehr zur Startseite in 8 s"
	disconnect_screen.show()
	disconnect_screen.move_to_front()
	# Mauszeiger freigeben (im Spiel ist er oft gefangen)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func hide_disconnect_screen() -> void:
	disconnect_left = 0.0
	if disconnect_screen != null:
		disconnect_screen.hide()


func _on_disconnect_back() -> void:
	hide_disconnect_screen()
	if game_manager:
		game_manager.abort_run_to_start()


func show_start_screen() -> void:
	# Runde 49: Menue-Musik starten (ruhiger Loop)
	SoundManager.play_music("menu")
	if start_screen:
		start_screen.show()
	_refresh_lazy_icons()
	if chest_overlay:
		chest_overlay.visible = false
	if hud:
		hud.hide()
	if death_screen:
		death_screen.hide()
	if lan_panel:
		lan_panel.hide()
	# wieder unsichtbar.
	_close_pages()
	refresh_profile_ui()
	# Haengende Joystick-Zustaende loesen (Bugfix nach mehreren Runs)
	if move_stick:
		move_stick.force_reset()
	if move_stick2:
		move_stick2.force_reset()

func show_hud() -> void:
	if hud:
		hud.show()
	hide_lobby()
	if lan_panel:
		lan_panel.hide()
	if move_stick:
		move_stick.force_reset()
	if move_stick2:
		move_stick2.force_reset()
	if boss_bar:
		boss_bar.visible = false
		boss_bar.modulate.a = 1.0
	if start_screen:
		start_screen.hide()
	if death_screen:
		death_screen.hide()

func show_death_screen(current_score: int, best_score: int, gold_gain: int = 0, gold_total: int = 0) -> void:
	# Runde 49: Die Action-Musik endet mit dem Tod - zurueck auf
	# den ruhigen Loop, bis wieder ein Run startet.
	SoundManager.play_music("menu")
	if death_screen:
		death_screen.show()
	if hud:
		hud.hide()
	if start_screen:
		start_screen.hide()
	
	var score_label = death_screen.find_child("ScoreLabel", true, false)
	var best_label = death_screen.find_child("BestScoreLabel", true, false)
	if score_label:
		if gold_gain > 0:
			score_label.text = "SCORE  %d\n+%d GOLD   ·   KONTO  %d" % [current_score, gold_gain, gold_total]
		else:
			score_label.text = "SCORE  %d" % current_score
	if best_label:
		best_label.text = "Best: %d" % best_score

func set_start_score(score: int) -> void:
	var label = start_screen.find_child("BestScoreLabel", true, false)
	if label and score > 0:
		label.text = "Best Score: %d" % score

func update_health(current: int, maximum: int, pid: int = 1) -> void:
	# Herzanzahl dynamisch an maximum anpassen (Max-Health-Upgrade, V6)
	var bar = health_bar if pid == 1 else health_bar2
	var arr = heart_labels if pid == 1 else heart_labels2
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
	if combo_label == null:
		return
	if count < 2:
		combo_label.visible = false
		return
	combo_label.text = "COMBO x%d  (%.2fx Punkte)" % [count, mult]
	combo_label.visible = true
	combo_label.scale = Vector2(1.2, 1.2)
	var tw := combo_label.create_tween()
	tw.tween_property(combo_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_score(new_score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % new_score

func _on_play_pressed() -> void:
	# Runde 40: erst die Run-Uebersicht zeigen, dann starten
	show_confirm_page()

func _on_quality_pressed() -> void:
	if game_manager:
		game_manager.cycle_quality()

func _on_fps_pressed() -> void:
	if game_manager:
		game_manager.toggle_fps()

func _on_name_changed(t: String) -> void:
	if game_manager:
		game_manager.set_player_name(t)
		refresh_profile_ui()

func _on_color_pressed(i: int) -> void:
	if game_manager == null:
		return
	if not game_manager.is_color_unlocked(i):
		show_banner("FARBE GESPERRT — im SHOP freischalten", Color(1.0, 0.6, 0.4))
		return
	game_manager.set_profile_color(i)
	refresh_profile_ui()

func _on_skin_pressed(i: int) -> void:
	# Runde 43: Skin im Charakter-Fenster waehlen
	if game_manager == null:
		return
	if not game_manager.unlocked_rigs.has(i):
		show_banner("SKIN GESPERRT — im SHOP freischalten", Color(1.0, 0.6, 0.4))
		return
	game_manager.set_profile_rig(i)
	refresh_profile_ui()
	_refresh_skin_buttons()


func _on_hat_pressed(i: int) -> void:
	if game_manager:
		game_manager.set_profile_hat(i)
		refresh_profile_ui()

func _current_hero_texture() -> Texture2D:
	# Runde 43/48: EINE Wahrheit fuer die Charakter-Vorschau.
	# Runde 48: jetzt Skin + Farbe + HUT kombiniert (vorher fehlte der Hut).
	if game_manager == null:
		return null
	var col: int = int(game_manager.p_color)
	var hat: int = int(game_manager.p_hat)
	var skin: int = int(game_manager.p_rig)
	return TextureManager.get_skin_hat_texture_or_player(col, skin, hat)


func refresh_profile_ui() -> void:
	if game_manager == null:
		return
	var col: int = game_manager.p_color
	var hat: int = game_manager.p_hat
	var nm: String = str(game_manager.p_name)
	# Runde 40: ein equippter Skin ersetzt das komplette Charakterbild
	var skin: int = int(game_manager.p_rig)
	# Runde 43: zentrale Quelle - damit zeigen Vorschau, Startseite und
	# Sammlung IMMER denselben Charakter
	var tex: Texture2D = _current_hero_texture()
	if tex == null:
		tex = TextureManager.get_player_texture(col, hat)
	if name_edit and name_edit.text != nm:
		name_edit.text = nm
	if char_preview:
		char_preview.texture = tex
	if main_hero_img:
		main_hero_img.texture = tex
	# Runde 43: die Skin-Kacheln im Charakter-Fenster mitaktualisieren
	_refresh_skin_buttons()
	# Runde 40: Startseiten-Held zeigt den equippten Skin
	var herov = start_screen.find_child("HeroPreview", true, false)
	if herov != null and herov is TextureRect:
		(herov as TextureRect).texture = tex
	var heron = start_screen.find_child("HeroSkinName", true, false)
	if heron != null and heron is Label:
		var sk_name: String = str(TextureManager.RIG_NAMES[clampi(skin, 0, 5)]) if skin > 0 else "DEIN HELD"
		(heron as Label).text = sk_name
	# Runde 40: Karten-Icon + Kartennamen + Statistik der Startseite fuellen.
	# (Beim Aufbau war game_manager noch null -> die Karten blieben leer.)
	var mapv = start_screen.find_child("MapPreview", true, false)
	var mapn = start_screen.find_child("MapName", true, false)
	if mapv != null and mapv is TextureRect:
		var mkey: String = str(game_manager.map_data().get("icon", "map_meadow"))
		var mtex = TextureManager.get_texture(mkey)
		if mtex == null:
			mtex = TextureManager.get_texture("map_meadow")
		if mtex != null:
			(mapv as TextureRect).texture = mtex
	if mapn != null and mapn is Label:
		(mapn as Label).text = str(game_manager.map_data().get("name", "ERDE")).to_upper()
	var statv = start_screen.find_child("StartStats", true, false)
	if statv != null and statv is Label:
		(statv as Label).text = "BESTER SCORE\n%d\n\nGOLD\n%d" % [int(game_manager.high_score), int(game_manager.gold)]
	if main_name_chip:
		main_name_chip.text = nm
	if char_name_chip:
		# Runde 43: alle drei Eigenschaften zeigen
		var skin_txt: String = str(TextureManager.RIG_NAMES[clampi(skin, 0, 5)]) if skin > 0 else "STANDARD"
		char_name_chip.text = "Farbe: %s   ·   Hut: %s   ·   Skin: %s" % [str(TextureManager.COLOR_NAMES[col]), str(TextureManager.HAT_NAMES[hat]), skin_txt]
	var open_hats: int = game_manager.unlocked_hats.size()
	if char_unlock_label:
		char_unlock_label.text = "%d/%d Farben   ·   %d/%d Hüte freigeschaltet   ·   Gold: %d" % [game_manager.unlocked_colors.size(), TextureManager.COLOR_NAMES.size(), open_hats, TextureManager.HAT_NAMES.size(), game_manager.gold]
	# Farbkacheln: gesperrte zeigen "?" (Freischaltung ueber Kisten im Shop)
	for i in range(color_buttons.size()):
		var cb = color_buttons[i]
		if cb == null:
			continue
		var open: bool = game_manager.is_color_unlocked(i)
		cb.disabled = not open
		if open:
			# Runde 48: die Farbkachel zeigt den aktuellen Skin in dieser
			# Farbe (vorher immer das Base-Skin)
			cb.icon = TextureManager.get_skin_hat_texture_or_player(i, skin, hat)
			cb.text = ""
			cb.tooltip_text = str(TextureManager.COLOR_NAMES[i])
		else:
			cb.icon = null
			cb.text = "?"
			cb.tooltip_text = "Gesperrt — im SHOP aus Kisten freischalten"
		cb.modulate = Color(1.45, 1.45, 1.45) if i == col else Color(0.78, 0.78, 0.84)
	refresh_hat_buttons(game_manager.unlocked_hats, hat)

func refresh_hat_buttons(unlocked: Array, cur: int) -> void:
	# Runde 48: die Hut-Kacheln zeigen jetzt das BILD des Helden mit diesem
	# Hut (Skin + Farbe + Hut kombiniert). Vorher stand dort nur Text.
	if game_manager == null:
		return
	var col: int = int(game_manager.p_color)
	var skin: int = int(game_manager.p_rig)
	for i in range(hat_buttons.size()):
		var b = hat_buttons[i]
		if b == null:
			continue
		var open: bool = unlocked.has(i)
		b.disabled = not open
		b.focus_mode = Control.FOCUS_NONE
		b.text = ""
		if open:
			b.icon = TextureManager.get_skin_hat_texture_or_player(col, skin, i)
			b.tooltip_text = str(TextureManager.HAT_NAMES[i]) + ("  (AKTIV)" if i == cur else "")
		else:
			# gesperrt: Silhouette in Grau
			b.icon = TextureManager.get_skin_hat_texture_or_player(col, skin, i)
			b.modulate = Color(0.42, 0.44, 0.52, 0.75)
			b.tooltip_text = str(TextureManager.HAT_NAMES[i]) + "  (gesperrt - im SHOP)"
		if i == cur:
			# aktiv: goldener Rahmen + heller
			b.add_theme_stylebox_override("normal", _make_pixel_panel_sb(Color(0.34, 0.26, 0.10), Color(1.0, 0.84, 0.24), 5, 6))
			b.add_theme_stylebox_override("hover", _make_pixel_panel_sb(Color(0.40, 0.31, 0.12), Color(1.0, 0.88, 0.34), 5, 6))
			b.add_theme_stylebox_override("pressed", _make_pixel_panel_sb(Color(0.28, 0.22, 0.08), Color(1.0, 0.84, 0.24), 5, 6))
			b.modulate = Color(1.20, 1.20, 1.20)
		elif open:
			b.add_theme_stylebox_override("normal", _make_pixel_panel_sb(Color(0.16, 0.18, 0.26), Color(0.42, 0.50, 0.64), 4, 6))
			b.add_theme_stylebox_override("hover", _make_pixel_panel_sb(Color(0.22, 0.25, 0.34), Color(0.55, 0.64, 0.78), 4, 6))
			b.add_theme_stylebox_override("pressed", _make_pixel_panel_sb(Color(0.12, 0.13, 0.18), Color(0.42, 0.50, 0.64), 4, 6))
			b.modulate = Color(1, 1, 1)

func _on_mode_pressed() -> void:
	if game_manager:
		game_manager.cycle_game_mode()

func set_mode_label(m: int) -> void:
	if mode_btn:
		mode_btn.text = "MODUS: " + ("WELLEN + SHOP" if m == 1 else "ENDLOS")

# ============================================================
# WELLEN-MODUS: Anzeige + Shop (Punkt 6)
# ============================================================
func update_wave_label(w: int, coins_v: int, shop: bool, t: float, remaining: int = 0,
		level_now: int = 0, level_goal: int = 0) -> void:
	var show_coin := t >= 0.0
	if coin_panel:
		coin_panel.visible = show_coin
	if coin_label:
		coin_label.text = str(coins_v)
	if wave_label == null:
		return
	if not show_coin:
		wave_label.visible = false
		return
	wave_label.visible = true
	# Runde 55: Kein Level-Ziel mehr in der Anzeige - der Wellen-Fortschritt
	# haengt nur noch an den Monstern der Welle, nicht am Level.
	if shop:
		wave_label.text = "WELLE %d GESCHAFFT   ·   Shop %ds" % [w, int(ceil(maxf(0.0, t)))]
	else:
		wave_label.text = "WELLE %d   ·   %d Monster uebrig" % [w, maxi(0, remaining)]
func shop_price_mult() -> float:
	# Runde 33: Preise skalieren mit der Karte (Mars/Jungel geben mehr Gold)
	if game_manager != null and game_manager.has_method("shop_price_mult"):
		return float(game_manager.call("shop_price_mult"))
	return 1.0

# Runde 52: Shop-Diagnose in der UI
func _sui(tag: String, msg: String) -> void:
	print("[SHOP][UI][%.2f][%s] %s" % [float(Time.get_ticks_msec()) / 1000.0, tag, msg])

# Runde 52: Signatur der zuletzt gezeichneten Shop-Liste. Verhindert,
# dass der 4-Hz-Netzwerk-Update den Shop komplett neu baut (Klicks gehen
# dabei verloren, weil die Karten im selben Frame ersetzt werden).
var _shop_sig: String = ""


func update_shop_coins(coins_v: int, buys_left: int = -1, buys_max: int = -1) -> void:
	# Leichtgewichtiges Update: nur Gold + Hinweis, KEIN Neuaufbau
	if shop_coin_label != null:
		shop_coin_label.text = "%d" % coins_v
	if shop_hint != null and buys_max > 0:
		shop_hint.text = "KAEUFE: %d / %d   ·   im Wellen-Modus gibt es Upgrades NUR hier" % [
			maxi(0, buys_left), buys_max]


func show_shop(coins_v: int, items: Array, buys_left: int = -1, buys_max: int = -1) -> void:
	if shop_panel == null:
		_sui("BUILD", "shop_panel war null -> wird jetzt gebaut")
		_build_shop()
	var sig: String = "%d|%d|%d|" % [coins_v, buys_left, buys_max]
	for itx in items:
		sig += "%s:%s;" % [str(itx.get("id", "?")), str(itx.get("bought", false))]
	if sig == _shop_sig and shop_panel != null and shop_panel.visible:
		update_shop_coins(coins_v, buys_left, buys_max)
		return
	_shop_sig = sig
	_sui("SHOW", "Items=%d | Gold=%d | Kaeufe=%d/%d | Panel vorher sichtbar=%s" % [
		items.size(), coins_v, buys_left, buys_max,
		str(shop_panel.visible if shop_panel != null else false)])
	if items.is_empty():
		_sui("WARN", "Shop mit LEERER Item-Liste geoeffnet - es gibt nichts zu kaufen")
	var buyable: int = 0
	for it0 in items:
		var p0: int = maxi(1, int(round(float(it0["price"]) * shop_price_mult())))
		if coins_v >= p0 and not bool(it0.get("bought", false)):
			buyable += 1
	_sui("PRICES", "%d von %d Items bezahlbar (Gold=%d, Kaeufe frei=%s)" % [
		buyable, items.size(), coins_v, str(buys_max <= 0 or buys_left > 0)])
	# Runde 28: Shop pausiert das Spiel - die Wellen liefen vorher im Hintergrund weiter
	get_tree().paused = true
	var kk: float = _ui_k()
	for c in shop_list.get_children():
		shop_list.remove_child(c)
		c.queue_free()
	for c in shop_continue_row.get_children():
		shop_continue_row.remove_child(c)
		c.queue_free()
	shop_title.text = "SHOP"
	if shop_wave_label:
		shop_wave_label.text = "Welle %d geschafft — jetzt einkaufen" % game_manager.wave if game_manager else ""
	if shop_coin_label:
		shop_coin_label.text = "%d" % coins_v
	if shop_hint:
		shop_hint.text = "Im Wellen-Modus gibt es Upgrades NUR hier — Level-Ups bringen keine Karten."
		if buys_max > 0:
			shop_hint.text = "KAEUFE: %d / %d   ·   im Wellen-Modus gibt es Upgrades NUR hier" % [maxi(0, buys_left), buys_max]
	for it in items:
		var price: int = maxi(1, int(round(float(it["price"]) * shop_price_mult())))
		var can: bool = coins_v >= price
		var rare: bool = bool(it.get("rare", false))
		var base_col := Color(0.24, 0.20, 0.07) if rare else Color(0.12, 0.34, 0.30)
		if not can:
			base_col = Color(0.20, 0.21, 0.25)
		var card := _make_styled_button("", base_col, int(28.0 * kk))
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
		shop_list.add_child(card)

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
		nm.label_settings = _make_label_settings(28, Color(1, 1, 1) if can else Color(0.6, 0.6, 0.65), 5)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt.add_child(nm)

		var pr = Label.new()
		pr.text = "%d Muenzen" % price
		pr.label_settings = _make_label_settings(22, Color(1.0, 0.85, 0.35) if can else Color(0.85, 0.35, 0.35), 4)
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt.add_child(pr)

	var cont := _make_styled_button("WEITER — naechste Welle", Color(0.26, 0.48, 0.92), int(30.0 * kk))
	cont.custom_minimum_size = Vector2(400.0 * kk, 88.0 * kk)
	cont.pressed.connect(_on_shop_continue)
	shop_continue_row.add_child(cont)
	shop_panel.visible = true

func _ui_k() -> float:
	# Runde 29: UI auf die Bildschirmgroesse skalieren (kleine Fenster/Handys)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	return clampf(minf(vp.y / 1000.0, vp.x / 1700.0), 0.50, 1.25)

func _build_shop() -> void:
	shop_panel = ColorRect.new()
	shop_panel.name = "ShopPanel"
	shop_panel.color = Color(0.04, 0.05, 0.08, 0.92)
	shop_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shop_panel)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var k: float = _ui_k()
	panel.offset_left = 320.0 * k
	panel.offset_right = -320.0 * k
	panel.offset_top = 80.0 * k
	panel.offset_bottom = -80.0 * k
	panel.add_theme_stylebox_override("panel", _make_panel_sb(0.96, 30))
	shop_panel.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(14.0 * k))
	panel.add_child(box)

	# Runde 29: Scrollbereich - kann nie den WEITER-Button aus dem Bild draengen
	shop_scroll = ScrollContainer.new()
	shop_scroll.custom_minimum_size = Vector2(0.0, float(get_viewport().get_visible_rect().size.y) * 0.44)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_scroll.add_theme_constant_override("scroll_deadzone", 12)
	# Runde 34b: erst an der richtigen Stelle (nach Kopf/Welle) in die Box haengen -
	# vorher stand der ScrollContainer als ERSTES Kind -> die Itemsappeared ueber
	# der SHOP-Ueberschrift.

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 24)
	box.add_child(head)

	shop_title = Label.new()
	shop_title.text = "SHOP"
	shop_title.label_settings = _make_label_settings(int(62.0 * k), Color(0.55, 0.95, 1.0), int(10.0 * k))
	head.add_child(shop_title)

	var coin_ic := TextureRect.new()
	coin_ic.texture = TextureManager.get_texture("icon_coin")
	coin_ic.custom_minimum_size = Vector2(48.0 * k, 48.0 * k)
	coin_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(coin_ic)

	shop_coin_label = Label.new()
	shop_coin_label.text = "0"
	shop_coin_label.label_settings = _make_label_settings(int(54.0 * k), Color(1.0, 0.85, 0.25), int(8.0 * k))
	head.add_child(shop_coin_label)

	shop_wave_label = Label.new()
	shop_wave_label.label_settings = _make_label_settings(int(28.0 * k), Color(0.88, 0.92, 0.95), int(5.0 * k))
	shop_wave_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(shop_wave_label)

	shop_list = GridContainer.new()          # Runde 36: Grid statt Liste
	shop_list.columns = 2
	shop_list.add_theme_constant_override("h_separation", int(14.0 * k))
	shop_list.add_theme_constant_override("v_separation", int(10.0 * k))
	# Runde 34b: HBox als Rahmen, damit die Item-Liste mittig sitzt
	# (die Liste haengt sonst links im Scrollbereich)
	var shop_wrap := HBoxContainer.new()
	shop_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(shop_scroll)                                    # Runde 34b: richtige Reihenfolge
	shop_scroll.add_child(shop_wrap)
	shop_wrap.add_child(shop_list)

	shop_continue_row = HBoxContainer.new()
	shop_continue_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(shop_continue_row)

	shop_hint = Label.new()
	shop_hint.label_settings = _make_label_settings(22, Color(0.75, 0.82, 0.85), 4)
	shop_hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(shop_hint)

	shop_panel.visible = false

func _on_shop_buy(id: String) -> void:
	_sui("CLICK", "Kauf-Klick '%s' (Panel sichtbar=%s, paused=%s)" % [
		id, str(shop_panel.visible if shop_panel != null else false), str(get_tree().paused)])
	if game_manager:
		game_manager.buy_shop_item(id)
	else:
		_sui("FAIL", "Klick '%s' ohne game_manager - nichts passiert" % id)

func _on_shop_continue() -> void:
	if game_manager:
		game_manager._next_wave()

func hide_shop() -> void:
	if shop_panel:
		shop_panel.visible = false
	_shop_sig = ""
	_sui("HIDE", "Shop geschlossen (modal_open=%s)" % str(is_modal_open()))
	# Runde 28: nach dem Shop laeuft das Spiel weiter (Pausenmenue/Upgrade bleiben aussen vor)
	if not is_modal_open():
		get_tree().paused = false

func set_fps_label(on: bool) -> void:
	debug_fps = on
	if fps_label:
		fps_label.visible = on
	refresh_settings_ui()
	if fps_btn:
		fps_btn.text = "FPS-ANZEIGE: " + ("AN" if on else "AUS")


func _on_play_duo_pressed() -> void:
	if game_manager:
		game_manager.start_game(true)

func _on_restart_pressed() -> void:
	if game_manager:
		game_manager.restart_game(true)

func _on_menu_pressed() -> void:
	if game_manager:
		game_manager.restart_game(false)

func _on_exit_pressed() -> void:
	if game_manager:
		game_manager.exit_game()

# Boss-HP-Leiste oben
func set_ping_visible(on: bool) -> void:
	# Runde 34: Ping-Knopf nur im Mehrspieler
	if ping_btn != null:
		ping_btn.visible = on

func _on_ping_pressed() -> void:
	if game_manager != null and game_manager.has_method("send_ping"):
		game_manager.call("send_ping")

func update_target_arrow(show_it: bool, dir: Vector2) -> void:
	# Runde 31: kleiner Pfeil in Richtung des letzten Wellen-Monsters
	if target_arrow == null:
		if hud == null:
			return
		target_arrow = TextureRect.new()
		target_arrow.name = "TargetArrow"
		target_arrow.texture = TextureManager.get_texture("arrow_marker")
		target_arrow.custom_minimum_size = Vector2(60, 60)
		target_arrow.size = Vector2(60, 60)
		target_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		target_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		target_arrow.pivot_offset = Vector2(30, 30)
		target_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target_arrow.process_mode = Node.PROCESS_MODE_ALWAYS
		target_arrow.z_index = 60
		hud.add_child(target_arrow)
	if not show_it:
		target_arrow.visible = false
		return
	target_arrow.visible = true
	var c: Vector2 = hud.size * 0.5
	var r: float = minf(hud.size.x, hud.size.y) * 0.17
	target_arrow.position = c + dir.normalized() * r
	target_arrow.rotation = dir.angle() + PI * 0.5   # Textur zeigt nach oben

func update_boss_hp(cur: int, mx: int) -> void:
	if boss_bar == null:
		return
	boss_bar.visible = true
	boss_bar.max_value = mx
	boss_bar.value = cur
	if cur <= 0:
		var tw := boss_bar.create_tween()
		tw.tween_interval(0.8)
		tw.tween_property(boss_bar, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func(): boss_bar.visible = false; boss_bar.modulate.a = 1.0)
	elif boss_bar.modulate.a < 1.0:
		boss_bar.modulate.a = 1.0
		boss_bar.visible = true

func update_xp(new_level: int, cur: int, needed: int) -> void:
	if lvl_label:
		lvl_label.text = "LVL %d" % new_level
	if xp_bar:
		xp_bar.max_value = needed
		xp_bar.value = cur

# Wahlkarten-Overlay (Stil B: Spiel pausiert, 3 Upgrades zur Auswahl)
func show_upgrade_cards(options: Array) -> void:
	hide_upgrade_cards()
	# Runde 28: alles auf die Bildschirmgroesse skalieren - vorher ragten die Karten
	# (fix 330 px + 72-px-Titel) unten aus dem Bild
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var k: float = clampf(minf(vp.y / 820.0, vp.x / 1560.0), 0.50, 1.25)
	upgrade_overlay = Control.new()
	upgrade_overlay.name = "UpgradeOverlay"
	upgrade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrade_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(upgrade_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	upgrade_overlay.add_child(dim)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	upgrade_overlay.add_child(box)

	var title = Label.new()
	title.text = "LEVEL UP!"
	title.label_settings = _make_label_settings(int(72.0 * k), Color(1.0, 0.85, 0.1), int(14.0 * k))
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var sub = Label.new()
	sub.text = "Waehle ein Upgrade"
	sub.label_settings = _make_label_settings(int(30.0 * k), Color(0.92, 0.95, 0.92), int(6.0 * k))
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(34.0 * k))
	box.add_child(row)

	for opt in options:
		var id := str(opt["id"])
		var accent: Color = UPGRADE_COLORS.get(id, Color(0.35, 0.45, 0.65))
		var card = _make_pixel_button("", accent.darkened(0.62), 26)
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
		nm.label_settings = _make_label_settings(int(34.0 * k), accent.lightened(0.35), int(6.0 * k))
		nm.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(nm)

		var ds = Label.new()
		ds.text = str(opt["desc"])
		ds.label_settings = _make_label_settings(int(22.0 * k), Color(0.92, 0.94, 0.96), int(4.0 * k))
		ds.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(ds)

		if game_manager:
			var used: int = int(game_manager.upg_stacks.get(id, 0))
			var cap: int = int(opt.get("cap", 0))
			if cap > 0:
				var st = Label.new()
				st.text = "Stufe %d / %d" % [used, cap]
				st.label_settings = _make_label_settings(20, Color(1.0, 0.85, 0.4), 4)
				st.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
				st.mouse_filter = Control.MOUSE_FILTER_IGNORE
				col.add_child(st)
func _on_card_pressed(card: Button) -> void:
	var id: String = card.get_meta("id")
	hide_upgrade_cards()
	emit_signal("upgrade_chosen", id)

func hide_upgrade_cards() -> void:
	if upgrade_overlay != null and is_instance_valid(upgrade_overlay):
		upgrade_overlay.queue_free()
	upgrade_overlay = null

# ============================================================
# MITSPIELER-LISTE (bis zu 3 Mitspieler, Runde 10)
# ============================================================
func update_partner_slot(slot: int, hp: int, mx: int, weapon_name: String, shield: int, pname: String = "") -> void:
	partner_slots[slot] = { "hp": hp, "mx": mx, "weapon": weapon_name, "shield": shield, "name": pname }
	_render_partner_rows()

func clear_partner_slots() -> void:
	partner_slots.clear()
	if partner_list:
		for c in partner_list.get_children():
			c.queue_free()
	partner_rows.clear()
	if partner_list:
		partner_list.visible = false

func _make_partner_row(slot: int) -> Dictionary:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	partner_list.add_child(box)

	var tag := Label.new()
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color(1.0, 0.74, 0.5))
	box.add_child(tag)

	var hearts := HBoxContainer.new()
	hearts.add_theme_constant_override("separation", 2)
	box.add_child(hearts)

	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", 6)
	box.add_child(wrow)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wrow.add_child(icon)

	var wlabel := Label.new()
	wlabel.add_theme_font_size_override("font_size", 18)
	wlabel.add_theme_color_override("font_color", Color(0.9, 0.9, 0.72))
	wrow.add_child(wlabel)

	return { "box": box, "tag": tag, "hearts": hearts, "icon": icon, "wlabel": wlabel }

func _render_partner_rows() -> void:
	if partner_list == null:
		return
	# Entfernte Slots aufraeumen
	for s in partner_rows.keys():
		if not partner_slots.has(s):
			var r = partner_rows[s]
			if is_instance_valid(r["box"]):
				r["box"].queue_free()
			partner_rows.erase(s)
	var keys := partner_slots.keys()
	keys.sort()
	for s in keys:
		var d: Dictionary = partner_slots[s]
		if not partner_rows.has(s):
			partner_rows[s] = _make_partner_row(int(s))
		var r: Dictionary = partner_rows[int(s)]
		var tag: Label = r["tag"]
		tag.text = "P%d %s%s" % [int(s), str(d["name"]), ("   +%d Schild" % int(d["shield"])) if int(d["shield"]) > 0 else ""]
		var hearts: HBoxContainer = r["hearts"]
		while hearts.get_child_count() < int(d["mx"]):
			var h := TextureRect.new()
			h.custom_minimum_size = Vector2(24, 24)
			h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h.texture = TextureManager.get_texture("heart_full")
			hearts.add_child(h)
		while hearts.get_child_count() > int(d["mx"]):
			var last = hearts.get_child(hearts.get_child_count() - 1)
			hearts.remove_child(last)
			last.queue_free()
		for i in range(hearts.get_child_count()):
			var hh = hearts.get_child(i)
			if hh:
				hh.texture = TextureManager.get_texture("heart_full" if i < int(d["hp"]) else "heart_empty")
		var icon: TextureRect = r["icon"]
		var w := str(d["weapon"])
		icon.texture = TextureManager.get_texture("weapon_" + w) if w != "" else null
		(r["wlabel"] as Label).text = w
	partner_list.visible = not partner_slots.is_empty()

# ============================================================
# LOBBY (Runde 10): Host wartet, bis Mitspieler da sind -> START
# ============================================================
func _build_lobby() -> void:
	lobby_panel = ColorRect.new()
	lobby_panel.name = "LobbyPanel"
	lobby_panel.color = Color(0.04, 0.06, 0.09, 0.98)
	lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(lobby_panel)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 260.0
	panel.offset_right = -260.0
	panel.offset_top = 60.0
	panel.offset_bottom = -60.0
	panel.add_theme_stylebox_override("panel", _make_panel_sb(0.96, 32))
	lobby_panel.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	lobby_title = Label.new()
	lobby_title.text = "LOBBY"
	lobby_title.label_settings = _make_label_settings(78, Color(0.45, 0.95, 0.65), 12)
	lobby_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lobby_title)

	lobby_info = Label.new()
	lobby_info.label_settings = _make_label_settings(28, Color(0.9, 0.94, 0.9), 6)
	lobby_info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lobby_info)

	var list_title = Label.new()
	list_title.text = "SPIELER"
	list_title.label_settings = _make_label_settings(30, Color(1.0, 0.85, 0.35), 6)
	list_title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(list_title)

	lobby_rows_box = VBoxContainer.new()
	lobby_rows_box.alignment = BoxContainer.ALIGNMENT_CENTER
	lobby_rows_box.add_theme_constant_override("separation", 10)
	box.add_child(lobby_rows_box)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 26)
	box.add_child(btn_row)

	lobby_ready_btn = _make_styled_button("BEREIT", Color(0.25, 0.55, 0.30), 32)
	lobby_ready_btn.custom_minimum_size = Vector2(320, 84)
	lobby_ready_btn.pressed.connect(_on_lobby_ready_pressed)
	btn_row.add_child(lobby_ready_btn)

	lobby_start_btn = _make_styled_button("SPIEL STARTEN", Color(0.22, 0.62, 0.32), 34)
	lobby_start_btn.custom_minimum_size = Vector2(400, 92)
	lobby_start_btn.pressed.connect(_on_lobby_start_pressed)
	btn_row.add_child(lobby_start_btn)

	var leave := _make_styled_button("VERLASSEN", Color(0.45, 0.28, 0.28), 30)
	leave.custom_minimum_size = Vector2(280, 78)
	leave.pressed.connect(_on_lobby_leave_pressed)
	box.add_child(leave)

	var hint = Label.new()
	hint.text = "Der Host startet das Spiel fuer alle — beide betreten das Feld gleichzeitig."
	hint.label_settings = _make_label_settings(24, Color(0.8, 0.86, 0.86), 5)
	hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	lobby_panel.visible = false

func show_lobby(is_host: bool, slot: int) -> void:
	if lobby_panel == null:
		_build_lobby()
	lobby_host = is_host
	lobby_my_ready = false
	lobby_panel.visible = true
	if start_screen:
		start_screen.hide()
	if hud:
		hud.hide()
	if lan_panel:
		lan_panel.hide()
	if death_screen:
		death_screen.hide()
	if lobby_ready_btn:
		lobby_ready_btn.visible = not is_host
	if lobby_start_btn:
		lobby_start_btn.visible = is_host
	if is_host:
		lobby_title.text = "LOBBY — HOST"
		lobby_info.text = "Warte auf Mitspieler …  ·  IP: %s  ·  Port %d" % [NetManager.get_local_ip(), NetManager.ENET_PORT]
	else:
		lobby_title.text = "LOBBY"
		lobby_info.text = "Verbunden — warte auf den Host …"
	update_lobby(NetManager.lobby, NetManager.player_count, is_host)

func update_lobby(roster: Dictionary, max_players: int, is_host: bool) -> void:
	if lobby_panel == null or not lobby_panel.visible:
		return
	if lobby_rows_box == null:
		return
	for c in lobby_rows_box.get_children():
		c.queue_free()
	var my_id := multiplayer.get_unique_id()
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
		card.add_theme_stylebox_override("panel", _make_chip_sb(Color(0.20, 0.42, 0.30, 0.85) if ready else Color(0.22, 0.26, 0.34, 0.85)))
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
		nl.label_settings = _make_label_settings(30, Color(1, 1, 1), 5)
		t.add_child(nl)
		var sl := Label.new()
		sl.text = "Host" if int(s) == 1 else ("Bereit" if ready else "Noch nicht bereit")
		sl.label_settings = _make_label_settings(22, Color(0.6, 1.0, 0.7) if ready else Color(1.0, 0.75, 0.4), 4)
		t.add_child(sl)
		lobby_rows_box.add_child(card)

	if is_host:
		var full := connected >= (max_players - 1)
		lobby_info.text = "Warte auf Mitspieler …  ·  %d/%d verbunden  ·  IP: %s  ·  Port %d" % [connected + 1, max_players, NetManager.get_local_ip(), NetManager.ENET_PORT]
		if lobby_start_btn:
			lobby_start_btn.disabled = connected < 1
			lobby_start_btn.text = "SPIEL STARTEN (%d)" % (connected + 1)
	else:
		if lobby_ready_btn:
			lobby_ready_btn.text = "BEREIT" if not lobby_my_ready else "BEREIT ✓"
			lobby_ready_btn.modulate = Color(1.35, 1.35, 1.35) if lobby_my_ready else Color(1, 1, 1)

func hide_lobby() -> void:
	if lobby_panel:
		lobby_panel.visible = false

func _on_lobby_ready_pressed() -> void:
	lobby_my_ready = not lobby_my_ready
	NetManager.c_send_lobby_ready(lobby_my_ready)
	if lobby_ready_btn:
		lobby_ready_btn.text = "BEREIT ✓" if lobby_my_ready else "BEREIT"
		lobby_ready_btn.modulate = Color(1.35, 1.35, 1.35) if lobby_my_ready else Color(1, 1, 1)

func _on_lobby_start_pressed() -> void:
	if game_manager and game_manager.has_method("start_lan_run_as_host"):
		game_manager.start_lan_run_as_host()

func _on_lobby_leave_pressed() -> void:
	if game_manager and game_manager.has_method("leave_lobby"):
		game_manager.leave_lobby()
	else:
		NetManager.leave()
		hide_lobby()

# ============================================================
# GOLD / META-ANZEIGE (Runde 11)
# ============================================================
func animate_gold(from_v: int, to_v: int) -> void:
	if _gold_tween != null and _gold_tween.is_valid():
		_gold_tween.kill()
	set_start_gold(from_v)
	_gold_tween = create_tween()
	_gold_tween.tween_method(func(v: float): set_start_gold(int(v)), float(from_v), float(to_v), 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_start_gold(g: int) -> void:
	if start_screen == null:
		return
	var l = start_screen.find_child("GoldLabel", true, false)
	if l:
		l.text = "GOLD: %d" % g
	if shop_gold_chip:
		var l2 = shop_gold_chip.get_meta("label")
		if l2:
			l2.text = "GOLD: %d" % g
	if maps_gold_chip:
		var l3 = maps_gold_chip.get_meta("label")
		if l3:
			l3.text = "GOLD: %d" % g

# ============================================================
# SHOP-SEITE (Kisten + Direktkauf)
# ============================================================
func _open_shop_page() -> void:
	if shop_page == null:
		_create_shop_page()
	_close_pages()
	shop_page.show()
	refresh_shop_ui()

func _create_shop_page() -> void:
	shop_page = _make_page("SHOP")
	var box := _page_box(shop_page)

	shop_gold_chip = _make_chip("GOLD: 0", Color(0.34, 0.27, 0.12), 26)
	(box.add_child(shop_gold_chip))

	var sub = Label.new()
	sub.text = "Drei Kisten, drei Seltenheits-Mischungen. Gesammeltes wird ersetzt, Verbrauchsgueter gelten fuer den naechsten Run."
	sub.label_settings = _make_label_settings(18, Color(0.86, 0.90, 0.88), 4)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	# Runde 42/48: Grid statt HBox - 3 Kisten passen sauber nebeneinander
	# Runde 48: das Grid wird zentriert (vorher klebte es links)
	var crow = GridContainer.new()
	crow.columns = 3
	crow.add_theme_constant_override("h_separation", 26)
	crow.add_theme_constant_override("v_separation", 16)
	var crow_wrap := HBoxContainer.new()
	crow_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	crow_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(crow_wrap)
	crow_wrap.add_child(crow)

	chest_cards.clear()
	if game_manager != null:
		for tier in game_manager.CHESTS:
			# Runde 43: alle Karten exakt gleich breit -> symmetrisches Bild
			var card := VBoxContainer.new()
			card.alignment = BoxContainer.ALIGNMENT_CENTER
			card.add_theme_constant_override("separation", 6)
			# Runde 45: kompakter, damit die Seite in den Bildschirm passt
			card.custom_minimum_size = Vector2(430, 296)
			card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			crow.add_child(card)

			# Runde 40: Truhe in einem Raritaets-Rahmen (Comic-Karten-Look)
			var tier_edge := Color(0.55, 0.60, 0.68)
			var tier_fill := Color(0.10, 0.11, 0.16, 0.85)
			match str(tier["id"]):
				"wood":
					tier_edge = Color(0.86, 0.62, 0.30)
					tier_fill = Color(0.18, 0.12, 0.06, 0.92)
				"silver":
					tier_edge = Color(0.86, 0.90, 0.96)
					tier_fill = Color(0.10, 0.12, 0.16, 0.92)
				"gold":
					tier_edge = Color(1.0, 0.82, 0.20)
					tier_fill = Color(0.18, 0.13, 0.03, 0.92)
			var icon_frame := PanelContainer.new()
			# Runde 48: die Truhe war viel zu klein (nur 128px hoch im 340er Rahmen)
			icon_frame.custom_minimum_size = Vector2(400, 170)
			# Runde 43: Pixel-Kachel statt weichem Comic-Panel
			icon_frame.add_theme_stylebox_override("panel", _make_pixel_panel_sb(tier_fill, tier_edge, 5, 8))
			card.add_child(icon_frame)
			var ic := TextureRect.new()
			ic.texture = TextureManager.get_texture(str(tier["icon"]))
			# Runde 48: Truhen-Icon deutlich groesser (war 108px -> 186px)
			ic.custom_minimum_size = Vector2(150, 150)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_frame.add_child(ic)

			var nl := Label.new()
			nl.text = str(tier["name"])
			nl.label_settings = _make_label_settings(24, tier_edge, 6)
			nl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(nl)

			# Runde 42: Seltenheits-Mix der Kiste als farbige Leiste
			# (eine Zeile je Stufe, in der Seltenheitsfarbe)
			var mixl2 := HBoxContainer.new()
			mixl2.alignment = BoxContainer.ALIGNMENT_CENTER
			mixl2.add_theme_constant_override("separation", 12)
			card.add_child(mixl2)
			var mixd: Dictionary = tier.get("mix", { "common": 100 })
			for rr in ["common", "rare", "epic"]:
				var pct: int = int(mixd.get(rr, 0))
				if pct <= 0:
					continue
				var rl := Label.new()
				rl.text = "%d%% %s" % [pct, str(game_manager.RARITY_NAMES.get(rr, rr))]
				var rc: Color = game_manager.RARITY_COLORS.get(rr, Color.WHITE)
				rl.label_settings = _make_label_settings(17, rc, 4)
				rl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
				mixl2.add_child(rl)

			var cl := Label.new()
			cl.text = "\n".join(game_manager.chest_contents(tier))
			cl.label_settings = _make_label_settings(16, Color(0.86, 0.90, 0.90), 3)
			cl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			cl.custom_minimum_size = Vector2(400, 56)
			cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(cl)

			var tier_col := Color(0.22, 0.50, 0.38)
			match str(tier["id"]):
				"wood":
					tier_col = Color(0.48, 0.32, 0.16)
				"silver":
					tier_col = Color(0.44, 0.47, 0.54)
				"gold":
					tier_col = Color(0.68, 0.52, 0.14)
			# Runde 40: Comic-Kauf-Button in der Raritaets-Farbe
			var b := _make_pixel_button("KAUFEN + OEFFNEN  %d" % int(tier["price"]), tier_col, 22)
			b.custom_minimum_size = Vector2(400, 60)
			b.pressed.connect(_on_chest_buy.bind(str(tier["id"])))
			card.add_child(b)
			chest_cards.append({ "btn": b, "price": int(tier["price"]) })

	var bt = Label.new()
	bt.name = "DirectBuyLabel"
	bt.text = "DIREKTKAUF  (nicht selten — gilt fuer genau einen Run)"
	bt.label_settings = _make_label_settings(20, Color(1.0, 0.86, 0.40), 5)
	bt.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(bt)
	# Runde 43: die Boost-Reihe lief rechts aus dem Bild -> ScrollContainer
	# Runde 48: die Boost-Karten liegen in einem zentrierten GRID (4 Spalten).
	# Der ScrollContainer war die Ursache fuer die linksbuendige Anordnung -
	# er streckt seine Kinder immer auf die volle Breite.
	# Runde 48: 4 Spalten, aber jede Kachel fuellt ihre Spalte -> die
	# letzte Reihe (3 Kacheln) sitzt dadurch zentriert statt linksbuendig.
	var brow = GridContainer.new()
	brow.name = "BoostCards"
	brow.columns = 4
	brow.add_theme_constant_override("h_separation", 20)
	brow.add_theme_constant_override("v_separation", 12)
	brow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var brow_wrap := HBoxContainer.new()
	brow_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	brow_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(brow_wrap)
	brow_wrap.add_child(brow)

	boost_cards.clear()
	if game_manager != null:
		for bo in game_manager.BOOSTS:
			var card2 := VBoxContainer.new()
			card2.alignment = BoxContainer.ALIGNMENT_CENTER
			card2.add_theme_constant_override("separation", 4)
			# Runde 43: feste Kartenbreite -> die Reihe bleibt im Rahmen
			card2.custom_minimum_size = Vector2(280, 0)
			# Runde 48: fuellt seine Spalte, damit unvollstaendige Reihen
			# mittig sitzen (vorher klebten sie links)
			card2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			brow.add_child(card2)

			# Runde 43: Pixel-Kachel um jedes Item-Icon (einheitlicher Stil)
			var icon_frame2 := PanelContainer.new()
			icon_frame2.custom_minimum_size = Vector2(72, 72)
			icon_frame2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon_frame2.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.10, 0.12, 0.18, 0.92), Color(0.42, 0.50, 0.64), 4, 6))
			card2.add_child(icon_frame2)
			var ic2 := TextureRect.new()
			ic2.texture = TextureManager.get_texture(str(bo["icon"]))
			ic2.custom_minimum_size = Vector2(60, 60)
			ic2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_frame2.add_child(ic2)

			var nl2 := Label.new()
			nl2.text = str(bo["name"])
			nl2.label_settings = _make_label_settings(19, Color(0.95, 0.95, 0.95), 4)
			nl2.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			card2.add_child(nl2)

			# Runde 45: Beschreibung als Tooltip (spart Hoehe, die Seite passt jetzt)
			card2.tooltip_text = str(bo["desc"])

			var b2 := _make_pixel_button("KAUFEN %d" % int(bo["price"]), Color(0.30, 0.42, 0.62), 22)
			b2.custom_minimum_size = Vector2(240, 42)
			b2.pressed.connect(_on_boost_buy.bind(str(bo["id"])))
			card2.add_child(b2)
			# Runde 49c: Karte und ID mit merken - nur BESITZENE
			# Boosts duerfen im Direktkauf erscheinen.
			boost_cards.append({ "btn": b2, "price": int(bo["price"]), "id": str(bo["id"]), "card": card2 })

	var back := _make_pixel_button("ZURUECK", Color(0.30, 0.34, 0.44), 26)
	back.custom_minimum_size = Vector2(280, 58)
	back.pressed.connect(_close_pages)
	box.add_child(back)
	shop_page.hide()

func refresh_shop_ui() -> void:
	if game_manager == null or shop_page == null:
		return
	var l = shop_gold_chip.get_meta("label")
	if l:
		l.text = "GOLD: %d" % game_manager.gold
	for i in range(chest_cards.size()):
		var c: Dictionary = chest_cards[i]
		var b: Button = c["btn"]
		b.disabled = game_manager.gold < int(c["price"])
	# Runde 49c: Der Direktkauf zeigt NUR Boosts, die der Spieler
	# schon besitzt. Vorher standen alle da, auch wenn man noch
	# nichts gekauft hatte - die neuen Boosts kommen aus den Kisten.
	var owned_any: bool = false
	for i in range(boost_cards.size()):
		var c2: Dictionary = boost_cards[i]
		var b2: Button = c2["btn"]
		var card2: Control = c2.get("card")
		var bid2: String = str(c2.get("id", ""))
		var owned: int = int(game_manager.boosts.get(bid2, 0)) if game_manager.boosts.has(bid2) else 0
		if card2 != null:
			card2.visible = owned > 0
		if owned > 0:
			owned_any = true
			b2.text = "KAUFEN %d  (x%d)" % [int(c2["price"]), owned]
			b2.disabled = game_manager.gold < int(c2["price"])
		else:
			b2.text = "GEHT NICHT"
			b2.disabled = true
	var dlabel = shop_page.find_child("DirectBuyLabel", true, false) as Label
	if dlabel != null:
		dlabel.visible = owned_any

func _on_chest_buy(tier_id: String) -> void:
	if game_manager == null:
		return
	# Runde 48: Der Kauf oeffnet nur das Bestaetigungs-Fenster.
	# Die Kiste wird erst nach einem weiteren Klick geoeffnet.
	if int(game_manager.gold) < int(game_manager.chest_price(tier_id)):
		show_banner("ZU WENIG GOLD", Color(1.0, 0.5, 0.35))
		return
	chest_pending_tier = tier_id
	_show_chest_confirm(tier_id)


func _show_chest_confirm(tier_id: String) -> void:
	# Runde 48: eigenes Fenster - der ganze Fokus liegt auf der Kiste.
	if chest_overlay == null:
		_build_chest_overlay()
	chest_overlay.set_meta("mode", "confirm")
	# Title aendern
	for c in chest_overlay.find_children("*", "Label", true, false):
		if (c as Label).text == "KISTE GEOEFFNET":
			(c as Label).text = "KISTE VERWENDEN"
	# Kisten-Icon in der Buehne zeigen
	var tname: String = "HOLZKISTE"
	var tprice: int = 0
	for tier in game_manager.CHESTS:
		if str(tier["id"]) == tier_id:
			tname = str(tier["name"])
			tprice = int(tier["price"])
			chest_box_icon.texture = TextureManager.get_texture(str(tier["icon"]))
	if chest_box_icon != null:
		chest_box_icon.visible = true
		chest_box_icon.modulate.a = 1.0
		chest_box_icon.scale = Vector2(1, 1)
		chest_box_icon.rotation = 0.0
		chest_result_icon.visible = false
	# Bestaetigungs-UI
	if chest_confirm_btn != null:
		chest_confirm_btn.visible = true
		chest_confirm_btn.text = "OEFFNEN  (%d Gold)" % tprice
	if chest_ok_btn != null:
		chest_ok_btn.visible = false
	if chest_confirm_hint != null:
		chest_confirm_hint.visible = true
	if chest_item_box != null:
		for c in chest_item_box.get_children():
			chest_item_box.remove_child(c)
			c.queue_free()
	chest_item_rows.clear()
	if chest_result_label != null:
		chest_result_label.visible = false
	chest_overlay.visible = true


func _on_chest_confirm() -> void:
	# Runde 48: der zweite Klick - jetzt wird die Kiste wirklich geoeffnet
	if game_manager == null:
		return
	var res: Dictionary = game_manager.open_chest(chest_pending_tier)
	if not bool(res.get("ok", false)):
		show_banner("ZU WENIG GOLD", Color(1.0, 0.5, 0.35))
		_on_chest_ok()
		return
	SoundManager.play("levelup")
	show_chest_result(res)
	refresh_shop_ui()
	refresh_profile_ui()

func _on_boost_buy(bid: String) -> void:
	if game_manager == null:
		return
	if not game_manager.buy_boost(bid):
		show_banner("ZU WENIG GOLD", Color(1.0, 0.5, 0.35))
		return
	show_banner("GEKAUFT — gilt im naechsten Run", Color(0.55, 1.0, 0.7))

func _chest_icon_texture(res: Dictionary) -> Texture2D:
	# Bugfix: Farb-/Hut-Texturen werden erst bei Bedarf erzeugt — get_texture()
	# kennt sie nicht und lieferte null (Kiste zeigte nur den Namen).
	var kind := str(res.get("kind", ""))
	if kind == "color" or kind == "hat":
		return TextureManager.get_player_texture(int(res.get("color", 0)), int(res.get("hat", 0)))
	var key := str(res.get("icon", "chest"))
	var tex: Texture2D = TextureManager.get_texture(key)
	if tex == null:
		tex = TextureManager.get_texture("chest")
	return tex

func _build_chest_overlay() -> void:
	chest_overlay = ColorRect.new()
	chest_overlay.name = "ChestOverlay"
	chest_overlay.color = Color(0.02, 0.03, 0.05, 0.96)
	chest_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	chest_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	chest_overlay.z_index = 40
	add_child(chest_overlay)

	# Runde 48: ZWEI Modi im Overlay
	#  - "confirm": neues Fenster mit der Kiste + Bestaetigungs-Button
	#  - "result":  die geoeffnete Kiste mit den Items
	chest_overlay.set_meta("mode", "confirm")


	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	# Runde 48: grosses Fenster - der ganze Fokus liegt auf der Kiste
	panel.offset_left = -700.0
	panel.offset_right = 700.0
	# Runde 48: 800px reichen fuer Truhe + zwei Item-Zeilen - vorher
	# waren es 960px mit 250px Leerraum.
	panel.offset_top = -400.0
	panel.offset_bottom = 400.0
	# Runde 40: Comic-Panel mit schwarzer Kontur
	panel.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.06, 0.06, 0.11, 0.97), Color(0.98, 0.80, 0.20), 8, 18))
	chest_overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var t := Label.new()
	t.text = "KISTE GEOEFFNET"
	t.label_settings = _make_label_settings(64, Color(1.0, 0.86, 0.35), 12)
	t.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)

	# Buehne: Kiste (wackelt) + Preis (poppt) am selben Platz
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(1000, 230)
	box.add_child(stage)

	chest_box_icon = TextureRect.new()
	chest_box_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chest_box_icon.texture = TextureManager.get_texture("chest_gold")
	# Runde 48: per Anker mittig - eine feste Position landete links,
	# weil die Buehne auf die volle Panelbreite gestreckt wird.
	chest_box_icon.set_anchors_preset(Control.PRESET_CENTER)
	chest_box_icon.offset_left = -140.0
	chest_box_icon.offset_right = 140.0
	chest_box_icon.offset_top = -140.0
	chest_box_icon.offset_bottom = 140.0
	chest_box_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_box_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest_box_icon.pivot_offset = Vector2(140, 140)
	chest_box_icon.visible = false
	stage.add_child(chest_box_icon)

	chest_result_icon = TextureRect.new()
	chest_result_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Runde 48: auch dieses Icon per Anker mittig
	chest_result_icon.set_anchors_preset(Control.PRESET_CENTER)
	chest_result_icon.offset_left = -140.0
	chest_result_icon.offset_right = 140.0
	chest_result_icon.offset_top = -140.0
	chest_result_icon.offset_bottom = 140.0
	chest_result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest_result_icon.pivot_offset = Vector2(140, 140)
	chest_result_icon.visible = false
	stage.add_child(chest_result_icon)

	# Runde 48: die Item-Liste bekommt eigene Zeilen (Icon + Text
	# nebeneinander). Vorher lag alles in EINEM Label, sodass sich
	# Text und Icons ueberlagerten.
	# Runde 48: Die Item-Liste ist eine eigene, ZENTRIERTE Box.
	# Jede Item-Zeile ist ein eigenes Panel (Icon + Text nebeneinander).
	chest_item_box = VBoxContainer.new()
	chest_item_box.name = "ChestItems"
	chest_item_box.alignment = BoxContainer.ALIGNMENT_CENTER
	chest_item_box.add_theme_constant_override("separation", 12)
	chest_item_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chest_item_box.custom_minimum_size = Vector2(1240, 0)
	# Runde 48: die Box zentriert ihre Zeilen - ohne das bleiben sie
	# linksbuendig platziert.
	chest_item_box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(chest_item_box)

	chest_result_label = Label.new()
	chest_result_label.label_settings = _make_label_settings(30, Color(1, 1, 1), 6)
	chest_result_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	chest_result_label.custom_minimum_size = Vector2(600, 40)
	chest_result_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chest_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(chest_result_label)

	# Runde 48: Bestaetigungs-Button (oeffnet die Kiste) und
	# Ergebnis-Button (schliesst das Fenster)
	chest_confirm_btn = _make_comic_button("OEFFNEN", Color(0.92, 0.62, 0.12), 34)
	chest_confirm_btn.custom_minimum_size = Vector2(520, 100)
	# Runde 48: Buttons zentrieren (sonst spannen sie ueber die ganze Breite)
	chest_confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chest_confirm_btn.pressed.connect(_on_chest_confirm)
	box.add_child(chest_confirm_btn)

	chest_ok_btn = _make_comic_button("WEITER", Color(0.20, 0.60, 0.36), 32)
	chest_ok_btn.custom_minimum_size = Vector2(440, 96)
	chest_ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chest_ok_btn.pressed.connect(_on_chest_ok)
	box.add_child(chest_ok_btn)

	# Hinweis-Text fuer den Bestaetigungs-Schritt
	chest_confirm_hint = Label.new()
	chest_confirm_hint.label_settings = _make_label_settings(24, Color(0.82, 0.88, 0.94), 5)
	chest_confirm_hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	chest_confirm_hint.text = "Klicke auf OEFFNEN, um die Kiste zu verwenden"
	chest_confirm_hint.custom_minimum_size = Vector2(700, 34)
	chest_confirm_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(chest_confirm_hint)

	chest_overlay.visible = false

func _play_chest_open_animation(res: Dictionary) -> void:
	# Runde 48: NEUER Ablauf im Stil von Clash Royal / CS:GO.
	#   1) Truhe bebt und waechst (Scale-Punch)
	#   2) Deckel springt nach oben weg
	#   3) Lichtstrahl waechst aus der Truhe
	#   4) Items SPRUDELN in einem Bogen nach oben (Fountain)
	#   5) Items fallen auf IHREN Platz in der Item-Liste
	#   6) Die Item-Zeile erscheint, wenn ihr Item ankommt
	#
	# Wichtig: die fliegenden Items liegen im OVERLAY, nicht in der
	# Buehne - sonst fliegen sie in falsche Koordinaten.
	if chest_overlay == null or chest_box_icon == null:
		return
	var rar: String = str(res.get("rarity", "common"))
	var ov_pos: Vector2 = chest_overlay.get_global_rect().position
	var chest_center: Vector2 = chest_box_icon.get_global_rect().get_center() - ov_pos

	# --- Zielpositionen: Mitte der Icon-Kachel jeder Item-Zeile ---
	var targets: Array = []
	for row_v in chest_item_rows:
		var row: Control = row_v
		var fr = row.find_child("ItemIconFrame", true, false) as Control
		if fr != null:
			targets.append(fr.get_global_rect().get_center() - ov_pos)
		else:
			targets.append(chest_center)

	# --- 1) Truhe bebt und waechst ---
	var base_scale: Vector2 = chest_box_icon.scale
	var shake := chest_box_icon.create_tween()
	shake.tween_property(chest_box_icon, "scale", Vector2(1.12, 0.90), 0.07)
	shake.tween_property(chest_box_icon, "scale", Vector2(0.94, 1.10), 0.07)
	shake.tween_property(chest_box_icon, "scale", Vector2(1.08, 0.96), 0.07)
	shake.tween_property(chest_box_icon, "scale", Vector2(1.0, 1.0), 0.07)
	shake.tween_callback(func():
		var big := chest_box_icon.create_tween()
		big.tween_property(chest_box_icon, "scale", Vector2(1.18, 1.18), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		big.tween_property(chest_box_icon, "scale", base_scale, 0.10))

	# Runde 48: Die Truhe verblasst, sobald die Items draussen sind.
	# Der Deckel ist eine Kopie, die Truhe selbst verschwindet komplett.
	var fade := chest_box_icon.create_tween()
	fade.tween_interval(0.74)
	fade.tween_property(chest_box_icon, "scale", Vector2(0.88, 0.88), 0.20)
	fade.tween_property(chest_box_icon, "modulate:a", 0.0, 0.22)
	fade.tween_callback(func(): chest_box_icon.visible = false)

	# --- 2) Deckel springt nach oben weg ---
	# Runde 48: Der Deckel ist eine exakte Kopie der Truhen-Groesse
	# (gleiche Anker + Offsets) - vorher lag er schief auf der Truhe.
	var lid := TextureRect.new()
	lid.texture = chest_box_icon.texture
	lid.set_anchors_preset(Control.PRESET_CENTER)
	lid.offset_left = chest_box_icon.offset_left
	lid.offset_right = chest_box_icon.offset_right
	lid.offset_top = chest_box_icon.offset_top
	lid.offset_bottom = chest_box_icon.offset_bottom
	lid.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lid.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lid.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lid.pivot_offset = Vector2(140, 140)
	lid.modulate = Color(1, 1, 1, 0.95)
	chest_overlay.add_child(lid)
	var ltw := lid.create_tween()
	ltw.set_parallel(true)
	# Der Deckel springt nach oben weg und dreht sich dabei
	ltw.tween_property(lid, "offset_top", lid.offset_top - 250.0, 0.55).set_delay(0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ltw.tween_property(lid, "offset_bottom", lid.offset_bottom - 250.0, 0.55).set_delay(0.34)
	ltw.tween_property(lid, "rotation", 0.55, 0.55).set_delay(0.34)
	ltw.tween_property(lid, "scale", Vector2(0.80, 0.80), 0.55).set_delay(0.34)
	ltw.tween_property(lid, "modulate:a", 0.0, 0.30).set_delay(0.64)
	ltw.chain().tween_callback(lid.queue_free)

	# --- 3) Lichtstrahl aus der Truhe ---
	# Runde 48: Kein Balken-Strahl mehr (der ragte in die Item-Liste).
	# Stattdessen ein weicher Licht-Kreis (Textur) hinter der Truhe.
	# Runde 48: Kein dauerhafter Strahl-Hintergrund. Stattdessen ein
	# kurzer Blitz, der zusammen mit der Truhe wieder verschwindet.
	var flash_box := ColorRect.new()
	flash_box.color = Color(1.0, 0.95, 0.70, 0.0)
	# Runde 48: kleiner Blitz, der NUR nach oben aus der Truhe kommt -
	# vorher ragte der 240er-Balken in die Item-Liste.
	flash_box.size = Vector2(200, 110)
	flash_box.position = chest_center - Vector2(100, 110)
	flash_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_overlay.add_child(flash_box)
	var btw := flash_box.create_tween()
	btw.tween_property(flash_box, "color", Color(1.0, 0.95, 0.70, 0.0), 0.18).set_delay(0.34)
	btw.tween_property(flash_box, "color", Color(1.0, 0.95, 0.70, 0.55), 0.09).set_delay(0.52)
	btw.tween_property(flash_box, "color", Color(1.0, 0.95, 0.70, 0.0), 0.22).set_delay(0.61)
	btw.chain().tween_callback(flash_box.queue_free)

	# --- 4/5) Items sprudeln nach oben und fallen auf ihren Platz ---
	var items: Array = res.get("items", [])
	var count: int = items.size()
	for i in range(count):
		var it: Dictionary = items[i]
		var icon_key: String = str(it.get("icon", "icon_coin"))
		var tex = TextureManager.get_texture(icon_key)
		if tex == null:
			continue
		var fly := TextureRect.new()
		fly.texture = tex
		fly.size = Vector2(110, 110)
		fly.position = chest_center - Vector2(55, 55)
		fly.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fly.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fly.pivot_offset = Vector2(55, 55)
		chest_overlay.add_child(fly)

		# Ziel: die Icon-Kachel dieses Items
		var tgt: Vector2 = chest_center
		if i < targets.size():
			tgt = targets[i]
		# Start: leicht seitlich versetzt (sprudelt breit)
		var start_off := Vector2(-70.0 + float(i) * 140.0, 0.0)
		# Bogen-Spitze: hoch ueber der Truhe
		var apex: Vector2 = chest_center + start_off + Vector2(0, -230.0)

		var delay: float = 0.42 + float(i) * 0.13
		var ftw := fly.create_tween()
		ftw.set_parallel(true)
		# Phase 1: hoch springen (Fountain)
		ftw.tween_property(fly, "position", apex, 0.30).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ftw.tween_property(fly, "scale", Vector2(1.35, 1.35), 0.30).set_delay(delay)
		ftw.tween_property(fly, "rotation", 1.2, 0.30).set_delay(delay)
		# Phase 2: auf den Platz fallen
		ftw.tween_property(fly, "position", tgt - Vector2(55, 55), 0.34).set_delay(delay + 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ftw.tween_property(fly, "scale", Vector2(0.95, 0.95), 0.34).set_delay(delay + 0.30)
		ftw.tween_property(fly, "rotation", 2.4, 0.34).set_delay(delay + 0.30)
		# Phase 3: verschwinden, die Zeile erscheint
		ftw.tween_property(fly, "modulate:a", 0.0, 0.12).set_delay(delay + 0.60)
		ftw.chain().tween_callback(fly.queue_free)
		# Die Item-Zeile wird sichtbar, wenn ihr Item ankommt
		if i < chest_item_rows.size():
			var row: Control = chest_item_rows[i]
			var rt: Tween = row.create_tween()
			rt.tween_interval(delay + 0.52)
			rt.tween_property(row, "modulate:a", 1.0, 0.16)

	# --- 6) Funken-Ring (Staerke nach Seltenheit) ---
	var spark_count: int = 8
	var spark_col: Color = Color(0.85, 0.85, 0.85)
	var flash: float = 0.0
	if rar == "rare":
		spark_count = 14
		spark_col = Color(0.40, 0.72, 1.0)
	elif rar == "epic":
		spark_count = 22
		spark_col = Color(1.0, 0.72, 0.25)
		flash = 0.35
	for i in range(spark_count):
		var sp := ColorRect.new()
		sp.color = spark_col
		sp.size = Vector2(12, 12)
		sp.position = chest_center - Vector2(6, 6)
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chest_overlay.add_child(sp)
		var ang: float = TAU * float(i) / float(spark_count) + randf() * 0.3
		var dist: float = randf_range(130.0, 250.0)
		var stw := sp.create_tween()
		stw.set_parallel(true)
		stw.tween_property(sp, "position", chest_center + Vector2(cos(ang), sin(ang)) * dist, 0.7).set_delay(0.40)
		stw.tween_property(sp, "modulate:a", 0.0, 0.5).set_delay(0.40)
		stw.tween_property(sp, "scale", Vector2(0.3, 0.3), 0.7).set_delay(0.40)
		stw.chain().tween_callback(sp.queue_free)

	# --- 7) Bildschirm-Blitz bei episch ---
	if flash > 0.0:
		var fl := ColorRect.new()
		fl.set_anchors_preset(Control.PRESET_FULL_RECT)
		fl.color = Color(1.0, 0.92, 0.60, 0.0)
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chest_overlay.add_child(fl)
		var flt := fl.create_tween()
		flt.tween_property(fl, "color", Color(1.0, 0.92, 0.60, flash), 0.10).set_delay(0.40)
		flt.tween_property(fl, "color", Color(1.0, 0.92, 0.60, 0.0), 0.45).set_delay(0.50)
		flt.chain().tween_callback(fl.queue_free)

func show_chest_result(res: Dictionary) -> void:
	if chest_overlay == null:
		_build_chest_overlay()
	var tex := _chest_icon_texture(res)
	var kind := str(res.get("kind", ""))
	var is_new: bool = (kind == "color" or kind == "hat" or kind == "map" or kind == "rig")
	chest_result_icon.texture = tex
	# Runde 48: Das grosse Ergebnis-Icon entfaellt - die Item-Liste
	# traegt das Ergebnis. Vorher lag der Herz-Icon ueber der Liste.
	chest_result_icon.visible = false
	# Die Truhe ist in der ANIMATION sichtbar und blendet dort aus
	chest_box_icon.visible = true
	chest_box_icon.modulate.a = 1.0
	# Runde 48: jedes Item bekommt eine EIGENE Zeile (Icon + Text).
	# Vorher stand alles in einem Label und ueberlagerte sich mit den
	# Icons der Animation.
	var item_list: Array = res.get("items", [])
	var txt: String = ""
	# alte Zeilen entfernen
	if chest_item_box != null:
		for c in chest_item_box.get_children():
			chest_item_box.remove_child(c)
			c.queue_free()
	if item_list.size() > 0:
		for g in item_list:
			var gl: String = str(g.get("label", ""))
			var gk: String = str(g.get("kind", ""))
			var gicon: String = str(g.get("icon", ""))
			var gnew: bool = (gk == "color" or gk == "rig" or gk == "hat" or gk == "map")
			var gclean: String = gl
			if gclean.begins_with("NEU!"):
				gclean = gclean.substr(4).strip_edges()
			# Runde 48: JEDE Item-Zeile ist ein eigenes Pixel-Panel.
			# So steht jede Zeile mittig untereinander und Text/Icon
			# ueberlagern sich nicht.
			# Runde 48: Die Zeile schrumpft auf ihren Inhalt und sitzt
			# mittig. Vorher spannte sie 900px und der Inhalt klebte links.
			var row := PanelContainer.new()
			row.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.10, 0.12, 0.18, 0.92), Color(0.42, 0.50, 0.64), 4, 8))
			# Runde 48: alle Zeilen gleich breit (760px) und mittig -
			# vorher waren sie unterschiedlich breit und linksbuendig.
			row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			row.custom_minimum_size = Vector2(760, 136)
			var rowbox := HBoxContainer.new()
			rowbox.alignment = BoxContainer.ALIGNMENT_CENTER
			rowbox.add_theme_constant_override("separation", 22)
			row.add_child(rowbox)
			# Icon-Kachel
			var frame := PanelContainer.new()
			frame.name = "ItemIconFrame"
			frame.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.16, 0.19, 0.28, 0.95), Color(0.62, 0.72, 0.88), 3, 3))
			frame.custom_minimum_size = Vector2(118, 118)
			frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			rowbox.add_child(frame)
			var ic := TextureRect.new()
			var itex = TextureManager.get_texture(gicon) if gicon != "" else null
			if itex == null:
				itex = TextureManager.get_texture("icon_coin")
			ic.texture = itex
			ic.custom_minimum_size = Vector2(106, 106)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			frame.add_child(ic)
			# Text
			var lbl := Label.new()
			lbl.text = ("NEU!  " if gnew else "") + gclean
			lbl.label_settings = _make_label_settings(32, Color(1, 1, 1), 6)
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
			# Runde 48: das Label schrumpft auf seinen Text - vorher
			# erzwang die feste 480px-Breite einen leeren Rand in der
			# Zeile, in dem der Icon allein stand.
			lbl.custom_minimum_size = Vector2(560, 128)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			rowbox.add_child(lbl)
			chest_item_box.add_child(row)
			# Runde 48: Die Zeile startet unsichtbar und wird sichtbar,
			# wenn ihr Item ankommt. KEIN Scale auf der Zeile - sonst
			# waere die Zielposition der fliegenden Items nicht stabil.
			row.modulate.a = 0.0
			chest_item_rows.append(row)
		txt = ""
	else:
		txt = ("NEU!  " if is_new else "") + str(res.get("label", ""))
	chest_result_label.text = txt
	# Runde 37: Seltenheitsfarbe (grau/blau/lila/gold) statt nur "neu"
	var rcol: Color = Color(1, 1, 1)
	if game_manager != null and game_manager.has_method("rarity_color"):
		rcol = game_manager.call("rarity_color", str(res.get("rarity", "common")))
	chest_result_label.add_theme_color_override("font_color", Color(0.62, 1.0, 0.80) if is_new else rcol)
	chest_result_icon.modulate = rcol

	# Runde 48: Ergebnis-Modus - Bestaetigungs-Knopf weg, WEITER-Button da
	chest_overlay.set_meta("mode", "result")
	for c in chest_overlay.find_children("*", "Label", true, false):
		if (c as Label).text == "KISTE VERWENDEN":
			(c as Label).text = "KISTE GEOEFFNET"
	if chest_confirm_btn != null:
		chest_confirm_btn.visible = false
	if chest_ok_btn != null:
		chest_ok_btn.visible = true
	if chest_confirm_hint != null:
		chest_confirm_hint.visible = false
	if chest_result_label != null:
		chest_result_label.visible = true
	chest_overlay.visible = true
	# Runde 43: Kisten-Animation abspielen
	_play_chest_open_animation(res)
	# Runde 38: Flashy-Overglow + Funken-Ring hinter dem Inhalt
	var glow := ColorRect.new()
	glow.name = "ChestGlow"
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(1, 0.92, 0.55, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_overlay.add_child(glow)
	var gcol: Color = Color(1, 1, 1)
	if game_manager != null and game_manager.has_method("rarity_color"):
		gcol = game_manager.call("rarity_color", str(res.get("rarity", "common")))
	glow.color = Color(gcol.r, gcol.g, gcol.b, 0.0)
	var gtw := glow.create_tween()
	gtw.tween_property(glow, "color", Color(gcol.r, gcol.g, gcol.b, 0.42), 0.18)
	gtw.tween_property(glow, "color", Color(gcol.r, gcol.g, gcol.b, 0.0), 0.55)
	gtw.tween_callback(glow.queue_free)
	# Runde 39: Deckel fliegt weg + Funken + RARE-Punch
	var icon_node: TextureRect = null
	for c in chest_overlay.find_children("*", "TextureRect", true, false):
		icon_node = c
		break
	if icon_node != null:
		var lid := TextureRect.new()
		lid.texture = icon_node.texture
		lid.size = icon_node.size
		lid.position = icon_node.position
		lid.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lid.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chest_overlay.add_child(lid)
		var ltw := lid.create_tween()
		ltw.set_parallel(true)
		ltw.tween_property(lid, "position:y", icon_node.position.y - 190.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ltw.tween_property(lid, "rotation", 1.1, 0.75)
		ltw.tween_property(lid, "modulate:a", 0.0, 0.75)
		ltw.chain().tween_callback(lid.queue_free)
		# Funken
		for i in range(10):
			var sp := ColorRect.new()
			sp.color = gcol
			sp.size = Vector2(9, 9)
			sp.position = icon_node.position + icon_node.size * 0.5
			sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chest_overlay.add_child(sp)
			var ang: float = TAU * float(i) / 10.0 + randf() * 0.4
			var dist: float = randf_range(90.0, 190.0)
			var stw := sp.create_tween()
			stw.set_parallel(true)
			stw.tween_property(sp, "position", sp.position + Vector2(cos(ang), sin(ang)) * dist, 0.65)
			stw.tween_property(sp, "modulate:a", 0.0, 0.65)
			stw.chain().tween_callback(sp.queue_free)
	# RARE!-Punch
	var rar: String = str(res.get("rarity", "common"))
	if rar == "rare" or rar == "epic" or rar == "legendary":
		var punch := Label.new()
		punch.text = "RARE!" if rar == "rare" else ("EPIC!!" if rar == "epic" else "LEGENDARY!!!")
		punch.label_settings = _make_label_settings(64, gcol, 6)
		punch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		punch.position = Vector2(200, 40)
		punch.scale = Vector2(2.4, 2.4)
		chest_overlay.add_child(punch)
		var ptw := punch.create_tween()
		ptw.set_parallel(true)
		ptw.tween_property(punch, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ptw.tween_property(punch, "modulate:a", 0.0, 1.0).set_delay(0.5)
		ptw.chain().tween_callback(punch.queue_free)

func _on_chest_ok() -> void:
	# Runde 48: Fenster schliessen und zurueck in den Shop
	if chest_overlay != null:
		chest_overlay.visible = false
	chest_pending_tier = ""
	if chest_overlay:
		chest_overlay.visible = false

# ============================================================
# KARTEN-SEITE
# ============================================================
func _open_maps_page() -> void:
	if maps_page == null:
		_create_maps_page()
	_close_pages()
	maps_page.show()
	refresh_maps_ui()

func _create_maps_page() -> void:
	maps_page = _make_page("KARTEN")
	var box := _page_box(maps_page)

	maps_gold_chip = _make_chip("GOLD: 0", Color(0.34, 0.27, 0.12), 34)
	box.add_child(maps_gold_chip)

	var sub = Label.new()
	sub.text = "Jede Karte ist eine eigene Welt mit eigenen Monstern. Freischalten per Schalter (XP in einem Run) oder mit Gold."
	sub.label_settings = _make_label_settings(22, Color(0.86, 0.90, 0.88), 5)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	# Runde 48: alle Karten bekommen dieselbe Hoehe (size_flags_vertical
	# FILL) und dieselbe Breite - vorher waren sie versetzt.
	var crow = HBoxContainer.new()
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	crow.add_theme_constant_override("separation", 18)
	crow.size_flags_vertical = Control.SIZE_FILL
	box.add_child(crow)

	maps_cards.clear()
	if game_manager != null:
		for m in game_manager.MAPS:
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
			map_frame.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.08, 0.10, 0.16, 0.92), Color(0.36, 0.78, 0.92), 5, 8))
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
			nl.label_settings = _make_label_settings(26, Color(1.0, 0.86, 0.40), 6)
			nl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(nl)

			var dl := Label.new()
			dl.text = str(m["desc"])
			dl.label_settings = _make_label_settings(18, Color(0.84, 0.88, 0.88), 4)
			dl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			dl.custom_minimum_size = Vector2(280, 62)
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(dl)

			var sl := Label.new()
			sl.label_settings = _make_label_settings(20, Color(0.7, 1.0, 0.7), 4)
			sl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			# Runde 48: feste Hoehe -> alle Karten gleich hoch
			sl.custom_minimum_size = Vector2(286, 30)
			card.add_child(sl)

			# Schalter-Block (Runde 12): Bedingung + Fortschritt
			var gl := Label.new()
			gl.label_settings = _make_label_settings(16, Color(1.0, 0.86, 0.45), 4)
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
			# Runde 48: feste Hoehe -> die Zeilen der Karten bleiben
			# untereinander buendig (die ERDE-Karte hat keine Jahreszeiten)
			srow.custom_minimum_size = Vector2(286, 40)
			card.add_child(srow)
			var sbtns: Array = []
			if game_manager != null and game_manager.seasons_enabled(str(m["id"])):
				for se in game_manager.SEASONS:
					var sb2 := _make_styled_button(str(se["name"]).substr(0, 4), Color(0.20, 0.24, 0.30), 17)
					sb2.custom_minimum_size = Vector2(68, 40)
					sb2.tooltip_text = str(se["name"]) + " — " + str(se["desc"])
					sb2.pressed.connect(_on_season_pressed.bind(str(m["id"]), str(se["id"])))
					srow.add_child(sb2)
					sbtns.append(sb2)
			var season_hint := Label.new()
			season_hint.label_settings = _make_label_settings(15, Color(0.72, 0.90, 1.0), 4)
			season_hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			season_hint.custom_minimum_size = Vector2(286, 30)
			season_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(season_hint)

			var b := _make_styled_button("WAEHLEN", Color(0.24, 0.52, 0.42), 22)
			b.custom_minimum_size = Vector2(286, 60)
			b.pressed.connect(_on_map_action.bind(str(m["id"])))
			card.add_child(b)
			maps_cards.append({ "btn": b, "status": sl, "gate_label": gl, "gate_bar": gb,
				"season_btns": sbtns, "season_hint": season_hint, "id": str(m["id"]) })

	var back := _make_styled_button("ZURUECK", Color(0.35, 0.38, 0.46), 30)
	back.custom_minimum_size = Vector2(300, 72)
	back.pressed.connect(_close_pages)
	box.add_child(back)
	maps_page.hide()

func refresh_maps_ui() -> void:
	if game_manager == null or maps_page == null:
		return
	var l = maps_gold_chip.get_meta("label")
	if l:
		l.text = "GOLD: %d" % game_manager.gold
	for c in maps_cards:
		var mid: String = c["id"]
		var d: Dictionary = game_manager.map_data(mid)
		var unlocked: bool = game_manager.is_map_unlocked(mid)
		var active: bool = game_manager.active_map == mid
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
			if pre != "" and not game_manager.is_map_unlocked(pre):
				gl.text = "Erst " + str(game_manager.map_data(pre)["name"]) + " freischalten"
				gb.visible = false
			else:
				gl.text = "SCHALTER: " + str(need) + " XP in EINEM Run  (Bestwert " + str(game_manager.best_run_xp) + ")"
				gb.visible = true
				gb.max_value = need
				gb.value = mini(game_manager.best_run_xp, need)
		# Jahreszeiten-Kacheln
		if c.has("season_btns") and (c["season_btns"] as Array).size() > 0:
			var planet: String = c["id"]
			var sel: String = str(game_manager.planet_season(planet))
			var btns: Array = c["season_btns"]
			for i in range(btns.size()):
				var se: Dictionary = game_manager.SEASONS[i]
				var sid := str(se["id"])
				var un: bool = game_manager.is_season_unlocked(planet, sid)
				var bb: Button = btns[i]
				bb.disabled = not un
				var col: Color = se["color"]
				if not un:
					bb.modulate = Color(0.55, 0.55, 0.60)
					bb.tooltip_text = str(se["name"]) + " — gesperrt: " + str(game_manager.season_gate_need(planet, sid)) + " XP in einem Run auf " + str(d["name"])
				else:
					bb.modulate = Color(col.r * 1.25, col.g * 1.25, col.b * 1.25) if sid == sel else Color(0.85, 0.85, 0.90)
			var hint: Label = c["season_hint"]
			if planet == game_manager.active_map:
				hint.text = "Aktiv: " + game_manager.season_name(sel)
			else:
				hint.text = ""
			var ptxt: String = str(game_manager.season_progress_text(planet))
			if ptxt != "":
				hint.text = (hint.text + "  ·  " if hint.text != "" else "") + "Schalter: " + ptxt
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
			b.disabled = game_manager.gold < price

func _on_season_pressed(planet: String, sid: String) -> void:
	if game_manager == null:
		return
	if not game_manager.is_season_unlocked(planet, sid):
		show_banner("JAHRESZEIT NOCH GESPERRT", Color(1.0, 0.6, 0.4))
		return
	if not game_manager.is_map_unlocked(planet):
		show_banner("ERST " + str(game_manager.map_data(planet)["name"]) + " FREISCHALTEN", Color(1.0, 0.6, 0.4))
		return
	game_manager.set_active_map(planet)
	game_manager.set_active_season(planet, sid)
	show_banner(str(game_manager.map_data(planet)["name"]) + " · " + game_manager.season_name(sid), Color(0.6, 1.0, 0.8))
	refresh_maps_ui()

func _on_map_action(mid: String) -> void:
	if game_manager == null:
		return
	if game_manager.is_map_unlocked(mid):
		game_manager.set_active_map(mid)
		show_banner("KARTE GEWAEHLT: " + str(game_manager.map_data(mid)["name"]), Color(0.6, 1.0, 0.8))
	else:
		if game_manager.buy_map(mid):
			show_banner("KARTE FREIGESCHALTET!", Color(0.6, 1.0, 0.8))
		else:
			show_banner("ZU WENIG GOLD", Color(1.0, 0.5, 0.35))
	refresh_maps_ui()
	refresh_shop_ui()
	if game_manager:
		var l = maps_gold_chip.get_meta("label")
		if l:
			l.text = "GOLD: %d" % game_manager.gold

# ============================================================
# Runde 37: SAMMLUNG (Cosmetics-Uebersicht)
# ============================================================

func _readonly_tile(b: Button) -> void:
	# Runde 62: Kachel nur anzeigen - kein Klick, kein Hover.
	# "disabled" bekommt die normale Optik, damit nichts grau wirkt.
	b.focus_mode = Control.FOCUS_NONE
	var sb := b.get_theme_stylebox("normal")
	if sb != null:
		b.add_theme_stylebox_override("disabled", sb)
	b.disabled = true


func show_collection() -> void:
	# Runde 37: Sammlungs-Screen (alle Farben + Huete, Fortschritt, Equip)
	# Runde 43: Inhalt danach einpassen
	if collection_page == null:
		_build_collection_page()
	_close_pages()
	collection_page.show()
	refresh_collection_ui()

func _build_collection_page() -> void:
	collection_page = _make_page("SAMMLUNG")
	# Runde 37: den vorhandenen Box-Container der Seite nutzen
	# (Panel = child 1 der Seite, darin die VBox = child 0)
	var panel := collection_page.get_child(1) as PanelContainer
	var box: VBoxContainer = panel.get_child(0) as VBoxContainer

	var info := Label.new()
	info.name = "CollectionInfo"
	info.label_settings = _make_label_settings(24, Color(1.0, 0.86, 0.40), 5)
	info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	# Runde 48: DREI getrennte Sektionen (je Header + eigenes, zentriertes
	# Kachel-Grid). Vorher lagen die Header als Zelle im selben Grid und
	# zerschoben das Raster.
	var sections := VBoxContainer.new()
	sections.name = "CollectionSections"
	sections.alignment = BoxContainer.ALIGNMENT_CENTER
	sections.add_theme_constant_override("separation", 10)
	box.add_child(sections)

	var back := _make_comic_button("ZURUECK", Color(0.26, 0.34, 0.52), 28)
	back.pressed.connect(func(): show_start_screen())
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_child(back)
	box.add_child(brow)

func _refresh_skin_buttons() -> void:
	# Runde 43: Skin-Kacheln aktualisieren - Icon, Rahmen, AKTIV-Marke
	if game_manager == null:
		return
	for i in range(skin_buttons.size()):
		var sk = skin_buttons[i]
		if sk == null:
			continue
		var owned: bool = game_manager.unlocked_rigs.has(i)
		var equipped: bool = int(game_manager.p_rig) == i
		var rar: String = str(game_manager.RIG_RARITY[i]) if i < game_manager.RIG_RARITY.size() else "rare"
		var rcol: Color = game_manager.RARITY_COLORS.get(rar, Color(0.5, 0.6, 0.8))
		# Icon: Skin in der aktuell gewaehlten Farbe
		var tex = game_manager.skin_preview_texture(i)
		if tex != null:
			sk.icon = tex
		if equipped:
			# aktiv = goldener Rahmen + heller
			sk.add_theme_stylebox_override("normal", _make_pixel_panel_sb(Color(0.34, 0.26, 0.10), Color(1.0, 0.84, 0.24), 5, 8))
			sk.add_theme_stylebox_override("hover", _make_pixel_panel_sb(Color(0.40, 0.31, 0.12), Color(1.0, 0.88, 0.34), 5, 8))
			sk.add_theme_stylebox_override("pressed", _make_pixel_panel_sb(Color(0.28, 0.22, 0.08), Color(1.0, 0.84, 0.24), 5, 8))
			sk.modulate = Color(1.18, 1.18, 1.18)
			sk.tooltip_text = str(TextureManager.RIG_NAMES[i]) + "  ·  " + str(game_manager.RARITY_NAMES.get(rar, rar)) + "  (AKTIV)"
		elif owned:
			sk.add_theme_stylebox_override("normal", _make_pixel_panel_sb(Color(0.16, 0.14, 0.22), rcol, 4, 8))
			sk.add_theme_stylebox_override("hover", _make_pixel_panel_sb(Color(0.22, 0.20, 0.30), rcol.lightened(0.2), 4, 8))
			sk.add_theme_stylebox_override("pressed", _make_pixel_panel_sb(Color(0.12, 0.10, 0.16), rcol, 4, 8))
			sk.modulate = Color(1, 1, 1)
			sk.tooltip_text = str(TextureManager.RIG_NAMES[i]) + "  ·  " + str(game_manager.RARITY_NAMES.get(rar, rar))
		else:
			# gesperrt: Silhouette + Raritaetsrand
			sk.add_theme_stylebox_override("normal", _make_pixel_panel_sb(Color(0.10, 0.10, 0.14), Color(0.28, 0.30, 0.36), 3, 8))
			sk.add_theme_stylebox_override("hover", _make_pixel_panel_sb(Color(0.14, 0.14, 0.19), Color(0.34, 0.36, 0.44), 3, 8))
			sk.add_theme_stylebox_override("pressed", _make_pixel_panel_sb(Color(0.08, 0.08, 0.11), Color(0.28, 0.30, 0.36), 3, 8))
			sk.modulate = Color(0.40, 0.42, 0.50, 0.9)
			sk.tooltip_text = str(TextureManager.RIG_NAMES[i]) + "  ·  " + str(game_manager.RARITY_NAMES.get(rar, rar)) + "  (gesperrt - im Shop)"


func _make_cat_section(parent: VBoxContainer, title: String, count: String, col: Color, columns: int) -> GridContainer:
	# Runde 48: eine Kategorie-Sektion: Header darueber, darunter ein
	# zentriertes Kachel-Grid.
	var sec := VBoxContainer.new()
	sec.add_theme_constant_override("separation", 4)
	parent.add_child(sec)
	var l := Label.new()
	l.text = title + "   " + count
	l.label_settings = _make_label_settings(26, col, 6)
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	sec.add_child(l)
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var wrap := HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec.add_child(wrap)
	wrap.add_child(g)
	return g


func _add_cat_header(grid: GridContainer, title: String, count: String, col: Color) -> void:
	# Runde 46: Kategorie-Header in der Sammlung (z. B. "FARBEN  10/10")
	# Runde 48: der Header liegt als EIGENE ZeILE ueber der Kachelreihe
	# (vorher war er eine Grid-Spalte und zerschob das Raster).
	var l := Label.new()
	l.text = title + "   " + count
	l.label_settings = _make_label_settings(26, col, 6)
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(0, 34)
	grid.add_child(l)



func refresh_collection_ui() -> void:
	# Runde 46: Die Sammlung zeigt ALLE drei Kategorien getrennt:
	# FARBEN, HUETE, SKINS - jeweils mit eigener Ueberschrift.
	if collection_page == null or game_manager == null:
		return
	var sections = collection_page.find_child("CollectionSections", true, false) as VBoxContainer
	var info = collection_page.find_child("CollectionInfo", true, false) as Label
	if sections == null:
		return
	for c in sections.get_children():
		sections.remove_child(c)
		c.queue_free()
	var cc: int = TextureManager.COLOR_NAMES.size()
	var hc: int = TextureManager.HAT_NAMES.size()
	var rc: int = TextureManager.RIG_NAMES.size()
	var own_c: int = 0
	for i in range(cc):
		if game_manager.unlocked_colors.has(i):
			own_c += 1
	var own_h: int = 0
	for i in range(hc):
		if game_manager.unlocked_hats.has(i):
			own_h += 1
	var own_r: int = 0
	for i in range(rc):
		if game_manager.unlocked_rigs.has(i):
			own_r += 1
	if info != null:
		info.text = "FARBEN %d/%d      SKINS %d/%d      HUETE %d/%d" % [own_c, cc, own_r, rc, own_h, hc]

	# ---- FARBEN ----
	var grid := _make_cat_section(sections, "FARBEN", "%d / %d" % [own_c, cc], Color(0.40, 0.82, 0.48), 10)
	# Runde 48: jede Farbe bekommt ein eigenes Farbfeld (echte Farbe aus
	# PLAYER_COLORS) statt eines gruenen Standard-Buttons.
	var pcol: int = int(game_manager.p_color)
	var pskin: int = int(game_manager.p_rig)
	var phat: int = int(game_manager.p_hat)
	for i in range(cc):
		var owned: bool = game_manager.unlocked_colors.has(i)
		var equipped: bool = pcol == i
		var b := _make_pixel_button("", Color(0.13, 0.14, 0.18), 18)
		b.custom_minimum_size = Vector2(140, 118)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 112)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.focus_mode = Control.FOCUS_NONE
		if owned:
			# Der Held in dieser Farbe als Vorschau
			b.icon = TextureManager.get_skin_hat_texture_or_player(i, pskin, phat)
		b.tooltip_text = str(TextureManager.COLOR_NAMES[i]) + (" (AKTIV)" if equipped else (" (gesperrt)" if not owned else ""))
		if equipped:
			b.add_theme_stylebox_override("normal", _make_pixel_panel_sb(Color(0.34, 0.26, 0.10), Color(1.0, 0.84, 0.24), 5, 6))
			b.modulate = Color(1.22, 1.22, 1.22)
		elif not owned:
			b.modulate = Color(0.40, 0.42, 0.50, 0.85)
		var idx: int = i
		# Runde 62: Sammlung ist READ-ONLY - nur anschauen, nichts umstellen.
		_readonly_tile(b)
		grid.add_child(b)

	# ---- SKINS (Runde 47/48: alle 6 Skin-Kacheln sichtbar) ----
	var grid_s := _make_cat_section(sections, "SKINS", "%d / %d" % [own_r, rc], Color(0.98, 0.80, 0.20), 6)
	for i in range(rc):
		var owned3: bool = game_manager.unlocked_rigs.has(i)
		var equipped3: bool = int(game_manager.p_rig) == i
		var rar3: String = str(game_manager.RIG_RARITY[i]) if i < game_manager.RIG_RARITY.size() else "rare"
		var rcol3: Color = game_manager.RARITY_COLORS.get(rar3, Color(0.5, 0.6, 0.8))
		var b3 := _make_pixel_button("", Color(0.13, 0.14, 0.18), 18)
		b3.custom_minimum_size = Vector2(140, 118)
		b3.expand_icon = true
		b3.add_theme_constant_override("icon_max_width", 112)
		b3.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b3.focus_mode = Control.FOCUS_NONE
		# Runde 48: Skin + Farbe + Hut
		var tex3 = TextureManager.get_skin_hat_texture_or_player(pcol, i, phat)
		if tex3 != null:
			b3.icon = tex3
		b3.tooltip_text = str(TextureManager.RIG_NAMES[i]) + "  ·  " + str(game_manager.RARITY_NAMES.get(rar3, rar3)) + (" (AKTIV)" if equipped3 else (" (gesperrt)" if not owned3 else ""))
		if equipped3:
			b3.modulate = Color(1.25, 1.25, 1.25)
		elif not owned3:
			b3.modulate = Color(0.40, 0.42, 0.50, 0.85)
		var idx3: int = i
		# Runde 62: READ-ONLY
		_readonly_tile(b3)
		grid_s.add_child(b3)

	# ---- HUETE ----
	var grid_h := _make_cat_section(sections, "HUETE", "%d / %d" % [own_h, hc], Color(0.70, 0.52, 0.95), 10)
	for i in range(hc):
		var owned2: bool = game_manager.unlocked_hats.has(i)
		var equipped2: bool = int(game_manager.p_hat) == i
		var rar2: String = str(game_manager.HAT_RARITY[i]) if i < game_manager.HAT_RARITY.size() else "common"
		var b2 := _make_pixel_button("", Color(0.13, 0.14, 0.18), 18)
		b2.custom_minimum_size = Vector2(140, 118)
		b2.expand_icon = true
		b2.add_theme_constant_override("icon_max_width", 112)
		b2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b2.focus_mode = Control.FOCUS_NONE
		# Runde 48: Hut-Bild (Skin+Farbe+Hut) statt leerer Kachel
		b2.icon = TextureManager.get_skin_hat_texture_or_player(pcol, pskin, i)
		b2.tooltip_text = str(TextureManager.HAT_NAMES[i]) + "  ·  " + str(game_manager.RARITY_NAMES.get(rar2, rar2)) + (" (AKTIV)" if equipped2 else (" (gesperrt)" if not owned2 else ""))
		if equipped2:
			b2.add_theme_stylebox_override("normal", _make_pixel_panel_sb(Color(0.34, 0.26, 0.10), Color(1.0, 0.84, 0.24), 5, 6))
			b2.modulate = Color(1.22, 1.22, 1.22)
		elif not owned2:
			b2.modulate = Color(0.40, 0.42, 0.50, 0.85)
		var idx2: int = i
		# Runde 62: READ-ONLY
		_readonly_tile(b2)
		grid_h.add_child(b2)


# ============================================================
# Runde 49: WAFFEN-STATS - anklickbare Karten mit Schaden, RPM
# und Nachladezeit. Klick -> Detailzeile klappt auf.
# ============================================================

const WEAPON_STATS := [
	{ "key": "weapon_pistol", "name": "PISTOLE", "desc": "Der Standard. Unendlich Munition, keine Nachladezeit. Verlaesslich, aber schwach gegen Panzer." },
	{ "key": "weapon_shotgun", "name": "SCHROTFLINTE", "desc": "6 Schuss, 3 Streu-Patronen pro Schuss. Toetet_groups im Nahbereich, reloadt aber lang." },
	{ "key": "weapon_machine", "name": "SMG", "desc": "40 Schuss Magazin, 600 RPM. Dauerfeuer, aber nach 40 Schuss 2.2s Nachladen." },
	{ "key": "weapon_laser", "name": "LASER", "desc": "24 Schuss, sehr hohe RPM und 560 px/s Geschwindigkeit. Nach 24 Schuss 1.6s Nachladen." },
	{ "key": "weapon_revolver", "name": "REVOLVER", "desc": "6 Schuss, 9 Schaden pro Schuss. Wiegt schwer, trifft aber am haeufigsten." },
]


func _open_stats_page() -> void:
	# Runde 49: Die Waffen-Stats-Seite
	if stats_page == null:
		_build_stats_page()
	_close_pages()
	stats_page.show()
	_refresh_stats_page()


func _build_stats_page() -> void:
	stats_page = _make_page("WAFFEN-STATS")
	var box := _page_box(stats_page)

	var sub = Label.new()
	sub.text = "Tippe auf eine Waffe fuer alle Werte. SCHADEN pro Schuss, RPM = Schuesse pro Minute, NACHLADEN = Magazin-Nachladezeit."
	sub.label_settings = _make_label_settings(19, Color(0.86, 0.90, 0.88), 4)
	sub.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var grid := GridContainer.new()
	grid.name = "StatsGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var wrap := HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(wrap)
	wrap.add_child(grid)

	stat_cards.clear()
	for w in WEAPON_STATS:
		var key: String = str(w["key"])
		var card := PanelContainer.new()
		card.name = "StatCard_" + key
		card.custom_minimum_size = Vector2(300, 300)
		card.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.12, 0.13, 0.19, 0.95), Color(0.45, 0.52, 0.66), 4, 10))
		grid.add_child(card)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		card.add_child(inner)

		# Icon
		var icon_frame := PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(280, 130)
		icon_frame.add_theme_stylebox_override("panel", _make_pixel_panel_sb(Color(0.08, 0.10, 0.16, 0.92), Color(0.36, 0.78, 0.92), 4, 6))
		inner.add_child(icon_frame)
		var ic := TextureRect.new()
		ic.texture = TextureManager.get_texture(key)
		ic.custom_minimum_size = Vector2(110, 110)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_frame.add_child(ic)

		# Name
		var nl := Label.new()
		nl.text = str(w["name"])
		nl.label_settings = _make_label_settings(24, Color(1.0, 0.86, 0.40), 6)
		nl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(nl)

		# Die drei Kernwerte
		var vals: Array = _weapon_stat_values(key)
		for v in vals:
			var vl := Label.new()
			vl.text = str(v)
			vl.label_settings = _make_label_settings(19, Color(0.90, 0.94, 0.96), 4)
			vl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			inner.add_child(vl)

		# Detailzeile (ausgeklappt)
		var detail := Label.new()
		detail.name = "Detail"
		detail.text = str(w["desc"])
		detail.label_settings = _make_label_settings(16, Color(0.78, 0.84, 0.88), 4)
		detail.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size = Vector2(280, 0)
		detail.visible = false
		inner.add_child(detail)

		# Klick = aufklappen
		var hit := Button.new()
		hit.flat = true
		hit.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit.offset_left = 0.0
		hit.offset_right = 0.0
		hit.offset_top = 0.0
		hit.offset_bottom = 0.0
		hit.focus_mode = Control.FOCUS_NONE
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		hit.pressed.connect(_toggle_stat_card.bind(card))
		card.add_child(hit)

		stat_cards.append({ "card": card, "detail": detail })

	var back := _make_pixel_button("ZURUECK", Color(0.30, 0.34, 0.44), 26)
	back.custom_minimum_size = Vector2(280, 58)
	back.pressed.connect(show_start_screen)
	box.add_child(back)
	stats_page.hide()


# Runde 49: Die echten Waffendaten (Spiegel von player_controller.gd,
# damit die Werte dort nicht nur im Spiel sichtbar sind)
const WEAPON_STAT_VALUES := {
	"weapon_pistol": { "damage": 3, "cooldown": 0.4, "mag": 0, "reload": 0.0 },
	"weapon_shotgun": { "damage": 5, "cooldown": 0.8, "mag": 6, "reload": 2.4 },
	"weapon_machine": { "damage": 2, "cooldown": 0.1, "mag": 40, "reload": 2.2 },
	"weapon_laser": { "damage": 2, "cooldown": 0.14, "mag": 24, "reload": 1.6 },
	"weapon_revolver": { "damage": 9, "cooldown": 1.05, "mag": 6, "reload": 1.9 },
}


func _weapon_stat_values(key: String) -> Array:
	# Runde 49: Schaden / RPM / Magazin / Nachladezeit
	var out: Array = []
	var d: Dictionary = WEAPON_STAT_VALUES.get(key, {})
	if d.is_empty():
		return ["SCHADEN  -", "RPM  -", "NACHLADEN  -"]
	var dmg: int = int(d.get("damage", 0))
	var cd: float = float(d.get("cooldown", 1.0))
	var rpm: int = int(round(60.0 / maxf(0.01, cd)))
	var mag: int = int(d.get("mag", 0))
	var rl: float = float(d.get("reload", 0.0))
	out.append("SCHADEN  %d" % dmg)
	out.append("RPM  %d" % rpm)
	if mag > 0:
		out.append("MAGAZIN  %d   NACHLADEN  %.1fs" % [mag, rl])
	else:
		out.append("MAGAZIN  UNENDLICH")
	return out


func _refresh_stats_page() -> void:
	# Runde 49: Die Werte der Karten auffrischen (Schaden haengt von
	# den Upgrades ab, RPM/Nachladen von der Waffe)
	for entry in stat_cards:
		var card: Control = entry["card"]
		var d = card.find_child("Detail", true, false) as Label
		if d == null:
			continue
		# Die Kernwerte sind eigene Labels - hier nur der Name
		pass


func _toggle_stat_card(card: Control) -> void:
	# Runde 49: Detailzeile auf- oder zuklappen
	var d = card.find_child("Detail", true, false) as Label
	if d == null:
		return
	d.visible = not d.visible
