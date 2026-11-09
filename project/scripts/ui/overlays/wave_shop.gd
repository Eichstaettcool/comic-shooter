class_name WaveShop
extends Control

# v1.40 — Shop fuer den RUNDEN-Modus.
# Drei Kategorien (WAFFEN · LEBEN · TRAENKE), jede Karte oeffnet ein eigenes
# Fenster (WaveItemWindow) mit Werten, Preis und KAUFEN/ABBRECHEN.
# Zusaetzlich: EIN wechselndes "ANGEBOT DES TAGES" mit 25 % Rabatt (W3.9).

var host: Node = null               # ui_manager (Stil-Helfer, HUD, Banner)
var game: Node = null               # game_manager (Muenzen, Spieler, Modul)
var rm = null                       # RoundsMode-Modul (RefCounted, kein Node!)
var box: VBoxContainer = null
var cat_node: Dictionary = {}       # Kategorie -> GridContainer
var window: PanelContainer = null
var coins_label: Label = null
var skill_box: HBoxContainer = null
var offer_label: Label = null
var _cards: Array = []

const CAT_ORDER := ["WAFFEN", "LEBEN", "TRAENKE"]
const CAT_TITLES := { "WAFFEN": "WAFFEN", "LEBEN": "LEBEN", "TRAENKE": "TRAENKE" }
const CAT_COLORS := {
	"WAFFEN": Color(0.98, 0.72, 0.20),
	"LEBEN": Color(0.95, 0.42, 0.42),
	"TRAENKE": Color(0.40, 0.82, 0.95),
}

const WEAPONS := [
	{ "id": "weapon_pistol", "name": "PISTOLE", "basis": 110 },
	{ "id": "weapon_shotgun", "name": "SCHROTFLINTE", "basis": 140 },
	{ "id": "weapon_machine", "name": "SMG", "basis": 165 },
	{ "id": "weapon_laser", "name": "LASER", "basis": 195 },
	{ "id": "weapon_revolver", "name": "REVOLVER", "basis": 225 },
]
const RARITIES := [
	{ "key": "common", "name": "GEWOEHNLICH", "dmg": 1.00, "preis": 1.0, "farbe": Color(0.72, 0.74, 0.78) },
	{ "key": "rare", "name": "SELTEN", "dmg": 1.25, "preis": 2.0, "farbe": Color(0.35, 0.65, 0.95) },
	{ "key": "epic", "name": "EPISCH", "dmg": 1.55, "preis": 3.4, "farbe": Color(0.72, 0.45, 0.95) },
	{ "key": "legendary", "name": "LEGENDAER", "dmg": 2.00, "preis": 5.6, "farbe": Color(0.99, 0.72, 0.20) },
]
const LIFE := [
	{ "id": "herz", "name": "+1 HERZ", "basis": 90, "desc": "Ein maximales Herz mehr (max. 5 Kaeufe)" },
	{ "id": "revive", "name": "LEBEN ZURUECK", "basis": 220, "desc": "Einmal wiederbelebt statt Run-Ende (max. 2)" },
	{ "id": "schild", "name": "SCHILD +2", "basis": 70, "desc": "Zwei Schildladungen, bleiben bis sie verbraucht sind" },
]
const POTIONS := [
	{ "id": "potion", "name": "HEILTRANK x1", "basis": 40, "desc": "Regeneriert 3 Herzen über 4,5 s (Taste Q)" },
	{ "id": "bombe", "name": "BOMBE x1", "basis": 55, "desc": "Flaechenschaden um dich herum (E)" },
	{ "id": "frost", "name": "FROST 10 s", "basis": 80, "desc": "Alle Gegner stehen 10 s still" },
]


# v1.51: dauerhafte Eigenschaften-Skills fuer den Runden-Modus
const SKILLS := [
	{ "id": "skill_speed", "name": "TEMPO +10 %", "basis": 60, "desc": "Lauftempo dauerhaft +10 %" },
	{ "id": "skill_reload", "name": "NACHLADEN -8 %", "basis": 70, "desc": "Nachladezeit dauerhaft -8 %" },
	{ "id": "skill_damage", "name": "SCHADEN +12 %", "basis": 80, "desc": "Waffenschaden dauerhaft +12 %" },
]
const SKILL_CAP := 6


