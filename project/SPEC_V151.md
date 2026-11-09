# SPEC v1.51 — Balancing Runden-Modus + Skills im Shop

Status: `[x]` umgesetzt und belegt · Stand: v1.51 · Builds: APK 1.51, EXE 1.51, iOS-Xcode-Projekt 1.51

## Ausgangslage (Fehlerbild des Nutzers)

> „ich komme im runden modus zb sogar in stufe leicht nicht über runde 9 hinaus
> irgendwann ist man einfach zu langsam und die roten holen einen ein"

Messung vor dem Umbau (v1.50): der schnellste Gegner ist RED mit 140 px/s, der
Spieler läuft 160 px/s. Die Runden-Kurve multipliziert das Gegnertempo mit
`spd_mult`, das bis 1,50 (Runde 14 SPRINT) bzw. 1,35 (Runde 21 SCHWARM) steigt.

| Runde | RED-Tempo v1.50 | Spieler | Verhältnis |
|---|---|---|---|
| 9 | 140 × 1,07 = **149,8** | 160 | 1,07 |
| 14 (SPRINT) | 140 × 1,50 = **210,0** | 160 | **0,76** |
| 21 (SCHWARM) | 140 × 1,35 = **189,0** | 160 | **0,85** |

Ab Runde 14 war der rote Gegner also **schneller als der Spieler** — Weglaufen
war unmöglich, nicht nur schwer. Genau das war die Wand.

## Punkte

### A1 — Gegnertempo deckeln `[x]`

`Rounds.spd_mult()` liefert höchstens **1,18** (vorher bis 1,50). Die
SPRINT-Runde 14 wurde von 1,50 auf 1,18 gesetzt.

**Abnahme:** `min_verhaeltnis >= 1,05` über die Runden 1–16 in allen drei Stufen.
**Beleg:** `[BAL151][TEMPO] stufe=leicht min_verhaeltnis=1.08 ok=true`
(identisch für normal/hart). Kurve: R9 = 1,20 · R14 = 1,08 · R16 = 1,13.

### A2 — Roter Gegner schwächer `[x]`

`monster_ai.gd` `TYPE_STATS`: RED 140 → **125** px/s (Leben unverändert 2).

**Abnahme:** RED-Tempo bei Runde 1 ≤ 125.
**Beleg:** `[BAL151][KURVE] stufe=leicht runde=1 … red_speed=125`.

### A3 — LEICHT entschärft `[x]`

`Rounds.DIFFICULTY["leicht"]`: HP-Faktor 0,85 → **0,80**, Monsterzahl 0,65 →
**0,58**, Münzfaktor 1,15 → **1,25**.

**Abnahme:** Runde 9 LEICHT hat weniger Gegner als vorher (18 → 16) und weniger HP.
**Beleg:** `[BAL151][KURVE] stufe=leicht runde=9 gegner=16 hp=183` (vorher 18 / 228).

### B1 — Mehr Münzen `[x]`

- Kill-Münzen: `2 + hp × 0,8` statt `1 + hp × 0,6`, Rundenskalierung `1 + 0,08r` statt `1 + 0,05r`.
- Rundenbonus: `16 + 6r` statt `12 + 4,5r`.

**Abnahme:** kumuliertes Einkommen bis Runde 9 LEICHT ≥ 1.200 Münzen.
**Beleg:** `[BAL151][EINKOMMEN] stufe=leicht r3=109(kum 277) r6=191(kum 786) r9=246(kum 1361) r12=306(kum 2200)`
· `[BAL151][MUENZ] runde=9 gruen=7 rot=7 blau=9 lila=12 boss=7`
(vorher: grün 3 / rot 4 / blau 4 / lila 6).

### C1 — Skills im Runden-Shop `[x]`

Neue Zeile **„SKILLS · DAUERHAFT"** im Shop zwischen den Runden, drei Karten:

| Skill | Wirkung je Stufe | Basispreis | Maximum |
|---|---|---|---|
| TEMPO +10 % | `speed_mult` +0,10 | 60 | 6 Stufen |
| NACHLADEN -8 % | `cooldown_mult` ×0,92 | 70 | 6 Stufen |
| SCHADEN +12 % | `damage_mult` +0,12 | 80 | 6 Stufen |

Preis steigt mit Runde (`Rounds.price_mult`) **und** Stufe (+45 % je Stufe).
Kauf direkt per Tipp auf die Karte, Stufenstand steht auf der Karte.

