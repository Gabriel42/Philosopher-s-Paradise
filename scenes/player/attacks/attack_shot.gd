class_name AttackShot
extends RefCounted
## One flying shot of an [Attack] (bolts, shards, seekers). Moved by
## [method Attack.move_shots]: it rides along with the runner and adds its own
## velocity, can home in on a target, and hits the first enemy it touches.

## Position (level space).
var position := Vector3.ZERO
## Own velocity (m/s), relative to the runner.
var velocity := Vector3.ZERO
## Seconds left before it vanishes.
var life := 1.0
## Radius used to hit and draw it.
var radius := 0.25
## Homing target (null = flies straight).
var target: AttackTarget
## Radians per second it turns toward [member target].
var turn_rate := 0.0
## When its target dies, picks the closest enemy instead.
var retarget := false
## Enemies it can still go through after the next hit (below 0 = used up).
var pierce := 0
## > 0: it explodes on its first hit, hurting everything this close.
var blast := 0.0
## Keys of the enemies it already hit (so a piercing shot hits each once).
var hit := {}
