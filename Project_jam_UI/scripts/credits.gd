extends Control

func _ready() -> void:
	$scene_1/AnimationPlayer.play("scene1")

func _input(event):
	if event.is_action_pressed("pause"):
		var target = GameManager.return_scene if "return_scene" in GameManager else "res://Project_jam_UI/scenes/main_menu.tscn"
		get_tree().change_scene_to_file(target)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ("scene1"):
		change_background()

func change_background():
	$Panel2.show()
	await get_tree().create_timer(0.6).timeout
	$ColorRect.show()
	await get_tree().create_timer(0.2).timeout
	$scene2/AnimationPlayer.play("scene2")
	$ColorRect.hide()
	await get_tree().create_timer(0.2).timeout
	$Panel2.hide()


func _on_animation2_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ("scene2"):
		get_tree().change_scene_to_file("res://Project_jam_UI/scenes/main_menu.tscn")
