extends Node

var sfx_map: Dictionary = {}
var audio_players: Array[AudioStreamPlayer2D] = []
const POOL_SIZE = 10

func _ready():
	sfx_map["shoot"] = preload("res://assets/sfx/shoot.wav")
	sfx_map["hurt"] = preload("res://assets/sfx/hurt.wav")
	sfx_map["die"] = preload("res://assets/sfx/die.wav")
	sfx_map["enemy_die"] = preload("res://assets/sfx/enemy-die.wav")
	sfx_map["explosion"] = preload("res://assets/sfx/Explosion.wav")
	sfx_map["xp"] = preload("res://assets/sfx/xp.wav")
	sfx_map["level_up"] = preload("res://assets/sfx/level-up.wav")
	sfx_map["game_over"] = preload("res://assets/sfx/game-over.wav")

	for i in POOL_SIZE:
		var player = AudioStreamPlayer2D.new()
		add_child(player)
		audio_players.append(player)

func play_sfx(name: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0):
	if not sfx_map.has(name):
		return
	for player in audio_players:
		if not player.playing:
			player.stream = sfx_map[name]
			player.global_position = position
			player.volume_db = volume_db
			player.play()
			return
