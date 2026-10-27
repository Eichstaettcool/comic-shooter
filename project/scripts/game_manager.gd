# GameManager.gd - Zentraler Spiel-Controller
# Verwaltet Spielzustände, Score, Map, Monster-Spawning und UI-Übergänge
extends Node2D

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
const CONFIG_VERSION := 2
var debug_fps: bool = false

# Zufalls-Events
var event_timer: float = 55.0
var gold_time: float = 0.0
const EVENTS := ["swarm", "elite", "lootrain", "frost", "gold"]

# ---------------- CO-OP (LAN Phase 2): eine gemeinsame Welt ----------------
var coop_host: bool = false           # dieser Rechner simuliert die Welt
var coop_client: bool = false         # dieser Rechner rendert + sendet Input
var _net_seed: int = 0
var _net_biome: String = "meadow"
var _net_chests: PackedFloat32Array = PackedFloat32Array()
var _net_zones: PackedFloat32Array = PackedFloat32Array()
var _pending_client_start: bool = false
var _host_chests: PackedFloat32Array = PackedFloat32Array()
var _host_zones: PackedFloat32Array = PackedFloat32Array()
var _ghosts: Dictionary = {}          # net_id -> Monster-Geist (Client)
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
const REVIVE_TIME := 2.5                # Sekunden Nachbarschaft zum Aufwecken
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
var game_mode: int = 0            # 0 = Endlos, 1 = Wellen
var wave: int = 0
var wave_active: bool = false
var in_shop: bool = false
var shop_time: float = 0.0
var coins: int = 0
var coins_bounty: int = 1          # Kopfgeld-Boost: doppelte Run-Muenzen
var run_xp: int = 0                # XP dieses Runs (Kartenschalter, Runde 12)
var best_run_xp: int = 0
var wave_remaining: int = 0       # zählt lebende Wellen-Monster (inkl. Splitter-Kinder)
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

func _start_wave() -> void:
	# Sicherheitsnetz: eine bereits laufende Welle nicht erneut starten
	if wave_active:
		return
	wave += 1
	wave_active = true
	in_shop = false
	wave_remaining = 0
	wave_start_level = level          # Runde 33: Level-Aufstiege dieser Welle zaehlen
	shop_ready.clear()
	slot_coins[my_slot] = coins
	ui_manager.hide_shop()
	var count := mini(48, int(round(float(mini(40, 5 + wave * 3)) * float(diff_data()["spawn"]))))
	var center: Vector2 = Vector2.ZERO
	if is_instance_valid(player):
		center = player.global_position
	else:
		center = map_generator.get_center()
	for i in range(count):
		spawn_monster_at(_wave_spawn_pos(center), _pick_random_monster_type())
	# Runde 38: Kraftfelder ab Welle 7 (alle 3 Wellen + nach jeder Boss-Welle)
	if wave >= 7 and (wave % 3 == 0 or wave % 10 == 0 or wave % 5 == 0):
		_spawn_force_field()
		# Runde 39: ab Welle 12 kommen mehrere Felder gleichzeitig
		if wave >= 12 and wave % 2 == 0:
			_spawn_force_field()
		if wave >= 20 and wave % 3 == 0:
			_spawn_force_field()
	# Runde 16 (B3): Mini-Boss alle 5 Wellen, Riesen-Biom-Boss alle 10
	if wave % 5 == 0:
		var is_giant: bool = (wave % 10 == 0)
		var btype: int = _biome_boss_type() if is_giant else _mini_boss_type()
		# Runde 49c: Der neue Boss MUSS IMMER gespawnt werden.
		# Vorher stand der Spawn in der if-Bedingung - dadurch wurde
		# ueberhaupt KEIN Boss erzeugt, wenn noch keiner lebte. Genau
		# das war der Fehler: der Mini-Boss (Welle 5) und der
		# Riesen-Boss (Welle 10) waren dadurch unsichtbar, und der
		# Endlos-Boss verschwand beim Wellenstart wieder.
		# Nur der ALTE Boss wird entfernt - der neue kommt immer.
		if current_boss != null and is_instance_valid(current_boss) and not current_boss.is_queued_for_deletion():
			current_boss.queue_free()
		current_boss = spawn_monster_at(_wave_spawn_pos(center, true), btype)
		# Runde 53: Dieser Pfad setzte _boss_active NICHT - dadurch feuerte
		# beim Tod eines Wellen-/Mini-Bosses nie das Defeat-Handling
		# (kein "BOSS BESIEGT", Bossbar blieb stehen).
		_boss_active = current_boss != null
		if current_boss != null:
			_boss_last_type = str(current_boss.get("type"))
			_bdiag("SPAWN", "Wellen-Boss Welle %d type=%d %s hp=%d/%d map=%s biome=%s" % [
				wave, btype, ("RIESE" if is_giant else "MINI"),
				int(current_boss.current_health), int(current_boss.start_hp),
				active_map, biome_id])
		else:
			_bdiag("SPAWN", "FEHLER: Wellen-Boss type=%d wurde nicht erzeugt" % btype)
		ui_manager.show_boss_warning(wave / 5)
		if is_giant:
			ui_manager.show_banner("%s ERSCHEINT!" % _biome_boss_name(), Color(1.0, 0.45, 0.75))
	ui_manager.show_banner("WELLE " + str(wave), Color(0.95, 0.85, 0.35))
	if not tip_shown and ui_manager.has_method("show_tip"):
		tip_shown = true
		ui_manager.show_tip("FEUERKNOPF GEDRÜCKT HALTEN = DAUERFEUER   ·   Q = TRANK, E = BOMBE")
		_save_profile()
	_recount_wave()
	ui_manager.update_wave_label(wave, coins, false, 0.0, wave_remaining, level, wave_start_level + WAVE_LEVEL_UPS)

# ============================================================
# SCHWIERIGKEIT + ZIELHILFE (Runde 15, Tester-Feedback)
# ============================================================
# Runde 49c: "coins" ist der MUENZ-FAKTOR und war VERKEHRT HERUM -
# haettere Schwierigkeit gab MEHR Gold (1.35 / 1.70). Jetzt gilt:
# haerter = weniger Gold, damit man nicht alles kaufen kann.
const DIFFICULTY := [
	{ "name": "LEICHT", "hp": 0.75, "dmg": 0.6, "speed": 0.90, "spawn": 0.80, "coins": 1.25, "hearts": 6 },
	{ "name": "NORMAL", "hp": 1.00, "dmg": 1.0, "speed": 1.00, "spawn": 1.00, "coins": 1.00, "hearts": 5 },
	{ "name": "SCHWER", "hp": 1.35, "dmg": 1.4, "speed": 1.10, "spawn": 1.25, "coins": 0.78, "hearts": 4 },
	{ "name": "HARDCORE", "hp": 1.80, "dmg": 1.9, "speed": 1.15, "spawn": 1.50, "coins": 0.58, "hearts": 3 }
]
var difficulty: int = 1
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

func quit_to_menu() -> void:
	paused = false
	get_tree().paused = false
	if ui_manager != null:
		ui_manager.hide_pause()
	current_state = GameState.MENU
	ui_manager.show_start_screen()

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
	shop_time = 30.0
	shop_ready.clear()
	shop_ready[my_slot] = false
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

