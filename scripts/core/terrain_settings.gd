class_name TerrainSettings
extends Resource
## Every number that shapes the endless level (resources/terrain.tres).
## 1 unit = 1 metre; "distance" means how far forward (along -Z) from the start.

@export var terrain_seed := 1

@export_group("Size")
## Length of one chunk of ground (along -Z).
@export var chunk_length := 120.0
## Width of the floating strip of ground (along X).
@export var width := 80.0
## Distance between two vertices of the ground mesh.
@export var cell_size := 2.0
## Chunks kept in front of the runner.
@export var chunks_ahead := 3
## Chunks kept behind the runner.
@export var chunks_behind := 1

@export_group("Shape")
## Height lost per metre forward, on average (0.12 = 12 % downhill).
@export var downhill_grade := 0.12
## Height of the big rolling hills (up and down from the average).
@export var hill_height := 14.0
## Rough distance between two big hills.
@export var hill_wavelength := 160.0
## Height of the small bumps on top of the hills.
@export var bump_height := 2.0
## Rough distance between two small bumps.
@export var bump_wavelength := 28.0
## The hills and ramps grow in over this distance from the start, so the
## runner starts on a smooth slope.
@export var start_smooth_distance := 60.0

@export_group("Ramps")
## Chance that a chunk has a ramp (a kicker, then a downhill landing).
@export_range(0.0, 1.0) var ramp_chance := 0.6
@export var ramp_height_min := 4.0
@export var ramp_height_max := 8.0
## Length of the kicker (rising part).
@export var ramp_length := 22.0
## Length of the downhill landing after the kicker's lip.
@export var landing_length := 30.0
## Length of the way back up to the normal ground after the landing.
@export var recovery_length := 30.0
## How deep the landing goes below the normal ground, as a part of the ramp's height.
@export var landing_depth_ratio := 0.6

@export_group("Obstacles")
@export var obstacles_per_chunk := 5

@export_group("Platforms")
## Floating platforms that can follow a ramp (one is picked at random each
## time). Empty = no platforms.
@export var platforms: Array[PlatformShape] = []
## Chance that a ramp has a platform after it.
@export_range(0.0, 1.0) var platform_chance := 0.7
## How far past the ramp's lip the platform starts (the kicker launches you
## onto it).
@export var platform_gap := 10.0
## How far below the lip the platform's top starts.
@export var platform_drop := 0.5
## Space always kept between a platform's underside and the ground below.
@export var platform_clearance := 1.5
## Where the ground below is close, a platform's underside gets shallower,
## down to this part of its depth; closer than that, the platform is skipped.
@export_range(0.0, 1.0) var platform_min_depth := 0.3
## Platforms tried after a ramp before giving up (a platform is skipped if
## the ground ahead would push it too high to land on).
@export var platform_tries := 6

@export_group("Island")
## How far the sides of the strip hang down (the floating island look).
@export var skirt_depth := 25.0

@export_group("World")
## When the runner is this far from (0, 0, 0), the whole world shifts back to
## the centre (far from it, 3D numbers lose precision and things shake).
@export var origin_shift_distance := 2000.0
## Falling this far below the ground respawns the runner ahead.
@export var fall_depth := 50.0

@export_group("Colors")
@export var grass_color := Color(0.42, 0.62, 0.36)
@export var steep_color := Color(0.86, 0.78, 0.6)
@export var rock_color := Color(0.42, 0.37, 0.34)
@export var obstacle_color := Color(0.93, 0.92, 0.88)


## Total length of one ramp (kicker, landing, recovery).
func ramp_total_length() -> float:
	return ramp_length + landing_length + recovery_length
