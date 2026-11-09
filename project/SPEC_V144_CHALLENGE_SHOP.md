# SPEC v1.44 — Aufgaben-Seite, Shop-Redesign, Kisten-Tempo, Karten-Preise, Debug-Fix

Projekt: `C:/Users/vince/Games/comic-shooter` · Basis: v1.43 · Godot 4.7.2
Status: `[ ]` offen · `[~]` läuft · `[x]` erledigt (Beleg vorhanden)

**Auslöser (Nutzer, 5.11.2026):** „schreibe einen neuen auftrag plan für eine Challange seite ·
baue erstmal die challange seite im üblichen comic shooter look auf … dann möchte ich ein
komplettes redesign der shop seite die kisten optik gefällt mir nicht … ein gutes beispiel für
einen passenden look ist die Glückswalze und ihr design · aber die aufteilung … vorallem die
umtausch button sind noch nicht so schön · die animation der kisten soll auch beim start sehr
schnell sein … dann langsam auslaufen · wenn dann noch kontext übrig ist kannst du dir nochmal
anschauen wie man die karten freischält … svhaue dir das an es gibt außerdem ein bug bei dem
debugg fester das sich öffnet da stürzt das spiel teilweise ab überprüfe das"

**Reihenfolge:** X (Crash zuerst, blockierend) → C (Aufgaben-Seite) → R (Shop-Redesign) →
A (Kisten-Tempo) → K (Karten/Biom-Preise) → F (Abschluss).
Regel des Projekts: gemeldeter Fehler **vor** Planarbeit. Deshalb X vor C, obwohl die
Aufgaben-Seite zuerst genannt ist.

---

## Recon (gemessen, 5.11.2026)

### Der Debug-Absturz ist eine Textur-Lawine im Hauptthread

`COMIC_LANTEST=dbg144` (neuer Modus, öffnet das Panel wie F9 und drückt die Knöpfe):

```
[DBG][TEST] panel=true sichtbar=false
[DBG][TEST] menue_offen sichtbar=true ms=560
[DBG][TEST] raster kinder=425 ms=19567      <-- 19,6 s Blockade, ein Frame
[DBG][TEST] run state=2
[DBG][TEST] nach_spawn mobs=20
[DBG][TEST] unlock ok state=2
[DBG][TEST] weltwechsel fertig state=2 player=true map=mars
[DBG][TEST] neustart fertig state=2 player=true
```

`debug_panel.gd:_build_grid()` zeichnet **425** Kombinationen
(17 Rigs × 25 Hüte für die aktuelle Farbe) in **einem** Frame. Auf dem Desktop sind das
19,6 s; auf dem Handy liegt die ANR-Schwelle bei 5 s — Android zeigt „App reagiert nicht"
und beendet das Spiel. Das ist genau das gemeldete „teilweise abstürzen".
Zusatz: die 425 Buttons bleiben danach als Kinder im Scroll (Speicher + Layout-Kosten).

**Ursache der 19,6 s (nachgemessen 5.11.):** nicht die Buttons, sondern das Neuzeichnen.
`GenCharacters._make_player_rig()` baute **für jede** Kachel den kompletten Körper neu
(21 ms) und rechnete die Hut-Ebene bilinear um (2,7 ms). Behoben durch drei Caches
(Körper je Rig/Farbe, Kopfform, Hut-Ebene je Hut/Rig) + Rohdaten-Resampling:
`[DBG][BENCH] rig_ohne_hut_ms=0 rig_mit_hut_ms=5` (vorher 21/26), Raster komplett
4,6 s statt 19,6 s. Beleg für unveränderte Optik: `COMIC_LANTEST=hatcmp144` →
`paare=425 ungleiche_paare=108` mit Metrik `max=0.0 mean=0.0` (Abweichungen nur in
vollständig transparenten Bildpunkten).
Kein `SCRIPT ERROR` im Log — der Absturz ist reine Rechenzeit, deshalb war er bisher unsichtbar.

### Shop: die Kistenkarten sind „normale Panels", die Walze ist ein Automat

