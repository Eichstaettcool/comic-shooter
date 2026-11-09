# Comic-Look für Kisten — Recherche & drei Art-Directions

Stand: 2026-11-08 · Projekt: Comic Shooter (Godot 4.7.2, 2D, Mobile)
Umfang: Designsprache, drei klar trennbare Varianten, Zeichen-Anleitung für prozedurale Generierung,
Farb-/Kontrast-Check. **Kein Code geändert** — reine Recherche und Art-Direction.

Ist-Zustand (Referenz für alle Koordinaten unten):
`scripts/texture/gen_chest_art.gd` zeichnet auf **64×64**, Kontur `OUTLINE = #14141A`, dann
`_crop_center(img, 62)` → `resize(256, NEAREST)`. Körper-Box ist `[7, 33, 50, 24]`.
Angezeigt wird die Kiste in `scripts/ui/chest_ui.gd` mit `cs = clamp(size.y * 0.17, 120, 200)`
— auf 1080p also **~184 px**, das ist ein **nicht-ganzzahliger** NEAREST-Downscale von 256 (Faktor 0,717).
Alle Maße unten sind 64er-Rasterpixel.

---

## 1. Comic-/Pop-Art-Grundlagen für Objekt-Design

### 1.1 Kontur: erst Linie, dann Farbe

Die Kontur ist im amerikanischen Mainstream-Comic das definierende Element, nicht die Farbe:
„The use of varying line weights is a defining element of comic book inking“ (Gary Martin,
*The Art of Comic Book Inking*, Kap. I). Martin unterscheidet vier Linientypen, die für
prozedurale Generierung direkt brauchbar sind:

| Typ | Verlauf | Einsatz am Kisten-Objekt |
|---|---|---|
| **Dead-weight** | konstante Dicke | Kristall-Kanten, UI-Icons, technische Kanten — „leblos“, bewusst für Härte |
| **Terse line** | dünn → dick, ohne Bauch | Blechkanten, Schlösser, alles Metallische/Kantige |
| **Cursive line** | dünn → dick → dünn | Holzplanken, Deckelwölbung, organische Formen |
| **Feathering** | viele kurze Linien, dünn → dick | Schattenübergang, Maserung, „Verlauf“ ohne Gradient |

**Die drei Regeln, die zählen** (Martin, Kap. III/IV):

1. **Lichtquelle zuerst festlegen.** Dann: *schwere Linie auf der Schattenseite, dünne Linie auf der
   Lichtseite*. Das erzeugt Volumen ohne Shading — genau der Trick, den ein flaches 64er-Sprite braucht.
2. **Tiefe über Konturgewicht.** Vordergrund = schwere Kontur, Mittelgrund = mittlere, Hintergrund =
   feine Linie. Für eine Kiste mit Deckel heißt das: Korpus 3 px, Deckel 2–3 px, Schloss/Deko 1–2 px.
3. **Kontur darf brechen.** An Prallflächen, Ecken und dort, wo Formen sich berühren, wird die Linie
   dicker („spotting blacks“), an Lichtkanten dünner oder ganz offen. Eine überall gleich dicke Kontur
   ist der häufigste Grund, warum generierte Assets „nach Vektorgrafik“ und nicht nach Comic aussehen.

