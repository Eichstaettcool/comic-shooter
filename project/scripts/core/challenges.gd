class_name Challenges
extends RefCounted

# v1.44 (C1/C2/C7): Aufgaben ("Challenges") - Datenmodell, Zustand, Belohnung.
#
# Bewusste Grenze (Spec v1.44 "Was NICHT geaendert wird"): es gibt noch KEINE
# Auswertung im Spielverlauf. Die Aufgaben, ihre Zustaende und die Belohnung
# sind aber echt - sie liegen im Profil und werden dort gespeichert.
#
# Zustaende: OFFEN  -> noch nicht angefangen (Karte gedimmt, Schloss)
#            LAEUFT -> in Arbeit (Akzentrahmen, Fortschrittsbalken)
#            ERLEDIGT -> geschafft, Belohnung abholbar (gruener Haken)
#            BELOHNT -> Belohnung gebucht (grau, Haken)
var host: Node = null

const OFFEN := "OFFEN"
const LAEUFT := "LAEUFT"
const ERLEDIGT := "ERLEDIGT"
const BELOHNT := "BELOHNT"

# C2: Aufgaben-Definitionen. v1.46 (B1): Es gibt nur noch EINE Quelle - die
# Definitionen in `challenge_run.gd` (12 Aufgaben, je drei Stufen). Dieses
# Modul haelt nur noch Zustand und Belohnung.
const RunDefs = preload("res://scripts/core/challenge_run.gd")


func defs() -> Array:
	return RunDefs.DEFS


func def_of(id: String) -> Dictionary:
	return RunDefs.def_of(id)


func _store() -> Dictionary:
	# Der Zustand liegt im game_manager (wird im Profil gespeichert).
	if host == null:
		return {}
	if typeof(host.get("challenges")) != TYPE_DICTIONARY:
		host.set("challenges", {})
	return host.get("challenges")


func ensure() -> void:
	# C1: jede ID genau einmal, fehlende Eintraege anlegen.
	var st: Dictionary = _store()
	var ids: Array = []
	var defs: Array = RunDefs.DEFS
	for d in defs:
		var id := str(d["id"])
		ids.append(id)
		if not st.has(id):
			st[id] = { "state": OFFEN, "progress": 0 }
	print("[CHAL][DEF] anzahl=%d ids=%s" % [defs.size(), ",".join(ids)])
	# v1.48 (C1): JEDE Aufgabe braucht eine Einschraenkung/ein Risiko.
	for d in defs:
		var teile: Array = []
		if str(d.get("startwaffe", "")) != "":
			teile.append("waffe=" + str(d["startwaffe"]).replace("weapon_", ""))
		var sp: Array = d.get("sperren", [])
		if not sp.is_empty():
			teile.append("sperren=" + "/".join(sp))
		if bool(d.get("kein_treffer", false)):
			teile.append("kein_treffer")
		if (d.get("zeit", []) as Array).size() > 0:
			teile.append("zeitlimit")
		print("[CHAL][REGEL] id=%s art=%s" % [str(d["id"]), ", ".join(teile) if not teile.is_empty() else "KEINE"])
	# v1.46 (B1): je Aufgabe die drei Stufen ausgeben (Runden + Diamanten) -
	# Beleg fuer "12 Aufgaben x 3 Stufen".
	for d in defs:
		var id2 := str(d["id"])
		var r: Array = d["runden"]
		var g: Array = d["gems"]
		print("[CHAL][DEF] id=%s ziel=%s einheit=%s stufen=leicht:%d/%d normal:%d/%d hart:%d/%d" % [
			id2, str(d["ziel"]), RunDefs.unit_of(id2),
			int(r[0]), int(g[0]), int(r[1]), int(g[1]), int(r[2]), int(g[2])])


func state_of(id: String) -> String:
	var st: Dictionary = _store()
	var e = st.get(id, {})
	if typeof(e) != TYPE_DICTIONARY:
		return OFFEN
	return str(e.get("state", OFFEN))


