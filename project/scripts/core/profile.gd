class_name ProfileModule
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null

# v1.39 D2: Profilformat mit stabilen IDs (Skins/Huete heissen, nicht nur Index)
const PROFILE_VERSION := 4

const HAT_RARITY := ["common", "common", "common", "rare", "rare", "common", "rare", "rare", "epic", "legendary",
	"legendary", "rare", "epic",
	"common", "common", "common", "common",
	"rare", "rare", "rare",
	"epic", "epic", "epic",
	"legendary", "legendary"]
const RIG_RARITY := ["common", "rare", "rare", "epic", "epic", "legendary", "epic", "legendary", "epic",
	"epic", "legendary",
	# v1.41 (N5): 3 legendaere + 3 epische Konzept-Skins (Nutzerwahl)
	"legendary", "legendary", "legendary", "epic", "epic", "epic"]


# v1.41 (S5): alte Index-Listen zum Umrechnen. Index i (v3) -> Name -> neuer Index.
const OLD_RIG_NAMES := ["STANDARD", "PANZERHELD", "NINJA", "ROBOTER", "COMIC-HELD", "MARS-MARSCHALL", "GEIST", "WIKINGER", "ALIEN", "SCHROTT-SCHÜTZE", "WÜSTENWANDERER", "DSCHUNGEL-SCOUT", "STRASSENKÄMPFER", "MARS-PLÜNDERER", "DSCHUNGEL-JÄGER", "ELEKTRO-TECHNIKER", "WIKINGER-RAIDER", "ROBO-AFFE", "VOLT-KOMMANDANT", "METEOR-GOLEM", "SPLITTER-KÖNIG", "STERNEN-WIKINGER", "SONNENBOSS", "URWALD-TITAN", "NEON-PHANTOM", "SPINNENMANN", "ZOMBIE", "KRISTALL-GOLEM", "SCHATTEN-KATZE"]
const OLD_HAT_NAMES := ["OHNE", "KAPPE", "COWBOY", "KRONE", "ZYLINDER", "WOLLMÜTZE", "PIRAT", "STROHHUT", "WIKINGER", "STERN", "HALO", "ANTENNE", "KRÖNCHEN", "STIRNBAND", "BRILLE", "ABZEICHEN", "RUCKSACK", "HÖRNER", "BLATTKRANZ", "ELEKTRO-ANTENNE", "MARS-VISIER", "KRISTALL-HALO", "DROHNE", "BLITZ-SCHWEIF", "SCHULTERPLATTEN", "STERNEN-HALO", "METEOR", "NEON-AURA", "STERNCHEN"]


