extends Area2D

@export var music_stream: AudioStream
@export var trigger_radius := 96.0
@export var volume_db := -8.0
@export var play_once := true
@export var stop_when_player_exits := false

var has_played := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 1
	setup_radius()
	setup_audio()


func setup_radius() -> void:
	var circle_shape := collision_shape.shape as CircleShape2D
	if circle_shape == null:
		circle_shape = CircleShape2D.new()
		collision_shape.shape = circle_shape

	circle_shape.radius = trigger_radius


func setup_audio() -> void:
	audio_player.stream = music_stream
	audio_player.volume_db = volume_db


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if play_once and has_played:
		return
	if audio_player.stream == null:
		return

	audio_player.play()
	has_played = true


func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	if stop_when_player_exits and audio_player.playing:
		audio_player.stop()
