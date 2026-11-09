class_name SeasonsModule
extends RefCounted

# Runde 138: Jahreszeiten aus game_manager.gd
var host: Node = null

const SEASONS := [
	{ "id": "spring", "name": "FRUEHLING", "desc": "Dichte Blaetter, Blueten — ruhiger Start",
	  "veg": 1.0, "speed": 1.0, "damage": 1.0, "loot": 1.0, "drift": 0.0, "ground_slow": 1.0,
	  "color": Color(0.55, 0.95, 0.65), "price": 0 },
	{ "id": "summer", "name": "SOMMER", "desc": "Kahle, schuettere Baeume, Hitze — Gegner +10% Tempo",
	  "veg": 0.62, "speed": 1.10, "damage": 1.0, "loot": 1.0, "drift": 0.0, "ground_slow": 0.97,
	  "color": Color(1.0, 0.85, 0.35), "price": 2500 },
	{ "id": "autumn", "name": "HERBST", "desc": "Orange Blaetter, Laubfall — mehr Kisten und Loot",
	  "veg": 1.10, "speed": 1.0, "damage": 1.0, "loot": 1.40, "drift": 0.0, "ground_slow": 1.0,
	  "color": Color(0.95, 0.62, 0.25), "price": 6000 },
	{ "id": "winter", "name": "WINTER", "desc": "Schnee, kahle Zweige, glatter Boden — Gegner -15% Tempo",
	  "veg": 0.75, "speed": 0.85, "damage": 1.0, "loot": 1.0, "drift": 0.17, "ground_slow": 0.92,
	  "color": Color(0.75, 0.88, 1.0), "price": 12000 }
]


func season_ids() -> Array:
	var out: Array = []
	for se in SEASONS:
		out.append(str(se["id"]))
	return out


func season_data(sid: String = "") -> Dictionary:
	var want = sid if sid != "" else host.season_id
	for se in SEASONS:
		if str(se["id"]) == want:
			return se
	return SEASONS[0]


func season_name(sid: String) -> String:
	for se in SEASONS:
		if str(se["id"]) == sid:
			return str(se["name"])
	return sid


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


func season_gate_need(planet: String, sid: String) -> int:
	# Runde 136 (I1): Jahreszeiten kosten Gold, kein XP-Gate mehr.
	return 0


# v1.44 (K1): Preis je Jahreszeit PRO PLANET = Kartenpreis / 3.
# ERDE ist kostenlos (Preis 0) und hat darum feste Einstiegspreise.
const ERDE_SEASON_PRICES := [800, 1200, 1600]      # SOMMER / HERBST / WINTER
const PLANETS := ["earth", "mars", "jungle", "volt"]


func season_price_for(planet: String, sid: String) -> int:
	var d: Dictionary = season_data(sid)
	if str(d["id"]) == "spring":
		return 0
	var card: int = int(host.map_data(planet).get("price", 0))
	if card <= 0:
		var idx: int = 0
		match str(d["id"]):
			"summer":
				idx = 0
			"autumn":
				idx = 1
			"winter":
				idx = 2
			_:
				idx = 0
		return int(ERDE_SEASON_PRICES[clampi(idx, 0, 2)])
	return int(round(float(card) / 3.0))


func price_log() -> void:
	# K1-Beleg: Preis je Jahreszeit fuer alle vier Planeten.
	for planet in PLANETS:
		var card: int = int(host.map_data(planet).get("price", 0))
		for se in SEASONS:
			var sid := str(se["id"])
			var price: int = season_price_for(planet, sid)
			var ratio: float = 0.0 if card <= 0 else float(price) / float(card)
			print("[KARTE][PREIS] planet=%s karte=%d saison=%s preis=%d verhaeltnis=%.2f" % [
				planet, card, sid, price, ratio])


func season_price(sid: String) -> int:
	# Altlast: globaler Preis (nur noch als Rueckfall fuer Anzeigen ohne Planet)
	return int(season_data(sid).get("price", 0))


func season_mode_of(planet: String) -> String:
	# Runde 136 (I2): FEST oder WECHSELND, pro Planet gespeichert
	if not host.season_mode.has(planet):
		host.season_mode[planet] = "fixed"
	return str(host.season_mode[planet])


func season_pool(planet: String) -> Array:
	# Nur freigeschaltete Jahreszeiten dieses Planeten, in SEASONS-Reihenfolge
	var out: Array = []
	if planet == "volt":
		for sid in host.volt_seasons():
			if host.is_season_unlocked(planet, sid):
				out.append(sid)
		return out
	for se in SEASONS:
		var sid := str(se["id"])
		if host.is_season_unlocked(planet, sid):
			out.append(sid)
	return out


