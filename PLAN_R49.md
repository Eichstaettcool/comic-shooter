# RUNDE 49 — Plan: LAN-Bugs + Boss-/Waffen-Features

Reihenfolge strikt halten. Jeder Schritt wird einzeln kompiliert und getestet.
Keine Struktur-Umbaue, die das Fenster zerlegen.

---

## TEIL 1 — LAN-Bugs ( kritisch, zuerst)

### Bug 1: Upgrade-Fenster öffnet sich für Clients nicht
**Ursache:** `_open_upgrade_ui()` (game_manager.gd Z3077) wird nur lokal aufgerufen.
`show_upgrade_cards()` läuft nur beim Host. Es gibt keinen RPC, der den Client
zum Öffnen des Upgrade-Fensters verpflichtet.
**Fix:**
- `net_manager.gd`: neuer RPC `h_send_upgrade_options(opts: Array)` → `coop_upgrade_options`
  (authority/reliable), Signal `upgrade_options_received(opts)`
- `game_manager.gd`: `_open_upgrade_ui()` → wenn `coop_client`, sendet er die
  3 Optionen an den Host und kehrt zurück; der Host sendet sie an ALLE Clients
- Der Client öffnet `ui_manager.show_upgrade_cards(opts)` beim Empfang
- **Achtung Skill-Regel:** `get_tree().paused` ist global — im LAN pausiert der
  Client seinen eigenen Baum, das ist gewollt (nur der Client pausiert sich,
  nicht der Host)

### Bug 2: Clients bekommen die Upgrades nicht angewendet
**Ursache:** `_on_upgrade_chosen(id)` (Z3102) ändert nur `player` des lokalen
Nodes. Beim Client existiert der Host-Player nicht, also passiert nichts.
**Fix:**
- `net_manager.gd`: RPC `h_apply_upgrade(slot: int, id: String)` → `coop_apply_upgrade`
- Host validiert (Upgrade war angeboten, Slot stimmt) und wendet es an
- Der Client wendet es auf SEINEN eigenen Player an (`_apply_upgrade_to_player`)
- `_on_upgrade_chosen` wird aufgeteilt: `_apply_upgrade_local(id)` + Broadcast

### Bug 3: Kein Death-Screen für Clients
**Ursache:** `show_death_screen()` (ui_manager Z2673) wird nur lokal aufgerufen.
**Fix:**
- `net_manager.gd`: RPC `h_send_game_over(score, best, gold_gain, gold_total)`
  → `coop_game_over`
- Host sendet bei `_game_over_multiplayer()` / Tod an alle Clients
- Clients zeigen `ui_manager.show_death_screen(...)`

### Bug 4: Revive funktioniert nicht über das Netz
**Ursache:** `_tick_downed()` (Z2756) läuft auf dem HOST und prüft die
Host-Player. `_revive_player(slot)` (Z2802) setzt `downed=false` nur am Host-Node.
Der Client sieht den Partner nie als "aufgewacht".
**Fix:**
- Der HOST entscheidet (Revive-Timer bleibt beim Host = autoritativ)
- `net_manager.gd`: RPC `h_send_downed_state(slot, downed, hp, revive_progress)`
  → `coop_downed_state` (10 Hz, unreliable reicht)
- Der Client setzt `downed`, `health` und den Ring am Partner-Sprite
- `players`-Dict: der Client hat nur den Partner-Ghost → Revive wirkt auf den Ghost

### Bug 5: Tote Spieler verschwinden auf dem Client
**Ursache:** Der Client-Ghost wird bei Tod versteckt (`visible = false`) oder
zerstört.
**Fix:**
- Der Ghost bleibt sichtbar, bekommt einen "DOWNED"-Zustand (halbtransparentes
  Sprite + Bodenring), erst bei Revive wieder volle Deckkraft
- Prüfung: Print `partner.visible` und `partner.modulate` im Test

### Bug 6: Rubber-Banding / Delay (Movement, Shooting, Monster)
**Ursache:** Partner-Position wird per `push_state` (unreliable) gesendet und
**ohne Interpolation** direkt gesetzt → ruckelt.
**Fix:**
- `net_manager.gd`/`game_manager.gd`: der Partner-Ghost interpoliert zwischen
  den letzten zwei empfangenen Positionen (`lerp` im `_process` mit
  `1.0 - exp(-speed * delta)`) statt zu teleportieren