func _next_wave(force: bool = false) -> void:
	# Runde 32: Doppel-Tap auf "WEITER" (auf dem Handy leicht passiert) oder
	# Button + ablaufender 30s-Timer haben die Welle ZWEIMAL gestartet
	# (doppelte Monster + uebersprungene Wellennummer = "2x auf dem Feld").
	# in_shop ist genau waehrend der Shop-Phase true -> zweiter Aufruf faellt raus.
	if not in_shop:
		return
	# Runde 33 (Variante B): der Client meldet nur "fertig", der Host entscheidet
	if coop_client and not coop_host:
		NetManager.c_send_shop_ready()
		ui_manager.hide_shop()
		return
	shop_ready[my_slot] = true
	if not force and coop_host and lan_mode and not _all_players_ready():
		ui_manager.show_banner("WARTE AUF DEN ANDEREN SPIELER", Color(0.95, 0.85, 0.35))
		return
	in_shop = false
	shop_time = 0.0
	ui_manager.hide_shop()
	_start_wave()

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
	game_mode = clampi(m, 0, 1)
	ui_manager.set_mode_label(game_mode)
	_save_profile()

func cycle_game_mode() -> void:
	set_game_mode(1 - game_mode)

# ---------------- Profil: Name, Farbe, Hut (Punkt 8) ----------------
var p_name: String = "HELD"
var p_color: int = 0
var p_hat: int = 0
var unlocked_hats: Array = [0, 1]      # ohne Hut + Kappe von Anfang an
var unlocked_rigs: Array = [0]          # Runde 38: Character-Rigs (0 = normal)
var p_rig: int = 0                      # Runde 38: aktives Rig
var partner_name: String = ""
var partner_color: int = 1
var partner_hat: int = 0

# ---------------- Meta-Progression (Runde 11): Gold, Kisten, Karten ----------------
var gold: int = 0
var chests_since_rare: int = 0          # Runde 36: Pity (10 Kisten ohne Rare -> Rare garantiert)
var xp_total: int = 0
var unlocked_colors: Array = [0, 1]        # Blau + Rot frei
var unlocked_maps: Array = ["earth"]
var active_map: String = "earth"
var boosts: Dictionary = {}                # id -> Anzahl (gekauft, noch nicht verbraucht)
var live_boosts: Dictionary = {}           # id -> true (in DIESEM Run aktiv)
const GOLD_PER_SCORE := 12

const BOOSTS := [
	{ "id": "heart", "name": "EXTRA-HERZ", "desc": "+1 maximales Herz im naechsten Run", "price": 40, "icon": "heart_full" },
	{ "id": "shield", "name": "SCHILD-START", "desc": "Start mit 2 Schild-Ladungen", "price": 30, "icon": "icon_shield" },
	{ "id": "rapid", "name": "SCHNELLFEUER-START", "desc": "Schnellfeuer 20 s ab Start", "price": 35, "icon": "powerup_rapid" },
	{ "id": "bounty", "name": "KOPFGELD", "desc": "Doppelte Run-Muenzen im Wellen-Modus", "price": 45, "icon": "icon_coin" },
	# Runde 41: neue Verbrauchsgueter - damit haben die Kisten dauerhaft
	# unterschiedliche Inhalte, auch wenn alle Cosmetics besessen sind
	{ "id": "speed", "name": "TURBO", "desc": "+15 % Tempo im naechsten Run", "price": 50, "icon": "powerup_rapid" },
	{ "id": "damage", "name": "KAMPFKRAFT", "desc": "+20 % Schaden im naechsten Run", "price": 55, "icon": "icon_crosshair" },
	{ "id": "vitality", "name": "ZWEITES HERZ", "desc": "+1 Herz UND sofort volle Leben", "price": 65, "icon": "heart_full" }
]

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
const CHESTS := [
	{ "id": "wood", "name": "HOLZKISTE", "price": 60, "icon": "chest_wood", "fallback": 20, "items": 1,
	  "mix": { "common": 78, "rare": 20, "epic": 2 },
	  "pool": [ ["boost_heart", 30], ["boost_shield", 25], ["boost_rapid", 25], ["boost_speed", 20], ["gold", 20] ] },
	{ "id": "silver", "name": "SILBERKISTE", "price": 150, "icon": "chest_silver", "fallback": 60, "items": 1,
	  "mix": { "common": 40, "rare": 48, "epic": 12 },
	  "pool": [ ["boost_vitality", 20], ["boost_damage", 20], ["boost_epic", 14], ["boost_big", 10], ["gold", 8] ] },
	{ "id": "gold", "name": "GOLDKISTE", "price": 320, "icon": "chest_gold", "fallback": 150, "items": 2,
	  "mix": { "common": 14, "rare": 46, "epic": 40 },
	  "pool": [ ["boost_epic", 14], ["boost_damage", 10], ["boost_vitality", 10], ["boost_big", 6], ["gold", 5] ] },
]

# Runde 42: Seltenheit der KOSMETIK-Items (Index-basiert auf die Reihenfolge
# in COLOR_NAMES / HAT_NAMES / RIG_NAMES).
# Gewoehnlich = die Basics, Selten = die kräftigen Varianten,
# Episch = die Sonderformen.
const COLOR_RARITY := ["common", "common", "common", "common", "common", "rare", "common", "rare", "rare", "epic"]
const HAT_RARITY := ["common", "common", "common", "rare", "rare", "common", "rare", "rare", "epic", "epic"]
const RIG_RARITY := ["common", "rare", "rare", "epic", "epic", "epic"]

const RARITY_NAMES := { "common": "GEWOEHNLICH", "rare": "SELTEN", "epic": "EPISCH" }
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

func buy_boost(bid: String) -> bool:
	for b in BOOSTS:
		if str(b["id"]) != bid:
			continue
		var price := int(b["price"])
		if gold < price:
			return false
		gold -= price
		boosts[bid] = int(boosts.get(bid, 0)) + 1
		_save_profile()
		SoundManager.play("pickup")
		ui_manager.refresh_shop_ui()
		ui_manager.animate_gold(gold + price, gold)
		return true
	return false

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
			"boost_speed", "boost_damage", "boost_vitality":
				ok = true
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


func chest_price(tier_id: String) -> int:
	# Runde 48: Preis einer Kiste (fuer den Bestaetigungs-Button)
	for tier in CHESTS:
		if str(tier["id"]) == tier_id:
			return int(tier["price"])
	return 999999


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
	_save_profile()
	ui_manager.animate_gold(gold + price, gold)
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
		"boost_heart":
			boosts["heart"] = int(boosts.get("heart", 0)) + 1
			return { "ok": true, "kind": "boost", "label": "EXTRA-HERZ", "rarity": rar, "icon": "heart_full" }
		"boost_shield":
			boosts["shield"] = int(boosts.get("shield", 0)) + 1
			return { "ok": true, "kind": "boost", "label": "SCHILD-START", "rarity": rar, "icon": "icon_shield" }
		"boost_rapid":
			boosts["rapid"] = int(boosts.get("rapid", 0)) + 1
			return { "ok": true, "kind": "boost", "label": "SCHNELLFEUER-START", "rarity": rar, "icon": "powerup_rapid" }
		"boost_big":
			var ids := ["heart", "shield", "rapid"]
			for i in range(2):
				var bid := str(ids[randi() % ids.size()])
				boosts[bid] = int(boosts.get(bid, 0)) + 1
			return { "ok": true, "kind": "boost", "label": "2x VERBRAUCHSGUT", "rarity": rar, "icon": "chest" }
		"boost_epic":
			boosts["bounty"] = int(boosts.get("bounty", 0)) + 1
			boosts["rapid"] = int(boosts.get("rapid", 0)) + 1
			return { "ok": true, "kind": "boost", "label": "KOPFGELD + SCHNELLFEUER", "rarity": rar, "icon": "icon_coin" }
		"boost_speed":
			boosts["speed"] = int(boosts.get("speed", 0)) + 1
			return { "ok": true, "kind": "boost", "label": "TURBO (+15 % TEMPO)", "rarity": rar, "icon": "powerup_rapid" }
		"boost_damage":
			boosts["damage"] = int(boosts.get("damage", 0)) + 1
			return { "ok": true, "kind": "boost", "label": "KAMPFKRAFT (+20 % SCHADEN)", "rarity": rar, "icon": "icon_crosshair" }
		"boost_vitality":
			boosts["vitality"] = int(boosts.get("vitality", 0)) + 1
			return { "ok": true, "kind": "boost", "label": "ZWEITES HERZ", "rarity": rar, "icon": "heart_full" }
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

