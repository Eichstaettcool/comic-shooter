# SPEC v1.52 — Kisten im Comic-Look, Öffnung mit drei Inszenierungen

Status: `[x]` umgesetzt, belegt · **Stil entschieden: POW-PANEL (2), andere Stile entfernt**

## Ausgangslage

Die Kisten waren 64×64-Pixel-Texturen (`gen_chest_art.gd`), die auf 270–450 px
hochskaliert wurden, und das „Öffnen" war ein **Laufband** (Roulette-Streifen,
4,5–8 s), das auf einem Item stehen blieb. Die Kiste selbst war nur Kulisse: ein
Bildwechsel von `chest_gem_<tier>` auf `chest_gem_open_<tier>` plus ein weißer
Blitz.

Deine Vorgabe: Comic-Look, viele Effekte, Hintergrund darf weg, **die Kiste ist
der Fokus**, drei unterschiedliche Ansätze zum Aussuchen.

## Punkte

### A1 — Kiste wird gezeichnet, nicht skaliert `[x]`

Neue Datei `scripts/ui/chest_view.gd` (`class_name ChestView`): eine `Control`,
die die Truhe komplett in `_draw()` aufbaut — Korpus, Deckel, zwei Eisenbänder,
Schloss, Halbton-Punktraster, Cel-Shading-Kanten, dicke Kontur. Deckel ist ein
eigenes Bauteil mit eigener Transformierung, der Innenraum leuchtet separat.

**Abnahme:** Kiste skaliert verlustfrei auf jede Fenstergröße, gleiche Optik in
Shop-Vorschau und Öffnung.
**Beleg:** `[SHOP][KISTE] tier=standard vorschau=chest_view stil=POW px=270` für
alle drei Stufen · Screenshot `screenshots/v152/shop_kisten.png`.

### A2 — Drei Art-Directions `[x]`

| Stil | Name | Farbwelt | Kontur | Deko |
|---|---|---|---|---|
| 1 | **TUSCHE-KNALL** | Papier-Beige, Holz, Gold | schwarze Tusche | Papier-Halbton im Hintergrund, Tintenspritzer als Partikel |
| 2 | **POW-PANEL** | Rot/Gelb auf Nachtblau | helle Creme-Kontur + dunkle Innenlinie | Ben-Day-Punkte, Strahlenkranz, Comic-Stern |
| 3 | **NEON-CHARGE** | Nachtblau/Cyan/Magenta | Cyan-Kante | Energie-Ringe, Lichtsäule, Glitzerpartikel |

**Abnahme:** Jede Stufe (standard/silver/premium) hat in jedem Stil eine eigene
Palette; Neon bleibt dunkel (Stufe färbt nur das Leuchten).
**Beleg:** `ChestView._pal()` mit `nur_akzent` für Neon · Screenshots
`stil_1_*`, `stil_2_*`, `stil_3_*` (je 5 Zeitpunkte).

### B1 — Drei Öffnungs-Dramaturgien `[x]`

Neue Datei `scripts/ui/chest_open_ui.gd` (`class_name ChestOpenUI`).

| Stil | Aufbau | Dauer | Effekte |
|---|---|---|---|
| 1 Tusche | Einblenden → 2 Ruckler + „KLIRR!" → Deckel klappt → **ein** Knall + Ring + Tintenspritzer + „POW!" → Karte | 2,4 s | 13 |
| 2 Pow | Push-in 55 % → 3 Vorblitze → Stillstand → Rütteln → Knall: Blitz 100 %, Stern, 14 Strahlen, 2 Ringe, „POW!", 46 Partikel, Screen-Shake → Karte schiebt von unten | 2,9 s | 16 |
| 3 Neon | 3 Energie-Ringe bauen auf, Leuchten steigt, Lichtsäule → Deckel auf, Säule schießt hoch, Ring, „ZZZAP!", Strahlen → Karte | 3,2 s | 13 |

Gemeinsam bei allen: **Hitstop 60 ms** im Knall, Vibration (`Input.vibrate_handheld`,
nur mobil), Deckel-Sound je Stufe, Skip per Tipp/ESC.

**Stufen-Dramaturgie (aus der Recherche übernommen):** nicht jede Kiste ist
gleich lang — die Stufe bekommt eine andere *Form*, nicht nur mehr Partikel.
`_tier_extra()` hängt zusätzliche Anticipation-Takte an (Vorblitz + Rütteln +
0,24 s Pause) und verlängert die Haltezeit um 0,3 s je Takt:

| Stufe | Zusatz-Takte | gemessene Dauer (Stil 2) |
|---|---|---|
| standard | 0 | **2,93 s** |
| silver | 1 | ~3,6 s (rechnerisch 0,66 s mehr) |
| premium | 2 | **4,01 s** |

**Beleg:** `[CHESTFX][TAKT] tier=premium zusatz_takte=2` ·
`[CHESTFX][FERTIG] stil=2 dauer=4.01 s effekte=20` ·
standard: `[CHESTFX][FERTIG] stil=2 dauer=2.93 s effekte=16`.