const ICON_BY_ID := {
	"weapon_pistol": "weapon_pistol",
	"weapon_shotgun": "weapon_shotgun",
	"weapon_machine": "weapon_machine",
	"weapon_laser": "weapon_laser",
	"weapon_revolver": "weapon_revolver",
	"herz": "heart_gold",
	"revive": "icon_revive",
	"schild": "icon_shield",
	"potion": "potion",
	"bombe": "bomb",
	"frost": "powerup_freeze",
}


static func icon_key_of(id: String) -> String:
	return str(ICON_BY_ID.get(id, ""))


# ------------------------------------------------------------------
# Katalog-Helfer (auch vom RoundsMode genutzt)
# ------------------------------------------------------------------

static func article_ids() -> Array:
	var out: Array = []
	for w in WEAPONS:
		out.append(str(w["id"]))
	for l in LIFE:
		out.append(str(l["id"]))
	for p in POTIONS:
		out.append(str(p["id"]))
	return out


static func article_by_id(id: String) -> Dictionary:
	for w in WEAPONS:
		if str(w["id"]) == id:
			return { "kind": "waffe", "id": id, "name": str(w["name"]), "basis": int(w["basis"]) }
	for l in LIFE:
		if str(l["id"]) == id:
			return { "kind": "leben", "id": id, "name": str(l["name"]), "basis": int(l["basis"]), "desc": str(l["desc"]) }
	for p in POTIONS:
		if str(p["id"]) == id:
			return { "kind": "trank", "id": id, "name": str(p["name"]), "basis": int(p["basis"]), "desc": str(p["desc"]) }
	return {}


static func price_of(id: String, round_no: int, diff: String, rabatt: bool = false) -> int:
	var a: Dictionary = article_by_id(id)
	if a.is_empty():
		return 0
	var p: float = float(a["basis"]) * Rounds.price_mult(round_no, diff)
	if rabatt:
		p *= 0.75
	return maxi(1, int(round(p / 5.0)) * 5)


static func skill_price(id: String, round_no: int, diff: String, stufe: int = 0) -> int:
	var basis: int = 0
	for k in SKILLS:
		if str(k["id"]) == id:
			basis = int(k["basis"])
	if basis == 0:
		return 0
	var p: float = float(basis) * Rounds.price_mult(round_no, diff) * (1.0 + 0.45 * float(stufe))
	return maxi(1, int(round(p / 5.0)) * 5)


static func skill_by_id(id: String) -> Dictionary:
	for k in SKILLS:
		if str(k["id"]) == id:
			return k
	return {}


static func weapon_price(w: Dictionary, rar: Dictionary, round_no: int, diff: String) -> int:
	var p: float = float(w["basis"]) * float(rar["preis"]) * Rounds.price_mult(round_no, diff)
	return maxi(1, int(round(p / 5.0)) * 5)


# ------------------------------------------------------------------
# Aufbau
# ------------------------------------------------------------------

func open(gm: Node) -> void:
	game = gm
	host = gm.get("ui_manager")
	rm = gm.get("rounds_mode")
	_build()
	_rebuild()
	print("[WSHOP][BAU] kategorien=%d karten=%d reihenfolge=%s" % [
		CAT_ORDER.size(), _cards.size(), ",".join(CAT_ORDER)])


