@tool
extends Area2D

enum TriggerType {
	CHANGE_STYLE,
	PLAY_SOUND,
	SOUND_AND_CHANGE,
	CAMERA_CONTROL,
	SIGNAL_ONLY,
	LEVEL_END,
	SEQUENCE
}

@export_category("Trigger Configuration")
@export var type: TriggerType = TriggerType.CHANGE_STYLE:
	set(val):
		type = val
		notify_property_list_changed()
		_update_visuals()



@export_category("Activation Rules")
@export var always_active: bool = false:
	set(val):
		always_active = val
		_update_visuals()
@export var active_in_mode: GameManager.GameMode = GameManager.GameMode.NATURAL:
	set(val):
		active_in_mode = val
		_update_visuals()
@export var appearance_delay: float = 0.0 # Wait before appearing in world


@export_group("Mode Style Settings")
@export var target_mode: GameManager.GameMode = GameManager.GameMode.TOUGH:
	set(val):
		target_mode = val
		_update_visuals()
@export var switch_delay: float = 0.0 # Only used if Sound+Change

@export_group("Camera Settings")
@export var camera_lock: bool = true # Only used if type is CAMERA_CONTROL

@export_group("Visual Settings")
@export var cute_texture: Texture2D:
	set(val):
		cute_texture = val
		_update_visuals()
@export var tough_texture: Texture2D:
	set(val):
		tough_texture = val
		_update_visuals()

@export_file("*.tscn") var next_scene: String
@export var loading_image: Texture2D

@export_group("Audio Settings")
@export var audio_clip: AudioStream
@export var volume_db: float = -6.0
@export_multiline var subtitle_text: String = ""

@export_group("Sequence Settings")
@export var stop_player_during_sequence: bool = true
@export var sequence_steps: Array[SequenceStep] = []
@export var cinematic_boss_transition: bool = false

@export var affected_by_gravity: bool = false
@export var gravity_scale: float = 1.0

@export_group("Director Settings")
@export var director_expression: String = "Normal"

@export_group("Chaining")
@export var wait_for_signal: bool = false:
	set(val):
		wait_for_signal = val
		_update_visuals()
@export var signal_targets: Array[Node2D] = []

@onready var audio_player = $AudioStreamPlayer
@onready var sprite = $Sprite2D

var has_triggered = false
var velocity = Vector2.ZERO
var is_falling = false
var is_waiting = false

func _validate_property(property: Dictionary):
	# Hide Style settings
	if property.name in ["target_mode", "switch_delay", "cute_texture", "tough_texture"]:
		if type != TriggerType.CHANGE_STYLE and type != TriggerType.SOUND_AND_CHANGE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
	# Hide Sound settings
	if property.name in ["audio_clip", "volume_db"]:
		if type != TriggerType.PLAY_SOUND and type != TriggerType.SOUND_AND_CHANGE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
	if property.name == "subtitle_text":
		if type != TriggerType.PLAY_SOUND and type != TriggerType.SOUND_AND_CHANGE and type != TriggerType.SEQUENCE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
			
	# Hide Camera settings
	if property.name == "camera_lock":
		if type != TriggerType.CAMERA_CONTROL:
			property.usage = PROPERTY_USAGE_NO_EDITOR
			
	# Hide Level End settings
	if property.name in ["next_scene", "loading_image"]:
		if type != TriggerType.LEVEL_END:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
	# Hide Sequence settings
	if property.name in ["stop_player_during_sequence", "sequence_steps", "cinematic_boss_transition"]:
		if type != TriggerType.SEQUENCE:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
	# Director expression dropdown logic
	if property.name == "director_expression":
		var expressions = ""
		# We need to know which director to show expressions for.
		# If it's a CHANGE_STYLE, we show for target_mode's director.
		# Otherwise we might not know, so we'll show a combined list or just common ones.
		# Let's show all available for both just to be safe.
		expressions = "Normal,Happy,Happy2,Evil,Talking,Angry,Thinking,Explains"
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = expressions

