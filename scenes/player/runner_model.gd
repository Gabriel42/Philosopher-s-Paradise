class_name RunnerModel
extends Node3D
## How the runner looks: the Mannequiny model (GDQuest, CC-BY 4.0) and its
## animations. [Runner] calls [method animate] every physics frame; this only
## shows the state, it never changes movement.
## In the air (after [member skydive_delay]) the body tips forward into a
## flying pose (arms swept back), its head pointing where it goes (up or
## down, [method fly]) and banking with the sideways slide. Fast fall (the parent [Runner]'s
## [signal Runner.fast_fall_changed]) starts a tucked forward roll that opens
## back into the skydive. The poses are made in code by [RunnerPose].
## Landing goes straight back into the run: the body snaps upright and the
## run animation starts at once (no landing animation, no squash). Landing
## past head-first in the roll finishes the flip forward, tucked.
## On the ground the body leans into the slope (forward going up, a little
## back going down) and the stride quickens on a climb.

## Ground speed (m/s) at which the run animation plays at its own pace.
@export var run_pace_speed := 7.0
## The run animation never plays slower or faster than this many times its pace.
@export var min_run_scale := 0.6
@export var max_run_scale := 2.5
## Below this ground speed (m/s) the runner stands idle.
@export var idle_below := 0.5
## Cross-fade time between animations (s).
@export var blend_time := 0.15
## Time in the air before the jump animation starts (s): shorter hops (a frame
## off the ground going uphill) keep the run going, so it doesn't stutter.
@export var air_grace := 0.1

@export_group("Landing")
## Cross-fade into the run when landing (s): short, so the runner just keeps
## running.
@export var land_blend := 0.05
## How fast the body rights itself out of the skydive on the ground (degrees/s).
@export var land_tip_speed := 1500.0
## Time to leave the skydive pose on the ground (s).
@export var land_pose_blend := 0.05

@export_group("Slopes")
## Lean forward per degree of rising slope (and back per degree going down).
@export var lean_per_degree := 0.5
## Most the body leans forward going up / back going down (degrees).
@export var max_lean_up := 15.0
@export var max_lean_down := 6.0
## How fast the lean follows the slope (degrees/s).
@export var lean_speed := 60.0
## Extra stride pace on a climb of 20° or more (0.3 = 30% quicker).
@export var climb_pace := 0.3

@export_group("Skydive")
## Time in the air before the flying pose starts (s), so small hops stay hops.
@export var skydive_delay := 0.15
## How far the body tips forward when flying level (degrees; 90 = belly flat,
## head forward). The climb angle is added on top, see [member pitch_follow].
@export var skydive_angle := 90.0
## Part of the climb angle (where the runner is going, up or down) the body
## follows: 1 = the head points exactly where it goes.
@export_range(0.0, 1.0) var pitch_follow := 0.7
## Most the body points its head up / down from level (degrees).
@export var max_pitch_up := 45.0
@export var max_pitch_down := 50.0
## Roll to the side at full sideways slide (degrees; right side down going right).
@export var max_bank := 30.0
## How fast the bank follows the slide (degrees/s).
@export var bank_speed := 150.0
## Time to blend into or out of a pose (s).
@export var pose_blend := 0.15
## How fast the body tips into the skydive or back upright (degrees/s).
@export var tip_speed := 600.0
## Height of the point the body turns around (m above the feet).
@export var turn_height := 0.95
## Bone turns of the skydive (degrees around the model's axes: x to its left,
## y up, z forward), see [RunnerPose].
## The flying pose: arms swept back along the body, legs together.
@export var skydive_pose: Dictionary[String, Vector3] = {
	"spine_02": Vector3(-10, 0, 0),
	"neck_01": Vector3(-55, 0, 0),
	"upperarm.l": Vector3(15, 0, -17),
	"upperarm.r": Vector3(15, 0, 17),
	"lowerarm.l": Vector3(15, 0, 20),
	"lowerarm.r": Vector3(15, 0, -20),
	"thigh.l": Vector3(0, 0, -3),
	"thigh.r": Vector3(0, 0, 3),
	"calf.l": Vector3(15, 0, 0),
	"calf.r": Vector3(15, 0, 0),
}

