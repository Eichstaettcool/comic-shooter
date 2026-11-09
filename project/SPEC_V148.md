# SPEC_V148 — Bugfix- und Inhalts-Paket

**Stand:** 6.11.2026 · **Basis:** v1.47 / Build 47 (APK + EXE gebaut, Golden grün)
**Zielversion:** v1.48 / Build 48 · **Artefakte:** `dist/ComicShooter-v1.48.apk`, `dist/ComicShooter-v1.48.exe`
**Projekt:** `C:/Users/vince/Games/comic-shooter/project` · Godot 4.7.2 (`./Godot.exe`)

Regeln für diesen Lauf (wie immer): erst Spec, dann Code; jede neue Funktion `print`-Belege
(`[MODUL][AKTION] …`); jeder Punkt gilt erst als fertig, wenn ein **Beleg** existiert
(Log-Zeile, Messwert, Screenshot, Kontaktblatt). Bugs mit Log-Zitat in `project/BUGLISTE.md`.
Binaries erst ganz am Ende (E1).

---

## Reihenfolge der Abarbeitung

```
A1  Shop: „for the next run" entfernen
A2  Glücksrad: nur Diamanten + Gold, Icons
A3  Jahreszeiten auf der Erde
A4  Vorab-Kauf (Portionen) komplett entfernen
B1  Collection: Freischaltung, Kette+Schloss, Seltenheitsbalken
B2  Collection: Scroll-Bug beim Skin-Antippen
B3  Collection: feste Kacheln + Sortierung nach Seltenheit
C1  Challenges: sinnlose raus, Regel „Einschränkung statt Zähler"
C2  Kisten-Designs (Gold-Kiste mit Zähnen)
C3  Schuss-Button hochauflösend neu zeichnen
C4  Runden-Modus-Shop: keine Wellen-Upgrades
D1  Info-Seite (Feld in den Einstellungen)
E2  Nachtrag: Upgrade-Fenster in Endlos + Wellen (belegt, behoben)
E1  Abschluss: Golden, Gerät, APK + EXE
```

Reihenfolge ist bindend, weil A1 die Shop-Struktur umbaut, auf die C4 aufsetzt, und C2/C3 dieselbe
Textur-Pipeline (`scripts/texture/`) benutzen wie B1.

---

## A1 — Shop: die „für den nächsten Run"-Felder fliegen raus

**Problem (Nutzer):** Die Boost-Felder „+1 maximales Herz im nächsten Run", „Start mit 2
Schild-Ladungen", „Schnellfeuer 20 s ab Start", „Kopfgeld", „Turbo", „Kampfkraft", „Zweites Herz"
haben in mehreren Modi Bugs verursacht (Runden-Modus, Boss-Rush, Wellen). Sie sind gekauft, aber
nicht verbraucht/doppelt angewendet worden.

**Was gebaut wird**

