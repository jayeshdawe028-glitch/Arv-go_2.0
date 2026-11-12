extends Node
# Saves the player's progress on the phone, so closing the game never loses it.
# File: user://aarvii_save.json (stays on the phone, survives app restarts)

signal settings_changed()

const SAVE_PATH := "user://aarvii_save.json"
const MAX_LEVEL := 50

# Highest level the player has unlocked (reached)
var highest_level := 1
# Level the player was last playing (Continue starts here)
var current_level := 1
var music_on := true
var sfx_on := true

# True when a save file exists (used to enable the Continue button)
var has_save := false
# Level that the Game scene should start with (set by the menu)
var pending_level := 1
# Set when the player finishes level 50, so the menu shows the victory screen
var show_victory := false


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	load_data()


func load_data() -> void:
	var file := File.new()
	if not file.file_exists(SAVE_PATH):
		has_save = false
		return
	if file.open(SAVE_PATH, File.READ) != OK:
		return
	var text := file.get_as_text()
	file.close()
	var data = parse_json(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	has_save = true
	highest_level = int(clamp(int(data.get("highest_level", 1)), 1, MAX_LEVEL))
	current_level = int(clamp(int(data.get("current_level", 1)), 1, highest_level))
	music_on = bool(data.get("music_on", true))
	sfx_on = bool(data.get("sfx_on", true))


func save_data() -> void:
	var data := {
		"highest_level": highest_level,
		"current_level": current_level,
		"music_on": music_on,
		"sfx_on": sfx_on,
	}
	var file := File.new()
	if file.open(SAVE_PATH, File.WRITE) == OK:
		file.store_string(to_json(data))
		file.close()
		has_save = true


# Starts a fresh game: progress is erased, settings (music/sound) are kept
func new_game() -> void:
	highest_level = 1
	current_level = 1
	pending_level = 1
	show_victory = false
	save_data()


# Called when the player starts or reaches a level
func set_current_level(level: int) -> void:
	current_level = int(clamp(level, 1, MAX_LEVEL))
	if current_level > highest_level:
		highest_level = current_level
	save_data()


# Called when a level is completed: unlocks the next one
func unlock(level: int) -> void:
	level = int(clamp(level, 1, MAX_LEVEL))
	if level > highest_level:
		highest_level = level
	save_data()


func set_music_on(value: bool) -> void:
	music_on = value
	save_data()
	emit_signal("settings_changed")


func set_sfx_on(value: bool) -> void:
	sfx_on = value
	save_data()
	emit_signal("settings_changed")
