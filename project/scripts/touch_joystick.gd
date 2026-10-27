# TouchJoystick.gd - Analoger Virtual-Joystick (Multi-Touch + Maus-Test)
# Große unsichtbare Touch-Zone (gesamtes Control-Rechteck), kleineres Visual in der Mitte.
extends Control

signal direction_changed(direction: Vector2)

var deadzone: float = 0.22
var vis_scale: float = 0.68   # Visual = 68% der Hitbox
var active: bool = false
var pointer_id: int = -999
var radius: float = 120.0     # nutzbare Auslenkung (Visual-Radius)

var base: TextureRect
var knob: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var visual := size * vis_scale
	radius = visual.x / 2.0
	var offset := (size - visual) / 2.0

	base = TextureRect.new()
	base.name = "Base"
	base.texture = TextureManager.get_texture("stick_base")
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_SCALE
	base.position = offset
	base.size = visual
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	knob = TextureRect.new()
	knob.name = "Knob"
	knob.texture = TextureManager.get_texture("stick_knob")
	knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	knob.stretch_mode = TextureRect.STRETCH_SCALE
	knob.size = visual * 0.36
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(knob)
	_reset_knob()

func _reset_knob() -> void:
	knob.position = size / 2.0 - knob.size / 2.0

func _gui_input(event) -> void:
	# Touch: gesamte Control-Fläche ist Hitbox
	if event is InputEventScreenTouch:
		if event.pressed:
			# Immer neu greifen — auch wenn ein alter Touch haengen geblieben ist
			active = true
			pointer_id = event.index
			_update_from_point(event.position)
			accept_event()
		elif event.index == pointer_id:
			_reset_state()
			accept_event()
	elif event is InputEventScreenDrag:
		if active and event.index == pointer_id:
			_update_from_point(event.position)
			accept_event()
	# Maus-Fallback für Desktop-Tests
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				active = true
				pointer_id = -1
				_update_from_point(event.position)
				accept_event()
			elif active and pointer_id == -1:
				_reset_state()
				accept_event()
	elif event is InputEventMouseMotion and active and pointer_id == -1:
		_update_from_point(event.position)

# Setzt den Joystick komplett zurueck (verhindert haengende Touch-Zustaende)
func force_reset() -> void:
	if active or pointer_id != -999:
		_reset_state()

func _reset_state() -> void:
	active = false
	pointer_id = -999
	_reset_knob()
	emit_signal("direction_changed", Vector2.ZERO)

func _notification(what: int) -> void:
	# Beim Ausblenden (Start-/Todes-Screen, Neustart) haengende Touches loesen
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		if active or pointer_id != -999:
			_reset_state()

func _update_from_point(p: Vector2) -> void:
	var center := size / 2.0
	var v := p - center
	var clamped := v
	if clamped.length() > radius:
		clamped = clamped.normalized() * radius
	knob.position = center + clamped - knob.size / 2.0
	var dir := v / radius
	if dir.length() > 1.0:
		dir = dir.normalized()
	if dir.length() < deadzone:
		dir = Vector2.ZERO
	emit_signal("direction_changed", dir)
