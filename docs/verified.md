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

## 2026-11-23 – Current enemy type named enemy1
- `--import` clean, test suite 46 passed, 0 failed, `--quit-after 300`
  headless with no errors.
- Temporary SceneTree script on the main scene: node `EndlessLevel/Enemy1`
  uses `res://resources/enemies/enemy1.tres` and has 40 enemies; the F3 label
  reads "Enemies (enemy1): 40".

## 2026-11-23 – Enemies keep a little space between them
- `spacing_radius` 0.2 m (capsule radius 0.3): centres stay ≥ 0.4 m apart,
  pushed apart sideways each frame (grid of 0.4 m cells hashed into packed
  arrays, close pairs listed once, then `spacing_passes` = 3 passes).
- Test suite: 49 passed, 0 failed. New: two enemies on one spot end 0.4 ±
  0.01 m apart after one step; 40 enemies dropped in 1 m² and all cutting off
  the same runner for 1 s stay > 0.36 m apart (1 pass only reached 0.32, 2+
  pass); spacing 0 leaves them overlapping.
- Found and fixed while testing: a neighbour cell hashing to the enemy's own
  slot paired the enemy with itself and shoved it sideways (crowd test went
  to 0.11 m).
- Cost of `step` (headless, 60 steps): 40 enemies 0.15 → 0.24 ms (0.26 packed
  in 10 × 10 m); 2000 enemies 7.2 → 14.2 ms spread out, 22.4 ms packed. A
  first version with a Dictionary grid took 20.7 ms for 2000.
- Game in a window (`--screen 1`, holding forward, 15 s, 40 enemies): 120
  meets, 2.70–3.17 s (median 3.00); closest pair seen 0.348 m. Screenshot:
  a packed clump around the runner, capsules touching and a bit overlapped,
  none inside another.
- Not checked: how it looks and feels in play (Gabriel). 2000 enemies with
  spacing on would now drop below 60 FPS.

## 2026-11-23 – enemy2: flankers that keep beside the runner and shoot
- `--import` clean, `--quit-after 300` headless with no errors. Test suite:
  65 passed, 0 failed (enemy1 tests unchanged after moving its steering into
  `_steer()`).
- New `enemy/test_enemy_flankers` (15): defaults and `enemy2.tres` (6,
  orange), spots 3 per side at ±5 m, rows −4/0/+4 m, a spot past the edge
  goes to the other side; they appear > 40 m ahead; at 30 m/s all 6 are
  within 1 m of their spot after 8 s and still after 13 s, speed 30 ± 0.5,
  no touches; still within 1.5 m after speeding to 45 m/s and drifting
  4 m/s right; a 0.5 s boost to 60 m/s leaves them > 3 m behind, 8 s later
  back within 1 m; closest pair over 10 s ≥ 0.6 m (no overlap); no shots
  before reaching the spots; 25–50 shots in 20 s, more than half hit; a
  runner standing still gets hit; `aim_shot` passes within 5 cm of a moving
  target; shots end within their 2 s life; origin shift keeps enemies and
  shots in place.
- New `debug/test_debug_menu` (2): main scene's panel is open at start, lists
  "enemy1: 40 out", "enemy2: 6 out", "Enemy2 shots: 0 fired / 0 hit"; F3
  closes it.
- Found and fixed while testing: enemies trailed their spot by one frame of
  travel (1.00 m at 60 m/s, 0.42 m at 25): gaps are now measured from where
  they end the frame (probe: 0.00 m at both speeds). Test runner faked
  `vel.y = 0` on hills, so shots missed (20 / 49 hit); it now passes the real
  velocity, as the game does.
- Game in a window (`--screen 1`, temporary SceneTree script holding forward,
  30 s, speeds 26–64 m/s with ramps and fast falls): enemy2 at their spots
  67% of the time after the first 6 s, off by up to 3 m after boosts and
  14.5 m once after a sudden slowdown, back within ~2 s; 55 shots, 29 hit
  (the rest mostly hit bumps in the ground on the way). Screenshots: 6
  orange capsules both sides of the runner, a glowing orange shot in flight
  next to its shooter, panel open at start with both types and the shot
  counter, 60 FPS.
- Not checked: how it feels to be flanked and shot at (Gabriel). Shots are
  small (0.15 m) and fly 0.2 s, so they are hard to see.

## 2026-11-23 – Start screen picks which enemy types appear
- Test suite: 73 passed, 0 failed. New: enemy1 and enemy2 turned off empty
  their pool at once (0 drawn, no shot left flying, none fired while off)
  and come back ahead when turned on; `menu/test_enemy_picker` (6): lists
  enemy1 and enemy2 ticked, unticking turns that type off (other stays at
  6), open pauses the game until Start (signal sent), Enter starts, the
  choice is saved and ticked again next time, the main scene's picker finds
  both types and doesn't open (or pause) headless.
- `--import` clean, `--quit-after 300` headless with no errors.
- Game in a window (`--screen 1`, temporary SceneTree script): picker open
  and game paused at frame 30 (runner still at z = −5 after 2 s, mouse
  free); unticked enemy1, sent Enter: picker closed, unpaused, mouse
  captured, then 0 enemy1, 6 enemy2, 7 shots; debug panel "enemy1: off".
  Saved file read back: enemy1=false, enemy2=true (deleted afterwards, so
  the first real start has both ticked).
