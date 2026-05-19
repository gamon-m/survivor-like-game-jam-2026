extends Node2D

@onready var game_over = $GameOver

func _ready() -> void:
	$Player.died.connect(game_over.show_game_over)
	game_over.retry_pressed.connect(_on_retry)

func _on_retry() -> void:
	get_tree().reload_current_scene()
