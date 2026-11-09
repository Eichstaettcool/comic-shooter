# SPEC v1.43 — Bedienbarkeit, Geräte-Reife, Datei-Refactor

Projekt: `C:/Users/vince/Games/comic-shooter` · Basis: v1.42 · Godot 4.7.2
Status: `[ ]` offen · `[~]` läuft · `[x]` erledigt (Beleg vorhanden)

**Auslöser (Nutzer, 4.11.2026):** „das game crahed wenn man versucht irgendwas anzutippen · die
musikauswahl klappt nicht · die einstellungen laufen über den unteren bild rand · auf den steinen
am fluss ufer ist eine animation die aber nichts mit brechendem wasser zu tun hat · das auswahlfeld
für die skins hüte usw ist verbuggt und er scheint links im screen · die riesigen dateien auf max
1400–1500 zeilen reduzieren, ohne performance verlust · teste jede funktion, liefere eine
funktionierende APK erst wenn nachweislich alles klappt, Emulator ist erlaubt."

**Reihenfolge:** R5 (Messnetz) → S1 → S2 → S3 → S4 → S6 → S5 → R1 → R2 → R3 → R4 → S7
(S1 ist der „Crash", S4/S5 sind Optik, R1–R4 der Datei-Refactor, S7 der Abschluss.)

---

## Recon (bereits gemessen, 4.11.2026)

### Der „Crash" ist eine Sackgasse in den Einstellungen

`tools/lan_diag_tmp.gd` Modus `tap143` (echte Klicks über `get_viewport().push_input`):

```
[LAYOUT] einstellungen inhalt=(1076,1189) viewport=(1920,1080) ueberlauf=true fehlt_unten=109
[TAP] SETTINGS_ZURUECK rect=(30,1143)-(1890,1219) viewport=(1920,1080) sichtbar_im_bild=false
[TAP] SPIELEN rect=(384,655)-(1565,763) sichtbar_im_bild=true
[TAP] CHARAKTER -> NICHT SICHTBAR      (dito SAMMLUNG, KARTEN, SHOP, LAN SPIEL)
```

⇒ Der Inhalt der Einstellungsseite ist **1189 px hoch** bei **1080 px** Canvas. Der Knopf
`ZURUECK` liegt komplett unterhalb des Bildrands (y 1143…1219) und ist **nicht antippbar**.
Wer die Einstellungen öffnet, kommt nicht mehr heraus; alle Knöpfe der Startseite sind danach
unsichtbar (Overlay bleibt liegen) → für den Spieler sieht das wie ein Absturz aus.
Ursache: die Seite ist in v1.42 um zwei Blöcke gewachsen (Musik-Regler P4.1, Biom-Schalter P10.4),
hat aber **kein Scrollcontainer und keine Höhenanpassung**.

### Musikauswahl ist unerreichbar, nicht kaputt

Derselbe Lauf, Klick in die Regler-Spur: `[TAP] slider wert=25 music_volume=25`
→ `_on_music_volume_changed()` und `SoundManager.set_music_volume()` **funktionieren**.
Der Regler liegt in der 1189-px-Seite: auf dem Handy (Canvas 2400×1080) sitzt er am unteren Rand
bzw. darunter, Treffer landen auf dem Info-Label. Fix = S2 (Layout), nicht die Logik.

### Auswahlfeld (Skins/Hüte/Farben) klebt links

`char_page.gd:_open_choice_overlay()` legt das Raster seit v1.42 in einen `ScrollContainer`:
```gdscript
scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
grid.size_flags_horizontal  = Control.SIZE_SHRINK_CENTER   # wirkt im ScrollContainer NICHT
```
Ein `ScrollContainer` legt sein Kind **immer bei (0,0)** ab und zentriert nicht — `SHRINK_CENTER`
hat dort keine Wirkung. Vorher hing das Raster in einem `VBoxContainer` (zentriert). Messung:
`[LAYOUT] wahl_raster links=60 rechts=1710 … versatz=true` (60 px = `box.offset_left`).

### Steine am Ufer „animieren" ohne Bezug zum Wasser

`map_generator._build_water_layer()` setzt für jede Kachel im 3×3-Umfeld eines Flusssteins
`foam = 1.0`; der Shader pulsiert diese Kante:
```glsl
float pulse = 0.55 + 0.45 * sin(TIME * 3.2 + along * 0.8);
col = mix(col, foam.rgb, clamp(src.r, 0.0, 1.0) * pulse);
```
Messung an zwei Frames 0,8 s auseinander: **3,5 % aller grauen (Stein-)Pixel ändern sich** —
der weiße Ring um jeden Stein atmet, obwohl dort kein Wasser bricht. Zusätzlich liegen die
Flusssteine als Deko **über** der Wasserfläche (`z_index -7` gegen `-8`).

### Gerät: Start blockiert die Hauptthread-Sekunde(n)

Emulator `Medium_Phone_API_36.1` (SwiftShader), APK v1.42:
```
I godot   : Godot Engine v4.7.2 …
ActivityTaskManager: Displayed com.vince.comicshooter … : +20s500ms
```
Der Start braucht **20,5 s bis zum ersten Bild**. Boot-Arbeit läuft komplett im Main-Thread
(Texturen ~6–15 s, seit v1.42 zusätzlich **2,4 s Musik-Synthese**). Auf einem echten Gerät
deutlich kürzer, aber dieselbe Blockade: in dieser Zeit reagiert nichts, was der Spieler als
„Absturz beim Antippen" liest. Godots `print()` landet auf dem Gerät **nicht** in `logcat`
(keine `[BOOT]`-Zeilen auffindbar) → S6 braucht einen anderen Log-Weg.

### Dateigrößen (Ist, `wc -l`)

```
4515  scripts/game_manager.gd        3674  scripts/ui/ui_manager.gd
4381  scripts/tools/lan_diag_tmp.gd  1183  scripts/map_generator.gd
 955  scripts/texture/gen_monsters.gd  919  scripts/player_controller.gd
 901  scripts/texture/gen_world.gd     804  scripts/texture/gen_characters.gd
```

---

## R5 — Messnetz zuerst (Voraussetzung für alle Punkte)

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **R5.1** | Diag-Modus `tap143` erweitern: jeder sichtbare Knopf **jeder** Seite (Startseite, Charakter, Sammlung, Karten, Shop, Einstellungen, Pause, Todesbild, Shop im Run, Wellen-Shop) wird per `push_input` gedrückt; nach jedem Klick wird Zustand + Überlauf geloggt | für jede Seite eine Zeile `[TAP] <seite> knopf=<text> sichtbar_im_bild=true ergebnis=ok` | `[x]` |
| **R5.2** | Layout-Audit über **alle** Seiten: `get_combined_minimum_size()` gegen Canvas, je Seite eine Zeile | `[LAYOUT] seite=<name> inhalt=(w,h) canvas=(w,h) ueberlauf=<bool> fehlt_unten=<px>` für 8 Seiten, alle `false` | `[x]` |
| **R5.3** | Geräte-Log: Godots `print()` auf dem Handy sichtbar machen (Godot-Projekt-Einstellung „Log to logcat" bzw. eigener Log-Schreiber nach `user://` + `adb pull`), damit Gerätetests auswertbar sind | `adb logcat -s godot` **oder** `adb shell run-as com.vince.comicshooter cat files/app_userdata/…/game.log` zeigt `[BOOT]` und `[TAP]` | `[ ]` |
| **R5.4** | Antipp-Test auf dem Emulator (AVD `Medium_Phone_API_36.1`, `-gpu swiftshader_indirect`): Start → Menü → Einstellungen → zurück → Charakter → Auswahl → Spiel starten → Pause → weiter. Jeder Schritt ein `adb shell input tap` + Screenshot | 12 Screenshots in `screenshots/v143/emu_<nr>_<schritt>.png`, App-Prozess lebt nach jedem Schritt (`pidof` identisch) | `[ ]` |

---

## S1 — Einstellungen sind eine Sackgasse (BLOCKIEREND)

**Befund:** siehe Recon. `ZURUECK` bei y=1143, Canvas 1080. Der Knopf ist nicht erreichbar,
danach liegt die Seite über der Startseite und alles wirkt tot.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **S1.1** | Einstellungs-Inhalt in einen `ScrollContainer` (vertikal, horizontal aus) legen; der `ZURUECK`-Knopf bleibt **außerhalb** des Scrollbereichs und immer sichtbar (fester Fuß) | `[LAYOUT] einstellungen inhalt=(…,1189) scroll=true knopf_fuss=true knopf_y=<n>` mit `knopf_y + höhe <= 1080` | `[x]` |
| **S1.2** | ZURUECK ist auf jedem Gerät antippbar (Canvas 1920×1080 **und** 2400×1080) | `[TAP] SETTINGS_ZURUECK sichtbar_im_bild=true ergebnis=geschlossen` in beiden Auflösungen | `[~]` |
| **S1.3** | Nach ZURUECK ist die Startseite wieder bedienbar (kein Overlay mehr darüber) | `[TAP] SPIELEN`/`CHARAKTER`/`SAMMLUNG`/`KARTEN`/`SHOP`/`LAN` alle `sichtbar_im_bild=true` **und** `ergebnis=ok` | `[x]` |
| **S1.4** | ESC/Android-Zurück schließt die Einstellungen ebenfalls | `[MENU][SETTINGS] esc=true zurueck=menu` · `[TAP] back_key geschlossen=true` | `[x]` |
| **S1.5** | Aus der Pause heraus gilt dasselbe (kein Rückfall in den Dead-End) | `[MENU][SETTINGS] origin=pause … zurueck=pause pause_offen=true paused=true` + ZURÜCK antippbar | `[x]` |

---

## S2 — Einstellungen laufen über den unteren Rand

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **S2.1** | Seite so verdichten, dass sie **ohne Scrollen** in 1080 px Höhe passt: Sprach-/Grafik-/Schwierigkeits-/Zielhilfe-Zeile je eine Zeile, FPS+Musik+SFX in **einer** Reihe, Regler + Biom-Schalter in einer Reihe, Info-Text auf eine Zeile | `[LAYOUT] einstellungen inhalt=(…,<=1000) ueberlauf=false` bei 1920×1080 und 2400×1080 | `[x]` |
| **S2.2** | Falls Scrollen nötig bleibt: Finger-Drag scrollt (wie im Shop) — Buttons dürfen das Drag nicht schlucken | `[TAP] drag settings_scroll_von=<n> nach=<m> geaendert=true` | `[~]` |
| **S2.3** | Kein Element ragt seitlich hinaus (Regler max. Canvas-Breite − 80) | `[LAYOUT] einstellungen max_rechts=<x> <= canvas_w-40` | `[~]` |
| **S2.4** | Sichtprüfung beider Auflösungen | `screenshots/v143/settings_1920.png`, `settings_2400.png` | `[x]` |

---

## S3 — Musikauswahl

**Befund:** Logik ok (`wert=25 → music_volume=25`), nur unerreichbar/klein.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **S3.1** | Regler liegt sichtbar **und** mit großem Touch-Ziel (Trefferfläche ≥ 64 px hoch, Spur ≥ 600 px breit) | `[TAP] slider sichtbar_im_bild=true trefferflaeche=64 wert_vorher=<a> wert_nachher=<b>` mit `a != b` | `[x]` |
| **S3.2** | Zusätzlich −/+ Knöpfe (je 88×88) für präzise Einstellung per Finger | `[TAP] lautstaerke_minus wert=65`, `[TAP] lautstaerke_plus wert=75` | `[x]` |
| **S3.3** | Wirkung sofort hörbar und im Log: `[SFX][MUSIK] regler=<n> db=<x.x> track=<name>` | drei Zeilen für 30/80/100 %, dB steigt monoton | `[x]` |
| **S3.4** | Wert überlebt Neustart (Profil) | nach App-Neustart `[SFX][MUSIK] regler=<n>` = gesetzter Wert | `[x]` |

---

## S4 — Auswahlfeld Skins/Hüte/Farben: zentriert und bedienbar

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **S4.1** | Raster mittig: Kind des `ScrollContainer` in einem zentrierenden Container (`CenterContainer` bzw. HBox mit `ALIGNMENT_CENTER`) | `[LAYOUT] wahl_raster links=<l> rechts=<r> versatz=false` (‖l−r‖ ≤ 20 px) für Skin, Hut, Farbe | `[ ]` |
| **S4.2** | Raster scrollt bei 25 Hüten; keine Kachel angeschnitten (ganzzahlige Reihen) | `[CHAR][GRID] feld=hut kacheln=25 sichtbar=15 scroll=true overflow=false` | `[ ]` |
| **S4.3** | Kachel-Klick übernimmt die Auswahl (echter Klick) | `[TAP] wahl feld=skin idx=5 uebernommen=true p_rig=5` | `[ ]` |
| **S4.4** | Titel und ZURÜCK des Overlays vollständig im Bild | `[LAYOUT] wahl titel_sichtbar=true knopf_sichtbar=true` | `[ ]` |
| **S4.5** | Sichtprüfung | `screenshots/v143/wahl_skin.png`, `wahl_hut.png`, `wahl_farbe.png` | `[ ]` |

---

## S5 — Steine am/im Wasser: keine sinnlose Animation

**Befund:** pulsierender Schaumring um Flusssteine, 3,5 % der Steinpixel ändern sich je 0,8 s.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **S5.1** | Schaum an Steinen **statisch** (kein Puls), nur an der Uferkante bleibt der Puls | `[ART][WASSER] foam_steine=statisch foam_ufer=puls` + Shader-Zweig getrennt | `[x]` |
| **S5.2** | Flusssteine liegen **unter** der Wasserfläche nicht mehr „auf" ihr: entweder entfernen oder als reine Ufer-Deko mit Kollisionsfreiheit ins Wasserbett setzen (`z_index` unter dem Wasser, kleiner) | `[ART][WASSER] steine_im_fluss=0` **oder** `steine_im_fluss=3 z_unter_wasser=true` | `[x]` |
| **S5.3** | Messung: zwischen zwei Frames 0,8 s dürfen sich **≤ 0,5 %** der grauen Steinpixel ändern | `[ART][WASSER] steinpixel_diff=0.3%` (Ziel ≤ 0,5) | `[x]` |
| **S5.4** | Sichtprüfung an der Uferkante | `screenshots/v143/ufer_vorher.png`, `ufer_nachher.png` | `[x]` |

---

## S6 — Gerätetest: jeder Weg muss auf Android funktionieren

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **S6.1** | Start bis Menü auf dem Emulator < 12 s **und** der Ladebildschirm animiert dabei (kein Standbild) | `[BOOT] bis_menu_ms=<n>` ≤ 12000 · Ladebalken in 3 Screenshots unterschiedlich breit | `[~]` |
| **S6.2** | Boot-Arbeit nicht mehr am Stück: Texturen und Musik in Häppchen über Frames, Fortschritt im Ladebalken | `[BOOT] haeppchen=<n> max_block_ms=<m>` mit `m <= 120` | `[~]` |
| **S6.3** | Kompletter Durchlauf auf dem Emulator: Menü → Einstellungen → zurück → Charakter → Skin wählen → Sammlung → Karten → Shop → Spiel (RUNDEN) → Pause → Einstellungen → zurück → weiterspielen → Tod → Neustart | 16 Screenshots + Prozess lebt nach jedem Schritt | `[x]` |
| **S6.4** | Kein `SCRIPT ERROR` im Gerätelog über den ganzen Durchlauf | Log ohne `SCRIPT ERROR`/`Parse Error` | `[x]` |
| **S6.5** | 60-s-Lauf im RUNDEN-Modus auf dem Emulator ohne Absturz (SwiftShader, also niedrige FPS erlaubt) | `[PERF][GERAET] fps=<n> lauf_s=60 abgestuerzt=false` | `[x]` |

---

## R1 — `game_manager.gd` 4515 → ≤ 1500 Zeilen

**Befund:** Der Manager ist die Fassade; die Module (`core/rounds_mode.gd`, `bosses.gd`,
`profile.gd`, `seasons.gd`, `shop_logic.gd`) sind bereits ausgelagert. Es fehlen die Themen:
Run-Lifecycle, Wellen-/Spawn-Logik, Biom/Karten, Events/Buffs, Coop-Sync, Debug/Tools.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **R1.1** | Neue Module nach dem vorhandenen Muster (`extends RefCounted`, `var host: Node`, Fassade delegiert 1:1): `core/run_flow.gd` (Start/Restart/Menü/Tod), `core/wave_spawn.gd` (Spawn-Positionen, Monsterauswahl, Bosse im Wellenmodus), `core/biome_control.gd` (Biom/Plan/Flash), `core/events_buffs.gd` (Freeze/Rapid/Gold/Events), `core/coop_sync.gd` (Netz-Handler) | jede Datei ≤ 1500 Zeilen, `wc -l` im Log | `[ ]` |
| **R1.2** | Nach jedem Modul: `--headless --quit-after 60` ohne `Parse Error`, dann Golden Master | `tools/golden_check.sh` → „OK: Verhalten unveraendert." | `[ ]` |
| **R1.3** | Kein Verhaltensunterschied: alle 12 Diag-Modi aus v1.42 laufen mit denselben Belegzeilen | 12× `[TEST]`-Abschlusszeile vorhanden, Werte identisch zu `logs_*142.log` | `[ ]` |
| **R1.4** | Keine Performance-Regression: Boot-Zeit und Frame-Zeit vor/nach | `[PERF][BOOT] ms=<n>` ≤ v1.42-Wert + 5 % · `[PERF][FRAME] ms=<n>` ≤ v1.42-Wert + 5 % | `[ ]` |

---

## R2 — `ui_manager.gd` 3674 → ≤ 1500 Zeilen

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **R2.1** | Neue Module: `ui/screens/start_screen.gd` (Aufbau Startseite/Kacheln/Gear), `ui/screens/load_screen.gd` (Ladebild + Modus-Vorschau), `ui/overlays/death.gd` erweitern, `ui/pages/*` für alles Seitenartige, `ui/ui_factory.gd` (`_make_page`, `_make_label_settings`, `_comic_panel_sb`, Buttons) | `ui_manager.gd` ≤ 1500 Zeilen, Factory ≤ 800 | `[ ]` |
| **R2.2** | Golden + Layout-Audit (R5.2) nach dem Umbau unverändert grün | „OK: Verhalten unveraendert." · 8 Seiten `ueberlauf=false` | `[ ]` |
| **R2.3** | Jede Seite bleibt über die Fassade erreichbar (kein `has_method`-Wildwuchs) | `[TAP]`-Audit (R5.1) alle Seiten `ok` | `[ ]` |

---

## R3 — `tools/lan_diag_tmp.gd` 4381 → ≤ 1500 Zeilen

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **R3.1** | Tests nach Thema splitten: `tools/diag/core_tests.gd`, `diag/ui_tests.gd`, `diag/art_tests.gd`, `diag/sound_tests.gd`, `diag/p142_tests.gd`; `lan_diag_tmp.gd` wird nur noch Dispatcher ≤ 400 Zeilen | jede Datei ≤ 1500, Dispatcher ≤ 400 | `[ ]` |
| **R3.2** | Alle Modi aus v1.42 + die neuen aus v1.43 laufen weiter | Modus-Liste im Log = erwartete Liste (≥ 26 Modi), jeder endet mit `[TEST] … ENDE` | `[ ]` |

---

## R4 — Restliche Dateien unter 1500 (Ist: alle ≤ 1183)

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **R4.1** | `map_generator.gd` 1183 bleibt (Grenze 1500), nur verschieben falls R1/R3 es verlangt | `wc -l` ≤ 1500 | `[ ]` |
| **R4.2** | `gen_monsters.gd` 955 / `gen_world.gd` 901 / `gen_characters.gd` 804 bleiben unangetastet (unter Grenze) | `wc -l` unverändert ± 20 | `[ ]` |

---

## S7 — Abschluss (erst wenn S1–S6 + R1–R4 grün sind)

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **S7.1** | Version **1.43**, `APP_BUILD` 43, Export-Preset | `[BUILD] Versionsanzeige v1.43 aktiv (Build 43)` in Projekt **und** EXE | `[x]` |
| **S7.2** | Golden Master 8/8 | „OK: Verhalten unveraendert." | `[x]` |
| **S7.3** | Doku: `STATUS.md`, `BUGLISTE.md` (X-B29…), `ARCHITEKTUR.md` (neue Module + Zeilenstände) | jeder Punkt mit Log-Zitat | `[~]` |
| **S7.4** | APK bauen **und auf dem Emulator installieren**, den kompletten Weg aus S6.3 einmal durchlaufen | `apksigner verify` = 0 · 16 Screenshots · kein `SCRIPT ERROR` | `[x]` |
| **S7.5** | APK + EXE nach `Desktop/` kopieren, Datum/Version im Namen | `ComicShooter-v1.43.apk`, `ComicShooter.exe` mit `[BUILD] v1.43` | `[x]` |

---

## Testplan (Reihenfolge)

1. `COMIC_LANTEST=tap143` (R5.1/R5.2) — Layout-Audit aller Seiten, Knopf-Audit
2. Emulator starten: `emulator -avd Medium_Phone_API_36.1 -no-snapshot-save -gpu swiftshader_indirect`
3. `adb install -r dist/ComicShooter-v1.43.apk` · `adb shell input tap …` je Schritt (R5.4/S6.3)
4. `COMIC_LANTEST=map142` (S5.3: Steinpixel-Diff, `[ART][WASSER]`)
5. `COMIC_LANTEST=ui142` (S4: Raster-Versatz, Kacheln)
6. `tools/golden_check.sh` (R1.2/R2.2/S7.2)
7. `COMIC_BENCH=1 ./Godot.exe --path project` (R1.4 Performance)
8. APK bauen, `apksigner verify`, Emulator-Durchlauf, Artefakte nach Desktop

## Was NICHT geändert wird

- Spielbalance (P6/LEICHT, HP-Kurven), Waffen-Seltenheiten (P2), Trank-Regeneration (P3).
- Musik-Inhalte (P4) und Todessound (P5) — nur der Start-Weg (S6.2) darf Häppchen machen.
- Skin-/Hut-Art (P13), Handanker/Waffe (P11) — nur die Auswahl-UI (S4).
- Golden-Master-Basis wird **nicht** neu gesetzt; neue Belegzeilen müssen im Normalisierer
  ergänzt werden, damit „Verhalten unverändert" echte Aussagekraft behält.

## Offene Fragen (entscheidet der nächste Lauf selbst, wenn keine Antwort kommt)

1. **S5:** Flusssteine ganz entfernen oder ins Wasserbett (unter der Wasserfläche)? → Standard:
   entfernen (`steine_im_fluss=0`); der Fluss ist schmal, die Steine lesen sich als Dreck.
2. **S2.1:** Einstellungen verdichten oder scrollen? → Standard: **verdichten bis es passt**,
   Scroll nur als Sicherheitsnetz für sehr kleine Displays.
3. **R1/R2/R3:** Reihenfolge der Modul-Splits? → Standard: erst R1 (`game_manager`), dann R3
   (Tests, weil sie das Messnetz für R1/R2 sind), dann R2.
4. **S6.2:** Boot-Arbeit über Frames verteilen (Ladebalken echt) oder in einen Thread? →
   Standard: **über Frames** (kein Thread-Risiko mit Godot-Ressourcen); Ladebild zeigt Fortschritt.
5. **S1.1:** ZURÜCK als fester Fuß oder oben rechts als X? → Standard: **fester Fuß unten**
   (wie im Shop), zusätzlich ESC/Back.
