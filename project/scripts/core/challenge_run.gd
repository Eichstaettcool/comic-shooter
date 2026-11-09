class_name ChallengeRun
extends RefCounted

# v1.45 (C1): Aufgaben als echte Spielmodi.
#
# Jede Aufgabe ist ein eigener Run im RUNDEN-Modus mit eigener Regel, eigenen
# Runden und je Schwierigkeitsstufe eigener Diamantenzahl. In einer Aufgabe
# gibt es keine Wahl mehr - die Einschraenkung IST die Aufgabe (z. B. nur
# Revolver, keine Heilung, keine Schild-Pickups).
#
# Zustand bleibt in der Fassade (game_manager), hier liegt nur die Logik.

var host: Node = null
var id: String = ""
var stufe: String = "normal"
var stufe_idx: int = 1
var runden_max: int = 0
var gems_reward: int = 0
var ziel_wert: int = 0
var zeit_limit: float = 0.0
var sperren: Array = []
var startwaffe: String = ""
var lp_start: int = 0
var aktiv: bool = false
var beendet: bool = false
var fortschritt: int = 0
var runde_aktuell: int = 0
var start_ms: int = 0
var boss_gezaehlt: int = 0
var kisten: int = 0
var schilde: int = 0
# v1.46 (B2): Zaehler fuer die neuen Aufgaben
var kills: int = 0
var muenzen: int = 0
var treffer: int = 0
var kein_treffer: bool = false

# C1: drei Stufen je Aufgabe. Runden und Diamanten sind gestaffelt
# (LEICHT < NORMAL < HART), damit HART immer mehr gibt als LEICHT.
const STUFEN := ["leicht", "normal", "hart"]
const STUFEN_LABEL := { "leicht": "LEICHT", "normal": "NORMAL", "hart": "HART" }

