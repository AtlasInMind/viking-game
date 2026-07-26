extends Node2D

## The returned longship (issue #19) - Act 1's second connected area, per
## docs/WORLD_BIBLE.md. Reachable from the village (game/scripts/main.gd)
## through the gap in the south treeline, past GATE. Mirrors main.gd's
## hand-authored map-building approach (issue #9) rather than inventing a
## new one: named Rects/points in code, a runtime-built TileMapLayer, no
## Tiled/TileMap-editor authoring. Deliberately has no NPCs, dialogue, or
## quest content yet - that's #20/#21's job; this issue is purely the
## area existing and being reachable.

const TILE_SIZE := 16
const SHIP_SIZE := Vector2i(18, 9)

## Same tile atlas/indices as main.gd's overworld tileset - only a subset
## is actually used here (path/water/wall/roof), but the source PNG's
## layout is shared, so the same index constants apply.
const TILE_PATH := 2
const TILE_WATER := 4
const TILE_WALL := 5
const TILE_ROOF := 6

## The hull's outer edge (gunwale) is every HULL cell not also in DECK -
## a 1-cell-thick wall automatically framing the inset, walkable deck.
const HULL := Rect2i(2, 1, 14, 6)
const DECK := Rect2i(3, 2, 12, 4)

## A small deck structure (roof tile, blocked like the village houses'
## roofs are - no interior yet, same reasoning as main.gd's TILE_DOOR
## note) - just enough for the space to read as a real ship, not an
## empty box.
const SHELTER := Rect2i(5, 3, 2, 1)

## The one way on/off the ship: a gap in the hull's south wall (row 6)
## continuing south as a gangplank across open water down to the return
## trigger. VILLAGE_ENTRY_CELL must match main.gd's TRANSITION_TO_SHIP_CELL
## neighbor - see the matching note in main.gd's SHIP_ENTRY_CELL.
const GANGPLANK_X := 8
const GANGPLANK_START_Y := 6
const RETURN_TO_VILLAGE_CELL := Vector2i(GANGPLANK_X, SHIP_SIZE.y - 1)
const VILLAGE_SCENE_PATH := "res://scenes/main.tscn"
const VILLAGE_ENTRY_CELL := Vector2i(15, 16)

## Must match main.gd's SHIP_ENTRY_CELL - this is where the player lands
## when arriving from the village. It's also this scene's own fallback
## for missing/invalid save data (see _resolve_start_position()): unlike
## VILLAGE_ENTRY_CELL (a village-space coordinate, only ever valid as an
## argument to main.gd's own _transition_to()), this one is in this
## scene's own coordinate space, so a fallback can safely use it.
const DEFAULT_ENTRY_CELL := Vector2i(GANGPLANK_X, GANGPLANK_START_Y + 1)

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player
@onready var _inventory_ui: InventoryUI = $UI/InventoryUI

var _occupied_cells: Dictionary = {}
var _inventory_key_was_pressed := false
var _tileset_source_id: int = -1


func _ready() -> void:
	# Mirrors main.gd's _load_save_if_continuing() exactly: WorldState and
	# Inventory are autoloads and already correct in memory for an
	# in-session transition from the village; pending_load only comes back
	# true for a fresh page load resuming a save that points here (either
	# a real Continue, or main.gd's own transition flipping it right
	# before changing scenes - see main.gd's _transition_to()).
	if SaveSystem.pending_load:
		SaveSystem.pending_load = false
		var loaded := SaveSystem.load_game()
		if loaded.has("flags") and loaded["flags"] is Dictionary:
			WorldState.from_dict(loaded["flags"])
		if loaded.has("inventory") and loaded["inventory"] is Dictionary:
			Inventory.from_dict(loaded["inventory"])

	_tileset_source_id = _build_tileset()
	_build_map(_tileset_source_id)

	var start := _resolve_start_position(SaveSystem.load_game())
	_player.initialize(_ground, start, TILE_SIZE, SHIP_SIZE, _occupied_cells)
	_player.moved.connect(_on_player_moved)