func unlock_hat(i: int) -> void:
	if not unlocked_hats.has(i):
		unlocked_hats.append(i)


# ---------------- Jahreszeiten (Runde 13, Option D Hybrid) ----------------
# Ein Planet startet in der gewaehlten Jahreszeit; im Run wandert sie per Score weiter.
const SEASONS := [
	{ "id": "spring", "name": "FRUEHLING", "desc": "Dichte Blaetter, Blueten — ruhiger Start",
	  "veg": 1.0, "speed": 1.0, "damage": 1.0, "loot": 1.0, "drift": 0.0, "ground_slow": 1.0,
	  "color": Color(0.55, 0.95, 0.65), "gate": {} },
	{ "id": "summer", "name": "SOMMER", "desc": "Kahle, schuettere Baeume, Hitze — Gegner +10% Tempo",
	  "veg": 0.62, "speed": 1.10, "damage": 1.0, "loot": 1.0, "drift": 0.0, "ground_slow": 0.97,
	  "color": Color(1.0, 0.85, 0.35), "gate": { "type": "xp", "need": 1500 } },
	{ "id": "autumn", "name": "HERBST", "desc": "Orange Blaetter, Laubfall — mehr Kisten und Loot",
	  "veg": 1.10, "speed": 1.0, "damage": 1.0, "loot": 1.40, "drift": 0.0, "ground_slow": 1.0,
	  "color": Color(0.95, 0.62, 0.25), "gate": { "type": "xp", "need": 2500 } },
	{ "id": "winter", "name": "WINTER", "desc": "Schnee, kahle Zweige, glatter Boden — Gegner -15% Tempo",
	  "veg": 0.75, "speed": 0.85, "damage": 1.0, "loot": 1.0, "drift": 0.17, "ground_slow": 0.92,
	  "color": Color(0.75, 0.88, 1.0), "gate": { "type": "xp", "need": 3500 } }
]
const SEASON_STEP := 1400.0        # Score pro Jahreszeiten-Wechsel im Run

var season_id: String = "spring"
var active_season: Dictionary = {}      # planet_id -> season_id (gewaehlt)
var season_unlocks: Dictionary = {}     # planet_id -> [season_id]

func seasons_enabled(planet: String = "") -> bool:
	var pid := planet if planet != "" else active_map
	return pid != "earth"      # Erde bleibt die Klimazonen-Reise

func season_ids() -> Array:
	var out: Array = []
	for se in SEASONS:
		out.append(str(se["id"]))
	return out

func season_data(sid: String = "") -> Dictionary:
	var want := sid if sid != "" else season_id
	for se in SEASONS:
		if str(se["id"]) == want:
			return se
	return SEASONS[0]

func season_name(sid: String) -> String:
	for se in SEASONS:
		if str(se["id"]) == sid:
			return str(se["name"])
	return sid

func planet_season(planet: String) -> String:
	if not active_season.has(planet):
		# Runde 38: die Elektro-Welt startet mit "sturm"
		active_season[planet] = "sturm" if planet == "volt" else "spring"
	return str(active_season[planet])

func volt_seasons() -> Array:
	# Runde 38: die vier kreativen Jahreszeiten der Elektro-Welt
	return ["sturm", "ueberlast", "blackout", "nebel"]

func season_display_name(planet: String, sid: String) -> String:
	# Runde 38: Anzeigenamen (die Season-IDs sind intern)
	match sid:
		"sturm":
			return "STURM"
		"ueberlast":
			return "UEBERLAST"
		"blackout":
			return "BLACKOUT"
		"nebel":
			return "NEBEL"
	return sid.to_upper()

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

func season_gate_need(planet: String, sid: String) -> int:
	var g: Dictionary = season_data(sid).get("gate", {})
	if g.is_empty():
		return 0
	return int(g.get("need", 0))

func season_progress_text(planet: String) -> String:
	# naechste gesperrte Jahreszeit dieses Planeten
	for se in SEASONS:
		var sid := str(se["id"])
		if is_season_unlocked(planet, sid):
			continue
		var need := season_gate_need(planet, sid)
		if need <= 0:
			continue
		return "%s: %d XP in einem Run (Bestwert %d)" % [str(se["name"]), need, best_run_xp]
	return ""

func _check_season_gates() -> void:
	if not seasons_enabled():
		return
	for se in SEASONS:
		var sid := str(se["id"])
		if is_season_unlocked(active_map, sid):
			continue
		var need := season_gate_need(active_map, sid)
		if need <= 0:
			continue
		if run_xp >= need:
			if not season_unlocks.has(active_map):
				season_unlocks[active_map] = ["spring"]
			(season_unlocks[active_map] as Array).append(sid)
			_save_profile()
			SoundManager.play("levelup")
			ui_manager.show_banner("NEUE JAHRESZEIT: " + str(se["name"]), se["color"])
			ui_manager.refresh_maps_ui()

func _check_season() -> void:
	# Im Run wandert die Jahreszeit per Score weiter (Zyklus ab Start-Jahreszeit)
	if not seasons_enabled():
		return
	var ids := season_ids()
	var start_idx := maxi(0, ids.find(planet_season(active_map)))
	var steps := int(score / SEASON_STEP)
	var want := str(ids[(start_idx + steps) % ids.size()])
	if want != season_id:
		season_id = want
		map_generator.set_season(season_id)
		var sd := season_data(season_id)
		ui_manager.show_banner(str(sd["name"]), sd["color"])

func get_loot_mult() -> float:
	return float(season_data().get("loot", 1.0))

func season_summary() -> String:
	if not seasons_enabled():
		return ""
	return season_name(season_id)

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

func _consume_boosts(p: Node) -> void:
	# Verbrauchsgüter gelten fuer genau einen Run
	live_boosts.clear()
	for b in BOOSTS:
		var bid := str(b["id"])
		var cnt := int(boosts.get(bid, 0))
		if cnt <= 0:
			continue
		live_boosts[bid] = true
		boosts[bid] = cnt - 1
	if is_instance_valid(p):
		if live_boosts.get("heart", false):
			p.call("add_max_health")
			p.call("heal", 99)
		if live_boosts.get("shield", false):
			p.call("add_shield", 2)
		if live_boosts.get("rapid", false):
			rapid_time = 20.0
		# Runde 41: neue Verbrauchsgueter anwenden
		if live_boosts.get("vitality", false):
			p.call("add_max_health")
			p.call("heal", 99)
		if live_boosts.get("speed", false):
			p.call("add_speed_mult", 0.15)
		if live_boosts.get("damage", false):
			p.call("add_damage_mult", 0.20)
	if live_boosts.get("bounty", false):
		coins_bounty = 2
	else:
		coins_bounty = 1
	_save_profile()

func boost_summary() -> String:
	var parts: Array = []
	for b in BOOSTS:
		var n := int(boosts.get(str(b["id"]), 0))
		if n > 0:
			parts.append("%s x%d" % [str(b["name"]), n])
	return " · ".join(parts) if not parts.is_empty() else "keine"

