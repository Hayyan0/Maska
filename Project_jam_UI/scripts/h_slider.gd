extends HSlider


var hovred = false
@onready var mouse_position: Node2D = $mouse_position
@onready var mouse_position_2: Node2D = $mouse_position2

func _physics_process(delta: float) -> void:
	pivot_offset = size / 2
	$mouse_position.position = Vector2(size.x + 10, size.y /2)
	$mouse_position2.position = Vector2(-10.0, size.y / 2)


func _on_mouse_entered() -> void:
	hovred = true
	MouseDisplay.hovred = true
	MouseDisplay.button_node = self


func _on_mouse_exited() -> void:
	hovred = false
	MouseDisplay.hovred = false
	MouseDisplay.button_node = null
