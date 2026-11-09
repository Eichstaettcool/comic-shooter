# UIManager.gd - Verwaltet HUD, StartScreen und DeathScreen inkl. Touch-Controls
extends Node

signal revive_hold_changed(held: bool)

const LootTable = preload("res://scripts/systems/loot_table.gd")

signal upgrade_chosen(id: String)
signal upgrade_toast_tapped

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
var boss_name_label: Label = null
var season_hud_label: Label = null
# Runde 136 (K): Sprache
var lang_buttons: Array = []
var _loc_throttle: float = 0.0
var _loc_total: int = 0
var _loc_inited: bool = false
var upgrade_overlay: Control = null
var upgrade_toast: Control = null
var shop_back_top: Button = null
var shop_back_bottom: Button = null

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
var diff_btn: Button = null      # v1.40: Schwierigkeitsgrad im Menue
var char_page: Control = null
var settings_page: Control = null
# v1.42 (P1): Aufrufer der Einstellungen merken - "menu" | "pause" | "run"
var settings_origin: String = "menu"
var char_preview: TextureRect = null
var char_name_chip: Label = null
# v1.46 (H1): Eingabefeld fuer den Charakternamen
var char_name_edit: LineEdit = null
var char_unlock_label: Label = null
# Runde 136 (D): neues Charakterfenster
var char_fields: Dictionary = {}
var char_choice_overlay: Control = null
var char_last_field: String = ""
var char_count_label: Label = null
var char_value_label: Label = null
var char_gold_chip: Control = null
var quality_btn = null
var fps_btn = null
var sound_btn = null
var sfx_btn = null
# v1.42 (P4.1): Musiklautstaerke-Regler in den Einstellungen
var music_slider = null
var music_slider_label = null
# v1.43 (S3.2): -/+ Knoepfe neben dem Regler
var music_minus_btn = null
var music_plus_btn = null
# v1.42 (P10.4): Schalter fuer den Biom-Uebergang
var biom_flash_btn = null
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
const LOAD_FADE: float = 0.25        # v1.45 (L4): ein Ausblenden fuer Boot und Run
# v1.42 (P14): Name + Ein-Satz-Beschreibung je Modus (Ladebildschirm)
const LOAD_MODE_INFO := {
	"runden": { "name": "RUNDEN-MODUS", "desc": "Wellen laufen in Gruppen ein, nach jeder Runde gibt es den Shop - regelmaessig ein Boss." },
	"endlos": { "name": "ENDLOS-MODUS", "desc": "Ein Run ohne Ende: Level-Up-Karten, Bosse alle 120 Sekunden, mehr Monster mit der Zeit." },
	"wellen": { "name": "WELLEN-MODUS", "desc": "Welle fuer Welle mit Shop dazwischen - Aufwertungen gibt es nur gegen Muenzen." },
	"coop": { "name": "COOP (LAN)", "desc": "Zwei Spieler in einer Welt: einer hostet, der andere steigt ein und hilft mit." },
}
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
var info_page: Control = null
var info_origin: String = "settings"
var shop_gold_chip: PanelContainer = null
var chest_cards: Array = []
var start_box: VBoxContainer = null     # Runde 40: Inhalts-Box der Startseite
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
# v1.56c (Bug 3): erst ab dieser Fingerbewegung ist es ein SCROLL-Zug,
# darunter ein Tipp (Knopf muss ihn bekommen).
const TIPP_SCHWELLE := 14.0
var _drag_gesamt: float = 0.0
var _drag_seite: String = ""
var _drag_von: int = 0
var _drag_nach: int = 0
var _drag_last_y: float = -99999.0
var _drag_px: float = 0.0
var _weapon_hud_sig: String = ""
var target_arrow: TextureRect = null
var collection_page: Control = null
# v1.44 (C): Aufgaben-Seite
var challenge_page: Control = null
var wave_shop: Control = null        # v1.40: Shop des RUNDEN-Modus
var wave_shop_btn: Button = null     # HUD-Icon "Shop"
var wave_next_btn: Button = null     # HUD-Icon "naechste Welle"
var wave_preview: Label = null       # Vorschau der folgenden Runde
var wave_icon_box: Control = null
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
	# v1.43 (S6.2): Das UI wird NICHT mehr hier gebaut - der Start wuerde sonst
	# sofort alle Starttexturen anfordern und die Haeppchen wieder zu einem
	# Block machen. GameManager ruft nach dem Chunk-Boot build_ui() auf.
	process_mode = Node.PROCESS_MODE_ALWAYS   # Pausen-Menue muss auch pausiert klickbar sein
	print("[UI][BOOT] bereit (Aufbau folgt nach dem Chunk-Boot)")


func build_ui() -> void:
	var t0: int = Time.get_ticks_msec()
	_create_hud()
	print("[UI][BOOT] hud ms=%d" % (Time.get_ticks_msec() - t0))
	_create_start_screen()
	print("[UI][BOOT] start ms=%d" % (Time.get_ticks_msec() - t0))
	_create_death_screen()
	print("[UI][BOOT] tod ms=%d" % (Time.get_ticks_msec() - t0))
	show_start_screen()
	print("[UI][BOOT] show_start ms=%d" % (Time.get_ticks_msec() - t0))
	# Runde 45: Ladebildschirm einblenden (Helden + Sprueche)
	_build_load_screen()
	print("[UI][BOOT] load ms=%d" % (Time.get_ticks_msec() - t0))
	if load_screen != null:
		load_screen.visible = true
		load_screen.modulate.a = 1.0
		load_time = 0.0
		load_next = 0.35
	NetManager.hosts_changed.connect(_refresh_lan_list)
	NetManager.conn_failed.connect(_on_lan_failed)
	NetManager.run_start_signal.connect(_on_lan_run_started)
	NetManager.partner_left.connect(_on_lan_partner_left)
	print("[UI][BOOT] Oberflaeche gebaut")

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
		# v1.48 (C3): Textur ist 256 px -> 0.9 bzw. 0.8 ergibt die alte Groesse.
		if on:
			shoot_btn.position = Vector2(1290, 880)
			shoot_btn.scale = Vector2(0.8, 0.8)
		else:
			shoot_btn.position = Vector2(1580, 790)
			shoot_btn.scale = Vector2(0.9, 0.9)

func _hud_panel_sb(alpha: float = 0.55, radius: int = 16) -> StyleBoxFlat: return UiStyle._hud_panel_sb(alpha, radius)


# Runde 61: Einheitlicher Comic-Stil wie auf der Startseite (dunkles Papier,
# dicke gelbe Kante, harter Versatzschatten). Wird fuer HUD, Pause und
# Uebersichten benutzt, damit alles aus einem Guss wirkt.
const COMIC_YELLOW := Color(0.99, 0.80, 0.22)
const COMIC_PAPER := Color(0.09, 0.12, 0.21)


func _hud_comic_sb(alpha: float = 0.94, accent: Color = COMIC_YELLOW, radius: int = 14, pad: int = 16) -> StyleBoxFlat: return UiStyle._hud_comic_sb(alpha, accent, radius, pad)


func _create_hud(): return _hud_p()._create_hud()

func _create_touch_controls(): return _hud_p()._create_touch_controls()

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
	lan_ip_edit.placeholder_text = "IP des Hosts, z. B. 192.168.188.142"
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
	if not _loc_inited and game_manager != null:
		_loc_inited = true
		Loc.set_lang(str(game_manager.get("lang")))
		print("[LOC][INIT] gespeicherte sprache=%s" % Loc.lang)
	# Runde 136 (K): bei ENGLISCH die Oberflaeche laufend uebersetzen.
	# Neue Seiten entstehen dynamisch - so wird jede ohne Einzelaufruf erfasst.
	if Loc.lang == "en":
		_loc_throttle += delta
		if _loc_throttle >= 0.35:
			_loc_throttle = 0.0
			var lst: Dictionary = Loc.apply_tree(self)
			if int(lst["done"]) > 0:
				_loc_total += int(lst["done"])
				print("[LOC][APPLY] uebersetzt=+%d (gesamt %d)" % [int(lst["done"]), _loc_total])
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
func update_partner(hp: int, mx: int, weapon_name: String, shield: int = 0, pname: String = "") -> void: _hud_p().update_partner(hp, mx, weapon_name, shield, pname)

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

func refresh_utility_hud(utils: Dictionary = {}, weapon_key: String = "") -> void: _hud_p().refresh_utility_hud(utils, weapon_key)

func update_reload_indicator(progress: float, text: String) -> void: _hud_p().update_reload_indicator(progress, text)


func refresh_weapon_hud(owned: Array, current_key: String) -> void: _hud_p().refresh_weapon_hud(owned, current_key)

func _rarry_placeholder() -> void:
	pass


func _rarity_col_of(r: String) -> Color:
	match r:
		"rare":
			return Color(0.35, 0.65, 0.95)
		"epic":
			return Color(0.72, 0.45, 0.95)
		"legendary":
			return Color(0.99, 0.72, 0.20)
	return Color(0.72, 0.74, 0.78)


func _rarity_label_de(r: String) -> String:
	match r:
		"rare":
			return "SELTEN"
		"epic":
			return "EPISCH"
		"legendary":
			return "LEGENDÄR"
	return "GEWÖHNLICH"


func _on_weapon_button(key: String) -> void: _hud_p()._on_weapon_button(key)

# ============================================================
# BUFF-ANZEIGE (Frost / Schnellfeuer)
# ============================================================
func update_switch_hint(txt: String, cur: int = -1, need: int = -1) -> void: _hud_p().update_switch_hint(txt, cur, need)

func update_buffs(rapid: float, freeze: float, gold: float = 0.0) -> void: _hud_p().update_buffs(rapid, freeze, gold)

# ============================================================
# BANNER (Biom-Wechsel / Boss besiegt)
# ============================================================
func show_banner(text: String, color: Color = Color(1, 1, 1)) -> void: _hud_p().show_banner(text, color)

func _shop_font() -> Font: return UiStyle._shop_font()


func _shop_ls(size: int, col: Color, outline: int = 6) -> LabelSettings: return UiStyle._shop_ls(size, col, outline)


# ---------------------------------------------------------------
# Runde 82: Aufweck-Knopf mit 5-Sekunden-Leiste
# ---------------------------------------------------------------
var revive_panel: Control = null
var revive_bar: ProgressBar = null
var revive_hint: Label = null

