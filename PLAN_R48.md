# RUNDE 48 — Plan: Optik & Zentrierung (vor den Game-Bugs)

Reihenfolge strikt einhalten. Nach jedem Schritt: Compile + Screenshot. **Keine Struktur-Umbaue,
die das Fenster zerlegen** (Lesson Learned aus R44/R47).

---

## Analyse der 6 Screenshots (Ist-Zustand)

| # | Nutzer-Punkt | Screenshot-Befund | Technische Ursache |
|---|---|---|---|
| 1 | Shop linksbündig, Kisten zu klein | 3 Kisten links oben, Boost-Grid links darunter, rechte Hälfte komplett leer | `_build_shop()`: `shop_list` in `ScrollContainer` → `shop_wrap` (HBox) → `shop_list` (Grid, 2 Spalten). `shop_list.size_flags_horizontal = SIZE_SHRINK_CENTER` wirkt nicht, weil im `ScrollContainer` der `HBox` volle Breite bekommt und das Grid links klebt. Karten-Icons nur 108×108 in einem 128er-Rahmen → zu klein. |
| 2 | Kisten-Overlay: Items weiß/komisch, unlesbar | "2x VERBRAUCHSGUT + ZWEITES HERZ" überlappt mit zwei Icons; Icons winzig, Text läuft ineinander | `show_chest_result()`: Label + Icons werden in **derselben HBox** platziert, Icons 64px, Label mehrzeilig. Kein Panel je Item. |
| 3 | Char: Mützen nur mit Base-Skin, andere fehlen | Hut-Reihe zeigt **nur Text** (OHNE, KAPPE, …), keine Bilder | `refresh_hat_buttons()` setzt `b.text = HAT_NAMES[i]` — **überschreibt das Icon-Slot-Verhalten**; das Icon wird nie gesetzt. Es gibt keine Hat-Textur mit Skin-Kombination. |
| 4 | Char: Farb-Vorschau immer Base-Skin | Vorschau zeigt Standard-Skin statt NINJA | `_current_hero_texture()` — muss geprüft werden; `cb.icon = TextureManager.get_player_texture(i, hat)` nutzt nur Farbe+Hut, **ohne Skin**. |
| 5 | Sammlung linksbündig, alle Farben grün | Grid links oben, Farben-Kacheln alle grün, keine Bilder | `refresh_collection_ui()` nutzt `_make_pixel_button` **ohne Icon** → grüne Standard-Buttons. Grid hat keinen Center-Wrap. |
| 6 | Karten verschoben, nicht auf gleicher Höhe | ERDE tiefer, MARS/JUNGLE/ELEKTRO höher, Textzeilen unterschiedlich | Karten in HBox ohne `size_flags_vertical = SIZE_FILL` → jede Karte nimmt nur ihre eigene Höhe. |
| 7 | Einstellungen von anderen Seiten nicht erreichbar | Zahnrad nur auf Startseite sichtbar | Gear-Button liegt in `start_screen`; Unterseiten (`_make_page`) verdecken ihn. |

---

## Schritt-für-Schritt

### Schritt 1 — Shop zentrieren + Kisten vergrößern
- `shop_list`: eigene `custom_minimum_size.x` = 1560, `size_flags_horizontal = SIZE_SHRINK_CENTER`
- `shop_wrap` → durch `MarginContainer` ersetzen, Grid mittig
- Kisten-Icon-Rahmen 128 → **210 px**, Icon 108 → **170 px**
- Boost-Grid: 4 Spalten, Zelle 250×250 (Icon 96, Name, Preisbutton)
- Title/Gold-Chip/Subtitle zentriert
- **Test:** Screenshot, Karten symmetrisch, nichts außerhalb

### Schritt 2 — Kisten-Overlay lesbar
- Jedes Item bekommt ein eigenes `PanelContainer` (Icon 96px + Name darunter, eigener Zeile)
- Icons und Text **nicht** in derselben HBox, sondern untereinander
- Seltenheitsfarbe als Rahmen
- **Test:** Screenshot Overlay, keine Überlappung

### Schritt 3 — Hut-Icons im Charakterfenster
- `refresh_hat_buttons()`: Icon **statt** Text setzen (`b.icon = ...`, `b.text = ""`)
- Hut-Textur: Hut auf dem **aktuellen Skin** (`get_skin_texture(color, skin)` + Hut-Overlay) — falls keine Overlay-Textur existiert: Hut auf Standard-Skin, aber mit aktueller **Farbe**
- Aktiver Hut: heller + goldener Rahmen
- Gesperrte Hut: Silhouette
- **Test:** Screenshot, alle 10 Hüte mit Bild

