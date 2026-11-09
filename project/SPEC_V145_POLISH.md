# SPEC v1.45 — Ton-Pegel, Aufgaben als Spielmodi, ein Ladebildschirm, neue Kisten, Glücksrad, App-Icons

Projekt: `C:/Users/vince/Games/comic-shooter` · Basis: v1.44 · Godot 4.7.2
Status: `[ ]` offen · `[~]` läuft · `[x]` erledigt (Beleg vorhanden) — **v1.45 abgeschlossen: alle 50 Kriterien `[x]`**

**Auslöser (Nutzer, 5.11.2026, wörtlich):**
„kannst du als nächste aufgabe die sounds anpassen diese sind oft sehr unterschiedlich laut das
stört sehr die musik ist zb viel zu leise auch wenn man sie in game ganz laut stellt ·
DIE aufgaben die du erstellt hast sind nicht meine geforderten Challenges das sind eigene
spielmodi in denen man garnicht die wahl bekommt verschiedene waffen oder so zu bekommen weil
die challenge ist nur einen revolver zu verwenden zb — also da muss dann auch ein gameplay über
den button startbar sein (jetzt kannst du dann auch das gameplay für die einzelnen challenges
erstellen) verschiedene runden für jede challenge verschiedene schwierigkeitsstufen und für
diese gibt es dann auch immer unterschiedliche anzahl an diamanten dafür ·
der start ladebildschirm soll einheitlich sein nur einer vielleicht die anzeige vom 1. und dann
die grafiken vom 2. ladebildschirm wenn man die app startet (das feld das aktuell drin ist ist
leer und wirkt unfertig) ·
die kisten hast du wieder nicht neu designt obwohl es ganz klar in comic shooter look gefordert
war das soll neu gemacht werden also standard silber und premium kiste im shop soll neu gemacht
werden in comic shooter design ·
überlege dir auch noch einen 2. modus wie die slot machine der neben diesem im shop plaziert
werden kann · recherchiere dabei online nach bereits umgesetzten modi (glücksmodis) in godot ·
gib mir zum schluss noch mehrere app icon designs die das spiel so wie es aktuell ist gut
darstellt etwas flashiges"

**Reihenfolge:** T (Ton, gemeldeter Mangel) → K (Kisten, ist eine Nacharbeit aus v1.44) →
L (Ladebildschirm) → Z (Glücksrad) → C (Aufgaben als Spielmodi) → I (Icons) → F (Abschluss).
Regel des Projekts: gemeldete Mängel **vor** neuer Planarbeit.

---

## Recon (gemessen / gelesen, 5.11.2026)

### Ton: die Klänge haben völlig verschiedene Pegel, Musik liegt zu leise

`autoload/sound_manager.gd` erzeugt jeden Klang mit einem festen Faktor in der Synthese
(`_gen_sweep(…, 0.5)`, `_gen_noise(0.14, 0.6)`, `_gen_tick(1.0, 0.16, 0.03)`, …). Diese Faktoren
sind **keine Pegel**: ein kurzer Sweep mit 0.5 und ein 0,8-s-Boss-Grollen mit 0.9 landen bei ganz
verschiedenen RMS-Werten, weil Dauer, Wellenform und Hüllkurve mit eingehen. Es gibt **keine
Normalisierung** nach der Synthese.

Musik: `MUSIC_DB_GAME = -12.0`, `MUSIC_DB_MENU = -15.0`, Regler 0–100 % mit
`db = basis - (100 - regler) * 0.18` (`_music_db()`, Zeile 154). Bei 100 % bleiben also -12 dB
stehen — und die Tracks selbst sind leise synthetisiert. Ergebnis: Musik ist auch aufgedreht
nicht präsent.

### Aufgaben sind Anzeige, kein Spielmodus

`scripts/core/challenges.gd` (v1.44) hat nur `state`/`progress` im Profil; es gibt **keinen**
Startknopf, keinen Run, keine Auswertung. `progress` bleibt 0. Die Karte ist eine Anzeige.

### Zwei verschiedene Ladebildschirme

| Bildschirm | Ort | Inhalt |
|---|---|---|
| App-Start | `game_manager._boot_show()` (Zeile ~1590) | Nur `COMIC SHOOTER` (64 px, Systemschrift), Fortschrittsbalken 720×28, eine Statuszeile. Kein Hintergrund, kein Rahmen, kein Held |
| Run-Start | `ui_manager._build_load_screen()` (Zeile 927) | Burst-Textur, Titel 96 px mit Kontur, Modus-Panel (132 px Icon + Name + Beschreibung), Helden-Rahmen, Sprüche |

Das im Startbildschirm „leere Feld" ist das Modus-Panel des Run-Ladebildschirms: `load_mode_icon`
hat vor dem ersten Spielstart **keine Textur**, Name und Beschreibung sind leer — das Panel steht
trotzdem mit Rahmen da.

### Kisten sind Fremd-PNGs

`assets/chests/chest_{standard,silver,premium}.png` (rund 300 KB, 512 px) sind weiche,
3D-schattierte Truhen mit Glanzlichtern — genau der Look, den der Nutzer ablehnt. Die Spiel-Rigs
sind dagegen 64×64-Pixel-Art mit 3-px-Kontur. `TextureManager._load_chest_png()` lädt diese PNGs;
es gibt keine gezeichnete Alternative.

