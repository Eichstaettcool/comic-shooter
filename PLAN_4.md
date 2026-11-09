# PLAN 4 — LAN-Multiplayer (WLAN) · Solo-UI-Korrektur · Gameplay-Agenda

## Recherche-Ergebnis (Godot-Doku + Community, 4.7)
- **Transport:** `ENetMultiplayerPeer` → `multiplayer.multiplayer_peer` setzen.
  Host: `create_server(PORT, max)`, Client: `create_client(IP, PORT)`. Nur UDP;
  im selben WLAN reicht die interne IP (192.168.x.x) — kein Port-Forwarding nötig.
- **Server-Liste/Discovery:** Beacon-Pattern — Host sendet per `PacketPeerUDP`
  mit `set_broadcast_enabled(true)` alle ~0.6s JSON/String an 255.255.255.255:PORT;
  Joiner lauscht mit `PacketUDPServer.listen(PORT, "0.0.0.0")`, sammelt
  `get_packet_ip()` → Hostliste. Fallback: manuelle IP-Eingabe (wichtig, falls
  Router-Broadcast blockt).
- **Sync:** High-Level RPCs (`@rpc("any_peer","unreliable")` für Position/HP,
  reliable für Join/Start). Host gibt Spielstart per `begin_run.rpc()` frei.

## ERLEDIGT & VERIFIZIERT (diese Runde)
1. **Solo-Layout gefixt**: Joystick links, **Schuss-Button rechts unten** (1580,790 –
   Daumen erreicht ihn ohne Umgreifen). Duo behält 2 Paare (P1 links, P2 rechts).
2. **LAN-Auswahl-Fenster**: Startscreen-Button „LAN SPIEL" (grün) → Panel mit
   [HOSTEN] [NEU SCANNEN] Hostliste [BEITRETEN] + manueller IP + Statuszeile.
3. **LAN-Grundschaltung Phase 1** („Spiegel-Coop") — im Zwei-Instanzen-Test verifiziert:
   - Host: `ENetMultiplayerPeer.create_server(7777)`, Beacon alle 0.6s an
     255.255.255.255 **und** an alle Interface-Broadcast-Adressen (WLAN-Router-
     Sicherheit), Beacon-Socket explizit auf eigenen Port gebunden
   - Joiner: `PacketPeerUDP.bind(7778)` → Hostliste, alternativ IP manuell
   - Client verbindet: `status=2, peers=[1]` ✔; Host empfängt echte Partnerdaten
     (hp=5/5, weapon=pistol, pos) ✔; Client startet seinen Run automatisch per
     `begin_run.rpc()` ✔
   - Partner erscheint als **durchscheinender roter Held** (Alpha 0.62) an seiner
     Position, rotiert in Blickrichtung
   - **Partner-HUD oben rechts in blassem Ton**: „PARTNER (WLAN)" + Herz-Zeile
     (Alpha 0.62) + Waffen-Icon + Waffenname + Schild-Anzeige
   - Verbindungsabbruch wird sauber behandelt (Partner verschwindet)
4. **Wichtige Godot-API-Fallen (gelernt)**:
   - `PacketUDPServer` existiert in 4.7 **nicht** → `PacketPeerUDP.bind(port, "0.0.0.0")`
   - `PacketPeerUDP.put_string()` gibt es **nicht** → `put_packet(str.to_utf8_buffer())`
   - `ENetMultiplayerPeer.get_local_port()` existiert nicht
   - `--quit-after N` zählt **Frames** (headless = sofort) → für Zeit-Tests
     Echtzeit-Warteschleife über `await get_tree().process_frame` nutzen
   - Limited-Broadcast (255.255.255.255) wird lokal **nicht** an andere Prozesse
     zugestellt → für PC-PC-Test immer die manuelle IP-Eingabe verwenden

## Phase 2 (nach Zwischentest, noch NICHT gebaut)
- Echte gemeinsame Welt: Host ist Authoritative für Monster/Spawns/Loot,
  Client sendet nur Inputs. Shared Score & Game-Over.
- Partner-Schilde/Animationen/Mündungsfeuer fernsynchen.

## GAMEPLAY-AGENDA (vereinbart, Umsetzung nach LAN)
| # | Feature | Detail |
|---|---|---|
| G1 | **KistenLoot vielseitiger** | Mehr Waffen-Typen (z.B. Laser, Rakete, Revolver, Strahlen-Burst), Seltenheits-Stufen (Common→Rare→Epic mit Farbring), Munitions-/Zeit-Powerups (Feuersalve, Freeze, Magnet) |
| G2 | **Waffen-HUD rechts oben** | Alle gefundenen Waffen als Icons oben rechts; antippbar = wechseln (aktuelle Waffe hervorgehoben) |
| G3 | **Boss-Respawn-Regel** | Neuer Boss spawnt ERST, wenn der aktuelle besiegt ist (+60s Pause danach). Kein Boss-Stapel. |
| G4 | **Biome nach Score** | Score-Schwellen wechseln die Welt: 0–499 Wiese (heute) · 500+ **Wüste** (Sand-Karo, Kakteen, Krokodil-Mobs) · 1200+ **Eis** (blaue Tiles, Pinguin-Mobs, glatte Boden-Beschleunigung) · 2200+ **Lofi-Lava** (dunkelrot, Dämonen, Lava-See = Schadenfelder statt Korruption). Übergang: 2s Flash + Banner „WÜSTE!", Tile-Palette in MapGenerator umschaltbar, Deko-Texturen wechseln mit. |
| G5 | Offene Ideen | Sounds je Biome, Endloop-Score-Atari-Style „READY", Online-Overplay statt LAN |

## Reihenfolge
1+2+3 → Headless-Check → Duo-Regression → APK → Vince-Zwischentest → dann G1–G3, danach G4.
