class_name QuestFlags

## Shared WorldState flag-name constants for Act 1's main quest thread
## (issue #21) - a single source of truth, since both main.gd (village)
## and ship.gd need to set and check several of these, unlike the
## earlier M1 flags (FLAG_ASKED_ABOUT_CAIRN, FLAG_CAIRN_LIGHT_PASSED),
## which only ever needed one script and stayed local consts there.
##
## The thread: meet Hakon in the village -> he points to Gunnar; water_npc
## only offers the way past the gate once you've met Hakon -> the ship;
## talk to Gunnar about the cargo -> a memory surfaces near the shelter
## (the ship's own challenge-layer beat) -> report back to Hakon for
## Act 1's resolution beat.

const MET_HAKON := "met_hakon"
const TALKED_TO_GUNNAR := "talked_to_gunnar"
const MEMORY_SURFACED := "memory_surfaced"
const ACT_ONE_RESOLVED := "act_one_resolved"
