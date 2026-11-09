# HUT_NAMEN — Name ↔ gezeichnetes Motiv (v1.39, Punkt C1)

Geprüft am Kontaktblatt `screenshots/v139/hats_29x4.png` (29 Hüte × 4 Rigs,
116 Kacheln, je Kachel Index + Name) gegen `HAT_NAMES` in
`scripts/texture/tex_draw.gd`.

**Ergebnis: 0 offene Abweichungen.** Ein Eintrag war falsch und ist behoben
(Nr. 7, STROHHUT war eine rote Mütze — die Meldung „rote Mütze ist als Krone
gelistet" trifft diesen Fall).

| idx | Name | gezeichnetes Motiv | Status |
|---|---|---|---|
| 0 | OHNE | kein Hut | passt |
| 1 | KAPPE | Baseballkappe: rote Kuppel, Mittelnaht, kurzer Schirm nach vorn rechts, Knopf oben (v1.39 neu gezeichnet) | passt (neu) |
| 2 | COWBOY | brauner Cowboyhut: Krempe, Krone, dunkles Band | passt |
| 3 | KRONE | Goldreif mit drei Zacken und rotem Rubin | passt |
| 4 | ZYLINDER | schwarzer Zylinder mit roter Binde und Krempe | passt |
| 5 | WOLLMÜTZE | blaue Wollmütze mit Rippen und weißem Bommel | passt |
| 6 | PIRAT | schwarzer Dreispitz mit weißem Knopf | passt |
| 7 | STROHHUT | strohgelbe breite Krempe, flache Krone, dunkles Band, Flechtmuster | **behoben** (war eine rote Mütze) |
| 8 | WIKINGER | Metallhelm mit zwei Hörnern und Nasenschutz | passt |
| 9 | STERN | freier gelber Stern mit Glanzpunkt (schwebt absichtlich) | passt |
| 10 | HALO | goldener Ring über dem Kopf (schwebt absichtlich) | passt |
| 11 | ANTENNE | zwei Antennen mit roter und grüner Spitze | passt |
| 12 | KRÖNCHEN | kleine dreizackige Krone, schräg aufgesetzt | passt |
| 13 | STIRNBAND | rotes Band um die Stirn mit Zipfel | passt |
| 14 | BRILLE | runde Schutzbrille: zwei Gläser, Steg | passt |
| 15 | ABZEICHEN | gold-roter Anstecker am Kragen (Körper-Item) | passt |
| 16 | RUCKSACK | brauner Rucksack am Rücken (Körper-Item) | passt |
| 17 | HÖRNER | zwei weiße Hörner ohne Helm | passt |
| 18 | BLATTKRANZ | Kranz aus sieben Blättern um den Kopf | passt |
| 19 | ELEKTRO-ANTENNE | Antenne mit leuchtender Kugel | passt |
| 20 | MARS-VISIER | dunkles Visier mit orangefarbenem Glas | passt |
| 21 | KRISTALL-HALO | fünf Kristallstrahlen über dem Kopf (schwebt) | passt |
| 22 | DROHNE | kleine Drohne mit zwei Rotoren über dem Kopf (schwebt) | passt |
| 23 | BLITZ-SCHWEIF | blauer Blitz-Schweif hinter dem Körper (Körper-Item) | passt |
| 24 | SCHULTERPLATTEN | zwei Metallplatten auf den Schultern (Körper-Item) | passt |
| 25 | STERNEN-HALO | goldener Ring mit sechs Sternen (schwebt) | passt |
| 26 | METEOR | kleiner Meteor mit Schweif neben dem Kopf | passt |
| 27 | NEON-AURA | drei neonfarbene Ringe um den Körper (Körper-Item) | passt |
| 28 | STERNCHEN | drei Comic-Sterne um den Kopf | passt |

## Kategorien (für den Sitz-Test in C7)

- **Kopf-Hüte** (Sitz-Regeln gelten): 1–9, 11–14, 17–20, 26, 28
- **Schwebe-Items** (dürfen schweben, müssen aber mittig und innerhalb
  Kopf + 4 px bleiben): 10, 21, 22, 25
- **Körper-Items** (keine Kopfdaten anwendbar): 15, 16, 23, 24, 27
Beleg für den Sitz: `tools/hat_fit.md` und `[HAT][SITZ]`-Zeilen
(`COMIC_LANTEST=hatfit`, 700 Paare, **0 Fehler** in 475 Kopf-Paaren).
