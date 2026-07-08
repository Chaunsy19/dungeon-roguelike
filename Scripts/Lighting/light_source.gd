extends Node2D

@export var light_color := Color(1.0, 0.72, 0.38, 1.0)
@export var light_energy := 1.4
@export var light_scale := 1.1
@export var flicker_enabled := true
@export var flicker_strength := 0.10
@export var flicker_speed := 6.0

var flicker_time := 0.0
var energy_multiplier := 1.0

@onready var point_light: PointLight2D = $PointLight2D

func _ready():
	apply_light_settings()

func _process(delta):
	if point_light == null:
		return

	if not flicker_enabled:
		point_light.energy = light_energy * energy_multiplier
		return

	flicker_time += delta * flicker_speed
	var flicker: float = (sin(flicker_time) + sin(flicker_time * 2.37)) * 0.5
	point_light.energy = max(0.0, light_energy + (flicker * flicker_strength)) * energy_multiplier

func apply_light_settings():
	if point_light == null:
		return

	point_light.color = light_color
	point_light.energy = light_energy * energy_multiplier
	point_light.texture_scale = light_scale

func set_energy_multiplier(value: float):
	energy_multiplier = clamp(value, 0.0, 1.0)
	apply_light_settings()
