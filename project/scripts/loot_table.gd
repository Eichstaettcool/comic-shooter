extends RefCounted
# Runde 67: Gewichtete Kisten-Inhalte (nur Kosmetik).
# Bewusst eigenstaendig und ohne UI, damit es headless testbar ist.

const CHESTS := {
	"standard": {
		"cost": 12,
		"weights": { "common": 44.0, "rare": 15.5, "epic": 5.0, "legendary": 0.5 },
		"kinds": ["color", "hat"],
		"min_rarity": "",
		"miss_chance": 14.0,      # Niete: nichts
		"gold_chance": 13.0,      # Trostpreis Gold
		"gem_chance": 12.0,       # Trostpreis Edelsteine
		"gold_min": 40, "gold_max": 140,
		"gem_tiers": [5, 10, 15, 25]
	},
	"silver": {
		"label": "SILBER",
		"cost": 18,
		"weights": { "common": 20.0, "rare": 30.0, "epic": 13.0, "legendary": 2.0 },
		"kinds": ["color", "hat"],
		"min_rarity": "",
		"miss_chance": 11.0,
		"gold_chance": 13.0,
		"gem_chance": 13.0,
		"gold_min": 80, "gold_max": 220,
		"gem_tiers": [5, 10, 15, 25, 40]
	},
	"premium": {
		"cost": 28,
		"weights": { "common": 0.0, "rare": 40.0, "epic": 19.5, "legendary": 5.5 },
		"kinds": ["color", "hat", "skin"],
		"min_rarity": "",
		"miss_chance": 11.0,
		"gold_chance": 13.0,
		"gem_chance": 15.0,
		"gold_min": 120, "gold_max": 320,
		"gem_tiers": [10, 15, 25, 40]
	}
}

const RARITY_ORDER := ["common", "rare", "epic", "legendary"]

# Rueckerstattung fuer Duplikate (in Edelsteinen)
const REFUND := { "common": 3, "rare": 6, "epic": 12, "legendary": 25 }


static func chest_cost(chest_id: String) -> int:
	if not CHESTS.has(chest_id):
		return 0
	return int(CHESTS[chest_id]["cost"])


static func rarity_rank(r: String) -> int:
	var i := RARITY_ORDER.find(r)
	return i if i >= 0 else 0


static func refund_for(rarity: String) -> int:
	return int(REFUND.get(rarity, 3))


static func _pick_rarity(weights: Dictionary, rng: RandomNumberGenerator, min_rarity: String,
		available: Dictionary = {}) -> String:
	var keys: Array = []
	var vals: Array = []
	for k in RARITY_ORDER:
		if not weights.has(k):
			continue
		if available.size() > 0 and not available.has(k):
			continue          # Stufe ohne Items nicht ziehen (sonst faellt sie still nach unten)
		if float(weights[k]) <= 0.0:
			continue
		keys.append(k)
		vals.append(float(weights[k]))
	if keys.is_empty():
		return "common"
	var idx: int = rng.rand_weighted(PackedFloat32Array(vals))
	var r: String = str(keys[idx])
	if min_rarity != "" and rarity_rank(r) < rarity_rank(min_rarity):
		r = min_rarity
	return r


static func roll(chest_id: String, catalog: Array, owned: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	# catalog: [ {kind, index, rarity}, ... ]
	# owned:   { "hat": [0,3], "skin": [1], "color": [0,1] }
	if not CHESTS.has(chest_id):
		return { "ok": false, "error": "unbekannte Kiste: %s" % chest_id }
	var cfg: Dictionary = CHESTS[chest_id]
	var kinds: Array = cfg["kinds"]

	# Runde 68: Niete (nichts) oder Trostpreis (Gold) - Spannung wie in einer
	# echten Lootbox: nicht jeder Griff ist ein Gewinn.
	var roll100: float = rng.randf() * 100.0
	var miss: float = float(cfg.get("miss_chance", 0.0))
	var goldc: float = float(cfg.get("gold_chance", 0.0))
	if roll100 < miss:
		return { "ok": true, "kind": "none", "index": -1, "rarity": "miss",
			"duplicate": false, "refund": 0, "name": "NIETE" }
	if roll100 < miss + goldc:
		var amount: int = rng.randi_range(int(cfg.get("gold_min", 40)), int(cfg.get("gold_max", 140)))
		return { "ok": true, "kind": "gold", "index": -1, "rarity": "gold",
			"duplicate": false, "refund": 0, "gold": amount, "name": "GOLD +%d" % amount }
	if roll100 < miss + goldc + float(cfg.get("gem_chance", 0.0)):
		var tiers: Array = cfg.get("gem_tiers", [5, 10])
		var g: int = int(tiers[rng.randi_range(0, tiers.size() - 1)])
		return { "ok": true, "kind": "gems", "index": -1, "rarity": "gems",
			"duplicate": false, "refund": 0, "gems": g, "name": "+%d EDELSTEINE" % g }
	var available: Dictionary = {}
	for e in catalog:
		if kinds.has(str(e["kind"])):
			available[str(e["rarity"])] = true
	var rarity: String = _pick_rarity(cfg["weights"], rng, str(cfg["min_rarity"]), available)

	# Erst alle Items dieser Seltenheit sammeln, dann eines ziehen
	var candidates: Array = []
	for e in catalog:
		if not kinds.has(str(e["kind"])):
			continue
		if str(e["rarity"]) != rarity:
			continue
		candidates.append(e)

	# Keine Treffer in dieser Stufe -> naechstniedrigere nehmen
	if candidates.is_empty():
		for e in catalog:
			if kinds.has(str(e["kind"])) and rarity_rank(str(e["rarity"])) <= rarity_rank(rarity):
				candidates.append(e)
	if candidates.is_empty():
		return { "ok": false, "error": "kein Inhalt fuer %s" % chest_id }

	var pick: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var kind := str(pick["kind"])
	var idx := int(pick["index"])
	var rar := str(pick["rarity"])
	var have: Array = owned.get(kind, [])
	var dup: bool = have.has(idx)
	return {
		"ok": true, "kind": kind, "index": idx, "rarity": rar,
		"duplicate": dup, "refund": refund_for(rar) if dup else 0,
		"name": str(pick.get("name", "%s %d" % [kind, idx]))
	}


# Nur fuer Tests: Verteilung ohne Duplikat-Logik
static func simulate(count: int, chest_id: String, catalog: Array,
		rng: RandomNumberGenerator) -> Dictionary:
	var hist: Dictionary = {}
	for i in range(count):
		var r := roll(chest_id, catalog, {}, rng)
		if bool(r.get("ok", false)):
			var k := str(r["rarity"])
			hist[k] = int(hist.get(k, 0)) + 1
	return hist
