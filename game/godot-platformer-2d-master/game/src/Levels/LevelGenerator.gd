extends Reference
# Builds levels 3 to 50 in code. Every level is always completable:
#  - gaps between platforms are smaller than the player's jump (max jump is about 300 px)
#  - steps up are never higher than 80 px (the jump is about 135 px high)
#  - the difficulty (more/narrower platforms, wider gaps, more cats, moving platforms) grows with the level number

const GroundBlock := preload("res://src/Levels/GroundBlock.gd")
const CheckpointScene := preload("res://src/Objects/Checkpoint.tscn")
const PortalScene := preload("res://src/Objects/Portal.tscn")
const FallLimitScene := preload("res://src/Objects/FallLimitArea.tscn")
const HookTargetScene := preload("res://src/Objects/HookTarget.tscn")
const PatrolScene := preload("res://src/AI/EnemyPassivePatrol.tscn")
const HopperScene := preload("res://src/AI/HopperEnemy.tscn")
const MovingPlatformScene := preload("res://src/Objects/MovingPlatform/MovingPlatform.tscn")
const WaypointsScene := preload("res://src/Objects/MovingPlatform/Waypoints.tscn")

const PROP_PATHS := [
	"res://assets/environment/props/bush_01.png",
	"res://assets/environment/props/bush_02.png",
	"res://assets/environment/props/rock_01.png",
	"res://assets/environment/props/rock_02.png",
	"res://assets/environment/props/birch_tree_01.png",
	"res://assets/environment/props/birch_tree_02.png",
	"res://assets/environment/props/birch_tree_03.png",
]

# Ground colour for each group of 10 levels
const WORLD_TINTS := [
	Color(1, 1, 1, 1),
	Color(0.82, 0.72, 1.0, 1),
	Color(1.0, 0.86, 0.68, 1),
	Color(0.72, 0.9, 1.1, 1),
	Color(1.0, 0.72, 0.8, 1),
]

const BASE_Y := 1000.0
const MIN_Y := 560.0
const MAX_Y := 1360.0

var _rng := RandomNumberGenerator.new()


func build(number: int) -> Node2D:
	_rng.seed = number * 7919 + 101
	var t: float = clamp((number - 3) / 47.0, 0.0, 1.0)
	var tint: Color = WORLD_TINTS[int(clamp((number - 1) / 10, 0, 4))]

	var level := Node2D.new()
	level.name = "Level%d" % number
	var checkpoints := Node.new()
	checkpoints.name = "Checkpoints"
	level.add_child(checkpoints)
	var decor := Node2D.new()
	decor.name = "Decor"
	level.add_child(decor)

	var segment_count := 12 + int(number * 0.8)
	var min_tiles := int(lerp(5, 2, t))
	var max_tiles := int(lerp(9, 4, t))

	var x := 0.0
	var y := BASE_Y
	var lowest := y
	var segments := []   # each: {x, y, w}

	for i in range(segment_count):
		var w: float
		if i == 0:
			w = 80.0 * 12.0
		elif i == segment_count - 1:
			w = 80.0 * 10.0
		else:
			w = 80.0 * _rng.randi_range(min_tiles, max_tiles)
		var block := GroundBlock.new()
		block.position = Vector2(x, y)
		block.modulate = tint
		block.setup(w)
		level.add_child(block)
		segments.append({x = x, y = y, w = w})
		lowest = max(lowest, y)

		if i == segment_count - 1:
			break

		var roll := _rng.randf()
		var hook_chance := 0.30 + 0.30 * t
		var climb_chance := 0.0 if number < 6 else 0.12 + 0.12 * t
		var mover_chance := 0.0 if number < 8 else 0.08 + 0.18 * t
		var gap: float
		var next_y: float = y

		if i > 0 and roll < hook_chance:
			# ---- HOOK PIT: too wide to jump, swing across with hook targets
			gap = _snap(_rng.randf_range(lerp(420.0, 600.0, t), lerp(560.0, 1000.0, t)), 20.0)
			next_y = y + 40.0 * _rng.randi_range(-1, 2)
			_add_hook_chain(level, x + w, gap, y, next_y)
		elif i > 0 and roll < hook_chance + climb_chance and y - 200.0 > BASE_Y - 1200.0:
			# ---- HOOK CLIMB: the next platform is higher than a jump, hook up to it
			var rise := 160.0 if _rng.randf() < 0.5 else 200.0
			gap = 120.0
			next_y = y - rise
			var up_target := HookTargetScene.instance()
			up_target.position = Vector2(x + w + gap - 30.0, next_y - 130.0)
			level.add_child(up_target)
		elif i > 0 and i < segment_count - 2 and roll < hook_chance + climb_chance + mover_chance:
			# ---- MOVING PLATFORM bridges the gap
			gap = _snap(_rng.randf_range(280.0, 340.0), 20.0)
			_add_mover(level, x + w, y, x + w + gap, t)
		else:
			# ---- PARKOUR JUMP: normal jump gap, sometimes a drop or a small step up
			gap = _snap(_rng.randf_range(lerp(120.0, 160.0, t), lerp(180.0, 220.0, t)), 20.0)
			var max_up := 80.0 if gap <= 160.0 else 40.0
			var dy := _snap(_rng.randf_range(-200.0, max_up), 40.0)   # negative = lower
			if _rng.randf() < 0.3:
				dy = 0.0
			next_y = clamp(y - dy, BASE_Y - 1200.0, BASE_Y + 500.0)
		x += w + gap
		y = next_y

	# ---- invisible wall behind the start
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask = 0
	var wall_shape := RectangleShape2D.new()
	wall_shape.extents = Vector2(40, 1500)
	var wall_collider := CollisionShape2D.new()
	wall_collider.shape = wall_shape
	wall.add_child(wall_collider)
	wall.position = Vector2(-40, BASE_Y)
	level.add_child(wall)

	# ---- start point, checkpoints, exit
	var start := Node2D.new()
	start.name = "0"
	start.position = Vector2(200, BASE_Y)
	checkpoints.add_child(start)

	var interval := 4
	var cp_index := 1
	for i in range(interval, segment_count - 1, interval):
		var seg: Dictionary = segments[i]
		var cp := CheckpointScene.instance()
		cp.name = str(cp_index)
		cp.position = Vector2(seg.x + 140.0, seg.y)
		checkpoints.add_child(cp)
		cp_index += 1

	var last: Dictionary = segments[segment_count - 1]
	var portal := PortalScene.instance()
	portal.position = Vector2(last.x + last.w * 0.6, last.y)
	portal.add_to_group("level_exit")
	level.add_child(portal)

	# ---- cats and decoration
	_add_enemies(level, segments, number, t)
	_add_props(decor, segments)

	# ---- falling below the world = death
	var fall := FallLimitScene.instance()
	fall.position = Vector2(0, lowest + 1000.0)
	level.add_child(fall)
	return level


