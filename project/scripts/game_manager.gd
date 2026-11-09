# GameManager.gd - Zentraler Spiel-Controller
# Verwaltet Spielzustände, Score, Map, Monster-Spawning und UI-Übergänge
extends Node2D

const LootTable = preload("res://scripts/systems/loot_table.gd")

enum GameState { MENU, LOBBY, PLAYING, DEAD }
var current_state: GameState = GameState.MENU
var score: int = 0
var high_score: int = 0
var player_health: int = 5
const MAX_HEALTH: int = 5

# XP- & Levelsystem (Runde 3, Stil B: Wahlkarten)
var xp: int = 0
var xp_needed: int = 25
var level: int = 1
var pending_upgrades: int = 0
var _upg_toast_was_open: bool = false
var upg_stacks: Dictionary = {}
var _boss_timer: float = 0.0
var _boss_count: int = 0
const BOSS_INTERVAL := 120.0
var current_boss: Node2D = null

# Buffs (Kistenloot) + Biome (Agenda G1/G4)
var freeze_time: float = 0.0
var rapid_time: float = 0.0
const FREEZE_DURATION := 5.0
const RAPID_DURATION := 8.0
const RAPID_COOLDOWN_MULT := 0.45
var biome_id: String = "meadow"
# Runde 38: Die Jahreszeiten kamen viel zu frueh (zu viel XP pro Runde).
# Im Wellen-Modus wechselt die Jahreszeit jetzt alle 4 Wellen, im Endlos-Modus
# erst bei deutlich hoeherem Score.
const BIOME_STEPS := [
	{ "score": 2500, "id": "desert" },
	{ "score": 7000, "id": "ice" },
	{ "score": 14000, "id": "lava" }
]
const BIOME_STEPS_WAVE := [
	{ "wave": 4, "id": "desert" },
	{ "wave": 8, "id": "ice" },
	{ "wave": 12, "id": "lava" }
]

# Grafikstufen: 0 = NIEDRIG (kein Shader, kaum Details, weniger Monster)
#              1 = MITTEL  (kein Shader, Details, 60 FPS) — STANDARD
#              2 = HOCH    (Soft-Look-Shader + alle Details)
var quality: int = 1
const QUALITY_NAMES := ["NIEDRIG", "MITTEL", "HOCH"]
const CONFIG_VERSION := 3   # v1.39 D2: Profilformat 3 (stabile Skin-/Hut-IDs)
var debug_fps: bool = false
var gems: int = 0            # Runde 67: Edelsteine fuer Kosmetik-Kisten
# v1.44 (C1): Zustand der Aufgaben-Seite { id: {state, progress} } - liegt im Profil.
var challenges: Dictionary = {}
var chests_opened: int = 0

# Zufalls-Events
var event_timer: float = 55.0
var gold_time: float = 0.0
const EVENTS := ["swarm", "elite", "lootrain", "frost", "gold"]

# ---------------- CO-OP (LAN Phase 2): eine gemeinsame Welt ----------------
var coop_host: bool = false           # dieser Rechner simuliert die Welt
var coop_client: bool = false         # dieser Rechner rendert + sendet Input
var _net_seed: int = 0
var _net_biome: String = "meadow"
var _net_map: String = ""
var _net_chests: PackedFloat32Array = PackedFloat32Array()
var _net_zones: PackedFloat32Array = PackedFloat32Array()
var _pending_client_start: bool = false
var _host_chests: PackedFloat32Array = PackedFloat32Array()
var _host_zones: PackedFloat32Array = PackedFloat32Array()
var _revive_held: bool = false
# B3: Karten offen (dieses Geraet waehlt) / Client meldet dem Host dasselbe
var in_upgrade: bool = false
var coop_busy: Dictionary = {}          # slot -> waehlt gerade Karten
var _ghosts: Dictionary = {}
# Runde 79: Snapshot-Puffer fuer Client-Interpolation (100 ms Verzoegerung)
var _mob_buf: Array = []          # [{ "t": ms, "seq": int, "e": [{id,type,x,y,hp,ang}] }]
var _mob_seq_last: int = -1
var _mob_pkt_count: int = 0
var _mob_seq_out: int = 0
const MOB_DELAY_MS: float = 100.0
const MOB_BUF_MAX: int = 6          # net_id -> Monster-Geist (Client)
var _item_ghosts: Dictionary = {}     # net_id -> Item-Geist (Client)

# --- Mehrspieler (Runde 10): bis zu 4 Spieler, Slot 1 = Host ---
var players: Dictionary = {}          # slot -> Player-Node
var my_slot: int = 1                  # eigener Slot (Host 1, Clients 2..4)
# Runde 33: Variante B - jeder Spieler hat eigene Muenzen + eigenen Shop
var slot_coins: Dictionary = {}       # Slot -> Muenzen
var shop_ready: Dictionary = {}        # Slot -> hat den Shop verlassen?
var shop_purchases_left: int = 3       # Runde 34: Kaeufe pro Shop-Phase
var shop_offers: Array = []             # Runde 34: in dieser Phase angebotene Items
# Runde 34: Mehrspieler - "downed" statt sofort Game Over + Aufwecken
var downed: Dictionary = {}             # Slot -> liegt am Boden
var downed_time: Dictionary = {}        # Slot -> Sekunden bis Game Over
var revive_progress: Dictionary = {}    # Slot -> Aufbauzeit (Partner in Naehe)
var spectator: Dictionary = {}          # Runde 51: Slot -> endgueltig tot (Zuschauer)
var _boss_defeats: int = 0              # Runde 53: wie viele Bosse WIRKLICH starben
var _boss_active: bool = false          # Runde 53: Boss lebt (Ref allein reicht nicht,
										# eine freigegebene Referenz vergleicht sich wie null)
var _boss_last_type: String = "?"       # Runde 53: Typ fuer das DEFEAT-Log merken
var _downed_rings: Dictionary = {}      # Runde 35b: HILFE-Ringe
var force_fields: Array = []            # Runde 38: wandernde Kraftfelder (ab Welle 7)
const DOWNED_LIMIT := 30.0              # Sekunden, bis der Run endet
const REVIVE_TIME := 5.0                # Runde 86: 5 s Halten zum Aufwecken
const WAVE_LEVEL_UPS := 2             # Level-Aufstiege pro Welle, BIS der Shop oeffnet
var wave_start_level: int = 1         # Level bei Wellebeginn (Differenz = Aufstiege)
var _reinforce_timer: float = 0.0     # Nachschub-Timer (Welle laeuft weiter bis Levelziel)
var slot_profiles: Dictionary = {}    # slot -> {name, color, hat}
var slot_ready: Dictionary = {}       # slot -> bool
var _t_mobs: float = 0.0
var _t_world: float = 0.0
var _t_myp: float = 0.0
var _t_items: float = 0.0
var _next_mid: int = 1
var _next_iid: int = 1
var _my_aim_deg: float = 0.0

# ---------------- Wellen-Modus mit Shop (Punkt 6) ----------------
var _event_blocked: int = 0
var game_mode: int = 0            # 0 = Endlos, 1 = Wellen (alt), 2 = Runden (v1.40)
var rounds_mode = null            # RoundsMode-Modul (game_mode == 2)
var round_difficulty: String = "normal"   # W6.8: leicht | normal | hart
var wave: int = 0
var wave_active: bool = false
var in_shop: bool = false
var shop_time: float = 0.0
var coins: int = 0
var run_xp: int = 0                # XP dieses Runs (Kartenschalter, Runde 12)
var best_run_xp: int = 0
var wave_remaining: int = 0       # zählt lebende Wellen-Monster (inkl. Splitter-Kinder)
# v1.56 (Spec K2): Erholungsfenster vor dem Shop - 6 s kein Spawn, keine Adds
var _shop_delay: float = 0.0
var _shop_delay_active: bool = false
var _shop_coins_start: int = 0        # Muenzen bei Wellenbeginn (C2: Guthaben vs Druck)
var _wave_watch_t: float = 0.0        # v1.56b: Watchdog gegen "Modus steht"
# v1.56 (Spec 4.1): Messzaehler fuer den Bot-Proxy (Treffer/Schaden/Heilung)
var bal_treffer: int = 0
var bal_schaden: int = 0
var bal_kills: int = 0
var _wave_upgrade_hint_shown: bool = false
# Runde 34: Shop wird zur echten Entscheidung
const SHOP_BUY_LIMIT := 3              # maximale Kaeufe pro Shop-Phase
const SHOP_RARE_ITEMS := [
	{ "id": "heal_plus", "label": "GROSSE HEILUNG", "price": 45, "rare": true, "desc": "Volle Heilung + 3 Herzen" },
	{ "id": "shield_plus", "label": "PANZER +3", "price": 40, "rare": true, "desc": "3 Schildtreffer extra" },
	{ "id": "maxhp2", "label": "MAX-HERZ +2", "price": 55, "rare": true, "desc": "2 Herzen mehr Maximum" },
	{ "id": "bomb_stash", "label": "3 BOMBEN", "price": 35, "rare": true, "desc": "Drei Bomben fuer sofort" },
	{ "id": "damage_plus", "label": "SCHADEN +35%", "price": 50, "rare": true, "desc": "Deutlich mehr Schaden" },
	{ "id": "speed_plus", "label": "TEMPO +20%", "price": 42, "rare": true, "desc": "Du bewegst dich schneller" },
	{ "id": "rapid_plus", "label": "SCHNELLFEUER 12s", "price": 38, "rare": true, "desc": "Dauerfeuer fuer 12 Sekunden" },
	{ "id": "gold_plus", "label": "GOLD +60", "price": 45, "rare": true, "desc": "Sofort 60 Muenzen extra" },
	{ "id": "freeze_plus", "label": "FROST 10s", "price": 40, "rare": true, "desc": "Gegner stehen 10s still" },
	{ "id": "combo_plus", "label": "COMBO +1", "price": 44, "rare": true, "desc": "Punkte-Multiplikator bleibt laenger" },
]
const SHOP_ITEMS := [
	{ "id": "potion", "label": "HEILTRANK x1", "price": 12 },
	{ "id": "bomb", "label": "BOMBE x1", "price": 18 },
	{ "id": "heal", "label": "KOMPLETT HEILEN", "price": 15 },
	{ "id": "shield", "label": "SCHILD +2", "price": 20 },
	{ "id": "weapon", "label": "ZUFALLSWAFFE", "price": 25 },
	{ "id": "maxhp", "label": "MAX-HERZ +1", "price": 30 },
	{ "id": "speed", "label": "TEMPO +8%", "price": 35 },
	{ "id": "damage", "label": "SCHADEN +20%", "price": 40 }
]

func _alive_real_monsters() -> int:
	var n := 0
	for m in get_tree().get_nodes_in_group("monsters"):
		if is_instance_valid(m) and not m.ghost:
			n += 1
	return n

func _wave_spawn_pos(center: Vector2, far: bool = false) -> Vector2:
	# Bugfix Runde 9: Wellen-Monster MÜSSEN innerhalb der Welt spawnen.
	# Vorher: 520-900 px um den Helden ohne Begrenzung -> am Kartenrand landeten
	# sie hinter der Grenzwand, waren unerreichbar und die Welle war nie fertig
	# ("in Welle 2 spawnt nichts mehr").
	var b: Rect2 = map_generator.get_bounds()
	var margin := 130.0
	var dmin := 520.0 if far else 400.0
	var dmax := 830.0 if far else 700.0
	var best := center
	for attempt in range(20):
		var a := randf_range(0.0, TAU)
		var p: Vector2 = center + Vector2(cos(a), sin(a)) * randf_range(dmin, dmax)
		p.x = clampf(p.x, b.position.x + margin, b.end.x - margin)
		p.y = clampf(p.y, b.position.y + margin, b.end.y - margin)
		best = p
		if p.distance_to(center) >= 240.0:
			return p
	return best

func _start_wave() -> void: _waves_p()._start_wave()

# ============================================================
# SCHWIERIGKEIT + ZIELHILFE (Runde 15, Tester-Feedback)
# ============================================================
# Runde 49c: "coins" ist der MUENZ-FAKTOR und war VERKEHRT HERUM -
# haettere Schwierigkeit gab MEHR Gold (1.35 / 1.70). Jetzt gilt:
# haerter = weniger Gold, damit man nicht alles kaufen kann.
# v1.56 (Spec A2): KEINE eigene Balancetabelle mehr. Alle Stufenwerte kommen
# aus scripts/core/balance.gd (Single Source of Truth). Diese Liste ist nur
# noch ein Adapter mit dem alten Schluessel-Layout (hp/dmg/speed/spawn/coins/hearts),
# damit HUD, Shop und Netzwerk weiter funktionieren.
static func _build_difficulty() -> Array:
	var out: Array = []
	for s in Balance.STUFEN:
		var d: Dictionary = Balance.data(s)
		out.append({
			"name": str(s).to_upper(),
			"hp": float(d["hp"]),
			"dmg": float(d["dmg"]),
			"speed": float(d["speed"]),
			"spawn": float(d["wellen_anzahl"]),
			"coins": float(d["coins"]),
			"hearts": int(d["hearts"]),
		})
	return out

var DIFFICULTY: Array = _build_difficulty()
var difficulty: int = 1
# v1.42 (P4.1): Musiklautstaerke in Prozent (Profil)
var music_volume: int = 80
var aim_assist: int = 1          # 0 = aus, 1 = schwach, 2 = stark
var tip_shown: bool = false
var paused: bool = false

func diff_data() -> Dictionary:
	return DIFFICULTY[clampi(difficulty, 0, DIFFICULTY.size() - 1)]

func set_difficulty(d: int) -> void:
	difficulty = clampi(d, 0, DIFFICULTY.size() - 1)
	if is_instance_valid(player):
		player.aim_assist = aim_assist
	_save_profile()
	if ui_manager != null and ui_manager.has_method("refresh_difficulty_ui"):
		ui_manager.call("refresh_difficulty_ui")

func set_aim_assist(a: int) -> void:
	aim_assist = clampi(a, 0, 2)
	for p in player_nodes():
		p.aim_assist = aim_assist
	_save_profile()
	if ui_manager != null and ui_manager.has_method("refresh_aim_ui"):
		ui_manager.call("refresh_aim_ui")

func request_chest_open(pos: Vector2) -> void:
	NetManager.c_send_chest_open(pos)

func _on_chest_open_request(pos: Vector2) -> void:
	# Host: Kiste in der Naehe finden, Loot normal spawnen (geht per Snapshot an
	# den Client) und die Kiste fuer beide entfernen.
	if not (lan_mode and NetManager.is_host):
		return
	var best: Node = null
	var best_d := 90.0
	for cc in chest_container.get_children():
		if not is_instance_valid(cc):
			continue
		var d: float = cc.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = cc
	if best != null:
		if best.has_method("_spawn_item"):
			best.call("_spawn_item")
		best.queue_free()

func _on_net_wave_state(w: int, shop: bool, t: float, remaining: int, c_v: int, mode: int) -> void:
	# Client: Wellen-/Shop-Zustand vom Host uebernehmen (vorher lief die Wellenlogik
	# beim Client nie -> im Mehrspieler kam der Nicht-Host nicht in den Shop)
	if not coop_client:
		return
	wave = w
	wave_remaining = remaining
	game_mode = mode
	# Runde 33: coins NICHT mehr vom Host uebernehmen - jeder Spieler hat eigene
	# Muenzen (kommen ueber _on_net_shop_state)
	if shop:
		if not in_shop:
			in_shop = true
			_sdiag("OPEN", "Client oeffnet Shop (Angebote bisher=%s)" % str(_shop_offer_ids()))
			ui_manager.show_shop(coins, shop_offers, shop_purchases_left, SHOP_BUY_LIMIT)
			ui_manager.show_banner("SHOP! %.0fs" % t, Color(0.55, 0.95, 1.0))
		shop_time = t
		ui_manager.update_wave_label(wave, coins, true, shop_time, wave_remaining)
	else:
		if in_shop:
			in_shop = false
			shop_time = 0.0
			ui_manager.hide_shop()
			ui_manager.show_banner("WELLE %d" % wave, Color(0.95, 0.85, 0.35))
		ui_manager.update_wave_label(wave, coins, false, 0.0, wave_remaining)

func refresh_utility_hud() -> void:
	if ui_manager != null and is_instance_valid(player) and ui_manager.has_method("refresh_utility_hud"):
			ui_manager.call("refresh_utility_hud", player.utilities, player.call("get_weapon_key"))

func toggle_pause() -> void:
	if current_state != GameState.PLAYING:
		return
	if paused:
		paused = false
		get_tree().paused = false
		if ui_manager != null:
			ui_manager.hide_pause()
		# v1.42 (P1.4): Beleg - Run laeuft mit unveraenderten Werten weiter
		if is_instance_valid(player):
			print("[PAUSE][RESUME] welle=%d hp=%d/%d muenzen=%d paused=false" % [
				wave, int(player.health), int(player.max_health), coins])
		else:
			print("[PAUSE][RESUME] welle=%d hp=-/- muenzen=%d paused=false (kein Spieler)" % [wave, coins])
	else:
		paused = true
		get_tree().paused = true
		if ui_manager != null:
			ui_manager.show_pause()

func restart_run() -> void:
	paused = false
	get_tree().paused = false
	if ui_manager != null:
		ui_manager.hide_pause()
	start_game(false, false)

func _clear_run() -> void:
	# Runde 76: Beim Verlassen eines Runs blieben Spieler und Monster in der
	# Welt stehen. Beim naechsten Start existierten dann ZWEI Figuren.
	# Hier wird die Welt vollstaendig geraeumt - Knoten werden sofort aus dem
	# Baum genommen, nicht erst am Frame-Ende.
	var removed := 0
	for slot in players.keys():
		var p = players[slot]
		if is_instance_valid(p):
			if p.get_parent() != null:
				p.get_parent().remove_child(p)
			p.queue_free()
			removed += 1
	players.clear()
	for p2 in [player, player2]:
		if p2 != null and is_instance_valid(p2):
			if p2.get_parent() != null:
				p2.get_parent().remove_child(p2)
			p2.queue_free()
			removed += 1
	player = null
	player2 = null
	if monster_container != null and is_instance_valid(monster_container):
		for m in monster_container.get_children():
			monster_container.remove_child(m)
			m.queue_free()
			removed += 1
	_monster_cache.clear()
	current_boss = null
	_boss_active = false
	wave_active = false
	in_shop = false
	zones.clear()
	print("[RUN] Welt geraeumt: %d Knoten entfernt" % removed)


func quit_to_menu() -> void:
	paused = false
	get_tree().paused = false
	if chal_active:
		chal_stop()
	if ui_manager != null and ui_manager.has_method("hide_challenge_hud"):
		ui_manager.call("hide_challenge_hud")
	_clear_run()
	if ui_manager != null:
		ui_manager.hide_pause()
	current_state = GameState.MENU
	ui_manager.show_start_screen()
	# v1.42 (P1.5): echter Abbruch - Startseite muss wieder spielbar sein
	if ui_manager != null:
		var sp = ui_manager.get("settings_page")
		if sp != null and is_instance_valid(sp):
			sp.hide()
		ui_manager.set("settings_origin", "menu")
	var ss: bool = false
	if ui_manager != null and ui_manager.start_screen != null:
		ss = ui_manager.start_screen.visible
	print("[PAUSE][MENU] run_beendet=true start_screen=%s im_runden=%s paused=false" % [
		str(ss), str(current_state == GameState.PLAYING)])

func can_shoot_now() -> bool:
	# Runde 15: im Shop und in Menues darf nicht geschossen werden (Tester-Feedback)
	# Runde 60: auch nicht, waehrend das Debug-Fenster offen ist
	if debug_open:
		return false
	if in_shop or current_state != GameState.PLAYING:
		return false
	if ui_manager != null and ui_manager.has_method("is_modal_open") and bool(ui_manager.call("is_modal_open")):
		return false
	return true

func _open_shop() -> void:
	in_shop = true
	wave_active = false
	_shop_delay_active = false
	shop_time = 30.0
	shop_ready.clear()
	shop_ready[my_slot] = false
	# v1.56 (Spec K6/C2): Shop-Guthaben an den Druck der Welle koppeln.
	# Ziel = k * druck_peak (Balance.shop_guthaben), Boss-Wellen zahlen doppelt.
	# Was die Welle ueber Kills eingebracht hat, wird auf das Ziel aufgestockt.
	if game_mode == 1:
		var druck_peak: float = float(_waves_p().wave_druck)
		if druck_peak <= 0.0:
			druck_peak = 1.0
		var ziel: int = Balance.shop_guthaben(druck_peak, bool(_waves_p().wave_boss))
		var verdient: int = maxi(0, coins - int(_shop_coins_start))
		var bonus: int = maxi(0, ziel - verdient)
		coins += bonus
		print("[BAL][SHOP] modus=wellen welle=%d verdient=%d bonus=%d guthaben=%d druck_peak=%.2f ziel=%d verhaeltnis=%.2f" % [
			wave, verdient, bonus, coins, druck_peak, ziel,
			Balance.shop_verhaeltnis(coins - int(_shop_coins_start), druck_peak)])
	slot_coins[my_slot] = coins
	shop_purchases_left = SHOP_BUY_LIMIT          # Runde 34
	shop_offers = _build_shop_offers()           # Runde 34
	_sdiag("OPEN", "Welle %d | Gold=%d | Kaeufe=%d/%d | Angebote=%s" % [
		wave, coins, shop_purchases_left, SHOP_BUY_LIMIT, str(_shop_offer_ids())])
	ui_manager.show_shop(coins, shop_offers, shop_purchases_left, SHOP_BUY_LIMIT)
	ui_manager.show_banner("SHOP! 30s", Color(0.55, 0.95, 1.0))
	_send_shop_state()
	_send_shop_offers()


func _send_shop_offers() -> void:
	# Runde 52: Die konkreten Angebote dieser Phase an die Clients.
	# Ohne das zeigte der Client den Gesamtkatalog (SHOP_ITEMS) und
	# Kaeufe wurden vom Host abgelehnt, ohne dass es sichtbar war.
	if not (coop_host and lan_mode):
		return
	var ids := PackedStringArray()
	var prices := PackedInt32Array()
	var bought := PackedByteArray()
	for o in shop_offers:
		ids.append(str(o.get("id", "?")))
		prices.append(int(o.get("price", 1)))
		bought.append(1 if bool(o.get("bought", false)) else 0)
	NetManager.h_send_shop_offers(ids, prices, bought, shop_purchases_left, SHOP_BUY_LIMIT)
	_sdiag("NET", "Angebote an Clients: %s | Kaeufe=%d" % [str(ids), shop_purchases_left])

func _next_wave(force: bool = false) -> void: _waves_p()._next_wave(force)

func _all_players_ready() -> bool:
	# Alle belegten Slots (ausser dem eigenen) muessen fertig sein.
	# shop_ready-Slots zaehlen mit, damit auch ein Spieler, dessen Verbindung
	# kurz weg war, nicht ewig blockiert.
	var slots: Array = []
	for s2 in NetManager.occupied_slots():
		slots.append(int(s2))
	for k in shop_ready.keys():
		var kk: int = int(k)
		if not slots.has(kk):
			slots.append(kk)
	for s3 in slots:
		if int(s3) == my_slot:
			continue
		if not bool(shop_ready.get(int(s3), false)):
			return false
	return true

func buy_shop_item(id: String) -> void:
	# Runde 33 (Variante B): der Client kauft mit SEINEN Muenzen -> der Host
	# prueft und wendet den Kauf auf den richtigen Spieler an.
	if coop_client and not coop_host:
		NetManager.c_send_shop_buy(id)
		return
	_apply_shop_purchase(id, my_slot)

func _apply_shop_purchase(id: String, slot: int) -> void:
	_sdiag("REQ", "Kauf '%s' fuer Slot %d (Gold Slot=%d, Kaeufe=%d, Angebot=%s)" % [
		id, slot, int(slot_coins.get(slot, 0)), shop_purchases_left, str(_shop_offer_ids())])
	if shop_purchases_left <= 0:
		_sdiag("FAIL", "Kauf '%s' ABGELEHNT: keine Kaeufe mehr (0/%d)" % [id, SHOP_BUY_LIMIT])
		return
	# Runde 34: nur die aktuell angebotenen Items sind kaufbar
	var offered := false
	for o in shop_offers:
		if str(o["id"]) == id:
			offered = true
			break
	if not offered and shop_offers.size() > 0:
		_sdiag("FAIL", "Kauf '%s' ABGELEHNT: nicht im Angebot %s" % [id, str(_shop_offer_ids())])
		return
	for it in shop_offers:
		if str(it["id"]) != id:
			continue
		# Runde 52: Ein bereits gekauftes Angebot ist verbraucht.
		# Vorher liess es sich per Doppelklick mehrfach kaufen.
		if bool(it.get("bought", false)):
			_sdiag("FAIL", "Kauf '%s' ABGELEHNT: bereits gekauft" % id)
			return
		# Runde 52: Preis pro Slot - der Client sieht denselben Wert.
		var price: int = shop_price(int(it["price"]))
		var cur: int = int(slot_coins.get(slot, 0))
		if cur < price:
			_sdiag("FAIL", "Kauf '%s' ABGELEHNT: zu wenig Gold (%d < %d)" % [id, cur, price])
			return
		slot_coins[slot] = cur - price
		shop_purchases_left -= 1
		_sdiag("BUY", "Slot %d kauft '%s' fuer %d -> Gold %d, Kaeufe uebrig %d" % [
			slot, id, price, int(slot_coins[slot]), shop_purchases_left])
		for o3 in shop_offers:            # Runde 36: Angebot als "verpasst" merken
			if str(o3["id"]) == id:
				o3["bought"] = true

		if slot == my_slot:
			coins = int(slot_coins[my_slot])
		SoundManager.play("pickup")
		var tgt = _player_for_slot(slot)
		if is_instance_valid(tgt):
			_apply_purchase(id, tgt)
		else:
			_sdiag("WARN", "Kauf '%s': kein Spieler-Knoten fuer Slot %d (Wirkung fehlt!)" % [id, slot])
		if duo_mode and slot == my_slot and is_instance_valid(player2):
			_apply_purchase(id, player2)
		if id == "maxhp" and is_instance_valid(tgt):
			ui_manager.update_health(tgt.call("get_health"), tgt.call("get_max_health"), 1)
		ui_manager.show_shop(coins, shop_offers, shop_purchases_left, SHOP_BUY_LIMIT)
		ui_manager.update_wave_label(wave, coins, true, shop_time, wave_remaining, level, wave_start_level + WAVE_LEVEL_UPS)
		_send_shop_state()
		_send_shop_offers()
		return

func _player_for_slot(slot: int) -> Node:
	if slot == my_slot and is_instance_valid(player):
		return player
	var p = players.get(slot, null)
	if is_instance_valid(p):
		return p
	return player

