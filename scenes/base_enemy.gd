extends CharacterBody2D

@export var speed = 100.0
@export var player_reference : CharacterBody2D
@export var loot_scene: PackedScene
@export var enemy_type: String


@export var base_health = 10
@export var health_multiplier = 1.0
@export var xp_multiplier = 1
@export var contact_damage = 10
var health: int

func _ready():
	health = int(max(1, base_health * health_multiplier))

func _physics_process(_delta: float) -> void:
	if !player_reference:
		return

	var direction = global_position.direction_to(player_reference.global_position)
	velocity = direction * speed

	$AnimationPlayer.play("run")
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false

	move_and_slide()

	var targets = $Hitbox.get_overlapping_bodies()
	for target in targets:
		if target is Player:
			target.take_damage(contact_damage)			

func take_damage(damage):
	health -= damage
	if health <= 0:
		queue_free()
		var xp_gem = loot_scene.instantiate() as Area2D
		xp_gem.global_position = global_position
		xp_gem.xp_amount = xp_gem.xp_amount * xp_multiplier
		get_tree().current_scene.call_deferred("add_child", xp_gem)