Belege: [Art of Comic Book Inking (PDF)](https://ia600600.us.archive.org/13/items/the-art-of-comic-book-inking/The-Art-of-Comic-Book-Inking.pdf) ·
[Clip Studio: Inking Tips](https://tips.clip-studio.com/en-us/articles/3783)

### 1.2 Ben-Day-Dots vs. Halbton/Screentone — nicht dasselbe

Wichtige, oft verwischte Unterscheidung (Wikipedia, Ben Day process):

- **Ben-Day-Dots**: *gleiche* Punktgröße, *gleiche* Verteilung über eine Fläche. Kein Verlauf, nur
  Flächenton. Erfunden 1879 von Benjamin Henry Day Jr., Standard im Farbcomic der 1950er/60er.
- **Halbton/Screentone**: Punkte *variieren kontinuierlich in der Größe* und erzeugen damit Grau-
  bzw. Farbverläufe. Screenwinkel üblich **K = 45°**, C = 15°, M = 75°, Y = 0°; der 30°-Abstand
  zwischen Kanälen existiert, um **Moiré** zu vermeiden.

Für Kisten heißt das: **Ben-Day = Dekoration/Materialtextur** (gleichmäßig, absolut reproduzierbar,
ein Loop mit fester Schrittweite), **Halbton = Verlauf** (Punktgröße pro Zeile ändern — aber genau
das bricht bei kleinem Display weg, siehe §4). Lichtenstein hat die Dots bewusst vergrößert und
verstärkt, um den Druck zu evozieren — die Übertreibung ist die Stilisierung, nicht der Fehler.

Belege: [Ben Day process (Wikipedia)](https://en.wikipedia.org/wiki/Ben_Day_process) ·
[TheCollector: Lichtenstein](https://www.thecollector.com/how-did-roy-lichtenstein-make-his-pop-art/) ·
[Halftone-Winkel/Frequenz](https://vectorwiz.com/guides/halftones-screen-printing)

### 1.3 Cel-Shading in Stufen (und warum 2 Stufen reichen)

Cel-Shading = Beleuchtung wird auf wenige diskrete Bänder quantisiert („stepped ramp“), nicht
geglättet. Für 64×64-Sprites gilt: **mehr als 3 Werte pro Materialfarbe sind nicht unterscheidbar**,
sie erzeugen nur Matsch. Praktikable Stufen:

| Stufe | Rolle | Wo |
|---|---|---|
| 0 | Kernschatten (fast Konturfarbe) | Unterseite, unter Deckelkante, Innenseite |
| 1 | Basiston | Hauptfläche |
| 2 | Lichtton (1 Stufe heller, leicht entsättigt) | oben, links, Deckeloberseite |
| 3 | **Rim-Light / Specular** (fast Weiß, 1 px) | Oberkante, Kante gegen Hintergrund |

Rim-Light ist per Definition ein Licht *hinter/hinter-seitlich* des Objekts, das eine helle Kante am
Rand erzeugt — im Comic als „negative space“/weiße Highlight-Linie gezeichnet. Es ist das billigste
Mittel, ein 2D-Objekt vom Hintergrund zu lösen, und kostet pro Kiste nur eine 1-px-Linie.

Belege: [Redshift Toon Material (stepped ramp)](https://help.maxon.net/r3d/cinema/en-us/Content/html/Material+Toon.html) ·
[Unity Toon Shader](https://docs.unity3d.com/Packages/com.unity.toonshader@0.15/manual/GettingStarted.html) ·
[Rim Light](https://www.toolsforfilm.com/glossary/rim-light)

### 1.4 Speed-/Motion-Lines

Zwei Funktionen (Studie zu Motion/Speed Lines): (a) Bewegungsmarker, (b) narratives Tempo-Signal.
Martin nennt dieselbe Form **„force lines“**: lange Feather-/Cursive-Linien, die eine Aktion
*umrunden und auf sie zeigen*. Für Kisten:

- **Radial** hinter der Kiste (Stern-Aura) → „hier passiert etwas Wichtiges“ (Reveal, Premium).
- **Parallel** an der Seite → „die Kiste kommt geflogen“ (Spawn/Drop-Animation).
- Nie über die Kistenfläche selbst — Speed-Lines gehören in den Hintergrund, sonst konkurrieren sie
  mit Kontur und Deko um dieselben Pixel.

Belege: [Motion lines (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC4376351/) ·
[Speed Lines Studie](https://ojs.uhnsugriwa.ac.id/index.php/lg/article/view/5491)

### 1.5 Inflation/Deformation bei Impact

„Squash and stretch“ = Übertreibung der Verformung eines nicht-starren Körpers, um Härte und
Krafteinwirkung zu zeigen. Im Comic-Keyframe:

- **Impact-Frame**: Kiste 6–8 % breiter, 4–6 % flacher; Kontur auf der Stauchungsseite **dicker**
  (Martin-Regel: schwere Linie dort, wo Schatten/Druck ist).
- **Follow-through**: 1 Frame später 3 % schmaler und höher (Overshoot), dann Settle.
- **Deckel**: beim Aufspringen nach hinten klappen, dabei leicht *länger* werden (Perspektiv-
  Stauchung) — ein gestauchter Deckel liest als „Scharnier“, ein starrer als „Bild verschoben“.

Für prozedurale Texturen: Deformation **nicht** in die Textur backen, sondern über `scale` im Tween
(`chest_ui.gd` macht das schon mit `Vector2(1.06, 0.96)`); in die Textur gehört nur die *gezeichnete*
Reaktion — dickere Kontur, Risse, Splitter, Staub-Burst.

Belege: [Animation Principles (UW)](https://courses.cs.washington.edu/courses/cse458/25au/content/exercises/animation_principles.html) ·
[Fundamental Principles (PDF)](https://www.dgp.toronto.edu/~patrick/csc418/notes/tutorial11.pdf)

### 1.6 Lettering / Onomatopoesie

Onomatopoesie ist im Comic kein Text, sondern **Form**: eigene Schrift, eigene Kontur, eigene
Perspektive, oft mit Halbton gefüllt. Regeln für Kisten-Effekte:

| Wort | Auslöser | Form |
|---|---|---|
| **KLIRR** | Kiste landet / Münzen fallen | hart, gezackt, 0° Rotation, Kontur 2 px |
| **KNACK** | Schloss bricht | schmal, hohe Buchstaben, 6° |
| **POW** | Reveal-Impakt | breit, fett, 12° Rotation, Stern-Burst dahinter |
| **BAM** | Deckel springt | rund, weich, kurzer Ausruf, 8° |
| **KLONG** | Metall-Tier (silver) | metallisch, kalte Füllung, Doppelkontur |
| **WUMM** | Premium-Reveal | tief, fette Serifen, Innen-Halbton |

Technisch: 3–5 Zeichen, Großbuchstaben, kein Kleinsatz; Kontur 2 px, harter Offset-Schatten
(2 px, 100 % Schwarz, keine Unschärfe), Füllung = Rim-Light-Farbe. Keine weichen Schatten —
weiche Schatten sind der schnellste Weg aus dem Comic-Look heraus.

Belege: [The Conversation: How comics make sound](https://theconversation.com/kapow-zap-splat-how-comics-make-sound-on-the-page-160455) ·
[Comic Book Sound Effects](https://comicbookco.com/comics/comic-book-sound-effects-evolution/)

### 1.7 Palette-Grundsatz

Pop-Art-Paletten bestehen aus **wenigen, flachen, hochgesättigten** Farben plus Schwarz — kein
Gradient, kein Ambient Occlusion. „Flat areas of unmodulated color“ ist die Formel.
Praktische Regel für dieses Spiel: **1 Grundton + 1 Schattenton + 1 Lichtton + 1 Akzentfarbe +
Schwarz**. Der Akzent ist die Tier-Farbe und darf als *einzige* gesättigt leuchten.

Belege: [Pop-Art-Paletten mit Hex](https://doncorgi.com/blog/pop-art-color-palettes/) ·
[Lichtenstein-Palette](https://www.omoro.io/palettes/lichtenstein-dots) ·
[Rarity-Farbkonvention in Spielen](https://auricartisan.com/library/learn/articles/2026-08-21-color-in-games)

---

## 2. Drei Art-Directions

Gemeinsame Constraints für alle drei (aus dem Ist-Code abgeleitet):
64×64-Raster · Kontur 2–3 px · keine 1-px-Details unterhalb der Kontur · **keine Zacken in der
obersten Zeile** (`kanten_spitzen()` in `gen_chest_art.gd` zählt Spalten, die ≥3 px über ihre
Nachbarn ragen — ein Sägezahn-Deckel fällt durch diese Messung) · offene Kiste = Deckel hinter dem
Korpus, Innenraum oben sichtbar.

---

### Variante A — „HOLZSCHNITT“ (Pulp Print)

**Idee:** Die Kiste sieht aus wie aus einem 1963er-Heft geschnitten: warmes Holz, schwarze
Pinselkontur, ein einziger Cyan-Spot als Farbakzent. Ruhigste der drei Varianten, höchste
Lesbarkeit bei kleiner Darstellung, „Abenteuer-Kiste“ statt „Loot-Box“.

**Referenzen**
- Gary Martin, *The Art of Comic Book Inking* — Cursive/Feathering, Liniengewicht:
  https://ia600600.us.archive.org/13/items/the-art-of-comic-book-inking/The-Art-of-Comic-Book-Inking.pdf
- Lichtenstein, *Whaam!* (Tate) — flache Primärflächen + harte Kontur:
  https://www.tate.org.uk/art/artworks/lichtenstein-whaam-t00897
- Lichtenstein-Dots/Palette: https://www.omoro.io/palettes/lichtenstein-dots
- Ben-Day-Referenz: https://en.wikipedia.org/wiki/Ben_Day_process

**Palette**

| Rolle | Hex | Einsatz |
|---|---|---|
| Ink (Kontur) | `#12100E` | alle Konturen, Schloss-Schlüsselloch |
| Papier/Cream | `#F3E4C8` | Label-Fläche, Rim-Light auf Holz, Innenraum-Boden |
| Holz Basis | `#C8763A` | Korpusfläche |
| Holz Licht | `#E39A5C` | Deckeloberseite, linke Kante |
| Holz Schatten | `#8A4522` | unter Deckelkante, rechte Seite |
| Holz Tiefschatten | `#6B2F16` | Ben-Day-Dots im Schattenfeld, Fuge |
| Spot-Cyan | `#2AA9C9` | ein einziges Deko-Band, Innenraum-Kante |
| Gold | `#F2B633` | Schloss, Beschläge |

**Material-Lesart:** Eiche, handgehobelt; Eisenbänder, genietet; Papier-Etikett. Alles, was man
auf einem Piratenmarkt kaufen würde.

**Kontur-Stil:** *Cursive* + *Feathering*. Korpus 3 px, Deckel 2–3 px, Deko 1–2 px. Kontur auf der
rechten/unteren Seite 1 px dicker als links/oben (= Licht von links oben). An den vier Ecken
**Kontur-Aufstau** (spotting blacks): kleine schwarze Keile, 3×3 px, in den Innenecken.

**Deko-Elemente:** 3 Plankenfugen (1 px, `#6B2F16`), zwei Eisenbänder mit je 2 Nieten, Schloss mit
Schlüsselloch, **Ben-Day-Feld** im unteren Schattenbereich (Punkte 2 px, Raster 5 px, 45° versetzt),
Papier-Etikett schräg auf dem Deckel (4×6 px, `#F3E4C8`, 1 px Kontur, 2 Striche als „Text“).

**Tier-Steigerung**

| Tier | Holz | Beschlag | Deko-Zuwachs |
|---|---|---|---|
| standard | Eiche `#C8763A` | Eisen `#5A5F6B` | 3 Fugen, 2 Bänder, 1 Ben-Day-Feld |
| silver | **silbern gestrichene** Planken `#9AA6B5` / `#6E7887`, Maserung bleibt sichtbar | Zinn `#C9D2DE` | + Cyan-Band, + 4 Ecknieten, + Etikett |
| premium | **schwarz lackiert** `#3A2E2A` mit Goldmaserung | Gold `#F2B633` | + Doppelkontur (2. Linie innen, 1 px versetzt), + dichtes Ben-Day (Raster 4), + Kronen-Relief im Deckel |

Wichtig: Das *Silhouetten-Rezept* bleibt in allen drei Tiers identisch. Steigerung passiert über
**Oberflächenbehandlung + Deko-Dichte**, nicht über neue Formen — sonst erkennt der Spieler die
Kiste nicht wieder.

**Geöffnet:** Deckel liegt hinter dem Korpus (die bestehende `_draw_open()`-Geometrie passt
unverändert). Innenraum = `#12100E` als Hohlraum, darüber ein Cream-Band `#F3E4C8` als
„Papier-Boden“, darin 2–3 flache Goldmünzen (`_disc`, 4–5 px, ohne Glanz). Kontur des geöffneten
Korpus bleibt 3 px; die Innenkante bekommt **keine** Kontur, sondern nur Cream → das liest als
„Licht fällt hinein“ ohne Glow.

**Ein-Satz-Pitch:** „HOLZSCHNITT ist die Kiste, die man aus einem vergilbten Heft ausschneiden
könnte — maximale Lesbarkeit, null Übersättigung, und sie steigert sich über Lack und Gold statt
über Neon.“

---

### Variante B — „KRISTALL-POP“ (Neon Scream)

**Idee:** Magenta-Emaille-Korpus, aufklappender Deckel aus facettiertem Kristall, Cyan-Rim-Light,
Screentone im Inneren. Die lauteste Variante — maximale Fernwirkung im Shop, klare „Premium“-
Ansage, aber empfindlich gegen Übersättigung.

**Referenzen**
- Spider-Verse: sichtbare Ben-Day-Dots als bewusstes Stilmittel:
  https://en.wikipedia.org/wiki/Ben_Day_process · https://www.bbc.com/culture/article/20230606-why-the-spider-verse-films-are-the-greatest-comic-book-movies-ever-made
- Pop-Art-Paletten (Magenta/Cyan-Kombinationen): https://doncorgi.com/blog/pop-art-color-palettes/
- Screentone/Gradient-Dots: https://tips.clip-studio.com/en-us/articles/6227
- Rarity-Farblogik (Violett = Epic, Gold = Legendary): https://www.brandchroma.com/fortnite-colors

**Palette**

| Rolle | Hex | Einsatz |
|---|---|---|
| Ink | `#0E0B14` | Kontur, Kristall-Innenkanten, Impact-Keile |
| Magenta | `#FF2E88` | Korpusfläche (Basiston) |
| Violett | `#553088` | Korpus-Schattenseite (bewusst *nicht* `#3A1B5C`, siehe §4) |
| Violett tief | `#3A1B5C` | nur Innenraum-Hohlraum |
| Cyan | `#00E5FF` | Rim-Light, Kristall-Kanten, Innen-Leuchten |
| Kristall hell | `#CFF7FF` | Facetten-Highlight, Rim-Specular |
| Kristall mittel | `#59C8F0` | Facetten-Grundfläche |
| Kristall dunkel | `#1E6FA8` | Facetten-Schattenseite |
| Gold | `#FFD23F` | Schloss, Premium-Fassung |

**Material-Lesart:** Emaille-Metall (Korpus) + geschliffener Kristall (Deckel, Schloss-Einlage).
Kein Holz, kein Rost — synthetisch, „Sammlerstück“.

**Kontur-Stil:** *Dead-weight*, konstant 3 px, **kein** Taper — die Härte ist die Aussage. Dazu eine
zweite, innenliegende 1-px-Linie in `#CFF7FF` entlang der Lichtkante (Rim-Light als gezeichnete
Linie, nicht als Shader). An Prallstellen (unterer Rand, Deckelfuge) **Impact-Keile**: 3–4 px breite
schwarze Dreiecke, die in die Fläche hineinragen.

**Deko-Elemente:** 5–9 Facetten-Dreiecke (`_tri`) mit je einer hellen Kante, **Screentone** im
Schattenfeld (Punkte 2 px, Raster 4 px, Größe pro Zeile +0/ +1 px = echter Halbton), radialer
Speed-Line-Kranz hinter der Kiste (12 Strahlen, 1 px, `#FF2E88` bei 40 % Deckkraft), Schloss mit
Raute-Einlage, „POW“-Burst optional beim Reveal.

**Tier-Steigerung**

| Tier | Korpus | Kristall | Zuwachs |
|---|---|---|---|
| standard | Magenta `#FF2E88` | 3 Facetten `#59C8F0` | 1 Speed-Line-Kranz (8 Strahlen) |
| silver | Cyan-Blau `#1E6FA8` / `#59C8F0` | 6 Facetten, hellere Kanten | + Rim-Light 1 px, + Schloss-Raute, + 12 Strahlen |
| premium | Violett `#553088` + Gold `#FFD23F` | 9 Facetten + schwebender Diamant | + Innen-Glow (3 konzentrische Ringe, 20/40/60 % Alpha), + Doppelkontur |

**Geöffnet:** Deckel hinter dem Korpus, **Innenraum leuchtet**: drei geschachtelte Ellipsen
(`_ellipse`, 18/12/6 px Radius) in `#CFF7FF` → `#59C8F0` → `#00E5FF` mit abnehmender Deckkraft,
darüber 4 nach oben laufende Lichtstrahlen (1 px, `#00E5FF`, 60 % → 0 %). Kontur des Hohlraums
bleibt schwarz — das Leuchten liegt **innen**, die Kontur schließt es ein. Das ist der Unterschied
zwischen „Comic-Glow“ und „Bloom-Brei“.

**Ein-Satz-Pitch:** „KRISTALL-POP ist die Variante, die auf einem 6-Zoll-Display aus drei Metern
Entfernung noch als ,hier ist was Seltenes‘ schreit — laut, kalt, sammelbar, mit dem stärksten
Reveal-Moment der drei.“

---

### Variante C — „STAHL & SPEEDLINE“ (Diesel Comic)

**Idee:** Verzinktes Blech, sichtbare Schweißnähte, Warnstreifen, Stempel-Nummer. Graustufen-
Monochrom plus **eine** heiße Akzentfarbe. Die nüchternste, „industriellste“ Variante — und
technisch die robusteste, weil sie fast ohne Sättigung auskommt.

**Referenzen**
- Borderlands-Cel-Shading (Kontur als 3D-Stilmittel):
  https://www.artstation.com/blogs/retrostylegames/N41DV/borderlands-art-style ·
  https://www.avclub.com/the-flat-3-d-look-a-brief-history-of-cel-shading-in-1798274914
- Force/Speed-Lines (Martin, Glossary): https://ia600600.us.archive.org/13/items/the-art-of-comic-book-inking/The-Art-of-Comic-Book-Inking.pdf
- Terse Line / Dead-weight: ebd., Glossary
- Kontrast-Referenz: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html

**Palette**

| Rolle | Hex | Einsatz |
|---|---|---|
| Ink | `#0B0D10` | Kontur, Schweißnaht, Stempel |
| Stahl hell | `#DCE3EC` | Deckeloberseite, Rim-Light-Fläche |
| Stahl | `#9AA6B5` | Korpusfläche |
| Stahl dunkel | `#5A6472` | Schattenseite, Rippen |
| Stahl tief | `#343C48` | unter Deckelkante, Innenraum |
| Orange | `#FF6B1A` | **einziger** Farbakzent: Griff, Warnstreifen, Tier-Marker |
| Gelb | `#FFE04A` | Warnband premium, Nieten-Highlight |
| Weiß | `#F7FAFF` | Kratzer, 1-px-Specular |

**Material-Lesart:** Verzinktes Stahlblech, genietet, leicht verbeult; Gummi-Griff; Siebdruck-
Warnstreifen. Werkstatt, nicht Schatzkammer.

**Kontur-Stil:** *Terse line* — dünn an der Lichtkante, dick an der Schattenkante, **ohne** Bauch in
der Mitte (Unterschied zu A!). Korpus 2 px oben, 4 px unten. Dazu **Doppelkontur** an der
Schattenseite: 2. Linie 2 px innen versetzt, 1 px, `#0B0D10` bei 60 % — erzeugt den „fetten“
Blechrand. 1-px-Kratzer in `#F7FAFF` ausschließlich auf der Lichtseite.

**Deko-Elemente:** 8 Nieten (2 px, `#DCE3EC` + 1 px `#5A6472` darunter = Halbton-Niete), 2 Quer-
Rippen, Schweißnaht als Zickzack aus `_thick_line` (1 px, 3 Zacken), Warnstreifen schräg (45°,
3 Streifen `#FF6B1A`/`#0B0D10`), Stempel „07“ (2 px Ziffern-Blöcke), Speed-Lines **horizontal**
an den Seiten (4 Linien, 1 px, 50 % Alpha) als Bewegungsmarker.

**Tier-Steigerung**

| Tier | Oberfläche | Akzent | Zuwachs |
|---|---|---|---|
| standard | mattverzinkt `#9AA6B5` | Orange nur am Griff | 4 Nieten, 1 Riegel, Stempel |
| silver | **poliert** `#DCE3EC` + harte Specular-Kante | Orange an Riegel + 1 Streifen | 8 Nieten, 3 Speed-Lines, Doppelkontur |
| premium | **brüniert** `#343C48` + polierte Kanten | Gelb `#FFE04A` + Gold-Rand | 3 Warnstreifen, Schweißnaht, Kronen-Plakette, Speed-Line-Kranz |

Achtung: In dieser Variante ist „silver“ *das Material* — die Steigerung muss deshalb über
**Politur + Kantenlicht**, nicht über Helligkeit allein laufen, sonst wirkt premium dunkler als
silver (siehe §4).

**Geöffnet:** Deckel hinter dem Korpus, Innenraum `#343C48` mit **einer** Lichtkante `#FFE04A`
entlang der oberen Innenkante (3 px) und einem orange glühenden Bodenstreifen (2 px, `#FF6B1A`
bei 70 %). Inhalt = kantige Barren (`_rect` 8×3 px, `#DCE3EC` + 1 px Schatten), keine Münzen —
Metallkiste, Metallinhalt.

**Ein-Satz-Pitch:** „STAHL & SPEEDLINE ist die Kiste für ein Spiel, in dem geschossen wird —
nüchtern, genietet, mit einer einzigen heißen Orange-Ader, und die einzige der drei, die auch bei
1,5-facher Kantenglättung und miesem Handy-Gamut noch sauber steht.“

---

## 3. Zeichen-Anleitung pro Variante (prozedural, `Image`/`CanvasItem`)

Gemeinsames Skelett für alle drei. **Reihenfolge ist Pflicht** — Kontur wird *nicht* nachträglich
per `_px_outline()` um alles gelegt, sondern jede Form bringt ihre Kontur mit (bei 64 px kostet
`_px_outline` die ganze Fläche und macht aus Deko ein schwarzes Gitter).

```
0. Bild 64×64, fill(0,0,0,0)
1. Bodenschatten:  _ellipse(32, 58, 25, 4, #000000 @32%)
2. KORPUS-Kontur:  _rect(7, 33, 50, 24, INK)
3. Korpus-Füllung: _rect(10, 36, 44, 18, BASIS)
4. Schattenseite:  _rect(10+r, 36, 44-r, 18, SCHATTEN)   # r = rechte Schattenbreite
5. Material-Deko  (Fugen / Rippen / Facetten / Nieten / Ben-Day)
6. LICHTKANTE:     _rect(10, 36, 44, 2, LICHT)           # 2-px-Band oben
7. DECKEL (falls geschlossen): Kontur → Füllung → Licht 2 px → Fuge
8. BESCHLAG:       Bänder/Rippen → Nieten → Schloss
9. RIM-LIGHT:      1-px-Linie entlang der Oberkante in RIM-Farbe
10. AKZENT:        Tier-Marker (Band, Streifen, Plakette)
11. AURA:          Speed-Lines / Strahlen (nur hinter der Kiste, nie darüber)
12. _crop_center(img, 62) → resize(size, NEAREST)   # wie im Ist-Code
```

`r` (Schattenbreite) ist der billigste Stil-Unterscheider: A = 8 px weich in 2 Stufen, B = 6 px hart
in 1 Stufe, C = 10 px in 2 Stufen mit Doppelkontur.

### 3.A HOLZSCHNITT — Schritt für Schritt

```
INK #12100E · BASIS #C8763A · LICHT #E39A5C · SCHATTEN #8A4522 · TIEF #6B2F16
CREAM #F3E4C8 · CYAN #2AA9C9 · GOLD #F2B633
```

1. Schatten-Ellipse: `_ellipse(32, 58, 25, 4, #000000 @32%)`.
2. Korpus: `_rect(7,33,50,24, INK)` → `_rect(10,36,44,18, BASIS)`.
3. Schattenseite rechts: `_rect(44,36,10,18, SCHATTEN)` (weiche Kante durch 2. Stufe
   `_rect(50,36,4,18, TIEF)`).
4. Plankenfugen: für `i in 1..3` → `_rect(10, 36 + i*5, 44, 1, TIEF)`.
5. **Ben-Day-Feld** im Schatten: Doppelschleife `for y in range(38,54,5)` / `for x in range(46,54,5)`,
   jeweils `_px` bei `(x + (y/5)%2*2, y)` in `TIEF` — 2-px-Punkte, 5-px-Raster, 45°-Versatz.
6. Lichtkante: `_rect(10,36,44,2, LICHT)`; zusätzlich `_rect(10,36,2,18, LICHT)` links.
7. Eisenbänder (2×): `_rect(bx,35,6,20, INK)` → `_rect(bx+1,36,4,18, #5A5F6B)` →
   `_rect(bx+1,36,1,18, #A8B0BD)`; `bx ∈ {16, 40}`.
8. Nieten: `_px(bx+2, 38, #DCE3EC)`, `_px(bx+2, 48, #DCE3EC)` je Band.
9. Schloss: `_rect(27,35,10,11, INK)` → `_rect(28,36,8,9, GOLD)` →
   `_rect(28,40,8,1, #B07C0F)` → Schlüsselloch `_px(32,38/39/40, INK)`.
10. Deckel: `_rect(9,20,46,14, INK)` → `_rect(11,22,42,10, LICHT)` → `_rect(11,27,42,5, BASIS)`
    → Fuge `_rect(9,32,46,3, INK)` → Lichtkante Deckel `_rect(11,22,42,2, #F0B47C)`.
11. Etikett: `_rect(34,23,14,6, INK)` → `_rect(35,24,12,4, CREAM)` → 2 Striche `_rect(36,25,8,1, INK)`.
12. Cyan-Band: `_rect(10,50,44,2, CYAN)` + `_rect(10,52,44,1, INK)` (nur ab Tier silver).
13. Rim-Light: `_rect(9,19,46,1, #FFE9C8)` — 1 px, die oberste Zeile. **Keine Zacken**:
    gerade Kante, sonst schlägt `kanten_spitzen()` an.

Offen: Deckel-Schritte 10–11 durch `_draw_open()` ersetzen, dann Boden
`_rect(10,37,44,3, CREAM)` + 2 Münzen `_disc(24,41,4, GOLD)` / `_disc(40,40,4, GOLD)` mit
je 1 px `#B07C0F` darunter.

### 3.B KRISTALL-POP — Schritt für Schritt

```
INK #0E0B14 · MAGENTA #FF2E88 · VIOLETT #553088 · TIEF #3A1B5C
CYAN #00E5FF · CRY_L #CFF7FF · CRY_M #59C8F0 · CRY_D #1E6FA8 · GOLD #FFD23F
```

1. Aura **zuerst**: 12 Strahlen als `_tri` vom Zentrum `(32,42)` nach außen (Radius 30–34),
   Breite 2 px, Farbe `#FF2E88 @40%` — `_aa` aus, sonst franst der Strahl aus.
2. Schatten-Ellipse `_ellipse(32,58,26,4, #000000 @38%)`.
3. Korpus: `_rect(7,33,50,24, INK)` → `_rect(10,36,44,18, MAGENTA)`.
4. Schattenseite: `_rect(42,36,12,18, VIOLETT)` — harte Kante, **kein** Zwischenton
   (Dead-weight-Ästhetik).
5. Screentone im Schatten: `for y in range(37,54,4)` → `_disc(46 + ((y/4)%2)*2, y, 1.0 + (y-37)/16, CRY_D)`
   → Punktgröße wächst von 1 auf 2 px = echter Halbton.
6. Facetten auf dem Korpus: 3× `_tri` mit `CRY_M`-Füllung, je 1 px `CRY_L`-Kante an der
   Lichtseite; Koordinaten z. B. `(14,38)-(24,36)-(20,46)`.
7. Lichtkante: `_rect(10,36,44,2, #FF7FB0)` + Rim `_rect(9,35,46,1, CRY_L)`.
8. Impact-Keile: 3 kleine `_tri` in `INK` an der Unterseite (`(12,56)-(16,52)-(20,56)` usw.).
9. Deckel: `_rect(11,19,42,15, INK)` → `_rect(13,21,38,11, #FF5B9E)` → 3 Facetten
   `_tri` in `CRY_M`/`CRY_D` → Deckel-Lichtkante `_rect(13,21,38,2, CRY_L)`.
10. Schloss: `_rect(26,34,12,12, INK)` → `_rect(27,35,10,10, GOLD)` → Raute
    `_tri(32,37)-(36,41)-(28,41)` in `CRY_L`, untere Hälfte `_tri(32,45)-(36,41)-(28,41)` in `CRY_D`.
11. Rim-Light: `_rect(11,18,42,1, CRY_L)` — 1 px über die Deckeloberseite.

Offen (= der Reveal-Moment): Deckel hinter Korpus; Innenraum `_rect(10,34,44,8, TIEF)` →
3 Ellipsen `_ellipse(32,38, 18/12/6, 4/3/2, CRY_L/CRY_M/CYAN)` mit Alpha 60/80/100 % →
4 Strahlen `_rect(30..34, 26, 1, 6, CYAN @60%)` nach oben. Kontur des Hohlraums bleibt `INK`.

### 3.C STAHL & SPEEDLINE — Schritt für Schritt

```
INK #0B0D10 · L #DCE3EC · M #9AA6B5 · D #5A6472 · SH #343C48
ORANGE #FF6B1A · GELB #FFE04A · WEISS #F7FAFF
```

1. Horizontale Speed-Lines **zuerst** (hinter der Kiste): 4× `_rect(0, 34+i*6, 6, 1, #9AA6B5 @50%)`
   und gespiegelt rechts `_rect(58, 34+i*6, 6, 1, …)` — nur außerhalb der Kiste, nie darüber.
2. Schatten-Ellipse `_ellipse(32,58,25,4, #000000 @32%)`.
3. Korpus: `_rect(7,33,50,24, INK)` → `_rect(10,36,44,18, M)`.
4. Schattenseite: `_rect(40,36,14,18, D)` → `_rect(50,36,4,18, SH)`.
5. **Doppelkontur** Schattenseite: `_rect(53,33,4,24, INK @60%)` (2 px innen versetzt, halbtransparent).
6. Quer-Rippen: 2× `_rect(10, 43, 44, 2, D)` + darunter `_rect(10, 45, 44, 1, INK)`.
7. Lichtkante: `_rect(10,36,44,2, L)` + `_rect(10,36,1,18, WEISS)`.
8. Kratzer: 2× `_px`-Kette in `WEISS`, nur rechts der Mitte, Länge 3–4 px, 1 px breit.
9. Nieten (8): `_px(x, y, L)` + `_px(x, y+1, D)`; `x ∈ {14, 26, 38, 50}`, `y ∈ {39, 51}`.
10. Warnstreifen (ab silver): 3× `_rect` schräg als Treppe (je 3×2 px versetzt), `ORANGE` /
    `INK` im Wechsel, Feld `(12,47)-(30,53)`.
11. Schloss/Riegel: `_rect(25,34,14,10, INK)` → `_rect(26,35,12,8, L)` → `_rect(26,35,12,2, D)`
    → Griff `_rect(31,37,4,4, ORANGE)`.
12. Stempel „07“: 2 Ziffern-Blöcke `_rect(46,38,3,5, INK)` + `_rect(51,38,3,5, INK)` mit
    1-px-Lücken — bei 64 px lesbar, bei 184 px Anzeige noch als „Zeichen“ erkennbar.
13. Deckel: `_rect(9,20,46,13, INK)` → `_rect(11,22,42,9, L)` → `_rect(11,27,42,4, M)` →
    Fuge `_rect(9,31,46,3, INK)` → Rim `_rect(11,21,42,1, WEISS)`.

Offen: Deckel hinter Korpus; Innenraum `_rect(10,34,44,10, SH)`; obere Innenkante
`_rect(10,34,44,3, GELB)`; Bodenstreifen `_rect(10,50,44,2, ORANGE @70%)`; Inhalt
3× `_rect(14+i*12, 44, 8, 3, L)` + je 1 px `D` darunter.

### 3.D Technische Fallstricke (gelten für alle drei)

- **`_aa` aus lassen.** Die Kantenglättung kostet bei 256 px ~0,5 s pro Strahl (Kommentar in
  `tex_draw.gd` zu `_aa_n`) und erzeugt bei Pixel-Art weiche Ränder, die im Comic-Look falsch sind.
- **`_thick_line()` ist eine Disc-Kette** — für Taper reicht: 3 Segmente mit `r = 1.5 / 1.0 / 0.6`
  hintereinander; das liest als Cursive-Linie ohne echten Vektor-Pfad.
- **`kanten_spitzen()` respektieren**: keine Sägezähne in der obersten Zeile. Kristall-Deckel
  deshalb als *flache* Facetten zeichnen, nicht als Zähne — die Zacken gehören in die Aura
  (Strahlen außerhalb der Silhouette), nicht in den Deckel.
- **Kein 1-px-Detail unter einer 2-px-Kontur.** Bei 256→184-Downscale (Faktor 0,717) verschwindet
  jede zweite Pixelzeile unregelmäßig; 1-px-Deko wird zu Rauschen.
- **Punktfelder mit 45°-Versatz** (`(y/step) % 2`), niemals achsenparallel zu einer
  2-px-Kontur — sonst entsteht Moiré (dieselbe Ursache wie im Druck: fehlender Winkelabstand).

---

## 4. Farb- und Kontrast-Check (1080p-Handy)

Messgrößen: WCAG-Kontrastverhältnis gegen die Kontur `INK` bzw. den UI-Hintergrund `#14141C`,
relative Leuchtdichte nach sRGB. Anzeigegröße der Kiste: `cs = clamp(1080 * 0.17, 120, 200) = 183,6 px`;
Textur 256 px → Skalierungsfaktor **0,717 (nicht ganzzahlig)**.

### 4.1 Gemessene Kontraste

| Variante | hellste Fläche | Kontrast zu INK | dunkelste Fläche | Kontrast zu INK | Bewertung |
|---|---|---|---|---|---|
| A Holz | `#F3E4C8` Cream | **15,1 : 1** | `#6B2F16` Tief | 1,85 : 1 | sehr gut, aber Schattenfeld grenzt an Kontur |
| B Kristall | `#CFF7FF` | **17,1 : 1** | `#3A1B5C` (Original) | **1,39 : 1** ✗ | Hohlraum verschmilzt mit Kontur |
| B (korrigiert) | `#CFF7FF` | 17,1 : 1 | `#553088` | 2,01 : 1 | ok |
| C Stahl | `#F7FAFF` | **18,6 : 1** | `#343C48` | 1,75 : 1 | sehr gut, rein valuemäßig |

Kritische Nachbarpaare (Matsch ab < 1,6 : 1):

| Paar | Kontrast | Konsequenz |
|---|---|---|
| A `#C8763A` / `#E39A5C` | **1,48 : 1** | Lichtkante auf Holz ist bei 184 px kaum sichtbar → 2-px-Band + 1-px Cream-Rim nötig |
| A `#C8763A` / `#8A4522` | 2,07 : 1 | grenzwertig, mit 3 px Kontur dazwischen ok |
| B `#FF2E88` / `#553088` | 2,77 : 1 | gut |
| C `#9AA6B5` / `#5A6472` | 2,43 : 1 | gut, weil dazwischen 2 px `INK`-Rippe liegt |
| C `#5A6472` / `#343C48` | 1,86 : 1 | ok mit Doppelkontur |

### 4.2 Wer gewinnt auf 1080p?

**Rangfolge: C > A > B.**

- **C (Stahl & Speedline)** ist die robusteste Variante. Sie ist fast monochrom (Leuchtdichte
  0,04–0,95), hat 18,6 : 1 Spitzenkontrast und nur *eine* gesättigte Farbe (`#FF6B1A`, S = 90 %).
  Auf einem 183-px-Sprite bleiben Kontur, Rippen und Nieten als **Valuestufen** unterscheidbar, auch
  wenn das Display die Sättigung hochzieht (viele Handys fahren „Vivid“ ≈ +20 % Sättigung,
  +15 % Kontrast). Der Orange-Akzent ist der einzige Kanal, den ein Gamut-Überlauf treffen kann —
  und er ist verzichtbar.
- **A (Holz & Druckerschwärze)** ist die wärmste und freundlichste, aber sie hat das schlechteste
  Nachbarpaar (1,48 : 1). Auf billigen LCDs mit niedriger Gamma-Korrektur „verschwimmt“ das
  Ben-Day-Feld im Schatten mit der Kontur — genau dort, wo die Dots 2 px groß sind. Gegenmittel
  ohne Codeänderung: Dots **eine Stufe heller** (`#8A4522` statt `#6B2F16`) und Raster auf 5 px.
- **B (Kristall-Pop)** hat den höchsten Kontrast *und* das höchste Risiko. Zyan `#00E5FF` hat
  S = 100 %, V = 100 %, Magenta S = 82 % — beide liegen am Rand des sRGB-Würfels. Auf OLED-Displays
  mit breitem Gamut werden sie „aus dem Bild heraus“ verstärkt, und ein 2-px-Punktfeld in
  Vollton-Cyan direkt neben Vollton-Magenta erzeugt **Farbsaum-Vibration** (chromatische
  Überlagerung), die als Flimmern wahrgenommen wird. Das ist der klassische Übersättigungs-Matsch:
  nicht zu dunkel, sondern zu laut.

### 4.3 Wo Matsch konkret droht

1. **Der 0,717-NEAREST-Downscale.** 256 → 184 px bedeutet: von je 20 Pixelzeilen fallen ~5
   unregelmäßig weg. Regelmäßige Muster (Ben-Day-Raster 4 px, Screentone 4 px) werden dadurch
   *ungleichmäßig* — sichtbar als „wabernde“ Punktreihen, nicht als Raster. **Regel: Rasterweite
   nie 4, immer 5 oder 6 px** — dann bleibt der Fehler unter der Wahrnehmungsschwelle.
2. **Ben-Day auf kleiner Fläche.** Bei 184 px Anzeige wird aus einer 2-px-Dot (64er-Basis) ein
   Punkt von ~5,7 px, aus Rasterweite 5 ein Abstand von ~14 px — sauber. Bei Rasterweite 3 bleibt
   im 64er-Raster nur 1 px Lücke; nach dem 0,717-Downscale fällt diese Lücke zeilenweise weg und
   das Feld kippt in eine Vollfläche → die Kiste wirkt schmutzig statt gedruckt.
3. **Screentone + Rim-Light gleichzeitig** (B): Punktfeld im Schatten *und* 1-px-Cyan-Kante direkt
   daneben. Der Rim wird von den Punkten „gefressen“.
4. **Silber-Tier in C.** Poliertes `#DCE3EC` (L = 0,762) gegen Premium-Brüniert `#343C48` (L = 0,044)
   heißt: premium ist **dunkler** als silver. Wenn die Tier-Reihenfolge über Helligkeit gelesen
   wird, wirkt premium wie ein Downgrade. Deshalb in C: premium über **Gold-Rand + Gelb-Akzent**
   markieren, nicht über Fläche.
5. **Reines Schwarz auf reinem Weiß** (Kontrast 21 : 1) ist im Comic-Look zu hart für Flächen —
   `#0B0D10` / `#F7FAFF` statt `#000` / `#FFF` kostet 2,4 Kontrastpunkte und nimmt das „Aufkleber“-
   Gefühl.

### 4.4 Empfehlung

Wenn nur **eine** Variante umgesetzt wird: **C** — beste Lesbarkeit, geringstes Sättigungsrisiko,
klarste Tier-Logik über Oberflächenfinish. Wenn die Kisten im Shop **maximale Aufmerksamkeit**
erzeugen sollen (und das ist ihr Job in einem Shop): **B**, aber mit korrigiertem Violett
(`#553088`), Raster 5–6 px und Glow nur *innerhalb* der Kontur. **A** ist die beste Wahl, wenn die
Kisten im Spiel selbst (Welt, nicht Shop) auftauchen — sie ist die einzige, die bei 120 px
Anzeigegröße nicht zufällt.

---

## 5. Pitches

1. **HOLZSCHNITT** — „Die Kiste, die man aus einem vergilbten Heft ausschneiden könnte: warmes Holz,
   Pinselkontur, ein einziger Cyan-Spot, und die Steigerung läuft über Lack und Gold statt über Neon.“
2. **KRISTALL-POP** — „Die Variante, die auf einem 6-Zoll-Display noch aus drei Metern als ‚hier ist
   was Seltenes‘ schreit: Magenta-Emaille, facettierter Kristalldeckel, Cyan-Rim und ein Innenraum,
   der von innen leuchtet statt von außen zu blühen.“
3. **STAHL & SPEEDLINE** — „Die Kiste für ein Spiel, in dem geschossen wird: genietetes Blech,
   Terse-Line-Kontur, eine einzige heiße Orange-Ader — und die einzige der drei, die bei
   0,717-facher NEAREST-Skalierung und miesem Handy-Gamut nachweislich sauber bleibt.“

---

## 6. Belege (alle geprüft)

| Thema | Quelle |
|---|---|
| Liniengewicht, Cursive/Terse/Dead-weight, Force Lines, Kontur-Tiefe | https://ia600600.us.archive.org/13/items/the-art-of-comic-book-inking/The-Art-of-Comic-Book-Inking.pdf |
| Inking-Grundlagen, Lineweight | https://tips.clip-studio.com/en-us/articles/3783 |
| Ben-Day vs. Halbton, Lichtenstein, Spider-Verse | https://en.wikipedia.org/wiki/Ben_Day_process |
| Lichtenstein: flache Farben, Dots, Kontur | https://www.thecollector.com/how-did-roy-lichtenstein-make-his-pop-art/ |
| Lichtenstein-Palette mit Hex | https://www.omoro.io/palettes/lichtenstein-dots |
| Pop-Art-Paletten mit Hex | https://doncorgi.com/blog/pop-art-color-palettes/ |
| Halbton-Winkel (K 45°), Moiré, Frequenz | https://vectorwiz.com/guides/halftones-screen-printing |
| Screentone anwenden | https://tips.clip-studio.com/en-us/articles/6227 |
| Cel-Shading: stepped ramp | https://help.maxon.net/r3d/cinema/en-us/Content/html/Material+Toon.html |
| Cel-Shading: 3 Grundfarben | https://docs.unity3d.com/Packages/com.unity.toonshader@0.15/manual/GettingStarted.html |
| Rim-Light Definition | https://www.toolsforfilm.com/glossary/rim-light |
| Motion/Speed Lines (Studie) | https://pmc.ncbi.nlm.nih.gov/articles/PMC4376351/ |
| Speed Lines als narratives Mittel | https://ojs.uhnsugriwa.ac.id/index.php/lg/article/view/5491 |
| Squash & Stretch | https://courses.cs.washington.edu/courses/cse458/25au/content/exercises/animation_principles.html |
| 12 Prinzipien (PDF) | https://www.dgp.toronto.edu/~patrick/csc418/notes/tutorial11.pdf |
| Onomatopoesie als Typografie | https://theconversation.com/kapow-zap-splat-how-comics-make-sound-on-the-page-160455 |
| Sound-Effects-Design | https://comicbookco.com/comics/comic-book-sound-effects-evolution/ |
| WCAG Kontrast 4,5:1 / 3:1 | https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html |
| Rarity-Farblogik | https://auricartisan.com/library/learn/articles/2026-08-21-color-in-games |
| Rarity-Hex-Referenz | https://www.brandchroma.com/fortnite-colors |
| Borderlands-Cel-Shading | https://www.artstation.com/blogs/retrostylegames/N41DV/borderlands-art-style |
| Cel-Shading-Historie | https://www.avclub.com/the-flat-3-d-look-a-brief-history-of-cel-shading-in-1798274914 |
| Lichtenstein *Whaam!* | https://www.tate.org.uk/art/artworks/lichtenstein-whaam-t00897 |
