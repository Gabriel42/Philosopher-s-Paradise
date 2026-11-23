class_name Movement
extends Resource
## Every number of the runner's movement (resources/movement.tres).
## Speeds in m/s, accelerations in m/s², turn rates in radians per second.

@export_group("Running")
## Top speed reached by running alone (slopes can take you much faster).
@export var run_speed := 22.0
## How fast running gets you to run_speed.
@export var run_accel := 25.0
## Slowing down when holding back.
@export var brake := 30.0
## Slowing down on the ground with no input.
@export var friction := 4.0
## Absolute top speed.
@export var max_speed := 140.0
## Air resistance: slowing of drag × speed² (the higher, the lower the speed
## reached going down a slope).
@export var drag := 0.0006
## Turning on the ground at low speed and at max speed.
@export var turn_rate_slow := 6.0
@export var turn_rate_fast := 1.5

@export_group("Slopes")
## How much a slope speeds you up going down (and slows you going up).
## 1 = like a ball rolling without friction.
@export var slope_factor := 1.0
## Steepest ground you can stand on, in degrees.
@export var max_floor_angle := 60.0
## How far the runner is pulled down to stay glued to the ground.
@export var floor_snap := 1.0

@export_group("Air")
@export var gravity := 30.0
## Gravity while holding fast fall.
@export var fast_fall_gravity := 110.0
@export var jump_velocity := 11.0
@export var air_turn_rate := 1.2
## Speeding up in the air while under run_speed.
@export var air_accel := 8.0
## Sideways speed that left / right give in the air (m/s), on top of the
## turning: the runner slides sideways while keeping its forward speed.
@export var air_side_speed := 14.0
## How fast that sideways speed comes and goes (m/s²).
@export var air_side_accel := 45.0

@export_group("Landing")
## Part of the speed along the ground kept when landing (1 = all of it).
## Landing along a downhill slope keeps your speed; landing flat loses the
## falling part.
@export_range(0.0, 1.0) var landing_keep := 1.0
## Part of the fall speed (the speed into the ground) turned into ground
## speed when landing on a downhill slope of [member landing_full_slope] or
## steeper. Flat ground gives half of it, a rising slope as steep gives none.
@export_range(0.0, 1.0) var landing_convert := 0.5
## Slope (degrees, going down your way) that gives all of [member landing_convert].
@export_range(1.0, 60.0) var landing_full_slope := 20.0
## A landing never leaves you with less than this part of the horizontal
## speed you had just before it.
@export_range(0.0, 1.0) var landing_min_keep := 0.75
## Part of the speed kept after falling off the world.
@export_range(0.0, 1.0) var respawn_keep := 0.5

@export_group("Camera")
@export var mouse_sensitivity := 0.003
@export var camera_distance := 5.0
## Camera distance and field of view at max speed (they grow with speed).
@export var camera_distance_fast := 8.0
@export var fov := 75.0
@export var fov_fast := 100.0
