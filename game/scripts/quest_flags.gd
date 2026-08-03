class_name QuestFlags

## Shared WorldState flag-name constants (issue #21; broadened by issue #29)
## - a single source of truth for any flag name more than one script needs.
## MET_HAKON/TALKED_TO_GUNNAR/MEMORY_SURFACED/ACT_ONE_RESOLVED were the
## first, needed by both main.gd (village) and ship.gd for the main quest
## thread. ASKED_ABOUT_CAIRN/CAIRN_LIGHT_PASSED started as local consts in
## main.gd (only one script needed them at the time) but moved here once
## quest_log.gd became a second consumer - a magic-string duplicate of
## main.gd's constant would have been the alternative, and this project's
## own precedent (see docs/DECISIONS.md's dialogue_lines entry) is to
## centralize a name the moment a second consumer needs it, not before.
##
## The main quest thread: meet Hakon in the village -> he points to Gunnar;
## water_npc only offers the way past the gate once you've met Hakon -> the
## ship; talk to Gunnar about the cargo -> a memory surfaces near the
## shelter (the ship's own challenge-layer beat) -> report back to Hakon
## for Act 1's resolution beat.
##
## Act 2's thread (issue #37, mirroring Act 1's exact shape): once
## ACT_ONE_RESOLVED, talk to Gunnar on the ship again -> he arranges
## passage, unlocking NORTH_GATE (ship.gd) north to the shoreline camp;
## talk to Hakon there -> the camp's explored; on to the second ship's
## wreck, where the same "hold still" mechanic (cairn_encounter.gd) reused
## a second time surfaces a recognition beat; report back to Hakon in the
## village for Act 2's own resolution - the same "return to Hakon" shape
## ACT_ONE_RESOLVED already established, not a new one invented for Act 2.

const MET_HAKON := "met_hakon"
const TALKED_TO_GUNNAR := "talked_to_gunnar"
const MEMORY_SURFACED := "memory_surfaced"
const ACT_ONE_RESOLVED := "act_one_resolved"

const GUNNAR_ARRANGED_PASSAGE := "gunnar_arranged_passage"
const SHORELINE_CAMP_EXPLORED := "shoreline_camp_explored"
const RECOGNITION_SURFACED := "recognition_surfaced"
const ACT_TWO_RESOLVED := "act_two_resolved"

## Side content (issue #10/#22, see main.gd's NPC/encounter wiring) - the
## cairn subplot's own two flags, unrelated to the main quest thread above.
const ASKED_ABOUT_CAIRN := "asked_about_cairn"
const CAIRN_LIGHT_PASSED := "cairn_light_passed"
