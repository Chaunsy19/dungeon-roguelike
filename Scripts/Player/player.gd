extends CharacterBody2D

@export var speed := 200.0
@export var acceleration := 900.0
@export var deceleration := 1200.0
@export var movement_animation_min_speed_scale := 0.35
@export var movement_animation_max_speed_scale := 2.0
@export var starting_hunger := 100.0
@export var hunger_drain_rate := .25
@export var starvation_damage_rate := .50
@export var attack_damage := 10.0
@export var attack_range := 42.0
@export var attack_arc_degrees := 80.0
@export var attack_cooldown := 0.7
@export var attack_animation_time := 0.45
@export var hit_flash_time := 0.12
@export var health_regen_per_constitution_level := 0.005
@export var health_regen_delay_after_damage := 5.0
@export var world_action_click_radius := 16.0
@export var world_action_reach := 48.0
@export var action_menu_mouse_cancel_distance := 80.0

const ACTION_EAT := 1
const ACTION_EXAMINE := 2
const ACTION_EQUIP := 3
const WORLD_ACTION_OPEN := 101
const WORLD_ACTION_LIGHT := 102
const WORLD_ACTION_SNUFF := 103
const DIRECTIONS := ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
const ITEM_DATABASE_SCRIPT := preload("res://Scripts/UI/item_database.gd")
const PLAYER_INVENTORY_SCRIPT := preload("res://Scripts/UI/player_inventory.gd")
const PLAYER_SKILLS_SCRIPT := preload("res://Scripts/UI/player_skills.gd")
const HEART_FULL_TEXTURE := preload("res://assets/Sprites/HUD/heart_full.png")
const HEART_MID_TEXTURE := preload("res://assets/Sprites/HUD/heart_mid.png")
const HEART_LOW_TEXTURE := preload("res://assets/Sprites/HUD/heart_low.png")
const HUNGER_FULL_TEXTURE := preload("res://assets/Sprites/HUD/hunger_full.png")
const HUNGER_MID_TEXTURE := preload("res://assets/Sprites/HUD/hunger_mid.png")
const HUNGER_LOW_TEXTURE := preload("res://assets/Sprites/HUD/hunger_low.png")

var selected_inventory_item := ""
var selected_world_target: Node = null
var facing_direction := "down"
var attack_cooldown_timer := 0.0
var attack_animation_timer := 0.0
var hit_flash_timer := 0.0
var health_regen_delay_timer := 0.0
var base_movement_animation_speed := 0.0

var hunger := 100.0
var health := 100.0
var item_database = ITEM_DATABASE_SCRIPT.new()
var inventory_system = PLAYER_INVENTORY_SCRIPT.new()
var skill_system = PLAYER_SKILLS_SCRIPT.new()

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
var menu: Control
var chest_loot_panel: Control
var item_action_menu: PopupMenu
var world_action_menu: PopupMenu
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
	menu = get_tree().current_scene.get_node_or_null("UI/Menu")
	chest_loot_panel = get_tree().current_scene.get_node_or_null("UI/ChestLootPanel")
	inventory_list = get_tree().current_scene.get_node_or_null("UI/Menu/MenuLayout/ContentPanel/Content/InventoryPage/InventoryList")
	equipment_slots = get_tree().current_scene.get_node_or_null("UI/Menu/MenuLayout/ContentPanel/Content/EquipmentPanel/EquipmentSlots")
	item_action_menu = get_tree().current_scene.get_node_or_null("UI/ItemActionMenu")
	world_action_menu = get_tree().current_scene.get_node_or_null("UI/WorldActionMenu")
	message_label = get_tree().current_scene.get_node_or_null("UI/MessageLabel")

	if item_action_menu != null:
		item_action_menu.id_pressed.connect(_on_item_action_selected)

	if world_action_menu != null:
		world_action_menu.id_pressed.connect(_on_world_action_selected)

	inventory_system.setup(self, inventory_list, equipment_slots, menu)

	update_woodcutting_label()
	update_wood_label()
	update_berries_label()
	update_hunger_label()
	update_health_label()
	update_constitution_label()