func show_revive_prompt(on: bool) -> void:
	if revive_panel == null:
		_build_revive_prompt()
	if revive_panel != null:
		revive_panel.visible = on


func set_revive_progress(p: float) -> void:
	if revive_bar != null:
		revive_bar.value = clampf(p, 0.0, 1.0) * 100.0


func _build_revive_prompt() -> void:
	revive_panel = Control.new()
	revive_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	revive_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(revive_panel)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.offset_left = -260.0
	box.offset_right = 260.0
	box.offset_top = -210.0
	box.offset_bottom = -60.0
	box.alignment = BoxContainer.ALIGNMENT_END
	revive_panel.add_child(box)

	revive_hint = Label.new()
	revive_hint.text = "PARTNER LIEGT — HALTE ZUM AUFWECKEN"
	revive_hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	revive_hint.label_settings = _make_label_settings(24, Color(1.0, 0.85, 0.35), 6)
	box.add_child(revive_hint)

	revive_bar = ProgressBar.new()
	revive_bar.min_value = 0.0
	revive_bar.max_value = 100.0
	revive_bar.value = 0.0
	revive_bar.custom_minimum_size = Vector2(520, 34)
	revive_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.11, 0.16, 0.95)
	bg.border_color = Color(0.05, 0.05, 0.08)
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.99, 0.80, 0.22)
	fill.set_corner_radius_all(3)
	revive_bar.add_theme_stylebox_override("background", bg)
	revive_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(revive_bar)

	var btn := _make_pixel_button("AUFWECKEN", Color(0.20, 0.62, 0.42), 28)
	btn.custom_minimum_size = Vector2(520, 74)
	# Runde 87: EIN Klick startet den 5-Sekunden-Lauf. Halten war in der
	# Praxis nicht zu schaffen (Log: 4 Versuche, alle bei 2,1-2,3 s abgebrochen).
	btn.pressed.connect(func(): revive_hold_changed.emit(true))
	btn.text = "AUFWECKEN (5 s)"
	box.add_child(btn)
	revive_panel.visible = false
	print("[REVIVE][UI] Aufweck-Knopf erzeugt")


# ---------------------------------------------------------------
# Runde 84: Klarer Zuschauer-Bildschirm
# ---------------------------------------------------------------
var spec_overlay: Control = null

func show_spectator_overlay(on: bool, partner_name: String = "") -> void:
	if spec_overlay == null:
		spec_overlay = Control.new()
		spec_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		spec_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(spec_overlay)

		var vig := ColorRect.new()
		vig.color = Color(0.02, 0.03, 0.06, 0.55)
		vig.set_anchors_preset(Control.PRESET_FULL_RECT)
		vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spec_overlay.add_child(vig)

		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_CENTER_TOP)
		vb.offset_left = -420.0
		vb.offset_right = 420.0
		vb.offset_top = 54.0
		vb.offset_bottom = 220.0
		vb.alignment = BoxContainer.ALIGNMENT_BEGIN
		spec_overlay.add_child(vb)

		var t1 := Label.new()
		t1.name = "SpecTitle"
		t1.text = "DU BIST AUSGESCHIEDEN"
		t1.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		t1.label_settings = _make_label_settings(46, Color(1.0, 0.42, 0.42), 10)
		vb.add_child(t1)

		var t2 := Label.new()
		t2.name = "SpecSub"
		t2.text = "ZUSCHAUER — dein Partner kämpft weiter"
		t2.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		t2.label_settings = _make_label_settings(24, Color(0.85, 0.90, 1.0), 6)
		vb.add_child(t2)
		spec_overlay.visible = false

	spec_overlay.visible = on
	if on and partner_name != "":
		var sub = spec_overlay.find_child("SpecSub", true, false)
		if sub != null:
			sub.text = "ZUSCHAUER — %s kämpft weiter" % partner_name
	print("[SPEC][UI] Overlay %s" % ("AN" if on else "AUS"))


func _make_label_settings(size: int, color: Color, outline: int) -> LabelSettings: return UiStyle._make_label_settings(size, color, outline)


func _make_stylebox(bg: Color) -> StyleBoxFlat: return UiStyle._make_stylebox(bg)


func _make_styled_button(text: String, bg: Color, font_size: int = 40) -> Button: return UiStyle._make_styled_button(text, bg, font_size)


# ============================================================
# Runde 40: COMIC-LOOK - Panels, Knöpfe, Chips, Zahnrad
# ============================================================

func _comic_panel_sb(fill: Color, border: Color = Color(0.06, 0.05, 0.10), bw: int = 7, pad: int = 14) -> StyleBoxFlat: return UiStyle._comic_panel_sb(fill, border, bw, pad)


func _comic_button_sb(fill: Color, pressed: bool = false) -> StyleBoxFlat: return UiStyle._comic_button_sb(fill, pressed)


func _make_comic_button(text: String, fill: Color, font_size: int = 40) -> Button: return UiStyle._make_comic_button(text, fill, font_size)


func _make_burst_texture(size: int = 512) -> ImageTexture: return UiStyle._make_burst_texture(size)


func ImageUtils_fill_polygon(img: Image, pts: PackedVector2Array, col: Color) -> void: UiStyle.ImageUtils_fill_polygon(img, pts, col)


func _make_halftone_texture(size: int = 64) -> ImageTexture: return UiStyle._make_halftone_texture(size)


# ============================================================
# Runde 43: PIXEL-ART-KACHELN (Punkt 7)
# Echte Pixel-Fase: die Ecken werden in 2-Stufen abgeschrägt, damit die
# Kachel "rund" wirkt, aber KEINE weichen Rundungen bekommt.
# ============================================================

func _make_pixel_panel_sb(fill: Color, border: Color = Color(0.06, 0.05, 0.10), bw: int = 4, pad: int = 8) -> StyleBoxFlat: return UiStyle._make_pixel_panel_sb(fill, border, bw, pad)


func _make_pixel_button(text: String, fill: Color, font_size: int = 40) -> Button: return UiStyle._make_pixel_button(text, fill, font_size)


# ---------------- Ladescreen (Runde 45) ----------------
var load_screen: Control = null
# v1.42 (P14): Modus-Vorschau im Ladebildschirm
var load_mode_icon: TextureRect = null
var load_mode_name: Label = null
var load_mode_desc: Label = null
var load_is_run: bool = false
var load_is_boot: bool = false    # v1.45 (L): App-Start benutzt dieselbe Flaeche
var load_shown_ms: int = 0
var load_actor: TextureRect = null
var load_quote: Label = null
var load_title: Label = null
var load_bar: ColorRect = null
# v1.45 (L-Nacharbeit): Rahmen + Kasten + Balken brauchen eigene Referenzen,
# sonst laesst sich die Mitte nicht messen und der leere Icon-Kasten nicht
# sauber ein-/ausschalten.
var load_icon_holder: Control = null
var load_panel: PanelContainer = null
var load_bubble: PanelContainer = null
var load_bar_bg: PanelContainer = null
var load_idx: int = 0
var load_tex: Array = []
# v1.43 (S6.2): nur die Varianten-Liste, Texturen entstehen beim Anzeigen
var load_specs: Array = []


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
	# v1.39 M4: benannte Kachel, damit der Diag-Modus den echten Klickweg
	# (Menue -> Kachel) reproduzieren kann - ohne Namenssuche im Baum.
	tile.name = "NavTile_%s" % icon_key
	tile.custom_minimum_size = Vector2(196, 196)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# v1.46 (A1): Kachel-Beschriftung als Beleg ausgeben - nach der Umbenennung
	# "AUFGABEN -> CHALLENGES" muss die Zeile den neuen Text tragen.
	if icon_key == "chal":
		print("[UI][NAV] kachel=%s" % text)

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
	hit.name = "NavHit_%s" % icon_key
	hit.tooltip_text = text
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

	# v1.42 (P14): Modus-Vorschau (Bild + Name + Ein-Satz-Beschreibung)
	var mode_panel := PanelContainer.new()
	load_panel = mode_panel
	mode_panel.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.10, 0.10, 0.18, 0.95), Color(0.45, 0.72, 0.98), 5, 14))
	mode_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(mode_panel)
	var mode_col := VBoxContainer.new()
	mode_col.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_col.add_theme_constant_override("separation", 6)
	mode_panel.add_child(mode_col)
	# Fester Rahmen, Bild darin vollflaechig (ein TextureRect allein ignoriert
	# in einem VBox seine Mindestgroesse und wurde auf Briefmarkengroesse gezogen)
	var icon_holder := Control.new()
	load_icon_holder = icon_holder
	icon_holder.custom_minimum_size = Vector2(132, 132)
	icon_holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mode_col.add_child(icon_holder)
	load_mode_icon = TextureRect.new()
	load_mode_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_mode_icon.offset_left = 0.0
	load_mode_icon.offset_top = 0.0
	load_mode_icon.offset_right = 0.0
	load_mode_icon.offset_bottom = 0.0
	load_mode_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	load_mode_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	load_mode_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_holder.add_child(load_mode_icon)
	load_mode_name = Label.new()
	load_mode_name.label_settings = _make_label_settings(44, Color(1.0, 0.90, 0.42), 8)
	# v1.45 (L-Nacharbeit): der Text stand linksbuendig im Kasten - jetzt mittig,
	# inkl. Zeilenumbruch, damit Name und Beschreibung dieselbe Achse haben.
	load_mode_name.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	load_mode_name.size_flags_horizontal = Control.SIZE_FILL
	mode_col.add_child(load_mode_name)
	load_mode_desc = Label.new()
	load_mode_desc.label_settings = _make_label_settings(24, Color(0.86, 0.92, 0.98), 4)
	load_mode_desc.custom_minimum_size = Vector2(560, 0)
	load_mode_desc.size_flags_horizontal = Control.SIZE_FILL
	load_mode_desc.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	load_mode_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_col.add_child(load_mode_desc)

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
	load_bubble = bubble
	bubble.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.96, 0.96, 0.99, 0.95), Color(0.06, 0.05, 0.10), 6, 22))
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(bubble)
	load_quote = Label.new()
	load_quote.text = ""
	load_quote.label_settings = _make_label_settings(30, Color(0.10, 0.09, 0.16), 0)
	load_quote.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	load_quote.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	load_quote.custom_minimum_size = Vector2(760, 0)
	load_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(load_quote)

	# Ladebalken (v1.45 L3: 720 x 28, Gold auf Dunkel)
	var bar_bg := PanelContainer.new()
	load_bar_bg = bar_bg
	bar_bg.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.10, 0.10, 0.16, 0.9), Color(0.30, 0.34, 0.44), 4, 5))
	bar_bg.custom_minimum_size = Vector2(720, 28)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(bar_bg)
	load_bar = ColorRect.new()
	load_bar.color = Color(0.98, 0.80, 0.20)
	load_bar.custom_minimum_size = Vector2(0, 18)
	load_bar.size = Vector2(0, 18)
	bar_bg.add_child(load_bar)

	# Helden-Texturen: v1.43 (S6.2) NUR die Liste der Varianten vorbereiten.
	# Vorher wurden hier 42 Kombittexturen am Stueck gezeichnet (~2,2 s Block).
	# Jetzt entsteht jede Figur erst, wenn sie im Ladebildschirm erscheint.
	load_specs = []
	for i in range(TextureManager.RIG_NAMES.size()):
		load_specs.append(["skin", i])
	for i in range(TextureManager.HAT_NAMES.size()):
		load_specs.append(["hat", i])
	load_tex = []
	_next_load_actor()


