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
