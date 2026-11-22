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
