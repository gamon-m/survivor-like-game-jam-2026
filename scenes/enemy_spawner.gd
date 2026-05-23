extends Node2D

@export var enemy_scenes: Array[EnemyConfig]
@export var max_enemies: int = 100
@onready var spawn_path: PathFollow2D = %PathFollow2D

var level_requirements = {
	"chaser": 0,
	"tank": 3,
	"marksman": 7,
	"swarmer": 10,
}

var spawn_weights = {
	"chaser": 0,
	"tank": 0,
	"marksman": 2,
	"swarmer": 0,
}

func _ready() -> void:
	$SpawnTimer.connect("timeout", _on_timer_timeout)

func _on_timer_timeout() -> void:
	var container = get_tree().current_scene.get_node("EnemiesContainer")
	if container.get_child_count() >= max_enemies:
		return

	var player_level = get_parent().xp_level
	var available = enemy_scenes.filter(func(c): return player_level >= level_requirements.get(c.enemy_type, 99))
	if available.is_empty():
		return
	var enemy_config = _weighted_pick(enemy_scenes)
	var enemy = enemy_config.scene.instantiate()

	spawn_path.progress_ratio = randf()
	enemy.global_position = spawn_path.global_position
	enemy.player_reference = get_parent()

	container.add_child(enemy)

func _weighted_pick(configs: Array) -> EnemyConfig:
	var total = 0
	for c in configs:
		total += spawn_weights.get(c.enemy_type, 1)
	var roll = randi() % total
	for c in configs:
		roll -= spawn_weights.get(c.enemy_type, 1)
		if roll < 0:
			return c
	return configs.back()
