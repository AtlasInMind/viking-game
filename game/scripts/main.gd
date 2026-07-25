extends Node2D

## Builds a small explorable overworld at runtime (tileset + tilemap) and
## hands it to the player. Runtime generation avoids hand-authoring the
## TileMapLayer's packed cell data by hand in a .tscn file.

const TILE_SIZE := 16
const MAP_SIZE := Vector2i(40, 24)

const TILE_GRASS := 0
const TILE_GRASS_FLOWERS := 1
const TILE_PATH := 2
const TILE_TREE := 3
const TILE_WATER := 4

const NPC_SCENE := preload("res://scenes/npc.tscn")

## Placeholder NPCs for M1's vertical slice - grid cells chosen to sit on the
## path near the player's start so they're immediately reachable.
const NPC_PLACEMENTS := [
	{"cell": Vector2i(22, 12), "facing": "down", "text": "The path north leads up toward the old cairn, if the weather holds."},
	{"cell": Vector2i(20, 10), "facing": "down", "text": "Careful near the water after dark. My grandmother never let us go near it then."},
]

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player
@onready var _dialogue: DialogueBox = $UI/DialogueBox

var _occupied_cells: Dictionary = {}
var _interact_was_pressed := false


func _ready() -> void:
	var source_id := _build_tileset()
	_build_map(source_id)
	_place_npcs()

	var start := Vector2i(MAP_SIZE.x / 2, MAP_SIZE.y / 2)
	_player.initialize(_ground, start, TILE_SIZE, MAP_SIZE, _occupied_cells)


func _process(_delta: float) -> void:
	var interact_pressed := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)
	var just_pressed := interact_pressed and not _interact_was_pressed
	_interact_was_pressed = interact_pressed
	if not just_pressed:
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


func _place_npcs() -> void:
	for placement in NPC_PLACEMENTS:
		var npc := NPC_SCENE.instantiate()
		add_child(npc)
		npc.facing = placement["facing"]
		npc.dialogue_text = placement["text"]
		npc.position = _grid_to_world(placement["cell"])
		_occupied_cells[placement["cell"]] = npc


func _grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE)


func _build_tileset() -> int:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tiles/overworld_tileset.png")
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for x in range(5):
		atlas.create_tile(Vector2i(x, 0))

	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "blocked")
	tile_set.set_custom_data_layer_type(0, TYPE_BOOL)

	var source_id := tile_set.add_source(atlas)
	for x in [TILE_TREE, TILE_WATER]:
		atlas.get_tile_data(Vector2i(x, 0), 0).set_custom_data("blocked", true)

	_ground.tile_set = tile_set
	return source_id


func _build_map(source_id: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1

	var water_rect := Rect2i(3, 3, 7, 5)

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var cell := Vector2i(x, y)
			var atlas_x := TILE_GRASS

			var on_border := x == 0 or y == 0 or x == MAP_SIZE.x - 1 or y == MAP_SIZE.y - 1
			var on_path := y == MAP_SIZE.y / 2 or x == MAP_SIZE.x / 2
			var in_water := water_rect.has_point(cell)

			if on_border:
				atlas_x = TILE_TREE
			elif in_water:
				atlas_x = TILE_WATER
			elif on_path:
				atlas_x = TILE_PATH
			elif rng.randf() < 0.12:
				atlas_x = TILE_GRASS_FLOWERS
			elif rng.randf() < 0.03:
				atlas_x = TILE_TREE

			_ground.set_cell(cell, source_id, Vector2i(atlas_x, 0))
