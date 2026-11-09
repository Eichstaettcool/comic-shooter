# SPEC_REST — Restarbeiten v1.35 (D1 · E3 · B3 · B11–B13)

Stand: 03.11. Abarbeitung von oben nach unten. `[ ]` offen · `[~]` läuft · `[x]` fertig + belegt.

---

## A — Kisten (D1)

### A1 — Splitter aus den offenen Kisten entfernen  `[x]`
Die `open_*.png` enthalten Reste der Hintergrund-Freistellung (flache Strahlen
neben dem Deckel, Premium violett, Standard lila, Silber warmgrau).
**Abnahme:** auf Grün-Hintergrund keine losen Formen mehr, keine Löcher in
Deckel/Wandung.
**Beleg:** `[D1][premium] Spitzen=5337 px in 4 Teilen, loesche 7684 px` +
`screenshots/213-kisten-spitzen.png`. Werkzeug: `tools/cut_chest_spikes.py`,
`tools/cut_chest_spikes_pass2b.py`, Originale in `project/assets/chests/_orig/`.

### A2 — offene Kiste auf die geschlossene ausrichten  `[x]`
Die offene Kachel saß tiefer als die geschlossene → beim Texturtausch sprang die
Kiste nach unten.
**Abnahme:** Standfläche (unterste Zeile + Mitte) deckungsgleich.
**Beleg:** `[D1][premium] Versatz dy +28 -> ausgeglichen … True`
(Standard +13, Silber +5). Werkzeug: `tools/align_open_chest.py`.

### A3 — Spitzen als eigene Sprite-Ebene  `[x]`
Eigene Textur `chest_spikes_<tier>` (eigener Ursprung: Mitte / 62 % Höhe),
eigene Ebene **hinter** der Kiste, beim Öffnen nur eingeblendet, nie verschoben.
**Abnahme:** Log `verschoben=nein`, Strahlen ragen nicht in die Kiste.
**Beleg:** `[CHEST][SPIKES] stufe=premium eigene ebene pos=(836,98) groesse=248`,
`[CHEST][SPIKES] eingeblendet … verschoben=nein`, `screenshots/216-kiste-offen-spitzen.png`.

---

## B — Glückswalze (E1 nachziehen + E3)

### B1 — `slot_ui.gd` kompiliert wieder  `[x]`
`bet_input` / `bet_slider` wurden benutzt, aber nie deklariert → Script
kompilierte nicht, die Walze ließ sich im Shop gar nicht öffnen.
**Beleg:** vorher `Parse Error: Identifier "bet_input" not declared`;
jetzt `[SLOT][UI] geoeffnet bet=100 gold=99999` beim Öffnen.

### B2 — Einsatz-Steuerung E1 (Feld + Regler + ±)  `[x]`
Minus/Feld/Plus mit Schrittweite 1/10/100, Chips 50/100/250, Regler 1–5000.
**Beleg:** `[SLOT][BET] Einsatz=100 (Gold=99999)`, `screenshots/218-slot-tabelle.png`.

### B3 — Chancen-Tabelle über den Walzen (E3)  `[x]`
Block „Symbol · 3 gleiche · Chance" in 2 Spalten × 4 Reihen, Zahlen kommen aus
`SlotMachine.odds_table()` — dieselbe Quelle wie `spin()`.
**Abnahme:** Tabelle ohne Überlappung, Summe = Trefferquote.
**Beleg:** `[SLOT][UI] Chancen-Tabelle: 7 Symbole, Trefferquote=21.12 %`,
`screenshots/218-slot-tabelle.png`.

---

## C — Co-op-Bugs

### C1 — B3: Pause friert beide ein  `[x]`
Im Co-op wird `get_tree().paused` nicht mehr gesetzt; die Welt läuft auf beiden
Geräten weiter. Der Wählende ist so lange unverwundbar, der Client meldet das
per RPC (`c_send_busy`) an den Host.
**Beleg:** `[B3][PAUSE] Host waehlt Karten - Welt laeuft weiter (kein tree.paused im Co-op)`,
`[B3][BUSY] Slot 2 busy=true`, `[B3][SCHUTZ] Slot 2 ignoriert Schaden (Karten offen)`.

### C2 — B11: `downed=true` bei `hp=1`  `[x]`
Beim Liegen wird `health` hart auf 0 gesetzt; Sync sendet beides konsistent.
**Beleg:** `tick 1: p1.health=0` (Startwert war 1).

### C3 — B12: `near=false` trotz Partner daneben  `[x]`
Näherung 95 px über echte Positionen + Fallback über die letzte Partnerposition
(110 px). Distanz und Zustand stehen im Log.
**Beleg:** `[LAN][…][DOWNED] Slot 1 liegt: rest=4.5s near=true …` bei 60 px
Abstand, Leiste 0,5 s/Tick bis 5,0.

### C4 — B13: beide downed → Run-Ende  `[x]`
**Beleg:** `[LAN][GAME OVER] alle Spieler liegen - Run wird beendet`.

### C5 — B18: Revive machte den Geretteten zum Zuschauer  `[x]`
Nach `_revive_player()` löschte derselbe Tick `downed_time` und lief in den
„nicht mehr aufweckbar"-Zweig: `health=0`, unsichtbar, Zuschauer. Jetzt bricht
der Tick nach erfolgreichem Revive ab.
**Beleg:** vorher `tick 10: p1.health=0`; jetzt
`[REVIVE] Slot 1 wieder im Spiel (health=4) - Zuschauer-Zweig uebersprungen`.

---

## D — Abschluss

### D1 — Builds  `[x]`
### D2 — STATUS.md / BUGLISTE.md aktualisiert  `[x]`
