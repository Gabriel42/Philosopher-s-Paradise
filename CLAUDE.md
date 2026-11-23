# Philosopher's Paradise

3D momentum runner made in **Godot 4.7.2 (stable)** with **GDScript**.
Inspired by *Haste: Broken Worlds* (speed kept by landing on slopes, runs
through broken worlds), with its own world, art and rules (see `docs/design.md`).
Developer: Gabriel.

## Working rules (always follow)

1. **Never start a task until Gabriel approves it.** Propose a short plan first
   (what you'll change, which files, any assumptions), then wait for a clear "go".
   Small follow-up fixes inside an approved task are fine; anything beyond its
   scope needs a new approval.
2. **Always verify.** Don't assume code works: run it in Godot (see Testing).
   Check calculations and any facts you look up (Godot APIs, versions) against
   official sources such as docs.godotengine.org. Say what you verified and how.
3. One question at a time when something is unclear.
4. **Respect file ownership** (table below). Never edit Gabriel's files unless
   he asks. If his notes or the TODO conflict with a request, point it out.
5. **Inspired by, never a copy.** Take ideas from *Haste* (how momentum feels,
   the run structure), never its names, characters, levels, art, music or look.
6. Commit only when asked.

## Project files

| File | Owner | What it is |
|---|---|---|
| `CLAUDE.md` | shared | Working rules, conventions, testing (this file) |
| `docs/design.md` | Gabriel; Claude proposes edits, applies once approved | Current game rules, the source of truth |
| `docs/notes.md` | **Gabriel only** | His thoughts, direction, how he wants to proceed |
| `docs/TODO.md` | Gabriel; Claude edits anything when asked, and on its own only adds `(Claude)` items to *Ideas* / *Bugs* and moves items to *Now* (approved) and to `docs/done.md` (verified) | Work list: Now / Next / Later / Ideas / Bugs |
| `docs/done.md` | Gabriel; Claude appends verified tasks (newest first, with the date and commit) | Finished tasks. Not imported here; read it only when needed |
| `docs/verified.md` | Claude | What was tested and how; update after each verified task |

When a task changes the game's rules or feel, propose the matching
`docs/design.md` edit in the plan. Read `docs/verified.md` before testing a feature.

@docs/design.md

@docs/notes.md

@docs/TODO.md

## Project structure

```
CREDITS.md        third-party assets that need credit
docs/             design.md, notes.md, TODO.md, done.md, verified.md (see table above)
scenes/main/      main.tscn + main.gd: entry scene (sky, sun, fog, the endless
                  level with the runner in it)
scenes/level/     endless_level.tscn + .gd (EndlessLevel): keeps chunks around
                  the runner (builds ahead, frees behind), shifts the world back
                  to the centre every 2 km (origin), respawns the runner ahead
                  when it falls off
                  terrain_chunk.gd (TerrainChunk): one chunk: ground mesh with
                  hanging sides, collision, rocks and pillars
scenes/player/    runner.tscn + runner.gd (Runner): placeholder runner (follow
                  camera with mouse look, speed label)
                  runner_model.tscn + .gd (RunnerModel): Mannequiny model,
                  picks idle / run / jump animations, skydive in the air,
                  tucked roll on fast fall
                  runner_pose.gd (RunnerPose): bends the bones into the
                  skydive and tuck poses (no animation for them)
                  blocky_model.tscn: first blocky human (not used)
                  runner_effects.gd (RunnerEffects): landing effects,
                  driven by the runner's signals
scenes/enemy/     enemy_swarm.gd (EnemySwarm): every enemy, cheap: arrays of
                  numbers, a fixed pool, one MultiMesh draws them all, ground
                  height from TerrainHeight (no physics); spawns them ahead,
                  intercepts the runner, counts touches (runner_touched);
                  spacing shared by every type; _steer() is what a type
                  overrides to move its own way; flying types (enemy3) sway
                  and bob forward on their own
                  enemy_flankers.gd (EnemyFlankers, extends EnemySwarm):
                  enemy2: keeps a spot beside the runner, matches its speed,
                  shoots at it (shot pool, second MultiMesh, distance hits;
                  shot_fired / runner_shot)
scenes/debug/     debug_menu.tscn + .gd (DebugMenu): debug panel, open at
                  start, F3 toggles (per enemy type: count, touches, shots;
                  FPS)
scenes/menu/      enemy_picker.tscn + .gd (EnemyPicker): start screen, game
                  paused, one checkbox per enemy type (EnemySwarm.active),
                  choice saved in user://enemy_picker.cfg; skipped headless
scripts/autoload/ global singletons (none yet)
scripts/core/     terrain_settings.gd (TerrainSettings): every number of the level
                  terrain_height.gd (TerrainHeight): ground height at any point
                  (downhill + hills + bumps + ramps), pure and seeded
                  movement.gd (Movement): every number of the runner
                  enemy_settings.gd (EnemySettings): every number of one
                  enemy type (each type is its own EnemySwarm node)
                  flanker_settings.gd (FlankerSettings, extends
                  EnemySettings): spot beside the runner, shots
resources/        terrain.tres, movement.tres (Gabriel tweaks these)
                  enemies/: one EnemySettings per enemy type (enemy1.tres:
                  the red capsules, node Enemy1 in main.tscn; enemy2.tres:
                  the 6 orange shooters, node Enemy2; enemy3.tres: the blue
                  flyers, node Enemy3)
assets/           art/, audio/sfx/, audio/music/, fonts/
                  art/characters/mannequiny/: the runner model (CC-BY 4.0,
                  see CREDITS.md)
tests/            run_tests.tscn + run_tests.gd: the test runner (see Testing)
                  test_case.gd (TestCase): base class, asserts, keep()
                  core/: test_project (main scene loads), test_terrain_height
                  level/test_endless_level, player/test_runner, player/test_landing,
                  player/test_runner_model, enemy/test_enemy_swarm,
                  enemy/test_enemy_flankers, debug/test_debug_menu,
                  menu/test_enemy_picker
```

A script that belongs to one scene lives next to it; shared scripts go in
`scripts/`. Update this tree when you add folders or important files.

## Technical setup

- Godot **4.7.2**, renderer **Forward+** (3D: real-time shadows, glow, fog,
  SDFGI if wanted), MSAA 3D 2×. Physics: **Jolt** (`physics/3d/physics_engine`).
- Window 1280×720, `canvas_items` stretch.
- **3D units: 1 unit = 1 metre.** Up is `+Y`, forward is `-Z` (Godot's
  convention: `-basis.z` is where a node looks).
- Inputs: `move_forward/back/left/right` (WASD), `jump` (Space), `fast_fall`
  (Shift), `toggle_debug` (F3). Mouse look and gamepad to add with the player.
- Placeholder geometry is CSG (`CSGBox3D`... with `use_collision`). Fine to
  block out levels; bake to meshes (or replace with real art) once a level is
  kept, since CSG is slow when it changes at runtime.
- Keep `editor/export/convert_text_resources_to_binary=false` in
  `project.godot` (in 4.7.2 binary conversion broke `PackedStringArray`s in
  Love Will Find's exports).

## Conventions

- Official GDScript style guide: `snake_case` files, folders, variables,
  functions; `PascalCase` for node names and `class_name`; `CONSTANT_CASE`
  constants; tabs for indentation; **static typing everywhere** (`var speed:
  float`, `-> void`, `:=`).
- `##` doc comments at the top of each script and on public functions.
- Prefer signals over direct references between distant nodes.
- Keep game logic separate from presentation: rules and data in `Resource`s /
  plain classes (testable without a scene), scenes only display them and send
  input.
- **Movement feel:** every number of the runner (speeds, gravity, slope boost,
  air control, landing windows...) goes in a `Resource` (e.g.
  `resources/movement.tres`) with `@export`s, never in `const`, so Gabriel can
  tune it live in the Inspector. Physics code goes in `_physics_process`, never
  `_process`; use `delta` everywhere so speed doesn't depend on frame rate.
- Randomness that shapes a level or a run goes through its own
  `RandomNumberGenerator` with a seed, so runs stay reproducible.
- **Endless level coordinates:** positions of nodes are in the level's
  shifted space; add `EndlessLevel.origin` to get real world coordinates
  (what `TerrainHeight.height_at` takes). Anything that remembers world
  positions (trails, effects) listens to `origin_shifted`. Ground height
  must stay a pure function of the real position and the seed, so chunks
  built apart still join.
- Game content (levels, abilities, items) is defined as `.tres` resources, not
  hard-coded.
- Any full-screen `Control` that is only decoration needs
  `mouse_filter = IGNORE`, or it swallows mouse input.
- Edit `.tscn` and `project.godot` files by hand only for small changes;
  otherwise say what to do in the editor.
- Commit `.uid` files; never commit `.godot/`.

## Versions

- The version is `application/config/version` in `project.godot`
  (major.minor.patch, now 0.0.1). Bump it only when Gabriel says a version is
  released.

## Testing

Godot executable on this machine:
`GODOT = C:\Users\gabri\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
(Git Bash: `/c/Users/gabri/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`)
(on Windows use the `_console.exe` build so output appears in the terminal)

- Import / refresh: `"$GODOT" --headless --path . --import`
- Run briefly: `"$GODOT" --headless --path . --quit-after 120`
- **Test suite:** `"$GODOT" --headless --path . res://tests/run_tests.tscn`
  runs every `tests/**/test_*.gd` and prints ok / FAIL per test, then
  "N passed, N failed"; exit code 1 if anything failed. Only some files:
  add `-- --only=player` (file names containing "player"). Import first if
  you added scripts. When running it from a tool, write the output to a file
  (not through `tail`), so it can be read even if the run is stopped. A test
  file that doesn't compile shows as FAIL; a test over 60 s prints STUCK.
- **Writing tests:** a file `tests/<area>/test_<thing>.gd` that
  `extends TestCase`; each `func test_...() -> void` is one test. Asserts:
  `assert_eq`, `assert_ne`, `assert_true`, `assert_false`, `assert_between`,
  `assert_near` (floats and vectors), `fail`. `keep(node)` adds a node under
  the test and frees it afterwards. An error printed during a test fails it.
  Test movement with fixed inputs over a fixed number of physics frames
  (`await get_tree().physics_frame`), and use default resources
  (`Movement.new()`), not the tuned `.tres`, so tweaks don't break tests.
- For one-off checks that don't belong in the suite, a temporary autoload or
  script is fine: it prints results and calls `get_tree().quit()`; remove it
  afterwards and never commit it.
- `--check-only --script` on scripts that use autoloads reports false errors;
  test those by running the project instead.
- **Visuals and feel:** headless can't show them. Run with a window and save a
  screenshot from a test script:
  `get_viewport().get_texture().get_image().save_png("user://shot.png")`,
  then look at it. Movement feel can only be judged by Gabriel playing: say
  what he should try.
- Always add `--screen 1` when opening a game window (tests, screenshots), so
  it opens on Gabriel's 2nd monitor (1280×720) instead of his main one.
- Record what you verified, and how, in `docs/verified.md`.
