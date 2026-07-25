extends Node2D

## A stationary, interactable overworld NPC. Placement/collision-registration
## is owned by main.gd (see _place_npcs()); this script only holds the NPC's
## own presentation and dialogue content.

@export var dialogue_text: String = "..."
@export var facing: String = "down":
	set(value):
		facing = value
		_update_sprite_frame()
@export var facing_right: bool = true:
	set(value):
		facing_right = value
		_update_sprite_frame()

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_update_sprite_frame()


func get_dialogue_text() -> String:
	return dialogue_text


func _update_sprite_frame() -> void:
	if _sprite == null:
		return
	var row: int = {"down": 0, "side": 1, "up": 2}.get(facing, 0)
	_sprite.region_rect = Rect2(0, row * 24, 16, 24)
	_sprite.flip_h = facing == "side" and not facing_right
