extends TestCase
## Enemies: closing speed (3 s to meet), interception, dodging, touches, recycling,
## origin shift, live count. Moves a pretend runner by hand and calls
## EnemySwarm.step() at 60 Hz (no physics, no Runner).

const DT := 1.0 / 60.0

var level: EndlessLevel
var swarm: EnemySwarm


func before_each() -> void:
	level = EndlessLevel.new()
	level.settings = TerrainSettings.new()
	swarm = EnemySwarm.new()
	swarm.settings = EnemySettings.new()
	swarm.settings.count = 1
	level.add_child(swarm)
	keep(level)
	level.set_physics_process(false)
	swarm.set_physics_process(false)


## Puts enemy 0 at [param x], [param distance] forward, running at [param speed],
## [param closing] m/s slower than the runner.
func _place(x: float, distance: float, speed: float, closing := 6.0) -> void:
	swarm.step(0.0, level.surface_point(0.0, 0.0), Vector3.ZERO)  # fills the pool
	swarm.positions[0] = level.surface_point(x, distance)
	swarm.speeds[0] = speed
	swarm.closings[0] = closing


## Runs a runner from ([param x], [param distance]) at [param vel] for
## [param seconds], on the ground. Returns its last position.
func _run(x: float, distance: float, vel: Vector3, seconds: float) -> Vector3:
	var pos := level.surface_point(x, distance)
	for frame in roundi(seconds / DT):
		pos = level.surface_point(pos.x + vel.x * DT, -(pos.z + vel.z * DT))
		swarm.step(DT, pos, vel)
	return pos


func test_runs_its_closing_speed_slower_than_the_runner() -> void:
	_place(30.0, 300.0, 0.0, 15.0)
	var pos := _run(-30.0, 0.0, Vector3(0, 0, -30), 3.0)
	assert_near(swarm.speeds[0], 30.0 - 15.0, 0.01)
	_run(pos.x, -pos.z, Vector3(0, 0, -50), 3.0)  # the runner speeds up
	assert_near(swarm.speeds[0], 50.0 - 15.0, 0.01)


## Sends enemy 0 ahead of a runner going straight at [param speed], then
## returns how many seconds it takes to reach the runner (down the strip).
func _time_to_meet(speed: float) -> float:
	var vel := Vector3(0, 0, -speed)
	_place(0.0, 0.0, 0.0)
	swarm.positions[0] = level.surface_point(0.0, -25.0)  # left behind...
	var pos := level.surface_point(0.0, 0.0)
	swarm.step(DT, pos, vel)  # ...so it is sent ahead
	var frames := 0
	while swarm.positions[0].z < pos.z and frames < 600:
		pos = level.surface_point(pos.x, -(pos.z + vel.z * DT))
		swarm.step(DT, pos, vel)
		frames += 1
	return frames * DT


func test_reaches_a_runner_at_run_speed_3_s_after_appearing() -> void:
	assert_near(_time_to_meet(22.0), 3.0, 0.1)


func test_reaches_a_fast_runner_3_s_after_appearing() -> void:
	assert_near(_time_to_meet(60.0), 3.0, 0.1)


func test_a_sudden_boost_leaves_it_behind() -> void:
	_place(30.0, 300.0, 24.0)
	var pos := _run(-30.0, 0.0, Vector3(0, 0, -60), 0.25)
	# 20 m/s² for 0.25 s: 24 -> 29, far from the 54 it wants.
	assert_near(swarm.speeds[0], 29.0, 0.1)
	assert_true(pos.z < 0.0)


func test_follows_the_ground() -> void:
	_place(10.0, 150.0, 20.0)
	_run(0.0, 0.0, Vector3(0, 0, -25), 1.0)
	var p := swarm.positions[0]
	assert_near(p.y, level.terrain.height_at(p.x, p.z), 0.001)


func test_cuts_off_a_runner_going_straight() -> void:
	_place(15.0, 100.0, 24.0)
	_run(0.0, 0.0, Vector3(0, 0, -30), 20.0)
	assert_eq(swarm.touches, 1, "the enemy 15 m to the side got in the way")


