# SPEC v1.54 — Skin × Hut: Verträglichkeit geprüft und repariert

Status: `[x]` alle 425 Kombinationen grün · Messung: `COMIC_LANTEST=hatmatrix` · Nachbesserung v1.55 unten

## Verfahren

17 Skins × 25 Hüte = **425 Kombinationen**, jede als 64×64-Textur erzeugt und
maschinell geprüft:

| Prüfung | Kriterium |
|---|---|
| **Oben abgeschnitten** | oberste deckende Pixelzeile bei `y <= 0` |
| **Seitlich abgeschnitten** | linke Kante `x = 0` oder rechte Kante `x = 63` |
| **Hut wirkt nicht** | weniger als 4 Pixel Unterschied zur Figur ohne Hut |

Zusätzlich Sichtprüfung über Kontaktblätter (`hatsheet154`, Zeilen = Skins,
Spalten = Hüte) — die Zahlen allein erkennen kein „Doppel-Kopfstück".

**Stand vorher:** 267 von 425 Kombinationen fehlerhaft
(178× oben abgeschnitten, 65× Hut unsichtbar, 24× seitlich abgeschnitten).
**Stand jetzt:** `[HATMX][ERGEBNIS] kombis=425 kaputt=0`.

## Was kaputt war (je Skin)

| Skin | Kombis | Oben ab | Seite ab | Hut unsichtbar |
|---|---|---|---|---|
| STANDARD | 10 | 8 | – | 2 |
| PANZERHELD | 16 | 12 | – | 4 |
| NINJA | 16 | 14 | – | 2 |
| ROBOTER | **25** | 25 | – | – |
| COMIC-HELD | 11 | 8 | – | 3 |
| MARS-MARSCHALL | 16 | 9 | – | 7 |
| GEIST | 12 | 9 | – | 3 |
| WIKINGER | 17 | 13 | – | 4 |
| ALIEN | 3 | 3 | – | – |
| SPINNENMANN | **25** | 1 | **24** | – |
| ZOMBIE | 7 | 4 | – | 3 |
| EISENKARDINAL | 22 | 15 | – | 7 |
| ONI-FELDHERR | 16 | 12 | – | 4 |
| EWIGER HERRSCHER | 21 | 14 | – | 7 |
| KAPITAEN ROST | 18 | 10 | – | 8 |
| FROSTBEIL | 22 | 15 | – | 7 |
| GRINSER | 10 | 6 | – | 4 |

## Reparaturen

### R1 — Hut nie mehr oben abschneiden `[x]`

`_hat_layer_fast()` hatte einen Deckel gegen unten (`y_bot > 63`), aber keinen
gegen oben. Ein Hut mit negativer Sitzkorrektur lief oben aus dem Bild.

Neu: wenn `y_top < 1`, wird der Hut nach unten geschoben; rutscht er dadurch in
die Augen, wird er zusätzlich verkleinert (`[HAT][DECKEL]`).

**Beleg:** `[HAT][DECKEL] hut=… rig=… oben=1.0 skala=…` in jedem betroffenen Lauf.

### R2 — Schwebende Hüte mit festem Sitz `[x]`

HALO (10), KRISTALL-HALO (20), STERNEN-HALO (23), DROHNE (21), STERN (9),
STERNCHEN (24) wurden an die Kopfform skaliert und über die Kopfoberkante
gesetzt. Auf hohen Skins (Helm/Kapuze) landeten sie außerhalb des Bildes oder
im Kopf.

Neu: `FLOAT_HATS` — feste Größe, fester Sitz 2 px über dem Kopf, keine
Kopfskalierung. `[HAT][MX]` zeigt sie jetzt auf allen 17 Skins.

### R3 — Körperteile an absoluter Position `[x]`

ABZEICHEN (15), RUCKSACK (16), SCHULTERPLATTEN (22) wurden wie Hüte auf den
Kopf gerechnet — sie landeten im Gesicht bzw. auf dem Hals.

Neu: `FIXED_HATS` — diese drei benutzen ihre absoluten Rasterkoordinaten.
Zusätzlich: Anstecker (15) und Schulterplatten (22) liegen jetzt **vor** dem
Körper (`HAT_BODY_ITEMS = [16]`), sonst waren sie hinter dem Torso unsichtbar
(14 bzw. 12 Skins). Der Rucksack sitzt weiter hinten, wurde aber nach links
gerückt (`x=10..22`), damit er neben dem Körper sichtbar bleibt.

### R4 — Eigenes Kopfstück weicht dem Hut `[x]`

Skins mit eingebautem Kopfstück behielten es unter dem neuen Hut
(Doppel-Helm, Hörner unter der Krone, Dreispitz unter dem Wikingerhelm).

Neu: `_rig_body(..., bare_head)` — bei `hat > 0` wird das skin-eigene
Kopfstück nicht gezeichnet:

| Skin | legt ab |
|---|---|
| PANZERHELD | Helm + Visier |
| WIKINGER | Helm + Hörner |
| EISENKARDINAL | Kettenkapuze |
| ONI-FELDHERR | Hörner |
| KAPITAEN ROST | Dreispitz |
| FROSTBEIL | Fellkapuze |

EWIGER HERRSCHER (Anubiskopf) und GRINSER (Maske) behalten ihren Kopf — das ist
das Gesicht, kein Hut. ROBOTER behält die Antenne (Teil des Kopfes).

**Beleg:** Kontaktblatt `sheet_r1-7-12-14_h0-13-8-6.png` (PANZERHELD, WIKINGER,
ONI, KAPITAEN ROST): mit Hut ist das eigene Kopfstück weg, ohne Hut ist es da.

