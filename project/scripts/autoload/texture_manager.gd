# TextureManager.gd - Autoload Singleton
# Generiert alle Comic-Style Texturen zur Laufzeit (keine externen Bilddateien nötig)
extends Node

var textures: Dictionary = {}

const OUTLINE := TexDraw.OUTLINE
const SHADOW := TexDraw.SHADOW

var _built: Dictionary = {}          # Gruppe -> true (Lazy-Erzeugung)

const GROUPS := ["boot", "run"]

# v1.43 (S6.2): Die Boot-Texturen werden nicht mehr in _ready am Stueck
# gezeichnet, sondern als Haeppchen-Liste vorbereitet. Der Boot-Loader ruft
# boot_next() einmal je Frame (bzw. solange das Budget reicht).
var boot_steps: Array = []
var boot_done: bool = false
var boot_last_step_ms: int = 0

func _ready():
	# Runde 137 (P2.3): Nur die Startmenge gehoert zum Boot.
	# Monster, Welt-Deko und Dschungel-Sets entstehen beim ersten Zugriff.
	boot_steps = GenRegistry.boot_steps(textures, self)
	print("[TEX][BOOT] bereit steps=%d (Haeppchen, Arbeitet der Boot-Loader ab)" % boot_steps.size())


# Ein Haeppchen zeichnen. Rueckgabe true = fertig.
func boot_next() -> bool:
	if boot_done:
		return true
	if boot_steps.is_empty():
		boot_done = true
		_built["boot"] = true
		print("[TEX][BOOT] fertig keys=%d" % textures.size())
		return true
	var s: Dictionary = boot_steps.pop_front()
	var t0: int = Time.get_ticks_msec()
	(s["fn"] as Callable).call()
	boot_last_step_ms = Time.get_ticks_msec() - t0
	print("[TEX][STEP] %s ms=%d keys=%d rest=%d" % [
		str(s["name"]), boot_last_step_ms, textures.size(), boot_steps.size()])
	return boot_steps.is_empty()


func boot_remaining() -> int:
	return boot_steps.size()


# Fallback: alles nachziehen (falls ein Aufrufer vor dem Boot fragt)
func boot_force() -> void:
	while not boot_next():
		pass


func _ensure_run() -> void:
	if _built.has("run"):
		return
	if OS.get_environment("COMIC_TEX_DEBUG") != "":
		print("[TEX][TRACE] run-Gruppe angefordert von:")
		print_stack()
	var t0: int = Time.get_ticks_msec()
	_gen_run()
	print("[TEX][LAZY] run-Gruppe gezeichnet: keys=%d ms=%d" % [textures.size(), Time.get_ticks_msec() - t0])

func get_texture(key: String) -> Texture2D:
	# v1.43 (S6.2): Vor dem Boot-Ende fehlende Keys synchron nachziehen.
	if not boot_done:
		boot_force()
	if not textures.has(key):
		# Fehlender Key: erst die zweite Gruppe nachziehen, dann erneut pruefen.
		_ensure_run()
	if not textures.has(key):
		if not _missing.has(key):
			_missing[key] = true
			print("[TEX][FEHLT] key=%s" % key)
		return null
	return textures.get(key)

var _missing: Dictionary = {}

func _gen_boot() -> void:
	if _built.has("boot"):
		return
	_built["boot"] = true
	GenRegistry.gen_boot(textures, self)

func _gen_run() -> void:
	if _built.has("run"):
		return
	_built["run"] = true
	GenRegistry.gen_run(textures, self)

# ---------- Basis-Primitives ----------

# Runde 59: Kantenglaettung fuer Charaktere. Die Figuren wurden mit harten
# Pixelkanten gezeichnet und sahen am Rand ausgefranst aus. Bei _aa = true
# rechnen die Primitive 4x4-Subpixel-Coverage und blenden den Rand weich ein.
var _aa: bool = false
const _AA_N: int = 4