### Schritt 4 — Vorschau zeigt aktuellen Skin
- `cb.icon` (Farbkacheln) = Skin+Farbe-Kombination
- `_current_hero_texture()` prüfen: muss Skin × Farbe × Hut liefern
- **Test:** Skin NINJA + Farbe STAHL → Vorschau zeigt NINJA in STAHL

### Schritt 5 — Sammlung ordentlich
- Grid zentrieren (eigene `HBox`-Zentrierung wie Schritt 1)
- Farbkacheln: **echte Farb-Felder** (ColorRect in der Kachel) statt grüner Buttons
- Header über die volle Breite (eigene Zeile, nicht Grid-Spalte)
- **Test:** Screenshot, 3 Kategorien zentriert, Farben korrekt

### Schritt 6 — Karten auf gleiche Höhe
- Karten-Container: `size_flags_vertical = SIZE_FILL` für alle
- Icon-Bereich fixe Höhe, Text-Bereich darunter
- **Test:** Screenshot, alle 4 Karten oben bündig

### Schritt 7 — Einstellungen von jeder Seite erreichbar
- Gear-Button aus `start_screen` in eine **globale Overlay-Ebene** über alle Seiten
- Klick → `_open_settings_page()` + alle anderen Seiten ausblenden
- **Test:** Klick von Shop/Char/Sammlung/Karten → Einstellungen öffnet

### Schritt 8 — Gesamttest
- Compile `COMPILE_OK`
- Headless-Audit: alle 6 Seiten, Überlauf 0, Klicks (Nav, Skin, Hut, Farbe, Gear)
- Screenshots aller 6 Seiten + Overlay, visuelle Prüfung
- APK-Export

---

## Regeln (aus früheren Runden gelernt)
1. **Keine Anchor-/Container-Experimente** an `_make_page` — die haben R44/R47 zerlegt.
2. Änderungen immer über **exakte Anker** (`s.replace(old, new, 1)`), nie über Zeilennummern.
3. Nach jedem Schritt: `COMPILE_OK` prüfen, dann Screenshot.
4. Bei Fehlschlag: **nicht** weiterreparieren, sondern dem Nutzer schreiben.
5. Keine Test-Hooks im ausgelieferten Code.


---

## ERGEBNIS (Runde 48 abgeschlossen)

### Behobene Punkte (Nutzer-Feedback mit Screenshots)

| # | Punkt | Ursache | Fix |
|---|---|---|---|
| 1 | Shop linksbündig, Seite wirkt leer | `ScrollContainer` streckt Kinder auf volle Breite; Karten-Grid direkt in der VBox | Beide Grids in zentrierenden HBox-Wrapper (`crow_wrap`, `brow_wrap`) |
| 2 | Kisten zu klein | Icon-Rahmen 340x128, Icon 108px | Rahmen 400x170, Icon 150px, Karte 430x296 |
| 3 | Items weiss/komisch, unlesbar | alles in EINEM Label; fliegende Items blieben liegen | Item = eigenes Pixel-Panel (Icon 128px + Text 480px); fliegende Items blenden aus |
| 4 | Mützen nur mit Base-Skin | Hut-Textur nur fuer Base-Skin; `refresh_hat_buttons` setzte nur Text | `_draw_hat()` herausgeloest -> `get_skin_hat_texture(color, skin, hat)` |
| 5 | Farb-Vorschau immer Base-Skin | `get_player_texture(i, hat)` ohne Skin | `get_skin_hat_texture_or_player()` fuer Vorschau + Farbkacheln |
| 6 | Sammlung linksbündig, alles gruen | Grid in VBox; Farb-Kacheln ohne Icon | 3 Sektionen (FARBEN/SKINS/HUETE) mit eigenem Header + zentriertem Grid; echte Helden-Bilder |
| 7 | Karten versetzt | Karten ohne feste Hoehe | alle 320x700, Icon-Flaeche 296x156, feste Status-/Jahreszeiten-Zeilen |
| 8 | Einstellungen nicht erreichbar | `_open_settings_page` blendete nur `char_page` aus | `_close_pages()` + `move_child` nach vorn + Gear `z_index=200` |
| 9 | Seiten stapelten sich | `_open_char_page` versteckte nur `settings_page` | alle `_open_*_page` nutzen `_close_pages()` |
| 10 | Startseiten-Icons leer | Icon-Key war `"lan"` statt `"nav_lan"` | Prefix ergaenzt; Kachel = Control + Icon-Node + Klick-Button |
| 11 | Kisten alle gleich aussehen | nur Farbe unterschiedlich | eigene Designs: `_make_chest_wood_icon` / `_make_chest_silver_icon` / `_make_chest_gold_icon` |
| 12 | Animation wirbelig, Items liegen | Items flogen zufaellig, blieben liegen; 2. Animations-Block | NEUE Animation (Clash-Royal-Stil): Buehne -> Deckel springt weg -> Burst -> Items sprudeln in Bogen -> fallen auf ihre Icon-Kachel -> Zeile erscheint. Alter Block entfernt. |