func _load_profile() -> void:
	if not FileAccess.file_exists("user://profile.save"):
		return
	var f := FileAccess.open("user://profile.save", FileAccess.READ)
	if f == null:
		return
	var d = f.get_var()
	f.close()
	if typeof(d) == TYPE_DICTIONARY:
		var ver: int = int(d.get("version", 2))
		# v1.49: Vorab-Kaeufe (Trank/Bombe/Schnellfeuer) sind entfernt.
		var q_alt = d.get("quick", {})
		if typeof(q_alt) == TYPE_DICTIONARY and q_alt.size() > 0:
			print("[SHOP][MIGR] quick_buffs verworfen eintraege=%d grund=vorabkauf_entfernt_v149" % q_alt.size())
		host.p_name = str(d.get("name", "HELD"))
		host.p_color = int(d.get("color", 0))
		host.p_hat = clampi(int(d.get("hat", 0)), 0, HAT_RARITY.size() - 1)
		var u = d.get("unlocked", [0, 1])
		if typeof(u) == TYPE_ARRAY:
			host.unlocked_hats = u
		# Runde 47: Skins (Rigs) persistent - vorher gingen sie bei jedem
		# Neustart verloren, dadurch waren alle Skins wieder gesperrt
		var ur = d.get("unlocked_rigs", [0])
		if typeof(ur) == TYPE_ARRAY:
			host.unlocked_rigs = ur
		if not host.unlocked_rigs.has(0):
			host.unlocked_rigs.append(0)
		host.p_rig = int(d.get("p_rig", 0))
		if not host.unlocked_rigs.has(host.p_rig):
			host.p_rig = 0
		# v1.41 (S5): die IDs sind die Wahrheit - der Index wird daraus neu bestimmt
		var _rid: String = str(host.get_meta("p_rig_id", ""))
		var _hid: String = str(host.get_meta("p_hat_id", ""))
		if _rid != "":
			var _ri: int = TextureManager.RIG_NAMES.find(_rid)
			host.p_rig = _ri if _ri >= 0 else 0
		if _hid != "":
			var _hi: int = TextureManager.HAT_NAMES.find(_hid)
			host.p_hat = _hi if _hi >= 0 else 0
		# Meta-Progression (Runde 11)
		host.gold = int(d.get("gold", 0))
		host.xp_total = int(d.get("xp_total", 0))
		var uc = d.get("unlocked_colors", [0, 1])
		if typeof(uc) == TYPE_ARRAY:
			host.unlocked_colors = uc
		var um = d.get("unlocked_maps", ["earth"])
		if typeof(um) == TYPE_ARRAY:
			host.unlocked_maps = um
		host.active_map = str(d.get("active_map", "earth"))
		# Migration alter Profile ("meadow" -> "earth")
		for i in range(host.unlocked_maps.size()):
			if str(host.unlocked_maps[i]) == "meadow" or str(host.unlocked_maps[i]) == "desert" or str(host.unlocked_maps[i]) == "ice" or str(host.unlocked_maps[i]) == "lava":
				host.unlocked_maps[i] = "earth"
		if host.active_map == "meadow" or not host.is_map_unlocked(host.active_map):
			host.active_map = "earth"
		if not host.unlocked_maps.has("earth"):
			host.unlocked_maps.append("earth")
		host.best_run_xp = int(d.get("best_run_xp", 0))
		# v1.42 (P9.6): Rueckfall auf die REISE-Map statt auf das alte Biom "meadow"
		if not host.is_map_unlocked(host.active_map):
			host.active_map = "earth"
		# v1.48 (A1): Boosts aus alten Profilen verwerfen (kein Dialog, kein Absturz)
		var bs_alt = d.get("boosts", {})
		if typeof(bs_alt) == TYPE_DICTIONARY and bs_alt.size() > 0:
			print("[SHOP][MIGR] boosts verworfen eintraege=%d grund=funktion_entfernt_v148" % bs_alt.size())
		var asea = d.get("active_season", {})
		if typeof(asea) == TYPE_DICTIONARY:
			host.active_season = asea
		host.difficulty = int(d.get("difficulty", 1))
		# v1.42 (P4.1): Musiklautstaerke
		host.music_volume = clampi(int(d.get("music_volume", 80)), 0, 100)
		SoundManager.set_music_volume(host.music_volume)
		host.biome_flash_on = bool(d.get("biome_flash", true))
		host.aim_assist = int(d.get("aim_assist", 1))
		host.tip_shown = bool(d.get("tip_shown", false))
		var sunl = d.get("season_unlocks", {})
		if typeof(sunl) == TYPE_DICTIONARY:
			host.season_unlocks = sunl
		var smode = d.get("season_mode", {})
		if typeof(smode) == TYPE_DICTIONARY:
			host.season_mode = smode
		host.lang = str(d.get("lang", "de"))
		# v1.44 (C1): Aufgaben-Zustand
		var ch = d.get("challenges", {})
		if typeof(ch) == TYPE_DICTIONARY:
			host.challenges = ch
			print("[PROFILE][CHAL] geladen aufgaben=%d" % ch.size())
	# v1.41 (S5): jetzt sind alle Felder gelesen - die stabilen IDs (Namen)
	# sind die Wahrheit und werden auf die neuen Indizes aufgeloest.
	# v1.42 (P12.1): VORHER die rohen Zahlen begrenzen - alte Profile koennen
	# Indizes jenseits der vorhandenen Skins/Huete/Farben enthalten.
	_clamp_cosmetics()
	_resolve_ids_v4(d, int(d.get("version", 2)))
	_migrate_profile(d, int(d.get("version", 2)))
	_clamp_choice_indices()
	if host.p_name == "":
		host.p_name = "HELD"
	SoundManager.set_muted(bool(d.get("muted", false)))
	# v1.44 (K5): Jahreszeiten-Freischaltungen pruefen (kein Gratis-Freischalten)
	if host.has_method("season_migrate"):
		host.call("season_migrate")


