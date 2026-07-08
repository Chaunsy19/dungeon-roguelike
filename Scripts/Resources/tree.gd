extends StaticBody2D

const WORLD_ACTION_CHOP := 104

@export var respawn_time := 5.0

var can_chop := true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tree_shape: Polygon2D = $Polygon2D

func chop():
	if can_chop == false:
		return

	can_chop = false
	print("Chopped tree!")

	tree_shape.visible = false
	collision_shape.disabled = true

	await get_tree().create_timer(respawn_time).timeout

	tree_shape.visible = true
	collision_shape.disabled = false
	can_chop = true


func _input_event(_viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			show_action_menu(event.position)


func show_action_menu(screen_position: Vector2):
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	if player.has_method("show_world_action_menu"):
		player.show_world_action_menu(self, screen_position)


func get_world_actions(_player = null) -> Array:
	if not can_chop:
		return []

	return [
		{
			"label": "Chop",
			"id": WORLD_ACTION_CHOP
		}
	]


func perform_world_action(action_id: int, player = null):
	if action_id != WORLD_ACTION_CHOP:
		return

	if not can_chop:
		return

	chop()

	if player != null:
		if player.has_method("add_wood"):
			player.add_wood(1)

		if player.has_method("gain_woodcutting_xp"):
			player.gain_woodcutting_xp(10)
