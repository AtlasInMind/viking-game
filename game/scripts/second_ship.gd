extends Node2D

## The second ship's wreck (issue #35) - Act 2's second new area and its
## biggest single revelation-location, per docs/WORLD_BIBLE.md's "The
## Second Ship": a different, older, unrelated longship, found abandoned
## by Hakon's own crew mid-voyage. Mirrors ship.gd's hand-authored
## map-building approach, deliberately reusing the exact same tile
## vocabulary (TILE_PATH/TILE_WALL/TILE_ROOF/TILE_WATER) rather than
## inventing new art for this issue - a BREACH rect (a gap in the hull,
## open to water) is the one structural difference, reading as damage/decay
## without needing new tile assets. Geography and transitions built by issue
## #35 (a dead end beyond this - Act 2 doesn't need a third new area);
## Hakon's placement/dialogue (see NPC_PLACEMENTS) added by issue #36.
## Main-quest wiring added by issue #37: RecognitionEncounter reuses the
## exact "hold still" mechanic (game/scripts/cairn_encounter.gd) ship.gd's
## own MemoryEncounter already proved out, per docs/WORLD_BIBLE.md's Act 2
## section ("another fragment of Hakon's memory surfacing, framed as
## recognition... he's seen this before") - a second beat, not a second
## mechanism.

const TILE_SIZE := 16
const WRECK_SIZE := Vector2i(16, 10)

## Same shared tile atlas/indices as main.gd/ship.gd's tileset.
const TILE_PATH := 2
const TILE_WATER := 4
const TILE_WALL := 5
const TILE_ROOF := 6

## The hull's outer edge is every HULL cell not also in DECK, same
## reasoning as ship.gd's own HULL/DECK pair.
const HULL := Rect2i(1, 1, 14, 7)
const DECK := Rect2i(2, 2, 12, 5)

## A broken mast/wreckage pile on deck (roof tile, blocked - no interior,
## same reasoning as ship.gd's SHELTER).
const SHELTER := Rect2i(6, 3, 3, 1)

## A gap in the west hull wall, open to the sea - the one visible sign this
## ship has sat here far longer than Hakon's own. Checked before HULL so it
## overrides that one section to TILE_WATER instead of TILE_WALL.
const BREACH := Rect2i(1, 4, 1, 2)

## This scene's own id in AreaRegistry (issue #30).
const AREA_ID := AreaRegistry.SECOND_SHIP

## The one way in/out: a gap in the hull's south wall continuing south to
## the return trigger, mirroring ship.gd's own gangplank exactly.
## ENTRY_CELL matches AreaRegistry.SECOND_SHIP's entry_cell (the canonical
## arrival point, used here and for world-map fast travel) - unlike
## shoreline_camp, this area has only one neighbor, so its canonical entry
## cell and its specific arrival-from-shoreline-camp cell are the same
## value with no separate local constant needed.
const GANGPLANK_X := 8
const GANGPLANK_START_Y := 7
const RETURN_TO_SHORELINE_CELL := Vector2i(GANGPLANK_X, WRECK_SIZE.y - 1)
const ENTRY_CELL := Vector2i(GANGPLANK_X, WRECK_SIZE.y - 2)
const DEFAULT_ENTRY_CELL := ENTRY_CELL

## Must match shoreline_camp.gd's own WRECK_ENTRY_CELL - this scene's
## coordinate space, not this one's, so it can't be resolved via
## AreaRegistry (whose entries are each area's own arrival point, not its
## neighbors'). Same hand-kept-in-sync-by-comment pattern as every other
## specific area-to-area connection before AreaRegistry centralized the
## generic fast-travel case (see that file's own note on why this is fine).
const SHORELINE_CAMP_ENTRY_CELL := Vector2i(10, 1)

const NPC_SCENE := preload("res://scenes/npc.tscn")

## Hakon (issue #36) - travels this far too, per docs/WORLD_BIBLE.md's Act 2
## section ("another fragment of Hakon's memory surfacing, framed as
## recognition... he's seen this before"). Stood on deck clear of SHELTER,
## facing east toward it - the wreckage is what the recognition line is
## about. No other NPC is placed here: per WORLD_BIBLE's Cast section, Act 2
## deliberately introduces no new living NPC, the wreck's own crew is long
## gone and stays untold through a person.
##
## Issue #37 adds the RECOGNITION_SURFACED-gated line: once the
## RecognitionEncounter below actually succeeds, this line replaces the
## foreshadowing fallback rather than repeating it forever - same
## most-progressed-first dialogue_lines discipline as everywhere else.
const NPC_PLACEMENTS := [
	{"id": "hakon", "cell": Vector2i(4, 4), "facing": "side", "facing_right": true, "lines": [
		{"flag": QuestFlags.RECOGNITION_SURFACED, "value": true, "text": "That's it. That's what I couldn't name - I stood somewhere like this before, right before everything after went quiet."},
		{"flag": "", "text": "I've stood on a deck like this before mine went quiet. Whatever happened to this crew - I think I understood it, once, right before I stopped understanding anything at all."},
	]},
]

