extends Node2D

## The returned longship (issue #19) - Act 1's second connected area, per
## docs/WORLD_BIBLE.md. Reachable from the village (game/scripts/main.gd)
## through the gap in the south treeline, past GATE. Mirrors main.gd's
## hand-authored map-building approach (issue #9) rather than inventing a
## new one: named Rects/points in code, a runtime-built TileMapLayer, no
## Tiled/TileMap-editor authoring. Gunnar (issue #20) is placed here
## rather than in the village, examining the ship's own cargo - the one
## place his line about it is actually true.

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

## This scene's own id in AreaRegistry (issue #30) - see main.gd's AREA_ID
## for the full reasoning.
const AREA_ID := AreaRegistry.SHIP

## The one way on/off the ship: a gap in the hull's south wall (row 6)
## continuing south as a gangplank across open water down to the return
## trigger. The village's scene/entry cell now resolve through AreaRegistry
## (issue #30) instead of a locally-hardcoded VILLAGE_ENTRY_CELL - see that
## file for why.
const GANGPLANK_X := 8
const GANGPLANK_START_Y := 6
const RETURN_TO_VILLAGE_CELL := Vector2i(GANGPLANK_X, SHIP_SIZE.y - 1)

## Must match AreaRegistry.SHIP's entry_cell - this is where the player
## lands when arriving from the village. It's also this scene's own
## fallback for missing/invalid save data (see _resolve_start_position()):
## unlike AreaRegistry.VILLAGE's entry_cell (a village-space coordinate,
## only ever valid as an argument to main.gd's own _transition_to()), this
## one is in this scene's own coordinate space, so a fallback can safely
## use it.
const DEFAULT_ENTRY_CELL := Vector2i(GANGPLANK_X, GANGPLANK_START_Y + 1)

const NPC_SCENE := preload("res://scenes/npc.tscn")

## Gunnar stands on deck near the shelter (not inside it - no interior
## exists, same reasoning as main.gd's house roofs), examining the
## recovered cargo stored there.
const NPC_PLACEMENTS := [
	{"id": "gunnar", "cell": Vector2i(7, 4), "facing": "up", "lines": [
		{"flag": "", "text": "This oil, this cloth - none of it's from anywhere I've traded. Whoever they met on that voyage, it wasn't on any route I know."},
	]},
]

## The ship's own challenge-layer beat (issue #21) - the same "hold
## still" mechanic issue #10 built (game/scripts/cairn_encounter.gd),
## reused rather than reinvented (as the MemoryEncounter node instance in
## ship.tscn, not instantiated here), reframed as a fragment of the
## crew's own fear surfacing near where they stood. Placed at the deck's
## far end from Gunnar/the gangplank, clear of SHELTER and the entry path.
##
## Deliberately ungated on QuestFlags.TALKED_TO_GUNNAR - purely spatial,
## same as CAIRN_TRIGGER_CELL in main.gd has no prerequisite either.
## Reaching it before talking to Gunnar skips the Hint's intermediate
## nudge but nothing breaks; Act 1 is exploratory, not a hard gate on
## visiting every beat in a fixed order.
const MEMORY_TRIGGER_CELL := Vector2i(12, 4)
const MEMORY_PUSH_BACK_CELL := Vector2i(10, 4)

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player
@onready var _dialogue: DialogueBox = $UI/DialogueBox
@onready var _inventory_ui: InventoryUI = $UI/InventoryUI
@onready var _journal_ui: JournalUI = $UI/JournalUI
@onready var _world_map_ui: WorldMapUI = $UI/WorldMapUI
@onready var _memory_encounter: Node2D = $MemoryEncounter
@onready var _hint: Label = $UI/Hint

var _occupied_cells: Dictionary = {}
var _npcs_by_id: Dictionary = {}
var _interact_was_pressed := false
var _inventory_key_was_pressed := false
var _journal_key_was_pressed := false
var _map_key_was_pressed := false
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
		if loaded.has("world_map") and loaded["world_map"] is Dictionary:
			WorldMap.from_dict(loaded["world_map"])

	_tileset_source_id = _build_tileset()
	_build_map(_tileset_source_id)
	_place_npcs()

	var start := _resolve_start_position(SaveSystem.load_game())
	_player.initialize(_ground, start, TILE_SIZE, SHIP_SIZE, _occupied_cells)
	_player.moved.connect(_on_player_moved)
	WorldState.flag_changed.connect(_on_flag_changed)
	_world_map_ui.travel_requested.connect(_on_travel_requested)

	# See main.gd's identical block for why this is idempotent-safe and
	# saved immediately.
	if not WorldMap.is_visited(AREA_ID):
		WorldMap.mark_visited(AREA_ID)
		_save_state()

	_memory_encounter.initialize(_player, MEMORY_TRIGGER_CELL, MEMORY_PUSH_BACK_CELL, WorldState.get_flag(QuestFlags.MEMORY_SURFACED))
	_memory_encounter.succeeded.connect(_on_memory_encounter_succeeded)
	_memory_encounter.failed.connect(_on_memory_encounter_failed)

	_update_hint()


