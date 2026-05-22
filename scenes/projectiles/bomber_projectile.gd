extends Area2D

var speed = 100.0
var direction = Vector2.RIGHT
var range_travelled = 0.0
var damage
var crit_chance
var explosion_radius = 50.0

func _physics_process(delta):
	position += direction * speed * delta
	range_travelled += (direction * speed * delta).length()
	if range_travelled > 800.0:
		queue_free()

func _on_body_entered(body):
	var hit_body = body
	if body.has_method("take_damage"):
		body.take_damage(damage * 2)
	_explode(hit_body)
	queue_free()

func _explode(hit_body):
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
			body.take_damage(damage)
