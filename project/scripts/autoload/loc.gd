# Loc.gd - Autoload: Spielsprache Deutsch / Englisch (Runde 136, Block K)
# Alle Texte stehen historisch hart im Code. Statt hunderte Textstellen
# anzufassen, laeuft apply_tree() rekursiv ueber die Oberflaeche und ersetzt
# jeden Treffer aus dem Woerterbuch. Fehlt ein Eintrag, bleibt der deutsche
# Text stehen - kein leerer Bildschirm.
extends Node

var lang: String = "de"
var _missing: Dictionary = {}      # deutscher Text -> true (schon geloggt)
var stat_labels: int = 0
var stat_done: int = 0
var stat_missing: int = 0

# Deutsch -> Englisch. Schluessel sind die deutschen Originaltexte.
const DE_EN := {
	# --- Startbildschirm / Menue ---
	"SPIELEN": "PLAY",
	"CHARAKTER": "CHARACTER",
	"SAMMLUNG": "COLLECTION",
	"KARTEN": "MAPS",
	"SHOP": "SHOP",
	"EINSTELLUNGEN": "SETTINGS",
	"PAUSE": "PAUSE",
	"FORTSETZEN": "RESUME",
	"NEU STARTEN": "RESTART",
	"HAUPTMENÜ": "MAIN MENU",
	"BEENDEN": "QUIT",
	"ZURÜCK": "BACK",
	"ZURUECK": "BACK",
	"WEITER": "CONTINUE",
	"JA": "YES",
	"NEIN": "NO",
	"ABBRECHEN": "CANCEL",
	"GOLD": "GOLD",
	"EDELSTEINE": "GEMS",
	"EDELSTEIN": "GEM",
	"BESTER SCORE": "BEST SCORE",
	"DEIN HELD": "YOUR HERO",
	# --- HUD ---
	"WAFFEN  (tippen)": "WEAPONS  (tap)",
	"WAFFEN-STATS": "WEAPON STATS",
	"HALTEN": "HOLD",
	"ÖFFNEN": "OPEN",
	"WELLE": "WAVE",
	"MONSTER übrig": "monsters left",
	"LEVEL": "LEVEL",
	"LVL": "LVL",
	# --- Shop ---
	"KISTEN": "CHESTS",
	"STANDARD": "STANDARD",
	"SILBER": "SILVER",
	"PREMIUM": "PREMIUM",
	"ÖFFNEN ": "OPEN ",
	"UMTAUSCHEN": "EXCHANGE",
	"EDELSTEINE AUFLADEN": "TOP UP GEMS",
	"SOFORTKAUF FÜR DEN NÄCHSTEN RUN": "BUY NOW FOR THE NEXT RUN",
	"GLÜCKSWALZE": "SLOT MACHINE",
	"DREHEN": "SPIN",
	"Nur Gold · Einsatz 1–5.000 · Trefferchance 21 %": "Gold only · bet 1-5,000",
	"Chancen": "Odds",
	"KISTE WIRD GEÖFFNET": "OPENING CHEST",
	"NIETE  ·  diesmal nichts": "NOTHING  ·  better luck next time",
	"TROSTPREIS": "CONSOLATION",
	"schon vorhanden": "already owned",
	"NEU!": "NEW!",
	"SO GEWINNT MAN": "HOW TO WIN",
	"GEWINN AB 2 GLEICHEN VON LINKS  ·  MITTE ZÄHLT": "WINS FROM 2 MATCHING FROM THE LEFT  ·  CENTER COUNTS",
	"EINSATZ": "BET",
	"GEWINN": "WIN",
	"NICHT GENUG GOLD": "NOT ENOUGH GOLD",
	"Einsatz": "Bet",
	# --- Charakter / Kosmetik ---
	"FARBE": "COLOR",
	"HUT": "HAT",
	"SKIN": "SKIN",
	"NAME": "NAME",
	"FARBE WÄHLEN": "CHOOSE COLOR",
	"HUT WÄHLEN": "CHOOSE HAT",
	"SKIN WÄHLEN": "CHOOSE SKIN",
	"freigeschaltet": "unlocked",
	"NOCH NICHTS FREIGESCHALTET — KISTEN IM SHOP": "NOTHING UNLOCKED YET — CHESTS IN THE SHOP",
	"Farben": "colors",
	"Hüte": "hats",
	"Skins": "skins",
	"GESPERRT": "LOCKED",
	"FREIGESCHALTET": "UNLOCKED",
	"AKTIV": "ACTIVE",
	"GEWÄHLT": "SELECTED",
	"WÄHLEN": "SELECT",
	"KAUFEN": "BUY",
	"ANGELEGT": "EQUIPPED",
	"KOLLEKTION": "COLLECTION",
	"GESAMT": "TOTAL",
	# --- Karten / Jahreszeiten ---
	"Jede Karte ist eine eigene Welt mit eigenen Monstern. Freischalten per Schalter (XP in einem Run) oder mit Gold.":
		"Every map is its own world with its own monsters. Unlock with gold.",
	"FRUEHLING": "SPRING",
	"SOMMER": "SUMMER",
	"HERBST": "AUTUMN",
	"WINTER": "WINTER",
	"FEST": "FIXED",
	"WECHSELND": "ROTATING",
	"als Nächstes": "next",
	"erst eine zweite Jahreszeit freischalten": "unlock a second season first",
	"ERST EINE ZWEITE JAHRESZEIT FREISCHALTEN": "UNLOCK A SECOND SEASON FIRST",
	"ZU WENIG GOLD": "NOT ENOUGH GOLD",
	"STURM": "STORM",
	"UEBERLAST": "OVERLOAD",
	"BLACKOUT": "BLACKOUT",
	"NEBEL": "FOG",
	# --- Upgrades ---
	"LEVEL UP!": "LEVEL UP!",
	"Waehle ein Upgrade": "Choose an upgrade",
	"NOCH": "LEFT",
	"VERFÜGBAR": "AVAILABLE",
	"nach der Wahl geht es sofort weiter": "the run continues right after your pick",
	"UPGRADES VERFÜGBAR": "UPGRADES AVAILABLE",
	"UPGRADE VERFÜGBAR": "UPGRADE AVAILABLE",
	"ANTIPPEN": "TAP",
	"UPGRADE": "UPGRADE",
	"VON": "OF",
	"Stufe": "Level",
	# --- Einstellungen ---
	"SCHWIERIGKEIT": "DIFFICULTY",
	"ZIELHILFE": "AIM ASSIST",
	"GRAFIK": "GRAPHICS",
	"MUSIK": "MUSIC",
	"SOUNDEFFEKTE": "SOUND EFFECTS",
	"SPRACHE": "LANGUAGE",
	"DEUTSCH": "GERMAN",
	"ENGLISH": "ENGLISH",
	"STUMM": "MUTED",
	"AN": "ON",
	"AUS": "OFF",
	"LEICHT": "EASY",
	"NORMAL": "NORMAL",
	"SCHWER": "HARD",
	"HARDCORE": "HARDCORE",
	"SCHWACH": "WEAK",
	"STARK": "STRONG",
	"NIEDRIG": "LOW",
	"HOCH": "HIGH",
	"MITTEL": "MEDIUM",
	"ZURÜCKSETZEN": "RESET",
	# --- Tod / Netzwerk ---
	"GAME OVER": "GAME OVER",
	"NOCHMAL": "AGAIN",
	"VERBINDUNG ZUM HOST ABGEBROCHEN": "CONNECTION TO HOST LOST",
	"SPIELER": "PLAYER",
	"IST GEFALLEN - GEH HIN UND WECK AUF": "IS DOWN - GO AND REVIVE",
	"MINI-BOSS BESIEGT": "MINI BOSS DEFEATED",
	# --- Runde 136b: nachgezogene Texte (aus [LOC][T]-Log) ---
	"DEIN HELD IST BEREIT": "YOUR HERO IS READY",
	"MONSTER AUF DEM PLAN": "MONSTERS INCOMING",
	"TIPPE ZUM STARTEN": "TAP TO START",
	"SPIELEN (DUO)": "PLAY (CO-OP)",
	"LAN-SPIEL": "LAN GAME",
	"GESCHAFFT": "CLEARED",
	"übrig": "left",
	"NEUES ZIEL": "NEW TARGET",
	"Farben + Hüte": "colors + hats",
	"bessere Chancen": "better odds",
	"auch Skins": "incl. skins",
	"Kiste": "Chest",
	"NIETE": "NO WIN",
	"Trostpreis": "consolation",
	"Kisten schalten neue frei": "chests unlock new ones",
	"HUT  (Kisten schalten neue frei)": "HAT  (chests unlock new ones)",
	"SKIN  (Kisten schalten neue frei)": "SKIN  (chests unlock new ones)",
	"FARBE GESPERRT — im SHOP freischalten": "COLOR LOCKED — unlock in the shop",
	"SKIN GESPERRT — im SHOP freischalten": "SKIN LOCKED — unlock in the shop",
	"ZU WENIG GOLD (2.500 NÖTIG)": "NOT ENOUGH GOLD (2,500 NEEDED)",
	"Schalter": "Gate",
	"Aktiv": "Active",
	"ERDE": "EARTH",
	"MARS": "MARS",
	"DSCHUNGEL": "JUNGLE",
	"ELEKTRO": "VOLT",
	"Waehle ein Upgrade!": "Choose an upgrade!",
	"GRAFIK-STUFE": "GRAPHICS QUALITY",
	"FPS ANZEIGEN": "SHOW FPS",
	"TON": "SOUND",
	"NOCHMAL SPIELEN": "PLAY AGAIN",
	"NEUER REKORD": "NEW RECORD",
	"GESAMMELTES GOLD": "GOLD EARNED",
	"Rueckkehr zur Startseite": "Back to menu in",
	"WELLE GESCHAFFT": "WAVE CLEARED",

	# --- v1.46 (A3): Umbenennung "Aufgaben -> Challenges" ---
	"CHALLENGES": "CHALLENGES",
	"CHALLENGE GESCHAFFT!": "CHALLENGE CLEARED!",
	"CHALLENGE VERFEHLT": "CHALLENGE FAILED",

	# --- Runde 136c: Seiten aus dem vollstaendigen EN-Lauf ---
	"HAUPTMENUE": "MAIN MENU",
	"„DEIN HELD IST BEREIT!“": "\"YOUR HERO IS READY!\"",
	"Top-Down Monster Shooter": "Top-down monster shooter",
	"MODUS: ENDLOS": "MODE: ENDLESS",
	"MODUS: WELLEN": "MODE: WAVES",
	"LAN SPIEL": "LAN GAME",
	"STANDARD-KISTE": "STANDARD CHEST",
	"SILBER-KISTE": "SILVER CHEST",
	"PREMIUM-KISTE": "PREMIUM CHEST",
	"🪙  DREHEN": "🪙  SPIN",
	"SCHNELLFEUER": "RAPID FIRE",
	"SCHNELLFEUER 20s": "RAPID FIRE 20s",
	"20 % schneller schiessen": "shoot 20 % faster",
	"2x TRANK": "2x POTION",
	"heilt 40 LP": "heals 40 HP",
	"2x BOMBE": "2x BOMB",
	"Flaechenschaden": "area damage",
	"Die ganze Reise: Wiese, Wueste, Eisfeld, Lavahoelle in einem Run":
		"The whole trip: meadow, desert, ice field and lava in one run",
	"WAEHLEN": "SELECT",
	"GEWAEHLT": "SELECTED",
	"FRUE": "SPRI",
	"SOMM": "SUMM",
	"HERB": "AUTU",
	"WINT": "WINT",
	"JUNGLE-PLANET": "JUNGLE PLANET",
	"Roter Sand, Mars-Maennchen und Rover. Alles rutscht — Drift-Physik!":
		"Red sand, Mars aliens and rovers. Everything slides — drift physics!",
	"Dichter Dschungel, Robo-Affen werfen Bananen, Riesenblumen spucken Sporen":
		"Dense jungle, robo-apes throw bananas, giant flowers spit spores",
	"ELEKTRO-WELT": "VOLT WORLD",
	"Sturmland aus Stahl und Strom: Teslaspulen, Kapazitaeten, Schrottroboter":
		"Stormland of steel and current: tesla coils, capacitors, scrap robots",
	"FARBEN 2/10      SKINS 1/25      HUETE 2/29": "COLORS 2/10      SKINS 1/25      HATS 2/29",
	"FARBEN": "COLORS",
	"HUETE": "HATS",
	"WEITER  (ESC)": "CONTINUE  (ESC)",
	"NEUSTART": "RESTART",
	"HAUPTMENUE ": "MAIN MENU ",
	"SCHWIERIGKEIT  (sofort wirksam)": "DIFFICULTY  (instant)",
	"ZIELHILFE  (rastet auf Monster ein)": "AIM ASSIST  (locks onto monsters)",
	"FPS-ANZEIGE: AUS": "FPS DISPLAY: OFF",
	"FPS-ANZEIGE: AN": "FPS DISPLAY: ON",
	"MUSIK: AN": "MUSIC: ON",
	"MUSIK: AUS": "MUSIC: OFF",
	"SOUNDEFFEKTE: AN": "SOUND EFFECTS: ON",
	"SOUNDEFFEKTE: AUS": "SOUND EFFECTS: OFF",
	"Aktuell: HOCH — Soft-Look-Shader, max 150 Monster": "Current: HIGH — soft-look shader, max 150 monsters",
	"Tipp: Feuerknopf gedrückt halten = Dauerfeuer   ·   Q = Trank   ·   E = Bombe":
		"Tip: hold fire = continuous fire   ·   Q = potion   ·   E = bomb",
	"RUN-UEBERSICHT": "RUN SUMMARY",
	"Score: 0": "Score: 0",
	"Best: 0": "Best: 0",
	"PISTOLE": "PISTOL",
	"SCHROTFLINTE": "SHOTGUN",
	"MASCHINENPISTOLE": "MACHINE PISTOL",
	"REVOLVER": "REVOLVER",
	"Der Standard. Unendlich Munition, keine Nachladezeit. Verlaesslich, aber schwach gegen Panzer.":
		"The default. Unlimited ammo, no reload. Reliable, but weak against armour.",
	"6 Schuss, 3 Streu-Patronen pro Schuss. Toetet_groups im Nahbereich, reloadt aber lang.":
		"6 shots, 3 pellets each. Kills groups up close, but reloads slowly.",
	"40 Schuss Magazin, 600 RPM. Dauerfeuer, aber nach 40 Schuss 2.2s Nachladen.":
		"40-round magazine, 600 RPM. Sustained fire, 2.2s reload after 40 shots.",
	"24 Schuss, sehr hohe RPM und 560 px/s Geschwindigkeit. Nach 24 Schuss 1.6s Nachladen.":
		"24 shots, very high RPM and 560 px/s. 1.6s reload after 24 shots.",
	"6 Schuss, 9 Schaden pro Schuss. Wiegt schwer, trifft aber am haeufigsten.":
		"6 shots, heavy damage each. Slow, but hits hardest.",
	"Tippe auf eine Waffe fuer alle Werte. SCHADEN pro Schuss, RPM = Schuesse pro Minute, NACHLADEN = Magazin-Nachladezeit.":
		"Tap a weapon for all values. DAMAGE per shot, RPM = rounds per minute, RELOAD = magazine reload time.",
	"UNENDLICH": "UNLIMITED",

	# --- Farben ---
	"BLAU": "BLUE",
	"ROT": "RED",
	"GRUEN": "GREEN",
	"GELB": "YELLOW",
	"LILA": "PURPLE",
	"WEISS": "WHITE",
	"ORANGE": "ORANGE",
	"CYAN": "CYAN",
	"ROSA": "PINK",
	"STAHL": "STEEL",

	# --- Huete ---
	"OHNE": "NONE",
	"KAPPE": "CAP",
	"COWBOY": "COWBOY",
	"KRONE": "CROWN",
	"ZYLINDER": "TOPHAT",
	"WOLLMÜTZE": "BEANIE",
	"PIRAT": "PIRATE",
	"STROHHUT": "STRAW HAT",
	"WIKINGER": "VIKING",
	"STERN": "STAR",
	"HALO": "HALO",
	"ANTENNE": "ANTENNA",
	"KRÖNCHEN": "TIARA",
	"STIRNBAND": "HEADBAND",
	"BRILLE": "GLASSES",
	"ABZEICHEN": "BADGE",
	"RUCKSACK": "BACKPACK",
	"HÖRNER": "HORNS",
	"BLATTKRANZ": "LEAF WREATH",
	"ELEKTRO-ANTENNE": "VOLT ANTENNA",
	"MARS-VISIER": "MARS VISOR",
	"KRISTALL-HALO": "CRYSTAL HALO",
	"DROHNE": "DRONE",
	"BLITZ-SCHWEIF": "BOLT TAIL",
	"SCHULTERPLATTEN": "PAULDRONS",
	"STERNEN-HALO": "STELLAR HALO",
	"METEOR": "METEOR",
	"NEON-AURA": "NEON AURA",
	"STERNCHEN": "LITTLE STAR",

	# --- Skins ---
	"PANZERHELD": "ARMOR HERO",
	"NINJA": "NINJA",
	"ROBOTER": "ROBOT",
	"COMIC-HELD": "COMIC HERO",
	"MARS-MARSCHALL": "MARS MARSHAL",
	"GEIST": "GHOST",
	"ALIEN": "ALIEN",
	"SCHROTT-SCHÜTZE": "SCRAP GUNNER",
	"WÜSTENWANDERER": "DESERT WANDERER",
	"DSCHUNGEL-SCOUT": "JUNGLE SCOUT",
	"STRASSENKÄMPFER": "STREET FIGHTER",
	"MARS-PLÜNDERER": "MARS RAIDER",
	"DSCHUNGEL-JÄGER": "JUNGLE HUNTER",
	"ELEKTRO-TECHNIKER": "VOLT TECH",
	"WIKINGER-RAIDER": "VIKING RAIDER",
	"ROBO-AFFE": "ROBO APE",
	"VOLT-KOMMANDANT": "VOLT COMMANDER",
	"METEOR-GOLEM": "METEOR GOLEM",
	"SPLITTER-KÖNIG": "SHARD KING",
	"STERNEN-WIKINGER": "STELLAR VIKING",
	"SONNENBOSS": "SUN BOSS",
	"URWALD-TITAN": "PRIMAL TITAN",
	"NEON-PHANTOM": "NEON PHANTOM",
	# --- weitere Texte aus dem zweiten EN-Lauf ---
	"HELD": "HERO",
	"SMG": "SMG",
	"LASER": "LASER",
	"PING": "PING",
	"„DEINE WAFFEN SIND LADEN!“": "\"YOUR WEAPONS ARE LOADED!\"",
	"DEINE WAFFEN SIND LADEN": "YOUR WEAPONS ARE LOADED",
	"FPS-ANZEIGE zeigt: FPS | Draw-Calls | Objekte | Proz-ms | Phys-ms | Monster | Stufe":
		"FPS display: FPS | draw calls | objects | proc-ms | phys-ms | monsters | quality",
	# --- Ladebildschirm-Sprueche ---
	"„BEREIT FUER ACTION!“": "\"READY FOR ACTION!\"",
	"„LETZTER SCHUSS GEFAHR!“": "\"LAST SHOT FIRED!\"",
	"„MONSTER AUF DEM PLAN!“": "\"MONSTERS INCOMING!\"",
	"BEREIT FUER ACTION!": "READY FOR ACTION!",
	"LETZTER SCHUSS GEFAHR!": "LAST SHOT FIRED!",
	"MONSTER AUF DEM PLAN!": "MONSTERS INCOMING!",
	"DEIN HELD IST BEREIT!": "YOUR HERO IS READY!",

	# ============================================================
	# v1.41 (F5): v1.40/v1.41-Oberflaechen - Seltenheiten, Artikel,
	# HUD, Shop, Menue, Themen-Banner, Waffen-Stats
	# ============================================================
	# --- Seltenheiten ---
	"GEWOEHNLICH": "COMMON",
	"SELTEN": "RARE",
	"EPISCH": "EPIC",
	"LEGENDAER": "LEGENDARY",
	# v1.42 (P2.5): Kurzbegruendung der Waffen-Seltenheiten
	"+0 % — Referenzstufe": "+0% — reference tier",
	"+30 % Schaden, −12 % Schussabstand, +20 % Magazin, −14 % Nachladen": "+30% damage, −12% shot interval, +20% magazine, −14% reload",
	"+65 % Schaden, −24 % Schussabstand, +45 % Magazin, −26 % Nachladen": "+65% damage, −24% shot interval, +45% magazine, −26% reload",
	"+110 % Schaden, −38 % Schussabstand, +75 % Magazin, −40 % Nachladen": "+110% damage, −38% shot interval, +75% magazine, −40% reload",
	# --- Artikel des Wellen-Shops ---
	"WELLEN-SHOP": "WAVE SHOP",
	"HEILTRANK x1": "HEALING POTION x1",
	# v1.42 (P3.5): Trank-Beschreibung (Regeneration)
	"Regeneriert 3 Herzen über 4,5 s (Taste Q)": "Regenerates 3 hearts over 4.5 s (key Q)",
	"regeneriert 3 Herzen über 4,5 s": "regenerates 3 hearts over 4.5 s",
	"HEILTRANK": "HEALING POTION",
	"BOMBE x1": "BOMB x1",
	"BOMBE": "BOMB",
	"LEBEN ZURUECK": "EXTRA LIFE",
	"SCHILD +2": "SHIELD +2",
	"+1 HERZ": "+1 HEART",
	"FROST 10 s": "FREEZE 10 s",
	"BESITZT · Seltenheit wählen": "OWNED · choose rarity",
	"AUSGERÜSTET": "EQUIPPED",
	"AUSRÜSTEN": "EQUIP",
	"AUSRUESTEN": "EQUIP",
	"ANGEBOT DES TAGES": "DEAL OF THE DAY",
	"AUSVERKAUFT": "SOLD OUT",
	"ZU WENIG MÜNZEN": "NOT ENOUGH COINS",
	"ZU WENIG MUENZEN": "NOT ENOUGH COINS",
	"MAX. 2 VERSICHERUNGEN": "MAX. 2 EXTRA LIVES",
	"MAX. 5 HERZEN GEKAUFT": "MAX. 5 HEARTS BOUGHT",
	"MÜNZEN": "COINS",
	"MÜNZEN:": "COINS:",
	# --- Menue / Modus / Schwierigkeit ---
	"MODUS: RUNDEN": "MODE: ROUNDS",
	"MODUS: WELLEN + SHOP": "MODE: WAVES + SHOP",
	"GRAD: LEICHT": "DIFFICULTY: EASY",
	"GRAD: NORMAL": "DIFFICULTY: NORMAL",
	"GRAD: HART": "DIFFICULTY: HARD",
	"GRAD: %s": "DIFFICULTY: %s",
	"GRAD: —": "DIFFICULTY: —",
	"HART": "HARD",
	"RUNDEN": "ROUNDS",
	"WELLEN + SHOP": "WAVES + SHOP",
	"WELLE >>": "WAVE >>",
	# --- Themen-Banner (RUNDEN-Modus) ---
	"PANZER-RUNDE": "ARMOR ROUND",
	"SPRINT-RUNDE": "SPRINT ROUND",
	"SCHWARM-RUNDE": "SWARM ROUND",
	"ELITE-RUNDE": "ELITE ROUND",
	"MINI-BOSS!": "MINI BOSS!",
	"BIOM-BOSS!": "BIOM BOSS!",
	# --- Waffen-Stats ---
	"SCHADEN": "DAMAGE",
	"MAGAZIN": "MAGAZINE",
	"NACHLADEN": "RELOAD",
	# --- dynamische Vorlagen (werden ueber Loc.fmt gesetzt) ---
	"MÜNZEN: %d": "COINS: %d",
	"WELLE %d GESCHAFFT   ·   Shop %ds": "WAVE %d CLEARED   ·   Shop %ds",
	"WELLE %d   ·   %d Monster uebrig": "WAVE %d   ·   %d monsters left",
	"NÄCHSTE RUNDE %d: %s": "NEXT ROUND %d: %s",
	"WELLE %d BESIEGT": "WAVE %d CLEARED",
	"WELLE %d": "WAVE %d",
	"%s-RUNDE": "%s ROUND",
	"ab %d Münzen": "from %d coins",
	"%d Münzen": "%d coins",
	"ZURÜCK INS SPIEL": "BACK TO GAME",
	"ZURUECK INS SPIEL": "BACK TO GAME",
	"WAFFEN": "WEAPONS",
	"LEBEN": "LIVES",
	"TRAENKE": "POTIONS",
	"COMBO x%d  (%.2fx Punkte)": "COMBO x%d  (%.2fx points)",
	"FARBE: %s   HUT: %s   SKIN: %s": "COLOR: %s   HAT: %s   SKIN: %s",
	"HELD: %s": "HERO: %s",
	"SKIN: ": "SKIN: ",
	"FARBE: ": "COLOR: ",
	"HUT: ": "HAT: ",
	"   ·   als Nächstes: ": "   ·   up next: ",
	"TRANK (Q)": "POTION (Q)",
	"BOMBE (E)": "BOMB (E)",
	"PARTNER (WLAN)": "PARTNER (LAN)",
	"Schild": "shield",
	"P2": "P2",
	"II": "II",
	"COMIC SHOOTER": "COMIC SHOOTER",
	"%d Münzen  ·  noch %d/%d": "%d coins  ·  left %d/%d",
	"%d Münzen  ·  gekauft %d/%d": "%d coins  ·  bought %d/%d",
	"noch %d/%d": "left %d/%d",
	"gekauft %d/%d": "bought %d/%d",
	"ANGEBOT DES TAGES: %s  ·  %d Münzen (-25 %%)  ·  antippen":
		"DEAL OF THE DAY: %s  ·  %d coins (-25%%)  ·  tap",
	"ANGEBOT DES TAGES: %s  ·  AUSVERKAUFT": "DEAL OF THE DAY: %s  ·  SOLD OUT",
	"Preis: %d Münzen   ·   dein Guthaben: %d": "Price: %d coins   ·   your balance: %d",
	"%s  Schaden %2d  ·  %3d RPM  ·  Magazin %2d  ·  %s":
		"%s  Damage %2d  ·  %3d RPM  ·  Magazine %2d  ·  %s",
	"SCHADEN  %d": "DAMAGE  %d",
	"MAGAZIN  %d   NACHLADEN  %.1fs": "MAGAZINE  %d   RELOAD  %.1fs",
	# --- v1.48 (D1): INFO-Seite ---
	"DAS ZIEL": "THE GOAL",
	"DIE MODI": "THE MODES",
	"DIE WAEHRUNGEN": "CURRENCIES",
	"SKINS, FARBEN UND HUETE": "SKINS, COLORS AND HATS",
	"KARTEN UND JAHRESZEITEN": "MAPS AND SEASONS",
	"STEUERUNG": "CONTROLS",
	"SPEICHERN": "SAVING",
	"Ein Run ist ein einzelner Versuch: Du laeufst durch eine zufaellige Karte, schiesst Monster, oeffnest Kisten und wirst alle 120 Sekunden von einem Boss besucht. Ziel ist so weit zu kommen wie moeglich - Punkte, Gold und Fortschritt bleiben nach dem Run erhalten.":
		"A run is a single attempt: you cross a random map, shoot monsters, open chests and a boss visits you every 120 seconds. The goal is to get as far as you can - score, gold and progress carry over after the run.",
	"ENDLOS: Wellen kommen ohne Ende, jedes Level bringt drei Karten zur Auswahl (Schaden, Tempo, Herzen, Schild). WELLEN: 30 Sekunden Shop nach jeder Welle, Gold statt Karten, Upgrades nur im Shop. RUNDEN: feste Rundenzahl, Boss am Ende, kein Level-Up. BOSS-RUSH und weitere Varianten laufen als CHALLENGE im Runden-Modus. ZU ZWEIT: ein Geraet hostet, das andere verbindet sich per WLAN - eine gemeinsame Welt.":
		"ENDLESS: waves keep coming, every level offers three cards (damage, speed, hearts, shield). WAVES: a 30 second shop after each wave, gold instead of cards, upgrades only in the shop. ROUNDS: a fixed number of rounds, a boss at the end, no level-ups. BOSS RUSH and other variants run as a CHALLENGE in rounds mode. CO-OP: one device hosts, the other joins over WLAN - one shared world.",
	"GOLD verdienst du im Run (Muenzen, Kills, Kisten) und gibst es im Shop fuer Kisten und Extras aus. DIAMANTEN sind selten: sie kommen aus Challenges, Kisten-Trostpreisen und dem Gluecksrad und bezahlen die grossen Kisten.":
		"You earn GOLD during a run (coins, kills, chests) and spend it in the shop on chests and extras. GEMS are rare: they come from challenges, chest consolation prizes and the wheel of fortune, and they pay for the big chests.",
	"Skins, Farben und Huete aendern nur das Aussehen, nie die Werte. Du bekommst sie aus Kisten, dem Gluecksrad und als Challenge-Belohnung. Ausgeruestet wird auf der Charakter-Seite; die Sammlung zeigt alles mit Seltenheitsfarbe und Schloss.":
		"Skins, colors and hats change looks only, never stats. You get them from chests, the wheel of fortune and as challenge rewards. Equip them on the character page; the collection shows everything with rarity color and padlock.",
	"Jeder Planet hat eigene Monster, Boeden und Tempowerte: Erde, Mars (Drift), Dschungel (dichte Vegetation), Elektro-Welt. Die Jahreszeit (Fruehling, Sommer, Herbst, Winter) aendert Optik und Gegnerwerte, nicht das Kartengrund-Layout. Auf der Karten-Seite waehlst du Planet, Jahreszeit und FEST oder WECHSELND.":
		"Each planet has its own monsters, ground and speed values: Earth, Mars (drift), jungle (dense vegetation), electric world. The season (spring, summer, autumn, winter) changes looks and enemy stats, not the map layout. On the maps page you pick planet, season and FIXED or CHANGING.",
	"Eine Challenge ist ein Run mit einer Einschraenkung: nur eine Waffe, keine Heilung, kein Schild, ein Zeitlimit oder kein einziger Treffer. Drei Stufen (LEICHT, NORMAL, HART) mit je eigener Rundenzahl und Diamantenbelohnung. Die Einschraenkung ist der Wettkampf - reine Zaehlaufgaben gibt es nicht mehr.":
		"A challenge is a run with a restriction: one weapon only, no healing, no shield, a time limit or not a single hit. Three tiers (EASY, NORMAL, HARD) with their own round count and gem reward. The restriction is the competition - plain kill counters are gone.",
	"STANDARD, SILBER und PREMIUM unterscheiden sich in Preis und Seltenheits-Chancen. Im Run erscheinen Kisten auf der Karte: drei Sekunden daneben stehen bleiben, dann oeffnen. Drin sind Waffen, Herzen, Schild, mehr maximales Leben, Frost oder Schnellfeuer.":
		"STANDARD, SILVER and PREMIUM differ in price and rarity odds. Chests appear on the map during a run: stand next to one for three seconds to open it. Inside: weapons, hearts, shield, extra max health, frost or rapid fire.",
	"Links der Joystick fuer die Bewegung, rechts der Schuss-Knopf (halten = Dauerfeuer). Trank und Bombe liegen als Knoepfe daneben, Pause oben rechts. Am Rechner: WASD oder Pfeiltasten, Leertaste schiesst, 1-5 wechseln die Waffe, ESC oder P pausiert.":
		"Left joystick moves, right fire button shoots (hold for autofire). Potion and bomb sit next to it, pause in the top right. On desktop: WASD or arrow keys, space shoots, 1-5 switch weapons, ESC or P pauses.",
	"Profil, Gold, Diamanten, Freischaltungen und Challenge-Fortschritt liegen lokal auf dem Geraet und werden nach jedem Run, Kauf und Abschluss gesichert. Es gibt kein Konto und keine Cloud - eine Neuinstallation setzt den Fortschritt zurueck.":
		"Profile, gold, gems, unlocks and challenge progress live on the device and are saved after every run, purchase and completion. There is no account and no cloud - reinstalling resets your progress.",
}


