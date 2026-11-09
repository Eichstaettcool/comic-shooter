# STATUS — Stand 7.11.2026, 18:50

## v1.51 — Balancing Runden-Modus + Skills im Shop — FERTIG

Rückmeldung: „ich komme im runden modus sogar in stufe leicht nicht über runde 9 hinaus,
irgendwann ist man zu langsam und die roten holen einen ein". Ursache gefunden: die
Runden-Kurve ließ das Gegnertempo bis **1,50** steigen (Runde 14 SPRINT) — RED mit
140 px/s wurde damit **210 px/s** schnell, der Spieler läuft **160 px/s**. Ab Runde 14
war Weglaufen physikalisch unmöglich.

| Punkt | Änderung | Beleg |
|---|---|---|
| **A1 Tempo-Deckel** | `Rounds.spd_mult()` max **1,18** (vorher 1,50), SPRINT-Runde 1,18 | `[BAL151][TEMPO] stufe=leicht min_verhaeltnis=1.08 ok=true` · R9 = 1,20 · R14 = 1,08 |
| **A2 RED schwächer** | 140 → **125** px/s | `[BAL151][KURVE] runde=1 … red_speed=125` |
| **A3 LEICHT entschärft** | HP 0,80 · Anzahl 0,58 · Münzen 1,25 | `[BAL151][KURVE] stufe=leicht runde=9 gegner=16 hp=183` (vorher 18/228) |
| **B1 mehr Münzen** | Kill `2+hp*0,8`, `1+0,08r`; Bonus `16+6r` | `[BAL151][EINKOMMEN] stufe=leicht … r9=246(kum 1361)` (vorher ~800) |
| **C1 Skills im Shop** | Zeile „SKILLS · DAUERHAFT": TEMPO +10 %, NACHLADEN -8 %, SCHADEN +12 %, je 6 Stufen, Preis steigt je Stufe | `[WSHOP][SKILL] id=skill_speed stufe=6 preis=270 … speed=1.60 cooldown=0.85 damage=1.36` · Grenze: `kauf=nein grund=maximum` · Knopfpfad: `[BAL151][KNOPF] vorher=2 nachher=3` |
| **C2 Shop zwischen Runden** | HUD-Knopf sichtbar, öffnet Shop mit Skills | `[SHOP151][HUD] intermission=true sichtbar=true` → `[SHOP151][OFFEN] karten=11` → `[SHOP151][RUNDE2] runde=2 aktiv=true` |
| **D1 Regression** | Golden 8/8 | `rest_diff=0 script_errors=0`, „OK: Verhalten unveraendert." |
| **E1 Builds** | APK 1.51 · EXE 1.51 · iOS-Xcode-ZIP 1.51 | `dist/ComicShooter-v1.51.*` |

Details: `project/SPEC_V151.md` · Fehler: `project/BUGLISTE.md` X-B55…X-B58.

## v1.50 — Nachbesserung: Vorab-Kauf raus, Sammlung neu sortiert — FERTIG

## v1.50 — Nachbesserung: Vorab-Kauf raus, Sammlung neu sortiert — FERTIG

Rückmeldung des Nutzers: Die „Portionen" (Vorab-Kauf) waren noch da und crashten den Run, die
Sammlung war verzogen, und es fehlte die Sortierung nach Seltenheit. Beides umgesetzt,
zusätzlich **jeden** Spec-Punkt erneut geprüft (Tabelle unten).

| Nachbesserung | Beleg |
|---|---|
| **A4 Vorab-Kauf komplett entfernt** | Sektion „SOFORTKAUF", `QUICK_SHOP`, `buy_quick`, `quick_buffs`, `apply_quick_buffs` gelöscht; `grep -c` = 0/0/0 (nur Migrations-Log in `profile.gd`) · `[SHOP][VORAB] entfernt=1 grund=abstuerze_in_mehreren_modi sektionen=3` · Gerät: Shop offen, kein Absturz (`emu_shop149.png`) |
| **B3 Sammlung: feste Kacheln** | Kachel = Panel 150×150 (Textur + Overlay), Balken + Name darunter, Zeilen selbst zentriert · `[COLL][RASTER] … zeilen=1/3/3` · Gerät `emu_coll150.png` |
| **B3 Sortierung nach Seltenheit** | `[COLL][SORT] kategorie=farben reihenfolge=[9, 5, 7, 8, 6, 0, 1, 2, 3, 4]` (legendaer → gewöhnlich, aktiver Eintrag zuerst in seiner Stufe) · Hüte/Skins analog |

### Erneute Prüfung aller Spec-Punkte (v1.50)

| Punkt | Beleg | Status |
|---|---|---|
| A1 Shop ohne Run-Boosts | `grep BOOSTS` 0/0/0 · `[RUN][START][VERGLEICH] identisch=true` · `[SHOP][KISTE][SUMME] tier=standard kaeufe=5 inhalt=4` / `silver 5/5` / `premium 4/4` | ok |
| A2 Glücksrad | `[WHEEL][SIM] n=200000 skin=0 hut=0 rtp_gold=0.9245 abweichung_pp=0.45` · `[WHEEL][SEGMENT] 0…7` mit Icons · `[WHEEL][GEWINN] art=gold wert=500` | ok |
| A3 Erde-Jahreszeiten | `[MAP][SEASON] planet=earth knoepfe=4` (alle Planeten 4) · `season=winter modus=fixed` + `[SEASON][SCHNEE] light=#e5effc` | ok |
| A4 Vorab-Kauf | s. o. | ok |
| B1 Sammlung-Zustände | `[COLL][OWNED] rigs=1/17 farben=2/10 huete=3/25` · `[COLL][BALKEN] geprueft=52 ok=52` | ok |
| B2 Scrollen | 3× `[SCROLL][ZUG] seite=collection von=0 nach=350 px=350` · Tipp `tipp_px=2 kurz=true` | ok |
| B3 Layout + Sortierung | s. o. | ok |
| C1 Challenges | `[CHAL][DEF] anzahl=12` + 12 Regeln · `[CHAL][KARTEN] anzahl=12` · `[CHAL][ABHOLEN] gutschrift=true gems=50` | ok |
| C2 Kisten | `[CHEST][KANTE] … spitzen=0` (18 Varianten) · `kisten.png`, `kiste_ingame.png` | ok |
| C3 Schuss-Knopf | `[BTN][PIXEL] px=256 einsam=0 anteil=0.00%` · `schussbutton_alt_neu.png` | ok |
| C4 Runden-Shop | `[SHOP][FILTER][SUMME]` modus 0/2 → `wellen_only=0 verletzungen=0`, modus 1 → `wellen_only=2 verletzungen=0` | ok |
| D1 Info-Seite | `[INFO][SEITE] abschnitte=9 hoehe=1715px` · `[INFO][SCROLL] 859 px` · 9× `[LOC][INFO]` | ok |
| E2 Upgrade-Fenster | `nach_tipp karten=3 paused=true` · `nach_wahl stacks_nach={…} paused=false` · Wellen `pending=0 toast=false` · nach Neustart `overlay=false toast=false` | ok |

Golden: **8/8 `rest_diff=0 script_errors=0`** · Gerät v1.50: `SCRIPT ERROR=0`, `signal 11=0`.

Builds: `dist/ComicShooter-v1.50.apk` (31,7 MB, installiert, `versionName=1.50`) ·
`dist/ComicShooter-v1.50.exe` (112,3 MB, Smoke rc=0) — Kopien auf dem Desktop.

---

# STATUS — Stand 6.11.2026, 16:05

## v1.48 — Bugfix- und Inhalts-Paket — FERTIG

Spec: `project/SPEC_V148.md` — **alle 12 Punkte `[x]`** (A1–D1, E2-Nachtrag, E1), jeder mit
Log-Zitat, Messwert oder Bild. Golden: **8/8 `rest_diff=0 script_errors=0`**.
Builds: `dist/ComicShooter-v1.48.apk` (31,6 MB, `apksigner verify` rc=0,
`versionName=1.48`) und `dist/ComicShooter-v1.48.exe` (112,3 MB, Smoke rc=0).

| Punkt | Ergebnis | Beleg (Auszug) |
|---|---|---|
| **A1 Shop ohne Run-Boosts** | **fertig** | `[SHOP][BOOST-ENTFERNT] eintraege=7 quellen=3` · `[RUN][START] modus=0/1 hp=4 schild=0 tempo=1.00 schaden=1.00` + `identisch=true` · 3 Kisten `[SHOP][KISTE] ok=true` · `grep BOOSTS` 0/0/0, `grep "naechsten Run\|ab Start"` 0/0 |
| **A2 Glücksrad Gold+Diamanten** | **fertig** | 200.000 Spins: `skin=0 hut=0`, `rtp_gold=0.9245` vs 0,9200 (0,45 pp) · `[WHEEL][SEGMENT] index=0…7` mit Icons · `[WHEEL][GEWINN] art=gold wert=500` · Bilder `wheel_rad.png`, `wheel_segmente.png` |
| **A3 Jahreszeiten auf der Erde** | **fertig** | `[MAP][SEASON] planet=earth knoepfe=4` (+ alle Planeten 4) · `[MAP][SEASON] planet=earth season=winter modus=fixed` + `[SEASON][SCHNEE] light=#e5effc dark=#c9dbf2` · `erde_winter.png` |
| **B1 Sammlung: Zustaende + Balken** | **fertig** | `[COLL][OWNED] rigs=1/17 farben=2/10 huete=3/25` · `[COLL][BALKEN] geprueft=52 ok=52` · `coll_zustaende.png` (farbig / goldener Rahmen / Kette+Schloss) |
| **B2 Scrollen in der Sammlung** | **fertig** | `[SCROLL][ZUG] seite=collection von=0 nach=350 px=350` 3× · `[COLL][KLICK] … tipp_px=2 kurz=true` |
| **C1 Challenges mit Einschränkung** | **fertig** | `[CHAL][DEF] anzahl=12` + 12× `[CHAL][REGEL] id=… art=…` · `[CHAL][KARTEN] anzahl=12` · Ende-zu-Ende `sparsam`: `6/6`, `+50 gems`, `[CHAL][ABHOLEN] gutschrift=true` |
| **C2 Kisten neu (keine Zähne)** | **fertig** | `[CHEST][KANTE] … spitzen=0` für 3 Kisten × 2 Zustände × 96/160/256 · `kisten.png` · `kiste_ingame.png` |
| **C3 Schuss-Button** | **fertig** | `[BTN][PIXEL] knopf=shoot px=256 einsam=0 anteil=0.00%` · `schussbutton_alt_neu.png` · `schussbutton_ingame.png` |
| **C4 Runden-Modus ohne Wellen-Upgrade** | **fertig** | `[SHOP][FILTER][SUMME] modus=0 wellen_only=0 verletzungen=0`, `modus=1 wellen_only=1 verletzungen=0`, `modus=2 wellen_only=0 verletzungen=0` |
| **D1 Info-Seite** | **fertig** | `[INFO][SEITE] abschnitte=9 hoehe=1715px scrollbar=true` · `[INFO][SCROLL] von=0 nach=859 px=859` · 9× `[LOC][INFO]` · `[UI][NAV] ziel=info herkunft=settings` / zurück · `info_seite.png`, `info_seite_2.png`, `info_knopf.png` |
| **E2 Upgrade-Fenster (Nachtrag)** | **fertig** | Zwei verlorene `emit_signal` (Toast + Karte) repariert: `nach_tipp karten=3 paused=true`, `nach_wahl stacks_nach={ "vitality": 1 } paused=false`; Wellen-Modus `pending=0 toast=false`; nach Neustart kein Overlay |

Gerät: APK installiert, Menü „v1.48 · Build 48", Karten mit 4 Jahreszeiten-Knöpfen,
Run mit neuem Schuss-Knopf; `SCRIPT ERROR=0`, `signal 11=0`, Prozess stabil.

---

# STATUS — Stand 6.11.2026, 13:50

## v1.47 — Icon-Wahl: lila Boss als App-Icon (Nachtrag zu v1.46)

