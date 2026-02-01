@tool
extends CharacterBody2D

@export_group("AI Stats")
@export var speed = 150.0
@export var chase_speed = 220.0
@export var sight_range = 1000.0:
	set(v):
		sight_range = v
		queue_redraw()

@export_range(100, 2000) var wander_width = 500.0:
	set(v):
		wander_width = v
		queue_redraw()

@export var attack_range = 110.0:
	set(v):
		attack_range = v
		queue_redraw()

@export var attack_damage = 1
@export var health = 2
@export var attack_cooldown: float = 1.0
@export var attack_windup_time: float = 0.5 # Widen window for easier parry (was 0.15)

@export_group("Loot")
@export var can_drop_items: bool = true
@export_range(0.0, 1.0) var drop_chance: float = 0.5
@export var loot_table: Array[Texture2D] = []
var pickup_scene_template = preload("res://objects/ItemPickup.tscn")

@export_group("Debug")
@export var debug_show_ranges: bool = true:
	set(v):
		debug_show_ranges = v
		queue_redraw()

var spawn_x = 0.0
var direction = 1
var is_attacking = false
var is_winding_up = false
var is_dead = false
var cooldown_timer = 0.0
var dir_cooldown_timer = 0.0
var push_velocity = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var raycast = $RayCast2D
@onready var collider = $CollisionShape2D

func _ready():
	if Engine.is_editor_hint():
		return
		
	add_to_group("enemies")
	spawn_x = global_position.x
	
	GameManager.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(GameManager.current_mode)
	
	if not is_dead:
		sprite.play("walk")

func _on_mode_changed(mode):
	if mode == GameManager.GameMode.TOUGH:
		visible = true
		process_mode = PROCESS_MODE_INHERIT
		is_attacking = false
		is_winding_up = false
	else:
		visible = false
		process_mode = PROCESS_MODE_DISABLED

func _draw():
	if not debug_show_ranges:
		return
		
	# Draw Sight Range (Blue)
	draw_arc(Vector2.ZERO, sight_range, 0, TAU, 32, Color(0.2, 0.5, 1.0, 0.4), 2.0)
	
	# Draw Attack Range (Red)
	draw_arc(Vector2.ZERO, attack_range, 0, TAU, 32, Color(1.0, 0.2, 0.2, 0.6), 2.0)
	
	# Draw Wander Territory (Green)
	# Note: spawn_x might not be set in editor, so we draw relative to current pos for preview
	var rx = wander_width / 2.0
	draw_line(Vector2(-rx, 20), Vector2(rx, 20), Color(0.2, 1.0, 0.2, 0.5), 4.0)
	draw_line(Vector2(-rx, 10), Vector2(-rx, 30), Color(0.2, 1.0, 0.2, 0.5), 2.0)
	draw_line(Vector2(rx, 10), Vector2(rx, 30), Color(0.2, 1.0, 0.2, 0.5), 2.0)

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
		
	if is_dead:
		# Apply gravity but skip AI logic
		velocity.y += 1200 * delta
		move_and_slide()
		return
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if dir_cooldown_timer > 0:
		dir_cooldown_timer -= delta
	
	if not is_on_floor():
		velocity.y += 1200 * delta
	
	if not is_attacking:
		_handle_ai(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 5)
	
	var final_velocity = velocity
	
	# Apply Push Velocity (Decay)
	if push_velocity.length() > 10:
		push_velocity = push_velocity.move_toward(Vector2.ZERO, 1000 * delta)
		final_velocity += push_velocity
	else:
		push_velocity = Vector2.ZERO
		
	set_velocity(final_velocity)
	move_and_slide()
	velocity = final_velocity - push_velocity # Keep internal velocity clean of external push
	
func apply_push(force: Vector2):
	push_velocity += force
	# Removed _update_visuals call