func _build() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	size = vp
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.94)
	dim.position = Vector2.ZERO
	dim.size = vp
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "WaveShopPanel"
	panel.position = Vector2(vp.x * 0.5 - 840.0, 20.0)
	panel.custom_minimum_size = Vector2(1680, 0)
	panel.add_theme_stylebox_override("panel", host._comic_panel_sb(Color(0.06, 0.06, 0.11, 0.98), Color(0.98, 0.80, 0.20), 8, 18))
	add_child(panel)

	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var titel := Label.new()
	titel.text = Loc.t("WELLEN-SHOP")
	titel.set_meta("loc_fmt", true)
	titel.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	titel.label_settings = host._make_label_settings(44, Color(1.0, 0.86, 0.35), 8)
	box.add_child(titel)

	coins_label = Label.new()
	coins_label.name = "WaveShopCoins"
	coins_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	coins_label.label_settings = host._make_label_settings(30, Color(0.98, 0.86, 0.45), 6)
	box.add_child(coins_label)

	# Angebot des Tages (W3.9)
	var offer_panel := PanelContainer.new()
	offer_panel.add_theme_stylebox_override("panel", host._make_pixel_panel_sb(Color(0.16, 0.12, 0.24), Color(0.95, 0.65, 0.95), 5, 10))
	box.add_child(offer_panel)
	offer_label = Label.new()
	offer_label.name = "WaveShopOffer"
	offer_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	offer_label.label_settings = host._make_label_settings(26, Color(1.0, 0.92, 0.98), 5)
	offer_panel.add_child(offer_label)
	offer_panel.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_offer_click())

	# Drei Kategorien nebeneinander
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(cols)
	_cards.clear()
	for cat in CAT_ORDER:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cols.add_child(v)
		var head := Label.new()
		head.text = Loc.t(str(CAT_TITLES[cat]))
		head.set_meta("loc_fmt", true)
		head.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		head.label_settings = host._make_label_settings(32, CAT_COLORS[cat], 6)
		v.add_child(head)
		var grid := GridContainer.new()
		grid.name = "WaveShopGrid_%s" % cat
		grid.columns = 1
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(grid)
		cat_node[cat] = grid

	# v1.51: Skills (dauerhaft für diesen Run)
	var sk_head := Label.new()
	sk_head.text = Loc.t("SKILLS · DAUERHAFT")
	sk_head.set_meta("loc_fmt", true)
	sk_head.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	sk_head.label_settings = host._make_label_settings(30, Color(0.62, 0.90, 0.72), 6)
	box.add_child(sk_head)
	skill_box = HBoxContainer.new()
	skill_box.name = "WaveShopSkills"
	skill_box.alignment = BoxContainer.ALIGNMENT_CENTER
	skill_box.add_theme_constant_override("separation", 14)
	box.add_child(skill_box)

	# Weiter
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var weiter: Button = host._make_comic_button(Loc.t("WEITER"), Color(0.20, 0.60, 0.36), 30)
	weiter.set_meta("loc_fmt", true)
	weiter.name = "WaveShopClose"
	weiter.custom_minimum_size = Vector2(340, 64)
	weiter.pressed.connect(close)
	row.add_child(weiter)


func _make_card(parent: Control, id: String, title: String, extra: String, preis: int, col: Color, cb: Callable, rarity: String = "") -> Button:
	# v1.41 (F3): Karte mit 64x64-Symbol links, Name rechts, Preiszeile mit
	# Muenz-Icon. Waffenkarten bekommen einen Seltenheitsrahmen.
	var b: Button = host._make_pixel_button("", Color(0.12, 0.13, 0.18), 16)
	b.custom_minimum_size = Vector2(520, 86)   # v1.51: 104 -> 86, damit die Skills-Zeile passt
	b.focus_mode = Control.FOCUS_NONE
	var rar_col: Color = col if rarity == "" else host._rarity_col_of(rarity)
	b.add_theme_stylebox_override("normal", host._make_pixel_panel_sb(Color(0.11, 0.12, 0.17), rar_col, 4, 10))
	b.add_theme_stylebox_override("hover", host._make_pixel_panel_sb(Color(0.16, 0.18, 0.24), rar_col.lightened(0.2), 4, 10))
	b.add_theme_stylebox_override("pressed", host._make_pixel_panel_sb(Color(0.09, 0.10, 0.14), rar_col, 4, 10))

	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.position = Vector2(10, 6)
	hb.size = Vector2(500, 76)
	hb.add_theme_constant_override("separation", 12)
	b.add_child(hb)

	# Symbol links (64x64 im Rahmen)
	var ikey: String = icon_key_of(id)
	var tex: Texture2D = TextureManager.get_texture(ikey) if ikey != "" else null
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(64, 64)
	frame.add_theme_stylebox_override("panel", host._make_pixel_panel_sb(Color(0.07, 0.08, 0.12), rar_col, 3, 4))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(frame)
	var ic := TextureRect.new()
	ic.name = "ShopIcon"
	ic.custom_minimum_size = Vector2(54, 54)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.texture = tex
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(ic)
	print("[WSHOP][ICON] artikel=%s tex=%s ok=%s" % [id, ikey, str(tex != null)])

	# Rechts: Name + Preiszeile
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	hb.add_child(vb)
	var l1 := Label.new()
	l1.text = title
	l1.set_meta("loc_fmt", true)
	l1.add_theme_font_size_override("font_size", 22)
	l1.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(l1)

	var prow := HBoxContainer.new()
	prow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prow.add_theme_constant_override("separation", 6)
	vb.add_child(prow)
	if preis > 0:
		var coin := TextureRect.new()
		coin.custom_minimum_size = Vector2(22, 22)
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		coin.texture = TextureManager.get_texture("icon_coin")
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prow.add_child(coin)
	var l2 := Label.new()
	l2.text = ("%d" % preis) if preis > 0 else "—"
	l2.add_theme_font_size_override("font_size", 19)
	l2.add_theme_color_override("font_color", col.lightened(0.35))
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prow.add_child(l2)
	if extra != "":
		var l3 := Label.new()
		l3.text = "  ·  " + extra
		l3.set_meta("loc_fmt", true)
		l3.add_theme_font_size_override("font_size", 18)
		l3.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))
		l3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prow.add_child(l3)
	b.pressed.connect(cb)
	parent.add_child(b)
	_cards.append(b)
	return b


