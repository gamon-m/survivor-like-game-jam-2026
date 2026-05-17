class_name Player

extends CharacterBody2D

@export var speed = 150.0

func _physics_process(_delta: float) -> void:	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if direction:
		$AnimationPlayer.play("run")
		if velocity.x < 0:
			$Sprite2D.flip_h = true
		elif velocity.x > 0:
			$Sprite2D.flip_h = false
	else:
		$AnimationPlayer.play("idle")