func set_lang(code: String) -> void:
	lang = "en" if code == "en" else "de"
	print("[LOC][SET] sprache=%s" % lang)


# Praefixe: Texte mit Zahlen/Werten im Rest. Der Rest wird rekursiv uebersetzt.
const SUFFIX_RULES := [
	[" 💎 ÖFFNEN", " 💎 OPEN"],
	[" GOLD", " GOLD"],
	[" GOLD NÖTIG)", " GOLD NEEDED)"],
	[" %", " %"],
	[" Farben", " colors"],
	[" Hüte", " hats"],
	[" Skins", " skins"],
	[" Münzen", " coins"],
	[" uebrig", " left"],
]

const PREFIX_RULES := [
	# v1.41 (F5): dynamische Zeilen aus v1.40/v1.41 zuerst (laengste Praefixe)
	["SCHADEN  ", "DAMAGE  "],
	["RPM  ", "RPM  "],
	["LVL ", "LVL "],
	["TRANK x", "POTION x"],
	["BOMBE x", "BOMB x"],
	["BESTER SCORE", "BEST SCORE"],
	["FPS-ANZEIGE", "FPS DISPLAY"],
	["SKINS ", "SKINS "],
	["FARBEN ", "COLORS "],
	["HUETE ", "HATS "],
	["MAGAZIN  ", "MAGAZINE  "],
	["NACHLADEN  ", "RELOAD  "],
	["STUFE: ", "TIER: "],
	["CHALLENGE · ", "CHALLENGE · "],
	["Chancen ", "Odds "],
	["Best Score: ", "Best score: "],
	["Score: ", "Score: "],
	["Best: ", "Best: "],
	["GOLD: ", "GOLD: "],
	["Aktiv: ", "Active: "],
	["Welle ", "Wave "],
	["Aktuell: ", "Current: "],
	["MODUS: ", "MODE: "],
	["GRAD: ", "DIFFICULTY: "],
	["SPIELER ", "PLAYER "],
	["MÜNZEN: ", "COINS: "],
	["WELLE ", "WAVE "],
	["NÄCHSTE RUNDE ", "NEXT ROUND "],
	["ab ", "from "],
	["gekauft ", "bought "],
	["noch ", "left "],
	["Preis: ", "Price: "],
	["Rueckkehr zur Startseite in ", "Back to menu in "],
]