func _snap(value: float, step: float) -> float:
	return round(value / step) * step


# Places 1-3 hook targets over a pit. The player jumps, then hooks from target to target.
# Targets are at most ~340 px apart (the hook reaches about 400 px).
func _add_hook_chain(level: Node2D, pit_x: float, width: float, y_left: float, y_right: float) -> void:
	var count := 1
	if width > 560.0:
		count = 2
	if width > 800.0:
		count = 3
	var top := min(y_left, y_right)
	for k in range(count):
		var tx: float
		if count == 1:
			tx = pit_x + width * 0.5
		else:
			tx = pit_x + 220.0 + (width - 420.0) * float(k) / float(count - 1)
		var target := HookTargetScene.instance()
		target.position = Vector2(tx, top - 230.0 + (40.0 if k % 2 == 1 else 0.0))
		level.add_child(target)


func _add_mover(level: Node2D, from_x: float, y: float, to_x: float, t: float) -> void:
	var platform := MovingPlatformScene.instance()
	var waypoints := WaypointsScene.instance()
	waypoints.name = "Waypoints"
	waypoints.points = PoolVector2Array([Vector2(from_x - 40.0, y + 18.0), Vector2(to_x + 40.0, y + 18.0)])
	waypoints.mode = 1   # ping-pong
	platform.add_child(waypoints)
	platform.speed = lerp(150.0, 260.0, t)
	platform.modulate = Color(0.85, 0.7, 1.0, 1)
	level.add_child(platform)


func _add_enemies(level: Node2D, segments: Array, number: int, t: float) -> void:
	var count := int(2 + number * 0.35)
	var candidates := []
	for i in range(2, segments.size() - 1):
		if segments[i].w >= 80.0 * 5:
			candidates.append(i)
	candidates.shuffle()
	for k in range(min(count, candidates.size())):
		var seg: Dictionary = segments[candidates[k]]
		var use_hopper := number >= 8 and _rng.randf() < 0.4
		var enemy: Node2D
		if use_hopper:
			enemy = HopperScene.instance()
			enemy.position = Vector2(seg.x + seg.w * 0.5, seg.y - 34.0)
			enemy.direction = 1 if _rng.randf() < 0.5 else -1
		else:
			enemy = PatrolScene.instance()
			enemy.position = Vector2(seg.x + seg.w * 0.5, seg.y - 31.0)
			enemy.direction = 1 if _rng.randf() < 0.5 else -1
			enemy.move_speed = lerp(100.0, 240.0, t)
			enemy.patrol_range = seg.w * 0.5 - 90.0
		level.add_child(enemy)
		if number >= 20 and enemy.has_node("Body"):
			enemy.get_node("Body").cat_angry = true


func _add_props(decor: Node2D, segments: Array) -> void:
	var textures := []
	for path in PROP_PATHS:
		if ResourceLoader.exists(path):
			textures.append(load(path))
	if textures.empty():
		return
	for seg in segments:
		var amount := _rng.randi_range(0, 2)
		for k in range(amount):
			var texture: Texture = textures[_rng.randi() % textures.size()]
			var sprite := Sprite.new()
			sprite.texture = texture
			var px: float = seg.x + _rng.randf_range(60.0, seg.w - 60.0)
			sprite.position = Vector2(px, seg.y - texture.get_height() * 0.5 + 8.0)
			decor.add_child(sprite)
