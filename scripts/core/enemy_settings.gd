class_name EnemySettings
extends Resource
## Every number of the enemies (resources/enemy.tres).
## Enemies appear ahead of the runner, run downhill a little slower than it,
## and move sideways to cut it off. Speeds in m/s, accelerations in m/s².

## How many enemies are out at once (can be changed while playing).
@export_range(0, 5000) var count := 40
## Seed of the spawn spots, so runs stay reproducible.
@export var spawn_seed := 7

@export_group("Body")
@export var radius := 0.3
## Full height of the capsule (the runner is 1.8 m).
@export var height := 1.0
@export var color := Color(0.85, 0.08, 0.08)

@export_group("Speed")
## Part of the runner's speed an enemy tries to run at (below 1: the runner
## catches up, so they meet).
@export_range(0.0, 2.0) var speed_ratio := 0.8
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
@export var spawn_distance := 120.0
## ...plus a random distance up to this, so they don't all come at once.
@export var spawn_spread := 120.0
## An enemy this far behind the runner is sent ahead again.
@export var recycle_distance := 20.0
## Enemies keep this far from the sides of the strip.
@export var edge_margin := 2.0

@export_group("Runner hitbox")
## Size of the runner when checking touches (matches its collision capsule).
@export var runner_radius := 0.4
@export var runner_height := 1.8
