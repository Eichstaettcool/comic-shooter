# NetManager.gd - Autoload: LAN-Multiplayer (ENet + UDP-Beacon-Discovery)
# Recherche-Basis: Godot High-Level-Multiplayer (ENetMultiplayerPeer) +
# PacketPeerUDP.set_broadcast_enabled / PacketUDPServer fuer die Hostliste.
extends Node

var ENET_PORT: int = 7777      # per COMIC_ENET_PORT aenderbar (Tests/mehrere Hosts)
const BEACON_PORT := 7778
const BEACON_TAG := "CSHV1"
const MAX_CLIENTS := 3          # Host + bis zu 3 Mitspieler (4 Spieler gesamt)
const SEND_HZ := 15.0
const MAX_PLAYERS := 4

var active: bool = false
var is_host: bool = false
var partner_id: int = 0
var discovered: Dictionary = {}     # ip -> Anzeigename
var status_text: String = ""

# --- Lobby / Mehrspieler (Runde 10) ---
var player_count: int = 2           # gewuenschte Gesamtzahl (2-4), vor host_game setzen
var my_slot: int = 1                # Host = 1, Clients 2..4
var lobby: Dictionary = {}          # peer_id -> {slot, name, color, hat, ready}
var lobby_active: bool = false

signal lobby_changed
signal partner_state(x: float, y: float, hp: int, mx: int, weapon_name: String, angle_deg: float, shield: int)
signal partner_left
signal run_start_signal             # Host hat freigegeben -> Client startet
signal conn_failed(why: String)
signal hosts_changed
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

var _broadcaster: PacketPeerUDP = null
var _listener: PacketPeerUDP = null
var _beacon_t: float = 0.0
var _dests_t: float = 0.0
var _beacon_dests: Array = []

func _ready() -> void:
	var penv := OS.get_environment("COMIC_ENET_PORT")
	if penv != "":
		ENET_PORT = int(penv)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_conn_failed)
	multiplayer.server_disconnected.connect(_on_server_down)

# Broadcast-Ziele: Limited-Broadcast + Broadcast-Adresse jedes Interfaces.
# (Manche WLAN-Router/APs verwerfen 255.255.255.255 — dann greift die
#  Subnetz-Broadcast-Adresse, z.B. 192.168.1.255)
func _refresh_beacon_dests() -> void:
	_beacon_dests.clear()
	_beacon_dests.append("255.255.255.255")
	for iface in IP.get_local_interfaces():
		var bcs = iface.get("broadcasts", [])
		for b in bcs:
			if b != "" and not _beacon_dests.has(b):
				_beacon_dests.append(b)

# ---------------- Host ----------------
func host_game(wanted_players: int = 2) -> String:
	player_count = clampi(wanted_players, 2, MAX_PLAYERS)
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(ENET_PORT, player_count - 1)
	if err != OK:
		return "Server-Start fehlgeschlagen (Port %d belegt?)" % ENET_PORT
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = true
	my_slot = 1
	partner_id = 0
	# Lobby: Host ist Slot 1 und immer "bereit"
	lobby.clear()
	lobby[1] = { "slot": 1, "name": "", "color": 0, "hat": 0, "ready": true, "host": true }
	lobby_active = true
	if _broadcaster == null:
		_broadcaster = PacketPeerUDP.new()
		_broadcaster.set_broadcast_enabled(true)   # Pflicht vor Broadcast (Godot-Doku)
		# Explizit auf einen freien lokalen Port binden, damit der Beacon-Socket
		# nicht mit dem ENet-Serverport (7777) kollidiert.
		_broadcaster.bind(0, "0.0.0.0")
	_broadcaster.set_dest_address("255.255.255.255", BEACON_PORT)
	_beacon_t = 0.0
	_dests_t = 0.0
	_refresh_beacon_dests()
	# Scan-Socket schliessen, falls offen (Host braucht keinen)
	stop_scan()
	set_process(true)
	status_text = "Host aktiv auf Port %d" % ENET_PORT
	return ""

# ---------------- Discovery (Scan) ----------------
func start_scan() -> String:
	discovered.clear()
	if _listener == null:
		_listener = PacketPeerUDP.new()
		var err: int = _listener.bind(BEACON_PORT, "0.0.0.0")
		if err != OK:
			_listener = null
			return "Scan nicht moeglich (Port %d belegt?)" % BEACON_PORT
	set_process(true)
	return ""