func _handle_ai(delta):
	var player = GameManager.player
	var target_dir = 0
	var player_in_sight = false
	
	# 1. Check if player is in sight range
	if player:
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player < sight_range:
			player_in_sight = true
	
	# 2. Decision Logic
	if player_in_sight:
		# CHASE
		var to_player_x = player.global_position.x - global_position.x
		
		# HYSTERESIS: Only change direction if significantly far away
		if abs(to_player_x) > 15.0:
			target_dir = sign(to_player_x)
		else:
			target_dir = direction # Maintain current direction
		
		if target_dir != direction and target_dir != 0:
			_flip()
		
		# Proximity Attack check
		var dist_to_player = global_position.distance_to(player.global_position)
		
		# SPACING LOGIC
		if dist_to_player < attack_range:
			# Within range
			if dist_to_player < attack_range * 0.6:
				# Too close! Back away
				target_dir = -sign(to_player_x)
				velocity.x = target_dir * speed # Retreat at normal speed
				if target_dir != 0 and target_dir != direction:
					_flip()
			else:
				# Sweet spot: Stop and Attack
				velocity.x = 0
				if cooldown_timer <= 0:
					_start_attack()
		else:
			# Too far: Chase
			velocity.x = target_dir * chase_speed
	else:
		# WANDER (Patrol) within territory
		var should_flip = false
		var dist_from_spawn = global_position.x - spawn_x
		
		if direction > 0 and dist_from_spawn > wander_width / 2.0:
			should_flip = true
		elif direction < 0 and dist_from_spawn < -wander_width / 2.0:
			should_flip = true
		
		# Wall/Ledge checks
		if is_on_wall() or (is_on_floor() and not raycast.is_colliding()):
			should_flip = true
			
		if should_flip and dir_cooldown_timer <= 0:
			_flip()
			dir_cooldown_timer = 1.0 # 1 second stability before turning again
			
		velocity.x = direction * speed

func _flip():
	direction *= -1
	if raycast:
		raycast.position.x *= -1
	if sprite:
		sprite.flip_h = direction < 0

func _start_attack():
	if is_attacking or cooldown_timer > 0: return
	is_attacking = true
	is_winding_up = true
	
	# Play attack animation
	if sprite and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		
		# Visual Cue for Parry (Yellow Flash)
		var tween = create_tween()
		sprite.modulate = Color(2.0, 2.0, 0.5, 1.0) # Bright Yellow
		tween.tween_property(sprite, "modulate", Color.WHITE, attack_windup_time)
	
	# Windup wait
	get_tree().create_timer(attack_windup_time).timeout.connect(_execute_attack)

func _execute_attack():
	if is_dead or not is_attacking: return
	
	is_winding_up = false # Parry window closed
	
	if GameManager.player:
		var dist = global_position.distance_to(GameManager.player.global_position)
		if dist < attack_range:
			# Player damage logic
			print("Enemy hit player for ", attack_damage, " damage!")
			if GameManager:
				GameManager.take_damage(attack_damage)
	
	get_tree().create_timer(0.2).timeout.connect(func():
		is_attacking = false
		cooldown_timer = attack_cooldown
		if sprite and not is_dead:
			sprite.play("walk")
	)

func take_damage(amount: int, is_parry: bool = false):
	if is_dead: return
	
	if is_parry:
		print("COMBAT: Parry Triggered! Health was: ", health)
		health -= 3
		
		# Knockback
		var knock_dir = -direction
		velocity.x = knock_dir * 400
		velocity.y = -200
		
		# Feedback
		if sprite:
			var t = create_tween()
			sprite.modulate = Color(2.0, 2.0, 2.0) # Flash white bright
			t.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	else:
		health -= amount
		print("COMBAT: Standard Hit! Health improved to: ", health)
	
	# Flicker Effect
	var tween = create_tween()
	if sprite:
		# Flash RED then toggle visibility for flicker effect
		sprite.self_modulate = Color.RED
		tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)
		tween.tween_interval(0.05)
		tween.tween_callback(func(): sprite.visible = false)
		tween.tween_interval(0.05)
		tween.tween_callback(func(): sprite.visible = true)
		tween.tween_interval(0.05)
		tween.tween_callback(func(): sprite.visible = false)
		tween.tween_interval(0.05)
		tween.tween_callback(func(): sprite.visible = true)
	
	if health <= 0:
		print("COMBAT: Enemy Died.")
		_die()

func _die():
	if is_dead: return
	is_dead = true
	collision_layer = 0 # No interaction with player/projectiles
	collision_mask = 1  # KEEP FLOOR COLLISION (Bit 1) so it falls
	
	collider.rotation = PI / 2 # Rotate 90 degrees
	
	velocity.x = 0
	
	# Spawn Loot
	if can_drop_items and loot_table.size() > 0:
		if randf() <= drop_chance:
			var dropped_texture = loot_table.pick_random()
			if dropped_texture and pickup_scene_template:
				var item = pickup_scene_template.instantiate()
				item.global_position = global_position + Vector2(0, -20)
				item.item_texture = dropped_texture # Assign texture dynamically
				get_parent().add_child(item)
				print("LOOT: Enemy dropped item (Texture)!")
	
	# Play death animation
	if sprite and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		# Wait for animation to finish then fade out
		await sprite.animation_finished
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