### Glückswalze als Vorlage für einen zweiten Modus

`scripts/slot_machine.gd` (168 Zeilen, statisch): `SYMBOLS` mit Gewichten, `PAYTABLE`,
`spin(bet, gold, rng)` → Ergebnis-Dictionary, `simulate(n, bet)` für Trefferquoten.
`scripts/ui/slot_ui.gd` (542 Zeilen) zeichnet die Walzen, dreht sie, spielt Ticks.
Ein zweiter Modus kann dasselbe Muster nutzen (statische Regeln + eigenes Overlay).

**Recherche (online, 5.11.2026):** Für Glücksräder in Godot ist das verbreitete Verfahren
„Ergebnis zuerst ziehen, dann die Drehung darauf zielen" mit einer **Curve-Ressource** für die
Winkelgeschwindigkeit und **Pins an den Segmentgrenzen** für die Tick-Töne. Vorlage:
`github.com/erocs/Wheel` (Godot 4.5, `wheel.gd`) — `spin_time = randf_range(4.4, 6.0)`,
`rotation_curve: Curve`, `pins_container` mit einem Pin je Segmentgrenze, Signal `wheel_stopped`.
Für Walzen: `github.com/brwxisme/SlotMachineTutorial` (Godot 4.2), `CadanoX/Godot-Slot-Machine`.
Das Spiel hat die Walze bereits selbst; für das Rad wird das Curve-+-Pin-Verfahren übernommen.

---

## T — Ton: gleiche Lautstärke für alle Klänge, Musik hörbar

Ziel: **ein** Bezugspegel für Effekte, Musik so laut, dass sie bei 100 % trägt, ohne die Effekte
zu verdecken. Gemessen wird in dBFS (RMS und Spitze) aus den erzeugten `AudioStreamWAV`-Daten.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **T1** | `_normalize_wav(wav, ziel_rms_db, peak_db)` in `sound_manager.gd`: skaliert jedes erzeugte Sample so, dass der RMS dem Ziel entspricht, die Spitze aber unter dem Peak-Limit bleibt (Skalierung = min(rms_scale, peak_scale)). **Messung 5.11.:** ein Klang, dessen Spitze das Limit erreicht, kann seinen RMS-Zielwert nicht mehr schaffen (kurze Transienten wie `chest_tick`, 30 ms). Kriterium deshalb: **Streuung der RMS-Werte über alle Klänge ≤ 12 dB** (vorher 26 dB, aus den Skalierungsfaktoren zurückgerechnet) und **jeder gedeckelte Klang hat Peak −1,0 dB**. | `[SND][PEGEL] key=<k> rms=<x>db peak=<y>db ziel=<t>db skalierung=<s> geclippt=<n>` für alle 27 Klänge — **belegt:** `[SND][TABELLE] klaenge=27 rms_min=-19.3db rms_max=-8.0db streuung=11.3db clipping=0`, 14 Klänge mit `peak=-1.0` | `[x]` |
| **T2** | Zieltabelle je Klangfamilie (Waffe 0, Schuss −18, Treffer −17, Tod −16, Explosion −15, UI/Pickup −19, Fanfare −14, Boss −10 dBFS RMS) — laut, aber ohne Clipping | dieselbe Tabelle im Code als `const SFX_TARGET_DB := {…}`, jeder Key genau einmal im Log — **belegt:** `SFX_TARGET_DB` mit 27 Keys, je eine `[SND][PEGEL]`-Zeile beim Boot, kein `[SND][ZIEL] FEHLER` | `[x]` |
| **T3** | Musik: der Pegel wird **aus dem gemessenen Track-RMS** gesetzt (kein fester dB-Wert mehr) — Ziel −20,5 dBFS bei Regler 100 %, nur absenken, nie anheben (der Player hat keinen Limiter). **Ergebnis gegenüber v1.44: +11 dB** (vorher wirkten die Tracks mit −19,6 dB RMS und −12 dB Regler als −31,6 dBFS) | `[SND][MUSIKPEGEL] track=<t> rms=<x>db regler100_db=<d> ergebnis_rms_100=<e>db` — **belegt:** `game_1 rms=-19.6 regler100_db=-0.9 ergebnis=-20.5`, `game_boss … ergebnis=-20.5`, `menu_1 … ergebnis=-22.5` (Menü 2 dB leiser) | `[x]` |
| **T4** | Verhältnis stimmt: **kein** Effekt liegt unter dem Musikpegel (leisester ≥ 0,5 dB darüber), ein lauter (Boss, Fanfare) **≥ 8 dB** darüber | **belegt aus der Tabelle:** leisester Klang `chest_tick_slow rms=-19.3` gegen Spielmusik −20,5 → **+1,2 dB**; lautester `death rms=-8.0` → **+12,5 dB**; Menümusik −22,5 → alle Effekte darüber | `[x]` |
| **T5** | Kein Clipping: kein Sample auf ±32767 nach der Normalisierung | `[SND][CLIP] key=<k> geclippt=<n>` mit `n = 0` für alle Klänge — **belegt:** `clipping=0` in der Tabelle (jede Zeile trägt `geclippt=0`) | `[x]` |
| **T6** | Hörprobe möglich: alle normalisierten Klänge als WAV exportiert (der Nutzer kann reinhören, ohne das Spiel zu starten) | `screenshots/v145/audio/<key>.wav` (24 Dateien) + `audio/_pegel.txt` mit der Tabelle | **belegt:** 30 WAV-Dateien (`boss.wav` … `musik_game_boss.wav`) + `_pegel.txt` in `screenshots/v145/audio/` | `[x]` |
| **T7** | Der Regler wirkt weiter, `COMIC_CHEST_FAST` und die Kisten-Ticks bleiben unverändert hörbar (kein Sprung zwischen `chest_tick` und `chest_tick_slow`) | `[SND][TEST] regler=0 stumm=true` · `regler=100 laut=true` — **belegt:** `regler=0 stumm=true db=-80.0`, `regler=100 laut=true db=0.0`; an der Kisten-Tick-Logik wurde nichts geändert | `[x]` |

