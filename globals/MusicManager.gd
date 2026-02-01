extends Node

var bgm_player: AudioStreamPlayer

@export var menu_volume_db: float = -15.0
@export var gameplay_volume_db: float = -25.0

func _ready():
	# Configure the audio player
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	var music_resource = load("res://assets/Sounds/Ost main theme + gameplay.ogg")
	if music_resource:
		bgm_player.stream = music_resource
		bgm_player.volume_db = menu_volume_db
		bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
		bgm_player.play()
	else:
		printerr("MusicManager ERROR: Could not load music file assets/Sounds/Ost main theme + gameplay.ogg")

func restart_for_gameplay():
	# Restart music from the beginning at gameplay volume
	bgm_player.stop()
	bgm_player.volume_db = gameplay_volume_db
	bgm_player.play()

func restart_for_menu():
	# Restart music from the beginning at menu volume
	bgm_player.stop()
	bgm_player.volume_db = menu_volume_db
	bgm_player.play()

func play_bgm():
	if bgm_player.stream and not bgm_player.playing:
		bgm_player.play()

func stop_bgm():
	bgm_player.stop()

func set_volume(db: float):
	bgm_player.volume_db = db
