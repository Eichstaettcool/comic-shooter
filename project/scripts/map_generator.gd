# MapGenerator.gd - Erstellt Karo-Muster Karte mit Bäumen und Steinen
extends Node2D

var map_size: Vector2 = Vector2(25, 25)
var tile_size: int = 32
var walkable_positions: Array[Vector2] = []
var obstacles: Array = []
var obstacle_kinds: Array = []
var biome_id: String = "meadow"
var detail_level: int = 2          # Grafikstufe: 2 = alle Details, 1 = nur Sprenkel, 0 = nur Karo

# --- Visual-Layer: frueher ~19.000 Draw-Calls/Frame, jetzt 3-4 ---
var base_sprite: Sprite2D = null
var grid_sprite: Sprite2D = null
var specks_mm: MultiMeshInstance2D = null
var plants_mm: MultiMeshInstance2D = null
var flowers_mm: MultiMeshInstance2D = null
var flower_tex: ImageTexture = null

# --- Biome (Agenda G4): Palette + Deko je Biom ---
var _ground_cache: Dictionary = {}       # Runde 35b: Boden-Bilder cachen (Ladezeit)

const BIOMES := {
	# Runde 35: Elektro-Welt - dunkles Stahlblau mit gelben Energieleitungen
	"volt": {
		"light": Color(0.27, 0.30, 0.45), "dark": Color(0.17, 0.19, 0.30),
		"grid": Color(0.45, 0.50, 0.70, 0.22),
		"speck_a": Color(0.55, 0.60, 0.80, 0.50), "speck_b": Color(0.98, 0.86, 0.30, 0.45),
		"plant": Color(0.60, 0.66, 0.85, 0.80),
		"flower_a": Color(1.0, 0.85, 0.25), "flower_b": Color(0.55, 0.90, 1.0),
		"tree": "volt_pylon", "rock": "volt_capacitor"
	},
	"meadow": {
		"light": Color(0.60, 0.85, 0.50), "dark": Color(0.45, 0.70, 0.35),
		"grid": Color(0.25, 0.45, 0.20, 0.20),
		"speck_a": Color(0.30, 0.55, 0.28, 0.55), "speck_b": Color(0.75, 0.95, 0.60, 0.45),
		"plant": Color(0.20, 0.45, 0.18, 0.85),
		"flower_a": Color(1.0, 0.45, 0.60), "flower_b": Color(1.0, 0.90, 0.30),
		"tree": "tree", "rock": "rock"
	},
	"desert": {
		"light": Color(0.93, 0.82, 0.55), "dark": Color(0.84, 0.72, 0.45),
		"grid": Color(0.55, 0.42, 0.20, 0.18),
		"speck_a": Color(0.75, 0.62, 0.35, 0.55), "speck_b": Color(1.0, 0.95, 0.75, 0.45),
		"plant": Color(0.45, 0.55, 0.25, 0.85),
		"flower_a": Color(0.95, 0.55, 0.25), "flower_b": Color(0.90, 0.85, 0.55),
		"tree": "cactus", "rock": "rock_desert"
	},
	"ice": {
		"light": Color(0.80, 0.90, 0.98), "dark": Color(0.66, 0.80, 0.94),
		"grid": Color(0.35, 0.55, 0.75, 0.18),
		"speck_a": Color(0.92, 0.97, 1.0, 0.60), "speck_b": Color(0.60, 0.78, 0.95, 0.45),
		"plant": Color(0.40, 0.62, 0.75, 0.85),
		"flower_a": Color(1.0, 1.0, 1.0), "flower_b": Color(0.75, 0.92, 1.0),
		"tree": "pine", "rock": "ice_rock"
	},
	"lava": {
		"light": Color(0.32, 0.22, 0.24), "dark": Color(0.24, 0.16, 0.18),
		"grid": Color(0.55, 0.22, 0.15, 0.25),
		"speck_a": Color(0.55, 0.20, 0.12, 0.55), "speck_b": Color(1.0, 0.55, 0.15, 0.45),
		"plant": Color(0.45, 0.18, 0.12, 0.85),
		"flower_a": Color(1.0, 0.50, 0.15), "flower_b": Color(0.95, 0.75, 0.25),
		"tree": "dead_tree", "rock": "lava_rock"
	},
	"mars": {
		"light": Color(0.74, 0.38, 0.28), "dark": Color(0.58, 0.27, 0.20),
		"grid": Color(0.35, 0.12, 0.08, 0.25),
		"speck_a": Color(0.45, 0.18, 0.12, 0.55), "speck_b": Color(0.95, 0.62, 0.42, 0.40),
		"plant": Color(0.50, 0.24, 0.16, 0.85),
		"flower_a": Color(1.0, 0.55, 0.25), "flower_b": Color(0.85, 0.35, 0.20),
		"tree": "mars_rock", "rock": "mars_crater"
	},
	"jungle": {
		"light": Color(0.26, 0.54, 0.28), "dark": Color(0.16, 0.40, 0.20),
		"grid": Color(0.10, 0.28, 0.12, 0.25),
		"speck_a": Color(0.14, 0.38, 0.16, 0.55), "speck_b": Color(0.55, 0.85, 0.40, 0.40),
		"plant": Color(0.10, 0.35, 0.14, 0.90),
		"flower_a": Color(1.0, 0.75, 0.20), "flower_b": Color(0.95, 0.35, 0.65),
		"tree": "palm", "rock": "bush"
	}
}

const SEASON_TINT := {
	"": Color(1, 1, 1),
	"spring": Color(1.00, 1.04, 0.98),
	"summer": Color(1.14, 1.04, 0.66),
	"autumn": Color(1.20, 0.86, 0.52),
	"winter": Color(1.00, 1.00, 1.00)
}
# Misch-Anteil Richtung Schneefarbe (Multiply kann nicht aufhellen)
const SEASON_MIX := { "": 0.0, "spring": 0.0, "summer": 0.0, "autumn": 0.0, "winter": 0.62, "mars_winter": 0.55 }
const SEASON_MIX_COLOR := { "": Color(1, 1, 1), "spring": Color(1, 1, 1), "summer": Color(1, 1, 1),
	"autumn": Color(1, 1, 1), "winter": Color(0.93, 0.96, 1.0) }
const SEASON_OBST := {
	"": Color(1, 1, 1),
	"spring": Color(1.05, 1.12, 1.05),
	"summer": Color(1.06, 1.00, 0.70),
	"autumn": Color(1.18, 0.78, 0.42),
	"winter": Color(0.80, 0.88, 1.00),
	# Runde 38: die Elektro-Welt-Jahreszeiten
	"sturm": Color(0.86, 0.94, 1.18),      # Gewitter: kuehl-blaues Flackern
	"ueberlast": Color(1.24, 0.72, 0.60),   # Ueberlast: gluehend rot
	"blackout": Color(0.52, 0.54, 0.72),    # Blackout: dunkel und kalt
	"nebel": Color(0.92, 0.96, 0.98)        # Nebel: milchig
}

var season_id: String = ""

func set_season(sid: String) -> void:
	season_id = sid
	# Baum-Textur je Jahreszeit: Sommer schuetter, Winter nackt
	var ty := str(BIOMES.get(biome_id, BIOMES["meadow"]).get("tree", "tree"))
	if biome_id == "jungle":
		ty = "dead_tree" if sid == "winter" else ("bush" if sid == "summer" else "palm")
	for i in range(obstacles.size()):
		var spr = obstacles[i]
		if not is_instance_valid(spr) or not (spr is Sprite2D):
			continue
		if i < obstacle_kinds.size() and str(obstacle_kinds[i]) == "tree":
			spr.texture = TextureManager.get_texture(ty)
		spr.modulate = SEASON_OBST.get(sid, Color(1, 1, 1))
	rebuild_visuals()

