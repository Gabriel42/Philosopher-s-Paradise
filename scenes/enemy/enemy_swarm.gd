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
## Flying types ([member EnemySettings.flying]) instead fly forward on their
## own, swaying and bobbing in a rough spiral (see [method _step_flying]); for
## them [member positions] is the middle of the capsule, not the feet.
## Lives under the [EndlessLevel]: positions are in the level's shifted space.

## Sent when the runner starts touching an enemy. [param total]: touches so far.
signal runner_touched(total: int)

## Floats per enemy in the MultiMesh buffer (a 3×4 transform).
const _STRIDE := 12
## Cell offsets (x, z pairs) looked at besides an enemy's own cell when
## listing close pairs: half of the 8 neighbours, so each pair comes up once.
const _HALF_NEIGHBOURS: Array[int] = [1, 0, -1, 1, 0, 1, 1, 1]

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
## Flyers: X of the line each one sways around.
var lanes := PackedFloat32Array()
## Flyers: seconds since each one appeared (drives its waves).
var fly_times := PackedFloat32Array()
## Flyers: side-to-side and up-and-down waves per second of each one.
var sway_frequencies := PackedFloat32Array()
var bob_frequencies := PackedFloat32Array()
## Flyers: where in each wave each one starts (radians).
var sway_phases := PackedFloat32Array()
var bob_phases := PackedFloat32Array()
## How many times the runner touched an enemy.
var touches := 0

var _rng := RandomNumberGenerator.new()
var _multimesh := MultiMesh.new()
var _buffer := PackedFloat32Array()
var _last_runner_pos := Vector3.ZERO
var _has_last_runner_pos := false
# Spacing grid and close pairs (see _keep_apart), kept to avoid allocating.
var _cell_start := PackedInt32Array()
var _cell_cursor := PackedInt32Array()
var _cell_of := PackedInt32Array()
var _cell_items := PackedInt32Array()
var _pairs := PackedInt32Array()


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
	if s.flying:
		_step_flying(delta, runner_pos)
		return
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
		positions[i] = p
	_keep_apart(half)
	for i in positions.size():
		var p := positions[i]
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


## Flyers: each one moves forward (-Z) at [member EnemySettings.fly_speed]
## and sits on its waves: sideways [code]lane + sway_width * sin(2π f t + φ)[/code],
## height [code]ground + fly_height + bob_height * sin(2π f' t + φ')[/code],
## with its own two frequencies, so the path loops without repeating. The
## capsule points along where it moves (forward, tilting with the waves).
## [param runner_pos] is only used for touches and for sending flyers ahead.
func _step_flying(delta: float, runner_pos: Vector3) -> void:
	var s := settings
	var origin := level.origin
	var terrain := level.terrain
	var low := Vector3.INF
	var high := -Vector3.INF
	for i in positions.size():
		var old := positions[i]
		var t := fly_times[i] + delta
		fly_times[i] = t
		var p := _fly_point(i, old.z - s.fly_speed * delta, t, terrain, origin)
		positions[i] = p
		var dir := p - old
		_check_fly_touch(i, p, dir, runner_pos)
		var ahead := runner_pos.z - p.z
		if ahead < -s.recycle_distance or ahead > s.fly_ahead_limit:
			_spawn(i, runner_pos, 0.0)
			p = positions[i]
			dir = Vector3.FORWARD
		if dir.length_squared() < 0.000001:
			dir = Vector3.FORWARD
		# The capsule's long axis is its Y: turn Y onto the direction.
		var basis := Basis(Quaternion(Vector3.UP, dir.normalized()))
		var b := i * _STRIDE
		_buffer[b] = basis.x.x
		_buffer[b + 1] = basis.y.x
		_buffer[b + 2] = basis.z.x
		_buffer[b + 3] = p.x
		_buffer[b + 4] = basis.x.y
		_buffer[b + 5] = basis.y.y
		_buffer[b + 6] = basis.z.y
		_buffer[b + 7] = p.y
		_buffer[b + 8] = basis.x.z
		_buffer[b + 9] = basis.y.z
		_buffer[b + 10] = basis.z.z
		_buffer[b + 11] = p.z
		low = low.min(p)
		high = high.max(p)
	if positions.is_empty():
		return
	_multimesh.buffer = _buffer
	var grow := Vector3.ONE * s.height
	_multimesh.custom_aabb = AABB(low - grow, high - low + grow * 2.0)