@export_group("Roll")
## Time of the forward roll (s).
@export var roll_time := 0.3
## Bone turns of the tuck held during the roll (same as [member skydive_pose]).
@export var tuck_pose: Dictionary[String, Vector3] = {
	"spine_01": Vector3(25, 0, 0),
	"spine_02": Vector3(25, 0, 0),
	"neck_01": Vector3(25, 0, 0),
	"thigh.l": Vector3(-120, 0, 0),
	"thigh.r": Vector3(-120, 0, 0),
	"calf.l": Vector3(140, 0, 0),
	"calf.r": Vector3(140, 0, 0),
	"upperarm.l": Vector3(-50, 0, 0),
	"upperarm.r": Vector3(-50, 0, 0),
	"lowerarm.l": Vector3(-70, 0, 0),
	"lowerarm.r": Vector3(-70, 0, 0),
}

var _on_floor := true
var _air_time := 0.0
var _rolling := false
## Landed mid-roll: finishing the flip forward on the ground.
var _finishing := false
## Time since the roll started (s).
var _roll_t := 0.0
## Tip when the roll started (degrees).
var _roll_from := 0.0
## Forward tip of the body now (degrees; negative = head forward).
var _tip := 0.0
## Slope under the runner (degrees, positive = rising ahead).
var _slope := 0.0
## Lean into the slope now (degrees, positive = forward), around the feet.
var _lean := 0.0
## Climb angle of the runner's motion (degrees, positive going up), from [method fly].
var _climb := 0.0
## Sideways slide, -1 (left) .. 1 (right), from [method fly].
var _side := 0.0
## Roll to the side now (degrees, positive = right side down).
var _bank := 0.0
## Bends the bones into the skydive and the tuck (made in [method _ready]).
var _pose: RunnerPose

@onready var _anim: AnimationPlayer = $Mannequiny/AnimationPlayer
@onready var _body: Node3D = $Mannequiny
@onready var _body_base: Transform3D = _body.transform
@onready var _skeleton: Skeleton3D = $Mannequiny/root/Skeleton3D


func _ready() -> void:
	for looping: String in ["idle", "run"]:
		_anim.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
	_pose = RunnerPose.new()
	_pose.name = "RunnerPose"
	_skeleton.add_child(_pose)
	# The poses are made on the standing pose: the first frame of idle.
	_anim.play("idle")
	_anim.seek(0.0, true)
	for b in _skeleton.get_bone_count():
		_pose.neutral.append(_skeleton.get_bone_pose_rotation(b))
	rebuild_poses()
	var runner := get_parent() as Runner
	if runner:
		runner.fast_fall_changed.connect(_on_fast_fall_changed)


## Works the poses out again (after changing [member skydive_pose] or
## [member tuck_pose] while the game runs).
func rebuild_poses() -> void:
	_pose.build(skydive_pose, tuck_pose)


