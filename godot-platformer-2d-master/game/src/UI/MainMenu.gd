extends Control
# Main menu: Continue / New Game / Select Level / Quit.
#
# To change the picture on this screen, replace the file
#     res://assets/branding/title_art.png
# with your own image (same name). Nothing else needs to change.

const UITheme := preload("res://src/UI/UITheme.gd")

const GAME_SCENE := "res://src/Main/Game.tscn"
const LOGO_PATH := "res://assets/branding/title_art.png"
const GAME_TITLE_1 := "GO AARVII"
const GAME_TITLE_2 := "GO !"
const TAGLINE := "A cute cat adventure"
const VERSION := "v1.0"
const CREDIT := "DEV : @ALWAYSJAKE28"
const YOUTUBE_URL := "https://youtube.com/@aarviineko?si=IO84bvDhRVasNPGt"
const Embedded := preload("res://src/Autoload/EmbeddedAssets.gd")

var _stars := []
var _time := 0.0
var _logo: TextureRect
var _screens := {}
var _current_screen := "main"
var _continue_button: Button
var _music_button: Button
var _sound_button: Button
var _levels_grid: GridContainer
var _logo_pivot_ready := false


func _ready() -> void:
	get_tree().set_quit_on_go_back(false)
	get_tree().paused = false
	Engine.time_scale = 1.0
	randomize()
	for i in range(70):
		_stars.append({
			pos = Vector2(randf() * 1920.0, randf() * 1080.0),
			size = rand_range(1.5, 5.0),
			phase = randf() * TAU,
			speed = rand_range(0.6, 2.2),
		})

	_build_main()
	_build_levels()
	_build_confirm()
	_build_victory()
# warning-ignore:return_value_discarded
	SaveData.connect("settings_changed", self, "_refresh_main")

	AudioManager.play_music("menu")
	if SaveData.show_victory:
		SaveData.show_victory = false
		_show("victory")
	else:
		_show("main")


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		if _current_screen != "main":
			_show("main")
		else:
			get_tree().quit()


func _process(delta: float) -> void:
	_time += delta
	update()
	if _logo:
		# gentle breathing animation on the picture
		_logo.rect_pivot_offset = _logo.rect_size * 0.5
		var s := 1.0 + 0.014 * sin(_time * 1.8)
		_logo.rect_scale = Vector2(s, s)


func _draw() -> void:
	var size := rect_size
	var top := UITheme.BG_DARK
	var bottom := UITheme.BG_MID
	draw_polygon(
		PoolVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)]),
		PoolColorArray([top, top, bottom, bottom])
	)
	for star in _stars:
		var alpha: float = 0.3 + 0.7 * (0.5 + 0.5 * sin(_time * star.speed + star.phase))
		var p := Vector2(star.pos.x * size.x / 1920.0, star.pos.y * size.y / 1080.0)
		var color := Color(1.0, 0.93, 1.0, alpha)
		draw_circle(p, star.size, color)
		if star.size > 3.8:
			draw_line(p + Vector2(-star.size * 2.4, 0), p + Vector2(star.size * 2.4, 0), color, 2.0)
			draw_line(p + Vector2(0, -star.size * 2.4), p + Vector2(0, star.size * 2.4), color, 2.0)


# ---------------------------------------------------------------- screens

func _show(name: String) -> void:
	_current_screen = name
	for key in _screens:
		_screens[key].visible = (key == name)
	if name == "levels":
		_refresh_levels()
	elif name == "main":
		_refresh_main()


func _new_screen(name: String) -> Control:
	var screen := Control.new()
	screen.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	add_child(screen)
	_screens[name] = screen
	return screen


