@tool
extends Resource
class_name SequenceEvent

@export var time_offset: float = 0.0
@export_multiline var subtitle_text: String = ""
@export var change_mode: bool = false:
	set(val):
		change_mode = val
		notify_property_list_changed()
@export var target_mode: GameManager.GameMode = GameManager.GameMode.TOUGH
@export var director_expression: String = "Normal"

func _validate_property(property: Dictionary):
	if property.name == "director_expression":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = "Normal,Happy,Happy2,Evil,Talking,Angry,Thinking,Explains"
	
	if property.name == "target_mode" and not change_mode:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _to_string():
	return "Event @ %.2fs: %s" % [time_offset, subtitle_text.left(20)]
