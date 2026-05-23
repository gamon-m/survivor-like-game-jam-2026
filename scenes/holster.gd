extends Node2D

@export var scene: PackedScene
@onready var range_finder = $RangeFinder


func _on_timer_timeout() -> void:
	var enemies_in_range = range_finder.get_overlapping_bodies()

	if enemies_in_range.size() == 0:
		return
	
	var target_enemy = null
	var shortest_distance = INF
	for enemy in enemies_in_range:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			target_enemy = enemy

	if target_enemy:
		shoot(target_enemy)

func shoot(target):
	var projectile = scene.instantiate() as Area2D
	projectile.global_position = global_position
	var direction_to_target = global_position.direction_to(target.global_position)
	projectile.direction = direction_to_target

	projectile.look_at(target.global_position)
	projectile.damage = get_parent().damage
	projectile.crit_chance = get_parent().crit_chance
	projectile.shot_range = get_parent().shot_range

	get_tree().current_scene.add_child(projectile)
