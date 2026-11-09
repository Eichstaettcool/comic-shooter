# TextureManager.gd - Autoload Singleton
# Generiert alle Comic-Style Texturen zur Laufzeit (keine externen Bilddateien nötig)
extends Node

var textures: Dictionary = {}

const OUTLINE := Color(0.08, 0.08, 0.1)
const SHADOW := Color(0, 0, 0, 0.25)

func _ready():
	_generate_all_textures()

func get_texture(key: String) -> Texture2D:
	return textures.get(key)

func _generate_all_textures():
	# Tiles (Karo)
	textures["tile_light"] = _rect_tex(Color(0.60, 0.85, 0.50), 32)
	textures["tile_dark"] = _rect_tex(Color(0.45, 0.70, 0.35), 32)

	# Spieler-Held (Top-Down Comic-Figur mit Gewehr)
	textures["player"] = _make_player(Color(0.20, 0.60, 1.0), Color(0.15, 0.25, 0.55))
	# P2 Held (rot/orange fuer lokalen Multiplayer)
	textures["player2"] = _make_player(Color(0.92, 0.35, 0.15), Color(0.45, 0.15, 0.10))

	# Monster (echte Gesichter mit Hörnern, Augen, Zähnen)
	textures["monster_green"] = _make_monster(Color(0.25, 0.80, 0.30), Color(0.45, 0.95, 0.50))
	textures["monster_red"] = _make_monster(Color(0.90, 0.25, 0.22), Color(1.0, 0.50, 0.45))
	textures["monster_blue"] = _make_monster(Color(0.20, 0.50, 0.90), Color(0.45, 0.70, 1.0))
	textures["monster_purple"] = _make_monster(Color(0.60, 0.22, 0.80), Color(0.80, 0.45, 1.0))
	textures["monster_yellow"] = _make_monster(Color(0.95, 0.80, 0.15), Color(1.0, 0.92, 0.45))
	textures["monster_pink"] = _make_monster(Color(0.95, 0.45, 0.70), Color(1.0, 0.70, 0.85))
	textures["monster_orange"] = _make_monster(Color(0.95, 0.50, 0.12), Color(1.0, 0.70, 0.35))
	textures["boss"] = _make_monster(Color(0.45, 0.05, 0.10), Color(0.80, 0.20, 0.25), true)
	# Biom-Spezialisten (Punkt 5)
	textures["monster_burrower"] = _make_monster(Color(0.86, 0.72, 0.40), Color(0.98, 0.88, 0.62))
	textures["monster_golem"] = _make_monster(Color(0.52, 0.74, 0.90), Color(0.82, 0.94, 1.0))
	textures["monster_pyro"] = _make_monster(Color(0.90, 0.32, 0.14), Color(1.0, 0.72, 0.26))

	# Projektile + Mündungsfeuer
	textures["projectile"] = _make_projectile()
	textures["muzzle_flash"] = _make_muzzle_flash()
	textures["enemy_ball"] = _make_enemy_ball()

	# Kiste
	textures["chest"] = _make_chest()

	# Bäume & Steine (mit Schatten + Lichtkante)
	textures["tree"] = _make_tree()
	textures["rock"] = _make_rock()
	# --- Biome-Deko ---
	textures["cactus"] = _make_cactus()
	textures["rock_desert"] = _make_rock_col(Color(0.80, 0.68, 0.44), Color(0.58, 0.46, 0.26))
	textures["pine"] = _make_pine()
	textures["ice_rock"] = _make_rock_col(Color(0.74, 0.86, 0.94), Color(0.50, 0.66, 0.80))
	textures["dead_tree"] = _make_dead_tree()
	textures["lava_rock"] = _make_rock_col(Color(0.44, 0.30, 0.28), Color(0.24, 0.14, 0.14))
	# --- Seltenheits-Ringe (Kistenloot) ---
	textures["rarity_common"] = _make_rarity_ring(Color(0.88, 0.90, 0.86))
	textures["rarity_rare"] = _make_rarity_ring(Color(0.35, 0.72, 1.0))
	textures["rarity_epic"] = _make_rarity_ring(Color(0.88, 0.45, 1.0))
	# --- Powerup-Icons ---
	textures["powerup_freeze"] = _make_freeze_icon()
	textures["powerup_rapid"] = _make_rapid_icon()

	# Herzen
	textures["heart_full"] = _create_heart_texture(Color(0.9, 0.1, 0.1), OUTLINE, 16)
	textures["heart_empty"] = _create_heart_texture(Color(0.3, 0.0, 0.0), OUTLINE, 16)
	# Item-Texturen (Runde 15): "Extra-Herz" fragte heart_gold ab -> war nicht vorhanden
	textures["heart_gold"] = _heart_padded(Color(0.98, 0.80, 0.20), Color(0.55, 0.36, 0.05), 36)
	textures["heart_big"] = _heart_padded(Color(0.92, 0.16, 0.28), OUTLINE, 36)

	# Waffen-Icons (Pickups)
	textures["weapon_pistol"] = _make_weapon_pistol()
	textures["weapon_shotgun"] = _make_weapon_shotgun()
	textures["weapon_machine"] = _make_weapon_machine()
	textures["weapon_laser"] = _make_weapon_laser()
	textures["weapon_revolver"] = _make_weapon_revolver()

	# Touch-Controls: Joystick + Schuss-Button
	textures["stick_base"] = _make_stick_base()
	# UI-Icons (Runde 9): Zahnrad, Schild, Münze
	textures["icon_gear"] = _make_gear_icon()
	textures["icon_crosshair"] = _make_crosshair_icon()
	textures["icon_shield"] = _make_shield_icon()
	textures["icon_coin"] = _make_coin_icon()
	# Runde 44: Navigations-Icons
	textures["nav_lan"] = _make_nav_icon("lan")
	textures["nav_char"] = _make_nav_icon("char")
	textures["nav_shop"] = _make_nav_icon("shop")
	textures["nav_coll"] = _make_nav_icon("coll")
	textures["nav_map"] = _make_nav_icon("map")
	# Meta-Shop (Runde 11): Kisten & Karten
	# Runde 40: eigene Truhen-Icon je Kisten-Raritaet
	textures["chest_wood"] = _make_chest_icon_rich("wood")
	textures["chest_silver"] = _make_chest_icon_rich("silver")
	textures["chest_gold"] = _make_chest_icon_rich("gold")
	textures["chest_platinum"] = _make_chest_icon_rich("platinum")
	textures["chest_storm"] = _make_chest_icon_rich("storm")
	# Runde 43: eigene Icons je Welt (Punkt 6)
	textures["map_meadow"] = _make_map_icon_earth("spring")
	textures["map_desert"] = _make_map_icon_earth("desert")
	textures["map_ice"] = _make_map_icon_earth("ice")
	textures["map_lava"] = _make_map_icon_earth("lava")
	# Runde 12: neue Welten
	textures["map_mars"] = _make_map_icon_mars()
	textures["map_jungle"] = _make_map_icon_jungle()
	textures["monster_mars_alien"] = _make_mars_alien()
	textures["monster_mars_rover"] = _make_mars_rover()
	textures["monster_robo_ape"] = _make_robo_ape()
	textures["monster_big_flower"] = _make_big_flower()
	textures["banana"] = _make_banana()
	textures["palm"] = _make_palm()
	textures["bush"] = _make_bush_dot()
	# Runde 64: gezeichnete Buesche im Baum-Stil (Kontur + Tiefe)
	# Runde 72: gemalte Kisten aus assets/chests/ (Fallback: prozedural)
	for _tier in ["standard", "silver", "premium"]:
		textures["chest_gem_" + _tier] = _load_chest_png("res://assets/chests/chest_%s.png" % _tier, _tier, false)
		textures["chest_gem_open_" + _tier] = _load_chest_png("res://assets/chests/open_%s.png" % _tier, _tier, true)
	# Runde 94: Walzensymbole
	textures["slot_machine_icon"] = _make_slot_icon(256)
	textures["slot_gem1"] = _make_gem_icon(1, 128)
	textures["slot_gem2"] = _make_gem_icon(2, 128)
	textures["slot_gem3"] = _make_gem_icon(3, 128)
	textures["slot_cherry"] = _make_slot_symbol("cherry", 128)
	textures["slot_bell"] = _make_slot_symbol("bell", 128)
	textures["slot_bar"] = _make_slot_symbol("bar", 128)
	textures["slot_gold1"] = _make_slot_symbol("gold1", 128)
	textures["slot_gold2"] = _make_slot_symbol("gold2", 128)
	textures["slot_gold3"] = _make_slot_symbol("gold3", 128)
	textures["slot_skull"] = _make_slot_symbol("skull", 128)
	textures["pbush_a"] = _make_bush_prop(56, 0)
	textures["pbush_b"] = _make_bush_prop(56, 1)
	textures["pbush_c"] = _make_bush_prop(56, 2)
	textures["pbush_d"] = _make_bush_prop(56, 3)
	textures["mars_rock"] = _make_rock_col(Color(0.66, 0.32, 0.24), Color(0.44, 0.18, 0.14))
	textures["mars_crater"] = _make_rock_col(Color(0.52, 0.24, 0.18), Color(0.34, 0.14, 0.11))
	# Runde 14: eigene Welt-Objekte je Planet
	textures["mars_boulder"] = _make_boulder(Color(0.62, 0.30, 0.22), Color(0.80, 0.46, 0.32), 64)
	textures["mars_boulder_big"] = _make_boulder(Color(0.58, 0.27, 0.20), Color(0.76, 0.42, 0.28), 128)
	textures["mars_crater_decal"] = _make_crater(160)
	textures["jungle_tree"] = _make_jungle_tree(128)
	# Runde 18: Dschungel-Set nach den Referenzbildern des Nutzers
	textures["jtree_round"] = _make_jtree_round(176)
	textures["jtree_tall"] = _make_jtree_tall(176)
	textures["jtree_willow"] = _make_jtree_willow(176)
	textures["jtree_ancient"] = _make_jtree_ancient(200)
	textures["jpalm"] = _make_jpalm(176)
	textures["jbush_leaf"] = _make_jbush_leaf(112)
	textures["jvine"] = _make_jvine(112)
	textures["jmushroom_red"] = _make_jmushroom(56, Color(0.90, 0.26, 0.24))
	textures["jmushroom_brown"] = _make_jmushroom(44, Color(0.62, 0.44, 0.24))
	textures["jcrystal"] = _make_jcrystal(96)
	textures["jreed"] = _make_jreed(80)
	textures["bridge"] = _make_bridge()
	textures["grass_tuft"] = _make_grass_tuft()
	textures["jrock"] = _make_jrock(64)
	textures["jflower"] = _make_jflower(48)
	textures["jflower_pink"] = _make_jflower(48, Color(0.98, 0.55, 0.70), Color(0.86, 0.42, 0.58), Color(0.99, 0.85, 0.35))
	textures["jflower_yellow"] = _make_jflower(48, Color(0.99, 0.88, 0.35), Color(0.88, 0.72, 0.22), Color(0.55, 0.32, 0.12))
	textures["jflower_blue"] = _make_jflower(48, Color(0.62, 0.72, 0.98), Color(0.45, 0.55, 0.86), Color(0.98, 0.92, 0.55))
	textures["jmushroom_red"] = _make_jmushroom(52, Color(0.86, 0.24, 0.22))
	# Runde 26: neue Boss-Designs (prozedural statt zusammengeklebter Fremd-Teile)
	textures["boss_jungle"] = _make_boss_jungle()
	textures["boss_mars"] = _make_boss_mars()
	# Runde 34: Erde-Boss neu gezeichnet (mutierter Kristall-Roboter)
	textures["boss_earth"] = _make_boss_earth()
	# Runde 35: Elektro-Welt
	textures["volt_pylon"] = _make_volt_pylon()
	textures["volt_capacitor"] = _make_volt_capacitor()
	textures["volt_spool"] = _make_volt_spool()
	textures["volt_wreck"] = _make_volt_wreck()
	textures["volt_antenna"] = _make_volt_antenna()
	textures["monster_volt_drone"] = _make_monster_volt_drone()
	textures["monster_volt_trooper"] = _make_monster_volt_trooper()
	textures["monster_volt_spider"] = _make_monster_volt_spider()
	# Runde 49: Neuer Elektro-Gegner - der SPULENTROOPER
	textures["monster_volt_spooler"] = _make_monster_volt_spooler()
	textures["boss_volt"] = _make_boss_volt()
	textures["map_volt"] = _make_map_icon_volt()
	# Runde 38: Character-Rigs
	for _r in range(4):
		textures["player_rig%d" % _r] = _make_player_rig(_r)
	textures["arrow_marker"] = _make_arrow_marker()
	textures["force_field"] = _make_force_field()
	textures["boss_mini_jungle"] = _make_mini_jungle()
	textures["boss_mini_mars"] = _make_mini_mars()
	textures["boss_mini_earth"] = _make_mini_earth()
	textures["boss_mini_volt"] = _make_mini_volt()
	textures["bamboo"] = _make_bamboo_pixel()
	textures["jleafpile"] = _make_jleafpile(96)
	textures["fern"] = _make_fern(64)
	textures["mushroom"] = _make_mushroom(40)
	textures["monster_mars_drone"] = _make_mars_drone()
	textures["monster_mars_guard"] = _make_mars_guard()
	textures["monster_robo_tiger"] = _make_robo_tiger()
	textures["monster_vine_trap"] = _make_vine_trap()
	textures["chest_run_common"] = _make_run_chest(Color(0.58, 0.40, 0.22), Color(0.66, 0.68, 0.72), Color(0.55, 0.80, 1.0), false)
	textures["chest_run_rare"] = _make_run_chest(Color(0.52, 0.54, 0.60), Color(0.80, 0.84, 0.90), Color(0.35, 0.72, 1.0), false)
	textures["chest_run_epic"] = _make_run_chest(Color(0.72, 0.56, 0.16), Color(0.98, 0.84, 0.30), Color(0.80, 0.40, 1.0), true)
	textures["glow_common"] = _make_glow(96, Color(0.70, 0.90, 1.0))
	textures["glow_rare"] = _make_glow(96, Color(0.40, 0.75, 1.0))
	textures["glow_epic"] = _make_glow(96, Color(0.85, 0.45, 1.0))
	# Runde 15: ECHTE Bilddateien (CC0 Kenney "Space Shooter" Meteoriten, mit PIL auf
	# Mars-Rostorange umgefaerbt, freigestellt + quadratisch zentriert) fuer den Mars.
	for i in range(1, 5):
		_load_external("mars_big_%d" % i, "res://assets/rocks/mars_big_%d.png" % i)
		_load_external("mars_mid_%d" % i, "res://assets/rocks/mars_mid_%d.png" % i)
		_load_external("mars_small_%d" % i, "res://assets/rocks/mars_small_%d.png" % i)
	# Runde 57: Dschungel-Palme und -Buesche als echte PNGs (CC0 Kenney
	# "Background Elements", mit PIL gruen abgestimmt + schwarze Kontur
	# ergaenzt, damit sie neben den gezeichneten Figuren bestehen).
	_load_external("jpalm_png", "res://assets/props/jungle_palm.png")
	_load_external("jbush_big_png", "res://assets/props/jungle_bush_big.png")
	_load_external("jbush_small_png", "res://assets/props/jungle_bush_small.png")
	# Runde 16 (Nutzerwahl A1/E2): echte CC0-PNGs ersetzen die gezeichneten Icons
	# Runde 17 (Nutzerfeedback): Waffen wieder im Comic-Stil (prozedural) - die
	# Rohr-Optik wirkte wie eine Tuer. Herzen/Schild/Trank/Bombe bleiben echte
	# PNGs, aber rot/blau eingefaerbt (Quelle war weiss) + eigene Upgrade-Icons.
	for k in ["heart_full", "heart_empty", "heart_gold", "shield", "potion", "bomb",
			"upg_power", "upg_turbo", "upg_speed", "upg_vitality", "upg_guardian", "upg_vampire"]:
		_load_external(k, "res://assets/items/%s.png" % k)
	# Echte Props fuer Erde + Dschungel
	for i in range(1, 9):
		_load_external("prop_tree_%d" % i, "res://assets/props/tree_%d.png" % i)
	for i in range(1, 7):
		_load_external("prop_bush_%d" % i, "res://assets/props/bush_%d.png" % i)
	for i in range(1, 4):
		_load_external("prop_stone_%d" % i, "res://assets/props/stone_%d.png" % i)
	_load_external("prop_tree_snow", "res://assets/props/tree_snow.png")
	# Runde 21: Pixel-Art-Sprites fuer Bambus + Gras (Nutzerwunsch)
	# Boss-Rigs je Biom (Runde 16, Nutzerwahl B1)
	for nm in ["mars", "jungle", "earth"]:
		textures["stick_knob"] = _make_stick_knob()
	textures["btn_shoot"] = _make_shoot_button()

	# Upgrades (V6): Schild-Ring, Schild-Icon, Gold-Herz
	textures["shield_ring"] = _make_shield_ring()
	textures["shield"] = _make_shield_icon()

# ---------- Basis-Primitives ----------

func _new_img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

# Runde 59: Kantenglaettung fuer Charaktere. Die Figuren wurden mit harten
# Pixelkanten gezeichnet und sahen am Rand ausgefranst aus. Bei _aa = true
# rechnen die Primitive 4x4-Subpixel-Coverage und blenden den Rand weich ein.
var _aa: bool = false
const _AA_N: int = 4


func _aa_blend(img: Image, x: int, y: int, c: Color, cov: float) -> void:
	if cov <= 0.002:
		return
	_px_blend(img, x, y, Color(c.r, c.g, c.b, c.a * cov))


func _aa_cov_disc(x: int, y: int, cx: float, cy: float, r: float) -> float:
	var hit: int = 0
	for sy in range(_AA_N):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(_AA_N)
		for sx in range(_AA_N):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(_AA_N)
			var dx: float = px - cx
			var dy: float = py - cy
			if dx * dx + dy * dy <= r * r:
				hit += 1
	return float(hit) / float(_AA_N * _AA_N)


func _aa_cov_ellipse(x: int, y: int, cx: float, cy: float, rx: float, ry: float) -> float:
	var hit: int = 0
	for sy in range(_AA_N):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(_AA_N)
		for sx in range(_AA_N):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(_AA_N)
			var dx: float = (px - cx) / rx
			var dy: float = (py - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				hit += 1
	return float(hit) / float(_AA_N * _AA_N)


func _aa_cov_rect(x: int, y: int, x0: int, y0: int, w: int, h: int) -> float:
	var hit: int = 0
	for sy in range(_AA_N):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(_AA_N)
		for sx in range(_AA_N):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(_AA_N)
			if px >= float(x0) and px < float(x0 + w) and py >= float(y0) and py < float(y0 + h):
				hit += 1
	return float(hit) / float(_AA_N * _AA_N)


func _aa_cov_tri(x: int, y: int, a: Vector2, b: Vector2, c: Vector2) -> float:
	var hit: int = 0
	for sy in range(_AA_N):
		var py: float = float(y) - 0.5 + (float(sy) + 0.5) / float(_AA_N)
		for sx in range(_AA_N):
			var px: float = float(x) - 0.5 + (float(sx) + 0.5) / float(_AA_N)
			if _point_in_triangle(Vector2(px, py), a, b, c):
				hit += 1
	return float(hit) / float(_AA_N * _AA_N)

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)

func _px_blend(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if c.a <= 0.001:
		return
	var d: Color = img.get_pixel(x, y)
	var a = c.a + d.a * (1.0 - c.a)
	if a <= 0.0:
		return
	var r = (c.r * c.a + d.r * d.a * (1.0 - c.a)) / a
	var g = (c.g * c.a + d.g * d.a * (1.0 - c.a)) / a
	var b = (c.b * c.a + d.b * d.a * (1.0 - c.a)) / a
	img.set_pixel(x, y, Color(r, g, b, a))

func _disc(img: Image, cx: float, cy: float, r: float, c: Color, blend: bool = false) -> void:
	for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
		for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 2):
			if _aa:
				var cov := _aa_cov_disc(x, y, cx, cy, r)
				if cov > 0.0:
					_aa_blend(img, x, y, c, cov)
			elif Vector2(float(x) - cx, float(y) - cy).length() <= r:
				if blend:
					_px_blend(img, x, y, c)
				else:
					_px(img, x, y, c)

func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color, blend: bool = false) -> void:
	for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 2):
		for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 2):
			if _aa:
				var cov := _aa_cov_ellipse(x, y, cx, cy, rx, ry)
				if cov > 0.0:
					_aa_blend(img, x, y, c, cov)
				continue
			var dx := (float(x) - cx) / rx
			var dy := (float(y) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				if blend:
					_px_blend(img, x, y, c)
				else:
					_px(img, x, y, c)

func _ring(img: Image, cx: float, cy: float, r: float, thickness: float, c: Color) -> void:
	for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 2):
		for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 2):
			var d := Vector2(float(x) - cx, float(y) - cy).length()
			if d <= r and d > r - thickness:
				_px(img, x, y, c)

func _rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for x in range(x0, x0 + w):
		for y in range(y0, y0 + h):
			_px(img, x, y, c)

func _tri(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, c: Color) -> void:
	var min_x := int(floor(minf(p0.x, minf(p1.x, p2.x))))
	var max_x := int(ceil(maxf(p0.x, maxf(p1.x, p2.x))))
	var min_y := int(floor(minf(p0.y, minf(p1.y, p2.y))))
	var max_y := int(ceil(maxf(p0.y, maxf(p1.y, p2.y))))
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			if _aa:
				var cov := _aa_cov_tri(x, y, p0, p1, p2)
				if cov > 0.0:
					_aa_blend(img, x, y, c, cov)
			elif _point_in_triangle(Vector2(x, y), p0, p1, p2):
				_px(img, x, y, c)

func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 = c - a
	var v1 = b - a
	var v2 = p - a
	var dot00 = v0.dot(v0)
	var dot01 = v0.dot(v1)
	var dot02 = v0.dot(v2)
	var dot11 = v1.dot(v1)
	var dot12 = v1.dot(v2)
	var denom = dot00 * dot11 - dot01 * dot01
	if absf(denom) < 0.000001:
		return false
	var inv_denom = 1.0 / denom
	var u = (dot11 * dot02 - dot01 * dot12) * inv_denom
	var v = (dot00 * dot12 - dot01 * dot02) * inv_denom
	return u >= 0 and v >= 0 and u + v < 1

func _rect_tex(color: Color, size: int) -> ImageTexture:
	var img = _new_img(size, size)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _outlined_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, fill: Color, ow: int) -> void:
	_ellipse(img, cx, cy, rx + ow, ry + ow, OUTLINE)
	_ellipse(img, cx, cy, rx, ry, fill)

func _outlined_disc(img: Image, cx: float, cy: float, r: float, fill: Color, ow: int) -> void:
	_disc(img, cx, cy, r + ow, OUTLINE)
	_disc(img, cx, cy, r, fill)

# ---------- Spieler-Held ----------

func _make_player(shirt := Color(0.20, 0.60, 1.0), pants := Color(0.15, 0.25, 0.55), hat: int = 0) -> ImageTexture:
	_aa = true
	var img = _new_img(64, 64)
	var skin := Color(0.95, 0.75, 0.55)
	var hair := Color(0.45, 0.25, 0.10)
	var gun := Color(0.25, 0.25, 0.30)

	# Schatten
	_ellipse(img, 32, 54, 18, 5, SHADOW, true)
	# Beine
	_outlined_ellipse(img, 26, 46, 4, 8, pants, 2)
	_outlined_ellipse(img, 38, 46, 4, 8, pants, 2)
	# Gewehrlauf nach rechts
	_rect(img, 40, 28, 20, 8, OUTLINE)
	_rect(img, 41, 29, 18, 6, gun)
	_rect(img, 55, 27, 5, 10, OUTLINE)
	_rect(img, 56, 28, 3, 8, gun)
	# Oberkörper
	_outlined_ellipse(img, 32, 36, 12, 14, shirt, 3)
	# Gürtel
	_rect(img, 21, 44, 22, 3, Color(0.35, 0.22, 0.10))
	# Arme
	_outlined_disc(img, 20, 34, 5, skin, 2)
	_outlined_disc(img, 44, 32, 5, skin, 2)
	# Kopf: Haut + Haar-Deckel (Top-Down), Gesicht nach rechts
	_outlined_disc(img, 32, 22, 9, skin, 2)
	_disc(img, 32, 20, 9, hair)
	_ellipse(img, 36, 25, 5, 4, skin)
	# Augenpunkte
	_px(img, 37, 24, OUTLINE)
	_px(img, 40, 24, OUTLINE)
	# --- Hüte: sitzen AUF dem Kopf, Gesicht + Augen (y=24) bleiben frei ---
	_draw_hat(img, hat)
	_aa = false
	return ImageTexture.create_from_image(img)


# ============================================================
# Runde 38: NEUE CHARACTER-RIGS (Helden-Overlays)
# ============================================================

func _make_force_field() -> ImageTexture:
	# Runde 39: sichtbares Hexagon-Kraftfeld
	var img = _new_img(256, 256)
	var line_c := Color(0.45, 0.85, 1.0, 0.85)
	var fill_c := Color(0.30, 0.60, 1.0, 0.16)
	var pts: Array = []
	for i in range(6):
		var a: float = PI / 6.0 + float(i) * TAU / 6.0
		pts.append(Vector2(128.0 + cos(a) * 120.0, 128.0 + sin(a) * 120.0))
	for i in range(6):
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % 6]
		_tri(img, p1, p2, Vector2(128, 128), fill_c)
	# Hexagon-Ringe + Ecken
	for ring in [1.0, 0.72, 0.44]:
		var rpts: Array = []
		for i in range(6):
			var a2: float = PI / 6.0 + float(i) * TAU / 6.0
			rpts.append(Vector2(128.0 + cos(a2) * 120.0 * ring, 128.0 + sin(a2) * 120.0 * ring))
		for i in range(6):
			var q1: Vector2 = rpts[i]
			var q2: Vector2 = rpts[(i + 1) % 6]
			_tri(img, q1, q2, Vector2(128, 128), Color(0, 0, 0, 0))
		_rect(img, int(rpts[0].x) - 2, int(rpts[0].y) - 2, 4, 4, line_c)
		_rect(img, int(rpts[2].x) - 2, int(rpts[2].y) - 2, 4, 4, line_c)
		_rect(img, int(rpts[4].x) - 2, int(rpts[4].y) - 2, 4, 4, line_c)
	return ImageTexture.create_from_image(img)

func _draw_ring(img, cx: float, cy: float, rx: float, ry: float, col: Color, width: float) -> void:
	# Einfacher Ring aus vielen kleinen Punkten (fuer Halo)
	var steps := 40
	for i in range(steps):
		var a: float = TAU * float(i) / float(steps)
		var px: float = cx + cos(a) * rx
		var py: float = cy + sin(a) * ry
		_disc(img, px, py, width, col, true)


