class_name Balance
extends RefCounted

# ============================================================
# v1.56 — ZENTRALE ZAHLENQUELLE (Spec K1)
# ============================================================
# Alle Modi (ENDLOS, WELLEN+SHOP, RUNDEN) ziehen ihre Gegnerwerte aus DIESEM
# Modell. waves.gd / rounds.gd / game_manager.DIFFICULTY sind nur noch
# Adapter - sie halten keine eigenen Balancetabellen mehr.
#
# Leitidee (Spec K2): Schwierigkeit ist DRUCK PRO SEKUNDE relativ zur
# Spielerleistung, mit geplanten Erholungsfenstern (Saegezahn), nicht ein
# HP-Multiplikator.
#
#   druck()        = HP/s die auf den Spieler zukommen / spieler_dps()
#   ziel_druck()   = Soll-Kurve ueber die Zeit (je Modus + Stufe)
#   spieler_dps()  = Referenz-DPS der Startwaffe (Pistole 3 dmg / 0,4 s)
#   fehler_budget()= erlaubte Treffer in 60 s (Ziel-Erlebnis je Stufe)
#
# Belegzeilen (Pflicht laut Spec):
#   [BAL][MODELL] modus=... stufe=... druck=... ziel=... abweichung=...
#   [BAL][PHASE] art=anlauf|peak|erholung|boss dauer=... druck=...
#   [BAL][ERHOLUNG] spawn=0 gegner_aktiv=...
#   [BAL][MIX] rolle=hetzer anteil=... aktiv_max=...
#   [BAL][BOSS] art=mini|biom phase=1|2 ersetzt_peak=true adds=0 telegraph=2.0
#   [BAL][ANKER] art=levelup+heilung grund=hp_niedrig

const STUFEN := ["leicht", "normal", "schwer", "hardcore"]
const MODI := ["endlos", "wellen", "runden"]

# MonsterType-Indizes (Spiegel von monster_ai.gd, Reihenfolge bindend)
const T_GREEN := 0
const T_RED := 1
const T_BLUE := 2
const T_PURPLE := 3
const T_YELLOW := 4
const T_PINK := 5
const T_ORANGE := 6

# ------------------------------------------------------------
# Das Modell. Jede Stufe unterscheidet sich in der STRUKTUR, nicht nur
# im Multiplikator (Fix gegen P5):
#   - Anlauf/Peak/Erholung sind unterschiedlich lang
#   - Hetzer-Limit und Schonfrist sind unterschiedlich
#   - Boss-Kadenz (erster Boss, Abstand) ist unterschiedlich
#   - Endlos-Druckkurve startet/endet anders und rampt anders schnell
# ------------------------------------------------------------
const MODELL := {
	"leicht": {
		"idx": 0, "hp": 0.85, "dmg": 0.75, "speed": 0.94, "hearts": 6, "coins": 1.25,
		"hit_ziel": 3.0, "preis": 0.90,
		# Endlos-Druckkurve: entspannt, aber nicht geschenkt
		"druck_start": 0.015, "druck_ende": 0.08, "druck_rampe": 720.0,
		"fenster": 3.2, "anlauf": 12.0, "peak": 15.0, "erholung": 14.0,
		"max_aktiv": 3,
		"hetzer_pro": 8, "schon_gegner": 8.0, "schon_hetzer": 60.0,
		"mini_ab": 300.0, "mini_alle": 180.0, "boss_ab": 660.0, "boss_alle": 420.0,
		"boss_kampf": 28.0, "erholung_nach_boss": 8.0,
		"hp_wachstum": 0.045, "hp_deckel": 2.2,
		"anker_alle": 90.0, "anker_hp": 0.40,
		"wellen_hp": 1.15, "wellen_anzahl": 0.80,
		"runden_hp": 0.80, "runden_anzahl": 0.70,
	},
	"normal": {
		"idx": 1, "hp": 1.00, "dmg": 1.00, "speed": 1.00, "hearts": 5, "coins": 1.00,
		"hit_ziel": 5.5, "preis": 1.00,
		"druck_start": 0.030, "druck_ende": 0.20, "druck_rampe": 600.0,
		"fenster": 2.5, "anlauf": 10.0, "peak": 16.0, "erholung": 12.0,
		"max_aktiv": 5,
		"hetzer_pro": 6, "schon_gegner": 6.0, "schon_hetzer": 60.0,
		"mini_ab": 240.0, "mini_alle": 150.0, "boss_ab": 540.0, "boss_alle": 300.0,
		"boss_kampf": 24.0, "erholung_nach_boss": 7.0,
		"hp_wachstum": 0.060, "hp_deckel": 3.2,
		"anker_alle": 90.0, "anker_hp": 0.40,
		"wellen_hp": 1.00, "wellen_anzahl": 1.00,
		"runden_hp": 1.00, "runden_anzahl": 1.00,
	},
	"schwer": {
		"idx": 2, "hp": 1.25, "dmg": 1.35, "speed": 1.08, "hearts": 4, "coins": 0.78,
		"hit_ziel": 10.0, "preis": 1.20,
		"druck_start": 0.05, "druck_ende": 0.18, "druck_rampe": 300.0,
		"fenster": 2.0, "anlauf": 7.0, "peak": 20.0, "erholung": 9.0,
		"max_aktiv": 8,
		"hetzer_pro": 4, "schon_gegner": 5.0, "schon_hetzer": 30.0,
		"mini_ab": 100.0, "mini_alle": 90.0, "boss_ab": 240.0, "boss_alle": 180.0,
		"boss_kampf": 20.0, "erholung_nach_boss": 6.0,
		"hp_wachstum": 0.075, "hp_deckel": 4.0,
		"anker_alle": 120.0, "anker_hp": 0.30,
		"wellen_hp": 1.25, "wellen_anzahl": 0.95,
		"runden_hp": 1.25, "runden_anzahl": 1.15,
	},
	"hardcore": {
		"idx": 3, "hp": 1.45, "dmg": 1.70, "speed": 1.14, "hearts": 3, "coins": 0.58,
		"hit_ziel": 15.0, "preis": 1.35,
		"druck_start": 0.32, "druck_ende": 1.20, "druck_rampe": 120.0,
		"fenster": 1.6, "anlauf": 5.0, "peak": 24.0, "erholung": 6.0,
		"max_aktiv": 18,
		"hetzer_pro": 3, "schon_gegner": 4.0, "schon_hetzer": 20.0,
		"mini_ab": 70.0, "mini_alle": 70.0, "boss_ab": 160.0, "boss_alle": 140.0,
		"boss_kampf": 16.0, "erholung_nach_boss": 6.0,
		"hp_wachstum": 0.090, "hp_deckel": 4.6,
		"anker_alle": 150.0, "anker_hp": 0.30,
		"wellen_hp": 1.50, "wellen_anzahl": 1.20,
		"runden_hp": 1.45, "runden_anzahl": 1.30,
	},
}

