extends StaticBody2D
# A solid block of grassy ground. Collision and drawing are both done here.
# The top-left corner of the block is the node's position.

const TILESET := preload("res://assets/tilesets/tileset.png")
const CELL := 80.0
const DIRT_COLOR := Color(0.341, 0.224, 0.200, 1.0)
const DRAWN_ROWS := 4

var width := 400.0
var depth := 1400.0


func setup(block_width: float, block_depth: float = 1400.0) -> void:
	width = block_width
	depth = block_depth
	collision_layer = 2
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.extents = Vector2(width * 0.5, depth * 0.5)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(width * 0.5, depth * 0.5)
	add_child(collider)
	update()


func _draw() -> void:
	var columns := int(round(width / CELL))
	if columns < 1:
		columns = 1
	# plain dirt below the tiled rows
	var body_top := CELL * DRAWN_ROWS
	draw_rect(Rect2(0.0, body_top - 2.0, width, depth - body_top + 2.0), DIRT_COLOR)
	var cell_width := width / float(columns)
	for row in range(DRAWN_ROWS):
		var source_row := 0 if row == 0 else 1
		for column in range(columns):
			var source_column := 1
			if column == 0:
				source_column = 0
			elif column == columns - 1:
				source_column = 2
			var source := Rect2(source_column * CELL, source_row * CELL, CELL, CELL)
			var target := Rect2(column * cell_width, row * CELL, cell_width + 0.5, CELL + 0.5)
			draw_texture_rect_region(TILESET, target, source)