func season_progress_text(planet: String) -> String:
	# naechste gesperrte Jahreszeit dieses Planeten
	for se in SEASONS:
		var sid := str(se["id"])
		if host.is_season_unlocked(planet, sid):
			continue
		var need := season_gate_need(planet, sid)
		if need <= 0:
			continue
		return "%s: %d XP in einem Run (Bestwert %d)" % [str(se["name"]), need, host.best_run_xp]
	return ""


func _season_label(sid: String) -> String:
	if sid == "":
		return ""
	if host.active_map == "volt":
		return season_display_name(host.active_map, sid)
	return season_name(sid)


func season_summary() -> String:
	if not host.seasons_enabled():
		return ""
	return season_name(host.season_id)


func buy_season(planet: String, sid: String) -> bool:
	# Runde 136 (I1): Jahreszeit mit Gold freischalten
	var price: int = season_price_for(planet, sid)
	if host.is_season_unlocked(planet, sid):
		print("[SEASON][KAUF] %s auf %s ist schon frei" % [sid, planet])
		return true
	if host.gold < price:
		print("[SEASON][KAUF] FEHLER: zu wenig Gold (%d noetig, %d vorhanden)" % [price, host.gold])
		host.ui_manager.show_banner("ZU WENIG GOLD (%s NÖTIG)" % host._num_dots_local(price), Color(1.0, 0.6, 0.4))
		return false
	var before: int = host.gold
	host.gold -= price
	if not host.season_unlocks.has(planet):
		host.season_unlocks[planet] = ["spring"]
	(host.season_unlocks[planet] as Array).append(sid)
	host._save_profile()
	print("[SEASON][KAUF] planet=%s saison=%s preis=%d gold_vorher=%d nachher=%d gespeichert=true" % [
		planet, sid, price, before, host.gold])
	host.ui_manager.show_banner("%s FREIGESCHALTET (−%s GOLD)" % [season_name(sid), host._num_dots_local(price)], Color(0.6, 1.0, 0.8))
	SoundManager.play("levelup")
	host.ui_manager.refresh_maps_ui()
	return true


func _check_season() -> void:
	# Runde 136 (I2): FEST bleibt, WECHSELND laeuft nur durch die
	# freigeschalteten Jahreszeiten dieses Planeten.
	if not host.seasons_enabled():
		return
	var pool: Array = season_pool(host.active_map)
	if pool.is_empty():
		return
	if season_mode_of(host.active_map) == "fixed":
		var want_fixed: String = host.planet_season(host.active_map)
		if not pool.has(want_fixed):
			want_fixed = str(pool[0])
		if host.season_id != want_fixed:
			host.season_id = want_fixed
			host.map_generator.set_season(host.season_id)
			print("[SEASON][FEST] planet=%s jahreszeit=%s (fest, kein Wechsel)" % [host.active_map, host.season_id])
		host._update_season_hud()
		return
	if pool.size() < 2:
		host._update_season_hud()
		return
	var steps: int = int(host.score / SEASON_STEP)
	var idx: int = ((steps % pool.size()) + pool.size()) % pool.size()
	var base: int = maxi(0, pool.find(host.planet_season(host.active_map)))
	var want: String = str(pool[(base + idx) % pool.size()])
	if want != host.season_id:
		var from: String = host.season_id
		host.season_id = want
		host.map_generator.set_season(host.season_id)
		var sd: Dictionary = season_data(host.season_id)
		host.ui_manager.show_banner(_season_label(host.season_id), sd["color"])
		print("[SEASON][WECHSEL] planet=%s von=%s nach=%s pool=%s" % [host.active_map, from, host.season_id, str(pool)])
	host._update_season_hud()


func _check_season_gates() -> void:
	# Runde 136 (I1): Jahreszeiten werden mit Gold gekauft (buy_season()).
	# Der fruehere XP-Schalter ist damit weg - die Aufrufstelle bleibt stehen.
	return

# Konstanten aus der Fassade (ui_manager.gd)
const SEASON_STEP := 1400.0        # Score pro Jahreszeiten-Wechsel im Run


func migrate_unlocks() -> void:
	# K5: gekaufte Jahreszeiten bleiben; fehlt die Startjahreszeit, wird sie
	# nachgetragen (sie gehoert zum Kartenkauf). Es wird NIE eine weitere
	# Jahreszeit gratis freigeschaltet.
	var alt: int = 0
	var neu: int = 0
	var gratis: int = 0
	for planet in host.season_unlocks.keys():
		var arr: Array = host.season_unlocks[planet]
		alt += arr.size()
		if not arr.has("spring"):
			arr.push_front("spring")
		neu += arr.size()
	print("[PROFILE][MIGR] saisons alt=%d neu=%d gratis=%d" % [alt, neu, gratis])
	for planet in ["earth", "mars", "jungle", "volt"]:
		print("[PROFILE][SEASON] %s frei=%d" % [planet, (host.season_unlocks.get(planet, []) as Array).size()])
