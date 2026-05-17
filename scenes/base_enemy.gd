extends CharacterBody2D

@export var speed = 100.0
@export var player_reference : CharacterBody2D
@export var enemy_type: String

func _physics_process(_delta: float) -> void:
	if !player_reference:
		return

	var direction = global_position.direction_to(player_reference.global_position)
	velocity = direction * speed

	$AnimationPlayer.play("run")
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false

	move_and_slide()
