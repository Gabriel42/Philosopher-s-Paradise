extends TestCase
## enemy2 (EnemyFlankers): reaching spots beside the runner, keeping them,
## spacing, shots fired and hitting, aiming, origin shift. Moves a pretend
## runner by hand and calls step() at 60 Hz (no physics, no Runner).

const DT := 1.0 / 60.0

var level: EndlessLevel
var flankers: EnemyFlankers


func before_each() -> void:
	level = EndlessLevel.new()
	level.settings = TerrainSettings.new()
	flankers = EnemyFlankers.new()
	flankers.settings = FlankerSettings.new()
	level.add_child(flankers)
	keep(level)
	level.set_physics_process(false)
	flankers.set_physics_process(false)


func _half() -> float:
	return level.settings.width * 0.5 - flankers.settings.edge_margin


## Runs a runner from ([param x], [param distance]) at [param vel] for
## [param seconds], on the ground. Returns its last position. The enemies get
## the runner's real velocity (it rides up and down the hills), as in the game.
func _run(x: float, distance: float, vel: Vector3, seconds: float) -> Vector3:
	var pos := level.surface_point(x, distance)
	for frame in roundi(seconds / DT):
		var before := pos
		pos = level.surface_point(pos.x + vel.x * DT, -(pos.z + vel.z * DT))
		flankers.step(DT, pos, (pos - before) / DT)
	return pos


## Largest distance (X/Z) of any enemy from its spot.
func _worst_off_spot(runner_pos: Vector3) -> float:
	var worst := 0.0
	for i in flankers.positions.size():
		var spot := flankers.spot_of(i, runner_pos, _half())
		var p := flankers.positions[i]
		worst = maxf(worst, Vector2(p.x - spot.x, p.z - spot.y).length())
	return worst


func test_defaults_are_six_orange_ones() -> void:
	var s := FlankerSettings.new()
	assert_eq(s.display_name, "enemy2")
	assert_eq(s.count, 6)
	assert_true(s.color.r > 0.9 and s.color.g > 0.3 and s.color.g < 0.7 and s.color.b < 0.2,
			"orange: %s" % s.color)
	var loaded := load("res://resources/enemies/enemy2.tres") as FlankerSettings
	assert_ne(loaded, null)
	assert_eq(loaded.count, 6)


func test_spots_are_three_per_side_in_rows() -> void:
	flankers.step(0.0, level.surface_point(0.0, 0.0), Vector3.ZERO)  # fills the pool
	var pos := Vector3(0.0, 0.0, -100.0)
	var want := [Vector2(-5, -104), Vector2(5, -104), Vector2(-5, -100),
			Vector2(5, -100), Vector2(-5, -96), Vector2(5, -96)]
	for i in 6:
		assert_near(flankers.spot_of(i, pos, _half()), want[i], 0.001, "spot %d" % i)


