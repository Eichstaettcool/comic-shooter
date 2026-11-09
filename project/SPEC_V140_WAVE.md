# SPEC v1.40 — Wellen-Modus (rundenbasiert, eigener Shop)

**Status: umgesetzt am 4.11.2026** — Block W0–W7 alle `[x]`, Belege in `STATUS.md`.

Projekt `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2.
Vorgänger: v1.39 (`SPEC_V139_LOOKS.md`, abgeschlossen).

**Auftrag in einem Satz:** Ein **rundenbasierter** Wellen-Modus für die erste Karte — jede
Runde mehr und stärkere Monster, nach jeder besiegten Runde ein Shop, der eigens für den Modus
gebaut ist (Waffen nach Seltenheit, Leben/Schild/Revive, Tränke, in Kategorien sortiert, jeder
Kauf öffnet ein eigenes Fenster), **keine Kisten auf der Karte**, und zwei Icons rechts oben
(„Shop öffnen" / „nächste Welle"), statt automatisch weiterzulaufen.

---

## 0 — Ausgangslage (geprüft am 4.11.2026, v1.39)

| Fakt | Wert | Ort |
|---|---|---|
| Es gibt **schon** einen Wellen-Modus | `game_mode = 1` (0 = Endlos) | `game_manager.gd:122`, `:537` |
| Wellen-Start | `count = mini(48, round(min(40, 5 + wave*3) * diff.spawn))` — **alle Monster auf einmal** in einem Frame | `core/waves.gd:_start_wave` |
| Balance | 6 Stufen `WAVE_BALANCE` (hp 1,00 → 2,55 · spd 1,00 → 1,15) über `wave_balance()` | `core/waves.gd:9` |
| HP/Speed-Skalierung existiert | `monster.apply_wave_mult(hp, spd)` beim Spawn | `core/spawn_api.gd:22` |
| Shop nach der Welle | automatisch nach **Abräumen** (`wave_remaining <= 0`), mit **Timer** `shop_time`, dann `_next_wave(true)` | `game_manager.gd:1645` |
| Shop-UI | `shop_run.gd` (`show_shop(coins, items, …)`) — flache Liste aus `SHOP_ITEMS` | `ui/overlays/shop_run.gd`, `core/shop_logic.gd:35` |
| Shop-Artikel heute | Heiltrank, Bombe, Komplett-Heilen, Schild +2, **Zufallswaffe**, Max-Herz +1, Tempo, Schaden | `core/shop_logic.gd:35` |
| Karten-Kisten | Nur beim **Mini-Boss-Kill** (`spawn_run_chest_at`) — kein Streu-Drop | `core/bosses.gd:128` |
| Waffen | 5 Waffen, 4 Seltenheiten (`common/rare/epic/legendary`) mit eigenen Stats | `player_controller.gd`, `WEAPON_STAT_VALUES` |
| HUD | `weapon_row` (3 Spalten) + Utility-Zeile (Trank/Bombe) + Wellen-Label | `ui/hud.gd:201`, `:250` |
| Monster-Katalog (Erde) | GREEN 3 HP · RED 2 · BLUE 4 · YELLOW 3 · PINK 4 · PURPLE 6 · ORANGE 12 (später GOLEM 16, BURROWER 5, PYRO 5, BIOME-SPEZIALISTEN) | `entities/monster/monster_stats.gd` |
| Mini-Boss / Boss | alle 5 Wellen Mini-Boss, alle 10 der Biom-Boss, `MINI_*`/`BOSS_*` | `core/waves.gd`, `core/bosses.gd` |
| Regressionnetz | `./tools/golden_check.sh` 8 Modi, Diag-Modi über `COMIC_LANTEST=<mode>` | `tools/golden_check.sh` |

**Wichtig:** Der bestehende Modus wird **nicht** ersetzt, sondern als **dritter Modus** daneben
gestellt: `game_mode` 0 = ENDLOS, 1 = WELLEN (alt, bleibt unverändert als Golden-Master-Referenz),
2 = **RUNDEN** (neu). So kann nichts Bestehendes kaputtgehen, und `golden_check.sh` bleibt gültig.

---

## Harte Regeln (für jeden Punkt)

1. Nach jedem Punkt: `./Godot.exe --headless --path project --quit-after 20` (0 `SCRIPT ERROR`)
   **und** `./tools/golden_check.sh` (8/8). Der neue Modus darf die alten Logs nicht verändern.
2. Jeder Punkt hat eine **Messzeile** im Log (`[WAVE][…]`, `[WSHOP][…]`) und, wo es um Aussehen
   geht, ein Bild in `screenshots/v140/`.
3. `game_mode == 1` (alter Wellen-Modus) bleibt **unangetastet** — alle neuen Pfade hängen an
   `game_mode == 2`.
4. Kein neuer Autoload. Neue Dateien: `core/rounds.gd` (Runden-Tabelle + Ökonomie),
   `ui/overlays/wave_shop.gd` (neuer Shop), `ui/overlays/wave_item_window.gd` (Kauf-Fenster).
5. Kisten sind im neuen Modus **verboten**: `spawn_run_chest_at()` wird bei `game_mode == 2`
   nicht aufgerufen und protokolliert das.
6. Builds erst in Block W7.

---

## W0 — Messnetz (kein Spielcode)  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W0.1** | Diag-Modus `rounds`: gibt 30 Runden als Tabelle aus (Gruppen, Anzahl, HP-Summe, Multiplikatoren) | 30 Zeilen `[WAVE][PLAN] runde=<n> gruppen=<g> monster=<m> hp=<summe> mult=<x>`; Datei `tools/round_plan.md` |
| **W0.2** | Diag-Modus `waveshot`: Kontaktblatt der drei Shop-Kategorien + des Kauf-Fensters (Platzhalter-Inhalte) | `screenshots/v140/shop_kat.png`, `shop_fenster.png`, `hud_icons.png`; Log `[SHOT] …` |
| **W0.3** | Baseline des alten Modus sichern (30 Runden im `game_mode=1`), damit die neue Balance vergleichbar ist | `tools/wave_baseline.md`: je Runde Monsterzahl + HP-Summe, Log `[WAVE][BASE] runde=<n> hp=<x>` |

---

## W1 — Runden-Kern (Spawn, Ende, Banner)  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W1.1** | **Runden = Gruppen** (BTD5-Prinzip): pro Runde eine Liste `[{typ, anzahl, abstand_s, delay_s}]`, Monster kommen **nacheinander** in Gruppen, nicht alle in einem Frame | `[WAVE][START] runde=1 gruppen=1 monster=8` … `[WAVE][GRUPPE] runde=1 nr=1 typ=GREEN anzahl=8 abstand=0.55` — Summe der Gruppen = `monster` |
| **W1.2** | **Runden-Tabelle 1–30** in `core/rounds.gd` (Erde): neue Typen kommen gestaffelt (R1–3 GREEN, ab R4 RED, ab R7 BLUE, ab R10 YELLOW/PINK, ab R13 PURPLE, ab R16 ORANGE, ab R19 GOLEM/BURROWER, ab R22 PYRO) | `[WAVE][PLAN]` für alle 30 Runden; **HP-Summe streng monoton steigend** (jede Runde > vorherige) |
| **W1.3** | **Stärkere Monster**: pro Runde `hp_mult` und `spd_mult` aus der Tabelle, angewendet über `apply_wave_mult` | `[WAVE][DIFF] runde=<n> hp_mult=<x> spd_mult=<y>`; R30 ≥ 3,0× HP und ≥ 1,25× Tempo gegenüber R1 |
| **W1.4** | **Rundenende** = alle Monster der Runde tot (`counts_for_wave`), nicht „Welle leer" über Timer | `[WAVE][ENDE] runde=<n> getoetet=<n>/<m> dauer=<s>`; kein `[WAVE][ENDE]` bevor `getoetet == m` |
| **W1.5** | **„WELLE n BESIEGT"** ploppt auf (Banner + Ton), 2 s sichtbar | `[WAVE][BANNER] runde=<n> text="WELLE 3 BESIEGT"`; Screenshot `screenshots/v140/welle_besiegt.png` |
| **W1.6** | **Keine Kisten und keine Kraftfelder** im Modus (Entscheidung 4.11.) | `[WAVE][KISTE] erlaubt=false aufrufe=0 felder=0` am Rundenende; Diag zählt `chest_container`-Kinder = 0 und Kraftfelder = 0 nach 5 Runden |
| **W1.7** | Mini-Boss alle 5, Biom-Boss alle 10 (wie bisher, aber in der Runden-Tabelle verankert) | `[WAVE][BOSS] runde=5 typ=MINI_EARTH`, `[WAVE][BOSS] runde=10 typ=BOSS_EARTH` |
| **W1.8** | Sicherheitsnetz: Runde gilt nach 90 s ohne lebende Monster trotzdem als beendet (Leck-Schutz) | `[WAVE][WARNUNG] runde=<n> notende nach 90 s (lebend=0)` |

---

## W2 — Intermission + zwei Icons  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W2.1** | Nach dem Rundenende **kein automatischer Weitermarsch**: der Modus wartet auf den Spieler (kein Timer) | 30 s ohne Eingabe: `[WAVE][INTERMISSION] t=30.0 wartet=true runde=<n>` |
| **W2.2** | Zwei Icons **rechts oben, unter der Waffen-/Tränke-Anzeige**: `WaveShopBtn` (Shop) und `WaveNextBtn` (nächste Welle) | Knoten `WaveShopBtn`/`WaveNextBtn` im HUD, nur in der Intermission sichtbar; `[WAVE][UI] icons=2 shop=true next=true` |
| **W2.3** | Shop-Icon **pausiert** das Spiel (Baum-Pause wie das Pause-Menü), Schließen setzt fort | `[WAVE][UI] shop_pause=true` beim Öffnen, `[WAVE][UI] shop_pause=false` beim Schließen |
| **W2.4** | Nächstes-Welle-Icon startet Runde `n+1` sofort, Icons verschwinden während der Runde | `[WAVE][UI] next_klick=true runde=<n+1>`; nach Start `icons=0` |
| **W2.5** | Tastatur/Gamepad: `ui_accept`-Alternative nicht nötig, aber `1`/`2` … **nein**: nur Icons + `Esc` (Pause) — Maus/Touch ist der Weg | Icons per `push_input`-Klick bedienbar (Diag `click`-Test), `[WAVE][UI] klick quelle=maus ok=true` |
| **W2.6** | Wellen-Label zeigt `WELLE n · MONSTER x/y · MÜNZEN k` | Log `[WAVE][HUD] text="WELLE 4 · MONSTER 12/26 · MÜNZEN 130"` |

---

## W3 — Shop für den Modus (Kategorien + eigene Fenster)  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W3.1** | Overlay `WSHOP` mit **drei Kategorien in fester Reihenfolge**: WAFFEN · LEBEN · TRÄNKE, jede Kategorie eine Spalte mit Karten | `[WSHOP][BAU] kategorien=3 karten=12 reihenfolge=waffen,leben,traenke`; Shot `screenshots/v140/shop_kat.png` |
| **W3.2** | **Klick auf eine Karte öffnet ein eigenes Fenster** (modal, über dem Shop) mit Icon, Name, Werten, Preis, KAUFEN/ABBRECHEN | Knoten `WaveItemWindow`; `[WSHOP][FENSTER] artikel=<id> offen=true`; Shot `shop_fenster.png` |
| **W3.3** | **Waffen nach Seltenheit**: pro Waffe 4 Karten (common/rare/epic/legendary) mit steigendem Schaden/RPM und steigendem Preis, Farbe nach Seltenheit; Kauf rüstet die Waffe aus (bzw. zeigt „AUSRÜSTEN", wenn schon besessen) | `[WSHOP][WAFFE] key=weapon_shotgun seltenheit=epic schaden=<x> rpm=<y> preis=<z> gekauft=true` je Karte |
| **W3.4** | **Leben**: `+1 Herz` (max. +5 über den Run), `+1 Leben zurückkaufen` (nur wenn tot? nein: **Revive-Versicherung**, max. 2 pro Run), `Schild +2 Ladungen` | `[WSHOP][LEBEN] art=herz|revive|schild wert=<n> preis=<p> ok=true`; harte Grenzen im Log (`limite=erreicht`) |
| **W3.5** | **Tränke** wie bisher: Heiltrank, Bombe (plus die vorhandenen Buffs) mit denselben Effekten wie im Run | `[WSHOP][TRANK] art=potion|bombe effekt=<n> ok=true` |
| **W3.6** | Sortierung stabil und sichtbar (Kategorie-Kopf + feste Artikelreihenfolge, Preise aufsteigend innerhalb der Kategorie) | `[WSHOP][SORT] kategorie=waffen preise=[120,240,420,760] aufsteigend=true` (3×) |
| **W3.7** | Kauf ohne Geld: Karte ausgegraut, Klick öffnet Fenster mit „ZU WENIG MÜNZEN", kein Abzug | `[WSHOP][KAUF] artikel=<id> ok=false grund=zu_wenig_muenz`; Münzen unverändert |
| **W3.8** | Shop-Zustand überlebt Schließen/Öffnen (kein Leck), Kinder konstant | `[WSHOP][ZUSTAND] kinder=<n>` 5× identisch, `delta=0` Knoten |
| **W3.9** | **Hybrid-Angebot**: pro Runde EIN wechselnder „ANGEBOT DES TAGES"-Slot über den Kategorien, 25 % Rabatt, genau 1× kaufbar | `[WSHOP][ANGEBOT] runde=<n> artikel=<id> rabatt=25 preis=<p> gekauft=<false|true>`; Artikel wechselt zwischen zwei Runden (`[WSHOP][ANGEBOT] runde=n artikel=A` ≠ `runde=n+1 artikel=B`), nach Kauf `ausverkauft=true` |

---

## W4 — Ökonomie  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W4.1** | Münzen pro Kill (typabhängig) **plus** Rundenbonus beim Abräumen | `[WAVE][ECO] runde=<n> kills=<k> muenzen=+<x> bonus=+<b> gesamt=<g>` |
| **W4.2** | Rundenbonus wächst mit der Runde (Formel in `rounds.gd`), damit der Shop ab R10 mithält | Bonus R10 ≥ 3× Bonus R1 (Log-Vergleich) |
| **W4.3** | Preise skalieren mit der Runde (`preis = basis * (1 + 0.06 * runde)`, gerundet auf 5) | `[WSHOP][PREIS] artikel=<id> runde=<n> preis=<p>`; monoton über 10 Runden |
| **W4.4** | Simulation: 30 Runden mit „alles kaufen was geht" → nie negativ, nie unendlich reich | `tools/wave_economy.md`: Tabelle Runde/Münzen/Einnahmen/Ausgaben; Endstand zwischen 0 und 2000 |
| **W4.5** | Kein Softlock: bei 0 Münzen gibt es jede 3. Runde **einen freien Heiltrank** (Gnadenregel) | `[WAVE][ECO] gnade=true runde=<n>` |

---

## W5 — Schwierigkeitskurve (messbar)  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W5.1** | HP-Summe pro Runde streng monoton (R1 → R30) | `[WAVE][PLAN]` 30 Zeilen, Prüfung im Diag: `monoton=true` |
| **W5.2** | Monsterzahl steigt bis R20, danach **gedeckelt** (Performance) | `monster` R1 ≤ 10, R10 ≈ 25–35, R20 ≤ 55, R30 ≤ 55; `[WAVE][PLAN] deckel=true` |
| **W5.3** | Neue Monsterart führt eine neue **Fähigkeit** ein (Panzerung, Tempo, Fernkampf) — nicht nur Farbe | Tabelle in `tools/round_plan.md` (Typ → Fähigkeit aus `monster_stats.gd`) |
| **W5.4** | 30 Runden im Diag-Lauf ohne `SCRIPT ERROR`, ohne Frame-Einbruch | `[PERF] fps_avg ≥ 54`, `proc_ms ≤ 0,10` im `rounds`-Modus |

---

## W6 — Optionen (entschieden am 4.11.2026)  `[x]`

| # | Vorschlag | Entscheidung | Aufwand |
|---|---|---|---|
| **W6.1** | **Wellen-Vorschau** in der Intermission („Nächste Runde: 18× Blau, 4× Gelb, 1× Mini-Boss") | **GEBAUT** | klein |
| **W6.2** | Frühstart-Bonus | abgelehnt | — |
| **W6.3** | Zins auf Restmünzen | abgelehnt | — |
| **W6.4** | Brotato-Angebote (4 zufällige + Reroll) | abgelehnt — stattdessen **Hybrid-Slot** (W3.9) | — |
| **W6.5** | Waffen-Upgrades Stufe 2/3 | abgelehnt | — |
| **W6.6** | **Themen-Runden**: jede 7. Runde eine eigene Regel (PANZER-RUNDE, SPRINT-RUNDE, SCHWARM-RUNDE …) | **GEBAUT** | klein |
| **W6.7** | Endlos nach R30 + „beste Runde" im Profil | abgelehnt (später) | — |
| **W6.8** | **Schwierigkeitsgrade** LEICHT / NORMAL / HART (Startherzen, Preise, HP-Multiplikator) | **GEBAUT** | mittel |

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W6.1** | Vorschau-Panel in der Intermission, gefüllt aus der Runden-Tabelle der **nächsten** Runde | `[WAVE][VORSCHAU] runde=<n+1> typen=GREEN×8,BLUE×4 boss=nein`; sichtbar im Shot `screenshots/v140/intermission.png` |
| **W6.6** | Themen-Runden: jede 7. Runde (`7, 14, 21, 28`) mit eigenem Regel-Set, Banner kündigt an | `[WAVE][THEMA] runde=7 thema=PANZER typen=[ORANGE,GOLEM] hp_mult=<x>`; 4 Themen im 30-Runden-Plan |
| **W6.8** | Drei Schwierigkeitsgrade, im Menü wählbar; wirken auf Startherzen, `hp_mult` und Preise | `[WAVE][DIFF] grad=hart herzen_start=3 hp_mult=1.25 preis_mult=1.2`; LEICHT: 5 Herzen / 0,85× / 0,9× |

## W7 — Abschluss  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **W7.1** | Version **1.40**, `APP_VERSION`/`APP_BUILD`, Modus im Menü wählbar (ENDLOS · WELLEN · RUNDEN) | `[BUILD] Versionsanzeige v1.40 aktiv (Build 40)`; Menü zeigt 3 Modi (`[MODE] wahl=2`) |
| **W7.2** | `golden_check.sh` 8/8, `[PERF] fps_avg ≥ 54`, `proc_ms ≤ 0,10` | Log-Zeilen im Bericht |
| **W7.3** | Doku: `SPEC_V140_WAVE.md` (Status), `STATUS.md`, `BUGLISTE.md`, `ARCHITEKTUR.md`, Bilder in `screenshots/v140/` | alle vier Dateien aktualisiert |
| **W7.4** | Builds `dist/ComicShooter-v1.40.apk` + `.exe` | beide vorhanden, APK `apksigner verify` = 0 |

---

## Reihenfolge

```
W0.1 W0.2 W0.3          Messnetz + Baseline
W1.1 → W1.8             Runden-Kern (Spawn in Gruppen, Ende, Banner, keine Kisten)
W2.1 → W2.6             Intermission + zwei Icons
W3.1 → W3.8             Shop (Kategorien, Fenster, Waffen/Leben/Tränke)
W4.1 → W4.5             Ökonomie
W5.1 → W5.4             Schwierigkeitskurve messen
W6.1 W6.6 W6.8          Vorschau, Themen-Runden, Schwierigkeitsgrade
W7.1 → W7.4             Version + Builds
```

---

## Bekannte Fallen

1. **`game_mode` hat zwei Zustände** — überall im Code steht `if game_mode == 1: … else: …`.
   Ein dritter Modus braucht **alle** Stellen geprüft (`grep -rn "game_mode"`), sonst verhält sich
   RUNDEN wie ENDLOS (Kisten, Bosse über Zeit, kein Shop).
2. **Monster-Spawn in einem Frame** ruckelt bei 40+ Monstern. Gruppen mit Abstand
   (`abstand_s`) sind Pflicht, sonst bricht `fps_avg` ein.
3. **`wave_remaining` / `_recount_wave()`** zählen über `counts_for_wave()` — Geister und
   bereits sterbende Monster dürfen nicht mitzählen (bestehender Bugfix aus Runde 55).
4. **Pause**: das Spiel nutzt `get_tree().paused`; der Shop muss `PROCESS_MODE_ALWAYS` haben,
   sonst reagiert er nicht (gleiche Falle wie beim Pause-Menü).
5. **Shop-Overlay über dem HUD**: Icons liegen im HUD, das Overlay darüber — beim Öffnen Icons
   ausblenden, sonst doppelte Klickflächen.
6. **Kein Timer**: der bestehende Modus schiebt automatisch weiter (`shop_time`). Im neuen Modus
   darf `shop_time` **nicht** laufen, sonst ist die Intermission weg.
7. **Index-Vertrag** (aus v1.39): Waffen sind Strings, Skins/Hüte Indizes — der neue Shop darf
   nur Waffen-Strings und Herz-/Schild-Zähler anfassen, nie `p_rig`/`p_hat`.

---

## Was ausdrücklich **nicht** geändert wird

- `game_mode == 1` (alter Wellenmodus) — bleibt als Golden-Master-Referenz unverändert.
- Endlos-Modus (`game_mode == 0`) und alle Kisten-/Kosmetik-Systeme.
- LAN/Coop: der neue Modus läuft **erstmal solo**; Coop ist nicht Teil von v1.40 (im Log:
  `[WAVE][NET] modus_nur_solo=true`).

---

## Umsetzungsnotizen (Abweichungen von der Spec, bewusst)

1. **W0.2**: Die Shop-Bilder entstehen im Diag-Modus `roundrun` (echter Spielpfad), nicht in einem
   eigenen `waveshot`. Dateien wie gefordert unter `screenshots/v140/`.
2. **W1.3/W1.7**: Boss-Log nutzt die Typnummer + Rolle (`typ=23 MINI-BOSS`, `typ=19 BOSS`)
   statt fester Namen `MINI_EARTH` — die Typ-IDs sind biomabhängig.
3. **W4.3**: Preisfaktor ist **0,075** pro Runde (Spec sagte 0,06). Grund: mit 0,06 lief das
   Ökonomie-Modell auf 6.512 Münzen Endstand (W4.4 verletzt), mit 0,075 und kleineren Kill-Münzen
   (0,09 statt 0,14) endet es bei 928.
4. **W4.5**: Gnadenregel sitzt in `RoundsMode._grace_check()` (eigener Pfad, am Rundenende gerufen),
   damit sie messbar testbar ist — gleicher Code wie im Spiel.
5. **W1.8**: Das 90-s-Sicherheitsnetz ist gebaut, wurde im Test aber nicht ausgelöst (alle Runden
   endeten regulär).