func _load_profile() -> void:
	if not FileAccess.file_exists("user://profile.save"):
		return
	var f := FileAccess.open("user://profile.save", FileAccess.READ)
	if f == null:
		return
	var d = f.get_var()
	f.close()
	if typeof(d) == TYPE_DICTIONARY:
		p_name = str(d.get("name", "HELD"))
		p_color = int(d.get("color", 0))
		p_hat = int(d.get("hat", 0))
		var u = d.get("unlocked", [0, 1])
		if typeof(u) == TYPE_ARRAY:
			unlocked_hats = u
		# Runde 47: Skins (Rigs) persistent - vorher gingen sie bei jedem
		# Neustart verloren, dadurch waren alle Skins wieder gesperrt
		var ur = d.get("unlocked_rigs", [0])
		if typeof(ur) == TYPE_ARRAY:
			unlocked_rigs = ur
		if not unlocked_rigs.has(0):
			unlocked_rigs.append(0)
		p_rig = int(d.get("p_rig", 0))
		if not unlocked_rigs.has(p_rig):
			p_rig = 0
		# Meta-Progression (Runde 11)
		gold = int(d.get("gold", 0))
		xp_total = int(d.get("xp_total", 0))
		var uc = d.get("unlocked_colors", [0, 1])
		if typeof(uc) == TYPE_ARRAY:
			unlocked_colors = uc
		var um = d.get("unlocked_maps", ["earth"])
		if typeof(um) == TYPE_ARRAY:
			unlocked_maps = um
		active_map = str(d.get("active_map", "earth"))
		# Migration alter Profile ("meadow" -> "earth")
		for i in range(unlocked_maps.size()):
			if str(unlocked_maps[i]) == "meadow" or str(unlocked_maps[i]) == "desert" or str(unlocked_maps[i]) == "ice" or str(unlocked_maps[i]) == "lava":
				unlocked_maps[i] = "earth"
		if active_map == "meadow" or not is_map_unlocked(active_map):
			active_map = "earth"
		if not unlocked_maps.has("earth"):
			unlocked_maps.append("earth")
		best_run_xp = int(d.get("best_run_xp", 0))
		if not is_map_unlocked(active_map):
			active_map = "meadow"
		var bs = d.get("boosts", {})
		if typeof(bs) == TYPE_DICTIONARY:
			boosts = bs
		var asea = d.get("active_season", {})
		if typeof(asea) == TYPE_DICTIONARY:
			active_season = asea
		difficulty = int(d.get("difficulty", 1))
		aim_assist = int(d.get("aim_assist", 1))
		tip_shown = bool(d.get("tip_shown", false))
		var sunl = d.get("season_unlocks", {})
		if typeof(sunl) == TYPE_DICTIONARY:
			season_unlocks = sunl
	if p_name == "":
		p_name = "HELD"
	SoundManager.set_muted(bool(d.get("muted", false)))

func _save_profile() -> void:
	var f := FileAccess.open("user://profile.save", FileAccess.WRITE)
	if f:
		f.store_var({ "name": p_name, "color": p_color, "hat": p_hat, "unlocked": unlocked_hats, "muted": SoundManager.muted,
			"unlocked_rigs": unlocked_rigs, "p_rig": p_rig,
			"gold": gold, "xp_total": xp_total, "unlocked_colors": unlocked_colors,
			"unlocked_maps": unlocked_maps, "active_map": active_map, "boosts": boosts,
			"best_run_xp": best_run_xp, "active_season": active_season, "season_unlocks": season_unlocks,
			"difficulty": difficulty, "aim_assist": aim_assist, "tip_shown": tip_shown })
		f.close()

func set_muted(m: bool) -> void:
	SoundManager.set_muted(m)
	_save_profile()

func set_player_name(n: String) -> void:
	var clean := n.strip_edges().substr(0, 10)
	p_name = clean if clean != "" else "HELD"
	_save_profile()

func set_profile_color(i: int) -> void:
	p_color = clampi(i, 0, 9)   # Runde 37: 10 Farben
	_apply_profile()
	_save_profile()

func unlock_rig(i: int) -> void:
	# Runde 38: Character-Rig freischalten
	if not unlocked_rigs.has(i):
		unlocked_rigs.append(i)
	_save_profile()

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
		NetManager.h_send_profile(p_name, p_color, p_hat)
	elif coop_client:
		NetManager.c_send_profile(p_name, p_color, p_hat)

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

const UPGRADES = [
	{"id": "power", "name": "MEHR SCHADEN", "desc": "Deine Waffen machen +25% Schaden", "cap": 5},
	{"id": "turbo", "name": "SCHNELLER NACHLADEN", "desc": "Alle Waffen laden 15% schneller nach", "cap": 4},
	{"id": "speed", "name": "SCHNELLE BEINE", "desc": "+15% Bewegungstempo", "cap": 4},
	{"id": "vitality", "name": "MEHR HERZEN", "desc": "+1 maximales Herz und sofort geheilt", "cap": 2},
	{"id": "guardian", "name": "SCHILD-LADUNG", "desc": "+2 Schild-Treffer (12 Sekunden)", "cap": 3},
	{"id": "vampire", "name": "VAMPIR", "desc": "Heilt 1 Herz fuer je 12 Kills", "cap": 1},
]

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
const ZONE_SCENE = preload("res://scripts/corruption_zone.gd")

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


func debug_unlock_all() -> void:
	gold += 99999
	for m in MAPS:
		_unlock_map(str(m["id"]))
	for i in range(TextureManager.COLOR_NAMES.size()):
		_unlock_color(i)
	for i in range(TextureManager.HAT_NAMES.size()):
		unlock_hat(i)
	for pid in ["mars", "jungle"]:
		season_unlocks[pid] = ["spring", "summer", "autumn", "winter"]
	_save_profile()
	ui_manager.set_start_gold(gold)
	ui_manager.refresh_shop_ui()
	ui_manager.refresh_maps_ui()
	SoundManager.play("levelup")
	ui_manager.show_banner("DEBUG: ALLES FREIGESCHALTET", Color(1.0, 0.85, 0.3))
	print("[DEBUG] Alles freigeschaltet (gold=%d)" % gold)

func _lan_diag_hook() -> void:
	var a = load("res://scripts/lan_diag_tmp.gd").new()
	add_child(a)
	a.start(self)


