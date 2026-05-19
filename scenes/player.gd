class_name Player

extends CharacterBody2D

signal xp_gained(growth_data)
signal leveled_up
signal died
signal health_changed(current, max)


@export var speed = 150.0
@export var health = 100
@export var max_health = 100
@export var damage = 10
@export var crit_chance = 0.0
@export var shot_speed = 1
@export var shot_range = 50
@export var damage_cooldown = 1.0

var xp = 0
var xp_level = 0
var xp_required = 10

var stat_levels = {
	"damage": 0,
	"crit_chance": 0,
	"shot_speed": 0,
	"shot_range": 0,
	"max_health": 0,
	"speed": 0
}

var _damage_timer = 0.0
var companions = []


func _physics_process(delta: float) -> void:	
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

	_damage_timer = max(0, _damage_timer - delta)

func take_damage(amount):
	if _damage_timer > 0:
		return
	health -= amount
	_damage_timer = damage_cooldown
	health_changed.emit(health, max_health)
	if health <= 0:
		health = 0
		died.emit()
		set_physics_process(false)
		$Sprite2D.visible = false
		$Hitbox.monitorable = false

func gain_xp(amount):
	xp += amount
	xp_gained.emit(xp, xp_required)
	if xp >= xp_required:
		xp -= xp_required
		level_up()


func level_up():
	xp_level += 1
	xp_required = int(xp_required * 1.5)
	leveled_up.emit()

func apply_stat(stat_name: String, value: float) -> void:
	match stat_name:
		"damage":
			damage += int(value)
		"crit_chance":
			crit_chance += value
		"shot_speed":
			shot_speed += int(value)
		"shot_range":
			shot_range += int(value)
		"max_health":
			max_health += int(value)
			health += int(value)
			health_changed.emit(health, max_health)
		"speed":
			speed += value

	stat_levels[stat_name] += 1
	print("applied stat %s" % stat_name + " with value %s" % value)

func get_stat_level(stat_name: String) -> int:
	return stat_levels.get(stat_name, 0)

func _on_hitbox_body_entered(body):
	print("Player hitbox entered by: ", body.name, " has contact_damage: ", "contact_damage" in body)
	if body.has_method("take_damage"):
		return
	if "contact_damage" in body:
		take_damage(body.contact_damage)

func heal(amount):
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)