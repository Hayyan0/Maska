extends Node

const DURATION = 1.0
var tween: Tween

func _ready():
	# Initialize uniforms
	RenderingServer.global_shader_parameter_set("wipe_progress", 0.0)
	RenderingServer.global_shader_parameter_set("target_is_tough", false)

func _process(delta):
	# Use window size for normalized screen coordinates
	var window_size = get_viewport().get_visible_rect().size
	var aspect = window_size.x / window_size.y
	
	var center = Vector2(0.5, 0.5)
	if is_instance_valid(GameManager.player):
		var screen_pos = GameManager.player.get_global_transform_with_canvas().origin
		center = screen_pos / window_size
	
	# Update ALL objects in the 'morphable' group
	# Multiply progress to reach 2.5 for full corner coverage
	get_tree().call_group("morphable", "update_morph_params", center, aspect, current_wipe_progress * 1.6, target_is_tough)

# Internal State
var current_wipe_progress = 0.0
var target_is_tough = false

func transition_to_tough():
	start_transition(true)

func transition_to_cute():
	start_transition(false)

func start_transition(to_tough: bool):
	target_is_tough = to_tough
	
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_method(set_wipe_progress, 0.0, 1.0, DURATION)

func set_wipe_progress(val):
	current_wipe_progress = val
	# Logic happens in _process so we don't double-loop
