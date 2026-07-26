class_name Item
extends Resource

## Static item definition (issue #17) - a catalog entry, not a held-item
## instance. Inventory (game/scripts/inventory.gd) stores only the id
## string per held item and looks up the full definition via
## ItemDatabase, so held-item state stays trivially JSON-serializable for
## SaveSystem, the same reasoning WorldState's flat flag store follows.

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
