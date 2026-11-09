# SPEC v1.42 — Bugfixes & Balance (Pause, Waffen, Tränke, Musik, Leicht-Modus, Map-Optik)

Projekt: `C:/Users/vince/Games/comic-shooter` · Basis: v1.41 (fertig) · Godot 4.7.2
Status-Spalte: `[ ]` offen · `[~]` läuft · `[x]` erledigt (Beleg vorhanden)

**Reihenfolge:** P1 → P9 → P12 → P2 → P3 → P6 → P13 → P11 → P4 → P5 → P7 → P10 → P14 → P8
(P1 blockiert jedes Weiterspielen, P9/P12 sind sichtbare Bugs, P2/P3/P6 ändern Gameplay, P13/P11 sind Skin-Details, P4/P5 sind Ton, P7/P10/P14 Optik, P8 ist Abschluss.)

**Grundregel:** Jeder Punkt braucht eine Log-Zeile, einen Messwert oder einen Screenshot.
Diagnose-Muster wie in v1.41: `COMIC_LANTEST=<modus> ./Godot.exe --path project`,
Modi in `project/scripts/tools/lan_diag_tmp.gd`, Bilder nach `screenshots/v142/`.

---

## P1 — Pause → Einstellungen wirft ins Startmenü (BLOCKIEREND)

**Befund (Recon v1.41):**
- `scripts/ui/overlays/pause.gd:108` — Knopf `EINSTELLUNGEN` ruft `host._open_settings_page()`.
- `scripts/ui/ui_manager.gd:1747` — `_open_settings_page()` ruft **immer** `_close_pages()`.
- `scripts/ui/ui_manager.gd:1761` — `_close_pages()` endet mit `start_screen.show()`.
- `scripts/ui/pages/settings_page.gd:131` — Knopf `ZURUECK` ruft `host._close_pages()`.

⇒ Aus der Pause öffnet sich das Startmenü **hinter** den Einstellungen; „ZURÜCK" zeigt es
erneut. Der Run gilt als verlassen, `start_screen` liegt über dem Spiel, der Pause-Overlay
ist weg, `get_tree().paused` bleibt stehen → weder weiterspielen noch neu starten möglich.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P1.1** | Einstellungen merken ihren Aufrufer: `settings_origin` = `"menu"` \| `"pause"` (+ `"run"` für den Gear-Knopf im HUD) | `[MENU][SETTINGS] origin=pause` im Log | `[x]` |
| **P1.2** | Aus der Pause: `_open_settings_page()` blendet **nur** den Pause-Overlay aus, `start_screen` bleibt verborgen | `[MENU][SETTINGS] start_screen_sichtbar=false pause_offen=false` | `[x]` |
| **P1.3** | `ZURUECK` kehrt zum Aufrufer zurück (Pause-Overlay wieder da, Spiel bleibt pausiert; aus dem Menü: Startseite) | `[MENU][SETTINGS] zurueck=pause` · Screenshot `pause_nach_settings.png` zeigt Pause-Overlay | `[x]` |
| **P1.4** | Nach ZURÜCK: „WEITERSPIELEN" setzt `get_tree().paused = false` und der Run läuft weiter (Welle, HP, Münzen unverändert) | `[PAUSE][RESUME] welle=8 hp=4/5 muenzen=120 paused=false` vorher/nachher identisch | `[x]` |
| **P1.5** | „HAUPTMENÜ" aus der Pause bleibt ein echter Abbruch: Run endet sauber, Startseite **spielbar** (neues Spiel startbar) | `[PAUSE][MENU] run_beendet=true start_screen=true im_runden=false`, danach Knopf „RUNDEN" drückbar, `[WAVE][START] runde=1` | `[x]` |
| **P1.6** | Rückweg über ESC aus den Einstellungen (Tastatur) verhält sich wie ZURÜCK | `[MENU][SETTINGS] esc=true zurueck=pause` | `[x]` |

---

## P2 — Waffen-Seltenheiten müssen spürbar sein (Feuerrate)