func _place_npcs() -> void:
	for placement in NPC_PLACEMENTS:
		var npc := NPC_SCENE.instantiate()
		add_child(npc)
		npc.facing = placement["facing"]
		npc.facing_right = placement.get("facing_right", true)
		npc.dialogue_lines = placement["lines"]
		npc.position = _grid_to_world(placement["cell"])
		_occupied_cells[placement["cell"]] = npc
		_npcs_by_id[placement["id"]] = npc


func _grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE)


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
		_transition_to_area(AreaRegistry.VILLAGE)
		return
	_save_state()


func _on_flag_changed(_flag: String, _value: Variant) -> void:
	_update_hint()
	_save_state()


## Now a thin wrapper over quest_log.gd's single shared implementation
## (issue #29), same as main.gd's _update_hint() - the two are identical
## now, resolving the "one branch doesn't need mirroring" caveat issue #25
## left on this function (see docs/DECISIONS.md): both scripts call the
## exact same QuestLog.get_current_objective(), so there's no divergent
## logic left to keep in sync by hand.
func _update_hint() -> void:
	_hint.text = "Arrow keys or WASD to move, Space to talk, I for inventory, J for journal, M for map\n%s" % QuestLog.get_current_objective()


func _on_memory_encounter_succeeded() -> void:
	WorldState.set_flag(QuestFlags.MEMORY_SURFACED, true)
	_dialogue.open("For a moment you're not sure whose fear that was - yours, or someone else's, still standing on this deck.")
	_player.set_input_enabled(false)


func _on_memory_encounter_failed() -> void:
	_dialogue.open("You flinch, and whatever it was slips back into the corner of your eye. Best to hold still, if you want to see it through.")
	_player.set_input_enabled(false)


func _save_state() -> void:
	var data := SaveSystem.load_game()
	data["player_x"] = _player.get_grid_pos().x
	data["player_y"] = _player.get_grid_pos().y
	data["flags"] = WorldState.to_dict()
	data["inventory"] = Inventory.to_dict()
	data["world_map"] = WorldMap.to_dict()
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
	data["world_map"] = WorldMap.to_dict()
	data["current_scene"] = target_scene
	SaveSystem.save_game(data)
	SaveSystem.pending_load = true
	get_tree().change_scene_to_file(target_scene)


## See main.gd's _transition_to_area() for the full reasoning - identical
## pattern, mirrored here rather than shared, same as _transition_to() above.
func _transition_to_area(area_id: String) -> void:
	var area := AreaRegistry.get_area(area_id)
	_transition_to(area["scene_path"], area["entry_cell"])


func _on_travel_requested(area_id: String) -> void:
	_transition_to_area(area_id)


func _process(_delta: float) -> void:
	_process_interact()
	_process_inventory_toggle()
	_process_journal_toggle()
	_process_map_toggle()


## Mirrors main.gd's _process_interact(), trimmed - no items/gates/quest
## flags here yet, just NPC dialogue.
func _process_interact() -> void:
	var interact_pressed := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)
	var just_pressed := interact_pressed and not _interact_was_pressed
	_interact_was_pressed = interact_pressed
	if not just_pressed or _inventory_ui.is_open() or _journal_ui.is_open() or _world_map_ui.is_open():
		return

	if _dialogue.is_open():
		_dialogue.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	var target: Vector2i = _player.get_grid_pos() + _player.get_facing_direction()
	var npc: Variant = _occupied_cells.get(target)
	if npc and npc.has_method("get_dialogue_text"):
		_dialogue.open(npc.get_dialogue_text())
		_player.set_input_enabled(false)
		if npc == _npcs_by_id.get("gunnar"):
			WorldState.set_flag(QuestFlags.TALKED_TO_GUNNAR, true)


func _process_inventory_toggle() -> void:
	var inventory_key_pressed := Input.is_key_pressed(KEY_I)
	var just_pressed := inventory_key_pressed and not _inventory_key_was_pressed
	_inventory_key_was_pressed = inventory_key_pressed
	if not just_pressed or _dialogue.is_open() or _journal_ui.is_open() or _world_map_ui.is_open():
		return

	if _inventory_ui.is_open():
		_inventory_ui.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	_inventory_ui.open()
	_player.set_input_enabled(false)


## Mirrors _process_inventory_toggle() exactly (issue #29).
func _process_journal_toggle() -> void:
	var journal_key_pressed := Input.is_key_pressed(KEY_J)
	var just_pressed := journal_key_pressed and not _journal_key_was_pressed
	_journal_key_was_pressed = journal_key_pressed
	if not just_pressed or _dialogue.is_open() or _inventory_ui.is_open() or _world_map_ui.is_open():
		return

	if _journal_ui.is_open():
		_journal_ui.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	_journal_ui.open()
	_player.set_input_enabled(false)


## Mirrors _process_inventory_toggle()/_process_journal_toggle() (issue #30).
func _process_map_toggle() -> void:
	var map_key_pressed := Input.is_key_pressed(KEY_M)
	var just_pressed := map_key_pressed and not _map_key_was_pressed
	_map_key_was_pressed = map_key_pressed
	if not just_pressed or _dialogue.is_open() or _inventory_ui.is_open() or _journal_ui.is_open():
		return

	if _world_map_ui.is_open():
		_world_map_ui.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	_world_map_ui.open(AREA_ID)
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