# Holt die Figur an Position i - bei Bedarf jetzt erst zeichnen (gecacht).
func _load_tex_at(i: int) -> Texture2D:
	while load_tex.size() <= i:
		load_tex.append(null)
	if load_tex[i] != null:
		return load_tex[i]
	if i < 0 or i >= load_specs.size():
		return null
	var s: Array = load_specs[i]
	var t: Texture2D = null
	if str(s[0]) == "skin":
		t = TextureManager.get_skin_texture(0, int(s[1]))
	else:
		t = TextureManager.get_player_texture(3, int(s[1]))
	load_tex[i] = t
	return t


func _next_load_actor() -> void:
	# Runde 45: naechster Held + passender Spruch
	if load_actor == null or load_specs.is_empty():
		return
	load_idx = (load_idx + 1) % load_specs.size()
	var tex: Texture2D = _load_tex_at(load_idx)
	if tex != null:
		load_actor.texture = tex
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
	if load_is_boot:
		return      # v1.45 (L): beim Boot kommt der Fortschritt aus dem Boot-Loader
	load_time += delta
	# Balken waechst
	if load_bar != null:
		var w: float = minf(1.0, load_time / LOAD_MIN_TIME)
		load_bar.size.x = 720.0 * w
	# Alle 1.6 s ein neuer Held
	if load_time >= load_next:
		load_next += 1.6
		_next_load_actor()
	# Fertig -> ausblenden
	if load_is_run:
		return
	if load_time >= LOAD_MIN_TIME and load_screen.visible:
		_hide_load_screen()


# ============================================================
# v1.45 (L): EIN Ladebildschirm fuer App-Start und Run-Start
# ============================================================

var _boot_status: Label = null


func build_boot_screen() -> void:
	# Baut (falls noetig) die gemeinsame Flaeche und schaltet sie in den
	# Boot-Zustand: Modus-Panel zeigt den zuletzt gespielten Modus, das
	# Icon-Feld bleibt NICHT als leerer Kasten stehen (es wird ausgeblendet,
	# bis die Modus-Grafik wirklich da ist), Balken + Status sind sichtbar.
	if load_screen == null:
		_build_load_screen()
	if load_screen == null:
		return
	load_is_boot = true
	load_is_run = false
	# Das Zahnrad der Startseite darf nicht ueber dem Ladebildschirm stehen
	if start_screen != null:
		start_screen.hide()
	load_time = 0.0
	load_screen.modulate.a = 1.0
	load_screen.visible = true
	load_shown_ms = Time.get_ticks_msec()
	var modus: String = _boot_mode_key()
	if load_mode_name != null:
		load_mode_name.text = str(LOAD_MODE_INFO[modus]["name"])
	if load_mode_desc != null:
		load_mode_desc.text = str(LOAD_MODE_INFO[modus]["desc"])
	# v1.45 (L-Nacharbeit): Der Kasten war leer, weil nur das Bild ausgeblendet
	# wurde - der 132-px-Platzhalter blieb stehen. Jetzt zeigt der Boot den
	# Modus mit Bild (aus demselben Bauweg), Name und Text mittig.
	if load_icon_holder != null:
		load_icon_holder.visible = true
	if load_mode_icon != null:
		load_mode_icon.visible = true
		load_mode_icon.texture = _mode_preview_texture(modus)
	# Statuszeile statt des langen Spruchs: schmalere Blase beim Start
	if load_bubble != null and load_quote != null:
		load_quote.custom_minimum_size = Vector2(520, 0)
	if load_bar != null:
		load_bar.custom_minimum_size = Vector2(0, 18)
		load_bar.size = Vector2(0, 18)
	# Messung erst nach dem Layout-Durchlauf (sonst sind alle Rechtecke noch 0)
	_report_boot_layout(modus)


func _report_boot_layout(modus: String) -> void:
	# v1.45 (L-Nacharbeit): erst zwei Frames warten - vorher hat der Container
	# seine Groessen noch nicht verteilt (auf dem Geraet standen dort 0 px).
	await get_tree().process_frame
	await get_tree().process_frame
	var info: Dictionary = load_layout_probe()
	print("[BOOT][UI] panel_modus=%s icon=an leer=false balken=(%.0f,%.0f) in_flaeche=%s mitte_text=%.0f mitte_kasten=%.0f abweichung=%.1fpx desc_abweichung=%.1fpx" % [
		modus, float(info["balken"].x), float(info["balken"].y), str(bool(info["in_flaeche"])),
		float(info["text_mitte"]), float(info["kasten_mitte"]), float(info["abweichung"]),
		float(info["beschreibung_abweichung"])])


func _boot_mode_key() -> String:
	# Zuletzt gewaehlter Modus aus dem Profil (game_manager.game_mode), sonst ENDLOS
	var m: int = 0
	if game_manager != null:
		m = int(game_manager.get("game_mode"))
	match m:
		2:
			return "runden"
		1:
			return "wellen"
		_:
			return "endlos"


func boot_progress(frac: float, txt: String) -> void:
	if load_screen == null:
		return
	if load_bar != null:
		var w: float = 720.0 * clampf(frac, 0.0, 1.0)
		load_bar.custom_minimum_size = Vector2(w, 18)
		load_bar.size = Vector2(w, 18)
	if load_quote != null:
		load_quote.text = txt


func load_layout_probe() -> Dictionary:
	# v1.45 (L-Nacharbeit): misst, ob der Text wirklich mittig im Kasten steht.
	# Grundlage sind die echten Rechtecke (global_rect) nach dem Layout -
	# keine angenommenen Zahlen.
	var kasten := Rect2()
	var name_r := Rect2()
	var desc_r := Rect2()
	var balken := Rect2()
	var blase := Rect2()
	if load_panel != null and is_instance_valid(load_panel):
		kasten = load_panel.get_global_rect()
	if load_mode_name != null and is_instance_valid(load_mode_name):
		name_r = load_mode_name.get_global_rect()
	if load_mode_desc != null and is_instance_valid(load_mode_desc):
		desc_r = load_mode_desc.get_global_rect()
	if load_bar_bg != null and is_instance_valid(load_bar_bg):
		balken = load_bar_bg.get_global_rect()
	if load_bubble != null and is_instance_valid(load_bubble):
		blase = load_bubble.get_global_rect()
	var text_mitte: float = name_r.position.x + name_r.size.x * 0.5
	var kasten_mitte: float = kasten.position.x + kasten.size.x * 0.5
	var in_flaeche: bool = false
	if load_screen != null and is_instance_valid(load_screen):
		var lr: Rect2 = load_screen.get_global_rect()
		in_flaeche = lr.encloses(balken) and is_instance_valid(load_bar_bg) and load_bar_bg.is_visible_in_tree()
	return {
		"kasten": kasten, "name": name_r, "desc": desc_r, "balken": balken.size,
		"blase": blase, "text_mitte": text_mitte, "kasten_mitte": kasten_mitte,
		"abweichung": absf(text_mitte - kasten_mitte),
		"beschreibung_abweichung": absf((desc_r.position.x + desc_r.size.x * 0.5) - kasten_mitte),
		"in_flaeche": in_flaeche,
	}


func hide_boot_screen() -> void:
	load_is_boot = false
	_hide_load_screen()


func show_load_for_run() -> void:
	# v1.42 (P14): Ladebildschirm mit Modus-Vorschau vor dem Run-Start.
	if load_screen == null:
		return
	load_is_run = true
	load_time = 0.0
	load_next = 1.6
	load_screen.modulate.a = 1.0
	load_screen.visible = true
	load_shown_ms = Time.get_ticks_msec()
	load_is_boot = false
	var modus: String = load_mode_key()
	if load_icon_holder != null:
		load_icon_holder.visible = true
	if load_mode_icon != null:
		load_mode_icon.visible = true
		load_mode_icon.texture = _mode_preview_texture(modus)
	# Spruch braucht die breite Blase, der Start-Status die schmale
	if load_quote != null:
		load_quote.custom_minimum_size = Vector2(760, 0)
	load_mode_name.text = str(LOAD_MODE_INFO[modus]["name"])
	load_mode_desc.text = str(LOAD_MODE_INFO[modus]["desc"])
	if load_bar != null:
		load_bar.custom_minimum_size = Vector2(0, 18)
		load_bar.size = Vector2(0, 18)
	print("[LOAD][BILD] modus=%s bild=load_%s dauer=%.1fs" % [
		modus, modus, LOAD_MIN_TIME])
	var instanzen: int = 1
	if game_manager != null and (bool(game_manager.get("duo_mode")) or bool(game_manager.get("lan_mode"))):
		instanzen = 2
		print("[LOAD][BILD] instanzen=%d modus=coop geteilt=true" % instanzen)


func load_mode_key() -> String:
	if game_manager != null:
		if bool(game_manager.get("duo_mode")) or bool(game_manager.get("lan_mode")):
			return "coop"
		var m: int = int(game_manager.get("game_mode"))
		if m == 2:
			return "runden"
		if m == 1:
			return "wellen"
	return "endlos"


