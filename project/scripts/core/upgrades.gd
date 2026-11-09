class_name UpgradesModule
extends RefCounted

# Runde 138: Upgrades aus game_manager.gd
var host: Node = null

# Spiegel von game_manager.gd - Enum ist nicht ueber host erreichbar,
# Reihenfolge muss identisch bleiben.
enum GameState { MENU, LOBBY, PLAYING, DEAD }

const UPGRADES = [
	{"id": "power", "name": "MEHR SCHADEN", "desc": "Deine Waffen machen +25% Schaden", "cap": 5},
	{"id": "turbo", "name": "SCHNELLER NACHLADEN", "desc": "Alle Waffen laden 15% schneller nach", "cap": 4},
	{"id": "speed", "name": "SCHNELLE BEINE", "desc": "+15% Bewegungstempo", "cap": 4},
	{"id": "vitality", "name": "MEHR HERZEN", "desc": "+1 maximales Herz und sofort geheilt", "cap": 2},
	{"id": "guardian", "name": "SCHILD-LADUNG", "desc": "+2 Schild-Treffer (12 Sekunden)", "cap": 3},
	{"id": "vampire", "name": "VAMPIR", "desc": "Heilt 1 Herz fuer je 12 Kills", "cap": 1},
]


func _upgrade_options() -> Array:
	# Verfuegbare Upgrades fuer die Karten (Runde 136: eigener Helfer, damit
	# Toast und Fenster dieselbe Auswahl benutzen).
	var avail: Array = []
	for u in UPGRADES:
		var used: int = int(host.upg_stacks.get(u["id"], 0))
		if used < int(u["cap"]):
			if u["id"] == "vitality" and is_instance_valid(host.player) and host.player.call("get_max_health") >= 7:
				continue
			avail.append(u)
	if avail.is_empty():
		return []
	avail.shuffle()
	return avail.slice(0, min(3, avail.size()))


func _open_upgrade_ui() -> void:
	# Wellen-Modus (Runde 9): KEINE Level-Up-Karten — Upgrades gibt es nur im
	# Shop nach einer geschafften Welle. Sonst doppelte Progression.
	if host.game_mode == 1:
		host.pending_upgrades = 0
		host.ui_manager.hide_upgrade_cards()
		host.ui_manager.hide_upgrade_toast()
		if host.get_tree().paused:
			host.get_tree().paused = false
		return
	# Runde 136 (H1): Im Einzelspieler wird NICHT mehr sofort pausiert. Erst
	# kommt ein Toast, das Spiel laeuft weiter. Die Karten oeffnen sich erst
	# auf Tipp (H2).
	if not ((host.coop_host or host.coop_client) and NetManager.active):
		_on_upgrade_earned()
		return
	SoundManager.play("levelup")
	var picks: Array = _upgrade_options()
	if picks.is_empty():
		host.pending_upgrades = 0
		host.ui_manager.hide_upgrade_toast()
		return
	# Runde 49: Der HOST schickt die Optionen an alle Clients, damit
	# deren Upgrade-Fenster aufgeht. Der Client oeffnet es selbst.
	if host.coop_host and NetManager.active:
		NetManager.h_send_upgrade_options(picks)
		host._ldiag("UPGRADE", "Host schickt %d Optionen an Clients" % picks.size())
	host._ldiag("UPGRADE", "Host oeffnet Karten -> paused=%s, pending=%d" % [str(host._should_pause_for_cards()), host.pending_upgrades])
	if host._should_pause_for_cards():
		host.get_tree().paused = true
	else:
		host.in_upgrade = true
		print("[B3][PAUSE] Host waehlt Karten - Welt laeuft weiter (kein tree.paused im Co-op)")
	host.ui_manager.show_upgrade_cards(picks, 1, maxi(1, host.pending_upgrades))