func _apply_purchase(id: String, p: Node) -> void:
	# Runde 34: Rare-Items
	match id:
		"heal_plus":
			p.call("heal", 99)
			if p.has_method("add_max_health"):
				p.call("add_max_health", 3)
			return
		"shield_plus":
			p.call("add_shield", 3)
			return
		"maxhp2":
			if p.has_method("add_max_health"):
				p.call("add_max_health", 2)
			return
		"bomb_stash":
			p.call("add_utility", "bomb", 3)
			return
		"damage_plus":
			if p.has_method("add_damage_mult"):
				p.call("add_damage_mult", 0.35)
			return
		"speed_plus":
			if p.has_method("add_speed_mult"):
				p.call("add_speed_mult", 0.20)
			return
		"rapid_plus":
			rapid_time = maxf(rapid_time, 12.0)
			return
		"gold_plus":
			slot_coins[my_slot] = int(slot_coins.get(my_slot, 0)) + 60
			if my_slot == 0 or true:
				coins = int(slot_coins.get(my_slot, coins))
			return
		"freeze_plus":
			freeze_time = maxf(freeze_time, 10.0)
			return
		"combo_plus":
			combo_count = combo_count + 1
			combo_timer = COMBO_WINDOW * 2.0
			return
	match id:
		"heal":
			p.call("heal", 99)
		"shield":
			p.call("add_shield", 2)
		"weapon":
			var ws := ["weapon_pistol", "weapon_shotgun", "weapon_machine", "weapon_laser", "weapon_revolver"]
			p.call("switch_weapon", ws[randi() % ws.size()])
		"maxhp":
			p.call("add_max_health")
		"speed":
			p.speed_mult = minf(1.6, p.speed_mult + 0.08)
		"damage":
			p.damage_mult = minf(3.0, p.damage_mult + 0.20)
		"potion":
			p.call("add_utility", "potion", 1)
		"bomb":
			p.call("add_utility", "bomb", 1)

func set_game_mode(m: int) -> void:
	game_mode = clampi(m, 0, 2)
	ui_manager.set_mode_label(game_mode)
	print("[MODE] wahl=%d %s" % [game_mode, mode_name(game_mode)])
	_save_profile()

func cycle_game_mode() -> void:
	set_game_mode((game_mode + 1) % 3)

func mode_name(m: int = -1) -> String:
	match (game_mode if m < 0 else m):
		1: return "WELLEN"
		2: return "RUNDEN"
	return "ENDLOS"

func set_round_difficulty(d: String) -> void:
	round_difficulty = d if Rounds.DIFFICULTY.has(d) else "normal"
	print("[WAVE][DIFF] grad=%s herzen_start=%d hp_mult=%.2f preis_mult=%.2f" % [
		round_difficulty, int(Rounds.DIFFICULTY[round_difficulty]["herzen"]),
		float(Rounds.DIFFICULTY[round_difficulty]["hp"]),
		float(Rounds.DIFFICULTY[round_difficulty]["preis"])])

func _rm():
	# Modul lazy anlegen (Fassade bleibt schlank, Modul kennt nur `host`)
	if rounds_mode == null:
		rounds_mode = RoundsMode.new()
		rounds_mode.host = self
	return rounds_mode

# --- Fassade fuer den RUNDEN-Modus (W2/W3) ---
func start_round() -> void: _rm().start_round()
func next_round() -> void: _rm().next_round()
func rounds_round_no() -> int: return int(_rm().round_no)
func rounds_lives() -> int: return int(_rm().lives)

func open_rounds_shop() -> void:
	# W2.3: Shop oeffnen pausiert das Spiel (Overlay liegt in der UI)
	if game_mode != 2:
		return
	if get_tree().paused:
		return
	set_rounds_shop_open(true)
	ui_manager.open_rounds_shop()
	print("[WAVE][UI] shop_offen=true runde=%d" % rounds_round_no())

func set_rounds_shop_open(open: bool) -> void:
	_rm().set_shop_open(open)
	if not open:
		print("[WAVE][UI] shop_offen=false")

func buy_revive_available() -> bool: return _rm().can_buy_revive()

# ---------------- Profil: Name, Farbe, Hut (Punkt 8) ----------------
var p_name: String = "HELD"
var lang: String = "de"        # Runde 136 (K): Spielsprache "de" | "en"
var p_color: int = 0
var p_hat: int = 0
var unlocked_hats: Array = [0, 1]      # ohne Hut + Kappe von Anfang an
var unlocked_rigs: Array = [0]          # Runde 38: Character-Rigs (0 = normal)
var p_rig: int = 0                      # Runde 38: aktives Rig
var partner_name: String = ""
var partner_color: int = 1
var partner_hat: int = 0
var partner_rig: int = 0
# Runde 111: zuletzt gemeldete Client-Position (fuer Naehe-Pruefung beim Revive)
var _partner_pos: Vector2 = Vector2.ZERO
var _partner_pos_fresh: float = 0.0

# ---------------- Meta-Progression (Runde 11): Gold, Kisten, Karten ----------------
var gold: int = 0
var chests_since_rare: int = 0          # Runde 36: Pity (10 Kisten ohne Rare -> Rare garantiert)
var xp_total: int = 0
var unlocked_colors: Array = [0, 1]        # Blau + Rot frei
var unlocked_maps: Array = ["earth"]
var active_map: String = "earth"
const GOLD_PER_SCORE := 12

const MAPS := [
	{ "id": "earth", "name": "ERDE", "biome": "meadow", "desc": "Die ganze Reise: Wiese, Wueste, Eisfeld, Lavahoelle in einem Run", "price": 0,
	  "icon": "map_meadow", "progressive": true, "pool": [], "gate": {},
	  "speed": 1.0, "damage": 1.0 },
	{ "id": "mars", "name": "MARS", "biome": "mars", "desc": "Roter Sand, Mars-Maennchen und Rover. Alles rutscht — Drift-Physik!",
	  "price": 6000, "icon": "map_mars", "progressive": false, "pool": [11, 11, 15, 15, 12, 12, 16],
	  "speed": 1.05, "damage": 1.0, "drift": 0.20,
	  "gate": { "type": "xp", "need": 2500, "prereq": "" } },
	{ "id": "jungle", "name": "JUNGLE-PLANET", "biome": "jungle", "desc": "Dichter Dschungel, Robo-Affen werfen Bananen, Riesenblumen spucken Sporen",
	  "price": 12000, "icon": "map_jungle", "progressive": false, "pool": [13, 13, 17, 17, 18, 14],
	  "speed": 1.0, "damage": 1.15, "vegetation": 2.1,
	  "gate": { "type": "xp", "need": 3500, "prereq": "mars" } },
	{ "id": "volt", "name": "ELEKTRO-WELT", "biome": "volt", "desc": "Sturmland aus Stahl und Strom: Teslaspulen, Kapazitaeten, Schrottroboter",
	  "price": 20000, "icon": "map_volt", "progressive": false, "pool": [25, 25, 26, 26, 27, 29, 29],
	  "speed": 1.08, "damage": 1.25, "vegetation": 1.05,
	  "gate": { "type": "xp", "need": 5000, "prereq": "jungle" } }
]

# Runde 42: NUR NOCH 3 KISTEN.
# Jede Kiste hat eine Seltenheits-VERTEILUNG fuer die KOSMETIK
# (Farben / Huete / Skins). Verbrauchsgueter und Gold sind immer
# "gewoehnlich" und fuellen den Rest auf.
# rarity-Keys: "common" = gewoehnlich, "rare" = selten, "epic" = episch
# v1.52: Jeder Gewinn zahlt zusaetzlich Gold/Edelsteine je Seltenheit - damit
# sich eine epische Kiste auch beim Geld lohnt, nicht nur optisch.
const CHEST_RARITY_BONUS := {
	"common": { "gold": 8, "gems": 0 },
	"rare": { "gold": 35, "gems": 2 },
	"epic": { "gold": 90, "gems": 6 },
	"legendary": { "gold": 220, "gems": 15 },
}

const CHESTS := [
	{ "id": "wood", "name": "HOLZKISTE", "price": 60, "icon": "chest_wood", "fallback": 20, "items": 1,
	  "mix": { "common": 78, "rare": 20, "epic": 2 },
	  "pool": [ ["gold", 62], ["gems", 38] ] },
	{ "id": "silver", "name": "SILBERKISTE", "price": 150, "icon": "chest_silver", "fallback": 60, "items": 1,
	  "mix": { "common": 40, "rare": 48, "epic": 12 },
	  "pool": [ ["gold", 70], ["gems", 30] ] },
	{ "id": "gold", "name": "GOLDKISTE", "price": 320, "icon": "chest_gold", "fallback": 150, "items": 2,
	  "mix": { "common": 14, "rare": 46, "epic": 40 },
	  "pool": [ ["gold", 78], ["gems", 22] ] },
]

# Runde 42: Seltenheit der KOSMETIK-Items (Index-basiert auf die Reihenfolge
# in COLOR_NAMES / HAT_NAMES / RIG_NAMES).
# Gewoehnlich = die Basics, Selten = die kräftigen Varianten,
# Episch = die Sonderformen.
const COLOR_RARITY := ["common", "common", "common", "common", "common", "rare", "common", "rare", "rare", "epic"]
const HAT_RARITY := ["common", "common", "common", "rare", "rare", "common", "rare", "rare", "epic", "legendary",
	"legendary", "rare", "epic",
	"common", "common", "common", "common",
	"rare", "rare", "rare",
	"epic", "epic", "epic",
	"legendary", "legendary"]
const RIG_RARITY := ["common", "rare", "rare", "epic", "epic", "legendary", "epic", "legendary", "epic",
	"epic", "legendary",
	# v1.41 (N5): 3 legendaere + 3 epische Konzept-Skins (Nutzerwahl)
	"legendary", "legendary", "legendary", "epic", "epic", "epic"]

const RARITY_NAMES := { "common": "GEWOEHNLICH", "rare": "SELTEN", "epic": "EPISCH", "legendary": "LEGENDAER" }
const RARITY_COLORS := {
	"common": Color(0.68, 0.72, 0.78),
	"rare": Color(0.38, 0.68, 1.0),
	"epic": Color(0.78, 0.46, 1.0)
}

func rarity_color(r: String) -> Color:
	# Runde 37: einheitliche Seltenheitsfarben (grau / blau / lila / gold)
	match r:
		"rare":
			return Color(0.36, 0.68, 1.0)
		"epic":
			return Color(0.78, 0.45, 1.0)
		"legendary":
			return Color(1.0, 0.82, 0.25)
	return Color(0.82, 0.85, 0.88)

func get_chests_since_rare() -> int:
	# Runde 36: fuer die Pity-Regel im chest_system
	return chests_since_rare

func map_data(mid: String = "") -> Dictionary:
	var want := mid if mid != "" else active_map
	for m in MAPS:
		if str(m["id"]) == want:
			return m
	return MAPS[0]

func is_map_unlocked(mid: String) -> bool:
	return unlocked_maps.has(mid)

func set_active_map(mid: String) -> void:
	if not is_map_unlocked(mid):
		return
	active_map = mid
	_save_profile()
	ui_manager.refresh_maps_ui()

func buy_map(mid: String) -> bool:
	var d := map_data(mid)
	var price := int(d.get("price", 600))
	if price <= 0 or is_map_unlocked(mid) or gold < price:
		return false
	gold -= price
	_unlock_map(mid)
	# v1.44 (K2): Kartenkauf schaltet NUR die Startjahreszeit frei.
	if not season_unlocks.has(mid):
		season_unlocks[mid] = ["spring"]
	var frei: Array = season_unlocks[mid]
	print("[KARTE][KAUF] planet=%s karte=%d frei=%s gesperrt=%d gold=%d" % [
		mid, price, str(frei), 3 - (frei.size() - 1), gold])
	_save_profile()
	ui_manager.show_banner("KARTE FREIGESCHALTET: " + str(d["name"]), Color(0.55, 0.95, 1.0))
	return true

func _unlock_map(mid: String) -> bool:
	if unlocked_maps.has(mid):
		return false
	unlocked_maps.append(mid)
	return true

func _unlock_color(i: int) -> bool:
	if unlocked_colors.has(i):
		return false
	unlocked_colors.append(i)
	return true

func is_color_unlocked(i: int) -> bool:
	return unlocked_colors.has(i)

# ---------------- Gold ----------------
func award_run_gold() -> int:
	var lvl: int = maxi(1, level)
	var g := int(score / GOLD_PER_SCORE) + lvl * 3 + int(float(coins) * 0.25)
	if g < 0:
		g = 0
	gold += g
	xp_total += score
	_save_profile()
	ui_manager.set_start_gold(gold)
	return g


# ---------------- Kisten ----------------
func _locked_colors() -> Array:
	var out: Array = []
	for i in range(TextureManager.COLOR_NAMES.size()):
		if not unlocked_colors.has(i):
			out.append(i)
	return out

func _locked_rigs() -> Array:
	# Runde 38: noch nicht freigeschaltete Rigs
	var out: Array = []
	for i in range(1, TextureManager.RIG_NAMES.size()):
		if not unlocked_rigs.has(i):
			out.append(i)
	return out

func _locked_hats(filter: Array) -> Array:
	var out: Array = []
	for i in filter:
		if not unlocked_hats.has(i):
			out.append(int(i))
	return out

func _locked_of_rarity(kind: String, rarity: String) -> Array:
	# Runde 42: nur die noch gesperrten Items einer Seltenheitsstufe
	var out: Array = []
	match kind:
		"color":
			for i in range(TextureManager.COLOR_NAMES.size()):
				if not unlocked_colors.has(i):
					var r: String = str(COLOR_RARITY[i]) if i < COLOR_RARITY.size() else "common"
					if r == rarity:
						out.append(i)
		"hat":
			for i in range(TextureManager.HAT_NAMES.size()):
				if not unlocked_hats.has(i):
					var r2: String = str(HAT_RARITY[i]) if i < HAT_RARITY.size() else "common"
					if r2 == rarity:
						out.append(i)
		"rig":
			for i in range(1, TextureManager.RIG_NAMES.size()):
				if not unlocked_rigs.has(i):
					var r3: String = str(RIG_RARITY[i]) if i < RIG_RARITY.size() else "rare"
					if r3 == rarity:
						out.append(i)
	return out

func _any_cosmetic_of_rarity(rarity: String) -> Array:
	# Runde 42: erst die "schoensten" Klassen probieren: Skins, dann Huete, dann Farben
	for kind in ["rig", "hat", "color"]:
		var lst := _locked_of_rarity(kind, rarity)
		if not lst.is_empty():
			return [kind, lst]
	return []

func _locked_maps() -> Array:
	var out: Array = []
	for m in MAPS:
		if int(m.get("price", 0)) > 0 and not unlocked_maps.has(str(m["id"])):
			out.append(str(m["id"]))
	return out

func _chest_pool(tier: Dictionary) -> Array:
	# Nicht mehr moegliche Eintraege (alles besessen) herausfiltern
	var out: Array = []
	for e in tier["pool"]:
		var tag := str(e[0])
		var ok := true
		match tag:
			"color":
				ok = not _locked_colors().is_empty()
			"rig":
				ok = not _locked_rigs().is_empty()
			"hat_low":
				ok = not _locked_hats([2, 5]).is_empty()
			"hat_high":
				ok = not _locked_hats([3, 4]).is_empty()
			"map":
				ok = not _locked_maps().is_empty()
		if ok:
			out.append(e)
	return out

func chest_contents(tier: Dictionary) -> Array:
	# Runde 42: Anzeige zeigt den SELTENHEITS-MIX der Kiste, nicht die rohe Pool-Liste.
	# Das ist aussagekraeftiger und der Shop laesst sich so lesen.
	var out: Array = []
	out.append("+ Verbrauchsgueter & Gold")
	return out

func chest_mix_label(tier: Dictionary) -> String:
	# Runde 42: kurze Mischung fuer die Karten-Ueberschrift
	var mix: Dictionary = tier.get("mix", { "common": 100 })
	var parts: Array = []
	for r in ["common", "rare", "epic"]:
		var pct: int = int(mix.get(r, 0))
		if pct > 0:
			parts.append("%d%% %s" % [pct, str(RARITY_NAMES.get(r, r))])
	return " \u00b7 ".join(parts)


func chest_price(tier_id: String) -> int: return _shopl_p().chest_price(tier_id)


func open_chest(tier_id: String) -> Dictionary:
	var tier: Dictionary = {}
	for c in CHESTS:
		if str(c["id"]) == tier_id:
			tier = c
	if tier.is_empty():
		return { "ok": false }
	var price := int(tier["price"])
	if gold < price:
		return { "ok": false, "reason": "zu wenig Gold" }
	gold -= price
	var res := _roll_chest(tier)
	if bool(res.get("ok", false)):
		res = _apply_chest_bonus(res)
	_save_profile()
	ui_manager.animate_gold(gold + price, gold)
	return res

func _apply_chest_bonus(res: Dictionary) -> Dictionary:
	# v1.52: Bonus je Seltenheit auf Gold/Edelsteine, direkt gebucht - die
	# Karte im UI zeigt nur noch an, was schon gutgeschrieben ist.
	var rar: String = str(res.get("rarity", ""))
	if not CHEST_RARITY_BONUS.has(rar):
		res["bonus"] = { "gold": 0, "gems": 0 }
		return res
	var b: Dictionary = CHEST_RARITY_BONUS[rar]
	var g: int = int(b["gold"])
	var m: int = int(b["gems"])
	gold += g
	gems += m
	res["bonus"] = { "gold": g, "gems": m }
	print("[CHEST][BONUS] rarity=%s gold=+%d gems=+%d gold_stand=%d gems_stand=%d" % [
		rar, g, m, gold, gems])
	return res


func _roll_chest(tier: Dictionary) -> Dictionary:
	# Runde 41: eine Kiste liefert MEHRERE Gegenstaende (Anzahl je Raritaet).
	# Vorher war es immer genau einer -> "die 3 teuren geben immer das Gleiche".
	var want_items: int = maxi(1, int(tier.get("items", 1)))
	var got: Array = []
	for _n in range(want_items):
		var one := _roll_one_chest_item(tier)
		if not bool(one.get("ok", false)):
			# nichts mehr zu vergeben -> Rest in Gold
			if got.is_empty():
				return one
			break
		got.append(one)
	if got.is_empty():
		return { "ok": false, "kind": "gold", "label": "Nichts Neues", "icon": "icon_coin" }
	# Haupt-Item = erstes Cosmetic, Rest = Boosts/sonstiges
	var main_item: Dictionary = got[0]
	for g in got:
		if str(g.get("kind", "")) in ["color", "rig", "hat", "map"]:
			main_item = g
			break
	var labels: Array = []
	for g in got:
		labels.append(str(g.get("label", "")))
	main_item["items"] = got
	main_item["label"] = " + ".join(labels)
	return main_item

func _roll_one_chest_item(tier: Dictionary) -> Dictionary:
	var pool := _chest_pool(tier)
	# Runde 42: Seltenheit IMMER ziehen (auch im "alles besessen"-Zweig),
	# damit "rar" ueberall definiert ist.
	var mix0: Dictionary = tier.get("mix", { "common": 100 })
	var rar: String = "common"
	var rsum0: int = 0
	for k0 in mix0.keys():
		rsum0 += int(mix0[k0])
	var rr0 := randi() % maxi(1, rsum0)
	for k0 in mix0.keys():
		rr0 -= int(mix0[k0])
		if rr0 < 0:
			rar = str(k0)
			break
	if pool.is_empty():
		# alles besessen -> Gold zurueck
		var fb := int(tier.get("fallback", 20))
		gold += fb
		return { "ok": true, "kind": "gold", "label": "%d Gold (alles besessen)" % fb, "rarity": rar, "icon": "icon_coin" }
	# Runde 42: "rar" ist oben schon gezogen -> jetzt ein passendes Cosmetic dazu.
	# Faellt kein Cosmetic der Seltenheit uebrig, greift der gewoehnliche Pool.
	# Cosmetics dieser Seltenheit suchen
	# Runde 42: die gezogene Seltenheit gilt fuer JEDES Ergebnis dieser Kiste
	var cands := _any_cosmetic_of_rarity(rar)
	if not cands.is_empty():
		var kind: String = str(cands[0])
		var lst: Array = cands[1]
		var pick_idx: int = int(lst[randi() % lst.size()])
		match kind:
			"color":
				_unlock_color(pick_idx)
				return { "ok": true, "kind": "color", "label": "FARBE " + str(TextureManager.COLOR_NAMES[pick_idx]), "icon": "player_c%d_h0" % pick_idx, "color": pick_idx, "rarity": rar }
			"hat":
				unlock_hat(pick_idx)
				return { "ok": true, "kind": "hat", "label": "HUT " + str(TextureManager.HAT_NAMES[pick_idx]), "icon": "player_c%d_h%d" % [0, pick_idx], "hat": pick_idx, "rarity": rar }
			"rig":
				unlock_rig(pick_idx)
				return { "ok": true, "kind": "rig", "label": "SKIN " + str(TextureManager.RIG_NAMES[pick_idx]), "icon": "player_rig%d" % pick_idx, "rig": pick_idx, "rarity": rar }
	# keine Cosmetics uebrig -> gewoehnlicher Pool (Boosts/Gold)
	var total := 0
	for e in pool:
		total += int(e[1])
	var r := randi() % maxi(1, total)
	var pick := str(pool[0][0])
	for e in pool:
		r -= int(e[1])
		if r < 0:
			pick = str(e[0])
			break
	match pick:
		"gold":
			var fb2 := int(tier["fallback"])
			gold += fb2
			return { "ok": true, "kind": "gold", "label": "%d Gold" % fb2, "icon": "icon_coin", "rarity": rar }
		"gems":
			var gg: int = 3 + (randi() % 6)
			gems += gg
			return { "ok": true, "kind": "gems", "label": "+%d DIAMANTEN" % gg, "rarity": rar, "icon": "icon_coin" }
		"color":
			var lc := _locked_colors()
			var ci := int(lc[randi() % lc.size()])
			_unlock_color(ci)
			return { "ok": true, "kind": "color", "label": "FARBE " + str(TextureManager.COLOR_NAMES[ci]), "icon": "player_c%d_h0" % ci, "color": ci }
		"rig":
			var lrg := _locked_rigs()
			if lrg.is_empty():
				return { "ok": false, "kind": "rig", "label": "SKIN", "icon": "player_rig1" }
			var rgi := int(lrg[randi() % lrg.size()])
			unlock_rig(rgi)
			return { "ok": true, "kind": "rig", "label": "SKIN " + str(TextureManager.RIG_NAMES[rgi]), "icon": "player_rig%d" % rgi, "rig": rgi }
		"hat_low":
			var lh := _locked_hats([2, 5])
			var hi := int(lh[randi() % lh.size()])
			unlock_hat(hi)
			return { "ok": true, "kind": "hat", "label": "HUT " + str(TextureManager.HAT_NAMES[hi]), "icon": "player_c0_h%d" % hi, "hat": hi }
		"hat_high":
			var lh2 := _locked_hats([3, 4])
			var hi2 := int(lh2[randi() % lh2.size()])
			unlock_hat(hi2)
			return { "ok": true, "kind": "hat", "label": "HUT " + str(TextureManager.HAT_NAMES[hi2]), "icon": "player_c0_h%d" % hi2, "hat": hi2 }
		"map":
			var lm := _locked_maps()
			var mid := str(lm[randi() % lm.size()])
			_unlock_map(mid)
			return { "ok": true, "kind": "map", "label": "KARTE " + str(map_data(mid)["name"]), "icon": str(map_data(mid)["icon"]), "map": mid }
	return { "ok": true, "kind": "gold", "label": "%d Gold" % int(tier["fallback"]), "rarity": rar, "icon": "icon_coin" }

func unlock_hat(i: int) -> void: _prof_p().unlock_hat(i)


# ---------------- Jahreszeiten (Runde 13, Option D Hybrid) ----------------
# Ein Planet startet in der gewaehlten Jahreszeit; im Run wandert sie per Score weiter.
const SEASONS := SeasonsModule.SEASONS
const SEASON_STEP := 1400.0        # Score pro Jahreszeiten-Wechsel im Run

var season_id: String = "spring"
var active_season: Dictionary = {}      # planet_id -> season_id (gewaehlt)
var season_unlocks: Dictionary = {}     # planet_id -> [season_id]
var season_mode: Dictionary = {}        # planet_id -> "fixed" | "cycle"

func seasons_enabled(planet: String = "") -> bool:
	# v1.48 (A3): Die ERDE bekommt die Jahreszeiten-Auswahl wie alle Planeten.
	# Die Klimazonen-Reise bleibt das BIOM (progressive=true) und ist davon
	# getrennt: Jahreszeit = Optik/Gegnerwerte, Biom = Kartengrund.
	var pid := planet if planet != "" else active_map
	return pid != ""

func season_ids() -> Array: return _seas_p().season_ids()

func season_data(sid: String = "") -> Dictionary: return _seas_p().season_data(sid)

func season_name(sid: String) -> String: return _seas_p().season_name(sid)

func planet_season(planet: String) -> String:
	if not active_season.has(planet):
		# Runde 38: die Elektro-Welt startet mit "sturm"
		active_season[planet] = "sturm" if planet == "volt" else "spring"
	return str(active_season[planet])

func volt_seasons() -> Array:
	# Runde 38: die vier kreativen Jahreszeiten der Elektro-Welt
	return ["sturm", "ueberlast", "blackout", "nebel"]

func season_display_name(planet: String, sid: String) -> String: return _seas_p().season_display_name(planet, sid)

func is_season_unlocked(planet: String, sid: String) -> bool:
	if not season_unlocks.has(planet):
		season_unlocks[planet] = ["spring"]
	return (season_unlocks[planet] as Array).has(sid)

func set_active_season(planet: String, sid: String) -> void:
	if not is_season_unlocked(planet, sid):
		return
	if planet == "volt" and not volt_seasons().has(sid):
		return
	active_season[planet] = sid
	_save_profile()
	ui_manager.refresh_maps_ui()

func season_gate_need(planet: String, sid: String) -> int: return _seas_p().season_gate_need(planet, sid)


func season_price(sid: String) -> int: return _seas_p().season_price(sid)


func season_price_for(planet: String, sid: String) -> int: return _seas_p().season_price_for(planet, sid)


func season_price_log() -> void: _seas_p().price_log()


func season_migrate() -> void: _seas_p().migrate_unlocks()


func buy_season(planet: String, sid: String) -> bool: return _seas_p().buy_season(planet, sid)


func _num_dots_local(v: int) -> String:
	# 2500 -> "2.500"
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if v < 0 else "") + out


