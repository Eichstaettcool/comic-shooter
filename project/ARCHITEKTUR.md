# ARCHITEKTUR-Zusatz v1.46

Stand: v1.46. Pläne: `SPEC_V146_POLISH.md`. Der v1.45-Abschnitt darunter bleibt gültig.

## Was v1.46 zusätzlich eingeführt hat

| Baustein | Datei | Zweck |
|---|---|---|
| `SmoothScroll` | `ui/smooth_scroll.gd` (neu) | weich laufender Scrollbereich: Ziehen (Touch + Maus) mit exaktem Fingerfolgen, Nachlauf ~0,3 s, Mausrad in 120-px-Stufen, harte Klemmung. Belege `[SCROLL][BAU/ZUG/RAD/ENDE]` |
| `UiStyle.smooth_scroll()` | `ui/ui_style.gd` | Fabrik für den Helfer (Tag + Mindesthöhe) |
| `apply_origin()` | `ui/pages/settings_page.gd` | blendet `SCHWIERIGKEIT` und `BIOM-ÜBERGANG` aus, wenn die Seite aus der Pause kommt (`[SET][ORIGIN]`) |
| `eye_pixels()` / `_head_metrics().eye_*` | `texture/gen_characters.gd` | Augenband je Skin aus dem gezeichneten Bild (Läufe ab 2 px) |
| Hut-Sitz über das Augenband | dito (`_hat_layer_fast`) | Unterkante auf die Augenoberkante, Verkleinern wenn nötig, Hutpixel über dem Augenband löschen |
| `HAT_BODY_ITEMS` hinten | dito (`_make_player_rig`) | Rucksack/Schulterplatten auf eigener Ebene hinter dem Körper (`[HAT][EBENE]`) |
| `_cover_percent()` | dito | Maß „wie viel Körper überdeckt eine Ebene" (px-genau) |
| zwei Player-Sätze + Crossfade | `autoload/sound_manager.gd` | `_music_player/_music_player_b`, `_music_menu/_music_menu_b`, `active_player()`; Aus- und Einblenden treffen nie dasselbe Objekt (`[MUSIK][WECHSEL] gleicher_player=false`) |
| `boss_1` + `play_boss_music()` + Riser | dito | bedrohlicher Track (55 Hz, Tritonus, Drums 0,30, Herzschlag), 1,2 s Einstieg, 1,0 s Rückkehr |
| Loop-GUARD `_process()` | dito | `seek(0)` kurz vor dem Ende statt Engine-Loop (Emulator-SIGSEGV im AudioTrack-Thread) — `[MUSIK][LOOP] nahtlos … quelle=seek` |
| `[MUSIK][CFG]` / `[MUSIK][DUCK]` | dito | Klangbild je Track, Dämpfung mit Rückweg |
| 12 Aufgaben × 3 Stufen | `core/challenge_run.gd` | neue Ziele `kills`, `muenzen`; Regeln `kein_treffer`, Sperre `verbrauch`; `ziel_of()`, `unit_of()` |
| eine Definitionsquelle | `core/challenges.gd` | `defs()` liefert `ChallengeRun.DEFS` (vorher zwei Listen) |
| Namensfeld | `ui/pages/char_page.gd`, `game_manager.set_player_name()` | `LineEdit` (10 Zeichen, Gerätetastatur), Trimmen, leer → `HELD`, Coop-Sync |
| Diag-Modi | `tools/lan_diag_tmp.gd` | `musik146`, `hat146`, `scroll146`, `chal_run146`, `icon146`, `rig146`, `set146`, `name146` |

Zeilenzahlen v1.46: `game_manager.gd` 4 900 · `ui_manager.gd` 4 130 · `smooth_scroll.gd` 233 ·
`challenge_run.gd` 480 · `challenge_page.gd` 405 · `sound_manager.gd` 1 100 · `lan_diag_tmp.gd` 7 000
(gerundet; maßgeblich ist `wc -l`).

