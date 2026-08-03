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

## Act 1's cast (issue #20, see docs/WORLD_BIBLE.md "One Man Remains") -
## placed where each person's presence actually makes sense, not just
## wherever the map had room. Gunnar is on the ship (see ship.gd), the
## one place his line about the cargo is actually true.
##
## cairn_npc stands beside the road (not on it - the road is one tile
## wide, and issue #10 needs the player able to walk past them to reach
## the trigger cell further north), facing east toward it. water_npc
## stands beside the pond - both are unnamed village texture predating
## the story decision and are left as-is, except water_npc's dialogue
## (issue #21), which now also carries the main quest's item/gate step.
##
## Line order matters (see QuestFlags/npc.gd) - Hakon's and water_npc's
## most-progressed condition is listed first so a later quest state isn't
## shadowed by an earlier one still being checked first.
##
## Act 2 coda (issue #36, see docs/WORLD_BIBLE.md's Cast section): once
## QuestFlags.ACT_ONE_RESOLVED is true, Hakon/Thora/Steinar/Solveig each get
## a new top-priority line about the second ship rather than repeating Act
## 1 text forever - they're the returning cast who "stay in the settlement"
## per WORLD_BIBLE while Hakon and Gunnar travel (placed in shoreline_camp.gd/
## second_ship.gd/ship.gd instead). ACT_ONE_RESOLVED is reused rather than a
## new Act-2-specific flag invented here - it's already the exact "Act 1 is
## over" signal these lines need, and issue #37 (not this one) owns adding
## any further Act 2 progression flags. Ingrid's is inserted after her
## existing item-conditional line, not before it - the carved-token payoff
## (issue #22) shouldn't be silently shadowed for a player who found it but
## reaches this point before checking back in with her.
const NPC_PLACEMENTS := [
	{"id": "cairn_npc", "cell": Vector2i(PATH_X - 1, 3), "facing": "side", "lines": [
		{"flag": "", "text": "The path north leads up toward the old cairn, if the weather holds."},
	]},
	{"id": "water_npc", "cell": Vector2i(7, 12), "facing": "down", "lines": [
		{"flag": QuestFlags.MET_HAKON, "value": true, "text": "The old rockslide still blocks the way to the ship - here, take this, it should lever it aside. Bring back whatever you find."},
		# QuestFlags.ASKED_ABOUT_CAIRN is set by cairn_npc's own interaction,
		# below in _process_interact() - cross-system reactivity (issue #8):
		# one NPC's conversation changing a different NPC's line, not just
		# an NPC remembering its own.
		{"flag": QuestFlags.ASKED_ABOUT_CAIRN, "value": true, "text": "Asking about the cairn again? Some say lights move up there at night."},
		{"flag": "", "text": "Careful near the water after dark. My grandmother never let us go near it then."},
	]},
	{"id": "hakon", "cell": Vector2i(8, 6), "facing": "down", "lines": [
		# Act 2's resolution beat (issue #37, mirroring ACT_ONE_RESOLVED
		# below exactly): the RECOGNITION_SURFACED-gated line, not this one,
		# is what actually plays on the pivotal report-back visit - get_
		# dialogue_text() resolves before _process_interact()'s own
		# ACT_TWO_RESOLVED set_flag() call below runs. This one only shows
		# on a later, second visit.
		{"flag": QuestFlags.ACT_TWO_RESOLVED, "value": true, "text": "There's nothing more that ship's going to tell us. But I know now I wasn't imagining any of it - and I don't think you doubted me either, by the end."},
		{"flag": QuestFlags.RECOGNITION_SURFACED, "value": true, "text": "That quiet on the second ship - I knew it. Not from anywhere new. From somewhere I'd already been, and forgotten."},
		{"flag": QuestFlags.ACT_ONE_RESOLVED, "value": true, "text": "There's a second camp out there, and beyond it another wreck - if Gunnar can get us there, I want to see it before I lose the nerve to remember."},
		{"flag": QuestFlags.MEMORY_SURFACED, "value": true, "text": "You felt it too, then. That's why none of us wanted to come home and say it plain."},
		{"flag": QuestFlags.MET_HAKON, "value": true, "text": "Ask Gunnar about the cargo, if you want to know I'm not imagining things. I can't tell you where we went. I wish I could."},
		{"flag": "", "text": "I keep telling them - we never left the fjord. But my hands don't believe me. Look how the salt's worked into them."},
	]},
	{"id": "thora", "cell": Vector2i(5, 7), "facing": "side", "facing_right": true, "lines": [
		{"flag": QuestFlags.ACT_ONE_RESOLVED, "value": true, "text": "If there's anything of Ivar's out there, wherever he stood before it happened - bring it home, even if it's small. I'd rather hold something of his than nothing at all."},
		{"flag": QuestFlags.MET_HAKON, "value": true, "text": "Did he say my Ivar's name? Even once?"},
		{"flag": "", "text": "My boy rowed on that ship. Hakon lived. Go on, ask him something - anything. I can't."},
	]},
	{"id": "steinar", "cell": Vector2i(21, 6), "facing": "down", "lines": [
		{"flag": QuestFlags.ACT_ONE_RESOLVED, "value": true, "text": "My brother's crew broke camp somewhere out there before they came back changed. If Hakon can point to where, maybe I can finally answer for something real instead of guessing."},
		{"flag": "", "text": "My brother led that crew out. Now everyone wants to know why only one came back, and somehow that's mine to answer."},
	]},
	{"id": "solveig", "cell": Vector2i(13, 8), "facing": "side", "facing_right": true, "lines": [
		{"flag": QuestFlags.ACT_ONE_RESOLVED, "value": true, "text": "I sent them out once already not knowing what waited. Sending Hakon back feels like tempting the same mistake twice - but I won't be the one who tells grief to wait forever for its answer."},
		{"flag": "", "text": "I gave the order to send them out. If that was wrong, it's mine to carry, not the crew's kin."},
	]},
	{"id": "ingrid", "cell": Vector2i(18, 8), "facing": "side", "facing_right": false, "lines": [
		{"item": "carved_token", "text": "That's - that's the token he was carving. He never showed me the whole of it. I didn't know he'd finished it... had he?"},
		{"flag": QuestFlags.ACT_ONE_RESOLVED, "value": true, "text": "He never told me where they'd been, only that he was afraid to say it plain. If Hakon finds the words for it out there, I want to hear them, whatever they are."},
		{"flag": "", "text": "He told me, the night before they left, that if the weather turned bad he'd rather we never spoke again than write me a letter I'd have to bury with him. I didn't understand it then."},
	]},
]

