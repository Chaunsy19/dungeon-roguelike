extends Button

const ITEM_DATABASE_SCRIPT := preload("res://Scripts/item_database.gd")

var slot_type := ""
var player: Node = null
var item_database = ITEM_DATABASE_SCRIPT.new()


func setup(new_slot_type: String, player_node: Node):
	slot_type = new_slot_type
	player = player_node
	custom_minimum_size = Vector2(48, 48)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	update_text("")


func update_text(item_name: String):
	if item_name == "":
		text = get_slot_label(slot_type)
	else:
		text = get_slot_label(slot_type) + "\n" + item_database.get_display_name(item_name)


func _can_drop_data(_position, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	if not data.has("item_name"):
		return false

	if player == null:
		return false

	if not player.has_method("can_equip_item_to_slot"):
		return false

	return player.can_equip_item_to_slot(data["item_name"], slot_type)


func _drop_data(_position, data):
	if player == null:
		return

	if player.has_method("equip_item_to_slot"):
		player.equip_item_to_slot(data["item_name"], slot_type)


func get_slot_label(target_slot_type: String) -> String:
	if target_slot_type == "head":
		return "Head"
	if target_slot_type == "chest":
		return "Chest"
	if target_slot_type == "legs":
		return "Legs"
	if target_slot_type == "gloves":
		return "Gloves"
	if target_slot_type == "boots":
		return "Boots"
	if target_slot_type == "ring_1":
		return "Ring"
	if target_slot_type == "ring_2":
		return "Ring"
	if target_slot_type == "necklace":
		return "Neck"
	if target_slot_type == "bag":
		return "Bag"

	return target_slot_type.capitalize()