# Rollen (Spec K3). Reihenfolge bindend: 0=Laeufer 1=Hetzer 2=Anker 3=Stoerer
const ROLLEN := ["laeufer", "hetzer", "anker", "stoerer"]
const ROLLEN_QUOTE := {
	"leicht":   { "laeufer": 0.60, "hetzer": 0.20, "anker": 0.15, "stoerer": 0.05 },
	"normal":   { "laeufer": 0.50, "hetzer": 0.25, "anker": 0.20, "stoerer": 0.05 },
	"schwer":   { "laeufer": 0.40, "hetzer": 0.30, "anker": 0.22, "stoerer": 0.08 },
	"hardcore": { "laeufer": 0.30, "hetzer": 0.35, "anker": 0.25, "stoerer": 0.10 },
}

# Basis-HP je Typ (Spiegel monster_ai.type_stats - nur als Referenz fuer druck())
const TYP_HP := {
	0: 3, 1: 2, 2: 4, 3: 6, 4: 3, 5: 4, 6: 12,
	8: 5, 9: 16, 10: 5, 31: 6, 32: 14, 33: 9, 34: 3,
}
const MITTLERE_HP := 3.6      # mix-gewichtete Basis-HP (Laeufer/Anker-Mittel)
const REF_DPS := 7.5          # Pistole: 3 Schaden / 0,4 s Schussfolge


# ============================================================
# Basisfunktionen (Spec K1: druck, ziel_druck, spieler_dps, fehler_budget)
# ============================================================

static func data(stufe: String) -> Dictionary:
	return MODELL.get(stufe, MODELL["normal"])


static func stufe_von_index(idx: int) -> String:
	return STUFEN[clampi(idx, 0, STUFEN.size() - 1)]


static func index_von_stufe(stufe: String) -> int:
	return int(data(stufe).get("idx", 1))


static func spieler_dps() -> float:
	return REF_DPS


static func fehler_budget(stufe: String) -> int:
	return int(round(float(data(stufe)["hit_ziel"])))


static func druck(anzahl: float, hp_mult: float, fenster: float, hp_basis: float = MITTLERE_HP) -> float:
	# Druck = (Gegner-HP * Anzahl) / Spawn-Fenster, normiert auf die Spieler-DPS
	if fenster <= 0.0:
		return 0.0
	return (float(anzahl) * float(hp_basis) * float(hp_mult)) / (fenster * spieler_dps())


