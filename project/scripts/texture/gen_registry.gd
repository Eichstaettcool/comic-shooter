class_name GenRegistry
extends TexDraw

# Runde 138: Zuordnung Textur-Key -> Zeichner-Modul.
# Reine Daten, kein Zustand: der Aufrufer reicht das textures-Dictionary
# und die Fassade herein (fuer _load_external/_load_chest_png).
#
# v1.43 (S6.2): gen_boot ist in HAEPPCHEN zerlegt. `boot_steps()` liefert eine
# geordnete Liste { "name": ..., "fn": Callable }, die TextureManager Frame fuer
# Frame abarbeitet - so blockiert der Start nicht mehr Sekunden am Stueck.
# `gen_boot()` bleibt als "alles auf einmal" erhalten (Fallback/Tests).


static func boot_steps(tex: Dictionary, host: Node) -> Array:
	var steps: Array = []
	var add := func(n: String, f: Callable) -> void:
		steps.append({ "name": n, "fn": f })

	# --- Tiles + Held ---
	add.call("tiles", func() -> void:
		tex["tile_light"] = TexDraw._rect_tex(Color(0.60, 0.85, 0.50), 32)
		tex["tile_dark"] = TexDraw._rect_tex(Color(0.45, 0.70, 0.35), 32))
	add.call("player", func() -> void:
		tex["player"] = GenCharacters._make_player(Color(0.20, 0.60, 1.0), Color(0.15, 0.25, 0.55))
		tex["player2"] = GenCharacters._make_player(Color(0.92, 0.35, 0.15), Color(0.45, 0.15, 0.10)))
	add.call("chest", func() -> void:
		tex["chest"] = GenChests._make_chest())
	add.call("rarity", func() -> void:
		tex["rarity_common"] = GenItems._make_rarity_ring(Color(0.88, 0.90, 0.86))
		tex["rarity_rare"] = GenItems._make_rarity_ring(Color(0.35, 0.72, 1.0))
		tex["rarity_epic"] = GenItems._make_rarity_ring(Color(0.88, 0.45, 1.0)))
	add.call("herzen", func() -> void:
		tex["heart_full"] = GenItems._create_heart_texture(Color(0.9, 0.1, 0.1), OUTLINE, 16)
		tex["heart_empty"] = GenItems._create_heart_texture(Color(0.3, 0.0, 0.0), OUTLINE, 16)
		tex["heart_gold"] = GenItems._heart_padded(Color(0.98, 0.80, 0.20), Color(0.55, 0.36, 0.05), 36)
		tex["heart_big"] = GenItems._heart_padded(Color(0.92, 0.16, 0.28), OUTLINE, 36))
	add.call("waffen_icons", func() -> void:
		tex["weapon_pistol"] = GenItems._make_weapon_pistol()
		tex["weapon_shotgun"] = GenItems._make_weapon_shotgun()
		tex["weapon_machine"] = GenItems._make_weapon_machine())
	add.call("waffen_icons2", func() -> void:
		tex["weapon_laser"] = GenItems._make_weapon_laser()
		tex["weapon_revolver"] = GenItems._make_weapon_revolver())
	add.call("touch_stick", func() -> void:
		tex["stick_base"] = GenUi._make_stick_base())
	add.call("touch_knob", func() -> void:
		tex["stick_knob"] = GenUi._make_stick_knob())
	add.call("touch_shoot", func() -> void:
		tex["btn_shoot"] = GenUi._make_shoot_button())
	add.call("icons_ui", func() -> void:
		tex["icon_gear"] = GenUi._make_gear_icon()
		tex["icon_crosshair"] = GenUi._make_crosshair_icon()
		tex["icon_shield"] = GenUi._make_shield_icon()
		tex["icon_coin"] = GenUi._make_coin_icon()
		tex["coll_lock"] = GenUi._make_lock_chain(96)
		tex["wheel_icon_gold"] = GenUi._make_wheel_icon("gold", 96)
		tex["wheel_icon_gems"] = GenUi._make_wheel_icon("gems", 96)
		tex["wheel_icon_miss"] = GenUi._make_wheel_icon("miss", 96)
		tex["icon_revive"] = GenUi._make_revive_icon())
	add.call("nav_icons", func() -> void:
		tex["nav_lan"] = GenUi._make_nav_icon("lan")
		tex["nav_char"] = GenUi._make_nav_icon("char")
		tex["nav_shop"] = GenUi._make_nav_icon("shop")
		tex["nav_coll"] = GenUi._make_nav_icon("coll")
		tex["nav_map"] = GenUi._make_nav_icon("map")
		tex["nav_chal"] = GenUi._make_nav_icon("chal"))
	add.call("chal_icons", func() -> void:
		tex["chal_revolver"] = GenUi._make_chal_icon("revolver", 128)
		tex["chal_shield"] = GenUi._make_chal_icon("shield", 128)
		tex["chal_crown"] = GenUi._make_chal_icon("crown", 128)
		tex["chal_clock"] = GenUi._make_chal_icon("clock", 128)
		tex["chal_heart"] = GenUi._make_chal_icon("heart", 128)
		tex["chal_chest"] = GenUi._make_chal_icon("chest", 128))
	add.call("kisten_icons", func() -> void:
		tex["chest_wood"] = GenChests._make_chest_icon_rich("wood")
		tex["chest_silver"] = GenChests._make_chest_icon_rich("silver")
		tex["chest_gold"] = GenChests._make_chest_icon_rich("gold")
		tex["chest_platinum"] = GenChests._make_chest_icon_rich("platinum")
		tex["chest_storm"] = GenChests._make_chest_icon_rich("storm"))
	add.call("map_icons", func() -> void:
		tex["map_meadow"] = GenUi._make_map_icon_earth("spring")
		tex["map_desert"] = GenUi._make_map_icon_earth("desert")
		tex["map_ice"] = GenUi._make_map_icon_earth("ice")
		tex["map_lava"] = GenUi._make_map_icon_earth("lava")
		tex["map_mars"] = GenUi._make_map_icon_mars()
		tex["map_jungle"] = GenUi._make_map_icon_jungle()
		tex["map_volt"] = GenUi._make_map_icon_volt())
	# v1.45 (K): Die Shop-Kisten werden GEZEICHNET (64x64-Pixel-Art, 3 px Kontur,
	# 4x NEAREST -> 256 px) statt aus fremden PNGs geladen. Die Schluessel
	# heissen unveraendert chest_gem_<tier> / chest_gem_open_<tier>, damit Shop
	# und Reveal ohne Umweg umstellen.
	add.call("chest_art_standard", func() -> void:
		tex["chest_gem_standard"] = GenChestArt._make_chest_art("standard", false)
		tex["chest_gem_open_standard"] = GenChestArt._make_chest_art("standard", true))
	add.call("chest_art_silver", func() -> void:
		tex["chest_gem_silver"] = GenChestArt._make_chest_art("silver", false)
		tex["chest_gem_open_silver"] = GenChestArt._make_chest_art("silver", true))
	add.call("chest_art_premium", func() -> void:
		tex["chest_gem_premium"] = GenChestArt._make_chest_art("premium", false)
		tex["chest_gem_open_premium"] = GenChestArt._make_chest_art("premium", true))
	print("[CHEST][TEX] quelle=generiert tier=standard,silver,premium px=256")
	add.call("chest_spikes_a", func() -> void:
		tex["chest_spikes_standard"] = GenChests._make_chest_spikes("standard", 256))
	add.call("chest_spikes_b", func() -> void:
		tex["chest_spikes_silver"] = GenChests._make_chest_spikes("silver", 256))
	add.call("chest_spikes_c", func() -> void:
		tex["chest_spikes_premium"] = GenChests._make_chest_spikes("premium", 256))
	add.call("slot_icon", func() -> void:
		tex["slot_machine_icon"] = GenItems._make_slot_icon(256))
	add.call("slot_gem1", func() -> void:
		tex["slot_gem1"] = GenItems._make_gem_icon(1, 128))
	add.call("slot_gem2", func() -> void:
		tex["slot_gem2"] = GenItems._make_gem_icon(2, 128))
	add.call("slot_gem3", func() -> void:
		tex["slot_gem3"] = GenItems._make_gem_icon(3, 128))
	add.call("slot_cherry", func() -> void:
		tex["slot_cherry"] = GenItems._make_slot_symbol("cherry", 128))
	add.call("slot_bell", func() -> void:
		tex["slot_bell"] = GenItems._make_slot_symbol("bell", 128))
	add.call("slot_bar", func() -> void:
		tex["slot_bar"] = GenItems._make_slot_symbol("bar", 128))
	add.call("slot_gold1", func() -> void:
		tex["slot_gold1"] = GenItems._make_slot_symbol("gold1", 128))
	add.call("slot_gold2", func() -> void:
		tex["slot_gold2"] = GenItems._make_slot_symbol("gold2", 128))
	add.call("slot_gold3", func() -> void:
		tex["slot_gold3"] = GenItems._make_slot_symbol("gold3", 128))
	add.call("slot_skull", func() -> void:
		tex["slot_skull"] = GenItems._make_slot_symbol("skull", 128))
	add.call("rigs", func() -> void:
		for _r in range(4):
			tex["player_rig%d" % _r] = GenCharacters._make_player_rig(_r))
	add.call("run_kisten", func() -> void:
		tex["chest_run_common"] = GenChests._make_run_chest(Color(0.58, 0.40, 0.22), Color(0.66, 0.68, 0.72), Color(0.55, 0.80, 1.0), false)
		tex["chest_run_rare"] = GenChests._make_run_chest(Color(0.52, 0.54, 0.60), Color(0.80, 0.84, 0.90), Color(0.35, 0.72, 1.0), false)
		tex["chest_run_epic"] = GenChests._make_run_chest(Color(0.72, 0.56, 0.16), Color(0.98, 0.84, 0.30), Color(0.80, 0.40, 1.0), true))
	add.call("glow_common", func() -> void:
		tex["glow_common"] = GenItems._make_glow(96, Color(0.70, 0.90, 1.0)))
	add.call("glow_rare", func() -> void:
		tex["glow_rare"] = GenItems._make_glow(96, Color(0.40, 0.75, 1.0)))
	add.call("glow_epic", func() -> void:
		tex["glow_epic"] = GenItems._make_glow(96, Color(0.85, 0.45, 1.0)))
	add.call("shield", func() -> void:
		tex["shield_ring"] = GenItems._make_shield_ring()
		tex["shield"] = GenUi._make_shield_icon())
	add.call("monster_a", func() -> void:
		tex["monster_green"] = GenMonsters._make_monster(Color(0.25, 0.80, 0.30), Color(0.45, 0.95, 0.50))
		tex["monster_red"] = GenMonsters._make_monster(Color(0.90, 0.25, 0.22), Color(1.0, 0.50, 0.45))
		tex["monster_blue"] = GenMonsters._make_monster(Color(0.20, 0.50, 0.90), Color(0.45, 0.70, 1.0)))
	add.call("monster_b", func() -> void:
		tex["monster_purple"] = GenMonsters._make_monster(Color(0.60, 0.22, 0.80), Color(0.80, 0.45, 1.0))
		tex["monster_yellow"] = GenMonsters._make_monster(Color(0.95, 0.80, 0.15), Color(1.0, 0.92, 0.45))
		tex["monster_pink"] = GenMonsters._make_monster(Color(0.95, 0.45, 0.70), Color(1.0, 0.70, 0.85)))
	add.call("monster_c", func() -> void:
		tex["monster_orange"] = GenMonsters._make_monster(Color(0.95, 0.50, 0.12), Color(1.0, 0.70, 0.35))
		tex["monster_burrower"] = GenMonsters._make_monster(Color(0.86, 0.72, 0.40), Color(0.98, 0.88, 0.62))
		tex["monster_golem"] = GenMonsters._make_monster(Color(0.52, 0.74, 0.90), Color(0.82, 0.94, 1.0)))
	add.call("monster_d", func() -> void:
		tex["monster_pyro"] = GenMonsters._make_monster(Color(0.90, 0.32, 0.14), Color(1.0, 0.72, 0.26))
		tex["monster_sporenbrut"] = GenMonsters._make_sporenbrut()
		tex["monster_schild"] = GenMonsters._make_schild())
	add.call("monster_e", func() -> void:
		tex["monster_herold"] = GenMonsters._make_herold()
		tex["monster_spore"] = GenMonsters._make_spore())
	add.call("png_items_a", func() -> void:
		for k in ["heart_full", "heart_empty", "heart_gold", "shield"]:
			host._load_external(k, "res://assets/items/%s.png" % k))
	add.call("png_items_b", func() -> void:
		for k in ["potion", "bomb"]:
			host._load_external(k, "res://assets/items/%s.png" % k))
	add.call("png_items_c", func() -> void:
		for k in ["upg_power", "upg_turbo", "upg_speed"]:
			host._load_external(k, "res://assets/items/%s.png" % k))
	add.call("png_items_d", func() -> void:
		for k in ["upg_vitality", "upg_guardian", "upg_vampire"]:
			host._load_external(k, "res://assets/items/%s.png" % k))
	return steps


