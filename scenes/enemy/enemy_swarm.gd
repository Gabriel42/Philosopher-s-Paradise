class_name EnemySwarm
extends Node3D
## All the enemies of the level, kept cheap so there can be many at once:
## no node or physics body per enemy, only arrays of numbers, one
## [MultiMeshInstance3D] that draws every capsule in one go, and a fixed pool
## (an enemy left behind is sent ahead again, nothing is created or freed
## during a run).
## Enemies appear ahead of the runner and run downhill (-Z) a fixed amount
## slower than it (their closing speed, set at spawn so they reach it
## [member EnemySettings.meet_time] seconds later), and move sideways toward
## where the runner will be when they meet. They follow the ground with
## [method TerrainHeight.height_at] (no collisions: they pass through rocks).
## Lives under the [EndlessLevel]: positions are in the level's shifted space.

## Sent when the runner starts touching an enemy. [param total]: touches so far.
signal runner_touched(total: int)

## Floats per enemy in the MultiMesh buffer (a 3×4 transform).
const _STRIDE := 12

@export var settings: EnemySettings
## The level (terrain height, width, origin shifts). Defaults to the parent.
@export var level: EndlessLevel
## What the enemies go after (a [Runner]; any Node3D works).
@export var runner: Node3D

## Feet of each enemy, in the level's space.
var positions := PackedVector3Array()
## Speed down the strip (m/s) of each enemy.
var speeds := PackedFloat32Array()
## How much slower than the runner (m/s down the strip) each enemy runs.
var closings := PackedFloat32Array()
## Sideways speed (m/s along X) of each enemy.
var side_speeds := PackedFloat32Array()
## 1 while an enemy touches the runner (a touch counts once).
var touching := PackedByteArray()
## How many times the runner touched an enemy.
var touches := 0

var _rng := RandomNumberGenerator.new()
var _multimesh := MultiMesh.new()
var _buffer := PackedFloat32Array()
var _last_runner_pos := Vector3.ZERO
var _has_last_runner_pos := false


func _ready() -> void:
	if settings == null:
		settings = EnemySettings.new()
	if level == null:
		level = get_parent() as EndlessLevel
	_rng.seed = settings.spawn_seed
	var material := StandardMaterial3D.new()
	material.albedo_color = settings.color
	var mesh := CapsuleMesh.new()
	mesh.radius = settings.radius
	mesh.height = settings.height
	mesh.radial_segments = 12
	mesh.rings = 4
	mesh.material = material
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.mesh = mesh
	var view := MultiMeshInstance3D.new()
	view.name = "View"
	view.multimesh = _multimesh
	add_child(view)
	if level != null:
		level.origin_shifted.connect(_on_origin_shifted)


func _physics_process(delta: float) -> void:
	if runner == null or level == null or level.terrain == null:
		return
	var pos := runner.global_position
	var vel := Vector3.ZERO
	if runner is CharacterBody3D:
		vel = (runner as CharacterBody3D).velocity
	elif _has_last_runner_pos:
		vel = (pos - _last_runner_pos) / delta
	_last_runner_pos = pos
	_has_last_runner_pos = true
	step(delta, pos, vel)


