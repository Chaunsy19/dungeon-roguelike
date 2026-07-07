@tool
extends Node2D

@export var size := Vector2(32, 32):
	set(value):
		size = value
		update_shadow_shape()

@export var show_editor_preview := true:
	set(value):
		show_editor_preview = value
		update_shadow_shape()

@onready var light_occluder: LightOccluder2D = $LightOccluder2D
@onready var editor_preview: Polygon2D = $EditorPreview


func _ready():
	update_shadow_shape()


func _process(_delta):
	if Engine.is_editor_hint():
		update_shadow_shape()


func update_shadow_shape():
	var half_size: Vector2 = size * 0.5
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])

	var target_occluder: LightOccluder2D = light_occluder
	if target_occluder == null:
		target_occluder = get_node_or_null("LightOccluder2D") as LightOccluder2D

	if target_occluder != null:
		var polygon: OccluderPolygon2D = target_occluder.occluder
		if polygon == null:
			polygon = OccluderPolygon2D.new()
			target_occluder.occluder = polygon

		polygon.closed = true
		polygon.polygon = points

	var preview: Polygon2D = editor_preview
	if preview == null:
		preview = get_node_or_null("EditorPreview") as Polygon2D

	if preview != null:
		preview.polygon = points
		preview.visible = Engine.is_editor_hint() and show_editor_preview