func _rebuild() -> void:
	var r: int = int(rm.get("round_no")) if rm != null else 1
	var diff: String = str(rm.get("difficulty")) if rm != null else "normal"
	coins_label.text = Loc.fmt("MÜNZEN: %d", [int(game.coins)])
	coins_label.set_meta("loc_fmt", true)
	_cards.clear()   # v1.51: sonst waechst die Liste bei jedem Rebuild
	for cat in CAT_ORDER:
		var grid: GridContainer = cat_node[cat]
		for c in grid.get_children():
			grid.remove_child(c)
			c.queue_free()

	# W3.6: innerhalb jeder Kategorie nach Preis aufsteigend sortieren
	var eintraege: Dictionary = { "WAFFEN": [], "LEBEN": [], "TRAENKE": [] }
	# v1.45 (C3/C4): In einer Aufgabe ist die Einschraenkung die Aufgabe -
	# gesperrte Karten erscheinen gar nicht erst.
	var keine_waffen: bool = bool(game.get("chal_active")) and bool(game.call("chal_regel", "waffenkarten"))
	var keine_heilung: bool = bool(game.get("chal_active")) and bool(game.call("chal_regel", "heilung"))
	if keine_waffen or keine_heilung:
		print("[WSHOP][SPERREN] waffenkarten=%s heilung=%s" % [
			str(keine_waffen), str(keine_heilung)])
	for w in WEAPONS:
		if keine_waffen:
			continue
		var p: int = price_of(str(w["id"]), r, diff)
		var owned: bool = _owns_weapon(str(w["id"]))
		var rar: String = _rarity_of(str(w["id"]))
		eintraege["WAFFEN"].append({
			"id": str(w["id"]),
			"preis": 0 if owned else p,
			"titel": str(w["name"]),
			"extra": (Loc.t("BESITZT · Seltenheit wählen") if owned else ""),
			"cb": _on_weapon_click.bind(str(w["id"])),
			"col": CAT_COLORS["WAFFEN"],
			"rarity": rar if owned and rar != "" else "epic",
		})
	for l in LIFE:
		if keine_heilung and (str(l["id"]) == "herz" or str(l["id"]) == "revive"):
			continue
		var p2: int = price_of(str(l["id"]), r, diff)
		var extra2: String = ""
		if str(l["id"]) == "revive":
			extra2 = Loc.fmt("noch %d/%d", [int(rm.MAX_LIVES) - int(rm.get("lives")), int(rm.MAX_LIVES)])
		elif str(l["id"]) == "herz":
			extra2 = Loc.fmt("gekauft %d/%d", [int(rm.get("hearts_bought")), int(rm.MAX_HEARTS)])
		eintraege["LEBEN"].append({
			"id": str(l["id"]), "preis": p2, "titel": str(l["name"]), "extra": extra2,
			"cb": _on_article_click.bind(str(l["id"])), "col": CAT_COLORS["LEBEN"], "rarity": "",
		})
	for p3 in POTIONS:
		if keine_heilung and str(p3["id"]) == "potion":
			continue
		var pp: int = price_of(str(p3["id"]), r, diff)
		var extra3: String = ""
		eintraege["TRAENKE"].append({
			"id": str(p3["id"]), "preis": pp, "titel": str(p3["name"]), "extra": extra3,
			"cb": _on_article_click.bind(str(p3["id"])), "col": CAT_COLORS["TRAENKE"], "rarity": "",
		})
	for cat in CAT_ORDER:
		var liste: Array = eintraege[cat]
		liste.sort_custom(func(a, b): return int(a["preis"]) < int(b["preis"]))
		var preise: Array = []
		for e in liste:
			preise.append(int(e["preis"]))
			_make_card(cat_node[cat], str(e["id"]), Loc.t(str(e["titel"])), str(e["extra"]),
				int(e["preis"]), e["col"], e["cb"], str(e["rarity"]))
		var auf: bool = true
		for i in range(1, preise.size()):
			if int(preise[i]) < int(preise[i - 1]):
				auf = false
		print("[WSHOP][SORT] kategorie=%s preise=%s aufsteigend=%s" % [
			cat.to_lower(), str(preise), str(auf)])
	# W4.3: Preise skalieren mit der Runde
	for cid in ["potion", "herz", "revive", "schild", "bombe", "frost"]:
		print("[WSHOP][PREIS] artikel=%s runde=%d preis=%d" % [cid, r, price_of(cid, r, diff)])
	# Angebot
	if rm != null and str(rm.get("offer_id")) != "":
		var oid: String = str(rm.get("offer_id"))
		var oa: Dictionary = article_by_id(oid)
		var op: int = price_of(oid, r, diff, true)
		if bool(rm.get("offer_bought")):
			offer_label.text = Loc.fmt("ANGEBOT DES TAGES: %s  ·  AUSVERKAUFT", [Loc.t(str(oa.get("name", oid)))])
		else:
			offer_label.text = Loc.fmt("ANGEBOT DES TAGES: %s  ·  %d Münzen (-25 %%)  ·  antippen", [
				Loc.t(str(oa.get("name", oid))), op])
		offer_label.set_meta("loc_fmt", true)
	_fill_skills(r, diff)
	print("[WSHOP][ZUSTAND] kinder=%d karten=%d" % [get_child_count(), _cards.size()])


