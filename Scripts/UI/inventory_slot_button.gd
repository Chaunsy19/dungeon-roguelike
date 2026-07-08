extends Button

const SLOT_SIZE := Vector2(48, 48)

var item_name := ""
var item_count := 0
var display_name := ""
var icon_path := ""
var player: Node = null


func setup(new_item_name: String, new_display_name: String, new_icon_path: String, new_item_count: int, tooltip: String, player_node: Node):
	item_name = new_item_name
	display_name = new_display_name
	icon_path = new_icon_path
	item_count = new_item_count
	player = player_node
	tooltip_text = tooltip
	custom_minimum_size = SLOT_SIZE
	clip_contents = true
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = true
	update_slot_visual()


func update_slot_visual():
	clear_slot_visual()
	icon = null

	if item_name == "":
		text = ""
		return

	var texture := get_item_texture()
	if texture == null:
		text = get_fallback_text()
		return

	text = ""
	icon = texture

	if item_count > 1:
		add_count_label()


func clear_slot_visual():
	for child in get_children():
		remove_child(child)
		child.queue_free()


func get_item_texture() -> Texture2D:
	if icon_path == "":
		return null

	if not ResourceLoader.exists(icon_path):
		return null

	var texture := load(icon_path) as Texture2D
	return texture


func get_fallback_text() -> String:
	if item_count > 1:
		return "%s\nx%s" % [display_name, item_count]

	return display_name


func add_count_label():
	var count_label := Label.new()
	count_label.text = str(item_count)
	count_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	count_label.offset_left = 0
	count_label.offset_top = 0
	count_label.offset_right = -3
	count_label.offset_bottom = -2
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	count_label.size_flags_vertical = Control.SIZE_SHRINK_END
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 3)
	add_child(count_label)


func _get_drag_data(_position):
	if item_name == "":
		return null

	var preview := create_drag_preview()
	set_drag_preview(preview)

	return {
		"source": "inventory",
		"item_name": item_name,
		"player": player
	}


func _can_drop_data(_position, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	if data.get("source", "") != "equipment":
		return false

	if not data.has("slot_type"):
		return false

	if player == null:
		return false

	if not player.has_method("can_unequip_item_from_slot"):
		return false

	return player.can_unequip_item_from_slot(data["slot_type"])


func _drop_data(_position, data):
	if player == null:
		return

	if player.has_method("unequip_item_from_slot"):
		player.unequip_item_from_slot(data["slot_type"])


func create_drag_preview() -> Control:
	var texture := get_item_texture()
	if texture == null:
		var preview_label := Label.new()
		preview_label.text = get_fallback_text()
		preview_label.custom_minimum_size = SLOT_SIZE
		return preview_label

	var preview := Control.new()
	preview.custom_minimum_size = SLOT_SIZE

	var icon := TextureRect.new()
	icon.texture = texture
	icon.size = SLOT_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(icon)

	if item_count > 1:
		var count_label := Label.new()
		count_label.text = str(item_count)
		count_label.position = Vector2(0, 25)
		count_label.size = Vector2(45, 20)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 3)
		preview.add_child(count_label)

	return preview
