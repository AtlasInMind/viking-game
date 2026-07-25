extends Control

@onready var _start_button: Button = $MenuPanel/StartButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