**Abnahme:** Jeder Stil läuft ohne Skriptfehler und endet mit vollständiger
Belohnungskarte, die komplett im Bild liegt.
**Beleg:** `[CHESTFX][FERTIG] stil=1 dauer=2.42 s effekte=13 woerter=2`,
`stil=2 … 2.92 s effekte=16`, `stil=3 … 3.21 s effekte=13` ·
`[CHESTFX][IMPACT] hitstop=0.06 vibration=false sound=chest_open_standard`
(Vibration nur auf Gerät) · `errs=0` in allen drei Testläufen.

### B2 — Hintergrund ist weg `[x]`

Kein Shop, kein Menü, keine Karteileiste: Vollflächen-Hintergrund je Stil
(Papier / Nachtblau / Schwarz), nur Kiste, Effekte und Belohnung.

**Beleg:** Screenshots `stil_1_t0_55.png` … `stil_3_t3_6.png` — im Bild ist
ausschließlich die Kiste plus Effekte zu sehen.

### C1 — Shop-Vorschau nutzt dieselbe Kiste `[x]`

`shop_page.gd` baut statt `TextureRect` einen `ChestView` (270 px) in das
Kistenfenster. Damit zeigt der Shop genau das Objekt, das sich später öffnet.

**Beleg:** `[SHOP][KISTE] tier=silver vorschau=chest_view …` ·
`screenshots/v152/shop_kisten.png` (drei Kisten mittig im Rahmen).

### C2 — Echter Kaufpfad `[x]`

`ui_manager._on_chest_open()` wählt die neue Inszenierung; das alte Laufband
bleibt über `COMIC_CHEST_STYLE=0` erreichbar.

**Beleg:** `[SHOP][KAUF] tier=standard abgebucht=12 gems_vorher=999 nachher=987 ok=true`
→ `[CHEST][PFAD] oeffnung=chest_open_ui stil=standard` →
`[CHESTFX][START] stil=2 tier=standard item=hat_7 rarity=rare` →
`[CHESTFX][FERTIG] stil=2 dauer=2.92 s` · Screenshots `buy_oeffnung.png`,
`buy_karte.png`.

### D1 — Keine Regression `[x]`

**Abnahme:** `tools/golden_check.sh` 8/8 grün.
**Beleg:** `chestfull/upg/shop/mini/loc2/seasons/char/wpn2 … rest_diff=0 script_errors=0`
· „OK: Verhalten unveraendert."

**Anmerkung:** `seasons` hängt am gespeicherten Profil (`season_unlocks`). Nach
den Kisten-Tests war der Zustand „mars hat schon Sommer" gespeichert, dann
verweigert der Test den Wechsel-Modus. Mit dem Referenzzustand
(`season_unlocks: je Planet nur "spring"`, Modus `fixed`) ist der Modus grün —
Wiederherstellung über den Diag-Modus `seasfix`.

## v1.53 — Nutzer-Feedback umgesetzt

### F1 — Nur noch Stil 2 `[x]`

Tusche (1) und Neon (3) sind **gelöscht**, nicht abgeschaltet: `STYLE_FIXED = 2`,
die Funktionen `_anim_tusche`, `_tusche_open`, `_anim_neon`, `_neon_open` gibt es
nicht mehr. `COMIC_CHEST_STYLE=0` bleibt als Notausgang für das alte Laufband.

**Beleg:** `[CHESTFX][SETUP] stil=2 (POW) fest=ja` · `grep _anim_tusche` = 0 Treffer.

### F2 — Ein Tipp pro Seltenheitsstufe `[x]`

Die Kiste öffnet sich **nicht mehr von selbst**. Jeder Tipp legt Effekte zu
(Wackeln, Glühen, Ring, Wort, Partikel), die Kiste bleibt zu:

| Seltenheit | Tipps bis zum Öffnen |
|---|---|
| gewöhnlich | 1 |
| selten | 2 |
| episch | 3 |
| legendär | 4 |

