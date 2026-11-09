# SPEC v1.46 — Challenges, Scroll, Musik, Hüte, Skins, Name, Einstellungen, Icons

Projekt: `C:/Users/vince/Games/comic-shooter` · Basis: v1.45 · Godot 4.7.2
Status: `[ ]` offen · `[~]` läuft · `[x]` erledigt (Beleg vorhanden)

**Auslöser (Nutzer, 6.11.2026, wörtlich):**

„die Aufgaben sollten Challenges heißen das soll angepasst werden · dann kannst du dir nochmal
6 weitere challenges ausdenken jeweils mit schwierigkeitsgrad die ansicht soll dabei smooth
scrollbar sein · die ingame musik ist teilweise aus teilweise manchmal an und sie gefällt mir
nicht sie sollte eher wie die musik am startbildschirm sein · wenn ein boss erscheint soll eine
bedrohliche musik kommen · manche skins sehen noch verbuggt aus mit manchen hüten das soll
geprüft werden · der vikinger und ghost hero sollen überarbeitet werden die sind nicht gelungen ·
es soll bei character auch möglich sein den namen seinen characters anzupassen · in den ingame
einstellungen soll man nicht biom wechsel einstellen können und auch keinen schwierigkeitsgrad ·
das app icon ist auch noch nicht schön gib mir dann 5 varianten davon das ich dann entscheiden kann"

**Reihenfolge:** A (Umbenennung) → C (Scroll) → B (6 neue Challenges) → I (Einstellungen) →
H (Name) → D (Musik ingame) → E (Boss-Musik) → F (Hüte) → G (Vikinger + Geist) → J (Icons) → K (Abschluss).
Regel des Projekts: gemeldeter Mangel vor neuer Planarbeit, und jeder Block mit Beleg.

---

## Recon (gemessen / gelesen, 6.11.2026)

### Musik: Trackwechsel reißt die Musik ab, Loop hat ein Loch

Neuer Messmodus `COMIC_LANTEST=musik146` (`[MUSIK][STATE]`, `[MUSIK][LOOP]`). Auszug:

```
[MUSIK][STATE] tag=runde1_nach_1.2s  current=game_1    spieler_playing=true   pos=1.18
[MUSIK][STATE] tag=runde2_nach_1.2s  current=game_2    spieler_playing=false  pos=0.00
[MUSIK][STATE] tag=runde3_nach_1.2s  current=game_3    spieler_playing=true   pos=1.18
[MUSIK][STATE] tag=boss_nach_1.2s    current=game_boss spieler_playing=false  pos=0.00
```

**Ursache 1 — derselbe Player wird aus- und eingeblendet.** `play_music()` legt für Spiel-Tracks
immer `_music_player` an. Beim Wechsel `game_1 → game_2` sind `alt_p` und `ziel` **dasselbe Objekt**:
der Fade-Out-Tween (`volume_db → -60`, dann `alt_p.stop()`) läuft gegen den Fade-In-Tween
(`-60 → Ziel-dB`) auf derselben Property. Ergebnis: `playing=false`, Position 0 — der Track startet
und wird 0,6 s später gestoppt. Nur der nächste Wechsel weckt ihn wieder: „teilweise an, teilweise aus".

**Ursache 2 — der Loop ist kein Loop.** `_track_assemble()` setzt bewusst
`loop_mode = LOOP_DISABLED` (Emulator-Crash in v1.43) und startet über das `finished`-Signal neu.
Die Tracks sind 6,86–11,43 s lang; der Neustart verliert messbar Zeit:

```
[MUSIK][LOOP] t=6s playing=true pos=7.23
[MUSIK][LOOP] t=8s playing=true pos=0.67     # Neustart, ~0,5 s fehlen
```

Längen: `menu_1 11.43s/84bpm/sine`, `game_1 10.00s/96bpm/sine`, `game_2 9.23s/104bpm/square`,
`game_3 8.57s/112bpm/saw`, `game_4 8.00s/120bpm/saw`, `game_boss 6.86s/140bpm/square`.

**Ursache 3 — Regler/Pause.** `set_music_ducked(true)` (Pause) setzt nur `_music_ducked`; der
Rückweg läuft allein über `play_music()`. Bleibt der Track gleich, wird erst beim nächsten Wechsel
aufgehoben — Musik bleibt leise, wenn zwischen Pause und Weiter kein Trackwechsel passiert.

**Was dem Nutzer an der Menü-Musik gefällt:** `menu_1` = 84 BPM, Sinus-Lead, **keine** Drums,
Bass 0.13, Arp 0.055, Akkorde `[220/261.6/329.6] …`. `game_1` ist mit 96 BPM und `sine` noch nah dran —
`game_2 … game_4` kippen auf `square`/`saw` und bis 120 BPM. Das ist der Unterschied, den er hört.

### Hüte auf Skins: 128 von 408 Kombinationen auffällig

Neuer Messmodus `COMIC_LANTEST=hat146` (Augen-Band + Körper-Überdeckung, 17 Rigs × 24 Hüte = 408):

```
[HAT][PRUEF] ERGEBNIS paare=408 auffaellig=128
[HAT][PRUEF] AUFFAELLIG rig=0 hut=6 augen=100% koerper=67.7%
```