func test_a_spot_past_the_edge_goes_to_the_other_side() -> void:
	flankers.step(0.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
	var pos := Vector3(_half() - 1.0, 0.0, 0.0)  # runner hugging the right edge
	var right := flankers.spot_of(1, pos, _half())
	assert_near(right.x, pos.x - 7.5, 0.001)
	var left := flankers.spot_of(0, pos, _half())
	assert_near(left.x, pos.x - 5.0, 0.001)


func test_they_appear_ahead() -> void:
	flankers.step(DT, level.surface_point(0.0, 0.0), Vector3(0, 0, -30))
	for p in flankers.positions:
		assert_true(-p.z > 40.0, "appeared %.1f m ahead" % -p.z)


func test_reach_their_spots_and_keep_them() -> void:
	var vel := Vector3(0, 0, -30)
	var pos := _run(0.0, 0.0, vel, 8.0)
	assert_true(_worst_off_spot(pos) < 1.0, "off spot by %.2f m" % _worst_off_spot(pos))
	pos = _run(pos.x, -pos.z, vel, 5.0)  # and they stay there
	assert_true(_worst_off_spot(pos) < 1.0, "off spot by %.2f m" % _worst_off_spot(pos))
	for i in 6:
		assert_near(flankers.speeds[i], 30.0, 0.5, "matches the runner's speed")
	assert_eq(flankers.touches, 0, "they stay beside, not on, the runner")


func test_follow_a_runner_that_speeds_up_and_turns() -> void:
	var pos := _run(0.0, 0.0, Vector3(0, 0, -25), 8.0)
	pos = _run(pos.x, -pos.z, Vector3(4, 0, -45), 6.0)  # faster, drifting right
	assert_true(_worst_off_spot(pos) < 1.5, "off spot by %.2f m" % _worst_off_spot(pos))


func test_a_sudden_boost_leaves_them_behind_then_they_catch_up() -> void:
	var pos := _run(0.0, 0.0, Vector3(0, 0, -25), 8.0)
	pos = _run(pos.x, -pos.z, Vector3(0, 0, -60), 0.5)
	assert_true(_worst_off_spot(pos) > 3.0, "left behind by %.2f m" % _worst_off_spot(pos))
	pos = _run(pos.x, -pos.z, Vector3(0, 0, -60), 8.0)
	assert_true(_worst_off_spot(pos) < 1.0, "caught up: %.2f m" % _worst_off_spot(pos))


func test_never_overlap() -> void:
	var pos := level.surface_point(0.0, 0.0)
	var vel := Vector3(0, 0, -30)
	var closest := INF
	for frame in roundi(10.0 / DT):
		pos = level.surface_point(pos.x, -(pos.z + vel.z * DT))
		flankers.step(DT, pos, vel)
		for i in 6:
			for j in range(i + 1, 6):
				var a := flankers.positions[i]
				var b := flankers.positions[j]
				closest = minf(closest, Vector2(a.x - b.x, a.z - b.z).length())
	assert_true(closest >= 2.0 * flankers.settings.radius,
			"closest pair %.2f m (bodies are %.1f m wide)" % [closest, 2.0 * flankers.settings.radius])


func test_no_shots_before_reaching_their_spots() -> void:
	_run(0.0, 0.0, Vector3(0, 0, -30), 0.5)  # still far ahead
	assert_eq(flankers.shots_fired, 0)


func test_they_shoot_and_hit_a_steady_runner() -> void:
	var fired: Array[int] = []
	var hit: Array[int] = []
	flankers.shot_fired.connect(func(total: int) -> void: fired.append(total))
	flankers.runner_shot.connect(func(total: int) -> void: hit.append(total))
	_run(0.0, 0.0, Vector3(0, 0, -30), 20.0)
	# ~14 s at their spots, 6 enemies, one shot every 2 s each: about 40.
	assert_between(flankers.shots_fired, 25, 50)
	assert_true(flankers.shots_hit > flankers.shots_fired / 2,
			"%d of %d hit" % [flankers.shots_hit, flankers.shots_fired])
	assert_eq(fired.size(), flankers.shots_fired)
	assert_eq(hit.size(), flankers.shots_hit)


func test_a_runner_standing_still_gets_hit() -> void:
	_run(0.0, 0.0, Vector3.ZERO, 12.0)
	assert_true(flankers.shots_hit > 0, "%d hits" % flankers.shots_hit)


func test_aim_meets_a_moving_target() -> void:
	var from := Vector3(5, 1, 0)
	var shooter_vel := Vector3(0, 0, -30)
	var to := Vector3(0, 1, 0)
	var target_vel := Vector3(3, 0, -30)
	var v := EnemyFlankers.aim_shot(from, shooter_vel, to, target_vel, 25.0)
	assert_near((v - shooter_vel).length(), 25.0, 0.001, "speed relative to the shooter")
	# Follow both for up to 1 s: the shot must pass within 5 cm of the target.
	var closest := INF
	for k in 1000:
		var t := k * 0.001
		closest = minf(closest, (from + v * t).distance_to(to + target_vel * t))
	assert_true(closest < 0.05, "missed by %.3f m" % closest)


func test_shots_are_drawn_and_disappear() -> void:
	_run(0.0, 0.0, Vector3(0, 0, -30), 10.0)
	var view := flankers.get_node("Shots") as MultiMeshInstance3D
	assert_eq(view.multimesh.instance_count, flankers.settings.max_shots)
	# Stop shooting: every shot ends within its life.
	flankers.settings.shot_interval = 1000.0
	for i in 6:
		flankers.shot_timers[i] = 1000.0
	var pos := _run(0.0, 300.0, Vector3(0, 0, -30), flankers.settings.shot_life + 0.1)
	for life in flankers.shot_lives:
		assert_true(life <= 0.0)
	assert_true(pos.z < 0.0)


func test_origin_shift_keeps_enemies_and_shots_in_place() -> void:
	var mover := Node3D.new()
	level.add_child(mover)
	level.runner = mover
	var pos := _run(0.0, 2400.0, Vector3(0, 0, -30), 6.0)
	mover.position = pos
	var real := flankers.positions[0] + level.origin
	var shot := flankers.shot_positions[0] + level.origin
	level.check_origin_shift()
	assert_true(level.origin.length() > 1000.0, "the world shifted")
	assert_near(flankers.positions[0] + level.origin, real, 0.01)
	assert_near(flankers.shot_positions[0] + level.origin, shot, 0.01)


func test_turned_off_it_has_no_enemies_and_no_shots() -> void:
	_run(0.0, 0.0, Vector3(0, 0, -30), 8.0)
	assert_true(flankers.shots_fired > 0)
	flankers.active = false
	assert_eq(flankers.positions.size(), 0)
	for life in flankers.shot_lives:
		assert_true(life <= 0.0, "no shot left flying")
	var fired := flankers.shots_fired
	_run(0.0, 300.0, Vector3(0, 0, -30), 4.0)
	assert_eq(flankers.shots_fired, fired, "no shots while off")