func _ready():
	# Runde 50: Der GM muss bei get_tree().paused=true WEITERLAUFEN, damit
	# der LAN-Sync nicht stehen bleibt (Upgrade-Fenster des Hosts).
	# Kinder erben sonst ALWAYS -> Spielwelt explizit auf PAUSABLE setzen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	ysort.process_mode = Node.PROCESS_MODE_PAUSABLE
	camera.process_mode = Node.PROCESS_MODE_PAUSABLE
	monster_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	print("[LAN][BOOT] process_mode gesetzt (GM=ALWAYS, Welt=PAUSABLE)")
	if OS.get_environment("COMIC_LANTEST") != "":
		_lan_diag_hook()
	_load_high_score()
	_load_profile()
	_load_scenes()
	ui_manager.register_references(self, null)
	# Runde 60: Debug-Fenster (F9) - Charakter-Vorschau, Weltwechsel, Freischalten
	debug_panel = load("res://scripts/debug_panel.gd").new()
	add_child(debug_panel)
	debug_panel.call("setup", self)
	ui_manager.connect("upgrade_chosen", Callable(self, "_on_upgrade_chosen"))
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
	NetManager.wave_state_received.connect(_on_net_wave_state)
	NetManager.chest_open_request_received.connect(_on_chest_open_request)
	NetManager.world_synced.connect(_on_world_synced)
	NetManager.my_player_synced.connect(_on_my_player_synced)
	NetManager.mobs_synced.connect(_on_mobs_synced)
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

	# --- Wellen-Modus (Punkt 6) ---
	if game_mode == 1:
		if in_shop:
			shop_time -= delta
			ui_manager.update_wave_label(wave, coins, true, shop_time, wave_remaining)
			if shop_time <= 0.0:
				_next_wave(true)
		elif wave_active and wave_remaining <= 0:
			# Runde 55: Der Shop oeffnet, sobald die Welle LEER ist - unabhaengig
			# vom Level. Vorher hing der Fortschritt an Level-Aufstiegen und
			# schickte Nachschub-Monster, obwohl die Welle laengst geraeumt war.
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
	if _boss_active and (not is_instance_valid(current_boss) or current_boss.is_queued_for_deletion()):
		var dead_type: String = str(current_boss.get("type")) if is_instance_valid(current_boss) else "?"
		var dead_hp: int = int(current_boss.get("current_health")) if is_instance_valid(current_boss) else -1
		_boss_active = false
		current_boss = null
		ui_manager.hide_boss_bar()
		_boss_defeats += 1
		_bdiag("DEFEAT", "Boss besiegt (#%d type=%s hp=%d map=%s) -> Banner" % [
			_boss_defeats, _boss_last_type, dead_hp, active_map])
		ui_manager.show_banner("BOSS BESIEGT!", Color(0.45, 1.0, 0.55))
		_boss_timer = 0.0
	if game_mode == 0:
		_boss_timer += delta
		if _boss_timer >= BOSS_INTERVAL:
			_boss_timer = 0.0
			_spawn_boss()

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

func start_game(duo: bool = false, lan: bool = false):
	if current_state != GameState.MENU and current_state != GameState.LOBBY:
		return
	# Runde 49: Action-Musik fuer den Run
	SoundManager.play_music("game")
	duo_mode = duo
	lan_mode = lan
	# Runde 53: Zuschauer-Status eines alten Runs darf nicht ueberleben
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
	_boss_timer = 0.0
	_boss_count = 0
	current_boss = null
	freeze_time = 0.0
	rapid_time = 0.0
	biome_id = str(map_data()["biome"])
	map_generator.set_biome(biome_id)
	event_timer = randf_range(40.0, 60.0)
	gold_time = 0.0
	_apply_quality()

	# Karte generieren
	map_generator.generate_map(MAP_COLS, MAP_ROWS, TILE_SIZE)
	map_generator.set_season(season_id)
	map_generator.place_planet_obstacles(get_vegetation())

	# Kisten platzieren
	_place_chests()

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
	else:
		ui_manager.update_wave_label(0, 0, false, -1.0, 0)

	# Monster-Spawning starten (im Wellen-Modus uebernimmt der Wellen-Manager)
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
	var num_zones: int = 2   # Runde 16 (C1): fest, nicht mehr an die Grafikstufe gekoppelt
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

	# Kamera folgt Spieler (Camera bleibt Kind von Main -> überlebt Player-Tod, V4)
	camera.global_position = player.position
	camera.make_current()

	# UI anzeigen
	ui_manager.show_hud()
	_consume_boosts(player)          # Verbrauchsgueter anwenden (Spieler existiert jetzt)
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
		NetManager.c_send_profile(p_name, p_color, p_hat)

func _spawn_slot_player(slot: int, is_remote_driven: bool, is_remote_ctrl: bool) -> Node:
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
	p.call("apply_profile", int(pr["color"]), int(pr["hat"]))
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
	print("LOBBY: Host gestartet, max ", NetManager.player_count, " Spieler, IP ", NetManager.get_local_ip())

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

func _apply_slot_profiles() -> void:
	for s in players.keys():
		var p = players[s]
		if not is_instance_valid(p):
			continue
		var pr := _slot_texture_profile(s)
		p.call("apply_profile", int(pr["color"]), int(pr["hat"]))

func start_lobby_from_menu(wanted_players: int) -> void:
	start_lan_host(wanted_players)

# Host drueckt im Lobby-Fenster START: Clients losschicken + selbst starten
func start_lan_run_as_host() -> void:
	if not NetManager.is_host:
		return
	if current_state != GameState.LOBBY:
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
		NetManager.h_send_profile(p_name, p_color, p_hat)

func _on_coop_profile(peer_id: int, peer_name: String, color: int, hat: int) -> void:
	var slot := NetManager.slot_of_peer(peer_id)
	partner_name = peer_name
	partner_color = color
	partner_hat = hat
	if slot <= 0:
		slot = 2
	slot_profiles[slot] = { "name": peer_name, "color": color, "hat": hat }
	var p = players.get(slot, null)
	if is_instance_valid(p):
		p.call("apply_profile", color, hat)
	if is_instance_valid(player2):
		player2.call("apply_profile", color, hat)
	# Partner-Grafik beim Client (Geist) einfärben
	if coop_client and is_instance_valid(partner_node):
		var spr = partner_node.get_node_or_null("Sprite2D")
		if spr:
			spr.texture = TextureManager.get_player_texture(color, hat)

func _send_coop_init() -> void:
	NetManager.h_send_init(_net_seed, _host_chests, _host_zones, biome_id)

func _on_coop_init(net_seed: int, chests: PackedFloat32Array, zone_data: PackedFloat32Array, biome: String) -> void:
	_net_seed = net_seed
	_net_chests = chests
	_net_zones = zone_data
	_net_biome = biome
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
	# Karte mit dem Host-Seed erzeugen -> identische Hindernisse
	map_generator.clear_map()
	seed(_net_seed)
	map_generator.generate_map(MAP_COLS, MAP_ROWS, TILE_SIZE)
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
	_consume_boosts(player)
	ui_manager.update_health(MAX_HEALTH, MAX_HEALTH, 1)
	ui_manager.update_score(0)
	ui_manager.update_combo(0, 1.0)
	ui_manager.update_buffs(0.0, 0.0, 0.0)
	ui_manager.refresh_weapon_hud(player.call("get_owned_weapons"), player.call("get_weapon_key"))
	print("COOP: Client-Run gestartet (Seed=", _net_seed, ", Kisten=", int(_net_chests.size() / 2), ", Zonen=", int(_net_zones.size() / 3), ")")

# ---------- Host: Senden ----------
func _coop_host_tick(delta: float) -> void:
	_t_mobs += delta
	if _t_mobs >= 0.10:      # Runde 34: 10 statt 7.7 Hz (fluessiger)
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

func _make_light_ghost(mtype: int) -> Sprite2D:
	# Runde 34: Client-Geister als einfaches Sprite (vorher: komplette Monster-Szene
	# mit CollisionShape + Warn-Sprite + KI-Skript pro Geist -> viel Last)
	var sp := Sprite2D.new()
	var key: String = str(monster_ai_script.ghost_texture_key(mtype)) if monster_ai_script != null else "monster_green"
	var tex = TextureManager.get_texture(key)
	if tex != null:
		sp.texture = tex
	var sc: float = float(monster_ai_script.ghost_scale(mtype)) if monster_ai_script != null else 1.0
	sp.scale = Vector2(sc, sc)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sp.z_index = 1
	return sp

func _send_mob_snapshot() -> void:
	var data := PackedFloat32Array()
	for m in _monster_cache:          # Runde 33: eigene Liste statt Baumsuche
		if not is_instance_valid(m) or m.ghost:
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
	var w: float = 1.0 - exp(-14.0 * delta)
	for g in _ghosts.values():
		if is_instance_valid(g):
			var tgt: Vector2 = g.get_meta("tgt", g.position)
			g.position = g.position.lerp(tgt, w)
	_t_myp += delta
	if _t_myp >= 0.05:
		_t_myp = 0.0
		var ang := _my_aim_deg
		if player.input_direction != Vector2.ZERO:
			ang = rad_to_deg(player.input_direction.angle())
			_my_aim_deg = ang
		NetManager.c_send_input(player.input_direction, player.shoot_held, ang)