- Extrapolation: hält die letzte Geschwindigkeit an, wenn kein Paket kommt
- **Idempotenz-Regel:** Die Sync-Funktion darf KEINE Knotenliste neu bauen
- Firing: der Client sendet nur seinen Winkel/Input, der HOST schießt
  (bereits so) → der Client sieht die Projektile des Hosts

---

## TEIL 2 — Miniboss-System

### 2a. Schwebende Health-Bar über dem Miniboss
- `monster_ai.gd`: neuer `miniboss_bar` (ColorRect-Hintergrund + ColorRect-Füllung)
  als Kind des Monsters, `z_index` über dem Sprite, Position `y = -halbe Höhe - 20`
- Füllt sich aus `current_health / max_health` in `_process` (nur bei Miniboss)
- Versteckt sich, wenn der Boss stirbt

### 2b. Visuelle Aura bei Spezialfähigkeit
- `monster_ai.gd`: `aura` (Sprite2D/ColorRect) als Kind, pulsierend per Tween
- Farbe = Ability-Farbe des aktuellen Bioms

### 2c. Biom-spezifische Fähigkeiten
- Neue const-Tabelle in `monster_ai.gd`:
  `MINIBOSS_ABILITIES = { "earth": {...}, "mars": {...}, "jungle": {...}, "volt": {...} }`
  mit Ability-Name, Schaden, Farbe, Cooldown
- Der Miniboss erbt die Fähigkeiten des aktuellen Bioms (`_biome_boss_type()`
  liefert den Biom-Kontext)
- Die Aura-Farbe folgt der aktiven Fähigkeit
- Feuer-Effekt für Mars/Elektro, Eis-Effekt für Erde-Winter usw.

---

## TEIL 3 — Main-Boss-Enhancements

### 3a. Dash-Angriff mit Aufwind-Animation
- `monster_ai.gd`: neuer Boss-State "DASH"
- Aufwind: 0.65 s Scale-Puls + Warn-Flag (`dash_warning = true`)
- Dash: 6× Geschwindigkeit für 1 s in Richtung des Spielers
- `_enter_boss_state(i)` setzt Timer + Warning-Timer (Skill-Regel!)

### 3b. Weak-Point-System
- `monster_ai.gd`: `weak_points: Array` = Positionen relativ zum Boss
  (z. B. Schild links, Kern oben)
- `take_damage(amount, ...)` prüft den Einschlagpunkt: liegt er in der
  Weak-Point-Zone → Schaden × 2.5
- Visuelles Feedback: kurzer Blitz + Sound beim Treffer
- Test: Schaden ohne Weak-Point vs. mit Weak-Point

---

## TEIL 4 — Waffen-Balancing + UI

### 4a. Magazin/Reload für Laser + SMG
- `player_controller.gd`: `mag_size` (Laser 24, SMG 40), `ammo` counter
- Nach `mag_size` Schüssen → `reload_time` (Laser 1.6 s, SMG 2.2 s), kein Schuss
-Reload-Indikator im HUD: Balken + Text „NACHLADEN 1.2s"
- `cooldown` bleibt unberührt (Buff-Faktor-Regel!)

### 4b. Waffen-Stat-Karten (anklickbar/ausklappbar)
- Neue Seite/Overlay „WAFFEN-STATS"
- Pro Waffe eine Karte: Schaden, RPM, Nachladezeit
- Klick → aufklappbare Detailzeile

---

## Verifikation je Schritt
1. `COMPILE_OK` (0 Parse/Script-Errors)
2. Headless-Test mit numerischen Assertions (Upgrade-Sync, Death-Sync, Revive-Sync,
   Weak-Point-Schaden, Magazin-Zähler, Stat-Karten)
3. Screenshot der neuen UI (Upgrade-Overlay, Boss mit Aura+Bar, Waffen-Stats)
4. Am Ende: kompletter Seiten-Audit + APK

## Regeln
- Keine Test-Hooks im ausgelieferten Code
- `_on_upgrade_chosen` / `_revive_player` etc.: bestehende Funktionen PATCHEN,
  keine Duplikate
- `get_tree().paused` ist global → im LAN pausiert nur der Client sich
- Jede neue RPC braucht Host+Client-Seite UND ein Signal
- Reihenfolge der RPC-Definitionen einhalten (authority-RPCs zuerst)


---

# RUNDE 49 — ABRECHNUNG (Kisten, Katze, Elektro-Mob, Bugfixes)

