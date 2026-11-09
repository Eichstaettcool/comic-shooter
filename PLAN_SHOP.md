# PLAN: Shop- und Kisten-System (Runde 67)

## 1. Test-Ergebnis vorab (LAN-Rejoin)

| Szenario | Ergebnis |
|---|---|
| Host + Client, gleiche Karte | `697248/421` == `697248/421` ✅ |
| Client stürzt ab (Verbindung weg) | Host läuft weiter, **aber** die Figur des Clients bleibt in `players` stehen ❌ |
| Neuer Client tritt mitten im Run bei | hängt im Menü (`state=0`), kommt **nicht** in den Run ❌ |

**Folge:** Rejoin während eines Runs ist nicht unterstützt. Zwei Aufgaben daraus:
- `_on_peer_left` muss den Spieler-Slot aufräumen (Node + `players`).
- Late-Join: entweder sauber ablehnen („Run läuft bereits, bitte neu starten") **oder**
  Client mit aktuellem Wellen-/Kartenzustand joinen lassen (aufwändig, später).

---

## 2. Wirtschaft: Gold → Edelsteine → Kisten

### Umtausch (bewusst teuer)

| Gold | Edelsteine | Kurs |
|---|---|---|
| 1.000 | 1 | 1 Gem / 1.000 Gold |
| 10.000 | 12 | **1,2× Bonus** — Anreiz für große Pakete |

Damit ein Run (~2.000–4.000 Gold) etwa 2–4 Gems bringt, eine Kiste aber 12–25 kostet,
sind das 4–8 Runs pro Kiste. Das ist der Hebel gegen „nach drei Runden alles frei".

### Kisten

| Kiste | Preis | Inhalt |
|---|---|---|
| **STANDARD-KISTE** | 12 Gems | Farben + Hüte, 1 Item |
| **PREMIUM-KISTE** | 28 Gems | höhere Chance auf Skins, 1 Item, garantiert mind. „selten" |

Nur Kosmetik. Keine Boosts, keine Waffen — die Balance bleibt unberührt.

### Drops (Gewichte, Summe 100)

**Standard:** gewöhnlich 62 · selten 28 · episch 9 · legendär 1
**Premium:** gewöhnlich 25 · selten 45 · episch 24 · legendär 6

### Duplikate

Kein Doppel-Ärger: ein bereits besessenes Item wird in **Gems umgewandelt**
(gewöhnlich 3, selten 6, episch 12, legendär 25). Das hält den Fortschritt
auch bei Pech am Laufen und verhindert tote Kisten.

---

## 3. Technik

### Datenmodell (`game_manager`)

```gdscript
var gems: int = 0
var chests_opened: int = 0
var pity_counter: int = 0        # optional: nach 10 Kisten ohne "episch" eins erzwingen
```

Speichern im bestehenden `savegame.save` (neue Felder am Ende, alte Saves bleiben lesbar —
gleiches Muster wie bei Musik/SFX).

### Neue Dateien

| Datei | Aufgabe |
|---|---|
| `scripts/loot_table.gd` | Gewichtete Auswahl, Duplikat-Erkennung, Rückgabe `{id, rarity, duplicate, refund}` |
| `scripts/chest_ui.gd` | Kisten-Auswahl, Öffnen-Animation, Ergebnis-Panel |

### Loot-Auswahl

Godot 4 bringt `RandomNumberGenerator.rand_weighted(weights)` mit — kein eigener
Kumulativ-Code nötig. Eigene `RandomNumberGenerator`-Instanz mit gespeichertem Seed,
damit Tests reproduzierbar sind (gleiches Muster wie beim Karten-Generator, Runde 65).

### Öffnen-Animation (CS:GO-Stil)

Aufbau: ein `Control` mit `clip_contents = true`, darin ein `HBoxContainer` mit ~40
Item-Kacheln (74 px + 8 px Abstand = 82 px Schritt).

1. **Streifen füllen**: zufällige Items aus dem Pool, das **Gewinner-Item** an einer
   festen Position (z. B. Index 32).
2. **Zielposition** berechnen: `-1 * (32 * 82) + halbe_Breite - 37`.
3. **Ein einziger Tween** auf `position:x`, Dauer ~3,4 s,
   `TRANS_CUBIC`, `EASE_OUT` → startet schnell, wird langsam, bleibt stehen.
4. **Marker**: feste senkrechte Linie in der Mitte; darunter ein kleiner Pfeil.
5. **Nachlauf**: kurzes „Einrasten" (±4 px, 0,12 s, `TRANS_BACK`) für das CS:GO-Gefühl.
6. **Reveal**: Karte skaliert von 0,8 auf 1,0 (`TRANS_BACK/EASE_OUT`), Glow-Farbe nach
   Seltenheit, Item-Name + Rarity-Label, bei Duplikat „+X Gems".

**Warum ein Tween und kein AnimationPlayer:** Die Zielposition hängt von der Item-Zahl
und der Bildschirmbreite ab. Ein Tween mit berechneter Zielposition ist robuster als
eine feste Keyframe-Animation und lässt sich im Test auf 0,2 s verkürzen.

### UI-Aufbau (Shop-Seite, Comic-Stil wie Startseite)

```
[ GOLD: 12.450 ]   [ EDELSTEINE: 7 ]

UMTAUSCH
[ 1.000 Gold  →  1 Gem ]   [ 10.000 Gold  →  12 Gems ]

KISTEN
[ STANDARD · 12 💎 ]  [ PREMIUM · 28 💎 ]

           (Öffnen-Ansicht mit Laufband)
```

Alles `_make_pixel_button` + `_hud_comic_sb` — kein neuer Stil.

### Debug & Tests

- Logs: `[CHEST] open kind=standard cost=12 -> item=hat_3 rarity=rare duplicate=false refund=0`
- `[SHOP][GEMS] exchange 1000 gold -> 1 gem (gems=8)`
- Headless-Test: 10.000 Züge aus der Loot-Tabelle → Verteilung gegen Soll prüfen (±1 %).
- Test: Duplikat wird korrekt in Gems umgewandelt.
- Test: Umtausch bei zu wenig Gold wird abgelehnt (`[SHOP][GEMS] FEHLER: zu wenig Gold`).
- Test: Animation auf 0,2 s gerafft → Zielitem muss exakt unter dem Marker liegen.

---

## 4. Reihenfolge der Umsetzung

1. `gems` + Speichern/Laden + Umtausch (mit Logs) → headless testbar
2. `loot_table.gd` + Verteilungstest
3. Shop-Seite: Gems-Anzeige, Umtausch-Knöpfe
4. `chest_ui.gd`: Auswahl + Öffnen + Ergebnis
5. Animation feinjustieren (Dauer, Einrasten, Glow)
6. Komplett-Test: 10 Kisten öffnen, Kontostand prüfen
7. Build 1.7 + Screenshot fürs README

## 5. Offene Punkte / Risiken

- **Pity-System**: ohne Garantie kann Pech zu 15 Standard-Kisten ohne Skin führen.
  Vorschlag: nach 10 Kisten ohne „episch" wird das nächste Ergebnis mindestens episch.
- **Bestehende Kisten im Run** (die Truhen auf der Karte) bleiben unverändert —
  nur der Shop-Kistenkauf wird neu. Sonst kippt die Run-Balance.
- **Gold-Menge** muss evtl. nachjustiert werden, wenn 1.000 Gold zu leicht erreicht wird.
  Dann Kurs auf 1.500 Gold/Gem.