func _on_mobs_synced(data: PackedFloat32Array) -> void:
	if not coop_client or current_state != GameState.PLAYING:
		return
	var seen: Dictionary = {}
	var i := 0
	while i + 6 <= data.size():
		var id := int(data[i])
		var mtype := int(data[i + 1])
		var x := data[i + 2]
		var y := data[i + 3]
		var hp := int(data[i + 4])
		var ang := data[i + 5]
		seen[id] = true
		var g = _ghosts.get(id)
		if g == null or not is_instance_valid(g):
			g = _make_light_ghost(int(mtype))
			monster_container.add_child(g)
			_ghosts[id] = g
			g.set_meta("hp", hp)
		else:
			# Runde 50: Nur das Ziel merken - bewegt wird in _coop_client_tick
			g.set_meta("tgt", Vector2(x, y))
			g.set("flip_h", ang > 90.0)
			_t_diag_ghost += 1
			var old_hp: int = int(g.get_meta("hp", hp))
			if hp < old_hp:
				g.set("modulate", Color(1.6, 0.7, 0.7))
			else:
				g.set("modulate", Color(1, 1, 1))
			g.set_meta("hp", hp)
		i += 6
	for id in _ghosts.keys():
		if not seen.has(id):
			var g = _ghosts[id]
			if is_instance_valid(g):
				g.queue_free()
			_ghosts.erase(id)
	# Runde 50: Diagnose - Zaehler erst nach dem Log nullen
	if _ldiag_th("GHOSTS", 1.0, "Client-Geister: %d Ziel-Updates/s, ghosts=%d fps=%d" % [
		_t_diag_ghost, _ghosts.size(), Engine.get_frames_per_second()]):
		_t_diag_ghost = 0

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
				it.monitoring = false
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
	player.health = hp
	player.max_health = mx
	player.shield = shield
	player.call("set_remote_transform", Vector2(x, y), angle)
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
	# Co-op: einer faellt -> Run fuer beide beendet
	current_state = GameState.DEAD
	SoundManager.play("death")
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

# Runde 34: Balance-Tabelle - je Wellenbereich Monsterzahl, HP- und Speed-Faktor.
# Ersetzt die alten Formeln (5 + wave*3 / +12 XP / Boss-HP 1+0.18*wave).
const WAVE_BALANCE := [
	{ "upto": 3,  "count": 6,  "hp": 1.00, "spd": 1.00 },
	{ "upto": 6,  "count": 9,  "hp": 1.18, "spd": 1.03 },
	{ "upto": 10, "count": 13, "hp": 1.42, "spd": 1.06 },
	{ "upto": 15, "count": 17, "hp": 1.72, "spd": 1.09 },
	{ "upto": 22, "count": 21, "hp": 2.10, "spd": 1.12 },
	{ "upto": 30, "count": 25, "hp": 2.55, "spd": 1.15 },
]

func wave_balance() -> Dictionary:
	# Runde 34: Balance fuer die aktuelle Welle
	var e: Dictionary = WAVE_BALANCE[WAVE_BALANCE.size() - 1]
	for row in WAVE_BALANCE:
		if wave <= int(row["upto"]):
			e = row
			break
	var over: float = maxf(0.0, float(wave - int(e["upto"])))
	return {
		"count": maxi(1, int(round(float(e["count"]) * (1.0 + 0.06 * over) * float(diff_data()["spawn"])))),
		"hp": float(e["hp"]) * (1.0 + 0.09 * over),
		"spd": minf(1.45, float(e["spd"]) * (1.0 + 0.015 * over)),
	}

# Runde 33: Pro-Map-Kurve (Mars/Jungel geben mehr XP+Gold -> mehr XP pro Level noetig)
const XP_CURVE_MULT := { "earth": 1.0, "mars": 1.7, "jungle": 2.1 }
# Runde 49c: Die Preise steigen, damit Gold knapp bleibt.
const SHOP_PRICE_MULT := { "earth": 1.45, "mars": 1.9, "jungle": 2.25 }

func xp_multiplier() -> float:
	return float(XP_CURVE_MULT.get(active_map, 1.0))

func shop_price_mult() -> float:
	return float(SHOP_PRICE_MULT.get(active_map, 1.0))

func shop_price(base: int) -> int:
	# Runde 34: Preise steigen auch mit der Wellennummer
	# Runde 49c: 0.05 -> 0.085. Die Preise muessen schneller
	# wachsen als der Ertrag, sonst kann man irgendwann alles kaufen.
	var wave_mult: float = 1.0 + 0.085 * float(maxi(0, wave - 1))
	return maxi(1, int(round(float(base) * shop_price_mult() * wave_mult)))

func _build_shop_offers() -> Array:
	# Runde 34: pro Phase 5 normale Angebote (Karten-Bias pro Map) + 1 Rare-Item
	var weighted: Array = []
	for it in SHOP_ITEMS:
		var iid: String = str(it["id"])
		var w: float = 1.0
		match active_map:
			"jungle":
				w = 2.2 if (iid == "heal" or iid == "maxhp") else 0.6
			"mars":
				w = 2.2 if (iid == "shield" or iid == "potion") else 0.6
			_:
				w = 1.0
		# Runde 36b: Kopie! Sonst schreibt das "verpasst"-Flag in die Konstante
		weighted.append({"item": it.duplicate(true), "w": w})
	var offers: Array = []
	var picks: int = mini(5, weighted.size())
	for i in range(picks * 3):
		if offers.size() >= picks:
			break
		var total: float = 0.0
		for e in weighted:
			total += float(e["w"])
		var r: float = randf() * total
		for j in range(weighted.size() - 1, -1, -1):
			r -= float(weighted[j]["w"])
			if r <= 0.0:
				offers.append(weighted[j]["item"])
				weighted.remove_at(j)
				break
	# Rare-Item dazu
	if SHOP_RARE_ITEMS.size() > 0:
		offers.append(SHOP_RARE_ITEMS[randi() % SHOP_RARE_ITEMS.size()].duplicate(true))
	var ids: Array = []
	for o in offers:
		ids.append(str(o.get("id", "?")))
	_sdiag("OFFERS", "%d Angebote erzeugt (Map=%s): %s" % [offers.size(), active_map, str(ids)])
	return offers

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
		var near := false
		for s2 in players.keys():
			if int(s2) == sl:
				continue
			var o = players[s2]
			if is_instance_valid(o) and not bool(downed.get(int(s2), false)):
				if o.global_position.distance_to(dp.global_position) < 95.0:
					near = true
					break
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
		if near:
			revive_progress[sl] = float(revive_progress.get(sl, 0.0)) + delta
			if float(revive_progress[sl]) >= REVIVE_TIME:
				_revive_player(sl)
		else:
			revive_progress[sl] = 0.0
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
		if p.has_signal("health_changed"):
			p.emit_signal("health_changed", int(p.get("health")))
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
	SoundManager.play("death")

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