func _is_noise(text: String) -> bool:
	# Reine Zahlen/Symbole brauchen keine Uebersetzung
	var t2: String = text.strip_edges()
	if t2 == "":
		return true
	for i in range(t2.length()):
		var c: String = t2[i]
		if c >= "A" and c <= "Z":
			return false
		if c >= "a" and c <= "z":
			return false
		if c in ["Ä", "Ö", "Ü", "ä", "ö", "ü", "ß"]:
			return false
	return true


func t(text: String) -> String:
	if lang == "de":
		return text
	var hit = DE_EN.get(text, null)
	if hit != null:
		return str(hit)
	for rule in PREFIX_RULES:
		var pre: String = str(rule[0])
		if text.begins_with(pre):
			var rest: String = text.substr(pre.length())
			var rest_en: String = rest
			if DE_EN.has(rest):
				rest_en = str(DE_EN[rest])
			return str(rule[1]) + rest_en
	# Suffixe: Preis-/Zaehlzeilen enden auf einer Einheit
	for srule in SUFFIX_RULES:
		var suf: String = str(srule[0])
		if text.ends_with(suf):
			var head: String = text.substr(0, text.length() - suf.length())
			return head + str(srule[1])
	return text


func has_key(text: String) -> bool:
	# Kennt das Woerterbuch diesen Text (auch wenn EN == DE ist)?
	if DE_EN.has(text):
		return true
	for rule in PREFIX_RULES:
		if text.begins_with(str(rule[0])):
			return true
	for srule in SUFFIX_RULES:
		if text.ends_with(str(srule[0])):
			return true
	return false