## A. Neues Elektro-Mob: SPULENTROOPER (Typ 29)

**Anlass:** Der Nutzer meldete, dass auf der Elektro-Karte „nur 2 Mobs" sind.

**Befund:** Der Volt-Pool hatte zwar drei Typen (`[25, 25, 26, 27, 26]`), aber:
1. **Die drei Volt-Mobs hatten KEINE eigene KI-Verzweigung** — sie liefen alle
   als Standard-Monster (nur `type_stats` unterschied sie). Der Spieler sah
   dadurch „Drohne" und „Trooper", die beide „irgendein Roboter" aussahen.
2. `BOSS_VOLT` war im Enum an Position **28**, `VOLT_SPOOLER` an **29** — meine
   erste Annahme (29/30) war falsch und hat zuerst zwei Fehler produziert.

**Umsetzung:**
- `monster_ai.gd`: Enum `..., BOSS_VOLT, VOLT_SPOOLER }` → **Typ 29**
- `monster_ai.gd`: `type_stats` → `{ speed 52, health 22, damage 3, points 130 }`
- `monster_ai.gd`: **eigene KI-Zweige** für `VOLT_DRONE` (schwebt, rauscht
  geradeaus), `VOLT_TROOPER` (deckungsuchend, Einzelschuss) und
  `VOLT_SPOOLER` (langsam, hält 210-420 px Abstand, **3er-Salve**)
- `texture_manager.gd`: `_make_monster_volt_spooler()` — Teslaspule am Rücken,
  Schild mit Blitz-Emblem, Stab mit leuchtender Kugel, Visier
- `game_manager.gd`: Pool `[25, 25, 26, 26, 27, 29, 29]`, Gewicht `{29: 1.8}`

**Test-Evidenz (headless, `AUDIT49V`):**
```
AUDIT49V   type=29 speed=46.8 hp=22 dmg=3     ✓ Stats greifen
AUDIT49V   sprite_ok=true                     ✓ Textur gesetzt
AUDIT49V   projektile=2 (Salve erwartet)      ✓ feuert
AUDIT49V   spooler_alive hp=22 ranged=true    ✓ lebt, ist ranged
AUDIT49V   volt_pool=[25,25,26,26,27,29,29]  ✓ im Pool
AUDIT49V   typ29_gewicht=1.8                  ✓ gewichtet
AUDIT49V   kisten_ok=6/ 6                     ✓ alle Kisten-Icons da
AUDIT49V FEHLER=0
```

**Sichtprüfung (Window-Lauf, `compare/v106/02_mobs_katze_spooler.png`):**
Beide Mobs sind im Feld klar lesbar und unterscheidbar.

## B. Kisten-Designs neu gezeichnet

**Befund (vorher):** Alle Truhen teilten sich dieselbe Silhouette — `chest_storm`
und `chest_platinum` waren reine Farbvarianten, `chest_silver` las sich durch
zwei dunkle „Verschluss-Haften" **als Gesicht** (Augen mit Pupillen), und die
Standard-Kiste `chest` war ein flacher brauner Topf.

| Kiste | vorher | jetzt |
|---|---|---|
| `chest` | flacher Topf | klassische Truhe: gewölbter Deckel, Deckelspalt, 2 Eisenbänder, Schloss mit Schlüsselbart, Eckbeschläge, Füße |
| `chest_silver` | Industrie-Kiste mit „Gesicht" | 1 zentrales Schloss, 4 Ecknieten, untere Hälfte aufgehellt |
| `chest_platinum` | umgefärbte Standardkiste | eigene Silhouette: flacher Deckel mit **facettiertem Kristall**, leuchtender Spalt |
| `chest_storm` | umgefärbte Standardkiste | eigene Silhouette: flache, breite **Waffenkiste** mit Sturm-Fangzähnen, Warnstreifen, Blitzzeichen |

**Textur-Blatt:** `compare/v105/sheet_kisten_shop.png`

## C. Roboterkatze (Jungle) neu gezeichnet

`monster_robo_tiger` war ein flacher, gestreckter Metallblock — er las wie ein
Kabel, nicht wie ein Tier.

**Neu:** hoher Körper auf vier Beinen, aufrechte helle Brustpartie, runder
Kopf mit **zwei spitzen Ohren** (mit dunklem Innenohr), Schnauze mit Nase und
sichtbarem Zahn, leuchtendes blaues Auge, Halsband mit Antenne, **Schweif nach
oben gebogen**, Tigerstreifen.