func _ready():
	if wait_for_signal and not Engine.is_editor_hint():
		is_waiting = true
		monitoring = false
		visible = false
	else:
		# If there's an appearance delay, hide initially
		if appearance_delay > 0.0 and not Engine.is_editor_hint():
			monitoring = false
			visible = false # Hide the whole trigger
			get_tree().create_timer(appearance_delay).timeout.connect(_appear)
		else:
			_appear() # Still run appear logic to handle gravity start
	
	if Engine.is_editor_hint():
		return
		
	# Connect to mode changes to update visibility at runtime
	if not GameManager.mode_changed.is_connected(_on_mode_changed):
		GameManager.mode_changed.connect(_on_mode_changed)
	
	# Ensure AudioPlayer exists (auto-create if missing in scene for backward compat)
	if not audio_player and (type != TriggerType.CHANGE_STYLE):
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	
	# Fix masks if needed via code? No, handled in scene.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	if is_falling:
		velocity.y += 980.0 * gravity_scale * delta
		var movement = velocity * delta
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + movement)
		query.collision_mask = 1 # World layer
		
		var result = space_state.intersect_ray(query)
		if result:
			global_position = result.position
			is_falling = false
			velocity = Vector2.ZERO
		else:
			global_position += movement

func _on_body_entered(body):
	if has_triggered or is_waiting:
		return
		
	var is_player = (body == GameManager.player) or (body.name == "Player")
	
	if is_player:
		var current = GameManager.current_mode
		
		if not always_active:
			if current != active_in_mode:
				print("COLLISION: Trigger skipped (wrong mode: ", GameManager.GameMode.keys()[current], ")")
				return
		
		# Bypass switch check for SIGNAL_ONLY or PLAY_SOUND
		if type == TriggerType.CHANGE_STYLE or type == TriggerType.SOUND_AND_CHANGE:
			var should_execute = false
			if target_mode == GameManager.GameMode.TOUGH:
				if current != GameManager.GameMode.TOUGH:
					should_execute = true
			elif target_mode == GameManager.GameMode.CUTE:
				if current != GameManager.GameMode.CUTE:
					should_execute = true
			
			if not should_execute:
				# If we have signal targets, we still want to fire those even if we don't change style
				if signal_targets.is_empty():
					return
		
		# execute
		has_triggered = true
		execute_trigger()
		_update_visuals()

func execute_trigger():
	print("CHAINING: Activator '", name, "' triggered!")
	
	# Activate targets if chained
	for target in signal_targets:
		if target and target.has_method("receive_activation_signal"):
			print("CHAINING: Signaling target '", target.name, "'")
			target.receive_activation_signal()
	
	match type:
		TriggerType.CHANGE_STYLE:
			GameManager.change_mode(target_mode)
			
		TriggerType.PLAY_SOUND:
			play_sound()
			
		TriggerType.SOUND_AND_CHANGE:
			play_sound()
			if switch_delay > 0.0:
				await get_tree().create_timer(switch_delay).timeout
			GameManager.change_mode(target_mode)
			
		TriggerType.CAMERA_CONTROL:
			var camera = GameManager.player.get_node_or_null("Camera2D")
			if camera:
				camera.is_centered = camera_lock
				print("Camera Center Mode: ", camera_lock)
		
		TriggerType.SIGNAL_ONLY:
			pass
			
		TriggerType.LEVEL_END:
			if next_scene != "":
				if is_instance_valid(GameManager.player):
					GameManager.player.input_enabled = false
				TransitionLayer.full_transition_to_level(next_scene, loading_image)
		
		TriggerType.SEQUENCE:
			await run_sequence()
	
	
	# Always update director expression if not LEVEL_END or SEQUENCE
	if type != TriggerType.LEVEL_END and type != TriggerType.SEQUENCE:
		var dir = ""
		if type == TriggerType.CHANGE_STYLE or type == TriggerType.SOUND_AND_CHANGE:
			dir = "Jumana" if target_mode == GameManager.GameMode.CUTE else "Luay"
		else:
			dir = GameManager.current_director
		
		GameManager.update_director(dir, director_expression)

