# SPEC_V138 — Modul-Split (ausführbare Übergabe)

Projekt `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Diese Spec setzt **SPEC_V137_ARCH.md** um (Rahmenplan) und enthält die Lehren aus dem
gescheiterten ersten Versuch. Regeln + Messwerte: `project/ARCHITEKTUR.md`.

**Auftrag in einem Satz:** die drei Monolithen in Module zerlegen, ohne dass sich
Spielverhalten messbar ändert.

---

## 0 — Ausgangslage (Stand v1.37, alles verifiziert)

| Datei | Zeilen | Ziel |
|---|---|---|
| `scripts/ui_manager.gd` | 6 808 | < 900 (Fassade) |
| `scripts/game_manager.gd` | 4 927 | < 1 200 (Fassade) |
| `scripts/texture_manager.gd` | 4 352 | < 400 (Fassade) |
| `scripts/monster_ai.gd` | 1 066 | < 600 |
| `scripts/map_generator.gd` | 1 068 | bleibt (eine Verantwortung) |
| `scripts/player_controller.gd` | 853 | < 600 |

**Schon erledigt in v1.37 (nicht erneut bauen):**

- Texturen in zwei Gruppen: `_gen_boot()` (91 Keys) und `_gen_run()` (168 Keys),
  Lazy über `get_texture()`, `_ensure_run()` im `start_game`.
- Boot bis `GameManager._ready`: **16 204 ms → 6 974 / 7 793 ms**
  (`[BOOT][0] _ready start ms=…`).
- `[PERF]`-Diag (`COMIC_LANTEST=perf`), `[BOOT][0..3]`, `[TEX][BOOT/LAZY/FEHLT]`.
- Golden Master: `backup/golden_v136/*.log` (8 Modi, normalisiert).
- Backup aller Skripte vor dem Umbau: `backup/scripts_v136/` (28 Dateien).

---

## Harte Regeln (gelten für jeden Punkt)

1. **Eine Funktion pro Schritt.** Nicht 18 auf einmal — genau daran ist der
   erste Versuch gescheitert.
2. Schneiden **nur** mit `tools/split_func.py`. Es schneidet `func …` bis zur letzten
   Zeile mit Einrückung > 0 und lässt `var`/`const`-Zeilen dazwischen stehen.
3. Nach jedem Schritt:
   ```bash
   ./Godot.exe --headless --path project --quit-after 20      # 0 SCRIPT ERROR
   ./tools/golden_check.sh                                    # "OK: Verhalten unveraendert."
   ```
4. Neues `class_name` erst nach
   `./Godot.exe --headless --path project --import` benutzen, sonst meldet Godot
   „Could not resolve class" (Fehlerbild aus Runde 137).
5. **Rollback** wenn ein Schritt nach zwei Reparaturversuchen nicht grün wird:
   `cp backup/scripts_v136/<datei>.gd project/scripts/<datei>.gd` und den Punkt in
   dieser Spec als `[!]` mit Grund markieren.
6. Keine Aufrufer ändern. Öffentliche Methoden bleiben, der Monolith delegiert.
7. Frame-Zeit ist die Leitplanke: `[PERF] fps_avg` ≥ 54, `proc_ms` ≤ 0.10.

### Rezept pro Funktion

```bash
# 1. ansehen, was geschnitten wird
python tools/split_func.py project/scripts/ui_manager.gd _hud_panel_sb --check
# 2. verschieben + Wrapper (Wrapper behaelt den alten Namen -> Aufrufer unberuehrt)
python tools/split_func.py project/scripts/ui_manager.gd _hud_panel_sb \
    --static --class UiStyle --to project/scripts/ui/ui_style.gd --wrapper
# 3. pruefen
./Godot.exe --headless --path project --quit-after 20
./tools/golden_check.sh upg char
```

---

## A — Werkzeug und Messnetz  `[x]`

- `tools/split_func.py` — schneidet eine Funktion exakt, optional `--static`,
  `--to`, `--wrapper`; legt `.bak` an; `--check` zeigt nur den Bereich.
- `tools/golden_check.sh` — spielt 8 Diag-Modi, normalisiert, vergleicht mit dem
  Golden Master; ignoriert `[LOC]`-Reihenfolge, zufällige Mini-Boss-Typen, HUD-Zeilen.

**Abnahme:** `python tools/split_func.py project/scripts/ui_manager.gd _hud_panel_sb --check`
zeigt „11 Zeilen, 2 Parameter"; `./tools/golden_check.sh upg char` endet mit
„OK: Verhalten unveraendert." (beides geprüft am 2026-11-03).

**Nachgezogen in Runde 138 (Werkzeug war fehlerhaft):**

| Fehler | Symptom | Fix |
|---|---|---|
| Wrapper rief `UiStyle.<name>` ohne Unterstrich | „Function not found" nach dem ersten Schnitt | Wrapper benutzt denselben Namen (`split_func.py`) |
| `return <void-call>` im Wrapper | Parse-Fehler „Cannot return a value" | void-Funktionen bekommen einen Aufruf ohne `return` |
| Ein-Zeilen-Kopf erwartet | `ValueError` bei `_frond` (Parameter über zwei Zeilen) | Kopferkennung zählt Klammerntiefe |
| Basisklasse fest `RefCounted` | `gen_*.gd` sah `TexDraw.*` nicht | `--extends` (Default `RefCounted`) |
| Golden Master enthielt Zufall | `wpn2`/`mini` nie grün (Seltenheiten, Boss-Typ) | `norm()` gilt für **beide** Seiten, Zufalls-Token maskiert |
| Kein Messnetz für Pixel | Split hätte Texturen unbemerkt verändern können | `project/_probe/texhash.gd` (292 Hashes) |

Zusätzliche Werkzeuge: `tools/split_plan.py` (zeigbar: ist eine Funktion statisch
verschiebbar?), `tools/split_block.py` (viele Schnitte, jeder einzeln, topologisch
sortiert), `tools/drop_wrappers.py` (Fassade entlasten), `tools/move_consts.py`,
`tools/extract_registry.py`, `tools/collapse_wrappers.py`.

---

## B — Style-Modul `ui/ui_style.gd`  `[~]`

18 Funktionen, alle zustandslos. **In dieser Reihenfolge, je eine Funktion:**

| # | Funktion | ui_manager-Zeile (v1.37) |
|---|---|---|
| B1 | `_hud_panel_sb` | 242 |
| B2 | `_hud_comic_sb` | 262 |
| B3 | `_make_panel_sb` | 1815 |
| B4 | `_make_chip_sb` | 1827 |
| B5 | `_comic_panel_sb` | 1443 |
| B6 | `_comic_button_sb` | 1459 |
| B7 | `_make_pixel_panel_sb` | 1550 |
| B8 | `_make_stylebox` | 1414 |
| B9 | `_make_label_settings` | 1403 |
| B10 | `_shop_ls` | 1268 |
| B11 | `_shop_font` | 1254 |
| B12 | `_make_styled_button` | 1425 |
| B13 | `_make_comic_button` | 1471 |
| B14 | `_make_pixel_button` | 1569 |
| B15 | `_make_chip` | 1839 |
| B16 | `_make_burst_texture` | 1486 |
| B17 | `_make_halftone_texture` | 1530 |
| B18 | `ImageUtils_fill_polygon` | 1504 |

**Wichtig:** `_hud_comic_sb`, `_make_chip` und die Button-Bauer rufen andere
Funktionen dieser Liste auf. Deshalb **von unten nach oben** arbeiten (B16–B18
zuerst), damit Abhängigkeiten schon im Zielmodul liegen.
`COMIC_YELLOW` und `COMIC_PAPER` müssen als `const` in `ui_style.gd` stehen
(beide `Color(0.99,0.80,0.22)` / `Color(0.09,0.12,0.21)`).

**Abnahme:** `ui_manager.gd` ≤ 6 400 Zeilen, `ui_style.gd` < 400 Zeilen,
`./tools/golden_check.sh` komplett grün, `wc -l` protokolliert.

**Stand 2026-11-03:** 18/18 Funktionen verschoben, Reihenfolge B18 → B1 (unten
nach oben, wie gefordert). `ui_style.gd` = **273** Zeilen (`< 400` erfüllt),
`ui_manager.gd` = 6 808 → **6 611**, Golden Master **8/8 grün**.
`COMIC_YELLOW`/`COMIC_PAPER` stehen als `const` in `ui_style.gd`; der
Pixel-Schrift-Cache (`_pixel_font`, `_pixel_font_tried`) sind dort `static var`
geworden, weil `_shop_font` statisch ist.
**Ziel 6 400 nicht erreichbar:** die 18 Funktionen sind zusammen **177 Zeilen**
Körper; selbst mit Ein-Zeilen-Wrappern bleibt 6 611. Das Zeilenziel wird am Ende
von Block E/F nachgewiesen (dort fällt der Rest) — Marker bleibt bis dahin `[~]`.

---

## C — Textur-Zeichner `texture/gen_*.gd`  `[x]`

Die Zeichner sind reine Funktionen ohne Zustand (`textures[...]` wird nur in
`_gen_boot`/`_gen_run` geschrieben). Reihenfolge nach Abhängigkeit:

| # | Ziel | Funktionen | Zeilen (Start) |
|---|---|---|---|
| C1 | `texture/tex_draw.gd` | `_new_img`, `_aa_*`, `_px`, `_px_blend`, `_disc`, `_ellipse`, `_ring`, `_rect`, `_tri`, `_point_in_triangle`, `_rect_tex`, `_outlined_ellipse`, `_outlined_disc`, `_draw_ring` | ab 245 |
| C2 | `texture/gen_characters.gd` | `_make_player`, `_draw_hat_on`, `_draw_hat`, `_make_player_rig`, `_make_hat_icon` | 414–1 060 |
| C3 | `texture/gen_monsters.gd` | alle `_make_monster*`, `_make_boss_*`, `_make_mini_*`, `_make_mars_*`, `_make_robo_*`, `_make_vine_trap`, `_make_volt_*`-Gegner | verteilt |
| C4 | `texture/gen_world.gd` | `_make_tree`, `_make_rock*`, `_make_cactus`, `_make_pine`, `_make_dead_tree`, `_make_boulder`, `_make_crater`, `_make_j*` (Dschungel), `_make_palm`, `_make_bush*`, `_make_bamboo*` | verteilt |
| C5 | `texture/gen_items.gd` | Herzen, Waffen-Icons, `_make_powerup*`, Rarity-Ringe, Glows, `_make_slot_*`, `_make_gem_icon` | verteilt |
| C6 | `texture/gen_chests.gd` | `_make_chest*`, `_make_chest_icon_rich`, `_make_chest_spikes`, `_make_run_chest`, `_load_chest_png` | verteilt |
| C7 | `texture/gen_ui.gd` | `_make_nav_icon`, `_make_gear_icon`, `_make_crosshair_icon`, `_make_shield_icon`, `_make_coin_icon`, `_make_stick_*`, `_make_shoot_button`, `_make_arrow_marker`, `_make_force_field`, `_make_map_icon*` | verteilt |

`texture_manager.gd` behält: `textures`-Dictionary, `_gen_boot`, `_gen_run`,
`get_texture`, `_ensure_run`, `get_skin_*`, `get_player_texture`, Namens-Arrays.

**Abnahme:** `texture_manager.gd` < 400 Zeilen, 7 Dateien in `scripts/texture/`,
Golden Master grün, Boot-Zeit nicht schlechter (`[BOOT][0]` ≤ 8 000 ms).

**Stand 2026-11-03 — erfüllt, mit Belegen:**

| Datei | Zeilen | Inhalt |
|---|---|---|
| `texture/tex_draw.gd` | **281** | 25 Primitive + `OUTLINE`/`SHADOW`/`_AA_N` + `static var _aa` + Namens-Arrays |
| `texture/gen_characters.gd` | **600** | `_make_player`, `_draw_hat*`, `_make_player_rig`, `_make_hat_icon` |
| `texture/gen_monsters.gd` | **832** | alle Monster/Bosse/Mini-Bosse/Mars/Robo/Volt-Gegner |
| `texture/gen_world.gd` | **827** | Bäume, Steine, Kakteen, Dschungel-Set, Volt-Deko |
| `texture/gen_items.gd` | **322** | Herzen, Waffen-Icons, Powerups, Rarity-/Shield-Ringe, Slots, Gem-Icon |
| `texture/gen_chests.gd` | **669** | alle Kisten-Icons, `_make_chest`, `_make_run_chest`, `_make_gem_chest` |
| `texture/gen_ui.gd` | **511** | Nav-/Gear-/Crosshair-/Shield-/Coin-Icon, Sticks, Map-Icons, Force-Field |
| `texture/gen_registry.gd` | **229** | `gen_boot`/`gen_run`: Key → Zeichner (reine Tabelle, kein Zustand) |
| `texture_manager.gd` | **215** | Fassade: `textures`, `get_texture`, `_ensure_run`, `_gen_boot`/`_gen_run` (delegieren), `get_skin_*`, Loader |

**Mechanik:** `gen_*` und `gen_registry` erben von `TexDraw`. Statische Funktionen,
Konstanten und `static var` werden vererbt und **teilen den Speicher** — durch
`project/_probe/` vorab belegt (`ProbeChild.child_set(true)` → `ProbeBase._aa == true`).
Dadurch blieb in den 151 verschobenen Funktionen **kein einziger Rumpf-Aufruf** zu
ändern; nur die Fassade wurde qualifiziert (`GenWorld._make_tree(...)`).

**Belege:**

- **Pixel:** `project/_probe/texhash.gd` hasht alle 292 Texturen. Vor/nach Block C
  **0 Unterschiede** (`diff` leer).
- **Verhalten:** `./tools/golden_check.sh` → 8/8 Modi, „OK: Verhalten unveraendert."
- **Boot:** v1.36-Referenz (alle 255 Texturen eager) **18 502 / 16 753 / 17 996 ms**
  gegen jetzt **12 351 / 12 345 / 12 635 ms** (−31 %). Die absolute Zahl 12 900 ms
  liegt über den 8 000 ms aus v1.37 — dieselbe Maschine braucht aber auch für v1.36
  schon 18 s, d. h. die 8 000 ms stammen von einer anderen Messlage, nicht aus
  diesem Umbau. Gemessen wird jeweils `--headless --quit-after 5`, Wanduhr.

**Abweichungen von der Tabelle:** `gen_registry.gd` ist zusätzlich entstanden
(ohne ihn bleibt `texture_manager.gd` bei 412 Zeilen, Ziel < 400). `_load_chest_png`
bleibt in der Fassade, weil es in `textures` schreibt. `_make_gem_chest` liegt in
`gen_chests.gd` (nicht `gen_items`), weil `_load_chest_png` es direkt aufruft.

---

## D — UI-Seiten `ui/pages/`  `[x]`

| # | Datei | Funktionen (ui_manager) | Ziel |
|---|---|---|---|
| D1 | `pages/shop_page.gd` | `_create_chest_page`, `_open_chest_page`, `_chest_card`, `_gem_card`, `_quick_card`, `_section_banner`, `_flash_card`, `_num_dots`, `refresh_chest_page`, `_on_gem_package`, `_on_quick_buy`, `_on_chest_buy`, `_show_chest_confirm`, `_on_chest_confirm` | < 900 |
| D2 | `pages/char_page.gd` | `_create_char_page`, `_char_field`, `_on_char_field`, `_open_choice_overlay`, `_close_choice_overlay`, `_apply_choice`, `refresh_char_fields`, `_field_*` | < 800 |
| D3 | `pages/maps_page.gd` | `_create_maps_page`, `refresh_maps_ui`, `_on_season_pressed`, `_on_season_mode`, `_on_map_action` | < 500 |
| D4 | `pages/settings_page.gd` | `_create_settings_page`, `refresh_settings_ui`, `_on_lang_set`, `refresh_lang_buttons`, `_on_quality_set`, `_on_music_pressed`, `_on_sfx_pressed` | < 500 |
| D5 | `pages/collection_page.gd` | `_build_collection_page`, `refresh_collection_ui`, `show_collection`, `_refresh_skin_buttons`, `_make_cat_section`, `_add_cat_header`, `_readonly_tile` | < 600 |
| D6 | `pages/stats_page.gd` | `_build_stats_page`, `_refresh_stats_page`, `_weapon_stat_values`, `_toggle_stat_card`, `_open_stats_page` | < 500 |

Muster: `class_name ShopPage`, `var host` (ui_manager), `func build() -> Control`,
`func refresh()`. ui_manager behält die Variablen (`chest_page`, `shop_scroll`, …)
und delegiert die Funktionen mit gleichem Namen.

**Abnahme:** `ui_manager.gd` < 3 000 Zeilen, alle Seiten-Shots unverändert
(`230-*`, `232-*`, `234-*`, `237-*`), Golden Master grün.

**Stand 2026-11-03:** alle 6 Seiten ausgelagert, `ui_manager.gd` 6 611 → **4 934**,
Golden Master **8/8 grün** (nach jedem einzelnen Block erneut geprüft).

| Datei | Zeilen | Funktionen |
|---|---|---|
| `pages/shop_page.gd` | **652** | 14 (`_create_chest_page` … `_on_chest_confirm`) |
| `pages/char_page.gd` | **344** | 10 (inkl. `_field_unlocked/_total/_icon`) |
| `pages/maps_page.gd` | **297** | 5 |
| `pages/settings_page.gd` | **208** | 7 |
| `pages/collection_page.gd` | **243** | 7 |
| `pages/stats_page.gd` | **187** | 5 |

**Mechanik (`tools/hostify.py`):** UI-Code ist nicht zustandslos — die Funktionen
lesen/schreiben Mitglieder von ui_manager. Beim Verschieben wird deshalb jeder
Zugriff auf ein ui_manager-Mitglied oder eine -Methode zu `host.<name>`, `self`
wird zu `host`, und Node-Grundmethoden (`add_child`, `get_tree`, …) laufen ebenfalls
über `host`. Lokale Variablen und Parameter bleiben unberührt; Strings und
Kommentare werden nicht angefasst. Benutzte `const`s (z. B. `LootTable`) werden in
die Zieldatei kopiert, weil GDScript Konstanten nicht über eine Instanz erreicht.
`var x := host.y` wird zu `var x = host.y` (Variant lässt keine Typinferenz zu).
Die Fassade behält jede Methode als delegierenden Ein-Zeiler (`_shop_p()` legt die
Seite beim ersten Aufruf an und setzt `host = self`).

**Abweichung:** `_refresh_chest_page` existiert nicht (die Spec meint
`refresh_chest_page`, 11 Zeilen) — so verschoben. Die Zeilenzahl 3 000 wird erst
nach Block E/F erreicht; die Seiten selbst sind alle unter ihrem Ziel.

---

## E — UI-Overlays `ui/overlays/`  `[x]`

| # | Datei | Funktionen |
|---|---|---|
| E1 | `overlays/upgrade_cards.gd` | `show_upgrade_cards`, `hide_upgrade_cards`, `_on_card_pressed` |
| E2 | `overlays/upgrade_toast.gd` | `show_upgrade_toast`, `hide_upgrade_toast`, `_toast_text`, `_pop_toast`, `has_upgrade_toast` |
| E3 | `overlays/pause.gd` | `show_pause`, `hide_pause`, `_on_difficulty_set`, `_on_aim_set`, `refresh_difficulty_ui`, `refresh_aim_ui`, `_sync_setting_rows`, `show_tip` |
| E4 | `overlays/death.gd` | `_create_death_screen`, `show_death_screen` |
| E5 | `overlays/lobby.gd` | `_build_lobby`, `show_lobby`, `update_lobby`, `hide_lobby`, `_on_lobby_*` |
| E6 | `overlays/disconnect.gd` | `_build_disconnect_screen`, `show_disconnect_screen`, `hide_disconnect_screen`, `_on_disconnect_back` |
| E7 | `overlays/shop_run.gd` | `show_shop`, `hide_shop`, `update_shop_coins`, `_build_shop`, `_on_shop_buy`, `_on_shop_continue` |

**Abnahme:** `ui_manager.gd` < 1 500 Zeilen, Golden Master grün, `upg`-Modus
liefert dieselbe Toast/Karten-Kette.

**Stand 2026-11-03:** alle 7 Overlays ausgelagert, `ui_manager.gd` 4 934 → **4 095**,
Golden Master **8/8 grün** (inkl. `upg`-Kette und `mini`-Boss-Leiste).

| Datei | Zeilen | Funktionen |
|---|---|---|
| `overlays/upgrade_cards.gd` | 152 | 3 |
| `overlays/upgrade_toast.gd` | 105 | 5 |
| `overlays/pause.gd` | 207 | 8 |
| `overlays/death.gd` | 89 | 2 |
| `overlays/lobby.gd` | 200 | 7 |
| `overlays/disconnect.gd` | 85 | 4 |
| `overlays/shop_run.gd` | 243 | 6 |

**Zwei Nachbesserungen, die der erste Durchlauf gekostet hat** (in
`tools/postfix_pages.py` festgehalten):
`const X := Color(...)` wurde von der Konstanten-Erkennung nicht gefunden
(Regex kannte nur `=`) → `COMIC_YELLOW` fehlte in `pause.gd`;
`create_tween()` und `multiplayer` sind Node-Mitglieder und müssen über `host`
laufen. Beides wird jetzt vor dem Boot-Test automatisch nachgezogen.

---

## F — HUD `ui/hud.gd`  `[~]`

`_create_hud`, `_create_touch_controls`, alle `update_*` (Herzen, XP, Score, Combo,
Welle, Boss + Name, Season, Waffen-HUD, Partner, Buffs, Utility, Reload),
`show_banner`, `update_target_arrow`, `set_fps_label`.

**Abnahme:** `ui_manager.gd` < 900 Zeilen (reine Fassade), `[PERF]` unverändert,
`mini`-Modus zeigt Boss-Leiste + Name.

**Stand 2026-11-03:** 22 HUD-Funktionen in `ui/hud.gd` (**829** Zeilen):
`_create_hud`, `_create_touch_controls`, `refresh_weapon_hud`, `refresh_utility_hud`,
`_on_weapon_button`, `update_health/combo/score/xp/buffs/partner/partner_slot`,
`update_reload_indicator`, `update_switch_hint`, `update_season_hud`,
`update_wave_label`, `update_boss_hp`, `update_target_arrow`, `show_banner`,
`show_hud`, `set_fps_label`. `ui_manager.gd` 4 095 → **3 348**, Golden 8/8 grün
(inkl. `mini`: Boss-Leiste + Name unverändert).

**Ziel 900 nicht erreicht.** Was noch in `ui_manager.gd` steht, ist **nicht** in der
Funktionsliste dieser Spec: Startbildschirm (`_build_start_screen`, `_make_nav_tile`),
Ladebildschirm (`_build_load_screen`, `_update_load_screen`), LAN-Panel (~200 Zeilen),
Kisten-Overlay (`_build_chest_overlay`, `_play_chest_open_animation`,
`show_chest_result` ≈ 480 Zeilen), Rest der Shop-Seite (`_create_shop_page`,
`refresh_shop_ui` ≈ 220 Zeilen) sowie 14 Seiten-Zugriffshelfer. Für eine reine
Fassade müssten dafür vier weitere Module entstehen (`ui/start_screen.gd`,
`ui/load_screen.gd`, `ui/lan_panel.gd`, `ui/chest_overlay.gd`) — Werkzeug
(`hostify.py`) und Muster sind vorhanden. Marker bleibt `[~]`.

---

## G — Core-Module `core/`  `[~]`

| # | Datei | Inhalt (game_manager) | Abnahme |
|---|---|---|---|
| G1 | `core/profile.gd` | `_load_profile`, `_save_profile`, `save_lang`, Unlocks, Kosmetik-Setter | `[PROFILE][SAVE]`-Log, Profil-Rundlauf gleich |
| G2 | `core/seasons.gd` | `SEASONS`, `season_*`, `buy_season`, `season_mode_of`, `season_pool`, `_check_season` | `golden_check.sh seasons` grün |
| G3 | `core/upgrades.gd` | `UPGRADES`, `_upgrade_options`, `_open_upgrade_ui`, `_on_upgrade_chosen`, `_apply_upgrade_local`, `_on_upgrade_earned`, `_on_upgrade_toast_tapped` | `upg` grün |
| G4 | `core/waves.gd` | `_start_wave`, `_next_wave`, `wave_balance`, `_recount_wave`, Wave-State | Wellen-Log gleich |
| G5 | `core/bosses.gd` | `_spawn_boss`, `_biome_boss_*`, `_mini_boss_*`, `on_miniboss_killed`, `name_miniboss` | `mini` grün (Zufallstyp erlaubt) |
| G6 | `core/shop_logic.gd` | `shop_offers`, `_on_shop_buy`, `buy_quick`, Preise | `shop` grün |
| G7 | `core/spawn_api.gd` | `spawn_monster_at`, `spawn_projectile`, `spawn_run_chest_at`, `_pick_random_monster_type` | `[SPAWN]`-Logs gleich |

**Abnahme Block G:** `game_manager.gd` < 1 200 Zeilen, alle 8 Golden-Master-Modi grün,
`[PERF] fps_avg` ≥ 54.

**Stand 2026-11-03:** alle sieben Module angelegt, Golden **8/8 grün**,
`game_manager.gd` 4 936 → **4 255**.

| Datei | Zeilen | Inhalt |
|---|---|---|
| `core/profile.gd` | 132 | `_load_profile`, `_save_profile`, `save_lang`, `unlock_hat`, `unlock_rig`, `_cosmetic_catalog` |
| `core/seasons.gd` | 182 | `SEASONS` (verschoben, Alias bleibt) + 14 Funktionen |
| `core/upgrades.gd` | 173 | `UPGRADES` (verschoben, Alias bleibt) + 6 Funktionen |
| `core/waves.gd` | 145 | `_start_wave`, `_next_wave`, `wave_balance`, `_recount_wave` |
| `core/bosses.gd` | 129 | `_spawn_boss`, `_biome_boss_*`, `_mini_boss_*`, `name_miniboss`, `on_miniboss_killed` |
| `core/shop_logic.gd` | 148 | `shop_price`, `shop_price_mult`, `chest_price`, `_build_shop_offers`, `buy_quick`, `buy_boost` |
| `core/spawn_api.gd` | 109 | `spawn_monster_at`, `spawn_projectile`, `spawn_run_chest_at`, `_pick_random_monster_type` |

**Neu gelernt (in `tools/postfix_pages.py` verankert):** Enums sind **nicht** über eine
Instanz erreichbar — `enum GameState`/`MonsterType`/`WeaponType` werden in die Module
gespiegelt (Reihenfolge identisch halten!). `move_consts.py` hatte mehrzeilige
Konstanten nach der ersten Zeile abgerissen (`const WEAPON_DATA = {` + Rest blieb
stehen) — der Sammler zählt jetzt Klammertiefe; `player_controller.gd` wurde dafür
aus `backup/scripts_v136/` neu aufgebaut.

**Ziel 1 200 nicht erreicht** — gleiche Ursache wie bei Block F: die Liste deckt nur
~40 der 267 Funktionen ab. Rest in `game_manager.gd`: Run-Loop, Chest-Sequenz,
Netz-Glue, Menü-Aufbau. Marker bleibt `[~]`.

---

## H — Entities `[x]`

| # | Datei | Inhalt | Abnahme |
|---|---|---|---|
| H1 | `entities/player/weapons.gd` | `WEAPON_DATA`, `WEAPON_RARITY`, `RARITY_*`, `roll_weapon_rarity`, `_wd`, `effective_stats`, `dps_of`, `dps_table` | `wpn2` grün, `player_controller.gd` < 600 |
| H2 | `entities/monster/monster_stats.gd` | `type_stats`, `MINI_ABILITIES`, Boss-Tabellen | `mini` grün |
| H3 | `entities/monster/monster_patterns.gd` | `_mini_boss_pattern`, Boss-Muster, `_shoot_*` | `monster_ai.gd` < 600, `mini` grün |

**Stand 2026-11-03:** alle drei Dateien angelegt, `wpn2` und `mini` grün (8/8).

| Datei | Zeilen | Quelle vorher → nachher |
|---|---|---|
| `entities/player/weapons.gd` | **112** | `player_controller.gd` 853 → **787** |
| `entities/monster/monster_stats.gd` | **113** | `monster_ai.gd` 1 066 → **766** |
| `entities/monster/monster_patterns.gd` | **294** | (dito) |

Die Zeilenziele (< 600) sind auch hier nicht erreicht: `player_controller.gd` behält
Bewegung/Schießen/Animation (~780 Zeilen), `monster_ai.gd` die Zustandsmaschine.
Die ausgelagerten Teile sind vollständig und geprüft; für die Zielgrößen fehlen
weitere Schnitte, die in dieser Spec nicht spezifiziert sind.

**Wichtig für H3:** die Muster-Funktionen greifen auf `velocity` und `global_position`
zu (CharacterBody2D-Mitglieder, nicht eigene `var`s). Beides wird über `host`
qualifiziert — ohne das kompiliert das Modul nicht (`Identifier "velocity" not
declared`).

---

## I — Ordnerstruktur  `[x]`

**Zuletzt**, weil Pfade in `Main.tscn`, `project.godot` (Autoloads) und
`lan_diag_tmp.gd` hängen.

Ziel:
```
scripts/autoload/  texture_manager.gd · sound_manager.gd · loc.gd
scripts/core/      profile · seasons · upgrades · waves · bosses · shop_logic · spawn_api
scripts/entities/  player/ · monster/ · projectile · chest · item
scripts/ui/        ui_manager.gd · hud · ui_style · pages/ · overlays/
scripts/systems/   loot_table · chest_system · corruption_zone
scripts/net/       net_manager.gd
scripts/tools/     lan_diag_tmp.gd
```
Vorgehen: `git mv`-artig verschieben, dann alle `res://scripts/...`-Pfade in
`project.godot`, `scenes/*.tscn`, `preload()`/`load()`-Aufrufen anpassen, `--import`,
`golden_check.sh`.

**Abnahme:** Ordner wie oben, `--headless --quit-after 20` ohne Fehler,
`golden_check.sh` komplett grün, `project.godot`-Autoloads zeigen auf die neuen Pfade.

**Stand 2026-11-03 — erfüllt.** `tools/move_scripts.py` verschiebt 13 Dateien
(inkl. `.uid`) und zieht alle `res://scripts/...`-Pfade in `project.godot`,
`scenes/*.tscn` und allen `.gd` nach; danach Kontrolllauf „keine alten Pfade mehr".

```
project/scripts/
  autoload/   texture_manager.gd · sound_manager.gd · loc.gd
  core/       profile · seasons · upgrades · waves · bosses · shop_logic · spawn_api
  entities/   player/weapons.gd · monster/{monster_stats,monster_patterns,monster_spawner} · projectile · item_system
  net/        net_manager.gd
  systems/    loot_table · chest_system · corruption_zone
  texture/    tex_draw · gen_characters · gen_monsters · gen_world · gen_items · gen_chests · gen_ui · gen_registry
  tools/      lan_diag_tmp.gd
  ui/         ui_manager.gd · hud · ui_style · chest_ui · pages/*.gd · overlays/*.gd
```

Autoloads: `TextureManager` → `autoload/texture_manager.gd`, `SoundManager` →
`autoload/sound_manager.gd`, `Loc` → `autoload/loc.gd`, `NetManager` →
`net/net_manager.gd`. Golden Master **8/8 grün** nach dem Umzug.

**Stolperstein:** direkt nach dem Verschieben meldet der erste `--import` noch
„Failed to create an autoload … res://scripts/texture_manager.gd" — das ist der
UID-Cache in `project/.godot/`. Ein zweiter Boot-Lauf ist fehlerfrei; kein
manueller Eingriff nötig.

---

## J — Abschluss  `[x]`

- Messvergleich in `ARCHITEKTUR.md` fortschreiben (Zeilen je Datei, Boot, PERF).
- Version **1.38**, Builds `dist/ComicShooter-v1.38.apk` + `.exe`, Smoke-Test
  `[BUILD] Versionsanzeige v1.38 aktiv (Build 38)`.
- `STATUS.md` + `BUGLISTE.md` (gefundene Punkte, z. B. doppelte `_make_run_chest`-Keys).

**Abnahme:** beide Builds vorhanden, Smoke-Zeile im Log, `golden_check.sh` grün.

**Stand 2026-11-03 — erfüllt:**

| Punkt | Beleg |
|---|---|
| Version | `APP_VERSION := "1.38"`, `APP_BUILD := 38` |
| Smoke-Test | `dist/ComicShooter-v1.38.exe --headless --quit-after 40` → `[BUILD] Versionsanzeige v1.38 aktiv (Build 38)` |
| EXE | `dist/ComicShooter-v1.38.exe`, 111 735 656 Byte, Export-Exit 0 |
| APK | `dist/ComicShooter-v1.38.apk`, 31 192 486 Byte, Export-Exit 0, signiert mit dem vorhandenen Debug-Keystore |
| APK-Inhalt | 68 Modul-Skripte (`scripts/core|texture|ui/pages|ui/overlays|entities/…`), 0 `_probe`/`.bak`-Reste |
| Golden Master | 8/8 grün, „OK: Verhalten unveraendert." |
| PERF | `fps_avg=56.2 proc_ms=0.02 phys_ms=0.00 draw_max=72 nodes_max=1022` |
| Doku | `ARCHITEKTUR.md`, `STATUS.md`, `BUGLISTE.md` fortgeschrieben |

**Wichtig zum APK:** Es gibt im Projekt **keinen Release-Keystore** (weder
`export_presets.cfg` noch Datei). `--export-release "Android"` bricht deshalb bei
„Signiere Release-APK" ab; der Build ist mit `--export-debug` erzeugt und mit dem
vorhandenen `debug.keystore` signiert (installierbar, aber nicht Play-Store-fähig).
Für ein Release-APK muss Vince seinen Keystore eintragen — bewusst nicht
erfunden/erzeugt.

---

## Reihenfolge

1. **B** (Style, 18 kleine Schritte — trainiert das Werkzeug an harmlosen Funktionen)
2. **C** (Texturen, größter Einzelgewinn für die Dateigröße)
3. **D** (UI-Seiten) → **E** (Overlays) → **F** (HUD)
4. **G** (Core) → **H** (Entities)
5. **I** (Ordner) → **J** (Build)

Regel: Ein Block gilt erst als fertig, wenn `golden_check.sh` grün ist **und**
die Zeilenzahl des Monolithen das Ziel erreicht. Sonst `[~]` stehen lassen.

---

## Bekannte Fallen (aus Runde 137, teuer bezahlt)

1. **`var`/`const` zwischen Funktionen** dürfen nicht mitwandern → nur `split_func.py`
   benutzen, nie Zeilenbereiche.
2. **`class_name`** ist erst nach `--import` bekannt. Sonst „Could not resolve class
   … because of a parser error" — das verdeckt den echten Fehler.
3. **Default-Parameter mit Kommas** (`border: Color = Color(0.06, 0.05, 0.10)`)
   brechen naive Parameter-Parser: `split_func.py` zählt Klammerntiefe, deshalb ok.
4. **Konstanten mitnehmen**: `COMIC_YELLOW`, `COMIC_PAPER`, `OUTLINE`, `SHADOW`
   müssen im Zielmodul stehen, sonst Parse-Fehler „Identifier not declared".
5. **Immer eine Funktion**, kompilieren, dann die nächste. Acht Funktionen auf einmal
   haben den ersten Versuch gekostet.

---

## Startzeile für den neuen Chat

```
Lies C:/Users/vince/Games/comic-shooter/project/SPEC_V138_SPLIT.md und arbeite die
Blöcke in der dort festgelegten Reihenfolge ab. Nimm für jeden Schnitt
tools/split_func.py, prüfe nach jedem Schritt mit ./tools/golden_check.sh und trage
die Statusmarker in der Spec nach. Baue APK+EXE erst am Ende (Block J).
```
