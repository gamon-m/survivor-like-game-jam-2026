extends Node

var sfx_map: Dictionary = {}
var audio_players: Array[AudioStreamPlayer2D] = []
var last_played: Dictionary = {}
const POOL_SIZE = 10
const COOLDOWN = 0.1

var bgm_player: AudioStreamPlayer
var music_volume_db: float = -20.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	bgm_player = AudioStreamPlayer.new()
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.volume_db = music_volume_db
	add_child(bgm_player)

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

func play_music(key: String, volume_db: float = music_volume_db):
	var path: String
	match key:
		"main":
			path = "res://assets/music/xDeviruchi - Mysterious Dungeon.wav"
		"boss":
			path = "res://assets/music/xDeviruchi - Decisive Battle (Loop).wav"
		"victory":
			path = "res://assets/music/xDeviruchi - Decisive Battle (End).wav"
		_:
			return
	bgm_player.stream = load(path)
	bgm_player.volume_db = volume_db
	bgm_player.play()

func stop_music():
	bgm_player.stop()

func play_sfx(name: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0):
	if not sfx_map.has(name):
		return
	if Time.get_ticks_msec() - last_played.get(name, 0) < COOLDOWN * 1000:
		return
	last_played[name] = Time.get_ticks_msec()
	for player in audio_players:
		if not player.playing:
			player.stream = sfx_map[name]
			player.global_position = position
			player.volume_db = volume_db
			player.play()
			return
