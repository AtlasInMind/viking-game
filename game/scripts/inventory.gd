extends Node

## Global held-items store (see [autoload] in project.godot), mirroring
## WorldState's flag-store pattern (game/scripts/world_state.gd) for a
## collection of unique item ids instead of flat key/value flags. Items
## aren't stackable/counted - Act 1's items are expected to be unique
## quest/key items (see docs/WORLD_BIBLE.md), not a resource-gathering
## inventory - held_item_ids is deliberately a set-like Array, not a
## Dictionary of counts.

signal item_added(id: String)

var _held_item_ids: Array[String] = []


func add_item(id: String) -> void:
	if _held_item_ids.has(id):
		return
	_held_item_ids.append(id)
	item_added.emit(id)


func has_item(id: String) -> bool:
	return _held_item_ids.has(id)


func remove_item(id: String) -> void:
	_held_item_ids.erase(id)


func get_held_item_ids() -> Array[String]:
	return _held_item_ids.duplicate()


func clear() -> void:
	_held_item_ids = []


## Mirrors WorldState.from_dict()'s bulk-restore-without-signals approach -
## used when restoring from a save, before anything that reacts to
## item_added has finished setting itself up.
func from_dict(data: Dictionary) -> void:
	var ids: Array[String] = []
	if data.has("held_item_ids") and data["held_item_ids"] is Array:
		for id in data["held_item_ids"]:
			if id is String:
				ids.append(id)
	_held_item_ids = ids


func to_dict() -> Dictionary:
	return {"held_item_ids": _held_item_ids.duplicate()}
