extends Node

## Global settings autoload (see [autoload] in project.godot) - issue #32's
## remappable-input and adjustable-text-size requirements. Persisted
## separately from SaveSystem's save file (a new user://settings.json, not a
## field merged into the game save) since these are player/device
## preferences that should survive independently of - and exist before -
## any actual save game (e.g. rebinding keys from the title screen before
## ever pressing Start).
##
## Every action gets exactly one *remappable* key (what this autoload
## stores/persists) plus zero or more always-on "fixed" alias keys (e.g.
## WASD alongside the arrow keys) that remapping never touches - so a
## player who never opens Settings keeps exactly today's key layout, and a
## player who does still keeps the muscle-memory alias working alongside
## whatever they rebound the primary key to. Actions are registered
## directly on Godot's InputMap at runtime (not via project.godot's static
## [input] section, which intentionally defines none of these) so the rest
## of the game reads input via Input.is_action_pressed("move_up") etc.,
## the same as any other Godot input action, with no touch/keyboard/remap
## branching needed at the call site (see touch_controls.gd, which drives
## these same actions via Input.action_press()/action_release()).

const SETTINGS_PATH := "user://settings.json"

const TEXT_SCALE_MIN := 0.8
const TEXT_SCALE_MAX := 1.6
const TEXT_SCALE_STEP := 0.2
const DEFAULT_TEXT_SCALE := 1.0
const BASE_FONT_SIZE := 16

## action -> {"default": Key, "fixed": [Key, ...], "label": String}. "label"
## is the human-readable name the settings screen displays - kept here
## rather than duplicated in settings_screen.gd since it's a property of
## the action, not of any one screen.
const _ACTIONS := {
	"move_up": {"default": KEY_UP, "fixed": [KEY_W], "label": "Move Up"},
	"move_down": {"default": KEY_DOWN, "fixed": [KEY_S], "label": "Move Down"},
	"move_left": {"default": KEY_LEFT, "fixed": [KEY_A], "label": "Move Left"},
	"move_right": {"default": KEY_RIGHT, "fixed": [KEY_D], "label": "Move Right"},
	"interact": {"default": KEY_SPACE, "fixed": [KEY_ENTER], "label": "Interact / Talk"},
	"toggle_inventory": {"default": KEY_I, "fixed": [], "label": "Inventory"},
	"toggle_journal": {"default": KEY_J, "fixed": [], "label": "Journal"},
	"toggle_map": {"default": KEY_M, "fixed": [], "label": "Map"},
}

signal binding_changed(action: String)
signal text_scale_changed(scale: float)

var _bindings: Dictionary = {}
var _text_scale := DEFAULT_TEXT_SCALE


func _ready() -> void:
	_load()
	for action in _ACTIONS:
		_rebuild_action(action)


func get_actions() -> Array:
	return _ACTIONS.keys()


func get_action_label(action: String) -> String:
	return _ACTIONS[action]["label"]


func get_binding(action: String) -> Key:
	return _bindings.get(action, _ACTIONS[action]["default"])


## Returns the other action already using key (as its remappable primary or
## one of its fixed aliases), or "" if key is free - checked by
## settings_screen.gd before actually rebinding, so two actions can't
## silently end up sharing a key. Without this, e.g. rebinding "interact"
## onto W (move_up's fixed alias) would make every W press both talk and
## walk, and rebinding move_up onto S would make it cancel out with
## move_down in player.gd's _read_direction() - a real, silent dead key.
func find_conflicting_action(key: Key, exclude_action: String) -> String:
	for action in _ACTIONS:
		if action == exclude_action:
			continue
		if get_binding(action) == key or _ACTIONS[action]["fixed"].has(key):
			return action
	return ""


func set_binding(action: String, key: Key) -> void:
	_bindings[action] = key
	_rebuild_action(action)
	_save()
	binding_changed.emit(action)


func reset_binding(action: String) -> void:
	_bindings.erase(action)
	_rebuild_action(action)
	_save()
	binding_changed.emit(action)


func reset_all() -> void:
	_bindings.clear()
	_text_scale = DEFAULT_TEXT_SCALE
	for action in _ACTIONS:
		_rebuild_action(action)
	_save()
	text_scale_changed.emit(_text_scale)


func get_text_scale() -> float:
	return _text_scale


func set_text_scale(scale: float) -> void:
	_text_scale = clampf(scale, TEXT_SCALE_MIN, TEXT_SCALE_MAX)
	_save()
	text_scale_changed.emit(_text_scale)


## The village/ship scenes' Hint label reads this instead of a hardcoded
## control-scheme string (issue #32) - once keys are remappable, a static
## "I for inventory" string would go stale/misleading the moment a player
## actually rebinds I to something else. WASD stays a fixed phrase since
## those are the "fixed" aliases movement always keeps regardless of
## remapping (see _ACTIONS) - only the remappable primary keys need to be
## read live.
func controls_hint_text() -> String:
	return "%s/%s/%s/%s or WASD to move, %s to talk, %s for inventory, %s for journal, %s for map" % [
		OS.get_keycode_string(get_binding("move_up")),
		OS.get_keycode_string(get_binding("move_down")),
		OS.get_keycode_string(get_binding("move_left")),
		OS.get_keycode_string(get_binding("move_right")),
		OS.get_keycode_string(get_binding("interact")),
		OS.get_keycode_string(get_binding("toggle_inventory")),
		OS.get_keycode_string(get_binding("toggle_journal")),
		OS.get_keycode_string(get_binding("toggle_map")),
	]


## Convenience for every Label that needs to honor the text-size setting
## (dialogue/hint/inventory/journal text, per issue #32's acceptance
## criteria) - one line at each call site rather than repeating the
## multiply-and-round everywhere.
func scaled_font_size() -> int:
	return int(round(BASE_FONT_SIZE * _text_scale))


func _rebuild_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, _make_key_event(get_binding(action)))
	for fixed_key in _ACTIONS[action]["fixed"]:
		InputMap.action_add_event(action, _make_key_event(fixed_key))


func _make_key_event(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	return event


func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return

	if parsed.has("bindings") and parsed["bindings"] is Dictionary:
		for action in parsed["bindings"]:
			if _ACTIONS.has(action) and (parsed["bindings"][action] is int or parsed["bindings"][action] is float):
				_bindings[action] = int(parsed["bindings"][action])
	if parsed.has("text_scale") and (parsed["text_scale"] is float or parsed["text_scale"] is int):
		_text_scale = clampf(float(parsed["text_scale"]), TEXT_SCALE_MIN, TEXT_SCALE_MAX)


func _save() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Settings: failed to open settings file for writing (%s)" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({"bindings": _bindings, "text_scale": _text_scale}))
	file.close()