**Befund:** `scripts/entities/player/weapons.gd:30` — `WEAPON_RARITY` hat nur
`damage / reload / mag / speed` (Geschossgeschwindigkeit). `_wd()` (Zeile 60) skaliert
**`cooldown` nicht** → Feuerrate ist für gewöhnlich/selten/episch/legendär identisch.
Deshalb fühlt sich jede Stufe gleich an.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P2.1** | `WEAPON_RARITY` bekommt `cooldown` (Faktor auf die Schussfolge) und größere Abstände: `common 1.00 / rare 0.88 / epic 0.76 / legendary 0.62` | Tabelle im Code + `[WPN][RARITY] stufe=epic cooldown_mult=0.76` | `[x]` |
| **P2.2** | `_wd()` wendet den Faktor an: `out["cooldown"] = base["cooldown"] * rarity_mult(key,"cooldown")`, Untergrenze 0,05 s | `[WPN][STATS] waffe=machine stufe=common cooldown=0.100` … `stufe=legendary cooldown=0.062` | `[x]` |
| **P2.3** | Schaden spreizt deutlicher: `1.00 / 1.30 / 1.65 / 2.10`, Nachladen `1.00 / 0.86 / 0.74 / 0.60`, Magazin `1.00 / 1.20 / 1.45 / 1.75` | `[WPN][STATS]` je Waffe × 4 Stufen, DPS-Abstand legendary/common **≥ 2,5×** | `[x]` |
| **P2.4** | Anzeige zieht nach: Statistik-Overlay (`stats_page.gd`) und Shop-Karten zeigen RPM **und** Schaden der **aktuellen** Stufe, nicht der Basis | Screenshot `v142/stats_rpm.png` mit vier Zeilen RPM 600/682/789/968 für dieselbe Waffe | `[x]` |
| **P2.5** | Seltenheits-Labels erklären den Unterschied (Kurztext DE/EN), z. B. episch „+45 % Magazin, −24 % Schussabstand" | `Loc`-Einträge vorhanden, `[LOC][CHECK] flaeche=stats fehlt=0` | `[x]` |
| **P2.6** | Kein Rückschritt: Waffe mit `mag = 0` (Pistole) bleibt ohne Nachladen, DPS-Kurve steigt monoton über die Stufen | `dps_table()` für jede Stufe aufsteigend, Log `[WPN][DPS] monoton=true` | `[x]` |

---

## P3 — Heiltrank regeneriert 3 Herzen, heilt nicht 1 Punkt

**Befund:** `scripts/player_controller.gd:182` — `use_potion()` macht `heal(2)`
(2 HP sofort, bei 5 Herzen = 40 %). Gewünscht: 3 Herzen über kurze Zeit nachfüllen.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P3.1** | Trank heilt **3 HP als Regeneration** über 4,5 s (1 HP je 1,5 s), nicht sofort | `[TRANK][REGEN] start hp=2/5 ziel=5 dauer=4.5s` → drei Zeilen `+1 LP (3/5) (4/5) (5/5)` | `[x]` |
| **P3.2** | Regeneration stoppt am Maximum, überschüssige Ticks verfallen | `[TRANK][REGEN] ende hp=5/5 ticks=3 rest=0`, kein HP über `max_health` | `[x]` |
| **P3.3** | Während der Regeneration sichtbar: pulsierendes Herz über dem Spieler + HUD-Herzen füllen sich nacheinander | Screenshot `v142/trank_regen_0.png` / `_1.png` / `_2.png` mit 3/5, 4/5, 5/5 | `[x]` |
| **P3.4** | Zweiter Trank während laufender Regeneration addiert (max. 1 Trank gleichzeitig aktiv, Rest wartet) | `[TRANK][REGEN] queue=1` — kein HP-Verlust, keine Doppel-Ticks | `[x]` |
| **P3.5** | Beschreibung stimmt in DE und EN: „regeneriert 3 Herzen über 4,5 s" / „regenerates 3 hearts over 4.5 s" (Shop + HUD-Tooltip) | `[LOC][CHECK] flaeche=shop fehlt=0`, Screenshot Shop-Karte | `[x]` |
| **P3.6** | Preis/Balance: Trank bleibt bei 12 Münzen im Runden-Shop, `2x TRANK`-Karte bei 300 | Shop-Werte unverändert (`[SHOP][PREIS]`-Log) | `[x]` |

