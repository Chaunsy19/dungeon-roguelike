extends CharacterBody2D

@export var speed := 200.0
@export var acceleration := 900.0
@export var deceleration := 1200.0
@export var movement_animation_min_speed_scale := 0.35
@export var movement_animation_max_speed_scale := 2.0
@export var starting_hunger := 100.0
@export var hunger_drain_rate := .25
@export var berry_hunger_restore := 25.0
@export var starvation_damage_rate := .50
@export var attack_damage := 10.0
@export var attack_range := 42.0
@export var attack_arc_degrees := 80.0
@export var attack_cooldown := 0.7
@export var attack_animation_time := 0.45
@export var hit_flash_time := 0.12
@export var health_regen_per_constitution_level := 0.005
@export var health_regen_delay_after_damage := 5.0

const BASE_INVENTORY_SLOT_COUNT := 10
const ACTION_EAT := 1
const ACTION_EXAMINE := 2
const ACTION_EQUIP := 3
const SKILL_XP_REQUIREMENT_SCALE := 1.15
const DIRECTIONS := ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
const EQUIPMENT_SLOT_TYPES := ["head", "chest", "legs", "gloves", "boots", "ring_1", "ring_2", "necklace", "bag"]
const EQUIPMENT_SLOT_LAYOUT := [
	"", "", "head", "", "",
	"gloves", "", "necklace", "", "boots",
	"", "ring_1", "chest", "ring_2", "",
	"", "", "legs", "bag", ""
]
const INVENTORY_SLOT_BUTTON_SCRIPT := preload("res://Scripts/inventory_slot_button.gd")
const EQUIPMENT_SLOT_BUTTON_SCRIPT := preload("res://Scripts/equipment_slot_button.gd")
const HEART_FULL_TEXTURE := preload("res://assets/Sprites/HUD/heart_full.png")
const HEART_MID_TEXTURE := preload("res://assets/Sprites/HUD/heart_mid.png")
const HEART_LOW_TEXTURE := preload("res://assets/Sprites/HUD/heart_low.png")
const HUNGER_FULL_TEXTURE := preload("res://assets/Sprites/HUD/hunger_full.png")
const HUNGER_MID_TEXTURE := preload("res://assets/Sprites/HUD/hunger_mid.png")
const HUNGER_LOW_TEXTURE := preload("res://assets/Sprites/HUD/hunger_low.png")

var interaction_pressed := false
var selected_inventory_item := ""
var facing_direction := "down"
var attack_cooldown_timer := 0.0
var attack_animation_timer := 0.0
var hit_flash_timer := 0.0
var health_regen_delay_timer := 0.0
var base_movement_animation_speed := 0.0

var wood := 0
var berries := 0
var hunger := 100.0
var health := 100.0
var equipment := {}

var woodcutting_xp := 0
var woodcutting_level := 1
var woodcutting_xp_to_next_level := 30

var constitution_xp := 0
var constitution_level := 1
var constitution_xp_to_next_level := 30
var constitution_damage_xp_progress := 0.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var woodcutting_label: Label
var woodcutting_skill_label: Button
var constitution_skill_label: Button
var wood_label: Label
var berries_label: Label
var hunger_icon: TextureRect
var health_icon: TextureRect
var inventory_list: GridContainer
var equipment_slots: GridContainer
var item_action_menu: PopupMenu
var message_label: Label

func _ready():
	base_movement_animation_speed = speed
	hunger = clamp(starting_hunger, 0.0, 100.0)
	setup_player_animations()

	woodcutting_label = get_tree().current_scene.get_node_or_null("UI/WoodcuttingLabel")
	woodcutting_skill_label = get_tree().current_scene.get_node_or_null("UI/Menu/MenuLayout/ContentPanel/Content/SkillsPage/WoodcuttingSkillLabel")
	constitution_skill_label = get_tree().current_scene.get_node_or_null("UI/Menu/MenuLayout/ContentPanel/Content/SkillsPage/ConstitutionSkillLabel")
	wood_label = get_tree().current_scene.get_node_or_null("UI/WoodLabel")
	berries_label = get_tree().current_scene.get_node_or_null("UI/BerriesLabel")
	hunger_icon = get_tree().current_scene.get_node_or_null("UI/HungerIcon")
	health_icon = get_tree().current_scene.get_node_or_null("UI/HealthIcon")
	inventory_list = get_tree().current_scene.get_node_or_null("UI/Menu/MenuLayout/ContentPanel/Content/InventoryPage/InventoryList")
	equipment_slots = get_tree().current_scene.get_node_or_null("UI/Menu/MenuLayout/ContentPanel/Content/EquipmentPanel/EquipmentSlots")
	item_action_menu = get_tree().current_scene.get_node_or_null("UI/ItemActionMenu")
	message_label = get_tree().current_scene.get_node_or_null("UI/MessageLabel")

	if item_action_menu != null:
		item_action_menu.id_pressed.connect(_on_item_action_selected)

	update_woodcutting_label()
	update_wood_label()
	update_berries_label()
	update_hunger_label()
	update_health_label()
	update_constitution_label()
	setup_equipment_slots()
	update_inventory_list()
	update_equipment_slots()

