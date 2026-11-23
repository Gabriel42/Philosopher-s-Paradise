# Philosopher's Paradise – Design

> Living document, the source of truth for the game's rules. `?` = not decided yet.

## Pitch
? (a 3D momentum runner; what the "philosopher" and the "paradise" are is still to decide)

## Genre & references
- Genre: 3D third-person momentum runner, run-based.
- Inspiration: **Haste: Broken Worlds** (Landfall): speed is everything; you keep
  and gain it by landing smoothly on downward slopes, lose it on bad landings;
  short levels strung into a run across broken worlds. We take the *feel*, not
  its world, characters or look.

## Core loop
?

## Movement
? (speeds, slopes, jump, abilities)
- Landing keeps your speed along the ground and turns part of your fall into
  forward speed: the most on a downhill slope, half on flat ground, none on a
  rising slope. You always keep at least ~75% of your horizontal speed.
- Fast fall into a downhill slope is how you gain speed.
- Effects show it: dust at the feet on landing (more after a fast fall), a
  camera shake on hard landings. No ring.
- In the air the runner takes a skydive pose (belly down, arms and legs
  spread). Starting a fast fall, it tucks into a ball and rolls forward once,
  then opens back into the skydive.
- Landing has no stomp and no squash: the runner snaps upright and just keeps
  running. Landing in the middle of the roll (past head-first) finishes the
  flip forward first.
- On the ground the runner leans into the slope (forward going up, a little
  back going down) and its stride quickens on climbs.

## Runs and levels
- A level is an endless strip of floating ground (80 m wide) that goes downhill, with rolling hills, small bumps and ramps (a kicker, then a downhill landing). Falling off the sides puts you back ahead with half your speed.
- Rocks and pillars are scattered on it; hitting one stops you.
- Each level comes from a seed: the same seed gives the same ground.
- Enemies. **enemy1** (placeholder: small red capsules) appear 45–60 m ahead and close in
  so they reach you about 3 s after appearing, however fast you go (they run
  a fixed amount slower than you, charging uphill if you're slow), moving
  sideways to cut you off; you dodge them. They can overlap each other a
  little but keep some space between them, so they look like a swarm, not a
  blob. Touching one does nothing yet (only counted).
- **enemy2** (placeholder: orange capsules, 6 at a time) appear ahead, take a
  spot beside you (3 per side, 5 m out, 4 m apart) and keep up with your
  speed (a sudden boost leaves them behind for a moment), shooting at you
  every ~2 s. They never overlap. Shots do nothing yet (only counted).
- **enemy3** (placeholder: blue capsules lying flat, nose forward), 20 of them,
  fly ~4 m above the ground. Their movement ignores the runner: each one flies
  forward at its own steady pace while swaying side to side and bobbing up and
  down at two different frequencies (each has its own), so it loops in a rough,
  never-repeating spiral and the group looks like a loose wavy flock. They appear
  ahead of you and come back ahead when you pass them. Out of reach on the
  ground: you hit one only by jumping into it. Touching one is only counted.
- Runs: ?

## Attacks
- Like in survivor games, attacks are automatic: no button, each fires on its
  own cooldown at the closest enemies within its reach, ignoring the ones
  already passed (more than 2 m behind). Shots move with the runner, so they
  keep up at any speed.
- Enemies have health (3 for now) and die from attacks; a killed enemy
  appears ahead again (counted in the debug panel).
- For testing, one attack at a time, swapped with the mouse wheel. The 10
  placeholder attacks:
  1. **Spark Bolt**: a fast, slightly homing bolt at the closest enemy, often.
  2. **Arc Chain**: instant lightning that jumps from enemy to enemy (5).
  3. **Orbit Stones**: 4 stones circling you, hitting what runs into them.
  4. **Pulse**: a wave around you (7 m) when an enemy is that close.
  5. **Lance**: an instant beam toward the closest, through everything in line.
  6. **Seekers**: 3 homing missiles on different enemies, small blasts.
  7. **Starfall**: a ring marks an enemy, a rock lands on it 0.8 s later (blast).
  8. **Glaive**: a disc thrown at an enemy that comes back, hitting both ways.
  9. **Shard Fan**: 5 shards in a fan, each going through 2 enemies.
  10. **Vortex**: a well on the closest group that pulls them in and hurts over time.
- Which attacks the game keeps, and how you get or upgrade them: ?

## Setting and art
?

## Controls
- Keyboard: WASD move, Space jump, Shift fast fall (placeholder), Esc quits, F3 debug panel (open at start for now). At start, a screen picks which enemy types appear (for testing; Enter starts), and whether the runner attacks at all (the run starts with the attack last used). Mouse wheel swaps the attack (for testing). Mouse / gamepad: ?
