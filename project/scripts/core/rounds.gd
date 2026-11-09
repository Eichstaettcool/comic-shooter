class_name Rounds

extends RefCounted

# v1.40 — Runden-Katalog fuer den RUNDEN-Modus (game_mode == 2).
# Aufbau wie in Bloons TD: jede Runde besteht aus GRUPPEN (Typ + Anzahl),
# die nacheinander mit Abstand einlaufen - nicht "alles in einem Frame".
# Die HP-Summe ist ueber alle 30 Runden STRENG monoton (W5.1).

# MonsterType-Indizes (Spiegel von monster_stats.gd, Reihenfolge bindend):
# 0 GREEN 1 RED 2 BLUE 3 PURPLE 4 YELLOW 5 PINK 6 ORANGE 8 BURROWER 9 GOLEM 10 PYRO

const MAX_MONSTER := 52          # W5.2: harte Obergrenze je Runde (Performance)
# v1.42 (P6.3): LEICHT hat eine eigene, niedrigere Obergrenze je Runde
const MAX_MONSTER_LEICHT := 34
const ROUND_COUNT := 30

const DIFFICULTY_STUFEN := ["leicht", "normal", "schwer", "hart"]

# v1.56 (Spec A2): Adapter auf Balance (core/balance.gd) - KEINE eigene
# Balancetabelle mehr. Schluessel bleiben, damit HUD/Shop/Netzwerk laufen:
#   herzen = Startherzen, hp = HP-Faktor, anzahl = Gegnerzahl-Faktor,
#   muenz = Muenzen-Faktor, preis = Preisfaktor.
static var DIFFICULTY: Dictionary = _build_difficulty()


static func _build_difficulty() -> Dictionary:
	var out: Dictionary = {}
	# RUNDEN kennt nur drei Stufen: leicht | normal | hart
	var map: Dictionary = { "leicht": "leicht", "normal": "normal", "schwer": "schwer", "hart": "schwer" }
	for k in DIFFICULTY_STUFEN:
		var bst: String = str(map[k])
		var d: Dictionary = Balance.data(bst)
		out[k] = {
			"name": str(k).to_upper(),
			"herzen": int(d["hearts"]),
			"hp": float(d["hp"]),
			"preis": float(d["preis"]),
			"muenz": float(d["coins"]),
			"anzahl": float(d["runden_anzahl"]),
		}
	return out

const THEMES := {
	7: { "name": "PANZER", "desc": "Schwere Gegner, wenige, viel Leben", "farbe": Color(1.00, 0.55, 0.24) },
	14: { "name": "SPRINT", "desc": "Schnelle Gegner - sie rennen dich um", "farbe": Color(0.35, 0.78, 1.00) },
	21: { "name": "SCHWARM", "desc": "Viele schwache Gegner auf einmal", "farbe": Color(0.47, 0.94, 0.47) },
	28: { "name": "ELITE", "desc": "Nur die haertesten Typen", "farbe": Color(0.86, 0.35, 0.86) },
}

