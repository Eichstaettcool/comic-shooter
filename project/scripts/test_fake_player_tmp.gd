extends Node2D
# Test-Doppel fuer die Downed-/Revive-Pruefung (COMIC_LANTEST=downed).
# Hat nur die Schnittstelle, die _tick_downed()/_revive_player() anfassen.

var health: int = 3
var max_health: int = 6
var downed: bool = false
var god_mode: bool = false

func get_health() -> int:
	return health

func get_max_health() -> int:
	return max_health
