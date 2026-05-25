extends Node2D

@onready var player: Player = $Player
@onready var enemy_spawner: Timer = $Player/EnemySpawner/SpawnTimer
@onready var camera: Camera2D = $Player/Camera2D
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var ui: CanvasLayer = $UI

@export var boss_scene: PackedScene

var boss

func _ready() -> void:
	AudioManager.play_music("main")
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled_up)

func _on_player_died() -> void:
	AudioManager.stop_music()
	$GameOver.show_game_over()

func _on_player_leveled_up() -> void:
	if player.xp_level == 15:
		call_deferred("_start_boss_fight")

func _start_boss_fight():
	AudioManager.play_music("boss")
	enemy_spawner.stop()

	camera.limit_left = int(player.global_position.x)
	camera.limit_right = int(player.global_position.x)
	camera.limit_top = int(player.global_position.y)
	camera.limit_bottom = int(player.global_position.y)

	boss = boss_scene.instantiate()
	boss.global_position = player.global_position
	boss.global_position.y -= 150
	boss.player_reference = player
	boss.health_changed.connect(ui.set_boss_hp)
	boss.tree_exited.connect(_on_boss_died)
	add_child(boss)

	ui.show_boss_hp(boss.max_hp)

func _on_boss_died():
	ui.hide_boss_hp()
	ui.save_best_time_on_win()
	for enemy in enemies_container.get_children():
		enemy.queue_free()
	AudioManager.play_music("victory")
	$YouWin.show_you_win()
