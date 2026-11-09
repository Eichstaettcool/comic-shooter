class_name SmoothScroll
extends Control

# v1.46 (C1-C3): gemeinsam genutzter, weich laufender Scrollbereich.
#
# Warum ein eigener Container und nicht ScrollContainer:
#   Der eingebaute ScrollContainer springt beim Mausrad in Stufen und hat beim
#   Ziehen per Maus keinen Nachlauf. Fuer die Challenge-Ansicht (12 Karten)
#   brauchen wir: Finger folgt exakt (Versatz <= 2 px), Loslassen laeuft aus
#   (250-450 ms) und das Rad schiebt in 120-px-Stufen weich nach.
#
# Aufbau:
#   SmoothScroll (clip_contents)
#     |- content (Control): wird auf seine Mindestgroesse gesetzt und ueber
#        position.y = -offset bewegt.
#
# Belege (Spec v1.46 C1-C3):
#   [SCROLL][BAU]   Aufbau, Modus, Nachlauf
#   [SCROLL][ZUG]   Versatz Finger/Inhalt + Nachlaufzeit nach dem Loslassen
#   [SCROLL][RAD]   Radstufe, Grenzen, Klemmung

const STEP_PX := 120.0
const EASE_RATE := 16.0          # 1/s: nach ~0,36 s sind 99 % der Strecke weg
const SETTLE_PX := 0.5
const DRAG_TOLERANCE := 2.0

var content: Control = null
var offset: float = 0.0
var target: float = 0.0
var dragging: bool = false
var _drag_start_y: float = 0.0
var _drag_start_offset: float = 0.0
var _drag_expected: float = 0.0
var _versatz_max: float = 0.0
var _drag_samples: int = 0
var _release_ms: int = 0
var _settle_ms: int = 0
var _velocity: float = 0.0
var _last_sample_y: float = 0.0
var _last_sample_t: int = 0
var _log_end_done: bool = false
var _bau_final: bool = false
var tag: String = ""


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func set_content(c: Control) -> void:
	content = c
	if content.get_parent() != self:
		add_child(content)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	_log_bau()


func v_max() -> float:
	if content == null:
		return 0.0
	var need: float = content.get_combined_minimum_size().y
	return maxf(0.0, need - size.y)


func _log_bau() -> void:
	print("[SCROLL][BAU] seite=%s modus=drag+wheel nachlauf=true schritt=%.0f max=%.0f sicht=%.0f" % [
		tag, STEP_PX, v_max(), size.y])


func _process(delta: float) -> void:
	if content == null:
		return
	# Inhalt immer auf Mindestgroesse + volle Breite ziehen.
	var need: Vector2 = content.get_combined_minimum_size()
	if absf(content.size.y - need.y) > 0.5:
		content.size = Vector2(size.x, need.y)
	elif absf(content.size.x - size.x) > 0.5:
		content.size = Vector2(size.x, maxf(need.y, content.size.y))
	var vmax: float = v_max()
	# Beleg mit echten Massen: beim Aufbau stehen die Kindmasse noch nicht.
	if not _bau_final and vmax > 0.0:
		_bau_final = true
		print("[SCROLL][BAU] seite=%s modus=drag+wheel nachlauf=true schritt=%.0f max=%.0f sicht=%.0f gemessen=true" % [
			tag, STEP_PX, vmax, size.y])
	target = clampf(target, 0.0, vmax)
	if dragging:
		offset = clampf(offset, 0.0, vmax)
		content.position = Vector2(0.0, -offset)
		return
	# Nachlauf: exponentielle Annaeherung an den Zielwert (kein Sprung).
	if absf(target - offset) > SETTLE_PX:
		var k: float = 1.0 - exp(-EASE_RATE * delta)
		offset = lerpf(offset, target, k)
		if _settle_ms == 0:
			_settle_ms = Time.get_ticks_msec()
	elif absf(target - offset) <= SETTLE_PX and _release_ms > 0 and not _log_end_done:
		offset = target
		_log_zug()
		_log_end_done = true
		_release_ms = 0
		_settle_ms = 0
	offset = clampf(offset, 0.0, vmax)
	content.position = Vector2(0.0, -offset)