func _draw_hat(img, hat: int) -> void:
	# Runde 98: Halo, Antenne, Kroenchen zuerst - eigene Motive, kein
	# Durchlauf durch die alten case-Zweige.
	if hat == 10:
		_draw_ring(img, 32.0, 6.0, 11.0, 4.5, Color(1.0, 0.88, 0.35), 2.2)
		_draw_ring(img, 32.0, 6.0, 11.0, 4.5, Color(1.0, 0.97, 0.70), 1.2)
		return
	if hat == 11:
		_thick_line(img, Vector2(28, 20), Vector2(26, 7), 2.0, OUTLINE)
		_thick_line(img, Vector2(36, 20), Vector2(38, 7), 2.0, OUTLINE)
		_disc(img, 26, 6, 2.4, OUTLINE, true)
		_disc(img, 38, 6, 2.4, OUTLINE, true)
		_disc(img, 26, 6, 1.6, Color(1.0, 0.45, 0.35), true)
		_disc(img, 38, 6, 1.6, Color(0.45, 1.0, 0.55), true)
		return
	if hat == 12:
		_rect(img, 21, 10, 22, 7, OUTLINE)
		_rect(img, 22, 11, 20, 5, Color(0.99, 0.84, 0.26))
		_tri(img, Vector2(24, 11), Vector2(27, 4), Vector2(30, 11), OUTLINE)
		_tri(img, Vector2(31, 11), Vector2(34, 3), Vector2(37, 11), OUTLINE)
		_tri(img, Vector2(24, 11), Vector2(27, 5), Vector2(30, 11), Color(1.0, 0.92, 0.45))
		_tri(img, Vector2(31, 11), Vector2(34, 4), Vector2(37, 11), Color(1.0, 0.92, 0.45))
		return

	# Runde 48: Hut-Overlay - wird fuer Base-Skin UND alle Skins benutzt
	match hat:
		1:
			# Kappe: Kuppel + Schirm nach rechts + Knopf
			_disc(img, 32, 14, 9, OUTLINE)
			_disc(img, 32, 14, 7, Color(0.90, 0.20, 0.20))
			_rect(img, 37, 15, 12, 5, OUTLINE)
			_rect(img, 38, 16, 10, 3, Color(0.74, 0.14, 0.14))
			_disc(img, 32, 6, 2, Color(0.74, 0.14, 0.14))
		2:
			# Cowboyhut: breite Krempe + Krone + Band
			_ellipse(img, 32, 17, 17, 5, OUTLINE)
			_ellipse(img, 32, 17, 15, 3, Color(0.55, 0.38, 0.18))
			_ellipse(img, 32, 12, 9, 6, OUTLINE)
			_ellipse(img, 32, 12, 7, 4, Color(0.70, 0.50, 0.25))
			_rect(img, 26, 14, 12, 2, Color(0.35, 0.22, 0.10))
		3:
			# Krone
			_rect(img, 24, 11, 16, 7, OUTLINE)
			_rect(img, 25, 12, 14, 5, Color(0.98, 0.82, 0.20))
			_tri(img, Vector2(25, 12), Vector2(28, 4), Vector2(31, 12), Color(0.98, 0.82, 0.20))
			_tri(img, Vector2(31, 12), Vector2(34, 3), Vector2(37, 12), Color(0.98, 0.82, 0.20))
			_tri(img, Vector2(36, 12), Vector2(39, 5), Vector2(40, 12), Color(0.98, 0.82, 0.20))
			_disc(img, 34, 14, 1, Color(0.85, 0.20, 0.30))
		4:
			# Zylinder + rotes Band
			_ellipse(img, 32, 17, 13, 4, OUTLINE)
			_ellipse(img, 32, 17, 11, 2, Color(0.12, 0.12, 0.16))
			_rect(img, 25, 4, 14, 15, OUTLINE)
			_rect(img, 26, 5, 12, 13, Color(0.12, 0.12, 0.16))
			_rect(img, 26, 15, 12, 3, Color(0.85, 0.15, 0.20))
		5:
			# Wollmütze: Kuppel + Rippen + Bommel
			_disc(img, 32, 14, 9, OUTLINE)
			_disc(img, 32, 14, 7, Color(0.30, 0.62, 0.95))
			_rect(img, 27, 8, 2, 11, Color(0.22, 0.50, 0.80))
			_rect(img, 32, 7, 2, 12, Color(0.22, 0.50, 0.80))
			_rect(img, 36, 9, 2, 10, Color(0.22, 0.50, 0.80))
			_disc(img, 32, 5, 4, OUTLINE)
			_disc(img, 32, 5, 3, Color(0.96, 0.96, 0.99))
		6:
			# Piratenhut: Dreispitz + weisse Knoepfe
			_tri(img, Vector2(32.0, 4.0), Vector2(50.0, 16.0), Vector2(32.0, 12.0), OUTLINE)
			_tri(img, Vector2(32.0, 6.0), Vector2(46.0, 15.0), Vector2(32.0, 13.0), Color(0.18, 0.18, 0.22))
			_tri(img, Vector2(32.0, 4.0), Vector2(14.0, 16.0), Vector2(32.0, 12.0), OUTLINE)
			_tri(img, Vector2(32.0, 6.0), Vector2(18.0, 15.0), Vector2(32.0, 13.0), Color(0.18, 0.18, 0.22))
			_disc(img, 32, 8, 2, Color(0.95, 0.95, 0.98))
		7:
			# Stroempf: runder Hut + Bündel + Kante
			_ellipse(img, 32, 12, 9, 8, OUTLINE)
			_ellipse(img, 32, 12, 7, 6, Color(0.90, 0.35, 0.30))
			_rect(img, 23, 14, 18, 4, OUTLINE)
			_rect(img, 24, 15, 16, 2, Color(0.80, 0.28, 0.24))
			_disc(img, 32, 4, 3, Color(0.95, 0.95, 0.98))
		8:
			# Viking: Eisenhelm + Hoerner + Nieten
			_ellipse(img, 32, 13, 9, 7, OUTLINE)
			_ellipse(img, 32, 13, 7, 5, Color(0.62, 0.66, 0.74))
			_tri(img, Vector2(24.0, 12.0), Vector2(12.0, 6.0), Vector2(24.0, 4.0), Color(0.92, 0.90, 0.82))
			_tri(img, Vector2(40.0, 12.0), Vector2(52.0, 6.0), Vector2(40.0, 4.0), Color(0.92, 0.90, 0.82))
			_rect(img, 28, 12, 9, 3, Color(0.30, 0.32, 0.38))
		9:
			# Stern: goldene Krone mit Stern in der Mitte
			_tri(img, Vector2(22.0, 14.0), Vector2(26.0, 4.0), Vector2(30.0, 14.0), Color(1.0, 0.82, 0.25))
			_tri(img, Vector2(34.0, 14.0), Vector2(38.0, 4.0), Vector2(42.0, 14.0), Color(1.0, 0.82, 0.25))
			_rect(img, 21, 13, 22, 4, OUTLINE)
			_rect(img, 22, 14, 20, 2, Color(1.0, 0.82, 0.25))
			_tri(img, Vector2(32.0, 2.0), Vector2(35.0, 9.0), Vector2(29.0, 9.0), Color(1.0, 0.94, 0.55))
func _make_player_rig(idx: int, shirt: Color = Color(0.20, 0.60, 1.0), pants: Color = Color(0.15, 0.25, 0.55), hat: int = -1) -> ImageTexture:
	# Runde 42: SKINS sind komplette Charakter-Looks UND nehmen die gewaehlte
	# Spielerfarbe an - Farbe x Haut x Skin sind frei kombinierbar.
	# Runde 48: optionaler Hut obendrauf (hat < 0 = kein Hut)
	_aa = true
	var img = _new_img(64, 64)
	var skin := Color(0.95, 0.75, 0.55)
	var hair := Color(0.45, 0.25, 0.10)
	var gun := Color(0.25, 0.25, 0.30)
	match idx:
		1:
			# PANZERHELD: Panzerung in der Spielerfarbe, Helm mit Visier
			var armor := shirt.lerp(Color(0.45, 0.50, 0.60), 0.55)
			var armor_dark := armor.darkened(0.30)
			_outlined_ellipse(img, 32, 36, 15, 14, armor, 3)
			_outlined_ellipse(img, 17, 30, 7, 9, armor_dark, 3)
			_outlined_ellipse(img, 47, 30, 7, 9, armor_dark, 3)
			_outlined_disc(img, 32, 21, 11, armor_dark, 3)
			_rect(img, 23, 18, 18, 6, Color(0.12, 0.16, 0.24))
			_disc(img, 27, 21, 2, Color(1.0, 0.86, 0.30))
			_disc(img, 37, 21, 2, Color(1.0, 0.86, 0.30))
			_disc(img, 32, 36, 4, Color(1.0, 0.82, 0.22))
			_outlined_ellipse(img, 26, 47, 4, 8, pants, 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants, 2)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		2:
			# NINJA: dunkle Stoffe, Schal in der Spielerfarbe
			var ninja := shirt.darkened(0.62)
			_outlined_ellipse(img, 32, 36, 12, 14, ninja, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, pants.darkened(0.5), 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants.darkened(0.5), 2)
			_outlined_disc(img, 32, 22, 11, Color(0.18, 0.20, 0.28), 3)
			_rect(img, 22, 21, 20, 5, Color(0.92, 0.92, 0.96))
			_disc(img, 27, 14, 2, Color(0.10, 0.11, 0.16))
			_disc(img, 37, 14, 2, Color(0.10, 0.11, 0.16))
			_tri(img, Vector2(48.0, 26.0), Vector2(61.0, 42.0), Vector2(46.0, 33.0), shirt)
			_rect(img, 14, 30, 36, 6, shirt)
			_rect(img, 40, 30, 20, 4, OUTLINE)
			_rect(img, 41, 31, 18, 2, Color(0.82, 0.86, 0.92))
		3:
			# ROBOTER: Metall mit Leuchtkern in der Spielerfarbe
			var metal := Color(0.68, 0.72, 0.80).lerp(shirt, 0.28)
			_outlined_ellipse(img, 32, 36, 13, 14, metal, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, pants.lerp(metal, 0.4), 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants.lerp(metal, 0.4), 2)
			_outlined_disc(img, 32, 21, 12, metal.lightened(0.12), 3)
			_rect(img, 24, 18, 16, 6, shirt)
			_rect(img, 31, 3, 3, 9, Color(0.45, 0.50, 0.60))
			_disc(img, 32, 3, 4, shirt.lightened(0.3))
			_disc(img, 32, 36, 6, shirt.lightened(0.25))
			_disc(img, 30, 34, 2, Color(1, 1, 1))
			_outlined_ellipse(img, 20, 32, 5, 8, metal.darkened(0.15), 3)
			_outlined_ellipse(img, 44, 32, 5, 8, metal.darkened(0.15), 3)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		6:
			# GEIST: schwebendes Laken, keine Beine, leuchtende Augen.
			# Farbe des Spielers faerbt das Laken ein.
			var sheet := shirt.lerp(Color(0.88, 0.94, 1.0), 0.55)
			# welliger Saum unten
			for k in range(4):
				_outlined_disc(img, 24 + k * 5, 50, 4, sheet, 2)
			_outlined_ellipse(img, 32, 33, 15, 17, sheet, 3)
			_outlined_ellipse(img, 32, 27, 12, 11, sheet.lightened(0.06), 2)
			# Kapuze / Gesichtsöffnung
			_outlined_ellipse(img, 33, 26, 8, 9, Color(0.10, 0.10, 0.16), 2)
			_disc(img, 30, 25, 2.0, Color(0.55, 0.90, 1.0), true)
			_disc(img, 37, 25, 2.0, Color(0.55, 0.90, 1.0), true)
			# Arme als Zipfel
			_outlined_disc(img, 43, 36, 4, sheet, 2)
			_outlined_disc(img, 21, 36, 4, sheet, 2)
		7:
			# WIKINGER: breiter Koerper, Fellkragen, Helm mit Hoernern, Bart.
			var fur := shirt.lerp(Color(0.55, 0.42, 0.30), 0.35)
			_outlined_ellipse(img, 32, 38, 14, 13, shirt, 3)
			_outlined_ellipse(img, 32, 33, 16, 7, fur, 3)          # Fellkragen
			_outlined_ellipse(img, 26, 48, 5, 8, pants.darkened(0.2), 2)
			_outlined_ellipse(img, 38, 48, 5, 8, pants.darkened(0.2), 2)
			_outlined_disc(img, 32, 22, 11, Color(0.86, 0.70, 0.55), 3)
			# Bart
			_tri(img, Vector2(24, 24), Vector2(32, 40), Vector2(40, 24), Color(0.62, 0.30, 0.14))
			_disc(img, 28, 22, 1.6, OUTLINE, true)
			_disc(img, 36, 22, 1.6, OUTLINE, true)
			# Helm + Hoerner
			_outlined_disc(img, 32, 16, 11, Color(0.55, 0.58, 0.64), 3)
			_rect(img, 21, 15, 22, 4, Color(0.42, 0.45, 0.52))
			_tri(img, Vector2(23, 12), Vector2(15, 4), Vector2(24, 8), Color(0.94, 0.92, 0.86))
			_tri(img, Vector2(41, 12), Vector2(49, 4), Vector2(40, 8), Color(0.94, 0.92, 0.86))
			_rect(img, 40, 30, 20, 8, OUTLINE)
			_rect(img, 41, 31, 18, 6, Color(0.42, 0.30, 0.18))
		8:
			# ALIEN: grosser dreieckiger Kopf, drei Augen, Tentakel.
			var skin8 := Color(0.46, 0.82, 0.42).lerp(shirt, 0.25)
			# Tentakel statt Beine
			_thick_line(img, Vector2(27, 44), Vector2(22, 55), 3.0, OUTLINE)
			_thick_line(img, Vector2(32, 44), Vector2(32, 56), 3.0, OUTLINE)
			_thick_line(img, Vector2(37, 44), Vector2(42, 55), 3.0, OUTLINE)
			_outlined_ellipse(img, 32, 38, 12, 11, skin8.darkened(0.12), 3)
			# Kopf: breite Ellipse, nach unten schmaler
			_outlined_ellipse(img, 32, 24, 15, 13, skin8, 3)
			_tri(img, Vector2(18, 26), Vector2(46, 26), Vector2(32, 12), skin8)
			# drei Augen
			_disc(img, 25, 22, 3.2, Color(0.06, 0.05, 0.10), true)
			_disc(img, 32, 20, 3.6, Color(0.06, 0.05, 0.10), true)
			_disc(img, 39, 22, 3.2, Color(0.06, 0.05, 0.10), true)
			_disc(img, 32, 20, 1.6, Color(0.95, 0.95, 0.35), true)
			_rect(img, 40, 30, 20, 8, OUTLINE)
			_rect(img, 41, 31, 18, 6, Color(0.30, 0.34, 0.30))
		4:
			# COMIC-HELD: Umhang + Muskel in der Spielerfarbe
			_tri(img, Vector2(20.0, 26.0), Vector2(44.0, 26.0), Vector2(40.0, 50.0), shirt.darkened(0.22))
			_tri(img, Vector2(44.0, 26.0), Vector2(20.0, 26.0), Vector2(24.0, 50.0), shirt.darkened(0.22))
			_outlined_ellipse(img, 32, 36, 13, 13, shirt, 3)
			_disc(img, 32, 34, 4, Color(1.0, 0.88, 0.25))
			_outlined_ellipse(img, 26, 47, 4, 8, pants, 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants, 2)
			_outlined_disc(img, 32, 22, 10, skin, 3)
			_ellipse(img, 32, 16, 11, 6, Color(0.95, 0.78, 0.28), true)
			_px(img, 36, 23, OUTLINE)
			_px(img, 40, 23, OUTLINE)
			_rect(img, 34, 27, 7, 2, OUTLINE)
			_outlined_ellipse(img, 19, 32, 4, 7, skin, 2)
			_outlined_ellipse(img, 45, 32, 4, 7, skin, 2)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		5:
			# MARS-MARSCHALL: weisser Anzug mit Farbakzenten
			var suit := Color(0.90, 0.92, 0.96)
			_outlined_ellipse(img, 32, 36, 13, 14, suit, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, suit.darkened(0.16), 2)
			_outlined_ellipse(img, 38, 47, 4, 8, suit.darkened(0.16), 2)
			_outlined_disc(img, 32, 21, 12, suit, 3)
			_ellipse(img, 35, 22, 8, 6, Color(0.35, 0.72, 0.88), true)
			_px(img, 33, 22, Color(1, 1, 1, 0.85))
			_rect(img, 31, 5, 3, 8, Color(0.60, 0.64, 0.72))
			_disc(img, 32, 5, 3, shirt)
			_rect(img, 16, 26, 7, 16, OUTLINE)
			_rect(img, 17, 27, 5, 14, Color(0.55, 0.80, 0.92))
			_rect(img, 26, 30, 12, 3, shirt)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
		_:
			_outlined_ellipse(img, 32, 36, 12, 14, shirt, 3)
			_outlined_ellipse(img, 26, 47, 4, 8, pants, 2)
			_outlined_ellipse(img, 38, 47, 4, 8, pants, 2)
			_outlined_disc(img, 32, 22, 10, skin, 3)
			_ellipse(img, 32, 16, 11, 6, hair, true)
			_px(img, 36, 23, OUTLINE)
			_px(img, 40, 23, OUTLINE)
			_rect(img, 40, 28, 20, 8, OUTLINE)
			_rect(img, 41, 29, 18, 6, gun)
			_rect(img, 55, 27, 5, 10, OUTLINE)
			_rect(img, 56, 28, 3, 8, gun)
	# Runde 48: Hut auf den Skin zeichnen
	if hat >= 0:
		_draw_hat(img, hat)
	_aa = false
	return ImageTexture.create_from_image(img)


const COLOR_NAMES := ["BLAU", "ROT", "GRUEN", "GELB", "LILA", "WEISS", "ORANGE", "CYAN", "ROSA", "STAHL"]
# Runde 38: Character-Rigs (Helden-Overlays)
# Runde 40/42: RIGS = echte SKINS (kompletter Charakter-Look, farbbar)
const RIG_NAMES := ["STANDARD", "PANZERHELD", "NINJA", "ROBOTER", "COMIC-HELD", "MARS-MARSCHALL", "GEIST", "WIKINGER", "ALIEN"]
const HAT_NAMES := ["OHNE", "KAPPE", "COWBOY", "KRONE", "ZYLINDER", "WOLLMÜTZE", "PIRAT", "STROHHUT", "WIKINGER", "STERN", "HALO", "ANTENNE", "KRÖNCHEN"]

const PLAYER_COLORS := [
	{ "shirt": Color(0.20, 0.60, 1.00), "pants": Color(0.15, 0.25, 0.55) },
	{ "shirt": Color(0.90, 0.24, 0.22), "pants": Color(0.45, 0.13, 0.13) },
	{ "shirt": Color(0.28, 0.78, 0.32), "pants": Color(0.13, 0.34, 0.16) },
	{ "shirt": Color(0.98, 0.82, 0.18), "pants": Color(0.50, 0.38, 0.10) },
	{ "shirt": Color(0.68, 0.30, 0.92), "pants": Color(0.30, 0.13, 0.46) },
	{ "shirt": Color(0.94, 0.94, 0.96), "pants": Color(0.42, 0.44, 0.50) },
	{ "shirt": Color(0.98, 0.52, 0.14), "pants": Color(0.46, 0.22, 0.08) },
	{ "shirt": Color(0.20, 0.84, 0.88), "pants": Color(0.10, 0.36, 0.40) },
	{ "shirt": Color(0.98, 0.42, 0.72), "pants": Color(0.46, 0.16, 0.30) },
	{ "shirt": Color(0.58, 0.64, 0.72), "pants": Color(0.26, 0.30, 0.36) }
]


func _make_hat_icon(idx: int, size: int) -> ImageTexture:
	# Runde 97: Hut-Motive eigenstaendig in 128 px (statt Ausschnitt aus der
	# Figur). Reihenfolge entspricht _draw_hat().
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var cx := f * 0.5
	var base := f * 0.72          # Unterkante des Hutes
	# Zuordnung der gezeichneten Motive zur echten Hut-Reihenfolge aus _draw_hat():
	# 0 Kappe, 1 Cowboy, 2 Krone, 3 Zylinder, 4 Wollmuetze, 5 Pirat,
	# 6 Strohhut, 7 Wikinger, 8 Stern
	var map := [0, 4, 2, 1, 5, 7, 4, 3, 8, 9, 10, 11]
	var style: int = int(map[idx]) if idx >= 0 and idx < map.size() else 0
	match style:
		0:  # Kappe
			_ellipse(img, int(cx), int(base - f * 0.10), int(f * 0.30), int(f * 0.20), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.12), int(f * 0.27), int(f * 0.17), Color(0.82, 0.18, 0.20))
			_rect(img, int(cx - f * 0.34), int(base - f * 0.04), int(f * 0.68), int(f * 0.08), OUTLINE)
			_rect(img, int(cx - f * 0.32), int(base - f * 0.03), int(f * 0.64), int(f * 0.05), Color(0.68, 0.12, 0.14))
		1:  # Zylinder
			_rect(img, int(cx - f * 0.18), int(base - f * 0.46), int(f * 0.36), int(f * 0.40), OUTLINE)
			_rect(img, int(cx - f * 0.15), int(base - f * 0.44), int(f * 0.30), int(f * 0.38), Color(0.16, 0.16, 0.20))
			_rect(img, int(cx - f * 0.15), int(base - f * 0.16), int(f * 0.30), int(f * 0.08), Color(0.72, 0.16, 0.18))
			_rect(img, int(cx - f * 0.36), int(base - f * 0.08), int(f * 0.72), int(f * 0.10), OUTLINE)
			_rect(img, int(cx - f * 0.34), int(base - f * 0.07), int(f * 0.68), int(f * 0.06), Color(0.22, 0.22, 0.26))
		2:  # Krone
			_rect(img, int(cx - f * 0.30), int(base - f * 0.26), int(f * 0.60), int(f * 0.22), OUTLINE)
			_rect(img, int(cx - f * 0.27), int(base - f * 0.24), int(f * 0.54), int(f * 0.18), Color(0.96, 0.80, 0.20))
			for i in range(3):
				var px: float = cx + (float(i) - 1.0) * f * 0.20
				_tri(img, Vector2(px, base - f * 0.56), Vector2(px + f * 0.09, base - f * 0.26), Vector2(px - f * 0.09, base - f * 0.26), OUTLINE)
				_tri(img, Vector2(px, base - f * 0.52), Vector2(px + f * 0.06, base - f * 0.27), Vector2(px - f * 0.06, base - f * 0.27), Color(0.99, 0.86, 0.30))
		3:  # Wikinger
			_ellipse(img, int(cx), int(base - f * 0.22), int(f * 0.28), int(f * 0.20), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.23), int(f * 0.25), int(f * 0.17), Color(0.62, 0.64, 0.70))
			_tri(img, Vector2(cx - f * 0.26, base - f * 0.28), Vector2(cx - f * 0.52, base - f * 0.52), Vector2(cx - f * 0.30, base - f * 0.10), OUTLINE)
			_tri(img, Vector2(cx + f * 0.26, base - f * 0.28), Vector2(cx + f * 0.52, base - f * 0.52), Vector2(cx + f * 0.30, base - f * 0.10), OUTLINE)
			_tri(img, Vector2(cx - f * 0.29, base - f * 0.29), Vector2(cx - f * 0.46, base - f * 0.46), Vector2(cx - f * 0.31, base - f * 0.15), Color(0.94, 0.92, 0.86))
			_tri(img, Vector2(cx + f * 0.29, base - f * 0.29), Vector2(cx + f * 0.46, base - f * 0.46), Vector2(cx + f * 0.31, base - f * 0.15), Color(0.94, 0.92, 0.86))
		4:  # Cowboy
			_ellipse(img, int(cx), int(base - f * 0.10), int(f * 0.44), int(f * 0.12), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.11), int(f * 0.41), int(f * 0.09), Color(0.62, 0.44, 0.22))
			_ellipse(img, int(cx), int(base - f * 0.26), int(f * 0.24), int(f * 0.16), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.27), int(f * 0.21), int(f * 0.13), Color(0.72, 0.52, 0.26))
		5:  # Helm
			_ellipse(img, int(cx), int(base - f * 0.20), int(f * 0.30), int(f * 0.24), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.21), int(f * 0.27), int(f * 0.21), Color(0.34, 0.52, 0.34))
			_rect(img, int(cx - f * 0.03), int(base - f * 0.30), int(f * 0.06), int(f * 0.26), Color(0.90, 0.92, 0.94))
		6:  # Zauberer
			_tri(img, Vector2(cx, base - f * 0.72), Vector2(cx + f * 0.30, base - f * 0.08), Vector2(cx - f * 0.30, base - f * 0.08), OUTLINE)
			_tri(img, Vector2(cx, base - f * 0.66), Vector2(cx + f * 0.25, base - f * 0.11), Vector2(cx - f * 0.25, base - f * 0.11), Color(0.34, 0.26, 0.62))
			_ellipse(img, int(cx), int(base - f * 0.08), int(f * 0.34), int(f * 0.08), Color(0.34, 0.26, 0.62))
			_disc(img, cx + f * 0.12, base - f * 0.42, f * 0.03, Color(1.0, 0.90, 0.40), true)
		7:  # Pirat
			_ellipse(img, int(cx), int(base - f * 0.14), int(f * 0.24), int(f * 0.18), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.15), int(f * 0.21), int(f * 0.15), Color(0.20, 0.20, 0.24))
			_ellipse(img, int(cx), int(base - f * 0.06), int(f * 0.36), int(f * 0.08), Color(0.20, 0.20, 0.24))
			_disc(img, cx, base - f * 0.20, f * 0.05, Color(0.95, 0.95, 0.90), true)
		9:  # Halo (Engelsschein)
			var halo := Color(1.0, 0.88, 0.35)
			_ellipse(img, int(cx), int(base - f * 0.40), int(f * 0.26), int(f * 0.11), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.40), int(f * 0.22), int(f * 0.08), Color(0, 0, 0, 0))
			_draw_ring(img, cx, base - f * 0.40, f * 0.24, f * 0.09, halo, f * 0.045)
			_disc(img, cx - f * 0.22, base - f * 0.48, f * 0.03, Color(1, 1, 0.85, 0.9), true)
		10:  # Antenne
			for sgn in [-1.0, 1.0]:
				var ax: float = cx + sgn * f * 0.13
				_thick_line(img, Vector2(ax, base - f * 0.16), Vector2(ax + sgn * f * 0.06, base - f * 0.56), 4.0, OUTLINE)
				_thick_line(img, Vector2(ax, base - f * 0.16), Vector2(ax + sgn * f * 0.06, base - f * 0.56), 2.0, Color(0.55, 0.60, 0.68))
				_disc(img, ax + sgn * f * 0.06, base - f * 0.58, f * 0.05, OUTLINE, true)
				_disc(img, ax + sgn * f * 0.06, base - f * 0.58, f * 0.035, Color(1.0, 0.45, 0.35) if sgn < 0 else Color(0.45, 1.0, 0.55), true)
		11:  # Kroenchen
			_rect(img, int(cx - f * 0.24), int(base - f * 0.22), int(f * 0.48), int(f * 0.18), OUTLINE)
			_rect(img, int(cx - f * 0.21), int(base - f * 0.20), int(f * 0.42), int(f * 0.14), Color(0.99, 0.84, 0.26))
			for i in range(3):
				var px3: float = cx + (float(i) - 1.0) * f * 0.15
				_tri(img, Vector2(px3, base - f * 0.44), Vector2(px3 + f * 0.07, base - f * 0.22), Vector2(px3 - f * 0.07, base - f * 0.22), OUTLINE)
				_tri(img, Vector2(px3, base - f * 0.40), Vector2(px3 + f * 0.045, base - f * 0.23), Vector2(px3 - f * 0.045, base - f * 0.23), Color(1.0, 0.92, 0.45))
		8:  # Stern-Krone
			_rect(img, int(cx - f * 0.26), int(base - f * 0.22), int(f * 0.52), int(f * 0.16), OUTLINE)
			_rect(img, int(cx - f * 0.23), int(base - f * 0.20), int(f * 0.46), int(f * 0.12), Color(0.99, 0.84, 0.24))
			for i in range(5):
				var a: float = -PI * 0.5 + float(i) * TAU / 5.0
				var px2: float = cx + cos(a) * f * 0.16
				var py2: float = base - f * 0.34 + sin(a) * f * 0.16
				_disc(img, px2, py2, f * 0.055, Color(1.0, 0.94, 0.55), true)
		_:
			_ellipse(img, int(cx), int(base - f * 0.18), int(f * 0.28), int(f * 0.18), OUTLINE)
			_ellipse(img, int(cx), int(base - f * 0.19), int(f * 0.25), int(f * 0.15), Color(0.70, 0.28, 0.72))
	_aa = false
	return ImageTexture.create_from_image(img)


func get_hat_only_texture(idx: int) -> Texture2D:
	# Runde 96: Nur der Hut, ohne Figur - fuer die Gewinner-Kachel.
	# Wird einmal gezeichnet und dann aus dem Cache geliefert.
	var key := "hat_only_%d" % idx
	if textures.has(key):
		return textures[key]
	textures[key] = _make_hat_icon(idx, 128)
	var img = textures[key].get_image()
	print("[HAT][TEX] Hut %d gezeichnet (%dx%d)" % [idx, img.get_width(), img.get_height()])
	return textures[key]


func get_skin_texture(color_idx: int, skin_idx: int) -> Texture2D:
	# Runde 42: Skin x Farbe - der Skin nimmt die Spielerfarbe an.
	var key := "skin_c%d_s%d" % [color_idx, skin_idx]
	if textures.has(key):
		return textures[key]
	var ci := clampi(color_idx, 0, PLAYER_COLORS.size() - 1)
	var c: Dictionary = PLAYER_COLORS[ci]
	var tex := _make_player_rig(clampi(skin_idx, 0, RIG_NAMES.size() - 1), c["shirt"], c["pants"])
	textures[key] = tex
	return tex

func get_skin_hat_texture(color_idx: int, skin_idx: int, hat_idx: int) -> Texture2D:
	# Runde 48: SKIN + FARBE + HUT in einem Bild.
	# Vorher konnte man nur Base-Skin mit Hut kombinieren - die
	# Hut-Auswahl im Charakterfenster zeigte darum immer das Base-Skin.
	var key := "skinh_c%d_s%d_h%d" % [color_idx, skin_idx, hat_idx]
	if textures.has(key):
		return textures[key]
	var ci := clampi(color_idx, 0, PLAYER_COLORS.size() - 1)
	var c: Dictionary = PLAYER_COLORS[ci]
	var si := clampi(skin_idx, 0, RIG_NAMES.size() - 1)
	var hi := clampi(hat_idx, 0, HAT_NAMES.size() - 1)
	var tex: ImageTexture
	if si <= 0:
		# Base-Skin: der normale Spieler mit Hut
		tex = _make_player(c["shirt"], c["pants"], hi)
	else:
		tex = _make_player_rig(si, c["shirt"], c["pants"], hi)
	textures[key] = tex
	return tex


func get_skin_hat_texture_or_player(color_idx: int, skin_idx: int, hat_idx: int) -> Texture2D:
	# Runde 48: wie get_skin_hat_texture, faellt aber zurueck, falls die
	# Kombination nicht erzeugt werden kann.
	var t = get_skin_hat_texture(color_idx, skin_idx, hat_idx)
	if t == null:
		t = get_player_texture(color_idx, hat_idx)
	return t


