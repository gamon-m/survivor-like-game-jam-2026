extends Node2D

func _ready() -> void:
	$Player.died.connect($GameOver.show_game_over)
