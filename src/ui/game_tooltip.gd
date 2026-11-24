## 4X/RTS-style lockable tooltip (GW-AA pass 4, after CK3/Civ):
##
##   IDLE      nothing showing
##   DWELL     the pointer rests on a target (a tile, a card, a button); after
##             GRACE seconds of stillness the ring starts
##   CHARGING  only a small circular ring next to the pointer, filling over
##             CHARGE seconds (no tip yet); moving off the target (or more
##             than MOVE_SLOP px), clicking or dragging cancels it
##   LOCKED    the ring is full: the tip opens pinned in place (gold border,
##             lock badge) and stays until a click outside it or Esc
##
## Placement never covers the rects the board marks as off-limits (the
## pre-wave hint banner, the wave roster): the panel slides beside or above
## them instead. Time and pointer come in through [method tick], so tests can
## drive the whole state machine without real frames.
class_name GameTooltip
extends Control

enum State { IDLE, DWELL, CHARGING, LOCKED }

## Grace before the ring appears, ring fill time, and pointer slop (px).
## GW-AA pass 5: longer, so a glance never locks a tip by accident.
const GRACE := 0.45
const CHARGE := 1.2
const MOVE_SLOP := 7.0
## The ring: radius, stroke, and where it sits relative to the pointer.
const RING_RADIUS := 10.0
const RING_WIDTH := 3.5
const RING_OFFSET := Vector2(20.0, 18.0)
const RING_COLOR := Color(1.0, 0.93, 0.62, 0.95)
const RING_TRACK := Color(0.1, 0.16, 0.1, 0.55)
## Gap kept between the panel and anything it must not cover.
const AVOID_GAP := 8.0

## Off-limits rects (global pixels) for the locked panel; the board supplies
## them (the hint banner while it shows, the roster).
var avoid_provider: Callable
## Returns true while the ring must not start (GW-AA pass 5): a Warden card is
## held or dragged, or a Warden is selected for placement. While it says so,
## a pending dwell is dropped; a tip that already locked stays.
var suppress_provider: Callable

var _state := State.IDLE
var _t := 0.0
var _text := ""
var _key := ""
var _bottom_line := NAN
var _anchor := Vector2.ZERO
var _pointer := Vector2.ZERO
var _panel: PanelContainer
var _label: Label
var _badge: Label
var _ring: Control
var _manual_time := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Over the HUD (z 60) and the drag ghost (z 110).
	z_index = 120
	z_as_relative = false
	_panel = PanelContainer.new()
	_panel.name = "TipPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_panel.add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, FlatStyle.INK, 10, 3))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	_badge = Label.new()
	_badge.name = "LockBadge"
	_badge.text = "LOCKED  ·  Esc or click away to close"
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45, 0.85))
	_badge.add_theme_font_size_override("font_size", 11)
	column.add_child(_badge)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", FlatStyle.CREAM)
	_label.add_theme_font_size_override("font_size", 16)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(220, 0)
	column.add_child(_label)
	_panel.add_child(column)
	add_child(_panel)
	_ring = Control.new()
	_ring.name = "DwellRing"
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.visible = false
	_ring.size = Vector2.ONE * (RING_RADIUS + RING_WIDTH) * 2.0
	_ring.draw.connect(_draw_ring)
	add_child(_ring)


## Asks for a tip about [param key] (a stable id for the hovered thing).
## Re-asking for the same key keeps the dwell running; a new key restarts it.
## [param bottom_line] (global y) puts the locked panel's bottom on that line.
func request(key: String, text: String, bottom_line: float = NAN) -> void:
	if _state == State.LOCKED or suppressed():
		return
	if key == _key and _state != State.IDLE:
		_text = text
		return
	_key = key
	_text = text
	_bottom_line = bottom_line
	_begin_dwell(_current_pointer())


## The pointer left the thing it was resting on: drop a pending dwell.
## A locked tip stays until dismissed.
func cancel(key: String = "") -> void:
	if _state == State.LOCKED:
		return
	if not key.is_empty() and key != _key:
		return
	_reset()


## Closes the tip whatever its state (click outside, Esc, a drag starting).
func dismiss() -> void:
	_reset()


## Kept for the old callers: a plain cancel.
func hide_tip() -> void:
	cancel()


## Old API: request with the text as its own key.
func show_text(text: String, bottom_line: float = NAN) -> void:
	request(text, text, bottom_line)


## Whether the board says no ring may start right now.
func suppressed() -> bool:
	return suppress_provider.is_valid() and bool(suppress_provider.call())


func state() -> State:
	return _state


## Ring fill 0..1 (0 outside CHARGING, 1 when locked).
func progress() -> float:
	match _state:
		State.CHARGING:
			return clampf((_t - GRACE) / CHARGE, 0.0, 1.0)
		State.LOCKED:
			return 1.0
		_:
			return 0.0


func is_locked() -> bool:
	return _state == State.LOCKED


func ring_visible() -> bool:
	return _ring.visible


## The tip panel's global rect (empty when nothing is showing).
func panel_rect() -> Rect2:
	return _panel.get_global_rect() if _panel.visible else Rect2()


func text() -> String:
	return _text


## Tests drive time and the pointer by hand; real frames stop ticking.
func set_manual_time(manual: bool) -> void:
	_manual_time = manual


func _process(delta: float) -> void:
	if not _manual_time:
		tick(delta, get_global_mouse_position())


