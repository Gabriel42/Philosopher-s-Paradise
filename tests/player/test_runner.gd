extends TestCase
## The placeholder runner on the endless level.

const RUNNER := preload("res://scenes/player/runner.tscn")

var level: EndlessLevel
var runner: Runner


func before_each() -> void:
	level = EndlessLevel.new()
	level.settings = TerrainSettings.new()
	runner = RUNNER.instantiate()
	runner.use_player_input = false
	runner.movement = Movement.new()
	level.add_child(runner)
	level.runner = runner
	keep(level)


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func test_stands_on_the_ground() -> void:
	await _wait(60)
	assert_true(runner.is_on_floor(), "on the floor")
	var ground := level.surface_point(runner.position.x, level.runner_distance())
	assert_near(runner.position.y, ground.y, 0.3, "feet on the ground")


func test_running_forward_goes_far_and_fast() -> void:
	await _wait(20)
	runner.move_input = Vector2(0.0, 1.0)
	await _wait(240)  # 4 s
	assert_true(level.runner_distance() > 50.0, "distance %.1f" % level.runner_distance())
	assert_true(runner.speed > 15.0, "speed %.1f" % runner.speed)


func test_jump_leaves_the_ground() -> void:
	await _wait(30)
	var start_y := runner.position.y
	runner.wants_jump = true
	await _wait(10)
	assert_false(runner.is_on_floor(), "in the air")
	assert_true(runner.position.y > start_y + 0.5, "went up")


func test_fast_fall_lands_sooner() -> void:
	await _wait(30)
	runner.wants_jump = true
	runner.fast_falling = true
	var frames := 0
	await _wait(3)
	while not runner.is_on_floor() and frames < 120:
		await _wait(1)
		frames += 1
	assert_true(frames < 30, "landed after %d frames (a normal jump is about 44)" % frames)


func test_model_idles_when_still_and_runs_when_fast() -> void:
	var model := runner.get_node("Model") as RunnerModel
	await _wait(1)
	model.animate(0.0, true)
	assert_eq(model.current_animation(), "idle", "still")
	model.animate(10.0, true)
	assert_eq(model.current_animation(), "run", "fast")


func test_model_runs_when_moving() -> void:
	var model := runner.get_node("Model") as RunnerModel
	await _wait(20)
	runner.move_input = Vector2(0.0, 1.0)
	await _wait(60)
	assert_eq(model.current_animation(), "run", "running")


func test_model_jumps_in_the_air() -> void:
	var model := runner.get_node("Model") as RunnerModel
	await _wait(60)
	runner.wants_jump = true
	await _wait(10)
	assert_false(runner.is_on_floor(), "in the air")
	assert_eq(model.current_animation(), "air_jump", "in the air")


func test_model_skydives_in_the_air_only() -> void:
	var model := runner.get_node("Model") as RunnerModel
	await _wait(60)
	assert_near(model.pose_amount(), 0.0, 0.01, "no pose on the ground")
	runner.wants_jump = true
	await get_tree().create_timer(0.45).timeout
	assert_false(runner.is_on_floor(), "in the air")
	assert_near(model.pose_amount(), 1.0, 0.01, "skydive pose")
	assert_near(model.tip(), model.flight_tip(), 3.0, "tipped forward, following the climb")
	while not runner.is_on_floor():
		await _wait(1)
	await get_tree().create_timer(0.3).timeout
	assert_near(model.pose_amount(), 0.0, 0.01, "pose gone after landing")
	assert_near(model.tip(), 0.0, 0.1, "upright after landing")


func test_mouse_motion_does_not_turn_the_camera() -> void:
	runner.use_player_input = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _wait(5)
	var pivot: Node3D = runner.get_node("CameraPivot")
	var before := pivot.rotation
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(400.0, 200.0)
	runner._unhandled_input(motion)
	await _wait(5)
	runner.use_player_input = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	assert_near(pivot.rotation, before, 0.0001, "camera unchanged")
	assert_near(pivot.rotation, Vector3(runner.movement.camera_pitch, 0.0, 0.0), 0.0001,
			"fixed angle")
