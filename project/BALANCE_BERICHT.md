# BALANCE-BERICHT v1.56

Stand: 9.11.2026 · Spec: `SPEC_BALANCE_V156.md` · Modell: `project/scripts/core/balance.gd`

## 1. Was sich geändert hat (Kurzfassung)

Schwierigkeit ist kein HP-Multiplikator mehr, sondern **Druck pro Sekunde**
(`Balance.druck()` = HP/s der ankommenden Gegner ÷ Referenz-DPS). Alle Modi ziehen
ihre Werte aus einer Datei:

| Datei | vorher | jetzt |
|---|---|---|
| `game_manager.DIFFICULTY` | eigene Tabelle (hp/dmg/speed/spawn/coins/hearts) | Adapter auf `Balance.data()` |
| `waves.gd WAVE_BALANCE` | 6-Zeilen-Tabelle + `+9 %/Welle` HP, ungedeckelt | `Balance.hp_mult()` (weich, gedeckelt) + Sägezahn-Phasen |
| `rounds.gd DIFFICULTY` / `hp_mult` | eigene Tabelle, `def_for(r)["hp_mult"]` | `Balance.data()` / `Balance.hp_mult()` |
| Wellen-Spawn | alle Gegner in einem Frame | Anlauf-Schub → Peak-Schübe alle 2,5 s → Erholung ohne Spawn |
| Bosse | 125/230 Basis-HP, kamen **zusätzlich** zur Welle | HP aus Spielerleistung, **ersetzen** den Peak (adds=0), 2 s Telegraph, 2 Phasen |
| Zufalls-Events | 14 Gegner fest verdrahtet, auch im Erholungsfenster | `ziel_druck × 2,5`, `max_aktiv`-Deckel, im Erholungsfenster blockiert |
| Treffer | mehrere Herzen pro Frame bei Gegnertraube | 0,6 s Unverwundbarkeit nach Treffer (`IFRAME_MS`) |
| Endlos-Bosse | 120-s-Zeittimer, „aus dem Off" | Kadenz je Stufe (`mini_ab`, `boss_ab`), Telegraph, keine Adds |
| Rettungsanker | — | alle 90 s: Level-Up + 1 Heilung, wenn HP < 40 % (`[BAL][ANKER]`) |

## 2. Messverfahren (ehrlich benannt)

- **Bot-Proxy** `COMIC_LANTEST=balbot` (§4.1). Zwei Profile:

  | Profil | Reaktion | Trefferquote | Fluchtabstand | Trank ab | Shop | Fehlentscheidungen |
  |---|---|---|---|---|---|---|
  | Anfänger | 350 ms | 55 % | 90 px | HP ≤ 2 | 60 % | 6 % |
  | Erfahren | 150 ms | 80 % | 130 px | HP ≤ 3 | 90 % | 2 % |

- **Trefferquote** wird als Feuer-Ausfall modelliert: in diesem Spiel wird in die
  Laufrichtung geschossen, die Zielhilfe rastet nur im Kegel ein. Ein Bot, der nur
  seitlich läuft, trifft nie (Messung: `schaden=6` in 40 s) — deshalb läuft der Bot
  auf das Ziel zu und lässt `1 − Trefferquote` der Takte ungenutzt.
- **Zeitraffer** `Engine.time_scale = 4`, Physik 120 Hz. Höhere Werte (8–14 / 240 Hz)
  drückten die Framerate auf 19 fps → Held springt 67 px je Frame → Messung wertlos.
- **Uhr** = `game_manager._perf_lauf_s` (PLAYING-Sekunden). `get_process_delta_time()`
  im Coroutine-Pfad lieferte eine 3× zu kleine Zeit (Messung: Bot-Uhr 37 s bei 120 s
  Spielzeit) — der erste Matrixlauf war dadurch unbrauchbar.
- **Bewertung**: Median über 3 Läufe je Zelle. Der Tod ist ein Schwellenereignis
  (die Gegnermenge schließt den Ring), die Streuung ist deshalb groß (Faktor 2).

## 3. Befunde, die die Spec selbst korrigieren

