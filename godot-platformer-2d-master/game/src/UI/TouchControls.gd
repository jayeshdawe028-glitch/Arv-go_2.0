extends CanvasLayer
# On-screen controls for phones. Everything is drawn in code, so no image files are needed.
#
# Left side:  left / right buttons, and a down button (drop through thin platforms)
# Right side: jump button, hook button (auto-aims at the closest hook target),
#             and an aim stick: hold it to aim in slow motion, release to fire the hook.
#             Releasing the stick near its center cancels the shot.
#
# The buttons send regular input actions (move_left, move_right, move_down, jump, hook),
# so the rest of the game works exactly like with a keyboard.

const AIM_DEADZONE := 0.25
const HIT_MARGIN := 1.25

const COLOR_IDLE := Color(1, 1, 1, 0.2)
const COLOR_PRESSED := Color(1, 1, 1, 0.45)
const COLOR_OUTLINE := Color(1, 1, 1, 0.55)
const COLOR_GLYPH := Color(1, 1, 1, 0.8)

var _canvas: Control

var _buttons := {}
var _aim_center := Vector2.ZERO
var _aim_radius := 100.0

var _touches := {}
var _held := {}
var _aim_finger := -1
var _aim_vector := Vector2.ZERO


func _ready() -> void:
	# Keep receiving touches while the game is paused (e.g. during level transitions),
	# so that a released finger is never missed
	pause_mode = Node.PAUSE_MODE_PROCESS

	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
# warning-ignore:return_value_discarded
	_canvas.connect("draw", self, "_on_canvas_draw")
# warning-ignore:return_value_discarded
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
# warning-ignore:return_value_discarded
	Settings.connect("controls_changed", self, "_on_controls_changed")
	_on_controls_changed()


func _exit_tree() -> void:
	_release_all()


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_APP_PAUSED:
		_release_all()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if Settings.controls != Settings.TOUCH:
			Settings.set_controls(Settings.TOUCH)
		if event.pressed:
			_on_touch_down(event.index, event.position)
		else:
			_on_touch_up(event.index)
	elif event is InputEventScreenDrag:
		if Settings.controls == Settings.TOUCH:
			_on_touch_move(event.index, event.position)


# Layout, in 1920x1080 reference units scaled to the actual screen height
func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var u := screen.y / 1080.0
	_buttons = {
		"left": {pos = Vector2(170.0 * u, screen.y - 170.0 * u), radius = 115.0 * u, action = "move_left"},
		"right": {pos = Vector2(450.0 * u, screen.y - 170.0 * u), radius = 115.0 * u, action = "move_right"},
		"down": {pos = Vector2(310.0 * u, screen.y - 410.0 * u), radius = 80.0 * u, action = "move_down"},
		"jump": {pos = Vector2(screen.x - 180.0 * u, screen.y - 190.0 * u), radius = 125.0 * u, action = "jump"},
		"hook": {pos = Vector2(screen.x - 470.0 * u, screen.y - 150.0 * u), radius = 95.0 * u, action = "hook"},
	}
	_aim_center = Vector2(screen.x - 230.0 * u, screen.y - 560.0 * u)
	_aim_radius = 170.0 * u


func _on_touch_down(index: int, pos: Vector2) -> void:
	_layout()

	if _aim_finger == -1 and pos.distance_to(_aim_center) <= _aim_radius * HIT_MARGIN:
		_aim_finger = index
		Settings.touch_aiming = true
		_set_aim(pos)
		return

	var id := _find_button(pos)
	if id == "":
		return
	_touches[index] = id
	if id == "hook":
		_tap_hook()
	else:
		_send(_buttons[id].action, true)
	_canvas.update()


func _on_touch_move(index: int, pos: Vector2) -> void:
	if index == _aim_finger:
		_layout()
		_set_aim(pos)
		return

	# Sliding the thumb from left to right (or back) switches direction without lifting it
	if _touches.has(index) and _touches[index] in ["left", "right"]:
		_layout()
		var id := _find_button(pos)
		if id in ["left", "right"] and id != _touches[index]:
			_send(_buttons[_touches[index]].action, false)
			_touches[index] = id
			_send(_buttons[id].action, true)
			_canvas.update()


func _on_touch_up(index: int) -> void:
	if index == _aim_finger:
		var aim := _aim_vector
		_aim_finger = -1
		_aim_vector = Vector2.ZERO
		Settings.touch_aiming = false
		if aim.length() > AIM_DEADZONE:
			# Settings.touch_aim stays set while the hook fires, so it goes where the stick pointed
			Settings.touch_aim = aim
			_tap_hook()
		Settings.touch_aim = Vector2.ZERO
		_canvas.update()
		return

	if _touches.has(index):
		var id: String = _touches[index]
		_touches.erase(index)
		if id != "hook":
			_send(_buttons[id].action, false)
		_canvas.update()


