class_name ChestOpenUI
extends Control

# v1.52 — Kisten-Oeffnung mit drei waehlbaren Inszenierungen.
#
# Der Nutzer wollte weg vom Laufband (Roulette) hin zur Kiste selbst: "der
# Hintergrund beim Oeffnen kann weg sein, es soll sich nur auf die Kisten-
# oeffnung konzentriert werden". Deshalb gibt es drei Stile, die sich in
# Dramaturgie und Effekt-Mix unterscheiden:
#
#   STIL 1  TUSCHE-KNALL   ruhig, handgezeichnet, ein grosser Knall       ~3,0 s
#   STIL 2  POW-PANEL      laut, Panel-Rahmen, Slow-Mo, Sternenexplosion  ~4,2 s
#   STIL 3  NEON-CHARGE    technisch, Aufladen, Energie-Ringe, Lichtsaeule ~3,8 s
#
# Umschalten: Konstante DEFAULT_STYLE oder Umgebungsvariable COMIC_CHEST_STYLE
# (0 = altes Laufband in chest_ui.gd, 1/2/3 = die Stile hier).

signal finished(result: Dictionary)
signal closed()

# v1.53: Es bleibt bei EINEM Stil - POW-PANEL (Nutzerentscheidung).
# 1 (Tusche) und 3 (Neon) sind entfernt, nicht nur abgeschaltet.
const STYLE_FIXED := 2

const STAR_TEX_SIZE := 24

var gm: Node = null
var host: Node = null
var result: Dictionary = {}
var style: int = STYLE_FIXED
var tier: String = "standard"

var chest: ChestView = null
var card: PanelContainer = null
var _ready_btn: Button = null
var _hint: Label = null
var _flash: ColorRect = null
var _ring: Control = null
var _beam: Control = null
var _word_layer: Control = null
var _particles: CPUParticles2D = null
var _tween: Tween = null
var _done: bool = false
var _t_start: int = 0
var _phase: String = ""
var _fx_count: int = 0
var _word_count: int = 0
var _star_tex: ImageTexture = null
var _letzter_tipp_ms: int = 0      # v1.57c: Doppelzaehlung (Touch + Maus-Emulation)
var _ready_to_close: bool = false   # v1.57c: "WEITER"-Knopf schon sichtbar


func setup(gmi: Node) -> void:
	gm = gmi
	host = gm.get("ui_manager")
	style = STYLE_FIXED
	print("[CHESTFX][SETUP] stil=%d (%s) fest=ja" % [style, ChestView.STYLE_NAMES[style - 1]])


func open(chest_id: String, res: Dictionary) -> void:
	result = res
	tier = chest_id
	var vp: Vector2 = get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	size = vp
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_star_tex = _make_star_texture()
	_build()
	var t: String = str(res.get("rarity", "common"))
	print("[CHESTFX][START] stil=%d tier=%s item=%s_%d rarity=%s dup=%s" % [
		style, tier, str(res.get("kind", "?")), int(res.get("index", -1)), t,
		str(res.get("duplicate", false))])
	_t_start = Time.get_ticks_msec()
	_anim_pow()