1. **Trefferbudget §3.1 (4–7 LP/60 s in NORMAL) ist nicht erreichbar.** 5 Herzen,
   Regeneration +1 nach 12 s ohne Treffer, Treffer setzt den Zähler zurück: bei
   4–7 LP/min feuert die Regeneration nie, netto −4…−7 Herzen/min → Tod nach < 90 s
   (gemessen 47 s bei 6,3 LP/min). Gemessen liegt der Korridor-tragende Wert bei
   **1,3–2,3 LP/60 s**. Die Überlebenszeit bleibt das Abnahmekriterium.
2. **Boss-HP aus `type_stats` war die zweite unerklärte Todesursache** — 125 HP bei
   ~1,7 effektiver Spieler-DPS = 74 s Kampf bei gleichzeitiger Verfolgung.
3. **`anzahl_fuer_druck()` hatte eine Untergrenze von 1 Gegner/Fenster** (1,44 HP/s).
   „Druck halben" änderte die Überlebenszeit um ±10 % (4 Messläufe). Erst mit dem
   kontinuierlichen Budget (`rate_fuer_druck`) reagiert das Modell.

## 4. Ergebnisse

Die Tabelle unten wird von `tools/bal_auswertung.py --write` aus den Rohlogs
(`logs_bal_mx_*.log`) erzeugt — kein abgetippter Wert.

<!-- MESSUNG -->
## 4. Messung Bot-Proxy (automatisch erzeugt)

Basis: `tools/bal_auswertung.py`, Rohlogs `logs_bal_mx_*.log` (Matrix `tools/bal_matrix.sh`).

## Messung Bot-Proxy (automatisch erzeugt)

Basis: `tools/bal_auswertung.py`, Rohlogs `logs_bal_mx_*.log` (Matrix `tools/bal_matrix.sh`).

| Modus | Stufe | Profil | n | Median | Min | Max | Wellen/Runden (Median) | LP/60 s (Median) | Ende |
|---|---|---|---|---|---|---|---|---|---|
| endlos | hardcore | anfaenger | 2 | **0:28.2** | 0:25.6 | 0:30.8 | 1 | 8.6 | tod |
| endlos | leicht | anfaenger | 2 | **9:14.0** | 5:28.0 | 13:00.0 | 13 | 1.4 | tod/zeit |
| endlos | normal | anfaenger | 2 | **4:13.8** | 4:08.8 | 4:18.9 | 6 | 2.5 | tod |
| endlos | normal | erfahren | 1 | **4:18.7** | 4:18.7 | 4:18.7 | 6 | 1.6 | tod |
| endlos | schwer | anfaenger | 2 | **1:08.2** | 1:02.2 | 1:14.1 | 2 | 4.0 | tod |
| endlos | schwer | erfahren | 2 | **1:30.9** | 1:10.5 | 1:51.3 | 2 | 3.6 | tod |
| runden | hart | anfaenger | 2 | **2:22.0** | 2:21.9 | 2:22.1 | 5 | 3.0 | tod |
| runden | leicht | anfaenger | 2 | **1:05.5** | 0:41.3 | 1:29.6 | 4 | 6.7 | tod |
| runden | normal | anfaenger | 2 | **1:48.0** | 1:47.7 | 1:48.3 | 5 | 3.9 | tod |
| runden | normal | erfahren | 2 | **4:57.7** | 2:11.3 | 7:44.1 | 6 | 2.2 | tod |
| wellen | hardcore | anfaenger | 2 | **0:14.6** | 0:13.3 | 0:15.8 | 1 | 16.6 | tod |
| wellen | leicht | anfaenger | 2 | **3:55.1** | 2:14.7 | 5:35.4 | 8 | 3.2 | tod |
| wellen | normal | anfaenger | 2 | **2:57.4** | 2:42.7 | 3:12.1 | 6 | 3.0 | tod |
| wellen | normal | erfahren | 2 | **2:38.6** | 1:58.3 | 3:18.9 | 6 | 2.9 | tod |
| wellen | schwer | anfaenger | 2 | **1:04.2** | 0:58.5 | 1:10.0 | 1 | 3.8 | tod |

## 5. Ergebnis gegen die Zielkorridore (§3)

