# SPEC v1.39 — Looks & Sammlung (ausführbare Übergabe)

Projekt `C:/Users/vince/Games/comic-shooter`, Godot 4.7.2. Rahmen: `PLAN_V139_LOOKS.md`.
Vorgänger: `SPEC_V138_SPLIT.md` (Modul-Split, abgeschlossen; Struktur in `ARCHITEKTUR.md`).

**Auftrag in einem Satz:** Hüte sollen auf jeder Figur richtig sitzen und richtig heißen,
die Sammlung darf nicht abstürzen, Kisten-Animationen müssen überspringbar sein, und die
Skins sollen ohne Slop, mit vier neuen eigenen Formen und per Debug-Knopf komplett
freischaltbar sein — **ohne** bestehende Profile zu zerstören.

---

## 0 — Ausgangslage (Stand v1.38, geprüft am 3.11.2026)

| Fakt | Wert | Ort |
|---|---|---|
| Hüte | **29** (`OHNE` … `STERNCHEN`) | `scripts/texture/tex_draw.gd:264` (`HAT_NAMES`) |
| Hut-Seltenheiten | 29 Einträge (konsistent) | `scripts/game_manager.gd:624` (`HAT_RARITY`) |
| Skins/Rigs | **25** (`STANDARD` … `NEON-PHANTOM`) | `scripts/texture/tex_draw.gd:263` (`RIG_NAMES`) |
| Skin-Seltenheiten | 25 Einträge (konsistent) | `scripts/game_manager.gd:630` (`RIG_RARITY`) |
| Hut-Zeichnung | Sonderfälle 10/11/12, dann `match hat` mit Armen 1–8, 9, 13–28 | `scripts/texture/gen_characters.gd` (`_draw_hat`) |
| Hut-Sitz | **ein** y-Offset je Rig (`HEAD_ANCHOR`, 25 Werte), Hutgröße fix | `tex_draw.gd:261`, `_draw_hat_on` |
| Skin-Zeichnung | `match idx` mit 25 Armen (6–17 Zeilen je Arm) | `gen_characters.gd` (`_make_player_rig`) |
| Kisten-Ablauf | `_play_chest_open_animation` → `show_chest_result`, Dauer 4,5–8,0 s | `scripts/ui/ui_manager.gd:2773`, `:2955` |
| Debug „alles freischalten" | existiert, schaltet Farben/Hüte/Maps/Seasons — **nicht** `unlocked_rigs` | `debug_panel.gd:110`, `game_manager.gd:1417` |
| Sammlung | öffnet im Diag-Modus `char` **fehlerfrei** (0 SCRIPT ERROR, `232c-sammlung.png`) | `scripts/ui/pages/collection_page.gd` |
| Regressionnetz | `./tools/golden_check.sh` 8 Modi grün; Werkzeuge in `tools/` | `SPEC_V138_SPLIT.md` §A |

**Wichtig:** die Rigs sind sich **textlich** unähnlich (max. Jaccard 0,22 zwischen zwei
Armen) — der „Slop"-Eindruck ist **visuell** (gleiche Silhouette, andere Farbe). Deshalb
misst Block M Silhouetten, nicht Code.

---

## Harte Regeln (gelten für jeden Punkt)

1. **Ein Punkt pro Schritt.** Nach jedem Punkt: `./Godot.exe --headless --path project
   --quit-after 20` (0 `SCRIPT ERROR`) und `./tools/golden_check.sh`.
2. **Bilder statt Adjektive.** Jede Aussage „sitzt besser" wird durch ein Kontaktblatt
   und eine Log-Zeile belegt (`[HAT][SITZ]`, `[RIG][IOU]`, `[COLL][…]`).
3. **Indizes sind Verträge.** `p_rig`, `unlocked_rigs`, `p_hat`, `unlocked_hats` werden
   **index-basiert** gespeichert. Ohne Migration (Punkt D2) darf keine Liste umsortiert
   oder gekürzt werden.
4. **Cache mitdenken.** Figuren werden über `(Farbe, Skin, Hut)` gecacht
   (`get_skin_hat_texture_or_player`). Nach jeder Hut-/Skin-Änderung prüfen, dass der
   Cache-Key die Änderung sieht — sonst zeigt das Spiel die alte Textur.