func test_aims_where_the_runner_will_be() -> void:
	_place(0.0, 150.0, 24.0)
	# Runner drifting right at 3 m/s: the enemy (6 m/s closing, 4 s look-ahead)
	# heads for 12 m right of the runner.
	var pos := _run(0.0, 0.0, Vector3(3, 0, -30), 3.0)
	assert_true(swarm.positions[0].x > pos.x + 5.0,
			"enemy leads the runner: %.1f vs %.1f" % [swarm.positions[0].x, pos.x])


func test_a_late_sidestep_dodges() -> void:
	_place(0.0, 60.0, 24.0)
	var pos := level.surface_point(0.0, 0.0)
	var vel := Vector3(0, 0, -30)
	while swarm.positions[0].z < pos.z + 5.0:  # until the enemy is behind
		if pos.z - swarm.positions[0].z < 5.0:
			vel.x = 15.0  # sidestep at the last moment
		pos = level.surface_point(pos.x + vel.x * DT, -(pos.z + vel.z * DT))
		swarm.step(DT, pos, vel)
	assert_eq(swarm.touches, 0)


func test_a_touch_counts_once() -> void:
	var sent: Array[int] = []
	swarm.runner_touched.connect(func(total: int) -> void: sent.append(total))
	_place(0.3, 0.0, 20.0, 0.0)
	var pos := _run(0.0, 0.0, Vector3(0, 0, -20), 0.5)  # running side by side
	assert_eq(swarm.touches, 1)
	swarm.positions[0].x += 5.0  # apart...
	pos = _run(pos.x, -pos.z, Vector3(0, 0, -20), 0.1)
	swarm.positions[0] = pos  # ...and touching again
	swarm.step(DT, pos, Vector3(0, 0, -20))
	assert_eq(swarm.touches, 2)
	assert_eq(sent, [1, 2] as Array[int])


