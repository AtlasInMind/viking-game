extends Node2D

## The shoreline camp (issue #35) - Act 2's first new area, per
## docs/WORLD_BIBLE.md's "The Second Ship". Where Hakon's own crew made
## landfall and camped before finding the second ship, sitting between the
## ship (south, reached by boat) and the second ship's wreck (north, reached
## on foot). Mirrors ship.gd's/main.gd's hand-authored map-building approach
## (issue #9). Geography and area-to-area transitions built by issue #35;
## Hakon's placement/dialogue (see NPC_PLACEMENTS) added by issue #36 on top
## of that, using the UI shell #35 already wired so this wasn't retrofitting
## missing infrastructure. Full main-quest wiring (flags, cutscene, gating)
## is issue #37's job, still to come.

const TILE_SIZE := 16
const SHORELINE_SIZE := Vector2i(20, 16)

## Same shared tile atlas/indices as main.gd/ship.gd's tileset.
const TILE_GRASS_FLOWERS := 1
const TILE_PATH := 2
const TILE_TREE := 3
const TILE_WATER := 4

## This scene's own id in AreaRegistry (issue #30) - see main.gd's AREA_ID
## for the full reasoning.
const AREA_ID := AreaRegistry.SHORELINE_CAMP

## South edge: the sea, back toward the ship. A landing strip cuts through
## it at LANDING_X, mirroring ship.gd's own gangplank pattern exactly.
## SHIP_ENTRY_CELL matches AreaRegistry.SHORELINE_CAMP's entry_cell (the
## canonical arrival point, used here and for world-map fast travel).
const LANDING_X := 10
const TRANSITION_TO_SHIP_CELL := Vector2i(LANDING_X, SHORELINE_SIZE.y - 1)
const SHIP_ENTRY_CELL := Vector2i(LANDING_X, SHORELINE_SIZE.y - 2)

## North edge: onward on foot to the second ship's wreck. WRECK_ENTRY_CELL
## is this scene's own local arrival point for the return trip - not
## AreaRegistry's canonical entry, since this area has two neighbors (see
## area_registry.gd's note on why that's fine).
const TRANSITION_TO_WRECK_CELL := Vector2i(LANDING_X, 0)
const WRECK_ENTRY_CELL := Vector2i(LANDING_X, 1)

## Fallback for missing/invalid save data - the same cell as
## AreaRegistry's canonical entry, mirroring ship.gd's own
## DEFAULT_ENTRY_CELL reasoning.
const DEFAULT_ENTRY_CELL := SHIP_ENTRY_CELL

const NPC_SCENE := preload("res://scenes/npc.tscn")

## Hakon (issue #36, see docs/WORLD_BIBLE.md's Cast/Act 2 sections) - he
## "insists on coming along" and his memory keeps surfacing from physical
## proximity to where it happened, so he's placed here rather than left
## behind in the village. Stood off the open landing-to-wreck line (not on
## LANDING_X or the border), roughly where a hastily-broken camp would have
## been, facing the interior rather than either transition. Gunnar isn't
## placed here - see ship.gd's own NPC_PLACEMENTS comment for why.
const NPC_PLACEMENTS := [
	{"id": "hakon", "cell": Vector2i(6, 8), "facing": "side", "facing_right": true, "lines": [
		{"flag": "", "text": "We camped here. I remember the fire - we let it die rather than tend it, like leaving quick mattered more than staying warm."},
	]},
]

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player
@onready var _dialogue: DialogueBox = $UI/DialogueBox
@onready var _inventory_ui: InventoryUI = $UI/InventoryUI
@onready var _journal_ui: JournalUI = $UI/JournalUI
@onready var _world_map_ui: WorldMapUI = $UI/WorldMapUI
@onready var _cutscene: CutscenePlayer = $CutscenePlayer
@onready var _hint: Label = $UI/Hint

var _occupied_cells: Dictionary = {}
var _npcs_by_id: Dictionary = {}
var _interact_was_pressed := false
var _inventory_key_was_pressed := false
var _journal_key_was_pressed := false
var _map_key_was_pressed := false
var _tileset_source_id: int = -1


func _ready() -> void:
	_hint.add_theme_font_size_override("font_size", Settings.scaled_font_size())

	# Mirrors ship.gd's _ready() exactly - see its own comment for the full
	# reasoning on load order/idempotence.
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
	_player.initialize(_ground, start, TILE_SIZE, SHORELINE_SIZE, _occupied_cells)
	_player.moved.connect(_on_player_moved)
	WorldState.flag_changed.connect(_on_flag_changed)
	_world_map_ui.travel_requested.connect(_on_travel_requested)

	if not WorldMap.is_visited(AREA_ID):
		WorldMap.mark_visited(AREA_ID)
		_save_state()

	_cutscene.initialize(_dialogue, _player.get_camera(), _player, [_inventory_ui, _journal_ui, _world_map_ui])

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
	if loaded.x < 0 or loaded.y < 0 or loaded.x >= SHORELINE_SIZE.x or loaded.y >= SHORELINE_SIZE.y:
		return DEFAULT_ENTRY_CELL
	var tile_data := _ground.get_cell_tile_data(loaded)
	if tile_data == null or tile_data.get_custom_data("blocked"):
		return DEFAULT_ENTRY_CELL
	return loaded


