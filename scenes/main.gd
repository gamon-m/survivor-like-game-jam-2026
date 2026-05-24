extends Node2D

@onready var player: Player = $Player
@onready var enemy_spawner: Timer = $Player/EnemySpawner/SpawnTimer
@onready var camera: Camera2D = $Player/Camera2D
@onready var enemies_container: Node2D = $EnemiesContainer

@export var boss_scene: PackedScene

var boss


func _ready() -> void:
	player.died.connect($GameOver.show_game_over)
	player.leveled_up.connect(_on_player_leveled_up)

func _on_player_leveled_up() -> void:
	if player.xp_level == 1:
		call_deferred("_start_boss_fight")

func _start_boss_fight():
	enemy_spawner.stop()


	camera.limit_left = int(player.global_position.x)
	camera.limit_right = int(player.global_position.x)
	camera.limit_top = int(player.global_position.y)
	camera.limit_bottom = int(player.global_position.y)

	boss = boss_scene.instantiate()
	boss.global_position = player.global_position
	boss.global_position.y -= 150
	boss.player_reference = player
	add_child(boss)
