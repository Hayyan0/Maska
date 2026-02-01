extends CharacterBody2D

@export_group("Cute Stats")
@export var speed_cute = 400.0
@export var jump_cute = -600.0
@export var frames_cute : SpriteFrames

@export_group("Tough Stats")
@export var speed_tough = 250.0 

@export var frames_tough : SpriteFrames

@export_group("Natural Stats")
@export var speed_natural = 350.0
@export var jump_natural = -550.0
@export var frames_natural : SpriteFrames

# --- INTERNAL STATE ---
# Glow Removed

var current_speed = 0.0
var gravity = 980.0

@export_group("Jump Polish")
@export var coyote_time_duration: float = 0.15
@export var jump_buffer_duration: float = 0.15
@export var fall_gravity_multiplier: float = 1.8

@export_group("Movement Polish")
@export var acceleration_ground: float = 0.2
@export var acceleration_air: float = 0.05
@export var friction: float = 0.15

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var can_double_jump: bool = false
var is_preparing_jump: bool = false
var max_sprite_height: float = 0.0
var is_dying: bool = false
var is_attacking: bool = false

@onready var sprite = $Sprite2D # This is now an AnimatedSprite2D
@onready var collider = $CollisionShape2D

var initial_collider_height: float = 0.0
var initial_collider_pos_y: float = 0.0

var contact_damage_timer: float = 0.0
@export var hit_range = 150.0

var input_enabled: bool = true

# Walk SFX
var grass_sfx: Array[AudioStream] = []
var concrete_sfx: Array[AudioStream] = []
var step_audio_player: AudioStreamPlayer
var step_timer: float = 0.0
var step_interval: float = 0.35 # Time between footsteps

# Sword SFX
var sword_sfx: Array[AudioStream] = []
var sword_audio_player: AudioStreamPlayer

func _ready():
	# Reset state flags (fixes respawn-dead bug when returning from main menu)
	is_dying = false
	is_attacking = false
	
	# Listen to the global brain
	GameManager.mode_changed.connect(_on_mode_changed)
	# Initialize
	add_to_group("morphable")
	GameManager.player = self
	
	sprite.animation_finished.connect(_on_animation_finished)
	
	if not frames_cute: print("ERROR: frames_cute export is NULL")
	if not frames_tough: print("ERROR: frames_tough export is NULL")
	
	GameManager.set_safe_position(global_position)
	_on_mode_changed(GameManager.current_mode)
	
	# CAPTURE INITIAL COLLIDER SETTINGS (to avoid overwriting user changes)
	if collider.shape is CapsuleShape2D:
		initial_collider_height = collider.shape.height
		initial_collider_pos_y = collider.position.y
	
	# Determine base sprite height for ground alignment
	if sprite.sprite_frames:
		var tex = sprite.sprite_frames.get_frame_texture("idle", 0)
		if tex: max_sprite_height = tex.get_height()
	
	# Load walk SFX
	_load_walk_sfx()

func update_morph_params(center, aspect, progress, is_tough):
	if sprite.material:
		sprite.material.set_shader_parameter("wipe_center", center)
		sprite.material.set_shader_parameter("screen_aspect", aspect)
		sprite.material.set_shader_parameter("wipe_progress", progress)
		sprite.material.set_shader_parameter("target_is_tough", is_tough)

func _on_mode_changed(mode):
	# Update Stat Logic
	if mode == GameManager.GameMode.CUTE:
		current_speed = speed_cute
		sprite.sprite_frames = frames_cute
	elif mode == GameManager.GameMode.TOUGH:
		current_speed = speed_tough
		sprite.sprite_frames = frames_tough
	else:
		current_speed = speed_natural
		sprite.sprite_frames = frames_natural
	
	sprite.play("idle")
	sprite.play("idle")
	# _update_visual_glow() # REMOVED: Glow placeholder removed

# func _update_visual_glow(): REMOVED

