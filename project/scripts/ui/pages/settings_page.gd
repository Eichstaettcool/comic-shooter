class_name SettingsPage
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
#
# v1.43 (S1/S2/S3): Die Seite ist jetzt zweiteilig aufgebaut:
#   page
#     dim / panel
#       root VBox
#         title  "EINSTELLUNGEN"
#         scroll (ScrollContainer, vertikal)  <- Inhalt (darf scrollen)
#         footer HBox                          <- ZURUECK, immer sichtbar
# Der Inhalt ist so verdichtet, dass er bei 1920x1080 UND 2400x1080 ohne
# Scrollen passt; der ScrollContainer bleibt Sicherheitsnetz fuer kleine
# Displays. Der Musikregler hat eine Trefferflaeche von 88 px und zusaetzlich
# -/+ Knoepfe (88x88) fuer die Bedienung mit dem Finger.
var host: Node = null

const AIM_NAMES := ["AUS", "SCHWACH", "STARK"]
const DIFF_NAMES := ["LEICHT", "NORMAL", "SCHWER", "HARDCORE"]

const LABEL_W := 500.0
const ROW_SEP := 6

var _content: VBoxContainer = null
var _scroll: ScrollContainer = null
var _footer: HBoxContainer = null
var _row_diff: HBoxContainer = null
var _row_biom: HBoxContainer = null


# v1.46 (I1/I2): Aus der Pause gibt es KEINE Schwierigkeits- und Biom-Wahl -
# beides gehoert zum Startmenue (dort werden die Werte fuer den Run gesetzt).
func apply_origin(origin: String) -> void:
	var im_pause: bool = (origin == "pause" or origin == "run")
	if _row_diff != null:
		_row_diff.visible = not im_pause
	if _row_biom != null:
		_row_biom.visible = not im_pause
	var reihen: int = 0
	if _content != null:
		for c in _content.get_children():
			var cc := c as Control
			if cc != null and cc.is_visible_in_tree():
				reihen += 1
	print("[SET][ORIGIN] herkunft=%s schwierigkeit=%s biom=%s" % [
		origin, "aus" if im_pause else "an", "aus" if im_pause else "an"])
	var back: Control = null
	if host.settings_page != null:
		back = host.settings_page.find_child("SettingsBack", true, false)
	var fy: float = back.get_global_rect().position.y if back != null else -1.0
	if fy <= 0.0 and host.get_tree() != null:
		# Layout steht erst nach einem Frame - sonst misst der Beleg 0.
		await host.get_tree().process_frame
		fy = back.get_global_rect().position.y if (back != null and is_instance_valid(back)) else -1.0
	print("[SET][LAYOUT] herkunft=%s reihen=%d zurueck_y=%.0f" % [origin, reihen, fy])


