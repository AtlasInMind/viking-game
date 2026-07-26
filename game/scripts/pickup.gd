class_name Pickup
extends Node2D

## A hidden, off-the-beaten-path item rewarding exploration (issue #22).
## Implements the same get_dialogue_text() interface NPCs do, so
## main.gd's existing interact handling (which only checks
## has_method("get_dialogue_text")) picks it up with no changes needed
## to that check - only a new branch for what happens once interacted
## with, matching how every other item grant in this project already
## works. Deliberately has no sprite - found by walking up and
## interacting, not by sight, matching "hidden" literally.
##
## Whether it's already been taken is read from Inventory directly, not
## a local flag - a local bool wouldn't survive a save/reload (this node
## is destroyed and recreated with every scene load), while Inventory's
## own persisted state already answers "do we have it" correctly.

@export var item_id: String = ""
@export var found_text: String = ""
@export var already_found_text: String = "Nothing more here."


func get_dialogue_text() -> String:
	if Inventory.has_item(item_id):
		return already_found_text
	return found_text