---

## P4 — Musik lauter und mehrere Soundtracks

**Befund:** `scripts/autoload/sound_manager.gd` — `_music_player.volume_db = -19.0`
(Spiel), `_music_menu.volume_db = -22.0`, SFX-Pool `-8.0`. Es gibt genau **zwei**
Tracks (`_gen_music_menu()`, `_gen_music_game()`), `play_music("game")` läuft endlos.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P4.1** | Lautstärke anheben: Spiel **−12 dB**, Menü **−15 dB**, dazu `music_volume`-Regler (0…100 %) in den Einstellungen, Standard 80 % | `[SFX][MUSIK] track=game db=-15.6 regler=80` (Regler 100 % = −12 dB) | `[x]` |
| **P4.2** | Mindestens **4 Spiel-Tracks** (unterscheidbar in Tempo/Tonart/Instrumentierung) + 2 Menü-Tracks | `[SFX][MUSIK] tracks=6 namen=menu_1,menu_2,game_1,game_2,game_3,game_4` | `[x]` |
| **P4.3** | Track wechselt pro Runde (Reihenfolge fest, kein Zufall), Übergang weich (0,6 s Fade statt harter Schnitt) | `[SFX][MUSIK] runde=9 track=game_3 fade=0.6s` — bei Runde 8, 9, 10 unterschiedliche Tracks | `[x]` |
| **P4.4** | Beim Boss erscheint der Boss-Track, danach zurück zum Rundentrack | `[SFX][MUSIK] boss=true track=game_boss` → `boss=false track=game_3` | `[x]` |
| **P4.5** | Kein Klick/Knacken im Loop: Tracklänge ist ganzzahliges Vielfaches der Loop-Bars, `loop_mode` gesetzt | `[SFX][MUSIK] loop=ok laenge=16.00s bars=16` für jeden Track | `[x]` |
| **P4.6** | Menü-/Spielwechsel schaltet sauber (kein doppelt laufender Track) | `[SFX][MUSIK] aktiv=1` beim Wechsel Menü → Spiel | `[x]` |

---

## P5 — Todessound

**Befund:** `_streams["death"] = _gen_sweep(400→50 Hz, 1.2 s)` existiert
(`sound_manager.gd:289`) und wird an zwei Stellen gespielt
(`game_manager.gd:2897`, `:3429`) — im Runden-Modus ist er zu leise/undifferenziert
und die Musik läuft unverändert weiter.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P5.1** | Eigener Todes-Jingle (2,0 s, absteigend + Ausklang), deutlich lauter als SFX-Standard (`+4 dB`), nicht vom SFX-Pool verdrängt (eigener Player) | `[SFX][TOD] dauer=2.00s db=-4.0 eigener_player=true` | `[x]` |
| **P5.2** | Musik wird beim Tod auf −24 dB abgesenkt und beim Neustart wieder angehoben | `[SFX][TOD] musik=-24.0` → `[SFX][MUSIK] musik=-12.0` nach Neustart | `[x]` |
| **P5.3** | Tod im **Runden-Modus** löst ihn aus (nicht nur Endlos-Modus) | `[WAVE][TOD] runde=8` + `[SFX][TOD]` in derselben Log-Sequenz | `[x]` |
| **P5.4** | Bei ausgeschaltetem SFX bleibt es still, Musik-Absenkung passiert trotzdem | `[SFX][TOD] sfx_aus=true gespielt=false musik=-24.0` | `[x]` |

---

## P6 — LEICHT im Runden-Modus zu schwer (ab Runde 8/9 zu viele Monster)

