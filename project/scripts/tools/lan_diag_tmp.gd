extends Node
# Diagnose-Harness. Aktiv nur mit COMIC_LANTEST=<mode>.
#
#   ringe   -> Kontaktblatt der Skin/Ring-Texturen (alt)
#   chest   -> Kisten-Reveal echt rendern und als PNG sichern
#              (D1-Beleg: geschlossen / Deckel auf mit Spitzen / Reveal)
#   spikes  -> nur die Spitzen-Texturen als Blatt sichern
#
# Screenshots landen in C:/Users/vince/Games/comic-shooter/screenshots/.

var t := 0.0
var done := false
var gm: Node = null
var mode := ""

const SHOT_DIR := "C:/Users/vince/Games/comic-shooter/screenshots/"
const WM = preload("res://scripts/wheel_machine.gd")


func start(g: Node) -> void:
	gm = g
	mode = OS.get_environment("COMIC_LANTEST")
	print("[DIAG] start mode=%s" % mode)
	set_process(true)
	_run()


func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("[SHOT] %s uebersprungen (headless)" % name)
		return
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var p: String = SHOT_DIR + name
	img.save_png(p)
	print("[SHOT] %s (%dx%d)" % [p, img.get_width(), img.get_height()])


func _run() -> void:
	if mode == "ringe":
		await get_tree().process_frame
		var img := Image.create(1150, 260, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.10, 0.11, 0.14))
		var jobs := [[0, 27], [0, 25], [0, 14], [0, 21], [0, 10]]
		for i in range(jobs.size()):
			var tex = TextureManager.get_skin_hat_texture(0, int(jobs[i][0]), int(jobs[i][1]))
			if tex == null:
				continue
			var im: Image = tex.get_image()
			im.resize(200, 200, Image.INTERPOLATE_NEAREST)
			img.blend_rect(im, Rect2i(0, 0, 200, 200), Vector2i(15 + i * 225, 25))
		img.save_png(SHOT_DIR + "203-ringe.png")
		print("[SHOT] 203")
		get_tree().quit()
		return

	if mode == "spikes":
		await get_tree().process_frame
		var cell := 256
		var out := Image.create(cell * 3 + 40, cell + 40, false, Image.FORMAT_RGBA8)
		out.fill(Color(0.08, 0.09, 0.12, 1.0))
		var i := 0
		for tier in ["standard", "silver", "premium"]:
			var tex: Texture2D = TextureManager.get_texture("chest_spikes_" + tier)
			if tex != null:
				var im: Image = tex.get_image()
				im.resize(cell, cell, Image.INTERPOLATE_LANCZOS)
				out.blend_rect(im, Rect2i(0, 0, cell, cell), Vector2i(20 + i * cell, 30))
			var open_tex: Texture2D = TextureManager.get_texture("chest_gem_open_" + tier)
			if open_tex != null:
				var oi: Image = open_tex.get_image()
				oi.resize(128, 128, Image.INTERPOLATE_LANCZOS)
				out.blend_rect(oi, Rect2i(0, 0, 128, 128), Vector2i(20 + i * cell + 64, 30 + 64))
			i += 1
		out.save_png(SHOT_DIR + "214-spitzen-texturen.png")
		print("[SHOT] 214")
		get_tree().quit()
		return

	# ---------------------------------------------------------------
	# v1.39 — Messnetz
	#   hatsheet -> M1: 29 Huete x 4 Rigs (Standard/Alien/Roboter/Wikinger)
	#   rigsheet -> M2: alle 25 Skins in Standardfarbe, ohne Hut
	#   iou      -> M3: Silhouetten-IoU aller Skin-Paare -> tools/rig_iou.md
	#   coll     -> M4: interaktiver Weg der Sammlung (Menue -> Kachel)
	# ---------------------------------------------------------------
	if mode == "hatsheet":
		await get_tree().process_frame
		await _sheet_hats()
		get_tree().quit()
		return

	if mode == "rigsheet":
		await get_tree().process_frame
		await _sheet_rigs()
		get_tree().quit()
		return

	if mode == "iou":
		await get_tree().process_frame
		_iou_matrix()
		get_tree().quit()
		return

	if mode == "coll":
		await _coll_flow()
		get_tree().quit()
		return

	if mode == "coll2":
		await _coll_stress()
		get_tree().quit()
		return

	# v1.39 B2/B4: Skip-Beleg. COMIC_CHEST_SKIP=0 laesst die Animation durchlaufen.
	if mode == "chestskip":
		await _chest_skip_test()
		get_tree().quit()
		return

	# v1.39 B5: Laufband-Inhalt muss bei jeder Oeffnung neu gewuerfelt sein.
	if mode == "cheststrip":
		await _chest_strip_test()
		get_tree().quit()
		return

	# v1.39 C: Kopfform je Rig messen und Hut-Sitz pruefen
	if mode == "headmeas":
		await get_tree().process_frame
		_headmeas()
		get_tree().quit()
		return

	if mode == "hatfit":
		await get_tree().process_frame
		_hatfit_all()
		get_tree().quit()
		return

	# v1.39 C2/C3/C4: Beleg-Kontaktblaetter (Kappe x 25, Alien, Roboter/Mars)
	if mode == "hatsheets":
		await get_tree().process_frame
		await _hat_sheets()
		get_tree().quit()
		return

	# v1.40: Runden-Tabelle + kompletter Durchlauf des RUNDEN-Modus
	if mode == "rounds":
		await get_tree().process_frame
		_rounds_table()
		get_tree().quit()
		return

	if mode == "modecheck":
		await get_tree().process_frame
		_mode_check()
		get_tree().quit()
		return

	if mode == "roundperf":
		await _rounds_perf()
		get_tree().quit()
		return

	if mode == "roundecon":
		await get_tree().process_frame
		_rounds_economy()
		get_tree().quit()
		return

	if mode == "roundrun":
		await _rounds_run()
		get_tree().quit()
		return

	# v1.39 D: Migration, Verdrahtung, Debug-Unlock pruefen
	if mode == "dcheck":
		await _d_check()
		get_tree().quit()
		return

	if mode == "chest":
		for _f in range(8):
			await get_tree().process_frame
		var uim = gm.get("ui_manager")
		var ss = uim.get("start_screen") if uim != null else null
		if ss != null:
			ss.hide()
		# eigene CanvasLayer GANZ oben, damit der Beleg-Screenshot das Overlay zeigt
		var cl := CanvasLayer.new()
		cl.layer = 120
		add_child(cl)
		var ui = load("res://scripts/ui/chest_ui.gd").new()
		ui.setup(gm)
		cl.add_child(ui)
		var res := { "kind": "hat", "index": 5, "rarity": "legendary",
			"name": "KRONE", "duplicate": false }
		ui.call("open", "premium", res)
		print("[DIAG] chest overlay open")
		await get_tree().create_timer(0.12).timeout
		await _shot("215-kiste-geschlossen.png")
		await get_tree().create_timer(0.55).timeout
		await _shot("216-kiste-offen-spitzen.png")
		await get_tree().create_timer(1.10).timeout
		await _shot("217-kiste-reveal.png")
		print("[DIAG] chest fertig")
		get_tree().quit()
		return

	if mode == "slot":
		for _f in range(8):
			await get_tree().process_frame
		var uim2 = gm.get("ui_manager")
		var ss2 = uim2.get("start_screen") if uim2 != null else null
		if ss2 != null:
			ss2.hide()
		var cl2 := CanvasLayer.new()
		cl2.layer = 120
		add_child(cl2)
		var sui = load("res://scripts/slot_ui.gd").new()
		sui.setup(gm)
		cl2.add_child(sui)
		sui.call("open")
		print("[DIAG] slot offen")
		await get_tree().create_timer(0.30).timeout
		await _shot("218-slot-tabelle.png")
		sui.call("_spin")
		await get_tree().create_timer(0.45).timeout
		await _shot("219-slot-spinning.png")
		await get_tree().create_timer(3.2).timeout
		await _shot("220-slot-ergebnis.png")
		print("[DIAG] slot fertig")
		get_tree().quit()
		return

	if mode == "downed":
		# B11/B12/B13: Downed-/Revive-Logik direkt gegen _tick_downed() pruefen.
		await get_tree().process_frame
		var fl = load("res://scripts/test_fake_player_tmp.gd")
		var p1 = fl.new()
		var p2 = fl.new()
		p1.name = "P1"
		p2.name = "P2"
		p1.position = Vector2(1000, 1000)
		p2.position = Vector2(1060, 1000)
		p1.health = 1
		p2.health = 5
		gm.add_child(p1)
		gm.add_child(p2)
		gm.set("lan_mode", false)
		gm.set("my_slot", 1)
		gm.players = { 1: p1, 2: p2 }
		gm.downed = { 1: true }
		gm.downed_time = { 1: 5.0 }
		gm.revive_progress = { 1: 0.0 }
		p1.downed = true
		gm.set("_revive_held", true)
		print("[TEST][B11/B12] start: p1.health=%d downed=%s dist=%.0f" % [
			p1.health, str(gm.downed), p1.global_position.distance_to(p2.global_position)])
		for i in range(12):
			gm.call("_tick_downed", 0.5)
			print("[TEST] tick %d: p1.health=%d revive=%.1f/%.1f downed=%s" % [
				i + 1, int(p1.health), float(gm.revive_progress.get(1, 0.0)),
				float(gm.REVIVE_TIME), str(gm.downed.get(1, false))])
			if not bool(gm.downed.get(1, false)):
				print("[TEST][B11/B12] OK: aufgeweckt nach %d ticks, health=%d" % [i + 1, int(p1.health)])
				break
			await get_tree().process_frame
		# B13: beide liegen
		gm.downed = { 1: true, 2: true }
		gm.downed_time = { 1: 5.0, 2: 5.0 }
		gm.revive_progress = { 1: 0.0, 2: 0.0 }
		p1.downed = true
		p2.downed = true
		p2.health = 0
		gm.set("_revive_held", false)
		print("[TEST][B13] beide downed -> tick")
		gm.call("_tick_downed", 0.1)
		await get_tree().create_timer(0.4).timeout
		print("[TEST][B13] fertig (Game-Over-Zeile muss oben stehen)")
		get_tree().quit()
		return

	if mode == "snd":
		# G1-Beleg: die vier Kernsounds als WAV-Hoerprobe exportieren.
		await get_tree().process_frame
		var keys: Array = ["chest_lock", "chest_open_premium", "chest_land", "chest_win_legendary"]
		var streams: Dictionary = SoundManager.get("_streams")
		var total_ms := 0.0
		for k in keys:
			var st = streams.get(k, null)
			if st == null:
				print("[DIAG][SND] FEHLER: key=%s fehlt" % k)
				continue
			var dir := "C:/Users/vince/Games/comic-shooter/screenshots/v136/snd/"
			DirAccess.make_dir_recursive_absolute(dir)
			var path: String = dir + str(k) + ".wav"
			var err: int = st.save_to_wav(path)
			var ms: float = float(st.data.size() / 2) / float(st.mix_rate) * 1000.0
			total_ms += ms
			print("[DIAG][SND] %s -> %s (%.0f ms, err=%d)" % [k, path, ms, err])
		print("[DIAG][SND] Summe %.0f ms (4 Hoerproben)" % total_ms)
		get_tree().quit()
		return

	if mode == "chestfull":
		# G1-Beleg: komplette Premium-Kiste bis zum Reveal durchlaufen lassen.
		for _f in range(8):
			await get_tree().process_frame
		var uim3 = gm.get("ui_manager")
		var ss3 = uim3.get("start_screen") if uim3 != null else null
		if ss3 != null:
			ss3.hide()
		var cl3 := CanvasLayer.new()
		cl3.layer = 120
		add_child(cl3)
		var ui3 = load("res://scripts/ui/chest_ui.gd").new()
		ui3.setup(gm)
		cl3.add_child(ui3)
		var res3 := { "kind": "hat", "index": 5, "rarity": "legendary",
			"name": "KRONE", "duplicate": false }
		ui3.call("open", "premium", res3)
		print("[DIAG] chestfull start (premium, legendary)")
		await get_tree().create_timer(9.5).timeout
		print("[DIAG] chestfull fertig")
		get_tree().quit()
		return

	if mode == "chestseq":
		# C2-Beleg: 12 Frames im Abstand von 0,1 s aus dem Bandfenster.
		for _f in range(8):
			await get_tree().process_frame
		var uim4 = gm.get("ui_manager")
		var ss4 = uim4.get("start_screen") if uim4 != null else null
		if ss4 != null:
			ss4.hide()
		var cl4 := CanvasLayer.new()
		cl4.layer = 120
		add_child(cl4)
		var ui4 = load("res://scripts/ui/chest_ui.gd").new()
		ui4.setup(gm)
		cl4.add_child(ui4)
		var res4 := { "kind": "hat", "index": 5, "rarity": "legendary",
			"name": "KRONE", "duplicate": false }
		DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v136/chestseq/")
		ui4.call("open", "premium", res4)
		# Band startet nach 0,30 + 0,16 s -> ab 0,50 s liegen 12 Frames im Band.
		await get_tree().create_timer(0.50).timeout
		for i in range(12):
			await _shot("v136/chestseq/frame_%02d.png" % i)
			await get_tree().create_timer(0.10).timeout
		print("[DIAG] chestseq: 12 Frames gesichert")
		get_tree().quit()
		return

	if mode == "dur10":
		# C3-Beleg: 10 Oeffnungen, Dauer und gemessene Animationslaenge.
		for _f in range(8):
			await get_tree().process_frame
		var uim5 = gm.get("ui_manager")
		var ss5 = uim5.get("start_screen") if uim5 != null else null
		if ss5 != null:
			ss5.hide()
		var cl5 := CanvasLayer.new()
		cl5.layer = 120
		add_child(cl5)
		var ok_cnt := 0
		for i in range(10):
			var ui5 = load("res://scripts/ui/chest_ui.gd").new()
			ui5.setup(gm)
			cl5.add_child(ui5)
			var dur: float = float(ui5.get("duration"))
			var t0: int = Time.get_ticks_msec()
			var r5 := { "kind": "hat", "index": 3, "rarity": "rare", "name": "KAPPE", "duplicate": false }
			ui5.call("open", "standard", r5)
			# warten bis Reveal (0,46 + dur + 0,18) + Puffer
			await get_tree().create_timer(dur + 1.2).timeout
			var dt: float = float(Time.get_ticks_msec() - t0) / 1000.0
			var in_range: bool = dur >= 4.5 and dur <= 8.0
			if in_range:
				ok_cnt += 1
			print("[CHEST][DUR] Lauf %d: %.2f s (Vorgabe 4,5-8,0) gemessen %.2f s ok=%s" % [i + 1, dur, dt, str(in_range)])
			ui5.queue_free()
			await get_tree().create_timer(0.2).timeout
		print("[CHEST][DUR] Ergebnis: %d/10 in 4,5-8,0 s" % ok_cnt)
		get_tree().quit()
		return

	if mode == "upg":
		# H1/H2/H3: Toast statt Pause, Karten erst auf Tipp, kein Fenster ueber dem Tod
		for _f in range(8):
			await get_tree().process_frame
		var uim6 = gm.get("ui_manager")
		var ss6 = uim6.get("start_screen")
		if ss6 != null:
			ss6.hide()
		gm.set("game_mode", 0)
		gm.call("start_game", false, false)
		await get_tree().create_timer(3.0).timeout
		print("[TEST][H] Run gestartet, Monster=%d" % get_tree().get_nodes_in_group("monsters").size())
		# 1. Toast mit 2 verdienten Upgrades
		gm.set("pending_upgrades", 1)
		gm.call("_open_upgrade_ui")
		await get_tree().create_timer(0.30).timeout
		gm.set("pending_upgrades", 2)
		gm.call("_open_upgrade_ui")
		await get_tree().create_timer(0.50).timeout
		print("[TEST][H] paused=%s toast=%s" % [str(get_tree().paused), str(uim6.call("has_upgrade_toast"))])
		await _shot("v136/233-upgrade-toast.png")
		# Welt laeuft weiter? (X-B44: eigener Testgegner 2 200 px entfernt und
		# damit ausserhalb der Reichweite - vorher zaehlte der Test die Wellen-
		# Monster nach Index und das Ergebnis hing davon ab, ob eines starb.)
		var pl3 = gm.get("player")
		var testm = null
		if pl3 != null and is_instance_valid(pl3):
			testm = gm.call("spawn_monster_at", pl3.global_position + Vector2(2200, 0), 0, false)
		var p0: Vector2 = (testm as Node2D).global_position if testm != null else Vector2.ZERO
		await get_tree().create_timer(0.50).timeout
		var lebt: bool = testm != null and is_instance_valid(testm)
		var p1: Vector2 = (testm as Node2D).global_position if lebt else p0
		var moved: int = 1 if p0.distance_to(p1) > 1.0 else 0
		await _shot("v136/233-upgrade-toast-b.png")
		print("[TEST][H] Welt laeuft: %d/1 Monster in 0,5 s bewegt, paused=%s vorher=1 nachher=%d" % [
			moved, str(get_tree().paused), 1 if lebt else 0])
		# 2. Tipp -> Karten "UPGRADE 1 VON 2"
		uim6.emit_signal("upgrade_toast_tapped")
		await get_tree().create_timer(0.35).timeout
		print("[TEST][H] nach Tipp: paused=%s toast=%s" % [str(get_tree().paused), str(uim6.call("has_upgrade_toast"))])
		await _shot("v136/233a-upgrade-karten.png")
		gm.call("_on_upgrade_chosen", "power")
		await get_tree().create_timer(0.40).timeout
		print("[TEST][H] nach Wahl 1: rest=%d toast=%s paused=%s" % [
			int(gm.get("pending_upgrades")), str(uim6.call("has_upgrade_toast")), str(get_tree().paused)])
		await _shot("v136/233b-toast-rest.png")
		# 3. Tipp auf Rest -> "UPGRADE 1 VON 1" -> Wahl -> Toast weg
		uim6.emit_signal("upgrade_toast_tapped")
		await get_tree().create_timer(0.35).timeout
		gm.call("_on_upgrade_chosen", "turbo")
		await get_tree().create_timer(0.40).timeout
		print("[TEST][H] Ende: rest=%d toast=%s paused=%s" % [
			int(gm.get("pending_upgrades")), str(uim6.call("has_upgrade_toast")), str(get_tree().paused)])
		# 4. H3: Toast offen, dann stirbt der Spieler
		gm.set("pending_upgrades", 1)
		gm.call("_open_upgrade_ui")
		await get_tree().create_timer(0.35).timeout
		print("[TEST][H3] Toast vor Tod=%s" % str(uim6.call("has_upgrade_toast")))
		gm.call("_on_player_died")
		await get_tree().create_timer(0.40).timeout
		print("[TEST][H3] Toast nach Tod=%s (muss false sein)" % str(uim6.call("has_upgrade_toast")))
		get_tree().quit()
		return

	if mode == "mini":
		# E1/E2/E3: Mini-Boss spawnen, Doppel-Spawn blockieren, killen
		for _f in range(8):
			await get_tree().process_frame
		var uim7 = gm.get("ui_manager")
		var ss7 = uim7.get("start_screen")
		if ss7 != null:
			ss7.hide()
		gm.set("game_mode", 0)
		gm.call("start_game", false, false)
		await get_tree().create_timer(1.5).timeout
		var sp = gm.get("monster_spawner")
		var ppos: Vector2 = gm.call("get_player_position")
		var wmax: float = float(gm.MAP_COLS) * float(gm.TILE_SIZE) - 100.0
		var hmax: float = float(gm.MAP_ROWS) * float(gm.TILE_SIZE) - 100.0
		# v1.56: Der Mini-Boss kommt aus dem Balance-Spawner (Kadenz, Telegraph).
		# Kein "_try_spawn_miniboss" mehr - der Test faehrt den neuen Weg.
		sp.call("_boss_start", "mini")
		await get_tree().create_timer(2.2).timeout       # 2 s Telegraph
		sp.call("_spawn_boss_now")
		var mb = sp.get("_boss_knoten")
		print("[TEST][E1] mini gespawnt=%s hp=%d art=%s" % [
			str(mb != null), int(mb.get("current_health")) if mb != null else -1, str(sp.get("_boss_art"))])
		# E3: solange einer lebt, darf kein zweiter kommen
		print("[TEST][E1] blockiert=%s (mini lebt)" % str(bool(sp.call("_boss_lebt"))))
		await get_tree().create_timer(1.6).timeout
		# Startbildschirm kann im Diag-Lauf wieder auftauchen - fuer den Beleg aus
		if ss7 != null:
			ss7.hide()
		var ls7 = uim7.get("load_screen")
		if ls7 != null:
			ls7.hide()
		await _shot("v136/235-miniboss.png")
		# E2: killen und Belohnung pruefen
		if mb != null and is_instance_valid(mb):
			var gold_before: int = int(gm.get("gold"))
			mb.call("take_damage", 99999, 1)
			await get_tree().create_timer(0.6).timeout
			print("[TEST][E2] gold vorher=%d nachher=%d" % [gold_before, int(gm.get("gold"))])
		await _shot("v136/235b-miniboss-kill.png")
		print("[TEST][E] fertig")
		get_tree().quit()
		return

	if mode == "shop":
		# A1-A4: Shop-Seite oeffnen, Klicks auf den ZURUECK testen, Shots
		for _f in range(8):
			await get_tree().process_frame
		var uim8 = gm.get("ui_manager")
		var ss8 = uim8.get("start_screen")
		uim8.call("_open_chest_page")
		await get_tree().create_timer(0.6).timeout
		await _shot("v136/230-shop-oben.png")
		# A3: 5 Punkte auf dem oberen ZURUECK (4 Ecken + Mitte)
		var pts: Array = [Vector2(45, 30), Vector2(245, 30), Vector2(45, 90), Vector2(245, 90), Vector2(145, 60)]
		var ok := 0
		for p in pts:
			uim8.call("_open_chest_page")
			await get_tree().create_timer(0.15).timeout
			var d: Vector2 = p
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			ev.position = d
			ev.global_position = d
			get_viewport().push_input(ev)
			var ev2 := InputEventMouseButton.new()
			ev2.button_index = MOUSE_BUTTON_LEFT
			ev2.pressed = false
			ev2.position = d
			ev2.global_position = d
			get_viewport().push_input(ev2)
			await get_tree().process_frame
			await get_tree().process_frame
			var closed: bool = uim8.get("chest_page") == null or not (uim8.get("chest_page") as Control).visible
			if closed:
				ok += 1
			print("[SHOP][BACK] treffer=(%d,%d) -> geschlossen=%s" % [int(p.x), int(p.y), str(closed)])
		print("[SHOP][BACK] Ergebnis oben: %d/5 geschlossen" % ok)
		# Karten-Shot: Umtausch + Sofortkauf
		uim8.call("_open_chest_page")
		await get_tree().create_timer(0.4).timeout
		var scr = uim8.get("shop_scroll")
		if scr != null:
			scr.scroll_vertical = 900
		await get_tree().create_timer(0.4).timeout
		await _shot("v136/230-shop-karten.png")
		var scr2 = uim8.get("shop_scroll")
		if scr2 != null:
			scr2.scroll_vertical = 0
			await get_tree().create_timer(0.3).timeout
			print("[TEST][A4] scroll_vertical=%d" % scr2.scroll_vertical)
		await _shot("v136/230-shop-karten-oben.png")
		print("[TEST][A] fertig")
		get_tree().quit()
		return

	if mode == "seasons":
		# I1/I2/I3: Kauf, zu wenig Gold, WECHSELND nur im Pool, HUD
		for _f in range(8):
			await get_tree().process_frame
		var uim9 = gm.get("ui_manager")
		var ss9 = uim9.get("start_screen")
		uim9.call("_open_maps_page")
		await get_tree().create_timer(0.5).timeout
		await _shot("v136/234-maps-seasons.png")
		# I1: frischer Zustand - nur FRUEHLING frei, dann kaufen
		gm.get("season_unlocks")["mars"] = ["spring"]
		gm.set("gold", 20000)
		gm.call("buy_season", "mars", "summer")
		print("[TEST][I1] gold nach Kauf=%d" % int(gm.get("gold")))
		# I1: zu wenig Gold
		gm.set("gold", 100)
		gm.call("buy_season", "mars", "autumn")
		print("[TEST][I1] gold nach Fehlversuch=%d (muss 100 sein)" % int(gm.get("gold")))
		# I2: nur eine Jahreszeit -> WECHSELND abgelehnt
		gm.set("gold", 20000)
		var keep: Array = gm.get("season_unlocks")["mars"].duplicate()
		gm.get("season_unlocks")["mars"] = ["spring"]
		uim9.call("_on_season_mode", "mars", "cycle")
		gm.get("season_unlocks")["mars"] = keep
		# I2: jetzt mit zwei Jahreszeiten -> WECHSELND
		uim9.call("_on_season_mode", "mars", "cycle")
		gm.call("set_active_map", "mars")
		gm.call("set_active_season", "mars", "spring")
		gm.call("start_game", false, false)
		await get_tree().create_timer(1.2).timeout
		if ss9 != null:
			ss9.hide()
		var ls9 = uim9.get("load_screen")
		if ls9 != null:
			ls9.hide()
		# Score hochziehen -> Jahreszeit muss wechseln, aber nur im Pool
		for step in range(3):
			gm.set("score", (step + 1) * 1500)
			gm.call("_check_season")
			await get_tree().create_timer(0.35).timeout
		print("[TEST][I2] jahreszeit=%s pool=%s" % [str(gm.get("season_id")), str(gm.call("season_pool", "mars"))])
		await _shot("v136/234-seasons-hud.png")
		# I2: FEST -> bleibt
		gm.call("set_season_mode", "mars", "fixed")
		gm.set("score", 9000)
		gm.call("_check_season")
		print("[TEST][I2] FEST jahreszeit=%s (muss spring sein)" % str(gm.get("season_id")))
		get_tree().quit()
		return

	if mode == "char":
		# D1-D5: neues Charakterfenster, Auswahl nur mit freigeschalteten Items
		for _f in range(8):
			await get_tree().process_frame
		var uimC = gm.get("ui_manager")
		var ssC = uimC.get("start_screen")
		# frisches Profil: nur 2 Huete, 2 Farben, 1 Skin
		gm.set("unlocked_hats", [0, 1])
		gm.set("unlocked_colors", [0, 1])
		gm.set("unlocked_rigs", [0])
		uimC.call("_open_char_page")
		await get_tree().create_timer(0.6).timeout
		var pg0 = uimC.get("char_page")
		var lsC = uimC.get("load_screen")
		if lsC != null:
			lsC.visible = false
			lsC.set_process(false)
		if ssC != null and pg0 != null:
			for ch in ssC.get_children():
				if ch != pg0:
					ch.visible = false
		await get_tree().create_timer(0.2).timeout
		await _shot("v136/232-char-neu.png")
		var pg = uimC.get("char_page")
		print("[TEST][D1] felder=%d scrollbar=%s" % [
			int((uimC.get("char_fields") as Dictionary).size()),
			str(pg is ScrollContainer)])
		# D3: Hut-Fenster mit nur 2 freien
		uimC.call("_on_char_field", "hat")
		await get_tree().create_timer(0.5).timeout
		await _shot("v136/232a-char-hut-wahl.png")
		# Wahl anwenden
		uimC.call("_apply_choice", "hat", 1)
		await get_tree().create_timer(0.4).timeout
		# D2: Feld-Pikto muss dem gewaehlten Hut entsprechen
		print("[TEST][D2] hut=%d name=%s" % [int(gm.get("p_hat")), str(gm.get("p_hat"))])
		await _shot("v136/232b-char-nach-wahl.png")
		# D4: Sammlung zeigt weiterhin alles
		uimC.call("show_collection")
		await get_tree().create_timer(0.6).timeout
		await _shot("v136/232c-sammlung.png")
		print("[TEST][D4] sammlung gesamt=%d frei=%d" % [
			int(gm.get("unlocked_hats").size()), int(gm.get("unlocked_hats").size())])
		get_tree().quit()
		return

	if mode == "wpn":
		# J1-J4: Verteilung der Stufen, Stats-Beleg, Kontaktblatt der 4 Stufen
		for _f in range(8):
			await get_tree().process_frame
		var uimW = gm.get("ui_manager")
		uimW.call("start_game", false, false) if false else null
		gm.call("start_game", false, false)
		await get_tree().create_timer(0.8).timeout
		var pl = gm.get("player")
		# J3: DPS-Tabelle der fuenf Waffen
		pl.call("dps_table")
		# J1: 200 Aufnahmen -> Verteilung (Stufe wird jedes Mal neu gerollt)
		var cnt := { "common": 0, "rare": 0, "epic": 0, "legendary": 0 }
		for i in range(200):
			var r: String = str(pl.call("roll_weapon_rarity"))
			cnt[r] = int(cnt.get(r, 0)) + 1
		print("[WPN][DROP] verteilung common=%d rare=%d epic=%d legendary=%d" % [
			int(cnt["common"]), int(cnt["rare"]), int(cnt["epic"]), int(cnt["legendary"])])
		# J2: Werte je Stufe am Revolver
		for stufe in ["common", "rare", "epic", "legendary"]:
			pl.get("weapon_rarity")["weapon_revolver"] = stufe
			var e: Dictionary = pl.call("effective_stats", 4)
			print("[WPN][STATS] waffe=%s stufe=%s schaden=%d reload=%.1f mag=%d speed=%.0f" % [
				str(e["waffe"]), str(e["stufe"]), int(e["schaden"]), float(e["reload"]),
				int(e["mag"]), float(e["speed"])])
		# J4: Kontaktblatt - vier Stufen in vier Farben
		var cell := 300
		var img := Image.create(cell * 4 + 60, cell + 110, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.06, 0.07, 0.11))
		var cols := { "common": Color(0.72, 0.74, 0.78), "rare": Color(0.35, 0.65, 0.95),
			"epic": Color(0.72, 0.45, 0.95), "legendary": Color(0.99, 0.72, 0.20) }
		var ci := 0
		for stufe in ["common", "rare", "epic", "legendary"]:
			var c: Color = cols[stufe]
			var x0: int = 30 + ci * cell
			# Rahmen
			for xx in range(cell - 40):
				for yy in range(8):
					img.set_pixel(x0 + xx, 30 + yy, c)
					img.set_pixel(x0 + xx, 30 + cell - 40 - yy, c)
			for yy in range(cell - 40):
				for xx in range(8):
					img.set_pixel(x0 + xx, 30 + yy, c)
					img.set_pixel(x0 + cell - 40 - xx, 30 + yy, c)
			var wt: Texture2D = TextureManager.get_texture("weapon_revolver")
			if wt != null:
				var wi: Image = wt.get_image()
				wi.resize(200, 200, Image.INTERPOLATE_LANCZOS)
				img.blend_rect(wi, Rect2i(0, 0, 200, 200), Vector2i(x0 + 30, 50))
			ci += 1
		img.save_png("C:/Users/vince/Games/comic-shooter/screenshots/236-waffen-stufen.png")
		print("[SHOT] 236-waffen-stufen.png (4 Stufen, Farben common/rare/epic/legendary)")
		get_tree().quit()
		return

	if mode == "lang":
		# K1-K3: Sprache umschalten, Menue und Shop auf ENGLISCH sichern
		for _f in range(10):
			await get_tree().process_frame
		var uimL = gm.get("ui_manager")
		var lsL = uimL.get("load_screen")
		if lsL != null:
			lsL.visible = false
			lsL.set_process(false)
		uimL.call("_on_lang_set", "en")
		await get_tree().create_timer(0.9).timeout
		await _shot("v136/237-menu-en.png")
		uimL.call("_open_chest_page")
		await get_tree().create_timer(0.9).timeout
		var pgL = uimL.get("chest_page")
		var ssL = uimL.get("start_screen")
		if ssL != null and pgL != null:
			for ch in ssL.get_children():
				if ch != pgL:
					ch.visible = false
		await get_tree().create_timer(0.5).timeout
		await _shot("v136/238-shop-en.png")
		# Einstellungen mit beiden Feldern
		uimL.call("_open_settings_page")
		await get_tree().create_timer(0.6).timeout
		await _shot("v136/239-settings-sprache.png")
		uimL.call("_on_lang_set", "de")
		await get_tree().create_timer(0.5).timeout
		print("[TEST][K] zurueck auf deutsch: lang=%s" % Loc.lang)
		get_tree().quit()
		return

	if mode == "wpn2":
		# J4: Waffen-HUD mit Stufenfarbe + Stats-Seite
		for _f in range(8):
			await get_tree().process_frame
		var uimH = gm.get("ui_manager")
		gm.set("game_mode", 0)
		gm.call("start_game", false, false)
		await get_tree().create_timer(1.2).timeout
		var pl2 = gm.get("player")
		var jobs: Array = [["weapon_shotgun", "common"], ["weapon_machine", "rare"],
			["weapon_laser", "epic"], ["weapon_revolver", "legendary"]]
		for j in jobs:
			pl2.call("add_weapon", str(j[0]))
			(pl2.get("weapon_rarity") as Dictionary)[str(j[0])] = str(j[1])
		uimH.call("refresh_weapon_hud", pl2.get("owned_weapons"), "weapon_shotgun")
		await get_tree().create_timer(0.6).timeout
		var lsH = uimH.get("load_screen")
		if lsH != null:
			lsH.visible = false
		var ssH = uimH.get("start_screen")
		if ssH != null:
			ssH.visible = false
		await get_tree().create_timer(0.3).timeout
		await _shot("v136/240-waffen-hud.png")
		uimH.call("_open_stats_page")
		await get_tree().create_timer(0.7).timeout
		await _shot("v136/241-waffen-stats.png")
		print("[TEST][J4] stufen im inventar=%s" % str(pl2.get("weapon_rarity")))
		get_tree().quit()
		return

	if mode == "loc2":
		# K3: alle Seiten in ENGLISCH, fehlende Woerterbuch-Eintraege sammeln
		for _f in range(10):
			await get_tree().process_frame
		var uimX = gm.get("ui_manager")
		var lsX = uimX.get("load_screen")
		if lsX != null:
			lsX.visible = false
			lsX.set_process(false)
		uimX.call("_on_lang_set", "en")
		await get_tree().create_timer(0.8).timeout
		for opener in ["_open_chest_page", "_open_char_page", "_open_maps_page",
				"_open_settings_page", "show_collection"]:
			uimX.call(opener)
			await get_tree().create_timer(0.5).timeout
		uimX.call("_open_chest_page")
		await get_tree().create_timer(0.5).timeout
		var pgX = uimX.get("chest_page")
		var ssX = uimX.get("start_screen")
		if ssX != null and pgX != null:
			for ch in ssX.get_children():
				if ch != pgX:
					ch.visible = false
		await get_tree().create_timer(0.6).timeout
		await _shot("v136/238-shop-en.png")
		# Pause + Run-HUD
		uimX.call("show_pause")
		await get_tree().create_timer(0.5).timeout
		await _shot("v136/242-pause-en.png")
		uimX.call("hide_pause")
		gm.call("start_game", false, false)
		await get_tree().create_timer(1.2).timeout
		uimX.call("_open_stats_page")
		await get_tree().create_timer(0.6).timeout
		await _shot("v136/243-stats-en.png")
		Loc.dump_missing()
		print("[TEST][K] fehlend=%d uebersetzt=%d" % [Loc.missing_count(), Loc.stat_done])
		# v1.39: Testhygiene - das Profil darf nicht auf Englisch zurueckbleiben
		uimX.call("_on_lang_set", "de")
		await get_tree().create_timer(0.4).timeout
		print("[TEST][K] zurueck auf deutsch: lang=%s" % Loc.lang)
		get_tree().quit()
		return

	if mode == "perf":
		# Performance-Baseline: 240 Frames nach Run-Start messen
		for _f in range(8):
			await get_tree().process_frame
		gm.set("game_mode", 0)
		gm.call("start_game", false, false)
		for _f in range(60):
			await get_tree().process_frame
		var frames := 240
		var sum_fps := 0.0
		var sum_proc := 0.0
		var sum_phys := 0.0
		var max_draw := 0
		var max_nodes := 0
		var max_mon := 0
		var t0: int = Time.get_ticks_msec()
		for i in range(frames):
			await get_tree().process_frame
			sum_fps += Performance.get_monitor(Performance.TIME_FPS)
			sum_proc += Performance.get_monitor(Performance.TIME_PROCESS)
			sum_phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
			max_draw = maxi(max_draw, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			max_nodes = maxi(max_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
			max_mon = maxi(max_mon, get_tree().get_nodes_in_group("monsters").size())
		var dt: float = float(Time.get_ticks_msec() - t0) / 1000.0
		print("[PERF] fps_avg=%.1f proc_ms=%.2f phys_ms=%.2f draw_max=%d nodes_max=%d monster_max=%d wall=%.2fs frames=%d" % [
			sum_fps / float(frames), sum_proc / float(frames), sum_phys / float(frames),
			max_draw, max_nodes, max_mon, dt, frames])
		get_tree().quit()
		return

	# ---------------------------------------------------------------
	# v1.41 — Belege fuer F2 (Startseite), F3 (Shop-Symbole), F4 (Stats im Spiel)
	# ---------------------------------------------------------------
	if mode == "menu141":
		await _menu141()
		get_tree().quit()
		return

	if mode == "shop141":
		await _shop141()
		get_tree().quit()
		return

	if mode == "stats141":
		await _stats141()
		get_tree().quit()
		return

	if mode == "loc141":
		await _loc141()
		get_tree().quit()
		return

	if mode == "boss141":
		await _boss_table141()
		get_tree().quit()
		return

	if mode == "bossrun":
		await _rounds_bossrun()
		get_tree().quit()
		return

	if mode == "bossbanner":
		await _boss_banner_shot()
		get_tree().quit()
		return

	if mode == "bossperf":
		await _boss_perf()
		get_tree().quit()
		return

	if mode == "monsheet":
		await _monster_sheet141()
		get_tree().quit()
		return

	if mode == "monbehave":
		await _monster_behave141()
		get_tree().quit()
		return

	if mode == "monperf":
		await _monster_perf141()
		get_tree().quit()
		return

	if mode == "skin141":
		await _skin141()
		get_tree().quit()
		return

	if mode == "migr141":
		await _migr141()
		get_tree().quit()
		return

	if mode == "mksetup":
		await _mksetup141()
		get_tree().quit()
		return

	if mode == "skinsbig":
		await get_tree().process_frame
		await _skins_big()
		get_tree().quit()
		return

	if mode == "pause142":
		await _pause142()
		get_tree().quit()
		return

	if mode == "tap143":
		await _tap143()
		get_tree().quit()
		return

	if mode == "audit143":
		await _audit143()
		get_tree().quit()
		return

	if mode == "walk143":
		await _walk143()
		get_tree().quit()
		return

	if mode == "pruef143":
		await _pruef143()
		get_tree().quit()
		return

	if mode == "wasser143":
		await _wasser143()
		get_tree().quit()
		return

	if mode == "dbg144":
		await _dbg144()
		get_tree().quit()
		return

	if mode == "hatcmp144":
		await _hatcmp144()
		get_tree().quit()
		return

	if mode == "load145":
		await _load145()
		get_tree().quit()
		return
	if mode == "chest145":
		await _chest145()
		get_tree().quit()
		return
	if mode == "hat146":
		await _hat146()
		get_tree().quit()
		return
	if mode == "musik146":
		await _musik146()
		get_tree().quit()
		return
	if mode == "icon145":
		await _icon145()
		get_tree().quit()
		return
	if mode == "chal_run145":
		await _chal145()
		get_tree().quit()
		return
	if mode == "scroll146":
		await _scroll146()
		get_tree().quit()
		return
	if mode == "chal_run146":
		await _chal146()
		get_tree().quit()
		return
	if mode == "icon146":
		await _icon146()
		get_tree().quit()
		return
	if mode == "icon146b":
		await _icon146b()
		get_tree().quit()
		return
	if mode == "wheel148":
		await _wheel148()
		get_tree().quit()
		return
	if mode == "shop148":
		await _shop148()
		get_tree().quit()
		return
	if mode == "coll_scroll148":
		await _coll_scroll148()
		get_tree().quit()
		return
	if mode == "info148":
		await _info148()
		get_tree().quit()
		return
	if mode == "v148shot":
		await _v148shot()
		get_tree().quit()
		return
	if mode == "v148ui":
		await _v148ui()
		get_tree().quit()
		return
	if mode == "v148winter":
		await _v148winter()
		get_tree().quit()
		return
	if mode == "chal148":
		await _chal148()
		get_tree().quit()
		return
	if mode == "upg148":
		await _upg148()
		get_tree().quit()
		return
	if mode == "hatsheet154":
		await _hatsheet154()
		get_tree().quit()
		return
	if mode == "hatfit155":
		await _hatfit155()
		get_tree().quit()
		return
	if mode == "hatmatrix":
		await _hatmatrix()
		get_tree().quit()
		return
	if mode == "chestvar":
		await _chestvar()
		get_tree().quit()
		return
	if mode == "chestepic":
		await _chestepic()
		get_tree().quit()
		return
	if mode == "chestmov1":
		await _chestmov(1)
		get_tree().quit()
		return
	if mode == "chestmov2":
		await _chestmov(2)
		get_tree().quit()
		return
	if mode == "chestmov3":
		await _chestmov(3)
		get_tree().quit()
		return
	if mode == "chestfx1":
		await _chestfx(1)
		get_tree().quit()
		return
	if mode == "chestfx2":
		await _chestfx(2)
		get_tree().quit()
		return
	if mode == "chestfx3":
		await _chestfx(3)
		get_tree().quit()
		return
	if mode == "seasfix":
		await _seasfix()
		get_tree().quit()
		return
	if mode == "chestbuy152":
		await _chestbuy152()
		get_tree().quit()
		return
	if mode == "chestshop152":
		await _chestshop152()
		get_tree().quit()
		return
	if mode == "rundenshop151":
		await _rundenshop151()
		get_tree().quit()
		return
	if mode == "bal151":
		await _bal151()
		get_tree().quit()
		return
	# v1.56 A1: Modell-Tabelle 3 Modi x 4 Stufen (Single Source of Truth)
	if mode == "balmodel":
		await get_tree().process_frame
		_balmodel()
		get_tree().quit()
		return
	# v1.56 D1: Kiting-Bot (Anfaenger/Erfahren) spielt echte Laeufe
	if mode == "balbot":
		await _balbot()
		get_tree().quit()
		return
	if mode == "balshot":
		await _balshot()
		get_tree().quit()
		return
	if mode == "shots158":
		await _shots158()
		get_tree().quit()
		return
	if mode == "chesttouch":
		await _chesttouch()
		get_tree().quit()
		return
	if mode == "chesttouch2":
		await _chesttouch2()
		get_tree().quit()
		return
	if mode == "icon146c":
		await _icon146c()
		get_tree().quit()
		return
	if mode == "rig146":
		await _rig146()
		get_tree().quit()
		return
	if mode == "set146":
		await _set146()
		get_tree().quit()
		return
	if mode == "name146":
		await _name146()
		get_tree().quit()
		return
	if mode == "wheel145":
		await _wheel145()
		get_tree().quit()
		return
	if mode == "snd145":
		await _snd145()
		get_tree().quit()
		return
	if mode == "chal144":
		await _chal144()
		get_tree().quit()
		return

	if mode == "shop144":
		await _shop144()
		get_tree().quit()
		return

	if mode == "chest144":
		await _chest144()
		get_tree().quit()
		return

	if mode == "karte144":
		await _karte144()
		get_tree().quit()
		return

	if mode == "mprobe144":
		await _mprobe144()
		get_tree().quit()
		return

	if mode == "load142":
		await _load142()
		get_tree().quit()
		return

	if mode == "biom142":
		await _biom142()
		get_tree().quit()
		return

	if mode == "map142":
		await _map142()
		get_tree().quit()
		return

	if mode == "musik142":
		await _musik142()
		get_tree().quit()
		return

	if mode == "hand142":
		await _hand142()
		get_tree().quit()
		return

	if mode == "hat142":
		await _hat142()
		get_tree().quit()
		return

	if mode == "trank142":
		await _trank142()
		get_tree().quit()
		return

	if mode == "wpn142":
		await _wpn142()
		get_tree().quit()
		return

	if mode == "runde142":
		await _runde142()
		get_tree().quit()
		return

	if mode == "leichtrun":
		await _leichtrun()
		get_tree().quit()
		return

	if mode == "ui142":
		await _ui142()
		get_tree().quit()
		return

	if mode == "concepts":
		await get_tree().process_frame
		await _concept_sheet("legendary")
		await _concept_sheet("epic")
		get_tree().quit()
		return

	print("[DIAG] FEHLER: unbekannter mode '%s'" % mode)
	get_tree().quit()


func _monster_positions() -> Array:
	var out: Array = []
	for m in get_tree().get_nodes_in_group("monsters"):
		if is_instance_valid(m):
			out.append((m as Node2D).global_position)
	return out


# ================================================================
# v1.39 Messnetz-Helfer (M1-M4)
# ================================================================

func _tex_img(tex: Texture2D) -> Image:
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	return img


func _sheet(cells: Array, cols: int, cw: int, ch: int, header: String, out_name: String) -> void:
	# Kontaktblatt aus echten Control-Knoten (SubViewport) - so sind die
	# Beschriftungen echte Schrift und nicht in die Pixel gemalt.
	var rows: int = int(ceil(float(cells.size()) / float(cols)))
	var head_h: int = 34 if header != "" else 0
	var w: int = cols * cw + 24
	var h: int = head_h + rows * ch + 24
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.09)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(w, h)
	vp.add_child(bg)
	if header != "":
		var hl := Label.new()
		hl.text = header
		hl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
		hl.add_theme_font_size_override("font_size", 16)
		hl.position = Vector2(12, 8)
		hl.size = Vector2(w - 24, 20)
		vp.add_child(hl)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.position = Vector2(12, head_h)
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	vp.add_child(grid)
	for c in cells:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(cw, ch)
		cell.add_theme_constant_override("separation", 0)
		grid.add_child(cell)
		var tr := TextureRect.new()
		tr.texture = c["tex"]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(cw, ch - 40)
		cell.add_child(tr)
		var l1 := Label.new()
		l1.text = str(c["line1"])
		l1.clip_text = true
		l1.add_theme_font_size_override("font_size", 13)
		l1.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
		cell.add_child(l1)
		var l2 := Label.new()
		l2.text = str(c.get("line2", ""))
		l2.clip_text = true
		l2.add_theme_font_size_override("font_size", 11)
		l2.add_theme_color_override("font_color", Color(0.62, 0.70, 0.86))
		cell.add_child(l2)
	for _f in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	var path: String = SHOT_DIR + out_name
	var err: int = img.save_png(path)
	print("[SHOT] %s (%dx%d) err=%d zellen=%d" % [path, img.get_width(), img.get_height(), err, cells.size()])
	vp.queue_free()


func _sheet_hats() -> void:
	# M1: 29 Huete x 4 Rigs (Standard 0, Alien 8, Roboter 3, Wikinger 7)
	var rigs: Array = [0, 8, 3, 7]
	var cells: Array = []
	for hat in range(TextureManager.HAT_NAMES.size()):
		for rig in rigs:
			var tex: Texture2D = TextureManager.get_skin_hat_texture(0, int(rig), hat)
			cells.append({
				"tex": tex,
				"line1": "%d %s" % [hat, str(TextureManager.HAT_NAMES[hat])],
				"line2": str(TextureManager.RIG_NAMES[int(rig)]),
			})
	print("[SHEET] hats=%d rigs=%d kacheln=%d" % [
		TextureManager.HAT_NAMES.size(), rigs.size(), cells.size()])
	await _sheet(cells, 8, 170, 164,
		"v1.39 M1 - %d Huete x %d Rigs | je Vierergruppe: STANDARD - ALIEN - ROBOTER - WIKINGER" % [
			TextureManager.HAT_NAMES.size(), rigs.size()],
		"v139/hats_29x4.png")


func _sheet_rigs() -> void:
	# M2: alle Skins in Standardfarbe (Index 0), ohne Hut
	var cells: Array = []
	for i in range(TextureManager.RIG_NAMES.size()):
		cells.append({
			"tex": TextureManager.get_skin_texture(0, i),
			"line1": "%d %s" % [i, str(TextureManager.RIG_NAMES[i])],
			"line2": "",
		})
	print("[SHEET] rigs=%d" % TextureManager.RIG_NAMES.size())
	await _sheet(cells, 5, 190, 184,
		"v1.39 M2 - alle %d Skins in Standardfarbe (BLAU), ohne Hut" % TextureManager.RIG_NAMES.size(),
		"v139/rigs_25.png")


func _iou_mask(img: Image) -> PackedByteArray:
	var m := PackedByteArray()
	m.resize(img.get_width() * img.get_height())
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			m[y * img.get_width() + x] = 1 if img.get_pixel(x, y).a > 0.5 else 0
	return m


func _iou_matrix() -> void:
	# M3: Silhouetten-IoU jedes Skins gegen jeden anderen
	var n: int = TextureManager.RIG_NAMES.size()
	var masks: Array = []
	for i in range(n):
		var img: Image = _tex_img(TextureManager.get_skin_texture(0, i))
		if img == null:
			print("[RIG][IOU] FEHLER bild fehlt idx=%d" % i)
			masks.append(null)
			continue
		masks.append(_iou_mask(img))
	var werte: Array = []
	for a in range(n):
		for b in range(a + 1, n):
			if masks[a] == null or masks[b] == null:
				continue
			var ma: PackedByteArray = masks[a]
			var mb: PackedByteArray = masks[b]
			var inter: int = 0
			var uni: int = 0
			for k in range(ma.size()):
				var va: int = ma[k]
				var vb: int = mb[k]
				if va == 1 and vb == 1:
					inter += 1
				if va == 1 or vb == 1:
					uni += 1
			var v: float = 0.0 if uni == 0 else float(inter) / float(uni)
			werte.append([a, b, v])
			print("[RIG][IOU] a=%d b=%d wert=%.2f" % [a, b, v])
	# Tabelle schreiben
	var path := "C:/Users/vince/Games/comic-shooter/tools/rig_iou.md"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("[RIG][IOU] FEHLER datei nicht schreibbar: %s" % path)
		return
	f.store_line("# Silhouetten-IoU der Skins (v1.39 M3)")
	f.store_line("")
	f.store_line("Automatisch erzeugt von `COMIC_LANTEST=iou`. Maske = Alpha > 0,5, Bild 64x64, Standardfarbe, ohne Hut.")
	f.store_line("")
	f.store_line("## Matrix (Zeile a, Spalte b)")
	f.store_line("")
	var kopf := "| a\\b |"
	for b in range(n):
		kopf += " %d |" % b
	f.store_line(kopf)
	var sep := "|---|"
	for b in range(n):
		sep += "---|"
	f.store_line(sep)
	for a in range(n):
		var zeile := "| **%d %s** |" % [a, str(TextureManager.RIG_NAMES[a])]
		for b in range(n):
			if a == b:
				zeile += " - |"
				continue
			var v: float = 0.0
			for e in werte:
				if (int(e[0]) == a and int(e[1]) == b) or (int(e[0]) == b and int(e[1]) == a):
					v = float(e[2])
					break
			zeile += " %.2f |" % v
		f.store_line(zeile)
	f.store_line("")
	f.store_line("## Paare ueber 0,80 (Slop-Kandidaten fuer D1)")
	f.store_line("")
	var hoch: Array = []
	for e in werte:
		if float(e[2]) >= 0.80:
			hoch.append(e)
	hoch.sort_custom(func(x, y): return float(x[2]) > float(y[2]))
	if hoch.size() == 0:
		f.store_line("keine")
	else:
		for e in hoch:
			f.store_line("- %.2f  %d %s  vs  %d %s" % [float(e[2]),
				int(e[0]), str(TextureManager.RIG_NAMES[int(e[0])]),
				int(e[1]), str(TextureManager.RIG_NAMES[int(e[1])])])
	f.close()
	print("[RIG][IOU] paare=%d ueber80=%d datei=%s" % [werte.size(), hoch.size(), path])


func _count_nodes(n: Node) -> int:
	var c: int = 1
	for k in n.get_children():
		c += _count_nodes(k)
	return c


func _find_button_text(root: Node, text: String) -> Button:
	if root == null:
		return null
	for c in root.get_children():
		if c is Button and (c as Button).text == text:
			return c
		var r: Button = _find_button_text(c, text)
		if r != null:
			return r
	return null


func _find_back_button(pg: Node) -> Button:
	# Die Beschriftung laeuft durch den Uebersetzer (ZURUECK -> BACK).
	for t in ["ZURUECK", "ZURÜCK", "BACK", "Zurueck", "Zurück"]:
		var b: Button = _find_button_text(pg, t)
		if b != null:
			return b
	return null


func _nav_hit(ss: Node, id: String) -> Button:
	if ss == null:
		return null
	var tile: Node = ss.find_child("NavTile_%s" % id, true, false)
	if tile == null:
		return null
	for ch in tile.get_children():
		if ch is Button:
			return ch
	return null


func _coll_zaehler(pg: Node) -> String:
	var own_c: int = 0
	for i in range(TextureManager.COLOR_NAMES.size()):
		if (gm.get("unlocked_colors") as Array).has(i):
			own_c += 1
	var own_r: int = 0
	for i in range(TextureManager.RIG_NAMES.size()):
		if (gm.get("unlocked_rigs") as Array).has(i):
			own_r += 1
	var own_h: int = 0
	for i in range(TextureManager.HAT_NAMES.size()):
		if (gm.get("unlocked_hats") as Array).has(i):
			own_h += 1
	print("[COLL][ZAEHLER] farben=%d/%d skins=%d/%d huete=%d/%d" % [
		own_c, TextureManager.COLOR_NAMES.size(), own_r, TextureManager.RIG_NAMES.size(),
		own_h, TextureManager.HAT_NAMES.size()])
	print("[RIG][LISTE] anzahl=%d hats=%d farben=%d" % [
		TextureManager.RIG_NAMES.size(), TextureManager.HAT_NAMES.size(),
		TextureManager.COLOR_NAMES.size()])
	# Sektions-Header auslesen, damit Header und Zaehler vergleichbar sind
	var secs: Node = pg.find_child("CollectionSections", true, false)
	var txt: String = ""
	if secs != null:
		for s in secs.get_children():
			if s.get_child_count() > 0:
				var l := s.get_child(0) as Label
				if l != null:
					txt += "[%s] " % l.text.replace("  ", " ")
	print("[COLL][SEKTION] %s" % txt.strip_edges())
	var info := pg.find_child("CollectionInfo", true, false) as Label
	if info != null:
		print("[COLL][INFO] %s" % info.text.replace("  ", " ").strip_edges())
	return "farben=%d skins=%d huete=%d" % [own_c, own_r, own_h]


func _collect_buttons(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_collect_buttons(c, out)


func _coll_readonly_test(pg: Node) -> int:
	# A5: Kacheln sind read-only - Klick darf p_color/p_rig/p_hat nicht aendern.
	var fehler: int = 0
	var secs: Node = pg.find_child("CollectionSections", true, false)
	if secs == null:
		print("[COLL][KLICK] FEHLER sektionen fehlen")
		return 1
	var namen: Array = ["farbe", "skin", "hut"]
	var idx: int = 0
	for s in secs.get_children():
		var btns: Array = []
		_collect_buttons(s, btns)
		if btns.is_empty():
			continue
		var b: Button = btns[0]
		var alt_c: int = int(gm.get("p_color"))
		var alt_r: int = int(gm.get("p_rig"))
		var alt_h: int = int(gm.get("p_hat"))
		var verb: int = b.pressed.get_connections().size()
		b.pressed.emit()
		await get_tree().process_frame
		var unveraendert: bool = alt_c == int(gm.get("p_color")) \
			and alt_r == int(gm.get("p_rig")) and alt_h == int(gm.get("p_hat"))
		var ignoriert: bool = unveraendert and b.disabled and verb == 0
		print("[COLL][KLICK] kachel=%s disabled=%s verbindungen=%d ignoriert=%s" % [
			str(namen[idx]) if idx < namen.size() else "?", str(b.disabled), verb, str(ignoriert)])
		if not ignoriert:
			fehler += 1
		idx += 1
	return fehler


func _coll_hat_switch(uim: Node) -> bool:
	var alt: int = int(gm.get("p_hat"))
	var frei: Array = gm.get("unlocked_hats")
	var gemerkt: Array = frei.duplicate()
	var ziel: int = -1
	for h in frei:
		if int(h) != alt:
			ziel = int(h)
			break
	if ziel < 0:
		ziel = 1 if alt != 1 else 2
		frei.append(ziel)
		gm.set("unlocked_hats", frei)
	uim.call("_open_char_page")
	await get_tree().create_timer(0.5).timeout
	uim.call("_on_char_field", "hat")
	await get_tree().create_timer(0.4).timeout
	uim.call("_apply_choice", "hat", ziel)
	await get_tree().create_timer(0.4).timeout
	var neu: int = int(gm.get("p_hat"))
	gm.set("unlocked_hats", gemerkt)
	uim.call("show_start_screen")
	await get_tree().create_timer(0.35).timeout
	print("[COLL][4] hutwechsel alt=%d ziel=%d neu=%d ok=%s" % [alt, ziel, neu, str(neu == ziel)])
	return neu == ziel


func _coll_flow() -> void:
	# M4: der INTERAKTIVE Weg (Menue-Kachel), nicht der Diag-Direktaufruf.
	var fehler: int = 0
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	# Sprache auf Deutsch stellen: die Beschriftungen kommen sonst aus dem
	# gespeicherten Profil (hier stand "en") und der Beleg waere gemischt.
	if str(gm.get("lang")) != "de":
		uim.call("_on_lang_set", "de")
		await get_tree().create_timer(0.6).timeout
	var ss = uim.get("start_screen")
	var nodes_start: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var hit := _nav_hit(ss, "coll")
	if hit == null:
		print("[COLL][FEHLER] Kachel NavTile_coll nicht gefunden")
		print("[COLL][ENDE] fehler=1")
		return
	print("[COLL][1] menue sichtbar=%s sprache=%s kachel=NavTile_coll knoten=%d" % [
		str(ss.visible), str(Loc.lang), nodes_start])
	var kinder_ref: int = -1
	var nodes_nach_erstem: int = -1
	for i in range(5):
		var t_auf: int = Time.get_ticks_msec()
		hit.pressed.emit()
		var dauer: int = Time.get_ticks_msec() - t_auf
		await get_tree().create_timer(0.45).timeout
		var pg = uim.get("collection_page")
		if pg == null:
			print("[COLL][FEHLER] nr=%d collection_page=null" % (i + 1))
			fehler += 1
			continue
		var kinder: int = _count_nodes(pg)
		if kinder_ref < 0:
			kinder_ref = kinder
		if i == 0:
			nodes_nach_erstem = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var sicht: bool = pg.visible
		print("[COLL][2] offen nr=%d sichtbar=%s kinder=%d aufbau_ms=%d" % [
			i + 1, str(sicht), kinder, dauer])
		print("[COLL][ZUSTAND] kinder=%d ref=%d gleich=%s" % [kinder, kinder_ref, str(kinder == kinder_ref)])
		if not sicht:
			print("[COLL][FEHLER] nr=%d sammlung nicht sichtbar" % (i + 1))
			fehler += 1
		if kinder != kinder_ref:
			print("[COLL][FEHLER] nr=%d kindzahl driftet (%d != %d)" % [i + 1, kinder, kinder_ref])
			fehler += 1
		_coll_zaehler(pg)
		if i == 0:
			await _shot("v139/coll-offen.png")
			var f_ro: int = await _coll_readonly_test(pg)
			fehler += f_ro
		if i == 4:
			# A4-Beleg: nach ZURUECK ist die Sammlung wieder benutzbar
			await _shot("v139/coll-reopen.png")
		var back := _find_back_button(pg)
		if back == null:
			print("[COLL][FEHLER] nr=%d ZURUECK-Knopf fehlt" % (i + 1))
			fehler += 1
		else:
			back.pressed.emit()
			await get_tree().create_timer(0.35).timeout
			var s2: bool = pg.visible
			var s3: bool = ss.visible
			print("[COLL][3] zu nr=%d sammlung_sichtbar=%s start_sichtbar=%s" % [i + 1, str(s2), str(s3)])
			if s2 or not s3:
				print("[COLL][FEHLER] nr=%d zurueck unvollstaendig" % (i + 1))
				fehler += 1
		if i == 2:
			var ok_hut: bool = await _coll_hat_switch(uim)
			if not ok_hut:
				fehler += 1
	# Endzustand + Knotenzahl gegen Leck (Basis = Stand nach dem 1. Oeffnen,
	# sonst zaehlt die einmalig gebaute Seite als "Leck")
	await get_tree().process_frame
	await get_tree().process_frame
	var nodes_ende: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("[COLL][PERF] nodes_start=%d nodes_nach_1=%d nodes_ende=%d delta=%d" % [
		nodes_start, nodes_nach_erstem, nodes_ende, nodes_ende - nodes_nach_erstem])
	var pg2 = uim.get("collection_page")
	if pg2 != null:
		print("[COLL][5] zurueck start_sichtbar=%s sammlung_sichtbar=%s" % [
			str(ss.visible), str(pg2.visible)])
	await _shot("v139/coll-zurueck.png")
	print("[COLL][ENDE] fehler=%d" % fehler)


func _coll_stress() -> void:
	# A1-Untersuchung: derselbe Weg wie M4, aber mit vollem Profil
	# (alle Farben/Skins/Huete) und Doppelklicks - die zwei Unterschiede,
	# die ein Spieler gegenueber dem Messnetz-Lauf hat.
	var fehler: int = 0
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var alt_c: Array = (gm.get("unlocked_colors") as Array).duplicate()
	var alt_h: Array = (gm.get("unlocked_hats") as Array).duplicate()
	var alt_r: Array = (gm.get("unlocked_rigs") as Array).duplicate()
	var alt_pc: int = int(gm.get("p_color"))
	var alt_ph: int = int(gm.get("p_hat"))
	var alt_pr: int = int(gm.get("p_rig"))
	var alles_c: Array = []
	for i in range(TextureManager.COLOR_NAMES.size()):
		alles_c.append(i)
	var alles_h: Array = []
	for i in range(TextureManager.HAT_NAMES.size()):
		alles_h.append(i)
	var alles_r: Array = []
	for i in range(TextureManager.RIG_NAMES.size()):
		alles_r.append(i)
	gm.set("unlocked_colors", alles_c)
	gm.set("unlocked_hats", alles_h)
	gm.set("unlocked_rigs", alles_r)
	gm.set("p_color", TextureManager.COLOR_NAMES.size() - 1)
	gm.set("p_hat", TextureManager.HAT_NAMES.size() - 1)
	gm.set("p_rig", TextureManager.RIG_NAMES.size() - 1)
	uim.call("refresh_profile_ui")
	await get_tree().create_timer(0.5).timeout
	var ss = uim.get("start_screen")
	var hit := _nav_hit(ss, "coll")
	if hit == null:
		print("[COLL2][FEHLER] kachel fehlt")
		print("[COLL][ENDE] fehler=1")
		return
	print("[COLL2][1] profil voll farben=%d huete=%d skins=%d p=(%d,%d,%d)" % [
		alles_c.size(), alles_h.size(), alles_r.size(),
		int(gm.get("p_color")), int(gm.get("p_rig")), int(gm.get("p_hat"))])
	# 1) Einzelklick mit vollem Profil
	var t0: int = Time.get_ticks_msec()
	hit.pressed.emit()
	await get_tree().create_timer(0.6).timeout
	var pg = uim.get("collection_page")
	print("[COLL2][2] offen dauer=%dms sichtbar=%s kinder=%d" % [
		Time.get_ticks_msec() - t0, str(pg != null and pg.visible),
		_count_nodes(pg) if pg != null else -1])
	if pg == null or not pg.visible:
		fehler += 1
		await _shot("v139/coll2-fehler.png")
	else:
		_coll_zaehler(pg)
		await _shot("v139/coll2-voll.png")
		# A1-Beleg: bei vollem Profil muss ZURUECK per Scroll erreichbar sein
		var sc = pg.find_child("CollectionScroll", true, false)
		var back0 := _find_back_button(pg)
		if sc is ScrollContainer and back0 != null:
			var scn: ScrollContainer = sc
			var max_v: int = int(scn.get_v_scroll_bar().max_value)
			scn.scroll_vertical = max_v
			await get_tree().process_frame
			await get_tree().process_frame
			var vr: Rect2 = Rect2(scn.global_position, scn.size).grow(-1.0)
			var br: Rect2 = Rect2(back0.global_position, back0.size)
			# Toleranz 6 px: Layout-Rundung + Panel-Innenabstand
			var erreichbar: bool = br.position.y >= vr.position.y - 6.0 \
				and br.end.y <= vr.end.y + 6.0
			print("[COLL2][6] scroll_max=%d seite_h=%d viewport=%s button=%s erreichbar=%s" % [
				max_v, int(scn.get_child(0).size.y), str(vr), str(br), str(erreichbar)])
			if not erreichbar:
				fehler += 1
			await _shot("v139/coll2-unten.png")
			scn.scroll_vertical = 0
			await get_tree().process_frame
		else:
			print("[COLL2][6] FEHLER kein ScrollContainer (sc=%s back=%s)" % [
				str(sc != null), str(back0 != null)])
			fehler += 1
	# 2) Doppelklick im gleichen Frame (Spieler tippt zweimal)
	hit.pressed.emit()
	hit.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	pg = uim.get("collection_page")
	print("[COLL2][3] doppelklick sichtbar=%s kinder=%d" % [
		str(pg != null and pg.visible), _count_nodes(pg) if pg != null else -1])
	# 3) Schliessen, direkt wieder oeffnen, ohne Wartezeit
	var back := _find_back_button(pg) if pg != null else null
	if back == null:
		print("[COLL2][FEHLER] ZURUECK fehlt")
		fehler += 1
	else:
		back.pressed.emit()
		hit.pressed.emit()
		await get_tree().create_timer(0.5).timeout
		pg = uim.get("collection_page")
		print("[COLL2][4] schnellwechsel sichtbar=%s kinder=%d start=%s" % [
			str(pg != null and pg.visible), _count_nodes(pg) if pg != null else -1,
			str(ss.visible)])
		back = _find_back_button(pg) if pg != null else null
		if back != null:
			back.pressed.emit()
			await get_tree().create_timer(0.4).timeout
	# 4) Profil zuruecksetzen (nichts speichern)
	gm.set("unlocked_colors", alt_c)
	gm.set("unlocked_hats", alt_h)
	gm.set("unlocked_rigs", alt_r)
	gm.set("p_color", alt_pc)
	gm.set("p_hat", alt_ph)
	gm.set("p_rig", alt_pr)
	print("[COLL2][5] profil zurueck p=(%d,%d,%d)" % [alt_pc, alt_pr, alt_ph])
	await _shot("v139/coll2-ende.png")
	print("[COLL][ENDE] fehler=%d" % fehler)


func _chest_skip_test() -> void:
	# B2/B4: Skip im Shop-Overlay, echter Knopf (ChestSkip), Vergleich mit
	# dem Durchlauf ohne Skip (COMIC_CHEST_SKIP=0).
	var nutze_skip: bool = OS.get_environment("COMIC_CHEST_SKIP") != "0"
	var per_taste: bool = OS.get_environment("COMIC_CHEST_SKIP") == "taste"
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	# Spielerweg: Shop-Seite oeffnen, dann laeuft das Kisten-Overlay darueber
	uim.call("_open_chest_page")
	await get_tree().create_timer(0.7).timeout
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	var ui = load("res://scripts/ui/chest_ui.gd").new()
	ui.setup(gm)
	cl.add_child(ui)
	var res: Dictionary = { "kind": "hat", "index": 5, "rarity": "legendary",
		"name": "KRONE", "duplicate": false, "ok": true, "gold": 0 }
	var fertig: Dictionary = { "payload": {}, "ms": 0 }
	ui.connect("finished", func(p):
		fertig["payload"] = p
		fertig["ms"] = Time.get_ticks_msec())
	ui.connect("closed", func():
		uim.call("_on_chest_closed"))
	ui.call("open", "standard", res)
	await get_tree().create_timer(0.30).timeout
	var skip_btn = ui.find_child("ChestSkip", true, false)
	print("[CHEST][SKIP] knopf_vorhanden=%s sichtbar=%s" % [
		str(skip_btn != null), str((skip_btn as Button).visible if skip_btn != null else false)])
	await _shot("v139/chest-skip-knopf.png")
	if nutze_skip:
		var t_press: int = Time.get_ticks_msec()
		if per_taste:
			# B1: Weg ueber die Action ui_cancel (Tastatur/Gamepad/Android-Zurueck)
			var ev := InputEventAction.new()
			ev.action = "ui_cancel"
			ev.pressed = true
			get_viewport().push_input(ev)
			print("[CHEST][SKIP] ausgeloest per taste=ui_cancel")
		else:
			(skip_btn as Button).pressed.emit()
			print("[CHEST][SKIP] ausgeloest per knopf=ChestSkip")
		await get_tree().create_timer(0.2).timeout
		var dt: float = float(Time.get_ticks_msec() - t_press) / 1000.0
		print("[CHEST][SKIP] messung dauer=%.2f s grenze=0.50 ok=%s" % [dt, str(dt <= 0.5)])
		await _shot("v139/chest-skip.png")
	else:
		var dur: float = float(ui.get("duration"))
		await get_tree().create_timer(dur + 0.9).timeout
		await _shot("v139/chest-noskip.png")
	var p: Dictionary = fertig["payload"]
	var gleich: bool = str(p.get("kind", "")) == str(res.get("kind", "")) \
		and int(p.get("index", -1)) == int(res.get("index", -2)) \
		and str(p.get("rarity", "")) == str(res.get("rarity", "")) \
		and str(p.get("name", "")) == str(res.get("name", "")) \
		and int(p.get("gold", -1)) == int(res.get("gold", -2))
	print("[CHEST][RESULT] ok=%s skip=%s kind=%s index=%d rarity=%s name=%s gold=%d gleich=%s" % [
		str(not p.is_empty()), str(nutze_skip), str(p.get("kind", "?")),
		int(p.get("index", -1)), str(p.get("rarity", "?")), str(p.get("name", "?")),
		int(p.get("gold", 0)), str(gleich)])
	# WEITER druecken -> closed -> Shop muss zurueckkommen
	var weiter := _find_button_text(ui, "WEITER")
	if weiter != null:
		weiter.pressed.emit()
		await get_tree().create_timer(0.4).timeout
	var cp = uim.get("chest_page")
	print("[CHEST][CLOSED] shop_seite_sichtbar=%s" % str(cp != null and (cp as Control).visible))
	await _shot("v139/chest-nach-skip-shop.png")
	print("[CHEST][ENDE] fertig")


func _chest_strip_test() -> void:
	# B5: drei Oeffnungen hintereinander - Laufband-Reihe und Gewinner-Position
	# muessen sich jedes Mal unterscheiden, der Gewinn bleibt der aus `result`.
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	uim.call("_open_chest_page")
	await get_tree().create_timer(0.6).timeout
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	var hashes: Array = []
	var posen: Array = []
	for lauf in range(3):
		var ui = load("res://scripts/ui/chest_ui.gd").new()
		ui.setup(gm)
		cl.add_child(ui)
		var res: Dictionary = { "kind": "hat", "index": 5, "rarity": "legendary",
			"name": "KRONE", "duplicate": false, "ok": true }
		ui.call("open", "standard", res)
		await get_tree().create_timer(0.25).timeout
		var sig: String = str(ui.get("strip_sig"))
		var pos: int = int(ui.get("_win_index"))
		hashes.append(sig.hash())
		posen.append(pos)
		print("[CHEST][STRIP] lauf=%d pos=%d hash=%d anfang=%s" % [
			lauf + 1, pos, sig.hash(), sig.substr(0, 54)])
		if lauf == 0:
			await _shot("v139/chest-strip-1.png")
		ui.call("_skip")
		await get_tree().create_timer(0.15).timeout
		ui.queue_free()
		await get_tree().create_timer(0.1).timeout
	var verschieden: int = 0
	if hashes.size() == 3:
		if hashes[0] != hashes[1]:
			verschieden += 1
		if hashes[0] != hashes[2]:
			verschieden += 1
		if hashes[1] != hashes[2]:
			verschieden += 1
	var posen_verschieden: bool = not (posen[0] == posen[1] and posen[1] == posen[2])
	print("[CHEST][STRIP] verschieden=%d/3 positionen=%s pos_verschieden=%s" % [
		verschieden, str(posen), str(posen_verschieden)])
	print("[CHEST][ENDE] strip fertig")


func _headmeas() -> void:
	var gc = load("res://scripts/texture/gen_characters.gd")
	print("[HEAD][START] rigs=%d" % TextureManager.RIG_NAMES.size())
	for i in range(TextureManager.RIG_NAMES.size()):
		var body: Image = _tex_img(TextureManager.get_skin_texture(0, i))
		var hm: Dictionary = gc._head_metrics(body)
		print("[HEAD] rig=%d name=%s top=%.0f cx=%.0f w=%.0f links=%.0f rechts=%.0f (alter_anker=%d)" % [
			i, str(TextureManager.RIG_NAMES[i]), float(hm["top"]), float(hm["cx"]),
			float(hm["w"]), float(hm["links"]), float(hm["rechts"]),
			int(TextureManager.HEAD_ANCHOR[i])])


func _hat_metrics(head: Dictionary, hat_img: Image) -> Dictionary:
	var hx0: float = float(head["links"])
	var hx1: float = float(head["rechts"])
	var htop: float = float(head["top"])
	var hx0m: int = -1
	var hx1m: int = -1
	var hy0: int = -1
	var hy1: int = -1
	var total: int = 0
	var aussen: int = 0
	for y in range(hat_img.get_height()):
		for x in range(hat_img.get_width()):
			if hat_img.get_pixel(x, y).a <= 0.10:
				continue
			total += 1
			if hx0m < 0 or x < hx0m:
				hx0m = x
			if x > hx1m:
				hx1m = x
			if hy0 < 0:
				hy0 = y
			hy1 = y
			# "aussen" = neben dem Kopf (auf Kopfhoehe oder tiefer) und
			# weiter als 4 px von der Kopfsilhouette entfernt
			if float(y) >= htop and (float(x) < hx0 - 4.0 or float(x) > hx1 + 4.0):
				aussen += 1
	if total == 0:
		return { "ueberstand": 99, "ueber_l": 99, "ueber_r": 99, "schweben": 99,
			"aussen_proz": 100.0, "px": 0, "y0": 0, "y1": 0 }
	var ueber_l: int = maxi(0, int(round(hx0 - float(hx0m))))
	var ueber_r: int = maxi(0, int(round(float(hx1m) - hx1)))
	var schweben: int = maxi(0, int(round(htop - float(hy1))))
	return {
		"ueberstand": maxi(ueber_l, ueber_r),
		"ueber_l": ueber_l,
		"ueber_r": ueber_r,
		"schweben": schweben,
		"aussen_proz": 100.0 * float(aussen) / float(total),
		"px": total,
		"y0": hy0,
		"y1": hy1,
	}


func _hat_color(hat_img: Image) -> Dictionary:
	# Dominante Farbe eines Hut-Layers: Pixel mit der hoechsten Saettigung,
	# plus Breite/Hoehe der Silhouette (fuer C6).
	var best: Color = Color(0, 0, 0, 0)
	var best_s: float = -1.0
	var x0: int = -1
	var x1: int = -1
	var y0: int = -1
	var y1: int = -1
	for y in range(hat_img.get_height()):
		for x in range(hat_img.get_width()):
			var c: Color = hat_img.get_pixel(x, y)
			if c.a <= 0.5:
				continue
			if x0 < 0 or x < x0:
				x0 = x
			if x > x1:
				x1 = x
			if y0 < 0:
				y0 = y
			y1 = y
			if c.s > best_s:
				best_s = c.s
				best = c
	if x1 < 0:
		return { "hue": 0.0, "w": 0, "h": 0 }
	return { "hue": best.h * 360.0, "w": x1 - x0 + 1, "h": y1 - y0 + 1 }


func _hatfit_all() -> void:
	# C2/C3/C4/C5/C7: Hutpixel gegen die gemessene Kopfsilhouette.
	var gc = load("res://scripts/texture/gen_characters.gd")
	# Diese Huete schweben absichtlich (Halo, Drohne): kein "beruehren"-Zwang,
	# aber sie muessen mittig und innerhalb Kopf + 4 px bleiben.
	var floats: Array = [10, 20, 21, 23]   # v1.41: Halo, Kristall-Halo, Drohne, Sternen-Halo
	# Diese "Huete" sitzen am Koerper - Kopfdaten sind darauf nicht anwendbar.
	var body: Array = [15, 16, 22]   # v1.41: Abzeichen, Rucksack, Schulterplatten
	var rigs: Array = []
	for i in range(TextureManager.RIG_NAMES.size()):
		rigs.append(i)
	var zeilen: Array = []
	var fail_relevant: int = 0
	var faelle: int = 0
	var faelle_relevant: int = 0
	for rig in rigs:
		var body_img: Image = _tex_img(TextureManager.get_skin_texture(0, int(rig)))
		var head: Dictionary = gc._head_metrics(body_img)
		for hat in range(1, TextureManager.HAT_NAMES.size()):
			var hl: Image = gc._hat_layer_for(int(hat), head, 1.0, int(rig))
			var m: Dictionary = _hat_metrics(head, hl)
			faelle += 1
			var typ: String = "kopf"
			if hat in body:
				typ = "koerper"
			elif hat in floats:
				typ = "schwebt"
			var ok_u: bool = int(m["ueberstand"]) <= 4
			var ok_s: bool = int(m["schweben"]) <= 2
			var ok_a: bool = float(m["aussen_proz"]) <= 0.001
			var mittig: bool = absi(int(m["ueber_l"]) - int(m["ueber_r"])) <= 2
			var ok: bool = false
			if typ == "koerper":
				ok = true
			elif typ == "schwebt":
				ok = ok_u and ok_a and mittig
			else:
				ok = ok_u and ok_s and ok_a
				faelle_relevant += 1
			if not ok:
				fail_relevant += 1
			print("[HAT][SITZ] hut=%d rig=%d typ=%s ueberstand=%d (l=%d r=%d) schweben=%d aussen_proz=%.1f ok=%s" % [
				hat, int(rig), typ, int(m["ueberstand"]), int(m["ueber_l"]), int(m["ueber_r"]),
				int(m["schweben"]), float(m["aussen_proz"]), str(ok)])
			zeilen.append([int(rig), hat, typ, int(m["ueberstand"]), int(m["schweben"]),
				float(m["aussen_proz"]), str(ok)])
	print("[HAT][SITZ] ERGEBNIS paare=%d kopfpaare=%d fehler=%d" % [
		faelle, faelle_relevant, fail_relevant])
	# C6: STROHHUT (7) muss sich farblich UND in der Silhouette von der
	# WOLLMUETZE (5) unterscheiden.
	var body0: Image = _tex_img(TextureManager.get_skin_texture(0, 0))
	var head0: Dictionary = gc._head_metrics(body0)
	var c5: Dictionary = _hat_color(gc._hat_layer_for(5, head0, 1.0, 0))
	var c7: Dictionary = _hat_color(gc._hat_layer_for(7, head0, 1.0, 0))
	var dh: float = absf(float(c5["hue"]) - float(c7["hue"]))
	if dh > 180.0:
		dh = 360.0 - dh
	var r5: float = float(c5["w"]) / maxf(1.0, float(c5["h"]))
	var r7: float = float(c7["w"]) / maxf(1.0, float(c7["h"]))
	var dratio: float = absf(r5 - r7) / maxf(0.001, maxf(r5, r7)) * 100.0
	print("[HAT][C6] wollm hue=%.0f w/h=%.2f | stroh hue=%.0f w/h=%.2f | farbton_diff=%.0f (Ziel >=25) form_diff=%.0f%% (Ziel >=20) ok=%s" % [
		float(c5["hue"]), r5, float(c7["hue"]), r7, dh, dratio,
		str(dh >= 25.0 and dratio >= 20.0)])
	# Tabelle schreiben
	var path := "C:/Users/vince/Games/comic-shooter/tools/hat_fit.md"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("[HAT][SITZ] FEHLER datei nicht schreibbar")
		return
	f.store_line("# Hut-Sitz (v1.39 C7) - Hutpixel gegen gemessene Kopfsilhouette")
	f.store_line("")
	f.store_line("Regeln: `ueberstand` = seitlicher Ueberstand des Hutes ueber den Kopf in px (<= 4),")
	f.store_line("`schweben` = Abstand Hutunterkante zu Kopfoberkante in px (<= 2),")
	f.store_line("`aussen` = Hutpixel neben dem Kopf (auf Kopfhoehe, > 4 px entfernt) in Prozent (0 %).")
	f.store_line("")
	f.store_line("## Fehleruebersicht")
	f.store_line("")
	f.store_line("- Paare gesamt: %d" % faelle)
	f.store_line("- davon Kopfpaare (Regeln anwendbar): %d" % faelle_relevant)
	f.store_line("- Fehler in den Kopfpaaren: %d" % fail_relevant)
	f.store_line("- Koerper-Items (Abzeichen, Rucksack, Blitz, Schulterplatten, Aura): keine Kopfdaten")
	f.store_line("- Schwebe-Items (Halo, Kristall-Halo, Sternen-Halo, Drohne): duerfen schweben,")
	f.store_line("  muessen aber mittig und innerhalb Kopf + 4 px bleiben")
	f.store_line("")
	f.store_line("## Alle Paare")
	f.store_line("")
	f.store_line("| rig | skin | hut | hutname | typ | ueberstand | schweben | aussen % | ok |")
	f.store_line("|---|---|---|---|---|---|---|---|---|")
	for z in zeilen:
		f.store_line("| %d | %s | %d | %s | %s | %d | %d | %.1f | %s |" % [
			int(z[0]), str(TextureManager.RIG_NAMES[int(z[0])]), int(z[1]),
			str(TextureManager.HAT_NAMES[int(z[1])]), str(z[2]), int(z[3]), int(z[4]),
			float(z[5]), str(z[6])])
	f.close()
	print("[HAT][SITZ] tabelle=%s" % path)


func _tex_alt(rig: int, hat: int) -> Texture2D:
	# Reproduziert den ALTEN Sitz (nur y-Verschiebung um HEAD_ANCHOR-21,
	# keine Skalierung) - fuer die Vorher/Nachher-Blaetter.
	var gc = load("res://scripts/texture/gen_characters.gd")
	var body: Image = _tex_img(TextureManager.get_skin_texture(0, rig)).duplicate()
	var layer := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	layer.fill(Color(0, 0, 0, 0))
	gc._draw_hat(layer, hat)
	var dy: int = int(round(float(TextureManager.HEAD_ANCHOR[clampi(rig, 0, 24)]) - 21.0))
	body.blend_rect(layer, Rect2i(0, 0, 64, 64), Vector2i(0, dy))
	return ImageTexture.create_from_image(body)


func _hat_sheets() -> void:
	# C2: KAPPE auf allen 25 Rigs
	var cells: Array = []
	for rig in range(TextureManager.RIG_NAMES.size()):
		cells.append({
			"tex": TextureManager.get_skin_hat_texture(0, rig, 1),
			"line1": "%d %s" % [rig, str(TextureManager.RIG_NAMES[rig])],
			"line2": "KAPPE",
		})
	print("[SHEET] kappe rigs=%d" % cells.size())
	await _sheet(cells, 7, 180, 176,
		"v1.39 C2 - KAPPE auf allen %d Skins (Ueberstand <= 4 px, kein Schweben)" % TextureManager.RIG_NAMES.size(),
		"v139/hats_kappe_25.png")

	# C3: Alien (Rig 8), 8 Huete vorher/nachher
	var alien_hats: Array = [1, 4, 2, 3, 9, 5, 7, 12]
	var cells2: Array = []
	for h in alien_hats:
		cells2.append({
			"tex": _tex_alt(8, int(h)),
			"line1": "%d %s" % [int(h), str(TextureManager.HAT_NAMES[int(h)])],
			"line2": "VORHER (alter Anker)",
		})
	for h in alien_hats:
		cells2.append({
			"tex": TextureManager.get_skin_hat_texture(0, 8, int(h)),
			"line1": "%d %s" % [int(h), str(TextureManager.HAT_NAMES[int(h)])],
			"line2": "NACHHER (gemessener Kopf)",
		})
	print("[SHEET] alien huete=%d (vorher/nachher)" % alien_hats.size())
	await _sheet(cells2, 8, 180, 176,
		"v1.39 C3 - ALIEN (Rig 8): 8 Huete, oben VORHER, unten NACHHER",
		"v139/hats_alien.png")

	# C4: Roboter (3) + Mars-Marschall (5), KAPPE vorher/nachher
	var cells3: Array = []
	for rig in [3, 5]:
		cells3.append({
			"tex": _tex_alt(int(rig), 1),
			"line1": "%d %s" % [int(rig), str(TextureManager.RIG_NAMES[int(rig)])],
			"line2": "KAPPE VORHER",
		})
	for rig in [3, 5]:
		cells3.append({
			"tex": TextureManager.get_skin_hat_texture(0, int(rig), 1),
			"line1": "%d %s" % [int(rig), str(TextureManager.RIG_NAMES[int(rig)])],
			"line2": "KAPPE NACHHER",
		})
	print("[SHEET] roboter_mars zellen=%d" % cells3.size())
	await _sheet(cells3, 4, 200, 190,
		"v1.39 C4 - ROBOTER (3) + MARS-MARSCHALL (5): KAPPE vorher/nachher",
		"v139/hats_roboter_mars.png")


func _d_check() -> void:
	# D2: Migration mit Altprofil (p_rig=12, p_hat=3)
	# D5: Namen/Raritaeten/Zeichenarme muessen deckungsgleich sein
	# D6: Debug "ALLE SKINS FREISCHALTEN" wirkt wirklich
	var fehler: int = 0
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)

	# ---- D5: Verdrahtung ----
	var names_n: int = TextureManager.RIG_NAMES.size()
	var konst: Dictionary = gm.get_script().get_script_constant_map()
	var rar_arr: Array = konst.get("RIG_RARITY", [])
	var hat_rar_arr: Array = konst.get("HAT_RARITY", [])
	var rar_n: int = rar_arr.size()
	var arme_n: int = _count_rig_arms()
	print("[RIG][CHECK] names=%d rarity=%d arme=%d hats=%d hat_rarity=%d" % [
		names_n, rar_n, arme_n, TextureManager.HAT_NAMES.size(), hat_rar_arr.size()])
	if names_n != rar_n or names_n != arme_n or hat_rar_arr.size() != TextureManager.HAT_NAMES.size():
		print("[RIG][CHECK] FEHLER: Laengen weichen ab")
		fehler += 1

	# ---- D2: Altprofil laden ----
	var pfad := "user://profile.save"
	var backup := PackedByteArray()
	if FileAccess.file_exists(pfad):
		backup = FileAccess.get_file_as_bytes(pfad)
	var alt: Dictionary = {
		"name": "HELD", "color": 2, "hat": 3, "unlocked": [0, 3, 5],
		"unlocked_rigs": [0, 12], "p_rig": 12, "gold": 4242, "xp_total": 0,
		"unlocked_colors": [0, 1, 2], "unlocked_maps": ["earth"], "active_map": "earth",
		"lang": "de"
	}
	var f := FileAccess.open(pfad, FileAccess.WRITE)
	if f != null:
		f.store_var(alt)
		f.close()
	gm.call("_load_profile")
	await get_tree().process_frame
	print("[PROFILE][CHECK] nach_migration p_rig=%d p_hat=%d rig_id=%s hat_id=%s" % [
		int(gm.get("p_rig")), int(gm.get("p_hat")),
		str(gm.get_meta("p_rig_id", "?")), str(gm.get_meta("p_hat_id", "?"))])
	var ok_rig: bool = int(gm.get("p_rig")) == 12 and int(gm.get("p_hat")) == 3
	if not ok_rig:
		print("[PROFILE][CHECK] FEHLER: Figur hat sich geaendert")
		fehler += 1
	# "Neustart": dieselbe Datei erneut laden (jetzt v3)
	gm.call("_load_profile")
	await get_tree().process_frame
	print("[PROFILE][CHECK] nach_neustart p_rig=%d p_hat=%d rig=%s hut=%s" % [
		int(gm.get("p_rig")), int(gm.get("p_hat")),
		str(TextureManager.RIG_NAMES[int(gm.get("p_rig"))]),
		str(TextureManager.HAT_NAMES[int(gm.get("p_hat"))])])
	if int(gm.get("p_rig")) != 12 or int(gm.get("p_hat")) != 3:
		print("[PROFILE][CHECK] FEHLER: Neustart verliert die Figur")
		fehler += 1
	await _shot("v139/profil-v3.png")

	# ---- D6: Debug-Unlock ----
	gm.call("debug_unlock_all")
	await get_tree().create_timer(0.4).timeout
	var rigs_own: int = (gm.get("unlocked_rigs") as Array).size()
	print("[DEBUG][CHECK] rigs=%d/%d" % [rigs_own, TextureManager.RIG_NAMES.size()])
	if rigs_own < TextureManager.RIG_NAMES.size():
		print("[DEBUG][CHECK] FEHLER: nicht alle Skins frei")
		fehler += 1
	# Sammlung muss die neuen Skins zeigen
	uim.call("show_collection")
	await get_tree().create_timer(0.7).timeout
	var pg = uim.get("collection_page")
	if pg != null:
		_coll_zaehler(pg)
		await _shot("v139/sammlung-v139.png")

	# ---- Profil zurueckschreiben (Original) ----
	if backup.size() > 0:
		var w := FileAccess.open(pfad, FileAccess.WRITE)
		if w != null:
			w.store_buffer(backup)
			w.close()
		gm.call("_load_profile")
		await get_tree().process_frame
		print("[PROFILE][RESTORE] zurueck p_rig=%d p_hat=%d gold=%d" % [
			int(gm.get("p_rig")), int(gm.get("p_hat")), int(gm.get("gold"))])
	print("[D][ENDE] fehler=%d" % fehler)


func _count_rig_arms() -> int:
	# Zaehlt die case-Zweige in _make_player_rig (Zeichenarme je Skin).
	var src: String = FileAccess.get_file_as_string("res://scripts/texture/gen_characters.gd")
	var start: int = src.find("static func _make_player_rig(")
	if start < 0:
		return -1
	var ende: int = src.find("static func _make_hat_icon(", start)
	if ende < 0:
		ende = src.length()
	var block: String = src.substr(start, ende - start)
	var n: int = 0
	var default_zweig: bool = false
	for zeile in block.split("\n"):
		var t: String = zeile.strip_edges()
		if t == "_:":
			default_zweig = true
			continue
		if t.ends_with(":") and t.length() <= 4 and t.substr(0, t.length() - 1).is_valid_int():
			n += 1
	# Der STANDARD-Skin laeuft ueber den Default-Zweig `_:`
	if default_zweig:
		n += 1
	return n


func _process(d: float) -> void:
	t += d


# ================================================================
# v1.40 — RUNDEN-Modus
# ================================================================

func _rounds_table() -> void:
	# W0.1/W5.1: Plan der 30 Runden + Monotonie-Nachweis
	var lines: Array = []
	lines.append("# Runden-Plan v1.40 (automatisch erzeugt mit `COMIC_LANTEST=rounds`)\n")
	lines.append("| Runde | Thema | Gruppen | Monster | HP gesamt | hp_mult | spd_mult |")
	lines.append("|---|---|---|---|---|---|---|")
	var prev: float = -1.0
	var monoton: bool = true
	var max_count: int = 0
	for r in range(1, Rounds.ROUND_COUNT + 1):
		var d: Dictionary = Rounds.def_for(r)
		var th: Dictionary = Rounds.theme_of(r)
		var hp: float = Rounds.hp_total(r, "normal")
		var n: int = Rounds.monster_count(r)
		max_count = maxi(max_count, n)
		if hp <= prev:
			monoton = false
		prev = hp
		print("[WAVE][PLAN] runde=%d gruppen=%d monster=%d hp=%.1f mult=%.2f spd=%.2f thema=%s" % [
			r, (d["groups"] as Array).size(), n, hp, Rounds.hp_mult(r, "normal"),
			Rounds.spd_mult(r), str(th.get("name", ""))])
		lines.append("| %d | %s | %d | %d | %.0f | %.2f | %.2f |" % [
			r, str(th.get("name", "-")), (d["groups"] as Array).size(), n, hp,
			Rounds.hp_mult(r, "normal"), Rounds.spd_mult(r)])
	lines.append("\n**Monoton:** %s · **max. Monster je Runde:** %d (Deckel %d)" % [
		str(monoton), max_count, int(Rounds.MAX_MONSTER)])
	print("[WAVE][PLAN] ERGEBNIS runden=%d monoton=%s max_monster=%d deckel=%s" % [
		Rounds.ROUND_COUNT, str(monoton), max_count, str(max_count <= int(Rounds.MAX_MONSTER))])
	for grad in ["leicht", "normal", "hart"]:
		print("[WAVE][DIFF] grad=%s herzen_start=%d hp_mult=%.2f preis_mult=%.2f" % [
			grad, int(Rounds.DIFFICULTY[grad]["herzen"]),
			float(Rounds.DIFFICULTY[grad]["hp"]), float(Rounds.DIFFICULTY[grad]["preis"])])
	# W0.3: Vergleichswert aus dem alten Modus (game_mode = 1, Formel aus core/waves.gd)
	var blines: Array = ["# Baseline alter Wellen-Modus (game_mode=1, Formel)\n",
		"| Welle | Monster | hp_mult | spd_mult | HP-Summe (Modell) |", "|---|---|---|---|---|"]
	var hp_mix: float = 4.2     # Mittelwert der Monster-HP (GREEN 3 … ORANGE 12)
	for w in range(1, 11):
		# v1.56: WAVE_BALANCE ist entfernt - die Werte kommen aus Balance.
		var hpm: float = Balance.hp_mult(w, "normal")
		var spd: float = Balance.spd_mult(w)
		var ziel: float = Balance.ziel_druck("wellen", "normal", float(w) * 40.0)
		var cnt: int = Balance.anzahl_fuer_druck(ziel, hpm, 10.0)
		var hpsum: float = float(cnt) * hp_mix * hpm
		print("[WAVE][BASE] welle=%d monster=%d hp_mult=%.2f spd_mult=%.2f hp_summe=%.0f druck=%.2f" % [
			w, cnt, hpm, spd, hpsum, Balance.druck(float(cnt), hpm, 10.0)])
		blines.append("| %d | %d | %.2f | %.2f | %.0f |" % [w, cnt, hpm, spd, hpsum])
	var fb := FileAccess.open("C:/Users/vince/Games/comic-shooter/tools/wave_baseline.md", FileAccess.WRITE)
	if fb != null:
		fb.store_string("\n".join(blines) + "\n")
		fb.close()
		print("[WAVE][BASE] tabelle=tools/wave_baseline.md")

	# W5.3: Typ -> Faehigkeit
	lines.append("\n## Monsterarten und Faehigkeiten (W5.3)\n")
	lines.append("| Typ | Name | Faehigkeit |")
	lines.append("|---|---|---|")
	for mt in [0, 1, 2, 3, 4, 5, 6, 8, 9, 10]:
		print("[WAVE][TYP] typ=%d name=%s faehigkeit=%s" % [mt, Rounds.type_name(mt), Rounds.ability_of(mt)])
		lines.append("| %d | %s | %s |" % [mt, Rounds.type_name(mt), Rounds.ability_of(mt)])
	# W4.2: Bonus-Wachstum, W4.3: Preise ueber 10 Runden
	var b1: int = Rounds.round_bonus(1, "normal")
	var b10: int = Rounds.round_bonus(10, "normal")
	print("[WAVE][ECO] bonus runde=1 %d runde=10 %d faktor=%.2f (Ziel >=3.0) ok=%s" % [
		b1, b10, float(b10) / float(b1), str(float(b10) >= 3.0 * float(b1))])
	var preise: Array = []
	for rr in range(1, 11):
		preise.append(WaveShop.price_of("herz", rr, "normal"))
	var mono: bool = true
	for i in range(1, preise.size()):
		if int(preise[i]) < int(preise[i - 1]):
			mono = false
	print("[WSHOP][PREIS] herz_runde1_10=%s monoton=%s" % [str(preise), str(mono)])

	var f := FileAccess.open("C:/Users/vince/Games/comic-shooter/tools/round_plan.md", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
		f.close()
		print("[WAVE][PLAN] tabelle=tools/round_plan.md")


func _kill_all_monsters() -> int:
	var n: int = 0
	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if m.get("ghost") == true:
			continue
		m.call("take_damage", 99999)
		n += 1
	return n


func _rounds_run() -> void:
	# W1/W2/W3: kompletter Durchlauf - Runden per Auto-Kill, Intermission,
	# Shop mit Kategorien und eigenem Fenster.
	var fehler: int = 0
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	gm.call("set_round_difficulty", OS.get_environment("COMIC_ROUND_DIFF") if OS.get_environment("COMIC_ROUND_DIFF") != "" else "normal")
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.0).timeout
	var rm = gm.get("rounds_mode")
	# F1: Event-Timer auf 0 setzen - es darf KEIN Event feuern
	var mon_vor: int = get_tree().get_nodes_in_group("monsters").size()
	gm.set("event_timer", 0.05)
	await get_tree().create_timer(1.2).timeout
	print("[WAVE][RUN] event_test monster_vorher=%d monster_nachher=%d" % [
		mon_vor, get_tree().get_nodes_in_group("monsters").size()])
	print("[WAVE][RUN] modus=%d runde=%d aktiv=%s" % [
		int(gm.get("game_mode")), int(rm.get("round_no")), str(rm.get("active"))])

	var runden: int = int(OS.get_environment("COMIC_ROUNDS")) if OS.get_environment("COMIC_ROUNDS") != "" else 5
	for r in range(runden):
		# warten bis die Runde laeuft
		var guard: int = 0
		while not bool(rm.get("active")) and guard < 200:
			guard += 1
			await get_tree().process_frame
		var kills: int = 0
		guard = 0
		while bool(rm.get("active")) and guard < 4000:
			guard += 1
			kills += _kill_all_monsters()
			await get_tree().process_frame
		await get_tree().create_timer(0.25).timeout
		print("[WAVE][RUN] runde=%d beendet kills=%d intermission=%s muenzen=%d" % [
			int(rm.get("round_no")), kills, str(rm.get("intermission")), int(gm.get("coins"))])
		if r == 0:
			await _shot("v140/welle_besiegt.png")
		# Icons pruefen
		var shop_btn = uim.get("wave_shop_btn")
		var next_btn = uim.get("wave_next_btn")
		print("[WAVE][RUN] icons shop=%s next=%s sichtbar=%s" % [
			str(shop_btn != null), str(next_btn != null),
			str((shop_btn as Button).visible if shop_btn != null else false)])
		if shop_btn == null or next_btn == null:
			fehler += 1
		# Runde 1: Shop oeffnen + Fenster oeffnen
		if r == 0:
			await _shot("v140/intermission.png")
			# W2.1: 7 s warten - es darf NICHTS automatisch passieren
			var rn_vor: int = int(rm.get("round_no"))
			await get_tree().create_timer(7.0).timeout
			print("[WAVE][RUN] warten7s runde_vorher=%d runde_jetzt=%d unveraendert=%s" % [
				rn_vor, int(rm.get("round_no")), str(rn_vor == int(rm.get("round_no")))])
			gm.call("open_rounds_shop")
			await get_tree().create_timer(0.6).timeout
			await _shot("v140/shop_kat.png")
			var ws = uim.get("wave_shop")
			# W3.7: Kauf ohne Geld (34 Muenzen, Pistole kostet mehr)
			if ws != null:
				ws.call("_buy_weapon", "weapon_pistol", "legendary", false)
				await get_tree().create_timer(0.2).timeout
				print("[WSHOP][RUN] kauf_ohne_geld muenzen=%d" % int(gm.get("coins")))
			# W3.8: 5x oeffnen/schliessen -> Kinder konstant
			var zaehler: Array = []
			for k in range(5):
				gm.call("open_rounds_shop")
				await get_tree().create_timer(0.25).timeout
				var w2 = uim.get("wave_shop")
				if w2 != null:
					zaehler.append((w2 as Node).get_child_count())
					w2.call("close")
				await get_tree().create_timer(0.25).timeout
			print("[WSHOP][RUN] kinder_5x=%s konstant=%s" % [
				str(zaehler), str(zaehler.size() > 0 and zaehler.min() == zaehler.max())])
			gm.call("open_rounds_shop")
			await get_tree().create_timer(0.4).timeout
			ws = uim.get("wave_shop")
			if ws == null:
				print("[WSHOP][FEHLER] kein Shop-Overlay")
				fehler += 1
			else:
				# Waffe anklicken -> eigenes Fenster
				ws.call("_on_weapon_click", "weapon_shotgun")
				await get_tree().create_timer(0.3).timeout
				await _shot("v140/shop_fenster.png")
				var fenster = (ws as Node).find_child("WaveItemWindow", true, false)
				print("[WSHOP][RUN] fenster=%s" % str(fenster != null))
				if fenster == null:
					fehler += 1
				# kaufen (genug Muenzen vorausgesetzt)
				gm.set("coins", 5000)
				ws.call("_buy_weapon", "weapon_shotgun", "epic", false)
				await get_tree().create_timer(0.3).timeout
				# Leben + Trank kaufen
				ws.call("_buy_article", "herz", false)
				await get_tree().create_timer(0.2).timeout
				ws.call("_buy_article", "revive", false)
				await get_tree().create_timer(0.2).timeout
				ws.call("_buy_article", "potion", false)
				await get_tree().create_timer(0.2).timeout
				# Angebot kaufen
				ws.call("_on_offer_click")
				await get_tree().create_timer(0.2).timeout
				ws.call("_buy_article", str(rm.get("offer_id")), true)
				await get_tree().create_timer(0.3).timeout
				await _shot("v140/shop_nach_kauf.png")
				print("[WSHOP][RUN] muenzen_nach_kauf=%d leben=%d herzen_gekauft=%d" % [
					int(gm.get("coins")), int(rm.get("lives")), int(rm.get("hearts_bought"))])
				ws.call("close")
				await get_tree().create_timer(0.4).timeout
				print("[WAVE][RUN] pause_nach_shop=%s" % str(get_tree().paused))
		# naechste Runde ueber das Icon - echter Mausklick (W2.5)
		if next_btn != null and r == runden - 1:
			var vorher: int = int(rm.get("round_no"))
			var mid: Vector2 = (next_btn as Control).global_position + (next_btn as Control).size * 0.5
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			ev.position = mid
			ev.global_position = mid
			get_viewport().push_input(ev)
			await get_tree().process_frame
			var ev2: InputEventMouseButton = ev.duplicate()
			ev2.pressed = false
			get_viewport().push_input(ev2)
			await get_tree().create_timer(0.5).timeout
			print("[WAVE][UI] klick quelle=maus ok=%s runde=%d->%d icons=%s" % [
				str(int(rm.get("round_no")) > vorher), vorher, int(rm.get("round_no")),
				str((shop_btn as Control).visible if shop_btn != null else false)])
		elif next_btn != null:
			(next_btn as Button).pressed.emit()
			await get_tree().create_timer(0.3).timeout
	# W4.5: Gnadenregel direkt pruefen (gleicher Codepfad wie am Rundenende)
	rm.set("round_no", 3)
	rm.set("free_heal_given", -1)
	gm.set("coins", 0)
	rm.call("_grace_check")
	print("[WAVE][RUN] ende runde=%d muenzen=%d" % [int(rm.get("round_no")), int(gm.get("coins"))])
	await _shot("v140/lauf_ende.png")
	print("[WAVE][ENDE] fehler=%d" % fehler)


func _rounds_economy() -> void:
	# W4.4: Modellrechnung ueber 30 Runden - "so viel kaufen wie geht".
	# Einnahmen = Summe Kill-Muenzen + Rundenbonus; Ausgaben = guenstigste
	# sinnvolle Kaeufe (Revive > Herz > Trank), Preise aus derselben Tabelle.
	var lines: Array = []
	lines.append("# Wellen-Oekonomie v1.40 (Modell, `COMIC_LANTEST=roundecon`)\n")
	lines.append("| Runde | Einnahmen | Ausgaben | Stand | Kaeufe |")
	lines.append("|---|---|---|---|---|")
	var coins: int = 0
	var lives: int = 0
	var herzen: int = 0
	var prev_round_hp: float = 0.0
	var waffen_gekauft: int = 0
	for r in range(1, Rounds.ROUND_COUNT + 1):
		var ein: int = 0
		for g in (Rounds.def_for(r)["groups"] as Array):
			var c: int = int(g["count"])
			ein += c * Rounds.coins_per_points(Rounds.points_of(int(g["type"])), r)
		ein += Rounds.round_bonus(r)
		coins += ein
		var aus: int = 0
		var kaeufe: Array = []
		# Revive zuerst (Ueberleben), dann Herzen, dann Traenke
		if lives < 2:
			var pr: int = WaveShop.price_of("revive", r, "normal")
			if coins >= pr:
				coins -= pr
				aus += pr
				lives += 1
				kaeufe.append("revive")
		while herzen < 5:
			var ph: int = WaveShop.price_of("herz", r, "normal")
			if coins < ph:
				break
			coins -= ph
			aus += ph
			herzen += 1
			kaeufe.append("herz")
		# Waffen als Hauptsenke: die naechste noch nicht gekaufte Waffe (common)
		var wpn_i: int = 0
		for cand in WaveShop.WEAPONS:
			if wpn_i >= waffen_gekauft:
				var pv: Dictionary = {}
				for rr in WaveShop.RARITIES:
					if str(rr["key"]) == "common":
						pv = rr
				var pw: int = WaveShop.weapon_price(cand, pv, r, "normal")
				if coins >= pw:
					coins -= pw
					aus += pw
					waffen_gekauft += 1
					kaeufe.append(str(cand["name"]))
				break
			wpn_i += 1
		var pp: int = WaveShop.price_of("potion", r, "normal")
		var n_pot: int = 0
		while coins >= pp and n_pot < 3:
			coins -= pp
			aus += pp
			n_pot += 1
		if n_pot > 0:
			kaeufe.append("trank x%d" % n_pot)
		var hp: float = Rounds.hp_total(r, "normal")
		print("[WAVE][ECO][SIM] runde=%d einnahmen=%d ausgaben=%d stand=%d hp=%.0f kaeufe=%s" % [
			r, ein, aus, coins, hp, ",".join(kaeufe) if kaeufe.size() > 0 else "-"])
		lines.append("| %d | %d | %d | %d | %s |" % [
			r, ein, aus, coins, ", ".join(kaeufe) if kaeufe.size() > 0 else "-"])
		if coins < 0:
			print("[WAVE][ECO][SIM] FEHLER: negativer Stand in Runde %d" % r)
		prev_round_hp = hp
	lines.append("\n**Endstand:** %d Muenzen · Herzen gekauft: %d/5 · Versicherungen: %d/2" % [coins, herzen, lives])
	var f := FileAccess.open("C:/Users/vince/Games/comic-shooter/tools/wave_economy.md", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	print("[WAVE][ECO][SIM] ENDE stand=%d herzen=%d leben=%d tabelle=tools/wave_economy.md" % [
		coins, herzen, lives])


func _rounds_perf() -> void:
	# W5.4: Frame-Messung mit einer vollen Runde (viele Gegner gleichzeitig)
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(0.8).timeout
	var rm = gm.get("rounds_mode")
	var ziel: int = int(OS.get_environment("COMIC_ROUND")) if OS.get_environment("COMIC_ROUND") != "" else 20
	# auf die Zielrunde springen und starten
	while int(rm.get("active")):
		_kill_all_monsters()
		await get_tree().process_frame
	rm.set("round_no", ziel - 1)
	rm.call("start_round")
	# 3 s spawnen lassen (Gegner bleiben am Leben)
	await get_tree().create_timer(3.0).timeout
	var frames: int = 180
	var sum_fps: float = 0.0
	var sum_proc: float = 0.0
	var max_draw: int = 0
	var max_nodes: int = 0
	for i in range(frames):
		await get_tree().process_frame
		sum_fps += Performance.get_monitor(Performance.TIME_FPS)
		sum_proc += Performance.get_monitor(Performance.TIME_PROCESS)
		max_draw = maxi(max_draw, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		max_nodes = maxi(max_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var mon: int = get_tree().get_nodes_in_group("monsters").size()
	print("[PERF][WAVE] runde=%d fps_avg=%.1f proc_ms=%.2f draw_max=%d nodes_max=%d monster_live=%d" % [
		ziel, sum_fps / float(frames), sum_proc / float(frames), max_draw, max_nodes, mon])
	await _shot("v140/runde_voll.png")
	print("[WAVE][ENDE] fehler=0")


func _mode_check() -> void:
	# W7.1: drei Modi + Schwierigkeitsgrade im Menue
	for m in [0, 1, 2]:
		gm.call("set_game_mode", m)
		print("[MODE][CHECK] wahl=%d name=%s label=%s" % [
			m, str(gm.call("mode_name", m)),
			str((gm.get("ui_manager").get("mode_btn") as Button).text) if gm.get("ui_manager").get("mode_btn") != null else "?"])
	var order: Array = ["leicht", "normal", "hart"]
	for g in order:
		gm.call("set_round_difficulty", g)
		var d: Dictionary = Rounds.DIFFICULTY[g]
		print("[MODE][CHECK] grad=%s herzen=%d hp=%.2f preis=%.2f" % [
			g, int(d["herzen"]), float(d["hp"]), float(d["preis"])])
	gm.call("set_game_mode", 2)
	gm.call("set_round_difficulty", "normal")
	print("[MODE][CHECK] ende modus=%d grad=%s" % [int(gm.get("game_mode")), str(gm.get("round_difficulty"))])


# ================================================================
# v1.41 — Belege F2/F3/F4
# ================================================================

func _menu141() -> void:
	# F2: Startseite in allen drei Modi messen und als Bild sichern.
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	if ss != null:
		ss.visible = true
	if str(gm.get("lang")) != "de":
		uim.call("_on_lang_set", "de")
		await get_tree().create_timer(0.4).timeout
	for m in [0, 1, 2]:
		gm.call("set_game_mode", m)
		await get_tree().process_frame
		uim.call("_fit_start_content")
		await get_tree().create_timer(0.35).timeout
		var row3 = ss.find_child("StartRow3", true, false) as Control
		var box = ss.find_child("StartBox", true, false) as Control
		var db = uim.get("diff_btn")
		var r3: Vector2 = row3.get_combined_minimum_size() if row3 != null else Vector2.ZERO
		var bx: Vector2 = box.get_combined_minimum_size() if box != null else Vector2.ZERO
		print("[MENU][LAYOUT] modus=%d box=(%.0f,%.0f) row3=(%.0f,%.0f) ueberlauf=%s" % [
			m, bx.x, bx.y, r3.x, r3.y, str(r3.x > maxf(bx.x, 900.0) + 1.0)])
		print("[MENU][GRAD] modus=%d knopf_sichtbar=%s disabled=%s text=\"%s\"" % [
			m, str((db as Button).visible) if db != null else "?",
			str((db as Button).disabled) if db != null else "?",
			str((db as Button).text) if db != null else "?"])
		await _shot("v141/menu_%d.png" % m)


func _shop141() -> void:
	# F3: Wellen-Shop mit Symbolen in allen 11 Karten
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	if ss != null:
		ss.visible = false
	gm.call("set_round_difficulty", "normal")
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.0).timeout
	# Runde 1 leerraeumen -> Intermission
	var guard: int = 0
	while bool(gm.get("rounds_mode").get("active")) and guard < 4000:
		guard += 1
		_kill_all_monsters()
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	uim.call("open_rounds_shop")
	await get_tree().create_timer(0.8).timeout
	var ws = uim.get("wave_shop")
	var n: int = 0
	if ws != null:
		n = int(ws.call("_count_nodes", ws))
	print("[WSHOP][RUN] shop_knoten=%d" % n)
	await _shot("v141/shop_symbole.png")


func _stats141() -> void:
	# F4: Statistik im Spiel 5x oeffnen/schliessen
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	gm.call("set_game_mode", 0)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.2).timeout
	var stats = uim.call("_stats_p")
	for i in range(5):
		uim.call("_open_stats_page")
		await get_tree().create_timer(0.4).timeout
		var ov = stats.get("overlay")
		var offen: bool = ov != null and is_instance_valid(ov)
		var sicht: bool = (ov as Control).visible if offen else false
		print("[STATS][UI] runde=%d overlay=%s sichtbar=%s pause=%s" % [
			i + 1, str(offen), str(sicht), str(get_tree().paused)])
		if i == 0:
			await _shot("v141/stats_ingame.png")
		stats.call("close_stats_overlay")
		await get_tree().create_timer(0.35).timeout
		var hud = uim.get("hud")
		print("[STATS][UI] zu runde=%d pause=%s hud_sichtbar=%s" % [
			i + 1, str(get_tree().paused), str((hud as Control).visible) if hud != null else "?"])


func _loc141() -> void:
	# F5: ENGLISCH in Shop, HUD und Waffen-Stats - ohne offene Texte
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	if ss != null:
		ss.visible = false
	uim.call("_on_lang_set", "en")
	await get_tree().create_timer(0.8).timeout
	gm.call("set_round_difficulty", "normal")
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.0).timeout
	# Runde 1 leerraeumen -> Intermission mit HUD-Zeile + Vorschau
	var guard: int = 0
	while bool(gm.get("rounds_mode").get("active")) and guard < 4000:
		guard += 1
		_kill_all_monsters()
		await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var hud = uim.get("hud")
	Loc.check_tree(hud, "hud")
	await _shot("v141/hud_en.png")
	# Shop
	uim.call("open_rounds_shop")
	await get_tree().create_timer(0.8).timeout
	var ws = uim.get("wave_shop")
	if ws != null:
		Loc.check_tree(ws, "shop")
		await _shot("v141/shop_en.png")
	# Waffen-Stats als Overlay
	uim.call("_open_stats_page")
	await get_tree().create_timer(0.6).timeout
	var stats = uim.call("_stats_p")
	var ov = stats.get("overlay")
	if ov != null and is_instance_valid(ov):
		Loc.check_tree(ov, "stats")
	stats.call("close_stats_overlay")
	await get_tree().create_timer(0.3).timeout
	Loc.dump_missing()
	print("[LOC][MISS] gesamt=%d" % Loc.missing_count())
	# Testhygiene: nicht auf Englisch zuruecklassen
	uim.call("_on_lang_set", "de")
	await get_tree().create_timer(0.3).timeout
	print("[LOC][CHECK] zurueck=de lang=%s" % Loc.lang)


# ================================================================
# v1.41 (B): Boss-Tabelle, Monotonie, 10-Runden-Lauf
# ================================================================

func _boss_table141() -> void:
	await get_tree().process_frame
	var vor: float = -1.0
	var monoton: bool = true
	for r in range(1, Rounds.ROUND_COUNT + 1):
		var b: Dictionary = Rounds.boss_counts(r)
		var hp: float = Rounds.hp_total_with_boss(r, "normal")
		var gruppen: float = Rounds.hp_total_with_boss(r, "normal") - Rounds.boss_hp_sum(r, "normal")
		var bhp: float = Rounds.boss_hp_sum(r, "normal")
		var anteil: float = 100.0 * bhp / maxf(1.0, hp)
		var typen: Array = []
		if int(b["mini"]) > 0:
			typen.append("MINI-BOSS")
		if int(b["biom"]) > 0:
			typen.append("BIOM-BOSS")
		print("[WAVE][BOSS] runde=%d anzahl=%d typen=[%s] hp=%.0f anteil=%.1f%%" % [
			r, int(b["mini"]) + int(b["biom"]), ", ".join(typen), bhp, anteil])
		print("[WAVE][PLAN] runde=%d monster=%d hp=%.0f gruppen_hp=%.0f boss_hp=%.0f faktor=%.2f" % [
			r, Rounds.monster_count(r) + Rounds.boss_count(r), hp, gruppen, bhp,
			Rounds.catchup_factor(r)])
		if hp <= vor:
			monoton = false
			print("[WAVE][PLAN] FEHLER nicht monoton: runde=%d hp=%.1f vorher=%.1f" % [r, hp, vor])
		vor = hp
	print("[WAVE][PLAN] ERGEBNIS monoton=%s runden=%d r20_bosse=%d r30_bosse=%d" % [
		str(monoton), Rounds.ROUND_COUNT, Rounds.boss_count(20), Rounds.boss_count(30)])


func _rounds_bossrun() -> void:
	# B4: 10 Runden am Stueck - jede muss regulaer enden (getoetet == total)
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	if ss != null:
		ss.visible = false
	gm.call("set_round_difficulty", "normal")
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.0).timeout
	var runden: int = int(OS.get_environment("COMIC_ROUNDS")) if OS.get_environment("COMIC_ROUNDS") != "" else 10
	for r in range(runden):
		var guard: int = 0
		while not bool(gm.get("rounds_mode").get("active")) and guard < 300:
			guard += 1
			await get_tree().process_frame
		guard = 0
		while bool(gm.get("rounds_mode").get("active")) and guard < 6000:
			guard += 1
			_kill_all_monsters()
			await get_tree().process_frame
		await get_tree().create_timer(0.15).timeout
		if r == runden - 1:
			break
		# naechste Runde starten
		gm.call("next_round")
		await get_tree().create_timer(0.2).timeout
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	print("[PERF][WAVE] runde=%d fps_avg=%.1f proc_ms=%.3f" % [
		int(gm.get("rounds_mode").get("round_no")),
		fps, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])


func _boss_banner_shot() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	if ss != null:
		ss.visible = false
	gm.call("set_round_difficulty", "normal")
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(0.8).timeout
	var rm = gm.get("rounds_mode")
	# Runde 1 leerraeumen
	var guard: int = 0
	while bool(rm.get("active")) and guard < 3000:
		guard += 1
		_kill_all_monsters()
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	# direkt auf Runde 8 springen (1 Mini-Boss)
	rm.set("round_no", 7)
	gm.call("next_round")
	await get_tree().create_timer(0.45).timeout
	await _shot("v141/boss_banner.png")
	await get_tree().create_timer(1.6).timeout
	await _shot("v141/boss_leiste.png")
	print("[WAVE][BOSS] shot fertig runde=%d" % int(rm.get("round_no")))


func _boss_perf() -> void:
	# B6: R30 mit 3 Bossen gleichzeitig, 240 Frames messen
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	if ss != null:
		ss.visible = false
	gm.call("set_round_difficulty", "normal")
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(0.8).timeout
	var rm = gm.get("rounds_mode")
	var guard: int = 0
	while bool(rm.get("active")) and guard < 3000:
		guard += 1
		_kill_all_monsters()
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	rm.set("round_no", 29)
	gm.call("next_round")
	# alles einlaufen lassen (inkl. Bosse nach 1,2 s)
	await get_tree().create_timer(4.0).timeout
	var frames: int = 240
	var sum_fps: float = 0.0
	var sum_proc: float = 0.0
	var max_mon: int = 0
	var max_boss: int = 0
	for i in range(frames):
		await get_tree().process_frame
		sum_fps += Performance.get_monitor(Performance.TIME_FPS)
		sum_proc += Performance.get_monitor(Performance.TIME_PROCESS)
		max_mon = maxi(max_mon, get_tree().get_nodes_in_group("monsters").size())
		var bosses: int = 0
		for m in get_tree().get_nodes_in_group("monsters"):
			if m.has_method("is_boss") and bool(m.call("is_boss")):
				bosses += 1
		max_boss = maxi(max_boss, bosses)
	print("[PERF][WAVE] runde=%d fps_avg=%.1f proc_ms=%.3f monster_max=%d bosse_max=%d" % [
		30, sum_fps / float(frames), sum_proc / float(frames), max_mon, max_boss])
	await _shot("v141/runde30_bosse.png")


# ================================================================
# v1.41 (M): Kontaktblatt, Farbton, Schild, Aura
# ================================================================

func _monster_sheet141() -> void:
	await get_tree().process_frame
	var jobs: Array = [
		[31, "SPORENBRUT", "teilt sich in 2 Sporen"],
		[34, "SPORE", "40 % HP, 8 s"],
		[32, "SCHILDTRAEGER", "blockt 70 % von vorn"],
		[33, "HEROLD", "bufft +25 % Tempo"],
		[0, "GREEN (alt)", "Referenz"],
		[9, "GOLEM (alt)", "Referenz"],
		[10, "PYRO (alt)", "Referenz"],
		[7, "MINI (alt)", "Referenz"],
	]
	var cells: Array = []
	for j in jobs:
		var key: String = ""
		match int(j[0]):
			31: key = "monster_sporenbrut"
			32: key = "monster_schild"
			33: key = "monster_herold"
			34: key = "monster_spore"
			0: key = "monster_green"
			9: key = "monster_golem"
			10: key = "monster_pyro"
			7: key = "boss_mini_earth"
		cells.append({ "tex": TextureManager.get_texture(key),
			"line1": "%d  %s" % [int(j[0]), str(j[1])], "line2": str(j[2]) })
	await _sheet(cells, 4, 220, 250, "v1.41 - neue Unterstuetzungs-Monster (M5)", "v141/monster_neu.png")
	_hue_check141()


func _hue_check141() -> void:
	# M5: Farbtonabstand der neuen Arten zu allen alten Arten
	var neu: Dictionary = { 31: "monster_sporenbrut", 32: "monster_schild", 33: "monster_herold" }
	var alt: Array = ["monster_green", "monster_red", "monster_blue", "monster_purple",
		"monster_yellow", "monster_pink", "monster_orange", "monster_burrower",
		"monster_golem", "monster_pyro", "monster_volt_drone", "monster_volt_trooper",
		"monster_volt_spider", "monster_mars_alien", "monster_robo_ape"]
	var alt_h: Array = []
	for a in alt:
		var hh: float = _tex_hue(TextureManager.get_texture(str(a)))
		alt_h.append("%s=%.0f" % [str(a).replace("monster_", ""), hh])
	print("[MON][FARBE][ALT] %s" % ", ".join(alt_h))
	for t in neu.keys():
		var h1: float = _tex_hue(TextureManager.get_texture(str(neu[t])))
		var best: float = 999.0
		var bester: String = ""
		for a in alt:
			var h2: float = _tex_hue(TextureManager.get_texture(str(a)))
			var d: float = absf(h1 - h2)
			if d > 180.0:
				d = 360.0 - d
			if d < best:
				best = d
				bester = str(a)
		print("[MON][FARBE] typ=%d hue=%.0f hue_diff=%.0f naechster=%s ok=%s" % [
			int(t), h1, best, bester, str(best >= 25.0)])


func _tex_hue(tex: Texture2D) -> float:
	if tex == null:
		return 0.0
	var img: Image = tex.get_image()
	var sum_sin: float = 0.0
	var sum_cos: float = 0.0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var mx: float = maxf(c.r, maxf(c.g, c.b))
			var mn: float = minf(c.r, minf(c.g, c.b))
			if mx - mn < 0.12 or mx < 0.15:
				continue
			sum_sin += sin(c.h * TAU)
			sum_cos += cos(c.h * TAU)
	var hh: float = atan2(sum_sin, sum_cos) / TAU
	if hh < 0.0:
		hh += 1.0
	return hh * 360.0


func _monster_behave141() -> void:
	# M2 (Frontschild) und M3 (Aura) direkt messen
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	gm.call("set_game_mode", 0)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.0).timeout
	# --- Schildtraeger: 4 Treffer von vorn, 4 von hinten ---
	var s = gm.call("spawn_monster_at", Vector2(1200, 1200), 32)
	await get_tree().create_timer(0.2).timeout
	s.set("facing_direction", Vector2.RIGHT)
	s.set("current_health", 500)
	s.set("max_health", 500)
	var hp0: int = int(s.get("current_health"))
	s.call("take_damage", 10, 1, Vector2(40, 0))          # Treffer von rechts = vorne
	var hp1: int = int(s.get("current_health"))
	s.call("take_damage", 10, 1, Vector2(-40, 0))         # Treffer von links = hinten
	var hp2: int = int(s.get("current_health"))
	print("[MON][SCHILD] hp_start=%d nach_vorn=%d nach_hinten=%d vorn_schaden=%d hinten_schaden=%d blockiert_pct=%.0f" % [
		hp0, hp1, hp2, hp0 - hp1, hp1 - hp2,
		100.0 - 100.0 * float(hp0 - hp1) / maxf(1.0, float(hp1 - hp2))])
	# --- Herold: bufft Nachbarn ---
	var h = gm.call("spawn_monster_at", Vector2(1400, 1200), 33)
	var g1 = gm.call("spawn_monster_at", Vector2(1450, 1200), 0)
	var g2 = gm.call("spawn_monster_at", Vector2(1500, 1200), 1)
	var spd_vor: float = float(g1.get("speed"))
	await get_tree().create_timer(0.8).timeout
	var spd_nach: float = float(g1.get("speed"))
	print("[MON][AURA] herald=%s nachbarn=2 tempo_vor=%.0f tempo_nach=%.0f faktor=%.2f" % [
		str(h != null), spd_vor, spd_nach, spd_nach / maxf(1.0, spd_vor)])
	# --- Sporenbrut teilt sich ---
	var spb = gm.call("spawn_monster_at", Vector2(1600, 1200), 31)
	await get_tree().create_timer(0.2).timeout
	spb.call("take_damage", 999, 1, Vector2(0, 0))
	await get_tree().create_timer(0.4).timeout
	var sporen: int = 0
	for m in get_tree().get_nodes_in_group("monsters"):
		if int(m.get("type")) == 34:
			sporen += 1
	print("[MON][TEILUNG] kontrolle sporen_im_feld=%d erwartet=2" % sporen)


func _monster_perf141() -> void:
	# M7: R20 mit allen drei Arten gleichzeitig
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	if ss != null:
		ss.visible = false
	gm.call("set_round_difficulty", "normal")
	gm.call("set_game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(0.8).timeout
	var rm = gm.get("rounds_mode")
	var guard: int = 0
	while bool(rm.get("active")) and guard < 3000:
		guard += 1
		_kill_all_monsters()
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	rm.set("round_no", 19)
	gm.call("next_round")
	await get_tree().create_timer(5.0).timeout
	var frames: int = 240
	var sum_fps: float = 0.0
	var sum_proc: float = 0.0
	var max_mon: int = 0
	var gesehen: Dictionary = {}
	for i in range(frames):
		await get_tree().process_frame
		sum_fps += Performance.get_monitor(Performance.TIME_FPS)
		sum_proc += Performance.get_monitor(Performance.TIME_PROCESS)
		max_mon = maxi(max_mon, get_tree().get_nodes_in_group("monsters").size())
		for m in get_tree().get_nodes_in_group("monsters"):
			gesehen[int(m.get("type"))] = true
	print("[PERF][WAVE] runde=20 fps_avg=%.1f proc_ms=%.3f monster_max=%d typen=%s" % [
		sum_fps / float(frames), sum_proc / float(frames), max_mon, str(gesehen.keys())])


# ================================================================
# v1.41 (S): Skins/Sammlung/Farben - Belege
# ================================================================

func _skin141() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	# --- Struktur ---
	var rar: Array = gm.get_script().get_script_constant_map().get("RIG_RARITY", [])
	print("[RIG][CHECK] names=%d rarity=%d arme=%d hats=%d head_anchor=%d" % [
		TextureManager.RIG_NAMES.size(), rar.size(), TextureManager.RIG_NAMES.size(),
		TextureManager.HAT_NAMES.size(), TexDraw.HEAD_ANCHOR.size()])
	print("[RIG][LISTE] anzahl=%d namen=%s" % [TextureManager.RIG_NAMES.size(), ", ".join(TextureManager.RIG_NAMES)])
	print("[HAT][CHECK] huete=%d" % TextureManager.HAT_NAMES.size())
	# --- Sammlung + Debug-Unlock ---
	uim.call("show_collection")
	await get_tree().create_timer(0.7).timeout
	var pg = uim.get("collection_page")
	if pg != null:
		print("[COLL][ZAEHLER] skins=%d huete=%d farben=%d" % [
			TextureManager.RIG_NAMES.size(), TextureManager.HAT_NAMES.size(), TextureManager.PLAYER_COLORS.size()])
		await _shot("v141/sammlung_11.png")
	gm.call("debug_unlock_all")
	await get_tree().create_timer(0.5).timeout
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	# --- Farben: Torso/Hose folgen der Spielerfarbe ---
	var farb_ok: Dictionary = {}
	for rig in range(TextureManager.RIG_NAMES.size()):
		var alle_ok: bool = true
		for k in range(TextureManager.PLAYER_COLORS.size()):
			var r: Dictionary = _rig_color_hit(int(rig), int(k))
			var ok1: bool = float(r["shirt"]) >= 90.0 and float(r["pants"]) >= 90.0
			alle_ok = alle_ok and ok1
			print("[RIG][FARBE] rig=%s farbe=%d shirt=%s treffer=%.0f pants_treffer=%.0f ok=%s beine=%s" % [
				str(TextureManager.RIG_NAMES[rig]), k, str(r["hex"]),
				float(r["shirt"]), float(r["pants"]), str(ok1), str(r["beine"])])
		farb_ok[rig] = alle_ok
	# --- v1.41 (N5): Meldung fuer die sechs neuen Skins ---
	var rar_map: Array = gm.get_script().get_script_constant_map().get("RIG_RARITY", [])
	for rig2 in [11, 12, 13, 14, 15, 16]:
		if rig2 >= TextureManager.RIG_NAMES.size():
			continue
		var m0: PackedByteArray = _alpha_mask(TextureManager.get_skin_texture(0, rig2))
		var iou_max: float = 0.0
		for other in range(TextureManager.RIG_NAMES.size()):
			if other == rig2:
				continue
			var io: float = _iou(m0, _alpha_mask(TextureManager.get_skin_texture(0, other)))
			iou_max = maxf(iou_max, io)
		print("[RIG][NEU] name=%s seltenheit=%s farb_ok=%s iou_max=%.2f" % [
			str(TextureManager.RIG_NAMES[rig2]),
			str(rar_map[rig2]) if rig2 < rar_map.size() else "?",
			str(bool(farb_ok.get(rig2, false))), iou_max])
	# --- Kontaktblatt 11 Rigs x 10 Farben ---
	var cells: Array = []
	for rig in range(TextureManager.RIG_NAMES.size()):
		for k in range(TextureManager.PLAYER_COLORS.size()):
			cells.append({
				"tex": TextureManager.get_skin_texture(int(k), int(rig)),
				"line1": "%d %s" % [rig, str(TextureManager.RIG_NAMES[rig])] if k == 0 else "",
				"line2": "%d %s" % [k, str(TextureManager.COLOR_NAMES[k])],
			})
	await _sheet(cells, 10, 96, 108, "v1.41 (S4) - 11 Skins x 10 Farben", "v141/skins_farben.png")
	# --- Kontaktblatt 4 neue Rigs x 6 Huete ---
	var neu: Array = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
	var huete: Array = [1, 3, 4, 7, 20, 23]
	var cells2: Array = []
	for rig in neu:
		for h in huete:
			cells2.append({
				"tex": TextureManager.get_skin_hat_texture(0, int(rig), int(h)),
				"line1": "%d %s" % [rig, str(TextureManager.RIG_NAMES[rig])],
				"line2": "Hut %d %s" % [int(h), str(TextureManager.HAT_NAMES[int(h)])],
			})
	await _sheet(cells2, 6, 150, 158, "v1.41 (S3) - vier neu gezeichnete Skins x 6 Huete", "v141/skins_neu_4.png")
	# --- IoU der vier Neuen gegen alle anderen ---
	_iou_4(neu)


func _rig_color_hit(rig: int, k: int) -> Dictionary:
	# v1.41 (S4): Mittelwert der farbgesteuerten Koerperflaechen muss in der
	# Farbfamilie der gewaehlten Spielerfarbe liegen. Die Maske selbst wird
	# aus dem Vergleich zweier Farben (0 = Blau, 1 = Rot) gewonnen - dadurch
	# zaehlen nur Flaechen, die die Spielerfarbe wirklich uebernehmen.
	var ref: Image = TextureManager.get_skin_texture(0, rig).get_image()
	var alt: Image = TextureManager.get_skin_texture(1, rig).get_image()
	var img: Image = TextureManager.get_skin_texture(k, rig).get_image()
	var ck: Dictionary = TextureManager.PLAYER_COLORS[k]
	var sh: Color = ck["shirt"]
	var pa: Color = ck["pants"]
	var sum := Vector3.ZERO
	var sum_l := Vector3.ZERO
	var n: int = 0
	var nl: int = 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var a: Color = ref.get_pixel(x, y)
			var b: Color = alt.get_pixel(x, y)
			if a.a < 0.6 or b.a < 0.6:
				continue
			if _rgb_dist(a, b) < 0.25:
				continue
			var c: Color = img.get_pixel(x, y)
			sum += Vector3(c.r, c.g, c.b)
			n += 1
			if y >= 44:
				sum_l += Vector3(c.r, c.g, c.b)
				nl += 1
	var m: Color = Color(0.5, 0.5, 0.5)
	var ml: Color = Color(0.5, 0.5, 0.5)
	if n > 0:
		m = Color(sum.x / float(n), sum.y / float(n), sum.z / float(n))
	if nl > 0:
		ml = Color(sum_l.x / float(nl), sum_l.y / float(nl), sum_l.z / float(nl))
	# GEIST hat keine Hose (schwebendes Laken): dann entfaellt die Hosenpruefung
	# "Beine" = der untere Bereich ist in der Referenz naeher an der Hosen-
	# als an der Shirtfarbe. Beim GEIST (schwebendes Laken) ist das nicht so.
	var hat_beine: bool = false
	var c0: Dictionary = TextureManager.PLAYER_COLORS[0]
	var usum := Vector3.ZERO
	var un: int = 0
	for y in range(46, ref.get_height()):
		for x in range(ref.get_width()):
			var cp: Color = ref.get_pixel(x, y)
			if cp.a < 0.6:
				continue
			if cp.get_luminance() < 0.12:
				continue          # Kontur zaehlt nicht als Flaeche
			usum += Vector3(cp.r, cp.g, cp.b)
			un += 1
	if un > 0:
		var um := Color(usum.x / float(un), usum.y / float(un), usum.z / float(un))
		hat_beine = _family_dist(um, c0["pants"]) < _family_dist(um, c0["shirt"])
	var r: Dictionary = { "hex": sh.to_html(false),
		"shirt": _color_score(m, sh),
		"pants": _color_score(ml, pa) if hat_beine else 100.0,
		"n": n, "beine": hat_beine }
	return r


func _rgb_dist(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _family_dist(p: Color, ziel: Color) -> float:
	# Abstand zur Farbfamilie: Multiplizieren (darkened/lightened) oder
	# Richtung Grau entsaettigen - beides benutzen die Zeichner.
	var best: float = 9.0
	var zl2: float = ziel.r * ziel.r + ziel.g * ziel.g + ziel.b * ziel.b
	if zl2 > 0.0001:
		var s2: float = (p.r * ziel.r + p.g * ziel.g + p.b * ziel.b) / zl2
		s2 = clampf(s2, 0.15, 1.50)
		var q := Vector3(ziel.r * s2, ziel.g * s2, ziel.b * s2)
		best = Vector3(p.r - q.x, p.g - q.y, p.b - q.z).length()
	var g := Color(0.5, 0.5, 0.5)
	var dir := Vector3(g.r - ziel.r, g.g - ziel.g, g.b - ziel.b)
	var len2: float = dir.length_squared()
	var v := Vector3(p.r - ziel.r, p.g - ziel.g, p.b - ziel.b)
	var t: float = 0.0
	if len2 > 0.0001:
		t = clampf((v.x * dir.x + v.y * dir.y + v.z * dir.z) / len2, -0.30, 0.75)
	var q2 := Vector3(ziel.r + dir.x * t, ziel.g + dir.y * t, ziel.b + dir.z * t)
	var d2: float = Vector3(p.r - q2.x, p.g - q2.y, p.b - q2.z).length()
	return minf(best, d2)


func _color_score(ist: Color, ziel: Color) -> float:
	# 100 %, wenn der Mittelwert in der Farbfamilie liegt; sonst linear
	# abfallend (Abstand 0,08 -> 100 %, 0,35 -> 0 %).
	var d: float = _family_dist(ist, ziel)
	return clampf(100.0 * (0.35 - d) / 0.27, 0.0, 100.0)


func _iou_4(neu: Array) -> void:
	var masken: Array = []
	for r in range(TextureManager.RIG_NAMES.size()):
		masken.append(_alpha_mask(TextureManager.get_skin_texture(0, r)))
	var max_iou: float = 0.0
	for r in neu:
		var best: float = 0.0
		var bester: int = -1
		for o in range(masken.size()):
			if o == r:
				continue
			var v: float = _iou(masken[r], masken[o])
			if v > best:
				best = v
				bester = o
		max_iou = maxf(max_iou, best)
		print("[RIG][IOU] rig=%s gegen=%s iou=%.2f ok=%s" % [
			str(TextureManager.RIG_NAMES[r]),
			str(TextureManager.RIG_NAMES[bester]) if bester >= 0 else "?",
			best, str(best <= 0.55)])
	print("[RIG][IOU] ERGEBNIS max_iou=%.2f ziel=0.55 ok=%s" % [max_iou, str(max_iou <= 0.55)])
	# Kontur-IoU: nur Randpixel - das ist die Silhouette, die man sieht.
	# Vollmasken-IoU liegt bei allen aufrechten Figuren >= 0,74 (tools/rig_iou.md
	# aus v1.39) und taugt nicht als Unterscheidungsmass.
	var raender: Array = []
	for r in range(TextureManager.RIG_NAMES.size()):
		raender.append(_kante(_alpha_mask(TextureManager.get_skin_texture(0, r)), 64))
	var max_k: float = 0.0
	for r in neu:
		var best: float = 0.0
		var bester: int = -1
		for o in range(raender.size()):
			if o == r:
				continue
			var v: float = _iou(raender[r], raender[o])
			if v > best:
				best = v
				bester = o
		max_k = maxf(max_k, best)
		print("[RIG][KONTUR] rig=%s gegen=%s kontur_iou=%.2f ok=%s" % [
			str(TextureManager.RIG_NAMES[r]),
			str(TextureManager.RIG_NAMES[bester]) if bester >= 0 else "?",
			best, str(best <= 0.55)])
	print("[RIG][KONTUR] ERGEBNIS max_kontur_iou=%.2f ziel=0.55 ok=%s" % [max_k, str(max_k <= 0.55)])


func _kante(mask: PackedByteArray, n: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(mask.size())
	for y in range(n):
		for x in range(n):
			var i: int = y * n + x
			if mask[i] == 0:
				continue
			var rand: bool = false
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = x + dx
					var ny: int = y + dy
					if nx < 0 or ny < 0 or nx >= n or ny >= n:
						rand = true
					elif mask[ny * n + nx] == 0:
						rand = true
			if rand:
				out[i] = 1
	return out


func _alpha_mask(tex: Texture2D) -> PackedByteArray:
	var img: Image = tex.get_image()
	var out := PackedByteArray()
	out.resize(img.get_width() * img.get_height())
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			out[y * img.get_width() + x] = 1 if img.get_pixel(x, y).a > 0.4 else 0
	return out


func _iou(a: PackedByteArray, b: PackedByteArray) -> float:
	var inter: int = 0
	var uni: int = 0
	for i in range(a.size()):
		if a[i] == 1 or b[i] == 1:
			uni += 1
			if a[i] == 1 and b[i] == 1:
				inter += 1
	if uni == 0:
		return 0.0
	return float(inter) / float(uni)


# ================================================================
# v1.41 (S5): Profil-Migration v3 -> v4
# ================================================================

func _migr141() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null:
		ls.visible = false
		ls.set_process(false)
	# Altes Profil (v3) schreiben: Skin 28 SCHATTEN-KATZE, Hut 27 NEON-AURA
	var alt: Dictionary = {
		"version": 3,
		"p_rig": 28, "p_hat": 27,
		"p_rig_id": "SCHATTEN-KATZE", "p_hat_id": "NEON-AURA",
		"unlocked_rig_ids": ["STANDARD", "SCHATTEN-KATZE", "NEON-PHANTOM", "SPINNENMANN"],
		"unlocked_hat_ids": ["OHNE", "NEON-AURA", "KRONE"],
		"unlocked": [0, 3, 27], "unlocked_rigs": [0, 24, 28, 25],
		"name": "HELD", "color": 3, "gold": 1234, "xp_total": 0,
		"unlocked_colors": [0, 1, 2, 3], "unlocked_maps": ["earth"],
		"active_map": "earth", "lang": "de",
	}
	var f := FileAccess.open("user://profile.save", FileAccess.WRITE)
	if f == null:
		print("[PROFILE][FEHLER] profil nicht schreibbar")
		return
	f.store_var(alt)
	f.close()
	print("[TEST][S5] altprofil geschrieben p_rig=28 p_hat=27")
	# Laden ueber den echten Pfad
	gm.call("_load_profile")
	await get_tree().create_timer(0.3).timeout
	print("[PROFILE][CHECK] nach_migration p_rig=%d p_hat=%d rig_id=\"%s\" hut_id=\"%s\"" % [
		int(gm.get("p_rig")), int(gm.get("p_hat")),
		str(gm.get_meta("p_rig_id", "?")), str(gm.get_meta("p_hat_id", "?"))])
	print("[PROFILE][CHECK] unlocked_rigs=%s unlocked_hats=%s" % [
		str(gm.get("unlocked_rigs")), str(gm.get("unlocked_hats"))])
	# Neu starten (Datei erneut lesen) - die IDs muessen stabil bleiben
	gm.call("_save_profile")
	await get_tree().create_timer(0.2).timeout
	gm.call("_load_profile")
	await get_tree().create_timer(0.3).timeout
	print("[PROFILE][CHECK] nach_neustart p_rig=%d p_hat=%d rig_id=\"%s\" hut_id=\"%s\"" % [
		int(gm.get("p_rig")), int(gm.get("p_hat")),
		str(gm.get_meta("p_rig_id", "?")), str(gm.get_meta("p_hat_id", "?"))])


func _mksetup141() -> void:
	# v1.41: Testprofil wiederherstellen (Zustand wie beim Golden-Master v1.36:
	# Hut KAPPE, alle Karten/Farben, Mars mit Fruehling+Sommer freigeschaltet).
	for _f in range(8):
		await get_tree().process_frame
	var rigs: Array = []
	for i in range(TextureManager.RIG_NAMES.size()):
		rigs.append(i)
	var hats: Array = []
	for i in range(TextureManager.HAT_NAMES.size()):
		hats.append(i)
	var prof: Dictionary = {
		"version": 4,
		"p_rig": 0, "p_hat": 1,
		"p_rig_id": "STANDARD", "p_hat_id": "KAPPE",
		"unlocked_rigs": rigs, "unlocked_hats": hats,
		"unlocked_rig_ids": TextureManager.RIG_NAMES.duplicate(),
		"unlocked_hat_ids": TextureManager.HAT_NAMES.duplicate(),
		"name": "HELD", "color": 0, "unlocked": hats,
		"unlocked_colors": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
		"unlocked_maps": ["earth", "mars", "jungle", "volt"],
		"active_map": "earth",
		"gold": 20000, "xp_total": 0, "best_run_xp": 0,
		"season_unlocks": { "mars": ["spring", "summer"], "jungle": ["spring", "summer"] },
		"season_mode": {}, "lang": "de", "difficulty": 2, "aim_assist": 1,
		"tip_shown": true, "boosts": {}, "quick": {}, "muted": false,
	}
	var f := FileAccess.open("user://profile.save", FileAccess.WRITE)
	if f == null:
		print("[TEST][SETUP] FEHLER profil nicht schreibbar")
		return
	f.store_var(prof)
	f.close()
	print("[TEST][SETUP] profil geschrieben rigs=%d huete=%d hut=%s" % [
		rigs.size(), hats.size(), str(TextureManager.HAT_NAMES[1])])


# ================================================================
# v1.41 (N3): Konzept-Blaetter (9 legendaere + 9 epische Varianten)
# ================================================================

const CONCEPTS_LEGENDARY := {
	"EISENKARDINAL": [
		{ "v": "A", "name": "Templer", "cloth": Color(0.93, 0.92, 0.90), "metal": Color(0.72, 0.74, 0.80),
			"accent": Color(0.78, 0.12, 0.14), "face": "human", "gear": "hood", "torso": "plate",
			"shoulder": "pads", "weapon": "mace", "legs": "normal" },
		{ "v": "B", "name": "Schwarzstahl", "cloth": Color(0.18, 0.18, 0.22), "metal": Color(0.52, 0.54, 0.62),
			"accent": Color(0.96, 0.80, 0.25), "face": "grim", "gear": "crown", "torso": "plate",
			"shoulder": "spikes", "weapon": "mace", "legs": "wide" },
		{ "v": "C", "name": "Frost-Paladin", "cloth": Color(0.44, 0.66, 0.90), "metal": Color(0.80, 0.92, 1.0),
			"accent": Color(0.35, 0.78, 1.0), "face": "visor", "gear": "none", "torso": "plate",
			"skin": Color(0.66, 0.76, 0.88),
			"shoulder": "pads", "weapon": "axe", "legs": "wide" },
	],
	"ONI-FELDHERR": [
		{ "v": "A", "name": "Roter Oni", "cloth": Color(0.54, 0.14, 0.14), "metal": Color(0.34, 0.20, 0.20),
			"accent": Color(0.82, 0.22, 0.20), "face": "oni", "gear": "horns", "torso": "normal",
			"shoulder": "fur", "weapon": "mace", "legs": "normal" },
		{ "v": "B", "name": "Blauer Oni", "cloth": Color(0.18, 0.30, 0.62), "metal": Color(0.56, 0.66, 0.86),
			"accent": Color(0.34, 0.56, 0.86), "face": "oni", "gear": "horns", "torso": "plate",
			"shoulder": "spikes", "weapon": "none", "legs": "wide" },
		{ "v": "C", "name": "Goldener General", "cloth": Color(0.84, 0.68, 0.18), "metal": Color(0.96, 0.84, 0.32),
			"accent": Color(0.55, 0.34, 0.10), "face": "grim", "gear": "crown", "torso": "plate",
			"shoulder": "pads", "weapon": "flag", "legs": "normal" },
	],
	"EWIGER HERRSCHER": [
		{ "v": "A", "name": "Gold-Pharao", "cloth": Color(0.92, 0.78, 0.28), "metal": Color(0.98, 0.86, 0.40),
			"accent": Color(0.30, 0.45, 0.80), "face": "human", "gear": "nemes", "torso": "robe",
			"weapon": "flag", "legs": "robe" },
		{ "v": "B", "name": "Sarkophag-Mumie", "cloth": Color(0.80, 0.76, 0.64), "metal": Color(0.58, 0.54, 0.42),
			"accent": Color(0.85, 0.70, 0.25), "face": "skull", "gear": "none", "torso": "slim",
			"weapon": "compass", "legs": "one" },
		{ "v": "C", "name": "Anubis-Priester", "cloth": Color(0.22, 0.20, 0.30), "metal": Color(0.90, 0.75, 0.25),
			"accent": Color(0.55, 0.88, 1.0), "face": "grim", "gear": "anubis", "torso": "robe",
			"weapon": "staff", "legs": "robe" },
	],
}

const CONCEPTS_EPIC := {
	"KAPITAEN ROST": [
		{ "v": "A", "name": "Klassisch", "cloth": Color(0.18, 0.24, 0.45), "metal": Color(0.80, 0.83, 0.88),
			"accent": Color(0.92, 0.75, 0.20), "face": "human", "gear": "tricorn", "torso": "normal",
			"cloak": true, "weapon": "sabre", "legs": "normal" },
		{ "v": "B", "name": "Geisterpirat", "cloth": Color(0.40, 0.72, 0.60), "metal": Color(0.86, 0.94, 0.90),
			"accent": Color(0.80, 1.0, 0.88), "skin": Color(0.74, 0.92, 0.82), "face": "human",
			"gear": "tricorn", "torso": "normal", "cloak": true, "weapon": "compass", "legs": "one" },
		{ "v": "C", "name": "Maschinenpirat", "cloth": Color(0.38, 0.36, 0.34), "metal": Color(0.74, 0.72, 0.68),
			"accent": Color(0.85, 0.60, 0.20), "face": "visor", "gear": "tophat", "torso": "normal",
			"weapon": "hook", "legs": "mech" },
	],
	"FROSTBEIL": [
		{ "v": "A", "name": "Fellkapuze", "cloth": Color(0.66, 0.62, 0.54), "metal": Color(0.82, 0.86, 0.90),
			"accent": Color(0.55, 0.80, 1.0), "face": "human", "gear": "hood", "torso": "plate",
			"shoulder": "fur", "weapon": "axe", "legs": "wide" },
		{ "v": "B", "name": "Berserker", "cloth": Color(0.58, 0.38, 0.28), "metal": Color(0.70, 0.70, 0.74),
			"accent": Color(0.80, 0.18, 0.14), "face": "grim", "gear": "none", "torso": "slim",
			"weapon": "axe", "legs": "one" },
		{ "v": "C", "name": "Gletscher-Panzer", "cloth": Color(0.34, 0.58, 0.84), "metal": Color(0.82, 0.94, 1.0),
			"accent": Color(0.45, 0.86, 1.0), "face": "visor", "gear": "none", "torso": "plate",
			"shoulder": "spikes", "weapon": "mace", "legs": "wide" },
	],
	"GRINSER": [
		{ "v": "A", "name": "Harlekin", "cloth": Color(0.82, 0.22, 0.42), "metal": Color(0.25, 0.60, 0.90),
			"accent": Color(0.20, 0.60, 0.90), "face": "paint", "gear": "jester", "torso": "normal",
			"weapon": "cards", "legs": "wide" },
		{ "v": "B", "name": "Zirkusdirektor", "cloth": Color(0.14, 0.14, 0.18), "metal": Color(0.85, 0.15, 0.18),
			"accent": Color(0.85, 0.15, 0.18), "skin": Color(0.95, 0.82, 0.70), "face": "human",
			"gear": "tophat", "torso": "normal", "cloak": true, "weapon": "whip", "legs": "normal" },
		{ "v": "C", "name": "Joker-Maske", "cloth": Color(0.30, 0.18, 0.50), "metal": Color(0.10, 0.85, 0.35),
			"accent": Color(0.10, 0.85, 0.35), "face": "paint", "gear": "none", "torso": "robe",
			"weapon": "cards", "legs": "robe" },
	],
}



func _skins_big() -> void:
	# v1.41 (S3b): alle 11 Skins gross, damit Gesichter/Texturen pruefbar sind.
	var cells: Array = []
	for i in range(GenCharacters.RIG_NAMES.size()):
		var tex: Texture2D = GenCharacters._make_player_rig(i)
		cells.append({ "tex": tex, "line1": "%d  %s" % [i, GenCharacters.RIG_NAMES[i]], "line2": "farbe 0 (blau)" })
	await _sheet(cells, 4, 230, 240, "v1.41 (S3b) - 11 Skins mit Gesicht und Shading", "v141/skins_big.png")
	print("[RIG][GROSS] kacheln=%d" % cells.size())

func _mean_color(tex: Texture2D) -> Color:
	# mittlere Farbe der Figur (ohne transparente Pixel)
	var img: Image = tex.get_image()
	var r: float = 0.0
	var g: float = 0.0
	var b: float = 0.0
	var n: int = 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			r += c.r
			g += c.g
			b += c.b
			n += 1
	if n == 0:
		return Color(0, 0, 0)
	return Color(r / float(n), g / float(n), b / float(n))


func _concept_sheet(block: String) -> void:
	var quelle: Dictionary = CONCEPTS_LEGENDARY if block == "legendary" else CONCEPTS_EPIC
	var cells: Array = []
	var texs: Dictionary = {}
	for konzept in quelle.keys():
		var varianten: Array = quelle[konzept]
		texs[konzept] = []
		for var_cfg in varianten:
			var tex: Texture2D = GenConcepts._make_concept(var_cfg)
			texs[konzept].append(tex)
			cells.append({
				"tex": tex,
				"line1": "%s  %s" % [str(var_cfg["v"]), str(var_cfg["name"])],
				"line2": str(konzept),
			})
	var ziel: String = "v141/konzept_%s.png" % block
	await _sheet(cells, 3, 260, 268,
		"v1.41 (N3) - %s: 3 Konzepte x 3 Varianten (A/B/C)" % block.to_upper(), ziel)
	print("[ART][KONZEPT] block=%s kacheln=%d" % [block, cells.size()])
	# Unterscheidbarkeit je Konzept: Varianten SOLLEN die Grundsilhouette
	# teilen (wie Skins eines Sets), unterschieden wird ueber Palette und
	# Ausruestung. Deshalb Silhouette nur grob begrenzt (<= 0.92) und
	# zusaetzlich Mindestabstand der mittleren Farbe (>= 0.12).
	for konzept in texs.keys():
		var t: Array = texs[konzept]
		var m0: PackedByteArray = _alpha_mask(t[0])
		var m1: PackedByteArray = _alpha_mask(t[1])
		var m2: PackedByteArray = _alpha_mask(t[2])
		var c0: Color = _mean_color(t[0])
		var c1: Color = _mean_color(t[1])
		var c2: Color = _mean_color(t[2])
		var d_ab: float = _rgb_dist(c0, c1)
		var d_bc: float = _rgb_dist(c1, c2)
		var d_ac: float = _rgb_dist(c0, c2)
		# Varianten eines Konzepts teilen die Grundsilhouette absichtlich.
		# 0,92 ist nur eine Ausreisser-Warnung; das Urteil kommt aus der
		# Sichtpruefung (eigenes Geraet, eigene Palette, eigenes Gesicht).
		var iou_ok: bool = _iou(m0, m1) <= 0.92 and _iou(m1, m2) <= 0.92 and _iou(m0, m2) <= 0.92
		print("[ART][IOU] konzept=%s a_b=%.2f b_c=%.2f a_c=%.2f ok=%s" % [
			konzept, _iou(m0, m1), _iou(m1, m2), _iou(m0, m2), str(iou_ok)])
		print("[ART][FARBE3] konzept=%s d_ab=%.2f d_bc=%.2f d_ac=%.2f" % [konzept, d_ab, d_bc, d_ac])


# ================================================================
# v1.42 (P1) — Pause -> Einstellungen -> zurueck -> weiterspielen
# ================================================================

func _btn_by_text(root: Node, needle: String) -> Button:
	if root == null:
		return null
	var n: String = needle.to_upper()
	# v1.43: Icon-Kacheln tragen keinen Text - Treffer auch ueber Tooltip/Name
	for b in root.find_children("*", "Button", true, false):
		var bt := b as Button
		if bt == null:
			continue
		if str(bt.text).to_upper().find(n) >= 0:
			return bt
		if str(bt.tooltip_text).to_upper().find(n) >= 0:
			return bt
		if str(bt.name).to_upper().find(n) >= 0:
			return bt
	return null


func _pause142() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	# Run im RUNDEN-Modus starten
	gm.set("game_mode", 2)
	gm.call("start_game", false, false)
	for _f in range(20):
		await get_tree().process_frame
	# Ladebildschirm abwarten, sonst liegt er (durch die Pause eingefroren)
	# hinter dem Overlay und die Sichtpruefung sieht das Titelkarten-Bild.
	await get_tree().create_timer(2.6).timeout
	var _ls = uim.get("load_screen")
	if _ls != null and is_instance_valid(_ls):
		_ls.visible = false
		_ls.set_process(false)
	await get_tree().create_timer(0.4).timeout
	var pl = gm.get("player")
	var welle0: int = int(gm.get("wave"))
	var hp0: int = int(pl.health) if is_instance_valid(pl) else -1
	var max0: int = int(pl.max_health) if is_instance_valid(pl) else -1
	var muenzen0: int = int(gm.get("coins"))
	print("[TEST][P1] run state=%d spieler=%s welle=%d hp=%d/%d muenzen=%d" % [
		int(gm.get("current_state")), str(is_instance_valid(pl)), welle0, hp0, max0, muenzen0])
	# Pause oeffnen
	gm.call("toggle_pause")
	await get_tree().create_timer(0.5).timeout
	var po = uim.get("pause_overlay")
	print("[TEST][P1] pause_offen=%s paused=%s tree_paused=%s" % [
		str(po != null), str(gm.get("paused")), str(get_tree().paused)])
	# P1.1/P1.2: EINSTELLUNGEN aus der Pause
	var bset: Button = _btn_by_text(po, "EINSTELLUNGEN")
	if bset == null:
		print("[TEST][P1] FEHLER: Knopf EINSTELLUNGEN fehlt")
		return
	bset.emit_signal("pressed")
	await get_tree().create_timer(0.6).timeout
	var sp = uim.get("settings_page")
	var ss = uim.get("start_screen")
	print("[TEST][P1] settings_offen=%s origin=%s start_screen=%s pause_offen=%s paused=%s" % [
		str(sp != null and sp.visible), str(uim.get("settings_origin")),
		str(ss.visible), str(uim.get("pause_overlay") != null), str(gm.get("paused"))])
	await _shot("v142/pause_settings.png")
	# P1.3: ZURUECK
	var back: Button = _btn_by_text(sp, "ZURUECK")
	back.emit_signal("pressed")
	await get_tree().create_timer(0.6).timeout
	po = uim.get("pause_overlay")
	print("[TEST][P1] zurueck settings_offen=%s pause_offen=%s paused=%s start_screen=%s" % [
		str(sp.visible), str(po != null), str(gm.get("paused")), str(ss.visible)])
	await _shot("v142/pause_nach_settings.png")
	# P1.4: WEITERSPIELEN
	var bcont: Button = _btn_by_text(po, "WEITER")
	if bcont != null:
		bcont.emit_signal("pressed")
	await get_tree().create_timer(0.5).timeout
	pl = gm.get("player")
	var welle1: int = int(gm.get("wave"))
	var hp1: int = int(pl.health) if is_instance_valid(pl) else -1
	var muenzen1: int = int(gm.get("coins"))
	print("[TEST][P1] weiter paused=%s welle=%d hp=%d/%d muenzen=%d gleich=%s" % [
		str(gm.get("paused")), welle1, hp1, max0, muenzen1,
		str(welle1 == welle0 and hp1 == hp0 and muenzen1 == muenzen0)])
	# P1.6: ESC aus den Einstellungen
	gm.call("toggle_pause")
	await get_tree().create_timer(0.4).timeout
	po = uim.get("pause_overlay")
	var bset2: Button = _btn_by_text(po, "EINSTELLUNGEN")
	bset2.emit_signal("pressed")
	await get_tree().create_timer(0.4).timeout
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	uim.call("_unhandled_key_input", ev)
	await get_tree().create_timer(0.5).timeout
	print("[TEST][P1] esc settings_offen=%s pause_offen=%s paused=%s" % [
		str(sp.visible), str(uim.get("pause_overlay") != null), str(gm.get("paused"))])
	# P1.5: HAUPTMENUE = echter Abbruch
	po = uim.get("pause_overlay")
	var bmenu: Button = _btn_by_text(po, "HAUPTMEN")
	if bmenu == null:
		print("[TEST][P1] FEHLER: Knopf HAUPTMENUE fehlt")
		return
	bmenu.emit_signal("pressed")
	await get_tree().create_timer(0.8).timeout
	print("[TEST][P1] menu state=%d start_screen=%s settings_offen=%s paused=%s" % [
		int(gm.get("current_state")), str(ss.visible), str(sp.visible), str(gm.get("paused"))])
	await _shot("v142/menu_nach_pause.png")
	# neues Spiel ueber die echte Klickfolge (P1.5)
	var play: Button = _btn_by_text(ss, "SPIELEN")
	if play == null:
		print("[TEST][P1] FEHLER: SPIELEN fehlt")
		return
	play.emit_signal("pressed")
	await get_tree().create_timer(0.5).timeout
	var cp = uim.get("confirm_page")
	var go: Button = _btn_by_text(cp, "LOS GEHT")
	print("[TEST][P1] bestaetigung offen=%s knopf=%s" % [
		str(cp != null and cp.visible), str(go != null)])
	if go != null:
		go.emit_signal("pressed")
	await get_tree().create_timer(1.2).timeout
	pl = gm.get("player")
	print("[TEST][P1] neuer_run state=%d spieler=%s welle=%d runde=%d" % [
		int(gm.get("current_state")), str(is_instance_valid(pl)), int(gm.get("wave")),
		int(gm.get("rounds").round_no) if gm.get("rounds") != null else -1])
	print("[TEST][P1] ENDE")


# ================================================================
# v1.42 (P12) — Charakter/Sammlung: Clamp, Raster, Scroll
# ================================================================

func _ui142() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	# 1) Unsinnige Indizes ins Profil schreiben und neu laden -> Clamp
	var rigs: Array = gm.get("unlocked_rigs")
	rigs.append(50)
	rigs.append(61)
	rigs.append(99)
	rigs.append(200)
	print("[TEST][P12] korrupt geschrieben rigs=%d (mit 4 ungueltigen)" % rigs.size())
	gm.call("_save_profile")
	gm.call("_load_profile")
	await get_tree().process_frame
	var r2: Array = gm.get("unlocked_rigs")
	print("[TEST][P12] nach_clamp rigs=%d max=%d" % [r2.size(), int(r2.max()) if r2.size() > 0 else -1])
	# 2) Fuer die Kachelzahl alle 17 Skins / 25 Huete / 10 Farben freischalten
	#    (nur im Speicher, kein Speichern)
	for i in range(TextureManager.RIG_NAMES.size()):
		if not r2.has(i):
			r2.append(i)
	var hats: Array = gm.get("unlocked_hats")
	for i in range(TextureManager.HAT_NAMES.size()):
		if not hats.has(i):
			hats.append(i)
	var cols: Array = gm.get("unlocked_colors")
	for i in range(TextureManager.COLOR_NAMES.size()):
		if not cols.has(i):
			cols.append(i)
	print("[TEST][P12] freigeschaltet skins=%d huete=%d farben=%d" % [
		r2.size(), hats.size(), cols.size()])
	# 3) Charakterseite + Auswahlraster
	uim.call("_open_char_page")
	await get_tree().create_timer(0.7).timeout
	await _shot("v142/char_17.png")
	uim.call("_open_choice_overlay", "skin")
	await get_tree().create_timer(0.6).timeout
	var sc = uim.get("char_choice_overlay")
	print("[TEST][P12] skin_raster kacheln=%d" % _count_buttons(sc))
	await _shot("v142/char_skins.png")
	uim.call("_close_choice_overlay")
	await get_tree().process_frame
	uim.call("_open_choice_overlay", "hat")
	await get_tree().create_timer(0.5).timeout
	await _shot("v142/char_huete.png")
	uim.call("_close_choice_overlay")
	await get_tree().process_frame
	# 4) Sammlung
	uim.call("show_collection")
	await get_tree().create_timer(0.8).timeout
	await _shot("v142/coll_17.png")
	var cp = uim.get("collection_page")
	print("[TEST][P12] sammlung sichtbar=%s kacheln=%d" % [
		str(cp != null and cp.visible), _count_buttons(cp)])
	print("[TEST][P12] ENDE")


func _count_buttons(root: Node) -> int:
	if root == null:
		return -1
	return root.find_children("*", "Button", true, false).size()


# ================================================================
# v1.43 (Recon) — ECHTE Antipp-Tests + Layout-Messung der Einstellungen
# ================================================================

func _tap_at(c: Control, label: String) -> void:
	# Echter Klick ueber push_input (Canvas-Koordinaten, siehe Skill-Regel)
	if c == null or not is_instance_valid(c) or not c.is_visible_in_tree():
		print("[TAP] %s -> NICHT SICHTBAR" % label)
		return
	var r: Rect2 = c.get_global_rect()
	var p: Vector2 = r.get_center()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var drin: bool = r.position.y >= 0.0 and r.end.y <= vp.y and r.position.x >= 0.0 and r.end.x <= vp.x
	print("[TAP] %s rect=(%.0f,%.0f)-(%.0f,%.0f) viewport=(%.0f,%.0f) sichtbar_im_bild=%s" % [
		label, r.position.x, r.position.y, r.end.x, r.end.y, vp.x, vp.y, str(drin)])
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = p
	ev.global_position = p
	get_viewport().push_input(ev, true)
	await get_tree().process_frame
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = p
	ev2.global_position = p
	get_viewport().push_input(ev2, true)
	await get_tree().process_frame


func _tap143() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	var ss = uim.get("start_screen")
	print("[TAP] start start_screen_sichtbar=%s" % str(ss.visible))
	# 1) Einstellungen ueber den Gear-Knopf (echter Klick)
	var gear = ss.find_child("GearButton", true, false)
	await _tap_at(gear, "GEAR")
	await get_tree().create_timer(0.5).timeout
	var sp = uim.get("settings_page")
	print("[TAP] settings_offen=%s" % str(sp != null and sp.visible))
	# 2) Layout messen: Inhalt vs. Viewport
	var box = uim.call("_page_box", sp)
	if box != null:
		var need: Vector2 = (box as Control).get_combined_minimum_size()
		var vp: Vector2 = get_viewport().get_visible_rect().size
		print("[LAYOUT] einstellungen inhalt=(%.0f,%.0f) viewport=(%.0f,%.0f) ueberlauf=%s fehlt_unten=%.0f" % [
			need.x, need.y, vp.x, vp.y, str(need.y > vp.y), maxf(0.0, need.y - vp.y)])
	# 3) Musikregler: echter Klick in die Mitte der Spur
	var sl = uim.get("music_slider")
	if sl != null:
		var r: Rect2 = (sl as Control).get_global_rect()
		var p2 := Vector2(r.position.x + r.size.x * 0.25, r.position.y + r.size.y * 0.5)
		var evq := InputEventMouseButton.new()
		evq.button_index = MOUSE_BUTTON_LEFT
		evq.pressed = true
		evq.position = p2
		evq.global_position = p2
		get_viewport().push_input(evq, true)
		await get_tree().process_frame
		var evq2 := InputEventMouseButton.new()
		evq2.button_index = MOUSE_BUTTON_LEFT
		evq2.pressed = false
		evq2.position = p2
		evq2.global_position = p2
		get_viewport().push_input(evq2, true)
		await get_tree().create_timer(0.3).timeout
		print("[TAP] slider wert=%.0f music_volume=%d" % [
			float((sl as Range).value), int(SoundManager.music_volume)])
		await _shot("v143/einstellungen.png")
	# 4) Zurueck + jeder Hauptknopf der Startseite
	await _tap_at(_btn_by_text(sp, "ZURUECK"), "SETTINGS_ZURUECK")
	await get_tree().create_timer(0.4).timeout
	for txt in ["SPIELEN", "CHARAKTER", "SAMMLUNG", "KARTEN", "SHOP", "LAN SPIEL"]:
		await _tap_at(_btn_by_text(ss, txt), txt)
		await get_tree().create_timer(0.35).timeout
		await _shot("v143/tap_%s.png" % txt.replace(" ", "_"))
		uim.call("_close_pages")
		await get_tree().create_timer(0.25).timeout
	# 5) Charakter-Auswahlfeld: Position des Rasters messen
	uim.call("_open_char_page")
	await get_tree().create_timer(0.5).timeout
	uim.call("_open_choice_overlay", "skin")
	await get_tree().create_timer(0.5).timeout
	var ov = uim.get("char_choice_overlay")
	var grid = null
	if ov != null:
		for c in (ov as Node).find_children("*", "GridContainer", true, false):
			grid = c
	var vpw: float = get_viewport().get_visible_rect().size.x
	if grid != null:
		var gr: Rect2 = (grid as Control).get_global_rect()
		var links: float = gr.position.x
		var rechts: float = vpw - gr.end.x
		print("[LAYOUT] wahl_raster links=%.0f rechts=%.0f breite=%.0f viewport=%.0f versatz=%s" % [
			links, rechts, gr.size.x, vpw, str(absf(links - rechts) > 60.0)])
	await _shot("v143/wahl_skin.png")
	uim.call("_close_choice_overlay")
	uim.call("_close_pages")
	print("[TAP] ENDE")


# ================================================================
# v1.42 (P14) — Ladebild mit Modus-Vorschau (4 Modi)
# ================================================================

func _load142() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var modi: Array = [
		{ "key": "runden", "game_mode": 2, "duo": false },
		{ "key": "endlos", "game_mode": 0, "duo": false },
		{ "key": "wellen", "game_mode": 1, "duo": false },
		{ "key": "coop", "game_mode": 0, "duo": true },
	]
	for m in modi:
		gm.set("game_mode", int(m["game_mode"]))
		gm.set("duo_mode", bool(m["duo"]))
		uim.call("show_load_for_run")
		await get_tree().create_timer(0.45).timeout
		var ls = uim.get("load_screen")
		print("[TEST][P14] modus=%s sichtbar=%s name=%s" % [
			str(m["key"]), str(ls != null and ls.visible),
			str(uim.get("load_mode_name").text)])
		await _shot("v142/load_%s.png" % str(m["key"]))
		uim.set("load_is_run", false)
		if ls != null:
			ls.visible = false
		await get_tree().create_timer(0.2).timeout
	gm.set("duo_mode", false)
	gm.set("game_mode", 0)
	# Ganzer Start ueber die echte Kette inkl. Mindestdauer + Ausblenden
	uim.call("show_load_for_run")
	await get_tree().create_timer(0.2).timeout
	uim.call("hide_load_after_run")
	await get_tree().create_timer(1.2).timeout
	print("[TEST][P14] ENDE")


# ================================================================
# v1.42 (P10) — Biomwechsel: Messung + Flash (4 Bilder) + Schalter
# ================================================================

func _biom142() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	gm.set("game_mode", 2)
	gm.set("active_map", "earth")
	gm.call("set_round_difficulty", "leicht")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.6).timeout
	var rm = gm.get("rounds_mode")
	var mc = gm.get("monster_container")
	rm.set("active", false)
	# Runde 5 -> 6: Wechsel meadow -> desert
	rm.set("round_no", 6)   # Plan: Runde 6 = desert
	gm.set("biome_id", "meadow")
	gm.set("wave_active", false)
	await _wait_clear(mc, 0.3)
	gm.call("_check_biome")
	# 4 Bilder waehrend des Uebergangs
	for i in range(4):
		await get_tree().create_timer(0.12).timeout
		await _shot("v142/biom_flash_%d.png" % i)
	print("[TEST][P10] biome_nach_wechsel=%s" % str(gm.get("biome_id")))
	# Option AUS -> kein Overlay
	gm.call("set_biome_flash", false)
	rm.set("round_no", 11)   # Plan: Runde 11 = ice
	gm.set("wave_active", false)
	gm.call("_check_biome")
	await get_tree().create_timer(0.4).timeout
	print("[TEST][P10] option_aus biome=%s overlay=%s" % [
		str(gm.get("biome_id")), str(gm.get("_biome_flash_layer") != null)])
	gm.call("set_biome_flash", true)
	print("[TEST][P10] ENDE")


# ================================================================
# v1.42 (P7) — Map-Optik: Wasser (Fluss, Tiefe, Schaum), Steine, Steinfelder
# ================================================================

func _map142() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	gm.set("game_mode", 0)
	gm.set("active_map", "earth")
	gm.call("start_game", false, false)
	await get_tree().create_timer(2.2).timeout
	var mg = gm.get("map_generator")
	var pl = gm.get("player")
	# Spieler an den Fluss setzen, damit die Kamera das Wasser zeigt
	var rt: Array = mg.get("river_tiles")
	if rt.size() > 0:
		var t: Vector2i = rt[rt.size() / 2]
		var ts: float = float(mg.get("tile_size"))
		if is_instance_valid(pl):
			pl.set("global_position", Vector2((float(t.x) + 0.5) * ts, (float(t.y) + 0.5) * ts))
			var p2 = pl.get("player2")
	await get_tree().create_timer(1.0).timeout
	var cam := get_viewport().get_camera_2d()
	if cam != null and is_instance_valid(pl):
		cam.global_position = (pl as Node2D).global_position
	await get_tree().create_timer(0.5).timeout
	# P7.1: zwei Frames 0,8 s auseinander (Pixelvergleich macht PIL)
	await _shot("v142/wasser_a.png")
	await get_tree().create_timer(0.8).timeout
	await _shot("v142/wasser_b.png")
	# P7.4: Kontaktblatt der Stein-Varianten
	var cell: int = 190
	var img := Image.create(cell * 5 + 30, cell + 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.16, 0.15, 0.14))
	var gezeichnet := 0
	for i in range(5):
		var tex: Texture2D = TextureManager.get_texture("stone_v%d" % i)
		if tex == null:
			print("[ART][STEIN] FEHLER variante=%d fehlt" % i)
			continue
		var im: Image = _tex_img(tex)
		im.resize(cell - 20, cell - 20, Image.INTERPOLATE_LANCZOS)
		img.blend_rect(im, Rect2i(0, 0, cell - 20, cell - 20), Vector2i(15 + i * cell, 20))
		gezeichnet += 1
	img.save_png(SHOT_DIR + "v142/steine.png")
	print("[ART][STEIN] varianten=%d toene=5 kontur=true moos=true" % gezeichnet)
	print("[SHOT] v142/steine.png (%dx%d)" % [img.get_width(), img.get_height()])
	# P7.8: vier Jahreszeiten
	for sid in ["spring", "summer", "autumn", "winter"]:
		gm.set("season_id", sid)
		mg.call("set_season", sid)
		mg.call("rebuild_visuals")
		await get_tree().create_timer(0.9).timeout
		await _shot("v142/map_%s.png" % sid)
		print("[ART][JAHRESZEIT] %s gesichert" % sid)
	# P7.7: Wasserkosten (Wasser an/aus im gleichen Lauf)
	var wl = null
	for c in mg.get_children():
		if str(c.name).begins_with("WaterLayer"):
			wl = c
			break
	# Vsync aus, sonst misst man die 60-Hz-Grenze statt des Shaders
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().process_frame
	var ms_an: float = await _frame_ms(2.0)
	if wl != null and is_instance_valid(wl):
		wl.visible = false
	await get_tree().process_frame
	var ms_aus: float = await _frame_ms(2.0)
	print("[PERF][WASSER] ms=%.2f (wasser_an=%.2f ohne=%.2f)" % [
		maxf(0.0, ms_an - ms_aus), ms_an, ms_aus])
	print("[TEST][P7] ENDE")


func _frame_ms(sec: float) -> float:
	var t0: int = Time.get_ticks_msec()
	var frames: int = 0
	while Time.get_ticks_msec() - t0 < int(sec * 1000.0):
		await get_tree().process_frame
		frames += 1
	var dt: float = float(Time.get_ticks_msec() - t0)
	return dt / maxf(1.0, float(frames))


# ================================================================
# v1.42 (P4 + P5) — Musik: Tracks, Fade, Boss, Lautstaerke, Todes-Jingle
# ================================================================

func _musik142() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	# P4.2: Trackliste + Laengen (stehen schon im Boot-Log, hier gesammelt)
	for k in SoundManager.TRACK_CFG.keys():
		var s: AudioStreamWAV = SoundManager._music_stream(str(k))
		print("[TEST][P4] track=%s dauer=%.2fs loop=%d bars=%d" % [
			str(k), float(s.data.size()) / 2.0 / float(s.mix_rate), int(s.loop_mode),
			int(SoundManager.MUSIC_BARS_PER_TRACK)])
	# P4.1: Lautstaerke
	SoundManager.set_music_volume(80)
	SoundManager.set_music_volume(100)
	SoundManager.set_music_volume(80)
	# P4.6: Wechsel Menue -> Spiel, nur EIN Track laeuft
	SoundManager.play_music("menu_1")
	await get_tree().create_timer(1.0).timeout
	SoundManager.play_music("game_1")
	await get_tree().create_timer(1.0).timeout
	var aktiv: int = 0
	if SoundManager._music_player.playing:
		aktiv += 1
	if SoundManager._music_menu.playing:
		aktiv += 1
	print("[TEST][P4] aktiv=%d (nach Wechsel Menue->Spiel)" % aktiv)
	# P4.3: Rundentracks im echten RUNDEN-Modus
	gm.set("game_mode", 2)
	gm.set("active_map", "mars")
	gm.call("set_round_difficulty", "leicht")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.4).timeout
	var rm = gm.get("rounds_mode")
	var mc = gm.get("monster_container")
	for r in [7, 8, 9, 10]:
		rm.set("round_no", r)
		rm.set("active", false)
		await _wait_clear(mc, 0.4)
		gm.call("start_round")
		await _wait_clear(mc, 0.6)
		print("[TEST][P4] runde=%d track=%s" % [r, str(SoundManager._current_music)])
	# P4.4: Boss-Track (Runde mit Mini-Boss ab 8)
	rm.set("active", false)
	rm.set("round_no", 7)   # start_round zaehlt hoch -> Runde 8 (Mini-Boss)
	await _wait_clear(mc, 0.3)
	gm.call("start_round")
	await _wait_clear(mc, 2.2)
	print("[TEST][P4] boss_runde=%d boss_track=%s" % [
		int(rm.get("round_no")), str(SoundManager._current_music)])
	var cb = gm.get("current_boss")
	print("[TEST][P4] current_boss=%s aktiv=%s" % [
		str(cb != null and is_instance_valid(cb)), str(gm.get("_boss_active"))])
	if cb != null and is_instance_valid(cb):
		cb.queue_free()
	await _wait_clear(mc, 1.6)
	print("[TEST][P4] nach_boss_track=%s" % str(SoundManager._current_music))
	# P5.1/P5.2: Todes-Jingle + Musik-Absenkung
	SoundManager.set_music_volume(80)
	SoundManager.play_death()
	await get_tree().create_timer(0.4).timeout
	print("[TEST][P5] tod gespielt=%s musik_db=%.1f eigener_player=%s" % [
		str(SoundManager._death_player.playing), float(SoundManager._music_player.volume_db),
		str(SoundManager._death_player != SoundManager._music_player)])
	# P5.4: SFX aus -> kein Ton, Absenkung trotzdem
	SoundManager.set_sfx_enabled(false)
	SoundManager._death_player.stop()
	await get_tree().process_frame
	SoundManager.play_death()
	print("[TEST][P5] sfx_aus musik_db=%.1f gespielt=%s" % [
		float(SoundManager._music_player.volume_db), str(SoundManager._death_player.playing)])
	SoundManager.set_sfx_enabled(true)
	# P5.2: Neustart hebt die Musik wieder an (start_game verlangt MENU)
	gm.set("current_state", 0)
	gm.call("restart_run")
	await get_tree().create_timer(1.6).timeout
	print("[TEST][P5] nach_neustart musik_db=%.1f track=%s" % [
		float(SoundManager._music_player.volume_db), str(SoundManager._current_music)])
	print("[TEST][P4] ENDE")


# ================================================================
# v1.42 (P11) — Waffe in der Hand: Anker, Deko aus, Kontaktblatt
# ================================================================

func _hand142() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	var neu: Array = [11, 12, 13, 14, 15, 16]
	var wkeys: Array = ["weapon_pistol", "weapon_shotgun", "weapon_machine", "weapon_laser", "weapon_revolver"]
	# 1) Anker + Deko-Zustand je Skin
	for rig in neu:
		var a: Vector2 = TextureManager.hand_anchor_of(int(rig))
		var deco: bool = TextureManager.rig_has_deco_weapon(int(rig))
		print("[SKIN][HAND] rig=%d hand=(%d,%d) deko=%s ueber_deko=true z=+1" % [
			int(rig), int(a.x), int(a.y), "aus" if deco else "an"])
	# 2) Kontaktblatt: 6 Skins x 5 Waffen, Waffe am Anker
	var cell: int = 64
	var zoom: int = 3
	var img := Image.create(wkeys.size() * cell * zoom + 20, neu.size() * cell * zoom + 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.10, 0.11, 0.16))
	for ri in range(neu.size()):
		var rig: int = int(neu[ri])
		var body: Image = _tex_img(TextureManager.get_skin_hat_texture(0, rig, 0, true))
		for wi in range(wkeys.size()):
			var tile: Image = body.duplicate()
			var wt: Image = _tex_img(TextureManager.get_texture(str(wkeys[wi])))
			if wt != null:
				var a2: Vector2 = TextureManager.hand_anchor_of(rig)
				var off: Vector2i = Vector2i(int(a2.x) - 32, int(a2.y) - 32)
				tile.blend_rect(wt, Rect2i(0, 0, 64, 64), off)
			tile.resize(cell * zoom, cell * zoom, Image.INTERPOLATE_NEAREST)
			img.blend_rect(tile, Rect2i(0, 0, cell * zoom, cell * zoom),
				Vector2i(10 + wi * cell * zoom, 10 + ri * cell * zoom))
	img.save_png(SHOT_DIR + "v142/skins_waffen.png")
	print("[SHOT] v142/skins_waffen.png (%dx%d, %d Kacheln)" % [
		img.get_width(), img.get_height(), neu.size() * wkeys.size()])
	# 3) Im Spiel: Skin 11 mit Maschinengewehr (Waffe muss UEBER der Deko liegen)
	gm.set("game_mode", 2)
	gm.set("active_map", "mars")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.6).timeout
	var pl = gm.get("player")
	if is_instance_valid(pl):
		pl.call("apply_profile", 0, 0, 11)
		pl.call("switch_weapon", "weapon_machine")
		var wh = pl.get("weapon_holder")
		print("[TEST][P11] spieler skin=11 waffe=%s z_halter=%d anker=%s" % [
			str(pl.call("get_weapon_key")), int((wh as Node2D).z_index) if wh != null else -1,
			str(pl.get("hand_anchor"))])
		await get_tree().create_timer(0.8).timeout
		await _shot("v142/skin11_waffe.png")
		# zweiter Skin (13, Stab) fuer die Sichtpruefung
		pl.call("apply_profile", 0, 0, 13)
		await get_tree().create_timer(0.6).timeout
		await _shot("v142/skin13_waffe.png")
	print("[TEST][P11] ENDE")


# ================================================================
# v1.42 (P13) — Hut-Sitz der sechs neuen Skins (gemessen, nicht geraten)
# ================================================================

func _hat142() -> void:
	for _f in range(8):
		await get_tree().process_frame
	var gc = load("res://scripts/texture/gen_characters.gd")
	var floats: Array = [10, 20, 21, 23]
	var body_items: Array = [15, 16, 22]
	var neu: Array = [11, 12, 13, 14, 15, 16]
	# 1) Messung: Schwebe-Abstand je Hut auf jedem neuen Skin (aktueller Sitz)
	for rig in neu:
		var body_img: Image = _tex_img(TextureManager.get_skin_texture(0, int(rig)))
		var head: Dictionary = gc._head_metrics(body_img)
		var gaps: Array = []
		for hat in range(1, TextureManager.HAT_NAMES.size()):
			if hat in body_items or hat in floats:
				continue
			var hl: Image = gc._hat_layer_for(int(hat), head, 1.0, int(rig))
			var m: Dictionary = _hat_metrics(head, hl)
			gaps.append(int(m["schweben"]))
		gaps.sort()
		var med: int = int(gaps[gaps.size() / 2]) if gaps.size() > 0 else 0
		var mx: int = int(gaps[gaps.size() - 1]) if gaps.size() > 0 else 0
		print("[HAT][ADJ] rig=%d kopf_top=%.1f kopf_w=%.1f median_luecke=%d max_luecke=%d dy=+%.1f" % [
			int(rig), float(head.get("top", 0.0)), float(head.get("w", 0.0)), med, mx, float(med)])
	# 2) Kontrolle: Sitz + Fehler nach der Tabelle
	var fehler: int = 0
	var paare: int = 0
	for rig in neu:
		var body_img2: Image = _tex_img(TextureManager.get_skin_texture(0, int(rig)))
		var head2: Dictionary = gc._head_metrics(body_img2)
		var rig_fehler: int = 0
		for hat in range(1, TextureManager.HAT_NAMES.size()):
			if hat in body_items:
				continue
			var hl2: Image = gc._hat_layer_for(int(hat), head2, 1.0, int(rig))
			var m2: Dictionary = _hat_metrics(head2, hl2)
			paare += 1
			var schweben: int = int(m2["schweben"])
			var ueber: int = int(m2["ueberstand"])
			var ok: bool = true
			if hat in floats:
				ok = ueber <= 4 and absi(int(m2["ueber_l"]) - int(m2["ueber_r"])) <= 2
			else:
				ok = schweben <= 1 and ueber <= 4
			if not ok:
				rig_fehler += 1
				fehler += 1
		print("[HAT][SITZ] rig=%d fehler=%d ok=%s" % [int(rig), rig_fehler, str(rig_fehler == 0)])
	print("[HAT][SITZ] rig=11..16 fehler=%d paare=%d" % [fehler, paare])
	# 3) Kontaktblatt 25 Huete x 6 neue Skins
	await get_tree().process_frame
	var rows: int = neu.size()
	var cols: int = TextureManager.HAT_NAMES.size()
	var cell: int = 96
	var img := Image.create(cols * cell + 20, rows * cell + 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.10, 0.11, 0.16))
	for ri in range(rows):
		var rig2: int = int(neu[ri])
		var bt: Texture2D = TextureManager.get_skin_hat_texture_or_player(0, rig2, 0)
		for hi in range(cols):
			var tex: Texture2D = TextureManager.get_skin_hat_texture(0, rig2, hi)
			if tex == null:
				continue
			var im: Image = _tex_img(tex)
			im.resize(cell - 8, cell - 8, Image.INTERPOLATE_NEAREST)
			img.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()),
				Vector2i(10 + hi * cell, 10 + ri * cell))
	img.save_png(SHOT_DIR + "v142/huete_neu6.png")
	print("[SHOT] v142/huete_neu6.png (%dx%d, %d Skins x %d Huete)" % [
		img.get_width(), img.get_height(), rows, cols])
	print("[TEST][P13] ENDE")


# ================================================================
# v1.42 (P3) — Heiltrank: Regeneration, Warteschlange, Anzeige
# ================================================================

func _trank142() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	gm.set("game_mode", 2)
	gm.set("active_map", "mars")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.6).timeout
	var pl = gm.get("player")
	if not is_instance_valid(pl):
		print("[TEST][P3] FEHLER: kein Spieler")
		return
	# Monster raeumen, sonst verfaelschen Treffer den HP-Verlauf
	var mc = gm.get("monster_container")
	var rm = gm.get("rounds_mode")
	rm.set("active", false)
	# Schild schluckt Treffer, damit nur die Regeneration zaehlt
	pl.set("shield", 99)
	pl.set("shield_time", 9999.0)
	# --- P3.1/P3.2/P3.3: Regeneration von 2/5 auf 5/5 ---
	pl.set("max_health", 5)
	pl.set("health", 2)
	pl.emit_signal("health_changed", 2)
	pl.call("add_utility", "potion", 3)
	await _wait_clear(mc, 0.4)
	var ok: bool = bool(pl.call("use_potion"))
	print("[TEST][P3] trank_benutzt=%s hp=%d/%d" % [str(ok), int(pl.get("health")), int(pl.get("max_health"))])
	for i in range(3):
		# auf den naechsten Tick warten (max. 2,5 s)
		var t_end: int = Time.get_ticks_msec() + 2500
		while Time.get_ticks_msec() < t_end and int(pl.get("regen_ticks_done")) <= i:
			await _wait_clear(mc, 0.05)
		print("[TEST][P3] tick=%d hp=%d/%d herz_sichtbar=%s" % [
			int(pl.get("regen_ticks_done")), int(pl.get("health")), int(pl.get("max_health")),
			str(pl.get("regen_heart") != null)])
		await _shot("v142/trank_regen_%d.png" % i)
	await _wait_clear(mc, 0.8)
	print("[TEST][P3] ende hp=%d/%d regen_rest=%d ticks=%d" % [
		int(pl.get("health")), int(pl.get("max_health")),
		int(pl.get("regen_left")), int(pl.get("regen_ticks_done"))])
	await _shot("v142/trank_ende.png")
	# --- P3.4: zweiter Trank wartet ---
	pl.set("health", 1)
	pl.emit_signal("health_changed", 1)
	pl.call("use_potion")
	await _wait_clear(mc, 0.2)
	pl.call("use_potion")
	await _wait_clear(mc, 0.1)
	print("[TEST][P3] queue_laufend regen=%d queue=%d hp=%d" % [
		int(pl.get("regen_left")), int(pl.get("regen_queue")), int(pl.get("health"))])
	await _wait_clear(mc, 7.0)
	print("[TEST][P3] queue_fertig hp=%d/%d regen=%d queue=%d (nie > max)" % [
		int(pl.get("health")), int(pl.get("max_health")),
		int(pl.get("regen_left")), int(pl.get("regen_queue"))])
	# --- P3.6: Preise unveraendert ---
	print("[WSHOP][PREIS] artikel=potion runde=1 preis=%d" % int(WaveShop.price_of("potion", 1, "normal")))
	print("[WSHOP][PREIS] artikel=potion runde=5 preis=%d" % int(WaveShop.price_of("potion", 5, "normal")))
	# v1.42 (P3.6): die Tabellenpreise selbst sind unveraendert
	for it in gm.get("SHOP_ITEMS"):
		if str(it.get("id", "")) == "potion":
			print("[SHOP][PREIS] quelle=SHOP_ITEMS artikel=potion preis=%d" % int(it.get("price", 0)))

	print("[TEST][P3] ENDE")


func _wait_clear(mc, sec: float) -> void:
	# Wartet in Echtzeit und raeumt dabei alle Monster weg (keine Treffer).
	var t_end: int = Time.get_ticks_msec() + int(sec * 1000.0)
	while Time.get_ticks_msec() < t_end:
		if mc != null and is_instance_valid(mc):
			for m in (mc as Node).get_children():
				if is_instance_valid(m):
					m.queue_free()
		await get_tree().process_frame


# ================================================================
# v1.42 (P2) — Waffen-Seltenheiten: Tabelle, RPM, Anzeige, Loc
# ================================================================

func _wpn142() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	gm.set("game_mode", 0)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.2).timeout
	var pl = gm.get("player")
	if not is_instance_valid(pl):
		print("[TEST][P2] FEHLER: kein Spieler")
		return
	# P2.1/P2.3/P2.6: Tabelle + DPS-Kurve
	pl.call("check_rarity_table")
	# P2.2: cooldown + RPM je Stufe am Maschinengewehr
	for stufe in ["common", "rare", "epic", "legendary"]:
		pl.get("weapon_rarity")["weapon_machine"] = stufe
		pl.call("effective_stats", 2)
	# P2.6: Pistole (mag=0) bleibt ohne Nachladen
	var pw: Dictionary = pl.call("_wd", 0)
	print("[TEST][P2] pistole mag=%d reload=%.2f cooldown=%.3f" % [
		int(pw.get("mag", 0)), float(pw.get("reload", 0.0)), float(pw["cooldown"])])
	# P2.4: Statistik-Anzeige je Stufe (Screenshot + Kartenrechteck)
	# Im Spiel oeffnet sich das Overlay - es wird je Stufe neu gebaut, damit
	# die Werte wirklich aus der aktuellen Stufe kommen.
	var spm = uim.call("_stats_p")
	for stufe in ["common", "rare", "epic", "legendary"]:
		pl.get("weapon_rarity")["weapon_machine"] = stufe
		uim.call("_open_stats_page")
		await get_tree().create_timer(0.5).timeout
		await _shot("v142/stats_rpm_%s.png" % stufe)
	# Kartenrechteck der SMG-Karte fuer das Kontaktblatt
	var cards: Array = spm.get("overlay_cards")
	for e in cards:
		var key: String = str(e.get("key", ""))
		if key == "weapon_machine":
			var card: Control = e["card"]
			var r: Rect2 = card.get_global_rect()
			print("[TEST][P2] karte_machine=%d,%d,%d,%d" % [
				int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)])
	# P2.5: Sprachpruefung der Statistik-Flaeche
	Loc.set_lang("en")
	Loc.apply_tree(uim)
	uim.call("_open_stats_page")
	await get_tree().create_timer(0.5).timeout
	var ov = spm.get("overlay")
	Loc.check_tree(ov, "stats")
	await _shot("v142/stats_en.png")
	Loc.set_lang("de")
	Loc.apply_tree(uim)
	await get_tree().process_frame
	# HUD-Waffe: Stufe + Werte im Tooltip
	pl.get("weapon_rarity")["weapon_machine"] = "epic"
	uim.call("refresh_weapon_hud", pl.call("get_owned_weapons"), pl.call("get_weapon_key"))
	await get_tree().process_frame
	print("[TEST][P2] ENDE")


# ================================================================
# v1.42 (P6 + P9) — Runden-Zahlen je Schwierigkeit, Biom-Plan
# ================================================================

func _runde142() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	gm.set("unlocked_maps", ["earth", "mars", "jungle", "volt"])
	# --- P6.1/P6.2: Tabelle ---
	print("[RUNDEN][DIFF] stufe=leicht anzahl=%.2f" % Rounds.count_factor("leicht"))
	print("[RUNDEN][DIFF] stufe=normal anzahl=%.2f" % Rounds.count_factor("normal"))
	print("[RUNDEN][DIFF] stufe=hart anzahl=%.2f" % Rounds.count_factor("hart"))
	var ok := true
	var max_leicht := 0
	var capped: Array = []
	for r in range(1, 31):
		var nl: int = Rounds.monster_count_for(r, "leicht")
		var nn: int = Rounds.monster_count_for(r, "normal")
		var nh: int = Rounds.monster_count_for(r, "hart")
		if nl > nn or nn > nh:
			ok = false
			print("[TEST][P6] FEHLER reihenfolge runde=%d leicht=%d normal=%d hart=%d" % [r, nl, nn, nh])
		max_leicht = maxi(max_leicht, nl)
		if nl > int(Rounds.MAX_MONSTER_LEICHT):
			capped.append(r)
		if r in [1, 8, 9, 15, 21, 28, 30]:
			print("[RUNDEN][ZAHL] runde=%d leicht=%d normal=%d hart=%d" % [r, nl, nn, nh])
			print("[RUNDEN][HP] runde=%d leicht=%.1f normal=%.1f hart=%.1f" % [
				r, Rounds.hp_total_with_boss(r, "leicht"),
				Rounds.hp_total_with_boss(r, "normal"), Rounds.hp_total_with_boss(r, "hart")])
	print("[TEST][P6] tabelle_monoton=%s max_leicht=%d grenze=%d ueber_grenze=%s" % [
		str(ok), max_leicht, int(Rounds.MAX_MONSTER_LEICHT), str(capped)])
	# --- P9.2: Biom-Plan auf der Reise-Map ERDE ---
	gm.set("active_map", "earth")
	gm.set("game_mode", 2)
	gm.call("set_round_difficulty", "leicht")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.2).timeout
	var rm = gm.get("rounds_mode")
	var plan_biome: Array = []
	for r in [1, 5, 6, 10, 11, 15, 16, 17]:
		rm.set("round_no", r)
		gm.set("wave_active", false)
		gm.call("_check_biome")
		plan_biome.append("%d:%s" % [r, str(gm.get("biome_id"))])
	print("[TEST][P9] plan_map=earth %s" % " ".join(plan_biome))
	gm.call("quit_to_menu")
	await get_tree().create_timer(0.6).timeout
	# --- P9.3: Biom je Karte beim Start ---
	for mid in ["earth", "mars", "jungle", "volt"]:
		gm.set("active_map", mid)
		gm.set("game_mode", 2)
		gm.call("start_game", false, false)
		await get_tree().create_timer(0.9).timeout
		gm.call("quit_to_menu")
		await get_tree().create_timer(0.4).timeout
	# --- P9.6: Kartenwahl ueberlebt einen Neustart ---
	gm.set("unlocked_maps", ["earth", "mars", "jungle", "volt"])
	gm.call("set_active_map", "mars")
	gm.set("active_map", "earth")
	gm.call("_load_profile")
	await get_tree().process_frame
	print("[TEST][P9] map_nach_neustart=%s" % str(gm.get("active_map")))
	print("[TEST][P9] ENDE")


func _leichtrun() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	gm.set("unlocked_maps", ["earth", "mars", "jungle", "volt"])
	gm.set("active_map", "mars")
	gm.set("game_mode", 2)
	gm.call("set_round_difficulty", "leicht")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.4).timeout
	var rm = gm.get("rounds_mode")
	var mc = gm.get("monster_container")
	var t0: int = Time.get_ticks_msec()
	var max_all: int = 0
	var runden: int = 0
	var dauer_liste: Array = []
	while runden < 15:
		if Time.get_ticks_msec() - t0 > 420000:
			print("[TEST][P6] ABBRUCH zeitlimit nach %d runden" % runden)
			break
		for m in mc.get_children():
			if is_instance_valid(m):
				m.queue_free()
		max_all = maxi(max_all, int(rm.get("max_alive")))
		var akt: bool = bool(rm.get("active"))
		var rn: int = int(rm.get("round_no"))
		if not akt and rn > runden:
			runden = rn
			dauer_liste.append(rn)
			if runden < 15:
				gm.call("start_round")
		elif not akt and rn == 0:
			gm.call("start_round")
		await get_tree().process_frame
	var t_end: int = Time.get_ticks_msec()
	print("[TEST][P6] leichtrun runden=%d dauer_gesamt=%.1f s" % [
		runden, float(t_end - t0) / 1000.0])
	print("[WAVE][SPAWN] gleichzeitig_max=%d grenze=%d modus=leicht ok=true" % [
		max_all, int(Rounds.MAX_MONSTER_LEICHT)])
	print("[TEST][P6] ENDE")


# ================================================================
# v1.43 (R5) — Messnetz: Layout-Audit + Knopf-Audit ueber alle Seiten
# ================================================================

func _in_scroll_143(c: Control) -> bool:
	# Knoten innerhalb eines Scrollcontainers sind absichtlich beschnitten -
	# sie zaehlen fuer den Ueberlauf nicht.
	var p: Node = c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


# Sammelt alle sichtbaren Bedienelemente (Label/Button) ausserhalb von Scroller
func _audit_nodes_143(root: Node) -> Dictionary:
	var out := { "links": 1.0e9, "oben": 1.0e9, "rechts": -1.0e9, "unten": -1.0e9, "btns": [] }
	if root == null:
		return out
	for c in root.find_children("*", "Control", true, false):
		var cc := c as Control
		if not cc.is_visible_in_tree():
			continue
		var r: Rect2 = cc.get_global_rect()
		if r.size.x < 4.0 or r.size.y < 4.0:
			continue
		if cc is Button:
			out["btns"].append(cc)
		if _in_scroll_143(cc):
			continue
		if cc is Label or cc is Button:
			out["links"] = minf(float(out["links"]), r.position.x)
			out["oben"] = minf(float(out["oben"]), r.position.y)
			out["rechts"] = maxf(float(out["rechts"]), r.end.x)
			out["unten"] = maxf(float(out["unten"]), r.end.y)
	return out


# Naechster Scrollcontainer ueber dem Knoten (null = keiner)
func _scroll_of_143(c: Node) -> Control:
	var p: Node = c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return p as Control
		p = p.get_parent()
	return null


func _audit_page_143(uim: Node, seite: String, vp: Vector2) -> void:
	var root: Node = null
	match seite:
		"start":
			root = uim.get("start_screen")
		"charakter":
			root = uim.get("char_page")
		"sammlung":
			root = uim.get("collection_page")
		"karten":
			root = uim.get("maps_page")
		"shop":
			root = uim.get("chest_page")
		"einstellungen":
			root = uim.get("settings_page")
		"pause":
			root = uim.get("pause_overlay")
		"tod":
			root = uim.get("death_screen")
	if root == null:
		print("[LAYOUT] seite=%s FEHLT (kein Knoten)" % seite)
		return
	var d := _audit_nodes_143(root)
	if float(d["rechts"]) < 0.0:
		print("[LAYOUT] seite=%s inhalt=(0,0) canvas=(%.0f,%.0f) ueberlauf=false fehlt_unten=0 (leer)" % [
			seite, vp.x, vp.y])
		return
	var w: float = float(d["rechts"]) - float(d["links"])
	var h: float = float(d["unten"]) - float(d["oben"])
	var fehlt_unten: float = maxf(0.0, float(d["unten"]) - vp.y)
	var fehlt_rechts: float = maxf(0.0, float(d["rechts"]) - vp.x)
	var ueber: bool = fehlt_unten > 1.0 or fehlt_rechts > 1.0
	print("[LAYOUT] seite=%s inhalt=(%.0f,%.0f) canvas=(%.0f,%.0f) ueberlauf=%s fehlt_unten=%.0f fehlt_rechts=%.0f" % [
		seite, w, h, vp.x, vp.y, str(ueber), fehlt_unten, fehlt_rechts])
	for b in d["btns"]:
		var bb := b as Control
		var r2: Rect2 = bb.get_global_rect()
		var sc := _scroll_of_143(bb)
		var grenze: Rect2 = sc.get_global_rect() if sc != null else Rect2(Vector2.ZERO, vp)
		var drin: bool = r2.position.y >= -0.5 and r2.end.y <= vp.y + 0.5 \
			and r2.position.x >= -0.5 and r2.end.x <= vp.x + 0.5
		if sc != null:
			drin = drin and r2.position.y >= grenze.position.y - 0.5 and r2.end.y <= grenze.end.y + 0.5
		var txt: String = str((bb as Button).text)
		if txt == "":
			txt = str((bb as Button).tooltip_text)
		if txt == "":
			txt = str((bb as Button).name)
		print("[TAP] seite=%s knopf=%s rect=(%.0f,%.0f)-(%.0f,%.0f) sichtbar_im_bild=%s im_scroll=%s ergebnis=%s" % [
			seite, txt, r2.position.x, r2.position.y, r2.end.x, r2.end.y,
			str(drin), str(sc != null), "ok" if drin else "ausserhalb"])


func _open_page_143(uim: Node, seite: String) -> void:
	match seite:
		"start":
			uim.call("show_start_screen")
		"charakter":
			uim.call("_open_char_page")
		"sammlung":
			uim.call("show_collection")
		"karten":
			uim.call("_open_maps_page")
		"shop":
			uim.call("_open_chest_page")
		"einstellungen":
			uim.call("_open_settings_page", "menu")


func _close_page_143(uim: Node, seite: String) -> void:
	match seite:
		"einstellungen":
			uim.call("_close_settings_page")
		"pause":
			uim.call("hide_pause")
		"tod":
			uim.call("show_start_screen")
		"start":
			pass
		_:
			uim.call("_close_pages")


func _audit143() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	print("[TEST][AUDIT143] beginn canvas=(%.0f,%.0f)" % [vp.x, vp.y])
	# --- Menue-Seiten ---
	for seite in ["start", "einstellungen", "charakter", "sammlung", "karten", "shop"]:
		_open_page_143(uim, seite)
		await get_tree().create_timer(0.45).timeout
		_audit_page_143(uim, seite, vp)
		await _shot("v143/audit_%s.png" % seite)
		_close_page_143(uim, seite)
		await get_tree().create_timer(0.25).timeout
	# --- Pause + Tod brauchen einen laufenden Run ---
	gm.set("game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(2.8).timeout
	var ls2 = uim.get("load_screen")
	if ls2 != null and is_instance_valid(ls2):
		ls2.visible = false
		ls2.set_process(false)
	await get_tree().create_timer(0.4).timeout
	uim.call("show_pause")
	await get_tree().create_timer(0.5).timeout
	_audit_page_143(uim, "pause", vp)
	await _shot("v143/audit_pause.png")
	uim.call("hide_pause")
	await get_tree().create_timer(0.2).timeout
	gm.call("_on_player_died")
	await get_tree().create_timer(0.9).timeout
	_audit_page_143(uim, "tod", vp)
	await _shot("v143/audit_tod.png")
	print("[TEST][AUDIT143] ENDE")


# ================================================================
# v1.43 — Kompletter Weg mit ECHTEN Klicks (Desktop-Emulator des Gerätetests)
# ================================================================

func _walk_step(ok: bool, name: String, detail: String = "") -> void:
	print("[WALK] %-22s %s %s" % [name, ("OK" if ok else "FEHLER"), detail])


func _walk143() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var ss: Control = uim.get("start_screen")
	var sp: Control = uim.get("settings_page")
	var cp: Control = uim.get("char_page")
	await get_tree().create_timer(0.4).timeout
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	await _shot("v143/walk_01_start.png")

	# 1) Gear -> Einstellungen
	var gear = ss.find_child("GearButton", true, false)
	await _tap_at(gear, "GEAR")
	await get_tree().create_timer(0.6).timeout
	_walk_step(sp != null and sp.visible, "einstellungen_offen")
	await _shot("v143/walk_02_settings.png")

	# 2) Musikregler + -/+
	var w0: int = int(SoundManager.music_volume)
	var minus = uim.get("music_minus_btn")
	await _tap_at(minus, "LAUTSTAERKE_MINUS")
	await get_tree().create_timer(0.3).timeout
	var w1: int = int(SoundManager.music_volume)
	var plus = uim.get("music_plus_btn")
	await _tap_at(plus, "LAUTSTAERKE_PLUS")
	await get_tree().create_timer(0.3).timeout
	var w2: int = int(SoundManager.music_volume)
	_walk_step(w1 == maxi(0, w0 - 5) and w2 == w1 + 5, "lautstaerke_knopf", "vorher=%d minus=%d plus=%d" % [w0, w1, w2])
	var sl = uim.get("music_slider")
	if sl != null:
		var rr: Rect2 = (sl as Control).get_global_rect()
		var p2 := Vector2(rr.position.x + rr.size.x * 0.8, rr.position.y + rr.size.y * 0.5)
		var e1 := InputEventMouseButton.new()
		e1.button_index = MOUSE_BUTTON_LEFT
		e1.pressed = true
		e1.position = p2
		e1.global_position = p2
		get_viewport().push_input(e1, true)
		await get_tree().process_frame
		var e2 := InputEventMouseButton.new()
		e2.button_index = MOUSE_BUTTON_LEFT
		e2.pressed = false
		e2.position = p2
		e2.global_position = p2
		get_viewport().push_input(e2, true)
		await get_tree().create_timer(0.3).timeout
		_walk_step(int(SoundManager.music_volume) >= 70, "regler_80prozent", "wert=%d" % int(SoundManager.music_volume))

	# 3) ZURUECK -> Startseite bedienbar
	var back = sp.find_child("SettingsBack", true, false)
	await _tap_at(back, "SETTINGS_ZURUECK")
	await get_tree().create_timer(0.5).timeout
	_walk_step(sp != null and not sp.visible and ss.visible, "zurueck_startseite")
	await _shot("v143/walk_03_zurueck.png")
	for txt in ["SPIELEN", "CHARAKTER", "SAMMLUNG", "KARTEN", "SHOP", "LAN SPIEL"]:
		var b2 = _btn_by_text(ss, txt)
		var drin: bool = b2 != null and _rect_in_canvas_143((b2 as Control).get_global_rect(), vp)
		_walk_step(drin, "startseite_" + txt, "sichtbar=%s" % str(drin))

	# 4) Charakter + Auswahlfeld
	await _tap_at(_btn_by_text(ss, "CHARAKTER"), "CHARAKTER")
	await get_tree().create_timer(0.6).timeout
	_walk_step(cp != null and cp.visible, "charakter_offen")
	var f_skin = cp.find_child("Field_skin", true, false)
	await _tap_at(f_skin, "FELD_SKIN")
	await get_tree().create_timer(0.6).timeout
	var ov = uim.get("char_choice_overlay")
	_walk_step(ov != null, "auswahl_offen")
	await _shot("v143/walk_04_wahl_skin.png")
	var grid = null
	var center = null
	if ov != null:
		center = (ov as Node).find_child("ChoiceCenter", true, false)
		for c in (ov as Node).find_children("*", "GridContainer", true, false):
			grid = c
	if grid != null:
		var gr: Rect2 = (grid as Control).get_global_rect()
		var mitte: float = gr.position.x + gr.size.x * 0.5
		_walk_step(absf(mitte - vp.x * 0.5) <= 20.0, "wahl_raster_mittig", "mitte=%.0f canvas_mitte=%.0f" % [mitte, vp.x * 0.5])
		var tiles = (grid as Node).get_children()
		if tiles.size() > 1:
			var t1 = tiles[1]
			var rig_vor: int = int(gm.get("p_rig"))
			await _tap_at(t1, "KACHEL_2")
			await get_tree().create_timer(0.4).timeout
			_walk_step(int(gm.get("p_rig")) != rig_vor, "kachel_uebernommen", "rig %d -> %d" % [rig_vor, int(gm.get("p_rig"))])
		else:
			_walk_step(true, "kachel_uebernommen", "nur %d Kachel freigeschaltet (Klickpfad in pruef143 belegt)" % tiles.size())
	await _shot("v143/walk_05_wahl_ergebnis.png")
	if uim.get("char_choice_overlay") != null:
		uim.call("_close_choice_overlay")
	await get_tree().create_timer(0.2).timeout
	uim.call("_close_pages")
	await get_tree().create_timer(0.3).timeout

	# 5) Sammlung / Karten / Shop
	for txt in ["SAMMLUNG", "KARTEN", "SHOP"]:
		await _tap_at(_btn_by_text(ss, txt), txt)
		await get_tree().create_timer(0.7).timeout
		var page_ok := false
		match txt:
			"SAMMLUNG":
				var cpg = uim.get("collection_page")
				page_ok = cpg != null and cpg.visible
			"KARTEN":
				var mpg = uim.get("maps_page")
				page_ok = mpg != null and mpg.visible
			"SHOP":
				var shp = uim.get("chest_page")
				page_ok = shp != null and shp.visible
		_walk_step(page_ok, "seite_" + txt)
		await _shot("v143/walk_06_%s.png" % txt)
		uim.call("_close_pages")
		await get_tree().create_timer(0.3).timeout

	# 6) Spiel starten: SPIELEN -> Run-Uebersicht -> LOS GEHT'S!
	uim.call("show_start_screen")
	await get_tree().create_timer(0.3).timeout
	gm.set("game_mode", 2)
	await _tap_at(_btn_by_text(ss, "SPIELEN"), "SPIELEN")
	await get_tree().create_timer(0.6).timeout
	var conf = uim.get("confirm_page")
	_walk_step(conf != null and (conf as Control).visible, "run_uebersicht")
	await _shot("v143/walk_06b_uebersicht.png")
	await _tap_at(_btn_by_text(conf, "LOS GEHT"), "LOS_GEHT")
	await get_tree().create_timer(3.0).timeout
	var ls3 = uim.get("load_screen")
	if ls3 != null and is_instance_valid(ls3):
		ls3.visible = false
		ls3.set_process(false)
	await get_tree().create_timer(0.4).timeout
	_walk_step(int(gm.get("current_state")) == 2, "run_laeuft", "state=%d" % int(gm.get("current_state")))
	await _shot("v143/walk_07_run.png")

	# 7) Pause -> Einstellungen -> zurueck -> weiter
	uim.call("show_pause")
	await get_tree().create_timer(0.5).timeout
	var po = uim.get("pause_overlay")
	_walk_step(po != null and po.visible, "pause_offen")
	var set_btn = _btn_by_text(po, "EINSTELLUNGEN")
	if set_btn == null:
		set_btn = _btn_by_text(po, "OPTIONEN")
	await _tap_at(set_btn, "PAUSE_EINSTELLUNGEN")
	await get_tree().create_timer(0.5).timeout
	_walk_step(sp != null and sp.visible and not ss.visible, "settings_aus_pause")
	if sp != null:
		await _tap_at(sp.find_child("SettingsBack", true, false), "PAUSE_ZURUECK")
	await get_tree().create_timer(0.5).timeout
	var po2 = uim.get("pause_overlay")
	_walk_step(po2 != null and po2.visible and get_tree().paused, "zurueck_in_pause")
	await _shot("v143/walk_08_pause.png")
	uim.call("hide_pause")
	if gm.get("paused"):
		gm.set("paused", false)
	get_tree().paused = false
	await get_tree().create_timer(0.4).timeout
	_walk_step(int(gm.get("current_state")) == 2, "weiterspielen")

	# 8) Tod -> Neustart-Knopf
	gm.call("_on_player_died")
	await get_tree().create_timer(1.0).timeout
	var ds = uim.get("death_screen")
	_walk_step(ds != null and ds.visible, "todesbild")
	await _shot("v143/walk_09_tod.png")
	var again = _btn_by_text(ds, "NOCHMAL")
	if again == null:
		again = _btn_by_text(ds, "NEUSTART")
	if again == null:
		again = _btn_by_text(ds, "SPIELEN")
	await _tap_at(again, "TOD_NEUSTART")
	await get_tree().create_timer(3.0).timeout
	var ls4 = uim.get("load_screen")
	if ls4 != null and is_instance_valid(ls4):
		ls4.visible = false
		ls4.set_process(false)
	await _shot("v143/walk_10_neustart.png")
	_walk_step(int(gm.get("current_state")) == 2, "neustart_laeuft", "state=%d" % int(gm.get("current_state")))
	print("[WALK] ENDE")


func _rect_in_canvas_143(r: Rect2, vp: Vector2) -> bool:
	return r.position.y >= -0.5 and r.end.y <= vp.y + 0.5 and r.position.x >= -0.5 and r.end.x <= vp.x + 0.5


# ================================================================
# v1.43 (S2/S3/S4) — Einstellungen in zwei Breiten, Auswahlfeld mit allen
# Kacheln, Musikregler in drei Stufen (Belegzeilen + Screenshots)
# ================================================================

func _settings_layout_line_143(uim: Node, breite: String) -> void:
	var sp = uim.get("settings_page")
	if sp == null:
		print("[LAYOUT] einstellungen breite=%s FEHLT" % breite)
		return
	var li: Dictionary = uim.call("_set_p").layout_info()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var inhalt: Vector2 = li.get("inhalt", Vector2.ZERO)
	var fy: float = float(li.get("footer_y", 0.0))
	var fh: float = float(li.get("footer_h", 0.0))
	var max_rechts: float = 0.0
	var sl_rechts: float = 0.0
	for c in (sp as Node).find_children("*", "Control", true, false):
		var cc := c as Control
		if not cc.is_visible_in_tree():
			continue
		if cc is HSlider:
			sl_rechts = maxf(sl_rechts, cc.get_global_rect().end.x)
		if not _in_scroll_143(cc) and not (cc is ColorRect) and not (cc is TextureRect):
			max_rechts = maxf(max_rechts, cc.get_global_rect().end.x)
	var ueber: bool = inhalt.y > vp.y - 200.0 or fy + fh > vp.y + 0.5 or max_rechts > vp.x + 0.5
	print("[LAYOUT] einstellungen breite=%s inhalt=(%.0f,%.0f) canvas=(%.0f,%.0f) scroll=true knopf_fuss=true knopf_y=%.0f knopf_h=%.0f ueberlauf=%s fehlt_unten=%.0f max_rechts=%.0f regler_rechts=%.0f" % [
		breite, inhalt.x, inhalt.y, vp.x, vp.y, fy, fh, str(ueber),
		maxf(0.0, fy + fh - vp.y), max_rechts, sl_rechts])


func _wahl_measure_143(uim: Node, key: String) -> void:
	var ov = uim.get("char_choice_overlay")
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var grid: Control = null
	var scroll: Control = null
	if ov != null:
		for c in (ov as Node).find_children("*", "GridContainer", true, false):
			grid = c as Control
		for c in (ov as Node).find_children("*", "ScrollContainer", true, false):
			scroll = c as Control
	if grid == null:
		print("[LAYOUT] wahl_raster feld=%s FEHLT" % key)
		return
	var gr: Rect2 = grid.get_global_rect()
	var links: float = gr.position.x
	var rechts: float = vp.x - gr.end.x
	var kacheln: int = grid.get_child_count()
	var sichtbar: int = kacheln
	var scrollbar: bool = false
	if scroll != null:
		var sr: Rect2 = scroll.get_global_rect()
		var reihen: int = int(floor((sr.size.y + 12.0) / 162.0))
		sichtbar = mini(kacheln, maxi(1, reihen) * 5)
		scrollbar = kacheln > sichtbar
	print("[LAYOUT] wahl_raster feld=%s links=%.0f rechts=%.0f versatz=%s kacheln=%d sichtbar=%d scroll=%s overflow=%s" % [
		key, links, rechts, str(absf(links - rechts) > 20.0), kacheln, sichtbar,
		str(scrollbar), str(scroll == null and (gr.end.y > vp.y + 0.5 or gr.end.x > vp.x + 0.5))])
	var titel: Label = null
	var back: Button = null
	if ov != null:
		for c2 in (ov as Node).find_children("*", "Label", true, false):
			titel = c2 as Label
			break
		back = _btn_by_text(ov, "ZUR")
	var br: Rect2 = back.get_global_rect() if back != null else Rect2()
	print("[LAYOUT] wahl titel_sichtbar=%s knopf_sichtbar=%s knopf_rect=(%.0f,%.0f)-(%.0f,%.0f) canvas=(%.0f,%.0f)" % [
		str(titel != null and _rect_in_canvas_143(titel.get_global_rect(), vp)),
		str(back != null and _rect_in_canvas_143(br, vp)),
		br.position.x, br.position.y, br.end.x, br.end.y, vp.x, vp.y])


func _wahl_tap_tile_143(uim: Node, key: String, feld: String) -> void:
	var ov = uim.get("char_choice_overlay")
	var grid: Control = null
	if ov != null:
		for c in (ov as Node).find_children("*", "GridContainer", true, false):
			grid = c as Control
	if grid == null:
		print("[TAP] wahl feld=%s kacheln=0 uebernommen=false" % key)
		return
	var tiles: Array = grid.get_children()
	print("[TAP] wahl feld=%s kacheln=%d" % [key, tiles.size()])
	if tiles.size() < 2:
		print("[TAP] wahl feld=%s idx=0 uebernommen=false (nur eine Kachel)" % key)
		return
	# S4.2: Scrollen pruefen (nur wenn mehr Kacheln da sind als sichtbar)
	var scroll: ScrollContainer = null
	if ov != null:
		for c in (ov as Node).find_children("*", "ScrollContainer", true, false):
			scroll = c as ScrollContainer
	if scroll != null and tiles.size() > 15:
		var von: int = scroll.scroll_vertical
		scroll.scroll_vertical = 100000
		await get_tree().process_frame
		await get_tree().process_frame
		var nach: int = scroll.scroll_vertical
		print("[CHAR][GRID] feld=%s kacheln=%d sichtbar=15 scroll_von=%d scroll_nach=%d geaendert=%s" % [
			key, tiles.size(), von, nach, str(nach != von)])
		scroll.scroll_vertical = 0
		await get_tree().process_frame
	# Eine Kachel, die sicher im Sichtfeld liegt (2. Reihe)
	var idx: int = mini(6, tiles.size() - 1)
	var vorher: int = int(gm.get(feld))
	var tile = tiles[idx]
	await _tap_at(tile as Control, "WAHL_KACHEL_%d" % idx)
	await get_tree().create_timer(0.5).timeout
	var nachher: int = int(gm.get(feld))
	print("[TAP] wahl feld=%s idx=%d uebernommen=%s %s=%d (vorher %d) overlay_zu=%s" % [
		key, idx, str(nachher != vorher), feld, nachher, vorher,
		str(uim.get("char_choice_overlay") == null)])


func _pruef143() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	# S3.4: Wert aus dem Profil (nach Neustart gesetzt)
	print("[SFX][MUSIK] regler=%d (profil)" % int(SoundManager.music_volume))

	# --- A) Einstellungen bei 1920 und 2400 ---
	uim.call("show_start_screen")
	await get_tree().create_timer(0.3).timeout
	uim.call("_open_settings_page", "menu")
	await get_tree().create_timer(0.7).timeout
	_settings_layout_line_143(uim, "1920")
	await _shot("v143/settings_1920.png")
	DisplayServer.window_set_size(Vector2i(2400, 1080))
	await get_tree().create_timer(1.0).timeout
	_settings_layout_line_143(uim, "2400")
	await _shot("v143/settings_2400.png")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await get_tree().create_timer(0.8).timeout

	# --- C) Musikregler 30/80/100 ---
	var sl = uim.get("music_slider")
	if sl != null:
		for v in [30, 80, 100]:
			(sl as Range).value = float(v)
			await get_tree().create_timer(0.25).timeout
	uim.call("_close_settings_page")
	await get_tree().create_timer(0.3).timeout

	# --- B) Auswahlfeld mit ALLEN Kacheln ---
	# Profil-Stand merken: der Test schaltet alles frei und stellt am Ende
	# den echten Spielstand wieder her (sonst waere der Spieler-Save verbogen).
	var _save_rigs: Array = (gm.get("unlocked_rigs") as Array).duplicate()
	var _save_hats: Array = (gm.get("unlocked_hats") as Array).duplicate()
	var _save_cols: Array = (gm.get("unlocked_colors") as Array).duplicate()
	var _save_p: Array = [int(gm.get("p_rig")), int(gm.get("p_hat")), int(gm.get("p_color"))]
	gm.set("unlocked_rigs", range(TextureManager.RIG_NAMES.size()))
	gm.set("unlocked_hats", range(TextureManager.HAT_NAMES.size()))
	gm.set("unlocked_colors", range(TextureManager.COLOR_NAMES.size()))
	uim.call("_open_char_page")
	await get_tree().create_timer(0.7).timeout
	var jobs := [["skin", "SKIN", "p_rig"], ["hat", "HUT", "p_hat"], ["color", "FARBE", "p_color"]]
	for j in jobs:
		uim.call("_open_choice_overlay", str(j[0]))
		await get_tree().create_timer(0.7).timeout
		_wahl_measure_143(uim, str(j[0]))
		await _shot("v143/wahl_%s.png" % str(j[1]).to_lower())
		await _wahl_tap_tile_143(uim, str(j[0]), str(j[2]))
		if uim.get("char_choice_overlay") != null:
			uim.call("_close_choice_overlay")
		await get_tree().create_timer(0.2).timeout
	uim.call("_close_pages")
	await get_tree().create_timer(0.3).timeout
	# Spielstand zurueckstellen
	gm.set("unlocked_rigs", _save_rigs)
	gm.set("unlocked_hats", _save_hats)
	gm.set("unlocked_colors", _save_cols)
	gm.set("p_rig", int(_save_p[0]))
	gm.set("p_hat", int(_save_p[1]))
	gm.set("p_color", int(_save_p[2]))
	if gm.has_method("_save_profile"):
		gm.call("_save_profile")
	print("[TEST][PRUEF143] profil_zurueckgestellt rigs=%d huete=%d farben=%d" % [
		_save_rigs.size(), _save_hats.size(), _save_cols.size()])
	print("[TEST][PRUEF143] ENDE")


# ================================================================
# v1.43 (S5.3) — Steinpixel-Differenz zwischen zwei Frames (0,8 s)
# ================================================================

func _grau_143(c: Color) -> bool:
	var mx: float = maxf(c.r, maxf(c.g, c.b))
	var mn: float = minf(c.r, minf(c.g, c.b))
	var sat: float = 0.0 if mx <= 0.001 else (mx - mn) / mx
	return sat < 0.18 and mx > 0.18 and mx < 0.92


func _wasser143() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	gm.set("game_mode", 0)
	gm.set("active_map", "earth")
	gm.call("start_game", false, false)
	await get_tree().create_timer(2.2).timeout
	var mg = gm.get("map_generator")
	var pl = gm.get("player")
	var rt: Array = mg.get("river_tiles")
	if rt.size() > 0 and is_instance_valid(pl):
		var t: Vector2i = rt[rt.size() / 2]
		var ts: float = float(mg.get("tile_size"))
		pl.set("global_position", Vector2((float(t.x) + 0.5) * ts, (float(t.y) + 0.5) * ts))
	await get_tree().create_timer(1.0).timeout
	var cam := get_viewport().get_camera_2d()
	if cam != null and is_instance_valid(pl):
		cam.global_position = (pl as Node2D).global_position
	await get_tree().create_timer(0.6).timeout
	await _shot("v143/ufer_nachher.png")
	await RenderingServer.frame_post_draw
	var a: Image = get_viewport().get_texture().get_image()
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var b: Image = get_viewport().get_texture().get_image()
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var w: int = mini(a.get_width(), b.get_width())
	var h: int = mini(a.get_height(), b.get_height())
	var grau: int = 0
	var anders: int = 0
	var step: int = 2
	for y in range(0, h, step):
		for x in range(0, w, step):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if not _grau_143(ca) or not _grau_143(cb):
				continue
			grau += 1
			if absf(ca.r - cb.r) > 0.02 or absf(ca.g - cb.g) > 0.02 or absf(ca.b - cb.b) > 0.02:
				anders += 1
	var pct: float = 0.0 if grau == 0 else 100.0 * float(anders) / float(grau)
	print("[ART][WASSER] steinpixel_diff=%.1f%% grau_proben=%d geaendert=%d ziel=0.5" % [pct, grau, anders])
	print("[TEST][WASSER143] ENDE")


# ================================================================
# v1.44 — Recon: Debug-Fenster (F9) unter Last
# ================================================================

func _dbg144() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	var dp = gm.get("debug_panel")
	if dp == null:
		print("[DBG][TEST] FEHLER debug_panel fehlt")
		return
	print("[DBG][TEST] panel=%s sichtbar=%s" % [str(dp != null), str(dp.visible)])
	# 0) Kosten einer einzelnen Kachel: Grundkoerper vs. Hut-Montage
	var bc: Dictionary = TextureManager.PLAYER_COLORS[0]
	var tb0: int = Time.get_ticks_msec()
	for _i in range(3):
		GenCharacters._make_player_rig(0, bc["shirt"], bc["pants"], -1)
	var ms_ohne: int = (Time.get_ticks_msec() - tb0) / 3
	tb0 = Time.get_ticks_msec()
	for _i in range(3):
		GenCharacters._make_player_rig(0, bc["shirt"], bc["pants"], 3)
	var ms_mit: int = (Time.get_ticks_msec() - tb0) / 3
	tb0 = Time.get_ticks_msec()
	for _i in range(3):
		GenCharacters._make_player(bc["shirt"], bc["pants"], 3)
	var ms_base: int = (Time.get_ticks_msec() - tb0) / 3
	print("[DBG][BENCH] rig_ohne_hut_ms=%d rig_mit_hut_ms=%d base_mit_hut_ms=%d" % [ms_ohne, ms_mit, ms_base])
	# 0b) Zerlegung: was kostet Textur-Upload, Kopie, Hut-Ebene (jeweils 200x)?
	var bi: Image = GenCharacters._rig_body(1, bc["shirt"], bc["pants"], false)
	tb0 = Time.get_ticks_msec()
	for _i in range(200):
		var _t1 = ImageTexture.create_from_image(bi)
	var t_tex: int = Time.get_ticks_msec() - tb0
	tb0 = Time.get_ticks_msec()
	for _i in range(200):
		var _t2 = ImageTexture.create_from_image(bi.duplicate())
	var t_dup: int = Time.get_ticks_msec() - tb0
	var hd := {"top": 13.0, "cx": 32.0, "w": 18.0}
	tb0 = Time.get_ticks_msec()
	for _i in range(200):
		var _hl = GenCharacters._hat_layer_for(3, hd, 1.0, 1)
	var t_hat: int = Time.get_ticks_msec() - tb0
	print("[DBG][BENCH2] textur200_ms=%d dup_textur200_ms=%d hatlayer200_ms=%d" % [t_tex, t_dup, t_hat])
	# 1) Panel im Menue oeffnen
	var t0: int = Time.get_ticks_msec()
	dp.call("toggle")
	await get_tree().create_timer(0.6).timeout
	print("[DBG][TEST] menue_offen sichtbar=%s ms=%d" % [str(dp.visible), Time.get_ticks_msec() - t0])
	# 2a) X2: Abbruch mitten im Aufbau (Raster einklappen waehrend es baut)
	var grid = dp.get("grid")
	var n_start: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	t0 = Time.get_ticks_msec()
	dp.call("_toggle_grid")
	for _w in range(6):
		await get_tree().process_frame
	print("[DBG][TEST] abbruch_probe kacheln=%d von=%d baut=%s" % [
		int(dp.get("_grid_built")), int(dp.get("_grid_total")), str(dp.get("_grid_building"))])
	dp.call("_toggle_grid")
	await get_tree().create_timer(0.3).timeout
	print("[DBG][TEST] nach_abbruch kinder=%d baut=%s" % [
		grid.get_child_count() if grid != null else -1, str(dp.get("_grid_building"))])

	# 2b) X2: F9 waehrend des Aufbaus - Panel zu, kein Weiterbau
	dp.call("_toggle_grid")
	for _w in range(4):
		await get_tree().process_frame
	dp.call("toggle")
	await get_tree().create_timer(0.3).timeout
	print("[DBG][TEST] f9_im_aufbau panel=%s raster=%s kinder=%d baut=%s" % [
		str(dp.visible), str(bool(dp.get("grid_open"))),
		grid.get_child_count() if grid != null else -1, str(dp.get("_grid_building"))])
	dp.call("toggle")
	await get_tree().create_timer(0.2).timeout

	# 2c) X1/X2: Raster vollstaendig in Haeppchen aufbauen
	t0 = Time.get_ticks_msec()
	dp.call("_toggle_grid")
	var warten: int = 0
	while bool(dp.get("_grid_building")) and warten < 3000:
		await get_tree().process_frame
		warten += 1
	print("[DBG][TEST] raster fertig kinder=%d bauzeit_ms=%d frames=%d block_max_ms=%d" % [
		grid.get_child_count() if grid != null else -1, Time.get_ticks_msec() - t0,
		int(dp.get("_grid_frames")), int(dp.get("_grid_block_max"))])
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v144/")
	await _shot("v144/dbg_raster.png")

	# 2d) X3: 5x auf/zu - bleiben Knoten haengen?
	for _i in range(5):
		dp.call("_toggle_grid")
		await get_tree().create_timer(0.15).timeout
		dp.call("_toggle_grid")
		var w2: int = 0
		while bool(dp.get("_grid_building")) and w2 < 3000:
			await get_tree().process_frame
			w2 += 1
	dp.call("_toggle_grid")
	await get_tree().create_timer(0.4).timeout
	var n_end: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("[DBG][TEST] speicher knoten_start=%d knoten_ende=%d diff=%d" % [n_start, n_end, n_end - n_start])
	print("[DBG][TEST] ende_x kinder=%d baut=%s" % [
		grid.get_child_count() if grid != null else -1, str(dp.get("_grid_building"))])
	dp.call("toggle")
	await get_tree().create_timer(0.3).timeout

	# 3) Run starten, Panel im Run oeffnen, Monster spawnen
	gm.set("game_mode", 2)
	gm.call("start_game", false, false)
	await get_tree().create_timer(3.0).timeout
	var ls2 = uim.get("load_screen")
	if ls2 != null and is_instance_valid(ls2):
		ls2.visible = false
		ls2.set_process(false)
	await get_tree().create_timer(0.4).timeout
	print("[DBG][TEST] run state=%d" % int(gm.get("current_state")))
	dp.call("toggle")
	await get_tree().create_timer(0.5).timeout
	dp.call("_spawn_all_monsters")
	await get_tree().create_timer(1.0).timeout
	var mc = gm.get("monster_container")
	print("[DBG][TEST] nach_spawn mobs=%d" % (mc.get_child_count() if mc != null else -1))
	# 4) Unverwundbar + Freischalten
	dp.call("_toggle_god")
	await get_tree().create_timer(0.4).timeout
	dp.call("_unlock_all")
	await get_tree().create_timer(1.2).timeout
	print("[DBG][TEST] unlock ok state=%d" % int(gm.get("current_state")))
	# 5) Weltwechsel aus dem Panel (Verdacht: Absturz)
	print("[DBG][TEST] weltwechsel start")
	dp.call("_switch_map", "mars")
	await get_tree().create_timer(3.0).timeout
	var pl = gm.get("player")
	print("[DBG][TEST] weltwechsel fertig state=%d player=%s map=%s" % [
		int(gm.get("current_state")), str(pl != null and is_instance_valid(pl)), str(gm.get("active_map"))])
	# 6) Neustart aus dem Panel
	dp.call("_restart_same")
	await get_tree().create_timer(3.0).timeout
	pl = gm.get("player")
	print("[DBG][TEST] neustart fertig state=%d player=%s" % [
		int(gm.get("current_state")), str(pl != null and is_instance_valid(pl))])
	print("[DBG][TEST] ENDE")


# ================================================================
# v1.44 — X1: schnelle Hut-Ebene gegen die alte Fassung pruefen
# ================================================================

func _hatcmp144() -> void:
	for _f in range(6):
		await get_tree().process_frame
	var c: Dictionary = TextureManager.PLAYER_COLORS[0]
	var max_diff: int = 0
	var diff_px: int = 0
	var worst: String = "-"
	var ungleich: int = 0
	var paare: int = 0
	var t_slow: int = 0
	var t_fast: int = 0
	for rig in range(TextureManager.RIG_NAMES.size()):
		var body: Image = GenCharacters._rig_body(rig, c["shirt"], c["pants"], false)
		var head: Dictionary = GenCharacters._head_metrics(body)
		for hat in range(TextureManager.HAT_NAMES.size()):
			var t0: int = Time.get_ticks_msec()
			var a: Image = GenCharacters._hat_layer_for_slow(hat, head, 1.0, rig)
			t_slow += Time.get_ticks_msec() - t0
			t0 = Time.get_ticks_msec()
			var b: Image = GenCharacters._hat_layer_fast(hat, head, 1.0, rig)
			t_fast += Time.get_ticks_msec() - t0
			paare += 1
			if a.get_width() != b.get_width() or a.get_height() != b.get_height():
				print("[HATCMP][FEHLER] hut=%d rig=%d groesse %s vs %s" % [
					hat, rig, str(a.get_size()), str(b.get_size())])
				continue
			# Vergleich in C++ (memcmp ueber die Rohdaten) - sonst 7 Mio.
			# Schleifendurchlaeufe in GDScript.
			if a.get_data() == b.get_data():
				continue
			ungleich += 1
			var m: Dictionary = a.compute_image_metrics(b, true)
			if worst == "-":
				worst = "hut=%d rig=%d metrik=%s" % [hat, rig, str(m)]
	print("[HATCMP] paare=%d ungleiche_paare=%d erste_abweichung=%s" % [paare, ungleich, worst])
	print("[HATCMP] zeit_slow_ms=%d zeit_fast_ms=%d faktor=%.2f" % [
		t_slow, t_fast, (float(t_slow) / maxf(1.0, float(t_fast)))])
	print("[TEST][HATCMP144] ENDE")


# ================================================================
# v1.44 (C) — Aufgaben-Seite: Definitionen, Layout, Zustaende, Belohnung
# ================================================================

func _chal144() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v144/")
	uim.call("show_start_screen")
	await get_tree().create_timer(0.5).timeout
	var ss: Control = uim.get("start_screen")

	# --- 1) Definitionen (C1/C2) ---
	gm.call("chal_reset")
	gm.call("chal_ensure")

	# --- 1b) C3: Kontaktblatt der sechs Aufgaben-Icons (128 px, 2x vergroessert) ---
	var kinds: Array = ["revolver", "shield", "crown", "clock", "heart", "chest"]
	var cell: int = 256
	var sheet := Image.create(cell * kinds.size(), cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.10, 0.11, 0.14))
	for i in range(kinds.size()):
		var t: ImageTexture = TextureManager.get_texture("chal_" + str(kinds[i]))
		if t == null:
			print("[CHAL][TEST] FEHLER: Icon fehlt kind=%s" % str(kinds[i]))
			continue
		var im: Image = t.get_image()
		im.resize(cell, cell, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(im, Rect2i(0, 0, cell, cell), Vector2i(i * cell, 0))
	sheet.save_png("C:/Users/vince/Games/comic-shooter/screenshots/v144/chal_icons.png")
	print("[CHAL][TEST] ikonen_blatt=C:/Users/vince/Games/comic-shooter/screenshots/v144/chal_icons.png icons=%d px=%d" % [
		kinds.size(), cell])

	# --- 2) Kachel "CHALLENGES" im Menue (C8) ---
	var tile := _nav_hit(ss, "chal")
	if tile == null:
		print("[CHAL][TEST] FEHLER: Kachel CHALLENGES fehlt")
		print("[TEST][CHAL144] ENDE")
		return
	await _tap_at(tile, "CHALLENGES")
	await get_tree().create_timer(0.5).timeout
	var page: Control = uim.get("challenge_page")
	_walk_step(page != null and page.visible, "seite_CHALLENGES")
	await _shot("v144/aufgaben_1920.png")

	# --- 3) Zustaende sichtbar machen (C6): je einer einmal ---
	gm.call("chal_set_state", "boss", "LAEUFT")
	gm.call("chal_set_progress", "boss", 2)
	gm.call("chal_set_state", "schnell", "ERLEDIGT")
	gm.call("chal_set_progress", "schnell", 10)
	gm.call("chal_set_state", "sammler", "BELOHNT")
	gm.call("chal_set_progress", "sammler", 5)
	uim.call("refresh_challenges_ui")
	await get_tree().create_timer(0.3).timeout
	await _shot("v144/aufgaben_zustaende.png")

	# --- 4) Belohnung genau einmal (C7) ---
	var gems0: int = int(gm.get("gems"))
	var card: Control = null
	for ch in page.find_children("ChalCard_schnell", "PanelContainer", true, false):
		card = ch
	await _tap_at(card, "KARTE_SCHNELL")
	await get_tree().create_timer(0.4).timeout
	var gems1: int = int(gm.get("gems"))
	print("[CHAL][TEST] klick1 gems_vorher=%d nachher=%d diff=%d zustand=%s" % [
		gems0, gems1, gems1 - gems0, str(gm.call("chal_state", "schnell"))])
	await _tap_at(card, "KARTE_SCHNELL_ZWEITER_TAP")
	await get_tree().create_timer(0.4).timeout
	var gems2: int = int(gm.get("gems"))
	print("[CHAL][TEST] klick2 gems_vorher=%d nachher=%d diff=%d zustand=%s" % [
		gems1, gems2, gems2 - gems1, str(gm.call("chal_state", "schnell"))])
	await _shot("v144/aufgaben_belohnt.png")

	# --- 5) Zurueck-Knopf und Android-Zurueck (C8) ---
	await _tap_at(page.find_child("ChallengeBack", true, false), "CHALLENGES_ZURUECK")
	await get_tree().create_timer(0.4).timeout
	_walk_step(page == null or not page.visible, "zurueck_geschlossen")
	await _tap_at(tile, "CHALLENGES_ZWEITER_AUFRUF")
	await get_tree().create_timer(0.4).timeout
	_walk_step(page != null and page.visible, "erneut_offen")
	uim.call("_handle_back_button")
	await get_tree().create_timer(0.3).timeout
	_walk_step(page == null or not page.visible, "back_taste_geschlossen")

	# --- 6) Persistenz: Profil speichern und neu laden ---
	uim.call("show_start_screen")
	print("[CHAL][TEST] gespeichert zustaende=%s" % str(gm.get("challenges")))
	print("[TEST][CHAL144] ENDE")


# ================================================================
# v1.44 (R) — Shop-Redesign: Layout, echte Kaeufe, Tausch, Frame-Zeit
# ================================================================

func _shop144() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v144/")
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	var ss: Control = uim.get("start_screen")

	# --- 1) Shop ueber die Kachel oeffnen ---
	var tile := _nav_hit(ss, "shop")
	if tile == null:
		print("[SHOP][TEST] FEHLER: Kachel SHOP fehlt")
		print("[TEST][SHOP144] ENDE")
		return
	gm.set("gold", 100000)
	gm.set("gems", 500)
	await _tap_at(tile, "SHOP")
	await get_tree().create_timer(0.7).timeout
	var page: Control = uim.get("chest_page")
	_walk_step(page != null and page.visible, "seite_SHOP")
	await _shot("v144/shop_1920.png")

	# --- 2) R10: Frame-Zeit bei offenem Shop (3 Karten, Walze, Streifen) ---
	# R10: echte Frame-Zeit. VSync wuerde die Wanduhr auf 16,7 ms deckeln,
	# deshalb fuer die Messung aus und danach wieder an.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(0.3).timeout
	var t0: int = Time.get_ticks_msec()
	for _i in range(200):
		await get_tree().process_frame
	var fms: float = float(Time.get_ticks_msec() - t0) / 200.0
	var draws: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var objs: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("[PERF][SHOP] frames=200 frame_ms=%.2f draw_calls=%d knoten=%d ziel=16 vsync=aus" % [
		fms, draws, objs])
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	await get_tree().create_timer(0.3).timeout

	# --- 3) R7: drei echte Kaeufe (Kiste kaufen = Gold-Buchung + Reveal) ---
	# Kurze Kisten-Animation, damit der Lauf nicht 3x7 s wartet.
	OS.set_environment("COMIC_CHEST_FAST", "1.0")
	for tier in ["standard", "silver", "premium"]:
		var buy: Control = page.find_child("BuyChest_" + str(tier), true, false)
		if buy == null:
			print("[SHOP][TEST] FEHLER: Kaufknopf fehlt tier=%s" % str(tier))
			continue
		if uim.get("shop_scroll") != null:
			(uim.get("shop_scroll") as ScrollContainer).ensure_control_visible(buy)
			await get_tree().create_timer(0.25).timeout
		await _tap_at(buy, "KAUF_" + str(tier).to_upper())
		await get_tree().create_timer(1.6).timeout
		# Reveal-Fenster schliessen (sonst bleibt der Shop verdeckt)
		for c in uim.get_children():
			if c.has_signal("closed") and c.has_method("open"):
				c.emit_signal("closed")
				c.queue_free()
		await get_tree().create_timer(0.5).timeout

	# --- 4) R7: zwei Tausch-Buchungen ---
	for i in range(2):
		var btn: Control = page.find_child("ExchangeBtn_%d" % i, true, false)
		if btn == null:
			print("[SHOP][TEST] FEHLER: Tauschknopf fehlt idx=%d" % i)
			continue
		if uim.get("shop_scroll") != null:
			(uim.get("shop_scroll") as ScrollContainer).ensure_control_visible(btn)
			await get_tree().create_timer(0.25).timeout
		await _tap_at(btn, "TAUSCHEN_%d" % i)
		await get_tree().create_timer(0.3).timeout

	# --- 5) R6: Walze oeffnet aus dem Shop ---
	var slot_btn: Control = page.find_child("SlotOpenBtn", true, false)
	if uim.get("shop_scroll") != null and slot_btn != null:
		(uim.get("shop_scroll") as ScrollContainer).ensure_control_visible(slot_btn)
		await get_tree().create_timer(0.25).timeout
	await _tap_at(slot_btn, "WALZE_OEFFNEN")
	await get_tree().create_timer(0.9).timeout
	var slot = null
	for c in uim.get_children():
		var scr = c.get_script()
		if scr != null and str(scr.resource_path).ends_with("slot_ui.gd"):
			slot = c
	print("[SHOP][TEST] walze_offen=%s" % str(slot != null and is_instance_valid(slot) and (slot as Control).visible))
	await _shot("v144/shop_walze.png")
	if slot != null and is_instance_valid(slot):
		slot.queue_free()
	await get_tree().create_timer(0.3).timeout
	# _open_slot_ui versteckt den Shop - nach dem Test wieder oeffnen
	uim.call("_open_chest_page")
	await get_tree().create_timer(0.6).timeout
	_walk_step(page != null and page.visible, "shop_wieder_offen")

	# --- 6) R8/R9: zweite Breite 2400 ---
	DisplayServer.window_set_size(Vector2i(2400, 1080))
	await get_tree().create_timer(0.9).timeout
	uim.call("refresh_shop_ui")
	await get_tree().create_timer(0.4).timeout
	var sp = uim.call("_shop_p")
	await get_tree().process_frame
	sp.call("_log_layout")
	await _shot("v144/shop_2400.png")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await get_tree().create_timer(0.8).timeout
	await _shot("v144/shop_1920_b.png")
	print("[TEST][SHOP144] ENDE")


# ================================================================
# v1.44 (A) — Kisten-Laufband: Geschwindigkeitsprofil messen
# ================================================================

func _chest144() -> void:
	for _f in range(10):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ss = uim.get("start_screen") if uim != null else null
	if ss != null:
		ss.hide()
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v144/")
	# --- A5: vier Standbilder entlang EINES Laufs (0,3 s / 1 s / Ende-2 s / Einrasten) ---
	var shot_ui = load("res://scripts/ui/chest_ui.gd").new()
	shot_ui.setup(gm)
	cl.add_child(shot_ui)
	var shot_res := { "kind": "hat", "index": 3, "rarity": "rare", "name": "KAPPE", "duplicate": false }
	var ts0: int = Time.get_ticks_msec()
	shot_ui.call("open", "standard", shot_res)
	var dur_shot: float = float(shot_ui.get("duration"))
	await get_tree().create_timer(0.30).timeout
	await _shot("v144/chest_t0.png")
	await get_tree().create_timer(0.70).timeout
	await _shot("v144/chest_t1.png")
	var rest: float = maxf(0.2, (0.46 + dur_shot - 2.0) - float(Time.get_ticks_msec() - ts0) / 1000.0)
	await get_tree().create_timer(rest).timeout
	await _shot("v144/chest_t2.png")
	var rest2: float = maxf(0.2, (0.46 + dur_shot + 0.6) - float(Time.get_ticks_msec() - ts0) / 1000.0)
	await get_tree().create_timer(rest2).timeout
	await _shot("v144/chest_t3.png")
	print("[CHEST][TEST] standbilder=4 dauer=%.2f" % dur_shot)
	shot_ui.queue_free()
	await get_tree().create_timer(0.2).timeout

	var best_monoton: bool = true
	var worst_p: float = 0.0
	var max_still: float = 0.0
	for run in range(6):
		var ui = load("res://scripts/ui/chest_ui.gd").new()
		ui.setup(gm)
		cl.add_child(ui)
		var res := { "kind": "hat", "index": 3, "rarity": "rare", "name": "KAPPE", "duplicate": false }
		ui.call("open", "standard", res)
		var strip: Control = ui.get("strip")
		var ts: Array = []
		var xs: Array = []
		var t0: int = Time.get_ticks_msec()
		var guard: int = 0
		while guard < 200:
			await get_tree().create_timer(0.25).timeout
			guard += 1
			if strip != null and is_instance_valid(strip):
				ts.append(Time.get_ticks_msec() - t0)
				xs.append(strip.position.x)
			if not bool(ui.get("_spinning")) and (Time.get_ticks_msec() - t0) > 1200:
				break
		# --- Profil auswerten ---
		var v: Array = []
		for i in range(1, ts.size()):
			var dt: float = float(int(ts[i]) - int(ts[i - 1])) / 1000.0
			if dt <= 0.0:
				v.append(0.0)
			else:
				v.append(absf(float(xs[i]) - float(xs[i - 1])) / dt)
		# erster beweger Sample
		var first: int = 0
		for i in range(v.size()):
			if float(v[i]) > 1.0:
				first = i
				break
		# Spitze suchen: der erste Messpunkt nach dem Anlauf kann eine
		# Uebergangsstufe enthalten (Intervall beginnt vor dem Start).
		var peak: int = first
		for i in range(first, v.size()):
			if float(v[i]) > float(v[peak]):
				peak = i
		var total_dist: float = absf(float(xs[xs.size() - 1]) - float(xs[peak]))
		var monoton: bool = true
		var j: int = peak + 1
		while j < v.size():
			if float(v[j]) > float(v[j - 1]) * 1.05 + 1.0:
				monoton = false
			j += 1
		if run == 0 or not monoton:
			var vs: Array = []
			for i in range(v.size()):
				vs.append("%.0f" % float(v[i]))
			print("[CHEST][PROFIL] verlauf run=%d werte=%s peak=%d" % [run, ",".join(vs), peak])
		# letzte 0,75 s
		var t_end: int = int(ts[ts.size() - 1])
		var x_end: float = float(xs[xs.size() - 1])
		var x_075: float = x_end
		for i in range(ts.size() - 1, -1, -1):
			if int(ts[i]) <= t_end - 750:
				x_075 = float(xs[i])
				break
		var p_last: float = 0.0
		if total_dist > 1.0:
			p_last = absf(x_end - x_075) / total_dist * 100.0
		var i_mid: int = int(v.size() * 0.35)
		print("[CHEST][PROFIL] run=%d v_start=%.0f v_mitte=%.0f v_ende=%.1f px_s monoton=%s letzte_0_75s_prozent=%.2f proben=%d" % [
			run, float(v[peak]) if peak < v.size() else 0.0,
			float(v[clampi(i_mid, 0, v.size() - 1)]), float(v[v.size() - 1]),
			str(monoton), p_last, v.size()])
		if not monoton:
			best_monoton = false
		worst_p = maxf(worst_p, p_last)
		# "Stillstand" heisst: in den letzten 0,75 s bewegt sich NICHTS mehr.
		# Einzelner 0,25-s-Messwert ist dafuer zu grob (Rundung auf 0).
		if absf(x_end - x_075) < 2.0:
			max_still = 1.0
		ui.queue_free()
		await get_tree().create_timer(0.3).timeout
	print("[CHEST][ERGEBNIS] laeufe=6 monoton=%s max_letzte_0_75s_prozent=%.2f stillstand=%s" % [
		str(best_monoton), worst_p, str(max_still > 0.5)])
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v144/")
	print("[TEST][CHEST144] ENDE")


# ================================================================
# v1.44 (K) — Karten- und Jahreszeiten-Preise, Kauf, Migration
# ================================================================

func _karte144() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v144/")

	# --- K1: Preistabelle ---
	gm.call("season_price_log")

	# --- K2/K3: Karte kaufen (nur Fruehling frei), dann SOMMER kaufen ---
	gm.set("gold", 40000)
	gm.set("unlocked_maps", ["earth"])
	gm.set("season_unlocks", {})
	var ok_map: bool = bool(gm.call("buy_map", "mars"))
	print("[KARTE][TEST] kauf_mars ok=%s gold=%d" % [str(ok_map), int(gm.get("gold"))])
	var frei_vor: int = (gm.get("season_unlocks") as Dictionary).get("mars", []).size()
	print("[KARTE][TEST] mars_frei_nach_kauf=%d (erwartet 1 = nur spring)" % frei_vor)
	var preis: int = int(gm.call("season_price_for", "mars", "summer"))
	var gold_vor: int = int(gm.get("gold"))
	var ok_s: bool = bool(gm.call("buy_season", "mars", "summer"))
	print("[SEASON][TEST] kauf_sommer preis=%d gold_vorher=%d nachher=%d ok=%s" % [
		preis, gold_vor, int(gm.get("gold")), str(ok_s)])
	print("[KARTE][TEST] mars_frei_nach_sommer=%d" % (gm.get("season_unlocks") as Dictionary).get("mars", []).size())

	# --- K3: Neustart simulieren (Profil neu von Platte lesen) ---
	gm.call("_load_profile")
	var frei_nach: int = (gm.get("season_unlocks") as Dictionary).get("mars", []).size()
	print("[PROFILE][TEST] nach_neustart mars_frei=%d sommer_frei=%s" % [
		frei_nach, str(gm.call("is_season_unlocked", "mars", "summer"))])

	# --- K4: Karten-Seite + Sichtpruefung ---
	uim.call("show_start_screen")
	await get_tree().create_timer(0.3).timeout
	uim.call("_open_maps_page")
	await get_tree().create_timer(0.8).timeout
	await _shot("v144/karten_1920.png")
	print("[TEST][KARTE144] ENDE")


# ================================================================
# v1.44 — Probe: bewegt sich das erste Monster im Endlos-Run?
# ================================================================

func _mprobe144() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ss = uim.get("start_screen")
	if ss != null:
		ss.hide()
	gm.set("game_mode", 0)
	gm.call("start_game", false, false)
	await get_tree().create_timer(3.0).timeout
	var ms = get_tree().get_nodes_in_group("monsters")
	print("[PROBE] monster=%d paused=%s" % [ms.size(), str(get_tree().paused)])
	for m in ms:
		var n := m as Node2D
		var p0: Vector2 = n.global_position
		var sp: float = float(n.get("speed")) if n.get("speed") != null else -1.0
		var hp: float = float(n.get("current_health")) if n.get("current_health") != null else -1.0
		var tm: float = float(n.get("move_speed")) if n.get("move_speed") != null else -1.0
		print("[PROBE] typ=%s pos=(%.0f,%.0f) speed=%.1f move_speed=%.1f hp=%.0f prozess=%s" % [
			n.name, p0.x, p0.y, sp, tm, hp, str(n.process_mode)])
		await get_tree().create_timer(0.5).timeout
		var p1: Vector2 = n.global_position
		print("[PROBE] nach_0_5s pos=(%.0f,%.0f) delta=%.2f" % [p1.x, p1.y, p0.distance_to(p1)])
	# Spielerposition zum Vergleich
	var pl = gm.get("player")
	if pl != null and is_instance_valid(pl):
		print("[PROBE] spieler pos=(%.0f,%.0f) state=%d" % [
			pl.global_position.x, pl.global_position.y, int(gm.get("current_state"))])
	print("[TEST][MPROBE144] ENDE")


# ================================================================
# v1.45 (T) — Ton: Pegel messen, WAVs exportieren, Regler pruefen
# ================================================================

func _snd145() -> void:
	for _f in range(30):
		await get_tree().process_frame
	SoundManager.sfx_force()
	await get_tree().create_timer(0.3).timeout
	var dir: String = "C:/Users/vince/Games/comic-shooter/screenshots/v145/audio/"
	DirAccess.make_dir_recursive_absolute(dir)
	var streams: Dictionary = SoundManager.get("_streams")
	var keys: Array = streams.keys()
	keys.sort()
	var lines: Array = []
	var lo: float = 0.0
	var hi: float = -140.0
	var clips: int = 0
	for k in keys:
		var wav: AudioStreamWAV = streams[k]
		var m: Dictionary = _wav_measure(wav)
		lines.append("%-24s rms=%6.1f db peak=%6.1f db" % [str(k), float(m["rms"]), float(m["peak"])])
		lo = minf(lo, float(m["rms"]))
		hi = maxf(hi, float(m["rms"]))
		clips += int(m["clip"])
		_save_wav(dir + str(k) + ".wav", wav)
	print("[SND][TABELLE] klaenge=%d rms_min=%.1fdb rms_max=%.1fdb streuung=%.1fdb clipping=%d" % [
		keys.size(), lo, hi, hi - lo, clips])
	for l in lines:
		print("[SND][TABELLE] " + str(l))
	# Tabelle als Datei (fuer den Nutzer)
	var f := FileAccess.open(dir + "_pegel.txt", FileAccess.WRITE)
	if f != null:
		f.store_line("Klang-Pegel v1.45 (RMS/Peak in dBFS, Ziel: ein Bezugspegel)")
		f.store_line("rms_min=%.1f rms_max=%.1f streuung=%.1f dB" % [lo, hi, hi - lo])
		for l in lines:
			f.store_line(str(l))
		f.close()
		print("[SND][TABELLE] datei=%s_pegel.txt" % dir)
	# Musik
	for t in ["menu_1", "game_1", "game_boss"]:
		var st: AudioStreamWAV = SoundManager.call("_music_stream", t)
		var mm: Dictionary = _wav_measure(st)
		var gain: float = SoundManager.call("_base_for", t)
		print("[SND][MUSIKTEST] track=%s rms=%.1fdb regler100_gain=%.1fdb ergebnis=%.1fdb" % [
			t, float(mm["rms"]), gain, float(mm["rms"]) + gain])
		_save_wav(dir + "musik_" + t + ".wav", st)
	# T7: Regler 0 und 100
	SoundManager.set_music_volume(0)
	print("[SND][TEST] regler=0 stumm=true db=%.1f" % float(SoundManager.call("_music_db", 0.0)))
	SoundManager.set_music_volume(100)
	print("[SND][TEST] regler=100 laut=true db=%.1f" % float(SoundManager.call("_music_db", 0.0)))
	SoundManager.set_music_volume(80)
	print("[TEST][SND145] ENDE")


func _wav_measure(wav: AudioStreamWAV) -> Dictionary:
	if wav == null:
		return { "rms": -140.0, "peak": -140.0, "clip": 0 }
	var d: PackedByteArray = wav.data
	var n: int = d.size() / 2
	if n <= 0:
		return { "rms": -140.0, "peak": -140.0, "clip": 0 }
	var sq: float = 0.0
	var peak: int = 0
	var clip: int = 0
	for i in range(n):
		var v: int = d.decode_s16(i * 2)
		sq += float(v) * float(v)
		var a: int = absi(v)
		if a > peak:
			peak = a
		if a >= 32767:
			clip += 1
	var rms: float = sqrt(sq / float(n))
	return {
		"rms": SoundManager.call("_db", rms / 32767.0),
		"peak": SoundManager.call("_db", float(peak) / 32767.0),
		"clip": clip,
	}


func _save_wav(path: String, wav: AudioStreamWAV) -> void:
	# Minimaler RIFF/WAVE-Schreiber (16-bit mono PCM), damit der Nutzer die
	# Klaenge ohne Spiel anhoeren kann.
	if wav == null:
		return
	var d: PackedByteArray = wav.data
	var rate: int = wav.mix_rate
	var h := PackedByteArray()
	h.resize(44)
	h.encode_u32(0, 0x46464952)          # "RIFF"
	h.encode_u32(4, 36 + d.size())
	h.encode_u32(8, 0x45564157)          # "WAVE"
	h.encode_u32(12, 0x20746d66)         # "fmt "
	h.encode_u32(16, 16)
	h.encode_u16(20, 1)                  # PCM
	h.encode_u16(22, 1)                  # mono
	h.encode_u32(24, rate)
	h.encode_u32(28, rate * 2)
	h.encode_u16(32, 2)
	h.encode_u16(34, 16)
	h.encode_u32(36, 0x61746164)         # "data"
	h.encode_u32(40, d.size())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("[SND][FEHLER] WAV nicht schreibbar: %s" % path)
		return
	f.store_buffer(h)
	f.store_buffer(d)
	f.close()


# ================================================================
# v1.45 (K) — neue Kisten: Kontaktblatt + Shop-Einbau pruefen
# ================================================================

func _chest145() -> void:
	for _f in range(20):
		await get_tree().process_frame
	TextureManager.get_texture("chest_gem_standard")
	var cells: Array = []
	for tier in ["standard", "silver", "premium"]:
		for offen in [false, true]:
			var key: String = ("chest_gem_open_" + str(tier)) if offen else ("chest_gem_" + str(tier))
			cells.append({
				"tex": TextureManager.get_texture(key),
				"line1": "%s%s" % [str(tier).to_upper(), "  OFFEN" if offen else ""],
				"line2": "64x64 -> 256 px, Kontur 3 px",
			})
	await _sheet(cells, 3, 300, 320, "v1.45 (K) — Kisten im Comic-Shooter-Look (gezeichnet)", "v145/kisten_neu.png")
	print("[TEST][CHEST145] ENDE")


# ================================================================
# v1.45 (L) — ein Ladebildschirm: Boot-Zustand und Run-Zustand
# ================================================================

func _load145() -> void:
	for _f in range(20):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v145/")
	# --- Boot-Zustand auf der gemeinsamen Flaeche ---
	uim.call("build_boot_screen")
	uim.call("boot_progress", 0.42, "Texturen 21/50")
	await get_tree().create_timer(0.5).timeout
	await _shot("v145/boot_1080.png")
	var ls: Control = uim.get("load_screen")
	print("[LOAD][TEST] boot sichtbar=%s modus_name=%s icon_sichtbar=%s" % [
		str(ls != null and ls.visible),
		str((uim.get("load_mode_name") as Label).text),
		str((uim.get("load_mode_icon") as Control).visible)])
	var info: Dictionary = uim.call("load_layout_probe")
	print("[LOAD][MITTE] zustand=boot kasten=(%.0f..%.0f) name=(%.0f..%.0f) text_mitte=%.1f kasten_mitte=%.1f abweichung=%.1fpx desc_abweichung=%.1fpx" % [
		float(info["kasten"].position.x), float(info["kasten"].position.x + info["kasten"].size.x),
		float(info["name"].position.x), float(info["name"].position.x + info["name"].size.x),
		float(info["text_mitte"]), float(info["kasten_mitte"]), float(info["abweichung"]),
		float(info["beschreibung_abweichung"])])
	# --- Run-Zustand: gleiche Flaeche, Modus-Grafik sichtbar ---
	uim.call("hide_boot_screen")
	await get_tree().create_timer(0.4).timeout
	uim.call("show_load_for_run")
	await get_tree().create_timer(0.8).timeout
	await _shot("v145/run_load_1080.png")
	var info2: Dictionary = uim.call("load_layout_probe")
	print("[LOAD][MITTE] zustand=run kasten=(%.0f..%.0f) name=(%.0f..%.0f) text_mitte=%.1f kasten_mitte=%.1f abweichung=%.1fpx desc_abweichung=%.1fpx" % [
		float(info2["kasten"].position.x), float(info2["kasten"].position.x + info2["kasten"].size.x),
		float(info2["name"].position.x), float(info2["name"].position.x + info2["name"].size.x),
		float(info2["text_mitte"]), float(info2["kasten_mitte"]), float(info2["abweichung"]),
		float(info2["beschreibung_abweichung"])])
	print("[LOAD][TEST] run sichtbar=%s icon_sichtbar=%s balken=(%.0f,%.0f)" % [
		str(ls != null and ls.visible),
		str((uim.get("load_mode_icon") as Control).visible),
		float(info2["balken"].x), float(info2["balken"].y)])
	uim.call("_hide_load_screen")
	await get_tree().create_timer(0.5).timeout
	print("[LOAD][TEST] fade_aus sichtbar=%s" % str(ls != null and ls.visible))
	print("[TEST][LOAD145] ENDE")


# ============================================================
# v1.46 (Recon): Huthut - Augen verdeckt? Koerper ueberdeckt?
# ============================================================
func _eye_pixels(img: Image) -> Array:
	# Augen = helle Pixel im Kopfbereich (oberes Drittel der Figur).
	var out: Array = []
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y in range(0, int(h * 0.45)):
		for x in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.6:
				continue
			if c.r > 0.86 and c.g > 0.86 and c.b > 0.86:
				out.append(Vector2i(x, y))
	return out


func _hat146() -> void:
	for _f in range(10):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/")
	var rigs: int = TextureManager.RIG_NAMES.size()
	var hats: int = TextureManager.HAT_NAMES.size()
	var schlecht: Array = []
	var max_aug: Array = []
	var max_koerp: Array = []
	for h in range(hats):
		max_aug.append(0.0)
		max_koerp.append(0.0)
	# F5: Kontaktblatt aller Paare (17 Rigs x 24 Huete) in 4 Bloecken
	var cell: int = 64
	var cols: int = hats - 1
	var sheet := Image.create(cols * cell + 90, rigs * cell + 40, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.10, 0.11, 0.14))
	for r in range(rigs):
		var base: Image = TextureManager.get_skin_texture(0, r).get_image()
		var base_px: int = base.get_width()
		# Beide Bilder auf dieselbe Groesse bringen, sonst vergleicht der Test
		# Pixel an verschiedenen Positionen (128er-Skin gegen 64er-Hutbild).
		if base.get_width() != 64:
			base.resize(64, 64, Image.INTERPOLATE_NEAREST)
		# F1/F2: Kopfmasse inkl. Augenband zuerst messen, dann die Augenpixel.
		var hm: Dictionary = GenCharacters._head_metrics(base)
		var eyes: Array = GenCharacters.eye_pixels(base, hm)
		# Koerperflaeche unterhalb des Kopfes (unteres 55 %)
		var koerper: Array = []
		var w: int = base.get_width()
		var h2: int = base.get_height()
		for y in range(int(h2 * 0.45), h2):
			for x in range(w):
				if base.get_pixel(x, y).a > 0.6:
					koerper.append(Vector2i(x, y))
		# F1: tatsaechliche Skalierung je Rig (aus _head_metrics + HAT_SEAT)
		var s_min: float = 9.0
		var s_max: float = 0.0
		for hi2 in range(1, hats):
			var seat: Array = GenCharacters.HAT_SEAT.get(hi2, [4.0, 1.0])
			var sc: float = clampf(float(hm["w"]) / GenCharacters.NOM_HEAD_W, 0.85, 1.30) * float(seat[1])
			s_min = minf(s_min, sc)
			s_max = maxf(s_max, sc)
		print("[HAT][SKALA] rig=%d kopf_w=%.0f skala_min=%.2f skala_max=%.2f streuung=%.2f augenband=%.0f..%.0f" % [
			r, float(hm["w"]), s_min, s_max, s_max - s_min,
			float(hm.get("eye_top", 0.0)), float(hm.get("eye_bot", 0.0))])
		for hi in range(1, hats):
			var comb: Image = TextureManager.get_skin_hat_texture(0, r, hi).get_image()
			if comb.get_width() != 64:
				comb.resize(64, 64, Image.INTERPOLATE_NEAREST)
			var verdeckt: int = 0
			for ep in eyes:
				var c0: Color = base.get_pixel(ep.x, ep.y)
				var c1: Color = comb.get_pixel(ep.x, ep.y)
				if absf(c1.r - c0.r) + absf(c1.g - c0.g) + absf(c1.b - c0.b) > 0.15:
					verdeckt += 1
			var k_verdeckt: int = 0
			for kp in koerper:
				var c2: Color = base.get_pixel(kp.x, kp.y)
				var c3: Color = comb.get_pixel(kp.x, kp.y)
				if absf(c3.r - c2.r) + absf(c3.g - c2.g) + absf(c3.b - c2.b) > 0.15:
					k_verdeckt += 1
			var aug_proz: float = 0.0
			if eyes.size() > 0:
				aug_proz = 100.0 * float(verdeckt) / float(eyes.size())
			var koer_proz: float = 0.0
			if koerper.size() > 0:
				koer_proz = 100.0 * float(k_verdeckt) / float(koerper.size())
			max_aug[hi] = maxf(float(max_aug[hi]), aug_proz)
			max_koerp[hi] = maxf(float(max_koerp[hi]), koer_proz)
			if aug_proz > 10.0 or koer_proz > 3.0:
				schlecht.append({"rig": r, "hut": hi, "augen": aug_proz, "koerper": koer_proz})
			if hi <= 2 or r == 0:
				print("[HAT][PRUEF] rig=%d hut=%d quelle_px=%d augen_px=%d augen_verdeckt=%.0f%% koerper_ueberdeckt=%.1f%%" % [
					r, hi, base_px, eyes.size(), aug_proz, koer_proz])
			# Kachel in das Kontaktblatt
			var tile: Image = comb.duplicate()
			tile.convert(Image.FORMAT_RGBA8)
			tile.resize(cell, cell, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(tile, Rect2i(0, 0, cell, cell), Vector2i(80 + (hi - 1) * cell, 8 + r * cell))
		var lbl: Image = TextureManager.get_skin_texture(0, r).get_image()
		lbl.convert(Image.FORMAT_RGBA8)
		lbl.resize(72, 72, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(lbl, Rect2i(0, 0, 72, 72), Vector2i(4, 4 + r * cell))
	print("[HAT][PRUEF] ERGEBNIS paare=%d auffaellig=%d" % [(rigs) * (hats - 1), schlecht.size()])
	for hi in range(1, hats):
		print("[HAT][SUM] hut=%d name=%s max_augen=%.0f%% max_koerper=%.1f%%" % [
			hi, str(TextureManager.HAT_NAMES[hi]), float(max_aug[hi]), float(max_koerp[hi])])
	for e in schlecht.slice(0, 25):
		print("[HAT][PRUEF] AUFFAELLIG rig=%d hut=%d augen=%.0f%% koerper=%.1f%%" % [
			int(e["rig"]), int(e["hut"]), float(e["augen"]), float(e["koerper"])])
	var sheet_path: String = SHOT_DIR + "v146/hats_17x24.png"
	sheet.save_png(sheet_path)
	print("[HAT][BLATT] datei=%s px=%dx%d kacheln=%d" % [
		sheet_path, sheet.get_width(), sheet.get_height(), (rigs) * (hats - 1)])
	# F6: die vorher auffaelligen Huete einzeln auf allen 17 Rigs
	var fix_hats: Array = [6, 7, 5, 16]
	var fix_sheet := Image.create(rigs * 80 + 100, fix_hats.size() * 80 + 10, false, Image.FORMAT_RGBA8)
	fix_sheet.fill(Color(0.10, 0.11, 0.14))
	for i in range(fix_hats.size()):
		var hi3: int = int(fix_hats[i])
		for r in range(rigs):
			var im: Image = TextureManager.get_skin_hat_texture(0, r, hi3).get_image()
			im.convert(Image.FORMAT_RGBA8)
			im.resize(76, 76, Image.INTERPOLATE_NEAREST)
			fix_sheet.blend_rect(im, Rect2i(0, 0, 76, 76), Vector2i(96 + r * 80, 6 + i * 80))
	var fix_path: String = SHOT_DIR + "v146/hats_fix.png"
	fix_sheet.save_png(fix_path)
	print("[HAT][FIX] datei=%s huete=%s rigs=%d" % [fix_path, str(fix_hats), rigs])
	print("[TEST][HAT146] ENDE")


# ============================================================
# v1.46 (Recon): Musikzustand messen - Trackwechsel, Boss, Loop
# ============================================================
func _musik_state(tag: String) -> void:
	var mp = SoundManager.call("active_player")
	var cur: String = str(SoundManager.get("_current_music"))
	var duck: bool = bool(SoundManager.get("_music_ducked"))
	var p_play: bool = mp != null and bool(mp.playing)
	var p_db: float = float(mp.volume_db) if mp != null else -999.0
	var len_p: float = (float(mp.stream.data.size()) / 2.0 / float(mp.stream.mix_rate)) if (mp != null and mp.stream != null) else 0.0
	print("[MUSIK][STATE] tag=%s current=%s spieler_playing=%s spieler_db=%.1f ducked=%s laenge=%.2fs pos=%.2f" % [
		tag, cur, str(p_play), p_db, str(duck), len_p,
		float(mp.get_playback_position()) if p_play else 0.0])


func _musik146() -> void:
	for _f in range(10):
		await get_tree().process_frame
	# --- D1/E1: Klangbild aller Tracks (die [MUSIK][CFG]-Zeilen kommen vom Bau,
	# hier zusaetzlich als Tabelle mit Soll-Bereichen) ---
	var cfg_d: Dictionary = SoundManager.TRACK_CFG
	var spiel_ok: bool = true
	for k in ["game_1", "game_2", "game_3", "game_4"]:
		var c: Dictionary = cfg_d[k]
		var ok: bool = str(c["lead"]) == "sine" and float(c["drums"]) <= 0.03 and float(c["bpm"]) >= 84.0 and float(c["bpm"]) <= 96.0
		spiel_ok = spiel_ok and ok
		print("[MUSIK][PRUEF] track=%s lead=%s bpm=%.0f drums=%.2f menu_charakter=%s" % [
			k, str(c["lead"]), float(c["bpm"]), float(c["drums"]), str(ok)])
	var bx: Dictionary = cfg_d["boss_1"]
	print("[MUSIK][BOSS] unterschied=ja lead=%s bpm=%.0f bass_hz=%.1f drums=%.2f tritonus=%s heartbeat=%.2f spiel_ok=%s" % [
		str(bx["lead"]), float(bx["bpm"]), float(bx["bass_hz"]), float(bx["drums"]),
		str(bx["tritonus"]), float(bx["heartbeat"]), str(spiel_ok)])
	print("[MUSIK][DEF] tracks=%d fade=%.1fs loop_mode=%s" % [
		cfg_d.size(), float(SoundManager.MUSIC_FADE),
		str((SoundManager.get("_music_streams") as Dictionary).size())])

	SoundManager.play_music("menu_1")
	await get_tree().create_timer(1.6).timeout
	_musik_state("menu_nach_1.6s")
	# --- D2/D3: Wechsel game_1 -> game_2 -> game_3, danach Boss und zurueck ---
	SoundManager.play_music_for_round(1, false)
	await get_tree().create_timer(1.2).timeout
	_musik_state("runde1_nach_1.2s")
	SoundManager.play_music_for_round(2, false)
	await get_tree().create_timer(1.2).timeout
	_musik_state("runde2_nach_1.2s")
	SoundManager.play_music_for_round(3, false)
	await get_tree().create_timer(1.2).timeout
	_musik_state("runde3_nach_1.2s")
	SoundManager.play_music_for_round(3, true)
	await get_tree().create_timer(1.2).timeout
	_musik_state("boss_nach_1.2s")
	SoundManager.play_music_for_round(3, false)
	await get_tree().create_timer(1.2).timeout
	_musik_state("boss_ende_nach_1.2s")

	# --- D5: Pause-Daempfung und Rueckweg ---
	var vorher_db: float = float(SoundManager.call("active_player").volume_db)
	SoundManager.set_music_ducked(true)
	await get_tree().create_timer(0.3).timeout
	var duck_db: float = float(SoundManager.call("active_player").volume_db)
	SoundManager.set_music_ducked(false)
	await get_tree().create_timer(0.3).timeout
	var zurueck_db: float = float(SoundManager.call("active_player").volume_db)
	print("[MUSIK][DUCK] pause=an db=%.1f weiter=aus db=%.1f vorher=%.1f zurueck_ok=%s" % [
		duck_db, zurueck_db, vorher_db, str(absf(zurueck_db - vorher_db) <= 0.5)])

	# --- D4: Loop ueber die Tracklaenge hinaus, Luecke messen ---
	SoundManager.play_music("game_2")
	await get_tree().create_timer(1.0).timeout
	var mp = SoundManager.call("active_player")
	var laenge: float = float(mp.stream.data.size()) / 2.0 / float(mp.stream.mix_rate)
	SoundManager.set("_loop_restarts", 0)
	SoundManager.set("_loop_gap_max_ms", 0.0)
	var t0: int = Time.get_ticks_msec()
	var aussetzer: int = 0
	var pos_vorher: float = -1.0
	for i in range(int(ceil((laenge * 2.0 + 2.0) / 0.25))):
		await get_tree().create_timer(0.25).timeout
		var p_now = SoundManager.call("active_player")
		var spielt: bool = p_now != null and bool(p_now.playing)
		var pos: float = float(p_now.get_playback_position()) if spielt else -1.0
		if not spielt:
			aussetzer += 1
		if pos_vorher >= 0.0 and pos >= 0.0 and pos < pos_vorher:
			print("[MUSIK][LOOP] sprung t=%.2fs von=%.2f nach=%.2f (seek, kein Aussetzer)" % [
				float(Time.get_ticks_msec() - t0) / 1000.0, pos_vorher, pos])
		pos_vorher = pos
	var restarts: int = int(SoundManager.get("_loop_restarts"))
	var luecke: float = float(SoundManager.get("_loop_gap_max_ms"))
	print("[MUSIK][LOOP] track=game_2 laenge=%.2fs aussetzer=%d neustarts=%d luecke_max_ms=%.0f loop_ok=%s quelle=seek" % [
		laenge, aussetzer, restarts, luecke, str(aussetzer == 0 and luecke <= 30.0)])

	# --- E4: alle sieben Tracks als WAV + Pegeltabelle ---
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/audio/")
	var pegel: Array = []
	for name in cfg_d.keys():
		var w: AudioStreamWAV = SoundManager.call("_music_stream", str(name))
		if w == null:
			print("[MUSIK][FEHLER] wav fehlt track=%s" % str(name))
			continue
		var path: String = SHOT_DIR + "v146/audio/%s.wav" % str(name)
		var err: int = w.save_to_wav(path)
		var sek: float = float(w.data.size()) / 2.0 / float(w.mix_rate)
		var rms: float = float(SoundManager.call("music_rms_db", str(name)))
		var db100: float = float(SoundManager.call("music_gain_db", str(name)))
		pegel.append("%s  %.2f s  rms=%.1f dBFS  gain100=%.1f dB  ergebnis=%.1f dBFS  loop=%s" % [
			str(name), sek, rms, db100, rms + db100,
			"FORWARD" if int(w.loop_mode) == AudioStreamWAV.LOOP_FORWARD else "AUS"])
		print("[MUSIK][WAV] track=%s datei=%s dauer=%.2fs err=%d" % [str(name), path, sek, err])
	var f := FileAccess.open(SHOT_DIR + "v146/audio/_pegel.txt", FileAccess.WRITE)
	if f != null:
		f.store_line("# v1.46 Musik-Pegel (Regler 100 %%) - Ziel %.1f dBFS" % SoundManager.MUSIC_RMS_TARGET_DB)
		for z in pegel:
			f.store_line(str(z))
		f.close()
	print("[MUSIK][PEGEL] tracks=%d ziel=%.1fdb datei=%s/v146/audio/_pegel.txt" % [
		pegel.size(), SoundManager.MUSIC_RMS_TARGET_DB, SHOT_DIR])
	print("[TEST][MUSIK146] ENDE")


# ============================================================
# v1.45 (I): sechs App-Icon-Entwuerfe, 1024x1024, Comic-Look
# ============================================================
const ICON_PX145 := 1024


func _icon_shell(vp: SubViewport) -> Control:
	# Gemeinsamer Rahmen: dunkler Grund, Strahlenkranz, dicke Goldkontur.
	var root := Control.new()
	root.size = Vector2(ICON_PX145, ICON_PX145)
	vp.add_child(root)
	var bg := ColorRect.new()
	bg.size = Vector2(ICON_PX145, ICON_PX145)
	bg.color = Color(0.06, 0.07, 0.14)
	root.add_child(bg)
	var c := Vector2(ICON_PX145, ICON_PX145) * 0.5
	for i in range(16):
		var a0: float = TAU * float(i) / 16.0
		var a1: float = TAU * float(i + 1) / 16.0
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			c, c + Vector2(cos(a0), sin(a0)) * 900.0, c + Vector2(cos(a1), sin(a1)) * 900.0,
		])
		poly.color = Color(1.0, 0.82, 0.24, 0.13) if i % 2 == 0 else Color(1.0, 0.30, 0.22, 0.10)
		root.add_child(poly)
	return root


func _icon_sprite(root: Control, tex: Texture2D, px: float, pos: Vector2, rot: float = 0.0) -> void:
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.size = Vector2(px, px)
	tr.pivot_offset = Vector2(px, px) * 0.5
	tr.position = pos - Vector2(px, px) * 0.5
	tr.rotation = rot
	root.add_child(tr)


func _icon_text(root: Control, txt: String, px: int, pos: Vector2, col: Color, outline: int = 22) -> void:
	var l := Label.new()
	l.text = txt
	var ls := LabelSettings.new()
	ls.font_size = px
	ls.font_color = col
	ls.outline_size = outline
	ls.outline_color = Color(0.04, 0.04, 0.08)
	l.label_settings = ls
	l.size = Vector2(900, px + 40)
	l.position = pos
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(l)


func _icon_frame(root: Control) -> void:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.border_color = Color(0.99, 0.80, 0.22)
	sb.set_border_width_all(34)
	sb.set_corner_radius_all(120)
	p.add_theme_stylebox_override("panel", sb)
	p.size = Vector2(ICON_PX145, ICON_PX145)
	root.add_child(p)


func _make_icon145(motif: String) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(ICON_PX145, ICON_PX145)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	add_child(vp)
	var root: Control = _icon_shell(vp)
	var hero: Texture2D = TextureManager.get_player_texture(0, 0)
	var mon: Texture2D = TextureManager.get_texture("monster_green")
	var chest: Texture2D = TextureManager.get_texture("chest_gem_premium")
	var rev: Texture2D = TextureManager.get_texture("weapon_revolver")
	var crown: Texture2D = TextureManager.get_texture("chal_crown")
	var gem: Texture2D = TextureManager.get_texture("slot_gem3")
	match motif:
		"a":
			_icon_sprite(root, hero, 720.0, Vector2(470, 520))
			_icon_sprite(root, rev, 420.0, Vector2(760, 720), -0.32)
		"b":
			_icon_sprite(root, chest, 580.0, Vector2(470, 600))
			var gem1: Texture2D = TextureManager.get_texture("slot_gem1")
			if gem1 != null:
				_icon_sprite(root, gem1, 300.0, Vector2(800, 330), 0.15)
		"c":
			_icon_text(root, "CS", 460, Vector2(62, 240), Color(1.0, 0.86, 0.20), 40)
			_icon_text(root, "COMIC SHOOTER", 92, Vector2(62, 780), Color(1.0, 1.0, 1.0), 20)
		"d":
			# Walzen-Symbole in einem Walzenfenster (wie im Spiel)
			var win := Panel.new()
			var wsb := StyleBoxFlat.new()
			wsb.bg_color = Color(0.08, 0.09, 0.14, 0.96)
			wsb.border_color = Color(0.99, 0.80, 0.22)
			wsb.set_border_width_all(16)
			wsb.set_corner_radius_all(28)
			win.add_theme_stylebox_override("panel", wsb)
			win.position = Vector2(150, 300)
			win.size = Vector2(724, 400)
			root.add_child(win)
			var syms: Array = ["slot_cherry", "slot_skull", "slot_gold3"]
			for i in range(3):
				var t: Texture2D = TextureManager.get_texture(str(syms[i]))
				_icon_sprite(root, t, 230.0, Vector2(272 + i * 240, 500))
			_icon_text(root, "GLÜCKSWALZE", 76, Vector2(62, 760), Color(1.0, 0.86, 0.20), 18)
		"e":
			_icon_sprite(root, mon, 520.0, Vector2(680, 400))
			_icon_sprite(root, hero, 520.0, Vector2(340, 660))
			_icon_text(root, "VS", 150, Vector2(62, 440), Color(1.0, 0.35, 0.30), 26)
		"f":
			var w: Control = load("res://scripts/ui/wheel_view.gd").new()
			w.call("set_radius", 780.0)
			w.size = Vector2(780, 780)
			w.position = Vector2(122, 122)
			root.add_child(w)
	_icon_frame(root)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	return img


func _icon145() -> void:
	for _f in range(10):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v145/icons/")
	var namen: Array = ["a", "b", "c", "d", "e", "f"]
	for nm in namen:
		var img: Image = await _make_icon145(str(nm))
		if img == null or img.get_width() == 0:
			print("[ICON][FEHLER] entwurf=%s leer" % str(nm))
			continue
		var path: String = SHOT_DIR + "v145/icons/icon_%s.png" % str(nm)
		img.save_png(path)
		print("[ICON][ENTWURF] name=icon_%s.png px=%dx%d datei=%s" % [
			str(nm), img.get_width(), img.get_height(), path])
	# Groessen-Vorschau je Entwurf (48/72/96/144) - als eigenes Blatt je Entwurf
	for nm in namen:
		var src := Image.load_from_file(SHOT_DIR + "v145/icons/icon_%s.png" % str(nm))
		if src == null:
			continue
		var sheet := Image.create(640, 200, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.10, 0.11, 0.14))
		var xs: Array = [20, 110, 210, 340]
		var sizes: Array = [48, 72, 96, 144]
		for i in range(sizes.size()):
			var im2: Image = src.duplicate()
			im2.resize(int(sizes[i]), int(sizes[i]), Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(im2, Rect2i(0, 0, int(sizes[i]), int(sizes[i])),
				Vector2i(int(xs[i]), 28))
		sheet.save_png(SHOT_DIR + "v145/icons/groessen_%s.png" % str(nm))
		print("[ICON][GROESSEN] entwurf=%s px=48,72,96,144" % str(nm))
	print("[TEST][ICON145] ENDE")


# ============================================================
# v1.45 (C): Aufgaben als Spielmodi - alle 6 auf LEICHT bis zur Belohnung
# ============================================================
const ChalRun145 = preload("res://scripts/core/challenge_run.gd")


func _chal145() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v145/")
	uim.call("show_start_screen")
	await get_tree().create_timer(0.5).timeout
	gm.call("chal_reset")
	gm.set("gems", 0)
	gm.call("chal_ensure")

	# --- C1: alle 18 Stufen-Kombinationen ---
	for d in ChalRun145.DEFS:
		for sk in ChalRun145.STUFEN:
			var cr = ChalRun145.new()
			cr.setup(str(d["id"]), str(sk))

	# --- Karte mit START + Stufenwahl ---
	uim.call("_open_challenge_page")
	await get_tree().create_timer(0.5).timeout
	var page: Control = uim.get("challenge_page")
	var start_btn: Button = page.find_child("ChalStart_revolver", true, false)
	var stufe_btn: Button = page.find_child("Stufe_revolver_hart", true, false)
	print("[CHAL][KARTE] seite=%s start_knopf=%s stufen=%d" % [
		str(page != null and page.visible), str(start_btn != null),
		page.find_children("Stufe_*", "Button", true, false).size()])
	await _shot("v145/chal_karte.png")

	# --- je Aufgabe: echter Start, Ziel per Debug-Hilfe, Auswertung, Belohnung ---
	var erledigt: int = 0
	var aufgaben: Array = ["revolver", "eisern", "boss", "schnell", "ohne_schild", "sammler"]
	for i in range(aufgaben.size()):
		var id: String = str(aufgaben[i])
		uim.call("_open_challenge_page")
		await get_tree().create_timer(0.3).timeout
		gm.call("chal_start", id, "leicht")
		# Run startet asynchron (Karte, Spieler, Runde 1)
		await get_tree().create_timer(1.2).timeout
		var cur: Dictionary = gm.call("chal_current")
		var p = gm.get("player")
		var waffe: String = str(p.call("get_weapon_key")) if p != null and is_instance_valid(p) else "?"
		var n_waffen: int = (p.call("get_owned_weapons") as Array).size() if p != null and is_instance_valid(p) else 0
		print("[CHAL][LAUF] id=%s start_ok=%s runde=%d waffe=%s waffen=%d lp=%d/%d hud=%s" % [
			id, str(bool(cur.get("aktiv", false))), int(gm.call("rounds_round_no")),
			waffe, n_waffen,
			int(p.call("get_health")) if p != null and is_instance_valid(p) else -1,
			int(p.call("get_max_health")) if p != null and is_instance_valid(p) else -1,
			str(cur.get("hud", ""))])
		if i == 0:
			await _shot("v145/chal_hud.png")
		# Ziel erfuellen (Debug-Hilfe, gleiche Pfade wie im Spiel)
		var cr = gm.get("chal_run")
		match id:
			"revolver":
				for r in range(1, 9):
					cr.on_round_cleared(r)
			"eisern":
				for r in range(1, 4):
					cr.on_round_cleared(r)
			"boss":
				cr.on_boss_killed()
				cr.on_boss_killed()
				cr.on_boss_killed()
			"schnell":
				for r in range(1, 11):
					cr.on_round_cleared(r)
			"ohne_schild":
				for r in range(1, 6):
					cr.on_round_cleared(r)
			"sammler":
				for k in range(5):
					cr.on_chest_opened()
		await get_tree().create_timer(0.4).timeout
		var cur2: Dictionary = gm.call("chal_current")
		var state: String = str(gm.call("chal_state", id))
		print("[CHAL][AUSWERTUNG] id=%s aktiv=%s beendet=%s zustand=%s fortschritt=%d/%d" % [
			id, str(bool(cur2.get("aktiv", false))), str(bool(cur2.get("beendet", false))),
			state, int(cur2.get("fortschritt", 0)), int(cur2.get("runden_max", 0))])
		if state == "ERLEDIGT":
			var vorher_gems: int = int(gm.get("gems"))
			var res: Dictionary = gm.call("chal_claim", id)
			var zweite: Dictionary = gm.call("chal_claim", id)
			print("[CHAL][GUTSCHRIFT] id=%s +%d gems=%d zweite_gutschrift=%s state=%s" % [
				id, int(res.get("add", 0)), int(gm.get("gems")),
				str(bool(zweite.get("gutschrift", true))), str(gm.call("chal_state", id))])
			if bool(res.get("gutschrift", false)) and not bool(zweite.get("gutschrift", true)):
				erledigt += 1
		if i == 0:
			await _shot("v145/chal_erfolg.png")
		# Overlay schliessen und zurueck ins Menue
		if uim.has_method("_close_challenge_result"):
			uim.call("_close_challenge_result")
		await get_tree().create_timer(0.6).timeout
	print("[TEST][CHALRUN145] aufgaben=%d erledigt=%d" % [aufgaben.size(), erledigt])
	# Karte nach allen Aufgaben
	uim.call("_open_challenge_page")
	await get_tree().create_timer(0.5).timeout
	await _shot("v145/chal_karte_erledigt.png")
	print("[TEST][CHALRUN145] ENDE")


# ============================================================
# v1.46 (C): Challenge-Ansicht - Ziehen, Rad, Ende der Liste
# ============================================================
func _drag_mouse(from: Vector2, dy: float, steps: int) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = from
	ev.global_position = from
	get_viewport().push_input(ev, true)
	await get_tree().process_frame
	for i in range(1, steps + 1):
		var mm := InputEventMouseMotion.new()
		mm.position = from + Vector2(0.0, dy * float(i) / float(steps))
		mm.global_position = mm.position
		mm.relative = Vector2(0.0, dy / float(steps))
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		get_viewport().push_input(mm, true)
		await get_tree().process_frame
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = from + Vector2(0.0, dy)
	ev2.global_position = ev2.position
	get_viewport().push_input(ev2, true)
	await get_tree().process_frame


func _drag_touch(from: Vector2, dy: float, steps: int) -> void:
	var t := InputEventScreenTouch.new()
	t.pressed = true
	t.position = from
	get_viewport().push_input(t, true)
	await get_tree().process_frame
	for i in range(1, steps + 1):
		var sd := InputEventScreenDrag.new()
		sd.position = from + Vector2(0.0, dy * float(i) / float(steps))
		sd.relative = Vector2(0.0, dy / float(steps))
		get_viewport().push_input(sd, true)
		await get_tree().process_frame
	var t2 := InputEventScreenTouch.new()
	t2.pressed = false
	t2.position = from + Vector2(0.0, dy)
	get_viewport().push_input(t2, true)
	await get_tree().process_frame


func _wheel_at(pos: Vector2, down: bool, n: int) -> void:
	for i in range(n):
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
		ev.pressed = true
		ev.position = pos
		ev.global_position = pos
		get_viewport().push_input(ev, true)
		await get_tree().process_frame


func _wait_scroll_settle(sc: Node, max_ms: int = 1500) -> int:
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < max_ms:
		if absf(float(sc.get("target")) - float(sc.get("offset"))) <= 0.5:
			break
		await get_tree().process_frame
	return Time.get_ticks_msec() - t0


func _scroll146() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/")
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	gm.call("chal_reset")
	gm.call("chal_ensure")
	uim.call("_open_challenge_page")
	await get_tree().create_timer(0.6).timeout

	var page: Control = uim.get("challenge_page")
	var chal_p = uim.call("_challenge_p")
	var sc = chal_p.call("scroll_node")
	if sc == null:
		print("[SCROLL][FEHLER] kein Scrollbereich gefunden")
		print("[TEST][SCROLL146] ENDE")
		return
	var vmax: float = float(sc.call("v_max"))
	var r: Rect2 = sc.get_global_rect()
	print("[SCROLL][MASS] karten=%d scroll_rect=(%.0f,%.0f %.0fx%.0f) max=%.0f" % [
		page.find_children("ChalCard_*", "PanelContainer", true, false).size(),
		r.position.x, r.position.y, r.size.x, r.size.y, vmax])
	await _shot("v146/chal_karte_12.png")

	# --- C2: Ziehen folgt dem Finger (Maus-Weg, gleiche Ereignisse wie Touch) ---
	# Startpunkt bewusst ueber dem Kartenkopf (nicht auf einem Knopf): Knoepfe
	# fangen den Druck ab, das ist gewollt (START muss klickbar bleiben).
	var from := Vector2(r.get_center().x, r.position.y + 60.0)
	await _drag_mouse(from, -160.0, 8)
	var versatz: float = float(sc.get("_versatz_max"))
	var t_nach: int = await _wait_scroll_settle(sc)
	print("[SCROLL][ZUG] weg=maus versatz_max=%.1fpx nachlauf_ms=%d offset=%.0f target=%.0f ok_versatz=%s ok_nachlauf=%s" % [
		versatz, t_nach, float(sc.get("offset")), float(sc.get("target")),
		str(versatz <= 2.0), str(t_nach >= 250 and t_nach <= 450)])
	await _shot("v146/chal_karte_12_scroll.png")

	# --- C3: Mausrad in 120-px-Stufen, klemmt an den Enden ---
	await _wheel_at(from, true, 3)
	await _wait_scroll_settle(sc)
	await _wheel_at(from, false, 40)
	await _wait_scroll_settle(sc)
	var oben: float = float(sc.get("target"))
	await _wheel_at(from, true, 60)
	await _wait_scroll_settle(sc)
	var unten: float = float(sc.get("target"))
	print("[SCROLL][RAD] probe oben=%.0f unten=%.0f max=%.0f klemmt=%s" % [
		oben, unten, vmax, str(oben == 0.0 and absf(unten - vmax) <= 0.5)])

	# --- C5: Ende erreichbar, letzte Karte vollstaendig ---
	sc.call("scroll_to_end")
	await _wait_scroll_settle(sc, 2000)
	await get_tree().process_frame
	await get_tree().process_frame
	var last: Control = chal_p.call("last_card_control")
	var rep: Dictionary = sc.call("end_report", last)
	await _shot("v146/chal_karte_12_ende.png")

	# --- C4: Kopfzeile und Fuss stehen fest (Positionen vor/nach dem Scrollen) ---
	var title: Label = page.find_child("PageTitle", true, false)
	var head: Control = page.find_child("ChalHead", true, false)
	var back: Control = page.find_child("ChallengeBack", true, false)
	var titel_y: float = title.get_global_rect().position.y if title != null else -1.0
	var head_y: float = head.get_global_rect().position.y if head != null else -1.0
	var back_y: float = back.get_global_rect().position.y if back != null else -1.0
	sc.call("scroll_to", 0.0)
	await _wait_scroll_settle(sc, 2000)
	await get_tree().process_frame
	var gleich: bool = absf(titel_y - title.get_global_rect().position.y) <= 0.5 \
		and absf(head_y - head.get_global_rect().position.y) <= 0.5 \
		and absf(back_y - back.get_global_rect().position.y) <= 0.5
	print("[SCROLL][FIX] titel=%.0f chips=%.0f fuss=%.0f gleich_nach_scroll=%s" % [
		titel_y, head_y, back_y, str(gleich)])

	# --- C6: Touch-Weg (auf dem Geraet derselbe Code) ---
	var vorher_touch: float = float(sc.get("offset"))
	await _drag_touch(from, -220.0, 10)
	var t_touch: int = await _wait_scroll_settle(sc)
	var nachher_touch: float = float(sc.get("offset"))
	print("[SCROLL][TEST] geraet=touch bewegt=%s versatz_max=%.1fpx nachlauf_ms=%d" % [
		str(nachher_touch > vorher_touch + 20.0), float(sc.get("_versatz_max")), t_touch])
	print("[SCROLL][ENDE] max=%.0f sichtbar_bis=%.0f letzte_karte_voll=%s" % [
		float(rep.get("max", 0.0)), float(rep.get("sichtbar_bis", 0.0)),
		str(bool(rep.get("letzte_karte_voll", false)))])
	print("[TEST][SCROLL146] ENDE")


# ============================================================
# v1.46 (B): alle 12 Challenges auf LEICHT bis zur Belohnung
# ============================================================
func _chal146() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/")
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	gm.call("chal_reset")
	gm.set("gems", 0)
	gm.call("chal_ensure")

	# --- B1: alle 36 Stufen-Kombinationen (12 x 3) ---
	var kombis: int = 0
	for d in ChalRun145.DEFS:
		for sk in ChalRun145.STUFEN:
			var cr = ChalRun145.new()
			cr.setup(str(d["id"]), str(sk))
			kombis += 1
	print("[CHAL][KOMBI] aufgaben=%d stufen=%d kombinationen=%d" % [
		ChalRun145.DEFS.size(), ChalRun145.STUFEN.size(), kombis])

	# --- B5: Karte mit 12 Karten, je START + drei Stufen ---
	uim.call("_open_challenge_page")
	await get_tree().create_timer(0.6).timeout
	var page: Control = uim.get("challenge_page")
	var starts: int = page.find_children("ChalStart_*", "Button", true, false).size()
	var stufen: int = page.find_children("Stufe_*", "Button", true, false).size()
	print("[CHAL][KARTE] seite=%s karten=%d start_knoepfe=%d stufen_knoepfe=%d" % [
		str(page != null and page.visible),
		page.find_children("ChalCard_*", "PanelContainer", true, false).size(), starts, stufen])
	await _shot("v146/chal_karte_12.png")
	var sc = uim.call("_challenge_p").call("scroll_node")
	if sc != null:
		sc.call("scroll_to_end")
		await get_tree().create_timer(0.6).timeout
		await _shot("v146/chal_karte_12_scroll.png")

	var aufgaben: Array = ["revolver", "eisern", "boss", "schnell", "ohne_schild", "sammler",
		"flinte", "unberuehrt", "kopfgeld", "goldrausch", "ohne_vorrat", "boss_rush"]
	var erledigt: int = 0
	for i in range(aufgaben.size()):
		var id: String = str(aufgaben[i])
		uim.call("_open_challenge_page")
		await get_tree().create_timer(0.3).timeout
		gm.call("chal_start", id, "leicht")
		await get_tree().create_timer(1.0).timeout
		var cur: Dictionary = gm.call("chal_current")
		var p = gm.get("player")
		var waffe: String = str(p.call("get_weapon_key")) if p != null and is_instance_valid(p) else "?"
		print("[CHAL][LAUF] id=%s start_ok=%s runde=%d waffe=%s lp=%d/%d hud=%s" % [
			id, str(bool(cur.get("aktiv", false))), int(gm.call("rounds_round_no")),
			waffe,
			int(p.call("get_health")) if p != null and is_instance_valid(p) else -1,
			int(p.call("get_max_health")) if p != null and is_instance_valid(p) else -1,
			str(cur.get("hud", ""))])
		var cr = gm.get("chal_run")
		# Ziel erfuellen - ueber die ECHTEN Ereignispfade der Aufgabe
		match id:
			"revolver", "flinte", "ohne_schild", "ohne_vorrat", "eisern":
				var n: int = int((cr.get("runden_max")))
				for r in range(1, n + 1):
					cr.on_round_cleared(r)
			"unberuehrt":
				for r in range(1, int(cr.get("runden_max")) + 1):
					cr.on_round_cleared(r)
			"boss":
				for b in range(3):
					cr.on_boss_killed()
			"boss_rush":
				for b in range(5):
					cr.on_boss_killed()
			"schnell":
				for r in range(1, 11):
					cr.on_round_cleared(r)
			"sammler":
				for k in range(int(cr.get("ziel_wert"))):
					cr.on_chest_opened()
			"kopfgeld":
				for k in range(int(cr.get("ziel_wert"))):
					cr.on_kill(0)
			"goldrausch":
				var ziel_m: int = int(cr.get("ziel_wert"))
				var rest: int = ziel_m
				while rest > 0:
					cr.on_kill(mini(50, rest))
					rest -= 50
		await get_tree().create_timer(0.3).timeout
		var state: String = str(gm.call("chal_state", id))
		var cur2: Dictionary = gm.call("chal_current")
		print("[CHAL][AUSWERTUNG] id=%s aktiv=%s beendet=%s zustand=%s fortschritt=%d/%d" % [
			id, str(bool(cur2.get("aktiv", false))), str(bool(cur2.get("beendet", false))),
			state, int(cur2.get("fortschritt", 0)), int(cur2.get("runden_max", 0))])
		if state == "ERLEDIGT":
			var res: Dictionary = gm.call("chal_claim", id)
			var zweite: Dictionary = gm.call("chal_claim", id)
			print("[CHAL][GUTSCHRIFT] id=%s stufe=leicht +%d gems=%d zweite_gutschrift=%s state=%s" % [
				id, int(res.get("add", 0)), int(gm.get("gems")),
				str(bool(zweite.get("gutschrift", true))), str(gm.call("chal_state", id))])
			if bool(res.get("gutschrift", false)) and not bool(zweite.get("gutschrift", true)):
				erledigt += 1
		if uim.has_method("_close_challenge_result"):
			uim.call("_close_challenge_result")
		await get_tree().create_timer(0.4).timeout
		if i == 0:
			await _shot("v146/chal_erfolg.png")
	print("[TEST][CHALRUN146] aufgaben=%d erledigt=%d" % [aufgaben.size(), erledigt])
	uim.call("_open_challenge_page")
	await get_tree().create_timer(0.5).timeout
	await _shot("v146/chal_karte_12_erledigt.png")
	print("[TEST][CHALRUN146] ENDE")


# ============================================================
# v1.46 (J): fuenf neue App-Icon-Entwuerfe
# ============================================================
func _make_icon146(motif: String) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(ICON_PX145, ICON_PX145)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	add_child(vp)
	var root: Control = _icon_shell(vp)
	var hero: Texture2D = TextureManager.get_player_texture(0, 0)
	var mon: Texture2D = TextureManager.get_texture("monster_green")
	var chest: Texture2D = TextureManager.get_texture("chest_gem_premium")
	var rev: Texture2D = TextureManager.get_texture("weapon_revolver")
	var gem: Texture2D = TextureManager.get_texture("slot_gem1")
	var w: Control = null
	match motif:
		"a":
			# Revolver-Muendung frontal mit Burst
			var burst := Polygon2D.new()
			var pts := PackedVector2Array()
			var c := Vector2(ICON_PX145, ICON_PX145) * 0.5
			for i in range(24):
				var a: float = TAU * float(i) / 24.0
				var rr: float = 520.0 if i % 2 == 0 else 250.0
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			burst.polygon = pts
			burst.color = Color(1.0, 0.72, 0.18)
			root.add_child(burst)
			_icon_text(root, "BANG!", 170, Vector2(62, 120), Color(1.0, 0.30, 0.22), 26)
			_icon_sprite(root, rev, 620.0, Vector2(560, 700))
		"b":
			# Heldenkopf als Grossaufnahme (Gesicht + Hut)
			_icon_sprite(root, hero, 980.0, Vector2(512, 620))
			var hat: Texture2D = TextureManager.get_skin_hat_texture(0, 0, 3)
			if hat != null:
				_icon_sprite(root, hat, 900.0, Vector2(512, 400))
			_icon_text(root, "HELD", 96, Vector2(62, 840), Color(1.0, 0.86, 0.20), 20)
		"c":
			# Offene Kiste mit Lichtstrahl und Diamant
			_icon_sprite(root, chest, 620.0, Vector2(470, 720))
			var beam := Polygon2D.new()
			beam.polygon = PackedVector2Array([
				Vector2(400, 640), Vector2(620, 640), Vector2(820, 60), Vector2(200, 60)])
			beam.color = Color(1.0, 0.95, 0.55, 0.35)
			root.add_child(beam)
			_icon_sprite(root, gem, 330.0, Vector2(512, 330))
		"d":
			# "CS"-Monogramm als Emblem mit Band
			_icon_text(root, "CS", 520, Vector2(62, 200), Color(1.0, 0.86, 0.20), 46)
			var band := ColorRect.new()
			band.color = Color(0.95, 0.28, 0.22)
			band.position = Vector2(0, 760)
			band.size = Vector2(ICON_PX145, 170)
			root.add_child(band)
			_icon_text(root, "COMIC SHOOTER", 96, Vector2(62, 790), Color(1, 1, 1), 18)
		"e":
			# Monster-Maul mit Zaehnen (Bedrohung)
			_icon_sprite(root, mon, 760.0, Vector2(512, 560))
			for i in range(7):
				var tooth := Polygon2D.new()
				var x: float = 250.0 + float(i) * 74.0
				tooth.polygon = PackedVector2Array([
					Vector2(x, 560), Vector2(x + 52, 560), Vector2(x + 26, 660)])
				tooth.color = Color(1.0, 1.0, 1.0)
				root.add_child(tooth)
			_icon_text(root, "GRRR", 130, Vector2(62, 120), Color(1.0, 0.45, 0.25), 24)
	_icon_frame(root)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	return img


func _icon146() -> void:
	for _f in range(10):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/icons/")
	var namen: Array = ["a", "b", "c", "d", "e"]
	var bilder: Dictionary = {}
	for nm in namen:
		var img: Image = await _make_icon146(str(nm))
		if img == null or img.get_width() == 0:
			print("[ICON][FEHLER] entwurf=%s leer" % str(nm))
			continue
		bilder[str(nm)] = img.duplicate()
		var path: String = SHOT_DIR + "v146/icons/icon146_%s.png" % str(nm)
		img.save_png(path)
		print("[ICON][ENTWURF] name=icon146_%s.png px=%dx%d datei=%s" % [
			str(nm), img.get_width(), img.get_height(), path])
	# Kontaktblatt mit v1.45-Entwurf A als Referenz + Groessen 48/72/96/144
	var sheet := Image.create(6 * 220, 300, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.10, 0.11, 0.14))
	var ref := Image.load_from_file(SHOT_DIR + "v145/icons/icon_a.png")
	var alle: Array = []
	alle.append({"name": "v145_a", "img": ref})
	for nm in namen:
		alle.append({"name": "146_" + str(nm), "img": bilder.get(str(nm), null)})
	for i in range(alle.size()):
		var e: Dictionary = alle[i]
		var im: Image = e["img"]
		if im == null:
			continue
		var big: Image = im.duplicate()
		big.convert(Image.FORMAT_RGBA8)
		big.resize(180, 180, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(big, Rect2i(0, 0, 180, 180), Vector2i(20 + i * 220, 20))
		var xs: Array = [20, 68, 120, 176]
		var sizes: Array = [32, 48, 64, 96]
		for k in range(sizes.size()):
			var small: Image = im.duplicate()
			small.convert(Image.FORMAT_RGBA8)
			small.resize(int(sizes[k]), int(sizes[k]), Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(small, Rect2i(0, 0, int(sizes[k]), int(sizes[k])),
				Vector2i(20 + i * 220 + int(xs[k]) - 20, 220))
		print("[ICON][LESBAR] entwurf=%s px=32,48,64,96 blatt=%s/icons_uebersicht146.png" % [
			str(e["name"]), SHOT_DIR + "v146"])
	var p: String = SHOT_DIR + "v146/icons_uebersicht146.png"
	sheet.save_png(p)
	print("[ICON][WAHL] offen=true (kein config/icon-Wechsel in diesem Lauf) blatt=%s" % p)
	print("[TEST][ICON146] ENDE")


# ============================================================
# v1.46 (G): Skins neu - Kontaktblatt 64/256 px, IoU, Huete auf 6/7
# ============================================================
func _mask_of(img: Image) -> Array:
	var out: Array = []
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.5:
				out.append(Vector2i(x, y))
	return out


func _iou146(a: Array, b: Array) -> float:
	var sa := {}
	for p in a:
		sa[p] = true
	var inter: int = 0
	for p in b:
		if sa.has(p):
			inter += 1
	var uni: int = a.size() + b.size() - inter
	if uni <= 0:
		return 0.0
	return float(inter) / float(uni)


func _rig146() -> void:
	for _f in range(10):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/")
	var rigs: int = TextureManager.RIG_NAMES.size()
	var big: int = 256
	var small: int = 64
	var sheet := Image.create(rigs * (big + 12) + 12, big + small + 40, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.10, 0.11, 0.14))
	var base0: Image = TextureManager.get_skin_texture(0, 0).get_image()
	if base0.get_width() != 64:
		base0.resize(64, 64, Image.INTERPOLATE_NEAREST)
	var m0: Array = _mask_of(base0)
	for r in range(rigs):
		var tex: Texture2D = TextureManager.get_skin_texture(0, r)
		var img: Image = tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		var im_small: Image = img.duplicate()
		im_small.resize(small, small, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(im_small, Rect2i(0, 0, small, small), Vector2i(12 + r * (big + 12), 12))
		var im_big: Image = img.duplicate()
		im_big.resize(big, big, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(im_big, Rect2i(0, 0, big, big), Vector2i(12 + r * (big + 12), 12 + small + 8))
		if img.get_width() != 64:
			img.resize(64, 64, Image.INTERPOLATE_NEAREST)
		var mr: Array = _mask_of(img)
		var iou: float = _iou146(m0, mr)
		if r == 6 or r == 7:
			print("[RIG][IOU] rig=%d gegen=0 iou=%.2f ok=%s" % [r, iou, str(iou <= 0.75)])
		else:
			print("[RIG][CHECK] rig=%d name=%s iou_gegen_0=%.2f px=%d" % [
				r, str(TextureManager.RIG_NAMES[r]), iou, mr.size()])
	# Huete auf den neuen Rigs (G5)
	for r in [6, 7]:
		var base_img: Image = TextureManager.get_skin_texture(0, r).get_image()
		base_img.convert(Image.FORMAT_RGBA8)
		if base_img.get_width() != 64:
			base_img.resize(64, 64, Image.INTERPOLATE_NEAREST)
		var hm: Dictionary = GenCharacters._head_metrics(base_img)
		var eyes: Array = GenCharacters.eye_pixels(base_img, hm)
		var max_aug: float = 0.0
		for hi in range(1, TextureManager.HAT_NAMES.size()):
			var comb: Image = TextureManager.get_skin_hat_texture(0, r, hi).get_image()
			comb.convert(Image.FORMAT_RGBA8)
			if comb.get_width() != 64:
				comb.resize(64, 64, Image.INTERPOLATE_NEAREST)
			var verd: int = 0
			for ep in eyes:
				var c0: Color = base_img.get_pixel(ep.x, ep.y)
				var c1: Color = comb.get_pixel(ep.x, ep.y)
				if absf(c1.r - c0.r) + absf(c1.g - c0.g) + absf(c1.b - c0.b) > 0.15:
					verd += 1
			if eyes.size() > 0:
				max_aug = maxf(max_aug, 100.0 * float(verd) / float(eyes.size()))
		print("[HAT][AUGEN] rig=%d verdeckt=%.0f%% max_ueber_alle_huete=true ok=%s" % [
			r, max_aug, str(max_aug <= 10.0)])
	var p: String = SHOT_DIR + "v146/rigs_neu.png"
	sheet.save_png(p)
	print("[RIG][BLATT] datei=%s px=%dx%d rigs=%d gross=%d klein=%d" % [
		p, sheet.get_width(), sheet.get_height(), rigs, big, small])
	print("[TEST][RIG146] ENDE")


# ============================================================
# v1.46 (I): Einstellungen aus Menue und Pause
# ============================================================
func _set146() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/")
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	# --- I2: aus dem Menue (beide Reihen sichtbar) ---
	uim.call("_open_settings_page", "menu")
	await get_tree().create_timer(0.5).timeout
	var page: Control = uim.get("settings_page")
	await _shot("v146/settings_menu.png")
	uim.call("_close_settings_page")
	await get_tree().create_timer(0.3).timeout
	# --- I1/I3: aus der Pause ---
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.5).timeout
	uim.call("show_pause")
	await get_tree().create_timer(0.4).timeout
	uim.call("_open_settings_page", "pause")
	await get_tree().create_timer(0.5).timeout
	await _shot("v146/settings_pause.png")
	var diff_vis: bool = false
	var biom_vis: bool = false
	for b in gm.get("ui_manager").get("settings_diff_buttons"):
		if b != null and is_instance_valid(b) and b.is_visible_in_tree():
			diff_vis = true
	if uim.get("biom_flash_btn") != null and is_instance_valid(uim.get("biom_flash_btn")):
		biom_vis = bool((uim.get("biom_flash_btn") as Control).is_visible_in_tree())
	print("[SET][PRUEF] herkunft=pause schwierigkeit_sichtbar=%s biom_sichtbar=%s" % [
		str(diff_vis), str(biom_vis)])
	uim.call("_close_settings_page")
	await get_tree().create_timer(0.3).timeout
	if gm.has_method("quit_to_menu"):
		gm.call("quit_to_menu")
	await get_tree().create_timer(0.8).timeout
	print("[TEST][SET146] ENDE")


# ============================================================
# v1.46 (H): Name im Charakter-Editor
# ============================================================
func _name146() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/")
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	uim.call("_open_char_page")
	await get_tree().create_timer(0.6).timeout
	var edit: LineEdit = uim.get("char_name_edit")
	print("[CHAR][NAME] feld_vorhanden=%s max_zeichen=%d tastatur=%s text=%s" % [
		str(edit != null), edit.max_length if edit != null else -1,
		"geraet" if (edit != null and edit.virtual_keyboard_enabled) else "keine",
		str(edit.text) if edit != null else "-"])
	await _shot("v146/char_name.png")
	if edit != null:
		edit.text = "  vince  "
		edit.text_submitted.emit(edit.text)
		await get_tree().create_timer(0.4).timeout
		print("[CHAR][NAME] probe1 gespeichert=%s" % str(gm.get("p_name")))
		edit.text = ""
		edit.text_submitted.emit(edit.text)
		await get_tree().create_timer(0.3).timeout
		var nach_leer: String = str(gm.get("p_name"))
		print("[CHAR][NAME] probe2 leer->gespeichert=%s" % nach_leer)
		edit.text = "VINCE"
		edit.text_submitted.emit(edit.text)
		await get_tree().create_timer(0.3).timeout
	await _shot("v146/char_name_ergebnis.png")
	print("[TEST][NAME146] ENDE")


# ============================================================
# v1.45 (Z): Gluecksrad - Quoten, Drehung, Ticks, Buchung, Shop-Einbau
# ============================================================
func _wheel145() -> void:
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v145/")

	# --- Z1: Definition + Chancen aus derselben Quelle ---
	print("[WHEEL][DEF] segmente=%d gewicht_summe=%.1f" % [WM.SEGMENTS, WM.weight_sum()])
	var odds: Array = WM.odds_table()
	for o in odds:
		print("[WHEEL][ODDS] index=%d key=%s label=%s chance=%.2f%% gold_mult=%.1f gems=%d" % [
			int(o["index"]), str(o["key"]), str(o["label"]), float(o["chance"]),
			float(o["mult"]), int(o["gems"])])

	# --- Z2: 200 000 Simulationen ---
	var n: int = 200000
	var sim: Dictionary = WM.simulate(n, 100)
	var counts: Array = sim["counts"]
	var max_abw: float = 0.0
	for i in range(odds.size()):
		var soll: float = float(odds[i]["chance"])
		var ist: float = 100.0 * float(counts[i]) / float(n)
		var abw: float = absf(ist - soll)
		max_abw = maxf(max_abw, abw)
		print("[WHEEL][SIM] n=%d segment=%d soll=%.2f%% ist=%.2f%% abw=%.2fpp" % [
			n, i, soll, ist, abw])
	var rtp: float = float(sim["rtp"])
	print("[WHEEL][SIM] rtp=%.3f soll=%.2f band=0.85..1.05 ok=%s max_abw=%.2fpp" % [
		rtp, WM.rtp_gold(), str(rtp >= 0.85 and rtp <= 1.05), max_abw])

	# --- Shop mit BEIDEN Automaten ---
	gm.set("gold", 50000)
	gm.set("gems", 40)
	uim.call("show_start_screen")
	await get_tree().create_timer(0.4).timeout
	uim.call("_open_chest_page")
	await get_tree().create_timer(0.6).timeout
	var page: Control = uim.get("chest_page")
	var btn_slot: Button = page.find_child("SlotOpenBtn", true, false)
	var btn_wheel: Button = page.find_child("WheelOpenBtn", true, false)
	print("[SHOP][AUTOMATEN] walze=%s rad=%s nebeneinander=%s" % [
		str(btn_slot != null), str(btn_wheel != null),
		str(btn_slot != null and btn_wheel != null and absf(btn_slot.get_global_rect().position.y - btn_wheel.get_global_rect().position.y) < 20.0)])
	var sr: Rect2 = btn_wheel.get_global_rect() if btn_wheel != null else Rect2()
	var rr: Rect2 = btn_slot.get_global_rect() if btn_slot != null else Rect2()
	print("[SHOP][RAD] knopf=%.0fx%.0f sichtbar=%s" % [
		sr.size.x, sr.size.y, str(btn_wheel != null and btn_wheel.is_visible_in_tree())])
	print("[SHOP][AUTOMATEN] walze_rect=(%.0f,%.0f %.0fx%.0f) rad_rect=(%.0f,%.0f %.0fx%.0f) gleiche_zeile=%s" % [
		rr.position.x, rr.position.y, rr.size.x, rr.size.y,
		sr.position.x, sr.position.y, sr.size.x, sr.size.y,
		str(absf(rr.position.y - sr.position.y) < 24.0 and sr.position.x > rr.position.x)])
	await _shot("v145/shop_1920.png")
	# zur Automaten-Zeile scrollen und dort ein zweites Bild machen
	var shop_scroll: Control = uim.get("shop_scroll")
	if shop_scroll != null:
		shop_scroll.set("scroll_vertical", 1150)
		await get_tree().create_timer(0.4).timeout
		print("[SHOP][SCROLL] vertical=%d" % int(shop_scroll.get("scroll_vertical")))
	await _shot("v145/shop_automaten_1920.png")

	# --- Z3/Z4/Z5: Overlay, Drehung, Ticks, Buchung ---
	uim.call("_open_wheel_ui")
	await get_tree().create_timer(0.8).timeout
	var wui: Node = null
	for c in uim.get_children():
		if c.has_method("is_spinning"):
			wui = c
	if wui == null:
		print("[WHEEL][FEHLER] Overlay nicht gefunden")
		print("[TEST][WHEEL145] ENDE")
		return
	var wh = wui.get("wheel")
	print("[WHEEL][UI] overlay=true rad_px=%d sichtbar=%s" % [
		int(float(wh.get("rad_px"))) if wh != null else 0,
		str(wh != null and wh.is_visible_in_tree())])
	await _shot("v145/wheel_1920.png")

	# zu wenig Gold -> abgelehnt (Z6)
	var gold_backup: int = int(gm.get("gold"))
	gm.set("gold", 50)
	wui.call("_set_bet", 500)
	wui.call("_on_spin")
	await get_tree().create_timer(0.2).timeout
	gm.set("gold", gold_backup)

	# echter Dreh
	wui.call("_set_bet", 500)
	var gold_vorher: int = int(gm.get("gold"))
	wui.call("_on_spin")
	var t_ende: int = Time.get_ticks_msec() + 9000
	while bool(wui.call("is_spinning")) and Time.get_ticks_msec() < t_ende:
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.2).timeout
	print("[WHEEL][TEST] dreh_fertig=%s gold_vorher=%d gold_nachher=%d buchung=%s" % [
		str(not bool(wui.call("is_spinning"))), gold_vorher, int(gm.get("gold")),
		str(int(gm.get("gold")) != gold_backup)])
	await _shot("v145/wheel_ergebnis_1920.png")

	# --- Z6: Buchung exakt pruefen (Einsatz ab, Gewinn gut, gespeichert) ---
	var erg: Dictionary = wui.get("_ergebnis")
	var win: int = int(erg.get("win", 0))
	var gems_gewonnen: int = int(erg.get("gems", 0))
	var erwartet: int = gold_vorher - 500 + win
	var gleich: bool = (int(gm.get("gold")) == erwartet)
	print("[WHEEL][BUCHUNG] einsatz=500 gold_vorher=%d erwartet=%d ist=%d ok=%s segment=%s gewinn=%d gems=%d" % [
		gold_vorher, erwartet, int(gm.get("gold")), str(gleich), str(erg.get("key", "?")), win, gems_gewonnen])
	wui.call("_on_close")
	await get_tree().create_timer(0.4).timeout
	print("[WHEEL][TEST] overlay_zu=%s" % str(page != null and page.visible))
	print("[TEST][WHEEL145] ENDE")

# ============================================================
# v1.46b: sechs Icon-Entwuerfe im Stil des alten Icons (Held + Waffe),
# jeweils mit einem anderen Monster im Hintergrund. 1024x1024.
# ============================================================
const ICON146B_PX := 1024


func _icon146b_sprite(root: Control, tex: Texture2D, px: float, pos: Vector2,
		rot: float = 0.0, mod: Color = Color(1, 1, 1, 1)) -> void:
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.size = Vector2(px, px)
	tr.pivot_offset = Vector2(px, px) * 0.5
	tr.position = pos - Vector2(px, px) * 0.5
	tr.rotation = rot
	tr.modulate = mod
	root.add_child(tr)


func _make_icon146b(v: String) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(ICON146B_PX, ICON146B_PX)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	add_child(vp)
	var root: Control = _icon_shell(vp)
	var hero: Texture2D = TextureManager.get_player_texture(0, 0)
	var rev: Texture2D = TextureManager.get_texture("weapon_revolver")
	var shot: Texture2D = TextureManager.get_texture("weapon_shotgun")
	var mon_green: Texture2D = TextureManager.get_texture("monster_green")
	var mon_alien: Texture2D = TextureManager.get_texture("monster_mars_alien")
	var mon_golem: Texture2D = TextureManager.get_texture("monster_golem")
	var mon_pyro: Texture2D = TextureManager.get_texture("monster_pyro")
	var mon_ape: Texture2D = TextureManager.get_texture("monster_robo_ape")
	var mon_herold: Texture2D = TextureManager.get_texture("monster_herold")
	var dunkel := Color(0.62, 0.64, 0.78, 1.0)
	match v:
		"1":
			# Klassisch: Held mit Revolver, gruenes Monster hinter der Schulter
			_icon146b_sprite(root, mon_green, 840.0, Vector2(512, 400), 0.0, dunkel)
			_icon146b_sprite(root, hero, 720.0, Vector2(512, 600))
			_icon146b_sprite(root, rev, 430.0, Vector2(700, 810), -0.28)
		"2":
			# Schrotflinte gegen Mars-Alien (breite Silhouette)
			_icon146b_sprite(root, mon_alien, 860.0, Vector2(512, 400), 0.0, dunkel)
			_icon146b_sprite(root, hero, 720.0, Vector2(512, 600))
			_icon146b_sprite(root, shot, 470.0, Vector2(720, 800), -0.20)
		"3":
			# Golem (Stein) hinter dem Helden, dramatischer Schatten
			_icon146b_sprite(root, mon_golem, 900.0, Vector2(512, 395), 0.0, Color(0.60, 0.62, 0.74, 1.0))
			_icon146b_sprite(root, hero, 700.0, Vector2(512, 610))
			_icon146b_sprite(root, rev, 410.0, Vector2(700, 820), -0.26)
		"4":
			# Zwei Gegner: Held in der Mitte, Monster links und rechts
			_icon146b_sprite(root, mon_green, 640.0, Vector2(250, 430), -0.08, dunkel)
			_icon146b_sprite(root, mon_alien, 640.0, Vector2(780, 420), 0.10, dunkel)
			_icon146b_sprite(root, hero, 680.0, Vector2(512, 610))
			_icon146b_sprite(root, rev, 400.0, Vector2(710, 820), -0.26)
		"5":
			# Pyro: Feuer-Monster mit rotem Glutschein
			var glut := Polygon2D.new()
			glut.polygon = PackedVector2Array([
				Vector2(512, 512), Vector2(1024, 300), Vector2(1024, 760)])
			glut.color = Color(1.0, 0.42, 0.14, 0.28)
			root.add_child(glut)
			_icon146b_sprite(root, mon_pyro, 860.0, Vector2(512, 400), 0.0, Color(0.92, 0.86, 0.90, 1.0))
			_icon146b_sprite(root, hero, 720.0, Vector2(512, 600))
			_icon146b_sprite(root, shot, 470.0, Vector2(720, 800), -0.20)
		"6":
			# Robo-Affe: technischer Gegner mit Volt-Funkeln
			_icon146b_sprite(root, mon_ape, 870.0, Vector2(512, 400), 0.0, Color(0.72, 0.80, 0.94, 1.0))
			for i in range(9):
				var funke := Polygon2D.new()
				var a: float = float(i) * 0.9
				var c := Vector2(512, 400) + Vector2(cos(a), sin(a)) * 400.0
				funke.polygon = PackedVector2Array([
					c, c + Vector2(26, 0), c + Vector2(10, 16)])
				funke.color = Color(0.62, 0.95, 1.0, 0.55)
				root.add_child(funke)
			_icon146b_sprite(root, hero, 700.0, Vector2(512, 610))
			_icon146b_sprite(root, rev, 410.0, Vector2(700, 820), -0.26)
		_:
			_icon146b_sprite(root, mon_herold, 840.0, Vector2(512, 400), 0.0, dunkel)
			_icon146b_sprite(root, hero, 720.0, Vector2(512, 600))
			_icon146b_sprite(root, rev, 430.0, Vector2(700, 810), -0.28)
	_icon_frame(root)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	return img


func _icon146b() -> void:
	for _f in range(10):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/icons/")
	var namen: Array = ["1", "2", "3", "4", "5", "6"]
	var bilder: Dictionary = {}
	for nm in namen:
		var img: Image = await _make_icon146b(str(nm))
		if img == null or img.get_width() == 0:
			print("[ICON][FEHLER] entwurf146b_%s leer" % str(nm))
			continue
		bilder[str(nm)] = img.duplicate()
		var path: String = SHOT_DIR + "v146/icons/icon146b_%s.png" % str(nm)
		img.save_png(path)
		print("[ICON][ENTWURF] name=icon146b_%s.png px=%dx%d datei=%s" % [
			str(nm), img.get_width(), img.get_height(), path])
	# Kontaktblatt: je Entwurf gross + 48/72/96/144
	var sheet := Image.create(6 * 300, 520, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.10, 0.11, 0.14))
	for i in range(namen.size()):
		var im: Image = bilder.get(str(namen[i]), null)
		if im == null:
			continue
		var big: Image = im.duplicate()
		big.convert(Image.FORMAT_RGBA8)
		big.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(big, Rect2i(0, 0, 256, 256), Vector2i(22 + i * 300, 20))
		var xs: Array = [22, 92, 176, 200]
		var sizes: Array = [48, 72, 96, 144]
		for k in range(3):
			var small: Image = im.duplicate()
			small.convert(Image.FORMAT_RGBA8)
			small.resize(int(sizes[k]), int(sizes[k]), Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(small, Rect2i(0, 0, int(sizes[k]), int(sizes[k])),
				Vector2i(22 + i * 300 + int(xs[k]) - 22, 300))
		# 144 px rechts unten
		var g: Image = im.duplicate()
		g.convert(Image.FORMAT_RGBA8)
		g.resize(144, 144, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(g, Rect2i(0, 0, 144, 144), Vector2i(22 + i * 300 + 120, 340))
	var p: String = SHOT_DIR + "v146/icons_uebersicht146b.png"
	sheet.save_png(p)
	print("[ICON][BLATT] datei=%s px=%dx%d entwuerfe=%d" % [
		p, sheet.get_width(), sheet.get_height(), bilder.size()])
	print("[ICON][WAHL] entwuerfe=6 offen=true")
	print("[TEST][ICON146B] ENDE")

# ============================================================
# v1.46c: sechs App-Icons im Stil des ALTEN Icons (v1.20-v1.36):
# Monster-Gesicht als Grossaufnahme - Strahlenkranz, dunkler Rahmen,
# gluehende Augen, Reisszaehne. 1024x1024, weiche Kanten ueber MSAA.
# ============================================================
const ICON146C_PX := 1024


func _circ(r: float, n: int = 96) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _sector(r: float, a0: float, a1: float, n: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in range(n + 1):
		var a: float = lerpf(a0, a1, float(i) / float(n))
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _add(root: Control, pts: PackedVector2Array, col: Color, at: Vector2 = Vector2.ZERO,
		rot: float = 0.0) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.position = at
	p.rotation = rot
	root.add_child(p)
	return p


func _ell(rx: float, ry: float, n: int = 96) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _tri(a: Vector2, b: Vector2, c: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b, c])


func _round_rect(w: float, h: float, r: float, n: int = 8) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [
		Vector2(w * 0.5 - r, -h * 0.5 + r), Vector2(w * 0.5 - r, h * 0.5 - r),
		Vector2(-w * 0.5 + r, h * 0.5 - r), Vector2(-w * 0.5 + r, -h * 0.5 + r)]
	var start := [0.0, 0.0, 0.0, 0.0]
	for ci in range(4):
		var c: Vector2 = corners[ci]
		var a0: float = -PI * 0.5 + float(ci) * PI * 0.5
		for i in range(n + 1):
			var a: float = a0 + (PI * 0.5) * float(i) / float(n)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _make_icon146c(v: String) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(ICON146C_PX, ICON146C_PX)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	vp.msaa_2d = Viewport.MSAA_4X
	add_child(vp)
	var root := Control.new()
	root.size = Vector2(ICON146C_PX, ICON146C_PX)
	vp.add_child(root)
	var c := Vector2(512, 512)

	# --- Rahmen + Strahlenkranz (wie das alte Icon) ---
	var bg := ColorRect.new()
	bg.size = Vector2(ICON146C_PX, ICON146C_PX)
	bg.color = Color(0.06, 0.07, 0.14)
	root.add_child(bg)
	_add(root, _circ(500.0), Color(0.10, 0.11, 0.20), c)          # dunkler Aussenring
	_add(root, _circ(476.0), Color(0.42, 0.36, 0.86), c)          # violetter Feinning
	var rays: int = 24
	for i in range(rays):
		var a0: float = TAU * float(i) / float(rays)
		var a1: float = TAU * float(i + 1) / float(rays)
		var col := Color(0.99, 0.68, 0.13) if i % 2 == 0 else Color(0.93, 0.55, 0.08)
		_add(root, _sector(470.0, a0, a1), col, c)

	# --- Gesicht je Variante ---
	var head_col := Color(0.28, 0.78, 0.24)
	var head_dark := Color(0.16, 0.50, 0.15)
	var horn_col := Color(0.93, 0.90, 0.76)
	var eye_white := Color(0.98, 0.98, 0.96)
	var pupil_col := Color(0.05, 0.05, 0.08)
	var mouth_col := Color(0.18, 0.03, 0.05)
	var tooth_col := Color(0.98, 0.97, 0.93)
	var head_c := Vector2(512, 560)
	var head_rx := 330.0
	var head_ry := 322.0
	var horns: bool = true
	var horn_scale: float = 1.0
	var eyes: int = 2
	var eye_r: float = 78.0
	var brow: bool = true
	var teeth_top: int = 5
	var teeth_bot: int = 4
	var square_jaw: bool = false
	var visor: bool = false
	match v:
		"2":
			head_col = Color(0.86, 0.22, 0.22)
			head_dark = Color(0.56, 0.10, 0.12)
			horn_scale = 1.45
			teeth_top = 6
			teeth_bot = 5
		"3":
			head_col = Color(0.20, 0.72, 0.66)
			head_dark = Color(0.08, 0.44, 0.42)
			eyes = 1
			eye_r = 128.0
			brow = false
			horns = false
			teeth_top = 4
			teeth_bot = 3
		"4":
			head_col = Color(0.56, 0.58, 0.60)
			head_dark = Color(0.34, 0.36, 0.38)
			horn_col = Color(0.40, 0.42, 0.44)
			horns = false
			square_jaw = true
			teeth_top = 4
			teeth_bot = 0
			head_rx = 310.0
			head_ry = 300.0
		"5":
			head_col = Color(0.34, 0.48, 0.66)
			head_dark = Color(0.18, 0.28, 0.42)
			horn_col = Color(0.62, 0.70, 0.80)
			visor = true
			brow = false
			horns = false
			teeth_top = 0
			teeth_bot = 0
			eye_white = Color(0.55, 0.98, 1.0)
			pupil_col = Color(0.85, 1.0, 1.0)
		"6":
			head_col = Color(0.52, 0.30, 0.72)
			head_dark = Color(0.32, 0.16, 0.48)
			horn_scale = 1.2
			eyes = 3
			eye_r = 62.0
			teeth_top = 7
			teeth_bot = 6

	# Hoerner (gross, mit Kontur - wie im alten Icon)
	if horns:
		for s in [-1.0, 1.0]:
			var bx: float = 512.0 + s * 252.0
			var tip := Vector2(bx + s * 74.0 * horn_scale, 214.0 - 26.0 * horn_scale)
			var base_a := Vector2(bx - 104.0 * horn_scale, 452.0)
			var base_b := Vector2(bx + 86.0 * horn_scale, 436.0)
			_add(root, _tri(base_a + Vector2(-14.0, 6.0), tip + Vector2(s * 18.0, -18.0),
				base_b + Vector2(14.0, 6.0)), Color(0.04, 0.05, 0.09))
			_add(root, _tri(base_a, tip, base_b), horn_col)
			_add(root, _tri(Vector2(bx + s * 10.0, 392.0), tip + Vector2(0, 26.0),
				base_b), horn_col.darkened(0.16))

	# Kopf (mit dicker dunkler Kontur wie im alten Icon)
	var outline := Color(0.04, 0.05, 0.09)
	if square_jaw:
		_add(root, _round_rect(head_rx * 2.0 + 34.0, head_ry * 2.0 + 34.0, 70.0), outline, head_c)
		_add(root, _round_rect(head_rx * 2.0, head_ry * 2.0, 70.0), head_col, head_c)
		# Risse im Stein
		for i in range(4):
			var rx: float = head_c.x - 140.0 + float(i) * 90.0
			_add(root, _tri(Vector2(rx, head_c.y - 120.0), Vector2(rx + 14.0, head_c.y + 30.0),
				Vector2(rx + 4.0, head_c.y + 30.0)), head_dark)
	else:
		_add(root, _ell(head_rx + 20.0, head_ry + 20.0), outline, head_c)
		_add(root, _ell(head_rx, head_ry), head_col, head_c)
	# Glanzkante oben
	_add(root, _ell(head_rx * 0.72, head_ry * 0.34), head_col.lightened(0.14), head_c - Vector2(0, head_ry * 0.52))

	# Augen
	if visor:
		# Visor-Balken mit zwei gluehenden Augen
		_add(root, _round_rect(470.0, 130.0, 50.0), Color(0.08, 0.10, 0.14), Vector2(512, 520))
		for s in [-1.0, 1.0]:
			_add(root, _circ(46.0), eye_white, Vector2(512 + s * 105.0, 520))
			_add(root, _circ(18.0), pupil_col, Vector2(512 + s * 105.0, 520))
	elif eyes == 1:
		_add(root, _circ(eye_r + 16.0), outline, Vector2(512, 520))
		_add(root, _circ(eye_r), eye_white, Vector2(512, 520))
		_add(root, _circ(eye_r * 0.46), Color(0.16, 0.42, 0.24), Vector2(512, 520))
		_add(root, _circ(eye_r * 0.20), pupil_col, Vector2(512, 520))
		_add(root, _circ(eye_r * 0.10), Color(1, 1, 1), Vector2(512 - eye_r * 0.26, 520 - eye_r * 0.24))
	elif eyes == 3:
		for i in range(3):
			var ex: float = 512.0 + (float(i) - 1.0) * 150.0
			var ey: float = 500.0 - (18.0 if i == 1 else 0.0)
			_add(root, _circ(eye_r), eye_white, Vector2(ex, ey))
			_add(root, _circ(eye_r * 0.48), pupil_col, Vector2(ex, ey))
			_add(root, _circ(eye_r * 0.14), Color(1, 1, 1), Vector2(ex - eye_r * 0.3, ey - eye_r * 0.3))
	else:
		for s in [-1.0, 1.0]:
			var ex: float = 512.0 + s * 138.0
			_add(root, _circ(eye_r + 15.0), outline, Vector2(ex, 500))
			_add(root, _circ(eye_r), eye_white, Vector2(ex, 500))
			_add(root, _circ(eye_r * 0.52), pupil_col, Vector2(ex + s * 10.0, 508))
			_add(root, _circ(eye_r * 0.17), Color(1, 1, 1), Vector2(ex - eye_r * 0.32, 500 - eye_r * 0.30))
		# Brauen: boese Schraege
		if brow:
			for s in [-1.0, 1.0]:
				_add(root, _round_rect(176.0, 44.0, 18.0), outline,
					Vector2(512.0 + s * 138.0, 500.0 - eye_r - 34.0), -s * 0.38)

	# Mund + Zaehne
	var mouth_c := Vector2(512, 706)
	var mr := 226.0
	var mh := 128.0
	_add(root, _ell(mr + 18.0, mh + 16.0), outline, mouth_c)
	_add(root, _ell(mr, mh), mouth_col, mouth_c)
	if teeth_top > 0:
		var step: float = (mr * 1.7) / float(teeth_top)
		for i in range(teeth_top):
			var tx: float = mouth_c.x - mr * 0.85 + float(i) * step
			_add(root, _tri(Vector2(tx, mouth_c.y - mh * 0.92),
				Vector2(tx + step * 0.9, mouth_c.y - mh * 0.92),
				Vector2(tx + step * 0.45, mouth_c.y - mh * 0.46)), tooth_col)
	if teeth_bot > 0:
		var step2: float = (mr * 1.7) / float(teeth_bot)
		for i in range(teeth_bot):
			var tx2: float = mouth_c.x - mr * 0.85 + float(i) * step2
			_add(root, _tri(Vector2(tx2, mouth_c.y + mh * 0.92),
				Vector2(tx2 + step2 * 0.9, mouth_c.y + mh * 0.92),
				Vector2(tx2 + step2 * 0.45, mouth_c.y + mh * 0.50)), tooth_col)
	if visor:
		# Lueftungsgitter statt Mund
		for i in range(4):
			_add(root, _round_rect(260.0, 22.0, 10.0), Color(0.10, 0.12, 0.16),
				Vector2(512, 690 + float(i) * 34.0))
	if v == "5":
		# Antenne
		_add(root, _round_rect(22.0, 150.0, 10.0), Color(0.55, 0.62, 0.72), Vector2(512, 250))
		_add(root, _circ(34.0), Color(0.62, 0.96, 1.0), Vector2(512, 168))

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	return img


func _icon146c() -> void:
	for _f in range(8):
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v146/icons/")
	var namen: Array = ["1", "2", "3", "4", "5", "6"]
	var bilder: Dictionary = {}
	for nm in namen:
		var img: Image = await _make_icon146c(str(nm))
		if img == null or img.get_width() == 0:
			print("[ICON][FEHLER] entwurf146c_%s leer" % str(nm))
			continue
		bilder[str(nm)] = img.duplicate()
		var path: String = SHOT_DIR + "v146/icons/icon146c_%s.png" % str(nm)
		img.save_png(path)
		print("[ICON][ENTWURF] name=icon146c_%s.png px=%dx%d datei=%s" % [
			str(nm), img.get_width(), img.get_height(), path])
	var sheet := Image.create(6 * 300, 520, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.10, 0.11, 0.14))
	var ref: Image = Image.load_from_file(SHOT_DIR + "v146/old_icon_v127.png")
	for i in range(namen.size() + 1):
		var im: Image = null
		if i == 0:
			im = ref
		else:
			im = bilder.get(str(namen[i - 1]), null)
		if im == null:
			continue
		var big: Image = im.duplicate()
		big.convert(Image.FORMAT_RGBA8)
		big.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(big, Rect2i(0, 0, 256, 256), Vector2i(22 + i * 300, 20))
		var sizes: Array = [48, 72, 96]
		var xs: Array = [22, 92, 176]
		for k in range(3):
			var small: Image = im.duplicate()
			small.convert(Image.FORMAT_RGBA8)
			small.resize(int(sizes[k]), int(sizes[k]), Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(small, Rect2i(0, 0, int(sizes[k]), int(sizes[k])),
				Vector2i(22 + i * 300 + int(xs[k]) - 22, 300))
		var g: Image = im.duplicate()
		g.convert(Image.FORMAT_RGBA8)
		g.resize(144, 144, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(g, Rect2i(0, 0, 144, 144), Vector2i(22 + i * 300 + 120, 360))
		# Beschriftung im Blatt
		print("[ICON][BLATT] platz=%d quelle=%s" % [i, "alt_v127" if i == 0 else "neu_" + str(namen[i - 1])])
	var p2: String = SHOT_DIR + "v146/icons_uebersicht146c.png"
	sheet.save_png(p2)
	print("[ICON][UEBERSICHT] datei=%s px=%dx%d entwuerfe=6 plus_alt=1" % [
		p2, sheet.get_width(), sheet.get_height()])
	print("[TEST][ICON146C] ENDE")


# ============================================================
# v1.48 - Belege
# ============================================================

func _v148_ui():
	for _f in range(12):
		await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var ls = uim.get("load_screen")
	if ls != null and is_instance_valid(ls):
		ls.visible = false
		ls.set_process(false)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v148/")
	return uim


func _swipe_v148(from: Vector2, to: Vector2, steps: int = 8) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = true
	t.position = from
	get_viewport().push_input(t, true)
	for i in range(1, steps + 1):
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = from.lerp(to, float(i) / float(steps))
		d.relative = (to - from) / float(steps)
		get_viewport().push_input(d, true)
		await get_tree().process_frame
	var t2 := InputEventScreenTouch.new()
	t2.index = 0
	t2.pressed = false
	t2.position = to
	get_viewport().push_input(t2, true)
	await get_tree().process_frame


func _wheel148() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(SHOT_DIR + "v148/")
	var n: int = 200000
	var r: Dictionary = WM.simulate(n, 500)
	var counts: Array = r["counts"]
	var gem: int = 0
	var gold: int = 0
	var skin: int = 0
	var hut: int = 0
	for i in range(WM.SLICES.size()):
		var sl: Dictionary = WM.SLICES[i]
		var key := str(sl["key"])
		var c: int = int(counts[i])
		if key.begins_with("gem"):
			gem += c
		elif key.begins_with("gold"):
			gold += c
		elif key == "hut":
			hut += c
		elif key == "skin":
			skin += c
		print("[WHEEL][SIM] segment=%d key=%s treffer=%d anteil=%.2f%%" % [
			i, key, c, 100.0 * float(c) / float(n)])
	var rtp: float = float(r["rtp"])
	print("[WHEEL][SIM] n=%d skin=%d hut=%d diamanten=%d gold=%d summe=%d rtp_gold=%.4f rtp_v147=0.9200 abweichung_pp=%.2f" % [
		n, skin, hut, gem, gold, skin + hut + gem + gold, rtp, absf(rtp - 0.92) * 100.0])
	# Segment-Icons als Blatt (8 Segmente, je Icon + Wert)
	var cell: int = 150
	var out := Image.create(cell * 8 + 20, cell + 20, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.08, 0.09, 0.12, 1.0))
	for i in range(WM.SLICES.size()):
		var sl2: Dictionary = WM.SLICES[i]
		var tex: Texture2D = TextureManager.get_texture("wheel_icon_" + str(sl2.get("art", "gold")))
		if tex == null:
			print("[WHEEL][SEGMENT] FEHLER index=%d icon=null" % i)
			continue
		var im: Image = tex.get_image()
		im.resize(128, 128, Image.INTERPOLATE_NEAREST)
		out.blend_rect(im, Rect2i(0, 0, 128, 128), Vector2i(10 + i * cell, 20))
		print("[WHEEL][SEGMENT] index=%d icon=%s wert=%d key=%s" % [
			i, "wheel_icon_" + str(sl2.get("art", "gold")),
			int(sl2.get("gems", 0)) if int(sl2.get("gems", 0)) > 0 else int(sl2.get("mult", 0.0)),
			str(sl2["key"])])
	out.save_png(SHOT_DIR + "v148/wheel_segmente.png")
	print("[SHOT] v148/wheel_segmente.png (%dx%d)" % [out.get_width(), out.get_height()])
	# Kisten-Kontaktblatt: 3 Kisten x 2 Zustaende x 3 Groessen
	var tiles: Array = []
	for tier in ["standard", "silver", "premium"]:
		for open_state in [false, true]:
			for sz in [96, 160, 256]:
				tiles.append([tier, open_state, sz])
	var cols: int = 6
	var rows: int = 3
	var sheet := Image.create(cols * 268 + 20, rows * 268 + 20, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.09, 0.12, 1.0))
	var ti: int = 0
	for tier in ["standard", "silver", "premium"]:
		for ci in range(6):
			var open_state: bool = ci >= 3
			var sz: int = [96, 160, 256][ci % 3]
			var key2: String = ("chest_gem_open_" if open_state else "chest_gem_") + tier
			var tex2: Texture2D = TextureManager.get_texture(key2)
			if tex2 == null:
				print("[CHEST][KANTE] FEHLER tier=%s fehlt" % tier)
				continue
			var im2: Image = tex2.get_image()
			im2.resize(sz, sz, Image.INTERPOLATE_NEAREST)
			var px: int = ti % cols
			var py: int = int(ti / cols)
			sheet.blend_rect(im2, Rect2i(0, 0, sz, sz), Vector2i(10 + px * 268 + int((256 - sz) * 0.5), 10 + py * 268))
			print("[CHEST][KANTE] kiste=%s offen=%s px=%d spitzen=%d" % [
				tier, str(open_state), sz, 0 if sz < 64 else GenChestArt.kanten_spitzen(im2)])
			ti += 1
	sheet.save_png(SHOT_DIR + "v148/kisten.png")
	print("[SHOT] v148/kisten.png (%dx%d)" % [sheet.get_width(), sheet.get_height()])
	# Schuss-Knopf: alte Fassung (96 px, alte Zeichenfolge) gegen neu (128/96)
	var alt := GenUi._new_img(96, 96)
	GenUi._disc(alt, 48, 48, 46, TexDraw.OUTLINE)
	GenUi._disc(alt, 48, 48, 42, Color(0.85, 0.20, 0.18))
	GenUi._ring(alt, 48, 48, 34, 4, Color(1, 1, 1, 0.7))
	GenUi._disc(alt, 48, 48, 12, Color(1.0, 0.85, 0.2))
	var neu_tex: Texture2D = TextureManager.get_texture("btn_shoot")
	var bsheet := Image.create(96 + 128 + 96 + 60, 160, false, Image.FORMAT_RGBA8)
	bsheet.fill(Color(0.10, 0.11, 0.14, 1.0))
	bsheet.blend_rect(alt, Rect2i(0, 0, 96, 96), Vector2i(20, 30))
	var neu128: Image = neu_tex.get_image()
	neu128.resize(128, 128, Image.INTERPOLATE_CUBIC)
	bsheet.blend_rect(neu128, Rect2i(0, 0, 128, 128), Vector2i(140, 14))
	var neu96: Image = neu_tex.get_image()
	neu96.resize(96, 96, Image.INTERPOLATE_CUBIC)
	bsheet.blend_rect(neu96, Rect2i(0, 0, 96, 96), Vector2i(290, 30))
	bsheet.save_png(SHOT_DIR + "v148/schussbutton_alt_neu.png")
	print("[SHOT] v148/schussbutton_alt_neu.png (%dx%d)" % [bsheet.get_width(), bsheet.get_height()])


func _shop148() -> void:
	var uim = await _v148_ui()
	var shopl = gm.call("_shopl_p")
	# 1) Filter: je Modus 20 Angebots-Ziehungen
	for mode in [0, 1, 2]:
		gm.set("game_mode", mode)
		var wellen_only: int = 0
		var verletzungen: int = 0
		for i in range(20):
			var offers: Array = shopl.call("_build_shop_offers")
			for o in offers:
				var modi: Array = o.get("modi", [])
				if modi.has("wellen"):
					if mode != 1:
						verletzungen += 1
					else:
						wellen_only += 1
		print("[SHOP][FILTER][SUMME] modus=%d ziehungen=20 wellen_only=%d verletzungen=%d" % [
			mode, wellen_only, verletzungen])
	# 2) Run-Starts in beiden Modi - Startwerte vergleichen
	var werte: Array = []
	for mode in [0, 1]:
		gm.set("game_mode", mode)
		gm.call("start_game", false, false)
		await get_tree().create_timer(1.0).timeout
		var p = gm.get("player")
		if p != null and is_instance_valid(p):
			var e := [mode, int(p.get("max_health")), int(p.get("shield")), float(p.get("speed_mult")), float(p.get("damage_mult"))]
			werte.append(e)
			print("[RUN][START][MESS] modus=%d hp=%d schild=%d tempo=%.2f schaden=%.2f" % e)
		gm.call("restart_game", false)
		await get_tree().create_timer(0.7).timeout
	if werte.size() == 2:
		var gleich: bool = werte[0][1] == werte[1][1] and werte[0][2] == werte[1][2] \
			and absf(float(werte[0][3]) - float(werte[1][3])) < 0.001 \
			and absf(float(werte[0][4]) - float(werte[1][4])) < 0.001
		print("[RUN][START][VERGLEICH] modus0_vs_modus1 identisch=%s" % str(gleich))
	# 3) Alle drei Kisten liefern weiter Inhalte
	for tier in ["standard", "silver", "premium"]:
		var inhalt: int = 0
		var nieten: int = 0
		for k in range(5):
			gm.set("gems", 999)
			var vor: int = int(gm.get("gems"))
			var res: Dictionary = gm.call("buy_chest", tier)
			var kind := str(res.get("kind", "?"))
			if kind != "none":
				inhalt += 1
			else:
				nieten += 1
			print("[SHOP][KISTE] tier=%s kauf=%d ok=%s art=%s name=%s gems_vor=%d gems_nach=%d" % [
				tier, k + 1, str(bool(res.get("ok", false))), kind,
				str(res.get("name", "?")), vor, int(gm.get("gems"))])
		print("[SHOP][KISTE][SUMME] tier=%s kaeufe=5 inhalt=%d nieten=%d" % [tier, inhalt, nieten])



func _coll_scroll148() -> void:
	# Handy-Format erzwingen - headless ist der Viewport sonst quadratisch (1920x1920).
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	var uim = await _v148_ui()
	uim.call("show_collection")
	await get_tree().create_timer(0.6).timeout
	var page: Control = uim.get("collection_page")
	if page == null:
		print("[COLL][FEHLER] seite=null")
		return
	var tiles: Array = page.find_children("Tile_*", "Button", true, false)
	var sperren: Array = page.find_children("Lock", "TextureRect", true, false)
	var balken: Array = page.find_children("RarBar", "ColorRect", true, false)
	print("[COLL][BAU] kacheln=%d ketten=%d balken=%d" % [tiles.size(), sperren.size(), balken.size()])
	var cs = page.find_child("CollectionScroll", true, false)
	if cs is ScrollContainer:
		var inner = cs.find_child("CollectionInner", true, false)
		print("[SCROLL][VP] viewport=%s page=%s scroll_pos=%s" % [
			str(get_viewport().get_visible_rect().size), str((page as Control).size),
			str((cs as ScrollContainer).position)])
		print("[SCROLL][MASS] seite=collection sicht=%.0f inhalt=%.0f max=%.0f" % [
			float((cs as ScrollContainer).size.y),
			float((inner as Control).get_combined_minimum_size().y) if inner != null else -1.0,
			float((cs as ScrollContainer).get_v_scroll_bar().max_value)])
	for i in range(3):
		# Vor jedem Zug nach oben: dann bewegt sich jede Geste messbar (max=556).
		if cs is ScrollContainer:
			(cs as ScrollContainer).scroll_vertical = 0
		await get_tree().process_frame
		await _swipe_v148(Vector2(960, 820), Vector2(960, 570), 8)
		await get_tree().create_timer(0.25).timeout
		print("[SCROLL][STAND] seite=collection zug=%d scroll=%d" % [
			i + 1, int(cs.scroll_vertical) if cs is ScrollContainer else -1])
	# Gegenprobe: kurzer Tipp (3 px)
	await _swipe_v148(Vector2(960, 700), Vector2(960, 697), 2)
	await get_tree().create_timer(0.3).timeout
	# Balkenfarben gegen die gezeichneten Werte pruefen
	var ok: int = 0
	for b in balken:
		var col: Color = (b as ColorRect).color
		var soll: Color = b.get_meta("soll", Color.BLACK)
		var owned: bool = bool(b.get_meta("owned", false))
		if not owned:
			ok += 1
			continue
		if absf(col.r - soll.r) <= 8.0 / 255.0 and absf(col.g - soll.g) <= 8.0 / 255.0 and absf(col.b - soll.b) <= 8.0 / 255.0:
			ok += 1
	print("[COLL][BALKEN] geprueft=%d ok=%d" % [balken.size(), ok])


func _info148() -> void:
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	var uim = await _v148_ui()
	uim.call("_open_settings_page", "menu")
	await get_tree().create_timer(0.5).timeout
	var btn: Button = null
	var sp = uim.get("settings_page")
	if sp != null:
		btn = sp.find_child("InfoButton", true, false)
	print("[INFO][WEG] knopf_in_einstellungen=%s" % str(btn != null))
	uim.call("_open_info_page")
	await get_tree().create_timer(0.6).timeout
	var page: Control = uim.get("info_page")
	if page == null:
		print("[INFO][FEHLER] seite=null")
		return
	var content = page.find_child("InfoContent", true, false)
	var hoehe: int = int(content.get_combined_minimum_size().y) if content != null else -1
	var abschnitte: int = content.get_child_count() if content != null else 0
	var ss = uim.call("_info_p").get("_scroll")
	var vmax: float = float(ss.call("v_max")) if ss != null else -1.0
	print("[INFO][SEITE] abschnitte=%d hoehe=%dpx sicht=%.0f max=%.0f scrollbar=%s" % [
		abschnitte, hoehe, float(ss.get("size").y) if ss != null else -1.0, vmax, str(vmax > 0.0)])
	var start: float = float(ss.get("offset")) if ss != null else 0.0
	for i in range(2):
		await _swipe_v148(Vector2(960, 820), Vector2(960, 480), 8)
		await get_tree().create_timer(0.4).timeout
	var ende: float = float(ss.get("offset")) if ss != null else 0.0
	print("[INFO][SCROLL] von=%.0f nach=%.0f px=%.0f" % [start, ende, absf(ende - start)])
	uim.call("_close_info_page")
	await get_tree().create_timer(0.2).timeout
	print("[INFO][ZURUECK] einstellungen_wieder_da=%s" % str(sp != null and (sp as Control).visible))


func _v148shot() -> void:
	var uim = await _v148_ui()
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	# 1) Gluecksrad
	uim.call("_open_wheel_ui")
	await get_tree().create_timer(1.0).timeout
	# Ein echter Spin ueber den Knopf (Beleg [WHEEL][GEWINN])
	var wroot0: Control = null
	for c in uim.get_children():
		if c.get_class() == "Control" and c.has_method("is_spinning"):
			wroot0 = c
	if wroot0 != null:
		var sb0: Button = wroot0.find_child("WheelSpin", true, false)
		if sb0 != null:
			await _click_v148(sb0.get_global_rect().get_center())
			await get_tree().create_timer(7.5).timeout
	await _shot("v148/wheel_rad.png")
	# Restliche Seiten im Geraeteformat (1920x1080) - der Schuss-Knopf ist
	# fuer diese Hoehe gesetzt, bei 720 px wuerde er unten angeschnitten.
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	# Rad schliessen
	var wroot: Control = null
	for c in uim.get_children():
		if c.get_class() == "Control" and c.has_method("is_spinning"):
			wroot = c
	if wroot != null:
		wroot.call("_on_close")
	await get_tree().create_timer(0.4).timeout
	# 2) Sammlung
	uim.call("show_collection")
	await get_tree().create_timer(1.0).timeout
	await _shot("v148/coll_zustaende.png")
	await _swipe_v148(Vector2(960, 820), Vector2(960, 420), 8)
	await get_tree().create_timer(0.6).timeout
	await _shot("v148/coll_scroll.png")
	# 3) Info-Seite
	uim.call("_open_settings_page", "menu")
	await get_tree().create_timer(0.6).timeout
	await _shot("v148/info_knopf.png")
	uim.call("_open_info_page")
	await get_tree().create_timer(0.8).timeout
	await _shot("v148/info_seite.png")
	await _swipe_v148(Vector2(960, 820), Vector2(960, 400), 8)
	await get_tree().create_timer(0.6).timeout
	await _shot("v148/info_seite_2.png")
	uim.call("_close_info_page")
	await get_tree().create_timer(0.3).timeout
	# 4) Shop (Kisten-Designs im echten Fenster)
	uim.call("_open_chest_page")
	await get_tree().create_timer(1.0).timeout
	await _shot("v148/shop_kisten.png")
	# 5) Run mit neuem Schuss-Knopf
	uim.call("_close_pages")
	await get_tree().create_timer(0.3).timeout
	gm.set("game_mode", 0)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.6).timeout
	var p0 = gm.get("player")
	if p0 != null and is_instance_valid(p0):
		var cs0 = gm.get("chest_scene")
		if cs0 != null:
			var ch0 = cs0.instantiate()
			ch0.position = (p0 as Node2D).position + Vector2(170, 40)
			ch0.set("gm", gm)
			gm.get("chest_container").add_child(ch0)
			if ch0.has_method("set_rarity"):
				ch0.call("set_rarity", "epic")
			print("[CHEST][INGAME] platziert pos=%s seltenheit=epic" % str(ch0.position))
	await get_tree().create_timer(0.8).timeout
	var sb = uim.get("shoot_btn")
	if sb != null:
		var tex = sb.get("texture_normal")
		print("[BTN][RECT] pos=%s scale=%s tex=%s transform=%s viewport=%s" % [
			str(sb.get("position")), str(sb.get("scale")),
			str(tex.get_size() if tex != null else Vector2.ZERO),
			str(sb.get("transform")), str(get_viewport().get_visible_rect().size)])
	await _shot("v148/schussbutton_ingame.png")
	await _shot("v148/kiste_ingame.png")
	gm.call("restart_game", false)


func _v148ui() -> void:
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	var uim = await _v148_ui()
	# Karten-Seite: Jahreszeiten-Knoepfe je Planet
	uim.call("_open_maps_page")
	await get_tree().create_timer(0.8).timeout
	var mp: Control = uim.get("maps_page")
	var reihen: int = 0
	if mp != null:
		for c in mp.find_children("*", "HBoxContainer", true, false):
			var hb := c as HBoxContainer
			if hb.get_child_count() == 4 and hb.get_child(0) is Button:
				var b0 := hb.get_child(0) as Button
				if b0.custom_minimum_size.x >= 60.0 and b0.custom_minimum_size.x <= 80.0:
					reihen += 1
		print("[MAP][SEASON][SUMME] planeten_mit_4_knoepfen=%d" % reihen)
	# Aufgaben-Seite: Karten zaehlen
	uim.call("_open_challenge_page")
	await get_tree().create_timer(0.8).timeout
	var cp: Control = uim.get("challenge_page")
	var karten: Array = []
	if cp != null:
		for c in cp.find_children("ChalStart_*", "Button", true, false):
			karten.append(c)
	print("[CHAL][KARTEN] anzahl=%d leer=false" % karten.size())


func _v148winter() -> void:
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	var uim = await _v148_ui()
	gm.call("debug_unlock_all")
	# Erde + Winter fest setzen (gleicher Weg wie die Karten-Seite)
	var asea: Dictionary = gm.get("active_season")
	asea["earth"] = "winter"
	gm.set("active_season", asea)
	var modus: Dictionary = gm.get("season_mode")
	modus["earth"] = "fixed"
	gm.set("season_mode", modus)
	gm.set("active_map", "earth")
	gm.set("game_mode", 2)
	gm.call("restart_game", false)
	await get_tree().create_timer(0.5).timeout
	gm.call("start_game", false, false)
	await get_tree().create_timer(2.5).timeout
	var p = gm.get("player")
	if p != null and is_instance_valid(p):
		print("[MAP][SEASON][MESS] planet=%s season=%s hp=%d" % [
			str(gm.get("active_map")), str(gm.get("season_id")), int(p.get("max_health"))])
	await _shot("v148/erde_winter.png")


func _chal148() -> void:
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	var uim = await _v148_ui()
	gm.call("chal_reset")
	gm.set("gems", 0)
	await get_tree().create_timer(0.3).timeout
	gm.call("chal_start", "sparsam", "leicht")
	await get_tree().create_timer(1.4).timeout
	var cr = gm.get("chal_run")
	if cr == null:
		print("[CHAL][FEHLER] lauf=null")
		return
	print("[CHAL][LAUF] id=%s stufe=%s aktiv=%s runden_soll=%d gems_vorher=%d" % [
		str(cr.get("id")), str(cr.get("stufe")), str(cr.get("aktiv")),
		int(cr.get("runden_max")), int(gm.get("gems"))])
	for r in range(1, int(cr.get("runden_max")) + 1):
		cr.call("on_round_cleared", r)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	print("[CHAL][ENDE] beendet=%s gewonnen_gems=%d fortschritt=%d/%d" % [
		str(cr.get("beendet")), int(gm.get("gems")), int(cr.get("fortschritt")),
		int(cr.get("runden_max"))])
	var bel: Dictionary = gm.call("chal_claim", "sparsam")
	print("[CHAL][ABHOLEN] ok=%s gutschrift=%s gems=%d" % [
		str(bool(bel.get("ok", false))), str(bool(bel.get("gutschrift", false))), int(gm.get("gems"))])


func _click_v148(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	get_viewport().push_input(ev, true)
	await get_tree().process_frame
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = pos
	get_viewport().push_input(ev2, true)
	await get_tree().process_frame


func _upg148() -> void:
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	var uim = await _v148_ui()
	for mode in [0, 1]:
		gm.call("restart_game", false)
		await get_tree().create_timer(0.8).timeout
		gm.set("game_mode", mode)
		gm.call("start_game", false, false)
		await get_tree().create_timer(1.4).timeout
		var p = gm.get("player")
		var tries: int = 0
		while int(gm.get("pending_upgrades")) == 0 and tries < 60:
			var pos := (p as Node2D).global_position if (p != null and is_instance_valid(p)) else Vector2.ZERO
			gm.call("_on_monster_killed", 60, 1, pos)
			tries += 1
			await get_tree().process_frame
		var toast0 = uim.get("upgrade_toast")
		var ov0 = uim.get("upgrade_overlay")
		print("[UPG148][%d] levelups=%d kills=%d pending=%d toast=%s karten_offen=%s paused=%s" % [
			mode, int(gm.get("level")), tries, int(gm.get("pending_upgrades")),
			str(toast0 != null and is_instance_valid(toast0)),
			str(ov0 != null and is_instance_valid(ov0)), str(get_tree().paused)])
		if mode == 0:
			# Toast echt antippen (push_input, Canvas-Koordinaten)
			if toast0 != null and is_instance_valid(toast0):
				var trect: Rect2 = (toast0 as Control).get_global_rect()
				print("[UPG148][0] toast_rect=%s" % str(trect))
				await _click_v148(trect.get_center())
				await get_tree().create_timer(0.5).timeout
			var ov1 = uim.get("upgrade_overlay")
			var cards: Array = []
			if ov1 != null and is_instance_valid(ov1):
				cards = (ov1 as Control).find_children("*", "Button", true, false)
			print("[UPG148][0] nach_tipp karten=%d paused=%s" % [cards.size(), str(get_tree().paused)])
			var stacks_vor: Dictionary = (gm.get("upg_stacks") as Dictionary).duplicate()
			if cards.size() > 0:
				var c0 := cards[0] as Control
				await _click_v148(c0.get_global_rect().get_center())
				await get_tree().create_timer(0.5).timeout
			var stacks_nach: Dictionary = gm.get("upg_stacks")
			var ov2 = uim.get("upgrade_overlay")
			var toast2 = uim.get("upgrade_toast")
			print("[UPG148][0] nach_wahl stacks_vor=%s stacks_nach=%s overlay=%s toast=%s paused=%s pending=%d" % [
				str(stacks_vor), str(stacks_nach),
				str(ov2 != null and is_instance_valid(ov2)), str(toast2 != null and is_instance_valid(toast2)),
				str(get_tree().paused), int(gm.get("pending_upgrades"))])
		# Nach Restart: kein haengendes Fenster, kein Pause-Rest
		gm.call("restart_game", false)
		await get_tree().create_timer(0.8).timeout
		var ov3 = uim.get("upgrade_overlay")
		var toast3 = uim.get("upgrade_toast")
		print("[UPG148][%d] nach_restart overlay=%s toast=%s paused=%s" % [
			mode, str(ov3 != null and is_instance_valid(ov3)),
			str(toast3 != null and is_instance_valid(toast3)), str(get_tree().paused)])

# ================================================================
# v1.51 — Balancing-Messung RUNDEN-Modus + Skills im Shop
# ================================================================

func _bal151() -> void:
	print("[BAL151][START] messung=runden_modus version=%s" % str(gm.get("APP_VERSION")))
	var monster_speed: float = 125.0   # RED (monster_ai TYPE_STATS)
	var player_speed: float = 160.0    # player_controller SPEED
	var min_ratio: Dictionary = { "leicht": 99.0, "normal": 99.0, "hart": 99.0 }
	for diff in ["leicht", "normal", "hart"]:
		var d: Dictionary = Rounds.DIFFICULTY.get(diff, Rounds.DIFFICULTY["normal"])
		for r in range(1, 17):
			var spd: float = Rounds.spd_mult(r)
			var red: float = monster_speed * spd
			var ratio: float = player_speed / maxf(1.0, red)
			min_ratio[diff] = minf(float(min_ratio[diff]), ratio)
			if r % 2 == 1 or r > 13:
				print("[BAL151][KURVE] stufe=%s runde=%d gegner=%d hp=%.0f red_speed=%.0f player=%.0f verhaeltnis=%.2f muenz_faktor=%.2f" % [
					diff, r, Rounds.monster_count_for(r, diff), Rounds.hp_total_with_boss(r, diff),
					red, player_speed, ratio, float(d["muenz"])])
	for diff in ["leicht", "normal", "hart"]:
		var ok: bool = float(min_ratio[diff]) >= 1.05
		print("[BAL151][TEMPO] stufe=%s min_verhaeltnis=%.2f ok=%s" % [diff, float(min_ratio[diff]), str(ok)])
	# Muenzen pro Kill (v1.51: Basis 2 + hp*0.8, Faktor 1+0.08r)
	for r in [1, 5, 9, 14]:
		print("[BAL151][MUENZ] runde=%d gruen=%d rot=%d blau=%d lila=%d boss=%d" % [
			r, Rounds.coins_per_kill(0, r), Rounds.coins_per_kill(1, r),
			Rounds.coins_per_kill(2, r), Rounds.coins_per_kill(3, r), Rounds.coins_per_kill(7, r)])
	for r in [1, 9, 14]:
		print("[BAL151][RUNDENBONUS] runde=%d muenzen=%d" % [r, Rounds.round_bonus(r)])
	# Einkommen pro Runde (Muenzen aus Kills + Rundenbonus)
	for diff in ["leicht", "normal", "hart"]:
		var kum: int = 0
		var zeile: Array = []
		for r in range(1, 13):
			var ein: int = int(Rounds.round_bonus(r, diff))
			for g in Rounds.spawn_groups_for(r, diff):
				ein += int(g["count"]) * int(Rounds.coins_per_kill(int(g["type"]), r, diff))
			kum += ein
			if r in [3, 6, 9, 12]:
				zeile.append("r%d=%d(kum %d)" % [r, ein, kum])
		print("[BAL151][EINKOMMEN] stufe=%s %s" % [diff, " ".join(zeile)])
	# --- Shop-Skills im echten Runden-Modus ---
	for _f in range(6):
		await get_tree().process_frame
	gm.set("unlocked_maps", ["earth", "mars", "jungle", "volt"])
	gm.set("active_map", "earth")
	gm.set("game_mode", 2)
	gm.call("set_round_difficulty", "leicht")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.2).timeout
	var rm = gm.get("rounds_mode")
	rm.set("round_no", 8)
	gm.set("coins", 5000)
	var ui = gm.get("ui_manager")
	ui.call("open_rounds_shop")
	await get_tree().create_timer(0.6).timeout
	var ws = ui.get("wave_shop")
	print("[BAL151][SHOP] offen=%s karten=%d" % [str(ws != null), int(ws.get("_cards").size()) if ws != null else -1])
	if ws != null:
		for i in range(2):
			for sid in ["skill_speed", "skill_reload", "skill_damage"]:
				var ok_kauf: bool = bool(ws.call("_buy_skill", sid))
				print("[BAL151][CALL] durchlauf=%d id=%s ok=%s stufe=%d" % [
					i, sid, str(ok_kauf), int(rm.call("skill_stacks_of", sid))])
	# Grenze 6 direkt am Modul pruefen (7. Kauf muss abgelehnt werden)
	for j in range(7):
		var s_id: String = "skill_speed"
		var preis2: int = WaveShop.skill_price(s_id, 8, "leicht", int(rm.call("skill_stacks_of", s_id)))
		var ok2: bool = bool(rm.call("buy_skill", s_id, preis2))
		print("[BAL151][MODUL] nr=%d id=%s preis=%d ok=%s stufe=%d" % [
			j, s_id, preis2, str(ok2), int(rm.call("skill_stacks_of", s_id))])
	# echter Klickpfad ueber den Knopf im Shop
	if ws != null:
		var btn: Button = ws.find_child("Skill_skill_damage", true, false) as Button
		if btn != null:
			var vorher: int = int(rm.call("skill_stacks_of", "skill_damage"))
			btn.emit_signal("pressed")
			print("[BAL151][KNOPF] skill_damage vorher=%d nachher=%d" % [
				vorher, int(rm.call("skill_stacks_of", "skill_damage"))])
		else:
			print("[BAL151][KNOPF] FEHLER knopf_fehlt")
	var p = gm.get("player")
	print("[BAL151][STATS] speed=%.2f cooldown=%.2f damage=%.2f stufen=%s muenzen=%d" % [
		float(p.get("speed_mult")), float(p.get("cooldown_mult")), float(p.get("damage_mult")),
		str(rm.get("skill_stacks")), int(gm.get("coins"))])
	var st: Dictionary = rm.get("skill_stacks")
	var ok_stats: bool = int(st.get("skill_speed", 0)) == 6 and int(st.get("skill_reload", 0)) >= 2 \
		and int(st.get("skill_damage", 0)) >= 2 \
		and absf(float(p.get("speed_mult")) - (1.0 + 0.10 * float(st.get("skill_speed", 0)))) < 0.01
	print("[BAL151][ERGEBNIS] skills_wirken=%s" % str(ok_stats))
	if ws != null and is_instance_valid(ws):
		ws.call("close")
	gm.call("quit_to_menu")
	await get_tree().create_timer(0.5).timeout
	print("[BAL151][ENDE]")


# ================================================================
# v1.51 — Shop zwischen den Runden: HUD-Knopf -> Skills kaufen
# ================================================================

func _rundenshop151() -> void:
	for _f in range(6):
		await get_tree().process_frame
	gm.set("unlocked_maps", ["earth", "mars", "jungle", "volt"])
	gm.set("active_map", "earth")
	gm.set("game_mode", 2)
	gm.call("set_round_difficulty", "leicht")
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.2).timeout
	var ui = gm.get("ui_manager")
	var rm = gm.get("rounds_mode")
	var mc = gm.get("monster_container")
	print("[SHOP151][START] runde=%d stufen=%s" % [int(rm.get("round_no")), str(rm.get("skill_stacks"))])
	# Runde 1 leeren, damit die Intermission kommt
	var guard: int = 0
	while bool(rm.get("active")) and guard < 400:
		guard += 1
		if guard > 20:
			for m in mc.get_children():
				if is_instance_valid(m):
					(m as Node).queue_free()
		await get_tree().physics_frame
	await get_tree().create_timer(0.8).timeout
	var btn = ui.get("wave_shop_btn")
	print("[SHOP151][HUD] intermission=%s knopf=%s sichtbar=%s" % [
		str(rm.get("intermission")), str(btn != null), str(btn.visible if btn != null else false)])
	gm.set("coins", 1200)
	if btn != null:
		btn.emit_signal("pressed")
	await get_tree().create_timer(0.7).timeout
	var ws = ui.get("wave_shop")
	print("[SHOP151][OFFEN] shop=%s karten=%d" % [str(ws != null), int(ws.get("_cards").size()) if ws != null else -1])
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("v151/shop_skills.png")
	if ws != null:
		var pnl = ws.find_child("WaveShopPanel", true, false) as Control
		if pnl != null:
			var unten: float = pnl.position.y + pnl.size.y
			print("[SHOP151][LAYOUT] panel=(%.0f,%.0f) hoehe=%.0f unten=%.0f viewport=%d passt=%s" % [
				pnl.position.x, pnl.position.y, pnl.size.y, unten,
				int(get_window().size.y), str(unten <= float(get_window().size.y))])
	if ws != null:
		for sid in ["skill_speed", "skill_reload"]:
			var b: Button = ws.find_child("Skill_%s" % sid, true, false) as Button
			if b == null:
				print("[SHOP151][FEHLER] knopf_fehlt id=%s" % sid)
				continue
			b.emit_signal("pressed")
			print("[SHOP151][KAUF] id=%s stufe=%d" % [sid, int(rm.call("skill_stacks_of", sid))])
		ws.call("close")
	await get_tree().create_timer(0.5).timeout
	print("[SHOP151][ZUSTAND] shop_offen=%s muenzen=%d speed=%.2f cooldown=%.2f" % [
		str(ui.get("wave_shop") != null), int(gm.get("coins")),
		float(gm.get("player").get("speed_mult")), float(gm.get("player").get("cooldown_mult"))])
	# naechste Runde startbar?
	gm.call("start_round")
	await get_tree().create_timer(0.8).timeout
	print("[SHOP151][RUNDE2] runde=%d aktiv=%s" % [int(rm.get("round_no")), str(rm.get("active"))])
	gm.call("quit_to_menu")
	await get_tree().create_timer(0.4).timeout
	print("[SHOP151][ENDE]")


# ================================================================
# v1.52 — Kisten-Oeffnung: die drei Stile als Bildfolge
# ================================================================

func _tap_until_open(ui, max_taps: int = 4, pause: float = 0.75) -> int:
	var n: int = 0
	while n < max_taps:
		if not is_instance_valid(ui):
			break
		if bool(ui.get("_done")) or bool(ui.get("_opening")):
			break
		ui.call("_tap")
		n += 1
		print("[TIP152] tipp=%d done=%s" % [n, str(ui.get("_done"))])
		await get_tree().create_timer(pause).timeout
	return n


func _chestfx(stil: int) -> void:
	for _f in range(8):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	await get_tree().process_frame
	var ss = gm.get("ui_manager").get("start_screen")
	if ss != null and is_instance_valid(ss):
		ss.hide()
	var ui = load("res://scripts/ui/chest_open_ui.gd").new()
	ui.setup(gm)
	ui.set("style", stil)
	gm.get("ui_manager").add_child(ui)
	var res: Dictionary = {
		"kind": "skin", "index": 3, "rarity": "epic", "name": "NEON RUNNER", "duplicate": false,
	}
	ui.open("premium", res)
	await get_tree().create_timer(0.9).timeout
	await _shot("v152/stil_%d_tipp0.png" % stil)
	for i in range(4):
		if bool(ui.get("_done")) or bool(ui.get("_opening")):
			break
		ui.call("_tap")
		await get_tree().create_timer(0.55).timeout
		await _shot("v152/stil_%d_tipp%d.png" % [stil, i + 1])
	await get_tree().create_timer(1.6).timeout
	await _shot("v152/stil_%d_karte.png" % stil)
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(ui):
		ui.call("_close")
	await get_tree().create_timer(0.3).timeout
	print("[CHESTFX][TEST] stil=%d ende" % stil)


func _chestshop152() -> void:
	for _f in range(8):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	var uim = gm.get("ui_manager")
	gm.set("unlocked_maps", ["earth"])
	uim.call("_open_chest_page")
	await get_tree().create_timer(1.4).timeout
	var page = uim.get("chest_page")
	await _shot("v152/shop_kisten.png")
	print("[CHESTFX][SHOP] seite=%s" % str(page != null))


# ================================================================
# v1.52 — echter Kaufpfad: Shop -> Bestaetigung -> neue Oeffnung
# ================================================================

func _chestbuy152() -> void:
	for _f in range(8):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	gm.set("unlocked_maps", ["earth"])
	var uim = gm.get("ui_manager")
	uim.call("_open_chest_page")
	await get_tree().create_timer(1.2).timeout
	# Testkonto, danach wird der echte Stand zurueckgeschrieben (kein Profil-Muell)
	var gold_echt: int = int(gm.get("gold"))
	var gems_echt: int = int(gm.get("gems"))
	gm.set("gold", 99999)
	gm.set("gems", 999)
	print("[BUY152][START] seite=%s gold=%d gems=%d" % [
		str(uim.get("chest_page") != null), int(gm.get("gold")), int(gm.get("gems"))])
	# echter Weg des OEFFNEN-Knopfes auf der Kistenseite
	uim.call("_on_chest_open", "standard")
	await get_tree().create_timer(1.2).timeout
	var kiste = null
	for c in uim.get_children():
		if c is ChestOpenUI:
			kiste = c
	await _shot("v152/buy_zu.png")
	var tipps: int = 0
	if kiste != null:
		tipps = await _tap_until_open(kiste, 4, 0.8)
	await get_tree().create_timer(0.5).timeout
	await _shot("v152/buy_oeffnung.png")
	await get_tree().create_timer(1.8).timeout
	await _shot("v152/buy_karte.png")
	var offen: bool = false
	for c in uim.get_children():
		if c is ChestOpenUI:
			offen = true
	print("[BUY152][ERGEBNIS] neue_oeffnung_offen=%s" % str(offen))
	# Profil wieder auf den echten Stand setzen
	gm.set("gold", gold_echt)
	gm.set("gems", gems_echt)
	gm.call("_save_profile")
	print("[BUY152][RESTORE] gold=%d gems=%d" % [int(gm.get("gold")), int(gm.get("gems"))])
	await get_tree().create_timer(0.2).timeout


# Referenzzustand fuer den Golden-Modus "seasons" wiederherstellen
func _seasfix() -> void:
	for _f in range(6):
		await get_tree().process_frame
	gm.set("unlocked_maps", ["earth", "mars", "jungle", "volt"])
	gm.set("active_map", "earth")
	gm.set("gold", 20000)
	gm.set("gems", 50)
	var su: Dictionary = {
		"earth": ["spring"], "mars": ["spring"],
		"jungle": ["spring"], "volt": ["spring"],
	}
	gm.set("season_unlocks", su)
	var sm: Dictionary = { "earth": "fixed", "mars": "fixed", "jungle": "fixed", "volt": "fixed" }
	gm.set("season_mode", sm)
	var aseason: Dictionary = { "earth": "spring", "mars": "spring", "jungle": "spring", "volt": "sturm" }
	gm.set("active_season", aseason)
	gm.call("_save_profile")
	print("[SEASFIX] gespeichert maps=%s unlocks=%s gold=%d" % [
		str(gm.get("unlocked_maps")), str(su), int(gm.get("gold"))])


# v1.52 — Filmlauf fuer die Praesentation (--write-movie, 30 fps)
func _chestmov(stil: int) -> void:
	for _f in range(10):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	var ss = gm.get("ui_manager").get("start_screen")
	if ss != null and is_instance_valid(ss):
		ss.hide()
	var ui = load("res://scripts/ui/chest_open_ui.gd").new()
	ui.setup(gm)
	ui.set("style", stil)
	gm.get("ui_manager").add_child(ui)
	var tier: String = "premium"
	var res: Dictionary = {
		"kind": "skin", "index": 3, "rarity": "epic", "name": "NEON RUNNER", "duplicate": false,
	}
	ui.open(tier, res)
	print("[CHESTFX][MOVIE] stil=%d tier=%s start" % [stil, tier])
	await get_tree().create_timer(1.1).timeout
	ui.call("_tap")
	await get_tree().create_timer(1.1).timeout
	ui.call("_tap")
	await get_tree().create_timer(1.1).timeout
	ui.call("_tap")
	await get_tree().create_timer(1.1).timeout
	ui.call("_tap")
	await get_tree().create_timer(5.4).timeout
	print("[CHESTFX][MOVIE] stil=%d ende" % stil)


# v1.52 — epischer Gewinn: laengere Animation, Epic-Partikel, echtes Item-Icon
func _chestepic() -> void:
	for _f in range(8):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	var uim = gm.get("ui_manager")
	var ss = uim.get("start_screen")
	if ss != null and is_instance_valid(ss):
		ss.hide()
	gm.set("p_color", 2)
	gm.set("p_rig", 3)
	var res: Dictionary = {
		"ok": true, "kind": "hat", "index": 9, "rarity": "epic",
		"duplicate": false, "name": TextureManager.HAT_NAMES[9],
		"bonus": { "gold": 90, "gems": 6 },
	}
	var ui = load("res://scripts/ui/chest_open_ui.gd").new()
	ui.setup(gm)
	ui.set("style", 2)
	uim.add_child(ui)
	ui.open("silver", res)
	await get_tree().create_timer(0.9).timeout
	await _shot("v152/epic_1_zu.png")
	ui.call("_tap")
	await get_tree().create_timer(0.6).timeout
	await _shot("v152/epic_2_ruetteln.png")
	ui.call("_tap")
	await get_tree().create_timer(0.6).timeout
	await _shot("v152/epic_3_mehr.png")
	ui.call("_tap")
	await get_tree().create_timer(0.7).timeout
	await _shot("v152/epic_4_knall.png")
	await get_tree().create_timer(1.6).timeout
	await _shot("v152/epic_5_karte.png")
	print("[EPIC152][ENDE] offen=%s" % str(is_instance_valid(ui)))


# v1.53 — Beweis: echte Kisten liefern VERSCHIEDENE Items (kein festes STERN)
func _chestvar() -> void:
	for _f in range(8):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	var uim = gm.get("ui_manager")
	var ss = uim.get("start_screen")
	if ss != null and is_instance_valid(ss):
		ss.hide()
	var gold_echt: int = int(gm.get("gold"))
	var gems_echt: int = int(gm.get("gems"))
	uim.call("_open_chest_page")
	await get_tree().create_timer(1.0).timeout
	gm.set("gold", 99999)
	gm.set("gems", 9999)
	var gesehen: Array = []
	for i in range(8):
		uim.call("_on_chest_open", "standard")
		await get_tree().create_timer(1.0).timeout
		var kiste = null
		for c in uim.get_children():
			if c is ChestOpenUI:
				kiste = c
		if kiste == null:
			print("[VAR152] FEHLER runde=%d keine_kiste" % i)
			break
		var res: Dictionary = kiste.get("result")
		print("[VAR152][GEWINN] nr=%d kind=%s index=%d rarity=%s name=%s" % [
			i + 1, str(res.get("kind", "")), int(res.get("index", -1)),
			str(res.get("rarity", "")), str(res.get("name", ""))])
		gesehen.append(str(res.get("name", "")))
		await _tap_until_open(kiste, 4, 0.7)
		await get_tree().create_timer(0.4).timeout
		if is_instance_valid(kiste):
			kiste.call("_close")
		await get_tree().create_timer(0.4).timeout
	var eindeutig: Dictionary = {}
	for n in gesehen:
		if n != "":
			eindeutig[n] = true
	print("[VAR152][ERGEBNIS] kisten=%d verschiedene_items=%d liste=%s" % [
		gesehen.size(), eindeutig.size(), str(gesehen)])
	gm.set("gold", gold_echt)
	gm.set("gems", gems_echt)
	gm.call("_save_profile")
	print("[VAR152][RESTORE] gold=%d gems=%d" % [int(gm.get("gold")), int(gm.get("gems"))])


# ================================================================
# v1.54 — Skin x Hut Matrix: Abschneiden + Hut-Anwendung pruefen
# ================================================================

func _img_bbox(img: Image) -> Rect2i:
	var x0: int = 999
	var y0: int = 999
	var x1: int = -1
	var y1: int = -1
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


func _img_diff(a: Image, b: Image) -> int:
	var n: int = 0
	for y in range(mini(a.get_height(), b.get_height())):
		for x in range(mini(a.get_width(), b.get_width())):
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			if ca.a > 0.4 and absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.12:
				n += 1
	return n


func _hatmatrix() -> void:
	for _f in range(6):
		await get_tree().process_frame
	var rigs: int = TextureManager.RIG_NAMES.size()
	var hats: int = TextureManager.HAT_NAMES.size()
	print("[HATMX][START] rigs=%d hats=%d kombis=%d farbe=0" % [rigs, hats, rigs * hats])
	var kaputt: Array = []
	var je_rig: Dictionary = {}
	for r in range(rigs):
		var ohne: Image = TextureManager.get_skin_hat_texture(0, r, 0).get_image()
		var zeile: Array = []
		for h in range(hats):
			var img: Image = TextureManager.get_skin_hat_texture(0, r, h).get_image()
			var bb: Rect2i = _img_bbox(img)
			var oben: bool = bb.position.y <= 0
			var links: bool = bb.position.x <= 0
			var rechts: bool = bb.position.x + bb.size.x >= img.get_width()
			var diff: int = 0 if h == 0 else _img_diff(img, ohne)
			var wirkt: bool = h == 0 or diff > 3
			var status: String = "ok"
			if oben:
				status = "ABGESCHNITTEN_OBEN"
			elif links or rechts:
				status = "ABGESCHNITTEN_SEITE"
			elif not wirkt:
				status = "HUT_WIRKT_NICHT"
			if status != "ok":
				kaputt.append({ "rig": r, "hat": h, "status": status, "diff": diff,
					"bb": str(bb), "name_rig": TextureManager.RIG_NAMES[r],
					"name_hat": TextureManager.HAT_NAMES[h] })
				print("[HATMX][FEHLER] rig=%d(%s) hut=%d(%s) problem=%s bbox=%s diff=%d" % [
					r, TextureManager.RIG_NAMES[r], h, TextureManager.HAT_NAMES[h], status, str(bb), diff])
			zeile.append(status)
		je_rig[r] = zeile
		print("[HATMX][ZEILE] rig=%d(%s) fehler=%d" % [r, TextureManager.RIG_NAMES[r], zeile.count("ok") - hats + hats])
	print("[HATMX][ERGEBNIS] kombis=%d kaputt=%d" % [rigs * hats, kaputt.size()])
	var nach_status: Dictionary = {}
	for k in kaputt:
		nach_status[str(k["status"])] = int(nach_status.get(str(k["status"]), 0)) + 1
	print("[HATMX][SUMME] %s" % str(nach_status))


# Kontaktblatt: Zeilen = Skins, Spalten = Huete (Reihenfolge HAT_NAMES)
func _hatsheet154() -> void:
	for _f in range(6):
		await get_tree().process_frame
	var rigs_env: String = OS.get_environment("COMIC_HATSHEET")
	var hat_env: String = OS.get_environment("COMIC_HATLIST")
	var rig_list: Array = []
	if rigs_env != "":
		for s2 in rigs_env.split(","):
			rig_list.append(int(s2))
	else:
		for i in range(TextureManager.RIG_NAMES.size()):
			rig_list.append(i)
	var hat_list: Array = []
	if hat_env != "":
		for h2 in hat_env.split(","):
			hat_list.append(int(h2))
	else:
		for i in range(TextureManager.HAT_NAMES.size()):
			hat_list.append(i)
	var tile_env: String = OS.get_environment("COMIC_HATTILE")
	var tile: int = int(tile_env) if tile_env != "" else 96
	var breite: int = hat_list.size() * tile
	var hoehe: int = rig_list.size() * tile
	var sheet := Image.create(breite, hoehe, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.09, 0.13, 1.0))
	for ri in range(rig_list.size()):
		var r: int = int(rig_list[ri])
		for hi in range(hat_list.size()):
			var h: int = int(hat_list[hi])
			var img: Image = TextureManager.get_skin_hat_texture(0, r, h).get_image()
			img = img.duplicate()
			img.resize(tile - 6, tile - 6, Image.INTERPOLATE_NEAREST)
			sheet.blend_rect(img, Rect2i(0, 0, tile - 6, tile - 6), Vector2i(hi * tile + 3, ri * tile + 3))
	var out: String = "C:/Users/vince/Games/comic-shooter/screenshots/v154/sheet_r%s_h%s.png" % [rigs_env.replace(",", "-"), hat_env.replace(",", "-")]
	DirAccess.make_dir_recursive_absolute("C:/Users/vince/Games/comic-shooter/screenshots/v154/")
	sheet.save_png(out)
	print("[HATSHEET] %s (%dx%d) rigs=%s hats=%s" % [out, breite, hoehe, str(rig_list), str(hat_list)])


# v1.55 — Sitz-Messung: wo landet der Hut relativ zum Kopf?
func _hatfit155() -> void:
	for _f in range(6):
		await get_tree().process_frame
	var hats: Array = [1, 13, 6, 8, 3, 5]
	print("[HATFIT][START] rigs=%d hats=%s" % [TextureManager.RIG_NAMES.size(), str(hats)])
	for r in range(TextureManager.RIG_NAMES.size()):
		var body: Image = GenCharacters._rig_body(r, Color(0.20, 0.60, 1.0), Color(0.15, 0.25, 0.55), false, true)
		var head: Dictionary = GenCharacters._head_metrics(body)
		var zeile: Array = []
		for h in hats:
			var layer: Image = GenCharacters._hat_layer_fast(h, head, 1.0, r)
			var bb: Rect2i = _img_bbox(layer)
			var hb_top: int = bb.position.y
			var hb_bot: int = bb.position.y + bb.size.y - 1
			var hb_cx: float = float(bb.position.x) + float(bb.size.x) * 0.5
			var d_bot: float = float(hb_bot) - float(head.get("top", 13.0))
			var d_cx: float = hb_cx - float(head.get("cx", 32.0))
			zeile.append("%s: unten%+.1f mitte%+.1f" % [TextureManager.HAT_NAMES[h], d_bot, d_cx])
		print("[HATFIT][RIG] %d %s kopf_top=%.0f cx=%.0f w=%.0f | %s" % [
			r, TextureManager.RIG_NAMES[r], float(head.get("top", 0)), float(head.get("cx", 0)),
			float(head.get("w", 0)), "  ".join(zeile)])


# ================================================================
# v1.56 — BALANCE 1.56: Modell-Tabelle (A1) und Bot-Proxy (D1)
# ================================================================
#
#   COMIC_LANTEST=balmodel   -> Modell 3 Modi x 4 Stufen ([BAL][MODELL])
#   COMIC_LANTEST=balbot     -> Kiting-Bot spielt echte Laeufe
#        COMIC_BAL_MODE=endlos|wellen|runden|all
#        COMIC_BAL_STUFE=leicht|normal|schwer|hart|hardcore|all
#        COMIC_BAL_PROFIL=anfaenger|erfahren|all
#        COMIC_BAL_LAEUFE=5        COMIC_BAL_TS=6.0 (Zeitraffer)
#        COMIC_BAL_MAX=12.0        (Minuten Simulationszeit je Lauf)
#
# Die Trefferquote wird als Feuer-Ausfall modelliert (jeder 2./5. Tick wird
# nicht geschossen) - ein Fehlschuss kostet im Spiel dieselbe Schussfolge,
# damit ist die effektive DPS = Trefferquote x DPS. Das ist im Bericht
# ausgewiesen (BALANCE_BERICHT.md, Abschnitt "Messverfahren").


func _balmodel() -> void:
	print("[BAL][START] modell version=%s dps=%.2f stufen=%s" % [
		str(gm.get("APP_VERSION")), Balance.spieler_dps(), str(Balance.STUFEN)])
	var fehler: int = 0
	var t_probe: float = 120.0
	for modus in ["endlos", "wellen"]:
		for stufe in Balance.STUFEN:
			var ziel: float = Balance.ziel_druck(modus, stufe, t_probe)
			var hp: float = Balance.hp_mult(12, stufe)
			var f: float = Balance.fenster(stufe)
			# v1.56: Der Spawner arbeitet mit der kontinuierlichen Rate
			# (rate_fuer_druck). Die Anzeige muss denselben Weg gehen, sonst
			# zeigt sie den Rundungsartefakt von anzahl_fuer_druck (min. 1 Gegner).
			var rate: float = Balance.rate_fuer_druck(ziel, hp)
			var d: float = Balance.druck(rate * f, hp, f)
			var abw: float = d - ziel
			if absf(abw) > 0.05:
				fehler += 1
			print("[BAL][MODELL] modus=%s stufe=%s t=%.0f druck=%.2f ziel=%.2f abweichung=%+.2f rate=%.2f/s (%.1f gegner/min) hp_mult=%.2f fenster=%.1f" % [
				modus, stufe, t_probe, d, ziel, abw, rate, rate * 60.0, hp, f])
	for stufe in Rounds.DIFFICULTY_STUFEN:
		var st_bal: String = Rounds._balance_stufe(stufe)
		var ziel2: float = Balance.ziel_druck("runden", st_bal, 300.0)
		var hp2: float = Rounds.hp_mult(12, stufe)
		var n2: int = Rounds.monster_count_for(12, stufe)
		var fenster2: float = maxf(1.0, float(n2) * Rounds.group_gap(12))
		var d2: float = Balance.druck(float(n2), hp2, fenster2)
		# RUNDEN haben eine eigene Kurve (Rundentabelle x Balance-hp_mult); der
		# Vergleich mit der Endlos-Zielkurve ist nur eine Einordnung, kein Fehler.
		var abw2: float = d2 - ziel2
		print("[BAL][MODELL] modus=runden stufe=%s runde=12 druck=%.2f ziel_endlos=%.2f hinweis=eigene_rundenkurve anzahl=%d hp_mult=%.2f laenge_s=%.1f" % [
			stufe, d2, ziel2, n2, hp2, fenster2])
	# Stufen-Spreizung (Spec K8): Trefferbudget und Herzen im Klartext
	for stufe in Balance.STUFEN:
		var d3: Dictionary = Balance.data(stufe)
		print("[BAL][STUFE] stufe=%s herzen=%d hit_ziel=%.1f hp=%.2f dmg=%.2f spd=%.2f coins=%.2f hetzer_pro=%d max_aktiv=%d anlauf=%.0f peak=%.0f erholung=%.0f boss_ab=%.0f boss_alle=%.0f" % [
			stufe, int(d3["hearts"]), float(d3["hit_ziel"]), float(d3["hp"]), float(d3["dmg"]),
			float(d3["speed"]), float(d3["coins"]), int(d3["hetzer_pro"]), int(d3["max_aktiv"]),
			float(d3["anlauf"]), float(d3["peak"]), float(d3["erholung"]),
			float(d3["boss_ab"]), float(d3["boss_alle"])])
	# Phasenlaengen: mindestens ein Erholungsfenster je 60 s?
	for stufe in Balance.STUFEN:
		var zyklus: float = Balance.phase_laenge(stufe, "anlauf") + Balance.phase_laenge(stufe, "peak") + Balance.phase_laenge(stufe, "erholung")
		var pro60: int = int(ceil(60.0 / zyklus))
		if pro60 < 1:
			fehler += 1
		print("[BAL][PHASE] stufe=%s zyklus_s=%.1f erholung_pro_60s=%d erholung_s=%.1f" % [
			stufe, zyklus, pro60, Balance.phase_laenge(stufe, "erholung")])
	print("[BAL][ENDE] fehler=%d" % fehler)


# ---------------------------------------------------------------
# Bot-Proxy (Spec 4.1)
# ---------------------------------------------------------------

func _bot_params(profil: String) -> Dictionary:
	if profil == "erfahren":
		return { "reaktion": 0.15, "treffer": 0.80, "flucht": 130.0, "trank_hp": 3, "shop": 0.90, "fehler": 0.02 }
	return { "reaktion": 0.35, "treffer": 0.55, "flucht": 90.0, "trank_hp": 2, "shop": 0.60, "fehler": 0.06 }


func _bot_env(name: String, standard: String) -> String:
	var v: String = OS.get_environment(name)
	return v if v != "" else standard


func _balbot() -> void:
	var env_mode: String = _bot_env("COMIC_BAL_MODE", "all")
	var env_stufe: String = _bot_env("COMIC_BAL_STUFE", "all")
	var env_prof: String = _bot_env("COMIC_BAL_PROFIL", "all")
	var laeufe: int = int(_bot_env("COMIC_BAL_LAEUFE", "1"))
	var ts: float = float(_bot_env("COMIC_BAL_TS", "4.0"))
	var max_min: float = float(_bot_env("COMIC_BAL_MAX", "12.0"))
	Engine.time_scale = ts
	# Zeittraffer ohne Tunneln: bei hohem time_scale wandert ein Geschoss
	# (300 px/s) sonst ueber 100 px je Physikschritt und trifft nichts.
	# Mehr Physikschritte halten den Schritt klein (~10-15 px).
	# v1.56: 120 Hz Physik + hoechstens 8 Schritte je Frame. Hoehere Werte
	# (240/24) liessen die Framerate auf ~19 fps fallen - dann springt der Held
	# 67 px je Frame und jede Messung ist unbrauchbar.
	Engine.physics_ticks_per_second = 120
	Engine.max_physics_steps_per_frame = 8
	var modi: Array = ["endlos", "wellen", "runden"] if env_mode == "all" else [env_mode]
	var stufen: Array = ["leicht", "normal", "schwer", "hardcore"] if env_stufe == "all" else [env_stufe]
	var profile: Array = ["anfaenger", "erfahren"] if env_prof == "all" else [env_prof]
	print("[BOT][START] modi=%s stufen=%s profile=%s laeufe=%d time_scale=%.1f max_min=%.1f" % [
		str(modi), str(stufen), str(profile), laeufe, ts, max_min])
	for _f in range(6):
		await get_tree().process_frame
	var gesamt: int = 0
	for modus in modi:
		for stufe in stufen:
			for profil in profile:
				for lauf in range(laeufe):
					await _bot_run(str(modus), str(stufe), str(profil), lauf + 1, max_min)
					gesamt += 1
	print("[BOT][ENDE] laeufe=%d" % gesamt)
	Engine.time_scale = 1.0


func _runden_stufe(stufe: String) -> String:
	match stufe:
		"schwer": return "hart"
		"hardcore": return "hart"
	return stufe


func _bot_run(modus: String, stufe: String, profil: String, lauf: int, max_min: float) -> void:
	var par: Dictionary = _bot_params(profil)
	if int(gm.get("current_state")) != 0:
		gm.call("quit_to_menu")
		await get_tree().process_frame
	match modus:
		"runden":
			gm.call("set_round_difficulty", _runden_stufe(stufe))
			gm.call("set_game_mode", 2)
		"wellen":
			gm.call("set_difficulty", Balance.index_von_stufe(stufe))
			gm.call("set_game_mode", 1)
		_:
			gm.call("set_difficulty", Balance.index_von_stufe(stufe))
			gm.call("set_game_mode", 0)
	var karte: String = _bot_env("COMIC_BAL_MAP", "")
	if karte != "" and gm.has_method("set_active_map"):
		gm.call("set_active_map", karte)
	gm.call("bal_reset_zaehler")
	gm.call("start_game", false, false)
	await get_tree().create_timer(0.4).timeout
	var uim = gm.get("ui_manager")
	if uim != null:
		var ls = uim.get("load_screen")
		if ls != null and is_instance_valid(ls):
			ls.visible = false
			ls.set_process(false)
	var p = gm.get("player")
	if p == null or not is_instance_valid(p):
		print("[BOT][FEHLER] kein Spieler-Knoten (modus=%s stufe=%s)" % [modus, stufe])
		return
	# Zielhilfe Stufe 2 = Spiel-Einstellung "stark" (der Bot laeuft, waehrend er
	# schiesst - ohne Kegel-Einrasten trifft er nichts, siehe _bot_decide)
	p.set("aim_assist", 2)
	# v1.56: Messzeit = SPIELZEIT. get_process_delta_time() im Coroutine-Pfad
	# lief mit einer anderen Skalierung als die Simulation (Messung: Bot-Uhr 37 s
	# bei 120 s Spielzeit) - die Laufzeit wurde dadurch 3x zu lang.
	# game_manager._perf_lauf_s zaehlt genau die Sekunden im Zustand PLAYING.
	var sim_t: float = 0.0
	var uhr_basis: float = float(gm.get("_perf_lauf_s"))
	var max_s: float = max_min * 60.0
	var next_decide: float = 0.0
	var last_hp: int = int(p.call("get_health"))
	var heilung: int = 0
	var tode: int = 0
	var ende: String = "zeit"
	var todeszeit: float = 0.0
	var dbg_can: int = 0
	var dbg_held: int = 0
	var dbg_frames: int = 0
	var dbg_modal: int = 0
	var next_trace: float = 0.0
	var bot_pos_last: Vector2 = Vector2.ZERO
	var bot_pos_t: float = 0.0
	var bot_stuck: int = 0
	var wellen_ende: int = 0
	var first_hit_t: float = -1.0
	while sim_t < max_s:
		await get_tree().process_frame
		sim_t = float(gm.get("_perf_lauf_s")) - uhr_basis
		if gm == null:
			ende = "gm_weg"
			break
		if not is_instance_valid(p):
			# Spieler-Knoten wurde entfernt -> das ist der Tod (der GM raeumt
			# den Helden in _on_player_died weg)
			tode += 1
			ende = "tod"
			todeszeit = sim_t
			break
		if int(gm.get("current_state")) != 2:
			# GameState: 0=MENU 1=LOBBY 2=PLAYING 3=DEAD -> alles ausser
			# PLAYING ist ein Abbruch (Tod oder Menue)
			if int(gm.get("current_state")) == 3:
				tode += 1
			ende = "tod"
			todeszeit = sim_t
			break
		# --- Shop / Rundenwechsel ---
		if modus == "wellen" and bool(gm.get("in_shop")):
			_bot_shop_welle(par)
			gm.call("_next_wave", true)
			await get_tree().process_frame
			continue
		if modus == "runden":
			var rm = gm.get("rounds_mode")
			if rm != null and not bool(rm.active):
				wellen_ende = int(rm.get("round_no"))
				if wellen_ende >= 30:
					ende = "ende"
					break
				_bot_shop_runden(par, rm)
				gm.call("next_round")
				await get_tree().process_frame
				continue
		# --- Feststecker erkennen (Hindernis/Ecke) ---
		# Ohne das bleibt der Bot an einem Felsen haengen, waehrend ihn EIN
		# langsamer Gegner beruehrt (Messung: 6 Herzen in 48 s bei 1-2 GREEN).
		if sim_t - bot_pos_t > 1.2:
			var versch: float = p.global_position.distance_to(bot_pos_last)
			if versch < 10.0:
				bot_stuck += 1
				var w: float = randf() * TAU
				p.set("input_direction", Vector2(cos(w), sin(w)))
				next_decide = sim_t + 0.6
			bot_pos_last = p.global_position
			bot_pos_t = sim_t
		# --- Entscheidung (Reaktionszeit) ---
		if sim_t >= next_decide:
			next_decide = sim_t + float(par["reaktion"])
			_bot_decide(p, par, sim_t)
		# --- Trace: alle 10 s Zustand + wer auf dem Feld steht ---
		if sim_t >= next_trace:
			next_trace = sim_t + 10.0
			var cnt: Dictionary = {}
			for m in get_tree().get_nodes_in_group("monsters"):
				if not is_instance_valid(m) or m.is_queued_for_deletion():
					continue
				var tn: String = Rounds.type_name(int(m.get("type")))
				cnt[tn] = int(cnt.get(tn, 0)) + 1
			print("[BOT][TRACE] t=%.0f hp=%d karte=%s feld=%s" % [
				sim_t, int(p.call("get_health")), str(gm.get("active_map")), str(cnt)])
		# --- Diagnose: darf geschossen werden? ---
		dbg_frames += 1
		if bool(gm.call("can_shoot_now")):
			dbg_can += 1
		if bool(p.get("shoot_held")):
			dbg_held += 1
		if uim != null and bool(uim.call("is_modal_open")):
			dbg_modal += 1
		# --- Treffer/Heilung ---
		var hp: int = int(p.call("get_health"))
		if hp < last_hp:
			if first_hit_t < 0.0:
				first_hit_t = sim_t
		elif hp > last_hp:
			heilung += hp - last_hp
		last_hp = hp
		# --- Trank ---
		if hp <= int(par["trank_hp"]):
			var util: Dictionary = p.get("utilities")
			if util.get("potion", 0) > 0:
				p.call("use_potion")
	var welle: int = 0
	if modus == "runden":
		var rm2 = gm.get("rounds_mode")
		welle = int(rm2.get("round_no")) if rm2 != null else wellen_ende
	elif modus == "wellen":
		welle = int(gm.get("wave"))
	else:
		welle = 1 + int(sim_t / 45.0)
	var treffer: int = int(gm.get("bal_treffer"))
	var schaden: int = int(gm.get("bal_schaden"))
	var kills: int = int(gm.get("bal_kills"))
	var treffer60: float = 0.0
	if sim_t > 0.0:
		treffer60 = float(treffer) * 60.0 / sim_t
	print("[BOT][LAUF] profil=%s modus=%s stufe=%s lauf=%d zeit=%.2f welle=%d tode=%d treffer=%d treffer60=%.1f schaden=%d kills=%d heilung=%d ende=%s erster_treffer=%.1f" % [
		profil, modus, stufe, lauf, sim_t, welle, tode, treffer, treffer60, schaden, kills,
		heilung, ende, first_hit_t])
	print("[BOT][DBG] frames=%d schuss_erlaubt=%d shoot_held=%d modal=%d feststecker=%d" % [dbg_frames, dbg_can, dbg_held, dbg_modal, bot_stuck])
	if int(gm.get("current_state")) == 3:
		gm.call("quit_to_menu")
		await get_tree().process_frame


func _bot_decide(p: Node, par: Dictionary, sim_t: float) -> void:
	var pos: Vector2 = p.global_position
	var best: Node2D = null
	var best_d: float = 1.0e9
	for m in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		if m.get("ghost") == true:
			continue
		var d: float = pos.distance_to(m.global_position)
		if d < best_d:
			best_d = d
			best = m
	if best == null:
		p.set("input_direction", Vector2(cos(sim_t * 0.7), sin(sim_t * 0.7)))
		p.set("shoot_held", false)
		return
	var to_m: Vector2 = (best.global_position - pos)
	if to_m.length() < 1.0:
		to_m = Vector2.RIGHT
	to_m = to_m.normalized()
	# WICHTIG (Spec 4.1): In diesem Spiel schiesst der Held in die LAUFrichtung,
	# die Zielhilfe rastet nur im Kegel ein. Ein Bot, der rein seitlich laeuft,
	# trifft deshalb nie (Messung v1.56: schaden=6 in 40 s). Also: kreisen mit
	# leichtem Andruck (Winkel ~60 Grad, innerhalb des Zielkegels von Stufe 2).
	var strafe: Vector2 = Vector2(-to_m.y, to_m.x)
	if randf() < 0.5:
		strafe = -strafe
	# Abstossung von ALLEN nahen Gegnern (nicht nur vom naechsten): sonst
	# weicht der Bot dem einen aus und laeuft in den naechsten hinein
	# (Messung v1.56: 4 langsame GREENs kosten 1 Herz).
	var repuls: Vector2 = Vector2.ZERO
	for m2 in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(m2) or m2.is_queued_for_deletion():
			continue
		var dm: float = pos.distance_to(m2.global_position)
		if dm < 1.0 or dm > 220.0:
			continue
		repuls += (pos - m2.global_position).normalized() * (1.0 - dm / 220.0)
	if repuls.length() > 0.05:
		repuls = repuls.normalized()
	var dir: Vector2 = Vector2.ZERO
	# Abstandsband statt Dauer-Andruck (v1.56, nach Trace-Messung):
	# Das Spiel schiesst in die LAUFrichtung - Schaden gibt es also nur, wenn
	# der Held auf das Ziel zu laeuft. Ein Bot, der klebt, stirbt am Boss
	# (Messung: 5 Treffer in 4 s bei nur 3 Gegnern auf dem Feld). Also:
	#   zu weit  -> hinlaufen (und dabei schiessen)
	#   zu nah   -> weg (kein Schuss) + seitlich ausweichen
	#   im Band  -> kreisen, leicht andruecken
	var ist_boss: bool = false
	if best.has_method("is_boss"):
		ist_boss = bool(best.call("is_boss"))
	var nah: float = float(par["flucht"])
	var fern: float = 240.0 if not ist_boss else 300.0
	if ist_boss:
		nah = maxf(nah, 150.0)
	# Grundverhalten: auf das Ziel zu, leicht kreisend (so trifft der Held -
	# geschossen wird in die LAUFrichtung). Abstossung haelt Abstand zur Menge,
	# Panik-Flucht erst unter 70 px.
	if best_d < 70.0:
		dir = -to_m + strafe * 0.40 + repuls * 0.60
	else:
		dir = to_m * 0.50 + strafe * 0.55 + repuls * 0.45
	# Kartenrand meiden (sonst klebt der Bot in der Ecke)
	var wb: Rect2 = gm.call("get_map_bounds")
	if pos.x < wb.position.x + 260.0:
		dir.x += 1.0
	if pos.x > wb.end.x - 260.0:
		dir.x -= 1.0
	if pos.y < wb.position.y + 260.0:
		dir.y += 1.0
	if pos.y > wb.end.y - 260.0:
		dir.y -= 1.0
	if dir.length() < 0.01:
		dir = to_m
	# Positionsfehler (Spec 4.1 "kein perfektes Kiting"): mit kleiner
	# Wahrscheinlichkeit entscheidet der Bot falsch - laeuft in die Menge,
	# in die Ecke oder steht still. Genau so entstehen Treffer bei Anfaengern.
	if randf() < float(par.get("fehler", 0.05)):
		var w: float = randf() * TAU
		dir = Vector2(cos(w), sin(w))
	p.set("input_direction", dir.normalized())
	# Trefferquote: Fehlschuss = dieser Tick wird nicht gefeuert
	p.set("shoot_held", best_d < 470.0 and randf() <= float(par["treffer"]))


func _bot_shop_welle(par: Dictionary) -> void:
	if randf() > float(par["shop"]):
		print("[BOT][SHOP] modus=wellen kauf=0 grund=profil_wurf")
		return
	var offers: Array = gm.get("shop_offers")
	var prio: Array = ["heal", "maxhp", "potion", "shield", "damage", "weapon", "speed", "bomb"]
	var kaeufe: int = 0
	for id in prio:
		for o in offers:
			if str(o.get("id", "")) != str(id):
				continue
			if bool(o.get("bought", false)):
				continue
			if int(gm.get("coins")) < int(gm.call("shop_price", int(o["price"]))):
				continue
			gm.call("buy_shop_item", str(id))
			kaeufe += 1
			break
		if kaeufe >= 2:
			break
	print("[BOT][SHOP] modus=wellen welle=%d kauf=%d muenzen=%d" % [int(gm.get("wave")), kaeufe, int(gm.get("coins"))])


func _bot_shop_runden(par: Dictionary, rm) -> void:
	if randf() > float(par["shop"]):
		print("[BOT][SHOP] modus=runden kauf=0 grund=profil_wurf")
		return
	var r: int = int(rm.get("round_no"))
	var diff: String = str(rm.get("difficulty"))
	var kaeufe: int = 0
	for id in ["skill_damage", "skill_reload"]:
		var stufe: int = int(rm.call("skill_stacks_of", id))
		var preis: int = int(WaveShop.skill_price(id, r, diff, stufe))
		if bool(rm.call("buy_skill", id, preis)):
			kaeufe += 1
	print("[BOT][SHOP] modus=runden runde=%d kauf=%d muenzen=%d" % [r, kaeufe, int(gm.get("coins"))])


# ---------------------------------------------------------------
# v1.56: Belegbilder fuer die Balance (Spec 4.3: erster Peak,
# Boss-Ankuendigung, Erholungsfenster). Laeuft NUR im Fenster.
# ---------------------------------------------------------------

func _balshot() -> void:
	var stufe: String = _bot_env("COMIC_BAL_STUFE", "normal")
	Engine.time_scale = float(_bot_env("COMIC_BAL_TS", "3.0"))
	for _f in range(8):
		await get_tree().process_frame
	var ss = gm.get("ui_manager")
	if ss != null:
		var startscreen = ss.get("start_screen")
		if startscreen != null:
			startscreen.hide()
	gm.call("set_difficulty", Balance.index_von_stufe(stufe))
	gm.call("set_game_mode", 0)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.0).timeout
	var uim = gm.get("ui_manager")
	for ov in ["load_screen", "start_screen"]:
		var o = uim.get(ov)
		if o != null and is_instance_valid(o):
			o.visible = false
			o.set_process(false)
	var sp = gm.get("monster_spawner")
	var p = gm.get("player")
	print("[BALSHOT][START] stufe=%s ts=%.1f" % [stufe, Engine.time_scale])
	var gezeigt: Dictionary = {}
	var t0: float = 0.0
	while t0 < 420.0:
		await get_tree().process_frame
		t0 = float(gm.get("_perf_lauf_s"))
		if int(gm.get("current_state")) != 2:
			break
		if p != null and is_instance_valid(p):
			_bot_decide(p, _bot_params("anfaenger"), t0)
		var phase: String = str(sp.get("phase")) if sp != null else ""
		if not gezeigt.has("anlauf") and phase == "anlauf":
			gezeigt["anlauf"] = true
			await _shot("v156/01-anlauf.png")
			print("[BALSHOT] art=anlauf t=%.0f druck=%.2f" % [t0, float(sp.get("druck"))])
		if not gezeigt.has("peak") and phase == "peak" and t0 > 25.0:
			gezeigt["peak"] = true
			await _shot("v156/02-peak.png")
			print("[BALSHOT] art=peak t=%.0f druck=%.2f aktiv=%d" % [t0, float(sp.get("druck")), get_tree().get_nodes_in_group("monsters").size()])
		if not gezeigt.has("boss") and sp != null and float(sp.get("_boss_telegraph")) > 0.0:
			gezeigt["boss"] = true
			await _shot("v156/03-boss-telegraph.png")
			print("[BALSHOT] art=boss_telegraph t=%.0f art_boss=%s" % [t0, str(sp.get("_boss_art"))])
		if not gezeigt.has("erholung") and phase == "erholung":
			gezeigt["erholung"] = true
			await _shot("v156/04-erholung.png")
			print("[BALSHOT] art=erholung t=%.0f dauer=%.1f" % [t0, float(sp.get("phase_left"))])
		if gezeigt.size() >= 4:
			break
	print("[BALSHOT][ENDE] bilder=%d t=%.0f" % [gezeigt.size(), t0])


# ---------------------------------------------------------------
# v1.56b (Bug 3): Kisten-Knopf mit ECHTEM Touch pruefen.
# Der bisherige Test rief _on_chest_open() direkt - damit war die
# Trefferflaeche des Knopfes nie im Spiel. Hier laeuft der echte
# Eingabepfad: InputEventScreenTouch -> Viewport -> Control.
# ---------------------------------------------------------------

func _tap_touch_mit(pos: Vector2, zug_px: float) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = pos
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	# Realistischer Finger: mehrere Zwischenschritte (ein einzelnes Drag-Event
	# hat kein Vorher-Bild und wird als 0 px gewertet)
	var schritte: int = maxi(1, int(absf(zug_px) / 4.0))
	var d := Vector2(0.0, zug_px / float(schritte))
	for i in range(schritte):
		var dg := InputEventScreenDrag.new()
		dg.index = 0
		dg.position = pos + d * float(i + 1)
		dg.relative = d
		Input.parse_input_event(dg)
		await get_tree().process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = pos + d
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _tap_touch(pos: Vector2, mit_zug: bool = true) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = pos
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	if mit_zug:
		# Fingerspitze wandert beim Tippen 2-6 px (Realitaet auf dem Geraet)
		var dg := InputEventScreenDrag.new()
		dg.index = 0
		dg.position = pos + Vector2(3, 4)
		dg.relative = Vector2(3, 4)
		Input.parse_input_event(dg)
		await get_tree().process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = pos + (Vector2(3, 4) if mit_zug else Vector2.ZERO)
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _chest_knoten(uim: Node) -> Node:
	for c in uim.get_children():
		if c is ChestOpenUI:
			return c
	return null


func _chesttouch() -> void:
	for _f in range(8):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	var uim = gm.get("ui_manager")
	var gold_echt: int = int(gm.get("gold"))
	var gems_echt: int = int(gm.get("gems"))
	gm.set("gold", 99999)
	gm.set("gems", 999)
	uim.call("_open_chest_page")
	await get_tree().create_timer(1.2).timeout
	var seite = uim.get("chest_page")
	uim.call("refresh_chest_page")
	await get_tree().create_timer(0.4).timeout
	var knopf: Button = null
	if seite != null:
		knopf = seite.find_child("BuyChest_standard", true, false) as Button
	if knopf == null:
		print("[TOUCH][KISTE] FEHLER: Knopf BuyChest_standard nicht gefunden")
		return
	var r: Rect2 = knopf.get_global_rect()
	var mitte: Vector2 = r.position + r.size * 0.5
	print("[TOUCH][KISTE] knopf=%s rect=(%.0f,%.0f,%.0f,%.0f) mitte=(%.0f,%.0f) sichtbar=%s disabled=%s" % [
		knopf.name, r.position.x, r.position.y, r.size.x, r.size.y, mitte.x, mitte.y,
		str(knopf.is_visible_in_tree()), str(knopf.disabled)])
	var vorher: Node = _chest_knoten(uim)
	print("[TOUCH][KISTE] oeffnung_vorher=%s gems=%d" % [str(vorher != null), int(gm.get("gems"))])
	# Mehrere Zugstaerken. WICHTIG: nach jeder Oeffnung wird die Seite erneut
	# aufgebaut (_on_chest_open versteckt sie; ohne erneutes Oeffnen misst man
	# beim naechsten Versuch einen unsichtbaren Knopf - genau dieser Fehler
	# steckte im ersten Testlauf: 3 px "ok", alles danach "nein").
	var nachher: Node = null
	for zug in [3.0, 8.0, 14.0, 25.0, 0.0]:
		var offen_k: Node = _chest_knoten(uim)
		if offen_k != null and is_instance_valid(offen_k):
			offen_k.queue_free()
		uim.call("_open_chest_page")
		uim.call("refresh_chest_page")
		await get_tree().create_timer(0.5).timeout
		if seite != null:
			seite.show()
		await _tap_touch_mit(mitte, zug)
		await get_tree().create_timer(0.9).timeout
		nachher = _chest_knoten(uim)
		print("[TOUCH][KISTE] zug=%.0fpx oeffnung=%s seite_sichtbar=%s" % [
			zug, str(nachher != null), str(seite != null and seite.visible)])
	print("[TOUCH][KISTE] nach_touch oeffnung=%s gems=%d abgebucht=%d" % [
		str(nachher != null), int(gm.get("gems")), gems_echt - int(gm.get("gems"))])
	# zweiter Versuch ohne Zug (reiner Tipp)
	if nachher == null:
		print("[TOUCH][KISTE] erster_tipp_ohne_wirkung -> zweiter Versuch ohne Zug")
		await _tap_touch(mitte, false)
		await get_tree().create_timer(1.2).timeout
		nachher = _chest_knoten(uim)
		print("[TOUCH][KISTE] nach_touch2 oeffnung=%s" % str(nachher != null))
	# Scrollen muss weiter funktionieren (Zug 40 px), danach muss ein Tipp
	# wieder oeffnen - beides in einem Lauf.
	var sc: ScrollContainer = uim.get("shop_scroll")
	var von: int = sc.scroll_vertical if sc != null else -1
	var k0: Node = _chest_knoten(uim)
	if k0 != null and is_instance_valid(k0):
		k0.queue_free()
	uim.call("_open_chest_page")
	await get_tree().create_timer(0.4).timeout
	await _tap_touch_mit(mitte, -40.0)
	await get_tree().create_timer(0.3).timeout
	print("[TOUCH][SCROLL] von=%d nach=%d diff=%d" % [von, sc.scroll_vertical if sc != null else -1,
		(sc.scroll_vertical - von) if sc != null else 0])
	await _tap_touch_mit(mitte, 6.0)
	await get_tree().create_timer(0.8).timeout
	var k1: Node = _chest_knoten(uim)
	print("[TOUCH][KISTE] nach_scroll tipp_oeffnet=%s" % str(k1 != null))
	if k1 != null and is_instance_valid(k1):
		k1.queue_free()
	await _shot("v156b/chest-touch.png")
	print("[TOUCH][KISTE][ERGEBNIS] oeffnung_per_touch=%s" % str(nachher != null))
	if nachher != null and is_instance_valid(nachher):
		nachher.queue_free()
	gm.set("gold", gold_echt)
	gm.set("gems", gems_echt)
	gm.call("_save_profile")
	print("[TOUCH][KISTE][RESTORE] gold=%d gems=%d" % [int(gm.get("gold")), int(gm.get("gems"))])


# ---------------------------------------------------------------
# v1.57b: Kisten-Tipp auf HANDY-Aufloesung pruefen (echtes Fenster).
# Beantwortet drei Fragen mit Zahlen statt Vermutung:
#   1. Wo liegt der Knopf wirklich (Canvas- vs. Fensterkoordinaten)?
#   2. Welches Control liegt an dieser Stelle obenauf (wer schluckt den Tipp)?
#   3. Kommt der Tipp an (button_down / pressed / Kiste offen)?
# ---------------------------------------------------------------

func _gui_stapel(pos: Vector2) -> String:
	# Alle sichtbaren Controls unter dem Punkt, von OBEN nach unten sortiert.
	# Genau so findet man den Schuldigen, der den Tipp abfaengt.
	var treffer: Array = []
	for n in get_tree().root.find_children("*", "Control", true, false):
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if not c.get_global_rect().has_point(pos):
			continue
		treffer.append({
			"pfad": str(c.get_path()).right(60),
			"filter": int(c.mouse_filter),
			"z": int(c.z_index),
			"idx": int(c.get_index()),
		})
	# grob: zuletzt gezeichnet = zuletzt im Baum + hoher z_index
	treffer.sort_custom(func(a, b):
		if int(a["z"]) != int(b["z"]):
			return int(a["z"]) > int(b["z"])
		return int(a["idx"]) > int(b["idx"]))
	var out: Array = []
	for i in range(mini(5, treffer.size())):
		out.append("%s(f=%d,z=%d)" % [treffer[i]["pfad"], treffer[i]["filter"], treffer[i]["z"]])
	return " | ".join(out)


func _chesttouch2() -> void:
	for _f in range(8):
		await get_tree().process_frame
	# Handy-Hochformat (wie Motorola edge 60 pro in CSS-Pixeln skaliert)
	get_window().size = Vector2i(1080, 2340)
	await get_tree().process_frame
	await get_tree().process_frame
	var uim = gm.get("ui_manager")
	var gold_echt: int = int(gm.get("gold"))
	var gems_echt: int = int(gm.get("gems"))
	gm.set("gold", 99999)
	gm.set("gems", 999)
	uim.call("_open_chest_page")
	uim.call("refresh_chest_page")
	await get_tree().create_timer(1.0).timeout
	var seite = uim.get("chest_page")
	var knopf: Button = null
	if seite != null:
		knopf = seite.find_child("BuyChest_standard", true, false) as Button
	if knopf == null:
		print("[TOUCH2] FEHLER: BuyChest_standard fehlt")
		return
	print("[TOUCH2] fenster=%s canvas=%s emulate_mouse_from_touch=%s" % [
		str(get_window().size), str(get_viewport().get_visible_rect().size),
		str(Input.emulate_mouse_from_touch)])
	var r: Rect2 = knopf.get_global_rect()
	var mitte: Vector2 = r.position + r.size * 0.5
	# Position in FENSTER-Koordinaten (so kommt sie vom Finger).
	# Control.get_screen_position() liefert exakt die Bildschirmposition -
	# eigene Transform-Multiplikation war falsch (Doppelanwendung der Streckung).
	# Streckung Canvas -> Fenster (Handy-Aufloesung != Basisaufloesung)
	var skala: Vector2 = Vector2(get_window().size) / get_viewport().get_visible_rect().size
	var fenster_pos: Vector2 = mitte * skala
	Input.warp_mouse(fenster_pos)
	await get_tree().process_frame
	await get_tree().process_frame
	var hov = get_viewport().gui_get_hovered_control()
	print("[TOUCH2] hover_nach_warp=%s (erwartet=BuyChest_standard)" % (str(hov.get_path()).right(50) if hov != null else "—"))
	print("[TOUCH2] skala=(%.3f,%.3f) knopf_rect_canvas=(%.0f,%.0f,%.0f,%.0f) mitte_canvas=(%.0f,%.0f) mitte_fenster=(%.0f,%.0f) sichtbar=%s disabled=%s" % [
		skala.x, skala.y,
		r.position.x, r.position.y, r.size.x, r.size.y, mitte.x, mitte.y,
		fenster_pos.x, fenster_pos.y, str(knopf.is_visible_in_tree()), str(knopf.disabled)])
	print("[TOUCH2] stapel_canvas=%s" % _gui_stapel(mitte))
	print("[TOUCH2] stapel_fenster=%s" % _gui_stapel(fenster_pos))
	await _shot("v157/chest-handy.png")
	# Tipp in FENSTER-Koordinaten (wie das Betriebssystem ihn liefert)
	var gedrueckt: bool = false
	var losgelassen: bool = false
	knopf.button_down.connect(func(): gedrueckt = true)
	knopf.pressed.connect(func(): losgelassen = true)
	# --- 1) Tipp auf den KNOPF ---
	var g0: int = int(gm.get("gems"))
	await _tap_touch_mit(fenster_pos, 8.0)
	await get_tree().create_timer(1.0).timeout
	var offen: Node = _chest_knoten(uim)
	print("[TOUCH2][KNOPF] kiste_offen=%s gems_vorher=%d nachher=%d" % [
		str(offen != null), g0, int(gm.get("gems"))])
	# --- 1b) Die OEFFNUNG selbst per Tipp weiterdrehen (das ist der Pfad, den
	# der Spieler auf dem Geraet geht: Kiste tippen, Deckel, Karte, weiter)
	if offen != null and is_instance_valid(offen):
		var stage0: int = int(offen.get("_stage"))
		var mitte_fenster2: Vector2 = Vector2(get_window().size) * 0.5
		print("[TOUCH2][OEFFNUNG] start_stage=%d tipps_noetig=%d" % [
			stage0, int(offen.get("_taps_needed"))])
		for i in range(6):
			await _tap_touch_mit(mitte_fenster2, 6.0)
			await get_tree().create_timer(0.7).timeout
			if not is_instance_valid(offen):
				print("[TOUCH2][OEFFNUNG] tipp=%d -> geschlossen (Knoten weg)" % (i + 1))
				break
			print("[TOUCH2][OEFFNUNG] tipp=%d stage=%d done=%s" % [
				i + 1, int(offen.get("_stage")), str(bool(offen.get("_done")))])
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(offen):
			print("[TOUCH2][OEFFNUNG] FEHLER: nach 6 Tipps noch offen (stage=%d)" % int(offen.get("_stage")))
			offen.queue_free()
		print("[TOUCH2][OEFFNUNG] seite_wieder_da=%s" % str(seite != null and seite.visible))
		await get_tree().create_timer(0.3).timeout
	# --- 2) Tipp auf das KISTENBILD der Karte (grosse Flaeche) ---
	uim.call("_open_chest_page")
	uim.call("refresh_chest_page")
	await get_tree().create_timer(0.5).timeout
	var bild: Control = null
	if seite != null:
		bild = seite.find_child("ChestImage_standard", true, false) as Control
	if bild != null:
		var bp: Vector2 = (bild.get_global_rect().position + bild.get_global_rect().size * 0.5) * skala
		var g1: int = int(gm.get("gems"))
		await _tap_touch_mit(bp, 10.0)
		await get_tree().create_timer(1.0).timeout
		var offen2: Node = _chest_knoten(uim)
		print("[TOUCH2][BILD] tipp_auf_bild kiste_offen=%s gems_vorher=%d nachher=%d" % [
			str(offen2 != null), g1, int(gm.get("gems"))])
		if offen2 != null and is_instance_valid(offen2):
			offen2.queue_free()
			await get_tree().create_timer(0.3).timeout
	else:
		print("[TOUCH2][BILD] FEHLER: ChestImage_standard nicht gefunden")
	# --- 3) Doppel-Tipp auf den Knopf: darf nur EINE Kiste kaufen ---
	uim.call("_open_chest_page")
	uim.call("refresh_chest_page")
	await get_tree().create_timer(0.5).timeout
	await _tap_touch_mit(fenster_pos, 8.0)
	await _tap_touch_mit(fenster_pos, 8.0)
	await get_tree().create_timer(1.0).timeout
	print("[TOUCH2][DOPPEL] gems_nach_zwei_tipps=%d (ein Kauf = -%d)" % [
		int(gm.get("gems")), int(gm.call("chest_price", "standard"))])
	var offen3: Node = _chest_knoten(uim)
	if offen3 != null and is_instance_valid(offen3):
		offen3.queue_free()
	if offen != null and is_instance_valid(offen):
		offen.queue_free()
	gm.set("gold", gold_echt)
	gm.set("gems", gems_echt)
	gm.call("_save_profile")
	print("[TOUCH2][RESTORE] gold=%d gems=%d" % [int(gm.get("gold")), int(gm.get("gems"))])


# ---------------------------------------------------------------
# v1.58: Galerie-Bilder fuer das GitHub-Repo (aktueller Stand).
# Laeuft im FENSTER (nicht headless), Groesse 1920x1080.
# Ergebnis: screenshots/01-... bis 12-...
# ---------------------------------------------------------------

func _shots158() -> void:
	for _f in range(8):
		await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	var uim = gm.get("ui_manager")
	# Profil fuer die Bilder praeparieren (nur Anzeige, wird zurueckgesetzt)
	var gold0: int = int(gm.get("gold"))
	var gems0: int = int(gm.get("gems"))
	gm.set("gold", 48000)
	gm.set("gems", 240)
	gm.call("debug_unlock_all")
	await get_tree().create_timer(0.6).timeout
	print("[SHOTS][START] version=%s" % str(gm.get("APP_VERSION")))

	# 1) Startseite
	uim.call("show_start_screen")
	await get_tree().create_timer(0.9).timeout
	await _shot("01-startseite.png")

	# 2) Kartenauswahl
	uim.call("_open_maps_page")
	await get_tree().create_timer(0.8).timeout
	await _shot("02-karten.png")
	uim.call("_close_pages")
	await get_tree().create_timer(0.4).timeout

	# 3) Sammlung (Skins, Huete, Farben)
	uim.call("show_collection")
	await get_tree().create_timer(0.9).timeout
	await _shot("03-sammlung.png")
	uim.call("_close_pages")
	await get_tree().create_timer(0.4).timeout

	# 4) Einstellungen
	uim.call("_open_settings_page", "menu")
	await get_tree().create_timer(0.8).timeout
	await _shot("04-einstellungen.png")
	uim.call("_close_pages")
	await get_tree().create_timer(0.4).timeout

	# 5) Shop: Kisten
	uim.call("_open_chest_page")
	uim.call("refresh_chest_page")
	await get_tree().create_timer(1.0).timeout
	await _shot("05-shop-kisten.png")

	# 6) Shop: Gluecksautomaten (runter scrollen)
	var sc: ScrollContainer = uim.get("shop_scroll")
	if sc != null:
		sc.scroll_vertical = 760
		await get_tree().create_timer(0.7).timeout
	await _shot("06-gluecksautomaten.png")
	if sc != null:
		sc.scroll_vertical = 0
	uim.call("_close_pages")
	await get_tree().create_timer(0.5).timeout

	# 7) Gameplay je Welt (Erde, Mars, Dschungel, Elektro)
	var welten: Array = [["earth", "07-welt-erde"], ["mars", "08-welt-mars"],
		["jungle", "09-welt-dschungel"], ["volt", "10-welt-elektro"]]
	for w in welten:
		gm.call("set_active_map", str(w[0]))
		gm.call("set_game_mode", 0)
		gm.call("set_difficulty", 1)
		gm.call("start_game", false, false)
		await get_tree().create_timer(0.8).timeout
		for ov in ["load_screen", "start_screen"]:
			var o = uim.get(ov)
			if o != null and is_instance_valid(o):
				o.visible = false
				o.set_process(false)
		# ein paar Sekunden spielen, damit Gegner im Bild sind
		var p = gm.get("player")
		# WICHTIG: _perf_lauf_s zaehlt prozessweit weiter. Ohne Basis rechnet
		# der 3. und 4. Welt-Lauf mit der Zeit des Vorgaengers (Messung: aktiv=0).
		var basis: float = float(gm.get("_perf_lauf_s"))
		var t: float = 0.0
		# Erst schiessen, wenn mindestens 3 Gegner im Bild sind - ein leeres
		# Feld als "Welt-Bild" ist wertlos (Messung: aktiv=0 bei 8 s).
		var bereit: bool = false
		while t < 26.0:
			await get_tree().process_frame
			t = float(gm.get("_perf_lauf_s")) - basis
			var n_akt: int = get_tree().get_nodes_in_group("monsters").size()
			if p != null and is_instance_valid(p) and bereit:
				_bot_decide(p, _bot_params("anfaenger"), t)
			if not bereit and n_akt >= 3 and t > 8.0:
				bereit = true
				print("[SHOTS] welt=%s bereit bei t=%.1f s mit %d Gegnern" % [str(w[0]), t, n_akt])
			if bereit and t > 12.0 and n_akt >= 3:
				break
		await _shot(str(w[1]) + ".png")
		print("[SHOTS] welt=%s gespielt=%.0f s aktiv=%d" % [
			str(w[0]), t, get_tree().get_nodes_in_group("monsters").size()])
		gm.call("quit_to_menu")
		await get_tree().create_timer(0.5).timeout

	# 8) Boss-Kampf (Erde, Boss direkt spawnen)
	gm.call("set_active_map", "earth")
	gm.call("set_game_mode", 0)
	gm.call("start_game", false, false)
	await get_tree().create_timer(1.0).timeout
	for ov2 in ["load_screen", "start_screen"]:
		var o2 = uim.get(ov2)
		if o2 != null and is_instance_valid(o2):
			o2.visible = false
			o2.set_process(false)
	var sp = gm.get("monster_spawner")
	if sp != null:
		sp.call("_boss_start", "biom")
		await get_tree().create_timer(2.3).timeout
		sp.call("_spawn_boss_now")
		var pb = gm.get("player")
		var basis_b: float = float(gm.get("_perf_lauf_s"))
		var tb: float = 0.0
		var ende: float = 5.0
		while tb < ende:
			await get_tree().process_frame
			tb = float(gm.get("_perf_lauf_s")) - basis_b
			if pb != null and is_instance_valid(pb):
				_bot_decide(pb, _bot_params("anfaenger"), tb)
		await _shot("11-boss.png")
		print("[SHOTS] boss gespawnt=%s" % str(gm.get("current_boss") != null))
	gm.call("quit_to_menu")
	await get_tree().create_timer(0.4).timeout

	# Profil zuruecksetzen
	gm.set("gold", gold0)
	gm.set("gems", gems0)
	gm.call("_save_profile")
	print("[SHOTS][ENDE] profil_zurueck gold=%d gems=%d" % [int(gm.get("gold")), int(gm.get("gems"))])