const DEFS := [
	{
		"id": "revolver", "name": "REVOLVER-RUNDE", "icon": "revolver",
		"desc": "Nur der Revolver, keine andere Waffe",
		"startwaffe": "weapon_revolver",
		"sperren": ["waffen_pickups", "waffenkarten"],
		"runden": [8, 12, 16], "gems": [40, 90, 160], "ziel": "runden", "ziel_wert": [8, 12, 16],
	},
	{
		"id": "eisern", "name": "EISERN", "icon": "shield",
		"desc": "Mit 1 Leben die Runden ueberstehen - keine Heilung",
		"startwaffe": "",
		"sperren": ["heilung", "herz_pickup", "maxhealth_kauf"],
		"lp_start": 1,
		"runden": [3, 5, 8], "gems": [60, 120, 200], "ziel": "runden", "ziel_wert": [3, 5, 8],
	},
	{
		"id": "boss", "name": "BOSS-JAEGER", "icon": "crown",
		"desc": "Drei Bosse legen - ohne ein Schild zu benutzen",
		"startwaffe": "",
		"sperren": ["schild_pickup"],
		"runden": [12, 16, 20], "gems": [40, 90, 150], "ziel": "bosse", "ziel_wert": [3, 3, 3],
	},
	{
		"id": "schnell", "name": "BLITZSCHNELL", "icon": "clock",
		"desc": "Welle 10 erreichen, bevor die Uhr abgelaufen ist",
		"startwaffe": "",
		"sperren": [],
		"runden": [10, 10, 10], "gems": [35, 80, 140], "ziel": "zeit", "ziel_wert": [10, 10, 10],
		"zeit": [420.0, 360.0, 300.0],
	},
	{
		"id": "ohne_schild", "name": "OHNE SCHILD", "icon": "heart",
		"desc": "Runden ohne ein Schild-Pickup ueberstehen",
		"startwaffe": "",
		"sperren": ["schild_pickup"],
		"runden": [5, 10, 14], "gems": [30, 70, 120], "ziel": "runden", "ziel_wert": [5, 10, 14],
	},
	# --- v1.46 (B1): sechs weitere Aufgaben, je drei Stufen ---
	{
		"id": "flinte", "name": "FLINTEN-FIEBER", "icon": "revolver",
		"desc": "Nur die Schrotflinte, keine andere Waffe",
		"startwaffe": "weapon_shotgun",
		"sperren": ["waffen_pickups", "waffenkarten"],
		"runden": [8, 12, 16], "gems": [45, 95, 165], "ziel": "runden", "ziel_wert": [8, 12, 16],
	},
	{
		"id": "unberuehrt", "name": "UNBERUEHRT", "icon": "shield",
		"desc": "Runden ohne einen einzigen Treffer",
		"startwaffe": "",
		"sperren": [], "kein_treffer": true,
		"runden": [5, 8, 11], "gems": [70, 150, 260], "ziel": "runden", "ziel_wert": [5, 8, 11],
	},
	{
		"id": "kopfgeld", "name": "KOPFGELD", "icon": "crown",
		"desc": "Monster erledigen - ohne Waffen-Pickup, nur die Startwaffe",
		"startwaffe": "",
		"sperren": ["waffen_pickups", "waffenkarten"],
		"runden": [10, 12, 16], "gems": [30, 65, 120], "ziel": "kills", "ziel_wert": [60, 120, 200],
	},
	{
		"id": "goldrausch", "name": "GOLDRAUSCH", "icon": "chest",
		"desc": "Muenzen sammeln - ohne Heilung und ohne zusaetzliche Herzen",
		"startwaffe": "",
		"sperren": ["heilung", "herz_pickup"],
		"runden": [10, 14, 18], "gems": [40, 90, 160], "ziel": "muenzen", "ziel_wert": [300, 700, 1200],
	},
	{
		"id": "ohne_vorrat", "name": "OHNE VORRAT", "icon": "heart",
		"desc": "Runden ohne Trank und ohne Bombe ueberstehen",
		"startwaffe": "",
		"sperren": ["verbrauch"],
		"runden": [8, 12, 16], "gems": [40, 90, 160], "ziel": "runden", "ziel_wert": [8, 12, 16],
	},
	{
		"id": "nahkampf", "name": "NAHKAMPF", "icon": "revolver",
		"desc": "Nur die Startpistole, kein Trank, keine Bombe",
		"startwaffe": "weapon_pistol",
		"sperren": ["waffen_pickups", "waffenkarten", "verbrauch"],
		"runden": [8, 12, 16], "gems": [45, 95, 165], "ziel": "runden", "ziel_wert": [8, 12, 16],
	},
	{
		"id": "sparsam", "name": "SPARSAM", "icon": "heart",
		"desc": "Ohne Trank, Bombe und Schild - nur du und die Waffe",
		"startwaffe": "",
		"sperren": ["verbrauch", "schild_pickup"],
		"runden": [6, 10, 14], "gems": [50, 100, 175], "ziel": "runden", "ziel_wert": [6, 10, 14],
	}]


static func def_of(id2: String) -> Dictionary:
	for d in DEFS:
		if str(d["id"]) == id2:
			return d
	return {}


static func stufe_index(stufe2: String) -> int:
	for i in range(STUFEN.size()):
		if STUFEN[i] == stufe2:
			return i
	return 1