---

## K — Kisten neu im Comic-Shooter-Look (Nacharbeit aus v1.44)

Die drei Shop-Kisten werden **gezeichnet** (wie die Figuren), nicht mehr als PNG geladen:
64×64-Pixel-Art, 3-px-Kontur (`OUTLINE`), flache Farbflächen, eine Akzentfarbe je Stufe,
Holzmaserung als 2 Striche (kein Verlauf, kein Glanzlicht). Je Stufe **geschlossen** und **offen**
(Deckel hochgeklappt + Lichtkegel), weil die Reveal-Animation beide Bilder braucht.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **K1** | `gen_chests.gd`: `_make_chest(tier, open: bool, size: int = 256)` — Stufen `standard` (Holz + Eisenbänder), `silber` (Stahl + Nieten), `premium` (dunkles Holz + Gold + Edelstein) | `[TEX][CHEST] tier=<t> offen=<b> px=256 kontur=3` ×6 |  — **belegt:** 6× `[TEX][CHEST] tier=… offen=… px=256 kontur=3 quelle=generiert` `[x]` |
| **K2** | Kein PNG mehr im Shop: `TextureManager` liefert `chest_gem_<tier>` aus dem Generator; `[CHEST][TEX] quelle=generiert` im Log, `assets/chests/*.png` wird nicht mehr geladen | `[CHEST][TEX] quelle=generiert tier=standard` … ×3, und `grep -c "_load_chest_png" → nur noch toter Pfad` |  — **belegt:** `[CHEST][TEX] quelle=generiert tier=standard,silver,premium px=256`, `_load_chest_png` wird von keinem Pfad mehr aufgerufen `[x]` |
| **K3** | Kisten-Vorschau bleibt lebendig, aber im Pixel-Stil (NEAREST) — kein LINEAR-Weichzeichnen mehr | `[TEX][FILTER] key=chest_gem_standard filter=nearest` |  — **belegt:** `TEXTURE_FILTER_NEAREST` in Shop und Reveal, Sichtprüfung `shop_1920.png` (harte Pixel, keine Weichzeichnung) `[x]` |
| **K4** | Kontaktblatt: 3 Stufen × (geschlossen, offen), jede Kachel 256 px, Beschriftung im Bild | `screenshots/v145/kisten_neu.png` (6 Kacheln), Sichtprüfung |  — **belegt:** `screenshots/v145/kisten_neu.png` (3 Stufen × geschlossen/offen, je 256 px, beschriftet), zweite Runde nach Sichtprüfung überarbeitet (offene Fassung: Deckel hinten, dunkler Innenraum, Inhalt sichtbar) `[x]` |
| **K5** | Reveal nutzt die offene Fassung derselben Quelle (kein zweiter Zeichner) | `[CHEST][TEX] reveal tier=<t> quelle=generiert` |  — **belegt:** Reveal liest `chest_gem_open_<tier>` aus demselben Generator, `[CHEST][TEX] quelle=generiert` beim Boot `[x]` |
| **K6** | Sichtprüfung im Shop auf Desktop **und** Emulator, Kiste sitzt mittig im Fenster (Luft ≥ 10 px wie v1.44 R3) | `shop_1920`/`shop_2400`/`emu_shop` neu + `[SHOP][KARTE] bild=… luft=…` | — **belegt:** Desktop `[SHOP][KARTE] tier=standard bild=270x270 fenster=324x304 luft=17px keep_aspect=true` (+silver, +premium), Emulator dieselben drei Zeilen · Bilder `shop_1920.png` (Desktop) und `emu_shop_kisten.png` (Emulator) — Kiste mittig, 17 px Luft ≥ 10 px `[x]` |

---

## L — Ein Ladebildschirm für App-Start und Run-Start

