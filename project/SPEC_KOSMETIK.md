# SPEC_KOSMETIK — Umsetzungsplan

Stand: v1.34. Jeder Punkt ist einzeln abarbeitbar, testbar und hat ein Abnahmekriterium.
Status: `[ ]` offen, `[~]` in Arbeit, `[x]` fertig + geprüft.

---

## Teil A — Skins (16 Stück, 4 pro Seltenheit)

Jeder Skin ist eine eigene Zeichnung in `_make_player_rig()`, **keine** Farbvariante
eines bestehenden Skins. Jeder Skin braucht:

- eigene Silhouette (Umriss unterscheidbar bei 32 px)
- Mitwirkung der Spielerfarbe an mindestens einer sichtbaren Stelle (Kragen, Naht,
  Schulterstück) — damit die Farbwahl im Charakterfenster wirkt
- eigenen Kopf-Anker (`head_anchor_y`) für die Hutposition

### A1 — Gewöhnlich (common)

| # | Name | Merkmale |
|---|---|---|
| A1.1 | Schrottplatz-Schütze | Flickjacke, große Knöpfe, aufgenähte Flicken |
| A1.2 | Wüstenwanderer | sandfarben, übergroßer Schal, Staubbrille auf der Stirn |
| A1.3 | Dschungel-Scout | grün, Blatt-Schulterpolster, kleiner Rucksack |
| A1.4 | Straßenkämpfer | Hoodie, fingerlose Handschuhe, auffällige Turnschuhe |

### A2 — Selten (rare)

| # | Name | Merkmale |
|---|---|---|
| A2.1 | Mars-Plünderer | rostrote Rüstungsteile, Atemmaske, leuchtendes Visier |
| A2.2 | Dschungel-Jäger | Blätterumhang, Knochen-Schulterstück, Kriegsbemalung |
| A2.3 | Elektro-Techniker | blaue Arbeitskleidung, Kabelgürtel, Funken |
| A2.4 | Wikinger-Raider | Fellumhang, geflochtener Bart, offener Helm über den Augen |

### A3 — Episch (epic)

| # | Name | Merkmale |
|---|---|---|
| A3.1 | Robo-Affe-König | goldene Roboter-Rüstung, übergroße Schulterplatten, leuchtende Augen |
| A3.2 | Volt-Kommandant | dunkle Rüstung, türkise Energielinien, Blitz auf der Brust |
| A3.3 | Meteor-Golem | Steinplatten, glühende Risse, schwebende Gesteinsstücke |
| A3.4 | Splitter-König | Kristallkrone, facettierte Rüstung, Splitter als Umriss |

### A4 — Legendär (legendary)

| # | Name | Merkmale |
|---|---|---|
| A4.1 | Sternen-Wikinger | dunkelblau, kosmischer Fellumhang, Helm mit leuchtenden Hörnern |
| A4.2 | Sonnenboss | Goldpanzer, Sonnenmotiv, comicartige Lichtstrahlen |
| A4.3 | Urwald-Titan | riesige Blattschulter, leuchtende Ranken, Pflanzenbegleiter |
| A4.4 | Neon-Phantom | schwarzer Körper, pinke/blaue Neonlinien, Farb-Nachzieher |

**Abnahme A:** Kontaktblatt mit allen 16 Skins in 2 Farben; jedes Paar muss sich in
der Silhouette unterscheiden; Farbwechsel muss sichtbar sein.

---

## Teil B — Zusätzliche Cosmetics (16)

### B1 — Gewöhnlich
Stoffstirnband, runde Schutzbrille, kleines Abzeichen, einfacher Rucksack

### B2 — Selten
Wikinger-Hörner, Dschungel-Blätterkranz, Elektro-Antenne, Mars-Visier

### B3 — Episch
Kristall-Halo, schwebende Drohne, Blitz-Schweif, leuchtende Schulterplatten

### B4 — Legendär
Sternen-Halo, Mini-Meteor als Begleiter, animierte Neon-Aura,
goldene Comic-Sternchen beim Auftauchen

**Abnahme B:** Jedes Teil erscheint in Kisten, ist ausrüstbar und im Spiel sichtbar.
Kontaktblatt mit allen 16.

---

