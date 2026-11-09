class_name DeathOverlay
extends RefCounted

# Runde 138: aus ui_manager.gd ausgelagert.
# Zustand bleibt in der Fassade - jeder Zugriff laeuft ueber `host`.
var host: Node = null


func _create_death_screen():
	host.death_screen = Control.new()
	host.death_screen.name = "DeathScreen"
	host.death_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.death_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(host.death_screen)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.25, 0.08, 0.08)
	host.death_screen.add_child(bg)

	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	host.death_screen.add_child(box)

	var title = Label.new()
	title.text = "GAME OVER"
	title.label_settings = host._make_label_settings(100, Color(0.95, 0.25, 0.2), 14)
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var score_lbl = Label.new()
	score_lbl.name = "ScoreLabel"
	score_lbl.text = "Score: 0"
	score_lbl.label_settings = host._make_label_settings(56, Color(1, 1, 1), 10)
	score_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(score_lbl)

	var best_lbl = Label.new()
	best_lbl.name = "BestScoreLabel"
	best_lbl.text = "Best: 0"
	best_lbl.label_settings = host._make_label_settings(40, Color(1.0, 0.85, 0.3), 8)
	best_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(best_lbl)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 40)
	box.add_child(buttons)

	var restart_btn = host._make_styled_button("NOCHMAL SPIELEN", Color(0.2, 0.7, 0.3), 34)
	restart_btn.custom_minimum_size = Vector2(420, 80)
	restart_btn.pressed.connect(host._on_restart_pressed)
	buttons.add_child(restart_btn)

	var menu_btn = host._make_styled_button("HAUPTMENUE", Color(0.25, 0.5, 0.9), 34)
	menu_btn.custom_minimum_size = Vector2(380, 80)
	menu_btn.pressed.connect(host._on_menu_pressed)
	buttons.add_child(menu_btn)

	var exit_btn = host._make_styled_button("BEENDEN", Color(0.45, 0.45, 0.5), 34)
	exit_btn.custom_minimum_size = Vector2(320, 80)
	exit_btn.pressed.connect(host._on_exit_pressed)
	buttons.add_child(exit_btn)

	host.death_screen.hide()


func show_death_screen(current_score: int, best_score: int, gold_gain: int = 0, gold_total: int = 0) -> void:
	# Runde 49: Die Action-Musik endet mit dem Tod - zurueck auf
	# den ruhigen Loop, bis wieder ein Run startet.
	SoundManager.play_music("menu")
	if host.death_screen:
		host.death_screen.show()
	if host.hud:
		host.hud.hide()
	if host.start_screen:
		host.start_screen.hide()
	
	var score_label = host.death_screen.find_child("ScoreLabel", true, false)
	var best_label = host.death_screen.find_child("BestScoreLabel", true, false)
	if score_label:
		if gold_gain > 0:
			score_label.text = "SCORE  %d\n+%d GOLD   ·   KONTO  %d" % [current_score, gold_gain, gold_total]
		else:
			score_label.text = "SCORE  %d" % current_score
	if best_label:
		best_label.text = "Best: %d" % best_score
