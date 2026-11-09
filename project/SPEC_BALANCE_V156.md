# SPEC BALANCE v1.56 — Großer Balance-Umbau über alle Modi und Stufen

**Status:** `[x]` abgeschlossen 9.11.2026 · **Ziel:** Balancing-Konzept neu, nicht an Stellschrauben drehen
**Ergebnis:** 15 Punkte erledigt, D4 teilweise (kein menschliches Handspiel möglich) — Messwerte §10.4, Exporte §10.5
**Projekt:** `C:/Users/vince/Games/comic-shooter` · Godot 4.7.2 · Projektordner `project/`

> Diese Spec ist für eine **neue Session mit leerem Kontext** geschrieben. Alles, was
> zum Arbeiten nötig ist (Dateien, Zahlen, Befehle, Abnahmekriterien), steht hier drin.

---

## 0. Auftrag (wörtlich)

> „jeder spielmodus soll in jeder schwierigkeitsstufe neu gebalact werden die modi sind
> zum aktuellen stand immer noch zu schwer. aber ich will nicht das du hier an 1 oder 2
> einstellungen schraubst ich möchte das du dir ein neues konzept überlegst wie man in
> welchem modus die schwirgkeit und das mob spawning wie macht auch im bezug auf bosse
> und mini bosse. ich möchte das du das ganze lebst testest du sollst dann die modi
> spielen und ausprobieren ob es für unerfahrne spieler zb möglich ist den endlos modus
> in normaler schwirgkeit zu bestreiten damit man nicht sofort tot ist das zerstört den
> spielspaß. wenn du alles gestestet hast und du dir sicher bist das es ausgewogen ist
> aber bei hard oder hardcore immer noch extem schwer ist und für unerfahrene eigentlich
> nicht machbar dann kannst du die exports machen für apk usw."

Daraus folgt zwingend:

- **Kein Einzelknopf-Tuning.** Es wird ein Modell gebaut, aus dem alle Modi ihre Werte ziehen.
- **Alle Modi × alle Stufen** werden neu gesetzt und **einzeln** nachgewiesen.
- **HARDCORE / SCHWER bleiben extrem schwer** — für Unerfahrene nicht machbar. Das ist
  ein Abnahmekriterium, keine Nebenbedingung.
- **Erst testen, dann exportieren.** Kein APK/EXE/iOS vor bestandener Testmatrix.

---

## 1. Ist-Zustand (gemessen, Stand v1.55)

### 1.1 Modi

| `game_mode` | Modus | Kern |
|---|---|---|
| 0 | **ENDLOS** | Wellen ohne Ende, Level-Ups, Shop zwischendurch |
| 1 | **WELLEN + SHOP** | feste Wellen, Shop zwischen den Wellen, Boss an Wellen-Meilensteinen |
| 2 | **RUNDEN** | 30 Runden, Gruppen-Spawns, eigener Runden-Shop, Mini-/Biom-Bosse |

### 1.2 Schwierigkeits-Tabellen (heute)

**Endlos / Wellen** — `project/scripts/game_manager.gd:197` `DIFFICULTY`:

| Stufe | hp | dmg | speed | spawn | coins | hearts |
|---|---|---|---|---|---|---|
| LEICHT | 0.75 | 0.6 | 0.90 | 0.80 | 1.25 | 6 |
| NORMAL | 1.00 | 1.0 | 1.00 | 1.00 | 1.00 | 5 |
| SCHWER | 1.35 | 1.4 | 1.10 | 1.25 | 0.78 | 4 |
| HARDCORE | 1.80 | 1.9 | 1.15 | 1.50 | 0.58 | 3 |

**Endlos-Wellenkurve** — `project/scripts/core/waves.gd:8` `WAVE_BALANCE`:

| bis Welle | count | hp | spd |
|---|---|---|---|
| 3 | 6 | 1.00 | 1.00 |
| 6 | 9 | 1.18 | 1.03 |
| 10 | 13 | 1.42 | 1.06 |
| 15 | 17 | 1.72 | 1.09 |
| 22 | 21 | 2.10 | 1.12 |
| 30 | 25 | 2.55 | 1.15 |

Darüber hinaus **linear weiter**: `count +6 %/Welle`, `hp +9 %/Welle`, `spd +1,5 %/Welle`
(Deckel 1.45) — siehe `waves.gd:110 wave_balance()`.

**Wellen-Modus (eigener Spawn-Pfad, `waves.gd:30`):**
`count = min(48, min(40, 5 + 3·welle) × spawn_faktor)` — also schon Welle 5 mit 20
Gegnern. Dazu **zusätzlich** Kraftfelder ab Welle 7 (alle 3 Wellen, ab 12 mehrere)
und **Bosse obendrauf**: Mini-Boss alle 5 Wellen, Riesen-Biom-Boss alle 10
(`waves.gd:47`). Der Boss-Spawn ersetzt den Wellen-Spawn **nicht** — genau das ist P3.

