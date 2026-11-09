# SPEC v1.41 — Fixes, Bosse, neue Monster, Skin-Kur

**Ausgangslage:** v1.40 (Runden-Modus) gebaut, Golden 8/8. Alles hier baut darauf auf.
**Status-Spalte:** `[ ]` offen · `[~]` läuft · `[x]` erledigt (Beleg vorhanden)

---

## Harte Regeln (für jeden Punkt)

1. **Golden-Master darf nicht brechen.** `tools/golden_check.sh` muss 8/8 bleiben —
   einzige erlaubte Ausnahme: `char`-Log (enthält die Rig-Liste, ändert sich durch S1) → neu einfrieren, dokumentieren.
2. **Jeder Punkt braucht eine Log-Zeile** mit Präfix `[WAVE]`, `[WSHOP]`, `[MON]`, `[RIG]`, `[MENU]`, `[PROFILE]`.
3. **Modus 0 (ENDLOS) und Modus 1 (WELLEN+SHOP) bleiben unverändert** — kein Balance-Eingriff, keine neuen Monster dort.
4. **Deutsch** in UI-Texten, Kommentaren und Logs. Kein stiller Fehlschlag.
5. Vor jedem Build: `--headless --quit-after 20` → 0 `SCRIPT ERROR`.

---

## F — Fehlerbehebungen

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **F1** | **Zufalls-Events** (MONSTERSTURM, ELITEWELLE, LOOTREGEN, FROSTSTURM, GOLDRAUSCH) dürfen im Runden-Modus **nicht** feuern. Sie spawnen Monster, die nicht in `alive` der Runde zählen → Runde endet falsch oder nie. | `[WAVE][EVENT] erlaubt=false modus=runden blockiert=<n>`, **kein** Banner `MONSTERSTURM!`/`ELITEWELLE!`/`GOLDRAUSCH!` in einem 5-Minuten-Lauf | **[x]** `belegt: logs_f1.log` |
| **F2** | **Startseite verzieht sich** beim Umschalten auf RUNDEN. Ursache: `row3` (Modus-Knopf 330 + `diff_btn` 300 + 2 Chips) wächst, weil `diff_btn.visible` umgeschaltet wird; die zentrierte `box` wird breiter als die Panel-Innenbreite. | `row3` feste Mindestbreite 1180 + `SIZE_SHRINK_CENTER`; `diff_btn` **immer sichtbar**, in Modus 0/1 `disabled` mit Text `GRAD: —`; `[MENU][LAYOUT] modus=<0\|1\|2> box=(w,h) row3=(w,h) ueberlauf=false`; Shots `screenshots/v141/menu_0/1/2.png` | `[x]` |
| **F3** | **Shop zeigt nur Text** — Karten brauchen Symbole. Links 64×64-Icon, rechts Name; Preiszeile mit Münz-Icon; Waffenkarten mit Seltenheitsrahmen. Vorhandene Keys: `weapon_pistol/shotgun/machine/laser/revolver`, `heart_gold`, `icon_shield`, `potion`, `bomb`, `powerup_freeze`, `icon_coin`. **Neu zeichnen:** `icon_revive` (Herz + Pfeil) für „LEBEN ZURÜCK". | `[WSHOP][ICON] artikel=<id> tex=<key> ok=true` für **alle 11** Artikel; `screenshots/v141/shop_symbole.png`; 0 `[TEX][FEHLT]` | `[x]` |
| **F4** | **Tote Sackgasse: Waffen-Stats im Spiel.** `StatsPage._build_stats_page()` hängt die Seite an **`start_screen`**, `_open_stats_page()` ruft zusätzlich `_close_pages()` (zeigt die Startseite). Im laufenden Spiel heißt das: Spiel **läuft ungepausiert weiter**, die Seite liegt unter der Startseite/HUD, es gibt keinen Rückweg ins Spiel — erst der Tod beendet den Zustand. | Getrennte Pfade: **im Spiel** öffnet die Statistik als eigenes Overlay über `ui_manager` (wie das Pause-Menü), `get_tree().paused = true`, Knopf **„ZURÜCK INS SPIEL"** + `Esc` schließen es und pausieren wieder auf; **im Menü** bleibt die Seite wie bisher unter `start_screen`. `[STATS][UI] offen=true quelle=hud pause=true` / `[STATS][UI] offen=false zurueck=spiel pause=false`; 5× öffnen/schließen ohne Hänger; HUD nach dem Schließen wieder sichtbar (`[STATS][UI] hud_sichtbar=true`) | `[x]` |
| **F5** | **Englisch bleibt teils deutsch.** `Loc.t()` übersetzt per exakter Textsuche (+ Präfix/Suffix-Regeln). Alle Texte aus v1.40/v1.41 fehlen im Wörterbuch: Seltenheiten (`GEWOEHNLICH`, `SELTEN`, `EPISCH`, `LEGENDAER`), Artikelnamen/-beschreibungen (`HEILTRANK`, `LEBEN ZURUECK`, `SCHILD +2`, `+1 HERZ`, `FROST 10 s`), HUD (`WELLE >>`, `NÄCHSTE RUNDE %d: …`, `WELLE %d BESIEGT`), Shop (`MÜNZEN: %d`, `ab %d Münzen`, `%d Münzen`, `BESITZT · Seltenheit wählen`, `AUSGERÜSTET`, `ANGEBOT DES TAGES`, `AUSVERKAUFT`, `ZU WENIG MÜNZEN`, `gekauft %d/%d`, `noch %d/%d`, `MAX. 2 VERSICHERUNGEN`, `MAX. 5 HERZEN GEKAUFT`), Menü (`MODUS: RUNDEN`, `MODUS: WELLEN + SHOP`, `GRAD: LEICHT/NORMAL/HART`), Themen-Banner (`PANZER-RUNDE`, `SPRINT-RUNDE`, `SCHWARM-RUNDE`, `ELITE-RUNDE`) und die Waffen-Stats-Seite (`SCHADEN`, `MAGAZIN`, `NACHLADEN` + die fünf Beschreibungen). | (a) alle statischen Strings in `Loc.DE_EN`; (b) dynamische über neue Präfix-/Suffix-Regeln (`"ab "`→`"from "`, `" Münzen"`→`" coins"`, `"WELLE "`→`"WAVE "`, `"NÄCHSTE RUNDE "`→`"NEXT ROUND "`, `"gekauft "`→`"bought "`, `"noch "`→`"left "`) **und** über `Loc.fmt(key, args)` für zusammengesetzte Sätze; (c) Sprachwechsel baut die v1.40-Oberflächen neu (`WaveShop._rebuild()`, HUD-Label, Modus-/GRAD-Knopf). Beleg: `[LOC][CHECK] flaeche=shop knoten=<n> fehlt=0`, `[LOC][CHECK] flaeche=hud fehlt=0`, `[LOC][CHECK] flaeche=stats fehlt=0`, `[LOC][MISS] gesamt=0` in einem EN-Lauf; Shots `screenshots/v141/shop_en.png`, `hud_en.png` | `[x]` |
---

