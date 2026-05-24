class_name Player

extends CharacterBody2D

signal xp_gained(growth_data)
signal leveled_up
signal died
signal health_changed(current, max)


@export var speed = 100
@export var health = 100
@export var max_health = 100
@export var damage = 10
@export var crit_chance = 0.0
@export var shot_delay = 1.0
@export var shot_range = 75

var xp = 0
var xp_level = 0
var xp_required = 10

var stat_levels = {
	"damage": 0,
	"crit_chance": 0,
	"shot_delay": 0,
	"shot_range": 0,
	"max_health": 0,
	"speed": 0
}

var companions: Array[BaseCompanion] = []

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if direction:
		$AnimationPlayer.play("run")
		if velocity.x < 0:
			$Sprite2D.flip_h = true
		elif velocity.x > 0:
			$Sprite2D.flip_h = false
	else:
		$AnimationPlayer.play("idle")

func _on_damage_timer_timeout():
	for body in $Hitbox.get_overlapping_bodies():
		if "contact_damage" in body:
			take_damage(body.contact_damage)
			break

func take_damage(amount):
	if $DamageTimer.time_left > 0:
		return

	health -= amount
	health_changed.emit(health, max_health)

	$DamageTimer.start()

	if health <= 0:
		health = 0
		died.emit()
		$CollisionShape2D.set_deferred("disabled", true)
		hide()
		get_tree().paused = true

func gain_xp(amount):
	xp += amount
	xp_gained.emit(xp, xp_required)
	if xp >= xp_required:
		xp -= xp_required
		level_up()


func level_up():
	xp_level += 1
	xp_required = int(xp_required * 1.3)
	leveled_up.emit()

func apply_stat(stat_name: String, value: float) -> void:
	match stat_name:
		"damage":
			damage += int(value)
		"crit_chance":
			crit_chance += value
		"shot_delay":
			shot_delay = max(shot_delay - value, 0.2)
			$Holster/Timer.wait_time = shot_delay
		"shot_range":
			shot_range = min(shot_range + value, 200)
			$Holster/RangeFinder/Range.shape.radius = shot_range
		"max_health":
			max_health += int(value)
			health += int(value)
			health_changed.emit(health, max_health)
		"speed":
			speed += int(value)

	stat_levels[stat_name] += 1

func get_stat_level(stat_name: String) -> int:
	return stat_levels.get(stat_name, 0)

func heal(amount):
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func add_companion(companion: BaseCompanion):
	companions.append(companion)
	_update_companion_chain()

func replace_companion(index, companion: BaseCompanion):
	companions[index] = companion
	_update_companion_chain()

func _update_companion_chain():
	for i in range(companions.size()):
		if i == 0 or companions[i].type.to_lower() == "meatshield":
			companions[i].follow_target = self
		else:
			companions[i].follow_target = _find_previous(i - 1)

func _find_previous(index: int):
	if index < 0:
		return self
	if companions[index].type.to_lower() == "meatshield":
		return _find_previous(index - 1)
	return companions[index]
