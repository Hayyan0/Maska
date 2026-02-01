extends Control

func _ready() -> void:
	if is_instance_valid(PostProcessing):
		PostProcessing.set_ui_mode()
	$AnimationPlayer.play("4")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == ("4"):
		get_tree().change_scene_to_file("res://Project_jam_UI/scenes/main_menu.tscn")
