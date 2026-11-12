tool
extends Position2D
class_name Hook, "res://assets/icons/icon_hook.svg"
# Throws a raycast that can interact with Hookable bodies and calculate a pull vector towards those bodies.
# The raycast is updated manually for greater precision with where the player is aiming
# Draws the hook's range in the editor


# warning-ignore:unused_signal
signal hooked_onto_target(target_global_position)

onready var ray_cast: RayCast2D = $RayCast2D
onready var arrow: Node2D = $Arrow
onready var snap_detector: Area2D = $SnapDetector
onready var cooldown: Timer = $Cooldown

var is_aiming := false setget set_is_aiming
var is_active := true setget set_is_active

onready var _radius: float = snap_detector.calculate_length()

func _ready() -> void:
	if Engine.editor_hint:
		update()


func _draw() -> void:
	if not Engine.editor_hint:
		return

	DrawingUtils.draw_circle_outline(self, Vector2.ZERO, snap_detector.calculate_length(), Color.lightgreen)


func can_hook() -> bool:
	return is_active and snap_detector.has_target() and cooldown.is_stopped()


func get_aim_direction() -> Vector2:
	var direction := Vector2.ZERO
	match Settings.controls:
		Settings.GAMEPAD:
			direction = Utils.get_aim_joystick_direction()
		Settings.TOUCH:
			direction = get_touch_aim_direction()
		Settings.KBD_MOUSE, _:
			direction = (get_global_mouse_position() - global_position).normalized()
	return direction


const TOUCH_AIM_DEADZONE := 0.25
const WORLD_COLLISION_MASK := 2


# Touch screens: the aim stick gives a manual direction. Without it, the hook
# points at the closest active hook target in range that has a clear line of sight.
func get_touch_aim_direction() -> Vector2:
	if Settings.touch_aim.length() > TOUCH_AIM_DEADZONE:
		return Settings.touch_aim.normalized()

	var best_direction := Vector2.ZERO
	var best_distance := _radius * 0.9
	var space_state := get_world_2d().direct_space_state
	for target in get_tree().get_nodes_in_group("hook_targets"):
		if not is_instance_valid(target) or not target.is_active:
			continue
		var to_target: Vector2 = target.global_position - global_position
		var distance := to_target.length()
		if distance >= best_distance or distance < 1.0:
			continue
		var obstacle := space_state.intersect_ray(global_position, target.global_position, [], WORLD_COLLISION_MASK)
		if not obstacle.empty():
			continue
		best_distance = distance
		best_direction = to_target / distance

	if best_direction == Vector2.ZERO:
		best_direction = _get_facing_direction()
	return best_direction


func _get_facing_direction() -> Vector2:
	var player := get_parent()
	if player and player.has_node("LedgeWallDetector"):
		var facing: float = player.get_node("LedgeWallDetector").scale.x
		if facing < 0.0:
			return Vector2.LEFT
	return Vector2.RIGHT


func set_is_aiming(value: bool) -> void:
	is_aiming = value
	Engine.time_scale = 0.05 if is_aiming == true else 1.0


func set_is_active(value: bool) -> void:
	is_active = value
	set_process_unhandled_input(value)