func _physics_process(delta):
	# If dead or paused, stop input/movement
	if is_dying or not input_enabled or GameManager.health <= 0:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		
		if is_dying:
			collider.rotation = PI / 2 # Rotate 90 degrees
			if sprite.sprite_frames.has_animation("death"):
				if sprite.animation != "death":
					sprite.play("death")
			else:
				# Fallback if no death animation exists
				GameManager.die()
		else:
			# If we are not "is_dying" yet but health is 0, start dying
			if GameManager.health <= 0:
				is_dying = true
				if sprite.sprite_frames.has_animation("death"):
					sprite.play("death")
				else:
					GameManager.die()
			elif is_attacking:
				# Just stay on attack frame if somehow transition is stuck
				pass
			else:
				sprite.play("idle")
		return

	# Ground Alignment Fix (for Crouch/Prep frames)
	if is_preparing_jump and sprite.sprite_frames:
		var current_tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if current_tex:
			# Push the sprite down to align the bottom with the floor
			var height_diff = max_sprite_height - current_tex.get_height()
			sprite.position.y = max(0, height_diff / 2.0)
			
			# Adjust Collider to match visual crouch
			if $CollisionShape2D.shape is CapsuleShape2D:
				$CollisionShape2D.shape.height = max(40, current_tex.get_height())
				$CollisionShape2D.position.y = height_diff / 2.0
	else:
		sprite.position.y = 0
		collider.rotation = 0 # RESET ROTATION
		if collider.shape is CapsuleShape2D:
			collider.shape.height = initial_collider_height
			collider.position.y = initial_collider_pos_y

	# Timers
	move_and_slide() # move_and_slide updates is_on_floor()
	

	
	if is_on_floor():
		coyote_timer = coyote_time_duration
		can_double_jump = true
	else:
		coyote_timer -= delta
		
	jump_buffer_timer -= delta
	
	# Add gravity
	if not is_on_floor():
		var multiplier = 1.0
		if velocity.y > 0: # Falling
			multiplier = fall_gravity_multiplier
		velocity.y += gravity * multiplier * delta	


	
	# Contact Damage & Pushing
	if contact_damage_timer > 0:
		contact_damage_timer -= delta
		
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("enemies"):
			# Push Enemy
			if collider.has_method("apply_push"):
				var push_dir = (collider.global_position - global_position).normalized()
				# Flatten Y for horizontal push mainly
				push_dir.y *= 0.2 
				collider.apply_push(push_dir * 5000 * delta)
			
			# Take Contact Damage
			if contact_damage_timer <= 0:
				GameManager.take_damage(1)
				contact_damage_timer = 1.0 # 1 second invincibility for contact damage
				# Optional: Bounce player back a tiny bit
				velocity.x = -sign(collider.global_position.x - global_position.x) * 200
	if Input.is_action_just_pressed("jump") and GameManager.current_mode != GameManager.GameMode.TOUGH:
		jump_buffer_timer = jump_buffer_duration

	# Handle Jump
	if jump_buffer_timer > 0 and not is_preparing_jump:
		if is_on_floor() or coyote_timer > 0:
			# Start Ground Preparation (Frames 1-4)
			is_preparing_jump = true
			sprite.play("jump")
			# 4 frames / 24 FPS = 0.16s
			get_tree().create_timer(0.12).timeout.connect(func():
				if is_instance_valid(self):
					var jump_val = jump_cute if GameManager.current_mode == GameManager.GameMode.CUTE else jump_natural
					velocity.y = jump_val
					is_preparing_jump = false
			)
			jump_buffer_timer = 0
			coyote_timer = 0

		
	# Variable Jump Height (REMOVED: User requested fixed jump)
	
	# Handle Attack
	if Input.is_action_just_pressed("attack") and GameManager.current_mode == GameManager.GameMode.TOUGH:
		_trigger_attack_glow()
	
	var safe_pos_timer: float = 0.0

	# Safe Position Tracking
	if is_on_floor():
		safe_pos_timer += get_process_delta_time()
		if safe_pos_timer > 0.5: # 0.5s stability required
			GameManager.set_safe_position(global_position)
	else:
		safe_pos_timer = 0.0
	
	# Fall Detection
	if global_position.y > 2000: # Adjust threshold as needed
		# In Cute mode, fall = damage + respawn
		# In Tough mode, fall vs damage is tricky. User said "tough mode you loose heart when you are hit without respawn".
		# Assuming fall in Tough also damages.
		if GameManager.current_mode == GameManager.GameMode.CUTE:
			GameManager.take_damage(1)
		elif GameManager.current_mode == GameManager.GameMode.TOUGH:
			# If we fall in tough mode, do we die instantly or take damage?
			# User said: "tough mode you loose heart when you are hit without respawn"
			# Falling off might be instant death or damage. Let's start with damage.
			# But if no respawn, we just fall forever.
			# So for Tough Mode fall, we probably should respawn OR die instantly.
			# Given "without respawn" implies combat. Falling usually implies death or respawn penalty.
			# I'll implement take_damage(1) and FORCE respawn for fall only, or just take damage and let them fall (which breaks game).
			# Let's assume Fall = Damage + Respawn for *both* modes essentially, OR fall = instant death in Tough.
			# Re-reading: "in cute mode when you fall... respawn... in tough mode... without respawn"
			# This implies Tough mode doesn't respawn on hit, but doesn't explicitly say fall.
			# If I don't respawn on fall in Tough, game softlocks.
			# I will treat Fall as a special case that *must* respawn or kill.
			# Let's apply damage and respawn for now to avoid softlock.
			GameManager.take_damage(1)
			GameManager.respawn_player() # Force respawn on fall even in Tough to prevent softlocks

	# Handle Movement
	var direction = Input.get_axis("move_left", "move_right")
	
	# Determine current acceleration factor
	var accel = acceleration_ground if is_on_floor() else acceleration_air
	
	if direction:
		# Use lerp-like move_toward for acceleration
		velocity.x = move_toward(velocity.x, direction * current_speed, current_speed * accel)
		sprite.flip_h = direction < 0
	else:
		# Use friction for stopping
		var stop_accel = friction if is_on_floor() else acceleration_air
		velocity.x = move_toward(velocity.x, 0, current_speed * stop_accel)

	move_and_slide()
	update_animation()