func _gui_input(event: InputEvent) -> void:
	if OS.get_environment("COMIC_SCROLL_DEBUG") == "1":
		print("[SCROLL][EV] %s pos=%s dragging=%s" % [event.get_class(), str(event.position), str(dragging)])
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_start_drag(st.position.y)
		else:
			_end_drag()
		accept_event()
		return
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_drag_to(sd.position.y)
		accept_event()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_wheel(-STEP_PX)
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_wheel(STEP_PX)
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_drag(mb.position.y)
			else:
				_end_drag()
			accept_event()
			return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if dragging and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_drag_to(mm.position.y)
			accept_event()


func _start_drag(y: float) -> void:
	dragging = true
	_drag_start_y = y
	_drag_start_offset = offset
	_drag_expected = offset
	_versatz_max = 0.0
	_drag_samples = 0
	_velocity = 0.0
	_last_sample_y = y
	_last_sample_t = Time.get_ticks_msec()
	_release_ms = 0
	_settle_ms = 0
	_log_end_done = false


func _drag_to(y: float) -> void:
	var want: float = _drag_start_offset - (y - _drag_start_y)
	var vmax: float = v_max()
	want = clampf(want, 0.0, vmax)
	offset = want
	target = want
	_drag_expected = want
	var versatz: float = absf(offset - want)
	_versatz_max = maxf(_versatz_max, versatz)
	_drag_samples += 1
	var now: int = Time.get_ticks_msec()
	var dt: float = maxf(0.001, float(now - _last_sample_t) / 1000.0)
	_velocity = clampf((y - _last_sample_y) / dt * -1.0, -3000.0, 3000.0)  # px/s in Inhaltsrichtung
	_last_sample_y = y
	_last_sample_t = now


func _end_drag() -> void:
	if not dragging:
		return
	dragging = false
	_release_ms = Time.get_ticks_msec()
	# Nachlauf: Schwung aus der letzten Bewegung, gedeckelt auf 220 px.
	var vmax: float = v_max()
	target = clampf(offset + clampf(_velocity * 0.08, -160.0, 160.0), 0.0, vmax)
	print("[SCROLL][ZUG] versatz_max=%.1fpx probes=%d schwung=%.0fpx/s ziel=%.0f max=%.0f" % [
		_versatz_max, _drag_samples, _velocity, target, vmax])


func _wheel(dy: float) -> void:
	var vmax: float = v_max()
	var vorher: float = target
	target = clampf(target + dy, 0.0, vmax)
	print("[SCROLL][RAD] schritt=%.0f min=0 max=%.0f vorher=%.0f nachher=%.0f klemmt=%s" % [
		STEP_PX, vmax, vorher, target, str(absf(target - vorher) < absf(dy) - 0.5)])


func _log_zug() -> void:
	var nachlauf: int = Time.get_ticks_msec() - _release_ms if _release_ms > 0 else 0
	print("[SCROLL][ZUG] nachlauf_ms=%d versatz_max=%.1fpx" % [nachlauf, _versatz_max])


func scroll_to(y: float) -> void:
	target = clampf(y, 0.0, v_max())
	_log_end_done = false


func scroll_to_end() -> void:
	target = v_max()
	_log_end_done = false


# Beleg fuer C5: Ende der Liste erreichbar, letzte Karte nicht abgeschnitten.
func end_report(last_card: Control) -> Dictionary:
	var vmax: float = v_max()
	var sichtbar_bis: float = offset + size.y
	var voll: bool = false
	if last_card != null:
		var g: Rect2 = last_card.get_global_rect()
		var own: Rect2 = get_global_rect()
		voll = g.end.y <= own.end.y + 1.0 and g.position.y >= own.position.y - 1.0
	var d := {
		"max": vmax, "offset": offset, "sichtbar_bis": sichtbar_bis,
		"letzte_karte_voll": voll, "sicht": size.y,
	}
	print("[SCROLL][ENDE] max=%.0f offset=%.0f sichtbar_bis=%.0f sicht=%.0f letzte_karte_voll=%s" % [
		vmax, offset, sichtbar_bis, size.y, str(voll)])
	return d