static func gen_boot(tex: Dictionary, host: Node) -> void:
	# Fallback: alles am Stueck (kein Frame-Splitting)
	for s in boot_steps(tex, host):
		(s["fn"] as Callable).call()


static func gen_run(tex: Dictionary, host: Node) -> void:
	# Monster (echte Gesichter mit Hörnern, Augen, Zähnen)
	tex["boss"] = GenMonsters._make_monster(Color(0.45, 0.05, 0.10), Color(0.80, 0.20, 0.25), true)
	# Biom-Spezialisten (Punkt 5)
	# Projektile + Mündungsfeuer
	tex["projectile"] = GenMonsters._make_projectile()
	tex["muzzle_flash"] = GenMonsters._make_muzzle_flash()
	tex["enemy_ball"] = GenMonsters._make_enemy_ball()
	# Bäume & Steine (mit Schatten + Lichtkante)
	tex["tree"] = GenWorld._make_tree()
	tex["rock"] = GenWorld._make_rock()
	# --- Biome-Deko ---
	tex["cactus"] = GenWorld._make_cactus()
	tex["rock_desert"] = GenWorld._make_rock_col(Color(0.80, 0.68, 0.44), Color(0.58, 0.46, 0.26))
	tex["pine"] = GenWorld._make_pine()
	tex["ice_rock"] = GenWorld._make_rock_col(Color(0.74, 0.86, 0.94), Color(0.50, 0.66, 0.80))
	tex["dead_tree"] = GenWorld._make_dead_tree()
	tex["lava_rock"] = GenWorld._make_rock_col(Color(0.44, 0.30, 0.28), Color(0.24, 0.14, 0.14))
	# --- Powerup-Icons ---
	tex["powerup_freeze"] = GenItems._make_freeze_icon()
	tex["powerup_rapid"] = GenItems._make_rapid_icon()
	tex["monster_mars_alien"] = GenMonsters._make_mars_alien()
	tex["monster_mars_rover"] = GenMonsters._make_mars_rover()
	tex["monster_robo_ape"] = GenMonsters._make_robo_ape()
	tex["monster_big_flower"] = GenWorld._make_big_flower()
	tex["banana"] = GenWorld._make_banana()
	tex["palm"] = GenWorld._make_palm()
	tex["bush"] = GenWorld._make_bush_dot()
	tex["pbush_a"] = GenWorld._make_bush_prop(56, 0)
	tex["pbush_b"] = GenWorld._make_bush_prop(56, 1)
	tex["pbush_c"] = GenWorld._make_bush_prop(56, 2)
	tex["pbush_d"] = GenWorld._make_bush_prop(56, 3)
	tex["mars_rock"] = GenWorld._make_rock_col(Color(0.66, 0.32, 0.24), Color(0.44, 0.18, 0.14))
	tex["mars_crater"] = GenWorld._make_rock_col(Color(0.52, 0.24, 0.18), Color(0.34, 0.14, 0.11))
	# Runde 14: eigene Welt-Objekte je Planet
	tex["mars_boulder"] = GenWorld._make_boulder(Color(0.62, 0.30, 0.22), Color(0.80, 0.46, 0.32), 64)
	tex["mars_boulder_big"] = GenWorld._make_boulder(Color(0.58, 0.27, 0.20), Color(0.76, 0.42, 0.28), 128)
	tex["mars_crater_decal"] = GenWorld._make_crater(160)
	tex["jungle_tree"] = GenWorld._make_jungle_tree(128)
	# Runde 18: Dschungel-Set nach den Referenzbildern des Nutzers
	tex["jtree_round"] = GenWorld._make_jtree_round(176)
	tex["jtree_tall"] = GenWorld._make_jtree_tall(176)
	tex["jtree_willow"] = GenWorld._make_jtree_willow(176)
	tex["jtree_ancient"] = GenWorld._make_jtree_ancient(200)
	tex["jpalm"] = GenWorld._make_jpalm(176)
	tex["jbush_leaf"] = GenWorld._make_jbush_leaf(112)
	tex["jvine"] = GenWorld._make_jvine(112)
	tex["jmushroom_red"] = GenWorld._make_jmushroom(56, Color(0.90, 0.26, 0.24))
	tex["jmushroom_brown"] = GenWorld._make_jmushroom(44, Color(0.62, 0.44, 0.24))
	tex["jcrystal"] = GenWorld._make_jcrystal(96)
	tex["jreed"] = GenWorld._make_jreed(80)
	tex["bridge"] = GenWorld._make_bridge()
	tex["grass_tuft"] = GenWorld._make_grass_tuft()
	tex["jrock"] = GenWorld._make_jrock(64)
	# v1.42 (P7.4): fuenf Stein-Varianten mit Umriss, 5 Grautoenen und Moos
	for _si in range(5):
		tex["stone_v%d" % _si] = GenWorld._make_stone_variant(_si, 128)
	tex["jflower"] = GenWorld._make_jflower(48)
	tex["jflower_pink"] = GenWorld._make_jflower(48, Color(0.98, 0.55, 0.70), Color(0.86, 0.42, 0.58), Color(0.99, 0.85, 0.35))
	tex["jflower_yellow"] = GenWorld._make_jflower(48, Color(0.99, 0.88, 0.35), Color(0.88, 0.72, 0.22), Color(0.55, 0.32, 0.12))
	tex["jflower_blue"] = GenWorld._make_jflower(48, Color(0.62, 0.72, 0.98), Color(0.45, 0.55, 0.86), Color(0.98, 0.92, 0.55))
	tex["jmushroom_red"] = GenWorld._make_jmushroom(52, Color(0.86, 0.24, 0.22))
	# Runde 26: neue Boss-Designs (prozedural statt zusammengeklebter Fremd-Teile)
	tex["boss_jungle"] = GenMonsters._make_boss_jungle()
	tex["boss_mars"] = GenMonsters._make_boss_mars()
	# Runde 34: Erde-Boss neu gezeichnet (mutierter Kristall-Roboter)
	tex["boss_earth"] = GenMonsters._make_boss_earth()
	# Runde 35: Elektro-Welt
	tex["volt_pylon"] = GenWorld._make_volt_pylon()
	tex["volt_capacitor"] = GenWorld._make_volt_capacitor()
	tex["volt_spool"] = GenWorld._make_volt_spool()
	tex["volt_wreck"] = GenWorld._make_volt_wreck()
	tex["volt_antenna"] = GenWorld._make_volt_antenna()
	tex["monster_volt_drone"] = GenMonsters._make_monster_volt_drone()
	tex["monster_volt_trooper"] = GenMonsters._make_monster_volt_trooper()
	tex["monster_volt_spider"] = GenMonsters._make_monster_volt_spider()
	# Runde 49: Neuer Elektro-Gegner - der SPULENTROOPER
	tex["monster_volt_spooler"] = GenMonsters._make_monster_volt_spooler()
	tex["boss_volt"] = GenMonsters._make_boss_volt()
	# Runde 38: Character-Rigs
	tex["arrow_marker"] = GenUi._make_arrow_marker()
	tex["force_field"] = GenUi._make_force_field()
	tex["boss_mini_jungle"] = GenMonsters._make_mini_jungle()
	tex["boss_mini_mars"] = GenMonsters._make_mini_mars()
	tex["boss_mini_earth"] = GenMonsters._make_mini_earth()
	tex["boss_mini_volt"] = GenMonsters._make_mini_volt()
	tex["bamboo"] = GenWorld._make_bamboo_pixel()
	tex["jleafpile"] = GenWorld._make_jleafpile(96)
	tex["fern"] = GenWorld._make_fern(64)
	tex["mushroom"] = GenWorld._make_mushroom(40)
	tex["monster_mars_drone"] = GenMonsters._make_mars_drone()
	tex["monster_mars_guard"] = GenMonsters._make_mars_guard()
	tex["monster_robo_tiger"] = GenMonsters._make_robo_tiger()
	tex["monster_vine_trap"] = GenMonsters._make_vine_trap()
	# Runde 15: ECHTE Bilddateien (CC0 Kenney "Space Shooter" Meteoriten, mit PIL auf
	# Mars-Rostorange umgefaerbt, freigestellt + quadratisch zentriert) fuer den Mars.
	for i in range(1, 5):
		host._load_external("mars_big_%d" % i, "res://assets/rocks/mars_big_%d.png" % i)
		host._load_external("mars_mid_%d" % i, "res://assets/rocks/mars_mid_%d.png" % i)
		host._load_external("mars_small_%d" % i, "res://assets/rocks/mars_small_%d.png" % i)
	# Runde 57: Dschungel-Palme und -Buesche als echte PNGs (CC0 Kenney
	# "Background Elements", mit PIL gruen abgestimmt + schwarze Kontur
	# ergaenzt, damit sie neben den gezeichneten Figuren bestehen).
	host._load_external("jpalm_png", "res://assets/props/jungle_palm.png")
	host._load_external("jbush_big_png", "res://assets/props/jungle_bush_big.png")
	host._load_external("jbush_small_png", "res://assets/props/jungle_bush_small.png")
	# Runde 16 (Nutzerwahl A1/E2): echte CC0-PNGs ersetzen die gezeichneten Icons
	# Runde 17 (Nutzerfeedback): Waffen wieder im Comic-Stil (prozedural) - die
	# Rohr-Optik wirkte wie eine Tuer. Herzen/Schild/Trank/Bombe bleiben echte
	# PNGs, aber rot/blau eingefaerbt (Quelle war weiss) + eigene Upgrade-Icons.
	# Echte Props fuer Erde + Dschungel
	for i in range(1, 9):
		host._load_external("prop_tree_%d" % i, "res://assets/props/tree_%d.png" % i)
	for i in range(1, 7):
		host._load_external("prop_bush_%d" % i, "res://assets/props/bush_%d.png" % i)
	for i in range(1, 4):
		host._load_external("prop_stone_%d" % i, "res://assets/props/stone_%d.png" % i)
	host._load_external("prop_tree_snow", "res://assets/props/tree_snow.png")
	# Runde 21: Pixel-Art-Sprites fuer Bambus + Gras (Nutzerwunsch)
	# Boss-Rigs je Biom (Runde 16, Nutzerwahl B1)
