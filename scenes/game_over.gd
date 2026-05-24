extends CanvasLayer

func _ready() -> void:
	visible = false

func show_game_over() -> void:
	AudioManager.play_sfx("game_over")
	visible = true
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