# ------------------------------------------------------------------ Aufbau
func _build() -> void:
	# Hintergrund je Stil: Papier (Tusche), Panel (Pow), Nacht (Neon)
	var bg := ColorRect.new()
	bg.name = "ChestBg"
	bg.position = Vector2.ZERO
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match style:
		1:
			bg.color = Color(0.94, 0.90, 0.80, 0.97)
		2:
			bg.color = Color(0.04, 0.03, 0.08, 0.99)
		_:
			bg.color = Color(0.02, 0.02, 0.06, 0.995)
	add_child(bg)
	# v1.53: dezenter Hintergrund im Spieldesign (Verlauf, Halbton, Speedlines,
	# Vignette, Raritäts-Glow) - vorher war die Flaeche einfach nur schwarz.
	var bd := Backdrop.new()
	bd.name = "ChestBackdrop"
	bd.position = Vector2.ZERO
	bd.size = size
	bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bd.style = style
	bd.tint = _rarity_col(str(result.get("rarity", "common")))
	bd.chest_y = size.y * 0.42
	add_child(bd)
	_fx("hintergrund", "stil=%d ebene=backdrop verlauf+halbton+speedlines+vignette" % style)
	# Papier-Halbton bei Stil 1 als eigene Ebene
	if style == 1:
		var dots := HalftoneBackdrop.new()
		dots.size = size
		dots.position = Vector2.ZERO
		dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dots)
		_fx("halbton_hintergrund", "raster=9")

	# Kiste
	var cs: float = clampf(size.y * 0.42, 260.0, 520.0)
	chest = ChestView.new()
	chest.name = "ChestView"
	chest.size = Vector2(cs, cs)
	chest.position = Vector2(size.x * 0.5 - cs * 0.5, size.y * 0.5 - cs * 0.62)
	chest.set_style(style - 1)
	chest.set_tier(tier)
	chest.pivot_offset = chest.size * 0.5
	add_child(chest)
	_fx("kiste", "px=%d stil=%s tier=%s" % [int(cs), ChestView.STYLE_NAMES[style - 1], tier])

	# Lichtsaeule (nur Neon)
	var beam := Beam.new()
	beam.name = "ChestBeam"
	(beam as Control).position = Vector2(size.x * 0.5 - cs * 0.55, chest.position.y - cs * 0.95)
	(beam as Control).size = Vector2(cs * 1.1, cs * 1.6)
	(beam as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.col = Color(0.45, 0.98, 1.0)
	beam.alpha = 0.0
	add_child(beam)
	_beam = beam

	# Schockwellen-Ring (eigene Zeichenebene)
	_ring = Ring.new()
	_ring.name = "ChestRing"
	(_ring as Control).position = Vector2.ZERO
	(_ring as Control).size = size
	(_ring as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_ring as Control).visible = false
	add_child(_ring)

	# Comic-Woerter ("KLIRR!", "POW!", "ZZZAP!")
	_word_layer = Control.new()
	_word_layer.name = "ChestWords"
	_word_layer.position = Vector2.ZERO
	_word_layer.size = size
	_word_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_word_layer)

	# Partikel (Funken/Staub)
	_particles = CPUParticles2D.new()
	_particles.name = "ChestParticles"
	_particles.position = Vector2(size.x * 0.5, chest.position.y + cs * 0.42)
	_particles.one_shot = true
	_particles.emitting = false
	_particles.amount = 46
	_particles.lifetime = 1.1
	_particles.explosiveness = 0.95
	_particles.direction = Vector2(0, -1)
	_particles.spread = 62.0
	_particles.gravity = Vector2(0, 620)
	_particles.initial_velocity_min = 180.0
	_particles.initial_velocity_max = 520.0
	_particles.scale_amount_min = 0.5
	_particles.scale_amount_max = 1.5
	_particles.texture = _star_tex
	match style:
		1:
			_particles.color = Color(0.15, 0.12, 0.10)
		2:
			_particles.color = Color(1.0, 0.88, 0.25)
		_:
			_particles.color = Color(0.50, 0.98, 1.0)
	add_child(_particles)

	# Blitz
	_flash = ColorRect.new()
	_flash.name = "ChestFlash"
	_flash.position = Vector2.ZERO
	_flash.size = size
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	# Ergebnis-Karte
	_build_card()