**Befund:** `scripts/core/rounds.gd:10` — `DIFFICULTY` skaliert nur `herzen`, `hp`, `preis`,
`muenz`. **Die Monsteranzahl ist für alle Schwierigkeiten identisch**
(`monster_count()` liest nur `def_for(r)["groups"]`). Runde 8 = 28 Monster, Runde 9 = 30,
unabhängig von LEICHT.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P6.1** | `DIFFICULTY` bekommt `anzahl`: `leicht 0.65`, `normal 1.00`, `hart 1.15` | `[RUNDEN][DIFF] stufe=leicht anzahl=0.65` | `[x]` |
| **P6.2** | `monster_count(r, diff)` und die Spawn-Liste nutzen den Faktor (abgerundet, mindestens 1 Monster je Gruppe, Bosse unberührt) | `[RUNDEN][ZAHL] runde=8 leicht=18 normal=28` · `runde=9 leicht=19 normal=30` | `[x]` |
| **P6.3** | Zusätzlich Obergrenze je Runde für LEICHT: `MAX_MONSTER_LEICHT = 34` (NORMAL 52), nie mehr gleichzeitig im Feld | `[WAVE][SPAWN] gleichzeitig_max=34` bei einem 15-Runden-Lauf LEICHT | `[x]` |
| **P6.4** | Simulation LEICHT R1–15: kein Run über 25 s, keine Welle mit `getoetet < total` (kein Hänger) | `[WAVE][ENDE] … dauer=…` 15×, alle `getoetet == total`, `dauer ≤ 25.0` | `[x]` |
| **P6.5** | NORMAL und HART bleiben unverändert (Golden Master muss grün bleiben) | `tools/golden_check.sh` → 8/8 `rest_diff=0` | `[x]` |
| **P6.6** | HP-Kurve bleibt wie in v1.41 (kein Doppel-Nerf): `hp_total(9,"leicht")` unverändert, nur die Anzahl sinkt | `[RUNDEN][HP] runde=9 leicht=…` = Wert aus v1.41 | `[x]` |
| **P6.7** | Anzeige: Wellen-Vorschau im HUD zeigt die Anzahl der **gewählten** Schwierigkeit | `[HUD][VORSCHAU] runde=9 anzahl=19 modus=leicht` | `[x]` |

---

## P7 — Map-Optik: Wasser und Steinfelder

**Befund:** `scripts/map_generator.gd:252` `_build_water_layer()` mit
`shaders/water.gdshader` (zwei Sinus-Wellen, `speed 0.30`, `tiles (20,80)`; Schaum nur
am Ufer). Steine: `jrock`, `prop_stone_1`, `prop_stone_2` (Zeile 927) — flache graue
Flächen ohne Kante/Textur. Beides wirkt im Spiel wie „graue Felder".

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P7.1** | Wasser fließt sichtbar **in Flussrichtung** (UV-Offset entlang der Flussachse statt nur vertikalem Sinus), mit Stromschnellen an Engstellen | Shader-Uniform `flow_dir`; zwei Frames 0,8 s auseinander → Pixel-Differenz > 25 % der Wasserfläche | `[x]` |
| **P7.2** | Wasser hat Tiefenwirkung: Randbereiche heller (Ufer), Mitte dunkler, mindestens **4** Blautöne | `[ART][WASSER] toene=4 min_helligkeit=… max=…`, Screenshot `v142/wasser.png` | `[x]` |
| **P7.3** | Schaum/Gischt nur an Uferkante und an Steinen im Fluss, animiert (pulsierend) | `[ART][WASSER] foam_kanten=…`, Sichtprüfung: kein weißes Band quer durch den Fluss | `[x]` |
| **P7.4** | Steine mit echter Textur: Kante (dunkler Umriss), 3–5 Grautöne, Moos/Gras an der Unterseite, wechselnde Formen (nicht dasselbe Sprite 20×) | `[ART][STEIN] varianten≥4 toene≥4` + Kontaktblatt `v142/steine.png` | `[x]` |
| **P7.5** | Steinfelder als **Feld** erkennbar: Gruppen aus 2–5 Steinen unterschiedlicher Größe, mindestens eine Kante am Feldrand | `[MAP][STEINFELD] felder=… steine_pro_feld=2-5` | `[x]` |
| **P7.6** | Ufersteine ragen nicht ins Wasser (v1.41-Regel bleibt) und brechen keine Brücke | `[MAP][UFER] eingriff=false bruecken_frei=true` | `[x]` |
| **P7.7** | Performance: Wasser-Shader kostet ≤ 1,5 ms je Frame in Runde 20 | `[PERF][WASSER] ms=1.2` | `[x]` |
| **P7.8** | Sichtprüfung in vier Jahreszeiten (Frühling/Sommer/Herbst/Winter) — Wasser bleibt blau, Steine passen zur Palette | 4 Screenshots `v142/map_<season>.png` | `[x]` |

