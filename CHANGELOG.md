# Changelog

## v1.4

**Karte**
- Büsche neu gezeichnet im Stil der Bäume (Kontur, dunkle Unterseite,
  Lichtkante) — die geladenen busch_*.png hatten keine Kontur und wirkten
  wie Flammen
- Waffen-Überschrift gekürzt, sie wurde abgeschnitten

## v1.3

**Karte**
- Schlagschatten deutlich kleiner und heller (wirkten vorher wie dunkle Pfützen)
- Erde/Wiese dichter bepflanzt: 96 statt 58 Baum-Cluster, Büsche, mehr Steine
  und farbige Blumen (vorher 125 Objekte, jetzt ~275)

**Oberfläche**
- LAN-Fenster zentriert und im Comic-Stil (war fest auf 520,60 gesetzt und
  960 px hoch — ragte auf 720p unten aus dem Bild)
- Trank/Bombe-Knöpfe zeigen ihr Label schon beim Run-Start (vorher stand
  auf beiden "TRANK x0")

## v1.2

**Korrekturen**
- Hüte verschwanden im Spiel, sobald ein Skin gewählt war (Skin-Pfad rief die
  Textur ohne Hut-Parameter ab) — behoben
- Sammlung ist jetzt Read-only: Outfits, Farben und Hüte lassen sich dort nur
  ansehen, geändert wird im Charakter-Menü

**Einstellungen**
- Musik und Soundeffekte sind getrennt schaltbar und werden gespeichert
  (vorher ein gemeinsamer Sound-Schalter)

**Karte**
- Boden-Gitter wieder auf allen Karten inklusive Dschungel eingeblendet
  (ohne das Gitter wirkten Wiese und Wüste als leere Fläche)

## v1.1

**Oberfläche**
- HUD, Pause-Menü und Upgrade-Karten im Comic-Stil der Startseite
- Waffen-Slots von 56 auf 88 px vergrößert (bessere Trefferfläche auf dem Handy)
- Trank-/Bomben-Knöpfe größer und mit Rahmen

**Grafik**
- Charaktere mit Kantenglättung (Coverage-Sampling) — keine ausgefransten Ränder mehr
- Schlagschatten unter allen Karten-Objekten
- Dschungel: Blatthaufen, farbige Blumen, rote Pilze, weicherer Boden
- Debug-Karo-Raster entfernt (war die Ursache des sichtbaren Kachelgitters)

**Audio**
- Spielmusik im ruhigen Stil des Startbildschirms (keine Drums mehr)

**Technik**
- Debug-Fenster mit `F9`: Charakter-Vorschau, Weltwechsel, Freischalten, Live-Werte
- Zuschauermodus, Downed-/Revive-Sync und Shop-Fixes für den LAN-Koop

## v1.0

Erste Fassung: vier Welten, Wellen-Modus, Bosse, Shop, LAN-Koop.