func set_biome(id: String) -> void:
	if not BIOMES.has(id):
		return
	biome_id = id
	# Vorhandene Deko auf die neuen Texturen umstellen (Baum<->Kaktus usw.)
	var b: Dictionary = BIOMES[id]
	for i in range(obstacles.size()):
		var spr = obstacles[i]
		if not is_instance_valid(spr) or not (spr is Sprite2D):
			continue
		var kind = obstacle_kinds[i] if i < obstacle_kinds.size() else "tree"
		spr.texture = TextureManager.get_texture(str(b.get(kind, b["tree"])))
	rebuild_visuals()
	queue_redraw()

func get_biome() -> String:
	return biome_id

func _ready() -> void:
	# Hintergrund immer hinter allem anderen zeichnen
	z_index = -10

var _shadow_tex: Texture2D = null


func _get_shadow_tex() -> Texture2D:
	# Runde 58: weicher, radialer Schatten (64px) fuer Props - gibt Tiefe
	if _shadow_tex != null:
		return _shadow_tex
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(64):
		for x in range(64):
			var dx: float = (float(x) - 31.5) / 31.5
			var dy: float = (float(y) - 31.5) / 31.5
			var d: float = sqrt(dx * dx + dy * dy)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a * 0.20
			if a > 0.002:
				img.set_pixel(x, y, Color(0.05, 0.10, 0.06, a))
	_shadow_tex = ImageTexture.create_from_image(img)
	return _shadow_tex


# Runde 65: eigener Zufallsgenerator fuer die Karte. Vorher lief alles ueber
# die GLOBALEN rng.randf()/rng.randi(). Der globale Zustand haengt aber davon ab, wie
# viele Zufallszahlen vorher verbraucht wurden - auf Host und Client war das
# unterschiedlich, deshalb kamen trotz gleichem Seed zwei verschiedene Karten
# heraus (Fluss, Baeume, Kisten an anderen Stellen).
var rng := RandomNumberGenerator.new()
var map_seed: int = 0


func generate_map(cols: int, rows: int, tile_sz: int, seed_value: int = 0) -> void:
	if seed_value != 0:
		map_seed = seed_value
	if map_seed == 0:
		map_seed = int(Time.get_unix_time_from_system() * 1000.0)
	rng.seed = map_seed
	map_size = Vector2(cols, rows)
	tile_size = tile_sz
	walkable_positions.clear()

	for x in range(cols):
		for y in range(rows):
			var pos = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)
			walkable_positions.append(pos)

	_carve_river(cols, rows)
	rebuild_visuals()

func _carve_river(cols: int, rows: int) -> void:
	# Bugfix Runde 20: alte Fluss-Nodes IMMER freigeben. Vorher stapelten sich die
	# unsichtbaren Wasser-Waende bei jedem Lauf -> Spieler blieb ueberall haengen
	# ("Hitboxen zerschossen").
	for n in river_nodes:
		if is_instance_valid(n):
			n.queue_free()
	river_nodes.clear()
	river_axis = 0
	river_tiles.clear()
	bridges.clear()
	if not bool(_terrain().get("river", false)):
		return
	var axis: int = 1 if rng.randf() < 0.5 else 2      # 1 = Nord-Sued, 2 = West-Ost
	var span: int = rows if axis == 1 else cols
	var across: int = cols if axis == 1 else rows
	var base_pos: float = float(across) * (0.28 if rng.randf() < 0.5 else 0.72)
	var amp: float = 3.0
	var hw: float = 1.6
	var phase: float = rng.randf() * TAU
	var water: Dictionary = {}
	for i in range(span):
		var center: float = base_pos + sin(float(i) * 0.09 + phase) * amp
		for d in range(-int(hw), int(hw) + 1):
			var p: int = int(round(center)) + d
			if p < 1 or p >= across - 1:
				continue
			var tl: Vector2i = Vector2i(p, i) if axis == 1 else Vector2i(i, p)
			water[tl] = true
	# Runde 22: 3-4 Bruecken gleichmaessig verteilt. Das Wasser bleibt DURCHGEHEND
	# (Optik), nur die KOLLISION hat an der Bruecke eine Luecke -> der Fluss wird
	# nicht mehr aufgerissen (vorher "weisse Flecken" und "Fluss hoert auf").
	var nbr: int = 3 if rng.randf() < 0.5 else 4
	if across < 60:
		nbr = 2
	var seg: float = float(span) / float(nbr + 1)
	for bi in range(nbr):
		var at: int = int(seg * float(bi + 1))
		at = clampi(at, 8, span - 9)
		var ctr: int = int(round(base_pos + sin(float(at) * 0.09 + phase) * amp))
		bridges.append({ "axis": axis, "at": at, "cross": ctr, "half": int(hw) + 1 })
	for k in water.keys():
		river_tiles.append(k)
	# Wasser aus den begehbaren Positionen entfernen (kein Spawn/Monster im Fluss)
	var keep_pos: Array[Vector2] = []
	for p in walkable_positions:
		var tx: int = int(p.x / tile_size)
		var ty: int = int(p.y / tile_size)
		if not water.has(Vector2i(tx, ty)):
			keep_pos.append(p)
	walkable_positions = keep_pos
	river_axis = axis
	_build_river_walls(water)
	_build_water_layer(cols, rows)
	_build_bridges()
	print("FLUSS achse=", axis, " tiles=", river_tiles.size(), " bruecken=", bridges.size())

func _build_water_layer(cols: int, rows: int) -> void:
	# Wasser als eigene, krispe und ANIMIERTE Ebene: Maske in 8 px/Tile.
	# v1.42 (P7): Die Maske traegt jetzt ZWEI Kanaele - R = Uferkante (Schaum),
	# G = Tiefe (0 am Ufer, 1 in der Flussmitte). Damit bekommt der Shader
	# Tiefenwirkung (4 Blautoene) und einen Flussrichtungs-Offset.
	if river_tiles.size() == 0:
		return
	var minx := 9999
	var maxx := -9999
	var miny := 9999
	var maxy := -9999
	for t in river_tiles:
		var tv: Vector2i = t
		minx = mini(minx, tv.x)
		maxx = maxi(maxx, tv.x)
		miny = mini(miny, tv.y)
		maxy = maxi(maxy, tv.y)
	minx = maxi(0, minx - 1)
	maxx = mini(cols - 1, maxx + 1)
	miny = maxi(0, miny - 1)
	maxy = mini(rows - 1, maxy + 1)
	var pw := maxx - minx + 1
	var ph_ := maxy - miny + 1
	var pp := 8
	var wset: Dictionary = {}
	for t in river_tiles:
		wset[t] = true
	# --- Tiefe je Kachel (Abstand zum Ufer, 0..1) ---
	var depth_of: Dictionary = {}
	var nahes: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	var tief_max := 3
	for tx in range(pw):
		for ty in range(ph_):
			var tt := Vector2i(minx + tx, miny + ty)
			if not wset.has(tt):
				continue
			var d := 0
			for r in range(1, tief_max + 1):
				var rand_getroffen := false
				for dv in nahes:
					if not wset.has(tt + dv * r):
						rand_getroffen = true
						break
				if rand_getroffen:
					break
				d += 1
			depth_of[tt] = float(d) / float(tief_max)
	# --- Steine IM Fluss: v1.43 (S5.2) entfernt ---
	# Vorher lagen 3 Deko-Steine auf der Wasserflaeche und der Shader liess um
	# jede Kachel im 3x3-Umfeld einen weissen Ring pulsieren - das las sich wie
	# ein Fehler, weil dort kein Wasser bricht. Der Fluss ist schmal; die Steine
	# wirkten wie Dreck. Also: keine Steine im Wasser, kein Stein-Schaum.
	var fluß_steine: Array = []
	# --- Pixelmaske ---
	var img := Image.create(pw * pp, ph_ * pp, false, Image.FORMAT_RGBA8)
	var foam_kanten := 0
	for px in range(pw * pp):
		for py in range(ph_ * pp):
			var tx2: int = minx + int(px / pp)
			var ty2: int = miny + int(py / pp)
			var key := Vector2i(tx2, ty2)
			if not wset.has(key):
				continue
			var foam := 0.0
			for d3 in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if not wset.has(key + d3):
					foam = 1.0
					break
			if foam > 0.0:
				foam_kanten += 1
			var dep: float = float(depth_of.get(key, 0.0))
			# R = Uferkante (pulsierender Schaum), G = Tiefe, B = Stein-Schaum (immer 0)
			img.set_pixel(px, py, Color(foam, dep, 0.0, 1.0))
	var spr := Sprite2D.new()
	spr.name = "WaterLayer"
	spr.centered = false
	spr.texture = ImageTexture.create_from_image(img)
	spr.position = Vector2(float(minx) * tile_size, float(miny) * tile_size)
	spr.scale = Vector2(float(tile_size) / float(pp), float(tile_size) / float(pp))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index = -8
	var mat := ShaderMaterial.new()
	var sh = load("res://shaders/water.gdshader")
	var flow := Vector2(0.0, 1.0)
	var achse := 1
	for b in bridges:
		achse = int(b["axis"])
		break
	if achse == 2:
		flow = Vector2(1.0, 0.0)
	if sh != null:
		mat.shader = sh
		mat.set_shader_parameter("tiles", Vector2(float(pw), float(ph_)))
		mat.set_shader_parameter("flow_dir", flow)
		mat.set_shader_parameter("speed", 0.30)
	spr.material = mat
	add_child(spr)
	river_nodes.append(spr)
	# v1.43 (S5.2): keine Deko-Steine mehr auf der Wasserflaeche
	var toene: Array = [Color(0.36, 0.68, 0.86), Color(0.24, 0.56, 0.78), Color(0.14, 0.42, 0.66), Color(0.06, 0.27, 0.48)]
	var hmin := 9.9
	var hmax := -1.0
	for c in toene:
		var lum: float = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
		hmin = minf(hmin, lum)
		hmax = maxf(hmax, lum)
	print("[ART][WASSER] toene=%d min_helligkeit=%.2f max=%.2f foam_kanten=%d steine_im_fluss=%d foam_steine=keine foam_ufer=puls flow_dir=(%.0f,%.0f) tiefe_kanaele=1" % [
		toene.size(), hmin, hmax, foam_kanten, fluß_steine.size(), flow.x, flow.y])
	_water_river_stones = fluß_steine