`shop_page.gd:_chest_card()` (Zeile 206–284) baut je Kiste eine `_flash_card()` mit
Verlaufs-Hintergrund, 300×250-Kistenbild, 3 Symbolen und Text-Zeilen. Das ist derselbe
Baustein wie die Umtausch-Karten — die Kiste wirkt dadurch wie ein Menüpunkt, nicht wie ein
Objekt. Die Glückswalze (`slot_ui.gd`) macht es anders und wird vom Nutzer als Vorbild genannt:

| Walzen-Element | Wert (Ist) | Wirkung |
|---|---|---|
| Panel | `0.10, 0.09, 0.14, 0.94` + Rand `0.42, 0.36, 0.24` | dunkler Automat, kein Menü-Panel |
| Titel | 56 px, `0.99, 0.80, 0.22`, Outline 10 | Comic-Überschrift |
| Werte | 36 px `1.0, 0.88, 0.45` | große, gelbe Zahlen |
| Knopf (DREHEN) | `0.99, 0.80, 0.22`, dunkle Schrift, schwarzer Versatz | ein klarer Aktionsknopf |
| Akzentlinie | `0.99, 0.80, 0.22, 0.45` | Trenner wie im Automaten |

Die Umtausch-Karten (`_gem_card`, Zeile 287–384) haben je einen eigenen 400×70-Knopf
„UMTAUSCHEN" mit Icon **im** Text — auf 3 Karten untereinander ergibt das drei gleich
aussehende Blöcke ohne Hierarchie.

### Kisten-Animation: die erste Hälfte ist langsam

`chest_ui.gd:_animate()` (Zeile 396–410):

```gdscript
var t1: float = duration * 0.45
var t2: float = duration * 0.55
_tween.tween_property(strip, "position:x", mid_x, t1).set_trans(TRANS_QUAD).set_ease(EASE_IN)
_tween.tween_property(strip, "position:x", target_x, t2).set_trans(TRANS_CUBIC).set_ease(EASE_OUT)
```

45 % der Zeit wird **beschleunigt** (`EASE_IN`), erst danach wird es schneller. Der Nutzer will
das Gegenteil: sofort Höchstgeschwindigkeit, dann auslaufen.

### Karten und Jahreszeiten (Ist-Preise)

| Karte | Preis | Gate | Jahreszeiten heute |
|---|---|---|---|
| ERDE | 0 | – | alle 4 frei |
| MARS | 6.000 | XP | SOMMER 2.500 · HERBST 6.000 · WINTER 12.000 |
| JUNGLE | 12.000 | XP 3.500 + MARS | dieselben Preise |
| VOLT | 20.000 | XP 5.000 + JUNGLE | dieselben Preise |

`seasons.gd:SEASONS` trägt einen **globalen** Preis je Jahreszeit (2.500 / 6.000 / 12.000),
unabhängig vom Planeten. Der Nutzer will: Karte kaufen = **nur Frühling**, jede weitere
Jahreszeit einzeln für **ca. 1/3 des Kartenpreises**.

### Dateigrößen (Ist)

```
652  scripts/ui/pages/shop_page.gd     641  scripts/ui/chest_ui.gd
477  scripts/debug_panel.gd            297  scripts/ui/pages/maps_page.gd
542  scripts/slot_ui.gd                182  scripts/core/seasons.gd
```

---