## Side content (issue #22): a keepsake dropped somewhere it was never
## meant to be found again, in the open grass east of the crossroads -
## off every path/road tile and clear of the gate, so it's reachable by
## wandering from the very start, not gated behind main-quest progress.
## No sprite (see pickup.gd), no hint pointing at it - purely a reward
## for exploring, matching design pillar #1 in docs/PROJECT_VISION.md.
## Optional: Ingrid's reactive line above is the only thing that changes,
## and nothing here is required to complete or progress the main quest.
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const PICKUP_PLACEMENTS := [
	{"id": "carved_token_pickup", "cell": Vector2i(24, 11),
		"item_id": "carved_token",
		"found_text": "Half-finished, tucked into the grass here: someone was carving a small token, roughly a woman's likeness, never finished.",
		"already_found_text": "Just flattened grass here now."},
]

## Challenge-layer prototype (issue #10): stepping onto CAIRN_TRIGGER_CELL,
## further up the road past cairn_npc, starts the "hold still" encounter;
## failing pushes the player back to CAIRN_PUSH_BACK_CELL (south of the
## trigger, clear of cairn_npc and the crossroads) to retry.
const CAIRN_TRIGGER_CELL := Vector2i(PATH_X, 1)
const CAIRN_PUSH_BACK_CELL := Vector2i(PATH_X, 3)