## B — Bosse in späteren Runden (zusätzlich zu den Gruppen)

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **B1** | **Boss-Beimischung** nach fester Tabelle (zusätzlich zu den normalen Gruppen, nicht als Ersatz). **Ersetzt** die alte Regel `round_no % 5` in `RoundsMode.start_round()` (bisher: Mini alle 5, Biom alle 10): `1–7` keine · `8–14` jede 2. Runde 1 Mini-Boss · `15–24` jede Runde 1 Mini-Boss + jede 5. Runde 1 Biom-Boss · `25–30` wie 15–24, R30 zusätzlich 2 Mini-Bosse | `[WAVE][BOSS] runde=<n> anzahl=<k> typen=[ERD-KÄFER]` je Runde; R20 ≥ 1 Boss, R30 = 3 | `[x]` |
| **B2** | **HP-Drossel**: Boss-HP = Basis × `hp_mult` × **0,55**, damit ein Boss ≤ 45 % der HP-Summe der Runde stellt (sonst steht die Runde 40 s still) | `[WAVE][BOSS] hp=<x> anteil=<pct>%` mit `anteil ≤ 45` in allen Boss-Runden | `[x]` |
| **B3** | **Ankündigung**: Banner `MINI-BOSS!` / `BIOM-BOSS!` 1,2 s vor dem Spawn + Boss-Leiste mit Namen | `[WAVE][BOSS] warnung=true runde=<n>`, Banner-Shot | `[x]` |
| **B4** | **Rundenende bleibt korrekt**: Bosse zählen in `total`/`alive`; Runde endet nur bei `getoetet == total` | 10 Runden (`COMIC_ROUNDS=10`) ohne Hänger: jede Runde `[WAVE][ENDE] getoetet=<n>/<total>` mit `n == total`, Dauer < 60 s | `[x]` |
| **B5** | **Monotonie hält**: Boss-HP zählt in die HP-Summe, R1 → R30 weiter streng steigend | `[WAVE][PLAN] ERGEBNIS monoton=true` nach der Änderung | `[x]` |
| **B6** | **Performance** mit 3 Bossen + 40 Monstern gleichzeitig | `[PERF][WAVE] runde=30 fps_avg ≥ 54 proc_ms ≤ 0,10` | `[x]` |