## Regeln, die aus v1.46 dazukommen

1. **Augen sind tabu.** Jede Kopfbedeckung wird gegen das gemessene Augenband geprüft; passt sie
   nicht darüber, wird sie verkleinert (nicht die Augen verdeckt). Messung: `COMIC_LANTEST=hat146`.
2. **Musik läuft nie im Audio-Thread neu an.** Kein `LOOP_FORWARD` auf Android (Emulator-SIGSEGV);
   Loop über `seek(0)` im Main-Thread, `finished` bleibt Sicherheitsnetz.
3. **Ein Zeichenweg pro Skin.** `_make_player()` wird für Spielertexturen nicht mehr benutzt —
   sonst weichen Hut-Sitz und Messung voneinander ab.
4. **Log-Formeln müssen den gezeichneten Wert ausgeben**, nicht eine zweite Formel (B46-2).

# ARCHITEKTUR — Comic Shooter

Stand: v1.46. Pläne: `SPEC_V146_POLISH.md`. Der v1.45-Abschnitt darunter bleibt gültig.

## Was v1.45 zusätzlich eingeführt hat

| Baustein | Datei | Zweck |
|---|---|---|
| `SFX_TARGET_DB` + `_normalize_wav()` | `autoload/sound_manager.gd` | ein Pegelbezug (dBFS RMS) für alle 27 Klänge, Peak-Limit −1 dBFS statt fester Synthese-Faktoren |
| Musikpegel aus Track-RMS | dito | `MUSIC_RMS_TARGET_DB = -20.5`, Basis je Track gemessen statt konstant |
| `gen_chests._make_chest()` | `texture/gen_chests.gd` | drei Kistenstufen gezeichnet (64²-Raster, 3-px-Kontur), je geschlossen/offen |
| `load_layout_probe()` | `ui/ui_manager.gd` | misst Kastenmitte gegen Textmitte (px) — Beleg statt Behauptung |
| `WheelMachine` | `wheel_machine.gd` | 8 Segmente, Gewichte (Summe 100), `spin()`, `odds_table()`, `simulate()` — RTP 0,92 |
| `wheel_view.gd` | `ui/wheel_view.gd` | gezeichnetes Rad (`_draw`, Tortenstücke + Nabe), kein PNG; `labels_an` für die Shop-Vorschau |
| `wheel_ui.gd` | `ui/wheel_ui.gd` | Overlay: Ergebnis zuerst, Zielwinkel, `TRANS_CUBIC`, Tick je Segmentgrenze, Buchung |
| `ChallengeRun` | `core/challenge_run.gd` | 6 Aufgaben × 3 Stufen (Runden, Diamanten, Sperren), Ereignisse `on_round_*`, `on_boss_killed`, `on_chest_opened`, Auswertung |
| START + Stufenwahl | `ui/pages/challenge_page.gd` | Aufgabe als Spielmodus startbar, Zielzahlen/Beschreibung je Stufe |
| `set_challenge_hud()` / `show_challenge_result()` | `ui/ui_manager.gd` | HUD-Zeile oben links, Ergebnis-Fenster am Run-Ende |
| Sperren im Run | `game_manager.gd`, `overlays/wave_shop.gd` | `[CHAL][SPERRE]`: Waffen-/Herz-/Schild-Pickups, Waffenkarten und Heilung im Runden-Shop |
| `signal chest_opened` | `systems/chest_system.gd` | SAMMLER zählt geöffnete Kisten (ein Signal, auch bei epischem Doppel-Loot) |
| `_icon145()` | `tools/lan_diag_tmp.gd` | sechs Entwürfe in einem SubViewport rendern (Strahlen, Rahmen, Sprites, Text) |
| Diag-Modi | dito | `snd145`, `chest145`, `load145`, `wheel145`, `chal_run145`, `icon145` |
| `norm()` erweitert | `tools/golden_check.sh` | `NxNNN → NxN` (1-px-Rundung der Kistenvorschau) |

