class_name JournalUI
extends Panel

## Quest-log/journal panel (issue #29) - mirrors inventory_ui.gd's
## open/close/refresh pattern exactly, rather than inventing a new one.
## Content comes entirely from quest_log.gd (itself reading WorldState/
## Inventory), so this panel has no quest-progress logic of its own -
## it's a plain text view, same "placeholder visuals, M2 re-skins later"
## approach the rest of this project's UI already follows.
##
## Coexists with the existing trailing-hint-line rather than replacing it
## (see docs/DECISIONS.md's 2026-07-26 quest-log entry): the hint stays
## for at-a-glance guidance without opening a panel, matching this
## project's "exploration first, minimal friction" design pillar; the
## journal adds the history/secrets record the hint was never meant to
## carry on its own.

## Unlike InventoryUI's Label (a short, bounded item list), this panel's
## content only grows over the course of Act 1 - by the final beat it's
## long enough to overflow any fixed panel size, confirmed empirically
## against the exported build during this issue's own verification pass.
## A ScrollContainer (see the .tscn) keeps all of it actually reachable
## instead of silently clipping the bottom of the "So far"/"Also found"
## lists once they grow past a fixed panel height.
@onready var _label: Label = $ScrollContainer/Label

var _is_open := false


func _ready() -> void:
	visible = false
	_label.add_theme_font_size_override("font_size", Settings.scaled_font_size())


func open() -> void:
	refresh()
	visible = true
	_is_open = true


func close() -> void:
	visible = false
	_is_open = false


func is_open() -> bool:
	return _is_open


## Rebuilds the displayed text from QuestLog's current state - called on
## open() rather than kept continuously in sync, same reasoning as
## InventoryUI.refresh(): nothing needs to see it change while closed.
func refresh() -> void:
	var lines: Array[String] = []
	lines.append("Current objective:")
	lines.append(QuestLog.get_current_objective())

	var completed := QuestLog.get_completed_steps()
	if not completed.is_empty():
		lines.append("")
		lines.append("So far:")
		for entry in completed:
			lines.append("- %s" % entry)

	var secrets := QuestLog.get_discovered_secrets()
	if not secrets.is_empty():
		lines.append("")
		lines.append("Also found:")
		for entry in secrets:
			lines.append("- %s" % entry)

	_label.text = "\n".join(lines)
