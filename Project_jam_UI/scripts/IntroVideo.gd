extends Control

@onready var video_player = $AspectRatioContainer/VideoStreamPlayer

var can_skip = false

func _ready():
	# Allow skipping only after a short delay to prevent accidental skips from the menu click
	get_tree().create_timer(1.0).timeout.connect(func(): can_skip = true)
	
	# Safety timeout: if video doesn't end in 15 seconds, move on anyway
	get_tree().create_timer(15.0).timeout.connect(_transition_to_level0)
	
	# Ensure the video starts playing
	if video_player.stream:
		if is_instance_valid(MusicManager):
			MusicManager.stop_bgm()
		print("Attempting to play video: ", video_player.stream.resource_path)
		video_player.play()
		# If it's still not playing after a tiny delay, it might be a codec failure
		get_tree().create_timer(0.5).timeout.connect(func():
			if not video_player.is_playing():
				print("VIDEO ERROR: Failed to start playback. Skipping...")
				_transition_to_level0()
		)
	else:
		print("VIDEO ERROR: No video stream found. Skipping...")
		_transition_to_level0()
		
	video_player.finished.connect(_on_video_finished)

func _input(event):
	if not can_skip:
		return
		
	# Allow skipping with Space, Enter or Escape
	if event is InputEventKey and event.is_pressed():
		_transition_to_level0()
	if event is InputEventMouseButton and event.is_pressed():
		_transition_to_level0()

func _on_video_finished():
	_transition_to_level0()

func _transition_to_level0():
	# Ensure we only transition once
	if get_tree().current_scene.name == "IntroVideo":
		get_tree().change_scene_to_file("res://Level0.tscn")
