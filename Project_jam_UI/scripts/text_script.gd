extends Label

@export var fill_speed := 1.5 

@onready var mat := material as ShaderMaterial

var progress := 0.0
var is_filling := false

func _ready() -> void:
	play_shader_fill()


func play_shader_fill():
	progress = 0.0
	is_filling = true
	mat.set_shader_parameter("reveal", 0.0)

func _process(delta):
	if not is_filling:
		return

	progress += delta * fill_speed
	progress = clamp(progress, 0.0, 1.0)

	mat.set_shader_parameter("reveal", progress)

	if progress >= 1.0:
		is_filling = false