func get_player_texture(color_idx: int, hat_idx: int) -> ImageTexture:
	var key := "player_c%d_h%d" % [color_idx, hat_idx]
	if textures.has(key):
		return textures[key]
	var ci := clampi(color_idx, 0, PLAYER_COLORS.size() - 1)
	var c: Dictionary = PLAYER_COLORS[ci]
	var tex := _make_player(c["shirt"], c["pants"], clampi(hat_idx, 0, HAT_NAMES.size() - 1))
	textures[key] = tex
	return tex

func _make_crosshair_icon() -> ImageTexture:
	# Runde 43: Pixel-Art-Fadenkreuz (16x16, 4x NEAREST) - einheitlich mit
	# der Muenze und den uebrigen Item-Icons.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.32, 0.10, 0.08)
	var mid := Color(1.0, 0.38, 0.28)
	var light := Color(1.0, 0.68, 0.52)
	# Ring (Pixelkreis) + Kreuzstifte
	for y in range(px):
		for x in range(px):
			var dx: float = float(x) - 7.5
			var dy: float = float(y) - 7.5
			var d: float = sqrt(dx * dx + dy * dy)
			if d >= 3.6 and d <= 6.4:
				small.set_pixel(x, y, mid)
	for i in range(4):
		var o: int = 7 - i
		small.set_pixel(7, o, mid)
		small.set_pixel(8, o, mid)
		small.set_pixel(o, 7, mid)
		small.set_pixel(o, 8, mid)
	# Innerer Ring hell
	for y in range(px):
		for x in range(px):
			var dx2: float = float(x) - 7.5
			var dy2: float = float(y) - 7.5
			var d2: float = sqrt(dx2 * dx2 + dy2 * dy2)
			if d2 >= 4.6 and d2 <= 5.4:
				small.set_pixel(x, y, light)
	# Mitte dunkel + Kern
	small.set_pixel(7, 7, edge)
	small.set_pixel(8, 7, edge)
	small.set_pixel(7, 8, edge)
	small.set_pixel(8, 8, edge)
	# Kontur nachziehen
	for y in range(px):
		for x in range(px):
			if small.get_pixel(x, y).a > 0.0:
				var up: bool = y + 1 < px and small.get_pixel(x, y + 1).a > 0.0
				var dn: bool = y - 1 >= 0 and small.get_pixel(x, y - 1).a > 0.0
				var lf: bool = x + 1 < px and small.get_pixel(x + 1, y).a > 0.0
				var rt: bool = x - 1 >= 0 and small.get_pixel(x - 1, y).a > 0.0
				if not (up and dn and lf and rt):
					small.set_pixel(x, y, edge)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


func _make_gear_icon() -> ImageTexture:
	var img = _new_img(96, 96)
	# Zahnrad: 8 Zähne + Ring + Nabe
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var c := Vector2(48, 48) + Vector2(cos(a), sin(a)) * 36.0
		_outlined_disc(img, int(c.x), int(c.y), 12, Color(0.86, 0.89, 0.96), 2)
	_outlined_disc(img, 48, 48, 30, Color(0.86, 0.89, 0.96), 3)
	_disc(img, 48, 48, 13, Color(0.30, 0.34, 0.42))
	_disc(img, 48, 48, 9, Color(0.14, 0.16, 0.22))
	return ImageTexture.create_from_image(img)

func _make_shield_icon() -> ImageTexture:
	# Runde 43: Pixel-Art-Schild (16x16, 4x NEAREST) - vorher war es ein
	# weiches Dreieck und brach die Einheitlichkeit der Icon-Reihe.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.12, 0.16, 0.26)
	var body := Color(0.36, 0.62, 0.92)
	var light := Color(0.72, 0.88, 1.0)
	# Schildform in Pixelstufen
	for y in range(3, 12):
		var w: int = 5
		if y > 6:
			w = 5 - (y - 6)
		if y >= 11:
			w = 1
		for x in range(8 - w, 8 + w):
			small.set_pixel(x, y, body)
	# Spitze
	small.set_pixel(7, 12, body)
	small.set_pixel(8, 12, body)
	small.set_pixel(7, 13, body.darkened(0.2))
	small.set_pixel(8, 13, body.darkened(0.2))
	# Innerer Rand + Glanz
	for y in range(4, 11):
		small.set_pixel(6, y, light)
	small.set_pixel(7, 4, light)
	small.set_pixel(8, 4, light)
	# Mittelstreifen
	for y in range(5, 11):
		small.set_pixel(7, y, light.darkened(0.15))
		small.set_pixel(8, y, light.darkened(0.15))
	# Kontur
	_px_outline(small, px, edge)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)



# ============================================================
# Runde 44: Navigations-Icons fuer die Startseiten-Kacheln
# ============================================================

func _make_nav_icon(kind: String) -> ImageTexture:
	# Runde 44: 16x16 Pixel-Art-Icon fuer die Startseiten-Kacheln
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var dark := Color(0.10, 0.10, 0.16)
	match kind:
		"lan":
			# Zwei Spieler + Verbindung
			_outlined_disc(small, 5, 6, 3, Color(0.95, 0.72, 0.30), 1)
			_outlined_disc(small, 11, 6, 3, Color(0.40, 0.78, 0.95), 1)
			_rect(small, 2, 10, 6, 4, dark)
			_rect(small, 8, 10, 6, 4, dark)
			_rect(small, 6, 5, 4, 1, Color(0.60, 0.95, 0.60))
		"char":
			# Heldenkopf
			_outlined_disc(small, 8, 7, 5, Color(0.95, 0.75, 0.55), 1)
			_ellipse(small, 8, 4, 5, 3, Color(0.45, 0.25, 0.10), true)
			_px(small, 6, 7, dark)
			_px(small, 10, 7, dark)
			_rect(small, 6, 10, 5, 1, dark)
			_rect(small, 4, 12, 8, 3, Color(0.30, 0.55, 0.95))
		"shop":
			# Truhe
			_rect(small, 3, 6, 10, 6, Color(0.72, 0.48, 0.22))
			_rect(small, 2, 4, 12, 3, Color(0.88, 0.62, 0.26))
			_rect(small, 6, 4, 4, 8, Color(0.55, 0.38, 0.16))
			_rect(small, 7, 7, 2, 2, Color(0.98, 0.85, 0.30))
		"coll":
			# Raster (Sammlung)
			for gy in range(3, 14, 5):
				for gx in range(3, 14, 5):
					_rect(small, gx, gy, 4, 4, Color(0.62, 0.42, 0.85))
					_rect(small, gx + 1, gy + 1, 2, 2, Color(0.85, 0.72, 0.98))
		"map":
			# Weltkarte
			_rect(small, 2, 3, 12, 10, Color(0.20, 0.56, 0.68))
			_rect(small, 4, 5, 3, 2, Color(0.60, 0.85, 0.40))
			_rect(small, 8, 8, 4, 2, Color(0.60, 0.85, 0.40))
			_rect(small, 5, 9, 2, 2, Color(0.95, 0.85, 0.35))
	_px_outline(small, px, dark)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)

func _make_coin_icon() -> ImageTexture:
	# Runde 43: Pixel-Art-Muenze im gleichen Stil wie das Herz-Asset
	# (16x16 Pixel, 4x NEAREST) - vorher war sie ein weicher Vektor-Kreis
	# und damit die hässliche Ausnahme in der Icon-Reihe.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var edge := Color(0.42, 0.28, 0.05)
	var mid := Color(0.98, 0.80, 0.18)
	var light := Color(1.0, 0.93, 0.55)
	# runde Muenze in Pixelstufen
	var rows := [
		"....XXXXXX....",
		"..XXXXXXXXXX..",
		".XXXXXXXXXXXX.",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		"XXXXXXXXXXXXXX",
		".XXXXXXXXXXXX.",
		"..XXXXXXXXXX..",
		"....XXXXXX...."
	]
	for y in range(rows.size()):
		var r: String = str(rows[y])
		for x in range(px):
			if x < r.length() and str(r[x]) == "X":
				small.set_pixel(x, 2 + y, mid)
	# Randpixel dunkel
	for y in range(2, 13):
		for x in range(px):
			if small.get_pixel(x, y).a > 0.0:
				var up_ok: bool = y + 1 < px and small.get_pixel(x, y + 1).a > 0.0
				var down_ok: bool = y - 1 >= 0 and small.get_pixel(x, y - 1).a > 0.0
				var left_ok: bool = x + 1 < px and small.get_pixel(x + 1, y).a > 0.0
				var right_ok: bool = x - 1 >= 0 and small.get_pixel(x - 1, y).a > 0.0
				if not (up_ok and down_ok and left_ok and right_ok):
					small.set_pixel(x, y, edge)
	# Praegung: heller Rand + Waehrungszeichen
	for x in range(5, 11):
		small.set_pixel(x, 4, light)
		small.set_pixel(x, 9, light)
	for y in range(5, 9):
		small.set_pixel(5, y, light)
		small.set_pixel(10, y, light)
	# kleines Zeichen in der Mitte
	small.set_pixel(7, 6, edge)
	small.set_pixel(8, 6, edge)
	small.set_pixel(8, 7, edge)
	small.set_pixel(7, 8, edge)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


func _make_chest_icon(body: Color, band: Color) -> ImageTexture:
	# Runde 43: KISTENKÖRPER in 3/4-Ansicht, Pixel-Art (24x24, 3x NEAREST).
	# Vorher war es ein flaches 16x16-Icon - der Nutzer fand die Kisten
	# "nicht special" und ohne Oeffnungs-Animation.
	var px: int = 24
	var big: int = 3
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	var dark := Color(0.09, 0.07, 0.06)
	var shade := body.darkened(0.34)
	var bshade := band.darkened(0.26)
	var highlight := body.lightened(0.22)
	# --- Korpus (3/4-Ansicht: Front + rechte Seite) ---
	# Front: x 3..16, y 12..20 ; Seite: x 16..20, y 10..18
	for y in range(12, 21):
		for x in range(3, 17):
			small.set_pixel(x, y, body if y < 18 else shade)
	for y in range(10, 19):
		for x in range(16, 21):
			small.set_pixel(x, y, shade)
	# Front-Planken
	for y in range(15, 21):
		for x in range(3, 17):
			small.set_pixel(x, y, shade if (y == 15 or y == 18) else body)
	# --- Deckel (schraeg nach hinten oben) ---
	for y in range(6, 13):
		for x in range(3, 17):
			small.set_pixel(x, y, band)
	for y in range(4, 7):
		for x in range(5, 16):
			small.set_pixel(x, y, band.lightened(0.10))
	# Deckel-Oberkante (3/4)
	for x in range(16, 21):
		for y in range(3, 11):
			small.set_pixel(x, y, bshade)
	# --- Metallbaender ---
	for y in range(6, 21):
		small.set_pixel(6, y, bshade)
		small.set_pixel(7, y, band.lightened(0.18))
		small.set_pixel(14, y, bshade)
		small.set_pixel(15, y, band.lightened(0.18))
	# Band quer ueber den Deckel
	for x in range(3, 21):
		if x < 16:
			small.set_pixel(x, 11, bshade)
		else:
			small.set_pixel(x, 9, bshade)
	# --- Schloss ---
	for y in range(10, 15):
		small.set_pixel(10, y, Color(0.98, 0.85, 0.30))
		small.set_pixel(11, y, Color(0.98, 0.85, 0.30))
	small.set_pixel(10, 12, dark)
	small.set_pixel(11, 12, dark)
	small.set_pixel(10, 13, dark)
	small.set_pixel(11, 13, dark)
	# Schloss-Rahmen
	small.set_pixel(9, 10, dark)
	small.set_pixel(12, 10, dark)
	small.set_pixel(9, 14, dark)
	small.set_pixel(12, 14, dark)
	# --- Griff oben ---
	small.set_pixel(9, 2, dark)
	small.set_pixel(10, 2, dark)
	small.set_pixel(11, 2, dark)
	small.set_pixel(12, 2, dark)
	small.set_pixel(9, 3, dark)
	small.set_pixel(12, 3, dark)
	small.set_pixel(10, 3, band.lightened(0.30))
	small.set_pixel(11, 3, band.lightened(0.30))
	# --- Niete ---
	small.set_pixel(4, 13, band.lightened(0.35))
	small.set_pixel(4, 19, band.lightened(0.30))
	small.set_pixel(13, 13, band.lightened(0.35))
	small.set_pixel(13, 19, band.lightened(0.30))
	small.set_pixel(17, 11, band.lightened(0.25))
	small.set_pixel(17, 17, band.lightened(0.22))
	# --- Glanzlicht auf dem Deckel ---
	small.set_pixel(8, 7, Color(1, 1, 1, 0.42))
	small.set_pixel(9, 7, Color(1, 1, 1, 0.28))
	small.set_pixel(12, 16, Color(1, 1, 1, 0.16))
	# Fuss
	for x in range(4, 16):
		small.set_pixel(x, 21, dark)
	# Kontur ringsum
	_px_outline(small, px, dark)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


func _make_chest_icon_rich(tier: String) -> ImageTexture:
	# Runde 49: JEDE Kiste hat eine EIGENE SILHOUETTE - nicht nur eine
	# andere Farbe. Vorher teilten sich Holz/Silber/Gold dieselbe
	# Truhenform und Platinum/Storm waren reine Farbvarianten, dadurch
	# sahen alle Kisten gleich aus.
	match tier:
		"wood":
			# HOLZTRUHE: gewölbter Deckel, Planken, Eisenbeschlag
			return _make_chest_wood_icon()
		"silver":
			# INDUSTRIE-CRATE: eckiger Koffer mit Nieten + Warnstreifen
			return _make_chest_silver_icon()
		"gold":
			# SCHATZTRUHE: hoher gewölbter Deckel, Goldschmuck, Rubin
			return _make_chest_gold_icon()
		"platinum":
			# KRISTALL-TRUHE: schlanke Truhe mit leuchtendem Spalt
			return _make_chest_platinum_icon()
		"storm":
			# STURMKISTE: flache Waffenkiste mit Stangen + Blitzzeichen
			return _make_chest_storm_icon()
	return _make_chest_wood_icon()


func _px_ell(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	# Runde 49: Ellipsen-Helfer fuer die Kisten-Formen
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx: float = float(x - cx) / float(maxi(1, rx))
			var dy: float = float(y - cy) / float(maxi(1, ry))
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)


func _px_rect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			img.set_pixel(x, y, col)


func _px_up(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	# Rechteck mit abgerundeten oberen Ecken (Truhen-Deckel)
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if y == y0 and (x == x0 or x == x0 + w - 1):
				continue
			img.set_pixel(x, y, col)


func _make_chest_platinum_icon() -> ImageTexture:
	# Runde 49: KRISTALL-TRUHE - eine schlanke, hohe Truhe mit einem
	# leuchtenden Spalt in der Mitte (darin ein Kristall). Eigenes
	# Silhouettenprofil, nicht die Standard-Truhenform.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.12, 0.10, 0.20)
	var shell := Color(0.84, 0.88, 0.96)
	var shell2 := Color(0.62, 0.66, 0.80)
	var glow := Color(0.70, 0.42, 1.0)
	var glow_l := Color(0.92, 0.76, 1.0)
	# --- Facettierter Kristall, der aus dem Deckel SPITZT ---
	# (Runde 49: vorher war es eine zusaetzliche Spitze ueber dem
	# Deckel - das las sich als Grabstein, nicht als Truhe.)
	_tri(img, Vector2(9, 8), Vector2(12, 1), Vector2(15, 8), OUTLINE)
	_tri(img, Vector2(10, 8), Vector2(12, 3), Vector2(14, 8), glow)
	_px(img, 12, 5, glow_l)
	# --- Deckel (flach, breit) ---
	_px_up(img, 6, 8, 12, 3, shell)
	_px_rect(img, 6, 10, 12, 1, shell2)
	# --- Korpus ---
	_px_rect(img, 5, 11, 14, 10, shell)
	# Seiten-Schatten
	_px_rect(img, 5, 11, 3, 10, shell2)
	_px_rect(img, 16, 11, 3, 10, shell2.darkened(0.12))
	# --- Leuchtender Spalt in der Mitte ---
	_px_rect(img, 10, 11, 4, 10, glow)
	_px_rect(img, 11, 12, 2, 8, glow_l)
	# --- Rahmenkanten ---
	_px_rect(img, 4, 11, 1, 10, dark)
	_px_rect(img, 19, 11, 1, 10, dark)
	# --- Fussleiste ---
	_px_rect(img, 4, 20, 16, 2, shell2)
	_px_rect(img, 4, 21, 16, 1, dark)
	# Glanzlichter
	img.set_pixel(7, 13, Color(1, 1, 1, 0.45))
	img.set_pixel(8, 13, Color(1, 1, 1, 0.22))
	img.set_pixel(17, 17, Color(1, 1, 1, 0.20))
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _make_chest_storm_icon() -> ImageTexture:
	# Runde 49: STURMKISTE - eine flache, breite WAFFENKISTE mit
	# Stangen oben drauf und einem Blitzzeichen auf dem Deckel.
	# Eigenes Silhouettenprofil (flach und breit statt hoch).
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.07, 0.10, 0.16)
	var steel := Color(0.26, 0.56, 0.84)
	var steel2 := Color(0.17, 0.38, 0.62)
	var steel3 := Color(0.40, 0.72, 0.98)
	var bolt := Color(0.98, 0.94, 0.42)
	# --- Stangen (Sturm-Fangzaehne) oben ---
	for x in [6, 8, 15, 17]:
		_px_rect(img, x, 2, 2, 5, steel2)
		img.set_pixel(x, 1, bolt)
	# --- Flacher Deckel ---
	_px_up(img, 2, 7, 20, 5, steel3)
	_px_rect(img, 2, 11, 20, 1, steel2)
	# --- Breiter, flacher Korpus ---
	_px_rect(img, 3, 12, 18, 8, steel)
	_px_rect(img, 3, 12, 3, 8, steel2)
	_px_rect(img, 18, 12, 3, 8, steel2.darkened(0.10))
	# --- Warnstreifen ---
	for x in range(3, 21):
		if (x + 12) % 6 < 3:
			img.set_pixel(x, 15, bolt)
	# --- Blitzzeichen auf dem Deckel ---
	var bz := [Vector2i(12, 7), Vector2i(10, 9), Vector2i(12, 9), Vector2i(10, 12)]
	for p in bz:
		img.set_pixel(p.x, p.y, bolt)
	img.set_pixel(11, 8, bolt)
	img.set_pixel(11, 10, bolt)
	# --- Schloss ---
	_px_rect(img, 10, 16, 4, 4, steel2)
	_px_rect(img, 11, 17, 2, 2, bolt)
	# --- Fuesse ---
	_px_rect(img, 3, 20, 4, 2, dark)
	_px_rect(img, 17, 20, 4, 2, dark)
	# Glanz
	img.set_pixel(5, 8, Color(1, 1, 1, 0.40))
	img.set_pixel(6, 8, Color(1, 1, 1, 0.18))
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _make_chest_wood_icon() -> ImageTexture:
	# Runde 48: Holztruhe - waermere Farbtöne als Basis, sichtbare
	# Plankenfugen, ein Eisenband und ein Wulst am Deckel.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.13, 0.08, 0.05)
	var body := Color(0.72, 0.47, 0.24)
	var body2 := Color(0.60, 0.38, 0.19)
	var body3 := Color(0.82, 0.58, 0.31)
	var iron := Color(0.36, 0.38, 0.44)
	var iron_l := Color(0.56, 0.59, 0.66)
	# --- Deckel (schraeg, gewollt) ---
	for y in range(5, 12):
		for x in range(2, 18):
			img.set_pixel(x, y, body3 if y < 8 else body)
	for y in range(3, 7):
		for x in range(4, 17):
			img.set_pixel(x, y, body3.lightened(0.10))
	# --- Korpus ---
	for y in range(12, 21):
		for x in range(2, 18):
			img.set_pixel(x, y, body if y < 18 else body2)
	# Seiten-Schatten
	for y in range(9, 19):
		for x in range(18, 22):
			img.set_pixel(x, y, body2.darkened(0.18))
	# Plankenfugen (waagerecht)
	for yy in [14, 17]:
		for x in range(2, 18):
			img.set_pixel(x, yy, body2.darkened(0.30))
	# Eisenband quer
	for x in range(2, 22):
		img.set_pixel(x, 12, iron)
		img.set_pixel(x, 13, iron_l)
	# Vertikale Eisenbaender
	for x in [5, 6, 15, 16]:
		for y in range(6, 21):
			img.set_pixel(x, y, iron if x in [5, 15] else iron_l)
	# Schloss
	for y in range(11, 16):
		img.set_pixel(10, y, Color(0.98, 0.84, 0.28))
		img.set_pixel(11, y, Color(0.98, 0.84, 0.28))
	img.set_pixel(10, 13, dark)
	img.set_pixel(11, 13, dark)
	img.set_pixel(9, 11, dark)
	img.set_pixel(12, 11, dark)
	img.set_pixel(9, 15, dark)
	img.set_pixel(12, 15, dark)
	# Griff
	for x in range(9, 13):
		img.set_pixel(x, 2, dark)
	img.set_pixel(9, 3, iron)
	img.set_pixel(12, 3, iron)
	# Glanzlicht
	img.set_pixel(7, 7, Color(1, 1, 1, 0.40))
	img.set_pixel(8, 7, Color(1, 1, 1, 0.22))
	img.set_pixel(3, 16, Color(1, 1, 1, 0.14))
	# Fuesse
	for x in range(3, 17):
		img.set_pixel(x, 21, dark)
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _make_chest_silver_icon() -> ImageTexture:
	# Runde 48: Silberkiste - ein INDUSTRIE-Design: eckige Kiste mit
	# Nietenreihen, Warnstreifen und einem Gitterdeckel.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.10, 0.11, 0.15)
	var steel := Color(0.78, 0.82, 0.88)
	var steel2 := Color(0.52, 0.57, 0.66)
	var steel3 := Color(0.92, 0.95, 1.0)
	var warn := Color(0.98, 0.76, 0.20)
	# Deckel (flach, industriell)
	for y in range(4, 11):
		for x in range(2, 22):
			img.set_pixel(x, y, steel3 if y < 6 else steel)
	# Runde 49: KEIN Gitter mehr - zwei dunkle Felder auf dem Deckel
	# lasen sich als Augen, das Sprite bekam ein Gesicht. Stattdessen
	# eine einzelne Deckelkante und Nieten an den Ecken.
	for y in [9]:
		for x in range(2, 22):
			img.set_pixel(x, y, steel2)
	for nx in [4, 19]:
		for ny in [6, 8]:
			img.set_pixel(nx, ny, steel2)
	# Warndreieck als Erkennungsmerkmal in der Mitte des Deckels
	_tri(img, Vector2(9, 4), Vector2(12, 8), Vector2(15, 4), warn)
	_tri(img, Vector2(10, 5), Vector2(12, 7), Vector2(14, 5), Color(0.20, 0.22, 0.28))
	# Korpus
	for y in range(11, 21):
		for x in range(2, 22):
			img.set_pixel(x, y, steel if y < 17 else steel2)
	# Untere Haelfte leicht aufhellen - das dunkle Band las sich
	# sonst als Mund hoehle
	for y in range(17, 21):
		for x in range(2, 22):
			if img.get_pixel(x, y) == steel2:
				img.set_pixel(x, y, steel2.lightened(0.14))
	# Warnstreifen
	for x in range(2, 22):
		img.set_pixel(x, 15, warn)
		img.set_pixel(x, 16, warn.darkened(0.25))
	# Runde 49: KEINE durchlaufende Nietenreihe mehr. Die helle
	# Punktereihe ueber dem dunklen Band las sich als Zaehne in einem
	# Mund - die Kiste bekam ein Gesicht. Jetzt nur noch VIER Nieten
	# an den Ecken, das Band dazwischen bleibt einfarbig.
	for nx in [4, 19]:
		img.set_pixel(nx, 12, steel3)
		img.set_pixel(nx, 13, steel2.darkened(0.20))
		img.set_pixel(nx, 18, steel3)
		img.set_pixel(nx, 19, steel2.darkened(0.20))
	# Ecken-Winkel (Rahmen) statt Scharnier-Felder
	for x in [3, 18]:
		for y in [11, 12, 18, 19]:
			img.set_pixel(x, y, steel2.darkened(0.25))
	# Runde 49: EIN zentrales Schloss statt zwei Haetten. Die zwei
	# Haetten mit ihren dunklen Pixeln bildeten Augen mit Pupillen -
	# die Kiste bekam ein Gesicht und las als Wesen, nicht als Kiste.
	for y in range(12, 17):
		for x in range(10, 14):
			img.set_pixel(x, y, steel2)
	for y in range(13, 16):
		for x in range(11, 13):
			img.set_pixel(x, y, steel3)
	img.set_pixel(11, 15, dark)
	img.set_pixel(12, 15, dark)
	# Griff oben
	for x in range(10, 14):
		img.set_pixel(x, 2, dark)
	for x in range(11, 13):
		img.set_pixel(x, 3, steel3)
	# Glanz
	img.set_pixel(4, 6, Color(1, 1, 1, 0.45))
	img.set_pixel(5, 6, Color(1, 1, 1, 0.20))
	img.set_pixel(3, 13, Color(1, 1, 1, 0.18))
	# Fuesse
	for x in range(3, 21):
		img.set_pixel(x, 21, dark)
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _make_chest_gold_icon() -> ImageTexture:
	# Runde 48: Goldtruhe - der PRESTIGE-Schrank: wulstiger Deckel,
	# Doppelband, leuchtender Edelstein auf dem Schloss.
	var px: int = 24
	var big: int = 4
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dark := Color(0.24, 0.15, 0.03)
	var gold := Color(0.98, 0.79, 0.24)
	var gold2 := Color(0.74, 0.54, 0.10)
	var gold3 := Color(1.0, 0.92, 0.52)
	var gem := Color(0.35, 0.85, 0.95)
	# Wulst-Deckel (oben gewolbt)
	for y in range(4, 12):
		var bulge: int = 0
		if y < 6:
			bulge = 1
		for x in range(2 - bulge, 22 + bulge):
			img.set_pixel(x, y, gold3 if y < 7 else gold)
	# Deckel-Fuge
	for x in range(2, 22):
		img.set_pixel(x, 11, gold2)
	# Korpus
	for y in range(12, 21):
		for x in range(2, 22):
			img.set_pixel(x, y, gold if y < 18 else gold2)
	# Doppelband
	for x in range(2, 22):
		img.set_pixel(x, 14, gold2)
		img.set_pixel(x, 15, gold3)
	# Vertikale Zierbaender
	for x in [5, 6, 17, 18]:
		for y in range(4, 21):
			img.set_pixel(x, y, gold2 if x in [5, 17] else gold3)
	# GROSSER Edelstein im Schloss
	for y in range(9, 15):
		for x in range(9, 14):
			var edge: bool = (x == 9 or x == 13 or y == 9 or y == 14)
			img.set_pixel(x, y, gold2 if edge else gem)
	img.set_pixel(10, 11, Color(1, 1, 1, 0.75))
	# Goldener Wulst oben
	for x in range(8, 16):
		img.set_pixel(x, 3, dark)
	for x in range(9, 15):
		img.set_pixel(x, 2, gold3)
	# Glanzlicht
	img.set_pixel(7, 7, Color(1, 1, 1, 0.55))
	img.set_pixel(8, 7, Color(1, 1, 1, 0.30))
	img.set_pixel(3, 17, Color(1, 1, 1, 0.22))
	# Fuesse
	for x in range(3, 21):
		img.set_pixel(x, 21, dark)
	_px_outline(img, px, dark)
	img.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


# ============================================================
# Runde 43: WELTEN-ICONS (Punkt 6)
# Jede Welt bekommt ein eigenes, wiedererkennbares Motiv in 16x16
# Pixel-Art. Die generischen Motive (tuft/cactus/ice/lava) sind weg.
# ============================================================

func _px_canvas(px: int) -> Image:
	return Image.create(px, px, false, Image.FORMAT_RGBA8)

func _px_outline(small: Image, px: int, col: Color) -> void:
	# Runde 43: Kontur um alle gesetzten Pixel legen
	for y in range(px):
		for x in range(px):
			if small.get_pixel(x, y).a > 0.0:
				var up: bool = y + 1 < px and small.get_pixel(x, y + 1).a > 0.0
				var dn: bool = y - 1 >= 0 and small.get_pixel(x, y - 1).a > 0.0
				var lf: bool = x + 1 < px and small.get_pixel(x + 1, y).a > 0.0
				var rt: bool = x - 1 >= 0 and small.get_pixel(x - 1, y).a > 0.0
				if not (up and dn and lf and rt):
					small.set_pixel(x, y, col)