func _build_main() -> void:
	var screen := _new_screen("main")

	var margin := MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_constant_override("margin_" + side, 50)
	screen.add_child(margin)

	var row := HBoxContainer.new()
	row.add_constant_override("separation", 30)
	margin.add_child(row)

	# ---- left: the picture
	var left := CenterContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)

	_logo = TextureRect.new()
	var texture: Texture = _load_logo()
	_logo.texture = texture
	_logo.expand = true
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.rect_min_size = Vector2(800, 850)
	left.add_child(_logo)

	# ---- right: title + buttons
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGN_CENTER
	right.add_constant_override("separation", 16)
	row.add_child(right)

	right.add_child(UITheme.make_label(GAME_TITLE_1, 112, UITheme.GOLD, true))
	right.add_child(UITheme.make_label(GAME_TITLE_2, 112, UITheme.GOLD, true))
	var tagline := UITheme.make_label(TAGLINE, 40, UITheme.TEXT_DIM)
	right.add_child(tagline)

	var spacer := Control.new()
	spacer.rect_min_size = Vector2(0, 24)
	right.add_child(spacer)

	_continue_button = UITheme.make_button("Continue", Vector2(660, 104), 48)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	_continue_button.connect("pressed", self, "_on_continue")
	right.add_child(_continue_button)

	var new_button := UITheme.make_button("New Game", Vector2(660, 104), 48)
	new_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	new_button.connect("pressed", self, "_on_new_game")
	right.add_child(new_button)

	var levels_button := UITheme.make_button("Select Level", Vector2(660, 104), 48)
	levels_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	levels_button.connect("pressed", self, "_show", ["levels"])
	right.add_child(levels_button)

	var quit_button := UITheme.make_button("Quit", Vector2(660, 104), 48, Color(0.45, 0.14, 0.30, 1))
	quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	quit_button.connect("pressed", self, "_on_quit")
	right.add_child(quit_button)

	var toggles := HBoxContainer.new()
	toggles.alignment = BoxContainer.ALIGN_CENTER
	toggles.add_constant_override("separation", 20)
	right.add_child(toggles)
	_music_button = UITheme.make_button("Music: On", Vector2(320, 80), 32)
# warning-ignore:return_value_discarded
	_music_button.connect("pressed", self, "_on_toggle_music")
	toggles.add_child(_music_button)
	_sound_button = UITheme.make_button("Sound: On", Vector2(320, 80), 32)
# warning-ignore:return_value_discarded
	_sound_button.connect("pressed", self, "_on_toggle_sound")
	toggles.add_child(_sound_button)

	var version := UITheme.make_label(VERSION + "   |   " + CREDIT, 28, UITheme.GOLD)
	right.add_child(version)

	# YouTube button (top-left corner)
	var yt := Button.new()
	yt.rect_position = Vector2(40, 30)
	yt.rect_min_size = Vector2(150, 104)
	yt.rect_size = Vector2(150, 104)
	yt.focus_mode = Control.FOCUS_NONE
	yt.add_stylebox_override("normal", UITheme.box(Color(0.9, 0.1, 0.1, 1), Color(1, 1, 1, 1), 30, 4))
	yt.add_stylebox_override("hover", UITheme.box(Color(1.0, 0.2, 0.2, 1), Color(1, 1, 1, 1), 30, 4))
	yt.add_stylebox_override("pressed", UITheme.box(Color(0.6, 0.05, 0.05, 1), UITheme.GOLD, 30, 4))
	var play := Polygon2D.new()
	play.polygon = PoolVector2Array([Vector2(-20, -26), Vector2(-20, 26), Vector2(28, 0)])
	play.position = Vector2(75, 52)
	play.color = Color(1, 1, 1, 1)
	yt.add_child(play)
# warning-ignore:return_value_discarded
	yt.connect("pressed", self, "_on_youtube")
	screen.add_child(yt)


