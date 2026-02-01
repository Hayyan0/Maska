extends Control

var mouse_speed = 1.0
@export var mouse_hover = false

var button_hoverd : Node = null
@onready var mouse_select: Control = $mouse_out/mouse_select
@onready var mouse_select_2: Control = $mouse_out/mouse_select2
@onready var mouse_out: Control = $mouse_out


func _ready() -> void:
	print("MOUSE: Initializing...")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$horred.play("off")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true

func _process(delta: float) -> void:
	# Use viewport position to be coordinate-independent
	var m_pos = get_viewport().get_mouse_position()
	global_position = m_pos
	
	if button_hoverd == null:
		# Visuals chase the mouse position
		mouse_select.global_position = mouse_select.global_position.lerp(m_pos, 25.0 * delta)
		mouse_select_2.global_position = mouse_select_2.global_position.lerp(m_pos, 25.0 * delta)
		$select_mode.play("unselect")
	else:
		# Cursor parts split around the button
		mouse_select.global_position = mouse_select.global_position.lerp(button_hoverd.mouse_position.global_position, 25.0 * delta)
		mouse_select_2.global_position = mouse_select_2.global_position.lerp(button_hoverd.mouse_position_2.global_position, 25.0 * delta)
		$select_mode.play("select")

func _input(event: InputEvent) -> void:
	if mouse_hover:
		$horred.play("on")
	else:
		$horred.play("off")