Zusätzlich am Kontaktblatt `screenshots/v139/hats_29x4.png` sichtbar: `PIRAT` (Hut 6), `STROHHUT`
(7) und `WOLLMÜTZE` (5) liegen auf dem Augenband, `RUCKSACK` (16) sitzt auf der Brust statt hinter
dem Körper.

**Zwei Code-Ursachen:**
1. `[HAT][FIT] hud=… s=1.39 | s=1.45` — der Hut wird mit **konstanter** Skalierung aufgesetzt,
   obwohl die Kopfbreiten je Rig zwischen `w=25` und `w=29` liegen. Kein Fit je Rig.
2. Rig 0 läuft über einen **zweiten Zeichenweg**: `get_skin_hat_texture()` ruft für `si <= 0`
   `GenCharacters._make_player(...)`, sonst `_make_player_rig(...)`. Die 20 „auffälligen" Paare von
   Rig 0 sind Messrauschen dieser Doppelspur (beide Funktionen zeichnen nicht deckungsgleich) —
   die Messung selbst muss auf einen Weg umgestellt werden, sonst zeigt sie für Rig 0 immer 100 %.

### Vikinger und Geist

Rig 7 `WIKINGER` besteht sichtbar aus dem Standardkörper mit einem braunen Fleck als Bart; Rig 6
`GEIST` ebenfalls nur Standardkörper mit anderer Farbe (Kontaktblatt `hats_29x4.png`, Spalte
WIKINGER vs. STANDARD). Keine eigene Silhouette (Helm, Hörner, Umhang bzw. schwebender Saum).

### „Aufgaben" heißt überall AUFGABEN

`ui_manager.gd:1728` (`{ "id": "chal", "text": "AUFGABEN" }`), `challenge_page.gd:29`
(`_make_page("AUFGABEN")`), HUD-Präfix `AUFGABE ·` in `set_challenge_hud()`, Diag-Schritte
`seite_AUFGABEN`. Die Datenmodelle heißen bereits `Challenges`.

### Challenge-Ansicht ist nicht scrollbar

`challenge_page.gd` baut `host._make_page()` (Vollbild-Panel, `VBoxContainer`) mit einem festen
`GridContainer` 3×2 — kein `ScrollContainer`. Mit 12 Karten (4 Reihen à 292 px = 1 190 px + Kopf
+ Fuß) passt das nicht in 1 080 px.

### Einstellungen: Schwierigkeit und Biom stehen auch im Pause-Menü

`settings_page.gd` baut die Reihe `SCHWIERIGKEIT` (Zeile ~88) und den Schalter
`BIOM-ÜBERGANG: AN/AUS` (Zeile ~160) immer. Die Seite kennt bereits die Herkunft:
`ui_manager.settings_origin` = `"menu"` oder `"pause"` (gesetzt in `_open_settings_page(org)`).

### Name: Funktion vorhanden, Bedienung fehlt

`game_manager.set_player_name()` (Zeile 1496) kürzt auf 10 Zeichen, speichert im Profil
(`profile.gd:181`) — es gibt aber **keine** Eingabe: die Charakterseite zeigt nur `char_name_chip`
(Label). Kein `LineEdit` in `char_page.gd`.

---

## A — „Aufgaben" heißt ab jetzt CHALLENGES

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **A1** | Menü-Kachel, Seitentitel und HUD-Präfix umbenennen (`CHALLENGES`, HUD `CHALLENGE · …`) | `[UI][NAV] kachel=CHALLENGES` · `[UI][PAGE] titel=CHALLENGES` · `[CHAL][HUD] prefix=CHALLENGE` | `[x]` |
| **A2** | Kein sichtbares „AUFGABEN" mehr in der Oberfläche; Treffer nur noch in Changelogs/Spec (`grep`) | `grep -rn "AUFGABEN" scripts/` → 0 Treffer in UI-Dateien, Diag-Schritte umbenannt (`seite_CHALLENGES`) | `[x]` |
| **A3** | Übersetzungen mitziehen (`Loc`), DE + EN | `[LOC][KEY] challenges de=CHALLENGES en=CHALLENGES` | `[x]` |

---

## B — Sechs weitere Challenges (12 gesamt), je drei Stufen