## Progression gate prototype (issue #18): a rockslide-styled blocked cell
## on the otherwise-empty path south of the crossroads, cleared once the
## player holds GATE's required item. Placeholder gate/key proving the
## mechanism works end-to-end - not real Act 1 content, see #21.
const GATE: GateDefinition = preload("res://data/gates/south_gate.tres")

## This scene's own id in AreaRegistry (issue #30) - used to mark itself
## visited for the world map and to let WorldMapUI show "(you are here)"
## instead of a travel button for its own entry.
const AREA_ID := AreaRegistry.VILLAGE

## Area transition (issue #19): past the gate, the south path opens a gap
## in the border treeline (see _tile_for()) leading to the returned
## longship. The target scene/entry cell now resolve through AreaRegistry
## (issue #30) instead of a locally-hardcoded SHIP_ENTRY_CELL - see that
## file for why a third consumer (fast travel) justified centralizing what
## used to be two hand-kept-in-sync copies.
const TRANSITION_TO_SHIP_CELL := Vector2i(PATH_X, MAP_SIZE.y - 1)

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Node2D = $Player
@onready var _cairn_encounter: Node2D = $CairnEncounter
@onready var _dialogue: DialogueBox = $UI/DialogueBox
@onready var _inventory_ui: InventoryUI = $UI/InventoryUI
@onready var _journal_ui: JournalUI = $UI/JournalUI
@onready var _world_map_ui: WorldMapUI = $UI/WorldMapUI
@onready var _hint: Label = $UI/Hint

var _occupied_cells: Dictionary = {}
var _interactables_by_id: Dictionary = {}
var _interact_was_pressed := false
var _inventory_key_was_pressed := false
var _journal_key_was_pressed := false
var _map_key_was_pressed := false
var _tileset_source_id: int = -1


func _ready() -> void:
	_hint.add_theme_font_size_override("font_size", Settings.scaled_font_size())

	# Load save data (and restore WorldState from it) before placing NPCs,
	# so a continued game's NPCs reflect prior flag state from their very
	# first frame instead of only updating reactively on the next change.
	var save_data := _load_save_if_continuing()

	_tileset_source_id = _build_tileset()
	_build_map(_tileset_source_id)
	_place_npcs()
	_place_pickups()

	var start := _resolve_start_position(save_data)
	_player.initialize(_ground, start, TILE_SIZE, MAP_SIZE, _occupied_cells)
	_player.moved.connect(_on_player_moved)
	WorldState.flag_changed.connect(_on_flag_changed)
	Inventory.item_added.connect(_on_item_added)

	_cairn_encounter.initialize(_player, CAIRN_TRIGGER_CELL, CAIRN_PUSH_BACK_CELL, WorldState.get_flag(QuestFlags.CAIRN_LIGHT_PASSED))
	_cairn_encounter.succeeded.connect(_on_cairn_encounter_succeeded)
	_cairn_encounter.failed.connect(_on_cairn_encounter_failed)
	_world_map_ui.travel_requested.connect(_on_travel_requested)

	# Marks itself visited every time this scene loads (idempotent past the
	# first time - WorldMap.mark_visited() no-ops if already visited), so
	# the village is always on the map without needing a special "starting
	# area" case. Saved immediately so a save made before the next flag
	# change/step still remembers it was visited.
	if not WorldMap.is_visited(AREA_ID):
		WorldMap.mark_visited(AREA_ID)
		_save_state()

	_update_hint()


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
	if data.has("world_map") and data["world_map"] is Dictionary:
		WorldMap.from_dict(data["world_map"])
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


func _on_player_moved(grid_pos: Vector2i) -> void:
	if grid_pos == TRANSITION_TO_SHIP_CELL:
		_transition_to_area(AreaRegistry.SHIP)
		return
	_save_state()


## Any flag change gets persisted immediately, not just on movement -
## talking to an NPC doesn't require the player to also take a step before
## the resulting state change survives a reload.
func _on_flag_changed(_flag: String, _value: Variant) -> void:
	_refresh_gate_tile()
	_update_hint()
	_save_state()


