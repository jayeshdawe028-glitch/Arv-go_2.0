extends Node

const Embedded := preload("res://src/Autoload/EmbeddedAssets.gd")
# Plays the background music and the sound effects.
# Music files:  res://assets/audio/music_menu.ogg  and  music_game.ogg
# Sound files:  res://assets/audio/  (death_1.mp3, death_2.mp3, meow.wav, click.wav ...)
# To change a sound, just replace the file with another one using the same name.

const MUSIC := {
	"menu": "res://assets/audio/music_menu.ogg",
	"game": "res://assets/audio/music_game.ogg",
}
const SFX := {
	"death_1": "res://assets/audio/death_1.mp3",
	"death_2": "res://assets/audio/death_2.mp3",
	"meow": "res://assets/audio/meow.wav",
	"click": "res://assets/audio/click.wav",
	"checkpoint": "res://assets/audio/checkpoint.wav",
	"level_complete": "res://assets/audio/level_complete.wav",
}

const MUSIC_VOLUME_DB := -9.0
const SFX_VOLUME_DB := -3.0
const SFX_VOICES := 6

var _music_player: AudioStreamPlayer
var _sfx_players := []
var _cache := {}
var _current_music := ""


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = MUSIC_VOLUME_DB
	add_child(_music_player)
# warning-ignore:return_value_discarded
	_music_player.connect("finished", self, "_on_music_finished")
	for i in range(SFX_VOICES):
		var player := AudioStreamPlayer.new()
		player.volume_db = SFX_VOLUME_DB
		add_child(player)
		_sfx_players.append(player)
# warning-ignore:return_value_discarded
	SaveData.connect("settings_changed", self, "_on_settings_changed")


func play_music(name: String) -> void:
	if name == _current_music and _music_player.playing:
		return
	_current_music = name
	if not SaveData.music_on:
		_music_player.stop()
		return
	var stream: AudioStream = _get_stream(MUSIC.get(name, ""))
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = true
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_current_music = ""
	_music_player.stop()


func play_sfx(name: String) -> void:
	if not SaveData.sfx_on:
		return
	var stream: AudioStream = _get_stream(SFX.get(name, ""))
	if stream == null:
		return
	var player: AudioStreamPlayer = null
	for candidate in _sfx_players:
		if not candidate.playing:
			player = candidate
			break
	if player == null:
		player = _sfx_players[0]
	player.stream = stream
	player.play()


# Plays one of the two death sounds at random
func play_death() -> void:
	play_sfx("death_1" if randi() % 2 == 0 else "death_2")


# Finds a sound by its path. Order: 1) Godot-imported file, 2) copy stored inside the code.
func _get_stream(path: String) -> AudioStream:
	if path.empty():
		return null
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null:
		var key := path.get_file().get_basename()
		if Embedded.DATA.has(key):
			var ogg := AudioStreamOGGVorbis.new()
			ogg.data = Marshalls.base64_to_raw(Embedded.DATA[key])
			stream = ogg
	_cache[path] = stream
	return stream


func _on_music_finished() -> void:
	# Safety net: if the stream did not loop by itself, start it again
	if _current_music != "" and SaveData.music_on:
		_music_player.play()


func _on_settings_changed() -> void:
	if not SaveData.music_on:
		_music_player.stop()
	elif _current_music != "" and not _music_player.playing:
		var name := _current_music
		_current_music = ""
		play_music(name)
