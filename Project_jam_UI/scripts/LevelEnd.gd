extends Control

func _ready():
	# Fade in effect or just wait
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://Project_jam_UI/scenes/main_menu.tscn")

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		get_tree().change_scene_to_file("res://Project_jam_UI/scenes/main_menu.tscn")