Zeilenzahlen v1.45: `game_manager.gd` 4 863 · `ui_manager.gd` 4 098 · `wheel_machine.gd` 137 ·
`wheel_view.gd` 79 · `wheel_ui.gd` 416 · `challenge_run.gd` 309 · `challenge_page.gd` 389 ·
`shop_page.gd` 631 · `lan_diag_tmp.gd` 6 273.

## Fluss einer Aufgabe (v1.45)

```
ChallengePage START ──► game_manager.chal_start(id, stufe)
        ├─ ChallengeRun.setup()        (Runden/Diamanten/Sperren je Stufe)
        ├─ set_round_difficulty() + set_game_mode(2)
        └─ start_game() ──► RoundsMode.reset() ──► ChallengeRun.start()
                                  │                    ├─ Waffe sperren (owned_weapons = [revolver])
                                  │                    └─ LP setzen (EISERN: 1)
                                  ├─ Runde 1..N:  on_round_started() → HUD + Zeitlimit
                                  ├─ Rundenende:   on_round_cleared() → Zielprüfung
                                  ├─ Boss-Tod:     on_boss_killed()
                                  └─ Kiste offen:  on_chest_opened()
                                            │
                                            └─ Ziel erreicht ──► chal_run_finished()
                                                     ├─ Profil: ERLEDIGT + Belohnung der STUFE
                                                     └─ ui_manager.show_challenge_result()
```

---

Stand v1.39 (unverändert): Pläne `SPEC_V139_LOOKS.md`, `PLAN_V139_LOOKS.md`.

## Was v1.39 zusätzlich eingeführt hat

| Baustein | Datei | Zweck |
|---|---|---|
| `_head_metrics()` | `texture/gen_characters.gd` | misst Kopfform (Oberkante, Mitte, Breite) aus dem gezeichneten Bild |
| `_hat_layer_for()` + `HAT_SEAT` + `RIG_HAT_ADJ` | dito | Hut wird auf die gemessene Kopfform gesetzt (Sitz + Skalierung je Hut) |
| `CollectionScroll` | `ui/pages/collection_page.gd` | Sammlung scrollbar (vorher war ZURÜCK bei vollem Profil unerreichbar) |
| `ChestSkip` + `_skip()` | `ui/chest_ui.gd` | Kistenanimation überspringbar (Knopf + `ui_cancel`) |
| `_on_chest_closed()` | `ui/ui_manager.gd` | Shop-Refresh nach dem Schließen als eigener, geloggter Weg |
| `PROFILE_VERSION` 3 + IDs | `core/profile.gd` | stabile `p_rig_id`/`p_hat_id`, Migration v2 → v3 |
| Rigs 25–28 | `texture/gen_characters.gd` | SPINNENMANN, ZOMBIE, KRISTALL-GOLEM, SCHATTEN-KATZE |
| Diag-Modi | `tools/lan_diag_tmp.gd` | `hatsheet`, `rigsheet`, `iou`, `headmeas`, `hatfit`, `hatsheets`, `coll`, `coll2`, `chestskip`, `cheststrip`, `dcheck` |

Zeilenstände v1.39: `tex_draw.gd` 281 · `gen_characters.gd` 855 · `collection_page.gd` 266 ·
`chest_ui.gd` 641 · `core/profile.gd` 202 · `game_manager.gd` 4 275 · `ui_manager.gd` 3 358 ·
`tools/lan_diag_tmp.gd` 1 861.

## Messwerte vorher / nachher

