# SKIN_SLOP — Entscheidungen zu Skins und Hüten (v1.41, Stand N5)

## Bestand

| Bereich | v1.39 | v1.41 |
|---|---|---|
| Skins (Rigs) | 29 | **17** (11 Basis + 6 gewählte Konzepte) |
| Hüte | 29 | **25** |
| Farben | 12 | 10 |

## Entfernt (18 Skins, 4 Hüte)

SCHROTT-SCHÜTZE, WÜSTENWANDERER, DSCHUNGEL-SCOUT, STRASSENKÄMPFER, MARS-PLÜNDERER,
DSCHUNGEL-JÄGER, ELEKTRO-TECHNIKER, WIKINGER-RAIDER, ROBO-AFFE, VOLT-KOMMANDANT,
METEOR-GOLEM, SPLITTER-KÖNIG, STERNEN-WIKINGER, SONNENBOSS, URWALD-TITAN,
NEON-PHANTOM, KRISTALL-GOLEM, SCHATTEN-KATZE.

Hüte: MARS-VISIER, BLITZ-SCHWEIF, METEOR, NEON-AURA.

## Die 6 neuen Skins (Nutzerwahl aus je 3 Designoptionen)

| Rig | Name | Seltenheit | Variante | Merkmale |
|---|---|---|---|---|
| 11 | EISENKARDINAL | legendary | A Templer | Kettenkapuze, Plattenpanzer, rotes Wappen, Streitkolben |
| 12 | ONI-FELDHERR | legendary | B Blauer Oni | Maske mit Hauern, Hörner, Stachelschultern, Klauen (keine Waffe), breiter Stand |
| 13 | EWIGER HERRSCHER | legendary | C Anubis-Priester | Schakelkopf mit Ohren, Robe, goldener Stab, Medaillon |
| 14 | KAPITAEN ROST | epic | A Klassisch | Dreispitz, Umhang, Säbel |
| 15 | FROSTBEIL | epic | A Fellkapuze | Kapuze, Fellkragen, Eisaxt, breiter Stand |
| 16 | GRINSER | epic | C Joker-Maske | weiß geschminkt, grünes Grinsen, Robe, Spielkarten |

Die nicht gewählten Varianten bleiben als Kontaktblatt in
`screenshots/v141/konzept_legendary.png` und `konzept_epic.png`.

## Wie gezeichnet wird (v1.41, zweite Fassung)

Quelle ist immer noch prozedurales GDScript — dadurch ist jede Figur
reproduzierbar, golden-check-fähig und ohne Binär-Assets prüfbar:

- `scripts/texture/gen_concepts.gd` — datengetriebener Zeichner
  (`_make_concept(cfg)`), Schichten: Schatten → Rücken (Umhang/Schild) →
  Beine → Rumpf mit Falten → Gürtel → Schultern → Arme → Kopfbedeckung hinten
  → **Gesicht** → Kopfbedeckung vorn → Waffe. 18 Varianten = 18 Konfigurationen.
- `scripts/texture/gen_characters.gd` — die 11 Basis-Skins, dazu
  `_face_pass(img, rig)` (Augen/Mund je Skin), `_shade_body()` (Licht von links
  oben, Schatten rechts unten, Faktor 0,66–1,20 auf Stoff/Hose) und
  `_eye_pair()/_mouth()` als gemeinsame Bausteine.

## Messgrundlage

| Prüfung | Ergebnis (Beleg) |
|---|---|
| Namen/Seltenheiten/Kopfanker | `[RIG][CHECK] names=17 rarity=17 arme=17 hats=25 head_anchor=17` |
| Hautfarben folgen der Spielerfarbe | `[RIG][FARBE] … ok=true` für **170** Paare (17 × 10), Shading erhält die Farbfamilie |
| Silhouetten (Kontur-IoU) | `[RIG][KONTUR] ERGEBNIS max_kontur_iou=… ziel=0.55` |
| Hüte sitzen | `[HAT][SITZ] ERGEBNIS paare=408 kopfpaare=289 fehler=0` (17 Skins × 24 Hüte, „OHNE" ausgenommen) |
| Neue Skins einzeln | `[RIG][NEU] name=… seltenheit=… farb_ok=true iou_max=…` (6×) |
| Sammlung | `[COLL][ZAEHLER] skins=17 huete=25 farben=10`, Debug-Unlock 17/17 |
| Golden Master | `tools/golden_check.sh` → 8 Modi `rest_diff=0 script_errors=0` |

**Warum Vollmasken-IoU untauglich ist:** alle aufrechten Figuren teilen den
Körperblock, deshalb liegen sie zwischen 0,74 und 0,93 (siehe `tools/rig_iou.md`).
Gemessen wird die **Kanten**-IoU der Silhouette (Ziel ≤ 0,55). Bei den
Konzept-Varianten *eines* Konzepts ist Ähnlichkeit gewollt (wie Skins eines
Sets) — dort entscheidet die Sichtprüfung, nicht der IoU.