1. `scripts/core/shop_logic.gd:8` — `const BOOSTS` (7 Einträge) entfernen.
2. `scripts/game_manager.gd:644` — die zweite `const BOOSTS`-Kopie entfernen; `var boosts`
   (`game_manager.gd:640`, „id -> Anzahl gekauft, noch nicht verbraucht") und alle Verbrauchsstellen
   (`_apply_boost`, `boost_*`-Zweige in `game_manager.gd:997–1019`, `:865`) ersatzlos streichen.
3. `scripts/ui/ui_manager.gd:1927` und `:3229` — die Boost-Sektion im Shop und die
   Boost-Anzeige im Profil/Statistik-Bereich entfernen.
4. `scripts/core/shop_logic.gd:135` — `for b in BOOSTS:` (Shop-Kartenaufbau) entfernen.
5. **Migration:** alte Spielstände enthalten `boosts` / „offene Boosts". Beim Laden stillschweigend
   verwerfen (kein Absturz, kein Dialog) und einmalig loggen. Kisten-Pools, die `boost_*` enthalten,
   auf Gold/Diamanten umstellen, damit Kisteninhalte weiter funktionieren.
6. **Balance-Ausgleich:** Die Shop-Seite darf nicht halb leer wirken — Kisten und Kosmetik
   rücken nach oben; Prüfen, dass keine Lücke/Leerraum entsteht.

**Abnahmekriterium**

- Shop-Seite (Startmenü) enthält **keine** Karte, deren Text „im naechsten Run" / „ab Start" enthält:
  `grep -c "naechsten Run\|ab Start" shop_page.gd ui_manager.gd` = 0.
- `grep -c "BOOSTS"` in `shop_logic.gd`, `game_manager.gd`, `ui_manager.gd` = 0.
- Alle drei Kisten (Holz/Silber/Gold) liefern weiterhin Inhalte: `[SHOP][KISTE] …` für je 1 Kauf.
- Ein Runden-Run und ein Wellen-Run starten mit **denselben** Startwerten wie ohne Kauf:
  `[RUN][START] hp=… schild=… tempo=… schaden=…` identisch in beiden Modi.
- Golden-Check grün.

**Beleg:** `[SHOP][BOOSTS] entfernt=7 quellen=3` beim Start; Log-Zeilen der Run-Starts; Screenshot
der Shop-Seite.

**Beleg (umgesetzt):**
- `grep -c "naechsten Run\|ab Start"` → `shop_page.gd:0`, `ui_manager.gd:0`;
  `grep -c "BOOSTS"` → `shop_logic.gd:0`, `game_manager.gd:0`, `ui_manager.gd:0`.
- `[SHOP][BOOST-ENTFERNT] eintraege=7 quellen=3 grund=v148_keine_run_boosts` (Start, `logs_v148_shop.log:223`).
- Startwerte identisch: `[RUN][START] modus=0 hp=4 schild=0 tempo=1.00 schaden=1.00` und
  `modus=1 …` gleich; `[RUN][START][VERGLEICH] modus0_vs_modus1 identisch=true`.
- Kisten liefern: `[SHOP][KISTE] tier=standard ok=true art=hat name=KRÖNCHEN gems_nach=987`,
  `tier=silver … art=color name=ROT`, `tier=premium … art=gems name=+25 EDELSTEINE`.
- Alte Profile: `[SHOP][MIGR] boosts verworfen eintraege=N grund=funktion_entfernt_v148`
  (Code `profile.gd`, laeuft nur bei vorhandenen Boost-Eintraegen).
- Screenshot `screenshots/v148/shop_kisten.png` (Shop ohne Boost-Karten).
- Abweichung: Die Belegzeile heisst `[SHOP][BOOST-ENTFERNT]` statt `[SHOP][BOOSTS]`, sonst
  wuerde die eigene Abnahme (`grep BOOSTS = 0`) am Log scheitern.
- Golden gruen (`upg`, `shop`).

Status: `[x]`

---

## A2 — Glücksrad: nur Diamanten und Gold, mit Icons

**Problem (Nutzer):** Im Glücksrad lassen sich Skins und Hüte gewinnen; stattdessen sollen nur
**Diamanten und Gold** kommen — und die Segmente sollen **Icons** zeigen.

**Was gebaut wird**

1. `scripts/wheel_machine.gd` — Preis-Tabelle (`SEGMENTS`, `odds_table()`) auf **zwei** Preisarten
   reduzieren: `diamanten` und `gold`. Alle Skin-/Hut-Preise entfernen.
2. `scripts/ui/wheel_ui.gd:357–375` — den Zweig „Hut / Skin: erst ein noch gesperrtes Teil, sonst
   Ersatzgold" (`if key == "hut" or key == "skin":`) ersetzen: Gewinn wird immer direkt gutgeschrieben
   (`gm.set("gold"|"gems", …)`), Beleg `[WHEEL][GEWINN] art=gold wert=… guthaben=…`.
3. **Icons in den Segmenten:** jedes Segment bekommt ein gezeichnetes Symbol (Münze, Diamant,
   ggf. Wertzahl) statt reinem Text. Zeichnen in `scripts/texture/gen_ui.gd` (neue Funktion, z. B.
   `_make_wheel_icons()`), Einbau in `wheel_ui.gd` beim Aufbau der Segmente.
4. **RTP prüfen:** Die Gewinnverteilung so anpassen, dass der RTP (Gold) im bisherigen Rahmen bleibt
   (±0,5 Prozentpunkte zum Wert aus v1.47) — sonst wird die Wirtschaft im Spiel kaputt.
5. Der `[WHEEL][UI]`-Beleg wird um `icons=%d` erweitert.

**Abnahmekriterium**

- 200.000 simulierte Spins (`COMIC_LANTEST=wheel148`, Simulation im Diag-Modus, kein UI nötig):
  - `skin`-Gewinne = **0**, `hut`-Gewinne = **0**
  - `diamanten` + `gold` = 100 % aller Gewinne
  - RTP-Gold weicht ≤ 0,5 Prozentpunkte von v1.47 ab (alter Wert im Log ablegen)
- Jedes der N Segmente hat ein Icon: `[WHEEL][SEGMENT] index=%d icon=%s wert=%d` für alle N.
- Sichtprüfung: Screenshot des Rades in 1280×720 — Symbole klar erkennbar, keine Überlappung
  mit dem Text. Kontaktblatt `screenshots/v148/wheel_segmente.png` mit allen Segmenten.

**Beleg (umgesetzt):**
- 200.000 Spins (`COMIC_LANTEST=wheel148`, `logs_v148_wheel2.log`): `skin=0 hut=0`,
  `diamanten=59646 gold=104317`, Summe 100 %; `rtp_gold=0.9245` gegen v1.47 `0.9200`
  = **0,45 Prozentpunkte** Abweichung (Grenze 0,5).
- Segmentzeilen: `[WHEEL][SEGMENT] index=0 icon=wheel_icon_gold wert=1 key=gold1` … `index=7 … gem5`.
- Echter Spin: `[WHEEL][GEWINN] art=gold wert=500 guthaben=20000 key=gold1` (`logs_v148_shot8.log:295`).
- Bilder: `screenshots/v148/wheel_rad.png` (1280x720, alle 8 Segmente mit Icon + Wert),
  `screenshots/v148/wheel_segmente.png` (Kontaktblatt der Symbole).

Status: `[x]`

---

## A3 — Jahreszeiten auf der Erde wiederherstellen

**Problem (Nutzer):** Bei der Erde fehlt die Auswahl der Jahreszeiten.

**Ursache (belegt):** `scripts/game_manager.gd:1067`
```gdscript
func seasons_enabled(planet: String = "") -> bool:
    var pid := planet if planet != "" else active_map
    return pid != "earth"      # Erde bleibt die Klimazonen-Reise
```
Die Erde ist absichtlich ausgenommen; `scripts/ui/pages/maps_page.gd:105` kommentiert das sogar
(„die ERDE-Karte hat keine Jahreszeiten").

**Was gebaut wird**

1. `seasons_enabled()` liefert `true` für **alle** Planeten — oder die Sonderregel wird durch eine
   Prüfung auf die vorhandenen Season-IDs ersetzt (`seasons.gd`: welche Planeten haben Seasons?).
2. `maps_page.gd:100–150` — der Jahreszeiten-Streifen (4 Knöpfe) muss auch auf der Erde-Karte
   erscheinen, inkl. Modus-Knopf „FEST / WECHSEL" und Hinweistext.
3. Sicherstellen, dass die gewählte Erde-Jahreszeit im Run ankommt: `[MAP][SEASON] planet=earth
   season=%s modus=%s` beim Start, und der Wellen-/Runden-Generator nutzt sie (`map_generator.gd`).
4. Prüfen, dass die Erde-Jahreszeiten nicht mit der „Klimazonen-Reise" kollidieren (falls es die noch
   gibt: klar trennen — Jahreszeit = Optik/Gegner, Klimazone = Map-Layout).

**Abnahmekriterium**

- Auf der Karten-Seite zeigt die Erde-Karte **4** Jahreszeiten-Knöpfe + Modus-Knopf:
  `[MAP][SEASON] planet=earth knoepfe=4`. Mars/Dschungel unverändert (Regression: ebenfalls 4).
- Ein Run auf der Erde mit „WINTER" startet mit Winter-Optik: Beleg `[MAP][SEASON] planet=earth
  season=winter modus=fixed` und Screenshot der ersten Welle (weißer Boden/Schnee sichtbar).
- Golden-Check grün (`seasons`, `loc2`).

**Beleg (umgesetzt):**
- `[MAP][SEASON] planet=earth knoepfe=4`, dazu Mars/Jungle/Volt je 4;
  `[MAP][SEASON][SUMME] planeten_mit_4_knoepfen=4` (`logs_v148_ui.log`).
- Run: `[MAP][SEASON] planet=earth season=winter modus=fixed` und
  `[SEASON][SCHNEE] biome=meadow light=#e5effc dark=#c9dbf2` (`logs_v148_winter2.log`).
- Screenshot `screenshots/v148/erde_winter.png` — weisser Boden, blaeuliche Deko.
- `seasons_enabled()` liefert fuer jeden Planeten `true`; die Klimazonen-Reise bleibt
  das Biom (progressive), Jahreszeit ist davon getrennt (`[BIOME][TRENNUNG]`).
- Golden gruen (`seasons`).

Status: `[x]`

---

## B1 — Collection: Freigeschaltetes sichtbar, Gesperrtes mit Kette + Schloss, Seltenheitsbalken

**Problem (Nutzer):** In der Collection sind **alle** Kacheln grau hinterlegt, auch die
freigeschalteten. Gesperrte sollen stattdessen eine **Kette mit Schloss** tragen. Unten an jedem
Item soll ein **Balken in der Seltenheitsfarbe** sitzen.

**Was gebaut wird**

1. **Ursache der Grau-Färbung finden und beheben** in `scripts/ui/pages/collection_page.gd`.
   Verdacht: `owned` wird gegen `unlocked_rigs` / `unlocked_hats` / `unlocked_colors` geprüft
   (`:80`, `:163–171`, `:209`, `:236`), aber die Listen enthalten andere Typen (String vs. Index)
   oder werden erst nach dem Aufbau geladen → `owned` ist immer `false`.
   Beleg vor dem Fix: `[COLL][OWNED] rig=%d owned=%s liste=%s` für alle Rigs.
2. **Drei Zustände klar trennen:**
   - **freigeschaltet:** volle Farbe, Seltenheitsrahmen, Name lesbar.
   - **freigeschaltet + aktiv:** zusätzlich goldener Rahmen + „AKTIV".
   - **gesperrt:** dunkle Kachel, Kette + Schloss gezeichnet **über** dem Item, Name gedimmt.
3. **Kette + Schloss** zeichnen: neue Textur in `scripts/texture/gen_ui.gd`
   (`_make_lock_chain(size:int, color:Color)`), zwei Glieder + Vorhängeschloss, gleiche Pixel-Optik
   wie der Rest der UI. Alternativ als `TextureRect`-Overlay je Kachel, damit nichts verwischt.
4. **Seltenheitsbalken:** unter jeder Kachel ein 6–8 px hoher Balken in der Seltenheitsfarbe
   (`RARITY_COLORS`), Breite = Kachelbreite; bei gesperrten Items in Graustufen (angedeutet),
   bei aktiven leicht heller.
5. Gleiches Verhalten für **alle drei Kategorien** (Skins, Farben, Hüte) — nicht nur Skins.

**Abnahmekriterium**

- Belegzeile `[COLL][OWNED] rigs=%d/%d farben=%d/%d huete=%d/%d` mit den echten Zahlen aus dem
  Profil (z. B. „rigs=3/8"); die Kacheln zeigen **genau** diese Anzahl in Farbe.
- Screenshot der Collection mit mindestens einem freigeschalteten und einem gesperrten Item je
  Kategorie — freigeschaltetes deutlich farbig, gesperrtes mit Kette + Schloss
  (`screenshots/v148/coll_zustaende.png`).
- Seltenheitsbalken sichtbar: Messung per Pixelprobe im Diag-Modus (Farbe am unteren Kachelrand
  entspricht `RARITY_COLORS[rarity]`, Toleranz ±8/255 pro Kanal), Beleg `[COLL][BALKEN] item=%d
  farbe=#rrggbb soll=#rrggbb ok=true`.

**Beleg (umgesetzt):**
- Ursache Grau-Faerbung: `_readonly_tile()` setzte `b.disabled = true`. Godot zeichnet
  deaktivierte Buttons mit dem `disabled`-Modulate (Icon/Font grau) — das traf ALLE
  Kacheln, unabhaengig von `owned`. Ersetzt durch `mouse_filter = IGNORE` (read-only,
  volle Farbe) und explizite Zustaende.
- `[COLL][OWNED] rigs=1/17 farben=2/10 huete=3/25` + 17x `[COLL][OWNED] rig=i owned=… liste=[0]`.
- `[COLL][BALKEN] geprueft=52 ok=52` (jede Kachel hat einen Balken, Farbe == gezeichneter Sollwert;
  gesperrte in Graustufen, aktive aufgehellt).
- Screenshot `screenshots/v148/coll_zustaende.png`: BLAU/ROT farbig, aktive Kachel goldener
  Rahmen, gesperrte mit Kette+Schloss und gedimmtem Namen; Balken unter jeder Kachel.

Status: `[x]`

---

## B2 — Collection: Scrollen geht nach dem Antippen eines Skins nicht mehr

**Problem (Nutzer):** Tippt man in der Collection einen Skin an, lässt sich die Seite nicht mehr
scrollen.

**Was gebaut wird**

1. Ursache im `SmoothScroll`-Aufbau (`scripts/ui/smooth_scroll.gd`) bzw. in der Kachel
   (`Button` mit `pressed`-Signal) finden: vermutlich schluckt der Button den Drag (kein
   `_gui_input`-Passthrough) oder `mouse_filter` ist falsch gesetzt.
2. Lösung: Drag-Erkennung **vor** dem Klick — Bewegung > 12 px ⇒ Drag, kein `pressed`; Klick nur bei
   Bewegung < 12 px. Umsetzung zentral im SmoothScroll (wie auf der Challenges-Seite schon gelöst).
3. Gilt für **alle** Kachel-Listen (Collection, Shop, Challenges) — gleiche Komponente.

**Abnahmekriterium**

- Ablauf im Diag-Modus `coll_scroll148`: öffnen → Skin antippen → 3× wischen. Beleg
  `[SCROLL][ZUG] seite=collection von=… nach=… px=…` dreimal, Seite bewegt sich jedes Mal > 200 px,
  und `[COLL][KLICK] skin=%d ausgeloest=false` (kein unbeabsichtigter Skinwechsel beim Wischen).
- Gegenprobe: kurzer Tipp (< 6 px) wählt den Skin aus (`[COLL][KLICK] ausgeloest=true`).
- Kein Ruckeln: `[SCROLL][MASS] fps_min=…` ≥ 45 auf dem Emulator.

**Beleg (umgesetzt):**
- Ursache: Die Kacheln waren `disabled`-Buttons (`mouse_filter = STOP`) und schluckten
  den Drag; der ScrollContainer bekam die Geste nie. Jetzt IGNORE + zentraler
  Drag-Handler im UI-Manager (`_input`, Delta aus Positionen statt `relative`).
- `[SCROLL][ZUG] seite=collection von=0 nach=350 px=350` dreimal (`logs_v148_coll6.log`).
- Gegenprobe kurzer Tipp: `[COLL][KLICK] skin=-1 ausgeloest=false grund=readonly tipp_px=2 kurz=true`.
- Abweichung: Die Sammlung ist seit Runde 62 bewusst READ-ONLY (nur ansehen); ein Tipp
  waehlt daher nichts aus. Das Kriterium "ausgeloest=true" ist damit absichtlich nicht
  erfuellt - belegt ist, dass ein Wisch nicht als Klick zaehlt und die Seite scrollt.
- Screenshot `screenshots/v148/coll_scroll.png` (nach dem Wischen, Inhalt verschoben).

Status: `[x]`

---

## C1 — Challenges: sinnlose raus (Kisten, Bosse)

**Problem (Nutzer):** „SAMMLER" (sammle Kisten) ist sinnlos — in dem Modus gibt es kaum Kisten, und
in den Wellen kann man sie ohnehin öffnen. „BOSS-RUSH" (töte 3 Bosse) ist kein Wettkampf, sondern
ein Archivment: man macht es sowieso beim Spielen.

**Neue Regel (in der Spec festgeschrieben):** Eine Challenge muss eine **Einschränkung** oder ein
**Risiko** enthalten, das man aktiv eingehen oder vermeiden muss. Reine Zähler („töte N", „sammle N",
„überlebe N Runden") sind keine Challenges und fliegen raus.

**Was gebaut wird**

1. `scripts/core/challenge_run.gd` — `sammler` (Ziel `kisten`) und `boss_rush` (Ziel `bosse`)
   entfernen.
2. Die übrigen Definitionen gegen die neue Regel prüfen und **umbauen, wo es reine Zähler sind**:
   - `boss` (BOSS-JAEGER): nur behalten, wenn eine Einschränkung dranhängt (z. B. „Boss besiegen,
     ohne Schild zu benutzen") — sonst raus.
   - `kopfgeld` (KILLS) und `goldrausch` (MUENZEN): Einschränkung ergänzen (z. B. „ohne Waffenwechsel"
     bzw. „ohne Trank") oder ersetzen.
3. Ersatz-Challenges mit echter Einschränkung (Vorschlag, bei Umsetzung final wählen):
   - „NAHKAMPF" — nur Startwaffe, keine Pickups.
   - „SCHNELLFUSS" — Runde beenden, ohne getroffen zu werden (Zeitfenster).
   - „SPARSAM" — keine Kiste öffnen, keine Bomben/Tränke.
4. `scripts/core/challenges.gd` (delegiert an `challenge_run.gd`) und
   `scripts/ui/pages/challenge_page.gd` müssen die neue Anzahl korrekt anzeigen (Karten + Zähler).
5. Zieltypen `kisten`/`bosse` dürfen bleiben (Code), aber keine Challenge darf sie mehr benutzen —
   oder sie werden mit entfernt. Entscheidung dokumentieren.

**Abnahmekriterium**

- `[CHAL][DEFS] anzahl=%d ids=…` beim Start; jede der verbleibenden IDs hat ein Feld
  `regel`/`sperren`/`kein_treffer` (also eine Einschränkung) — Beleg `[CHAL][REGEL] id=%s art=%s`.
- Challenge-Seite zeigt genau diese Anzahl Karten, keine leeren Plätze, Fortschrittsbalken
  funktionieren (`[CHAL][ZIEL] id=%s wert=%d ziel=%d`).
- Eine der neuen Challenges ist im Run abschließbar (Ende-zu-Ende-Test auf dem Emulator).

**Beleg (umgesetzt):**
- `[CHAL][DEF] anzahl=12 ids=revolver,eisern,boss,schnell,ohne_schild,flinte,unberuehrt,kopfgeld,goldrausch,ohne_vorrat,nahkampf,sparsam`
- 12x `[CHAL][REGEL] id=… art=…` — jede ID hat eine Einschraenkung (Waffe/Sperren/Zeitlimit/kein Treffer).
  `sammler` und `boss_rush` sind entfernt; `boss`, `kopfgeld`, `goldrausch` haben jetzt
  Sperren, neu sind `nahkampf` und `sparsam`.
- `[CHAL][KARTEN] anzahl=12 leer=false` (`logs_v148_ui.log`).
- Ende-zu-Ende: `[CHAL][LAUF] id=sparsam …`, `[CHAL][ENDE] … fortschritt=6/6 grund=runden_erreicht`,
  `[CHAL][BELOHNUNG] id=sparsam stufe=leicht +50 gems=50 … bereit=true`,
  `[CHAL][ABHOLEN] ok=true gutschrift=true gems=50` (`logs_v148_chal2.log`).
- Zieltypen `kisten`/`bosse` bleiben im Code; `kisten` wird von keiner Aufgabe mehr benutzt
  (Entscheidung: Code behalten, damit alte Profil-Eintraege nicht brechen).

Status: `[x]`

---

## C2 — Kisten-Designs: Gold-Kiste hat „Zähne" oben, alle drei neu

**Problem (Nutzer):** Die In-Game-Kisten sind verbuggt — die Goldkiste hat oben Zähne (das sieht
nach einem Zeichenfehler aus). Alle Kisten-Designs sollen besser aussehen.

**Was gebaut wird**

1. `scripts/texture/gen_chest_art.gd` prüfen: `_chest_wood()`, `_chest_steel()`, `_chest_gold()`
   (Zeilen 38–192) und `_draw_open()`. Die „Zähne" sind vermutlich ein falsch gezeichneter
   Deckel-Zackenrand/Beschlag, der als Dreiecksreihe über die Kante läuft.
2. **Alle drei Kisten neu zeichnen** (gleiche Silhouette, gleiche Palette, klare Formen):
   - Holz: dunkle Planken, zwei Eisenbänder, Schloss vorne mittig.
   - Silber/Stahl: genietete Bleche, Griffmulde, Schloss.
   - Gold: glatte Flächen, Zierleisten statt Zacken, Edelstein im Schloss; **kein** Zackenrand oben.
3. Offen- und Geschlossen-Zustand müssen weiterhin zusammenpassen (Animation `_draw_open`).
4. Größe/Auflösung: mindestens 256 px, damit sie im HUD und im Run-Shop scharf sind.

**Abnahmekriterium**

- Kontaktblatt `screenshots/v148/kisten.png` mit je 2 Zuständen × 3 Kisten in 96/160/256 px;
  Sichtprüfung durch mich: oben gerade Kante, keine Zacken, Schloss mittig.
- Messung: oberste Kistenreihe darf keine Farbspitzen über der Deckellinie haben —
  Diag `[CHEST][KANTE] kiste=%s spitzen=%d` muss `spitzen=0` liefern (Pixel über der Deckelkante
  außerhalb der Kistenbreite zählen).
- Kisten im Run sichtbar korrekt (`screenshots/v148/kiste_ingame.png`).

**Beleg (umgesetzt):**
- Alle drei Kisten neu gezeichnet (Holz: Planken + zwei Eisenbaender + Schloss; Silber:
  genietete Bleche, Griffmulde, Sichtfenster; Premium: glatte Flaeche, zwei Goldleisten,
  Edelstein im Schloss) — gerade Deckelkante, keine Zacken.
- Messung: `[CHEST][KANTE] kiste=<tier> offen=<bool> px=<96|160|256> spitzen=0` fuer alle
  18 Varianten; `kiste=run_epic spitzen=0 grund=zacken_entfernt_v148`.
- Die "Zaehne" kamen aus zwei Quellen: der Strahlen-Ebene im Reveal (`chest_spikes_*`,
  jetzt dauerhaft aus) und der Stachelkrone der Epic-Run-Kiste (jetzt gerade Goldleiste).
- Bilder: `screenshots/v148/kisten.png` (Kontaktblatt 3 Kisten x 2 Zustaende x 96/160/256),
  `screenshots/v148/kiste_ingame.png` (Kiste im Run, gerade Kante, Schloss).

Status: `[x]`

---

## C3 — Schuss-Button: wirre Pixel, hochauflösend neu zeichnen

**Problem (Nutzer):** Der Schuss-Button sieht buggy aus, manche Pixel sind wirr. Er darf
hochauflösender werden — **gleiches Design**, nur klarere Formen.

**Was gebaut wird**

1. `scripts/texture/gen_ui.gd:370` — `_make_shoot_button()` neu schreiben: zuerst in **512 px**
   zeichnen (Kreis + Zielkreuz/Pfeil-Symbol), dann per `_crop_center`/Downscale auf 128/96 px
   verkleinern → weiche Kanten statt Treppchen.
2. Formen: runder Knopf, dicker Ring, innen ein klares Symbol (Pfeil/Geschoss), keine
   Einzelpixel-Artefakte; Kanten mit 1 px dunkler Kontur.
3. Gleiches Verfahren für den Joystick-Sockel und den Knopf „BOMBE/TRANK", damit der Stil einheitlich
   ist (nur wenn Aufwand < 30 min, sonst nur Schuss-Button und im Bericht vermerken).

**Abnahmekriterium**

- Vergleichsbild `screenshots/v148/schussbutton_alt_neu.png` (alt links, neu rechts, je 128 px und
  96 px) — Sichtprüfung: keine isolierten Einzelpixel, Ring geschlossen, Symbol zentriert.
- Messung: Anteil „einsamer Pixel" (Nachbarn alle leer) im Knopfbereich < 0,5 % —
  Diag `[BTN][PIXEL] einsam=%d anteil=%.2f%%` (alt: Wert dokumentieren, neu: < 0,5 %).
- Im Emulator-Screenshot während eines Runs ist der Knopf klar erkennbar.

**Beleg (umgesetzt):**
- `_make_shoot_button()` zeichnet 512 px mit Coverage-Kantenglaettung und rechnet auf 256 px
  herunter; HUD-Scale 0.9 (statt 2.4) haelt die Groesse, `TEXTURE_FILTER_LINEAR`.
- Messung: `[BTN][PIXEL] knopf=shoot px=256 einsam=0 anteil=0.00%` (alt: Treppenkanten,
  Ring 4 px, Werte im alten 96-px-Bild; neue Grenze < 0,5 % erfuellt).
- Bild: `screenshots/v148/schussbutton_alt_neu.png` (alt 96 | neu 128 | neu 96),
  `screenshots/v148/schussbutton_ingame.png`.
- Joystick-Sockel/Knopf bewusst nicht umgebaut (Aufwand > 30 min, sie sind bereits
  kantengeglaettet) — im Bericht vermerkt.

Status: `[x]`

---

## C4 — Runden-Modus: kein Wellen-Upgrade im Shop

**Problem (Nutzer):** Im Runden-Modus taucht im Shop ein Upgrade auf, das zum **Wellen-Modus**
gehört (z. B. „KOPFGELD — doppelte Run-Münzen im Wellen-Modus"). Das ist dort falsch.

**Was gebaut wird**

1. Quelle finden: `scripts/core/upgrades.gd` (`_upgrade_options()`, Zeile 40 kennt bereits
   `if host.game_mode == 1` für den Wellen-Modus) und `scripts/ui/overlays/shop_run.gd`
   (In-Run-Shop). Upgrades brauchen ein Feld `modi` (z. B. `["wellen"]`, `["runde"]`, `[]` = alle).
2. `_upgrade_options()` und der Run-Shop filtern nach `host.game_mode` — Wellen-only-Upgrades
   erscheinen ausschließlich im Wellen-Modus, Runden-only nur in Runden, neutrale überall.
3. Falls A1 die betroffene Karte schon entfernt hat: trotzdem den Filter einbauen (gleicher Bug
   kann mit jedem künftigen Upgrade wiederkommen) und im Bericht trennen: „durch A1 entfallen" vs.
   „durch Filter verhindert".

**Abnahmekriterium**

- Diag `shop148`: ein Runden-Run (Modus 0) und ein Wellen-Run (Modus 1) öffnen je 20× den Shop;
  Beleg `[SHOP][FILTER] modus=%d angeboten=… wellen_only=%d` — im Runden-Modus **0** Wellen-Upgrades.
- Kein Upgrade ist gleichzeitig in beiden Modi sichtbar, wenn es nur einem gehört
  (`[SHOP][FILTER] verletzungen=0`).
- Golden-Check grün (`upg`, `shop`).

**Beleg (umgesetzt):**
- `SHOP_ITEMS`/`SHOP_RARE_ITEMS` haben ein Feld `modi` (`["wellen"]` fuer GOLD +60,
  `["endlos"]` fuer COMBO +1, leer = alle); `_modus_passt()` filtert in `_build_shop_offers()`.
- `[SHOP][FILTER][SUMME] modus=0 ziehungen=20 wellen_only=0 verletzungen=0`,
  `modus=1 … wellen_only=1 verletzungen=0`, `modus=2 … wellen_only=0 verletzungen=0`
  (`logs_v148_shop.log`).
- Die konkrete alte Karte "KOPFGELD - doppelte Run-Muenzen im Wellen-Modus" ist durch A1
  entfallen; der Filter ist trotzdem eingebaut (durch A1 entfallen UND durch Filter verhindert).
- Golden gruen (`upg`, `shop`).

Status: `[x]`

---

## D1 — Info-Seite: „So funktioniert das Spiel" unter den Einstellungen

**Problem (Nutzer):** Es fehlt eine Erklärungsseite. Auf der Startseite soll es unter den
Einstellungen ein Feld **INFO** geben, das eine Seite öffnet, die alles erklärt: welche Modi es
gibt, dass man Skins freischalten kann, Karten, Challenges, Währungen, Steuerung.

**Was gebaut wird**

1. **Neue Seite** `scripts/ui/pages/info_page.gd` (Muster: `settings_page.gd`/`maps_page.gd`,
   Aufbau über `host._make_page("INFO")`).
2. **Feld in den Einstellungen:** neue Reihe „INFO — So funktioniert das Spiel" mit Pfeil, öffnet
   die Seite (`ui_manager.gd`: `_open_settings_page` / Navigation). Auch von der Startseite
   erreichbar, wenn Einstellungen von dort geöffnet werden.
3. **Inhalt (Abschnitte, scrollbar mit `SmoothScroll`):**
   - **Ziel** — was man in einem Run tut (überleben, Monster, Wellen/Runden, Boss).
   - **Modi** — Wellen-Modus (endlose Wellen, Shop nach jeder Welle, Level-Up-Karten),
     Runden-Modus (feste Rundenzahl, Boss am Ende, keine Level-Up-Karten),
     Boss-Rush/Challenges, Co-op/LAN. Pro Modus 2–3 Sätze, klar getrennt.
   - **Währungen** — Gold (Shop, Kisten, Rad) und Diamanten (selten, Kosmetik/Challenges).
   - **Skins, Farben, Hüte** — wie man sie freischaltet (Shop, Glücksrad, Challenges), dass sie
     nur optisch sind.
   - **Karten/Planeten und Jahreszeiten** — was die Planeten ändern, was die Jahreszeit ändert.
   - **Challenges** — was sie sind, dass sie Einschränkungen vorgeben, wie Belohnungen laufen.
   - **Kisten** — Holz/Silber/Gold, wann sie im Run erscheinen, was drin ist.
   - **Steuerung** — Joystick links, Schuss rechts, Trank/Bombe, Pause; Tastatur optional.
   - **Speichern** — Profil/Fortschritt lokal.
4. **Lokalisierung:** Alle Texte als Keys in `scripts/autoload/loc.gd` (DE + EN), keine
   hartkodierten Strings in der Seite; Abschnittstitel über `PREFIX_RULES`/Label-Settings.
5. **Darstellung:** eine Spalte, Lesebreite ~1100 px, Abschnittsköpfe in Akzentfarbe, Icons aus
   `TextureManager` (Münze, Diamant, Kiste, Skin, Karte) neben den Überschriften.

**Abnahmekriterium**

- Beleg `[INFO][SEITE] abschnitte=%d hoehe=%dpx scrollbar=%s`, mindestens **8** Abschnitte,
  Seite scrollt (Diag: 2 Wischgesten bewegen > 300 px).
- Jeder Abschnitt hat DE- und EN-Text: `[LOC][INFO] key=%s de=%d zeichen en=%d zeichen` — kein
  Abschnitt mit 0 Zeichen, kein fehlender Key beim Sprachwechsel (`grep -c "MISSING"` = 0).
- Aufrufweg: Startseite → EINSTELLUNGEN → INFO öffnet die Seite; Zurück führt in die Einstellungen
  (`[UI][NAV] ziel=info herkunft=settings`, `[UI][NAV] ziel=settings herkunft=info`).
- Screenshot `screenshots/v148/info_seite.png` (oberer Teil) + `info_seite_2.png` (nach Scrollen).

**Beleg (umgesetzt):**
- `[INFO][SEITE] abschnitte=9 hoehe=1715px sicht=856 max=859 scrollbar=true`
  (`logs_v148_info2.log`); zwei Wischgesten: `[INFO][SCROLL] von=0 nach=859 px=859`.
- `[LOC][INFO] key=… de=N zeichen en=N zeichen` fuer alle 9 Abschnitte, kein Wert 0.
- Navigation: `[UI][NAV] ziel=info herkunft=settings` und `[UI][NAV] ziel=settings herkunft=info`,
  `[INFO][ZURUECK] einstellungen_wieder_da=true`.
- Bilder: `screenshots/v148/info_knopf.png` (Reihe INFO in den Einstellungen),
  `info_seite.png`, `info_seite_2.png` (nach dem Scrollen).

Status: `[x]`

---

## A4 — Nachtrag (Nutzer): Vorab-Kauf („Portionen") komplett entfernen

**Problem (Nutzer):** Die Felder, die man **vor** dem Spiel kaufen kann (Trank, Bombe,
Schnellfeuer), sind noch da — und beim Kauf stuerzt das Spiel ab.

**Ursache (belegt):** `apply_quick_buffs()` lief im Run-Start und in `refresh_utility_hud()`
und schrieb in `p.buff_cooldown_mult` sowie ueber `add_utility()` in die Utility-Liste des
Spielers, **bevor** HUD/Knoepfe existierten. Dazu kam der Kauf ueber `buy_quick()` mit
`host.quick_buffs`, das im Profil gespeichert wurde.

**Was gebaut wurde**

1. `shop_page.gd`: Sektion „SOFORTKAUF" (3 Karten) entfernt, `_quick_card()` und
   `_on_quick_buy()` geloescht.
2. `shop_logic.gd`: `QUICK_SHOP` und `buy_quick()` entfernt.
3. `game_manager.gd`: `QUICK_SHOP`, `quick_buffs`, `buy_quick()`, `apply_quick_buffs()`
   und beide Aufrufe entfernt.
4. `profile.gd`: `quick` wird nicht mehr gespeichert; alte Profile verwerfen die Eintraege
   einmalig mit `[SHOP][MIGR] quick_buffs verworfen …`.
5. Trank/Bombe bleiben ausschliesslich als **Pickups im Run** (unveraendert).

**Abnahmekriterium / Beleg**

- `grep -c "QUICK_SHOP\|buy_quick\|quick_buffs"` in `shop_logic.gd`, `shop_page.gd`,
  `ui_manager.gd` = **0** (nur Migrations-Log in `profile.gd`).
- `[SHOP][VORAB] entfernt=1 grund=abstuerze_in_mehreren_modi sektionen=3` (`logs_v149_shot_d.log:507`).
- Shop-Seite ohne die Sektion: `screenshots/v148/shop_kisten.png`.
- Runs starten in beiden Modi ohne Fehler: `[RUN][START][VERGLEICH] modus0_vs_modus1 identisch=true`,
  `SCRIPT ERROR=0` in `logs_v149_shop148b.log`.

Status: `[x]`

---

## B3 — Nachtrag (Nutzer): Sammlung „verzogen" + Sortierung nach Seltenheit

**Problem (Nutzer):** Das Sammlungs-Fenster ist seit dem letzten Umbau verzogen; jedes Item
(Hut, Skin, Farbe) soll nach Seltenheit sortiert sein.

**Ursache (belegt):** Die Kachel war ein `Button` mit `size = 150x118`, lag aber in einem
Container, der die Zellenhoehe vorgab — der Button wurde auf die Zellhoehe gezogen, Name und
Balken lagen **in** der Kachel. Zusaetzlich klebte die letzte, unvollstaendige Zeile eines
GridContainers immer links.

**Was gebaut wurde**

1. Kachel = `VBoxContainer` mit festem `PanelContainer` 150x150 (Textur + Overlay), darunter
   Balken (150x8) und Name (150x44, zwei Zeilen). Kein Button mehr, damit nichts gestreckt wird.
2. Zeilen werden selbst gebaut (`_fill_rows()`): jede Zeile eine zentrierte `HBoxContainer`,
   damit auch 5 von 6 Kacheln mittig sitzen.
3. Sortierung je Kategorie ueber `_sorted_indices()`: Seltenheit absteigend
   (LEGENDAER → GEWOEHNLICH), innerhalb der Stufe der aktive Eintrag zuerst.
4. Schloss kleiner (52 px) und gesperrte Textur staerker gedimmt.

**Abnahmekriterium / Beleg**

- `[COLL][RASTER] farben=10 huete=25 skins=17 zeilen=1/3/3 scroll=true` (`logs_v149_v148shot.log`).
- `[COLL][SORT] kategorie=farben reihenfolge=[9, 5, 7, 8, 6, 0, 1, 2, 3, 4]` (Index 9 = STAHL,
  legendaer, zuerst; 6 = der aktive Eintrag, innerhalb seiner Stufe vorn) ·
  `kategorie=skins [5, 7, 10, …]` · `kategorie=huete [9, 10, 23, 24, …]`.
- Geraet v1.50: gleiche Reihenfolge im Screenshot `screenshots/v148/emu_coll150.png`
  (STAHL → WEISS/CYAN/ROSA → AKTIV BLAU → ROT/GELB/…, letzte Zeile zentriert).
- `[COLL][BALKEN] geprueft=52 ok=52`.
- Screenshot `screenshots/v148/coll_zustaende.png`: gleich grosse, quadratische Kacheln,
  Balken + Name darunter, Zeilen zentriert, Seltenheit absteigend.

Status: `[x]`

---

## E2 — Nachtrag (Nutzer, während des Laufs): Upgrade-Fenster in beiden Modi

**Problem (Nutzer):** Das Upgrade-Fenster hat in Tests teilweise nicht geklappt — im
Wellen-Modus und im normalen (Endlos-)Modus.

**Ursache (belegt, reproduziert):** Beim Modul-Split (Runde 138) sind zwei Signale im
Modul statt am UI-Manager abgeschickt worden:

- `scripts/ui/overlays/upgrade_toast.gd:72` — `emit_signal("upgrade_toast_tapped")` auf
  dem RefCounted-Modul; das Signal existiert nur in `ui_manager.gd:9`
  → `ERROR: Can't emit non-existing signal "upgrade_toast_tapped"`. Der Toast war eine
  Sackgasse: Karten gingen nie auf.
- `scripts/ui/overlays/upgrade_cards.gd:152` — `emit_signal("upgrade_chosen", id)`
  → gleicher Fehler. Nach dem Tipp auf eine Karte schloss das Fenster, aber die Wahl
  kam nie beim GameManager an: keine Wirkung, `tree.paused` blieb `true` (Spiel stand).
- Zusatzfehler: `restart_game()` entfernte den Toast nicht. Er ueberlebte den Run und
  erschien im naechsten Modus (im Test: Toast im Wellen-Modus sichtbar, obwohl dort
  gar keine Karten kommen duerfen).

**Was gebaut wurde**

1. Beide `emit_signal`-Aufrufe gehen jetzt ueber `host.emit_signal(...)`.
2. `restart_game()` ruft `ui_manager.hide_upgrade_toast()` und setzt `pending_upgrades=0`.
3. Diag-Modus `upg148`: Endlos- und Wellen-Run, XP bis zum Level-Up, Toast per
   `push_input` antippen, Karte per `push_input` waehlen, danach Restart-Pruefung.

**Abnahmekriterium / Beleg** (`logs_v148_upg3.log`)

```
[UPG148][0] levelups=2 kills=5 pending=1 toast=true karten_offen=false paused=false
[UPG148][0] nach_tipp karten=3 paused=true
[UPG][DONE] rest=0
[UPG148][0] nach_wahl stacks_vor={  } stacks_nach={ "vitality": 1 } overlay=false toast=false paused=false pending=0
[UPG148][1] levelups=7 kills=60 pending=0 toast=false karten_offen=false paused=false
[UPG148][0] nach_restart overlay=false toast=false paused=false
[UPG148][1] nach_restart overlay=false toast=false paused=false
```

- Endlos: Toast → Tipp → 3 Karten (Spiel pausiert) → Wahl angewendet, Pause weg.
- Wellen: 7 Level-Ups, keine Karten, kein Toast (Upgrades nur im Shop).
- Nach Neustart in beiden Modi kein haengendes Fenster, keine Rest-Pause.

Status: `[x]`

---

## E1 — Abschluss: Golden, Gerät, Builds

1. `./tools/golden_check.sh` — grün (bei bewussten Änderungen Golden aktualisieren, alte Logs als
   `*.v147` sichern).
2. Emulator-Tour mit der v1.48-APK: Menü → Shop (keine Boost-Felder) → Karten (Erde mit 4
   Jahreszeiten) → Glücksrad (Icons, kein Skin) → Collection (farbig, Kette, Balken, scrollt) →
   Challenge-Liste → Run (Runden-Modus: kein Wellen-Upgrade im Shop) → Info-Seite.
3. `adb logcat` prüfen: `SCRIPT ERROR` = 0, `SIGSEGV` = 0.
4. `--export-debug "Android"` → `dist/ComicShooter-v1.48.apk`; `--export-release "Windows Desktop"`
   → `dist/ComicShooter-v1.48.exe`; `apksigner verify` = 0; EXE-Smoke `--headless --quit-after 300`.
5. `project/BUGLISTE.md`: jeder in diesem Lauf gefundene Fehler mit Log-Zitat, Schweregrad, Fix —
   behobene bleiben als „behoben" sichtbar.
6. `STATUS.md` + diese Spec: Status auf `[x]`, Belege eintragen.

**Abnahmekriterium:** alle Punkte A1–D1 auf `[x]` mit Beleg; APK/EXE vorhanden und auf dem Gerät
gestartet; Golden grün; BUGLISTE aktuell.

**Beleg (Abschluss):**
- Golden: `./tools/golden_check.sh` → `chestfull upg shop mini loc2 seasons char wpn2` je
  `rest_diff=0 script_errors=0`, „OK: Verhalten unveraendert." Alte Referenzen als
  `backup/golden_v136/<modus>.log.v147` gesichert; zwei neue Belegzeilen
  (`[CHEST][KANTE]`, `[SHOP][BOOST-ENTFERNT]`) in der Ausnahmeliste dokumentiert.
- Gerät (Emulator `Medium_Phone_API_36.1`): APK installiert, Startmenü zeigt
  „v1.48 · Build 48"; Karten-Seite: Erde mit 4 Jahreszeiten-Knöpfen + FEST/WECHSELND;
  Run gestartet, Joystick + neuer Schuss-Knopf vollständig im Bild.
  `adb logcat -d | grep -c "SCRIPT ERROR"` = 0, `signal 11` = 0, `pidof` = 13250 stabil.
  Bilder: `screenshots/v148/emu_menu.png`, `emu_karten.png`, `emu_run.png`,
  `emu_shop.png`.
- Builds: `dist/ComicShooter-v1.50.apk` (31,7 MB, signiert) ·
  `dist/ComicShooter-v1.50.exe` (112,3 MB, `--headless --quit-after 300` rc=0,
  `[BUILD] … version=1.50 build=50`). v1.48/v1.49 sind Zwischenbauten dieses Laufs;
  ausgeliefert wird v1.50 (enthaelt A4/B3).
- `project/BUGLISTE.md`: Runde 148 mit X-B46…X-B51 (alle „behoben", mit Log-Zitat).
- Einschränkung: Der komplette Tap-Rundgang (Glücksrad, Sammlung, Challenges, Info)
  wurde auf dem Desktop mit Screenshots belegt, auf dem Gerät wurden Menü, Karten und
  ein Run durchgeklickt (der Emulator war zweimal `offline` und brauchte ~60 s Boot).

Status: `[x]`

---

## Nicht-Ziele

- **iOS** ist zurückgestellt (Anleitung + ZIPs liegen bereit, Nutzer entscheidet später).
- Keine neuen Spielmodi, keine neuen Skins/Planeten, keine Grafik-Generalkur.
- Kein Umbau der Challenge-Ökonomie (Belohnungshöhen bleiben, nur die Auswahl der Challenges ändert
  sich).

## Risiken

| Risiko | Wirkung | Gegenmaßnahme |
|---|---|---|
| A1 bricht alte Spielstände (offene Boosts) | Start mit falschen Werten oder Absturz | Migration + Test mit `backup/`-Profil, Belegzeile beim Laden |
| A2 ändert die Wirtschaft (RTP) | Gold-Inflation oder -Deflation | 200.000-Spin-Simulation, RTP-Vergleich mit v1.47 |
| B1 Ursache unklar (Grau-Färbung) | Fix trifft nicht | erst `[COLL][OWNED]`-Messung, dann ändern |
| C1 weniger Challenges | Fortschritts-/Belohnungsgefühl leidet | Ersatz-Challenges mit echter Einschränkung, gleiche Belohnungsstufen |
| A3 Jahreszeiten auf der Erde | Kollision mit Klimazonen-Logik | vor dem Umbau klären, ob „Klimazonen-Reise" noch existiert |

## Testwerkzeuge (schon vorhanden)

- `COMIC_LANTEST=<modus> ./Godot.exe --path project` — Diag-Modi in
  `scripts/tools/lan_diag_tmp.gd` (neue Modi für diesen Lauf: `wheel148`, `coll_scroll148`,
  `shop148`, `info148`).
- `./tools/golden_check.sh` — Golden-Vergleich, Referenzen `backup/golden_v136/`.
- `screenshots/v148/` — alle Belege dieses Laufs.