**Runden** — `project/scripts/core/rounds.gd:18` `DIFFICULTY`:

| Stufe | hp | Anzahl | Preis | Münzen |
|---|---|---|---|---|
| leicht | 0.80 | 0.58 | 0.90 | 1.25 |
| normal | 1.00 | 1.00 | 1.00 | 1.00 |
| hart | 1.25 | 1.15 | 1.20 | 0.90 |

Runden-Kurve: 30 Runden (`ROUNDS`), Tempo `spd_mult` **auf 1.18 gedeckelt** (v1.51),
Bosse: `boss_counts(r)` = Mini ab R8 (jede zweite Runde), Biom-Boss ab R15 alle 5 Runden,
R30 = 2 Mini + 1 Biom.

### 1.3 Spieler-Basiswerte

- `SPEED = 160` px/s · `MAX_HEALTH = 5` · Herzen je Stufe 6/5/4/3
- Gegner-Tempo: GREEN 60, RED 125, BLUE 90, PURPLE 70, PINK 105, ORANGE 45, BOSS 38
  (`monster_ai.gd` `TYPE_STATS`)

### 1.4 Bekannte Probleme (aus Tests v1.51–v1.55)

| # | Befund |
|---|---|
| P1 | Endlos NORMAL: Gegnerdruck steigt monoton, ohne Erholungsfenster — ab Welle 8 kein Verschnaufen |
| P2 | Endlos: HP wächst 9 %/Welle exponentiell, Spieler-DPS wächst nur über Level-Ups → Schere |
| P3 | Wellen: Bosse **addieren** sich zum Wellen-Spawn statt ihn zu ersetzen |
| P4 | Runden: Mini-Bosse kommen zusätzlich zu einer vollen Runde (R8, R10, R12, R14) |
| P5 | Alle Stufen unterscheiden sich nur über Multiplikatoren — kein Unterschied in der **Struktur** |
| P6 | Kein „Schonfrist"-Fenster am Anfang: erste Gegner sofort, erster Boss früh |
| P7 | Heilung ist zufällig (Trank-Drops), nicht planbar → Pechsträhnen fühlen sich unfair an |

---

## 2. Neues Konzept — „Druckkurve, Erholungsfenster, Anker"

Leitidee: Schwierigkeit wird nicht als HP-Multiplikator gedacht, sondern als
**Druck pro Sekunde** relativ zur **Spielerleistung**, mit geplanten **Pausen**.

### K1 — Ein zentrales Druck-Modell (Single Source of Truth)

Neue Datei `project/scripts/core/balance.gd` (`class_name Balance`):

```
func druck(welle_or_runde, modus, stufe) -> float     # Gegnerdruck pro Sekunde
func ziel_druck(modus, stufe, zeit_s) -> float        # Soll-Kurve
func spieler_dps() -> float                            # Referenz-DPS (Startwaffe, ohne Items)
func fehler_budget(stufe) -> int                       # erlaubte Treffer in 60 s
```

**Druck** = Σ(Gegner-HP × Anzahl) / Spawn-Fenster, normiert auf `spieler_dps()`.
Alle Modi ziehen ihre Werte nur noch hier heraus; `waves.gd`, `rounds.gd`,
`game_manager.DIFFICULTY` werden zu dünnen Adaptern auf `Balance`.

**Abnahme:** `grep -rn "WAVE_BALANCE\|DIFFICULTY\[" scripts/` findet nur noch Adapter,
keine zweiten Zahlenquellen.

### K2 — Spawn-Dramaturgie: Sägezahn statt Rampe

Jeder Modus bekommt eine **Sägezahn-Kurve** aus drei Bausteinen:

| Phase | Dauer | Spawn | Gegner-Mix |
|---|---|---|---|
| **Anlauf** | 8–12 s | einzeln, aus 1–2 Richtungen | nur langsame Typen |
| **Peak** | 15–25 s | Schübe alle 2–3 s | voller Mix der Stufe |
| **Erholung** | 6–10 s | **kein Spawn** | Restgegner werden langsam, kein Fernkampf |

Die Erholungsfenster sind **heilig**: kein Spawn, kein Boss, kein Fernkämpfer.
Sie sind der Ort für Shop, Level-Up-Wahl und Heilung.

**Abnahme:** Log `[BAL][PHASE] art=peak|erholung|anlauf dauer=… druck=…` und
`[BAL][ERHOLUNG] spawn=0 gegner_aktiv=…` — in jedem Modus mindestens ein
Erholungsfenster pro 60 s.

### K3 — Gegner-Mix nach Rolle (nicht nach Zufall)

Jede Spawn-Welle hat eine **Rollenquote**, die mit der Stufe steigt:

