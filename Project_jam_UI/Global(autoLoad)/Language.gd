extends Node

var languge_path = "res://Project_jam_UI/json/Language/"
var languge_selected = "arabic"
var languge_path_select = ""


func _physics_process(delta: float) -> void:
	languge_path_select = str(languge_path,languge_selected,".json")

var _cache_data = {}
var _last_lang = ""

func text(key: String) -> String:
	if languge_selected != _last_lang:
		_load_language()
	
	if _cache_data.has(key):
		return _cache_data[key]
	return key

func _load_language():
	_last_lang = languge_selected
	var path = str(languge_path, languge_selected, ".json")
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			_cache_data = json.data
		else:
			print("JSON Parse Error: ", json.get_error_message())
	else:
		print("Language File Not Found: ", path)

func lan_func_sel(index_lan: int):
	if index_lan == 0:
		languge_selected = "english"
	if index_lan == 1:
		languge_selected = "arabic"
	# Force reload next time text() is called
	_last_lang = ""

