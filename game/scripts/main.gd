extends Node2D

## Builds a small explorable overworld at runtime (tileset + tilemap) and
## hands it to the player. The tileset itself is still constructed at
## runtime (see _build_tileset()), but the map layout below (issue #9) is
## hand-authored - a deliberately placed crossroads village, not algorithmic
## generation. See docs/DECISIONS.md for why this is authored as named
## rects/points in code rather than in Tiled or Godot's TileMap editor.

const TILE_SIZE := 16
const MAP_SIZE := Vector2i(30, 18)

const TILE_GRASS := 0
const TILE_GRASS_FLOWERS := 1
const TILE_PATH := 2
const TILE_TREE := 3
const TILE_WATER := 4
const TILE_WALL := 5
const TILE_ROOF := 6
const TILE_DOOR := 7

## The village crossroads sits at the map's exact center, so the existing
## default-spawn logic (MAP_SIZE / 2, see _resolve_start_position()) already
## lands the player on it without duplicating the coordinates.
const PATH_X := MAP_SIZE.x / 2
const PATH_Y := MAP_SIZE.y / 2

const HOUSE_A_ROOF := Rect2i(5, 4, 3, 1)
const HOUSE_A_WALL := Rect2i(5, 5, 3, 1)
const HOUSE_A_DOOR := Vector2i(6, 5)

const HOUSE_B_ROOF := Rect2i(21, 4, 3, 1)
const HOUSE_B_WALL := Rect2i(21, 5, 3, 1)
const HOUSE_B_DOOR := Vector2i(22, 5)

const POND := Rect2i(3, 11, 4, 3)

const NPC_SCENE := preload("res://scenes/npc.tscn")

## World-state flag demonstrating cross-system reactivity (issue #8): set
## when the player first asks the cairn NPC about the cairn, checked by the
## water NPC's dialogue - a flag changing behavior somewhere else entirely,
## not just an NPC remembering its own conversation.
const FLAG_ASKED_ABOUT_CAIRN := "asked_about_cairn"
const WATER_NPC_DEFAULT_TEXT := "Careful near the water after dark. My grandmother never let us go near it then."
const WATER_NPC_FOLLOWUP_TEXT := "Asking about the cairn again? Some say lights move up there at night."

## cairn_npc stands beside the road (not on it - the road is one tile wide,
## and issue #10 needs the player able to walk past them to reach the
## trigger cell further north), facing east toward it. water_npc stands
## beside the pond. Both placed where their dialogue actually makes sense,
## unlike the arbitrary path-adjacent spots the procedural map only had
## room for.
const NPC_PLACEMENTS := [
	{"id": "cairn_npc", "cell": Vector2i(PATH_X - 1, 3), "facing": "side", "text": "The path north leads up toward the old cairn, if the weather holds."},
	{"id": "water_npc", "cell": Vector2i(7, 12), "facing": "down", "text": WATER_NPC_DEFAULT_TEXT},
]

## Challenge-layer prototype (issue #10): stepping onto CAIRN_TRIGGER_CELL,
## further up the road past cairn_npc, starts the "hold still" encounter;
## failing pushes the player back to CAIRN_PUSH_BACK_CELL (south of the
## trigger, clear of cairn_npc and the crossroads) to retry.
const FLAG_CAIRN_LIGHT_PASSED := "cairn_light_passed"
const CAIRN_TRIGGER_CELL := Vector2i(PATH_X, 1)
const CAIRN_PUSH_BACK_CELL := Vector2i(PATH_X, 3)

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player
@onready var _cairn_encounter: Node2D = $CairnEncounter
@onready var _dialogue: DialogueBox = $UI/DialogueBox
@onready var _inventory_ui: InventoryUI = $UI/InventoryUI

var _occupied_cells: Dictionary = {}
var _npcs_by_id: Dictionary = {}
var _interact_was_pressed := false
var _inventory_key_was_pressed := false


