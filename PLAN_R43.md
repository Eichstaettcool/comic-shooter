# RUNDE 43 — AUSFÜHRLICHER UMSETZUNGSPLAN

Stand: 25.10.2026 · Projekt: `C:\Users\vince\Games\comic-shooter`
Bilder: 6 Nutzer-Screenshots (Charakter-Fenster, Shop, Sammlung, Karten, Kisten-Overlay, Startseite)

---

## 0. BEFUNDANALYSE (was in den Bildern wirklich kaputt ist)

| # | Nutzer-Beschwerde | Gemessene Ursache im Code | Beweis |
|---|---|---|---|
| 1 | Skin-Wechsel gehört ins Charakter-Fenster | `ui_manager.gd:1709 _create_char_page()` hat **nur** Farb- und Hut-Reihen. Skins leben nur in der SAMMLUNG (`refresh_collection_ui`, ab 3973). | Screenshot 1 (CHARAKTER) zeigt keine Skin-Reihe |
| 2 | Vorschau zeigt Standard statt Auswahl | `refresh_profile_ui()` (2409) setzt `char_preview.texture = tex`, wobei `tex` aus `get_player_texture(col, hat)` kommt — **ohne Skin-Logik**, und der Skin-Zweig sitzt an anderer Stelle. Außerdem wird die Vorschau bei Farbwahl über `refresh_profile_ui()` aktualisiert, das aber `p_rig` nur in der Startseiten-Vorschau berücksichtigt. | Screenshot 1: Vorschau = Standard, Text sagt „Farbe: ROSA" |
| 3 | Shop unsymmetrisch, Kisten langweilig | (a) `_create_shop_page()` nutzt `GridContainer` mit 3 Spalten, aber jede Karte hat **eigene Breite** durch unterschiedlich lange Texte → Ränder ungleich. (b) `_make_chest_icon()` ist ein 16×16-Pixel-Icon, **kein 3D-Kistenkörper**, keine Öffnungs-Animation beim Hover/Klick. (c) „DIREKTKAUF"-Reihe läuft rechts aus dem Bild (Screenshot 2: „KAMPF…" abgeschnitten). | Screenshot 2 |
| 4 | Gold-Symbol hässlich, uneinheitlich | `icon_coin` = `_make_coin_icon()` (617): **zwei weiche Kreise** (`_outlined_disc`), während `heart_full` eine **echte PNG-Datei** ist (`assets/items/heart_full.png`, 16×16 Pixel-Art). Zwei verschiedene Techniken in derselben Icon-Reihe. | Screenshot 2: KOPFGELD = gelber Ring, EXTRA-HERZ = schönes Pixel-Herz |
| 5 | Skin-Auswahl merkwürdig | Skin-Kacheln in der SAMMLUNG nutzen `b3.icon = skin_preview_texture(i)` (120×120-Kachel, 64px-Bild) — kein Rahmen, keine Seltenheitsfarbe, kein Name sichtbar, nur Tooltip. | Screenshot 3: letzte Zeile, winzige Kacheln ohne Beschriftung |
| 6 | Welten-Icons nichtssagend | `_make_map_icon()` zeichnet nur 3 Motive (`tuft`, `cactus`, `ice`, `lava`) auf 8×8-Checker → Erde/Mars/Jungle sehen fast gleich aus, es fehlt die Welt-Identität. `_make_map_icon_volt()` ist ein Blitz. | Screenshot 4: 4 Icons, kein Welt-Bezug |
| 7 | Kacheln der Startseite eckig | `_make_comic_button()` nutzt `set_corner_radius_all(3)` — **fast eckig**. Nutzer will **runden Pixel-Art-Style**. | Screenshot 6: alle Nav-Buttons eckig |

---

## 1. PUNKT 1 — Skin-Auswahl ins Charakter-Fenster

**Ziel:** Alle drei Charakter-Eigenschaften (Farbe, Hut, Skin) an EINEM Ort.

