extends CharacterBody2D

enum Phase {ONE, TWO, THREE}
enum BossState {MOVE, ATTACK}

@export var max_hp = 1000
@export var player_reference: Player
@export var bullet_scene: PackedScene
@export var bullet_damage = 10
@export var bullet_speed = 100

var phase_data = {
	Phase.ONE: {
		"speed": 50, 
		"attack_delay": 1.5, 
		"enemy_spawn_delay": 3.0, 
		"enemy_count": {"min": 3, "max": 5}, 
		"enemy_types": ["chaser"], 		
	},
	Phase.TWO: {
		"speed": 75, 
		"attack_delay": 1.0, 
		"enemy_spawn_delay": 3.0, 
		"enemy_count": {"min": 4, "max": 6}, 
		"enemy_types": ["chaser", "tank", "marksman"]
	},
	Phase.THREE: {
		"speed": 100, 
		"attack_delay": 0.5, 
		"enemy_spawn_delay": 2.0, 
		"enemy_count": {"min": 5, "max": 7}, 
		"enemy_types": ["chaser", "tank", "marksman", "swarmer"]
	}
}

var attack_data = {
	"spread":{
		"move_duration": 5.0,
		"attack_duration": 2.5,
		"shots_per_attack": 3,
		"burst_delay": 0.3,
		"burst_start_delay": 1.0
	}
}

var hp
var phase
var boss_state
var attack_timer: Timer
var spawn_timer: Timer
var shots_remaining
var phase_timer: Timer

func _ready() -> void:
	hp = max_hp
	phase = Phase.ONE

	attack_timer = Timer.new()
	attack_timer.wait_time = phase_data[phase]["attack_delay"]
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	add_child(attack_timer)

	phase_timer = Timer.new()
	phase_timer.one_shot = true
	phase_timer.connect("timeout", _on_phase_timer_timeout)
	add_child(phase_timer)
	phase_timer.start()

	spawn_timer = Timer.new()
	spawn_timer.wait_time = phase_data[phase]["enemy_spawn_delay"]
	spawn_timer.connect("timeout", _on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

	_enter_move_state()

func _physics_process(_delta: float) -> void:
	if not player_reference: return

	var direction = global_position.direction_to(player_reference.global_position)

	if boss_state == BossState.MOVE:
		velocity = direction * phase_data[phase]["speed"] 
	elif boss_state == BossState.ATTACK:
		velocity = Vector2.ZERO

	if velocity == Vector2.ZERO:
		$AnimationPlayer.play("idle")
	else:
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
	if boss_state != BossState.ATTACK:
		return
	match phase:
		Phase.ONE:
			fire_spread(3)
		Phase.TWO:
			fire_ring(8)
		Phase.THREE:
			fire_single()

func _on_spawn_timer_timeout() -> void:
	var types = phase_data[phase]["enemy_types"]
	var counts = phase_data[phase]["enemy_count"]
	var count = randi_range(counts["min"], counts["max"])
	for i in range(count):
		var type = types.pick_random()
		spawn_enemy(type)

func _update_phase_timers():
	attack_timer.wait_time = phase_data[phase]["attack_delay"]
	spawn_timer.wait_time = phase_data[phase]["enemy_spawn_delay"]
	spawn_timer.start()
	attack_timer.start()

func _on_phase_timer_timeout() -> void:
	if boss_state == BossState.MOVE:
		_enter_attack_state()
	elif boss_state == BossState.ATTACK:
		_enter_move_state()

func _enter_move_state():
	boss_state = BossState.MOVE
	attack_timer.stop()
	phase_timer.wait_time = attack_data["spread"]["move_duration"]
	phase_timer.start()

func _enter_attack_state():
	boss_state = BossState.ATTACK
	var data = attack_data["spread"]
	shots_remaining = data["shots_per_attack"]
	get_tree().create_timer(data["burst_start_delay"]).timeout.connect(_fire_burst.bind(data))
	phase_timer.wait_time = data["attack_duration"]
	phase_timer.start()

func _fire_burst(data):
	fire_spread(3)
	shots_remaining -= 1
	if shots_remaining > 0:
		get_tree().create_timer(data["burst_delay"]).timeout.connect(_fire_burst.bind(data))
	else:
		_enter_move_state()

func fire_spread(amount):
	var direction = global_position.direction_to(player_reference.global_position)
	var spread_angle = 0.3
	var start_angle = -spread_angle * (amount - 1) / 2.0
	for i in range(amount):
		var projectile = bullet_scene.instantiate() as Area2D
		projectile.global_position = global_position
		projectile.direction = direction.rotated(start_angle + i * spread_angle)
		projectile.damage = bullet_damage
		projectile.speed = 150
		projectile.shot_range = 1000
		get_tree().current_scene.add_child(projectile)

func fire_single():
	pass

func fire_ring(amount):
	pass

func spawn_enemy(type):
	pass