func _ready() -> void:
	# Load save data (and restore WorldState from it) before placing NPCs,
	# so a continued game's NPCs reflect prior flag state from their very
	# first frame instead of only updating reactively on the next change.
	var save_data := _load_save_if_continuing()

	var source_id := _build_tileset()
	_build_map(source_id)
	_place_npcs()

	var start := _resolve_start_position(save_data)
	_player.initialize(_ground, start, TILE_SIZE, MAP_SIZE, _occupied_cells)
	_player.moved.connect(_on_player_moved)
	WorldState.flag_changed.connect(_on_flag_changed)

	_cairn_encounter.initialize(_player, CAIRN_TRIGGER_CELL, CAIRN_PUSH_BACK_CELL, WorldState.get_flag(FLAG_CAIRN_LIGHT_PASSED))
	_cairn_encounter.succeeded.connect(_on_cairn_encounter_succeeded)
	_cairn_encounter.failed.connect(_on_cairn_encounter_failed)


## Continue (see title_screen.gd) sets SaveSystem.pending_load before
## changing to this scene; Start leaves it false (and clears WorldState
## itself), so a fresh game never needs the player to manually clear a
## save. The flag is consumed here (reset to false) so it can't leak into
## a later session.
func _load_save_if_continuing() -> Dictionary:
	if not SaveSystem.pending_load:
		return {}
	SaveSystem.pending_load = false
	var data := SaveSystem.load_game()
	if data.has("flags") and data["flags"] is Dictionary:
		WorldState.from_dict(data["flags"])
	if data.has("inventory") and data["inventory"] is Dictionary:
		Inventory.from_dict(data["inventory"])
	return data


func _resolve_start_position(data: Dictionary) -> Vector2i:
	var default_start := Vector2i(MAP_SIZE.x / 2, MAP_SIZE.y / 2)
	if not (data.has("player_x") and data.has("player_y")):
		return default_start
	if not ((data["player_x"] is int or data["player_x"] is float) and (data["player_y"] is int or data["player_y"] is float)):
		return default_start

	var loaded := Vector2i(int(data["player_x"]), int(data["player_y"]))
	if loaded.x < 0 or loaded.y < 0 or loaded.x >= MAP_SIZE.x or loaded.y >= MAP_SIZE.y:
		return default_start
	if _occupied_cells.has(loaded):
		return default_start
	var tile_data := _ground.get_cell_tile_data(loaded)
	if tile_data == null or tile_data.get_custom_data("blocked"):
		return default_start
	return loaded


func _on_player_moved(_grid_pos: Vector2i) -> void:
	_save_state()


## Any flag change gets persisted immediately, not just on movement -
## talking to an NPC doesn't require the player to also take a step before
## the resulting state change survives a reload.
func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == FLAG_ASKED_ABOUT_CAIRN and value:
		var water_npc: Variant = _npcs_by_id.get("water_npc")
		if water_npc:
			water_npc.dialogue_text = WATER_NPC_FOLLOWUP_TEXT
	_save_state()


func _on_cairn_encounter_succeeded() -> void:
	WorldState.set_flag(FLAG_CAIRN_LIGHT_PASSED, true)
	_dialogue.open("The light drifts on past the stones. Whatever it was, it didn't seem to mind you.")
	_player.set_input_enabled(false)


func _on_cairn_encounter_failed() -> void:
	_dialogue.open("You flinch, and the light flares - gone before you can look at it straight. Best to hold still, next time.")
	_player.set_input_enabled(false)


## Load-merge-save rather than overwrite, so this and the position-save in
## _on_player_moved() don't clobber each other's fields (see the note on
## SaveSystem.save_game()).
func _save_state() -> void:
	var data := SaveSystem.load_game()
	data["player_x"] = _player.get_grid_pos().x
	data["player_y"] = _player.get_grid_pos().y
	data["flags"] = WorldState.to_dict()
	data["inventory"] = Inventory.to_dict()
	SaveSystem.save_game(data)


func _process(_delta: float) -> void:
	_process_interact()
	_process_inventory_toggle()


