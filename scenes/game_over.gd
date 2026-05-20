extends CanvasLayer

func _ready() -> void:
	visible = false

func show_game_over() -> void:
	visible = true
	get_tree().paused = true

func _on_retry_pressed() -> void:
	print("Retry button pressed!")
	get_tree().paused = false
	get_tree().reload_current_scene()
