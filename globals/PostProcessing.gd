extends Node

# --- Profile Settings ---
# We define a simple dictionary structure for each profile to hold the values.
# This makes it easy to add more properties later.

@export_group("Profile: CUTE")
@export var cute_glow_strength: float = 0.9
@export var cute_glow_hdr_threshold: float = 1.0
@export var cute_brightness: float = 1.02
@export var cute_saturation: float = 1.1
@export var cute_vignette_intensity: float = 0.2
@export var cute_vignette_opacity: float = 0.3
@export var cute_grain_amount: float = 0.0
@export var cute_chromatic: float = 0.0

@export_group("Profile: TOUGH")
@export var tough_glow_strength: float = 0.8
@export var tough_glow_hdr_threshold: float = 0.9
@export var tough_brightness: float = 0.9
@export var tough_saturation: float = 0.6
@export var tough_vignette_intensity: float = 0.5
@export var tough_vignette_opacity: float = 0.6
@export var tough_grain_amount: float = 0.05
@export var tough_chromatic: float = 0.005

@export_group("Profile: NATURAL")
@export var natural_glow_strength: float = 1.0
@export var natural_glow_hdr_threshold: float = 0.85
@export var natural_brightness: float = 0.9
@export var natural_saturation: float = 1.0
@export var natural_vignette_intensity: float = 0.4
@export var natural_vignette_opacity: float = 0.4
@export var natural_grain_amount: float = 0.015
@export var natural_chromatic: float = 0.0

@export_group("Profile: UI / MENU")
@export var ui_glow_strength: float = 0.5
@export var ui_glow_hdr_threshold: float = 0.95
@export var ui_brightness: float = 1.0
@export var ui_saturation: float = 1.0
@export var ui_vignette_intensity: float = 0.6
@export var ui_vignette_opacity: float = 0.6
@export var ui_grain_amount: float = 0.0
@export var ui_chromatic: float = 0.0

# --- Current State (Private) ---
var _current_glow_strength: float = 0.8
var _current_glow_hdr_threshold: float = 0.8
var _current_brightness: float = 1.0
var _current_saturation: float = 1.0
var _current_vignette_intensity: float = 0.4
var _current_vignette_opacity: float = 0.4
var _current_grain_amount: float = 0.015
var _current_chromatic: float = 0.0

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var effect_rect: ColorRect = $ShaderLayer/EffectRect
@onready var glitch_rect: ColorRect = $ShaderLayer/GlitchRect

var _tween: Tween

func _ready():
	# Connect to GameManager to listen for changes
	if GameManager:
		GameManager.mode_changed.connect(_on_game_mode_changed)
	
	# Initial update
	_update_visuals()

# Public method to force UI mode (called by Main Menu)
func set_ui_mode():
	_animate_to_profile(ui_glow_strength, ui_glow_hdr_threshold, ui_brightness, ui_saturation, ui_vignette_intensity, ui_vignette_opacity, ui_grain_amount, ui_chromatic)

# Signal Handler
func _on_game_mode_changed(mode):
	match mode:
		GameManager.GameMode.CUTE:
			_animate_to_profile(cute_glow_strength, cute_glow_hdr_threshold, cute_brightness, cute_saturation, cute_vignette_intensity, cute_vignette_opacity, cute_grain_amount, cute_chromatic)
		GameManager.GameMode.TOUGH:
			_animate_to_profile(tough_glow_strength, tough_glow_hdr_threshold, tough_brightness, tough_saturation, tough_vignette_intensity, tough_vignette_opacity, tough_grain_amount, tough_chromatic)
		GameManager.GameMode.NATURAL:
			_animate_to_profile(natural_glow_strength, natural_glow_hdr_threshold, natural_brightness, natural_saturation, natural_vignette_intensity, natural_vignette_opacity, natural_grain_amount, natural_chromatic)

func _animate_to_profile(glow, hdr, bright, sat, vig_int, vig_op, grain, chrom):
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	
	var time = 1.0 # Transition duration
	
	_tween.tween_property(self, "_current_glow_strength", glow, time)
	_tween.tween_property(self, "_current_glow_hdr_threshold", hdr, time)
	_tween.tween_property(self, "_current_brightness", bright, time)
	_tween.tween_property(self, "_current_saturation", sat, time)
	_tween.tween_property(self, "_current_vignette_intensity", vig_int, time)
	_tween.tween_property(self, "_current_vignette_opacity", vig_op, time)
	_tween.tween_property(self, "_current_grain_amount", grain, time)
	_tween.tween_property(self, "_current_chromatic", chrom, time)
	
	# Force constant update during tween
	_tween.tween_method(_tween_update, 0.0, 1.0, time)

func _tween_update(_val):
	_update_visuals()

func _update_visuals():
	# Update Bloom
	if is_node_ready() and world_env and world_env.environment:
		var env = world_env.environment
		env.glow_strength = _current_glow_strength
		env.glow_hdr_threshold = _current_glow_hdr_threshold
	
	# Update Shader
	if is_node_ready() and effect_rect and effect_rect.material:
		var mat = effect_rect.material as ShaderMaterial
		mat.set_shader_parameter("brightness", _current_brightness)
		mat.set_shader_parameter("saturation", _current_saturation)
		mat.set_shader_parameter("vignette_intensity", _current_vignette_intensity)
		mat.set_shader_parameter("vignette_opacity", _current_vignette_opacity)
		mat.set_shader_parameter("grain_amount", _current_grain_amount)
		mat.set_shader_parameter("chromatic_aberration", _current_chromatic)

func trigger_glitch(duration: float):
	if glitch_rect:
		glitch_rect.visible = true
		
		# --- Audio Glitch Implementation ---
		var master_bus = AudioServer.get_bus_index("Master")
		
		# Add Distortion Effect
		var dist = AudioEffectDistortion.new()
		dist.mode = AudioEffectDistortion.MODE_CLIP
		dist.drive = 0.8
		AudioServer.add_bus_effect(master_bus, dist)
		var effect_idx = AudioServer.get_bus_effect_count(master_bus) - 1
		
		# Chaos Loop
		var start_time = Time.get_ticks_msec()
		var end_time = start_time + (duration * 1000)
		
		while Time.get_ticks_msec() < end_time:
			# Random Pitch Shifting
			AudioServer.set_bus_volume_db(master_bus, randf_range(-10.0, 5.0))
			# Randomly mute/unmute for "choppy" feel
			AudioServer.set_bus_mute(master_bus, randf() > 0.8)
			
			await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
			
			if not is_inside_tree(): return # Safety
		
		# Clean Up
		AudioServer.set_bus_mute(master_bus, false)
		AudioServer.set_bus_volume_db(master_bus, 0.0)
		if effect_idx < AudioServer.get_bus_effect_count(master_bus):
			AudioServer.remove_bus_effect(master_bus, effect_idx)
			
		glitch_rect.visible = false