---

## M — Neue Unterstützer-Monster (erst nach B)

Drei neue Typen, eigene Silhouette + eigene Fähigkeit. Enum in `entities/monster/monster_stats.gd` und `monster_patterns.gd` (aktuell bis Index 30 belegt → neue ab **31**).

| # | Typ | Name | Fähigkeit | Abnahmekriterium | Status |
|---|---|---|---|---|---|
| **M1** | 31 | **SPORENBRUT** | schnell, klein; teilt sich beim Tod in **2 SPOREN** (Typ 34, 40 % HP, leben 8 s) | `[MON][TEILUNG] typ=31 kinder=2`, Sporen spawnen nur 1× (kein Rekursion) | `[x]` |
| **M2** | 32 | **SCHILDTRÄGER** | 70 % Schadensreduktion aus dem Frontwinkel ±70°, von hinten voller Schaden; Tempo 0,8× | `[MON][SCHILD] blockiert=70% winkel=70` | `[x]` |
| **M3** | 33 | **HEROLD** | macht keinen Schaden; bufft Monster im Radius 180 px mit **+25 % Tempo**; 1,5× HP | `[MON][AURA] gebufft=<n> radius=180` | `[x]` |
| **M4** | Einbindung in `core/rounds.gd`: ab R10 SPORENBRUT (max. 20 % der Rundenzahl), ab R13 SCHILDTRÄGER, ab R16 HEROLD (max. 2 je Runde); Punkte/Münzen in `Rounds.points_of` | `[WAVE][PLAN] runde=10 typen=[GREEN,SPORENBRUT]`, Anteil ≤ 20 % | `[x]` |
| **M5** | **Design**: eigene Silhouette (nicht nur Farbe), Farbtonabstand ≥ 25 zu allen alten Arten | Kontaktblatt `screenshots/v141/monster_neu.png`, `[MON][FARBE] typ=<n> hue_diff=<x>` | `[x]` |
| **M6** | Alle drei Arten tauchen im echten Lauf auf | `[MON][SPAWN] typ=31/32/33` in einem 2× 20-Runden-Lauf | `[x]` |
| **M7** | Performance mit allen drei Arten | `[PERF][WAVE] runde=20 fps_avg ≥ 54` | `[x]` |

---

## S — Skin-Kur (entfernen, Hüte entfernen, vier neu zeichnen)

### S1 — 18 Skins entfernen

