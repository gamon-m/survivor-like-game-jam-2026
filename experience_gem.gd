extends Area2D

@export var xp_amount = 1

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("gain_xp"):
		body.gain_xp(xp_amount)
		AudioManager.play_sfx("xp", global_position, 1.0)
		queue_free()