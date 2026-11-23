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
- Runs: ?

## Setting and art
?

## Controls
- Keyboard: WASD move, Space jump, Shift fast fall (placeholder), Esc quits, F3 debug panel. Mouse / gamepad: ?