func _process_interact() -> void:
	var interact_pressed := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)
	var just_pressed := interact_pressed and not _interact_was_pressed
	_interact_was_pressed = interact_pressed
	if not just_pressed or _inventory_ui.is_open():
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
		if npc == _npcs_by_id.get("cairn_npc"):
			WorldState.set_flag(FLAG_ASKED_ABOUT_CAIRN, true)
			# Placeholder items proving issue #17's inventory system
			# end-to-end, granted via an existing interaction rather than
			# new world content - not real Act 1 items, see #21.
			Inventory.add_item("placeholder_charm")
			Inventory.add_item("placeholder_stone")
			# set_flag() above already triggered one _save_state() via
			# _on_flag_changed(), but that ran before these items were
			# added - save again so the grant survives immediately
			# rather than only on the player's next step.
			_save_state()


## Toggling the inventory panel is mutually exclusive with dialogue - it
## won't open mid-conversation, and talking is blocked while it's open
## (see the _inventory_ui.is_open() guard in _process_interact()).
func _process_inventory_toggle() -> void:
	var inventory_key_pressed := Input.is_key_pressed(KEY_I)
	var just_pressed := inventory_key_pressed and not _inventory_key_was_pressed
	_inventory_key_was_pressed = inventory_key_pressed
	if not just_pressed or _dialogue.is_open():
		return

	if _inventory_ui.is_open():
		_inventory_ui.close()
		_player.set_input_enabled(true)
		return

	if _player.is_moving():
		return

	_inventory_ui.open()
	_player.set_input_enabled(false)


func _place_npcs() -> void:
	for placement in NPC_PLACEMENTS:
		var npc := NPC_SCENE.instantiate()
		add_child(npc)
		npc.facing = placement["facing"]
		npc.dialogue_text = placement["text"]
		npc.position = _grid_to_world(placement["cell"])
		_occupied_cells[placement["cell"]] = npc
		_npcs_by_id[placement["id"]] = npc

	# Reflect already-loaded WorldState (e.g. from a continued save)
	# immediately, rather than waiting for a flag_changed signal that won't
	# fire for state that was bulk-restored via WorldState.from_dict().
	if WorldState.get_flag(FLAG_ASKED_ABOUT_CAIRN):
		var water_npc: Variant = _npcs_by_id.get("water_npc")
		if water_npc:
			water_npc.dialogue_text = WATER_NPC_FOLLOWUP_TEXT


func _grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE)


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
	# TILE_DOOR is blocked like TILE_WALL deliberately, not by oversight: no
	# house interiors exist yet, so there's nowhere for walking onto a door
	# to lead. It's a visual accent marking a future interaction point, not
	# a passable tile - revisit when interiors/entry are actually built.
	for x in [TILE_TREE, TILE_WATER, TILE_WALL, TILE_ROOF, TILE_DOOR]:
		atlas.get_tile_data(Vector2i(x, 0), 0).set_custom_data("blocked", true)

	_ground.tile_set = tile_set
	return source_id


func _build_map(source_id: int) -> void:
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			_ground.set_cell(cell, source_id, Vector2i(_tile_for(cell), 0))


## Every case here is a deliberate placement (issue #9) - the two houses,
## the pond, and the crossroads are all named regions above, checked
## door-before-wall-before-roof since HOUSE_*_DOOR sits inside HOUSE_*_WALL.
## The only non-fixed choice is which grass variant renders, and that's a
## deterministic pattern (not randomness) purely for ground texture.
func _tile_for(cell: Vector2i) -> int:
	var on_border := cell.x == 0 or cell.y == 0 or cell.x == MAP_SIZE.x - 1 or cell.y == MAP_SIZE.y - 1
	if on_border:
		return TILE_TREE
	if POND.has_point(cell):
		return TILE_WATER
	if cell == HOUSE_A_DOOR or cell == HOUSE_B_DOOR:
		return TILE_DOOR
	if HOUSE_A_ROOF.has_point(cell) or HOUSE_B_ROOF.has_point(cell):
		return TILE_ROOF
	if HOUSE_A_WALL.has_point(cell) or HOUSE_B_WALL.has_point(cell):
		return TILE_WALL
	if cell.x == PATH_X or cell.y == PATH_Y:
		return TILE_PATH
	if (cell.x + cell.y) % 5 == 0:
		return TILE_GRASS_FLOWERS
	return TILE_GRASS
