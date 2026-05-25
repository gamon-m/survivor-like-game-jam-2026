extends Control

var _main_index := 0
var _settings_index := 0

func _ready():
	AudioManager.play_music("title")
	_setup_theme()
	$SettingsPanel.hide()
	$VBoxContainer/PlayButton.grab_focus()

func _setup_theme():
	var font = FontFile.new()
	font.font_data = load("res://assets/monogram.ttf")

	var custom_theme = Theme.new()
	custom_theme.default_font = font
	custom_theme.default_font_size = 28
	custom_theme.set_font_size("font_size", "Label", 28)
	custom_theme.set_font_size("font_size", "Button", 28)
	theme = custom_theme

	$VBoxContainer/Title.add_theme_font_size_override("font_size", 56)
	$SettingsPanel/VBox/Title.add_theme_font_size_override("font_size", 48)

	$SettingsPanel/VBox/VBox/VolumeContainer/VolumeSlider.value = AudioManager.master_volume * 100.0
	$SettingsPanel/VBox/VBox/VolumeContainer/VolumeValue.text = "%d%%" % (AudioManager.master_volume * 100.0)

	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	var best = cfg.get_value("game", "best_time", -1.0)
	if best > 0:
		var m = int(best) / 60
		var s = int(best) % 60
		$BestTimeLabel.text = "Best: %02d:%02d" % [m, s]

func _input(event):
	if $SettingsPanel.visible:
		_handle_settings_nav(event)
	else:
		_handle_main_nav(event)

func _handle_main_nav(event):
	var buttons = [$VBoxContainer/PlayButton, $VBoxContainer/SettingsButton, $VBoxContainer/ExitButton]
	var vp = get_viewport()
	if event.is_action_pressed("move_up"):
		_main_index = (_main_index - 1 + buttons.size()) % buttons.size()
		buttons[_main_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_main_index = (_main_index + 1) % buttons.size()
		buttons[_main_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		buttons[_main_index].pressed.emit()
		if vp: vp.set_input_as_handled()

func _handle_settings_nav(event):
	var vp = get_viewport()
	if event.is_action_pressed("pause"):
		_on_settings_back_pressed()
		if vp: vp.set_input_as_handled()
		return
	var slider = $SettingsPanel/VBox/VBox/VolumeContainer/VolumeSlider
	var back = $SettingsPanel/VBox/BackButton
	var controls = [slider, back]
	if event.is_action_pressed("move_up"):
		_settings_index = (_settings_index - 1 + controls.size()) % controls.size()
		controls[_settings_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_settings_index = (_settings_index + 1) % controls.size()
		controls[_settings_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		if controls[_settings_index] == slider:
			slider.value = max(slider.min_value, slider.value - 5)
			if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		if controls[_settings_index] == slider:
			slider.value = min(slider.max_value, slider.value + 5)
			if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if controls[_settings_index] == back:
			back.pressed.emit()
		if vp: vp.set_input_as_handled()

func _on_play_pressed():
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed():
	$VBoxContainer.hide()
	$SettingsPanel.show()
	_settings_index = 0
	$SettingsPanel/VBox/VBox/VolumeContainer/VolumeSlider.grab_focus()

func _on_settings_back_pressed():
	$SettingsPanel.hide()
	$VBoxContainer.show()
	_main_index = 1
	$VBoxContainer/SettingsButton.grab_focus()

func _on_exit_pressed():
	get_tree().quit()

func _on_volume_slider_value_changed(value):
	AudioManager.set_master_volume(value / 100.0)
	$SettingsPanel/VBox/VBox/VolumeContainer/VolumeValue.text = "%d%%" % value