| Messung | v1.36 | v1.37 | **v1.38** |
|---|---|---|---|
| Boot bis `GameManager._ready` | 16 204 ms | 6 974 ms | (Messlage s. u.) |
| Boot Wanduhr, gleiche Maschine | 18 502 / 16 753 / 17 996 ms | — | **12 351 / 12 345 / 12 635 ms** |
| `[PERF]` fps_avg (240 Frames) | 56,1 | 56,3 – 59,0 | **56,2** |
| `[PERF]` proc_ms | 0,02 | 0,02 | **0,02** |
| `[PERF]` draw_max | 56 | 72 – 87 | **72** |
| Node-Zahl | 994 | 950 | **1 022** |
| Texturen | 255 eager | 91 + 168 lazy | 91 + 168 lazy (Pixel-identisch geprüft) |
| `texture_manager.gd` | 4 352 | 4 355 | **215** |
| `ui_manager.gd` | 6 808 | 6 808 | **3 348** |
| `game_manager.gd` | 4 927 | 4 936 | **4 255** |
| `monster_ai.gd` | 1 066 | 1 066 | **766** |
| `player_controller.gd` | 853 | 853 | **787** |

Die v1.37-Bootzahl (6 974 ms) und die heutigen 12 35x ms sind **nicht vergleichbar**:
dieselbe Maschine braucht für v1.36 schon 18,0 s. Der saubere Vergleich ist die
Zeile „Boot Wanduhr, gleiche Maschine" — **−31 % gegen v1.36**. Die 292 Textur-Hashes (Block C) beweisen, dass der Umbau keine Pixel verändert hat.

**Ehrlich:** Der Split ändert `proc_ms` nicht (0,02 ms vorher wie nachher). Der
Gewinn ist Startzeit (weniger Eager-Arbeit), Übersicht (Monolithen 4 352 → 215,
6 808 → 3 348, 4 927 → 4 255 Zeilen) und die Tatsache, dass Änderungen jetzt in
einer Datei mit einer Verantwortung landen. Die Zeilenziele aus `SPEC_V138_SPLIT.md`
(< 900 / < 1 200 / < 400 für die Fassaden) sind für `ui_manager` und `game_manager`
**nicht** erreicht — die dort gelisteten Funktionen sind nur ein Teil der Dateien.

## Regel: Fassade + Module (Strangler)

Die Aufrufer bleiben unverändert. Jede öffentliche Methode, die heute existiert, muss
danach noch existieren. Neue Module werden eingehängt, der Monolith delegiert.

Erlaubte Aufrufrichtung:

```
ui/        → core/       → entities/
  Seiten        Run-State      Spieler/Monster
  HUD           Profil         Waffen
  Overlays      Seasons
                Upgrades
```

Nie zurück (`entities` ruft nie `ui`), nie quer (`ui/pages` ruft nie `core/profile`
direkt — nur über die Fassade).

## Ist-Struktur (nach Runde 138)

```
project/scripts/
  autoload/  texture_manager.gd (215) · sound_manager.gd · loc.gd
  core/      profile (132) · seasons (182) · upgrades (173) · waves (145)
             bosses (129) · shop_logic (148) · spawn_api (109)
  entities/  player/weapons.gd (112)
             monster/monster_stats.gd (113) · monster_patterns.gd (294)
                     monster_spawner.gd
             projectile.gd · item_system.gd
  texture/   tex_draw (281) · gen_characters (600) · gen_monsters (832)
             gen_world (827) · gen_items (322) · gen_chests (669) · gen_ui (511)
             gen_registry (229)
  ui/        ui_manager.gd (3 348) · hud.gd (829) · ui_style.gd (273) · chest_ui.gd
             pages/    shop (652) · char (344) · maps (297) · settings (208)
                       collection (243) · stats (187)
             overlays/ upgrade_cards · upgrade_toast · pause · death · lobby
                       disconnect · shop_run
  systems/   loot_table · chest_system · corruption_zone
  net/       net_manager.gd
  tools/     lan_diag_tmp.gd
  game_manager.gd (4 255) · monster_ai.gd (766) · map_generator.gd (1 068)
  player_controller.gd (787) · debug_panel.gd · slot_* · chest_ui-Reste
```