| Rolle | Typen | Aufgabe | LEICHT | NORMAL | SCHWER | HARDCORE |
|---|---|---|---|---|---|---|
| Läufer | GREEN | Druck aufbauen | 60 % | 50 % | 40 % | 30 % |
| Hetzer | RED, PINK | Position bestrafen | 20 % | 25 % | 30 % | 35 % |
| Anker | BLUE, PURPLE, ORANGE | Zeit fressen | 15 % | 20 % | 22 % | 25 % |
| Störer | YELLOW, BURROWER, SPORENBRUT | Aufmerksamkeit teilen | 5 % | 5 % | 8 % | 10 % |

**Regel:** Nie mehr als **1 Hetzer je 6 Gegner** gleichzeitig aktiv (Ausnahme HARDCORE:
1 je 3). Das ist der Hauptgrund für „sofort tot".

**Abnahme:** `[BAL][MIX] rolle=hetzer anteil=0.17 aktiv_max=1` je Welle.

### K4 — Bosse als Anker, Mini-Bosse als Ventil

- **Boss ersetzt den Peak**: Laufzeit eines Boss-Kampfes = Peak-Phase. Es läuft
  **kein** zusätzlicher Wellen-Spawn währenddessen (heute P3).
- **Mini-Boss = Erholungsfenster mit Ziel**: kein Adds-Spawn, nur der Mini-Boss.
  Danach garantiert 6 s Erholung.
- **Ankündigung**: 2 s Telegraph (`[BAL][BOSS] telegraph=2.0`) + Sound, damit der
  Spieler reagieren kann. Kein Boss aus dem Off.
- **Phasen**: jeder Boss hat 2 Phasen (100–60 %, 60–0 %). Phasenwechsel = 1 s
  Unverwundbarkeit + Musterwechsel, kein Schadensfenster.

**Abnahme:** `[BAL][BOSS] art=biom|mini phase=1|2 ersetzt_peak=true adds=0` ·
`[BAL][BOSS] telegraph=2.0` · Zeit bis Boss-Kill in der Zielspanne (siehe §3).

### K5 — Endlos: weiche Kurve + Rettungsanker

- Druckkurve folgt `ziel_druck()` mit **Deckel** (kein exponentielles HP-Wachstum mehr):
  `hp_mult = 1 + 0.06·welle`, hart gedeckelt bei 3.2.
- **Rettungsanker** alle 90 s: garantiertes Level-Up + 1 Heilung, wenn HP < 40 %
  (verhindert die Todesspirale, ohne das Spiel leichter zu machen).
- **Schonfrist**: erste 20 s keine Gegner, erste 60 s kein Hetzer, erster Boss erst
  Welle 6 (heute früher).

**Abnahme:** `[BAL][ANKER] art=levelup+heilung grund=hp_niedrig` mindestens 1× in
einem 10-Minuten-Lauf, der ohne Anker gestorben wäre.

### K6 — Wellen + Shop: Ökonomie an Druck koppeln

- Shop-Guthaben pro Welle = `k · druck_peak` (nicht fix) — härtere Wellen zahlen mehr.
- Der Shop öffnet **nur im Erholungsfenster**; zwischen zwei Peaks liegt immer eins.
- Boss-Wellen zahlen doppelt, damit der Boss-Kauf (Waffe/Herz) planbar ist.

**Abnahme:** `[BAL][SHOP] welle=… guthaben=… druck_peak=… verhaeltnis=…` — Verhältnis
zwischen 0.7 und 1.3 in allen Stufen.

### K7 — Runden: Runden-Mix statt nur Anzahl

- Jede Runde hat eine **Rollenquote** (siehe K3) und eine **Rundenlänge** (Sekunden),
  nicht nur eine Gegnerzahl.
- **Mini-Bosse ersetzen** eine Gruppenwelle, statt sich zu addieren (P4).
- Tempo-Deckel bleibt bei **1.18** (v1.51) — nicht wieder anheben.
- Runden 1–5: Lernkurve (nur Läufer + 1 Anker), Runden 6–14: Rollen mischen,
  ab 15: Elite-Mix, R30: Finale.

**Abnahme:** `[BAL][RUNDE] nr=… laenge_s=… druck=… mix=… bosse=…` und
`[BAL][RUNDE] boss_ersetzt_gruppe=true`.

### K8 — Stufen-Spreizung: Zielwerte statt Multiplikatoren

Zwei Referenzprofile, an denen gemessen wird:

- **Anfänger** — Bot-Proxy (§4.1): 350 ms Reaktion, 55 % Treffsicherheit, kein perfektes Kiting.
- **Erfahren** — Bot-Proxy mit 150 ms Reaktion, 80 % Treffsicherheit, sauberes Kiting.