func _build_card() -> void:
	card = PanelContainer.new()
	card.name = "ChestCard"
	var cw: float = minf(size.x * 0.62, 820.0)
	card.custom_minimum_size = Vector2(cw, 0)
	card.position = Vector2(size.x * 0.5 - cw * 0.5, size.y * 0.70)
	card.size = Vector2(cw, 0)
	card.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.85, 0.85)
	card.pivot_offset = Vector2(cw * 0.5, 120)
	add_child(card)
	var rar: String = str(result.get("rarity", "common"))
	var rc: Color = _rarity_col(rar)
	card.add_theme_stylebox_override("panel",
		host._comic_panel_sb(Color(0.05, 0.05, 0.09, 1.0), rc, 10, 20))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var head := Label.new()
	head.text = "DU HAST ERHALTEN"
	head.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	head.label_settings = host._make_label_settings(38, rc.lightened(0.30), 8)
	vb.add_child(head)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	vb.add_child(row)
	var icon := TextureRect.new()
	icon.name = "ChestRewardIcon"
	icon.custom_minimum_size = Vector2(180, 180)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = _icon_tex(result)
	row.add_child(icon)
	var txt := VBoxContainer.new()
	txt.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(txt)
	var nm := Label.new()
	nm.name = "ChestRewardName"
	nm.text = str(result.get("name", "Belohnung"))
	nm.label_settings = host._make_label_settings(40, Color(0.99, 0.99, 1.0), 7)
	txt.add_child(nm)
	var sub := Label.new()
	sub.text = rar.to_upper() + ("  ·  DOPPELT" if bool(result.get("duplicate", false)) else "")
	sub.label_settings = host._make_label_settings(24, rc, 5)
	txt.add_child(sub)
	# v1.52: Bonus je Seltenheit, direkt unter der Stufe
	var b: Dictionary = result.get("bonus", {})
	var bg: int = int(b.get("gold", 0))
	var bm: int = int(b.get("gems", 0))
	if bg > 0 or bm > 0:
		var bl := Label.new()
		bl.name = "ChestBonus"
		var teile: Array = []
		if bg > 0:
			teile.append("+%d GOLD" % bg)
		if bm > 0:
			teile.append("+%d EDELSTEINE" % bm)
		bl.text = "  ·  ".join(teile)
		bl.label_settings = host._make_label_settings(26, Color(0.98, 0.86, 0.42), 5)
		txt.add_child(bl)

	_ready_btn = host._make_comic_button("WEITER", Color(0.20, 0.60, 0.36), 28)
	_ready_btn.name = "ChestAgain"
	_ready_btn.custom_minimum_size = Vector2(320, 66)
	_ready_btn.modulate = Color(1, 1, 1, 0)
	_ready_btn.pressed.connect(_close)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_child(_ready_btn)
	vb.add_child(brow)

	_hint = Label.new()
	_hint.text = "Tippen zum Überspringen"
	_hint.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	_hint.label_settings = host._make_label_settings(20, Color(0.72, 0.76, 0.86), 4)
	_hint.position = Vector2(0, size.y - 40)
	_hint.size = Vector2(size.x, 30)
	add_child(_hint)


func _icon_tex(res: Dictionary) -> Texture2D:
	# Das gewonnene Item zeigt SICH SELBST (Hut/Skin/Farbe/Gold/Gems).
	if host != null and host.has_method("_chest_icon_texture"):
		var t = host.call("_chest_icon_texture", res)
		if t != null:
			return t
	return TextureManager.get_texture("chest")


# ------------------------------------------------------------------ Tipp-Dramaturgie
#
# v1.53: Die Kiste oeffnet sich NICHT von selbst. Jede Seltenheitsstufe kostet
# einen Tipp weniger als die naechste Stufe - der Spieler weiss nicht, wie oft
# er noch tippen muss, und hofft bei jedem Tipp auf etwas Selteneres:
#   common 1 Tipp · rare 2 · epic 3 · legendary 4
# Die Kiste bleibt bis zum letzten Tipp ZU; jeder Tipp davor legt Effekte zu.

const TAPS_PER_RARITY := { "common": 1, "rare": 2, "epic": 3, "legendary": 4 }
const TAP_WORDS := ["KLIRR!", "BAM!", "KRACH!", "WUMM!"]

var _taps_needed: int = 1
var _stage: int = 0
var _opening: bool = false


func _taps_for_rarity() -> int:
	var r: String = str(result.get("rarity", "common"))
	return int(TAPS_PER_RARITY.get(r, 1))