func setup(id2: String, stufe2: String) -> bool:
	var d: Dictionary = def_of(id2)
	if d.is_empty():
		print("[CHAL][FEHLER] unbekannte_aufgabe id=%s" % id2)
		return false
	id = id2
	stufe = stufe2 if STUFEN.has(stufe2) else "normal"
	stufe_idx = stufe_index(stufe)
	runden_max = int((d["runden"] as Array)[stufe_idx])
	gems_reward = int((d["gems"] as Array)[stufe_idx])
	ziel_wert = int((d["ziel_wert"] as Array)[stufe_idx])
	zeit_limit = float((d.get("zeit", [0.0, 0.0, 0.0]) as Array)[stufe_idx])
	sperren = (d.get("sperren", []) as Array).duplicate()
	startwaffe = str(d.get("startwaffe", ""))
	lp_start = int(d.get("lp_start", 0))
	fortschritt = 0
	runde_aktuell = 0
	boss_gezaehlt = 0
	kisten = 0
	schilde = 0
	kills = 0
	muenzen = 0
	treffer = 0
	kein_treffer = bool(d.get("kein_treffer", false))
	aktiv = false
	beendet = false
	print("[CHAL][STUFE] id=%s stufe=%s runden=%d diamanten=%d ziel=%s ziel_wert=%d zeit=%.0fs" % [
		id, stufe, runden_max, gems_reward, str(d["ziel"]), ziel_wert, zeit_limit])
	return true


func hat(sperre: String) -> bool:
	return sperren.has(sperre)


func start(h: Node) -> void:
	host = h
	aktiv = true
	beendet = false
	start_ms = Time.get_ticks_msec()
	fortschritt = 0
	boss_gezaehlt = 0
	kisten = 0
	schilde = 0
	kills = 0
	muenzen = 0
	treffer = 0
	_apply_rules()
	print("[CHAL][START] id=%s stufe=%s runden=%d waffe=%s sperren=%s" % [
		id, stufe, runden_max,
		(startwaffe.replace("weapon_", "").to_upper() if startwaffe != "" else "frei"), str(sperren)])


func _apply_rules() -> void:
	if host == null:
		return
	var p = host.get("player")
	if startwaffe != "" and p != null and is_instance_valid(p):
		p.set("owned_weapons", [startwaffe])
		if p.has_method("switch_weapon"):
			p.call("switch_weapon", startwaffe)
		print("[CHAL][REGEL] id=%s waffe=%s pickups=%d waffenkarten=%d" % [
			id, startwaffe.replace("weapon_", ""), 0, 0])
	if lp_start > 0 and p != null and is_instance_valid(p):
		p.set("max_health", lp_start)
		p.set("health", lp_start)
		if host.has_method("ui_manager") == false:
			pass
		var uim = host.get("ui_manager")
		if uim != null and uim.has_method("update_health"):
			uim.call("update_health", lp_start, lp_start, 1)
		print("[CHAL][REGEL] id=%s lp_start=%d heilung=%d" % [id, lp_start, 0 if hat("heilung") else 1])
	if hat("schild_pickup"):
		print("[CHAL][REGEL] id=%s schild_pickups=0" % id)


func anzeige_wert() -> int:
	# Was im HUD/Ergebnis als Fortschritt steht: bei RUNDEN-Zielen die
	# aktuelle Runde, bei Bossen/Kisten/Kills/Muenzen der Zaehler.
	match str(def_of(id).get("ziel", "runden")):
		"bosse":
			return boss_gezaehlt
		"kisten":
			return kisten
		"kills":
			return kills
		"muenzen":
			return muenzen
		_:
			return maxi(fortschritt, runde_aktuell)


func ziel_text() -> String:
	match str(def_of(id).get("ziel", "runden")):
		"bosse":
			return "BOSSE %d/%d" % [boss_gezaehlt, ziel_wert]
		"zeit":
			return "RUNDE %d/%d · %s" % [anzeige_wert(), runden_max, restzeit_text()]
		"kisten":
			return "KISTEN %d/%d" % [kisten, ziel_wert]
		"kills":
			return "KILLS %d/%d" % [kills, ziel_wert]
		"muenzen":
			return "MUENZEN %d/%d" % [muenzen, ziel_wert]
		_:
			return "RUNDE %d/%d" % [anzeige_wert(), runden_max]


# v1.46 (B1): Zielzahl der gewaehlten Stufe fuer den Fortschrittsbalken.
static func ziel_of(id2: String, stufe2: String) -> int:
	var d: Dictionary = def_of(id2)
	if d.is_empty():
		return 1
	var i: int = stufe_index(stufe2)
	return int((d["ziel_wert"] as Array)[i])