func stop_scan() -> void:
	if _listener != null:
		_listener.close()
		_listener = null

# ---------------- Client ----------------
func join_game(ip: String) -> String:
	var addr := ip.strip_edges()
	if addr == "":
		return "Keine IP angegeben"
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(addr, ENET_PORT)
	if err != OK:
		return "Verbindungsaufbau fehlgeschlagen"
	multiplayer.multiplayer_peer = peer
	active = true
	is_host = false
	stop_scan()
	status_text = "Verbinde mit %s ..." % addr
	return ""

func leave() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	active = false
	is_host = false
	partner_id = 0
	my_slot = 1
	lobby.clear()
	lobby_active = false
	if _broadcaster != null:
		_broadcaster.close()
		_broadcaster = null
	stop_scan()
	discovered.clear()
	set_process(false)

func has_partner() -> bool:
	return active and not multiplayer.get_peers().is_empty()

# ---------------- Polling ----------------
func _process(delta: float) -> void:
	# Host sendet Beacon (0.6s Takt) an alle Broadcast-Adressen
	if is_host and _broadcaster != null:
		_beacon_t += delta
		_dests_t += delta
		if _dests_t >= 5.0:
			_dests_t = 0.0
			_refresh_beacon_dests()
		if _beacon_t >= 0.6:
			_beacon_t = 0.0
			var msg := "%s|%s|%d" % [BEACON_TAG, OS.get_name(), ENET_PORT]
			var buf := msg.to_utf8_buffer()
			for d in _beacon_dests:
				_broadcaster.set_dest_address(str(d), BEACON_PORT)
				_broadcaster.put_packet(buf)
	# Client lauscht auf Beacons
	if _listener != null:
		var changed := false
		while _listener.get_available_packet_count() > 0:
			var bytes: PackedByteArray = _listener.get_packet()
			var txt: String = bytes.get_string_from_utf8()
			if txt.begins_with(BEACON_TAG + "|"):
				var ip: String = _listener.get_packet_ip()
				var parts: PackedStringArray = txt.split("|")
				var nm: String = parts[1] if parts.size() > 1 else "Host"
				if not discovered.has(ip):
					discovered[ip] = nm
					changed = true
		if changed:
			hosts_changed.emit()

# ---------------- Zustands-Sync ----------------
func send_partner_state(pos: Vector2, hp: int, mx: int, weapon_name: String, angle_deg: float, shield: int) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	push_state.rpc(pos.x, pos.y, hp, mx, weapon_name, angle_deg, shield)

# Runde 49: LAN-Bugs - Signale fuer Upgrade-/Death-/Downed-Sync
signal upgrade_options_received(opts: Array)
signal upgrade_choice_received(slot: int, id: String)
signal upgrade_applied_received(slot: int, id: String)
signal game_over_data(score_v: int, best_v: int, gold_gain: int, gold_total: int)
signal downed_state_received(slot: int, is_downed: bool, hp: int, progress: float)


@rpc("any_peer", "call_remote", "unreliable")
func push_state(x: float, y: float, hp: int, mx: int, weapon_name: String, angle_deg: float, shield: int) -> void:
	partner_id = multiplayer.get_remote_sender_id()
	partner_state.emit(x, y, hp, mx, weapon_name, angle_deg, shield)

@rpc("authority", "call_local", "reliable")
func begin_run() -> void:
	run_start_signal.emit()

# ---------------- Callbacks ----------------
func _on_peer_connected(id: int) -> void:
	partner_id = id
	if is_host:
		# Lobby (Runde 10): NICHT automatisch starten — der Host drueckt START.
		if not lobby.has(id):
			lobby[id] = { "slot": _free_slot(), "name": "", "color": 0, "hat": 0, "ready": false, "host": false }
		h_lobby_broadcast()
		peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	partner_id = 0
	if is_host and lobby.has(id):
		lobby.erase(id)
		h_lobby_broadcast()
	peer_left.emit(id)
	partner_left.emit()

func _free_slot() -> int:
	var used := [1]
	for k in lobby.keys():
		used.append(int(lobby[k]["slot"]))
	for s in range(2, MAX_PLAYERS + 1):
		if not used.has(s):
			return s
	return 2

