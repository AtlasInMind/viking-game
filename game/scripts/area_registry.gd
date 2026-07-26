class_name AreaRegistry

## Single source of truth for every explorable area's scene path and arrival
## point (issue #30) - the "lookup table" docs/DECISIONS.md's issue #19 entry
## deferred until a third consumer justified it. Until now, main.gd and
## ship.gd each hardcoded the *other* scene's entry cell locally (SHIP_ENTRY_CELL/
## VILLAGE_ENTRY_CELL) with a comment noting they had to be kept in sync by
## hand; the world map/fast-travel system is exactly that third consumer
## (issue #29's QuestFlags/QuestLog precedent: centralize a name/value the
## moment a second-or-later consumer needs it, not before), since fast travel
## has to be able to resolve *any* visited area's arrival point generically,
## not just "the other one of exactly two scenes."
##
## How a future area gets added (M5): build its scene using the existing
## hand-authored map-building pattern (see docs/DECISIONS.md's map-authoring
## entry), pick one arrival cell for it, add one entry to AREAS below, and
## call `WorldMap.mark_visited(<id>)` in that scene's _ready(). No other
## code needs to change - the world map UI, fast travel, and any new
## area-to-area walking transition all resolve scene path/entry cell/display
## name from this same table.

const VILLAGE := "village"
const SHIP := "ship"

const AREAS := [
	{"id": VILLAGE, "display_name": "Village", "scene_path": "res://scenes/main.tscn", "entry_cell": Vector2i(15, 16)},
	{"id": SHIP, "display_name": "The Ship", "scene_path": "res://scenes/ship.tscn", "entry_cell": Vector2i(8, 7)},
]


static func get_area(id: String) -> Dictionary:
	for area in AREAS:
		if area["id"] == id:
			return area
	return {}


static func get_display_name(id: String) -> String:
	return get_area(id).get("display_name", id)