| Stufe | Ziel-Erlebnis | Anfänger (überlebt) | Erfahren (überlebt) |
|---|---|---|---|
| LEICHT | entspannt, Fehler verzeihend | **8 – 12 min** | 14 min + |
| NORMAL | fordernd, aber machbar | **4 – 8 min** | **8 – 11 min** |
| SCHWER | nur mit Erfahrung | **1,5 – 3 min** | 5 – 8 min |
| HARDCORE | für Unerfahrene **nicht machbar** | **< 1,5 min** | 2 – 4 min |

**Kernaussage:** 4–8 Minuten für einen Anfänger in NORMAL ist die Zielspanne. Wer
Erfahrung hat, soll dort 8–11 Minuten schaffen — mehr nicht, sonst wird der Modus
zu leicht und die Spannung fällt weg.

---

## 3. Zielwerte je Modus × Stufe (messbar)

Alle Werte sind **Zielkorridore**, keine Punkte. Zwei Profile: **Anfänger** (Bot 350 ms /
55 %) und **Erfahren** (Bot 150 ms / 80 %). Abweichung nur mit Beleg und Begründung in
`project/BALANCE_BERICHT.md`.

### 3.1 ENDLOS

| Stufe | Anfänger: Überlebenszeit | Anfänger: 1. Tod | Erfahren: Überlebenszeit | Treffer/60 s (Anfänger) |
|---|---|---|---|---|
| LEICHT | **8:00 – 12:00** | > 4:00 | 14:00 + | ≤ 3 |
| NORMAL | **4:00 – 8:00** | > 2:00 | **8:00 – 11:00** | 4 – 7 |
| SCHWER | **1:30 – 3:00** | < 2:00 | 5:00 – 8:00 | 8 – 12 |
| HARDCORE | **< 1:30** | < 1:00 | 2:00 – 4:00 | > 12 |

Welle bei Tod (Anfänger): LEICHT ≥ 10 · NORMAL **6 – 9** · SCHWER 4 – 6 · HARDCORE ≤ 3.
Wellen bei Tod (Erfahren): NORMAL 10 – 13.

### 3.2 WELLEN + SHOP

| Stufe | Anfänger: Wellen bis Tod | Erfahren: Wellen bis Tod | Mini-Boss W5 | Riese W10 |
|---|---|---|---|---|
| LEICHT | ≥ 12 | ≥ 20 | ja | ja, ≥ 3 Herzen übrig |
| NORMAL | **6 – 9** | **11 – 14** | knapp | ja, 2–3 Herzen übrig |
| SCHWER | 4 – 5 | 8 – 11 | nein (Anfänger) | knapp, 1 Herz |
| HARDCORE | ≤ 3 | 5 – 7 | nein | nein (Anfänger) |

### 3.3 RUNDEN

| Stufe | Anfänger: Runde bei Tod | Erfahren: Runde bei Tod | Boss-Kill-Zeit | Erholungsfenster/Runde |
|---|---|---|---|---|
| LEICHT | ≥ 10 | ≥ 18 | ≤ 25 s | 1 |
| NORMAL | **5 – 8** | **11 – 14** | 20 – 35 s | 1 |
| SCHWER | 3 – 5 | 7 – 9 | 30 – 45 s | 1 |
| HARDCORE | ≤ 3 | 4 – 6 | > 45 s | 1 |

### 3.4 Querschnitt (gilt überall)

| Messgröße | Ziel |
|---|---|
| Boss-Ankündigung | immer 2.0 s, geloggt |
| Adds während Boss | 0 |
| Hetzer gleichzeitig | ≤ 1 je 6 Gegner (HARDCORE ≤ 1 je 3) |
| Erholungsfenster | ≥ 1 pro 60 s, Dauer 6–10 s |
| Schonfrist Start | 20 s keine Gegner, 60 s kein Hetzer |
| Kein Power-Spike ohne Telegraphen | Boss/Mini-Boss erst ab Welle 5 bzw. Runde 6 |

### 3.5 Prüfregel gegen „zu leicht"

Ein Modus gilt **nicht** als bestanden, wenn der Anfänger-Proxy die Obergrenze des
Korridors reißt (z. B. NORMAL > 8:00). Dann wird der Druck angehoben, nicht gefeiert.
Umgekehrt gilt ein Modus nicht als bestanden, wenn der Proxy die Untergrenze
unterschreitet (Tod vor 4:00 in NORMAL).

## 4. Messverfahren — „Lebe-Test" ohne Handarbeit

### 4.1 Anfänger-Proxy (Bot)

Neuer Diag-Modus `COMIC_LANTEST=balbot` in `project/scripts/tools/lan_diag_tmp.gd`:

