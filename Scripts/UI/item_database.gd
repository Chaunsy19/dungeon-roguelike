extends RefCounted

const TAG_EDIBLE := "Edible"
const TAG_EQUIPMENT := "Equipment"
const TAG_FIRESTARTER := "Firestarter"
const TAG_LOCKPICK := "Lockpick"

# Add new items here. The item key, like "berries", is what code and save data should use.
const ITEMS := {
	"berries": {
		"display_name": "Berries",
		"inventory_name": "Berries",
		"inventory_tooltip": "Edible",
		"examine_text": "Small wild berries. They restore hunger when eaten.",
		"icon_path": "res://assets/Sprites/Items/Consumable/BerryIcon.png",
		"inventory_sort_order": 10,
		"tags": {
			TAG_EDIBLE: {
				"hunger_restore": 25
			}
		}
	},
	"wood": {
		"display_name": "Wood",
		"inventory_name": "Wood",
		"inventory_tooltip": "Crafting material.",
		"examine_text": "Unrefined wood, not good for anything other than firewood in it's current state.",
		"icon_path": "res://assets/Sprites/Items/Resources/LogIcon.png",
		"inventory_sort_order": 20
	},
	"small_bag": {
		"display_name": "Damaged Sack",
		"inventory_name": "Damaged Sack",
		"inventory_tooltip": "Equipment.",
		"examine_text": "A badly damaged canvas sack, increases your inventory space when equipped.",
		"icon_path": "res://assets/Sprites/Items/Equipment/DamagedSack.png",
		"inventory_sort_order": 30,
		"tags": {
			TAG_EQUIPMENT: {
				"slot": "bag",
				"bag_slot_bonus": 4
			}
		}
	},
	"bent_lockpick": {
		"display_name": "Bent Lockpick",
		"inventory_name": "Bent Lockpick",
		"inventory_tooltip": "Consumable tool.",
		"examine_text": "This lockpick is on its last leg. I hope you are not relying on this one.",
		"icon_path": "res://assets/Sprites/Items/Tools/Consumable/BentLockpick.png",
		"inventory_sort_order": 40,
		"tags": {
			TAG_LOCKPICK: {
				"break_chance": 0.75
			}
		}
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


func get_tags(item_name: String) -> Dictionary:
	return get_item_value(item_name, "tags", {})


func has_tag(item_name: String, tag_name: String) -> bool:
	return get_tags(item_name).has(tag_name)


func get_tag_data(item_name: String, tag_name: String) -> Dictionary:
	if not has_tag(item_name, tag_name):
		return {}

	var tag_data = get_tags(item_name)[tag_name]
	if tag_data is Dictionary:
		return tag_data

	return {}


func get_tag_value(item_name: String, tag_name: String, key: String, default_value):
	return get_tag_data(item_name, tag_name).get(key, default_value)


func is_firestarter(item_name: String) -> bool:
	return has_tag(item_name, TAG_FIRESTARTER)


func is_lockpick(item_name: String) -> bool:
	return has_tag(item_name, TAG_LOCKPICK)


func get_lockpick_break_chance(item_name: String) -> float:
	return float(get_tag_value(item_name, TAG_LOCKPICK, "break_chance", 0.0))


func can_eat(item_name: String) -> bool:
	return has_tag(item_name, TAG_EDIBLE)


func get_hunger_restore(item_name: String) -> int:
	return int(get_tag_value(item_name, TAG_EDIBLE, "hunger_restore", 0))


func get_equipment_slot(item_name: String) -> String:
	return get_tag_value(item_name, TAG_EQUIPMENT, "slot", "")


func get_bag_slot_bonus(item_name: String) -> int:
	return int(get_tag_value(item_name, TAG_EQUIPMENT, "bag_slot_bonus", 0))


func get_item_value(item_name: String, key: String, default_value):
	var item := get_item(item_name)
	if item.is_empty():
		return default_value

	return item.get(key, default_value)
