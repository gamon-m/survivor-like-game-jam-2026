class_name BaseCompanion

extends CharacterBody2D

@export var player: Player
@export var follow_target: Node2D
@export var follow_distance: float = 20
@export var follow_speed: float = 3
@export var type: String

var orbit_angle: float = 0.0
var orbit_speed: float = 1.0

# func _ready():
	# if player:
	# 	follow_speed = player.speed

func _physics_process(delta: float) -> void:
	if not follow_target:
		print("no target")
		return

	if type == "Meatshield":
		follow_target = player
		_process_orbit_movement(delta)
	else:
		_process_lerp_movement(delta)


func _process_lerp_movement(delta):
	var direction = global_position.direction_to(follow_target.global_position)
	var target_position = follow_target.global_position - (direction * follow_distance)
	global_position = global_position.lerp(target_position, delta * follow_speed)

func _process_orbit_movement(delta):
	orbit_angle += delta * orbit_speed
	var offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * follow_distance
	global_position = follow_target.global_position + offset
