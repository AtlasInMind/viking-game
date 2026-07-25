extends Control

@onready var _start_button: Button = $MenuPanel/StartButton
@onready var _continue_button: Button = $MenuPanel/ContinueButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.disabled = not SaveSystem.has_save()
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	SaveSystem.pending_load = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_continue_pressed() -> void:
	SaveSystem.pending_load = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
