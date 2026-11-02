# SPEC · LAN-Koop stabil machen

Status: Entwurf 1 · Ziel-Version v1.26
Grundlage: zwei echte Logs (Handy als Host, PC als Client) + Recherche zu
Godot-4-ENet-Koop (Godot-Docs, GameCodex-Lobby-Guide, ssebs/multiplayer-poc).

---

## 1. Was heute nachweislich kaputt ist

Alles hier ist aus Logs belegt, nicht vermutet.

| # | Symptom | Beleg im Log |
|---|---|---|
| 1 | Client startet einen Run **ohne Peer** („SOLO/1") | `[LAN][24.39][SOLO/1][DOWNED_CL] Client: Slot 1 downed=true hp=0` |
| 2 | Beide Seiten starten mit **hp=0** und sind sofort downed | `[LAN][53.74][HOST/1][DOWNED] Slot 2 liegt: rest=30.0s` direkt nach dem Start |
| 3 | Host-Slot wird trotz LAN **entfernt** und gleichzeitig als downed geführt | `[DEATH] health<=0 -> nicht LAN, Knoten wird entfernt` + danach `Slot 1 liegt: rest=29.7s` |
| 4 | Client kann Host **nicht aufwecken** | `near=true revive=0.0/5.0` über 25 s, obwohl der Bot 61 px daneben stand |
| 5 | Revive-Knopf springt zurück | 4 Versuche, alle bei 2,1–2,3 von 2,5 s abgebrochen |
| 6 | Host kann nicht hosten, wenn eine alte Instanz läuft | `ERROR: Couldn't create an ENet host.` (Port 7777 belegt) |

Was **funktioniert** (belegt): Verbindungsaufbau PC ↔ Handy, Karten- und
Kisten-Sync, 20–25 Monster-Snapshots/s, 17–19 Spieler-Updates/s, 58–60 FPS
auf dem Handy über mehrere Minuten.

---

## 2. Soll-Architektur

### 2.1 Grundsatz

**Host-autoritativ, ein Weltzustand.** Der Host simuliert Spieler, Monster,
Projektile und Wellen. Der Client sendet **nur Eingaben** und rendert den
Host-Zustand mit 100 ms Verzögerung.

```
Client                          Host
  │  Input (20 Hz, unreliable)    │
  ├──────────────────────────────►│  simuliert alles
  │                               │
  │  Snapshot (20 Hz, unreliable) │
  │◄──────────────────────────────┤  mobs[], players[], world
  │                               │
  │  Events (reliable)            │
  │◄──────────────────────────────┤  downed, revive, shop, death
```

### 2.2 Lobby als eigener Zustand

Die Lobby ist ein **getrennter Zustand** (`GameState.LOBBY`), nicht Teil des
Runs. Regeln:

1. Host startet den Run **nur**, wenn `NetManager.player_count >= 2`.
   Sonst: `[LAN] Warte auf Mitspieler: 1/2` und Knopf bleibt gesperrt.
2. Client startet **nie** aus eigenem Antrieb. Er wartet auf
   `run_start_signal` **und** prüft `multiplayer.get_peers().size() > 0`.
3. Beide senden vor dem Start ein `ready`-RPC; der Host wartet auf alle.
4. Erst wenn alle `ready` sind, wird die Szene geladen und **dann** pausiert
   aufgehoben (kein „Start ins Leere").

### 2.3 Spieler-Spawn

- Jeder Slot startet mit `max_health` aus `diff_data()["hearts"]`, nie mit 0.
- Der Host sendet nach dem Spawn einen **Full-State** (`coop_player` +
  `coop_world`) an alle Clients — nicht nur Deltas.
- `hp=0` beim Start ist ein **Fehler** und wird geloggt:
  `[LAN][FEHLER] Slot %d startet mit hp=0`.

### 2.4 Downed / Revive (bidirektional)

| Aktion | Weg |
|---|---|
| Client weckt Host | `c_send_revive(slot, active)` → `srv_revive_request` → Host zählt |
| Host weckt Client | lokal, wie bisher |
| Fortschritt anzeigen | `h_send_downed_state(slot, downed, hp, progress)` → Client-Banner + Ring |
| Erfolg | `h_send_downed_state(..., false, hp, 0)` |

**Regeln:**
- Aufwecken: **ein Klick** startet den 5-s-Lauf (kein Halten).
- Abbruch bei Entfernung > 120 px oder wenn der Aufweckende selbst downed ist.
- Nach Erfolg: 60 % HP + **2 s Unverwundbarkeit**.
- 30-s-Fenster; danach Zuschauer.
- Der Host-Slot wird **nie** entfernt, solange ein Partner lebt — auch nicht
  bei „health<=0".

### 2.5 Sync-Kanäle

| Kanal | Frequenz | Reliability | Inhalt |
|---|---|---|---|
| Mobs | 20 Hz | unreliable (seq) | id, type, x, y, hp, facing |
| Spieler | 20 Hz | unreliable | x, y, hp, max, weapon, angle, shield |
| Welt | 2,5 Hz | unreliable | Score, Combo, Biom, Buffs, Boss-HP |
| Events | bei Bedarf | **reliable** | downed, revive, shop-offer, death, run-start |
| Chat/Log | selten | reliable | Fehlertexte, Ready |

**Nie** Positionsdaten über `reliable` — das erzeugt Kopf-an-Kopf-Stau.

### 2.6 Client-Wiedergabe

1. Sequenznummer pro Snapshot, ältere verwerfen.
2. Ringpuffer (6 Snapshots ≈ 300 ms), Abspielung 100 ms hinter „jetzt".
3. Eigener Held: lokale Prediction, Korrektur erst ab 12 px (weich) bzw.
   220 px (Resync).
4. Fremder Held: Interpolation aus dem Puffer, kein Snapping.

### 2.7 Fehlerbehandlung

| Fall | Verhalten |
|---|---|
| Port 7777 belegt | `[LAN][FEHLER] Port belegt` im LAN-Fenster, kein stiller Fehlschlag |
| Verbindung scheitert | Status „Verbindung fehlgeschlagen: <Grund>" + erneut versuchen |
| Peer trennt | Slot aufräumen, Figur entfernen, Host läuft weiter |
| Host trennt | Client zurück ins Menü mit Hinweis |
| Version ungleich | `[LAN][FEHLER] Versionskonflikt` (Protokoll-Version im Handshake) |

---

## 3. Umsetzungsplan

| # | Schritt | Aufwand | Test |
|---|---|---|---|
| 1 | Lobby-Guard: Host wartet auf ≥ 2 Spieler, Client nur auf Signal | klein | Log `[LAN] Warte auf Mitspieler` |
| 2 | Spawn mit `max_health`, Full-State nach Spawn | klein | `hp>0` in beiden Logs |
| 3 | Host-Slot nie entfernen, solange Partner lebt | klein | kein `Knoten wird entfernt` im LAN |
| 4 | Revive-RPC (Client → Host) | erledigt | `revive=5.0/5.0` |
| 5 | Revive als Klick statt Halten | erledigt | Knopf-Log |
| 6 | Zuschauer-Overlay + Kamera auf Partner | erledigt | Screenshot |
| 7 | Snapshot-Puffer + Sequenznummern | erledigt | `[BUF]`-Test |
| 8 | Client-Prediction + Reconciliation | erledigt | `[PRED]`-Test |
| 9 | Relevanzfilter (1650 px) | erledigt | `[REL]`-Test |
| 10 | Protokoll-Version im Handshake | mittel | Verbindung zwischen v1.25/v1.26 schlägt sauber fehl |
| 11 | Peer-Trennung räumt Slot auf | mittel | Client beendet → Host-Slot weg |
| 12 | Zwei-Instanzen-Test + adb-Log beider Seiten | groß | Messwerte unten |

---

## 4. Testplan

### 4.1 Automatisiert (eine Instanz)

| Test | Erwartung |
|---|---|
| `slot/chest/reveal`-Regressionen | unverändert grün |
| Puffer-Test (3 Pakete, altes erneut) | `seq` bleibt, Interpolation 50/150 |
| Prediction-Test | weich 22 px, Resync 0 |
| Revive-Handler | `downed={1:true}`, `progress=2.5` |

### 4.2 Zwei Instanzen (PC + Handy, adb)

| Szenario | Erwartung |
|---|---|
| Host startet ohne Client | Knopf gesperrt, `[LAN] Warte auf Mitspieler: 1/2` |
| Client verbindet | beide `partner=[1,2]`, `hp>0` |
| 60 s spielen | Snapshots 20 ± 2/s, keine `[RECON]`-Flut |
| Host stirbt | Client sieht Banner, kann aufwecken → `5.0/5.0` |
| Client stirbt | Host weckt auf → 60 % HP + 2 s Schutz |
| Client beendet App | Host räumt Slot auf, kein Geist |
| Host beendet App | Client zurück ins Menü |

### 4.3 Messwerte, die im Log stehen müssen

```
[LAN][SYNC] mobs=20/s players=20/s world=3/s monsters=N
[LAN][DOWNED] Slot X liegt: rest=…s near=true revive=x.x/5.0
[NET][RECON] Resync dist=…   (darf selten sein)
[LAN][Warte] 1/2
```

---

## 5. Akzeptanzkriterien

1. Ein Run startet **nur** mit zwei verbundenen Spielern; ohne Partner bleibt
   der Host in der Lobby.
2. Beide Spieler starten mit vollen HP.
3. Beide können den anderen aufwecken; der Fortschritt läuft bis 5,0/5,0.
4. Der Host-Slot verschwindet nicht, solange der Client lebt.
5. Nach dem Verlassen einer Seite bleibt kein Geist und kein toter Slot zurück.
6. Über 2 Minuten bleibt die Snapshot-Rate ≥ 18/s.

---

## 6. Offene Punkte

- **NAT/Internet** ist nicht Teil dieser Spec — nur LAN/WLAN im selben Netz.
- Portwechsel (falls 7777 belegt) wird gemeldet, aber nicht automatisch belegt.
- Reconnect nach Verbindungsabbruch ist nicht vorgesehen (Neustart beider Seiten).