func season_mode_of(planet: String) -> String: return _seas_p().season_mode_of(planet)


func set_season_mode(planet: String, mode: String) -> void:
	if mode != "fixed" and mode != "cycle":
		return
	season_mode[planet] = mode
	_save_profile()
	print("[SEASON][MODE] planet=%s modus=%s gespeichert" % [planet, mode])
	ui_manager.refresh_maps_ui()


func season_pool(planet: String) -> Array: return _seas_p().season_pool(planet)

func season_progress_text(planet: String) -> String: return _seas_p().season_progress_text(planet)

func _check_season_gates() -> void: _seas_p()._check_season_gates()


func _season_label(sid: String) -> String: return _seas_p()._season_label(sid)


func _update_season_hud() -> void:
	var pool: Array = season_pool(active_map)
	var nxt := ""
	if season_mode_of(active_map) == "cycle" and pool.size() >= 2:
		var i: int = pool.find(season_id)
		nxt = str(pool[(i + 1) % pool.size()])
	if ui_manager != null and ui_manager.has_method("update_season_hud"):
		var col: Color = season_data(season_id).get("color", Color(1, 1, 1))
		ui_manager.update_season_hud(_season_label(season_id), _season_label(nxt), col)


func _check_season() -> void: _seas_p()._check_season()

func get_loot_mult() -> float:
	return float(season_data().get("loot", 1.0))

func season_summary() -> String: return _seas_p().season_summary()

# ---------------- Karten- und Boost-Wirkung im Run ----------------
func get_monster_speed_mult() -> float:
	return float(map_data().get("speed", 1.0)) * float(season_data().get("speed", 1.0))

func get_monster_damage_mult() -> float:
	return float(map_data().get("damage", 1.0)) * float(season_data().get("damage", 1.0))

func get_ground_slow() -> float:
	return float(map_data().get("ground_slow", 1.0)) * float(season_data().get("ground_slow", 1.0))

func get_drift() -> float:
	return maxf(float(map_data().get("drift", 0.0)), float(season_data().get("drift", 0.0)))

func get_vegetation() -> float:
	var q: float = [0.60, 0.85, 1.0][clampi(quality, 0, 2)]
	return float(map_data().get("vegetation", 1.0)) * float(season_data().get("veg", 1.0)) * q

# ---------------- Kartenschalter (Runde 12): Meilenstein im Run ----------------
func _check_map_gates() -> void:
	for m in MAPS:
		var g: Dictionary = m.get("gate", {})
		if g.is_empty():
			continue
		var mid := str(m["id"])
		if is_map_unlocked(mid):
			continue
		var pre := str(g.get("prereq", ""))
		if pre != "" and not is_map_unlocked(pre):
			continue
		if str(g.get("type", "xp")) != "xp":
			continue
		if run_xp >= int(g.get("need", 0)):
			_unlock_map(mid)
			_save_profile()
			SoundManager.play("levelup")
			ui_manager.show_banner("NEUE KARTE: " + str(m["name"]), Color(0.60, 1.0, 0.80))
			ui_manager.refresh_maps_ui()

func _switch_need() -> int:
	# Naechster offener Schalter (Karte oder Jahreszeit) fuer den HUD-Balken
	for m in MAPS:
		var g: Dictionary = m.get("gate", {})
		if g.is_empty() or is_map_unlocked(str(m["id"])):
			continue
		var pre := str(g.get("prereq", ""))
		if pre != "" and not is_map_unlocked(pre):
			continue
		return int(g.get("need", 0))
	if seasons_enabled():
		for se in SEASONS:
			var sid := str(se["id"])
			if is_season_unlocked(active_map, sid):
				continue
			var n := season_gate_need(active_map, sid)
			if n > 0:
				return n
	return -1

func _switch_hint_text() -> String:
	var a := gate_progress_text()
	var b := season_progress_text(active_map) if seasons_enabled() else ""
	if a != "" and b != "":
		return a + "   ·   " + b
	return a if a != "" else b

func gate_progress_text() -> String:
	# Naechster noch gesperrter Schalter (fuer HUD/Karten-Seite)
	for m in MAPS:
		var g: Dictionary = m.get("gate", {})
		if g.is_empty() or is_map_unlocked(str(m["id"])):
			continue
		var pre := str(g.get("prereq", ""))
		if pre != "" and not is_map_unlocked(pre):
			continue
		return "%s: %d/%d XP" % [str(m["name"]), run_xp, int(g.get("need", 0))]
	return ""

func _load_profile() -> void: _prof_p()._load_profile()

# ---------------------------------------------------------------
# Runde 93: Glueckswalze (nur Gold, siehe SPEC_SLOT.md)
# ---------------------------------------------------------------
const SlotMachine = preload("res://scripts/slot_machine.gd")

# B5: einzige Versionsquelle fuer Menue, Log und Export-Preset
const APP_VERSION := "1.58"
const APP_BUILD := 58
# v1.43 (S6.5): Laufzeit-Messung fuers Geraet
var _perf_lauf_s: float = 0.0
var _perf_tick: float = 0.0
var slot_rng := RandomNumberGenerator.new()
var slot_rng_ready: bool = false
var slot_spins_total: int = 0
var slot_gold_won_total: int = 0

func is_protected(slot: int) -> bool:
	# B3: Im Co-op wird NICHT mehr die ganze Welt pausiert, wenn jemand Karten
	# waehlt. Stattdessen ist der Waehlende unverwundbar, bis er gewaehlt hat -
	# sonst stirbt er blind hinter dem Kartenfenster.
	if not (coop_host or coop_client):
		return false
	if int(slot) == int(my_slot) and in_upgrade:
		return true
	return bool(coop_busy.get(int(slot), false))


func _should_pause_for_cards() -> bool:
	# Einzelspieler pausiert weiter (alte UX). Im Co-op laeuft die Welt auf
	# beiden Geraeten weiter - der Host ist die Simulation, ein Pause dort
	# friert auch den Client ein (BUGLISTE B3).
	if NetManager.active and (coop_host or coop_client):
		return false
	return true


func _on_busy_received(slot: int, busy: bool) -> void:
	# B3: Client meldet "ich waehle gerade Karten" -> Host schuetzt ihn
	coop_busy[int(slot)] = busy
	print("[B3][BUSY] Slot %d busy=%s (Tabelle=%s)" % [slot, str(busy), str(coop_busy)])


func slot_odds() -> Array:
	# E3: Tabelle fuer die Walzen-UI (Symbol, 3x-Auszahlung, Chance)
	return SlotMachine.odds_table()


func slot_hit_rate() -> float:
	return SlotMachine.odds_hit_rate()


func slot_spin(bet: int) -> Dictionary:
	if not slot_rng_ready:
		slot_rng.randomize()
		slot_rng_ready = true
	var r: Dictionary = SlotMachine.spin(bet, gold, slot_rng)
	if bool(r.get("ok", false)):
		gold = int(r["gold_after"])
		slot_spins_total += 1
		slot_gold_won_total += int(r["win"])
		_save_profile()
	return r


func _save_profile() -> void: _prof_p()._save_profile()


# ============================================================
# v1.44 (C): Aufgaben-Modul
# ============================================================

var _chal: Challenges = null

func _chal_p() -> Challenges:
	if _chal == null:
		_chal = Challenges.new()
		_chal.host = self
	return _chal


func chal_defs() -> Array: return _chal_p().defs()

func chal_ensure() -> void: _chal_p().ensure()

func chal_state(id: String) -> String: return _chal_p().state_of(id)

func chal_progress(id: String) -> int: return _chal_p().progress_of(id)

func chal_set_state(id: String, state: String) -> void: _chal_p().set_state(id, state)

func chal_set_progress(id: String, n: int) -> void: _chal_p().set_progress(id, n)

func chal_claim(id: String) -> Dictionary: return _chal_p().claim(id)

func chal_counts() -> Dictionary: return _chal_p().counts()

func chal_reset() -> void: _chal_p().reset_all()


# ============================================================
# v1.45 (C): Aufgaben als echte Spielmodi
# ============================================================
const ChallengeRunScript = preload("res://scripts/core/challenge_run.gd")

var chal_run = null                 # ChallengeRunScript-Instanz des laufenden Runs
var chal_active: bool = false
var chal_id: String = ""
var chal_stufe: String = "normal"


func chal_start(id: String, stufe: String) -> void:
	# Startet eine Aufgabe als eigenen Run (RUNDEN-Modus, eigene Regel).
	if current_state != GameState.MENU and current_state != GameState.LOBBY:
		print("[CHAL][FEHLER] start_unmoeglich zustand=%d" % int(current_state))
		return
	if chal_run == null:
		chal_run = ChallengeRunScript.new()
	if not bool(chal_run.setup(id, stufe)):
		chal_run = null
		print("[CHAL][FEHLER] setup_fehlgeschlagen id=%s stufe=%s" % [id, stufe])
		return
	chal_active = true
	chal_id = id
	chal_stufe = stufe
	set_round_difficulty(stufe)
	set_game_mode(2)
	if ui_manager != null and ui_manager.has_method("_close_pages"):
		ui_manager.call("_close_pages")
	start_game(false, false)


func chal_stop() -> void:
	if chal_active and chal_run != null and not bool(chal_run.beendet):
		print("[CHAL][ABBRUCH] id=%s zustand=LAEUFT fortschritt=%d" % [chal_id, int(chal_run.fortschritt)])
		_chal_save_progress(int(chal_run.fortschritt), false, 0)
	chal_active = false
	chal_run = null


func chal_run_finished(gewonnen: bool, gems: int, fortschritt: int, runden_max: int, grund: String, id: String, stufe: String) -> void:
# Wird von ChallengeRun gerufen, wenn das Ziel erreicht oder der Run vorbei ist.
	var fortschritt_anzeige: int = mini(fortschritt, runden_max)
	if chal_run != null:
		fortschritt_anzeige = mini(int(chal_run.anzeige_wert()), int(chal_run.runden_max))
	print("[CHAL][ENDE] id=%s stufe=%s ziel=%s fortschritt=%d/%d diamanten=%d grund=%s" % [
		id, stufe, ("ja" if gewonnen else "nein"), fortschritt_anzeige, runden_max,
		(gems if gewonnen else 0), grund])
	chal_active = false
	if gewonnen:
		_chal_save_progress(fortschritt_anzeige, true, gems)
	else:
		_chal_save_progress(fortschritt_anzeige, false, 0)
	if ui_manager != null and ui_manager.has_method("show_challenge_result"):
		ui_manager.call("show_challenge_result", id, stufe, gewonnen, gems, fortschritt_anzeige, runden_max, grund)


func _chal_save_progress(fortschritt: int, gewonnen: bool, gems: int) -> void:
	# Zustand + Belohnung im Profil sichern. Die Belohnung gehoert zur STUFE,
	# in der gewonnen wurde (HART gibt mehr als LEICHT).
	if challenges == null or typeof(challenges) != TYPE_DICTIONARY:
		challenges = {}
	var e: Dictionary = challenges.get(chal_id, { "state": Challenges.LAEUFT, "progress": 0 })
	var vorher_state: String = str(e.get("state", Challenges.OFFEN))
	if gewonnen:
		# Schon belohnt -> bleibt BELOHNT (keine zweite Auszahlung), Regel C10.
		e["state"] = Challenges.BELOHNT if vorher_state == Challenges.BELOHNT else Challenges.ERLEDIGT
		if vorher_state != Challenges.BELOHNT:
			e["reward"] = gems
			e["stufe"] = chal_stufe
		e["progress"] = fortschritt
	elif str(e.get("state", Challenges.OFFEN)) != Challenges.ERLEDIGT and str(e.get("state", Challenges.OFFEN)) != Challenges.BELOHNT:
		e["state"] = Challenges.LAEUFT
		e["progress"] = maxi(int(e.get("progress", 0)), fortschritt)
	challenges[chal_id] = e
	_save_profile()
	if gewonnen:
		print("[CHAL][BELOHNUNG] id=%s stufe=%s +%d gems=%d erneut=false bereit=true" % [
			chal_id, chal_stufe, gems, int(gems)])


func chal_current() -> Dictionary:
	# Bequemer Zugriff fuer UI/Diag.
	if chal_run == null:
		return {}
	return {
		"id": chal_id, "stufe": chal_stufe, "aktiv": chal_active,
		"runden_max": int(chal_run.runden_max), "fortschritt": int(chal_run.fortschritt),
		"ziel_wert": int(chal_run.ziel_wert), "gems": int(chal_run.gems_reward),
		"boss": int(chal_run.boss_gezaehlt), "kisten": int(chal_run.kisten),
		"hud": str(chal_run.hud_text()), "beendet": bool(chal_run.beendet),
	}


func chal_regel(sperre: String) -> bool:
	if not chal_active or chal_run == null:
		return false
	return bool(chal_run.hat(sperre))


func chal_damage_taken(amount: int) -> void:
	# v1.46 (B2): Treffer-Zaehler fuer UNBERUEHRT.
	if not chal_active or chal_run == null or not is_instance_valid(chal_run):
		return
	chal_run.on_damage_taken(amount)


func set_muted(m: bool) -> void:
	SoundManager.set_muted(m)
	_save_profile()

func set_player_name(n: String) -> void:
	var clean := n.strip_edges().substr(0, 10)
	p_name = clean if clean != "" else "HELD"
	_save_profile()
	# v1.46 (H3): Name sofort im Menue und im Coop (Host/Client) bekannt.
	notify_profile_changed()
	print("[PROFILE][NAME] name=%s gespeichert=true coop_host=%s coop_client=%s" % [
		p_name, str(coop_host), str(coop_client)])

func set_profile_color(i: int) -> void:
	p_color = clampi(i, 0, 9)   # Runde 37: 10 Farben
	_apply_profile()
	_save_profile()

func unlock_rig(i: int) -> void: _prof_p().unlock_rig(i)

func set_profile_rig(i: int) -> void:
	if not unlocked_rigs.has(i):
		return
	p_rig = i
	_apply_profile()
	_save_profile()
	notify_profile_changed()

func set_profile_hat(i: int) -> void:
	if not unlocked_hats.has(i):
		return
	p_hat = i
	_apply_profile()
	_save_profile()

func _apply_profile() -> void:
	if is_instance_valid(player):
		player.call("apply_profile", p_color, p_hat, p_rig)


func skin_preview_texture(skin_idx: int, color_idx: int = -1) -> Texture2D:
	# Runde 42: Vorschau eines Skins in der gerade gewaehlten Farbe
	# Runde 47: der Coop-Block war toter Code NACH dem return
	var ci: int = p_color if color_idx < 0 else color_idx
	return TextureManager.get_skin_texture(ci, clampi(skin_idx, 0, TextureManager.RIG_NAMES.size() - 1))


func notify_profile_changed() -> void:
	# Runde 47: an Partner senden (vorher unerreichbarer toter Code)
	if coop_host:
		NetManager.h_send_profile(p_name, p_color, p_hat, p_rig)
	elif coop_client:
		NetManager.c_send_profile(p_name, p_color, p_hat, p_rig)

func _try_unlock_hat() -> void:
	var locked: Array = []
	for i in range(1, TextureManager.HAT_NAMES.size()):
		if not unlocked_hats.has(i):
			locked.append(i)
	if locked.is_empty():
		return
	var pick: int = int(locked[randi() % locked.size()])
	unlocked_hats.append(pick)
	_save_profile()
	ui_manager.show_banner("NEUER HUT: " + str(TextureManager.HAT_NAMES[pick]) + "!", Color(0.95, 0.55, 1.0))
	ui_manager.refresh_hat_buttons(unlocked_hats, p_hat)
const TYPE_BOSS := 7  # Index im MonsterType-Enum

const UPGRADES := UpgradesModule.UPGRADES

# Game-Einstellungen (120x80 Kacheln = 3840x2560 px, automatisch generiert pro Run)
const MAP_COLS: int = 120
const MAP_ROWS: int = 80
const TILE_SIZE: int = 32
const NUM_CHESTS: int = 22
const NUM_TREES: int = 110
const NUM_ROCKS: int = 70
const MONSTER_SPAWN_INTERVAL: float = 30.0
const FIRST_WAVE_DELAY: float = 5.0

# Node-Referenzen
@onready var ysort = $YSort
@onready var monster_container = $YSort/MonsterContainer
@onready var chest_container = $YSort/ChestContainer
@onready var item_container = $YSort/ItemContainer
@onready var camera = $Camera2D
@onready var map_generator = $YSort/MapGenerator
@onready var monster_spawner = $MonsterSpawner
@onready var ui_manager = $CanvasLayer/UIManager

var player: Node2D = null
var debug_panel: CanvasLayer = null
var debug_open: bool = false
var player2: Node2D = null       # Duo-Modus (roter Held)
var duo_mode: bool = false

# Combo-Multiplikator
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW := 3.0

# Korruptionszonen
var zones: Array = []
const NUM_ZONES := 3
const ZONE_SCENE = preload("res://scripts/systems/corruption_zone.gd")

# LAN-Multiplayer (Phase 1: eigene Welt + sichtbarer Partner)
var lan_mode: bool = false
var partner_node: Node2D = null
var partner_target: Vector2 = Vector2.ZERO
var partner_velocity: Vector2 = Vector2.ZERO
var partner_pred_time: float = 0.0
var _net_acc: float = 0.0
var _monster_cache: Array = []
var monster_ai_script: Object = null      # Runde 34: statische Helfer (Geist-Textur)
var _arrow_tick: float = 0.0      # Runde 33: eigene Monster-Liste (kein get_nodes_in_group pro Snapshot)
var _net_wave_t: float = 0.0
# Runde 50: Zaehler fuer die LAN-Diagnose (Snapshots pro Sekunde)
var _t_diag_mobs: int = 0
var _t_diag_pl: int = 0
var _t_diag_ghost: int = 0
var _t_diag_world: int = 0
var _downed_net_t: Dictionary = {}

# Szenen werden per load() geladen (nicht preload, da sie per create_scenes.gd erstellt werden)
var player_scene: PackedScene = null
var monster_scene: PackedScene = null
var chest_scene: PackedScene = null
var item_scene: PackedScene = null
var projectile_scene: PackedScene = null

func _input(event: InputEvent) -> void:
	# Runde 60: F9 oeffnet das Debug-Fenster. Der fruehere Freischalt-Trick
	# steckt jetzt als Knopf im Fenster (debug_unlock_all).
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		if debug_panel != null and is_instance_valid(debug_panel):
			debug_panel.call("toggle")
			get_viewport().set_input_as_handled()


func debug_toggle() -> void:
	# Geheimer Debug-Modus (7x auf die Versionszeile tippen)
	if debug_panel == null or not is_instance_valid(debug_panel):
		print("[DEBUG] Fenster existiert noch nicht - wird erzeugt")
		debug_unlock_all()
		return
	debug_panel.call("toggle")
	print("[DEBUG] Fenster umgeschaltet (open=%s)" % str(debug_open))


func debug_unlock_all() -> void:
	gold += 99999
	for m in MAPS:
		_unlock_map(str(m["id"]))
	for i in range(TextureManager.COLOR_NAMES.size()):
		_unlock_color(i)
	for i in range(TextureManager.HAT_NAMES.size()):
		unlock_hat(i)
	# v1.39 D6: Skins fehlten hier komplett ("ALLE SKINS FREISCHALTEN" tat nichts)
	for i in range(TextureManager.RIG_NAMES.size()):
		unlock_rig(i)
	for pid in ["mars", "jungle"]:
		season_unlocks[pid] = ["spring", "summer", "autumn", "winter"]
	_save_profile()
	var rigs_n: int = 0
	for i in range(TextureManager.RIG_NAMES.size()):
		if unlocked_rigs.has(i):
			rigs_n += 1
	var hats_n: int = 0
	for i in range(TextureManager.HAT_NAMES.size()):
		if unlocked_hats.has(i):
			hats_n += 1
	var col_n: int = 0
	for i in range(TextureManager.COLOR_NAMES.size()):
		if unlocked_colors.has(i):
			col_n += 1
	print("[DEBUG][UNLOCK] rigs=%d/%d huete=%d/%d farben=%d/%d" % [
		rigs_n, TextureManager.RIG_NAMES.size(), hats_n, TextureManager.HAT_NAMES.size(),
		col_n, TextureManager.COLOR_NAMES.size()])
	ui_manager.set_start_gold(gold)
	ui_manager.refresh_shop_ui()
	ui_manager.refresh_maps_ui()
	ui_manager.refresh_profile_ui()
	SoundManager.play("levelup")
	ui_manager.show_banner("DEBUG: ALLES FREIGESCHALTET", Color(1.0, 0.85, 0.3))
	print("[DEBUG] Alles freigeschaltet (gold=%d)" % gold)

func _lan_diag_hook() -> void:
	var a = load("res://scripts/tools/lan_diag_tmp.gd").new()
	add_child(a)
	a.start(self)


# ============================================================
# v1.43 (S6.1/S6.2) — Ladebildschirm mit echtem Fortschritt
# ============================================================
var _boot_layer: CanvasLayer = null
var _boot_bar: ProgressBar = null
var _boot_label: Label = null
var _boot_t0: int = 0


func _boot_show() -> void:
	# v1.45 (L): EIN Ladebildschirm fuer App-Start und Run-Start. Vorher baute
	# der Boot eine eigene Text-Flaeche (Titel + Balken ohne Grafik) - jetzt
	# benutzt er die Flaeche des UI-Managers (Burst, Titel mit Kontur, Panel,
	# Held) und nur der Balken/Status kommt aus dem Boot.
	_boot_t0 = Time.get_ticks_msec()
	var ui = get_node_or_null("CanvasLayer/UIManager")
	if ui != null and ui.has_method("build_boot_screen"):
		ui.call("build_boot_screen")
		print("[BOOT][UI] flaeche=geteilt boot=true balken=(720,28) quelle=ui_manager._build_load_screen")
		print("[BUILD] icon=icon146c_6.png quelle=res://icon.png px=1024 version=%s build=%d" % [APP_VERSION, APP_BUILD])
		return
	# Rueckfall (kein UI-Manager): schlichte Text-Flaeche, damit der Boot nie
	# ohne Anzeige laeuft.
	_boot_layer = CanvasLayer.new()
	_boot_layer.name = "BootLayer"
	_boot_layer.layer = 250
	add_child(_boot_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.11, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boot_layer.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boot_layer.add_child(center)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	center.add_child(col)
	var t := Label.new()
	t.text = "COMIC SHOOTER"
	t.add_theme_font_size_override("font_size", 64)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	t.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	_boot_bar = ProgressBar.new()
	_boot_bar.name = "BootBar"
	_boot_bar.max_value = 100.0
	_boot_bar.show_percentage = false
	_boot_bar.custom_minimum_size = Vector2(720, 28)
	col.add_child(_boot_bar)
	_boot_label = Label.new()
	_boot_label.text = "Lade ..."
	_boot_label.add_theme_font_size_override("font_size", 24)
	_boot_label.add_theme_color_override("font_color", Color(0.86, 0.90, 0.94))
	_boot_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_boot_label)
	print("[BOOT][UI] flaeche=eigene boot=true (kein UI-Manager)")


func _boot_hide() -> void:
	var ui = get_node_or_null("CanvasLayer/UIManager")
	if _boot_layer == null and ui != null and ui.has_method("hide_boot_screen"):
		ui.call("hide_boot_screen")
		print("[LOAD][FADE] dauer=0.25 quelle=boot geteilt=true")
		_boot_bar = null
		_boot_label = null
		return
	if _boot_layer != null and is_instance_valid(_boot_layer):
		_boot_layer.queue_free()
	_boot_layer = null
	_boot_bar = null
	_boot_label = null


func _boot_set(frac: float, txt: String) -> void:
	if _boot_bar != null:
		_boot_bar.value = clampf(frac, 0.0, 1.0) * 100.0
	if _boot_label != null:
		_boot_label.text = txt
	var ui = get_node_or_null("CanvasLayer/UIManager")
	if ui != null and ui.has_method("boot_progress"):
		ui.call("boot_progress", frac, txt)


# Arbeitet Texturen und Musik Haeppchen fuer Haeppchen ab (je Frame eins).
func _boot_all() -> Dictionary:
	var total: int = SoundManager.sfx_remaining() + TextureManager.boot_remaining() + SoundManager.music_remaining() + 2
	var done: int = 0
	var haeppchen: int = 0
	var max_block: int = 0
	var max_name: String = ""
	# --- SFX-Bank ---
	while not SoundManager.sfx_done:
		var ts: int = Time.get_ticks_msec()
		var fs: bool = SoundManager.sfx_next()
		var dts: int = Time.get_ticks_msec() - ts
		if dts > max_block:
			max_block = dts
			max_name = "sfx"
		haeppchen += 1
		done += 1
		_boot_set(float(done) / float(maxi(1, total)), "Klaenge %d/%d" % [done, total - 2])
		if fs:
			break
		await get_tree().process_frame
	# --- Texturen ---
	var tex_total: int = total - SoundManager.music_remaining() - 2
	while not TextureManager.boot_done:
		var t0: int = Time.get_ticks_msec()
		var fertig: bool = TextureManager.boot_next()
		var dt: int = Time.get_ticks_msec() - t0
		if dt > max_block:
			max_block = dt
			max_name = "tex"
		haeppchen += 1
		done += 1
		_boot_set(float(done) / float(maxi(1, total)), "Texturen %d/%d" % [done, tex_total])
		if fertig:
			break
		await get_tree().process_frame
	# --- Musik ---
	while not SoundManager.music_done:
		var t1: int = Time.get_ticks_msec()
		var fertig2: bool = SoundManager.music_next()
		var dt2: int = Time.get_ticks_msec() - t1
		if dt2 > max_block:
			max_block = dt2
			max_name = "musik"
		haeppchen += 1
		done += 1
		_boot_set(float(done) / float(maxi(1, total)), "Musik %d/%d" % [done, total - 2])
		if fertig2:
			break
		await get_tree().process_frame
	_boot_set(0.99, "Oberflaeche ...")
	await get_tree().process_frame
	print("[BOOT] haeppchen=%d max_block_ms=%d (grösster Block: %s) bis_hier_ms=%d" % [
		haeppchen, max_block, max_name, Time.get_ticks_msec() - _boot_t0])
	return { "haeppchen": haeppchen, "max_block_ms": max_block }


