extends CanvasLayer

@onready var pause_panel = $PausePanel
@onready var logo = $PausePanel/Logo
@onready var resume_button = $PausePanel/VBoxContainer/ResumeButton
@onready var settings_button = $PausePanel/VBoxContainer/SettingsButton
@onready var credits_button = $PausePanel/VBoxContainer/CreditsButton
@onready var exit_button = $PausePanel/VBoxContainer/ExitButton

@onready var settings_panel = $SettingsPanel
@onready var exit_confirmation = $ExitConfirmation

var is_paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	settings_panel.visible = false
	exit_confirmation.visible = false
	_update_text()

func _input(event):
	if event.is_action_pressed("pause"):
		if exit_confirmation.visible:
			_on_no_pressed()
		elif settings_panel.visible:
			_on_back_pressed()
		else:
			toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	visible = is_paused
	
	if is_paused:
		_update_text()
		if is_instance_valid(MouseDisplay):
			MouseDisplay.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		
		# Initial state animations
		if resume_button.has_method("in_scene"): resume_button.in_scene()
		if settings_button.has_method("in_scene"): settings_button.in_scene()
		if credits_button.has_method("in_scene"): credits_button.in_scene()
		if exit_button.has_method("in_scene"): exit_button.in_scene()
	else:
		if is_instance_valid(MouseDisplay):
			MouseDisplay.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

func _update_text():
	if Language:
		resume_button.text = Language.text("resume")
		settings_button.text = Language.text("setting")
		credits_button.text = Language.text("Crd")
		exit_button.text = Language.text("exit_to_menu")
		
		# Settings Panel Localization using exact Main Menu node names
		settings_panel.get_node("Label").text = Language.text("setting")
		settings_panel.get_node("setter").text = Language.text("lan_display")
		settings_panel.get_node("setter2").text = Language.text("master_sound")
		settings_panel.get_node("setter3").text = Language.text("talk_sound")
		settings_panel.get_node("setter4").text = Language.text("soundeffect")
		settings_panel.get_node("setter5").text = Language.text("music")
		
		settings_panel.get_node("Button").text = Language.text("back")
		settings_panel.get_node("Button2").text = Language.text("rest")
		settings_panel.get_node("Button3").text = Language.text("save")
		
		$ExitConfirmation/Label.text = Language.text("do_you_want_exit")
		$ExitConfirmation/HBoxContainer/YesButton.text = Language.text("yes")
		$ExitConfirmation/HBoxContainer/NoButton.text = Language.text("no")

func _on_language_pressed(idx):
	if Language:
		Language.lan_func_sel(idx)
		_update_text()

func _on_resume_pressed():
	toggle_pause()

func _on_settings_pressed():
	pause_panel.visible = false
	settings_panel.visible = true
	# Trigger shader animations for all setter labels
	for i in range(1, 6):
		var node_name = "setter" if i == 1 else "setter" + str(i)
		var node = settings_panel.get_node_or_null(node_name)
		if node and node.has_method("play_shader_fill"):
			node.play_shader_fill()
	settings_panel.get_node("Label").play_shader_fill()

func _on_back_pressed():
	settings_panel.visible = false
	pause_panel.visible = true

func _on_restore_defaults_pressed():
	if Language: Language.lan_func_sel(1) # Arabic
	# Reset Sliders using exact Main Menu paths
	settings_panel.get_node("setter2/HSlider").value = 100
	settings_panel.get_node("setter3/HSlider").value = 80
	settings_panel.get_node("setter4/HSlider").value = 80
	settings_panel.get_node("setter5/HSlider").value = 80
	_update_text()

func _on_save_pressed():
	_on_back_pressed()

func _on_credits_pressed():
	get_tree().paused = false
	if GameManager:
		GameManager.return_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://Project_jam_UI/scenes/credits.tscn")

func _on_exit_pressed():
	pause_panel.visible = false
	exit_confirmation.visible = true
	$ExitConfirmation/Label.play_shader_fill()
	$ExitConfirmation/HBoxContainer/YesButton.in_scene()
	$ExitConfirmation/HBoxContainer/NoButton.in_scene()

func _on_yes_pressed():
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://Project_jam_UI/scenes/main_menu.tscn")

func _on_no_pressed():
	exit_confirmation.visible = false
	pause_panel.visible = true
