tool
extends Node2D
# Draws a rectangle with an outline


export var size := Vector2(40.0, 40.0) setget set_size
export var outline := Vector2(6.0, 6.0) setget set_outline

export var color_fill := Color(0.890625, 0.583793, 0.149597) setget set_color_fill
export var color_outline := Color(0.890625, 0.583793, 0.149597) setget set_color_outline


# Cat mode: draws a cute cat face instead of a plain rectangle
export var cat_style := false setget set_cat_style
export var cat_angry := false setget set_cat_angry


func _draw() -> void:
	if cat_style:
		_draw_cat()
		return
	var size_complete := size + outline
	var rect_outline := Rect2(-size_complete / 2, size_complete)
	var rect_fill := Rect2(-size / 2, size)
	draw_rect(rect_outline, color_outline)
	draw_rect(rect_fill, color_fill)


func set_size(value:Vector2) -> void:
	size = value
	update()

func set_outline(value:Vector2) -> void:
	outline = value
	update()


func set_color_fill(value:Color) -> void:
	color_fill = value
	update()


func set_color_outline(value:Color) -> void:
	color_outline = value
	update()


func set_cat_style(value: bool) -> void:
	cat_style = value
	update()


func set_cat_angry(value: bool) -> void:
	cat_angry = value
	update()


func _ellipse(rx: float, ry: float) -> PoolVector2Array:
	var points := PoolVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		points.append(Vector2(cos(a) * rx, sin(a) * ry))
	return points


func _scaled_tri(p0: Vector2, p1: Vector2, p2: Vector2, k: float) -> PoolVector2Array:
	var c := (p0 + p1 + p2) / 3.0
	return PoolVector2Array([c + (p0 - c) * k, c + (p1 - c) * k, c + (p2 - c) * k])


func _draw_ear(side: float, rx: float, ry: float, alpha: float) -> void:
	var p0 := Vector2(side * rx * 0.15, -ry * 0.85)
	var p1 := Vector2(side * rx * 0.92, -ry * 0.35)
	var p2 := Vector2(side * rx * 0.70, -ry * 1.45)
	draw_colored_polygon(_scaled_tri(p0, p1, p2, 1.22), color_outline)
	draw_colored_polygon(_scaled_tri(p0, p1, p2, 1.0), color_fill)
	draw_colored_polygon(_scaled_tri(p0, p1, p2, 0.55), Color(1.0, 0.65, 0.75, alpha))


func _draw_cat() -> void:
	var alpha: float = color_fill.a
	var rx: float = size.x * 0.5
	var ry: float = size.y * 0.5
	_draw_ear(-1.0, rx, ry, alpha)
	_draw_ear(1.0, rx, ry, alpha)
	draw_colored_polygon(_ellipse(rx + outline.x * 0.5, ry + outline.y * 0.5), color_outline)
	draw_colored_polygon(_ellipse(rx, ry), color_fill)
	# cheeks
	draw_circle(Vector2(-rx * 0.62, ry * 0.25), ry * 0.16, Color(1.0, 0.6, 0.7, alpha * 0.55))
	draw_circle(Vector2(rx * 0.62, ry * 0.25), ry * 0.16, Color(1.0, 0.6, 0.7, alpha * 0.55))
	# eyes
	var white := Color(1, 1, 1, alpha)
	var dark := Color(0.08, 0.04, 0.14, alpha)
	var eye_r := ry * 0.30
	for side in [-1.0, 1.0]:
		var c := Vector2(side * rx * 0.38, -ry * 0.12)
		draw_circle(c, eye_r, white)
		draw_circle(c + Vector2(0, ry * 0.03), eye_r * (0.5 if cat_angry else 0.62), dark)
		draw_circle(c + Vector2(-eye_r * 0.2, -eye_r * 0.2), eye_r * 0.18, white)
		if cat_angry:
			draw_line(c + Vector2(-side * eye_r * 1.1, -eye_r * 1.5), c + Vector2(side * eye_r * 0.9, -eye_r * 0.7), dark, 4.0)
	# nose and mouth
	var nose := Vector2(0, ry * 0.16)
	draw_colored_polygon(PoolVector2Array([nose + Vector2(-ry * 0.1, 0), nose + Vector2(ry * 0.1, 0), nose + Vector2(0, ry * 0.12)]), Color(1.0, 0.55, 0.65, alpha))
	draw_arc(nose + Vector2(-ry * 0.1, ry * 0.12), ry * 0.1, 0.0, PI * 0.9, 8, dark, 2.0)
	draw_arc(nose + Vector2(ry * 0.1, ry * 0.12), ry * 0.1, PI * 0.1, PI, 8, dark, 2.0)
	# whiskers
	var whisker := Color(1, 1, 1, alpha * 0.85)
	for side in [-1.0, 1.0]:
		for k in range(2):
			var from := Vector2(side * rx * 0.55, ry * (0.25 + 0.14 * k))
			var to := Vector2(side * (rx + 14.0), ry * (0.12 + 0.3 * k))
			draw_line(from, to, whisker, 2.0)