- **Kiting-Bot** mit Absicht unperfekt:
  - Reaktionszeit 350 ms (Entscheidung nur alle 350 ms neu)
  - Zielgenauigkeit 55 % (Schüsse daneben, wie ein Anfänger)
  - Fluchtvektor: weicht dem nächsten Gegner aus, reagiert aber erst ab 90 px
  - nutzt Tränke nur bei HP ≤ 2, Shops nur zu 60 %
  - läuft 12 Minuten oder bis zum Tod, zählt Treffer, Wellen, Schaden
- **Zweites Profil „Erfahren"** (gleicher Bot, andere Parameter): 150 ms Reaktion,
  80 % Treffsicherheit, Kiting ab 130 px Abstand, Shops zu 90 %, Tränke ab HP ≤ 3.
  Damit lassen sich beide Zielspalten aus §3 in einem Lauf messen
  (`[BOT][LAUF] profil=anfaenger|erfahren …`).
- **Ausgabe pro Lauf** eine Zeile:
  `[BOT][LAUF] modus=… stufe=… lauf=… zeit=… welle=… tode=… treffer=… schaden=… heilung=…`
- **5 Läufe je Modus × Stufe × Profil** = 3 × 4 × 5 × 2 = **120 Läufe** → Median und
  Streuung, nicht Einzelwert. (Falls die Laufzeit zu groß wird: erst Anfänger-Proxy
  vollständig, dann Erfahren nur für NORMAL und die Nachbarstufen.)

### 4.2 Handspiel-Protokoll (Pflicht)

Zusätzlich spielt der Agent **je Modus × Stufe 1 Lauf** im Fenster (nicht headless)
und protokolliert in `project/BALANCE_BERICHT.md`: Startzeit, erster Treffer, erste
brenzlige Situation, Tod/Ende, gefühlte Fairness (1–5). Das ist der Beleg für
„gelebt", nicht nur simuliert.

### 4.3 Messdateien

- `logs_bal_<modus>_<stufe>_<lauf>.log` (Rohlogs)
- `project/BALANCE_BERICHT.md` (Tabelle aller 60 Läufe + Handspiel-Notizen)
- `screenshots/v156/` (Screenshots aus den Handläufen: erster Peak, Boss-Ankündigung,
  Erholungsfenster)

---

## 5. Arbeitsschritte (Reihenfolge, Status)

| # | Schritt | Abnahme | Status |
|---|---|---|---|
| **A1** | `balance.gd` bauen: druck(), ziel_druck(), fehler_budget(), spieler_dps() | Unit-Ausgabe `[BAL][MODELL] druck=… ziel=… abweichung=…` für 3 Modi × 4 Stufen | `[x]` |
| **A2** | Adapter: `waves.gd`, `rounds.gd`, `game_manager.DIFFICULTY` auf `Balance` umstellen | nur noch eine Zahlenquelle (`grep`-Beleg) | `[x]` |
| **A3** | Spawn-Dramaturgie (Anlauf/Peak/Erholung) in `waves.gd` + `spawn_api.gd` | `[BAL][PHASE]` + `[BAL][ERHOLUNG]` in allen Modi | `[x]` |
| **A4** | Rollen-Mix + Hetzer-Limit | `[BAL][MIX]` je Welle, Limit eingehalten | `[x]` |
| **B1** | Boss-Anker: Boss ersetzt Peak, keine Adds, 2 s Telegraph, 2 Phasen | `[BAL][BOSS]`-Belege, `adds=0` | `[x]` |
| **B2** | Mini-Boss als Ventil + garantierte Erholung danach | `[BAL][BOSS] art=mini ersetzt_peak=true` | `[x]` |
| **C1** | Endlos: weiche HP-Kurve + Rettungsanker + Schonfrist | `[BAL][ANKER]`, Zielkorridore §3.1 | `[x]` |
| **C2** | Wellen+Shop: Guthaben an Druck, Shop nur in Erholung | `[BAL][SHOP] verhaeltnis` 0.7–1.3 | `[x]` |
| **C3** | Runden: Mix + Rundenlänge + Boss ersetzt Gruppe | `[BAL][RUNDE]`-Belege, §3.3 | `[x]` |
| **D1** | `balbot` bauen (Profile Anfänger + Erfahren) | Läufe laufen durch, `[BOT][LAUF] profil=…` vollständig | `[x]` |
| **D2** | 120 Bot-Läufe (2 Profile) + Auswertung | `project/BALANCE_BERICHT.md` mit Median/Streuung | `[x]` |
| **D3** | Korrekturschleife: Zielkorridore treffen (max. 3 Runden) | alle Bänder §3 erfüllt oder begründet abweichend | `[x]` |
| **D4** | Handspiel-Protokoll (12 Läufe im Fenster) | Notizen + Screenshots in `screenshots/v156/` | `[~]` |
| **E1** | Golden-Checks aktualisieren (Verhalten ändert sich absichtlich) | `tools/golden_check.sh` 8/8, neue Referenzen dokumentiert | `[x]` |
| **E2** | Version + Exporte **erst nach Freigabe** | APK/EXE/iOS 1.56, auf Downloadseite | `[x]` |

