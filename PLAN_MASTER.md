# ComicShooter — MASTER-PLAN (konsolidiert, Stand 18.10.)
**Engine:** Godot 4.7.2 (headless-Build läuft) · **Ziel:** Android-APK, Landscape 1920×1080
**Projekt:** `C:\Users\vince\Games\comic-shooter\project` · **APK:** `ComicShooter.apk` (~29 MB, debug-signiert)

---

## 1. Spiel-Konzept (Kernanforderungen aus dem Chat) ✅ = umgesetzt

| Anforderung | Status | Umsetzung |
|---|---|---|
| 2D Top-Down, Charakter von oben | ✅ | Comic-Held mit Gewehr, rotiert zur Schussrichtung |
| Button-Steuerung | ✅ | Touch-Joystick (links, 440px Hitbox) + Feuer-Button (halten = Dauerfeuer) |
| Verschiedene Monster, die folgen | ✅ | 7 Typen + Boss: Grün/Blau/Lila/Rot + Werfer (schießt), Splitter (teilt sich), Panzer (12 HP) — jagen den nächsten Helden |
| Schusswaffen auf der Map | ✅ | 3 Waffen (Pistole/Schrot/MG) aus Kisten |
| Karo-Karte Comic-Stil, Bäume/Steine | ✅ | 120×80 Tiles auto-generiert pro Run, Details (Gras/Blumen), Hindernisse mit Kollision, Grenzwände |
| Kisten: 3s draufstehen → Loot | ✅ | Timer + Fortschritts-Label; Loot: Waffe 40% / Herz 28% / Schild 18% / Max-Herz 14% |
| 5 Herzen, 1 Treffer = 1 Herz | ✅ | + Schild-System, + Regeneration (12s ohne Treffer = +1 Herz) |
| Comic-Stil alles | ✅ | 100% prozedurale Pixel-Texturen zur Laufzeit, keine Asset-Dateien (Ausnahme: App-Icon icon.png) |
| Startbildschirm | ✅ | animiertes Logo, Helden-/Monster-Parade, Buttons SPIELEN / 2 SPIELER / Best Score |
| Todesbildschirm + Score | ✅ | Score + Best, NOCHMAL / BEENDEN |
| Score-Anzeige In-Game + Highscore | ✅ | Highscore in `user://savegame.save`; XP-Balken + LVL; Combo-Multi bis ×5 |
| Mobile App | ✅ | APK-Build automatisiert; Touch-UI; 16:9 expand-stretch |
| XP & Level-Up Wahlkarten (Stil B) | ✅ | 3 Karten zur Wahl, Spiel pausiert |
| Boss alle 2 Min | ✅ | Krone, Fächerschuss, HP-Balken, 300 Punkte |
| Korruptionszonen | ✅ | 3 driftende Felder: Spieler −30%, Monster +35% Tempo |
| Lokaler Multiplayer 1 Gerät | ✅ | Duo-Tastatur (WASD/Pfeile) + zweites Joystick-Paar |

## 2. Architektur (kurz)
- **Autoloads:** `TextureManager` (alle Sprites), `SoundManager` (11 prozedurale WAV-Sounds), geplanter `NetManager` (LAN)
- **Scenes:** handgeschriebene .tscn (Player/Monster/Projectile/Chest/Item/Main)
- **Scripts:** game_manager (State-Machine MENU/PLAYING/DEAD, Spawns, XP/Combo, Boss-Timer), player_controller, monster_ai, chest_system, item_system, map_generator (hash-deterministische Deko), ui_manager (HUD/Screens/Cards/Joysticks), touch_joystick, corruption_zone
- **Collision-Layer:** 1=P1, 2=Monster, 4=Projektil, 8=Loot, 16=Hindernis, 32=Gegner-Kugel

## 3. ⏳ OFFENE PUNKTE (Reihenfolge fixiert)

### A — ERLEDIGT ✅
1. **Solo-Layout-Korrektur** ✅ Joystick links, Schuss-Button rechts unten; Duo = 2 Paare
2. **LAN-Multiplayer über WLAN** ✅ (verifiziert im Zwei-Instanzen-Test)
   - `ENetMultiplayerPeer` Server/Client auf Port 7777 ✔
   - Discovery: Beacon (0.6s) an 255.255.255.255 + alle Interface-Broadcasts →
     `PacketPeerUDP.bind(7778)` Hostliste + manuelle IP als Fallback ✔
   - Auswahl-Fenster: LAN SPIEL → [HOSTEN] [NEU SCANNEN] Liste [BEITRETEN] ✔
   - Phase-1-Sync: eigene Welt pro Gerät, Partner als durchscheinender Held,
     **Leben + Waffe des Partners blass oben rechts** (Alpha 0.62), Pos/HP/Waffe
     ~15 Hz RPC, Client startet automatisch per `begin_run.rpc()` ✔
   - Test-Evidenz: Client `status=2 peers=[1]`, Host empfängt hp=5/5/pistol/pos ✔