func hide_load_after_run() -> void:
	# v1.42 (P14.2): mindestens 0,8 s sichtbar, dann ausblenden.
	if load_screen == null or not load_screen.visible:
		return
	var sichtbar: float = float(Time.get_ticks_msec() - load_shown_ms) / 1000.0
	var rest: float = maxf(0.0, 0.8 - sichtbar)
	var leer: int = 0
	print("[LOAD][UEBERGANG] frames_leer=%d" % leer)
	if rest > 0.01:
		await get_tree().create_timer(rest).timeout
	var gesamt: float = float(Time.get_ticks_msec() - load_shown_ms) / 1000.0
	print("[LOAD][BILD] sichtbar=%.2fs" % gesamt)
	load_is_run = false
	_hide_load_screen()


func _mode_preview_texture(modus: String) -> Texture2D:
	# Ein Bild je Modus, aus vorhandenen Sprites zusammengesetzt:
	#   runden = Monster + Krone (Wellen + Boss), endlos = Schadel-Monster + Uhr,
	#   wellen = drei Monster als Welle, coop = zwei Figuren.
	var img := Image.create(160, 160, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.06, 0.07, 0.12, 0.0))
	var pl_a: Image = _tex_img_safe(TextureManager.get_player_texture(0, 0))
	var pl_b: Image = _tex_img_safe(TextureManager.get_player_texture(1, 0))
	var mon: Image = _tex_img_safe(TextureManager.get_texture("monster_green"))
	var boss: Image = _tex_img_safe(TextureManager.get_texture("monster_orange"))
	match modus:
		"runden":
			_blit_scaled(img, mon, 96, Rect2i(0, 54, 96, 96))
			_blit_scaled(img, mon, 84, Rect2i(24, 76, 84, 84))
			_blit_scaled(img, boss, 134, Rect2i(40, 0, 134, 134))
		"endlos":
			_blit_scaled(img, mon, 158, Rect2i(0, 2, 158, 158))
		"wellen":
			_blit_scaled(img, mon, 62, Rect2i(0, 90, 62, 62))
			_blit_scaled(img, mon, 78, Rect2i(40, 40, 78, 78))
			_blit_scaled(img, mon, 62, Rect2i(96, 90, 62, 62))
		"coop":
			_blit_scaled(img, pl_a, 104, Rect2i(0, 40, 104, 104))
			_blit_scaled(img, pl_b, 104, Rect2i(56, 40, 104, 104))
		_:
			_blit_scaled(img, mon, 128, Rect2i(16, 16, 128, 128))
	return ImageTexture.create_from_image(img)


func _tex_img_safe(t: Texture2D) -> Image:
	if t == null:
		return null
	var im: Image = t.get_image()
	if im == null:
		return null
	if im.is_compressed():
		im.decompress()
	return im


func _blit_scaled(dst: Image, src: Image, size: int, at: Rect2i) -> void:
	if src == null:
		return
	var im: Image = src.duplicate()
	im.resize(size, size, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(im, Rect2i(0, 0, size, size), at.position)


func _hide_load_screen() -> void:
	if load_screen == null:
		return
	var tw := load_screen.create_tween()
	tw.tween_property(load_screen, "modulate:a", 0.0, LOAD_FADE)
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

func _make_chip_sb(bg: Color) -> StyleBoxFlat: return UiStyle._make_chip_sb(bg)


func _make_chip(text: String, bg: Color, size: int = 30) -> PanelContainer: return UiStyle._make_chip(text, bg, size)

# v1.44 (R1): Walzen-Look (Automaten-Panel, Banner, goldener Aktionsknopf)
func _slot_panel_sb(pad: int = 14, border: int = 3) -> StyleBoxFlat: return UiStyle._slot_panel_sb(pad, border)

func _slot_banner(text: String, font_size: int = 40) -> Control: return UiStyle._slot_banner(text, font_size)

func _slot_button(text: String, font_size: int = 28) -> Button: return UiStyle._slot_button(text, font_size)


func _make_page(title_text: String) -> Control:
	# Runde 45: zurueck zum einfachen Aufbau (wie vor der R44-Umbauten):
	# Dim + Panel + Box. Die Seite liegt im VOLLBILD, der Inhalt bekommt
	# Innenabstand. Kein Scroll, kein Scaling - das Layout verhaelt sich
	# wieder exakt wie vorher.
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	start_screen.add_child(page)
	# Runde 103: Seite nach GANZ OBEN - sonst liegt sie unter dem Startbildschirm-
	# Overlay und Titel/Banner scheinen durch die Karten.
	start_screen.move_child(page, start_screen.get_child_count() - 1)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.05, 0.08, 1.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0.0
	panel.offset_right = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.05, 0.05, 0.10, 1.0), Color(0.98, 0.80, 0.20), 5, 30))
	page.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.name = "PageTitle"
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

	# Versionsanzeige - damit man am Geraet sofort sieht, welcher Build laeuft
	var ver := Label.new()
	# B5: EINE Quelle fuer Menue, Log und Export (game_manager.APP_VERSION).
	# Hier laeuft das ueber die Konstanten-Map des Scripts, weil game_manager
	# beim Bau des Startbildschirms noch nicht zugewiesen ist.
	var _gsc := load("res://scripts/game_manager.gd")
	var _vname := str(_gsc.get_script_constant_map().get("APP_VERSION", "?"))
	var _vbuild := int(_gsc.get_script_constant_map().get("APP_BUILD", 0))
	ver.text = "v%s  ·  Build %d" % [_vname, _vbuild]
	ver.set_meta("loc_fmt", true)   # v1.41 (F5): Versionszeile bleibt so
	ver.label_settings = _make_label_settings(20, Color(0.75, 0.80, 0.86), 3)
	ver.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	ver.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(ver)
	# Geheim: 7x tippen schaltet das Debug-Fenster frei
	ver.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			ver.set_meta("taps", int(ver.get_meta("taps", 0)) + 1)
			var n: int = int(ver.get_meta("taps"))
			print("[DEBUG] Tap %d/7" % n)
			if n >= 7:
				ver.set_meta("taps", 0)
				game_manager.call("debug_toggle"))
	print("[BUILD] Versionsanzeige v%s aktiv (Build %d)" % [_vname, _vbuild])

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
		{ "id": "shop", "text": "SHOP", "col": Color(0.86, 0.58, 0.12), "cb": _open_chest_page },
		{ "id": "coll", "text": "SAMMLUNG", "col": Color(0.74, 0.22, 0.46), "cb": func(): show_collection() },
		{ "id": "map", "text": "KARTEN", "col": Color(0.18, 0.56, 0.70), "cb": _open_maps_page },
		{ "id": "chal", "text": "CHALLENGES", "col": Color(0.62, 0.46, 0.10), "cb": _open_challenge_page }
	]
	for nd in nav_defs:
		nav.add_child(_make_nav_tile(str(nd["id"]), str(nd["text"]), nd["col"], nd["cb"]))

	# Modus + Chips
	# v1.41 (F2): feste Mindestbreite + SHRINK_CENTER. Vorher wuchs die Zeile,
	# sobald der GRAD-Knopf sichtbar wurde, und die zentrierte Box wurde
	# breiter als die Panel-Innenbreite -> die Startseite verzog sich.
	var row3 = HBoxContainer.new()
	row3.name = "StartRow3"
	row3.alignment = BoxContainer.ALIGNMENT_CENTER
	row3.add_theme_constant_override("separation", 18)
	row3.custom_minimum_size = Vector2(1180, 74)
	row3.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(row3)

	mode_btn = _make_pixel_button("MODUS: ENDLOS", Color(0.26, 0.38, 0.70), 24)
	mode_btn.custom_minimum_size = Vector2(330, 74)
	mode_btn.pressed.connect(_on_mode_pressed)
	row3.add_child(mode_btn)
	# v1.40 (W6.8): Schwierigkeitsgrad fuer den RUNDEN-Modus
	diff_btn = _make_pixel_button("GRAD: NORMAL", Color(0.32, 0.30, 0.46), 22)
	diff_btn.name = "DifficultyBtn"
	diff_btn.custom_minimum_size = Vector2(300, 74)
	diff_btn.pressed.connect(_on_difficulty_pressed)
	row3.add_child(diff_btn)

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
	gear.pressed.connect(func(): _open_settings_page("menu"))
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
	# v1.41 (F2): Beleg - Inhalt darf die Panel-Innenbreite nicht ueberschreiten
	var row3 := start_screen.find_child("StartRow3", true, false) as Control
	var modus: int = int(game_manager.game_mode) if game_manager != null else -1
	var bx: Vector2 = sbox.get_combined_minimum_size()
	var r3: Vector2 = row3.get_combined_minimum_size() if row3 != null else Vector2.ZERO
	var innen: float = maxf(bx.x, 900.0)
	var ueberlauf: bool = r3.x > innen + 1.0
	print("[MENU][LAYOUT] modus=%d box=(%.0f,%.0f) row3=(%.0f,%.0f) ueberlauf=%s" % [
		modus, bx.x, bx.y, r3.x, r3.y, str(ueberlauf)])


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
	if challenge_page:
		challenge_page.hide()
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
	h2.text = "DEIN HELD FUER DIESEN RUN"
	h2.label_settings = _make_label_settings(24, Color(0.72, 0.86, 0.96), 5)
	h2.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	hcol.add_child(h2)
	var items: Array = []
	# Ausgeruesteter Held
	var pcol: int = int(game_manager.p_color)
	var phat: int = int(game_manager.p_hat)
	var prig: int = int(game_manager.p_rig)
	var hero_txt: String = Loc.fmt("HELD: %s", [str(game_manager.p_name)])
	if prig > 0:
		hero_txt += "  ·  " + Loc.t("SKIN: ") + Loc.t(str(TextureManager.RIG_NAMES[clampi(prig, 0, 5)]))
	else:
		hero_txt += "  ·  " + Loc.t("FARBE: ") + Loc.t(str(TextureManager.COLOR_NAMES[pcol])) + "  ·  " + Loc.t("HUT: ") + Loc.t(str(TextureManager.HAT_NAMES[phat]))
	items.append(hero_txt)
	# Gekaufte Karten-Inhalte dieser Session (Skins/Farben/Huete sind dauerhaft)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	confirm_box.add_child(grid)
	if items.is_empty():
		var none_l := Label.new()
		none_l.text = "Der Run startet mit deinem gewaehlten Helden."
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
	# v1.43 (B29): Auf breiten Displays (2400x1080) lief der Kopf-Panel ueber die
	# volle Breite und der HELD-Chip klebte am linken Rand. Jetzt zentrieren
	# sich alle Bloecke auf ihre Mindestbreite.
	for c in confirm_box.get_children():
		if c is Control and (c as Control).get_index() > 0:
			(c as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
			game_manager.call("start_game_deferred"))
	brow.add_child(go)