## The recognition beat (issue #37) - reuses cairn_encounter.gd's "hold
## still" mechanic a second time (ship.gd's MemoryEncounter was the first
## reuse), instanced as RecognitionEncounter in second_ship.tscn. Placed on
## open deck near the wreckage pile (clear of SHELTER/Hakon/the gangplank),
## deliberately ungated on SHORELINE_CAMP_EXPLORED or any other Act 2
## flag - purely spatial, same reasoning as ship.gd's own MEMORY_TRIGGER_CELL
## having no prerequisite either.
const RECOGNITION_TRIGGER_CELL := Vector2i(10, 4)
const RECOGNITION_PUSH_BACK_CELL := Vector2i(12, 5)

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player
@onready var _dialogue: DialogueBox = $UI/DialogueBox
@onready var _inventory_ui: InventoryUI = $UI/InventoryUI
@onready var _journal_ui: JournalUI = $UI/JournalUI
@onready var _world_map_ui: WorldMapUI = $UI/WorldMapUI
@onready var _recognition_encounter: Node2D = $RecognitionEncounter
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
	_player.initialize(_ground, start, TILE_SIZE, WRECK_SIZE, _occupied_cells)
	_player.moved.connect(_on_player_moved)
	WorldState.flag_changed.connect(_on_flag_changed)
	_world_map_ui.travel_requested.connect(_on_travel_requested)

	if not WorldMap.is_visited(AREA_ID):
		WorldMap.mark_visited(AREA_ID)
		_save_state()

	_recognition_encounter.initialize(_player, RECOGNITION_TRIGGER_CELL, RECOGNITION_PUSH_BACK_CELL, WorldState.get_flag(QuestFlags.RECOGNITION_SURFACED))
	_recognition_encounter.succeeded.connect(_on_recognition_encounter_succeeded)
	_recognition_encounter.failed.connect(_on_recognition_encounter_failed)
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
	if loaded.x < 0 or loaded.y < 0 or loaded.x >= WRECK_SIZE.x or loaded.y >= WRECK_SIZE.y:
		return DEFAULT_ENTRY_CELL
	var tile_data := _ground.get_cell_tile_data(loaded)
	if tile_data == null or tile_data.get_custom_data("blocked"):
		return DEFAULT_ENTRY_CELL
	return loaded


func _on_player_moved(grid_pos: Vector2i) -> void:
	if grid_pos == RETURN_TO_SHORELINE_CELL:
		_transition_to(AreaRegistry.get_area(AreaRegistry.SHORELINE_CAMP)["scene_path"], SHORELINE_CAMP_ENTRY_CELL)
		return
	_save_state()


func _on_flag_changed(_flag: String, _value: Variant) -> void:
	_update_hint()
	_save_state()


func _update_hint() -> void:
	_hint.text = "%s\n%s" % [Settings.controls_hint_text(), QuestLog.get_current_objective()]


## Mirrors ship.gd's _on_memory_encounter_succeeded() - a real CutscenePlayer
## sequence (issue #31), not a single static line, for the same reason: this
## is Act 2's own biggest beat, framed as recognition rather than a new fear
## (docs/WORLD_BIBLE.md's Act 2 section) - Hakon's seen this exact stillness
## before, days before the rest of his memory went dark. Camera pans toward
## BREACH (the gap in the west hull wall, open to the sea) rather than
## straight up/out like ship.gd's own pan - what's being recognized here is
## the wreck itself, not the water beyond it.
func _on_recognition_encounter_succeeded() -> void:
	_cutscene.play([
		{"type": "flag", "flag": QuestFlags.RECOGNITION_SURFACED, "value": true},
		{"type": "dialogue", "text": "This isn't new. Somewhere behind Hakon's silence, this exact stillness is already familiar - he's stood somewhere just like this before, and it's the last clear thing he remembers before the rest went dark."},
		{"type": "camera_pan", "offset": Vector2(-32, 0), "duration": 1.2},
		{"type": "wait", "duration": 1.0},
		{"type": "dialogue", "text": "Whatever this ship's crew walked into, Hakon's crew found it too, close enough to call it the same shape. That's the fear he's been carrying - not distance, but recognition."},
		{"type": "camera_pan", "offset": Vector2.ZERO, "duration": 1.0},
	])


func _on_recognition_encounter_failed() -> void:
	_dialogue.open("You flinch, and the recognition slips away before you can hold it steady. Best to hold still, if you want to see it through.")
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


## Mirrors shoreline_camp.gd's _process_interact() - Hakon (issue #36) is
## the only NPC here. Unlike shoreline_camp.gd's Hakon, talking to him here
## has no quest-flag side effect of its own (issue #37) - RECOGNITION_SURFACED
## is set by the RecognitionEncounter succeeding (see
## _on_recognition_encounter_succeeded()), not by this conversation; his
## dialogue_lines entry above only reads that flag, live, same as everywhere
## else.
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
	for x in [TILE_WATER, TILE_WALL, TILE_ROOF]:
		atlas.get_tile_data(Vector2i(x, 0), 0).set_custom_data("blocked", true)

	_ground.tile_set = tile_set
	return source_id


func _build_map(source_id: int) -> void:
	for y in range(WRECK_SIZE.y):
		for x in range(WRECK_SIZE.x):
			var cell := Vector2i(x, y)
			_ground.set_cell(cell, source_id, Vector2i(_tile_for(cell), 0))


## Same priority reasoning as ship.gd's _tile_for(): the gangplank check
## comes first so it can punch through the hull's south wall in one
## uniform column; BREACH is checked before HULL so it can override one
## section of the hull's own wall to open water instead.
func _tile_for(cell: Vector2i) -> int:
	if cell.x == GANGPLANK_X and cell.y >= GANGPLANK_START_Y:
		return TILE_PATH
	if SHELTER.has_point(cell):
		return TILE_ROOF
	if BREACH.has_point(cell):
		return TILE_WATER
	if DECK.has_point(cell):
		return TILE_PATH
	if HULL.has_point(cell):
		return TILE_WALL
	return TILE_WATER