### B — GAMEPLAY-AGENDA: ALLES ERLEDIGT ✅ (verifiziert)
| # | Feature | Status / Umsetzung |
|---|---|---|
| G1 | **Loot vielseitiger** | ✅ 5 Waffen (Pistole, Schrot, MG, **Laser** 0.14s/560 px/s, **Revolver** 9 dmg), **Seltenheits-Ringe** (common 60% / rare 30% / epic 10%, epic-Herz heilt 2, epischer Ring pulsiert), 2 neue **Powerups: Frost** (Monster ×0.35 Tempo, 5s) und **Schnellfeuer** (Feuerrate ×2.2, 8s) |
| G2 | **Item-/Waffenanzeige oben rechts** | ✅ Waffen-HUD oben rechts: alle Fundwaffen als Icons, **antippbar = Waffe wechseln**, aktuelle Waffe hell hervorgehoben; Buff-Zeile darunter („SCHNELLFEUER 6s  FROST 3s") |
| G3 | **Boss-Regel** | ✅ Boss spawnt nur, wenn kein Boss lebt; nach Boss-Tod +60s Pause (getestet: 2. Spawn blockiert, nach Tod `timer=60.1`) |
| G4 | **Biome nach Score** | ✅ 0 Wiese → **500 Wüste** (Kakteen, Sand-Karo) → **1200 Eis** (Piniensäle mit Schnee, Eisbrocken) → **2200 Lavahölle** (dunkle Tiles, tote Bäume mit Glut, Glut-Sprenkel). Übergang: Banner („WIESE/WÜSTE/EISFELD/LAVAHOELLE") + Sound + Spawn-Intervall −10%. Monster werden je Biom leicht eingefärbt (Biome-Tint). Deko wird live umgetexturiert. |
| B2 | **Soft-Look-Shader** | ✅ `shaders/soft_look.gdshader` (CanvasItem, `hint_screen_texture`/`SCREEN_UV` nach Godot-Doku „Custom post-processing" + godotshaders-Rezepten): 5-Tap-Weichzeichner gegen harte Pixelkanten, dezenter Bloom auf hellen Flächen, angehobene Schatten (lift), +7% Sättigung, leichte Wärme, sanfte Vignette. Läuft auf `CanvasLayer`-Layer 1 → **unter** dem HUD (HUD = Layer 2), Android-tauglich (5 Taps). |
| B3 | **Laufanimation** | ✅ Körper bleibt **aufrecht** (kein Kopfüber mehr): nur horizontales Spiegeln (`flip_h`) je Blickrichtung, Wippen (±1.8 px) + comic-Kippen (`skew` ±0.05) + leichte Stauchung im Lauf-Takt. Waffe & Mündungsfeuer drehen weiter voll mit. |

### Verifikations-Evidenz (Headless-Tests)
- `T1 weapons=[pistol, laser, revolver] cur=weapon_revolver` (HUD/Inventar)
- `T2 freeze=4.85 rapid=7.85 buffmult=0.45` (Buffs wirken auf Feuerrate)
- `T3 biome@509=desert`, `T4 biome@2210=lava, spawn_interval=22.68` (Biom-Schwellen)
- `T6 boss_guard=true boss_count=1`, `T7 nach Boss-Tod timer=60.1` (Boss-Regel)
- `T8 postfx=true material=true` (Shader-Layer aktiv)
- Smoke-Test mit 27 Monstern + Boss + Frost 3,5s: **0 Fehler**
- Gefundener & gefixter Bug: `set_biome()` versuchte `.texture` auf Grenzwand-`StaticBody2D` zu setzen → jetzt `spr is Sprite2D`-Guard

### C — Offen
- **LAN Phase 2**: gemeinsame Welt (Host authoritative), geteilte Schäden/Score/Loot
- Release-Keystore für Play Store (aktuell debug-signiert)
- Balancing nach deinem Spielgefühl (Zahlen stehen in `player_controller.gd` WEAPON_DATA, `game_manager.gd` BIOME_STEPS/FREEZE/RAPID)

### D — RUNDE 5: Bugfixes, Perf, Waffen-Look ✅
| Thema | Umsetzung |
|---|---|
| **Joystick hing nach mehreren Runs** | Ursache: Touch-Release kam nie an (Tod/Pause/Ausblenden) → `active` blieb mit altem Touch-Index stehen, neue Berührung wurde ignoriert. Fix: **Re-Grab** bei jeder neuen Berührung + `force_reset()` bei Start-/Todes-Screen & Szenenstart + Reset bei `NOTIFICATION_VISIBILITY_CHANGED` |
| **Boss-Hitbox verbuggt** | Boss skalierte nur den Sprite (2,3×), die `CircleShape2D` blieb Radius 14. Fix: `collision_shape.scale = base_scale` (auch Mini-Splitter 0,65×) — verifiziert `collision_scale=(2.3, 2.3)` |
| **Joystick-Position** | von (20, 620) → **(96, 566)**, P2 gespiegelt (1384, 566) — Daumen-freundlicher |
| **Knopf zum Hauptmenü** | Todes-Screen hat jetzt **NOCHMAL SPIELEN** (direkter Run) + **HAUPTMENUE** (zurück, `restart_game(false)`) + BEENDEN |
| **Performance/Speicher** | Messung über 5 Run-Zyklen: **Node-Zahl konstant 772**, Speicher plateaut bei ~45 MB (kein Leak). Echter Leak gefixt: übrig gebliebene Projektile beim Neustart (Gruppe `projectiles` wird jetzt geräumt). Last-Quellen sind Render-Last (Shader + 9600 Tile-Draws) und Monstermenge → Grafikstufen |
| **Grafikstufen** | Startbild-Button **GRAFIK: HOCH/MITTEL/NIEDRIG** (persistiert im Savegame): NIEDRIG = Shader aus, Bodendetails aus, Spawnabstand ×1,4, max 55 Monster, nur 1 Korruptionszone · MITTEL = Shader an, halbe Details, ×1,15, max 95, 2 Zonen · HOCH = alles, ×1,0, max 150, 3 Zonen |
| **Zufalls-Events** | alle 45–75 s eines von 5: **MONSTERSTURM** (14 Mobs), **ELITEWELLE** (3 Panzer + 3 Splitter), **LOOTREGEN** (8 Items), **FROSTSTURM** (Frost 6 s), **GOLDRAUSCH** (12 s doppelte Punkte) — Banner + Sound, verifiziert |
| **Waffen-Look** | 5 **eigene, detaillierte Waffen-Sprites** (Pistole, Flinte mit Holzschaft, MG mit Magazin/Kühlrippen, Laser mit Glühkern, Revolver mit Trommel & Hahn) statt Linien-Symbole — gelten für Kisten-Loot, Waffen-HUD **und** die **Waffe in der Hand** des Spielers (wechselt live beim Aufsammeln) |

### G — RUNDE 6: PERFORMANCE-BUG GEFUNDEN & BEHOBEN ✅ (höchste Prio)
**Messung im gerenderten Fenster (1920×1080, 60 Monster, Benchmark-Hook):**

| Phase | FPS | Draw-Calls | Objects/Frame | CPU Proz. |
|---|---|---|---|---|
| VORHER „alles an" | **3,6** | **19.254** | 19.382 | 178 ms |
| NACHHER „alles an (HOCH)" | **35,2** | **49** | 246 | 33 ms |
| NACHHER ohne Shader (MITTEL) | **59–60** | 54 | 205 | 19 ms |

**Ursache (der „Fehler"):** `map_generator._draw()` zeichnete **pro Frame** 9.600 Tile-Rechtecke + 9.600 Rasterlinien + ~20.000 Detail-Rects einzeln → ~19.000 Draw-Calls und ~150–400 ms CPU pro Frame. Der Soft-Look-Shader war nur der zweite Faktor (kostet ~24 fps).

**Fix:** Der Map-Hintergrund besteht jetzt aus **3–5 Draw-Calls**:
1. **Basiskaro** als 120×80-Pixel-Bild (1 Pixel pro Tile) mit `NEAREST` ×32 hochskaliert → 1 Sprite, 1 Draw-Call
2. **Karo-Raster** als eine 32×32-Kacheltextur mit `TEXTURE_REPEAT` + `region_rect` über die ganze Karte → 1 Sprite, 1 Draw-Call
3. **Details** (Sprenkel, Halme, Blumen/Kristalle/Glut) als **MultiMeshInstance2D** mit Per-Instance-Transform + Farbe → 3 MultiMeshes, 3 Draw-Calls (9.600 / 4.100 / ~800 Instances)
4. `_draw()` ist jetzt bewusst leer

**Weitere Optimierungen:**
- Shader entschärft: `filter_linear_mipmap` → `filter_linear` (kein Mipmap-Bau pro Frame), Tap-Gewichte angepasst
- **Soft-Look-Shader nur noch auf HOCH** — Standard ist **MITTEL** (60 fps, ohne Shader), NIEDRIG für schwache Geräte
- Config-Version im Savegame: bestehende Installationen werden einmalig automatisch auf MITTEL gestellt
- Grafikstufen wirken jetzt auf: Shader, Rasterlinien, Detaildichte (2/1/0 pro Tile), Monster-Obergrenze (150/110/55) und Spawnabstand

**Neu: FPS-/Debug-Anzeige** — im Hauptmenü „FPS-ANZEIGE: AN/AUS" (wird im Savegame gemerkt). Zeigt live: `FPS | Draw | Obj | Proz ms | Phys ms | Monster | Grafik | Shader`.

### H — RUNDE 7: ECHTER CO-OP (LAN Phase 2) ✅
**Vorher:** jeder spielte auf seiner eigenen Karte mit eigenen Monstern (nur Position/HP des Partners wurden gespiegelt).
**Jetzt:** **eine gemeinsame Welt** — Host ist autoritativ, der Client ist Renderer + Input-Terminal.

| Baustein | Umsetzung |
|---|---|
| **Gleiche Karte** | Host würfelt beim Run-Start einen `seed` und schickt ihn mit; der Client erzeugt daraus identische Tiles + Hindernisse. Kisten (Positionen) und Korruptionszonen kommen als Liste mit (`coop_init`). |
| **Gemeinsame Monster** | Host simuliert alle Monster (KI, Schaden, Tod) und schickt alle 0,13 s einen Snapshot (`[id, typ, x, y, hp, blick]*N` über `PackedFloat32Array`). Client erzeugt/aktualisiert/entfernt daraus **Geister** (keine KI, keine Kollision, weiches Nachziehen + Treffer-Blitz). |
| **Client als Terminal** | Client sendet 20×/s nur `input_dir + shoot + zielwinkel`. Der Host bewegt den roten Helden selbst (`remote_driven`), feuert, trifft, öffnet Kisten, sammelt Loot → alles autoritativ. Client-Spieler läuft `remote_controlled` (Position/Blick aus dem Netz). |
| **Geteilter Fortschritt** | Welt-Sync alle 0,4 s: Score, Combo, Biom, Frost/Schnellfeuer/Goldrausch, Boss-HP. Biomwechsel + Banner laufen auf beiden Geräten. |
| **Gegenseitig helfen** | Ein gemeinsamer Run: getroffene Monster, Loot und Kisten sind für beide da; Partner-Herzen/Waffe werden auf beiden Geräten blass oben rechts angezeigt. Einer fällt → Game Over für beide (`coop_over`). |
| **Optik** | Schüsse des Mitspielers werden als Ereignis gemeldet (Mündungsfeuer + kosmetisches Projektil beim Client), Monster-Treffer blitzen beim Client auf. |

**Verifikation (2 Instanzen, eigener Port):** Client `ghosts=21`, `chests=22`, `seed` identisch mit Host, `mypos`/`myhp` vom Host gesteuert (HP sank durch Monstertreffer auf 985), Hosts Held `p2pos` bewegte sich durch Client-Input, RPC-Kanal bestätigt (init + run_start + partner_state).

**Dabei gefundener, gravierender Bug:** Beim Einfügen des Test-Hooks waren die Signal-Verbindungen (`run_start`, `peer_joined`, alle Co-op-Signale) **ans Ende der Testfunktion hinter `get_tree().quit()`** gerutscht → im Normalbetrieb nie verbunden, dadurch wirkte das ganze Netzwerk "kaputt". Jetzt sauber in `_ready()`.
**Debug-Hilfe:** ENET-Port per Umgebungsvariable `COMIC_ENET_PORT` überschreibbar (nötig, wenn mehrere Test-Hosts parallel laufen — ein belegter Port führte zu "verbunden, aber Host sieht nichts").

### E — Roadmap Stand
1. ~~**Charakterauswahl / Personalisierung**~~ ✅ ERLEDIGT (Runde 8): Name + 6 Farben + 6 Hüte im Hauptmenü, im Co-op wählt jeder seins (Profil wird geteilt)
1b. ⏳ **NÄCHSTER SCHRITT: Lobby + 4-Spieler-Modus** (siehe Runde 8, „Offen")
2. ~~**LAN Phase 2**: gemeinsame Welt~~ ✅ ERLEDIGT (Runde 7)
3. **iOS-Export**: machbar, aber nur von macOS mit Xcode + Apple-Developer-Account (Details unten)

### I — Feature-Ideen (Vorschläge, noch nicht gebaut)
| Idee | Warum es sich lohnt | Aufwand |
|---|---|---|
| **Wiederbeleben im Co-op** | Statt "einer tot = Ende" wird der Gefallene *downed* und der Partner kann ihn 3 s daneben stehend aufwecken — das ist gelebte Teamarbeit | klein (Host-Logik + Banner + HUD) |
| **Mini-Map oben rechts** | Große Karte (3840×2560) + Partner/Monster/Bosse außerhalb des Bildschirms | klein-mittel |
| **Ping/Kommandos (8 Richtungen)** | Mitspieler markieren Ziele/„Hilfe!" per Taste — ersetzt Sprachchat im WLAN | klein |
| **Geteilte Level-Ups** | Beide steigen gemeinsam auf; Kartenwahl wird abwechselnd bestimmt | klein |
| ~~**Wellen-Modus mit Shop**~~ ✅ **GEBAUT (Runde 8)** | Zwischen Wellen 30 s Shop (Waffen/Rüstung kaufen) — mehr Meta-Tiefe als reine Kisten | mittel |
| **Bestenliste (global)** | lokal pro Gerät gibt es die Namenseingabe schon (Runde 8); global braucht HTTP-Backend | mittel |
| ~~**Skins/Hüte als Loot**~~ ✅ **GEBAUT (Runde 8)** | Freischaltbares Aussehen aus seltenen Kisten → Langzeitmotivation | mittel |
| **Controller-Support (Gamepad)** | Godot kann Input-Maps; Steam-Deck-artiges Spielen am Handy mit BT-Pad | klein |
| ~~**Bosse mit Angriffsmustern**~~ ✅ **GEBAUT (Runde 8)** | Fächer → Anlauf (Warn-Puls) → Beschwören (3 Minis) | mittel |
| ~~**Biom-Spezialmonster**~~ ✅ **GEBAUT (Runde 8)** | Wüste: Graber (gräbt & taucht beim Helden auf), Eis: Eisgolem (verlangsamt 3 s), Lava: Feuerwerfer (hält Abstand) | mittel |
| **Täglicher Run mit Seed** | Gleicher Seed für alle (z. B. UTC-Datum) + Freunde können denselben Run vergleichen | klein |
| **Cloud-Save / Konto** | Fortschritt & Aussehen geräteübergreifend (Google Play Games) | groß |
| **Mehr Grafik-Stufen-Feinschliff** | z. B. Schattenwurf, Partikel an/aus je Stufe, Auflösungsskalierung (render_scale 0.8) für schwache Geräte | klein |

### J — RUNDE 8: Punkte 4/5/6/8 + Personalisierung ✅ (verifiziert)
| Punkt | Umsetzung | Verifikation |
|---|---|---|
| **4 · Boss-Angriffsmuster** | 3-teiliger Zyklus: **Kugelfächer** (5 Schüsse, 4 s) → **Anlauf** (0,65 s Warn-Puls der Größe, dann 6× Tempo-Sturm) → **Beschwören** (3 Mini-Splitter + Banner) | Headless-Test: `boss_states=[0,1]`, Timer 3,0→1,0→0,7→Umlauf, HP 40 |
| **5 · Biom-Spezialmonster** | **Graber** (Wüste, 8): gräbt sich alle 4 s unter und taucht 130–210 px neben dem Helden auf (Fade-In) · **Eisgolem** (Eis, 9): 16 HP, verlangsamt beim Kontakt 3 s (Held bläulich) · **Feuerwerfer** (Lava, 10): hält 320–460 px, wirft 2-DMG-Feuerbälle. 22 % Biom-Chance ab 20 s | Headless: `slow=2.27` nach Golem-Kontakt; Typen 8/9/10 spawnen & verhalten sich |
| **6 · Wellen-Modus mit Shop** | Startbild-Button **MODUS: ENDLOS / WELLEN+SHOP**. Welle N = 5+N·3 Monster, alle 5 Wellen ein Boss. Welle geräumt → **30 s Shop** mit 6 Käufen (Heilen 15 / Schild 20 / Waffe 25 / Max-Herz 30 / Tempo 35 / Schaden 40), Münzen = 50 % der Kill-Punkte. HUD-Zeile „WELLE n · Münzen", „WEITER"-Button startet sofort | Headless: `wave=1 mobs=8` → `wave_rem=0 shop=true time=25` → Kauf `coins 100→70, maxhp 5→6` → `wave2=2 mobs=11` |
| **8 · Hüte als Loot + Personalisierung** | Hauptmenü: **Namenseingabe** (max 10), **6 Farben** (Blau/Rot/Grün/Gelb/Lila/Weiß), **6 Hüte** (Ohne/Kappe/Cowboy/Krone/Zylinder/Mütze) — prozedural auf die Heldentextur gezeichnet. Gespeichert in `user://profile.save`. **Epische Kisten schalten zu 35 % einen zufälligen Hut frei** (Banner „NEUER HUT: …"), Hut-Auswahl erscheint im Menü. Im Co-op teilen beide ihr Profil (Name/Farbe/Hut) → Partner-Name steht im HUD oben rechts | Headless: `hat_tex_diff=true hats=6 colors=6`; Profil lädt/speichert |

**Fix dabei:** im Wellen-Modus wurde der Dauer-Spawner nach dem Stopp wieder gestartet (Wellen wären nie zu Ende gegangen) → `start_spawning` läuft jetzt nur noch im Endlos-Modus. **Zusätzlich:** Wellen-Fortschritt läuft über einen Zähler (`wave_remaining`, zählt auch Splitter-Kinder), nicht über „keine Monster in der Szene" — sonst blockiert ein Minimonster den Shop.

### M — RUNDE 10: Lobby-Zwischenfenster + 4-Spieler-Modus ✅ (verifiziert)
**Auftrag:** (1) Mitspieler soll erst in die **Lobby des Hosts** joinen, beide sehen sich dort, erst ein **START des Hosts** bringt beide **gleichzeitig** aufs Feld. (2) Modus mit **mehr als 2 Spielern (bis 4)**.

#### 1. Lobby-Zwischenfenster
**Vorher:** sobald ein Client verbunden war, rief `_on_peer_connected()` direkt `begin_run.rpc()` → der Run startete automatisch, ohne Kontrolle und ohne dass der Client etwas von der Gruppe sah.
**Jetzt:** das automatische Starten ist entfernt. Ablauf:
1. Hauptmenü → `LAN SPIEL` → **Spielerzahl 2 / 3 / 4** wählen (neue Knopfreihe, aktive Zahl hervorgehoben) → `HOSTEN`.
2. Host: `NetManager.host_game(n)` öffnet den Server mit `n-1` Client-Slots und geht in den neuen Zustand **`GameState.LOBBY`**. Statt des Spiels erscheint das **Lobby-Fenster**: Titel „LOBBY — HOST", Zeile mit **eigener IP + Port**, „Warte auf Mitspieler … · k/n verbunden", die **Spielerkarten** (Heldengrafik in der gewählten Farbe + Hut, Name, „Host/ Bereit/ Noch nicht bereit", Markierung „(DU)") und der Knopf **`SPIEL STARTEN (k)`** (erst aktiv, wenn mindestens ein Mitspieler verbunden ist).
3. Client: in der Hostliste des WLANs (oder per IP) `BEITRETEN` → `GameState.LOBBY` mit **eigenem Fenster**: „Verbunden — warte auf den Host …", dieselbe Spielerliste, eigene Karte, und **`BEREIT`** zum Umschalten (wird an den Host gemeldet und in dessen Liste als „Bereit" angezeigt).
4. Host drückt **START** → `coop_begin.rpc()` (reliable, `call_local`) → **alle Geräte starten im gleichen Frame-Moment**: der Host baut seine Welt und schickt danach Seed/Kisten/Zonen, die Clients warten auf genau diese Daten und bauen dieselbe Karte. Beide Seiten betreten so **gleichzeitig** das Feld.
5. `VERLASSEN` schließt die Sitzung sauber (`leave_lobby()` → zurück ins Hauptmenü).

**Protokoll (neue RPCs in NetManager):** `coop_lobby(roster, max)` (Host → alle, reliable), `coop_profile(name,color,hat)` (Client → Host; der Host legt Name/Farbe/Hut des Peers in der Lobby ab), `coop_ready(r)` (Client → Host), `coop_begin()` (Host → alle). Der Client schickt sein Profil automatisch direkt nach dem Verbinden (`multiplayer.connected_to_server`).

**Wichtig dabei gefixt:** `_send_coop_init()` wurde vorher beim Beitritt geschickt — da waren Kisten und Zonen noch nicht generiert. Jetzt geht der Init **nach** dem Weltaufbau des Hosts raus (`start_lan_run_as_host()`), die Clients bauen erst dann (Guard auf `_net_seed != 0`).

#### 2. 4-Spieler-Modus
**Modell:** Host ist **Slot 1 und autoritativ**, Clients bekommen beim Beitritt den ersten freien Slot 2–4. Damit gilt weiter „eine gemeinsame Welt": nur der Host simuliert (Monster, Kisten, Loot, Schaden, Score), Clients senden nur Input und rendern.
- `MAX_CLIENTS 1 → 3` (Server erlaubt jetzt 3 Mitspieler), Slots generisch über `NetManager.lobby` + `_free_slot()`.
- **Spieler-Erzeugung generisch:** neuer Helfer `_spawn_slot_player(slot, remote_driven, remote_controlled)` ersetzt die fest verdrahteten `player`/`player2`-Blöcke. Host: Slot 1 lokal, Slots 2–4 mit `remote_driven` (Input aus dem Netz). Client: **alle** Slots mit `remote_controlled` (Position kommt vom Host), eigener Slot ist `my_slot`.
- **Input-Routing pro Peer:** `coop_input` liefert jetzt die Absender-ID (`multiplayer.get_remote_sender_id()`); der Host mappt Peer → Slot (`slot_of_peer`) und schreibt den Input in den richtigen Helden. Vorher landete jeder Input pauschal auf `player2`.
- **Ein Spieler-Snapshot für alle:** neuer Broadcast `coop_players(data, weapons)` mit 7 Floats je Spieler (Slot, x, y, HP, MaxHP, Blickwinkel, Schild) + Waffennamen. Jeder Client wendet ihn auf **alle** Helden an (eigener Held + Mitspieler-Grafiken in deren Profilfarbe/-hut). Der frühere Ein-Spieler-RPC `coop_player` wird nicht mehr benutzt.
- **Mitspieler-HUD:** die einzelne Partner-Box ist jetzt eine **Liste** (`update_partner_slot(slot, …)` / `_render_partner_rows()`) mit bis zu 3 Zeilen — je Zeile „P<n> Name", Herzen, Waffen-Icon + Name, Schild-Bonus, alles im blassen Ton.
- **Welt-Features auf alle Slots verallgemeinert:** `get_nearest_target()` (Monster jagen den nächsten beliebigen Helden), Kamera (Client folgt dem eigenen Helden, Host der Gruppe über `player_centroid()`), Buffs (`buff_cooldown_mult` für alle), Schild/Slow wirken weiter pro getroffenem Helden (Monster schaden dem kollidierten Körper — funktioniert automatisch für alle 4).
- **Regel bleibt:** einer fällt → Run für alle beendet (`coop_over` an alle).

#### 3. Verifikation (echte Mehrprozess-Tests, headless, je 1 Host + Clients)
**3 Spieler (Port 7892):**
```
LT host roster=3 slots=[1, 2, 3] state=1 lobby_ui=true
LT host state=2 players=[1, 2, 3] profile_slots=[1, 2, 3]
LT host nach4s players=[1, 2, 3] nodes=3 mobs=1
LT c1 state=2 my_slot=2 players=[1, 2, 3] roster=3
LT c1 eigener=true pos=(1993, 1279) mobs=1
LT c2 state=2 my_slot=3 players=[1, 2, 3] roster=3
LT c2 eigener=true pos=(2067, 1279) mobs=1
```
**4 Spieler (Port 7893):**
```
LT host roster=4 slots=[1, 2, 3, 4] state=1 lobby_ui=true
LT host state=2 players=[1, 2, 3, 4] profile_slots=[1, 2, 3, 4]
LT host nach4s players=[1, 2, 3, 4] nodes=4 mobs=1
LT c1 state=2 my_slot=2 players=[1, 2, 3, 4] roster=4 / eigener=true pos=(1993, 1279) mobs=1
LT c2 state=2 my_slot=3 players=[1, 2, 3, 4] roster=4 / eigener=true pos=(2068, 1280) mobs=1
LT c3 state=2 my_slot=4 players=[1, 2, 3, 4] roster=4 / eigener=true pos=(2142, 1280) mobs=1
```
Alle drei/vier Instanzen bauen dieselbe Karte, jeder steuert seinen eigenen Slot, Monster-Snapshots kommen bei allen Clients an. Zusätzlich 0 `SCRIPT ERROR`/`Parse Error` im Regressionlauf.

**Dabei gefundener Bug:** `_try_start_coop_client()` prüfte noch `current_state != MENU` → der Client blieb in der Lobby hängen und baute die Welt nie auf (im Test sichtbar als `state=1 players=[]`). Guard um `LOBBY` erweitert.

### N — RUNDE 11: Meta-Progression (Gold, Kisten-Shop, Skins & Karten) + Startseiten-Aufräumen

#### Auftrag (aus dem Chat)
1. Zahnrad war nicht anklickbar, Startseite wirkt unordentlich (besonders der Text unter BEST SCORE) → aufräumen.
2. Lokalen 2-Spieler-Modus auf einem Gerät vorerst entfernen.
3. Skin-Inhalte **nur mit Münzen** freischalten, Münzen bekommt man **über XP**.
4. Das Konzept soll **zukunftsfähig** sein: auch **Karten (Maps), Mobs** usw. sollen so freigeschaltet werden — eine neue Karte wählen und mit anderen Monstern spielen.
5. Zugang zu Karten- und Skin-Inhalten **nur über Kisten**, die man in einer **Shop-UI** kauft (dort gibt es auch **nicht seltene** Inhalte).
6. Vorbild-Idee: *Clash-Royale*-Prinzip mit Deko-/Sammelartikeln.

---
#### Konzept (Idea-Ausarbeitung für unseren Kontext)

**Leitidee:** Ein **Meta-Layer über dem Run**, komplett offline und persistiert im Profil. Der Run liefert XP → XP wird am Run-Ende in **Gold** umgerechnet → Gold kauft **Kisten** im Shop → Kisten liefern **Skins (Farben/Hüte)**, **Karten** und **Verbrauchsgüter**. Damit hat Langzeitspiel einen sichtbaren Zweck, ohne dass Gameplay-Upgrades (Level-Up-Karten / Wellen-Shop) mit Kosmetik vermischt werden.

**Drei Währungen, klar getrennt (wichtig, damit es nicht verwirrt):**
| Währung | Gültigkeit | Verdienst | Ausgabe |
|---|---|---|---|
| **XP / Level** | nur im Run | Kills | Level-Up-Karten (Endlos-Modus) |
| **Run-Münzen** (`coins`) | nur im Run | Kills im Wellen-Modus | Wellen-Shop zwischen den Wellen |
| **Gold** (neu, persistent) | Profil, über Runs hinweg | am Run-Ende aus Score+XP+Level (+25 % der Run-Münzen) | Kisten & Direktkäufe im Meta-Shop |

**Gold-Formel (Run-Ende):** `gold_gain = int(score / 12) + level * 3 + int(coins * 0.25)`.
Beispiel: Score 1200, Level 8, 40 Run-Münzen → 100 + 24 + 10 = **134 Gold**. Anzeige auf dem Todes-Screen: „+134 GOLD  (Konto: 540)". Auf der Startseite steht dauerhaft ein **GOLD-Chip** neben BEST SCORE.

**Kisten (Kern des Systems).** Gewichtete Zufallsziehung aus dem Pool der Kistenstufe, **Duplicate-Schutz**: bereits Besessenes fällt aus dem Pool; ist der Pool leer, gibt es Gold zurück („UMTAUSCH"). Jede Kiste zeigt ihre möglichen Inhalte als Mini-Icons.

| Kiste | Preis | Pool (mit Gewicht) |
|---|---|---|
| **HOLZKISTE** | 60 Gold | Verbrauchsgüter (Extra-Herz 30 %, Schild-Start 25 %, Schnellfeuer-Start 25 %, 20 Gold zurück 20 %), Farben „selten" (5 %) |
| **SILBERKISTE** | 150 Gold | Farben 45 %, Hüte (Cowboy/Mütze) 30 %, Verbrauchsgüter groß 20 %, 60 Gold zurück 5 % |
| **GOLDKISTE** | 320 Gold | **Karten** 35 %, Hüte (Krone/Zylinder) 40 %, epische Boosts 20 %, 150 Gold zurück 5 % |

→ „Auch nicht seltene Inhalte": die Holzkiste enthält bewusst **keine** Sammelstücke, sondern sofort spürbare Run-Vorteile (Verbrauchsgüter). Das ist der Clash-Royale-Gedanke: billige Kiste = schneller Nutzen, teure Kiste = Sammel-Inhalt.

**Karten (Maps) als zweite Sammel-Schiene.**
| Karte | Biom | Besonderheit | Freischaltung |
|---|---|---|---|
| **WIESE** | meadow | Standard, Biomen-Wechsel nach Score (wie bisher) | frei |
| **WÜSTE** | desert | startet in der Wüste, **Graber-Chance 22 % → 42 %**, Monster +10 % Tempo | Goldkiste **oder** 600 Gold direkt |
| **EISFELD** | ice | startet im Eis, **Eisgolem-Chance hoch**, Boden verlangsamt dauerhaft leicht (×0,9) | Goldkiste oder 600 Gold |
| **LAVAHÖLLE** | lava | startet in Lava, **Feuerwerfer häufig**, Gegner-Schaden +25 % | Goldkiste oder 900 Gold |

Wirkung: `start_biome`, `monster_bias` (Multiplikator auf die Biom-Spezialisten-Chance), `speed_mult`, `damage_mult`. Die Karte wird auf der Seite **KARTEN** gewählt und im Profil gespeichert; die Seite zeigt Biom-Bild, Besonderheit und Status (FREI / WÄHLEN / GESPERRT + Preis). Damit ist der vom Nutzer gewünschte Zukunftspfad („neue Karte mit anderen Monstern") strukturell da — weitere Karten sind nur neue Einträge in `MAPS`.

**Verbrauchsgüter (Direktkauf im Shop, gelten für den nächsten Run, verbrauchen sich beim Start):**
`Extra-Herz` (Start mit 6 Herzen) · `Schild-Start` (2 Ladungen) · `Schnellfeuer-Start` (20 s) · `Kopfgeld` (doppelte Run-Münzen im Wellen-Modus). Preise 30–45 Gold. Anzeige im Shop als „AKTIVE BOOSTS: …".

**Persistenz** (`user://profile.save`, Dictionary, alles mit Defaults → alte Profile bleiben gültig):
`name, color, hat, muted, unlocked (Hüte), unlocked_colors, unlocked_maps, gold, xp_total, active_map, boosts{}`.
**Freischaltungs-Regeln:** Farben 0/1 (Blau/Rot) sind frei, Farben 2–5 und alle Hüte außer „Ohne/Kappe" nur über Kisten. Hüte dürfen weiterhin auch aus epischen Run-Kisten fallen (bestehender Pfad bleibt).

**UI-Aufbau (Startseite und Seiten):**
- **Startseite (aufgeräumt):** Titel → Held + Name → Monster-Parade → **SPIELEN** (groß) → Reihe `LAN SPIEL · CHARAKTER · SHOP · KARTEN` → Reihe `MODUS: ENDLOS/WELLEN` + Chips `BEST SCORE` / `GOLD` → **Zahnrad** oben rechts. Die lange Debug-Zeile unter BEST SCORE entfällt ersatzlos; die Steuerungshinweise wandern als kleiner Tooltip/Untertitel an den SPIELEN-Knopf.
- **SHOP-Seite:** Gold-Chip oben, 3 Kistenkarten (Icon, Name, Preis, Inhalts-Icons, KAUFEN), Bereich DIREKTKAUF mit 4 Boost-Karten (aktiv/gekauft hervorgehoben), ZURÜCK. Kauf → **Öffnungs-Overlay**: Kiste wackelt (Tween), Deckel auf, Inhalt poppt mit Namen auf, bei neuem Sammelstück Banner „NEU: KRONE".
- **KARTEN-Seite:** 4 Kartenkarten mit Biom-Icon, Besonderheit, Status und WÄHLEN/GESPERRT(Preis)-Knopf, ZURÜCK.
- **CHARAKTER-Seite:** gesperrte Farben wie die gesperrten Hüte behandelt (Kachel zeigt „?", Tooltip „Im Shop freischalten"), Zeile „X/6 Farben · Y/6 Hüte".
- **Hauptmenü-Einträge:** 2-SPIELER-Knopf (lokales Duo) entfernt.

**Fehler-Fix Zahnrad:** Ursache ist die Z-Reihenfolge: die Vollflächen-`box` (VBoxContainer, `PRESET_FULL_RECT`) wird **nach** dem Zahnrad hinzugefügt und liegt damit darüber; `Control`-Container schlucken Klicks in ihrem ganzen Rect. Fix: `box.mouse_filter = MOUSE_FILTER_IGNORE` (Buttons als Kinder bleiben klickbar) **und** Zahnrad zuletzt hinzufügen + `z_index` hoch.

**Technische Aufteilung:**
- `game_manager.gd`: `GOLD_PER_SCORE`, `MAPS`, `CHESTS`, `BOOSTS` (Datenkonstanten), Meta-Vars, `_load_profile/_save_profile` erweitert, `award_run_gold()`, `open_chest(tier)`, `buy_boost(id)`, `set_active_map(id)`, `unlock_map/color/hat`, Anwendung von Karte+Boosts in `start_game()`/`_start_coop_client()`, `_pick_random_monster_type()` mit Karten-Bias.
- `ui_manager.gd`: Startseiten-Umbau, `_create_shop_page()`, `_create_maps_page()`, Charakter-Sperren, Gold-Chips, Kisten-Öffnungs-Overlay.
- `texture_manager.gd`: `chest_wood`, `chest_silver`, `chest_gold`, `map_meadow/desert/ice/lava`, `boost_heart/shield/rapid/coin`.

**Verifikationsplan:** Headless-Autotest (`COMIC_META`): Gold-Gutschrift prüfen (`award_run_gold` mit festem Score), Kistenkauf/-öffnung (Gold sinkt, Inhalt landet im Besitz, Duplicate-Schutz greift bei erschöpftem Pool), Kartenwahl (`set_active_map` → Run startet im Karten-Biom, Bias greift), Boost-Kauf (Effekt beim nächsten `start_game`). Danach Regression + APK.

---


**Umsetzung — Ergebnis (alles gebaut und headless verifiziert):**

| Baustein | Umsetzung |
|---|---|
| **Startseite** | Neuer Aufbau: Titel → Held + Name → Monster-Parade → **SPIELEN** (620×104, Steuerhinweise als Tooltip) → Reihe `LAN SPIEL · CHARAKTER · SHOP · KARTEN` (je 296×80) → Reihe `MODUS: ENDLOS/WELLEN` + Chips **BEST SCORE** und **GOLD**. Die lange Debug-Zeile ist ersatzlos weg, der **2-SPIELER-Knopf entfernt**. |
| **Zahnrad-Bug** | Ursache: die Vollflächen-`box` wurde nach dem Zahnrad eingefügt und schluckte als `Control` jeden Klick in ihrem Rect. Fix: `box.mouse_filter = MOUSE_FILTER_IGNORE` (Kinder-Buttons bleiben klickbar) + Zahnrad mit `z_index = 30`. Prüfung: `box_ignore=true zahnrad=true duo_knopf=false`. |
| **Gold** | persistent im Profil; `award_run_gold()` am Run-Ende = `score/12 + level*3 + 25% der Run-Münzen`; Anzeige auf Startseite (Gold-Chip), Shop/Karten-Seite und im Todes-Screen („Score: n / +134 GOLD (Konto: …)"). |
| **Kisten-Shop** | Eigene Startseiten-Seite **SHOP**: Gold-Chip, 3 Kistenkarten (Holz 60 / Silber 150 / Gold 320) mit Icon, Inhaltsliste und KAUFEN-Knopf (deaktiviert bei zu wenig Gold), Bereich **DIREKTKAUF** mit 4 Verbrauchsgütern, Öffnungs-Overlay mit Pop-Animation + „NEU!"-Kennzeichnung. |
| **Karten** | Eigene Seite **KARTEN**: 4 Kartenkarten mit Biom-Icon, Beschreibung und Status (AKTIV / FREIGESCHALTET / GESPERRT + Preis). Kauf per Gold **oder** Kiste. Wirkung im Run: Startbiom, Monster-Bias (Spezialisten-Chance ×bias), Monster-Tempo, Gegner-Schaden, Boden-Effekt. |
| **Farben** | Wie Hüte jetzt sperrbar: Start frei sind nur Blau + Rot, Farben 2–5 kommen aus Kisten (Kachel zeigt „?" + Tooltip). Kopfzeile der Charakterseite: „k/6 Farben · m/6 Hüte freigeschaltet · Gold: n". |
| **Persistenz** | `profile.save` erweitert (gold, xp_total, unlocked_colors, unlocked_maps, active_map, boosts) — alles mit Defaults, alte Profile bleiben gültig. |
| **Technik** | `map_data()`, `get_monster_speed_mult()`, `get_monster_damage_mult()`, `get_ground_slow()` werden in `monster_ai.gd` (Tempo über `zone_boost`, Kontaktschaden über `damage_amount`) und `player_controller.gd` (Boden-Verlangsamung) abgefragt. Texturen: `chest_wood/silver/gold`, `map_meadow/desert/ice/lava`. |

**Verifikation (headless, echter Lauf, `COMIC_META`):**
```
MT shop_page=true kisten=3 boosts=4
MT maps_page=true karten=4
MT char=true farbknopf3_gesperrt=true farbe1_frei=true
MT holzkiste ok=true label=SCHILD-START gold 1000->940          (60 Gold korrekt)
MT goldkiste kind=map label=KARTE EISFELD gold=620              (Karte aus Kiste)
MT besitz huete=[0,1] karten=["meadow","ice"] farben=[0,1]
MT boost_kauf=true heart=1 gold=580
MT karte_gekauft=true aktiv=desert biom=desert
MT run biome=desert maxhp=6 heart_rest=0 speed_mult=1.1         (Karte + Boost wirken)
MT run_gold=134 konto=…                                          (1200/12 + 8*3 + 40*0.25 = 134)
MT alles_besessen kind=boost label=KOPFGELD + SCHNELLFEUER      (keine Duplikate: Sammel-Einträge fallen aus dem Pool)
MT startseite letztes_kind=… box_ignore=true zahnrad=true duo_knopf=false
MT_DONE
```
**Gefundener Bug:** `_consume_boosts()` stand **vor** der Spieler-Erzeugung in `start_game()` → `player` war noch ungültig, das Extra-Herz verpuffte (sichtbar als `maxhp=5` bei `heart_rest=0`). Verschoben hinter den Spieleraufbau → `maxhp=6`.

**Bewusst offen gelassen:** der Pool der Kisten enthält immer auch Verbrauchsgüter, der „alles besessen → Gold zurück"-Zweig ist also nur ein Sicherheitsnetz; der eigentliche Schutz ist, dass fertige Sammelstücke vor der Ziehung aus dem Pool fliegen (kein Duplikat möglich).

### O — RUNDE 12: Echte Welten statt Biom-Varianten + Schalter-Freischaltung + HUD-Neubau ✅

#### 1. Analyse: warum die alten Karten sinnlos waren (Kritik aus dem Chat)
Die vier „Karten“ waren nur **Start-Biome derselben Karte**: die Erde-Karte lief per Score sowieso durch Wiese → Wüste → Eis → Lava. Wer eine „Wüste“ kaufte, bekam also nichts, was er nicht in jedem zweiten Run gratis gesehen hätte — und bei 600–900 Gold war es zusätzlich viel zu billig. Karten müssen **eigene Welten mit eigenem Inhalt** sein, sonst ist der Kauf wertlos.

#### 2. Neues Karten-Modell
| Karte | Welt & Inhalt | Eigene Monster (neue Rigs) | Eigene Physik / Eigenheit | **Schalter** (Freischaltung) | Gold-Alternative |
|---|---|---|---|---|---|
| **ERDE** | die komplette Reise: Wiese → Wüste → Eis → Lava | die 11 bestehenden Typen + Boss | Standard | frei | – |
| **MARS** | roter Sand, Krater, kein Grün; Felsen statt Bäume | **Mars-Männchen** (schwebt, Antenne, schießt Strahlen), **Mars-Rover** (14 HP, fährt langsam und **rammt in Schüben** mit kurzer Anlauf-Warnung) | **Drift-Physik (`drift 0.20`)** — der Held rutscht nach, man muss gegensteuern; Gegner +5 % Tempo | **2.500 XP in EINEM Run** | 6.000 Gold |
| **JUNGLE-PLANET** | dichter Dschungel, **2,1-fache Vegetation** (Palmen + Büsche als Deckung) | **Robo-Affe** (bleibt auf Abstand, **wirft Bananen** — drehen sich im Flug), **Riesenblume** (verwurzelt, spuckt Sporen) | viele Hindernisse → Sichtlinien zu, Gegner **+15 % Schaden** | **3.500 XP in einem Run** *und* Mars vorher frei | 12.000 Gold |

Neue, prozedural gezeichnete Rigs (keine Asset-Dateien): `monster_mars_alien`, `monster_mars_rover`, `monster_robo_ape`, `monster_big_flower`, dazu `banana` (Projektil, rotiert im Flug), `palm`, `bush`, `mars_rock`, `mars_crater` und die Karten-Icons `map_mars`/`map_jungle`. Zwei neue Biome im Map-Generator (`mars`, `jungle`) mit eigenen Bodenfarben, Rasterlinien, Sprenkeln und Deko-Texturen.

#### 3. Schalter-Logik (genau, wie gewünscht)
Ein Kartenschalter ist ein **Run-Meilenstein**, kein Kauf:

    gate = { "type": "xp", "need": 2500, "prereq": "" }       # Mars
    gate = { "type": "xp", "need": 3500, "prereq": "mars" }   # Jungle

- `run_xp` zählt jeden Kill-XP **innerhalb eines Runs** (Reset bei jedem Start).
- `_check_map_gates()` läuft **live bei jedem Kill** und noch einmal am Run-Ende; sind `need` **und** `prereq` erfüllt, wird die Karte freigeschaltet → Sound + Banner **„NEUE KARTE: MARS“**, Karten-Seite aktualisiert sich sofort.
- **Sichtbarkeit des Schalters an drei Stellen:** (a) im **Run-HUD** rechts im Panel der Hinweis `MARS: 1820/2500 XP`; (b) auf der **KARTEN-Seite** pro gesperrter Karte der Block **„SCHALTER: 2500 XP in EINEM Run (Bestwert 1240)“** mit Fortschrittsbalken; (c) wenn die Voraussetzung fehlt, stattdessen „Erst MARS freischalten“.
- `best_run_xp` wird **persistiert** — der Balken zeigt den Fortschritt also über Runs hinweg.
- Gold bleibt **Abkürzung** für Ungeduldige (6.000 / 12.000 — bewusst teuer), damit Gold nicht entwertet wird.

#### 4. HUD im Run neu gebaut (gemeldeter Bug)
**Bug:** `combo_label` lag bei (200,44) und damit **über** der XP-Zeile (10,54); der Wellen-/Münz-Text bei (200,78) klebte direkt am XP-Balken — deshalb „sieht man das Gold nicht“.
**Jetzt vier getrennte Bereiche in Panels** (`_hud_panel_sb`, halbtransparent, gerundet):
- **oben links**: Panel mit Herzreihe (+ P2-Reihe versteckt) und darunter `LVL n` + XP-Balken.
- **oben Mitte**: Score groß (48 px, Outline) mit Combo-Zeile darunter; **Boss-Balken** mittig unter dem Score.
- **oben rechts**: **Waffen-Panel** mit Titel „WAFFEN (antippen zum Wechseln)“ und den Waffenkacheln (Icons, aktive hervorgehoben) — darunter getrennt der **Münz-Chip** (Münz-Icon + Zahl), darunter die **Wellen-Zeile** („WELLE 3 · 7 Monster übrig“), dann Buff-Zeile und der neue **Schalter-Hinweis**.
- **links unter dem Leben-Panel**: die Mitspieler-Liste (bis 3 Zeilen); FPS/Debug bleibt unten links.

`update_wave_label()` setzt **Münzen und Wellentext getrennt** (`coin_label` / `wave_label`), damit sich nichts mehr überlagert.

#### 5. Verifikation (headless, echter Lauf)

    WT vorher karten=["earth"] hinweis=MARS: 1240/2500 XP
    WT nach_2600 karten=["earth","mars"]                        (Schalter kippt live)
    WT nach_3600 karten=["earth","mars","jungle"]               (prereq-Kette greift)
    WT kartenseite karten=3 schalterbloecke=2 erster='SCHALTER: 2500 XP in EINEM Run  (Bestwert 1240)'
    WT mars biome=mars drift=0.2 veg=1.0
    WT mars pool_verteilung={1:68, 11:73, 0:90, 12:32, 2:23, 3:14}    (11=Mars-Maennchen 24%, 12=Rover 11%)
    WT panels links_x=18.0 rechts_x=-436.0 muenzpanel=true schalterlabel=true
    WT welle='WELLE 3   ·   7 Monster uebrig' muenzen=42 muenzpanel_sichtbar=true
    WT_DONE

Plus 0 `SCRIPT ERROR`/`Parse Error` im Regressionlauf. **Migration:** alte Profile mit `unlocked_maps=["meadow"]` bzw. `active_map="meadow"` werden automatisch auf die neue ID `earth` umgeschrieben.

#### 6. Bewusst offen (nächste Runde)
Meteoriten-Einschläge auf Mars (Warnschatten → Einschlag), Bananen-**Splitter** beim Aufprall (Banane platzt in 3 kleine), **eigene Karten-Bosse** (Meteor-Boss / Affen-Boss statt Krone-Boss), Drift auch für Monster, und die Clash-Royale-Idee **Deko-Sammelartikel** (nur Aussehen, keine Wirkung) als zusätzlicher Kisten-Inhalt.

### P — KONZEPT: Planeten & Jahreszeiten (Optionen zur Entscheidung) + UI-Paket

#### 0. Schon erledigt (Bug aus dem Chat)
**Kisten-Öffnung zeigte teils nur den Namen.** Ursache: die Held-Texturen für Farben/Hüte werden erst **bei Bedarf** erzeugt (`TextureManager.get_player_texture`), der Dialog holte sie aber mit `get_texture("player_c4_h0")` → `null` → kein Bild. Fix: neue Hilfe `_chest_icon_texture(res)` (nutzt `get_player_texture`, Fallback auf die Kiste) und eine echte **Reveal-Sequenz**: Kiste wackelt 3×, hüpft beim Deckel-Aufspringen, verschwindet, Inhalt poppt mit Bounce + Sound; Sammelstücke bekommen „NEU!" in Grün und grüne Schrift. Verifiziert für Hut/Farbe/Karte/Boost/Gold (`bild=true` in allen 6 Fällen).

#### 1. Grundprinzip Jahreszeiten
Ein **Planet** = Inhalts-Paket (Boden-Palette, Deko, Monster-Rigs, Physik, Schalter). Eine **Jahreszeit** ist die zweite Achse: sie ändert **Aussehen + Gefahr + Modifikatoren**, ohne neue Monster-Rigs. Alles läuft über die vorhandenen Tabellen (`BIOMES`: light/dark/grid/speck; Pflanzendichte; `drift`/`ground_slow`; `speed`/`damage`; Loot-Anzahl) — genau dafür ist die Struktur aus Runde 12 schon gebaut.

| Jahreszeit | Boden | Vegetation | Effekt/Physik | Monster | Loot |
|---|---|---|---|---|---|
| **Frühling** | frisches Grün | dicht belaubt, Blüten | Pollen-Partikel, normaler Boden | normal | normal |
| **Sommer** | ausgeblichen/gelblich | **schüttere, kahle Bäume**, Staub | **Hitze-Flimmern** (Sichtnebel), Boden trocken (schnell) | **+10 % Tempo** | normal |
| **Herbst** | orange/braun | Laub + **fallende Blätter** (Partikel) | Laub bedeckt den Boden | normal | **mehr Loot/Kisten** |
| **Winter** | weiß/grau | **kahle Zweige + Schnee liegt** | **glatt (Drift)**, Schneeverwehungen als Hindernis, Schneefall | **−15 % Tempo** | Kisten besser sichtbar |

#### 2. Vier Umsetzungs-Optionen

**OPTION A — Jahreszeiten als Stufen IM Run** (wie heute die Erd-Klimazonen)
Ein Planet startet in einer Jahreszeit und wandert per Score weiter: Frühling → Sommer → Herbst → Winter → (Zyklus). Aufwand klein-mittel, nutzt die vorhandene Biom-Schwellen-Logik. *Pro:* ein langer Run zeigt alles. *Contra:* keine Wahl, jede Runde läuft gleich.

**OPTION B — Jahreszeit = eigene Karte** (Planet × 4 als Sammelkarten)
Die Karten-Seite listet pro Planet vier Jahreszeiten-Karten (JUNGLE — SOMMER, JUNGLE — WINTER …), jede mit eigenem Schalter und eigenen Modifikatoren. Aufwand mittel (Tabelleneinträge + Grafik über Paletten/Deko). *Pro:* maximale Sammel-Tiefe (3 Planeten × 4 = 12 Karten), bewusste Wahl der Herausforderung (Winter = glatt, Sommer = schnell), passt perfekt zu Gold/Kisten/Schaltern. *Contra:* mehr Auswahl-UI nötig, Monster bleiben gleich.

**OPTION C — Live-Zyklus** (Seasons wechseln während des Runs)
Alle ~60–75 s wechselt die Jahreszeit live mit weicher Überblendung (Palette lerpt, Bäume tauschen, Schnee setzt ein). Aufwand groß, Balance- und Performance-Risiko auf niedriger Grafikstufe. *Pro:* spektakulär, gibt langen Runs Optik-Höhepunkte.

**OPTION D — HYBRID (Empfehlung)**
- Jeder Planet bekommt auf der Karten-Seite einen **Jahreszeiten-Streifen** (4 Felder, einzeln per Schalter freischaltbar, z. B. „spiele JUNGLE und erreiche 2.000 XP im Sommer").
- Die **gewählte Jahreszeit bestimmt den Start**, im Run wandert sie per Score weiter (wie A) — kurze Runs = gezielte Wahl, lange Runs = alle vier.
- Dazu die **Deko-Sammelartikel** (Clash-Royale-Idee) als Kisten-Inhalt: reine Platzier-Optik („Schneemann", „Hängematte", „Meteoriten-Skulptur"), die im Hintergrund des Planeten auftaucht.

#### 3. Planeten-Fahrplan
| Planet | Thema | Seasons | Status |
|---|---|---|---|
| **ERDE** | die Reise Wiese→Wüste→Eis→Lava | heute Klimazonen, später Seasons | ✅ gebaut |
| **MARS** | Staub, Krater, Drift | Perihel-Sommer (Staubsturm, schnell) · Eiszeit (CO₂-Schnee, glatt) · Sturmzeit (Sicht runter) | ✅ Basis gebaut (Rigs, Drift, Schalter) |
| **JUNGLE** | Vegetation | **Frühling** (Blüten, dicht) · **Sommer** (kahl, Hitze) · **Herbst** (Blätterfall, Loot) · **Winter** (Schnee, glatt, langsam) | ✅ Basis gebaut (Rigs, Bananen) |
| **EISMOND** | ewiger Winter, Roboter-Drohnen | nur Winter + „Sonnenfinsternis"-Event | 💡 Idee |
| **VULKANWELT** | Lava, Ascheregen | Ascheregen · Erkaltungsphase | 💡 Idee |
| **RUINENSTADT** | verfallene Stadt, Banditen-Roboter | Tag/Nacht statt Seasons | 💡 Idee |

#### 4. UI-Paket (Priorität von oben nach unten)
1. ✅ **Kisten-Dialog** gefixt + Reveal-Animation (siehe 0.)
2. **Karten-Seite**: Jahreszeiten-Streifen (4 Kacheln je Planet, gesperrte grau mit Schalter-Text) + kleine Biom-Vorschau.
3. **Shop-Kisten**: Seltenheitsrahmen (Holz=braun, Silber=grau, Gold=golden) und ein „ÖFFNEN"-Knopf mit kurzem Aufblitzen.
4. **Zahlen animieren**: Gold zählt im Shop und im Todes-Screen hoch, statt zu springen.
5. **Run-HUD**: Schalter-Hinweis als Mini-Fortschrittsbalken im rechten Panel (statt reiner Textzeile).
6. **Todes-Screen**: drei Zeilen mit Icons (Score / +Gold / Bestwert).
7. **Deko-Artikel-Anzeige**: kleine „Sammlung"-Reihe auf der Charakter-/Karten-Seite (nur Optik).

### Q — RUNDE 13: Jahreszeiten umgesetzt (Option D Hybrid) + UI-Paket ✅

**Entscheidung des Nutzers:** Hybrid **D** (Jahreszeiten-Streifen je Planet + Fortschritt im Run), zuerst **Jungle-Jahreszeiten** + UI-Paket.

#### 1. Jahreszeiten-System
Vier Jahreszeiten als Datentabelle (`SEASONS`), jede mit Optik, Vegetationsdichte und Modifikatoren:

| Jahreszeit | Effekt | Schalter (XP in EINEM Run) |
|---|---|---|
| **FRÜHLING** | dichte Blätter, ruhiger Start | frei |
| **SOMMER** | Vegetation ×0,62 (kahle, schüttere Bäume), Gegner **+10 % Tempo**, Boden trockener (×0,97) | 1.500 XP |
| **HERBST** | Vegetation ×1,10, Gegner +15 % Schaden | 2.500 XP |
| **WINTER** | Vegetation ×0,75, Gegner **−15 % Tempo**, **Drift 0,17** (glatt), Boden ×0,92 | 3.500 XP |

- **Fortschritt im Run:** die gewählte Jahreszeit ist der Start, danach wandert sie per Score weiter (**alle 1.400 Punkte** eine Jahreszeit im Zyklus) — kurze Runs = gezielte Wahl, lange Runs = alle vier. Wechsel mit Banner + Sound.
- **Schalter:** pro Planet eigene Freischaltung (`season_unlocks`), live bei jedem Kill und am Run-Ende geprüft (`_check_season_gates`), Banner „NEUE JAHRESZEIT: WINTER"; Fortschritt als `_switch_need()` im HUD-Balken und als Text auf der Karten-Seite.
- **Feste Kopplung an den Planeten:** Erde behält die Klimazonen-Reise (`seasons_enabled()` ist für Erde false), Mars und Jungle haben Seasons.
- **Persistenz:** `active_season` (gewählte Jahreszeit je Planet) und `season_unlocks` liegen im Profil.

#### 2. Optik der Jahreszeiten (ohne neue Asset-Dateien)
- `map_generator.set_season()` färbt die komplette Palette über eine **Multiplikation** plus – wo Aufhellen nötig ist – einen **Mix Richtung Schneefarbe** (Multiply kann nicht heller werden: der erste Versuch machte den Winter *dunkler*, per Test aufgefallen und korrigiert).
- **Baum-Textur wechselt je Jahreszeit:** Jungle = Palme (Frühling/Herbst) → **Busch/kahl im Sommer** → **nackter Baum (dead_tree) im Winter**, dazu Blau-Modulate im Winter und Orange im Herbst.
- Zusätzliche Details: Winter bekommt weiße Boden-Sprenkel (Schneeflecken), Herbst orangefarbenes Laub auf dem Boden.
- Vegetationsdichte kommt aus `Karte × Jahreszeit` — der Dschungel hat 2,1-fache Vegetation, im Sommer nur 2,1 × 0,62.

#### 3. UI-Paket (umgesetzt)
1. **Kisten-Dialog gefixt** (frühere Runde): Icon wurde für Farben/Hüte nicht gefunden → nur der Name; jetzt `_chest_icon_texture()` + echte Reveal-Sequenz.
2. **Karten-Seite**: pro Planet ein **Jahreszeiten-Streifen** aus 4 Kacheln — freie farbig (aktive aufgehellt), gesperrte grau mit Tooltip („gesperrt: 2500 XP in einem Run auf JUNGLE"), darunter die Zeile „Aktiv: SOMMER · Schalter: HERBST: 2500 XP in einem Run (Bestwert 1200)". Klick auf eine Kachel wählt Planet **und** Jahreszeit in einem Schritt.
3. **Shop-Kisten** haben jetzt Seltenheitsfarben (Holz = braun, Silber = grau, Gold = golden) und heißen „KAUFEN + OEFFNEN".
4. **Gold-Zahl zählt animiert hoch** (`animate_gold`, Tween über 0,7 s) — beim Kistenkauf, beim Boostkauf und beim Kartenkauf.
5. **Run-HUD**: der Schalter-Hinweis hat jetzt einen **Mini-Fortschrittsbalken** (`switch_bar`) unter dem Text.
6. **Todes-Screen**: dreizeilig formatiert („SCORE n / +n GOLD · KONTO n" + Bestwert).

#### 4. Verifikation (headless, echter Lauf)

    ST nach1600 saisons=["spring","summer"]
    ST alle saisons=["spring","summer","autumn","winter"]        (Schalter-Kette)
    ST im_run folge=["spring","summer","autumn","winter"]        (Wechsel per Score)
    ST winter tempo=0.85 drift=0.17 boden=0.92 veg=1.575
    ST sommer tempo=1.1 veg=1.302      ST herbst loot=1.4
    ST optik hindernisse=238 baum_wechsel=true mod_wechsel=true
             boden_sommer=(0.29,0.55,0.18)  boden_winter=(0.66,0.79,0.72)  helligkeit true
    ST kartenseite streifen=2  hinweis_jungle='Aktiv: SOMMER  ·  Schalter: HERBST: 2500 XP in einem Run (Bestwert 1200)'
    ST hud balken braucht=2500 sichtbar=true max=2500.0
    ST_DONE

Boden wird im Winter **heller** (Schneefarbe, `helligkeit true`) statt dunkler, Baum-Rig und Modulate wechseln, Schalter und HUD-Balken greifen. 0 `SCRIPT ERROR` im Regressionlauf.

#### 5. Offen (nächste Runde)
Karten-Bosse (Meteor-/Affen-Boss statt Krone-Boss), Meteoriten-Einschläge auf Mars, Bananen-Splitter beim Aufprall, **Deko-Sammelartikel** mit eigener Sammlungs-Seite (Punkt 7 des UI-Pakets ist noch nicht gebaut), Planeten **EISMOND**/**VULKANWELT**/**RUINENSTADT**, Sommer-Hitze-Flimmern als Sicht-Effekt.

### R — RUNDE 14: Eigene Weltgenerierung je Planet, exklusive Monster, schönere Kisten

**Kritik (aus dem Chat):** Die neuen Karten sehen aus wie die Startkarte in anderer Farbe — Bäume/Steine passen nicht, Mars braucht **große Felsen und Krater**, der Dschungel **viel mehr und größere Bäume, Bambus**, es fühlt sich wie eine „billige Kopie" an statt wie ein neues Spielerlebnis. Außerdem: In-Game-Kisten sind noch nicht schön (Farbe = Qualität fehlt, Öffnungs-Anzeige hübscher), und die Planeten brauchen **komplett eigene Monster** — Mars nur Mars-Monster, Jungle nur Jungle-Monster, nichts von der Startkarte.

#### 1. Weltgenerierung je Planet (Kern dieser Runde)
Bisher war „Karte" nur eine Palette + Baum-Texturtausch. Jetzt bekommt jeder Planet ein **Terrain-Profil** (`PLANET_TERRAIN`), das drei Dinge steuert:

| Ebene | Erde | Mars | Jungle |
|---|---|---|---|
| **Bodenmuster** | Schachbrett (wie bisher) | **Dünenbänder** (`dunes`): weiche Sinus-Bänder + grobes Rauschen, kein Schachbrett | **Kronenschatten** (`canopy`): große dunkle/helle Flecken wie Baumkronen-Schatten + Moos |
| **Kleindeko** | Sprenkel, Grashalme, Blumen | Kraterstaub-Sprenkel, Kies, **keine Pflanzen** | Sprenkel, **Farne**, Blätter, Pilze + Blüten |
| **Hindernisse (geclustert!)** | Baum 1–2, Fels 1–2 | **Große Felsen 1–3** (Scale 1,6–3,0, Radius 20), **Krater** (Scale 1,4–2,4, keine Kollision = begehbare Mulde), kleine Felsen | **Dschungelbaum** (Scale 1,2–2,2) 1–3, **Bambus** 3–7 (Scale 0,9–1,4, Radius 12), **Farne** 2–4 |

Umsetzung: `place_planet_obstacles()` ersetzt `place_obstacles()` und platziert **Cluster** (Zentrum zufällig, dann N Kopien im Umkreis 30–70 px) statt Einzelobjekte — das allein ändert den Look massiv. Neue Texturen (prozedural, wie immer): `mars_boulder`, `mars_boulder_big`, `mars_rock`, `mars_crater`, `jungle_tree`, `bamboo`, `fern`, `mushroom`. Der Boden bleibt **1 Pixel pro Tile + NEAREST** (1 Draw-Call) — nur das Muster ist jetzt je Planet ein anderes, deshalb kostet das keinen Frame.

#### 2. Exklusive Monster je Planet (keine Überschneidung)
`_pick_random_monster_type()` gibt es künftig **strikt** getrennt — hat ein Planet einen Pool, kommt **nur** der Pool (kein Rückfall auf Erde-Typen):

| Planet | Pool | Eigenschaften |
|---|---|---|
| **ERDE** | Grün, Rot, Blau, Lila, Werfer, Splitter, Panzer (+ Biom-Spezialisten Graber/Eisgolem/Feuerwerfer in ihren Klimazonen) + Boss | wie bisher |
| **MARS** | Mars-Männchen, **Mars-Drohne** (neu), Mars-Rover, **Mars-Wächter** (neu) | Männchen: schwebt + Strahl. **Drohne: schnell, stürzt sich auf den Helden und explodiert (2 Schaden, stirbt dabei)**. Rover: rammt in Schüben. **Wächter: 22 HP, Panzerung 50 % (Projektile machen halben Schaden), schwerer Kontaktschaden** |
| **JUNGLE** | Robo-Affe, **Robo-Tiger** (neu), **Rankenfalle** (neu), Riesenblume | Affe: wirft Bananen. **Tiger: sehr schnell, Kurz-Attacken**. **Rankenfalle: verwurzelt, schnappt zu wenn der Held nahe kommt (2 Schaden)**. Blume: spuckt Sporen |

Neue Rigs: `monster_mars_drone` (Untertasse mit rotem Auge + Leuchtring), `monster_mars_guard` (gepanzerter Brocken mit Schildplatte), `monster_robo_tiger` (vierbeinige Blechkatze mit Leuchtstreifen), `monster_vine_trap` (gezahntes Maul auf Rankenstiel). Technik: neue Felder `armor` (Schadensreduktion in `take_damage`) und `kamikaze` (Kontakt-Treffer → `die()`), plus eigene Bewegungszweige.

#### 3. Kisten im Run: schöner + Qualität sichtbar
- **Drei Kistengrafiken** für die Seltenheit: `chest_run_common` (Holz, grauer Beschlag), `chest_run_rare` (silberne Bänder + blaues Juwel), `chest_run_epic` (goldene Bänder + lila Juwel + Zackenrand).
- **Leuchtkranz** hinter der Kiste in der Seltenheitsfarbe, sanft pulsierend (Tween) → man sieht aus der Ferne: „die ist besser".
- **Öffnungs-Anzeige** statt rohem Text: Fortschrittsbalken über der Kiste + Prozentanzeige, danach **Aufpoppen** des Inhalts mit Seltenheits-Ring, Namensschild (schwebt kurz nach oben) und Sound.
- Seltenheit wird beim Platzieren gewürfelt (60/30/10 %) und beeinflusst den Loot (epic = besserer Pool).

#### 4. Verifikationsplan
Headless: (a) Terrain — Hinderniszahl/-größen und Bodenpixel je Planet unterscheiden sich messbar (Mars: keine Pflanzen-Deko, Krater vorhanden; Jungle: Bambus-Cluster > N); (b) Monster — je 300 Ziehungen pro Planet darf **nur** der Pool vorkommen, Erde-Typen 0-mal; (c) Kisten — Rarität setzt Textur + Leuchtfarbe, epischer Loot-Pool besser. Danach: Debug-Fenster zum Ansehen (kein APK in dieser Runde).

**Umsetzung — Ergebnis (headless verifiziert):**

| Punkt | Umsetzung |
|---|---|
| **Eigene Weltgenerierung** | `PLANET_TERRAIN`-Tabelle: Erde = Schachbrett + Baum/Fels; **Mars = Dünenbänder** (Sinus + Grob-Rauschen, kein Schachbrett) mit **großen Felsen (Scale 1,5–2,6, Kollision 26)**, kleinen Felsen und **Kratern (Decal, keine Kollision, z_index -5)**; **Jungle = Kronenschatten-Flecken** mit **Dschungelbäumen (Scale 1,1–2,1)**, **Bambus (3–6 Halme pro Cluster)**, **Farnen** und Büschen. Alle Hindernisse werden in **Clustern** platziert (`place_planet_obstacles`) — das ändert den Look fundamental. Neue Texturen: `mars_boulder`, `mars_boulder_big`, `mars_crater_decal`, `jungle_tree`, `bamboo`, `fern`, `mushroom`. |
| **Boden** | Bleibt 1 Pixel pro Tile + NEAREST (1 Draw-Call), aber **drei verschiedene Muster**: Schachbrett / Dünen / Kronenschatten. Messbar: Nachbar-Pixeldifferenz Erde 0,33 vs. Mars/Jungle 0,12. |
| **Exklusive Monster** | Pools sind **strikt** getrennt (kein Rückfall): Mars = Männchen, **Drohne** (neu), Rover, **Wächter** (neu); Jungle = Affe, **Tiger** (neu), **Rankenfalle** (neu), Blume. Erde = nur Erde-Typen. 400 Ziehungen je Planet → **0 fremde Typen**. |
| **Eigenschaften** | Neue Felder `armor` (Wächter: 50 % weniger Schaden, verifiziert 10 → 5) und `kamikaze` (Drohne stirbt beim Treffer). Tiger: Kurz-Attacken mit Anlauf; Rankenfalle: schnappt bei < 185 px zu (Burst 250 px/s). |
| **Kisten im Run** | Drei Kistengrafiken nach Seltenheit (Holz/Silber/Gold mit Zackenrand), **Leuchtkranz** in der Seltenheitsfarbe (pulsierend, von Weitem sichtbar), **Fortschrittsbalken** statt Text beim Öffnen, **schwebender Item-Name** in der Seltenheitsfarbe, epische Kiste = **2 Loot-Stücke** (verifiziert). Seltenheit wird beim Platzieren gewürfelt (60/30/10). |
| **Grafikstufen** | Vegetationsdichte jetzt an die Grafikstufe gekoppelt (NIEDRIG 0,60 / MITTEL 0,85 / HOCH 1,0): Jungle 531 Objekte auf MITTEL statt 664. |

**Zwei echte Bugs dabei gefunden und behoben:**
1. **Hindernisse wurden zwischen Runs nicht geräumt** — die Liste wuchs immer weiter und der Dschungel erbte **Krater und Felsen vom Mars-Run** (im Test sichtbar als `crater 22` in der Jungle-Statistik). `place_planet_obstacles()` räumt jetzt zu Beginn auf.
2. **Grenzwände landeten ohne Kind-Eintrag in `obstacles`** — dadurch liefen `obstacles` und `obstacle_kinds` auseinander (Test zeigte „?"-Einträge). Wände bekommen jetzt `kind = "wall"`.

**Verifikation:**
```
W14 earth  muster=meadow objekte=122 arten={tree:67, rock:51, wall:4}          nachbar_diff=0.33
W14 mars   muster=mars   objekte=157 arten={tree:82, crater:20, rock:51, wall:4} nachbar_diff=0.12
W14 jungle muster=jungle objekte=531 arten={tree:328, rock:199, wall:4}        nachbar_diff=0.12
W14 mars_pool=[15,12,16,11]  jungle_pool=[17,18,13,14]
W14 erde_typen=[1,0,2,3]  erde_hat_mars_oder_jungle=false
W14 kiste episch tex=true glow=true loot_stuecke=2 balken=true
W14 waechter panzerung hp 22->17 (10 Schaden -> 5) kamikaze_drohne=true
```

**Noch offen:** Meteoriten-Einschläge auf Mars, Rankenfalle-Ranken als Deko, Karten-Bosse (Meteor-/Affen-Boss), Deko-Sammlungsseite, weitere Planeten (Eismond/Vulkanwelt/Ruinenstadt).

### S — RUNDE 15: Tester-Feedback ("Gabechen") — 13 Punkte

Alle Punkte aus dem Testbericht, mit der im Code gefundenen Ursache:

| # | Feedback | Ursache im Code (geprüft) | Lösung |
|---|---|---|---|
| 1 | Verschiedene **Schwierigkeiten** | es gibt nur feste Monster-Werte | 4 Profile LEICHT/NORMAL/SCHWER/HARDCORE (Monster-HP, Schaden, Tempo, Spawnrate, Münz-Faktor, Startherzen). Auswahl auf der Startseite, im Profil gespeichert, im Pausenmenü umstellbar |
| 2 | **Waffen-Inventar** — genervt wenn die gute Waffe vom Revolver ersetzt wird | `owned_weapons` existiert bereits, aber das Aufsammeln ruft `switch_weapon()` → **sofortiger Zwangswechsel** | Aufsammeln legt die Waffe nur ins **Inventar** (kein Zwangswechsel, „NEU"-Badge). Wechseln per HUD-Taste (durchschalten) und Tasten **1–5** |
| 3 | **Utilitys**: Heiltrank, Bombe | fehlen komplett | 2 Utility-Slots: **HEILTRANK** (+2 Herzen), **BOMBE** (Flächenschaden), **ZEITLUPE** (3s). Im Shop kaufbar + Kisten-Drops. Auslösen per HUD-Button und **Q/E** |
| 4 | **Pausen-Screen** | nur `get_tree().paused` für Level-Up-Karten, kein Menü | Echtes Pausen-Overlay (HUD-Button + **ESC/P**): Weiter, Neustart, Einstellungen, Hauptmenü. Pausiert Spiel **und** Wellen-/Shop-Timer |
| 5 | **Dschungel-Hitboxen buggy** | Kollisionskreis sitzt in der **Sprite-Mitte** und skaliert voll mit — Bambus ist 112 px hoch, trifft also mitten im Nichts; Spieler bleibt hängen/läuft durch | Hindernisse kollidieren jetzt an der **Basis** (Stammfuß/Boden) mit eigenem, kleinerem Radius: neue Felder `rbase` + `yoff` je Objektart |
| 6 | **Schießende Gegner zu OP** | Feuerrate/Schaden/Projektil-Tempo hoch, kein Vorwarnen | Werte gesenkt (Feuerrate, Schaden, Projektil-Tempo), **Telegraph**: 0,35 s Ladeblitz vor dem Schuss, Treffer nur mit Sichtlinie |
| 7 | **Mütze/Kappe verdecken das Gesicht** | Hüte werden über die ganze Kopf-/Gesichtsfläche gezeichnet | Hut neu gezeichnet: sitzt **auf** dem Kopf, Gesicht + Augen bleiben sichtbar; alle 5 Hüte überarbeitet |
| 8 | **Aimen ist schwer** | Blickrichtung = reine Laufrichtung, kein Zielen | **Zielhilfe** AUS/SCHWACH/STARK (rastet auf das nächste Monster im Kegel ein) + **Maus-Zielen** am PC, sichtbare Ziel-Linie |
| 9 | **Wellen-Anzeige buggy** | `show_shop()` hängt jedes Mal einen weiteren Button an `shop_continue_row` (wird nie geleert) → Button-Stapel (roter Kreis im Screenshot) | Zeile vor dem Aufbau leeren; Wellen-Label zeigt zusätzlich Monster-Rest + Shop-Countdown in einer Zeile |
| 10 | **HUD off screen** (Splash-Texte, Boss-Leiste) | `hud = Control.new()` hat **keinen Anker** → Größe 0,0; `PRESET_CENTER_TOP`/`anchor 0.5` beziehen sich auf Breite 0 → Banner und Boss-Leiste liegen **halb außerhalb** | `hud.set_anchors_preset(PRESET_FULL_RECT)` + Banner/Boss-Leiste relativ zur echten Viewport-Größe |
| 11 | „wusstest du, dass man **gedrückt halten** kann?" | funktioniert schon (`shoot_held`/LEERTASTE) — ist nur nicht erklärt | Hinweis im Startscreen + Tipp beim ersten Schuss |
| 12 | **Kisten nicht öffnen** (Nicht-Host), **Waffe dreht nicht sichtbar mit**, schießen im Menü | Client hat keine Kisten-Interaktion mit dem Host; Waffe folgt nur der Laufrichtung; keine Schuss-Sperre im Menü | Client sendet „Kiste geöffnet" an den Host (Host vergibt Loot), **Schießen gesperrt** in Shop/Pause/Kisten-Öffnung, Waffe folgt der Zielrichtung auch im Stehen |
| 13 | MP **Nicht-Host**: Animation buggy, **kein Shop nach der Welle** | `_physics_process` bricht beim Client früh ab (`_coop_client_tick` → `return`) → Client führt **die Wellenlogik nie aus** | Host sendet Wellen-/Shop-Events (`h_send_wave_state`), Client baut Shop + Banner daraus auf, Partner-Animation erhält Blickwinkel + Waffenwechsel |

**Reihenfolge der Umsetzung:** UI-Bugs (9, 10, 7) → Gameplay (5, 6, 12) → neue Features (1, 2, 3, 4, 8, 11) → Mehrspieler (13).

**Verifikation (headless):** Shop-Aufbau 3× hintereinander → genau 1 WEITER-Button; HUD-Anker = Vollbild-Rechteck und Banner/Boss-Leiste innerhalb (0..Viewport); Inventar: 3 Waffen aufsammeln → alle 3 bleiben, Wechsel per Taste ändert `current_weapon`; Utility: Trank heilt, Bombe tötet Monster im Radius; Schwierigkeit: HARDCORE hat messbar mehr Monster-HP als LEICHT; Pause: `paused` + Shop-Timer steht; Dschungel: Kollisionsradius an der Basis < halbe Sprite-Höhe; Schützen: Telegraph-Zeit > 0 und Schaden gesenkt.

**Umsetzung — Ergebnis (headless verifiziert):**

```
R15 shop_weiter_buttons=1   (vorher: 1 Button pro Shop-Aufruf -> Stapel)
R15 shop_items=8 ids=[potion, bomb, heal, shield, weapon, maxhp, speed, damage]
R15 hud_groesse=(1920,1920)=viewport   banner_rect=(0,538)(1920x115)   bossbar=(346,259)(1229x26)
     -> vorher: HUD-Control 0x0, Banner/Boss-Leiste lagen halb ausserhalb
R15 huete_augen_sichtbar=true           (alle 5 Hüte, Augen bei y=24 frei)
R15 hp_leicht=2  hp_hardcore=5          (Schwierigkeit skaliert Monster-HP)
R15 inventar=[pistol, shotgun, laser]   aktuell_nach_aufsammeln=shotgun  (KEIN Zwangswechsel)
R15 nach_taste3=laser                   (Wechsel per Taste funktioniert)
R15 trank: 2 -> 4 Herzen   bombe: Monster-HP 3 -> tot   rest_bomben=0
R15 pause_gesetzt=true overlay=true wieder_aktiv=true shopzeit_unveraendert=true
R15 schiessen_im_shop=false  schiessen_normal=true   (Sperre greift)
R15 zielhilfe_ist=-17.6 soll=-17.6      (rastet exakt aufs Monster ein)
R15 telegraph_an=true aus=true          (Vorwarnung vor dem Schuss)
R15 jungle_kollisionen=609 min_radius=6.4 max_radius=44.0   (vorher effektiv ~0.5px -> sc²)
R15 client_kiste_monitoring=true loot_lokal=0   (Nicht-Host darf öffnen, Host vergibt Loot)
```

**Zwei echte Bugs, die dabei auffielen:**
1. **Client-Kisten waren „nur Optik"** — sie wurden mit `monitoring = false` erzeugt, hatten also gar keine Kollision. Genau deshalb konnte der Nicht-Host nie öffnen. Jetzt interaktiv; das Öffnen läuft über den Host, damit beide Seiten denselben Loot bekommen.
2. **`get_aim_degrees()` gab immer 0 zurück** (`sprite.rotation` ist immer 0) — deshalb stand die Waffe des Mitspielers/LAN-Hosts permanent nach rechts und die Animation wirkte kaputt. Liefert jetzt die echte Zielrichtung.

**Nebenbei gefunden:** die Zielhilfe nahm im Headless-Test die Mausposition (0,0) als Zielrichtung → Maus-Zielen ist jetzt auf echte Bewegung (> 8 px) beschränkt und im Headless-Modus komplett aus.

### T — RUNDE 16: Optik-Paket (Wahl-Optionen, Feedback offen)

**Befunde im Code (gemessen, nicht geraten):**

| Problem | Ursache (geprüft) |
|---|---|
| Items/Herzen „verbuggt" | `heart_full`/`heart_empty`/`heart_gold` sind nur **16x16 px** (im HUD und in der Welt hochskaliert), Herz-Form ist eine grobe Kreisformel; Schild/Waffen 40-64 px mit dünnen Konturen |
| Boss „verbuggt", unspektakulär, zu wenig Leben | **eine** Boss-Sorte für alle Biome, Rig nur **56x56 px** (kaum größer als ein normales Monster -> beim Skalieren matschig), **40 HP** (normale Gegner haben 3-22), 3 Angriffe (Fächer/Ansturm/Beschwören), keine Biom-Anpassung |
| Grafikstufe drosselt Gameplay | `_apply_quality()` setzt `monster_spawner.quality_mult = 1.40` bei NIEDRIG (weniger Gegner) und `num_zones = [1,2,3][quality]` -> Grafikstufe ändert Schwierigkeit |
| Jungle „pixelig/überlappend" | Boden wird als **1 Pixel pro Tile** erzeugt und mit **NEAREST** hochskaliert (`map_generator.gd:173/199`) -> hartes Raster; Props sind prozedurale Kreise/Dreiecke (64-128 px) und werden geclustert ohne Mindestabstand gesetzt -> Kronen überlappen unkontrolliert |

**Optionen (Auswahl offen — der Nutzer entscheidet):**

**A) Items + Herzen**
1. *Echte PNGs*: Scribble Dungeons (32 Items @64 px, Outline-Stil passt zum Comic-Look) für Waffe/Schild/Trank + Board Game Icons für Herzen.
2. *Prozedural neu*: 64 px, saubere Formen (Herz mit Glanzkante + Schatten, Schild mit Wölbung, Waffen als Silhouetten).
3. *Mix*: PNGs für Pickups, HUD-Herzen separat handgezeichnet in 24 px (scharf auf kleiner Größe).

**B) Bosse**
1. *Eigener Boss je Biom* (Mars: Meteor-Golem mit Meteoritenwurf/Bodenschlag, Jungle: Robo-Affe-König mit Bananensalve/Rankenarm, Erde: Splitter-König) — gebaut aus dem Monster-Baukasten (356 Teile), 3-4 eigene Angriffe, 2 Phasen, 150-260 HP, skaliert mit der Welle.
2. *Eine Boss-Basis + 3 Biom-Skins* + je 1-2 biom-spezifische Angriffe (deutlich weniger Aufwand).
3. *Boss-Stufen*: Mini-Boss alle 5 Wellen (heutige Größe) + Riesen-Biom-Boss alle 10.
4. Kombination 1+3.

**C) Grafikstufe**
1. Stufe wirkt **nur** auf Optik (Shader, Deko-Dichte, Bodenauflösung, Partikel, Schatten) — Monsterzahl und Zonen bleiben auf jeder Stufe gleich.
2. Wie 1, zusätzlich auf NIEDRIG weniger Partikel-Effekte, aber identische Gegnerzahl.
3. Wie 1, plus separater Regler „Gegnerdichte" unabhängig von der Grafik.

**D) Jungle-Optik**
1. *Echte Props* (Background Elements Remastered bis 240 px) + weicher Boden (8 px pro Tile statt 1) + Platzierungsregeln (Mindestabstand, Kronen dürfen sich nicht schneiden, eigene Kronen-Ebene).
2. *Prozedural in 2x Auflösung* mit mehr Farbtönen/Shading, ohne externe Assets.
3. *Mix*: echte Bäume/Bambus + weicher Boden, Kleindeko bleibt prozedural.
4. Nur Bodenauflösung + Filter fixen, Props unverändert.

**E) Umfang**
1. Nur Jungle + Items + Bosse anfassen.
2. Alle Karten auf echte Assets umstellen (Erde-Bäume/Felsen mit).
3. Jungle als Testlauf umsetzen, Rest nach Freigabe.

**Vergleichsblätter:** `compare/optionen.png` (Items/Herzen/Jungle/Boss-Teile) und `compare/boss_boden.png` (montierte Biom-Bosse + Bodenvergleich IST/weich).

**Entscheidung (vom Nutzer einzutragen):** Items = _ ; Bosse = _ ; Grafikstufe = _ ; Jungle = _ ; Umfang = _

**Entscheidung des Nutzers:** Items = **A1** (echte PNGs) · Bosse = **B4** (B1+B3) · Grafikstufe = **C1** (nur Optik) · Jungle = **D1** (echte Props + weicher Boden + Platzierungsregeln) · Umfang = **E2** (alle Karten auf echte Assets).

**Umsetzung — Ergebnis (headless verifiziert):**

```
R16 items: heart_full (50x40) heart_empty (56x43) heart_gold (50x40) shield (64x64)
           weapon_pistol/revolver (64x64) potion (60x60) bomb (120x112)   -> alles echte PNGs
R16 props: prop_tree_1 (188x408) prop_tree_7 Palme (400x476) prop_bush_1 (240x120) prop_stone_1 (64x56)
R16 boss:  boss_mars/jungle/earth = je 320x320 px
R16 biom_boss mars=19 jungle=20 erde=21
R16 quali=0 gegner=1 zonen=2 quality_mult=1.0
R16 quali=2 gegner=1 zonen=2 quality_mult=1.0     -> Gameplay identisch (vorher gedrosselt)
R16 boden=(720,480) scale=(5.33,5.33) filter_linear=true   (6 px/Tile statt 1 px/Tile + NEAREST)
R16 jungle objekte=72 nahe_paare=0 min_abstand/radius=99  -> keine Kronen-Ueberlappung mehr
R16 boss hp: mini=120  mars=180  jungle=200  erde=230
R16 boss groesse: 106 px (mini) / 134 / 141 / 134 px   (vorher 56 px)
```

**Was konkret umgesetzt wurde**

1. **Items (A1):** `heart_full`/`heart_empty`/`heart_gold` aus *Board Game Icons*, `shield` aus *Scribble Dungeons*, die 5 Waffen als Kitbash aus echten Turm-Rohren (*Topdown Tanks*) + Griff, Trank/Bombe als echte PNGs. Die HUD-Herzen sind TextureRects mit fester Größe -> skalieren automatisch, keine HUD-Änderung nötig.
2. **Bosse (B4):** Drei neue Biome-Bosse (**Meteor-Golem / Robo-Affe-König / Splitter-König**) aus dem *Monster Builder Pack* montiert, je 320 px Rig, 180/200/230 HP (+12 % pro Welle), eigener Angriff je Biom (Fels-Salve / Bananen-Salve / Rundum-Salve), Anlauf mit Vorwarnung, Beschwören **biom-eigener** Diener, **Phase 2 ab 50 % Leben** (schneller, kürzere Pausen). Stufen: **Mini-Boss alle 5 Wellen (120 HP)**, **Riesen-Biom-Boss alle 10 Wellen** mit eigenem Banner.
3. **Grafikstufe (C1):** `monster_spawner.quality_mult` konstant 1.0, `num_zones` fest auf 2 — die Stufe steuert nur noch Shader, Deko-Dichte und Bodenauflösung (3/6/9 px pro Tile).
4. **Jungle + alle Karten (D1/E2):** Boden wird weich hochskaliert (kubisch + LINEAR) statt hartem Pixelraster; Erde und Dschungel nutzen echte Baum-/Palmen-/Busch-/Stein-PNGs mit **Höhenvorgabe** statt fester Skalierung; **Mindestabstand** über die sichtbare Größe verhindert Kronen-Überlappung; Bäume haben einen **Fußpunkt** (`offset`), damit Y-Sortierung und Kollision an der Objektbasis sitzen (Kronen-Ebene).
5. **Scale-Bug gefunden:** `is_boss()` gab es nach meinem Patch doppelt (Parse-Fehler) und `heart_gold` wurde von einer zweiten 16-px-Zuweisung überschrieben — beides behoben.

**Noch offen / bewusst nicht gemacht:** `powerup_freeze`/`powerup_rapid` bleiben gezeichnet (in der Bibliothek gab es keine passenden Icons), und die Feinskalierung der neuen Props (Größe/Dichte im Dschungel) ist Erfahrungssache — Rückmeldung nach dem Test einplanen.

### U — RUNDE 17: Korrektur nach Test (Comic-Look zurück)

**Feedback:** Waffen sehen „aus wie eine Tür" · Jungle-Bäume passen nicht zum Comic-Look · Herzen sollen wieder rot sein · Level-Up-Karten „immer noch unschön/verbuggt".

**Ursachen (gemessen):**
1. **Herzen waren weiß** — die *Board Game Icons* sind ein **weiß/graustufiges** Icon-Set (Hauptfarbe 240,240,240). Deshalb sahen Herz, Trank und Schild farblos aus; mein „Gold-Tint" griff ins Leere, weil er rote Flächen erwartete.
2. **Level-Up-Karten hatten immer schon schlechte Icons** — `UPGRADE_ICONS` zeigte auf `"projectile"`, `"weapon_machine"`, `"powerup_rapid"` usw. (kleine, teils unpassende Texturen in einem 104-px-Slot).
3. **Waffen-Kitbash** aus Turm-Rohren wirkte wie eine Tür.
4. **Jungle-Props** aus *Background Elements* sind ein flacher Vektor-Stil, der neben den gezeichneten Comic-Figuren fremd wirkt.

**Änderungen:**
- **Waffen:** zurück auf die prozeduralen Comic-Waffen (kein Kitbash mehr).
- **Herzen/Trank/Schild:** bleiben echte PNGs, aber **korrekt eingefärbt** (Herz kräftig rot 0,97/0,16/0,23, Extra-Herz Gold, Schild stahlblau, Trank rot, Bombe dunkel). Die Quelle war weiß.
- **Upgrade-Karten:** eigenes Icon-Set in 128 px, gezeichnet im Comic-Stil (Fadenkreuz = Schaden, Pfeile = Nachladen, Chevron = Tempo, Herz = Leben, Schild = Panzer, Tropfen = Vampir) und `UPGRADE_ICONS` darauf umgebogen.
- **Jungle + Erde:** zurück auf die gezeichneten Comic-Props (`jungle_tree`, `bamboo`, `fern`, `bush`, `tree`, `rock`), **aber** mit allen neuen Regeln: Mindestabstand (keine Kronen-Überlappung), Fuß-Punkt für Sortierung/Kollision an der Objektbasis, weicher Boden (6 px/Tile, LINEAR).
- Mars behält die echten rostorange Felsen (die waren ausdrücklich gewünscht).

**Ergebnis (headless verifiziert):**
```
R17 weapon_pistol/revolver = (64, 40)       -> wieder prozeduraler Comic-Look
R17 heart_full herz_farbe = (0.97, 0.16, 0.23) rot=true
R17 shield = (64, 64) | upg_power/upg_vampire = (128, 128)
R17 karten_icons_fehlen = []                 -> alle 6 Karten haben ein Icon
R17 jungle_arten = { jungle_tree: 66, bamboo: 86, fern: 92, bush: 32 }  objekte=280
R17 min_kollision = 6.4 | boden = 720x480 weich = true
```

**Hinweis:** Die echten Prop-Dateien (`assets/props/*`) bleiben im Projekt, werden aber von Erde/Jungle nicht mehr verwendet — so ist der Wechsel später eine Zeile in der Terrain-Tabelle.

### V — RUNDE 18: Dschungel nach Nutzer-Referenzbildern + erkennbarer Affe

**Feedback:** Jungle-Map „immer noch nicht schön" · Inspiration aus den hochgeladenen Bildern (magischer Wald / Jungle-Tileset), aber **nicht so eng**, damit man kämpfen kann · Affe soll als **echter Affe** erkennbar sein.

**Aus den Referenzbildern abgeleitet (per Bildanalyse):**
runde „Wolken"-Kronen · **3-4 Grüntöne pro Krone** (dunkel #2d4c1e → mittel → hell #8bc34a) mit **dunkler Kontur** · zusätzlich Palmen mit dunkelrotem Stamm, **Trauerweiden mit hängenden Strängen**, ein **Urbaum mit Kristall und Gesicht in den Wurzeln** · Grund: Gras in mehreren Tönen + **Erd-Flecken/Wege** + Moos + Wasser · Deko: **rote Fliegenpilze**, braune Pilze, **blaue Kristalle**, Schilf/Kolben, Moossteine, weiße Blüten, Feuerfliegen.

**Umgesetzt (alles prozedural im Comic-Stil, mit Kontur):**
| Neu | Beschreibung |
|---|---|
| `jtree_round`, `jtree_tall` | runde Wolkenkronen mit 3 Grüntönen + Highlight oben-links |
| `jtree_willow` | Trauerweide mit 9 hängenden Strängen |
| `jtree_ancient` | Urbaum: krummer Stamm, Wurzeln, **Gesicht**, **blauer Kristall** |
| `jpalm` | Palme mit dunkelrotem geringeltem Stamm + Kokosnüssen |
| `jbush_leaf` | Busch mit großen Blättern |
| `jvine` | hängende Ranken (**ohne Kollision**) |
| `jmushroom_red` / `_brown` | Fliegenpilz mit weißen Punkten / brauner Pilz |
| `jcrystal` | blauer Kristall-Cluster |
| `jreed`, `jrock`, `jflower` | Schilf mit Kolben, Moosstein, weiße Blüte |
| **`monster_robo_ape`** | **neu gezeichnet**: Gorilla-Silhouette (breite Schultern, lange Arme im Knöchelgang, Schnauze, Ohren, kurze Beine), Metall-Brustplatte mit Leuchtkern, Robo-Auge + Antenne, **Banane in der Hand** |

**Boden:** Gras in **drei Tönen** + **Erdwege** (grobe Rausch-Blöcke > 0,78) + **Moos** (dunkle Bereiche) — wird weich hochskaliert, dadurch organische Flecken statt Raster.

**Dichte bewusst moderat** (Nutzerwunsch „nicht so eng"): 18 Kronen-Baum-Cluster, 12 hohe, 10 Palmen, 7 Weiden, 3 Urbäume (selten), 16 Bambus-Cluster, plus Deko — gemessen **488 Objekte mit 15 verschiedenen Arten**, Mindestabstand weiterhin aktiv.

**Verifikation:**
```
R18 jungle_arten = { jtree_round: 41, jtree_tall: 22, jpalm: 15, jtree_willow: 10, jtree_ancient: 5,
                     bamboo: 54, jbush_leaf: 52, fern: 44, jvine: 13, jmushroom_red: 55,
                     jmushroom_brown: 68, jcrystal: 8, jreed: 28, jrock: 25, jflower: 44 }
R18 objekte = 488 | boden = 720x480 weich = true | monster_robo_ape = 80x80
Bildprüfung: alle Objekte vollständig (nichts abgeschnitten), Affe klar als Gorilla erkennbar,
             Boden zeigt 3 Grüntöne + Erdwege + Moos
```

**Gefundene Stolpersteine:** `_make_robo_ape()` existierte bereits (Namensdublette → Parse-Fehler) und die `textures[...]`-Zuweisungen des neuen Sets rutschten zunächst durch den Anker — beides behoben.

### W — RUNDE 19: Flüsse mit Brücken, Deko-Ebene, Klärung „roter Bereich"

**1) „Was ist dieser rote Bereich?"** — Das ist der **Feuer-Knopf** unten rechts (roter Ring mit weißem Innenring und gelbem Kern), das Touch-Bedienelement zum Schießen. Kein Bug. Falls die **roten Fliegenpilze** gemeint waren: die sind reine Deko (im Referenzbild vorhanden) — sie sahen nur wie Gegner aus, deshalb von 12 auf **5 Cluster** reduziert.

**2) Gräser überlappten Bambus (Bug, bestätigt):** Die Boden-Deko (Grasbüschel/Blätter/Blüten) läuft als MultiMesh-Ebene und hatte `z_index = 0` — sie wurde also **über** den Objekten gezeichnet. Jetzt `z_index = -2` auf allen drei Deko-Ebenen → Deko liegt sauber **unter** Bambus, Büschen und Bäumen. Verifiziert: `deko_z_index = [-2, -2, -2]`.

**3) Flüsse + Brücken + Ufersteine (Nutzerwunsch, wie im Referenzbild):**
- `_carve_river()` erzeugt einen mäandernden Fluss (Achse zufällig Nord-Süd/West-Ost, Sinus-Wobble, ~5-6 Tiles breit) und **entfernt die Wasser-Tiles aus den begehbaren Positionen** → keine Spawns und keine Monster im Wasser.
- **1-2 Brücken** im mittleren Drittel: dort wird das Deck freigestochen (Wasser-Tiles entfernt) → **nur über die Brücken ist der Fluss überquerbar**.
- Kollision: pro Wasserzeile ein `StaticBody2D` (Layer 16), Brückenzeilen bleiben offen → **94 Wandkörper** bei 658-749 Wasser-Tiles.
- Optik: Wasser wird mit Tiefen-/Uferfarben direkt ins Bodenbild geschrieben (weiche Ufer durch die kubische Skalierung) + neue **Holzbrücken-Textur** (Planken, Geländer, Pfosten) als kachelbare Sprites.
- **Ufersteine:** entlang der Wasser-Kanten werden Felsbrocken (echte Stein-PNGs + `jrock`) mit Kollision gesetzt.
- Fluss gibt es auf **Erde und Dschungel** (`"river": true`), **nicht auf dem Mars** (Flag fehlt → früher Ausstieg).

**Verifikation:**
```
FLUSS achse=2 tiles=749 bruecken=1
R19 earth  wasser_tiles=658 bruecken=1 wasser_koerper=94 begehbare=8942 (von 9600)
           mitte_im_wasser=false
R19 jungle wie Erde | R19 deko_z_index=[-2,-2,-2]
CLEAN_OK  (alle Testhaken entfernt, 0 Parse-Fehler)
```

**Hinweis:** Die Kartenmitte liegt garantiert nicht im Wasser (Fluss bei 28 % oder 72 % der Breite) und der Spieler startet auf dem Festland.

### X — RUNDE 26: Karten sauber, Auto-Aim-Fix, Boss-Redesign

**Nutzer-Feedback + im Code gefundene Ursachen:**

| # | Punkt | Ursache (geprüft) | Lösung |
|---|---|---|---|
| 1 | **Erde sieht „dreckig" aus** (dunkelgrüne Bambus/Gräser) | Die Erde hat `plants: true` → die Deko-Ebene „Blades" zeichnet dunkelgrüne Grasbüschel über die ganze Karte (seit Runde 25 in dunklem Grün) | Erde: `plants: false` (keine Grasbüschel mehr) · dafür **mehr Blumen** (`h2 % 23` → `h2 % 9`) und **3 Blütenfarben** (Gelb/Orange/Pink) + 6 Cluster der großen `jflower`-Blüte als Farbtupfer |
| 2 | **Jungle-Grüntöne „abgehakt"**, wirkt dreckig | Der Boden nutzt 3 stark unterschiedliche Töne (hell 0.32/0.64/0.26 ↔ Moos 0.09/0.25/0.13) plus dunkle Grasbüschel | Boden-Palette **enger** (helle/dunkle Abweichung ~halbiert), Moos-Anteil reduziert, Jungle `plants: false` (keine dunklen Büschel mehr) |
| 3 | **Auto-Aim zielt immer nach rechts unten**, auch ohne Ziel; mit AUS dasselbe beim Stehenbleiben | `_solve_aim()` übernimmt die **Mausposition**, wenn sie sich > 8 px bewegt — auf dem Gerät liegt der Cursor/Finger unten rechts (Feuerknopf) → Ziel zeigt dorthin | **Maus-Zielen komplett entfernt** (Touch-Spiel). Default ist jetzt strikt die **zuletzt gelaufene Richtung** (`facing_direction` bleibt stehen, wenn kein Input und kein Ziel) |
| 4a | **Jungle-Boss sieht schlecht aus**, Bar verschwindet nie, Boss bekommt kein Leben | Bar: `update_boss_hp(40, 40)` ist **hart auf 40** codiert und wird beim Boss-Tod nicht versteckt. HP: `start_hp` wurde vor der Wellen-Skalierung gesetzt | Echte HP an die Bar (kein 40), Bar **wird beim Boss-Tod/Ende versteckt**, `start_hp` **nach** der Skalierung, HP-Faktor von 0,12 auf **0,18** pro Welle |
| 4b | **Design-Katastrophe** | Die Boss-Rigs waren aus Fremd-Assets zusammengeklebt (Monster-Builder-Teile) | Neu gezeichnet: **Jungle = mutierter Halb-Roboter-Gorilla** (Gorilla-Körper wie der Bananen-Affe, eine Roboter-Schulter + Kralle, rotes Robo-Auge, Kabel, Banane) · **Mars = mutierter Alien-Roboter** (Alien-Schädel mit großen Augen auf einem Maschinenkörper mit Leuchkern, Greifarmen, Antennen) |

**Verifikationsplan (mehrfach, vor Abgabe):**
1. Texturen dumpen und auf Gras-Hintergrund ansehen (Bosse, Blumen)
2. Live-Screenshot Erde + Jungle mit Kamera auf Objekte/Boss
3. Zahlenprüfung: Boss-HP bei Welle 1 vs. 10, Bar-Sichtbarkeit nach Boss-Tod, Zielwinkel im Stand (= letzte Laufrichtung, nicht fest)

### Y — RUNDE 33: MP-Variante B (eigener Shop je Spieler) + Level-Gate + Pro-Map-Kurven + Performance

**Ausgangslage (Audit vom 25.10., vor der Umsetzung erstellt und abgenommen):**
1. *MP-Shop friert die anderen Spieler ein* — `ui_manager.show_shop()` setzte `get_tree().paused = true`
   (global, auch im Duo-Modus) und der Shop-Zustand wurde an den Client gesynct
   (`_on_net_wave_state` → `show_shop(coins)`), d.h. der Client öffnete den **Shop des Hosts
   mit den Münzen des Hosts** und pausierte selbst. Zusätzlich konnte der Client mit den
   Host-Münzen einkaufen (`buy_shop_item` zog die lokalen Münzen ab).
2. *Performance Nicht-Host schlecht* — `refresh_weapon_hud()` baute **alle** Waffen-Buttons bei
   jedem Aufruf neu auf (clear + `queue_free` + neue Buttons) und wurde im Sync-Pfad
   **15×/s pro Spieler** aufgerufen → massenhaftes Node-Churn. Dazu `get_nodes_in_group("monsters")`
   (baumweite Suche) pro Mob-Snapshot (7,7 Hz) und ein Pfeil-Update pro Frame.

**Umsetzung Variante B (eigener Shop pro Spieler):**

| Bereich | Datei | Umsetzung |
|---|---|---|
| Münzen pro Slot | `game_manager.gd` | `slot_coins: Dictionary` (Slot→Münzen); jeder Kill wird dem **Schützen** gutgeschrieben |
| Kill-Zuordnung | `projectile.gd`, `player_controller.gd`, `monster_ai.gd` | Projektil trägt `owner_slot`; `take_damage(amount, owner_slot)` merkt `last_hit_slot`; `monster_killed(points, slot)` |
| Kaufen | `game_manager.gd` | `buy_shop_item()` → Client schickt `coop_shop_buy` an den Host; Host prüft **dessen** Münzen und wendet den Kauf auf **diesen** Spieler an (`_apply_shop_purchase(id, slot)`) |
| Shop-Phase | `net_manager.gd` | Neu: `coop_shop_state` (Münzen pro Slot, Ready-Flags, Level/XP), `coop_shop_buy`, `coop_shop_ready` |
| Shop öffnet | `game_manager.gd` | Erst wenn **beide** Spieler 2 Level aufgestiegen sind (siehe Level-Gate) |
| Nächste Welle | `game_manager.gd` | `_next_wave(force)`: Host startet erst, wenn **alle** belegten Slots `shop_ready` haben; der 30-s-Timer erzwingt die Welle |
| Pause | `ui_manager.gd` | Pause bleibt nur im Singleplayer; im MP steuert jeder Spieler seinen eigenen Shop |

**Level-Gate:** `WAVE_LEVEL_UPS := 2` — pro Welle müssen **beide** Spieler 2 Level aufsteigen.
Ist das Ziel nicht erreicht, spawnt `_spawn_reinforcement()` Nachschub-Monster (35 % der
Wellengröße, 2-s-Takt) und die Welle läuft weiter → der Shop öffnet erst am Level-Ziel.

**Pro-Map-Kurven** (`game_manager.gd`):

| Map | XP-Faktor | XP Level 2 | XP-Wachstum | Shoppreise (Heiltrank / Schaden) |
|---|---|---|---|---|
| Erde | ×1,0 | 25 | +12 | 12 / 40 |
| Mars | ×1,7 | 43 | +20 | 17 / 58 |
| Jungle | ×2,1 | 53 | +25 | 20 / 68 |

Begründung: Mars/Jungel-Mobs geben mehr Punkte → mehr Gold **und** mehr XP. Der XP-Bedarf
steigt deshalb, die Preise steigen mit (die Karten bleiben lohnend, aber der Shop ist nicht
trivial). `shop_price()` wird beim Anzeigen **und** beim Kauf benutzt → Anzeige und Abbuchung
sind garantiert identisch.

**Performance-Fixes:**
- `refresh_weapon_hud()` baut nur noch neu, wenn sich Waffenliste/aktive Waffe ändern
  (Signatur-Vergleich) → aus 15 Aufrufen/s pro Spieler wird 1 echter Neuaufbau.
- Eigene `_monster_cache`-Liste statt `get_nodes_in_group("monsters")` pro Snapshot.
- Zielpfeil-Update von 60 Hz auf 5 Hz gedrosselt.
- `_alive_real_monsters()` ist toter Code (kein Aufruf) → bestätigt unkritisch.

**Test-Evidenz (Headless, `COMIC_V33`):**
```
V33 MAP earth:  xp_level2=25 xp_waechst=12 preis_heiltrank=12 preis_schaden=40
V33 MAP mars:   xp_level2=43 xp_waechst=20 preis_heiltrank=17 preis_schaden=58
V33 MAP jungle: xp_level2=53 xp_waechst=25 preis_heiltrank=20 preis_schaden=68
V33 MUENZEN: slot1=57 slot2=57   (getrennt je Spieler)
V33 KAUF slot2: vorher=100 nachher=85  slot1=57  (nur der Käufer verliert Münzen)
V33 GATE (0 Aufstiege): shop_offen=false  reinforcement_monster=5  (Welle läuft weiter)
V33 GATE (2 Aufstiege): shop_offen=true
V33 READY-GATE: alle_ready=false (Slot 2 nicht fertig) → true (beide fertig)
V33 PERF Waffen-HUD: gleiche_instance=true (kein Neuaufbau) / bei Änderung neu gebaut=true
```

**Offen / nicht am Gerät prüfbar:** der echte Zwei-Geräte-Test (Host + Client) der Variante B —
es steht kein zweites Gerät zur Verfügung. Die Logik ist headless getestet (Coins-Trennung,
Ready-Gate, Kauf-Zuordnung), der Netz-Transport folgt dem bestehenden RPC-Muster
(`coop_wave_state`, `coop_input`).

### Z — RUNDE 34: Shop als Entscheidung, Balance-Tabelle, MP-Ausbau, Performance-Hardening, Erde-Boss

**Punkt 1 — Level-Ziel sichtbar:** Das Wellen-Label zeigt jetzt `WELLE 2 · 6 Monster uebrig · LEVEL 4 → 6`
(aktuelles Level → Ziel-Level, Ziel = `wave_start_level + WAVE_LEVEL_UPS`).

**Punkt 2 — Shop als echte Entscheidung**
| Element | Umsetzung |
|---|---|
| Kauf-Limit | `SHOP_BUY_LIMIT := 3` Käufe pro Shop-Phase (`shop_purchases_left`, im Shop-Text „KÄUFE: 2 / 3") |
| Auswahl-Angebote | `_build_shop_offers()` wählt pro Phase **5 von 8** Items (gewichtet) + **1 Rare-Item** |
| Rare-Items | `SHOP_RARE_ITEMS`: GROSSE HEILUNG, PANZER +3, MAX-HERZ +2, 3 BOMBEN, SCHADEN +35 % (goldener Rahmen im Shop) |
| Wellenpreise | `shop_price()` = Basis × Map-Faktor × (1 + 0,05 × (Welle−1)) — Anzeige **und** Abbuchung nutzen dieselbe Funktion |

**Punkt 3 — Map-spezifische Angebote:** Gewichtung im Angebot: Jungle bevorzugt `heal`/`maxhp` (2,2×),
Mars bevorzugt `shield`/`potion` (2,2×), Erde neutral. Gemessen: von je 40 Angeboten wählte
Jungle **73** Heilungs-Angebote, Erde **58**, Mars **43**.

**Punkt 4 — Balance-Tabelle** (`WAVE_BALANCE`) ersetzt die Formeln (`5 + wave*3`, `+12 XP`, Boss-HP-Faktor):
`upto/count/hp/spd` je Wellenbereich, darüber hinaus Wachstum (count +6 %/Welle, hp +9 %/Welle, spd +1,5 %/Welle, Deckel 1,45).
`apply_wave_mult()` im Monster setzt HP/Speed. Gemessen:
Welle 1 → 5 Monster/HP 1,00 · Welle 5 → 7/1,18 · Welle 12 → 14/1,72 · Welle 25 → 20/2,55 · Welle 35 → 26/3,70.

**Punkt 5 — MP-Ausbau**
| Feature | Umsetzung |
|---|---|
| Downed + Aufwecken | Im Mehrspieler beendet ein Tod **nicht** mehr den Run: der Spieler liegt 30 s am Boden (`downed`), der Partner muss 2,5 s neben ihm stehen (`REVIVE_TIME`) → Aufwecken mit 60 % Leben. Läuft die Zeit ab → Game Over (`_game_over_multiplayer`) |
| Sync | Der Spieler-Sync hat jetzt 8 Werte pro Slot (neu: Downed-Flag) |
| Ping | Neuer RPC `coop_ping` + HUD-Knopf **PING** (nur im Mehrspieler sichtbar) → pulsierende Markierung beim Partner |
| Host-Migration | `multiplayer.server_disconnected` → der verbleibende Peer wird Host (`coop_host = true`), Monster werden geräumt und die Welle neu gestartet (Banner „DER HOST IST WEG – DU BIST JETZT HOST") |

**Punkt 6 — Performance-Hardening**
| Maßnahme | Wirkung |
|---|---|
| Client-Geister = einfaches `Sprite2D` | vorher komplette Monster-Szene (CollisionShape + Warn-Sprite + KI-Skript) pro Geist → jetzt 1 Sprite mit sanftem Nachziehen (0,4) und Treffer-Blitz |
| `refresh_weapon_hud()` nur bei Änderung | (aus Runde 33) verhindert 15 Neuaufbauten/s pro Spieler |
| `_monster_cache` statt `get_nodes_in_group()` | keine baumweite Suche pro Snapshot |
| Snapshot-Frequenz 0,13 s → 0,10 s | 7,7 → 10 Hz (flüssigere Monsterbewegung) |
| Platzierungs-Raster (220 px) | Map-Erzeugung: O(n²) → O(n) (350 Objekte, ~60k → ~2k Vergleiche) |
| Pfeil-Update 60 Hz → 5 Hz | weniger Arbeit pro Frame |

**Punkt 7 — Erde-Riesenboss neu:** `_make_boss_earth()` = **mutierter Kristall-Roboter** (Steinpanzer,
leuchtender Kristallkern in der Brust, Kristallklinge, Schulterkristalle, Kristallkrone, glühende Augen),
320×320, ersetzt das Fremd-Asset.

**Test-Evidenz (Headless, `COMIC_V34`):**
```
V34 BALANCE welle 1/5/12/25/35: 5/7/14/20/26 Monster, HP 1.00/1.18/1.72/2.55/3.70
V34 MAP: 401 Objekte
V34 SHOP angebote=6 rare=1  preis@w5(jungle)=31  (15 × 1,7 × 1,2)
V34 SHOP kauf-limit: uebrig=0 nach 5 Klicks (3 erlaubt)
V34 SHOP bias: heilung_gewahlt jungle 73 / erde 58 / mars 43
V34 DOWNED: aufgeweckt=true hp=4
V34 PING: marker_neu=1
V34 BOSS erde: textur_ok=(320, 320)
```

**Bekannte Schwäche (für die nächste Runde):** Die Map-Erzeugung braucht ~1,9 s (der Boden wird
pixelweise erzeugt) → spürbarer Ladehitch auf dem Handy. Der Raster-Fix beschleunigt nur die
Objekt-Platzierung, nicht das Bodenbild.

**Runde 34b — Korrekturen nach der Sichtprüfung (Screenshots):**
- Shop-Layout: der Scroll-Container war als **erstes** Kind der Box eingefügt → die Items standen
  **über** der SHOP-Überschrift. Korrigiert: der Scroll kommt jetzt zwischen Wellen-Text und
  WEITER-Button, die Item-Liste hängt in einem HBox-Wrapper (mittig zentriert).
- Erde-Boss verfeinert: leuchtende Kristallrisse im Stein, Halo um den Kern, Nieten auf den
  Armen, größere Kristallkrone.

### AA — RUNDE 35: ELEKTRO-WELT (neuer Planet) + VORSCHLÄGE AUS RUNDE 34
### AB — RUNDE 36: SHOP- & LOOTBOX-ÜBERARBEITUNG (Plan + Teil-Implementierung)

**Runde 35 — Elektro-Welt (4. Planet, „volt")**
| Bereich | Umsetzung |
|---|---|
| Boden | `voltgrid`: dunkles Stahlblau mit dezenten Plattenfugen (jeder 11. Kachel) und **einzelnen** gelben Energieleitungen (jeder 67.) — die erste Version hatte dicke Diagonalbänder (sah aus wie ein Strichcode) → korrigiert nach Sichtprüfung |
| Biome-Tabelle | `BIOMES["volt"]` ergänzt — **wichtig**: `set_biome()` lehnt unbekannte Biome ab, ohne den Eintrag blieb der Map-Generator auf „earth" (die Karte sah aus wie die Erde, obwohl die Objekte die Volt-Welt waren) |
| Objekte | Teslaspule, Antennenmast, Energieblock, Kabeltrommel, Schrottroboter (5 Arten, 17/13/28/22/20 Cluster) |
| Monster | VOLT_DRONE (Schwebedrohne), VOLT_TROOPER (Spulentrooper), VOLT_SPIDER (Spinnenspule) — eigene Typen 25–27, im Enum + Statistiken |
| Boss | **DER STURMLEITER** (`BOSS_VOLT`, 260 HP): Riesenroboter mit gewaltiger Teslaspule, Blitzkern, Lichtbogen zwischen den Armen |
| Freischaltung | 20.000 Gold + 5.000 XP + „jungle" als Voraussetzung, Icon `map_volt` (Blitz im Kreis) |
| Balance | `_map_type_weights()`: eigene Gegner-Verteilung pro Karte (Mars = mehr Schützen, Jungle = mehr Pflanzen, Elektro = mehr Technik) |

**Vorschläge aus Runde 34 (umgesetzt):**
1. **Map-Ladezeit** — Bodenbilder werden jetzt gecacht (`_ground_cache`, Schlüssel Biome|Jahreszeit|Detailstufe): **1.632 ms → 128 ms** beim zweiten Laden (≈ 12×) ✓
2. **Balance pro Karte** — `_map_type_weights()` ✓ (s. o.)
3. **Downed-Optik** — der gefallene Mitspieler bekommt einen sichtbaren **HILFE-Ring**, dessen Größe/Farbe den Aufweck-Fortschritt zeigt (rot → grün) ✓
4. **Rare-Items** — von 5 auf **11** erweitert (TEMPO +20 %, SCHNELLFEUER 12 s, GOLD +60, FROST 10 s, COMBO +1 …) ✓
5. **Host-Migration** — der neue Host startet die Welle **nicht** neu (Wellennummer bleibt), er füllt sie nur neu auf (`_spawn_wave_monsters()`) ✓
6. **LAN-Test** — ersetzt durch einen **Simulations-Test** (Host+Client-Logik in einem Prozess, siehe Test-Evidenz); ein echter Zwei-Geräte-Test bleibt für dich offen

**Runde 36 — Shop & Lootbox (Plan)**
*Ziel:* Der Shop soll eine Entscheidung sein, die Lootboxen sollen sich lohnen und die Sammlung soll übersichtlich sein.

| Baustein | Inhalt | Status |
|---|---|---|
| **A. Shop-Grid** | 2 Spalten, große Icons, Hover-Tooltip mit vollem Effekt, gekaufte Angebote als **„verpasst"** (abgedunkelt, nicht mehr klickbar) | **umgesetzt** ✓ |
| **B. Karten-Vielfalt** | 5 Kisten-Tiers (Holz 60 / Silber 150 / Gold 320 / **Platin 640** / **Sturm 1.200** Gold) | **umgesetzt** ✓ |
| **C. Pity-Regel** | Nach 10 Kisten **ohne** Rare ist mindestens Rare garantiert (`chests_since_rare`, `get_chests_since_rare()`) | **umgesetzt** ✓ |
| **D. Kisten-Vorschau** | Im Menü je Kiste anzeigen: mögliche Items + Wahrscheinlichkeit + „x bis Pity" | **geplant** |
| **E. Sammlungs-Screen** | Neuer Menü-Tab **SAMMLUNG**: Grid aller Cosmetics (Farben/Hüte), Fortschritt „12/24 gesammelt", Vorschau beim Antippen, Equip-Knopf | **geplant** |
| **F. Mehr Cosmetics** | 12 Farben, 8 Hüte, neue Kategorien (Umhänge, Flügel, Emotes) + ein Editor-Screen mit Live-Vorschau | **geplant** |
| **G. Seltenheits-Look** | Einheitliche Seltenheitsfarben (grau/blau/lila/gold) für Karten, Items und Kisten-Öffnungs-Animation | **geplant** |
| **H. Kisten-Opening** | Aufklapp-Animation mit Funken + Rarity-Einblendung statt Text-Popup | **geplant** |

### AC — RUNDE 37: COSMETICS, SAMMLUNG-SCREEN, KISTEN-PITY, SELTENHEITSFARBEN

**1. Mehr Cosmetics**
| Bereich | Umsetzung |
|---|---|
| Farben | 6 → **10** (ORANGE, CYAN, ROSA, STAHL neu) in `PLAYER_COLORS` + `COLOR_NAMES`; `set_profile_color()`-Cap 5 → 9 |
| Hüte | 6 (OHNE, KAPPE, COWBOY, KRONE, ZYLINDER, MUETZE) — Bestand unverändert, alle jetzt in der Sammlung sichtbar |
| Freischaltung | unverändert über Kisten (`color` / `hat_low` / `hat_high`) |

**2. SAMMLUNG-Screen** (neuer Menüpunkt neben „KARTEN")
| Element | Umsetzung |
|---|---|
| Grid | 5 Spalten, 16 Kacheln (10 Farben + 6 Hüte) mit dem echten Spieler-Icon (`player_c%d_h%d`) |
| Gesperrt | abgedunkelt (Modulate 0,35) + Tooltip „(gesperrt - in Kisten)" |
| Aktiv | heller + Tooltip „(AKTIV)" |
| Fortschritt | „FARBEN 6 / 10      HUETE 6 / 6" |
| Equip | Tippen auf einen eigenen Gegenstand setzt ihn sofort (`set_profile_color` / `set_profile_hat`) + `_apply_profile()` + `_save_profile()` |
| Seitenlogik | `collection_page` wird in `_close_pages()` mitgeschlossen, eigener „ZURUECK"-Button |

**3. Kisten-Vorschau + Pity im Menü:** Jede Kiste zeigt zusätzlich **„RARE in X Kisten"**
(X = Rest bis zur garantierten Rare, aus `chests_since_rare`).

**4. Einheitliche Seltenheitsfarben:** `game_manager.rarity_color()` → common grau, rare blau,
epic lila, legendary gold. Verwendet in der Kisten-Öffnung (Text **und** Icon).

**Test-Evidenz (Headless, `COMIC_V43`):**
```
V43 farben=10 huete=6
V43 grid=true eintraege=16   (10 Farben + 6 Huete)
V43 fortschritt: FARBEN 6 / 10      HUETE 6 / 6
V42 equip farbe: 3 -> 4            (Equip funktioniert)
```

**Beim Selbst-Testen gefunden:** Der erste Aufbau castete den Box-Container der Seite auf
`PanelContainer` → die Seite blieb leer. Korrigiert: Panel = Kind 1 der Seite, VBox = Kind 0
darin.

### AD — RUNDE 38: STARTSEITE, CHARACTER-RIGS, KISTEN-LOOT, SAISONEN, KRAFTFELD

| Punkt | Umsetzung |
|---|---|
| **Startseite schicker** | Hero-Vorschau des Helden (190 px) + Statistikzeile („BESTER SCORE … GOLD …") über dem SPIELEN-Knopf |
| **Neue Character-Rigs** | 4 Rigs als Helden-Overlay: OHNE, **PANZERHELD** (Schulterpanzer + Helm mit Leuchten), **NINJA** (Maske + Schal), **ROBOTER** (Metallkopf + leuchtender Brustkern). Freischaltbar, ausrüstbar, eigene Zeile in der SAMMLUNG, neuer Kisten-Inhalt `rig` |
| **Kisten liefern Cosmetics** | Gold 5 % → 2–5 %, Kopfgeld nur noch in der Holzkiste, dafür **Rigs** (Silber 12 %, Gold 20 %, Platin 25 %, Sturm 35 %) + mehr Farben/Hüte |
| **Flashy-Kisten-Animation** | Seltenheits-Overglow (Hintergrund-Puls in der Raritäts-Farbe: grau/blau/lila/gold) + Einfärben von Text **und** Icon, zusätzlich zum vorhandenen Wackel-/Deckel-/Bounce-Ablauf |
| **Kisten-Layout** | je Kiste jetzt zusätzlich „RARE in X Kisten" (Rest bis zur garantierten Rare) + die möglichen Inhalte, alles zentriert |
| **Saisonwechsel zu früh** | Im **Wellen-Modus** wechselt die Jahreszeit jetzt nach **4/8/12 Wellen** (vorher nach Score → durch die vielen XP mitten im Run), im Endlos-Modus erst bei 2.500 / 7.000 / 14.000 Score |
| **Wanderndes Kraftfeld** | Ab Welle 7 (alle 3 Wellen + jede 5er/10er-Welle) erscheint ein Kraftfeld, das über die Karte wandert (34 px/s, prallt an den Rändern ab) und den Spieler **auf 65 % Tempo bremst** — dadurch werden die späteren Runden spürbar schwerer. Banner „KRAFTFELD AKTIV" |
| **Volt-Jahreszeiten** | 4 kreative: **STURM** (kühl-blau), **ÜBERLAST** (glühend rot), **BLACKOUT** (dunkel), **NEBEL** (milchig) — eigene Bodenfarben, eigene Objekt-Töne, eigene Anzeigenamen |

**Test-Evidenz (Headless, `COMIC_V46`/`V47`):**
```
V46 volt_saisons=4 anzeige=UEBERLAST
V46 kraftfelder=1 gewandert=true
V46 kisten: rigs=4 gold=5
V46 rigs=[0,1,2] aktiv=2  namen=4
V46 sammlung=20 (10 Farben + 6 Huete + 4 Rigs)
V46 fortschritt: FARBEN 10 / 10  HUETE 6 / 6  RIGS 3 / 4
```

**Beim Selbst-Testen gefunden:** (1) Der „rig"-Kisten-Fall landete zuerst in der Pool-Filter-Funktion
(„Cannot return Dictionary because the function returns Array") → jetzt `ok`-Check im Filter und
der eigentliche Fall in der Roll-Funktion. (2) Der erste Saison-Test lief auf der
Jungle-Karte — dort wechseln die Jahreszeiten gar nicht (nur die Erde-Karte ist „progressive"),
der Test prüft jetzt die Erde.

### AE — RUNDE 39: KRAFTFELD-UPGRADE, STARTSEITE, KISTEN-ANIMATION, NEUE HUETE

| Punkt | Umsetzung |
|---|---|
| **Kraftfelder sichtbar** | Neues `force_field`-Asset: Hexagon-Feld (3 Ringe + Eckmarker, cyan) liegt als rotierendes, pulsierendes Overlay auf der Zone |
| **Mehrere Kraftfelder** | Ab Welle 12 kommen **zwei** Felder gleichzeitig, ab Welle 20 bei jeder 3. Welle **drei** |
| **Kraftfeld als Risiko-Belohnung** | Kills **innerhalb** eines Feldes bringen **50 % extra Münzen** (das Feld bremst, lohnt sich aber) |
| **Startseite** | Großes **Karten-Icon** der aktiven Karte + **Hero-Vorschau** + Statistikzeile („BESTER SCORE … GOLD …") über dem SPIELEN-Knopf |
| **Kisten-Animation** | **Deckel fliegt** weg (fliegt nach oben, rotiert, blendet aus), **10 Funken** sprühen radial, bei Rare/Epic/Legendary ein **„RARE!/EPIC!!/LEGENDARY!!!"-Punch** (Skalierung 2,4 → 1,0 mit Back-Ease) |
| **4 neue Hüte** | **PIRAT** (Dreispitz), **STROMP** (mit Bündel), **VIKING** (Eisenhelm mit Hörnern), **STERN** (goldene Krone) → 6 → **10 Hüte** |

**Test-Evidenz:** Kompilierung fehlerfrei (0 Parse-Errors) · Zwei-Instanzen-Test auf einem Rechner
(Host + Client, eigener ENet-Port) gestartet: Host bindet, Client joint ohne Fehler und sendet den
Lobby-Ready; der Empfang von `run_start`/`partner_state` war **in der Headless-Automation nicht
verifizierbar** (ENet-Session im Headless-Modus) → bleibt als Punkt für den echten Zwei-Geräte-Test.

**Beim Umsetzen gefundene und behobene Fehler:**
1. Beim Einfügen der neuen Hut-Fälle wurde der **Rest der `texture_manager.gd` dupliziert** (164 k statt 90 k) → Datei anhand der Duplikatgrenze repariert, alle Funktionen wieder genau einmal vorhanden
2. Der neue Fall klebte ohne Zeilenumbruch an der vorigen Zeile (`…0.99))		6:`) → Parse-Error „Expected end of statement" → Trennzeichen ergänzt
3. `Node.get_child_index()` existiert in Godot 4 nicht → auf `get_index()` umgestellt
4. Der Kraftfeld-Bonus brauchte die **Kill-Position** → `monster_killed` sendet jetzt `global_position` mit
5. `play_btn.get_parent()` war beim Verbinden noch `null` (Button noch nicht im Baum) → Einfügen erst nach `box.add_child(play_btn)`

### AF — RUNDE 40/41: COMIC-LOOK, SKINS, KISTEN-VIELFALT, RUN-UEBERSICHT

**1. Comic-Look der Startseite**
- Hintergrund: Farbverlauf + **rotierender Strahlenburst** + **Ben-Day-Halbtönraster** + schwarze Randbänder
- Neue Bausteine: `_comic_panel_sb()` (dicke schwarze Kontur, eckig, Schlagschatten), `_comic_button_sb()`, `_make_comic_button()`
- Die Seite liegt in einem **Comic-Panel**; Titel mit 14 px Kontur
- Mitte neu als **drei Karten**: Welt-Icon, Held (mit equipptem Skin), Statistik
- Alle Knöpfe (SPIELEN, LAN, CHARAKTER, SHOP, SAMMLUNG, KARTEN, MODUS) als Comic-Buttons

**2. Abgeschnittene untere Felder (Bug des Nutzers)**
- Ursache: feste Pixelhoehe, bei 900 px Fenster lagen Modus/Score/Gold unter dem Rand
- Fix: `_fit_start_content()` **misst** `get_combined_minimum_size()` und skaliert passend; haengt am `size_changed`-Signal
- Messung: Inhalt 1240x835, `passt_vertikal=true`, Nav-Leiste sichtbar

**3. Settings-/Zahnrad-Button (Bug des Nutzers)**
- Gelbes Comic-Feld statt grauem; Icon ueber `alignment`/`vertical_icon_alignment` **echt zentriert** (vorher oben links)
- Icon-Farbe auf Dunkel umgestellt, damit es im gelben Feld sichtbar ist

**4. Kisten-Design**
- `_make_chest_icon()` neu: gewölbter Deckel, Metallbaender, Nieten, Glanzlicht, detailliertes Schloss
- Je Raritaet eine eigene Truhe: `chest_wood/silver/gold/platinum/storm`
- Shop-Karten: Raritaets-Rahmen + farbige Beschriftung, Comic-Kauf-Buttons
- Kisten-Overlay: rotierender Burst, Comic-Panel, „WEITER"-Button, alle Items einzeln gelistet

**5. RIG -> SKIN (Begriffskorrektur des Nutzers)**
- „rig" war ein Overlay; gemeint war ein **Skin des gespielten Charakters**
- Jetzt zeichnet `_make_player_rig()` **komplette Charaktere**: STANDARD, PANZERHELD, NINJA, ROBOTER, COMIC-HELD, MARS-MARSCHALL
- Der Skin **ersetzt** das Spielerbild komplett (`apply_profile`); Label „SKIN"; Sammlung zeigt „SKINS 1/6"

**6. Kisten-Vielfalt (Bug des Nutzers: "die 3 teuren geben immer nur das gleiche")**
- Ursache: die drei teuren Kisten teilten sich denselben Pool; besessene Cosmetics wurden herausgefiltert, es blieb `boost_epic`+`gold`
- Fix: je Kiste ein **eigener thematischer Pool** + Item-Anzahl (Holz 1, Silber 1, Gold 2, Platin 2, Sturm 3)
- Neue Verbrauchsgueter als dauerhafte Alternativen: **TURBO** (+15 % Tempo), **KAMPFKRAFT** (+20 % Schaden), **ZWEITES HERZ**; dazu neues Icon `icon_crosshair`
- `_roll_chest()` liefert jetzt mehrere Items; `_roll_one_chest_item()` rollt einzeln

**7. RUN-UEBERSICHT (Zwischenfenster)**
- Neue Seite zwischen Menue/Lobby und Spiel: Modus, Karte, **alle aktiven Items mit Anzahl**, ausgeruesteter Held
- „ZURUECK" und „LOS GEHT'S!" - erst der Klick startet den Run

**Test-Evidenz (Headless `COMIC_V53`..`V56`, Screenshots in `compare/v53`..`v56`):**
```
V53 gold verschiedene=16 avg_items=2
V53 platinum verschiedene=16 avg_items=2
V53 storm verschiedene=36 avg_items=3
V53 alle_cosmetics_besessen: verschiedene=33
V53 boosts=["shield","heart","bounty","rapid","damage","vitality","speed"]
V54 start ok, confirm versteckt=true / confirm sichtbar=true / zurueck: versteckt=true
V55 mapicon_gesetzt=true mapname=ELEKTRO-WELT  stats=BESTER SCORE | 31326 | GOLD | 50000
V56 label=NEU! SKIN NINJA | TURBO
```

**Beim Testen gefunden und behoben:**
1. `_close_pages()` blendete die neue Run-Uebersicht nicht aus -> sie lag beim Zurueck weiter ueber dem Menue
2. Die Startseiten-Karten waren **leer**, weil ihr Inhalt nur beim Aufbau gesetzt wurde und `game_manager` da noch null war -> jetzt bei jedem Anzeigen befuellt
3. Doppeltes „NEU! NEU!" im Kisten-Overlay -> Prefix wird jetzt entdoppelt
4. Gesperrte Skins waren fast schwarz und damit unsichtbar -> jetzt Silhouette mit sichtbarem Tooltip
5. `sum()` existiert in GDScript nicht; `get_child_index()` -> `get_index()`; `TextureRect.color` -> `ColorRect`; `TextureRect.get_parent()` ist `null` bis `add_child()`

### AG — RUNDE 42: KISTEN-NEUBAU (3 Kisten + Seltenheiten), PIXEL-ART-ICONS, SKIN-FARBEN

**Der gemeldete Shop-Bug (Bild des Nutzers)**
- 5 Kisten liefen rechts aus dem Bild -> jetzt **3 Kisten in einem `GridContainer` (3 Spalten)**
- „RARE in 10 Kisten" stand bei **jeder** Kiste (auch bei der Holzkiste) -> entfernt
- „20 Gold zurueck" stand als **Inhalt** in der Liste -> entfernt
- Der Seltenheits-Mix stand nach dem Umbau **zweimal** (Textzeile + Farbleiste) -> Textzeile entfernt

**1. Kisten auf 3 reduziert + Seltenheits-Konzept**
Jede Kiste hat eine `mix`-Verteilung fuer die KOSMETIK (Farben / Huete / Skins);
Verbrauchsgueter und Gold sind immer „gewoehnlich" und fuellen den Rest auf.

| Kiste | Preis | Items | gewoehnlich | selten | episch |
|---|---|---|---|---|---|
| HOLZKISTE | 60 | 1 | 78 % | 20 % | 2 % |
| SILBERKISTE | 150 | 1 | 40 % | 48 % | 12 % |
| GOLDKISTE | 320 | 2 | 14 % | 46 % | 40 % |

- `COLOR_RARITY` / `HAT_RARITY` / `RIG_RARITY` ordnen jedes Cosmetic einer Stufe zu
  (Farben: 7x gewoehnlich, 3x selten, 1x episch · Huete: 4/4/2 · Skins: 1/2/3)
- `_roll_one_chest_item()` zieht **erst die Seltenheit**, dann ein Cosmetic **dieser
  Stufe** (Reihenfolge Skin -> Hut -> Farbe); passt keins, greift der Verbrauchsgueter-Pool
- Anzeige im Shop: jede Stufe einzeln und in ihrer Farbe (grau / blau / lila)

**2. Pixel-Art-Icons (Wunsch des Nutzers)**
- `_make_map_icon()` und `_make_map_icon_volt()`: 16x16 Pixel, 4x hochskaliert mit
  `INTERPOLATE_NEAREST` -> harte Pixelkanten statt weicher Verlaeufe
- `_make_chest_icon()` komplett neu in Pixel-Art: Korpus, gewölbter Deckel,
  Metallbaender, Schloss, Nieten, Glanzlicht, Pixel-Kontur
- `TextureRect.texture_filter = NEAREST` im Shop

**3. Skins sind farbbar (Zusatzwunsch des Nutzers)**
- `_make_player_rig(idx, shirt, pants)` nimmt die **Spielerfarbe** an
- `get_skin_texture(color, skin)` cached nach `skin_c%d_s%d`
- `player_controller.apply_profile()` nutzt die Skin-Farbe; Startseiten- und
  Sammlungs-Vorschau zeigen den Skin in der gewaehlten Farbe

**Test-Evidenz (Headless `COMIC_V57`..`V60`, Screenshots `compare/v57`..`v60`):**
```
V58 kisten=3
V58 rarities=["common", "rare", "epic"]
V58 skin_x_farbe=60/60
V58 FEHLER=0
V60 icon map_meadow=(64,64) map_volt=(64,64) chest_wood=(64,64) chest_gold=(64,64)
```

**Beim Testen gefunden und behoben:**
1. `Image.resize()` gibt in Godot 4 **void** zurueck (mutiert) -> `small.resize(...)` ohne Rueckgabe
2. Eisberg-Maske lief mit `8 + j` bis **16** -> Out-of-Bounds -> Breite auf 8 begrenzt
3. Ein Zeilenindex-Edit hat den Konstanten-Block (`PLAYER_COLORS`, `HAT_NAMES`...) mit
   ersetzt -> Block wiederhergestellt
4. `\n` in einem Python-R-String landete als **echter Zeilenumbruch** in der .gd-Datei
   (`cl.text = "` / `".join(...)` auf zwei Zeilen) -> zusammengefuehrt
5. Die Seltenheit war in einem Return-Zweig nicht definiert -> Seltenheits-Ziehung
   an den **Anfang** der Roll-Funktion verschoben
6. `RARITY_COLORS`/`RARITY_NAMES` waren nicht `static` -> als Const-Dictionaries
   mit Zugriff ueber die Instanz

### AH — RUNDE 43: CHARAKTER-FENSTER, PIXEL-ART-ICONS, WELTEN-ICONS, KISTEN-ANIMATION

**Vorbereitung:** Der Nutzer bat ausdruecklich um einen ausfuehrlichen Plan VOR der Umsetzung.
Er liegt als `PLAN_R43.md` (11.223 Zeichen) im Projektwurzel - mit Befundanalyse je
Nutzer-Punkt, konkreter Umsetzung, Risiken, Reihenfolge und Teststrategie.

**1. Skin-Wechsel ins Charakter-Fenster**
- `_create_char_page()` bekommt eine **SKIN-Reihe** (6 Kacheln, 168x168, NEAREST)
- `skin_buttons` als Member, `_on_skin_pressed(i)`, `_refresh_skin_buttons()`
- Aktiver Skin = goldener Rahmen + helle Kachel; gesperrter = Silhouette + Tooltip
- Die Sammlung verweist mit dem Button **„SKINS WAEHLEN -> CHARAKTER"** dorthin

**2. Vorschau zeigt den gewaehlten Charakter**
- Ursache: die Vorschau lief ueber zwei verschiedene Wege und einer davon ohne Skin
- Fix: **eine** Methode `_current_hero_texture()` - Skin (in der gewaehlten Farbe),
  sonst Farbe+Hut. Vorschau, Startseite und Sammlung nutzen alle dieselbe Quelle
- `char_name_chip` nennt jetzt alle drei Werte: „Farbe: WEISS · Hut: PIRAT · Skin: NINJA"

**3. Shop symmetrisch + Kisten-Animation**
- Alle 3 Karten auf feste Breite (400 px) und Hoehe (470 px) -> symmetrisches Bild
- Die Boost-Reihe laeuft rechts aus dem Bild -> **ScrollContainer** („BoostScroll")
- `_make_chest_icon()` neu: **Kistenkoerper in 3/4-Ansicht** (24x24 Pixel, 3x NEAREST)
  mit Deckel, Metallbaendern, Schloss, Griff, Nieten, Planken -> 72x72
- `_play_chest_open_animation()`: Truhe schuettelt -> Deckel fliegt auf -> Lichtstrahl
  -> Items fliegen heraus -> Funken (3/10/18 je Seltenheit) -> Bildschirm-Blitz bei epic

**4. Einheitliches Icon-Design**
- `icon_coin` war ein weicher Vektor-Kreis neben der Pixel-Art-Grafik des Herzens
- Neu: Muenze, Fadenkreuz und Schild als **Pixel-Art** (16x16, 4x NEAREST)
- Alle Item-Icons bekommen eine Pixel-Kachel im Shop

**5. Skin-Auswahl an einem Ort**
- Skin-Kacheln aus der SAMMLUNG entfernt (nur noch Farben + Huete = 20 Kacheln)
- Fortschrittstext verweist auf das Charakter-Fenster

**6. Welten-Icons anschaulich**
- Neu je Welt: `_make_map_icon_earth(season)` (Himmel/Sonne/Huegel/Baum),
  `_make_map_icon_mars()` (roter Boden/Krater/Felsen/Antenne),
  `_make_map_icon_jungle()` (Blattdach/Liane/Banane/Rauch), `_make_map_icon_volt()`
  (Blitz/Spulen auf Stahl)
- Die generischen Motive (tuft/cactus/ice/lava) sind weg

**7. Pixel-Art-Kacheln**
- `_make_pixel_panel_sb()` + `_make_pixel_button()`: keine Rundeglanz, harter
  5-px-Versatz unten rechts, `corner_detail = 1` (abgeschrägte Pixel-Ecken)
- Umgestellt: Startseiten-Nav, Sammlung, Charakter-Kacheln, Karten-Rahmen, Shop-Karten

**Test-Evidenz (Headless `COMIC_V62`..`V65`, Screenshots `compare/v62`..`v65`):**
```
V62 P2 vorschau_folgt_farbe=true
V62 P1 skin_kacheln=6  vorschau_ist_skin=true
V62 P2 namechip=Farbe: WEISS · Hut: PIRAT · Skin: NINJA
V62 P5 sammlung_kacheln=20
V62 P4 icon_coin 64x64 farbstufen=4 (Muenze jetzt Pixel-Art wie das Herz)
V62 P6 welten_icons=7 unterschiedliche_paare=21
V62 FEHLER=0
V64 FEHLER=0
```

**Beim Testen gefunden und behoben:**
1. `_make_map_icon_volt()` existierte bereits -> **Doppeldefinition** (Parse-Error) ->
   die alte Funktion entfernt
2. `_px_outline()` wurde vor seiner Definition genutzt -> Reihenfolge geprueft
3. Die fliegenden Items wurden auf die **volle Panelbreite aufgeblasen**
   (TextureRect ohne feste Groesse) -> jetzt 72x72 fest
4. Der Schild war ein weiches Vektor-Dreieck und brach die Icon-Einheitlichkeit
5. `game_manager` ist im Autoload nicht direkt erreichbar (nur ueber `ui_manager.game_manager`)
   -> im Test korrigiert
6. `Color.get_rgba8()` existiert in Godot 4 nicht -> Farbzaehlung ueber r/g/b

### K — OFFEN / NÄCHSTE RUNDE ⏳
| Thema | Plan |
|---|---|
| ~~**Lobby vor dem Run**~~ | ✅ **GEBAUT (Runde 10)** — siehe Abschnitt M |
| ~~**4-Spieler-Modus**~~ | ✅ **GEBAUT (Runde 10)** — bis zu 4 Spieler, Host autoritativ, Mitspieler-Liste im HUD |
| ~~**Zuschauer / Rejoin**~~ | ⏳ offen |
| ~~**Jahreszeiten + neue Planeten**~~ | ✅ **GEBAUT (Runde 13)** — Option D Hybrid: Jahreszeiten-Streifen je Planet, Fortschritt im Run, Jungle+Mars mit Seasons. Offen: Karten-Bosse, Meteoriten, Deko-Sammlung, weitere Planeten |
| ~~**Skin-/Karten-Freischaltung über Kisten**~~ | ✅ **GEBAUT (Runde 11)** — Gold aus XP, Kisten-Shop, Karten wählbar |
| ~~**Weitere Karten & Mobs als Sammel-Inhalt**~~ | ✅ **GEBAUT (Runde 12)** — Mars + Jungle als echte Welten mit eigenen Rigs, eigener Physik und XP-Schaltern; nächster Ausbau: Karten-Bosse, Meteoriten, Deko-Artikel |
| **Team-Modus-Ideen** | Geteilte Leben, Wiederbeleben („downed" + 3 s aufwecken), freundliches Feuer, Ping/Kommandos per Button |
| **iOS** | bleibt Zukunft — Windows kann kein `.ipa` bauen (Mac + Xcode + Apple Developer nötig), Projekt ist kompatibel (siehe Abschnitt F) |

### L — RUNDE 9: Menü-Neubau, Charakter-/Einstellungsseite, Wellen-Regeln, Welle-2-Bug ✅
**Auftrag:** Characterwahl auf eine eigene Seite, FPS-Anzeige + Grafik in eine Einstellungsseite hinter einem Zahnrad, im Wellen-Modus keine Level-Up-Karten mehr (Upgrades nur im Shop), Shop/Anzeige/Karten optisch aufwerten, Startmenü aufräumen — plus der gemeldete Bug „in Welle 2 spawnt kein Monster und kein Boss".

#### 1. Startmenü neu strukturiert (aufgeräumt)
Das Menü ist jetzt eine **Hauptseite + zwei Unterseiten** statt einer langen Liste:
- **Farbverlauf-Hintergrund** (GradientTexture statt flacher grüner Fläche), Karo-Bänder oben/unten nur noch halbtransparent (Alpha 0.55) — ruhigeres Bild.
- **Reihe 1:** `SPIELEN` (560×108, groß) · **Reihe 2:** `2 SPIELER` + `LAN SPIEL` · **Reihe 3:** `CHARAKTER` + `MODUS: ENDLOS/WELLEN`.
- Links oben der **eigene Held als Vorschau** (zeigt live die gewählte Farbe + Hut) mit Name + Untertitel, darunter die Monster-Parade — jetzt inkl. der neuen Biom-Monster (Graber/Golem/Feuerwerfer), damit die neuen Inhalte im Menü sichtbar sind.
- **Zahnrad-Knopf oben rechts** (prozedural gezeichnetes Zahnrad-Icon `icon_gear`, 96 px, rundes Panel) → öffnet die Einstellungsseite. Erreichbar, ohne das Menü zu verlassen.
- `BEST SCORE` + Kurz-Hinweis unter den Knöpfen; die Eingabemodi (Joystick/Tastatur) stehen in einer Zeile.
- Die früheren Profil-Zeilen (Name/Farbe/Hut) sind aus dem Hauptmenü **entfernt** — sie liegen jetzt auf der Charakterseite.

#### 2. Charakter-Seite (`CHARAKTER`-Knopf)
Eigene Seite als Panel über dem Menü (`_make_page()` erzeugt Dimmer + rundes Panel + Titel):
- **Große Heldenvorschau (240 px)**, aktualisiert sich sofort bei jeder Änderung (gleiche Textur wie im Spiel).
- **Namenseingabe** (max. 10 Zeichen) + Chip „Farbe: X · Hut: Y".
- **6 Farbkacheln**: jede Kachel zeigt den Helden **in dieser Farbe mit dem aktuellen Hut** (Button-Icon), die aktive ist aufgehellt.
- **6 Hutkacheln**: jede zeigt den Helden **mit diesem Hut**; nicht freigeschaltete sind gesperrt und zeigen „?" mit Tooltip „Noch nicht freigeschaltet — aus epischen Kisten". Darunter „X von 6 Hüten freigeschaltet".
- `ZURUECK` schließt die Seite. Die Seite ist Kind des Start-Screens → `start_screen.hide()` versteckt sie automatisch, kein Zustandsleck zwischen Runs.

#### 3. Einstellungs-Seite (Zahnrad)
- **GRAFIK-STUFE** als drei explizite Knöpfe `NIEDRIG / MITTEL / HOCH` (aktive Stufe aufgehellt) — vorher war es nur ein Durchschalt-Knopf. Darunter eine Erklärzeile, was die Stufe konkret macht (Shader, Detaildichte, Monster-Obergrenze). Neuer Setter `GameManager.set_quality(i)` (vorher nur `cycle_quality()`).
- **FPS-ANZEIGE: AN/AUS** und **SOUND: AN/AUS** (neu: `SoundManager.muted` + `set_muted()`, wird im Profil gespeichert; `play()` bricht bei Stumm ab). Beide Knöpfe zeigen ihren Zustand im Text und sind farblich markiert.
- Info-Text, was die FPS-Anzeige ausgibt, und `ZURUECK`.

#### 4. Wellen-Modus: keine Level-Up-Karten mehr
- `_open_upgrade_ui()` bricht im Wellen-Modus sofort ab: `pending_upgrades = 0`, offene Karten werden geschlossen, eine eventuelle Pause wird aufgehoben.
- `_gain_xp()` zählt im Wellen-Modus keine Karten mehr auf (`pending_upgrades` bleibt 0), zeigt aber **einmal pro Run** das Banner „WELLEN-MODUS: UPGRADES NUR IM SHOP".
- Damit ist die Progression sauber getrennt: **Endlos** → Level-Up-Karten, **Wellen** → Münzen + Shop nach jeder Welle.

#### 5. Shop + Karten + Anzeige aufgewertet
- **Shop**: rundes Panel (statt nacktem Vollflächen-Dimmer), Titelzeile „SHOP" + **Münz-Icon mit großem Kontostand**, Untertitel „Welle N geschafft — jetzt einkaufen", **Item-Karten** mit eigenem Icon (Herz / Schild / Flinte / epischer Ring / Blitz / Kugel), Name + Preiszeile. Bezahlbares grün, unbezahlbares ausgegraut und deaktiviert. Highlight-Button `WEITER — naechste Welle` (springt sofort zur nächsten Welle) und Fußzeile „Im Wellen-Modus gibt es Upgrades NUR hier". Das Panel läuft mit `PROCESS_MODE_ALWAYS`, damit es auch bei pausiertem Baum bedienbar bleibt.
- **Level-Up-Karten (Endlos)**: echte Karten mit **Akzentfarbe je Upgrade** (Rahmen + Titel in der Akzentfarbe), **Icon**, Name, Beschreibung (autowrap) und **„Stufe X / Y"** aus den Stack-Caps — vorher nur ein Button mit zwei Textzeilen. Kinder-Labels liegen auf `MOUSE_FILTER_IGNORE`, damit der Klick weiter auf dem Karten-Button landet.
- **Wellen-HUD** zeigt jetzt auch den Fortschritt: `WELLE n · k Monster uebrig · m Muenzen` bzw. im Shop `WELLE n GESCHAFFT · m MUENZEN · Shop schliesst in Xs` — damit ist sofort sichtbar, ob noch Monster offen sind.

#### 6. Bugfix: „in Welle 2 sind keine Monster und kein Boss gespawnt"
**Ursache:** `_start_wave()` setzte die Wellen-Monster 520–900 px um den Helden **ohne Begrenzung** auf die Welt. Der Endlos-Spawner und der Boss-Spawn klemmen ihre Position dagegen nach `clampf(..., 100, wmax)` ab. Stand der Spieler am Kartenrand (nach Welle 1 sehr wahrscheinlich), landete der Großteil der Welle **hinter der Grenzwand**: sie waren unerreichbar, unsichtbar und `wave_remaining` fiel nie auf 0 → keine Welle fertig, kein Shop, kein Folge-Boss. Der Boss kommt zusätzlich planmäßig erst in Welle 5 (`wave % 5 == 0`).
**Fix (3 Ebenen):**
1. Neue Helferfunktion `_wave_spawn_pos(center, far)` würfelt die Position und **klemmt sie in die Kartengrenzen** (130 px Rand), mit bis zu 20 Versuchen und Mindestabstand 240 px, damit nichts auf dem Helden steht. Genutzt für Wellen-Monster **und** den Wellen-Boss.
2. **Sicherheitsnetz in `monster_ai`**: jedes Monster prüft 1×/s, ob es außerhalb der Karten-Grenzen steht, und zieht sich ggf. 90 px ins Feld zurück. Das deckt auch Splitter-Kinder, Rückstoß und WLAN-Geister ab.
3. Der Wellen-Fortschritt hängt an einem **Zähler** (`wave_remaining`, zählt auch Splitter-Kinder), nicht an „keine Monster in der Szene" — plus die neue HUD-Zeile „k Monster uebrig".

**Verifikation (headless, echter Lauf) — Spieler bewusst in die Ecke (260,260) gestellt:**
```
UI menu=true char=true setseite=true zahnrad=true
UI char_sichtbar=true set_versteckt=true farben=6 huete=6 vorschau=true
UI set_sichtbar=true char_versteckt=true grafikbuttons=3
UI grafik=2 sound_vorher=false / sound_aus=true / UI zu=true
WAVE1 welle=1 rest=8 ausserhalb=0
WAVE1 shop_offen=true rest=0
WAVE karten_offen=false pending=0 pausiert=false
WAVE2 welle=2 monster=11 rest=11 ausserhalb=0      <- Bug behoben
UITEST_DONE
```
Zusätzlich 0 `SCRIPT ERROR`/`Parse Error` im Regressionlauf (`--quit-after 400`).

**Gelernte Fallen in dieser Runde:** (a) Wellen-/Rundenlogik nie über „was gerade in der Szene steht" steuern, sondern über Spawn-/Kill-Zähler; (b) ein Modus, der den Standard-Spawner ersetzt, muss den **Start**-Aufruf gaten (ein früher `stop_spawning()` wird von einem späteren `start_spawning()` derselben Funktion sonst wieder aufgehoben); (c) `icon_max_width` ist bei Button ein **Theme-Constant**, keine Property; (d) beim Austausch umfangreicher Funktionen per Skript genau prüfen, welche Funktion das nächste `\nfunc ` ist — sonst löscht der Nachfolge-Schritt die frisch eingesetzte Funktion wieder.

### F — iOS-Export: Antwort
- **Machbar? Ja.** Derselbe Godot-Projektordner exportiert ohne Code-Änderung nach iOS (Touch-UI ist bereits 9:16-tauglich). GDScript hat keine C#-Einschränkungen (die gelten nur für C#-Projekte).
- **Aber**: Godot verlangt laut Doku (4.7) **„export from a computer running macOS with Xcode installed"** — aus Windows geht kein `.ipa`. Der Export erzeugt ein Xcode-Projekt, das auf einem Mac gebaut/signiert wird.
- **Nötig**: Mac (oder Cloud-Mac / GitHub-Actions-macOS-Runner), Xcode + Command Line Tools, iOS-Export-Templates (im vorhandenen Template-Paket enthalten), **Apple Developer Program (99 €/Jahr)** für Team-ID, echtes Gerät/TestFlight/App Store. Kostenlose Apple-ID reicht nur für 7-Tage-Sideload.
- **Aufwand für uns**: gering (Export-Preset + Bundle-ID `com.example.comicshooter` + App-Icon in allen iOS-Größen), der Aufwand liegt komplett bei Apple-Toolchain/Hardware.

## 4. Build & Test
```
./Godot.exe --headless --path project --quit-after 120      # Regression (0 Fehler)
./Godot.exe --headless --path project --export-debug Android ComicShooter.apk
```
LAN-Test: 2 Geräte gleiches WLAN (AP → Clients) ODER PC: 2 Instanzen, manuelle IP 127.0.0.1.