var _water_river_stones: Array = []


func _build_bridges() -> void:
	# Bruecken sichtbar ueber dem Wasser (z_index -7) und genau so breit wie das Deck
	for b in bridges:
		var br := Sprite2D.new()
		br.name = "Bridge"
		br.texture = TextureManager.get_texture("bridge")
		br.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		br.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		br.centered = true
		br.z_index = -7
		var at: int = int(b["at"])
		var cross: int = int(b["cross"])
		var half: int = int(b["half"])
		if int(b["axis"]) == 1:
			# Fluss Nord-Sued -> Bruecke quer, 2 Tiles Ueberlappung je Ufer
			var wdt: float = float(half * 2 + 1) * tile_size
			var hgt: float = 3.0 * tile_size
			br.region_enabled = true
			br.region_rect = Rect2(0.0, 0.0, wdt, hgt)
			br.position = Vector2(float(cross) * tile_size + tile_size * 0.5, float(at) * tile_size + tile_size * 0.5)
		else:
			br.rotation = PI * 0.5
			var wdt2: float = float(half * 2 + 1) * tile_size
			br.region_enabled = true
			br.region_rect = Rect2(0.0, 0.0, wdt2, 3.0 * tile_size)
			br.position = Vector2(float(at) * tile_size + tile_size * 0.5, float(cross) * tile_size + tile_size * 0.5)
		add_child(br)
		river_nodes.append(br)

func _build_river_walls(water: Dictionary) -> void:
	# Wasser = Wand auf Layer 16; Brueckenreihen bleiben offen -> nur dort queren
	var open_rows: Dictionary = {}
	for b in bridges:
		for k in range(int(b["at"]) - 1, int(b["at"]) + 2):     # nur das Deck (3 Tiles)
			open_rows[k] = true
	if river_axis == 1:
		for y in range(int(map_size.y)):
			if open_rows.has(y):
				continue
			_water_run(y, true, water)
	else:
		for x in range(int(map_size.x)):
			if open_rows.has(x):
				continue
			_water_run(x, false, water)

func _water_run(idx: int, vertical: bool, water: Dictionary) -> void:
	var limit: int = int(map_size.x) if vertical else int(map_size.y)
	var start: int = -1
	for i in range(limit + 1):
		var t: Vector2i = Vector2i(i, idx) if vertical else Vector2i(idx, i)
		var isw: bool = (i < limit) and water.has(t)
		if isw and start < 0:
			start = i
		elif not isw and start >= 0:
			var r: Rect2 = Rect2(float(start) * tile_size, float(idx) * tile_size, float(i - start) * tile_size, tile_size) if vertical else Rect2(float(idx) * tile_size, float(start) * tile_size, tile_size, float(i - start) * tile_size)
			var body := StaticBody2D.new()
			body.collision_layer = 16
			body.collision_mask = 0
			body.position = r.position + r.size * 0.5
			var col := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = r.size
			col.shape = shape
			body.add_child(col)
			add_child(body)
			river_nodes.append(body)
			start = -1

func _draw() -> void:
	# Bewusst leer: Hintergrund wird jetzt von base_sprite/grid_sprite/MultiMeshes
	# gezeichnet (1 Draw-Call je Layer statt ~19.000 Einzel-Rects pro Frame).
	pass

