extends Node2D

@export var scene: PackedScene
@onready var range_finder = $RangeFinder


func _ready() -> void:
	range_finder.collision_mask = 1

func _on_timer_timeout() -> void:
	var entities_in_range = range_finder.get_overlapping_bodies()

	if entities_in_range.size() == 0:
		return
	
	var target_entity = null
	for entity in entities_in_range:
		if entity is not Player:
			continue
		target_entity = entity
		break

	if target_entity:
		shoot(target_entity)

func shoot(target):
	var projectile = scene.instantiate() as Area2D
	projectile.global_position = global_position
	var direction_to_target = global_position.direction_to(target.global_position)
	projectile.direction = direction_to_target

	projectile.look_at(target.global_position)
	projectile.damage = get_parent().bullet_damage
	projectile.crit_chance = 0.0

	get_tree().current_scene.add_child(projectile)