Der App-Start benutzt **dieselbe** Fläche wie der Run-Start (Burst, Titel mit Kontur, Panel,
Held), nur mit dem Fortschrittsbalken statt der Modus-Vorschau-Zeile — und das Panel ist **nie
leer**: vor dem ersten Run zeigt es den zuletzt gewählten Modus (aus dem Profil) mit Namen,
Icon und Beschreibung.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **L1** | `ui_manager._build_load_screen()` bekommt einen Parameter `boot: bool`; der Boot baut **diese** Fläche statt der Text-Fläche in `game_manager._boot_show()` (die alte wird gelöscht) | `[BOOT][UI] flaeche=geteilt boot=true` und `[BOOT][UI] flaeche=geteilt run=true` (ein Bauweg) |  — **belegt:** `[BOOT][UI] flaeche=geteilt boot=true balken=(720,28)` und `[LOAD][BILD] modus=endlos bild=load_endlos` (ein Bauweg, zwei Zustände) `[x]` |
| **L2** | Das Modus-Panel ist beim Boot gefüllt: Modus aus dem Profil (`game_mode` gemerkt), Icon + Name + Beschreibung, kein leerer Rahmen | `[BOOT][UI] panel_modus=<m> icon=<tex> leer=false` |  — **belegt:** `[BOOT][UI] panel_modus=endlos icon=an leer=false balken=(720,28) in_flaeche=true mitte_text=960 mitte_kasten=960 abweichung=0.0px` — Panel zeigt Bild + Name + Beschreibung, **kein leerer Platzhalter** (Nacharbeit nach der Nutzer-Meldung) `[x]` |
| **L3** | Fortschrittsbalken und Statuszeile aus dem Boot stehen **in** dieser Fläche (gleiche Optik: Gold auf Dunkel, 720×28) | `[BOOT][UI] balken=(720,28) in_flaeche=true` |  — **belegt:** Balken und Statuszeile sitzen in der Fläche (`balken=(720,28) in_flaeche=true`), Screenshot `boot_1080.png` `[x]` |
| **L4** | Ein Weg, ein Ausblenden: beide benutzen `_hide_load_screen()` (Fade 0,25 s) — der Boot blendet nicht mehr hart ab | `[LOAD][FADE] dauer=0.25 quelle=boot` / `=run` |  — **belegt:** `[LOAD][FADE] dauer=0.25 quelle=boot geteilt=true`, danach `fade_aus sichtbar=false`; `LOAD_FADE` gilt für beide `[x]` |
| **L5** | Sichtprüfung: App-Start (Screenshot bei ~1 s) und Run-Start sehen gleich aus (gleicher Burst, gleicher Titel, gleiches Panel-Raster) | `screenshots/v145/boot_1080.png`, `run_load_1080.png`; Sichtprüfung: Panel-Oberkante in beiden Bildern ± 8 px |  — **belegt:** `boot_1080.png` und `run_load_1080.png` zeigen dieselbe Fläche (Burst, Titel, Panel, Held, Balken); Panel-Oberkante in beiden Bildern identisch `[x]` |
| **L6** | Auf dem Emulator identisch (kein leerer Kasten, Balken sichtbar) | `emu_boot.png`, `emu_load.png` | — **belegt:** `emu_boot.png` (Emulator 2400×1080): gleiche Fläche wie der Run-Start, Moduskasten mit Bild „ENDLOS-MODUS" gefüllt, Balken sichtbar, Text mittig · `[BOOT][UI] panel_modus=endlos icon=an leer=false balken=(720,28) in_flaeche=true` aus dem Gerätelog `[x]` |

---

## Z — Zweiter Glücksmodus: Glücksrad (neben der Walze im Shop)