## Advances the state machine by [param delta] with the pointer at
## [param pointer] (global pixels).
func tick(delta: float, pointer: Vector2) -> void:
	_pointer = pointer
	if _state != State.LOCKED and _state != State.IDLE and suppressed():
		_reset()
		return
	match _state:
		State.DWELL, State.CHARGING:
			if pointer.distance_to(_anchor) > MOVE_SLOP:
				# Still on the target but moving: the dwell starts over here.
				_begin_dwell(pointer)
				return
			_t += delta
			if _t >= GRACE + CHARGE:
				_lock()
			elif _t >= GRACE:
				_state = State.CHARGING
				_ring.visible = true
				_ring.position = _anchor + RING_OFFSET - _ring.size * 0.5
				_ring.queue_redraw()
		_:
			pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_handle_press((event as InputEventMouseButton).global_position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_press((event as InputEventScreenTouch).position)
	elif event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_ESCAPE and _state == State.LOCKED:
		dismiss()
		get_viewport().set_input_as_handled()


## A press anywhere: cancels a pending dwell; closes a locked tip unless the
## press lands on the tip itself.
func _handle_press(at: Vector2) -> void:
	match _state:
		State.DWELL, State.CHARGING:
			_reset()
		State.LOCKED:
			if not panel_rect().has_point(at):
				_reset()
		_:
			pass


## Test hook: the same handling a real mouse press gets.
func press_at(at: Vector2) -> void:
	_handle_press(at)


func _begin_dwell(pointer: Vector2) -> void:
	_state = State.DWELL
	_t = 0.0
	_anchor = pointer
	_ring.visible = false
	_panel.visible = false


func _reset() -> void:
	_state = State.IDLE
	_t = 0.0
	_key = ""
	_ring.visible = false
	_panel.visible = false


func _lock() -> void:
	_state = State.LOCKED
	_ring.visible = false
	_open_panel()


## Opens the tip pinned in place (gold border + lock badge). Nothing but the
## ring shows before this: the tip only ever appears locked.
func _open_panel() -> void:
	_label.text = _text
	_badge.visible = true
	_panel.visible = true
	_panel.reset_size()
	_panel.add_theme_stylebox_override("panel", FlatStyle.panel(FlatStyle.PANEL, Color(1.0, 0.84, 0.4), 10, 3))
	_place_panel()


func _current_pointer() -> Vector2:
	return _pointer if _manual_time else get_global_mouse_position()


## Puts the locked panel near the anchor without covering the off-limits
## rects: above the bottom line (lawn tips ride in the sky over the felt) or
## beside the pointer, then slid left/right or up past anything it would hit.
func _place_panel() -> void:
	var tip_size := _panel.get_combined_minimum_size()
	_panel.size = tip_size
	var viewport := get_viewport_rect().size
	var pos := _anchor + Vector2(16, 22)
	if not is_nan(_bottom_line):
		pos = Vector2(_anchor.x - tip_size.x * 0.5, _bottom_line - tip_size.y)
	elif pos.y + tip_size.y > viewport.y - 8.0:
		# Near the bottom (the card tray): open above the pointer instead.
		pos.y = _anchor.y - tip_size.y - 14.0
	pos = _clamp(pos, tip_size, viewport)
	var avoid: Array = avoid_provider.call() if avoid_provider.is_valid() else []
	for _pass in 3:
		var hit := Rect2()
		for rect in avoid:
			var r: Rect2 = rect
			if r.size.x > 0.0 and Rect2(pos, tip_size).grow(AVOID_GAP * 0.5).intersects(r):
				hit = r
				break
		if hit.size.x <= 0.0:
			break
		# Try left of it, right of it, then above it; keep the closest fit.
		var options := [
			Vector2(hit.position.x - tip_size.x - AVOID_GAP, pos.y),
			Vector2(hit.end.x + AVOID_GAP, pos.y),
			Vector2(pos.x, hit.position.y - tip_size.y - AVOID_GAP),
		]
		var best := pos
		var best_d := INF
		for option in options:
			var o := _clamp(option, tip_size, viewport)
			if Rect2(o, tip_size).intersects(hit):
				continue
			var d := o.distance_to(pos)
			if d < best_d:
				best_d = d
				best = o
		pos = best
	_panel.global_position = pos


func _clamp(pos: Vector2, tip_size: Vector2, viewport: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, 8.0, maxf(8.0, viewport.x - tip_size.x - 8.0)),
		clampf(pos.y, 8.0, maxf(8.0, viewport.y - tip_size.y - 8.0)))


func _draw_ring() -> void:
	var c := _ring.size * 0.5
	_ring.draw_circle(c, RING_RADIUS + RING_WIDTH * 0.5, Color(0, 0, 0, 0.18))
	_ring.draw_arc(c, RING_RADIUS, 0.0, TAU, 40, RING_TRACK, RING_WIDTH, true)
	var p := progress()
	if p > 0.0:
		_ring.draw_arc(c, RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * p, 40, RING_COLOR, RING_WIDTH, true)


## Rests on [param control] for the tip: hover starts the dwell, leaving
## cancels it (a locked tip stays).
static func attach(control: Control, text: String, tip: GameTooltip) -> void:
	var key := "ctl:%d" % control.get_instance_id()
	control.mouse_entered.connect(func() -> void: tip.request(key, text))
	control.mouse_exited.connect(func() -> void: tip.cancel(key))