func fmt(key: String, args: Array = []) -> String:
	# v1.41 (F5): zusammengesetzte Saetze ueber eine Vorlage bauen.
	# Die Vorlage steht im Woerterbuch ("MÜNZEN: %d"), die Zahlen kommen
	# erst danach hinein - so bleibt der Satz in beiden Sprachen korrekt.
	var tmpl: String = key
	if lang == "en":
		var hit = DE_EN.get(key, null)
		if hit != null:
			tmpl = str(hit)
	if args.is_empty():
		return tmpl
	return tmpl % args


func is_fmt(text: String) -> bool:
	# Kennt das Woerterbuch die Vorlage (fuer [LOC][CHECK])?
	return DE_EN.has(text)


func t_lenient(text: String, key: String) -> String:
	# Fuer Texte mit Zahlen: ersetzt nur den festen Teil
	if lang == "de":
		return text
	var hit = DE_EN.get(key, null)
	if hit == null:
		return text
	return str(hit)


func missing_count() -> int:
	return _missing.size()


func dump_missing() -> void:
	# Alle fehlenden Texte als Liste ins Log (Grundlage fuers Woerterbuch)
	var keys: Array = _missing.keys()
	keys.sort()
	for k in keys:
		print("[LOC][MISS] %s" % str(k))
	print("[LOC][MISS] gesamt=%d" % keys.size())


