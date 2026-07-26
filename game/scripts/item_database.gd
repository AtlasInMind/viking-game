extends Node

## Global item catalog (see [autoload] in project.godot): maps an item's id
## (as stored in Inventory / save data) to its full Item definition. New
## items are added by creating an Item .tres resource under
## game/data/items/ and preloading it below - a fixed, small, hand-curated
## list rather than a runtime directory scan, since the item roster is
## authored content, not something generated/discovered at runtime.

const ITEMS: Array[Item] = [
	preload("res://data/items/placeholder_charm.tres"),
	preload("res://data/items/placeholder_stone.tres"),
	preload("res://data/items/rusted_key.tres"),
	preload("res://data/items/carved_token.tres"),
]

var _by_id: Dictionary = {}


func _ready() -> void:
	for item in ITEMS:
		_by_id[item.id] = item


func get_item(id: String) -> Item:
	return _by_id.get(id)


func has_item_definition(id: String) -> bool:
	return _by_id.has(id)