# ============================================================
# VISUALS: 1 Bild-Sprite + 1 Raster-Sprite + 3 MultiMeshes
# (vorher ~19.000 Draw-Calls pro Frame, jetzt 3-5)
# ============================================================
func rebuild_visuals() -> void:
	var cols := int(map_size.x)
	var rows := int(map_size.y)
	var B: Dictionary = BIOMES.get(biome_id, BIOMES["meadow"]).duplicate()
	var tint: Color = SEASON_TINT.get(season_id, Color(1, 1, 1))
	var mix: float = float(SEASON_MIX.get(season_id, 0.0))
	var mixcol: Color = SEASON_MIX_COLOR.get(season_id, Color(1, 1, 1))
	for key in ["light", "dark", "grid", "speck_a", "speck_b", "plant", "flower_a", "flower_b"]:
		if B.has(key):
			var c: Color = B[key]
			var t := Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a)
			if mix > 0.0:
				t = t.lerp(Color(mixcol.r, mixcol.g, mixcol.b, c.a), mix)
			B[key] = t
	# Jahreszeit-Details: Schnee bzw. Laub
	if season_id == "winter":
		# v1.48 (A3): Erde bekommt echten Schnee - die reine 0,62-Mischung
		# blieb gruenlich. Jetzt feste Schneetoene fuer Boden und Deko.
		B["light"] = Color(0.90, 0.94, 0.99)
		B["dark"] = Color(0.79, 0.86, 0.95)
		B["grid"] = Color(0.70, 0.79, 0.90)
		B["speck_a"] = Color(0.86, 0.91, 0.97)
		B["speck_b"] = Color(1.0, 1.0, 1.0, 0.90)
		B["plant"] = Color(0.74, 0.84, 0.93)
		B["flower_a"] = Color(0.90, 0.95, 1.0)
		B["flower_b"] = Color(0.82, 0.90, 0.98)
		print("[SEASON][SCHNEE] biome=%s light=#%02x%02x%02x dark=#%02x%02x%02x" % [
			biome_id, int(0.90 * 255), int(0.94 * 255), int(0.99 * 255),
			int(0.79 * 255), int(0.86 * 255), int(0.95 * 255)])
	elif season_id == "sturm":
		B["light"] = Color(0.26, 0.30, 0.46)
		B["dark"] = Color(0.16, 0.19, 0.32)
		B["speck_b"] = Color(0.75, 0.90, 1.0, 0.45)
		B["flower_a"] = Color(0.70, 0.90, 1.0)
	elif season_id == "ueberlast":
		B["light"] = Color(0.34, 0.24, 0.26)
		B["dark"] = Color(0.20, 0.14, 0.16)
		B["speck_b"] = Color(1.0, 0.60, 0.30, 0.50)
		B["flower_a"] = Color(1.0, 0.55, 0.25)
	elif season_id == "blackout":
		B["light"] = Color(0.13, 0.14, 0.20)
		B["dark"] = Color(0.08, 0.09, 0.13)
		B["speck_b"] = Color(0.50, 0.55, 0.75, 0.35)
		B["flower_a"] = Color(0.45, 0.70, 1.0)
	elif season_id == "nebel":
		B["light"] = Color(0.40, 0.43, 0.48)
		B["dark"] = Color(0.30, 0.32, 0.36)
		B["speck_b"] = Color(0.90, 0.92, 0.95, 0.40)
		B["flower_a"] = Color(0.85, 0.90, 0.95)
	elif season_id == "autumn":
		B["speck_b"] = Color(0.95, 0.60, 0.25, 0.55)
		B["flower_a"] = Color(0.90, 0.55, 0.20)

	# 1) Basiskaro (Runde 16): Muster in 1 px/Tile berechnen, dann KUBISCH weich
	# hochskalieren -> keine harten Pixelkanten mehr (Nutzerwahl D1: weicher Boden)
	# Runde 35b: Boden-Bild cachen - die Map-Erzeugung kostete sonst ~1,9 s
	var _pp0: int = [3, 6, 9][clampi(detail_level, 0, 2)]
	var _ckey: String = "%s|%s|%d" % [biome_id, season_id, detail_level]
	var _ctex: ImageTexture = _ground_cache.get(_ckey, null) as ImageTexture
	if _ctex != null:
		if base_sprite == null:
			base_sprite = Sprite2D.new()
			base_sprite.name = "BaseTiles"
			base_sprite.centered = false
			add_child(base_sprite)
		base_sprite.texture = _ctex
		# Runde 58: Beim Cache-Treffer fehlten scale + Filter. Dadurch wurde
		# die Textur 1:1 (9x zu gross, NEAREST) gezeichnet und erzeugte ein
		# sichtbares Kachelraster.
		base_sprite.scale = Vector2(float(tile_size) / float(_pp0), float(tile_size) / float(_pp0))
		base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		return
	var img := Image.create(cols, rows, false, Image.FORMAT_RGBA8)
	var pattern := str(_terrain().get("ground", "checker"))
	for x in range(cols):
		for y in range(rows):
			var h := _tile_hash(x, y)
			var v := float(h % 3 - 1) / 350.0
			var base: Color
			var shade := 1.0
			var vign := 1.0
			match pattern:
				"dunes", "regolith":
					# Mars: feiner Regolith-Staub, nur dezente Flecken (keine Wolkenbaender)
					var n := float(_tile_hash(x >> 4, y >> 4) % 100) / 100.0
					var n2 := float(_tile_hash(x, y) % 100) / 100.0
					base = (B["light"] as Color).lerp(B["dark"], clampf(0.34 + n * 0.30 + (n2 - 0.5) * 0.20, 0.0, 1.0))
				"voltgrid":
					# Runde 35: Elektro-Welt - Stahlplatten mit gelben Energieleitungen
					var n3 := float(_tile_hash(x >> 3, y >> 3) % 100) / 100.0
					base = Color(0.17, 0.19, 0.30).lerp(Color(0.27, 0.30, 0.45), n3)
					if x % 11 == 0 or y % 11 == 0:
						base = Color(0.40, 0.44, 0.64)      # Plattenfuge (dezent)
					elif (x + y) % 67 == 0:
						base = Color(0.94, 0.82, 0.22)      # einzelne Energieleitung (sparsam)
				"canopy", "junglefloor":
					# Dschungelboden nach Referenzbild: Gras in drei Toenen,
					# dazwischen Erd-Flecken (Wege) und dunkleres Moos
					# Runde 57: coarse und mid waren DERSELBE Hash (x>>2) - dadurch
					# gab es nur eine Rauschskala und der Boden wirkte gekachelt.
					var coarse := float(_tile_hash(x >> 4, y >> 4) % 100) / 100.0
					var mid := float(_tile_hash(x >> 2, y >> 2) % 100) / 100.0
					var fine := float(_tile_hash(x, y) % 100) / 100.0
					if mid > 0.74:
						base = (B["light"] as Color).lerp(Color(0.36, 0.64, 0.31), 0.08 + fine * 0.16)   # helles Gras
					elif mid < 0.26:
						base = (B["dark"] as Color).lerp(Color(0.21, 0.44, 0.24), 0.20 + fine * 0.16)   # Moos (mild)
					else:
						base = (B["light"] as Color).lerp(B["dark"], 0.42 + fine * 0.20)
					# grosse, weiche Moosflaechen ueber mehrere Tiles
					if coarse > 0.82:
						base = base.lerp(Color(0.27, 0.48, 0.25), 0.22 + fine * 0.10)
					# Runde 58: Tiefe - grossflaechige Helligkeit + Randabdunklung,
					# damit der Boden nicht wie eine flache Farbflaeche wirkt.
					shade = 0.90 + 0.16 * coarse
					# nur eine leichte warme Trockenflaeche, keine grossen Flecken
					if coarse > 0.93:
						base = base.lerp(Color(0.50, 0.58, 0.26), 0.16)
					var nx2: float = absf(float(x) / float(cols) - 0.5) * 2.0
					var ny2: float = absf(float(y) / float(rows) - 0.5) * 2.0
					vign = 1.0 - 0.13 * clampf(nx2 * nx2 * 0.5 + ny2 * ny2 * 0.5, 0.0, 1.0)
				_:
					base = B["light"] if (x + y) % 2 == 0 else B["dark"]
			img.set_pixel(x, y, Color((base.r + v) * shade * vign, (base.g + v) * shade * vign, (base.b + v * 0.5) * shade * vign))
	# Runde 20: Wasser liegt als eigene animierte Ebene ueber dem Boden (s. _build_water_layer)
	# Runde 57: 3x3-Weichzeichner auf der 1-px-Ebene. Die Rauschbloecke
	# (x>>2 / x>>4) waren flaechig konstant und blieben als Kachelraster
	# sichtbar, obwohl die Textur kubisch skaliert wird.
	var soft: Image = img.duplicate()
	for yy in range(rows):
		for xx in range(cols):
			var ar := 0.0
			var ag := 0.0
			var ab := 0.0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx: int = clampi(xx + dx, 0, cols - 1)
					var ny: int = clampi(yy + dy, 0, rows - 1)
					var cc: Color = img.get_pixel(nx, ny)
					ar += cc.r
					ag += cc.g
					ab += cc.b
			soft.set_pixel(xx, yy, Color(ar / 9.0, ag / 9.0, ab / 9.0, 1.0))
	img = soft

	if base_sprite == null:
		base_sprite = Sprite2D.new()
		base_sprite.name = "BaseTiles"
		base_sprite.centered = false
		add_child(base_sprite)
	# Runde 16 (D1): Muster in 1 px/Tile berechnen und dann WEICH hochskalieren.
	# Vorher: 1 px/Tile mit NEAREST = hartes Pixelraster.
	var _pp: int = [3, 6, 9][clampi(detail_level, 0, 2)]      # Pixel pro Tile je Grafikstufe
	img.resize(cols * _pp, rows * _pp, Image.INTERPOLATE_CUBIC)
	_ground_cache[_ckey] = ImageTexture.create_from_image(img)
	base_sprite.texture = _ground_cache[_ckey]
	base_sprite.scale = Vector2(float(tile_size) / float(_pp), float(tile_size) / float(_pp))
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	base_sprite.position = Vector2.ZERO
	base_sprite.z_index = -10

	# 2) Karo-Raster: eine Kachel-Textur, per region_rect ueber die Karte wiederholt
	if grid_sprite == null:
		grid_sprite = Sprite2D.new()
		grid_sprite.name = "GridLines"
		grid_sprite.centered = false
		grid_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		add_child(grid_sprite)
	grid_sprite.texture = _make_grid_texture(B["grid"])
	grid_sprite.region_enabled = true
	grid_sprite.region_rect = Rect2(0, 0, cols * tile_size, rows * tile_size)
	grid_sprite.position = Vector2.ZERO
	# Runde 62: Karo-Raster wieder auf allen Karten und Detailstufen einblenden.
	# Ohne das Gitter wirkten vor allem Wiese/Wueste als leere Farbflaeche.
	grid_sprite.visible = detail_level >= 1

	# 3) Details als MultiMesh (je 1 Draw-Call)
	if specks_mm and is_instance_valid(specks_mm):
		specks_mm.queue_free()
	if plants_mm and is_instance_valid(plants_mm):
		plants_mm.queue_free()
	if flowers_mm and is_instance_valid(flowers_mm):
		flowers_mm.queue_free()
	specks_mm = null
	plants_mm = null
	flowers_mm = null
	if detail_level <= 0:
		return
	var _T: Dictionary = _terrain()
	var _do_plants: bool = bool(_T.get("plants", true))
	var _do_flowers: bool = bool(_T.get("flowers", true))
	var _fern_clusters: int = int(_T.get("fern_clusters", 0))
	var _flower_key := str(_T.get("flower_tex", ""))
	if _flower_key != "":
		var ft = TextureManager.get_texture(_flower_key)
		if ft != null:
			flower_tex = ft
	if flower_tex == null:
		flower_tex = _make_flower_texture()
	var specks: Array = []
	var blades: Array = []
	var flowers: Array = []
	var speck_count := 2 if detail_level >= 2 else 1
	for x in range(cols):
		for y in range(rows):
			var h2 := _tile_hash(x, y)
			var ox := float(x * tile_size)
			var oy := float(y * tile_size)
			var sx1 := ox + float(h2 % 24) + 2.0
			var sy1 := oy + float((h2 >> 5) % 24) + 2.0
			specks.append([Transform2D(0.0, Vector2(3.0, 4.0), 0.0, Vector2(sx1 + 1.5, sy1 + 2.5)), (B["speck_a"] as Color).lerp(Color(1, 1, 1), 0.30)])
			if speck_count >= 2:
				var sx2 := ox + float((h2 >> 9) % 24) + 2.0
				var sy2 := oy + float((h2 >> 13) % 24) + 2.0
				specks.append([Transform2D(0.0, Vector2(2.0, 4.0), 0.0, Vector2(sx2 + 1.0, sy2 + 2.0)), B["speck_b"]])
			if detail_level < 2:
				continue
			if _fern_clusters > 0 and h2 % 7 == 0:
				# Runde 56: Groesse und Neigung variieren - vorher standen die
				# Bueschel in einem festen Raster (jedes 5. Tile, gleiche Groesse)
				# und wirkten wie Kachel-Artefakte.
				var fx0 := ox + float((h2 >> 4) % 26) + 2.0
				var fy0 := oy + float((h2 >> 7) % 26) + 2.0
				var bsc: float = 0.75 + 0.55 * float((h2 >> 3) % 100) / 100.0
				var brot: float = float((h2 >> 11) % 70 - 35) * 0.01745
				blades.append([Transform2D(brot, Vector2(11.0, 13.0) * bsc, 0.0, Vector2(fx0, fy0)), Color(0.85, 1.0, 0.9, 0.95)])
			if not _do_plants:
				continue
			if h2 % 7 == 0:
				var bx := ox + float(8 + (h2 % 12))
				var by := oy + 26.0
				blades.append([Transform2D(0.0, Vector2(22.0, 20.0), 0.0, Vector2(bx - 6.0, by - 10.0)), B["plant"].lerp(Color(1, 1, 1), 0.25)])
			elif _do_flowers and h2 % int(_T.get("flower_dens", 23)) == 0:
				var fx := ox + float(6 + (h2 % 20))
				var fy := oy + float(8 + ((h2 >> 3) % 16))
				var fc: Color = B["flower_a"] if h2 % 3 == 0 else (B["flower_b"] if h2 % 3 == 1 else Color(0.94, 0.42, 0.62))
				flowers.append([Transform2D(0.0, Vector2(9.0, 9.0), 0.0, Vector2(fx, fy)), fc])
				if h2 % 2 == 0:
					flowers.append([Transform2D(0.0, Vector2(7.0, 7.0), 0.0, Vector2(fx + 7.0, fy + 5.0)),
						B["flower_b"] if h2 % 4 == 0 else Color(0.96, 0.88, 0.34)])
	specks_mm = _build_multimesh("Specks", specks, null)
	plants_mm = _build_multimesh("Blades", blades, TextureManager.get_texture("grass_tuft"))
	flowers_mm = _build_multimesh("Flowers", flowers, flower_tex)

