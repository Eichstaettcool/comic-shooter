# 🎮 ComicShooter — 2D Top-Down Shooter (Godot 4 / Mobile)

**Stand:** 16.10.2026 · **Engine:** Godot 4.7.2-stable (Win64) · **Ziel:** Android APK
**Projektpfad:** `C:\Users\vince\Games\comic-shooter\project`

---

## 1. Spielkonzept

Top-Down 2D-Shooter im Comic-Stil. Der Spieler bewegt sich auf einer kleinen Karo-Karte,
sammelt Waffen & Heilung aus Kisten und bekämpft Monster, die ihn verfolgen.

| Feature | Beschreibung |
|---|---|
| **Spieler** | Blauer Comic-Kreis, 5 Herzen, Touch-D-Pad + Schuss-Button |
| **Welt** | 25×25 Kacheln à 32 px (800×800 px), Karo-Muster, Bäume + Steine |
| **Kisten** | 8 Stück verteilt; 3 s stehenbleiben zum Öffnen → Waffe (70 %) oder Herz (30 %) |
| **Monster** | 4 Typen, folgen dem Spieler, unterschiedliche Farben/Stats |
| **Waffen** | Pistole / Schrotflinte (3er-Streuung) / Maschinengewehr |
| **Screens** | Startscreen (Highscore) → HUD → Todes-Screen (Score + Neustart/Beenden) |
| **Highscore** | In `user://savegame.save` persistiert, auf Start- + Todes-Screen sichtbar |

### Monster-Stats

| Typ | Farbe | Speed | HP | Schaden | Punkte | Spawn-Chance |
|---|---|---|---|---|---|---|
| GREEN | grün | 60 | 3 | 1 | 10 | 40 % |
| RED | rot | 140 | 2 | 1 | 20 | 30 % |
| BLUE | blau | 90 | 4 | 1 | 30 | 20 % |
| PURPLE | lila | 70 | 6 | 2 | 50 | 10 % |

### Waffen-Stats

| Waffe | Schaden | Cooldown | Geschwindigkeit | Besonderheit |
|---|---|---|---|---|
| Pistole | 3 | 0.4 s | 300 | Standard |
| Schrotflinte | 5 | 0.8 s | 250 | 3 Projektile, ±0.15 rad Streuung |
| Maschinengewehr | 2 | 0.1 s | 350 | Dauerfeuer |

---

## 2. Architektur

### Autoload
- **TextureManager** (`texture_manager.gd`) — erzeugt ALLE Comic-Texturen zur Laufzeit
  (Kreise, Herz-Formen, Baum, Kiste, Waffen-Icons, Pfeil-Buttons) → keine externen Assets nötig.

### Scene-Graph (Main.tscn)
```
Main (Node2D, game_manager.gd)
├── YSort (y_sort_enabled)
│   ├── MonsterContainer
│   ├── ChestContainer
│   ├── ItemContainer
│   └── MapGenerator (map_generator.gd, zeichnet Karo-Boden via _draw())
├── MonsterSpawner (monster_spawner.gd)
├── Camera2D (Limits 0..800, reparented auf Player beim Start)
└── CanvasLayer
    └── UIManager (ui_manager.gd: HUD, Start-, Todes-Screen, Touch-Controls)
```

### Collision-Layer-Matrix

| Objekt | Layer | Mask | Zweck |
|---|---|---|---|
| Player | 1 | 2+8 (=10) | trifft Monster, sammelt Items |
| Monster | 2 | 1 | kollidiert mit Player |
| Projectile | 4 | 2 | trifft Monster |
| Chest/Item | 8 | 1 | von Player auslösbar |

### State-Machine (GameManager)
```
MENU (Startscreen) ──Play──▶ PLAYING ──HP≤0──▶ DEAD (Todes-Screen)
                                  ▲                     │
                                  └─── Restart ◀────────┘
```

---

## 3. Dateiübersicht (alle vorhanden ✅)