func _create_char_page() -> void: _char_p()._create_char_page()


func _char_field(key: String, caption: String) -> Control: return _char_p()._char_field(key, caption)


func _on_char_field(key: String) -> void: _char_p()._on_char_field(key)


func _field_unlocked(key: String) -> Array: return _char_p()._field_unlocked(key)


func _field_total(key: String) -> int: return _char_p()._field_total(key)


func _field_icon(key: String, idx: int) -> Texture2D: return _char_p()._field_icon(key, idx)


func _rar_col(idx: int) -> Color:
	# Rahmenfarbe aus der Seltenheit des Items (Hut/Kosmetik)
	var r: String = ""
	if idx >= 0 and idx < game_manager.HAT_RARITY.size():
		r = str(game_manager.HAT_RARITY[idx])
	match r:
		"rare":
			return Color(0.35, 0.65, 0.95)
		"epic":
			return Color(0.72, 0.45, 0.95)
		"legendary":
			return Color(0.99, 0.72, 0.20)
	return Color(0.55, 0.60, 0.68)


func _open_choice_overlay(key: String) -> void: _char_p()._open_choice_overlay(key)


func _close_choice_overlay() -> void: _char_p()._close_choice_overlay()


func _apply_choice(key: String, idx: int) -> void: _char_p()._apply_choice(key, idx)


