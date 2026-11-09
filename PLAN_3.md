# PLAN 3 — Combo · Zonen · Icon · Balancing · Shot-Fix · Lokaler Multiplayer

## Block 1 — Fix & Feeling (klein, zuerst)
1. **Schuss-Animation Rotation**: Spieler-Sprite rotiert komplett zur Blickrichtung
   (nicht nur flip_h). Mündungsfeuer, Waffe & Projektil-Absprung folgen dem Winkel →
   korrekt bei oben/unten/diagonal.
2. **Regeneration**: Nach 12 s ohne Schaden → +1 Herz (bis max), automatisch, Herz pulst.
3. **App-Icon**: prozedural generiert (Boss-Gesicht, Gold-Krone, Comic-Ring) → icon.png,
   in project.godot eingetragen, nutzt Android automatisch.

## Block 2 — Neue Systeme
4. **Combo-Multiplikator**: Kills innerhalb 3 s Fenster stapeln.
   Score × (1 + 0.25·(Combo−1)), Cap ×5. Combo-Anzeige unter Score, "x4!" Popups.
5. **Korruptionszonen**: 3 wandernde violette Flächen pro Run (pulsierend, driftend).
   Spieler drin: −30% Tempo. Monster drin: +35% Tempo & rot getintet.
6. **Balancing-Runde** (Default-Vorschlag, Feedback erbeten):
   - Werfer: Schuss-Intervall 2.0 → 2.6 s, Kugel 210 → 200 px/s
   - Panzer: 12 HP aber nur 1 Schaden (war 2)
   - Splitter-Kinder: Spawn-Intervall-Pause
   - Boss: Fächer 5 → 5, aber Fächer-Winkel weiter (0.32) damit lückenhaft-meidbar
   - Erstes Monster spawnt nach 5 s (statt ~15) → früher Druck = früher XP

## Block 3 — Lokaler Multiplayer (Split-Touch, 1 Gerät)
7. **2-Spieler-Modus**: Startscreen-Button "2 SPIELER".
   - P1: blauer Held (links: Joystick + Feuer unten links)
   - P2: **roter Held** (rechts: Feuer + Joystick unten rechts)
   - Tastatur-Test: P1 WASD+Space, P2 Pfeile+Enter
   - Kamera folgt Midpoint beider Spieler
   - **Wenn einer stirbt → Game Over für beide** (wie gewünscht)
   - HUD: P1 Herzen oben links, P2 Herzen oben rechts, Score/XP/Boss gemeinsam
   - Kisten/Waffen: geteilte Welt, jeder eigenes Inventar/Cooldown
   - Combo/XP gemeinsam
8. **Startscreen Redesign**: schräger Logo-Bounce, beide Helden + Monster-Reihe als
   Besetzung, Buttons SPIELEN / 2 SPIELER, Steuerungs-Hints.

## Reihenfolge & Build
Block1 → Check → Block2 → Check → Block3 → Check → APK → Feedback an Vince.
Offene Frage an Vince: Balancing-Defaults ok? Monster-Feeling nach Tests?
