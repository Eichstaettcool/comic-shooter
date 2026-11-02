extends RefCounted
# Runde 92: Einarmiger Bandit - reine Mathematik, keine UI.
# Spec: SPEC_SLOT.md
#
# Drei Walzen, eine Gewinnlinie. Auszahlung ist ein Vielfaches des Einsatzes.
# Es wird NUR Gold ausgezahlt - keine Edelsteine, keine Items.

const BETS := [50, 100, 250]

# Gewichte je Walze (Summe 100). Jede Walze nutzt denselben Streifen.
const SYMBOLS := {
	"cherry": 22.0,
	"bell": 18.0,
	"bar": 12.0,
	"gold1": 9.0,
	"gold2": 5.0,
	"gold3": 1.5,
	"skull": 32.5,
}

# Auszahlung als Vielfaches des Einsatzes.
const PAYTABLE := {
	"gold3": 370.0,
	"gold2": 110.0,
	"gold1": 46.0,
	"bar": 55.0,
	"bell": 37.0,
	"cherry": 18.5,
}

# Zwei gleiche Symbole, von links beginnend.
const PAYTABLE_TWO := {
	"cherry": 5.5,
	"bell": 2.8,
	"bar": 3.7,
	"gold1": 3.7,
}

const SYMBOL_LIST := ["cherry", "bell", "bar", "gold1", "gold2", "gold3", "skull"]


static func _total_weight() -> float:
	var t: float = 0.0
	for k in SYMBOLS.keys():
		t += float(SYMBOLS[k])
	return t


static func _pick(rng: RandomNumberGenerator) -> String:
	var roll: float = rng.randf() * _total_weight()
	var acc: float = 0.0
	for k in SYMBOL_LIST:
		acc += float(SYMBOLS[k])
		if roll <= acc:
			return str(k)
	return "skull"


static func spin_symbols(rng: RandomNumberGenerator) -> Array:
	return [_pick(rng), _pick(rng), _pick(rng)]


static func evaluate(symbols: Array) -> Dictionary:
	# Reihenfolge: erst 3 gleiche, dann 2 gleiche von links.
	if symbols.size() != 3:
		return { "win_mult": 0.0, "combo": "error" }
	var a := str(symbols[0])
	var b := str(symbols[1])
	var c := str(symbols[2])
	if a == b and b == c:
		if PAYTABLE.has(a):
			return { "win_mult": float(PAYTABLE[a]), "combo": "three_" + a }
		return { "win_mult": 0.0, "combo": "three_skull" }
	if a == b and PAYTABLE_TWO.has(a):
		return { "win_mult": float(PAYTABLE_TWO[a]), "combo": "two_" + a }
	return { "win_mult": 0.0, "combo": "none" }


static func spin(bet: int, gold: int, rng: RandomNumberGenerator) -> Dictionary:
	# Ergebnis-Dictionary: ok, symbols, combo, win, gold_after, error
	if not BETS.has(bet):
		print("[SLOT] FEHLER: unbekannter Einsatz %d (erlaubt: %s)" % [bet, str(BETS)])
		return { "ok": false, "error": "bad_bet", "gold_after": gold }
	if gold < bet:
		print("[SLOT] spin bet=%d gold=%d -> ABGELEHNT: zu wenig Gold" % [bet, gold])
		return { "ok": false, "error": "no_gold", "gold_after": gold }
	var sym := spin_symbols(rng)
	var ev: Dictionary = evaluate(sym)
	var win: int = int(round(float(ev["win_mult"]) * float(bet)))
	var after: int = gold - bet + win
	print("[SLOT] spin bet=%d gold=%d -> %s combo=%s win=%d gold_after=%d" % [
		bet, gold, str(sym), str(ev["combo"]), win, after])
	return {
		"ok": true, "symbols": sym, "combo": str(ev["combo"]),
		"win": win, "gold_after": after, "error": "",
	}


static func simulate(spins: int, bet: int) -> Dictionary:
	# RTP- und Trefferquoten-Test. Seed fest, damit der Test reproduzierbar ist.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261101
	var total_bet: int = 0
	var total_win: int = 0
	var hits: int = 0
	var jackpots: int = 0
	var gold: int = 100000000
	# Ohne Log pro Spin - 200k Zeilen wuerden die Simulation unbrauchbar machen.
	for i in range(spins):
		var sym2 := spin_symbols(rng)
		var ev2: Dictionary = evaluate(sym2)
		var win2: int = int(round(float(ev2["win_mult"]) * float(bet)))
		total_bet += bet
		total_win += win2
		if win2 > 0:
			hits += 1
		if str(ev2["combo"]) == "three_gold3":
			jackpots += 1
	var rtp: float = 0.0
	if total_bet > 0:
		rtp = 100.0 * float(total_win) / float(total_bet)
	var hitrate: float = 0.0
	if spins > 0:
		hitrate = 100.0 * float(hits) / float(spins)
	return {
		"spins": spins, "bet": bet, "rtp": rtp, "hitrate": hitrate,
		"jackpots": jackpots, "won": total_win, "wagered": total_bet,
	}