func _trigger_attack_glow():
	if is_attacking: return # Prevent spam
	
	is_attacking = true
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	
	# Play random sword sound
	_play_sword_sfx()
	
	# Detect Enemies to Hit/Parry
	_check_attack_hits()

func _check_attack_hits():
	var targets = get_tree().get_nodes_in_group("enemies")
	targets.append_array(get_tree().get_nodes_in_group("destructible"))
	
	var hit_count = 0
	for target in targets:
		if not is_instance_valid(target): continue
		if not target.visible: continue
		
		# Distances
		var to_target = target.global_position - global_position
		var dist = to_target.length()
		
		var effective_range = hit_range
		if target.is_in_group("destructible"):
			effective_range = hit_range * 3 # 300px works for tree dimensions

		# DEBUG: Log potential targets
		if dist < effective_range * 2: # Adjusted debug range
			print("[AttackDebug] Potential target: ", target.name, " dist: ", dist, " range: ", effective_range)

		if dist < effective_range:
			# Check if target is in front of us
			var dot = to_target.normalized().x
			var is_in_front = (dot > 0 and not sprite.flip_h) or (dot < 0 and sprite.flip_h)
			
			# Overlap tolerance: if we are VERY close, direction doesn't matter
			if dist < hit_range * 0.5:
				is_in_front = true
				
			if is_in_front:
				hit_count += 1
				# PARRY LOGIC: Check if target is in "Windup" phase
				var is_windup = target.get("is_winding_up")
				var is_parry = is_windup == true
				
				if is_parry:
					_play_parry_sfx()
				
				if target.has_method("take_damage"):
					print("[AttackDebug] Hitting ", target.name)
					target.take_damage(1, is_parry)
	
	if hit_count == 0:
		print("[AttackDebug] No targets in range/front among ", targets.size(), " candidates.")

func _play_parry_sfx():
	# Use sword_audio_player but with higher pitch and volume for distinct "CLANG"
	if sword_sfx.size() > 0:
		var random_sfx = sword_sfx[randi() % sword_sfx.size()]
		sword_audio_player.stream = random_sfx
		sword_audio_player.pitch_scale = 1.2
		sword_audio_player.volume_db = 5.0 # Louder
		sword_audio_player.play()
		
		# Reset later? No need, next sword swing will reset properties or we just reset them in _play_sword_sfx


func update_animation():
	if is_preparing_jump or is_attacking:
		return
		
	if is_on_floor():
		if abs(velocity.x) > 10.0:
			sprite.play("walk")
			_handle_walk_sfx(get_physics_process_delta_time())
		else:
			sprite.play("idle")
			step_timer = 0.0 # Reset when idle
	else:
		if velocity.y < 0:
			# Stay on frame 5-7 (ascent)
			if sprite.animation != "jump" or sprite.frame < 4:
				sprite.play("jump")
				sprite.frame = 4
		else:
			sprite.play("fall")

func _on_animation_finished():
	if sprite.animation == "death":
		# Only signal death completion if we are actually at 0 health
		if GameManager.health <= 0:
			GameManager.die()
	
	if sprite.animation == "attack":
		is_attacking = false

func _load_walk_sfx():
	step_audio_player = AudioStreamPlayer.new()
	step_audio_player.volume_db = -15.0
	add_child(step_audio_player)
	
	# Load grass sounds
	for i in range(1, 10):
		var path = "res://assets/sfx/grass/FS-grass-%d.ogg" % i
		var sfx = load(path)
		if sfx:
			grass_sfx.append(sfx)
	
	# Load concrete sounds
	for i in range(1, 10):
		var path = "res://assets/sfx/concrete/FS-cement-%d.ogg" % i
		var sfx = load(path)
		if sfx:
			concrete_sfx.append(sfx)
	
	# Load sword sounds
	sword_audio_player = AudioStreamPlayer.new()
	sword_audio_player.volume_db = -8.0
	add_child(sword_audio_player)
	
	for i in range(1, 5):
		var path = "res://assets/sfx/Sword/sword%d.ogg" % i
		var sfx = load(path)
		if sfx:
			sword_sfx.append(sfx)

func _handle_walk_sfx(delta: float):
	step_timer += delta
	if step_timer >= step_interval:
		step_timer = 0.0
		_play_random_step()

func _play_random_step():
	var sounds: Array[AudioStream] = []
	
	if GameManager.current_mode == GameManager.GameMode.NATURAL:
		sounds = concrete_sfx
	else: # Cute or Tough = grass
		sounds = grass_sfx
	
	if sounds.size() > 0:
		var random_sfx = sounds[randi() % sounds.size()]
		step_audio_player.stream = random_sfx
		step_audio_player.play()

func _play_sword_sfx():
	if sword_sfx.size() > 0:
		var random_sfx = sword_sfx[randi() % sword_sfx.size()]
		sword_audio_player.stream = random_sfx
		sword_audio_player.pitch_scale = 1.0 # Reset pitch
		sword_audio_player.volume_db = -8.0 # Reset volume
		sword_audio_player.play()