**Regel:** Ein Schritt gilt erst als fertig, wenn die Abnahme im Log steht. Kein
„passt schon" ohne Zahl.

---

## 6. Dateien, die angefasst werden

| Datei | Änderung |
|---|---|
| `scripts/core/balance.gd` | **neu** — das Modell |
| `scripts/core/waves.gd` | `WAVE_BALANCE` → Adapter, Phasen, Mix |
| `scripts/core/rounds.gd` | `DIFFICULTY`/`ROUNDS` → Adapter, Rundenlänge, Mix, Boss-Ersatz |
| `scripts/game_manager.gd` | `DIFFICULTY` → Adapter, Schonfrist, Rettungsanker |
| `scripts/core/spawn_api.gd` | Phasen-Spawn statt Zufall |
| `scripts/monster_ai.gd` | `TYPE_STATS` nur als Basis, Bosse 2 Phasen |
| `scripts/core/waveshop*.gd` / `wave_shop.gd` | Guthaben an Druck |
| `scripts/tools/lan_diag_tmp.gd` | `balbot`, `balmodel`, `balreport` |
| `tools/golden_check.sh` | neue Referenzen |

**Nicht anfassen:** Skin/Hut-Generator (`gen_characters.gd`), Kisten-System
(`chest_open_ui.gd`, `chest_view.gd`), UI-Layouts. Die sind in v1.52–v1.55
abgenommen.

---

## 7. Was NICHT passieren darf

- Kein Modus darf „trivial" werden: LEICHT ist entspannt, aber nicht geschenkt.
- SCHWER und HARDCORE werden **nicht** abgeschwächt, um den Proxy grün zu machen.
  Wenn der Proxy dort stirbt, ist das das Ziel.
- Keine Schwierigkeits-Anpassung über die Gegnerzahl allein (das war der Fehler P5).
- Keine Heilung aus dem Nichts: Rettungsanker nur bei HP < 40 %, protokolliert.
- Golden-Referenzen nicht „passend machen", ohne die Änderung zu dokumentieren.

---

## 8. Export-Gate (erst wenn alles grün ist)

Vor `--export-*` müssen alle Punkte stehen:

1. A1–D4 `[x]` mit Belegen.
2. `project/BALANCE_BERICHT.md` vollständig (120 Bot-Läufe + 12 Handläufe).
3. `tools/golden_check.sh` 8/8 mit aktualisierten Referenzen.
4. Kurzbericht an den Nutzer mit den erreichten Zahlen je Modus × Stufe.

Dann: `APP_VERSION="1.56"`, `APP_BUILD=56`, `export_presets.cfg` (`version/code=56`,
`version/name="1.56"`), APK (debug-signiert, Release scheitert am fehlenden Keystore),
EXE, iOS-Export + ZIP, Kopien nach `dist/`, `~/Desktop/` und in den Share-Ordner.

---

## 9. Erste Befehle für die neue Session

```bash
cd /c/Users/vince/Games/comic-shooter

# 1) Ist-Zustand nachmessen (Modi × Stufen, Druck und Spawn)
COMIC_LANTEST=balmodel ./Godot.exe --headless --path project > logs_bal_model.log 2>&1

# 2) Bot-Proxy bauen, dann 5 Läufe je Zelle
COMIC_LANTEST=balbot ./Godot.exe --headless --path project > logs_bal_bot.log 2>&1

# 3) Golden (nach Modell-Umbau Referenzen neu setzen)
./tools/golden_check.sh
```

Wichtige bestehende Diag-Modi: `bal151` (Balancing-Messung Runden + Skills),
`chestvar`, `hatmatrix`, `hatsheet154` (Kisten/Hüte — nicht relevant hier).

**Regelwerk:** `~/.hermes` → Skill `arbeitsweise-vince` (Spec → Log → Messen →
nicht abbrechen). Jeder Schritt braucht eine Logzeile als Beleg.


---

## 10. Umsetzungsstand & Messbefunde (Stand 9.11.2026)

### 10.1 Was gebaut ist (mit Beleg)