## Moves every enemy by [param delta] seconds toward a runner at
## [param runner_pos] (feet, level space) going at [param runner_vel], checks
## touches, sends back the ones left behind, and updates the drawing.
func step(delta: float, runner_pos: Vector3, runner_vel: Vector3) -> void:
	var s := settings
	_fit_count(runner_pos, runner_vel)
	var runner_forward := maxf(-runner_vel.z, 0.0)
	var half := level.settings.width * 0.5 - s.edge_margin
	var origin := level.origin
	var terrain := level.terrain
	var low := Vector3.INF
	var high := -Vector3.INF
	for i in positions.size():
		var p := positions[i]
		var target := runner_forward - closings[i]
		var speed := move_toward(speeds[i], target, s.acceleration * delta)
		speeds[i] = speed
		p.z -= speed * delta
		# Where will the runner be (sideways) when it reaches this enemy?
		var gap := runner_pos.z - p.z
		var closing := runner_forward - speed
		var t := s.max_predict_time
		if closing > 0.1:
			t = clampf(gap / closing, 0.0, t)
		var aim := clampf(runner_pos.x + runner_vel.x * t, -half, half)
		var want := clampf((aim - p.x) * 3.0, -s.side_speed, s.side_speed)
		var side := move_toward(side_speeds[i], want, s.side_acceleration * delta)
		side_speeds[i] = side
		p.x = clampf(p.x + side * delta, -half, half)
		p.y = terrain.height_at(p.x + origin.x, p.z + origin.z) - origin.y
		positions[i] = p
		_check_touch(i, p, runner_pos)
		if p.z > runner_pos.z + s.recycle_distance:
			_spawn(i, runner_pos, runner_forward)
		var b := i * _STRIDE
		p = positions[i]
		_buffer[b + 3] = p.x
		_buffer[b + 7] = p.y + s.height * 0.5
		_buffer[b + 11] = p.z
		low = low.min(p)
		high = high.max(p)
	if positions.is_empty():
		return
	_multimesh.buffer = _buffer
	var grow := Vector3(s.radius, s.height, s.radius)
	_multimesh.custom_aabb = AABB(low - grow, high - low + grow * 2.0)


func _check_touch(i: int, p: Vector3, runner_pos: Vector3) -> void:
	var s := settings
	var apart := Vector2(p.x - runner_pos.x, p.z - runner_pos.z).length()
	var overlap := apart < s.radius + s.runner_radius \
			and p.y < runner_pos.y + s.runner_height \
			and p.y + s.height > runner_pos.y
	if overlap and touching[i] == 0:
		touches += 1
		runner_touched.emit(touches)
	touching[i] = 1 if overlap else 0


## Puts enemy [param i] ahead of the runner (going [param runner_forward] m/s
## down the strip), with the closing speed that reaches it
## [member EnemySettings.meet_time] seconds later.
func _spawn(i: int, runner_pos: Vector3, runner_forward: float) -> void:
	var s := settings
	var half := level.settings.width * 0.5 - s.edge_margin
	var p := Vector3(_rng.randf_range(-half, half), 0.0, 0.0)
	p.z = runner_pos.z - s.spawn_distance - _rng.randf_range(0.0, s.spawn_spread)
	var origin := level.origin
	p.y = level.terrain.height_at(p.x + origin.x, p.z + origin.z) - origin.y
	positions[i] = p
	closings[i] = (runner_pos.z - p.z) / maxf(s.meet_time, 0.01)
	speeds[i] = runner_forward - closings[i]
	side_speeds[i] = 0.0
	touching[i] = 0


## Grows or shrinks the pool to [member EnemySettings.count] (also when it is
## changed while playing).
func _fit_count(runner_pos: Vector3, runner_vel: Vector3) -> void:
	var count := maxi(settings.count, 0)
	var old := positions.size()
	if count == old:
		return
	positions.resize(count)
	speeds.resize(count)
	closings.resize(count)
	side_speeds.resize(count)
	touching.resize(count)
	var runner_forward := maxf(-runner_vel.z, 0.0)
	for i in range(old, count):
		_spawn(i, runner_pos, runner_forward)
	_buffer.resize(count * _STRIDE)
	for i in count:
		var b := i * _STRIDE
		for k in [0, 1, 2, 4, 5, 6, 8, 9, 10]:
			_buffer[b + k] = 0.0
		_buffer[b] = 1.0
		_buffer[b + 5] = 1.0
		_buffer[b + 10] = 1.0
	_multimesh.instance_count = count


func _on_origin_shifted(delta: Vector3) -> void:
	for i in positions.size():
		positions[i] -= delta
	_last_runner_pos -= delta
