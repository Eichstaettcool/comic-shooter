extends Control
# v1.41 (F4): Eingabe-Ebene fuer die Waffen-Stats-Seite IM SPIEL.
# Bewusst als kleines Control (kein class_name, wird per load() erzeugt),
# damit im pausierten Baum (get_tree().paused) noch Escape ankommt.

var on_close: Callable = Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	print("[STATS][UI] overlay-input bereit (esc schliesst)")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		print("[STATS][UI] esc gedrueckt -> schliessen")
		if on_close.is_valid():
			on_close.call()