func _ready():
	# Runde 50: Der GM muss bei get_tree().paused=true WEITERLAUFEN, damit
	# der LAN-Sync nicht stehen bleibt (Upgrade-Fenster des Hosts).
	# Kinder erben sonst ALWAYS -> Spielwelt explizit auf PAUSABLE setzen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	ysort.process_mode = Node.PROCESS_MODE_PAUSABLE
	camera.process_mode = Node.PROCESS_MODE_PAUSABLE
	monster_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	print("[LAN][BOOT] process_mode gesetzt (GM=ALWAYS, Welt=PAUSABLE)")
	# Runde 137 (P2): Boot-Phasen messen - der eigentliche Startkosten-Fresser
	var _bt: int = Time.get_ticks_msec()
	print("[BOOT][0] _ready start ms=%d tex_keys=%d" % [_bt, TextureManager.textures.size()])
	# v1.43 (S6.1/S6.2): Erst der Ladebildschirm mit Fortschritt, dann die
	# schwere Arbeit in Haeppchen. Vorher blockierte der Start mehrere Sekunden
	# am Stueck - fuer den Spieler sah das wie ein Absturz aus.
	_boot_show()
	await _boot_all()
	_boot_hide()
	print("[BOOT][0b] haeppchen fertig ms=%d" % (Time.get_ticks_msec() - _bt))
	# v1.43 (S6.2): Die Oberflaeche wird erst jetzt gebaut - sie braucht alle
	# Starttexturen. Vorher lief das in ui_manager._ready und blockierte mit.
	ui_manager.call("build_ui")
	print("[BOOT][0c] ui gebaut ms=%d" % (Time.get_ticks_msec() - _bt))
	if OS.get_environment("COMIC_LANTEST") != "":
		_lan_diag_hook()
	_load_high_score()
	_load_profile()
	print("[SHOP][BOOST-ENTFERNT] eintraege=7 quellen=3 grund=v148_keine_run_boosts")
	print("[BOOT][1] profil+highscore ms=%d" % (Time.get_ticks_msec() - _bt))
	_load_scenes()
	print("[BOOT][2] szenen geladen ms=%d" % (Time.get_ticks_msec() - _bt))
	ui_manager.register_references(self, null)
	# Runde 60: Debug-Fenster (F9) - Charakter-Vorschau, Weltwechsel, Freischalten
	debug_panel = load("res://scripts/debug_panel.gd").new()
	add_child(debug_panel)
	debug_panel.call("setup", self)
	print("[BOOT][3] debug_panel ms=%d" % (Time.get_ticks_msec() - _bt))
	ui_manager.connect("upgrade_chosen", Callable(self, "_on_upgrade_chosen"))
	# Runde 136 (H1): Tipp auf den Toast oeffnet erst die Karten
	ui_manager.connect("upgrade_toast_tapped", Callable(self, "_on_upgrade_toast_tapped"))
	_setup_initial_state()
	_setup_post_process()
	ui_manager.set_fps_label(debug_fps)
	# LAN-/Co-op-Signale (muss in _ready passieren!)
	NetManager.run_start_signal.connect(_on_lan_run_start)
	NetManager.spectator_received.connect(_on_net_spectator)
	NetManager.partner_state.connect(_on_partner_state)
	NetManager.partner_left.connect(_on_partner_gone)
	NetManager.peer_joined.connect(_on_peer_joined_coop)
	NetManager.coop_init_received.connect(_on_coop_init)
	NetManager.hit_requested.connect(_on_net_hit_request)
	NetManager.wave_state_received.connect(_on_net_wave_state)
	NetManager.chest_open_request_received.connect(_on_chest_open_request)
	NetManager.world_synced.connect(_on_world_synced)
	NetManager.my_player_synced.connect(_on_my_player_synced)
	NetManager.mobs_synced.connect(_on_mobs_synced)
	NetManager.downed_state_received.connect(_on_downed_state)
	NetManager.revive_request_received.connect(_on_revive_request)
	NetManager.busy_received.connect(_on_busy_received)
	ui_manager.revive_hold_changed.connect(_on_revive_hold)
	NetManager.items_synced.connect(_on_items_synced)
	NetManager.shot_synced.connect(_on_shot_synced)
	NetManager.coop_game_over.connect(_on_coop_game_over)
	NetManager.remote_input_received.connect(_on_remote_input)
	NetManager.coop_profile_received.connect(_on_coop_profile)
	NetManager.lobby_changed.connect(_on_lobby_changed)
	NetManager.peer_left.connect(_on_peer_left)
	NetManager.players_synced.connect(_on_players_synced)
	NetManager.shop_state_received.connect(_on_net_shop_state)
	NetManager.shop_buy_requested.connect(_on_net_shop_buy)
	NetManager.shop_offers_received.connect(_on_net_shop_offers)
	NetManager.shop_ready_received.connect(_on_net_shop_ready)
	NetManager.ping_received.connect(_on_net_ping)
	# Runde 49: LAN-Sync fuer Upgrade-Fenster, Upgrades, Game-Over, Revive
	NetManager.upgrade_options_received.connect(_on_net_upgrade_options)
	NetManager.upgrade_choice_received.connect(_on_net_upgrade_choice)
	NetManager.upgrade_applied_received.connect(_on_net_upgrade_applied)
	NetManager.game_over_data.connect(_on_net_game_over_data)
	NetManager.downed_state_received.connect(_on_net_downed_state)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_net_connected)

func _process(delta: float) -> void:
	# v1.43 (S6.5): Laufzeit-Beleg auf dem Geraet - alle 30 s eine Zeile
	if current_state == GameState.PLAYING:
		_perf_lauf_s += delta
		_perf_tick += delta
		if _perf_tick >= 10.0:
			_perf_tick = 0.0
			print("[PERF][GERAET] fps=%d lauf_s=%.0f abgestuerzt=false" % [
				Engine.get_frames_per_second(), _perf_lauf_s])
	if current_state != GameState.PLAYING:
		return
	# Runde 50: Bei pausiertem Spiel (Upgrade-Fenster) laeuft NUR der
	# Netzwerk-Sync weiter - die Simulation wird uebersprungen.
	# Vorher stoppte _process komplett, der Client bekam keine Snapshots
	# mehr und die Welt fror ein (FPS blieben stabil).
	if get_tree().paused:
		# Runde 52: Der Shop pausiert die Welt. Timer und Wellen-Zustand
		# muessen trotzdem weiterlaufen - sonst schliesst der Shop nie
		# von selbst und der Client erfaehrt nie, dass er offen ist.
		if in_shop and current_state == GameState.PLAYING:
			shop_time -= delta
			ui_manager.update_wave_label(wave, coins, true, shop_time, wave_remaining)
			if coop_host:
				_net_wave_t += delta
				if _net_wave_t >= 0.25:
					_net_wave_t = 0.0
					NetManager.h_send_wave_state(wave, in_shop, shop_time, wave_remaining, coins, game_mode)
					_send_shop_state()
			if shop_time <= 0.0:
				_sdiag("TIMEOUT", "Shop-Zeit abgelaufen -> naechste Welle")
				_next_wave(true)
				return
		if coop_client:
			_coop_client_tick(delta)
		elif coop_host:
			_coop_host_tick(delta)
		if lan_mode:
			_ldiag_th("PAUSED", 1.0, "Spiel pausiert - nur Sync laeuft, Welt steht")
		return
	_arrow_tick += 1.0
	if _arrow_tick >= 0.2:           # Runde 33: 5x/s statt pro Frame
		_arrow_tick = 0.0
		_tick_force_fields(delta)      # Runde 38: wandernde Kraftfelder
	if lan_mode and not downed.is_empty():
			_tick_downed(delta)      # Runde 34: Aufweck-/Game-Over-Timer
	_update_target_arrow()   # Runde 31: Pfeil zum letzten Wellen-Monster
	# Kamera folgt Midpoint der Spieler (V4-Fix bleibt: Camera nicht unter Player)
	# Kamera: Client folgt dem eigenen Helden, Host/Duo der Gruppe
	# Runde 51: Als Zuschauer folgt die Kamera dem ueberlebenden Partner
	var cam_tgt: Node2D = null
	if bool(spectator.get(int(my_slot), false)):
		var al: Array = _alive_slots()
		if not al.is_empty():
			cam_tgt = players.get(int(al[0]), null)
	if cam_tgt != null and is_instance_valid(cam_tgt):
		camera.global_position = cam_tgt.global_position
	elif coop_client:
		if is_instance_valid(player):
			camera.global_position = player.global_position
	elif (duo_mode or coop_host) and player_nodes().size() > 1:
		camera.global_position = player_centroid()
	elif is_instance_valid(player):
		camera.global_position = player.global_position

	# --- Co-op: Host simuliert + sendet, Client rendert + sendet Input ---
	if coop_client:
		_coop_client_tick(delta)
		return
	if coop_host:
		_coop_host_tick(delta)

	# Combo-Fenster
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			ui_manager.update_combo(0, 1.0)
	# --- LAN: Partnerposition interpolieren + eigenen Zustand senden ---
	# Runde 50: Im Co-op-Modus macht das h_send_players (15 Hz, alle Slots).
	# Der alte Einzelpartner-Sync lief zusaetzlich mit 15 Hz -> doppelte
	# Bandbreite. Nur noch im Legacy-LAN (ohne coop) aktiv.
	if lan_mode and not coop_host and not coop_client:
		if is_instance_valid(partner_node):
			# Runde 49: Zeitbasierte Interpolation statt fester Rate
			# (framerate-unabhaengig) + Extrapolation aus der letzten
			# Geschwindigkeit, damit der Partner bei Paketverlust nicht
			# stehen bleibt. Das war die Ursache des Rubber-Banding.
			var w: float = 1.0 - exp(-18.0 * delta)
			var goal: Vector2 = partner_target + partner_velocity * partner_pred_time
			partner_node.position = partner_node.position.lerp(goal, clampf(w, 0.0, 1.0))
			partner_pred_time = maxf(0.0, partner_pred_time - delta)
		if is_instance_valid(player) and NetManager.has_partner():
			_net_acc += delta
			if _net_acc >= 1.0 / NetManager.SEND_HZ:
				_net_acc = 0.0
				NetManager.send_partner_state(
					player.global_position,
					player.call("get_health"),
					player.call("get_max_health"),
					player.call("get_weapon_name"),
					player.call("get_aim_degrees"),
					player.call("get_shield"))
		if NetManager.is_host and current_state == GameState.PLAYING:
			_net_wave_t += delta
			if _net_wave_t >= 0.25:
				_net_wave_t = 0.0
				NetManager.h_send_wave_state(wave, in_shop, shop_time, wave_remaining, coins, game_mode)
				_send_shop_state()      # Runde 33: eigene Muenzen/Level des Clients

	# --- Buffs (Freeze / Rapid) ---
	if freeze_time > 0.0:
		freeze_time = maxf(0.0, freeze_time - delta)
	if rapid_time > 0.0:
		rapid_time = maxf(0.0, rapid_time - delta)
	if gold_time > 0.0:
		gold_time = maxf(0.0, gold_time - delta)
	var buff_mult := RAPID_COOLDOWN_MULT if rapid_time > 0.0 else 1.0
	for p in player_nodes():
		p.buff_cooldown_mult = buff_mult
	ui_manager.update_buffs(rapid_time, freeze_time, gold_time)

	# --- RUNDEN-Modus (v1.40) ---
	if game_mode == 2:
		if not get_tree().paused:
			_rm().process_round(delta)

	# --- Wellen-Modus (Punkt 6) ---
	if game_mode == 1:
		if in_shop:
			shop_time -= delta
			ui_manager.update_wave_label(wave, coins, true, shop_time, wave_remaining)
			if shop_time <= 0.0:
				_next_wave(true)
		elif wave_active:
			# v1.56 (Spec K2/A3): Saegezahn - Anlauf/Peak/Erholung, Boss-Telegraph,
			# gestaffelter Nachschub. Die Welle ist erst leer, wenn AUCH der
			# Spawn-Vorrat aufgebraucht ist (sonst oeffnet der Shop zu frueh).
			_waves_p().stage_tick(delta)
			var offen: int = int(_waves_p().offen())
			# v1.56b (Bug 4): Watchdog - wenn 12 s lang nichts mehr kommt, steht
			# der Modus. Dann Zustand ins Log (Beleg statt Vermutung).
			# Watchdog nur fuer den echten Standfall: nichts auf dem Feld,
			# aber die Welle gilt als offen (25 s). Ein einzelner Gegner, den der
			# Spieler gerade jagt, ist kein Standfall.
			var akt_feld: int = get_tree().get_nodes_in_group("monsters").size()
			if (wave_remaining > 0 or offen > 0) and akt_feld == 0:
				_wave_watch_t += delta
				if _wave_watch_t > 25.0:
					_wave_watch_t = 0.0
					print("[WAVE][WATCHDOG] welle=%d rest=%d offen=%d feld=%d phase=%s phase_left=%.1f shop=%s paused=%s" % [
						wave, wave_remaining, offen, akt_feld, str(_waves_p().phase),
						float(_waves_p().phase_left), str(in_shop), str(get_tree().paused)])
			else:
				_wave_watch_t = 0.0
			if wave_remaining <= 0 and offen <= 0:
				if not _shop_delay_active:
					_shop_delay_active = true
					_shop_delay = 6.0
					_waves_p()._clear_slow()
					print("[BAL][ERHOLUNG] modus=wellen welle=%d art=vor_shop spawn=0 gegner_aktiv=0 dauer=6.0" % wave)
				else:
					_shop_delay -= delta
					if _shop_delay <= 0.0:
						_shop_delay_active = false
						print("[WAVE] Welle %d geraeumt (level_ups=%d, benoetigt war %d) -> Shop" % [
							wave, _level_ups_gained(), WAVE_LEVEL_UPS])
						_open_shop()
		elif not wave_active and wave == 0:
			_start_wave()

	# --- Zufalls-Events (Monstersturm, Elitewelle, Lootregen, Froststurm, Goldrausch) ---
	event_timer -= delta
	if event_timer <= 0.0:
		event_timer = randf_range(45.0, 75.0)
		_trigger_random_event()

	# Boss-Regel (G3): nur im Endlos-Modus ueber Zeit, sonst kommen Bosse in Welle 5/10/15...
	# Runde 26: Bossbar immer ausblenden, wenn der Boss nicht mehr existiert
	# Runde 53: Boss-Tod wird am VERSCHWINDEN des Knotens erkannt, nicht
	# ueber einen Timer. Vorher zeigte der Timer 60 s lang "BOSS BESIEGT!",
	# auch wenn nie ein Boss da war.
	# v1.56 (Spec K4): Boss-Phase 2 bei 60 % HP - 1 s unverwundbar, Musterwechsel
	if _boss_active and is_instance_valid(current_boss) and not current_boss.is_queued_for_deletion():
		var hp_now: int = int(current_boss.get("current_health"))
		var hp_max: int = maxi(1, int(current_boss.get("start_hp")))
		if int(current_boss.get_meta("bal_phase", 1)) == 1 and float(hp_now) / float(hp_max) <= 0.60:
			current_boss.set_meta("bal_phase", 2)
			current_boss.set("bal_invuln_until_ms", Time.get_ticks_msec() + 1000)
			current_boss.set("boss_state", 2)
			current_boss.set("boss_timer", 0.0)
			_bdiag("PHASE", "Boss phase=2 hp=%d/%d (60%% erreicht) unverwundbar=1.0s" % [hp_now, hp_max])
			print("[BAL][BOSS] phase=2 schwelle=0.60 hp=%d/%d unverwundbar=1.0 muster=wechsel" % [hp_now, hp_max])
			ui_manager.show_banner("BOSS · PHASE 2", Color(1.0, 0.35, 0.35))
	if _boss_active and (not is_instance_valid(current_boss) or current_boss.is_queued_for_deletion()):
		var dead_type: String = str(current_boss.get("type")) if is_instance_valid(current_boss) else "?"
		var dead_hp: int = int(current_boss.get("current_health")) if is_instance_valid(current_boss) else -1
		_boss_active = false
		current_boss = null
		ui_manager.hide_boss_bar()
		_boss_defeats += 1
		if chal_active and chal_run != null:
			chal_run.on_boss_killed()
		_bdiag("DEFEAT", "Boss besiegt (#%d type=%s hp=%d map=%s) -> Banner" % [
			_boss_defeats, _boss_last_type, dead_hp, active_map])
		ui_manager.show_banner("BOSS BESIEGT!", Color(0.45, 1.0, 0.55))
		# v1.42 (P4.4): nach dem Boss zurueck zum Rundentrack
		var rn_b: int = _round_no_now()
		SoundManager.play_music_for_round(maxi(1, rn_b), false)
		# v1.46 (E3): Rueckkehr in den Rundentrack, ohne Aussetzer.
		print("[MUSIK][BOSS] ende=dauer%.1fs zurueck=game_%d" % [
			SoundManager.BOSS_FADE_OUT, ((maxi(1, rn_b) - 1) % 4) + 1])
		_boss_timer = 0.0
	if game_mode == 0:
		# v1.56 (Spec K4/B1): Bosse kommen AUSSCHLIESSLICH aus dem Saegezahn-Spawner
		# (Balance-Kadenz, 2 s Telegraph, keine Adds). Der alte 120-s-Zeittimer
		# setzte einen Boss "aus dem Off" mitten in den Peak - das ist entfernt.
		_boss_timer += delta
		if _boss_timer >= BOSS_INTERVAL:
			_boss_timer = 0.0

func is_corrupted(p: Vector2) -> bool:
	for z in zones:
		if is_instance_valid(z) and z.contains(p):
			return true
	return false

func _load_scenes() -> void:
	player_scene = load("res://scenes/Player.tscn") as PackedScene
	monster_scene = load("res://scenes/Monster.tscn") as PackedScene
	monster_ai_script = load("res://scripts/monster_ai.gd")   # Runde 34: statische Helfer
	chest_scene = load("res://scenes/Chest.tscn") as PackedScene
	item_scene = load("res://scenes/Item.tscn") as PackedScene
	projectile_scene = load("res://scenes/Projectile.tscn") as PackedScene

func _setup_initial_state():
	current_state = GameState.MENU
	score = 0
	ui_manager.show_start_screen()
	ui_manager.set_start_score(high_score)
	ui_manager.set_start_gold(gold)
	ui_manager.set_mode_label(game_mode)

func start_game_deferred() -> void:
	# v1.42 (P14): erst die Modus-Vorschau zeigen, dann die Welt bauen.
	if ui_manager != null and ui_manager.has_method("show_load_for_run"):
		ui_manager.call("show_load_for_run")
	await get_tree().process_frame
	await get_tree().process_frame
	start_game(false, false)


func start_game(duo: bool = false, lan: bool = false):
	if current_state != GameState.MENU and current_state != GameState.LOBBY:
		return
	# Runde 49: Action-Musik fuer den Run
	SoundManager.play_music_for_round(1, false)
	SoundManager.set_music_volume(music_volume)
	duo_mode = duo
	lan_mode = lan
	# Runde 53: Zuschauer-Status eines alten Runs darf nicht ueberleben
	_clear_run()
	spectator.clear()
	downed.clear()
	downed_time.clear()
	revive_progress.clear()
	_boss_defeats = 0
	current_boss = null
	_boss_active = false
	# Co-op-Rolle: Host simuliert die gemeinsame Welt
	coop_client = false
	coop_host = lan and NetManager.is_host
	# Runde 137 (P2.3): die zweite Texturgruppe JETZT zeichnen (waehrend der
	# Ladebildschirm laeuft), damit im ersten Spielbild keine 1-3 s Pause entsteht.
	TextureManager.call("_ensure_run")
	if coop_host:
		NetManager.coop_role = 1
		_net_seed = randi()
		seed(_net_seed)          # gleiche Karte auf beiden Seiten
		_next_mid = 1
		_next_iid = 1
	current_state = GameState.PLAYING
	score = 0
	player_health = MAX_HEALTH
	combo_count = 0
	combo_timer = 0.0
	xp = 0
	# Runde 49c: 25 -> 60. Vorher brauchte man nur 1-2 Kills
	# pro Level (Monster geben 10-30 Punkte) - zu oft ein Upgrade.
	xp_needed = maxi(20, int(round(60.0 * xp_multiplier())))
	level = 1
	pending_upgrades = 0
	upg_stacks.clear()
	run_xp = 0
	if not season_unlocks.has(active_map):
		season_unlocks[active_map] = ["spring"]
	season_id = planet_season(active_map)
	# Runde 136 (I2): Modus + Pool beim Run-Start protokollieren und im HUD zeigen
	print("[SEASON][MODE] planet=%s modus=%s pool=%s jahreszeit=%s" % [
		active_map, season_mode_of(active_map), str(season_pool(active_map)), season_id])
	print("[MAP][SEASON] planet=%s season=%s modus=%s" % [
		active_map, season_id, season_mode_of(active_map)])
	_update_season_hud()
	_boss_timer = 0.0
	_boss_count = 0
	current_boss = null
	freeze_time = 0.0
	rapid_time = 0.0
	biome_id = str(map_data()["biome"])
	biome_changes = 0
	map_generator.set_biome(biome_id)
	# v1.42 (P9): Biom beim Start, Wechselplan und Trennung von der Jahreszeit
	print("[BIOME][START] map=%s biome=%s" % [active_map, biome_id])
	var _plan_txt: String = _biome_plan_text()
	if _plan_txt != "":
		print("[BIOME][PLAN] map=%s %s" % [active_map, _plan_txt])
	print("[BIOME][TRENNUNG] season=%s biome=%s unveraendert=true" % [season_id, biome_id])
	print("[MAP][WAHL] aktiv=%s modus=%s" % [active_map, season_mode_of(active_map)])
	event_timer = randf_range(40.0, 60.0)
	gold_time = 0.0
	_apply_quality()

	# Karte generieren
	map_generator.generate_map(MAP_COLS, MAP_ROWS, TILE_SIZE, _net_seed)
	map_generator.set_season(season_id)
	map_generator.place_planet_obstacles(get_vegetation())

	# Kisten platzieren - im RUNDEN-Modus gibt es KEINE Kisten auf der Karte (v1.40)
	var kisten_im_run: bool = (game_mode == 2 and chal_active and chal_run != null and str(chal_run.id) == "sammler")
	if game_mode == 2 and not kisten_im_run:
		print("[WAVE][KISTE] erlaubt=false aufrufe=0 felder=0 (platzierung uebersprungen)")
	else:
		_place_chests()
		if kisten_im_run:
			print("[CHAL][REGEL] id=sammler kisten_erlaubt=true quelle=run_map")

	# Wellen-Modus: kein Dauer-Spawner, stattdessen Wellen + Shop
	coins = 0
	slot_coins.clear()
	slot_coins[my_slot] = 0
	shop_ready.clear()
	wave = 0
	in_shop = false
	shop_time = 0.0
	wave_active = false
	_wave_upgrade_hint_shown = false
	ui_manager.hide_shop()
	ui_manager.hide_upgrade_cards()
	if game_mode == 1:
		monster_spawner.stop_spawning()
		ui_manager.update_wave_label(0, 0, false, 0.0, 0)
	elif game_mode == 2:
		monster_spawner.stop_spawning()
		ui_manager.update_wave_label(0, 0, false, -1.0, 0)
		ui_manager.set_wave_icons(false, false)
	else:
		ui_manager.update_wave_label(0, 0, false, -1.0, 0)

	# Monster-Spawning starten (im Wellen-/Runden-Modus uebernimmt der Wellen-Manager)
	if game_mode == 0:
		monster_spawner.start_spawning(FIRST_WAVE_DELAY, MONSTER_SPAWN_INTERVAL, self)
	else:
		monster_spawner.stop_spawning()

	# --- Spieler erstellen (Runde 10: bis zu 4 Slots) ---
	players.clear()
	my_slot = 1
	if coop_host:
		var hslots := NetManager.occupied_slots()
		if hslots.is_empty():
			hslots = [1]
		_build_slot_profiles()
		for s in hslots:
			_spawn_slot_player(int(s), int(s) != 1, false)
	else:
		_spawn_slot_player(1, false, false)
		if duo_mode:
			_spawn_slot_player(2, false, false)
	player = player_for_slot(1)
	player2 = player_for_slot(2)
	for _p in player_nodes():
		_p.aim_assist = aim_assist
	if duo_mode and is_instance_valid(player2):
		ui_manager.register_references2(player2)
	# Hinweis: health_changed/player_died werden bereits in _spawn_slot_player()
	# verbunden — hier NICHT nochmal (sonst "signal already connected"-Fehler).

	# Korruptionszonen (3 wandernde Felder)
	for z in zones:
		if is_instance_valid(z):
			z.queue_free()
	zones.clear()
	_host_zones = PackedFloat32Array()
	var num_zones: int = 0 if game_mode == 2 else 2   # v1.40: RUNDEN-Modus = nur Monster
	var zone_positions = map_generator.get_random_walkable_positions(num_zones, 12)
	for pos in zone_positions:
		var zone = ZONE_SCENE.new()
		var zr := randf_range(260.0, 380.0)
		zone.setup(pos, zr)
		ysort.add_child(zone)
		zones.append(zone)
		_host_zones.append(pos.x)
		_host_zones.append(pos.y)
		_host_zones.append(zr)

	# UI registrieren
	ui_manager.register_references(self, player)
	ui_manager.set_duo(duo_mode)
	# v1.48 (A1): Startwerte belegen - beide Modi muessen identisch starten
	if is_instance_valid(player):
		print("[RUN][START] modus=%d hp=%d schild=%d tempo=%.2f schaden=%.2f" % [
			game_mode, int(player.max_health), int(player.shield),
			float(player.speed_mult), float(player.damage_mult)])

	# Kamera folgt Spieler (Camera bleibt Kind von Main -> überlebt Player-Tod, V4)
	camera.global_position = player.position
	camera.make_current()

	# UI anzeigen
	ui_manager.show_hud()
	ui_manager.update_health(player.call("get_health"), player.call("get_max_health"), 1)
	if duo_mode:
		ui_manager.update_health(MAX_HEALTH, MAX_HEALTH, 2)
	ui_manager.update_score(score)
	ui_manager.update_xp(1, 0, 25)
	ui_manager.update_combo(0, 1.0)
	if lan_mode:
		ui_manager.set_duo(false)
		ui_manager.set_ping_visible(true)      # Runde 34: Ping-Knopf im Mehrspieler
		print("LAN: Run gestartet (Host=", NetManager.is_host, ", Partner=", NetManager.has_partner(), ")")
	# Waffen-HUD (G2) + Buff-Anzeige initialisieren
	ui_manager.refresh_weapon_hud(player.call("get_owned_weapons"), player.call("get_weapon_key"))
	# Runde 63: Trank/Bombe-Beschriftung sofort setzen - vorher stand beim
	# Start auf beiden Knoepfen "TRANK x0".
	ui_manager.refresh_utility_hud(player.utilities, player.call("get_weapon_key"))
	ui_manager.update_buffs(0.0, 0.0)
	# Eigenes Profil auf den Helden anwenden
	_apply_profile()
	if coop_client and not coop_host:
		NetManager.c_send_profile(p_name, p_color, p_hat, p_rig)
	# v1.40: RUNDEN-Modus - Startherzen je Schwierigkeit, dann Runde 1
	if game_mode == 2:
		_rm().reset(round_difficulty)
		if chal_active and chal_run != null:
			chal_run.start(self)
			ui_manager.call("set_challenge_hud", str(chal_run.hud_text()))
		else:
			ui_manager.call("hide_challenge_hud")
		_rm().start_round()
	# v1.42 (P14): Ladebild nach dem Weltaufbau ausblenden (min. 0,8 s sichtbar)
	if ui_manager != null and ui_manager.has_method("hide_load_after_run"):
		ui_manager.call("hide_load_after_run")

