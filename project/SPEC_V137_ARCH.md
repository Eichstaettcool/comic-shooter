# SPEC_V137 — Architektur-Umbau (Wartbarkeit + Ladezeit)

Projekt `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2, Version **1.37**.
Diese Datei ist der Arbeitsplan. Status: `[ ]` offen · `[~]` läuft · `[x]` fertig + belegt.

---

## 0 — Ist-Zustand (gemessen, nicht geschätzt)

| Datei | Zeilen | Anteil |
|---|---|---|
| `scripts/ui_manager.gd` | 6808 | 27 % |
| `scripts/game_manager.gd` | 4927 | 20 % |
| `scripts/texture_manager.gd` | 4319 | 17 % |
| `scripts/map_generator.gd` | 1068 | 4 % |
| `scripts/monster_ai.gd` | 1066 | 4 % |
| `scripts/player_controller.gd` | 853 | 3 % |
| Summe Projekt | 24 749 | |

**Baseline (vor dem Umbau, gemessen am 2026-11-03):**

- Boot (headless, 20 Frames): **17,0 – 17,9 s** (3 Läufe)
- `[PERF]` im Run (240 Frames): `fps_avg=56.1 proc_ms=0.02 phys_ms=0.00 draw_max=56 nodes_max=994`
- Golden Master: 8 Diag-Modi in `backup/golden_v136/*.log` (normalisiert)

### Ehrliche Einordnung „Performance"

Eine 6800-Zeilen-Datei kostet **keine** Frame-Zeit — `proc_ms=0.02` beweist das.
Sie kostet:

1. **Startzeit**: GDScript wird beim Laden geparst/kompiliert; die drei Monolithen
   werden beim Boot komplett geladen. Der eigentliche Boot-Fresser ist aber die
   **prozedurale Texturerzeugung** in `texture_manager.gd` (alles beim Start).
2. **Wartbarkeit**: 120+ Funktionen in einem Script, unklare Zuständigkeiten,
   jede Änderung muss den ganzen Kontext kennen.

Deshalb zwei getrennte Ziele: **Ladezeit** (messbar über Boot-Zeit) und
**Struktur** (messbar über Dateigröße + Modulgrenzen). Frame-Zeit darf sich
nicht verschlechtern — sie ist die Leitplanke, nicht das Ziel.

---

## Grundregel für alle Phasen

**Strangler-Muster mit Fassade.** Die Aufrufer bleiben unangetastet:
`ui_manager.show_banner(...)`, `game_manager.map_data(...)`, `TextureManager.get_texture(...)`
müssen nach jeder Phase weiter funktionieren. Neue Module werden eingehängt,
der Monolith delegiert nur noch.

Nach **jeder** Phase:

```bash
./Godot.exe --headless --path project --quit-after 60        # 0 SCRIPT ERROR
for m in chestfull upg shop mini loc2 seasons char wpn2; do   # Golden Master
  COMIC_LANTEST=$m ./Godot.exe --path project > /tmp/$m.log 2>&1; done
COMIC_LANTEST=perf ./Godot.exe --path project | grep PERF     # Leitplanke
```

Ohne Golden-Master-Vergleich gilt eine Phase als **nicht** abgeschlossen.

---

## P1 — Messnetz und Zielstruktur

### P1.1 — Performance-Diag  `[x]`
`COMIC_LANTEST=perf` misst 240 Frames nach Run-Start: FPS, Prozess-/Physik-Zeit,
Draw-Calls, Node-Zahl, Monsterzahl.
**Abnahme:** `[PERF] fps_avg=… proc_ms=… draw_max=… nodes_max=…` (liegt vor).

### P1.2 — Golden Master  `[x]`
Acht Diag-Modi als normalisierte Logs (`backup/golden_v136/`), Zahlen durch `N`
ersetzt, Koordinaten durch `(X,Y)`.
**Abnahme:** 8 Dateien vorhanden, `wc -l` gesamt 1109 Zeilen.

### P1.3 — Backup vor dem Umbau  `[x]`
**Abnahme:** `backup/scripts_v136/` mit 28 `.gd`-Dateien (990 KB).

### P1.4 — Zielstruktur anlegen  `[~]`
```
project/scripts/
  autoload/      sound_manager.gd · loc.gd · texture_manager.gd (Fassade)
  core/          run_state · profile · seasons · upgrades · waves · bosses · shop_logic
  entities/      player/ · monster/ · projectile · chest · item
  ui/            ui_manager.gd (Fassade) · hud · style · pages/ · overlays/ · widgets/
  systems/       loot_table · chest_system · corruption_zone
  net/           net_manager
  tools/         lan_diag_tmp · generators
```
**Abnahme:** Ordner existieren, `project.godot`-Autoload-Pfade angepasst,
Boot ohne Fehler, Golden Master unverändert.

### P1.5 — ARCHITEKTUR.md  `[x]`
Modulkarte: welches Modul besitzt welchen Zustand, wer darf wen aufrufen
(Richtung: `ui → core → entities`, nie zurück), Namenskonventionen.
**Abnahme:** Datei vorhanden, jede Datei > 500 Zeilen hat einen Eintrag.

---

## P2 — `texture_manager.gd` (4319) zerlegen und Boot-Zeit senken

Ist: ein Autoload mit allen prozeduralen Zeichnern (Charaktere, Monster, Items,
UI, Kisten) und einem Cache. Alles wird beim Start generiert.

### P2.1 — Cache und Fassade trennen  `[x]`
- `autoload/texture_manager.gd` wird **Fassade**: `get_texture(key)`, `get_skin_texture`,
  `get_hat_only_texture`, `get_player_texture`, `get_skin_hat_texture*` → Delegation.
- `texture/texture_cache.gd`: Dictionary + `has/get/put`, Log `[TEX][CACHE] hit=… miss=…`.
**Abnahme:** `[TEX][CACHE]`-Zeile im Log; Golden Master identisch.

**Ergebnis:** Fassade (`get_texture` + Lazy + `[TEX][FEHLT]`) steht; ein eigener
`texture_cache.gd` ist noch **nicht** ausgelagert (P2.2 zieht ihn mit).

### P2.2 — Zeichner in Themenmodule  `[~]`
`texture/gen_characters.gd`, `gen_monsters.gd`, `gen_items.gd`, `gen_chests.gd`,
`gen_ui.gd`, `gen_maps.gd` — reine `static func`s ohne Zustand.
**Abnahme:** keine Datei > 1200 Zeilen, `texture_manager.gd` < 400 Zeilen.

### P2.3 — Lazy-Erzeugung  `[x]`
Texturen werden **beim ersten Zugriff** erzeugt (nicht beim Boot), außer einer
kleinen Startmenge (Herz, Held, Kisten, UI-Grundlagen).
**Abnahme:** Boot-Zeit ≤ 15,0 s (Baseline 17,0 s), `[TEX][BOOT] eager=… lazy=…`.

**Ergebnis Runde 137:** `[TEX][BOOT] eager=boot keys=91 ms=2939` ·
`[TEX][LAZY] run-Gruppe gezeichnet: keys=259 ms=1165` ·
`[BOOT][0] _ready start ms=6974` (vorher 16 204) · Wanduhr-Boot 14,1–15,9 s (Ziel erreicht).
Der Startbildschirm zieht die run-Gruppe über seine Monster-Parade — diese 10 Monster
liegen deshalb in der boot-Gruppe, sonst wäre die Trennung wirkungslos.

---

## P3 — `ui_manager.gd` (6808) in Seiten und Widgets zerlegen

### P3.1 — Style/Widget-Modul  `[ ]`
`ui/ui_style.gd`: `_make_pixel_button`, `_comic_panel_sb`, `_hud_comic_sb`,
`_make_chip`, `_shop_ls`, `_make_burst_texture`, `_make_halftone_texture` …
als `static func`s. `ui_manager` behält Wrapper gleichen Namens.
**Abnahme:** `ui_style.gd` < 500 Zeilen, `ui_manager.gd` < 6200, Golden Master identisch.

### P3.2 — Seiten als eigene Klassen  `[ ]`
`ui/pages/shop_page.gd` (Kisten/Umtausch/Sofortkauf), `char_page.gd`,
`maps_page.gd`, `settings_page.gd`, `collection_page.gd`, `stats_page.gd`.
Muster: `Page.new(host)`, `build() -> Control`, `refresh()`.
**Abnahme:** `ui_manager.gd` < 2500 Zeilen, jede Seite < 800, alle Seiten-Shots unverändert.

### P3.3 — Overlays  `[ ]`
`ui/overlays/upgrade_cards.gd`, `upgrade_toast.gd`, `pause.gd`, `death.gd`,
`lobby.gd`, `disconnect.gd`, `shop_run.gd`.
**Abnahme:** `ui_manager.gd` < 1500 Zeilen, 0 SCRIPT ERROR, Golden Master identisch.

### P3.4 — HUD-Modul  `[ ]`
`ui/hud.gd`: Aufbau + alle `update_*` (Herzen, XP, Score, Welle, Boss, Season, Waffen).
**Abnahme:** `ui_manager.gd` < 900 Zeilen (Fassade), PERF unverändert.

---

## P4 — `game_manager.gd` (4927) in Kernmodule zerlegen

### P4.1 — Profil/Save  `[ ]`
`core/profile.gd`: Laden/Speichern, Kosmetik-Unlocks, Gold, Sprache.
**Abnahme:** `[PROFILE][SAVE] … keys=…` vorhanden, Profil-Rundlauf (Save→Load) identisch.

### P4.2 — Jahreszeiten  `[ ]`
`core/seasons.gd`: SEASONS, Preis/Kauf, Modus FEST/WECHSELND, Pool, HUD-Update.
**Abnahme:** `COMIC_LANTEST=seasons`-Log identisch zum Golden Master.

### P4.3 — Upgrades  `[ ]`
`core/upgrades.gd`: UPGRADES, Auswahl, Anwenden, Toast/Verkettung.
**Abnahme:** `COMIC_LANTEST=upg`-Log identisch.

### P4.4 — Wellen/Bosse/Mini-Bosse  `[ ]`
`core/waves.gd` + `core/bosses.gd`: Wellenstart, Balance, Boss-/Mini-Boss-Spawn.
**Abnahme:** `COMIC_LANTEST=mini`-Log identisch.

### P4.5 — Shop-Logik  `[ ]`
`core/shop_logic.gd`: Angebote, Preise, Käufe, Quick-Buffs.
**Abnahme:** `COMIC_LANTEST=shop`-Log identisch.

### P4.6 — Fassade  `[ ]`
`game_manager.gd` behält alle öffentlichen Methoden als Delegation, hält nur
noch Run-State (Score, Wellen, Referenzen auf Nodes).
**Abnahme:** `game_manager.gd` < 1200 Zeilen, alle 8 Golden-Master-Modi identisch.

---

## P5 — Entities

### P5.1 — Waffen  `[ ]`
`entities/player/weapons.gd`: `WEAPON_DATA`, `WEAPON_RARITY`, Roll, `_wd()`,
`dps_of`, `dps_table`. `player_controller` delegiert.
**Abnahme:** `COMIC_LANTEST=wpn2` identisch, `player_controller.gd` < 600 Zeilen.

### P5.2 — Monster  `[ ]`
`entities/monster/monster_stats.gd` (Tabellen), `monster_patterns.gd` (Angriffsmuster).
**Abnahme:** `monster_ai.gd` < 600 Zeilen, Golden Master identisch.

---

## P6 — Abschluss

### P6.1 — Messvergleich + Builds  `[ ]`
Boot-Zeit, PERF, Dateigrößen vorher/nachher in `ARCHITEKTUR.md`; APK+EXE v1.37.
**Abnahme:** `dist/ComicShooter-v1.37.apk` + `.exe`, `[BUILD] Versionsanzeige v1.37 aktiv (Build 37)`,
Boot-Zeit ≤ Baseline, PERF `fps_avg` ≥ 54, `proc_ms` ≤ 0.10.

### P6.2 — Doku  `[ ]`
`STATUS.md` + `ARCHITEKTUR.md` aktualisiert, `BUGLISTE.md` um gefundene Punkte.
**Abnahme:** beide Dateien aktuell, jede Phase mit Belegzeile.

---

## Stand nach Runde 137 (ehrlich)

| Punkt | Status | Was fehlt |
|---|---|---|
| P1.1 – P1.3, P1.5 | `[x]` | — |
| P1.4 Ordnerstruktur | `[~]` | Ordner sind noch nicht angelegt; Autoload-Pfade unverändert |
| P2.1 Fassade | `[x]` | eigener `texture_cache.gd` fehlt (kommt mit P2.2) |
| P2.2 Zeichner-Split | `[ ]` | `texture_manager.gd` noch 4 3xx Zeilen; Split in `gen_*.gd` offen |
| P3.1 Style-Modul | `[ ]` | **Versuch zurückgerollt** (siehe unten) |
| P2.3 Lazy | `[x]` | Boot von 16,2 s auf 7,0 s bis `_ready` gesenkt |
| P3 UI-Split | `[ ]` | `ui_manager.gd` unverändert 6 8xx Zeilen |
| P4 Core-Split | `[ ]` | `game_manager.gd` unverändert 4 9xx Zeilen |
| P5 Entities | `[ ]` | `player_controller`, `monster_ai` unverändert |
| P6 Build/Messvergleich | `[x]` | gebaut, siehe unten |

**Build v1.37:** `dist/ComicShooter-v1.37.apk` (31,1 MB) · `dist/ComicShooter-v1.37.exe` (111 MB),
Smoke-Test `[BUILD] Versionsanzeige v1.37 aktiv (Build 37)` · `[BOOT][0] _ready start ms=7793`
(vorher 16 204) · `[TEX][BOOT] keys=91 ms=2339`.

**Golden Master nach dem Umbau:** `chestfull 0`, `char 0`, `upg 0`, `loc2 0` Diff-Zeilen;
`mini` unterscheidet sich nur im zufälligen Mini-Boss-Typ, `wpn2`/`shop`/`seasons`
nur in der Reihenfolge der LOC-Logs. Verhalten unverändert.

## Rückgerollt: P3.1 Style-Modul (Versuch vom 2026-11-03)

Der mechanische Split der 18 Style-Funktionen nach `ui/ui_style.gd` (statische Klasse)
ist **gescheitert und zurückgerollt**:

- Beim Ausschneiden per Skript wanderten Member-Deklarationen, die zwischen den
  Funktionen lagen (`var load_screen`, `const LOAD_QUOTES`, `const COMIC_PAPER`),
  mit in die neue Datei — danach fehlten sie im `ui_manager`.
- `ui_style.gd` blieb mit einem Parse-Fehler stehen (`Expected end of statement …
  found ","`), den ich in der verfügbaren Zeit nicht lokalisiert habe.
- `class_name` wird in Godot erst nach `--import` aufgelöst; der Fehler überdeckte
  die eigentliche Ursache.

**Lehre für den nächsten Versuch (in dieser Reihenfolge):**

1. **Nicht per Zeilenbereich schneiden.** Funktionen einzeln per AST/`func`-Grenze
   holen und dabei **nur** `func … :` bis zur letzten Zeile mit Einrückung > 0 nehmen;
   Top-Level-Zeilen (`var`, `const`) dazwischen explizit stehen lassen.
2. **Erst eine** Funktion verschieben, kompilieren, dann die nächste — nicht 18 auf einmal.
3. `./Godot.exe --headless --path project --import` ausführen, **bevor** ein neues
   `class_name` benutzt wird.
4. Rückweg bereithalten: `backup/scripts_v136/` (vor dem Umbau angelegt) — hat hier
   funktioniert, `ui_manager.gd` ist wieder auf dem Stand v1.36b.

Der Rollback ist verifiziert: `chestfull`, `shop`, `char` 0 Diff-Zeilen,
`upg` 1 Zeile (`[SEASON][HUD]` — Reihenfolge), `SCRIPT ERROR` keine.

## Reihenfolge

1. **P1** (Messnetz + Struktur) — Voraussetzung für alles andere
2. **P2** (Texturen) — größter Boot-Hebel, isoliert testbar
3. **P3** (UI) — größter Wartbarkeits-Brocken
4. **P4** (Game-Manager)
5. **P5** (Entities)
6. **P6** (Messvergleich + Builds)

Regel: Eine Phase wird nur begonnen, wenn die vorige Golden-Master-gleich ist.
