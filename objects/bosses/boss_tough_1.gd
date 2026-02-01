extends CharacterBody2D

@export var health = 15
@export var speed = 100.0
@export var attack_range = 300.0
@export var wave_scene: PackedScene = preload("res://objects/bosses/boss_wave.tscn")
const ATTACK_SOUND = preload("res://Reaper - Ground attack.wav")

enum State { IDLE, ATTACK_1, ATTACK_2, HURT, DEATH }
var current_state = State.IDLE

var gravity = 1200.0
var target_player: Node2D
var is_dead = false

@onready var sprite = $AnimatedSprite2D
var audio_player: AudioStreamPlayer2D

var is_active = false

func _ready():
	add_to_group("enemies")
	add_to_group("bosses")
	target_player = GameManager.player
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Audio setup
	audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = ATTACK_SOUND
	add_child(audio_player)

func _physics_process(delta):
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return
		
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# ALWAYS FACE PLAYER (if valid)
	if not is_instance_valid(target_player):
		target_player = GameManager.player
		
	if is_instance_valid(target_player):
		# logic inverted as requested: currently it looks away implies default asset might be Left facing or this result was inverted
		sprite.flip_h = target_player.global_position.x > global_position.x
		
	if not is_active:
		# Check if we should activate
		if has_node("VisibleOnScreenNotifier2D"):
			if get_node("VisibleOnScreenNotifier2D").is_on_screen():
				is_active = true
				print("BOSS: Activated by screen entry!")
		else:
			# Fallback: Distance check (approx screen width)
			if is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) < 1000:
				is_active = true
		
		# If still not active, stay idle and apply gravity
		move_and_slide()
		return

	match current_state:
		State.IDLE:
			_handle_idle(delta)
		State.ATTACK_1, State.ATTACK_2:
			velocity.x = move_toward(velocity.x, 0, speed * delta)

	move_and_slide()

func _handle_idle(delta):
	if not is_instance_valid(target_player):
		target_player = GameManager.player
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	
	if dist < attack_range:
		if randf() > 0.5:
			_start_attack_1()
		else:
			_start_attack_2()
	else:
		# Slowly walk toward player if far
		var dir = sign(target_player.global_position.x - global_position.x)
		velocity.x = dir * speed

func _start_attack_1():
	current_state = State.ATTACK_1
	sprite.play("attack_1")
	# Attack 1 event (Ground slam) is triggered by animation frame or timer
	get_tree().create_timer(0.5).timeout.connect(_on_ground_slam)

func _on_ground_slam():
	if current_state != State.ATTACK_1 or is_dead: return
	
	# Play Sound
	if audio_player:
		audio_player.play()
	
	# Shake Camera
	if is_instance_valid(target_player):
		var cam = target_player.get_node_or_null("Camera2D")
		if cam and cam.has_method("shake"):
			cam.shake(0.5, 15.0)
	
	# Spawn Wave
	if wave_scene:
		var wave = wave_scene.instantiate()
		# global_position is center. 
		# Making wave bigger and spawning lower
		wave.scale = Vector2(2.5, 2.5) # Bigger wave
		wave.global_position = global_position + Vector2(0, 90) # Lower spawn (feet)
		wave.direction = Vector2.LEFT if not sprite.flip_h else Vector2.RIGHT # Direction based on flip (Note: flip logic changed above)
		# Wait, if flip_h is true (Facing RIGHT now), direction should be RIGHT.
		# If flip_h is false (Facing LEFT), direction should be LEFT.
		# My physics_process logic: flip_h = target > global (Right). So flip_h=True means Right.
		# So wave.direction = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT.
		wave.direction = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT
		
		get_parent().add_child(wave)

func _start_attack_2():
	current_state = State.ATTACK_2
	sprite.play("attack_2")
	# Simple melee damage check at the end of animation or mid-animation
	get_tree().create_timer(0.4).timeout.connect(_check_melee_hit)

func _check_melee_hit():
	if current_state != State.ATTACK_2 or is_dead: return
	if is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist < 150.0:
			GameManager.take_damage(1)

func take_damage(amount: int, is_parry: bool = false):
	if is_dead: return
	
	health -= amount
	print("BOSS: Took damage! Health: ", health)
	
	# Visual feedback
	var t = create_tween()
	sprite.modulate = Color.RED
	t.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		_die()
	elif not (current_state == State.ATTACK_1 or current_state == State.ATTACK_2):
		current_state = State.HURT
		# sprite.play("hurt") # If hurt animation exists

func _die():
	is_dead = true
	current_state = State.DEATH
	collision_layer = 0
	sprite.play("idle") # Fallback to idle if no death anim
	
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	t.tween_callback(queue_free)
	print("BOSS: Defeated!")

func _on_animation_finished():
	if current_state == State.ATTACK_1 or current_state == State.ATTACK_2 or current_state == State.HURT:
		current_state = State.IDLE
		sprite.play("idle")