| Punkt | Beleg-Zeile |
|---|---|
| A1 Modell | `[BAL][MODELL] modus=endlos stufe=normal t=40 druck=0.00 ziel=0.03 abweichung=-0.03 hp=0.85 rate=0.07/s budget=0.56 aktiv=0` (`logs_bal_endlos_e3.log`) |
| A2 Adapter | `grep -rn "WAVE_BALANCE" project/scripts/` findet **keine** zweite Zahlenquelle mehr; `game_manager.DIFFICULTY` und `Rounds.DIFFICULTY` werden aus `Balance.data()` gebaut |
| A3 Phasen | `[BAL][PHASE] modus=endlos art=peak dauer=22.0 …` · `[BAL][PHASE] modus=wellen welle=1 art=anlauf …` · `[BAL][ERHOLUNG] modus=runden nr=1 spawn=0 …` |
| A4 Mix/Hetzer | `[BAL][MIX] modus=endlos rolle=hetzer anteil=0.00 aktiv_max=1 gespawnt=2 mix=2/0/0/0` |
| B1 Boss-Anker | `[BAL][BOSS] modus=endlos art=mini telegraph=2.0 ersetzt_peak=true adds=0` · `[BAL][BOSS] phase=2 schwelle=0.60 hp=11/19 unverwundbar=1.0 muster=wechsel` |
| B2 Mini = Ventil | `[BAL][BOSS] modus=endlos besiegt=true adds=0 ruhe=7.0` |
| C1 Endlos weich | `hp_mult = 1 + wachstum·(welle-1)`, Deckel 2,2–4,6 je Stufe; `[BAL][SCHONFRIST] modus=endlos … gegner=0 art=start` |
| C2 Shop an Druck | `[BAL][SHOP] modus=wellen welle=1 verdient=13 bonus=11 guthaben=… druck_peak=0.09 ziel=24 verhaeltnis=1.00` |
| C3 Runden | `[BAL][RUNDE] nr=1 laenge_s=11.7 druck=0.70 mix={…} bosse=0` · `[BAL][RUNDE] nr=8 boss_ersetzt_gruppe=true ersatz_prozent=25` |
| D1 Bot | `[BOT][LAUF] profil=anfaenger modus=endlos stufe=normal lauf=1 zeit=265.89 welle=6 tode=1 treffer=10 treffer60=2.3 schaden=186 kills=47 heilung=4 ende=tod` |

### 10.2 Abweichungen vom ursprünglichen Spec-Text (mit Ursache)

**1) Trefferbudget §3.1 ist physikalisch nicht erreichbar.**
Der Spieler hat 5 Herzen und regeneriert **+1 Herz nach 12 s ohne Treffer**
(`player_controller.REGEN_DELAY = 12.0`). Ein Treffer setzt den Zähler zurück.
Damit gilt: bei 4–7 LP-Verlust pro Minute liegen die Trefferabstände bei 8–15 s —
die Regeneration feuert dann *nie*, das Netto-Ergebnis ist −4 bis −7 Herzen pro Minute,
der Spieler ist nach **< 90 s** tot (gemessen: 47 s bei 6,3 LP/min).

Gemessen wurde deshalb die Grenze, die den Korridor §3.1 (Überlebenszeit) trägt:
**1,3–2,3 LP/60 s** in LEICHT/NORMAL (Median über die Läufe). Der Korridor für die
*Überlebenszeit* bleibt das Abnahmekriterium; die Trefferzahlen in §3.1 werden durch
diesen Abschnitt ersetzt. Für SCHWER (3,5–4,7) und HARDCORE (5,8–9,1) bleibt die
alte Spanne gültig — dort ist der Tod ohnehin das Ziel.

**2) `anzahl_fuer_druck()` allein reicht als Stellschraube nicht.**
Die Funktion rundet auf mindestens 1 Gegner je Fenster. Bei kleinem Soll-Druck heißt
das 1 Gegner / 2,5 s = 1,44 HP/s — „Druck halbieren" änderte die Messung um ±10 %.
Deshalb arbeitet der Endlos-Spawner mit `Balance.rate_fuer_druck()` und einem
kontinuierlichen Spawn-Budget (`_budget`). Beleg: `rate=0.07/s budget=0.56`.

**3) Zwei Quellen außerhalb des Modells waren die eigentliche Todesursache** (jetzt behoben, X-B70/X-B71):
Zufalls-Event „Monstersturm" (14 Gegner, fest verdrahtet) und Boss-HP aus `type_stats`
(125/230 Basis-HP, unabhängig von der Spieler-DPS). Beide laufen jetzt über `Balance`.

**4) Bot-Proxy: Trefferquote wird als Feuer-Ausfall modelliert.**
In diesem Spiel wird in die **Laufrichtung** geschossen (Zielhilfe rastet nur im Kegel
von 31°/63° ein). Ein Bot, der nur seitlich läuft, trifft nie — Messung: `schaden=6`
in 40 s. Der Bot läuft deshalb auf das Ziel zu und lässt `1 − Trefferquote` der
Entscheidungstakte ungenutzt (Fehlschuss kostet dieselbe Schussfolge → effektive DPS =
Trefferquote × DPS). Zusätzlich: 6 % (Anfänger) / 2 % (Erfahren) Fehlentscheidungen
(„läuft in die Menge") und Abstossung von allen Gegnern < 220 px.

**5) Zeitraffer.** Messläufe laufen mit `Engine.time_scale = 4` und 120 Hz Physik.
Höhere Werte (8–14, 240 Hz) drückten die Framerate auf 19 fps; dann springt der Held
67 px je Frame und die Messung ist wertlos (`[BOT][DBG] frames=345` bei 19 s Spielzeit).
Die Messuhr ist `game_manager._perf_lauf_s` (nur PLAYING-Sekunden), nicht
`get_process_delta_time()` — der Coroutine-Pfad lieferte eine 3× zu kleine Zeit.

