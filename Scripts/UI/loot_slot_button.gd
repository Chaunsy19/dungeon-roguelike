extends Button

const ITEM_DATABASE_SCRIPT := preload("res://Scripts/UI/item_database.gd")
const SLOT_SIZE := Vector2(48, 48)

var item_name := ""
var item_count := 0
var item_database = ITEM_DATABASE_SCRIPT.new()


func setup(new_item_name: String, new_item_count: int):
	item_name = new_item_name
	item_count = new_item_count
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
		tooltip_text = "Empty chest slot"
		disabled = true
		return

	disabled = false
	tooltip_text = "Take %s" % item_database.get_inventory_name(item_name)

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
	var icon_path := item_database.get_icon_path(item_name)
	if icon_path == "":
		return null

	if not ResourceLoader.exists(icon_path):
		return null

	var texture := load(icon_path) as Texture2D
	return texture


func get_fallback_text() -> String:
	if item_count > 1:
		return "%s\nx%s" % [item_database.get_inventory_name(item_name), item_count]

	return item_database.get_inventory_name(item_name)


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
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 3)
	add_child(count_label)
