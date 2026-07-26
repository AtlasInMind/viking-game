class_name GateDefinition
extends Resource

## Data-driven definition of a single conditionally-blocked map cell
## (issue #18): a cell that renders/behaves as a wall until its unlock
## condition (an item, a flag, or both - leave either blank to skip that
## check) is met, then reads as open path. Modeled as a Resource, not a
## hardcoded if-branch in main.gd, so adding another gate later is a
## matter of authoring another .tres file, the same pattern items (#17)
## and NPCs already follow.

@export var cell: Vector2i
@export var required_item_id: String = ""
@export var required_flag: String = ""


## Fails open, not closed: a gate with both fields left blank has no
## requirement to check and reads as already unlocked, rather than
## permanently stuck. Always set at least one of the two fields on a real
## gate - an empty one is a silently-inert always-open tile, not an error.
func is_unlocked() -> bool:
	if required_item_id != "" and not Inventory.has_item(required_item_id):
		return false
	if required_flag != "" and not WorldState.get_flag(required_flag):
		return false
	return true
