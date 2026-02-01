extends CanvasLayer

var hovred = false
@export var mouse: Node

var button_node : Node = null


func _process(delta: float) -> void:
	mouse.button_hoverd = button_node
	if mouse:
		if hovred:
			mouse.mouse_hover = true
		else:
			mouse.mouse_hover = false
