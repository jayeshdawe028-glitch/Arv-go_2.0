extends Control
# Company splash screen.
# Shows the Bonina logo on black for about 3 seconds when the game starts,
# then goes straight into the main menu (same idea as a studio logo before
# a game starts).
#
# To change the logo, just replace:
#     res://assets/branding/bonina_logo.png
# with your own image (same name). Nothing else needs to change.
#
# Timings can be changed below: FADE_IN + HOLD + FADE_OUT = total seconds.

const MAIN_SCENE := "res://src/UI/MainMenu.tscn"
const FADE_IN := 0.7
const HOLD := 1.6
const FADE_OUT := 0.7

onready var _logo: TextureRect = $Logo


func _ready() -> void:
	get_tree().set_quit_on_go_back(false)
	get_tree().paused = false
	Engine.time_scale = 1.0
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.modulate = Color(1, 1, 1, 0)
# warning-ignore:return_value_discarded
	_play()


func _play() -> void:
	var fade_in := Tween.new()
	add_child(fade_in)
	fade_in.interpolate_property(_logo, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1),
			FADE_IN, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	fade_in.start()
	yield(fade_in, "tween_all_completed")

	yield(get_tree().create_timer(HOLD), "timeout")

	var fade_out := Tween.new()
	add_child(fade_out)
	fade_out.interpolate_property(_logo, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0),
			FADE_OUT, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	fade_out.start()
	yield(fade_out, "tween_all_completed")

	get_tree().change_scene(MAIN_SCENE)