func _make_map_icon_earth(season: String) -> ImageTexture:
	# Runde 43: ERDE - Landschaft mit Himmel, Sonne, Huegel und Baum
	var px: int = 16
	var small := _px_canvas(px)
	var sky := Color(0.42, 0.68, 0.92)
	var ground := Color(0.48, 0.76, 0.36)
	var dark_g := Color(0.30, 0.56, 0.22)
	var sun := Color(1.0, 0.88, 0.30)
	var tree := Color(0.18, 0.48, 0.20)
	match season:
		"desert":
			sky = Color(0.92, 0.72, 0.42)
			ground = Color(0.88, 0.76, 0.44)
			dark_g = Color(0.68, 0.56, 0.28)
			tree = Color(0.42, 0.60, 0.24)
		"ice":
			sky = Color(0.62, 0.78, 0.92)
			ground = Color(0.86, 0.93, 0.98)
			dark_g = Color(0.66, 0.78, 0.88)
			tree = Color(0.40, 0.58, 0.52)
		"lava":
			sky = Color(0.32, 0.14, 0.16)
			ground = Color(0.36, 0.20, 0.20)
			dark_g = Color(0.22, 0.10, 0.10)
			tree = Color(0.55, 0.22, 0.12)
	# Himmel oben
	for y in range(0, 6):
		for x in range(px):
			small.set_pixel(x, y, sky)
	# Sonne
	small.set_pixel(12, 1, sun)
	small.set_pixel(11, 1, sun)
	small.set_pixel(12, 2, sun)
	small.set_pixel(13, 2, sun)
	# Huegel-Linie
	for x in range(px):
		var h: int = 6 + int(round(sin(float(x) * 0.55) * 1.4))
		for y in range(h, px):
			small.set_pixel(x, y, ground)
	# dunkle Kante
	for x in range(px):
		var h2: int = 6 + int(round(sin(float(x) * 0.55) * 1.4))
		small.set_pixel(x, h2, dark_g)
	# Baum links
	for y in range(6, 10):
		small.set_pixel(4, y, tree)
	small.set_pixel(3, 7, tree)
	small.set_pixel(5, 7, tree)
	small.set_pixel(4, 5, tree)
	# Busch rechts
	small.set_pixel(11, 10, dark_g)
	small.set_pixel(12, 10, dark_g)
	small.set_pixel(11, 11, dark_g)
	_px_outline(small, px, Color(0.10, 0.12, 0.16))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)

func _make_map_icon_mars() -> ImageTexture:
	# Runde 43: MARS - roter Boden, Krater, Felsbrocken, Antenne
	var px: int = 16
	var small := _px_canvas(px)
	var sky := Color(0.72, 0.34, 0.26)
	var ground := Color(0.82, 0.44, 0.30)
	var dark := Color(0.52, 0.24, 0.18)
	var rock := Color(0.46, 0.30, 0.26)
	for y in range(0, 5):
		for x in range(px):
			small.set_pixel(x, y, sky)
	for y in range(5, px):
		for x in range(px):
			small.set_pixel(x, y, ground)
	# Horizont-Kante
	for x in range(px):
		small.set_pixel(x, 5, dark)
	# Krater (Ring)
	for i in range(4):
		small.set_pixel(3 + i, 9, dark)
		small.set_pixel(11 - i, 9, dark)
		small.set_pixel(2, 10 + i, dark)
		small.set_pixel(13, 10 + i, dark)
	small.set_pixel(4, 10, ground.darkened(0.10))
	small.set_pixel(5, 10, ground.darkened(0.10))
	small.set_pixel(10, 10, ground.darkened(0.10))
	# Felsen links
	small.set_pixel(2, 12, rock)
	small.set_pixel(3, 11, rock)
	small.set_pixel(3, 12, rock)
	small.set_pixel(2, 13, rock)
	# Antenne rechts (Mars-Rover)
	small.set_pixel(12, 8, Color(0.70, 0.72, 0.78))
	small.set_pixel(12, 9, Color(0.70, 0.72, 0.78))
	small.set_pixel(11, 7, Color(0.94, 0.40, 0.28))
	small.set_pixel(13, 12, Color(0.30, 0.26, 0.24))
	small.set_pixel(14, 12, Color(0.30, 0.26, 0.24))
	_px_outline(small, px, Color(0.16, 0.08, 0.06))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)

func _make_map_icon_jungle() -> ImageTexture:
	# Runde 43: JUNGLE - dichtes Blattdach, Lianen, Vulkan, Banane
	var px: int = 16
	var small := _px_canvas(px)
	var deep := Color(0.12, 0.30, 0.16)
	var leaf := Color(0.24, 0.56, 0.24)
	var leaf2 := Color(0.36, 0.68, 0.28)
	var ground := Color(0.20, 0.40, 0.20)
	for y in range(0, px):
		for x in range(px):
			small.set_pixel(x, y, deep)
	# Blattdach oben (3 Ebenen)
	for y in range(0, 4):
		for x in range(px):
			small.set_pixel(x, y, leaf if (x + y) % 3 == 0 else leaf2)
	for y in range(4, 6):
		for x in range(px):
			small.set_pixel(x, y, leaf.darkened(0.18))
	# Boden
	for y in range(12, px):
		for x in range(px):
			small.set_pixel(x, y, ground)
	# Stamm
	for y in range(5, 13):
		small.set_pixel(7, y, Color(0.34, 0.24, 0.14))
		small.set_pixel(8, y, Color(0.28, 0.19, 0.11))
	# Liane links
	for y in range(3, 10):
		small.set_pixel(2, y, leaf2)
	small.set_pixel(3, 8, leaf2)
	small.set_pixel(3, 9, leaf2)
	# Banane rechts (gelb)
	small.set_pixel(12, 9, Color(0.98, 0.86, 0.20))
	small.set_pixel(13, 9, Color(0.98, 0.86, 0.20))
	small.set_pixel(13, 10, Color(0.90, 0.78, 0.16))
	small.set_pixel(12, 8, Color(0.40, 0.62, 0.20))
	# Vulkan-Rauch
	small.set_pixel(11, 1, Color(0.62, 0.58, 0.60))
	small.set_pixel(12, 0, Color(0.62, 0.58, 0.60))
	_px_outline(small, px, Color(0.06, 0.14, 0.08))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)

func _make_map_icon_volt() -> ImageTexture:
	# Runde 43: ELEKTRO-WELT - Blitz, Spulen, Kabel auf dunklem Stahl
	var px: int = 16
	var small := _px_canvas(px)
	var steel := Color(0.18, 0.20, 0.30)
	var steel2 := Color(0.26, 0.29, 0.42)
	var bolt := Color(1.0, 0.86, 0.22)
	var bolt2 := Color(1.0, 0.97, 0.65)
	for y in range(px):
		for x in range(px):
			small.set_pixel(x, y, steel if (x + y) % 4 == 0 else steel2)
	# Spulen links + rechts
	for y in range(4, 11):
		small.set_pixel(1, y, Color(0.55, 0.40, 0.16))
		small.set_pixel(14, y, Color(0.55, 0.40, 0.16))
	for x in range(1, 4):
		small.set_pixel(x, 4, Color(0.75, 0.56, 0.22))
		small.set_pixel(x, 10, Color(0.75, 0.56, 0.22))
	for x in range(12, 15):
		small.set_pixel(x, 4, Color(0.75, 0.56, 0.22))
		small.set_pixel(x, 10, Color(0.75, 0.56, 0.22))
	# Blitz in der Mitte
	var b := [[8,1],[7,2],[6,3],[5,4],[4,5],[8,5],[9,6],[10,7],[11,8],[12,9],[11,10],[10,11],[9,12],[8,13],[7,12],[6,11],[5,10],[4,9],[5,8],[6,7],[7,6],[8,5]]
	for p in b:
		small.set_pixel(int(p[0]), int(p[1]), bolt)
	small.set_pixel(6, 4, bolt2)
	small.set_pixel(5, 5, bolt2)
	small.set_pixel(9, 6, bolt2)
	_px_outline(small, px, Color(0.06, 0.06, 0.10))
	small.resize(px * 4, px * 4, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)

func _make_map_icon(base: Color, accent: Color, motif: String) -> ImageTexture:
	# Runde 42: echtes PIXEL-ART-Icon.
	# 16x16 Pixel 4x hochskaliert (NEAREST) -> harte Kanten, keine weichen Verlaeufe.
	var px: int = 16
	var big: int = 4
	var small := Image.create(px, px, false, Image.FORMAT_RGBA8)
	small.fill(Color(0, 0, 0, 0))
	for y in range(px):
		for x in range(px):
			var c := base if (x + y) % 2 == 0 else base.darkened(0.16)
			small.set_pixel(x, y, c)
	var dark := accent.darkened(0.45)
	match motif:
		"tuft":
			for hx in [5, 9, 12]:
				for i in range(4):
					small.set_pixel(hx, 9 - i, accent)
				small.set_pixel(hx - 1, 8, accent.darkened(0.22))
				small.set_pixel(hx + 1, 7, accent.darkened(0.22))
		"cactus":
			for i in range(8):
				small.set_pixel(7, 13 - i, accent)
			for i in range(3):
				small.set_pixel(5, 10 - i, accent)
				small.set_pixel(9, 8 - i, accent)
			small.set_pixel(4, 11, accent)
			small.set_pixel(10, 9, accent)
		"ice":
			# Runde 42: Breite begrenzt (max 8 Pixel je Seite), sonst Out-of-Bounds
			for i in range(9):
				var w: int = mini(8, 9 - i)
				for j in range(w):
					small.set_pixel(8 - j, 12 - i, accent)
					small.set_pixel(8 + j, 12 - i, accent)
			for i in range(3):
				var w2: int = mini(4, 4 - i)
				for j in range(w2):
					small.set_pixel(8 - j, 10 - i, Color(1, 1, 1))
					small.set_pixel(8 + j, 10 - i, Color(1, 1, 1))
		"lava":
			for i in range(4):
				small.set_pixel(5 - i, 11, accent)
				small.set_pixel(5 + i, 11, accent)
				small.set_pixel(5, 11 - i, accent)
				small.set_pixel(5, 11 + i, accent)
			small.set_pixel(4, 10, accent.lightened(0.35))
			small.set_pixel(6, 10, accent.lightened(0.35))
			small.set_pixel(4, 12, accent.lightened(0.35))
			small.set_pixel(6, 12, accent.lightened(0.35))
			small.set_pixel(5, 10, accent.lightened(0.55))
			small.set_pixel(5, 12, accent.lightened(0.55))
	for i in range(px):
		small.set_pixel(i, 0, dark)
		small.set_pixel(i, px - 1, dark)
		small.set_pixel(0, i, dark)
		small.set_pixel(px - 1, i, dark)
	# Runde 42: resize() mutiert in Godot 4 (gibt void zurueck)
	small.resize(px * big, px * big, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


func _make_mars_alien() -> ImageTexture:
	var img = _new_img(64, 64)
	var skin := Color(0.45, 0.86, 0.46)
	var suit := Color(0.86, 0.36, 0.24)
	_ellipse(img, 32, 55, 14, 4, SHADOW, true)
	_outlined_ellipse(img, 32, 38, 11, 13, suit, 3)
	_outlined_disc(img, 32, 22, 12, skin, 3)
	_outlined_disc(img, 27, 22, 5, Color(0.08, 0.08, 0.12), 1)
	_outlined_disc(img, 38, 22, 5, Color(0.08, 0.08, 0.12), 1)
	_px(img, 26, 20, Color(1, 1, 1))
	_px(img, 37, 20, Color(1, 1, 1))
	_rect(img, 31, 4, 2, 8, OUTLINE)
	_outlined_disc(img, 32, 3, 4, Color(1.0, 0.86, 0.25), 1)
	_rect(img, 40, 32, 16, 6, OUTLINE)
	_rect(img, 41, 33, 14, 4, Color(0.30, 0.32, 0.38))
	_outlined_disc(img, 44, 38, 4, skin, 2)
	return ImageTexture.create_from_image(img)

func _make_mars_rover() -> ImageTexture:
	var img = _new_img(64, 64)
	var body := Color(0.78, 0.72, 0.62)
	var panel := Color(0.30, 0.45, 0.85)
	_ellipse(img, 32, 55, 20, 5, SHADOW, true)
	_outlined_disc(img, 16, 47, 8, Color(0.20, 0.20, 0.24), 2)
	_outlined_disc(img, 48, 47, 8, Color(0.20, 0.20, 0.24), 2)
	_rect(img, 12, 27, 40, 22, OUTLINE)
	_rect(img, 14, 29, 36, 18, body)
	_tri(img, Vector2(52, 25), Vector2(61, 38), Vector2(52, 51), Color(0.60, 0.58, 0.54))
	_rect(img, 18, 15, 28, 12, OUTLINE)
	_rect(img, 20, 17, 24, 8, panel)
	_outlined_disc(img, 32, 38, 6, Color(1.0, 0.35, 0.25), 2)
	_px(img, 31, 37, Color(1, 1, 1))
	return ImageTexture.create_from_image(img)

func _make_big_flower() -> ImageTexture:
	var img = _new_img(64, 64)
	var petal := Color(0.95, 0.36, 0.66)
	var core := Color(1.0, 0.86, 0.26)
	var stem := Color(0.20, 0.50, 0.22)
	_ellipse(img, 32, 57, 14, 4, SHADOW, true)
	_rect(img, 30, 34, 5, 22, OUTLINE)
	_rect(img, 31, 36, 3, 20, stem)
	for i in range(6):
		var a := TAU * float(i) / 6.0
		var c := Vector2(32, 26) + Vector2(cos(a), sin(a)) * 13.0
		_outlined_disc(img, int(c.x), int(c.y), 8, petal, 2)
	_outlined_disc(img, 32, 26, 10, core, 3)
	_outlined_disc(img, 32, 26, 5, Color(0.55, 0.18, 0.35), 2)
	return ImageTexture.create_from_image(img)

func _make_banana() -> ImageTexture:
	var img = _new_img(32, 32)
	var peel := Color(0.98, 0.86, 0.26)
	var dark := Color(0.72, 0.56, 0.10)
	for i in range(9):
		var t := float(i) / 8.0
		var a := PI * 0.18 + PI * 0.66 * t
		var c := Vector2(16, 19) + Vector2(cos(a) * 11.0, -sin(a) * 9.0)
		_disc(img, int(c.x), int(c.y), 4, peel)
		_px(img, int(c.x), int(c.y) - 3, dark)
	return ImageTexture.create_from_image(img)

func _make_palm() -> ImageTexture:
	var img = _new_img(64, 64)
	var trunk := Color(0.50, 0.36, 0.20)
	var leaf := Color(0.20, 0.62, 0.26)
	_ellipse(img, 32, 56, 16, 5, SHADOW, true)
	_rect(img, 28, 22, 8, 34, OUTLINE)
	_rect(img, 30, 24, 4, 32, trunk)
	for i in range(5):
		var a := -PI * 0.9 + PI * 0.8 * (float(i) / 4.0)
		var c := Vector2(32, 22) + Vector2(cos(a) * 15.0, sin(a) * 12.0)
		_ellipse(img, int(c.x), int(c.y), 9, 5, leaf)
	_outlined_disc(img, 30, 22, 4, Color(0.85, 0.65, 0.20), 1)
	return ImageTexture.create_from_image(img)


# ---------- Runde 14: Welt-Objekte der Planeten ----------

func _heart_padded(color: Color, outline_color: Color, size: int) -> ImageTexture:
	# Herz mit Rand im Bild (sonst wird der Umriss am breitesten Punkt angeschnitten)
	var inner := int(round(float(size) * 0.82))
	var src: Image = _create_heart_texture(color, outline_color, inner).get_image()
	var img = _new_img(size, size)
	var off := int((size - inner) / 2)
	for x in range(inner):
		for y in range(inner):
			var c: Color = src.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x + off, y + off, c)
	return ImageTexture.create_from_image(img)

func _load_external(key: String, res_path: String) -> void:
	# Laedt ein echtes PNG aus assets/ ; faellt bei Problemen auf die prozedurale
	# Variante zurueck (Schluessel bleibt in jedem Fall gueltig).
	if not ResourceLoader.exists(res_path):
		return
	var tex = load(res_path)
	if tex != null and tex is Texture2D:
		textures[key] = tex

func _make_boulder(body: Color, hl: Color, size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(c + c * 0.52), int(c * 0.86), int(c * 0.22), SHADOW, true)
	_outlined_disc(img, int(c - c * 0.26), int(c - c * 0.02), int(c * 0.44), body, 3)
	_outlined_disc(img, int(c + c * 0.30), int(c + c * 0.06), int(c * 0.38), body, 3)
	_outlined_disc(img, int(c + c * 0.04), int(c - c * 0.34), int(c * 0.34), body, 3)
	_disc(img, int(c - c * 0.24), int(c - c * 0.22), int(c * 0.20), hl)
	_disc(img, int(c + c * 0.32), int(c - c * 0.08), int(c * 0.15), hl)
	return ImageTexture.create_from_image(img)

func _make_crater(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(c), int(c * 0.94), int(c * 0.80), Color(0.66, 0.32, 0.23), true)
	_ellipse(img, int(c), int(c), int(c * 0.76), int(c * 0.62), Color(0.46, 0.19, 0.15), true)
	_ellipse(img, int(c), int(c), int(c * 0.58), int(c * 0.47), Color(0.30, 0.12, 0.10), true)
	_ellipse(img, int(c), int(c - c * 0.52), int(c * 0.72), int(c * 0.10), Color(0.82, 0.48, 0.35, 0.75), true)
	return ImageTexture.create_from_image(img)

func _make_jungle_tree(size: int) -> ImageTexture:
	# Bugfix: Krone lag vorher teilweise ausserhalb des Bildes (oben abgeschnitten)
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var trunk := Color(0.44, 0.31, 0.19)
	var leaf1 := Color(0.14, 0.44, 0.21)
	var leaf2 := Color(0.24, 0.62, 0.30)
	_ellipse(img, int(c), int(size - c * 0.18), int(c * 0.72), int(c * 0.13), SHADOW, true)
	_rect(img, int(c - c * 0.12), int(c * 0.46), int(c * 0.24), int(c * 0.60), OUTLINE)
	_rect(img, int(c - c * 0.08), int(c * 0.48), int(c * 0.16), int(c * 0.58), trunk)
	# drei Bueschel, alle mit Rand innerhalb der Leinwand
	_outlined_disc(img, int(c - c * 0.40), int(c * 0.58), int(c * 0.28), leaf1, 3)
	_outlined_disc(img, int(c + c * 0.42), int(c * 0.56), int(c * 0.26), leaf1, 3)
	_outlined_disc(img, int(c), int(c * 0.36), int(c * 0.30), leaf2, 3)
	_outlined_disc(img, int(c - c * 0.16), int(c * 0.70), int(c * 0.22), leaf2, 2)
	return ImageTexture.create_from_image(img)

func _make_bamboo_pixel() -> ImageTexture:
	# Runde 56: Bambus mit echter Kontur. Vorher 2 px breite Striche ohne
	# Rand - auf dem Boden kaum als Pflanze lesbar.
	var W := 44
	var H := 80
	var img = _new_img(W, H)
	var s_l := Color(0.62, 0.82, 0.40)
	var s_m := Color(0.46, 0.68, 0.29)
	var s_d := Color(0.30, 0.48, 0.20)
	var leaf := Color(0.30, 0.58, 0.24)
	var leaf_l := Color(0.50, 0.76, 0.34)
	var xs := [8, 17, 26, 35]
	for i in range(xs.size()):
		var x: int = xs[i]
		var h: int = H - 16 - (i % 3) * 8
		var top: int = H - h
		# Halm: 7 px Kontur, 4 px Fuellung, Lichtkante
		_rect(img, x - 3, top, 7, h, OUTLINE)
		_rect(img, x - 2, top + 1, 4, h - 1, s_m if i % 2 == 0 else s_l)
		_rect(img, x - 2, top + 1, 1, h - 1, s_l)
		var k: int = top + 6
		while k < H - 4:
			# Runde 57: Knoten nur als dunkelgruener Ring, NICHT als voller
			# schwarzer Balken - der liess die Halme wie Leitern aussehen.
			_rect(img, x - 2, k, 5, 2, s_d)
			_rect(img, x - 2, k + 2, 5, 1, s_l)
			k += 9
		# Blattbueschel
		var lb := Vector2(float(x) + 0.5, float(top + 2))
		_leaf(img, lb, lb + Vector2(-13, -9), lb + Vector2(-5, 4), leaf)
		_leaf(img, lb, lb + Vector2(13, -11), lb + Vector2(5, 3), leaf_l)
		_leaf(img, lb, lb + Vector2(1, -15), lb + Vector2(3, 1), leaf)
	print("[JUNGLE][TEX] bamboo neu gezeichnet (%dx%d, 4 Halme)" % [W, H])
	return ImageTexture.create_from_image(img)