func _fill_skills(r: int, diff: String) -> void:
	if skill_box == null:
		return
	for c in skill_box.get_children():
		skill_box.remove_child(c)
		c.queue_free()
	if rm == null:
		return
	var stufen: Array = []
	for k in SKILLS:
		var id: String = str(k["id"])
		var stufe: int = int(rm.call("skill_stacks_of", id))
		var preis: int = skill_price(id, r, diff, stufe)
		var voll: bool = stufe >= int(SKILL_CAP)
		var bezahlbar: bool = int(game.coins) >= preis
		var col := Color(0.35, 0.78, 0.55) if (bezahlbar and not voll) else Color(0.42, 0.44, 0.50)
		var b: Button = host._make_pixel_button("", Color(0.11, 0.13, 0.17), 18)
		b.name = "Skill_%s" % id
		b.custom_minimum_size = Vector2(470, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", host._make_pixel_panel_sb(Color(0.10, 0.13, 0.11), col, 4, 10))
		b.add_theme_stylebox_override("hover", host._make_pixel_panel_sb(Color(0.15, 0.20, 0.16), col.lightened(0.25), 4, 10))
		b.add_theme_stylebox_override("pressed", host._make_pixel_panel_sb(Color(0.08, 0.10, 0.09), col, 4, 10))
		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.position = Vector2(12, 8)
		vb.size = Vector2(446, 60)
		vb.add_theme_constant_override("separation", 2)
		b.add_child(vb)
		var l1 := Label.new()
		l1.text = Loc.t(str(k["name"]))
		l1.set_meta("loc_fmt", true)
		l1.add_theme_font_size_override("font_size", 24)
		l1.add_theme_color_override("font_color", Color(0.96, 0.99, 0.96))
		l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(l1)
		var l2 := Label.new()
		if voll:
			l2.text = Loc.fmt("MAXIMUM · Stufe %d/%d", [stufe, int(SKILL_CAP)])
		else:
			l2.text = Loc.fmt("Stufe %d/%d  ·  %d Münzen", [stufe, int(SKILL_CAP), preis])
		l2.set_meta("loc_fmt", true)
		l2.add_theme_font_size_override("font_size", 18)
		l2.add_theme_color_override("font_color", Color(0.80, 0.86, 0.92) if not voll else Color(0.62, 0.66, 0.72))
		l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(l2)
		b.pressed.connect(_buy_skill.bind(id))
		skill_box.add_child(b)
		stufen.append("%s=%d/%d" % [id.replace("skill_", ""), stufe, int(SKILL_CAP)])
	print("[WSHOP][SKILLS] runde=%d angebot=%d stand=%s" % [r, SKILLS.size(), ",".join(stufen)])


func _buy_skill(id: String) -> bool:
	if rm == null:
		return false
	var r: int = int(rm.get("round_no"))
	var diff: String = str(rm.get("difficulty"))
	var stufe: int = int(rm.call("skill_stacks_of", id))
	var preis: int = skill_price(id, r, diff, stufe)
	if bool(rm.call("buy_skill", id, preis)):
		var k: Dictionary = skill_by_id(id)
		host.show_banner(Loc.t(str(k.get("name", id))), Color(0.45, 0.90, 0.60))
		_after_purchase(false)
		return true
	if stufe >= int(SKILL_CAP):
		host.show_banner(Loc.t("MAXIMUM ERREICHT"), Color(1.0, 0.6, 0.3))
	else:
		host.show_banner(Loc.t("ZU WENIG MÜNZEN"), Color(1.0, 0.5, 0.35))
	return false


func _rarity_of(key: String) -> String:
	if not is_instance_valid(game.player):
		return ""
	var d = game.player.get("weapon_rarity")
	if d is Dictionary:
		return str((d as Dictionary).get(key, ""))
	return ""


func _stat_values(key: String) -> Dictionary:
	# WEAPON_STAT_VALUES liegt als Konstante in ui_manager - ueber die
	# Konstanten-Map lesen, weil `instanz.CONST` nicht zuverlaessig ist.
	var map: Dictionary = host.get_script().get_script_constant_map()
	var all_v: Dictionary = map.get("WEAPON_STAT_VALUES", {})
	return all_v.get(key, {})


func _count_nodes(n: Node) -> int:
	var c: int = 1
	for k in n.get_children():
		c += _count_nodes(k)
	return c


func _owns_weapon(key: String) -> bool:
	if not is_instance_valid(game.player):
		return false
	return (game.player.get("owned_weapons") as Array).has(key)


# ------------------------------------------------------------------
# Klick -> eigenes Fenster (W3.2)
# ------------------------------------------------------------------

func _on_weapon_click(key: String) -> void:
	var w: Dictionary = {}
	for e in WEAPONS:
		if str(e["id"]) == key:
			w = e
	if w.is_empty():
		return
	_open_window({
		"kind": "waffe",
		"id": key,
		"name": str(w["name"]),
		"rarities": true,
	})


func _on_article_click(id: String) -> void:
	var a: Dictionary = article_by_id(id)
	if a.is_empty():
		return
	_open_window({ "kind": str(a["kind"]), "id": id, "name": str(a["name"]), "desc": str(a.get("desc", "")) })


func _on_offer_click() -> void:
	if rm == null:
		return
	if bool(rm.get("offer_bought")):
		return
	var oid: String = str(rm.get("offer_id"))
	if oid == "":
		return
	var a: Dictionary = article_by_id(oid)
	_open_window({ "kind": str(a.get("kind", "")), "id": oid, "name": str(a.get("name", oid)),
		"desc": str(a.get("desc", "")), "rabatt": true, "rarities": str(a.get("kind", "")) == "waffe" })


func _open_window(data: Dictionary) -> void:
	if window != null and is_instance_valid(window):
		window.queue_free()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	# Dim hinter dem Fenster, damit der Shop dahinter nicht durchscheint
	var dim := ColorRect.new()
	dim.name = "WaveItemDim"
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.position = Vector2.ZERO
	dim.size = vp
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 19
	add_child(dim)
	window = PanelContainer.new()
	window.name = "WaveItemWindow"
	window.position = Vector2(vp.x * 0.5 - 430.0, vp.y * 0.5 - 260.0)
	window.custom_minimum_size = Vector2(860, 0)
	window.add_theme_stylebox_override("panel", host._comic_panel_sb(Color(0.08, 0.08, 0.14, 0.99), Color(0.98, 0.80, 0.20), 8, 16))
	window.z_index = 20
	add_child(window)
	window.set_meta("dim", dim)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	window.add_child(vb)
	var t := Label.new()
	t.text = str(data.get("name", "?"))
	t.set_meta("loc_fmt", true)
	t.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	t.label_settings = host._make_label_settings(40, Color(1.0, 0.88, 0.40), 8)
	vb.add_child(t)
	if str(data.get("desc", "")) != "":
		var d := Label.new()
		d.text = str(data["desc"])
		d.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(820, 0)
		d.add_theme_font_size_override("font_size", 20)
		d.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		vb.add_child(d)
	var r: int = int(rm.get("round_no")) if rm != null else 1
	var diff: String = str(rm.get("difficulty")) if rm != null else "normal"
	var rabatt: bool = bool(data.get("rabatt", false))
	if bool(data.get("rarities", false)) and str(data.get("kind", "")) == "waffe":
		# Vier Seltenheiten zur Auswahl (W3.3)
		var wdef: Dictionary = {}
		for e in WEAPONS:
			if str(e["id"]) == str(data["id"]):
				wdef = e
		var stats: Dictionary = _stat_values(str(data["id"]))
		for rar in RARITIES:
			var preis: int = weapon_price(wdef, rar, r, diff)
			if rabatt:
				preis = maxi(1, int(round(float(preis) * 0.75 / 5.0)) * 5)
			var dmg: int = maxi(1, int(round(float(stats.get("damage", 1)) * float(rar["dmg"]))))
			var rpm: int = int(round(60.0 / maxf(0.05, float(stats.get("cooldown", 0.4)))))
			# schon in dieser Seltenheit ausgeruestet -> AUSRUESTEN (kostenlos)
			var ausgeruestet: bool = _rarity_of(str(data["id"])) == str(rar["key"])
			if ausgeruestet:
				preis = 0
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 16)
			vb.add_child(row)
			var l := Label.new()
			l.text = Loc.fmt("%s  Schaden %2d  ·  %3d RPM  ·  Magazin %2d  ·  %s", [
				Loc.t(str(rar["name"])), dmg, rpm, int(stats.get("mag", 0)),
				Loc.t("AUSGERÜSTET") if ausgeruestet else Loc.fmt("%d Münzen", [preis])])
			l.set_meta("loc_fmt", true)
			l.custom_minimum_size = Vector2(600, 40)
			l.add_theme_font_size_override("font_size", 22)
			l.add_theme_color_override("font_color", rar["farbe"])
			row.add_child(l)
			var buy: Button = host._make_comic_button(Loc.t("AUSRÜSTEN") if ausgeruestet else Loc.t("KAUFEN"),
				rar["farbe"].darkened(0.35), 22)
			buy.custom_minimum_size = Vector2(190, 56)
			buy.pressed.connect(_buy_weapon.bind(str(data["id"]), str(rar["key"]), rabatt))
			row.add_child(buy)
	else:
		var a: Dictionary = article_by_id(str(data["id"]))
		var preis2: int = price_of(str(data["id"]), r, diff, rabatt)
		if str(data.get("kind", "")) == "waffe":
			preis2 = price_of(str(data["id"]), r, diff, rabatt)
		var pl := Label.new()
		pl.text = Loc.fmt("Preis: %d Münzen   ·   dein Guthaben: %d", [preis2, int(game.coins)])
		pl.set_meta("loc_fmt", true)
		pl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", 24)
		pl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.45))
		vb.add_child(pl)
		var brow := HBoxContainer.new()
		brow.alignment = BoxContainer.ALIGNMENT_CENTER
		brow.add_theme_constant_override("separation", 20)
		vb.add_child(brow)
		var kauf: Button = host._make_comic_button(Loc.t("KAUFEN"), Color(0.20, 0.60, 0.36), 26)
		kauf.custom_minimum_size = Vector2(260, 70)
		kauf.name = "WaveItemBuy"
		kauf.pressed.connect(_buy_article.bind(str(data["id"]), rabatt))
		brow.add_child(kauf)
	var ab: Button = host._make_comic_button(Loc.t("ABBRECHEN"), Color(0.40, 0.20, 0.22), 24)
	ab.custom_minimum_size = Vector2(260, 64)
	ab.pressed.connect(_close_window)
	var arow := HBoxContainer.new()
	arow.alignment = BoxContainer.ALIGNMENT_CENTER
	arow.add_child(ab)
	vb.add_child(arow)
	print("[WSHOP][FENSTER] artikel=%s offen=true" % str(data.get("id", "?")))