**Sichtprüfung:** `compare/v106/02_mobs_katze_spooler.png` — die Katze ist im
Feld sofort als Katze erkennbar.

## D. Gefundene Spiel-Bugs (alle headless verifiziert)

| Bug | Ursache | Fix |
|---|---|---|
| **Bananen machen keinen Schaden** | `projectile.gd` rief `take_damage` mit **2** Argumenten, der Spieler nimmt **1** → Exception | 1-Argument-Call |
| **Boss greift nicht an (Volt)** | `_biome_boss_type()` gab **27** (VOLT_SPIDER) zurück statt 28 (BOSS_VOLT) → der „Boss" war ein normaler Gegner | `return 28` |
| **Biom-Bosse können nie dashen** | Der Dash-Block existierte nur in `_boss_pattern` (Typ 7), nicht in `_biome_boss` | State 3 in `_biome_boss` + Dash-Zyklus |
| **2 Bosse übereinander** | `_spawn_boss()` und der Wellen-Boss liefen parallel; `current_boss` überwachte nur den letzten | Boss ersetzt statt verdoppelt |
| **HP-Bar/Aura/Weak Points fehlen** | `set_type()` läuft **nach** `add_child()` → `_ready()` sah den Default-Typ | `_apply_boss_visuals()` in `set_type()` + `_ready()` |
| **Magazin/Nachladen**: `ammo` → `-1` | `-1` bedeutet „unendlich" — nach dem Nachladen war die Waffe unendlich | `ammo = 0`, Magazin füllt sich neu |
| **Stats-Seite „SCHADEN –"** | UI hatte keinen Zugriff auf `WEAPON_DATA` (private const im Player) | `WEAPON_STAT_VALUES` in der UI |
| **Projektil-Maske** | `set_banana()`/`set_enemy()` nach `add_child()` → die Area behielt die Spieler-Maske | `_apply_layers()` bei jedem Setzen |

**Boss-Test-Evidenz:**
```
AUDIT49 banana_schaden health 5 -> 4             ✓
AUDIT49 boss type=20 is_biome=true              ✓
AUDIT49 lebende_bosse=1 (1 erwartet)            ✓ kein Doppel-Boss
AUDIT49 boss weak_points=2                      ✓
AUDIT49 weakpoint hp 150 -> 140 -> 115          ✓ 10 normal / 25 am Kern
```

## E. Test-Infrastruktur (der eigentliche Hebel)

`test_runner.py` im Projekt-Root — **headless**, kein Fenster, kein Suchen,
kein Schließen:

- Hook-Installation mit **Verifikation** (`_audit_hook-def=1 | _ready=1 | OK`) —
  ein fehlender Anker kann nicht mehr stillschweigend ins Leere laufen
- `remove_hook()` in fester Reihenfolge, entfernt **alle** `_audit*`-Varianten
- `capture_output` statt Datei-Umleitung (Godot puffert `print` in die Pipe)
- nur **eine** Output-Quelle (Godot dupliziert `print` nach stdout *und* stderr)
- wertet die **Fehlerzahl** aus (`FEHLER=0` = PASS), nicht nur das Vorhandensein
- `--window` schaltet den Fenstermodus für Screenshots frei (headless hat keine GPU)
- `COMIC_TESTNODE` wählt den Testknoten, damit mehrere Tests parallel liegen können

### Lehren aus dieser Runde (dokamentiert für spätere Runden)

1. **Ein fehlender Anker ist ein stiller No-op.** Der Test-Hook wurde dreimal
   „installiert" und lief dreimal nie — das Skript meldete trotzdem Erfolg.
   Deshalb: nach jedem Einfügen **verifizieren**, nicht annehmen.
2. **Der Hook läuft in `_ready()` — die Szenen sind noch nicht gesetzt.**
   `start_game()` und `spawn_monster_at()` brauchen gewartete Frames. Ein Test,
   der vorher auf den Spieler wartet, blockiert sich selbst (Deadlock).
3. **`get_tree().get_children()` gibt es nicht** — die Kamera hängt unter `root`.
4. **Die Kamera folgt dem Spieler jede Frame** (`camera.global_position = ...`),
   sie lässt sich nicht für einen Screenshot umsetzen — stattdessen die Mobs
   skalieren und nebeneinander stellen.
