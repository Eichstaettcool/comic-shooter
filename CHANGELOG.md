# Changelog

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