func receive_activation_signal():
	if not is_waiting: return
	is_waiting = false
	
	print("Trigger received signal! Starting delay: ", appearance_delay)
	
	if appearance_delay > 0.0:
		get_tree().create_timer(appearance_delay).timeout.connect(_appear)
	else:
		_appear()

func play_sound():
	if audio_clip:
		# Queue through GameManager to prevent overlaps
		GameManager.queue_trigger_sound(audio_clip, volume_db, subtitle_text)

func run_sequence():
	if is_instance_valid(GameManager.player) and stop_player_during_sequence:
		GameManager.player.input_enabled = false
	
	for i in range(sequence_steps.size()):
		var step = sequence_steps[i]
		if not step: continue
		var is_last = (i == sequence_steps.size() - 1)
		
		# Change Mode if requested
		if step.change_mode:
			GameManager.change_mode(step.target_mode)
		
		# Update Director
		var dir = GameManager.current_director
		if step.change_mode:
			dir = "Jumana" if step.target_mode == GameManager.GameMode.CUTE else "Luay"
		
		GameManager.update_director(dir, step.director_expression)
		
		print("[Sequence] Running step ", i+1, "/", sequence_steps.size(), " BossTransition: ", cinematic_boss_transition, " Last: ", is_last)
		
		# Handle Audio/Sequence
		if cinematic_boss_transition and is_last and step.audio_clip:
			var dur = step.audio_clip.get_length()
			print("[Sequence] Boss Transition Step started. Audio duration: ", dur)
			# Start step in background
			if not step.events.is_empty():
				run_step_with_events(step)
			else:
				GameManager.queue_trigger_sound(step.audio_clip, step.volume_db, step.subtitle_text)
					
			if dur > 5.1:
				print("[Sequence] Waiting for glitch sync at ", dur - 5.0)
				# Transition timing
				await get_tree().create_timer(dur - 5.0).timeout
				print("[Sequence] Triggering Glitch (5s to cover transition fade)")
				GameManager.trigger_glitch(5.0) # Increased to overlap fade
				# Wait 4.2s (glitch is 5s, transition fade is 0.8s)
				await get_tree().create_timer(4.2).timeout
				print("[Sequence] Switching to BossFight.tscn")
				TransitionLayer.full_transition_to_level("res://BossFight.tscn")
				return
			else:
				print("[Sequence] Audio too short for cinematic sync, immediate transition after play.")
				# Fallback if audio is short: wait for it and then transition
				await get_tree().create_timer(max(0.1, dur)).timeout
				TransitionLayer.full_transition_to_level("res://BossFight.tscn")
				return
		
		# Normal step logic (not boss transition)
		if step.audio_clip:
			if not step.events.is_empty():
				await run_step_with_events(step)
			else:
				# Simple audio step
				GameManager.queue_trigger_sound(step.audio_clip, step.volume_db, step.subtitle_text)
				await get_tree().process_frame
				while GameManager.is_trigger_playing or not GameManager.trigger_audio_queue.is_empty():
					await get_tree().process_frame
		else:
			# If no audio, still show subtitle if present
			if step.subtitle_text != "":
				var dur = 4.0
				GameManager.trigger_subtitle(step.subtitle_text, dur)
				await get_tree().create_timer(dur).timeout
		
		# Delay after step
		if step.delay_after > 0:
			await get_tree().create_timer(step.delay_after).timeout
			
	if is_instance_valid(GameManager.player):
		GameManager.player.input_enabled = true