func _spawn_slot_player(slot: int, is_remote_driven: bool, is_remote_ctrl: bool) -> Node:
	# Runde 65: Existiert fuer diesen Slot schon eine Figur, muss sie weg.
	# Vorher blieb der alte Charakter in der Welt stehen (Doppel-Spawn): er
	# nahm weiter Schaden, starb mit und riss den Run mit.
	var old = players.get(slot, null)
	if old != null and is_instance_valid(old):
		if old.player_died.is_connected(Callable(self, "_on_player_died")):
			old.player_died.disconnect(Callable(self, "_on_player_died"))
		old.queue_free()
		print("[COOP][SPAWN] Alter Spieler fuer Slot %d entfernt" % slot)
	players.erase(slot)
	var p = player_scene.instantiate()
	p.max_health = int(diff_data()["hearts"])
	p.health = p.max_health
	p.player_id = slot
	p.gm = self
	p.remote_driven = is_remote_driven
	p.remote_controlled = is_remote_ctrl
	p.position = map_generator.get_center() + Vector2(74.0 * float(slot - 1), 0.0)
	ysort.add_child(p)
	p.connect("health_changed", Callable(self, "_on_slot_health").bind(slot))
	p.connect("player_died", Callable(self, "_on_player_died"))
	players[slot] = p
	var pr := _slot_texture_profile(slot)
	p.call("apply_profile", int(pr["color"]), int(pr["hat"]), int(pr.get("rig", 0)))
	return p

func _on_slot_health(new_health: int, slot: int) -> void:
	var p = players.get(slot, null)
	var mx := MAX_HEALTH
	var wpn := ""
	var sh := 0
	if is_instance_valid(p):
		mx = p.call("get_max_health")
		wpn = str(p.call("get_weapon_name"))
		sh = int(p.call("get_shield"))
	if slot == my_slot:
		player_health = new_health
		ui_manager.update_health(new_health, mx, 1)
	else:
		ui_manager.update_partner_slot(slot, new_health, mx, wpn, sh, str(_slot_texture_profile(slot)["name"]))

func _place_chests():
	_host_chests = PackedFloat32Array()
	var chest_cnt := maxi(4, int(round(float(NUM_CHESTS) * get_loot_mult())))
	var positions = map_generator.get_random_walkable_positions(chest_cnt, 5)
	for pos in positions:
		var chest = chest_scene.instantiate()
		chest.position = pos
		chest.connect("item_spawned", Callable(self, "_on_chest_item_spawned"))
		chest.connect("chest_opened", Callable(self, "_on_run_chest_opened"))
		chest.gm = self
		var cr := randf()
		var crar := "common"
		if cr >= 0.90:
			crar = "epic"
		elif cr >= 0.60:
			crar = "rare"
		chest.call("set_rarity", crar)
		chest_container.add_child(chest)
		_host_chests.append(pos.x)
		_host_chests.append(pos.y)

func _on_run_chest_opened() -> void:
	# v1.45 (C8): SAMMLER zaehlt Kisten, die im Run geoeffnet wurden.
	if chal_active and chal_run != null:
		chal_run.on_chest_opened()


func _on_p1_health(new_health: int):
	player_health = new_health
	var mx = MAX_HEALTH
	if is_instance_valid(player):
		mx = player.call("get_max_health")
	ui_manager.update_health(new_health, mx, 1)

func _on_p2_health(new_health: int):
	var mx = MAX_HEALTH
	if is_instance_valid(player2):
		mx = player2.call("get_max_health")
	ui_manager.update_health(new_health, mx, 2)

func get_nearest_target(from: Vector2) -> Node2D:
	# Alle Helden (Duo wie 4-Spieler-LAN): Monster jagen den naechsten
	var best: Node2D = null
	var best_d := INF
	for p in player_nodes():
		var d := from.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	if best != null:
		return best
	if is_instance_valid(player):
		return player
	return null

# ---------------- Mehrspieler-Helfer (Runde 10) ----------------
func player_nodes() -> Array:
	var out: Array = []
	var keys := players.keys()
	keys.sort()
	for s in keys:
		var p = players[s]
		if is_instance_valid(p):
			out.append(p)
	return out

func local_player() -> Node:
	var p = players.get(my_slot, null)
	if is_instance_valid(p):
		return p
	return player if is_instance_valid(player) else null

func player_for_slot(s: int) -> Node:
	var p = players.get(s, null)
	return p if is_instance_valid(p) else null

func player_centroid() -> Vector2:
	var arr := player_nodes()
	if arr.is_empty():
		return map_generator.get_center()
	var c := Vector2.ZERO
	for p in arr:
		c += p.global_position
	return c / float(arr.size())

func _slot_texture_profile(slot: int) -> Dictionary:
	return slot_profiles.get(slot, { "name": "P%d" % slot, "color": (slot - 1) % 6, "hat": 0 })

# ---------------- LAN-Partner ----------------
func _on_lan_run_start() -> void:
	# Client: Host hat den Run freigegeben -> Co-op-Welt aufbauen
	if current_state != GameState.MENU and current_state != GameState.LOBBY:
		return
	if NetManager.is_host:
		return
	if multiplayer.get_peers().size() < 1:
		print("[LAN][FEHLER] run_start ohne Verbindung - Client bleibt im Menue")
		return
	coop_client = true
	NetManager.coop_role = 2
	my_slot = maxi(2, NetManager.my_slot)
	_build_slot_profiles()
	_pending_client_start = true
	_try_start_coop_client()

# ============================================================
# LOBBY (Runde 10): Host + Clients warten, Host startet
# ============================================================
func start_lan_host(wanted_players: int = 2) -> void:
	var err: String = NetManager.host_game(wanted_players)
	if err != "":
		ui_manager.lan_status.text = err
		return
	NetManager.c_send_lobby_profile("", 0, 0)   # Profile erst im Run
	my_slot = 1
	current_state = GameState.LOBBY
	NetManager.lobby[1]["name"] = p_name
	NetManager.lobby[1]["color"] = p_color
	NetManager.lobby[1]["hat"] = p_hat
	_build_slot_profiles()
	ui_manager.show_lobby(true, 1)
	var host_ip: String = str(NetManager.get_local_ip())
	print("LOBBY: Host gestartet, max ", NetManager.player_count, " Spieler, IP ", host_ip)
	# Runde 108: Der Host muss seine IP SEHEN - sonst kann der andere nicht
	# beitreten. Vorher stand sie nur im Log.
	if ui_manager != null and ui_manager.get("lan_status") != null:
		ui_manager.lan_status.text = "DEINE IP: %s   ·   WARTE AUF MITSPIELER (1/%d)" % [host_ip, NetManager.player_count]
	if ui_manager != null and ui_manager.get("lan_ip_edit") != null:
		ui_manager.lan_ip_edit.placeholder_text = host_ip
	# Runde 85: IP und Port direkt im LAN-Fenster anzeigen, damit der
	# Handy-Spieler sie nur abtippen muss.
	if ui_manager != null and ui_manager.get("lan_status") != null:
		ui_manager.lan_status.text = "HOST: %s  ·  PORT %d" % [NetManager.get_local_ip(), NetManager.ENET_PORT]

func start_lan_join(ip: String) -> void:
	var err: String = NetManager.join_game(ip)
	if err != "":
		ui_manager.lan_status.text = err
		return
	current_state = GameState.LOBBY
	ui_manager.show_lobby(false, 0)
	print("LOBBY: verbinde mit ", ip)

func leave_lobby() -> void:
	NetManager.leave()
	players.clear()
	slot_profiles.clear()
	slot_ready.clear()
	current_state = GameState.MENU
	ui_manager.hide_lobby()
	ui_manager.show_start_screen()

func _build_slot_profiles() -> void:
	# Host- und Client-Sicht: Profile aus der Lobby-Roster ableiten
	slot_profiles.clear()
	slot_ready.clear()
	var my_id := multiplayer.get_unique_id()
	for k in NetManager.lobby.keys():
		var pr: Dictionary = NetManager.lobby[k]
		var slot := int(pr.get("slot", 1))
		var is_me: bool = (int(k) == my_id) if not NetManager.is_host else (int(k) == 1)
		slot_profiles[slot] = {
			"name": p_name if is_me else str(pr.get("name", "P%d" % slot)),
			"color": p_color if is_me else int(pr.get("color", (slot - 1) % 6)),
			"hat": p_hat if is_me else int(pr.get("hat", 0))
		}
		slot_ready[slot] = bool(pr.get("ready", false))

func _on_lobby_changed() -> void:
	if current_state == GameState.LOBBY:
		_build_slot_profiles()
		ui_manager.update_lobby(NetManager.lobby, NetManager.player_count, NetManager.is_host)
	# Im Run: Profile fuer HUD/Texturen aktualisieren
	elif current_state == GameState.PLAYING:
		_build_slot_profiles()
		_apply_slot_profiles()

func _on_peer_left(_id: int) -> void:
	if current_state == GameState.PLAYING:
		ui_manager.show_banner("Mitspieler hat verlassen", Color(1.0, 0.5, 0.4))
	# Runde 104: Slot aufraeumen - vorher blieb die Figur als Geist stehen
	# und der Run lief mit einem toten Partner weiter.
	var removed := 0
	for sl in players.keys():
		if int(sl) == int(my_slot):
			continue
		var p = players[sl]
		if is_instance_valid(p):
			if p.get_parent() != null:
				p.get_parent().remove_child(p)
			p.queue_free()
			removed += 1
		players.erase(sl)
		downed.erase(int(sl))
		downed_time.erase(int(sl))
		revive_progress.erase(int(sl))
		spectator.erase(int(sl))
		var ring = _downed_rings.get(int(sl), null)
		if is_instance_valid(ring):
			ring.queue_free()
		_downed_rings.erase(int(sl))
	print("[LAN] Peer getrennt - %d Partner-Figur(en) entfernt, players=%s" % [removed, str(players.keys())])

func _apply_slot_profiles() -> void:
	for s in players.keys():
		var p = players[s]
		if not is_instance_valid(p):
			continue
		var pr := _slot_texture_profile(s)
		p.call("apply_profile", int(pr["color"]), int(pr["hat"]), int(pr.get("rig", 0)))

func start_lobby_from_menu(wanted_players: int) -> void:
	start_lan_host(wanted_players)

# Host drueckt im Lobby-Fenster START: Clients losschicken + selbst starten
func start_lan_run_as_host() -> void:
	if not NetManager.is_host:
		return
	if current_state != GameState.LOBBY:
		return
	# Runde 99: Ohne Mitspieler darf kein Run starten - sonst laufen beide
	# Seiten als "SOLO/1" mit hp=0 (genau das stand im Log).
	var peers: int = multiplayer.get_peers().size()
	if peers < 1:
		print("[LAN] Warte auf Mitspieler: 1/2 - Run noch nicht gestartet")
		if ui_manager != null and ui_manager.get("lan_status") != null:
			ui_manager.lan_status.text = "WARTE AUF MITSPIELER (1/2)"
		return
	NetManager.h_start_run()      # coop_begin -> alle Clients bauen die Welt auf
	ui_manager.hide_lobby()
	start_game(false, true)       # Host baut seine Welt (coop_host)
	_send_coop_init()             # Seed/Kisten/Zonen JETZT schicken (nach dem Aufbau)

func _on_net_connected() -> void:
	# Client: sofort Profil an den Host schicken, damit die Lobby es anzeigt
	if not NetManager.is_host:
		NetManager.c_send_lobby_profile(p_name, p_color, p_hat)

# ============================================================
# CO-OP (Phase 2): eine gemeinsame Welt
# ============================================================
func _on_peer_joined_coop(peer_id: int) -> void:
	if coop_host:
		_send_coop_init()
		NetManager.h_send_profile(p_name, p_color, p_hat, p_rig)

func _on_coop_profile(peer_id: int, peer_name: String, color: int, hat: int, rig: int = 0) -> void:
	var slot := NetManager.slot_of_peer(peer_id)
	partner_name = peer_name
	partner_color = color
	partner_hat = hat
	partner_rig = rig
	if slot <= 0:
		slot = 2
	slot_profiles[slot] = { "name": peer_name, "color": color, "hat": hat, "rig": rig }
	var p = players.get(slot, null)
	if is_instance_valid(p):
		p.call("apply_profile", color, hat, rig)
	if is_instance_valid(player2):
		player2.call("apply_profile", color, hat, rig)
	# Partner-Grafik beim Client (Geist) einfärben
	if coop_client and is_instance_valid(partner_node):
		var spr = partner_node.get_node_or_null("Sprite2D")
		if spr:
			spr.texture = TextureManager.get_player_texture(color, hat)

func _send_coop_init() -> void:
	NetManager.h_send_init(_net_seed, _host_chests, _host_zones, biome_id, active_map)

func _on_net_hit_request(monster_id: int, damage: int) -> void:
	# Runde 66: Treffer-Autoritaet - nur der Host zieht Schaden ab.
	if not coop_host:
		return
	for m in _monster_cache:
		if is_instance_valid(m) and int(m.get("net_id")) == monster_id:
			m.call("take_damage", damage, 0)
			return
	print("[COOP][HIT] FEHLER: monster=%d nicht gefunden (dmg=%d)" % [monster_id, damage])


func _on_coop_init(net_seed: int, chests: PackedFloat32Array, zone_data: PackedFloat32Array, biome: String, map_id: String = "") -> void:
	_net_seed = net_seed
	_net_chests = chests
	_net_zones = zone_data
	_net_biome = biome
	_net_map = map_id
	_try_start_coop_client()

func _try_start_coop_client() -> void:
	if not _pending_client_start or _net_seed == 0:
		return
	if current_state != GameState.MENU and current_state != GameState.LOBBY:
		return
	_pending_client_start = false
	_start_coop_client()

func _start_coop_client() -> void:
	current_state = GameState.PLAYING
	score = 0
	player_health = MAX_HEALTH
	combo_count = 0
	combo_timer = 0.0
	xp = 0
	# Runde 49c: 25 -> 60. Vorher brauchte man nur 1-2 Kills
	# pro Level (Monster geben 10-30 Punkte) - zu oft ein Upgrade.
	xp_needed = maxi(20, int(round(60.0 * xp_multiplier())))
	level = 1
	pending_upgrades = 0
	upg_stacks.clear()
	_boss_timer = 0.0
	_boss_count = 0
	current_boss = null
	freeze_time = 0.0
	rapid_time = 0.0
	gold_time = 0.0
	# Karte mit dem Host-Seed erzeugen -> identische Hindernisse.
	# Runde 65: WICHTIG - zuerst Karte und Biom vom Host uebernehmen, sonst
	# erzeugt der Client mit seiner eigenen Karte eine voellig andere Welt
	# (andere Dichte, andere Hindernisse) und laeuft gegen andere Kollisionen.
	if _net_map != "":
		active_map = _net_map
	if _net_biome != "":
		biome_id = _net_biome
	map_generator.biome_id = biome_id
	map_generator.clear_map()
	map_generator.generate_map(MAP_COLS, MAP_ROWS, TILE_SIZE, _net_seed)
	if not season_unlocks.has(active_map):
		season_unlocks[active_map] = ["spring"]
	season_id = planet_season(active_map)
	map_generator.set_season(season_id)
	map_generator.place_planet_obstacles(get_vegetation())
	biome_id = _net_biome
	if _net_biome == "" or _net_biome == "meadow":
		biome_id = str(map_data()["biome"])
	map_generator.set_biome(biome_id)
	map_generator.detail_level = quality
	map_generator.rebuild_visuals()
	# Monster-Geister leeren
	for id in _ghosts.keys():
		var g = _ghosts[id]
		if is_instance_valid(g):
			g.queue_free()
	_ghosts.clear()
	for id in _item_ghosts.keys():
		var it = _item_ghosts[id]
		if is_instance_valid(it):
			it.queue_free()
	_item_ghosts.clear()
	# Kisten des Hosts (nur Optik)
	for c in chest_container.get_children():
		c.queue_free()
	var i := 0
	while i + 1 < _net_chests.size():
		var chest = chest_scene.instantiate()
		chest.gm = self
		chest.position = Vector2(_net_chests[i], _net_chests[i + 1])
		chest.connect("item_spawned", Callable(self, "_on_chest_item_spawned"))
		chest.connect("chest_opened", Callable(self, "_on_run_chest_opened"))
		chest_container.add_child(chest)
		# NICHT mehr abschalten: der Client darf Kisten oeffnen (Host vergibt Loot)
		i += 2
	# Korruptionszonen des Hosts (nur Optik)
	for z in zones:
		if is_instance_valid(z):
			z.queue_free()
	zones.clear()
	i = 0
	while i + 2 < _net_zones.size():
		var zone = ZONE_SCENE.new()
		zone.setup(Vector2(_net_zones[i], _net_zones[i + 1]), _net_zones[i + 2])
		ysort.add_child(zone)
		zone.set_process(false)
		zones.append(zone)
		i += 3
	# Eigener Held + alle Mitspieler (Runde 10: bis zu 4 Slots, Host simuliert)
	players.clear()
	my_slot = maxi(2, NetManager.my_slot)
	_build_slot_profiles()
	var cslots := NetManager.occupied_slots()
	if cslots.is_empty():
		cslots = [1, my_slot]
	for s in cslots:
		var si := int(s)
		var p := _spawn_slot_player(si, false, true)
		if si == my_slot:
			player = p
	player2 = null
	if is_instance_valid(player):
		# Runde 52: _spawn_slot_player() hat player_died schon verbunden -
		# ein zweites connect() warf "already connected" und liess den
		# Todes-Handler DOPPELT laufen.
		if not player.player_died.is_connected(Callable(self, "_on_player_died")):
			player.connect("player_died", Callable(self, "_on_player_died"))
		player.connect("health_changed", Callable(self, "_on_p1_health"))
	# Mitspieler-HUD aufbauen
	_refresh_partner_hud()
	# UI
	ui_manager.register_references(self, player)
	ui_manager.set_duo(false)
	ui_manager.show_hud()
	ui_manager.update_health(MAX_HEALTH, MAX_HEALTH, 1)
	ui_manager.update_score(0)
	ui_manager.update_combo(0, 1.0)
	ui_manager.update_buffs(0.0, 0.0, 0.0)
	ui_manager.refresh_weapon_hud(player.call("get_owned_weapons"), player.call("get_weapon_key"))
	print("COOP: Client-Run gestartet (Seed=", _net_seed, ", Kisten=", int(_net_chests.size() / 2), ", Zonen=", int(_net_zones.size() / 3), ")")

# ---------- Host: Senden ----------
func _coop_host_tick(delta: float) -> void:
	_t_mobs += delta
	if _t_mobs >= 0.05:      # Runde 77: 20 Hz - 10 Hz war fuer Egoshooter zu wenig
		_t_mobs = 0.0
		_send_mob_snapshot()
		_t_diag_mobs += 1
	_t_world += delta
	if _t_world >= 0.4:
		_t_world = 0.0
		var bhp := 0
		var bmx := 0
		if current_boss != null and is_instance_valid(current_boss):
			bhp = int(current_boss.current_health)
			bmx = int(current_boss.max_health)
		NetManager.h_send_world(score, combo_count, biome_id, freeze_time, rapid_time, gold_time, bhp, bmx)
		_t_diag_world += 1
		# Runde 50: Zaehler erst NACH dem Log zuruecksetzen (vorher wurde
		# alle 0.4 s genullt -> die Ausgabe war keine Rate pro Sekunde).
		if _ldiag_th("SYNC", 1.0, "gesendet: mobs=%d/s players=%d/s world=%d/s monsters=%d paused=%s" % [
			_t_diag_mobs, _t_diag_pl, _t_diag_world, _monster_cache.size(), str(get_tree().paused)]):
			_t_diag_mobs = 0
			_t_diag_pl = 0
			_t_diag_world = 0
	_t_myp += delta
	if _t_myp >= 0.066:
		_t_myp = 0.0
		_send_players_snapshot()
		_t_diag_pl += 1
	_t_items += delta
	if _t_items >= 0.25:
		_t_items = 0.0
		_send_item_snapshot()
	# Mitspieler-Anzeige (Name/Herzen/Waffe, blasser Ton) auf dem Host
	_refresh_partner_hud()

func _send_players_snapshot() -> void:
	var data := PackedFloat32Array()
	var weapons := PackedStringArray()
	var keys := players.keys()
	keys.sort()
	for s in keys:
		var p = players[s]
		if not is_instance_valid(p):
			continue
		data.append(float(int(s)))
		data.append(p.global_position.x)
		data.append(p.global_position.y)
		data.append(float(p.call("get_health")))
		data.append(float(p.call("get_max_health")))
		data.append(float(p.call("get_aim_degrees")))
		data.append(float(p.call("get_shield")))
		data.append(1.0 if bool(downed.get(int(s), false)) else 0.0)   # Runde 34: downed-Flag
		weapons.append(str(p.call("get_weapon_name")))
	NetManager.h_send_players(data, weapons)

func _refresh_partner_hud() -> void:
	for s in players.keys():
		var si := int(s)
		if si == my_slot:
			continue
		var p = players[si]
		if not is_instance_valid(p):
			continue
		ui_manager.update_partner_slot(si, int(p.call("get_health")), int(p.call("get_max_health")),
			str(p.call("get_weapon_name")), int(p.call("get_shield")), str(_slot_texture_profile(si)["name"]))

func _on_players_synced(data: PackedFloat32Array, weapons: PackedStringArray) -> void:
	if not coop_client or current_state != GameState.PLAYING:
		return
	var i := 0
	var n := 0
	while i + 7 <= data.size():
		var slot := int(data[i])
		var x := data[i + 1]
		var y := data[i + 2]
		var hp := int(data[i + 3])
		var mx := int(data[i + 4])
		var ang := data[i + 5]
		var sh := int(data[i + 6])
		var wpn: String = str(weapons[n]) if n < weapons.size() else ""
		var p = players.get(slot, null)
		if is_instance_valid(p):
			if wpn != "":
				var wk := "weapon_" + wpn
				if p.call("get_weapon_key") != wk:
					p.call("switch_weapon", wk)
			p.health = hp
			p.max_health = mx
			p.shield = sh
			p.call("set_remote_transform", Vector2(x, y), ang)
			if slot == my_slot:
				player_health = hp
				ui_manager.update_health(hp, mx, 1)
				ui_manager.refresh_weapon_hud(p.call("get_owned_weapons"), p.call("get_weapon_key"))
			else:
				ui_manager.update_partner_slot(slot, hp, mx, wpn, sh, str(_slot_texture_profile(slot)["name"]))
		var dwn: bool = (i + 7 < data.size()) and (float(data[i + 7]) > 0.5)
		p.set("downed", dwn)
		i += 8
		n += 1

func _make_light_ghost(mtype: int) -> StaticBody2D:
	# Runde 34: Client-Geister als einfaches Sprite (vorher: komplette Monster-Szene
	# mit CollisionShape + Warn-Sprite + KI-Skript pro Geist -> viel Last)
	# Runde 66: zusaetzlich eine Kollision auf der Monster-Ebene, damit
	# Schuesse des Clients ueberhaupt treffen (Treffer geht an den Host).
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.add_to_group("monsters")
	var sp := Sprite2D.new()
	var key: String = str(monster_ai_script.ghost_texture_key(mtype)) if monster_ai_script != null else "monster_green"
	var tex = TextureManager.get_texture(key)
	if tex != null:
		sp.texture = tex
	var sc: float = float(monster_ai_script.ghost_scale(mtype)) if monster_ai_script != null else 1.0
	sp.scale = Vector2(sc, sc)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sp.z_index = 1
	body.add_child(sp)
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0 * sc
	cs.shape = shape
	body.add_child(cs)
	body.set_script(load("res://scripts/ghost_body.gd"))
	body.set("gm", self)
	body.set("sprite", sp)
	return body

func _send_mob_snapshot() -> void:
	var data := PackedFloat32Array()
	_mob_seq_out += 1
	data.append(float(_mob_seq_out))   # Sequenz gegen Out-of-Order
	# Runde 81: Nur Monster in der Naehe des Clients senden (Relevanz).
	# Auf grossen Karten mit 40+ Gegnern halbiert das die Paketgroesse.
	var anchor: Vector2 = Vector2.ZERO
	var have_anchor := false
	for sl in players.keys():
		if int(sl) != my_slot:
			var cp = players[sl]
			if is_instance_valid(cp):
				anchor = cp.global_position
				have_anchor = true
	for m in _monster_cache:          # Runde 33: eigene Liste statt Baumsuche
		if not is_instance_valid(m) or m.ghost:
			continue
		# Runde 110: Radius 1650 -> 2600. Vorher verschwanden Monster, die weit
		# vom Partner standen, obwohl der Host sie sah.
		if have_anchor and m.global_position.distance_to(anchor) > 2600.0:
			continue
		if m.net_id == 0:
			m.net_id = _next_mid
			_next_mid += 1
		data.append(float(m.net_id))
		data.append(float(m.type))
		data.append(m.global_position.x)
		data.append(m.global_position.y)
		data.append(float(m.current_health))
		data.append(180.0 if (m.sprite != null and m.sprite.flip_h) else 0.0)
	NetManager.h_send_mobs(data)

func _send_item_snapshot() -> void:
	var data := PackedFloat32Array()
	var types := PackedStringArray()
	var rars := PackedStringArray()
	for it in item_container.get_children():
		if not is_instance_valid(it):
			continue
		if it.net_id == 0:
			it.net_id = _next_iid
			_next_iid += 1
		data.append(float(it.net_id))
		data.append(it.global_position.x)
		data.append(it.global_position.y)
		types.append(str(it.item_type))
		rars.append(str(it.rarity))
	NetManager.h_send_items(data, types, rars)

func _on_remote_input(peer_id: int, dx: float, dy: float, shoot: bool, angle: float) -> void:
	if not coop_host:
		return
	var slot := NetManager.slot_of_peer(peer_id)
	var p = players.get(slot, null)
	if is_instance_valid(p):
		p.call("set_remote_input", Vector2(dx, dy), shoot, angle)

func notify_shot(p: Node2D, angle_rad: float) -> void:
	if coop_host and p != null and p != player:
		NetManager.h_send_shot(p.global_position.x, p.global_position.y, rad_to_deg(angle_rad))

