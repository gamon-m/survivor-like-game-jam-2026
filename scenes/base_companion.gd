class_name BaseCompanion

extends CharacterBody2D

@export var player: Player
@export var follow_target: Node2D
@export var follow_distance: float = 20
@export var follow_speed: float = 3
@export var type: String
@export var holster_scene: PackedScene = preload("res://scenes/holster.tscn")

var orbit_angle: float = 0.0
var orbit_speed: float = 1.0
var holster
var damage = 0
var crit_chance = 0
var shot_range = 0

func _ready() -> void:
	player.connect("leveled_up", _update_stats)

	if type.to_lower() == "meatshield":
		_setup_meatshield()
		return

	holster = holster_scene.instantiate() as Node2D
	add_child(holster)

	_update_stats()

	match type.to_lower():
		"bomber":
			_setup_bomber()
		"fullauto":
			_setup_fullauto()


func _physics_process(delta: float) -> void:
	if not follow_target:
		return

	if type.to_lower() == "meatshield":
		_process_orbit_movement(delta)
	else:
		_process_lerp_movement(delta)


func _process_lerp_movement(delta):
	var direction = global_position.direction_to(follow_target.global_position)
	var target_position = follow_target.global_position - (direction * follow_distance)
	global_position = global_position.lerp(target_position, delta * follow_speed)

func _process_orbit_movement(delta):
	orbit_angle += delta * orbit_speed
	var offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * follow_distance * 2
	global_position = follow_target.global_position + offset

func _update_stats():
	damage = player.damage
	crit_chance = player.crit_chance
	shot_range = player.shot_range
	if holster:
		holster.get_node("RangeFinder/Range").shape.radius = shot_range

	match type.to_lower():
		"bomber":
			_apply_bomber_stats()
		"fullauto":
			_apply_fullauto_stats()

func _apply_bomber_stats():
	shot_range = player.shot_range / 2
	if holster:
		holster.get_node("RangeFinder/Range").shape.radius = shot_range

func _apply_fullauto_stats():
	damage = player.damage / 2

func _setup_bomber():
	holster.scene = preload("res://scenes/projectiles/bomber_projectile.tscn")
	holster.get_node("Timer").wait_time = 2.0

func _setup_fullauto():
	pass

func _setup_meatshield():
	follow_target = player
	get_node("ContactTimer").timeout.connect(_on_contact_timer_timeout)
	get_node("MeatshieldHitbox").area_entered.connect(_on_hitbox_area_entered)
	
func _on_contact_timer_timeout():
	for body in $MeatshieldHitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)

func _on_hitbox_area_entered(area: Area2D):
	pass
	