func slot_of_peer(pid: int) -> int:
	if lobby.has(pid):
		return int(lobby[pid]["slot"])
	return 0

func occupied_slots() -> Array:
	var out: Array = []
	for k in lobby.keys():
		out.append(int(lobby[k]["slot"]))
	out.sort()
	return out

# ---------------- Lobby-Sync (Host -> alle) ----------------
func h_lobby_broadcast() -> void:
	if not is_host:
		return
	my_slot = 1
	if multiplayer.get_peers().is_empty():
		lobby_changed.emit()
		return
	coop_lobby.rpc(lobby, player_count)
	lobby_changed.emit()

func c_send_lobby_profile(nm: String, color: int, hat: int) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_profile.rpc_id(1, nm, color, hat)

func c_send_lobby_ready(r: bool) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_ready.rpc_id(1, r)

# Host startet den Run fuer ALLE gleichzeitig
func h_start_run() -> void:
	if not is_host:
		return
	lobby_active = false
	coop_begin.rpc()

func all_ready() -> bool:
	for k in lobby.keys():
		if int(k) == 1:
			continue
		if not bool(lobby[k].get("ready", false)):
			return false
	return lobby.size() > 1

func _on_conn_failed() -> void:
	active = false
	conn_failed.emit("Verbindung fehlgeschlagen — IP/Host pruefen")

func _on_server_down() -> void:
	active = false
	partner_left.emit()

# ============================================================
# CO-OP (Phase 2): Host simuliert die EINE Welt, Client rendert + sendet Input
# ============================================================
var coop_role: int = 0      # 1 = Host, 2 = Client

signal coop_init_received(net_seed: int, chests: PackedFloat32Array, zone_data: PackedFloat32Array, biome: String, map_id: String)
signal world_synced(score: int, combo: int, biome: String, freeze: float, rapid: float, gold: float, boss_hp: int, boss_max: int)
signal spectator_received(slot: int)
signal my_player_synced(x: float, y: float, hp: int, mx: int, weapon: String, angle: float, shield: int)
signal mobs_synced(data: PackedFloat32Array)
signal items_synced(data: PackedFloat32Array, types: PackedStringArray, rarities: PackedStringArray)
signal shot_synced(x: float, y: float, angle: float)
signal coop_game_over()
signal remote_input_received(peer_id: int, dx: float, dy: float, shoot: bool, angle: float)
signal coop_profile_received(peer_id: int, peer_name: String, color: int, hat: int, rig: int)
signal players_synced(data: PackedFloat32Array, weapons: PackedStringArray)

func h_send_profile(peer_name: String, color: int, hat: int, rig: int = 0) -> void:
	if multiplayer.get_peers().is_empty():
		return
	coop_profile.rpc(peer_name, color, hat, rig)

func c_send_profile(peer_name: String, color: int, hat: int, rig: int = 0) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_profile.rpc_id(1, peer_name, color, hat, rig)

# ---------- Host: senden ----------
func h_send_init(net_seed: int, chests: PackedFloat32Array, zone_data: PackedFloat32Array, biome: String, map_id: String = "") -> void:
	coop_init.rpc(net_seed, chests, zone_data, biome, map_id)

func h_send_world(score_v: int, combo_v: int, biome: String, frz: float, rap: float, gold: float, bhp: int, bmx: int) -> void:
	coop_world.rpc(score_v, combo_v, biome, frz, rap, gold, bhp, bmx)

func h_send_my_player(pos: Vector2, hp: int, mx: int, weapon: String, angle: float, shield: int) -> void:
	coop_player.rpc(pos.x, pos.y, hp, mx, weapon, angle, shield)

func h_send_mobs(data: PackedFloat32Array) -> void:
	if multiplayer.get_peers().is_empty():
		return
	coop_mobs.rpc(data)

func h_send_items(data: PackedFloat32Array, types: PackedStringArray, rarities: PackedStringArray) -> void:
	if multiplayer.get_peers().is_empty():
		return
	coop_items.rpc(data, types, rarities)

func h_send_shot(x: float, y: float, angle: float) -> void:
	coop_shot.rpc(x, y, angle)

func h_send_game_over() -> void:
	coop_over.rpc()

