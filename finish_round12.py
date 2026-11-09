import io

# ---------------- 1) Testcode entfernen ----------------
P = r'C:\Users\vince\Games\comic-shooter\project\scripts\game_manager.gd'
s = io.open(P, encoding='utf-8').read()
i = s.index("func _worldtest() -> void:")
j = s.index("func _ready():")
s = s[:i] + s[j:]
s = s.replace('''func _ready():
	if OS.get_environment("COMIC_WORLD") != "":
		_worldtest()
	_load_high_score()''', '''func _ready():
	_load_high_score()''', 1)
io.open(P, 'w', encoding='utf-8').write(s)
print("Testcode entfernt:", s.count("_worldtest"))

# ---------------- 2) Plan ----------------
PLAN = r'C:\Users\vince\Games\comic-shooter\PLAN_MASTER.md'
p = io.open(PLAN, encoding='utf-8').read()

O = r'''### O — RUNDE 12: Echte Welten statt Biom-Varianten + Schalter-Freischaltung + HUD-Neubau ✅

#### 1. Analyse: warum die alten Karten sinnlos waren (Kritik aus dem Chat)
Die vier „Karten" waren nur **Start-Biome derselben Karte**: die Erde-Karte lief per Score sowieso durch Wiese → Wüste → Eis → Lava. Wer eine „Wüste" kaufte, bekam also nichts, was er nicht in jedem zweiten Run gratis gesehen hätte — und bei 600–900 Gold war es zusätzlich zu billig. Karten müssen **eigene Welten mit eigenem Inhalt** sein (eigene Monster-Rigs, eigene Physik), sonst ist der Kauf Betrug am Spieler.

#### 2. Neues Karten-Modell
| Karte | Welt & Inhalt | Eigene Monster (neue Rigs) | Eigene Physik / Eigenheit | **Schalter** (Freischaltung) | Gold-Alternative |
|---|---|---|---|---|---|
| **ERDE** | die komplette Reise: Wiese → Wüste → Eis → Lava | die 11 bestehenden Typen + Boss | Standard | frei | – |
| **MARS** | roter Sand, Krater, kein Grün; Felsen statt Bäume | **Mars-Männchen** (schwebt, Antenne, schießt Strahlen), **Mars-Rover** (14 HP, fährt langsam und **rammt in Schüben** mit kurzer Anlauf-Warnung) | **Drift-Physik (`drift 0.20`)** — der Held rutscht nach, man muss gegensteuern; Gegner +5 % Tempo | **2.500 XP in EINEM Run** | 6.000 Gold |
| **JUNGLE-PLANET** | dichter Dschungel, **2,1-fache Vegetation** (Palmen + Büsche als Deckung) | **Robo-Affe** (bleibt auf Abstand, **wirft Bananen** — drehen sich im Flug), **Riesenblume** (verwurzelt, spuckt Sporen) | viele Hindernisse → Sichtlinien zu, Gegner **+15 % Schaden** | **3.500 XP in einem Run** *und* Mars vorher frei | 12.000 Gold |

Neue, prozedural gezeichnete Rigs (keine Asset-Dateien): `monster_mars_alien`, `monster_mars_rover`, `monster_robo_ape`, `monster_big_flower`, dazu `banana` (Projektil, rotiert im Flug), `palm`, `bush`, `mars_rock`, `mars_crater` und die Karten-Icons `map_mars`/`map_jungle`. Zwei neue Biome im Map-Generator (`mars`, `jungle`) mit eigenen Bodenfarben, Rasterlinien, Sprenkeln und Deko-Texturen.

#### 3. Schalter-Logik (genau, wie gewünscht)
Ein Kartenschalter ist ein **Run-Meilenstein**, kein Kauf:
```
gate = { "type": "xp", "need": 2500, "prereq": "" }      # Mars
gate = { "type": "xp", "need": 3500, "prereq": "mars" }  # Jungle
```
- `run_xp` zählt jeden Kill-XP **innerhalb eines Runs** (Reset bei jedem Start).
- `_check_map_gates()` läuft **live bei jedem Kill** und noch einmal am Run-Ende; sind `need` **und** `prereq` erfüllt, wird die Karte freigeschaltet → Sound + Banner **„NEUE KARTE: MARS"**, Karten-Seite aktualisiert sich sofort.
- **Sichtbarkeit des Schalters an drei Stellen:** (a) im **Run-HUD** rechts unten im Panel der Hinweis `MARS: 1820/2500 XP`; (b) auf der **KARTEN-Seite** pro gesperrter Karte der Block **„SCHALTER: 2500 XP in EINEM Run (Bestwert 1240)"** mit Fortschrittsbalken; (c) bei erfüllter Voraussetzung aber fehlendem Vorgänger stattdessen „Erst MARS freischalten".
- `best_run_xp` wird **persistiert** — der Balken zeigt also den Fortschritt über Runs hinweg, ohne dass man ihn verliert.
- Gold bleibt als **Abkürzung** für Ungeduldige (6.000 / 12.000 — bewusst teuer), damit Gold nicht entwertet wird.

#### 4. HUD im Run neu gebaut (gemeldeter Bug)
**Bug:** `combo_label` lag bei (200,44) und damit **über** der XP-Zeile (10,54); der Wellen-/Münz-Text bei (200,78) klebte direkt am XP-Balken — deshalb „sieht man das Gold nicht".
**Jetzt vier getrennte Bereiche in Panels** (`_hud_panel_sb`, halbtransparent, gerundet):
- **oben links**: Panel mit Herzreihe (+ P2-Reihe versteckt) und darunter `LVL n` + XP-Balken.
- **oben Mitte**: Score groß (48 px, Outline) mit Combo-Zeile darunter; **Boss-Balken** mittig unter dem Score.
- **oben rechts**: **Waffen-Panel** mit Titel „WAFFEN (antippen zum Wechseln)" und den Waffenkacheln (Icons, aktive hervorgehoben) — darunter getrennt der **Münz-Chip** (Münz-Icon + Zahl) und darunter die **Wellen-Zeile** („WELLE 3 · 7 Monster übrig"), dann die Buff-Zeile und der neue **Schalter-Hinweis**.
- **links unten vom Leben-Panel**: die Mitspieler-Liste (bis 3 Zeilen); FPS/Debug bleibt unten links.
`update_wave_label()` setzt jetzt **Münzen und Wellentext getrennt** (`coin_label` / `wave_label`), damit sich nichts mehr überlagert.

#### 5. Verifikation (headless, echter Lauf)
```
WT vorher karten=["earth"] hinweis=MARS: 1240/2500 XP
WT nach_2600 karten=["earth","mars"]                       (Schalter kippt live)
WT nach_3600 karten=["earth","mars","jungle"]              (prereq-Kette greift)
WT kartenseite karten=3 schalterbloecke=2 erster='SCHALTER: 2500 XP in EINEM Run  (Bestwert 1240)'
WT mars biome=mars drift=0.2 veg=1.0
WT mars pool_verteilung={1:68, 11:73, 0:90, 12:32, 2:23, 3:14}   (11=Mars-Maennchen 24%, 12=Rover 11%)
WT panels links_x=18.0 rechts_x=-436.0 muenzpanel=true schalterlabel=true
WT welle='WELLE 3   ·   7 Monster uebrig' muenzen=42 muenzpanel_sichtbar=true
WT_DONE
```
Plus 0 `SCRIPT ERROR`/`Parse Error` im Regressionlauf. **Migration:** alte Profile mit `unlocked_maps=["meadow"]`/`active_map="meadow"` werden automatisch auf die neue ID `earth` umgeschrieben.

#### 6. Bewusst offen (nächste Runde)
Meteoriten-Einschläge auf Mars (Warnschatten → Einschlag), Bananen-**Splitter** beim Aufprall, **eigene Karten-Bosse** (Meteor-Boss / Affen-Boss statt Krone-Boss), Drift auch für Monster, und die Clash-Royale-Idee **Deko-Sammelartikel** (nur Aussehen, keine Wirkung) als zusätzlicher Kisten-Inhalt.

'''
p = p.replace("### K — OFFEN / NÄCHSTE RUNDE ⏳", O + "### K — OFFEN / NÄCHSTE RUNDE ⏳", 1)

p = p.replace("| **Weitere Karten & Mobs als Sammel-Inhalt** | Struktur steht (`MAPS`-Tabelle + `monster_bias`): neue Karte = ein Eintrag; als nächstes z. B. „Wüste II" mit eigenen Mob-Varianten, Deko-Artikel (Clash-Royale-Idee) als reine Sammelstücke ohne Gameplay-Wirkung |",
"| ~~**Weitere Karten & Mobs als Sammel-Inhalt**~~ | ✅ **GEBAUT (Runde 12)** — Mars + Jungle als echte Welten mit eigenen Rigs, Physik und XP-Schaltern; nächster Ausbau: Karten-Bosse, Meteoriten, Deko-Artikel |", 1)

io.open(PLAN, 'w', encoding='utf-8').write(p)
print("Plan:", len(p), "Zeichen")