**Muster, das sich bewährt hat:**

1. Zustandslose Helfer → `static` in einer Klasse, Aufrufer erben davon
   (`texture/gen_*.gd extends TexDraw`). Statische Funktionen, Konstanten und
   `static var` werden vererbt und teilen den Speicher → **null** Rumpf-Änderungen.
2. Zustandsbehafteter Code → Modul mit `var host: Node`, jeder Mitglieds-Zugriff
   läuft über `host.`; die Fassade behält jede Methode als Ein-Zeiler.
3. Enums sind **nicht** über eine Instanz erreichbar → in die Module spiegeln.
4. Konstanten wandern mit, in der Fassade bleibt `const X := Modul.X` als Alias.


## Ziel-Struktur (noch offen)

```
project/scripts/
  autoload/   texture_manager.gd (Fassade) · sound_manager · loc
  core/       run_state · profile · seasons · upgrades · waves · bosses · shop_logic
  entities/   player/(core, weapons, visuals) · monster/(core, stats, patterns)
  ui/         ui_manager.gd (Fassade) · hud · style · pages/* · overlays/*
  systems/    loot_table · chest_system · corruption_zone
  net/        net_manager
  tools/      lan_diag_tmp
```

## Was schon umgebaut ist (Runde 137)

1. **Textur-Gruppen + Lazy-Erzeugung** (`texture_manager.gd`)
   - `_gen_boot()`: 91 Keys (Tiles, Held, Herzen, Waffen-Icons, UI-Icons, Kisten-PNGs,
     Walzen-Symbole, Karten-Icons, Skin-Rigs, Monster-Parade des Startbildschirms)
   - `_gen_run()`: 168 Keys (Bosse, Biom-Gegner, Welt-Deko, Dschungel-Set, Effekte)
   - `get_texture()` zieht die zweite Gruppe beim ersten fehlenden Key nach,
     `_ensure_run()` wird im `start_game` **vor** dem ersten Frame aufgerufen.
   - Debug: `[TEX][BOOT]`, `[TEX][LAZY]`, `[TEX][FEHLT]`, `[TEX][TRACE]` (mit `COMIC_TEX_DEBUG=1`).
2. **Boot-Messpunkte** (`game_manager._ready`)
   `[BOOT][0]` bis `[BOOT][3]` zeigen, welche Phase wie viel Zeit kostet.
3. **Regressionnetz**
   - `COMIC_LANTEST=perf` misst FPS, Prozess-/Physik-Zeit, Draw-Calls, Nodes.
   - Golden Master: `backup/golden_v136/*.log` (8 Diag-Modi, normalisiert).
   - Vergleich nach jedem Umbau: `diff golden/<m>.log neu/<m>.log` → nur LOC-Reihenfolge,
     Zufall (Mini-Boss-Typ) und Timing dürfen abweichen.

## v1.40 — Runden-Modus (`game_mode = 2`)

| Datei | Zeilen | Aufgabe |
|---|---|---|
| `core/rounds.gd` | ~200 | Katalog: 30 Runden als Gruppen, HP-/Tempo-Multiplikatoren, Themen-Runden, Schwierigkeitsgrade, Preis-/Münz-Formeln (`class_name Rounds`, statisch) |
| `core/rounds_mode.gd` | ~265 | Zustandsmaschine Runde → Gruppen → leer → Intermission → Shop/Weiter (`class_name RoundsMode`, `RefCounted`, alles über `host`) |
| `ui/overlays/wave_shop.gd` | ~550 | Shop mit 3 Kategorien, eigenem Kauf-Fenster je Artikel, 4 Waffen-Seltenheiten, Angebot des Tages (`class_name WaveShop`) |
| `game_manager.gd` | Fassade | `_rm()`, `start_round/next_round/open_rounds_shop/set_rounds_shop_open/revive`, Tod-Haken, `num_zones` |
| `ui/hud.gd` | +90 | `WaveShopBtn`/`WaveNextBtn` unter der Waffen-/Tränke-Leiste, Vorschau der nächsten Runde |
| `ui/ui_manager.gd` | +40 | `open_rounds_shop()`, `set_wave_icons()`, `GRAD`-Knopf im Menü |