func _physics_process(delta):
	handle_hit_flash(delta)
	handle_attack_timers(delta)
	handle_action_menu_mouse_cancel()
	handle_movement(delta)
	handle_hunger(delta)
	handle_starvation_damage(delta)
	handle_health_regen(delta)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if try_show_world_action_menu_at_mouse():
				get_viewport().set_input_as_handled()
				return

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

func add_wood(amount):
	add_item("wood", amount)

func add_berries(amount):
	add_item("berries", amount)

func add_item(item_name: String, amount: int):
	inventory_system.add_item(item_name, amount)
	update_item_count_labels()

func eat_berry():
	eat_item("berries")

func eat_item(item_name: String):
	if not item_database.can_eat(item_name):
		return

	if inventory_system.get_item_count(item_name) <= 0:
		return

	if hunger >= 100:
		return

	if not inventory_system.remove_item(item_name, 1):
		return

	hunger += item_database.get_hunger_restore(item_name)
	hunger = clamp(hunger, 0, 100)

	update_item_count_labels()
	update_hunger_label()

func examine_item(item_name: String):
	show_message(item_database.get_examine_text(item_name))

func show_message(message: String):
	if message_label == null:
		print(message)
		return

	message_label.text = message

func open_chest(chest: Node):
	if chest_loot_panel == null:
		show_message("No chest window found.")
		return

	if chest_loot_panel.has_method("open_chest"):
		chest_loot_panel.call("open_chest", chest, self)

func show_world_action_menu(target: Node, screen_position: Vector2):
	if world_action_menu == null:
		return

	if target == null:
		return

	if not target.has_method("get_world_actions"):
		return

	var actions: Array = target.get_world_actions(self)
	if actions.is_empty():
		return

	selected_world_target = target
	world_action_menu.clear()

	for action in actions:
		world_action_menu.add_item(action["label"], action["id"])

	world_action_menu.position = screen_position
	world_action_menu.popup()

func handle_action_menu_mouse_cancel():
	close_popup_if_mouse_is_away(world_action_menu, true)
	close_popup_if_mouse_is_away(item_action_menu, false)

func close_popup_if_mouse_is_away(popup_menu: PopupMenu, clears_world_target: bool):
	if popup_menu == null:
		return

	if not popup_menu.visible:
		return

	var popup_rect := Rect2(Vector2(popup_menu.position), Vector2(popup_menu.size)).grow(action_menu_mouse_cancel_distance)
	if popup_rect.has_point(get_viewport().get_mouse_position()):
		return

	popup_menu.hide()

	if clears_world_target:
		selected_world_target = null
	else:
		selected_inventory_item = ""

func try_show_world_action_menu_at_mouse() -> bool:
	var mouse_world_position := get_global_mouse_position()
	var target := get_world_action_target_at_position(mouse_world_position)
	if target == null:
		return false

	if not is_world_action_in_reach(mouse_world_position):
		show_message("Too far away.")
		return true

	show_world_action_menu(target, get_viewport().get_mouse_position())
	return true

func get_world_action_target_at_position(world_position: Vector2) -> Node:
	var query_shape := CircleShape2D.new()
	query_shape.radius = world_action_click_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [get_rid()]

	var results := get_world_2d().direct_space_state.intersect_shape(query, 16)
	var best_target: Node = null
	var best_distance := INF

	for result in results:
		var collider := result.get("collider") as Node
		var target := get_world_action_target(collider)
		if target == null:
			continue

		var actions: Array = target.get_world_actions(self)
		if actions.is_empty():
			continue

		var distance := 0.0
		if target is Node2D:
			distance = world_position.distance_squared_to(target.global_position)

		if distance < best_distance:
			best_distance = distance
			best_target = target

	return best_target

func get_world_action_target(collider: Node) -> Node:
	var current := collider

	while current != null:
		if current.has_method("get_world_actions") and current.has_method("perform_world_action"):
			return current

		current = current.get_parent()

	return null

