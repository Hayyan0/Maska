
@tool
extends Button

var hovred = false
@onready var mouse_position: Node2D = $mouse_position
@onready var mouse_position_2: Node2D = $mouse_position2


func _ready() -> void:
	$AnimationPlayer.play("unhovred")
	in_scene()


func _physics_process(delta: float) -> void:
	pivot_offset = size / 2
	$mouse_position.position = Vector2(size.x, size.y /2)
	$mouse_position2.position = Vector2(0.0, size.y / 2)
	if hovred:
		$AnimationPlayer.play("hovred")
	else:
		$AnimationPlayer.play("unhovred")


func _on_mouse_entered() -> void:
	hovred = true
	MouseDisplay.hovred = true
	MouseDisplay.button_node = self

func in_scene():
	$AnimationPlayer2.play("intro")

func out_scene():
	$AnimationPlayer2.play("outro")


func _on_mouse_exited() -> void:
	hovred = false
	MouseDisplay.hovred = false
	MouseDisplay.button_node = null
