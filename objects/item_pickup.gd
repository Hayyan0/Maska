extends Area2D

@export var item_texture: Texture2D
@export var item_value: int = 1
@export var magnet_speed: float = 400.0
@export var magnet_radius: float = 30.0 # Reduced from 150 to require "walking on it"

@onready var sprite = $Sprite2D

var target_player = null
var is_magnetized = false
var is_following = false
var can_collect = false

func _ready():
	if item_texture:
		sprite.texture = item_texture
	
	sprite.visible = true # Ensure visible
	
	# Spawn Animation (Pop up)
	var tween = create_tween()
	var random_x = randf_range(-50, 50)
	var target_pos = position + Vector2(random_x, -50)
	# Jump up and side
	tween.tween_property(self, "position", target_pos, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fall down to ground (simulated)
	tween.tween_property(self, "position:y", target_pos.y + 50, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Collection Delay
	get_tree().create_timer(1.0).timeout.connect(func(): can_collect = true)
	
	# Connect overlap signal for magnet detection
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("morphable"): # Player group
		target_player = body
		if can_collect:
			is_magnetized = true

func _process(delta):
	if not can_collect: return
	
	if is_following:
		if is_instance_valid(target_player):
			var target_offset = Vector2(0, -80) # Follow above head
			var desired_pos = target_player.global_position + target_offset
			global_position = global_position.lerp(desired_pos, 15.0 * delta)
		else:
			queue_free()
		return

	# If we have a target but not magnetized yet, check if it's still alive/valid
	if target_player and not is_magnetized:
		if is_instance_valid(target_player):
			is_magnetized = true
		else:
			target_player = null

	# Fallback: check overlapping bodies if no target
	if not target_player:
		var bodies = get_overlapping_bodies()
		for b in bodies:
			if b.is_in_group("morphable"):
				target_player = b
				is_magnetized = true
				break
	
	if is_magnetized and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position).normalized()
		# Speed up Magnet if player is moving fast
		var effective_speed = magnet_speed + target_player.velocity.length()
		global_position += direction * effective_speed * delta
		
		# Check for collection distance - increased to 40 for better reliability
		if global_position.distance_to(target_player.global_position) < 40.0:
			_collect()

func _collect():
	if is_following: return
	
	if GameManager:
		# Assume heart logic for now, can be genericized later
		if "Heart" in name or (item_texture and (item_texture.resource_path.contains("Heart") or item_texture.resource_path.contains("1.png"))):
			if GameManager.health < GameManager.max_health:
				GameManager.health += item_value
				if GameManager.health > GameManager.max_health:
					GameManager.health = GameManager.max_health
				GameManager.health_changed.emit(GameManager.health, GameManager.max_health)
				print("Collected Item! Health: ", GameManager.health)
	
	is_following = true
	# Disable physical interactions
	monitoring = false
	monitorable = false
	# Ensure it stays on top visually
	z_index = 10
	
	# Feedback animation when sticking
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.3, 0.3), 0.1)
	tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.1)