func _translate_node(n: Node, stats: Dictionary) -> void:
	if n is Label:
		var lbl := n as Label
		# v1.41 (F5): Labels, die per Loc.fmt gebaut werden, uebersetzen sich
		# selbst - sie zaehlen nicht als Luecke (sonst falsches "fehlt").
		if lbl.has_meta("loc_fmt"):
			return
		stats["labels"] = int(stats.get("labels", 0)) + 1
		var src: String = lbl.text
		if lang == "de":
			# Rueckweg: deutschen Originaltext wiederherstellen
			if lbl.has_meta("loc_de") and src != "":
				var back: String = str(lbl.get_meta("loc_de"))
				if lbl.text != back:
					lbl.text = back
					stats["done"] = int(stats.get("done", 0)) + 1
			return
		if src == "":
			r_labels(n, stats)
			return
		if not lbl.has_meta("loc_de"):
			lbl.set_meta("loc_de", src)
		if not lbl.has_meta("loc_en_done"):
			var out: String = t(src)
			if out != src:
				lbl.text = out
				stats["done"] = int(stats.get("done", 0)) + 1
			else:
				if not _is_noise(src) and not has_key(src):
					stats["missing"] = int(stats.get("missing", 0)) + 1
					if not _missing.has(src):
						_missing[src] = true
						print("[LOC][T] fehlt=\"%s\"" % src)
			lbl.set_meta("loc_en_done", true)
	elif n is Button:
		var b := n as Button
		if b.has_meta("loc_fmt"):
			return
		stats["labels"] = int(stats.get("labels", 0)) + 1
		var src2: String = b.text
		if lang == "de":
			if b.has_meta("loc_de") and src2 != "":
				var back2: String = str(b.get_meta("loc_de"))
				if b.text != back2:
					b.text = back2
					stats["done"] = int(stats.get("done", 0)) + 1
			if b.has_meta("loc_de_tip"):
				b.tooltip_text = str(b.get_meta("loc_de_tip"))
			return
		if src2 != "":
			if not b.has_meta("loc_de"):
				b.set_meta("loc_de", src2)
			if not b.has_meta("loc_en_done"):
				var out2: String = t(src2)
				if out2 != src2:
					b.text = out2
					stats["done"] = int(stats.get("done", 0)) + 1
				else:
					if not _is_noise(src2) and not has_key(src2):
						stats["missing"] = int(stats.get("missing", 0)) + 1
						if not _missing.has(src2):
							_missing[src2] = true
							print("[LOC][T] fehlt=\"%s\"" % src2)
				b.set_meta("loc_en_done", true)
		# Tooltips mituebersetzen
		if b.tooltip_text != "":
			if not b.has_meta("loc_de_tip"):
				b.set_meta("loc_de_tip", b.tooltip_text)
			var tip_src: String = str(b.get_meta("loc_de_tip"))
			var tip: String = t(tip_src)
			if tip != b.tooltip_text:
				b.tooltip_text = tip
				stats["done"] = int(stats.get("done", 0)) + 1
	elif n is LineEdit:
		var le := n as LineEdit
		if lang == "de":
			if le.has_meta("loc_de_ph"):
				le.placeholder_text = str(le.get_meta("loc_de_ph"))
			return
		if le.placeholder_text != "":
			if not le.has_meta("loc_de_ph"):
				le.set_meta("loc_de_ph", le.placeholder_text)
			var ph: String = t(str(le.get_meta("loc_de_ph")))
			if ph != le.placeholder_text:
				le.placeholder_text = ph
				stats["done"] = int(stats.get("done", 0)) + 1
	for c in n.get_children():
		_translate_node(c, stats)


