extends CanvasLayer

var _nav_index := 0

func _setup_font():
	var font = FontFile.new()
	font.font_data = load("res://assets/monogram.ttf")
	var custom_theme = Theme.new()
	custom_theme.default_font = font
	custom_theme.default_font_size = 28
	custom_theme.set_font_size("font_size", "Label", 28)
	custom_theme.set_font_size("font_size", "Button", 28)
	for child in get_children():
		if child is Control:
			child.theme = custom_theme

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_setup_font()
	visible = false

func _input(event):
	if not visible:
		return
	var buttons = [$Panel/VBoxContainer/RetryButton, $Panel/VBoxContainer/MainMenuButton]
	var vp = get_viewport()
	if event.is_action_pressed("move_up"):
		_nav_index = (_nav_index - 1 + buttons.size()) % buttons.size()
		buttons[_nav_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_nav_index = (_nav_index + 1) % buttons.size()
		buttons[_nav_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		buttons[_nav_index].pressed.emit()
		if vp: vp.set_input_as_handled()

func show_you_win() -> void:
	visible = true
	get_tree().paused = true
	_nav_index = 0
	$Panel/VBoxContainer/RetryButton.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