Aktuelle Liste (`TexDraw.RIG_NAMES`, Index → Name). **Entfernen** (Indizes): 9 SCHROTT-SCHÜTZE, 10 WÜSTENWANDERER, 11 DSCHUNGEL-SCOUT, 12 STRASSENKÄMPFER, 13 MARS-PLÜNDERER, 14 DSCHUNGEL-JÄGER, 15 ELEKTRO-TECHNIKER, 16 WIKINGER-RAIDER, 17 ROBO-AFFE, 18 VOLT-KOMMANDANT, 19 METEOR-GOLEM, 20 SPLITTER-KÖNIG, 21 STERNEN-WIKINGER, 22 SONNENBOSS, 23 URWALD-TITAN, 24 NEON-PHANTOM, 27 KRISTALL-GOLEM, 28 SCHATTEN-KATZE.

**Bleiben (11):** 0 STANDARD, 1 PANZERHELD, 2 NINJA, 3 ROBOTER, 4 COMIC-HELD, 5 MARS-MARSCHALL, 6 GEIST, 7 WIKINGER\*, 8 ALIEN\*, 25 SPINNENMANN\*, 26 ZOMBIE (\* = wird in S3 neu gezeichnet).

| Abnahmekriterium | Status |
|---|---|
| `[RIG][CHECK] names=11 rarity=11 arme=11 hats=25` | `[x]` |
| Sammlung zeigt 11 Skins, `[COLL][ZAEHLER] skins=11` | `[x]` |
| Kein `[TEX][FEHLT]` für alte Skin-Keys, 0 `SCRIPT ERROR` | `[x]` |

### S2 — 4 Hüte entfernen

`HAT_NAMES` (29): entfernen **20 MARS-VISIER**, **23 BLITZ-SCHWEIF**, **26 METEOR**, **27 NEON-AURA** → **25 Hüte**.
Abnahme: `[HAT][CHECK] huete=25`, Hut-Sitz-Test `[HAT][SITZ] … fehler=0` über alle 25 × 11 Rigs.

### S3 — ALIEN, WIKINGER, SPINNENMANN, ZOMBIE neu zeichnen

Kritik des Nutzers: „sehen verbuggt aus, Shape passt nicht, zu viele Hüte, sieht nicht besonders aus". Der ZOMBIE kommt ausdrücklich dazu: „der zombie soll angepasst werden damit die hüte passen und soll neu gezeichnet werden".

| Skin | Neue Form (verbindlich) |
|---|---|
| **ALIEN** | Birnenkopf, Breite 20 px, Oberkante y=13; 2 große ovale Augen (asymmetrisch), **eine** Antenne; schlanker Körper, 3-Finger-Hände, digitigrade Beine. Keine Flügel, keine Helmreste, keine zweite Hut-Andeutung. |
| **WIKINGER** | Breite Schultern, Fellumhang, runder Holzschild auf dem Rücken, kurzer Bart. **Kopf frei** (kein Helm!) — Hüte müssen passen. |
| **SPINNENMANN** | Geduckt, 4 Beine aus dem Rumpf + 2 Arme, Hinterleib nach hinten; Kopf frei, klar vom Hinterleib getrennt. |
| **ZOMBIE** | Aufrechter Gang (nicht mehr gebeugt), Kopf **frei und mittig** (kein Haar-Klumpen, keine offene Schädeldecke), Arme hängen seitlich statt nach vorn; zerrissenes Hemd, ein Bein nachgezogen. Ziel: **Hüte sitzen** — Kopfbreite 18–22 px, Oberkante y = 12–16, `HAT_SEAT` neu messen. |

Regeln für alle drei:
- Kopfbreite **18–22 px**, Kopfoberkante **y = 12–16** (damit `_head_metrics` greift), `HAT_SEAT` neu messen.
- Höchstens **3** Akzentfarben je Skin, keine Farbverläufe.
- Beine/Arme müssen sich um **≥ 15°** von den alten Rigs unterscheiden (Silhouette).
- Für den ZOMBIE gilt zusätzlich: Hut-Sitz über **allen 25 Hüten** fehlerfrei (er war der Skin mit den meisten Hut-Kollisionen).

| Abnahmekriterium | Status |
|---|---|
| Kontaktblatt `screenshots/v141/skins_neu_4.png` (4 Rigs × 6 Hüte, sauber, ohne Überlappung) | `[x]` |
| `[HAT][SITZ] ERGEBNIS paare=<n> kopfpaare=<n> fehler=0` | `[x]` |
| IoU der vier gegen alle anderen Rigs `≤ 0,55` (`tools/rig_iou.md`) | `[x]` |