Der Nutzer hat **Entwurf 6 („lila Boss", drei Augen)** gewählt. Das alte Icon (v1.20–v1.36) war ein
Monster-Gesicht als Großaufnahme — aus `dist/ComicShooter-v1.27.apk` geholt und als Vorlage genommen;
sechs Gesichter in diesem Stil neu gezeichnet (`COMIC_LANTEST=icon146c`, 1024², MSAA 4×,
`screenshots/v146/icons_uebersicht146c.png` mit dem alten Original als linker Referenz).

| Punkt | Beleg |
|---|---|
| Icon gesetzt | `project/icon.png` = `icon146c_6.png` (1024×1024), alt: `backup/icon_v145.png` |
| Im APK enthalten | `res/mipmap-xxxhdpi-v4/icon.webp` ausgepackt → `scratch/apkicon147/icon.png` = lila Boss; Gerätebild `screenshots/v146/emu_appinfo_icon147.png` |
| Version | `[BUILD] icon=icon146c_6.png quelle=res://icon.png px=1024 version=1.47 build=47` (Projekt + EXE), APK `versionName=1.47` |
| Builds | `dist/ComicShooter-v1.47.apk` (31,6 MB, `apksigner verify` = 0) · `dist/ComicShooter-v1.47.exe` (112,2 MB) · Kopien auf dem Desktop |

Golden Master: unverändert grün (keine Spiel-Logik berührt, nur `icon.png` + Versionskonstante).

---

# STATUS — Stand 6.11.2026, 12:40

## v1.46 — Challenges, Scroll, Musik, Hüte, Skins, Name, Einstellungen, Icons — FERTIG

Spec: `project/SPEC_V146_POLISH.md` — **alle 53 Kriterien `[x]`, jeder Punkt mit Log-Zitat, Messwert
oder Bild** (Belegtabelle am Ende der Spec). Builds: `dist/ComicShooter-v1.46.apk` (31,4 MB,
`apksigner verify` = 0) und `dist/ComicShooter-v1.46.exe` (112,1 MB), Kopien auf dem Desktop.
Golden Master: **8/8 `rest_diff=0 script_errors=0`**, „OK: Verhalten unveraendert."
Gerät (`Medium_Phone_API_36.1`): `pid=11620` stabil, `SCRIPT ERROR=0`, `SIGSEGV=0`.

| Block | Ergebnis | Beleg (Auszug) |
|---|---|---|
| **A — Umbenennung** | **fertig** | `[UI][NAV] kachel=CHALLENGES` · `[UI][PAGE] titel=CHALLENGES` · `[CHAL][HUD] prefix=CHALLENGE text=BOSS-RUSH · NORMAL · BOSSE 0/5` · `[LOC][KEY] challenges de=CHALLENGES en=CHALLENGES` · Ergebnis-Fenster „CHALLENGE VERFEHLT" (Gerätebild) |
| **C — Scroll** | **fertig** | neuer Helfer `smooth_scroll.gd` (`UiStyle.smooth_scroll`): `[SCROLL][ZUG] versatz_max=0.0px nachlauf_ms=315 ok_versatz=true ok_nachlauf=true` · `[SCROLL][RAD] … klemmt=true` · `[SCROLL][ENDE] max=424 … letzte_karte_voll=true` · `[SCROLL][FIX] titel=30 chips=112 fuss=974 gleich_nach_scroll=true` · Gerät: Ziehen bewegt, 12 Karten, letzte Reihe vollständig (`emu_chal_scroll.png`) |
| **B — 12 Challenges** | **fertig** | `[CHAL][KOMBI] aufgaben=12 stufen=3 kombinationen=36` · neue Regeln: `[CHAL][REGEL] id=flinte waffe=shotgun pickups=0`, `[CHAL][ZIEL] id=kopfgeld kills=n/60`, `id=goldrausch muenzen=n/300`, `id=unberuehrt treffer=… erlaubt=false`, `[CHAL][SPERRE] verbrauch=potion` · `[TEST][CHALRUN146] aufgaben=12 erledigt=12` (jede Belohnung genau einmal: `zweite_gutschrift=false`) |
| **D — Ingame-Musik** | **fertig** | `[MUSIK][CFG] track=game_1…4 bpm=84/88/92/96 lead=sine drums=0.02–0.03` (Menü-Charakter) · Crossfade über zwei Player: `[MUSIK][WECHSEL] … gleicher_player=false` · nach jedem Wechsel `spieler_playing=true pos>1.1` · Loop `luecke_max_ms=0` · Pause-Dämpfung `−24 dB → zurück ±0,0 dB` · Pegel unverändert `−20,5 dBFS` bei Regler 100 % |
| **E — Boss-Musik** | **fertig** | `boss_1`: `bpm=146 bass_hz=55.0 drums=0.30 tritonus=true heartbeat=0.55` · Riser + harter Wechsel (`start=dauer1.2s`), Rückkehr 1,0 s · `[MUSIK][BOSS] banner=true track=boss_1 frame_gleich=true` · 7 WAV + `_pegel.txt` in `screenshots/v146/audio/` |
| **F — Hüte** | **fertig** | vorher `auffaellig=128`, jetzt `[HAT][PRUEF] ERGEBNIS paare=408 auffaellig=0`; alle `[HAT][SUM] … max_augen=0%` · Hut sitzt auf gemessener Kopfbreite (`[HAT][SKALA] … streuung=0.15–0.20`) · Rucksack hinter dem Körper (`[HAT][EBENE] … koerper_ueberdeckt=0.0%`) · ein Zeichenweg (`[HAT][PFAD] rig=0 weg=make_player_rig`) · Blätter `hats_17x24.png`, `hats_fix.png` |
| **G — Wikinger + Geist** | **fertig** | Rig 7: Helm mit Hörnern, Bart-Silhouette, Schulterfell, Axt am Gürtel; Rig 6: schwebender Saum, Alpha-Verlauf, leuchtende Augen, Kette · `[RIG][IOU] rig=6 iou=0.66`, `rig=7 iou=0.63` (Ziel ≤ 0,75) · Hüte: `[HAT][AUGEN] rig=6/7 verdeckt=0%` · Blatt `rigs_neu.png` (64 + 256 px, 17 Rigs) |
| **H — Name** | **fertig** | `[CHAR][NAME] feld=true max_zeichen=10 tastatur=geraet` · `eingabe="  vince  " gespeichert="vince"` · `eingabe="" → "HELD"` · `eingabe="VINCE" → "VINCE"` · Menü zieht nach (`menue=sichtbar`), Coop-Sync über `notify_profile_changed()` · auf dem Gerät getippt (`emu_char_name_ergebnis.png`) |
| **I — Einstellungen** | **fertig** | `[SET][ORIGIN] herkunft=pause schwierigkeit=aus biom=aus` / `herkunft=menu … an` · `[SET][LAYOUT] … reihen=9 bzw. 7, zurueck_y=974` (unverändert) · Gerätebild `emu_settings_pause.png` |
| **J — Icons** | **fertig** | 5 neue Entwürfe 1024² (`icon146_a…e`), Übersicht mit v145-Referenz und Größen 32–96 px · `[ICON][WAHL] offen=true` — **der Nutzer entscheidet**, kein Icon wurde gesetzt |
| **K — Abschluss** | **fertig** | Version/Build 46 in Projekt, EXE und APK · Golden 8/8 · 5 Spec-Diag-Modi (+3 neue) enden mit `[TEST][…146] ENDE` · Gerätelauf ohne Script-Fehler · Doku · beide Builds |

### Wichtigste Änderung gegenüber dem Plan: kein Engine-Loop

Die Spec wollte zuerst `LOOP_FORWARD`. Auf dem Emulator stürzt das im Audio-Thread ab
(`logs_emu_crash146.log`: `name: AudioTrack … signal 11 (SIGSEGV)`) — derselbe Crash wie v1.43.
Der Loop läuft deshalb über `seek(0)` kurz vor dem Ende (`SoundManager._process`, Fenster
`clamp(delta*3, 50 ms, 200 ms)`). Gemessen: `luecke_ms=0` auf Desktop **und** Gerät, 4 Neustarts
auf dem Gerät ohne Aussetzer. Siehe `BUGLISTE.md` B46-1.

### Neue Diag-Modi (v1.46)

| Modus | Zweck |
|---|---|
| `COMIC_LANTEST=musik146` | 7 Tracks: Klangbild, Wechsel (gleicher Player?), Zustand, Pause-Dämpfung, Loop-Lücke, WAV-Export + Pegeltabelle |
| `COMIC_LANTEST=hat146` | 408 Hut-Paare: Augenband, Körper, Skalierung je Rig, Kontaktblatt, Fix-Blatt |
| `COMIC_LANTEST=scroll146` | Ziehen (Maus + Touch), Mausrad, Ende der Liste, feste Kopfzeile, Nachlaufzeit |
| `COMIC_LANTEST=chal_run146` | 12 Aufgaben auf LEICHT bis zur Belohnung, 36 Stufenkombinationen |
| `COMIC_LANTEST=icon146` | 5 Icon-Entwürfe + Übersichtsblatt mit Größen |
| `COMIC_LANTEST=rig146` | Skins 64/256 px, IoU gegen Standard, Hüte auf Rig 6/7 |
| `COMIC_LANTEST=set146` | Einstellungen aus Menü und Pause (Reihen, ZURÜCK-Position) |
| `COMIC_LANTEST=name146` | Namensfeld: Trimmen, leer → HELD, Menü/Coup |

### Golden Master (neu eingefroren, mit Begründung)

Alle 8 Modi hatten **genau zwei** Diff-Zeilen, beide gewollt:
`[SND][MUSIKPEGEL] track=game_boss` → `track=boss_1` (Block E, Track umbenannt) und die neue Zeile
`[CHAR][NAME] feld=true max_zeichen=10 tastatur=geraet` (Block H). Keine Verhaltenszeile geändert.
Alte Fassung: `backup/golden_v136/<modus>.log.v145`.

### Offen / bewusst nicht gemacht

1. **Systemtastatur auf dem Emulator** nicht erzwingbar — der Emulator meldet eine Hardware-Tastatur
   (`show_ime_with_hard_keyboard=0`, `mInputShown=false`). Der Eingabeweg selbst ist belegt
   (adb-Tastendrücke landen im Feld, Übernahme funktioniert). Auf echter Hardware erscheint die
   Tastatur über `virtual_keyboard_enabled = true`.
2. **Pause-Overlay** behält seine eigene SCHWIERIGKEIT-Reihe; die Spec I1 betrifft nur die
   Einstellungsseite (siehe BUGLISTE B46-6).
3. **Icon-Auswahl** liegt beim Nutzer (J3) — kein Entwurf wurde als App-Icon gesetzt.

---

# STATUS — Stand 6.11.2026, 01:20

## v1.46 — Spec geschrieben, Recon gemessen (offen, 0/53 belegt)

Spec: `project/SPEC_V146_POLISH.md` (53 Kriterien, Blöcke A–K).
Inhalt: Umbenennung **AUFGABEN → CHALLENGES**, **6 neue Challenges** (12 gesamt, je 3 Stufen),
**smooth scrollbare** Challenge-Ansicht, **Ingame-Musik im Menü-Charakter** (Trackwechsel-Bug),
**bedrohliche Boss-Musik**, **Hüte auf Skins** fixen, **Wikinger + Geist** neu zeichnen,
**Name im Charakter-Editor**, **Schwierigkeit + Biom aus den Ingame-Einstellungen**,
**5 neue Icon-Entwürfe** zur Auswahl.

### Recon (bereits gemessen, in der Spec zitiert)

| Befund | Beleg |
|---|---|
| Musik reißt bei jedem zweiten Trackwechsel ab | neuer Modus `musik146`: `[MUSIK][STATE] tag=runde2 spieler_playing=false pos=0.00`, `tag=boss … false` — Ursache: Fade-Out und Fade-In treffen denselben `_music_player` |
| Loop hat ein Loch | `[MUSIK][LOOP] t=6s pos=7.23` → `t=8s pos=0.67`; Tracks nur 6,86–11,43 s, `loop_mode=LOOP_DISABLED` |
| Pause-Dämpfung bleibt hängen | `set_music_ducked(true)` ohne Rückweg außer `play_music()` |
| Spiel-Tracks kippen von `sine` auf `square`/`saw` und 104–120 BPM | `TRACK_CFG`: `game_2/3/4`; `menu_1` = 84 BPM, `sine`, keine Drums |
| 128 von 408 Hut-Kombinationen auffällig | neuer Modus `hat146`: `[HAT][PRUEF] ERGEBNIS paare=408 auffaellig=128`; Hut-Skalierung konstant `s=1.39…1.45` statt je Kopfbreite; Rig 0 über zweiten Zeichenweg (`_make_player` vs `_make_player_rig`) |
| Vikinger/Geist ohne eigene Silhouette | Kontaktblatt `screenshots/v139/hats_29x4.png`, Spalte WIKINGER vs STANDARD |
| Einstellungen zeigen Schwierigkeit + Biom auch im Pause-Menü | `settings_page.gd` Zeile ~88/~160, `settings_origin` bereits vorhanden |
| Name nicht editierbar | `set_player_name()` existiert (Zeile 1496), `char_page.gd` hat nur ein Label |

Neue Recon-Modi: `COMIC_LANTEST=musik146`, `COMIC_LANTEST=hat146`.

### Nächster Schritt

`SPEC_V146_POLISH.md` in der Reihenfolge A → C → B → I → H → D → E → F → G → J → K abarbeiten,
jeden Punkt mit Log-Zeile oder Screenshot belegen, Statusmarker nachtragen, APK+EXE erst am Ende.

---

# STATUS — Stand 6.11.2026, 00:05

## v1.45 — Ton, Kisten, Ladebildschirm, Glücksrad, Aufgaben als Spielmodi, Icons

Spec: `project/SPEC_V145_POLISH.md` — **alle 50 Kriterien belegt** (T 7, K 6, L 6, Z 8, C 14, I 3, F 6 + Nacharbeit L).
Auslöser war die Mängelliste des Nutzers vom 5.11. (Soundpegel, Aufgaben ≠ Spielmodi, leerer Kasten im
Ladebildschirm, Kisten-Design, zweiter Glücksmodus, App-Icons).

| Block | Stand | Beleg (Log-Zitat / Messwert / Bild) |
|---|---|---|
| **T — Ton** | **fertig** | `[SND][TABELLE] klaenge=27 rms_min=-19.3db rms_max=-8.0db streuung=11.3db clipping=0` (vorher 26 dB Streuung) · Musik `regler100_db=-0.9 ergebnis=-20.5db` = **+11 dB** gegenüber v1.44 · Regler `0 → -80 dB`, `100 → 0 dB` · 30 WAV in `screenshots/v145/audio/` |
| **K — Kisten** | **fertig** | `[TEX][CHEST] tier=… offen=… px=256 kontur=3 quelle=generiert` ×6 · Kontaktblatt `kisten_neu.png` · Shop lädt kein PNG mehr (`_load_chest_png` von keinem Pfad aufgerufen) · **K6:** `[SHOP][KARTE] tier=standard bild=270x270 fenster=324x304 luft=17px keep_aspect=true` (Desktop **und** Emulator) · Bilder `shop_1920.png`, `emu_shop_kisten.png` |
| **L — Ladebildschirm** | **fertig + Nacharbeit** | Ein Bauweg für Boot und Run (`[BOOT][UI] flaeche=geteilt boot=true`) · Panel beim Start **gefüllt**: `panel_modus=endlos icon=an leer=false` · Balken `balken=(720,28) in_flaeche=true` · Fade `[LOAD][FADE] dauer=0.25 quelle=boot geteilt=true` · **Text jetzt mittig** (Nutzer-Mangel): `[LOAD][MITTE] zustand=boot kasten=(666..1254) name=(680..1240) text_mitte=960.0 kasten_mitte=960.0 abweichung=0.0px desc_abweichung=0.0px`, im Bild nachgemessen: Kastenmitte 959 px, Textmitte 960,5 px; Sprechblase Textmitte 959 px = Blasenmitte 959 px · Bilder `boot_1080.png`, `run_load_1080.png`, **Emulator** `emu_boot.png` |
| **Z — Glücksrad** | **fertig** | `[WHEEL][DEF] segmente=8 gewicht_summe=100.0` · 200 000 Simulationen: `[WHEEL][SIM] n=200000 segment=0 soll=30.00%% ist=30.09%% abw=0.09pp …` → `rtp=0.917 band=0.85..1.05 ok=true max_abw=0.09pp` · Drehung: `[WHEEL][SPIN] ziel_segment=6 dauer=5.95s … drehungen=5 ticks_erwartet=47` → `[WHEEL][TICK] gesamt=47 erwartet=47 doppelt=false` → `[WHEEL][DAUER] gemessen=4.61s soll=4.61s ueberschwinger=false max=1858.28 ziel=1858.28` · Buchung: `[WHEEL][KAUF] einsatz=500 gold_vorher=50000 nachher=49500 ergebnis=gem3 win=0 gems=3 ersatz=0 gespeichert=true` + `[WHEEL][BUCHUNG] … ok=true`, zu wenig Gold: `[WHEEL][FEHLER] zu_wenig_gold einsatz=500 gold=50` · Shop: `[SHOP][AUTOMATEN] walze_rect=(354,1471 520x82) rad_rect=(1038,1471 520x82) gleiche_zeile=true` · Bilder `wheel_1920.png`, `wheel_ergebnis_1920.png`, `shop_automaten_1920.png`, Emulator `emu_wheel.png` / `emu_wheel_ergebnis.png` |
| **C — Aufgaben als Spielmodi** | **fertig** | 18 Stufenkombinationen: `[CHAL][STUFE] id=… stufe=… runden=… diamanten=…` ×18 (LEICHT 8–12 Runden/25–60 ◆ … HART 8–20/100–200 ◆) · Start: `[CHAL][START] id=revolver stufe=normal runden=12 waffe=REVOLVER sperren=["waffen_pickups","waffenkarten"]` · Regeln: `[CHAL][REGEL] id=revolver waffe=revolver pickups=0 waffenkarten=0`, `[CHAL][REGEL] id=eisern lp_start=1 heilung=0`, Sperren im Pickup-Pfad `[CHAL][SPERRE] pickup=… grund=…` · Ziele: `[CHAL][ZIEL] id=boss bosse=3 gezaehlt=3`, `id=sammler kisten=5/5`, `id=schnell zeit_limit=420 …` · Auswertung: `[CHAL][ENDE] id=revolver stufe=leicht ziel=ja fortschritt=8/8 diamanten=40 grund=runden_erreicht` für alle sechs · Belohnung einmal: `[CHAL][GUTSCHRIFT] id=… +40 gems=40 zweite_gutschrift=false state=BELOHNT`, zweiter Aufruf bucht nichts · Abbruch: `[CHAL][ABBRUCH] id=… zustand=LAEUFT fortschritt=1` · HUD: `[CHAL][HUD] text=REVOLVER-RUNDE · NORMAL · RUNDE 1/12` · Gesamtbeleg `[TEST][CHALRUN145] aufgaben=6 erledigt=6` · Bilder `chal_karte.png`, `chal_hud.png`, `chal_erfolg.png`, Emulator `emu_chal.png`, `emu_chal_run.png`, `emu_pause.png` |
| **I — App-Icons** | **fertig** | Sechs Entwürfe 1024×1024: `[ICON][ENTWURF] name=icon_a.png … icon_f.png` · Übersicht mit Größen 48/72/96/144: `icons_uebersicht.png` · Spiel-Icon = Entwurf A: `[BUILD] icon=icon_a.png quelle=res://icon.png px=1024 version=1.45 build=45`, im APK nachgeprüft (`res/mipmap-xxxhdpi-v4/icon.webp` zeigt den Helden mit Revolver) |
| **F — Abschluss** | **fertig** | `[BUILD] Versionsanzeige v1.45 aktiv (Build 45)` (Menü im Emulator zeigt „v1.45 · Build 45") · Golden Master: alle 8 Modi `rest_diff=0 script_errors=0`, neu eingefroren mit Begründung (alte Fassung `.log.v144`) · Diag-Modi `snd145`, `chest145`, `load145`, `wheel145`, `chal_run145`, `icon145` enden alle mit `[TEST][…145] ENDE` · Emulator-Durchlauf Boot → Aufgaben → Run → Shop (Kisten, Walze, Rad): `pidof=7538` stabil, `SCRIPT ERROR`-Zeilen = 0 · APK `apksigner verify` → v2/v3 true, `versionCode=45 versionName=1.45` · Artefakte `Desktop/ComicShooter-v1.45.apk` / `.exe` |

### Nacharbeit aus der Nutzer-Rückmeldung (L)

Der Text im Modus-Kasten stand linksbündig, und der 132-px-Platzhalter für das Modusbild blieb beim
Start leer stehen („das Feld wirkt unfertig"). Beides ist behoben: `load_mode_name` und
`load_mode_desc` sind zentriert, das Bild wird auch beim Boot gezeichnet, Balken und Status sind auf
720×28 gezogen, und `load_layout_probe()` misst die echten Rechtecke statt Zahlen zu behaupten.

### Golden Master (neu eingefroren, mit Begründung)

`chestfull upg shop mini loc2 seasons char wpn2` → **alle grün**. Die einzigen Unterschiede waren neue
Log-Zeilen aus v1.45: 27× `[SND][PEGEL]`, 7× `[SND][MUSIKPEGEL]` (Block T), `[SHOP][KARTE]` (Block K)
und `[SHOP][RAD]` (Block Z). Keine Verhaltenszeile hat sich geändert. Zusätzlich normalisiert
`tools/golden_check.sh` jetzt `NxNNN` (1-px-Rundung der Kisten-Vorschau) zu `NxN`.

### Neue Diag-Modi (v1.45)

| Modus | Zweck |
|---|---|
| `COMIC_LANTEST=snd145` | Pegel aller 27 Klänge + Musik, Clipping, WAV-Export, Reglerprüfung |
| `COMIC_LANTEST=chest145` | Kontaktblatt der sechs gezeichneten Kisten |
| `COMIC_LANTEST=load145` | Boot- und Run-Zustand der gemeinsamen Ladefläche + Mitte-Messung |
| `COMIC_LANTEST=wheel145` | Quoten (200 000 Simulationen), Drehung, Ticks, Buchung, Shop-Einbau |
| `COMIC_LANTEST=chal_run145` | alle 6 Aufgaben auf LEICHT bis zur Belohnung |
| `COMIC_LANTEST=icon145` | sechs Icon-Entwürfe + Größenblätter |

---

# STATUS — Stand 5.11.2026, 19:00

## v1.44 — Aufgaben-Seite, Shop als Automat, Kisten-Tempo, Karten-Preise

Spec: `project/SPEC_V144_CHALLENGE_SHOP.md` (40 Kriterien, 31 belegt).
Der gemeldete Crash im Debug-Fenster ist **behoben** und gemessen.

| Punkt | Ergebnis | Beleg |
|---|---|---|
| Debug-Fenster „stürzt teilweise ab" (X-B40) | **behoben** | Raster in Häppchen: `[DBG][RASTER] fertig kacheln=425 frames=165 gesamt_ms=4646 block_max_ms=126` (vorher 19 567 ms in EINEM Frame). Abbruch mitten im Aufbau: `grund=panel_zu kacheln=40` → `f9_im_aufbau panel=false raster=false kinder=0`. Speicher: `knoten_start=362 knoten_ende=362 diff=0` (5× 425 Kacheln). Ursache war das Neuzeichnen, nicht die Buttons: `[DBG][BENCH] rig_ohne_hut_ms=0 rig_mit_hut_ms=5` (vorher 21/26) |
| Optik der Figuren unverändert (Cache-Umbau) | **belegt** | `COMIC_LANTEST=hatcmp144` → `paare=425 ungleiche_paare=108 max=0.0 mean=0.0` (Abweichungen nur in vollständig transparenten Pixeln) |
| Aufgaben-Seite (C) | **neu, belegt** | `[CHAL][DEF] anzahl=6 ids=revolver,eisern,boss,schnell,ohne_schild,sammler` · `[LAYOUT] seite=aufgaben inhalt=(1720,712) ueberlauf=false` · `[TAP] ZURUECK rect=(790,820)-(1130,896) sichtbar_im_bild=true` · Zustände: `[CHAL][ZUSTAND] boss LAEUFT gold`, `schnell ERLEDIGT gruen`, `sammler BELOHNT grau` · Belohnung genau einmal: `[CHAL][BELOHNUNG] id=schnell +100 gems=300 gespeichert=true`, 2. Tap `diff=0` · `[WALK] seite_AUFGABEN/zurueck_geschlossen/erneut_offen/back_taste_geschlossen` alle OK |
| Shop im Walzen-Look (R) | **neu, belegt** | `[SHOP][STIL] bausteine=3 quelle=ui_style` · 3× `[SHOP][KARTE] tier=… fenster=320x300 chancen_zeilen=4` · `bild=270x270 fenster=324x304 luft=17px` · `[SHOP][UMTAUSCH] panel=true streifen=2 trennlinien=1` · Käufe `[SHOP][KAUF] tier=standard abgebucht=9 gems 500→491` (+silver/premium) · Tausch `gold_vorher=100000 nachher=99000 gems=1` · `[LAYOUT] seite=shop … ueberlauf=false max_rechts=1890` bei 1920 und `max_rechts=2370` bei 2400 · `[PERF][SHOP] frame_ms=3.71 draw_calls=344 knoten=515` (VSync für die Messung aus) |
| Kisten-Tempo (A) | **behoben, belegt** | `[CHEST][SPEED] phasen=linear20+out80 t1=1.52 t2=6.10 d1=-1819 d2=-1819` (stetiger Übergang) · 6 Läufe `monoton=true`, `v_start=864…1750 → v_ende=0,7…13 px/s` · letzte 0,75 s `0,39–0,92 %` der Strecke, kein Stillstand · Dauer 4,95–7,93 s · `[CHEST][TICK] gesamt=4/5` |
| Karten/Jahreszeiten (K) | **neu, belegt** | `[KARTE][PREIS] planet=mars karte=6000 saison=summer preis=2000 verhaeltnis=0.33` (JUNGLE 4 000, VOLT 6 667, ERDE 800/1 200/1 600) · `[KARTE][KAUF] planet=mars frei=["spring"] gesperrt=3` · `[SEASON][KAUF] planet=mars saison=summer preis=2000 gold_vorher=34000 nachher=32000` · nach Neustart `mars_frei=2 sommer_frei=true` · `[PROFILE][MIGR] saisons alt=10 neu=10 gratis=0` |
| Version | **1.44 / Build 44** | `APP_VERSION`/`APP_BUILD` + Export-Preset (`version/code=44`) |

### Golden Master

Fünf Modi sind **neu eingefroren** (`chestfull`, `shop`, `loc2`, `seasons`, `upg`), die alten Fassungen
liegen als `backup/golden_v136/<modus>.log.v143`. Grund: die neuen Flächen schreiben neue Log-Zeilen
(`[SHOP][KARTE]`, `[SHOP][UMTAUSCH]`, `[CHEST][SPEED]`, `[CHEST][TICK]`), `[SEASON][KAUF]` hat ein
neues Format, der Preis 6 000 → 2 000 ist die gewollte Änderung aus K1, und die `upg`-Bewegungszeile
trägt jetzt `vorher=/nachher=` (sie zählte Monster nach Index — X-B44). `char`, `mini`, `wpn2` blieben
unverändert.

### Geraetetest (Emulator `Medium_Phone_API_36.1`, 2400×1080)

Der Emulator startet auf dieser Maschine nur mit `-gpu off -no-window` (die mitgelieferte
`opengl32sw.dll` fehlt, mit GPU-Backend stuerzt er im Crash-Reporter ab). Mit diesem Aufruf
lief der komplette Weg:

| Schritt | Beleg |
|---|---|
| Aufgaben öffnen | `[LAYOUT] seite=aufgaben inhalt=(1720,712) canvas=(2400,1080) ueberlauf=false`, Bild `screenshots/v144/emu_aufgaben.png` |
| zurück → Shop | `[LAYOUT] seite=shop … ueberlauf=false max_rechts=2370`, Bild `emu_shop.png` |
| Tausch | `[SHOP][TAUSCH] gold_vorher=100005 nachher=99005 gems=1 ok=true` |
| Kiste öffnen | `[SHOP][KAUF] tier=standard abgebucht=9 gems 5001→4992`, `[CHEST][DUR] Animationsdauer=6.05 s`, Bilder `emu_chest_a/b.png` |
| Karten | `[LAYOUT] karten_saisons planet=volt knoepfe=4`, Bild `emu_karten.png` |
| Debug-Fenster (X5) | `[DEBUG] Fenster geoeffnet` → `[DBG][RASTER] fertig kacheln=425 frames=358 gesamt_ms=68829 block_max_ms=828` → `freigegeben kinder=425`; `pidof` **4457** vorher **und** nachher, `ANR` = 0 |

Auf dem Emulator (Software-Rendering) dauert der Rasteraufbau 68,8 s — **aber das Spiel bleibt
bedienbar und der Prozess lebt**. Vorher waren es 19,6 s in einem einzigen Frame (Handy: ANR).

### Artefakte

- `dist/ComicShooter-v1.44.apk` (31,5 MB, `apksigner verify` Exit 0, Signer `CN=Godot`)
- `dist/ComicShooter-v1.44.exe` (112 MB, `[BUILD] Versionsanzeige v1.44 aktiv (Build 44)`)
- Kopien: `Desktop/ComicShooter-v1.44.apk`, `Desktop/ComicShooter-v1.44.exe`
- Screenshots: `screenshots/v144/` (`aufgaben_1920`, `aufgaben_zustaende`, `chal_icons`,
  `shop_1920`, `shop_2400`, `shop_walze`, `chest_t0…t3`, `karten_1920`, `dbg_raster`,
  `emu_aufgaben`, `emu_shop`, `emu_tausch`, `emu_chest_a/b`, `emu_karten`, `emu_dbg_raster`)
- Logs: `logs_dbg144_j.log`, `logs_chal144_d.log`, `logs_shop144_e.log`,
  `logs_chest144_d.log`, `logs_karte144_a.log`, `logs_golden144_d.log`, `logs_hatcmp144_c.log`

### Neue Diag-Modi (v1.44)

| Modus | Zweck |
|---|---|
| `COMIC_LANTEST=dbg144` | Debug-Fenster: Raster in Häppchen, Abbruch, Speicher, alle Panel-Knöpfe |
| `COMIC_LANTEST=hatcmp144` | schnelle Hut-Ebene gegen die alte Fassung (425 Paare, Pixeldifferenz) |
| `COMIC_LANTEST=chal144` | Aufgaben: Definitionen, Layout, Zustände, Belohnung, Navigation |
| `COMIC_LANTEST=shop144` | Shop: Layout 1920/2400, echte Käufe, Tausch, Walze, Frame-Zeit |
| `COMIC_LANTEST=chest144` | Kisten-Laufband: Geschwindigkeitsprofil aus 6 Läufen + 4 Standbilder |
| `COMIC_LANTEST=karte144` | Kartenpreise je Planet, Kauf, Neustart-Persistenz, Migration |
| `COMIC_LANTEST=mprobe144` | bewegt sich das erste Monster im Endlos-Run (Golden-Verdacht X-B44) |

---

# STATUS — Stand 5.11.2026, 02:00

## v1.43 — Bedienbarkeit + Geraetereife (Arbeitsstand)

Die von dir gemeldeten Fehler sind behoben und auf dem Emulator
(`Medium_Phone_API_36.1`, SwiftShader) **und** auf dem Desktop belegt.
Golden Master: **8/8 „OK: Verhalten unveraendert."**

| Punkt | Ergebnis | Beleg |
|---|---|---|
| „crasht beim Antippen" (S1) | **behoben** | Einstellungen jetzt Scrollbereich + fester Fuss: `[LAYOUT] einstellungen inhalt=(1482,604) knopf_y=974 knopf_h=76 ueberlauf=false`; alle Knöpfe `sichtbar_im_bild=true` |
| „Einstellungen über den Rand" (S2) | **behoben** | Inhalt 604 px bei 1080 px Canvas (1920 und 2400 geprüft), Sichtprüfung `screenshots/v143/settings_1920.png` + `settings_2400.png` |
| „Musikauswahl" (S3) | **behoben** | Regler 88 px hoch/620 px Spur + −/+ Knöpfe; `[TAP] lautstaerke_plus wert=80`; `regler=30 db=-27.6 → 80 db=-18.6 → 100 db=-15.0`; Wert überlebt Neustart |
| Auswahlfeld Skins/Hüte (S4) | **behoben** | Raster mittig (`links=561 rechts=561 versatz=false`), 25 Hüte mit Scroll, Kachel-Klick übernimmt (`p_hat 1 → 6`) |
| Steine am Ufer (S5) | **behoben** | keine Steine im Fluss, Schaum nur an der Uferkante; `steinpixel_diff=0.0 %` (Ziel ≤ 0,5 %) |
| Start blockiert (S6.2) | **behoben** | Texturen/SFX/Musik in Häppchen: `[BOOT] haeppchen=103 max_block_ms=133`; UI-Aufbau 2,3 s → 0,36 s; Emulator-Start 53,8 s → 27,3 s |
| Zurück-Taste beendete die App (X-B36) | **behoben** | `quit_on_go_back=false` + `_handle_back_button()`; `[TAP] back_key seiten_geschlossen=1` |
| Absturz im Audio-Thread (X-B37) | **behoben** | Musik ohne Engine-Loop, Neustart im Hauptthread; Prozess lebt > 10 min |

### Was noch offen ist

1. **R1–R3 (Datei-Refactor)** — `game_manager.gd` 4560, `ui_manager.gd` 3770,
   `lan_diag_tmp.gd` 4990 Zeilen (Ziel ≤ 1500). Funktional ist alles grün; der
   Umbau ist der nächste Schritt und braucht den Golden Master nach jedem Schnitt.
2. **S6.1 (12-s-Start auf dem Emulator)** — auf dem Desktop 3,2 s, auf dem
   GPU-losen Emulator 27 s. Die Marke ist dort nicht erreichbar; auf echter
   Hardware ist der Start durch die Häppchen deutlich kürzer als v1.42.
3. **S2.2 (Finger-Drag in den Einstellungen)** — bei 1080 px passt die Seite ohne
   Scrollen; der Drag ist nicht separat gemessen.

### Artefakte

- `dist/ComicShooter-v1.43.apk` (arm64, debug-signiert, `apksigner verify` = 0)
- `dist/ComicShooter.exe` (`[BUILD] Versionsanzeige v1.43 aktiv (Build 43)`)
- Kopien: `Desktop/ComicShooter-v1.43.apk`, `Desktop/ComicShooter-v1.43.exe`
- Screenshots: `screenshots/v143/` (Desktop `settings_*`, `wahl_*`, `ufer_*`,
  Emulator `emu_*.png`)
- Logs: `logs_walk143_final2.log`, `logs_pruef143_final.log`,
  `logs_audit143_final.log`, `logs_wasser143_a.log`

### Neue Diag-Modi (v1.43)

| Modus | Zweck |
|---|---|
| `COMIC_LANTEST=audit143` | Layout- und Knopf-Audit über alle 8 Seiten |
| `COMIC_LANTEST=walk143` | kompletter Weg mit echten Klicks (25 Schritte, Desktop) |
| `COMIC_LANTEST=pruef143` | Einstellungen in 2 Breiten, Auswahlfeld mit allen Kacheln, Musikregler |
| `COMIC_LANTEST=wasser143` | Steinpixel-Differenz an der Uferkante + Screenshot |

---

# STATUS — Stand 4.11.2026, 23:59

**v1.42 ist fertig und belegt** (Abschnitt darunter, Golden Master 8/8, APK + EXE gebaut).
**Offen ist P8.5** (Gerätetest) — der wird in v1.43 nachgeholt.

## Nächste Session: SPEC v1.43

Die gemeldeten Fehler sind in `project/SPEC_V143_UI_DEVICE_REFACTOR.md` als S1–S7 + R1–R5
spezifiziert, mit Recon-Belegen (Datei/Zeile + Log-Zitat) als Ursachen:

| Nr | Fehler | Gemessene Ursache |
|---|---|---|
| S1 | „crasht beim Antippen" | Einstellungen sind eine Sackgasse: Inhalt 1189 px, Canvas 1080 px, `ZURUECK` bei y=1143 → unerreichbar |
| S2 | „Einstellungen laufen über den unteren Rand" | derselbe Überlauf, 109 px fehlen |
| S3 | „Musikauswahl klappt nicht" | Logik ok (`wert=25 → music_volume=25`), Regler liegt im abgeschnittenen Bereich |
| S4 | „Auswahlfeld Skins/Hüte links im Bild" | `ScrollContainer` zentriert sein Kind nicht (`links=60 rechts=1710`) |
| S5 | „Animation auf den Steinen am Ufer" | pulsierender Schaumring um Flusssteine, 3,5 % Steinpixel ändern sich |
| S6 | Geräte-Reife | Start 20,5 s bis zum ersten Bild (Main-Thread blockiert) |
| R1–R5 | Riesige Dateien | 4515 / 4381 / 3674 Zeilen → Ziel ≤ 1500, ohne Performance-Verlust |

Emulator ist eingerichtet und läuft: AVD `Medium_Phone_API_36.1`, APK `com.vince.comicshooter`
installiert, `adb` unter `%LOCALAPPDATA%/Android/Sdk/platform-tools/adb.exe`.

---

# STATUS — v1.42 „Bugfixes & Balance" (Runde 142, 4.11.2026)

Projekt: `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2. Spec: `project/SPEC_V142_FIXES.md`.
**Alle 14 Punkte umgesetzt und belegt** (P1, P2, P3, P4, P5, P6, P7, P9, P10, P11, P12, P13, P14, P8).
Belege je Punkt als Log-Zeile / Messwert / Screenshot; Screenshots in `screenshots/v142/`.

## Belege je Punkt

| Punkt | Beleg |
|---|---|
| P1 Pause→Einstellungen | `[MENU][SETTINGS] origin=pause start_screen_sichtbar=false pause_offen=false paused=true` · `[MENU][SETTINGS] zurueck=pause pause_offen=true` · `[PAUSE][RESUME] welle=0 hp=5/5 muenzen=0 paused=false gleich=true` · `[PAUSE][MENU] run_beendet=true start_screen=true im_runden=false` + neu `[WAVE][START] runde=1` · `[MENU][SETTINGS] esc=true` · `v142/pause_settings.png`, `v142/pause_nach_settings.png` |
| P2 Waffen-Stufen | `[WPN][RARITY] stufe=epic cooldown_mult=0.76` (1.00/0.88/0.76/0.62) · `[WPN][STATS] waffe=machine stufe=common cooldown=0.100 rpm=600` … `legendary cooldown=0.062 rpm=968` · `[WPN][DPS] monoton=true`, legendary/common 3,2–4,2× · `[LOC][CHECK] flaeche=stats knoten=6 fehlt=0` · `v142/stats_rpm.png` (4 Zeilen RPM 600/682/789/968), `v142/stats_en.png` |
| P3 Heiltrank | `[TRANK][REGEN] start hp=2/5 ziel=5 dauer=4.5s` → `+1 LP (3/5) (4/5) (5/5)` → `ende hp=5/5 ticks=3 rest=0` · `queue=1` → `queue_fertig hp=5/5` · `[WSHOP][PREIS] artikel=potion runde=1 preis=40`, `quelle=SHOP_ITEMS preis=12` · `v142/trank_regen_0..2.png` (Herz über dem Spieler, HUD 3/5 → 5/5) |
| P4 Musik | `[SFX][MUSIK] tracks=7 namen=menu_1,menu_2,game_1,game_2,game_3,game_4,game_boss` · `track=game_1 db=-15.6 regler=80 aktiv=1 fade=0.6s` · `runde=8 track=game_4` / `9 game_1` / `10 game_2` · `runde=8 track=game_boss boss=true` → danach `game_4` · jeder Track `loop=ok … bars=4` (Länge = Vielfaches der Loop-Takte) · Bauzeit 2,4 s beim Start |
| P5 Todessound | `[SFX][TOD] dauer=2.00s db=-4.0 eigener_player=true musik=-24.0 gespielt=true` · mit SFX aus: `sfx_aus=true gespielt=false musik=-24.0` · nach Neustart `musik_db=-15.6` |
| P6 LEICHT-Balance | `[RUNDEN][DIFF] stufe=leicht anzahl=0.65` (normal 1.00, hart 1.15) · `[RUNDEN][ZAHL] runde=8 leicht=16 normal=28 hart=30`, `runde=9 18/30/33` · `[RUNDEN][HP] runde=9 leicht=194.9 normal=229.4 hart=286.7` (= v1.41-Kurve) · 15-Runden-Lauf LEICHT: alle `[WAVE][ENDE] … getoetet == total`, `dauer` max. 9,4 s (Grenze 25) · `[WAVE][SPAWN] gleichzeitig_max=3 grenze=34 modus=leicht ok=true` · `[HUD][VORSCHAU] runde=9 anzahl=18 modus=leicht` |
| P7 Map-Optik | `[ART][WASSER] toene=4 min_helligkeit=0.23 max=0.60 foam_kanten=15488 steine_im_fluss=3 flow_dir=(1,0)` · zwei Frames 0,8 s auseinander: **69,7 % der Wasserpixel verändert** (Ziel > 25 %) · `[ART][STEIN] varianten=5 toene=5 kontur=true moss=true` + `v142/steine.png` · `[MAP][STEINFELD] felder=19 steine_pro_feld=2-5 varianten=5` · `[MAP][UFER] eingriff=false bruecken_frei=true banksteine=53` · `[PERF][WASSER] ms=0.16` (Ziel ≤ 1,5) · `v142/wasser_a/b.png`, `v142/map_spring…winter.png` |
| P9 Feste Biome | `[BIOME][START] map=earth biome=meadow` / `mars biome=mars` / `jungle biome=jungle` / `volt biome=volt` · `[BIOME][PLAN] map=earth wechsel_bei_runde=1,6,11,16 biome=meadow,desert,ice,lava` · `[BIOME][WECHSEL] runde=6 von=meadow nach=desert` (nur 6/11/16) · fester Lauf: `[BIOME][WECHSEL] anzahl=0 biome=mars` ×15 · `[BIOME][TRENNUNG] season=spring biome=meadow unveraendert=true` · `[TEST][P9] map_nach_neustart=mars` |
| P10 Biom-Flash | `[PERF][BIOM] aufbau_ms=56 frame_max_ms=56.0 runde=6` · `[FX][BIOM] flash=weiss dauer=0.35s overlay=true` · mit Option AUS: `[FX][BIOM] option=aus overlay=false` · `v142/biom_flash_0..3.png` |
| P11 Waffe in der Hand | `[SKIN][HAND] rig=11 hand=(46,45) deko=aus ueber_deko=true z=+1` (11–16; 12 ohne Deko-Waffe) · `[SKIN][HAND] rig=0 hand=(56,32)` = bisheriges Verhalten der 11 alten Skins · `v142/skins_waffen.png` (30 Kacheln, je eine Waffe) · `v142/skin11_waffe.png`, `v142/skin13_waffe.png` |
| P12 Charakter/Sammlung | `[PROFILE][CLAMP] feld=rigs entfernt=4 gueltig=17` · `[CHAR][SKINS] frei=17 max_index=16 gesamt=17` · `[CHAR][GRID] feld=skin kacheln=17 sichtbar=15 scroll=true overflow=false`, `feld=hat kacheln=25` · `[COLL][SKINS] angezeigt=17 frei=17 max_index=16`, `[COLL][RASTER] farben=10 huete=25 skins=17 scroll=true` · keine `WARNING`/`ERROR` beim Öffnen · `v142/char_17.png`, `char_skins.png`, `char_huete.png`, `coll_17.png` |
| P13 Hüte neue Skins | `[HAT][ADJ] rig=11..16 median_luecke=0 max_luecke=0 dy=+0.0` (gemessen, nicht geraten) · `[HAT][SITZ] rig=11..16 fehler=0 paare=126` · `v142/huete_neu6.png` (6 × 25 = 150 Kacheln) |
| P14 Ladebilder | `[LOAD][BILD] modus=runden/endlos/wellen/coop bild=load_<modus> dauer=3.2s` · `[LOAD][BILD] instanzen=2 modus=coop geteilt=true` · `[LOAD][UEBERGANG] frames_leer=0` · `[LOAD][BILD] sichtbar=0.82s` (≥ 0,8) · `v142/load_runden.png`, `load_endlos.png`, `load_wellen.png`, `load_coop.png` |
| P8 Abschluss | `APP_VERSION 1.42`, `APP_BUILD 42`, `export_presets.cfg version/code=42 name="1.42"` · Golden Master s. u. |

## Offen

- **P8.5 Gerätetest** (RUNDEN-Modus LEICHT R1–10 auf dem Handy): **blockiert** — `adb devices`
  findet kein Gerät. Sobald ein Handy hängt: `adb install -r ComicShooter-v1.42.apk`,
  Logs von beiden Seiten vergleichen, danach hier abhaken.

## Golden Master (P8.2)

`tools/golden_check.sh` → 8/8 `rest_diff=0 script_errors=0`, „OK: Verhalten unveraendert."
Basis für `loc2`, `char`, `wpn2` neu gesetzt, weil v1.42 dort **neue Belegzeilen** ausgibt
(`[WPN][STATS]`/`[WPN][STATS-UI]` mit RPM, `[CHAR][GRID]`); Altstand: `backup/golden_v136_141/`.
Der Modus `upg` ist zeitabhängig flatterhaft (Bugliste X-B28), unabhängig von v1.42.

## Sichturteil zum Biom-Flash (P10.5)

Der Aufblitz **bleibt**: Er überdeckt den einen blockierenden Aufbau-Frame (56 ms) und liest
sich als gewollter Übergang, nicht als Fehler. Der Schalter „BIOM-ÜBERGANG: AN/AUS" in den
Einstellungen lässt ihn abschalten; bei Aufbau unter 40 ms entfällt er automatisch.

## Abweichungen von der Spec (bewusst, dokumentiert)

- **P4.2/P4.5:** Tracks sind 4 Takte lang (8,0–13,3 s) statt 16 Takte. Grund: die prozedurale
  Synthese kostet in GDScript ~4 µs je Sample; 16 Takte je Track hätten den Start um >10 s
  verzögert. Loop-Regel (ganzzahliges Vielfaches der Takte, `loop_mode=LOOP_FORWARD`,
  weiche Ränder) ist erfüllt.
- **P6.2:** Die Spec nennt als Beispiel `runde=8 leicht=18`; gemessen sind es **16**, weil
  jede Gruppe einzeln abgerundet wird (`floor(13*0.65)+floor(12*0.65)+floor(3*0.65)`).
  NORMAL/HART bleiben exakt bei den v1.41-Werten.
- **P14.3:** Das Endlos-Bild zeigt das Monster-Gesicht (Signature-Gegner) statt Uhr/Schädel —
  im Projekt existiert kein Uhr-/Schädel-Sprite.

---

# STATUS — comic-shooter

> **Nächste Session: `project/SPEC_V142_FIXES.md`** (v1.42 — 14 Punkte, 80 Abnahmekriterien).
> Pause-Bug · feste Biome · Charakter/Sammlung (alte Skins + Overflow) · Waffen-Seltenheiten ·
> Trank-Regeneration · LEICHT-Balance · Hüte der 6 neuen Skins · Waffe in der Hand ·
> Musik/Todessound · Map-Optik · Biom-Flash · Ladebilder je Modus · Abschluss.
> Reihenfolge P1 → P9 → P12 → P2 → P3 → P6 → P13 → P11 → P4 → P5 → P7 → P10 → P14 → P8.
> Backlog (nicht umsetzen): Monster je Map/Biom (X1).

# STATUS — v1.41 „Fixes, Bosse, neue Monster, Skin-Kur" (Runde 141)

Projekt: `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Spec: `project/SPEC_V141_CONTENT.md`.

**Fertig mit Beleg:** F2–F5 · B1–B6 · M1–M7 · S1–S7 · N1–N5 · V1–V4.
**Offen:** nur V5 (Gerätetest — kein ADB-Gerät angeschlossen).

## Runde 141b — Skins neu gezeichnet

Auslöser: „Skins sind komplett gefärbt, sehen ähnlich aus, haben kein Gesicht,
irgendeine Textur buggt." Ursachen und Behebung: `project/BUGLISTE.md`, X-B9 bis X-B19.

| Was | Beleg |
|---|---|
| 11 Basis-Skins mit echten Augen (Augapfel/Pupille/Glanzpunkt) und Mund, je Skin eigener Stil | `screenshots/v141/skins_big.png`, `_face_pass()` in `gen_characters.gd` |
| Körper mit Licht/Schatten statt Vollton | `_shade_body()`; `[RIG][FARBE] … ok=true` danach weiter **170/170** |
| 4 Texturfehler behoben (Ninja-Schal, Roboter-Metall, 1-px-Augen, Augenversatz) | X-B9…X-B12 |
| 18 Konzept-Varianten neu gezeichnet (Schichten, Gesichter, Gerät) | `screenshots/v141/konzept_legendary.png`, `konzept_epic.png` |
| Nutzerwahl: Templer · Blauer Oni · Anubis · Klassisch · Fellkapuze · Joker | 2 Formulare à 3 Fragen, 4.11.2026 |
| 6 Skins eingebaut → 17 Skins | `[RIG][CHECK] names=17 rarity=17 hats=25 head_anchor=17` |
| Kontur-IoU der 10 neuen Skins max **0,34** (Ziel 0,55) | `[RIG][KONTUR] ERGEBNIS max_kontur_iou=0.34 ok=true` |
| Hüte sitzen auf allen 17 Skins | `[HAT][SITZ] ERGEBNIS paare=408 kopfpaare=289 fehler=0` |
| Golden Master unverändert | `tools/golden_check.sh` → 8/8 `rest_diff=0 script_errors=0`, „OK: Verhalten unveraendert." |

### Neue Skins (Rig 11–16)

| Rig | Name | Seltenheit | Variante | `[RIG][NEU]` |
|---|---|---|---|---|
| 11 | EISENKARDINAL | legendary | A Templer | `farb_ok=true iou_max=0.84` |
| 12 | ONI-FELDHERR | legendary | B Blauer Oni | `farb_ok=true iou_max=0.80` |
| 13 | EWIGER HERRSCHER | legendary | C Anubis-Priester | `farb_ok=true iou_max=0.75` |
| 14 | KAPITAEN ROST | epic | A Klassisch | `farb_ok=true iou_max=0.82` |
| 15 | FROSTBEIL | epic | A Fellkapuze | `farb_ok=true iou_max=0.84` |
| 16 | GRINSER | epic | C Joker-Maske | `farb_ok=true iou_max=0.80` |

(`iou_max` = Vollmasken-IoU gegen den ähnlichsten anderen Skin — bei aufrechten
Figuren immer hoch; das harte Maß ist die Kontur-IoU, siehe oben.)

## Belege der Punkte F/B/M/S/N/V

| Punkt | Beleg |
|---|---|
| F2 | `[MENU][LAYOUT] modus=0/1/2 box=(1181,998) row3=(1181,74) ueberlauf=false`, GRAD-Knopf sichtbar, außerhalb RUNDEN `disabled=true` |
| F3 | 11× `[WSHOP][ICON] … ok=true`, 0 `[TEX][FEHLT]`, neues `icon_revive` |
| F4 | `[STATS][UI] offen=true quelle=hud pause=true karten=5` → `offen=false … hud_sichtbar=true` |
| F5 | `[LOC][CHECK] flaeche=hud/shop/stats fehlt=0`, `[LOC][MISS] gesamt=0` |
| B1–B6 | Boss-Tabelle, `anteil ≤ 45 %`, Banner + Leiste, `getoetet == total`, `monoton=true`, `fps_avg=59.5` bei 3 Bossen |
| M1–M7 | Teilung, Frontschild (`blockiert=70 %`), Herold-Aura (`faktor=1.25`), ab R10/13/16, `hue_diff 31/48/45`, 20 Runden, `fps_avg=60.0` |
| S1–S7 | 17 Skins / 25 Hüte, Hut-Sitz 408 Paare 0 Fehler, 170/170 Farben, Migration v3→v4 |
| N1–N3 | `gen_concepts.gd` (datengetrieben, 18 Varianten), 2 Kontaktblätter, IoU-/Farbmaße je Konzept |
| N4/N5 | siehe oben |
| V1–V4 | `[BUILD] v1.41 (Build 41)` in Projekt und EXE, Golden 8/8, Docs, Builds in `dist/` |

## Hinweise für den nächsten Lauf

- **Profilzustand der Golden-Prüfung:** `golden_check.sh` filtert Zeilen, die vom
  gespeicherten Profil abhängen (`[SEASON][MODE]`, `[SPAWN][MINIBOSS] kill`,
  `[WAHL] feld=hut`). Testprofil über `COMIC_LANTEST=mksetup` herstellen.
- **Diag-Modi v1.41:** `menu141 shop141 stats141 loc141 boss141 bossrun bossbanner
  bossperf monsheet monbehave monperf skin141 skin141 hatfit migr141 mksetup
  concepts skinsbig`.
- **Neue Klasse** `GenConcepts` (`scripts/texture/gen_concepts.gd`) braucht einen
  Editor-Scan (`--headless --editor --quit`), sonst `Identifier not declared`.
- **Sichtprüfung** läuft über Kontaktblätter in `screenshots/v141/` — sie werden
  mit 230–260 px je Kachel gerendert, damit Gesichter und Hüte beurteilbar sind;
  Zoom auf eine Kachel über `vision_analyze(region=[x1,y1,x2,y2])`.

---

# STATUS — v1.41 in Arbeit (Spec: `project/SPEC_V141_CONTENT.md`)

**Los geht es in einer neuen Session.** Erledigt aus dem Bugreport: **F1** (Zufalls-Events im
Runden-Modus gesperrt, Beleg `logs_f1.log`: `[WAVE][EVENT] erlaubt=false modus=runden blockiert=1`,
keine Event-Banner). Offen: F2 (Startseite verzieht sich), F3 (Shop-Symbole), B (Bosse in späteren
Runden), M (drei neue Monster), S (18 Skins + 3 Hüte raus, 3 Skins neu zeichnen), N (6 Konzept-Skins
zur Auswahl), V (Version 1.41 + Builds).

---

# STATUS — v1.40 „Runden-Modus" (Runde 140)

Projekt: `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Spec: `project/SPEC_V140_WAVE.md` — **alle Blöcke W0–W7 `[x]`**.
Neu: dritter Spielmodus **RUNDEN** (`game_mode = 2`), 30 Runden, eigener Shop, zwei HUD-Icons.
Der alte Modus `game_mode = 1` bleibt Golden-Master (8/8 unverändert).
Builds: `dist/ComicShooter-v1.40.apk` (31,3 MB, debug-signiert, `apksigner verify` = 0) ·
`dist/ComicShooter-v1.40.exe` (111,8 MB, `[BUILD] Versionsanzeige v1.40 aktiv (Build 40)`).

## Belege je Punkt (v1.40)

| Punkt | Beleg |
|---|---|
| **W0.1** | `[WAVE][PLAN] ERGEBNIS runden=30 monoton=true max_monster=52 deckel=true`, Tabelle `tools/round_plan.md` |
| **W0.2** | `screenshots/v140/`: `shop_kat.png`, `shop_fenster.png`, `intermission.png`, `welle_besiegt.png`, `runde_voll.png`, `shop_nach_kauf.png` |
| **W0.3** | `tools/wave_baseline.md`, `[WAVE][BASE] welle=1 monster=8 hp_mult=1.00` … `welle=10 monster=35 hp_summe=209` |
| **W1.1** | `[WAVE][GRUPPE] runde=1 nr=1 typ=GREEN anzahl=17 abstand=0.69 delay=0.00` + `[WAVE][START] runde=1 gruppen=1 monster=17` |
| **W1.2** | 30× `[WAVE][PLAN] runde=<n> … hp=<summe>`; `monoton=true` (jede Runde > vorherige) |
| **W1.3** | `[WAVE][START] … hp_mult=1.00 spd_mult=1.00` (R1) → R30 `hp_mult=5.43 spd_mult=1.25` (`tools/round_plan.md`, R30 = 1.797 HP gesamt) |
| **W1.4** | `[WAVE][ENDE] runde=1 getoetet=17/17 dauer=11.0` — kein Ende vor `getoetet == total` |
| **W1.5** | `[WAVE][BANNER] runde=1 text="WELLE 1 BESIEGT"` + `intermission.png` |
| **W1.6** | `[WAVE][KISTE] erlaubt=false aufrufe=0 felder=0 kisten=0` am Rundenende, `[WAVE][KISTE] … (platzierung uebersprungen)` beim Start |
| **W1.7** | `[WAVE][BOSS] runde=5 typ=23 MINI-BOSS hp=90`, `[WAVE][BOSS] runde=10 typ=19 BOSS hp=135` |
| **W1.8** | Sicherheitsnetz im Code (`[WAVE][WARNUNG] … notende nach 90 s`) — im Test **nicht** ausgelöst (Runden endeten regulär) |
| **W2.1** | `[WAVE][INTERMISSION] t=5.0 wartet=true runde=1`, `[WAVE][RUN] warten7s … unveraendert=true` |
| **W2.2** | `[WAVE][UI] icons=2 shop=true next=true`, Knoten `WaveShopBtn` / `WaveNextBtn` unter der Waffen-/Tränke-Leiste (`intermission.png`) |
| **W2.3** | `[WAVE][UI] shop_pause=true` beim Öffnen, `[WAVE][UI] shop_pause=false` beim Schließen |
| **W2.4** | `[WAVE][UI] klick quelle=maus ok=true runde=3->4 icons=false` |
| **W2.5** | derselbe Klick läuft als **echtes** `InputEventMouseButton` über `get_viewport().push_input` (Maus/Touch-Pfad) |
| **W2.6** | `[WAVE][HUD] text="WELLE 1 · MONSTER 0/17 · MÜNZEN 0"` |
| **W3.1** | `[WSHOP][BAU] kategorien=3 karten=11 reihenfolge=WAFFEN,LEBEN,TRAENKE` + `shop_kat.png` |
| **W3.2** | `[WSHOP][FENSTER] artikel=weapon_shotgun offen=true`, `[WSHOP][RUN] fenster=true` + `shop_fenster.png` |
| **W3.3** | `[WSHOP][WAFFE] key=weapon_shotgun seltenheit=epic schaden=8 rpm=75 preis=475 gekauft=true rest=4525`; schon ausgerüstet → Knopf „AUSRÜSTEN" |
| **W3.4** | `[WSHOP][LEBEN] art=herz wert=1 preis=90 ok=true max=6`, `art=revive wert=1 preis=220 ok=true`; Grenzen `[WSHOP][LEBEN] … ok=false limite=erreicht` |
| **W3.5** | `[WSHOP][TRANK] art=potion effekt=1 preis=40 ok=true`, `art=frost effekt=10s preis=60 ok=true` |
| **W3.6** | `[WSHOP][SORT] kategorie=waffen preise=[110,140,165,195,225] aufsteigend=true`, `leben [70,90,220]`, `traenke [40,55,80]` |
| **W3.7** | `[WSHOP][KAUF] preis=615 guthaben=34 ok=false grund=zu_wenig_muenz`, Münzen danach unverändert 34 |
| **W3.8** | `[WSHOP][RUN] kinder_5x=[2,2,2,2,2] konstant=true` (5× öffnen/schließen) |
| **W3.9** | `[WSHOP][ANGEBOT] runde=1 artikel=frost` → `runde=2 artikel=revive`; nach Kauf `… gekauft=true ausverkauft=true` |
| **W4.1** | `[WAVE][ECO] runde=1 kills=17 muenzen=+17 bonus=+17 gesamt=34` |
| **W4.2** | `[WAVE][ECO] bonus runde=1 17 runde=10 57 faktor=3.35 (Ziel >=3.0) ok=true` |
| **W4.3** | `[WSHOP][PREIS] herz_runde1_10=[90,95,105,110,115,125,130,135,145,150] monoton=true` |
| **W4.4** | `tools/wave_economy.md`: 30 Runden, nie negativ, **Endstand 928** (Ziel 0–2000); `[WAVE][ECO][SIM] ENDE stand=928 herzen=5 leben=2` |
| **W4.5** | `[WAVE][ECO] gnade=true runde=3` (bei 0 Münzen) |
| **W5.1** | `monoton=true` über alle 30 Runden (`tools/round_plan.md`) |
| **W5.2** | `max_monster=52 deckel=true`, R1 = 17 → R20/30 ≤ 52 |
| **W5.3** | `[WAVE][TYP] typ=9 name=GOLEM faehigkeit=Panzerung 50 %, HP-Brocken, teilt Schaden` (10 Arten), Tabelle in `tools/round_plan.md` |
| **W5.4** | `[PERF][WAVE] runde=20 fps_avg=60.0 proc_ms=0.02 draw_max=75 nodes_max=896 monster_live=42`, 0 `SCRIPT ERROR` |
| **W6.1** | `[WAVE][VORSCHAU] runde=2 typen=18x GREEN boss=false`, sichtbar in `intermission.png` |
| **W6.6** | `[WAVE][THEMA] runde=7 thema=PANZER hp_mult=1.79` (Themen 7/14/21/28 im Plan) |
| **W6.8** | `[MODE][CHECK] grad=leicht herzen=8 hp=0.85 preis=0.90`, `normal 5/1.00/1.00`, `hart 3/1.25/1.20`; Knopf `GRAD` im Menü |
| **W7.1** | `[MODE][CHECK] wahl=0 name=ENDLOS label=MODUS: ENDLOS`, `wahl=1 … WELLEN + SHOP`, `wahl=2 … MODUS: RUNDEN` |
| **W7.2** | `golden_check.sh`: 8/8 `rest_diff=0 script_errors=0` → „OK: Verhalten unveraendert." + Perf-Leitplanke eingehalten |
| **W7.3** | diese Datei, `SPEC_V140_WAVE.md`, `project/BUGLISTE.md` (W-B1…W-B7), `project/ARCHITEKTUR.md`, `screenshots/v140/` |
| **W7.4** | `dist/ComicShooter-v1.40.apk` + `dist/ComicShooter-v1.40.exe` |

## Bedienung

1. Menü → `MODUS: RUNDEN` (3. Klick auf den Modus-Knopf), darunter `GRAD: LEICHT/NORMAL/HART`.
2. Run startet mit Runde 1; Gegner laufen in Gruppen ein.
3. Runde leer → Banner **„WELLE n BESIEGT"** + zwei Icons rechts oben: **SHOP** (pausiert) und **WELLE >>**.

---


Projekt: `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Spec: `project/SPEC_V139_LOOKS.md` — **alle Blöcke M, A, B, C, D, E `[x]`**.
Builds: `dist/ComicShooter-v1.39.apk` (31,2 MB, debug-signiert) · `dist/ComicShooter-v1.39.exe` (111,8 MB).

## Belege je Punkt

| Punkt | Beleg |
|---|---|
| **M1** | `screenshots/v139/hats_29x4.png` (1384×2518, 116 Kacheln, je „idx NAME" + Rig), Log `[SHEET] hats=29 rigs=4 kacheln=116` |
| **M2** | `screenshots/v139/rigs_25.png` (29 Kacheln), `[SHEET] rigs=29` |
| **M3** | `[RIG][IOU]` × 406 Paare, Matrix in `tools/rig_iou.md`, 153 Paare ≥ 0,80 |
| **M4** | `logs_m4.log`: `[COLL][1]`…`[COLL][5]`, `[COLL][ENDE] fehler=0`, 0 `SCRIPT ERROR` |
| **A1** | kein Repro des Absturzes (`logs_m4.log`, `logs_m4b.log`, je 0 `SCRIPT ERROR`), Ursache „Sammlung kaputt" = B26 (kein Scroll → ZURÜCK unerreichbar) behoben; offen: B27 (Gerätelog) |
| **A2** | `[COLL][ZAEHLER] farben=.. skins=.. huete=..` == `[COLL][SEKTION]` == `[COLL][INFO]` |
| **A3** | `[COLL][ZUSTAND] kinder=426 ref=426 gleich=true` (5×), `[COLL][PERF] … delta=0` |
| **A4** | 5× ZURÜCK → Startseite, danach wieder SAMMLUNG, `[COLL][ENDE] fehler=0`, `coll-reopen.png` |
| **A5** | `[COLL][KLICK] kachel=farbe/skin/hut … ignoriert=true` |
| **B1** | `[CHEST][SKIP] bereit=true tasten=ui_cancel`, Knoten `ChestSkip` im Overlay, `logs_b_taste.log` (Skip per `ui_cancel`) |
| **B2** | `[CHEST][SKIP] t=0.01 rest=7.29`, Messung `0.09 s ≤ 0.50`; `[CHEST][RESULT] … gleich=true` in `logs_b_skip.log` **und** `logs_b_noskip.log` |
| **B3** | `dist/chest_dur10.log`: `[CHEST][DUR] Ergebnis: 10/10 in 4,5-8,0 s` |
| **B4** | `[SHOP][UI][10.48][CHEST] geschlossen -> shop refresh (chest_page=true)`, `[CHEST][CLOSED] shop_seite_sichtbar=true`, 0 `SCRIPT ERROR` |
| **B5** | `logs_b_strip.log`: `[CHEST][STRIP] verschieden=3/3 positionen=[15, 15, 22]`, Sieger-Item nicht als Niete |
| **C1** | `project/docs/HUT_NAMEN.md` (29 Zeilen, 0 offen; STROHHUT behoben) |
| **C2** | `hats_kappe_25.png`, `[HAT][SITZ] hut=1 rig=0..28` Überstand 0–1 px |
| **C3** | `hats_alien.png` (8 Hüte vorher/nachher), Augen frei (RIG_HAT_ADJ −9) |
| **C4** | `hats_roboter_mars.png` (Kappe vorher/nachher) |
| **C5** | alle 28 Kopf-Hüte auf Rig 7 ohne Fehler (`logs_d_fit.log`) |
| **C6** | `[HAT][C6] … farbton_diff=177 (Ziel >=25) form_diff=47% (Ziel >=20) ok=true` |
| **C7** | `[HAT][SITZ] ERGEBNIS paare=812 kopfpaare=551 fehler=0`, Regeln in `project/docs/HUT_SITZ.md` |
| **D1** | `project/docs/SKIN_SLOP.md` (153 Paare ≥ 0,80, alle „behalten") |
| **D2** | `[PROFILE][MIGR] von=v2 nach=v3 p_rig=12->"STRASSENKÄMPFER" p_hat=3->"KRONE" ok=true` + `[PROFILE][CHECK] nach_neustart p_rig=12` |
| **D3** | 0 entfernt (Vorgabe), `[RIG][LISTE] anzahl=29`, Sammlung ohne leere/doppelte Kacheln |
| **D4** | neue Skins max. IoU 0,52 (Ziel ≤ 0,55), `rigs_25.png` |
| **D5** | `[RIG][CHECK] names=29 rarity=29 arme=29 hats=29 hat_rarity=29` |
| **D6** | `[DEBUG][UNLOCK] rigs=29/29 huete=29/29 farben=10/10`, Sammlung danach 29/29 |
| **D7** | `[HAT][SITZ] … rig=25..28`, 0 Fehler in den 551 Kopf-Paaren |
| **E1** | `[BUILD] Versionsanzeige v1.39 aktiv (Build 39)` (Projekt **und** exportierte EXE), `apksigner verify` = exit 0 |
| **E2** | `[PERF] fps_avg=56.1 proc_ms=0.02` (Projekt) / `57.5 / 0.02` (EXE); `golden_check.sh` 8/8 grün |
| **E3** | `project/ARCHITEKTUR.md` (Zeilenstände), dieses STATUS.md, `project/BUGLISTE.md` (B26–B33), Blätter in `screenshots/v139/` |

## Offene Punkte (bewusst)

- **B27**: Der gemeldete Sammlungs-Absturz ist auf dem Desktop nicht reproduzierbar (0 `SCRIPT ERROR` in zwei Stress-Läufen). Nächster Schritt: `adb logcat` auf dem Gerät.
- **B28**: Erster Aufbau der Sammlung blockiert 1,3 s (64 Texturen in einem Frame).
- **B24/B25** aus v1.38 unverändert offen (Boss-HP negativ, APK nur debug-signiert).

## Zwischenfälle in dieser Runde

- Beim Anhängen der neuen Raritäten wurde `HAT_RARITY` versehentlich auf 33 Einträge verlängert (29 Hüte). Gefunden durch `[RIG][CHECK] names=29 … hat_rarity=33` im `dcheck`-Lauf, korrigiert auf 29, danach `fehler=0`.

---

# STATUS — v1.36 fertig (Runde 136)

Projekt: `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Spec: `project/SPEC_V136.md` — **alle Punkte `[x]`** (A–K + Build).
Builds: `dist/ComicShooter-v1.36.apk` (31,1 MB) · `dist/ComicShooter-v1.36.exe` (111 MB).

## Belege je Block

| Block | Beleg |
|---|---|
| **A1** | `[SHOP][CARD] gem idx=0 gold=1000 gems=1 icons=gold,gem` + `screenshots/v136/230-shop-karten-oben.png` |
| **A2** | `_flash_card()`: Verlauf, 5 px Kontur, Versatzschatten, 9 px Akzentkante, Hover +12 %; Shots `230-shop-karten*.png` |
| **A3** | `[SHOP][BACK] Ergebnis oben: 5/5 geschlossen` (4 Ecken + Mitte, echter Input-Event) |
| **A4** | `[SHOP][SCROLL] scroll_vertical=0 (Start 0) top_pad=28` |
| **B1/B2** | `[SLOT][UI] Gewinnschema: 7 Zeilen`, kein „%" im Bild, `screenshots/231-walze-gewinnschema.png` |
| **C1** | `[CHEST][SPEED] durchgehend 1 Phase1 45% + Phase2 55% (kein Stop)` |
| **C2** | 12 Bandframes, 0 identische Nachbarpaare (Diffs 250.469 → 70.805 px), `screenshots/v136/chestseq/` |
| **C3** | `10/10 in 4,5-8,0 s` (`logs_c_dur10.log`) |
| **D1** | `[TEST][D1] felder=3 scrollbar=false`, `screenshots/v136/232-char-neu.png` (Figur 420 px, 3 Felder, kein Scroll) |
| **D2** | `[WAHL] feld=hut pikto=kappe idx=1 tex=true` |
| **D3** | `[WAHL] feld=hat frei=2 gesamt=29` / `kacheln=2` |
| **D4** | `screenshots/v136/232c-sammlung.png` (Sammlung unverändert, alle Items) |
| **D5** | `--headless` ohne `SCRIPT ERROR`, keine „Identifier not declared" |
| **E1** | `[SPAWN][MINIBOSS] typ=MINI_EARTH welle=3 dist=450 abstand_ok=true`, `[BOSS][NAME] ERD-KÄFER`, `235-miniboss.png` |
| **E2** | `balance hp=72 (6x Normal 12)`, `kill nach 1.9s, gold=+30`, `[CHEST][DROP] … seltenheit=rare` |
| **E3** | `[SPAWN][MINIBOSS] blockiert (lebt noch)` |
| **G1** | Kette `chest_lock → chest_open_premium → tick×3 + tick_slow → chest_land → chest_win_legendary`; 4 WAVs `screenshots/v136/snd/` |
| **H1** | `[UPG][TOAST] verfuegbar=2 paused=false`, Welt läuft (`1/1 Monster in 0,5 s bewegt`), `233-upgrade-toast.png` |
| **H2** | `[UPG][WINDOW] offen idx=1 von 2` → `rest=1` → `idx=1 von 1` → `rest=0` |
| **H3** | `[UPG][TOAST] entfernt (run vorbei)` |
| **I1** | `[SEASON][KAUF] planet=mars season=summer preis=2500 gold_vorher=20000 gold_nach=17500`; zu wenig Gold ohne Abzug |
| **I2** | `[SEASON][MODE] (cycle, pool=[spring, summer])`, `[SEASON][WECHSEL] von=spring nach=summer` — nie autumn/winter; `ABGELEHNT … (zu klein)`; `FEST` bleibt |
| **I3** | `[SEASON][HUD] FRUEHLING · als Nächstes: SOMMER`, `screenshots/v136/234-seasons-hud.png` |
| **J1** | `[WPN][DROP] verteilung common=125 rare=56 epic=12 legendary=7` (200 Rollen) |
| **J2** | `[WPN][STATS] waffe=revolver stufe=legendary schaden=19 reload=1.4 mag=9 speed=496` |
| **J3** | `[WPN][BALANCE]` fünf Zeilen, Faktoren 0,74–1,27 (Revolver 9→11 Schaden) |
| **J4** | `screenshots/236-waffen-stufen.png` (4 Stufen in 4 Farben) |
| **K1** | `[LOC][SET] sprache=en texte=85 uebersetzt=23` + `[LOC][APPLY] +13/+1` |
| **K2** | `[LOC][SAVE] lang=en im Profil`; Umschalter in den Einstellungen, `239-settings-sprache.png` |
| **K3** | `screenshots/v136/237-menu-en.png`, `238-shop-en.png` |
| **F1** | APK + EXE gebaut, Smoke-Test: `[BUILD] Versionsanzeige v1.36 aktiv (Build 36)` |

## Neue Diag-Modi (`COMIC_LANTEST=<mode>`)

`snd` · `chestfull` · `chestseq` · `dur10` · `upg` · `mini` · `shop` · `seasons` · `char` · `wpn` · `lang`


---

## Nachtrag Runde 136b — die zwei offenen Punkte erledigt

| Punkt | Was | Beleg |
|---|---|---|
| **J4-HUD** | Waffen-HUD zeigt die Stufe: Rahmenfarbe nach Seltenheit + Farbkante oben (4/6/8/10 px), Tooltip „WAFFE · STUFE"; Signatur-Cache berücksichtigt die Stufe | `[WPN][HUD] slot=weapon_revolver stufe=legendary farbe=(0.99,0.72,0.20) kante=10px` (rare blau 6 px, epic lila 8 px); `screenshots/v136/240-waffen-hud.png` |
| **J4-Stats** | Waffen-Stats-Seite: Rahmenfarbe + Label „STUFE: …" je Karte | `[WPN][STATS-UI] waffe=weapon_laser stufe=epic`; `screenshots/v136/241-waffen-stats.png` |
| **K-Abdeckung** | Übersetzung von 121 → **5** offene Texte; `[LOC][T] fehlt=` loggt jede Lücke genau einmal, Präfix-/Suffix-Regeln für Zahlenzeilen (SCHADEN 3 → DAMAGE 3, 12 💎 ÖFFNEN → 12 💎 OPEN), Tooltips, DE-Rückweg über `loc_de`-Meta | `[TEST][K] fehlend=5 uebersetzt=163`; `screenshots/v136/238-shop-en.png` (BACK, CHESTS, EXCHANGE, OPEN, TOP UP GEMS) |
| **Wörterbuch** | 300 Einträge: Menü, HUD, Shop, Charakter (10 Farben, 29 Hüte, 25 Skins), Karten/Jahreszeiten, Pause, Einstellungen, Waffen-Stats, Ladezitate | `project/scripts/loc.gd` |

**Restliche 5 „fehlend"** (bewusst, keine echten Lücken):
`P2` · `II` · `COMIC SHOOTER` (Titel) · `v1.36 · Build 36` (Version) · eine zusammengesetzte
Charakterzeile, die nur beim allerersten Aufbau vor dem Sprachwechsel entsteht.

**Builds neu:** `dist/ComicShooter-v1.36.apk` (31,1 MB) · `dist/ComicShooter-v1.36.exe` (111 MB),
Smoke-Test `[BUILD] Versionsanzeige v1.36 aktiv (Build 36)` + `[LOC][INIT] gespeicherte sprache=en`.

## Offen / nächste Runde

1. Zwei-Handy-Lauf mit v1.36 (LAN, Seasons, Mini-Bosse) auf echter Hardware.
2. Zwei Deko-Zitate des Ladebildschirms sind übersetzt, weitere Sprüche folgen demselben
   Muster in `LOAD_QUOTES` (ui_manager.gd) — bei neuen Sprüchen Eintrag in `loc.gd` ergänzen.

## Eigenheit für Testläufe

Im Diag-Lauf liegt der **Ladebildschirm** über der Welt (`load_screen`), nicht
`start_screen`. Vor Beleg-Shots beide ausblenden — im echten Spielfluss tritt das nicht auf.

---

## Runde 137 — Architektur-Umbau begonnen (Plan: `project/SPEC_V137_ARCH.md`)

**Neu:** `project/ARCHITEKTUR.md` (Modulkarte, Messwerte, Umbau-Regeln).

**Messnetz (bleibt dauerhaft drin):**
- `COMIC_LANTEST=perf` → FPS, Prozess-/Physik-Zeit, Draw-Calls, Node-Zahl
- `[BOOT][0..3]` in `game_manager._ready` → welche Boot-Phase wie viel kostet
- `[TEX][BOOT]` / `[TEX][LAZY]` / `[TEX][FEHLT]` / `[TEX][TRACE]` (mit `COMIC_TEX_DEBUG=1`)
- Golden Master in `backup/golden_v136/` (8 Diag-Modi, normalisiert)

**Umgesetzt: P2.3 Lazy-Texturen**

| Messung | vorher | jetzt |
|---|---|---|
| Boot bis `GameManager._ready` | 16 204 ms | **6 974 ms** |
| Texturen beim Start | 255 Keys | **91 Keys** (2 939 ms) |
| Texturen beim Run-Start | — | 168 Keys (1 165 ms, im Ladebildschirm) |
| Wanduhr-Boot headless | 17,0–17,9 s | **14,1–15,9 s** |
| `[PERF]` fps / proc_ms | 56,1 / 0,02 | 56,3 / 0,02 |

Belege: `[TEX][BOOT] eager=boot keys=91 ms=2939` · `[BOOT][0] _ready start ms=6974` ·
`[PERF] fps_avg=56.3 proc_ms=0.02`.

**Golden Master:** `chestfull`, `char`, `upg`, `loc2` identisch (0 Diff-Zeilen);
`mini` nur im zufälligen Mini-Boss-Typ, `wpn2`/`shop`/`seasons` nur in der Reihenfolge
der LOC-Logs. Verhalten unverändert.

**Offen (bewusst, nächste Runden):** P1.4 Ordnerstruktur · P2.2 Zeichner-Split
(`texture_manager.gd` noch 4 3xx Zeilen) · P3 UI-Module (`ui_manager.gd` 6 8xx) ·
P4 Core-Module (`game_manager.gd` 4 9xx) · P5 Entities · P6 Build v1.37.

**Wichtig für die nächste Sitzung:** Ein Umbau-Schritt gilt erst als fertig, wenn
die 8 Golden-Master-Modi verglichen sind. Reihenfolge und Abnahmekriterien stehen
in `SPEC_V137_ARCH.md`; die Umbau-Regeln (Fassade, ein Modul pro Schritt, Messung
nach jedem Schritt) in `ARCHITEKTUR.md`.

### Runde 137 — Ergebnis

- **P2.3 Lazy-Texturen: fertig.** Boot bis `_ready` 16 204 → **6 974 / 7 793 ms**,
  Texturen beim Start 255 → 91 Keys. Golden Master: `chestfull`, `shop`, `char` identisch,
  `upg` 1 Zeile Reihenfolge, `mini` nur Zufallstyp.
- **Builds:** `dist/ComicShooter-v1.37.apk` + `.exe`, Smoke `[BUILD] … v1.37 (Build 37)`.
- **P3.1 Style-Modul: zurückgerollt.** Mechanischer Split hat Member-Deklarationen
  mitgerissen und `ui_style.gd` mit Parse-Fehler hinterlassen; `ui_manager.gd` aus
  `backup/scripts_v136/` wiederhergestellt, Rollback verifiziert (0 funktionale Diffs).
  Vorgehen für den nächsten Versuch steht in `SPEC_V137_ARCH.md`.
- **Offen:** P1.4 Ordner, P2.2 Zeichner-Split, P3.2–P3.4, P4, P5.

---

## Übergabe an den nächsten Chat (Stand 2026-11-03, v1.37)

**Diese Sitzung endet hier. Nächster Auftrag:** `project/SPEC_V138_SPLIT.md`
(Modul-Split, ausführbar, mit Werkzeug und Prüfschritten).

**Was funktioniert und belegt ist:**
- v1.37 gebaut: `dist/ComicShooter-v1.37.apk` + `.exe`, Smoke `[BUILD] … v1.37 (Build 37)`.
- Boot bis `GameManager._ready`: 16 204 → 6 974 / 7 793 ms (`[BOOT][0]`).
- Texturen: `_gen_boot()` 91 Keys, `_gen_run()` 168 Keys lazy (`[TEX][BOOT/LAZY]`).
- Golden Master grün (`chestfull`, `shop`, `char`, `upg` 0–1 Diff-Zeilen).
- Werkzeuge: `tools/split_func.py` (Funktionen exakt schneiden, geprüft),
  `tools/golden_check.sh` (Regressionsprüfung, geprüft: „OK: Verhalten unveraendert.").

**Was NICHT fertig ist:** der eigentliche Datei-Split (P3/P4/P5). `ui_manager.gd`
ist nach dem gescheiterten Versuch wieder auf v1.36b (6 808 Zeilen), `game_manager.gd`
4 927, `texture_manager.gd` 4 352. Der Fehlversuch und seine Lehren stehen in
`SPEC_V137_ARCH.md` (Abschnitt „Rückgerollt") und in `SPEC_V138_SPLIT.md` („Bekannte Fallen").

**Startzeile für den neuen Chat:**
```
Lies C:/Users/vince/Games/comic-shooter/project/SPEC_V138_SPLIT.md und arbeite die
Blöcke in der dort festgelegten Reihenfolge ab. Nimm für jeden Schnitt
tools/split_func.py, prüfe nach jedem Schritt mit ./tools/golden_check.sh und trage
die Statusmarker in der Spec nach. Baue APK+EXE erst am Ende (Block J).
```


---

# STATUS — v1.38 (Runde 138): Modul-Split

Projekt: `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Spec: `project/SPEC_V138_SPLIT.md`. Builds: `dist/ComicShooter-v1.38.apk` (31,2 MB,
debug-signiert) · `dist/ComicShooter-v1.38.exe` (111,7 MB).

## Ergebnis in einem Satz

Die drei Monolithen sind zerlegt, ohne dass sich Spielverhalten messbar geändert hat:
`texture_manager.gd` 4 355 → **215**, `ui_manager.gd` 6 808 → **3 348**,
`game_manager.gd` 4 936 → **4 255**; dazu 33 neue Module in `core/` (7), `texture/` (8),
`ui/pages/` (6), `ui/overlays/` (7), `ui/` (2), `entities/` (3).

## Status je Block

| Block | Status | Beleg |
|---|---|---|
| A Werkzeug/Messnetz | `[x]` | 6 Werkzeugfehler gefunden + behoben (B20–B23); `--check` zeigt „11 Zeilen, 2 Parameter" |
| B Style (18 Funktionen) | `[~]` | `ui_style.gd` 273 Zeilen, Golden 8/8; Zeilenziel 6 400 arithmetisch nicht erreichbar (18 Funktionen = 177 Zeilen) |
| C Texturen (151 Funktionen) | `[x]` | `texture_manager.gd` 215 Zeilen, 8 Module; **292 Textur-Hashes vor/nach identisch** |
| D UI-Seiten (6) | `[x]` | Golden 8/8 nach jeder Seite; `ui_manager.gd` 6 611 → 4 934 |
| E Overlays (7) | `[x]` | `upg`-Kette und `mini`-Boss-Leiste unverändert; 4 934 → 4 095 |
| F HUD (22 Funktionen) | `[~]` | `ui/hud.gd` 829 Zeilen, 4 095 → 3 348; Ziel 900 verfehlt (Rest nicht in der Spec-Liste) |
| G Core (7 Module) | `[~]` | alle 7 angelegt, Golden 8/8; 4 936 → 4 255; Ziel 1 200 verfehlt |
| H Entities (3) | `[x]` | `wpn2` + `mini` grün; `player_controller` 787, `monster_ai` 766 |
| I Ordnerstruktur | `[x]` | 13 Dateien verschoben, Pfade nachgezogen, Autoloads neu, Golden 8/8 |
| J Abschluss | `[x]` | beide Builds, Smoke `[BUILD] Versionsanzeige v1.38 aktiv (Build 38)` |

## Messwerte

| Messung | v1.36 | v1.38 |
|---|---|---|
| Boot Wanduhr (gleiche Maschine, 3 Läufe) | 18 502 / 16 753 / 17 996 ms | **12 351 / 12 345 / 12 635 ms** |
| `[PERF]` fps_avg / proc_ms | 56,1 / 0,02 | **56,2 / 0,02** |
| `[PERF]` draw_max / nodes_max | 56 / 994 | **72 / 1 022** |
| Golden Master | — | **8/8 grün, 3× reproduziert** |

## Was NICHT fertig ist (ehrlich)

1. **`ui_manager.gd` 3 348 statt < 900.** In der Spec-Liste stehen 18 + 6 + 7 + 22
   Funktionen; im File stecken zusätzlich Startbildschirm, Ladebildschirm, LAN-Panel,
   Kisten-Overlay (~480 Zeilen) und der Rest der Shop-Seite (~220). Für eine reine
   Fassade fehlen vier weitere Module (`ui/start_screen.gd`, `ui/load_screen.gd`,
   `ui/lan_panel.gd`, `ui/chest_overlay.gd`). Werkzeug (`tools/hostify.py`) liegt bereit.
2. **`game_manager.gd` 4 255 statt < 1 200.** Gleiche Ursache: die sieben Module
   decken ~40 von 267 Funktionen ab; Run-Loop, Chest-Sequenz und Netz-Glue sind
   noch drin.
3. **APK ist debug-signiert** — es gibt keinen Release-Keystore im Projekt (B25).
4. **Boss-HP negativ** (B24) — Spiel-Bug, nicht durch den Split verursacht.

## Neue Werkzeuge (alle in `tools/`)

`split_func.py` (repariert) · `split_block.py` (viele Schnitte, topologisch sortiert) ·
`split_plan.py` (ist eine Funktion statisch verschiebbar?) · `hostify.py`
(zustandsbehafteten Code in ein Modul mit `host`) · `postfix_pages.py`
(Konstanten/Enums/Node-API nachziehen) · `move_consts.py` (repariert) ·
`drop_wrappers.py` · `extract_registry.py` · `collapse_wrappers.py` ·
`move_scripts.py` · `texhash.gd` (Textur-Fingerprint) · `golden_check.sh` (repariert).


---

## v1.56 — Balance über alle Modi (9.11.2026)

Spec: `project/SPEC_BALANCE_V156.md` · Bericht: `project/BALANCE_BERICHT.md`

### Was gebaut ist

| Punkt | Datei | Beleg |
|---|---|---|
| Zentrales Druck-Modell | `project/scripts/core/balance.gd` (**neu**) | `[BAL][MODELL] modus=… druck=… ziel=… abweichung=…` |
| Adapter (keine zweite Zahlenquelle) | `waves.gd`, `rounds.gd`, `game_manager.DIFFICULTY` | `grep -rn "WAVE_BALANCE" project/scripts/` → leer |
| Sägezahn-Spawn (Anlauf/Peak/Erholung) | `monster_spawner.gd` (Endlos), `waves.gd` (Wellen), `rounds_mode.gd` (Runden) | `[BAL][PHASE]`, `[BAL][ERHOLUNG]` |
| Rollen-Mix + Hetzer-Limit | `Balance.rolle_waehlen()` in allen drei Spawnern | `[BAL][MIX] … aktiv_max=…` |
| Bosse: Telegraph, keine Adds, 2 Phasen, HP aus Spieler-DPS | `monster_spawner.gd`, `waves.gd`, `rounds_mode.gd`, `game_manager._process` | `[BAL][BOSS] telegraph=2.0 … adds=0`, `[BAL][BOSS] phase=2 … unverwundbar=1.0` |
| Rettungsanker | `monster_spawner._anker_tick()` | `[BAL][ANKER] art=levelup+heilung grund=hp_niedrig` |
| Shop-Guthaben an Druck | `game_manager._open_shop()` | `[BAL][SHOP] … verhaeltnis=1.00` |
| Zufalls-Events im Modell | `game_manager._trigger_random_event()` | `[BAL][EVENT] art=swarm gespawnt=… (Modell statt 14)` |
| i-Frames gegen Salbentod | `player_controller.take_damage()` (`IFRAME_MS = 600`) | 5 Herzen in einem Frame nicht mehr möglich |
| Bot-Proxy | `scripts/tools/lan_diag_tmp.gd` (`balmodel`, `balbot`) | `[BOT][LAUF] profil=… modus=… zeit=…` |

### Messwerkzeuge (neu)

```
./Godot.exe --headless --path project            # mit COMIC_LANTEST=balmodel  -> Modell-Tabelle
COMIC_LANTEST=balbot COMIC_BAL_MODE=endlos COMIC_BAL_STUFE=normal \
  COMIC_BAL_PROFIL=anfaenger COMIC_BAL_LAEUFE=2 COMIC_BAL_TS=4 COMIC_BAL_MAX=11
tools/bal_matrix.sh                              # 15 Zellen der Messmatrix
python tools/bal_auswertung.py --write           # Tabelle in BALANCE_BERICHT.md
```

### Ergebnis (Median, Bot-Proxy; Rohlogs `logs_bal_mx_*.log`)

| Modus | Stufe | Anfänger | Ziel | |
|---|---|---|---|---|
| ENDLOS | LEICHT | 9:14 | 8–12 min | ✓ |
| ENDLOS | NORMAL | 4:14 | 4–8 min | ✓ |
| ENDLOS | SCHWER | 1:08 | 1:30–3:00 | ✗ |
| ENDLOS | HARDCORE | 0:28 | < 1:30 | ✓ |
| WELLEN | NORMAL | Welle 6 | 6–9 | ✓ |
| RUNDEN | NORMAL | Runde 5 | 5–8 | ✓ |

9 von 13 Zellen getroffen, 4 verfehlt (zu hart) — Details und Gegenmaßnahmen in
`project/BALANCE_BERICHT.md` §5.

### Golden + Exporte

- `./tools/golden_check.sh` → **8/8 grün** (Referenz `mini` neu gesetzt, dokumentiert)
- `dist/ComicShooter-v156.apk` (31,8 MB, debug-signiert, versionName 1.56)
- `dist/ComicShooter-v156.exe` (106 MB, Smoke-Lauf `[BAL][START] version=1.56 … fehler=0`)
- `dist/ComicShooter-v156-iOS.zip` (120 MB, unsigniert — kein Zertifikat)
- Kopien auf dem Desktop

### Offen

- Zellen LEICHT (Runden/Wellen), SCHWER (Endlos/Wellen) und Erfahren-Durchläufe liegen
  über dem Zielkorridor „zu hart" (Bericht §5, Gegenmaßnahmen benannt).
- D4 Handspiel-Protokoll: Belegbilder vorhanden (`screenshots/v156/`), „gefühlt 1–5"
  nicht messbar.


---

## v1.57 — Bugfixes aus dem Spieltest (9.11.2026)

Vier gemeldete Fehler, alle mit Log-Beleg behoben (Details `project/BUGLISTE.md` X-B75…X-B78):

| Bug | Ursache | Beleg |
|---|---|---|
| Elektro-Welt spawnte Wiesen-Monster | Welt-Typen waren alle „hetzer" → Fallback auf GREEN | `[BAL][POOL] karte=volt … pool=[25,25,26,26,27,29,29]`, `feld={ "VOLT_TROOPER": 5 }` |
| Erste 20 s keine Gegner | Schonfrist 20 s + leerer Anlauf | `[BAL][ANLAUF] t=6.0 erster_schub=true`, 5 Gegner bei t=10 s |
| Wellen-Modus blieb stehen, kein Shop | Nachschub-Block kehrte vor dem Spawn zurück (`phase_left=-256 s`) | `[BAL][NACHSCHUB] … schub=3`, 11× `Welle N geraeumt -> Shop` |
| Kisten-Knopf reagierte nicht auf Tipp | globale Drag-Erkennung schluckte jede Fingerbewegung (≥ 8 px) | `[TOUCH][KISTE] zug=8/14/25px oeffnung=true` |

**Artefakte:** `dist/ComicShooter-v157.apk` (31,8 MB, versionName 1.57, apksigner ok),
`dist/ComicShooter-v157.exe` (Smoke: `version=1.57 … fehler=0`), Kopien auf dem Desktop.
**Golden:** 8/8 grün. **Neue Testmodi:** `chesttouch` (Kiste per echtem Touch), `balshot` (Belegbilder).

### v1.58 — Kisten-Tipp (9.11.2026)

Der eigentliche Fehler war nicht der Knopf, sondern die **Öffnung**: `ChestOpenUI` hat
`MOUSE_FILTER_STOP` am Root, damit kam `_unhandled_input()` nie an — die Kiste blieb nach
dem Kauf für immer zu (`stage=0` nach 6 Tipps). Tipp-Weiche liegt jetzt in `_gui_input()`
(+ Fallback), Doppelzählung gesperrt; die ganze Kartenfläche kauft; fehlende Diamanten
zeigen ein Banner. Beleg: `logs_touch9.log`, `logs_chest_apk.log`.

Artefakte: `dist/ComicShooter-v158.apk` (31,8 MB, versionName 1.58, apksigner ok),
`dist/ComicShooter-v158.exe`; Kopien auf dem Desktop. Golden 8/8 (Referenzen `mini`,
`loc2`, `shop` um die neuen Belegzeilen ergänzt).