# ---------- Client: senden ----------
func c_send_input(dir: Vector2, shoot: bool, angle: float) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_input.rpc_id(1, dir.x, dir.y, shoot, angle)

# ============================================================
# Runde 15: Wellen-/Shop-Zustand + Kisten-Interaktion (Nicht-Host)
# ============================================================
signal wave_state_received(wave_v: int, in_shop: bool, shop_t: float, remaining: int, coins_v: int, mode: int)
signal chest_open_request_received(pos: Vector2)

func h_send_wave_state(wave_v: int, in_shop: bool, shop_t: float, remaining: int, coins_v: int, mode: int) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_wave_state.rpc(wave_v, in_shop, shop_t, remaining, coins_v, mode)

@rpc("authority", "call_remote", "reliable")
func coop_wave_state(wave_v: int, in_shop: bool, shop_t: float, remaining: int, coins_v: int, mode: int) -> void:
	wave_state_received.emit(wave_v, in_shop, shop_t, remaining, coins_v, mode)

# ============================================================
# Runde 33: Variante B - eigener Shop pro Spieler
# ============================================================
signal shop_state_received(coins_by_slot: PackedInt32Array, ready_flags: PackedByteArray,
		level_v: int, xp_v: int, xp_need: int, level_need: int)
signal shop_buy_requested(item_id: String)
signal shop_offers_received(ids: PackedStringArray, prices: PackedInt32Array,
	bought: PackedByteArray, buys_left: int, buys_max: int)
signal shop_ready_received()

func h_send_shop_state(coins_by_slot: PackedInt32Array, ready_flags: PackedByteArray,
		level_v: int, xp_v: int, xp_need: int, level_need: int) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_shop_state.rpc(coins_by_slot, ready_flags, level_v, xp_v, xp_need, level_need)

@rpc("authority", "call_remote", "reliable")
func coop_shop_state(coins_by_slot: PackedInt32Array, ready_flags: PackedByteArray,
		level_v: int, xp_v: int, xp_need: int, level_need: int) -> void:
	shop_state_received.emit(coins_by_slot, ready_flags, level_v, xp_v, xp_need, level_need)

func c_send_shop_buy(item_id: String) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_shop_buy.rpc_id(1, item_id)

signal hit_requested(monster_id: int, damage: int)

@rpc("any_peer", "call_remote", "reliable")
func c_hit(monster_id: int, damage: int) -> void:
	# Client meldet einen Treffer - der Host entscheidet ueber den Schaden
	hit_requested.emit(monster_id, damage)


func c_send_hit(monster_id: int, damage: int) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	c_hit.rpc_id(1, monster_id, damage)


@rpc("any_peer", "call_remote", "reliable")
func coop_shop_buy(item_id: String) -> void:
	shop_buy_requested.emit(item_id)


func h_send_shop_offers(ids: PackedStringArray, prices: PackedInt32Array,
		bought: PackedByteArray, buys_left: int, buys_max: int) -> void:
	# Runde 52: Der Client muss DIESELBEN Angebote sehen wie der Host.
	# Vorher zeigte er SHOP_ITEMS (Gesamtkatalog) und Kaeufe ausserhalb
	# des Angebots wurden stillschweigend abgelehnt.
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_shop_offers.rpc(ids, prices, bought, buys_left, buys_max)


@rpc("authority", "call_remote", "reliable")
func coop_shop_offers(ids: PackedStringArray, prices: PackedInt32Array,
		bought: PackedByteArray, buys_left: int, buys_max: int) -> void:
	shop_offers_received.emit(ids, prices, bought, buys_left, buys_max)

func c_send_shop_ready() -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_shop_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func coop_shop_ready() -> void:
	shop_ready_received.emit()

# Runde 34: Ping-Markierung (Partner markiert eine Stelle)
signal ping_received(x: float, y: float)

func c_send_ping(x: float, y: float) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_ping.rpc_id(1, x, y)

@rpc("any_peer", "call_remote", "reliable")
func coop_ping(x: float, y: float) -> void:
	ping_received.emit(x, y)

func c_send_chest_open(pos: Vector2) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_chest_open.rpc_id(1, pos)

@rpc("any_peer", "call_remote", "reliable")
func coop_chest_open(pos: Vector2) -> void:
	chest_open_request_received.emit(pos)

