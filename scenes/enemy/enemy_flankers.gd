class_name EnemyFlankers
extends EnemySwarm
## Enemies that run beside the runner and shoot at it (enemy2). Same cheap
## pool, spacing, ground following and drawing as [EnemySwarm]; only the way
## they move changes, plus shots.
## Each enemy has a spot beside the runner: even ones on the left, odd ones on
## the right, [member FlankerSettings.side_distance] out, in rows
## [member FlankerSettings.row_spacing] apart along the run. They appear
## ahead, drop back to their spot, then hold it by matching the runner's
## speed (with a top acceleration, so a sudden boost leaves them behind for a
## moment). Once at its spot, each one fires every
## [member FlankerSettings.shot_interval] seconds at where the runner will be.
## Shots are a fixed pool drawn by a second MultiMesh; a hit is a distance
## check against the runner (no physics). Shots do nothing yet but count.
## Needs [FlankerSettings] as [member EnemySwarm.settings].

## Sent when an enemy fires. [param total]: shots fired so far.
signal shot_fired(total: int)
## Sent when a shot hits the runner. [param total]: hits so far.
signal runner_shot(total: int)

## Seconds until each enemy's next shot (counts down only at its spot).
var shot_timers := PackedFloat32Array()
## Position (level space) of each shot of the pool.
var shot_positions := PackedVector3Array()
## Velocity (m/s) of each shot.
var shot_velocities := PackedVector3Array()
## Seconds left for each shot; 0 or less = not flying.
var shot_lives := PackedFloat32Array()
## Shots fired so far.
var shots_fired := 0
## Shots that hit the runner so far.
var shots_hit := 0

var _shot_multimesh := MultiMesh.new()
var _shot_buffer := PackedFloat32Array()
var _next_shot := 0


func _ready() -> void:
	if not settings is FlankerSettings:
		if settings != null:
			push_error("EnemyFlankers needs FlankerSettings, got %s" % settings)
		settings = FlankerSettings.new()
	super._ready()
	var f := _flank()
	var material := StandardMaterial3D.new()
	material.albedo_color = f.shot_color
	material.emission_enabled = true
	material.emission = f.shot_color
	material.emission_energy_multiplier = 2.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := SphereMesh.new()
	mesh.radius = f.shot_radius
	mesh.height = f.shot_radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = material
	_shot_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_shot_multimesh.mesh = mesh
	var view := MultiMeshInstance3D.new()
	view.name = "Shots"
	view.multimesh = _shot_multimesh
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)


## Where enemy [param i] wants to be (level space: x = X, y = Z) beside a
## runner at [param runner_pos]; [param half] is how far from the middle of
## the strip it may go. A spot past the edge moves to the other side,
## further out (so it doesn't sit on that side's enemy).
func spot_of(i: int, runner_pos: Vector3, half: float) -> Vector2:
	var f := _flank()
	var rows := ceili(positions.size() / 2.0)
	var row := floori(i / 2.0)
	var side := -1.0 if i % 2 == 0 else 1.0
	var z := runner_pos.z + (row - (rows - 1) * 0.5) * f.row_spacing
	var x := runner_pos.x + side * f.side_distance
	if absf(x) > half:
		x = runner_pos.x - side * f.side_distance * 1.5
	return Vector2(clampf(x, -half, half), z)


## Speed (m/s, signed) to close a gap of [param gap] m: [member
## FlankerSettings.steer_gain] × gap, but never faster than what can still
## stop on the spot braking at half of [param accel].
func _closing_speed(gap: float, accel: float) -> float:
	var g := absf(gap)
	return signf(gap) * minf(_flank().steer_gain * g, sqrt(accel * g))


func _steer(i: int, delta: float, runner_pos: Vector3, runner_vel: Vector3,
		half: float) -> void:
	var f := _flank()
	var spot := spot_of(i, runner_pos, half)
	var p := positions[i]
	# Gaps are measured from where it ends this frame if it keeps its speed
	# (the runner has already moved), else it trails by one frame of travel.
	# Along the run (speeds are down the strip, -Z): behind its spot = +.
	var behind := p.z - speeds[i] * delta - spot.y
	var extra := clampf(_closing_speed(behind, f.acceleration),
			-f.approach_speed, f.catch_up_speed)
	var speed := move_toward(speeds[i], -runner_vel.z + extra, f.acceleration * delta)
	speeds[i] = speed
	p.z -= speed * delta
	# Sideways, relative to the runner's own sideways speed.
	var side_gap := spot.x - (p.x + side_speeds[i] * delta)
	var want := runner_vel.x + clampf(_closing_speed(side_gap, f.side_acceleration),
			-f.flank_side_speed, f.flank_side_speed)
	var side := move_toward(side_speeds[i], want, f.side_acceleration * delta)
	side_speeds[i] = side
	p.x = clampf(p.x + side * delta, -half, half)
	positions[i] = p


## Appears ahead like enemy1, but already on its own side of the strip.
func _spawn(i: int, runner_pos: Vector3, runner_forward: float) -> void:
	super._spawn(i, runner_pos, runner_forward)
	var f := _flank()
	var half := level.settings.width * 0.5 - f.edge_margin
	var p := positions[i]
	p.x = clampf(spot_of(i, runner_pos, half).x + _rng.randf_range(-3.0, 3.0), -half, half)
	var origin := level.origin
	p.y = level.terrain.height_at(p.x + origin.x, p.z + origin.z) - origin.y
	positions[i] = p
	shot_timers[i] = _rng.randf_range(0.0, f.shot_interval)


func _resize(count: int) -> void:
	shot_timers.resize(count)
	if count == 0:  # turned off (or count 0): no shots left flying either
		shot_lives.fill(0.0)
		_draw_shots()