# ---------- Spieler-Held ----------

# ============================================================
# Runde 38: NEUE CHARACTER-RIGS (Helden-Overlays)
# ============================================================

# Runde 130 (C3): Kopf-Anker je Skin. Der Hut wird als eigene Ebene gezeichnet
# und um (anchor - 21) verschoben aufgesetzt, statt auf feste y-Werte zu bauen.
const HEAD_ANCHOR := TexDraw.HEAD_ANCHOR
# v1.42 (P11): Handanker + Deko-Waffen-Maske je Skin
const HAND_ANCHOR := TexDraw.HAND_ANCHOR
const RIG_DECO_WEAPON := TexDraw.RIG_DECO_WEAPON

const COLOR_NAMES := TexDraw.COLOR_NAMES
# Runde 38: Character-Rigs (Helden-Overlays)
# Runde 40/42: RIGS = echte SKINS (kompletter Charakter-Look, farbbar)
const RIG_NAMES := TexDraw.RIG_NAMES
const HAT_NAMES := TexDraw.HAT_NAMES

const PLAYER_COLORS := TexDraw.PLAYER_COLORS

func get_hat_only_texture(idx: int) -> Texture2D:
	# Runde 96: Nur der Hut, ohne Figur - fuer die Gewinner-Kachel.
	# Wird einmal gezeichnet und dann aus dem Cache geliefert.
	var key := "hat_only_%d" % idx
	if textures.has(key):
		return textures[key]
	textures[key] = GenCharacters._make_hat_icon(idx, 128)
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
	var tex := GenCharacters._make_player_rig(clampi(skin_idx, 0, RIG_NAMES.size() - 1), c["shirt"], c["pants"])
	textures[key] = tex
	return tex


func hand_anchor_of(skin_idx: int) -> Vector2:
	# v1.42 (P11.1): Handanker des Skins in Textur-Pixeln
	var i: int = clampi(skin_idx, 0, HAND_ANCHOR.size() - 1)
	var a: Array = HAND_ANCHOR[i]
	return Vector2(float(a[0]), float(a[1]))


func rig_has_deco_weapon(skin_idx: int) -> bool:
	var i: int = clampi(skin_idx, 0, RIG_DECO_WEAPON.size() - 1)
	return bool(RIG_DECO_WEAPON[i])


func get_skin_texture_noweapon(color_idx: int, skin_idx: int) -> Texture2D:
	# v1.42 (P11.3): Skin ohne gezeichnete Waffen-Deko - fuer Skins, die im
	# Spiel die ECHTE Waffe in der Hand halten (sonst liegen zwei Waffen uebereinander).
	var key := "skin_c%d_s%d_nw" % [color_idx, skin_idx]
	if textures.has(key):
		return textures[key]
	var ci := clampi(color_idx, 0, PLAYER_COLORS.size() - 1)
	var c: Dictionary = PLAYER_COLORS[ci]
	var si: int = clampi(skin_idx, 0, RIG_NAMES.size() - 1)
	if not bool(RIG_DECO_WEAPON[si]):
		# Standard-Skin: unveraendert (P11.5)
		var t0: Texture2D = get_skin_texture(color_idx, skin_idx)
		textures[key] = t0
		print("[SKIN][HAND] rig=%d deko=bleibt grund=keine_dekowaffe" % si)
		return t0
	var tex := GenCharacters._make_player_rig(si, c["shirt"], c["pants"], -1, true)
	textures[key] = tex
	print("[SKIN][HAND] rig=%d deko=aus grund=ueberlappung" % si)
	return tex

