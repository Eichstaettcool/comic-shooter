class_name InfoPage
extends RefCounted

# v1.48 (D1): "So funktioniert das Spiel" - eine reine Erklaerseite.
# Aufbau wie die anderen Seiten: _make_page("INFO") + Scrollbereich + ZURUECK.
# Alle Texte stehen als deutsche Originaltexte im Code und werden ueber
# Loc.t() / Loc.apply_tree() ins Englische uebersetzt (eine Quelle).
var host: Node = null

const SECTIONS := [
	{
		"key": "DAS ZIEL",
		"icon": "icon_crosshair",
		"de": "Ein Run ist ein einzelner Versuch: Du laeufst durch eine zufaellige Karte, schiesst Monster, oeffnest Kisten und wirst alle 120 Sekunden von einem Boss besucht. Ziel ist so weit zu kommen wie moeglich - Punkte, Gold und Fortschritt bleiben nach dem Run erhalten."
	},
	{
		"key": "DIE MODI",
		"icon": "nav_lan",
		"de": "ENDLOS: Wellen kommen ohne Ende, jedes Level bringt drei Karten zur Auswahl (Schaden, Tempo, Herzen, Schild). WELLEN: 30 Sekunden Shop nach jeder Welle, Gold statt Karten, Upgrades nur im Shop. RUNDEN: feste Rundenzahl, Boss am Ende, kein Level-Up. BOSS-RUSH und weitere Varianten laufen als CHALLENGE im Runden-Modus. ZU ZWEIT: ein Geraet hostet, das andere verbindet sich per WLAN - eine gemeinsame Welt."
	},
	{
		"key": "DIE WAEHRUNGEN",
		"icon": "icon_coin",
		"de": "GOLD verdienst du im Run (Muenzen, Kills, Kisten) und gibst es im Shop fuer Kisten und Extras aus. DIAMANTEN sind selten: sie kommen aus Challenges, Kisten-Trostpreisen und dem Gluecksrad und bezahlen die grossen Kisten."
	},
	{
		"key": "SKINS, FARBEN UND HUETE",
		"icon": "nav_char",
		"de": "Skins, Farben und Huete aendern nur das Aussehen, nie die Werte. Du bekommst sie aus Kisten, dem Gluecksrad und als Challenge-Belohnung. Ausgeruestet wird auf der Charakter-Seite; die Sammlung zeigt alles mit Seltenheitsfarbe und Schloss."
	},
	{
		"key": "KARTEN UND JAHRESZEITEN",
		"icon": "nav_map",
		"de": "Jeder Planet hat eigene Monster, Boeden und Tempowerte: Erde, Mars (Drift), Dschungel (dichte Vegetation), Elektro-Welt. Die Jahreszeit (Fruehling, Sommer, Herbst, Winter) aendert Optik und Gegnerwerte, nicht das Kartengrund-Layout. Auf der Karten-Seite waehlst du Planet, Jahreszeit und FEST oder WECHSELND."
	},
	{
		"key": "CHALLENGES",
		"icon": "nav_chal",
		"de": "Eine Challenge ist ein Run mit einer Einschraenkung: nur eine Waffe, keine Heilung, kein Schild, ein Zeitlimit oder kein einziger Treffer. Drei Stufen (LEICHT, NORMAL, HART) mit je eigener Rundenzahl und Diamantenbelohnung. Die Einschraenkung ist der Wettkampf - reine Zaehlaufgaben gibt es nicht mehr."
	},
	{
		"key": "KISTEN",
		"icon": "chest_gem_standard",
		"de": "STANDARD, SILBER und PREMIUM unterscheiden sich in Preis und Seltenheits-Chancen. Im Run erscheinen Kisten auf der Karte: drei Sekunden daneben stehen bleiben, dann oeffnen. Drin sind Waffen, Herzen, Schild, mehr maximales Leben, Frost oder Schnellfeuer."
	},
	{
		"key": "STEUERUNG",
		"icon": "btn_shoot",
		"de": "Links der Joystick fuer die Bewegung, rechts der Schuss-Knopf (halten = Dauerfeuer). Trank und Bombe liegen als Knoepfe daneben, Pause oben rechts. Am Rechner: WASD oder Pfeiltasten, Leertaste schiesst, 1-5 wechseln die Waffe, ESC oder P pausiert."
	},
	{
		"key": "SPEICHERN",
		"icon": "icon_gear",
		"de": "Profil, Gold, Diamanten, Freischaltungen und Challenge-Fortschritt liegen lokal auf dem Geraet und werden nach jedem Run, Kauf und Abschluss gesichert. Es gibt kein Konto und keine Cloud - eine Neuinstallation setzt den Fortschritt zurueck."
	},
]