## Act 1's minimal "what to do next" (issue #21), now a thin wrapper over
## quest_log.gd's single shared implementation (issue #29) rather than its
## own duplicated if/elif chain - see quest_log.gd for the ordered step
## list and the reasoning for checking GATE.is_unlocked() rather than the
## item directly. Coexists with the new JournalUI panel rather than being
## replaced by it (docs/DECISIONS.md, 2026-07-26): this stays for
## at-a-glance guidance without opening a panel.
func _update_hint() -> void:
	_hint.text = "%s\n%s" % [Settings.controls_hint_text(), QuestLog.get_current_objective()]


## GATE (issue #18) can be flag-gated as well as item-gated, so both
## Inventory.item_added and WorldState.flag_changed refresh it live - not
## just at map-build time - in case the unlock condition is met mid-play
## rather than already true when a continued save's map first builds.
## _update_hint() needs the same live refresh (issue #25) now that its
## MET_HAKON branch also reads Inventory state, not just flags - without
## this, picking up the rusted key wouldn't update the hint until the next
## unrelated flag change happened to fire it.
func _on_item_added(_id: String) -> void:
	_refresh_gate_tile()
	_update_hint()


func _refresh_gate_tile() -> void:
	_ground.set_cell(GATE.cell, _tileset_source_id, Vector2i(_tile_for(GATE.cell), 0))


func _on_cairn_encounter_succeeded() -> void:
	WorldState.set_flag(QuestFlags.CAIRN_LIGHT_PASSED, true)
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
	data["world_map"] = WorldMap.to_dict()
	data["current_scene"] = scene_file_path
	SaveSystem.save_game(data)


## Area transitions (issue #19) write the arriving scene's entry cell as
## the saved position and flip pending_load, reusing the exact same
## "restore everything from disk" path _load_save_if_continuing() already
## uses for a title-screen Continue - WorldState/Inventory are already
## correct in memory (autoloads survive change_scene_to_file), so this
## round-trip through disk is only there to fix the player's position
## after the scene tree (and the old Player node) gets replaced, and to
## make the new area durable across a later real page reload.
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


## Resolves an AreaRegistry id to its scene/entry cell and hands off to
## _transition_to() - the one thing both the existing walk-into-a-transition-
## cell path (_on_player_moved()) and fast travel (_on_travel_requested())
## have in common, now that both resolve through the same registry.
func _transition_to_area(area_id: String) -> void:
	var area := AreaRegistry.get_area(area_id)
	_transition_to(area["scene_path"], area["entry_cell"])


## WorldMapUI already closed itself before emitting this (see its
## _on_travel_pressed()), so no player-input/UI-state cleanup is needed here
## beyond the transition itself.
func _on_travel_requested(area_id: String) -> void:
	_transition_to_area(area_id)


func _process(_delta: float) -> void:
	_process_interact()
	_process_inventory_toggle()
	_process_journal_toggle()
	_process_map_toggle()


