# HUT_SITZ — Messregeln für den Hut-Sitz (v1.39, Punkt C7)

Gemessen wird **nicht nach Augenmaß**, sondern am gerenderten Bild:
`COMIC_LANTEST=hatfit` erzeugt für jedes Paar (Skin × Hut) eine Zeile

```
[HAT][SITZ] hut=<i> rig=<r> typ=<kopf|schwebt|koerper> ueberstand=<px> (l=<px> r=<px>) schweben=<px> aussen_proz=<p> ok=<true|false>
```

## Wie der Kopf gemessen wird

`GenCharacters._head_metrics()` liest die **gezeichnete** Figur (ohne Hut):

1. Pro Zeile wird der zusammenhängende Alpha-Lauf um die Mittelachse gesucht.
2. Kopfoberkante = erste Zeile, deren Mittellauf **≥ 12 px** breit ist und es
   auch in den zwei Zeilen darunter bleibt. Damit fallen Antennen, Drohnen und
   Hornspitzen oben heraus.
3. Kopfbreite = breitester Mittellauf in den ersten 9 Zeilen unter der
   Oberkante; Kopfmitte = Mitte dieses Laufs.

Messwerte (Beleg: `[HEAD]`-Zeilen, `COMIC_LANTEST=headmeas`): Standard
`top=11 cx=32 w=25`, Alien `top=9 w=33`, Roboter `top=8 w=29`,
Wikinger `top=4 w=29`.

## Wie der Hut sitzt

`GenCharacters._hat_layer_for(hat, head)` zeichnet den Hut in eine eigene
64×64-Ebene und bildet ihn auf den gemessenen Kopf ab:

```
s  = clamp(Kopfbreite / 25, 0,85 … 1,30) · Hut-Faktor
dx = Kopfmitte − 32
dy = (Kopfoberkante + SITZ) − 21      # 21 = Auflagepunkt der Standardfigur
```

`SITZ` ist pro Hut in `HAT_SEAT` hinterlegt (z. B. KAPPE 9,0 · KRONE 6,5 ·
STIRNBAND 12,0 · HALO 0,0). Sonderfall Rig 8 (ALIEN): `RIG_HAT_ADJ = −9`,
weil die Augen dort **auf** der Kopfform liegen und frei bleiben müssen.
Läuft ein Hut oben aus dem Bild (Halo auf hohen Köpfen), wird er ins Bild
zurückgeschoben statt abgeschnitten.

## Die drei Regeln

| Regel | Bedeutung | Grenze |
|---|---|---|
| `ueberstand` | seitlicher Überstand des Huts über die Kopfsilhouette (`max(links, rechts)`) | ≤ 4 px |
| `schweben` | Abstand Hutunterkante ↔ Kopfoberkante (0 = Hut liegt auf) | ≤ 2 px |
| `aussen_proz` | Anteil Hutpixel, die **auf Kopfhöhe oder tiefer** weiter als 4 px neben dem Kopf liegen | 0 % |

Zusatzregeln:

- **Schwebe-Items** (10 HALO, 21 KRISTALL-HALO, 25 STERNEN-HALO, 22 DROHNE):
  `schweben` ist dort erlaubt, dafür gilt zusätzlich `|links − rechts| ≤ 2 px`
  (mittig) und `ueberstand ≤ 4 px`.
- **Körper-Items** (15 ABZEICHEN, 16 RUCKSACK, 23 BLITZ-SCHWEIF,
  24 SCHULTERPLATTEN, 27 NEON-AURA): keine Kopfdaten anwendbar, weil diese
  "Hüte" am Körper hängen; sie werden nicht transformiert.

## Ergebnis (v1.39)

```
[HAT][SITZ] ERGEBNIS paare=700 kopfpaare=475 fehler=0
```

Alle 475 Kopf-Paare erfüllen Überstand ≤ 4 px, Schweben ≤ 2 px und 0 %
Hutpixel neben dem Kopf. Vollständige Tabelle: `tools/hat_fit.md`.