var _scroll: SmoothScroll = null
var _abschnitte: int = 0


func _create() -> void:
	host.info_page = host._make_page("INFO")
	var box: VBoxContainer = host._page_box(host.info_page)
	box.add_theme_constant_override("separation", 8)

	# Lesespalte ~1100 px, zentriert, scrollbar
	var zeile := HBoxContainer.new()
	zeile.alignment = BoxContainer.ALIGNMENT_CENTER
	zeile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(zeile)

	_scroll = SmoothScroll.new()
	_scroll.tag = "info"
	_scroll.custom_minimum_size = Vector2(1100, 460)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zeile.add_child(_scroll)

	var content := VBoxContainer.new()
	content.name = "InfoContent"
	content.add_theme_constant_override("separation", 18)
	content.custom_minimum_size = Vector2(1080, 0)
	_scroll.set_content(content)

	for s in SECTIONS:
		var abschnitt := VBoxContainer.new()
		abschnitt.add_theme_constant_override("separation", 4)
		content.add_child(abschnitt)
		var kopf := HBoxContainer.new()
		kopf.add_theme_constant_override("separation", 12)
		abschnitt.add_child(kopf)
		var ic := TextureRect.new()
		ic.texture = TextureManager.get_texture(str(s["icon"]))
		ic.custom_minimum_size = Vector2(44, 44)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		kopf.add_child(ic)
		var h := Label.new()
		h.text = str(s["key"])
		h.label_settings = host._make_label_settings(34, Color(1.0, 0.84, 0.30), 7)
		h.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		kopf.add_child(h)
		var body := Label.new()
		body.name = "Info_" + str(s["key"]).replace(" ", "_")
		body.text = str(s["de"])
		body.label_settings = host._make_label_settings(23, Color(0.92, 0.94, 0.97), 4)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(1080, 0)
		abschnitt.add_child(body)
		var linie := ColorRect.new()
		linie.color = Color(0.98, 0.80, 0.22, 0.22)
		linie.custom_minimum_size = Vector2(0, 2)
		abschnitt.add_child(linie)
		_abschnitte += 1
		var en: String = str(Loc.DE_EN.get(str(s["de"]), ""))
		print("[LOC][INFO] key=%s de=%d zeichen en=%d zeichen" % [str(s["key"]), str(s["de"]).length(), en.length()])

	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(brow)
	var back: Button = host._make_pixel_button("ZURUECK", Color(0.32, 0.36, 0.46), 30)
	back.name = "InfoBack"
	back.custom_minimum_size = Vector2(340, 76)
	back.pressed.connect(host._close_info_page)
	brow.add_child(back)
	host.info_page.hide()


func open(origin: String = "settings") -> void:
	if host.info_page == null:
		_create()
	# v1.48 (D1): Scrollbereich auf die freie Hoehe setzen (Titel + Zurueck +
	# Rand abziehen) - sonst laeuft der Inhalt unter den Zurueck-Knopf.
	var vp_y: float = host.get_viewport().get_visible_rect().size.y
	_scroll.custom_minimum_size = Vector2(1100, maxf(320.0, vp_y - 250.0))
	host._close_pages()
	host.info_page.show()
	host.info_origin = origin
	if _scroll != null:
		_scroll.scroll_to(0.0)
	var hoehe: int = 0
	if _scroll != null and _scroll.content != null:
		hoehe = int(_scroll.content.get_combined_minimum_size().y)
	print("[INFO][SEITE] abschnitte=%d hoehe=%dpx scrollbar=true" % [_abschnitte, hoehe])
	print("[UI][NAV] ziel=info herkunft=%s" % origin)
	var back0 = host.info_page.find_child("InfoBack", true, false)
	print("[INFO][LAYOUT] scroll=%.0fx%.0f back_y=%.0f back_unten=%.0f viewport=%.0f" % [
		_scroll.size.x, _scroll.size.y,
		(back0 as Control).get_global_rect().position.y if back0 != null else -1.0,
		(back0 as Control).get_global_rect().end.y if back0 != null else -1.0, vp_y])


func close() -> void:
	if host.info_page != null:
		host.info_page.hide()
	var org: String = str(host.info_origin)
	host.info_origin = "settings"
	print("[UI][NAV] ziel=%s herkunft=info" % ("settings" if org == "settings" else "menu"))
	if org == "settings" and host.settings_page != null:
		host.settings_page.show()
		if host.settings_page.has_method("refresh_settings_ui"):
			host.settings_page.call("refresh_settings_ui")
	else:
		host.show_start_screen()
