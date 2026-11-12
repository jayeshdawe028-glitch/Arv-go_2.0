extends Node
# Loads, unloads and finishes levels (1 to 50).
# Level 1 and 2 are the hand-made scenes, levels 3 to 50 are built by LevelGenerator.gd

signal level_loaded(number)

const LevelGeneratorScript := preload("res://src/Levels/LevelGenerator.gd")

var current_number := 1

var _game: Node = null
var _player: Player = null
var _level: Node2D = null
var _busy := false


func setup(game: Node, player: Player, number: int) -> void:
	_game = game
	_player = player
	_level = null
	_busy = false
	_load_level(number, true)


func get_level() -> Node2D:
	return _level


# Reloads the current level from the start
func restart_level() -> void:
	goto_level(current_number)


func goto_level(number: int) -> void:
	if _busy:
		return
	_load_level(number, false)


# Called by the portal at the end of a level
func finish_level() -> void:
	if _busy:
		return
	_busy = true
	Engine.time_scale = 1.0
	var done := current_number
	AudioManager.play_sfx("level_complete")
	SaveData.unlock(done + 1)
	get_tree().paused = true
	_game.hud.show_banner("Level %d complete!" % done)
	yield(get_tree().create_timer(1.7), "timeout")
	_game.hud.hide_banner()
	if done >= SaveData.MAX_LEVEL:
		SaveData.show_victory = true
		_busy = false
		leave_to_menu()
		return
	_busy = false
	_load_level(done + 1, false)


func leave_to_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_level = null
	_busy = false
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://src/UI/MainMenu.tscn")


func _create_level(number: int) -> Node2D:
	var level: Node2D = null
	if number == 1:
		level = (load("res://src/Levels/Level1.tscn") as PackedScene).instance()
		var exit := level.get_node_or_null("Exit2")
		if exit:
			exit.add_to_group("level_exit")
	elif number == 2:
		level = (load("res://src/Levels/Level2.tscn") as PackedScene).instance()
		var exit := level.get_node_or_null("Exit")
		if exit:
			exit.add_to_group("level_exit")
	else:
		level = LevelGeneratorScript.new().build(number)
	return level


func _load_level(number: int, first: bool) -> void:
	_busy = true
	number = int(clamp(number, 1, SaveData.MAX_LEVEL))
	Engine.time_scale = 1.0

	if not first:
		get_tree().paused = true
		yield(_game.hud.fade_to_black(), "completed")
		if is_instance_valid(_level):
			_level.queue_free()
			yield(_level, "tree_exited")

	current_number = number
	SaveData.set_current_level(number)

	_game.remove_child(_player)
	_level = _create_level(number)

	var start: Node2D = _level.get_node("Checkpoints").get_child(0)
	_player.global_position = start.position
	_player.respawn_position = start.position
	_player.has_teleported = false

	_game.level = _level
	_game.add_child(_level)
	_game.add_child(_player)
	# The level must be drawn behind the player
	_game.move_child(_level, 0)

	if not first:
		# Start the new level with a clean player (no leftover speed or state)
		_player.hook.is_aiming = false
		_player.state_machine.transition_to("Move/Idle")

	_game.hud.set_level(number)
	emit_signal("level_loaded", number)

	get_tree().paused = false
	_busy = false
	yield(_game.hud.fade_from_black(), "completed")