static func rate_fuer_druck(ziel: float, hp_mult: float, hp_basis: float = MITTLERE_HP) -> float:
	# Gegner pro SEKUNDE fuer den Soll-Druck. Wichtig fuer kleine Druecke:
	# anzahl_fuer_druck() rundet auf mindestens 1 Gegner je Fenster und setzt
	# damit eine Untergrenze (1 Gegner / 2,5 s = 1,44 HP/s) - das war die
	# Ursache, warum "Druck senken" nichts bewirkt hat. Der Spawner arbeitet
	# deshalb mit diesem kontinuierlichen Budget.
	if hp_basis <= 0.0 or hp_mult <= 0.0:
		return 0.0
	return (float(ziel) * spieler_dps()) / (float(hp_basis) * float(hp_mult))


static func anzahl_fuer_druck(ziel: float, hp_mult: float, fenster: float, hp_basis: float = MITTLERE_HP) -> int:
	# Umkehrung von druck(): wie viele Gegner braucht es fuer den Soll-Druck?
	if hp_basis <= 0.0 or hp_mult <= 0.0:
		return 1
	var n: float = (float(ziel) * fenster * spieler_dps()) / (float(hp_basis) * float(hp_mult))
	return maxi(1, int(round(n)))


static func ziel_druck(modus: String, stufe: String, zeit_s: float) -> float:
	# Soll-Kurve. ENDLOS/WELLEN/RUNDEN haben unterschiedliche Anlaufphasen:
	# die Rampe startet erst nach der Schonfrist, damit der Anfang ruhig ist.
	var d: Dictionary = data(stufe)
	var start: float = float(d["druck_start"])
	var ende: float = float(d["druck_ende"])
	var rampe: float = maxf(1.0, float(d["druck_rampe"]))
	var schon: float = float(d["schon_gegner"])
	var t: float = maxf(0.0, float(zeit_s) - schon)
	var f: float = clampf(t / rampe, 0.0, 1.0)
	var z: float = lerpf(start, ende, f)
	match modus:
		"runden":
			# Runden haben ihre eigene Progression (Rundenindex), hier nur Referenz
			z *= 0.85
		"wellen":
			z *= 0.95
	return z


# ============================================================
# Wellen-/Runden-Kurven (Adapter-Ziele, ersetzen WAVE_BALANCE / ROUNDS.hp_mult)
# ============================================================

static func hp_mult(welle: int, stufe: String = "normal") -> float:
	# Spec K5: weiche Kurve 1 + 0.06*welle, hart gedeckelt (kein Exponentialwachstum)
	var d: Dictionary = data(stufe)
	var roh: float = 1.0 + float(d["hp_wachstum"]) * float(maxi(0, welle - 1))
	return minf(float(d["hp_deckel"]), roh) * float(d["hp"])


static func spd_mult(welle: int) -> float:
	# Tempodeckel 1.18 bleibt (v1.51) - darueber wird nicht gegangen
	return minf(1.18, 1.0 + 0.012 * float(maxi(0, welle - 1)))


static func dmg_mult(stufe: String) -> float:
	return float(data(stufe)["dmg"])


static func speed_mult(stufe: String) -> float:
	return float(data(stufe)["speed"])


static func hearts(stufe: String) -> int:
	return int(data(stufe)["hearts"])


static func coin_mult(stufe: String) -> float:
	return float(data(stufe)["coins"])


# ============================================================
# Rollen-Mix + Hetzer-Limit (Spec K3)
# ============================================================

static func rolle_von_type(t: int) -> String:
	# Rollen nach Spec K3. WICHTIG (Bug v1.56b): die Welt-Typen (Mars/Jungle/
	# Elektro) muessen EIGENE Rollen haben. Vorher waren 11..34 pauschal
	# "hetzer" - im Elektro-Pool gibt es damit keinen einzigen Laeufer/Anker,
	# also fiel der Spawner auf GREEN zurueck und die Elektro-Welt spawnte
	# nur gruene Wiesen-Monster.
	match t:
		0: return "laeufer"                       # GREEN
		1, 5: return "hetzer"                     # RED, PINK
		2, 3, 6: return "anker"                   # BLUE, PURPLE, ORANGE
		4, 8, 31: return "stoerer"                # YELLOW, BURROWER, SPORENBRUT
		# Mars
		11: return "laeufer"                      # MARS_ALIEN   72 px/s
		12: return "anker"                        # MARS_ROVER   46 px/s
		15: return "hetzer"                       # MARS_DRONE  132 px/s kamikaze
		16: return "anker"                        # MARS_GUARD
		# Jungle
		13: return "laeufer"                      # ROBO_APE     78 px/s
		17: return "hetzer"                       # ROBO_TIGER
		18: return "anker"                        # VINE_TRAP    steht
		14: return "stoerer"                      # BIG_FLOWER   steht, spuckt
		# Elektro
		25: return "hetzer"                       # VOLT_DRONE   120 px/s
		26: return "laeufer"                      # VOLT_TROOPER  78 px/s
		27: return "hetzer"                       # VOLT_SPIDER  105 px/s
		29: return "stoerer"                      # VOLT_SPOOLER  52 px/s, Salve
	# Alles andere (inkl. Bosse/Minis) gilt als Anker - Bosse werden ohnehin
	# nicht aus dem Pool gezogen (siehe ist_boss_typ()).
	return "anker"


