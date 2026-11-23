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
