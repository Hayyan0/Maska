extends Control

func switched():
	$Label.play_shader_fill()
	$setter.play_shader_fill()
	$setter2.play_shader_fill()
	$setter3.play_shader_fill()
	$setter4.play_shader_fill()
	$setter5.play_shader_fill()
	$setter/Button.in_scene()
	$setter/Button2.in_scene()


func _on_button_pressed() -> void:
	switched()
	Language.lan_func_sel(1)
	


func _on_button_2_pressed() -> void:
	switched()
	Language.lan_func_sel(0)


func _on_restore_defaults_pressed() -> void:
	switched()
	# Reset Language to Arabic (default)
	Language.lan_func_sel(1)
	
	# Reset Sliders
	# Check if nodes exist before accessing
	if has_node("setter2/HSlider"): $setter2/HSlider.value = 100
	if has_node("setter3/HSlider"): $setter3/HSlider.value = 80
	if has_node("setter4/HSlider"): $setter4/HSlider.value = 80
	if has_node("setter5/HSlider"): $setter5/HSlider.value = 80

	