func _recount_wave() -> void:
	# Zaehlt alle lebenden Monster, die zur Welle gehoeren (Pflanzen/Ranken nicht)
	var n: int = 0
	for m2 in monster_container.get_children():
		if not is_instance_valid(m2) or m2.is_queued_for_deletion():
			continue
		# Wichtig: im Container liegen auch Item-Geister/Nicht-Monster
		if not m2.has_method("counts_for_wave"):
			continue
		if m2.get("ghost") == true:
			continue
		# wichtig: das Signal kommt VOR queue_free() - sterbende Monster nicht mitzaehlen
		if int(m2.get("current_health")) <= 0:
			continue
		if not m2.call("counts_for_wave"):
			continue
		n += 1
	wave_remaining = n

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

func spawn_monster_at(position: Vector2, mtype: int = -1, as_mini: bool = false):
	var monster = monster_scene.instantiate()
	monster.position = position
	monster.connect("monster_killed", Callable(self, "_on_monster_killed"))
	monster.connect("damage_player", Callable(self, "_on_monster_damage_player"))
	monster_container.add_child(monster)
	_monster_cache.append(monster)     # Runde 33
	monster.call("set_gm", self)
	var t := mtype if mtype >= 0 else _pick_random_monster_type()
	monster.call("set_type", t)
	if not bool(monster.call("is_boss")):
		# Runde 34: Wellen-Balance auf normale Monster anwenden
		var bal: Dictionary = wave_balance()
		monster.call("apply_wave_mult", float(bal["hp"]), float(bal["spd"]))
	if monster.call("is_boss"):
		# Runde 27: vorher stand hier "t == TYPE_BOSS" - damit waren die Biom-Bosse
		# (Mars/Jungle/Erde) und die neuen Mini-Bosse NICHT verbunden, die Bossbar
		# hat sich im Kampf also nie aktualisiert
		monster.connect("boss_hp", Callable(self, "_on_boss_hp"))
	if as_mini:
		monster.call("set_mini")
	# Wellen-Modus: Zaehlung erfolgt zentral in _recount_wave() (Runde 31)
	return monster

func _on_boss_hp(cur: int, mx: int):
	ui_manager.update_boss_hp(cur, mx)

# Werfer-Gegner: gelbe Kugel in Player-Richtung
func spawn_projectile(position: Vector2, dir: Vector2, dmg: int, spd: float, chain: int = 0) -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	proj.call("set_enemy", dmg)
	proj.position = position
	proj.set_direction(dir, spd)
	# Runde 55: Blitzkette - Treffer springt auf den Partner ueber
	proj.set("gm", self)
	proj.set("chain_hops", chain)
	ysort.add_child(proj)

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

func _mini_boss_type() -> int:
	# Runde 27: Mini-Bosse je Biom (Papagei / Sonde / Kaefer)
	match active_map:
		"mars": return 23
		"jungle": return 24
		"volt":
			# Runde 54: eigener Volt-Mini (Index 30) statt Erd-Kaefer
			_bdiag("MINI", "Volt-Karte -> MINI_VOLT (Spule)")
			return 30
		_: return 22

func _biome_boss_type() -> int:
	match biome_id:
		"volt":
			# Runde 49: BOSS_VOLT ist der Enum-Index 28. Vorher stand
			# hier 27 (VOLT_SPIDER) - der "Volt-Boss" war damit ein
			# normaler Spinnen-Gegner: kein Boss-Muster, keine Weak
			# Points, kein Boss-Balken. Genau das war die Meldung
			# "der Boss greift nicht an".
			return 28
		"mars":
			return 19
		"jungle":
			return 20
		_:
			return 21

func _biome_boss_name() -> String:
	match biome_id:
		"mars":
			return "METEOR-GOLEM"
		"jungle":
			return "ROBO-AFFE-KÖNIG"
		_:
			return "SPLITTER-KÖNIG"

func _spawn_boss() -> void:
	if not is_instance_valid(player):
		_bdiag("SPAWN", "ABGEBROCHEN: kein Spieler-Knoten")
		return
	# Erst spawnen, wenn der alte Boss besiegt ist
	if current_boss != null and is_instance_valid(current_boss) and not current_boss.is_queued_for_deletion():
		_bdiag("SPAWN", "ABGEBROCHEN: es lebt noch ein Boss (%s hp=%d)" % [
			str(current_boss.get("type")), int(current_boss.get("current_health"))])
		return
	_boss_count += 1
	# Boss etwas ausserhalb des Schirms spawnen
	var ang := randf_range(0, TAU)
	var pos := player.position + Vector2(cos(ang), sin(ang)) * 600.0
	var wmax := float(MAP_COLS * TILE_SIZE) - 200.0
	var hmax := float(MAP_ROWS * TILE_SIZE) - 200.0
	pos.x = clampf(pos.x, 200.0, wmax)
	pos.y = clampf(pos.y, 200.0, hmax)
	# Runde 49: Es darf nie zwei Bosse gleichzeitig geben. Wenn
	# current_boss schon lebt, wird der alte zuerst entfernt.
	if current_boss != null and is_instance_valid(current_boss) and not current_boss.is_queued_for_deletion():
		current_boss.queue_free()
	current_boss = spawn_monster_at(pos, _biome_boss_type())
	_boss_active = current_boss != null
	ui_manager.show_boss_warning(_boss_count)
	if current_boss != null:
		# Runde 26: echte Werte statt hart 40/40
		var bmx: int = int(current_boss.start_hp)
		ui_manager.update_boss_hp(int(current_boss.current_health), maxi(1, bmx))
		_bdiag("SPAWN", "Boss #%d type=%s hp=%d/%d pos=%s map=%s biome=%s" % [
			_boss_count, str(current_boss.get("type")), int(current_boss.current_health),
			bmx, str(pos.round()), active_map, biome_id])
		_boss_last_type = str(current_boss.get("type"))
	else:
		_bdiag("SPAWN", "FEHLER: spawn_monster_at() lieferte null (type=%d)" % _biome_boss_type())

func _pick_random_monster_type() -> int:
	# Zeit-gesteuert: Werfer ab 60s, Splitter ab 90s, Panzer ab 120s
	var t := Time.get_ticks_msec() / 1000.0
	var r = randf()
	# Welten-Pool (Runde 12): Mars/Jungle haben eigene Gegner
	var pool: Array = map_data().get("pool", [])
	if not pool.is_empty():
		# Runde 35b: Gewichte pro Karte (Mars = mehr Schuetzen, Jungle = mehr
		# Pflanzen, Elektro = mehr Technik-Gegner)
		var mw: Dictionary = _map_type_weights()
		if mw.is_empty():
			return int(pool[randi() % pool.size()])   # Planeten sind STRIKT getrennt
		var mtotal: float = 0.0
		for mt in pool:
			mtotal += float(mw.get(int(mt), 1.0))
		var mroll: float = randf() * mtotal
		for mt2 in pool:
			mroll -= float(mw.get(int(mt2), 1.0))
			if mroll <= 0.0:
				return int(mt2)
		return int(pool[randi() % pool.size()])
	# Biom-Spezialisten (Punkt 5): je Biom eigene Gegner, die die Mechanik nutzen
	# Karten (Runde 11): bias multipliziert die Chance
	var bias := float(map_data().get("bias", 1.0))
	var biome_roll := randf()
	if biome_roll < clampf(0.22 * bias, 0.0, 0.85) and t > 20.0:
		match biome_id:
			"desert":
				return 8     # GRABER
			"ice":
				return 9     # EISGOLEM
			"lava":
				return 10    # FEUERWERFER
	if r < 0.28:
		return 0  # GREEN
	elif r < 0.50:
		return 1  # RED
	elif r < 0.64:
		return 2  # BLUE
	elif r < 0.74:
		return 3  # PURPLE
	elif r < 0.84:
		return 4 if t > 60.0 else 0   # YELLOW (Werfer)
	elif r < 0.92:
		return 5 if t > 90.0 else 1   # PINK (Splitter)
	else:
		return 6 if t > 120.0 else 2  # ORANGE (Panzer)

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