func _create_settings_page() -> void:
	host.settings_page = host._make_page("EINSTELLUNGEN")
	var box: VBoxContainer = host._page_box(host.settings_page)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 6)

	# --- Scrollbereich (Inhalt) ---
	_scroll = ScrollContainer.new()
	_scroll.name = "SettingsScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	# S2.2: Finger-Drag muss scrollen koennen, auch wenn Knoepfe darunter liegen
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(_scroll)

	_content = VBoxContainer.new()
	_content.name = "SettingsContent"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", ROW_SEP)
	_scroll.add_child(_content)

	# --- Sprache ---
	var lrow := _mkrow("SPRACHE")
	host.lang_buttons.clear()
	var lde = host._make_styled_button("DEUTSCH", Color(0.24, 0.44, 0.36), 26)
	lde.custom_minimum_size = Vector2(240, 66)
	lde.pressed.connect(_on_lang_set.bind("de"))
	lrow.add_child(lde)
	host.lang_buttons.append(lde)
	var len_btn = host._make_styled_button("ENGLISH", Color(0.24, 0.34, 0.52), 26)
	len_btn.custom_minimum_size = Vector2(240, 66)
	len_btn.pressed.connect(_on_lang_set.bind("en"))
	lrow.add_child(len_btn)
	host.lang_buttons.append(len_btn)
	print("[LOC][UI] Sprachumschalter gebaut (DEUTSCH / ENGLISH)")

	# --- Grafik-Stufe ---
	var qrow := _mkrow("GRAFIK-STUFE")
	host.quality_buttons.clear()
	for i in range(3):
		var qb = host._make_pixel_button(["NIEDRIG", "MITTEL", "HOCH"][i], Color(0.30, 0.34, 0.44), 28)
		qb.custom_minimum_size = Vector2(250, 68)
		qb.pressed.connect(_on_quality_set.bind(i))
		qrow.add_child(qb)
		host.quality_buttons.append(qb)

	host.quality_info_label = Label.new()
	host.quality_info_label.label_settings = host._make_label_settings(24, Color(0.85, 0.90, 0.85), 6)
	host.quality_info_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(host.quality_info_label)

	# --- Schwierigkeit ---
	var drow := _mkrow("SCHWIERIGKEIT")
	_row_diff = drow
	host.settings_diff_buttons.clear()
	for i in range(DIFF_NAMES.size()):
		var db2 = host._make_pixel_button(str(DIFF_NAMES[i]), Color(0.30, 0.34, 0.44), 26)
		db2.custom_minimum_size = Vector2(230, 68)
		db2.pressed.connect(host._on_difficulty_set.bind(i))
		drow.add_child(db2)
		host.settings_diff_buttons.append(db2)

	# --- Zielhilfe ---
	var arow := _mkrow("ZIELHILFE  (rastet auf Monster ein)")
	host.settings_aim_buttons.clear()
	for i in range(3):
		var ab2 = host._make_pixel_button(str(AIM_NAMES[i]), Color(0.30, 0.34, 0.44), 26)
		ab2.custom_minimum_size = Vector2(230, 68)
		ab2.pressed.connect(host._on_aim_set.bind(i))
		arow.add_child(ab2)
		host.settings_aim_buttons.append(ab2)

	# --- Schalter: FPS / Musik / SFX in EINER Reihe (S2.1) ---
	var trow := HBoxContainer.new()
	trow.alignment = BoxContainer.ALIGNMENT_CENTER
	trow.add_theme_constant_override("separation", 20)
	_content.add_child(trow)

	host.fps_btn = host._make_pixel_button("FPS-ANZEIGE: AUS", Color(0.28, 0.32, 0.42), 24)
	host.fps_btn.custom_minimum_size = Vector2(360, 68)
	host.fps_btn.pressed.connect(host._on_fps_pressed)
	trow.add_child(host.fps_btn)

	host.sound_btn = host._make_pixel_button("MUSIK: AN", Color(0.24, 0.42, 0.34), 24)
	host.sound_btn.custom_minimum_size = Vector2(360, 68)
	host.sound_btn.pressed.connect(_on_music_pressed)
	trow.add_child(host.sound_btn)

	host.sfx_btn = host._make_pixel_button("SOUNDEFFEKTE: AN", Color(0.24, 0.34, 0.48), 24)
	host.sfx_btn.custom_minimum_size = Vector2(400, 68)
	host.sfx_btn.pressed.connect(_on_sfx_pressed)
	trow.add_child(host.sfx_btn)

	# --- Musik-Lautstaerke (S3): Regler + -/+ ---
	var vrow := _mkrow("MUSIK-LAUTSTAERKE")
	host.music_minus_btn = host._make_pixel_button("-", Color(0.34, 0.30, 0.40), 34)
	host.music_minus_btn.custom_minimum_size = Vector2(88, 88)
	host.music_minus_btn.pressed.connect(_on_music_step.bind(-5))
	vrow.add_child(host.music_minus_btn)

	var slider := HSlider.new()
	slider.name = "MusicVolume"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = float(SoundManager.music_volume)
	slider.custom_minimum_size = Vector2(620, 88)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	vrow.add_child(slider)
	host.music_slider = slider

	host.music_plus_btn = host._make_pixel_button("+", Color(0.30, 0.38, 0.34), 34)
	host.music_plus_btn.custom_minimum_size = Vector2(88, 88)
	host.music_plus_btn.pressed.connect(_on_music_step.bind(5))
	vrow.add_child(host.music_plus_btn)

	var vl := Label.new()
	vl.text = "%d %%" % SoundManager.music_volume
	vl.label_settings = host._make_label_settings(30, Color(0.90, 0.94, 0.98), 6)
	vl.custom_minimum_size = Vector2(130, 0)
	vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	vrow.add_child(vl)
	host.music_slider_label = vl
	slider.value_changed.connect(_on_music_volume_changed)

	# --- Biom-Uebergang (Flash) ---
	host.biom_flash_btn = host._make_pixel_button("BIOM-ÜBERGANG: AN", Color(0.30, 0.34, 0.44), 24)
	host.biom_flash_btn.custom_minimum_size = Vector2(520, 68)
	host.biom_flash_btn.pressed.connect(_on_biom_flash_pressed)
	var frow := HBoxContainer.new()
	frow.alignment = BoxContainer.ALIGNMENT_CENTER
	frow.add_child(host.biom_flash_btn)
	_content.add_child(frow)
	_row_biom = frow

	var info = Label.new()
	info.label_settings = host._make_label_settings(20, Color(0.80, 0.86, 0.86), 5)
	info.text = "FPS-ANZEIGE: FPS | Draw-Calls | Objekte | ms | Monster | Stufe   ·   NIEDRIG = ohne Shader   ·   HOCH = Soft-Look-Shader"
	info.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_OFF
	_content.add_child(info)

	# --- v1.48 (D1): INFO-Seite ---
	var irow := _mkrow("INFO")
	var ib: Button = host._make_pixel_button("SO FUNKTIONIERT DAS SPIEL   >", Color(0.24, 0.36, 0.52), 26)
	ib.name = "InfoButton"
	ib.custom_minimum_size = Vector2(620, 68)
	ib.pressed.connect(host._open_info_page)
	irow.add_child(ib)
	print("[UI][NAV] ziel=info herkunft=settings knopf=true")

	# --- Fuss: ZURUECK ausserhalb des Scrollbereichs (S1.1) ---
	_footer = HBoxContainer.new()
	_footer.name = "SettingsFooter"
	_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_footer.add_theme_constant_override("separation", 20)
	box.add_child(_footer)

	var back = host._make_pixel_button("ZURUECK", Color(0.35, 0.38, 0.46), 32)
	back.name = "SettingsBack"
	back.custom_minimum_size = Vector2(340, 76)
	back.pressed.connect(host._close_settings_page)
	_footer.add_child(back)

	host.settings_page.hide()
	# v1.42 (P1.2): Die Einstellungen liegen NICHT mehr unter start_screen -
	# sonst ist die Seite bei verborgenem Startmenue (Aufruf aus der Pause)
	# automatisch mit versteckt. Als Kind des UI-Managers bleibt sie eigenstaendig.
	var old_parent: Node = host.settings_page.get_parent()
	if old_parent != null and old_parent != host:
		old_parent.remove_child(host.settings_page)
		host.add_child(host.settings_page)
	# Zahnrad/Gear liegt in start_screen (z 200) - die Seite muss darueber liegen
	host.settings_page.z_index = 230
	print("[MENU][SETTINGS] Seite neu verdrahtet: parent=%s scroll=true knopf_fuss=true" % [
		host.settings_page.get_parent().name])