func refresh_char_fields() -> void: _char_p().refresh_char_fields()


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
	# Runde 30: Listen per Finger-Drag scrollen - global, weil Item-Buttons die
	# Drag-Events schlucken. v1.48 (B2): gilt fuer ALLE Seiten-Listen
	# (Sammlung, Shop) und protokolliert jeden Zug als Beleg.
	var ziel: Array = _scroll_ziel()
	if ziel.is_empty():
		_drag_reset()
		return
	var seite: String = str(ziel[0])
	var sc: ScrollContainer = ziel[1]
	# Mausrad scrollt die Liste (der Container selbst hoert nicht mehr zu)
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			sc.scroll_vertical += 120 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -120
			return
	var pos_y: float = -99999.0
	if event is InputEventScreenDrag:
		pos_y = (event as InputEventScreenDrag).position.y
	elif event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pos_y = (event as InputEventMouseMotion).position.y
	if pos_y > -9999.0:
		# v1.48 (B2): Delta aus den POSITIONEN rechnen, nicht aus relative -
		# bei gestreckter UI sind die relativen Werte nicht in Canvas-Pixeln.
		#
		# v1.56c (Bug 3): ERST ab TIPP_SCHWELLE als Zug behandeln. Vorher wurde
		# JEDE Fingerbewegung geschluckt (`set_input_as_handled`) - ein Tipp auf
		# einen Knopf in einer Scroll-Liste verlor dadurch das Release, sobald
		# der Finger 8 px wanderte (auf dem Geraet normal). Messung: Zug 3 px =
		# Kiste oeffnet, Zug 8/14/25 px = Kiste oeffnet NICHT.
		var dy: float = 0.0
		if _drag_last_y > -9999.0:
			dy = pos_y - _drag_last_y
		_drag_last_y = pos_y
		_drag_gesamt += absf(dy)
		if _drag_gesamt < TIPP_SCHWELLE:
			return                       # noch ein Tipp - Knopf bekommt das Event
		if _drag_seite == "":
			_drag_seite = seite
			_drag_von = sc.scroll_vertical
			_drag_px = 0.0
		if absf(dy) > 0.0:
			sc.scroll_vertical -= int(dy * 1.6)
			_drag_px += absf(dy * 1.6)
			_drag_nach = sc.scroll_vertical
		get_viewport().set_input_as_handled()
		return
	var ende: bool = false
	if event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		ende = true
	elif event is InputEventMouseButton and not (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		ende = true
	if ende and _drag_gesamt < TIPP_SCHWELLE:
		# Kurzer Tipp in einer Liste: durchlassen, damit der Knopf ihn bekommt.
		print("[SCROLL][TIPP] seite=%s px=%.0f schwelle=%.0f durchgelassen=true" % [
			seite, _drag_gesamt, TIPP_SCHWELLE])
		_drag_reset()
		return
	if ende and _drag_seite != "":
		print("[SCROLL][ZUG] seite=%s von=%d nach=%d px=%d" % [
			_drag_seite, _drag_von, _drag_nach, int(_drag_px)])
		if _drag_seite == "collection":
			var kurz: bool = _drag_px < 12.0
			print("[COLL][KLICK] skin=%d ausgeloest=false grund=readonly tipp_px=%d kurz=%s" % [
				-1, int(_drag_px), str(kurz)])
	_drag_reset()


func _drag_reset() -> void:
	_drag_gesamt = 0.0
	_drag_seite = ""
	_drag_von = 0
	_drag_nach = 0
	_drag_px = 0.0
	_drag_last_y = -99999.0


func _scroll_ziel() -> Array:
	# Erstes sichtbares Scroll-Ziel: Sammlung vor Shop.
	if collection_page != null and collection_page.visible:
		var cs = collection_page.find_child("CollectionScroll", true, false)
		if cs is ScrollContainer:
			return ["collection", cs]
	if shop_scroll != null:
		var aktiv: bool = (shop_panel != null and shop_panel.visible) \
			or (chest_page != null and chest_page.visible)
		if aktiv:
			return ["shop", shop_scroll]
	return []


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# v1.42 (P1.6): ESC in den Einstellungen wirkt wie ZURUECK
		# v1.43 (S1.4): zusaetzlich die Aktion ui_cancel (Gamepad B / Android)
		if (event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel")) \
				and settings_page != null and settings_page.visible:
			print("[MENU][SETTINGS] esc=true")
			_close_settings_page()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if game_manager != null and game_manager.has_method("toggle_pause"):
				game_manager.call("toggle_pause")
		elif event.keycode == KEY_A and game_manager != null and game_manager.current_state == 1:
			game_manager.call("cycle_game_mode")


func _notification(what: int) -> void:
	# v1.43 (S1.4): Android-Zurueck schliesst die Einstellungen.
	# Ohne das blieb die Seite bei Geraeten ohne ESC offen (Sackgasse).
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_button()


func _handle_back_button() -> void:
	# v1.43: Zurueck ist eine Navigation, kein Beenden (quit_on_go_back=false).
	if settings_page != null and settings_page.visible:
		print("[TAP] back_key einstellungen_geschlossen=true")
		_close_settings_page()
		get_viewport().set_input_as_handled()
		return
	if pause_overlay != null and is_instance_valid(pause_overlay) and pause_overlay.visible:
		print("[TAP] back_key pause_geschlossen=true")
		if game_manager != null:
			game_manager.paused = false
		get_tree().paused = false
		hide_pause()
		get_viewport().set_input_as_handled()
		return
	var offene: Array = []
	for seite in [char_page, shop_page, maps_page, collection_page, challenge_page, chest_page, confirm_page]:
		if seite != null and is_instance_valid(seite) and (seite as Control).visible:
			offene.append(seite)
	if not offene.is_empty():
		print("[TAP] back_key seiten_geschlossen=%d" % offene.size())
		_close_pages()
		get_viewport().set_input_as_handled()
		return
	if game_manager != null and int(game_manager.get("current_state")) == 2:
		print("[TAP] back_key pause_geoeffnet=true")
		show_pause()
		get_viewport().set_input_as_handled()
		return
	print("[TAP] back_key im_hauptmenue=true (ignoriert)")

func show_pause() -> void: _pause_p().show_pause()

func hide_pause() -> void: _pause_p().hide_pause()

func _on_difficulty_set(i: int) -> void: _pause_p()._on_difficulty_set(i)

func _on_aim_set(i: int) -> void: _pause_p()._on_aim_set(i)

func refresh_difficulty_ui() -> void: _pause_p().refresh_difficulty_ui()

func refresh_aim_ui() -> void: _pause_p().refresh_aim_ui()

# Reihen in der Einstellungsseite mitziehen (falls dort ebenfalls vorhanden)
func _sync_setting_rows() -> void: _pause_p()._sync_setting_rows()

func show_tip(text: String) -> void: _pause_p().show_tip(text)

func _on_lang_set(code: String) -> void: _set_p()._on_lang_set(code)


func refresh_lang_buttons() -> void: _set_p().refresh_lang_buttons()


func _create_settings_page() -> void: _set_p()._create_settings_page()

# ---------------- Navigation ----------------
func _open_char_page() -> void:
	if char_page == null:
		return
	# Runde 48: alle anderen Seiten schliessen - sonst stapeln sich
	# Shop/Charakter/Sammlung uebereinander (der Shop blieb sichtbar).
	_close_pages()
	char_page.show()
	refresh_profile_ui()

func _open_settings_page(origin: String = "") -> void:
	# v1.42 (P1): Die Einstellungen merken sich ihren Aufrufer. Aus der Pause
	# darf die Startseite NICHT aufgehen (sie lag vorher hinter den Einstellungen
	# und der Run galt als verlassen).
	if settings_page == null:
		return
	var org: String = origin
	if org == "":
		org = "pause" if pause_overlay != null else "menu"
	settings_origin = org
	if org == "pause":
		# Pause-Overlay weg, Spiel bleibt pausiert, Startseite bleibt verborgen
		hide_pause()
		if game_manager != null:
			game_manager.paused = true
		get_tree().paused = true
		if start_screen:
			start_screen.hide()
	elif org == "run":
		# Gear im HUD: Spiel anhalten, Einstellungen zeigen
		if game_manager != null and game_manager.current_state == 1 and not game_manager.paused:
			game_manager.paused = true
			get_tree().paused = true
		if start_screen:
			start_screen.hide()
	else:
		_close_pages()
	settings_page.show()
	settings_page.z_index = 230
	# Runde 48: die Einstellungs-Seite nach oben in die Zeichenreihenfolge
	# holen, damit sie ueber den anderen Seiten liegt.
	if settings_page.get_parent() != null:
		var par := settings_page.get_parent()
		par.move_child(settings_page, par.get_child_count() - 1)
	refresh_settings_ui()
	# v1.46 (I1-I3): Pause-Aufruf ohne Schwierigkeit/Biom, Menue mit.
	_set_p().apply_origin(org)
	var ss_vis: bool = start_screen.visible if start_screen != null else false
	print("[MENU][SETTINGS] origin=%s start_screen_sichtbar=%s pause_offen=%s paused=%s" % [
		org, str(ss_vis), str(pause_overlay != null), str(get_tree().paused)])

	# v1.43 (S1.1/S2.1): Layout-Beleg - Inhalt, Scroll, fester Fuss, Ueberlauf
	var li: Dictionary = _set_p().layout_info()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var inhalt: Vector2 = li.get("inhalt", Vector2.ZERO)
	var fy: float = float(li.get("footer_y", 0.0))
	var fh: float = float(li.get("footer_h", 0.0))
	var max_rechts: float = 0.0
	if settings_page != null:
		for c in settings_page.find_children("*", "Control", true, false):
			var cc := c as Control
			if cc.is_visible_in_tree():
				max_rechts = maxf(max_rechts, cc.get_global_rect().end.x)
	print("[LAYOUT] einstellungen inhalt=(%.0f,%.0f) canvas=(%.0f,%.0f) scroll=%s knopf_fuss=%s knopf_y=%.0f knopf_h=%.0f ueberlauf=%s fehlt_unten=%.0f max_rechts=%.0f" % [
		inhalt.x, inhalt.y, vp.x, vp.y, str(bool(li.get("scroll", false))),
		str(bool(li.get("footer", false))), fy, fh,
		str(fy + fh > vp.y + 0.5), maxf(0.0, fy + fh - vp.y), max_rechts])
	if ss_vis and org == "pause":
		printerr("[MENU][SETTINGS] FEHLER: Startseite sichtbar aus der Pause")


func _close_settings_page() -> void:
	# v1.42 (P1.3): ZURUECK kehrt zum Aufrufer zurueck.
	var org: String = settings_origin
	if settings_page:
		settings_page.hide()
	settings_origin = "menu"
	if org == "pause":
		# Pause-Overlay wieder aufbauen, Spiel bleibt pausiert
		if game_manager != null:
			game_manager.paused = true
		get_tree().paused = true
		show_pause()
		print("[MENU][SETTINGS] zurueck=pause pause_offen=%s paused=%s" % [
			str(pause_overlay != null), str(get_tree().paused)])
		return
	if org == "run":
		if game_manager != null:
			game_manager.paused = false
		get_tree().paused = false
		print("[MENU][SETTINGS] zurueck=run paused=false")
		return
	_close_pages()
	print("[MENU][SETTINGS] zurueck=menu")

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
	# v1.44 (C8): Aufgaben-Seite mit schliessen
	if challenge_page:
		challenge_page.hide()
	# Runde 74: Kisten-Seite wurde nie geschlossen -> Zurueck tat nichts
	if chest_page:
		chest_page.hide()
	# v1.48 (D1): Info-Seite mit schliessen
	if info_page:
		info_page.hide()
	if start_screen:
		start_screen.show()
	# Runde 40: die Run-Uebersicht ist auch eine Seite - sonst liegt sie
	# beim Zurueck zur Startseite weiter ueber dem Menue
	if confirm_page:
		confirm_page.hide()
	refresh_profile_ui()

func _on_quality_set(i: int) -> void: _set_p()._on_quality_set(i)

func _on_music_pressed() -> void: _set_p()._on_music_pressed()

func _on_sfx_pressed() -> void: _set_p()._on_sfx_pressed()

func refresh_settings_ui() -> void: _set_p().refresh_settings_ui()

func set_quality_label(name: String) -> void:
	if quality_info_label:
		quality_info_label.set_meta("tier_name", name)
	refresh_settings_ui()
func _create_death_screen(): return _death_p()._create_death_screen()

# Boss-Warnung (kurzer roter Blink-Banner)
func update_season_hud(cur_name: String, next_name: String, col: Color) -> void: _hud_p().update_season_hud(cur_name, next_name, col)


func set_boss_name(txt: String) -> void:
	if boss_name_label == null:
		return
	boss_name_label.text = txt
	boss_name_label.visible = txt != ""
	print("[BOSS][NAME] %s" % txt)


func hide_boss_bar() -> void:
	# Runde 26: Leiste ausblenden, wenn kein Boss mehr da ist
	if boss_bar != null:
		boss_bar.visible = false
		boss_bar.modulate.a = 1.0
	if boss_name_label != null:
		boss_name_label.visible = false

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


func _build_disconnect_screen() -> void: _disc_p()._build_disconnect_screen()


func show_disconnect_screen(msg: String = "VERBINDUNG ZUM HOST ABGEBROCHEN") -> void: _disc_p().show_disconnect_screen(msg)


func hide_disconnect_screen() -> void: _disc_p().hide_disconnect_screen()


func _on_disconnect_back() -> void: _disc_p()._on_disconnect_back()


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

func show_hud() -> void: _hud_p().show_hud()

func show_death_screen(current_score: int, best_score: int, gold_gain: int = 0, gold_total: int = 0) -> void: _death_p().show_death_screen(current_score, best_score, gold_gain, gold_total)

func set_start_score(score: int) -> void:
	var label = start_screen.find_child("BestScoreLabel", true, false)
	if label and score > 0:
		label.text = "Best Score: %d" % score

func update_health(current: int, maximum: int, pid: int = 1) -> void: _hud_p().update_health(current, maximum, pid)

func update_combo(count: int, mult: float) -> void: _hud_p().update_combo(count, mult)

func update_score(new_score: int) -> void: _hud_p().update_score(new_score)

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
	# Runde 136 (D): die drei Felder des neuen Fensters
	refresh_char_fields()
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
		char_name_chip.text = nm
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
		if m == 2:
			mode_btn.text = Loc.t("MODUS: RUNDEN")
		elif m == 1:
			mode_btn.text = Loc.t("MODUS: WELLEN + SHOP")
		else:
			mode_btn.text = Loc.t("MODUS: ENDLOS")
	refresh_difficulty_label()


func refresh_mode_labels() -> void:
	# v1.41 (F5): nach dem Sprachwechsel alle v1.40-Etiketten neu bauen.
	if game_manager == null:
		return
	set_mode_label(int(game_manager.game_mode))
	var h = hud
	if h != null and is_instance_valid(h):
		if h.get("wave_shop_btn") != null:
			(h.get("wave_shop_btn") as Button).text = Loc.t("SHOP")
		if h.get("wave_next_btn") != null:
			(h.get("wave_next_btn") as Button).text = Loc.t("WELLE >>")
	if int(game_manager.game_mode) == 2:
		var rm = game_manager.get("rounds_mode")
		if rm != null:
			update_wave_label(int(rm.get("round_no")), int(game_manager.coins),
				bool(rm.get("intermission")), -1.0, int(rm.get("alive")))
	print("[MENU][LOC] etiketten neu gebaut modus=%d sprache=%s" % [int(game_manager.game_mode), Loc.lang])

# ============================================================
# WELLEN-MODUS: Anzeige + Shop (Punkt 6)
# ============================================================
func update_wave_label(w: int, coins_v: int, shop: bool, t: float, remaining: int = 0, level_now: int = 0, level_goal: int = 0) -> void: _hud_p().update_wave_label(w, coins_v, shop, t, remaining, level_now, level_goal)

# ============================================================
# v1.40: RUNDEN-Modus - Icons im HUD + eigener Shop
# ============================================================
func set_wave_icons(shop: bool, next: bool) -> void: _hud_p().set_wave_icons(shop, next)
func set_rounds_preview(txt: String) -> void: _hud_p().set_rounds_preview(txt)

func open_rounds_shop() -> void:
	# Overlay des Wellen-Shops (pausiert den Baum ueber game_manager)
	if game_manager == null:
		return
	if wave_shop != null and is_instance_valid(wave_shop):
		wave_shop.queue_free()
	wave_shop = load("res://scripts/ui/overlays/wave_shop.gd").new()
	add_child(wave_shop)
	wave_shop.call("open", game_manager)
	print("[WSHOP][UI] offen=true")
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


func update_shop_coins(coins_v: int, buys_left: int = -1, buys_max: int = -1) -> void: _shoprun_p().update_shop_coins(coins_v, buys_left, buys_max)


func show_shop(coins_v: int, items: Array, buys_left: int = -1, buys_max: int = -1) -> void: _shoprun_p().show_shop(coins_v, items, buys_left, buys_max)

func _ui_k() -> float:
	# Runde 29: UI auf die Bildschirmgroesse skalieren (kleine Fenster/Handys)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	return clampf(minf(vp.y / 1000.0, vp.x / 1700.0), 0.50, 1.25)

func _build_shop() -> void: _shoprun_p()._build_shop()

func _on_shop_buy(id: String) -> void: _shoprun_p()._on_shop_buy(id)

func _on_shop_continue() -> void: _shoprun_p()._on_shop_continue()

func hide_shop() -> void: _shoprun_p().hide_shop()

func set_fps_label(on: bool) -> void: _hud_p().set_fps_label(on)


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

func update_target_arrow(show_it: bool, dir: Vector2) -> void: _hud_p().update_target_arrow(show_it, dir)

func update_boss_hp(cur: int, mx: int) -> void: _hud_p().update_boss_hp(cur, mx)

func update_xp(new_level: int, cur: int, needed: int) -> void: _hud_p().update_xp(new_level, cur, needed)

# Wahlkarten-Overlay (Stil B: Spiel pausiert, 3 Upgrades zur Auswahl)
func show_upgrade_cards(options: Array, idx: int = 1, total: int = 1) -> void: _cards_p().show_upgrade_cards(options, idx, total)


func _on_card_pressed(card: Button) -> void: _cards_p()._on_card_pressed(card)

func hide_upgrade_cards() -> void: _cards_p().hide_upgrade_cards()


# ============================================================
# Runde 136 (H1): Endlos-Modus - Hinweis statt Spielstopp
# Ein kleiner Toast unten mittig, das Spiel laeuft weiter. Er bleibt
# stehen, bis der Spieler tippt (kein Timeout), und zaehlt hoch, wenn
# waehrenddessen ein weiteres Upgrade dazukommt.
# ============================================================
func show_upgrade_toast(n: int) -> void: _toast_p().show_upgrade_toast(n)


func _toast_text(n: int) -> String: return _toast_p()._toast_text(n)


func _pop_toast(node: Control) -> void: _toast_p()._pop_toast(node)


func hide_upgrade_toast() -> void: _toast_p().hide_upgrade_toast()


func has_upgrade_toast() -> bool: return _toast_p().has_upgrade_toast()

# ============================================================
# MITSPIELER-LISTE (bis zu 3 Mitspieler, Runde 10)
# ============================================================
func update_partner_slot(slot: int, hp: int, mx: int, weapon_name: String, shield: int, pname: String = "") -> void: _hud_p().update_partner_slot(slot, hp, mx, weapon_name, shield, pname)

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
func _build_lobby() -> void: _lobby_p()._build_lobby()

func show_lobby(is_host: bool, slot: int) -> void: _lobby_p().show_lobby(is_host, slot)

func update_lobby(roster: Dictionary, max_players: int, is_host: bool) -> void: _lobby_p().update_lobby(roster, max_players, is_host)

func hide_lobby() -> void: _lobby_p().hide_lobby()

func _on_lobby_ready_pressed() -> void: _lobby_p()._on_lobby_ready_pressed()

func _on_lobby_start_pressed() -> void: _lobby_p()._on_lobby_start_pressed()

func _on_lobby_leave_pressed() -> void: _lobby_p()._on_lobby_leave_pressed()

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
# ============================================================
# Runde 67: KISTEN-SEITE (Edelsteine + Kosmetik-Kisten)
# ============================================================
var chest_page: Control = null
var gems_label: Control = null
var chest_msg: Label = null


func _open_chest_page() -> void: _shop_p()._open_chest_page()


func _create_chest_page() -> void: _shop_p()._create_chest_page()


func _num_dots(v: int) -> String: return _shop_p()._num_dots(v)






func _open_slot_ui() -> void:
	var ui = load("res://scripts/slot_ui.gd").new()
	ui.setup(game_manager)
	add_child(ui)
	if chest_page != null:
		chest_page.hide()
	if start_screen != null:
		start_screen.hide()
	ui.call("open")
	ui.connect("closed", func():
		if chest_page != null:
			chest_page.show()
		if start_screen != null:
			start_screen.show()
		refresh_chest_page())
	print("[SLOT][UI] Seite geoeffnet")


# ============================================================
# v1.45 (C11/C14): Aufgaben-HUD + Ergebnis-Fenster
# ============================================================
var chal_hud: Label = null
var chal_result: Control = null


func set_challenge_hud(txt: String) -> void:
	if hud == null or not is_instance_valid(hud):
		return
	if chal_hud == null or not is_instance_valid(chal_hud):
		chal_hud = Label.new()
		chal_hud.name = "ChallengeHud"
		chal_hud.position = Vector2(40, 150)
		chal_hud.size = Vector2(1100, 48)
		chal_hud.label_settings = _make_label_settings(28, Color(1.0, 0.86, 0.42), 8)
		chal_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chal_hud.z_index = 30
		chal_hud.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.add_child(chal_hud)
	chal_hud.text = "CHALLENGE · " + txt
	chal_hud.visible = true
	print("[CHAL][HUD] prefix=CHALLENGE text=%s" % txt)


func hide_challenge_hud() -> void:
	if chal_hud != null and is_instance_valid(chal_hud):
		chal_hud.visible = false


func show_challenge_result(id: String, stufe: String, gewonnen: bool, gems: int,
		fortschritt: int, runden_max: int, grund: String) -> void:
	# C14: Ergebnis-Fenster am Run-Ende. Bleibt stehen, bis WEITER gedrueckt wird
	# (Prozess laeuft weiter, damit der Knopf auch bei pausiertem Spiel wirkt).
	if chal_result != null and is_instance_valid(chal_result):
		chal_result.queue_free()
	chal_result = Control.new()
	chal_result.name = "ChalResult"
	chal_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	chal_result.z_index = 120
	chal_result.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(chal_result)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	chal_result.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(900, 0)
	panel.offset_left = -450
	panel.offset_right = 450
	panel.offset_top = -260
	panel.offset_bottom = 260
	var rand_col := Color(0.30, 0.78, 0.45) if gewonnen else Color(0.95, 0.45, 0.35)
	panel.add_theme_stylebox_override("panel", _comic_panel_sb(Color(0.09, 0.10, 0.16, 0.99), rand_col, 7, 26))
	chal_result.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)

	var titel := Label.new()
	titel.text = "CHALLENGE GESCHAFFT!" if gewonnen else "CHALLENGE VERFEHLT"
	titel.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	titel.label_settings = _make_label_settings(58, rand_col, 12)
	col.add_child(titel)

	var def: Dictionary = game_manager.call("chal_defs").filter(func(d): return str(d["id"]) == id)[0]
	var name_lbl := Label.new()
	name_lbl.text = str(def.get("name", id))
	name_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.label_settings = _make_label_settings(36, Color(1.0, 0.90, 0.45), 8)
	col.add_child(name_lbl)

	var stufe_lbl := Label.new()
	stufe_lbl.text = "STUFE %s  ·  %d/%d RUNDEN" % [str(stufe).to_upper(), fortschritt, runden_max]
	stufe_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	stufe_lbl.label_settings = _make_label_settings(26, Color(0.86, 0.92, 0.98), 4)
	col.add_child(stufe_lbl)

	var reward := Label.new()
	reward.text = ("BELOHNUNG: +%d DIAMANTEN  ·  auf der Karte abholen" % gems) if gewonnen else ("GRUND: %s  ·  Fortschritt bleibt erhalten" % grund)
	reward.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	reward.label_settings = _make_label_settings(24, Color(0.55, 1.0, 0.70) if gewonnen else Color(0.95, 0.72, 0.60), 4)
	col.add_child(reward)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btn_row)
	var weiter: Button = _make_pixel_button("WEITER", Color(0.98, 0.80, 0.20), 34)
	weiter.name = "ChalResultWeiter"
	weiter.custom_minimum_size = Vector2(360, 78)
	weiter.pressed.connect(_close_challenge_result)
	btn_row.add_child(weiter)
	print("[CHAL][BANNER] id=%s gewonnen=%s gems=%d grund=%s" % [id, str(gewonnen), gems, grund])


