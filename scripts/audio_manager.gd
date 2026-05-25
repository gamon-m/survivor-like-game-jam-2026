extends Node

var sfx_map: Dictionary = {}
var audio_players: Array[AudioStreamPlayer2D] = []
var last_played: Dictionary = {}
const POOL_SIZE = 10
const COOLDOWN = 0.1

var bgm_player: AudioStreamPlayer
var music_volume_db: float = -20.0
var _music_loops: bool = false

var master_volume: float = 1.0:
	set(v):
		master_volume = v
		var bus_idx = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(v))
		_save_config()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	bgm_player = AudioStreamPlayer.new()
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.volume_db = music_volume_db
	bgm_player.finished.connect(_on_music_finished)
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

	_load_config()

func _load_config():
	var cfg = ConfigFile.new()
	var err = cfg.load("user://settings.cfg")
	if err == OK:
		var v = cfg.get_value("audio", "master_volume", 1.0)
		master_volume = v
	else:
		master_volume = 1.0

func _save_config():
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save("user://settings.cfg")

func set_master_volume(value: float):
	master_volume = value

func play_music(key: String, volume_db: float = music_volume_db):
	_music_loops = key != "victory"
	var path: String
	match key:
		"title":
			path = "res://assets/music/xDeviruchi - Title Theme (Loop).wav"
		"main":
			path = "res://assets/music/xDeviruchi - Mysterious Dungeon.wav"
		"boss":
			path = "res://assets/music/xDeviruchi - Decisive Battle (Loop).wav"
		"victory":
			path = "res://assets/music/xDeviruchi - Decisive Battle (End).wav"
		_:
			return
	var stream = load(path)
	if stream is AudioStreamWAV and key == "title":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = 5318460
	bgm_player.stream = stream
	bgm_player.volume_db = volume_db
	bgm_player.play()

func _on_music_finished():
	if _music_loops:
		bgm_player.play()

func stop_music():
	bgm_player.stop()
	_music_loops = false

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
