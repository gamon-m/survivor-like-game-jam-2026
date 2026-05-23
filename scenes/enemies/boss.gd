extends CharacterBody2D

enum Phase {ONE, TWO, THREE}

@export var max_hp = 1000
@export var player_reference: Player

var phase_date = {
	Phase.ONE: {
		"speed": 50, "attack_delay": 1.5, "enemy_spawn_delay": 3.0, "enemy_count": {"min": 3, "max": 5}, "enemy_types": ["chaser"]
	},
	Phase.TWO: {
		"speed": 75, "attack_delay": 1.0, "enemy_spawn_delay": 3.0, "enemy_count": {"min": 4, "max": 6}, "enemy_types": ["chaser", "tank", "marksman"]
	},
	Phase.THREE: {
		"speed": 100, "attack_delay": 0.5, "enemy_spawn_delay": 2.0, "enemy_count": {"min": 5, "max": 7}, "enemy_types": ["chaser", "tank", "marksman", "swarmer"]
	}
}

var hp
var phase
var attack_timer: Timer
var spawn_timer: Timer

func _ready() -> void:
	hp = max_hp
	phase = Phase.ONE

	attack_timer = Timer.new()
	attack_timer.wait_time = phase_date[phase]["attack_delay"]
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	add_child(attack_timer)
	attack_timer.start()

	spawn_timer = Timer.new()
	spawn_timer.wait_time = phase_date[phase]["enemy_spawn_delay"]
	spawn_timer.connect("timeout", _on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _physics_process(_delta: float) -> void:
	if not player_reference: return

	var direction = global_position.direction_to(player_reference.global_position)
	velocity = direction * phase_date[phase]["speed"] 

	$AnimationPlayer.play("run")
	$Sprite2D.flip_h = velocity.x < 0
	move_and_slide()

func take_damage(amount):
	hp -= amount
	if hp <= 0:
		die()
		return

	var old_phase = phase
	
	if phase == Phase.ONE and hp < max_hp * 0.6:
		phase = Phase.TWO
	elif phase == Phase.TWO and hp < max_hp * 0.3:
		phase = Phase.THREE
	
	if phase != old_phase:
		_update_phase_timers()


func die():
	queue_free()

func _on_attack_timer_timeout() -> void:
	match phase:
		Phase.ONE:
			fire_spread(3)
		Phase.TWO:
			fire_ring(8)
		Phase.THREE:
			fire_single()

func _on_spawn_timer_timeout() -> void:
	var types = phase_date[phase]["enemy_types"]
	var counts = phase_date[phase]["enemy_count"]
	var count = randi_range(counts["min"], counts["max"])
	for i in range(count):
		var type = types.pick_random()
		spawn_enemy(type)

func _update_phase_timers():
	attack_timer.wait_time = phase_date[phase]["attack_delay"]
	spawn_timer.wait_time = phase_date[phase]["enemy_spawn_delay"]
	spawn_timer.start()
	attack_timer.start()


func fire_spread(amount):
	pass

func fire_single():
	pass

func fire_ring(amount):
	pass

func spawn_enemy(type):
	pass