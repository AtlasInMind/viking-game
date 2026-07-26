class_name InventoryUI
extends Panel

## Minimal inventory panel (issue #17) - lists held items' names/
## descriptions as plain text. Placeholder visuals only; M2's art pipeline
## re-skins this later, same as the rest of the M1 slice was in #13.

@onready var _label: Label = $Label

var _is_open := false


func _ready() -> void:
	visible = false


func open() -> void:
	refresh()
	visible = true
	_is_open = true


func close() -> void:
	visible = false
	_is_open = false


func is_open() -> bool:
	return _is_open


## Rebuilds the displayed text from Inventory's current held items -
## called on open() rather than kept continuously in sync, since nothing
## needs to see inventory changes while the panel is closed.
func refresh() -> void:
	var held_ids := Inventory.get_held_item_ids()
	if held_ids.is_empty():
		_label.text = "(empty)"
		return

	var lines: Array[String] = []
	for id in held_ids:
		var item := ItemDatabase.get_item(id)
		if item == null:
			continue
		lines.append("- %s" % item.display_name)
	_label.text = "\n".join(lines)