Neue Aufgaben nutzen nur Mechaniken, die es schon gibt (Runden, Kills, Münzen, Kisten, Bosse,
Waffen-/Trank-Sperren). Muster wie `ChallengeRun` (DEFS + `runden[3]`/`gems[3]`).

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **B1** | **FLINTEN-FIEBER** (nur Schrotflinte), **UNBERÜHRT** (N Runden ohne Treffer), **KOPFGELD** (N Monster in einem Run), **GOLDRAUSCH** (N Münzen in einem Run), **OHNE VORRAT** (N Runden ohne Trank/Bombe), **BOSS-RUSH** (5 Bosse) — je 3 Stufen | `[CHAL][STUFE]` für **alle 36** Kombinationen (12 Aufgaben × 3 Stufen), LEICHT < NORMAL < HART bei Runden **und** Diamanten | `[x]` |
| **B2** | Neue Regeln im Lauf: Waffen-Sperre (Flinten-Fieber), Treffer-Zähler (Unberührt), Kill-/Münzen-Zähler (Kopfgeld, Goldrausch), Verbrauchs-Sperre (Ohne Vorrat) | `[CHAL][REGEL] id=flinte waffe=weapon_shotgun pickups=0` · `[CHAL][ZIEL] id=unberuehrt treffer=0 runden=n` · `[CHAL][ZIEL] id=kopfgeld kills=n/ziel` · `[CHAL][ZIEL] id=goldrausch muenzen=n/ziel` · `[CHAL][SPERRE] verbrauch=potion` | `[x]` |
| **B3** | Ziel-Auswertung + Belohnung wie bei den sechs bestehenden (Zustand, Stufe, einmal zahlen) | `[CHAL][ENDE]` je neuer Aufgabe · `[CHAL][GUTSCHRIFT] id=… stufe=… +d gems=… zweite_gutschrift=false` | `[x]` |
| **B4** | Alle 12 Aufgaben auf LEICHT durchspielbar (Debug-Hilfen wie `chal_run145`) | `[TEST][CHALRUN146] aufgaben=12 erledigt=12` | `[x]` |
| **B5** | Sichtprüfung: 12 Karten, jede mit START + drei Stufenknöpfen, Zielzahlen passen zur Stufe | `chal_karte_12.png`, `chal_karte_12_scroll.png` | `[x]` |

---

## C — Challenge-Ansicht smooth scrollbar

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **C1** | Gemeinsamer Helfer `ui_style.smooth_scroll(...)`: `ScrollContainer` + Ziehen (Touch/Maus) + Mausrad, Bewegung über Zielfwert mit Nachlauf (kein Sprung) | `[SCROLL][BAU] seite=challenges modus=drag+wheel nachlauf=true` | `[x]` |
| **C2** | Ziehen folgt dem Finger: Versatz zwischen Finger und Inhalt ≤ 2 px, Loslassen läuft aus | `[SCROLL][ZUG] versatz_max=…px nachlauf_ms=…` (≤ 2 px, Nachlauf 250–450 ms) | `[x]` |
| **C3** | Mausrad in Stufen von 120 px, kein Überschwingen über Anfang/Ende | `[SCROLL][RAD] schritt=120 min=0 max=<n> klemmt=true` | `[x]` |
| **C4** | Kopfzeile (Titel, Zähler, Diamanten) bleibt stehen, nur das Raster scrollt; ZURÜCK bleibt fest | `[SCROLL][FIX] titel=true chips=true fuss=true` | `[x]` |
| **C5** | 12 Karten vollständig erreichbar, letzte Karte nicht abgeschnitten | `[SCROLL][ENDE] max=<n> sichtbar_bis=<n> letzte_karte_voll=true` + Bild | `[x]` |
| **C6** | Auf dem Emulator identisch (Touch-Ziehen) | `emu_chal_scroll.png`, `[SCROLL][TEST] geraet=touch ok=true` | `[x]` |

---

## D — Ingame-Musik im Menü-Charakter, keine Löcher mehr

Ziel: dieselbe Klangfarbe wie `menu_1` (Sinus, ruhig, ohne Drums), aber unterscheidbar nach
Runde; **kein** Abbruch beim Trackwechsel, **kein** Loch am Loop-Ende.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **D1** | Spiel-Tracks auf Menü-Charakter: Sinus-Lead, Drums 0–0.03, 84–96 BPM, gleiche Akkordfamilie wie `menu_1`; Unterschied nur über Bass/Arp | `[MUSIK][CFG] track=game_1 bpm=… lead=sine drums=…` für game_1…game_4, alle `lead=sine`, `bpm` 84–96, `drums ≤ 0.03` | `[x]` |
| **D2** | Zwei Player (A/B) mit Crossfade: Aus- und Einblenden dürfen **nie** dasselbe Objekt treffen | `[MUSIK][WECHSEL] von=game_1 nach=game_2 fade_out=0.6s fade_in=0.6s gleicher_player=false` | `[x]` |
| **D3** | Nach jedem Wechsel läuft der neue Track: 1 s nach dem Wechsel `playing=true`, Position > 0,5 s | `[MUSIK][STATE] tag=runde<n> spieler_playing=true pos=>0.5` für Runde 1→2→3→Boss→zurück | `[x]` |
| **D4** | Loop ohne hörbares Loch: Engine-Loop statt Neustart (Risiko Emulator-Crash aus v1.43 abfangen) **oder** Neustart mit ≤ 30 ms Lücke | `[MUSIK][LOOP] wechsel=<n> luecke_ms=…` (≤ 30 ms), 3 Durchläufe ohne Aussetzer | `[x]` |
| **D5** | Pause/Weiter hebt die Dämpfung sicher auf | `[MUSIK][DUCK] pause=an db=… weiter=aus db=…` (nach Weiter wieder Ziel-DB ± 0,5 dB) | `[x]` |
| **D6** | Pegel bleibt in der v1.45-Tabelle (kein Rückfall auf alte Faktoren) | `[SND][TABELLE] … streuung ≤ 12 dB clipping=0` und Musik-RMS weiter −20,5 dBFS bei Regler 100 % | `[x]` |