func _make_bamboo_alt(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var stalk := Color(0.72, 0.86, 0.36)
	var dark := Color(0.40, 0.58, 0.20)
	var leaf := Color(0.26, 0.68, 0.32)
	var c := float(size) / 2.0
	_ellipse(img, int(c), size - 6, int(c * 0.62), 5, SHADOW, true)
	for i in range(5):
		var x := int(c + (float(i) - 2.0) * c * 0.30)
		var h := int(c * (1.44 + 0.13 * float(i % 3)))
		_rect(img, x - 5, size - h - 3, 11, h, OUTLINE)
		_rect(img, x - 3, size - h - 1, 7, h - 4, stalk)
		for k in range(1, 5):
			_rect(img, x - 4, size - int(float(h) * float(k) / 5.0), 9, 2, dark)
		_tri(img, Vector2(x - 3, size - h - 3), Vector2(x - 18, size - h - 10), Vector2(x - 3, size - h + 4), leaf)
		_tri(img, Vector2(x + 4, size - h - 3), Vector2(x + 19, size - h - 12), Vector2(x + 4, size - h + 2), leaf)
	return ImageTexture.create_from_image(img)

func _make_fern(size: int) -> ImageTexture:
	# Runde 56: Echter Farn. Vorher ein Stern aus sieben graden Dreiecken
	# ("Grasbueschel"). Jetzt sechs geschwungene Wedel mit Fiederblaettern.
	var img = _new_img(size, size)
	var leaf := Color(0.19, 0.52, 0.24)
	var leaf2 := Color(0.31, 0.70, 0.32)
	var s: float = float(size)
	_ellipse(img, int(s * 0.50), int(s * 0.88), int(s * 0.26), int(s * 0.06), SHADOW, true)
	var base := Vector2(s * 0.50, s * 0.86)
	for i in range(6):
		var ang: float = deg_to_rad(-152.0 + 24.0 * float(i))
		var ln: float = s * (0.52 + 0.06 * float(i % 3))
		_frond(img, base, ang, ln, s * 0.10, leaf if i % 2 == 0 else leaf2, leaf2, s * 0.10)
	_disc(img, base.x, base.y - 2.0, s * 0.07, Color(0.16, 0.38, 0.20))
	print("[JUNGLE][TEX] fern neu gezeichnet (%dpx, 6 Wedel)" % size)
	return ImageTexture.create_from_image(img)

func _jleaf_shape(img: Image, center: Vector2, angle: float, length: float, width: float, col: Color) -> void:
	# Runde 58: Einzelnes Blatt - zwei Haelften (hell/dunkel) + Mittelrippe
	# + Stiel. Vorher waren es Rauten ohne Rippe, die wie Splitter wirkten.
	var d: Vector2 = Vector2.RIGHT.rotated(angle) * length * 0.5
	var n: Vector2 = Vector2(-d.y, d.x) * width * 0.5
	var tip1: Vector2 = center - d
	var tip2: Vector2 = center + d
	_tri(img, tip1, tip2, center + n, col.lightened(0.10))
	_tri(img, tip1, tip2, center - n, col.darkened(0.14))
	_thick_line(img, tip1, tip2, 1.1, col.darkened(0.38))
	_thick_line(img, tip2, tip2 + d.normalized() * (length * 0.22), 1.4, col.darkened(0.30))


func _make_jleafpile(size: int) -> ImageTexture:
	# Runde 58b: Runde, gedämpfte Blatthaufen. Die Dreiecks-Blätter lasen im
	# Spiel wie orange Explosionen. Jetzt flache Blattkissen aus ueberlappenden
	# Scheiben mit dunkler Kante und kleinem Glanzpunkt.
	var img = _new_img(size, size)
	var f := float(size)
	var cols := [Color(0.52, 0.36, 0.19), Color(0.62, 0.46, 0.22), Color(0.44, 0.44, 0.20), Color(0.68, 0.52, 0.26)]
	_ellipse(img, int(f * 0.50), int(f * 0.70), int(f * 0.40), int(f * 0.14), Color(0.14, 0.18, 0.10, 0.40), true)
	var spots := [
		Vector2(0.32, 0.62), Vector2(0.50, 0.58), Vector2(0.68, 0.63),
		Vector2(0.40, 0.69), Vector2(0.60, 0.70), Vector2(0.50, 0.66),
		Vector2(0.24, 0.66), Vector2(0.76, 0.67), Vector2(0.46, 0.72),
	]
	for i in range(spots.size()):
		var p: Vector2 = spots[i] * f
		var r: float = f * (0.115 - 0.008 * float(i % 3))
		var c: Color = cols[i % cols.size()]
		_disc(img, p.x, p.y + r * 0.22, r, Color(0.18, 0.16, 0.09, 0.55))   # Schattenkante
		_disc(img, p.x, p.y, r * 0.94, c)                                   # Blatt
		_disc(img, p.x - r * 0.26, p.y - r * 0.28, r * 0.34, c.lightened(0.16))  # Glanz
	print("[JUNGLE][TEX] jleafpile neu gezeichnet (%dpx, 9 runde Blaetter)" % size)
	return ImageTexture.create_from_image(img)


func _make_mushroom(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var stem := Color(0.94, 0.90, 0.80)
	var cap := Color(0.90, 0.28, 0.32)
	_rect(img, int(size * 0.44), int(size * 0.55), int(size * 0.12), int(size * 0.35), OUTLINE)
	_rect(img, int(size * 0.46), int(size * 0.57), int(size * 0.08), int(size * 0.32), stem)
	_ellipse(img, int(size / 2), int(size * 0.50), int(size * 0.30), int(size * 0.22), OUTLINE, true)
	_ellipse(img, int(size / 2), int(size * 0.48), int(size * 0.27), int(size * 0.19), cap, true)
	_disc(img, int(size * 0.40), int(size * 0.44), 3, Color(1, 1, 1, 0.85))
	_disc(img, int(size * 0.60), int(size * 0.50), 2, Color(1, 1, 1, 0.85))
	return ImageTexture.create_from_image(img)

func _make_glow(size: int, col: Color) -> ImageTexture:
	var img = _new_img(size, size)
	var c := int(size / 2)
	for r in range(c, 0, -1):
		var a := pow(1.0 - float(r) / float(c), 1.6) * 0.5
		_disc(img, c, c, r, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)

func _make_run_chest(body: Color, band: Color, gem: Color, spikes: bool) -> ImageTexture:
	# Runde 49: Die IN-GAME-Truhe war ein flacher Block (zwei
	# Rechtecke + ein Kreis) und sah aus wie ein Kistendeckel, nicht
	# wie eine Truhe. Jetzt: gewoelbter Deckel, sichtbarer Deckelspalt,
	# Eisenbaender, ein Schloss mit dem Edelstein und - bei der
	# Epic-Variante - eine Krone aus Stacheln.
	var img = _new_img(64, 64)
	var dark := Color(0.10, 0.08, 0.07)
	var body2 := body.darkened(0.28)
	var body3 := body.lightened(0.18)
	var band2 := band.darkened(0.24)
	var band_l := band.lightened(0.24)
	# --- Schatten ---
	_ellipse(img, 32, 58, 25, 5, SHADOW)
	# --- Korpus ---
	_rect(img, 7, 32, 50, 24, OUTLINE)
	_rect(img, 9, 34, 46, 20, body)
	# Seiten-Schatten
	_rect(img, 45, 34, 10, 20, body2)
	# Boden-Kante
	_rect(img, 9, 50, 46, 4, body2)
	# --- Gewoelbter Deckel (mit Kontur) ---
	_outlined_ellipse(img, 32, 31, 22, 10, body3, 3)
	# Deckelspalt (dunkle Linie)
	_rect(img, 9, 32, 46, 2, OUTLINE)
	# --- Zwei Eisenbaender quer ueber Deckel und Korpus ---
	for bx in [15, 45]:
		_rect(img, bx, 21, 5, 35, OUTLINE)
		_rect(img, bx + 1, 22, 3, 33, band)
		_rect(img, bx + 1, 22, 1, 33, band_l)
	# --- Schloss in der Mitte ---
	_rect(img, 27, 36, 11, 12, OUTLINE)
	_rect(img, 28, 37, 9, 10, band)
	_rect(img, 29, 38, 7, 8, band2)
	# Edelstein im Schloss
	_outlined_disc(img, 32, 42, 6, gem, 2)
	_disc(img, 30, 40, 2, Color(1, 1, 1, 0.9))
	# --- Eckbeschlaege ---
	_rect(img, 7, 32, 3, 24, band2)
	_rect(img, 54, 32, 3, 24, band2)
	# --- Fuesse ---
	_rect(img, 10, 56, 8, 4, OUTLINE)
	_rect(img, 46, 56, 8, 4, OUTLINE)
	# --- Glanzlicht auf dem Deckel ---
	# blend=true, sonst ERSETZT _px den Pixel und das Licht wird ein
	# halbtransparentes Loch im Deckel.
	_ellipse(img, 22, 26, 7, 3, Color(1, 1, 1, 0.30), true)
	# --- Epic: Krone aus Stacheln auf dem Deckel ---
	if spikes:
		for i in range(5):
			var x := 13 + i * 10
			_tri(img, Vector2(x, 24), Vector2(x + 5, 8), Vector2(x + 10, 24), OUTLINE)
			_tri(img, Vector2(x + 1, 23), Vector2(x + 5, 11), Vector2(x + 9, 23), band)
			_disc(img, x + 5, 12, 2, gem)
	return ImageTexture.create_from_image(img)

# ---------- Runde 14: Planeten-Monster ----------

func _make_mars_drone() -> ImageTexture:
	var img = _new_img(64, 64)
	var metal := Color(0.72, 0.74, 0.80)
	var eye := Color(1.0, 0.25, 0.20)
	_ellipse(img, 32, 53, 14, 4, SHADOW, true)
	_outlined_ellipse(img, 32, 34, 20, 9, metal, 3)
	_outlined_disc(img, 32, 27, 11, Color(0.85, 0.88, 0.95), 2)
	_outlined_disc(img, 32, 27, 6, eye, 2)
	_px(img, 31, 26, Color(1, 1, 1))
	for i in range(5):
		var a := PI * (0.15 + 0.18 * float(i))
		_disc(img, int(32.0 + cos(a) * 18.0), int(34.0 + sin(a) * 8.0), 2, Color(0.55, 1.0, 0.85))
	return ImageTexture.create_from_image(img)

func _make_mars_guard() -> ImageTexture:
	var img = _new_img(64, 64)
	var rock := Color(0.58, 0.30, 0.24)
	var plate := Color(0.78, 0.76, 0.72)
	var eye := Color(1.0, 0.55, 0.20)
	_ellipse(img, 32, 57, 20, 5, SHADOW, true)
	_outlined_ellipse(img, 22, 50, 8, 8, rock, 2)
	_outlined_ellipse(img, 42, 50, 8, 8, rock, 2)
	_outlined_ellipse(img, 32, 34, 17, 17, rock, 3)
	_outlined_ellipse(img, 41, 33, 11, 15, plate, 3)
	_rect(img, 37, 22, 8, 20, OUTLINE)
	_outlined_disc(img, 26, 17, 9, rock, 3)
	_outlined_disc(img, 25, 16, 3, eye, 1)
	return ImageTexture.create_from_image(img)

func _make_robo_tiger() -> ImageTexture:
	# Runde 49: ROBOTER-KATZE - eine klar erkennbare Katzen-Silhouette:
	# hoher Koerper auf vier Beinen, Brust aufrecht, runder Kopf mit
	# zwei spitzen Ohren, Schnauze, leuchtendes Auge und ein Schweif
	# nach oben. Vorher war es ein flacher, gestreckter Block, der
	# eher wie ein Kabel las.
	var img = _new_img(64, 64)
	var metal := Color(0.82, 0.80, 0.72)
	var metal2 := Color(0.62, 0.60, 0.54)
	var metal3 := Color(0.94, 0.93, 0.88)
	var stripe := Color(0.16, 0.17, 0.22)
	var glow := Color(0.35, 0.95, 1.0)
	_ellipse(img, 30, 55, 17, 4, SHADOW, true)
	# --- Schweif (nach oben gebogen) ---
	_tri(img, Vector2(14, 40), Vector2(4, 22), Vector2(12, 42), OUTLINE)
	_tri(img, Vector2(13, 39), Vector2(7, 26), Vector2(12, 39), metal2)
	_rect(img, 9, 26, 3, 3, glow)
	# --- Hintere Beine ---
	for lx in [20, 34]:
		_rect(img, lx, 38, 6, 16, OUTLINE)
		_rect(img, lx + 1, 39, 4, 14, metal2)
		_rect(img, lx, 51, 7, 3, OUTLINE)
	# --- Vorderbeine (heller, naeher) ---
	for lx in [15, 29]:
		_rect(img, lx, 36, 7, 18, OUTLINE)
		_rect(img, lx + 1, 37, 5, 16, metal)
		_rect(img, lx, 50, 8, 4, OUTLINE)
		_rect(img, lx + 1, 51, 6, 2, metal2)
	# --- Koerper (hoch, Brust aufrecht) ---
	_outlined_ellipse(img, 28, 32, 15, 12, metal, 3)
	# Brustpartie heller
	_ellipse(img, 24, 30, 8, 8, metal3)
	# --- Tigerstreifen ---
	_rect(img, 22, 21, 3, 11, stripe)
	_rect(img, 28, 20, 3, 13, stripe)
	_rect(img, 34, 22, 3, 9, stripe)
	# --- Kopf (rund, gross) ---
	_outlined_disc(img, 48, 24, 12, metal, 3)
	# Backenzeichnung
	_ellipse(img, 45, 27, 7, 5, metal3)
	# --- Ohren (spitz, mit Innen) ---
	_tri(img, Vector2(40, 15), Vector2(42, 3), Vector2(47, 13), OUTLINE)
	_tri(img, Vector2(41, 14), Vector2(43, 6), Vector2(46, 13), metal)
	_tri(img, Vector2(42, 13), Vector2(43, 8), Vector2(45, 12), stripe)
	_tri(img, Vector2(50, 13), Vector2(55, 3), Vector2(57, 15), OUTLINE)
	_tri(img, Vector2(51, 13), Vector2(54, 6), Vector2(56, 14), metal)
	_tri(img, Vector2(52, 12), Vector2(54, 8), Vector2(55, 13), stripe)
	# --- Auge (leuchtend) ---
	_outlined_disc(img, 51, 21, 4, glow, 2)
	_px(img, 50, 20, Color(1, 1, 1, 0.9))
	# --- Schnauze + Nase ---
	_ellipse(img, 55, 27, 5, 4, metal3)
	_px(img, 57, 25, OUTLINE)
	_px(img, 56, 26, OUTLINE)
	# --- Zaehne ---
	_tri(img, Vector2(52, 29), Vector2(54, 33), Vector2(55, 29), Color(0.96, 0.96, 0.90))
	# --- Halsband mit Antenne ---
	_rect(img, 38, 31, 6, 3, OUTLINE)
	_rect(img, 39, 32, 4, 1, glow)
	_rect(img, 41, 26, 2, 6, OUTLINE)
	_disc(img, 42, 25, 2, glow)
	return ImageTexture.create_from_image(img)

func _make_vine_trap() -> ImageTexture:
	var img = _new_img(64, 64)
	var stem := Color(0.18, 0.46, 0.22)
	var maw := Color(0.62, 0.18, 0.32)
	var tooth := Color(0.96, 0.96, 0.90)
	_ellipse(img, 32, 57, 16, 5, SHADOW, true)
	_rect(img, 29, 34, 6, 24, OUTLINE)
	_rect(img, 30, 36, 4, 22, stem)
	_disc(img, 22, 48, 7, stem)
	_disc(img, 42, 44, 6, stem)
	_outlined_ellipse(img, 32, 26, 16, 12, maw, 3)
	_tri(img, Vector2(18, 20), Vector2(24, 8), Vector2(30, 20), maw)
	_tri(img, Vector2(34, 20), Vector2(40, 8), Vector2(46, 20), maw)
	for i in range(5):
		var x := 20 + i * 6
		_tri(img, Vector2(x, 20), Vector2(x + 3, 13), Vector2(x + 6, 20), tooth)
	_disc(img, 32, 27, 6, Color(0.30, 0.06, 0.14))
	return ImageTexture.create_from_image(img)


# ============================================================
# Runde 18: Dschungel-Set nach Referenzbildern des Nutzers
# (runde Wolkenkronen, 3-4 Gruentoenen + dunkle Kontur, Palmen,
#  Trauerweide, Urbaum mit Kristall, Pilze, Kristalle, Schilf)
# ============================================================

const JT_LEAF_D := Color(0.11, 0.31, 0.15)
const JT_LEAF := Color(0.20, 0.52, 0.24)
const JT_LEAF_L := Color(0.38, 0.70, 0.30)
const JT_TRUNK_D := Color(0.30, 0.20, 0.12)
const JT_TRUNK := Color(0.48, 0.33, 0.19)

func _leaf_cluster(img, cx: float, cy: float, r: float) -> void:
	# Busch in 3 Toenen: dunkle Kontur, Mittelton, Highlight oben-links
	_outlined_disc(img, int(cx), int(cy), int(r), JT_LEAF_D, 3)
	_disc(img, int(cx), int(cy), int(r * 0.88), JT_LEAF)
	_disc(img, int(cx - r * 0.26), int(cy - r * 0.30), int(r * 0.44), JT_LEAF_L)

func _trunk(img, cx: float, top: float, bot: float, w: float) -> void:
	_rect(img, int(cx - w / 2.0 - 2.0), int(top), int(w + 4.0), int(bot - top), OUTLINE)
	_rect(img, int(cx - w / 2.0), int(top), int(w), int(bot - top), JT_TRUNK)
	_rect(img, int(cx - w / 2.0), int(top), int(w * 0.34), int(bot - top), JT_TRUNK_D)

func _make_jtree_round(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.08), int(c * 0.60), int(c * 0.13), SHADOW, true)
	_trunk(img, c, c * 0.66, size - c * 0.06, c * 0.20)
	# Wurzelansatz
	_tri(img, Vector2(c - c * 0.10, size - c * 0.16), Vector2(c - c * 0.30, size - c * 0.02), Vector2(c - c * 0.02, size - c * 0.20), JT_TRUNK_D)
	_leaf_cluster(img, c, c * 0.50, c * 0.36)
	_leaf_cluster(img, c - c * 0.40, c * 0.68, c * 0.26)
	_leaf_cluster(img, c + c * 0.42, c * 0.66, c * 0.25)
	_leaf_cluster(img, c - c * 0.12, c * 0.34, c * 0.20)
	_leaf_cluster(img, c + c * 0.20, c * 0.38, c * 0.19)
	return ImageTexture.create_from_image(img)

func _make_jtree_tall(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.06), int(c * 0.52), int(c * 0.11), SHADOW, true)
	_trunk(img, c, c * 0.34, size - c * 0.05, c * 0.16)
	# leichte Kruemmung
	_ellipse(img, int(c + c * 0.04), int(c * 0.70), int(c * 0.10), int(c * 0.20), JT_TRUNK, true)
	_leaf_cluster(img, c, c * 0.32, c * 0.25)
	_leaf_cluster(img, c - c * 0.30, c * 0.38, c * 0.22)
	_leaf_cluster(img, c + c * 0.32, c * 0.36, c * 0.22)
	return ImageTexture.create_from_image(img)

func _make_jtree_willow(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.06), int(c * 0.58), int(c * 0.12), SHADOW, true)
	_trunk(img, c, c * 0.40, size - c * 0.05, c * 0.18)
	_leaf_cluster(img, c, c * 0.36, c * 0.30)
	# haengende Straenge
	var strand := Color(0.24, 0.56, 0.28)
	var strand_d := Color(0.13, 0.36, 0.18)
	for i in range(9):
		var px0 := c - c * 0.62 + float(i) * (c * 1.24 / 8.0)
		var hh := c * (0.42 + 0.22 * float((i * 7) % 5) / 4.0)
		_rect(img, int(px0), int(c * 0.30), 5, int(hh), OUTLINE)
		_rect(img, int(px0) + 1, int(c * 0.32), 3, int(hh - 4), strand if i % 2 == 0 else strand_d)
	return ImageTexture.create_from_image(img)

func _make_jtree_ancient(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.06), int(c * 0.62), int(c * 0.14), SHADOW, true)
	# krummer, dicker Stamm mit Gesicht in den Wurzeln
	_trunk(img, c - c * 0.04, c * 0.36, size - c * 0.05, c * 0.34)
	_tri(img, Vector2(c - c * 0.20, size - c * 0.18), Vector2(c - c * 0.44, size - c * 0.02), Vector2(c - c * 0.04, size - c * 0.24), JT_TRUNK_D)
	_tri(img, Vector2(c + c * 0.18, size - c * 0.18), Vector2(c + c * 0.42, size - c * 0.02), Vector2(c + c * 0.04, size - c * 0.24), JT_TRUNK_D)
	_disc(img, int(c - c * 0.10), int(size - c * 0.30), int(c * 0.05), Color(0.08, 0.08, 0.10))   # Augen
	_disc(img, int(c + c * 0.06), int(size - c * 0.30), int(c * 0.05), Color(0.08, 0.08, 0.10))
	_leaf_cluster(img, c, c * 0.40, c * 0.34)
	_leaf_cluster(img, c - c * 0.44, c * 0.54, c * 0.26)
	_leaf_cluster(img, c + c * 0.46, c * 0.50, c * 0.26)
	# blauer Kristall am Stamm
	_tri(img, Vector2(c + c * 0.22, c * 0.86), Vector2(c + c * 0.30, c * 0.48), Vector2(c + c * 0.38, c * 0.86), OUTLINE)
	_tri(img, Vector2(c + c * 0.24, c * 0.84), Vector2(c + c * 0.30, c * 0.52), Vector2(c + c * 0.36, c * 0.84), Color(0.42, 0.82, 0.98))
	return ImageTexture.create_from_image(img)

