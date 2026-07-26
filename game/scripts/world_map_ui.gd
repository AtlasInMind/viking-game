class_name WorldMapUI
extends Panel

## World map/fast-travel panel (issue #30) - mirrors inventory_ui.gd/
## journal_ui.gd's open/close/refresh pattern. Unlike those two (plain text
## views), this panel needs an actual action per row (travel there), not
## just information, so it builds one Button per visited AreaRegistry entry
## instead of a single Label - the current area's button is shown disabled
## rather than omitted, so the panel always shows "where you are" alongside
## "where you can go." Areas never visited are omitted entirely (not shown
## greyed-out/locked) - the acceptance criteria are explicit that the map
## should only ever show areas the player has actually been to.

signal travel_requested(area_id: String)

@onready var _list: VBoxContainer = $ScrollContainer/VBoxContainer

var _is_open := false


func _ready() -> void:
	visible = false


func open(current_area_id: String) -> void:
	refresh(current_area_id)
	visible = true
	_is_open = true


func close() -> void:
	visible = false
	_is_open = false


func is_open() -> bool:
	return _is_open


func refresh(current_area_id: String) -> void:
	for child in _list.get_children():
		child.queue_free()

	for area in AreaRegistry.AREAS:
		var id: String = area["id"]
		if not WorldMap.is_visited(id):
			continue
		var button := Button.new()
		if id == current_area_id:
			button.text = "%s (you are here)" % area["display_name"]
			button.disabled = true
		else:
			button.text = "Travel to %s" % area["display_name"]
			button.pressed.connect(_on_travel_pressed.bind(id))
		_list.add_child(button)


func _on_travel_pressed(id: String) -> void:
	close()
	travel_requested.emit(id)
