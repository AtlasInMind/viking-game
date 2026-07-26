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
	WorldState.clear()
	Inventory.clear()
	WorldMap.clear()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## A save can now point at any area (issue #19's area transitions stamp
## their own scene into "current_scene", the same field this reads) - a
## missing/invalid value defensively falls back to the village, the same
## way _resolve_start_position() in main.gd falls back to the default
## spawn on invalid position data.
func _on_continue_pressed() -> void:
	SaveSystem.pending_load = true
	var data := SaveSystem.load_game()
	var target_scene: Variant = data.get("current_scene", "res://scenes/main.tscn")
	if not (target_scene is String) or not ResourceLoader.exists(target_scene):
		target_scene = "res://scenes/main.tscn"
	get_tree().change_scene_to_file(target_scene)