**Umsetzung:**
1. In `_create_char_page()` nach der Hut-Reihe eine **SKIN-Reihe** einfügen:
   - Titel `"SKIN"` + Seltenheits-Hinweis
   - `HBoxContainer` mit einer Kachel je `RIG_NAMES`-Eintrag
   - Kachel = Button mit `skin_preview_texture(i)` (Farbe des Helden), 132×132
   - **Gesperrte Skins**: Silhouette + Schloss-Overlay, Tooltip „im Shop freischalten"
   - **Ausgerüsteter Skin**: goldener Rahmen + „AKTIV"-Marke
2. `skin_buttons: Array` als Member (analog `color_buttons`/`hat_buttons`)
3. `_on_skin_pressed(i)` → `game_manager.set_profile_rig(i)` + `refresh_profile_ui()` + `refresh_skin_buttons()`
4. `refresh_profile_ui()` erneuert die Skin-Kacheln (Rahmen/Aktiv-Marke/Icon)
5. **Die Skin-Reihe wird aus der SAMMLUNG entfernt** (Punkt 5) — dort nur noch Farben + Hüte, die Sammlung verweist auf das Charakter-Fenster

**Risiko:** `p_rig` ist im Profil gespeichert → bleibt erhalten. `set_profile_rig` prüft `unlocked_rigs` → gesperrte Skins bleiben gesperrt.

---

## 2. PUNKT 2 — Vorschau zeigt den gewählten Charakter

**Ursache:** `refresh_profile_ui()` berechnet `tex` über einen Weg, der den Skin nicht konsistent mitnimmt.

**Umsetzung:**
1. **Eine einzige Quelle** für die Charakter-Textur: neue Methode in `ui_manager.gd`
   ```gdscript
   func _current_hero_texture() -> Texture2D:
       # Einzige Wahrheit: Skin (falls >0) in der gewaehlten Farbe, sonst Farbe+Hut
   ```
   → verwendet `game_manager.skin_preview_texture(p_rig, p_color)` bzw. `get_player_texture(col, hat)`
2. `char_preview.texture`, `main_hero_img.texture`, Startseiten-Held und Sammlungs-Vorschau nutzen **alle** diese eine Methode
3. **Live-Vorschau beim Anklicken**: `_on_color_pressed` / `_on_hat_pressed` / `_on_skin_pressed` aktualisieren `char_preview` **sofort** (nicht nur über `refresh_profile_ui()`)
4. `char_name_chip` zeigt jetzt `"Farbe: X · Hut: Y · Skin: Z"` (alle drei)
5. Prüfung: die Kachel in der SAMMLUNG (Zeile 3953) nutzt ebenfalls den Skin → sonst zeigt die Sammlung weiter den Standard

**Test:** Headless — Farbe setzen → `char_preview.texture` muss sich vom Standard unterscheiden; Skin setzen → Textur muss `skin_c%d_s%d` entsprechen.

---

## 3. PUNKT 3 — Shop symmetrisch + Kisten mit Animation

**3a. Symmetrie**
1. Alle 3 Karten bekommen **feste Breite** (`custom_minimum_size.x = 380`) und gleiche Höhe
2. Der Seltenheits-Mix wird **zweizeilig** (Farbleiste), die „+ Verbrauchsgueter"-Zeile entfällt (sie stand doppelt)
3. Die „DIREKTKAUF"-Reihe (Boosts) läuft rechts aus dem Bild → in einen **eigenen `ScrollContainer`** mit fester Höhe, damit sie scrollbar ist statt abgeschnitten
4. Der Shop-Inhalt bekommt eine `ScrollContainer`-Hülle (wie die Sammlung), damit auf kleinen Höhen nichts rausläuft

