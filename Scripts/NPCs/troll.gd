extends CharacterBody2D

enum Faction {
	FRIENDLY,
	NEUTRAL,
	ENEMY
}

@export var faction: Faction = Faction.ENEMY
@export var speed := 80.0
@export var aggro_radius := 220.0
@export var stop_distance := 24.0
@export var max_health := 30.0
@export var attack_damage := 5.0
@export var attack_cooldown := 2.0
@export var hit_flash_time := 0.12
@export var health_regen_rate := 0.1
@export var health_regen_delay_after_damage := 5.0

var health := max_health
var dead := false
var player: Node2D
var player_in_attack_range := false
var attack_timer := 0.0
var hit_flash_timer := 0.0
var health_regen_delay_timer := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

func _ready():
	update_faction_groups()
	health = max_health
	setup_health_bar()
	player = get_tree().current_scene.get_node_or_null("Player")
	animated_sprite.play("idle")

	if attack_area != null:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)

func _physics_process(delta):
	if dead:
		return

	handle_hit_flash(delta)
	handle_health_regen(delta)

	if not is_enemy():
		player_in_attack_range = false
		play_idle()
		move_and_slide()
		return

	handle_attack_timer(delta)

	if player == null:
		play_idle()
		return

	var direction := global_position.direction_to(player.global_position)
	var distance := global_position.distance_to(player.global_position)

	if distance <= stop_distance:
		velocity = Vector2.ZERO
		animated_sprite.flip_h = direction.x > 0
		animated_sprite.play("idle")
	elif distance <= aggro_radius:
		velocity = direction * speed
		animated_sprite.flip_h = direction.x > 0
		animated_sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		play_idle()

	move_and_slide()

func handle_attack_timer(delta):
	if attack_timer > 0:
		attack_timer -= delta

	if player_in_attack_range and attack_timer <= 0:
		attack_player()

func handle_health_regen(delta):
	if health_regen_delay_timer > 0:
		health_regen_delay_timer -= delta
		return

	if health <= 0 or health >= max_health:
		return

	if health_regen_rate <= 0:
		return

	health += health_regen_rate * delta
	health = clamp(health, 0, max_health)
	update_health_bar()

func attack_player():
	if not is_enemy():
		return

	if player == null:
		return

	if not player.has_method("take_damage"):
		return

	player.take_damage(attack_damage)
	attack_timer = attack_cooldown

func play_idle():
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func _on_attack_area_body_entered(body):
	if is_enemy() and body == player:
		player_in_attack_range = true
		attack_timer = 0.0

func _on_attack_area_body_exited(body):
	if body == player:
		player_in_attack_range = false

func take_damage(amount):
	if dead:
		return

	health -= amount
	health = clamp(health, 0, max_health)
	health_regen_delay_timer = health_regen_delay_after_damage
	update_health_bar()
	start_hit_flash()

	if health <= 0:
		die()

func is_dead() -> bool:
	return dead

func is_enemy() -> bool:
	return faction == Faction.ENEMY

func update_faction_groups():
	add_to_group("npcs")
	remove_from_group("friendly_npcs")
	remove_from_group("neutral_npcs")
	remove_from_group("enemies")

	if faction == Faction.FRIENDLY:
		add_to_group("friendly_npcs")
	elif faction == Faction.NEUTRAL:
		add_to_group("neutral_npcs")
	elif faction == Faction.ENEMY:
		add_to_group("enemies")

func setup_health_bar():
	if health_bar == null:
		return

	health_bar.visible = false
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	update_health_bar_color()

func update_health_bar():
	if health_bar == null:
		return

	health_bar.visible = true
	health_bar.max_value = max_health
	health_bar.value = health
	update_health_bar_color()

func update_health_bar_color():
	if health_bar == null:
		return

	var fill_style := StyleBoxFlat.new()

	if health <= max_health / 3.0:
		fill_style.bg_color = Color(0.9, 0.08, 0.06, 1)
	else:
		fill_style.bg_color = Color(0.15, 0.85, 0.18, 1)

	health_bar.add_theme_stylebox_override("fill", fill_style)

func start_hit_flash():
	hit_flash_timer = hit_flash_time
	animated_sprite.modulate = Color(1.8, 1.8, 1.8, 1)

func handle_hit_flash(delta):
	if hit_flash_timer <= 0:
		return

	hit_flash_timer -= delta

	if hit_flash_timer <= 0:
		animated_sprite.modulate = Color(1, 1, 1, 1)

func die():
	dead = true
	velocity = Vector2.ZERO
	animated_sprite.modulate = Color(1, 1, 1, 1)
	if health_bar != null:
		health_bar.visible = false
	if death_sound != null:
		death_sound.play()
	animated_sprite.play("death")
	$CollisionShape2D.disabled = true
