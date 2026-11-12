extends Node
# The gameplay scene. Builds the HUD and asks the LevelLoader to load the level
# chosen in the menu (SaveData.pending_level).

const HUDScript := preload("res://src/UI/HUD.gd")

onready var transition: ColorRect = $UI/Transition

var level: Node2D = null
var hud: CanvasLayer = null


func _ready() -> void:
	get_tree().set_quit_on_go_back(false)
	get_tree().paused = false
	Engine.time_scale = 1.0
	OS.keep_screen_on = true

	# The old developer panels and loading screen are not used in the finished game
	$UI/DebugDock.hide()
	$UI/Transition.hide()

	hud = HUDScript.new()
	add_child(hud)

	AudioManager.play_music("game")
	LevelLoader.setup(self, $Player, SaveData.pending_level)


func _exit_tree() -> void:
	OS.keep_screen_on = false
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_full_screen"):
		OS.window_fullscreen = not OS.window_fullscreen
