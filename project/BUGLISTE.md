# BUGLISTE — Stand v1.46 (6.11.2026)

Hinweis: Die Einträge B1–B44 stammen aus den Tests bis v1.32 (Motorola edge 60 pro als Host,
Samsung SM-G780G als Client, WLAN `TP-Link_2.4GHz_53A540`, adb über USB) und bleiben unverändert
stehen — behobene Punkte sind dort als „behoben" markiert.

## v1.46 — gefunden und behoben

| # | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **B46-1** | **kritisch** | Engine-Loop (`LOOP_FORWARD`) stürzt auf dem Emulator im Audio-Thread ab — App beendet sich nach ~11 s | `logs_emu_crash146.log`: `tid: 11308, name: AudioTrack … signal 11 (SIGSEGV)` | **behoben** — `LOOP_DISABLED` + `seek(0)` kurz vor dem Ende (`SoundManager._process`); belegt `[MUSIK][LOOP] nahtlos … quelle=seek`, `SIGSEGV=0` |
| **B46-2** | mittel | Hut-Skalierung wurde falsch geloggt (`clampf(w/18,0.90,1.45)` statt `clampf(w/25,0.85,1.30)*seat`) — die Recon-Zahl „s=1.39 konstant" war ein Log-Artefakt | `[HAT][FIT] … s=1.39` (alt) | **behoben** — Log zeigt den echten Faktor, Streuung je Rig 0,14–0,20 |
| **B46-3** | mittel | 128 von 408 Hut-Kombinationen verdeckten die Augen (Kappe/Wollmütze/Strohhut/Brille 82–100 %) | `[HAT][PRUEF] ERGEBNIS paare=408 auffaellig=128` | **behoben** — Augenband gemessen, Hut darüber gesetzt/verkleinert, Hutpixel über dem Augenband gelöscht: `auffaellig=0` |
| **B46-4** | niedrig | Rucksack/Schulterplatten lagen auf der Brust | Kontaktblatt `v139/hats_29x4.png`, Hut 16 | **behoben** — eigene Ebene hinter dem Körper: `[HAT][EBENE] hut=16 … koerper_ueberdeckt=0.0%` |
| **B46-5** | mittel | Rig 0 lief über einen zweiten Zeichenweg (`_make_player` ohne Hut-Fit) — Messung zeigte dort immer 100 % | Code-Vergleich `texture_manager.get_skin_hat_texture()` | **behoben** — ein Weg für alle Skins: `[HAT][PFAD] rig=0 weg=make_player_rig` |
| **B46-6** | mittel | Einstellungen zeigten auch aus der Pause SCHWIERIGKEIT und BIOM-ÜBERGANG | `settings_page.gd` Zeile 84/159 | **behoben** — `apply_origin()`: `[SET][ORIGIN] herkunft=pause schwierigkeit=aus biom=aus` |
| **B46-7** | niedrig | Musik-Loop-Log ohne Bezug (nur Zeitstempel) | `[MUSIK][LOOP] t=8s pos=0.67` (alt) | **behoben** — Track, Neustarts, Lücke, Fenster in einer Zeile |

