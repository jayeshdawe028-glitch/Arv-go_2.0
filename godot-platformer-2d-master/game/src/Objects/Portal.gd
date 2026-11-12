extends Area2D
# The exit portal of a level. Touching it completes the level.
# Only portals in the group "level_exit" finish the level (the loader sets this up),
# so decorative portals do nothing.


export(String, FILE) var next_level_file_path := ""
export(String) var next_level_portal_name := ""


func _ready() -> void:
# warning-ignore:return_value_discarded
	connect("body_entered", self, "_on_body_entered")


func _on_body_entered(body: PhysicsBody2D) -> void:
	if not body is Player:
		return
	if not is_in_group("level_exit"):
		return
	LevelLoader.finish_level()
