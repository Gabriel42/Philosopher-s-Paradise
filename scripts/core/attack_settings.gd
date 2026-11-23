class_name AttackSettings
extends Resource
## Every number of one runner attack (e.g. resources/attacks/spark_bolt.tres).
## Attacks fire on their own and aim at the closest enemies; each attack uses
## only some of these numbers (its script's doc says which). Distances in m,
## times in s, speeds in m/s (shots move relative to the runner, so they keep
## up however fast it goes).

## Name shown on screen and in the debug panel.
@export var display_name := "Attack"
## Health taken from an enemy per hit (enemies have [member EnemySettings.health]).
## For attacks that hurt over time (Vortex): per second.
@export var damage := 1.0
## Seconds between two shots. Orbit Stones: before a stone hits the same enemy again.
@export var cooldown := 1.0
## Only enemies this close (from the runner's chest) are aimed at.
@export var reach := 30.0
## Enemies more than this far behind the runner (down the strip) are not
## aimed at: they are already passed. Very large = aim at the closest anywhere.
@export var ignore_behind := 2.0
## How many shots / chain jumps / stones / targets at once.
@export_range(1, 50) var count := 1
## Speed of the shots (m/s, relative to the runner). Orbit Stones: turns per second.
@export var speed := 40.0
## Radius of a shot, or half the width of a beam or chain.
@export var size := 0.25
## Radius of a blast, a ring, a well or an orbit; for Arc Chain how far a jump reaches.
@export var area := 0.0
## How long a shot flies / a well lasts / a falling rock takes to land.
@export var duration := 1.0
## Extra enemies a shot goes through before it is used up.
@export_range(0, 100) var pierce := 0
## Full angle of a fan of shots (degrees).
@export_range(0.0, 180.0) var spread := 0.0
## How fast homing shots turn toward their target (radians per second; 0 = straight).
@export var turn_rate := 0.0
## How hard a well pulls enemies to its middle (share of the gap per second).
@export var pull := 0.0
@export var color := Color(1.0, 0.85, 0.3)