## True when enemy [param i] is at its spot beside the runner.
func is_in_place(i: int, runner_pos: Vector3) -> bool:
	var half := level.settings.width * 0.5 - settings.edge_margin
	var spot := spot_of(i, runner_pos, half)
	var p := positions[i]
	return Vector2(p.x - spot.x, p.z - spot.y).length() <= _flank().in_place_distance


func _after_step(delta: float, runner_pos: Vector3, runner_vel: Vector3) -> void:
	var f := _flank()
	_fit_shots()
	_move_shots(delta, runner_pos, runner_vel)
	for i in positions.size():
		if not is_in_place(i, runner_pos):
			continue
		shot_timers[i] -= delta
		if shot_timers[i] <= 0.0:
			shot_timers[i] += f.shot_interval
			_fire(i, runner_pos, runner_vel)
	_draw_shots()


## Velocity for a shot leaving [param from] (on a shooter moving at
## [param shooter_vel]) at [param speed] m/s relative to the shooter, that
## meets a target now at [param to] moving at [param target_vel] in a
## straight line (shots have no gravity). If the target is too fast to be
## caught, aims straight at it.
static func aim_shot(from: Vector3, shooter_vel: Vector3, to: Vector3,
		target_vel: Vector3, speed: float) -> Vector3:
	var r := to - from
	var dist := r.length()
	if dist < 0.001 or speed <= 0.0:
		return shooter_vel
	var dir := r / dist
	# Seen from the target, the shot must fly straight at it: cancel the part
	# of the shooter's relative speed that would push it off that line.
	var u := shooter_vel - target_vel
	var cancel := -(u - dir * u.dot(dir)) / speed
	var along_sq := 1.0 - cancel.length_squared()
	var aim := dir
	if along_sq > 0.0:
		aim = cancel + dir * sqrt(along_sq)
	return shooter_vel + aim * speed


func _fire(i: int, runner_pos: Vector3, runner_vel: Vector3) -> void:
	var f := _flank()
	var from := positions[i] + Vector3.UP * f.muzzle_height
	var shooter_vel := Vector3(side_speeds[i], 0.0, -speeds[i])
	var to := runner_pos + Vector3.UP * f.aim_height
	var k := _next_shot
	_next_shot = (k + 1) % shot_lives.size()
	shot_positions[k] = from
	shot_velocities[k] = aim_shot(from, shooter_vel, to, runner_vel, f.shot_speed)
	shot_lives[k] = f.shot_life
	shots_fired += 1
	shot_fired.emit(shots_fired)


## Moves the flying shots, ends those that hit the ground or ran out of time,
## and counts those that hit the runner (checked along the whole move, seen
## from the runner, so a fast shot can't skip through it in one frame).
func _move_shots(delta: float, runner_pos: Vector3, runner_vel: Vector3) -> void:
	var f := _flank()
	var reach := f.runner_radius + f.shot_radius
	var origin := level.origin
	for k in shot_lives.size():
		if shot_lives[k] <= 0.0:
			continue
		var v := shot_velocities[k]
		var now := shot_positions[k] + v * delta
		shot_positions[k] = now
		shot_lives[k] -= delta
		var rel_now := now - runner_pos
		var rel_move := (v - runner_vel) * delta
		var rel_before := rel_now - rel_move
		# Closest point (on X/Z) of this move to the runner's axis.
		var flat := Vector2(rel_move.x, rel_move.z)
		var t := 0.0
		if flat.length_squared() > 0.000001:
			t = clampf(-Vector2(rel_before.x, rel_before.z).dot(flat)
					/ flat.length_squared(), 0.0, 1.0)
		var c := rel_before + rel_move * t
		if Vector2(c.x, c.z).length() < reach \
				and c.y > -f.shot_radius and c.y < f.runner_height + f.shot_radius:
			shot_lives[k] = 0.0
			shots_hit += 1
			runner_shot.emit(shots_hit)
		elif now.y < level.terrain.height_at(now.x + origin.x, now.z + origin.z) - origin.y:
			shot_lives[k] = 0.0


## Keeps the shot pool at [member FlankerSettings.max_shots].
func _fit_shots() -> void:
	var count := maxi(_flank().max_shots, 1)
	if shot_lives.size() == count:
		return
	shot_positions.resize(count)
	shot_velocities.resize(count)
	shot_lives.resize(count)
	_shot_buffer.resize(count * _STRIDE)
	_shot_buffer.fill(0.0)
	_next_shot = 0
	_shot_multimesh.instance_count = count


func _draw_shots() -> void:
	var low := Vector3.INF
	var high := -Vector3.INF
	for k in shot_lives.size():
		var b := k * _STRIDE
		var size := 0.0  # a shot not flying is drawn with no size
		if shot_lives[k] > 0.0:
			size = 1.0
			var p := shot_positions[k]
			_shot_buffer[b + 3] = p.x
			_shot_buffer[b + 7] = p.y
			_shot_buffer[b + 11] = p.z
			low = low.min(p)
			high = high.max(p)
		_shot_buffer[b] = size
		_shot_buffer[b + 5] = size
		_shot_buffer[b + 10] = size
	_shot_multimesh.buffer = _shot_buffer
	if low.x <= high.x:
		var grow := Vector3.ONE * _flank().shot_radius
		_shot_multimesh.custom_aabb = AABB(low - grow, high - low + grow * 2.0)


func _on_origin_shifted(delta: Vector3) -> void:
	super._on_origin_shifted(delta)
	for k in shot_positions.size():
		shot_positions[k] -= delta


func _flank() -> FlankerSettings:
	return settings as FlankerSettings
