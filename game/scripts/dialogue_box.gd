class_name DialogueBox
extends Panel

@onready var _label: Label = $Label

var _is_open := false


func _ready() -> void:
	visible = false


func open(text: String) -> void:
	_label.text = text
	visible = true
	_is_open = true


func close() -> void:
	visible = false
	_is_open = false


func is_open() -> bool:
	return _is_open
