extends Node2D

## Light/stylized challenge-layer prototype (issue #10) - see
## docs/DECISIONS.md ("Challenge layer") for why this concrete form was
## picked over alternatives. A tense "hold still while the light passes"
## beat: stepping onto the trigger cell starts a HOLD_DURATION window during
## which any further move fails the encounter (a gentle push-back, freely
## retryable); holding still for the full window succeeds, once, permanently
## - no stats, no numeric reward, nothing here to grind. Wired up by
## main.gd via initialize(), which owns the outcome (dialogue + WorldState).

signal succeeded
signal failed

const HOLD_DURATION := 3.0
const WISP_DRIFT_RADIUS := 5.0
const WISP_DRIFT_SPEED := 1.6
const WISP_PULSE_SPEED := 3.0

enum State { IDLE, ACTIVE, DONE }

@onready var _wisp: Sprite2D = $Wisp

var _player: Node2D
var _trigger_cell: Vector2i
var _push_back_cell: Vector2i
var _state := State.IDLE
var _hold_elapsed := 0.0
var _wisp_time := 0.0
var _wisp_origin := Vector2.ZERO


## already_done lets a continued save skip straight to State.DONE - without
## it, "succeeds once, permanently" would only hold within a single session,
## since this node's own _state doesn't persist (only the WorldState flag
## main.gd sets from the succeeded signal does).
func initialize(player: Node2D, trigger_cell: Vector2i, push_back_cell: Vector2i, already_done: bool = false) -> void:
	assert(trigger_cell != push_back_cell, "trigger_cell and push_back_cell must differ - force_move_to()'s own completion also emits moved(), which would otherwise immediately re-trigger or re-fail this encounter")
	_player = player
	_trigger_cell = trigger_cell
	_push_back_cell = push_back_cell
	_state = State.DONE if already_done else State.IDLE
	_player.moved.connect(_on_player_moved)
	_wisp.visible = false


func _process(delta: float) -> void:
	if _state != State.ACTIVE:
		return

	_hold_elapsed += delta
	_wisp_time += delta
	_wisp.position = _wisp_origin + Vector2(
		cos(_wisp_time * WISP_DRIFT_SPEED) * WISP_DRIFT_RADIUS,
		sin(_wisp_time * WISP_DRIFT_SPEED * 1.7) * WISP_DRIFT_RADIUS * 0.6 - 18.0
	)
	_wisp.modulate.a = 0.6 + 0.4 * sin(_wisp_time * WISP_PULSE_SPEED)

	if _hold_elapsed >= HOLD_DURATION:
		_succeed()


## "Hold still" is enforced against successful relocation (the moved
## signal), not against key presses - holding a direction that's blocked
## (e.g. up, with the border immediately north of the trigger cell) never
## emits moved() and so never fails. Consistent in-fiction (the character
## never actually moved), but worth knowing if a future trigger cell has
## open ground on all sides, where this would be less airtight.
func _on_player_moved(grid_pos: Vector2i) -> void:
	if _state == State.ACTIVE:
		_fail()
		return
	if _state == State.IDLE and grid_pos == _trigger_cell:
		_begin()


func _begin() -> void:
	_state = State.ACTIVE
	_hold_elapsed = 0.0
	_wisp_time = 0.0
	_wisp_origin = _player.position
	_wisp.visible = true
	_wisp.modulate.a = 1.0


func _succeed() -> void:
	_state = State.DONE
	_wisp.visible = false
	succeeded.emit()


func _fail() -> void:
	_state = State.IDLE
	_wisp.visible = false
	_player.force_move_to(_push_back_cell)
	failed.emit()
