# Verified

What was tested, and how.

## 2026-11-22 – Project setup
- `--import` then `--quit-after 120` headless: no errors.
- Test suite: 1 passed, 0 failed (`core/test_project`: the main scene loads).
- Not checked: how the placeholder world looks in a window (no screenshot taken).

## 2026-11-22 – Endless level + placeholder runner
- Test suite: 15 passed, 0 failed. New tests: terrain height (same seed same
  ground, other seed other ground, no jump over 1 m per 0.5 m up to 3 km,
  downhill overall, ramps in 10..38 of 40 chunks), endless level (chunks
  -1..3 at start, 3..7 at 500 m, chunk borders join to 1 mm, origin shift at
  2.5 km keeps the runner on the same ground and new chunks still join, falling
  respawns 20 m ahead), runner (stands on the ground, 4 s forward goes > 50 m
  and > 15 m/s, jump leaves the ground, fast fall lands in < 30 frames).
- Real game in a window (temporary script holding forward, steering to the
  middle, fast-falling when going down), 45 s: 1423 m, average ~32 m/s
  (115 km/h), top ground speed 49 m/s, several launches off ramps, no
  respawns. An earlier 90 s run passed 2 km: the origin shift happened with no
  visible jump. One chunk builds in ~11 ms (GTX 1660 SUPER).