func _build_multimesh(nm: String, arr: Array, tex: Texture2D) -> MultiMeshInstance2D:
	var mmi := MultiMeshInstance2D.new()
	mmi.z_index = -9      # Bugfix Runde 19/20: Deko unter Objekten, ueber dem Boden
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	mm.mesh = quad
	mm.instance_count = maxi(0, arr.size())
	for i in range(arr.size()):
		mm.set_instance_transform_2d(i, arr[i][0])
		mm.set_instance_color(i, arr[i][1])
	mmi.multimesh = mm
	if tex != null:
		mmi.texture = tex
		mmi.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # Runde 21: scharfer Pixel-Look
	add_child(mmi)
	return mmi

func _make_grid_texture(grid_col: Color) -> ImageTexture:
	var img := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	for x in range(tile_size):
		img.set_pixel(x, 0, grid_col)
	for y in range(tile_size):
		img.set_pixel(0, y, grid_col)
	return ImageTexture.create_from_image(img)

func _make_flower_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in range(16):
		for y in range(16):
			var d := Vector2(float(x) - 7.5, float(y) - 7.5).length()
			if d <= 5.0:
				img.set_pixel(x, y, Color(1, 1, 1))
			elif d <= 7.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0.55))
	return ImageTexture.create_from_image(img)

func _tile_hash(x: int, y: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663)
	return abs(h)

