class_name ShopLogic
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null

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
const MODUS_KEYS := { 0: "endlos", 1: "wellen", 2: "runden" }
const SHOP_PRICE_MULT := { "earth": 1.45, "mars": 1.9, "jungle": 2.25 }
const SHOP_RARE_ITEMS := [
	{ "id": "heal_plus", "label": "GROSSE HEILUNG", "price": 45, "rare": true, "desc": "Volle Heilung + 3 Herzen" },
	{ "id": "shield_plus", "label": "PANZER +3", "price": 40, "rare": true, "desc": "3 Schildtreffer extra" },
	{ "id": "maxhp2", "label": "MAX-HERZ +2", "price": 55, "rare": true, "desc": "2 Herzen mehr Maximum" },
	{ "id": "bomb_stash", "label": "3 BOMBEN", "price": 35, "rare": true, "desc": "Drei Bomben fuer sofort" },
	{ "id": "damage_plus", "label": "SCHADEN +35%", "price": 50, "rare": true, "desc": "Deutlich mehr Schaden" },
	{ "id": "speed_plus", "label": "TEMPO +20%", "price": 42, "rare": true, "desc": "Du bewegst dich schneller" },
	{ "id": "rapid_plus", "label": "SCHNELLFEUER 12s", "price": 38, "rare": true, "desc": "Dauerfeuer fuer 12 Sekunden" },
	{ "id": "gold_plus", "label": "GOLD +60", "price": 45, "rare": true, "desc": "Sofort 60 Muenzen extra", "modi": ["wellen"] },
	{ "id": "freeze_plus", "label": "FROST 10s", "price": 40, "rare": true, "desc": "Gegner stehen 10s still" },
	{ "id": "combo_plus", "label": "COMBO +1", "price": 44, "rare": true, "desc": "Punkte-Multiplikator bleibt laenger", "modi": ["endlos"] },
]


func _modus_passt(it: Dictionary, modus_key: String) -> bool:
	# Leere Liste = alle Modi. Sonst muss der aktuelle Modus enthalten sein.
	var modi: Array = it.get("modi", [])
	if modi.is_empty():
		return true
	return modi.has(modus_key)


func shop_price(base: int) -> int:
	# Runde 34: Preise steigen auch mit der Wellennummer
	# Runde 49c: 0.05 -> 0.085. Die Preise muessen schneller
	# wachsen als der Ertrag, sonst kann man irgendwann alles kaufen.
	var wave_mult: float = 1.0 + 0.085 * float(maxi(0, host.wave - 1))
	return maxi(1, int(round(float(base) * shop_price_mult() * wave_mult)))


func shop_price_mult() -> float:
	return float(SHOP_PRICE_MULT.get(host.active_map, 1.0))


func chest_price(tier_id: String) -> int:
	# Runde 48: Preis einer Kiste (fuer den Bestaetigungs-Button)
	for tier in CHESTS:
		if str(tier["id"]) == tier_id:
			return int(tier["price"])
	return 999999


func _build_shop_offers() -> Array:
	# Runde 34: pro Phase 5 normale Angebote (Karten-Bias pro Map) + 1 Rare-Item
	var weighted: Array = []
	# v1.48 (C4): modeigene Angebote filtern - Wellen-Only erscheint nur im Wellen-Modus.
	var modus_key: String = str(MODUS_KEYS.get(int(host.game_mode), "endlos"))
	var gefiltert: int = 0
	for it in SHOP_ITEMS:
		if not _modus_passt(it, modus_key):
			gefiltert += 1
			continue
		var iid: String = str(it["id"])
		var w: float = 1.0
		match host.active_map:
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
	# Rare-Item dazu (gleicher Filter)
	var rare_ok: Array = []
	for r0 in SHOP_RARE_ITEMS:
		if _modus_passt(r0, modus_key):
			rare_ok.append(r0)
	if rare_ok.size() > 0:
		offers.append(rare_ok[randi() % rare_ok.size()].duplicate(true))
	var wellen_only: int = 0
	for o in offers:
		for k in (o.get("modi", []) as Array):
			if str(k) == "wellen":
				wellen_only += 1
				break
	print("[SHOP][FILTER] modus=%d key=%s angeboten=%d wellen_only=%d gefiltert=%d verletzungen=%d" % [
		int(host.game_mode), modus_key, offers.size(), wellen_only, gefiltert,
		(0 if (modus_key != "wellen" and wellen_only == 0) or modus_key == "wellen" else 1)])
	var ids: Array = []
	for o in offers:
		ids.append(str(o.get("id", "?")))
	host._sdiag("OFFERS", "%d Angebote erzeugt (Map=%s): %s" % [offers.size(), host.active_map, str(ids)])
	return offers
