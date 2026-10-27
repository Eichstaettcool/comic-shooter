# CorruptionZone.gd - Wandernde violette Zone: Spieler langsamer, Monster schneller
extends Node2D

var radius: float = 300.0
var base_pos: Vector2 = Vector2.ZERO
var phase: float = 0.0
var drift_angle: float = 0.0
var time: float = 0.0

func setup(pos: Vector2, r: float) -> void:
	base_pos = pos
	position = pos
	radius = r
	phase = randf() * TAU
	drift_angle = randf() * TAU

func _ready() -> void:
	z_index = -5
	randomize_drift()

func randomize_drift() -> void:
	drift_angle = randf() * TAU

func _process(delta: float) -> void:
	time += delta
	# Driftet langsam in seine Richtung, dreht alle ~8s die Richtung
	position = base_pos + Vector2(cos(drift_angle), sin(drift_angle)) * (60.0 * sin(time * 0.4 + phase))
	if fmod(time, 8.0) < delta:
		randomize_drift()
	queue_redraw()

func _draw() -> void:
	var pulse := 1.0 + 0.05 * sin(time * 2.5 + phase)
	# 3 Schichten, innen intensiver
	draw_circle(Vector2.ZERO, radius * pulse, Color(0.35, 0.1, 0.45, 0.15))
	draw_circle(Vector2.ZERO, radius * 0.72 * pulse, Color(0.40, 0.10, 0.50, 0.20))
	draw_circle(Vector2.ZERO, radius * 0.45 * pulse, Color(0.45, 0.12, 0.55, 0.25))
	# Pulsierender Rand
	draw_arc(Vector2.ZERO, radius * pulse, 0, TAU, 48, Color(0.65, 0.25, 0.85, 0.5), 4.0)
	# Dornen-Kringel innen
	for k in range(6):
		var a := phase + k * TAU / 6.0 + time * 0.3
		var p := Vector2(cos(a), sin(a)) * radius * 0.6
		draw_circle(p, 10.0 + 4.0 * sin(time * 3.0 + k), Color(0.25, 0.05, 0.35, 0.5))

func contains(p: Vector2) -> bool:
	return global_position.distance_to(p) <= radius * 1.05