func is_world_action_in_reach(world_position: Vector2) -> bool:
	return global_position.distance_to(world_position) <= world_action_reach

func get_max_health():
	return 100 + ((skill_system.get_level("constitution") - 1) * 10)

func get_health_regen_rate():
	return skill_system.get_level("constitution") * health_regen_per_constitution_level

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
	var levels_gained := skill_system.gain_constitution_xp_from_damage(amount)

	if levels_gained > 0:
		health = get_max_health()
		show_message("Constitution level up! Level: %s" % skill_system.get_level("constitution"))

	update_health_label()
	update_constitution_label()

func gain_woodcutting_xp(amount):
	var levels_gained := skill_system.gain_xp("woodcutting", amount)

	if levels_gained > 0:
		print("Woodcutting level up! Level: ", skill_system.get_level("woodcutting"))

	update_woodcutting_label()

func gain_constitution_xp(amount):
	var levels_gained := skill_system.gain_xp("constitution", amount)

	if levels_gained > 0:
		health = get_max_health()
		show_message("Constitution level up! Level: %s" % skill_system.get_level("constitution"))

	update_health_label()
	update_constitution_label()

func update_wood_label():
	if wood_label == null:
		return

	wood_label.text = "Wood: %s" % inventory_system.get_wood()

func update_berries_label():
	if berries_label == null:
		return

	berries_label.text = "Berries: %s" % inventory_system.get_berries()

func update_item_count_labels():
	update_wood_label()
	update_berries_label()

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
	inventory_system.update_inventory_list()

func setup_equipment_slots():
	inventory_system.setup_equipment_slots()

func update_equipment_slots():
	inventory_system.update_equipment_slots()

func request_menu_fit_to_content():
	if menu == null:
		return

	if menu.has_method("request_fit_to_content"):
		menu.call("request_fit_to_content")

func get_inventory_slot_count() -> int:
	return inventory_system.get_inventory_slot_count()

func get_bag_slot_bonus(item_name: String) -> int:
	return inventory_system.get_bag_slot_bonus(item_name)

func can_equip_item_to_slot(item_name: String, slot_type: String) -> bool:
	return inventory_system.can_equip_item_to_slot(item_name, slot_type)

func equip_item_to_slot(item_name: String, slot_type: String):
	if not inventory_system.equip_item_to_slot(item_name, slot_type):
		return

	show_message("Equipped %s." % item_database.get_display_name(item_name))

func equip_item_to_first_available_slot(item_name: String):
	if not inventory_system.equip_item_to_first_available_slot(item_name):
		return

	show_message("Equipped %s." % item_database.get_display_name(item_name))

func get_possible_equipment_slots(item_name: String) -> Array:
	return inventory_system.get_possible_equipment_slots(item_name)

func get_item_equipment_slot(item_name: String) -> String:
	return inventory_system.get_item_equipment_slot(item_name)

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

	if item_database.can_eat(item_name):
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
		eat_item(selected_inventory_item)
	elif action_id == ACTION_EQUIP:
		equip_item_to_first_available_slot(selected_inventory_item)
	elif action_id == ACTION_EXAMINE:
		examine_item(selected_inventory_item)

	selected_inventory_item = ""

func _on_world_action_selected(action_id: int):
	if selected_world_target == null:
		return

	if selected_world_target.has_method("perform_world_action"):
		selected_world_target.perform_world_action(action_id, self)

	selected_world_target = null

func update_woodcutting_label():
	var text: String = skill_system.get_label_text("woodcutting")

	if woodcutting_label != null:
		woodcutting_label.text = text

	if woodcutting_skill_label != null:
		woodcutting_skill_label.text = "Wood\n%s" % skill_system.get_level("woodcutting")
		woodcutting_skill_label.tooltip_text = text

func update_constitution_label():
	var text: String = skill_system.get_label_text("constitution")

	if constitution_skill_label != null:
		constitution_skill_label.text = "Con\n%s" % skill_system.get_level("constitution")
		constitution_skill_label.tooltip_text = text
