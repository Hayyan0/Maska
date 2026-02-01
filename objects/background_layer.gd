extends CanvasLayer

@export var texture_cute: Texture2D
@export var texture_tough: Texture2D
@export var texture_natural: Texture2D

@onready var texture_rect = $TextureRect

func _ready():
	# Connect to the global brain
	GameManager.mode_changed.connect(_on_mode_changed)
	
	# Initial setup
	_on_mode_changed(GameManager.current_mode)

func _on_mode_changed(mode):
	match mode:
		GameManager.GameMode.CUTE:
			texture_rect.texture = texture_cute
		GameManager.GameMode.TOUGH:
			texture_rect.texture = texture_tough
		GameManager.GameMode.NATURAL:
			texture_rect.texture = texture_natural