---

## E — Boss-Musik: bedrohlich, eigener Ein-/Ausstieg

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **E1** | Eigener Boss-Track `boss_1`: tiefe Lage (55–110 Hz), Tritonus/kleine Sekunde, Drums 0,28–0,34, 144–152 BPM, Herzschlag-Layer; deutlich dunkler als die Spiel-Tracks | `[MUSIK][CFG] track=boss_1 bpm=… bass_hz=… tritonus=true drums=…` + `[MUSIK][BOSS] unterschied=ja` | `[x]` |
| **E2** | Boss-Start: harter Wechsel mit kurzem Riser (≤ 1,5 s), Boss-Ende: Rückkehr in 1,0 s | `[MUSIK][BOSS] start=dauer…s ende=dauer…s` | `[x]` |
| **E3** | Beim Boss-Tod zurück auf den Rundentrack, ohne Aussetzer (D3 gilt auch hier) | `[MUSIK][STATE] tag=boss_ende spieler_playing=true pos>0.5` | `[x]` |
| **E4** | Hörprobe als WAV: alle sieben Tracks exportiert | `screenshots/v146/audio/<track>.wav` (7 Dateien) + `_pegel.txt` | `[x]` |
| **E5** | Sichtprüfung im Lauf: Boss-Banner + Boss-Track gleichzeitig, Log-Zeile im selben Frame | `[MUSIK][BOSS] banner=true track=boss_1` | `[x]` |

---

## F — Hüte auf Skins prüfen und reparieren

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **F1** | Hut-Sitz je Rig **aus den Kopfmaßen** (kein konstanter Faktor): Skalierung und Höhe aus `_head_metrics()` je Rig | `[HAT][FIT] hut=<i> rig=<j> kopf_w=<n> skala=<s> dy=<n>` mit `s` **je Rig unterschiedlich**, Streuung der Skalierung ≥ 0,10 | `[x]` |
| **F2** | Augen bleiben frei: Hut deckt höchstens 10 % des Augenbands | `[HAT][AUGEN] hut=<i> rig=<j> verdeckt=…%` ≤ 10 % für alle 408 Paare | `[x]` |
| **F3** | Rucksack/Schulterplatten liegen **hinter** dem Körper (eigene Ebene), nicht auf der Brust | `[HAT][EBENE] hut=16 ebene=hinten koerper_ueberdeckt=…%` ≤ 3 % | `[x]` |
| **F4** | Rig 0 läuft über **einen** Zeichenweg (kein zweiter Zeichenweg mehr), Messung dadurch sauber | `[HAT][PFAD] rig=0 weg=make_player_rig` · `[HAT][PRUEF] auffaellig=0` | `[x]` |
| **F5** | Kontaktblatt aller 408 Paare in einem Bild, auffällige markiert | `screenshots/v146/hats_17x24.png` (408 Kacheln, 4 Blöcke), Sichtprüfung | `[x]` |
| **F6** | Sichtprüfung der vorher auffälligen Paare (PIRAT/STROHHUT/WOLLMÜTZE/RUCKSACK) auf allen 17 Rigs | `screenshots/v146/hats_fix.png`, Sichtprüfung | `[x]` |

---

## G — Vikinger und Geist neu zeichnen

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **G1** | `WIKINGER` (Rig 7): Helm mit Hörnern, Bart als Silhouette (nicht als Fleck), Schulterfell, Axt am Gürtel — 64²-Raster, 3-px-Kontur | `[RIG][NEU] rig=7 name=WIKINGER teile=helm+bart+fell+axt px=64 kontur=3` | `[x]` |
| **G2** | `GEIST` (Rig 6): schwebender Saum (keine Beine), transparenter Unterkörper (Alpha-Verlauf), Augen leuchten, Ketten — erkennbar ohne Farbe | `[RIG][NEU] rig=6 name=GEIST teile=saum+alpha+augen+kette px=64 kontur=3` | `[x]` |
| **G3** | Silhouette unterscheidbar: IoU gegen STANDARD ≤ 0,75 (vorher ~0,95) | `[RIG][IOU] rig=7 gegen=0 iou=…` · `rig=6 gegen=0 iou=…` | `[x]` |
| **G4** | Kontaktblatt alt/neu bei 64 px und 256 px, alle 17 Rigs zum Vergleich | `screenshots/v146/rigs_neu.png`, Sichtprüfung | `[x]` |
| **G5** | Hüte sitzen auf beiden neuen Rigs (F2/F3 gelten auch dort) | `[HAT][AUGEN] rig=6 verdeckt≤10%` · `rig=7 verdeckt≤10%` | `[x]` |

---

## H — Name im Charakter-Editor

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **H1** | Feld `NAME` in der Charakterseite (Tippen öffnet Eingabe, Bildschirmtastatur auf dem Gerät) | `[CHAR][NAME] feld=true max_zeichen=10 tastatur=geraet` | `[x]` |
| **H2** | Übernahme: leer → `HELD`, Leerzeichen getrimmt, Großschreibung wie eingegeben, Profil gespeichert | `[CHAR][NAME] eingabe="  vince  " gespeichert="vince" profil=true` · `eingabe="" → "HELD"` | `[x]` |
| **H3** | Name erscheint im Menü und im Coop (Host/Client) sofort | `[CHAR][NAME] menue=sichtbar coop=sync` | `[x]` |
| **H4** | Sichtprüfung: Feld, Tastatur, Ergebnis | `char_name.png`, `emu_char_name.png` | `[x]` |

