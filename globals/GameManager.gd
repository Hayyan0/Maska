extends Node

var player: Node2D

# Signal is like an Event Dispatcher in UE.
# Other objects will "Bind" (Connect) to this.
signal mode_changed(new_mode)
signal health_changed(current_health, max_health)
signal player_respawned(position)
signal game_over
signal director_updated(director_name, expression)
signal subtitle_triggered(text: String, duration: float)

enum GameMode {
	CUTE,
	TOUGH,
	NATURAL
}

# Current state variable
var current_mode: GameMode = GameMode.NATURAL

# Health System
var max_health: int = 3
var health: int = 3
var last_safe_position: Vector2 = Vector2.ZERO
var return_scene: String = "res://Project_jam_UI/scenes/main_menu.tscn"

# Director State
var current_director: String = "Jumana"
var current_expression: String = "Normal"

# Trigger Audio Queue
var trigger_audio_player: AudioStreamPlayer
var trigger_audio_queue: Array = [] # [{stream, volume, subtitle}]
var is_trigger_playing: bool = false

func _ready():
	reset_health()
	_setup_trigger_audio()

func _setup_trigger_audio():
	trigger_audio_player = AudioStreamPlayer.new()
	trigger_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(trigger_audio_player)
	trigger_audio_player.finished.connect(_on_trigger_audio_finished)

func toggle_mode():
	match current_mode:
		GameMode.NATURAL:
			change_mode(GameMode.CUTE)
		GameMode.CUTE:
			change_mode(GameMode.TOUGH)
		GameMode.TOUGH:
			change_mode(GameMode.CUTE)

func change_mode(mode: GameMode, silent: bool = false):
	# Update logic state immediately
	current_mode = mode
	mode_changed.emit(current_mode)
	
	# Trigger visual transition unless silent
	if not silent:
		TransitionLayer.start_transition()

func set_mode_silent(mode: GameMode):
	change_mode(mode, true)

func transition_to_level(path: String):
	TransitionLayer.start_transition()
	# Wait for transition to cover screen (DURATION is 1.0, wait 0.5-0.8)
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file(path)
	reset_health()

# --- Health Logic ---
func reset_health():
	health = max_health
	health_changed.emit(health, max_health)

func set_safe_position(pos: Vector2):
	if pos.distance_squared_to(last_safe_position) > 100: # Only log significant changes
		print("SAFE POS UPDATED: ", pos)
	last_safe_position = pos

func take_damage(amount: int = 1):
	if health <= 0: return

	health -= amount
	health_changed.emit(health, max_health)
	
	# Global Death Check
	if health <= 0:
		# We don't call die() here anymore. 
		# The player.gd will detect health <= 0 and play the animation, 
		# then call die() when finished.
		return
	
	if current_mode == GameMode.CUTE:
		# Respawn Logic
		respawn_player()
	elif current_mode == GameMode.TOUGH:
		# No respawn, check for death (already handled above)
		pass

func respawn_player():
	if is_instance_valid(player):
		# Respawn slightly higher to prevent floor clipping/falling
		var respawn_pos = last_safe_position + Vector2(0, -60)
		player.global_position = respawn_pos
		player.velocity = Vector2.ZERO
		print("RESPAWN: Sending player to ", respawn_pos, " (Safe Pos: ", last_safe_position, ")")
		
		# Force Camera Snap
		var cam = player.get_node_or_null("Camera2D")
		if cam and cam.has_method("force_update_position"):
			cam.force_update_position()
			
		player_respawned.emit(last_safe_position)

func die():
	print("GAMEMANAGER: Die() called! Emitting game_over...")
	game_over.emit()

func update_director(director: String, expression: String):
	current_director = director
	current_expression = expression
	director_updated.emit(director, expression)

func trigger_subtitle(text: String, duration: float = 4.0):
	subtitle_triggered.emit(text, duration)

func trigger_glitch(duration: float):
	if is_instance_valid(PostProcessing):
		PostProcessing.trigger_glitch(duration)

func queue_trigger_sound(stream: AudioStream, volume: float, subtitle: String):
	trigger_audio_queue.append({"stream": stream, "volume": volume, "subtitle": subtitle})
	_process_trigger_queue()

func _process_trigger_queue():
	if is_trigger_playing or trigger_audio_queue.is_empty():
		return
	
	var item = trigger_audio_queue.pop_front()
	is_trigger_playing = true
	trigger_audio_player.stream = item.stream
	# Apply -6.0dB global reduction to dialogue/trigger sounds
	trigger_audio_player.volume_db = item.volume - 6.0
	trigger_audio_player.play()
	
	if item.subtitle != "":
		var dur = 4.0
		if item.stream:
			dur = item.stream.get_length()
		trigger_subtitle(item.subtitle, dur)

func _on_trigger_audio_finished():
	is_trigger_playing = false
	_process_trigger_queue()
