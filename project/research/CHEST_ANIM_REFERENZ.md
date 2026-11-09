# Kisten-Öffnungs-Animationen: Referenzen, Zutaten-Katalog, Bauplan

Stand: 2026-11-08 · Ziel: 2D-Comic-Mobile-Game (Godot 4), Kisten-Öffnung **ohne** Kartenband,
Fokus auf der Kiste, 3 Tiers (standard / silver / premium).

**Kurzfassung**

1. „Flashig" ist kein Effekt-Reichtum, sondern **Kontrast**: ruhig → laut → ruhig.
2. Die **Anticipation** dauert länger als der Payoff (ca. 60/40). Der Knall ist der kürzeste Teil.
3. Es gibt **genau einen** lautesten Moment. Alles davor ist leiser, alles danach ist Nachhall.
4. **Sound gibt die Uhr vor**, nicht die Kurve. Jeder Impact-Punkt hat einen Sound.
5. Rarity wird **in Stufen** eskaliert und erst spät verraten.
6. Skip ist Pflicht, und zwar **früh** (ab ~0,5 s), sonst hasst der Vielspieler die Kiste.

---

## 1. Vierzehn Spiele-Referenzen

### 1. Overwatch — Lootbox
https://kotaku.com/why-opening-loot-boxes-feels-like-christmas-according-1793446800

