extends Camera2D

# Customizable deadzone size (percentage of viewport)
@export var deadzone_width: float = 0.8
@export var deadzone_height: float = 0.8
@export var horizontal_follow_speed: float = 4.0
@export var vertical_follow_speed: float = 2.0
@export var is_centered: bool = false # NEW: Locks camera to player center

@export var one_way: bool = true

@onready var player = get_parent()
var max_x_seen: float = -INF

# Shake variables
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready():
	# Initial position at player
	global_position = player.global_position
	max_x_seen = global_position.x
	# Ensure zoom is 1:1
	zoom = Vector2(1.0, 1.0)

func force_update_position():
	if player:
		global_position = player.global_position
		# Reset deadzone tracking
		max_x_seen = global_position.x

func shake(duration: float, intensity: float):
	shake_timer = duration
	shake_intensity = intensity

func _physics_process(delta):
	if not player: return
	
	var viewport_size = get_viewport_rect().size
	var half_viewport = viewport_size / 2.0
	
	# Deadzone boundaries in world coordinates
	var left_bound = global_position.x - (half_viewport.x * deadzone_width)
	var right_bound = global_position.x + (half_viewport.x * deadzone_width)
	var top_bound = global_position.y - (half_viewport.y * deadzone_height)
	var bottom_bound = global_position.y + (half_viewport.y * deadzone_height)
	
	var player_pos = player.global_position
	var target_pos = global_position
	var player_on_floor = player.is_on_floor()
	var has_floor = _has_floor_below()
	
	if is_centered:
		target_pos.x = player_pos.x
		# Only follow player DOWN if they are on the floor OR there's a floor below them.
		# But always follow them UP.
		if player_pos.y < global_position.y or player_on_floor or has_floor:
			target_pos.y = player_pos.y
	else:
		# Check horizontal
		if player_pos.x < left_bound:
			target_pos.x -= left_bound - player_pos.x
		elif player_pos.x > right_bound:
			target_pos.x += player_pos.x - right_bound
			
		# Check vertical
		if player_pos.y < top_bound:
			# Always follow UP
			target_pos.y -= top_bound - player_pos.y
		elif player_pos.y > bottom_bound:
			# Only follow DOWN if grounded or floor detected below (to ignore pits)
			if player_on_floor or has_floor:
				target_pos.y += player_pos.y - bottom_bound
	
	# Apply One-Way Lock (Applies to both modes)
	if one_way:
		target_pos.x = max(target_pos.x, max_x_seen)
		max_x_seen = target_pos.x

	# Smoothly move the camera with separate horizontal/vertical speeds
	global_position.x = lerp(global_position.x, target_pos.x, horizontal_follow_speed * delta)
	global_position.y = lerp(global_position.y, target_pos.y, vertical_follow_speed * delta)
	
	# Apply Shake
	if shake_timer > 0:
		shake_timer -= delta
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = Vector2.ZERO

func _has_floor_below() -> bool:
	if not player: return false
	
	var space_state = get_world_2d().direct_space_state
	# Cast a ray from player position downwards (up to 1200px)
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position, 
		player.global_position + Vector2(0, 1200),
		1 # Collision layer 1 (Environment)
	)
	# Exclude player
	query.exclude = [player.get_rid()]
	
	var result = space_state.intersect_ray(query)
	return result.size() > 0