### Kisten-Ablauf (neu)

```
KAUFEN + OEFFNEN (Shop)
  -> Fenster "KISTE VERWENDEN" (Truhe mittig, eigener Button "OEFFNEN (N Gold)")
  -> Klick auf OEFFNEN
  -> Animation: Truhe bebt+waechst, Deckel springt weg, Burst, Items sprudeln
  -> Fenster "KISTE GEOEFFNET" mit Item-Liste (jede Zeile mittig, Icon+Text)
  -> WEITER
```

### Test (headless, v98)

- Alle 6 Seiten: `max_y=1080, ausserhalb=0`
- Karten: `[700, 700, 700, 700]`
- Hut-Klick -> `p_hat=5`; Skin-Klick -> `p_rig=4`
- Einstellungen von der Kartenseite: `true`
- Bestaetigungs-Fenster: `mode=confirm`
- Item-Zeilen: `mitte_x=960` (exakt Bildschirmmitte), `sichtbar=true`


### Kisten-Fenster: keine dauerhaften Hintergruende (Nachpruefung)

- Der statische, dauerhaft rotierende `ChestBurst` (95 % Deckkraft) stand
  immer im Bild hinter der Truhe -> **entfernt**.
- Der Licht-Balken (240x240 ColorRect) ragte in die Item-Liste ->
  jetzt 200x110, sitzt ausschliesslich ueber der Truhen-Oberkante.
- Der alte zweite Animations-Block in `show_chest_result` (Truhe weg,
  Ergebnis-Icon poppt auf) -> **entfernt**. Die Item-Liste traegt jetzt
  das Ergebnis, das grosse Icon bleibt aus.
- Verifiziert in `compare/v99/04_ergebnis.png`: keine Reste, Item-Zeilen
  exakt in der Bildschirmmitte (mitte_x = 960), Icons 128 px, Text 32 px.


### Item-Zeilen: kompakt statt mit leerem Rand (v100)

- Das Label hatte eine feste Breite von 480 px, wodurch links in der
  Zeile ein leerer Raum stand (nur der Icon, dann Text).
- Jetzt: Zeile schrumpft auf Icon + Text (692 px), Label 520 px,
  `AUTOWRAP_OFF` (Text bleibt einzeilig), Icon-Kachel `SHRINK_CENTER`.
- Das grosse Ergebnis-Icon (Herz/Muenz-Ball) oben im Fenster bleibt
  ausgeblendet - die Item-Liste traegt das Ergebnis.
- Verifiziert in `compare/v100/02_ergebnis.png`:
  Zeilen `mitte_x=960`, Breite 692, Icon links am Text, kein Rest.


### Kisten-Fenster: Zentrierung der Item-Zeilen (v101)

Aus dem Nutzer-Screenshot (19:44) abgeleitet:
- Die Item-Zeilen waren **linksbuendig und unterschiedlich breit**
  (`chest_item_box` ist ein VBoxContainer - dessen Kinder werden ohne
  Alignment linksbuendig platziert).
- Fix: `chest_item_box.alignment = ALIGNMENT_CENTER`, jede Zeile
  feste Breite 760 px + `SHRINK_CENTER`, Icon-Kachel `SHRINK_CENTER`,
  Label `EXPAND_FILL` (Text fuellt den Rest der Zeile).
- Panel-Hoehe 960 -> 848 px (250 px Leerraum entfernt), Buehne 250 -> 230.
- Icon-Kachel 118 px, Icon 106 px (kein weisser Rand mehr).

Messwerte v101: WEITER-Button 440 px bei x=740, Panel 1400x848,
Item-Zeilen 760 px, exakt mittig (mitte_x = 960).