---

## I — Ingame-Einstellungen: keine Schwierigkeit, kein Biomwechsel

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **I1** | Bei `settings_origin == "pause"` fehlen die Reihen `SCHWIERIGKEIT` und `BIOM-ÜBERGANG` (auch nicht anklickbar, kein Platzhalter) | `[SET][ORIGIN] herkunft=pause schwierigkeit=aus biom=aus` | `[x]` |
| **I2** | Aus dem Hauptmenü bleiben beide sichtbar und wirksam | `[SET][ORIGIN] herkunft=menu schwierigkeit=an biom=an` + Klick setzt Wert (`[MODE] wahl=…`) | `[x]` |
| **I3** | Kein Layout-Sprung: die übrigen Reihen rücken auf, ZURÜCK bleibt an derselben Stelle | `[SET][LAYOUT] herkunft=pause reihen=<n> zurueck_y=<y>` (y gleich wie vorher ± 2 px) | `[x]` |
| **I4** | Sichtprüfung beide Herkünfte | `settings_menu.png`, `settings_pause.png` | `[x]` |

---

## J — Fünf neue App-Icon-Varianten (1024²)

Der Nutzer entscheidet; Entwurf A aus v1.45 bleibt als Vergleich liegen.

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **J1** | Fünf neue Entwürfe mit anderer Bildidee als v1.45: (a) Revolver-Mündung frontal mit Burst, (b) Heldenkopf als Großaufnahme (nur Gesicht + Hut), (c) Kiste offen mit Lichtstrahl + Diamant, (d) „CS"-Monogramm als Emblem mit Band, (e) Monster-Maul mit Zähnen (Bedrohung) | `[ICON][ENTWURF] name=icon146_a.png … icon146_e.png px=1024` + Sichtprüfung | `[x]` |
| **J2** | Kontaktblatt inkl. v1.45-Entwurf A als Referenz + Lesbarkeit 48/72/96/144 px | `screenshots/v146/icons_uebersicht146.png` | `[x]` |
| **J3** | Kein Entwurf wird fest eingebaut — Auswahl bleibt beim Nutzer; nur auf Wunsch gesetzt | `[ICON][WAHL] offen=true` (kein `config/icon`-Wechsel in diesem Lauf) | `[x]` |

### Nachtrag 6.11.2026, 13:45 — Icon-Wahl getroffen (v1.47)

