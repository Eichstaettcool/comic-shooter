class_name WeaponsModule
extends RefCounted

# Runde 138: Waffen-Daten aus player_controller.gd
var host: Node = null

# Spiegel von player_controller.gd - Enum ist nicht ueber host erreichbar,
# Reihenfolge muss identisch bleiben.
enum WeaponType { PISTOL, SHOTGUN, MACHINE, LASER, REVOLVER }

const WEAPON_DATA = {
	WeaponType.PISTOL: { "name": "pistol", "damage": 3, "cooldown": 0.4, "speed": 300.0, "mag": 0, "reload": 0.0 },
	WeaponType.SHOTGUN: { "name": "shotgun", "damage": 5, "cooldown": 0.8, "speed": 250.0, "spread": 3, "mag": 6, "reload": 2.4 },
	# Runde 49: SMG und Laser bekommen ein Magazin + Nachladezeit
	WeaponType.MACHINE: { "name": "machine", "damage": 2, "cooldown": 0.1, "speed": 350.0, "mag": 40, "reload": 2.2 },
	WeaponType.LASER: { "name": "laser", "damage": 2, "cooldown": 0.14, "speed": 560.0, "mag": 24, "reload": 1.6 },
	# Runde 136 (J3): 9 -> 11. Mit Magazin+Reload lag der Revolver sonst bei
	# Faktor 0,67 gegenueber dem Mittel der fuenf Waffen.
	WeaponType.REVOLVER: { "name": "revolver", "damage": 11, "cooldown": 1.05, "speed": 420.0, "mag": 6, "reload": 1.9 }
}
const RARITY_NAMES := ["common", "rare", "epic", "legendary"]
const RARITY_LABEL := { "common": "GEWÖHNLICH", "rare": "SELTEN", "epic": "EPISCH", "legendary": "LEGENDÄR" }
const RARITY_COLOR := {
	"common": Color(0.72, 0.74, 0.78),
	"rare": Color(0.35, 0.65, 0.95),
	"epic": Color(0.72, 0.45, 0.95),
	"legendary": Color(0.99, 0.72, 0.20),
}
const RARITY_WEIGHTS := { "common": 62.0, "rare": 26.0, "epic": 9.0, "legendary": 3.0 }
const WEAPON_RARITY := {
	# v1.42 (P2): "cooldown" ist der Faktor auf die Schussfolge. v1.41 skalierte
	# nur damage/reload/mag/speed - jede Stufe feuerte gleich schnell und fuehlte
	# sich deshalb identisch an. Untergrenze in _wd(): 0.05 s.
	"common":    { "damage": 1.00, "reload": 1.00, "mag": 1.00, "speed": 1.00, "cooldown": 1.00 },
	"rare":      { "damage": 1.30, "reload": 0.86, "mag": 1.20, "speed": 1.05, "cooldown": 0.88 },
	"epic":      { "damage": 1.65, "reload": 0.74, "mag": 1.45, "speed": 1.10, "cooldown": 0.76 },
	"legendary": { "damage": 2.10, "reload": 0.60, "mag": 1.75, "speed": 1.18, "cooldown": 0.62 },
}
# v1.42 (P2.2): kuerzeste erlaubte Schussfolge
const MIN_COOLDOWN := 0.05
# v1.42 (P2.5): Kurztexte je Stufe (DE/EN liegen in Loc)
const RARITY_DESC := {
	"common": "+0 % — Referenzstufe",
	"rare": "+30 % Schaden, −12 % Schussabstand, +20 % Magazin, −14 % Nachladen",
	"epic": "+65 % Schaden, −24 % Schussabstand, +45 % Magazin, −26 % Nachladen",
	"legendary": "+110 % Schaden, −38 % Schussabstand, +75 % Magazin, −40 % Nachladen",
}


func roll_weapon_rarity() -> String:
	var total: float = 0.0
	for k in RARITY_WEIGHTS:
		total += float(RARITY_WEIGHTS[k])
	var roll := randf() * total
	var acc := 0.0
	for k in RARITY_NAMES:
		acc += float(RARITY_WEIGHTS[k])
		if roll <= acc:
			return str(k)
	return "common"


func rarity_mult(key: String, field: String) -> float:
	var r: String = str(host.weapon_rarity.get(key, "common"))
	var tab: Dictionary = WEAPON_RARITY.get(r, WEAPON_RARITY["common"])
	return float(tab.get(field, 1.0))


func weapon_key_of(t: int) -> String:
	return "weapon_" + str(WEAPON_DATA[t]["name"])


func _wd(t: int = -1) -> Dictionary:
	# Effektive Werte der Waffe inklusive Seltenheitsstufe
	var tt: int = host.current_weapon if t < 0 else t
	var base: Dictionary = WEAPON_DATA[tt]
	var key: String = weapon_key_of(tt)
	var out: Dictionary = base.duplicate()
	out["damage"] = maxi(1, int(round(float(base["damage"]) * rarity_mult(key, "damage"))))
	out["speed"] = float(base["speed"]) * rarity_mult(key, "speed")
	# v1.42 (P2.2): Schussfolge skaliert mit der Stufe, Untergrenze 0.05 s
	out["cooldown"] = maxf(MIN_COOLDOWN, float(base["cooldown"]) * rarity_mult(key, "cooldown"))
	var mag: int = int(base.get("mag", 0))
	if mag > 0:
		out["mag"] = maxi(1, int(round(float(mag) * rarity_mult(key, "mag"))))
		out["reload"] = maxf(0.2, float(base.get("reload", 1.0)) * rarity_mult(key, "reload"))
	# P2.4: RPM = reine Schussfolge (ohne Nachladen), wie in der Statistik-UI
	out["rpm"] = int(round(60.0 / maxf(0.01, float(out["cooldown"]))))
	out["rarity"] = str(host.weapon_rarity.get(key, "common"))
	return out