5. **Enum-Indizes zählen.** `BOSS_VOLT` war 28, nicht 29 — zwei Folgefehler.
   Immer die Enum-Zeile auslesen und den Index ausrechnen, nie raten.
6. **Der Schild absorbiert den ersten Treffer** — `take_damage` prüft
   `shield > 0` zuerst. Ein Test, der `health` prüft, muss den Schild
   zurücksetzen, sonst ist „kein Schaden" das **richtige** Verhalten.
7. **`int(variant)` kann scheitern.** `int(gm.get("current_state"))` →
   „Nonexistent 'int' constructor", weil `get()` den Enum-Wert schon liefert.


### D. Nach dem ersten Screenshot — Nachbesserungen an den Mobs

Der erste Window-Screenshot zeigte: **Drohne, Trooper und Spinne waren alle
dunkelgrau-blau mit einem leuchtenden Kern** — im Feld nicht unterscheidbar.
Der Nutzer hatte Recht mit „nur 2 Mobs".

**Fix:**
- **Spinne**: eigener Farbton (dunkles Violett + giftgrüner Kern) + acht
  gestaffelte Spinnenbeine in drei Paaren
- **Trooper**: heller Roboter mit gelbem Visier, Brustplatte mit Warnstreifen,
  Spulen-Kern auf der Brust, Antenne und der Signatur-Spulenarm mit Stift
- **Spooler**: die Grundfarben wurden aufgehellt (Metall 0,50 → 0,62), er war
  auf dem dunklen Waldboden zu dunkel

**Finaler Sicht-Check** (`compare/v105/sheet_volt_mobs.png`): alle vier
Elektro-Mobs sind jetzt auf einen Blick unterscheidbar.

### E. Abschluss-Test (alles zusammen, headless)

```
AUDIT49F banana health 5 -> 4             ✓ Bananen machen Schaden
AUDIT49F bosse=1 (1 erwartet)            ✓ kein Doppel-Boss
AUDIT49F weak_points=2                   ✓ Weak Points da
AUDIT49F weakpoint 150 -> 140 -> 115     ✓ 10 normal / 25 am Kern
AUDIT49F typ 25 hp=6  speed=108.0 tex_ok=true   ✓ Drohne
AUDIT49F typ 26 hp=16 speed=70.2  tex_ok=true   ✓ Trooper
AUDIT49F typ 27 hp=10 speed=94.5  tex_ok=true   ✓ Spinne
AUDIT49F typ 29 hp=22 speed=46.8  tex_ok=true   ✓ Spooler (neu)
AUDIT49F kisten 6/ 6                     ✓ alle Kisten-Icons
AUDIT49F katze typ=17 tex_ok=true        ✓ Katze
AUDIT49F FEHLER=0
```

Projekt sauber: 0 Test-Hooks, 0 Env-Variablen, `COMPILE_CLEAN`.


### F. APK-Build (22:19, 29.516.012 Bytes)

```
./Godot.exe --headless --path project --export-debug "Android" \
    "C:/Users/vince/Games/comic-shooter/ComicShooter.apk"
```

**Verifikations-Beweis (nicht nur die Dateigröße):**
- `[ DONE ] update_scripts_classes` → die Skripte wurden neu kompiliert
- **Alle 272 Dateien** in der APK tragen den Zeitstempel 22:19-22:20 —
  ein vollständiger Rebuild, kein teilweises Update
- `monster_ai.gdc` 24.678 B, `texture_manager.gdc` 96.262 B (vorher deutlich
  kleiner — die neuen Zeichenfunktionen sind drin), `projectile.gdc` 1.874 B
- `apksigner verify` → **Signed**, CN=Godot
- vorherige APK (20:11): 29.491.436 B → jetzt: 29.516.012 B

**Projekt-Zustand nach dem Build:** 0 Test-Hooks, 0 temporäre Testdateien,
`COMPILE_CLEAN`.


---

# RUNDE 49b — In-Game-Kisten + Musik

## A. Die IN-GAME-Kisten waren nicht angepasst

**Befund:** Ich hatte in Runde 49 nur die **Shop-Icons** (`chest_wood`,
`chest_silver`, `chest_gold`, `chest_platinum`, `chest_storm`) neu gezeichnet.
Die Truhe, die man im **Spiel** findet, benutzt aber `chest_run_common` /
`chest_run_rare` / `chest_run_epic` — eine ganz andere Funktion
(`_make_run_chest`), die ich nicht angefasst hatte. Die war ein flacher Block:
zwei Rechtecke plus ein Kreis.