## Fills the pool with [param count] enemies, all within a [param size] m
## square [param distance] ahead, running 24 m/s (6 slower than the runner).
func _crowd(count: int, distance: float, size: float) -> void:
	swarm.settings.count = count
	swarm.step(0.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in count:
		swarm.positions[i] = level.surface_point(rng.randf() * size,
				distance + rng.randf() * size)
		swarm.speeds[i] = 24.0
		swarm.closings[i] = 6.0


## Smallest sideways (X/Z) distance between two enemies.
func _closest_pair() -> float:
	var best := INF
	for i in swarm.positions.size():
		for j in range(i + 1, swarm.positions.size()):
			var a := swarm.positions[i]
			var b := swarm.positions[j]
			best = minf(best, Vector2(a.x - b.x, a.z - b.z).length())
	return best


func test_two_on_one_spot_are_pushed_apart() -> void:
	_crowd(2, 100.0, 0.0)
	_run(0.0, 0.0, Vector3(0, 0, -30), DT)
	assert_near(_closest_pair(), 0.4, 0.01)


func test_a_crowd_keeps_its_spacing() -> void:
	_crowd(40, 100.0, 1.0)  # 40 enemies in 1 m²: deep inside each other
	_run(0.0, 0.0, Vector3(0, 0, -30), 1.0)  # all cutting off the same runner
	assert_true(_closest_pair() > 0.36, "closest pair %.3f m" % _closest_pair())


func test_no_spacing_lets_them_overlap() -> void:
	swarm.settings.spacing_radius = 0.0
	_crowd(2, 100.0, 0.0)
	_run(0.0, 0.0, Vector3(0, 0, -30), DT)
	assert_true(_closest_pair() < 0.01)


func test_jumping_over_does_not_touch() -> void:
	_place(0.0, 0.0, 0.0)
	swarm.step(DT, swarm.positions[0] + Vector3.UP * 1.2, Vector3.ZERO)
	assert_eq(swarm.touches, 0)


func test_left_behind_goes_ahead_again() -> void:
	_place(0.0, 0.0, 24.0)
	swarm.positions[0] = level.surface_point(0.0, 100.0 - 25.0)
	swarm.step(DT, level.surface_point(0.0, 100.0), Vector3(0, 0, -30))
	var ahead := -swarm.positions[0].z - 100.0
	var s := swarm.settings
	assert_between(ahead, s.spawn_distance - 1.0, s.spawn_distance + s.spawn_spread + 1.0)
	assert_near(swarm.closings[0], ahead / s.meet_time, 0.01)
	assert_near(swarm.speeds[0], 30.0 - swarm.closings[0], 0.01)


func test_origin_shift_keeps_enemies_in_place() -> void:
	var mover := Node3D.new()
	level.add_child(mover)
	level.runner = mover
	mover.position = level.surface_point(0.0, 2500.0)
	_place(5.0, 2600.0, 20.0)
	var real := swarm.positions[0] + level.origin
	level.check_origin_shift()
	assert_true(level.origin.length() > 1000.0, "the world shifted")
	assert_near(swarm.positions[0] + level.origin, real, 0.01)


func test_count_can_change_while_playing() -> void:
	var pos := level.surface_point(0.0, 0.0)
	swarm.settings.count = 50
	swarm.step(DT, pos, Vector3.ZERO)
	assert_eq(swarm.positions.size(), 50)
	var view := swarm.get_node("View") as MultiMeshInstance3D
	assert_eq(view.multimesh.instance_count, 50)
	swarm.settings.count = 10
	swarm.step(DT, pos, Vector3.ZERO)
	assert_eq(swarm.positions.size(), 10)
	assert_eq(view.multimesh.instance_count, 10)


# --- Flyers (enemy3 style) ---

## Makes the swarm a flying type with [param count] flyers and fills the pool
## around a runner standing at the start.
func _fly(count := 1) -> void:
	swarm.settings.flying = true
	swarm.settings.count = count
	swarm.step(0.0, level.surface_point(0.0, 0.0), Vector3.ZERO)


## Height of flyer [param i] above the ground under it.
func _above_ground(i: int) -> float:
	var p := swarm.positions[i] + level.origin
	return p.y - level.terrain.height_at(p.x, p.z)


func test_a_flyer_moves_the_same_whatever_the_runner_does() -> void:
	_fly(5)
	var a: Array[PackedVector3Array] = []
	for frame in 180:  # runner standing still
		swarm.step(DT, level.surface_point(0.0, 0.0), Vector3.ZERO)
		a.append(swarm.positions.duplicate())
	# Same seed, a runner zig-zagging and jumping around instead.
	var other := EnemySwarm.new()
	other.settings = swarm.settings
	level.add_child(other)
	other.set_physics_process(false)
	other.step(0.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
	for frame in 180:
		var t := frame * DT
		var pos := level.surface_point(8.0 * sin(t * 3.0), 10.0 * t) + Vector3.UP * fmod(t, 1.0)
		other.step(DT, pos, Vector3(24.0 * cos(t * 3.0), 0.0, -10.0))
		for i in 5:
			if not a[frame][i].is_equal_approx(other.positions[i]):
				fail("flyer %d differs at frame %d" % [i, frame])
				return


func test_a_flyer_flies_forward_at_its_speed() -> void:
	_fly()
	var start := swarm.positions[0].z
	for frame in 120:
		swarm.step(DT, level.surface_point(0.0, 0.0), Vector3.ZERO)
	assert_near(start - swarm.positions[0].z, swarm.settings.fly_speed * 2.0, 0.01)


func test_a_flyer_stays_in_the_air_above_a_runner_s_head() -> void:
	_fly(20)
	var s := swarm.settings
	var low := INF
	var high := -INF
	for frame in 300:
		swarm.step(DT, level.surface_point(0.0, 0.0), Vector3.ZERO)
		for i in 20:
			low = minf(low, _above_ground(i))
			high = maxf(high, _above_ground(i))
	assert_between(low, s.fly_height - s.bob_height - 0.001, s.fly_height)
	assert_between(high, s.fly_height, s.fly_height + s.bob_height + 0.001)
	assert_true(low > s.runner_height + s.radius, "lowest %.2f m" % low)


func test_a_flyer_sways_and_bobs_at_two_frequencies() -> void:
	_fly(20)
	var s := swarm.settings
	for i in 20:
		assert_between(swarm.sway_frequencies[i], s.sway_frequency_min, s.sway_frequency_max)
		assert_between(swarm.bob_frequencies[i], s.bob_frequency_min, s.bob_frequency_max)
		assert_true(swarm.bob_frequencies[i] > swarm.sway_frequencies[i])
	assert_ne(swarm.sway_frequencies[0], swarm.sway_frequencies[1], "each has its own")
	# Over 10 s flyer 0 covers its whole sway, and its bob crosses the middle
	# about 2 × its frequency × 10 times (the ground moves under it: ±1).
	var lane := swarm.lanes[0]
	var left := INF
	var right := -INF
	var crossings := 0
	var was_above := _above_ground(0) > s.fly_height
	for frame in 600:
		swarm.step(DT, level.surface_point(0.0, swarm.positions[0].z * -1.0 - 50.0), Vector3.ZERO)
		left = minf(left, swarm.positions[0].x - lane)
		right = maxf(right, swarm.positions[0].x - lane)
		var above := _above_ground(0) > s.fly_height
		if above != was_above:
			crossings += 1
		was_above = above
	assert_near(left, -s.sway_width, 0.05)
	assert_near(right, s.sway_width, 0.05)
	var expected := 2.0 * swarm.bob_frequencies[0] * 10.0
	assert_between(float(crossings), expected - 1.5, expected + 1.5)


func test_a_flyer_points_where_it_flies() -> void:
	_fly()
	for frame in 90:
		var before := swarm.positions[0]
		swarm.step(DT, level.surface_point(0.0, 0.0), Vector3.ZERO)
		var dir := (swarm.positions[0] - before).normalized()
		# Headless has no real renderer (the MultiMesh reads back identity),
		# so decode the buffer sent to it (MultiMesh.buffer layout: rows of
		# basis.x/y/z component then origin).
		var f := swarm._buffer
		var xf := Transform3D(Vector3(f[0], f[4], f[8]), Vector3(f[1], f[5], f[9]),
				Vector3(f[2], f[6], f[10]), Vector3(f[3], f[7], f[11]))
		assert_near(xf.basis.y.normalized(), dir, 0.001)
		assert_near(xf.origin, swarm.positions[0], 0.001)
		# Sway and bob reach ~9 m/s each against 12 m/s forward: up to ~47°
		# off straight ahead (plus the slope), never more than 60°.
		assert_true(xf.basis.y.dot(Vector3.FORWARD) > 0.5, "nose forward")


func test_a_flyer_left_behind_goes_ahead_again() -> void:
	_fly()
	var runner_pos := level.surface_point(0.0, 300.0)
	swarm.step(DT, runner_pos, Vector3(0, 0, -40))
	var ahead := runner_pos.z - swarm.positions[0].z
	var s := swarm.settings
	assert_between(ahead, s.spawn_distance - 1.0, s.spawn_distance + s.spawn_spread + 1.0)
	assert_near(swarm.fly_times[0], 0.0, 0.0001)


func test_a_flyer_too_far_ahead_comes_back() -> void:
	_fly()
	var s := swarm.settings
	swarm.positions[0].z = -(s.fly_ahead_limit + 5.0)
	swarm.step(DT, level.surface_point(0.0, 0.0), Vector3.ZERO)
	assert_between(-swarm.positions[0].z, s.spawn_distance - 1.0, s.spawn_distance + s.spawn_spread + 1.0)


func test_a_flyer_touches_a_runner_jumping_into_it() -> void:
	_fly()
	var p := swarm.positions[0]
	var ground := level.surface_point(p.x, -p.z)
	swarm.step(0.0, ground, Vector3.ZERO)  # standing under it
	assert_eq(swarm.touches, 0)
	swarm.step(0.0, p - Vector3.UP * 1.0, Vector3.ZERO)  # head in its belly
	assert_eq(swarm.touches, 1)
	swarm.step(0.0, p - Vector3.UP * 1.0, Vector3.ZERO)
	assert_eq(swarm.touches, 1, "a touch counts once")


func test_a_flyer_stays_on_the_strip() -> void:
	_fly(20)
	var half := level.settings.width * 0.5 - swarm.settings.edge_margin
	for frame in 600:
		swarm.step(DT, level.surface_point(0.0, 0.0), Vector3.ZERO)
		for i in 20:
			if absf(swarm.positions[i].x) > half + 0.001:
				fail("flyer %d at x %.2f" % [i, swarm.positions[i].x])
				return