# Baut eine Zeile "Beschriftung links, Bedienelemente rechts" (S2.1: eine
# Einstellung = eine Zeile, damit die Seite ohne Scrollen in 1080 px passt).
func _mkrow(caption: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(row)
	var lbl := Label.new()
	lbl.text = caption
	lbl.label_settings = host._make_label_settings(26, Color(1.0, 0.85, 0.35), 6)
	lbl.custom_minimum_size = Vector2(LABEL_W, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	return row


# S1.1/S2: Messwerte nach aussen geben (Diag-Harness + Log)
func layout_info() -> Dictionary:
	var need: Vector2 = Vector2.ZERO
	if _content != null:
		need = (_content as Control).get_combined_minimum_size()
	var back: Control = null
	if host.settings_page != null:
		back = host.settings_page.find_child("SettingsBack", true, false)
	var brect: Rect2 = back.get_global_rect() if back != null else Rect2()
	return {
		"inhalt": need,
		"scroll": _scroll != null,
		"footer": _footer != null,
		"footer_y": brect.position.y,
		"footer_h": brect.size.y if back != null else 0.0,
		"knopf_x": brect.position.x,
		"knopf_rechts": brect.end.x,
	}


func refresh_settings_ui() -> void:
	if host.game_manager == null:
		return
	var q: int = host.game_manager.get_quality()
	for i in range(host.quality_buttons.size()):
		if host.quality_buttons[i] != null:
			host.quality_buttons[i].modulate = Color(1.45, 1.45, 1.35) if i == q else Color(0.72, 0.74, 0.80)
	if host.quality_info_label:
		host.quality_info_label.text = "Aktuell: " + str(host.game_manager.QUALITY_NAMES[q]) + [" — ohne Shader, minimale Details, max 55 Monster", " — ohne Shader, volle Details, max 110 Monster", " — Soft-Look-Shader, max 150 Monster"][q]
	if host.fps_btn:
		host.fps_btn.text = "FPS-ANZEIGE: " + ("AN" if host.game_manager.debug_fps else "AUS")
		host.fps_btn.modulate = Color(1.35, 1.35, 1.35) if host.game_manager.debug_fps else Color(0.85, 0.85, 0.9)
	if host.sound_btn:
		host.sound_btn.text = "MUSIK: " + ("AN" if SoundManager.music_on else "AUS")
		host.sound_btn.modulate = Color(1.35, 1.35, 1.35) if SoundManager.music_on else Color(0.85, 0.85, 0.9)
	if host.biom_flash_btn != null:
		var bf: bool = bool(host.game_manager.get("biome_flash_on"))
		host.biom_flash_btn.text = "BIOM-ÜBERGANG: " + ("AN" if bf else "AUS")
		host.biom_flash_btn.modulate = Color(1.3, 1.3, 1.3) if bf else Color(0.85, 0.85, 0.9)
	if host.sfx_btn:
		host.sfx_btn.text = "SOUNDEFFEKTE: " + ("AN" if SoundManager.sfx_on else "AUS")
		host.sfx_btn.modulate = Color(1.35, 1.35, 1.35) if SoundManager.sfx_on else Color(0.85, 0.85, 0.9)
	if host.music_slider != null and is_instance_valid(host.music_slider):
		if absf(float(host.music_slider.value) - float(SoundManager.music_volume)) > 0.5:
			host.music_slider.set_value_no_signal(float(SoundManager.music_volume))
	if host.music_slider_label != null and is_instance_valid(host.music_slider_label):
		host.music_slider_label.text = "%d %%" % int(SoundManager.music_volume)


func _on_lang_set(code: String) -> void:
	# Runde 136 (K2): Sprache sofort anwenden und im Profil speichern
	Loc.set_lang(code)
	if host.game_manager != null:
		host.game_manager.set("lang", Loc.lang)
		if host.game_manager.has_method("save_lang"):
			host.game_manager.call("save_lang")
	var st: Dictionary = Loc.apply_tree(host)
	print("[LOC][SET] sprache=%s (gespeichert) texte=%d uebersetzt=%d" % [
		Loc.lang, int(st["labels"]), int(st["done"])])
	host._loc_total = int(st["done"])
	# Dynamisch zusammengesetzte Texte (Zaehler, Wertezeilen) neu bauen,
	# damit sie in der neuen Sprache entstehen statt nur uebersetzt zu werden.
	if host.game_manager != null:
		host.refresh_profile_ui()
		# v1.41 (F5): v1.40-Oberflaechen neu bauen (Shop, HUD-Zeile,
		# Modus-/GRAD-Knopf) - sonst bleiben dort deutsche Texte stehen.
		if host.has_method("refresh_mode_labels"):
			host.call("refresh_mode_labels")
		var ws = host.get("wave_shop")
		if ws != null and is_instance_valid(ws) and ws.has_method("_rebuild"):
			ws.call("_rebuild")
			print("[LOC][BUILD] wave_shop neu gebaut (sprache=%s)" % Loc.lang)
	refresh_settings_ui()


func refresh_lang_buttons() -> void:
	for i in range(host.lang_buttons.size()):
		var b: Button = host.lang_buttons[i]
		if b == null:
			continue
		var mine: String = "de" if i == 0 else "en"
		var active: bool = (Loc.lang == mine)
		b.modulate = Color(1.30, 1.30, 1.30, 1.0) if active else Color(0.80, 0.80, 0.85)
		b.disabled = active


func _on_quality_set(i: int) -> void:
	if host.game_manager:
		host.game_manager.set_quality(i)
	refresh_settings_ui()


func _on_music_pressed() -> void:
	# Runde 62: eigene Musik-Einstellung
	var on: bool = not SoundManager.music_on
	SoundManager.set_music_enabled(on)
	if host.game_manager != null:
		host.game_manager.call("set_music_setting", on)
	refresh_settings_ui()


func _on_biom_flash_pressed() -> void:
	if host.game_manager == null:
		return
	var on: bool = not bool(host.game_manager.get("biome_flash_on"))
	host.game_manager.call("set_biome_flash", on)
	refresh_settings_ui()


# S3.2: -/+ in 5-%-Schritten, immer ueber denselben Weg wie der Regler
func _on_music_step(delta: int) -> void:
	var neu: int = clampi(int(SoundManager.music_volume) + delta, 0, 100)
	if host.music_slider != null and is_instance_valid(host.music_slider):
		host.music_slider.set_value_no_signal(float(neu))
	_on_music_volume_changed(float(neu))
	print("[TAP] lautstaerke_%s wert=%d" % ["plus" if delta > 0 else "minus", neu])


func _on_music_volume_changed(v: float) -> void:
	# v1.42 (P4.1): Regler anwenden + im Profil speichern
	var pct: int = int(round(v))
	SoundManager.set_music_volume(pct)
	if host.music_slider_label != null and is_instance_valid(host.music_slider_label):
		host.music_slider_label.text = "%d %%" % pct
	if host.game_manager != null:
		host.game_manager.set("music_volume", pct)
		if host.game_manager.has_method("_save_profile"):
			host.game_manager.call("_save_profile")
	print("[SFX][MUSIK] regler=%d gespeichert=true" % pct)


func _on_sfx_pressed() -> void:
	var on: bool = not SoundManager.sfx_on
	SoundManager.set_sfx_enabled(on)
	if host.game_manager != null:
		host.game_manager.call("set_sfx_setting", on)
	refresh_settings_ui()
