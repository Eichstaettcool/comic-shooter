extends StaticBody2D
# Runde 66: Treffbarer Client-Geist.
# Der Client simuliert keine Gegner - er bekommt Positionen und HP vom Host.
# Damit ein Schuss trotzdem sofort reagiert (Sound/Flash) und der Schaden
# autoritativ beim Host landet, meldet der Geist den Treffer nur an:
#   -> Host prueft, ob der Gegner existiert und zieht den Schaden ab.
# Bisher waren die Geister reine Sprites ohne Kollision, deshalb ging auf
# dem Client jeder Schuss wirkungslos durch.

var gm: Node = null
var net_id: int = 0
var sprite: Sprite2D = null


func take_damage(amount: int, owner_slot: int = 0, _hit_local: Vector2 = Vector2.INF) -> void:
	# Sofortiges Feedback auf dem Client, Schaden entscheidet der Host
	SoundManager.play("hit")
	if sprite != null and is_instance_valid(sprite):
		sprite.modulate = Color(1.9, 1.3, 1.3)
		var tw := sprite.create_tween()
		tw.tween_property(sprite, "modulate", Color(1, 1, 1), 0.14)
	if gm != null and bool(gm.get("coop_client")) and net_id > 0:
		NetManager.c_send_hit(net_id, amount)
