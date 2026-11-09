# iOS-Build ohne Xcode auf deinem Mac

## Warum dein Mac nicht das Problem ist

Godots iOS-Export erzeugt nur ein **Xcode-Projekt**; gebaut wird es mit `xcodebuild`, und das
steckt in Xcode. Xcode 26 verlangt macOS 26 — wenn dein Mac das nicht bekommt, ist die lokale
Route tot, egal was du installierst. Zwei Wege bleiben:

| Weg | braucht deinen Mac? | braucht Xcode? | Aufwand |
|---|---|---|---|
| **A: GitHub Actions (macOS-Runner) + Sideloadly** | nein | nein (läuft in der Cloud) | 20 Min, einmalig |
| B: gemieteter Mac / Leih-Mac | nein | ja (dort vorinstalliert) | 15 Min, kostet Stundenpreis |
| C: ältere Xcode-Version auf deinem Mac | ja | ja, passend zur macOS-Version | riskant (s. u.) |

Weg A ist der einzige, der ohne fremde Hardware und ohne Geld funktioniert.

---

## Weg A — GitHub baut, Sideloadly installiert (Windows)

### 1. Repository anlegen und hochladen

1. Auf github.com ein **privates** Repo `comic-shooter` anlegen.
2. Das vorbereitete Paket `ComicShooter-repo-v150.zip` entpacken — es enthält `project/` (ohne
   `.godot`), `.github/workflows/ios.yml` und `.gitignore`.
3. Inhalt in das Repo pushen (GitHub Desktop: „Add existing repository" → Ordner wählen →
   Publish). Alternativ per Kommandozeile:

```bash
cd comic-shooter-repo
git init
git add .
git commit -m "v1.50"
git branch -M main
git remote add origin https://github.com/<DEIN-NAME>/comic-shooter.git
git push -u origin main
```

### 2. Workflow starten

1. Im Repo auf **Actions** → links „iOS Build (unsigned IPA)" → **Run workflow** → `main`.
2. Lauf dauert 8–15 Minuten. Am Ende steht unter **Artifacts**:
   `ComicShooter-unsigned-ipa` → ZIP herunterladen, darin `ComicShooter-v1.50-unsigned.ipa`.

Wenn der Lauf rot wird: im Log steht bei „Xcode-Targets anzeigen" der echte Target-Name und im
Schritt „Bauen ohne Signatur" der erste `error:`. Die zwei häufigen Fälle:

- `error: Signing for "ios" requires a development team` → es fehlt
  `CODE_SIGNING_ALLOWED=NO` (steht drin; sonst Zeile prüfen).
- `Godot_v4.7.2-stable_macos.universal.zip` 404 → Godot-Version im Workflow anpassen.

### 3. Auf dem iPhone installieren (Sideloadly, kostenlos)

1. **Apple Devices** (Microsoft Store) oder iTunes installieren — liefert die USB-Treiber.
2. **Sideloadly** von sideloadly.io installieren, iPhone per Kabel anschließen, „Vertrauen".
3. `.ipa` in Sideloadly ziehen, **Apple ID** eintragen (kostenloses Konto reicht), Start.
4. Am iPhone: **Einstellungen → Allgemein → VPN & Geräteverwaltung → Entwickler-App
   vertrauen**.
5. App starten. Gültigkeit **7 Tage**, danach denselben Vorgang wiederholen (max. 3 Apps
   gleichzeitig mit einer freien Apple-ID).

Das ist derselbe Weg wie bei AltStore/SideStore — ohne Jailbreak, ohne Developer-Programm.

---

## Weg B — gemieteter Mac (wenn es dauerhaft laufen soll)

Scaleway (Mac mini M1, stundenweise) oder Hetzner. Dort ist Xcode vorinstalliert:

1. `ComicShooter-v1.50-iOS-Xcode.zip` kopieren, entpacken.
2. `ios_v150.xcodeproj` öffnen → Target → *Signing & Capabilities* → Team = deine Apple-ID,
   Bundle-ID ggf. eindeutig machen (`com.vince.comicshooter2`).
3. iPhone per USB oder *Devices and Simulators* verbinden → Run.
4. Für eine `.ipa`: Product → Archive → Organizer → *Distribute App → Development*.

Hinweis: 7-Tage-Ablauf gilt auch hier bei freier Apple-ID; mit Developer-Programm (99 $/Jahr)
nicht.

---

## Weg C — ältere Xcode-Version auf deinem Mac (nur wenn Weg A nicht geht)

Xcode passt nur zu bestimmten macOS-Versionen (Apple-Tabelle
`developer.apple.com/support/xcode`, hier die relevanten Zeilen):

| Xcode | macOS | iOS-SDK |
|---|---|---|
| 26.x | 26 (Tahoe) | iOS 26 |
| 16.4 | 15.3+ | iOS 18.5 |
| 16.0–16.2 | 14.5+ | iOS 18 |
| 15.2 | 13.5+ | iOS 17.2 |
| 14.3 | 13.0+ | iOS 16.4 |
| 14.2 | 12.5+ | iOS 16.2 |

Ältere Xcodes gibt es nur als `.xip` im Apple-Developer-Portal (Anmeldung mit Apple-ID,
„More" → Downloads). Risiko: Die Godot-4.7.2-iOS-Templates sind gegen ein neueres SDK gebaut;
mit Xcode 14/15 kann der Link-Schritt mit `undefined symbol` scheitern. Deshalb ist Weg A
vorzuziehen — dort ist die Xcode-Version garantiert passend.

---

## Was schon fertig ist

- `dist/ComicShooter-v1.50-iOS-Xcode.zip` — vollständiges Xcode-Projekt für jeden Mac/CI-Lauf
  (`.xcodeproj`, `ios_v150.pck`, `ios_v150.xcframework`, `MoltenVK.xcframework`,
  `PrivacyInfo.xcprivacy`, Assets). Info.plist enthält `NSLocalNetworkUsageDescription`,
  damit der WLAN-Koop nicht stumm scheitert.
- `.github/workflows/ios.yml` — baut daraus die unsignierte `.ipa`.