---

## P8 — Abschluss

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P8.1** | Version **1.42** (`APP_VERSION`, `APP_BUILD` 42, Export-Preset) | `[BUILD] Versionsanzeige v1.42 aktiv (Build 42)` in Projekt **und** EXE | `[x]` |
| **P8.2** | Golden Master 8/8 unverändert | `tools/golden_check.sh` → „OK: Verhalten unveraendert." | `[x]` |
| **P8.3** | Doku: `STATUS.md`, `BUGLISTE.md` (X-B20… für P1/P2/P3/P6), `ARCHITEKTUR.md` | Dateien aktualisiert, jeder Punkt mit Log-Zitat | `[x]` |
| **P8.4** | Builds: `dist/ComicShooter-v1.42.apk` (signiert, `apksigner verify` = 0) + `.exe` (Smoke-Test `[BUILD] v1.42`) | beide Dateien vorhanden, Verify-Exit 0 | `[x]` |
| **P8.5** | Gerätetest Runden-Modus LEICHT R1–10 (falls ADB-Gerät hängt) | Log von beiden Seiten, keine Abweichung | `[ ]` **blockiert: kein ADB-Geraet** (`adb devices` leer) |

---

## P9 — Feste Biome: die Map darf ihr Biom nicht mehr wechseln

**Befund (Recon):**
- `scripts/game_manager.gd:34` — „Im Wellen-Modus wechselt die Jahreszeit jetzt alle 4 Wellen".
- `scripts/core/seasons.gd:68` — `season_mode_of(planet)` liefert per Default `"fixed"`, wird aber
  nirgends erzwungen; `game_manager.gd:1814` setzt `biome_id` nur beim Weltstart.
- Map „ERDE" (`game_manager.gd:632`) hat `biome = "meadow"`, die Beschreibung verspricht aber
  „Wiese, Wüste, Eisfeld, Lavahölle in einem Run" → wer das nicht will, bekommt trotzdem Wechsel.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P9.1** | `season_mode == "fixed"` heißt wirklich fest: **kein** Biomwechsel während eines Runs, auch nicht an Rundengrenzen | 10-Runden-Lauf auf fester Map: `[BIOME][WECHSEL] anzahl=0 biome=meadow` | `[x]` |
