extends StaticBody2D

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
