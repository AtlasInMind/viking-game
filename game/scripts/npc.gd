extends Node2D

## A stationary, interactable overworld NPC. Placement/collision-registration
## is owned by main.gd/ship.gd (see _place_npcs()); this script only holds
## the NPC's own presentation and dialogue content.
##
## dialogue_lines (issue #20) replaces a single fixed dialogue_text (M1):
## an ordered array of {"flag": String, "value": Variant, "text": String}
## dicts. get_dialogue_text() returns the first entry whose flag is unset
## (an always-true fallback - list these last) or matches WorldState,
## picked live on every call - not main.gd reaching in after the fact to
## overwrite an NPC's line on every relevant flag change, which stopped
## scaling once there was more than one NPC with more than one line (see
## docs/DECISIONS.md for the two special-cases this replaced).

## Plain Array, not Array[Dictionary] - it's assigned directly from
## main.gd/ship.gd's NPC_PLACEMENTS entries, which are themselves plain
## untyped dictionaries (matching that existing style), and Godot won't
## implicitly convert an untyped Array into a strictly-typed Array[T].
@export var dialogue_lines: Array = []
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
	for line in dialogue_lines:
		var flag: String = line.get("flag", "")
		if flag == "" or WorldState.get_flag(flag) == line.get("value", true):
			return line.get("text", "...")
	return "..."


func _update_sprite_frame() -> void:
	if _sprite == null:
		return
	var row: int = {"down": 0, "side": 1, "up": 2}.get(facing, 0)
	_sprite.region_rect = Rect2(0, row * 24, 16, 24)
	_sprite.flip_h = facing == "side" and not facing_right