**3b. Kisten-Design + Animation**
1. `_make_chest_icon()` wird **kein flaches 16×16-Icon**, sondern ein **richtiger Kistenkörper** in Pixel-Art (32×32 Basis, 2× skaliert):
   - 3/4-Ansicht: Deckel schräg, Korpus mit Planken, Metallbänder, Schloss, Nieten, Griff
   - Je Rarität andere Form UND Farbe (Holz eckig, Silber mit Reif, Gold mit Krone/Edelstein)
2. **Öffnungs-Animation**: beim Kaufen läuft eine Sequenz:
   - Truhe schüttelt (Tween-Rotation ±0.12, 3× schnell)
   - **Deckel fliegt auf** (eigene Sprite-Node, fliegt nach oben + rotiert)
   - **Lichtstrahl** (Cone/Gradient-TextureRect) blendet auf
   - Item-Icons fliegen aus der Truhe heraus (Tween auf die Zielposition)
   - Seltenheits-Fanfare: `common` = 3 Funken, `rare` = 8 blaue Funken, `epic` = goldener Blitz + Bildschirm-Flash
3. Die Karten-Icons bekommen einen **Hover-Effekt**: leichtes Anheben (Scale 1.06) + hellere Rahmenfarbe

**Test:** Headless — alle 3 Karten haben dieselbe Breite/Höhe; Animation erzeugt die erwarteten Nodes; Boost-Reihe ist scrollbar (Höhe < Viewport).

---

## 4. PUNKT 4 — Einheitliches Icon-Design (Gold = Pixel-Art)

**Ursache:** `icon_coin` ist prozedural (weiche Kreise), `heart_full` ist eine PNG. Zwei Techniken nebeneinander.

**Umsetzung:**
1. `_make_coin_icon()` wird **neu in Pixel-Art** gezeichnet (16×16, 4× NEAREST), im gleichen Stil wie das Herz:
   - Münze mit Kerbe/Prägung, harte Kanten, dunkle Kontur, 2 Ton-Werte
2. **Zusätzlich** eine echte Datei `assets/items/coin.png` als Backup-Pfad? → Nein, prozedural reicht, solange der Stil passt. **Entscheidung:** prozedural in Pixel-Art, damit keine Import-Pässe nötig sind.
3. **Alle Shop-Items auf dieselbe Technik**: `icon_shield`, `icon_crosshair`, `powerup_rapid` ebenfalls als 16×16-Pixel-Art neu zeichnen (aktuell teils weich, teils PNG)
4. **Regel:** Item-Icons = 16×16 Pixel-Art, 4× skaliert; die `TextureRect`s in der Boost-Reihe bekommen `texture_filter = NEAREST` und feste 64px-Kacheln

**Test:** Pixel-Scan — jedes Item-Icon muss eine 4er-Kantenstruktur haben (alle 4 Nachbarzeilen eines Punktes gleich). Vergleich Herz vs. Münze.

---

## 5. PUNKT 5 — Skin-Auswahl designsicher (ein Ort)

**Umsetzung:** Die Skin-Reihe wandert komplett ins **Charakter-Fenster** (Punkt 1). In der SAMMLUNG:
1. Nur noch **Farben + Hüte** (jeweils eine Kachel-Reihe)
2. Jede Kachel bekommt: Namen unter dem Bild, Seltenheitspunkt oben rechts, „AKTIV"-Marke
3. Die SAMMLUNG bekommt einen Hinweis-Button **„SKINS → CHARAKTER-FENSTER"**
4. Kein Skin-Duplikat mehr in der Sammlung

**Test:** Grid-Zählung — Sammlung enthält 10 + 10 = 20 Kacheln, keine 6 Skin-Kacheln mehr; Charakter-Fenster enthält 6 Skin-Kacheln.

---

## 6. PUNKT 6 — Welten-Icons anschaulich

**Umsetzung:** `_make_map_icon()` bekommt **pro Welt ein eigenes, erkennbares Motiv** in 16×16-Pixel-Art (statt 3 generischer Motive):