# v1.46 (B2): Pflicht-Trefferzahl von 0 (UNBERUEHRT) pruefen.
func treffer_erlaubt() -> bool:
	return not kein_treffer


# v1.46 (B1): Einheit des Ziels fuer die Karten (Runden/Monster/Muenzen/...).
static func unit_of(id2: String) -> String:
	match str(def_of(id2).get("ziel", "runden")):
		"bosse":
			return "Bosse"
		"kisten":
			return "Kisten"
		"kills":
			return "Monster"
		"muenzen":
			return "Muenzen"
		"zeit":
			return "Wellen"
		_:
			return "Runden"


static func desc_for(id2: String, stufe2: String) -> String:
	# Beschreibung mit den Zahlen der gewaehlten Stufe - sonst stand in der
	# Karte "20 Runden", waehrend LEICHT nur 8 verlangt.
	var d: Dictionary = def_of(id2)
	if d.is_empty():
		return ""
	var i: int = stufe_index(stufe2)
	var r: int = int((d["runden"] as Array)[i])
	var z: int = int((d["ziel_wert"] as Array)[i])
	match id2:
		"revolver":
			return "%d Runden am Stueck nur mit dem Revolver" % r
		"eisern":
			return "Mit 1 Leben %d Runden ueberstehen - keine Heilung" % r
		"boss":
			return "Drei Bosse legen, ohne ein Schild zu benutzen (%d Runden Zeit)" % r
		"schnell":
			var t: float = float((d.get("zeit", [0.0, 0.0, 0.0]) as Array)[i])
			return "Welle %d in unter %d:%02d Minuten erreichen" % [z, int(t) / 60, int(t) % 60]
		"ohne_schild":
			return "%d Runden ohne ein Schild-Pickup ueberstehen" % r
		"flinte":
			return "%d Runden am Stueck nur mit der Schrotflinte" % r
		"unberuehrt":
			return "%d Runden ohne einen einzigen Treffer" % r
		"kopfgeld":
			return "%d Monster ohne Waffen-Pickup erledigen (%d Runden Zeit)" % [z, r]
		"goldrausch":
			return "%d Muenzen sammeln - ohne Heilung (%d Runden Zeit)" % [z, r]
		"ohne_vorrat":
			return "%d Runden ohne Trank und ohne Bombe" % r
		"nahkampf":
			return "%d Runden nur mit der Startpistole, ohne Trank/Bombe" % r
		"sparsam":
			return "%d Runden ohne Trank, Bombe und Schild" % r
	return str(d.get("desc", ""))


func restzeit_text() -> String:
	if zeit_limit <= 0.0:
		return "-"
	var rest: float = zeit_limit - float(Time.get_ticks_msec() - start_ms) / 1000.0
	rest = maxf(0.0, rest)
	return "%d:%02d" % [int(rest) / 60, int(rest) % 60]


func hud_text() -> String:
	var d: Dictionary = def_of(id)
	return "%s · %s · %s" % [str(d["name"]), STUFEN_LABEL.get(stufe, stufe), ziel_text()]


# --- Ereignisse aus dem Run ---

func on_round_started(n: int) -> void:
	if not aktiv:
		return
	runde_aktuell = n
	print("[CHAL][HUD] id=%s runde=%d/%d ziel=%s" % [id, n, runden_max, ziel_text()])
	if str(def_of(id).get("ziel", "")) == "zeit" and zeit_limit > 0.0:
		var verbraucht: float = float(Time.get_ticks_msec() - start_ms) / 1000.0
		print("[CHAL][ZIEL] id=schnell zeit_limit=%.0f verbraucht=%.0f rest=%.0f" % [
			zeit_limit, verbraucht, maxf(0.0, zeit_limit - verbraucht)])
		if verbraucht > zeit_limit:
			_ende(false, "zeit_abgelaufen")


