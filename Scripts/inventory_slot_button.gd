extends Button

var item_name := ""
var player: Node = null


func setup(new_item_name: String, button_text: String, tooltip: String, player_node: Node):
	item_name = new_item_name
	player = player_node
	text = button_text
	tooltip_text = tooltip
	custom_minimum_size = Vector2(48, 48)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_CENTER


func _get_drag_data(_position):
	if item_name == "":
		return null

	var preview := Label.new()
	preview.text = text
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview)

	return {
		"source": "inventory",
		"item_name": item_name,
		"player": player
	}