- Fixed after the first screenshot: the world freezes before the camera
  pulls back (runner's back fills the screen) → dark backdrop behind the
  panel; the debug panel was paused and showed its placeholder text → it now
  updates while paused.
- Not checked: clicking the checkboxes with the real mouse (set from the
  script instead).
## 2026-11-23 – enemy3: blue flyers
- Test suite: 60 passed, 0 failed. New flyer tests in `enemy/test_enemy_swarm`:
  the same seed gives exactly the same flight for a runner standing still and
  one zig-zagging and jumping (3 s, 5 flyers, every frame); forward 2 s at
  12 m/s = 24 m (±0.01); 20 flyers over 5 s stay 2.5–5.5 m above the ground
  (fly height 4 ± bob 1.5), so always above a standing runner's head; each
  picks sway 0.25–0.5 Hz and bob 0.55–0.95 Hz (bob always faster, flyers
  differ); over 10 s the sway reaches ±3 m (±0.05) and the bob crosses its
  middle 2 × f × 10 times (±1.5); the capsule's long axis matches the
  frame's direction of travel (0.001) and stays within 60° of forward (max
  ~47° from the waves plus the slope); passed by 20 m → sent 45–60 m ahead,
  over 120 m ahead → sent back; standing under one doesn't touch, a head in
  its belly touches once; 20 flyers over 10 s stay inside the strip margin.
  New `debug/test_debug_menu`: one line per type ("enemy3: 20 out, 0
  touches"), and the main scene has Enemy1 + Enemy3 (flying, 20, blue).
  enemy1's tests are unchanged and pass.
- MultiMesh buffer layout: headless can't read transforms back (dummy
  renderer), so in a window the transform decoded from the swarm's buffer was
  compared with `MultiMesh.get_instance_transform(0)`: identical.
- Game in a window (`--screen 1`, temporary autoload, holding forward):
  screenshots at the start and at ~35 m/s: 20 blue capsules spread over the
  strip a few metres up, lying flat, nose forward and tilted by their waves,
  with shadows on the ground; F3 panel shows both types; 55–60 FPS.
- Not checked: how the movement looks in motion and how it feels (Gabriel).
  The runner model is also blue, so the flyers' colour is close to it.

## 2026-11-23 – Merge of enemy3 into main (with enemy2 and the start screen)
- Conflicts resolved keeping both: `EnemySwarm` has the flying mode
  (enemy3) and the `_steer` / `_after_step` / `_resize` hooks and `active`
  switch (enemy2, picker); the debug panel keeps `panel_text()` and adds
  "off" and shot lines; `main.tscn` has Enemy1, Enemy2, Enemy3, the debug
  panel with all three and the picker (enemy3's ext_resource renumbered to
  `10_enemy3`); both `test_debug_menu.gd` files merged into one.
- `--import` clean, `--quit-after 300` headless with no errors. Test suite:
  85 passed, 0 failed (1 expected failure first: the picker now finds 3
  types; test updated to enemy1/enemy2/enemy3, plus a new test that a
  flying type empties when unticked).
- Game in a window (`--screen 1`, temporary SceneTree script): picker shows
  enemy1, enemy2, enemy3 ticked; with only enemy3 ticked the run has 0 / 0 /
  20 enemies, panel "enemy1: off", "enemy2: off", "enemy3: 20 out", 60 FPS,
  blue flyers spread over the strip. Saved choice deleted afterwards.

## 2026-11-23 – Runner attacks (10, automatic, mouse-wheel swap)
- `--import` clean, `--quit-after 300` headless with no errors. Test suite:
  107 passed, 0 failed. New `player/test_attacks` (22 tests): enemy damage /
  kill / sent ahead / generation, capsule distance, dead targets; each of the
  10 attacks kills enemies placed in front of a still runner (Arc Chain kills
  3 in a chain, Lance 3 in a line, Starfall not before its 0.8 s fall, Vortex
  pulls two enemies 4 m apart to < 3 m and kills both in ~1.25 s, Glaive
  comes back); aims at the closest, skips enemies passed (6 m behind), no
  shot with nobody in reach, hits a flyer, Spark Bolt still kills from a
  runner going 40 m/s, shots follow the origin shift, turning off clears
  shots; the scene has 10 different attacks, one on at a time; wheel down /
  up swaps and wraps (index 1, then 0, then 9), label shows "10/10".
- Real game in a window (temporary script, runner holding forward, all 3
  enemy types, start screen skipped), each attack on for ~1–5 s with a
  screenshot: all 10 fire and kill (e.g. Pulse 25, Vortex 24, Orbit Stones 22,
  Lance 11, Arc Chain 10 kills), 54–60 FPS. Found and fixed: (1) attacks aimed
  behind the runner at enemies already passed: now skipped
  (`ignore_behind`, 2 m); (2) fast shots passed through enemies (~1.9 m per
  frame at speed): hits are now swept along the path each frame. A trace of
  18 Spark Bolts then showed all 18 hitting.