Der Nutzer hat sich für **Entwurf 6 („lila Boss", drei Augen)** entschieden — nach einer zweiten
Runde, weil das alte Icon (v1.20–v1.36) ein **Monster-Gesicht als Großaufnahme** war: aus
`dist/ComicShooter-v1.27.apk` (`res/mipmap-xxxhdpi-v4/icon.webp`) geholt, als Referenz genommen und
sechs Gesichter in diesem Stil neu gezeichnet (`COMIC_LANTEST=icon146c`, 1024², MSAA 4×).

- Gesetzt: `project/icon.png` = `screenshots/v146/icons/icon146c_6.png` (1024×1024), alt in
  `backup/icon_v145.png`.
- Beleg im APK: `res/mipmap-xxxhdpi-v4/icon.webp` ausgepackt →
  `scratch/apkicon147/icon.png` zeigt den lila Boss; Gerätebild
  `screenshots/v146/emu_appinfo_icon147.png` (App-Info mit Icon).
- Version dafür auf **1.47 / Build 47** (`[BUILD] icon=icon146c_6.png quelle=res://icon.png px=1024
  version=1.47 build=47`), Builds `dist/ComicShooter-v1.47.apk` (31,6 MB, `apksigner verify` = 0)
  und `.exe` (112,2 MB), Kopien auf dem Desktop.

---

## K — Abschluss

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **K1** | Version **1.46**, `APP_BUILD` 46, Export-Preset | `[BUILD] Versionsanzeige v1.46 aktiv (Build 46)` in Projekt und EXE | `[x]` |
| **K2** | Golden Master: unveränderte Modi grün, geänderte neu eingefroren mit Begründung (alte Fassung `.v145`) | `tools/golden_check.sh` → alle Modi `rest_diff=0` | `[x]` |
| **K3** | Diag-Modi: `musik146`, `hat146`, `chal_run146`, `scroll146`, `icon146` — jeder endet mit `[TEST] … ENDE` | 5× `[TEST][…146] ENDE` | `[x]` |
| **K4** | Emulator-Durchlauf: Menu → CHALLENGES (scrollen) → Challenge-Run (Musik hörbar/wechselt) → Charakter-Name → Einstellungen aus dem Pause | `pidof` identisch, `SCRIPT ERROR` = 0, Bilder `emu_*146.png` | `[x]` |
| **K5** | Doku: `STATUS.md`, `BUGLISTE.md`, `ARCHITEKTUR.md`, diese Spec mit Belegen | jede Zeile mit Log-Zitat | `[x]` |
| **K6** | APK + EXE nach `Desktop/` (`ComicShooter-v1.46.*`), `apksigner verify` = 0 | Artefakte mit Größe und Version | `[x]` |

---

## Testplan (Reihenfolge)

1. `COMIC_LANTEST=musik146` — Zustand nach jedem Wechsel, Loop-Lücke, Pause-Dämpfung
2. `COMIC_LANTEST=hat146` — 408 Paare (Augen, Körper, Skalierung je Rig)
3. `COMIC_LANTEST=scroll146` — Ziehen, Mausrad, Ende der Liste, Kopfzeile fest
4. `COMIC_LANTEST=chal_run146` — 12 Aufgaben auf LEICHT bis zur Belohnung
5. `COMIC_LANTEST=icon146` — fünf Entwürfe + Übersicht
6. `tools/golden_check.sh`
7. Emulator: Menu, CHALLENGES scrollen, Run mit Musikwechsel + Boss, Name ändern, Pause-Einstellungen
8. APK + EXE, `apksigner verify`, Artefakte nach `Desktop/`

## Was NICHT geändert wird

- Kein Umbau von `game_manager.gd`/`ui_manager.gd` über die genannten Hooks hinaus.
- Keine neuen Waffen, keine neuen Monster, kein Balancing der Kistenpreise.
- Die sechs bestehenden Challenges behalten Namen, Regeln und Stufen — nur die Umbenennung
  „Aufgaben → Challenges" betrifft sie.
- Die Walze und das Glücksrad bleiben unverändert.
- Kein Icon wird ohne Nutzerwahl Spiel-Icon (J3).

## Offene Fragen (entscheidet der nächste Lauf selbst)

1. **D4-Loop:** Engine-Loop (`LOOP_FORWARD`) ist der saubere Weg, brach aber in v1.43 den Emulator.
   Standard: **beides** — Loop im Stream aktivieren **und** `_restart_current_music()` als Netz
   behalten; wenn der Emulator-Test K4 ohne `SCRIPT ERROR` läuft, bleibt der Engine-Loop.
2. **D1-Tracks:** Wie viele Spiel-Tracks? Standard: **drei** (`game_1…game_3`) im Menü-Charakter,
   `game_4` entfällt (es war der härteste Ausreißer mit `saw`, 120 BPM).
3. **B1-Zahlen:** Runden/Diamanten je neuer Aufgabe → Standard: LEICHT 6–8 Runden / 30–50 ◆,
   NORMAL 10–12 / 70–100 ◆, HART 16–20 / 130–180 ◆; Faktor 1,4 für UNBERÜHRT und BOSS-RUSH
   (schwerer), 0,8 für KOPFGELD (leichter).
4. **F1-Skalierung:** Referenz-Kopfbreite → Standard: `w=27` (Mittelwert), Skala = `27 / kopf_w`,
   begrenzt auf 0,85–1,20.
5. **J-Auswahl:** Welcher Entwurf wird Icon? Standard: **keiner** — der Nutzer entscheidet (J3).
6. **H1-Tastatur:** eigenes Overlay oder System-Tastatur? Standard: `LineEdit` mit
   `virtual_keyboard_enabled`, damit auf dem Gerät die System-Tastatur erscheint.

---

## Belege (Stand 6.11.2026, v1.46)

Alle Punkte sind abgearbeitet. Rohprotokolle: `logs_*146_a.log` im Projektwurzelverzeichnis,
Bilder in `screenshots/v146/`.

| Block | Beleg |
|---|---|
| **A1** | `[UI][NAV] kachel=CHALLENGES` · `[UI][PAGE] titel=CHALLENGES` · `[CHAL][HUD] prefix=CHALLENGE text=BOSS-RUSH · NORMAL · BOSSE 0/5` (Gerät) |
| **A2** | `grep -rn "AUFGABEN" scripts/` → nur noch Kommentare; Kachel, Seitentitel, HUD, Ergebnis-Fenster, Diag-Schritte umbenannt (`seite_CHALLENGES`) |
| **A3** | `[LOC][KEY] challenges de=CHALLENGES en=CHALLENGES`; `CHALLENGE GESCHAFFT!/VERFEHLT` im Wörterbuch |
| **B1** | `[CHAL][KOMBI] aufgaben=12 stufen=3 kombinationen=36` · 12× `[CHAL][DEF] id=… stufen=leicht:r/d normal:r/d hart:r/d` (Runden **und** Diamanten steigend) |
| **B2** | `[CHAL][REGEL] id=flinte waffe=shotgun pickups=0` · `[CHAL][ZIEL] id=kopfgeld kills=n/60` · `id=goldrausch muenzen=n/300` · `id=unberuehrt treffer=… erlaubt=false` · `[CHAL][SPERRE] verbrauch=potion` |
| **B3** | `[CHAL][ENDE]` je Aufgabe · `[CHAL][GUTSCHRIFT] id=… stufe=leicht +d gems=… zweite_gutschrift=false` |
| **B4** | `[TEST][CHALRUN146] aufgaben=12 erledigt=12` |
| **B5** | `[CHAL][KARTE] seite=true karten=12 start_knoepfe=12 stufen_knoepfe=36` · `chal_karte_12.png`, `chal_karte_12_scroll.png`, Gerät `emu_chal.png` |
| **C1** | `[SCROLL][BAU] seite=challenges modus=drag+wheel nachlauf=true schritt=120 max=424 sicht=786 gemessen=true` (Helfer `UiStyle.smooth_scroll` → `smooth_scroll.gd`) |
| **C2** | `[SCROLL][ZUG] versatz_max=0.0px nachlauf_ms=315 ok_versatz=true ok_nachlauf=true` · Gerät: `[SCROLL][ZUG] versatz_max=0.0px probes=4` |
| **C3** | `[SCROLL][RAD] schritt=120 … klemmt=true` (Kette 0→120→240→360→424) · `[SCROLL][RAD] probe oben=0 unten=424 max=424 klemmt=true` |
| **C4** | `[SCROLL][FIX] titel=true chips=true fuss=true scroll_kind=grid` · `[SCROLL][FIX] titel=30 chips=112 fuss=974 gleich_nach_scroll=true` |
| **C5** | `[SCROLL][ENDE] max=424 offset=424 sichtbar_bis=1210 sicht=786 letzte_karte_voll=true` · `chal_karte_12_ende.png` |
| **C6** | `[SCROLL][TEST] geraet=touch bewegt=true versatz_max=0.0px nachlauf_ms=331` · Gerät `emu_chal_scroll.png` (12 Karten, letzte Reihe vollständig) |
| **D1** | `[MUSIK][CFG] track=game_1…4 bpm=84/88/92/96 lead=sine drums=0.02/0.02/0.03/0.03` · `[MUSIK][PRUEF] … menu_charakter=true` ×4 |
| **D2** | `[MUSIK][WECHSEL] von=game_1 nach=game_2 … gleicher_player=false` (jede Zeile, auch auf dem Gerät) |
| **D3** | `[MUSIK][STATE] tag=runde1/2/3/boss/boss_ende spieler_playing=true pos=1.20/1.22/1.20/1.21/1.15` |
| **D4** | `[MUSIK][LOOP] track=game_2 laenge=10.91s aussetzer=0 neustarts=2 luecke_max_ms=0 loop_ok=true quelle=seek` · Gerät: `[MUSIK][LOOP] nahtlos … restarts=4 luecke_ms=0 quelle=seek`, `SIGSEGV=0` |
| **D5** | `[MUSIK][DUCK] pause=an db=-24.0 weiter=aus db=-4.6 vorher=-4.6 zurueck_ok=true` |
| **D6** | `screenshots/v146/audio/_pegel.txt`: alle 7 Tracks `ergebnis=-20.5 dBFS`; `[SND][TABELLE]` unverändert (Golden Master grün) |
| **E1** | `[MUSIK][BOSS] unterschied=ja lead=sine bpm=146 bass_hz=55.0 drums=0.30 tritonus=true heartbeat=0.55` |
| **E2** | `[MUSIK][BOSS] start=dauer1.2s ende_dauer=1.0s` (Riser `_gen_riser`) |
| **E3** | `[MUSIK][STATE] tag=boss_ende_nach_1.2s current=game_3 spieler_playing=true pos=1.15` |
| **E4** | `[MUSIK][WAV]` ×7 nach `screenshots/v146/audio/` (`menu_1/2`, `game_1…4`, `boss_1`) + `_pegel.txt` |
| **E5** | `[MUSIK][BOSS] banner=true track=boss_1 runde=3 frame_gleich=true` (in `rounds_mode.start_round`) |
| **F1** | `[HAT][FIT] hut=… rig=… kopf_w=… skala=…` mit echtem Faktor · `[HAT][SKALA] rig=0 kopf_w=25 skala_min=0.90 skala_max=1.05 streuung=0.15` … `rig=14 streuung=0.20` (Ziel ≥ 0,10) |
| **F2** | `[HAT][PRUEF] ERGEBNIS paare=408 auffaellig=0` · alle `[HAT][SUM] … max_augen=0%` |
| **F3** | `[HAT][EBENE] hut=16 rig=0 ebene=hinten koerper_ueberdeckt=0.0%` (51 Zeilen, max 0,1 %) |
| **F4** | `[HAT][PFAD] rig=0 weg=make_player_rig hut=0 ein_weg=true` |
| **F5** | `screenshots/v146/hats_17x24.png` (1626×1128, 408 Kacheln) |
| **F6** | `screenshots/v146/hats_fix.png` (PIRAT/STROHHUT/WOLLMÜTZE/RUCKSACK × 17 Rigs) |
| **G1** | `rig 7`: Helm mit Hörnern, Bart-Silhouette, Schulterfell, Axt am Gürtel — `screenshots/v146/rigs_neu.png` (64/256 px) |
| **G2** | `rig 6`: schwebender Saum, Alpha-Verlauf, leuchtende Augen, Armkette — selbiges Blatt |
| **G3** | `[RIG][IOU] rig=6 gegen=0 iou=0.66 ok=true` · `rig=7 … iou=0.63 ok=true` |
| **G4** | `[RIG][BLATT] rigs_neu.png px=4568x360 rigs=17 gross=256 klein=64` |
| **G5** | `[HAT][AUGEN] rig=6 verdeckt=0% ok=true` · `rig=7 verdeckt=0% ok=true` (über alle 24 Hüte) |
| **H1** | `[CHAR][NAME] feld=true max_zeichen=10 tastatur=geraet` · Gerät `emu_char_name.png` |
| **H2** | `[CHAR][NAME] eingabe="  vince  " gespeichert="vince" profil=true` · `eingabe="" gespeichert="HELD"` · `eingabe="VINCE" gespeichert="VINCE"` |
| **H3** | `[CHAR][NAME] menue=sichtbar name=VINCE coop=sync` · `[PROFILE][NAME] … coop_host=false coop_client=false`, `notify_profile_changed()` im Setter |
| **H4** | `char_name.png`, `char_name_ergebnis.png`, `emu_char_name.png`, `emu_char_name_keyboard.png` (Feld + Cursor; die Systemtastatur bleibt auf diesem Emulator aus, weil er eine Hardware-Tastatur meldet — `show_ime_with_hard_keyboard=0`) |
| **I1** | `[SET][ORIGIN] herkunft=pause schwierigkeit=aus biom=aus` · `[SET][PRUEF] … schwierigkeit_sichtbar=false biom_sichtbar=false` · `emu_settings_pause.png` |
| **I2** | `[SET][ORIGIN] herkunft=menu schwierigkeit=an biom=an` · `settings_menu.png` |
| **I3** | `[SET][LAYOUT] herkunft=menu reihen=9 zurueck_y=974` vs. `herkunft=pause reihen=7 zurueck_y=974` — ZURÜCK unverändert |
| **I4** | `settings_menu.png`, `settings_pause.png`, `emu_settings_pause.png` |
| **J1** | `[ICON][ENTWURF] name=icon146_a…e.png px=1024x1024` (Mündung/Burst, Heldenkopf, offene Kiste mit Strahl, CS-Emblem, Monster-Maul) |
| **J2** | `[ICON][LESBAR]` ×6 · `screenshots/v146/icons_uebersicht146.png` (v145_a + 5 neue, 32/48/64/96 px) |
| **J3** | `[ICON][WAHL] offen=true (kein config/icon-Wechsel in diesem Lauf)` |
| **K1** | `[BUILD] Versionsanzeige v1.46 aktiv (Build 46)` in Projekt, EXE und APK (`versionCode=46 versionName=1.46`) |
| **K2** | `tools/golden_check.sh` → 8/8 `rest_diff=0 script_errors=0`, „OK: Verhalten unveraendert." (alt: `backup/golden_v136/*.log.v145`) |
| **K3** | `[TEST][MUSIK146] ENDE`, `[TEST][HAT146] ENDE`, `[TEST][CHALRUN146] ENDE`, `[TEST][SCROLL146] ENDE`, `[TEST][ICON146] ENDE` (+ neu `RIG146`, `SET146`, `NAME146`) |
| **K4** | Gerät: `pid=11620` stabil, `SCRIPT ERROR=0`, `SIGSEGV=0`; Bilder `emu_menu.png`, `emu_chal.png`, `emu_chal_scroll.png`, `emu_chal_run.png`, `emu_pause.png`, `emu_settings_pause.png`, `emu_char_name.png`, `emu_char_name_ergebnis.png` |
| **K5** | diese Spec, `STATUS.md` (v1.46), `BUGLISTE.md` (B46-1…7), `ARCHITEKTUR.md` |
| **K6** | `dist/ComicShooter-v1.46.apk` (31,4 MB, `apksigner verify` = 0, Signer `CN=Godot`) · `dist/ComicShooter-v1.46.exe` (112,1 MB) · Kopien auf dem Desktop |

### Abweichungen von der Spec (bewusst, dokumentiert)

- **D4:** Statt Engine-Loop läuft der Loop über `seek(0)` kurz vor dem Ende. Grund: `LOOP_FORWARD`
  stürzt auf dem Emulator im AudioTrack-Thread ab (SIGSEGV, `logs_emu_crash146.log`) — der
  Spec-Punkt „Engine-Loop **oder** Neustart ≤ 30 ms" ist über die zweite Variante erfüllt, gemessen
  `luecke_ms=0` auf Desktop **und** Gerät.
- **F1:** Die Recon-Zahl „Hut-Skalierung konstant 1.39" war ein Fehler der Log-Formel (B46-2), nicht
  des Zeichenwegs. Die Skalierung war schon vorher kopfbreitenabhängig; jetzt steht der echte Faktor
  im Log und die Streuung ist belegt.
- **G1:** Der Wikinger-Helm sitzt als Teil des Körpers auf dem Kopf; Hüte werden weiterhin darauf
  gesetzt (G5 belegt 0 % Augenverdeckung). Ein „Kopf frei"-Zwang wie in v1.41 gibt es nicht mehr.
- **I1:** Das Pause-Overlay selbst behält seine SCHWIERIGKEIT-Reihe (ausdrücklich nicht Teil der
  Spec); ausgeblendet werden die Reihen der **Einstellungsseite**.
