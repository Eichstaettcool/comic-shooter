# ComicShooter — Entwicklungsplan

**Engine:** Godot 4.7.2 · **Ziel:** Android (Landscape 1920×1080) · **Build:** `ComicShooter.apk`
**Projektpfad:** `C:\Users\vince\Games\comic-shooter\project`

---

## Runde 1 (abgeschlossen ✅)
2D Top-Down Shooter: 16:9 Welt, Karo-Karte mit Objekten, Kisten (3s öffnen),
4 Monster-Typen, 3 Waffen, 5 Herzen, Start-/Todes-Screen, Highscore,
Touch-Steuerung, Comic-Charaktere mit Animationen.

---

## Runde 2 — JETZIG (in Arbeit)

### Angenommene Punkte aus deinem Feedback

| # | Punkt | Priorität | Status |
|---|---|---|---|
| V1 | Joystick-Hitbox zu klein → unsichtbare Touch-Zone deutlich größer als Visual | hoch | ✅ |
| V2 | Rechter Ziel-Joystick **entfernen** (er war nur fürs Zielen) → Schuss-Button halten = Dauerfeuer in Blickrichtung | hoch | ✅ |
| V3 | Joysticks auf Start- und Todes-Screen **nicht anzeigen** | hoch | ✅ |
| V4 | **Nochmal-Spielen nach Tod ging nicht** (Camera mit Player gefreed) → gefixt | hoch | ✅ |
| V5 | **Automatisch generierte, größere Map** (120×80 Tiles, pro Run neu) | mittel | ✅ |
| V6 | **Zufällige Upgrades aus Kisten:** Schild, Max-Herz+, Herzen, Waffen | mittel | ✅ |

### Was dabei passiert ist
- **Joystick:** 440×440 px full-touch-Hitbox, Visual nur 300 px zentriert (70%)
- **Map:** 120×80 = 3840×2560 px, pro Spielstart neu geshuffelt, mehr Kisten/Bäume/Steine,
  Monster spawnen jetzt innerhalb der Weltgrenzen
- **Schild:** fängt Treffer ab, 12 s, pulsierender blauer Ring
- **Max-Herz:** bis 7 Herzen, HUD passt Herzanzahl dynamisch an
- **Kisten-Gewicht:** 40% Waffe / 28% Herz / 18% Schild / 14% Max-Herz
- **Todes-Fix:** Camera2D folgt per Code (kein reparent mehr), überlebt den Tod → Neustart ok

---

## Ideen-Katalog (Runde 3 — noch NICHT umgesetzt, zur Diskussion)

**1. XP- & Levelsystem** ← mein Favorit für Gameplay-Tiefe
   - Monster geben XP je nach Typ (grün 5 / rot 10 / blau 20 / lila 40)
   - Level-Up → Belohnung. **Entscheidungsfrage an dich (unten)**
   - Level-Balken im HUD, XP-Zahlen poppen über Monstern

**2. Neue Monstertypen mit Funktionen**
   - *Werfer*: schießt aus Distanz → Ausweichen nötig
   - *Splitter*: teilt sich beim Tod in 2 Kleine
   - *Panzer*: langsam, viel HP, braucht viele Treffer
   - *Boss*: alle 2 Min, großes Muster, hoher Score

**3. Sich verändernde Map**
   - *Supply-Drops*: alle 45 s neue Kiste sichtbar spawnen (mit Signal)
   - *Korruptionszonen*: dunkle Flächen wandern, Monster darin schneller
   - *Nacht-Ansturm*: alle 2 Min kurze Welle + Vignette, mehr Spawn

**4. Feinschliff**
   - App-Icon · prozedurale Sounds (pew/boom) · Combo-Multiplikator für schnelle Kills
   - Projektil blockt an Wänden/Bäumen · Monster-Leichen verblassen kurz

---

## ❓ Entscheidungsfrage (blockiert Runde 3)
Fürs Level-Up-System — welcher Stil?

- **A) Auto-Buff:** beim Level-Up sofort ein zufälliger Buff (schnell, action-lastig, kein Menü)
- **B) Wahlkarte (Roguelite):** Spiel pausiert kurz, du wählst 1 von 3 Buffs (mehr Strategie/Taktik)
- **C) Beides:** Auto-Buffs + alle paar Level eine Wahlkarte-Bonus

Sag A/B/C, dann setz ich Runde 3 passend um. (Oder sag einfach "mach deinen Favoriten" — dann nehm ich B.)

## Arbeitsweise
Ich arbeite strukturiert Punkt für Punkt ab, bau nach jeder größeren Änderung die APK
und geb dir nach jedem Block Feedback. Bei kreativen Ideen frag ich dich statt blind zu entscheiden.
