extends Node2D

@export var enemy_scenes: Array[EnemyConfig]
@onready var spawn_path: PathFollow2D = %PathFollow2D

func _ready() -> void:
	$SpawnTimer.connect("timeout", _on_timer_timeout)

func _on_timer_timeout() -> void:
	var filtered = enemy_scenes.filter(func(x): return x.enemy_type != "swarmer")
	var enemy_config = filtered.pick_random()
	var enemy = enemy_config.scene.instantiate()

	spawn_path.progress_ratio = randf()
	enemy.global_position = spawn_path.global_position
	enemy.player_reference = get_parent()

	get_tree().current_scene.add_child(enemy)