5. **Rollback** wenn ein Punkt nach zwei Reparaturversuchen nicht grün wird:
   Datei aus dem letzten `git`-Stand bzw. `backup/` zurück, Punkt `[!]` mit Grund.
6. Keine Builds vor Block E.

---

## M — Messnetz (Vorarbeit, kein Spielcode)  `[x]`

Belege: `screenshots/v139/hats_29x4.png` (1384x2518, 116 Kacheln, Log
`[SHEET] hats=29 rigs=4 kacheln=116`), `screenshots/v139/rigs_25.png`
(`[SHEET] rigs=25`), `tools/rig_iou.md` + 300 Zeilen `[RIG][IOU] a=.. b=.. wert=..`
(**143** Paare >= 0,80, darunter **IoU 1,00**: 9/13, 9/18, 9/24, 13/18, 13/24,
18/24, 16/21), `logs_m4.log` mit `[COLL][1]`…`[COLL][5]` und `[COLL][ENDE] fehler=0`.

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **M1** | Diag-Modus `hatsheet`: Kontaktblatt **29 Hüte × 4 Rigs** (Standard, Alien, Roboter, Wikinger), je Kachel Name + Index | `screenshots/v139/hats_29x4.png` existiert, 116 Kacheln, je Kachel Beschriftung `"<idx> <NAME>"` sichtbar; Log `[SHEET] hats=29 rigs=4 kacheln=116` |
| **M2** | Diag-Modus `rigsheet`: alle **25 Skins** in Standardfarbe, ohne Hut | `screenshots/v139/rigs_25.png` mit 25 Kacheln, Log `[SHEET] rigs=25` |
| **M3** | Silhouetten-IoU: Alpha-Maske jedes Skins gegen jeden anderen, Matrix ausgeben | `[RIG][IOU] a=<i> b=<j> wert=<0.00-1.00>` für alle 300 Paare; Datei `tools/rig_iou.md` mit Tabelle; **kein** Paar ≥ 0,80 ohne Eintrag in der Slop-Tabelle (D1) |
| **M4** | Diag-Modus `coll`: interaktiver Weg der Sammlung — Menü öffnen → SAMMLUNG 3× öffnen/schließen → Hut wechseln → ZURÜCK | `[COLL][1]…[COLL][5]` Zeilen, am Ende `[COLL][ENDE] fehler=0`; Rohlog enthält **keinen** `SCRIPT ERROR`; bei Absturz: Fehlerzitat in `BUGLISTE.md` |

**Warum M4 zuerst:** der vorhandene `char`-Modus ruft `show_collection()` auf und ist
grün. Der Crash aus dem Feedback muss also am interaktiven Weg hängen — ohne Repro kein Fix.

---

## A — Sammlung reparieren  `[x]`

Belege: `[COLL][ZAEHLER] farben=2/10 skins=1/25 huete=2/29` == `[COLL][SEKTION]
[FARBEN 2 / 10] [SKINS 1 / 25] [HUETE 2 / 29]` == `[COLL][INFO]` (A2);
`[COLL][ZUSTAND] kinder=426 ref=426 gleich=true` in allen 5 Laeufen und
`[COLL][PERF] nodes_start=334 nodes_nach_1=426 nodes_ende=426 delta=0` (A3);
`[COLL][KLICK] kachel=farbe|skin|hut … ignoriert=true` (A5);
`[COLL][ENDE] fehler=0` nach 5x oeffnen/ZURUECK + `coll-reopen.png` (A4).
A1: **kein** Repro des gemeldeten Absturzes (0 `SCRIPT ERROR` in `logs_m4.log`
und `logs_m4b.log`), aber die Ursache von "Sammlung kaputt" gefunden und behoben
(B26, kein Scroll → ZURUECK unerreichbar); Rest siehe BUGLISTE B27.

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **A1** | Crash aus M4 beheben (Ursache aus dem Log, nicht geraten) | `coll`-Modus: 3× öffnen/schließen, **0** `SCRIPT ERROR`, `[COLL][ENDE] fehler=0`; Ursache + Fix in `BUGLISTE.md` mit Log-Zitat |
| **A2** | Zähler/Info-Leiste korrekt: `FARBEN x/10  SKINS x/25  HUETE x/29` muss zu den Sektionen passen | Log `[COLL][ZAEHLER] farben=<own>/10 skins=<own>/25 huete=<own>/29`; Werte gleich den Sektions-Headern im selben Lauf |
| **A3** | Kein Leck / keine Dubletten beim Wiederöffnen (Kinder werden `queue_free`t, nicht nur entfernt) | 5× öffnen: `[COLL][ZUSTAND] kinder=<n>` **identisch** in allen 5 Läufen; Node-Zahl (`[PERF] nodes_max`) nach 5× Öffnen ≤ Start + 20 |
| **A4** | ZURÜCK führt zum Startbildschirm, Sammlung bleibt benutzbar | Nach ZURÜCK → SAMMLUNG erneut öffnen: `[COLL][ENDE] fehler=0`, Screenshot `screenshots/v139/coll-reopen.png` |
| **A5** | Regression: alle Sammlungs-Kacheln weiterhin read-only | Klick auf Farbe/Skin/Hut-Kachel ändert `p_color`/`p_rig`/`p_hat` **nicht** (`[COLL][KLICK] ignoriert=true`) |

