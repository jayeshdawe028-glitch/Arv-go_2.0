extends Reference
# Colors, fonts and button styles shared by all screens (menu, HUD, pause).
# Change the colors here to restyle the whole game.

const BG_DARK := Color(0.07, 0.04, 0.14, 1.0)
const BG_MID := Color(0.20, 0.10, 0.36, 1.0)
const PURPLE := Color(0.36, 0.18, 0.62, 1.0)
const PURPLE_LIGHT := Color(0.52, 0.30, 0.82, 1.0)
const GOLD := Color(0.97, 0.78, 0.31, 1.0)
const TEXT := Color(1, 1, 1, 1)
const TEXT_DIM := Color(0.8, 0.72, 0.95, 1.0)
const LOCKED := Color(0.25, 0.22, 0.32, 1.0)

const FONT_BOLD := "res://assets/theme/fonts/montserrat/Montserrat-Bold.ttf"
const FONT_BLACK := "res://assets/theme/fonts/montserrat/Montserrat-Black.ttf"


static func font(size: int, black := false) -> DynamicFont:
	var data := DynamicFontData.new()
	data.font_path = FONT_BLACK if black else FONT_BOLD
	var f := DynamicFont.new()
	f.font_data = data
	f.size = size
	f.use_filter = true
	return f


static func box(fill: Color, border: Color = GOLD, radius := 28, border_width := 5) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func style_button(button: Button, font_size := 44, fill: Color = PURPLE, border: Color = GOLD) -> void:
	button.add_font_override("font", font(font_size))
	button.add_color_override("font_color", TEXT)
	button.add_color_override("font_color_hover", TEXT)
	button.add_color_override("font_color_pressed", GOLD)
	button.add_color_override("font_color_disabled", Color(1, 1, 1, 0.35))
	button.add_stylebox_override("normal", box(fill, border))
	button.add_stylebox_override("hover", box(fill.lightened(0.12), border))
	button.add_stylebox_override("pressed", box(fill.darkened(0.2), GOLD))
	button.add_stylebox_override("disabled", box(LOCKED, Color(0.4, 0.35, 0.5, 1)))
	button.add_stylebox_override("focus", StyleBoxEmpty.new())
	button.focus_mode = Control.FOCUS_NONE


static func make_button(text: String, size: Vector2, font_size := 44, fill: Color = PURPLE) -> Button:
	var button := Button.new()
	button.text = text
	button.rect_min_size = size
	style_button(button, font_size, fill)
	button.pause_mode = Node.PAUSE_MODE_PROCESS
# warning-ignore:return_value_discarded
	button.connect("pressed", AudioManager, "play_sfx", ["click"])
	return button


static func make_label(text: String, font_size: int, color: Color = TEXT, black := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_font_override("font", font(font_size, black))
	label.add_color_override("font_color", color)
	label.add_color_override("font_color_shadow", Color(0, 0, 0, 0.55))
	label.add_constant_override("shadow_offset_x", 3)
	label.add_constant_override("shadow_offset_y", 4)
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	return label
