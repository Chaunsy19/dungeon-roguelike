extends RefCounted

# Add new items here. The item key, like "berries", is what code and save data should use.
const ITEMS := {
	"berries": {
		"display_name": "Berries",
		"inventory_name": "Berries",
		"inventory_tooltip": "Edible",
		"examine_text": "Small wild berries. They restore hunger when eaten.",
		"icon_path": "res://assets/Sprites/Items/BerryIcon.png",
		"inventory_sort_order": 10,
		"hunger_restore": 25,
		"can_eat": true
	},
	"wood": {
		"display_name": "Wood",
		"inventory_name": "Wood",
		"inventory_tooltip": "Crafting material.",
		"examine_text": "Unrefined wood, not good for anything other than firewood in it's current state.",
		"icon_path": "res://assets/Sprites/Items/LogIcon.png",
		"inventory_sort_order": 20
	},
	"small_bag": {
		"display_name": "Damaged Sack",
		"inventory_name": "Damaged Sack",
		"inventory_tooltip": "Equipment.",
		"examine_text": "A badly damaged canvas sack, increases your inventory space when equipped.",
		"icon_path": "res://assets/Sprites/Items/DamagedSack.png",
		"inventory_sort_order": 30,
		"equipment_slot": "bag",
		"bag_slot_bonus": 4
	}
}


func has_item(item_name: String) -> bool:
	return ITEMS.has(item_name)


func get_item(item_name: String) -> Dictionary:
	if not has_item(item_name):
		return {}

	return ITEMS[item_name]


func get_display_name(item_name: String) -> String:
	return get_item_value(item_name, "display_name", item_name.capitalize())


func get_inventory_name(item_name: String) -> String:
	return get_item_value(item_name, "inventory_name", get_display_name(item_name))


func get_inventory_tooltip(item_name: String) -> String:
	return get_item_value(item_name, "inventory_tooltip", "")


func get_icon_path(item_name: String) -> String:
	return get_item_value(item_name, "icon_path", "")


func get_inventory_sort_order(item_name: String) -> int:
	return int(get_item_value(item_name, "inventory_sort_order", 9999))


func get_examine_text(item_name: String) -> String:
	return get_item_value(item_name, "examine_text", "%s: Nothing interesting." % get_display_name(item_name))


func can_eat(item_name: String) -> bool:
	return bool(get_item_value(item_name, "can_eat", false))


func get_hunger_restore(item_name: String) -> int:
	return int(get_item_value(item_name, "hunger_restore", 0))


func get_equipment_slot(item_name: String) -> String:
	return get_item_value(item_name, "equipment_slot", "")


func get_bag_slot_bonus(item_name: String) -> int:
	return int(get_item_value(item_name, "bag_slot_bonus", 0))


func get_item_value(item_name: String, key: String, default_value):
	var item := get_item(item_name)
	if item.is_empty():
		return default_value

	return item.get(key, default_value)
