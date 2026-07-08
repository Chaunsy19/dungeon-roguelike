@tool
extends StaticBody2D

const FRONT_TEXTURE := preload("res://assets/Sprites/Interactables/Chest1Front.png")
const REAR_TEXTURE := preload("res://assets/Sprites/Interactables/Chest1Rear.png")

@export_enum("front", "rear") var facing := "front":
	set(value):
		facing = value
		update_sprite()

@export_range(1, 40) var slot_count := 10
@export var starting_items: Array[ChestItemStack] = []

var item_counts := {}

@onready var sprite: Sprite2D = $Sprite2D


func _ready():
	update_sprite()

	if not Engine.is_editor_hint():
		rebuild_contents()


func update_sprite():
	var chest_sprite := get_node_or_null("Sprite2D") as Sprite2D
	if chest_sprite == null:
		return

	if facing == "rear":
		chest_sprite.texture = REAR_TEXTURE
	else:
		chest_sprite.texture = FRONT_TEXTURE


func rebuild_contents():
	item_counts.clear()

	for item_stack in starting_items:
		if item_stack == null:
			continue

		if item_stack.item_name == "" or item_stack.amount <= 0:
			continue

		item_counts[item_stack.item_name] = get_item_count(item_stack.item_name) + item_stack.amount


func interact(player = null):
	if player == null:
		return

	if player.has_method("open_chest"):
		player.open_chest(self)


func get_item_counts() -> Dictionary:
	return item_counts.duplicate()


func get_item_count(item_name: String) -> int:
	return int(item_counts.get(item_name, 0))


func take_item(item_name: String, requested_amount: int) -> int:
	if requested_amount <= 0:
		return 0

	var current_amount := get_item_count(item_name)
	if current_amount <= 0:
		return 0

	var taken_amount = min(current_amount, requested_amount)
	var remaining_amount = current_amount - taken_amount

	if remaining_amount <= 0:
		item_counts.erase(item_name)
	else:
		item_counts[item_name] = remaining_amount

	return taken_amount


func is_empty() -> bool:
	return item_counts.is_empty()
