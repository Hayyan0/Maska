extends Node

@export var targets := {} # Dictionary: NodePath -> String

var langugue_sel: Dictionary




func _physics_process(delta: float) -> void:
	var file = FileAccess.open(str(Language.languge_path_select), FileAccess.READ)
	if not file:
		return
	var json_string := file.get_as_text()
	langugue_sel = JSON.parse_string(json_string)
	_apply_text()


func _apply_text():
	for path: NodePath in targets.keys():
		var key: String = targets[path]

		if key == "":
			continue

		var node := get_node_or_null(path)
		if node == null:
			continue

		if node is Label or node is Button:
			node.text = langugue_sel.get(key, key)
			
		if node is TextureRect and key == "logo":
			if Language.languge_selected == "arabic":
				node.texture = load("res://assets/LOGO/LOGO.png")
			else:
				node.texture = load("res://assets/LOGO/LogoEN.png")
