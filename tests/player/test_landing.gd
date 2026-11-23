extends TestCase
## Landing on flat and 20° sloped floors: how much speed is kept, the signals
## and the effects.

const RUNNER := preload("res://scenes/player/runner.tscn")

var world: Node3D
var runner: Runner
var landings: Array[Vector3] = []  # (impact, kept, speed right after)
var fast_fall_events: Array[bool] = []


func before_each() -> void:
	world = Node3D.new()
	keep(world)
	landings.clear()
	fast_fall_events.clear()


## A floor through the origin tilted by [param degrees] around X (negative:
## going down towards -Z), and the runner just above it moving with [param v].
func _drop(degrees: float, v: Vector3, fast_fall := false, m: Movement = null, height := 0.4) -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3.DOWN * 0.5
	floor_body.add_child(shape)
	floor_body.rotation.x = deg_to_rad(degrees)
	world.add_child(floor_body)
	runner = RUNNER.instantiate()
	runner.use_player_input = false
	runner.movement = m if m else Movement.new()
	world.add_child(runner)
	runner.position = Vector3.UP * height
	runner.velocity = v
	runner.heading = Vector3(v.x, 0.0, v.z).normalized()
	runner.fast_falling = fast_fall
	runner.landed.connect(func(impact: float, kept: float) -> void:
		landings.append(Vector3(impact, kept, runner.speed)))
	runner.fast_fall_changed.connect(func(on: bool) -> void: fast_fall_events.append(on))
	for i in 10:
		await get_tree().physics_frame


func test_flat_landing_turns_some_fall_into_speed() -> void:
	await _drop(0.0, Vector3(0.0, -20.0, -20.0))
	assert_eq(landings.size(), 1, "one landing")
	assert_between(landings[0].z, 24.0, 27.0, "20 + 20 × 0.5 × 0.5 ≈ 25")


func test_downhill_landing_gains_speed() -> void:
	await _drop(-20.0, Vector3(0.0, -20.0, -20.0))
	assert_eq(landings.size(), 1, "one landing")
	assert_between(landings[0].z, 29.0, 34.0, "≈ 31.6 m/s")
	assert_true(landings[0].y > 1.0, "kept more than the total before (%.2f)" % landings[0].y)


func test_uphill_landing_keeps_the_minimum() -> void:
	await _drop(-20.0, Vector3(0.0, -20.0, 20.0))
	assert_near(landings[0].z, 15.0, 1.0, "75% of 20 m/s")


func test_no_convert_is_the_old_landing() -> void:
	var m := Movement.new()
	m.landing_convert = 0.0
	m.landing_min_keep = 0.0
	await _drop(0.0, Vector3(0.0, -20.0, -20.0), false, m)
	assert_between(landings[0].z, 19.0, 20.5, "keeps only the 20 m/s along the ground")


func test_fast_fall_signal_on_then_off_at_landing() -> void:
	await _drop(0.0, Vector3(0.0, -5.0, -10.0), true)
	assert_eq(fast_fall_events, [true, false] as Array[bool], "on in the air, off on the ground")


func test_fast_fall_rolls_tucked_then_skydives_then_rights() -> void:
	# From 60 m with fast fall gravity (110): about 1 s in the air.
	await _drop(0.0, Vector3(0.0, 0.0, -10.0), true, null, 60.0)
	var model := runner.get_node("Model") as RunnerModel
	var lowest := model.tip()
	var most_tucked := model.tuck_amount()
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 400:
		await get_tree().process_frame
		lowest = minf(lowest, model.tip())
		most_tucked = maxf(most_tucked, model.tuck_amount())
	assert_false(runner.is_on_floor(), "still in the air")
	assert_true(lowest < -300.0, "rolled a full turn (lowest tip %.0f°)" % lowest)
	assert_near(most_tucked, 1.0, 0.01, "fully tucked during the roll")
	assert_near(model.tip(), model.flight_tip(), 3.0, "flying tip after the roll")
	assert_true(model.tip() < -model.skydive_angle, "head down, falling fast (%.0f°)" % model.tip())
	assert_near(model.tuck_amount(), 0.0, 0.01, "opened into the skydive")
	assert_near(model.pose_amount(), 1.0, 0.01, "in the skydive pose")
	while not runner.is_on_floor():
		await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	assert_near(model.tip(), 0.0, 0.1, "upright again after landing")
	assert_near(model.pose_amount(), 0.0, 0.01, "back to the animation")