func _clamp_cosmetics() -> void:
	# v1.42 (P12.1): Nach der Skin-Reduktion 29 -> 11 -> 17 koennen in alten
	# Profilen Indizes >= 17 stehen. Die werden beim Laden entfernt (mit Log),
	# sonst zeigt die Sammlung leere Kacheln und RIG_NAMES[i] laeuft ins Leere.
	var jobs: Array = [
		{ "feld": "rigs", "arr": host.unlocked_rigs, "max": TextureManager.RIG_NAMES.size() },
		{ "feld": "huete", "arr": host.unlocked_hats, "max": TextureManager.HAT_NAMES.size() },
		{ "feld": "farben", "arr": host.unlocked_colors, "max": TextureManager.COLOR_NAMES.size() },
	]
	for j in jobs:
		var arr: Array = j["arr"]
		var lim: int = int(j["max"])
		var keep: Array = []
		var seen: Dictionary = {}
		for v in arr:
			var iv: int = int(v)
			if iv < 0 or iv >= lim:
				continue
			if seen.has(iv):
				continue
			seen[iv] = true
			keep.append(iv)
		var weg: int = arr.size() - keep.size()
		if weg > 0:
			keep.sort()
			arr.clear()
			for k in keep:
				arr.append(int(k))
			print("[PROFILE][CLAMP] feld=%s entfernt=%d gueltig=%d" % [
				str(j["feld"]), weg, keep.size()])
		elif arr.size() > 0:
			print("[PROFILE][CLAMP] feld=%s entfernt=0 gueltig=%d" % [str(j["feld"]), arr.size()])


func _clamp_choice_indices() -> void:
	# Auswahl-Indizes begrenzen (sonst zeigt das Menue ein leeres Feld)
	if host.p_rig < 0 or host.p_rig >= TextureManager.RIG_NAMES.size() or not host.unlocked_rigs.has(host.p_rig):
		host.p_rig = 0
	if host.p_hat < 0 or host.p_hat >= TextureManager.HAT_NAMES.size():
		host.p_hat = 0
	if host.p_color < 0 or host.p_color >= TextureManager.COLOR_NAMES.size():
		host.p_color = 0
	print("[PROFILE][WAHL] skin=%d farbe=%d hut=%d (nach Clamp)" % [
		host.p_rig, host.p_color, host.p_hat])


func _save_profile() -> void:
	var f := FileAccess.open("user://profile.save", FileAccess.WRITE)
	if f:
		f.store_var({ "version": PROFILE_VERSION,
			"p_rig_id": str(host.get_meta("p_rig_id", _rig_id(int(host.p_rig)))),
			"p_hat_id": str(host.get_meta("p_hat_id", _hat_id(int(host.p_hat)))),
			"unlocked_rig_ids": _ids_for(host.unlocked_rigs, TextureManager.RIG_NAMES),
			"unlocked_hat_ids": _ids_for(host.unlocked_hats, TextureManager.HAT_NAMES),
			"name": host.p_name, "color": host.p_color, "hat": host.p_hat, "unlocked": host.unlocked_hats, "muted": SoundManager.muted,
			"unlocked_rigs": host.unlocked_rigs, "p_rig": host.p_rig,
			"gold": host.gold, "xp_total": host.xp_total, "unlocked_colors": host.unlocked_colors,
			"unlocked_maps": host.unlocked_maps, "active_map": host.active_map,
			"best_run_xp": host.best_run_xp, "active_season": host.active_season, "season_unlocks": host.season_unlocks,
			"season_mode": host.season_mode, "lang": host.lang,
			"difficulty": host.difficulty, "aim_assist": host.aim_assist, "tip_shown": host.tip_shown,
			"music_volume": host.music_volume, "biome_flash": host.biome_flash_on,
			"challenges": host.challenges })
		f.close()