const PLANET_TERRAIN := {
	"earth": {
		"ground": "checker",
		"river": true,
		# Runde 26: keine dunklen Grasbueschel mehr (wirkten dreckig) - dafuer Blumen
		"plants": false, "flowers": true, "flower_tex": "", "flower_dens": 9, "fern_clusters": 0,
		"obstacles": [
			# Runde 63: Wiese war zu leer (76 Baeume auf der ganzen Karte).
			# Mehr Baeume, mehr Steine, mehr Blueten als Farbtupfer.
			{ "kind": "tree", "tex": "tree", "clusters": 96, "smin": 0.9, "smax": 1.25,
			  "radius": 12.0, "rbase": 11.0, "yoff": 12.0, "foot": true, "footat": 0.9, "cmin": 1, "cmax": 2 },
			{ "kind": "tree", "tex": "pbush_a", "texs": ["pbush_a", "pbush_b", "pbush_c", "pbush_d"],
			  "clusters": 34, "smin": 0.65, "smax": 0.95,
			  "radius": 8.0, "rbase": 0.0, "yoff": 4.0, "cmin": 1, "cmax": 2 },
			{ "kind": "rock", "tex": "rock", "clusters": 56, "smin": 0.8, "smax": 1.3,
			  "radius": 10.0, "rbase": 9.0, "yoff": 6.0, "cmin": 1, "cmax": 2 },
			# Runde 26: Blueten als Farbtupfer
			{ "kind": "rock", "tex": "jflower", "clusters": 18, "smin": 0.8, "smax": 1.2,
			  "radius": 4.0, "rbase": 4.0, "yoff": 4.0, "cmin": 2, "cmax": 4 },
			{ "kind": "rock", "tex": "jflower", "texs": ["jflower", "jflower_pink", "jflower_yellow", "jflower_blue"],
			  "clusters": 12, "smin": 0.9, "smax": 1.3,
			  "radius": 3.0, "rbase": 0.0, "yoff": 3.0, "cmin": 2, "cmax": 5 },
			# v1.42 (P7.5): Steinfelder - Gruppen aus 2-5 Steinen verschiedener
			# Groesse und Form (5 Varianten), damit ein "Feld" erkennbar ist.
			{ "kind": "rock", "tex": "stone_v0",
			  "texs": ["stone_v0", "stone_v1", "stone_v2", "stone_v3", "stone_v4"],
			  "clusters": 22, "smin": 0.30, "smax": 0.75,
			  "radius": 9.0, "rbase": 8.0, "yoff": 6.0, "cmin": 2, "cmax": 5, "feld": true }
		]
	},
	"volt": {
		"ground": "voltgrid",
		"river": false,
		"plants": false, "flowers": false, "flower_tex": "", "flower_dens": 30, "fern_clusters": 0,
		"obstacles": [
			{ "kind": "tree", "tex": "volt_pylon", "clusters": 17, "smin": 0.50, "smax": 0.85,
			  "radius": 22.0, "rbase": 20.0, "yoff": 34.0, "foot": true, "footat": 0.90, "cmin": 1, "cmax": 1 },
			{ "kind": "tree", "tex": "volt_antenna", "clusters": 13, "smin": 0.50, "smax": 0.80,
			  "radius": 18.0, "rbase": 16.0, "yoff": 30.0, "foot": true, "footat": 0.90, "cmin": 1, "cmax": 1 },
			{ "kind": "rock", "tex": "volt_capacitor", "clusters": 28, "smin": 0.50, "smax": 0.95,
			  "radius": 17.0, "rbase": 16.0, "yoff": 14.0, "cmin": 1, "cmax": 3 },
			{ "kind": "rock", "tex": "volt_spool", "clusters": 22, "smin": 0.40, "smax": 0.75,
			  "radius": 15.0, "rbase": 14.0, "yoff": 12.0, "cmin": 1, "cmax": 2 },
			{ "kind": "rock", "tex": "volt_wreck", "clusters": 20, "smin": 0.45, "smax": 0.85,
			  "radius": 17.0, "rbase": 16.0, "yoff": 14.0, "cmin": 1, "cmax": 2 }
		]
	},
	"mars": {
		"ground": "regolith",
		"plants": false, "flowers": false, "flower_tex": "", "fern_clusters": 0,
		"obstacles": [
			# RIESIGE Felsen aus echten Bilddateien (res://assets/rocks/, CC0 Kenney-Meteoriten
			# auf Mars-Rostorange umgefaerbt). Keine gezeichneten Krater/Wolken mehr.
			{ "kind": "tree", "tex": "mars_big_1", "texs": ["mars_big_1", "mars_big_2", "mars_big_3", "mars_big_4"],
			  "clusters": 13, "smin": 0.34, "smax": 0.62, "radius": 74.0, "rbase": 70.0, "yoff": 44.0, "cmin": 1, "cmax": 2 },
			{ "kind": "tree", "tex": "mars_big_3", "texs": ["mars_big_1", "mars_big_2", "mars_big_3", "mars_big_4"],
			  "clusters": 9, "smin": 0.30, "smax": 0.52, "radius": 66.0, "rbase": 62.0, "yoff": 40.0, "cmin": 1, "cmax": 2 },
			{ "kind": "rock", "tex": "mars_mid_1", "texs": ["mars_mid_1", "mars_mid_2", "mars_mid_3", "mars_mid_4"],
			  "clusters": 30, "smin": 0.34, "smax": 0.64, "radius": 46.0, "rbase": 44.0, "yoff": 24.0, "cmin": 1, "cmax": 3 },
			{ "kind": "rock", "tex": "mars_small_1", "texs": ["mars_small_1", "mars_small_2", "mars_small_3", "mars_small_4"],
			  "clusters": 34, "smin": 0.30, "smax": 0.55, "radius": 26.0, "rbase": 30.0, "yoff": 14.0, "cmin": 1, "cmax": 4 }
		]
	},
	"jungle": {
		"ground": "canopy",
		"river": true,
		# Runde 26: weichere Töne + keine dunklen Grasbueschel (Nutzerfeedback)
		"plants": false, "flowers": true, "flower_tex": "mushroom", "flower_dens": 26, "fern_clusters": 0,
		"obstacles": [
			# Runde 18: Dschungel nach den Referenzbildern des Nutzers
			# (runde Wolkenkronen, Palmen, Trauerweide, seltener Urbaum) - bewusst
			# NICHT so dicht wie in der Vorlage, damit man noch kaempfen kann
			{ "kind": "tree", "tex": "jtree_round", "clusters": 18, "smin": 0.42, "smax": 0.70,
			  "radius": 26.0, "rbase": 26.0, "yoff": 46.0, "foot": true, "footat": 0.90, "cmin": 1, "cmax": 2 },
			{ "kind": "tree", "tex": "jtree_tall", "clusters": 12, "smin": 0.44, "smax": 0.72,
			  "radius": 22.0, "rbase": 22.0, "yoff": 52.0, "foot": true, "footat": 0.92, "cmin": 1, "cmax": 2 },
			# Runde 57: Palme als echte Bilddatei (CC0 Kenney, gruen abgestimmt
			# + schwarze Kontur). hmin/hmax = gewuenschte Hoehe auf dem Schirm.
			{ "kind": "tree", "tex": "jpalm_png", "clusters": 10, "smin": 0.48, "smax": 0.78,
			  "hmin": 104.0, "hmax": 152.0,
			  "radius": 20.0, "rbase": 20.0, "yoff": 56.0, "foot": true, "footat": 0.90, "cmin": 1, "cmax": 2 },
			{ "kind": "tree", "tex": "jtree_willow", "clusters": 7, "smin": 0.42, "smax": 0.66,
			  "radius": 24.0, "rbase": 24.0, "yoff": 44.0, "foot": true, "footat": 0.90, "cmin": 1, "cmax": 1 },
			{ "kind": "tree", "tex": "jtree_ancient", "clusters": 3, "smin": 0.55, "smax": 0.85,
			  "radius": 34.0, "rbase": 34.0, "yoff": 52.0, "foot": true, "footat": 0.90, "cmin": 1, "cmax": 1 },
			{ "kind": "tree", "tex": "bamboo", "clusters": 10, "smin": 1.0, "smax": 1.55,
			  "radius": 12.0, "rbase": 9.0, "yoff": 42.0, "cmin": 3, "cmax": 5 },
			# Runde 57: Buesche als echte Bilddateien (zwei Varianten, per texs gemischt)
			{ "kind": "rock", "tex": "jbush_big_png", "texs": ["jbush_big_png", "jbush_small_png"],
			  "clusters": 14, "smin": 0.55, "smax": 0.95, "hmin": 38.0, "hmax": 66.0,
			  "radius": 12.0, "rbase": 12.0, "yoff": 10.0, "cmin": 2, "cmax": 3 },
			# Runde 57: Blaetterhaufen auf dem Boden (nur Deko, keine Kollision)
			{ "kind": "rock", "tex": "jleafpile", "clusters": 9, "smin": 0.48, "smax": 0.78,
			  "radius": 10.0, "rbase": 0.0, "yoff": 0.0, "cmin": 2, "cmax": 4 },
			{ "kind": "rock", "tex": "fern", "clusters": 12, "smin": 0.8, "smax": 1.3,
			  "radius": 8.0, "rbase": 8.0, "yoff": 14.0, "cmin": 2, "cmax": 3 },
			{ "kind": "rock", "tex": "jvine", "clusters": 8, "smin": 0.7, "smax": 1.1,
			  "radius": 6.0, "rbase": 0.0, "yoff": -40.0, "cmin": 1, "cmax": 2 },
			{ "kind": "rock", "tex": "jmushroom_brown", "texs": ["jmushroom_brown", "jmushroom_brown", "jmushroom_red"],
			  "clusters": 7, "smin": 0.7, "smax": 1.2,
			  "radius": 5.0, "rbase": 5.0, "yoff": 6.0, "cmin": 2, "cmax": 5 },
			{ "kind": "rock", "tex": "jreed", "clusters": 7, "smin": 0.7, "smax": 1.1,
			  "radius": 5.0, "rbase": 5.0, "yoff": 6.0, "cmin": 2, "cmax": 4 },
			{ "kind": "rock", "tex": "jrock", "clusters": 10, "smin": 0.6, "smax": 1.0,
			  "radius": 12.0, "rbase": 12.0, "yoff": 6.0, "cmin": 1, "cmax": 3 },
			{ "kind": "rock", "tex": "jflower", "texs": ["jflower", "jflower_pink", "jflower_yellow", "jflower_blue"],
			  "clusters": 15, "smin": 0.7, "smax": 1.1,
			  "radius": 4.0, "rbase": 4.0, "yoff": 4.0, "cmin": 2, "cmax": 4 }
		
		]
	}
}
var ferns_mm: MultiMeshInstance2D = null
# Runde 19: Fluss mit Bruecken (Nutzerwunsch) - Wasser blockiert, Bruecken queren
var river_axis: int = 0
var river_tiles: Array = []
var bridges: Array = []
var river_nodes: Array = []       # Wasser-Ebene, Bruecken, Waende -> werden beim Neuaufbau geraeumt