func _close_challenge_result() -> void:
	hide_challenge_hud()
	if chal_result != null and is_instance_valid(chal_result):
		chal_result.queue_free()
		chal_result = null
	if game_manager != null:
		game_manager.call("quit_to_menu")


func _open_wheel_ui() -> void:
	# v1.45 (Z7): zweiter Automat - eigenes Overlay, gleiche Rueckkehr wie die Walze.
	var ui = load("res://scripts/ui/wheel_ui.gd").new()
	ui.setup(game_manager)
	add_child(ui)
	if chest_page != null:
		chest_page.hide()
	if start_screen != null:
		start_screen.hide()
	ui.call("open")
	ui.connect("closed", func():
		if chest_page != null:
			chest_page.show()
		if start_screen != null:
			start_screen.show()
		refresh_chest_page())
	print("[WHEEL][UI] Seite geoeffnet quelle=shop")


func refresh_chest_page() -> void: _shop_p().refresh_chest_page()


func _on_gem_package(i: int) -> void: _shop_p()._on_gem_package(i)


var _chest_kauf_ms: int = 0        # v1.57b: Doppelkauf-Schutz (Tipp + Karte)

func _on_chest_open(chest_id: String) -> void:
	if game_manager == null:
		return
	# v1.57b: Karte UND Knopf loesen denselben Kauf aus (grosse Trefferflaeche).
	# Ein Doppel-Tipp auf dem Handy darf nur EINE Kiste kaufen.
	var jetzt: int = Time.get_ticks_msec()
	if jetzt - _chest_kauf_ms < 600:
		print("[TOUCH][DOPPEL] tier=%s ignoriert (%.0f ms seit dem letzten Kauf)" % [
			chest_id, float(jetzt - _chest_kauf_ms)])
		return
	_chest_kauf_ms = jetzt
	# Flash beim Kauf: kurzer weisser Blitz ueber der Seite
	var fl := ColorRect.new()
	fl.color = Color(1, 1, 1, 0)
	fl.anchor_right = 1.0
	fl.anchor_bottom = 1.0
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_page.add_child(fl)
	var ftw := fl.create_tween()
	ftw.tween_property(fl, "color:a", 0.75, 0.06)
	ftw.tween_property(fl, "color:a", 0.0, 0.22)
	ftw.tween_callback(fl.queue_free)
	var gems_vor: int = int(game_manager.gems)
	var res: Dictionary = game_manager.call("buy_chest", chest_id)
	print("[SHOP][KAUF] tier=%s abgebucht=%d gems_vorher=%d nachher=%d ok=%s" % [
		chest_id, gems_vor - int(game_manager.gems), gems_vor, int(game_manager.gems),
		str(bool(res.get("ok", false)))])
	refresh_chest_page()
	if not bool(res.get("ok", false)):
		if chest_msg != null:
			chest_msg.text = "Nicht genug Edelsteine für die Kiste"
		# v1.57b: Der kleine Hinweis am Seitenende wird auf dem Handy uebersehen -
		# deshalb zusaetzlich ein deutliches Banner + Log mit den Zahlen.
		show_banner("NICHT GENUG DIAMANTEN", Color(1.0, 0.45, 0.35))
		print("[TOUCH][KAUF] tier=%s ok=false grund=zu_wenig_diamanten haben=%d braucht=%d" % [
			chest_id, int(game_manager.gems), int(LootTable.chest_cost(chest_id))])
		return
	# v1.52: Standard ist die neue Inszenierung (chest_open_ui); das alte
	# Laufband bleibt per COMIC_CHEST_STYLE=0 erreichbar (Golden-Referenz).
	var stil_env: String = OS.get_environment("COMIC_CHEST_STYLE")
	var neuer_weg: bool = stil_env != "0"
	print("[CHEST][PFAD] oeffnung=%s" % ("chest_open_ui" if neuer_weg else "chest_ui (alt)"))
	var ui = load("res://scripts/ui/chest_open_ui.gd" if neuer_weg else "res://scripts/ui/chest_ui.gd").new()
	ui.setup(game_manager)
	add_child(ui)
	# Seite ausblenden, sonst scheint der Text durch Titel und Laufband
	if chest_page != null:
		chest_page.hide()
	if start_screen != null:
		start_screen.hide()
	ui.call("open", chest_id, res)
	ui.connect("closed", _on_chest_closed)