# ---------- Client: Empfangen ----------
func _coop_client_tick(delta: float) -> void:
	if not is_instance_valid(player):
		return
	# Runde 50: Monster-Geister werden HIER (60+ Hz) zum letzten Ziel
	# interpoliert. Vorher geschah das nur im Paket-Callback (~10 Hz),
	# dadurch ruckelten sie trotz stabiler FPS.
	# (alte Einzelziel-Glaettung ersetzt durch Puffer-Interpolation)
	# Runde 79: Monster aus dem Puffer 100 ms hinter "jetzt" abspielen
	_mob_lerp_to(float(Time.get_ticks_msec()) - MOB_DELAY_MS)
	# Downed-Ringe fuer den Partner auch auf dem Client zeichnen
	for sl in downed.keys():
		if bool(downed[sl]):
			var dp: Node2D = players.get(sl)
			if is_instance_valid(dp):
				_update_downed_ring(int(sl), dp)
	_t_myp += delta
	if _t_myp >= 0.05:
		_t_myp = 0.0
		var ang := _my_aim_deg
		if player.input_direction != Vector2.ZERO:
			ang = rad_to_deg(player.input_direction.angle())
			_my_aim_deg = ang
		NetManager.c_send_input(player.input_direction, player.shoot_held, ang)

func _on_revive_hold(held: bool) -> void:
	_revive_held = held
	# Runde 89: Im Client muss die Anfrage zum Host - sonst kann der Client
	# den Host nie aufwecken (genau das war der Fehler).
	if coop_client and NetManager.active:
		for sl in downed.keys():
			if bool(downed[sl]) and int(sl) != int(my_slot):
				NetManager.c_send_revive(int(sl), held)
				print("[REVIVE] Client sendet Aufweck-Anfrage slot=%d active=%s" % [int(sl), str(held)])
	print("[REVIVE] Knopf %s" % ("gedrueckt - halte 5 s" if held else "losgelassen"))


var _remote_revive: Dictionary = {}

func _on_revive_request(slot: int, active: bool) -> void:
	_remote_revive[slot] = active
	print("[REVIVE] Host: Client %s Slot %d" % ["weckt" if active else "laesst los", slot])


func _on_downed_state(slot: int, is_downed: bool, hp: int, progress: float) -> void:
	# Runde 78: Der Host sendet den Downed-/Revive-Zustand bereits, aber der
	# Client hat das Signal nie verbunden - dadurch gab es beim Partner
	# weder Ring noch Fortschritt, und der eigene Downed-Zustand kam nie an.
	if not coop_client:
		return
	var was: bool = bool(downed.get(slot, false))
	downed[slot] = is_downed
	if is_downed:
		revive_progress[slot] = progress
		if not was:
			if int(slot) == my_slot:
				ui_manager.show_banner("DU LIEGST - DEIN PARTNER MUSS DICH AUFWECKEN", Color(1.0, 0.40, 0.40))
				print("[NET][REVIVE] eigener Downed-Zustand empfangen")
			else:
				ui_manager.show_banner("PARTNER LIEGT - GEH ZU IHM!", Color(1.0, 0.72, 0.30))
				print("[NET][REVIVE] Partner downed slot=%d" % slot)
	else:
		revive_progress.erase(slot)
		if was:
			if int(slot) == my_slot:
				print("[NET][REVIVE] wieder auf den Beinen")
			else:
				print("[NET][REVIVE] Partner wieder auf den Beinen")


func _on_mobs_synced(data: PackedFloat32Array) -> void:
	if not coop_client or current_state != GameState.PLAYING:
		return
	if data.size() < 1:
		return
	var seq: int = int(data[0])
	# Aeltere oder doppelte Pakete verwerfen (unreliable = ungeordnet)
	if seq <= _mob_seq_last:
		return
	_mob_seq_last = seq
	_mob_pkt_count += 1
	if _mob_pkt_count % 20 == 0:
		print("[SYNC][CLIENT] mob-pakete=%d seq=%d" % [_mob_pkt_count, seq])
	var entries: Array = []
	var i := 1
	while i + 6 <= data.size():
		entries.append({
			"id": int(data[i]), "type": int(data[i + 1]),
			"x": data[i + 2], "y": data[i + 3],
			"hp": int(data[i + 4]), "ang": data[i + 5],
		})
		i += 6
	_mob_buf.append({ "t": Time.get_ticks_msec(), "seq": seq, "e": entries })
	while _mob_buf.size() > MOB_BUF_MAX:
		_mob_buf.pop_front()
	# Geister anlegen/entfernen (Position kommt aus dem Puffer)
	var seen: Dictionary = {}
	for e in entries:
		var id: int = int(e["id"])
		seen[id] = true
		var g = _ghosts.get(id)
		if g == null or not is_instance_valid(g):
			g = _make_light_ghost(int(e["type"]))
			monster_container.add_child(g)
			g.set("net_id", id)
			g.position = Vector2(float(e["x"]), float(e["y"]))
			_ghosts[id] = g
		g.set_meta("hp", int(e["hp"]))
		g.set_meta("ang", float(e["ang"]))
	for id in _ghosts.keys():
		if not seen.has(id):
			var gg = _ghosts[id]
			if is_instance_valid(gg):
				gg.queue_free()
			_ghosts.erase(id)

func _mob_lerp_to(target_ms: float) -> void:
	# Findet zwei Snapshots um target_ms und interpoliert dazwischen
	if _mob_buf.is_empty():
		return
	var a: Dictionary = _mob_buf[0]
	var b: Dictionary = _mob_buf[0]
	for k in range(_mob_buf.size()):
		var sn: Dictionary = _mob_buf[k]
		if float(sn["t"]) <= target_ms:
			a = sn
			b = _mob_buf[k + 1] if k + 1 < _mob_buf.size() else sn
		else:
			break
	var ta: float = float(a["t"])
	var tb: float = float(b["t"])
	var al: float = 0.0
	if tb > ta:
		al = clampf((target_ms - ta) / (tb - ta), 0.0, 1.0)
	var bmap: Dictionary = {}
	for e in b["e"]:
		bmap[int(e["id"])] = e
	for e in a["e"]:
		var id: int = int(e["id"])
		var g = _ghosts.get(id)
		if g == null or not is_instance_valid(g):
			continue
		var pa := Vector2(float(e["x"]), float(e["y"]))
		var pb := pa
		if bmap.has(id):
			var eb: Dictionary = bmap[id]
			pb = Vector2(float(eb["x"]), float(eb["y"]))
		g.position = pa.lerp(pb, al)

func _on_items_synced(data: PackedFloat32Array, types: PackedStringArray, rarities: PackedStringArray) -> void:
	if not coop_client or current_state != GameState.PLAYING:
		return
	var seen: Dictionary = {}
	var i := 0
	var n := 0
	while i + 3 <= data.size() and n < types.size():
		var id := int(data[i])
		var x := data[i + 1]
		var y := data[i + 2]
		seen[id] = true
		if not _item_ghosts.has(id) or not is_instance_valid(_item_ghosts.get(id)):
			var it = item_scene.instantiate()
			it.position = Vector2(x, y)
			it.set_item_type(types[n])
			if it.has_method("set_rarity"):
				it.set_rarity(rarities[n])
			item_container.add_child(it)
			it.set_physics_process(false)
			it.set_process(false)
			if it is Area2D:
				# Runde 109: monitoring NICHT waehrend der Physik-Abfrage umschalten -
				# genau das erzeugte "Can't change this state while flushing queries"
				# und fror beide Geraete ein.
				it.set_deferred("monitoring", false)
			it.net_id = id
			_item_ghosts[id] = it
		i += 3
		n += 1
	for id in _item_ghosts.keys():
		if not seen.has(id):
			var it = _item_ghosts[id]
			if is_instance_valid(it):
				it.queue_free()
			_item_ghosts.erase(id)

func _on_world_synced(score_v: int, combo_v: int, wbiome: String, frz: float, rap: float, gold: float, bhp: int, bmx: int) -> void:
	if not coop_client:
		return
	score = score_v
	combo_count = combo_v
	ui_manager.update_score(score)
	ui_manager.update_buffs(rap, frz, gold)
	if bmx > 0:
		ui_manager.update_boss_hp(bhp, bmx)
	if wbiome != biome_id:
		biome_id = wbiome
		map_generator.set_biome(biome_id)
		ui_manager.show_banner(_biome_name(wbiome), _biome_color(wbiome))

func _on_my_player_synced(x: float, y: float, hp: int, mx: int, weapon: String, angle: float, shield: int) -> void:
	if not coop_client or not is_instance_valid(player) or current_state != GameState.PLAYING:
		return
	var wk := "weapon_" + weapon
	if player.call("get_weapon_key") != wk:
		player.call("switch_weapon", wk)
		ui_manager.refresh_weapon_hud(player.call("get_owned_weapons"), player.call("get_weapon_key"))
		# Runde 49: Reload-Indikator aktualisieren
		if player.has_method("get_reload_progress"):
			ui_manager.update_reload_indicator(float(player.call("get_reload_progress")), str(player.call("get_ammo_text")))
	# Runde 99: Ein hp=0 direkt nach dem Spawn ist ein Sync-Fehler, kein Tod.
	# Vorher standen beide Seiten sofort auf 0 und waren "downed".
	if hp <= 0 and not bool(player.get("downed")) and int(player.health) > 0:
		print("[LAN][FEHLER] Sync lieferte hp=0 bei lebendem Spieler - ignoriert")
	else:
		player.health = hp
	player.max_health = mx
	player.shield = shield
	# Runde 80: Der eigene Held wird LOKAL gesteuert (Client-Prediction).
	# Vorher stand er auf remote_controlled und wurde 20x/s zur Host-Position
	# gezogen - jede Eingabe kam um RTT+50 ms verzoegert an (Gummiband).
	if player.remote_controlled or not player.local_controlled:
		player.remote_controlled = false
		player.local_controlled = true
		print("[NET][PREDICT] eigener Held lokal gesteuert (remote_controlled=false)")
	var srv := Vector2(x, y)
	var err: float = player.global_position.distance_to(srv)
	if err > 220.0:
		player.global_position = srv
		print("[NET][RECON] Resync dist=%.0f (Teleport/Respawn)" % err)
	elif err > 12.0:
		# sanfte Korrektur: 22 % pro Paket, nie sichtbarer Sprung
		player.global_position = player.global_position.lerp(srv, 0.22)
	player.call("set_remote_transform", srv, angle)
	ui_manager.update_health(hp, mx, 1)

func _on_shot_synced(x: float, y: float, angle_deg: float) -> void:
	if not coop_client or current_state != GameState.PLAYING:
		return
	if is_instance_valid(player):
		player.call("play_shot_visual")
	_spawn_cosmetic_projectile(Vector2(x, y), deg_to_rad(angle_deg))

func _spawn_cosmetic_projectile(pos: Vector2, angle: float) -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	proj.position = pos
	ysort.add_child(proj)
	proj.collision_layer = 0
	proj.collision_mask = 0
	proj.call("set_direction", Vector2.RIGHT.rotated(angle), 320.0)

func _on_coop_game_over() -> void:
	if not coop_client:
		return
	if current_state == GameState.PLAYING:
		_on_player_died()

func _ensure_partner_node() -> void:
	if is_instance_valid(partner_node):
		return
	partner_node = Node2D.new()
	partner_node.name = "LanPartner"
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = TextureManager.get_texture("player")     # Mitspieler = blauer Held
	spr.modulate = Color(1, 1, 1, 0.92)
	partner_node.add_child(spr)
	partner_node.z_index = 5
	ysort.add_child(partner_node)
	partner_target = partner_node.position

func _on_partner_state(x: float, y: float, hp: int, mx: int, weapon_name: String, angle_deg: float, shield: int) -> void:
	_partner_pos = Vector2(x, y)
	_partner_pos_fresh = 1.0
	if current_state != GameState.PLAYING:
		return
	if coop_host:
		return          # Host hat einen echten zweiten Spieler (kein Geist)
	_ensure_partner_node()
	if not is_instance_valid(partner_node):
		return
	var new_target := Vector2(x, y)
	# Runde 49: Geschwindigkeit fuer die Extrapolation messen
	var moved: Vector2 = new_target - partner_target
	if moved.length() > 0.5:
		partner_velocity = moved
		partner_pred_time = 0.12
	partner_target = new_target
	var spr = partner_node.get_node_or_null("Sprite2D")
	if spr:
		spr.rotation = deg_to_rad(angle_deg)
	ui_manager.update_partner(hp, mx, weapon_name, shield)

func _on_partner_gone() -> void:
	clear_partner()

func clear_partner() -> void:
	if is_instance_valid(partner_node):
		partner_node.queue_free()
	partner_node = null
	if ui_manager:
		ui_manager.clear_partner()

func _on_player_died():
	if current_state != GameState.PLAYING:
		return
	# Runde 34: Im Mehrspieler faellt man nicht sofort aus - man wird "downed"
	# und kann vom Partner wieder aufgeweckt werden (2,5 s neben ihm stehen).
	if lan_mode:
		_ldiag("DEATH", "Spieler gefallen - Downed-Zweig (players=%s)" % str(players.keys()))
		for slot in players.keys():
			var pp = players[slot]
			if is_instance_valid(pp) and int(pp.call("get_health")) <= 0:
				var sl: int = int(slot)
				downed[sl] = true
				downed_time[sl] = DOWNED_LIMIT
				revive_progress[sl] = 0.0
				pp.set("downed", true)
				ui_manager.show_banner("SPIELER %d IST GEFALLEN - GEH HIN UND WECK AUF" % sl, Color(1.0, 0.42, 0.42))
				return
	# RUNDEN-Modus (v1.40): gekaufte Versicherung loest statt Run-Ende aus
	if game_mode == 2 and _rm().revive():
		return
	# v1.45 (C12): Tod im Run zaehlt nicht als erledigt, Fortschritt bleibt
	if chal_active and chal_run != null and not bool(chal_run.beendet):
		chal_run._ende(false, "gestorben")
		print("[CHAL][ABBRUCH] id=%s zustand=LAEUFT fortschritt=%d" % [chal_id, int(chal_run.fortschritt)])
	# Co-op: einer faellt -> Run fuer beide beendet
	current_state = GameState.DEAD
	SoundManager.play_death()
	# Meta-Progression (Runde 11/12): Gold + Kartenschalter
	if run_xp > best_run_xp:
		best_run_xp = run_xp
	_check_map_gates()
	_check_season_gates()
	var gained_gold := award_run_gold()
	# Level-Up-Pause sauber aufloesen
	pending_upgrades = 0
	if get_tree().paused:
		get_tree().paused = false
	ui_manager.hide_upgrade_cards()
	# H3: ein offener Hinweis darf den Tod nicht ueberleben
	if _upg_toast_was_open:
		ui_manager.hide_upgrade_toast()
		_upg_toast_was_open = false
		print("[UPG][TOAST] entfernt (run vorbei)")

	# High Score speichern
	if score > high_score:
		high_score = score
		_save_high_score()

	# Death Screen anzeigen
	ui_manager.show_death_screen(score, high_score, gained_gold, gold)

	# Runde 49: LAN-Broadcast MIT Daten - die Clients brauchen Score und
	# Gold fuer ihren eigenen Death-Screen.
	if coop_host and NetManager.active:
		NetManager.h_send_game_over_data(int(score), int(high_score), int(gained_gold), int(gold))

	# LAN: Partner ausblenden und Sitzung schliessen (Phase 1)
	if lan_mode:
		clear_partner()
		NetManager.leave()
		lan_mode = false

const ITEM_NAMES := {
	"heart": "HERZ", "shield": "SCHILD", "maxhealth": "MAX-HERZ",
	"freeze": "FROST", "rapid": "SCHNELLFEUER",
	"weapon_pistol": "PISTOLE", "weapon_shotgun": "SCHROTFLINTE", "weapon_machine": "MASCHINENPISTOLE",
	"weapon_laser": "LASER", "weapon_revolver": "REVOLVER"
}

func _float_item_label(pos: Vector2, item_type: String, rarity: String) -> void:
	var l := Label.new()
	l.text = str(ITEM_NAMES.get(item_type, item_type))
	l.add_theme_font_size_override("font_size", 26)
	var col := Color(1, 1, 1)
	match rarity:
		"rare":
			col = Color(0.45, 0.80, 1.0)
		"epic":
			col = Color(0.85, 0.50, 1.0)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(240, 30)
	l.position = pos - Vector2(120, 40)
	l.z_index = 20
	ysort.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 46.0, 1.1).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.35)
	tw.tween_callback(l.queue_free)

func _on_chest_item_spawned(item_type: String, position: Vector2, rarity: String = "common"):
	# Runde 36: Pity-Zaehler (nach 10 Kisten ohne Rare ist Rare garantiert)
	if rarity == "rare" or rarity == "epic":
		chests_since_rare = 0
	else:
		chests_since_rare += 1
	_save_profile()
	SoundManager.play("chest")
	_float_item_label(position, item_type, rarity)
	var item = item_scene.instantiate()
	item.set_item_type(item_type)
	if item.has_method("set_rarity"):
		item.set_rarity(rarity)
	item.position = position
	item.connect("picked_up", Callable(self, "_on_item_picked_up"))
	item_container.add_child(item)

func _on_item_picked_up(item_type: String, who: Node2D, rarity: String = "common"):
	# v1.45 (C3/C4/C7): In einer Aufgabe sind bestimmte Pickups gesperrt.
	if chal_active and chal_run != null:
		if item_type.begins_with("weapon") and bool(chal_run.hat("waffen_pickups")):
			print("[CHAL][SPERRE] pickup=%s grund=waffen_pickups id=%s" % [item_type, chal_id])
			return
		if item_type == "heart" and bool(chal_run.hat("herz_pickup")):
			print("[CHAL][SPERRE] pickup=heart grund=herz_pickup id=%s" % chal_id)
			return
		if item_type == "maxhealth" and bool(chal_run.hat("heilung")):
			print("[CHAL][SPERRE] pickup=maxhealth grund=heilung id=%s" % chal_id)
			return
		if item_type == "shield" and bool(chal_run.hat("schild_pickup")):
			print("[CHAL][SPERRE] pickup=shield grund=schild_pickup id=%s" % chal_id)
			return
	SoundManager.play("pickup")
	var p = who if is_instance_valid(who) else player
	if p == null:
		return
	if item_type == "heart":
		# Episches Herz heilt voll
		var amt := 2 if rarity == "epic" else 1
		p.call("heal", amt)
	elif item_type == "shield":
		p.call("add_shield", 2)
	elif item_type == "freeze":
		freeze_time = FREEZE_DURATION
		ui_manager.show_banner("FROST!", Color(0.55, 0.85, 1.0))
	elif item_type == "rapid":
		rapid_time = RAPID_DURATION
		ui_manager.show_banner("SCHNELLFEUER!", Color(1.0, 0.8, 0.3))
	elif item_type == "maxhealth":
		p.call("add_max_health")
		if p == player:
			ui_manager.update_health(p.call("get_health"), p.call("get_max_health"), 1)
		else:
			ui_manager.update_health(p.call("get_health"), p.call("get_max_health"), 2)
	elif item_type.begins_with("weapon"):
		p.call("switch_weapon", item_type)
		# Waffen-HUD aktualisieren (nur fuer den lokalen Spieler)
		if p == player:
			ui_manager.refresh_weapon_hud(player.call("get_owned_weapons"), player.call("get_weapon_key"))
	# Epische Kisten können einen Hut freischalten (Punkt 8)
	if rarity == "epic" and randf() < 0.35:
		_try_unlock_hat()

# v1.56 (Spec A2): Die alte WAVE_BALANCE-Tabelle ist ENTFERNT. Die Wellenwerte
# kommen aus Balance.wave_balance() (core/balance.gd) - eine Zahlenquelle.
func wave_balance() -> Dictionary: return _waves_p().wave_balance()

# Runde 33: Pro-Map-Kurve (Mars/Jungel geben mehr XP+Gold -> mehr XP pro Level noetig)
const XP_CURVE_MULT := { "earth": 1.0, "mars": 1.7, "jungle": 2.1 }
# Runde 49c: Die Preise steigen, damit Gold knapp bleibt.
const SHOP_PRICE_MULT := { "earth": 1.45, "mars": 1.9, "jungle": 2.25 }

func xp_multiplier() -> float:
	return float(XP_CURVE_MULT.get(active_map, 1.0))

func shop_price_mult() -> float: return _shopl_p().shop_price_mult()

func shop_price(base: int) -> int: return _shopl_p().shop_price(base)

func _build_shop_offers() -> Array: return _shopl_p()._build_shop_offers()

func _spawn_force_field() -> void:
	# Runde 38: ein wanderndes Kraftfeld - es bremst den Spieler und macht
	# die spaeteren Runden schwer (vor allem nach Boss-Wellen).
	if ZONE_SCENE == null:
		return
	var z = ZONE_SCENE.new()
	var center: Vector2 = map_generator.get_center()
	if is_instance_valid(player):
		center = player.global_position
	var pos: Vector2 = _wave_spawn_pos(center, true)
	var r: float = randf_range(130.0, 200.0)
	z.setup(pos, r)
	z.set_meta("ff_dir", Vector2.RIGHT.rotated(randf() * TAU))
	z.set_meta("ff_r", r)
	# Runde 39: sichtbares Hexagon-Feld (Overlay auf der Zone)
	var hex := Sprite2D.new()
	hex.texture = TextureManager.get_texture("force_field")
	hex.modulate = Color(0.6, 0.9, 1.0, 0.75)
	hex.scale = Vector2(float(r) / 128.0, float(r) / 128.0)
	hex.z_index = 3
	z.add_child(hex)
	var htw := hex.create_tween()
	htw.set_loops()
	htw.tween_property(hex, "rotation", 0.35, 2.4)
	htw.tween_property(hex, "modulate:a", 0.42, 1.3)
	ysort.add_child(z)
	force_fields.append(z)
	ui_manager.show_banner("KRAFTFELD AKTIV - VORSICHT", Color(0.55, 0.75, 1.0))

func _tick_force_fields(delta: float) -> void:
	# Runde 38: Kraftfelder wandern + bremsen den Spieler
	if force_fields.is_empty():
		return
	var slow: bool = false
	var wb: Rect2 = map_generator.get_map_bounds() if map_generator.has_method("get_map_bounds") else Rect2()
	for z in force_fields:
		if not is_instance_valid(z):
			continue
		var d: Vector2 = z.get_meta("ff_dir", Vector2.RIGHT)
		z.position += d * 34.0 * delta
		if wb.size.length() > 0.0:
			if z.position.x < wb.position.x + 120.0 or z.position.x > wb.end.x - 120.0:
				d.x = -d.x
			if z.position.y < wb.position.y + 120.0 or z.position.y > wb.end.y - 120.0:
				d.y = -d.y
			z.set_meta("ff_dir", d.normalized())
		if is_instance_valid(player):
			var rr: float = float(z.get_meta("ff_r", 150.0))
			if player.global_position.distance_to(z.position) < rr:
				slow = true
	if is_instance_valid(player):
		player.speed_mult = 0.65 if slow else maxf(1.0, player.speed_mult)

func _spawn_wave_monsters() -> void:
	# Runde 35b: Monster der aktuellen Welle erzeugen (auch nach Host-Wechsel)
	var center: Vector2 = map_generator.get_center()
	if is_instance_valid(player):
		center = player.global_position
	for i in range(_wave_monster_count()):
		spawn_monster_at(_wave_spawn_pos(center), _pick_random_monster_type())
	_recount_wave()

func _level_ups_gained() -> int:
	return maxi(0, level - wave_start_level)

func _spawn_reinforcement() -> void:
	# Runde 33: Nachschub, damit der Spieler sein Levelziel erreicht
	_reinforce_timer = 2.0
	var n: int = maxi(4, int(round(float(_wave_monster_count()) * 0.35)))
	var center: Vector2 = map_generator.get_center()
	if is_instance_valid(player):
		center = player.global_position
	for i in range(n):
		spawn_monster_at(_wave_spawn_pos(center), _pick_random_monster_type())
	_recount_wave()
	ui_manager.show_banner("NOCH %d LEVEL FUER DEN SHOP" % maxi(0, WAVE_LEVEL_UPS - _level_ups_gained()), Color(0.95, 0.85, 0.35))

func _map_type_weights() -> Dictionary:
	# Runde 35b: eigene Monster-Anteile pro Karte (Mars = mehr Schuetzen,
	# Jungle = mehr Pflanzen/Schweine, Elektro = mehr Technik-Gegner)
	match active_map:
		"mars":
			return { 11: 3.0, 12: 2.0, 15: 3.0, 16: 2.0, 19: 1.0, 21: 1.0 }
		"jungle":
			return { 13: 2.0, 17: 2.5, 18: 2.5, 14: 2.0, 20: 1.0, 21: 1.0 }
		"volt":
			# Runde 49: Typ 29 = VOLT_SPOOLER (neu), 28 = BOSS_VOLT
			return { 25: 3.0, 26: 2.5, 27: 2.0, 29: 1.8, 24: 1.0, 28: 0.6 }
		_:
			return {}

func _wave_monster_count() -> int:
	# Runde 34: aus der Balance-Tabelle
	return int(wave_balance()["count"])

func _send_shop_state() -> void:
	# Runde 33: Shop-Zustand an die Clients (eigene Muenzen, Ready-Flags, Level)
	if not (coop_host and lan_mode):
		return
	var cb := PackedInt32Array()
	var rf := PackedByteArray()
	for i in range(1, 5):
		cb.append(int(slot_coins.get(i, 0)))
		rf.append(1 if bool(shop_ready.get(i, false)) else 0)
	NetManager.h_send_shop_state(cb, rf, level, xp, xp_needed, WAVE_LEVEL_UPS)

func _on_net_shop_offers(ids: PackedStringArray, prices: PackedInt32Array,
		bought: PackedByteArray, buys_left: int, buys_max: int) -> void:
	# Runde 52: Client baut seine Angebotsliste aus der Host-Nachricht.
	# Definitionen (Label/Preis/Rarity) kommen aus SHOP_ITEMS, damit die
	# Karten ihr Aussehen behalten.
	if coop_host:
		return
	shop_offers.clear()
	for i in range(ids.size()):
		var def: Dictionary = {}
		for it in SHOP_ITEMS:
			if str(it["id"]) == str(ids[i]):
				def = it.duplicate(true)
				break
		if def.is_empty():
			for it2 in SHOP_RARE_ITEMS:
				if str(it2["id"]) == str(ids[i]):
					def = it2.duplicate(true)
					break
		if def.is_empty():
			def = {"id": str(ids[i]), "label": str(ids[i]), "price": 1}
		if i < prices.size():
			def["price"] = int(prices[i])
		def["bought"] = (i < bought.size() and int(bought[i]) == 1)
		shop_offers.append(def)
	shop_purchases_left = buys_left
	_sdiag("NET", "Angebote vom Host: %s | Kaeufe=%d/%d" % [str(_shop_offer_ids()), buys_left, buys_max])
	if in_shop:
		ui_manager.show_shop(coins, shop_offers, buys_left, buys_max)