**Offen (bewusst):** Das Pause-Overlay selbst hat weiter eine eigene SCHWIERIGKEIT-Reihe
(„sofort wirksam"). Die Spec v1.46 (I1) betrifft die Einstellungsseite, ein Umbau des Overlays war
ausgeschlossen.

---

Hinweis: Die Einträge B1–B44 stammen aus den Tests bis v1.32 (Motorola edge 60 pro als Host,
Samsung SM-G780G als Client, WLAN `TP-Link_2.4GHz_53A540`, adb über USB) und bleiben unverändert
stehen — behobene Punkte sind dort als „behoben" markiert.


Die folgenden fünf Punkte sind in v1.45 gefunden und **behoben**; sie stehen hier als Beleg, weil sie
vom Nutzer gemeldet oder beim Messen sichtbar wurden.

---

## B45-1 — Text im Modus-Kasten des Ladebildschirms stand linksbündig (gemeldet, mittel)

**Symptom:** „der text im kasten nicht zentriert" — im blauen Modus-Panel standen Name und Beschreibung
am linken Rand, während der Kasten selbst mittig saß.

**Beleg (vorher, `boot_1080.png`):** Name „ENDLOS-MODUS" begann bei x=305 im 960-px-Bild = 610 px im
1920er Bild, Kastenmitte 960.

**Ursache:** `load_mode_name` / `load_mode_desc` hatten keine `horizontal_alignment`-Vorgabe (Godot
Default = links) und der Kasten wurde über `custom_minimum_size = 700` breit gezogen.

**Fix:** beide Labels auf `HORIZONTAL_ALIGNMENT_CENTER`, `size_flags_horizontal = FILL`, Beschreibung
560 px breit. **Beleg (nachher):** `[LOAD][MITTE] zustand=boot kasten=(666..1254) name=(680..1240)
text_mitte=960.0 kasten_mitte=960.0 abweichung=0.0px desc_abweichung=0.0px`; Pixelmessung im Bild:
Kastenmitte 959, Textmitte 960,5 (1,5 px = Antialiasing).

---

## B45-2 — Leerer Kasten beim App-Start („das Feld wirkt unfertig", mittel)

**Symptom:** Beim Start stand ein 132 px hoher leerer Platz im Modus-Panel.

**Ursache:** `build_boot_screen()` blendete nur `load_mode_icon` (TextureRect) aus; der Platzhalter
`icon_holder` blieb sichtbar und reservierte die Höhe.

**Fix:** Beim Boot wird jetzt das Modusbild gezeichnet (`_mode_preview_texture`) und der Platzhalter
bleibt sichtbar. **Beleg:** `[BOOT][UI] panel_modus=endlos icon=an leer=false`.

---

## B45-3 — Gold-Anzeige lag über dem ZURÜCK-Knopf des Glücksrads (niedrig)

**Symptom:** „GOLD: 50000" und der Knopf überlappten sich (`GC0ZURÜCK000` im Bild).

**Ursache:** `gold_label.position = (size.x - 520, 30)` bei 470 px Breite, `close` ab `size.x - 300`.

**Fix:** Gold bei `size.x - 700`, Breite 360. **Beleg:** `wheel_1920.png` / `emu_wheel.png` zeigen
„GOLD: 49500" und „ZURÜCK" getrennt.

---

## B45-4 — Aufgabenkarten ragten rechts aus der Seite (mittel)

**Symptom:** In der ersten Fassung der START/Stufen-Zeile fehlten rechts START-Knopf und Diamanten-Chip.

**Ursache:** 3×92 + START 150 + Icon 128 + Abstände = 602 px Karten-Mindestbreite, im 3-spaltigen Raster
also 1 842 px bei 1 720 px Seitenbreite.

**Fix:** Stufenknöpfe 80 px/18 px Schrift, START 126 px, Karte 560×292. **Beleg:** `chal_karte.png`
(Emulator `emu_chal.png`) — alle sechs Karten vollständig im Bild.

---

## B45-5 — Zielzahlen und Beschreibung passten nicht zur Stufe (niedrig)

**Symptom:** Karte sagte „20 Runden" (Text aus v1.44), LEICHT verlangt aber 8.

**Fix:** `ChallengeRun.desc_for(id, stufe)` erzeugt die Beschreibung aus den Zahlen der gewählten
Stufe; Fortschrittsbalken und „0/x" folgen der Stufe. **Beleg:** `[CHAL][WAHL] id=revolver stufe=hart
runden=16 diamanten=160`, `chal_karte.png` zeigt für NORMAL „12 Runden … 0/12".

---

---

## B1 — Lobby behält toten Host-Eintrag (kritisch)

**Symptom:** Nach einem beendeten Run bleibt der Host in der Fundliste stehen, obwohl
kein ENet-Server mehr lauscht. Der Client verbindet ins Leere.

**Beleg:**
```
17:53:41  CLIENT  LOBBY: verbinde mit 192.168.188.142
17:53:48  CLIENT  [LAN] Peer getrennt - 0 Partner-Figur(en) entfernt, players=[]
17:53:49  HOST    LOBBY: verbinde mit 192.168.188.142     <- Host verbindet zu sich selbst
```
Zusätzlich: `cat /proc/net/udp | grep 1e61` liefert keine Zeile.

**Fix:** Beacon-Einträge mit Zeitstempel versehen (TTL 3 s), abgelaufene entfernen;
eigenen Eintrag auf der Host-Seite nicht anklickbar machen; `peer_connected` /
`connection_failed` loggen.

---

## B2 — Fehlermeldung von `create_server` wird nicht sichtbar

`host_game()` gibt bei Fehlschlag einen String zurück, `start_lan_host()` zeigt ihn nur
in `lan_status` — im Log steht nichts. Deshalb war B1 so lange unsichtbar.

**Fix:** `print("[NET] host_game -> ", err)` und Zustand von `multiplayer_peer` loggen.

---

## B3 — Upgrade-Fenster pausiert die Welt für BEIDE Spieler (hoch) — BEHOBEN v1.35

**Beleg (alt):**
```
HOST  [LAN][136.47][HOST/1][SYNC] gesendet: ... paused=true
CLIENT [LAN][135.59][CLIENT/2][UPGRADE] Client oeffnet Karten (3) -> tree.paused=true
```
Während der Client seine drei Karten wählt, steht beim Host die Welt still.

**Fix (v1.35):** Im Co-op wird `get_tree().paused` gar nicht mehr gesetzt
(`_should_pause_for_cards()`); die Welt läuft auf beiden Geräten weiter. Der
Wählende ist bis zur Wahl unverwundbar, der Client meldet das per RPC
(`NetManager.c_send_busy` → `busy_received`), der Host schützt den Slot.
Einzelspieler pausiert weiter wie bisher.

---

## B4 — Client loggt keinen Sync-Empfang (mittel, Diagnose)

Der Client-Log enthält nur Upgrade-Zeilen, keine `[BUF]`- oder `[RECON]`-Ausgaben.
Damit ist nicht prüfbar, ob Interpolation und Reconciliation greifen.

**Fix:** sekündlich `[SYNC][CLIENT] pakete=N delay=ms resyncs=N` ausgeben.

---

## B5 — Version im Menü stimmt nicht mit der APK überein (klein)

Menü zeigt `v1.31 · Build 31`, installiert ist `versionName=1.32`.
Die Log-Zeile wurde korrigiert, die Anzeige nicht — sie wird aus einer anderen
Konstanten gespeist.

**Fix:** eine einzige Quelle (`APP_VERSION`) für Menü, Log und Export.

---

## B6 — Glocken-Symbol auf den Walzen (kosmetisch)

Das Symbol ist ein Dreieck mit Punkt, nicht als Glocke erkennbar.

---

## B7 — Pirat-Hut (Index 6) zu klein (kosmetisch)

Im Kontaktblatt nur ein weiß-roter Aufsatz, keine Augenklappe, kein Dreispitz.

---

## B8 — Hohe Latenz zwischen den Handys (Umgebung)

`ping` Handy→Handy: 170–350 ms RTT im 2,4-GHz-Band. Das erklärt gefühlte Verzögerung
auch bei fehlerfreiem Netcode.

**Maßnahme:** 5-GHz-Netz testen oder Kanal wechseln.

---

## B9 — Kein `peer_connected` im Log (mittel)

Beim erfolgreichen Lauf fehlt jede Verbindungsmeldung — der Übergang von
„verbinde" zu „im Spiel" ist im Log nicht nachvollziehbar.

---

## Bereits behoben (zur Abgrenzung)

- Hut-Icons zeigten andere Hüte als geliefert → Icons werden aus der echten Figur
  geschnitten.
- Hüte 0–9 wurden nie gezeichnet (Einrückung von `match hat:`).
- `clampi(rig, 0, 5)` klemmte die neuen Skins auf MARS-MARSCHALL.
- Skin wurde im LAN nicht übertragen (Profil-RPC ohne `rig`).
- Host-IP war im LAN-Fenster nicht sichtbar.

---

## B10 — Freeze bei gleichzeitig liegenden Spielern (kritisch, Fix eingebaut)

**Beleg:**
```
[CLIENT] Slot 1 downed=true hp=1 revive=0.0     (12x, 0,5-s-Takt)
[CLIENT] Slot 2 downed=true hp=0 revive=0.0     (Host auch downed)
[HOST]   [LAN] Peer getrennt - 1 Partner-Figur(en) entfernt, players=[1]
ERROR: Can't change this state while flushing queries.
       Use call_deferred() or set_deferred() to change monitoring state instead.
```

`it.monitoring = false` wurde mitten in der Physik-Abfrage gesetzt. Godot bricht die
Physik-Schleife dann ab, beide Geräte frieren ein.

**Fix (v1.33):** `it.set_deferred("monitoring", false)`.

---

## B11 — `downed=true` bei `hp=1` (hoch) — BEHOBEN v1.35

Client blieb 12 s bei `hp=1`, wurde aber als downed geführt. Zwei Zustände
widersprechen sich; die Wiederbelebung rechnet mit 0.

**Fix:** Beim Liegen wird `health` im Tick hart auf 0 gesetzt und so gesynct.
**Beleg (Testlauf `COMIC_LANTEST=downed`):**
```
[TEST][B11/B12] start: p1.health=1 downed={ 1: true } dist=60
[TEST] tick 1: p1.health=0 revive=0.5/5.0 downed=true
```

---

## B12 — `near=false` obwohl der Partner daneben steht (kritisch) — BEHOBEN v1.35

```
[HOST] Slot 1 liegt: rest=4.3s near=false revive=0.0/5.0 partner=[1, 2]
```
Über 12 Sekunden blieb `near` auf `false` und `revive` auf `0.0`. Die
Näherungsprüfung erkennt den Mitspieler nicht, deshalb startet die Leiste nie.

**Ursache:** `near` wurde nur über echte Knoten-Distanzen geprüft (95 px). Fehlte
dem Host die Client-Figur oder stand die Leiche am Rand, war das immer `false`.

**Fix:** Distanz 95 px über die Knoten **plus** Fallback über die zuletzt
gemeldete Partnerposition (110 px, solange frisch). `near`, `rest` und der
Revive-Stand stehen im Log, damit ein Fehlschlag sichtbar ist.
**Beleg:**
```
[LAN][11.51][SOLO/1][DOWNED] Slot 1 liegt: rest=4.5s near=true revive=0.0/5.0 partner=[1, 2]
[TEST] tick 10: p1.health=4 revive=0.0/5.0 downed=false
```

---

## B13 — Beide downed = Freeze statt Run-Ende (hoch) — BEHOBEN v1.35

Wenn Slot 1 und Slot 2 gleichzeitig liegen, gibt es niemanden zum Wiederbeleben.
Erwartet: Bildschirm „BEIDE BESIEGT", Rückkehr ins Menü.
**Fix:** `_tick_downed()` prüft jedes Mal, ob noch jemand steht; sonst Banner
„BEIDE BESIEGT" + `quit_to_menu()` nach 2 s.
**Beleg:**
```
[TEST][B13] beide downed -> tick
[LAN][GAME OVER] alle Spieler liegen - Run wird beendet
```

---

## B18 — Revive machte den Geretteten zum Zuschauer (kritisch, behoben v1.35)

**Symptom (aus dem Test aufgefallen):** Nach erfolgreichem Aufwecken stand der
Spieler mit `health=0`, war unsichtbar und wurde als Zuschauer geführt.

**Ursache:** `_revive_player()` löscht `downed`/`downed_time`. Derselbe Tick lief
danach weiter in den Zweig „`downed_time <= 0` → nicht mehr aufweckbar" und rief
`_make_spectator()`.

**Beleg vorher:**
```
[REVIVE] Slot 1 health=4 (max=6)
[TEST] tick 10: p1.health=0 revive=0.0/5.0 downed=false
```

**Fix:** Nach dem Revive wird der Tick für diesen Slot beendet; zusätzlich
Guard `if not downed.has(sl): continue` vor dem Timer-Zweig.

**Beleg nachher:**
```
[REVIVE] Slot 1 wieder im Spiel (health=4) - Zuschauer-Zweig uebersprungen
[TEST] tick 10: p1.health=4 revive=0.0/5.0 downed=false
```

---

## B19 — Glückswalze ließ sich im Shop nicht öffnen (kritisch, behoben v1.35)

**Symptom:** Klick auf „DREHEN" im Shop tat nichts.

**Ursache:** `slot_ui.gd` benutzte `bet_input` und `bet_slider`, ohne sie zu
deklarieren → das Script kompilierte nicht, `load()` lieferte ein defektes
GDScript ohne `new()`.

**Beleg:**
```
SCRIPT ERROR: Parse Error: Identifier "bet_input" not declared in the current scope.
   at: GDScript::reload (res://scripts/slot_ui.gd:179)
```

**Fix:** Feld, Regler und ±-Knöpfe (E1) gebaut und deklariert; Chancen-Tabelle
(E3) ergänzt.
**Beleg nachher:** `[SLOT][UI] geoeffnet bet=100 gold=99999`,
`[SLOT][UI] Chancen-Tabelle: 7 Symbole, Trefferquote=21.12 %`.

---

## Offen nach Runde 2

| Nr | Punkt | Status |
|---|---|---|
| B3 | Upgrade pausiert beide Spieler | behoben v1.35 |
| B11 | `downed=true` bei `hp=1` | behoben v1.35 |
| B12 | `near=false` verhindert Revive | behoben v1.35 |
| B13 | beide downed = Freeze | behoben v1.35 |
| B18 | Revive → Zuschauer | behoben v1.35 |
| B19 | Glückswalze öffnet nicht | behoben v1.35 |
| B1/B2/B4/B5/B9 | Lobby/Log/Version | offen |
| B8 | Latenz 2,4-GHz-WLAN | Umgebung |

---

# Runde 2 — Client-Gameplay (Logs vom 03.11., 18:00)

## B14 — Client simuliert Monster selbst (kritisch, BEHOBEN)

**Beleg:** `monster_ai.gd::_physics_process()` hatte **keine** Host/Client-Weiche.
Jedes Monster lief auf dem Client mit voller KI (Zielsuche, Bewegung, Fähigkeiten),
und gleichzeitig setzte der Host-Snapshot die Position neu.

Folgen:
- Monster „sind anders" (Client jagt eigene Ziele, Host andere)
- Teleportieren: lokale Bewegung + Snapshot-Korrektur im Wechsel
- Ruckeln und hohe CPU-Last auf dem Client

**Fix (v1.33):**
```gdscript
if gm != null and bool(gm.get("coop_client")):
    return
```
Position und Leben kommen ausschließlich vom Host.

---

## B15 — Relevanzfilter zu klein (hoch, BEHOBEN)

**Beleg:** `game_manager.gd:2596` — `distance_to(anchor) > 1650.0` verwarf Monster,
die der Host sah. Auf dem Client tauchten sie auf und verschwanden wieder.

**Fix (v1.33):** Radius **1650 → 2600 px**.

---

## B16 — Client-Log ohne Sync-Daten (mittel, BEHOBEN)

**Beleg:** `grep -c SYNC client_run.log` → **0**. Der Client loggte nur Upgrades.
Damit war nicht prüfbar, ob Snapshots ankommen.

**Fix (v1.33):**
```
[SYNC][CLIENT] mob-pakete=20 seq=41
```
alle 20 Pakete.

---

## B17 — Lag: drei Ursachen (Analyse)

| Ursache | Messwert | Maßnahme |
|---|---|---|
| RTT zwischen den Handys | 170–350 ms (2,4 GHz) | 5-GHz-Netz testen |
| Interpolationspuffer | 100 ms Verzögerung | auf 80 ms prüfen, sobald RTT < 120 ms |
| Upgrade-Fenster pausiert Welt | `paused=true` beim Host | nur lokal pausieren (B3) |
| Monster-Spitzen | `monsters=28` | Wellen-Spawn drosseln |

Die Client-KI (B14) hat zusätzlich CPU gefressen — nach dem Fix sollte der Client
deutlich ruhiger laufen.

---

## Offen nach Runde 2

| Nr | Punkt | Status |
|---|---|---|
| B3 | Upgrade pausiert beide Spieler | offen |
| B11 | `downed=true` bei `hp=1` | offen |
| B12 | `near=false` verhindert Revive | offen (kritisch) |
| B13 | beide downed = Freeze | offen |

---

# Runde 138 — Werkzeug- und Split-Fehler (alle mit Beleg)

Diese Punkte sind beim Modul-Split aufgefallen. Die Werkzeug-Fehler sind behoben,
die Spiel-Fehler stehen weiter offen.

## B20 — Golden-Master-Vergleich war einseitig normalisiert (hoch, BEHOBEN)

Beleg: `./tools/golden_check.sh` meldete bei unverändertem Code
`wpn2 rest_diff=8` und `mini rest_diff=6`:

```
< [WPN][DROP] waffe=shotgun seltenheit=epic  …
> [WPN][DROP] waffe=shotgun seltenheit=rare  …
< [BOSS][VISUAL] type=N key=boss_mini_jungle …
> [BOSS][VISUAL] type=N key=boss_mini_earth  …
```

Ursache: die Normalisierung lief nur über das **neue** Log, nicht über den Golden
Master; außerdem fehlten Zufalls-Token (Waffen-Seltenheit, Boss-Typ, Boss-Fähigkeit,
kumuliertes Gold). Damit war ein grüner Lauf Zufall — jede Blockabnahme wäre
wertlos gewesen.

Fix: `norm()` gilt für beide Seiten, maskiert `seltenheit`/`stufe` (R/N/E/L),
`key=boss_mini_*`, `kind=… name=…`, `gesamt N`. Danach 3× hintereinander 8/8 grün.

## B21 — `split_func.py` erzeugte nicht kompilierbare Wrapper (kritisch, BEHOBEN)

Beleg: `UiStyle.hud_panel_sb(...)` im Wrapper, aber `static func _hud_panel_sb(...)`
im Ziel → `SCRIPT ERROR: Parse Error: Function "hud_panel_sb()" not found`.

Drei Fehler in einem Werkzeug:
1. `a.name.lstrip("_")` im Aufruf, aber der Unterstrich blieb im Ziel.
2. `return <void-call>` in `void`-Funktionen → Parse-Fehler.
3. Mehrzeilige Signaturen (`_frond` mit 8 Parametern über zwei Zeilen) → `ValueError`.

Fix: gleicher Name in Wrapper und Ziel, void ohne `return`, Kopferkennung über
Klammerntiefe. Beleg: 139 Funktionen aus `texture_manager.gd` ohne einen
Script-Fehler verschoben.

## B22 — `move_consts.py` riss mehrzeilige Konstanten ab (kritisch, BEHOBEN)

Beleg nach dem Verschieben von `WEAPON_DATA`:

```
const WEAPON_DATA := WeaponsModule.WEAPON_DATA
	WeaponType.PISTOL: { "name": "pistol", … },     ← Rumpf blieb als Waisencode stehen
```

Ursache: der Sammler stoppte, sobald die Klammerntiefe einer Zeile 0 ergab
(`{ … },` netto 0). Fix: Tiefe startet bei 1 und wird über alle Zeilen geführt.
`player_controller.gd` musste aus `backup/scripts_v136/` neu aufgebaut werden;
danach `wpn2` grün.

## B23 — Enums sind nicht über eine Instanz erreichbar (mittel, BEHOBEN)

Beleg: `SCRIPT ERROR: Parse Error: Identifier "GameState" not declared` in
`core/upgrades.gd`, ebenso `MonsterType` und `WeaponType`.

`host.GameState` funktioniert in GDScript nicht (Enums sind Klassen-Konstanten).
Fix: Enum in jedes Modul spiegeln, das es benutzt — **Reihenfolge muss identisch
bleiben**, sonst vergleichen die Module gegen falsche Zahlen.

## B24 — Boss-HP läuft ins Negative (mittel, OFFEN)

Beleg aus `mini`-Rohlog:

```
[BOSS][PHASE] Volt-Spule ueberladen: hp=-84927/72 speed=N cd=N
```

Der Boss hat 72 max. HP, der Wert steht bei −84 927. Kein Absturz, aber die
Phasen-/HP-Leiste arbeitet mit unsinnigen Zahlen (Überlauf oder fehlende Klemmung
in `take_damage`). Nicht durch den Split verursacht — der Log stammt aus dem
unveränderten Spielcode.

## B25 — APK nur debug-signiert (mittel, OFFEN — braucht Vince)

Beleg: `./Godot.exe --headless --path project --export-release "Android" …`

```
WARNING: Codesignierung: Release-Keystore konnte nicht gefunden werden, Export fehlgeschlagen.
```

Im Projekt existiert kein Release-Keystore (weder in `export_presets.cfg` noch als
Datei). `dist/ComicShooter-v1.38.apk` ist deshalb mit `--export-debug` und dem
vorhandenen `debug.keystore` signiert: installierbar, aber nicht für den Play Store.

## B26 — Sammlung: ZURUECK unerreichbar, Seite laeuft unten aus dem Bild (hoch, BEHOBEN)

Beleg vorher (`screenshots/v139/coll2-voll.png`, Profil 10/25/29): die Sektion
HUETE ist am unteren Rand abgeschnitten, der ZURUECK-Knopf liegt komplett
ausserhalb des Schirms. Die Sammlungsseite hatte **keinen** Scrollbereich -
sie wurde direkt in die VBox der Seite gehaengt. Messung dazu:

```
[COLL2][6] scroll_max=0 ... erreichbar=false   (vor dem Fix)
```

Fix: Inhalt liegt jetzt in einem `ScrollContainer` (`CollectionScroll` ->
`CollectionInner`), beim Oeffnen wird auf 0 zurueckgescrollt.

Beleg nachher:

```
[COLL2][6] scroll_max=1402 seite_h=1402 viewport=[P: (31, 111), S: (1858, 938)]
           button=[P: (786, 960), S: (340, 90)] erreichbar=true
```

Screenshot `screenshots/v139/coll2-unten.png` zeigt HUETE 29/29 **und** ZURUECK.

## B27 — Gemeldeter Sammlungs-Absturz: auf dem Desktop nicht reproduzierbar (hoch, OFFEN)

Zwei Laeufe auf dem interaktiven Weg (Menue-Kachel `NavTile_coll`), beide ohne
einen einzigen `SCRIPT ERROR`:

| Lauf | Inhalt | Ergebnis |
|---|---|---|
| `COMIC_LANTEST=coll` (`logs_m4.log`) | 5x oeffnen/schliessen, Hutwechsel, ZURUECK | `[COLL][ENDE] fehler=0` |
| `COMIC_LANTEST=coll2` (`logs_m4b.log`) | volles Profil (10/25/29), Doppelklick, Schnellwechsel | `[COLL][ENDE] fehler=0` |

Knotenzahl bleibt konstant (`[COLL][PERF] ... delta=0`), Kindzahl identisch
(`[COLL][ZUSTAND] kinder=426 ref=426 gleich=true` in allen 5 Laeufen).

Damit ist der Absturz **nicht** im Sammlungscode nachweisbar. Zwei Kandidaten
bleiben, beide nur auf dem Geraet entscheidbar:

1. **B26** (ZURUECK unerreichbar) - der Spieler kommt nicht mehr raus, das
   sieht wie ein Haenger/Absturz aus.
2. **B28** (1,3 s Blockade beim ersten Oeffnen) - auf einem schwaecheren Handy
   deutlich laenger; Android zeigt dann "App reagiert nicht".

Naechster Schritt: Geraetelog (`adb logcat | grep -i godot`) beim Oeffnen der
Sammlung. Ohne Geraet bleibt der Punkt offen.

## B28 — Sammlung: erster Aufbau blockiert 1,3 s (mittel, OFFEN)

```
[COLL][2] offen nr=1 ... aufbau_ms=1323
[COLL][2] offen nr=2 ... aufbau_ms=24
[COLL][2] offen nr=4 ... aufbau_ms=534    (nach Hutwechsel: neue Texturen)
```

Der erste Aufbau erzeugt 64 Kombinationstexturen (10 Farben x 25 Skins x
29 Huete, jeweils in der aktuellen Kombination) und baut 426 Knoten in einem
Frame. Die Wiederholung ist mit 24 ms unauffaellig. Fix-Option: Texturen beim
Oeffnen in mehreren Frames nachziehen (Chunking) - nicht Teil von v1.39,
aber in B27 als Absturz-Kandidat notiert.

## B29 — Hut-Sitz war nur eine y-Verschiebung (hoch, BEHOBEN)

Beleg: `HEAD_ANCHOR` = ein Wert je Rig, Hutgröße fix. Gemessene Kopfformen
(`COMIC_LANTEST=headmeas`) wichen deutlich ab:

```
[HEAD] rig=8 name=ALIEN   top=9  cx=32 w=33   (alter_anker=24)
[HEAD] rig=7 name=WIKINGER top=4 cx=32 w=29   (alter_anker=22)
[HEAD] rig=0 name=STANDARD top=11 cx=32 w=25  (alter_anker=21)
```

Anker 24 beim Alien heißt 7 px zu tief gegenüber "Kopfoberkante + 8". Dazu kam
fehlende Skalierung: ein 18-px-Hut auf einem 33-px-Kopf.

Fix: `_head_metrics()` misst die Kopfform aus dem gezeichneten Bild,
`HAT_SEAT` gibt je Hut einen eigenen Sitz + Faktor, `RIG_HAT_ADJ` fängt den
Alien ab (Augen liegen dort oben). Beleg: `[HAT][SITZ] ERGEBNIS paare=700
kopfpaare=475 fehler=0`, Tabelle `tools/hat_fit.md`.

## B30 — STROHHUT war eine rote Mütze (mittel, BEHOBEN)

Beleg: alter Zeichnencode für Hut 7 (`_draw_hat`, case 7) nutzte
`Color(0.90, 0.35, 0.30)` — dieselbe Rotfamilie wie die Wollmütze. Ein
Strohhut war damit nicht erkennbar ("rote Mütze ist als Krone gelistet" ist
vermutlich dieser Eintrag).

Fix: strohgelbe breite Krempe + flache Krone + Band. Messung:
`[HAT][C6] wollm hue=211 w/h=0.85 | stroh hue=28 w/h=1.61 |
farbton_diff=177 (Ziel >=25) form_diff=47% (Ziel >=20) ok=true`.

## B31 — KAPPE: Kugel + rechteckiger Balken (mittel, BEHOBEN)

Beleg: alte Zeichnung `_disc(32,14,9)` + `_rect(37,15,12,5)` — der "Schirm"
war ein Balken, der seitlich aus jedem Kopf ragte (bei Rig 0 Überstand 8 px,
Grenze 4 px).

Fix: Kappe neu (Kuppel, Mittelnaht, kurzer Schirm 5,4 × 2,0, Knopf). Beleg:
`[HAT][SITZ] hut=1 rig=0..24` — Überstand 0 px (Ausnahme Rig 20: 1 px).
Kontaktblatt `screenshots/v139/hats_kappe_25.png`.

## B32 — Debug "ALLES FREISCHALTEN" liess die Skins gesperrt (mittel, BEHOBEN)

Beleg: `debug_unlock_all()` (game_manager) schaltete Farben, Hüte, Karten und
Seasons frei, rief aber nie `unlock_rig()` auf — `unlocked_rigs` blieb
unverändert. Der Knopf im Debug-Fenster wirkte deshalb nur halb.

Fix: Schleife über `RIG_NAMES.size()` + Zählausgabe.
Beleg: `[DEBUG][UNLOCK] rigs=29/29 huete=29/29 farben=10/10`, Sammlung danach
`[COLL][ZAEHLER] … skins=29/29`.

## B33 — Eigener Fehler: HAT_RARITY auf 33 verlängert (mittel, BEHOBEN)

Beim Anhängen der Raritäten für die vier neuen Skins traf die Textersetzung
auch die `HAT_RARITY`-Liste: 33 Einträge bei 29 Hüten. Folge wäre ein
Raritäts-Versatz in der Sammlung (Hut 26–28 hätten die Werte der falschen
Zeile gezeigt).

Gefunden vom eigenen Check, nicht durch Zufall:

```
[RIG][CHECK] names=29 rarity=29 arme=28 hats=29 hat_rarity=33
[RIG][CHECK] FEHLER: Laengen weichen ab
```

Fix: Liste auf 29 zurückgeschnitten, `RIG_RARITY` (beide Spiegel: `core/profile.gd`
und `game_manager.gd`) auf 29 erweitert. Danach:
`[RIG][CHECK] names=29 rarity=29 arme=29 hats=29 hat_rarity=29`.

## v1.40 — Runden-Modus (4.11.2026)

| # | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **W-B1** | mittel | Sound-Keys `wave_start`, `wave_clear`, `buy`, `boss_warning` existieren nicht → stumme Wellen | `[SND][FEHLER] key=wave_start fehlt` (5×) | **behoben** — auf vorhandene Keys (`levelup`, `chest_win_common`, `pickup`, `boss`) umgestellt |
| **W-B2** | hoch | Shop-Modul als `Node` deklariert, ist aber `RefCounted` → Shop öffnet nicht | `Invalid assignment of property or key 'rm' with value of type 'RefCounted'` | **behoben** — `var rm = null` (untypiert) |
| **W-B3** | hoch | Runde 1 startete nach dem Run-Start nicht (Modul erst beim ersten Icon-Klick initialisiert) | `[WAVE][RUN] modus=2 runde=0 aktiv=false` | **behoben** — `_rm().reset()` + `start_round()` nach dem Spieler-Spawn |
| **W-B4** | mittel | Korruptionszonen liefen im Runden-Modus mit (nur Monster gewünscht) | `[ZONE] spawn` im Modus | **behoben** — `num_zones = 0` bei `game_mode == 2` |
| **W-B5** | klein | Boss-Log zeigte `typ=<null>` | `[WAVE][BOSS] runde=5 typ=<null>` | **behoben** — Typnummer + Name (`MINI-BOSS`/`BOSS`) |
| **W-B6** | klein | Ökonomie war zu locker (Modell: 6.512 Münzen Endstand) | `[WAVE][ECO][SIM] ENDE stand=6512` | **behoben** — Kill-Münzen 0,14→0,09, Bonus 18+6,5r→12+4,5r, Preisfaktor 0,06→0,075; Endstand 928 |
| **W-B7** | klein | Icons im HUD wirkten ausgegraut (dunkler Comic-Rahmen als Füllung) | Screenshot `intermission.png` v1 | **behoben** — eigener `StyleBoxFlat` in Kategoriefarbe |


## v1.41 — Inhalt, Bosse, Skins (4.11.2026)

| # | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B1** | hoch | Im RUNDEN-Modus wurde die HP-Kurve der Runde **nicht** angewendet: normale Monster bekamen die Endlos-Wellen-Tabelle (`wave_balance()` mit `wave=0`), R30 war damit so leicht wie R1 | kein `apply_wave_mult` mit `Rounds.hp_mult` im Log; `[WAVE][START] hp_ziel=1797` vs. tatsächliche Monster-HP | **behoben** — `spawn_api.gd` nimmt im Modus 2 `Rounds.hp_mult_spawn()` |
| **X-B2** | hoch | Boss-Beschwörungen (`spawn_boss_minions`) zählten als Kills → Runde 10 endete mit `getoetet=49/30` | `[WAVE][ENDE] runde=10 getoetet=49/30` | **behoben** — geplante Monster werden markiert, `alive`/`killed` kommen aus dieser Liste |
| **X-B3** | mittel | Boss-HP überschritt die Runden-HP (R5: Boss 90 HP bei 83 HP Runde) → Runde stand | `[WAVE][BOSS] runde=5 typ=23 MINI-BOSS hp=90`, `[WAVE][START] runde=5 hp_ziel=83.2` | **behoben** — B2-Drossel (Faktor 0,55, Deckel 45 %) |
| **X-B4** | mittel | Nach dem Entfernen von 18 Skins/4 Hüten zeigten gespeicherte Profile auf falsche Einträge (Index-Migration fehlte) | `[PROFILE][MIGR] rig=SCHATTEN-KATZE->STANDARD` | **behoben** — `PROFILE_VERSION=4`, IDs werden **vor** dem Index aufgelöst |
| **X-B5** | mittel | Statistik-Seite war im Spiel eine Sackgasse (hing an `start_screen`, Spiel lief ungepausett weiter) | vorher kein `[STATS][UI]`-Log, kein Rückweg | **behoben** — eigenes Overlay über `ui_manager`, `pause=true`, ESC + Knopf |
| **X-B6** | klein | Startseite verzog sich, sobald der GRAD-Knopf sichtbar wurde (`row3` wuchs) | `box` wuchs von 1181 auf 1213 px | **behoben** — feste Mindestbreite 1180 + `SHRINK_CENTER`, Knopf immer sichtbar (deaktiviert) |
| **X-B7** | klein | Shop-Karten hatten nur Text, keine Symbole | Screenshot v1.40 | **behoben** — 64×64-Icon links, Preiszeile mit Münze, Waffen mit Seltenheitsrahmen, neues `icon_revive` |
| **X-B8** | klein | Gemessene Vollmasken-IoU taugt nicht als Silhouetten-Maß (alle aufrechten Figuren 0,74–0,93) | `tools/rig_iou.md` (v1.39) | **dokumentiert** — Kontur-IoU als Maß, siehe `docs/SKIN_SLOP.md` |

### Runde 141b — Skin-Neuzeichnung (4.11.2026)

| # | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B9** | hoch | **Keine Gesichter:** Augen waren 1 Pixel (`_px`), bei STANDARD und COMIC-HELD zusätzlich 4 px nach rechts versetzt, bei NINJA auf der Stirn statt im Maskenstreifen | `screenshots/v141/skins_big.png` (v1: leere Gesichter), Code `_px(img, 36, 23, OUTLINE)` / `_px(img, 40, 23, OUTLINE)` | **behoben** — `_eye_pair()` (Augapfel + Pupille + Glanzpunkt), `_mouth()`, `_face_pass()` je Skin |
| **X-B10** | hoch | **Alles flach eingefärbt:** Körperflächen waren reine Spielerfarbe ohne Licht/Schatten | v1-Sammelbild, alle Figuren einfarbig | **behoben** — `_shade_body()`, Faktor 0,66–1,20 nur auf Stoff/Hose; Farbprüfung danach weiter **170/170** grün |
| **X-B11** | mittel | NINJA: Schal war ein Balken über den ganzen Körper (`_rect(14, 30, 36, 6)`) und wirkte wie ein Gewehr | `skins_big.png` v1 | **behoben** — Kragen 22 px + Zipfel |
| **X-B12** | mittel | ROBOTER zu 62 % Spielerfarbe → sah aus wie STANDARD | `metal.lerp(shirt, 0.62)` | **behoben** — 40 %, Kern bleibt Akzent |
| **X-B13** | mittel | Konzeptzeichner: Kapuze/Nemes/Schakel lagen **über** dem Gesicht → gesichtslose Figuren | `konzept_legendary.png` v1 (Templer, Pharao, Anubis) | **behoben** — `_gear_back()` (hinter dem Gesicht) und `_gear_front()` getrennt |
| **X-B14** | mittel | Dreispitz war ein Teller mit Goldbalken quer über den Augen | `konzept_epic.png` v1 (Kapitän, Geisterpirat) | **behoben** — Krone + hochgeklappte Krempe + Goldpip |
| **X-B15** | klein | Enterhaken war ein „P" (Ring + Strich) | `konzept_epic.png` | **behoben** — J-Form |
| **X-B16** | klein | Schulterstacheln stachen durch den Kopf (Scheitelpunkte bei y=17) | `konzept_epic.png` (Gletscher-Panzer) | **behoben** — auf Schulterhöhe (y=21…32) |
| **X-B17** | klein | Fahne lag über dem Gesicht des Goldenen Generals | `konzept_legendary.png` | **behoben** — Stange links, Tuch neben dem Körper |
| **X-B18** | klein | Schakel-Ohren wurden am Bildrand abgeschnitten (y = −2) | Skin 13 im Kontaktblatt | **behoben** — Ohren ab y=2 |
| **X-B19** | klein | `RIG_RARITY` existierte **zweimal** (profile.gd und game_manager.gd); die erste Korrektur traf nur eine Kopie → `names=17 rarity=11` | `[RIG][CHECK] names=17 rarity=11` | **behoben** — beide Tabellen auf 17 Einträge |

---

## Runde 142 — Bugfixes & Balance (4.11.2026)

| # | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B20** | **kritisch** | **Pause → EINSTELLUNGEN warf ins Startmenü.** `_open_settings_page()` rief immer `_close_pages()`, das mit `start_screen.show()` endet; der Run galt als verlassen, der Pause-Overlay war weg und `get_tree().paused` blieb stehen → weder weiterspielen noch neu starten möglich | vorher: hinter den Einstellungen lag das Startmenü; `[MENU][SETTINGS]` existierte nicht | **behoben** — `settings_origin` (`menu`/`pause`/`run`), Seite liegt jetzt als Kind des UI-Managers (nicht mehr unter `start_screen`), `_close_settings_page()` kehrt zum Aufrufer zurück, ESC = ZURÜCK. Beleg: `[MENU][SETTINGS] origin=pause start_screen_sichtbar=false pause_offen=false paused=true`, `[PAUSE][RESUME] welle=0 hp=5/5 muenzen=0 paused=false gleich=true`, `screenshots/v142/pause_nach_settings.png` |
| **X-B21** | hoch | **Waffen-Seltenheiten waren nicht spürbar:** `WEAPON_RARITY` skalierte nur `damage/reload/mag/speed`, **nicht** `cooldown` → jede Stufe feuerte gleich schnell | `[WPN][STATS] stufe=common cooldown=0.100` … `legendary 0.062` fehlte | **behoben** — `cooldown`-Faktor 1.00/0.88/0.76/0.62 + größere Abstände bei Schaden/Nachladen/Magazin; RPM 600/682/789/968, DPS legendary/common 3,2–4,2×, `[WPN][DPS] monoton=true` |
| **X-B22** | mittel | **Heiltrank heilte 2 LP sofort** statt 3 Herzen über Zeit; zweiter Trank verpuffte | `use_potion()` rief `heal(2)` | **behoben** — Regeneration 1 LP je 1,5 s (max. 3), Warteschlange für einen zweiten Trank, pulsierendes Herz über dem Spieler. Beleg: `[TRANK][REGEN] start hp=2/5 ziel=5 dauer=4.5s` → `(3/5) (4/5) (5/5)` → `ende hp=5/5 ticks=3 rest=0`, `queue=1` |
| **X-B23** | hoch | **LEICHT war ab Runde 8/9 zu hart:** die Monsterzahl war für alle Schwierigkeiten identisch (nur HP/Preis/Münzen skalierten) | R8 = 28 Monster auf jeder Stufe | **behoben** — `DIFFICULTY.anzahl` (0,65 / 1,00 / 1,15), `Rounds.spawn_groups_for()`, Obergrenze 34 (LEICHT). Beleg: `[RUNDEN][ZAHL] runde=8 leicht=16 normal=28 hart=30`, 15-Runden-Lauf LEICHT: alle `getoetet == total`, `dauer` max. 9,4 s |
| **X-B24** | mittel | **Biom wechselte mitten im Run** (Reise-Map nach Score, feste Maps über den `progressive`-Flag nicht erzwungen) | `game_manager.gd:_check_biome()` las `BIOME_STEPS` nach Score | **behoben** — Wechsel nur an Rundengrenzen nach festem Plan (1/6/11/16), feste Maps bleiben fest. Beleg: `[BIOME][WECHSEL] runde=6 von=meadow nach=desert`, `[BIOME][WECHSEL] anzahl=0 biome=mars` ×15 |
| **X-B25** | mittel | **Charakter-/Sammlungsseite zeigte alte Skin-Indizes** (nach 29→11→17) und das Kachelraster lief über den Rand | `unlocked_rigs.duplicate()` ungeprüft, `grid.columns = 5` ohne Scroll | **behoben** — `[PROFILE][CLAMP] feld=rigs entfernt=4 gueltig=17`, Raster im ScrollContainer (ganzzahlige Reihen), `[CHAR][GRID] kacheln=17 sichtbar=15 scroll=true overflow=false` |
| **X-B26** | klein | Musik war zu leise (−19/−22 dB) und es gab nur zwei Tracks | `sound_manager.gd:_music_player.volume_db = -19.0` | **behoben** — 7 Tracks (2 Menü, 4 Spiel, Boss), −12/−15 dB + Regler (80 % = −15,6 dB), 0,6 s Fade, Boss-Track. Bauzeit aller Tracks beim Start ~2,4 s (einmalig, im Ladebildschirm) |
| **X-B27** | klein | Trank-Beschreibung versprach weiter „Heilt 2 Herzen" / „heilt 40 LP" | `wave_shop.gd:46`, `shop_logic.gd:32` | **behoben** — „Regeneriert 3 Herzen über 4,5 s (Taste Q)" + EN-Übersetzung in `loc.gd` |
| **X-B28** | mittel | **Golden-Master `upg` ist zeitabhängig flatterhaft** (nicht durch v1.42 verursacht): `[TEST][H] Welt laeuft: 0/1 Monster in 0,5 s bewegt` und Toast-Zähler wechseln je nach Frame-Reihenfolge | 3 Läufe: 1× grün, 2× rot mit wechselnden Zeilen | **offen (Test, kein Gameplay-Bug)** — `upg` prüft Bewegung in 0,5 s Wanduhr; auf einem ausgelasteten Rechner unterschreitet die Simulationszeit die Schwelle. Fix-Plan: Simulation über `Engine.time_scale` oder mehr Frames statt Wanduhr messen |

Golden-Master-Basis: die drei Modi `loc2`, `char`, `wpn2` wurden wegen **neuer Belegzeilen** (P2: `[WPN][STATS]`/`[WPN][STATS-UI]` mit RPM, P12: `[CHAR][GRID]`) neu gesetzt; der Altstand liegt in `backup/golden_v136_141/`. Kein Verhaltensunterschied — es sind ausschließlich zusätzliche Logfelder.

## Runde 143 — Recon zu den gemeldeten Fehlern (4.11.2026)

Belege aus `COMIC_LANTEST=tap143` (`logs_tap143.log`) — echte Klicks über
`get_viewport().push_input`, nicht `emit_signal`.

| ID | Schwere | Befund | Beleg | Fix-Plan |
|---|---|---|---|---|
| **X-B29** | **kritisch** | **Einstellungen sind eine Sackgasse** (für den Spieler „das Spiel crasht beim Antippen"): der Seiteninhalt ist 1189 px hoch, der Canvas 1080 px. Der Knopf `ZURUECK` liegt bei y 1143–1219 und ist damit **komplett unter dem Bildrand**; danach bleibt die Seite über der Startseite liegen und kein Knopf reagiert mehr | `[LAYOUT] einstellungen inhalt=(1076,1189) viewport=(1920,1080) ueberlauf=true fehlt_unten=109` · `[TAP] SETTINGS_ZURUECK rect=(30,1143)-(1890,1219) sichtbar_im_bild=false` · danach `[TAP] CHARAKTER -> NICHT SICHTBAR` | **offen** — SPEC v1.43 S1/S2: Scrollcontainer + fester Fuß, Seite auf ≤ 1000 px verdichten |
| **X-B30** | hoch | **Musikauswahl für den Spieler unerreichbar:** Regler liegt im überlaufenden Bereich, Treffer landen auf dem Info-Label. Die Logik selbst ist in Ordnung | `[TAP] slider wert=25 music_volume=25` (Logik ok) bei gleichzeitigem `ueberlauf=true fehlt_unten=109` | **offen** — SPEC v1.43 S3: Regler + −/+ Knöpfe (88×88) im sichtbaren Bereich |
| **X-B31** | mittel | **Auswahlfeld Skins/Hüte/Farben klebt am linken Rand** (v1.42-Regression): das Raster sitzt in einem `ScrollContainer`, und `SIZE_SHRINK_CENTER` hat dort keine Wirkung — ein ScrollContainer legt sein Kind immer bei (0,0) ab | `[LAYOUT] wahl_raster links=60 rechts=1710 breite=150 viewport=1920 versatz=true` | **offen** — SPEC v1.43 S4: zentrierender Container um das Raster |
| **X-B32** | mittel | **Schaumring um Flusssteine pulsiert ohne Bezug zum Wasser** — 3,5 % der grauen Steinpixel ändern sich zwischen zwei Frames 0,8 s auseinander. Zusätzlich liegen die Flusssteine als Deko **über** der Wasserfläche (`z_index -7` gegen `-8`) | Pixel-Diff `wasser_a.png`/`wasser_b.png`: `steinpixel=7608 veraendert=270 (3.5%)` gegen `wasserpixel 71,8 %` | **offen** — SPEC v1.43 S5: Schaum an Steinen statisch, Flusssteine entfernen oder ins Wasserbett |
| **X-B33** | hoch | **Start blockiert den Haupt-Thread** (auf dem Gerät „hängt beim Antippen"): 20,5 s bis zum ersten Bild auf dem Emulator; Texturen (~6–15 s) und seit v1.42 zusätzlich die Musik-Synthese (2,4 s) laufen am Stück | `ActivityTaskManager: Displayed com.vince.comicshooter … : +20s500ms` · `[SFX][MUSIK] … bauzeit_ms=3376` | **offen** — SPEC v1.43 S6.2: Boot-Arbeit in Häppchen über Frames, Ladebalken zeigt echten Fortschritt, `max_block_ms <= 120` |
| **X-B34** | mittel | **Godots `print()` ist auf dem Gerät nicht auswertbar** — im `logcat` finden sich keine `[BOOT]`/`[TAP]`-Zeilen, dadurch sind Gerätetests blind | `adb logcat -d | grep "\[BOOT\]"` → leer, nur `I godot : Godot Engine v4.7.2` | **offen** — SPEC v1.43 R5.3: Log zusätzlich nach `user://` schreiben, per `adb pull` holen |
| **X-B35** | mittel | **Dateigrößen weit über der Grenze**: `game_manager.gd` 4515, `lan_diag_tmp.gd` 4381, `ui_manager.gd` 3674 Zeilen (Ziel ≤ 1500) | `wc -l` | **offen** — SPEC v1.43 R1/R2/R3: Module nach bestehendem Muster (`extends RefCounted`, `var host`), Golden Master nach jedem Schnitt |


---

## Runde 143 — Ergebnis (Arbeitsstand nach Umsetzung)

Alle Belege sind Zeilen aus echten Läufen (`COMIC_LANTEST=…` auf dem Desktop bzw.
`adb logcat` auf dem Emulator `Medium_Phone_API_36.1`, SwiftShader).

| ID | Status | Beleg |
|---|---|---|
| **X-B29** | **behoben** | `[LAYOUT] einstellungen breite=1920 inhalt=(1482,604) canvas=(1920,1080) scroll=true knopf_fuss=true knopf_y=974 knopf_h=76 ueberlauf=false` · `[TAP] seite=einstellungen knopf=ZURUECK rect=(790,974)-(1130,1050) sichtbar_im_bild=true ergebnis=ok` · danach `[WALK] zurueck_startseite OK` und alle 6 Startknöpfe `sichtbar=true`. Auf dem Gerät: `[MENU][SETTINGS] zurueck=menu`, App lebt (`pidof` identisch) |
| **X-B30** | **behoben** | `[TAP] lautstaerke_minus wert=75` / `[TAP] lautstaerke_plus wert=80` (Gerät) · Regler 88 px hoch, Spur 620 px, `regler_rechts=1266` bei 1920er Canvas · `[SFX][MUSIK] regler=30 db=-27.6` → `80 db=-18.6` → `100 db=-15.0` (monoton) · Profil: nach Neustart `[SFX][MUSIK] regler=80 (profil)` |
| **X-B31** | **behoben** | `[LAYOUT] wahl_raster feld=skin links=561 rechts=561 versatz=false` · Hut: `kacheln=25 sichtbar=15 scroll=true overflow=false` · Klick: `[TAP] wahl feld=hat idx=6 uebernommen=true p_hat=6 (vorher 1) overlay_zu=true` |
| **X-B32** | **behoben** | `[ART][WASSER] steine_im_fluss=0 foam_steine=keine foam_ufer=puls` · `[ART][WASSER] steinpixel_diff=0.0% grau_proben=11459 geaendert=4 ziel=0.5` |
| **X-B33** | **behoben (Zielzeit auf dem Emulator nicht erreicht)** | Desktop: `[BOOT] haeppchen=103 max_block_ms=133 (grösster Block: tex) bis_hier_ms=4041` und `[BOOT][0c] ui gebaut ms=3229`. Emulator: `[BOOT][0c] ui gebaut ms=27284` (v1.42 brauchte dort allein für die Texturen 53788 ms). Der Emulator rechnet ohne GPU (SwiftShader); die 12-s-Marke aus S6.1 ist dort nicht erreichbar, der Ladebalken läuft aber sichtbar mit |
| **X-B34** | **behoben** | Godots `print()` landet auf dem Gerät unter dem Logcat-Tag **`godot`** (nicht `[BOOT]`-gefiltert): `adb logcat -d | grep -F " godot "` zeigt `[BOOT][0c] ui gebaut ms=…`, `[TAP] lautstaerke_minus wert=75`, `[TAP] back_key …`. Kein eigener Dateilog nötig |
| **X-B35** | **offen** | `wc -l`: `game_manager.gd` 4560, `ui_manager.gd` 3770, `lan_diag_tmp.gd` 4990 — die Refactors R1–R3 sind **nicht** umgesetzt (siehe SPEC Status). Alle funktionalen Punkte haben Vorrang bekommen; der Umbau ist der nächste Schritt und braucht den Golden Master nach jedem Schnitt |

### Neue Befunde aus dem Gerätetest (Runde 143)

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B36** | **kritisch** | **Android-Zurueck beendete die App.** Auf jeder Unterseite (Sammlung/Karten/Shop) schloss die Hardware-Taste das Spiel komplett — für den Spieler ein Absturz | `ActivityManager: Process com.vince.comicshooter (pid …) has died` direkt nach `input keyevent KEYCODE_BACK` | **behoben** — `config/quit_on_go_back=false` + `_handle_back_button()` (Einstellungen → zu, Pause → zu, Unterseite → Menü, im Run → Pause, im Hauptmenü → ignoriert). Beleg: `[TAP] back_key seiten_geschlossen=1`, `[TAP] back_key im_hauptmenue=true (ignoriert)`, App lebt |
| **X-B37** | **kritisch** | **Absturz im Audio-Track-Thread** (SIGSEGV) ~11 s nach dem Menüstart, reproduzierbar auf dem Emulator. Ursache: der Engine-Loop der Musik (`LOOP_FORWARD`) setzte im Audio-Thread neu an | `F DEBUG: name: AudioTrack >>> com.vince.comicshooter <<< · signal 11` (2×) | **behoben** — Tracks laufen ohne Engine-Loop, Neustart verzoegert im Hauptthread. Beleg: `[SFX][MUSIK] neustart track=menu_1 (Hauptthread)` alle ~11 s, Prozess lebt > 10 min |
| **X-B38** | klein | **Run-Übersicht auf breiten Displays (2400×1080) verzogen**: Kopf-Panel über die volle Breite, HELD-Chip klebte am linken Rand | Emulator-Screenshot `screenshots/v143/emu_16_uebersicht.png` | **behoben** — alle Blöcke `SIZE_SHRINK_CENTER` (`_confirm_refresh`) |
| **X-B39** | mittel | **Musik-Neustart war im Signal-Handler** (`_on_music_finished` rief `play()` direkt) — Arbeit im Audio-Thread | Code + X-B37 | **behoben** — `call_deferred("_restart_current_music")` |

---

## Runde 144 — Recon zum Debug-Fenster (5.11.2026)

| ID | Schwere | Befund | Beleg | Fix-Plan |
|---|---|---|---|---|
| **X-B40** | **kritisch** | **Debug-Fenster friert das Spiel beim Öffnen des Kachelrasters ein** — `debug_panel._build_grid()` zeichnet 425 Kombinationen (17 Rigs × 25 Hüte) in EINEM Frame. Desktop 19,6 s, Handy über der ANR-Schwelle (5 s) → Android beendet die App. Genau das gemeldete „teilweise abstürzen". Kein Script-Fehler im Log, weil es reine Rechenzeit ist | `COMIC_LANTEST=dbg144` → `[DBG][TEST] raster kinder=425 ms=19567` (alle anderen Panel-Knöpfe: Spawn 20 Mobs, Unverwundbar, Freischalten, Weltwechsel, Neustart ohne Fehler) | **behoben (5.11.)** — Raster baut in Häppchen (selbstregelnd 1–24 Kacheln/Frame, Ziel 25 ms), Fortschrittszeile, Abbruch bei Panel-/Raster-Schließen, Kacheln werden mit `free()` sofort freigegeben. **Ursache war nicht die Zahl der Buttons, sondern das Neuzeichnen:** `GenCharacters._make_player_rig()` baute je Kachel den ganzen Körper neu (21 ms) und rechnete die Hut-Ebene bilinear um (2,7 ms). Jetzt drei Caches (Körper je Rig/Farbe, Kopfform, Hut-Ebene) + Rohdaten-Resampling. Belege: `[DBG][BENCH] rig_ohne_hut_ms=0 rig_mit_hut_ms=5` (vorher 21/26) · `[DBG][RASTER] fertig kacheln=425 frames=165 gesamt_ms=4646 block_max_ms=126` (vorher 19567 ms in einem Frame) · `[DBG][RASTER] abgebrochen=true grund=panel_zu kacheln=40` · `speicher knoten_start=362 knoten_ende=362 diff=0` · Optik unverändert: `COMIC_LANTEST=hatcmp144` → `ungleiche_paare=108` mit `max=0.0 mean=0.0` (nur vollständig transparente Pixel) |
| **X-B41** | mittel | **Umtausch-Knöpfe im Shop ohne Hierarchie**: drei gleich aussehende 400×70-Knöpfe „UMTAUSCHEN" mit Icon im Text, je eine eigene Karte | `shop_page.gd:_gem_card()` Zeile 371–382, `_flash_card()` je Streifen | **behoben (5.11.)** — Umtausch ist ein Panel mit Streifen (Goldbetrag + Münze → Diamant + Stein → ein `TAUSCHEN`-Knopf 240×64 rechts), Trennlinie als Akzentlinie, kein Symbol im Knopftext. Belege: `[SHOP][UMTAUSCH] panel=true streifen=2 trennlinien=1`, `idx=0 streifen=true knopf=240x64 icon_im_text=false gold=1000 gems=1`, echte Buchung `[SHOP][TAUSCH] gold_vorher=100000 nachher=99000 gems=1 ok=true` |
| **X-B42** | klein | **Kisten-Laufband startet langsam**: 45 % der Dauer wird beschleunigt (`EASE_IN`), erst dann schneller — der Nutzer will sofortige Höchstgeschwindigkeit und Auslaufen | `chest_ui.gd:_animate()` `t1 = duration * 0.45 … TRANS_QUAD/EASE_IN` | **behoben (5.11.)** — Laufband startet ohne Anlauf: Phase 1 20 % LINEAR, Phase 2 80 % EASE_OUT (`TRANS_QUAD`; `QUART` fiel im Test durch, weil die letzten 0,75 s nur 0,01–0,03 % der Strecke legten → wirkte wie ein Hänger). Belege: `[CHEST][SPEED] phasen=linear20+out80 … t1=1.52 t2=6.10 d1=-1819 d2=-1819` (stetiger Übergang), 6 Läufe `monoton=true`, `v_start=864…1750 px/s → v_ende=0,7…13 px/s`, letzte 0,75 s `0,39–0,92 %` der Strecke |

---

## Runde 144 — Funde bei der Umsetzung (5.11.2026)

| ID | Schwere | Befund | Beleg | Fix-Plan |
|---|---|---|---|---|
| **X-B43** | klein | **Debug-Raster: Hut-Ebene pro Kachel teuer** — `_hat_layer_for()` samplet bilinear mit `get_pixel`/`set_pixel` (4096 Bildpunkte × 4 Nachbarn je Hut) | `[DBG][BENCH2] hatlayer200_ms=530` (2,65 ms je Ebene) | **behoben** — `_hat_layer_fast()` rechnet auf `PackedByteArray` und überspringt leere Nachbarschaften; Beleg `comic_lantest=hatcmp144` `paare=425 ungleiche_paare=108 max=0.0 mean=0.0` |
| **X-B44** | klein | **Golden-Master-Modus `upg` war nicht reproduzierbar** — die Bewegungsprüfung verglich Monster **nach Index**; stirbt das einzige Monster im Messfenster, lautet das Ergebnis `0/1` und sieht wie ein Standstill aus | `[TEST][H] Welt laeuft: 0/1 Monster in 0,5 s bewegt` (2 Läufe), `COMIC_LANTEST=mprobe144` zeigt dasselbe Monster mit `delta=76.23 px` in 0,5 s | **behoben** — Zeile trägt jetzt `vorher=<n> nachher=<n>`; Lauf danach `1/1 … vorher=1 nachher=1`. Golden für `upg` neu eingefroren (nur diese Zeile) |
| **X-B45** | klein | **Einstellungen-Zurück-Schaltfläche war auf 0,0 gemessen** — `layout_info()` lief im selben Frame wie `show()`, alle `Rect2` standen noch auf (0,0) | `[TAP] seite=aufgaben knopf=ZURUECK rect=(0,0)-(340,76)` | **behoben** — Seite wartet einen Frame (`await get_tree().process_frame`), danach `rect=(790,820)-(1130,896) sichtbar_im_bild=true` |

---

## Runde 148 — Funde bei der Umsetzung (6.11.2026)

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B46** | **kritisch** | **Upgrade-Fenster im Endlos-Modus ging nicht auf.** Der Toast war eine Sackgasse: `upgrade_toast.gd` schickte `upgrade_toast_tapped` auf dem RefCounted-Modul ab, das Signal existiert aber nur im UI-Manager (beim Modul-Split 138 verloren) | `ERROR: Can't emit non-existing signal "upgrade_toast_tapped"` (`logs_v148_upg.log:305`); danach `[UPG148][0] nach_tipp karten=0 paused=false` | **behoben** — `host.emit_signal(...)`. Beleg: `[UPG148][0] nach_tipp karten=3 paused=true` |
| **X-B47** | **kritisch** | **Kartenwahl kam nicht an, Spiel blieb pausiert.** Gleicher Mechanismus: `upgrade_cards.gd` schickte `upgrade_chosen` am Modul ab. Fenster schloss, Wirkung fehlte, `tree.paused` blieb `true` | `ERROR: Can't emit non-existing signal "upgrade_chosen"` (`logs_v148_upg2.log:305`), `stacks_nach={ } paused=true` | **behoben** — `host.emit_signal("upgrade_chosen", id)`. Beleg: `[UPG148][0] nach_wahl stacks_nach={ "vitality": 1 } paused=false pending=0` |
| **X-B48** | hoch | **Toast ueberlebte den Neustart** und erschien im naechsten Modus (im Test im Wellen-Modus, wo es gar keine Karten geben darf) | `[UPG148][0] nach_restart toast=true`, `[UPG148][1] … toast=true` | **behoben** — `restart_game()` ruft `hide_upgrade_toast()` + `pending_upgrades=0`. Beleg: beide Modi `nach_restart toast=false paused=false` |
| **X-B49** | hoch | **Sammlung: alle Kacheln grau, Seite liess sich nicht wischen.** `_readonly_tile()` setzte `disabled=true`: Godot zeichnet deaktivierte Buttons mit dem `disabled`-Modulate (grau) und der Button schluckte als `MOUSE_FILTER_STOP` den Drag | Screenshot v148/coll_zustaende.png (vorher: alles grau), `[SCROLL][ZUG] … px=64` ohne Bewegung (vorher) | **behoben** — Kacheln `mouse_filter = IGNORE`, drei Zustaende explizit gezeichnet, zentraler Drag-Handler. Beleg: `[SCROLL][ZUG] seite=collection von=0 nach=350 px=350` 3x |
| **X-B50** | mittel | **Winter auf der Erde praktisch unsichtbar** — die Jahreszeit wirkte nur als 0,62-Mischung auf eine gruene Palette, der Boden blieb gruen | Screenshot v148/erde_winter.png (vorher gruener Boden bei HUD "WINTER") | **behoben** — feste Schneetoene im Generator. Beleg: `[SEASON][SCHNEE] biome=meadow light=#e5effc dark=#c9dbf2` + neuer Screenshot |
| **X-B51** | klein | **Belegzeile kollidierte mit dem eigenen Abnahmekriterium**: `[SHOP][BOOSTS] entfernt=…` verhinderte `grep -c BOOSTS = 0` | `grep -c BOOSTS game_manager.gd` → 1 | **behoben** — Zeile heisst jetzt `[SHOP][BOOST-ENTFERNT]`; Grep in allen drei Dateien 0 |

---

## Runde 149/150 — Nachbesserungen nach Nutzer-Rueckmeldung (6.11.2026)

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B52** | **kritisch** | **Vorab-Kauf ("Portionen") crashte den Run.** `apply_quick_buffs()` lief im Run-Start/Utility-Refresh und schrieb `p.buff_cooldown_mult` sowie `add_utility()` in die Utility-Liste, bevor HUD/Knoepfe existierten; die Sektion stand weiter im Shop | `apply_quick_buffs` in `game_manager.gd` (2 Aufrufe) + `shop_page.gd` Sektion "SOFORTKAUF" | **behoben** — Sektion, `QUICK_SHOP`, `buy_quick`, `quick_buffs`, `apply_quick_buffs` entfernt; Profil verwirft alte Eintraege. Beleg: `[SHOP][VORAB] entfernt=1 …`, Shop ohne Sektion (`shop_kisten.png`), Runs `identisch=true`, `SCRIPT ERROR=0` |
| **X-B53** | hoch | **Sammlung "verzogen"**: Kachel war ein `Button` in einem Container, der die Zellenhoehe vorgab — der Button wurde auf Zellhoehe gezogen, Name/Balken lagen in der Kachel; die letzte Grid-Zeile klebte links | Screenshot `emu_coll.png` (v1.48): farbige Rechtecke mit Namen darin, Zeilen linksbuendig | **behoben** — feste Kachel 150x150 (Panel + Textur + Overlay), Balken/Name darunter, Zeilen selbst zentriert. Beleg: `[COLL][RASTER] … zeilen=1/3/3`, Screenshot `emu_coll149.png` |
| **X-B54** | mittel | **Sortierung nach Seltenheit fehlte** — Sammlung stand in Index-Reihenfolge | `[COLL][SORT]` existierte nicht | **behoben** — `_sorted_indices()`: Seltenheit absteigend, aktiver Eintrag zuerst in seiner Stufe (`[9, 5, 7, 8, 6, 0, 1, 2, 3, 4]`) |

---

## Runde 151 — Balancing Runden-Modus + Skills (6.11.2026)

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B55** | **hoch** | **Runden-Modus ab Runde 9 unschaffbar (LEICHT)**: die Runden-Kurve multiplizierte das Gegnertempo bis 1,50 (R14 SPRINT) — RED mit 140 px/s wurde damit **210 px/s schnell, der Spieler laeuft 160 px/s**. Weglaufen war ab R14 unmoeglich, nicht nur schwer | `Rounds.spd_mult(14)=1.50` + `monster_ai.gd` RED `speed: 140.0` → Verhaeltnis 0,76 | **behoben** — Deckel 1,18 in `spd_mult()`, SPRINT-Runde auf 1,18, RED auf 125 px/s. Beleg: `[BAL151][TEMPO] stufe=leicht min_verhaeltnis=1.08 ok=true` |
| **X-B56** | mittel | **Kein Fortschritt zwischen den Runden**: der Runden-Shop hatte nur Waffen/Leben/Traenke — Temp, Nachladezeit und Schaden liessen sich nicht verbessern, die Schwierigkeit lief dem Spieler davon | `wave_shop.gd` `CAT_ORDER = [WAFFEN, LEBEN, TRAENKE]` | **behoben** — Zeile „SKILLS · DAUERHAFT" mit TEMPO/NACHLADEN/SCHADEN (6 Stufen, Preis steigt je Stufe). Beleg: `[WSHOP][SKILL] id=skill_speed stufe=6 … speed=1.60`, `kauf=nein grund=maximum` |
| **X-B57** | mittel | **Muenzeinkommen zu knapp**: Kill-Muenzen `1 + hp*0,6`, Rundenbonus `12 + 4,5r` — im Shop war kaum etwas bezahlbar | kumuliert R9 LEICHT vorher ~800 Muenzen | **behoben** — `2 + hp*0,8` / `1 + 0,08r` / Bonus `16 + 6r`. Beleg: `[BAL151][EINKOMMEN] stufe=leicht r9=246(kum 1361)` |
| **X-B58** | klein | **`_cards` wuchs bei jedem Shop-Rebuild** (Altbestand, faellt jetzt bei jedem Skill-Kauf auf): nach 4 Kaeufen `karten=55` statt 11 | `[WSHOP][ZUSTAND] karten=55` in `logs_v151_bal.log` | **behoben** — `_cards.clear()` am Anfang von `_rebuild()`. Beleg: `[SHOP151][OFFEN] shop=true karten=11` |

---

## Runde 154 — Skin x Hut (7.11.2026)

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B60** | **hoch** | **Hüte wurden oben abgeschnitten**: `_hat_layer_fast()` deckelte nur nach unten (`y_bot > 63`), nicht nach oben. 178 von 425 Kombinationen betroffen | `[HATMX][FEHLER] rig=0(STANDARD) hut=6(PIRAT) problem=ABGESCHNITTEN_OBEN bbox=(18,0)` | **behoben** — `[HAT][DECKEL]`: bei `y_top < 1` schieben, sonst verkleinern. Matrix danach `kaputt=0` |
| **X-B61** | hoch | **Hüte auf hohen Skins unsichtbar**: Halos/Drohne/Stern wurden an die Kopfform skaliert und über die Kopfkante gesetzt — bei Helm- und Kapuzenskins lagen sie ausserhalb des Bildes | `[HATMX][FEHLER] … hut=10(HALO) problem=HUT_WIRKT_NICHT` auf 17 Skins | **behoben** — `FLOAT_HATS`: feste Größe, fester Sitz 2 px über dem Kopf |
| **X-B62** | mittel | **Körperteile im Gesicht**: Anstecker/Rucksack/Schulterplatten wurden wie Hüte auf den Kopf gerechnet | `problem=HUT_WIRKT_NICHT` 14x (ABZEICHEN), 12x (RUCKSACK) | **behoben** — `FIXED_HATS` (absolute Koordinaten), Anstecker/Schulterplatten nach vorne, Rucksack nach links |
| **X-B63** | mittel | **Doppeltes Kopfstück**: Skins mit eigenem Helm/Hörnern/Dreispitz/Kapuze behielten es unter dem neuen Hut | Kontaktblatt `sheet_r1-7-12-14_h0-13-8-6.png` (WIKINGER: Helm + Wikingerhelm gleichzeitig) | **behoben** — `_rig_body(..., bare_head)`; PANZERHELD, WIKINGER, EISENKARDINAL, ONI, KAPITAEN ROST, FROSTBEIL legen ab |
| **X-B64** | mittel | **Figur über den Bildrand**: ROBOTER-Antenne 1 px oben, SPINNENMANN-Bein 3 px rechts | 25 bzw. 24 Kombinationen `ABGESCHNITTEN_OBEN/SEITE` | **behoben** — Antenne `y=5`/Radius 3,6, Bein `x=59` |
| **X-B65** | **hoch** | **Hut schwebte über dem Kopf** (KAPITAEN ROST, WIKINGER): die Silhouetten-Oberkante wurde über das ganze Bild gemessen — Degenspitze bzw. Axt lagen höher als der Kopf | `[HATFIT][RIG] 14 … kopf_top` zu klein, Hut sass 4-6 px zu hoch | **behoben** — `_img_top_head()` misst nur in der Kopfspalte |
| **X-B66** | mittel | **Augenregel schob Hüte über die Silhouette** — bei hoch liegenden Augen landete der Hut über dem Kopf | Kontaktblatt `sheet_r7-14-1_h0-13-6-8.png` (Stirnband in der Luft) | **behoben** — Deckel `y_top >= sil_top` für getragene Hüte |
| **X-B67** | mittel | **KAPPE war 17 px hoch** und bedeckte auf jedem Skin die Augen; Hutgröße richtete sich nur nach der Kopfbreite | Zoom auf `sheet_r7-14-1-0_h1-2-3-6.png` | **behoben** — flachere Kappe (10 px) + Größenbegrenzung über die Kopfhöhe |
| **X-B68** | klein | **STIRNBAND** war ein loser Balken mit Pfeilspitze über dem Haar | dito | **behoben** — Band tiefer, Knoten statt Pfeil; sitzt auf der Stirn |
| **X-B69** | mittel | **PANZERHELD verlor Helm und Gesicht**, sobald ein Hut gewählt wurde (falsch verstandene Regel) | `sheet_r1-7-12-14_h0-13-8-6.png`, Zeile 1 | **behoben** — `bare_head` für PANZERHELD aus; Hüte sitzen auf dem Helm |


---

## v1.56 — Balance-Modell (8.11.2026)

Gefunden beim Umbau auf `scripts/core/balance.gd` (Spec `SPEC_BALANCE_V156.md`).

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B70** | **kritisch** | **Zufalls-Event „Monstersturm" spawnte 14 Gegner am Modell vorbei** („Elitewelle" 3 ORANGE + 3 geteilte PURPLE) — ohne Bezug zum Druck, auch mitten im Erholungsfenster. Das war die eigentliche Ursache für „sofort tot": Messung zeigte Tod bei 0–2 Gegnern auf dem Feld | `[BAL][EVENT] art=swarm … (Modell statt 14)` vorher: 14 Spawns in einem Frame, `erster_treffer` == Todeszeit | **behoben** — Events laufen durch `Balance.ziel_druck` × 2,5, respektieren `max_aktiv`, werden im Erholungsfenster blockiert: `[BAL][EVENT] blockiert grund=phase phase=erholung` |
| **X-B71** | **kritisch** | **Boss-/Mini-Boss-HP war unabhängig von der Spielerleistung** (Mini 125, Riese 230 Basis-HP). Ein Anfänger (gemessen ~1,7 effektive DPS) braucht dafür 70–140 s, während der Boss ihn jagt → sicherer Tod bei jedem Mini-Boss | `[BAL][BOSS] modus=endlos art=mini spawn=true hp=125` (alt) vs. `hp=28` (neu) | **behoben** — `Balance.boss_hp()`/`mini_hp()`: HP = Referenz-DPS × Ziel-Killzeit der Stufe (Spec 3.3), Mini-Boss eigenes Tempo (`Balance.mini_speed`) und Schaden 1 |
| **X-B72** | **hoch** | **„Druck senken" war wirkungslos**: `anzahl_fuer_druck()` rundete auf `maxi(1, …)` — bei kleinem Soll-Druck spawnte der Spawner trotzdem 1 Gegner je Fenster (1,44 HP/s Untergrenze). Vier Messläufe mit halbiertem Druck änderten die Überlebenszeit nur um ±10 % | `[BAL][MODELL] … anzahl=1 rate=0.07/s` nach dem Fix | **behoben** — kontinuierliches Spawn-Budget (`Balance.rate_fuer_druck()` + `_budget` im Spawner) |
| **X-B73** | mittel | **Trefferzähler erfasste Kontaktschaden nicht**: Kontakt läuft über `collider.call("take_damage")`, nicht über `game_manager._on_monster_damage_player` — der Bot meldete „treffer=0", obwohl der Spieler starb | `[BOT][LAUF] … treffer=0 … ende=tod` (alt) | **behoben** — Zählung im einzigen Trichter `player_controller.take_damage()` (`gm._bal_treffer(amount)`), zählt LP-Verlust |
| **X-B74** | mittel | **Rettungsanker konnte nicht greifen**: der 90-s-Zähler wurde auch zurückgesetzt, wenn die HP-Bedingung NICHT erfüllt war — im Tod-Fenster war der Anker damit immer „gerade verbraucht" | kein `[BAL][ANKER]` in 8 Läufen | **behoben** — Zähler wird nur bei tatsächlicher Auslösung zurückgesetzt |


---

## v1.57 — Vier gemeldete Fehler (9.11.2026)

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B75** | **hoch** | **Elektro-Welt spawnte nur grüne Wiesen-Monster.** `rolle_von_type()` ordnete alle Welt-Typen (11–34) pauschal „hetzer" zu; im Elektro-Pool `[25,26,26,27,29,29]` gibt es damit keinen Läufer/Anker. Sobald das Hetzer-Limit griff, fiel `_typ_fuer_rolle()` auf `GREEN` zurück | `[BAL][POOL] karte=volt quelle=map pool=[25,25,26,26,27,29,29]` · vorher `feld={ "?": 5 }` (GREEN im Elektro-Lauf) | **behoben** — eigene Rollen je Welttyp (11 Läufer, 12 Anker, 15 Hetzer, 13 Läufer, 17 Hetzer, 18/14 Anker, 25/27 Hetzer, 26 Läufer, 29 Störer); Fallback nimmt jetzt einen Typ **aus dem Kartenpool**. Beleg: `feld={ "VOLT_TROOPER": 5 }` (volt), `feld={ "MARS_ALIEN": 4 }` (mars) |
| **X-B76** | mittel | **Erste 20 s kein einziger Gegner** — Schonfrist war 20 s, danach lief der Anlauf noch bis zu 5 s leer. Der Spieler suchte Monster | `[BAL][SCHONFRIST] … dauer=20 art=start` | **behoben** — Schonfrist 8/6/5/4 s je Stufe + erster Schub sofort danach (`[BAL][ANLAUF] … erster_schub=true`), Anlauf-Schub alle 1,2 Fenster mit 3 Gegnern. Messung: 3 Gegner bei t=6 s, volles Feld (5) bei t=10 s |
| **X-B77** | **hoch** | **Wellen+Shop blieb stehen, Shop öffnete nicht.** Nach dem Räumen der Welle wurde der Nachschub-Block gesetzt, kehrte aber zurück, **bevor** der Spawn-Code lief: `phase=peak`, `phase_left` lief auf −256 s, `offen=3`, `feld=0` | `[WAVE][WATCHDOG] welle=1 rest=0 offen=3 feld=0 phase=peak phase_left=-256.1 shop=false` | **behoben** — Nachschub spawnt direkt (`[BAL][NACHSCHUB] … schub=3`); zusätzlich zählt `offen()` jetzt auch Boss-Telegraph/lebenden Boss, damit eine Boss-Welle nicht sofort als „fertig" gilt. Belege: 11× `[WAVE] Welle N geraeumt … -> Shop`, Welle 5 (Boss) räumt korrekt ab |
| **X-B78** | **hoch** | **Tippen auf „ÖFFNEN" (Kisten im Shop) wirkungslos**, sobald der Finger minimal wandert. Ursache: `ui_manager._input` behandelte **jede** Fingerbewegung als Scroll-Zug und rief `set_input_as_handled()` — der Knopf verlor das Release. Zusätzlich schluckte der `ScrollContainer` der Shop-Seite den Zug selbst | Messung mit echtem Eingabepfad (`Input.parse_input_event`): Zug 3 px = öffnet, Zug 8/14/25 px = öffnet **nicht** (alte Fassung) | **behoben** — Tipp-Schwelle 14 px (`TIPP_SCHWELLE`), darunter wird das Event durchgelassen (`[SCROLL][TIPP] … durchgelassen=true`); `ScrollContainer.mouse_filter = IGNORE` (gescrollt wird zentral, Mausrad mitgezogen). Beleg: `[TOUCH][KISTE] zug=8px oeffnung=true` … `zug=25px oeffnung=true` |

**Testwerkzeug:** `COMIC_LANTEST=chesttouch` (`logs_bug_chest7.log`) fährt den Kistenkauf über den **echten** Eingabepfad
(`InputEventScreenTouch`/`ScreenDrag` in 4-px-Schritten, wie ein Finger) und danach Scroll + erneuten Tipp.


### Nachtrag v1.58 — die Kiste ging wirklich nicht auf (9.11.2026)

| ID | Schwere | Befund | Beleg | Status |
|---|---|---|---|---|
| **X-B79** | **kritisch** | **Kisten-Öffnung reagierte auf keinen Tipp.** Das Overlay-Root (`ChestOpenUI`) hat `MOUSE_FILTER_STOP` und schluckt damit jedes Ereignis — `_unhandled_input()` wurde **nie** erreicht. Der Kauf wurde abgebucht, die Kiste blieb aber für immer zu (`_stage` blieb 0) | Messung im Fenster bei Handy-Auflösung (1080×2340, Canvas 1920×4160): `[TOUCH2][OEFFNUNG] tipp=1…6 stage=0 done=false`, danach `FEHLER: nach 6 Tipps noch offen` | **behoben** — Tipp-Weiche in `_gui_input()` (kommt an, weil das Root STOP ist), `_unhandled_input()` bleibt Fallback, Doppelzählung über 80 ms gesperrt. Beleg: `[CHESTFX][TIPP] stage=1 von=1`, `[CHESTFX][FERTIG] dauer=3.10 s`, `[CHESTFX][ZU]`, `seite_wieder_da=true` |
| **X-B80** | hoch | **Trefferfläche der Kisten-Karte zu klein**: nur der 320×64-Knopf kaufte; ein Tipp auf Kistenbild oder Chancen-Zeilen lief ins Leere. Auf dem Handy ist der Knopf nur 36 px hoch | `[TOUCH2][BILD] tipp_auf_bild kiste_offen=false` (alte Fassung) | **behoben** — die **ganze Karte** öffnet (alle Nicht-Knopf-Kinder `MOUSE_FILTER_IGNORE`, `card.gui_input`), Doppelkauf über 600 ms gesperrt (`[TOUCH][DOPPEL] … ignoriert`). Beleg: `tipp_auf_bild kiste_offen=true` |
| **X-B81** | mittel | **„Nicht genug Diamanten" war nur eine 20-px-Zeile am Seitenende** — auf dem Handy unsichtbar, der Tipp wirkte wirkungslos | `chest_msg` unter dem Scrollbereich | **behoben** — zusätzlich Banner `NICHT GENUG DIAMANTEN` + Log `[TOUCH][KAUF] … haben=… braucht=…` |