func _terrain() -> Dictionary:
	return PLANET_TERRAIN.get(biome_id, PLANET_TERRAIN["earth"])

func place_planet_obstacles(density: float = 1.0) -> void:
	# Ersetzt place_obstacles(): je Planet eigene Objekte, in CLUSTERN platziert
	# Bugfix Runde 14: vorher wurden alte Hindernisse NICHT geraeumt -> jeder Run
	# stapelte Objekte des vorherigen Planeten (Krater im Dschungel usw.)
	for o in obstacles:
		if is_instance_valid(o):
			o.queue_free()
	obstacles.clear()
	obstacle_kinds.clear()
	var T: Dictionary = _terrain()
	var specs: Array = T["obstacles"]
	var total := 0
	for sp in specs:
		total += int(round(float(sp["clusters"]) * density))
	var positions = get_random_walkable_positions(maxi(40, total * 3 + 12), 6)
	var pi := 0
	var world_w: float = map_size.x * tile_size
	var world_h: float = map_size.y * tile_size
	var placed: Array = []          # [Vector2, radius] -> verhindert Kronen-Ueberlappung
	# Runde 34: Raster-Index statt O(n^2)-Durchlauf (350 Objekte -> ~60k Vergleiche)
	var placed_grid: Dictionary = {}
	const GRID_CELL := 220.0
	var water_set: Dictionary = {}
	var water_block: Dictionary = {}
	var missing_keys: Dictionary = {}
	var prop_counts: Dictionary = {}
	# v1.42 (P7.5): Steinfelder zaehlen (Gruppen aus 2-5 Steinen)
	var steinfelder: int = 0
	var bank_steine: int = 0
	for rt in river_tiles:
		water_set[rt] = true
	# 3x3-Umgebung des Wassers sperren -> kein Objekt ragt in den Fluss
	for rt in river_tiles:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				water_block[Vector2i(rt) + Vector2i(dx, dy)] = true
	for sp in specs:
		var spec_tex := str(sp["tex"])
		var n := int(round(float(sp["clusters"]) * density))
		for i in range(n):
			if pi >= positions.size():
				break
			var center: Vector2 = positions[pi]
			pi += 1
			var cnt := rng.randi_range(int(sp["cmin"]), int(sp["cmax"]))
			var _feld_ist: bool = bool(sp.get("feld", false))
			if _feld_ist:
				steinfelder += 1
			for k in range(cnt):
				var spread := 34.0 + 26.0 * float(sp["smax"])
				var placed_ok := false
				var spr: Sprite2D = null
				for _try in range(14):
					var pos2: Vector2 = center + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
					if pos2.x < 150.0 or pos2.y < 150.0 or pos2.x > world_w - 150.0 or pos2.y > world_h - 150.0:
						continue
					if water_block.size() > 0 and water_block.has(Vector2i(int(pos2.x / tile_size), int(pos2.y / tile_size))):
						continue
					var tex_key0 := str(sp["tex"])
					if sp.has("texs"):
						var _vs0: Array = sp["texs"]
						tex_key0 = str(_vs0[rng.randi() % _vs0.size()])
					var _tex := TextureManager.get_texture(tex_key0)
					if _tex == null:
						if not missing_keys.has(tex_key0):
							missing_keys[tex_key0] = true
							print("[MAP][FEHLER] Textur fehlt: '%s' (Biom %s) - Prop wird uebersprungen" % [tex_key0, biome_id])
						continue
					var sc0 := rng.randf_range(float(sp["smin"]), float(sp["smax"]))
					if sp.has("hmin"):      # Hoehe in px vorgeben (echte Props sind unterschiedlich gross)
						var ts: Vector2 = _tex.get_image().get_size()
						var want := rng.randf_range(float(sp["hmin"]), float(sp["hmax"]))
						sc0 = want / maxf(1.0, ts.y)
					var _tsz: Vector2 = _tex.get_image().get_size()
					# Runde 29: exaktes SICHTBARES Rechteck statt Kreis um den Stamm.
					# Vorher (R16) wurde nur ein Kreis um den Fusspunkt geprueft - Bambus
					# (zentriert, 140 px hoch) und Baumkronen (~96 px ueber dem Stamm)
					# sind darin durchgerutscht und haben sich sichtbar ueberlagert.
					var off_y: float = 0.0
					if bool(sp.get("foot", false)):
						off_y = -_tsz.y * (0.5 - float(sp.get("footat", 0.88)))
					var cand := Rect2(pos2 + Vector2(-_tsz.x * 0.5 * sc0, (-_tsz.y * 0.5 + off_y) * sc0),
						Vector2(_tsz.x * sc0, _tsz.y * sc0))
					var vis_r: float = 0.42 * maxf(_tsz.x, _tsz.y) * sc0
					# Runde 34: nur die Rasterzellen im Umfeld pruefen
					var c0 := Vector2i(int(floor(cand.position.x / GRID_CELL)), int(floor(cand.position.y / GRID_CELL)))
					var c1 := Vector2i(int(floor(cand.end.x / GRID_CELL)), int(floor(cand.end.y / GRID_CELL)))
					var blocked := false
					for gx in range(c0.x, c1.x + 1):
						for gy in range(c0.y, c1.y + 1):
							for pl in placed_grid.get(Vector2i(gx, gy), []):
								if cand.grow(5.0).intersects(pl):
									blocked = true
									break
							if blocked:
								break
						if blocked:
							break
					if blocked:
						continue
					spr = Sprite2D.new()
					spr.texture = _tex
					spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if (tex_key0 == "bamboo" or tex_key0 == "jungle_tree") else CanvasItem.TEXTURE_FILTER_LINEAR
					spr.scale = Vector2(sc0, sc0)
					spr.position = pos2
					spr.z_index = -5 if str(sp["kind"]) == "crater" else 0
					if bool(sp.get("foot", false)):
						# Fuss-Punkt: Zeichen-/Sortierbasis an der Objektbasis (Kronen-Ebene).
						# Bugfix Runde 24: Offset.y = -H * (0.5 - Fussanteil) (vorher falsches
						# Vorzeichen -> Baeume wurden 0.8*H zu tief gezeichnet)
						spr.offset = Vector2(0.0, -_tsz.y * (0.5 - float(sp.get("footat", 0.88))))
					placed.append(cand)
					for gx2 in range(c0.x, c1.x + 1):
						for gy2 in range(c0.y, c1.y + 1):
							var gk := Vector2i(gx2, gy2)
							placed_grid[gk] = placed_grid.get(gk, []) + [cand]
					placed_ok = true
					break
				if not placed_ok or spr == null:
					continue
				var rbase := float(sp.get("rbase", sp["radius"]))
				# Runde 58: Schlagschatten unter dem Prop (ausser Kruemel/Krater)
				if str(sp["kind"]) != "crater" and bool(sp.get("shadow", true)):
					var fat := float(sp.get("footat", 0.5))
					var tsz: Vector2 = spr.texture.get_size()
					var hh: float = tsz.y * spr.scale.y
					var sh := Sprite2D.new()
					sh.texture = _get_shadow_tex()
					sh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
					# Runde 63: deutlich kleiner und heller - vorher wirkten die
					# Schatten wie breite dunkle Pfuetzen unter den Baeumen.
					var sw: float = tsz.x * spr.scale.x * 0.34
					sh.scale = Vector2(sw / 32.0, sw * 0.46 / 32.0)
					sh.position = Vector2(spr.position.x, spr.position.y + hh * fat - 2.0)
					sh.z_index = -1
					add_child(sh)
				if rbase > 0.0:
					_add_collision_body(spr, rbase, float(sp.get("yoff", 0.0)))
				add_child(spr)
				obstacles.append(spr)
				obstacle_kinds.append(str(sp["kind"]))
				prop_counts[spec_tex] = int(prop_counts.get(spec_tex, 0)) + 1
	print("[MAP][%s] %d Hindernisse platziert: %s%s" % [
		biome_id, obstacles.size(), str(prop_counts),
		("  FEHLENDE TEXTUREN: " + str(missing_keys.keys())) if missing_keys.size() > 0 else ""])
	# Runde 22: Ufersteine - bewusst 2 Tiles vom Wasser weg und kleiner, damit sie
	# NICHT ins Wasser ragen (sahen wie Unterbrechungen im Fluss aus)
	if river_tiles.size() > 0:
		var wset1: Dictionary = {}
		var wset2: Dictionary = {}
		for rt2 in river_tiles:
			wset1[rt2] = true
		var dirs: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for rt2 in river_tiles:
			for d in dirs:
				var nb1: Vector2i = Vector2i(rt2) + d
				if wset1.has(nb1):
					continue
				for d2 in dirs:
					var nb2: Vector2i = nb1 + d2
					if wset1.has(nb2):
						continue
					wset2[nb2] = true
		var bank_texs: Array = ["stone_v0", "stone_v1", "stone_v2", "stone_v3", "stone_v4"]
		for nb3 in wset2.keys():
			if rng.randf() > 0.16:
				continue
			var wx: float = float(nb3.x) * tile_size + tile_size * 0.5
			var wy: float = float(nb3.y) * tile_size + tile_size * 0.5
			if wx < 150.0 or wy < 150.0 or wx > world_w - 150.0 or wy > world_h - 150.0:
				continue
			var near_bridge := false
			for b in bridges:
				if int(b["axis"]) == 1 and absi(nb3.y - int(b["at"])) <= 3:
					near_bridge = true
				if int(b["axis"]) == 2 and absi(nb3.x - int(b["at"])) <= 3:
					near_bridge = true
			if near_bridge:
				continue
			var st := Sprite2D.new()
			st.texture = TextureManager.get_texture(str(bank_texs[rng.randi() % bank_texs.size()]))
			var sc := rng.randf_range(0.32, 0.52)
			st.scale = Vector2(sc, sc)
			st.position = Vector2(wx, wy)
			st.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_add_collision_body(st, 16.0, 4.0)
			add_child(st)
			obstacles.append(st)
			obstacle_kinds.append("rock")
			bank_steine += 1
	# v1.42 (P7.5): Beleg fuer Steinfelder + Ufer-Regel (P7.6)
	if steinfelder > 0:
		print("[MAP][STEINFELD] felder=%d steine_pro_feld=2-5 varianten=5" % [steinfelder])
	print("[MAP][UFER] eingriff=false bruecken_frei=true wasserkacheln=%d banksteine=%d" % [
		river_tiles.size(), bank_steine])
	# Jahreszeit-Modulate anwenden
	if season_id != "":
		var mcol: Color = SEASON_OBST.get(season_id, Color(1, 1, 1))
		for o in obstacles:
			if is_instance_valid(o) and o is Sprite2D:
				o.modulate = mcol
	_add_border_walls()

