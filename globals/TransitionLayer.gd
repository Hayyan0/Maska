extends CanvasLayer

@onready var transition_rect = $TransitionRect
@onready var fade_rect = $FadeRect
@onready var loading_screen = $LoadingScreen if has_node("LoadingScreen") else get_node_or_null("loading")

const DURATION = 1.0

@export_group("Customization")
@export var pattern_rotation: float = 45.0
@export var pattern_speed: float = 0.5

@export_group("Cute Mode Settings")
@export var cute_gradient: GradientTexture1D
@export var cute_icon_color: Color = Color(1, 1, 1, 0.8)

@export_group("Tough Mode Settings")
@export var tough_gradient: GradientTexture1D
@export var tough_icon_color: Color = Color(1, 1, 1, 0.8)

@export_group("Natural Mode Settings")
@export var natural_gradient: GradientTexture1D
@export var natural_icon_color: Color = Color(1, 1, 1, 0.8)




func _ready():
	if is_instance_valid(transition_rect): transition_rect.visible = false
	if is_instance_valid(fade_rect): fade_rect.visible = false
	if is_instance_valid(loading_screen): loading_screen.visible = false
	
	# Initialize Shader Params
	if is_instance_valid(transition_rect):
		transition_rect.material.set_shader_parameter("pattern_rotation", pattern_rotation)
		transition_rect.material.set_shader_parameter("pattern_speed", pattern_speed)



func _process(delta):
	if transition_rect and transition_rect.visible:
		# Use the project's base resolution for consistent normalized coordinates
		# This avoids centering issues with window resizing and black bars
		var proj_size = Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		)
		var aspect = proj_size.x / proj_size.y
		transition_rect.material.set_shader_parameter("aspect", aspect)
		
		# Update Hole Center (Player Position)
		if is_instance_valid(GameManager.player):
			# get_global_transform_with_canvas() is in window pixels
			# We need to normalize it relative to the game viewport
			var screen_pos = GameManager.player.get_global_transform_with_canvas().origin
			var window_size = get_viewport().get_visible_rect().size
			var center = screen_pos / window_size
			transition_rect.material.set_shader_parameter("hole_center", center)

func start_transition():
	# 1. Capture Screen (Old Mode)
	if not is_instance_valid(transition_rect):
		push_error("TransitionLayer: transition_rect is missing!")
		return
		
	var img = get_viewport().get_texture().get_image()
	var tex = ImageTexture.create_from_image(img)
	transition_rect.texture = tex
	transition_rect.visible = true
	
	# 2. Config based on Target Mode logic
	var grad = cute_gradient
	var icon_col = cute_icon_color
	
	match GameManager.current_mode:
		GameManager.GameMode.CUTE:
			grad = cute_gradient
			icon_col = cute_icon_color
		GameManager.GameMode.TOUGH:
			grad = tough_gradient
			icon_col = tough_icon_color
		GameManager.GameMode.NATURAL:
			grad = natural_gradient
			icon_col = natural_icon_color
			
	transition_rect.material.set_shader_parameter("border_gradient", grad)
	transition_rect.material.set_shader_parameter("icon_color", icon_col)
	
	# 3. Reset Hole
	transition_rect.material.set_shader_parameter("hole_radius", 0.0)
	
	# 4. Animate
	# Kill any existing tween to prevent "fight" between transitions
	var tween = create_tween()
	# Increase radius to 2.5 to ensure it covers corners regardless of player position
	tween.tween_method(set_radius, 0.0, 2.5, DURATION)
	tween.tween_callback(finish_transition)

func set_radius(val):
	if is_instance_valid(transition_rect):
		transition_rect.material.set_shader_parameter("hole_radius", val)

func finish_transition():
	if is_instance_valid(transition_rect):
		transition_rect.visible = false

func fade_from_black(duration: float = 1.0):
	if not is_instance_valid(fade_rect): return
	
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): if is_instance_valid(fade_rect): fade_rect.visible = false)

func full_transition_to_level(path: String, custom_image: Texture2D = null):
	# 1. Fade to black
	if not is_instance_valid(fade_rect):
		get_tree().change_scene_to_file(path) # Fallback
		return
		
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	await tween.finished
	
	# 2. Show New Loading Screen
	if not is_instance_valid(loading_screen):
		print("TRANSITION: loading_screen is null, searching...")
		loading_screen = get_node_or_null("LoadingScreen")
		if not loading_screen:
			loading_screen = get_node_or_null("loading")
			
	if is_instance_valid(loading_screen):
		print("TRANSITION: Found loading_screen: ", loading_screen.name)
		loading_screen.visible = true
		if loading_screen.has_method("start_loading"):
			loading_screen.start_loading()
		else:
			print("TRANSITION: loading_screen lacks start_loading() method")
	else:
		push_error("TransitionLayer: LoadingScreen node NOT FOUND in tree!")
		print("TRANSITION: Current children of TransitionLayer: ", get_children())
	# Use the custom_image if provided (though loading.tscn might not use it yet)
	if is_instance_valid(loading_screen) and custom_image and loading_screen.has_node("TextureRect"):
		loading_screen.get_node("TextureRect").texture = custom_image
		
	await get_tree().create_timer(1.5).timeout # Give animation time to play
	
	# 3. Change Scene
	if GameManager:
		GameManager.reset_health()
	print("TRANSITION: Changing scene to: ", path)
	get_tree().change_scene_to_file(path)
	
	# Wait a tiny bit for the new scene to initialize
	await get_tree().process_frame
	
	# 4. Hide Loading and Fade back
	if is_instance_valid(loading_screen):
		loading_screen.visible = false
	fade_from_black(0.8)