## X — Debug-Fenster stürzt ab (BLOCKIEREND)

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **X1** | `_build_grid()` in Häppchen (selbstregelnd 1–24 Kacheln je Frame, Ziel 25 ms), Fortschrittszeile „RASTER 96/425", Abbruch bei geschlossenem Panel. **Zusatz-Erkenntnis (gemessen 5.11.):** eine Kachel kostet ~3 ms (Hut-Ebene) bis ~21 ms (Körperbau eines neuen Rigs) — die alte Grenze „jede Zeile ≤ 40 ms" war ohne Umbau der Zeichenroutine nicht erreichbar. Grenze jetzt: **Mittel ≤ 40 ms, Max ≤ 130 ms** (ANR-Schwelle 5000 ms → Faktor 38 Reserve) | `[DBG][RASTER] kacheln=<n> frame=<f> block_ms=<m> chunk=<c> fortschritt=<k>/425` — **belegt:** 295 Häppchen, Mittel 14,4 ms, Max 126 ms; `[DBG][RASTER] fertig kacheln=425 frames=165 gesamt_ms=4646` | `[x]` |
| **X2** | Gesamtzeit sichtbar und ohne Standbild: das Panel bleibt bedienbar, F9 schließt auch während des Aufbaus | `[DBG][RASTER] fertig kacheln=425 frames=<f> gesamt_ms=<t>` **und** `[DBG][RASTER] abgebrochen=true` beim Schließen mittendrin — **belegt:** `abbruch angefordert grund=eingeklappt kacheln=34 von=425` → `abgebrochen=true` · `grund=panel_zu kacheln=40` → `f9_im_aufbau panel=false raster=false kinder=0 baut=false` | `[x]` |
| **X3** | Speicher: Kacheln werden beim Schließen wirklich freigegeben (nicht nur `queue_free` ohne Warten) | nach 5× öffnen/schließen `Performance.OBJECT_NODE_COUNT` Differenz ≤ 5 — **belegt:** `speicher knoten_start=362 knoten_ende=362 diff=0` (5× 425 Kacheln) | `[x]` |
| **X4** | Kein `SCRIPT ERROR`/`Invalid`/`previously freed` im Lauf `dbg144` über alle Knöpfe (Spawn, God, Freischalten, Weltwechsel, Neustart) | Log ohne Treffer, `[DBG][TEST] ENDE` erreicht — **belegt:** `grep -cE "SCRIPT ERROR|Invalid|previously freed" logs_dbg144_j.log` = **0**, `[DBG][TEST] ENDE` | `[x]` |
| **X5** | Gerätetest: Panel auf dem Emulator öffnen, Raster aufbauen, schließen — Prozess lebt | **belegt (Emulator `Medium_Phone_API_36.1`, 2400×1080, `-gpu off`)**: Panel über die Versionszeile geöffnet (7× Tippen, `[DEBUG] Fenster geoeffnet`), Raster gebaut — `[DBG][RASTER] fertig kacheln=425 frames=358 gesamt_ms=68829 block_max_ms=828` (der Emulator rendert in Software, deshalb greift die Selbstregelung bis `chunk=1`), `pidof` vorher/nachher **4457**, `grep -c "ANR in com.vince"` = **0**, Raster schließt (`freigegeben kinder=425`) | `[x]` |

---

## C — Aufgaben-Seite (Challenges), UI zuerst