func on_round_cleared(n: int) -> void:
	if not aktiv or beendet:
		return
	fortschritt = maxi(fortschritt, n)
	print("[CHAL][FORTSCHRITT] id=%s runden=%d/%d ziel=%s" % [id, fortschritt, runden_max, ziel_text()])
	match str(def_of(id).get("ziel", "runden")):
		"runden":
			if fortschritt >= ziel_wert:
				_ende(true, "runden_erreicht")
		"zeit":
			if fortschritt >= ziel_wert:
				_ende(true, "welle_im_zeitlimit")
		"bosse":
			if fortschritt >= runden_max and boss_gezaehlt < ziel_wert:
				_ende(false, "runden_aufgebraucht")
		"kisten":
			if fortschritt >= runden_max and kisten < ziel_wert:
				_ende(false, "runden_aufgebraucht")
		"kills":
			if fortschritt >= runden_max and kills < ziel_wert:
				_ende(false, "runden_aufgebraucht")
		"muenzen":
			if fortschritt >= runden_max and muenzen < ziel_wert:
				_ende(false, "runden_aufgebraucht")
	_update_hud()


func on_boss_killed() -> void:
	if not aktiv or beendet:
		return
	boss_gezaehlt += 1
	print("[CHAL][ZIEL] id=boss bosse=%d gezaehlt=%d" % [ziel_wert, boss_gezaehlt])
	if str(def_of(id).get("ziel", "")) == "bosse" and boss_gezaehlt >= ziel_wert:
		_ende(true, "bosse_gelegt")
	_update_hud()


func on_chest_opened() -> void:
	if not aktiv or beendet:
		return
	kisten += 1
	print("[CHAL][ZIEL] id=sammler kisten=%d/%d" % [kisten, ziel_wert])
	if str(def_of(id).get("ziel", "")) == "kisten" and kisten >= ziel_wert:
		_ende(true, "kisten_geoeffnet")
	_update_hud()


func on_shield_picked() -> void:
	if not aktiv or beendet:
		return
	schilde += 1
	if hat("schild_pickup"):
		_ende(false, "schild_benutzt")


# v1.46 (B2): Kills und Muenzen zaehlen (KOPFGELD / GOLDRAUSCH).
func on_kill(coins: int = 0) -> void:
	if not aktiv or beendet:
		return
	kills += 1
	muenzen += maxi(0, coins)
	var z: String = str(def_of(id).get("ziel", ""))
	if z == "kills":
		print("[CHAL][ZIEL] id=kopfgeld kills=%d/%d" % [kills, ziel_wert])
		if kills >= ziel_wert:
			_ende(true, "kills_erreicht")
	elif z == "muenzen":
		print("[CHAL][ZIEL] id=goldrausch muenzen=%d/%d (+%d)" % [muenzen, ziel_wert, coins])
		if muenzen >= ziel_wert:
			_ende(true, "muenzen_erreicht")
	if z == "kills" or z == "muenzen":
		_update_hud()


# v1.46 (B2): Treffer zaehlen (UNBERUEHRT). Ein echter LP-Verlust beendet
# den Lauf sofort - die Aufgabe ist "ohne einen einzigen Treffer".
func on_damage_taken(amount: int) -> void:
	if not aktiv or beendet:
		return
	treffer += 1
	print("[CHAL][ZIEL] id=unberuehrt treffer=%d schaden=%d erlaubt=%s" % [
		treffer, amount, str(treffer_erlaubt())])
	if kein_treffer:
		_ende(false, "getroffen")


func _update_hud() -> void:
	if host == null:
		return
	var uim = host.get("ui_manager")
	if uim != null and uim.has_method("set_challenge_hud"):
		uim.call("set_challenge_hud", hud_text())


func _ende(gewonnen: bool, grund: String) -> void:
	if beendet:
		return
	beendet = true
	aktiv = false
	if host != null:
		host.call("chal_run_finished", gewonnen, gems_reward, fortschritt, runden_max, grund, id, stufe)