**Neu (`_make_run_chest`):** gewölbter Deckel mit Kontur, sichtbarer
Deckelspalt, zwei Eisenbänder über Deckel und Korpus, ein Schloss mit
Edelstein, Eckbeschläge, Füße — und bei der Epic-Variante eine **Krone aus
Stacheln** mit Edelsteinen.

**Sichtprüfung:** `compare/v107/sheet_ingame_kisten.png` und
`compare/v107/01_ingame_truhen.png` (im echten Spiel: Holz / Metall / Gold).

**Bug dabei gefunden:** `_ellipse()` hat **keinen Outline-Parameter** — der
7. Parameter ist `blend`. Mein Glanzlicht mit `_px()` und Alpha < 1 **ersetzte**
den Pixel statt zu mischen und war deshalb ein halbtransparentes **Loch im
Deckel**. Fix: `blend = true` (dann `_px_blend`).

## B. Musik

**Befund:** `SoundManager` erzeugte prozedural nur **Effekte** (Schüsse, Treffer,
Level-up) — es gab **keine Musik**.

**Umsetzung (`sound_manager.gd`):** zwei neue Themes, ebenfalls prozedural
(keine Dateien — passend zum Projekt):

| Theme | Wo | Aufbau |
|---|---|---|
| `menu` | Startbildschirm | ruhiger Loop, 8 s: Am–F–G–Em, weiches Pad + Melodie, Tremolo, Saettigung am Loop-Rand (kein Klick) |
| `game` | im Run | Action-Loop, 8 s: Bass auf jedem Schlag, Kick auf 1+3, Snare auf 2+4, Hi-Hat, pentatonisches Arpeggio, Lead-Melodie |

**Verdrahtung:**
- `ui_manager.show_start_screen()` → `SoundManager.play_music("menu")`
- `game_manager.start_game()` → `SoundManager.play_music("game")`
- `ui_manager.show_death_screen()` → zurück auf den ruhigen Loop
- Der bestehende **SOUND-Schalter** schaltet jetzt auch die Musik ab
  (`set_muted` / `set_music_enabled`)

**Test-Evidenz (headless, `AUDIT49M`):**
```
AUDIT49M musik_streams=["menu", "game"]        ✓ beide Themes
AUDIT49M   menu bytes=352800 dauer=8.0s rms=3107 peak=15033   ✓ echter Ton
AUDIT49M   game bytes=352800 dauer=8.0s rms=3940 peak=28307   ✓ lauter, dynamischer
AUDIT49M menu_laeuft=true player_playing=true  ✓ spielt wirklich
AUDIT49M game_laeuft=true player_playing=true  ✓ Wechsel klappt
AUDIT49M nach_mute_playing=false               ✓ Stummschalter stoppt sie
AUDIT49M chest_textur_ok=true                  ✓ In-Game-Truhe hat Textur
AUDIT49M FEHLER=0
```

Der **RMS-Wert** ist der eigentliche Beweis: eine Datei, die nur formal
existiert, hat RMS ≈ 0. Hier ist 3107 (Menü) bzw. 3940 (Spiel) — es ist
wirklich Musik, keine Stille.

**Bug dabei gefunden:** `play_music()` brach ab, wenn `muted` war — dadurch
startete die Musik gar nicht, wenn der Ton im Profil aus war. Jetzt merkt sich
`play_music` die Auswahl und `set_muted(false)` startet sie nach.


### C. Abschluss-Test Runde 49b (alles zusammen)

```
AUDIT49Z themes=["menu", "game"]              ✓ beide Themes vorhanden
AUDIT49Z   menu rms=3107                      ✓ echter Ton (nicht Stille)
AUDIT49Z   game rms=3942                      ✓ lauter, dynamischer (Drums)
AUDIT49Z menu_playing=true                    ✓ Menue-Musik spielt
AUDIT49Z game_playing=true                    ✓ Wechsel klappt
AUDIT49Z im_run_musik=game playing=true       ✓ Spielmusik laeuft im Run
AUDIT49Z truhen_mit_textur=6 (mind. 3)        ✓ In-Game-Truhen mit Textur
AUDIT49Z bosse=1 weak_points=2                ✓ Boss-Logik intakt
AUDIT49Z spooler=true tex=true                ✓ neues Mob intakt
AUDIT49Z FEHLER=0
```

