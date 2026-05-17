extends Node2D

@export var enemy_scenes: Array[PackedScene]
@onready var spawn_path: PathFollow2D = %PathFollow2D

func _ready() -> void:
	$SpawnTimer.connect("timeout", _on_timer_timeout)

func _on_timer_timeout() -> void:
	var enemy = enemy_scenes.pick_random().instantiate() as CharacterBody2D

	spawn_path.progress_ratio = randf()
	enemy.global_position = spawn_path.global_position
	enemy.player_reference = get_parent()

	get_tree().current_scene.add_child(enemy)