func _anim_pow() -> void:
	_phase = "warten"
	_lid(0.0)
	chest.scale = Vector2(0.62, 0.62)
	chest.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(chest, "modulate:a", 1.0, 0.22)
	tw.tween_property(chest, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_setup_taps()


func _setup_taps() -> void:
	_taps_needed = _taps_for_rarity()
	_stage = 0
	_opening = false
	if _hint != null:
		_hint.visible = true
		_hint.text = "TIPPEN, UM ZU RÜTTELN"
	print("[CHESTFX][TIPP] benoetigt=%d rarity=%s tier=%s hinweis=ohne_zaehler" % [
		_taps_needed, str(result.get("rarity", "common")), tier])


func _tap() -> void:
	if _done or _opening:
		return
	_stage += 1
	if _stage >= _taps_needed:
		_open_now()
	else:
		_escalate(_stage)


func _escalate(n: int) -> void:
	# Jeder Tipp vor dem Oeffnen legt Effekte zu: mehr Wackeln, mehr Gluehen,
	# ein Ring, ein Wort, ein Partikelstoss - die Kiste bleibt aber ZU.
	var st: float = 3.0 + 3.0 * float(n)
	var glow: float = 0.25 + 0.2 * float(n)
	shake_chest(st, 0.09, 3)
	chest.set_state(-1.0, glow, Vector2.ZERO, 1.0 - 0.03 * float(n))
	var ring_col: Color = Color(0.98, 0.80, 0.22)
	if style == 1:
		ring_col = Color(0.09, 0.08, 0.10)
	elif style == 3:
		ring_col = Color(0.45, 0.98, 1.0)
	ring_burst(ring_col, 210.0 + 70.0 * float(n), 0.32, 10.0)
	word(str(TAP_WORDS[mini(n - 1, TAP_WORDS.size() - 1)]),
		Color(0.99, 0.86, 0.32), -0.08, 0.75 + 0.12 * float(n))
	flash(0.08 + 0.04 * float(n), 0.06)
	if n >= 2:
		spark_shower()
	SoundManager.play("chest_tick" if n < 3 else "chest_tick_slow")
	print("[CHESTFX][TIPP] nr=%d von=%d rarity=%s wackeln=%.0f gluehen=%.2f kiste=zu" % [
		n, _taps_needed, str(result.get("rarity", "common")), st, glow])


func shake_chest(strength: float, step: float, times: int) -> void:
	_shake(chest, strength, step, times)


func _open_now() -> void:
	_opening = true
	_phase = "knall"
	# Knall (Effekte + Deckel), danach Karte
	_pow_open()
	print("[CHESTFX][OEFFNEN] tipps=%d rarity=%s tier=%s" % [
		_stage, str(result.get("rarity", "common")), tier])
	var tw := create_tween()
	# Knall erst stehen lassen, dann Karte - 0,5 s war zu kurz, die Effekte
	# waren weg, bevor das Auge sie gelesen hat.
	tw.tween_interval(0.85)
	tw.tween_callback(_show_card)
	tw.tween_interval(1.1 + 0.3 * float(_tier_extra() + _rarity_extra()))
	tw.tween_callback(_enable_ready)


# ------------------------------------------------------------------ Knall je Stil
func _pow_open() -> void:
	_impact()
	flash(1.0, 0.07)
	_lid(1.0, 0.08)
	chest.set_state(1.0, 1.0, Vector2.ZERO, 1.12)
	var tw := create_tween()
	tw.tween_property(chest, "scale", Vector2(1.22, 1.22), 0.10)
	tw.tween_property(chest, "scale", Vector2(0.98, 0.98), 0.30).set_trans(Tween.TRANS_BACK)
	ring_burst(Color(1.0, 0.86, 0.16), 520.0, 0.42, 26.0)
	rings_burst(Color(1.0, 1.0, 1.0), 420.0, 0.30, 6.0, 0.06)
	word_burst("POW!", Color(1.0, 0.86, 0.16), 1.55)
	burst(1.0)
	rays(1.0)
	spark_shower()
	_shake_all(14.0, 0.18)
	_fx("deckel_auf", "stil=pow")


func _rarity_extra() -> int:
	# Vorfreude skaliert mit der SELTENHEIT des Gewinns, nicht nur mit der
	# Kistenstufe: episch/legendär bekommen deutlich mehr Anticipation.
	match str(result.get("rarity", "common")):
		"rare":
			return 1
		"epic":
			return 2
		"legendary":
			return 3
	return 0


func _is_epic() -> bool:
	var r: String = str(result.get("rarity", "common"))
	return r == "epic" or r == "legendary"


func _tier_extra() -> int:
	# Recherche-Empfehlung (CHEST_ANIM_REFERENZ.md): die Stufe bekommt eine
	# ANDERE FORM, nicht nur mehr Partikel - Standard kurz, Silber ein
	# zusaetzlicher Anticipation-Takt, Premium zwei plus laengere Haltezeit.
	match ChestView._norm_tier(tier):
		"silver":
			return 1
		"premium":
			return 2
	return 0


func _extra_beats(tw: Tween) -> void:
	var gesamt: int = _tier_extra() + _rarity_extra()
	for i in range(gesamt):
		var st: float = 4.0 + 2.0 * float(i)
		tw.tween_callback(func(): flash(0.12, 0.05))
		tw.tween_callback(func(): _shake(chest, st, 0.09, 3))
		tw.tween_interval(0.24)
	if gesamt > 0:
		print("[CHESTFX][TAKT] tier=%s rarity=%s zusatz_takte=%d (stufe %d + seltenheit %d)" % [
			tier, str(result.get("rarity", "common")), gesamt, _tier_extra(), _rarity_extra()])


func _epic_fx() -> void:
	# Vorfreude-Kick fuer episch/legendaer: zweiter Ring, zweite Partikelwolke
	# (violett), groesserer Stern, eigenes Wort und ein Atempause-Moment.
	if not _is_epic():
		return
	var farbe: Color = Color(0.72, 0.45, 0.95)
	ring_burst(farbe, 680.0, 0.54, 26.0)
	var p2 := CPUParticles2D.new()
	p2.name = "ChestParticlesEpic"
	p2.position = Vector2(size.x * 0.5, chest.position.y + chest.size.y * 0.30)
	p2.one_shot = true
	p2.amount = 64
	p2.lifetime = 1.5
	p2.explosiveness = 1.0
	p2.direction = Vector2(0, -1)
	p2.spread = 85.0
	p2.gravity = Vector2(0, 420)
	p2.initial_velocity_min = 140.0
	p2.initial_velocity_max = 430.0
	p2.scale_amount_min = 0.4
	p2.scale_amount_max = 1.7
	p2.color = farbe
	p2.texture = _star_tex
	add_child(p2)
	p2.emitting = true
	word("EPISCH!", farbe.lightened(0.25), 0.08, 1.15)
	print("[CHESTFX][EPIC] rarity=%s ring=2 partikel=%d farbe=%s atempause=0.28" % [
		str(result.get("rarity", "")), p2.amount, farbe.to_html(false)])
	var tw := create_tween()
	tw.tween_interval(0.28)


func _impact() -> void:
	# Drei Griffe, die den Knall physisch machen (Recherche #10, #24, #25):
	# kurzer Hitstop, Vibration auf dem Geraet, Deckel-Sound je Stufe.
	Engine.time_scale = 0.05
	var tree := get_tree()
	if tree != null:
		tree.create_timer(0.06, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(45, 0.7)
	SoundManager.play("chest_open_" + _norm_tier_for_sound(tier))
	_epic_fx()
	print("[CHESTFX][IMPACT] hitstop=0.06 vibration=%s sound=chest_open_%s" % [
		str(OS.has_feature("mobile")), _norm_tier_for_sound(tier)])


func _norm_tier_for_sound(t: String) -> String:
	if str(t) == "standard" or str(t) == "wood":
		return "standard"
	if str(t) == "premium" or str(t) == "gold":
		return "premium"
	return "silver"


func _fx(name: String, detail: String) -> void:
	_fx_count += 1
	print("[CHESTFX][FX] nr=%d %s %s" % [_fx_count, name, detail])


func _lid(t: float, dur: float = 0.0) -> void:
	if dur <= 0.0:
		chest.set_state(t, -1.0)
		return
	var tw := create_tween()
	tw.tween_method(func(v: float): chest.set_state(v), chest.lid_t, t, dur) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake(node: Control, strength: float, step: float, times: int) -> void:
	var tw := create_tween()
	for i in range(times):
		var off := Vector2(randf_range(-strength, strength), randf_range(-strength * 0.6, strength * 0.6))
		tw.tween_property(node, "position", node.position + off, step * 0.5)
		tw.tween_property(node, "position", node.position, step * 0.5)
	_fx("shake", "staerke=%.1f mal=%d" % [strength, times])


func _shake_all(strength: float, step: float) -> void:
	if chest != null:
		_shake(chest, strength, step, 4)
	if card != null and card.modulate.a > 0.1:
		_shake(card, strength * 0.4, step, 3)


func flash(alpha: float, dur: float) -> void:
	if _flash == null:
		return
	_flash.color = Color(1, 1, 1, alpha)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur)
	_fx("blitz", "alpha=%.2f dauer=%.2f" % [alpha, dur])


func ring_burst(col: Color, radius: float, dur: float, width: float) -> void:
	var r := _ring as Ring
	if r == null:
		return
	r.setup(col, radius, dur, width, chest.get_global_rect().get_center())
	r.play()
	_fx("ring", "radius=%.0f dauer=%.2f" % [radius, dur])


func rings_burst(col: Color, radius: float, dur: float, width: float, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	ring_burst(col, radius, dur, width)


func ring_pulse(col: Color, radius: float, dur: float) -> void:
	ring_burst(col, radius, dur, 5.0)


func word(text: String, col: Color, rot: float, scale_to: float) -> void:
	if _word_layer == null:
		return
	var l := Label.new()
	l.name = "ChestWord_%d" % _word_count
	l.text = text
	l.z_index = 5
	var ls := LabelSettings.new()
	ls.font_size = 92
	ls.font_color = col
	ls.outline_size = 12
	ls.outline_color = Color(0.02, 0.02, 0.04) if style != 1 else Color(0.98, 0.96, 0.90)
	l.label_settings = ls
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(size.x, 120)
	l.position = Vector2(0, size.y * 0.11)
	l.pivot_offset = Vector2(size.x * 0.5, 60)
	l.rotation = rot
	l.scale = Vector2(0.2, 0.2)
	l.modulate = Color(1, 1, 1, 0)
	_word_layer.add_child(l)
	_word_count += 1
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 1.0, 0.08)
	tw.tween_property(l, "scale", Vector2(scale_to, scale_to), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(0.5)
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 0.0, 0.34)
	tw.tween_property(l, "position:y", l.position.y - 60.0, 0.34)
	tw.set_parallel(false)
	tw.tween_callback(l.queue_free)
	_fx("wort", "text=%s" % text)


func word_burst(text: String, col: Color, scale_to: float) -> void:
	word(text, col, -0.10, scale_to)


func burst(t: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): chest.set_state(-1.0, -1.0, Vector2(-999, -999), -1.0, -1.0, v), 0.0, t, 0.22)
	_fx("sternen_burst", "t=%.2f" % t)


