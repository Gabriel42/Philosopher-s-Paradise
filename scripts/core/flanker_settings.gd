class_name FlankerSettings
extends EnemySettings
## Every number of an enemy type that runs beside the runner and shoots at it
## (an [EnemyFlankers] node, e.g. resources/enemies/enemy2.tres). The
## inherited Speed / Intercept numbers are not used, except
## [member EnemySettings.acceleration] and [member EnemySettings.side_acceleration]
## (how fast it can change speed). Speeds in m/s, accelerations in m/s².

@export_group("Flanking")
## How far to the side of the runner each enemy keeps.
@export var side_distance := 5.0
## Gap along the run between enemies on the same side (half go left, half
## right, in rows centred on the runner: 3 per side = 4 m behind, level,
## 4 m ahead).
@export var row_spacing := 4.0
## Fastest it closes in on its spot along the run, relative to the runner
## (an enemy ahead slows down by up to this much to drop back beside you).
@export var approach_speed := 15.0
## Fastest it catches up when left behind, relative to the runner.
@export var catch_up_speed := 12.0
## Top sideways speed, relative to the runner.
@export var flank_side_speed := 10.0
## How hard it steers toward its spot (1/s): wanted speed = distance × this
## (capped, and slowed in time to stop on the spot without overshooting).
@export var steer_gain := 2.0
## Counts as "beside the runner" (and may shoot) within this of its spot.
@export var in_place_distance := 1.5

@export_group("Shooting")
## Seconds between two shots of one enemy (each starts at a random time).
@export_range(0.1, 30.0) var shot_interval := 2.0
## Speed of a shot, added to the speed of the enemy that fired it.
@export var shot_speed := 25.0
## A shot that hits nothing disappears after this many seconds.
@export var shot_life := 2.0
@export var shot_radius := 0.15
## Most shots flying at once (a fixed pool; the oldest is reused).
@export_range(1, 1000) var max_shots := 32
## Height above an enemy's feet where shots leave from.
@export var muzzle_height := 0.7
## Height above the runner's feet that shots aim at.
@export var aim_height := 1.0
@export var shot_color := Color(1.0, 0.55, 0.1)


func _init() -> void:
	display_name = "enemy2"
	count = 6
	spawn_seed = 11
	color = Color(1.0, 0.5, 0.05)
	# Twice this (0.8 m) is more than the 0.6 m body: they never overlap.
	spacing_radius = 0.4
	acceleration = 25.0
	side_acceleration = 25.0
