class_name PlatformShape
extends Resource
## Every number of one floating platform (resources/platforms/*.tres).
## A platform is a long strip of floating ground that runs north (along -Z,
## the way the runner goes). "Distance" is how far along it from its start.
## Built by [PlatformBuilder].

## Short name shown in the previews.
@export var label := ""

@export_group("Size")
## Length along -Z.
@export var length := 80.0
## Width across (X) at the start.
@export var width := 12.0
## Width at the end, as a part of [member width] (1 = same, 0.2 = pointy).
@export_range(0.05, 3.0) var end_width_ratio := 1.0
## Distance between two vertices of the mesh.
@export var cell_size := 2.0

@export_group("Height")
## How high the start floats above the main ground.
@export var float_height := 10.0
## Height lost per metre forward (0.12 = parallel to the main ground,
## 0 = level, so it rises above the ground as the ground falls away).
@export var grade := 0.12
## Up and down waves along the platform (0 = none).
@export var wave_height := 0.0
@export var wave_length := 40.0
## Side tilt in degrees (positive = right side lower).
@export_range(-45.0, 45.0) var bank_degrees := 0.0
## Side tilt that swings from one side to the other along the platform
## (a twisting ribbon), in degrees.
@export_range(0.0, 45.0) var twist_degrees := 0.0
## How far the top dips in the middle across (a half-pipe), in metres.
@export var trough_depth := 0.0

@export_group("Curve")
## Sideways swing of the centre line (an S-curve), in metres.
@export var curve_amount := 0.0
## Distance of one full sideways swing.
@export var curve_wavelength := 120.0
## Sideways drift from start to end (a diagonal platform), in metres.
@export var drift := 0.0

@export_group("Pieces")
## Number of pieces with gaps between them (1 = one piece).
@export_range(1, 20) var pieces := 1
## Length of each gap between two pieces.
@export var gap_length := 6.0
## Each piece after the first is moved up or down by up to this (steps).
@export var piece_step := 0.0
## Extra decks stacked above (0 = one deck).
@export_range(0, 3) var extra_decks := 0
## Height between two decks.
@export var deck_spacing := 8.0

@export_group("Kicker")
## Height of a kicker that rises at the end (0 = none).
@export var kicker_height := 0.0
## Length of that kicker.
@export var kicker_length := 14.0

@export_group("Look")
## How far the underside hangs below the edges (the floating island look).
@export var skirt_depth := 8.0
## Random in-and-out of the edges, in metres (rough, natural edges).
@export var edge_wobble := 0.0
## Rocks and pillars on top.
@export_range(0, 30) var obstacles := 0
## Seed for the wobble and the obstacles.
@export var shape_seed := 1