## Middle of flyer [param i] at [param z] (level space), [param t] seconds
## into its flight.
func _fly_point(i: int, z: float, t: float, terrain: TerrainHeight,
		origin: Vector3) -> Vector3:
	var s := settings
	var x := lanes[i] + s.sway_width * sin(TAU * sway_frequencies[i] * t + sway_phases[i])
	var ground := terrain.height_at(x + origin.x, z + origin.z) - origin.y
	var y := ground + s.fly_height \
			+ s.bob_height * sin(TAU * bob_frequencies[i] * t + bob_phases[i])
	return Vector3(x, y, z)


## Touch check for a flyer lying along [param dir] with its middle at
## [param p]: three points along its axis (ends and middle), each a ball of
## [member EnemySettings.radius], against the runner's upright capsule.
func _check_fly_touch(i: int, p: Vector3, dir: Vector3, runner_pos: Vector3) -> void:
	var s := settings
	var axis := dir.normalized() if dir.length_squared() > 0.000001 else Vector3.FORWARD
	var half_axis := axis * maxf(s.height * 0.5 - s.radius, 0.0)
	var reach := s.radius + s.runner_radius
	var bottom := runner_pos.y + s.runner_radius
	var top := runner_pos.y + maxf(s.runner_height - s.runner_radius, s.runner_radius)
	var overlap := false
	for k in 3:
		var c := p + half_axis * float(k - 1)
		var closest := Vector3(runner_pos.x, clampf(c.y, bottom, top), runner_pos.z)
		if c.distance_squared_to(closest) < reach * reach:
			overlap = true
			break
	if overlap and touching[i] == 0:
		touches += 1
		runner_touched.emit(touches)
	touching[i] = 1 if overlap else 0