func _on_net_shop_state(coins_by_slot: PackedInt32Array, ready_flags: PackedByteArray,
		level_v: int, xp_v: int, xp_need: int, level_need: int) -> void:
	if not coop_client:
		return
	if coins_by_slot.size() > 0:
		var idx: int = clampi(my_slot - 1, 0, coins_by_slot.size() - 1)
		coins = int(coins_by_slot[idx])
		slot_coins[my_slot] = coins
	level = level_v
	xp = xp_v
	xp_needed = maxi(1, xp_need)
	ui_manager.update_xp(level, xp, xp_needed)
	if in_shop:
		# Runde 52: Nur Gold/Hinweis aktualisieren - der 4-Hz-Tick darf den
		# Shop NICHT neu aufbauen (sonst verschluckte Klicks).
		ui_manager.update_shop_coins(coins, shop_purchases_left, SHOP_BUY_LIMIT)
		ui_manager.update_wave_label(wave, coins, true, shop_time, wave_remaining)

func _on_net_shop_buy(item_id: String) -> void:
	if not coop_host:
		_sdiag("FAIL", "shop_buy empfangen, aber ich bin kein Host (ignoriert)")
		return
	var slot: int = 2
	var pid: int = multiplayer.get_remote_sender_id()
	if pid > 0:
		slot = int(NetManager.slot_of_peer(pid))
	_sdiag("NET", "Client-Anfrage '%s' von peer %d -> Slot %d" % [item_id, pid, slot])
	_apply_shop_purchase(item_id, slot)

func _on_net_shop_ready() -> void:
	if not coop_host:
		return
	var slot: int = 2
	var pid: int = multiplayer.get_remote_sender_id()
	if pid > 0:
		slot = int(NetManager.slot_of_peer(pid))
	shop_ready[slot] = true
	_send_shop_state()
	if _all_players_ready() and bool(shop_ready.get(my_slot, false)):
		_next_wave(true)

func _tick_downed(delta: float) -> void:
	# Runde 34: Aufweck-Timer, Game-Over wenn alle liegen
	if downed.is_empty():
		return
	for slot in downed.keys():
		var sl: int = int(slot)
		downed_time[sl] = float(downed_time.get(sl, DOWNED_LIMIT)) - delta
		var dp = players.get(sl, null)
		if not is_instance_valid(dp):
			continue
		# Runde 111: downed=true bei hp=1 fuehrte dazu, dass die Revive-Logik
		# mit 1 HP weiterrechnete. Beim Liegen ist health = 0.
		if int(dp.get("health")) > 0 and bool(downed.get(sl, false)):
			dp.set("health", 0)
		var near := false
		for s2 in players.keys():
			if int(s2) == sl:
				continue
			var o = players[s2]
			if is_instance_valid(o) and not bool(downed.get(int(s2), false)):
				if o.global_position.distance_to(dp.global_position) < 95.0:
					near = true
					break
		# Runde 111: Der Host hat die Client-Figur evtl. nicht synchron - dann war
		# near IMMER false und die Leiste lief nie. Zusaetzlich die zuletzt
		# gemeldete Partnerposition pruefen.
		if not near and int(sl) != 2 and _partner_pos_fresh > 0.0:
			if _partner_pos.distance_to(dp.global_position) < 110.0:
				near = true
		# Runde 50: Downed-Zustand an die Clients melden - 10 Hz pro Slot
		# (vorher ein reliable-RPC in JEDEM Frame = ~60/s)
		if coop_host and NetManager.active:
			var now_ms: int = Time.get_ticks_msec()
			var last_ms: int = int(_downed_net_t.get(sl, 0))
			if now_ms - last_ms >= 100:
				_downed_net_t[sl] = now_ms
				NetManager.h_send_downed_state(sl, true, int(dp.get("health")), float(revive_progress.get(sl, 0.0)))
		_update_downed_ring(sl, dp)
		# Runde 50: Diagnose - wer liegt, wie lange noch, ist jemand nah?
		_ldiag_th("DOWNED", 0.5, "Slot %d liegt: rest=%.1fs near=%s revive=%.1f/%.1f partner=%s" % [
			sl, float(downed_time.get(sl, 0.0)), str(near),
			float(revive_progress.get(sl, 0.0)), REVIVE_TIME,
			str(players.keys())])
		# Runde 111: Liegen ALLE, kann niemand mehr aufwecken -> Run beenden.
		# Vorher lief der Timer ab und die Verbindung riss ab.
		var any_standing := false
		for s3 in players.keys():
			if not bool(downed.get(int(s3), false)):
				any_standing = true
				break
		if not any_standing:
			print("[LAN][GAME OVER] alle Spieler liegen - Run wird beendet")
			if ui_manager != null:
				ui_manager.show_banner("BEIDE BESIEGT", Color(1.0, 0.35, 0.35))
			await get_tree().create_timer(2.0).timeout
			quit_to_menu()
			return
		# Runde 83: Aufwecken nur, solange der Knopf gehalten wird
		if near:
			if ui_manager != null:
				ui_manager.call("show_revive_prompt", true)
				ui_manager.call("set_revive_progress", float(revive_progress.get(sl, 0.0)) / REVIVE_TIME)
			var client_holds: bool = bool(_remote_revive.get(sl, false))
			if _revive_held or client_holds:
				revive_progress[sl] = float(revive_progress.get(sl, 0.0)) + delta
			if float(revive_progress[sl]) >= REVIVE_TIME:
				_revive_player(sl)
				_revive_held = false
				_remote_revive.erase(sl)
				revive_progress[sl] = 0.0
				if ui_manager != null:
					ui_manager.call("show_revive_prompt", false)
				# B18: _revive_player() loescht downed/downed_time. Ohne dieses
				# continue lief derselbe Tick in den "nicht mehr aufweckbar"-Zweig,
				# setzte health=0 und machte den Geretteten zum Zuschauer.
				print("[REVIVE] Slot %d wieder im Spiel (health=%d) - Zuschauer-Zweig uebersprungen"
					% [sl, int(dp.get("health"))])
				continue
		else:
			revive_progress[sl] = 0.0
			_revive_held = false
			if ui_manager != null:
				ui_manager.call("show_revive_prompt", false)
		if not downed.has(sl):
			# B18: waehrend dieses Ticks wiederbelebt -> Timer-Zweig ueberspringen
			continue
		if float(downed_time.get(sl, 0.0)) <= 0.0:
			# Runde 51: Nicht mehr wiederbelebbar. Wenn noch jemand lebt,
			# wird dieser Spieler Zuschauer - sonst ist der Run vorbei.
			var alive_now: Array = _alive_slots()
			if alive_now.is_empty():
				_game_over_multiplayer()
				return
			_make_spectator(sl)

func _alive_slots() -> Array:
	# Runde 51: Wer lebt noch (nicht downed, kein Zuschauer)?
	var out: Array = []
	for s in players.keys():
		var sl: int = int(s)
		if bool(spectator.get(sl, false)):
			continue
		var p = players[sl]
		if is_instance_valid(p) and not bool(downed.get(sl, false)):
			out.append(sl)
	return out


func _make_spectator(sl: int) -> void:
	# Runde 51: Endgueltig tot -> Zuschauer beim ueberlebenden Partner.
	if bool(spectator.get(sl, false)):
		return
	spectator[sl] = true
	downed.erase(sl)
	downed_time.erase(sl)
	revive_progress.erase(sl)
	var ring = _downed_rings.get(sl, null)
	if is_instance_valid(ring):
		ring.queue_free()
	_downed_rings.erase(sl)
	var p = players.get(sl, null)
	if is_instance_valid(p):
		p.set("downed", false)
		p.set("spectating", true)
		p.set("health", 0)
		p.visible = false
		p.set_physics_process(false)
	_ldiag("SPECTATE", "Slot %d endgueltig tot -> Zuschauer (leben: %s)" % [sl, str(_alive_slots())])
	if coop_host and NetManager.active:
		NetManager.h_send_spectator(sl)
	if sl == int(my_slot):
		# Kamera auf den ueberlebenden Partner haengen, damit man nicht auf
		# der eigenen Leiche steht. Dazu ein klarer Zuschauer-Bildschirm.
		var alive: Array = _alive_slots()
		var pname: String = ""
		if alive.size() > 0:
			var partner = players.get(int(alive[0]), null)
			if is_instance_valid(partner):
				var cam = p.get("camera") if p != null else null
				if cam != null and cam is Camera2D:
					cam.reparent(partner)
					cam.position = Vector2.ZERO
					cam.make_current()
					print("[SPEC] Kamera auf Slot %d umgehaengt" % int(alive[0]))
			pname = str(_slot_texture_profile(int(alive[0])).get("name", "PARTNER"))
		ui_manager.call("show_spectator_overlay", true, pname)
		ui_manager.show_banner("DU BIST ZUSCHAUER", Color(0.75, 0.85, 1.0))


func _on_net_spectator(slot: int) -> void:
	# Runde 51: Der Host meldet, dass ein Spieler endgueltig tot ist
	if coop_host:
		return
	_make_spectator(slot)


func _update_downed_ring(slot: int, dp: Node2D) -> void:
	# Runde 35b: sichtbarer HILFE-Ring mit Aufweck-Fortschritt
	var ring = _downed_rings.get(slot, null)
	if not is_instance_valid(ring):
		ring = Sprite2D.new()
		ring.texture = TextureManager.get_texture("glow_common")
		ring.modulate = Color(1.0, 0.35, 0.35, 0.85)
		ring.z_index = 30
		ysort.add_child(ring)
		_downed_rings[slot] = ring
	ring.visible = true
	ring.position = dp.global_position
	var prog: float = clampf(float(revive_progress.get(slot, 0.0)) / REVIVE_TIME, 0.0, 1.0)
	ring.scale = Vector2(0.5 + prog * 0.9, 0.5 + prog * 0.9)
	ring.modulate = Color(1.0, 0.75 - prog * 0.35, 0.3 + prog * 0.5, 0.85)

func _revive_player(slot: int) -> void:
	# Runde 49: Der Host ist autoritativ fuer den Revive und meldet
	# das Ergebnis an alle Clients.
	if coop_host and NetManager.active:
		NetManager.h_send_downed_state(slot, false, 1, 0.0)
	var p = players.get(slot, null)
	if is_instance_valid(p):
		p.set("downed", false)
		p.set("health", maxi(1, int(round(float(p.call("get_max_health")) * 0.6))))
		print("[REVIVE] Slot %d health=%d (max=%d)" % [slot, int(p.get("health")), int(p.call("get_max_health"))])
		if p.has_signal("health_changed"):
			p.emit_signal("health_changed", int(p.get("health")))
		# Runde 86: 2 s Schutz, sonst wird man im Monsterknäuel sofort wieder
		# umgelegt (im Log: revive 2.3/2.5 -> wieder downed mit frischen 30 s).
		p.set("god_mode", true)
		var _guard = p
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(_guard):
				_guard.set("god_mode", false)
				print("[REVIVE] Schutz vorbei slot=%d" % slot))
		print("[REVIVE] Slot %d aufgeweckt, 2 s Schutz" % slot)
	var ring2 = _downed_rings.get(slot, null)
	if is_instance_valid(ring2):
		ring2.queue_free()
	_downed_rings.erase(slot)
	downed.erase(slot)
	downed_time.erase(slot)
	revive_progress.erase(slot)
	ui_manager.show_banner("SPIELER %d IST WIEDER DA" % slot, Color(0.45, 1.0, 0.6))

func _game_over_multiplayer() -> void:
	# Runde 34: niemand mehr aufweckbar -> Run vorbei
	downed.clear()
	downed_time.clear()
	revive_progress.clear()
	spectator.clear()
	if coop_host:
		NetManager.h_send_game_over()
	current_state = GameState.DEAD
	SoundManager.play_death()

func send_ping() -> void:
	# Runde 34: Ping an der eigenen Position
	if not is_instance_valid(player):
		return
	var p: Vector2 = player.global_position
	if coop_client and not coop_host:
		NetManager.c_send_ping(p.x, p.y)
	_show_ping_marker(p.x, p.y)

func _on_net_ping(x: float, y: float) -> void:
	_show_ping_marker(x, y)

func _show_ping_marker(x: float, y: float) -> void:
	var m := Sprite2D.new()
	m.texture = TextureManager.get_texture("glow_common")
	m.modulate = Color(1.0, 0.9, 0.3, 0.9)
	m.position = Vector2(x, y)
	m.scale = Vector2(0.6, 0.6)
	m.z_index = 40
	ysort.add_child(m)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector2(1.8, 1.8), 0.6)
	tw.tween_property(m, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(m.queue_free)

func _on_server_disconnected() -> void:
	# Runde 51: KEINE Host-Migration mehr. Der Client bekommt einen klaren
	# Hinweis und kehrt anschliessend auf die Startseite zurueck.
	if not coop_client:
		return
	_ldiag("NET", "Verbindung zum Host verloren -> Abbruch-Screen")
	coop_client = false
	get_tree().paused = false
	if ui_manager != null:
		ui_manager.show_disconnect_screen("VERBINDUNG ZUM HOST ABGEBROCHEN")

func abort_run_to_start() -> void:
	# Runde 51: Nach einem Verbindungsabbruch sauber auf die Startseite.
	# Alles zuruecksetzen, damit kein halber Co-op-Zustand haengen bleibt.
	_ldiag("NET", "abort_run_to_start (state=%d)" % int(current_state))
	get_tree().paused = false
	lan_mode = false
	coop_host = false
	coop_client = false
	_clear_all_monsters()
	downed.clear()
	downed_time.clear()
	revive_progress.clear()
	spectator.clear()
	_downed_rings.clear()
	NetManager.leave()
	players.clear()
	slot_profiles.clear()
	slot_ready.clear()
	current_state = GameState.MENU
	ui_manager.hide_lobby()
	ui_manager.hide_disconnect_screen()
	ui_manager.show_start_screen()
	_ldiag("NET", "zurueck auf Startseite")


func _clear_all_monsters() -> void:
	for m in _monster_cache:
		if is_instance_valid(m):
			m.queue_free()
	_monster_cache.clear()
	for g in _ghosts.values():
		if is_instance_valid(g):
			g.queue_free()
	_ghosts.clear()

func _recount_wave() -> void: _waves_p()._recount_wave()

func _update_target_arrow() -> void:
	# Runde 31: Pfeil zum letzten Monster (nur Wellen-Modus, nur wenn genau 1 uebrig)
	if ui_manager == null or not ui_manager.has_method("update_target_arrow"):
		return
	if game_mode != 1 or not wave_active or wave_remaining != 1 or player == null:
		ui_manager.update_target_arrow(false, Vector2.ZERO)
		return
	var last: Node2D = null
	for m2 in monster_container.get_children():
		if not is_instance_valid(m2) or m2.is_queued_for_deletion():
			continue
		if not m2.has_method("counts_for_wave"):
			continue
		if m2.get("ghost") == true:
			continue
		# wichtig: das Signal kommt VOR queue_free() - sterbende Monster nicht mitzaehlen
		if int(m2.get("current_health")) <= 0:
			continue
		if not m2.call("counts_for_wave"):
			continue
		last = m2
		break
	if last == null:
		ui_manager.update_target_arrow(false, Vector2.ZERO)
		return
	ui_manager.update_target_arrow(true, last.global_position - player.global_position)

func spawn_monster_at(position: Vector2, mtype: int = -1, as_mini: bool = false): return _spawn_p().spawn_monster_at(position, mtype, as_mini)

func _on_boss_hp(cur: int, mx: int):
	ui_manager.update_boss_hp(cur, mx)

# Werfer-Gegner: gelbe Kugel in Player-Richtung
func spawn_projectile(position: Vector2, dir: Vector2, dmg: int, spd: float, chain: int = 0) -> void: _spawn_p().spawn_projectile(position, dir, dmg, spd, chain)

func spawn_banana(position: Vector2, dir: Vector2, dmg: int, spd: float) -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	proj.call("set_banana", dmg)
	proj.position = position
	proj.set_direction(dir, spd)
	ysort.add_child(proj)

# Splitter: 2 gruenen Minis beim Tod
func spawn_splitter_children(position: Vector2) -> void:
	spawn_monster_at(position + Vector2(-26, 0), 0, true)
	spawn_monster_at(position + Vector2(26, 0), 0, true)

func _xp_factor() -> float:
	# Erd-Mobs ~30 Punkte im Schnitt, Mars ~70, Jungle ~85 -> gleiches Leveltempo
	match active_map:
		"jungle": return 0.34
		"mars": return 0.42
		_: return 1.0

func _mini_boss_type() -> int: return _boss_p()._mini_boss_type()

func _biome_boss_type() -> int: return _boss_p()._biome_boss_type()

func _biome_boss_name() -> String: return _boss_p()._biome_boss_name()

func _spawn_boss() -> void: _boss_p()._spawn_boss()

# ============================================================
# Runde 136 (E): Mini-Boss-Belohnung und Kisten-Drop
# ============================================================
func _mini_boss_display_name(t: int) -> String: return _boss_p()._mini_boss_display_name(t)


func name_miniboss(monster: Node) -> void: _boss_p().name_miniboss(monster)


func spawn_run_chest_at(pos: Vector2, rarity: String = "rare") -> void:
	# v1.40: im RUNDEN-Modus gibt es keine Kisten (auch nicht vom Mini-Boss)
	if game_mode == 2:
		print("[WAVE][KISTE] erlaubt=false aufrufe=1 (Kiste unterdrueckt)")
		return
	_spawn_p().spawn_run_chest_at(pos, rarity)


func on_miniboss_killed(dt: float, pos: Vector2 = Vector2.ZERO) -> void: _boss_p().on_miniboss_killed(dt, pos)


# ============================================================
# Runde 136 (J4): Waffen-Aufnahme mit Seltenheit
# ============================================================
func save_lang() -> void: _prof_p().save_lang()


func on_weapon_pickup(key: String, rar: String, st: Dictionary) -> void:
	var lbl: String = str(st.get("waffe", key)).to_upper()
	var rl: String = "GEWÖHNLICH"
	var col: Color = Color(0.72, 0.74, 0.78)
	match rar:
		"rare":
			rl = "SELTEN"
			col = Color(0.45, 0.72, 1.0)
		"epic":
			rl = "EPISCH"
			col = Color(0.78, 0.50, 1.0)
		"legendary":
			rl = "LEGENDÄR"
			col = Color(1.0, 0.80, 0.30)
	# DPS aus den effektiven Werten (gleiche Formel wie player.dps_of)
	var mag: int = int(st.get("mag", 0))
	var per: float = float(st.get("schaden", 1)) * float(st.get("spread", 1))
	var cd: float = maxf(0.01, float(st.get("tempo", 1.0)))
	var dps: float = per / cd
	if mag > 0:
		dps = (per * float(mag)) / maxf(0.01, float(mag) * cd + float(st.get("reload", 1.0)))
	print("[WPN][PICKUP] waffe=%s stufe=%s dps=%.1f" % [str(st.get("waffe", key)), rar, dps])
	ui_manager.show_banner("%s  ·  %s" % [lbl, rl], col)


func _pick_random_monster_type() -> int: return _spawn_p()._pick_random_monster_type()

# ============================================================
# Runde 50: LAN-DIAGNOSE
# Explizite Logzeilen mit [LAN] fuer die Fehlersuche. Jede Zeile
# nennt Rolle + Slot, damit man Host- und Client-Log direkt
# vergleichen kann.
# ============================================================
const LAN_DIAG := true

func _ldiag(tag: String, msg: String) -> void:
	if not LAN_DIAG:
		return
	var role: String = "HOST" if coop_host else ("CLIENT" if coop_client else "SOLO")
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	print("[LAN][%.2f][%s/%d][%s] %s" % [t, role, my_slot, tag, msg])

# Drossel fuer Logs, die pro Frame kommen wuerden
var _ldiag_t: Dictionary = {}

func _ldiag_th(tag: String, iv: float, msg: String) -> bool:
	if not LAN_DIAG:
		return false
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var last: float = float(_ldiag_t.get(tag, -999.0))
	if now - last < iv:
		return false
	_ldiag_t[tag] = now
	_ldiag(tag, msg)
	return true


# ============================================================
# Runde 52: SHOP-DIAGNOSE
# Gleiches Prinzip wie [LAN]: jede Entscheidung im Shop wird
# geloggt, jeder Abbruch mit EXPLIZITEM Grund.
# ============================================================
const SHOP_DIAG := true

func _sdiag(tag: String, msg: String) -> void:
	if not SHOP_DIAG:
		return
	var role: String = "HOST" if coop_host else ("CLIENT" if coop_client else "SOLO")
	print("[SHOP][%.2f][%s/%d][%s] %s" % [
		float(Time.get_ticks_msec()) / 1000.0, role, my_slot, tag, msg])

func _shop_offer_ids() -> Array:
	var out: Array = []
	for o in shop_offers:
		out.append(str(o.get("id", "?")))
	return out

# ============================================================
# Runde 53: BOSS-/MONSTER-DIAGNOSE
# Jede Boss-Entscheidung wird geloggt: Spawn, HP, Tod, Banner,
# Texturen. Jede Ablehnung mit explizitem Grund.
# ============================================================
const BOSS_DIAG := true

func _bdiag(tag: String, msg: String) -> void:
	if not BOSS_DIAG:
		return
	print("[BOSS][%.2f][%s|Welle %d][%s] %s" % [
		float(Time.get_ticks_msec()) / 1000.0, active_map, wave, tag, msg])


func _upgrade_options() -> Array: return _upg_p()._upgrade_options()


func _open_upgrade_ui() -> void: _upg_p()._open_upgrade_ui()


func _on_upgrade_earned() -> void: _upg_p()._on_upgrade_earned()


func _on_upgrade_toast_tapped() -> void: _upg_p()._on_upgrade_toast_tapped()

func _on_upgrade_chosen(id: String) -> void: _upg_p()._on_upgrade_chosen(id)


func _apply_upgrade_local(id: String) -> void: _upg_p()._apply_upgrade_local(id)


func _on_net_upgrade_applied(slot: int, id: String) -> void:
	# Runde 49: Der Client bekommt die bestaetigte Upgrade-Wahl
	_ldiag("UPGRADE", "Client bekam Bestaetigung '%s' fuer Slot %d (pending=%d)" % [id, slot, pending_upgrades])
	_apply_upgrade_local(id)
	pending_upgrades = maxi(0, pending_upgrades - 1)
	if pending_upgrades > 0 and current_state == GameState.PLAYING:
		_open_upgrade_ui()
	else:
		in_upgrade = false
		if coop_client and NetManager.active:
			NetManager.c_send_busy(false)
		_ldiag("UPGRADE", "Client schliesst Karten -> tree.paused=false")
		get_tree().paused = false


func _on_net_upgrade_options(opts: Array) -> void:
	# Runde 49: Der Client oeffnet das Upgrade-Fenster mit den
	# Optionen des Hosts
	if opts.is_empty():
		_ldiag("UPGRADE", "Client bekam LEERE Optionen - ignoriert")
		return
	if _should_pause_for_cards():
		_ldiag("UPGRADE", "Client oeffnet Karten (%d) -> tree.paused=true" % opts.size())
		get_tree().paused = true
	else:
		in_upgrade = true
		if coop_client and NetManager.active:
			NetManager.c_send_busy(true)
		print("[B3][PAUSE] Client waehlt Karten - Welt laeuft weiter, Slot %d geschuetzt" % int(my_slot))
	ui_manager.show_upgrade_cards(opts)

func _on_monster_killed(points: int, owner_slot: int = 0, monster_pos: Vector2 = Vector2.ZERO):
	bal_kills += 1
	# Runde 33: Cache bereinigen (tote Monster raus)
	var _clean: Array = []
	for _m in _monster_cache:
		if is_instance_valid(_m) and not _m.is_queued_for_deletion():
			_clean.append(_m)
	_monster_cache = _clean
	# Combo: Kills innerhalb des Fensters stapeln den Multiplikator
	if combo_count > 0:
		combo_count += 1
	else:
		combo_count = 1
	combo_timer = COMBO_WINDOW
	var mult := clampf(1.0 + 0.25 * float(combo_count - 1), 1.0, 5.0)
	var gained := int(round(float(points) * mult))
	if gold_time > 0.0:
		gained *= 2                      # Goldrausch-Event
	score += gained
	# RUNDEN-Modus (v1.40): Muenzen pro Kill + Wellen-Label
	if game_mode == 2:
		var _chal_coins: int = int(_rm().on_kill(points))
		# v1.46 (B2): KOPFGELD (Kills) und GOLDRAUSCH (Muenzen) zaehlen.
		if chal_active and chal_run != null:
			chal_run.on_kill(_chal_coins)
	# Wellen-Modus: Münzen für den Shop (Punkt 6)
	if game_mode == 1:
		# Runde 31: exakt nachzaehlen (Pflanzen/Ranken zaehlen nicht mit)
		_recount_wave()
		# Runde 33: Muenzen dem Schuetzen zuordnen (Variante B)
		var _slot: int = owner_slot if owner_slot > 0 else my_slot
		# Runde 49c: 0.5 -> 0.24. Vorher bekam man pro Welle so
		# viel Gold, dass der ganze Shop auf einmal kaufbar war.
		var _gain: int = maxi(1, int(round(float(points) * 0.24 * float(diff_data()["coins"]))))
		# Runde 39: Kills INNERHALB eines Kraftfeldes bringen 50 % extra Muenzen
		for zf in force_fields:
			if is_instance_valid(zf):
				var _fr: float = float(zf.get_meta("ff_r", 150.0))
				if zf.global_position.distance_to(monster_pos) < _fr:
					_gain = int(round(float(_gain) * 1.5))
					break
		slot_coins[_slot] = int(slot_coins.get(_slot, 0)) + _gain
		if _slot == my_slot:
			coins = int(slot_coins[my_slot])
		ui_manager.update_wave_label(wave, coins, in_shop, shop_time, wave_remaining)
	ui_manager.update_score(score)
	ui_manager.update_combo(combo_count, mult)
	_check_biome()

	# XP (Runde 3)
	# Runde 27: XP pro Karte normalisieren - Jungle-/Mars-Mobs geben viel mehr
	# Punkte, dadurch sprang man pro Kill mehrere Level hoch
	var pts: int = maxi(1, int(round(float(points) * _xp_factor())))
	run_xp += pts
	xp += pts
	while xp >= xp_needed:
		xp -= xp_needed
		# Runde 49c: Wachstum 12 -> 24, damit die Upgrades
		# seltener werden.
		xp_needed += maxi(12, int(round(24.0 * xp_multiplier())))
		level += 1
		if game_mode == 0:
			pending_upgrades += 1
		elif not _wave_upgrade_hint_shown:
			_wave_upgrade_hint_shown = true
			ui_manager.show_banner("WELLEN-MODUS: UPGRADES NUR IM SHOP", Color(0.55, 0.95, 1.0))
	ui_manager.update_xp(level, xp, xp_needed)
	_check_map_gates()
	_check_season_gates()
	_check_season()
	var need := _switch_need()
	ui_manager.update_switch_hint(_switch_hint_text(), run_xp, need)
	if is_instance_valid(player):
		player.call("on_kill")
	if pending_upgrades > 0 and current_state == GameState.PLAYING:
		_open_upgrade_ui()

# --- Biome (G4) -------------------------------------------------------------
# v1.42 (P9): Feste Maps bleiben in ihrem Biom. Die Reise-Map ERDE wechselt
# nur an Rundengrenzen und nur nach festem Plan - nie mitten in einer Welle,
# und nie, wenn die Jahreszeit auf "fest" steht.
const BIOME_PLAN_ROUNDS := [1, 6, 11, 16]
const BIOME_PLAN_IDS := ["meadow", "desert", "ice", "lava"]
var biome_changes: int = 0
# v1.42 (P10): Uebergangs-Flash beim Biomwechsel (abschaltbar)
var biome_flash_on: bool = true
var _biome_flash_layer: CanvasLayer = null
var _biome_flash_rect: ColorRect = null


func _biome_progressive() -> bool:
	# v1.42 (P9): Reise-Maps (ERDE) wechseln nach Plan, alle anderen bleiben
	# in ihrem Biom. Die Jahreszeit (season_mode) steuert NUR Farbe/Wetter -
	# sie darf das Biom nicht mehr mitziehen (P9.4).
	var md := map_data()
	return bool(md.get("progressive", true))


func _biome_plan_text() -> String:
	if not bool(map_data().get("progressive", true)):
		return ""
	return "wechsel_bei_runde=%s biome=%s" % [
		",".join(_int_list(BIOME_PLAN_ROUNDS)), ",".join(BIOME_PLAN_IDS)]


func _int_list(a: Array) -> Array:
	var out: Array = []
	for v in a:
		out.append(str(int(v)))
	return out


func _round_no_now() -> int:
	var rm = get("rounds_mode")
	if game_mode == 2 and rm != null:
		return int(rm.get("round_no"))
	return wave


func _log_biome_state(tag: String) -> void:
	print("[BIOME][WECHSEL] anzahl=%d biome=%s modus=%s runde=%d ausloeser=%s" % [
		biome_changes, biome_id, active_map, _round_no_now(), tag])


func _check_biome() -> void:
	var want_fixed := str(map_data()["biome"])
	if not _biome_progressive():
		if biome_id != want_fixed:
			print("[BIOME][KORREKTUR] map=%s von=%s nach=%s grund=fest" % [
				active_map, biome_id, want_fixed])
			biome_id = want_fixed
			map_generator.set_biome(biome_id)
		return
	# Reise-Map: Plan lesen, nur an der Rundengrenze wechseln
	var rn: int = _round_no_now()
	if wave_active and game_mode != 2:
		return
	var idx: int = BIOME_PLAN_ROUNDS.find(rn)
	if idx < 0:
		return
	var want: String = str(BIOME_PLAN_IDS[idx])
	if want == biome_id:
		return
	var von: String = biome_id
	biome_id = want
	biome_changes += 1
	_biome_transition(want, rn)
	monster_spawner.spawn_interval = maxf(2.5, monster_spawner.spawn_interval * 0.9)
	ui_manager.show_banner(_biome_name(want), _biome_color(want))
	SoundManager.play("levelup")
	print("[BIOME][WECHSEL] runde=%d von=%s nach=%s ausloeser=rundengrenze" % [rn, von, want])

func _biome_transition(want: String, runde: int) -> void:
	# v1.42 (P10): Weltaufbau messen, Spiel anhalten und - wenn es laenger als
	# 40 ms dauert - einen kurzen Flash darueber legen, damit der Haenger nicht
	# als Ruckler auffaellt.
	var t0: int = Time.get_ticks_msec()
	var was_paused: bool = get_tree().paused
	get_tree().paused = true
	if biome_flash_on:
		_biome_flash_in()
	map_generator.set_biome(want)
	var ms: int = Time.get_ticks_msec() - t0
	print("[PERF][BIOM] aufbau_ms=%d frame_max_ms=%.1f runde=%d" % [
		ms, float(ms), runde])
	if not biome_flash_on:
		print("[FX][BIOM] option=aus overlay=false")
	elif ms < 40:
		print("[FX][BIOM] flash=aus grund=schnell aufbau_ms=%d" % ms)
		_biome_flash_out(true)
	else:
		print("[FX][BIOM] flash=weiss dauer=0.35s overlay=true aufbau_ms=%d" % ms)
		_biome_flash_out(false)
	if not was_paused:
		get_tree().paused = false


func _biome_flash_in() -> void:
	if _biome_flash_layer != null and is_instance_valid(_biome_flash_layer):
		return
	_biome_flash_layer = CanvasLayer.new()
	_biome_flash_layer.name = "BiomFlash"
	_biome_flash_layer.layer = 150
	_biome_flash_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_biome_flash_layer)
	_biome_flash_rect = ColorRect.new()
	_biome_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_biome_flash_rect.color = Color(1, 1, 1, 0.0)
	_biome_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_biome_flash_layer.add_child(_biome_flash_rect)


