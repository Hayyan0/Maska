extends Control

var point_varint = 0
@export var point : Node

func _ready() -> void:
	$TextureRect2/brids/AnimationPlayer.play("anim")
	$"../ColorRect2/AnimationPlayer".play("start")

func _physics_process(delta: float) -> void:
	match point_varint:
		0:
			point = $"../point_1"
		1:
			point = $"../point_2"
		2:
			point = $"../point_3"
	position = lerp(position, point.position, 0.2 * delta)
	rotation = lerp(rotation, point.rotation, 0.2 * delta)


func _on_timer_timeout() -> void:
	point_varint = randi_range(0, 2)


func change_background():
	$"../Panel2".show()
	await get_tree().create_timer(0.7).timeout
	if $TextureRect2.visible == false:
		$TextureRect2.show()
		$"../ColorRect".show()
		await get_tree().create_timer(0.2).timeout
		$"../ColorRect".hide()
	else:
		$TextureRect2.hide()
		$"../ColorRect".show()
		await get_tree().create_timer(0.2).timeout
		$"../ColorRect".hide()
	await get_tree().create_timer(0.2).timeout
	$"../Panel2".hide()




func _on_timer_2_timeout() -> void:
	change_background()
	$Timer2.start()
	$TextureRect2/brids/AnimationPlayer.play("anim")