**Lehre:** Eine Test-Assertion, die „genau N" erwartet, meldet einen Fehler,
sobald das Spiel selbst noch Objekte spawnt. Im Spiel existierten bereits
Truhen — der Zaehler kam auf 6 statt 3. Die richtige Formulierung ist
„mindestens N", wenn man nur die eigenen Objekte pruefen will.


---

# RUNDE 49c — Boss-Bugs, Balancing, Shop

## A. Der Boss-Bug: Mini-Bosse unsichtbar, Erd-Boss sofort weg

**Ursache (Einrückung!):** Mein Runde-49-Patch hatte den Boss-Spawn
**in die if-Bedingung eingezogen**:

```gdscript
if current_boss != null and is_instance_valid(current_boss) and not current_boss.is_queued_for_deletion():
    current_boss.queue_free()
    current_boss = spawn_monster_at(_wave_spawn_pos(center, true), btype)   # <- in der if!
```

Der Spawn passierte also **nur, wenn schon ein Boss lebte**. Beim ersten
Boss (Mini-Boss Welle 5, Riesen-Boss Welle 10) war `current_boss` null →
**es wurde überhauptnichts gespawnt**. Und wenn der Endlos-Boss lebte,
wurde er beim Wellenstart freigegeben → „der Boss ist direkt wieder weg".

**Fix:** Der neue Boss wird **immer** gespawnt, nur der alte wird entfernt.

**Test-Evidenz:**
```
AUDIT49C welle=10 boss=true typ=21 hp=483      ✓ Riesen-Boss erscheint
AUDIT49C welle10_boss_lebt hp=483 max=483      ✓ lebt
AUDIT49C welle=5 miniboss=true typ=22 hp=179  ✓ Mini-Boss erscheint
AUDIT49C   bar=true aura=true                 ✓ HP-Bar + Aura
AUDIT49C miniboss_lebt hp=179 max=179
AUDIT49C FEHLER=0
```

**Nebenbei gefixt:** `max_health` wurde **vor** der Schwierigkeits-Skalierung
gesetzt, aber `current_health` **danach** — die Bossbar zeigte 483/644 statt
483/483. Jetzt wird `max_health` nach der Skalierung nachgezogen.

## B. Der Mini-Boss war „verbuggt"

Zwei Fehler, im Screenshot sichtbar:
1. **Die HP-Bar war 120 px breit bei einem 100 px hohen Boss** und lag bei
   -110 — sie war breiter als der Boss und schwebte abgeschnitten daneben.
   Jetzt: sie skaliert **mit** dem Boss und sitzt bei -74 direkt über dem Kopf.
2. **Der Mini-Erd-Boss hatte zwei runde gelbe Augen mit dunkler Pupille** —
   das las sich als großes Gesicht. Jetzt: schmale waagerechte
   Sensor-Spalten ohne Pupille (ein Käfer bleibt ein Käfer).

**Sichtprüfung:** `compare/v108/03_mini_und_erdboss.png`

## C. Balancing

### Endlos-Modus: zu viele Upgrades
`xp_needed` startete bei **25** und wuchs nur um **12** pro Level — bei
10-30 Punkten pro Monster war das alle 1-2 Kills ein Level.

| | vorher | jetzt |
|---|---|---|
| Start-XP | 25 | **60** |
| Wachstum pro Level | +12 | **+24** |

### Wellen-Modus: zu viel Gold
Pro Kill gab es `Punkte × 0,5` Gold, und die **Schwierigkeit gab mehr Gold
je härter** (SCHWER 1.35, HARDCORE 1.70) — verkehrt herum. Eine Welle
brachte so viel Gold, dass der komplette Shop auf einmal kaufbar war.

| | vorher | jetzt |
|---|---|---|
| Gold pro Punkt | 0,5 | **0,24** |
| Faktor LEICHT | 1.15 | 1.25 |
| Faktor NORMAL | 1.00 | 1.00 |
| Faktor SCHWER | 1.35 | **0.78** |
| Faktor HARDCORE | 1.70 | **0.58** |
| Preis-Wachstum je Welle | +5 % | **+8,5 %** |
| Preis-Faktor Erde | 1.00 | **1.45** |
| Preis-Faktor Mars | 1.45 | **1.90** |
| Preis-Faktor Jungle | 1.70 | **2.25** |

