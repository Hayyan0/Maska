extends Control

func _ready():
	# Ensure UI mode is set for post-processing
	if is_instance_valid(PostProcessing):
		PostProcessing.set_ui_mode()
	
	# Start with fade-in from black
	if TransitionLayer:
		TransitionLayer.fade_from_black(2.0)
	
	# Optional: Return to menu after a delay or on click
	get_tree().create_timer(10.0).timeout.connect(_on_timeout)

func _on_timeout():
	if GameManager:
		get_tree().change_scene_to_file("res://Project_jam_UI/scenes/main_menu.tscn")

func _input(event):
	if event is InputEventMouseButton or event is InputEventKey:
		if event.is_pressed():
			_on_timeout() # Skip to menu
