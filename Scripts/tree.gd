extends StaticBody2D

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
