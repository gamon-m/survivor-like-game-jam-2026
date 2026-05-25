extends CanvasLayer

@export var compananion_pool = {
	"gunner": {
		"name": "Gunner",
		"scene": preload("res://scenes/companions/gunner_companion.tscn")
	},
	"meatshield": {
		"name": "Meatshield",
		"scene": preload("res://scenes/companions/meatshield_companion.tscn")
	},
	"bomber": {
		"name": "Bomber",
		"scene": preload("res://scenes/companions/bomber_companion.tscn")
	},
	"fullauto": {
		"name": "Full Auto",
		"scene": preload("res://scenes/companions/fullauto_companion.tscn")
	}
} 
@export var player: Player
@onready var xp_bar: ProgressBar = $ProgressBar
@onready var level_label: Label = $ProgressBar/LevelLabel
@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var health_bar: ProgressBar = $HealthBar
@onready var level_up_label: Label = $LevelUpPanel/VBoxContainer/Label
@onready var character_button: Button = $LevelUpPanel/VBoxContainer/Button
@onready var stat_up_button: Button = $LevelUpPanel/VBoxContainer/Button2
@onready var heal_button: Button = $LevelUpPanel/VBoxContainer/Button3

@onready var sacrifice_panel: Panel = $ReplaceCompanionPanel
@onready var companion_one_button: Button = $ReplaceCompanionPanel/VBoxContainer/HBoxContainer/Companion1
@onready var companion_two_button: Button = $ReplaceCompanionPanel/VBoxContainer/HBoxContainer/Companion2
@onready var companion_three_button: Button = $ReplaceCompanionPanel/VBoxContainer/HBoxContainer/Companion3
@onready var companion_four_button: Button = $ReplaceCompanionPanel/VBoxContainer/HBoxContainer/Companion4
@onready var companion_five_button: Button = $ReplaceCompanionPanel/VBoxContainer/HBoxContainer/Companion5
@onready var back_button: Button = $ReplaceCompanionPanel/VBoxContainer/BackButton

@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var time_label: Label = $TimeLabel

var companion_buttons: Array[Button]
var _sacrifice_companion_idx := 0
var _sacrifice_on_back := false

var _elapsed_time: float = 0.0
var _pause_index := 0
var _character_callable: Callable
var _stat_callable: Callable
var _heal_callable: Callable
var _level_up_index := 0

var upgrade_templates = [
	{
		"stat": "damage",
		"label": "Damage",
		"base_min": 2,
		"base_max": 4,
		"scale_per_level": 0.3
	},
	{
		"stat": "crit_chance",
		"label": "Crit Chance",
		"base_min": 0.01,
		"base_max": 0.03,
		"scale_per_level": 0.1
	},
	{
		"stat": "shot_delay",
		"label": "Shot Delay",
		"base_min": 0.05,
		"base_max": 0.1,
		"scale_per_level": 0.1
	},
	{
		"stat": "shot_range",
		"label": "Shot Range",
		"base_min": 10,
		"base_max": 30,
		"scale_per_level": 0.2
	},
	{
		"stat": "max_health",
		"label": "Health",
		"base_min": 15,
		"base_max": 30,
		"scale_per_level": 0
	},
	{
		"stat": "speed",
		"label": "Movement Speed",
		"base_min": 5,
		"base_max": 10,
		"scale_per_level": 0.1
	}
]

var rarity_weights = {"common": 80, "rare": 20}
var disable_range_up = false
var pending_companion_data

func _setup_font():
	var font = FontFile.new()
	font.font_data = load("res://assets/monogram.ttf")
	var custom_theme = Theme.new()
	custom_theme.default_font = font
	custom_theme.default_font_size = 36
	custom_theme.set_font_size("font_size", "Label", 36)
	custom_theme.set_font_size("font_size", "Button", 36)
	for child in get_children():
		if child is Control:
			child.theme = custom_theme

func _ready() -> void:
	_setup_font()
	xp_bar.value = 0
	xp_bar.max_value = 100

	if !player:
		return
	level_label.text = "Level %d" % player.xp_level

	health_bar.value = player.health
	health_bar.max_value = player.max_health

	player.connect("xp_gained", _on_player_xp_gained)
	player.connect("leveled_up", _on_player_leveled_up)
	player.connect("health_changed", _on_player_health_changed)
	pause_overlay.visible = false

func _process(delta):
	if not get_tree().paused:
		_elapsed_time += delta
	time_label.text = _format_time(_elapsed_time)

func _format_time(secs: float) -> String:
	var m = int(secs) / 60
	var s = int(secs) % 60
	return "%02d:%02d" % [m, s]

func save_best_time_on_win():
	_save_best_time()

