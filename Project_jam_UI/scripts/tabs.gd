extends Node

@export var fade_time := 0.25

@export var pages: Array[Control] = []
var current_index := -1
var tween: Tween

func _ready():
	# Ensure custom cursor is visible in menu
	if is_instance_valid(MouseDisplay):
		MouseDisplay.visible = true
	
	# Set UI Post-Processing Mode
	if is_instance_valid(PostProcessing):
		PostProcessing.set_ui_mode()

	for child in get_children():
		if child is Control:
			pages.append(child)

	if pages.is_empty():
		return

	for p in pages:
		p.visible = false
		p.modulate.a = 0.0
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE

	switch_to(0)

func switch_to(index: int):
	if index < 0 or index >= pages.size():
		return

	if index == current_index:
		return

	if tween:
		tween.kill()

	var next := pages[index]
	var prev: Control = null

	if current_index != -1:
		prev = pages[current_index]

	current_index = index

	next.visible = true
	next.modulate.a = 0.0
	next.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		next,
		"modulate:a",
		1.0,
		fade_time
	)

	
	if prev:
		tween.parallel().tween_property(
			prev,
			"modulate:a",
			0.0,
			fade_time
		)

	tween.finished.connect(func():
		if prev:
			prev.visible = false
			prev.mouse_filter = Control.MOUSE_FILTER_IGNORE

		next.mouse_filter = Control.MOUSE_FILTER_STOP
	)


func _on_button_2_pressed() -> void:
	switch_to(1)
	$"../Setting".switched()
	



func _on_button_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Project_jam_UI/scenes/IntroVideo.tscn")

func _on_button_pressed() -> void:
	switch_to(0)


func _on_button_4_pressed() -> void:
	switch_to(2)
	$"../Exit_minu/Label".play_shader_fill()
	$"../Exit_minu/yes".in_scene()
	$"../Exit_minu/no".in_scene()


func _on_no_pressed() -> void:
	switch_to(0)


func _on_yes_pressed() -> void:
	get_tree().quit()


func _on_button_3_pressed() -> void:
	switch_to(3)
	if GameManager:
		GameManager.return_scene = "res://Project_jam_UI/scenes/main_menu.tscn"
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Project_jam_UI/scenes/credits.tscn")
