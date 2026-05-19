extends CanvasLayer

signal retry_pressed

func _ready() -> void:
	visible = false

func show_game_over() -> void:
	visible = true
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	retry_pressed.emit()
