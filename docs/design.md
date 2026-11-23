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
- In the air, left / right slide the runner sideways (up to 14 m/s, on top of
  turning toward the key), keeping its forward speed; letting go stops the
  slide.
- In the air the runner takes a flying pose: belly down, head forward, arms
  swept back along the body, legs together. The body points where it goes
  (head up when rising, down when falling, 70% of the climb angle, at most
  45° up / 50° down) and banks up to 30° toward the side it slides.
  Starting a fast fall, it tucks into a ball and rolls forward once, then
  opens back into the flying pose.
- Landing has no stomp and no squash: the runner snaps upright and just keeps
  running. Landing in the middle of the roll (past head-first) finishes the
  flip forward first.
- On the ground the runner leans into the slope (forward going up, a little
  back going down) and its stride quickens on climbs.

## Runs and levels
- A level is an endless strip of floating ground (80 m wide) that goes downhill, with rolling hills, small bumps and ramps (a kicker, then a downhill landing). Falling off the sides puts you back ahead with half your speed.
- Rocks and pillars are scattered on it; hitting one stops you.
- Floating platforms: after most ramps (about 2 chunks in 3 have one), a long strip of floating ground runs north, starting just under the kicker's lip so its launch carries you onto it (too slow and you hit its front edge). 20 shapes (runway, slide, rail, S-curve, banked turn, twisting ribbon, half-pipe, rollers, stepping stones, broken bridge, spearhead, funnel, kicker, two decks, rocky plaza...). They never sink into the ground below.
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
- Runs: a run is cut by **checkpoints** (how far apart, and what they look
  like: ?). At each one the run pauses: first the philosophy report, then
  the philosophy editor (see *Ideas and philosophies*). Between checkpoints
  you only run.

## Attacks
- Like in survivor games, attacks are automatic: no button, each fires on its
  own cooldown at the closest enemies within its reach, ignoring the ones
  already passed (more than 2 m behind). Shots move with the runner, so they
  keep up at any speed.
- Enemies have health (3 for now) and die from attacks; a killed enemy
  appears ahead again (counted in the debug panel).
- In the game the runner has **several attacks at once**; each one is an
  idea it was given (see *Ideas and philosophies*). For testing, for now,
  one attack at a time, swapped with the mouse wheel. The 10 placeholder
  attacks:
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
- Which attacks the game keeps: ? You get them as ideas.

## Ideas and philosophies
The main mechanic. **You never pick your upgrades.** Your philosophy picks
them for you, by rules you wrote. Inspired by FF12's gambits (an ordered
list of "if this, then that" rules that play for you), but here the rules
decide what you become, not what you do in a fight. Our own names, never
FF12's.

### Terms
- **Idea**: an upgrade. An attack, a stat or movement boost, or a boost to
  the philosophy itself (see *Ideas about the philosophy*).
- **Philosophy**: your ordered list of **rules**. Each rule says which idea
  to take when you get a choice.

### Tags
Every idea has tags. They mean nothing on their own: rules read them to
choose. One tag per category:
- **Color**: red, blue, green, gold, violet... (list: ?)
- **School**: Stoicism, Existentialism, Cynicism, Epicureanism, Nihilism,
  Absurdism, Skepticism, Utilitarianism... (list: ?)
- **Stance**: Aggressive or Passive.
- Other categories tied to philosophy (era, branch such as ethics or
  logic...): ?
- Bonuses for holding many ideas with the same tag: ? (later)

### How an idea is picked
1. During the run you earn an **idea reward** (when: ?, e.g. every N kills).
2. The game draws some **candidate** ideas (3 at first).
3. The philosophy reads its rules from the top. The first rule that matches
   a candidate takes it. You get it at once. Nothing stops the run.
4. If no rule matches: ? (a random candidate, or nothing).
- A rule is a **condition** plus what it takes. Conditions read the
  candidates' tags and the state of the run: ideas already held, speed,
  health, enemies near...
- Examples: "if I'm hurt, take a Passive idea"; "take an idea of the school
  I hold most"; "take a red idea"; "take an Aggressive idea"; "otherwise,
  take a random one".
- At first you have few rule slots and only simple conditions.

### Ideas about the philosophy
Some ideas improve the philosophy itself. Your philosophy picks them like
any other, so a philosophy that values them grows faster. For example:
- **More rules**: one more rule slot.
- **Better options**: new kinds of conditions to write rules with
  (examples: ?).
- **More idea rewards**: each idea reward gives one more idea.
- Maybe **more candidates** to choose from per reward: ?

### Checkpoints
At each checkpoint the run pauses:
1. **Report**: every choice the philosophy made since the last checkpoint,
   in order. For each one: the candidates, the idea taken, and **why**: which
   rule took it, what that rule saw (the tag or the state that matched), and
   why the rules above it didn't match.
2. **Editor**: you edit the philosophy: add, remove and reorder rules, turn
   them on or off, within the slots and options you have. Then the run goes
   on.
- The starting philosophy before the first checkpoint: ?

## Setting and art
?

## Controls
- Keyboard: WASD move, Space jump, Shift fast fall (placeholder), Esc quits, F3 debug panel (open at start for now). At start, the **setup screen** picks which enemy types appear (for testing; Enter starts), and whether the runner attacks at all (the run starts with the attack last used). R during a run goes back to the setup screen (the run starts over). Mouse wheel swaps the attack (for testing). The mouse does not move the camera: it stays fixed behind the runner, looking north down the course (tilt in `movement.tres`, `camera_pitch`). Gamepad: ?
