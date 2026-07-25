extends Node

## Global save/load autoload (see [autoload] in project.godot).
##
## Web exports keep user:// in an in-memory virtual filesystem (Emscripten
## IDBFS) backed by the browser's IndexedDB. Older Godot versions needed a
## manual JS-side FS.syncfs() call to flush writes before a reload, but as
## of this project's Godot 4.7, that global isn't even reachable from
## JavaScriptBridge.eval (it's wrapped inside the engine's own GodotFS/
## godot_js_os_fs_sync binding) - and it turns out to be unnecessary here:
## FileAccess writes on this export were verified to survive a real browser
## page reload with no manual sync call at all. Re-verify this specifically
## against a real browser (not just the editor) if this ever needs revisiting
## - see issue #3 for how this was confirmed.

const SAVE_PATH := "user://savegame.json"

## Set by the title screen before changing to the overworld scene, so the
## overworld knows whether to resolve its start position from a save
## (Continue) or use the default start (Start/new game). Consumed (reset to
## false) by whoever reads it, so it doesn't leak into a later session.
var pending_load := false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Replaces the whole save payload - it does not merge with what's already
## on disk. Fine while position is the only saved field; a future caller
## adding a second independent field (e.g. current-map state) should
## load_game()-merge-save_game() rather than call this with a partial dict,
## or an unrelated field will silently get wiped.
func save_game(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: failed to open save file for writing (%s)" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))
	file.close()


func load_game() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
