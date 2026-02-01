extends Control

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	start_loading()

func _on_visibility_changed():
	if visible:
		start_loading()

func start_loading():
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
		$AnimationPlayer.play("loading")
