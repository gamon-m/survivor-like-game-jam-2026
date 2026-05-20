extends Area2D

var speed = 300.0
var direction = Vector2.RIGHT
var range_travelled = 0.0
var damage
var crit_chance

func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	position += movement

	range_travelled += movement.length()
	if range_travelled > 1000.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if _check_crit():
			damage *= 2
		body.take_damage(damage)
		queue_free()
	else:
		queue_free()

func _check_crit() -> bool:
	return randf() < crit_chance