func _open_upgrade_ui() -> void:
	# Wellen-Modus (Runde 9): KEINE Level-Up-Karten — Upgrades gibt es nur im
	# Shop nach einer geschafften Welle. Sonst doppelte Progression.
	if game_mode == 1:
		pending_upgrades = 0
		ui_manager.hide_upgrade_cards()
		if get_tree().paused:
			get_tree().paused = false
		return
	SoundManager.play("levelup")
	var avail: Array = []
	for u in UPGRADES:
		var used: int = int(upg_stacks.get(u["id"], 0))
		if used < int(u["cap"]):
			if u["id"] == "vitality" and is_instance_valid(player) and player.call("get_max_health") >= 7:
				continue
			avail.append(u)
	if avail.is_empty():
		pending_upgrades = 0
		return
	avail.shuffle()
	var picks: Array = avail.slice(0, min(3, avail.size()))
	# Runde 49: Der HOST schickt die Optionen an alle Clients, damit
	# deren Upgrade-Fenster aufgeht. Der Client oeffnet es selbst.
	if coop_host and NetManager.active:
		NetManager.h_send_upgrade_options(picks)
		_ldiag("UPGRADE", "Host schickt %d Optionen an Clients" % picks.size())
	_ldiag("UPGRADE", "Host oeffnet Karten -> tree.paused=true, pending=%d" % pending_upgrades)
	get_tree().paused = true
	ui_manager.show_upgrade_cards(picks)

func _on_upgrade_chosen(id: String) -> void:
	# Runde 49: Der Client schickt seine Wahl an den HOST, der Host
	# wendet sie an UND broadcastet sie, damit auch der andere Client
	# die Stats wirklich bekommt (vorher passierte dort nichts).
	if coop_client and NetManager.active:
		NetManager.c_send_upgrade_choice(int(my_slot), id)
		_ldiag("UPGRADE", "Client schickt Wahl '%s' an Host, warte auf Bestaetigung (tree bleibt PAUSED)" % id)
		return
	_apply_upgrade_local(id)
	if coop_host and NetManager.active:
		NetManager.h_send_upgrade_applied(int(my_slot), id)
	pending_upgrades -= 1
	if pending_upgrades > 0 and current_state == GameState.PLAYING:
		_open_upgrade_ui()
	else:
		_ldiag("UPGRADE", "Host schliesst Karten -> tree.paused=false")
		get_tree().paused = false


func _apply_upgrade_local(id: String) -> void:
	# Runde 49: Die eigentliche Wirkung - fuer Host UND Client getrennt
	# anwendbar, damit die Stats beim Client nicht fehlen.
	upg_stacks[id] = int(upg_stacks.get(id, 0)) + 1
	if not is_instance_valid(player):
		return
	match id:
		"power":
			player.damage_mult *= 1.25
		"turbo":
			player.cooldown_mult *= 0.85
		"speed":
			player.speed_mult *= 1.15
		"vitality":
			player.call("add_max_health")
		"guardian":
			player.call("add_shield", 2)
		"vampire":
			player.vampire_per = 12


func _on_net_upgrade_applied(slot: int, id: String) -> void:
	# Runde 49: Der Client bekommt die bestaetigte Upgrade-Wahl
	_ldiag("UPGRADE", "Client bekam Bestaetigung '%s' fuer Slot %d (pending=%d)" % [id, slot, pending_upgrades])
	_apply_upgrade_local(id)
	pending_upgrades = maxi(0, pending_upgrades - 1)
	if pending_upgrades > 0 and current_state == GameState.PLAYING:
		_open_upgrade_ui()
	else:
		_ldiag("UPGRADE", "Client schliesst Karten -> tree.paused=false")
		get_tree().paused = false


func _on_net_upgrade_options(opts: Array) -> void:
	# Runde 49: Der Client oeffnet das Upgrade-Fenster mit den
	# Optionen des Hosts
	if opts.is_empty():
		_ldiag("UPGRADE", "Client bekam LEERE Optionen - ignoriert")
		return
	_ldiag("UPGRADE", "Client oeffnet Karten (%d) -> tree.paused=true" % opts.size())
	get_tree().paused = true
	ui_manager.show_upgrade_cards(opts)

func _on_monster_killed(points: int, owner_slot: int = 0, monster_pos: Vector2 = Vector2.ZERO):
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
	# Wellen-Modus: Münzen für den Shop (Punkt 6)
	if game_mode == 1:
		# Runde 31: exakt nachzaehlen (Pflanzen/Ranken zaehlen nicht mit)
		_recount_wave()
		# Runde 33: Muenzen dem Schuetzen zuordnen (Variante B)
		var _slot: int = owner_slot if owner_slot > 0 else my_slot
		# Runde 49c: 0.5 -> 0.24. Vorher bekam man pro Welle so
		# viel Gold, dass der ganze Shop auf einmal kaufbar war.
		var _gain: int = maxi(1, int(round(float(points) * 0.24 * float(diff_data()["coins"])))) * coins_bounty
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

# --- Biome (G4): Schwellen 500 / 1200 / 2200 Punkte ---
func _check_biome() -> void:
	# Karten (Runde 11): eine feste Karte bleibt in ihrem Biom
	var md := map_data()
	if not bool(md.get("progressive", true)):
		var want_fixed := str(md["biome"])
		if biome_id != want_fixed:
			biome_id = want_fixed
			map_generator.set_biome(biome_id)
			ui_manager.show_banner(_biome_name(want_fixed), _biome_color(want_fixed))
		return
	var want := "meadow"
	# Runde 38: im Wellen-Modus nach Wellenzahl, im Endlos-Modus nach Score
	var steps: Array = BIOME_STEPS_WAVE if game_mode == 1 else BIOME_STEPS
	var prog: int = wave if game_mode == 1 else score
	for step in steps:
		if prog >= int(step.get("wave", 999999) if game_mode == 1 else step.get("score", 999999)):
			want = str(step["id"])
	if want == biome_id:
		return
	biome_id = want
	map_generator.set_biome(want)
	monster_spawner.spawn_interval = maxf(2.5, monster_spawner.spawn_interval * 0.9)
	ui_manager.show_banner(_biome_name(want), _biome_color(want))
	SoundManager.play("levelup")

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
	if not is_instance_valid(player):
		return
	var ev: String = EVENTS[randi() % EVENTS.size()]
	match ev:
		"swarm":
			ui_manager.show_banner("MONSTERSTURM!", Color(1.0, 0.45, 0.35))
			for i in range(14):
				var a := randf_range(0.0, TAU)
				spawn_monster_at(player.position + Vector2(cos(a), sin(a)) * randf_range(420.0, 620.0))
		"elite":
			ui_manager.show_banner("ELITEWELLE!", Color(0.85, 0.55, 1.0))
			for i in range(3):
				var a2 := randf_range(0.0, TAU)
				spawn_monster_at(player.position + Vector2(cos(a2), sin(a2)) * randf_range(420.0, 620.0), 6)
			for i in range(3):
				var a3 := randf_range(0.0, TAU)
				spawn_monster_at(player.position + Vector2(cos(a3), sin(a3)) * randf_range(420.0, 620.0), 3, true)
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
	if is_instance_valid(player):
		player.call("take_damage", damage)

func restart_game(direct_start: bool = false):
	# Sicherheitsnetz: Pause & Karten-Overlay aufraeumen
	if get_tree().paused:
		get_tree().paused = false
	ui_manager.hide_upgrade_cards()
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
		file.close()


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