- Screenshots looked at: rolling green hills, white rocks and pillars, sky
  under the island's edge. Found and fixed: pale colours (vertex colours now
  sRGB), dark brown below the horizon (sky ground colours now sky blue),
  hitting a rock kept the speed counter high (now speed drops to what's left).
- Not checked: how it feels with a real player and the mouse (Gabriel).

## 2026-11-22 – Landing keeps speed + landing / fast-fall effects
- Before the change (temporary probe, 40 s scripted run on the real level,
  jumping every 1.5 s, fast-falling every other jump): real landings lost
  23–32% of total speed (e.g. 34.1 m/s in the air → 23.2 m/s); the fall speed
  was all thrown away.
- After: same probe, 146 landings, average 99% of total speed kept; fast fall
  onto downhill gains (37 → 42 m/s); worst landings (rising slopes) hit the
  floor of 75% of horizontal speed (36.4 → 27.3). The scripted run now reaches
  ~100 m/s (was ~50): speeds build much more, tuning is Gabriel's call.
- Test suite: 22 passed, 0 failed. New `player/test_landing` on flat and 20°
  floors, checked against hand maths: flat 20/20 m/s → 25 (24..27), downhill
  20° → ≈31.6 (29..34) and more than the total before, uphill 20° → 15 (75%),
  `landing_convert = 0` and `landing_min_keep = 0` give the old landing (20),
  fast_fall_changed sends true then false, a hard landing leaves dust + ring,
  a tiny hop leaves nothing.
- Found: on a 20° rising slope the runner leaves the floor every other frame
  (one-frame "landings" with ~0.5 m/s impact); harmless, effects ignore
  impacts under 4 m/s.
- Screenshots in a window (`--screen 1`, temporary SceneTree script): dust +
  orange slam ring on a slow fast-fall landing, cyan ring on good landings at
  38 and 46 m/s; fast fall shows the stretched, glowing body and speed lines.
  Fixed after the first shots: trail dots covered the view behind the runner
  (removed, replaced by the glow), effects left in the world were out of view
  at speed (the ring now follows the runner), speed lines thinner.
- Not checked: how the squash and the camera shake feel in motion, and the
  feel of the new landing with a real player (Gabriel).

## 2026-11-22 – Esc quits the game
- Game in a window (`--screen 1`, temporary SceneTree script) sent an Esc key
  press at frame 60: the game quit at frame 61, exit code 0.
- Test suite: 22 passed, 0 failed (tests don't use player input).

## 2026-11-22 – Runner model (blocky human) + free models to compare
- `scenes/player/runner_model.tscn`: blocky human built from Godot shapes
  (head with visor, chest, hips, arms with shoulder/elbow joints, legs with
  hip/knee joints and feet), ~1.8 m, faces -Z; replaces the capsule in the
  runner. Collision unchanged.
- Test suite: 16 passed, 0 failed (new: the runner's model has head, chest,
  forearms and feet, head 1.5-1.8 m above the feet).
- Downloaded (CC0, licences kept next to them): KayKit Adventurers Rogue
  (GitHub, `assets/art/characters/kaykit_rogue/`) and Kenney Blocky
  Characters 2.0 (OpenGameArt mirror of kenney.nl, `assets/art/characters/
  kenney_blocky/`). Both import with no errors in 4.7.2; they face +Z (turn
  180° to face -Z like the runner). KayKit has Idle / Running_A / Jump_*
  animations, Kenney has idle / sprint / walk.
- Screenshots looked at (window, temporary scene): all models side by side at
  1.8 m, in idle and in a run pose.
- Not checked: how the model looks while running in the game (static, no
  limb swing yet).
- Lean models added to compare (licence next to each): Kenney Animated
  Characters 1 (CC0, OpenGameArt; FBX model + separate idle/run/jump FBX +
  4 skins, `kenney_animated/`), Male Base Mesh (CC0, BoQsc GitHub,
  `male_base/`, rigged, no animations), Mannequiny 0.3.0 (**CC-BY 4.0**,
  credit "GDQuest and contributors", GDQuest GitHub, `mannequiny/`; has idle,
  run, air_jump, air_land, dash). All import with no errors.
- Found: the Male Base Mesh renders 1 m above its bounding box and turned 90°
  (its skin ignores the `metarig` node's offset and turn); the comparison
  scene fixes it by hand. Kenney Animated stands in T-pose there because its
  animations are in separate files (not loaded in the comparison).
- Screenshot looked at: all 6 models side by side at 1.8 m, idle and run.

## 2026-11-22 – Mannequiny is the runner
- `scenes/player/runner_model.tscn` + `.gd` (RunnerModel): Mannequiny turned
  180° to face -Z; plays idle (< 0.5 m/s), run (sped up with ground speed,
  0.6-2.5x its pace at 7 m/s) and air_jump in the air. idle and run are set
  to loop in code (they don't loop as imported). The blocky model is kept as
  `blocky_model.tscn` (not used).
- Test suite: 17 passed, 0 failed (new: model idles standing, runs when
  moving, shows air_jump in the air; replaces the blocky body-parts test).
- Real game in a window (temporary script holding forward 2.5 s): screenshot
  from the game camera shows its back, running; one from a camera in front
  shows it faces where it runs, feet on the ground, at 32 m/s.
- Credit for Mannequiny (CC-BY 4.0) added to `CREDITS.md`.
- Not checked: how the animation pace looks to a player at high speed (the
  run is capped at 2.5x from 17.5 m/s up), landing has no animation.
- The other compared models (KayKit Rogue, Kenney Blocky and Animated, Male
  Base Mesh) were deleted afterwards; nothing referenced them.
- After merging main (landing keeps speed + effects): suite 25 passed, 0
  failed. The runner now lands on the slope with speed kept (3.7 m/s at frame
  60 with no input), so the idle check calls the model directly. Game run
  300 frames in a window: no errors.

## 2026-11-22 – Fast fall roll + skydive in the air (no glow, no speed lines)
- Removed from `runner_effects.gd`: the orange glow, the stretch, the orange
  slam ring and the speed lines. A fast-fall landing still throws more dust
  and a wider ring, in the normal colours.
- The model has no tuck or skydive animation, so `RunnerPose` (a
  `SkeletonModifier3D`, checked in 4.7.2's ClassDB: it has
  `_process_modification_with_delta`) turns bones on top of the animation,
  starting from the first frame of `idle`.
- Test suite: 27 passed, 0 failed. `player/test_landing`
  `test_fast_fall_rolls_tucked_then_skydives_then_rights`: dropped from 60 m
  with fast fall, the body turns past -300° in 0.4 s, fully tucked on the
  way, then holds -75° in the skydive pose, untucked; 0.3 s after landing it
  is upright with no pose. `player/test_runner`
  `test_model_skydives_in_the_air_only`: no pose on the ground, full
  skydive at -75° 0.45 s into a jump, gone 0.3 s after landing. The two
  effect-count tests updated (no speed-line node any more).
- Screenshots (`--screen 1`, temporary SceneTree scripts): the model alone
  from the side and from behind/above (skydive: belly down, arms and legs
  spread, head up; tuck: a tight ball); in the level from the game camera
  (skydive on a jump) and from the side (skydive, tucked mid-roll at -247°).
  An earlier try (one flip then a dive in a held `air_jump` frame) was
  replaced at Gabriel's request: roll more compact, skydive on every jump.
- Found: running forward 8 s at ~30 m/s without jumping, the runner left the
  ground 28 times over the hills and was in the skydive 137 of 480 frames
  (only airs over `skydive_delay` = 0.15 s count). A jump with Shift on flat
  ground is ~0.23 s in the air, shorter than the 0.3 s roll: the roll is cut
  and finishes turning upright after landing.
- Not checked: how it feels in play (Gabriel).

## 2026-11-22 – No stutter near the ground, lean and quicker stride uphill
- Cause found first (temporary probe, 15 s running forward on the real
  level, no jumps): going uphill the runner left the floor for one frame 31
  times (30 on rising ground), because Godot doesn't snap to the floor while
  the velocity points up. Each hop switched run → air_jump → run with a
  cross-fade: 103 animation switches in 15 s. Movement left unchanged.
- After: the model ignores airs shorter than `air_grace` (0.1 s). Same
  probe: 46 short hops, 27 animation switches (only real airs). Lean ranged
  -6° (downhill cap) to 12° forward on climbs.
- Test suite: 31 passed, 0 failed. New `player/test_runner_model`: five
  one-frame hops keep the run animation, 0.2 s in the air starts the jump,
  stride 2.0 on the flat → 2.6 on a 20° climb (14 m/s). New
  `player/test_landing` test: leans 10° forward running up a 20° floor (not
  in the skydive though off the floor every other frame), -6° going down.
  One line of `test_model_idles_when_still_and_runs_when_fast` removed (it
  expected a single off-ground frame to start the jump: the stutter).
- Screenshot from the side on a real climb at 41 m/s: body leaning forward
  into the hill, run stride.
- Not checked: how the lean and the quicker stride feel in play (Gabriel).

## 2026-11-22 – Landing runs straight on (no stomp, no squash)
- Removed the landing squash from `RunnerEffects` (and its `model` link in
  `runner.tscn`). On the ground the model now rights itself at
  `land_tip_speed` (1500°/s), leaves the skydive pose in `land_pose_blend`
  (0.05 s), and a landing cross-fades into the run in `land_blend` (0.05 s)
  instead of 0.15 s. Dust, ring and camera shake unchanged.
- Test suite: 32 passed, 0 failed. New `player/test_landing` test: fast fall
  from 20 m, the model's scale stays exactly 1 through the landing, and
  0.1 s after it plays run, upright, out of the skydive pose.
- Temporary script on the real level (jump, fast fall, windowed): at
  touchdown the run animation already plays, scale 1; 3 frames later tip 0°,
  pose 0, upright running at 37 m/s (screenshot).
- Seen: a short fast fall can land mid-roll (tip -144° at touchdown); the
  body then turns back upright in about 0.1 s.
- Not checked: how it feels in play (Gabriel).

## 2026-11-22 – Mid-roll landing finishes the flip forward; no landing ring
- `RunnerModel`: landing past head-first in the fast-fall roll (tip below
  -90°) keeps the tuck and turns forward to upright at `land_tip_speed`;
  before that it rights itself as before. `RunnerEffects`: the ring is gone
  (with `good_kept`, `good_color`, `ring_size`, `ring_time`); dust and
  camera shake stay.
- Test suite: 33 passed, 0 failed. New `player/test_landing` test: fast
  fall from 3 m with a 0.5 s roll lands at a tip below -90°, then only turns
  forward, upright and running within 0.3 s. `test_hard_landing_leaves_effects`
  now expects no ring under Effects.
- Temporary script on the real level (windowed): touchdown at -169°, then
  -194, -219, -244 ... 0 (forward only), run animation, no ring child.
  Screenshot mid-flip: tucked ball, no ring on the ground.
- Not checked: how the flip-out feels in play (Gabriel).

## 2026-11-22 – Enemies (red capsules that intercept) + F3 debug panel
- Test suite: 44 passed, 0 failed. New `enemy/test_enemy_swarm` (pretend
  runner moved by hand, `EnemySwarm.step()` at 60 Hz): runs at 0.8 × the
  runner's 30 m/s (24 ± 0.01); a jump to 60 m/s only gets it from 24 to 29 in
  0.25 s (20 m/s²); stays on `height_at` to 1 mm; an enemy 15 m to the side
  cuts off a runner going straight (1 touch); with the runner drifting right
  it leads it by > 5 m; a sidestep 5 m before contact dodges (0 touches); a
  touch counts once while overlapping, again after parting (signal sends 1,
  2); the runner 1.2 m above an enemy doesn't touch it; an enemy 25 m behind
  goes 120..240 m ahead at the runner-matched speed; an origin shift at
  2.5 km keeps enemies at the same real position; count 50 → 10 while running
  resizes the pool and the MultiMesh.
- Game in a window (`--screen 1`, temporary SceneTree scripts, runner holding
  forward): screenshots show the red capsules (ten placed 8–30 m ahead) on the
  ground, a crowd far ahead with 2000 enemies, and the F3 panel (touches,
  enemy count, FPS) toggled by a `toggle_debug` event.
- Cost of `EnemySwarm.step` (GTX 1660 SUPER machine, GDScript): 40 enemies
  0.24 ms, 500 → 2.3 ms, 2000 → 9.4 ms (≈ 4.7 µs per enemy, most of it the
  ground height). 0, 40 and 2000 enemies all run at a steady 16.7 ms per frame
  (vsync) over 300 frames. One earlier probe read 7 FPS with 2000 enemies
  while the runner was stuck on a rock; not reproduced.
- Not checked: how dodging feels with a real player (Gabriel); enemies pass
  through rocks and pillars and glide over ramps (by design, no physics).

## 2026-11-23 – Enemies reach the runner 3 s after appearing
- Math: time to meet = gap / closing speed, so closing = gap / 3 s. Before
  (spawn 120–240 m, 0.8 × runner speed): 27–55 s at 22 m/s, 10–20 s at
  60 m/s. Now each enemy gets closing = gap / `meet_time` at spawn and runs at
  the runner's forward speed minus it; spawn 45–60 m gives 15–20 m/s.
- Test suite: 46 passed, 0 failed. Changed/new in `enemy/test_enemy_swarm`:
  runs 15 m/s slower than a 30 m/s runner and stays 15 slower when it goes to
  50; sent ahead of a steady runner it reaches it in 3 ± 0.1 s at 22 m/s and
  at 60 m/s; a recycled enemy's closing speed is its distance / 3 (± 0.01).
- Game in a window (`--screen 1`, temporary SceneTree script holding forward,
  15 s, 40 enemies, runner 27–35 m/s): 116 enemies reached the runner after
  min 2.78, median 3.00, max 3.10 s. Screenshots: capsules crowd around and
  behind the runner.
- Not checked: whether enemies visibly pop in at 45–60 m (fog 0.003 only hides
  ~15% at that distance; can't tell from a still), and how it feels (Gabriel).