func _process(delta: float) -> void:
	if _rolling and _on_floor:
		_rolling = false
		# Landed mid-roll: past head-first, the flip finishes forward;
		# before that the body just rights itself.
		_finishing = _tip < -90.0
	var airborne := not _on_floor and _air_time >= skydive_delay
	var fly_tip := flight_tip()
	var tuck := 0.0
	if _finishing:
		# Tucked, forward to the next upright (-360° is upright again).
		_tip = move_toward(_tip, -360.0, land_tip_speed * delta)
		tuck = 1.0
		if is_equal_approx(_tip, -360.0):
			_tip = 0.0
			_finishing = false
	elif _rolling:
		_roll_t += delta
		var t := clampf(_roll_t / roll_time, 0.0, 1.0)
		# One full turn forward, easing in and out, ending in the skydive.
		_tip = lerpf(_roll_from, -360.0 + fly_tip, ease(t, -1.6))
		# Tucks in fast, opens up near the end.
		tuck = minf(clampf(t / 0.15, 0.0, 1.0), clampf((1.0 - t) / 0.25, 0.0, 1.0))
		if t >= 1.0:
			_rolling = false
			_tip = fly_tip
	else:
		var target := fly_tip if airborne else 0.0
		# Back to -180..180 first, so a half-done roll doesn't unwind.
		var speed := land_tip_speed if _on_floor else tip_speed
		_tip = move_toward(wrapf(_tip, -180.0, 180.0), target, speed * delta)
	_pose.tuck = tuck
	var posed := 1.0 if airborne or _rolling or _finishing else 0.0
	var blend := land_pose_blend if _on_floor else pose_blend
	_pose.amount = move_toward(_pose.amount, posed, delta / blend)
	var lean_target := 0.0
	if not airborne and not _rolling and not _finishing:
		lean_target = clampf(_slope * lean_per_degree, -max_lean_down, max_lean_up)
	_lean = move_toward(_lean, lean_target, lean_speed * delta)
	var bank_target := clampf(_side, -1.0, 1.0) * max_bank if airborne or _rolling else 0.0
	var bank_rate := land_tip_speed if _on_floor else bank_speed
	_bank = move_toward(_bank, bank_target, bank_rate * delta)
	# Tip (air, roll) and bank (around the way it goes, outside the tip) turn
	# around the middle of the body; lean around the feet.
	var pivot := Vector3.UP * turn_height
	var turn := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(_tip)), Vector3.ZERO)
	var bank := Transform3D(Basis(Vector3.FORWARD, deg_to_rad(_bank)), Vector3.ZERO)
	var lean := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-_lean)), Vector3.ZERO)
	_body.transform = lean * Transform3D(Basis(), pivot) * bank * turn \
			* Transform3D(Basis(), -pivot) * _body_base


## Tells where the runner is going: [param climb] is the angle of its motion
## (degrees, positive going up), [param side] its sideways slide in the air
## (-1 left .. 1 right). The flying body points with the climb and banks with
## the slide.
func fly(climb: float, side: float) -> void:
	_climb = climb
	_side = side


## Tip of the flying body for the climb now (degrees, negative = head forward):
## [member skydive_angle] when level, head up going up, down going down.
func flight_tip() -> float:
	var pitch := clampf(_climb * pitch_follow, -max_pitch_down, max_pitch_up)
	return -skydive_angle + pitch


## Roll to the side (degrees, positive = right side down; for tests).
func bank() -> float:
	return _bank


func _on_fast_fall_changed(on: bool) -> void:
	if on:
		_rolling = true
		_finishing = false
		_roll_t = 0.0
		# From the tip now (the skydive: one turn from there).
		_roll_from = wrapf(_tip, -180.0, 180.0)
		_pose.amount = 1.0


## Forward tip of the body (degrees, negative = head forward; for tests).
func tip() -> float:
	return _tip


## How much the body is in its code pose: 0 animation, 1 pose (for tests).
func pose_amount() -> float:
	return _pose.amount


## How tucked the body is: 0 skydive, 1 tuck (for tests).
func tuck_amount() -> float:
	return _pose.tuck


## Lean into the slope (degrees, positive = forward; for tests).
func lean() -> float:
	return _lean


## Picks the animation for this frame: idle, run (faster with [param speed],
## and on a climb) or the jump in the air (mostly covered by the skydive
## pose); a hop shorter than [member air_grace] changes nothing.
## [param slope]: degrees of the ground along the run, positive rising.
func animate(speed: float, on_floor: bool, slope := 0.0) -> void:
	_on_floor = on_floor
	_air_time = 0.0 if on_floor else _air_time + get_physics_process_delta_time()
	if not on_floor:
		if _air_time >= air_grace:
			_play("air_jump")
			_anim.speed_scale = 1.0
		return
	_slope = slope
	# Just landed: straight into the run, no slow fade out of the jump.
	var blend := land_blend if _anim.assigned_animation == "air_jump" else blend_time
	if speed < idle_below:
		_play("idle", blend)
		_anim.speed_scale = 1.0
	else:
		_play("run", blend)
		var pace := clampf(speed / run_pace_speed, min_run_scale, max_run_scale)
		_anim.speed_scale = pace * (1.0 + climb_pace * clampf(slope / 20.0, 0.0, 1.0))


## The animation playing now (for tests).
func current_animation() -> String:
	return _anim.current_animation if _anim.is_playing() else _anim.assigned_animation


func _play(anim_name: String, blend := blend_time) -> void:
	if _anim.assigned_animation != anim_name:
		_anim.play(anim_name, blend)