func get_skin_hat_texture(color_idx: int, skin_idx: int, hat_idx: int, noweapon: bool = false) -> Texture2D:
	# Runde 48: SKIN + FARBE + HUT in einem Bild.
	# Vorher konnte man nur Base-Skin mit Hut kombinieren - die
	# Hut-Auswahl im Charakterfenster zeigte darum immer das Base-Skin.
	# v1.42 (P11.3): noweapon=true blendet die gezeichnete Skin-Waffe aus.
	var key := "skinh_c%d_s%d_h%d%s" % [color_idx, skin_idx, hat_idx, "_nw" if noweapon else ""]
	if textures.has(key):
		return textures[key]
	var ci := clampi(color_idx, 0, PLAYER_COLORS.size() - 1)
	var c: Dictionary = PLAYER_COLORS[ci]
	var si := clampi(skin_idx, 0, RIG_NAMES.size() - 1)
	var hi := clampi(hat_idx, 0, HAT_NAMES.size() - 1)
	var tex: ImageTexture
	# v1.46 (F4): EIN Zeichenweg fuer alle Skins. Vorher lief Rig 0 ueber
	# _make_player (Hut ohne Fit) und alle anderen ueber _make_player_rig -
	# die Messung zeigte fuer Rig 0 dadurch immer 100 % Abweichung.
	tex = GenCharacters._make_player_rig(si, c["shirt"], c["pants"], hi, noweapon)
	if si == 0:
		print("[HAT][PFAD] rig=0 weg=make_player_rig hut=%d ein_weg=true" % hi)
	textures[key] = tex
	if noweapon:
		print("[SKIN][HAND] rig=%d deko=aus grund=ueberlappung (mit Hut %d)" % [si, hi])
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
	var tex := GenCharacters._make_player(c["shirt"], c["pants"], clampi(hat_idx, 0, HAT_NAMES.size() - 1))
	textures[key] = tex
	return tex

# ============================================================
# Runde 44: Navigations-Icons fuer die Startseiten-Kacheln
# ============================================================

# ============================================================
# Runde 43: WELTEN-ICONS (Punkt 6)
# Jede Welt bekommt ein eigenes, wiedererkennbares Motiv in 16x16
# Pixel-Art. Die generischen Motive (tuft/cactus/ice/lava) sind weg.
# ============================================================

# ---------- Runde 14: Welt-Objekte der Planeten ----------

func _load_external(key: String, res_path: String) -> void:
	# Laedt ein echtes PNG aus assets/ ; faellt bei Problemen auf die prozedurale
	# Variante zurueck (Schluessel bleibt in jedem Fall gueltig).
	if not ResourceLoader.exists(res_path):
		return
	var tex = load(res_path)
	if tex != null and tex is Texture2D:
		textures[key] = tex

# ---------- Runde 14: Planeten-Monster ----------

# ============================================================
# Runde 18: Dschungel-Set nach Referenzbildern des Nutzers
# (runde Wolkenkronen, 3-4 Gruentoenen + dunkle Kontur, Palmen,
#  Trauerweide, Urbaum mit Kristall, Pilze, Kristalle, Schilf)
# ============================================================

const JT_LEAF_D := TexDraw.JT_LEAF_D
const JT_LEAF := TexDraw.JT_LEAF
const JT_LEAF_L := TexDraw.JT_LEAF_L
const JT_TRUNK_D := TexDraw.JT_TRUNK_D
const JT_TRUNK := TexDraw.JT_TRUNK

# ============================================================
# Runde 26: Boss-Redesign nach Nutzerwunsch
# ============================================================

# ============================================================
# Runde 27: Mini-Bosse (alle 5 Wellen) - je Biom ein eigenes Design
# ============================================================

# ============================================================
# Runde 35: ELEKTRO-WELT - Sturmland aus Stahl und Strom
# ============================================================

# ---------- Projektile & Mündungsfeuer ----------

# ---------- Kiste ----------

# ---------- Bäume & Steine ----------

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
	return GenChests._make_gem_chest(128, tier, open_state)

# ---------- Herz ----------

# ---------- Touch-Controls ----------

# ---------- Waffen (detailliert, Lauf zeigt nach rechts) ----------

# ---------- Loot / Powerups ----------