func _physics_process(delta):
	handle_hit_flash(delta)
	handle_attack_timers(delta)
	handle_movement(delta)
	handle_interaction()
	handle_hunger(delta)
	handle_starvation_damage(delta)
	handle_health_regen(delta)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			try_attack_toward_mouse()

func handle_movement(delta: float):
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1

	var target_velocity := direction.normalized() * speed

	if direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	else:
		update_facing_direction(direction)
		velocity = velocity.move_toward(target_velocity, acceleration * delta)

	move_and_slide()
	update_movement_animation()

func update_facing_direction(direction: Vector2):
	if direction == Vector2.ZERO:
		return

	var direction_names := ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]
	var angle_degrees := rad_to_deg(direction.angle())

	if angle_degrees < 0:
		angle_degrees += 360.0

	var direction_index := int(floor((angle_degrees + 22.5) / 45.0)) % direction_names.size()
	facing_direction = direction_names[direction_index]

func update_movement_animation():
	if attack_animation_timer > 0:
		return

	var movement_speed := velocity.length()

	if movement_speed < 5.0:
		animated_sprite.speed_scale = 1.0
		play_directional_animation("idle", facing_direction)
	else:
		var animation_speed_scale := 1.0

		if base_movement_animation_speed > 0:
			animation_speed_scale = clamp(movement_speed / base_movement_animation_speed, movement_animation_min_speed_scale, movement_animation_max_speed_scale)

		animated_sprite.speed_scale = animation_speed_scale
		play_directional_animation("run", facing_direction)

func handle_attack_timers(delta: float):
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if attack_animation_timer > 0:
		attack_animation_timer -= delta

	if health_regen_delay_timer > 0:
		health_regen_delay_timer -= delta

func start_hit_flash():
	hit_flash_timer = hit_flash_time
	animated_sprite.modulate = Color(1.8, 0.35, 0.35, 1)

func handle_hit_flash(delta: float):
	if hit_flash_timer <= 0:
		return

	hit_flash_timer -= delta

	if hit_flash_timer <= 0:
		animated_sprite.modulate = Color(1, 1, 1, 1)

func try_attack_toward_mouse():
	if attack_cooldown_timer > 0:
		return

	var aim_direction := global_position.direction_to(get_global_mouse_position())

	if aim_direction == Vector2.ZERO:
		return

	update_facing_direction(aim_direction)
	animated_sprite.speed_scale = 1.0
	play_directional_animation("attack", facing_direction)
	attack_enemy_in_direction(aim_direction)

	attack_cooldown_timer = attack_cooldown
	attack_animation_timer = attack_animation_time

func attack_enemy_in_direction(aim_direction: Vector2):
	var target = get_best_attack_target(aim_direction)

	if target == null:
		return

	target.take_damage(attack_damage)

func get_best_attack_target(aim_direction: Vector2):
	var best_target = null
	var best_score := 999999.0
	var max_angle := deg_to_rad(attack_arc_degrees) * 0.5

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null:
			continue

		if not enemy.has_method("take_damage"):
			continue

		if enemy.has_method("is_dead") and enemy.is_dead():
			continue

		var to_enemy: Vector2 = enemy.global_position - global_position
		var distance: float = to_enemy.length()

		if distance <= 0 or distance > attack_range:
			continue

		var angle: float = abs(aim_direction.angle_to(to_enemy.normalized()))

		if angle > max_angle:
			continue

		var score: float = distance + (angle * 20.0)

		if score < best_score:
			best_score = score
			best_target = enemy

	return best_target

