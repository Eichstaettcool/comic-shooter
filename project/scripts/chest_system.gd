# ChestSystem.gd - Kiste, die durch 3s Stehenbleiben geöffnet wird
extends Area2D

signal item_spawned(item_type: String, position: Vector2)

var is_player_near: bool = false
var rarity: String = "common"
var glow: Sprite2D = null
var prog_bar: ProgressBar = null
var open_time: float = 3.0
var timer_progress: float = 0.0
var gm: Node = null                # wird beim Platzieren gesetzt (LAN-Logik)

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var open_timer = $OpenTimer
@onready var prompt_label = $PromptLabel

func _ready():
	collision_layer = 8
	collision_mask = 1
	sprite.texture = TextureManager.get_texture("chest_run_common")
	# Leuchtkranz in der Seltenheitsfarbe (zeigt von Weitem: bessere Kiste)
	glow = Sprite2D.new()
	glow.name = "Glow"
	glow.texture = TextureManager.get_texture("glow_common")
	glow.z_index = -1
	glow.scale = Vector2(1.6, 1.6)
	add_child(glow)
	var gtw := glow.create_tween()
	gtw.set_loops()
	gtw.tween_property(glow, "scale", Vector2(1.9, 1.9), 1.1).set_trans(Tween.TRANS_SINE)
	gtw.tween_property(glow, "scale", Vector2(1.5, 1.5), 1.1).set_trans(Tween.TRANS_SINE)
	# Fortschrittsbalken statt rohem Text
	prog_bar = ProgressBar.new()
	prog_bar.name = "ProgBar"
	prog_bar.size = Vector2(70, 12)
	prog_bar.position = Vector2(-35, -48)
	prog_bar.show_percentage = false
	prog_bar.visible = false
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.08, 0.09, 0.12, 0.85)
	pb_bg.set_corner_radius_all(6)
	prog_bar.add_theme_stylebox_override("background", pb_bg)
	var pb_fg = StyleBoxFlat.new()
	pb_fg.bg_color = Color(0.35, 0.90, 1.0)
	pb_fg.set_corner_radius_all(6)
	prog_bar.add_theme_stylebox_override("fill", pb_fg)
	add_child(prog_bar)
	_apply_rarity()
	collision_shape.shape = CircleShape2D.new()
	collision_shape.shape.radius = 18
	open_timer.wait_time = open_time
	open_timer.one_shot = true
	prompt_label.hide()
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	open_timer.connect("timeout", Callable(self, "_on_open_timer_timeout"))

func set_rarity(r: String) -> void:
	rarity = r
	_apply_rarity()

func _apply_rarity() -> void:
	if sprite == null:
		return
	var key := "chest_run_common"
	var gkey := "glow_common"
	match rarity:
		"rare":
			key = "chest_run_rare"
			gkey = "glow_rare"
		"epic":
			key = "chest_run_epic"
			gkey = "glow_epic"
	sprite.texture = TextureManager.get_texture(key)
	if glow != null and is_instance_valid(glow):
		glow.texture = TextureManager.get_texture(gkey)

func _process(delta: float) -> void:
	if is_player_near and not open_timer.is_stopped():
		timer_progress = open_timer.get_time_left() / open_time
		prompt_label.text = "Öffnen"
		if prog_bar != null:
			prog_bar.max_value = open_time
			prog_bar.value = open_time - open_timer.get_time_left()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		is_player_near = true
		prompt_label.show()
		if prog_bar != null:
			prog_bar.visible = true
			prog_bar.value = 0.0
		prompt_label.text = "Halten: %.1fs" % open_time
		open_timer.start(open_time)

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		is_player_near = false
		open_timer.stop()
		prompt_label.hide()
		if prog_bar != null:
			prog_bar.visible = false

func _on_area_entered(area) -> void:
	# Prevent opening if blocked by other objects
	pass

func _on_open_timer_timeout() -> void:
	# Runde 15: Im LAN oeffnet der Client die Kiste beim HOST (der Host vergibt den
	# Loot, damit beide Seiten dasselbe bekommen). Vorher waren Client-Kisten
	# "nur Optik" (monitoring=false) -> Nicht-Host konnte NIE oeffnen.
	if gm != null and is_instance_valid(gm) and bool(gm.get("coop_client")) and not bool(gm.get("coop_host")):
		if gm.has_method("request_chest_open"):
			gm.call("request_chest_open", global_position)
		queue_free()
		return
	_spawn_item()
	queue_free()

func _spawn_item() -> void:
	var r = randf()
	var item_key := "heart"
	var w_weapon := 0.38 if rarity == "common" else (0.46 if rarity == "rare" else 0.52)
	if r < w_weapon:
		# Waffe (38%) — jetzt aus 5 Waffen
		var weapons = ["weapon_pistol", "weapon_shotgun", "weapon_machine", "weapon_laser", "weapon_revolver"]
		item_key = weapons[randi() % weapons.size()]
	elif r < 0.62:
		item_key = "heart"          # 24%
	elif r < 0.74:
		item_key = "shield"         # 12%
	elif r < 0.82:
		item_key = "maxhealth"      # 8%
	elif r < 0.91:
		item_key = "freeze"         # 9%  Monster 5s stark verlangsamt
	else:
		item_key = "rapid"          # 9%  doppelte Feuerrate 8s
	emit_signal("item_spawned", item_key, global_position, rarity)
	if rarity == "epic":
		# epische Kiste: zweites Stueck Loot
		var second := "maxhealth" if randf() < 0.5 else "shield"
		emit_signal("item_spawned", second, global_position + Vector2(24, 12), "rare")

func _roll_rarity() -> String:
	# Runde 36: Pity - nach 10 Kisten ohne Rare ist mindestens Rare garantiert
	if gm != null and gm.has_method("get_chests_since_rare"):
		if int(gm.call("get_chests_since_rare")) >= 10:
			return "rare"
	var x = randf()
	if x < 0.60:
		return "common"
	elif x < 0.90:
		return "rare"
	return "epic"
