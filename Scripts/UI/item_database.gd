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
		"inventory_tooltip": "Berries",
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
		"inventory_tooltip": "Wood",
		"examine_text": "Unrefined wood, not good for anything other than firewood in it's current state.",
		"icon_path": "res://assets/Sprites/Items/Resources/LogIcon.png",
		"inventory_sort_order": 20
	},
	"small_bag": {
		"display_name": "Damaged Sack",
		"inventory_name": "Damaged Sack",
		"inventory_tooltip": "Damaged Sack",
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
		"inventory_tooltip": "Bent Lockpick",
		"examine_text": "This lockpick is on it's last leg. I hope you are not relying on this one.",
		"icon_path": "res://assets/Sprites/Items/Tools/Consumable/BentLockpick.png",
		"inventory_sort_order": 40,
		"tags": {
			TAG_LOCKPICK: {
				"break_chance": 0.75
			}
		}
	},
	"lantern": {
		"display_name": "Lantern",
		"inventory_name": "Lantern",
		"inventory_tooltip": "Lantern",
		"examine_text": "A lit lantern. Useful for fire and dark places.",
		"icon_path": "res://assets/Sprites/Items/Equipment/Tools/Lantern.png",
		"inventory_sort_order": 50,
		"held_texture_path": "res://assets/Sprites/Items/Equipment/Tools/Lantern.png",
		"held_scale": 0.025,
		"held_offsets": {
			"down": Vector2(5, -11),
			"down_right": Vector2(7, -12),
			"right": Vector2(8, -13),
			"up_right": Vector2(6, -15),
			"up": Vector2(3, -16),
			"up_left": Vector2(-6, -15),
			"left": Vector2(-8, -13),
			"down_left": Vector2(-7, -12)
		},
		"held_frame_offsets": {
			"idle": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 0), Vector2(0, -1)],
			"walk": [Vector2(0, 0), Vector2(1, 1), Vector2(0, 0), Vector2(-1, -1)],
			"run": [Vector2(0, 0), Vector2(1, 1), Vector2(0, 0), Vector2(-1, -1), Vector2(0, 0), Vector2(1, 0)],
			"attack": [Vector2(0, 0), Vector2(2, 0), Vector2(3, -1), Vector2(2, -1), Vector2(1, 0), Vector2(0, 0), Vector2(0, 1)]
		},
		"held_z_indexes": {
			"up": 0,
			"up_left": 0,
			"up_right": 0
		},
		"held_light_enabled": true,
		"held_light_offset": Vector2(0, 5),
		"tags": {
			TAG_EQUIPMENT: {
				"slot": "tool"
			},
			TAG_FIRESTARTER: {}
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


func get_held_texture_path(item_name: String) -> String:
	return get_item_value(item_name, "held_texture_path", "")


func get_held_scale(item_name: String) -> float:
	return float(get_item_value(item_name, "held_scale", 1.0))


func get_held_offset(item_name: String, direction_name: String) -> Vector2:
	var offsets: Dictionary = get_item_value(item_name, "held_offsets", {})
	return offsets.get(direction_name, Vector2.ZERO)


func get_held_frame_offset(item_name: String, animation_type: String, frame_index: int, flipped: bool) -> Vector2:
	var frame_offsets: Dictionary = get_item_value(item_name, "held_frame_offsets", {})
	var offsets = frame_offsets.get(animation_type, [])
	if not (offsets is Array):
		return Vector2.ZERO

	if offsets.is_empty():
		return Vector2.ZERO

	var offset: Vector2 = offsets[frame_index % offsets.size()]
	if flipped:
		offset.x *= -1

	return offset


func get_held_z_index(item_name: String, direction_name: String) -> int:
	var z_indexes: Dictionary = get_item_value(item_name, "held_z_indexes", {})
	return int(z_indexes.get(direction_name, 2))


func has_held_light(item_name: String) -> bool:
	return bool(get_item_value(item_name, "held_light_enabled", false))


func get_held_light_offset(item_name: String) -> Vector2:
	return get_item_value(item_name, "held_light_offset", Vector2.ZERO)


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