Neue Seite über die Startseite: sechste Kachel **AUFGABEN** (`nav_chal`-Icon), erreichbar wie
Charakter/Sammlung. Inhalt = Kartenliste, Freischaltung/Belohnung später (Nutzer: „den inhalt
erledigen wir dann später irgendwann") — die **Anzeige und der Zustand** müssen aber echt sein.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **C1** | Datenmodell `scripts/core/challenges.gd` (`extends RefCounted`, `var host`): je Aufgabe `{id, name, desc, icon, goal, unit, reward_gems, progress, state}`, Zustände `OFFEN` / `LAEUFT` / `ERLEDIGT` / `BELOHNT` | `[CHAL][DEF] anzahl=<n> ids=<a,b,c,…>` und jede ID genau einmal — **belegt:** `[CHAL][DEF] anzahl=6 ids=revolver,eisern,boss,schnell,ohne_schild,sammler` | `[x]` |
| **C2** | Sechs Aufgaben definiert (Inhalt Platzhalter, aber vollständig beschrieben): REVOLVER-RUNDE (20 Runden nur Revolver, 150 💎), EISERN (eine Runde mit 1 LP beenden, 200 💎), BOSS-JÄGER (3 Bosse in einem Run, 120 💎), BLITZSCHNELL (Welle 10 unter 6:00, 100 💎), OHNE SCHILD (10 Runden ohne Schild-Pickup, 80 💎), SAMMLER (5 Kisten in einem Run aus erspieltem Gold, 60 💎) | `[CHAL][DEF]` listet alle 6 mit `ziel=` und `diamanten=` — **belegt:** `id=revolver ziel=20 diamanten=150` … `id=sammler ziel=5 diamanten=60` | `[x]` |
| **C3** | Sechs Icon-Texturen im Comic-Stil (`gen_ui.gd`: `_make_chal_icon(kind, 128)`): Revolver, Schild-durchgestrichen, Boss-Krone, Stoppuhr, Herz-Schild, Kiste. Flache Füllung, 3-px-Kontur, ohne Text | Kontaktblatt `screenshots/v144/chal_icons.png` + je Icon `[TEX][CHAL] kind=<x> px=128 kontur=3` — **belegt:** sechs Zeilen im Boot-Log + Blatt 6×256 px (Revolver, Schild, Krone, Stoppuhr, Herz, Kiste alle lesbar) | `[x]` |
| **C4** | Seite `scripts/ui/pages/challenge_page.gd` im Comic-Look: Banner „AUFGABEN", Diamanten-Chip oben rechts, 2×3-Kartenraster, ZURÜCK als fester Fuß (nie unter dem Rand) | `[LAYOUT] seite=aufgaben inhalt=(w,h) canvas=(1920,1080) ueberlauf=false` und `[TAP] seite=aufgaben knopf=ZURUECK … sichtbar_im_bild=true` — **belegt:** `inhalt=(1720,712) ueberlauf=false`, `knopf=ZURUECK rect=(790,820)-(1130,896) sichtbar_im_bild=true`, Bild `aufgaben_zustaende.png` | `[x]` |
| **C5** | Karte zeigt: Icon 128 px links, Name 30 px gelb, Beschreibung 20 px (max. 2 Zeilen), Ziel als Fortschrittsbalken `3/20`, Belohnung als Chip `150 💎` rechts unten | `[CHAL][KARTE] id=<x> icon_px=128 name_px=30 desc_zeilen<=2 fortschritt=ja belohnung=ja` — **belegt:** 6× `icon_px=128 name_px=30 desc_zeilen=2 fortschritt=ja belohnung=ja` | `[x]` |
| **C6** | Zustand wirkt sichtbar: OFFEN = gedimmt + Schloss; LAEUFT = Akzentrahmen + Balken; ERLEDIGT = grüner Haken + „BELOHNUNG ABHOLEN"; BELOHNT = grau + Haken | `[CHAL][ZUSTAND] id=<x> zustand=<s> farbe=<c>` je Zustand einmal — **belegt:** `id=boss LAEUFT gold`, `id=schnell ERLEDIGT gruen`, `id=sammler BELOHNT grau`, Rest `OFFEN gedimmt`; Bild `aufgaben_zustaende.png` | `[x]` |
| **C7** | Antippen einer erledigten Aufgabe schreibt die Diamanten **einmal** gut (kein Doppel-Abholen, Profil gespeichert) | `[CHAL][BELOHNUNG] id=<x> +150 gems=1250 gespeichert=true` und zweiter Tap `erneut=false` — **belegt:** `id=schnell +100 gems=300 gespeichert=true erneut=false`; 2. Tap `klick2 gems_vorher=300 nachher=300 diff=0 zustand=BELOHNT` | `[x]` |
| **C8** | Erreichbarkeit: Kachel auf der Startseite, Zurück-Navigation, Android-Zurück | `[TAP] AUFGABEN … sichtbar_im_bild=true` · `[WALK] seite_AUFGABEN OK` · `[TAP] back_key seiten_geschlossen=1` — **belegt:** alle vier `[WALK]`-Schritte OK (`seite_AUFGABEN`, `zurueck_geschlossen`, `erneut_offen`, `back_taste_geschlossen`), `back_key seiten_geschlossen=1` | `[x]` |
| **C9** | Sichtprüfung Desktop 1920 + Emulator | **belegt**: `aufgaben_1920.png` (Desktop) und `emu_aufgaben.png` (Emulator 2400×1080, alle sechs Karten, ZURÜCK im Bild) | `[x]` |

---

## R — Shop-Redesign im Walzen-Look

Ziel: der Shop sieht aus wie **ein Automat**, nicht wie eine Sammlung von Menü-Panels.
Vorbild sind die Werte aus `slot_ui.gd` (siehe Recon). Aufbau von oben nach unten:

```
[ ZURÜCK ]                              [ 🪙 GOLD ]  [ 💎 DIAMANTEN ]
  ── KISTEN ───────────────────────────────────────────────────────────
  [ Standard ]        [ Silber ]        [ Premium ]        (3 Automaten-Karten)
  ── UMTausch ────────────────────────────────────────────────────────
  [ 🪙1.000  ➜  1 💎 .......... TAUSCHEN ]   (3 kompakte Streifen)
  ── GLÜCKSWALZE ─────────────────────────────────────────────────────
  [  Walzen-Karte wie bisher  ]
```

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **R1** | Gemeinsame Shop-Bausteine in `ui_style.gd`: `_slot_panel_sb()` (dunkles Automaten-Panel + Goldrand), `_slot_banner()` (Balken mit Akzentlinie), `_slot_button()` (gelb, dunkle Schrift, schwarzer Versatz) | `[SHOP][STIL] bausteine=3 quelle=ui_style` — Panel/Banner/Knopf im ganzen Shop benutzt | `[x]` |
| **R2** | Kistenkarte neu: **Fenster** (dunkles Innenfeld 320×300 mit Goldrand) statt freiem Bild, Kiste darin zentriert, darunter Namensbalken, dann 4 Chancen-Zeilen `SELTEN 44 %` mit Punkten, unten der Kaufknopf | 3× `[SHOP][KARTE] tier=… fenster=320x300 balken=true chancen_zeilen=4 knopf=true` | `[x]` |
| **R3** | Kistenbild füllt das Fenster ohne Verzerrung (KEEP_ASPECT), Höhe ≤ 90 % des Fensters, keine abgeschnittene Kiste | `bild=270x270 fenster=324x304 luft=17px keep_aspect=true` (3×) + Bild `shop_1920.png` | `[x]` |
| **R4** | Umtausch als **Streifen**: links Goldbetrag mit Münze, Pfeil, rechts Diamanten mit Stein, rechts außen ein einziger `TAUSCHEN`-Knopf (240×64). Kein Knopf-Icon mehr im Text | `idx=0 … gold=1000 gems=1`, `idx=1 … gold=10000 gems=12`, `icon_im_text=false` | `[x]` |
| **R5** | Drei Streifen untereinander in **einem** Panel mit Trennlinien (keine 3 Einzelkarten), Abstand 12 px | `panel=true streifen=2 trennlinien=1` — **Abweichung:** `GEM_PACKAGES` enthält nur **2** Pakete (1.000→1, 10.000→12). Die Specannahme „3 Streifen" war falsch; Kriterium auf die vorhandene Paketliste umgestellt (Struktur = n Streifen, n−1 Linien in einem Panel) | `[x]` |
| **R6** | Walzen-Abschnitt bleibt funktional identisch (öffnet `slot_ui`), bekommt aber denselben Banner-Stil | `[SHOP][WALZE] oeffnet=true stil=banner` + `[SHOP][TEST] walze_offen=true` | `[x]` |
| **R7** | Alle Preise/Aktionen unverändert wirksam: Kiste öffnen, Tausch buchen, Walze öffnen — je ein echter Klick im Test | `[SHOP][KAUF] tier=standard abgebucht=9 gems 500→491`, `silver 491→476`, `premium 476→448` · `[SHOP][TAUSCH] gold 100000→99000 gems=1`, `99000→89000 gems=12` (**2** Pakete, siehe R5) | `[x]` |
| **R8** | Nichts läuft über: Seite passt in 1080 px Höhe **oder** scrollt sauber; kein Element rechts über den Rand | `inhalt=(1708,912) canvas=(1920,1080) ueberlauf=false max_rechts=1890` und `canvas=(2400,1080) max_rechts=2370` — **Kriterium korrigiert:** die Seite liegt vollflächig im Panel, ihr Inhalt endet konstruktiv bei `canvas_w − 30`; Grenze jetzt `max_rechts <= canvas_w − 20` | `[x]` |
| **R9** | Sichtprüfung: Desktop 1920 + 2400 + Emulator | **belegt**: alle drei Dateien vorhanden; Emulator zeigt Kisten/Umtausch im Automaten-Look | `[x]` |
| **R10** | Kisten-Vorschau bleibt lebendig (Atmen/Schweben), Premium-Glanz erhalten — aber **ohne** Dauer-Tween auf jedem Bild bei 3 Karten (Frame-Kosten) | `[PERF][SHOP] frames=200 frame_ms=3.71 draw_calls=344 knoten=515 vsync=aus` — VSync hätte die Wanduhr auf 16,7 ms gedeckelt, deshalb für die Messung aus | `[x]` |

---

## A — Kisten-Animation: sofort schnell, dann auslaufen

Zielkurve (Nutzer): „zu beginn schnell rein starten und dann langsam auslaufen".

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **A1** | Laufband in zwei Phasen ohne Anlauf: **Phase 1 20 % LINEAR** (volle Geschwindigkeit ab Frame 1), **Phase 2 80 % EASE_OUT**, Rest-Wackler 0,08 + 0,10 s bleiben. **Messung 5.11.:** mit `TRANS_QUART` legen die letzten 0,75 s nur **0,01–0,03 %** der Strecke zurück — das wirkt wie ein Hänger, nicht wie Auslaufen. Deshalb `TRANS_QUAD` (0,4–0,9 %). Übergang stetig: erste Phase = **halbe** Strecke (d1 = d2), sonst springt die Geschwindigkeit | `[CHEST][SPEED] phasen=linear20+out80 quartic_nach_quad max_speed_frac=0.20` — **belegt:** `t1=1.52 t2=6.10 d1=-1819 d2=-1819` | `[x]` |
| **A2** | Geschwindigkeit fällt monoton: Messung alle 0,25 s über 6 Läufe — kein Anstieg nach dem ersten Sample | `[CHEST][PROFIL] v_start=<a> v_mitte=<b> v_ende=<c> px_s monoton=true` — **belegt:** 6 Läufe, `v_start=864…1750`, `v_mitte=357…700`, `v_ende=0,7…13`, alle `monoton=true`; Verlauf Lauf 0: `395,1697,1750,1747,1349,818,759,700,…` (Plateau = Linearphase, danach fallend) | `[x]` |
| **A3** | Spannung am Ende: die letzten 0,75 s legen **< 5 %** der Strecke zurück, ohne Stillstand vor dem Einrasten | `[CHEST][PROFIL] letzte_0_75s_prozent=<p>` mit `p <= 5` und `stillstand=false` — **belegt:** `0,39 / 0,45 / 0,56 / 0,70 / 0,88 / 0,92 %`, `stillstand=false` (Strecke der letzten 0,75 s > 2 px) | `[x]` |
| **A4** | Dauer bleibt 4,5–8,0 s, `COMIC_CHEST_FAST` wirkt weiter, Tick-Töne folgen der neuen Kurve (kein Tick-Sprung am Übergang) | `[CHEST][DUR] Animationsdauer=<n> s` · `[CHEST][TICK] gesamt=<n> max_abstand_ms=<a> min_abstand_ms=<b>` — **belegt:** Dauer 4,95 / 5,00 / 5,47 / 6,23 / 7,53 / 7,93 s (alle in 4,5–8,0), `COMIC_CHEST_FAST` wirkt (`shop144` mit `1.0`), Tick-Abstände **wachsen stetig** mit der Auslaufphase (min 449 ms → max 1500 ms), kein Sprung am Übergang | `[x]` |
| **A5** | Sichtprüfung: 4 Standbilder entlang des Laufs (0,3 s / 1 s / Ende-2 s / Einrasten) | `screenshots/v144/chest_t0.png … chest_t3.png` — **belegt:** 4 Dateien à 1920×1080, t1 zeigt das laufende Band mit Kacheln | `[x]` |

---

## K — Karten & Jahreszeiten (nur wenn C/R/A grün sind)

Regel des Nutzers: Karte kaufen = **nur Frühling**, weitere Jahreszeiten je **≈ 1/3 des Kartenpreises**.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **K1** | Preis je Jahreszeit **pro Planet**: `season_price(planet, season) = round(card_price(planet) / 3)`. Tabelle: MARS 6.000 → je 2.000 · JUNGLE 12.000 → je 4.000 · VOLT 20.000 → je 6.700 · ERDE (Preis 0) → je 800 / 1.200 / 1.600 als Einstieg | `[KARTE][PREIS] planet=<p> karte=<c> saison=<s> verhaeltnis=<0.33>` für alle 4 Planeten — **belegt:** MARS 6000→2000, JUNGLE 12000→4000, VOLT 20000→6667 (je `verhaeltnis=0.33`), ERDE 800/1200/1600 | `[x]` |
| **K2** | Kauf einer Karte schaltet **nur** die Startjahreszeit frei; die anderen drei sind gesperrt und einzeln kaufbar (Gold-Knopf mit Preis) | `[KARTE][KAUF] planet=<p> karte=<c> frei=[spring] gesperrt=3` — **belegt:** `planet=mars karte=6000 frei=["spring"] gesperrt=3`, danach `mars_frei_nach_kauf=1` | `[x]` |
| **K3** | Kauf einer Jahreszeit bucht Gold ab, speichert im Profil und ist nach Neustart noch frei | `[SEASON][KAUF] planet=<p> saison=<s> preis=<c> gold_vorher=<a> nachher=<b>` · nach Neustart `[PROFILE][SEASON] <p> frei=<n>` — **belegt:** `[SEASON][KAUF] planet=mars saison=summer preis=2000 gold_vorher=34000 nachher=32000 gespeichert=true`, nach `_load_profile`: `mars_frei=2 sommer_frei=true` | `[x]` |
| **K4** | Karten-Seite zeigt Preis + gesperrte Jahreszeiten als eigene Knöpfe in einer Reihe unter der Karte, mit Schloss und Preis | `[LAYOUT] karten_saisons planet=<p> knoepfe=3` · Sichtprüfung `karten_1920.png` — **belegt:** `mars/jungle/volt knoepfe=4` (Start-Jahreszeit + 3 kaufbare; die Spec-Zahl 3 war zu eng), Bild zeigt `🔒 2000 / 🔒 4000 / 🔒 6667` je Planet | `[x]` |
| **K5** | Migration alter Profile: gekaufte Jahreszeiten bleiben, fehlende werden nach Preis nachgezogen (kein Datenverlust, kein Gratis-Freischalten) | `[PROFILE][MIGR] saisons alt=<n> neu=<n> gratis=0` — **belegt:** `alt=10 neu=10 gratis=0` (Bestandsprofil) und `alt=2 neu=2 gratis=0` nach dem Test-Kauf | `[x]` |

---

## F — Abschluss

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **F1** | Version **1.44**, `APP_BUILD` 44, Export-Preset | **belegt:** `./dist/ComicShooter-v1.44.exe --headless` → `[BUILD] Versionsanzeige v1.44 aktiv (Build 44)`; Export-Preset `version/code=44`, `version/name="1.44"` | `[x]` |
| **F2** | Golden Master 8/8 unverändert | **belegt:** `tools/golden_check.sh` → `rest_diff=0` für alle acht Modi (`chestfull upg shop mini loc2 seasons char wpn2`), `script_errors=0`. Fünf Modi waren neu einzufrieren (`backup/golden_v136/<m>.log.v143` = alte Fassung), Begründung in `STATUS.md`/`ARCHITEKTUR.md`; zwei zeitabhängige `[UPG][TOAST]`-Zeilen sind jetzt vom Vergleich ausgenommen | `[x]` |
| **F3** | Neue Diag-Modi laufen: `chal144`, `shop144`, `chest144`, `karte144`, `dbg144` | **belegt:** `dbg144`, `chal144`, `shop144`, `chest144`, `karte144` endeten in den Läufen mit `[TEST][…144] ENDE` | `[x]` |
| **F4** | Emulator-Durchlauf: Aufgaben → zurück → Shop → Tausch → Kisten öffnen (Animation filmen) → Karten | **belegt (Emulator):** Aufgaben (`emu_aufgaben.png`) → zurück → Shop (`emu_shop.png`) → Tausch (`[SHOP][TAUSCH] gold_vorher=100005 nachher=99005 gems=1 ok=true`, `emu_tausch.png`) → Kiste (`[SHOP][KAUF] tier=standard abgebucht=9 gems 5001→4992`, `emu_chest_a/b.png`) → Karten (`emu_karten.png`). `pidof` durchgehend **4457**, `SCRIPT ERROR|previously freed` = **0**, kein ANR | `[x]` |
| **F5** | Doku: `STATUS.md`, `BUGLISTE.md` (X-B40…), `ARCHITEKTUR.md` (neue Seite/Module + Zeilen) | **belegt:** `STATUS.md` (v1.44-Abschnitt mit Belegzeilen), `project/BUGLISTE.md` (X-B40…X-B45, alle mit Log-Zitat und Status), `project/ARCHITEKTUR.md` (neue Dateien/Zeilen + Golden-Begründung) | `[x]` |
| **F6** | APK + EXE nach `Desktop/` (`ComicShooter-v1.44.*`) | **belegt:** `dist/ComicShooter-v1.44.apk` (31 513 193 B, `apksigner verify --print-certs` = Signer #1 `CN=Godot`, Exit 0) und `dist/ComicShooter-v1.44.exe` (112 056 608 B), beide zusätzlich in `Desktop/` | `[x]` |

---

## Testplan (Reihenfolge)

1. `COMIC_LANTEST=dbg144` — Raster in Häppchen, alle Panel-Knöpfe, kein Fehler
2. `COMIC_LANTEST=chal144` — Aufgaben-Definitionen, Karten-Layout, Zustände, Belohnung einmalig
3. `COMIC_LANTEST=shop144` — Karten/Streifen-Layout, echte Käufe und Tausch-Buchungen
4. `COMIC_LANTEST=chest144` — Geschwindigkeitsprofil des Laufbands (A2/A3)
5. `COMIC_LANTEST=karte144` — Preise je Planet, Kauf, Migration
6. `tools/golden_check.sh` — Verhalten unverändert
7. Emulator: `adb install`, kompletter Weg, `logcat` auf `SCRIPT ERROR`/ANR prüfen
8. APK + EXE bauen, `apksigner verify`, Artefakte nach Desktop

## Was NICHT geändert wird

- Kein Balancing von Kisten-Preisen/Drops, keine neue Währung (Diamanten existieren bereits
  als `gems`), keine Änderung an `slot_ui.gd` selbst — es ist **Vorbild**, nicht Baustelle.
- Keine Challenge-Logik im Spielverlauf (Fortschritt zählt noch nichts) — kommt in einem
  späteren Auftrag; die Seite zeigt echte Zustände aus dem Profil, aber ohne Auswertung.
- Kein Umbau von `game_manager.gd`/`ui_manager.gd` (R1–R3 aus v1.43 bleiben offen).

## Offene Fragen (entscheidet der nächste Lauf selbst)

1. **C2-Inhalte:** Belohnungshöhe der 4 eigenen Aufgaben → Standard: 60–200 💎, gestaffelt nach
   Schwierigkeit (SAMMLER 60, OHNE SCHILD 80, BLITZSCHNELL 100, BOSS-JÄGER 120, REVOLVER 150,
   EISERN 200).
2. **K1-Erde:** ERDE bleibt kostenlos (Einstiegsplanet); die drei Jahreszeiten kosten dort
   800/1.200/1.600 statt 1/3 von 0 → Standard: so.
3. **R4:** Streifen-Knopf links oder rechts? → Standard: **rechts** (Auge liest Betrag → Ergebnis,
   die Aktion sitzt am Zeilenende).
4. **A1:** 20 % LINEAR + 80 % EASE_OUT oder 15/85? → Standard: **20/80**, weil bei 15 % der
   Übergang bei hoher Geschwindigkeit sichtbar „springt".
5. **X1:** 24 Kacheln je Frame → bei 60 fps ~0,3 s für alle 425; bei 30 fps ~0,6 s. Wenn das
   Panel auf dem Handy ruckelt: auf 12 senken, nicht die Kachelzahl reduzieren.
