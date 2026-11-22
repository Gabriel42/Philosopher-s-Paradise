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
