class_name RunnerPose
extends SkeletonModifier3D
## Poses the runner's body in code, on top of its animation (the model has no
## tuck or skydive animation). Each pose is a list of bone turns, made on the
## standing pose ([member neutral]): [code]bone name → Vector3[/code] of
## degrees around the model's axes (x: to its left, y: up, z: forward), each
## bone turning with its parent first. [RunnerModel] creates this under the
## skeleton and sets [member amount] (animation → pose) and [member tuck]
## (skydive → tuck).

## 0: the animation as it plays; 1: the pose.
var amount := 0.0
## 0: skydive; 1: tuck.
var tuck := 0.0
## Local rotation of each bone in the standing pose (filled by [RunnerModel]).
var neutral: Array[Quaternion] = []

var _skydive: Array[Quaternion] = []
var _tuck: Array[Quaternion] = []


## Works out both poses' bone rotations (call again after changing a pose).
func build(skydive: Dictionary, tuck_pose: Dictionary) -> void:
	_skydive = _pose(skydive)
	_tuck = _pose(tuck_pose)


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null or amount <= 0.0 or _skydive.size() != skeleton.get_bone_count():
		return
	for b in skeleton.get_bone_count():
		var target := _skydive[b].slerp(_tuck[b], tuck)
		var now := skeleton.get_bone_pose_rotation(b)
		skeleton.set_bone_pose_rotation(b, now.slerp(target, amount))


## Local bone rotations of a pose given as model-space turns per bone name.
func _pose(turns: Dictionary) -> Array[Quaternion]:
	var skeleton := get_skeleton()
	var local: Array[Quaternion] = []
	if skeleton == null or neutral.size() != skeleton.get_bone_count():
		return local
	var global: Array[Quaternion] = []
	for b in skeleton.get_bone_count():
		var parent := skeleton.get_bone_parent(b)
		var parent_global := global[parent] if parent >= 0 else Quaternion.IDENTITY
		var l := neutral[b]
		var turn: Vector3 = turns.get(skeleton.get_bone_name(b), Vector3.ZERO)
		if turn != Vector3.ZERO:
			var r := Quaternion.from_euler(turn * (PI / 180.0))
			l = parent_global.inverse() * r * parent_global * l
		local.append(l)
		global.append(parent_global * l)
	return local
