# Changelog

## v1.58
- Balance über alle drei Modi: eine Zahlenquelle (`scripts/core/balance.gd`),
  Schwierigkeit als Gegner-HP pro Sekunde gegen den Spieler-DPS
- Wellen laufen als Sägezahn: Anlauf, Peak, Erholung statt gleichmäßigem Anstieg
- Bosse ersetzen eine Welle, 2 s Telegraph, zwei Phasen, kurze Unverwundbarkeit
  beim Phasenwechsel, keine Adds
- Fix: Monster passen in jeder Welt zur Karte (Mars, Dschungel, Elektro hatten
  fremde Typen)
- Fix: In den ersten Sekunden war das Feld leer — Schonfrist verkürzt, erster
  Schub sofort
- Fix: Kisten ließen sich per Touch nicht öffnen (Overlay schluckte die Eingaben)
- Fix: Wellen+Shop blieb stehen, wenn alle Gegner besiegt waren, Shop öffnete nicht
- Spieler: 0,6 s Unverwundbarkeit nach Treffer
- Neue Galerie-Bilder, README überarbeitet

## v1.28
- Glückswalze im Shop: Walzenbänder mit gezeichneten Symbolen, 4 eigene Sounds,
  RTP 90,1 % über 200.000 Spins
- Neue Kosmetik: Engelsschein, Antenne, Krönchen (Hüte) + Astronaut,
  Gold-Roboter, Schatten (Skins)
- Kisten-Reveal zeigt nur noch das gewonnene Item; Gold/Gems als 1–3 Symbole
- Shop: Item-Symbole auf den Kistenkarten, Glückswalze als eigener Abschnitt
- LAN: Lobby-Guard (kein Run ohne Mitspieler), hp=0-Schutz, Host-Knoten bleibt,
  Peer-Trennung räumt den Slot auf
- Specs: SPEC_SLOT.md, SPEC_LAN.md

## v1.10
- Fix: Zwei Spieler-Figuren nach Run-Neustart — `_clear_run()` räumt Spieler,
  Monster und Boss-Referenzen beim Verlassen und vor jedem Start
- Fix: Mini-Bosse hatten 2 HP (`set_mini`) und starben beim ersten Treffer
- Fix: Boss-Spawn mit Sicherheitsnetz (zweiter Versuch, Log-Warnung)
- Shop: volle Breite (1680 px), Währungen als Icons, schräge Aufkleber-Header
- Lootbox: Gewinner-Kachel leuchtet und pulsiert, gestaffelt nach Seltenheit
- Loot: Gem-Stufen bis 40, Gold- und Gem-Felder im Laufband
- Debug: Monster-Dropdown (31 Typen), Boss/Mini-Boss je Karte, God-Mode

## v1.9
- Scrollen im Shop repariert (falscher Guard auf alte Shop-Seite)
- Shop auf volle Breite, größere Karten

## v1.7
- Gemalte Kisten (Standard/Silber/Premium), Blitz-Übergang beim Öffnen
- Kosmetik-Kisten mit Edelsteinen, Loot-Tabelle, Duplikat-Rückerstattung

## v1.3
- Schatten, dichtere Wiese, LAN-Fenster im Comic-Stil
