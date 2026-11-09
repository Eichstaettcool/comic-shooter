import io, os, urllib.request, urllib.parse
from PIL import Image

TMP = os.environ.get("TMPDIR", ".")
GAME = r'C:\Users\vince\Games\comic-shooter\project'
rows = [l.split('\t') for l in io.open(os.path.join(TMP, "kenney.tsv"), encoding='utf-8').read().splitlines() if l.strip()][1:]
BASE = "https://raw.githubusercontent.com/shorepine/kenney/master/"

# ---------- 0) Palme + langer Baum als Jungle-Props nachladen ----------
def grab(name, out):
    for r in rows:
        if os.path.basename(r[0]) == name and "Background Elements" in r[0]:
            dst = os.path.join(GAME, "assets", "props", out)
            if not os.path.exists(dst):
                try:
                    data = urllib.request.urlopen(BASE + urllib.parse.quote(r[0]), timeout=60).read()
                    io.open(dst, "wb").write(data)
                    im = Image.open(dst).convert("RGBA")
                    b = im.getbbox()
                    if b:
                        im.crop(b).save(dst)
                    print("geladen:", out, Image.open(dst).size, "aus", r[0])
                except Exception as e:
                    print("fehlt:", name, e)
                return
grab("treePalm.png", "tree_7.png")
grab("treeLong.png", "tree_8.png")
grab("treePineSnow.png", "tree_snow.png")

# ---------- 1) TextureManager: echte PNGs laden ----------
T = os.path.join(GAME, "scripts", "texture_manager.gd")
t = io.open(T, encoding='utf-8').read()
t = t.replace('''	for i in range(1, 5):
		_load_external("mars_big_%d" % i, "res://assets/rocks/mars_big_%d.png" % i)
		_load_external("mars_mid_%d" % i, "res://assets/rocks/mars_mid_%d.png" % i)
		_load_external("mars_small_%d" % i, "res://assets/rocks/mars_small_%d.png" % i)''',
'''	for i in range(1, 5):
		_load_external("mars_big_%d" % i, "res://assets/rocks/mars_big_%d.png" % i)
		_load_external("mars_mid_%d" % i, "res://assets/rocks/mars_mid_%d.png" % i)
		_load_external("mars_small_%d" % i, "res://assets/rocks/mars_small_%d.png" % i)
	# Runde 16 (Nutzerwahl A1/E2): echte CC0-PNGs ersetzen die gezeichneten Icons
	for k in ["heart_full", "heart_empty", "heart_gold", "shield", "potion", "bomb",
			"weapon_pistol", "weapon_shotgun", "weapon_machine", "weapon_laser", "weapon_revolver"]:
		_load_external(k, "res://assets/items/%s.png" % k)
	# Echte Props fuer Erde + Dschungel
	for i in range(1, 9):
		_load_external("prop_tree_%d" % i, "res://assets/props/tree_%d.png" % i)
	for i in range(1, 7):
		_load_external("prop_bush_%d" % i, "res://assets/props/bush_%d.png" % i)
	for i in range(1, 4):
		_load_external("prop_stone_%d" % i, "res://assets/props/stone_%d.png" % i)
	_load_external("prop_tree_snow", "res://assets/props/tree_snow.png")
	# Boss-Rigs je Biom (Runde 16, Nutzerwahl B1)
	for nm in ["mars", "jungle", "earth"]:
		_load_external("boss_" + nm, "res://assets/bosses/boss_%s.png" % nm)''', 1)
io.open(T, 'w', encoding='utf-8').write(t)
print("texture_manager:", len(t), "| props:", t.count("prop_tree"), "| bosses:", t.count("boss_mars"))

# ---------- 2) map_generator: weicher Boden + Platzierungsregeln + echte Props ----------
G = os.path.join(GAME, "scripts", "map_generator.gd")
g = io.open(G, encoding='utf-8').read()

# 2a) Boden: 4x Aufloesung + kubische Glaettung statt 1px/Tile NEAREST
g = g.replace('''	# 1) Basiskaro: 1 Pixel pro Tile, mit NEAREST hochskaliert''',
'''	# 1) Basiskaro (Runde 16): Muster in 1 px/Tile berechnen, dann KUBISCH weich
	# hochskalieren -> keine harten Pixelkanten mehr (Nutzerwahl D1: weicher Boden)''', 1)
g = g.replace('''	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST''',
'''	var _pp: int = [3, 6, 9][clampi(detail_level, 0, 2)]      # Pixel pro Tile je Grafikstufe
	img.resize(cols * _pp, rows * _pp, Image.INTERPOLATE_CUBIC)
	base_sprite.texture = ImageTexture.create_from_image(img)
	base_sprite.scale = Vector2(float(tile_size) / float(_pp), float(tile_size) / float(_pp))
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR''', 1)

