class_name WheelMachine
extends RefCounted

# v1.45 (Z1): Gluecksrad - reine Mathematik, keine UI. Vorbild: slot_machine.gd
# (statische Regeln + simulate()). Ein Spin waehlt GENAU EIN Segment; das
# Ergebnis steht also vor der Drehung fest, die UI zielt nur darauf.
#
# 8 Segmente, Gewichte summieren auf 100. Gold-RTP = 0,92. v1.48: nur Gold/Diamanten.

const BET_MIN := 100
const BET_MAX := 5000
const SEGMENTS := 8

# key, gewicht (Summe 100), gold_mult (x Einsatz), gems, label, farbe
const SLICES := [
	# v1.48 (A2): NUR Gold und Diamanten - keine Skins, keine Huete.
	# Gold-RTP bleibt 0,92 (Summe w*mult/100).
	{ "key": "gold1",  "w": 30.0, "mult": 1.0,  "gems": 0, "label": "GOLD x1",    "farbe": "gold", "art": "gold" },
	{ "key": "niete",  "w": 18.0, "mult": 0.0,  "gems": 0, "label": "NIETE",      "farbe": "grau", "art": "miss" },
	{ "key": "gold2",  "w": 16.0, "mult": 2.0,  "gems": 0, "label": "GOLD x2",    "farbe": "gold", "art": "gold" },
	{ "key": "gem1",   "w": 10.0, "mult": 0.0,  "gems": 1, "label": "DIAMANT 1",  "farbe": "blau", "art": "gems" },
	{ "key": "gold5",  "w": 6.0,  "mult": 5.0,  "gems": 0, "label": "GOLD x5",    "farbe": "gold", "art": "gold" },
	{ "key": "gem2",   "w": 8.0,  "mult": 0.0,  "gems": 2, "label": "DIAMANT 2",  "farbe": "blau", "art": "gems" },
	{ "key": "gem3",   "w": 6.0,  "mult": 0.0,  "gems": 3, "label": "DIAMANT 3",  "farbe": "blau", "art": "gems" },
	{ "key": "gem5",   "w": 6.0,  "mult": 0.0,  "gems": 5, "label": "DIAMANT 5",  "farbe": "blau", "art": "gems" },
]


static func _total_weight() -> float:
	var t: float = 0.0
	for s in SLICES:
		t += float(s["w"])
	return t


static func weight_sum() -> float:
	return _total_weight()


static func slice_angle_deg() -> float:
	return 360.0 / float(SEGMENTS)


static func index_of(key: String) -> int:
	for i in range(SLICES.size()):
		if str(SLICES[i]["key"]) == key:
			return i
	return -1


static func pick_index(rng: RandomNumberGenerator) -> int:
	# Gewichteter Zug: erst das Segment, dann steht das Ergebnis fest.
	var roll: float = rng.randf() * _total_weight()
	var acc: float = 0.0
	for i in range(SLICES.size()):
		acc += float(SLICES[i]["w"])
		if roll <= acc:
			return i
	return SLICES.size() - 1


static func outcome_for(idx: int, bet: int) -> Dictionary:
	# Was der Treffer in Gold/Diamanten bedeutet (ohne Buchung).
	if idx < 0 or idx >= SLICES.size():
		return { "ok": false, "error": "bad_index" }
	var s: Dictionary = SLICES[idx]
	var win: int = int(round(float(s["mult"]) * float(bet)))
	return {
		"ok": true, "index": idx, "key": str(s["key"]), "label": str(s["label"]),
		"win": win, "gems": int(s["gems"]), "error": "",
	}


static func spin(bet: int, gold: int, rng: RandomNumberGenerator) -> Dictionary:
	# Ergebnis-Dictionary: ok, index, key, label, win, gems, gold_after, error
	if bet < BET_MIN or bet > BET_MAX:
		print("[WHEEL][FEHLER] einsatz=%d ausserhalb %d..%d" % [bet, BET_MIN, BET_MAX])
		return { "ok": false, "error": "bad_bet", "gold_after": gold }
	if bet > gold:
		print("[WHEEL][FEHLER] zu_wenig_gold einsatz=%d gold=%d" % [bet, gold])
		return { "ok": false, "error": "no_gold", "gold_after": gold }
	var idx: int = pick_index(rng)
	var out: Dictionary = outcome_for(idx, bet)
	var after: int = gold - bet + int(out["win"])
	out["gold_after"] = after
	print("[WHEEL][SPIN] einsatz=%d gold=%d segment=%d key=%s gewinn=%d gems=%d gold_nachher=%d" % [
		bet, gold, idx, str(out["key"]), int(out["win"]), int(out["gems"]), after])
	return out


static func odds_table() -> Array:
	# Dieselben Gewichte und Auszahlungen wie spin() - keine zweite Zahlenquelle.
	var total: float = _total_weight()
	var out: Array = []
	for i in range(SLICES.size()):
		var s: Dictionary = SLICES[i]
		out.append({
			"index": i, "key": str(s["key"]), "label": str(s["label"]),
			"wert": (float(s["mult"]) if float(s["mult"]) > 0.0 else float(s["gems"])),
			"chance": 100.0 * float(s["w"]) / total,
			"mult": float(s["mult"]), "gems": int(s["gems"]),
		})
	return out


static func rtp_gold() -> float:
	var total: float = _total_weight()
	var rtp: float = 0.0
	for s in SLICES:
		rtp += float(s["w"]) / total * float(s["mult"])
	return rtp


static func simulate(n: int, bet: int) -> Dictionary:
	# Z2: fester Seed -> reproduzierbar. Zaehlt je Segment, Treffer und Gold-RTP.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261105
	var counts: Array = []
	for i in range(SLICES.size()):
		counts.append(0)
	var total_win: int = 0
	var total_bet: int = 0
	for _i in range(n):
		var idx: int = pick_index(rng)
		counts[idx] = int(counts[idx]) + 1
		total_bet += bet
		total_win += int(round(float(SLICES[idx]["mult"]) * float(bet)))
	var rtp: float = 0.0
	if total_bet > 0:
		rtp = float(total_win) / float(total_bet)
	return {
		"n": n, "bet": bet, "counts": counts, "rtp": rtp,
		"won": total_win, "wagered": total_bet,
	}


static func segment_center_deg(idx: int) -> float:
	# Mittelpunkt eines Segments in Grad, 0 = oben (Zeiger), im Uhrzeigersinn.
	return float(idx) * slice_angle_deg() + slice_angle_deg() * 0.5