| Welt | Motiv |
|---|---|
| ERDE | Landschaft: Hügel, Baum, Himmel, Sonne — mit Wüsten-/Eis-/Lava-Varianten (4 Unter-Motive) |
| MARS | Roter Boden, Krater, Felsbrocken, 2 Antennen/Rover |
| JUNGLE | Dichtes Blattdach, Lianen, Vulkan-Rauch, Banane |
| ELEKTRO | Blitz, Spulen, Kabel, dunkler Stahl (bestehend, aber überarbeitet) |

1. Neue Zeichenroutinen je Welt (`_make_map_icon_earth/mars/jungle/volt`)
2. Die Karten-Seite nutzt sie; die Startseiten-Karte zeigt das **aktive** Welt-Icon in groß (200px, Pixel-Art, NEAREST)
3. `map_data()` liefert den Icon-Key → die Startseiten-Vorschau muss den **Key der aktiven Map** nehmen (nicht `map_meadow`)

**Test:** Für jede Map muss ein eigenes Icon existieren (`get_texture(key) != null`), 64×64, und die Icons müssen sich paarweise unterscheiden (Pixel-Differenz > 30 %).

---

## 7. PUNKT 7 — Runder Pixel-Art-Style für die Kacheln

**Umsetzung:**
1. Neue Stylebox-Familie `_make_pixel_panel_sb(fill, border)`:
   - **Eckige** Pixel-Ecken sind hier richtig (Pixel-Art!), aber mit **abgeschrägten** Ecken (8er-Stufen) → wirkt „rund" ohne weich zu sein
   - 4px-Rahmen, harter 4px-Versatz-Schatten unten rechts
2. Neue Button-Familie `_make_pixel_button(text, fill, font_size)`:
   - `corner_radius = 0`, aber **Pixel-Fase** an den Ecken (1px-Stufen)
   - Fester 4px-Absatz unten (sofortiges Drücken)
3. Umstellung: Startseiten-Nav-Buttons, SAMMLUNG-Kacheln, CHARAKTER-Kacheln, Karten-Icons-Rahmen, Shop-Karten
4. **Nicht** umgestellt (bewusst weich): die Comic-Panels der Modalseiten (Titelrahmen) — dort passt der dicke schwarze Comic-Rahmen besser

**Test:** Screenshots aller Seiten; Kacheln müssen eckig-abgeschrägt wirken, nicht abgerundet-weich.

---

## 8. REIHENFOLGE UND TESTSTRATEGIE

**Reihenfolge** (jeder Punkt einzeln, mit Zwischentest):
1. Punkt 2 zuerst (Vorschau-Quelle zentralisieren) → trägt Punkt 1 und 5 mit
2. Punkt 1 + 5 (Skin ins Charakter-Fenster, Sammlung schlank)
3. Punkt 4 (Icon-Design vereinheitlichen — Voraussetzung für die Optik von 3)
4. Punkt 6 (Welten-Icons)
5. Punkt 7 (Pixel-Kacheln) — als Fundament für 3
6. Punkt 3 (Shop symmetrisch + Kisten-Animation) — nutzt 4, 6, 7
7. Abschluss: Volltest, Screenshots, Doku, APK

**Test-Strategie (2 unabhängige Pässe, wie gefordert):**
- **Numerisch (headless):** Vorschau-Textur == Skin-Textur? Kartenbreiten identisch? Icon-Pixel-raster? Welt-Icons paarweise verschieden? Kachelzählung? Boost-Reihe scrollbar?
- **Visuell (Screenshots + Vision):** alle 6 Seiten prüfen — Symmetrie, Lesbarkeit, Pixel-Kanten, kein Überlaufen

**Doku:** `PLAN_MASTER.md` Abschnitt **AH — RUNDE 43** mit Ursache → Fix → Testevidenz je Punkt.
**Artefakt:** `ComicShooter.apk` + `.idsig` im Projektwurzel, Debug-Fenster mit dem neuen Stand.