Der alte Modus `game_mode = 1` bleibt unverändert (Golden-Master 8/8).

## Regeln für die nächsten Schritte

1. **Ein Modul pro Schritt**, niemals zwei Monolithen gleichzeitig.
2. Nach jedem Schritt: `--headless --quit-after 60` (0 SCRIPT ERROR), 8 Golden-Master-Modi,
   `COMIC_LANTEST=perf` (Leitplanke: `fps_avg` ≥ 54, `proc_ms` ≤ 0,10).
3. Neue Datei erst anlegen, wenn die Fassade delegiert — **nie** Aufrufer gleichzeitig ändern.
4. Jede Datei > 900 Zeilen braucht hier einen Eintrag mit Besitzer und Zielgröße.
5. Namen: `snake_case.gd`, eine Verantwortung pro Datei, `class_name` nur für reine
   Helfer (z. B. `UiStyle`, `TexDraw`), keine Autoloads außer den vier bestehenden.

## v1.41 — was wo dazugekommen ist

| Bereich | Datei | Änderung |
|---|---|---|
| Runden-Modus | `core/rounds.gd` | `boss_counts()` (B1-Tabelle), `plan_for()/catchup_factor()` (B5, Monotonie mit Bossen), `groups_for()` (M4: Unterstützungstypen werden aus der größten Gruppe genommen, Rundenzahl bleibt), `hp_of/type_name/points_of/ability_of` um 31–34 erweitert |
| Runden-Modus | `core/rounds_mode.gd` | Boss-Ankündigung + Spawn nach 1,2 s, HP-Drossel (B2), `planned`-Liste als Wahrheit für `alive`/`killed` (B4) |
| Spawn | `core/spawn_api.gd` | im Modus 2 gilt `Rounds.hp_mult_spawn()` statt `wave_balance()` (X-B1); `[MON][SPAWN]`-Log für 31–34 |
| Monster | `monster_ai.gd`, `entities/monster/monster_stats.gd`, `monster_patterns.gd` | Enum + Tabellen bis Index 34; Frontschild (`front_block`), Aura (`aura_radius/aura_speed`), Teilung (`split_into/split_count/split_hp`), Lebenszeit (`life_left`) |
| Texturen | `texture/gen_characters.gd` | 11 Skins (S1), 25 Hüte (S2), WIKINGER/ALIEN/SPINNENMANN/ZOMBIE neu (S3), `RIG_HAT_ADJ` je Skin |
| Texturen | `texture/gen_monsters.gd`, `texture/gen_registry.gd` | SPORENBRUT/SCHILDTRÄGER/HEROLD/SPORE + `icon_revive` |
| Texturen | `texture/gen_concepts.gd` (**neu**) | datengetriebener Zeichner für die 18 Konzept-Varianten (N3) |
| Profil | `core/profile.gd` | `PROFILE_VERSION=4`, `_resolve_ids_v4()` (IDs vor Index), `OLD_RIG_NAMES`/`OLD_HAT_NAMES` als Migrationsbrücke |
| UI | `ui/ui_manager.gd` | `row3` feste Breite + GRAD-Knopf immer sichtbar (F2), `refresh_mode_labels()` (F5) |
| UI | `ui/overlays/wave_shop.gd` | Karten mit Symbol + Preiszeile (F3), alle Texte über `Loc.fmt/t` |
| UI | `ui/pages/stats_page.gd`, `ui/overlays/stats_overlay_input.gd` (**neu**) | Statistik als gepaustes Overlay im Spiel (F4) |
| Sprache | `autoload/loc.gd` | `fmt()`, `check_tree()`, neue Einträge/Regeln für v1.40/v1.41-Flächen (F5) |

