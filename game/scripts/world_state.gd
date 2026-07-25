extends Node

## Global flag/counter store for quest/world state (see [autoload] in
## project.godot). Deliberately just a Dictionary wrapper - no quest log UI,
## stage machine, or quest definitions here; that's M4's journal/quest-log
## work. Values are whatever JSON-safe type the caller wants (bool/int/
## float/String), since main.gd persists this store via SaveSystem as JSON.

signal flag_changed(flag: String, value: Variant)

var _flags: Dictionary = {}


func get_flag(flag: String, default: Variant = false) -> Variant:
	return _flags.get(flag, default)


func set_flag(flag: String, value: Variant) -> void:
	if _flags.get(flag) == value:
		return
	_flags[flag] = value
	flag_changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return _flags.has(flag)


func clear() -> void:
	_flags = {}


## Bulk-replaces all flags without emitting flag_changed - used when
## restoring from a save, before systems that react to flag_changed (e.g.
## main.gd's NPC wiring) have finished setting themselves up. See
## main.gd's _ready() for the load order this depends on.
func from_dict(data: Dictionary) -> void:
	_flags = data.duplicate()


func to_dict() -> Dictionary:
	return _flags.duplicate()