func _save_best_time():
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	var best = cfg.get_value("game", "best_time", INF)
	if _elapsed_time < best:
		cfg.set_value("game", "best_time", _elapsed_time)
		cfg.save("user://settings.cfg")

func _input(event):
	if pause_overlay.visible:
		_handle_pause_nav(event)
		if event.is_action_pressed("pause"):
			_toggle_pause()
			get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed("pause"):
		if $LevelUpPanel.visible or $ReplaceCompanionPanel.visible:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()

	if $LevelUpPanel.visible and not $ReplaceCompanionPanel.visible:
		_handle_level_up_nav(event)
	elif $ReplaceCompanionPanel.visible:
		_handle_sacrifice_nav(event)

func _toggle_pause():
	pause_overlay.visible = not pause_overlay.visible
	get_tree().paused = pause_overlay.visible
	if pause_overlay.visible:
		_pause_index = 0
		$PauseOverlay/Panel/VBoxContainer/ResumeButton.grab_focus()

func _handle_pause_nav(event):
	var buttons = [$PauseOverlay/Panel/VBoxContainer/ResumeButton, $PauseOverlay/Panel/VBoxContainer/MainMenuButton]
	var vp = get_viewport()
	if event.is_action_pressed("move_up"):
		_pause_index = (_pause_index - 1 + buttons.size()) % buttons.size()
		buttons[_pause_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_pause_index = (_pause_index + 1) % buttons.size()
		buttons[_pause_index].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		buttons[_pause_index].pressed.emit()
		if vp: vp.set_input_as_handled()

func _on_pause_resume_pressed():
	_toggle_pause()

func _on_pause_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _handle_level_up_nav(event):
	var buttons = [character_button, stat_up_button, heal_button]
	if event.is_action_pressed("move_up"):
		_level_up_index = (_level_up_index - 1 + buttons.size()) % buttons.size()
		buttons[_level_up_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_level_up_index = (_level_up_index + 1) % buttons.size()
		buttons[_level_up_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		buttons[_level_up_index].pressed.emit()
		get_viewport().set_input_as_handled()

func _handle_sacrifice_nav(event):
	var vp = get_viewport()
	if event.is_action_pressed("move_left"):
		if not _sacrifice_on_back:
			_sacrifice_companion_idx = (_sacrifice_companion_idx - 1 + player.companions.size()) % player.companions.size()
			companion_buttons[_sacrifice_companion_idx].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		if not _sacrifice_on_back:
			_sacrifice_companion_idx = (_sacrifice_companion_idx + 1) % player.companions.size()
			companion_buttons[_sacrifice_companion_idx].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_up"):
		if _sacrifice_on_back:
			_sacrifice_on_back = false
			companion_buttons[_sacrifice_companion_idx].grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		if not _sacrifice_on_back:
			_sacrifice_on_back = true
			back_button.grab_focus()
		if vp: vp.set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		if _sacrifice_on_back:
			back_button.pressed.emit()
		else:
			companion_buttons[_sacrifice_companion_idx].pressed.emit()
		if vp: vp.set_input_as_handled()

func _on_player_xp_gained(current, max_xp) -> void:
	xp_bar.value = current
	xp_bar.max_value = max_xp
	level_label.text = "Level %d" % player.xp_level

func _on_player_health_changed(current, max_health) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func show_boss_hp(max_hp: int) -> void:
	xp_bar.visible = false
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = max_hp
	boss_health_bar.visible = true

func hide_boss_hp() -> void:
	boss_health_bar.visible = false
	xp_bar.visible = true

func set_boss_hp(current: int, max_hp: int) -> void:
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = current

func _on_player_leveled_up() -> void:
	level_up_label.text = "Choose your reward!"
	get_tree().paused = true
	$LevelUpPanel.visible = true
	xp_bar.value = 0
	
	var companion_data = _generate_random_companion()
	var upgrade = _generate_random_upgrade()
	var heal_amount = int(player.max_health * 0.3)
	
	character_button.text = "Companion: " + companion_data.name
	character_button.disabled = false
	stat_up_button.text = upgrade.label
	stat_up_button.disabled = false
	heal_button.text = "Heal (%d HP)" % heal_amount
	heal_button.disabled = false
	
	_character_callable = _on_companion_selected.bind(companion_data)
	_stat_callable = _on_stat_selected.bind(upgrade)
	_heal_callable = _on_heal_selected.bind(heal_amount)
	
	character_button.pressed.connect(_character_callable)
	stat_up_button.pressed.connect(_stat_callable)
	heal_button.pressed.connect(_heal_callable)
	_level_up_index = 0
	character_button.grab_focus()

func _on_companion_selected(companion_data):
	if player.companions.size() >= 5:
		pending_companion_data = companion_data
		$LevelUpPanel.visible = false
		$ReplaceCompanionPanel.visible = true
		_populate_sacrifice_buttons()
	else:
		var companion = companion_data.scene.instantiate()
		companion.player = player
		companion.type = companion_data.name
		companion.global_position = player.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		get_tree().current_scene.add_child(companion)
		player.add_companion(companion)
		_on_resume()
		_clear_button_signals()

func _populate_sacrifice_buttons():
	back_button.connect("pressed", _on_sacrifice_back)
	companion_buttons = []
	_sacrifice_companion_idx = 0
	_sacrifice_on_back = false
	var all_buttons = [companion_one_button, companion_two_button, companion_three_button, companion_four_button, companion_five_button]
	for index in range(player.companions.size()):
		companion_buttons.append(all_buttons[index])
		companion_buttons[index].text = player.companions[index].type
		companion_buttons[index].connect("pressed", _on_sacrifice_selected.bind(index))
	companion_buttons[0].grab_focus()

func _on_sacrifice_selected(index):
	var companion_position = player.companions[index].global_position
	player.companions[index].queue_free()
	var companion = pending_companion_data.scene.instantiate()
	player.replace_companion(index, companion)
	companion.player = player
	companion.type = pending_companion_data.name
	companion.global_position = companion_position
	player.companions[index] = companion

	get_tree().current_scene.add_child(companion)
	$ReplaceCompanionPanel.visible = false
	_on_resume()
	_clear_button_signals()

func _on_sacrifice_back():
	$ReplaceCompanionPanel.visible = false
	$LevelUpPanel.visible = true
	pending_companion_data = null
	_level_up_index = 0
	character_button.grab_focus()

func _on_stat_selected(upgrade):
	player.apply_stat(upgrade.stat, upgrade.value)
	_on_resume()
	_clear_button_signals()

func _on_heal_selected(amount):
	player.heal(amount)
	_on_resume()
	_clear_button_signals()

func _clear_button_signals():
	character_button.pressed.disconnect(_character_callable)
	stat_up_button.pressed.disconnect(_stat_callable)
	heal_button.pressed.disconnect(_heal_callable)

func _on_resume():
	$LevelUpPanel.visible = false
	get_tree().paused = false

func _generate_random_upgrade() -> Dictionary:
	var template = _get_available_upgrade()
	var current_stat_level = player.get_stat_level(template.stat)
	var rarity = _weighted_pick(rarity_weights)

	var base_val = randf_range(template.base_min, template.base_max)
	var rarity_multiplier = 2.0 if rarity == "rare" else 1.0
	var level_multiplier = 1.0 + (current_stat_level * template.scale_per_level)

	var final_val = base_val * rarity_multiplier * level_multiplier
	
	var old_val = _get_current_stat(template.stat)

	var new_val = old_val + final_val
	if template.stat == "shot_delay":
		new_val = old_val - final_val
		new_val = _cap_shot_delay(new_val)

	if template.stat == "shot_range":
		new_val = _cap_range_up(new_val)

	var display_old = _format_stat(template.stat, old_val)
	var display_new = _format_stat(template.stat, new_val)
	
	var label = "%s (%s > %s)" % [template.label, display_old, display_new]
	if rarity == "rare":
		label = "RARE!!! " + label


	return {
		"stat": template.stat,
		"label": label,
		"rarity": rarity,
		"value": final_val
	}

func _get_available_upgrade() -> Dictionary:
	var available = upgrade_templates
	if player.shot_range >= 200:
		available = available.filter(func(t): return t.stat != "shot_range")
	if player.shot_delay <= 0.2:
		available = available.filter(func(t): return t.stat != "shot_delay")
	return available.pick_random()

func _get_current_stat(stat_name: String) -> float:
	match stat_name:
		"damage": return player.damage
		"crit_chance": return player.crit_chance
		"shot_delay": return player.shot_delay
		"shot_range": return player.shot_range
		"max_health": return player.max_health
		"speed": return player.speed
	return 0

func _format_stat(stat_name: String, value: float) -> String:
	match stat_name:
		"crit_chance": return "%d%%" % int(value * 100)
		"damage", "max_health", "shot_range", "speed": return "%d" % int(value)
		"shot_delay": return "%.2fs" % value
	return "%s" % value

func _weighted_pick(weights: Dictionary) -> String:
	var total = 0.0
	for key in weights: total += weights[key]
	var roll = randf() * total
	for key in weights:
		roll -= weights[key]
		if roll <= 0: return key
	return weights.keys()[0]

func _cap_range_up(value) -> float:
	if value >= 200:
		return 200
	return value

func _cap_shot_delay(value) -> float:
	if value <= 0.2:
		return 0.2
	return value

func _generate_random_companion():
	var key = compananion_pool.keys().pick_random()
	return compananion_pool[key]
