extends State
# The player died: plays the death animation + sound, then respawns at the last checkpoint.

const FAILSAFE_SECONDS := 1.5

var respawn_position := Vector2.ZERO
var _token := 0


func _on_Player_animation_finished(_anim_name: String) -> void:
	_respawn()


func enter(msg: Dictionary = {}) -> void:
	respawn_position = msg.get("respawn_position", owner.respawn_position)
	# If the player died while aiming the hook, the game was in slow motion: reset it
	owner.hook.is_aiming = false
	Engine.time_scale = 1.0
	owner.camera_rig.is_active = true
	owner.skin.play("die")
	AudioManager.play_death()
	if not owner.skin.is_connected("animation_finished", self, "_on_Player_animation_finished"):
		owner.skin.connect("animation_finished", self, "_on_Player_animation_finished")
	# Failsafe: whatever happens, the player always respawns
	_token += 1
	var my_token := _token
	yield(get_tree().create_timer(FAILSAFE_SECONDS), "timeout")
	if my_token == _token and _state_machine.state == self:
		_respawn()


func exit() -> void:
	_token += 1
	if owner.skin.is_connected("animation_finished", self, "_on_Player_animation_finished"):
		owner.skin.disconnect("animation_finished", self, "_on_Player_animation_finished")


func _respawn() -> void:
	if _state_machine.state != self:
		return
	_state_machine.transition_to("Spawn", {respawn_position = respawn_position})