**Abnahme 1:** Kauf erhöht den Wert am Spieler.
**Beleg:** `[WSHOP][SKILL] id=skill_speed stufe=1 preis=80 … speed=1.10` →
`… stufe=6 … speed=1.60 cooldown=0.85 damage=1.36` (2× NACHLADEN, 3× SCHADEN).
**Abnahme 2:** Grenze 6 wird gehalten.
**Beleg:** `[WSHOP][SKILL] id=skill_speed kauf=nein grund=maximum stufe=6`.
**Abnahme 3:** Kauf über den echten Knopf im Shop (nicht nur Modul-Aufruf).
**Beleg:** `[BAL151][KNOPF] skill_damage vorher=2 nachher=3`.

### C2 — Shop ist zwischen den Runden erreichbar `[x]`

**Abnahme:** Nach Rundenende ist der HUD-Knopf sichtbar, öffnet den Shop, Kauf
landet in den Stufen, die nächste Runde startet.
**Beleg:** `[SHOP151][HUD] intermission=true knopf=true sichtbar=true` →
`[SHOP151][OFFEN] shop=true karten=11` → `[SHOP151][KAUF] id=skill_speed stufe=1`
→ `[SHOP151][RUNDE2] runde=2 aktiv=true`.

### D1 — Keine Regression `[x]`

**Abnahme:** `tools/golden_check.sh` 8/8 grün.
**Beleg:** `chestfull/upg/shop/mini/loc2/seasons/char/wpn2 … rest_diff=0 script_errors=0`
· „OK: Verhalten unveraendert."

### E1 — Builds `[x]`

- `dist/ComicShooter-v1.51.apk` (Android, Debug-signiert wie 1.50; **Release-Export scheitert ohne Keystore** — `WARNING: Release-Keystore konnte nicht gefunden werden`) · `apksigner verify` ok · 31,7 MB
- `dist/ComicShooter-v1.51.exe` (Windows, Release) · `[DONE] savepack` · 112,3 MB
- `ios_v151.xcodeproj` + `.pck` + `.xcframework` → `dist/ComicShooter-v1.51-iOS-Xcode.zip` (101 MB, 43 Einträge, `project.pbxproj` + `ios_v151.pck` geprüft)
- Version: `APP_VERSION="1.51"`, `APP_BUILD=51`, `export_presets.cfg` `version/code=51`, `version/name="1.51"`

**Gerätetest (Emulator Medium_Phone_API_36.1, Paket com.vince.comicshooter):**

| Prüfung | Beleg |
|---|---|
| APK installiert | `adb install -r` → `Success` |
| App startet | `mCurrentFocus=com.vince.comicshooter/…GodotAppLauncher`, `pidof=2586` |
| Version sichtbar | Menü-Screenshot `screenshots/v151/emu_menu151d.png` → „v1.51 · Build 51" (Sichtprüfung) |
| Keine Skriptfehler | `logcat \| grep -c "SCRIPT ERROR"` = 0 · `grep -c "signal 11"` = 0 |
| Modus-Umschalter reagiert | Tap auf Modus-Zeile → „MODUS: WELLEN + SHOP" (`emu_modus151.png`) |

**Einschränkung:** Der Emulator brauchte nach einem Kaltstart ~2 Minuten bis zum Menü
(`[BOOT][0] _ready start ms=95926`). Der Shop zwischen den Runden wurde **nicht** per
Fingertipp auf dem Gerät durchgespielt — dieser Pfad ist headless belegt
(`[SHOP151]…`), weil ein vollständiger Kampf im Emulator zu langsam läuft.

---

## Abweichungen / Anmerkungen

- **LEICHT nutzt kein eigenes Gegnertempo.** Die Stufe skaliert HP, Anzahl,
  Preise und Münzen, nicht das Tempo — deshalb gilt die Tempo-Kurve für alle drei
  Stufen gleich. Das war schon in v1.50 so und wurde nicht geändert.
- **Skill-Kauf ohne Bestätigungsfenster.** Bewusste Entscheidung: der Effekt ist
  eine Zeile, das Fenster wäre ein zusätzlicher Klick pro Kauf. Rückgängig geht
  ein Kauf nicht — bei 6 Stufen und steigenden Preisen ist das vertretbar.
- **`_cards` wuchs bei jedem Rebuild** (Altbestand): `_rebuild()` leert die Liste
  jetzt, sonst hätte jeder Skill-Kauf die Kartenliste vervielfacht
  (`karten=11` statt 55 nach 4 Käufen).
