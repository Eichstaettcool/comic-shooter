# iOS-Export — Anleitung für den Mac (Comic Shooter v1.47)

Stand 6.11.2026. Projekt: Godot 4.7.2, Bundle-ID `com.vince.comicshooter`, Version 1.47 / Build 47.
Der Mac ist ein **anderer Rechner** — alles, was du brauchst, liegt auf dem Windows-Rechner auf dem
Desktop und wird übertragen.

---

## 0. Was du brauchst

| Ding | Woher | Wichtig |
|---|---|---|
| **Xcode** (aktuell, ~7 GB) | Mac App Store oder developer.apple.com | einmalig starten, Lizenz bestätigen, iOS-Plattform nachinstallieren |
| **Apple-ID** (kostenlos) | appleid.apple.com | reicht zum Testen auf dem eigenen iPhone (7 Tage gültig) |
| **Apple Developer Program** (99 $/Jahr) | developer.apple.com/programs | **nur** nötig für TestFlight / App Store |
| **Godot 4.7.2 (macOS)** | godotengine.org/download/macos | **exakt 4.7.2** — andere Version = andere Export-Templates = Ärger |
| **iOS-Export-Templates 4.7.2** | Godot → Editor → *Manage Export Templates* → *Download and Install* | ohne die schlägt der Export fehl |

Platz auf der Platte: ~15 GB frei (Xcode + Simulatoren).

---

## 1. Dateien auf den Mac bringen

Auf dem Windows-Desktop liegen zwei ZIPs. Übertragen per USB-Stick, AirDrop vom iPhone oder
Netzwerkfreigabe — egal, Hauptsache beide auf den Mac:

| Datei | Größe | Inhalt |
|---|---|---|
| `ComicShooter-Projekt-v147.zip` | 3 MB | das komplette Godot-Projekt (Skripte, Assets, Szenen, `project.godot`, `export_presets.cfg`, Icon). **Weg B** |
| `ComicShooter-iOS-v147-Xcode.zip` | 116 MB | fertiges **Xcode-Projekt** mit `ios_build.pck`, `libgodot.a`, MoltenVK und allen App-Icons. **Weg A** |

Auf dem Mac in den Ordner `~/Entwicklung/ComicShooter/` entpacken (Doppelklick reicht).

> **Wichtig für Weg A:** Die Datei `ios_build.pck` **muss** neben `ios_build.xcodeproj` liegen —
> so ist das ZIP gepackt. Wenn du nur das `.xcodeproj` weiterreichst, startet die App leer.

---

## Weg A — schnell ausprobieren (5 Minuten, ohne Godot)

1. `ComicShooter-iOS-v147-Xcode.zip` entpacken.
2. `ios_build.xcodeproj` doppelklicken → Xcode öffnet sich.
3. Links im Navigator das blaue Projekt `ios_build` anklicken → Reiter **Signing & Capabilities**:
   - **Team**: deine Apple-ID auswählen (ggf. erst *Add Account…* mit der Apple-ID).
   - **Bundle Identifier**: `com.vince.comicshooter` — wenn Xcode „already in use" meldet, hänge
     etwas an, z. B. `com.vince.comicshooter2`.
   - Häkchen bei **Automatically manage signing** setzen.
4. Oben als Ziel **iPhone 15 (Simulator)** oder dein angestecktes iPhone wählen → ▶︎ **Play**.
5. Beim ersten Start auf echtem Gerät: iPhone → *Einstellungen → Allgemein → VPN & Geräteverwaltung*
   → deinem Entwickler-Zertifikat **vertrauen**.

Fertig. Das ist die **Debug**-Fassung (zum Testen, nicht für den Store).

---

## Weg B — richtig exportieren (empfohlen, für Updates und App Store)

1. `ComicShooter-Projekt-v147.zip` entpacken → Ordner `project/`.
2. **Godot 4.7.2** starten → *Import* → `project/project.godot` wählen → *Import & Edit*.
   Beim ersten Öffnen re-importiert Godot alle Assets (dauert 1–2 Minuten).
3. *Editor → Manage Export Templates → Download and Install* (einmalig, ~1 GB).
4. *Project → Export…* → links **iOS** auswählen:
   - **Bundle Identifier**: `com.vince.comicshooter`
   - **Team ID**: deine 10-stellige Team-ID (findest du unter developer.apple.com → Membership)
   - **Export method**: `Xcode Project` (dann baut Xcode; so ist es hier eingestellt)
   - **App Store Team ID / Signing**: leer lassen, signiert wird in Xcode
   - **Version**: `1.47`, **Short Version**: `1.47` (Felder sind im Preset leer → leer = Godot nimmt
     die Projektversion, besser explizit eintragen)
   - **Export With Debug** abwählen, wenn du eine Release-Fassung willst (für den Store Pflicht)
   - **Export Project…** → Zielordner `~/Entwicklung/ComicShooter/ios_build`
5. Im Zielordner liegen jetzt `ios_build.xcodeproj`, `ios_build/`, `ios_build.pck`,
   `ios_build.xcframework`, `MoltenVK.xcframework`, `PrivacyInfo.xcprivacy`.
   `ios_build.xcodeproj` öffnen → wie in Weg A: Team wählen, starten.

---

## 2. Auf das eigene iPhone (ohne bezahltes Programm)