Blizzard-Designer Michael Heiberg beschreibt die Sequenz explizit als Anticipation-Maschine:
Kiste **bricht auf, rüttelt, spuckt nach oben, Items regnen herunter**, und nichts wird vor dem
Ende verraten. Das Glühen aus den **Ritzen** der Box wird bewusst schon *vor* dem Öffnen gezeigt,
um Spannung aufzubauen („we even build a little anticipation with the glow that emits from a
loot box's cracks"). Wichtig als Negativ-Beispiel: Ursprünglich kündigten farbige Lichter vor den
rotierenden Platten die Rarity an — das wurde **verworfen**, weil es die Erwartung zu früh auflöste
(„it killed your anticipation"). Das ist der stärkste Einzelbeleg dafür, dass Rarity-Tells *timing*-
abhängig sind und nicht *früh* sein müssen. Beleggrad: hoch (Entwickler-Interview).

### 2. Hearthstone — Kartenpacks
https://toucharcade.com/2017/04/04/designing-hearthstone-card-packs-animations-iterations-ungoro-and-more-with-art-director-ben-thompson/

Art Director Ben Thompson beschreibt den Produktionsweg: Konzeptart → 3D-Modell → **eigener
FX-/Effects-Verantwortlicher für das Öffnungs-Event**, plus **Storyboard der Öffnungsanimation**,
damit sie „alle Beats" trifft. Jedes Pack bekommt eine **eigene, thematisch passende** Öffnung —
die Animation ist Teil des Inhalts, nicht ein generisches UI-Overlay. Lehre für uns: ein
Storyboard mit markierten Beats (Rütteln / Knall / Reveal / Feiern) ist die eigentliche Arbeit,
nicht der Code. Beleggrad: hoch (Interview), Details zur Kurventechnik nennt die Quelle nicht.

### 3. Clash Royale — Truhen
https://www.therookies.co/blog/education/game-design-ux-best-practices-detailed-breakdown-of-clash-royale

Supercells Truhen-Platzierung ist UX-verankert (Truhenbereich unten, Ein-Hand-Bedienung), und
die Quelle nennt explizit **zwei Öffnungsmodi, „slow and fast opening"** — „after having to open
100+ chests it's a huge time and anxiety saver". Zweiter relevanter Punkt: Truhen-Drops folgen
einer **vordefinierten Reihenfolge**, die zufällig *wirkt* („ordered randomness") — die Erwartung
wird also dramaturgisch geplant, nicht dem Zufall überlassen. Beleggrad: hoch für die Modi,
mittel für die visuelle Choreografie (die Quelle beschreibt UX, keine Frames).

### 4. Brawl Stars — Brawl Boxes → Starr Drops
https://mobilegamer.biz/supercell-explains-brawl-stars-big-comeback-from-an-all-time-low-to-8-8x-revenue/

Supercell hat auf der GDC offengelegt, dass sie Lootboxen 2022 **komplett entfernt** haben, der
Umsatz einbrach, und sie 2023 randomisierte Belohnungen als **Starr Drops** zurückbrachten — mit
dem Satz „We had to infuse rewards once again with excitement". Das ist der seltene Fall, wo ein
Studio den Wert der Reward-*Präsentation* als Retention-Hebel beziffert (Umsatz ×8,8 von Juni 2023
bis Feb 2024). Die Quelle belegt Strategie und Wirtschaftlichkeit, **nicht** die konkrete
Animations-Mechanik der Box — die Choreografie ist hier nicht dokumentiert.

### 5. EA FC / FIFA Ultimate Team — Pack-Walkout
https://www.fut.gg/news/how-to-spot-a-single-vs-double-walkout-in-ea-fc-27/

Die Walkout-Sequenz ist eine **gebaute Leiter**: erst das ganze Stadion (bei einem Board, also
einem schwächeren Pull, startet die Kamera nah und das Item kommt sofort), dann fliegen Drohnen
zur Bühne, dann nacheinander **Nation → Liga → Verein → Spieler**. Die Rarity ist also nicht ein
Effekt, sondern eine **Reveal-Reihenfolge mit steigender Information**. Bemerkenswert: Profis
erkennen an der Drohnenflugbahn *vor* dem Reveal, ob ein „Double Walkout" kommt — der Tell ist
hier bewusst oder billigend in Kauf genommen und wird von der Community als Feature behandelt.
Beleggrad: hoch für den Ablauf, mittel für die Absicht dahinter.

### 6. CS2 — Weapon Cases
https://github.com/immortal-seeker/cs2-simulator-docs/blob/main/docs/sounds.md

CS2 nutzt ein **scrollendes Band mit Tick-Sound pro vorbeiziehendem Item**, das beim Abbremsen in
einen „display"-Sound übergeht, und danach **rarity-abhängige Reveal-Sounds** (blau / lila / pink /
rot / gold). Genau dieses Muster — Tickrate proportional zur Bandgeschwindigkeit, dann ein eigener
Sound für die Stufe — ist der billigste Weg, Spannung hörbar zu machen. Eine reguläre Öffnung
dauert laut Community-Messung **~7 Sekunden** ohne Skip; das ist die Obergrenze, nicht das Vorbild.
Beleggrad: mittel (Fan-Dokumentation der Original-Assets, keine Valve-Quelle).

### 7. Pokémon TCG Pocket — Immersive Cards
https://www.ign.com/wikis/pokemon-tcg-pocket/Immersive_Cards

Die stärkste Eskalations-Idee im ganzen Feld: Bei der höchsten Stufe (3-Sterne „Immersive")
**wechselt die Präsentationsform komplett** — statt Karte mit Effekt öffnet sich eine kurze
animierte Szene, die man per Halten erkundet. Damit ist die Rarity nicht „mehr Partikel", sondern
eine **andere Gattung von Belohnung**. Für ein 2D-Comic-Spiel ist das 1:1 übertragbar: Premium
bekommt eine eigene Panel-Sequenz, Standard nur einen Knall. Beleggrad: mittel (Wiki/Guide,
keine Entwickler-Aussage).

### 8. Candy Crush Saga — „Sugar Crush"
https://candycrush.fandom.com/wiki/Sugar_Crush

Am Levelende werden **übrige Züge in Spezial-Bonbons umgewandelt** und lösen eine Kettenreaktion
aus, begleitet von Text-Ausbrüchen („Sweet!", „Tasty!", „Divine!") — der Payoff wird also
**sukzessive aufgebaut und in Stufen kommentiert**, nicht in einem Frame abgefeuert. Das Muster
„Bühne räumen → Nachbeben → Label-Stufen → Abschluss" ist direkt auf eine Kiste übertragbar.
Beleggrad: mittel (Community-Wiki, kein King-Design-Dokument).

### 9. Coin Master — Slot als Belohnungsmotor
https://www.gamerefinery.com/how-coin-masters-approachable-art-defined-casual-slot-genre/

Coin Master setzt den **Spielautomaten als Kern-Interaktion** ein und kleidet ihn in einen
bewusst „storybook"-weichen, kontrastreichen Stil, der auf Handydisplays lesbar bleibt (Analyse von
Rovios Art Director). Der relevante Mechanismus: das Ergebnis wird von einer **mechanischen
Apparatur** präsentiert (Walzen, Hebel), nicht von einem Popup — die Maschine verkauft die
Spannung. Beleggrad: mittel; die Quelle analysiert Art Style und Genre, **nicht** die
Öffnungs-Choreografie im Detail.

### 10. Genshin Impact — Wunsch-Banner
https://typenorm.com/apps/genshin-impact

Der Wish-Screen ist bewusst ein **eigener, stark produzierter Screen** mit SpotLight auf dem
Feature-Charakter, Timer und Pity-Zähler — die UX-Analyse nennt den Kontrast zur ruhigen
Open World „a probabilistic spend mechanic dressed in celebratory animation". Für hohe Rarity
existiert zusätzlich eine **Sonderanimation** („Capturing Radiance" greift ein, wenn ein 50/50
verloren ginge — https://www.hoyolab.com/article/39798396). Lehre: die aufwendigste Animation
ist an das **seltenste Ereignis** gebunden, nicht an jede Öffnung. Beleggrad: mittel-hoch.

### 11. Apex Legends — Lootbox-Sequenz (akademisch)
https://dl.acm.org/doi/10.1145/3491102.3517642

CHI-'22-Paper (Yin & Xiao): Videoanalyse von **35 Random-Reward-Systemen** plus 14 Spieler-
Interviews. Zentrales Ergebnis für uns: die **erwartete Präsentation skaliert mit dem Aufwand, den
das Item gekostet hat, und mit seinem relativen Wert** — teure/seltene Belohnungen *müssen*
aufwendiger inszeniert werden, billige dürfen es nicht, sonst wirkt die Skala beliebig. Im
Vortrags-Transkript wird die Apex-Öffnung als Beispiel für „juiciness" durch die **Drehung/Spin**
genannt. Beleggrad: hoch (Peer-reviewed) für die Grundregel, mittel für Apex-Details.

### 12. Duelyst — Mystery Crates (Gegenbeispiel)
https://kotaku.com/why-opening-loot-boxes-feels-like-christmas-according-1793446800

Counterplay Games hat die Öffnung bewusst **kurz** gehalten: „There's no reveal animation", die
Kiste platzt auf, die Seiten fliegen weg, Lichtschwaden tragen in die Items — Anticipation steckt
im **Design der Kiste**, nicht in einer Sequenz. Begründung des Entwicklers: das Zielpublikum
öffnet viele Kisten, Gacha-Dramaturgie wurde bewusst vermieden. Das ist das legitimste Argument
gegen eine 5-Sekunden-Show — und der Grund, warum es **zwei Längen** geben muss.

### 13. Halo 5 — REQ Packs
https://kotaku.com/why-opening-loot-boxes-feels-like-christmas-according-1793446800

Lead Progression Designer Christopher Bloom: „You don't want to make anything too long because
some users open multiple in a row." Die Packs sind bewusst **untertreibend** (Karte → Aufplatzen
in ~ein Dutzend Karten, Konfetti, kleines Klingeln), weil sie im Dutzend geöffnet werden; die
Inszenierung ist auf **Batch-Tauglichkeit** optimiert. Direkt relevant für Shop-Kisten, die
Spieler mit erspielter Währung in Serie kaufen.

### 14. Marvel Snap — Reveal-/Split-Effekte
https://snap.fan/news/new-features-on-snapfan/

Marvel Snap trennt **Reveal-Effekt** (beim Aufdecken einer Karte) und **Split-Effekt** (dauerhafte
Kartenvariante mit eigenem Look) — Effekte sind also **modular an ein Objekt gehängt** und werden
kombiniert, nicht als Einmal-Sequenz gebaut. Das ist architektonisch interessant: ein Effekt-Set
pro Rarity-Stufe, das auf jedem Item wiederverwendbar ist. Beleggrad: schwach-mittel (Fan-Datenbank,
die Effekt-Kategorien dokumentiert; keine Design-Aussage zur Choreografie).

### Nicht ausreichend belegt (bewusst nicht ausgeschmückt)

- **Diablo Immortal** (Elder Rift / Legendary Crest): Quellen belegen das *System* (Crest →
  garantierter Legendary Gem, https://www.ign.com/wikis/diablo-immortal/Elder_Rifts), aber ich
  habe keine belastbare Beschreibung der Öffnungs-Choreografie gefunden.
- **Subway Surfers, Arena of Valor, AFK Arena**: keine verwertbare Design-/Technikquelle gefunden
  (nur Gameplay-Videos und Asset-Portfolios). Ich schreibe ihnen deshalb keine Techniken zu.

---

## 2. Zutaten-Katalog (25 Bausteine)

Dauer = **Empfehlungswerte** aus der Dramaturgie unten, keine Literaturaussage. Aufwand:
S = < ½ Tag, M = 1–2 Tage, L = 3+ Tage (inkl. Tuning auf Gerät).

### A. Bühne (das Umfeld ausschalten)

| # | Baustein | Wirkung / Psychologie | Dauer | Godot 4 Umsetzung | Aufwand |
|---|---|---|---|---|---|
| 1 | **Fokus-Dim / Vignette** | Umfeld verschwindet, Blick hat nur ein Ziel. Ohne das konkurriert der Shop mit der Kiste. | 150–250 ms | `CanvasLayer` (layer 90) + `ColorRect` + `ShaderMaterial` (radialer `smoothstep`-Alpha), `modulate:a` tweenen. Optional Vignette statt Vollton (deutlich billiger als Blur). | S |
| 2 | **Letterbox-Balken** | Kinogefühl, „jetzt passiert etwas Offizielles". Trennt Spiel- von Belohnungsmodus. | 120–200 ms | 2 `ColorRect` oben/unten, `create_tween().set_parallel()`, `tween_property(rect, "size:y", h, 0.18).set_trans(TRANS_CUBIC)`. | S |
| 3 | **Kamera-Push-in** | Nähe = Wichtigkeit. Der häufigste „Qualitäts"-Marker überhaupt. | 250–500 ms | Tween auf `scale` des Kisten-Containers (Pivot mittig setzen!) oder auf `Camera2D.zoom`. `TRANS_CUBIC`, `EASE_OUT`. | S |

### B. Anticipation (die eigentliche Kunst)

| # | Baustein | Wirkung / Psychologie | Dauer | Godot 4 Umsetzung | Aufwand |
|---|---|---|---|---|---|
| 4 | **Idle-Atmung** | Kiste wirkt lebendig, „da ist was drin". Winzige Dauerbewegung reicht. | Loop 1,2–2,0 s | `tween_property(scale, 1.02).set_loops()` + `set_trans(TRANS_SINE)`; alternativ `AnimationPlayer` mit Loop. | S |
| 5 | **Wind-up-Squash** | Anspannung vor dem Sprung (klassische Anticipation). | 200–350 ms | Tween `scale` → `Vector2(1.08, 0.92)`, `TRANS_BACK` / `EASE_OUT`. | S |
| 6 | **Rütteln, amplitudensteigend** | „Es will raus." Steigende Frequenz = steigende Erwartung. | 300–900 ms | Tween-Kette: 4–8 Schritte `rotation ±(2°→6°)` und `position ±(3→10 px)`, Abstand 90 ms → 40 ms. Bei kurzer Variante nur 3 Schritte. | S |
| 7 | **Glow aus den Rissen** | Licht von innen = Inhalt existiert. Overwatch-Beleg: bewusst vor dem Öffnen. | 400–1000 ms | Additives `TextureRect` (Riss-Maske) über der Kiste, `modulate:a` 0→1, dazu `Shader` mit animiertem Threshold (`step(noise, t)`), damit Licht „durch die Fugen wandert". | M |
| 8 | **Riser-Sound + Pitch-Anstieg** | Ohren kündigen den Impact an, bevor das Auge ihn sieht. | 600–1200 ms | `AudioStreamPlayer` + `tween_property(p, "pitch_scale", 1.15, 0.8)`, Loop bis zum Knall. | S |
| 9 | **Tick-Sync (Klick pro Rüttel-Peak)** | Macht die Bewegung „mechanisch greifbar", koppelt Ohr an Frame. | je 40–80 ms | `AudioStreamPlayer.play()` im `tween_callback()` jedes Rüttel-Schritts; `pitch_scale` leicht randomisieren (±3 %). | S |

### C. Impact (maximal 1–2 davon pro Öffnung)

| # | Baustein | Wirkung / Psychologie | Dauer | Godot 4 Umsetzung | Aufwand |
|---|---|---|---|---|---|
| 10 | **Hitstop / Freeze** | Kurzer Stillstand lässt Wucht „einschlagen" — der stärkste billige Effekt. | 50–100 ms | `Engine.time_scale = 0.02`, zurück mit `get_tree().create_timer(0.06, true, false, true)` (letztes Arg = `ignore_time_scale`). Vorsicht: betrifft *alle* Tweens. | M |
| 11 | **Impact-Frame (Invert)** | Comic-Signatur: 1–3 invertierte/weiße Frames = „Einschlag". | 33–80 ms | `ColorRect` fullscreen + `canvas_item`-Shader (`COLOR.rgb = 1.0 - screen`) mit `hint_screen_texture`, 2 Frames sichtbar, dann aus. | S |
| 12 | **Kamera-Shake (Trauma)** | Überträgt Wucht auf den Spieler-Körper. | 150–350 ms | Additiver Offset auf Kamera/Container: `for i in 8: tween_property(offset, rand)` mit fallender Amplitude; oder `Tween`-Kette. | S |
| 13 | **Squash → Stretch beim Aufplatzen** | Energie, „Gummi"-Physik. Ohne das wirkt der Knall wie ein Bildwechsel. | 120–200 ms | `scale` (1.28, 0.72) → (1,1), `TRANS_ELASTIC` / `EASE_OUT`. | S |
| 14 | **Deckel-Flug** | Andeutung von Physik + Richtung (Bewegung erzählt, woher das Item kommt). | 400–700 ms | Deckel als eigener Node: `position` (x/y getrennt: y mit `TRANS_QUAD` out, x linear) + `rotation` 0→±35° parallel, dann `modulate:a`→0. | S |
| 15 | **Burst-Partikel (Papier/Funken)** | Materie fliegt — der Frame wird „schmutzig", das wirkt handgemacht. | 300–800 ms | `CPUParticles2D`: `one_shot = true`, `explosiveness = 1.0`, `amount 24–60`, `gravity`, `scale_amount_min/max`, `color_ramp`. Für Konfetti-Nachwelle: zweiter Emitter mit negativer Gravity + `angular_velocity`. | S |
| 16 | **Speed Lines** | Manga-Zoom, „das ist ein Ereignis". Sehr billig, sehr Comic. | 120–300 ms | `Polygon2D`-Fächer (oder mehrere `Line2D`) hinter der Kiste: `scale` 0.6→1.15 + `modulate:a` 1→0. | S |
| 17 | **Lichtstrahlen (Rays)** | Epik/Heiligenschein, hebt das Item aus der Welt. | 600–1500 ms | `Polygon2D`-Stern mit `CanvasItemMaterial.blend_mode = BLEND_MODE_ADD`, `rotation` 0→15° über 1,5 s, `modulate:a` leicht pulsierend. | M |

### D. Reveal (das Item)

| # | Baustein | Wirkung / Psychologie | Dauer | Godot 4 Umsetzung | Aufwand |
|---|---|---|---|---|---|
| 18 | **Rarity-Beam** | Wert ist in 100 ms lesbar, ohne Text. | 400–900 ms | Gestrecktes additives `TextureRect`/`ColorRect` (1 px → 180 px Breite) hinter dem Item, `scale`+`modulate:a` Tween. Farbcode pro Tier. | S |
| 19 | **Farb-Wash** | Farbe = Rarity, wirkt auf die ganze Fläche (Raum „kippt"). | 300–600 ms | Fullscreen-`ColorRect` mit Gradient + `modulate:a` 0→0.25→0.10. Kein Shader nötig. | S |
| 20 | **Item-Pop mit Overshoot** | Belohnung „landet" statt „erscheint". | 250–450 ms | `scale` 0 → 1.15 → 1.0 mit `TRANS_BACK`/`EASE_OUT`, `rotation` −8°→0°, parallel `position` von der Kistenmitte nach oben. | S |
| 21 | **Karten-Flip** | Aufdecken als eigener Moment (Vorderseite → Rückseite → Inhalt). | 200–350 ms | `scale:x` 1→0 (150 ms), im `tween_callback` Textur tauschen, dann 0→1 mit `TRANS_BACK`. | S |
| 22 | **Count-up / Label-Roll** | Zahlen fühlen sich „verdient" an, nicht gesetzt. | 300–800 ms | `tween_method(_set_amount, 0, total, 0.6).set_trans(TRANS_QUAD)`, im Setter `str(int(v))`. | S |
| 23 | **Halte-Moment (Hold)** | Das Gehirn braucht ~0,5 s, um „was ist das?" abzuschließen. Wer hier sofort weiterklickt, verschenkt den Reward. | 400–1200 ms | `tween_interval(0.6)`, Input erst danach freigeben (Button `disabled` bis dahin). | S |

### E. Feedback (Kopplung an den Körper)

| # | Baustein | Wirkung / Psychologie | Dauer | Godot 4 Umsetzung | Aufwand |
|---|---|---|---|---|---|
| 24 | **Sound-Layer (Riser / Impact / Shimmer)** | Ein Ereignis = drei Schichten. Der wichtigste „Juice"-Posten überhaupt. | siehe Timeline | 3 `AudioStreamPlayer` auf eigenem Bus: Riser (endet exakt auf dem Impact-Frame), Impact (Bass + Noise), Shimmer (nur ab Rarity ≥ selten). | S |
| 25 | **Haptik-Puls** | Impact wird körperlich. Nur *ein* Puls, sonst wird es Rauschen. | 20–80 ms | `Input.vibrate_handheld(40, 0.6)` exakt im Impact-`tween_callback`. Auf iOS/Android unterschiedlich spürbar → auf Gerät pruefen. | S |

**Bewusst weggelassen** (Aufwand/Nutzen schlecht auf Handy): radialer Blur und Chromatic
Aberration als Fullscreen-Shader (kosten auf Mid-Tier-Androids Frames und damit genau das Timing,
das den Effekt trägt), echte 3D-Kisten, Physik-Simulation des Deckels.

---

## 3. Drei Dramaturgie-Timelines

### 3.1 Die 2-Sekunden-Variante (Standard-Kiste, häufig geöffnet)

| t (s) | Was passiert | Bausteine |
|---|---|---|
| 0,00 | Dim fährt ein, Letterbox klappt auf, „whoosh" | 1, 2 |
| 0,10 | Push-in auf 112 %, Kiste atmet einmal | 3, 4 |
| 0,30 | Wind-up-Squash (0,25 s), Riser startet | 5, 8 |
| 0,55 | 3× Rütteln, je ein Tick, Glow aus den Rissen | 6, 7, 9 |
| 0,85 | **Hitstop 60 ms** + Impact-Frame 2 Frames + Shake | 10, 11, 12 |
| 0,90 | Aufplatzen, Deckel fliegt, Papier-Burst | 13, 14, 15 |
| 1,05 | Item-Pop, Rarity-Beam, Farb-Wash | 18, 19, 20 |
| 1,30 | Label + Count-up | 22 |
| 1,60 | „Weiter" wird aktiv, Shimmer klingt aus | 23, 24, 25 |
| 2,00 | Letterbox raus, Dim raus | 1, 2 |

Regel: **eine** Steigerung, **ein** Knall, kein zweiter Höhepunkt. Skip ab 0,5 s (springt auf 1,05).

### 3.2 Die 3,5-Sekunden-Variante (Silver)

| t (s) | Was passiert | Bausteine |
|---|---|---|
| 0,00 | Dim + Letterbox, Push-in auf 108 % | 1, 2, 3 |
| 0,20 | Kiste atmet, Glow beginnt zu pulsieren | 4, 7 |
| 0,50 | Rütteln Stufe 1 (leicht, 4 Ticks), Riser | 6, 8, 9 |
| 1,00 | **Pause 150 ms** (Nichts tun ist ein Effekt) | — |
| 1,15 | Rütteln Stufe 2 (heftig, 6 Ticks, schneller), Squash | 5, 6, 9 |
| 1,55 | **Slow-Mo**: 0,25 s auf 0,35× — Risse glühen weiß | 10 (als Slow-Mo), 7 |
| 1,80 | **Hitstop 80 ms** + Impact-Frame + Shake | 10, 11, 12 |
| 1,85 | Aufplatzen, Deckel, Burst + Speed Lines | 13, 14, 15, 16 |
| 2,10 | Rays fahren auf, Item-Pop mit Overshoot | 17, 20 |
| 2,40 | Rarity-Beam + Farb-Wash (silber/weiß) | 18, 19 |
| 2,60 | Karten-Flip, Label, Count-up | 21, 22 |
| 3,10 | Hold, Konfetti-Nachwelle | 23, 15 |
| 3,50 | Ausblenden | 1, 2 |

Regel: **zwei** Rüttel-Stufen mit einer Pause dazwischen — die Pause ist der Unterschied zwischen
„spannend" und „hektisch". Skip ab 0,6 s.

### 3.3 Die 5-Sekunden-Variante (Premium)

| t (s) | Was passiert | Bausteine |
|---|---|---|
| 0,00 | Dim + Letterbox, Hintergrund kippt in Tier-Farbe (schwach) | 1, 2, 19 |
| 0,30 | Push-in 105 % → langsam, Kiste atmet zweimal | 3, 4 |
| 0,70 | Glow wandert durch die Fugen, tiefes Rumble | 7, 8 |
| 1,20 | Rütteln Stufe 1 + erste Funken aus den Rissen | 6, 9, 15 (klein) |
| 1,70 | **Pause 250 ms**, Kamera zieht 3 % zurück („Luft holen") | — |
| 2,00 | Rütteln Stufe 2, Squash, Riser steigt | 5, 6, 8 |
| 2,50 | **Slow-Mo 0,3 s auf 0,3×**, Speed Lines fahren ein | 10, 16 |
| 2,80 | **Hitstop 100 ms** + Impact-Frame + harter Shake | 10, 11, 12 |
| 2,85 | Aufplatzen, Deckel, **großer** Burst, Haptik | 13, 14, 15, 25 |
| 3,10 | Weiß-Blitz, Rays drehen auf, Farb-Wash voll | 11 (kurz), 17, 19 |
| 3,30 | Item-Pop (Overshoot + Rotation), Beam in Rarity-Farbe | 20, 18 |
| 3,60 | Karten-Flip → Detail-Panel, Count-up | 21, 22 |
| 4,20 | Hold 0,8 s, Konfetti-Nachwelle, Shimmer-Akkord | 23, 15, 24 |
| 5,00 | Ausblenden, Dim/Letterbox raus | 1, 2 |

Regel: Premium ist **nicht** „mehr von allem", sondern **eine Stufe mehr plus eine Pause mehr**.
Skip ab 0,8 s muss auf **allen** Stufen existieren; bei Batch-Öffnung (mehrere Kisten) die kurze
Variante erzwingen (Halo-5-Lehre).

---

## 4. Was billig wirkt — und was nicht

### Was billige Handygames falsch machen

1. **Alles gleichzeitig.** Funken, Shake, Konfetti, Blitz im selben Frame → das Auge findet keinen
   Fokus, der Impact wird nicht als Impact gelesen.
2. **Konstante Lautstärke.** Dauer-Rumble und Dauer-Glow ohne An/Aus; ohne Stille davor wirkt
   nichts laut.
3. **Lineare Eases / keine Overshoots.** Alles fährt „gleichmäßig" — sieht nach Placeholder aus.
4. **Rarity wird zu früh verraten** (Beam-Farbe schon beim Rütteln), oder umgekehrt: die Farbe
   kommt erst mit dem Text. Beides nimmt dem Reveal seinen Moment.
5. **Partikel ohne Tiefe**: gleiche Größe, gleiche Geschwindigkeit, kein Fade, kein Farbverlauf →
   sieht wie ein Sticker aus, nicht wie Materie.
6. **Shake auf dem ganzen Screen, ohne Abklingen.** Equal-amplitude-Rumble liest sich als
   Ruckeln/Bug, nicht als Wucht.
7. **Kein Sound-Sync.** Ein „Pop" für 3 Sekunden Animation; die Bewegung hat keinen Rhythmus.
8. **Zu lang und kein/zu später Skip.** 6–8 s ohne Ausstieg ist der häufigste Hass-Grund bei
   Vielspielern (siehe Halo-5- und Clash-Royale-Zitate).
9. **Toter Moment nach dem Reveal.** Kein Hold, kein Nachklang, Button schon aktiv → der Reward
   wird „weggeklickt", bevor er ankommt.
10. **Fake-Spannung**: ein Band, das offensichtlich nur Dekoration ist (Gewinner steht vorher
    fest, „Fast-Treffer" werden inszeniert). Das ist nicht nur billig, es ist die Mechanik, die
    Lootbox-Kritik auf sich zieht — und Vielspieler erkennen sie.
11. **Stilbruch.** Glow, Lens-Flares und 3D-Partikel in einem flachen Comic-Look → zwei
    Bildsprachen in einem Screen.
12. **Ruckeln.** Fullscreen-Shader auf Mid-Tier-Hardware → 30 fps mitten im Impact; damit ist die
    beste Kurve kaputt.

### Was AAA / erfolgreiche Titel richtig machen

1. **Drei Akte, ein Höhepunkt.** Anticipation länger als Payoff (grob 60/40), danach Nachhall.
2. **Stille als Werkzeug.** Pausen (Overwatch, EA-FC-Leiter) machen den Knall erst laut.
3. **Eine Informations-Hierarchie.** Bei EA FC: Nation → Liga → Verein → Spieler. Bei uns:
   Kiste → Rarity → Item → Menge. Nie alles gleichzeitig.
4. **Sound führt die Kurve**, Effekte hängen an Sound-Events (CS2: Tick pro Item, eigener
   Reveal-Sound je Rarity).
5. **Eskalation in Stufen statt Sprung.** Eine Stufe mehr Aufwand pro Tier, nicht „alles an".
6. **Der Reveal wird gehalten.** Ein bewusster Hold-Moment, in dem nichts passiert außer Ansehen.
7. **Respekt vor der Zeit**: zwei Längen, früher Skip, Batch-Modus (Clash Royale: „slow and fast").
8. **Konsistenz mit der Marke.** Die Öffnung sieht aus wie das Spiel, nicht wie ein Fremd-Plugin
   (Hearthstone baut pro Pack eine eigene, thematische Öffnung).
9. **Klarer Fokus**: ein Dim, eine Kiste, ein Item. Kein konkurrierender Shop im Hintergrund.
10. **Haptik punktuell** genau auf dem Impact — nicht als Dauerbrummen.

---

## 5. Empfehlung: die 10 Bausteine mit dem besten Flash/Aufwand-Verhältnis

Für ein 2D-Comic-Spiel auf Handy, 3 Tiers, ohne Kartenband. Alle Positionen sind **S** — das ist
die gute Nachricht: „flashig" ist hier eine Frage der Dramaturgie, nicht des Budgets.

| Rang | Baustein | Warum zuerst | Aufwand |
|---|---|---|---|
| 1 | **Fokus-Dim + Letterbox** (#1, #2) | Verwandelt „Popup" in „Szene". Größter Qualitätssprung pro Zeile Code. | S |
| 2 | **Kamera-Push-in** (#3) | Der billigste „das ist wichtig"-Marker. | S |
| 3 | **Rütteln mit steigender Frequenz + Tick-Sound** (#6, #9) | Erzeugt Erwartung, und zwar hörbar. | S |
| 4 | **Hitstop + Impact-Frame** (#10, #11) | Der Comic-Moment schlechthin: 2 Frames Invert = „BAM". Unterscheidet dich von 08/15-Shops. | S |
| 5 | **Squash→Stretch + Deckel-Flug** (#13, #14) | Bewegung mit Physik-Gefühl statt Bildwechsel. | S |
| 6 | **Burst-Partikel in Papier-Optik** (#15) | „Handgemacht" statt VFX-Pack — passt zum Comic-Look. | S |
| 7 | **Rarity-Beam + Farb-Wash** (#18, #19) | Rarity wird ohne Text lesbar; trägt die Tier-Unterscheidung. | S |
| 8 | **Item-Pop mit Overshoot + Karten-Flip** (#20, #21) | Der Reward „landet" statt zu erscheinen. | S |
| 9 | **Sound-Layer + Haptik** (#24, #25) | Der stärkste Juice-Posten überhaupt; ein Puls am Impact reicht. | S |
| 10 | **Hold 0,6 s + Skip ab 0,5 s** (#23 + Skip) | Ohne Hold kein Genuss, ohne Skip kein Respekt. Beides ist „Nichtstun". | S |

**Optionale Upgrades** (nur wenn Zeit): Rays (#17, M) für Premium, Glow aus Rissen (#7, M) als
Tier-Merkmal, Speed Lines (#16, S) für den Premium-Knall.

**Konkrete Zuordnung zu den drei Tiers**

- **standard** → 2,0-s-Timeline, Bausteine 1–2, 3–6, 9–15, 18–20, 22–25. Farbcode neutral/gelb.
- **silver** → 3,5-s-Timeline, plus #5, #7, #16, #17 (klein), #21, zweite Rüttel-Stufe, Pause.
- **premium** → 5,0-s-Timeline, plus #7 groß, #17, Slow-Mo (#10), zwei Pausen, Weiß-Blitz,
  Konfetti-Nachwelle, längster Hold. Premium bekommt **eine andere Form**, nicht nur mehr Effekt.

**Technische Leitplanken (Godot 4, Mobile)**

- Alles in **einem** `CanvasLayer` (layer ≥ 90) über dem Shop, damit Dim/Letterbox/Partikel
  garantiert über allem liegen; Tweens auf `Control`-Properties sind auf Handy billiger als
  Node-Instanziierung pro Frame.
- Timings **nicht** über `await`-Ketten, sondern über eine Tween-Kette mit `tween_callback()` —
  dann lässt sich mit einem `kill()` sauber skippen (`_tween.kill()` → direkt auf Reveal-Zustand
  setzen). Der bestehende Skip-Pfad in `chest_ui.gd` (`ui_cancel`) kann das weiter nutzen.
- `Engine.time_scale` nur mit `create_timer(..., ignore_time_scale = true)` zurücksetzen, sonst
  hängt das Spiel im Slow-Mo fest.
- Partikel: `CPUParticles2D` (Compatibility-Renderer, wenige Dutzend Partikel) statt
  `GPUParticles2D` — bei 24–60 Partikeln ist der GPU-Weg Overhead ohne Nutzen.
- Fullscreen-Shader nur, wenn sie < 0,5 ms kosten; im Zweifel Farb-Wash (#19) statt Shader.
- Auf **echtem Gerät** timen: 60-fps-Timing fühlt sich auf 30-fps-Geräten anders an; Impact darf
  nie in einen Frame-Drop fallen. Im Zweifel Impact 20 ms später legen.
- `Input.vibrate_handheld()` respektiert Systemeinstellungen nicht überall — Haptik als Bonus
  behandeln, nie als Informationsträger.

---

## 6. Quellen

- Kotaku, „Why Opening Loot Boxes Feels Like Christmas, According To Game Devs" (Overwatch,
  Duelyst, Halo 5): https://kotaku.com/why-opening-loot-boxes-feels-like-christmas-according-1793446800
- TouchArcade, „Designing Hearthstone Card Packs … With Art Director Ben Thompson":
  https://toucharcade.com/2017/04/04/designing-hearthstone-card-packs-animations-iterations-ungoro-and-more-with-art-director-ben-thompson/
- The Rookies, „Game Design UX Best Practices — Clash Royale":
  https://www.therookies.co/blog/education/game-design-ux-best-practices-detailed-breakdown-of-clash-royale
- MobileGamer.biz, „Supercell explains Brawl Stars' big comeback" (GDC):
  https://mobilegamer.biz/supercell-explains-brawl-stars-big-comeback-from-an-all-time-low-to-8-8x-revenue/
- FUT.GG, „How to Spot a Single vs Double Walkout in EA FC 27":
  https://www.fut.gg/news/how-to-spot-a-single-vs-double-walkout-in-ea-fc-27/
- CS2 Case-Opening Sound-Doku: https://github.com/immortal-seeker/cs2-simulator-docs/blob/main/docs/sounds.md
- IGN, Pokémon TCG Pocket „Immersive Cards": https://www.ign.com/wikis/pokemon-tcg-pocket/Immersive_Cards
- Candy Crush Wiki, „Sugar Crush": https://candycrush.fandom.com/wiki/Sugar_Crush
- GameRefinery, „How Coin Master's approachable Art defined Casual Slot genre":
  https://www.gamerefinery.com/how-coin-masters-approachable-art-defined-casual-slot-genre/
- Typenorm, Genshin-Impact-UX-Analyse: https://typenorm.com/apps/genshin-impact
- HoYoLAB, Wish-System/„Capturing Radiance": https://www.hoyolab.com/article/39798396
- Yin & Xiao, „The Reward for Luck" (CHI '22): https://dl.acm.org/doi/10.1145/3491102.3517642
- Snap.fan, Reveal-/Split-Effekte: https://snap.fan/news/new-features-on-snapfan/
- IGN, Diablo Immortal „Elder Rifts" (nur Systembeleg):
  https://www.ign.com/wikis/diablo-immortal/Elder_Rifts
- „Juice It or Lose It" (Jonasson & Purho, 2012), Zusammenfassung:
  https://gdad.wiki/wiki/sources/source-juice-it-or-lose-it
- Godot 4 Docs: Tween https://docs.godotengine.org/en/stable/classes/class_tween.html ·
  CanvasLayer https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html ·
  CPUParticles2D https://docs.godotengine.org/en/stable/classes/class_cpuparticles2d.html ·
  Input.vibrate_handheld https://docs.godotengine.org/en/stable/classes/class_input.html ·
  Screen-reading Shader (hint_screen_texture / BackBufferCopy)
  https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
- Material 3, Easing & Duration (Rahmen für UI-Timings ≤ 500 ms):
  https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration

## 7. Grenzen dieser Recherche

- **Dauern in ms sind Empfehlungen**, keine Messungen. Keine der Quellen nennt Frame-genaue
  Timings; die Timelines sind aus den beschriebenen Abläufen abgeleitet und müssen auf Gerät
  nachgetunt werden.
- **Keine Quelle** beschreibt eine Kisten-Öffnung speziell für ein 2D-Comic-Spiel — der
  Comic-Teil (Impact-Frame, Speed Lines, Halftone) ist eine Übertragung der Bildsprache, keine
  belegte Praxis.
- Für **Subway Surfers, Arena of Valor, AFK Arena** und die **Diablo-Immortal-Animation** habe ich
  keine belastbare Technikquelle gefunden; sie sind deshalb nicht mit behaupteten Techniken
  aufgeführt.
- Die CS2-Sound-Doku ist eine **Fan-Rekonstruktion** der Original-Assets, keine Valve-Dokumentation.