func setup_player_animations():
	if animated_sprite == null:
		return

	var sprite_frames := SpriteFrames.new()

	for direction_name in DIRECTIONS:
		add_directional_animation(sprite_frames, "idle", direction_name, 5.0, true)
		add_directional_animation(sprite_frames, "walk", direction_name, 8.0, true)
		add_directional_animation(sprite_frames, "run", direction_name, 12.0, true)
		add_directional_animation(sprite_frames, "attack", direction_name, 12.0, false)
		add_directional_animation(sprite_frames, "interact", direction_name, 8.0, false)
		add_directional_animation(sprite_frames, "jump", direction_name, 10.0, false)

	add_animation_from_row(sprite_frames, "rotate", "rotate", 0, 8, 12.0, true)

	animated_sprite.sprite_frames = sprite_frames
	play_directional_animation("idle", "down")

func add_directional_animation(sprite_frames: SpriteFrames, animation_type: String, direction_name: String, animation_speed: float, loops: bool):
	var row := get_sprite_row_for_direction(direction_name)
	var frame_count := get_frame_count_for_animation(animation_type)
	var animation_name := "%s_%s" % [animation_type, direction_name]

	add_animation_from_row(sprite_frames, animation_name, animation_type, row, frame_count, animation_speed, loops)

func add_animation_from_row(sprite_frames: SpriteFrames, animation_name: String, file_prefix: String, row: int, frame_count: int, animation_speed: float, loops: bool):
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, animation_speed)
	sprite_frames.set_animation_loop(animation_name, loops)

	for frame_index in range(frame_count):
		var texture = load("res://assets/player/%s_r%s_%s.png" % [file_prefix, row, frame_index])

		if texture != null:
			sprite_frames.add_frame(animation_name, texture)

func get_sprite_row_for_direction(direction_name: String) -> int:
	if direction_name == "down":
		return 0
	if direction_name == "down_right" or direction_name == "down_left":
		return 1
	if direction_name == "right" or direction_name == "left":
		return 2
	if direction_name == "up_right" or direction_name == "up_left":
		return 3

	return 4

func get_frame_count_for_animation(animation_type: String) -> int:
	if animation_type == "attack":
		return 7
	if animation_type == "run":
		return 6
	if animation_type == "jump":
		return 5

	return 4

func should_flip_direction(direction_name: String) -> bool:
	return direction_name == "left" or direction_name == "up_left" or direction_name == "down_left"

func play_directional_animation(animation_type: String, direction_name: String):
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	var animation_name := "%s_%s" % [animation_type, direction_name]

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return

	animated_sprite.flip_h = should_flip_direction(direction_name)

	if animation_type != "run":
		animated_sprite.speed_scale = 1.0

	if animated_sprite.animation == animation_name and animated_sprite.is_playing():
		return

	animated_sprite.play(animation_name)

func play_attack():
	play_directional_animation("attack", facing_direction)

func play_interact_animation():
	play_directional_animation("interact", facing_direction)

func play_jump_animation():
	play_directional_animation("jump", facing_direction)

func handle_interaction():
	if Input.is_physical_key_pressed(KEY_E) and not interaction_pressed:
		interaction_pressed = true
		try_interact()

	if not Input.is_physical_key_pressed(KEY_E):
		interaction_pressed = false

func handle_hunger(delta):
	hunger -= hunger_drain_rate * delta
	hunger = clamp(hunger, 0, 100)
	update_hunger_label()

func handle_starvation_damage(delta):
	if hunger > 0:
		return

	take_damage(starvation_damage_rate * delta)

func handle_health_regen(delta):
	if health <= 0:
		return

	if health >= get_max_health():
		return

	if hunger <= 0:
		return

	if health_regen_delay_timer > 0:
		return

	health += get_health_regen_rate() * delta
	health = clamp(health, 0, get_max_health())
	update_health_label()

func try_interact():
	var nearby_bodies := interaction_area.get_overlapping_bodies()

	for body in nearby_bodies:
		if body.has_method("interact"):
			body.interact(self)
			play_interact_animation()
			return

		if body.has_method("chop"):
			body.chop()
			add_wood(1)
			gain_woodcutting_xp(10)
			return

		if body.has_method("gather"):
			body.gather()
			add_berries(1)
			return

func add_wood(amount):
	wood += amount
	update_wood_label()
	update_inventory_list()

func add_berries(amount):
	berries += amount
	update_berries_label()
	update_inventory_list()

func eat_berry():
	if berries <= 0:
		return

	if hunger >= 100:
		return

	berries -= 1
	hunger += berry_hunger_restore
	hunger = clamp(hunger, 0, 100)

	update_berries_label()
	update_hunger_label()
	update_inventory_list()