func _build_levels() -> void:
	var screen := _new_screen("levels")
	screen.add_child(_dim(0.55))

	var center := CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	screen.add_child(center)

	var box := VBoxContainer.new()
	box.add_constant_override("separation", 26)
	center.add_child(box)

	box.add_child(UITheme.make_label("Select Level", 90, UITheme.GOLD, true))

	_levels_grid = GridContainer.new()
	_levels_grid.columns = 10
	_levels_grid.add_constant_override("hseparation", 14)
	_levels_grid.add_constant_override("vseparation", 14)
	box.add_child(_levels_grid)

	var back := UITheme.make_button("Back", Vector2(360, 96), 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	back.connect("pressed", self, "_show", ["main"])
	box.add_child(back)


func _build_confirm() -> void:
	var screen := _new_screen("confirm")
	screen.add_child(_dim(0.8))

	var center := CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	screen.add_child(center)

	var panel := PanelContainer.new()
	panel.add_stylebox_override("panel", UITheme.box(Color(0.14, 0.07, 0.27, 1), UITheme.GOLD, 36, 5))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_constant_override("separation", 28)
	panel.add_child(box)

	box.add_child(UITheme.make_label("Start a new game?", 70, UITheme.GOLD, true))
	var text := UITheme.make_label("Your saved progress will be erased\nand you will start again from Level 1.", 38, UITheme.TEXT)
	box.add_child(text)

	var yes := UITheme.make_button("Yes, start over", Vector2(640, 100), 44, Color(0.45, 0.14, 0.30, 1))
	yes.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	yes.connect("pressed", self, "_start_new_game")
	box.add_child(yes)

	var no := UITheme.make_button("Cancel", Vector2(640, 100), 44)
	no.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	no.connect("pressed", self, "_show", ["main"])
	box.add_child(no)


func _build_victory() -> void:
	var screen := _new_screen("victory")
	screen.add_child(_dim(0.8))

	var center := CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	screen.add_child(center)

	var panel := PanelContainer.new()
	panel.add_stylebox_override("panel", UITheme.box(Color(0.14, 0.07, 0.27, 1), UITheme.GOLD, 36, 5))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_constant_override("separation", 28)
	panel.add_child(box)

	box.add_child(UITheme.make_label("YOU DID IT!", 100, UITheme.GOLD, true))
	box.add_child(UITheme.make_label("You cleared all 50 levels.\nThe cats are very proud of you!", 44, UITheme.TEXT))

	var done := UITheme.make_button("Back to Menu", Vector2(640, 104), 46)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
# warning-ignore:return_value_discarded
	done.connect("pressed", self, "_show", ["main"])
	box.add_child(done)


func _dim(alpha: float) -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.08, alpha)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	return dim


# ---------------------------------------------------------------- refresh

func _refresh_main() -> void:
	if _continue_button == null:
		return
	if SaveData.has_save:
		_continue_button.text = "Continue  (Level %d)" % SaveData.current_level
		_continue_button.disabled = false
	else:
		_continue_button.text = "Continue"
		_continue_button.disabled = true
	_music_button.text = "Music: On" if SaveData.music_on else "Music: Off"
	_sound_button.text = "Sound: On" if SaveData.sfx_on else "Sound: Off"


func _refresh_levels() -> void:
	for child in _levels_grid.get_children():
		_levels_grid.remove_child(child)
		child.queue_free()
	for n in range(1, SaveData.MAX_LEVEL + 1):
		var button := UITheme.make_button(str(n), Vector2(150, 96), 40)
		if n > SaveData.highest_level:
			button.disabled = true
		elif n == SaveData.highest_level:
			UITheme.style_button(button, 40, Color(0.80, 0.50, 0.10, 1))
		button.connect("pressed", self, "_start_game", [n])
		_levels_grid.add_child(button)


# ---------------------------------------------------------------- actions

func _on_continue() -> void:
	_start_game(SaveData.current_level)


func _on_new_game() -> void:
	if SaveData.has_save and SaveData.highest_level > 1:
		_show("confirm")
	else:
		_start_new_game()


func _start_new_game() -> void:
	SaveData.new_game()
	_start_game(1)


func _start_game(level: int) -> void:
	SaveData.pending_level = level
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://src/Main/Game.tscn")


func _on_youtube() -> void:
	AudioManager.play_sfx("click")
# warning-ignore:return_value_discarded
	OS.shell_open(YOUTUBE_URL)


# Finds the logo. Order: 1) imported file, 2) raw file, 3) copy stored inside the code.
func _load_logo() -> Texture:
	if ResourceLoader.exists(LOGO_PATH):
		var imported := load(LOGO_PATH) as Texture
		if imported:
			return imported
	var image := Image.new()
	if File.new().file_exists(LOGO_PATH) and image.load(LOGO_PATH) == OK:
		var raw := ImageTexture.new()
		raw.create_from_image(image)
		return raw
	if image.load_png_from_buffer(Marshalls.base64_to_raw(Embedded.DATA["logo"])) == OK:
		var embedded := ImageTexture.new()
		embedded.create_from_image(image)
		return embedded
	return load("res://icon.png") as Texture


func _on_quit() -> void:
	get_tree().quit()


func _on_toggle_music() -> void:
	SaveData.set_music_on(not SaveData.music_on)


func _on_toggle_sound() -> void:
	SaveData.set_sfx_on(not SaveData.sfx_on)
