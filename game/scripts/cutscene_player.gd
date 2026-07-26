class_name CutscenePlayer
extends Node

## Data-driven cutscene/dialogue-scripting (issue #31) - plays an ordered
## Array of step Dictionaries (same "plain data over bespoke code" style as
## dialogue_lines/QuestLog/NPC_PLACEMENTS) with minimal further player input
## beyond advancing text, so M5's story acts can stage a bigger scripted
## moment without hand-wiring one-off code per beat the way the cairn/
## memory encounters and Act 1's resolution beat currently are.
##
## Step shapes (all keys except "type" optional, defaults noted):
##   {"type": "dialogue", "text": String} - shows text in the scene's
##     DialogueBox; advances only when the scene calls advance() (wired to
##     the same Space/Enter interact key normal dialogue already uses).
##   {"type": "wait", "duration": float} - auto-advances after N seconds,
##     no input needed. Default 1.0.
##   {"type": "camera_pan", "offset": Vector2, "duration": float} - tweens
##     the player's Camera2D.offset (not its position - the camera stays
##     parented to Player, see player.gd's get_camera()) to the given
##     relative offset in pixels, auto-advancing when the tween finishes.
##     Vector2.ZERO returns the view to centered-on-player. Default duration
##     1.0.
##   {"type": "flag", "flag": String, "value": Variant} - sets a WorldState
##     flag immediately (whatever the scene's own WorldState.flag_changed
##     listener already does - e.g. saving - happens the same as any other
##     set_flag() call) and auto-advances with no delay. Setting the flag
##     that marks a triggering encounter "already done" (e.g.
##     QuestFlags.MEMORY_SURFACED) as the first step, rather than after the
##     sequence finishes, means a reload in the narrow window before the
##     sequence completes loses the rest of the cutscene permanently (the
##     encounter won't re-trigger). Accepted for the same reason other
##     one-shot dialogue in this project isn't reload-safe mid-beat either -
##     revisit only if a future cutscene's content is long/valuable enough
##     that this becomes worth a real fix (e.g. persisting _index).
## Unrecognized step types are skipped (auto-advance) rather than erroring,
## so a typo'd/future step type doesn't hang a cutscene forever.
##
## A trigger for play() (e.g. cairn_encounter.gd's succeeded signal) can fire
## while Inventory/Journal/the world map happens to be open - those toggle on
## a global key (I/J/M) unrelated to the trigger's own position/timing, so
## there's no way to rule it out upstream. Without handling that here, the
## scene's own _process_interact()/_process_*_toggle() guards (which check
## the panel's is_open() before this player's own is_playing()) would
## soft-lock: Space couldn't reach advance() because a panel is "open", and
## the panel's own toggle key couldn't close it because a cutscene is
## "playing". play() force-closes any such panel before starting, so a
## cutscene always begins from a clean, panel-free state - see
## docs/DECISIONS.md's issue #31 entry.
signal finished

enum _StepState { NONE, DIALOGUE, WAITING, PANNING }

var _dialogue_box: DialogueBox
var _camera: Camera2D
var _player: Node2D
var _closeable_panels: Array = []
var _steps: Array = []
var _index := -1
var _state := _StepState.NONE
var _wait_remaining := 0.0


## closeable_panels is any list of objects duck-typed like InventoryUI/
## JournalUI/WorldMapUI (is_open()/close()) - passed generically rather than
## as named InventoryUI/JournalUI/WorldMapUI params so a future scene with a
## different panel set doesn't need this script to change.
func initialize(dialogue_box: DialogueBox, camera: Camera2D, player: Node2D, closeable_panels: Array = []) -> void:
	_dialogue_box = dialogue_box
	_camera = camera
	_player = player
	_closeable_panels = closeable_panels


func is_playing() -> bool:
	return _state != _StepState.NONE


func play(steps: Array) -> void:
	for panel in _closeable_panels:
		if panel.is_open():
			panel.close()
	_steps = steps
	_index = -1
	_player.set_input_enabled(false)
	_next_step()


## Called by the scene's interact handling in place of the normal "close
## dialogue" action while a "dialogue" step is up - mirrors that same
## Space/Enter key, but continues the sequence instead of closing for good.
## No-ops if called while a "wait"/"camera_pan" step is running (those only
## advance on their own timer/tween, not on player input).
func advance() -> void:
	if _state != _StepState.DIALOGUE:
		return
	_next_step()


func _process(delta: float) -> void:
	if _state != _StepState.WAITING:
		return
	_wait_remaining -= delta
	if _wait_remaining <= 0.0:
		_next_step()


func _next_step() -> void:
	_index += 1
	if _index >= _steps.size():
		_finish()
		return

	var step: Dictionary = _steps[_index]
	match step.get("type", ""):
		"dialogue":
			_state = _StepState.DIALOGUE
			_dialogue_box.open(step.get("text", "..."))
		"wait":
			_state = _StepState.WAITING
			_wait_remaining = step.get("duration", 1.0)
		"camera_pan":
			_state = _StepState.PANNING
			var tween := create_tween()
			tween.tween_property(_camera, "offset", step.get("offset", Vector2.ZERO), step.get("duration", 1.0))
			tween.finished.connect(_next_step)
		"flag":
			WorldState.set_flag(step.get("flag", ""), step.get("value", true))
			_next_step()
		_:
			_next_step()


func _finish() -> void:
	_state = _StepState.NONE
	_dialogue_box.close()
	_camera.offset = Vector2.ZERO
	_player.set_input_enabled(true)
	finished.emit()
