extends Area2D

@export_category("Audio Settings")
@export var audio_clip: AudioStream
@export var volume_db: float = -6.0
@export var subtitle_text: String = ""

@export_category("Mode Switch Settings")
@export var trigger_mode_switch: bool = false
@export var switch_delay: float = 3.5
@export var target_mode: GameManager.GameMode = GameManager.GameMode.TOUGH

@export_category("Director Settings")
@export var director_expression: String = "Normal"

@onready var audio_player = $AudioStreamPlayer

var has_triggered = false

func _ready():
	# Ensure we have an audio player
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	
	body_entered.connect(_on_body_entered)

func _get_property_list():
	var properties = []
	properties.append({
		"name": "director_expression",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Normal,Happy,Happy2,Evil,Talking,Angry,Thinking,Explains"
	})
	return properties

func _on_body_entered(body):
	print("AudioTrigger Hit By: ", body.name)
	
	if has_triggered:
		return
		
	# Check if the player entered (body usually has name "Player" or acts as one)
	# Also check GameManager.player just in case
	var is_player = (body == GameManager.player) or (body.name == "Player")
	
	if is_player:
		has_triggered = true
		print("AudioTrigger Activated!")
		
		# Play Audio
		if audio_clip:
			audio_player.stream = audio_clip
			audio_player.volume_db = volume_db
			audio_player.play()
			
			if subtitle_text != "":
				GameManager.trigger_subtitle(subtitle_text)
		
		# Update Director
		var dir = ""
		if trigger_mode_switch:
			dir = "جمانة" if target_mode == GameManager.GameMode.CUTE else "لؤي"
		else:
			dir = GameManager.current_director
		GameManager.update_director(dir, director_expression)
		
		# Delayed Switch
		if trigger_mode_switch:
			await get_tree().create_timer(switch_delay).timeout
			# Check if mode is already correct? Or force switch?
			# User implies "Switch Style", usually meaning forcing it.
			GameManager.change_mode(target_mode)