func _quad(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	# Runde 56: quadratische Bezier fuer geschwungene Staemme/Wedel
	var u: float = 1.0 - t
	return a * u * u + b * 2.0 * u * t + c * t * t


func _leaf(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	# Runde 56: Blatt mit dunkler Kontur (Comic-Look) - erst Rand, dann
	# die Fuellung leicht zum Zentrum hin verkleinert.
	var g: Vector2 = (a + b + c) / 3.0
	_tri(img, a, b, c, OUTLINE)
	_tri(img, g.lerp(a, 0.78), g.lerp(b, 0.78), g.lerp(c, 0.78), col)


func _frond(img: Image, base: Vector2, ang: float, length: float, droop: float,
		col: Color, col2: Color, leaf_len: float = 12.0) -> void:
	# Runde 56: Palmwedel - geschwungene Spindel mit Fiederblaettern
	var steps: int = 11
	var dir: Vector2 = Vector2.RIGHT.rotated(ang)
	# 1) dunkle Kontur der Spindel
	var prev: Vector2 = base
	for i in range(1, steps + 1):
		var f: float = float(i) / float(steps)
		var p: Vector2 = base + dir * length * f + Vector2(0, droop * f * f)
		_thick_line(img, prev, p, 3.0 - 1.6 * f, OUTLINE)
		prev = p
	# 2) Farbe + Fiederblaetter
	prev = base
	for i in range(1, steps + 1):
		var f: float = float(i) / float(steps)
		var p: Vector2 = base + dir * length * f + Vector2(0, droop * f * f)
		_thick_line(img, prev, p, 2.2 - 1.2 * f, col2)
		var t: Vector2 = (p - prev).normalized()
		var n: Vector2 = Vector2(-t.y, t.x)
		var ll: float = leaf_len * (1.0 - 0.55 * f)
		var c1: Color = col if i % 2 == 0 else col2
		_leaf(img, p, p + n * ll - t * 2.0, p + n * ll * 0.22, c1)
		_leaf(img, p, p - n * ll - t * 2.0, p - n * ll * 0.22, c1)
		prev = p


func _make_jpalm(size: int) -> ImageTexture:
	# Runde 56: ECHTE Palme. Vorher war das ein brauner Pfahl mit einem
	# Stern oben ("Besen"). Jetzt geschwungener Stamm mit Ringen und
	# acht gefiederte Wedel.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var trunk := Color(0.46, 0.30, 0.18)
	var trunk_l := Color(0.60, 0.41, 0.25)
	var trunk_d := Color(0.31, 0.19, 0.11)
	var frond := Color(0.17, 0.46, 0.21)
	var frond_l := Color(0.30, 0.64, 0.27)
	_ellipse(img, int(c), int(size - 10), int(c * 0.42), int(c * 0.09), SHADOW, true)

	var p0 := Vector2(c + 6.0, size - 16.0)
	var p1 := Vector2(c - 4.0, c + 18.0)
	var p2 := Vector2(c - 26.0, c * 0.44)
	# Stamm: Kontur, Fuellung, Ringe, Lichtkante
	for i in range(24):
		var f: float = float(i) / 23.0
		var p: Vector2 = _quad(p0, p1, p2, f)
		var r: float = 11.5 - 4.5 * f
		_disc(img, p.x, p.y, r + 2.0, OUTLINE)
	for i in range(24):
		var f: float = float(i) / 23.0
		var p: Vector2 = _quad(p0, p1, p2, f)
		var r: float = 11.0 - 4.5 * f
		_disc(img, p.x, p.y, r, trunk)
		_disc(img, p.x - r * 0.45, p.y, r * 0.42, trunk_l)
	for i in range(8):
		var f: float = float(i) / 8.0
		var p: Vector2 = _quad(p0, p1, p2, f)
		_disc(img, p.x, p.y + 1.0, 6.0 - 3.0 * f, trunk_d)

	var crown: Vector2 = p2
	for i in range(8):
		var ang: float = deg_to_rad(-168.0 + 21.0 * float(i))
		var ln: float = 62.0 + 10.0 * float(i % 3)
		_frond(img, crown, ang, ln, 20.0 + 10.0 * float(i % 2), frond, frond_l)
	# Kokosnuesse
	_disc(img, crown.x - 2.0, crown.y + 4.0, 7.0, OUTLINE)
	_disc(img, crown.x - 2.0, crown.y + 4.0, 5.0, Color(0.52, 0.36, 0.18))
	_disc(img, crown.x + 9.0, crown.y + 7.0, 6.0, OUTLINE)
	_disc(img, crown.x + 9.0, crown.y + 7.0, 4.0, Color(0.45, 0.30, 0.15))
	return ImageTexture.create_from_image(img)

func _make_jbush_leaf(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.04), int(c * 0.62), int(c * 0.10), SHADOW, true)
	_leaf_cluster(img, c, c * 0.72, c * 0.44)
	_leaf_cluster(img, c - c * 0.36, c * 0.94, c * 0.28)
	_leaf_cluster(img, c + c * 0.38, c * 0.90, c * 0.28)
	# grosse Blaetter
	var lf := Color(0.24, 0.58, 0.26)
	for i in range(5):
		var bx := c - c * 0.50 + float(i) * c * 0.26
		_tri(img, Vector2(bx, c * 1.34), Vector2(bx + c * 0.13, c * 0.52), Vector2(bx + c * 0.26, c * 1.34), lf)
	return ImageTexture.create_from_image(img)

func _make_jvine(size: int) -> ImageTexture:
	# Runde 56: Lianen mit Kontur und Blattpaaren entlang des Halms -
	# vorher waren es 2-px-Faeden mit lose schwebenden Dreiecken.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var v := Color(0.22, 0.54, 0.26)
	var vl := Color(0.36, 0.70, 0.32)
	for i in range(5):
		var px0: float = c - c * 0.44 + float(i) * c * 0.22
		var hh: float = c * (0.86 + 0.28 * float((i * 3) % 4) / 3.0)
		var sway: float = 3.5 if i % 2 == 0 else -3.5
		var steps: int = 7
		var prev := Vector2(px0, 0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(px0 + sway * f, hh * f)
			_thick_line(img, prev, p, 2.2, OUTLINE)
			prev = p
		prev = Vector2(px0, 0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(px0 + sway * f, hh * f)
			_thick_line(img, prev, p, 1.2, v if i % 2 == 0 else vl)
			prev = p
		for k in range(4):
			var f2: float = 0.18 + 0.20 * float(k)
			var bp := Vector2(px0 + sway * f2, hh * f2)
			var ll: float = c * (0.26 - 0.03 * float(k))
			_leaf(img, bp, bp + Vector2(-ll, -ll * 0.42), bp + Vector2(-ll * 0.18, ll * 0.30), v)
			_leaf(img, bp, bp + Vector2(ll, -ll * 0.30), bp + Vector2(ll * 0.18, ll * 0.42), vl)
	print("[JUNGLE][TEX] jvine neu gezeichnet (%dpx, 5 Ranken)" % size)
	return ImageTexture.create_from_image(img)

func _make_jmushroom(size: int, cap: Color) -> ImageTexture:
	# Runde 56: breiterer Hut, dickere Stielkante, Lamellenband - vorher
	# wirkte der Pilz wie ein kleiner brauner Klecks.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	_ellipse(img, int(c), int(size - c * 0.05), int(c * 0.56), int(c * 0.10), SHADOW, true)
	_rect(img, int(c - c * 0.16 - 2), int(c * 0.82), int(c * 0.32 + 4), int(c * 0.66), OUTLINE)
	_rect(img, int(c - c * 0.16), int(c * 0.84), int(c * 0.32), int(c * 0.62), Color(0.94, 0.90, 0.82))
	_rect(img, int(c - c * 0.16), int(c * 0.84), int(c * 0.10), int(c * 0.62), Color(0.80, 0.75, 0.66))
	_ellipse(img, int(c), int(c * 0.88), int(c * 0.74), int(c * 0.50), OUTLINE, true)
	_ellipse(img, int(c), int(c * 0.84), int(c * 0.68), int(c * 0.44), cap, true)
	_ellipse(img, int(c), int(c * 1.16), int(c * 0.60), int(c * 0.10), Color(0.86, 0.80, 0.68))
	_disc(img, int(c - c * 0.30), int(c * 0.56), int(c * 0.14), Color(1, 1, 1, 0.35))
	_disc(img, int(c - c * 0.24), int(c * 0.72), int(c * 0.10), Color(1, 1, 1, 0.9))
	_disc(img, int(c + c * 0.22), int(c * 0.80), int(c * 0.08), Color(1, 1, 1, 0.85))
	_disc(img, int(c + c * 0.02), int(c * 0.62), int(c * 0.07), Color(1, 1, 1, 0.7))
	print("[JUNGLE][TEX] jmushroom neu gezeichnet (%dpx)" % size)
	return ImageTexture.create_from_image(img)

func _make_jcrystal(size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var gem := Color(0.40, 0.80, 0.98)
	var gem_d := Color(0.22, 0.55, 0.85)
	_ellipse(img, int(c), int(size - c * 0.05), int(c * 0.62), int(c * 0.12), SHADOW, true)
	# drei Kristalle
	_tri(img, Vector2(c - c * 0.42, size - c * 0.12), Vector2(c - c * 0.28, c * 0.42), Vector2(c - c * 0.12, size - c * 0.12), OUTLINE)
	_tri(img, Vector2(c - c * 0.38, size - c * 0.16), Vector2(c - c * 0.28, c * 0.48), Vector2(c - c * 0.17, size - c * 0.16), gem_d)
	_tri(img, Vector2(c - c * 0.10, size - c * 0.10), Vector2(c + c * 0.06, c * 0.16), Vector2(c + c * 0.24, size - c * 0.10), OUTLINE)
	_tri(img, Vector2(c - c * 0.05, size - c * 0.15), Vector2(c + c * 0.06, c * 0.24), Vector2(c + c * 0.19, size - c * 0.15), gem)
	_tri(img, Vector2(c + c * 0.28, size - c * 0.14), Vector2(c + c * 0.42, c * 0.52), Vector2(c + c * 0.56, size - c * 0.14), OUTLINE)
	_tri(img, Vector2(c + c * 0.32, size - c * 0.18), Vector2(c + c * 0.42, c * 0.58), Vector2(c + c * 0.52, size - c * 0.18), gem_d)
	return ImageTexture.create_from_image(img)

func _make_bush_dot() -> ImageTexture:
	# Runde 25: echter Busch (drei ueberlappende gruene Kugeln mit Kontur)
	var img = _new_img(64, 64)
	var c := float(32)
	_ellipse(img, 32, 58, 20, 5, SHADOW, true)
	_outlined_disc(img, int(c - c * 0.30), int(44.0), 15, Color(0.18, 0.44, 0.19), 3)
	_outlined_disc(img, int(c + c * 0.30), int(42.0), 15, Color(0.18, 0.44, 0.19), 3)
	_outlined_disc(img, 32, 32, 18, Color(0.22, 0.52, 0.23), 3)
	_disc(img, 28, 26, 8, Color(0.34, 0.64, 0.28))
	_disc(img, 40, 30, 6, Color(0.30, 0.60, 0.26))
	return ImageTexture.create_from_image(img)

func _make_grass_tuft() -> ImageTexture:
	# Runde 25: GRUENES Grassbueschel (das weisse wurde im Spiel als weisse
	# Details/Schnee gelesen). Koerper gruen + dunkle Kontur.
	var img = _new_img(16, 22)
	var b1 := Color(0.28, 0.54, 0.22)
	var b2 := Color(0.40, 0.66, 0.29)
	var b3 := Color(0.24, 0.46, 0.19)
	for i in range(3):
		var x: int = 3 + i * 5
		var h: int = 13 + (i % 2) * 6
		_rect(img, x - 1, 22 - h, 4, h, OUTLINE)
		_rect(img, x, 22 - h + 1, 2, h - 2, b1 if i == 0 else (b2 if i == 1 else b3))
		_tri(img, Vector2(float(x - 1), float(22 - h)), Vector2(float(x + 2), float(22 - h - 5)), Vector2(float(x + 3), float(22 - h + 1)), b2)
	return ImageTexture.create_from_image(img)

func _make_bridge() -> ImageTexture:
	# Runde 23: klare Bruecke - Planken quer, seitliche Gelaender mit Pfosten,
	# Querbalken. Wird ueber die Kollisions-Insel gekachelt (texture_repeat).
	var img = _new_img(128, 96)
	var wood := Color(0.58, 0.40, 0.21)
	var wood_d := Color(0.45, 0.30, 0.15)
	var plank := Color(0.68, 0.49, 0.26)
	var dark := Color(0.34, 0.22, 0.11)
	# Planken (senkrecht, 8 Stueck)
	for i in range(8):
		var x: int = i * 16
		_rect(img, x, 12, 16, 72, OUTLINE)
		_rect(img, x + 1, 13, 14, 70, plank if i % 2 == 0 else wood_d)
	# seitliche Gelaender
	_rect(img, 0, 4, 128, 9, OUTLINE)
	_rect(img, 0, 6, 128, 5, wood)
	_rect(img, 0, 83, 128, 9, OUTLINE)
	_rect(img, 0, 85, 128, 5, wood)
	# Querbalken unter den Planken (Bruecken-Look)
	_rect(img, 0, 42, 128, 7, dark)
	# Pfosten
	for x in [4, 58, 114]:
		_rect(img, x, 0, 9, 96, OUTLINE)
		_rect(img, x + 1, 2, 7, 92, wood)
	return ImageTexture.create_from_image(img)

func _make_jreed(size: int) -> ImageTexture:
	# Runde 56: Schilf mit geschwungenen Halmen und Fahne - vorher waren es
	# fuenf gerade Striche ohne Kontur, die wie ein Strichcode wirkten.
	var img = _new_img(size, size)
	var c := float(size) / 2.0
	var st := Color(0.36, 0.60, 0.26)
	var st_l := Color(0.55, 0.76, 0.34)
	_ellipse(img, int(c), int(size - 5), int(c * 0.46), int(c * 0.08), SHADOW, true)
	for i in range(6):
		var bx: float = c - c * 0.34 + float(i) * c * 0.14
		var hh: float = c * (1.10 + 0.35 * float((i * 3) % 4) / 3.0)
		var topy: float = float(size) - hh - 4.0
		var sway: float = 7.0 if i % 2 == 0 else -7.0
		var steps: int = 8
		var prev := Vector2(bx, float(size) - 5.0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(bx + sway * f * f, float(size) - 5.0 - hh * f)
			_thick_line(img, prev, p, 2.6, OUTLINE)
			prev = p
		prev = Vector2(bx, float(size) - 5.0)
		for j in range(1, steps + 1):
			var f: float = float(j) / float(steps)
			var p := Vector2(bx + sway * f * f, float(size) - 5.0 - hh * f)
			_thick_line(img, prev, p, 1.6, st if i % 2 == 0 else st_l)
			prev = p
		var tip := Vector2(bx + sway, topy)
		_leaf(img, tip, tip + Vector2(-7, -10), tip + Vector2(-2, 2), st)
		_leaf(img, tip, tip + Vector2(7, -12), tip + Vector2(2, 1), st_l)
		_leaf(img, tip, tip + Vector2(0, -14), tip + Vector2(2, 0), st)
	print("[JUNGLE][TEX] jreed neu gezeichnet (%dpx, 6 Halme)" % size)
	return ImageTexture.create_from_image(img)

func _make_jrock(size: int) -> ImageTexture:
	# Runde 56: facettierter Fels statt glatter grauer Kiesel
	var img = _new_img(size, size)
	var f := float(size)
	var base := Color(0.48, 0.52, 0.50)
	var light := Color(0.64, 0.68, 0.63)
	var dark := Color(0.33, 0.37, 0.37)
	_ellipse(img, int(f * 0.50), int(f * 0.86), int(f * 0.44), int(f * 0.11), SHADOW, true)
	_outlined_ellipse(img, int(f * 0.50), int(f * 0.62), int(f * 0.38), int(f * 0.28), base, 3)
	_tri(img, Vector2(f * 0.54, f * 0.36), Vector2(f * 0.80, f * 0.60), Vector2(f * 0.46, f * 0.58), light)
	_tri(img, Vector2(f * 0.54, f * 0.36), Vector2(f * 0.46, f * 0.58), Vector2(f * 0.30, f * 0.44), Color(0.55, 0.59, 0.56))
	_tri(img, Vector2(f * 0.26, f * 0.66), Vector2(f * 0.44, f * 0.82), Vector2(f * 0.30, f * 0.82), dark)
	_disc(img, int(f * 0.64), int(f * 0.78), int(f * 0.11), Color(0.30, 0.50, 0.27))
	_disc(img, int(f * 0.72), int(f * 0.73), int(f * 0.06), Color(0.36, 0.58, 0.30))
	print("[JUNGLE][TEX] jrock neu gezeichnet (%dpx, facettiert)" % size)
	return ImageTexture.create_from_image(img)

func _make_jflower(size: int, petal := Color(0.98, 0.96, 0.92), petal_d := Color(0.86, 0.84, 0.80),
		center := Color(0.98, 0.72, 0.24)) -> ImageTexture:
	# Runde 56: Blume mit Kontur, Stiel und Blatt - vorher nur fünf weisse
	# Kreise ohne Rand, bei Spielgroesse nicht als Bluete lesbar.
	# Runde 58: Farbvarianten (weiss/pink/gelb) fuer Farbakzente in der Karte.
	var img = _new_img(size, size)
	var f := float(size)
	var stem := Color(0.26, 0.56, 0.26)
	var cx: float = f * 0.50
	var cy: float = f * 0.40
	_rect(img, int(cx) - 2, int(cy), 5, int(f * 0.52), OUTLINE)
	_rect(img, int(cx) - 1, int(cy), 3, int(f * 0.50), stem)
	_leaf(img, Vector2(cx + 1.0, cy + f * 0.30), Vector2(cx + f * 0.26, cy + f * 0.14), Vector2(cx + f * 0.04, cy + f * 0.36), stem)
	for i in range(5):
		var a: float = TAU * float(i) / 5.0 - PI * 0.5
		var px: float = cx + cos(a) * f * 0.20
		var py: float = cy + sin(a) * f * 0.20
		_disc(img, px, py, f * 0.16, OUTLINE)
		_disc(img, px, py, f * 0.135, petal if i % 2 == 0 else petal_d)
	_disc(img, cx, cy, f * 0.105, OUTLINE)
	_disc(img, cx, cy, f * 0.085, center)
	print("[JUNGLE][TEX] jflower neu gezeichnet (%dpx, %s)" % [size, str(petal)])
	return ImageTexture.create_from_image(img)

func _make_robo_ape() -> ImageTexture:
	# Runde 18: echter Gorilla-Umriss (breite Schultern, lange Arme im
	# Knoechelgang, Schnauze, Ohren) + Robo-Teile + Banane in der Hand
	var img = _new_img(80, 80)
	var fur := Color(0.40, 0.32, 0.28)
	var fur_d := Color(0.26, 0.20, 0.18)
	var metal := Color(0.72, 0.76, 0.82)
	var face := Color(0.80, 0.68, 0.56)
	var eye := Color(0.95, 0.35, 0.30)
	var banana := Color(0.98, 0.85, 0.30)
	_ellipse(img, 40, 75, 22, 5, SHADOW, true)
	# Beine (kurz)
	_outlined_ellipse(img, 29, 65, 7, 8, fur_d, 2)
	_outlined_ellipse(img, 51, 65, 7, 8, fur_d, 2)
	# Rumpf: breite Schultern, schmaler unten
	_outlined_ellipse(img, 40, 46, 18, 16, fur, 3)
	_outlined_ellipse(img, 40, 50, 13, 12, fur_d, 2)
	# Metall-Brustplatte
	_outlined_ellipse(img, 40, 44, 10, 10, metal, 2)
	_disc(img, 40, 44, 3, Color(0.55, 0.95, 1.0))
	# lange Arme bis zum Boden
	_outlined_ellipse(img, 19, 55, 7, 16, fur, 2)
	_outlined_ellipse(img, 61, 55, 7, 16, fur, 2)
	_outlined_disc(img, 17, 71, 7, fur_d, 2)
	_outlined_disc(img, 63, 71, 7, fur_d, 2)
	# Kopf + Schnauze + Ohren
	_outlined_disc(img, 40, 28, 14, fur, 3)
	_outlined_ellipse(img, 40, 33, 9, 6, face, 2)
	_px(img, 37, 30, OUTLINE)
	_px(img, 43, 30, OUTLINE)
	_rect(img, 36, 35, 8, 2, OUTLINE)
	_outlined_disc(img, 25, 25, 4, fur_d, 2)
	_outlined_disc(img, 55, 25, 4, fur_d, 2)
	# Robo-Auge + Antenne
	_outlined_disc(img, 40, 23, 3, eye, 1)
	_rect(img, 39, 12, 2, 5, OUTLINE)
	_disc(img, 40, 11, 3, eye)
	# Banane in der rechten Hand
	_tri(img, Vector2(63, 62), Vector2(77, 70), Vector2(64, 77), banana)
	_tri(img, Vector2(64, 68), Vector2(75, 72), Vector2(65, 78), Color(0.86, 0.72, 0.24))
	return ImageTexture.create_from_image(img)


# ============================================================
# Runde 26: Boss-Redesign nach Nutzerwunsch
# ============================================================

func _make_boss_jungle() -> ImageTexture:
	# MUTIERTER HALB-ROBOTER-GORILLA (Jungle): Gorilla-Koerper wie der Bananen-Affe,
	# aber eine Roboter-Schulter + Roboterarm mit Kralle, rotes Robo-Auge, Kabel,
	# Banane in der Hand.
	var img = _new_img(320, 320)
	var fur := Color(0.34, 0.26, 0.22)
	var fur_d := Color(0.22, 0.16, 0.14)
	var metal := Color(0.70, 0.74, 0.80)
	var metal_d := Color(0.44, 0.48, 0.55)
	var glow := Color(0.95, 0.30, 0.25)
	var face := Color(0.74, 0.62, 0.50)
	var banana := Color(0.98, 0.85, 0.30)
	_ellipse(img, 160, 296, 96, 20, SHADOW, true)
	_outlined_ellipse(img, 118, 250, 30, 34, fur_d, 4)
	_outlined_ellipse(img, 202, 250, 30, 34, metal_d, 4)
	_outlined_ellipse(img, 160, 178, 74, 66, fur, 6)
	_outlined_ellipse(img, 160, 196, 52, 48, fur_d, 4)
	_outlined_ellipse(img, 160, 172, 44, 42, metal, 5)
	_disc(img, 160, 172, 14, glow)
	_disc(img, 154, 166, 6, Color(1, 1, 1, 0.85))
	_outlined_ellipse(img, 96, 150, 40, 34, metal, 5)
	for i in range(3):
		_disc(img, 78 + i * 16, 136, 4, metal_d)
	_outlined_ellipse(img, 232, 214, 28, 62, fur, 5)
	_outlined_disc(img, 236, 278, 28, fur_d, 5)
	_outlined_ellipse(img, 88, 214, 24, 60, metal, 5)
	_outlined_disc(img, 84, 274, 24, metal_d, 5)
	for i in range(3):
		_tri(img, Vector2(float(64 + i * 16), 284.0), Vector2(float(58 + i * 16), 306.0), Vector2(float(74 + i * 16), 288.0), metal)
	_outlined_disc(img, 160, 100, 56, fur, 6)
	_outlined_ellipse(img, 160, 118, 36, 24, face, 4)
	_rect(img, 144, 126, 32, 6, OUTLINE)
	_outlined_disc(img, 100, 92, 16, fur_d, 4)
	_outlined_disc(img, 220, 92, 16, fur_d, 4)
	_outlined_disc(img, 140, 92, 10, Color(0.95, 0.95, 0.92), 3)
	_disc(img, 140, 92, 4, OUTLINE)
	_outlined_disc(img, 184, 92, 14, glow, 4)
	_disc(img, 184, 92, 6, Color(1.0, 0.75, 0.6))
	# Kabel kompakt unter der Schulterplatte (wirkten vorher aufgeklebt)
	for i in range(3):
		_rect(img, 112 + i * 7, 132 + i * 3, 4, 18, Color(0.20, 0.50, 0.40))
	_rect(img, 206, 44, 5, 34, OUTLINE)
	_disc(img, 208, 42, 7, glow)
	# Banane als klare ovale Form IN der rechten Faust (Dreieck wirkte wie eine Flosse)
	_outlined_ellipse(img, 240, 258, 30, 12, banana, 3)
	_disc(img, 214, 262, 4, Color(0.62, 0.48, 0.16))
	_disc(img, 266, 254, 4, Color(0.62, 0.48, 0.16))
	_ellipse(img, 238, 252, 16, 4, Color(1.0, 0.95, 0.6, 0.75), true)
	return ImageTexture.create_from_image(img)

func _make_boss_mars() -> ImageTexture:
	# MUTIERTER ALIEN-ROBOTER (Mars): grosser Alien-Schaedel mit schraegen Augen
	# auf einem Maschinenkoerper mit Leuchtkern, Krallehänden, Antennen, Kabeln.
	var img = _new_img(320, 320)
	var skin := Color(0.62, 0.76, 0.60)
	var skin_d := Color(0.44, 0.58, 0.44)
	var metal := Color(0.72, 0.70, 0.66)
	var metal_d := Color(0.46, 0.44, 0.42)
	var eye := Color(0.08, 0.06, 0.10)
	var core := Color(1.0, 0.55, 0.20)
	var rust := Color(0.62, 0.34, 0.24)
	_ellipse(img, 160, 298, 100, 20, SHADOW, true)
	_outlined_ellipse(img, 160, 262, 74, 34, metal, 5)
	_outlined_ellipse(img, 160, 272, 56, 22, metal_d, 4)
	_outlined_ellipse(img, 160, 190, 62, 54, metal, 6)
	_outlined_ellipse(img, 160, 196, 42, 36, rust, 4)
	_outlined_disc(img, 160, 190, 22, core, 4)
	_disc(img, 160, 190, 10, Color(1, 1, 1, 0.8))
	_outlined_ellipse(img, 92, 168, 30, 26, metal, 5)
	_outlined_ellipse(img, 228, 168, 30, 26, metal, 5)
	_outlined_ellipse(img, 78, 214, 20, 50, metal_d, 5)
	_outlined_ellipse(img, 242, 214, 20, 50, metal_d, 5)
	for s in [-1, 1]:
		for i in range(3):
			var bx: float = 160.0 + float(s * 84) + float((i - 1) * 14)
			_tri(img, Vector2(bx, 260.0), Vector2(bx + float(s * 6), 286.0), Vector2(bx + float(s * 14), 262.0), metal)
	_rect(img, 146, 118, 28, 26, OUTLINE)
	_rect(img, 150, 120, 20, 24, skin_d)
	_outlined_ellipse(img, 160, 76, 62, 46, skin, 6)
	_outlined_ellipse(img, 160, 92, 44, 26, skin_d, 4)
	for s2 in [-1, 1]:
		var ex: int = 160 + s2 * 30
		_outlined_ellipse(img, ex, 78, 20, 12, eye, 3)
		_disc(img, ex - s2 * 5, 74, 4, Color(0.95, 0.98, 1.0, 0.9))
	_rect(img, 144, 104, 32, 4, OUTLINE)
	for i in range(2):
		_rect(img, 138 + i * 40, 22, 4, 26, OUTLINE)
		_disc(img, 140 + i * 40, 20, 6, core)
	for i in range(4):
		_rect(img, 122 + i * 12, 116, 6, 22, Color(0.35, 0.30, 0.28))
	return ImageTexture.create_from_image(img)


# ============================================================
# Runde 27: Mini-Bosse (alle 5 Wellen) - je Biom ein eigenes Design
# ============================================================

func _make_mini_jungle() -> ImageTexture:
	# ROBOTER-PAPAGEI (Jungle): gruenlich schimmerndes Metall, Haken-Schnabel,
	# Federkamm, rotes Robo-Auge, ausgebreitete Metallfluegel, Krallenfuesse.
	var img = _new_img(224, 224)
	var metal := Color(0.28, 0.60, 0.48)
	var metal_d := Color(0.16, 0.38, 0.32)
	var steel := Color(0.72, 0.76, 0.82)
	var steel_d := Color(0.46, 0.50, 0.56)
	var beak := Color(0.98, 0.62, 0.20)
	var glow := Color(0.95, 0.25, 0.22)
	_ellipse(img, 112, 208, 62, 12, SHADOW, true)
	# Schwanzfedern (Metall)
	_tri(img, Vector2(104.0, 150.0), Vector2(46.0, 196.0), Vector2(78.0, 168.0), steel)
	_tri(img, Vector2(110.0, 156.0), Vector2(58.0, 208.0), Vector2(86.0, 176.0), steel_d)
	_tri(img, Vector2(116.0, 152.0), Vector2(70.0, 210.0), Vector2(94.0, 178.0), steel)
	# Fluügel
	for s in [-1, 1]:
		var sx: float = float(s)
		_tri(img, Vector2(118.0 + sx * 30.0, 122.0), Vector2(118.0 + sx * 80.0, 104.0), Vector2(118.0 + sx * 62.0, 170.0), steel)
		_tri(img, Vector2(118.0 + sx * 34.0, 128.0), Vector2(118.0 + sx * 72.0, 118.0), Vector2(118.0 + sx * 58.0, 160.0), steel_d)
	# Koerper + Brustplatte mit Leuchtlicht + Metallnieten
	_outlined_ellipse(img, 118, 140, 46, 40, metal, 5)
	for i in range(3):
		_disc(img, 92, 122 + i * 18, 3, steel_d)
		_disc(img, 144, 122 + i * 18, 3, steel_d)
	_outlined_ellipse(img, 120, 150, 24, 20, steel, 4)
	_disc(img, 120, 150, 7, glow)
	# Kopf + Kamm
	_outlined_disc(img, 126, 92, 30, metal, 5)
	_tri(img, Vector2(104.0, 70.0), Vector2(110.0, 36.0), Vector2(122.0, 70.0), steel)
	_tri(img, Vector2(118.0, 66.0), Vector2(126.0, 30.0), Vector2(136.0, 66.0), glow)
	_tri(img, Vector2(132.0, 68.0), Vector2(144.0, 40.0), Vector2(150.0, 70.0), steel)
	# Rot leuchtendes Robo-Auge
	_outlined_disc(img, 138, 88, 12, glow, 3)
	_disc(img, 138, 88, 6, Color(0.30, 0.04, 0.06))
	_disc(img, 135, 85, 3, Color(1.0, 0.92, 0.88))
	# Haken-Schnabel (Ober- + Unterschnabel als Haken)
	_tri(img, Vector2(146.0, 92.0), Vector2(188.0, 100.0), Vector2(148.0, 108.0), beak)
	_tri(img, Vector2(148.0, 104.0), Vector2(180.0, 110.0), Vector2(158.0, 128.0), beak)
	_tri(img, Vector2(156.0, 116.0), Vector2(174.0, 110.0), Vector2(162.0, 126.0), Color(0.78, 0.40, 0.08))
	# Beine + Krallen
	_rect(img, 96, 170, 10, 30, metal_d)
	_rect(img, 130, 170, 10, 30, metal_d)
	for s2 in [-1, 1]:
		var ox: float = 0.0 if s2 < 0 else 34.0
		_tri(img, Vector2(84.0 + ox, 198.0), Vector2(100.0 + ox, 216.0), Vector2(114.0 + ox, 198.0), steel)
	# Antenne
	_rect(img, 150, 56, 4, 24, OUTLINE)
	_disc(img, 152, 54, 6, glow)
	return ImageTexture.create_from_image(img)

func _make_mini_mars() -> ImageTexture:
	# ROBOTER-SONDE (Mars): schwebender Kugelkoerper mit grosser Linse,
	# Panzerring, Sensorarmen, Antenne, Triebwerksflamme.
	var img = _new_img(224, 224)
	var metal := Color(0.74, 0.72, 0.68)
	var metal_d := Color(0.44, 0.42, 0.40)
	var rust := Color(0.64, 0.36, 0.26)
	var lens := Color(1.0, 0.58, 0.18)
	var glow := Color(0.95, 0.30, 0.25)
	_ellipse(img, 112, 202, 56, 12, SHADOW, true)
	# Triebwerksflamme
	_tri(img, Vector2(94.0, 170.0), Vector2(130.0, 170.0), Vector2(112.0, 212.0), Color(1.0, 0.62, 0.24, 0.85))
	# Sensorarme
	_rect(img, 30, 110, 32, 10, metal_d)
	_rect(img, 162, 110, 32, 10, metal_d)
	_disc(img, 28, 115, 10, metal)
	_disc(img, 196, 115, 10, metal)
	# Kugelkoerper + Panzerring
	_outlined_disc(img, 112, 116, 52, metal, 6)
	_outlined_ellipse(img, 112, 116, 52, 18, rust, 4)
	# Grosse Linse
	_outlined_disc(img, 112, 110, 27, metal_d, 5)
	_outlined_disc(img, 112, 110, 18, lens, 4)
	_disc(img, 106, 104, 7, Color(1, 1, 1, 0.9))
	# Antenne + Seitenlichter
	_rect(img, 110, 34, 5, 30, OUTLINE)
	_disc(img, 112, 32, 7, glow)
	_disc(img, 72, 78, 5, glow)
	_disc(img, 152, 78, 5, glow)
	return ImageTexture.create_from_image(img)

func _thick_line(img: Image, a: Vector2, b: Vector2, r: float, c: Color) -> void:
	# Runde 54: dicke Linie als Disc-Kette (es gibt keinen Linien-Helfer)
	var n: int = maxi(2, int(a.distance_to(b) / maxf(1.0, r * 0.55)))
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(n))
		_disc(img, p.x, p.y, r, c)


func _make_mini_volt() -> ImageTexture:
	# Runde 54: VOLT-SPULE - lebende Teslaspule fuer die Elektro-Karte.
	# Drei Isolatoren, gewickelter Koerper, cyaner Kern (schwacher Punkt),
	# zwei violette Spitzen mit Lichtbogen.
	var img = _new_img(224, 224)
	var body := Color(0.23, 0.25, 0.39)
	var metal := Color(0.35, 0.37, 0.48)
	var metal_l := Color(0.49, 0.53, 0.66)
	var core := Color(0.31, 0.85, 1.0)
	var core_l := Color(0.87, 0.96, 1.0)
	var vio := Color(0.64, 0.42, 1.0)

	_ellipse(img, 112, 206, 60, 11, SHADOW, true)

	# Drei Isolatoren als Beine
	for lx in [76, 140, 108]:
		_rect(img, lx - 2, 170, 20, 36, OUTLINE)
		_rect(img, lx, 172, 16, 32, metal)
		_disc(img, lx + 8, 208, 9, OUTLINE)
		_disc(img, lx + 8, 208, 6, metal_l)

	# Spulenkoerper (Kapsel)
	_rect(img, 78, 84, 68, 96, OUTLINE)
	_disc(img, 112, 84, 34, OUTLINE)
	_disc(img, 112, 180, 34, OUTLINE)
	_rect(img, 84, 84, 56, 96, body)
	_disc(img, 112, 84, 28, body)
	_disc(img, 112, 180, 28, body)

	# Windungen
	for wy in [96, 122, 148, 174]:
		_ellipse(img, 112, wy, 42, 12, metal_l)
		_ellipse(img, 112, wy, 33, 6, body)

	# Kern = schwacher Punkt
	_disc(img, 112, 138, 30, OUTLINE)
	_disc(img, 112, 138, 26, core)
	_disc(img, 112, 138, 11, core_l)
	_disc(img, 104, 130, 4, Color(1, 1, 1, 0.9), true)

	# Kopfkappe
	_rect(img, 96, 56, 32, 32, OUTLINE)
	_rect(img, 100, 59, 24, 26, metal)

	# Spitzen
	_thick_line(img, Vector2(103, 70), Vector2(78, 34), 6, metal_l)
	_thick_line(img, Vector2(121, 70), Vector2(146, 34), 6, metal_l)
	_disc(img, 78, 32, 12, OUTLINE)
	_disc(img, 78, 32, 8, vio)
	_disc(img, 146, 32, 12, OUTLINE)
	_disc(img, 146, 32, 8, vio)

	# Lichtbogen zwischen den Spitzen
	_thick_line(img, Vector2(86, 28), Vector2(98, 40), 2, core_l)
	_thick_line(img, Vector2(98, 40), Vector2(88, 46), 2, core_l)
	_thick_line(img, Vector2(88, 46), Vector2(106, 58), 2, core_l)
	_thick_line(img, Vector2(138, 28), Vector2(126, 40), 2, core)
	_thick_line(img, Vector2(126, 40), Vector2(136, 46), 2, core)
	_thick_line(img, Vector2(136, 46), Vector2(118, 58), 2, core)

	# Sensor-Schlitze
	_rect(img, 104, 64, 8, 3, core_l)
	_rect(img, 116, 64, 8, 3, core_l)

	return ImageTexture.create_from_image(img)


func _make_mini_earth() -> ImageTexture:
	# ROBOTER-KAEFER (Erde): Halbkugel-Panzer mit Naht und Nieten, SECHS klar
	# getrennte Beine, Fuehler, zwei Leuchtaugen, deutliche Rueckenkanone.
	var img = _new_img(224, 224)
	var shell := Color(0.42, 0.52, 0.72)
	var shell_d := Color(0.24, 0.32, 0.50)
	var metal := Color(0.76, 0.78, 0.82)
	var metal_d := Color(0.50, 0.52, 0.58)
	var glow := Color(0.98, 0.72, 0.20)
	var glow2 := Color(0.95, 0.30, 0.25)
	_ellipse(img, 112, 208, 70, 12, SHADOW, true)
	# SECHS Beine (drei je Seite, untereinander versetzt)
	for s in [-1, 1]:
		var sx: float = float(s)
		for i in range(3):
			var ly: int = 112 + i * 30
			var lx: int = 112 + int(sx * (62.0 + float(i) * 6.0))
			_rect(img, lx - (8 if s < 0 else 0), ly, 18, 13, metal_d)
			_rect(img, lx + int(sx * 13.0) - (8 if s < 0 else 0), ly + 11, 12, 28, metal)
			_disc(img, lx + int(sx * 21.0), ly + 43, 8, metal)
	# Panzer (Halbkugel) + mittlere Naht + Platten mit Nieten
	_outlined_ellipse(img, 112, 134, 66, 48, shell, 6)
	_rect(img, 108, 88, 8, 92, shell_d)
	_outlined_ellipse(img, 74, 142, 20, 26, shell_d, 3)
	_outlined_ellipse(img, 150, 142, 20, 26, shell_d, 3)
	for i in range(3):
		_disc(img, 62, 128 + i * 14, 3, metal)
		_disc(img, 162, 128 + i * 14, 3, metal)
	# Kopf + Sensor-Spalten + Fuehler
	# Runde 49c: Zwei runde, gelbe Scheiben MIT dunkler Pupille lasen
	# sich als grosses Gesichts-Auge. Jetzt: schmale waagerechte
	# Sensor-Spalten ohne Pupille - das bleibt ein Kafer-Rig.
	_outlined_disc(img, 112, 84, 28, metal, 5)
	_rect(img, 88, 78, 18, 6, OUTLINE)
	_rect(img, 89, 79, 16, 4, glow)
	_rect(img, 118, 78, 18, 6, OUTLINE)
	_rect(img, 119, 79, 16, 4, glow)
	# Kleine Warnleuchte in der Mitte statt eines dritten Auges
	_rect(img, 109, 76, 6, 4, OUTLINE)
	_rect(img, 110, 77, 4, 2, glow2)
	_rect(img, 94, 42, 4, 26, OUTLINE)
	_rect(img, 126, 42, 4, 26, OUTLINE)
	_disc(img, 96, 40, 6, glow)
	_disc(img, 128, 40, 6, glow)
	# Rueckenkanone (Sockel + Turm + Rohr + Muendung) - deutlich auf dem Panzer
	_rect(img, 148, 88, 44, 16, metal_d)
	_rect(img, 162, 58, 24, 32, metal)
	_rect(img, 170, 36, 9, 24, metal_d)
	_disc(img, 174, 34, 9, glow2)
	_disc(img, 174, 34, 3, Color(1.0, 0.9, 0.6))
	return ImageTexture.create_from_image(img)

func _make_arrow_marker() -> ImageTexture:
	# Runde 31: Richtungspfeil zum letzten Monster (zeigt nach OBEN, wird gedreht)
	var img = _new_img(64, 64)
	_tri(img, Vector2(32.0, 4.0), Vector2(61.0, 42.0), Vector2(3.0, 42.0), OUTLINE)
	_tri(img, Vector2(32.0, 12.0), Vector2(54.0, 39.0), Vector2(10.0, 39.0), Color(1.0, 0.55, 0.12))
	_tri(img, Vector2(32.0, 20.0), Vector2(46.0, 35.0), Vector2(18.0, 35.0), Color(1.0, 0.86, 0.38))
	_rect(img, 25, 38, 14, 22, OUTLINE)
	_rect(img, 28, 40, 8, 18, Color(1.0, 0.72, 0.22))
	return ImageTexture.create_from_image(img)


func _make_boss_earth() -> ImageTexture:
	# Runde 34: MUTIERTER KRISTALL-ROBOTER (Erde-Riesenboss) - Panzerstand mit
	# leuchtendem Kristallkern, Kristallklinge, Schulterkristalle, Kristallkrone.
	var img = _new_img(320, 320)
	var stone := Color(0.44, 0.46, 0.52)
	var stone_d := Color(0.24, 0.26, 0.32)
	var crystal := Color(0.42, 0.82, 0.98)
	var crystal_d := Color(0.18, 0.48, 0.72)
	var glow := Color(0.60, 0.96, 1.0)
	_ellipse(img, 160, 298, 92, 20, SHADOW, true)
	_outlined_ellipse(img, 116, 250, 30, 36, stone_d, 4)
	_outlined_ellipse(img, 204, 250, 30, 36, stone_d, 4)
	_outlined_ellipse(img, 160, 178, 70, 64, stone, 6)
	_outlined_ellipse(img, 160, 186, 50, 44, stone_d, 4)
	# Kristallkern in der Brust
	_tri(img, Vector2(160.0, 136.0), Vector2(198.0, 198.0), Vector2(122.0, 198.0), OUTLINE)
	_tri(img, Vector2(160.0, 145.0), Vector2(190.0, 193.0), Vector2(130.0, 193.0), crystal)
	_tri(img, Vector2(160.0, 152.0), Vector2(173.0, 190.0), Vector2(147.0, 190.0), glow)
	# Schulterkristalle
	for s in [-1, 1]:
		var sx: float = float(s)
		_tri(img, Vector2(160.0 + sx * 52.0, 130.0), Vector2(160.0 + sx * 88.0, 98.0), Vector2(160.0 + sx * 78.0, 152.0), OUTLINE)
		_tri(img, Vector2(160.0 + sx * 54.0, 134.0), Vector2(160.0 + sx * 82.0, 106.0), Vector2(160.0 + sx * 74.0, 148.0), crystal)
	# Arme
	_outlined_ellipse(img, 92, 202, 26, 58, stone, 5)
	_outlined_ellipse(img, 228, 202, 26, 58, stone, 5)
	# Kristallklinge
	_tri(img, Vector2(236.0, 192.0), Vector2(302.0, 118.0), Vector2(262.0, 216.0), OUTLINE)
	_tri(img, Vector2(243.0, 193.0), Vector2(295.0, 128.0), Vector2(265.0, 210.0), crystal)
	_tri(img, Vector2(250.0, 195.0), Vector2(285.0, 140.0), Vector2(265.0, 203.0), glow)
	# Kopf + Kristallkrone
	_outlined_disc(img, 160, 96, 40, stone, 6)
	for i in range(5):
		var ang: float = -PI * 0.88 + float(i) * 0.44
		var bx: float = 160.0 + cos(ang) * 34.0
		var by: float = 96.0 + sin(ang) * 34.0
		_tri(img, Vector2(bx, by), Vector2(bx + cos(ang) * 30.0, by + sin(ang) * 30.0),
			Vector2(bx + cos(ang + 1.3) * 15.0, by + sin(ang + 1.3) * 15.0), crystal_d)
	_outlined_disc(img, 146, 96, 9, glow, 3)
	_outlined_disc(img, 174, 96, 9, glow, 3)
	_disc(img, 146, 96, 3, OUTLINE)
	_disc(img, 174, 96, 3, OUTLINE)
	# Runde 34b: leuchtende Kristallrisse im Stein + Halo um den Kern
	_ellipse(img, 160, 170, 74, 62, Color(0.35, 0.75, 1.0, 0.16), true)
	for cr in [[Vector2(108.0, 150.0), Vector2(96.0, 206.0), Vector2(116.0, 198.0)],
			[Vector2(214.0, 152.0), Vector2(226.0, 208.0), Vector2(204.0, 200.0)],
			[Vector2(160.0, 206.0), Vector2(154.0, 240.0), Vector2(168.0, 238.0)]]:
		_tri(img, cr[0], cr[1], cr[2], crystal_d)
		_tri(img, cr[0], cr[1], cr[2], Color(0.45, 0.85, 1.0, 0.75))
	# Nieten auf den Armen
	for i in range(3):
		_disc(img, 82, 186 + i * 16, 4, stone_d)
		_disc(img, 238, 186 + i * 16, 4, stone_d)
	# Groessere Kristallkrone
	for i in range(5):
		var ang2: float = -PI * 0.92 + float(i) * 0.46
		var bx2: float = 160.0 + cos(ang2) * 36.0
		var by2: float = 96.0 + sin(ang2) * 36.0
		_tri(img, Vector2(bx2, by2), Vector2(bx2 + cos(ang2) * 40.0, by2 + sin(ang2) * 40.0),
			Vector2(bx2 + cos(ang2 + 1.3) * 20.0, by2 + sin(ang2 + 1.3) * 20.0), OUTLINE)
		_tri(img, Vector2(bx2 + cos(ang2) * 4.0, by2 + sin(ang2) * 4.0),
			Vector2(bx2 + cos(ang2) * 36.0, by2 + sin(ang2) * 36.0),
			Vector2(bx2 + cos(ang2 + 1.3) * 16.0, by2 + sin(ang2 + 1.3) * 16.0), crystal)
	return ImageTexture.create_from_image(img)


# ============================================================
# Runde 35: ELEKTRO-WELT - Sturmland aus Stahl und Strom
# ============================================================

func _make_volt_pylon() -> ImageTexture:
	# Teslaspule: Sockel + Wickelringe + leuchtende Kugel
	var img = _new_img(96, 128)
	var steel := Color(0.42, 0.46, 0.56)
	var steel_d := Color(0.22, 0.25, 0.34)
	var glow := Color(1.0, 0.88, 0.30)
	_ellipse(img, 48, 120, 34, 10, SHADOW, true)
	_outlined_ellipse(img, 48, 108, 30, 18, steel_d, 4)
	_rect(img, 40, 44, 16, 70, OUTLINE)
	_rect(img, 42, 46, 12, 66, steel)
	for i in range(4):
		_outlined_ellipse(img, 48, 96 - i * 16, 20 - i * 2, 7, steel_d, 3)
	_outlined_disc(img, 48, 30, 15, glow, 4)
	_disc(img, 48, 30, 7, Color(1, 1, 0.85))
	_tri(img, Vector2(44.0, 40.0), Vector2(52.0, 20.0), Vector2(56.0, 42.0), Color(1.0, 0.92, 0.5, 0.7))
	return ImageTexture.create_from_image(img)

func _make_volt_capacitor() -> ImageTexture:
	# Energieblock mit Blitz-Symbol
	var img = _new_img(80, 80)
	var steel := Color(0.46, 0.52, 0.64)
	var steel_d := Color(0.24, 0.28, 0.38)
	var glow := Color(1.0, 0.85, 0.25)
	_ellipse(img, 40, 72, 26, 8, SHADOW, true)
	_outlined_ellipse(img, 40, 40, 26, 30, steel, 4)
	_outlined_ellipse(img, 40, 40, 16, 18, steel_d, 3)
	_tri(img, Vector2(44.0, 20.0), Vector2(26.0, 44.0), Vector2(40.0, 44.0), glow)
	_tri(img, Vector2(40.0, 44.0), Vector2(58.0, 44.0), Vector2(44.0, 64.0), glow)
	_tri(img, Vector2(42.0, 26.0), Vector2(33.0, 42.0), Vector2(40.0, 42.0), Color(1, 1, 0.8))
	_tri(img, Vector2(42.0, 46.0), Vector2(51.0, 46.0), Vector2(43.0, 58.0), Color(1, 1, 0.8))
	return ImageTexture.create_from_image(img)

func _make_volt_spool() -> ImageTexture:
	# Kabeltrommel
	var img = _new_img(88, 88)
	var steel := Color(0.38, 0.42, 0.52)
	var steel_d := Color(0.20, 0.23, 0.30)
	var wire := Color(0.95, 0.78, 0.20)
	_ellipse(img, 44, 78, 32, 9, SHADOW, true)
	_outlined_disc(img, 44, 44, 34, steel_d, 4)
	_outlined_disc(img, 44, 44, 22, wire, 4)
	_outlined_disc(img, 44, 44, 10, steel, 3)
	for i in range(6):
		var a: float = float(i) * TAU / 6.0
		_rect(img, 44 + int(cos(a) * 18.0) - 2, 44 + int(sin(a) * 18.0) - 2, 5, 5, steel_d)
	return ImageTexture.create_from_image(img)

func _make_volt_wreck() -> ImageTexture:
	# Schrottroboter
	var img = _new_img(96, 96)
	var steel := Color(0.44, 0.48, 0.58)
	var steel_d := Color(0.22, 0.25, 0.33)
	var dead := Color(0.55, 0.20, 0.20)
	_ellipse(img, 48, 88, 32, 9, SHADOW, true)
	_outlined_ellipse(img, 46, 62, 30, 20, steel_d, 4)
	_outlined_disc(img, 68, 38, 16, steel, 4)
	_disc(img, 62, 36, 5, dead)
	_rect(img, 18, 48, 8, 34, steel_d)
	_rect(img, 74, 62, 8, 22, steel_d)
	_tri(img, Vector2(30.0, 34.0), Vector2(38.0, 12.0), Vector2(40.0, 36.0), Color(1.0, 0.85, 0.3, 0.8))
	_disc(img, 26, 24, 4, Color(1.0, 0.9, 0.4))
	return ImageTexture.create_from_image(img)

func _make_volt_antenna() -> ImageTexture:
	# Antennenmast mit Parabolschuessel
	var img = _new_img(96, 128)
	var steel := Color(0.40, 0.44, 0.54)
	var steel_d := Color(0.20, 0.23, 0.31)
	var warn := Color(1.0, 0.35, 0.30)
	_ellipse(img, 48, 120, 28, 9, SHADOW, true)
	_rect(img, 44, 40, 8, 80, OUTLINE)
	_rect(img, 46, 42, 4, 76, steel)
	for i in range(3):
		_rect(img, 34, 96 - i * 20, 28, 4, steel_d)
	_outlined_ellipse(img, 48, 30, 28, 12, steel, 4)
	_outlined_ellipse(img, 48, 26, 20, 8, steel_d, 3)
	_disc(img, 48, 18, 6, warn)
	return ImageTexture.create_from_image(img)

func _make_monster_volt_drone() -> ImageTexture:
	# Schwebende Drohne mit blitzkern
	var img = _new_img(64, 64)
	var steel := Color(0.46, 0.50, 0.60)
	var steel_d := Color(0.24, 0.27, 0.36)
	var glow := Color(1.0, 0.86, 0.28)
	_ellipse(img, 32, 56, 18, 6, SHADOW, true)
	_outlined_ellipse(img, 32, 30, 22, 16, steel, 4)
	_outlined_disc(img, 32, 30, 9, glow, 3)
	_disc(img, 29, 27, 4, Color(1, 1, 0.9))
	_rect(img, 8, 22, 12, 5, steel_d)
	_rect(img, 44, 22, 12, 5, steel_d)
	_tri(img, Vector2(26.0, 40.0), Vector2(20.0, 54.0), Vector2(32.0, 46.0), steel_d)
	_tri(img, Vector2(38.0, 40.0), Vector2(44.0, 54.0), Vector2(32.0, 46.0), steel_d)
	return ImageTexture.create_from_image(img)

func _make_monster_volt_trooper() -> ImageTexture:
	# Runde 49: SPULEN-TROOPER - ein starker Roboter mit gelbem
	# Spulenarm. vorher war er ein dunkler Block mit zwei gelben
	# Augen, der in der Menge unterging.
	var img = _new_img(64, 64)
	var steel := Color(0.66, 0.69, 0.78)
	var steel_d := Color(0.38, 0.41, 0.50)
	var steel_l := Color(0.86, 0.89, 0.96)
	var yellow := Color(1.0, 0.82, 0.24)
	var yellow_l := Color(1.0, 0.94, 0.60)
	_ellipse(img, 32, 58, 20, 6, SHADOW, true)
	# --- Beine (dick, gepanzert) ---
	for lx in [18, 30]:
		_rect(img, lx, 46, 10, 12, OUTLINE)
		_rect(img, lx + 1, 47, 8, 10, steel_d)
		_rect(img, lx, 55, 11, 3, OUTLINE)
	# --- Torso (breit, mit Brustplatte) ---
	_outlined_ellipse(img, 28, 38, 15, 16, steel, 3)
	_rect(img, 20, 32, 17, 10, steel_l)
	# Warnstreifen auf der Brust
	for x in range(20, 37):
		if (x + 32) % 6 < 3:
			img.set_pixel(x, 35, yellow)
	# Spulen-Kern in der Brust
	_outlined_disc(img, 28, 37, 5, yellow, 2)
	_disc(img, 27, 36, 2, yellow_l)
	# --- Kopf (mit Visier) ---
	_outlined_disc(img, 28, 18, 12, steel, 3)
	_rect(img, 19, 15, 19, 7, steel_d)
	_rect(img, 21, 17, 15, 3, yellow)
	_px(img, 24, 18, Color(1, 1, 1, 0.9))
	_px(img, 32, 18, Color(1, 1, 1, 0.9))
	# Antenne
	_rect(img, 28, 2, 2, 6, OUTLINE)
	_disc(img, 29, 2, 2, yellow)
	# --- Spulenarm rechts (die Signatur) ---
	_rect(img, 40, 24, 8, 20, OUTLINE)
	_rect(img, 41, 25, 6, 18, steel_d)
	# Spule am Arm
	_outlined_disc(img, 46, 46, 9, steel, 3)
	_outlined_disc(img, 46, 46, 5, yellow, 2)
	_disc(img, 45, 45, 2, yellow_l)
	# Stift daraus
	_tri(img, Vector2(44, 52), Vector2(38, 62), Vector2(48, 62), yellow)
	_tri(img, Vector2(45, 52), Vector2(41, 60), Vector2(47, 60), yellow_l)
	return ImageTexture.create_from_image(img)

func _make_monster_volt_spider() -> ImageTexture:
	# Runde 49: SPULEN-SPINNE - eigener Farbton (dunkles Violett mit
	# giftgruenem Kern), sonst war sie von der Drohne kaum zu
	# unterscheiden (beide dunkelgrau mit leuchtendem Kern).
	# Dazu deutliche Spinnenbeine in drei Paaren.
	var img = _new_img(64, 64)
	var steel := Color(0.44, 0.36, 0.58)
	var steel_d := Color(0.24, 0.19, 0.34)
	var steel_l := Color(0.64, 0.55, 0.78)
	var glow := Color(0.62, 1.0, 0.42)
	_ellipse(img, 32, 58, 22, 6, SHADOW, true)
	# --- Acht Beine: je vier pro Seite, gestaffelt ---
	for s2 in [-1, 1]:
		for i2 in range(4):
			var y: float = 24.0 + float(i2) * 8.0
			var x0: int = 32 + int(s2 * 12.0)
			var x1: int = 32 + int(s2 * 24.0) - (3 if s2 > 0 else 0)
			# Oberschenkel waagerecht
			_rect(img, min(x0, x1), int(y), abs(x1 - x0) + 3, 3, steel_d)
			# Fuss nach unten
			_rect(img, x1, int(y), 3, 9 if i2 % 2 == 0 else 6, steel_d)
			_rect(img, x1, int(y), 2, 8 if i2 % 2 == 0 else 5, steel)
	# --- Koerper (breiter, flacher) ---
	_outlined_ellipse(img, 32, 36, 17, 14, steel, 3)
	# --- GIFTKERN ---
	_outlined_disc(img, 32, 36, 8, glow, 3)
	_disc(img, 29, 33, 3, Color(0.92, 1.0, 0.80))
	# --- Segment-Fugen ---
	_rect(img, 24, 26, 16, 2, steel_l)
	_rect(img, 24, 44, 16, 2, steel_l)
	return ImageTexture.create_from_image(img)

func _make_boss_volt() -> ImageTexture:
	# Runde 35: DER STURMLEITER - Riesenroboter mit gewaltiger Teslaspule
	var img = _new_img(320, 320)
	var steel := Color(0.40, 0.44, 0.56)
	var steel_d := Color(0.20, 0.23, 0.32)
	var dark := Color(0.28, 0.31, 0.42)
	var glow := Color(1.0, 0.88, 0.30)
	var arc := Color(0.70, 0.95, 1.0)
	_ellipse(img, 160, 296, 96, 20, SHADOW, true)
	# Beine
	_outlined_ellipse(img, 112, 246, 32, 38, steel_d, 5)
	_outlined_ellipse(img, 208, 246, 32, 38, steel_d, 5)
	# Rumpf
	_outlined_ellipse(img, 160, 176, 76, 66, steel, 6)
	_outlined_ellipse(img, 160, 184, 54, 46, dark, 4)
	# Blitzkern
	_outlined_disc(img, 160, 168, 26, steel_d, 4)
	_outlined_disc(img, 160, 168, 17, glow, 3)
	_disc(img, 154, 162, 6, Color(1, 1, 0.92))
	# Grosse Spule auf dem Ruecken
	_outlined_ellipse(img, 160, 116, 52, 26, steel_d, 5)
	for i in range(5):
		_outlined_ellipse(img, 160, 132 - i * 14, 34 - i * 3, 8, steel, 3)
	_outlined_disc(img, 160, 74, 20, glow, 4)
	_disc(img, 160, 74, 9, Color(1, 1, 0.9))
	# Arme
	_outlined_ellipse(img, 82, 196, 26, 60, steel, 5)
	_outlined_ellipse(img, 238, 196, 26, 60, steel, 5)
	_outlined_disc(img, 82, 256, 20, steel_d, 4)
	_outlined_disc(img, 238, 256, 20, steel_d, 4)
	# Kopf mit leuchtendem Visier
	_outlined_disc(img, 160, 214, 34, dark, 5)
	_rect(img, 140, 206, 40, 10, glow)
	# Lichtbogen zwischen den Armen
	for i in range(5):
		var x0: float = 96.0 + float(i) * 30.0
		_tri(img, Vector2(x0, 150.0), Vector2(x0 + 12.0, 118.0), Vector2(x0 + 22.0, 156.0), Color(arc.r, arc.g, arc.b, 0.75))
	return ImageTexture.create_from_image(img)

func _make_monster(body: Color, highlight: Color, crown: bool = false) -> ImageTexture:
	var img = _new_img(56, 56)
	var cx := 28.0

	# Schatten
	_ellipse(img, cx, 48, 16, 5, SHADOW, true)
	# Füße
	_outlined_ellipse(img, 20, 43, 5, 3, body, 2)
	_outlined_ellipse(img, 36, 43, 5, 3, body, 2)
	# Körper (Blob)
	_outlined_ellipse(img, cx, 30, 16, 15, body, 3)
	# Glanz/Bauch
	_ellipse(img, cx, 34, 9, 7, highlight, true)
	# Krone beim Boss (gold) oder Hörner
	if crown:
		_tri(img, Vector2(10, 14), Vector2(10, 4), Vector2(17, 11), Color(0.3, 0.22, 0.02))
		_tri(img, Vector2(21, 11), Vector2(25, 2), Vector2(29, 11), Color(0.3, 0.22, 0.02))
		_tri(img, Vector2(35, 11), Vector2(39, 2), Vector2(43, 11), Color(0.3, 0.22, 0.02))
		_tri(img, Vector2(10, 12), Vector2(10, 6), Vector2(16, 11), Color(1.0, 0.84, 0.2))
		_tri(img, Vector2(21, 10), Vector2(25, 4), Vector2(29, 10), Color(1.0, 0.84, 0.2))
		_tri(img, Vector2(35, 10), Vector2(39, 4), Vector2(43, 10), Color(1.0, 0.84, 0.2))
		_rect(img, 10, 11, 25, 4, Color(0.3, 0.22, 0.02))
		_rect(img, 11, 12, 23, 2, Color(1.0, 0.84, 0.2))
	else:
		_tri(img, Vector2(13, 18), Vector2(9, 6), Vector2(20, 12), OUTLINE)
		_tri(img, Vector2(14, 16), Vector2(11, 8), Vector2(19, 12), Color(0.95, 0.92, 0.80))
		_tri(img, Vector2(43, 18), Vector2(47, 6), Vector2(36, 12), OUTLINE)
		_tri(img, Vector2(42, 16), Vector2(45, 8), Vector2(37, 12), Color(0.95, 0.92, 0.80))
	# Arme/Stummel
	_outlined_disc(img, 9, 30, 4, body, 2)
	_outlined_disc(img, 47, 30, 4, body, 2)
	# Augen weiß + Pupillen
	_outlined_disc(img, 22, 25, 6, Color(1, 1, 1), 2)
	_outlined_disc(img, 34, 25, 6, Color(1, 1, 1), 2)
	_disc(img, 23, 26, 2.5, Color(0.05, 0.05, 0.08))
	_disc(img, 33, 26, 2.5, Color(0.05, 0.05, 0.08))
	# Zornige Augenbrauen
	_tri(img, Vector2(16, 17), Vector2(27, 20), Vector2(16, 20), OUTLINE)
	_tri(img, Vector2(40, 17), Vector2(29, 20), Vector2(40, 20), OUTLINE)
	# Mund mit Zähnen
	_ellipse(img, cx, 38, 10, 5.5, OUTLINE)
	_ellipse(img, cx, 38, 8, 4, Color(0.40, 0.05, 0.10))
	_tri(img, Vector2(22, 35), Vector2(26, 35), Vector2(24, 40), Color(1, 1, 1))
	_tri(img, Vector2(28, 35), Vector2(32, 35), Vector2(30, 40), Color(1, 1, 1))
	_tri(img, Vector2(25, 41.5), Vector2(29, 41.5), Vector2(27, 37), Color(1, 1, 1))
	return ImageTexture.create_from_image(img)

# ---------- Projektile & Mündungsfeuer ----------

func _make_projectile() -> ImageTexture:
	var img = _new_img(20, 20)
	_disc(img, 10, 10, 7, OUTLINE)
	_disc(img, 10, 10, 5, Color(0.95, 0.90, 0.2))
	_disc(img, 9, 9, 2.5, Color(1, 1, 0.9))
	return ImageTexture.create_from_image(img)

func _make_enemy_ball() -> ImageTexture:
	var img = _new_img(20, 20)
	_disc(img, 10, 10, 7, OUTLINE)
	_disc(img, 10, 10, 5, Color(0.95, 0.30, 0.25))
	_disc(img, 9, 9, 2.5, Color(1.0, 0.75, 0.7))
	return ImageTexture.create_from_image(img)

func _make_muzzle_flash() -> ImageTexture:
	var img = _new_img(48, 48)
	# Sternform (4 Zipfel)
	_tri(img, Vector2(24, 2), Vector2(16, 24), Vector2(32, 24), OUTLINE)
	_tri(img, Vector2(46, 24), Vector2(24, 16), Vector2(24, 32), OUTLINE)
	_tri(img, Vector2(24, 46), Vector2(16, 24), Vector2(32, 24), OUTLINE)
	_tri(img, Vector2(2, 24), Vector2(24, 16), Vector2(24, 32), OUTLINE)
	_tri(img, Vector2(24, 5), Vector2(18, 24), Vector2(30, 24), Color(1.0, 0.55, 0.1))
	_tri(img, Vector2(43, 24), Vector2(24, 18), Vector2(24, 30), Color(1.0, 0.55, 0.1))
	_tri(img, Vector2(24, 43), Vector2(18, 24), Vector2(30, 24), Color(1.0, 0.55, 0.1))
	_tri(img, Vector2(5, 24), Vector2(24, 18), Vector2(24, 30), Color(1.0, 0.55, 0.1))
	_disc(img, 24, 24, 10, Color(1.0, 0.85, 0.2))
	_disc(img, 24, 24, 5, Color(1, 1, 0.95))
	return ImageTexture.create_from_image(img)

# ---------- Kiste ----------

func _make_chest() -> ImageTexture:
	# Runde 49: Klassische Truhe mit klarer Silhouette - gewoelbter
	# Deckel, sichtbarer Deckelspalt, zwei Eisenbaender, ein Schloss
	# mit Schluesselbart und vier Fuessen. Vorher war es ein flacher
	# brauner Topf, der als "dumpfer Kasten" las.
	var img = _new_img(48, 48)
	var wood := Color(0.62, 0.40, 0.21)
	var wood_lit := Color(0.76, 0.52, 0.29)
	var wood_dark := Color(0.44, 0.26, 0.13)
	var iron := Color(0.44, 0.46, 0.52)
	var iron_l := Color(0.64, 0.67, 0.74)
	var gold := Color(0.96, 0.80, 0.26)
	_ellipse(img, 24, 43, 19, 4, SHADOW, true)
	# --- Korpus (leicht trapezfoermig: unten breiter) ---
	_rect(img, 6, 22, 36, 18, OUTLINE)
	_rect(img, 8, 23, 32, 16, wood)
	# Seiten-Schatten rechts
	_rect(img, 34, 23, 6, 16, wood_dark)
	# --- Deckel: gewoelbt, mit Spalt zum Korpus ---
	_ellipse(img, 24, 22, 18, 8, OUTLINE)
	_ellipse(img, 24, 21, 16, 6, wood_lit)
	# Deckelspalt (dunkle Linie zwischen Deckel und Korpus)
	_rect(img, 7, 21, 34, 2, OUTLINE)
	# Deckel-Front
	_rect(img, 8, 22, 32, 2, wood)
	# --- Zwei Eisenbaender quer ueber Deckel und Korpus ---
	for bx in [11, 33]:
		_rect(img, bx, 14, 4, 26, OUTLINE)
		_rect(img, bx + 1, 15, 2, 24, iron)
		_rect(img, bx + 1, 15, 1, 24, iron_l)
	# --- Schloss in der Mitte ---
	_rect(img, 20, 25, 8, 9, OUTLINE)
	_rect(img, 21, 26, 6, 7, iron)
	_rect(img, 22, 27, 4, 5, gold)
	_px(img, 23, 29, OUTLINE)
	_px(img, 23, 30, OUTLINE)
	# Schluesselbart
	_rect(img, 22, 32, 3, 3, gold)
	_px(img, 24, 34, gold)
	# --- Eckbeschlaege ---
	for ex in [6, 40]:
		_rect(img, ex, 22, 2, 18, iron)
	# --- Plankenfugen ---
	for yy in [27, 32, 36]:
		for lx in range(8, 34):
			_px(img, lx, yy, wood_dark)
	# --- Fuesse ---
	_rect(img, 8, 40, 5, 3, OUTLINE)
	_rect(img, 35, 40, 5, 3, OUTLINE)
	# --- Glanzlichter ---
	_rect(img, 17, 17, 4, 1, Color(1, 1, 1, 0.30))
	_rect(img, 18, 16, 2, 1, Color(1, 1, 1, 0.45))
	_px(img, 10, 29, Color(1, 1, 1, 0.16))
	return ImageTexture.create_from_image(img)

# ---------- Bäume & Steine ----------

func _make_bush_prop(size: int, variant: int = 0) -> ImageTexture:
	# Runde 64: Busch im Stil der Baeume - schwarze Kontur, dunkle Unterseite,
	# Hauptfarbe, Lichtkante oben links. Die geladenen busch_*.png hatten
	# keine Kontur und wirkten wie Flammen.
	var img = _new_img(size, size)
	var f := float(size)
	var leaf := Color(0.20, 0.70, 0.20)
	var leaf_dark := Color(0.12, 0.50, 0.14)
	var leaf_light := Color(0.45, 0.85, 0.40)
	var blobs: Array
	match variant % 4:
		0:
			blobs = [[0.34, 0.60, 0.23], [0.52, 0.55, 0.26], [0.68, 0.61, 0.21]]
		1:
			blobs = [[0.36, 0.58, 0.24], [0.58, 0.60, 0.21], [0.47, 0.45, 0.19]]
		2:
			blobs = [[0.30, 0.62, 0.20], [0.48, 0.58, 0.25], [0.68, 0.65, 0.18], [0.50, 0.44, 0.17]]
		_:
			blobs = [[0.40, 0.56, 0.27], [0.62, 0.62, 0.19]]
	for b in blobs:
		_disc(img, float(b[0]) * f, float(b[1]) * f, float(b[2]) * f + 2.0, OUTLINE)
	for b in blobs:
		_disc(img, float(b[0]) * f, float(b[1]) * f + f * 0.035, float(b[2]) * f * 0.95, leaf_dark)
	for b in blobs:
		_disc(img, float(b[0]) * f, float(b[1]) * f, float(b[2]) * f * 0.86, leaf)
	for b in blobs:
		_disc(img, float(b[0]) * f - float(b[2]) * f * 0.22, float(b[1]) * f - float(b[2]) * f * 0.26,
			float(b[2]) * f * 0.32, leaf_light, true)
	return ImageTexture.create_from_image(img)


func _load_chest_png(path: String, tier: String, open_state: bool):
	# Laedt das gemalte PNG; fehlt es, wird die gezeichnete Kiste genutzt.
	# Jeder Fehler wird gemeldet, kein stiller Fallback.
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			print("[CHEST][TEX] geladen: %s (%dx%d)" % [path, res.get_width(), res.get_height()])
			return res
		print("[CHEST][TEX] FEHLER: %s ist keine Textur" % path)
	else:
		print("[CHEST][TEX] FEHLER: %s fehlt - prozedurale Kiste" % path)
	return _make_gem_chest(128, tier, open_state)


func _make_gem_icon(level: int, size: int) -> ImageTexture:
	# Runde 95: 1-3 Edelsteine fuer den Kisten-Reveal
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var cx := f * 0.5
	for i in range(level):
		var ox: float = (float(i) - float(level - 1) * 0.5) * f * 0.22
		var cy: float = f * 0.55
		var w: float = f * 0.14
		var h: float = f * 0.20
		_tri(img, Vector2(cx + ox, cy - h), Vector2(cx + ox + w, cy), Vector2(cx + ox - w, cy), OUTLINE)
		_tri(img, Vector2(cx + ox, cy + h), Vector2(cx + ox + w, cy), Vector2(cx + ox - w, cy), OUTLINE)
		_tri(img, Vector2(cx + ox, cy - h * 0.9), Vector2(cx + ox + w * 0.85, cy), Vector2(cx + ox - w * 0.85, cy), Color(0.35, 0.82, 0.98))
		_tri(img, Vector2(cx + ox, cy - h * 0.9), Vector2(cx + ox, cy), Vector2(cx + ox - w * 0.85, cy), Color(0.78, 0.96, 1.0))
		_tri(img, Vector2(cx + ox, cy), Vector2(cx + ox + w * 0.85, cy), Vector2(cx + ox, cy + h * 0.9), Color(0.12, 0.52, 0.72))
		_disc(img, cx + ox - w * 0.3, cy - h * 0.45, f * 0.012, Color(1, 1, 1, 0.95), true)
	_aa = false
	return ImageTexture.create_from_image(img)


func _make_slot_icon(size: int) -> ImageTexture:
	# Runde 100: Automat als Kachel-Icon fuer den Shop
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var cx := f * 0.5
	# Gehaeuse
	_rect(img, int(f * 0.10), int(f * 0.14), int(f * 0.80), int(f * 0.72), OUTLINE)
	_rect(img, int(f * 0.14), int(f * 0.18), int(f * 0.72), int(f * 0.64), Color(0.55, 0.16, 0.20))
	# Fenster
	_rect(img, int(f * 0.18), int(f * 0.24), int(f * 0.64), int(f * 0.30), OUTLINE)
	_rect(img, int(f * 0.21), int(f * 0.27), int(f * 0.58), int(f * 0.24), Color(0.92, 0.90, 0.82))
	for i in range(3):
		var wx: float = f * 0.29 + float(i) * f * 0.18
		_disc(img, wx, f * 0.39, f * 0.055, [Color(0.80, 0.14, 0.18), Color(0.96, 0.78, 0.20), Color(0.24, 0.44, 0.78)][i], true)
	# Hebel
	_thick_line(img, Vector2(f * 0.86, f * 0.30), Vector2(f * 0.92, f * 0.62), 5.0, OUTLINE)
	_disc(img, f * 0.92, f * 0.64, f * 0.055, Color(0.95, 0.20, 0.20), true)
	# Muenzschacht
	_rect(img, int(f * 0.36), int(f * 0.70), int(f * 0.28), int(f * 0.08), OUTLINE)
	_rect(img, int(f * 0.38), int(f * 0.72), int(f * 0.24), int(f * 0.04), Color(0.15, 0.15, 0.18))
	# Fuss
	_rect(img, int(f * 0.14), int(f * 0.86), int(f * 0.72), int(f * 0.06), Color(0.30, 0.30, 0.36))
	_aa = false
	return ImageTexture.create_from_image(img)


func _make_slot_symbol(kind: String, size: int) -> ImageTexture:
	# Runde 94: Walzensymbole im Comic-Stil - dicke Kontur, flache Farben.
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var cx := f * 0.5
	match kind:
		"cherry":
			_thick_line(img, Vector2(cx, f * 0.30), Vector2(cx - f * 0.16, f * 0.62), 4.0, Color(0.20, 0.55, 0.22))
			_thick_line(img, Vector2(cx, f * 0.30), Vector2(cx + f * 0.18, f * 0.58), 4.0, Color(0.20, 0.55, 0.22))
			_disc(img, cx - f * 0.17, f * 0.66, f * 0.17, OUTLINE, true)
			_disc(img, cx + f * 0.19, f * 0.62, f * 0.16, OUTLINE, true)
			_disc(img, cx - f * 0.17, f * 0.65, f * 0.13, Color(0.80, 0.12, 0.16), true)
			_disc(img, cx + f * 0.19, f * 0.61, f * 0.12, Color(0.72, 0.10, 0.14), true)
			_disc(img, cx - f * 0.21, f * 0.60, f * 0.035, Color(1, 1, 1, 0.85), true)
		"bell":
			_tri(img, Vector2(cx, f * 0.20), Vector2(cx + f * 0.30, f * 0.66), Vector2(cx - f * 0.30, f * 0.66), OUTLINE)
			_tri(img, Vector2(cx, f * 0.26), Vector2(cx + f * 0.25, f * 0.64), Vector2(cx - f * 0.25, f * 0.64), Color(0.96, 0.79, 0.22))
			_rect(img, int(cx - f * 0.34), int(f * 0.64), int(f * 0.68), int(f * 0.08), OUTLINE)
			_rect(img, int(cx - f * 0.30), int(f * 0.66), int(f * 0.60), int(f * 0.04), Color(0.98, 0.86, 0.40))
			_disc(img, cx, f * 0.78, f * 0.07, OUTLINE, true)
			_disc(img, cx, f * 0.78, f * 0.05, Color(0.85, 0.66, 0.16), true)
		"bar":
			_rect(img, int(cx - f * 0.34), int(f * 0.30), int(f * 0.68), int(f * 0.40), OUTLINE)
			_rect(img, int(cx - f * 0.30), int(f * 0.34), int(f * 0.60), int(f * 0.32), Color(0.20, 0.42, 0.78))
			for i in range(3):
				_rect(img, int(cx - f * 0.22 + float(i) * f * 0.17), int(f * 0.40), int(f * 0.10), int(f * 0.20), Color(0.92, 0.95, 1.0))
		"gold1", "gold2", "gold3":
			var n: int = 1
			if kind == "gold2": n = 2
			elif kind == "gold3": n = 3
			for i in range(n):
				var ox: float = (float(i) - float(n - 1) * 0.5) * f * 0.22
				_disc(img, cx + ox, f * 0.52, f * 0.19, OUTLINE, true)
				_disc(img, cx + ox, f * 0.52, f * 0.15, Color(0.98, 0.80, 0.20), true)
				_disc(img, cx + ox - f * 0.04, f * 0.47, f * 0.045, Color(1, 1, 1, 0.9), true)
			if n == 3:
				_disc(img, cx, f * 0.22, f * 0.06, Color(1, 1, 0.9, 0.95), true)
		"skull":
			_disc(img, cx, f * 0.44, f * 0.28, OUTLINE, true)
			_disc(img, cx, f * 0.44, f * 0.24, Color(0.90, 0.90, 0.86), true)
			_rect(img, int(cx - f * 0.14), int(f * 0.60), int(f * 0.28), int(f * 0.14), OUTLINE)
			_rect(img, int(cx - f * 0.11), int(f * 0.60), int(f * 0.22), int(f * 0.11), Color(0.90, 0.90, 0.86))
			_disc(img, cx - f * 0.10, f * 0.42, f * 0.06, Color(0.05, 0.05, 0.08), true)
			_disc(img, cx + f * 0.10, f * 0.42, f * 0.06, Color(0.05, 0.05, 0.08), true)
			_tri(img, Vector2(cx, f * 0.50), Vector2(cx + f * 0.05, f * 0.58), Vector2(cx - f * 0.05, f * 0.58), Color(0.05, 0.05, 0.08))
	_aa = false
	return ImageTexture.create_from_image(img)


func _make_gem_chest(size: int, tier: String, open_state: bool) -> ImageTexture:
	# Runde 71: Truhen-Silhouette - hoher Korpus, halbrunder Deckel mit
	# Ueberstand, Schloss auf der Naht. Weiche Kanten via Coverage-Sampling.
	_aa = true
	var img = _new_img(size, size)
	var f := float(size)
	var body_l: Color
	var body_m: Color
	var body_d: Color
	var rim_l: Color
	var rim_m: Color
	var rim_d: Color
	var gem_l: Color
	var gem_m: Color
	var gem_d: Color
	match tier:
		"silver":
			body_l = Color(0.80, 0.82, 0.88); body_m = Color(0.60, 0.63, 0.70)
			body_d = Color(0.37, 0.40, 0.48)
			rim_l = Color(0.98, 0.99, 1.0); rim_m = Color(0.74, 0.78, 0.86); rim_d = Color(0.45, 0.48, 0.56)
			gem_l = Color(0.88, 1.0, 0.95); gem_m = Color(0.32, 0.86, 0.60); gem_d = Color(0.10, 0.50, 0.34)
		"premium":
			body_l = Color(0.48, 0.40, 0.68); body_m = Color(0.31, 0.25, 0.50)
			body_d = Color(0.17, 0.13, 0.31)
			rim_l = Color(1.0, 0.92, 0.60); rim_m = Color(0.87, 0.72, 0.33); rim_d = Color(0.50, 0.37, 0.14)
			gem_l = Color(0.96, 0.78, 1.0); gem_m = Color(0.75, 0.40, 0.98); gem_d = Color(0.43, 0.16, 0.66)
		_:
			body_l = Color(0.70, 0.47, 0.25); body_m = Color(0.50, 0.31, 0.16)
			body_d = Color(0.29, 0.17, 0.09)
			rim_l = Color(0.98, 0.89, 0.58); rim_m = Color(0.78, 0.64, 0.29); rim_d = Color(0.45, 0.34, 0.13)
			gem_l = Color(0.80, 0.98, 1.0); gem_m = Color(0.31, 0.73, 0.95); gem_d = Color(0.10, 0.36, 0.58)

	var cx: float = f * 0.5
	var half: float = f * 0.33          # halbe Korpusbreite
	var top: float = f * 0.50           # Deckel-Naht
	var bot: float = f * 0.84

	# Bodenschatten
	_ellipse(img, int(cx), int(bot + f * 0.02), int(half * 1.06), int(f * 0.045), Color(0, 0, 0, 0.28), true)

	# --- Deckel zuerst (Korpus deckt die untere Haelfte spaeter ab) ---
	if not open_state:
		_ellipse(img, int(cx), int(top), int(half * 1.06), int(f * 0.20), OUTLINE)
		_ellipse(img, int(cx), int(top - f * 0.005), int(half * 1.01), int(f * 0.185), body_m)
		_ellipse(img, int(cx), int(top - f * 0.045), int(half * 0.96), int(f * 0.150), body_l)
		# Metallkante entlang der Naht
		_rect(img, int(cx - half * 1.03), int(top - f * 0.018), int(half * 2.06), int(f * 0.030), rim_m)
		_rect(img, int(cx - half * 1.03), int(top - f * 0.018), int(half * 2.06), int(f * 0.010), rim_l)

	# --- Korpus ---
	_rect(img, int(cx - half) - 3, int(top) - 3, int(half * 2.0) + 6, int(bot - top) + 3, OUTLINE)
	_rect(img, int(cx - half), int(top), int(half * 2.0), int(f * 0.10), body_l)
	_rect(img, int(cx - half), int(top + f * 0.10), int(half * 2.0), int(f * 0.16), body_m)
	_rect(img, int(cx - half), int(bot - f * 0.08), int(half * 2.0), int(f * 0.08), body_d)
	# senkrechte Metallbaender
	for bx in [cx - half * 0.52, cx + half * 0.52]:
		_rect(img, int(bx - f * 0.020), int(top), int(f * 0.040), int(bot - top), rim_m)
		_rect(img, int(bx - f * 0.020), int(top), int(f * 0.012), int(bot - top), rim_l)

	# --- Schloss auf der Naht ---
	_rect(img, int(cx - f * 0.055), int(top - f * 0.035), int(f * 0.11), int(f * 0.105), OUTLINE)
	_rect(img, int(cx - f * 0.045), int(top - f * 0.025), int(f * 0.09), int(f * 0.085), rim_m)
	_rect(img, int(cx - f * 0.045), int(top - f * 0.025), int(f * 0.09), int(f * 0.012), rim_l)

	if open_state:
		# Deckel hinten aufgeklappt: schmaler Bogen ueber der Hinterkante
		_ellipse(img, int(cx), int(top - f * 0.10), int(half * 1.02), int(f * 0.075), OUTLINE)
		_ellipse(img, int(cx), int(top - f * 0.105), int(half * 0.97), int(f * 0.062), body_d)
		_ellipse(img, int(cx), int(top - f * 0.115), int(half * 0.80), int(f * 0.040), body_m)
		# Oeffnung + Licht
		_ellipse(img, int(cx), int(top + f * 0.01), int(half * 0.90), int(f * 0.055), Color(0.05, 0.04, 0.08, 1.0), true)
		_ellipse(img, int(cx), int(top + f * 0.015), int(half * 0.74), int(f * 0.040),
			Color(gem_m.r, gem_m.g, gem_m.b, 0.65), true)
		_ellipse(img, int(cx), int(top + f * 0.02), int(half * 0.42), int(f * 0.022), Color(1, 1, 1, 0.30), true)

	# --- Edelstein auf dem Deckel (geschlossen) ---
	if not open_state:
		var gy: float = top - f * 0.115
		var gw: float = f * 0.075
		var gh: float = f * 0.070
		_tri(img, Vector2(cx, gy - gh), Vector2(cx + gw, gy), Vector2(cx - gw, gy), OUTLINE)
		_tri(img, Vector2(cx, gy + gh * 0.55), Vector2(cx + gw, gy), Vector2(cx - gw, gy), OUTLINE)
		_tri(img, Vector2(cx, gy - gh * 0.82), Vector2(cx + gw * 0.80, gy), Vector2(cx - gw * 0.80, gy), gem_m)
		_tri(img, Vector2(cx, gy - gh * 0.82), Vector2(cx, gy), Vector2(cx - gw * 0.80, gy), gem_l)
		_tri(img, Vector2(cx, gy), Vector2(cx + gw * 0.80, gy), Vector2(cx, gy + gh * 0.40), gem_d)
		_disc(img, cx - gw * 0.28, gy - gh * 0.42, f * 0.010, Color(1, 1, 1, 0.95), true)

	_aa = false
	return ImageTexture.create_from_image(img)



func bw_inset(cx: float, bw: float, y: float) -> float:
	# Korpus verjuengt sich nach unten leicht -> Breitenfunktion
	return bw * (0.97 - 0.04 * clampf((y - cx * 0.8) / 400.0, 0.0, 1.0))



func _make_tree() -> ImageTexture:
	var img = _new_img(64, 64)
	var leaf := Color(0.20, 0.70, 0.20)
	var leaf_dark := Color(0.12, 0.50, 0.14)
	var leaf_light := Color(0.45, 0.85, 0.40)
	var trunk := Color(0.50, 0.30, 0.15)
	# Schatten
	_ellipse(img, 32, 58, 18, 4, SHADOW, true)
	# Stamm
	_rect(img, 27, 40, 10, 16, OUTLINE)
	_rect(img, 28, 41, 8, 14, trunk)
	# Blätter-Busche mit Outline
	for blob in [[22, 30, 11], [42, 30, 11], [32, 22, 14]]:
		_disc(img, blob[0], blob[1], blob[2] + 2, OUTLINE)
	_disc(img, 22, 30, 11, leaf_dark)
	_disc(img, 42, 30, 11, leaf_dark)
	_disc(img, 32, 22, 14, leaf)
	# Lichtkante
	_disc(img, 28, 16, 6, leaf_light, true)
	_disc(img, 37, 20, 4, leaf_light, true)
	return ImageTexture.create_from_image(img)

func _make_rock() -> ImageTexture:
	var img = _new_img(48, 48)
	var gray := Color(0.58, 0.58, 0.60)
	var gray_dark := Color(0.40, 0.40, 0.44)
	_ellipse(img, 24, 40, 18, 5, SHADOW, true)
	_ellipse(img, 24, 28, 17, 13, OUTLINE)
	_ellipse(img, 24, 28, 15, 11, gray)
	_ellipse(img, 19, 23, 6, 4, Color(0.75, 0.75, 0.78), true)
	# Riss
	_px(img, 26, 30, gray_dark)
	_px(img, 27, 32, gray_dark)
	_px(img, 28, 34, gray_dark)
	_px(img, 29, 35, gray_dark)
	return ImageTexture.create_from_image(img)

# ---------- Herz ----------
func _create_heart_texture(color: Color, outline_color: Color, size: int) -> ImageTexture:
	var img = _new_img(size, size)
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var fx = float(x) - size / 2.0
			var fy = float(y) - size / 2.0 + size / 4.0
			var circle1 = Vector2(float(x) - size / 4.0, fy).length()
			var circle2 = Vector2(float(x) - 3.0 * size / 4.0, fy).length()
			if circle1 <= half / 2.0 or circle2 <= half / 2.0 or (fy >= 0 and fy < half and abs(fx) < half - fy * 0.5):
				img.set_pixel(x, y, color)
			elif circle1 <= half / 2.0 + 1 or circle2 <= half / 2.0 + 1:
				img.set_pixel(x, y, outline_color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func _create_shape_texture(color: Color, outline_color: Color, size: int, outline_width: int, shape_type: String) -> ImageTexture:
	var outer = size
	var img = _new_img(outer * 2, outer * 2)
	var center = float(outer)
	for x in range(int(center * 2)):
		for y in range(int(center * 2)):
			if shape_type == "pistol":
				if abs(x - center) < size / 1.5 and abs(y - center) < size / 3:
					img.set_pixel(x, y, color)
				elif abs(x - center) < size * 0.7 and abs(y - center) < size / 2:
					img.set_pixel(x, y, outline_color)
			elif shape_type == "shotgun":
				if abs(x - center) < size and abs(y - center) < size / 3:
					img.set_pixel(x, y, color)
				elif abs(x - center) < size * 1.1 and abs(y - center) < size / 2:
					img.set_pixel(x, y, outline_color)
			elif shape_type == "machine":
				if abs(x - center) < size / 1.2 and abs(y - center) < size / 2:
					img.set_pixel(x, y, color)
				elif abs(x - center) < size * 0.9 and abs(y - center) < size:
					img.set_pixel(x, y, outline_color)
	return ImageTexture.create_from_image(img)

# ---------- Touch-Controls ----------

func _make_stick_base() -> ImageTexture:
	var img = _new_img(240, 240)
	_disc(img, 120, 120, 118, OUTLINE)
	_disc(img, 120, 120, 114, Color(0.1, 0.1, 0.12, 0.30))
	_ring(img, 120, 120, 108, 4, Color(1, 1, 1, 0.35))
	return ImageTexture.create_from_image(img)

func _make_stick_knob() -> ImageTexture:
	var img = _new_img(100, 100)
	_disc(img, 50, 50, 48, OUTLINE)
	_disc(img, 50, 50, 42, Color(0.90, 0.92, 0.95, 0.90))
	_disc(img, 50, 50, 20, Color(0.60, 0.62, 0.68, 0.90))
	_disc(img, 42, 40, 8, Color(1, 1, 1, 0.8), true)
	return ImageTexture.create_from_image(img)

func _make_shoot_button() -> ImageTexture:
	var img = _new_img(96, 96)
	_disc(img, 48, 48, 46, OUTLINE)
	_disc(img, 48, 48, 42, Color(0.85, 0.20, 0.18))
	_ring(img, 48, 48, 34, 4, Color(1, 1, 1, 0.7))
	_disc(img, 48, 48, 12, Color(1.0, 0.85, 0.2))
	return ImageTexture.create_from_image(img)

func _make_shield_ring() -> ImageTexture:
	var img = _new_img(64, 64)
	_ring(img, 32, 32, 30, 5, OUTLINE)
	_ring(img, 32, 32, 26, 4, Color(0.3, 0.85, 1.0, 0.75))
	# 4 Glanzpunkte
	for pt in [[32, 4], [32, 60], [4, 32], [60, 32]]:
		_disc(img, pt[0], pt[1], 3, Color(0.8, 0.98, 1.0))
	return ImageTexture.create_from_image(img)

func _make_cactus() -> ImageTexture:
	var img = _new_img(64, 64)
	var body := Color(0.30, 0.64, 0.34)
	var body_dark := Color(0.20, 0.48, 0.26)
	_ellipse(img, 32, 58, 14, 4, SHADOW, true)
	# Hauptkörper
	_rect(img, 27, 18, 11, 40, OUTLINE)
	_rect(img, 29, 20, 7, 36, body)
	# linker Arm
	_rect(img, 13, 32, 16, 8, OUTLINE)
	_rect(img, 15, 33, 13, 6, body)
	_rect(img, 13, 22, 8, 14, OUTLINE)
	_rect(img, 15, 24, 4, 11, body)
	# rechter Arm
	_rect(img, 36, 38, 15, 8, OUTLINE)
	_rect(img, 37, 39, 13, 6, body)
	_rect(img, 43, 26, 8, 16, OUTLINE)
	_rect(img, 45, 28, 4, 13, body)
	# Stacheln
	for i in range(6):
		_px(img, 30, 26 + i * 5, body_dark)
		_px(img, 34, 28 + i * 5, body_dark)
	# Blüte oben
	_disc(img, 32, 15, 5, OUTLINE)
	_disc(img, 32, 15, 3, Color(1.0, 0.45, 0.60))
	return ImageTexture.create_from_image(img)

func _make_pine() -> ImageTexture:
	var img = _new_img(64, 64)
	var snow := Color(0.94, 0.97, 1.0)
	var green := Color(0.16, 0.44, 0.36)
	var green_light := Color(0.30, 0.62, 0.50)
	var trunk := Color(0.36, 0.24, 0.16)
	_ellipse(img, 32, 58, 15, 4, SHADOW, true)
	_rect(img, 29, 46, 7, 12, OUTLINE)
	_rect(img, 30, 47, 5, 10, trunk)
	# Nadel-Ebenen (nach oben schmaler)
	var i := 0
	while i < 14:
		var w := 44 - i * 3
		var y := 46 - i * 3
		_rect(img, int(32 - w / 2) - 1, y, w + 2, 4, OUTLINE)
		_rect(img, int(32 - w / 2), y + 1, w, 2, green if i % 3 != 0 else green_light)
		i += 1
	# Schneehaube
	_rect(img, 28, 6, 8, 6, snow)
	_disc(img, 32, 6, 4, snow)
	return ImageTexture.create_from_image(img)

func _make_dead_tree() -> ImageTexture:
	var img = _new_img(64, 64)
	var wood := Color(0.42, 0.32, 0.26)
	var wood_light := Color(0.56, 0.44, 0.36)
	_ellipse(img, 32, 58, 14, 4, SHADOW, true)
	_rect(img, 28, 26, 9, 32, OUTLINE)
	_rect(img, 29, 27, 6, 30, wood)
	# kahle Äste
	_rect(img, 18, 28, 12, 5, OUTLINE)
	_rect(img, 19, 29, 11, 3, wood_light)
	_rect(img, 36, 22, 13, 5, OUTLINE)
	_rect(img, 37, 23, 12, 3, wood_light)
	_rect(img, 22, 16, 5, 14, OUTLINE)
	_rect(img, 23, 17, 3, 12, wood_light)
	_rect(img, 39, 10, 5, 14, OUTLINE)
	_rect(img, 40, 11, 3, 12, wood_light)
	# Glut-Augen (Lava-Biom)
	_disc(img, 30, 34, 2, Color(1.0, 0.45, 0.15))
	_disc(img, 36, 34, 2, Color(1.0, 0.45, 0.15))
	return ImageTexture.create_from_image(img)

func _make_rock_col(base: Color, darker: Color) -> ImageTexture:
	var img = _new_img(48, 48)
	_ellipse(img, 24, 40, 18, 5, SHADOW, true)
	_ellipse(img, 24, 28, 17, 13, OUTLINE)
	_ellipse(img, 24, 28, 15, 11, base)
	_ellipse(img, 19, 23, 6, 4, base.lightened(0.28), true)
	# Riss
	_px(img, 26, 30, darker)
	_px(img, 27, 32, darker)
	_px(img, 28, 34, darker)
	_px(img, 29, 35, darker)
	return ImageTexture.create_from_image(img)

# ---------- Waffen (detailliert, Lauf zeigt nach rechts) ----------

func _make_weapon_pistol() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.74, 0.76, 0.80)
	var steel_dark := Color(0.46, 0.48, 0.54)
	var grip := Color(0.34, 0.25, 0.18)
	_rect(img, 19, 14, 31, 10, OUTLINE)
	_rect(img, 21, 15, 28, 8, steel)
	_rect(img, 45, 17, 16, 6, OUTLINE)
	_rect(img, 45, 18, 15, 4, steel_dark)
	_rect(img, 23, 16, 6, 3, Color(0.92, 0.94, 0.98))
	_rect(img, 15, 22, 11, 15, OUTLINE)
	_rect(img, 17, 23, 8, 13, grip)
	_rect(img, 30, 24, 4, 7, OUTLINE)
	_rect(img, 36, 25, 3, 4, steel_dark)
	return ImageTexture.create_from_image(img)

func _make_weapon_shotgun() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.66, 0.68, 0.72)
	var wood := Color(0.55, 0.34, 0.19)
	var wood_dark := Color(0.38, 0.23, 0.13)
	# Schaft
	_rect(img, 6, 16, 16, 11, OUTLINE)
	_rect(img, 8, 17, 13, 9, wood)
	_rect(img, 8, 20, 13, 3, wood_dark)
	# Verschluss
	_rect(img, 20, 15, 16, 10, OUTLINE)
	_rect(img, 22, 16, 13, 8, Color(0.30, 0.30, 0.34))
	# langer Lauf
	_rect(img, 34, 17, 28, 6, OUTLINE)
	_rect(img, 34, 18, 27, 4, steel)
	# Pumpe
	_rect(img, 40, 22, 12, 6, OUTLINE)
	_rect(img, 41, 23, 10, 4, wood)
	return ImageTexture.create_from_image(img)

func _make_weapon_machine() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.46, 0.50, 0.56)
	var steel_dark := Color(0.28, 0.31, 0.36)
	var mag := Color(0.36, 0.58, 0.36)
	_rect(img, 12, 15, 34, 11, OUTLINE)
	_rect(img, 14, 16, 30, 9, steel)
	# Magazin unten
	_rect(img, 26, 25, 12, 13, OUTLINE)
	_rect(img, 28, 26, 8, 11, mag)
	_rect(img, 28, 28, 8, 2, Color(0.22, 0.40, 0.24))
	# Lauf mit Kühlrippen
	_rect(img, 44, 16, 18, 7, OUTLINE)
	_rect(img, 44, 17, 17, 5, steel_dark)
	for i in range(4):
		_px(img, 47 + i * 4, 17, Color(0.70, 0.74, 0.80))
	# Schulterstuetze
	_rect(img, 6, 14, 8, 13, OUTLINE)
	_rect(img, 7, 15, 6, 11, steel_dark)
	# Korn
	_rect(img, 54, 11, 3, 6, OUTLINE)
	return ImageTexture.create_from_image(img)

func _make_weapon_laser() -> ImageTexture:
	var img = _new_img(64, 40)
	var body := Color(0.30, 0.62, 0.72)
	var body_dark := Color(0.18, 0.42, 0.52)
	var glow := Color(0.55, 1.0, 1.0)
	# kompakter Körper
	_rect(img, 20, 14, 26, 13, OUTLINE)
	_rect(img, 22, 15, 22, 11, body)
	_rect(img, 22, 15, 22, 3, Color(0.55, 0.90, 1.0))
	# Energie-Kern
	_disc(img, 33, 20, 5, OUTLINE)
	_disc(img, 33, 20, 3, glow)
	# duenner Strahler
	_rect(img, 44, 18, 16, 5, OUTLINE)
	_rect(img, 44, 19, 15, 3, body_dark)
	_disc(img, 60, 20, 4, OUTLINE)
	_disc(img, 60, 20, 2.5, glow)
	# Griff
	_rect(img, 24, 26, 9, 11, OUTLINE)
	_rect(img, 25, 27, 7, 9, body_dark)
	return ImageTexture.create_from_image(img)

func _make_weapon_revolver() -> ImageTexture:
	var img = _new_img(64, 40)
	var steel := Color(0.80, 0.68, 0.30)
	var steel_dark := Color(0.52, 0.41, 0.16)
	var grip := Color(0.40, 0.24, 0.16)
	# Trommel
	_disc(img, 32, 20, 11, OUTLINE)
	_disc(img, 32, 20, 9, steel)
	for i in range(6):
		var a := i * TAU / 6.0
		_disc(img, 32 + cos(a) * 5.0, 20 + sin(a) * 5.0, 2.0, steel_dark)
	# Lauf
	_rect(img, 42, 17, 20, 7, OUTLINE)
	_rect(img, 42, 18, 19, 5, steel)
	# Hahn
	_rect(img, 20, 12, 6, 6, OUTLINE)
	# Griff schraeg
	_rect(img, 18, 26, 12, 13, OUTLINE)
	_rect(img, 20, 27, 9, 11, grip)
	# Abzug
	_rect(img, 34, 29, 4, 7, OUTLINE)
	return ImageTexture.create_from_image(img)

# ---------- Loot / Powerups ----------

func _make_rarity_ring(c: Color) -> ImageTexture:
	var img = _new_img(56, 56)
	_ring(img, 28, 28, 26, 4, Color(c.r, c.g, c.b, 0.85))
	_ring(img, 28, 28, 22, 2, Color(c.r, c.g, c.b, 0.35))
	# 4 Funkel-Punkte
	for pt in [[28, 3], [28, 53], [3, 28], [53, 28]]:
		_disc(img, pt[0], pt[1], 2.5, Color(1, 1, 1, 0.9))
	return ImageTexture.create_from_image(img)

func _make_freeze_icon() -> ImageTexture:
	var img = _new_img(40, 40)
	_disc(img, 20, 20, 19, OUTLINE)
	_disc(img, 20, 20, 17, Color(0.45, 0.80, 1.0))
	# Schneeflocke
	_rect(img, 19, 7, 3, 26, Color(1, 1, 1))
	_rect(img, 7, 19, 26, 3, Color(1, 1, 1))
	_px(img, 12, 12, Color(1, 1, 1))
	_px(img, 13, 13, Color(1, 1, 1))
	_px(img, 27, 27, Color(1, 1, 1))
	_px(img, 26, 26, Color(1, 1, 1))
	_px(img, 12, 28, Color(1, 1, 1))
	_px(img, 13, 27, Color(1, 1, 1))
	_px(img, 27, 13, Color(1, 1, 1))
	_px(img, 26, 12, Color(1, 1, 1))
	return ImageTexture.create_from_image(img)

func _make_rapid_icon() -> ImageTexture:
	var img = _new_img(40, 40)
	_disc(img, 20, 20, 19, OUTLINE)
	_disc(img, 20, 20, 17, Color(1.0, 0.72, 0.20))
	# Blitz
	_tri(img, Vector2(23, 6), Vector2(12, 22), Vector2(20, 22), Color(1, 1, 1))
	_tri(img, Vector2(17, 34), Vector2(28, 18), Vector2(20, 18), Color(1, 1, 1))
	return ImageTexture.create_from_image(img)


func _make_monster_volt_spooler() -> ImageTexture:
	# Runde 49: SPULENTROOPER - ein schwerer, gepanzerter Gegner:
	# eine grosse Teslaspule als Rucksack, ein breiter Schildschild
	# in der linken Hand und ein Stab mit einer Elektro-Kugel.
	# Er ist langsam, hat viel Leben und schiesst eine Salve.
	var img = _new_img(64, 64)
	var steel := Color(0.62, 0.66, 0.76)
	var steel_d := Color(0.34, 0.38, 0.48)
	var steel_l := Color(0.84, 0.88, 0.96)
	var copper := Color(0.92, 0.56, 0.26)
	var copper_l := Color(1.0, 0.78, 0.44)
	var glow := Color(0.55, 0.92, 1.0)
	_ellipse(img, 32, 58, 18, 5, SHADOW, true)
	# --- Rucksack: Teslaspule (Ringe) ---
	_outlined_ellipse(img, 20, 30, 10, 14, steel_d, 3)
	_outlined_ellipse(img, 20, 30, 6, 10, copper, 2)
	_ellipse(img, 20, 30, 3, 7, copper_l)
	# Spulenwindungen
	for ry in [23, 28, 33, 37]:
		_rect(img, 11, ry, 18, 2, copper_l if ry % 2 == 0 else copper)
	# --- Kopf ---
	_outlined_disc(img, 40, 22, 10, steel, 3)
	# Visier
	_rect(img, 34, 19, 12, 5, steel_d)
	_rect(img, 36, 20, 8, 3, glow)
	# --- Torso ---
	_outlined_ellipse(img, 40, 38, 13, 12, steel, 3)
	# Brustplatte mit Warnstreifen
	_rect(img, 34, 34, 12, 7, steel_l)
	for x in range(34, 46):
		if (x + 34) % 5 < 2:
			img.set_pixel(x, 36, copper)
	# --- Schild (linke Hand, zum Betrachter) ---
	_outlined_ellipse(img, 26, 42, 11, 14, steel_d, 3)
	_outlined_ellipse(img, 26, 42, 8, 11, steel, 2)
	# Schild-Emblem (Blitz)
	_tri(img, Vector2(24, 48), Vector2(28, 36), Vector2(29, 45), glow)
	# --- Beine ---
	_rect(img, 34, 48, 7, 10, OUTLINE)
	_rect(img, 35, 49, 5, 9, steel_d)
	_rect(img, 42, 48, 7, 10, OUTLINE)
	_rect(img, 43, 49, 5, 9, steel_d)
	# --- Stab mit Elektro-Kugel (rechte Hand) ---
	_rect(img, 52, 30, 3, 26, OUTLINE)
	_rect(img, 53, 31, 1, 24, steel_l)
	_outlined_disc(img, 53, 26, 6, glow, 2)
	_disc(img, 52, 25, 2, Color(1, 1, 1, 0.95))
	# Funken
	_px(img, 48, 20, glow)
	_px(img, 58, 18, glow)
	_px(img, 50, 14, glow)
	return ImageTexture.create_from_image(img)