func _on_player_moved(grid_pos: Vector2i) -> void:
	if grid_pos == TRANSITION_TO_SHIP_CELL:
		_transition_to_area(AreaRegistry.SHIP)
		return
	if grid_pos == TRANSITION_TO_WRECK_CELL:
		_transition_to_area(AreaRegistry.SECOND_SHIP)
		return
	_save_state()


func _on_flag_changed(_flag: String, _value: Variant) -> void:
	_update_hint()
	_save_state()


func _update_hint() -> void:
	_hint.text = "%s\n%s" % [Settings.controls_hint_text(), QuestLog.get_current_objective()]


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
## pattern, mirrored here rather than shared.
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


## Mirrors ship.gd's _process_interact() - Hakon (issue #36) is the only
## NPC here, no quest-flag side effects yet (that's issue #37's job, same
## as ship.gd's Gunnar branch was added by #21 after #20 placed him).
func _process_interact() -> void:
	var interact_pressed := Input.is_action_pressed("interact")
	var just_pressed := interact_pressed and not _interact_was_pressed
	_interact_was_pressed = interact_pressed
	if not just_pressed or _inventory_ui.is_open() or _journal_ui.is_open() or _world_map_ui.is_open():
		return

	if _cutscene.is_playing():
		_cutscene.advance()
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


func _process_inventory_toggle() -> void:
	var inventory_key_pressed := Input.is_action_pressed("toggle_inventory")
	var just_pressed := inventory_key_pressed and not _inventory_key_was_pressed
	_inventory_key_was_pressed = inventory_key_pressed
	if not just_pressed or _dialogue.is_open() or _journal_ui.is_open() or _world_map_ui.is_open() or _cutscene.is_playing():
		return

	if _inventory_ui.is_open():
		_inventory_ui.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	_inventory_ui.open()
	_player.set_input_enabled(false)


func _process_journal_toggle() -> void:
	var journal_key_pressed := Input.is_action_pressed("toggle_journal")
	var just_pressed := journal_key_pressed and not _journal_key_was_pressed
	_journal_key_was_pressed = journal_key_pressed
	if not just_pressed or _dialogue.is_open() or _inventory_ui.is_open() or _world_map_ui.is_open() or _cutscene.is_playing():
		return

	if _journal_ui.is_open():
		_journal_ui.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	_journal_ui.open()
	_player.set_input_enabled(false)


func _process_map_toggle() -> void:
	var map_key_pressed := Input.is_action_pressed("toggle_map")
	var just_pressed := map_key_pressed and not _map_key_was_pressed
	_map_key_was_pressed = map_key_pressed
	if not just_pressed or _dialogue.is_open() or _inventory_ui.is_open() or _journal_ui.is_open() or _cutscene.is_playing():
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
	atlas.get_tile_data(Vector2i(TILE_TREE, 0), 0).set_custom_data("blocked", true)
	atlas.get_tile_data(Vector2i(TILE_WATER, 0), 0).set_custom_data("blocked", true)

	_ground.tile_set = tile_set
	return source_id


func _build_map(source_id: int) -> void:
	for y in range(SHORELINE_SIZE.y):
		for x in range(SHORELINE_SIZE.x):
			var cell := Vector2i(x, y)
			_ground.set_cell(cell, source_id, Vector2i(_tile_for(cell), 0))


## The landing/onward cuts are checked before the border fill, same
## priority reasoning as ship.gd's gangplank check - south border is the
## sea (TILE_WATER, blocked), the other three sides are treeline/driftwood
## (TILE_TREE, blocked), and open ground reuses TILE_PATH as a placeholder
## "sand" tone (no new tile art invented for this issue - see docs/ART_BIBLE.md's
## "placeholder art is fine early" stance) with sparse TILE_GRASS_FLOWERS
## patches standing in for dune grass.
func _tile_for(cell: Vector2i) -> int:
	if cell.x == LANDING_X and (cell.y == 0 or cell.y == SHORELINE_SIZE.y - 1):
		return TILE_PATH
	var on_border := cell.x == 0 or cell.y == 0 or cell.x == SHORELINE_SIZE.x - 1 or cell.y == SHORELINE_SIZE.y - 1
	if on_border:
		if cell.y == SHORELINE_SIZE.y - 1:
			return TILE_WATER
		return TILE_TREE
	if (cell.x + cell.y) % 5 == 0:
		return TILE_GRASS_FLOWERS
	return TILE_PATH