# 2b) Platzierung: Mindestabstand + Hoehen-basierte Skalierung + Fuss-Punkt (Kronen-Ebene)
g = g.replace('''	var positions = get_random_walkable_positions(maxi(12, total + 8), 6)
	var pi := 0
	var world_w: float = map_size.x * tile_size
	var world_h: float = map_size.y * tile_size''',
'''	var positions = get_random_walkable_positions(maxi(40, total * 3 + 12), 6)
	var pi := 0
	var world_w: float = map_size.x * tile_size
	var world_h: float = map_size.y * tile_size
	var placed: Array = []          # [Vector2, radius] -> verhindert Kronen-Ueberlappung''', 1)

g = g.replace('''			var cnt := randi_range(int(sp["cmin"]), int(sp["cmax"]))
			for k in range(cnt):
				var spread := 34.0 + 26.0 * float(sp["smax"])
				var pos2: Vector2 = center + Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
				if pos2.x < 130.0 or pos2.y < 130.0 or pos2.x > world_w - 130.0 or pos2.y > world_h - 130.0:
					continue
				var spr := Sprite2D.new()
				var tex_key := str(sp["tex"])
				if sp.has("texs"):
					var _vs: Array = sp["texs"]
					tex_key = str(_vs[randi() % _vs.size()])
				spr.texture = TextureManager.get_texture(tex_key)
				if tex_key.begins_with("mars_"):
					spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # echte Fotos, kein Pixel-Look
				var sc := randf_range(float(sp["smin"]), float(sp["smax"]))
				spr.scale = Vector2(sc, sc)
				spr.position = pos2
				spr.z_index = -5 if str(sp["kind"]) == "crater" else 0
				var rbase := float(sp.get("rbase", sp["radius"]))
				if rbase > 0.0:
					_add_collision_body(spr, rbase, float(sp.get("yoff", 0.0)))''',
'''			var cnt := randi_range(int(sp["cmin"]), int(sp["cmax"]))
			for k in range(cnt):
				var spread := 34.0 + 26.0 * float(sp["smax"])
				var placed_ok := false
				var spr: Sprite2D = null
				for _try in range(8):
					var pos2: Vector2 = center + Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
					if pos2.x < 150.0 or pos2.y < 150.0 or pos2.x > world_w - 150.0 or pos2.y > world_h - 150.0:
						continue
					var tex_key0 := str(sp["tex"])
					if sp.has("texs"):
						var _vs0: Array = sp["texs"]
						tex_key0 = str(_vs0[randi() % _vs0.size()])
					var _tex := TextureManager.get_texture(tex_key0)
					if _tex == null:
						continue
					var sc0 := randf_range(float(sp["smin"]), float(sp["smax"]))
					if sp.has("hmin"):      # Hoehe in px vorgeben (echte Props sind unterschiedlich gross)
						var ts: Vector2 = _tex.get_image().get_size()
						var want := randf_range(float(sp["hmin"]), float(sp["hmax"]))
						sc0 = want / maxf(1.0, ts.y)
					var vis_r := 0.5 * float(sp.get("rbase", sp["radius"])) * sc0
					var blocked := false
					for pl in placed:
						var need: float = (vis_r + float(pl[1])) * 0.92
						if pos2.distance_to(pl[0]) < need:
							blocked = true
							break
					if blocked:
						continue
					spr = Sprite2D.new()
					spr.texture = _tex
					spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
					spr.scale = Vector2(sc0, sc0)
					spr.position = pos2
					spr.z_index = -5 if str(sp["kind"]) == "crater" else 0
					if bool(sp.get("foot", false)):
						# Fuss-Punkt: Sortier-/Kollisionspunkt an der Objektbasis (Kronen-Ebene)
						var ts2: Vector2 = _tex.get_image().get_size()
						spr.offset = Vector2(0.0, -ts2.y * 0.5 + ts2.y * float(sp.get("footat", 0.88)))
					placed.append([pos2, vis_r])
					placed_ok = true
					break
				if not placed_ok or spr == null:
					continue
				var rbase := float(sp.get("rbase", sp["radius"]))
				if rbase > 0.0:
					_add_collision_body(spr, rbase, float(sp.get("yoff", 0.0)))''', 1)

# 2c) Erde + Jungle auf echte Props umstellen
old_earth = '''		"obstacles": [
			{ "kind": "tree", "tex": "tree", "clusters": 62, "smin": 0.9, "smax": 1.25, "radius": 12.0, "rbase": 11.0, "yoff": 12.0, "cmin": 1, "cmax": 2 },
			{ "kind": "rock", "tex": "rock", "clusters": 40, "smin": 0.8, "smax": 1.3, "radius": 10.0, "rbase": 9.0, "yoff": 6.0, "cmin": 1, "cmax": 2 }
		]'''