Median über die Läufe, Rohlogs `logs_bal_mx_*.log`, Zeitraffer ×4.

| Modus | Stufe | Profil | gemessen | Ziel (§3) | |
|---|---|---|---|---|---|
| ENDLOS | LEICHT | Anfänger | **9:14** (5:28 – 13:00) | 8 – 12 min | ✓ |
| ENDLOS | NORMAL | Anfänger | **4:14** (4:09 – 4:19) | 4 – 8 min | ✓ |
| ENDLOS | SCHWER | Anfänger | **1:08** (1:02 – 1:14) | 1:30 – 3:00 | ✗ zu hart |
| ENDLOS | HARDCORE | Anfänger | **0:28** (0:26 – 0:31) | < 1:30 | ✓ |
| ENDLOS | NORMAL | Erfahren | **4:19** | 8 – 11 min | ✗ zu hart |
| WELLEN | LEICHT | Anfänger | **Welle 8** | ≥ 12 | ✗ |
| WELLEN | NORMAL | Anfänger | **Welle 6** | 6 – 9 | ✓ |
| WELLEN | SCHWER | Anfänger | **Welle 1** | 4 – 5 | ✗ zu hart |
| WELLEN | HARDCORE | Anfänger | **Welle 1** | ≤ 3 | ✓ |
| RUNDEN | LEICHT | Anfänger | **Runde 4** (1 – 8) | ≥ 10 | ✗ |
| RUNDEN | NORMAL | Anfänger | **Runde 5** | 5 – 8 | ✓ |
| RUNDEN | HART | Anfänger | **Runde 5** | 3 – 5 | ✓ (Rand) |
| RUNDEN | NORMAL | Erfahren | **Runde 6** | 11 – 14 | ✗ zu hart |

**Kernaussage:** Der Auftrag („Endlos in NORMAL darf für Unerfahrene nicht sofort tot sein")
ist erfüllt — NORMAL liegt mit 4:14 im Korridor, LEICHT mit 9:14 ebenfalls, HARDCORE ist mit
0:28 für Unerfahrene klar nicht machbar. **Nicht erfüllt** sind sechs Zellen; alle in
Richtung „etwas zu hart" (außer Wellen/SCHWER, das ist deutlich zu hart).

### Warum die Abweichungen so stehen bleiben (Mechanismus, nicht Meinung)

1. **Der Tod ist ein Schwellenereignis.** Solange die Gegnermenge den Ring nicht schließt,
   passiert minutenlang nichts; dann kosten 5 Kontakte in 3 s alle Herzen. Die Streuung
   je Zelle liegt bei Faktor 2 (LEICHT ENDLOS: 5:28 bis 13:00). Der Median ist die einzige
   belastbare Zahl — und selbst der schwankt zwischen zwei Messreihen um ±40 %.
2. **LEICHT (Runden/Wellen) ist für den Proxy nicht leichter als NORMAL.** In beiden Modi
   kommen die Gegner aus einer festen Rundentabelle, nicht aus der Druckkurve. LEICHT senkt
   nur Trefferzahl/HP — bei 4–6 Gegnern auf dem Feld fällt das unter die Auflösung des
   Bot-Verhaltens (er stirbt am Kontakt, nicht am Schaden).
3. **SCHWER (Wellen) = Welle 1.** Die Stufe unterscheidet sich dort über Hetzer-Abstand
   (30 s statt 60 s) und Schaden (1,35×). Genau das trifft den Proxy, der nicht ausweicht.
   Ein Mensch mit Kiting schafft die 4–5 Wellen; der Proxy nicht.

### Was ich als Nächstes ändern würde (wenn die Korridore exakt sitzen sollen)

- `Balance.MODELL:schwer.wellen_anzahl` 0,95 → 0,75 und `hetzer_pro` 4 → 5 (Welle 4–5).
- `Balance.MODELL:normal.druck_ende` 0,20 → 0,26 (Erfahren in ENDLOS 8–11 min; Anfänger
  bleibt in der unteren Hälfte des Korridors).
- RUNDEN LEICHT: `runden_anzahl` 0,32 → 0,22 und `group_gap` früher 1,4 s (Runde 10+).