- The 2nd monitor wasn't connected this time (`--screen 1` out of range), so
  the window opened on the main one.
- Not checked: how the attacks feel and look while playing (Gabriel); the
  mouse wheel with a real mouse (tested by sending the wheel events).

## 2026-11-23 – Attacks checkbox on the start screen
- Test suite: 114 passed, 0 failed. New: picker without attacks has no
  checkbox; the checkbox is ticked by default, unticking turns every attack
  off and hides the label, ticking turns the current one back on; "off" is
  remembered by the next picker; the attack last used (swapped during the
  run) is the one the next run starts with; the main scene's picker has the
  checkbox wired to `Runner/Attacks`; debug panel shows "Attack: Spark Bolt
  (0 fired, 0 kills)", then "Attack: off"; disabled attacks ignore the wheel
  and kill nothing in 0.5 s, then kill again once enabled.
- Game in a window (temporary script; `user://enemy_picker.cfg` backed up
  and restored afterwards): the start screen shows "Runner / Attacks (mouse
  wheel swaps)" under the enemy types; unticked and started, a 4 s run had
  no attack label, panel "Attack: off", 0 kills, and the file saved
  `[attacks] enabled=false index=0`.
- Not checked: clicking the checkbox with the real mouse (set from the script).

## 2026-11-23 – Floating platforms (20 shapes, after ramps)
- Previews: `scenes/debug/platform_preview.tscn` in a window builds all 20
  shapes and saved 20 numbered shots + an overview to
  `docs/previews/platforms/`; looked at the overview and #1, 6, 8, 10, 11,
  15, 16, 18, 20: each shape came out as meant (curves, bank, trough, gaps,
  second deck, kicker, rough edges and rocks), wedge nose on the front.
- Placement probe (temporary script, real `terrain.tres`, seed 1): 1000
  chunks, 585 ramps, 286 platforms (about one every 420 m); all 20 shapes
  appear, from 29 (Level shelf) down to 5 (Steep slide: a 30 % slope dives
  into the ground fast, so it is often cut or skipped). Placing costs
  ~1.3 ms per chunk, building one ~3 ms. 18 of 20 shapes show in the first
  200 chunks.
- Launch probe (temporary, main scene headless at fixed 60 fps): the runner
  put 40 m before each of the first 19 platforms' lips, lined up, held
  forward at 20 / 30 / 40 / 55 m/s. Landed on it 15 / 17 / 16 / 16 of 19;
  misses: hitting the front edge when slow (4 / 2 / 2 / 0), mostly the
  Funnel (7 m wide front), and overshooting short ones at 55 m/s. Tried
  gap 8 m / drop 1 m (90 % landed, 26 % fewer platforms) and 6 / 1 (all
  landed, 63 % fewer): kept 10 / 0.5.
- Real game in a window: screenshots off the kicker (platform ahead) and
  running on Level shelf, Twisting ribbon and Diagonal; 60 FPS.
- A full-run probe got stopped by a pillar right after a platform's end
  (x −16, 1502 m): the existing "rocks stop you" rule, not a platform bug.
- Test suite: 95 passed, 0 failed. New `level/test_platforms` (10): builder
  mesh = collision, shallower hull and cut length; same seed same
  platforms; 8+ platforms after ramps in 80 chunks; none without shapes;
  each starts platform_gap past its lip with the middle of its top
  platform_drop under it; every mesh vertex > 0.5 m above the ground
  (sampled 2 m, placement checks every 4 m); no rocks under platforms (40
  per chunk); level keeps a platform past its chunk, origin shift moves it,
  freed far behind; no two platforms cross (120 chunks, with a long
  drifting shape added).
- Not checked: how reaching them feels with a real player steering and
  jumping (Gabriel); `--screen 1` fell back to the main monitor (Godot saw
  only one screen).

## 2026-11-23 – More frequent platforms, setup screen, R goes back to it
- Platform rate (temporary script, 5 seeds × 200 chunks, the real
  `terrain.tres`): before (ramp_chance 0.6, platform_chance 0.7, 6 tries)
  29% of chunks had a platform. With platform_chance 1.0, a third of ramps
  still got none (no shape fit), so tries went up too: ramp 0.8 / platform
  1.0 / 6 tries 55%, 12 tries 60%, **20 tries 65%** (kept, set in
  `terrain.tres`; defaults unchanged, so tests are unaffected).
- Renamed EnemyPicker to SetupScreen (`scenes/menu/setup_screen.*`, test
  `menu/test_setup_screen`); save file still `user://enemy_picker.cfg`.
- Test suite: 126 passed, 0 failed. New: R (physical key) sends
  `back_requested` only while the setup screen is closed, not on key
  repeat; the main scene connects it to itself.
- Game in a window (`--screen 1`, temporary autoload): setup screen open and
  paused at start; after Start and 3 s of running, a real R key event
  (`Input.parse_input_event`) reloaded the scene: new Main, setup screen
  open, game paused, mouse visible, runner back at the start (z −5). The
  screenshot showed the setup screen with the saved choice ticked.
- Not checked: how the denser platforms feel to play (Gabriel).