- Xcode → Ziel = dein iPhone (Kabel, „Vertrauen" am iPhone bestätigen).
- Signing: **Personal Team** wählen (deine Apple-ID).
- ▶︎ startet die App; sie läuft **7 Tage**, danach neu bauen. Max. 3 Apps gleichzeitig.
- Das ist der übliche Weg zum Ausprobieren auf echter Hardware.

---

## 3. TestFlight / App Store (mit Developer Program)

1. **App Store Connect** → *My Apps* → **+** → *New App*:
   Plattform iOS, Name „Comic Shooter", Sprache Deutsch, Bundle-ID `com.vince.comicshooter`,
   SKU z. B. `comicshooter147`.
2. In Godot **Release** exportieren (nicht Debug), in Xcode öffnen.
3. Xcode: Ziel = *Any iOS Device (arm64)* → **Product → Archive**.
   - Erscheint „Archive" grau: oben ein echtes Gerät oder *Any iOS Device* wählen, nicht den Simulator.
4. Im Organizer: **Distribute App → App Store Connect → Upload**.
5. In App Store Connect ausfüllen: Screenshots (6,7″ iPhone **quer**), Beschreibung, Altersfreigabe,
   Datenschutz („keine Daten erhoben" — das Spiel sammelt nichts), Preis.
6. **TestFlight** ist nach dem Upload sofort nutzbar (intern ohne Prüfung).

---

## 4. Was bei DIESEM Spiel besonders ist

| Punkt | Was zu tun ist |
|---|---|
| **Querformat** | `handheld/orientation = sensor_landscape` — das iPhone quer halten. Im Preset nichts ändern. |
| **LAN/Co-op** | iOS fragt beim ersten Verbinden nach dem **lokalen Netzwerk**. Ohne `NSLocalNetworkUsageDescription` in der Info.plist schlägt die Suche still fehl. In Xcode: *ios_build-Info.plist* → Key `NSLocalNetworkUsageDescription` = „Comic Shooter findet Mitspieler im WLAN." |
| **Ton** | Der iPhone-Stummschalter kann die Musik abschalten (AVAudioSession). Zum Testen Schalter aus. In den Spiel-Einstellungen gibt es Regler für Musik/SFX. |
| **Steuerung** | Virtueller Joystick links, Feuerknopf rechts — funktioniert per Touch unverändert; Tastatur/Maus sind auf iOS irrelevant. |
| **Icons** | Das App-Icon (lila Boss, drei Augen) steckt schon in `Images.xcassets/AppIcon.appiconset` (1024 px + alle Größen). Wird beim Export automatisch aus `res://icon.png` erzeugt. |
| **Startbildschirm** | `Launch Screen.storyboard` + `SplashImage` sind dabei; kein Handlungsbedarf. |
| **Debug-Ausgaben** | Xcode-Konsole zeigt die gleichen Zeilen wie auf Windows (`[BUILD] Versionsanzeige v1.47 aktiv (Build 47)`, `[MUSIK]…`, `SCRIPT ERROR …`). Es gibt **keine** `COMIC_LANTEST`-Diag-Modi auf iOS (iOS kennt keine Umgebungsvariablen) — das ist normal. |
| **Renderer** | Projekt nutzt Forward+; auf iOS läuft das über MoltenVK. Wenn es auf alten Geräten ruckelt: *Project Settings → Rendering → Renderer → Mobile* und neu exportieren. |
| **Texturen** | `import_etc2_astc = true` ist gesetzt — richtig für iOS. |
| **Speicherstand** | Profil/Save liegen in `user://` (App-Sandbox); bleibt beim Update erhalten, verschwindet beim Löschen der App. |

---

## 5. Häufige Fehler und was sie bedeuten

| Meldung | Ursache / Lösung |
|---|---|
| `No export template found for iOS` | Templates fehlen oder sind eine andere Godot-Version → *Manage Export Templates* → 4.7.2 installieren |
| `Project export for preset "iOS" failed` + `Codesignierung: Release-Keystore…` | Das passiert nur beim **Android**-Preset, nicht bei iOS — falsches Preset gewählt |
| Xcode: `Signing for "ios_build" requires a development team` | Team unter *Signing & Capabilities* wählen |
| Xcode: `No such file: ios_build.pck` | Die `.pck` liegt nicht neben dem `.xcodeproj` (siehe Weg A/B) |
| App startet und zeigt nur ein graues Bild | `ios_build.xcframework` bzw. `MoltenVK.xcframework` fehlen im Ordner |
| `Unable to install … not supported by device` | In Xcode ein zu neues Deployment-Target (z. B. 17) bei älterem iPhone → *Build Settings → iOS Deployment Target* auf 13.0 senken |
| Co-op findet keinen Partner | lokale Netzwerk-Berechtigung fehlt (siehe oben), beide Geräte im selben WLAN, Pi-hole/VPN aus |
| Musik stumm, SFX laut | iOS-Stummschalter aktiv, oder Musikregler im Spiel auf 0 |

---

## 6. Checkliste in Kurzform

```
[ ] Xcode installiert, einmal gestartet, iOS-Plattform geladen
[ ] Godot 4.7.2 + iOS-Templates installiert
[ ] Projekt entpackt, importiert
[ ] Export-Preset iOS: Bundle-ID, Team-ID, Version 1.47
[ ] Export → ios_build.xcodeproj (pck + xcframeworks liegen daneben)
[ ] Xcode: Team gesetzt, Automatically manage signing
[ ] Auf Simulator gestartet  →  muss laufen
[ ] Auf iPhone gestartet    →  Zertifikat vertrauen
[ ] NSLocalNetworkUsageDescription ergänzt (für LAN)
[ ] Release-Export + Product → Archive → App Store Connect
```

---

## 7. Wenn etwas klemmt

Sag mir, an welchem Schritt es hängt, und schick die Zeile aus der Xcode-Konsole oder die
Fehlermeldung. Ich kann Fehler in Skripten sofort beheben und dir ein neues ZIP bauen — nur das
Signieren und Hochladen muss auf dem Mac passieren (das geht technisch nur dort).