func examine_item(item_name: String):
	if item_name == "berries":
		show_message("Berries: Small wild berries. They restore hunger when eaten.")
	elif item_name == "wood":
		show_message("Wood: A basic crafting material. It cannot be used yet.")

func show_message(message: String):
	if message_label == null:
		print(message)
		return

	message_label.text = message

func get_max_health():
	return 100 + ((constitution_level - 1) * 10)

func get_health_regen_rate():
	return constitution_level * health_regen_per_constitution_level

func take_damage(amount):
	if health <= 0:
		return

	health -= amount
	health = clamp(health, 0, get_max_health())
	health_regen_delay_timer = health_regen_delay_after_damage
	start_hit_flash()
	gain_constitution_xp_from_damage(amount)
	update_health_label()

	if health <= 0:
		show_message("You have collapsed.")

func gain_constitution_xp_from_damage(amount):
	constitution_damage_xp_progress += amount * 0.33

	while constitution_damage_xp_progress >= 1.0:
		constitution_damage_xp_progress -= 1.0
		gain_constitution_xp(1)

func gain_woodcutting_xp(amount):
	woodcutting_xp += amount

	while woodcutting_xp >= woodcutting_xp_to_next_level:
		woodcutting_xp -= woodcutting_xp_to_next_level
		woodcutting_level += 1
		woodcutting_xp_to_next_level = get_next_skill_xp_requirement(woodcutting_xp_to_next_level)
		print("Woodcutting level up! Level: ", woodcutting_level)

	update_woodcutting_label()

func gain_constitution_xp(amount):
	constitution_xp += amount

	while constitution_xp >= constitution_xp_to_next_level:
		constitution_xp -= constitution_xp_to_next_level
		constitution_level += 1
		constitution_xp_to_next_level = get_next_skill_xp_requirement(constitution_xp_to_next_level)
		health = get_max_health()
		show_message("Constitution level up! Level: %s" % constitution_level)

	update_health_label()
	update_constitution_label()

func get_next_skill_xp_requirement(current_requirement: int) -> int:
	return max(current_requirement + 1, int(ceil(current_requirement * SKILL_XP_REQUIREMENT_SCALE)))

func update_wood_label():
	if wood_label == null:
		return

	wood_label.text = "Wood: %s" % wood

func update_berries_label():
	if berries_label == null:
		return

	berries_label.text = "Berries: %s" % berries

func update_hunger_label():
	if hunger_icon == null:
		return

	var hunger_percent: float = hunger / 100.0

	if hunger_percent >= 0.66:
		hunger_icon.texture = HUNGER_FULL_TEXTURE
	elif hunger_percent >= 0.34:
		hunger_icon.texture = HUNGER_MID_TEXTURE
	else:
		hunger_icon.texture = HUNGER_LOW_TEXTURE

	hunger_icon.tooltip_text = "Hunger: %d / 100" % int(ceil(hunger))

func update_health_label():
	if health_icon == null:
		return

	var health_percent: float = health / get_max_health()

	if health_percent >= 0.66:
		health_icon.texture = HEART_FULL_TEXTURE
	elif health_percent >= 0.34:
		health_icon.texture = HEART_MID_TEXTURE
	else:
		health_icon.texture = HEART_LOW_TEXTURE

	health_icon.tooltip_text = "Health: %d / %d" % [int(ceil(health)), get_max_health()]

func update_inventory_list():
	if inventory_list == null:
		return

	for child in inventory_list.get_children():
		child.queue_free()

	var items := []

	if berries > 0:
		items.append({
			"text": "Berries\nx%s" % berries,
			"tooltip": "Small wild berries. Right-click for actions.",
			"name": "berries"
		})

	if wood > 0:
		items.append({
			"text": "Wood\nx%s" % wood,
			"tooltip": "A basic crafting material. Right-click for actions.",
			"name": "wood"
		})

	for slot_index in range(get_inventory_slot_count()):
		if slot_index < items.size():
			var item = items[slot_index]
			add_inventory_slot(item["text"], item["tooltip"], item["name"])
		else:
			add_inventory_slot("", "Empty inventory slot", "")

func add_inventory_slot(button_text: String, tooltip: String, item_name: String):
	var button := Button.new()
	button.set_script(INVENTORY_SLOT_BUTTON_SCRIPT)
	button.call("setup", item_name, button_text, tooltip, self)
	button.gui_input.connect(_on_inventory_item_gui_input.bind(item_name))
	inventory_list.add_child(button)

