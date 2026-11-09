# Comic Shooter

2D-Arena-Shooter im Comic-Look (Godot 4.7.2, GDScript) — Mobile-first, mit Touch-Steuerung,
drei Spielmodi, Meta-Progression (Kisten, Skins, Hüte, Karten) und LAN-Co-op.

**Aktuelle Version:** 1.58 · **Projektordner:** `project/`

---

## Spielmodi

| # | Modus | Kern |
|---|---|---|
| 0 | **ENDLOS** | Wellen ohne Ende, Level-Ups, Sägezahn-Spawn mit Erholungsfenstern |
| 1 | **WELLEN + SHOP** | feste Wellen, Shop zwischen den Wellen, Boss alle 5 Wellen |
| 2 | **RUNDEN** | 30 Runden, Gruppen-Spawns, Runden-Shop, Mini-/Biom-Bosse |

Vier Schwierigkeitsstufen (LEICHT / NORMAL / SCHWER / HARDCORE) mit **strukturell**
unterschiedlichem Aufbau — nicht nur Multiplikatoren: Phasenlängen, Hetzer-Limit,
Schonfrist, Boss-Kadenz und Druckkurve sind je Stufe eigene Werte.

## Balancing

Alle Modi ziehen ihre Zahlen aus **einer** Datei: `project/scripts/core/balance.gd`.

```
druck()           HP/s der ankommenden Gegner / Referenz-DPS
ziel_druck()      Soll-Kurve über die Zeit (je Modus × Stufe)
spieler_dps()     Referenz-DPS der Startwaffe (Pistole: 3 Schaden / 0,4 s)
fehler_budget()   erlaubte Treffer in 60 s je Stufe
```

`waves.gd`, `rounds.gd` und `game_manager.DIFFICULTY` sind nur noch Adapter darauf.
Messbericht: `project/BALANCE_BERICHT.md`, Konzept: `project/SPEC_BALANCE_V156.md`.

## Starten

```bash
# Godot 4.7.2 (Windows-Binary liegt nicht im Repo)
Godot.exe --path project

# Direkt in einen Modus springen (Diagnose-Modi, s. u.)
COMIC_LANTEST=balmodel Godot.exe --headless --path project
```

## Diagnose- und Messmodi

Aktiv über die Umgebungsvariable `COMIC_LANTEST` (Gerüst: `project/scripts/tools/lan_diag_tmp.gd`).
Jeder Modus schreibt Belegzeilen ins Log und beendet sich selbst.

| Modus | Zweck |
|---|---|
| `balmodel` | Balance-Modell 3 Modi × 4 Stufen (`[BAL][MODELL]`) |
| `balbot` | Kiting-Bot spielt echte Läufe, Profile Anfänger/Erfahren (`[BOT][LAUF]`) |
| `balshot` | Belegbilder (Anlauf, Peak, Boss-Telegraph, Erholung) — schreibt nach `screenshots/` (lokal, nicht im Repo) |
| `chesttouch` / `chesttouch2` | Kistenkauf + Öffnung über den **echten** Touch-Pfad |
| `chestfull`, `chestseq`, `chest145` | Kisten-Inszenierung, Sequenz, Grafik |
| `rounds`, `roundrun`, `roundecon` | Runden-Plan, Durchlauf, Ökonomie |
| `shop`, `shop141`, `rundenshop151` | Shop-Seiten, Kaufpfade |
| `hatfit`, `hatmatrix`, `hatsheet154` | Hüte: Sitz, Matrix, Kontaktblätter |
| `mini`, `boss141`, `bossrun` | Boss-/Mini-Boss-Spawn und -Kampf |

Beispiel für einen Messlauf:

```bash
COMIC_LANTEST=balbot COMIC_BAL_MODE=endlos COMIC_BAL_STUFE=normal \
  COMIC_BAL_PROFIL=anfaenger COMIC_BAL_LAEUFE=2 COMIC_BAL_TS=4 COMIC_BAL_MAX=11 \
  Godot.exe --headless --path project
```

`tools/bal_matrix.sh` fährt die komplette Matrix, `tools/bal_auswertung.py --write`
schreibt die Tabelle in den Balance-Bericht.

## Regressionstest

```bash
./tools/golden_check.sh          # 8 Diag-Modi gegen backup/golden_v136/
./tools/golden_check.sh shop upg # nur einzelne Modi
```

Vergleicht normalisierte Logs. Referenzen werden nur mit Begründung neu gesetzt
(siehe `project/BUGLISTE.md`).

## Aufbau

```
project/
  project.godot           Godot-Projekt
  scripts/
    core/                 balance.gd, waves.gd, rounds.gd, spawn_api.gd, shop_logic.gd …
    entities/             Spieler, Monster, Waffen
    ui/                   HUD, Seiten, Overlays (Shop, Kisten, Rad)
    tools/lan_diag_tmp.gd Diagnose-/Messgerüst (alle COMIC_LANTEST-Modi)
  assets/                 Grafiken (PNG, im Code generiert oder gezeichnet)
  scenes/, shaders/
  docs/, research/
tools/                    Build-, Mess- und Split-Werkzeuge (Python/Bash)
.github/workflows/ios.yml iOS-Build auf macOS-Runner (unsignierte IPA)
```

## Was nicht im Repo liegt

Bewusst ausgeschlossen (siehe `.gitignore`), weil es sich reproduzieren lässt:

- Godot-Binary und Export-Templates
- Builds: `dist/`, `*.apk`, `*.exe`, `*.pck`
- iOS-Exporte: `ios_v*/`, `*.xcframework/`, `*.xcodeproj/`
- Messlogs (`logs_*.log`), Screenshots (`screenshots/`), übrige `backup/`-Stände
- Keystores, `.env`-Dateien

## Lizenz

Noch keine Lizenz gesetzt. Ohne Lizenz gilt automatisch „alle Rechte vorbehalten" —
vor einer Veröffentlichung hier eine Lizenz (z. B. MIT) eintragen.