### R5 — Zwei Figuren liefen aus dem Bild `[x]`

- **ROBOTER:** Antennenkugel Radius 4 bei `y=3` → 1 px über dem oberen Rand.
  Jetzt `y=5`, Radius 3,6. Alle 25 Roboter-Kombis waren betroffen.
- **SPINNENMANN:** rechtes Bein endete bei `x=62` mit 3 px Strichstärke → über
  dem rechten Rand. Jetzt bei `x=59`. 24 Kombis betroffen.

**Beleg:** `[HATMX][ERGEBNIS] kombis=425 kaputt=0` nach beiden Fixes.

## Nachprüfung

| Prüfung | Beleg |
|---|---|
| Matrix 425 Kombis | `[HATMX][ERGEBNIS] kombis=425 kaputt=0`, `[HATMX][SUMME] { }` |
| Spiel startet weiter | `--quit-after 240`, `SCRIPT ERROR` = 0 |
| Sichtprüfung alle Skins | `screenshots/v154/sheet_r_h0-1-3-6-10.png` (17 × 5) |
| Doppel-Kopfstück | `sheet_r1-7-12-14_h0-13-8-6.png`, `sheet_r11-13-15-16_h0-1-6-3.png` |
| Körperteile | `sheet_r0-1-7-12_h15-16-22-0.png` |
| Randfälle | `sheet_r3-9_h0-1-4-10-23.png` (ROBOTER, SPINNENMANN) |

## Offen / bewusst so gelassen

- Die Messung läuft mit **Farbe 0**. Farben verändern nur Shirt/Hose-Farben,
  nicht Kopfform oder Hut-Sitz — die geprüfte Geometrie ist farbunabhängig.
- EWIGER HERRSCHER: Ohren bleiben unter dem Hut sichtbar (Anubiskopf). Das ist
  Absicht, kein Doppel-Kopfstück.
- NINJA behält seinen Mundschutz, GEIST seine Kapuze — beides ist Teil der
  Figur, nicht abnehmbar.

---

# v1.55 — Nachbesserung nach Sichtprüfung (Kapitän Rost, Wikinger, Panzerheld)

Rückmeldung: „der kapitaen rost sieht sehr verbuggt aus, das stirnband ist nicht auf
dem kopf, der piratenhut auch nicht, beim wikinger das stirnband auch nicht, und beim
panzerheld sollte der hut sein gesicht garnicht entfernt werden".

## Was tatsächlich falsch war

### N1 — Sitz wurde am Schwert gemessen `[x]`

Die Silhouetten-Oberkante kam aus dem **ganzen** Bild. Bei KAPITAEN ROST liegt die
Degenspitze über dem Kopf, bei WIKINGER die Axt — der Hut wurde dadurch zu hoch
angesetzt und schwebte.

**Fix:** `_img_top_head()` misst nur noch in der Kopfspalte (`cx ± 0,6·w`).
**Beleg:** `[HATFIT][RIG]` zeigt für alle 17 Skins `kopf_top` aus der Kopfspalte.

### N2 — Augenregel schob Hüte über den Kopf `[x]`

Bei Skins mit hoch liegenden Augen wurde der Hut über die Augen geschoben und
landete **über** der Silhouette.

**Fix:** neuer Deckel `y_top >= sil_top` für getragene Hüte (Schweber bleiben frei).
**Beleg:** Kontaktblatt `sheet_r7-14-1-0_h13-1-6.png` — Stirnband sitzt auf der Stirn.

### N3 — Kappe war 17 px hoch `[x]`

Die KAPPE (case 1) war für einen 14-px-Kopf zu groß und bedeckte die Augen.

**Fix:** flachere Kuppel (10 px), Schirm tiefer, Knopf tiefer; zusätzlich wird die
Hutgröße jetzt auch an der **Kopfhöhe** begrenzt (`avail = eye_top - top + 4`).
**Beleg:** `[HAT][SCHRUMPF] … grund=augenband` · Kontaktblatt
`sheet_r14-7-1-0_h1-3-6-8.png` — Augen bleiben frei.

### N4 — Stirnband war ein loser Streifen `[x]`

Das STIRNBAND war als dünner Balken mit Pfeilspitze gezeichnet und lag wie ein
Streifen über dem Haar.

**Fix:** Band 2 px tiefer (y=17..21), Knoten statt Pfeil, heller Oberkante.
**Beleg:** `sheet_r7-14-1-0_h13-1-6.png` — Band liegt auf der Stirn, Augen sichtbar.

### N5 — Panzerheld: nichts mehr entfernen `[x]`

`bare_head` ist für PANZERHELD abgeschaltet (`idx != 1`): Helm und Visier bleiben,
die Hüte werden auf den Helm gesetzt.
**Beleg:** `sheet_r14-7-1-0_h1-3-6-8.png`, Zeile 3 — Helm unverändert, Kappe/Krone/
Pirat/Wikingerhelm sitzen darauf.

## Stand nach der Nachbesserung

| Prüfung | Beleg |
|---|---|
| Matrix | `[HATMX][ERGEBNIS] kombis=425 kaputt=0` |
| Alle Skins × 6 Hüte | `screenshots/v154/sheet_r_h0-1-3-6-13-10.png` |
| KAPITAEN ROST / WIKINGER / PANZERHELD | `sheet_r14-7-1-0_h1-3-6-8.png` |
| Stimmen die Sitze? | `sheet_r7-14-1-0_h13-1-6.png` |
| Spielstart | `--quit-after 240`, `SCRIPT ERROR` = 0 |
