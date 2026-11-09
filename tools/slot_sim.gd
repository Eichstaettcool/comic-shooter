extends SceneTree
# E3-Beleg: 200.000 Simulationsspins -> RTP und Trefferquote.
# Aufruf: ./Godot.exe --headless --path project --script res://test_slot_sim_tmp.gd

func _init() -> void:
	var SM = load("res://scripts/slot_machine.gd")
	var r: Dictionary = SM.simulate(200000, 100)
	print("[SLOT][SIM] %d spins bet=%d: rtp=%.2f%% hit=%.2f%% jackpots=%d" % [
		int(r["spins"]), int(r["bet"]), float(r["rtp"]), float(r["hitrate"]), int(r["jackpots"])])
	print("[SLOT][SIM] analytisch: Trefferquote=%.2f%%" % float(SM.odds_hit_rate()))
	var rows: Array = SM.odds_table()
	for row in rows:
		print("   %-8s 3x=%6.1f  P3=%.4f%%  2x=%5.1f  P2=%.2f%%" % [
			str(row["key"]), float(row["pay3"]), float(row["chance3"]),
			float(row["pay2"]), float(row["chance2"])])
	quit()
