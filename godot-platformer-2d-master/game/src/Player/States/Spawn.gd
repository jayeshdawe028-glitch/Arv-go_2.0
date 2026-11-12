extends State
# Takes control away from the player and makes the character spawn


const FAILSAFE_SECONDS := 1.5

var _token := 0


func _on_Player_animation_finished(_anim_name: String) -> void:
	_finish()


func enter(msg: Dictionary = {}) -> void:
	Engine.time_scale = 1.0
	owner.stats.health = owner.stats.max_health
	owner.stats.set_invulnerable_for_seconds(2)
	owner.global_position = msg.get("respawn_position", owner.respawn_position)
	owner.is_active = false
	owner.camera_rig.is_active = false
	owner.skin.play("spawn")
	if not owner.skin.is_connected("animation_finished", self, "_on_Player_animation_finished"):
		owner.skin.connect("animation_finished", self, "_on_Player_animation_finished")
	_token += 1
	var my_token := _token
	yield(get_tree().create_timer(FAILSAFE_SECONDS), "timeout")
	if my_token == _token and _state_machine.state == self:
		_finish()


func exit() -> void:
	_token += 1
	owner.is_active = true
	owner.camera_rig.is_active = true
	if owner.skin.is_connected("animation_finished", self, "_on_Player_animation_finished"):
		owner.skin.disconnect("animation_finished", self, "_on_Player_animation_finished")


func _finish() -> void:
	if _state_machine.state != self:
		return
	_state_machine.transition_to("Move/Idle")