static func ist_boss_typ(t: int) -> bool:
	# Bosse/Mini-Bosse duerfen NICHT als normaler Wellengegner erscheinen.
	return t == 7 or t == 19 or t == 20 or t == 21 or t == 22 or t == 23 \
		or t == 24 or t == 28 or t == 30


static func quote(stufe: String, rolle: String) -> float:
	return float(ROLLEN_QUOTE.get(stufe, ROLLEN_QUOTE["normal"]).get(rolle, 0.0))


static func hetzer_max(aktiv: int, stufe: String) -> int:
	# Nie mehr als 1 Hetzer je N Gegner (HARDCORE 1 je 3)
	var pro: int = maxi(1, int(data(stufe).get("hetzer_pro", 6)))
	return maxi(1, int(ceil(float(maxi(1, aktiv)) / float(pro))))


static func typen_fuer_rolle(rolle: String, verfuegbar: Array) -> Array:
	var out: Array = []
	for t in verfuegbar:
		if rolle_von_type(int(t)) == rolle:
			out.append(int(t))
	return out


static func rolle_waehlen(stufe: String, mix_gewicht: Dictionary, aktiv_hetzer: int, aktiv: int) -> String:
	# Waehlt die Rolle fuer den naechsten Gegner. Das Hetzer-Limit wird HART
	# eingehalten (Hauptgrund fuer "sofort tot" laut Spec).
	var limit: int = hetzer_max(aktiv, stufe)
	if aktiv_hetzer >= limit:
		mix_gewicht = mix_gewicht.duplicate()
		mix_gewicht["hetzer"] = 0.0
		var summe: float = 0.0
		for r in ROLLEN:
			summe += float(mix_gewicht.get(r, 0.0))
		if summe <= 0.0:
			return "laeufer"
	var roll: float = randf()
	var acc: float = 0.0
	for r in ROLLEN:
		acc += float(mix_gewicht.get(r, 0.0))
		if roll <= acc:
			return r
	return "laeufer"


static func mix_gewichte(stufe: String) -> Dictionary:
	var out: Dictionary = {}
	for r in ROLLEN:
		out[r] = quote(stufe, r)
	return out


# ============================================================
# Phasen (Spec K2: Saegezahn)
# ============================================================

static func phase_laenge(stufe: String, art: String) -> float:
	var d: Dictionary = data(stufe)
	match art:
		"anlauf": return float(d["anlauf"])
		"peak": return float(d["peak"])
		"erholung": return float(d["erholung"])
		"boss": return float(d["boss_kampf"])
	return 8.0


static func naechste_phase(art: String) -> String:
	match art:
		"anlauf": return "peak"
		"peak": return "erholung"
		"erholung": return "anlauf"
		"boss": return "erholung"
	return "anlauf"


static func fenster(stufe: String) -> float:
	return float(data(stufe)["fenster"])


static func max_aktiv(stufe: String) -> int:
	return int(data(stufe)["max_aktiv"])


# ============================================================
# Endlos: Schonfrist, Rettungsanker, Boss-Kadenz (Spec K5)
# ============================================================

static func schonfrist_gegner(stufe: String) -> float:
	return float(data(stufe)["schon_gegner"])


static func schonfrist_hetzer(stufe: String) -> float:
	return float(data(stufe)["schon_hetzer"])


static func anker_intervall(stufe: String) -> float:
	return float(data(stufe)["anker_alle"])


static func anker_schwelle(stufe: String) -> float:
	return float(data(stufe)["anker_hp"])


static func mini_boss_faellig(stufe: String, t_s: float) -> bool:
	var d: Dictionary = data(stufe)
	var ab: float = float(d["mini_ab"])
	var alle: float = float(d["mini_alle"])
	if t_s < ab:
		return false
	return fmod(t_s - ab, alle) < 0.5 or t_s < ab + 0.5