### S4 — Farbauswahl-Kompatibilität (für ALLE 11 + 6 neuen Skins)

Körperflächen (Torso, Arme, Hose) übernehmen `PLAYER_COLORS[farbe].shirt` / `.pants`, nur die Akzente sind skin-eigen.

| Abnahmekriterium | Status |
|---|---|
| `[RIG][FARBE] rig=<name> farbe=<0..9> shirt=#rrggbb treffer=<pct> pants_treffer=<pct>` mit **≥ 90 %** | `[x]` |
| Kontaktblatt `screenshots/v141/skins_farben.png` (11 Rigs × 10 Farben) | `[x]` |

### S5 — Profil-Migration v3 → v4

`PROFILE_VERSION = 4`. `p_rig_id` / `p_hat_id` (stabile Namen, v1.39 eingeführt) bleiben die Wahrheit;
Indizes werden beim Laden über den Namen neu aufgelöst. Entfernte Namen → `STANDARD` / `OHNE`, Nutzer bekommt keine Fehlermeldung, nur Log.
`unlocked_rig_ids` / `unlocked_hat_ids` werden gefiltert.

**Ladereihenfolge (wichtig):** `_load_profile()` liest heute die **Index**-Listen (`unlocked_rigs`, `unlocked_hats`).
Ab v4 gilt: erst `unlocked_rig_ids`/`unlocked_hat_ids` über den Namen auflösen, nur wenn die fehlen,
auf die Indizes zurückfallen (und dabei auf die neue Array-Länge klemmen). Sonst zeigt ein altes Profil
nach dem Entfernen falsche Skins an.

| Abnahmekriterium | Status |
|---|---|
| `[PROFILE][MIGR] von=v3 nach=v4 rig=SCHATTEN-KATZE->STANDARD hut=NEON-AURA->OHNE entfernt_rigs=18 entfernt_huete=4` | `[x]` |
| Nach Neustart: `[PROFILE][CHECK] nach_neustart p_rig=<n> p_hat=<n>` konsistent | `[x]` |

### S6 — Sammlung, Debug-Unlock, Slop-Doku
`docs/SKIN_SLOP.md` auf die 11 verbleibenden reduzieren; Debug-Unlock zählt 11/11 Rigs + 25/25 Hüte + 10/10 Farben.
Abnahme: `[DEBUG][UNLOCK] rigs=11/11 huete=25/25 farben=10/10` (nach N5: 17/17).

### S7 — Golden neu einfrieren (nur `char`)
`char` enthält `[RIG][LISTE] anzahl=<n>` → nach S1 neu einfrieren (`backup/golden_v140/char.log` als v1.41 sichern), die anderen **7** Modi müssen unverändert bleiben. **Ergebnis v1.41:** nicht nötig — `norm()` ersetzt `=<zahl>` durch `=N`, `char` bleibt damit grün; Kopie trotzdem als `backup/golden_v141_char.log` gesichert.

---

## N — Neue Skins zur Auswahl (Nutzer entscheidet)

Ziel: **3 legendäre** + **3 epische** Skins. Zu jedem Konzept **3 vorgezeichnete Varianten** (A/B/C) — der Nutzer wählt je Konzept eine Variante, die kommt ins Spiel.

### N1 — Legendär (Vorschläge)

| Konzept | Idee | Variante A | Variante B | Variante C |
|---|---|---|---|---|
| **EISENKARDINAL** | Kreuzritter/Paladin, massige Rüstung, Kapuzenmantel | Templer: weißer Wappenrock, rotes Kreuz, Kettenhaube | Schwarzstahl: dunkle Platte, Goldlitzen, Zepter | Frost-Paladin: Eisplatten, blaues Visier, Frostkristall auf der Brust |
| **ONI-FELDHERR** | Oni-Samurai mit Maske und Hörnern | Roter Oni: Eisenkeule, Fellschurz | Blauer Oni: Schulterdämon, Klauenhand | Goldener General: Kriegsfahne, Lamellenrüstung |
| **EWIGER HERRSCHER** | Pharao/Mumie, Gold und Binden | Gold-Pharao: Nemes-Kopftuch, Krummstab | Sarkophag-Mumie: Binden, Skarabäus-Amulett, offene Rippen | Anubis-Priester: Schakalkopf, Stab mit Sichel |