**Neue Diag-Modi:** `menu141 shop141 stats141 loc141 boss141 bossrun bossbanner bossperf
monsheet monbehave monperf skin141 migr141 mksetup concepts`.

---

## Was v1.42 (Runde 142) geändert hat

| Baustein | Datei | Zweck |
|---|---|---|
| `settings_origin` + `_close_settings_page()` | `ui/ui_manager.gd` | Einstellungen kennen ihren Aufrufer (`menu`/`pause`/`run`); die Seite liegt jetzt als Kind des UI-Managers statt unter `start_screen` (P1) |
| `WEAPON_RARITY.cooldown` + `MIN_COOLDOWN` | `entities/player/weapons.gd` | Schussfolge skaliert je Seltenheit (1.00/0.88/0.76/0.62), `rpm`, `dps_at()`, `check_rarity_table()` (P2) |
| `regen_left/_tick_regen/_show_regen_heart` | `player_controller.gd` | Heiltrank regeneriert 3 LP über 4,5 s, Warteschlange für einen zweiten Trank (P3) |
| `TRACK_CFG` + `_gen_track/_gen_beat` + Fade/Duck | `autoload/sound_manager.gd` | 7 prozedurale Tracks (2 Menü, 4 Runden, Boss), sinustabellen-basierte Synthese, 0,6 s Fade, Lautstärke-Regler, Todes-Jingle auf eigenem Player (P4/P5) |
| `DIFFICULTY.anzahl` + `spawn_groups_for()` + `monster_cap()` | `core/rounds.gd` | Monsterzahl je Schwierigkeit (0,65/1,00/1,15), Obergrenze 34 (LEICHT) (P6) |
| `flow_dir`/`depth`-Kanal + 4 Blautöne + Puls-Schaum | `shaders/water.gdshader`, `map_generator._build_water_layer()` | Wasser fließt in Flussrichtung, Tiefenwirkung, Gischt an Ufer und Steinen (P7) |
| `_make_stone_variant()` | `texture/gen_world.gd` | 5 Stein-Silhouetten mit Umriss, 5 Grautönen und Moos (P7.4), als `stone_v0..v4` registriert |
| `BIOME_PLAN_ROUNDS`/`_biome_transition()` | `game_manager.gd` | Biomwechsel nur an Rundengrenzen (1/6/11/16), Aufbau gemessen, Flash + Schalter (P9/P10) |
| `HAND_ANCHOR` + `RIG_DECO_WEAPON` | `texture/tex_draw.gd`, `autoload/texture_manager.gd` | Handanker je Skin; Skins mit Deko-Waffe bekommen im Spiel die Fassung ohne Deko (`get_skin_hat_texture(..., noweapon)`) (P11) |
| `_clamp_cosmetics()` | `core/profile.gd` | Freischalt-Listen werden beim Laden auf gültige Indizes begrenzt (P12) |
| `show_load_for_run()` / `hide_load_after_run()` / `start_game_deferred()` | `ui/ui_manager.gd`, `game_manager.gd` | Ladebild mit Modus-Vorschau (Bild + Name + Beschreibung), min. 0,8 s sichtbar (P14) |
| `biome_flash_on`, `music_volume` im Profil | `core/profile.gd` | beide Schalter überleben einen Neustart |

**Neue Diag-Modi:** `pause142 wpn142 trank142 runde142 leichtrun musik142 map142 hand142
hat142 ui142 biom142 load142` (`tools/lan_diag_tmp.gd`).
**Neues Werkzeug:** `tools/spec_mark.py` (setzt Spec-Status `[ ]` → `[x]` zeilenweise).

---

## v1.44 — Aufgaben-Seite, Shop als Automat, Kisten-Tempo, Karten-Preise