const ROUNDS := [
	{ "n": 1, "hp_mult": 1.00, "spd_mult": 1.00, "groups": [{ "type": 0, "count": 6 }], "theme":"" },
	{ "n": 2, "hp_mult": 1.07, "spd_mult": 1.01, "groups": [{ "type": 0, "count": 7 }], "theme":"" },
	{ "n": 3, "hp_mult": 1.14, "spd_mult": 1.02, "groups": [{ "type": 0, "count": 8 }], "theme":"" },
	{ "n": 4, "hp_mult": 1.21, "spd_mult": 1.03, "groups": [{ "type": 0, "count": 11 }, { "type": 1, "count": 3 }], "theme":"" },
	{ "n": 5, "hp_mult": 1.32, "spd_mult": 1.03, "groups": [{ "type": 0, "count": 12 }, { "type": 1, "count": 4 }], "theme":"" },
	{ "n": 6, "hp_mult": 1.35, "spd_mult": 1.04, "groups": [{ "type": 0, "count": 14 }, { "type": 1, "count": 5 }], "theme":"" },
	{ "n": 7, "hp_mult": 1.79, "spd_mult": 1.05, "groups": [{ "type": 9, "count": 3 }, { "type": 6, "count": 1 }], "theme": "PANZER" },
	{ "n": 8, "hp_mult": 1.49, "spd_mult": 1.06, "groups": [{ "type": 1, "count": 13 }, { "type": 2, "count": 12 }, { "type": 0, "count": 3 }], "theme":"" },
	{ "n": 9, "hp_mult": 1.56, "spd_mult": 1.07, "groups": [{ "type": 1, "count": 14 }, { "type": 2, "count": 13 }, { "type": 0, "count": 3 }], "theme":"" },
	{ "n": 10, "hp_mult": 1.63, "spd_mult": 1.08, "groups": [{ "type": 5, "count": 10 }, { "type": 4, "count": 9 }, { "type": 1, "count": 5 }, { "type": 2, "count": 4 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 11, "hp_mult": 1.70, "spd_mult": 1.09, "groups": [{ "type": 5, "count": 11 }, { "type": 4, "count": 10 }, { "type": 2, "count": 5 }, { "type": 1, "count": 5 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 12, "hp_mult": 1.77, "spd_mult": 1.10, "groups": [{ "type": 5, "count": 12 }, { "type": 4, "count": 11 }, { "type": 2, "count": 5 }, { "type": 1, "count": 5 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 13, "hp_mult": 1.84, "spd_mult": 1.10, "groups": [{ "type": 5, "count": 8 }, { "type": 4, "count": 8 }, { "type": 3, "count": 7 }, { "type": 2, "count": 4 }, { "type": 1, "count": 4 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 14, "hp_mult": 1.76, "spd_mult": 1.18, "groups": [{ "type": 5, "count": 22 }, { "type": 4, "count": 15 }, { "type": 1, "count": 8 }], "theme": "SPRINT" },
	{ "n": 15, "hp_mult": 1.98, "spd_mult": 1.12, "groups": [{ "type": 5, "count": 10 }, { "type": 3, "count": 9 }, { "type": 4, "count": 9 }, { "type": 1, "count": 5 }, { "type": 2, "count": 4 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 16, "hp_mult": 2.09, "spd_mult": 1.13, "groups": [{ "type": 3, "count": 7 }, { "type": 5, "count": 7 }, { "type": 4, "count": 7 }, { "type": 6, "count": 4 }, { "type": 2, "count": 3 }, { "type": 1, "count": 3 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 17, "hp_mult": 2.12, "spd_mult": 1.14, "groups": [{ "type": 5, "count": 8 }, { "type": 4, "count": 8 }, { "type": 3, "count": 7 }, { "type": 6, "count": 5 }, { "type": 2, "count": 4 }, { "type": 1, "count": 4 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 18, "hp_mult": 2.21, "spd_mult": 1.15, "groups": [{ "type": 5, "count": 9 }, { "type": 3, "count": 8 }, { "type": 4, "count": 8 }, { "type": 6, "count": 5 }, { "type": 2, "count": 4 }, { "type": 1, "count": 4 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 19, "hp_mult": 2.26, "spd_mult": 1.16, "groups": [{ "type": 8, "count": 11 }, { "type": 3, "count": 5 }, { "type": 5, "count": 5 }, { "type": 4, "count": 5 }, { "type": 9, "count": 3 }, { "type": 6, "count": 3 }, { "type": 2, "count": 2 }, { "type": 1, "count": 2 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 20, "hp_mult": 2.37, "spd_mult": 1.17, "groups": [{ "type": 8, "count": 12 }, { "type": 5, "count": 6 }, { "type": 3, "count": 5 }, { "type": 4, "count": 5 }, { "type": 9, "count": 3 }, { "type": 6, "count": 3 }, { "type": 2, "count": 3 }, { "type": 1, "count": 3 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 21, "hp_mult": 4.02, "spd_mult": 1.35, "groups": [{ "type": 2, "count": 20 }, { "type": 1, "count": 19 }, { "type": 0, "count": 13 }], "theme": "SCHWARM" },
	{ "n": 22, "hp_mult": 2.51, "spd_mult": 1.18, "groups": [{ "type": 10, "count": 13 }, { "type": 8, "count": 11 }, { "type": 3, "count": 5 }, { "type": 5, "count": 5 }, { "type": 4, "count": 5 }, { "type": 9, "count": 3 }, { "type": 6, "count": 3 }, { "type": 1, "count": 3 }, { "type": 2, "count": 2 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 23, "hp_mult": 2.84, "spd_mult": 1.19, "groups": [{ "type": 10, "count": 11 }, { "type": 8, "count": 11 }, { "type": 5, "count": 6 }, { "type": 4, "count": 6 }, { "type": 3, "count": 5 }, { "type": 9, "count": 3 }, { "type": 6, "count": 3 }, { "type": 2, "count": 3 }, { "type": 1, "count": 3 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 24, "hp_mult": 3.03, "spd_mult": 1.20, "groups": [{ "type": 10, "count": 9 }, { "type": 8, "count": 9 }, { "type": 5, "count": 7 }, { "type": 3, "count": 6 }, { "type": 4, "count": 6 }, { "type": 9, "count": 4 }, { "type": 6, "count": 4 }, { "type": 2, "count": 3 }, { "type": 1, "count": 3 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 25, "hp_mult": 3.44, "spd_mult": 1.21, "groups": [{ "type": 10, "count": 8 }, { "type": 8, "count": 8 }, { "type": 3, "count": 7 }, { "type": 5, "count": 7 }, { "type": 4, "count": 7 }, { "type": 9, "count": 4 }, { "type": 6, "count": 4 }, { "type": 2, "count": 3 }, { "type": 1, "count": 3 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 26, "hp_mult": 3.87, "spd_mult": 1.22, "groups": [{ "type": 8, "count": 7 }, { "type": 3, "count": 7 }, { "type": 5, "count": 7 }, { "type": 4, "count": 7 }, { "type": 10, "count": 6 }, { "type": 6, "count": 5 }, { "type": 9, "count": 4 }, { "type": 2, "count": 4 }, { "type": 1, "count": 4 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 27, "hp_mult": 4.24, "spd_mult": 1.23, "groups": [{ "type": 3, "count": 7 }, { "type": 5, "count": 7 }, { "type": 4, "count": 7 }, { "type": 10, "count": 6 }, { "type": 8, "count": 6 }, { "type": 9, "count": 5 }, { "type": 6, "count": 5 }, { "type": 2, "count": 4 }, { "type": 1, "count": 4 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 28, "hp_mult": 4.54, "spd_mult": 1.23, "groups": [{ "type": 10, "count": 35 }, { "type": 6, "count": 10 }, { "type": 3, "count": 7 }], "theme": "ELITE" },
	{ "n": 29, "hp_mult": 5.20, "spd_mult": 1.24, "groups": [{ "type": 8, "count": 6 }, { "type": 9, "count": 6 }, { "type": 6, "count": 6 }, { "type": 3, "count": 6 }, { "type": 5, "count": 6 }, { "type": 4, "count": 6 }, { "type": 10, "count": 5 }, { "type": 2, "count": 5 }, { "type": 1, "count": 5 }, { "type": 0, "count": 1 }], "theme":"" },
	{ "n": 30, "hp_mult": 5.43, "spd_mult": 1.25, "groups": [{ "type": 9, "count": 6 }, { "type": 6, "count": 6 }, { "type": 3, "count": 6 }, { "type": 5, "count": 6 }, { "type": 4, "count": 6 }, { "type": 1, "count": 6 }, { "type": 10, "count": 5 }, { "type": 8, "count": 5 }, { "type": 2, "count": 5 }, { "type": 0, "count": 1 }], "theme":"" },
]


static func def_for(r: int) -> Dictionary:
	# Runden jenseits von 30 nutzen die letzte Zeile weiter (kein Crash).
	var i: int = clampi(r, 1, ROUND_COUNT) - 1
	return ROUNDS[i]


static func hp_mult(r: int, diff: String = "normal") -> float:
	# v1.56 (Spec A2/K5): Runden ziehen ihre HP-Kurve aus Balance.
	# weiche Kurve 1 + wachstum*(r-1), hart gedeckelt - kein Exponentialwachstum.
	return Balance.hp_mult(r, _balance_stufe(diff))


static func _balance_stufe(diff: String) -> String:
	# RUNDEN-Stufen auf die Balance-Stufen abbilden (hart -> schwer)
	match str(diff):
		"leicht": return "leicht"
		"schwer": return "schwer"
		"hart": return "schwer"
		"hardcore": return "hardcore"
	return "normal"


static func spd_mult(r: int) -> float:
	# v1.51: Deckel gegen "irgendwann bin ich zu langsam". Der Spieler laeuft
	# 160 px/s, schnelle Gegner (RED) 125 -> bei 1,18 sind sie 148 (LEICHT: 133).
	return minf(float(def_for(r)["spd_mult"]), 1.18)


static func theme_of(r: int) -> Dictionary:
	return THEMES.get(clampi(r, 1, ROUND_COUNT), {})


static func support_plan(r: int) -> Dictionary:
	# v1.41 (M4): ab R10 Sporenbrut (max 20 % der Rundenzahl), ab R13
	# Schildtraeger (2), ab R16 Herold (max 2). Die Monster werden aus der
	# groessten Gruppe GENOMMEN - die Rundenzahl bleibt dadurch konstant.
	var out: Dictionary = {}
	var gesamt: int = base_count(r)
	if r >= 10:
		out[31] = mini(4, int(floor(float(gesamt) * 0.20)))
	if r >= 13:
		out[32] = 2
	if r >= 16:
		out[33] = 2
	return out


static func groups_for(r: int) -> Array:
	var base: Array = (def_for(r)["groups"] as Array).duplicate(true)
	var plan: Dictionary = support_plan(r)
	for t in [31, 32, 33]:
		var n: int = int(plan.get(t, 0))
		if n <= 0:
			continue
		var idx: int = 0
		for i in range(base.size()):
			if int(base[i]["count"]) > int(base[idx]["count"]):
				idx = i
		if int(base[idx]["count"]) - n < 1:
			continue
		base[idx]["count"] = int(base[idx]["count"]) - n
		base.append({ "type": t, "count": n })
	return base


static func base_count(r: int) -> int:
	var n: int = 0
	for g in (def_for(r)["groups"] as Array):
		n += int(g["count"])
	return n


static func monster_count(r: int) -> int:
	# v1.42 (P6): Basis-Anzahl ohne Schwierigkeitsfaktor (HP-Kurve, Belege).
	var n: int = 0
	for g in (def_for(r)["groups"] as Array):
		n += int(g["count"])
	return n


static func count_factor(diff: String = "normal") -> float:
	return float(DIFFICULTY.get(diff, DIFFICULTY["normal"]).get("anzahl", 1.0))


static func monster_cap(diff: String = "normal") -> int:
	return MAX_MONSTER_LEICHT if count_factor(diff) < 1.0 else MAX_MONSTER


static func spawn_groups_for(r: int, diff: String = "normal") -> Array:
	# v1.42 (P6.2): Spawn-Liste MIT Schwierigkeitsfaktor. Abgerundet, mindestens
	# 1 Monster je Gruppe, Bosse bleiben unberuehrt (die kommen aus boss_counts).
	var base: Array = groups_for(r)
	var f: float = count_factor(diff)
	if is_equal_approx(f, 1.0):
		return base
	var out: Array = []
	for g in base:
		var c: int = maxi(1, int(floor(float(int(g["count"])) * f)))
		out.append({ "type": int(g["type"]), "count": c })
	# P6.3: Obergrenze je Runde - die groessten Gruppen zuerst kuerzen
	var cap: int = monster_cap(diff)
	var total: int = 0
	for g2 in out:
		total += int(g2["count"])
	var over: int = total - cap
	while over > 0:
		var bi: int = -1
		var biggest: int = 1
		for i in range(out.size()):
			if int(out[i]["count"]) > biggest:
				biggest = int(out[i]["count"])
				bi = i
		if bi < 0:
			break
		out[bi]["count"] = int(out[bi]["count"]) - 1
		over -= 1
	return out


static func monster_count_for(r: int, diff: String = "normal") -> int:
	var n: int = 0
	for g in spawn_groups_for(r, diff):
		n += int(g["count"])
	return n


static func hp_total(r: int, diff: String = "normal") -> float:
	# Erwartete Gesamt-HP der Runde (fuer die Kurven-Messung W5.1)
	var sum: float = 0.0
	for g in groups_for(r):
		sum += float(int(g["count"])) * float(hp_of(int(g["type"]))) * hp_mult(r, diff)
	return sum


static func hp_of(mtype: int) -> int:
	# Basis-HP aus monster_stats.gd (Spiegel, damit die Tabelle ohne Szene messbar ist)
	match mtype:
		0: return 3      # GREEN
		1: return 2      # RED
		2: return 4      # BLUE
		3: return 6      # PURPLE
		4: return 3      # YELLOW
		5: return 4      # PINK
		6: return 12     # ORANGE
		8: return 5      # BURROWER
		9: return 16     # GOLEM
		10: return 5     # PYRO
		31: return 6     # SPORENBRUT
		32: return 14    # SCHILDTRÄGER
		33: return 9     # HEROLD
		34: return 3     # SPORE
	return 3


static func type_name(mtype: int) -> String:
	# v1.56b: auch die Welt-Typen (Mars/Jungle/Elektro) benennen - vorher stand
	# im Log "?" und die Wellen-Vorschau war fuer diese Karten leer.
	if TYPE_NAMES.has(mtype):
		return str(TYPE_NAMES[mtype])
	return "?"


const TYPE_NAMES := {
	0: "GREEN", 1: "RED", 2: "BLUE", 3: "PURPLE", 4: "YELLOW", 5: "PINK", 6: "ORANGE",
	7: "BOSS", 8: "BURROWER", 9: "GOLEM", 10: "PYRO",
	11: "MARS_ALIEN", 12: "MARS_ROVER", 13: "ROBO_APE", 14: "BIG_FLOWER",
	15: "MARS_DRONE", 16: "MARS_GUARD", 17: "ROBO_TIGER", 18: "VINE_TRAP",
	19: "BOSS_MARS", 20: "BOSS_JUNGLE", 21: "BOSS_EARTH",
	22: "MINI_EARTH", 23: "MINI_MARS", 24: "MINI_JUNGLE",
	25: "VOLT_DRONE", 26: "VOLT_TROOPER", 27: "VOLT_SPIDER", 28: "BOSS_VOLT",
	29: "VOLT_SPOOLER", 30: "MINI_VOLT",
	31: "SPORENBRUT", 32: "SCHILDTRAEGER", 33: "HEROLD", 34: "SPORE",
}


static func preview(r: int, diff: String = "normal") -> String:
	# "8x GREEN, 4x BLUE" - fuer die Wellen-Vorschau (W6.1)
	# v1.42 (P6.7): zeigt die Anzahl der GEWAEHLTEN Schwierigkeit
	var parts: Array = []
	for g in spawn_groups_for(r, diff):
		parts.append("%dx %s" % [int(g["count"]), type_name(int(g["type"]))])
	return ", ".join(parts)


static func group_gap(r: int) -> float:
	# Abstand zwischen den Monstern einer Gruppe: frueh locker, spaet dicht
	# v1.56: frueh deutlich langsamer (1,10 s statt 0,70 s) - in Runde 1-3
	# standen sonst 6-8 Gegner gleichzeitig am Spieler (Messung: Tod in R2).
	return clampf(1.10 - 0.022 * float(r), 0.30, 1.10)


static func group_delay(r: int, i: int) -> float:
	# Versatz zwischen Gruppen - Gruppen laufen nacheinander ein
	return 0.0 if i <= 0 else 1.4 + 0.25 * float(i)


static func round_bonus(r: int, diff: String = "normal") -> int:
	# W4.2: Rundenbonus waechst mit der Runde (R10 >= 3x R1)
	var d: Dictionary = DIFFICULTY.get(diff, DIFFICULTY["normal"])
	# v1.51: mehr Muenzen, damit der Shop zwischen den Runden nutzbar ist
	var base: float = 16.0 + 6.0 * float(r)
	return int(round(base * float(d["muenz"])))


static func coins_per_kill(mtype: int, r: int, diff: String = "normal") -> int:
	var d: Dictionary = DIFFICULTY.get(diff, DIFFICULTY["normal"])
	# v1.51: Basis und Wachstum angehoben (rund 50-70 % mehr Muenzen)
	var basis: int = 2 + int(round(float(hp_of(mtype)) * 0.8))
	var scale: float = 1.0 + 0.08 * float(r)
	return maxi(1, int(round(float(basis) * scale * float(d["muenz"]))))


static func ability_of(mtype: int) -> String:
	# W5.3: jede Monsterart bringt eine eigene Faehigkeit mit (Quelle: monster_stats.gd)
	match mtype:
		0: return "Standardlaeufer, keine Panzerung"
		1: return "schnell (1,25x), wenig HP"
		2: return "Panzerung 15 % - Schild schwächt Treffer"
		3: return "Panzerung 30 %, teilt sich beim Tod"
		4: return "Fernkampf - schiesst aus der Distanz"
		5: return "heilt sich langsam selbst"
		6: return "Panzerung 45 %, langsam, viel HP"
		8: return "graebt sich ein und taucht hinter dem Spieler auf"
		9: return "Panzerung 50 %, HP-Brocken, teilt Schaden"
		10: return "Feuersturm - Flaechenschaden mit Brandmal"
		31: return "teilt sich beim Tod in 2 Sporen (40 % HP, 8 s)"
		32: return "blockt 70 % aus dem Frontwinkel (+-70 Grad)"
		33: return "kein Schaden, bufft Monster im Umkreis 180 px mit +25 % Tempo"
		34: return "Teilungs-Kind der Sporenbrut, zerfaellt nach 8 s"
	return "unbekannt"


static func points_of(mtype: int) -> int:
	# Punkte je Monsterart (Spiegel von monster_stats.gd)
	match mtype:
		0: return 10     # GREEN
		1: return 20     # RED
		2: return 30     # BLUE
		3: return 50     # PURPLE
		4: return 15     # YELLOW
		5: return 12     # PINK
		6: return 60     # ORANGE
		8: return 45     # BURROWER
		9: return 70     # GOLEM
		10: return 55    # PYRO
		31: return 40    # SPORENBRUT
		32: return 75    # SCHILDTRÄGER
		33: return 95    # HEROLD
		34: return 12    # SPORE
	return 10


static func coins_per_points(points: int, r: int, diff: String = "normal") -> int:
	# Muenzen pro Kill: Punkte des Monsters * Rundenfaktor * Schwierigkeit
	var d: Dictionary = DIFFICULTY.get(diff, DIFFICULTY["normal"])
	var basis: float = maxf(1.0, float(points) * 0.09)
	var scale: float = 1.0 + 0.05 * float(r)
	return maxi(1, int(round(basis * scale * float(d["muenz"]))))



# ================================================================
# v1.41 (B): Boss-Beimischung
# ================================================================
# Feste Tabelle (B1) - ersetzt die Regel "jede 5. Runde Mini, jede 10. Biom":
#   1-7    keine Bosse
#   8-14   jede 2. Runde 1 Mini-Boss
#   15-24  jede Runde 1 Mini-Boss + jede 5. Runde 1 Biom-Boss
#   25-29  wie 15-24
#   30     2 Mini-Bosse + 1 Biom-Boss (= 3)
const BOSS_BASE_MINI := 125          # MonsterStats.MINI_EARTH/MARS/JUNGLE/VOLT
const BOSS_BASE_BIOM := 230          # MonsterStats.BOSS_EARTH (hoechster Wert)
const BOSS_HP_FAKTOR := 0.55         # B2: Boss-HP = Basis * hp_mult * 0.55
const BOSS_ANTEIL_MAX := 0.45        # B2: Boss hoechstens 45 % der Runden-HP
const TOT_DIFF := 11                 # Spiegel von MonsterStats.MonsterType.TOT_DIFF

static var _plan_cache: Dictionary = {}


static func boss_counts(r: int) -> Dictionary:
	var mini: int = 0
	var biom: int = 0
	if r >= 8 and r <= 14:
		mini = 1 if r % 2 == 0 else 0
	elif r >= 15 and r <= 29:
		mini = 1
		biom = 1 if r % 5 == 0 else 0
	elif r == 30:
		mini = 2
		biom = 1
	return { "mini": mini, "biom": biom }


static func boss_count(r: int) -> int:
	var b: Dictionary = boss_counts(r)
	return int(b["mini"]) + int(b["biom"])


static func boss_hp_raw(r: int, diff: String = "normal") -> float:
	var b: Dictionary = boss_counts(r)
	if int(b["mini"]) + int(b["biom"]) <= 0:
		return 0.0
	return (float(int(b["mini"])) * float(BOSS_BASE_MINI)
		+ float(int(b["biom"])) * float(BOSS_BASE_BIOM)) * hp_mult(r, diff) * BOSS_HP_FAKTOR


static func _build_plan() -> void:
	# v1.41 (B5): Boss-HP zaehlt in die Summe. Damit die Kurve R1 -> R30
	# trotzdem STRENG steigt, bekommen Runden ohne (oder mit kleinem) Boss
	# einen Ausgleichsfaktor auf die Gruppen-HP. Der Boss bleibt bei
	# hoechstens 45 % der Runden-HP.
	var prev: float = 0.0
	for r in range(1, ROUND_COUNT + 1):
		var g: float = hp_total(r, "normal")
		var b: float = boss_hp_raw(r, "normal")
		var ziel: float = prev * 1.02
		var f: float = 1.0
		if g > 0.0 and g + b < ziel:
			f = (ziel - b) / g
		var g2: float = g * f
		var deckel: float = BOSS_ANTEIL_MAX / (1.0 - BOSS_ANTEIL_MAX) * g2
		var b2: float = minf(b, deckel)
		var total: float = g2 + b2
		_plan_cache[r] = { "gruppen": g2, "boss": b2, "total": total, "faktor": f }
		prev = total


static func plan_for(r: int) -> Dictionary:
	if _plan_cache.is_empty():
		_build_plan()
	return _plan_cache.get(clampi(r, 1, ROUND_COUNT), {})


static func catchup_factor(r: int) -> float:
	return float(plan_for(r).get("faktor", 1.0))


static func hp_mult_spawn(r: int, diff: String = "normal") -> float:
	# HP-Multiplikator, der beim Spawn auf normale Monster wirkt
	return hp_mult(r, diff) * catchup_factor(r)


static func boss_hp_sum(r: int, diff: String = "normal") -> float:
	if diff != "normal":
		# andere Schwierigkeiten skalieren den Boss anteilig mit
		return float(plan_for(r).get("boss", 0.0)) * (hp_mult(r, diff) / maxf(0.01, hp_mult(r, "normal")))
	return float(plan_for(r).get("boss", 0.0))


static func hp_total_with_boss(r: int, diff: String = "normal") -> float:
	if diff != "normal":
		return float(plan_for(r).get("gruppen", 0.0)) * (hp_mult(r, diff) / maxf(0.01, hp_mult(r, "normal"))) + boss_hp_sum(r, diff)
	return float(plan_for(r).get("total", 0.0))


static func preview_with_boss(r: int, diff: String = "normal") -> String:
	var txt: String = preview(r, diff)
	var b: Dictionary = boss_counts(r)
	var parts: Array = []
	if int(b["mini"]) > 0:
		parts.append("%dx MINI-BOSS" % int(b["mini"]))
	if int(b["biom"]) > 0:
		parts.append("%dx BIOM-BOSS" % int(b["biom"]))
	if not parts.is_empty():
		txt += ", " + ", ".join(parts)
	return txt


static func price_mult(r: int, diff: String = "normal") -> float:
	var d: Dictionary = DIFFICULTY.get(diff, DIFFICULTY["normal"])
	return (1.0 + 0.075 * float(maxi(0, r - 1))) * float(d["preis"])