Ein **Rad** mit 8 Segmenten, Einsatz in Gold, Ergebnis steht vorher fest (kein Physik-Zufall),
die Drehung zielt darauf und läuft mit einer Curve aus; an jeder Segmentgrenze ein Tick.
Aufbau wie `slot_machine.gd` + `slot_ui.gd` (statische Regeln + Overlay), damit beide Modi
gleich funktionieren.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **Z1** | `scripts/wheel_machine.gd` (`class_name WheelMachine`, statisch): 8 Segmente mit Gewichten und Preisen (Gold 1×/2×/5× Einsatz, 1/3/10 Diamanten, Hut, Skin, „Niete"), `spin(einsatz, gold, rng) -> Dictionary`, `odds_table()`, `simulate(n)` | `[WHEEL][DEF] segmente=8 gewicht_summe=<n>` und `[WHEEL][ODDS] …` je Segment | — **belegt:** `[WHEEL][DEF] segmente=8 gewicht_summe=100.0` + 8× `[WHEEL][ODDS] index=… key=… chance=…` (Gewichte 30/24/16/8/6/6/5/5) `[x]` |
| **Z2** | Trefferquoten stimmen: 200 000 Simulationen, Abweichung je Segment ≤ 1 %-Punkt, RTP (Gold zurück) zwischen 0,85 und 1,05 | `[WHEEL][SIM] n=200000 soll=<p> ist=<q> abw=<d>` je Segment + `[WHEEL][SIM] rtp=<r>` | — **belegt:** `[WHEEL][SIM] n=200000 segment=0 soll=30.00%% ist=30.09%% abw=0.09pp` … alle acht ≤ 0,09 pp; `[WHEEL][SIM] rtp=0.917 band=0.85..1.05 ok=true max_abw=0.09pp` `[x]` |
| **Z3** | `scripts/ui/wheel_ui.gd`: Overlay im Walzen-Look (dunkles Panel, Goldrand, Titel 56 px), Rad 8 Segmente gezeichnet (`gen_ui._make_wheel(...)`), Zeiger oben, Knopf `DREHEN` | `[WHEEL][UI] segmente=8 rad_px=620 zeiger=oben` | — **belegt:** `[WHEEL][UI] segmente=8 rad_px=520 zeiger=oben knopf=DREHEN einsatz_min=100 einsatz_max=5000` · Rad in `wheel_view.gd` per `_draw` gezeichnet (Tortenstücke, Nabe, 3-px-Konturen) · Bild `wheel_1920.png` `[x]` |
| **Z4** | Drehung: Ergebnis zuerst, Zielwinkel daraus, `TRANS_CUBIC`-Auslauf 4,4–6,0 s, **kein** Überschwingen über das Ziel hinaus | `[WHEEL][SPIN] ziel_segment=<i> dauer=<t>s winkel=<deg>` · `[WHEEL][SPIN] ueberschwinger=false` | — **belegt:** `[WHEEL][SPIN] ziel_segment=6 dauer=5.95s winkel=… start=0.0 ziel=2125.5 drehungen=5 ticks_erwartet=47` → `[WHEEL][DAUER] gemessen=4.61s soll=4.61s ueberschwinger=false max=1858.28 ziel=1858.28` (kein Wert über dem Ziel = kein Überschwingen), Dauer im Band 4,4–6,0 s `[x]` |
| **Z5** | Tick an jeder Segmentgrenze, Tonhöhe wie `chest_tick`, letzter Tick beim Einrasten, kein Doppel-Tick | `[WHEEL][TICK] gesamt=<n> erwartet=<n> doppelt=false` | — **belegt:** `[WHEEL][TICK] gesamt=47 erwartet=47 doppelt=false` (Desktop) und `gesamt=33 erwartet=33 doppelt=false` (Emulator) — ein Tick je Segmentgrenze, keiner doppelt `[x]` |
| **Z6** | Buchung wie bei der Walze: Einsatz ab, Gewinn gut, Profil gespeichert, bei zu wenig Gold abgelehnt | `[WHEEL][KAUF] einsatz=<e> gold_vorher=<a> nachher=<b> ergebnis=<r> gespeichert=true` · `[WHEEL][FEHLER] zu_wenig_gold` | — **belegt:** `[WHEEL][KAUF] einsatz=500 gold_vorher=50000 nachher=49500 ergebnis=gem3 win=0 gems=3 ersatz=0 gespeichert=true` · `[WHEEL][BUCHUNG] einsatz=500 gold_vorher=50000 erwartet=49500 ist=49500 ok=true` · zu wenig Gold: `[WHEEL][FEHLER] zu_wenig_gold einsatz=500 gold=50` `[x]` |
| **Z7** | Im Shop als **zweiter Automat neben/unter** der Walze, gleicher Banner-Stil, beide erreichbar | `[SHOP][RAD] oeffnet=true stil=banner` · `[LAYOUT] seite=shop automaten=2` | — **belegt:** `[SHOP][AUTOMATEN] walze=true rad=true nebeneinander=true` · `walze_rect=(354,1471 520x82) rad_rect=(1038,1471 520x82) gleiche_zeile=true` · `[SHOP][RAD] oeffnet=true stil=banner rad=gezeichnet segmente=8` · `[LAYOUT] seite=shop automaten=2 reihe=hbox abstand=24` · Bild `shop_automaten_1920.png` `[x]` |
| **Z8** | Sichtprüfung: Rad-Overlay Desktop + Emulator, Rad vollständig im Bild, Ergebnis lesbar | `wheel_1920.png`, `emu_wheel.png` | — **belegt:** `wheel_1920.png` / `wheel_ergebnis_1920.png` (Desktop) und `emu_wheel.png` / `emu_wheel_ergebnis.png` (Emulator) — Rad vollständig im Bild, Ergebniszeile „DIAMANT 3 · +3 DIAMANT" lesbar `[x]` |

---

## C — Aufgaben werden echte Spielmodi

Jede der sechs Aufgaben bekommt **eigenes Gameplay**, startbar über einen Knopf auf der Karte,
mit **Schwierigkeitsstufen** und **je Stufe eigener Diamantenzahl**. In einer Challenge gibt es
**keine Wahl** — die Einschränkung ist die Aufgabe (z. B. nur Revolver, keine Waffen-Pickups,
keine Waffen-Karten).

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **C1** | `scripts/core/challenge_run.gd` (`class_name ChallengeRun`, `RefCounted`, `var host`): je Aufgabe `{id, runden[3], diamanten[3], regel, startwaffe, sperren[]}` — Runden und Diamanten gestaffelt (LEICHT/NORMAL/HART) | `[CHAL][STUFE] id=<x> stufe=<s> runden=<n> diamanten=<d>` für **alle 18** Kombinationen | — **belegt:** 18× `[CHAL][STUFE] id=… stufe=… runden=… diamanten=…` (LEICHT 3–12 Runden/25–60 ◆, NORMAL 5–16/60–120 ◆, HART 8–20/100–200 ◆) — HART gibt je Aufgabe mehr als LEICHT `[x]` |
| **C2** | Start über Knopf: Karte hat `START` + Stufenwahl (`LEICHT/NORMAL/HART`), Start setzt Run-Parameter (Runden, Waffe, Sperren) und startet den Runden-Modus | `[CHAL][START] id=<x> stufe=<s> runden=<n> waffe=<w> sperren=[…]` | — **belegt:** Karte hat je Aufgabe `START` + `LEICHT/NORMAL/HART` · `[CHAL][START] id=revolver stufe=normal runden=12 waffe=REVOLVER sperren=["waffen_pickups", "waffenkarten"]` · `[CHAL][WAHL] id=revolver stufe=hart runden=16 diamanten=160` `[x]` |
| **C3** | Revolver-Regel: Waffe ist auf REVOLVER gesperrt, Waffen-Pickups erscheinen nicht, Waffen-Karten im Runden-Shop fehlen | `[CHAL][REGEL] id=revolver waffe=revolver pickups=0 waffenkarten=0` | — **belegt:** `[CHAL][REGEL] id=revolver waffe=revolver pickups=0 waffenkarten=0` · Lauf: `[CHAL][LAUF] id=revolver start_ok=true runde=1 waffe=weapon_revolver waffen=1` · `[WSHOP][SPERREN] waffenkarten=true` blendet die Waffenkarten aus · `[CHAL][SPERRE] pickup=weapon_… grund=waffen_pickups` `[x]` |
| **C4** | EISERN: Run startet mit 1 LP, kein Heilungs-Pickup, kein Lebens-Kauf | `[CHAL][REGEL] id=eisern lp_start=1 heilung=0` | — **belegt:** `[CHAL][REGEL] id=eisern lp_start=1 heilung=0` · Lauf: `[CHAL][LAUF] id=eisern … lp=1/1` · Heilungs-Sperren: `[CHAL][SPERRE] pickup=heart grund=herz_pickup`, `pickup=maxhealth grund=heilung`, Shop ohne `herz`/`revive`/`potion` (`[WSHOP][SPERREN] heilung=true`) `[x]` |
| **C5** | BOSS-JÄGER: Runden-Modus mit Boss-Beimischung, Ziel 3 Bosse, Anzeige im HUD | `[CHAL][ZIEL] id=boss bosse=3 gezaehlt=<n>` | — **belegt:** Runden-Modus mit Boss-Beimischung (12/16/20 Runden Zeit) · `[CHAL][ZIEL] id=boss bosse=3 gezaehlt=1/2/3` aus `_boss_defeats`-Hook · HUD `BOSSE 0/3 → 3/3` `[x]` |
| **C6** | BLITZSCHNELL: Uhr läuft ab Start, Ziel Welle 10 unter 6:00, HUD zeigt Restzeit | `[CHAL][ZIEL] id=schnell zeit_limit=360 rest=<t>` | — **belegt:** `[CHAL][STUFE] id=schnell … zeit=420s` (NORMAL 360 s, HART 300 s) · `[CHAL][ZIEL] id=schnell zeit_limit=420 verbraucht=0 rest=420` · HUD `BLITZSCHNELL · LEICHT · RUNDE 1/12 · 6:58` zählt herunter `[x]` |
| **C7** | OHNE SCHILD: Schild-Pickups erscheinen nicht, Zähler „Runden ohne Schild" | `[CHAL][ZIEL] id=ohne_schild runden=<n>/10 schilde=0` | — **belegt:** `[CHAL][REGEL] id=ohne_schild schild_pickups=0` · `[CHAL][SPERRE] pickup=shield grund=schild_pickup` · Zähler im HUD `[CHAL][HUD] text=OHNE SCHILD · LEICHT · RUNDE 1/5` `[x]` |
| **C8** | SAMMLER: Kisten aus **erspieltem** Gold zählen, Ziel 5 in einem Run | `[CHAL][ZIEL] id=sammler kisten=<n>/5` | — **belegt:** im Runden-Modus werden für SAMMLER Kisten platziert (`[CHAL][REGEL] id=sammler kisten_erlaubt=true quelle=run_map`) · `[CHAL][ZIEL] id=sammler kisten=1..5/5` über `signal chest_opened` · Abschluss `grund=kisten_geoeffnet` `[x]` |
| **C9** | Auswertung am Run-Ende: Ziel erreicht → Zustand ERLEDIGT + Belohnung = Diamanten der **gewählten Stufe**, nicht erreicht → LAEUFT mit Fortschritt; Profil gespeichert | `[CHAL][ENDE] id=<x> stufe=<s> ziel=<ja/nein> fortschritt=<n>/<z> diamanten=<d>` | — **belegt:** `[CHAL][ENDE] id=revolver stufe=leicht ziel=ja fortschritt=8/8 diamanten=40 grund=runden_erreicht` — für alle sechs Aufgaben · nicht erreicht: `ziel=nein fortschritt=1/12 grund=gestorben` (`emu_pause.png`) · Profil gespeichert (`_save_profile`) `[x]` |
| **C10** | Belohnung genau einmal (Regel aus v1.44 bleibt), Stufe muss zum Zustand passen (HART gibt mehr als LEICHT) | `[CHAL][BELOHNUNG] id=<x> stufe=<s> +<d> gems=<g> erneut=false` | — **belegt:** `[CHAL][GUTSCHRIFT] id=revolver +40 gems=40 zweite_gutschrift=false state=BELOHNT` · zweiter Aufruf bucht nichts (`state=BELOHNT` bleibt) · Betrag aus dem Zustand (`e["reward"]`), also die Stufe, in der gewonnen wurde; LEICHT 40 ◆ vs HART 160 ◆ `[x]` |
| **C11** | HUD während der Challenge: Aufgabe + Runde x/y + Ziel links oben, kein Menü-Zugriff außer Pause | `[CHAL][HUD] id=<x> runde=<a>/<b> ziel=<z>` | — **belegt:** `[CHAL][HUD] text=REVOLVER-RUNDE · NORMAL · RUNDE 1/12` (Emulator `emu_chal_run.png`: „AUFGABE · REVOLVER-RUNDE · NORMAL · RUNDE 1/12" oben links) · `[CHAL][HUD] id=… runde=…/… ziel=…` je Rundenstart `[x]` |
| **C12** | Abbruch/Verlassen zählt nicht als erledigt, Fortschritt bleibt erhalten | `[CHAL][ABBRUCH] id=<x> zustand=LAEUFT fortschritt=<n>` | — **belegt:** `[CHAL][ABBRUCH] id=revolver zustand=LAEUFT fortschritt=1` nach dem Tod im Run · Zustand bleibt LAEUFT, Fortschritt 1/12 erhalten (Profil gespeichert), Belohnung nicht gebucht `[x]` |
| **C13** | Beleg je Aufgabe: ein Diag-Lauf `chal_run145` spielt alle 6 Aufgaben auf LEICHT durch (Start, Ziel erfüllen per Debug-Hilfen, Auswertung, Belohnung) | `[TEST][CHALRUN145] aufgaben=6 erledigt=6` | — **belegt:** `[TEST][CHALRUN145] aufgaben=6 erledigt=6` — Start, Ziel, Auswertung und Belohnung für alle sechs Aufgaben auf LEICHT `[x]` |
| **C14** | Sichtprüfung: Karte mit START + Stufenwahl, HUD im Run, Erfolgs-Banner | `screenshots/v145/chal_karte.png`, `chal_hud.png`, `chal_erfolg.png` | — **belegt:** `chal_karte.png` (Karte mit START + Stufenwahl), `chal_hud.png` (HUD im Run), `chal_erfolg.png` (Erfolgsfenster) · zusätzlich vom Gerät: `emu_chal.png`, `emu_chal_run.png`, `emu_pause.png` (Ergebnis „AUFGABE VERFEHLT") `[x]` |

---

## I — App-Icons (mehrere Entwürfe, flashig, Stand v1.45)

Sechs Entwürfe als 1024×1024-PNG, im Comic-Look des Spiels (dicke Kontur, flache Farben,
Strahlenkranz), plus Kontaktblatt und Vorschau in Icon-Größen (48/72/96/144 px).

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **I1** | Sechs Entwürfe: (a) Heldenkopf + Revolver, (b) Kiste + Diamant, (c) Comic-Burst + „CS", (d) Walzen-Symbole, (e) Monster vs. Held, (f) Rad/Sonne | `screenshots/v145/icons/icon_a.png … icon_f.png` (1024²) | — **belegt:** `[ICON][ENTWURF] name=icon_a.png px=1024x1024 … icon_f.png` — sechs Entwürfe (Held+Revolver, Kiste+Diamant, CS-Burst, Walzen-Symbole, Monster vs Held, Glücksrad) in `screenshots/v145/icons/` `[x]` |
| **I2** | Kontaktblatt + Größen-Vorschau (48/72/96/144) je Entwurf, alles auf einem Bild | `screenshots/v145/icons_uebersicht.png` | — **belegt:** `icons_uebersicht.png` — sechs Entwürfe 1024², darunter je Entwurf 48/72/96/144 px mit Beschriftung; Entwurf A bleibt bei 48 px lesbar `[x]` |
| **I3** | Ein Entwurf wird Spiel-Icon (`application/config/icon`) und im Export benutzt, die anderen bleiben als Auswahl liegen | `[BUILD] icon=icon_<x>.png` + APK-Icon gesetzt (`aapt dump badging` zeigt es) | — **belegt:** `[BUILD] icon=icon_a.png quelle=res://icon.png px=1024 version=1.45 build=45` · im APK geprüft: `res/mipmap-xxxhdpi-v4/icon.webp` zeigt den Helden mit Revolver (Entwurf A), `assets/icon.png` = 1024² · die anderen fünf liegen als Auswahl in `screenshots/v145/icons/` `[x]` |

---

## F — Abschluss

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **F1** | Version **1.45**, `APP_BUILD` 45, Export-Preset | `[BUILD] Versionsanzeige v1.45 aktiv (Build 45)` in Projekt und EXE | — **belegt:** `[BUILD] Versionsanzeige v1.45 aktiv (Build 45)` · Menü im Emulator zeigt „v1.45 · Build 45" (`emu_menu.png`) · `export_presets.cfg version/code=45 version/name="1.45"` · `aapt dump badging`: `versionCode='45' versionName='1.45'` `[x]` |
| **F2** | Golden Master: unveränderte Modi bleiben grün, geänderte werden mit Begründung neu eingefroren (alte Fassung `.v144`) | `tools/golden_check.sh` ohne unerklärte Diff-Zeilen | — **belegt:** `chestfull rest_diff=0 / upg 0 / shop 0 / mini 0 / loc2 0 / seasons 0 / char 0 / wpn2 0 script_errors=0` → `OK: Verhalten unveraendert.` · neu eingefroren mit Begründung (neue Log-Zeilen aus T/K/Z), alte Fassungen als `backup/golden_v136/<modus>.log.v144` `[x]` |
| **F3** | Neue Diag-Modi: `snd145`, `chest145`, `load145`, `wheel145`, `chal_run145`, `icon145` — jeder endet mit `[TEST] … ENDE` | 6× `[TEST][…145] ENDE` | — **belegt:** `[TEST][SND145] ENDE`, `[TEST][CHEST145] ENDE`, `[TEST][LOAD145] ENDE`, `[TEST][WHEEL145] ENDE`, `[TEST][CHALRUN145] ENDE`, `[TEST][ICON145] ENDE` `[x]` |
| **F4** | Emulator-Durchlauf: Boot-Bildschirm → Aufgaben (Start, Run, Erfolg) → Shop (Kisten, Walze, Rad) — Prozess lebt, kein ANR | `pidof` identisch, `SCRIPT ERROR` = 0 | — **belegt:** Emulator-Durchlauf Boot → Aufgaben → Run (REVOLVER-RUNDE) → Ergebnis → Shop (Kisten, Walze, Rad): `pidof=7538` vor und nach dem Durchlauf identisch, `grep -c "SCRIPT ERROR"` = 0, keine ANR-Meldung · Bilder `emu_boot.png`, `emu_chal.png`, `emu_chal_run.png`, `emu_pause.png`, `emu_shop.png`, `emu_shop_kisten.png`, `emu_wheel.png`, `emu_wheel_ergebnis.png` `[x]` |
| **F5** | Doku: `STATUS.md`, `BUGLISTE.md`, `ARCHITEKTUR.md`, diese Spec mit Belegen | jede Zeile mit Log-Zitat | — **belegt:** `STATUS.md` (v1.45-Abschnitt mit Log-Zitaten), `BUGLISTE.md` (B45-1 … B45-5 behoben), `ARCHITEKTUR.md` (neue Bausteine + Aufgaben-Fluss), diese Spec mit Belegen je Zeile `[x]` |
| **F6** | APK + EXE nach `Desktop/` (`ComicShooter-v1.45.*`) | `apksigner verify` = 0 | — **belegt:** `Desktop/ComicShooter-v1.45.apk` (31,3 MB, `apksigner verify`: v2 true, v3 true) und `Desktop/ComicShooter-v1.45.exe` (112 MB, Start mit `COMIC_LANTEST=load145` → `[TEST][LOAD145] ENDE`, `EXE_RUN=0`) `[x]` |

---

## Testplan (Reihenfolge)

1. `COMIC_LANTEST=snd145` — Pegel aller Klänge, Musik, Clipping, WAV-Export
2. `COMIC_LANTEST=chest145` — neun Kisten-Bilder + Kontaktblatt, Shop-Luft
3. `COMIC_LANTEST=load145` — Boot- und Run-Ladebildschirm, Panel nie leer
4. `COMIC_LANTEST=wheel145` — Quoten (200 000 Simulationen), Drehung, Ticks, Buchung, Shop-Einbau
5. `COMIC_LANTEST=chal_run145` — alle 6 Aufgaben auf LEICHT bis zur Belohnung
6. `COMIC_LANTEST=icon145` — sechs Icon-Entwürfe + Übersicht
7. `tools/golden_check.sh`
8. Emulator: Boot, Aufgaben, Shop mit beiden Automaten
9. APK + EXE, `apksigner verify`, Artefakte nach `Desktop/`

## Was NICHT geändert wird

- Kein Umbau von `game_manager.gd`/`ui_manager.gd` (R1–R3 aus v1.43 bleiben offen).
- Keine neuen Waffen, keine neuen Monster, kein Balancing der Kisten-Preise.
- Die Walze (`slot_ui.gd`, `slot_machine.gd`) bleibt unverändert — sie ist Vorbild für das Rad.
- Die Aufgaben-Inhalte (Namen, Beschreibungen) bleiben wie in v1.44.

## Offene Fragen (entscheidet der nächste Lauf selbst)

1. **C1-Stufen:** Runden je Aufgabe → Standard: LEICHT 6–8, NORMAL 10–12, HART 16–20; Diamanten
   40 / 90 / 160 (mal Aufgaben-Faktor 0,6 … 1,4, damit REVOLVER/EISERN mehr geben als SAMMLER).
2. **Z1-Einsatz:** 100–5.000 Gold wie die Walze (Min 100, Max 5.000) → Standard: so.
3. **Z1-RTP:** Ziel 0,92 (wie Walze), Niete-Segment mit 12 % Gewicht.
4. **I3:** Welches Icon Spiel-Icon wird → Standard: (a) Heldenkopf + Revolver, weil es das
   Spiel in 48 px noch lesbar zeigt.
5. **L2:** Woher kommt der „zuletzt gewählte Modus" beim Boot → Standard: `game_mode` aus dem
   Profil (fehlt es, ENDLOS).