func place_obstacles(num_trees: int, num_rocks: int) -> void:
	var B: Dictionary = BIOMES.get(biome_id, BIOMES["meadow"])
	var positions = get_random_walkable_positions(num_trees + num_rocks, 5)
	for i in range(min(num_trees, positions.size())):
		var tree = Sprite2D.new()
		tree.texture = TextureManager.get_texture(str(B["tree"]))
		tree.position = positions[i]
		_add_collision_body(tree, 12.0)
		add_child(tree)
		obstacles.append(tree)
		obstacle_kinds.append("tree")
	for i in range(min(num_rocks, positions.size() - num_trees)):
		var rock = Sprite2D.new()
		rock.texture = TextureManager.get_texture(str(B["rock"]))
		rock.position = positions[num_trees + i]
		_add_collision_body(rock, 10.0)
		add_child(rock)
		obstacles.append(rock)
		obstacle_kinds.append("rock")
	_add_border_walls()

func _add_collision_body(sprite: Sprite2D, radius: float, yoff: float = 0.0) -> void:
	# StaticBody2D als Kind des Sprites -> blockiert Spieler & Monster (Layer 16)
	# WICHTIG (Runde 15): radius/yoff werden in TEXTUR-Pixeln uebergeben. Das Sprite
	# ist bereits skaliert, also NICHT nochmal mit sc multiplizieren (das ergab sc^2
	# und damit fast keine Kollision). yoff setzt die Kollision an die Objekt-BASIS
	# (Stammfuss/Boden) statt in die Sprite-Mitte.
	var body = StaticBody2D.new()
	body.collision_layer = 16
	body.collision_mask = 0
	body.position = Vector2(0.0, yoff)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = maxf(2.0, radius)
	col.shape = shape
	body.add_child(col)
	sprite.add_child(body)

func _add_border_walls() -> void:
	# Unsichtbare Wände an allen 4 Kartenrändern
	var w = map_size.x * tile_size
	var h = map_size.y * tile_size
	var t = 32.0
	var defs = [
		[Vector2(w / 2.0, -t / 2.0), Vector2(w + t * 2.0, t)],
		[Vector2(w / 2.0, h + t / 2.0), Vector2(w + t * 2.0, t)],
		[Vector2(-t / 2.0, h / 2.0), Vector2(t, h + t * 2.0)],
		[Vector2(w + t / 2.0, h / 2.0), Vector2(t, h + t * 2.0)]
	]
	for d in defs:
		var body = StaticBody2D.new()
		body.collision_layer = 16
		body.collision_mask = 0
		body.position = d[0]
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = d[1]
		col.shape = shape
		body.add_child(col)
		add_child(body)
		obstacles.append(body)
		obstacle_kinds.append("wall")

func get_center() -> Vector2:
	return Vector2(map_size.x * tile_size / 2, map_size.y * tile_size / 2)

func get_bounds() -> Rect2:
	return Rect2(0, 0, map_size.x * tile_size, map_size.y * tile_size)

func get_random_walkable_positions(count: int, margin: int = 3) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var available = walkable_positions.duplicate(true)
	# Runde 65: shuffle() nutzt den GLOBALEN Zufall - damit haing die Karte
	# wieder vom Zustand des Prozesses ab. Fisher-Yates mit unserem rng.
	for i in range(available.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = available[i]
		available[i] = available[j]
		available[j] = tmp
	var center = get_center()
	for pos in available:
		if positions.size() >= count:
			break
		if margin > 0 and pos.distance_to(center) < margin * tile_size:
			continue
		positions.append(pos)
	return positions

func clear_map() -> void:
	walkable_positions.clear()
	for n in river_nodes:
		if is_instance_valid(n):
			n.queue_free()
	river_nodes.clear()
	river_tiles.clear()
	bridges.clear()
	for obs in obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	obstacles.clear()
	queue_redraw()
