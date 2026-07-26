# Devlog #1 — One Man Remains (draft)

Draft for issue #24, meant to be pasted into itch.io's built-in devlog feature once the project page exists. Not final until reviewed.

---

**Hello, and welcome to the fjord.**

This is the first public build of this project — a small top-down exploration/story RPG, built solo with heavy AI-assisted engineering, in the spirit of GBA-era Pokemon games: grid-based movement, a tile-based world, readable pixel art. "Pokemon-scale" here means *length and breadth of world*, not the creature-collecting — there's no battle system, no monsters to catch. Combat is replaced with a much lighter challenge layer (you'll meet it — it mostly asks you to hold your nerve, not fight anything).

**What's in this build**

This chapter, "One Man Remains," is the game's first act. A longship returns to the settlement five months late, drifting in with no one at the oars. Only one person aboard is still alive, and his account of the voyage doesn't match what's still sitting in the ship's hold. You play someone close enough to the situation to start asking the questions nobody else wants to ask yet.

It's short by design — a first taste of the systems and the world rather than the full game. Expect somewhere around fifteen to thirty minutes if you talk to everyone and poke into the corners. There are a few things tucked away that nobody points you toward directly; that's intentional.

**What's under the hood**

Everything you're playing — the map, the dialogue, the item/inventory system, the save system, the quest-flag state that makes NPCs react to what you've actually done — was built solo with AI-assisted engineering, tracked issue-by-issue in the open. The art is procedurally generated placeholder art (built with a small Python/Pillow pipeline), not final illustration — a real art bible and a more deliberate production pipeline are the very next milestone. If the world looks a little rough around the edges right now, that's expected and temporary, not the intended final look.

**What's next**

The plan is to build this out act by act: a real art pass next, then the systems a much longer game needs (quest log, world map, accessibility options), then more content acts continuing this story. This first chapter deliberately leaves its central question — why the crew was afraid to come home — unresolved. That's not a plot hole; it's where the next chapter picks up.

**A note on feedback**

This is genuinely early, and feedback shapes where this goes next — bugs, confusing moments, things that didn't land, all useful. Thanks for playing.