new_earth = '''		"obstacles": [
			# echte Baum-PNGs (Runde 16, Nutzerwahl E2)
			{ "kind": "tree", "tex": "prop_tree_1", "texs": ["prop_tree_1", "prop_tree_4", "prop_tree_5"],
			  "clusters": 52, "hmin": 110.0, "hmax": 190.0, "smin": 0.3, "smax": 0.5,
			  "radius": 30.0, "rbase": 42.0, "yoff": -30.0, "foot": true, "footat": 0.94, "cmin": 1, "cmax": 2 },
			{ "kind": "tree", "tex": "prop_tree_2", "texs": ["prop_tree_2", "prop_tree_3"],
			  "clusters": 26, "hmin": 60.0, "hmax": 110.0, "smin": 0.5, "smax": 1.0, "radius": 16.0, "rbase": 16.0, "yoff": -10.0, "cmin": 1, "cmax": 3 },
			{ "kind": "rock", "tex": "prop_stone_1", "texs": ["prop_stone_1", "prop_stone_2", "prop_stone_3"],
			  "clusters": 30, "hmin": 40.0, "hmax": 80.0, "smin": 0.6, "smax": 1.2, "radius": 18.0, "rbase": 16.0, "yoff": 4.0, "cmin": 1, "cmax": 2 }
		]'''
if old_earth in g:
    g = g.replace(old_earth, new_earth, 1)
else:
    print("WARN Erde-Spec nicht gefunden")

old_jungle = '''		"obstacles": [
			{ "kind": "tree", "tex": "jungle_tree", "clusters": 32, "smin": 1.1, "smax": 2.1, "radius": 20.0, "rbase": 21.0, "yoff": 46.0, "cmin": 1, "cmax": 3 },
			{ "kind": "tree", "tex": "bamboo", "clusters": 38, "smin": 0.9, "smax": 1.5, "radius": 12.0, "rbase": 9.0, "yoff": 42.0, "cmin": 3, "cmax": 6 },
			{ "kind": "rock", "tex": "fern", "clusters": 30, "smin": 0.8, "smax": 1.5, "radius": 8.0, "rbase": 8.0, "yoff": 14.0, "cmin": 2, "cmax": 4 },
			{ "kind": "rock", "tex": "bush", "clusters": 18, "smin": 0.8, "smax": 1.3, "radius": 9.0, "rbase": 9.0, "yoff": 12.0, "cmin": 1, "cmax": 3 }
		]'''
new_jungle = '''		"obstacles": [
			# echte Palmen + Buesche (Runde 16, Nutzerwahl D1) mit Mindestabstand -> keine Kronen-Ueberlappung
			{ "kind": "tree", "tex": "prop_tree_7", "texs": ["prop_tree_7", "prop_tree_8"],
			  "clusters": 24, "hmin": 170.0, "hmax": 300.0, "smin": 0.4, "smax": 0.65,
			  "radius": 34.0, "rbase": 46.0, "yoff": -34.0, "foot": true, "footat": 0.95, "cmin": 1, "cmax": 2 },
			{ "kind": "tree", "tex": "prop_tree_1", "texs": ["prop_tree_1", "prop_tree_4"],
			  "clusters": 20, "hmin": 130.0, "hmax": 210.0, "smin": 0.3, "smax": 0.45,
			  "radius": 28.0, "rbase": 40.0, "yoff": -28.0, "foot": true, "footat": 0.94, "cmin": 1, "cmax": 2 },
			{ "kind": "rock", "tex": "prop_bush_1", "texs": ["prop_bush_1", "prop_bush_5"],
			  "clusters": 34, "hmin": 70.0, "hmax": 140.0, "smin": 0.3, "smax": 0.6, "radius": 18.0, "rbase": 26.0, "yoff": -12.0, "cmin": 2, "cmax": 4 },
			{ "kind": "rock", "tex": "prop_bush_2", "texs": ["prop_bush_2", "prop_bush_3", "prop_bush_4", "prop_bush_6"],
			  "clusters": 30, "hmin": 45.0, "hmax": 95.0, "smin": 0.4, "smax": 0.8, "radius": 14.0, "rbase": 20.0, "yoff": -8.0, "cmin": 1, "cmax": 3 }
		]'''
if old_jungle in g:
    g = g.replace(old_jungle, new_jungle, 1)
else:
    print("WARN Jungle-Spec nicht gefunden")
io.open(G, 'w', encoding='utf-8').write(g)
print("map_generator:", len(g), "| prop_tree:", g.count("prop_tree"), "| foot:", g.count('"foot"'))

# ---------- 3) Qualitaet NUR optisch (C1) ----------
S = os.path.join(GAME, "scripts", "game_manager.gd")
s = io.open(S, encoding='utf-8').read()
s = s.replace('''	if quality == 0:
		monster_spawner.quality_mult = 1.40''','''	# Runde 16 (C1): Grafikstufe darf das Gameplay NICHT veraendern.
	# Gegnerzahl, Zonen und Schwierigkeit sind auf jeder Stufe identisch.
	if false:
		monster_spawner.quality_mult = 1.40''', 1)
s = s.replace('var num_zones: int = [1, 2, 3][clampi(quality, 0, 2)]', 'var num_zones: int = 2   # Runde 16 (C1): fest, nicht mehr an die Grafikstufe gekoppelt', 1)
io.open(S, 'w', encoding='utf-8').write(s)
print("game_manager:", len(s), "| quality_mult entkoppelt:", s.count("if false:") , "| zonen fix:", s.count("var num_zones: int = 2"))
