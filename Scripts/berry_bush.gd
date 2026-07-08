extends StaticBody2D

const WORLD_ACTION_GATHER := 105

@export var respawn_time := 8.0

var can_gather := true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var bush_shape: Polygon2D = $Polygon2D

func gather():
	if can_gather == false:
		return

	can_gather = false
	print("Gathered berries!")

	bush_shape.visible = false
	collision_shape.disabled = true

	await get_tree().create_timer(respawn_time).timeout

	bush_shape.visible = true
	collision_shape.disabled = false
	can_gather = true


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
	if not can_gather:
		return []

	return [
		{
			"label": "Gather",
			"id": WORLD_ACTION_GATHER
		}
	]


func perform_world_action(action_id: int, player = null):
	if action_id != WORLD_ACTION_GATHER:
		return

	if not can_gather:
		return

	gather()

	if player != null and player.has_method("add_berries"):
		player.add_berries(1)