## Teil C — Hüte & Ankerpunkte

### C1 — Wikinger-Helm
Helm nach **oben und leicht nach hinten**; Augen und Gesicht frei; Hörner
**getrennt** vom Helm positioniert.

### C2 — Krone / Stern / Krönchen deutlich unterscheiden
- **Krone:** breit, gezackt, sitzt fest auf dem Kopf
- **Stern:** schwebt leicht über dem Kopf, rotiert langsam
- **Krönchen:** klein, schräg aufgesetzt

### C3 — Kopf-Anker pro Skin
Jeder Skin liefert `head_anchor_y` und `head_anchor_x`. Hüte werden relativ dazu
gezeichnet, nicht auf feste y-Werte.

### C4 — Prüfung in Bewegung
Kontaktblatt **und** Laufanimation (4 Frames pro Skin+Hut) prüfen: kein Schweben,
kein Durchrutschen ins Gesicht, keine Kollision mit Helm/Haar.

**Abnahme C:** 9 Skins × 13 Hüte = 117 Kombinationen, stichprobenartig 20 geprüft,
keine Fehlplatzierung.

---

## Teil D — Kisten

### D1 — Goldkisten-Spitzen
Spitzen als **eigene Sprite-Elemente** mit eigenem Ursprung; sie dürfen nicht in
die Kiste ragen und sich beim Öffnen nicht verschieben.

### D2 — Animationsdauer zufällig 4,5–8,0 s
Pro Öffnung `randf_range(4.5, 8.0)`. Der Gewinn wird **vor** dem Start festgelegt;
die Dauer ist reine Optik.

### D3 — Wechselnde Dynamik
Drehgeschwindigkeit variiert, Lichtblitze, Zwischenstopps. Mindestens zwei
Geschwindigkeitsphasen pro Lauf.

### D4 — Seltenheitsrahmen
| Stufe | Rahmen | Effekt |
|---|---|---|
| gewöhnlich | grau, 3 px | schlicht |
| selten | blau, 4 px | farbiger Schimmer |
| episch | violett, 5 px | pulsierendes Leuchten |
| legendär | gold, 6 px | animierte Partikel + Glanzlauf |

**Abnahme D:** 10 Öffnungen messen — alle zwischen 4,5 und 8,0 s; Gewinn identisch
mit dem vorab gezogenen Item; Spitzen unbewegt.

---

## Teil E — Glückswalze

### E1 — Einsatz frei 1–5.000
Zahlenfeld + Schieberegler + `+`/`−`. Schrittweite: 1 unter 100, 10 unter 1.000,
100 darüber.

### E2 — Nie mehr als vorhanden
Einsatz wird auf `min(einsatz, gold)` geklemmt; bei 0 Gold ist DREHEN gesperrt
mit Meldung „NICHT GENUG GOLD".

### E3 — Häufiger gewinnen, Chancen sichtbar
Trefferquote von 10,3 % auf **~22 %** erhöhen; RTP bleibt ≈ 90 %. Über dem Automaten
eine Tabelle: Symbol, 3× Auszahlung, Trefferchance.

### E4 — Letzte Walze langsamer bei zwei Treffern
Bei zwei gleichen Symbolen läuft Walze 3 mit 55 % Geschwindigkeit und hält 0,4 s
länger. Der Gewinn steht vorher fest — die Verzögerung ist nur Spannung.

**Abnahme E:** Einsatz 1, 999, 5000 getestet; 5.000 ohne Deckung gesperrt;
200.000 Simulationsspins → Trefferquote 22 ± 1 %, RTP 90 ± 1 %; bei zwei Gleichen
messbar längere Laufzeit von Walze 3.

---

## Reihenfolge der Abarbeitung

1. E1–E4 (Glückswalze) — unabhängig, schnell prüfbar
2. D1–D4 (Kisten) — unabhängig
3. C1–C4 (Hüte/Anker) — Voraussetzung für A/B
4. B1–B4 (Cosmetics)
5. A1–A4 (16 Skins)

Nach jedem Block: kompilieren, Kontaktblatt/Screenshot, Log-Ausgabe, Abnahme prüfen.
Erst wenn alle Punkte `[x]` sind, wird eine APK gebaut.