static func boss_faellig(stufe: String, t_s: float) -> bool:
	var d: Dictionary = data(stufe)
	var ab: float = float(d["boss_ab"])
	var alle: float = float(d["boss_alle"])
	if t_s < ab:
		return false
	return fmod(t_s - ab, alle) < 0.5 or t_s < ab + 0.5


static func erholung_nach_boss(stufe: String) -> float:
	return float(data(stufe)["erholung_nach_boss"])


# ============================================================
# Wellen-Modus: Boss-Takt (ersetzt Runde 16 "jede 5.")
# ============================================================

static func boss_welle(welle: int) -> bool:
	return welle >= 5 and welle % 5 == 0


static func riesen_welle(welle: int) -> bool:
	return welle >= 10 and welle % 10 == 0


# ============================================================
# Oekonomie: Shop-Guthaben an den Druck koppeln (Spec K6)
# ============================================================

const SHOP_K := 9.0        # Guthaben = k * druck_peak
const SHOP_MIN := 24

static func shop_guthaben(druck_peak: float, boss: bool = false) -> int:
	var g: float = SHOP_K * maxf(0.2, float(druck_peak))
	if boss:
		g *= 2.0
	return maxi(SHOP_MIN, int(round(g)))


static func shop_verhaeltnis(guthaben: int, druck_peak: float) -> float:
	if druck_peak <= 0.0:
		return 0.0
	return float(guthaben) / (SHOP_K * druck_peak)


# ============================================================
# Diagnose: eine Tabellenzeile pro Modus x Stufe
# ============================================================

static func modell_zeile(modus: String, stufe: String) -> String:
	var d: Dictionary = data(stufe)
	var t_probe: Array = [0.0, 60.0, 180.0, 300.0]
	var teile: Array = []
	for t in t_probe:
		teile.append("t%.0f=%.2f" % [float(t), ziel_druck(modus, stufe, float(t))])
	return "[BAL][MODELL] modus=%s stufe=%s ziel(%s) hit_ziel=%.1f hearts=%d hp=%.2f dmg=%.2f spd=%.2f hetzer_pro=%d max_aktiv=%d" % [
		modus, stufe, ", ".join(teile), float(d["hit_ziel"]), int(d["hearts"]),
		float(d["hp"]), float(d["dmg"]), float(d["speed"]),
		int(d["hetzer_pro"]), int(d["max_aktiv"])]


# ============================================================
# Boss-HP aus der Spielerleistung (Spec K4: "Boss-Kampf = Peak")
# ============================================================
# Vorher hatte ein Mini-Boss 125 Basis-HP und ein Riese 230 - unabhaengig
# davon, wie viel Schaden der Spieler macht. Ein Anfaenger (gemessen ca.
# 1,7 DPS effektiv) brauchte damit 70-140 s gegen einen Boss, der ihn
# gleichzeitig jagt: sicherer Tod. Jetzt gilt:
#   Boss-HP = Referenz-DPS * Ziel-Killzeit (je Stufe)
# Ziel-Killzeiten aus Spec 3.3 (RUNDEN, Spalte "Boss-Kill-Zeit").
const BOSS_KILL_ZIEL := { "leicht": 16.0, "normal": 24.0, "schwer": 34.0, "hardcore": 44.0 }
const BOSS_REF_DPS := 2.6
const RIESE_FAKTOR := 1.7


static func boss_kill_ziel(stufe: String) -> float:
	return float(BOSS_KILL_ZIEL.get(stufe, 24.0))


static func boss_hp(stufe: String, riese: bool = false) -> int:
	var hp: float = BOSS_REF_DPS * boss_kill_ziel(stufe)
	if riese:
		hp *= RIESE_FAKTOR
	return maxi(20, int(round(hp)))


static func mini_hp(stufe: String) -> int:
	# Mini-Boss = "Erholungsfenster mit Ziel" (K4). Messung v1.56: ein
	# Anfaenger braucht fuer 42 HP rund 25 s und stirbt dabei (der Mini-Boss
	# jagt ihn mit 100 px/s). Deshalb 45 % der Boss-HP und ein eigenes Tempo.
	return maxi(10, int(round(BOSS_REF_DPS * boss_kill_ziel(stufe) * 0.30)))


const MINI_SPEED := { "leicht": 58.0, "normal": 64.0, "schwer": 80.0, "hardcore": 95.0 }


static func mini_speed(stufe: String) -> float:
	return float(MINI_SPEED.get(stufe, 84.0))
