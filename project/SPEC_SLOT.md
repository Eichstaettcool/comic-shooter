# SPEC · Einarmiger Bandit im Shop + neue Kosmetik + Kisten-Reveal

Status: Entwurf 1 · Ziel-Version v1.24
Autor: Hermes · Projekt: Comic Shooter (Godot 4.7)

---

## 1. Ziel

Ein **Gold-Slot** („Glückswalze") im Shop, der **ausschließlich Gold** ausschüttet —
keine Edelsteine, keine Kosmetik, keine Run-Boosts. Damit bleibt die Wirtschaft
zwischen Shop und Kisten getrennt:

```
Run  →  Gold  →  [Glückswalze]  →  Gold  (Glücksspiel, RTP < 100 %)
                 [Umtausch]     →  Edelsteine
                 [Kisten]       →  Kosmetik
```

Der Slot ist **kein Fortschrittsvehikel**, sondern ein Zeitvertreib mit Spannung.
Er darf langfristig Gold kosten (RTP ≈ 92 %), damit er die Wirtschaft nicht
aufbläst.

## 2. Nicht-Ziele

- Kein Echtgeld, keine Gems, keine Items aus dem Slot.
- Kein Auto-Spin ohne Limit (max. 10 Spins am Stück).
- Keine progressive Jackpot-Verkettung über Sessions.

---

## 3. Mechanik

### 3.1 Aufbau

- **3 Walzen × 1 Reihe**, eine einzige Gewinnlinie (Mitte).
- Walzen stoppen **von links nach rechts** (0,55 s / 0,75 s / 1,05 s) —
  die letzte Walze ist die langsamste, dort entsteht die Spannung.
- Einsatz wählbar: **50 / 100 / 250 Gold** (Standard 100).
- Ein Spin dauert ~1,6 s bis zum ersten Ergebnis, ~2,4 s mit Gewinn-Animation.

### 3.2 Symbole und Gewichte

| Symbol | Gewicht je Walze | Bedeutung |
|---|---|---|
| `cherry` | 22 | kleine Gewinne |
| `bell` | 18 | mittlere Gewinne |
| `bar` | 12 | mittlere Gewinne |
| `gold1` | 9 | Goldstufe 1 |
| `gold2` | 5 | Goldstufe 2 |
| `gold3` | 1.5 | Jackpot-Symbol |
| `skull` | 32.5 | Niete |

Gewichte sind **pro Walze identisch** (kein Near-Miss-Tuning über die Walzenstreifen —
das wäre manipulativ und ist für ein Freundschaftsspiel nicht angemessen).

### 3.3 Auszahlungstabelle (Vielfaches des Einsatzes)

| Kombination | Auszahlung |
|---|---|
| 3× `gold3` | **370×** (Jackpot) |
| 3× `gold2` | 110× |
| 3× `gold1` | 46× |
| 3× `bar` | 55× |
| 3× `bell` | 37× |
| 3× `cherry` | 18,5× |
| 2× `cherry` (links beginnend) | 5,5× |
| 2× `bell` (links beginnend) | 2,8× |
| 2× `bar` (links beginnend) | 3,7× |
| 2× `gold1` (links beginnend) | 3,7× |
| alles andere | 0 |

**Ziel-RTP: 89–92 %**, Trefferquote **10–12 %** (eine Linie, drei Walzen).

> Gemessen mit `slot_machine.simulate(200000, 100)`:
> **RTP 90,10 %**, Trefferquote **10,32 %**, 1 Jackpot in 200.000 Spins.
> Die erste Fassung der Spec ging von 28–33 % Trefferquote aus — das war falsch
> gerechnet, weil nur die *ersten beiden* Walzen zählen, nicht alle Anordnungen.

### 3.4 Warum diese Werte

- Kleine Gewinne (2× `cherry`) kommen häufig → Rhythmus.
- Der Jackpot (40×) ist selten genug, um besonders zu sein, aber erreichbar.
- RTP < 100 % ist Absicht: Der Slot ist Unterhaltung, kein Gold-Generator.
  Bei 100 Spins à 100 Gold verliert man im Schnitt ~800 Gold.

---

## 4. Psychologie / UX (aus der Recherche)

Belegt wirksam und deshalb übernommen:

1. **Anticipation beim Stoppen** — Walzen 1 und 2 stoppen früh, Walze 3 spät.
   Bei zwei gleichen Symbolen wird die dritte Walze **extra langsam** (1,35 s)
   und die Musik setzt kurz aus.
2. **Near-Miss sichtbar machen, aber ehrlich** — wenn Walze 3 ein Symbol
   *eine Position* über/unter der Linie zeigt, wird es hervorgehoben (kurzer
   Glow), aber **nicht** als Gewinn verkauft. Kein Fake-„fast!"-Banner.
3. **Variable Belohnung** — kleine Gewinne häufig, große selten.
4. **Sound pro Ereignis** — Spin-Loop, Stop-Klick je Walze, kleiner Win-Jingle,
   großer Win mit Aufbau.
5. **Kurze Totzeit** — zwischen zwei Spins max. 0,4 s, damit der Rhythmus bleibt.

Nicht übernommen: Auto-Spin ohne Grenze, Einsatz-Eskalation, „Fast gewonnen!"-
Manipulation.

---

## 5. UI / UX

### 5.1 Aufbau (von oben nach unten)

```
┌──────────────────────────────────────────────┐
│  GLÜCKSWALZE            🪙 12.400            │  Kopf, Gold immer sichtbar
├──────────────────────────────────────────────┤
│   ┌─────┐  ┌─────┐  ┌─────┐                  │
│   │  🍒 │  │  🔔 │  │  💰 │                  │  3 Walzen, 3 Symbole sichtbar
│   │  💰 │  │  💰 │  │  💀 │                  │  Gewinnlinie in der Mitte
│   │  💀 │  │ 🍒  │  │  🔔 │                  │
│   └─────┘  └─────┘  └─────┘                  │
├──────────────────────────────────────────────┤
│  EINSATZ:  [50] [100] [250]                  │
│  [        DREHEN (100 🪙)        ]           │
│  Gewinn: +250 🪙                             │
└──────────────────────────────────────────────┘
```

### 5.2 Zustände

| Zustand | Verhalten |
|---|---|
| `IDLE` | DREHEN aktiv, Walzen stehen |
| `SPINNING` | DREHEN deaktiviert, Walzen laufen, Einsatz bereits abgezogen |
| `RESULT` | Gewinn-Animation, danach zurück zu `IDLE` nach 0,9 s |
| `NO_GOLD` | DREHEN aus, Hinweis „Nicht genug Gold" |

### 5.3 Bedienung

- Button **DREHEN**, Einsatz-Chips 50/100/250 (Tap wechselt)
- Tastatur am PC: Leertaste = drehen, 1/2/3 = Einsatz
- Kein Auto-Spin

---

## 6. Animationen — echte Walzenbänder

### 6.1 Aufbau der Walze

Eine Walze ist **kein einzelnes Symbol-Feld**, sondern ein **Band**, das hinter
einem Fenster durchläuft — wie bei einem Retro-Automaten:

```
┌──────────────┐  ← Fenster (clip_contents)
│   🍒 Kirsche │
│  ─────────── │  ← Gewinnlinie (Mitte)
│   🔔 Glocke  │  ← dieses Symbol zählt
│  ─────────── │
│   💀 Totenk. │
└──────────────┘
   Band läuft nach oben, Symbole kommen von unten nach
```

- Bandhöhe: 24 Symbole × 120 px
- Fenster: 230 × 300 px (2,5 Symbole sichtbar)
- Symbolzellen: 230 × 120 px, Symbol zentriert, 96 px groß

### 6.2 Symbole (prozedural, im Comic-Stil)

| ID | Motiv | Farben |
|---|---|---|
| `slot_cherry` | zwei Kirschen + Stiel | rot `(0.78,0.12,0.16)`, Stiel grün |
| `slot_bell` | Glocke mit Klöppel | gold `(0.95,0.78,0.20)` |
| `slot_bar` | Balken mit drei Streifen | blau `(0.20,0.42,0.78)` |
| `slot_gold1` | eine Münze | gold, dunkler Ring |
| `slot_gold2` | zwei Münzen gestapelt | gold |
| `slot_gold3` | drei Münzen + Stern | gold, heller Glanz |
| `slot_skull` | Totenkopf | weiß `(0.88,0.88,0.84)`, schwarze Augen |

Alle mit **dicker Kontur** (4 px) wie die übrigen Spielassets.

### 6.3 Bewegung

| Phase | Dauer | Verhalten |
|---|---|---|
| Anlauf | 0,12 s | Band beschleunigt aus dem Stand |
| Lauf | 0,4–1,0 s | konstante Geschwindigkeit ~900 px/s, Symbole wandern nach oben |
| Auslauf | 0,25 s | `TRANS_CUBIC` + `EASE_OUT`, Band wird langsamer |
| Einrasten | 0,12 s | 10 px Überschwingen, dann zurück (`TRANS_BACK`) |

Walze 1 stoppt nach **0,55 s**, Walze 2 nach **0,78 s**, Walze 3 nach **1,12 s**.
Bei zwei gleichen Symbolen wird Walze 3 **auf 1,45 s** gestreckt und die
Musik setzt für 0,3 s aus — das ist die Anticipation-Phase.

### 6.4 Near-Miss

Landet das dritte Symbol **eine Zelle** über oder unter der Linie, bekommt es
einen kurzen gelben Glow (0,25 s). Es wird **nicht** als Gewinn dargestellt.

### 6.5 Gewinn-Feedback

| Stufe | Feedback |
|---|---|
| kleiner Gewinn | Linie pulsiert, `+X 🪙` steigt auf |
| mittlerer Gewinn | zusätzlich 6 Funken an der Linie |
| Jackpot (3× gold3) | weißer Blitz, 12 Partikel, Screen-Shake 4 px, Banner „JACKPOT" |

## 7. Neue Kosmetik

Alle Items sind **rein optisch** und werden wie bestehende Hats/Rigs über
`TextureManager` erzeugt und in `HAT_RARITY` / `RIG_RARITY` einsortiert.

### 7.1 Hüte / Kopf-Aufsätze

| ID | Name | Seltenheit | Beschreibung | Animation |
|---|---|---|---|---|
| `halo` | ENGELSSCHEN | legendary | goldener Ring über dem Kopf, schwebt | Ring pulsiert, 2 kleine Funken |
| `cape` | CAPE | epic | Cape am Rücken, flattert | 4 Frames Wellenbewegung, 8 fps |
| `antenna` | ANTENNE | rare | zwei Fühler mit leuchtenden Spitzen | Spitzen blinken versetzt |
| `crown_small` | KRÖNCHEN | epic | kleine Zackenkrone | Glanzpunkt wandert |

### 7.2 Skins (Rigs)

| ID | Name | Seltenheit | Beschreibung |
|---|---|---|---|
| `astro` | ASTRONAUT | epic | weißer Anzug, Visier mit Sternreflex |
| `ninja` | NINJA | rare | dunkler Anzug, rotes Stirnband |
| `robot_gold` | GOLD-ROBOTER | legendary | goldene Panzerung, glühende Augen |

### 7.3 Technische Umsetzung

- `cape` und `halo` brauchen **Animationsframes**: `TextureManager` erzeugt
  4 Frames, `player_controller` schaltet sie über einen Timer (8 fps) durch.
- Der Halo wird **über** dem Kopf gezeichnet, mit `z_index` über dem Body.
- Cape liegt **hinter** dem Body (`z_index = -1`).

---

## 8. Kisten-Reveal: nur das gewonnene Item

### 8.1 Problem heute

Der Streifen zeigt gemischte Kacheln (Hüte auf Charakteren, Farben auf Figuren).
Man sieht nicht, *was* man gewonnen hat, sondern nur *wer* es trägt.

### 8.2 Neu

Die Gewinner-Kachel zeigt **ausschließlich das Item**:

| Ergebnis | Darstellung |
|---|---|
| `hat` | nur der Hut, freigestellt auf Kartenhintergrund |
| `color` | Figur in der neuen Farbe, **ohne** Hut, Farbring drumherum |
| `skin` | die Figur (Rig) ohne Hut |
| `gold` | **1 / 2 / 3 Goldmünzen** je nach Höhe (< 100 / 100–249 / ≥ 250) |
| `gems` | 1 / 2 / 3 Edelsteine je nach Höhe (< 10 / 10–24 / ≥ 25) |
| `none` | leere Karte mit „LEER" |

Die Füll-Kacheln im Streifen bleiben gemischt (das erzeugt Spannung), aber die
**Gewinner-Kachel** ist immer eindeutig.

### 8.3 Gold-Stufen

| Betrag | Symbole |
|---|---|
| 40–99 | 🪙 |
| 100–249 | 🪙🪙 |
| 250+ | 🪙🪙🪙 |

---

## 9. Datenmodell

```gdscript
# Spielstand
gold: int
slot_spins_total: int
slot_gold_won_total: int
slot_gold_lost_total: int
slot_biggest_win: int

# Slot-Konfiguration (Konstante)
const SLOT_BETS := [50, 100, 250]
const SLOT_SYMBOLS := { "cherry": 22.0, ... }
const SLOT_PAYTABLE := { ... }
```

Der Slot schreibt **nur** `gold` und die Statistikzähler — keine Edelsteine.

---

## 10. Fehlermeldungen und Logs

Jede Ablehnung wird geloggt, nie still geschluckt:

```
[SLOT] spin bet=100 gold=12400 -> symbols=[cherry,bell,skull] win=0 gold=12300
[SLOT] spin bet=250 gold=300 -> ABGELEHNT: zu wenig Gold
[SLOT] JACKPOT bet=100 -> 4000 Gold (gold=7900)
[SLOT] FEHLER: unbekannter Einsatz 75
[SLOT][SIM] 200000 spins: rtp=92.3% hit=30.1% jackpot=0.02%
```

---

## 11. Testplan

### 11.1 Unit / Headless

| Test | Erwartung |
|---|---|
| `simulate(200000, 100)` | RTP 89–92 %, Trefferquote 10–12 % |
| Einsatz > Gold | `spin()` gibt `ok=false`, Gold unverändert |
| Gold nach Spin | `gold_after == gold_before - bet + win` |
| Unbekannter Einsatz | Fehlerlog, `ok=false` |
| 3× `gold3` | Auszahlung exakt 40× Einsatz |
| Reveal-Stufe Gold | 50 → 1 Symbol, 150 → 2, 300 → 3 |

### 11.2 Integration

- Shop öffnen → Glückswalze → 10 Spins → Goldstand konsistent
- App beenden und neu starten → `slot_spins_total` bleibt erhalten
- Kiste öffnen → Gewinner-Kachel zeigt nur den Item-Typ

### 11.3 Sichtprüfung

Screenshots: Slot idle, Slot spinning, kleiner Gewinn, Jackpot, Kisten-Reveal
mit Hut / Farbe / Gold (1/2/3 Symbole).

---

## 12. Akzeptanzkriterien

1. Der Slot kann **kein** Gold erzeugen, das im Schnitt über dem Einsatz liegt
   (RTP < 100 %, nachgewiesen über 200.000 Spins → **90,10 %**).
2. Ein Spin mit zu wenig Gold verändert den Spielstand nicht und loggt den Grund.
3. Die Gewinner-Kachel zeigt bei jedem Ergebnis nur den Typ, den man gewonnen hat.
4. Neue Cosmetics erscheinen in Sammlung und Kisten und sind ausrüstbar.
5. Kein Absturz, wenn Kisten/Slot bei 0 Gold geöffnet werden.

---

## 13. Umsetzungsreihenfolge

1. `slot_machine.gd` + RTP-Simulation + Tests (headless)
2. Slot-UI im Shop (eigene Seite, eigener Knopf)
3. Animationen (Walzen, Stop, Win, Jackpot)
4. Kisten-Reveal auf Item-Typ umstellen
5. Neue Cosmetics (Halo, Cape, Antenne, Krönchen, 3 Skins)
6. Sounds
7. Build + Sichtprüfung

---

## 14. Offene Fragen

- Soll der Slot eigene Sounds bekommen oder die vorhandenen `click`/`win` nutzen?
  → Vorschlag: vorhandene nutzen, später eigene.
- Soll es ein Tageslimit geben (z. B. 50 Spins)? → Für ein Freundschaftsspiel
  nicht nötig, aber leicht nachrüstbar.