func run_step_with_events(step: SequenceStep):
	# Play Audio via GameManager
	# We want to use the GameManager player directly or via a specific method
	# Let's add a way to get the player or just use it.
	var ap = GameManager.trigger_audio_player
	ap.stream = step.audio_clip
	ap.volume_db = step.volume_db
	ap.play()
	GameManager.is_trigger_playing = true
	
	# Show initial subtitle if any
	if step.subtitle_text != "":
		GameManager.trigger_subtitle(step.subtitle_text, step.audio_clip.get_length() if step.audio_clip else 4.0)
	
	# Monitor events
	var pending_events = step.events.duplicate()
	pending_events.sort_custom(func(a, b): return a.time_offset < b.time_offset)
	
	while ap.playing or not pending_events.is_empty():
		var current_time = ap.get_playback_position()
		
		# Check for events
		while not pending_events.is_empty() and pending_events[0].time_offset <= current_time:
			var event = pending_events.pop_front()
			
			# Calculate duration for this event
			var duration = 4.0 # Default fallback
			if not pending_events.is_empty():
				duration = pending_events[0].time_offset - event.time_offset
			elif step.audio_clip:
				duration = step.audio_clip.get_length() - event.time_offset
			
			# Ensure subtitles don't vanish too fast
			duration = max(duration, 3.0)
				
			execute_event(event, duration)
		
		if not ap.playing and pending_events.is_empty():
			break
			
		await get_tree().create_timer(0.05).timeout
	
	GameManager.is_trigger_playing = false
	# Ensure the finished signal logic is handled if needed
	# In GameManager, _on_trigger_audio_finished will set it to false too.
	# But since we're hijacking the player here, we should be careful.

func execute_event(event: SequenceEvent, duration: float = 4.0):
	if event.subtitle_text != "":
		GameManager.trigger_subtitle(event.subtitle_text, duration)
	
	if event.change_mode:
		GameManager.change_mode(event.target_mode)
		
	var dir = GameManager.current_director
	if event.change_mode:
		dir = "Jumana" if event.target_mode == GameManager.GameMode.CUTE else "Luay"
	
	GameManager.update_director(dir, event.director_expression)

func _update_visuals():
	if not is_node_ready():
		await ready
		
	if not sprite:
		return
		
	# Texture Setting
	if type == TriggerType.PLAY_SOUND or type == TriggerType.CAMERA_CONTROL or type == TriggerType.SIGNAL_ONLY or type == TriggerType.LEVEL_END:
		sprite.texture = null
	else:
		match target_mode:
			GameManager.GameMode.CUTE:
				sprite.texture = cute_texture
			GameManager.GameMode.TOUGH:
				sprite.texture = tough_texture
			_:
				sprite.texture = null
			
	# Visibility Logic
	if Engine.is_editor_hint():
		# In editor, keep sprite visible if it has a texture, or show it as semi-transparent icon placeholder?
		# Actually, let's keep it visible so we can click it.
		sprite.visible = true 
	else:
		# Hide if already triggered or waiting
		if has_triggered or is_waiting:
			sprite.visible = false
		else:
			var current = GameManager.current_mode
			var is_visible = true
			
			# Rule 1: Check activation
			if not always_active:
				is_visible = (current == active_in_mode)
			
			# Rule 2: If it's a style trigger, also respect the opposite-mode logic
			if is_visible and (type == TriggerType.CHANGE_STYLE or type == TriggerType.SOUND_AND_CHANGE):
				is_visible = (current != target_mode)
			
			# Rule 3: Sound, Camera, Signal and Level End triggers are ALWAYS invisible in game
			if is_visible and (type == TriggerType.PLAY_SOUND or type == TriggerType.CAMERA_CONTROL or type == TriggerType.SIGNAL_ONLY or type == TriggerType.LEVEL_END):
				is_visible = false
				
			sprite.visible = is_visible

func _on_mode_changed(_new_mode):
	_update_visuals()

func _appear():
	monitoring = true
	visible = true
	_update_visuals()
	
	if affected_by_gravity:
		is_falling = true