| Datei | Zeilen | Aufgabe |
|---|---|---|
| `project.godot` | 10 | Autoload TextureManager, main_scene=Main.tscn, driver=0 (GLES3) |
| `scripts/texture_manager.gd` | 225 | Runtime-Texturen (prozedurale Pixel-Zeichnung) |
| `scripts/game_manager.gd` | 213 | Zustände, Score, Spawning, Highscore-I/O, Restart/Exit |
| `scripts/player_controller.gd` | 157 | Bewegung (Touch+Keyboard), 3 Waffen, 5 Herzen |
| `scripts/projectile.gd` | 32 | Area2D-Projektil, 3 s Lifetime |
| `scripts/monster_ai.gd` | 93 | 4 Typen, Verfolgung, Schadens-Cooldown 1 s |
| `scripts/monster_spawner.gd` | 40 | Wellen, Intervall 30→10 s (−2.0/Welle), mehr Monster pro Minute |
| `scripts/chest_system.gd` | 63 | 3 s Timer, Fortschritts-Label, Item-Spawn |
| `scripts/item_system.gd` | 35 | Herz-/Waffen-Pickups |
| `scripts/map_generator.gd` | 70 | Karo-Boden, 25 Bäume + 15 Steine, Random-Positionen |
| `scripts/ui_manager.gd` | 287 | HUD (5 Herzen, Score), D-Pad, Schuss-Button, Screens |
| `scripts/create_scenes.gd` | 244 | **Tool-Skript**: generiert alle 6 .tscn-Dateien programmatisch |

### Behobene Bugs (Review abgeschlossen)
1. ✅ Monster-Typ wurde nie gesetzt → gewichteter Zufall via `_pick_random_monster_type()`
2. ✅ Death-Screen: Exit-Button lag unterm Restart-Button → y 450→510
3. ✅ `$MapGenerator` → `$YSort/MapGenerator` (falscher Node-Pfad)
4. ✅ Chest-Timer-`timeout` war nie verbunden → Kiste hätte nie geöffnet
5. ✅ project.godot: fehlerhafte `[misc]`-Sektion entfernt, `driver = 0`

---

## 4. Umsetzungs-Roadmap

### Phase 1 — Engine-Setup ✅
- [x] Godot 4.7.2 Win64 heruntergeladen (82 MB, HTTP 200) und entpackt → `Godot.exe`
- [x] Szenen-Generierung gelöst: 6 .tscn **direkt als Text geschrieben** statt per Script
      (`--script`-Modus lädt keine Autoloads; `pack()` braucht owner — beide Probleme umgangen)
- [x] project.godot: main_scene=Main.tscn, Autoload mit `*`-Präfix, Display 1920×1080 Landscape

### Phase 2 — Desktop-Test 🖥️ (läuft)
- [x] Headless-Boot ohne Script-Fehler (--quit-after 300: clean)
- [x] Godot 4.7-Fixes: `KEY_W` statt `Key.W`, `Time.get_ticks_msec()`, keine Keyword-Args,
      `ResourceSaver.save(resource, path)`, `TouchScreenButton.scale` statt `.size`
- [ ] Spiel im Fenster starten → Startscreen → Play → Bewegung/Schießen prüfen
- [ ] Kisten-Öffnen (3 s), Herz-Pickup, Waffenwechsel testen
- [ ] Todes-Screen + Highscore-Persistenz (`user://savegame.save`) testen

### Phase 3 — Mobile-Anpassung 📱
- [ ] Touch-Steuerung verifizieren (D-Pad + Schuss-Button, Multi-Touch für Diagonalen)
- [ ] Auflösung: `display/window/size` auf 1920×1080 Landscape, `canvas_items` stretch
- [ ] UI-Skalierung für verschiedene Bildschirmgrößen (Anchors statt Hardcode-1080px)
- [ ] Performance: Texturen-Atlas prüfen, ggf. `mobile` Renderer statt GLES3 testen

### Phase 4 — Android-Export 🤖
- [ ] Android Build Template installieren (Editor → Manage Export Templates)
- [ ] Android SDK/JDK konfigurieren (Godot-Editor-Settings)
- [ ] Export-Preset "Android" erstellen (Package-Name, Icon, orientierung=Landscape)
- [ ] `Godot.exe --headless --export-release "Android" ComicShooter.apk --path project`
- [ ] APK aufs Handy sideloaden und Feldtest

### Phase 5 — Polish (optional)
- [ ] Screen-Shake bei Treffern, Partikel für Monster-Tode
- [ ] Sound (Schuss, Kiste, Tod) — prozedural oder freie Assets
- [ ] Monster droppen gelegentlich Herzen

---

## 5. Risiko / Offene Punkte

| Risiko | Lösung |
|---|---|
| Godot.zip verschwand nach Download (2×) | Vordergrund-curl mit fester `C:/...`-Pfadangabe; SHA prüfen |
| `--script`-Modus scheitert an fehlendem Main.tscn | Autoload-Bootstrap-Fallback (Abschnitt 4, Phase 1) |
| TouchScreenButton `pressed/released` auf Android | Erst auf Gerät testen; ggf. auf `Button`+`InputEventScreenTouch` umstellen |
| Hardcodierte 1080px-Zentrierung im UIManager | In Phase 3 durch Anchors ersetzen |

