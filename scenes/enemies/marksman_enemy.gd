extends "res://scenes/base_enemy.gd"

@export var shot_range = 100
@export var stop_distance = 130
@export var bullet_scene: PackedScene
@export var bullet_speed = 150
@export var bullet_damage = 10
@export var shot_delay = 1.5

func _ready():
	super()
	$Holster.scene = bullet_scene
	$Holster/Timer.wait_time = shot_delay
	$Holster/Timer.start()
	$Holster.call_deferred("_on_timer_timeout")
	var shape = $Holster/RangeFinder/Range.shape as CircleShape2D
	if shape:
		shape.radius = shot_range

func _physics_process(delta):
	if !player_reference:
		return

	var distance = global_position.distance_to(player_reference.global_position)
	var direction = global_position.direction_to(player_reference.global_position)

	if distance > stop_distance:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	$AnimationPlayer.play("run")
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false

	move_and_slide()

	var targets = $Hitbox.get_overlapping_bodies()
	for target in targets:
		if target is Player:
			target.take_damage(contact_damage)