## Pushes apart (sideways, on X and Z) any two enemies whose
## [member EnemySettings.spacing_radius] circles overlap, each by half the
## overlap, so they can overlap a little but never sit inside each other.
## Cheap: once per frame, enemies are sorted into a grid of cells one spacing
## wide (packed arrays, cells hashed into a table) and each one only looks in
## its own and the 8 neighbouring cells to list the pairs that are close; the
## [member EnemySettings.spacing_passes] passes then only go over those pairs.
func _keep_apart(half: float) -> void:
	var r := settings.spacing_radius
	var n := positions.size()
	if r <= 0.0 or n < 2:
		return
	var min_dist := r * 2.0
	var inv := 1.0 / min_dist
	var table := 64
	while table < n * 2:
		table *= 2
	var mask := table - 1
	# Counting sort of the enemies by cell: enemies of cell h are
	# _cell_items[_cell_start[h] .. _cell_start[h + 1]].
	_cell_start.resize(table + 1)
	_cell_start.fill(0)
	_cell_of.resize(n)
	_cell_items.resize(n)
	for i in n:
		var p := positions[i]
		var h := _cell_hash(floori(p.x * inv), floori(p.z * inv), mask)
		_cell_of[i] = h
		_cell_start[h + 1] += 1
	for h in table:
		_cell_start[h + 1] += _cell_start[h]
	_cell_cursor = _cell_start.duplicate()
	for i in n:
		var h := _cell_of[i]
		_cell_items[_cell_cursor[h]] = i
		_cell_cursor[h] += 1
	# Pairs close enough to matter this frame.
	var near := min_dist * 1.25
	var near_sq := near * near
	_pairs.clear()
	for i in n:
		var p := positions[i]
		var cx := floori(p.x * inv)
		var cz := floori(p.z * inv)
		# Own cell (pairs once: j > i), then half the neighbours (the other
		# half finds this pair from the other side).
		for c in 5:
			var h := _cell_of[i]
			if c > 0:
				h = _cell_hash(cx + _HALF_NEIGHBOURS[c * 2 - 2],
						cz + _HALF_NEIGHBOURS[c * 2 - 1], mask)
				if h == _cell_of[i]:
					continue  # hashed to its own slot: already looked there
			for k in range(_cell_start[h], _cell_start[h + 1]):
				var j := _cell_items[k]
				if c == 0 and j <= i:
					continue
				var q := positions[j]
				var ax := q.x - p.x
				var az := q.z - p.z
				if ax * ax + az * az < near_sq:
					_pairs.append(i)
					_pairs.append(j)
	if _pairs.is_empty():
		return
	for pass_index in maxi(settings.spacing_passes, 1):
		for k in range(0, _pairs.size(), 2):
			var i := _pairs[k]
			var j := _pairs[k + 1]
			var p := positions[i]
			var q := positions[j]
			var apart := Vector2(q.x - p.x, q.z - p.z)
			var dist := apart.length()
			if dist >= min_dist:
				continue
			# Same spot: split them along X (deterministic).
			var dir := apart / dist if dist > 0.0001 else Vector2.RIGHT
			var push := dir * (min_dist - dist) * 0.5
			p.x = clampf(p.x - push.x, -half, half)
			p.z -= push.y
			q.x = clampf(q.x + push.x, -half, half)
			q.z += push.y
			positions[i] = p
			positions[j] = q


## Slot of grid cell ([param cx], [param cz]) in a table of [param mask] + 1.
static func _cell_hash(cx: int, cz: int, mask: int) -> int:
	return ((cx * 73856093) ^ (cz * 19349663)) & mask


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
	if s.flying:
		_spawn_flyer(i, runner_pos, half)
		return
	var p := Vector3(_rng.randf_range(-half, half), 0.0, 0.0)
	p.z = runner_pos.z - s.spawn_distance - _rng.randf_range(0.0, s.spawn_spread)
	var origin := level.origin
	p.y = level.terrain.height_at(p.x + origin.x, p.z + origin.z) - origin.y
	positions[i] = p
	closings[i] = (runner_pos.z - p.z) / maxf(s.meet_time, 0.01)
	speeds[i] = runner_forward - closings[i]
	side_speeds[i] = 0.0
	touching[i] = 0


## Puts flyer [param i] ahead of the runner with its own waves; its line
## keeps the whole sway inside the strip ([param half]: half the usable width).
func _spawn_flyer(i: int, runner_pos: Vector3, half: float) -> void:
	var s := settings
	var lane_half := maxf(half - s.sway_width, 0.0)
	lanes[i] = _rng.randf_range(-lane_half, lane_half)
	sway_frequencies[i] = _rng.randf_range(s.sway_frequency_min, s.sway_frequency_max)
	bob_frequencies[i] = _rng.randf_range(s.bob_frequency_min, s.bob_frequency_max)
	sway_phases[i] = _rng.randf_range(0.0, TAU)
	bob_phases[i] = _rng.randf_range(0.0, TAU)
	fly_times[i] = 0.0
	var z := runner_pos.z - s.spawn_distance - _rng.randf_range(0.0, s.spawn_spread)
	positions[i] = _fly_point(i, z, 0.0, level.terrain, level.origin)
	speeds[i] = s.fly_speed
	closings[i] = 0.0
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
	lanes.resize(count)
	fly_times.resize(count)
	sway_frequencies.resize(count)
	bob_frequencies.resize(count)
	sway_phases.resize(count)
	bob_phases.resize(count)
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