| **P9.2** | Reise-Maps („ERDE") wechseln **nur an Rundengrenzen** und nur laut Plan, nie mitten in einer Welle | `[BIOME][PLAN] map=earth wechsel_bei_runde=1,6,11,16 biome=meadow,desert,ice,lava` + `[BIOME][WECHSEL] runde=6 von=meadow nach=desert` | `[x]` |
| **P9.3** | Beim Start gilt das Biom der **gewählten** Map (nicht meadow als Fallback) | `[BIOME][START] map=mars biome=mars` für alle Maps | `[x]` |
| **P9.4** | Jahreszeit ändert Farbe/Wetter, aber **nicht** das Biom — getrennte Felder (`season_id` ≠ `biome_id`) | `[BIOME][TRENNUNG] season=sommer biome=meadow unveraendert=true` | `[x]` |
| **P9.5** | Biomwechsel ist im Log eindeutig nachvollziehbar (von/nach, Runde, Auslöser) | die Zeilen aus P9.2/P9.3 im Log, keine stillen Wechsel | `[x]` |
| **P9.6** | Gespeicherte Map-Wahl bleibt nach Neustart erhalten (kein Zurückspringen auf meadow) | `[MAP][WAHL] aktiv=<id>` nach Neustart identisch | `[x]` |

---

## P10 — Ruckeln beim Biomwechsel verdecken (Flash), nur wenn es gut aussieht

**Befund:** Beim Biomwechsel wird die Welt neu aufgebaut (Boden, Wasser, Props) — im Spiel
als deutlicher Hänger sichtbar.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P10.1** | Übergang wird gemessen: Dauer des Weltaufbaus und längster Frame | `[PERF][BIOM] aufbau_ms=<x> frame_max_ms=<y> runde=<n>` | `[x]` |
| **P10.2** | Überblendung: kurzer Weiß-/Farbflash (≤ 0,35 s) + 0,25 s Ausblenden, während der Weltaufbau läuft; Spiel pausiert in dieser Zeit | `[FX][BIOM] flash=weiss dauer=0.35s overlay=true` | `[x]` |
| **P10.3** | Kein Flash, wenn der Aufbau unter 40 ms liegt (dann unnötig) | `[FX][BIOM] flash=aus grund=schnell aufbau_ms=31` | `[x]` |
| **P10.4** | Abschaltbar in den Einstellungen („BIOM-ÜBERGANG AN/AUS"), Standard AN; bei AUS kein Overlay | `[FX][BIOM] option=aus overlay=false` | `[x]` |
| **P10.5** | **Sichturteil:** sieht der Übergang gut aus, bleibt er; wirkt er billig, wird er ersatzlos entfernt und das hier dokumentiert | 4 Screenshots `v142/biom_flash_0..3.png`; Entscheidung + Begründung in `STATUS.md` | `[x]` |

---

## P11 — Skins mit Waffe in der Hand: echte Spielwaffe muss oben liegen

**Befund:** Die neuen Skins 11–16 zeichnen eine eigene Waffe
(`gen_concepts.gd`: Streitkolben, Axt, Stab, Säbel, Karten). Im Spiel hält die Figur
aber zusätzlich die ausgerüstete Waffe — beide liegen übereinander, die Skin-Waffe
verdeckt die echte.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P11.1** | Jeder Skin bekommt einen **Handanker** (Position der Waffenhand), wie `HEAD_ANCHOR` für Hüte | `[SKIN][HAND] rig=11 hand=(46,45)` … für alle 17 Skins | `[x]` |
| **P11.2** | Die **echte** Waffe wird am Handanker gezeichnet und liegt **über** der Skin-Deko (`z_index` höher) | `[SKIN][HAND] rig=11 waffe=machine ueber_deko=true z=+1` | `[x]` |
| **P11.3** | Skin-Deko, die die echte Waffe sichtbar überlappt, wird in diesem Fall ausgeblendet (nicht doppelt) | `[SKIN][HAND] rig=11 deko=aus grund=ueberlappung` | `[x]` |
| **P11.4** | Alle 6 neuen Skins × 5 Waffen als Kontaktblatt, Waffe sitzt in der Hand und zeigt in Schussrichtung | `screenshots/v142/skins_waffen.png` (30 Kacheln), Sichtprüfung ohne Fehlgriff | `[x]` |
| **P11.5** | Bestehende 11 Skins unverändert im Verhalten (Golden + `skins_big.png` identisch zur v1.41-Fassung außer Deko-Fix) | `tools/golden_check.sh` grün, Diff der Kontaktblätter nur bei 11–16 | `[x]` |

---

## P12 — Charakter-/Sammlungs-Anzeige: alte Skins + Overflow

**Befund:** `char_page.gd:144` liefert `unlocked_rigs.duplicate()` ungeprüft, `:208` setzt
`grid.columns = 5` ohne Scroll, `:320` liest `RIG_NAMES[rig]`. Nach der Skin-Reduktion
29 → 11 → 17 können dort **alte Indizes (≥ 17)** stehen (aus v3-Profilen oder
`debug_unlock_all` älterer Builds) → alte/leere Kacheln, und 17 Kacheln à 150 px
sprengen das Fenster.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P12.1** | Beim Laden werden Freischalt-Listen auf `0 … RIG_NAMES.size()-1` begrenzt, ungültige Einträge entfernt (mit Log) | `[PROFILE][CLAMP] feld=rigs entfernt=12 gueltig=17` | `[x]` |
| **P12.2** | Charakter- und Sammlungsseite zeigen **genau** die vorhandenen Skins (17), keine alten Namen/Bilder | `[CHAR][SKINS] frei=17 max_index=16` · `[COLL][SKINS] angezeigt=17` | `[x]` |
| **P12.3** | Kachelraster scrollt, statt über den Rand zu laufen; keine Kachel wird abgeschnitten | `[CHAR][GRID] kacheln=17 sichtbar=15 scroll=true overflow=false` | `[x]` |
| **P12.4** | Kein Overflow in der Konsole (keine „size is negative"/„minimum size" Warnungen) beim Öffnen von Charakter und Sammlung | Log ohne `WARNING`/`ERROR` aus `char_page`/`collection_page` | `[x]` |
| **P12.5** | Gleiches gilt für die Hut-Auswahl (25) und Farben (10) | `[CHAR][GRID] feld=hut kacheln=25 scroll=true` | `[x]` |
| **P12.6** | Screenshots beider Seiten mit voller Liste | `v142/char_17.png`, `v142/coll_17.png` | `[x]` |

---

## P13 — Hüte für die 6 neuen Skins optimieren

**Befund:** `gen_characters.gd` — `RIG_HAT_ADJ` enthält nur `7…10`. Die neuen Köpfe
(Schakel-Ohren, Dreispitz-Krempe, Kapuze) haben andere Oberkanten, Hüte sitzen dort
per Default-Anker.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P13.1** | `RIG_HAT_ADJ` um 11–16 ergänzt, je Skin gemessen (nicht geraten) | `[HAT][ADJ] rig=11 dy=+2.0 rig=13 dy=+3.0 …` für alle sechs | `[x]` |
| **P13.2** | Kein Hut schneidet in Ohren/Krempe, keiner schwebt (Lücke ≤ 1 px) | `[HAT][SITZ] rig=11..16 fehler=0`, je Skin `ueberstand` ≤ 1 px | `[x]` |
| **P13.3** | Alle 25 Hüte × 6 neue Skins als Kontaktblatt, Sichtprüfung | `screenshots/v142/huete_neu6.png` (150 Kacheln) | `[x]` |
| **P13.4** | Hut-Maske bleibt hinter den Ohren des Schakels (kein Durchstechen) | Sichtprüfung `rig=13` mit KRONE und ZYLINDER, Log `[HAT][SITZ] rig=13 … ok=true` | `[x]` |

---

## P14 — Ladebildschirm mit Modus-Vorschau

**Befund:** Es gibt einen Lade-Overlay (`ui_manager.gd:791` `load_actor`, `:934`) ohne
Modusbezug; vor Spielstart ist der Modus nirgends zu sehen.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **P14.1** | Je Modus ein Vorschaubild im Stil des Startbildschirms (RUNDEN, ENDLOS, WELLEN, COOP) inkl. Name + Ein-Satz-Beschreibung | `[LOAD][BILD] modus=runden bild=load_runden dauer=1.2s` für alle vier Modi | `[x]` |
| **P14.2** | Bild erscheint während der Ladezeit und bleibt **mindestens 0,8 s** sichtbar (kein Aufblitzen) | `[LOAD][BILD] sichtbar=1.10s` — Wert ≥ 0.8 | `[x]` |
| **P14.3** | Das Bild zeigt den Modus erkennbar (Runden: Wellen + Boss, Endlos: Uhr/Schädel, Wellen: Welle, COOP: zwei Figuren) | 4 Screenshots `v142/load_<modus>.png`, Sichtprüfung | `[x]` |
| **P14.4** | Kein Flackern beim Übergang ins Spiel (Bild → Spiel in einem Frame, kein weißer Frame dazwischen) | `[LOAD][UEBERGANG] frames_leer=0` | `[x]` |
| **P14.5** | Läuft auch im Splitscreen/COOP (beide sehen dasselbe Bild) | `[LOAD][BILD] instanzen=2 modus=coop` | `[x]` |

---

## Backlog (NICHT in v1.42 umsetzen, nur notiert)

| # | Idee | Warum später |
|---|---|---|
| **X1** | Monster je Map/Biom unterschiedlich (im Runden-Modus dieselben Monster auf jeder Map) | Erst nach Balance-Abschluss von v1.42 — hängt an `Rounds.groups_for()` und den Biom-Tabellen; braucht eigene Messreihe (HP-Kurve je Biom), sonst kippt die Balance aus P6. |
| **X2** | Waffen-Skins je Biome | Kosmetik, nach X1 sinnvoll. |

---

## Testplan (Reihenfolge)

1. `./Godot.exe --headless --path project --check-only --script res://scripts/ui/ui_manager.gd` (Syntax)
2. `COMIC_LANTEST=pause142` — P1 komplett (Menü → Pause → Einstellungen → ZURÜCK → WEITERSPIELEN → HAUPTMENÜ → neues Spiel)
3. `COMIC_LANTEST=wpn142` — P2 Tabelle `[WPN][STATS]` für 5 Waffen × 4 Stufen + `[WPN][DPS]`
4. `COMIC_LANTEST=trank142` — P3 Regeneration, HP-Verlauf, Queue
5. `COMIC_LANTEST=runde142` — P6 Zählungen LEICHT/NORMAL/HART je Runde 1–15
6. `COMIC_ROUNDS=15 COMIC_LANTEST=leichtrun` — End-to-End LEICHT, Dauer/Kills
7. `COMIC_LANTEST=musik142` — P4/P5 Trackliste, Fades, Todes-Jingle, Pegel
8. `COMIC_LANTEST=map142` — P7 Wasser/Steine, Kontaktblätter, Pixelmessung
9. `COMIC_LANTEST=biom142` — P9 Biomfestigkeit + P10 Flash/Messung
10. `COMIC_LANTEST=hand142` — P11 Handanker + Waffen-Overlay (30 Kacheln)
11. `COMIC_LANTEST=ui142` — P12 Clamp, Raster, Overflow-Warnungen
12. `COMIC_LANTEST=hat142` — P13 Hut-Sitz der sechs neuen Skins
13. `COMIC_LANTEST=load142` — P14 Ladebilder je Modus
14. `./tools/golden_check.sh` — P8.2
15. Export APK + EXE, Smoke-Test

## Was NICHT geändert wird

- Monster- und Boss-Balance aus v1.41 (nur die Anzahl auf LEICHT), HP-Kurven bleiben.
- Skins/Hüte/Farben (17/25/10) und das Farbregel-Werk aus v1.41.
- Endlos-Modus-Balance (nur der Runden-Modus wird in P6 angefasst).

## Offene Fragen (entscheidet der nächste Lauf selbst, wenn keine Antwort kommt)

1. P4: Sollen die Tracks pro **Runde** oder pro **Biom** wechseln? → Standard: pro Runde.
2. P5: Todes-Jingle 2,0 s oder länger (3,0 s, „ausklingend")? → Standard: 2,0 s.
3. P6: LEICHT-Faktor 0,65 oder 0,60? → Standard: 0,65, Messung muss P6.4 erfüllen.
4. P9: Soll die Map „ERDE" weiterhin die Reise (Wiese → Wüste → Eis → Lava) bleiben oder
   auch fest auf Wiese? → Standard: Reise bleibt, aber **nur** an Rundengrenzen (P9.2),
   alle anderen Maps fest.
5. P10: Flash-Farbe weiß oder map-farbig (Sand/Blau/Lava)? → Standard: weiß, 0,35 s;
   nach Sichturteil (P10.5) darf er ganz entfallen.
6. P11: Soll die Skin-Deko-Waffe grundsätzlich verschwinden, sobald eine echte Waffe
   ausgerüstet ist, oder nur bei Überlappung? → Standard: nur bei Überlappung (P11.3).