func save_lang() -> void:
	# Runde 136 (K2): Sprache im Profil sichern
	_save_profile()
	print("[LOC][SAVE] lang=%s im Profil" % host.lang)


func unlock_hat(i: int) -> void:
	if not host.unlocked_hats.has(i):
		host.unlocked_hats.append(i)


func unlock_rig(i: int) -> void:
	# Runde 38: Character-Rig freischalten
	if not host.unlocked_rigs.has(i):
		host.unlocked_rigs.append(i)
	_save_profile()


func _cosmetic_catalog() -> Array:
	# Alle freischaltbaren Kosmetik-Items mit Seltenheit
	var out: Array = []
	for i in range(TextureManager.HAT_NAMES.size()):
		var rar: String = str(HAT_RARITY[i]) if i < HAT_RARITY.size() else "common"
		out.append({ "kind": "hat", "index": i, "rarity": rar, "name": str(TextureManager.HAT_NAMES[i]) })
	for i in range(TextureManager.RIG_NAMES.size()):
		var rar2: String = str(RIG_RARITY[i]) if i < RIG_RARITY.size() else "rare"
		out.append({ "kind": "skin", "index": i, "rarity": rar2, "name": str(TextureManager.RIG_NAMES[i]) })
	for i in range(TextureManager.PLAYER_COLORS.size()):
		out.append({ "kind": "color", "index": i, "rarity": "common", "name": str(TextureManager.COLOR_NAMES[i]) })
	return out


func _rig_id(idx: int) -> String:
	var i: int = clampi(idx, 0, TextureManager.RIG_NAMES.size() - 1)
	return str(TextureManager.RIG_NAMES[i])


func _hat_id(idx: int) -> String:
	var i: int = clampi(idx, 0, TextureManager.HAT_NAMES.size() - 1)
	return str(TextureManager.HAT_NAMES[i])


func _resolve_ids_v4(d: Dictionary, ver: int) -> void:
	# v1.41 (S5): Migration auf v4.
	#   1. IDs (p_rig_id/p_hat_id) ueber den NAMEN auf den neuen Index aufloesen.
	#   2. entfernte Namen -> STANDARD / OHNE (nur Log, keine Fehlermeldung).
	#   3. unlocked_*_ids filtern; fehlen sie ganz, ueber die ALTEN Indizes
	#      (Index -> alter Name -> neuer Name) umrechnen.
	var rig_id: String = str(d.get("p_rig_id", ""))
	var hat_id: String = str(d.get("p_hat_id", ""))
	var alt_rig: int = int(d.get("p_rig", 0))
	var alt_hat: int = int(d.get("hat", 0))
	if rig_id == "" and alt_rig >= 0 and alt_rig < OLD_RIG_NAMES.size():
		rig_id = str(OLD_RIG_NAMES[alt_rig])
	if hat_id == "" and alt_hat >= 0 and alt_hat < OLD_HAT_NAMES.size():
		hat_id = str(OLD_HAT_NAMES[alt_hat])
	var neuer_rig: int = TextureManager.RIG_NAMES.find(rig_id)
	var neuer_hat: int = TextureManager.HAT_NAMES.find(hat_id)
	var rig_weg: bool = neuer_rig < 0
	var hat_weg: bool = neuer_hat < 0
	if rig_weg:
		neuer_rig = 0
	if hat_weg:
		neuer_hat = 0
	host.p_rig = neuer_rig
	host.p_hat = neuer_hat
	host.set_meta("p_rig_id", str(TextureManager.RIG_NAMES[neuer_rig]))
	host.set_meta("p_hat_id", str(TextureManager.HAT_NAMES[neuer_hat]))
	# Freischaltungen: IDs bevorzugt, sonst alte Indizes umrechnen
	var rid_list: Array = d.get("unlocked_rig_ids", [])
	var hid_list: Array = d.get("unlocked_hat_ids", [])
	var rigs_neu: Array = _names_to_indices(rid_list, TextureManager.RIG_NAMES)
	if rigs_neu.is_empty():
		rigs_neu = _old_indices_to_new(d.get("unlocked_rigs", [0]), OLD_RIG_NAMES, TextureManager.RIG_NAMES)
	var hats_neu: Array = _names_to_indices(hid_list, TextureManager.HAT_NAMES)
	if hats_neu.is_empty():
		hats_neu = _old_indices_to_new(d.get("unlocked", [0]), OLD_HAT_NAMES, TextureManager.HAT_NAMES)
	if not rigs_neu.has(0):
		rigs_neu.push_front(0)
	if not hats_neu.has(0):
		hats_neu.push_front(0)
	host.unlocked_rigs = rigs_neu
	host.unlocked_hats = hats_neu
	host.set_meta("unlocked_rig_ids", _ids_for(rigs_neu, TextureManager.RIG_NAMES))
	host.set_meta("unlocked_hat_ids", _ids_for(hats_neu, TextureManager.HAT_NAMES))
	if ver < PROFILE_VERSION or rig_weg or hat_weg:
		print("[PROFILE][MIGR] von=v%d nach=v4 rig=%s->%s hut=%s->%s entfernt_rigs=%d entfernt_huete=%d" % [
			ver, rig_id if rig_id != "" else "?", str(TextureManager.RIG_NAMES[neuer_rig]),
			hat_id if hat_id != "" else "?", str(TextureManager.HAT_NAMES[neuer_hat]),
			OLD_RIG_NAMES.size() - TextureManager.RIG_NAMES.size(),
			OLD_HAT_NAMES.size() - TextureManager.HAT_NAMES.size()])


