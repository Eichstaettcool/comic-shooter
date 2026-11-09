# SPEC_V136 — Shop, Glückswalze, Kistenanimation, Charakterfenster, Mini-Bosse

Ziel-Version **v1.36**. Projekt `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Ablage: Diese Datei ist der Arbeitsplan. Reihenfolge unten abarbeiten, Status
nachtragen: `[ ]` offen · `[~]` läuft · `[x]` fertig + belegt.

**Grundregel für alle Punkte:** jeder neue Pfad loggt
`[MODUL][AKTION] … werte` / `[MODUL][FEHLER] … ursache`.
Ohne Log-Zeile oder Screenshot gilt ein Punkt als offen.

Die Bilder, auf die sich die Punkte beziehen, liegen in `screenshots/v136/`
(aus den Handy-Screenshots des Nutzers: 01-charakter-ist, 02-kiste-ist, 03-shop-ist, 04-walze-ist).

**Blöcke:** A Shop · B Glückswalze · C Kistenanimation · D Charakterfenster ·
E Mini-Bosse · **G Kisten-Sound (hoch)** · **H Endlos-Upgrade-Toast (hoch)** ·
**I Jahreszeiten/Karten mit Gold (mittel)** · F Build/Doku.

---

## A — Shop-Seite aufwerten

Ist-Zustand (Screenshot 194853): flache Farbflächen, Umtausch ohne Bild,
Kistenreihe oben angeschnitten, „ZURÜCK" oben links nur an wenigen Pixeln
klickbar.

### A1 — Umtausch Gold → Edelstein mit Piktogrammen  `[x]`
Die Karten aus `_gem_card()` (ui_manager.gd:4440) zeigen heute nur Text
(„1000 GOLD → 1 EDELSTEIN"). Neu, je Karte in einer Zeile:

```
[Goldmünze 72px]   1.000 GOLD   ➜   1  [Edelstein 72px]
```
- Icons aus `TextureManager`: `slot_gold3` (Gold), `slot_gem1/2/3` (Edelstein).
- Beträge groß (34 px), Einheiten klein darunter, Pfeil als eigener Block.
- Der UMTZAUSCHEN-Knopf bleibt, bekommt aber Gold-/Gem-Symbol passend zur Karte.

**Abnahme:** Screenshot der Shop-Seite, auf dem beide Karten ein Gold- und ein
Edelstein-Piktogramm tragen; Log `[SHOP][CARD] gem idx=0 gold=1000 gems=1 icons=gold,gem`.

### A2 — Flächen und Knöpfe „flashiger"  `[x]`
Kein flaches Rechteck mehr. Jede Karte (Kisten, Umtausch, Sofortkauf) bekommt:
- Zweifarb-Verlauf (oben hell, unten dunkel) statt einer Farbe,
- 5 px Kontur + harter Versatzschatten (Comic-Look wie im Rest des Spiels),
- farbige Akzentkante links (4–8 px) in der Kartenfarbe hell,
- Icon-Chip oben links in der Karte,
- Hover: Fläche +12 % heller, Schatten verschiebt sich um 2 px (Knopf „drückt").

**Abnahme:** Screenshot vorher/nachher als Kontaktblatt
`screenshots/230-shop-karten.png`; kein Kartenrechteck ohne Verlauf.

### A3 — ZURÜCK-Knopf: ganze Fläche muss tippen  `[x]`
Symptom: der obere ZURÜCK (ui_manager.gd:4128, Position 40/26, 210×68) sieht
groß aus, reagiert aber nur auf einem winzigen Bereich.

Zu prüfen und zu beheben (in dieser Reihenfolge):
1. Wird der Knopf von einem später hinzugefügten Kind überdeckt
   (`scroll` beginnt bei y≈26, `box` liegt darüber)? → Knopf als **letztes**
   Kind anhängen und `z_index = 10` setzen.
2. `mouse_filter` der Nachbarn (ScrollContainer, `box`, Banner) auf
   `MOUSE_FILTER_IGNORE` bzw. `PASS` prüfen.
3. Trefferfläche unabhängig von der Darstellung: ein unsichtbarer
   `Button`-Streifen (0,0)-(260,110) oder `custom_minimum_size` + `size` auf
   beiden Achsen setzen.

**Abnahme:** Klicktest an 5 Punkten (4 Ecken + Mitte des sichtbaren Knopfes)
schließt die Seite 5×; Log `[SHOP][BACK] treffer=(x,y) -> geschlossen`.
Zusätzlich: derselbe Test für den unteren ZURÜCK.

### A4 — Kistenreihe startet vollständig sichtbar  `[x]`
Oben ist die Kistenzeile angeschnitten (nur die Unterkante sichtbar).
Der Scrollbereich muss unter Titel + Statusleiste beginnen und die erste Karte
vollständig zeigen (Scroll-Startwert 0, Innenabstand oben ≥ 24 px).

**Abnahme:** Screenshot zeigt die vollständige Kistenkarte mit Bild, Titel und
Preis; `scroll.scroll_vertical == 0` im Log beim Öffnen.

---

## B — Glückswalze: Gewinnschema statt Chancen

Ist-Zustand (Screenshot 194857): Tabelle „SYMBOL · 3 GLEICHE · CHANCE" mit
Prozentwerten. Der Nutzer will **keine** Chancen sehen, sondern ab wann es
Gewinn gibt.

### B1 — Tabelle durch „SO GEWINNT MAN" ersetzen  `[x]`
Der Block aus `_build_odds()` (slot_ui.gd) wird ersetzt. Inhalt = nur
Gewinnkombinationen, je Zeile: Symbol(e) · Bedingung · Auszahlung.

```
🍒 2 Kirschen           2,1× Einsatz
🍒🍒🍒 3 Kirschen        7,3× Einsatz
🔔 2 Glocken            1,0× Einsatz
🔔🔔🔔 3 Glocken        14,7× Einsatz
▮ 2 Balken              1,6× Einsatz
▮▮▮ 3 Balken           22,0× Einsatz
🪙 3 Münzen            45,0× / 151,9×
```
- Quelle: `SlotMachine.PAYTABLE` / `PAYTABLE_TWO` (`odds_table()` liefert die
  Werte schon; `chance3`/`chance2` bleiben unbenutzt).
- Reihenfolge aufsteigend nach Auszahlung, damit „2 Kirschen" oben steht.
- Kein Totenkopf, keine Prozentzahlen, kein „Trefferquote gesamt".
- Layout: 2 Spalten × 4 Reihen im selben Panel (Platz ist da), Icons 40 px.

**Abnahme:** Screenshot `screenshots/231-walze-gewinnschema.png`; im Bild
kommt das Wort „%" nicht vor; Log `[SLOT][UI] Gewinnschema: 7 Zeilen`.

### B2 — Verständlichkeit prüfen  `[x]`
Zusätzlich unter dem Schema eine Zeile:
„GEWINN AB 2 GLEICHEN VON LINKS · MITTE ZÄHLT".
**Abnahme:** im Screenshot lesbar, Zeile vorhanden.

---

## C — Kistenanimation ohne Freeze

Ist-Zustand: Deckel öffnet, dann steht das Bild ~0,3 s, dann läuft das Band an;
mittendrin ein weiterer Halt.

### C1 — Zwischenstopp im Laufband entfernen  `[x]`
In `chest_ui.gd::_animate()`:
- `var stop_t` + `_tween.tween_interval(stop_t)` (Runde 123) ersatzlos streichen.
- Stattdessen durchgehend eine Kurve: Phase 1 `TRANS_QUAD/EASE_IN` 0,45 der
  Zeit, dann nahtlos `TRANS_CUBIC/EASE_OUT` für den Rest (kein Interval).

**Abnahme:** Log ohne „Stop": `[CHEST][SPEED] durchgehend 1 Phase1 45% + Phase2 55%`.

### C2 — Kein Loch zwischen Deckel und Band  `[x]`
Das `tween_interval(0.24)` nach `_flash` entfällt; der Bandstart wird im
selben Tween direkt nach dem Blitz gestartet (Überlappung 0,05 s erlaubt).

**Abnahme:** 12 Frames im Abstand von 0,1 s aus dem Bandfenster extrahieren
(`COMIC_LANTEST=chestseq`), per Pixelvergleich: **kein** Paar aufeinander
folgender Frames ist im Bandfenster identisch.

### C3 — Dauer und Dynamik bleiben  `[x]`
Gesamtdauer weiter `randf_range(4.5, 8.0)` (D2), zwei Geschwindigkeitsphasen
bleiben (D3) — nur ohne Stillstand.
**Abnahme:** 10 Öffnungen loggen Dauern alle in 4,5–8,0 s.

---

## D — Charakterfenster komplett neu

Ist-Zustand (Screenshot 194833): drei lange Reihen (10 Farben, 29 Hüte, 24
Skins) untereinander, Vorschau klein oben, unübersichtlich.

### D1 — Neues Layout  `[x]`
Fenster `CHARAKTER` in 1920×1080, ohne Scrollen:

```
┌──────────────────────────────────────────────────────────────┐
│ CHARAKTER                                        🪙 1.754.190 │
│                                                              │
│  ┌────────────┐        ┌──────────────────────────────┐      │
│  │  FARBE     │        │                              │      │
│  │  [Pikto]   │        │      FIGUR (gross, 420 px)   │      │
│  │  LILA      │        │      mit Hut + Skin          │      │
│  ├────────────┤        │                              │      │
│  │  HUT       │        │  NAME: HELD                  │      │
│  │  [Pikto]   │        │  FARBE: LILA                 │      │
│  │  STERN     │        │  HUT: STERN                  │      │
│  ├────────────┤        │  SKIN: MARS-MARSCHALL        │      │
│  │  SKIN      │        │                              │      │
│  │  [Pikto]   │        │  10/10 Farben · 12/29 Hüte   │      │
│  │  MARS-...  │        │  16/24 Skins                 │      │
│  └────────────┘        └──────────────────────────────┘      │
│                    [ ZURÜCK ]                                 │
└──────────────────────────────────────────────────────────────┘
```
- Figur rechts **mittig** im Bild, groß (≥ 420×420), mit Hut und Skin.
- Links drei Felder (je ~380×150) untereinander, Abstand 18 px.
- Jedes Feld: Piktogramm (96 px) links, rechts zweizeilig LABEL + Wert.
- Das zuletzt geöffnete Feld ist hervorgehoben (Rahmen in Seltenheitsfarbe
  des Items).

**Abnahme:** Screenshot `screenshots/232-char-neu.png`; Figur ≥ 400 px hoch,
drei Felder vorhanden, kein Scrollbalken.

### D2 — Felder mit den aktuell gewählten Items  `[x]`
Piktogramme:
- **FARBE:** Figur in dieser Farbe ohne Hut (bestehende Textur
  `get_skin_texture(color_idx, rig)`).
- **HUT:** `TextureManager.get_hat_only_texture(idx)`.
- **SKIN:** Figur im Rig ohne Hut.

**Abnahme:** Log `[WAHL] feld=hut pikto=stern idx=29`.

### D3 — Auswahlfenster nur mit freigeschalteten Items  `[x]`
Klick auf ein Feld öffnet ein Overlay (eigene Seite, oben Titel
`FARBE WÄHLEN` / `HUT WÄHLEN` / `SKIN WÄHLEN`):
- Grid 5 Spalten × n Reihen, Kachel 150×150 mit Piktogramm + Name + Seltenheitsrahmen.
- **Nur freigeschaltete** Items (`unlocked_colors` / `unlocked_hats` / `unlocked_rigs`).
- Antippen wendet sofort an, schließt das Overlay, aktualisiert D1.
- Oben rechts `ZURÜCK` + Zähler „12 / 29 freigeschaltet".
- Gesperrte Items erscheinen hier **nicht** (nur in SAMMLUNG).

**Abnahme:** Bei frischem Profil (nur 2 Hüte frei) zeigt das Hut-Fenster genau
2 Kacheln; Log `[WAHL] feld=hut frei=2 gesamt=29`.

### D4 — Sammlung bleibt vollständig  `[x]`
`show_collection()` zeigt weiterhin **alle** Items, gesperrte gedimmt mit
Schloss. Kein Umbau nötig, nur prüfen, dass die neue Auswahl nichts verändert.

**Abnahme:** Screenshot Sammlung, gesperrte Kacheln sichtbar gedimmt.

### D5 — Aufräumen  `[x]`
Die alten Reihen (`FARBE`/`HUT`/`SKIN`-HBoxen mit allen Kacheln) und der
Namens-Editor wandern in das neue Layout bzw. entfallen. Keine toten Variablen
(`char_preview`, `char_name_chip` weiterverwenden).

**Abnahme:** `--check-only` ohne Fehler, im Spiel keine Warnung
„Identifier not declared".

---

## E — Mini-Bosse spawnen

Ist-Zustand: `monster_ai.gd` kennt `is_mini_boss()` + eigenes Angriffsmuster
(`_mini_boss_pattern`), aber **niemand spawnt sie**. Im Spawner
(`monster_spawner.gd`) gibt es nur `_spawn_monster_wave()`.

### E1 — Spawn-Regel  `[x]`
In `monster_spawner.gd`:
- Ab Welle 3: pro Welle 1 Mini-Boss, maximal 1 gleichzeitig auf der Karte.
- Spawn-Position wie Wellen-Gegner (im Sichtbereich, aber ≥ 420 px vom Spieler).
- Typ zufällig aus den vorhandenen Mini-Boss-Typen (siehe `is_mini_boss()`).
- Health-Balken + Name wie beim großen Boss.

**Abnahme:** Log `[SPAWN][MINIBOSS] typ=… welle=3 pos=(x,y) dist=… abstand_ok=true`
und ein Screenshot mit sichtbarem Mini-Boss + HP-Balken.

### E2 — Balancing  `[x]`
HP ≈ 6× Normalgegner, Schaden wie Normalgegner +1, Belohnung 5× Gold,
garantiert 1 Kisten-Drop.

**Abnahme:** 60-s-Testlauf, Log-Zeile `[SPAWN][MINIBOSS] kill nach Xs, gold=+N`.

### E3 — Kein Doppel-Spawn  `[x]`
Solange einer lebt, kein weiterer. Nach Tod frühestens in der nächsten Welle.

**Abnahme:** Log `[SPAWN][MINIBOSS] blockiert (lebt noch)` wenn versucht wird,
einen zweiten zu setzen.

---

## G — Kisten-Sounddesign (hohe Prio)

Ist-Zustand: `SoundManager` hat genau **einen** Kistensound
(`_streams["chest"]`, ein 0,3-s-Sweep) — er passt zu keiner Phase der
Reveal-Animation. Kisten klingen beim Öffnen beliebig.

### G1 — Geräusch pro Phase  `[x]`
In `sound_manager.gd` (alle prozedural, wie die übrigen Sounds, 22050 Hz mono):

| # | Key | Phase / Trigger in `chest_ui.gd` | Klang |
|---|---|---|---|
| 1 | `chest_lock` | `_animate()` Start | kurzes Rasseln/Zahnrad, 0,35 s (`_gen_ratchet`) |
| 2 | `chest_open_<tier>` | `_flash(tier)` Deckel auf | dumpfer Knall + Luft, 0,45 s, je Stufe höher: standard tief, silver mittel, premium hell + Glanz |
| 3 | `chest_tick` | pro 6. Kachel im Laufband (alle ~0,1 s im schnellen Teil) | trockener Klick, sehr kurz (0,03 s), leise (−16 dB) |
| 4 | `chest_tick_slow` | im Auslauf-Teil (letzte 20 %) | gleicher Klick, halbe Tonhöhe, damit man das Langsamerwerden hört |
| 5 | `chest_land` | Einrasten (`_tween_callback` nach dem Zurückschwingen) | sattes „Klack" + kurzer Bass, 0,2 s |
| 6 | `chest_win_<rarity>` | `_reveal()`, je Seltenheit | common: 2 Töne · rare: 3 Töne · epic: 4 Töne aufsteigend · legendary: Fanfare 0,8 s mit Becken-Noise |
| 7 | `chest_none` | `_reveal()` bei `kind == "none"` | absteigender 2-Ton, enttäuscht |

Regeln:
- Kein Sound doppelt pro Frame; `chest_tick` nur, wenn der Streifen wirklich
  läuft (`spinning`).
- Gesamtlautstärke: Kiste nie lauter als `hurt`; `_streams` mit −8 dB wie üblich.
- Fehlt ein Key, loggt `SoundManager.play()` `[SND][FEHLER] key=… fehlt` statt
  still zu schweigen.

**Abnahme:** Log beim Öffnen einer Premium-Kiste enthält in dieser Reihenfolge
`[SND] chest_lock`, `[SND] chest_open_premium`, ≥ 3× `chest_tick(_slow)`,
`[SND] chest_land`, `[SND] chest_win_legendary`. Jede Zeile nur 1× (tick ausgenommen).
**Zusatz:** 4 WAV-Exporte als Hörprobe nach `screenshots/v136/snd/` (2 s).

---

## H — Endlos-Modus: Upgrade-Hinweis statt Spielstopp (hohe Prio)

Ist-Zustand: im Endlos-Modus (`game_mode == 0`) ruft `_open_upgrade_ui()` sofort
`get_tree().paused = true` + `show_upgrade_cards()` — mitten im Kampf, ohne
Vorwarnung, und mit mehreren offenen Upgrades weiß man nicht, wie viele noch
kommen.

### H1 — Kleines Hinweisfenster (Toast)  `[x]`
Beim Verdienen eines Upgrades **kein** Pause, sondern ein Toast:

```
┌───────────────────────────┐
│  ⬆  2 UPGRADES VERFÜGBAR  │   ← 380 × 96, unten mittig, y ≈ 940
│      ANTIPPEN             │
└───────────────────────────┘
```
- Erscheint mit Pop (scale 0,8 → 1,0, 0,18 s), pulsiert danach leicht (±3 %).
- **Bleibt stehen**, bis der Spieler tippt (kein Timeout — im Kampf verpasst
  man sonst alles). Zähler zählt hoch, wenn ein weiteres Upgrade dazukommt.
- Spiel läuft weiter (`get_tree().paused` bleibt `false`).
- Erneutes Verdienen während der Toast steht: nur Zähler +1, kein zweiter Toast.

**Abnahme:** Log `[UPG][TOAST] verfuegbar=2 paused=false`;
Screenshot `screenshots/233-upgrade-toast.png` mit laufendem Spiel dahinter
(Monster sichtbar bewegt zwischen zwei 0,5 s auseinanderliegenden Frames).

### H2 — Kartenfenster erst auf Tipp, mit Zähler  `[x]`
Tipp auf den Toast → `show_upgrade_cards()`. Im Fenster oben:
`UPGRADE 1 VON 2` (bzw. `NOCH 2 VERFÜGBAR` nach der Wahl), unten klein
„nach der Wahl geht es sofort weiter".
- Pause erst **jetzt** (Einzelspieler). Im Co-op gilt weiter B3: keine Pause,
  Wählender ist unverwundbar.
- Nach der Wahl: schließt, `pending_upgrades -= 1`; ist noch etwas offen,
  erscheint der Toast sofort wieder mit dem Rest, sonst verschwindet er.
- Wellen-Modus (`game_mode == 1`) bleibt unverändert (keine Karten).

**Abnahme:** Bei 2 verdienten Upgrades: erst Toast „2 UPGRADES VERFÜGBAR" →
Klick → Titel „UPGRADE 1 VON 2" → Wahl → Toast „1 UPGRADE VERFÜGBAR" →
Klick → Titel „UPGRADE 1 VON 1" → Wahl → Toast weg.
Log `[UPG][WINDOW] offen idx=1 von 2` / `[UPG][DONE] rest=0`.

### H3 — Kein Fenster über dem Tod  `[x]`
Stirbt der Spieler, während der Toast steht, wird der Toast entfernt und kein
Kartenfenster mehr geöffnet.
**Abnahme:** Log `[UPG][TOAST] entfernt (run vorbei)`.

---

## I — Jahreszeiten und Karten mit Gold freischalten (mittlere Prio)

Ist-Zustand: Jahreszeiten hängen an einem **XP-Gate** (`gate: {type:"xp",
need: 1500/2500/3500}`), geschaltet wird pro Planet in der Map-Auswahl
(`ui_manager.gd:5504 ff.`), ein Wechsel-Modus existiert nur als automatischer
`SEASON_STEP`-Takt im Run und ist nicht steuerbar.

### I1 — Freischaltung mit Gold  `[x]`
- `SEASONS`-Einträge bekommen `price` (Gold) statt `gate.xp`:
  FRÜHLING 0 · SOMMER 2.500 · HERBST 6.000 · WINTER 12.000.
- Kauf in der Map-Auswahl: Knopf zeigt Kosten, Klick zieht Gold ab, speichert
  in `season_unlocks[planet]`, Log
  `[SEASON][KAUF] planet=mars season=summer preis=2500 gold_vorher=… gold_nach=…`.
- Zu wenig Gold: Meldung „ZU WENIG GOLD (2.500 NÖTIG)", kein Abzug.
- Startzustand: **nur FRÜHLING** frei (bereits so); ohne Kauf ist jede andere
  Jahreszeit gesperrt und nicht anwählbar.
- Karten selbst behalten ihre Gold-Preise (6.000 / 12.000 / 20.000); das
  XP-Gate der Karten bleibt als *zusätzliche* Bedingung, damit der Grind bleibt.

**Abnahme:** Frisches Profil: alle drei Nicht-Frühling-Jahreszeiten zeigen
Schloss + Preis; nach Kauf mit genug Gold ist genau diese frei, Gold ist um
den Preis kleiner. Log-Zeile wie oben.

### I2 — Modus pro Karte: FEST / WECHSELND  `[x]`
In der Map-Auswahl je Planet ein Umschalter mit zwei Feldern:

| Modus | Verhalten |
|---|---|
| **FEST** | die gewählte Jahreszeit bleibt den ganzen Run über |
| **WECHSELND** | Jahreszeit wechselt im Run weiter im `SEASON_STEP`-Takt — aber **nur durch die freigeschalteten** Jahreszeiten dieses Planeten |

- Ist nur eine Jahreszeit frei, ist WECHSELND ausgegraut mit Hinweis
  „erst eine zweite Jahreszeit freischalten".
- Gewählter Modus wird pro Planet gespeichert (`season_mode[planet]` =
  `"fixed"` / `"cycle"`), landet im Profil-Save und im LAN-Init, damit Host und
  Client dieselbe Jahreszeit sehen.
- Log beim Run-Start: `[SEASON][MODE] planet=mars modus=cycle pool=[spring,summer]`.

**Abnahme:** Auf Mars mit Sommer+Frühling frei: WECHSELND startet, im Run
wechselt die Jahreszeit mindestens 1× innerhalb von 60 s und **nie** auf Herbst
oder Winter (Log `[SEASON][WECHSEL] von=spring nach=summer`). Mit nur Frühling
frei ist der Knopf deaktiviert.

### I3 — Anzeige im Run  `[x]`
Im HUD (oben mittig, wo der Map-Name steht) zeigt der Modus WECHSELND die
aktuelle Jahreszeit + „als Nächstes: …". Beim Wechsel kurzer Banner
(`show_banner`) mit Jahreszeiten-Namen in ihrer Farbe.

**Abnahme:** Screenshot `screenshots/234-seasons-hud.png`.

---

## J — Waffen mit Seltenheitsstufen

Ist-Zustand: fünf Waffen (`WEAPON_DATA` in `player_controller.gd`), alle mit
festen Werten, kein Stufenunterschied. Eine Waffe ist immer gleich gut.

### J1 — Seltenheit beim Aufnehmen  `[x]`
Jede Waffe, die im Run aufgenommen wird, bekommt eine Stufe:
**gewöhnlich · selten · episch · legendär**. Gewichte 62 / 26 / 9 / 3 %.
- Stufe wird **beim Aufnehmen** gerollt (nicht beim Spawn), damit dieselbe
  Waffe im nächsten Run anders sein kann.
- Die Stufe bleibt für diesen Run an dieser Waffe (Umschalten ändert sie nicht).
- Anzeige: Farbe nach Stufe im Waffen-HUD (grau / blau / lila / gold) + Stern.
- Log `[WPN][DROP] waffe=shotgun seltenheit=epic schaden=… tempo=… mag=…`

**Abnahme:** Log-Zeile oben, und 200 Aufnahmen zeigen alle vier Stufen
(`[WPN][DROP] verteilung common=124 rare=52 epic=18 legendary=6`).

### J2 — Abgestufte Eigenschaften  `[x]`
Je Stufe multiplikativ auf die Basiswerte der Waffe:

| Stufe | Schaden | Nachladezeit | Magazin | Projektiltempo |
|---|---|---|---|---|
| gewöhnlich | ×1,00 | ×1,00 | ×1,00 | ×1,00 |
| selten | ×1,18 | ×0,92 | ×1,15 | ×1,05 |
| episch | ×1,40 | ×0,84 | ×1,30 | ×1,10 |
| legendär | ×1,70 | ×0,74 | ×1,50 | ×1,18 |

- Werte in **einer** Tabelle (`WEAPON_RARITY`), nicht an den Waffen verstreut.
- Nachladezeit und Magazin wirken auch auf die HUD-Anzeige.
- Log `[WPN][RARITY] stufe=legendary schaden=1.70 reload=0.74 mag=1.50 speed=1.18`

**Abnahme:** Log `[WPN][STATS] waffe=revolver stufe=epic schaden=31 reload=1.9 mag=7`
(aufgenommene Waffe stimmt mit Tabelle × Basiswert überein).

### J3 — Bestehende Waffen neu balancieren  `[x]`
Die fünf Waffen bekommen eine klare Rolle statt „alle ähnlich":
Pistole (Allrounder) · Schrotflinte (Nahkampf, Streuung) · Maschinenpistole
(Feuerrate, wenig Schaden) · Laser (durchschlagend, langsam) · Revolver
(Treffer, langsam, hoher Schaden).
- DPS über 30 s simulieren, Zielkorridor: keine Waffe mehr als **1,35×** über
  oder unter dem Mittel der fünf.
- Log `[WPN][BALANCE] waffe=… dps=… (Mittel=…) faktor=…`

**Abnahme:** Log-Tabelle mit fünf Zeilen, alle Faktoren in 0,74–1,35.

### J4 — Anzeige und Aufnahme  `[x]`
- Waffen-HUD und Waffen-Stats-Seite zeigen Stufe + Farbe.
- Beim Aufnehmen: Banner `SCHROTFLINTE · EPISCH`.
- Log `[WPN][PICKUP] waffe=shotgun stufe=epic dps=48.2`

**Abnahme:** Screenshot `screenshots/236-waffen-stufen.png` (vier Stufen in
vier Farben nebeneinander).

---

## K — Spielsprache Deutsch / Englisch

Ist-Zustand: alle Texte stehen hart im Code (deutsch), es gibt keine
Spracheinstellung.

### K1 — Übersetzungsschicht  `[x]`
Neues Autoload `Loc` (`project/scripts/loc.gd`):
- `Loc.t(text)` übersetzt einen deutschen String über ein Wörterbuch `DE_EN`.
- `Loc.apply_tree(node)` läuft rekursiv über `Label`, `Button`, `LineEdit`
  (Placeholder) und `RichTextLabel` und ersetzt jeden Treffer — so muss nicht
  jede der hunderten Textstellen einzeln angefasst werden.
- Fehlt ein Eintrag, bleibt der deutsche Text (kein leerer Bildschirm).
- Log `[LOC][T] fehlt="…"` je fehlendem Schlüssel (nur einmal).

**Abnahme:** `[LOC][SET] sprache=en texte=312 uebersetzt=248 fehlend=64`.

### K2 — Einstellung im Pausenmenü  `[x]`
Im Einstellungs-/Pausenmenü ein Umschalter **DEUTSCH / ENGLISH**:
- Auswahl landet im Profil (`lang = "de" | "en"`), wird gespeichert und beim
  Start angewandt.
- Umschalten wirkt **sofort** ohne Neustart (Seiten werden neu aufgebaut).
- Log `[LOC][SET] sprache=en (gespeichert)`.

**Abnahme:** Log-Zeile + Screenshot Einstellungen mit beiden Feldern, aktives
Feld hervorgehoben.

### K3 — Kernseiten übersetzt  `[x]`
Menü, HUD, Shop, Charakter, Karten, Pause/Einstellungen und Todesbild sind in
EN vollständig lesbar (keine deutschen Reste in diesen Seiten).

**Abnahme:** Screenshots `screenshots/237-menu-en.png` und
`screenshots/238-shop-en.png`; Sichtprüfung: kein deutscher Rest.

---

## F — Abschluss

### F1 — Builds  `[x]`
APK + EXE erst, wenn A–E `[x]` sind, Version `1.36` (APP_VERSION/APP_BUILD +
export_presets).
**Abnahme:** `dist/ComicShooter-v1.36.apk` + `.exe`, Smoke-Test
`[BUILD] Versionsanzeige v1.36 aktiv (Build 36)`.

### F2 — Doku  `[x]`
`STATUS.md` neu (fertig mit Beleg / offen), `BUGLISTE.md` um die neuen Punkte
erweitern (Zurück-Tippfläche, Kistenanimation, Mini-Bosse, Chancen-Tabelle).

---

## Reihenfolge der Abarbeitung

**Hohe Priorität zuerst:**

1. **G** (Kisten-Sound) — reine Soundarbeit, sofort hörbar
2. **H** (Endlos-Upgrade: Toast + Zähler) — Gameplay-Bremse weg
3. **C** (Kistenanimation durchgehend) — passt zu G, gleiche Datei
4. **B** (Walzen-Gewinnschema) — reine UI
5. **E** (Mini-Bosse) — Gameplay, braucht einen Testlauf

**Danach:**

6. **A** (Shop) — vier Einzelpunkte, A3 (Tippfläche) zuerst diagnostizieren
7. **I** (Jahreszeiten/Karten mit Gold + FEST/WECHSELND)
8. **D** (Charakterfenster) — größter Umbau, zuletzt
9. **J** (Waffen-Seltenheiten) — Gameplay, braucht einen Simulationslauf
10. **K** (Sprache DE/EN) — reine UI, zuletzt vor dem Build
11. **F** (Build + Doku)

Nach jedem Block: `./Godot.exe --headless --path project --quit-after 60`
(keine `SCRIPT ERROR`), Screenshot über `COMIC_LANTEST=<mode>` sichern,
Log-Zeile in diese Spec bzw. nach `STATUS.md` übertragen.

**Prioritäten auf einen Blick:** G und H sind „hoch" (sofort spürbar), I ist
„mittel", A/B/C/D/E sind der bereits bestätigte Umbau.
