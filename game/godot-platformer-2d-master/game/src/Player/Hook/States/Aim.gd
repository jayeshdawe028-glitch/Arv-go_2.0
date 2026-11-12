extends State


func unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("aim"):
		owner.is_aiming = not owner.is_aiming
	elif event.is_action_pressed("hook"):
		_state_machine.transition_to("Fire")


func physics_process(_delta: float) -> void:
	# On touch screens, holding the aim stick is what enables the slow-motion aiming
	if Settings.controls == Settings.TOUCH and owner.is_aiming != Settings.touch_aiming:
		owner.is_aiming = Settings.touch_aiming

	var cast: Vector2 = owner.get_aim_direction() * owner._radius
	var angle := cast.angle()
	owner.ray_cast.cast_to = cast
	owner.arrow.rotation = angle
	owner.snap_detector.rotation = angle
	owner.ray_cast.force_raycast_update()