func get_local_ip() -> String:
	for iface in IP.get_local_interfaces():
		if not bool(iface.get("loopback", false)):
			var addrs = iface.get("addresses", [])
			for a in addrs:
				var s := str(a)
				if s.begins_with("192.168.") or s.begins_with("10.") or s.begins_with("172."):
					return s
	for iface in IP.get_local_interfaces():
		var addrs2 = iface.get("addresses", [])
		for a in addrs2:
			if not str(a).begins_with("127."):
				return str(a)
	return "127.0.0.1"

# ---------- RPCs: Host -> Client (Autoritaet = Server) ----------
@rpc("authority", "call_remote", "reliable")
func coop_init(net_seed: int, chests: PackedFloat32Array, zone_data: PackedFloat32Array, biome: String, map_id: String = "") -> void:
	coop_init_received.emit(net_seed, chests, zone_data, biome, map_id)

@rpc("authority", "call_remote", "reliable")
func coop_world(score_v: int, combo_v: int, biome: String, frz: float, rap: float, gold: float, bhp: int, bmx: int) -> void:
	world_synced.emit(score_v, combo_v, biome, frz, rap, gold, bhp, bmx)

@rpc("authority", "call_remote", "unreliable")
func coop_player(x: float, y: float, hp: int, mx: int, weapon: String, angle: float, shield: int) -> void:
	my_player_synced.emit(x, y, hp, mx, weapon, angle, shield)

@rpc("authority", "call_remote", "unreliable")
func coop_mobs(data: PackedFloat32Array) -> void:
	mobs_synced.emit(data)

@rpc("authority", "call_remote", "unreliable")
func coop_items(data: PackedFloat32Array, types: PackedStringArray, rarities: PackedStringArray) -> void:
	items_synced.emit(data, types, rarities)

@rpc("authority", "call_remote", "unreliable")
func coop_shot(x: float, y: float, angle: float) -> void:
	shot_synced.emit(x, y, angle)

@rpc("authority", "call_remote", "reliable")
func coop_over() -> void:
	coop_game_over.emit()


# Runde 49: "Run verloren" MIT Daten (Score/Gold) an alle Clients.
# Der bestehende coop_over bleibt fuer die einfache Variante.
func h_send_game_over_data(score_v: int, best_v: int, gold_gain: int, gold_total: int) -> void:
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_game_over_data.rpc(score_v, best_v, gold_gain, gold_total)


@rpc("authority", "call_remote", "reliable")
func coop_game_over_data(score_v: int, best_v: int, gold_gain: int, gold_total: int) -> void:
	game_over_data.emit(score_v, best_v, gold_gain, gold_total)

# ---------- RPC: Client -> Host ----------
@rpc("any_peer", "call_remote", "unreliable")
func coop_input(dx: float, dy: float, shoot: bool, angle: float) -> void:
	if not is_host:
		return
	remote_input_received.emit(multiplayer.get_remote_sender_id(), dx, dy, shoot, angle)

# Profil (Name/Farbe/Hut) — im Run in beide Richtungen, in der Lobby Client -> Host
@rpc("any_peer", "call_remote", "reliable")
func coop_profile(peer_name: String, color: int, hat: int, rig: int = 0) -> void:
	var from_id := multiplayer.get_remote_sender_id()
	if is_host and lobby.has(from_id):
		lobby[from_id]["name"] = peer_name
		lobby[from_id]["color"] = color
		lobby[from_id]["hat"] = hat
		lobby[from_id]["rig"] = rig
		h_lobby_broadcast()
	coop_profile_received.emit(from_id, peer_name, color, hat, rig)

@rpc("any_peer", "call_remote", "reliable")
func coop_ready(r: bool) -> void:
	var from_id := multiplayer.get_remote_sender_id()
	if is_host and lobby.has(from_id):
		lobby[from_id]["ready"] = r
		h_lobby_broadcast()

# Lobby-Stand (Host -> Clients)
@rpc("authority", "call_remote", "reliable")
func coop_lobby(data: Dictionary, maxp: int) -> void:
	lobby = data
	player_count = maxp
	var my_id := multiplayer.get_unique_id()
	if lobby.has(my_id):
		my_slot = int(lobby[my_id]["slot"])
	lobby_changed.emit()