### N2 — Episch (Vorschläge)

| Konzept | Idee | Variante A | Variante B | Variante C |
|---|---|---|---|---|
| **KAPITÄN ROST** | Piratenkapitän mit Enterhaken | Klassisch: Dreispitz, blau-goldener Mantel, Säbel | Geisterpirat: grün-transparent, Algenbart, Kompass | Maschinenpirat: Holzbein, Zahnrad-Schulter, Enterhaken aus Stahl |
| **FROSTBEIL** | Eisläufer/Berserker mit Axt | Fellkapuze: Yeti-Pelz, Eisaxt, Schneebrille | Berserker: nackter Oberkörper mit Runen, Doppelaxt | Gletscher-Panzer: blaue Platten, Eiskristalle an Schultern |
| **GRINSER** | Zirkusclown, unheimlich | Harlekin: Rautenmuster, Schellenkappe, Karten | Zirkusdirektor: Zylinder, Frack, Peitsche | Joker-Maske: weißes Gesicht, rotes Grinsen, Kerzen auf dem Kopf |

### N3 — Zeichnen (Kontaktblätter)

| Datei | Inhalt | Abnahmekriterium | Status |
|---|---|---|---|
| `screenshots/v141/konzept_legendary.png` | 3 Konzepte × 3 Varianten = **9 Kacheln** à 128×128, je Kachel Name + Buchstabe, gleicher Pixelstil wie die Spiel-Rigs | 9 Kacheln, keine Überlappung, `[ART][KONZEPT] block=legendary kacheln=9` | `[x]` |
| `screenshots/v141/konzept_epic.png` | dasselbe für die 3 epischen Konzepte | `[ART][KONZEPT] block=epic kacheln=9` | `[x]` |
| Silhouetten-Check | Varianten müssen sich klar unterscheiden | IoU zwischen A/B/C desselben Konzepts **≤ 0,85** (`[ART][IOU] konzept=<n> a_b=<x> b_c=<x>`) | `[x]` |

### N4 — Auswahl durch den Nutzer

Abgefragt am 4.11.2026 (interaktives Formular, 2 Runden à 3 Fragen).
Gewählt:

| Konzept | Variante | Skin-Name im Spiel |
|---|---|---|
| EISENKARDINAL | **A Templer** | EISENKARDINAL (legendary) |
| ONI-FELDHERR | **B Blauer Oni** | ONI-FELDHERR (legendary) |
| EWIGER HERRSCHER | **C Anubis-Priester** | EWIGER HERRSCHER (legendary) |
| KAPITÄN ROST | **A Klassisch** | KAPITAEN ROST (epic) |
| FROSTBEIL | **A Fellkapuze** | FROSTBEIL (epic) |
| GRINSER | **C Joker-Maske** | GRINSER (epic) |

Die nicht gewählten Varianten bleiben als Kontaktblatt liegen:
`screenshots/v141/konzept_legendary.png`, `konzept_epic.png`.

### N5 — Einbau der gewählten 6