Der Hinweis zählt bewusst **nicht** mit („TIPPEN, UM ZU RÜTTELN"), damit die
Hoffnung auf etwas Selteneres erhalten bleibt.

**Beleg:** `[CHESTFX][TIPP] benoetigt=3 rarity=epic …` ·
`[CHESTFX][TIPP] nr=1 von=3 … kiste=zu` · `nr=2 von=3 … kiste=zu` ·
`[CHESTFX][OEFFNEN] tipps=3 rarity=epic tier=silver`.

### F3 — Episch: länger + eigene Partikel `[x]`

`_rarity_extra()` addiert Anticipation-Takte je Seltenheit (selten 1, episch 2,
legendär 3) **zusätzlich** zu den Stufen-Takten, episch bekommt einen zweiten
Ring, 64 violette Partikel, ein eigenes Wort („EPISCH!") und 0,28 s Atempause.

**Beleg:** `[CHESTFX][TAKT] tier=silver rarity=epic zusatz_takte=3 (stufe 1 + seltenheit 2)` ·
`[CHESTFX][EPIC] rarity=epic ring=2 partikel=64 farbe=b873f2 atempause=0.28` ·
`[CHESTFX][FERTIG] … dauer=4.58 s` gegen gewöhnlich `2.91 s`.

### F4 — Jeder Gewinn zahlt Gold/Edelsteine `[x]`

`CHEST_RARITY_BONUS` in `game_manager.gd`, direkt gebucht (Backend, nicht UI):

| Seltenheit | Gold | Edelsteine |
|---|---|---|
| gewöhnlich | +8 | — |
| selten | +35 | +2 |
| episch | +90 | +6 |
| legendär | +220 | +15 |

**Beleg:** `[CHEST][BONUS] rarity=common gold=+8 gems=+0 gold_stand=100007 gems_stand=987`
· Karte zeigt `+90 GOLD · +6 EDELSTEINE` (Screenshot `epic_5_karte.png`).

### F5 — Item statt Kiste im Ergebnis `[x]`

`_chest_icon_texture()` fällt nicht mehr auf das Kisten-Icon zurück: Hut → Hut-
Textur, Skin → Skin, Farbe → Figur in der Farbe, Gold/Gems → Symbol.

**Beleg:** `[CHEST][ICON] kind=hat index=9 tex=ja eigenes_item=true` ·
`[CHEST][ICON] kind=color index=7 tex=ja eigenes_item=true` ·
Screenshots `buy_karte.png` (KAPPE), `epic_5_karte.png` (STERN, Bonus).

**Hinweis:** Das im Test immer gleiche „STERN" war die **Testvorgabe** im
Diag-Modus (`"name": "STERN", "kind": "hat", "index": 9`), kein Fehler. Acht
echte Kisten beweisen die Streuung:
`["RUCKSACK", "BLAU", "+10 EDELSTEINE", "+25 EDELSTEINE", "GRUEN", "ABZEICHEN", "GRUEN", "GELB"]`
→ 7 verschiedene Gewinne bei 8 Kisten.

### F6 — Kisten der drei Stufen sind unterscheidbar `[x]`

Vorher unterschieden sie sich nur im Farbton. Jetzt eigenes Design:

| Stufe | Korpus | Deko | Schloss |
|---|---|---|---|
| standard | warmes Rot/Holz | Plankenfugen + Eisennägel | Messing |
| silver | Stahlblau | Nieten auf den Bändern | blauer Stein |
| premium | Violett | Goldkante + Goldsteine | lila Stein |

**Keine Zacken mehr** — die drei Goldspitzen auf dem Premium-Deckel wurden als
Fehler gelesen und sind entfernt (zweite Beschwerde zu Zacken nach v1.48/C2).

**Beleg:** `[SHOP][KISTE] tier=standard/silver/premium vorschau=chest_view stil=POW`
· Screenshot `shop_kisten.png`.

### F7 — Dezenter Hintergrund `[x]`

Statt schwarzer Fläche: Verlauf, Halbton-Punkte mit Radial-Fade, diagonale
Speedlines, Rand-Vignette und ein Glow in Raritätsfarbe hinter der Kiste.
Der graue Keil (Lichtkegel + dunkler Stern beim Öffnen) ist entfernt bzw. auf
eine helle Kontur reduziert.

**Beleg:** `[CHESTFX][FX] nr=2 hintergrund stil=2 ebene=backdrop verlauf+halbton+speedlines+vignette`
· Screenshots `epic_2_ruetteln.png`, `epic_5_karte.png`.

## Wie man umschaltet

- Stil ist fest: `ChestOpenUI.STYLE_FIXED = 2` (POW-PANEL).
- `COMIC_CHEST_STYLE=0` schaltet auf das alte Laufband zurück (`chest_ui.gd`).

## Recherche-Grundlage

Zwei Rechercheläufe (Subagenten) liegen bei:
- `project/research/CHEST_ANIM_REFERENZ.md` — 14 Spiele-Referenzen, 25 Effekt-
  Bausteine mit Dauer und Godot-Umsetzung, drei Dramaturgie-Timelines,
  „was billig wirkt".
- `project/research/CHEST_COMIC_LOOK.md` — Comic-Grundlagen (Kontur, Ben-Day,
  Cel-Shading, Speed Lines, Lettering), drei Art-Directions, prozedurale
  Zeichenanleitung, Kontrast-Check für 1080p.

Umgesetzt aus dem Katalog: Fokus-Dim (#1), Push-in (#3), Wind-up-Squash (#5),
Rütteln (#6), Glow (#7), Impact-Frame/Blitz (#11), Screen-Shake (#12),
Squash-Stretch (#13), Deckel-Klappe (#14), Partikel (#15), Speed Lines/Strahlen
(#16/17), Item-Pop (#20), Halte-Moment (#23), Sound (#24), Haptik (#25),
Hitstop (#10).

Nicht umgesetzt (bewusst): Letterbox (#2), Rarity-Beam (#18), Farb-Wash (#19),
Karten-Flip (#21), Count-up (#22) — Kandidaten für die Feinschliff-Runde nach
deiner Stil-Entscheidung.
