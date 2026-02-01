extends Node2D

@onready var cute_map = $CuteMap
@onready var tough_map = $ToughMap
@onready var natural_map = $NaturalMap if has_node("NaturalMap") else null
@onready var cute_tree_map = $CuteTreeMap if has_node("CuteTreeMap") else null
@onready var tough_tree_map = $ToughTreeMap if has_node("ToughTreeMap") else null

@export_group("Level Settings")
@export var level_start_sound: AudioStream
@export var sound_delay: float = 1.0
@export var start_subtitle: String = ""
@export var initial_mode: GameManager.GameMode = GameManager.GameMode.NATURAL
@export var hide_director: bool = false

func _ready():
	# Final polish: Smooth Fade From Black
	# We call this on the TransitionLayer global
	if TransitionLayer.has_method("fade_from_black"):
		TransitionLayer.fade_from_black(1.5)
	
	# Restart music at lower gameplay volume
	if is_instance_valid(MusicManager):
		MusicManager.restart_for_gameplay()
	
	# Hide custom cursor during gameplay
	if is_instance_valid(MouseDisplay):
		MouseDisplay.visible = false
	
	# Delayed sound playback
	if level_start_sound:
		get_tree().create_timer(sound_delay).timeout.connect(_play_level_start_sound)
		
	GameManager.mode_changed.connect(_update_world)
	# Set the initial mode for this level silently
	GameManager.set_mode_silent(initial_mode)
	# Force an update right at the start
	_update_world(GameManager.current_mode)
	
	# Ensure Post-Processing matches level start mode
	if is_instance_valid(PostProcessing) and GameManager:
		# We manually trigger the change to ensure it applies
		PostProcessing._on_game_mode_changed(GameManager.current_mode)
	
	# Apply hide_director setting to HUD
	var hud = get_node_or_null("HUD")
	if hud and "show_director" in hud:
		hud.show_director = not hide_director
		# Force refresh HUD mode to apply the visibility change
		if hud.has_method("_on_mode_changed"):
			hud._on_mode_changed(GameManager.current_mode)

func _play_level_start_sound():
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.stream = level_start_sound
	audio_player.volume_db = -8.0
	audio_player.play()
	
	if start_subtitle != "":
		GameManager.trigger_subtitle(start_subtitle)
	# Clean up after playing
	audio_player.finished.connect(audio_player.queue_free)

func _update_world(mode):
	# Visibility helper
	if cute_map: 
		cute_map.visible = (mode == GameManager.GameMode.CUTE)
		cute_map.collision_enabled = (mode == GameManager.GameMode.CUTE)
	
	if cute_tree_map:
		cute_tree_map.visible = (mode == GameManager.GameMode.CUTE)
		cute_tree_map.collision_enabled = (mode == GameManager.GameMode.CUTE)
	
	if tough_map:
		tough_map.visible = (mode == GameManager.GameMode.TOUGH)
		tough_map.collision_enabled = (mode == GameManager.GameMode.TOUGH)
		
	if tough_tree_map:
		tough_tree_map.visible = (mode == GameManager.GameMode.TOUGH)
		tough_tree_map.collision_enabled = (mode == GameManager.GameMode.TOUGH)
		
	if natural_map:
		natural_map.visible = (mode == GameManager.GameMode.NATURAL)
		natural_map.collision_enabled = (mode == GameManager.GameMode.NATURAL)
