extends PanelContainer

const ITEM_DATABASE_SCRIPT := preload("res://Scripts/UI/item_database.gd")
const LOOT_SLOT_BUTTON_SCRIPT := preload("res://Scripts/UI/loot_slot_button.gd")

var active_chest: Node = null
var player: Node = null
var item_database = ITEM_DATABASE_SCRIPT.new()

@onready var title_label: Label = $Layout/Header/Title
@onready var close_button: Button = $Layout/Header/Close
@onready var slot_grid: GridContainer = $Layout/SlotGrid


func _ready():
	visible = false
	close_button.pressed.connect(close_chest)


func _unhandled_input(event: InputEvent):
	if not visible:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			close_chest()
			get_viewport().set_input_as_handled()


func open_chest(chest: Node, player_node: Node):
	active_chest = chest
	player = player_node
	visible = true
	refresh()


func close_chest():
	visible = false
	active_chest = null
	player = null


func refresh():
	clear_slots()

	if active_chest == null:
		return

	var item_counts: Dictionary = active_chest.get_item_counts()
	var item_names := item_counts.keys()
	item_names.sort_custom(func(a, b): return item_database.get_inventory_sort_order(a) < item_database.get_inventory_sort_order(b))

	for slot_index in range(active_chest.slot_count):
		if slot_index < item_names.size():
			var item_name: String = item_names[slot_index]
			add_slot(item_name, int(item_counts[item_name]))
		else:
			add_slot("", 0)

	if active_chest.is_empty():
		title_label.text = "Chest - Empty"
	else:
		title_label.text = "Chest"


func clear_slots():
	for child in slot_grid.get_children():
		slot_grid.remove_child(child)
		child.queue_free()


func add_slot(item_name: String, amount: int):
	var button := Button.new()
	button.set_script(LOOT_SLOT_BUTTON_SCRIPT)
	button.call("setup", item_name, amount)

	if item_name != "":
		button.pressed.connect(take_stack.bind(item_name))

	slot_grid.add_child(button)


func take_stack(item_name: String):
	if active_chest == null or player == null:
		return

	if not active_chest.has_method("take_item"):
		return

	if not player.has_method("add_item"):
		return

	var amount := int(active_chest.take_item(item_name, active_chest.get_item_count(item_name)))
	if amount <= 0:
		return

	player.add_item(item_name, amount)
	refresh()
