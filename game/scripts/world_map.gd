extends Node

## Global visited-areas store (see [autoload] in project.godot), mirroring
## Inventory's held-items-set pattern (game/scripts/inventory.gd) for a set
## of visited AreaRegistry ids instead of held item ids - same reasoning:
## membership only, no per-area counts/metadata needed. This is the mutable
## half of the world map/fast-travel system (issue #30); AreaRegistry holds
## the static per-area data (scene path, entry cell, display name).

signal area_visited(id: String)

var _visited_area_ids: Array[String] = []


func mark_visited(id: String) -> void:
	if _visited_area_ids.has(id):
		return
	_visited_area_ids.append(id)
	area_visited.emit(id)


func is_visited(id: String) -> bool:
	return _visited_area_ids.has(id)


func get_visited_area_ids() -> Array[String]:
	return _visited_area_ids.duplicate()


func clear() -> void:
	_visited_area_ids = []


## Mirrors WorldState.from_dict()/Inventory.from_dict()'s bulk-restore-
## without-signals approach - used when restoring from a save, before
## anything that reacts to area_visited has finished setting itself up.
func from_dict(data: Dictionary) -> void:
	var ids: Array[String] = []
	if data.has("visited_area_ids") and data["visited_area_ids"] is Array:
		for id in data["visited_area_ids"]:
			if id is String:
				ids.append(id)
	_visited_area_ids = ids


func to_dict() -> Dictionary:
	return {"visited_area_ids": _visited_area_ids.duplicate()}
