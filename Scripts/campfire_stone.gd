extends StaticBody2D

@export var starts_lit := false
@export var light_fade_in_time := 1.5
@export var light_fade_out_time := 1.2
@export var startup_flicker_strength := 0.45
@export var snuff_flicker_strength := 0.35
@export var transition_flicker_speed := 22.0

var is_lit := false
var transition_timer := 0.0
var campfire_state := "unlit"

@onready var firepit: AnimatedSprite2D = $Firepit
@onready var fire: AnimatedSprite2D = $Fire
@onready var smoke: AnimatedSprite2D = $Smoke
@onready var light_source: Node2D = $LightSource


func _ready():
	if starts_lit:
		start_lit()
	else:
		start_unlit()


func _process(delta):
	if light_source == null:
		return

	if campfire_state == "lighting":
		process_lighting(delta)
		return

	if campfire_state == "snuffing":
		process_snuffing(delta)


func interact(_player = null):
	if campfire_state == "unlit" or campfire_state == "snuffing":
		start_lighting()
	else:
		start_snuffing()


func start_unlit():
	is_lit = false
	campfire_state = "unlit"
	transition_timer = 0.0

	if firepit != null:
		firepit.visible = true
		firepit.play("snuffed")
		firepit.stop()

	if fire != null:
		fire.visible = false
		fire.stop()

	if smoke != null:
		smoke.visible = false
		smoke.stop()

	if light_source != null:
		light_source.visible = false
		set_light_energy_multiplier(0.0)


func start_lit():
	is_lit = true
	campfire_state = "lit"
	transition_timer = 0.0
	show_burning_visuals()
	set_light_energy_multiplier(1.0)


func start_lighting():
	is_lit = true
	campfire_state = "lighting"
	transition_timer = 0.0
	show_burning_visuals()
	set_light_energy_multiplier(0.0)


func start_snuffing():
	if campfire_state == "unlit":
		return

	campfire_state = "snuffing"
	transition_timer = 0.0


func process_lighting(delta: float):
	transition_timer += delta
	var fade_percent: float = 1.0

	if light_fade_in_time > 0:
		fade_percent = clamp(transition_timer / light_fade_in_time, 0.0, 1.0)

	var eased_percent: float = ease_smooth(fade_percent)
	var flicker: float = get_transition_flicker(transition_timer, startup_flicker_strength)
	var energy_percent: float = clamp(eased_percent + (flicker * (1.0 - fade_percent)), 0.0, 1.0)

	set_light_energy_multiplier(energy_percent)

	if fade_percent >= 1.0:
		start_lit()


func process_snuffing(delta: float):
	transition_timer += delta
	var fade_percent: float = 1.0

	if light_fade_out_time > 0:
		fade_percent = clamp(transition_timer / light_fade_out_time, 0.0, 1.0)

	var eased_percent: float = ease_smooth(fade_percent)
	var base_energy: float = 1.0 - eased_percent
	var flicker: float = get_transition_flicker(transition_timer, snuff_flicker_strength)
	var energy_percent: float = clamp(base_energy + (flicker * base_energy), 0.0, 1.0)

	set_light_energy_multiplier(energy_percent)

	if fade_percent >= 1.0:
		start_unlit()


func show_burning_visuals():
	if firepit != null:
		firepit.visible = true
		firepit.play("burning")

	if fire != null:
		fire.visible = true
		fire.play()

	if smoke != null:
		smoke.visible = true
		smoke.play()

	if light_source != null:
		light_source.visible = true


func ease_smooth(value: float) -> float:
	return value * value * (3.0 - (2.0 * value))


func get_transition_flicker(time: float, strength: float) -> float:
	var flicker: float = (
		sin(time * transition_flicker_speed)
		+ sin(time * transition_flicker_speed * 1.73)
		+ sin(time * transition_flicker_speed * 0.47)
	) / 3.0

	return flicker * strength


func set_light_energy_multiplier(value: float):
	if light_source == null:
		return

	if light_source.has_method("set_energy_multiplier"):
		light_source.set_energy_multiplier(value)