func rays(t: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): chest.set_state(-1.0, -1.0, Vector2(-999, -999), -1.0, v), 0.0, t, 0.30)
	_fx("strahlenkranz", "t=%.2f" % t)


func spark_shower() -> void:
	if _particles == null:
		return
	_particles.emitting = true
	_particles.restart()
	_fx("partikel", "anzahl=%d" % _particles.amount)


func _show_card() -> void:
	_phase = "karte"
	# Strahlen/Stern weich ausblenden statt hart abschalten - der Knall bleibt
	# kurz stehen und die Karte bekommt danach eine ruhige Buehne.
	if chest != null:
		chest.set_state(-1.0, 0.35)
		var fade := create_tween()
		fade.set_parallel(true)
		fade.tween_method(func(v: float): chest.set_state(-1.0, -1.0, Vector2(-999, -999), -1.0, v),
			chest.rays_t, 0.0, 0.45)
		fade.tween_method(func(v2: float): chest.set_state(-1.0, -1.0, Vector2(-999, -999), -1.0, -1.0, v2),
			chest.burst_t, 0.0, 0.45)
	if card == null:
		return
	# Kiste macht Platz: kleiner und nach oben, damit die Belohnung frei steht
	var ziel_scale: float = 0.66
	var ziel_y: float = size.y * 0.5 - chest.size.y * 0.98
	var tw0 := create_tween()
	tw0.set_parallel(true)
	tw0.tween_property(chest, "scale", Vector2(ziel_scale, ziel_scale), 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw0.tween_property(chest, "position:y", ziel_y, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw0.tween_property(chest, "modulate:a", 0.92, 0.30)
	# Karte immer komplett sichtbar: nach dem Layout an den unteren Rand setzen
	await get_tree().process_frame
	var karte_y: float = clampf(size.y - card.size.y - 26.0, size.y * 0.45, size.y)
	card.position.y = karte_y + 46.0
	if _hint != null:
		_hint.visible = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.12)
	tw.tween_property(card, "position:y", karte_y, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx("karte", "rarity=%s" % str(result.get("rarity", "common")))


func _enable_ready() -> void:
	_phase = "fertig"
	if _ready_btn != null:
		var tw := create_tween()
		tw.tween_property(_ready_btn, "modulate:a", 1.0, 0.18)
		_ready_btn.disabled = false
	_done = true
	_ready_to_close = true
	var dauer: float = float(Time.get_ticks_msec() - _t_start) / 1000.0
	print("[CHESTFX][FERTIG] stil=%d dauer=%.2f s effekte=%d woerter=%d" % [
		style, dauer, _fx_count, _word_count])


func _skip() -> void:
	if _done:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_opening = true
	_lid(1.0)
	chest.set_state(1.0, 1.0, Vector2.ZERO, 1.0)
	_phase = "skip"
	_show_card()
	_enable_ready()
	print("[CHESTFX][SKIP] t=%.2f tipps=%d von=%d" % [
		float(Time.get_ticks_msec() - _t_start) / 1000.0, _stage, _taps_needed])


func _gui_input(event: InputEvent) -> void:
	# v1.57c (Bug 3, zweiter Teil): Das Overlay-Root hat MOUSE_FILTER_STOP und
	# schluckt damit JEDES Ereignis - _unhandled_input wurde deshalb nie
	# erreicht und die Oeffnung reagierte auf keinen Tipp (Messung: 6 Tipps,
	# stage blieb 0, done=false, Kiste blieb fuer immer zu).
	# Jetzt laeuft die Tipp-Weiche HIER an, _unhandled_input bleibt Fallback.
	_tipp_weiche(event)


func _unhandled_input(event: InputEvent) -> void:
	_tipp_weiche(event)


func _tipp_weiche(event: InputEvent) -> void:
	# v1.53: Tippen ist jetzt der Motor der Oeffnung (ein Tipp je Stufe),
	# ESC/Zurueck bleibt der Abkuerzungspfad direkt zum Ergebnis.
	if event.is_action_pressed("ui_cancel") and not _done:
		_skip()
		get_viewport().set_input_as_handled()
		return
	var klick: bool = false
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		klick = true
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		klick = true
	if not klick:
		return
	# Ein Tipp darf nur EINMAL zaehlen, auch wenn Maus-Emulation und
	# Touch-Ereignis beide ankommen.
	var jetzt: int = Time.get_ticks_msec()
	if jetzt - _letzter_tipp_ms < 80:
		return
	_letzter_tipp_ms = jetzt
	if _done:
		# fertig animiert, aber noch nicht geschlossen -> Tipp schliesst
		if _ready_to_close:
			_close()
		return
	print("[CHESTFX][TIPP] stage=%d von=%d t=%.2f" % [
		_stage + 1, _taps_needed, float(jetzt - _t_start) / 1000.0])
	_tap()
	get_viewport().set_input_as_handled()


func _close() -> void:
	var d: float = float(Time.get_ticks_msec() - _t_start) / 1000.0
	print("[CHESTFX][ZU] stil=%d gesamt=%.2f s phasen=%s" % [style, d, _phase])
	emit_signal("finished", result)
	emit_signal("closed")
	queue_free()


# ------------------------------------------------------------------ Hilfen
func _rarity_col(r: String) -> Color:
	match r:
		"rare":
			return Color(0.35, 0.65, 0.95)
		"epic":
			return Color(0.72, 0.45, 0.95)
		"legendary":
			return Color(0.99, 0.72, 0.20)
	return Color(0.72, 0.74, 0.78)


func _make_star_texture() -> ImageTexture:
	var s: int = STAR_TEX_SIZE
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(s * 0.5, s * 0.5)
	for y in range(s):
		for x in range(s):
			var d: float = Vector2(float(x) - c.x, float(y) - c.y).length() / (s * 0.5)
			if d <= 0.55:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
			elif d <= 0.95:
				# vier Zacken
				var ax: float = absf(float(x) - c.x)
				var ay: float = absf(float(y) - c.y)
				if ax < (1.0 - ay / (s * 0.5)) * 2.2 or ay < (1.0 - ax / (s * 0.5)) * 2.2:
					img.set_pixel(x, y, Color(1, 1, 1, 0.85))
	return ImageTexture.create_from_image(img)


# ===================================================================
# Ring: expandierender Schockwellen-Kreis (eigene Zeichenebene)
# ===================================================================
class Ring extends Control:
	var col: Color = Color.WHITE
	var radius: float = 0.0
	var target: float = 0.0
	var dur: float = 0.4
	var width: float = 8.0
	var center: Vector2 = Vector2.ZERO
	var alpha: float = 1.0

	func setup(c: Color, r: float, d: float, w: float, ctr: Vector2) -> void:
		col = c
		target = r
		dur = d
		width = w
		center = ctr
		radius = 8.0
		alpha = 1.0

	func play() -> void:
		visible = true
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_method(func(v: float): radius = v; queue_redraw(), 8.0, target, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(v: float): alpha = v; queue_redraw(), 1.0, 0.0, dur)
		tw.set_parallel(false)
		tw.tween_callback(func(): visible = false)

	func _draw() -> void:
		if radius <= 0.0:
			return
		var c: Color = col
		c.a = alpha
		draw_arc(center, radius, 0.0, TAU, 72, c, width, true)


# ===================================================================
# HalftoneBackdrop: Papier mit Punktraster (Stil 1)
# ===================================================================
class HalftoneBackdrop extends Control:
	func _draw() -> void:
		var step: float = 26.0
		var col := Color(0.10, 0.09, 0.12, 0.10)
		var y: float = 0.0
		var row: int = 0
		while y < size.y:
			var x: float = 0.0 if row % 2 == 0 else step * 0.5
			while x < size.x:
				draw_circle(Vector2(x, y), 3.2, col, true, -1.0, true)
				x += step
			y += step
			row += 1


# ===================================================================
# Beam: Lichtsaeule mit weichen Raendern (drei Rechtecke, gestapelt)
# ===================================================================
class Beam extends Control:
	var col: Color = Color(0.45, 0.98, 1.0)
	var alpha: float = 0.0:
		set(v):
			alpha = v
			queue_redraw()

	func _ready() -> void:
		set_process(false)

	func _draw() -> void:
		if alpha <= 0.001:
			return
		var layers: Array = [
			[0.00, 1.00, 0.10],
			[0.22, 0.56, 0.30],
			[0.38, 0.24, 0.85],
		]
		for l in layers:
			var c: Color = col
			c.a = alpha * float(l[2])
			var x: float = size.x * float(l[0])
			draw_rect(Rect2(Vector2(x, 0.0), Vector2(size.x * float(l[1]), size.y)), c)


# ===================================================================
# Backdrop: dezenter Buehnen-Hintergrund im Comic-Stil
#   1 Verlauf  2 Halbton mit Radial-Fade  3 diagonale Speedlines
#   4 Vignette  5 farbiger Glow hinter der Kiste (Raritaet)
# ===================================================================
class Backdrop extends Control:
	var style: int = 2
	var tint: Color = Color(0.98, 0.80, 0.22)
	var chest_y: float = 460.0

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var a: Color
		var b: Color
		match style:
			1:
				a = Color(0.97, 0.93, 0.84)
				b = Color(0.88, 0.82, 0.68)
			3:
				a = Color(0.05, 0.07, 0.15)
				b = Color(0.02, 0.02, 0.05)
			_:
				a = Color(0.07, 0.07, 0.13)
				b = Color(0.02, 0.02, 0.04)
		# 1) Verlauf in 32 Baendern (billiger als ein Shader)
		var n: int = 32
		for i in range(n):
			var t0: float = float(i) / float(n)
			var c: Color = a.lerp(b, t0)
			draw_rect(Rect2(0.0, h * t0, w, h / float(n) + 1.0), c)
		# 2) Halbton-Punkte, nach aussen schwächer
		var step: float = 42.0
		var cx: float = w * 0.5
		var cy: float = chest_y
		var maxd: float = sqrt(cx * cx + cy * cy)
		var dot_col: Color = Color(0.02, 0.02, 0.03, 0.10) if style == 1 else Color(1, 1, 1, 0.045)
		var row: int = 0
		var y: float = 0.0
		while y < h:
			var x: float = 0.0 if row % 2 == 0 else step * 0.5
			while x < w:
				var d: float = Vector2(x - cx, y - cy).length() / maxd
				var al: float = dot_col.a * clampf(1.0 - d * 0.9, 0.0, 1.0)
				if al > 0.004:
					var c2: Color = dot_col
					c2.a = al
					draw_circle(Vector2(x, y), 4.2, c2, true, -1.0, true)
				x += step
			y += step
			row += 1
		# 3) diagonale Speedlines (nur Nacht-Stile)
		if style != 1:
			var lines: int = 14
			for i in range(lines):
				var off: float = float(i) * (w / float(lines)) - w * 0.2
				var lc: Color = Color(1, 1, 1, 0.028)
				draw_line(Vector2(off, 0.0), Vector2(off + h * 0.55, h), lc, 3.0)
		# 4) Vignette: vier Randverlaeufe (Kreise bildeten sichtbare Ringe)
		var vc: Color = Color(0.0, 0.0, 0.0) if style != 1 else Color(0.42, 0.34, 0.20)
		var bands: int = 12
		var band_h: float = h * 0.055
		var band_w: float = w * 0.045
		for i in range(bands):
			var t: float = float(i) / float(bands)
			var c4: Color = vc
			c4.a = 0.075 * (1.0 - t)
			draw_rect(Rect2(0.0, band_h * float(i), w, band_h + 1.0), c4)              # oben
			draw_rect(Rect2(0.0, h - band_h * float(i + 1), w, band_h + 1.0), c4)     # unten
			draw_rect(Rect2(band_w * float(i), 0.0, band_w + 1.0, h), c4)             # links
			draw_rect(Rect2(w - band_w * float(i + 1), 0.0, band_w + 1.0, h), c4)     # rechts
		# 5) Glow hinter der Kiste in Raritaetsfarbe
		for i in range(6):
			var g: Color = tint
			g.a = 0.030 - 0.004 * float(i)
			draw_circle(Vector2(cx, cy), 180.0 + 70.0 * float(i), g, true, -1.0, true)