# Host gibt den Run frei -> alle starten gleichzeitig
@rpc("authority", "call_local", "reliable")
func coop_begin() -> void:
	lobby_active = false
	run_start_signal.emit()

# Alle Spieler-Zustaende (Host -> Clients)
func h_send_players(data: PackedFloat32Array, weapons: PackedStringArray) -> void:
	if multiplayer.get_peers().is_empty():
		return
	coop_players.rpc(data, weapons)

@rpc("authority", "call_remote", "unreliable")
func coop_players(data: PackedFloat32Array, weapons: PackedStringArray) -> void:
	players_synced.emit(data, weapons)


# ============================================================
# Runde 49: LAN-Sync fuer Upgrade-Fenster, Upgrades, Game-Over
# und Downed/Revive. Der HOST ist autoritativ, der CLIENT zeigt an.
# ============================================================


func h_send_upgrade_options(opts: Array) -> void:
	# Runde 49: Der Host schickt die 3 Upgrade-Optionen an alle Clients
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_upgrade_options.rpc(opts)


@rpc("authority", "call_remote", "reliable")
func coop_upgrade_options(opts: Array) -> void:
	upgrade_options_received.emit(opts)


func h_apply_upgrade(slot: int, id: String) -> void:
	# Runde 49: Der Host bestaetigt eine Upgrade-Wahl
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_apply_upgrade.rpc(slot, id)


@rpc("authority", "call_remote", "reliable")
func coop_apply_upgrade(slot: int, id: String) -> void:
	upgrade_applied_received.emit(slot, id)


signal revive_request_received(slot: int, active: bool)

signal busy_received(slot: int, busy: bool)


func c_send_busy(busy: bool) -> void:
	# B3: Client meldet dem Host, dass er Karten waehlt (Welt laeuft weiter,
	# er ist in dieser Zeit unverwundbar).
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_busy_rpc.rpc_id(1, busy)


@rpc("any_peer", "call_remote", "reliable")
func coop_busy_rpc(busy: bool) -> void:
	if not multiplayer.is_server():
		return
	var pid: int = multiplayer.get_remote_sender_id()
	busy_received.emit(int(slot_of_peer(pid)), busy)


func c_send_revive(slot: int, active: bool) -> void:
	# Client meldet dem Host, dass er beim liegenden Partner aufweckt.
	if not active or multiplayer.get_peers().is_empty():
		pass
	rpc_id(1, "srv_revive_request", slot, active)


@rpc("any_peer", "call_remote", "reliable")
func srv_revive_request(slot: int, active: bool) -> void:
	if not multiplayer.is_server():
		return
	revive_request_received.emit(slot, active)


func h_send_downed_state(slot: int, is_downed: bool, hp: int, progress: float) -> void:
	# Runde 49: Downed/Revive-Zustand (unreliable reicht - 10 Hz)
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_downed_state.rpc(slot, is_downed, hp, progress)


func h_send_spectator(slot: int) -> void:
	# Runde 51: Ein Spieler ist endgueltig tot und wird Zuschauer
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_spectator.rpc(slot)


@rpc("authority", "call_remote", "reliable")
func coop_spectator(slot: int) -> void:
	spectator_received.emit(slot)


@rpc("authority", "call_remote", "unreliable")
func coop_downed_state(slot: int, is_downed: bool, hp: int, progress: float) -> void:
	downed_state_received.emit(slot, is_downed, hp, progress)


func c_send_upgrade_choice(slot: int, id: String) -> void:
	# Runde 49: Client -> Host: "ich habe Upgrade X gewaehlt"
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_upgrade_choice.rpc_id(1, slot, id)


@rpc("any_peer", "call_remote", "reliable")
func coop_upgrade_choice(slot: int, id: String) -> void:
	upgrade_choice_received.emit(slot, id)


func h_send_upgrade_applied(slot: int, id: String) -> void:
	# Runde 49: Host -> alle: "Upgrade X wurde angewendet"
	if not active or multiplayer.get_peers().is_empty():
		return
	coop_upgrade_applied.rpc(slot, id)


@rpc("authority", "call_remote", "reliable")
func coop_upgrade_applied(slot: int, id: String) -> void:
	upgrade_applied_received.emit(slot, id)
