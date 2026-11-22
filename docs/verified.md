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
