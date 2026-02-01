@tool
extends StaticBody2D

@export_category("Barrier Configuration")
@export var always_active: bool = false:
	set(val):
		always_active = val
		_update_state(GameManager.current_mode if not Engine.is_editor_hint() else active_in_mode)
@export var active_in_mode: GameManager.GameMode = GameManager.GameMode.NATURAL:
	set(val):
		active_in_mode = val
		_update_state(GameManager.current_mode if not Engine.is_editor_hint() else active_in_mode)

@onready var collision_shape = $CollisionShape2D

# Save default layers to restore them later
var default_layer: int
var default_mask: int

func _ready():
	default_layer = collision_layer
	default_mask = collision_mask
	
	GameManager.mode_changed.connect(_on_mode_changed)
	_update_state(GameManager.current_mode)

func _on_mode_changed(new_mode):
	_update_state(new_mode)

func _update_state(current_mode):
	if not is_inside_tree(): return
	
	if Engine.is_editor_hint():
		# In editor, always visible/active, but change color for feedback
		if collision_shape:
			match active_in_mode:
				GameManager.GameMode.CUTE:
					collision_shape.debug_color = Color(1, 0.4, 0.7, 0.4) # Pink
				GameManager.GameMode.TOUGH:
					collision_shape.debug_color = Color(0, 0.8, 1, 0.4) # Cyan
				_:
					collision_shape.debug_color = Color(0.7, 0, 0, 0.4) # Red (Default)
		
		# Always red if always_active is on
		if always_active and collision_shape:
			collision_shape.debug_color = Color(0.7, 0, 0, 0.4)
			
		return

	var should_be_active = always_active or (current_mode == active_in_mode)
	
	if should_be_active:
		collision_layer = default_layer
		collision_mask = default_mask
	else:
		collision_layer = 0
		collision_mask = 0
