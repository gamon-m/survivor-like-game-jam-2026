extends CanvasLayer

@export var compananion_pool: PackedStringArray = [
    "bomber", 
    "damage_augmentor", 
    "full_auto", 
    "gunner", 
    "meatshield", 
    "speed_augmentor"
    ]
@export var player: Player
@onready var xp_bar: ProgressBar = $ProgressBar
@onready var health_bar: ProgressBar = $HealthBar
@onready var level_up_label: Label = $LevelUpPanel/VBoxContainer/Label
@onready var character_button: Button = $LevelUpPanel/VBoxContainer/Button
@onready var stat_up_button: Button = $LevelUpPanel/VBoxContainer/Button2
@onready var heal_button: Button = $LevelUpPanel/VBoxContainer/Button3

var _character_callable: Callable
var _stat_callable: Callable
var _heal_callable: Callable

var upgrade_templates = [
	{
		"stat": "damage",
		"label": "Damage",
		"base_min": 2,
		"base_max": 5,
		"scale_per_level": 0.3
	},
	{
		"stat": "crit_chance",
		"label": "Crit Chance",
		"base_min": 0.02,
		"base_max": 0.05,
		"scale_per_level": 0.2
	},
	{
		"stat": "shot_speed",
		"label": "Shot Speed",
		"base_min": 0.05,
		"base_max": 0.2,
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
		"base_min": 20,
		"base_max": 50,
		"scale_per_level": 0
	},
	{
		"stat": "speed",
		"label": "Movement Speed",
		"base_min": 5,
		"base_max": 15,
		"scale_per_level": 0.1
	}
]

var rarity_weights = {"common": 0, "rare": 100}

func _ready() -> void:
	xp_bar.value = 0
	xp_bar.max_value = 100

	if !player:
		return

	health_bar.value = player.health
	health_bar.max_value = player.max_health

	player.connect("xp_gained", _on_player_xp_gained)
	player.connect("leveled_up", _on_player_leveled_up)
	player.connect("health_changed", _on_player_health_changed)
	

func _on_player_xp_gained(current, max_xp) -> void:
	xp_bar.value = current
	xp_bar.max_value = max_xp

func _on_player_health_changed(current, max_health) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func _on_player_leveled_up() -> void:
	level_up_label.text = "Choose your reward!"
	get_tree().paused = true
	$LevelUpPanel.visible = true
	xp_bar.value = 0
	
	var companion = compananion_pool[randi() % compananion_pool.size()]
	var upgrade = _generate_random_upgrade()
	var heal_amount = int(player.max_health * 0.3)
	
	character_button.text = "Companion: " + companion.capitalize()
	character_button.disabled = false
	stat_up_button.text = upgrade.label
	stat_up_button.disabled = false
	heal_button.text = "Heal (%d HP)" % heal_amount
	heal_button.disabled = false
	
	_character_callable = _on_companion_selected.bind(companion)
	_stat_callable = _on_stat_selected.bind(upgrade)
	_heal_callable = _on_heal_selected.bind(heal_amount)
	
	character_button.pressed.connect(_character_callable)
	stat_up_button.pressed.connect(_stat_callable)
	heal_button.pressed.connect(_heal_callable)

func _on_companion_selected(companion):
	player.companions.append(companion)
	_on_resume()
	_clear_button_signals()

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
	var template = upgrade_templates.pick_random()
	var current_stat_level = player.get_stat_level(template.stat)
	var rarity = _weighted_pick(rarity_weights)

	var base_val = randf_range(template.base_min, template.base_max)
	var rarity_multiplier = 2.0 if rarity == "rare" else 1.0
	var level_multiplier = 1.0 + (current_stat_level * template.scale_per_level)

	var final_val = base_val * rarity_multiplier * level_multiplier
	
	var old_val = _get_current_stat(template.stat)
	var new_val = old_val + final_val
	var display_old = _format_stat(template.stat, old_val)
	var display_new = _format_stat(template.stat, new_val)
	
	var label = "%s (%s → %s)" % [template.label, display_old, display_new]
	if rarity == "rare":
		label = "RARE!!! " + label
	return {
		"stat": template.stat,
		"label": label,
		"rarity": rarity,
		"value": final_val
	}

func _get_current_stat(stat_name: String) -> float:
	match stat_name:
		"damage": return player.damage
		"crit_chance": return player.crit_chance
		"shot_speed": return player.shot_speed
		"shot_range": return player.shot_range
		"max_health": return player.max_health
		"speed": return player.speed
	return 0

func _format_stat(stat_name: String, value: float) -> String:
	match stat_name:
		"crit_chance": return "%d%%" % int(value * 100)
		"damage", "max_health", "shot_speed", "shot_range": return "%d" % int(value)
		"speed": return "%.1f" % value
	return "%s" % value

func _weighted_pick(weights: Dictionary) -> String:
	var total = 0.0
	for key in weights: total += weights[key]
	var roll = randf() * total
	for key in weights:
		roll -= weights[key]
		if roll <= 0: return key
	return weights.keys()[0]

