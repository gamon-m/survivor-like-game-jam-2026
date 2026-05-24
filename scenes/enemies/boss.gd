extends CharacterBody2D

enum Phase {ONE, TWO, THREE}
enum BossState {MOVE, ATTACK}
enum CyclePhase {MOVE, PAUSE, BURST}

@export var max_hp = 5000
@export var player_reference: Player
@export var bullet_scene: PackedScene
@export var bullet_damage = 10
@export var bullet_speed = 200
@export var contact_damage = 20

signal health_changed(current, max_hp)

var phase_data = {
	Phase.ONE: {
		"speed": 50,
		"enemy_spawn_delay": 3.0,
		"enemy_count": {"min": 3, "max": 5},
		"enemy_types": ["chaser"],
		"spawn_weights": {"chaser": 10},
		"attacks": ["burst"],
		"burst_shots": 3,
		"burst_delay": 0.5
	},
	Phase.TWO: {
		"speed": 75,
		"enemy_spawn_delay": 3.0,
		"enemy_count": {"min": 4, "max": 6},
		"enemy_types": ["chaser", "tank", "marksman"],
		"spawn_weights": {"chaser": 10, "tank": 2, "marksman": 4},
		"attacks": ["burst", "ring"],
		"burst_shots": 4,
		"burst_delay": 0.4
	},
	Phase.THREE: {
		"speed": 100,
		"enemy_spawn_delay": 2.0,
		"enemy_count": {"min": 5, "max": 7},
		"enemy_types": ["chaser", "tank", "marksman", "swarmer"],
		"spawn_weights": {"chaser": 10, "tank": 2, "marksman": 4, "swarmer": 3},
		"attacks": ["burst", "ring", "single"],
		"burst_shots": 5,
		"burst_delay": 0.3
	}
}

var attack_data = {
	"move_duration": 3.0,
	"pause_duration": 1.0,
	"single_fire_rate": 0.1,
	"single_duration": 1.5,
	"single_speed_mult": 1.5,
	"single_spread": 0.02
}

var hp
var phase
var boss_state
var spawn_timer: Timer

var cycle_phase: CyclePhase
var burst_remaining: int
var pause_target: Callable
var cycle_timer: Timer

var attack_index: int = 0
var rapid_timer: Timer


func _ready() -> void:
	hp = max_hp
	phase = Phase.ONE

	cycle_timer = Timer.new()
	cycle_timer.one_shot = true
	cycle_timer.timeout.connect(_on_cycle_timer_timeout)
	add_child(cycle_timer)
	_enter_move()

	rapid_timer = Timer.new()
	rapid_timer.timeout.connect(_on_rapid_timer_timeout)
	add_child(rapid_timer)

	spawn_timer = Timer.new()
	spawn_timer.wait_time = phase_data[phase]["enemy_spawn_delay"]
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()


func _physics_process(_delta: float) -> void:
	if not player_reference: return

	var direction = global_position.direction_to(player_reference.global_position)

	if boss_state == BossState.MOVE:
		velocity = direction * phase_data[phase]["speed"]
	else:
		velocity = Vector2.ZERO

	if velocity == Vector2.ZERO:
		$AnimationPlayer.play("idle")
	else:
		$AnimationPlayer.play("run")

	$Sprite2D.flip_h = velocity.x < 0

	move_and_slide()

	var targets = $Hitbox.get_overlapping_bodies()
	for target in targets:
		if target is Player:
			target.take_damage(contact_damage)


func take_damage(amount):
	hp -= amount
	health_changed.emit(hp, max_hp)
	$Sprite2D.modulate = Color.RED
	create_tween().tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
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


func _on_cycle_timer_timeout() -> void:
	match cycle_phase:
		CyclePhase.MOVE:
			_enter_pause(_enter_burst)
		CyclePhase.PAUSE:
			pause_target.call()
		CyclePhase.BURST:
			_handle_burst_tick()


func _enter_move():
	cycle_phase = CyclePhase.MOVE
	boss_state = BossState.MOVE
	cycle_timer.start(attack_data["move_duration"])


func _enter_pause(next: Callable):
	cycle_phase = CyclePhase.PAUSE
	pause_target = next
	boss_state = BossState.ATTACK
	velocity = Vector2.ZERO
	cycle_timer.start(attack_data["pause_duration"])