func _close_window() -> void:
	if window != null and is_instance_valid(window):
		var d = window.get_meta("dim", null)
		if d != null and is_instance_valid(d):
			(d as Node).queue_free()
		window.queue_free()
	window = null


# ------------------------------------------------------------------
# Kaufen
# ------------------------------------------------------------------

func _pay(preis: int) -> bool:
	if int(game.coins) < preis:
		print("[WSHOP][KAUF] preis=%d guthaben=%d ok=false grund=zu_wenig_muenz" % [preis, int(game.coins)])
		host.show_banner(Loc.t("ZU WENIG MÜNZEN"), Color(1.0, 0.5, 0.35))
		return false
	game.coins -= preis
	return true


func _buy_weapon(key: String, rarity: String, rabatt: bool = false) -> void:
	var wdef: Dictionary = {}
	for e in WEAPONS:
		if str(e["id"]) == key:
			wdef = e
	var rar: Dictionary = {}
	for rr in RARITIES:
		if str(rr["key"]) == rarity:
			rar = rr
	if wdef.is_empty() or rar.is_empty():
		return
	var preis: int = weapon_price(wdef, rar, int(rm.get("round_no")), str(rm.get("difficulty")))
	if rabatt:
		preis = maxi(1, int(round(float(preis) * 0.75 / 5.0)) * 5)
	if preis > 0 and not _pay(preis):
		return
	if is_instance_valid(game.player):
		game.player.call("add_weapon", key)
		(game.player.get("weapon_rarity") as Dictionary)[key] = rarity
		host.refresh_weapon_hud(game.player.get("owned_weapons"), key)
	var stats: Dictionary = _stat_values(key)
	print("[WSHOP][WAFFE] key=%s seltenheit=%s schaden=%d rpm=%d preis=%d gekauft=true rest=%d" % [
		key, rarity, maxi(1, int(round(float(stats.get("damage", 1)) * float(rar["dmg"])))),
		int(round(60.0 / maxf(0.05, float(stats.get("cooldown", 0.4))))), preis, int(game.coins)])
	_after_purchase(rabatt)
	_close_window()


