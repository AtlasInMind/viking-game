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

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player


func _ready() -> void:
	var source_id := _build_tileset()
	_build_map(source_id)

	var start := Vector2i(MAP_SIZE.x / 2, MAP_SIZE.y / 2)
	_player.initialize(_ground, start, TILE_SIZE, MAP_SIZE)


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