---

## 6. Nächster konkreter Schritt
**Phase 1 abschließen:** Godot.zip verifizieren/entpacken, dann Szenen generieren und
das Spiel erstmals headless + mit Fenster starten.

---

# 🔄 Version 2 — Feedback-Runde (16.10.)

## Angenommene Fixes & Features

| # | Punkt | Status |
|---|---|---|
| V1 | **Joystick-Hitbox zu klein** → 440×440 unsichtbare Touch-Zone um 300er-Visual | ⏳ |
| V2 | **Rechter Ziel-Joystick entfernen** → Schuss-Button halten = Dauerfeuer in Blickrichtung | ⏳ |
| V3 | **Joysticks auf Start-/Todes-Screen unsichtbar** (touch_layer war CanvasLayer → ignoriert hud.hide()) | ⏳ |
| V4 | **Nochmal-Spielen nach Tod kaputt** — Root-Cause: Camera an Player reparented → mit Player gefreed → `start_game()` bricht mit Fehler ab. Fix: Camera bleibt Kind von Main, folgt per Code | ⏳ |
| V5 | **Automatisch generierte größere Map** (120×80 Tiles = 3840×2560,.seed pro Run, mehr Kisten/Bäume/Steine) | ⏳ |
| V6 | **Zufällige Upgrades aus Kisten:** Schild (fängt 2 Treffer, 12s), Max-Herz+1 (bis 7), Herzen, Waffen — gewichtet | ⏳ |

## Ideen-Katalog (Diskussion, noch NICHT umgesetzt)

1. **XP- & Levelsystem:** Monster geben XP nach Typ (grün 5 / rot 10 / blau 20 / lila 40).
   Level-Up → zufälliger Buff (Salve +1, Cooldown −10 %, Speed +8 %, Erster Treffer gratis…)
   — oder als Wahlkarte (3 Upgrades zur Auswahl, Roguelite-Stil). **Frage an Vince?**
2. **Neue Monstertypen mit Funktionen:**
   - *Werfer* (schießt aus Distanz — Ausweichen nötig)
   - *Splitter* (teilt sich beim Tod in 2 Kleine)
   - *Panzer* (langsam, 12 HP, nur Schrotflinte effektiv? / braucht viele Treffer)
   - *Boss* alle 2 Minuten (groß, eigenes Muster, riesiger Score)
3. **Sich verändernde Map:**
   - *Supply-Drops* alle 45 s: neue Kiste spawnt sichtbar mit Fallschirm/Rauch
   - *Korruptionszonen*: dunkle Flächen wandern über die Map, Monster darin werden schneller
   - *Nachtzyklus*: alle 2 Min kurzer "Dunkelheits-Ansturm" mit mehr Spawn + Vignette
4. **Feinschliff-Optionen:** App-Icon generieren, Sounds prozedural (pew/boom), Combo-Multiplikator
   für schnelle Kills, Wand-Blocking von Projectiles, Monster-Leichen die kurz sichtbar bleiben.

## Arbeitsreihenfolge
Fenix-Schritt 1: V1–V4 (Bugfixes/Controls) → bauen + Feedback ✅ erledigt (V4 von Vince bestätigt)
Fenix-Schritt 2: V5–V6 (Map & Upgrades) → gebaut ✅
Runde 3 (STIL B gewählt, umgesetzt ✅):
- XP-System: Kills geben XP (grün10/rot20/blau30/lila50/gelb15/pink12/orange60), grüner "+XP"-Popup
- Level-Up → Spiel pausiert, 3 Wahlkarten aus Pool (Schaden/Tempo/Cooldown/Max-Herz/Schild/Vampir)
- XP-Balken + LVL-Anzeige im HUD
- Neue Monster mit Funktion: GELB=Werfer (hält Abstand, schießt alle 2s, ab 60s),
  PINK=Splitter (2 grüne Minis beim Tod, ab 90s), ORANGE=Panzer (12 HP, langsam, ab 120s)
- Zeit-gesteuerte Spawn-Pool = natürlicher Schwierigkeitsanstieg
Offen für Runde 4: Boss alle 2 Min · Korruptionszonen · Nacht-Ansturm · Sounds · Icon · Combo-Multiplikator