func setup_equipment_slots():
	if equipment_slots == null:
		return

	for slot_type in EQUIPMENT_SLOT_TYPES:
		equipment[slot_type] = ""

	for child in equipment_slots.get_children():
		child.queue_free()

	for slot_type in EQUIPMENT_SLOT_LAYOUT:
		if slot_type == "":
			add_equipment_spacer()
		else:
			add_equipment_slot(slot_type)

func add_equipment_slot(slot_type: String):
	var button := Button.new()
	button.set_script(EQUIPMENT_SLOT_BUTTON_SCRIPT)
	button.call("setup", slot_type, self)
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

func get_inventory_slot_count() -> int:
	var bag_item := ""

	if equipment.has("bag"):
		bag_item = equipment["bag"]

	return BASE_INVENTORY_SLOT_COUNT + get_bag_slot_bonus(bag_item)

func get_bag_slot_bonus(item_name: String) -> int:
	if item_name == "small_bag":
		return 18

	return 0

func can_equip_item_to_slot(item_name: String, slot_type: String) -> bool:
	if item_name == "":
		return false

	var item_slot_type := get_item_equipment_slot(item_name)

	if item_slot_type == "":
		return false

	if item_slot_type == "ring":
		return slot_type == "ring_1" or slot_type == "ring_2"

	return item_slot_type == slot_type

func equip_item_to_slot(item_name: String, slot_type: String):
	if not can_equip_item_to_slot(item_name, slot_type):
		show_message("%s cannot be equipped there." % item_name.capitalize())
		return

	equipment[slot_type] = item_name
	update_equipment_slots()
	update_inventory_list()
	show_message("Equipped %s." % item_name.capitalize())

func equip_item_to_first_available_slot(item_name: String):
	var possible_slots := get_possible_equipment_slots(item_name)

	if possible_slots.is_empty():
		show_message("%s cannot be equipped." % item_name.capitalize())
		return

	for slot_type in possible_slots:
		if equipment.get(slot_type, "") == "":
			equip_item_to_slot(item_name, slot_type)
			return

	equip_item_to_slot(item_name, possible_slots[0])

func get_possible_equipment_slots(item_name: String) -> Array:
	var item_slot_type := get_item_equipment_slot(item_name)

	if item_slot_type == "ring":
		return ["ring_1", "ring_2"]

	if item_slot_type != "":
		return [item_slot_type]

	return []

func get_item_equipment_slot(item_name: String) -> String:
	if item_name == "small_bag":
		return "bag"

	return ""

func _on_inventory_item_gui_input(event: InputEvent, item_name: String):
	if item_name == "":
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			show_item_action_menu(item_name)

func show_item_action_menu(item_name: String):
	if item_action_menu == null:
		return

	selected_inventory_item = item_name
	item_action_menu.clear()

	if item_name == "berries":
		item_action_menu.add_item("Eat", ACTION_EAT)

	if get_item_equipment_slot(item_name) != "":
		item_action_menu.add_item("Equip", ACTION_EQUIP)

	item_action_menu.add_item("Examine", ACTION_EXAMINE)
	item_action_menu.position = get_viewport().get_mouse_position()
	item_action_menu.popup()

func _on_item_action_selected(action_id: int):
	if selected_inventory_item == "":
		return

	if action_id == ACTION_EAT:
		if selected_inventory_item == "berries":
			eat_berry()
	elif action_id == ACTION_EQUIP:
		equip_item_to_first_available_slot(selected_inventory_item)
	elif action_id == ACTION_EXAMINE:
		examine_item(selected_inventory_item)

	selected_inventory_item = ""

func update_woodcutting_label():
	var text := "Level: %s XP %s / %s" % [
		woodcutting_level,
		woodcutting_xp,
		woodcutting_xp_to_next_level
	]

	if woodcutting_label != null:
		woodcutting_label.text = text

	if woodcutting_skill_label != null:
		woodcutting_skill_label.text = "Woodcutting\n%s" % woodcutting_level
		woodcutting_skill_label.tooltip_text = text

func update_constitution_label():
	var text := "Level: %s XP %s / %s" % [
		constitution_level,
		constitution_xp,
		constitution_xp_to_next_level
	]

	if constitution_skill_label != null:
		constitution_skill_label.text = "Constitution\n%s" % constitution_level
		constitution_skill_label.tooltip_text = text