func _process_interact() -> void:
	var interact_pressed := Input.is_action_pressed("interact")
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
		if npc == _interactables_by_id.get("cairn_npc"):
			WorldState.set_flag(QuestFlags.ASKED_ABOUT_CAIRN, true)
			# Placeholder items proving issue #17's inventory system
			# end-to-end - #21 deliberately left this cairn subplot as
			# optional village texture rather than folding it into the
			# main quest thread; see #22 for real secrets/collectibles.
			Inventory.add_item("placeholder_charm")
			Inventory.add_item("placeholder_stone")
			# set_flag() above already triggered one _save_state() via
			# _on_flag_changed(), but that ran before these items were
			# added - save again so the grant survives immediately
			# rather than only on the player's next step.
			_save_state()
		elif npc == _interactables_by_id.get("water_npc"):
			# The rusted key is the main quest's real item/gate step
			# (issue #21) - only offered once the player has a reason to
			# want it (they've met Hakon and know the ship matters).
			# Idempotent either way (Inventory.add_item no-ops if already
			# held), so re-visiting water_npc afterward is harmless.
			if WorldState.get_flag(QuestFlags.MET_HAKON):
				Inventory.add_item("rusted_key")
				_save_state()
		elif npc == _interactables_by_id.get("hakon"):
			WorldState.set_flag(QuestFlags.MET_HAKON, true)
			# Act 1's resolution beat (issue #21): reporting back after
			# the ship's memory encounter closes the thread. _on_flag_changed()
			# already saves for both set_flag() calls here, no extra call needed.
			if WorldState.get_flag(QuestFlags.MEMORY_SURFACED):
				WorldState.set_flag(QuestFlags.ACT_ONE_RESOLVED, true)
			# Act 2's resolution beat (issue #37) - the exact same "report
			# back to Hakon" shape, one flag pair over.
			if WorldState.get_flag(QuestFlags.RECOGNITION_SURFACED):
				WorldState.set_flag(QuestFlags.ACT_TWO_RESOLVED, true)
		elif npc == _interactables_by_id.get("carved_token_pickup"):
			# Side content (issue #22) - optional, not required for the
			# main quest. Idempotent (Inventory.add_item no-ops if already
			# held), so revisiting after taking it just repeats the
			# already-found text with no further effect.
			Inventory.add_item("carved_token")
			_save_state()


## Toggling the inventory panel is mutually exclusive with dialogue and the
## journal - it won't open mid-conversation or while the journal is open,
## and talking is blocked while it's open (see the _inventory_ui.is_open()
## guard in _process_interact()).
func _process_inventory_toggle() -> void:
	var inventory_key_pressed := Input.is_action_pressed("toggle_inventory")
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


## Mirrors _process_inventory_toggle() exactly (issue #29) - mutually
## exclusive with dialogue and the inventory panel the same way.
func _process_journal_toggle() -> void:
	var journal_key_pressed := Input.is_action_pressed("toggle_journal")
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


## Mirrors _process_inventory_toggle()/_process_journal_toggle() (issue #30)
## - mutually exclusive with dialogue and the other two panels the same way.
## Unlike those two, open() takes this scene's own AREA_ID so the panel can
## mark it "(you are here)" rather than offering a travel button to it.
func _process_map_toggle() -> void:
	var map_key_pressed := Input.is_action_pressed("toggle_map")
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


func _place_npcs() -> void:
	for placement in NPC_PLACEMENTS:
		var npc := NPC_SCENE.instantiate()
		add_child(npc)
		npc.facing = placement["facing"]
		npc.facing_right = placement.get("facing_right", true)
		npc.dialogue_lines = placement["lines"]
		npc.position = _grid_to_world(placement["cell"])
		_occupied_cells[placement["cell"]] = npc
		_interactables_by_id[placement["id"]] = npc


func _place_pickups() -> void:
	for placement in PICKUP_PLACEMENTS:
		var pickup := PICKUP_SCENE.instantiate()
		add_child(pickup)
		pickup.item_id = placement["item_id"]
		pickup.found_text = placement["found_text"]
		pickup.already_found_text = placement["already_found_text"]
		pickup.position = _grid_to_world(placement["cell"])
		_occupied_cells[placement["cell"]] = pickup
		_interactables_by_id[placement["id"]] = pickup


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
	# Checked before the border/tree fallback deliberately - this is the one
	# deliberate gap in the treeline, not an oversight.
	if cell == TRANSITION_TO_SHIP_CELL:
		return TILE_PATH
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
	# A single blocked cell in open grass would just be a walk-around, not
	# a gate - GATE.cell.y is blocked wall-to-wall, with only GATE's own
	# cell conditionally passable, an actual chokepoint (issue #19 review).
	if cell.y == GATE.cell.y:
		if cell.x == GATE.cell.x:
			return TILE_PATH if GATE.is_unlocked() else TILE_WALL
		return TILE_WALL
	if cell.x == PATH_X or cell.y == PATH_Y:
		return TILE_PATH
	if (cell.x + cell.y) % 5 == 0:
		return TILE_GRASS_FLOWERS
	return TILE_GRASS