func _biome_flash_out(sofort: bool) -> void:
	if _biome_flash_rect == null or not is_instance_valid(_biome_flash_rect):
		return
	if sofort:
		_biome_flash_rect.color = Color(1, 1, 1, 0.0)
		_free_flash()
		return
	# Einblenden in 0,35 s, dann 0,25 s ausblenden
	var tw: Tween = create_tween()
	tw.set_parallel(false)
	tw.tween_property(_biome_flash_rect, "color:a", 0.92, 0.18)
	tw.tween_property(_biome_flash_rect, "color:a", 0.92, 0.17)
	tw.tween_property(_biome_flash_rect, "color:a", 0.0, 0.25)
	tw.tween_callback(_free_flash)


func _free_flash() -> void:
	if _biome_flash_layer != null and is_instance_valid(_biome_flash_layer):
		_biome_flash_layer.queue_free()
	_biome_flash_layer = null
	_biome_flash_rect = null


func set_biome_flash(on: bool) -> void:
	biome_flash_on = on
	_save_profile()
	print("[FX][BIOM] option=%s overlay=%s" % ["an" if on else "aus", str(on)])


func _biome_name(id: String) -> String:
	match id:
		"desert":
			return "WUESTE"
		"ice":
			return "EISFELD"
		"lava":
			return "LAVAHOELLE"
	return "WIESE"

func _biome_color(id: String) -> Color:
	match id:
		"desert":
			return Color(0.95, 0.80, 0.35)
		"ice":
			return Color(0.55, 0.85, 1.0)
		"lava":
			return Color(1.0, 0.45, 0.25)
	return Color(0.55, 0.95, 0.60)

func get_biome() -> String:
	return biome_id

func get_biome_tint() -> Color:
	match biome_id:
		"desert":
			return Color(1.0, 0.96, 0.86)
		"ice":
			return Color(0.88, 0.96, 1.0)
		"lava":
			return Color(1.0, 0.86, 0.80)
	return Color(1, 1, 1)

func is_frozen() -> bool:
	return freeze_time > 0.0

# --- Punkt 4/5: Boss-Beschwörung, Golem-Verlangsamung, Kartengrenzen ---
func spawn_boss_minions(pos: Vector2) -> void:
	# Runde 16: Beschwoerung nutzt die Monster des aktuellen Bioms
	for i in range(3):
		var a := randf_range(0.0, TAU)
		spawn_monster_at(pos + Vector2(cos(a), sin(a)) * randf_range(70.0, 120.0), _pick_random_monster_type(), true)
	ui_manager.show_banner("DER BOSS BESCHWOERT HILFE!", Color(0.85, 0.4, 1.0))

func apply_player_slow_to(who: Node, dur: float) -> void:
	if is_instance_valid(who) and who.has_method("apply_slow"):
		who.call("apply_slow", dur)

func get_map_bounds() -> Rect2:
	return map_generator.get_bounds()

# ---------------- Grafikstufen ----------------
func _apply_quality() -> void:
	var fx = get_node_or_null("PostFX")
	if fx:
		fx.visible = quality >= 2              # Soft-Look-Shader nur auf HOCH
	map_generator.detail_level = quality       # Bodendetails
	map_generator.rebuild_visuals()
	# Runde 16 (C1): Grafikstufe darf das Gameplay NICHT veraendern.
	# Gegnerzahl, Zonen und Schwierigkeit sind auf jeder Stufe identisch.
	if false:
		monster_spawner.quality_mult = 1.40
		monster_spawner.max_monsters = 55
	elif quality == 1:
		monster_spawner.quality_mult = 1.0
		monster_spawner.max_monsters = 110
	else:
		monster_spawner.quality_mult = 1.0
		monster_spawner.max_monsters = 150
	if ui_manager:
		ui_manager.set_quality_label(str(QUALITY_NAMES[quality]))

func cycle_quality() -> void:
	quality = (quality + 1) % 3
	_apply_quality()
	_save_high_score()

func set_quality(i: int) -> void:
	quality = clampi(i, 0, 2)
	_apply_quality()
	_save_high_score()

func get_quality() -> int:
	return quality

func toggle_fps() -> void:
	debug_fps = not debug_fps
	ui_manager.set_fps_label(debug_fps)
	_save_high_score()

# ---------------- Zufalls-Events ----------------
func _trigger_random_event() -> void:
	# v1.41 (F1): im RUNDEN-Modus gibt es KEINE Zufalls-Events. Die Events
	# spawnen Monster, die nicht in `alive` der Runde zaehlen - die Runde
	# haette dadurch falsch beendet (oder nie beendet).
	if game_mode == 2:
		_event_blocked = int(_event_blocked) + 1
		print("[WAVE][EVENT] erlaubt=false modus=runden blockiert=%d" % int(_event_blocked))
		return
	if not is_instance_valid(player):
		return
	# v1.56 (Spec K1/K2): Zufalls-Events laufen DURCH das Balance-Modell.
	# Vorher spawnte "Monstersturm" fest 14 Gegner und "Elitewelle" 3 ORANGE +
	# 3 geteilte PURPLE - ohne Bezug zum Druck und ohne Ruecksicht auf das
	# Erholungsfenster. Genau diese Spitzen waren der unerklaerte "sofort tot"-
	# Effekt (Messung v1.56: Tod bei aktiv=0-2 Feldgegnern).
	var sp = monster_spawner
	var st_ev: String = Balance.stufe_von_index(int(difficulty))
	var phase_ev: String = str(sp.get("phase")) if sp != null else "peak"
	if phase_ev == "erholung":
		print("[BAL][EVENT] blockiert grund=phase phase=erholung (Fenster ist heilig)")
		return
	var t_ev: float = float(sp.get("t")) if sp != null else 0.0
	var platz: int = maxi(0, Balance.max_aktiv(st_ev) - get_tree().get_nodes_in_group("monsters").size())
	var ziel_ev: float = Balance.ziel_druck("endlos", st_ev, t_ev) * 2.5          # Event = kurzer Peak
	var hpm_ev: float = Balance.hp_mult(1 + int(t_ev / 45.0), st_ev)
	var ev: String = EVENTS[randi() % EVENTS.size()]
	print("[BAL][EVENT] art=%s stufe=%s phase=%s platz=%d druck_ziel=%.2f t=%.0f" % [ev, st_ev, phase_ev, platz, ziel_ev, t_ev])
	match ev:
		"swarm":
			var n_sw: int = mini(platz, Balance.anzahl_fuer_druck(ziel_ev, hpm_ev, 4.0))
			ui_manager.show_banner("MONSTERSTURM!", Color(1.0, 0.45, 0.35))
			for i in range(n_sw):
				var a := randf_range(0.0, TAU)
				spawn_monster_at(player.position + Vector2(cos(a), sin(a)) * randf_range(420.0, 620.0))
			print("[BAL][EVENT] art=swarm gespawnt=%d (Modell statt 14)" % n_sw)
		"elite":
			var n_el: int = mini(2, maxi(0, platz - 1))
			ui_manager.show_banner("ELITEWELLE!", Color(0.85, 0.55, 1.0))
			for i in range(n_el):
				var a2 := randf_range(0.0, TAU)
				spawn_monster_at(player.position + Vector2(cos(a2), sin(a2)) * randf_range(420.0, 620.0), 6)
			for i in range(n_el):
				var a3 := randf_range(0.0, TAU)
				spawn_monster_at(player.position + Vector2(cos(a3), sin(a3)) * randf_range(420.0, 620.0), 3)
			print("[BAL][EVENT] art=elite gespawnt=%d (Modell statt 3+3)" % (n_el * 2))
		"lootrain":
			ui_manager.show_banner("LOOTREGEN!", Color(1.0, 0.85, 0.35))
			for i in range(8):
				var a4 := randf_range(0.0, TAU)
				_spawn_random_loot(player.position + Vector2(cos(a4), sin(a4)) * randf_range(140.0, 340.0))
		"frost":
			freeze_time = maxf(freeze_time, 6.0)
			ui_manager.show_banner("FROSTSTURM!", Color(0.55, 0.90, 1.0))
		"gold":
			gold_time = 12.0
			ui_manager.show_banner("GOLDRAUSCH! doppelte Punkte", Color(1.0, 0.85, 0.20))
	SoundManager.play("boss")

func _spawn_random_loot(pos: Vector2) -> void:
	var keys := ["heart", "shield", "maxhealth", "freeze", "rapid",
		"weapon_pistol", "weapon_shotgun", "weapon_machine", "weapon_laser", "weapon_revolver"]
	var key: String = keys[randi() % keys.size()]
	var r := randf()
	var rar := "common"
	if r > 0.90:
		rar = "epic"
	elif r > 0.60:
		rar = "rare"
	_on_chest_item_spawned(key, pos, rar)

# --- Soft-Look Post-Processing (Shader) ---
func _setup_post_process() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PostFX"
	layer.layer = 1                       # ueber der Welt, unter dem HUD (HUD = Layer 2)
	var rect := ColorRect.new()
	rect.name = "SoftLook"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = load("res://shaders/soft_look.gdshader")
	if sh != null:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		rect.material = mat
	layer.add_child(rect)
	add_child(layer)

func _on_monster_damage_player(damage: int):
	# v1.56: Treffer zaehlen (Bot-Proxy: "Treffer/60 s" aus Spec 3.1)
	bal_treffer += 1
	if is_instance_valid(player):
		player.call("take_damage", damage)

func _bal_treffer(n: int) -> void:
	bal_treffer += maxi(0, int(n))

func _bal_dmg(n: int) -> void:
	# v1.56: ausgeteilter Schaden (Hook in monster_ai.take_damage)
	bal_schaden += maxi(0, int(n))

func bal_reset_zaehler() -> void:
	bal_treffer = 0
	bal_schaden = 0
	bal_kills = 0

func restart_game(direct_start: bool = false):
	# Sicherheitsnetz: Pause & Karten-Overlay aufraeumen
	if get_tree().paused:
		get_tree().paused = false
	ui_manager.hide_upgrade_cards()
	# v1.48 (E2): auch den Toast entfernen - er blieb nach dem Run stehen
	# und tauchte im naechsten Modus wieder auf.
	ui_manager.hide_upgrade_toast()
	pending_upgrades = 0
	# Alle Container bereinigen
	for child in monster_container.get_children():
		child.queue_free()
	for child in chest_container.get_children():
		child.queue_free()
	for child in item_container.get_children():
		child.queue_free()

	# Spieler entfernen
	if is_instance_valid(player):
		player.queue_free()
		player = null
	if is_instance_valid(player2):
		player2.queue_free()
		player2 = null
	for z in zones:
		if is_instance_valid(z):
			z.queue_free()
	zones.clear()

	# Karte bereinigen
	map_generator.clear_map()

	# Monster-Spawner stoppen
	monster_spawner.stop_spawning()

	# Buffs/Boss/Biom zuruecksetzen
	freeze_time = 0.0
	rapid_time = 0.0
	current_boss = null
	_boss_active = false
	biome_id = "meadow"

	# LAN-Sitzung beenden + Partner entfernen
	clear_partner()
	if NetManager.active:
		NetManager.leave()
	lan_mode = false
	# Co-op-Zustand zuruecksetzen
	coop_host = false
	coop_client = false
	NetManager.coop_role = 0
	_net_seed = 0
	_pending_client_start = false
	for id in _ghosts.keys():
		if is_instance_valid(_ghosts[id]):
			_ghosts[id].queue_free()
	_ghosts.clear()
	for id in _item_ghosts.keys():
		if is_instance_valid(_item_ghosts[id]):
			_item_ghosts[id].queue_free()
	_item_ghosts.clear()

	# Projektile/Effekte ausserhalb der Container aufraeumen (Leak-Fix)
	for p in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(p):
			p.queue_free()

	# UI zurücksetzen
	ui_manager.register_references(self, null)
	_setup_initial_state()
	if direct_start:
		start_game(false, false)

func exit_game():
	get_tree().quit()

func get_player_position() -> Vector2:
	if is_instance_valid(player):
		return player.position
	return Vector2.ZERO

func _load_high_score():
	var save_path = "user://savegame.save"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			high_score = file.get_32()
			# Grafikstufe (aeltere Speicherstaende haben das Feld nicht)
			if file.get_position() + 4 <= file.get_length():
				quality = clampi(file.get_32(), 0, 2)
			if file.get_position() + 4 <= file.get_length():
				debug_fps = file.get_32() == 1
			var cfg_ver := 0
			if file.get_position() + 4 <= file.get_length():
				cfg_ver = file.get_32()
			if cfg_ver < CONFIG_VERSION:
				quality = 1        # einmalig auf MITTEL (60 FPS) umstellen
			# Runde 62: Musik- und Effekt-Schalter (aeltere Saves haben sie nicht)
			if file.get_position() + 4 <= file.get_length():
				SoundManager.set_music_enabled(file.get_32() == 1)
			if file.get_position() + 4 <= file.get_length():
				SoundManager.set_sfx_enabled(file.get_32() == 1)
			if file.get_position() + 4 <= file.get_length():
				gems = maxi(0, file.get_32())
			file.close()

func _save_high_score():
	var save_path = "user://savegame.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.store_32(quality)
		file.store_32(1 if debug_fps else 0)
		file.store_32(CONFIG_VERSION)
		file.store_32(1 if SoundManager.music_on else 0)
		file.store_32(1 if SoundManager.sfx_on else 0)
		file.store_32(gems)
		file.close()


# ============================================================
# Runde 67: Edelsteine, Umtausch und Kosmetik-Kisten
# ============================================================

const GEM_PACKAGES := [
	{ "gold": 1000, "gems": 1 },
	{ "gold": 10000, "gems": 12 },
]


func _cosmetic_catalog() -> Array: return _prof_p()._cosmetic_catalog()


func _owned_map() -> Dictionary:
	return { "hat": unlocked_hats, "skin": unlocked_rigs, "color": unlocked_colors }


# ---------------------------------------------------------------
# v1.49 (A1.7): Der Vorab-Kauf ("Portionen") ist komplett entfernt.
# Er hat in mehreren Modi Abstuerze verursacht (Utility-Listen des Spielers
# wurden vor dem ersten Frame befuellt) und doppelte Werte erzeugt.
# ---------------------------------------------------------------


func exchange_gold_for_gems(pkg_index: int) -> bool:
	if pkg_index < 0 or pkg_index >= GEM_PACKAGES.size():
		print("[SHOP][GEMS] FEHLER: unbekanntes Paket %d" % pkg_index)
		return false
	var pkg: Dictionary = GEM_PACKAGES[pkg_index]
	var need: int = int(pkg["gold"])
	var give: int = int(pkg["gems"])
	if gold < need:
		print("[SHOP][GEMS] FEHLER: zu wenig Gold (%d von %d)" % [gold, need])
		return false
	gold -= need
	gems += give
	_save_profile()
	ui_manager.refresh_shop_ui()
	print("[SHOP][GEMS] exchange %d gold -> %d gems (gems=%d, gold=%d)" % [need, give, gems, gold])
	return true


func buy_chest(chest_id: String) -> Dictionary:
	var cost: int = LootTable.chest_cost(chest_id)
	if cost <= 0:
		print("[CHEST] FEHLER: unbekannte Kiste '%s'" % chest_id)
		return { "ok": false, "error": "unbekannte Kiste" }
	if gems < cost:
		print("[CHEST] FEHLER: zu wenig Edelsteine (%d von %d)" % [gems, cost])
		return { "ok": false, "error": "zu wenig Edelsteine" }
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var res: Dictionary = LootTable.roll(chest_id, _cosmetic_catalog(), _owned_map(), rng)
	if not bool(res.get("ok", false)):
		print("[CHEST] FEHLER: %s" % str(res.get("error", "?")))
		return res
	gems -= cost
	# v1.52: Bonus je Seltenheit buchen (Niete bekommt keinen Bonus)
	if str(res.get("kind", "")) != "none":
		res = _apply_chest_bonus(res)
	else:
		res["bonus"] = { "gold": 0, "gems": 0 }
	var kind := str(res["kind"])
	var idx := int(res["index"])
	if kind == "none":
		print("[CHEST] open kind=%s cost=%d -> NIETE (nichts) gems=%d" % [chest_id, cost, gems])
		chests_opened += 1
		_save_profile()
		return res
	if kind == "gems":
		var g_add: int = int(res.get("gems", 0))
		gems += g_add
		print("[CHEST] open kind=%s cost=%d -> Trostpreis EDELSTEINE +%d (gems=%d)" % [chest_id, cost, g_add, gems])
		chests_opened += 1
		_save_profile()
		return res
	if kind == "gold":
		var g_add: int = int(res.get("gold", 0))
		gold += g_add
		print("[CHEST] open kind=%s cost=%d -> Trostpreis GOLD +%d (gold=%d)" % [chest_id, cost, g_add, gold])
		chests_opened += 1
		_save_profile()
		return res
	if bool(res["duplicate"]):
		var refund: int = int(res["refund"])
		gems += refund
		print("[CHEST] open kind=%s cost=%d -> item=%s_%d rarity=%s duplicate=true refund=%d" % [
			chest_id, cost, kind, idx, str(res["rarity"]), refund])
	else:
		match kind:
			"hat":
				if not unlocked_hats.has(idx):
					unlocked_hats.append(idx)
			"skin":
				if not unlocked_rigs.has(idx):
					unlocked_rigs.append(idx)
			"color":
				if not unlocked_colors.has(idx):
					unlocked_colors.append(idx)
		print("[CHEST] open kind=%s cost=%d -> item=%s_%d rarity=%s duplicate=false refund=0" % [
			chest_id, cost, kind, idx, str(res["rarity"])])
	chests_opened += 1
	_save_profile()
	print("[CHEST] Kontostand: gems=%d  geoeffnet=%d" % [gems, chests_opened])
	return res


func set_music_setting(on: bool) -> void:
	SoundManager.set_music_enabled(on)
	_save_high_score()
	print("[SETTINGS] Musik %s" % ("AN" if on else "AUS"))


func set_sfx_setting(on: bool) -> void:
	SoundManager.set_sfx_enabled(on)
	_save_high_score()
	print("[SETTINGS] Soundeffekte %s" % ("AN" if on else "AUS"))


# ============================================================
# Runde 49: LAN-Handler fuer Upgrade / Game-Over / Revive
# ============================================================


func _on_net_upgrade_choice(slot: int, id: String) -> void:
	# Der HOST bekommt die Wahl eines Clients und bestaetigt sie
	if not coop_host:
		return
	_apply_upgrade_local(id)
	NetManager.h_send_upgrade_applied(slot, id)


func _on_net_game_over_data(score_v: int, best_v: int, gold_gain: int, gold_total: int) -> void:
	# Der CLIENT bekommt den Run-Verlust und zeigt den Death-Screen
	if coop_host:
		return
	ui_manager.show_death_screen(score_v, best_v, gold_gain, gold_total)


func _on_net_downed_state(slot: int, is_downed: bool, hp: int, progress: float) -> void:
	# Der CLIENT uebernimmt den Downed/Revive-Zustand des Partners
	if coop_host:
		return
	_ldiag_th("DOWNED_CL", 0.5, "Client: Slot %d downed=%s hp=%d revive=%.1f" % [slot, str(is_downed), hp, progress])
	var p = players.get(slot, null)
	if not is_instance_valid(p):
		return
	p.set("downed", is_downed)
	p.set("health", hp)
	if p.has_signal("health_changed"):
		p.emit_signal("health_changed", hp)
	# Runde 49: Der Spieler bleibt SICHTBAR (halbtransparent), er wird
	# nicht versteckt - vorher verschwand er vom Feld.
	p.set("visible", true)
	if is_downed:
		p.set("modulate", Color(1.0, 1.0, 1.0, 0.45))
	else:
		p.set("modulate", Color(1, 1, 1, 1))
	revive_progress[slot] = progress


# ============================================================
# Runde 49: Test-Hook (temporaer) - LAN-Sync pruefen
# ============================================================


var _prof: ProfileModule = null

func _prof_p() -> ProfileModule:
	if _prof == null:
		_prof = ProfileModule.new()
		_prof.host = self
	return _prof


var _seas: SeasonsModule = null

func _seas_p() -> SeasonsModule:
	if _seas == null:
		_seas = SeasonsModule.new()
		_seas.host = self
	return _seas


var _upg: UpgradesModule = null

func _upg_p() -> UpgradesModule:
	if _upg == null:
		_upg = UpgradesModule.new()
		_upg.host = self
	return _upg


var _waves: WavesModule = null

func _waves_p() -> WavesModule:
	if _waves == null:
		_waves = WavesModule.new()
		_waves.host = self
	return _waves


var _boss: BossesModule = null

func _boss_p() -> BossesModule:
	if _boss == null:
		_boss = BossesModule.new()
		_boss.host = self
	return _boss


var _spawn: SpawnApi = null

func _spawn_p() -> SpawnApi:
	if _spawn == null:
		_spawn = SpawnApi.new()
		_spawn.host = self
	return _spawn


var _shopl: ShopLogic = null

func _shopl_p() -> ShopLogic:
	if _shopl == null:
		_shopl = ShopLogic.new()
		_shopl.host = self
	return _shopl
