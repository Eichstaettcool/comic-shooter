# PLAN v1.39 — „Looks & Sammlung"

Feedback von Gabechen (3.11.2026), gebündelt zu **vier Überpunkten** und in **Blöcke**
gelegt, die in dieser Reihenfolge abgearbeitet werden. Details, messbare Kriterien
und Fallen: `SPEC_V139_LOOKS.md`.

## Überpunkte

| # | Überpunkt | Rohpunkte aus dem Feedback |
|---|---|---|
| **P1** | **Hüte sitzen falsch / heißen falsch** | Alien: Kappe, Zylinder, Cowboy, Krone, Stern, Wollmütze, Strohhut, Krönchen · Roboter: Kappe · Mars-Marschall: Kappe · Wikinger: alle außer Halo · „Kappe sieht an sich kacke aus" · Strohhut sieht aus wie rote Mütze · „rote Mütze ist als Krone gelistet" |
| **P2** | **Sammlung ist kaputt** | „Beim Öffnen des Menüs für die Sammlung stürzt das Game ab" · „die Sammlung ist außerdem kaputt" |
| **P3** | **Kisten-Animation nicht überspringbar** | „Button zum Skippen der Kistenanimation im Shop" · „die mögliche Gewinnauswahl ist immer dieselbe — Reihenfolge/Inhalt/Winner müssen bei jeder Öffnung neu gewürfelt werden" |
| **P4** | **Skins: Slop raus, neue Formen rein, Debug-Unlock** | „AI-Slop-Skins entfernen (gleiches Pattern, kein Mehrwert)" · „neue Skins zeichnen, z. B. Spinnenmann, Zombie — mit anderen Rigs, also anderen Formen" · „Debug-Menü: Button um alle Skins freizuschalten" |

## Blöcke

| Block | Inhalt | Warum in dieser Position |
|---|---|---|
| **M — Messnetz** | Kontaktblätter (29 Hüte × 4 Rigs, alle 25 Skins), Silhouetten-IoU, Diag-Modus `coll`, Baseline-Shots | Ohne Bilder und Repro-Modus ist „sieht kacke aus" nicht abnehmbar und der Crash nicht greifbar |
| **A — Sammlung** | Crash reproduzieren und beheben, Zähler, Reopen, Leck | Blockiert das Testen von C und D (die Sammlung ist der Prüfstand für Hüte und Skins) |
| **B — Kisten-Skip** | Skip-Knopf, Restzeit-Logik, Ergebnis-Screen | Klein, unabhängig, sofort nutzbar |
| **C — Hüte** | Namenstabelle, Kappe neu, Sitz je Rig (Alien/Wikinger/Roboter/Mars), Strohhut ≠ Wollmütze | Braucht die Kontaktblätter aus M, liefert die Bilder für D |
| **D — Skins** | Slop-Tabelle, Entfernen **mit Profil-Migration**, 4 neue Rigs (Spinnenmann, Zombie, …), Debug-Unlock | Größter Eingriff, ändert Index-Layout → nur nach A (Sammlung) und mit Migration |
| **E — Abschluss** | v1.39, Builds, Kontaktblätter, Doku | Nach allen Blöcken, damit kein Testbuild als Ergebnis rausgeht |

## Reihenfolge

```
M1 → M2 → M3 → M4          Messnetz, kein Spielcode
A1 → A2 → A3 → A4          Sammlung
B1 → B2 → B3               Skip
C1 → C2 → C3 → C4 → C5 → C6 → C7
D1 → D2 → D3 → D4 → D5 → D6 → D7
E1 → E2 → E3               Version + Builds
```

Regeln wie in `SPEC_V138_SPLIT.md`: eine Änderung pro Schritt, nach jedem Schritt
`./tools/golden_check.sh`, Statusmarker nachtragen, keine Builds vor Block E.

## Zwei Dinge, die vor dem ersten Schnitt klar sein müssen

1. **Profil-Migration ist Pflicht.** Skins und Hüte sind **Index-basiert** gespeichert
   (`p_rig`, `unlocked_rigs`, `p_hat`, `unlocked_hats`). Wer Skins löscht, verschiebt
   alle folgenden Indizes — ohne Migration verlieren bestehende Profile ihren Skin
   (falsche Figur, falsche Hüte). Deshalb: IDs einführen oder Lücken behalten.
2. **Der Crash ist im Diag-Modus nicht reproduzierbar.** `COMIC_LANTEST=char` baut die
   Sammlung und schießt `232c-sammlung.png` — **0 SCRIPT ERROR**. Der Fehler sitzt also
   im interaktiven Weg (Menü-Kachel „SAMMLUNG", `ui_manager.gd:1363`). Erst `coll`-Modus
   bauen, dann fixen — nicht blind reparieren.