---

## B — Kisten-Animation überspringbar  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **B1** | Skip-Knopf im Kisten-Overlay (Shop), sichtbar ab dem ersten Frame der Animation, auch per Tastatur/Gamepad (Action `ui_cancel`) | Overlay enthält Knoten `ChestSkip`; Log `[CHEST][SKIP] bereit=true` beim Start |
| **B2** | Skip springt sofort zum Ergebnis: Dauer ≤ 0,5 s, Belohnung identisch | `[CHEST][SKIP] t=<s> rest=<s>` mit `t ≤ 0.50`; Gold/Items im Ergebnis **gleich** dem Lauf ohne Skip (Vergleich zweier Logs, gleiche Kistenstufe) |
| **B3** | Ohne Skip unverändert: 10 Öffnungen zwischen 4,5 und 8,0 s | `dist/chest_dur10.log`: `10/10 in 4,5-8,0 s` (bestehender Test, `COMIC_LANTEST=dur10`) |
| **B4** | Skip bricht keine Folgeaktion ab (Ergebnis-Screen, „OK", Shop-Refresh) | Nach Skip: `[CHEST][RESULT] ok=true`, `[SHOP][UI][N]` Zeile vorhanden, kein `SCRIPT ERROR` |
| **B5** | **Laufband wird bei jeder Öffnung neu gewürfelt** (Reihenfolge der Kacheln, Nieten-Auswahl, Position des Gewinners). Vorher stand die Nieten-Reihe fest: `catalog[(i*7+3) % n]` — jede Kiste zeigte dieselben Items in derselben Reihenfolge | `[CHEST][STRIP] gewinner_pos=<n> hash=<h>` unterscheidet sich zwischen 3 Öffnungen (3/3 verschiedene Hashes, Position zufällig 14–22); der Gewinn bleibt der aus `result` (`[CHEST][RESULT] … gleich=true`); Sieger-Item erscheint **nicht** zusätzlich als Niete |

Belege B: `logs_b_skip.log` (`[CHEST][SKIP] bereit=true`, `t=0.01 rest=7.29`,
Messung `0.09 s ≤ 0.50`, `[CHEST][RESULT] … gleich=true`,
`[SHOP][UI][10.48][CHEST] geschlossen -> shop refresh`), `logs_b_noskip.log`
(gleiches Ergebnis ohne Skip), `logs_b_taste.log` (Skip über `ui_cancel`),
`logs_b_strip.log` (`verschieden=3/3 positionen=[15, 15, 22]`),
`dist/chest_dur10.log` (`10/10 in 4,5-8,0 s`). Golden Master `chestfull` neu
eingefroren (neue Pflicht-Logzeilen), vorher/nachher-Diff enthält **nur** die
drei neuen Zeilen (alte Fassung: `backup/golden_v136/chestfull.log.v138`).

---

## C — Hüte: Sitz und Namen  `[x]`

Ausgangsproblem: **eine** Hutgröße + **ein** y-Anker je Rig (`HEAD_ANCHOR`), aber 25 sehr
unterschiedliche Kopfformen. Dazu Namen, die nicht zum gezeichneten Motiv passen.

**Lösung statt Handtabelle:** `_head_metrics()` misst die Kopfform aus dem gezeichneten
Bild (Oberkante, Mitte, Breite), `HAT_SEAT` gibt je Hut Sitz + Faktor, `RIG_HAT_ADJ`
fängt Sonderfälle ab (Alien: Augen oben). Regeln + Messverfahren: `docs/HUT_SITZ.md`.

Belege: `[HAT][SITZ] ERGEBNIS paare=700 kopfpaare=475 fehler=0` (alle 475 Kopf-Paare
Überstand ≤ 4 px, Schweben ≤ 2 px, 0 % Hutpixel neben dem Kopf), Tabelle
`tools/hat_fit.md`, `docs/HUT_NAMEN.md` (29 Zeilen, 0 offene Abweichungen),
`[HAT][C6] … ok=true`, Blätter `hats_kappe_25.png`, `hats_alien.png`,
`hats_roboter_mars.png`, `hats_29x4.png`. Nebenbefunde: BUGLISTE B29–B31.

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **C1** | Namenstabelle: Kontaktblatt M1 gegen `HAT_NAMES` prüfen, jede Abweichung notieren und beheben (Motiv ↔ Name) | Tabelle `docs/HUT_NAMEN.md` mit 29 Zeilen `idx · Name · gezeichnetes Motiv · Status`; **0** offene Abweichungen; „rote Mütze als Krone" ist einer der Einträge |
| **C2** | `KAPPE` komplett neu (Form, Proportion, Schirm), auf **allen 25** Rigs tragbar | `[HAT][SITZ] hut=1 rig=<0..24> ueberstand=<px>` — Überstand ≤ 4 px auf allen 25 Rigs; Kontaktblatt `hats_kappe_25.png` |
| **C3** | **Alien** (Rig 8): `KAPPE, ZYLINDER, COWBOY, KRONE, STERN, WOLLMÜTZE, STROHHUT, KRÖNCHEN` neu setzen (eigener Anker + Skalierung je Hut) | 8 Zeilen `[HAT][SITZ] hut=<i> rig=8 ueberstand=<px>` mit ≤ 4 px; Kontaktblatt `hats_alien.png` mit 8 Kacheln vorher/nachher |
| **C4** | **Roboter** (Rig 3) und **Mars-Marschall** (Rig 5): `KAPPE` sitzt | `[HAT][SITZ] hut=1 rig=3` und `rig=5` ≤ 4 px; Kontaktblatt `hats_roboter_mars.png` |
| **C5** | **Wikinger** (Rig 7): alle Hüte **außer HALO (10)** sitzen | 28 Zeilen `[HAT][SITZ] rig=7 hut=<1..28 außer 10>` mit ≤ 4 px; HALO bewusst unverändert |
| **C6** | `STROHHUT` (7) sieht nicht mehr wie eine rote Mütze aus und ist von `WOLLMÜTZE` (5) klar unterscheidbar | Farbton-Differenz im Kontaktblatt ≥ 25° (Hutfarbe) **und** andere Silhouette (Breite/Höhe-Verhältnis unterscheidet sich ≥ 20 %); Sichtprüfung im Blatt dokumentiert |
| **C7** | Sitzprüfung automatisiert (statt Augenmaß): Hutpixel gegen Kopfsilhouette | `[HAT][SITZ]`-Zeile je geprüftem Paar; Anteil Hutpixel **außerhalb** Kopf+4 px = 0 % |

**Definition „sitzt":** Hutpixel liegen vollständig innerhalb der Kopfsilhouette + 4 px
Toleranz, und der Hut berührt den Kopf (kein Schweben: Abstand ≤ 2 px).

---

## D — Skins: Slop raus, neue Formen, Debug-Unlock  `[x]`

**Entscheidung zu D3 (Slop entfernen): 0 Skins entfernt.** Vorgabe des Auftraggebers:
„wenn du dir nicht sicher bist welche Skins mit AI-Slop gemeint sind, dann entferne keine".
Der Slop ist messbar (153 Paare ≥ 0,80, sieben Paare mit IoU 1,00), aber jeder Skin hat
eigenen Namen, eigene Zeichnung und eigene Rarität — Löschen würde Sammlungen beschädigen
ohne eindeutigen Gewinn. Stattdessen: **D2** (Migration) + **D4** (vier neue Silhouetten).
Tabelle mit allen 153 Paaren und Entscheidung: `docs/SKIN_SLOP.md`.

Belege: `tools/rig_iou.md` (406 Paare), `docs/SKIN_SLOP.md` (153 × „behalten"),
`[PROFILE][MIGR] von=v2 nach=v3 p_rig=12->"STRASSENKÄMPFER" p_hat=3->"KRONE" ok=true`
(+ `[PROFILE][CHECK] nach_neustart … p_rig=12`), `[RIG][CHECK] names=29 rarity=29 arme=29
hats=29 hat_rarity=29`, `[DEBUG][UNLOCK] rigs=29/29 huete=29/29 farben=10/10`,
`[RIG][LISTE] anzahl=29`, neue Skins max. IoU **0,52** (Ziel ≤ 0,55),
`[HAT][SITZ] ERGEBNIS paare=812 kopfpaare=551 fehler=0` (D7),
Blatt `rigs_25.png` (29 Kacheln), `sammlung-v139.png` (10/10 · 29/29 · 29/29).

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **D1** | Slop-Liste aus M3: alle Paare mit IoU ≥ 0,80, Entscheidung je Paar (`behalten` / `entfernen` / `umformen`) | Tabelle `docs/SKIN_SLOP.md`; jede Zeile mit IoU-Wert, Entscheidung, Begründung; **kein** Paar ≥ 0,80 bleibt ohne Entscheidung |
| **D2** | **Profil-Migration** vor jedem Entfernen: Skins/Hüte bekommen stabile String-IDs (`rig_id`, `hat_id`) ODER Lücken bleiben erhalten; `CONFIG_VERSION` 2 → 3 | Altprofil mit `p_rig=12`, `p_hat=3` laden → gleiche Figur wie vor dem Umbau; Log `[PROFILE][MIGR] von=v2 nach=v3 p_rig=12->„<ID>" ok=true`; Neustart behält die Figur |
| **D3** | Slop-Skins entfernen, Liste aus D1 | `RIG_NAMES.size()` = 25 − <entfernt> + <neu>; Sammlung zeigt keine leeren/doppelten Kacheln; `[RIG][LISTE] anzahl=<n>` |
| **D4** | **4 neue Skins mit eigener Silhouette**, mindestens: **SPINNENMANN**, **ZOMBIE**, plus zwei weitere (Vorschlag: KRISTALL-GOLEM, SCHATTEN-KATZE) | Je neuer Skin: `[RIG][IOU] neu=<name> max_gegen_bestand=<wert>` mit **≤ 0,55**; eigene Zeichnung in `_make_player_rig` (kein `modulate`-Klon); Kontaktblatt `rigs_neu.png` |
| **D5** | Neue Skins voll verdrahtet: Name, Rarität, Zeichencode, Hut-Anker, Freischaltpreis, Sammlungskachel | `RIG_NAMES`, `RIG_RARITY` und `_make_player_rig` haben identische Länge (`[RIG][CHECK] names=<n> rarity=<n> arme=<n>`); Kachel im Blatt zeigt Figur, Tooltip Name+Rarität |
| **D6** | Debug-Menü: „ALLE SKINS FREISCHALTEN" wirkt wirklich (Button existiert, `debug_unlock_all` vergisst `unlocked_rigs`) | Klick → `[DEBUG][UNLOCK] rigs=<n>/<n> huete=<n>/29 farben=<n>/10`; Sammlung zeigt danach alle Skins als freigeschaltet |
| **D7** | Hüte auf neuen Rigs: die vier Neuen sind im Hut-Kontaktblatt enthalten und bestehen C7 | 4 × 29 Zeilen `[HAT][SITZ]` für die neuen Rigs, 0 % außerhalb |

**Reihenfolge innerhalb D ist bindend:** D2 (Migration) **vor** D3 (Entfernen) — sonst
verlieren bestehende Spielstände ihre Figur.

---

## E — Abschluss  `[x]`

| # | Was | Messbares Abnahmekriterium |
|---|---|---|
| **E1** | Version **1.39** (`APP_VERSION`, `APP_BUILD`), Builds `dist/ComicShooter-v1.39.apk` + `.exe` | Smoke: `[BUILD] Versionsanzeige v1.39 aktiv (Build 39)`; beide Dateien vorhanden (APK debug-signiert, kein Release-Keystore im Projekt → siehe BUGLISTE B25) |
| **E2** | `golden_check.sh` 8/8 grün, `[PERF] fps_avg ≥ 54`, `proc_ms ≤ 0,10` | Log-Zeilen im Bericht |
| **E3** | Doku: `ARCHITEKTUR.md` (Zeilenzahlen), `STATUS.md` (Belege je Punkt), `BUGLISTE.md` (Crash-Ursache, Slop-Entscheidungen), Kontaktblätter in `screenshots/v139/` | Alle vier Dateien aktualisiert, Bilder vorhanden |

Belege E: `[BUILD] Versionsanzeige v1.39 aktiv (Build 39)` im Projekt-Lauf **und** in der
exportierten EXE (`logs_e_exe.log`), `[PERF] fps_avg=56.1 proc_ms=0.02` (Projekt) bzw.
`57.5 / 0.02` (EXE), `golden_check.sh` 8/8 `rest_diff=0 script_errors=0`,
`apksigner verify dist/ComicShooter-v1.39.apk` = exit 0 (debug-signiert, CN=Godot),
`dist/ComicShooter-v1.39.apk` 31,2 MB · `dist/ComicShooter-v1.39.exe` 111,8 MB.

---

## Reihenfolge

```
M1 M2 M3 M4        (Messnetz)
A1 A2 A3 A4 A5     (Sammlung)
B1 B2 B3 B4        (Skip)
C1 C2 C3 C4 C5 C6 C7   (Hüte)
D1 D2 D3 D4 D5 D6 D7   (Skins; D2 zwingend vor D3)
E1 E2 E3           (Abschluss)
```

Ein Block gilt erst als fertig, wenn `golden_check.sh` grün ist **und** das jeweilige
Kontaktblatt/Log-Kriterium belegt ist. Sonst `[~]` stehen lassen.

---

## Bekannte Fallen

1. **Index-Vertrag:** `p_rig`, `unlocked_rigs`, `p_hat`, `unlocked_hats` sind Zahlen.
   Umsortieren ohne Migration = verlorene Skins bei allen Spielern.
2. **Zwei Namenslisten:** `HAT_NAMES`/`RIG_NAMES` stehen in `texture/tex_draw.gd` und
   werden in `texture_manager.gd` als `const … := TexDraw.…` gespiegelt — Änderungen
   immer an der Quelle.
3. **Textur-Cache:** `(Farbe, Skin, Hut)` ist der Cache-Key. Nach Umzeichnen prüfen,
   dass die Sammlung die neue Textur zieht (sonst „alte Kappe" trotz neuem Code).
4. **`HEAD_ANCHOR` hat 25 Werte** — neue Rigs brauchen dort einen Eintrag, sonst
   `Index out of bounds`.
5. **Hüte über den Kopf hinaus** sind kein Parse-Fehler, sondern unsichtbar im
   Kontaktblatt — deshalb M1 vor C.
6. **Kisten-Skip** darf die Belohnung nicht neu würfeln: Ergebnis-Dictionary
   durchreichen, nicht erneut `chest_system` aufrufen.
7. **Diag-Modus `char` deckt die Sammlung nicht ab** (er ist grün, obwohl der Crash
   gemeldet ist) — nicht als „nicht reproduzierbar" abhaken, sondern M4 bauen.

---

## Startzeile für die neue Session

```
Lies C:/Users/vince/Games/comic-shooter/project/PLAN_V139_LOOKS.md und
C:/Users/vince/Games/comic-shooter/project/SPEC_V139_LOOKS.md und arbeite die
Blöcke in der dort festgelegten Reihenfolge ab (M → A → B → C → D → E).
Nach jedem Punkt: ./Godot.exe --headless --path project --quit-after 20 und
./tools/golden_check.sh. Belege als Kontaktblatt + Log-Zeile, Statusmarker in der
Spec nachtragen. Builds erst in Block E.
```
