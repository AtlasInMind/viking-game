extends Node2D

## Grid-based overworld movement (Pokemon-GBA style): one tile per press,
## turn-in-place when facing a direction that's blocked instead of ignoring
## the input, tile-locked so the sprite is always aligned to the grid.

const MOVE_TIME := 0.14

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _camera: Camera2D = $Camera2D

var _tile_size := 16
var _ground: TileMapLayer
var _grid_pos := Vector2i.ZERO
var _moving := false
var _facing := "down"
var _facing_right := true
var _step_frame := 0


func initialize(ground: TileMapLayer, start_grid_pos: Vector2i, tile_size: int, map_size: Vector2i) -> void:
	_ground = ground
	_tile_size = tile_size
	_grid_pos = start_grid_pos
	position = _grid_to_world(_grid_pos)

	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map_size.x * tile_size
	_camera.limit_bottom = map_size.y * tile_size
	_camera.make_current()

	_update_sprite_frame()


func _process(_delta: float) -> void:
	if _ground == null or _moving:
		return

	var direction := _read_direction()
	if direction == Vector2i.ZERO:
		_step_frame = 0
		_update_sprite_frame()
		return

	_face(direction)

	var target := _grid_pos + direction
	if _is_blocked(target):
		_update_sprite_frame()
		return

	_step_frame = 1 - _step_frame
	_update_sprite_frame()
	_move_to(target)


func _read_direction() -> Vector2i:
	var direction := Vector2i.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if direction.x != 0 and direction.y != 0:
		direction.y = 0
	return direction


func _face(direction: Vector2i) -> void:
	if direction.y < 0:
		_facing = "up"
	elif direction.y > 0:
		_facing = "down"
	elif direction.x != 0:
		_facing = "side"
		_facing_right = direction.x > 0


func _is_blocked(cell: Vector2i) -> bool:
	var data := _ground.get_cell_tile_data(cell)
	if data == null:
		return true
	return data.get_custom_data("blocked")


func _move_to(target: Vector2i) -> void:
	_moving = true
	var tween := create_tween()
	tween.tween_property(self, "position", _grid_to_world(target), MOVE_TIME)
	tween.finished.connect(func() -> void:
		_grid_pos = target
		_moving = false
	)


func _grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * _tile_size + _tile_size / 2.0, cell.y * _tile_size + _tile_size)


func _update_sprite_frame() -> void:
	var row: int = {"down": 0, "side": 1, "up": 2}[_facing]
	_sprite.region_rect = Rect2(_step_frame * 16, row * 24, 16, 24)
	_sprite.flip_h = _facing == "side" and not _facing_right
