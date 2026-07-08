extends RefCounted

const BASE_INVENTORY_SLOT_COUNT := 10
const EQUIPMENT_SLOT_TYPES := ["head", "chest", "legs", "gloves", "boots", "ring_1", "ring_2", "necklace", "bag"]
const EQUIPMENT_SLOT_LAYOUT := [
	"", "", "head", "", "",
	"gloves", "", "necklace", "", "boots",
	"", "ring_1", "chest", "ring_2", "",
	"", "", "legs", "bag", ""
]
const INVENTORY_SLOT_BUTTON_SCRIPT := preload("res://Scripts/inventory_slot_button.gd")
const EQUIPMENT_SLOT_BUTTON_SCRIPT := preload("res://Scripts/equipment_slot_button.gd")
const ITEM_DATABASE_SCRIPT := preload("res://Scripts/item_database.gd")

var player: Node
var inventory_list: GridContainer
var equipment_slots: GridContainer
var menu: Control
var item_database = ITEM_DATABASE_SCRIPT.new()

var item_counts := {}
var equipment := {}


func setup(player_node: Node, inventory_grid: GridContainer, equipment_grid: GridContainer, menu_node: Control):
	player = player_node
	inventory_list = inventory_grid
	equipment_slots = equipment_grid
	menu = menu_node

	setup_equipment_slots()
	update_inventory_list()
	update_equipment_slots()


func add_wood(amount: int):
	add_item("wood", amount)


func add_berries(amount: int):
	add_item("berries", amount)


func add_item(item_name: String, amount: int):
	if amount <= 0:
		return

	if not item_database.has_item(item_name):
		push_warning("Unknown inventory item: %s" % item_name)

	item_counts[item_name] = get_item_count(item_name) + amount
	update_inventory_list()


func consume_berry() -> bool:
	return remove_item("berries", 1)


func remove_item(item_name: String, amount: int) -> bool:
	if amount <= 0:
		return false

	var current_amount := get_item_count(item_name)
	if current_amount < amount:
		return false

	var new_amount := current_amount - amount
	if new_amount <= 0:
		item_counts.erase(item_name)
	else:
		item_counts[item_name] = new_amount

	update_inventory_list()
	return true


func get_item_count(item_name: String) -> int:
	return int(item_counts.get(item_name, 0))


func get_wood() -> int:
	return get_item_count("wood")


func get_berries() -> int:
	return get_item_count("berries")


func update_inventory_list():
	if inventory_list == null:
		return

	for child in inventory_list.get_children():
		inventory_list.remove_child(child)
		child.queue_free()

	var items := []

	var item_names := item_counts.keys()
	item_names.sort_custom(func(a, b): return item_database.get_inventory_sort_order(a) < item_database.get_inventory_sort_order(b))

	for item_name in item_names:
		var amount := get_item_count(item_name)
		if amount > 0:
			items.append(get_inventory_item_entry(item_name, amount))

	for slot_index in range(get_inventory_slot_count()):
		if slot_index < items.size():
			var item = items[slot_index]
			add_inventory_slot(item["name"], item["display_name"], item["icon_path"], item["amount"], item["tooltip"])
		else:
			add_inventory_slot("", "", "", 0, "Empty inventory slot")

	request_menu_fit_to_content()


func add_inventory_slot(item_name: String, display_name: String, icon_path: String, amount: int, tooltip: String):
	var button := Button.new()
	button.set_script(INVENTORY_SLOT_BUTTON_SCRIPT)
	button.call("setup", item_name, display_name, icon_path, amount, tooltip, player)
	button.gui_input.connect(Callable(player, "_on_inventory_item_gui_input").bind(item_name))
	inventory_list.add_child(button)


func get_inventory_item_entry(item_name: String, amount: int) -> Dictionary:
	return {
		"display_name": item_database.get_inventory_name(item_name),
		"icon_path": item_database.get_icon_path(item_name),
		"amount": amount,
		"tooltip": item_database.get_inventory_tooltip(item_name),
		"name": item_name
	}


func setup_equipment_slots():
	if equipment_slots == null:
		return

	for slot_type in EQUIPMENT_SLOT_TYPES:
		equipment[slot_type] = ""

	for child in equipment_slots.get_children():
		equipment_slots.remove_child(child)
		child.queue_free()

	for slot_type in EQUIPMENT_SLOT_LAYOUT:
		if slot_type == "":
			add_equipment_spacer()
		else:
			add_equipment_slot(slot_type)

	request_menu_fit_to_content()


func add_equipment_slot(slot_type: String):
	var button := Button.new()
	button.set_script(EQUIPMENT_SLOT_BUTTON_SCRIPT)
	button.call("setup", slot_type, player)
	equipment_slots.add_child(button)


func add_equipment_spacer():
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(48, 48)
	equipment_slots.add_child(spacer)


func update_equipment_slots():
	if equipment_slots == null:
		return

	for child in equipment_slots.get_children():
		var slot_type_value = child.get("slot_type")
		if typeof(slot_type_value) != TYPE_STRING:
			continue

		var slot_type: String = slot_type_value
		var equipped_item: String = ""
		if equipment.has(slot_type):
			equipped_item = equipment[slot_type]

		if child.has_method("update_text"):
			child.update_text(equipped_item)

	request_menu_fit_to_content()


func request_menu_fit_to_content():
	if menu == null:
		return

	if menu.has_method("request_fit_to_content"):
		menu.call("request_fit_to_content")


func get_inventory_slot_count() -> int:
	var bag_item := ""

	if equipment.has("bag"):
		bag_item = equipment["bag"]

	return BASE_INVENTORY_SLOT_COUNT + get_bag_slot_bonus(bag_item)


func get_bag_slot_bonus(item_name: String) -> int:
	return item_database.get_bag_slot_bonus(item_name)


func can_equip_item_to_slot(item_name: String, slot_type: String) -> bool:
	if item_name == "":
		return false

	var item_slot_type := get_item_equipment_slot(item_name)

	if item_slot_type == "":
		return false

	if item_slot_type == "ring":
		return slot_type == "ring_1" or slot_type == "ring_2"

	return item_slot_type == slot_type


func equip_item_to_slot(item_name: String, slot_type: String) -> bool:
	if not can_equip_item_to_slot(item_name, slot_type):
		if player != null and player.has_method("show_message"):
			player.show_message("%s cannot be equipped there." % item_database.get_display_name(item_name))
		return false

	equipment[slot_type] = item_name
	update_equipment_slots()
	update_inventory_list()
	return true


func equip_item_to_first_available_slot(item_name: String) -> bool:
	var possible_slots := get_possible_equipment_slots(item_name)

	if possible_slots.is_empty():
		if player != null and player.has_method("show_message"):
			player.show_message("%s cannot be equipped." % item_database.get_display_name(item_name))
		return false

	for slot_type in possible_slots:
		if equipment.get(slot_type, "") == "":
			return equip_item_to_slot(item_name, slot_type)

	return equip_item_to_slot(item_name, possible_slots[0])


func get_possible_equipment_slots(item_name: String) -> Array:
	var item_slot_type := get_item_equipment_slot(item_name)

	if item_slot_type == "ring":
		return ["ring_1", "ring_2"]

	if item_slot_type != "":
		return [item_slot_type]

	return []


func get_item_equipment_slot(item_name: String) -> String:
	return item_database.get_equipment_slot(item_name)