func _find_button(pos: Vector2) -> String:
	var best_id := ""
	var best_ratio := HIT_MARGIN
	for id in _buttons:
		var button: Dictionary = _buttons[id]
		var ratio: float = pos.distance_to(button.pos) / button.radius
		if ratio <= best_ratio:
			best_ratio = ratio
			best_id = id
	return best_id


func _set_aim(pos: Vector2) -> void:
	var v := (pos - _aim_center) / _aim_radius
	if v.length() > 1.0:
		v = v.normalized()
	_aim_vector = v
	Settings.touch_aim = v
	_canvas.update()


func _tap_hook() -> void:
	_send("hook", true)
	_send("hook", false)


# Sends an input action, only when its state actually changes
func _send(action: String, pressed: bool) -> void:
	if action != "hook" and _held.get(action, false) == pressed:
		return
	_held[action] = pressed
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _release_all() -> void:
	for action in _held.keys():
		if _held[action]:
			_send(action, false)
	_held.clear()
	_touches.clear()
	_aim_finger = -1
	_aim_vector = Vector2.ZERO
	Settings.touch_aiming = false
	Settings.touch_aim = Vector2.ZERO
	if is_instance_valid(_canvas):
		_canvas.update()


func _on_controls_changed() -> void:
	var is_touch: bool = Settings.controls == Settings.TOUCH
	if not is_touch:
		_release_all()
	_canvas.visible = is_touch
	_canvas.update()


func _on_viewport_size_changed() -> void:
	_canvas.update()


func _on_canvas_draw() -> void:
	_layout()
	var pressed_ids := _touches.values()

	for id in _buttons:
		var button: Dictionary = _buttons[id]
		var is_down: bool = id in pressed_ids
		_draw_round_button(button.pos, button.radius, is_down)
		match id:
			"left":
				_draw_arrow(button.pos, Vector2.LEFT, button.radius * 0.45)
			"right":
				_draw_arrow(button.pos, Vector2.RIGHT, button.radius * 0.45)
			"down":
				_draw_arrow(button.pos, Vector2.DOWN, button.radius * 0.45)
			"jump":
				_draw_arrow(button.pos, Vector2.UP, button.radius * 0.45)
			"hook":
				_draw_crosshair(button.pos, button.radius * 0.5)

	# Aim stick
	var aiming := _aim_finger != -1
	_canvas.draw_circle(_aim_center, _aim_radius, COLOR_PRESSED if aiming else COLOR_IDLE)
	_canvas.draw_arc(_aim_center, _aim_radius, 0.0, TAU, 48, COLOR_OUTLINE, 3.0)
	_canvas.draw_arc(_aim_center, _aim_radius * AIM_DEADZONE, 0.0, TAU, 24, COLOR_IDLE, 2.0)
	var knob := _aim_center + _aim_vector * _aim_radius
	_canvas.draw_circle(knob, _aim_radius * 0.3, COLOR_PRESSED if aiming else COLOR_IDLE)
	_draw_crosshair(knob, _aim_radius * 0.2)


func _draw_round_button(pos: Vector2, radius: float, is_down: bool) -> void:
	_canvas.draw_circle(pos, radius, COLOR_PRESSED if is_down else COLOR_IDLE)
	_canvas.draw_arc(pos, radius, 0.0, TAU, 48, COLOR_OUTLINE, 3.0)


func _draw_arrow(pos: Vector2, direction: Vector2, size: float) -> void:
	var side := Vector2(-direction.y, direction.x)
	var points := PoolVector2Array([
		pos + direction * size,
		pos - direction * size * 0.6 + side * size * 0.8,
		pos - direction * size * 0.6 - side * size * 0.8,
	])
	_canvas.draw_colored_polygon(points, COLOR_GLYPH)


func _draw_crosshair(pos: Vector2, size: float) -> void:
	_canvas.draw_arc(pos, size, 0.0, TAU, 24, COLOR_GLYPH, 3.0)
	_canvas.draw_circle(pos, size * 0.25, COLOR_GLYPH)
	_canvas.draw_line(pos + Vector2(-size * 1.4, 0.0), pos + Vector2(-size * 0.6, 0.0), COLOR_GLYPH, 3.0)
	_canvas.draw_line(pos + Vector2(size * 0.6, 0.0), pos + Vector2(size * 1.4, 0.0), COLOR_GLYPH, 3.0)
	_canvas.draw_line(pos + Vector2(0.0, -size * 1.4), pos + Vector2(0.0, -size * 0.6), COLOR_GLYPH, 3.0)
	_canvas.draw_line(pos + Vector2(0.0, size * 0.6), pos + Vector2(0.0, size * 1.4), COLOR_GLYPH, 3.0)