func _on_chest_closed() -> void:
	# v1.39 B4: eigener Weg (statt Lambda), damit der Diag-Modus denselben
	# Code benutzt und der Shop-Refresh im Log belegt ist.
	if chest_page != null:
		chest_page.show()
	if start_screen != null:
		start_screen.show()
	refresh_chest_page()
	refresh_shop_ui()
	_sui("CHEST", "geschlossen -> shop refresh (chest_page=%s)" % str(
		chest_page != null and chest_page.visible))


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
func _on_chest_buy(tier_id: String) -> void: _shop_p()._on_chest_buy(tier_id)


func _show_chest_confirm(tier_id: String) -> void: _shop_p()._show_chest_confirm(tier_id)


func _on_chest_confirm() -> void: _shop_p()._on_chest_confirm()

func _chest_icon_texture(res: Dictionary) -> Texture2D:
	# v1.52: Der Gewinn zeigt SICH SELBST. Vorher fiel fast alles auf das
	# Kisten-Icon zurueck (res hat kein "icon"-Feld) - genau das hat der Nutzer
	# als "statt der Items kommen die Kisten" gesehen.
	var kind := str(res.get("kind", ""))
	var idx := int(res.get("index", -1))
	var tex: Texture2D = null
	match kind:
		"hat":
			tex = TextureManager.get_hat_only_texture(idx)
		"skin":
			tex = TextureManager.get_skin_texture(int(game_manager.get("p_color")), idx)
		"color":
			tex = TextureManager.get_skin_texture(idx, int(game_manager.get("p_rig")))
		"gold":
			tex = TextureManager.get_texture("slot_gold1")
		"gems":
			tex = TextureManager.get_texture("slot_gem1")
	if tex == null:
		tex = TextureManager.get_texture("chest")
	print("[CHEST][ICON] kind=%s index=%d tex=%s eigenes_item=%s" % [
		kind, idx, "ja" if tex != TextureManager.get_texture("chest") else "kiste_fallback",
		str(kind == "hat" or kind == "skin" or kind == "color")])
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

func _create_maps_page() -> void: _maps_p()._create_maps_page()

func refresh_maps_ui() -> void: _maps_p().refresh_maps_ui()

func _on_season_mode(planet: String, mode: String) -> void: _maps_p()._on_season_mode(planet, mode)


func _on_season_pressed(planet: String, sid: String) -> void: _maps_p()._on_season_pressed(planet, sid)

func _on_map_action(mid: String) -> void: _maps_p()._on_map_action(mid)

# ============================================================
# Runde 37: SAMMLUNG (Cosmetics-Uebersicht)
# ============================================================

func _readonly_tile(b: Button) -> void: _coll_p()._readonly_tile(b)


func show_collection() -> void: _coll_p().show_collection()


# ============================================================
# v1.44 (C): AUFGABEN (Challenges)
# ============================================================

var _chalp: ChallengePage = null

func _challenge_p() -> ChallengePage:
	if _chalp == null:
		_chalp = ChallengePage.new()
		_chalp.host = self
	return _chalp


func _open_challenge_page() -> void:
	if challenge_page == null:
		_create_challenge_page()
	_close_pages()
	challenge_page.show()
	refresh_challenges_ui()
	# C4: Layout-Beleg beim echten Oeffnen. Erst ein Frame warten - vorher
	# stehen alle Rect2 noch auf (0,0), weil Godot das Layout erst danach rechnet.
	await get_tree().process_frame
	var li: Dictionary = _challenge_p().layout_info()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var inhalt: Vector2 = li.get("inhalt", Vector2.ZERO)
	var r: Rect2 = li.get("knopf_rect", Rect2())
	var sichtbar: bool = r.size.y > 0.0 and r.end.y <= vp.y + 0.5 and r.position.y >= 0.0
	print("[LAYOUT] seite=aufgaben inhalt=(%.0f,%.0f) canvas=(%.0f,%.0f) ueberlauf=%s max_rechts=%.0f" % [
		inhalt.x, inhalt.y, vp.x, vp.y, str(inhalt.y > vp.y - 40.0), float(li.get("max_rechts", 0.0))])
	print("[TAP] seite=aufgaben knopf=ZURUECK rect=(%.0f,%.0f)-(%.0f,%.0f) sichtbar_im_bild=%s" % [
		r.position.x, r.position.y, r.end.x, r.end.y, str(sichtbar)])


func _create_challenge_page() -> void: _challenge_p()._create_challenge_page()


func refresh_challenges_ui() -> void: _challenge_p().refresh_challenges_ui()

func _build_collection_page() -> void: _coll_p()._build_collection_page()

func _refresh_skin_buttons() -> void: _coll_p()._refresh_skin_buttons()

# --- v1.48 (D1): INFO-Seite ---
const InfoPageScript = preload("res://scripts/ui/pages/info_page.gd")
var _info = null

func _info_p():
	if _info == null:
		_info = InfoPageScript.new()
		_info.host = self
	return _info


func _open_info_page() -> void:
	_info_p().open("settings")


func _close_info_page() -> void:
	_info_p().close()


func _make_cat_section(parent: VBoxContainer, title: String, count: String, col: Color, columns: int) -> VBoxContainer: return _coll_p()._make_cat_section(parent, title, count, col, columns)


func _add_cat_header(grid: GridContainer, title: String, count: String, col: Color) -> void: _coll_p()._add_cat_header(grid, title, count, col)


func refresh_collection_ui() -> void: _coll_p().refresh_collection_ui()


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


func _open_stats_page() -> void: _stats_p()._open_stats_page()


func _build_stats_page() -> void: _stats_p()._build_stats_page()


# Runde 49: Die echten Waffendaten (Spiegel von player_controller.gd,
# damit die Werte dort nicht nur im Spiel sichtbar sind)
const WEAPON_STAT_VALUES := {
	"weapon_pistol": { "damage": 3, "cooldown": 0.4, "mag": 0, "reload": 0.0 },
	"weapon_shotgun": { "damage": 5, "cooldown": 0.8, "mag": 6, "reload": 2.4 },
	"weapon_machine": { "damage": 2, "cooldown": 0.1, "mag": 40, "reload": 2.2 },
	"weapon_laser": { "damage": 2, "cooldown": 0.14, "mag": 24, "reload": 1.6 },
	"weapon_revolver": { "damage": 9, "cooldown": 1.05, "mag": 6, "reload": 1.9 },
}


func _weapon_stat_values(key: String) -> Array: return _stats_p()._weapon_stat_values(key)


func _refresh_stats_page() -> void: _stats_p()._refresh_stats_page()


func _toggle_stat_card(card: Control) -> void: _stats_p()._toggle_stat_card(card)


var _shop: ShopPage = null

func _shop_p() -> ShopPage:
	if _shop == null:
		_shop = ShopPage.new()
		_shop.host = self
	return _shop


var _char: CharPage = null

func _char_p() -> CharPage:
	if _char == null:
		_char = CharPage.new()
		_char.host = self
	return _char


var _maps: MapsPage = null

func _maps_p() -> MapsPage:
	if _maps == null:
		_maps = MapsPage.new()
		_maps.host = self
	return _maps


var _set: SettingsPage = null

func _set_p() -> SettingsPage:
	if _set == null:
		_set = SettingsPage.new()
		_set.host = self
	return _set


var _coll: CollectionPage = null

func _coll_p() -> CollectionPage:
	if _coll == null:
		_coll = CollectionPage.new()
		_coll.host = self
	return _coll


var _stats: StatsPage = null

func _stats_p() -> StatsPage:
	if _stats == null:
		_stats = StatsPage.new()
		_stats.host = self
	return _stats


var _cards: UpgradeCards = null

func _cards_p() -> UpgradeCards:
	if _cards == null:
		_cards = UpgradeCards.new()
		_cards.host = self
	return _cards


var _toast: UpgradeToast = null

func _toast_p() -> UpgradeToast:
	if _toast == null:
		_toast = UpgradeToast.new()
		_toast.host = self
	return _toast


var _pause: PauseOverlay = null

func _pause_p() -> PauseOverlay:
	if _pause == null:
		_pause = PauseOverlay.new()
		_pause.host = self
	return _pause


var _death: DeathOverlay = null

func _death_p() -> DeathOverlay:
	if _death == null:
		_death = DeathOverlay.new()
		_death.host = self
	return _death


var _lobby: LobbyOverlay = null

func _lobby_p() -> LobbyOverlay:
	if _lobby == null:
		_lobby = LobbyOverlay.new()
		_lobby.host = self
	return _lobby


var _disc: DisconnectOverlay = null

func _disc_p() -> DisconnectOverlay:
	if _disc == null:
		_disc = DisconnectOverlay.new()
		_disc.host = self
	return _disc


var _shoprun: ShopRunOverlay = null

func _shoprun_p() -> ShopRunOverlay:
	if _shoprun == null:
		_shoprun = ShopRunOverlay.new()
		_shoprun.host = self
	return _shoprun


var _hud: Hud = null

func _hud_p() -> Hud:
	if _hud == null:
		_hud = Hud.new()
		_hud.host = self
	return _hud


# ------------------------------------------------------------
# v1.40: Schwierigkeitsgrad des RUNDEN-Modus (W6.8)
# ------------------------------------------------------------

func _on_difficulty_pressed() -> void:
	if game_manager == null:
		return
	var order: Array = ["leicht", "normal", "hart"]
	var i: int = order.find(str(game_manager.round_difficulty))
	if i < 0:
		i = 1
	game_manager.call("set_round_difficulty", str(order[(i + 1) % order.size()]))
	refresh_difficulty_label()


func refresh_difficulty_label() -> void:
	if diff_btn == null or game_manager == null:
		return
	var d: Dictionary = Rounds.DIFFICULTY.get(str(game_manager.round_difficulty), {})
	var im_runden: bool = int(game_manager.game_mode) == 2
	# v1.41 (F2): Knopf bleibt IMMER sichtbar (sonst waechst row3 und die
	# Startseite verzieht sich). Ausserhalb von RUNDEN ist er deaktiviert.
	diff_btn.visible = true
	diff_btn.disabled = not im_runden
	if im_runden:
		diff_btn.text = Loc.fmt("GRAD: %s", [Loc.t(str(d.get("name", "NORMAL")))])
	else:
		diff_btn.text = Loc.t("GRAD: —")
	print("[MENU][GRAD] modus=%d text=\"%s\" disabled=%s" % [
		int(game_manager.game_mode), diff_btn.text, str(diff_btn.disabled)])