func _on_upgrade_chosen(id: String) -> void:
	# Runde 49: Der Client schickt seine Wahl an den HOST, der Host
	# wendet sie an UND broadcastet sie, damit auch der andere Client
	# die Stats wirklich bekommt (vorher passierte dort nichts).
	if host.coop_client and NetManager.active:
		NetManager.c_send_upgrade_choice(int(host.my_slot), id)
		host._ldiag("UPGRADE", "Client schickt Wahl '%s' an Host, warte auf Bestaetigung (tree bleibt PAUSED)" % id)
		return
	_apply_upgrade_local(id)
	if host.coop_host and NetManager.active:
		NetManager.h_send_upgrade_applied(int(host.my_slot), id)
	host.pending_upgrades -= 1
	if host.coop_host and NetManager.active:
		# Co-op: alte Logik (Optionen direkt weitergeben, keine Pause)
		if host.pending_upgrades > 0 and host.current_state == GameState.PLAYING:
			host.get_tree().paused = false
			_open_upgrade_ui()
		else:
			host.in_upgrade = false
			host.get_tree().paused = false
		return
	# Runde 136 (H2): nach der Wahl geht es sofort weiter. Ist noch etwas
	# offen, kommt der Toast mit dem Rest zurueck - dann tippt man erneut.
	host.pending_upgrades = maxi(0, host.pending_upgrades)
	host.in_upgrade = false
	host.ui_manager.hide_upgrade_cards()
	if host.get_tree().paused:
		host.get_tree().paused = false
	if host.pending_upgrades > 0 and host.current_state == GameState.PLAYING:
		host._upg_toast_was_open = false
		_on_upgrade_earned()
	else:
		host.pending_upgrades = 0
		host.ui_manager.hide_upgrade_toast()
		host._upg_toast_was_open = false
	print("[UPG][DONE] rest=%d" % host.pending_upgrades)


func _apply_upgrade_local(id: String) -> void:
	# Runde 49: Die eigentliche Wirkung - fuer Host UND Client getrennt
	# anwendbar, damit die Stats beim Client nicht fehlen.
	host.upg_stacks[id] = int(host.upg_stacks.get(id, 0)) + 1
	if not is_instance_valid(host.player):
		return
	match id:
		"power":
			host.player.damage_mult *= 1.25
		"turbo":
			host.player.cooldown_mult *= 0.85
		"speed":
			host.player.speed_mult *= 1.15
		"vitality":
			host.player.call("add_max_health")
		"guardian":
			host.player.call("add_shield", 2)
		"vampire":
			host.player.vampire_per = 12


func _on_upgrade_earned() -> void:
	# H1: Toast zeigen, Spiel laeuft weiter.
	var picks: Array = _upgrade_options()
	if picks.is_empty():
		host.pending_upgrades = 0
		host.ui_manager.hide_upgrade_toast()
		print("[UPG][TOAST] kein Upgrade mehr verfuegbar (alles ausgeschoepft)")
		return
	if not host._upg_toast_was_open:
		SoundManager.play("levelup")
	host._upg_toast_was_open = true
	host.in_upgrade = false
	host.ui_manager.show_upgrade_toast(host.pending_upgrades)
	print("[UPG][TOAST] verfuegbar=%d paused=%s" % [host.pending_upgrades, str(host.get_tree().paused)])
	host._ldiag("UPGRADE", "Toast statt Pause: verfuegbar=%d, tree.paused=%s" % [host.pending_upgrades, str(host.get_tree().paused)])


func _on_upgrade_toast_tapped() -> void:
	# H2: erst jetzt pausieren und die Karten zeigen.
	if host.current_state != GameState.PLAYING:
		host.ui_manager.hide_upgrade_toast()
		host._upg_toast_was_open = false
		print("[UPG][TOAST] entfernt (run vorbei)")
		return
	if host.pending_upgrades <= 0:
		host.ui_manager.hide_upgrade_toast()
		host._upg_toast_was_open = false
		return
	var picks: Array = _upgrade_options()
	if picks.is_empty():
		host.pending_upgrades = 0
		host.ui_manager.hide_upgrade_toast()
		host._upg_toast_was_open = false
		print("[UPG][DONE] rest=0 (keine Optionen mehr)")
		return
	var total: int = maxi(1, host.pending_upgrades)
	host.ui_manager.hide_upgrade_toast()
	host._upg_toast_was_open = true
	host.get_tree().paused = true
	host.in_upgrade = true
	host.ui_manager.show_upgrade_cards(picks, 1, total)
	print("[UPG][WINDOW] offen idx=1 von %d" % total)