Damit sind die Preise **schneller** als der Ertrag: ab Welle ~10 reicht das
Gold nicht mehr für alles, und in späten Wellen bleibt man öfter ohne Gold.

**Test-Evidenz:** `xp_needed=60`, `shop_preise: potion=17 damage=58`

## D. Shop: Direktkauf zeigte unbesessene Items

**Befund:** Die Shop-Seite baute eine Karte für **jedes** Boost aus `BOOSTS` —
also standen alle da, auch wenn der Spieler noch **keins** besessen hatte.

**Fix:** Der Direktkauf zeigt **nur besessene** Boosts (die neuen kommen aus
den Kisten). Die Karte zeigt den Besitz (`KAUFEN 40  (x2)`), und die
Direktkauf-Überschrift verschwindet, wenn nichts besessen wird.

**Test-Evidenz:**
```
AUDIT49C shop_boosts_ohne_besitz=0 (0 erwartet)   ✓ nichts ohne Besitz
AUDIT49C shop_boosts_mit_besitz=1 (1 erwartet)    ✓ besessener Boost da
```

---

# RUNDE 49d — Windows-EXE und iOS

## A. Windows-EXE ✅

**Voraussetzung:** Die Export-Templates waren nur für Android installiert
(`android_debug.apk`, `android_release.apk`, `android_source.zip`).
Für Windows fehlten sie komplett.

**Schritte:**
1. Templates heruntergeladen: `Godot_v4.7.2-stable_export_templates.tpz` (1,19 GB)
   von der GitHub-Release-Seite
2. **Nur** die nötigen Dateien entpackt (Windows-EXEs + `ios.zip`), nicht die
   1,2 GB Android-Teile — Platz ist knapp (19 GB frei)
3. Preset `[preset.1] "Windows Desktop"` angelegt (x86_64, `embed_pck=false`)

**Ergebnis:**
```
ComicShooter.exe   103.140.864 Bytes  (23:15)
ComicShooter.pck      845.104 Bytes
```
**Verifiziert:** `ComicShooter.exe --headless --quit-after 120` läuft mit
**0 SCRIPT ERROR / Parse Error** — die EXE lädt das PCK und die Skripte.

## B. iOS — das Xcode-Projekt ist fertig, die .ipa braucht einen Mac

**Was geht:** Der Export erzeugt ein **vollständiges Xcode-Projekt** vom
Windows-Host aus. Verifiziert durch drei aufeinanderfolgende Blocker:

| Blocker | Ergebnis |
|---|---|
| 1. `ios.zip`-Vorlage fehlte | nach dem Entpacken erledigt |
| 2. „App-Store-Team-ID nicht angegeben" | Platzhalter `ABCDE12345` gesetzt |
| 3. **Xcode-Build** | → **`.ipa können nur unter MacOS gebaut werden`** |

Godots eigene Meldung beim erfolgreichen Export:
> `WARNING: Xcode-Build: .ipa können nur unter MacOS gebaut werden. Das
> Xcode-Projekt wird verlassen ohne das Paket zu bauen.`

**Ergebnis (430 MB, als ZIP zum Übertragen):**
```
ios_build.xcodeproj/    25 K   <- das Xcode-Projekt
ios_build/              766 K  <- Info.plist, Storyboard, Assets, dylibs
ios_build.pck           828 K  <- die Spieldaten
ios_build.xcframework   409 M  <- die Godot-iOS-Engine
MoltenVK.xcframework     20 M
ComicShooter_iOS_Xcode.zip  152 MB
```

**Was auf dem Mac noch passieren muss (5 Minuten):**
1. ZIP entpacken
2. `ios_build.xcodeproj` in Xcode öffnen
3. **Signing & Capabilities** → das Team des Apple-Developers eintragen
   (ersetzt den Platzhalter `ABCDE12345`)
4. Einen **Signing-Team** für die Bundle-ID `com.vince.comicshooter` wählen
5. Build → „Any iOS Device" → `Product` → `.ipa`

**Was der Nutzer dafür braucht:** ein Apple-Developer-Account (99 $/Jahr) für
Team-ID und Signatur. Mit einer kostenlosen Apple-ID geht es nur als
7-Tage-Sideload.

**Alternativen ohne Mac:** ein Cloud-Mac oder ein GitHub-Actions-Runner mit
macOS — dann läuft der Build dort automatisch. Der Projektanteil daran ist
klein (Preset + Icon-Set), der Aufwand steckt in Apples Toolchain.