func r_labels(_n: Node, _stats: Dictionary) -> void:
	return


func check_tree(root: Node, flaeche: String) -> int:
	# v1.41 (F5): Belegzeile - wie viele Knoten, wie viele fehlende Texte?
	# Zaehlt nur Labels/Buttons, die NICHT per Loc.fmt gebaut werden.
	var st := { "knoten": 0, "fehlt": [] }
	_check_walk(root, st)
	var fehlend: int = (st["fehlt"] as Array).size()
	print("[LOC][CHECK] flaeche=%s knoten=%d fehlt=%d" % [flaeche, int(st["knoten"]), fehlend])
	# Nur die ersten 8 offenen Texte nennen - der Rest steht in [LOC][MISS]
	var lst: Array = st["fehlt"]
	for i in range(mini(lst.size(), 8)):
		print("[LOC][CHECK] fehlt_text=\"%s\"" % str(lst[i]))
	return fehlend


func _check_walk(n: Node, st: Dictionary) -> void:
	if n == null:
		return
	var txt: String = ""
	var zaehlt: bool = false
	if n is Label:
		var lb := n as Label
		if not lb.has_meta("loc_fmt"):
			# Nach apply_tree steht in .text schon Englisch - dann zaehlt der
			# deutsche Originaltext aus loc_de als Quelle.
			txt = str(lb.get_meta("loc_de", lb.text))
			zaehlt = true
	elif n is Button:
		var bt := n as Button
		if not bt.has_meta("loc_fmt"):
			txt = str(bt.get_meta("loc_de", bt.text))
			zaehlt = true
	if zaehlt:
		st["knoten"] = int(st["knoten"]) + 1
		if txt != "" and not _is_noise(txt) and not has_key(txt):
			(st["fehlt"] as Array).append(txt)
	for c in n.get_children():
		_check_walk(c, st)


func apply_tree(root: Node) -> Dictionary:
	var stats := { "labels": 0, "done": 0, "missing": 0 }
	if root == null:
		return stats
	_translate_node(root, stats)
	stat_labels = int(stats["labels"])
	if int(stats["done"]) > 0:
		stat_done += int(stats["done"])
	if int(stats["missing"]) > 0:
		stat_missing += int(stats["missing"])
	return stats
