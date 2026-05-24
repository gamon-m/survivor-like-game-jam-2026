extends Area2D

var speed = 100.0
var direction = Vector2.RIGHT
var range_travelled = 0.0
var damage
var crit_chance
var explosion_radius = 50.0
var shot_range

func _physics_process(delta):
	position += direction * speed * delta
	range_travelled += (direction * speed * delta).length()
	if range_travelled > shot_range*2: 
		_explode(null)
		queue_free()

func _on_body_entered(body):
	var hit_body = body
	var is_crit = _check_crit()
	if body.has_method("take_damage"):
		var dmg = damage * 2
		if is_crit:
			dmg *= 2
		body.take_damage(dmg)
	_explode(hit_body, is_crit)
	queue_free()

func _explode(hit_body, is_crit = false):
	AudioManager.play_sfx("explosion", global_position, -10.0)
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = explosion_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2

	var results = space.intersect_shape(query)
	for result in results:
		var body = result.get("collider") as Node
		if body and body.has_method("take_damage") and body != hit_body:
			if is_crit:
				damage *= 2
			body.take_damage(damage)

func _check_crit() -> bool:
	return randf() < crit_chance
