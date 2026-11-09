# ItemSystem.gd - Weapon und Health Pickups (für Kisten und Drops)
extends Area2D

signal picked_up(item_type: String)

var item_type: String = "heart"
var rarity: String = "common"
var ring: Sprite2D = null
var net_id: int = 0

func _ready():
	collision_layer = 8
	collision_mask = 1
	connect("body_entered", Callable(self, "_on_body_entered"))
	_update_texture()

func set_item_type(type: String) -> void:
	item_type = type
	_update_texture()

func _update_texture() -> void:
	var sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var tex: Texture2D = null
	match item_type:
		"heart":
			tex = TextureManager.get_texture("heart_full")
		"shield":
			tex = TextureManager.get_texture("shield")
		"maxhealth":
			tex = TextureManager.get_texture("heart_gold")
		"weapon_pistol":
			tex = TextureManager.get_texture("weapon_pistol")
		"weapon_shotgun":
			tex = TextureManager.get_texture("weapon_shotgun")
		"weapon_machine":
			tex = TextureManager.get_texture("weapon_machine")
		"weapon_laser":
			tex = TextureManager.get_texture("weapon_laser")
		"weapon_revolver":
			tex = TextureManager.get_texture("weapon_revolver")
		"freeze":
			tex = TextureManager.get_texture("powerup_freeze")
		"rapid":
			tex = TextureManager.get_texture("powerup_rapid")
	if tex == null:
		tex = TextureManager.get_texture("heart_full")   # Fallback statt leerer Anzeige
	sprite.texture = tex

# Seltenheits-Ring (common/rare/epic) hinter dem Item
func set_rarity(r: String) -> void:
	rarity = r
	if ring == null:
		ring = Sprite2D.new()
		ring.name = "RarityRing"
		ring.z_index = -1
		add_child(ring)
	ring.texture = TextureManager.get_texture("rarity_" + r)
	if r == "epic":
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(ring, "scale", Vector2(1.14, 1.14), 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ring, "scale", Vector2(0.94, 0.94), 0.55).set_trans(Tween.TRANS_SINE)

func get_rarity() -> String:
	return rarity

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		emit_signal("picked_up", item_type, body, rarity)
		queue_free()