func rarity_label(key: String) -> String:
	# v1.42 (P2.5): Stufe + Kurzbegruendung fuer die Anzeige
	var r: String = str(host.weapon_rarity.get(key, "common"))
	return "%s — %s" % [str(RARITY_LABEL.get(r, r)), str(RARITY_DESC.get(r, ""))]


func stats_by_key(key: String) -> Dictionary:
	# v1.42 (P2.4): Werte einer Waffe ueber ihren Schluessel ("weapon_machine")
	for t in WEAPON_DATA.keys():
		if weapon_key_of(int(t)) == key:
			return _wd(int(t))
	return {}


func rpm_of(t: int = -1) -> int:
	return int(_wd(t)["rpm"])


func effective_stats(t: int) -> Dictionary:
	# Fuer Logs/Anzeige: Waffe, Stufe und die daraus folgenden Werte
	var w: Dictionary = _wd(t)
	var out: Dictionary = {
		"waffe": str(w["name"]), "stufe": str(w.get("rarity", "common")),
		"schaden": int(w["damage"]), "tempo": float(w["cooldown"]),
		"mag": int(w.get("mag", 0)), "reload": float(w.get("reload", 0.0)),
		"speed": float(w["speed"]), "spread": int(w.get("spread", 1)),
		"rpm": int(w.get("rpm", 0)),
	}
	# v1.42 (P2.2): Belegzeile mit der tatsaechlichen Schussfolge der Stufe
	print("[WPN][STATS] waffe=%s stufe=%s cooldown=%.3f rpm=%d schaden=%d mag=%d reload=%.2f" % [
		str(out["waffe"]), str(out["stufe"]), float(out["tempo"]), int(out["rpm"]),
		int(out["schaden"]), int(out["mag"]), float(out["reload"])])
	return out


func dps_at(t: int, stufe: String) -> float:
	# DPS einer Waffe in einer bestimmten Stufe (Stufe wird nur kurz gesetzt)
	var key: String = weapon_key_of(t)
	var alt = host.weapon_rarity.get(key, "common")
	host.weapon_rarity[key] = stufe
	var d: float = dps_of(t)
	if alt == null:
		host.weapon_rarity.erase(key)
	else:
		host.weapon_rarity[key] = alt
	return d


func check_rarity_table() -> bool:
	# v1.42 (P2.1/P2.3/P2.6): Stufentabelle + Monotonie der DPS-Kurve belegen
	for stufe in RARITY_NAMES:
		var row: Dictionary = WEAPON_RARITY[stufe]
		print("[WPN][RARITY] stufe=%s cooldown_mult=%.2f damage_mult=%.2f reload_mult=%.2f mag_mult=%.2f" % [
			str(stufe), float(row["cooldown"]), float(row["damage"]),
			float(row["reload"]), float(row["mag"])])
	var ok := true
	for t in [WeaponType.PISTOL, WeaponType.SHOTGUN, WeaponType.MACHINE, WeaponType.LASER, WeaponType.REVOLVER]:
		var prev: float = 0.0
		var line: Array = []
		for stufe in RARITY_NAMES:
			var d: float = dps_at(t, str(stufe))
			line.append("%s=%.1f" % [str(stufe), d])
			if d < prev - 0.001:
				ok = false
			prev = d
		var ratio: float = dps_at(t, "legendary") / maxf(0.01, dps_at(t, "common"))
		print("[WPN][DPS] waffe=%s %s legendary_common=%.2f" % [
			str(WEAPON_DATA[t]["name"]), " ".join(line), ratio])
		if ratio < 2.5:
			ok = false
			print("[WPN][FEHLER] legendary/common nur %.2f (Ziel >= 2.5) waffe=%s" % [
				ratio, str(WEAPON_DATA[t]["name"])])
	print("[WPN][DPS] monoton=%s" % str(ok))
	return ok


func dps_of(t: int) -> float:
	# Schaden pro Sekunde inklusive Nachladen und Streuung
	var w: Dictionary = _wd(t)
	var dmg: float = float(w["damage"]) * float(w.get("spread", 1))
	var cd: float = float(w["cooldown"])
	var mag: int = int(w.get("mag", 0))
	if mag <= 0:
		return dmg / maxf(0.01, cd)
	return (dmg * float(mag)) / maxf(0.01, float(mag) * cd + float(w.get("reload", 1.0)))


func dps_table() -> Array:
	# J3: DPS-Tabelle ueber alle fuenf Waffen (Basis, ohne Stufenbonus)
	var out: Array = []
	var sum := 0.0
	for t in [WeaponType.PISTOL, WeaponType.SHOTGUN, WeaponType.MACHINE, WeaponType.LASER, WeaponType.REVOLVER]:
		var d: float = dps_of(t)
		sum += d
		out.append({ "waffe": str(WEAPON_DATA[t]["name"]), "dps": d })
	var mean: float = sum / maxf(1.0, float(out.size()))
	for row in out:
		row["faktor"] = float(row["dps"]) / maxf(0.01, mean)
		print("[WPN][BALANCE] waffe=%s dps=%.1f (Mittel=%.1f) faktor=%.2f" % [
			str(row["waffe"]), float(row["dps"]), mean, float(row["faktor"])])
	return out
