extends CharacterBody2D

@export var speed = 400.0
@export var damage = 1
@export var lifetime = 3.0
@export var gravity = 1200.0

var direction = Vector2.RIGHT
var is_reversed = false
var is_winding_up = true # Parryable

func _ready():
	add_to_group("boss_projectiles")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	# Connect Hitbox signals
	if has_node("Hitbox"):
		$Hitbox.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
	velocity.x = direction.x * speed
	
	move_and_slide()

func take_damage(_amount: int, is_parry: bool = false):
	if is_parry and not is_reversed:
		reverse()

func reverse():
	is_reversed = true
	is_winding_up = false # No longer parryable once reversed
	direction *= -1
	modulate = Color(1.0, 0.5, 0.5) # Change color to indicate it's dangerous to boss
	print("WAVE: Parried and reversed!")

func _on_body_entered(body):
	if body.is_in_group("player") and not is_reversed:
		if GameManager:
			GameManager.take_damage(damage)
		queue_free()
	elif body.is_in_group("bosses") and is_reversed:
		if body.has_method("take_damage"):
			body.take_damage(2, true) # Bonus damage for parry
		queue_free()