func _fire_current_attack():
	match phase_data[phase]["attacks"][attack_index]:
		"burst":
			fire_spread(3)
		"ring":
			fire_ring(8)


func _enter_burst():
	cycle_phase = CyclePhase.BURST
	var attack = phase_data[phase]["attacks"][attack_index]

	if attack == "single":
		rapid_timer.wait_time = attack_data["single_fire_rate"]
		rapid_timer.start()
		cycle_timer.start(attack_data["single_duration"])
	else:
		burst_remaining = phase_data[phase]["burst_shots"]
		_fire_current_attack()
		burst_remaining -= 1
		cycle_timer.start(phase_data[phase]["burst_delay"])


func _handle_burst_tick():
	var attack = phase_data[phase]["attacks"][attack_index]

	if attack == "single":
		rapid_timer.stop()
		attack_index = (attack_index + 1) % phase_data[phase]["attacks"].size()
		_enter_pause(_enter_move)
		return

	_fire_current_attack()
	burst_remaining -= 1
	if burst_remaining > 0:
		cycle_timer.start(phase_data[phase]["burst_delay"])
	else:
		attack_index = (attack_index + 1) % phase_data[phase]["attacks"].size()
		_enter_pause(_enter_move)


func _on_spawn_timer_timeout() -> void:
	var types = phase_data[phase]["enemy_types"]
	var counts = phase_data[phase]["enemy_count"]
	var count = randi_range(counts["min"], counts["max"])
	for i in range(count):
		var type = _weighted_pick(types, phase_data[phase]["spawn_weights"])
		spawn_enemy(type)


func _update_phase_timers():
	spawn_timer.wait_time = phase_data[phase]["enemy_spawn_delay"]
	spawn_timer.start()
	attack_index = 0


func fire_spread(amount):
	var direction = global_position.direction_to(player_reference.global_position)
	var spread_angle = 0.3
	var start_angle = -spread_angle * (amount - 1) / 2.0
	for i in range(amount):
		var projectile = bullet_scene.instantiate() as Area2D
		projectile.global_position = global_position
		projectile.direction = direction.rotated(start_angle + i * spread_angle)
		projectile.damage = bullet_damage
		projectile.speed = bullet_speed
		projectile.shot_range = 1000
		get_tree().current_scene.add_child(projectile)


func _on_rapid_timer_timeout():
	fire_single()


func fire_single():
	var dir = global_position.direction_to(player_reference.global_position)
	var spread = attack_data["single_spread"]
	var p = bullet_scene.instantiate() as Area2D
	p.global_position = global_position
	p.direction = dir + Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	p.damage = bullet_damage
	p.speed = bullet_speed * attack_data["single_speed_mult"]
	p.shot_range = 1000
	get_tree().current_scene.add_child(p)


func fire_ring(amount):
	var step = TAU / amount
	for i in range(amount):
		var p = bullet_scene.instantiate() as Area2D
		p.global_position = global_position
		p.direction = Vector2.RIGHT.rotated(step * i)
		p.damage = bullet_damage
		p.speed = bullet_speed
		p.shot_range = 1000
		get_tree().current_scene.add_child(p)


func _weighted_pick(types: Array, weights: Dictionary) -> String:
	var total = 0
	for t in types:
		total += weights.get(t, 1)
	var roll = randi() % total
	for t in types:
		roll -= weights.get(t, 1)
		if roll < 0:
			return t
	return types.back()


func spawn_enemy(type):
	var spawner = get_tree().current_scene.get_node("Player/EnemySpawner")
	if not spawner:
		return
	var container = get_tree().current_scene.get_node("EnemiesContainer")
	if not container:
		return
	for config in spawner.enemy_scenes:
		if config.enemy_type == type:
			var enemy = config.scene.instantiate()
			enemy.player_reference = player_reference
			enemy.health_multiplier *= 1.0 + player_reference.xp_level * 0.1
			enemy.loot_scene = null
			var angle = randf_range(0, TAU)
			enemy.global_position = global_position + Vector2(cos(angle), sin(angle)) * randf_range(75, 125)
			container.add_child(enemy)
			return