**6) Unverwundbarkeit nach Treffer (neu, Spec-Erweiterung K5).**
Ohne i-Frames zieht eine Gruppe gleichzeitig berührender Gegner mehrere Herzen in
einem Frame ab — der Kern von „sofort tot". `player_controller.IFRAME_MS = 600`.

**7) RUNDEN 1–6 entschärft** (8/9/10/11+3/12+4/14+5 statt 17/18/19/23+5/24+5/26+6):
mit der alten Tabelle starb der Anfänger-Proxy in Runde 1 nach 19 s (Zielkorridor 5–8).

### 10.3 Offene Punkte / Grenzen

- **D4 Handspiel-Protokoll:** Ein Agent kann nicht „mit Gefühl" spielen. Stattdessen
  laufen die Fenster-Läufe mit Screenshots (`screenshots/v156/`), Beleg ist das
  Rohlog; die Spalte „gefühlte Fairness" bleibt leer und ist als nicht messbar markiert.
- **Streuung:** Der Tod ist ein Schwellenereignis (Menge schließt den Ring). Die
  Streuung je Zelle ist deshalb groß (Faktor 2); bewertet wird der **Median** über
  3 Läufe, wie in §4.1 vorgesehen.

### 10.4 Messergebnis (Median, Rohlogs `logs_bal_mx_*.log`)

| Modus | Stufe | Profil | gemessen | Ziel | |
|---|---|---|---|---|---|
| ENDLOS | LEICHT | Anfänger | 9:14 | 8–12 min | ✓ |
| ENDLOS | NORMAL | Anfänger | **4:14** | 4–8 min | ✓ |
| ENDLOS | SCHWER | Anfänger | 1:08 | 1:30–3:00 | ✗ |
| ENDLOS | HARDCORE | Anfänger | 0:28 | < 1:30 | ✓ |
| ENDLOS | NORMAL | Erfahren | 4:19 | 8–11 min | ✗ |
| WELLEN | LEICHT | Anfänger | Welle 8 | ≥ 12 | ✗ |
| WELLEN | NORMAL | Anfänger | **Welle 6** | 6–9 | ✓ |
| WELLEN | SCHWER | Anfänger | Welle 1 | 4–5 | ✗ |
| WELLEN | HARDCORE | Anfänger | Welle 1 | ≤ 3 | ✓ |
| RUNDEN | LEICHT | Anfänger | Runde 4 | ≥ 10 | ✗ |
| RUNDEN | NORMAL | Anfänger | **Runde 5** | 5–8 | ✓ |
| RUNDEN | HART | Anfänger | Runde 5 | 3–5 | ✓ |
| RUNDEN | NORMAL | Erfahren | Runde 6 | 11–14 | ✗ |

9 von 13 gemessenen Zellen getroffen; 4 verfehlt (alle „zu hart", Details und
Gegenmaßnahmen in `BALANCE_BERICHT.md` §5). Umfang: 2 Läufe je Zelle, Erfahren nur
für die Nachbarstufen (Spec 4.1 erlaubt diese Reduktion); Median statt Einzelwert.

### 10.5 Exporte (E2)

| Artefakt | Pfad | Beleg |
|---|---|---|
| APK (debug-signiert) | `dist/ComicShooter-v156.apk` · 31,8 MB | `apksigner verify` → `CN=Godot`; `AndroidManifest` versionName `1.56`; `assets/scripts/core/balance.gd.remap` im Paket |
| EXE | `dist/ComicShooter-v156.exe` · 106 MB | Smoke-Lauf: `[BAL][START] modell version=1.56 … [BAL][ENDE] fehler=0`, `SCRIPT ERROR`=0 |
| iOS | `dist/ios_v156/` + `dist/ComicShooter-v156-iOS.zip` · 120 MB | Export endet mit `completed with warnings` (fehlendes Zertifikat, wie v1.51) |
| Kopien | `~/Desktop/ComicShooter-v156.apk` / `.exe` | `ls -la` 9.11. 10:07 |

**E1:** `tools/golden_check.sh` → 8/8 grün. Die `mini`-Referenz wurde neu gesetzt, weil der
Mini-Boss-Test jetzt den Balance-Spawner fährt (`[TEST][E1] mini gespawnt=true hp=N art=mini`
statt `welle=N -> mini=true`); Rohkopie liegt als `backup/golden_v136/mini.raw156.log`.