| Bereich | Datei | Zeilen | Änderung |
|---|---|---|---|
| Aufgaben | `core/challenges.gd` (**neu**) | 157 | `class_name Challenges` (`RefCounted`, `var host`): sechs Aufgaben (id/name/desc/icon/goal/unit/reward_gems), Zustände `OFFEN`/`LAEUFT`/`ERLEDIGT`/`BELOHNT`, `claim()` bucht genau einmal, `ensure()` legt fehlende Einträge an |
| Aufgaben | `ui/pages/challenge_page.gd` (**neu**) | 302 | Seite mit Banner, Diamanten-Chip, Raster 3×2, festem Fuß; `layout_info()` liefert die Messwerte für den Beleg |
| Aufgaben | `ui/ui_manager.gd` | 3 816 | Kachel `AUFGABEN` (`nav_chal`), `_challenge_p()`, `_open_challenge_page()` (loggt `[LAYOUT]`/`[TAP]` nach einem Frame), Seite in `_close_pages()` und in der Zurück-Tasten-Liste |
| Shop | `ui/ui_style.gd` | 338 | drei Bausteine: `_slot_panel_sb()` (dunkles Automaten-Panel + Goldrand), `_slot_banner()` (Goldschrift + Akzentlinie), `_slot_button()` (gold, dunkle Schrift, Versatz) |
| Shop | `ui/pages/shop_page.gd` | 581 | komplett neu aufgebaut: Kistenkarten mit **Fenster** 320×300 (Bild 270×270, 17 px Luft), Namensbalken, vier Chancen-Zeilen; Umtausch als **ein** Panel mit Streifen; Walze und Sofortkauf im Banner-Look; `_log_layout()` für R8/R3 |
| Kisten | `ui/chest_ui.gd` | 667 | `_animate()`: 20 % LINEAR + 80 % EASE_OUT (`TRANS_QUAD`), `mid_x` bei 50 % (stetiger Übergang), `[CHEST][TICK]`-Zusammenfassung in `_land()` |
| Texturen | `texture/gen_characters.gd` | 930 | drei Caches (`_rig_body_cache`, `_base_body_cache`, `_head_cache` + `_hat_layer_cache`) und `_hat_layer_fast()` (Rohdaten statt `get_pixel`); `_hat_layer_for_slow()` bleibt als Vergleichsmaß im Code |
| Texturen | `texture/gen_ui.gd` | 654 | `_make_chal_icon(kind, size)` (sechs Motive, 128 px, 3-px-Kontur), Nav-Icon `chal` |
| Karten | `core/seasons.gd` | 239 | `season_price_for(planet, sid)` = Kartenpreis/3 (ERDE 800/1 200/1 600), `price_log()`, `migrate_unlocks()` |
| Profil | `core/profile.gd` | 345 | `challenges` wird gespeichert und geladen, `season_migrate()` beim Start |
| Debug | `debug_panel.gd` | 593 | `_build_grid()` baut in Häppchen (selbstregelnd 1–24 Kacheln, Ziel 25 ms), Fortschrittszeile, `_abort_grid()`/`_clear_grid()` |
| Messnetz | `tools/lan_diag_tmp.gd` | 5 672 | neue Modi `dbg144`, `hatcmp144`, `chal144`, `shop144`, `chest144`, `karte144`, `mprobe144` |

**Golden Master:** fünf Modi neu eingefroren (`chestfull`, `shop`, `loc2`, `seasons`, `upg`), alte Fassungen
liegen als `backup/golden_v136/<modus>.log.v143`. Grund je Modus: neue Log-Zeilen der neuen Flächen
(`[SHOP][KARTE]`, `[SHOP][UMTAUSCH]`, `[CHEST][SPEED]`, `[CHEST][TICK]`), Format von `[SEASON][KAUF]`
und der Preis 6 000 → 2 000 (K1 ist eine gewollte Änderung), sowie `vorher=/nachher=` in der
`upg`-Bewegungszeile. Die Modi `char`, `mini`, `wpn2` blieben unverändert.
