class_name QuestLog

## Single source of truth for Act 1's main-quest progress text (issue #29) -
## both the current-objective hint (main.gd/ship.gd's _update_hint(), a
## one-line call now instead of a duplicated if/elif chain) and the
## journal's history of completed beats (journal_ui.gd) read from the same
## ordered _STEPS list, instead of two separately-maintained copies of the
## same priority-ordered logic. This also resolves the implicit invariant
## docs/DECISIONS.md's issue #25 entry flagged: ship.gd previously couldn't
## mirror main.gd's gate-check branch (it has no GATE reference), so it
## relied on unenforced reasoning about why that was still safe. Now both
## scripts call the exact same function, so there's nothing left to drift.
##
## Plain data (flag names + text), not executable callables, matching this
## project's established style (dialogue_lines, GateDefinition) over one-off
## code per step.

const GATE: GateDefinition = preload("res://data/gates/south_gate.tres")

## Checked in order; each step's "done" condition, its objective text while
## still the most-progressed incomplete step, and its journal-entry text
## once done. "gate" steps check GATE.is_unlocked() instead of a WorldState
## flag directly, so a future required_flag on the gate can't silently
## desync the journal/hint from what's actually blocking the path (see the
## comment on GATE.is_unlocked() itself).
const _STEPS := [
	{
		"flag": QuestFlags.MET_HAKON,
		"objective": "Find out what happened to the crew. Start with Hakon.",
		"completed": "Met Hakon, the expedition's sole survivor. He insists the crew never left the fjord - his hands say otherwise.",
	},
	{
		"gate": true,
		"objective": "A rockslide still blocks the path south - ask around near the water for a way past it.",
		"completed": "Found a rusted key near the water, said to lever aside the rockslide blocking the way to the ship.",
	},
	{
		"flag": QuestFlags.TALKED_TO_GUNNAR,
		"objective": "Find Gunnar and ask about the ship's cargo.",
		"completed": "Spoke with Gunnar aboard the ship - the cargo comes from nowhere he's ever traded.",
	},
	{
		"flag": QuestFlags.MEMORY_SURFACED,
		"objective": "Something about the ship doesn't sit right. Look around it.",
		"completed": "A fragment of memory surfaced on the ship's deck - someone's fear, maybe Hakon's, maybe not.",
	},
	{
		"flag": QuestFlags.ACT_ONE_RESOLVED,
		"objective": "Go back and tell Hakon what you saw.",
		"completed": "Told Hakon what surfaced on the ship. He wasn't surprised - just relieved someone else finally felt it too.",
	},
]

const _RESOLVED_OBJECTIVE := "For now, the rest stays buried with the ship."

## Side content/secrets (issue #22 pattern) - each entry is visible in the
## journal only once its own condition is met, same "found, not hinted at"
## discipline the underlying content already follows (see main.gd's
## PICKUP_PLACEMENTS/NPC_PLACEMENTS comments) - the journal records what's
## been found, it doesn't point at what hasn't.
const _SECRETS := [
	{
		"flag": QuestFlags.ASKED_ABOUT_CAIRN,
		"text": "Asked the villager by the northern road about the old cairn. Some say lights move up there at night.",
	},
	{
		"flag": QuestFlags.CAIRN_LIGHT_PASSED,
		"text": "Held steady while a strange light drifted past the cairn stones. Whatever it was, it didn't seem to mind you.",
	},
	{
		"item": "carved_token",
		"text": "Found a half-carved wooden token in the grass east of the crossroads - someone was carving a woman's likeness, never finished.",
	},
]


static func _step_done(step: Dictionary) -> bool:
	if step.get("gate", false):
		return GATE.is_unlocked()
	return WorldState.get_flag(step["flag"])


## Scans from the *most*-progressed step backward, not forward for the
## first incomplete one - those aren't equivalent once steps can complete
## out of order, which they can here: ship.gd's MEMORY_TRIGGER_CELL is
## deliberately reachable without TALKED_TO_GUNNAR ever being set (see its
## own comment), and main.gd sets ACT_ONE_RESOLVED off MEMORY_SURFACED
## alone, with no check on TALKED_TO_GUNNAR. A forward scan would get
## stuck forever on "Find Gunnar..." in that reachable state, even after
## Act 1 has actually resolved. Scanning backward for the highest-index
## done step and returning the *next* step's objective matches what the
## pre-#29 per-script _update_hint() actually did (it checked ACT_ONE_RESOLVED
## first, then MEMORY_SURFACED, etc.) - confirmed by an independent review
## after the first version of this function got this wrong.
static func get_current_objective() -> String:
	for i in range(_STEPS.size() - 1, -1, -1):
		if _step_done(_STEPS[i]):
			if i + 1 < _STEPS.size():
				return _STEPS[i + 1]["objective"]
			return _RESOLVED_OBJECTIVE
	return _STEPS[0]["objective"]


static func get_completed_steps() -> Array[String]:
	var completed: Array[String] = []
	for step in _STEPS:
		if _step_done(step):
			completed.append(step["completed"])
	return completed


static func get_discovered_secrets() -> Array[String]:
	var found: Array[String] = []
	for secret in _SECRETS:
		var item: String = secret.get("item", "")
		var is_found: bool = Inventory.has_item(item) if item != "" else WorldState.get_flag(secret["flag"])
		if is_found:
			found.append(secret["text"])
	return found
