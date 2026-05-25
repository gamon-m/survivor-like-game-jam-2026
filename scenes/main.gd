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

	_create_arena_barriers()

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
	_remove_arena_barriers()
	AudioManager.play_music("victory")
	$YouWin.show_you_win()

func _create_arena_barriers():
	var viewport_size = get_viewport_rect().size
	var zoom = camera.zoom
	var half_w = (viewport_size.x / zoom.x) / 2.0
	var half_h = (viewport_size.y / zoom.y) / 2.0
	var thickness = 20.0
	var vertical_inset = 20.0
	var center = player.global_position

	var container = Node2D.new()
	container.name = "ArenaBarriers"

	var top = StaticBody2D.new()
	var top_shape = CollisionShape2D.new()
	top_shape.shape = RectangleShape2D.new()
	top_shape.shape.size = Vector2(half_w * 2.0 + thickness * 2.0, thickness)
	top.add_child(top_shape)
	top.position = Vector2(center.x, center.y - half_h + vertical_inset - thickness / 2.0)
	top.collision_layer = 4
	container.add_child(top)

	var bottom = StaticBody2D.new()
	var bottom_shape = CollisionShape2D.new()
	bottom_shape.shape = RectangleShape2D.new()
	bottom_shape.shape.size = Vector2(half_w * 2.0 + thickness * 2.0, thickness)
	bottom.add_child(bottom_shape)
	bottom.position = Vector2(center.x, center.y + half_h - vertical_inset + thickness / 2.0)
	bottom.collision_layer = 4
	container.add_child(bottom)

	var left = StaticBody2D.new()
	var left_shape = CollisionShape2D.new()
	left_shape.shape = RectangleShape2D.new()
	left_shape.shape.size = Vector2(thickness, (half_h - vertical_inset) * 2.0 + thickness * 2.0)
	left.add_child(left_shape)
	left.position = Vector2(center.x - half_w - thickness / 2.0, center.y)
	left.collision_layer = 4
	container.add_child(left)

	var right = StaticBody2D.new()
	var right_shape = CollisionShape2D.new()
	right_shape.shape = RectangleShape2D.new()
	right_shape.shape.size = Vector2(thickness, (half_h - vertical_inset) * 2.0 + thickness * 2.0)
	right.add_child(right_shape)
	right.position = Vector2(center.x + half_w + thickness / 2.0, center.y)
	right.collision_layer = 4
	container.add_child(right)

	add_child(container)

func _remove_arena_barriers():
	var barriers = get_node_or_null("ArenaBarriers")
	if barriers:
		barriers.queue_free()
