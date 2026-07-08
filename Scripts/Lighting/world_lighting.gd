@tool
extends Node2D

@export_range(0.0, 100.0, 1.0) var world_darkness := 98.0:
	set(value):
		world_darkness = value
		apply_world_darkness()

@export var darkness_tint := Color(0.85, 0.93, 1.25, 1.0):
	set(value):
		darkness_tint = value
		apply_world_darkness()

@onready var world_darkness_node: CanvasModulate = $WorldDarkness


func _ready():
	apply_world_darkness()


func apply_world_darkness():
	var darkness_percent: float = clamp(world_darkness, 0.0, 100.0)
	var darkness_amount: float = darkness_percent / 100.0
	var brightness: float = lerp(1.0, 0.04, darkness_amount)
	var darkness_color: Color = Color(
		clamp(brightness * darkness_tint.r, 0.0, 1.0),
		clamp(brightness * darkness_tint.g, 0.0, 1.0),
		clamp(brightness * darkness_tint.b, 0.0, 1.0),
		1.0
	)
	var target: CanvasModulate = world_darkness_node

	if target == null:
		target = get_node_or_null("WorldDarkness") as CanvasModulate

	if target != null:
		target.color = darkness_color
