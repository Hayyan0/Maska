extends CanvasLayer

@onready var title_label = $Label
@onready var replay_button = $VBoxContainer/ReplayButton
@onready var exit_button = $VBoxContainer/ExitButton

func _ready():
	visible = false
	# Ensure this node processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if GameManager:
		print("DEATH SCREEN: Connecting to GameManager...")
		GameManager.game_over.connect(_on_game_over)
	else:
		print("DEATH SCREEN: GameManager not found!")
	
	# Initial Translation
	_update_text()

func _update_text():
	if Language:
		title_label.text = Language.text("game_over")
		replay_button.text = Language.text("replay")
		exit_button.text = Language.text("exit_to_menu")

func _on_game_over():
	print("DEATH SCREEN: Received game_over signal! Showing...")
	visible = true
	get_tree().paused = true
	
	# Show the Custom Cursor (MouseDisplay)
	if is_instance_valid(MouseDisplay):
		MouseDisplay.visible = true
		
	# Use HIDDEN so the Custom Cursor (MouseDisplay) is seen instead of System Cursor
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_update_text()
	
	# Trigger Animations
	if title_label.has_method("play_shader_fill"):
		title_label.play_shader_fill()
		
	if replay_button.has_method("in_scene"):
		replay_button.in_scene()
		
	if exit_button.has_method("in_scene"):
		exit_button.in_scene()

func _on_replay_pressed():
	get_tree().paused = false
	visible = false
	GameManager.reset_health()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN # Or however gameplay handles mouse
	get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(MouseDisplay):
		MouseDisplay.visible = true
	get_tree().change_scene_to_file("res://Project_jam_UI/scenes/main_menu.tscn")