func progress_of(id: String) -> int:
	var st: Dictionary = _store()
	var e = st.get(id, {})
	if typeof(e) != TYPE_DICTIONARY:
		return 0
	return int(e.get("progress", 0))


func set_state(id: String, state: String, reward: int = -1) -> void:
	var st: Dictionary = _store()
	var e: Dictionary = st.get(id, { "state": OFFEN, "progress": 0 })
	e["state"] = state
	if reward >= 0:
		# v1.45 (C10): Die Belohnung haengt an der STUFE, in der gewonnen wurde.
		e["reward"] = reward
	st[id] = e
	host.set("challenges", st)
	print("[CHAL][ZUSTAND] id=%s zustand=%s belohnung=%d farbe=%s" % [
		id, state, int(e.get("reward", -1)), _farbe_zu_state(state)])


func set_progress(id: String, n: int) -> void:
	var st: Dictionary = _store()
	var e: Dictionary = st.get(id, { "state": OFFEN, "progress": 0 })
	e["progress"] = n
	st[id] = e
	host.set("challenges", st)


func counts() -> Dictionary:
	var out: Dictionary = { OFFEN: 0, LAEUFT: 0, ERLEDIGT: 0, BELOHNT: 0 }
	for d in RunDefs.DEFS:
		var s: String = state_of(str(d["id"]))
		out[s] = int(out.get(s, 0)) + 1
	return out


func _farbe_zu_state(state: String) -> String:
	match state:
		LAEUFT:
			return "gold"
		ERLEDIGT:
			return "gruen"
		BELOHNT:
			return "grau"
		_:
			return "gedimmt"


# C7: Belohnung genau einmal buchen. Der zweite Tap aendert nichts.
func claim(id: String) -> Dictionary:
	var d: Dictionary = def_of(id)
	if d.is_empty():
		print("[CHAL][BELOHNUNG] id=%s erneut=false gutschrift=false grund=unbekannt" % id)
		return { "ok": false, "gutschrift": false, "gems": int(host.gems) }
	var state: String = state_of(id)
	if state != ERLEDIGT:
		# Schon belohnt (oder noch nicht erledigt): nichts buchen, nichts doppelt zahlen.
		print("[CHAL][BELOHNUNG] id=%s erneut=false gutschrift=false grund=zustand_%s gems=%d" % [
			id, state, int(host.gems)])
		return { "ok": false, "gutschrift": false, "gems": int(host.gems) }
	# v1.45 (C10): Betrag der gewaehlten Stufe (im Zustand gespeichert),
	# sonst der alte Standardwert der Aufgabe.
	var st: Dictionary = _store()
	var e: Dictionary = st.get(id, {})
	var add: int = int(e.get("reward", (d["gems"] as Array)[1]))
	host.gems = int(host.gems) + add
	set_state(id, BELOHNT)
	# gems liegen in savegame.save (nicht im Profil) -> beides sichern
	if host.has_method("_save_high_score"):
		host.call("_save_high_score")
	if host.has_method("_save_profile"):
		host.call("_save_profile")
	var stufe_txt: String = str(e.get("stufe", "?"))
	print("[CHAL][BELOHNUNG] id=%s stufe=%s +%d gems=%d erneut=false gespeichert=true" % [
		id, stufe_txt, add, int(host.gems)])
	return { "ok": true, "gutschrift": true, "gems": int(host.gems), "add": add }


func reset_all() -> void:
	# Nur fuer Tests/Diag: alles zurueck auf OFFEN.
	var st: Dictionary = {}
	for d in RunDefs.DEFS:
		st[str(d["id"])] = { "state": OFFEN, "progress": 0 }
	host.set("challenges", st)
	print("[CHAL][RESET] aufgaben=%d zustand=OFFEN" % RunDefs.DEFS.size())