func _buy_article(id: String, rabatt: bool = false) -> void:
	var a: Dictionary = article_by_id(id)
	if a.is_empty():
		return
	var r: int = int(rm.get("round_no"))
	var preis: int = price_of(id, r, str(rm.get("difficulty")), rabatt)
	# Grenzen vor dem Bezahlen pruefen
	if id == "revive" and not bool(rm.can_buy_revive()):
		print("[WSHOP][LEBEN] art=revive ok=false limite=erreicht")
		host.show_banner(Loc.t("MAX. 2 VERSICHERUNGEN"), Color(1.0, 0.6, 0.3))
		_close_window()
		return
	if id == "herz" and not bool(rm.can_buy_heart()):
		print("[WSHOP][LEBEN] art=herz ok=false limite=erreicht")
		host.show_banner(Loc.t("MAX. 5 HERZEN GEKAUFT"), Color(1.0, 0.6, 0.3))
		_close_window()
		return
	if not _pay(preis):
		return
	match id:
		"herz":
			if is_instance_valid(game.player):
				game.player.max_health = int(game.player.max_health) + 1
				game.player.health = int(game.player.health) + 1
			rm.set("hearts_bought", int(rm.get("hearts_bought")) + 1)
			print("[WSHOP][LEBEN] art=herz wert=1 preis=%d ok=true max=%d" % [
				preis, int(game.player.max_health)])
		"revive":
			rm.set("lives", int(rm.get("lives")) + 1)
			print("[WSHOP][LEBEN] art=revive wert=%d preis=%d ok=true" % [int(rm.get("lives")), preis])
		"schild":
			if is_instance_valid(game.player):
				game.player.shield = int(game.player.shield) + 2
				game.player.shield_time = 9999.0
			print("[WSHOP][LEBEN] art=schild wert=2 preis=%d ok=true" % preis)
		"potion":
			if is_instance_valid(game.player):
				game.player.call("add_utility", "potion", 1)
			print("[WSHOP][TRANK] art=potion effekt=1 preis=%d ok=true" % preis)
		"bombe":
			if is_instance_valid(game.player):
				game.player.call("add_utility", "bomb", 1)
			print("[WSHOP][TRANK] art=bombe effekt=1 preis=%d ok=true" % preis)
		"frost":
			game.freeze_time = 10.0
			print("[WSHOP][TRANK] art=frost effekt=10s preis=%d ok=true" % preis)
		_:
			if id.begins_with("weapon_"):
				_buy_weapon(id, "common", rabatt)
				return
			print("[WSHOP][KAUF] artikel=%s FEHLER unbekannt" % id)
			game.coins += preis
			return
	_after_purchase(rabatt)
	_close_window()


func _after_purchase(rabatt: bool) -> void:
	if rabatt and rm != null:
		rm.set("offer_bought", true)
		print("[WSHOP][ANGEBOT] runde=%d artikel=%s gekauft=true ausverkauft=true" % [
			int(rm.get("round_no")), str(rm.get("offer_id"))])
	_rebuild()
	host.update_wave_label(int(rm.get("round_no")), int(game.coins), true, -1.0, 0)
	SoundManager.play("pickup")   # Kauf


func close() -> void:
	if window != null and is_instance_valid(window):
		window.queue_free()
		window = null
	game.set_rounds_shop_open(false)
	queue_free()
	print("[WSHOP][ZU] geschlossen")