func _names_to_indices(ids: Array, namen: Array) -> Array:
	var out: Array = []
	for v in ids:
		var i: int = namen.find(str(v))
		if i >= 0 and not out.has(i):
			out.append(i)
	return out


func _old_indices_to_new(arr: Array, alte: Array, neue: Array) -> Array:
	var out: Array = []
	for v in arr:
		var i: int = int(v)
		if i < 0 or i >= alte.size():
			continue
		var n: int = neue.find(str(alte[i]))
		if n < 0:
			continue        # entfernter Skin/Hut - faellt still weg (nur Log oben)
		if not out.has(n):
			out.append(n)
	return out


func _migrate_profile(d: Dictionary, ver: int) -> void:
	# v1.41 (S5): Die eigentliche Migration passiert in _resolve_ids_v4() -
	# dort werden die stabilen IDs zuerst aufgeloest, erst danach gilt der
	# Index. Hier bleibt nur noch das Sichern des neuen Formats.
	if ver < PROFILE_VERSION:
		print("[PROFILE][MIGR] format v%d -> v%d gesichert" % [ver, PROFILE_VERSION])
		_save_profile()
		return
	# Neues Profil: wenn eine ID auf einen anderen Index zeigt, gewinnt die ID
	var p_rig: int = int(host.p_rig)
	var p_hat: int = int(host.p_hat)
	var rig_id: String = str(host.get_meta("p_rig_id", _rig_id(p_rig)))
	var hat_id: String = str(host.get_meta("p_hat_id", _hat_id(p_hat)))
	var ridx: int = TextureManager.RIG_NAMES.find(rig_id)
	if ridx >= 0 and ridx != p_rig:
		print("[PROFILE][MIGR] index korrigiert p_rig=%d -> %d (\"%s\")" % [p_rig, ridx, rig_id])
		host.p_rig = ridx
		if not host.unlocked_rigs.has(ridx):
			host.unlocked_rigs.append(ridx)
	var hidx: int = TextureManager.HAT_NAMES.find(hat_id)
	if hidx >= 0 and hidx != p_hat:
		print("[PROFILE][MIGR] index korrigiert p_hat=%d -> %d (\"%s\")" % [p_hat, hidx, hat_id])
		host.p_hat = hidx
		if not host.unlocked_hats.has(hidx):
			host.unlocked_hats.append(hidx)
	host.set_meta("p_rig_id", rig_id)
	host.set_meta("p_hat_id", hat_id)


func _ids_for(arr: Array, names: Array) -> Array:
	var out: Array = []
	for v in arr:
		var i: int = int(v)
		if i >= 0 and i < names.size():
			out.append(str(names[i]))
	return out