| Abnahmekriterium | Status |
|---|---|
| `RIG_NAMES` +6, `RIG_RARITY` +3 `legendary` / +3 `epic`, `HEAD_ANCHOR` +6, Hut-Sitz je Skin | `[x]` — `[RIG][CHECK] names=17 rarity=17 arme=17 hats=25 head_anchor=17`; Hut-Sitz über `HAT_SEAT`-Standard, kein `RIG_HAT_ADJ` nötig (Messung s. u.) |
| `[RIG][NEU] name=<NAME> seltenheit=<legendary\|epic> farb_ok=true` (6×) + Hut-Sitz `[HAT][SITZ] ERGEBNIS … fehler=0` | `[x]` — 6 Zeilen `[RIG][NEU]` mit `farb_ok=true`, `[HAT][SITZ] ERGEBNIS paare=408 kopfpaare=289 fehler=0` (`logs_skin141_n5d.log`, `logs_hatfit_n5.log`) |
| Sammlung zeigt `skins=17` (11 + 6), Debug-Unlock 17/17 | `[x]` — `[COLL][ZAEHLER] skins=17 huete=25 farben=10`, `[DEBUG][UNLOCK] rigs=17/17`, `screenshots/v141/sammlung_11.png` |

---

## V — Abschluss

| # | Was | Abnahmekriterium | Status |
|---|---|---|---|
| **V1** | Version **1.41**, `APP_VERSION`/`APP_BUILD` 41, Export-Preset | `[BUILD] Versionsanzeige v1.41 aktiv (Build 41)` | `[x]` |
| **V2** | Golden 8/8 (nach S7), Perf-Leitplanke | Log-Zeilen | `[x]` |
| **V3** | Doku: diese Spec (Status), `STATUS.md`, `project/BUGLISTE.md`, `project/ARCHITEKTUR.md`, `docs/SKIN_SLOP.md`, `screenshots/v141/` | alle aktualisiert | `[x]` |
| **V4** | Builds `dist/ComicShooter-v1.41.apk` + `.exe` | beide vorhanden, `apksigner verify` = 0 | `[x]` |
| **V5** | Gerätetest | offen, solange kein ADB-Gerät hängt | `[ ]` |

---

## Reihenfolge

```
F1 (erledigt)  →  F2  →  F3  →  F4  →  F5
B1 → B6
M1 → M7
S1 → S2 → S5 → S6 → S3 → S4 → S7
N1 → N2 → N3  →  [NUTZER WÄHLT]  →  N5 → N6
V1 → V4
```

---

## Bekannte Fallen (aus v1.39/v1.40, spart Zeit)

1. **Neue `class_name`-Skripte** brauchen einen Editor-Scan, sonst `Identifier "X" not declared`:
   `./Godot.exe --headless --editor --quit --path project`.
2. **Konstanten über eine Instanz** sind unzuverlässig (`inst.RIG_RARITY` → leer).
   Richtig: `inst.get_script().get_script_constant_map().get("NAME", [])`.
3. **Export-Pfade müssen absolut** sein (`C:/Users/vince/Games/comic-shooter/dist/...`),
   sonst `ERROR: Der Zielordner existiert nicht` (relativ zu `project/`).
4. **Sound-Keys** existieren nur diese: `boss, chest*, death, game, hit, hurt, kill, levelup,
   machine, menu, pickup, shoot, shotgun, slot_*`. Unbekannte Keys → `[SND][FEHLER] key=… fehlt`.
5. **Runden-Modul ist `RefCounted`**: `var rm = null` (nicht `var rm: Node`).
6. **Array-Indizes nie ohne ID-Migration umsortieren** — Profil speichert Namen (`p_rig_id`, `p_hat_id`).
7. **Events spawnen ungezählte Monster** → im Runden-Modus verboten (F1).
8. **Golden**: `char`-Modus gibt die Rig-Liste aus — nach Skin-Änderungen neu einfrieren.
9. **Seiten hängen an `start_screen`** (`_make_page`): jede Seite, die im Spiel geöffnet wird, liegt
   damit unter dem Menü und pausiert nichts (Ursache von F4). In-Game-Overlays gehören als Kind an
   `ui_manager` mit `get_tree().paused = true`.

## Ausdrücklich **nicht** ändern
- Modus 0 (ENDLOS) und Modus 1 (WELLEN+SHOP): Balancing, Events, Kisten, Kraftfelder bleiben.
- Kisten-System, Meta-Shop, LAN, Sammlungs-Layout, Touch-Steuerung.
- Die 30-Runden-Struktur und die Gruppen-Logik aus v1.40 (nur Boss-Beimischung + neue Monster ergänzen).