func test_leans_forward_running_uphill_and_back_downhill() -> void:
	# Floor tilted +20°: rising towards -Z, where the runner goes.
	await _drop(20.0, Vector3(0.0, 0.0, -10.0), false, null, 0.05)
	runner.move_input = Vector2(0.0, 1.0)
	await get_tree().create_timer(0.6).timeout
	var model := runner.get_node("Model") as RunnerModel
	# (On a straight climb it is off the floor every other frame: hops too
	# short to count as air.)
	assert_near(model.pose_amount(), 0.0, 0.01, "not in the skydive")
	assert_near(model.lean(), 10.0, 0.5, "half of 20° forward")
	world.queue_free()
	world = Node3D.new()
	keep(world)
	await _drop(-20.0, Vector3(0.0, 0.0, -10.0), false, null, 0.05)
	runner.move_input = Vector2(0.0, 1.0)
	await get_tree().create_timer(0.6).timeout
	model = runner.get_node("Model") as RunnerModel
	assert_near(model.lean(), -6.0, 0.5, "back, capped at 6° going down")


func test_hard_landing_leaves_effects() -> void:
	await _drop(0.0, Vector3(0.0, -30.0, -10.0), true)
	assert_eq(world.get_child_count(), 3, "floor, runner, dust left in the world")
	assert_eq(runner.get_node("Effects").get_child_count(), 0, "no ring")


func test_hard_landing_runs_straight_on_without_squash() -> void:
	# Fast fall from 20 m (≈ 0.6 s in the air): skydive, then a hard landing.
	await _drop(0.0, Vector3(0.0, 0.0, -10.0), true, null, 20.0)
	runner.move_input = Vector2(0.0, 1.0)
	var model := runner.get_node("Model") as RunnerModel
	var worst_scale := 0.0
	while not runner.is_on_floor():
		await get_tree().process_frame
		worst_scale = maxf(worst_scale, (model.scale - Vector3.ONE).length())
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 100:
		await get_tree().process_frame
		worst_scale = maxf(worst_scale, (model.scale - Vector3.ONE).length())
	assert_near(worst_scale, 0.0, 0.001, "the model never squashes")
	assert_eq(model.current_animation(), "run", "running 0.1 s after landing")
	assert_near(model.tip(), 0.0, 0.1, "upright 0.1 s after landing")
	assert_near(model.pose_amount(), 0.0, 0.01, "out of the skydive 0.1 s after landing")


func test_landing_mid_roll_finishes_the_flip_forward() -> void:
	# Fast fall from 3 m lands ≈ 0.23 s in; a 0.5 s roll is then past
	# head-first.
	await _drop(0.0, Vector3(0.0, 0.0, -10.0), true, null, 3.0)
	var model := runner.get_node("Model") as RunnerModel
	model.roll_time = 0.5
	runner.move_input = Vector2(0.0, 1.0)
	while not runner.is_on_floor():
		await get_tree().process_frame
	var at_touch := model.tip()
	assert_true(at_touch < -90.0, "landed past head-first (tip %.0f°)" % at_touch)
	var prev := at_touch
	var went_back := false
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 300:
		await get_tree().process_frame
		var now := model.tip()
		if now != 0.0 and now > prev + 0.01:
			went_back = true
		prev = now
	assert_false(went_back, "only turned forward")
	assert_near(model.tip(), 0.0, 0.1, "upright after the flip")
	assert_near(model.pose_amount(), 0.0, 0.01, "back to the animation")
	assert_eq(model.current_animation(), "run", "running")


func test_small_hop_leaves_no_effects() -> void:
	await _drop(0.0, Vector3(0.0, -1.0, -10.0), false, null, 0.02)
	assert_eq(world.get_child_count(), 2, "only floor and runner")
	assert_eq(runner.get_node("Effects").get_child_count(), 0, "nothing")


func test_left_right_slides_sideways_in_the_air() -> void:
	# 20 m up (≈ 1.1 s of fall), going north at 20 m/s, holding right.
	await _drop(0.0, Vector3(0.0, 0.0, -20.0), false, null, 20.0)
	runner.move_input = Vector2(1.0, 0.0)
	var x0 := runner.position.x
	await get_tree().create_timer(0.5).timeout
	assert_false(runner.is_on_floor(), "still in the air")
	assert_near(runner.air_side, runner.movement.air_side_speed, 0.01, "full slide to the right")
	var right := Vector3(-runner.heading.z, 0.0, runner.heading.x)
	assert_near(Vector3(runner.velocity.x, 0.0, runner.velocity.z).dot(right), 14.0, 0.5,
			"14 m/s sideways")
	assert_true(runner.position.x - x0 > 4.0, "moved right %.1f m" % (runner.position.x - x0))
	var forward := Vector3(runner.velocity.x, 0.0, runner.velocity.z).dot(runner.heading)
	assert_between(forward, 19.5, 22.1, "forward speed kept (air_accel up to run_speed)")
	runner.move_input = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	assert_near(runner.air_side, 0.0, 0.01, "slide stops when let go")
	while not runner.is_on_floor():
		await get_tree().physics_frame
	assert_eq(runner.air_side, 0.0, "no slide on the ground")
