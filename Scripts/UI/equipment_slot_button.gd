extends Button

const ITEM_DATABASE_SCRIPT := preload("res://Scripts/UI/item_database.gd")
const SLOT_SIZE := Vector2(48, 48)

var slot_type := ""
var equipped_item := ""
var player: Node = null
var item_database = ITEM_DATABASE_SCRIPT.new()


func setup(new_slot_type: String, player_node: Node):
	slot_type = new_slot_type
	player = player_node
	custom_minimum_size = SLOT_SIZE
	clip_contents = true
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = true
	update_text("")


func update_text(item_name: String):
	clear_slot_visual()
	icon = null
	equipped_item = item_name

	if item_name == "":
		text = get_slot_label(slot_type)
		tooltip_text = get_slot_label(slot_type)
		return

	var display_name := item_database.get_display_name(item_name)
	var texture := get_item_texture(item_name)

	if texture == null:
		text = get_slot_label(slot_type) + "\n" + display_name
	else:
		text = ""
		icon = texture

	tooltip_text = "%s: %s" % [get_slot_label(slot_type), display_name]


func clear_slot_visual():
	for child in get_children():
		remove_child(child)
		child.queue_free()


func get_item_texture(item_name: String) -> Texture2D:
	var icon_path := item_database.get_icon_path(item_name)
	if icon_path == "":
		return null

	if not ResourceLoader.exists(icon_path):
		return null

	var texture := load(icon_path) as Texture2D
	return texture


func _can_drop_data(_position, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	if not data.has("item_name"):
		return false

	if data.get("source", "") != "inventory":
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


func _get_drag_data(_position):
	if equipped_item == "":
		return null

	var preview := create_drag_preview()
	set_drag_preview(preview)

	return {
		"source": "equipment",
		"slot_type": slot_type,
		"item_name": equipped_item,
		"player": player
	}


func create_drag_preview() -> Control:
	var texture := get_item_texture(equipped_item)
	if texture == null:
		var preview_label := Label.new()
		preview_label.text = item_database.get_display_name(equipped_item)
		preview_label.custom_minimum_size = SLOT_SIZE
		return preview_label

	var preview := Control.new()
	preview.custom_minimum_size = SLOT_SIZE

	var icon_preview := TextureRect.new()
	icon_preview.texture = texture
	icon_preview.size = SLOT_SIZE
	icon_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(icon_preview)

	return preview


func _gui_input(event: InputEvent):
	if equipped_item == "":
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if player != null and player.has_method("unequip_item_from_slot"):
				player.unequip_item_from_slot(slot_type)
				accept_event()


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
