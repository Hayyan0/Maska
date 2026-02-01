extends CanvasLayer

@onready var head_icon = $MarginContainer/HBoxContainer/HeadIcon
@onready var hearts_container = $MarginContainer/HBoxContainer/HeartsContainer
@onready var director_face = $DirectorCam/FrameRatio/DirectorMargin/SpriteClipper/FaceCam
@onready var director_cover = $DirectorCam/FrameRatio/Cover
@onready var director_bg = $DirectorCam/FrameRatio/DirectorMargin/SpriteClipper/BgColor
@onready var subtitle_label = $SubtitleLabel

# Textures
const HEAD_CUTE = preload("res://assets/Cute Head.png")
const HEAD_TOUGH = preload("res://assets/Tough Head.png")
const HEART_FULL = preload("res://assets/Heart.png")
const HEART_DEAD = preload("res://assets/Dead Heart.png")

const COVER_CUTE = preload("res://assets/CuteCover.png")
const COVER_TOUGH = preload("res://assets/Tough Cover.png")

const COLOR_CUTE = Color("#f5d1d6")
const COLOR_TOUGH = Color("#cbd6f0")

var heart_nodes: Array[TextureRect] = []
var show_director = true

func _ready():
	_setup_hearts()
	
	if GameManager:
		GameManager.mode_changed.connect(_on_mode_changed)
		GameManager.health_changed.connect(_on_health_changed)
		GameManager.director_updated.connect(_on_director_updated)
		GameManager.subtitle_triggered.connect(_on_subtitle_triggered)
		# Initialize
		_on_mode_changed(GameManager.current_mode)
		_on_health_changed(GameManager.health, GameManager.max_health)
		_on_director_updated(GameManager.current_director, GameManager.current_expression)

func _setup_hearts():
	# Clear existing
	for child in hearts_container.get_children():
		child.queue_free()
	heart_nodes.clear()
	
	# Create 3 hearts (or whatever max_health is)
	for i in range(3):
		var heart = TextureRect.new()
		heart.texture = HEART_FULL
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(48, 48) # Smaller hearts (was 64)
		hearts_container.add_child(heart)
		heart_nodes.append(heart)

func _on_mode_changed(mode):
	# Update Head Icon
	match mode:
		GameManager.GameMode.CUTE:
			head_icon.texture = HEAD_CUTE
			director_cover.texture = COVER_CUTE
			director_bg.color = COLOR_CUTE
			visible = true
		GameManager.GameMode.TOUGH:
			head_icon.texture = HEAD_TOUGH
			director_cover.texture = COVER_TOUGH
			director_bg.color = COLOR_TOUGH
			visible = true
		GameManager.GameMode.NATURAL:
			visible = false 

	# Director logic: Cute Mode -> Jumana, Tough Mode -> Luay
	var new_director = "Jumana" if mode == GameManager.GameMode.CUTE else "Luay"
	if mode != GameManager.GameMode.NATURAL:
		GameManager.update_director(new_director, "Normal")
	
	$DirectorCam.visible = show_director and (mode != GameManager.GameMode.NATURAL)

func _on_director_updated(director_name, expression):
	var path = "res://assets/Directors/" + director_name + "/" + expression + ".png"
	
	# ResourceLoader.exists is more reliable in exported builds than FileAccess.file_exists
	if ResourceLoader.exists(path):
		director_face.texture = load(path)
	else:
		# Fallback to Normal if expression doesn't exist
		var fallback_path = "res://assets/Directors/" + director_name + "/Normal.png"
		if ResourceLoader.exists(fallback_path):
			director_face.texture = load(fallback_path)
		else:
			print("UI ERROR: Could not find expression or fallback for: ", director_name)

func _on_health_changed(current_health, max_health):
	for i in range(heart_nodes.size()):
		if i < current_health:
			heart_nodes[i].texture = HEART_FULL
		else:
			heart_nodes[i].texture = HEART_DEAD

func _on_subtitle_triggered(text: String, duration: float):
	if text == "":
		subtitle_label.visible = false
		return
		
	subtitle_label.text = text
	subtitle_label.visible = true
	
	# Reset timer if already running
	var timer = get_tree().create_timer(duration)
	await timer.timeout
	
	# Only hide if the text hasn't changed (to avoid hiding new subtitles too early)
	if subtitle_label.text == text:
		subtitle_label.visible = false
