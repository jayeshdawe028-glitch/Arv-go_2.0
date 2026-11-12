extends CanvasLayer
# In-game screen: level number, pause button, pause menu, level banner and screen fades.
# Created by Game.gd.

const UITheme := preload("res://src/UI/UITheme.gd")

var _root: Control
var _level_label: Label
var _banner: Label
var _pause_button: Button
var _pause_panel: Control
var _music_button: Button
var _sound_button: Button
var _fade_rect: ColorRect
var _tween: Tween
var _banner_tween: Tween


func _ready() -> void:
	layer = 105
	pause_mode = Node.PAUSE_MODE_PROCESS

	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_level_badge()
	_build_pause_button()
	_build_banner()
	_build_pause_panel()
	_build_fade()
	_refresh_toggle_texts()
# warning-ignore:return_value_discarded
	SaveData.connect("settings_changed", self, "_refresh_toggle_texts")


func _notification(what: int) -> void:
	# Android back button opens / closes the pause menu
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		toggle_pause()


# ---------------------------------------------------------------- public

func set_level(number: int) -> void:
	_level_label.text = "Level %d / %d" % [number, SaveData.MAX_LEVEL]
	show_banner("Level %d" % number, 1.4)


func show_banner(text: String, auto_hide_seconds := 0.0) -> void:
	_banner.text = text
	_banner.modulate = Color(1, 1, 1, 0)
	_banner.show()
	_banner_tween.stop_all()
	_banner_tween.interpolate_property(_banner, "modulate:a", 0.0, 1.0, 0.25)
	if auto_hide_seconds > 0.0:
		_banner_tween.interpolate_property(_banner, "modulate:a", 1.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN, auto_hide_seconds)
	_banner_tween.start()


func hide_banner() -> void:
	_banner_tween.stop_all()
	_banner.hide()


func fade_to_black() -> void:
	_tween.stop_all()
	_tween.interpolate_property(_fade_rect, "modulate:a", _fade_rect.modulate.a, 1.0, 0.35)
	_tween.start()
	yield(_tween, "tween_all_completed")


func fade_from_black() -> void:
	_tween.stop_all()
	_tween.interpolate_property(_fade_rect, "modulate:a", _fade_rect.modulate.a, 0.0, 0.45)
	_tween.start()
	yield(_tween, "tween_all_completed")


func toggle_pause() -> void:
	if _pause_panel.visible:
		_resume()
	else:
		_open_pause()


# ---------------------------------------------------------------- building

func _build_level_badge() -> void:
	var panel := PanelContainer.new()
	panel.add_stylebox_override("panel", UITheme.box(Color(0.12, 0.06, 0.24, 0.72), UITheme.GOLD, 24, 3))
	panel.rect_position = Vector2(36, 28)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_label = UITheme.make_label("Level 1 / 50", 38, UITheme.GOLD)
	panel.add_child(_level_label)
	_root.add_child(panel)


func _build_pause_button() -> void:
	_pause_button = UITheme.make_button("II", Vector2(120, 120), 54)
	_pause_button.rect_position = Vector2(1920 - 120 - 36, 28)
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.margin_left = -156
	_pause_button.margin_right = -36
	_pause_button.margin_top = 28
	_pause_button.margin_bottom = 148
# warning-ignore:return_value_discarded
	_pause_button.connect("pressed", self, "_open_pause")
	_root.add_child(_pause_button)


func _build_banner() -> void:
	_banner = UITheme.make_label("", 110, UITheme.GOLD, true)
	_banner.set_anchors_and_margins_preset(Control.PRESET_CENTER_TOP)
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.margin_left = 0
	_banner.margin_right = 0
	_banner.margin_top = 250
	_banner.margin_bottom = 420
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.hide()
	_root.add_child(_banner)
	_banner_tween = Tween.new()
	_banner_tween.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_banner_tween)


func _build_pause_panel() -> void:
	_pause_panel = Control.new()
	_pause_panel.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_pause_panel.hide()
	_root.add_child(_pause_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.02, 0.09, 0.82)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_pause_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_pause_panel.add_child(center)

	var box := VBoxContainer.new()
	box.add_constant_override("separation", 22)
	center.add_child(box)

	box.add_child(UITheme.make_label("Paused", 96, UITheme.GOLD, true))

	var resume := UITheme.make_button("Resume", Vector2(640, 110), 48)
# warning-ignore:return_value_discarded
	resume.connect("pressed", self, "_resume")
	box.add_child(resume)

	var restart := UITheme.make_button("Restart Level", Vector2(640, 110), 48)
# warning-ignore:return_value_discarded
	restart.connect("pressed", self, "_restart")
	box.add_child(restart)

	var row := HBoxContainer.new()
	row.add_constant_override("separation", 22)
	box.add_child(row)
	_music_button = UITheme.make_button("Music: On", Vector2(309, 100), 36)
# warning-ignore:return_value_discarded
	_music_button.connect("pressed", self, "_toggle_music")
	row.add_child(_music_button)
	_sound_button = UITheme.make_button("Sound: On", Vector2(309, 100), 36)
# warning-ignore:return_value_discarded
	_sound_button.connect("pressed", self, "_toggle_sound")
	row.add_child(_sound_button)

	var menu := UITheme.make_button("Main Menu", Vector2(640, 110), 48, Color(0.45, 0.14, 0.30, 1))
# warning-ignore:return_value_discarded
	menu.connect("pressed", self, "_to_menu")
	box.add_child(menu)


func _build_fade() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 120
	fade_layer.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.03, 0.01, 0.07, 1)
	_fade_rect.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate = Color(1, 1, 1, 1)
	fade_layer.add_child(_fade_rect)
	_tween = Tween.new()
	_tween.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_tween)


# ---------------------------------------------------------------- actions

func _open_pause() -> void:
	if LevelLoader._busy:
		return
	_pause_panel.show()
	get_tree().paused = true


func _resume() -> void:
	_pause_panel.hide()
	get_tree().paused = false


func _restart() -> void:
	_pause_panel.hide()
	LevelLoader.restart_level()


func _to_menu() -> void:
	_pause_panel.hide()
	LevelLoader.leave_to_menu()


func _toggle_music() -> void:
	SaveData.set_music_on(not SaveData.music_on)


func _toggle_sound() -> void:
	SaveData.set_sfx_on(not SaveData.sfx_on)


func _refresh_toggle_texts() -> void:
	if _music_button:
		_music_button.text = "Music: On" if SaveData.music_on else "Music: Off"
	if _sound_button:
		_sound_button.text = "Sound: On" if SaveData.sfx_on else "Sound: Off"