func _resolve_start_position(data: Dictionary) -> Vector2i:
	if not (data.has("player_x") and data.has("player_y")):
		return DEFAULT_ENTRY_CELL
	if not ((data["player_x"] is int or data["player_x"] is float) and (data["player_y"] is int or data["player_y"] is float)):
		return DEFAULT_ENTRY_CELL

	var loaded := Vector2i(int(data["player_x"]), int(data["player_y"]))
	if loaded.x < 0 or loaded.y < 0 or loaded.x >= SHIP_SIZE.x or loaded.y >= SHIP_SIZE.y:
		return DEFAULT_ENTRY_CELL
	var tile_data := _ground.get_cell_tile_data(loaded)
	if tile_data == null or tile_data.get_custom_data("blocked"):
		return DEFAULT_ENTRY_CELL
	return loaded


func _on_player_moved(grid_pos: Vector2i) -> void:
	if grid_pos == RETURN_TO_VILLAGE_CELL:
		_transition_to(VILLAGE_SCENE_PATH, VILLAGE_ENTRY_CELL)
		return
	_save_state()


func _save_state() -> void:
	var data := SaveSystem.load_game()
	data["player_x"] = _player.get_grid_pos().x
	data["player_y"] = _player.get_grid_pos().y
	data["flags"] = WorldState.to_dict()
	data["inventory"] = Inventory.to_dict()
	data["current_scene"] = scene_file_path
	SaveSystem.save_game(data)


## See main.gd's _transition_to() for the full reasoning - identical
## pattern, mirrored here rather than shared, since only two areas exist.
func _transition_to(target_scene: String, entry_cell: Vector2i) -> void:
	var data := SaveSystem.load_game()
	data["player_x"] = entry_cell.x
	data["player_y"] = entry_cell.y
	data["flags"] = WorldState.to_dict()
	data["inventory"] = Inventory.to_dict()
	data["current_scene"] = target_scene
	SaveSystem.save_game(data)
	SaveSystem.pending_load = true
	get_tree().change_scene_to_file(target_scene)


func _process(_delta: float) -> void:
	var inventory_key_pressed := Input.is_key_pressed(KEY_I)
	var just_pressed := inventory_key_pressed and not _inventory_key_was_pressed
	_inventory_key_was_pressed = inventory_key_pressed
	if not just_pressed:
		return

	if _inventory_ui.is_open():
		_inventory_ui.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	_inventory_ui.open()
	_player.set_input_enabled(false)


func _build_tileset() -> int:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tiles/overworld_tileset.png")
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for x in range(8):
		atlas.create_tile(Vector2i(x, 0))

	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "blocked")
	tile_set.set_custom_data_layer_type(0, TYPE_BOOL)

	var source_id := tile_set.add_source(atlas)
	# Water and the hull walls/roof are all impassable - there's no
	# "grass"-equivalent open tile here, open water is the default and is
	# blocked like main.gd's TILE_WATER is.
	for x in [TILE_WATER, TILE_WALL, TILE_ROOF]:
		atlas.get_tile_data(Vector2i(x, 0), 0).set_custom_data("blocked", true)

	_ground.tile_set = tile_set
	return source_id


func _build_map(source_id: int) -> void:
	for y in range(SHIP_SIZE.y):
		for x in range(SHIP_SIZE.x):
			var cell := Vector2i(x, y)
			_ground.set_cell(cell, source_id, Vector2i(_tile_for(cell), 0))


## Deliberate placements: DECK (walkable interior) is checked before HULL
## (its border) since DECK is inset by one cell on every side, and the
## gangplank check comes first so it can punch through both the hull's
## south wall and the open water beyond it in one uniform column.
func _tile_for(cell: Vector2i) -> int:
	if cell.x == GANGPLANK_X and cell.y >= GANGPLANK_START_Y:
		return TILE_PATH
	if SHELTER.has_point(cell):
		return TILE_ROOF
	if DECK.has_point(cell):
		return TILE_PATH
	if HULL.has_point(cell):
		return TILE_WALL
	return TILE_WATER
