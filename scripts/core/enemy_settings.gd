class_name EnemySettings
extends Resource
## Every number of one enemy type (e.g. resources/enemies/enemy1.tres). Each
## type is its own [EnemySwarm] node with its own settings.
## Enemies appear ahead of the runner, close in so they reach it about
## [member meet_time] seconds later, and move sideways to cut it off.
## Speeds in m/s, accelerations in m/s².

## Name of this enemy type (shown in the debug panel).
@export var display_name := "enemy1"
## How many enemies are out at once (can be changed while playing).
@export_range(0, 5000) var count := 40
## Seed of the spawn spots, so runs stay reproducible.
@export var spawn_seed := 7

@export_group("Body")
@export var radius := 0.3
## Full height of the capsule (the runner is 1.8 m).
@export var height := 1.0
## Invisible circle inside each enemy that others can't enter: two enemies
## keep their centres at least twice this apart (below twice [member radius]
## they still overlap a little, like a swarm). 0 = no spacing.
@export_range(0.0, 2.0) var spacing_radius := 0.2
## How many times per frame close enemies are pushed apart (more = a packed
## crowd keeps its spacing better, but costs more).
@export_range(1, 8) var spacing_passes := 3
@export var color := Color(0.85, 0.08, 0.08)
## Damage an enemy takes before it dies (see [member AttackSettings.damage]).
@export var health := 3.0

@export_group("Speed")
## Seconds from an enemy appearing to it reaching the runner. At spawn each
## enemy gets a closing speed (its distance ahead / this), then runs at the
## runner's forward speed minus it, so the timing holds when the runner
## speeds up or slows down (a runner slower than that is charged uphill).
@export_range(0.5, 20.0) var meet_time := 3.0
## How fast an enemy gets to that speed (a sudden boost leaves it behind).
@export var acceleration := 20.0

@export_group("Intercept")
## Top sideways speed when cutting the runner off.
@export var side_speed := 10.0
## How fast the sideways speed changes (lower = easier to wrong-foot).
@export var side_acceleration := 20.0
## Furthest ahead (seconds) an enemy guesses where the runner will be.
@export var max_predict_time := 4.0

@export_group("Spawning")
## Enemies appear at least this far ahead of the runner...
@export var spawn_distance := 45.0
## ...plus a random distance up to this, so they don't all come at once.
@export var spawn_spread := 15.0
## An enemy this far behind the runner is sent ahead again.
@export var recycle_distance := 20.0
## Enemies keep this far from the sides of the strip.
@export var edge_margin := 2.0

@export_group("Flying")
## On: the enemy flies instead of running (Speed and Intercept are not used).
## It flies forward (-Z) at [member fly_speed], lying flat with its nose
## along where it goes, swaying side to side and bobbing up and down at two
## different frequencies (each enemy picks its own), so it loops in a rough
## spiral. Its movement never looks at the runner: the runner only sets where
## it appears and when it is sent ahead again.
@export var flying := false
## Height of the middle of the flight above the ground (m).
@export var fly_height := 4.0
## Speed forward down the strip (m/s).
@export var fly_speed := 12.0
## How far it sways to each side of its line (m).
@export var sway_width := 3.0
## How far it bobs above and below [member fly_height] (m).
@export var bob_height := 1.5
## Side-to-side waves per second: each enemy picks one between these.
@export var sway_frequency_min := 0.25
@export var sway_frequency_max := 0.5
## Up-and-down waves per second: each enemy picks one between these.
@export var bob_frequency_min := 0.55
@export var bob_frequency_max := 0.95
## A flyer this far ahead of the runner (a slow runner left behind by them)
## is sent back to [member spawn_distance] ahead.
@export var fly_ahead_limit := 120.0

@export_group("Runner hitbox")
## Size of the runner when checking touches (matches its collision capsule).
@export var runner_radius := 0.4
@export var runner_height := 1.8
